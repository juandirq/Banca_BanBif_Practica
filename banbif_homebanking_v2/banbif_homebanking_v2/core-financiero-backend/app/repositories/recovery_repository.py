from app.database import get_connection, normalize_row


def list_recovery_cases(band: str | None = None):
    band_filter = None

    if band and band.strip().upper() not in ("TODOS", "TODAS", "ALL"):
        band_filter = band.strip()

    base_query = """
        SELECT
            rc.id AS recovery_case_id,
            rc.credit_application_id AS solicitud_id,
            rc.user_id,
            u.full_name AS cliente_nombre,
            u.document AS cliente_documento,
            ca.product,
            ca.amount,
            ca.status AS estado_credito,
            ca.disbursement_status AS estado_desembolso,
            rc.overdue_amount AS saldo_vencido,
            rc.days_past_due AS dias_mora,
            rc.band AS banda,
            rc.status AS estado_gestion,
            rc.assigned_to,
            au.full_name AS asignado_a,
            COUNT(ra.id) AS total_gestiones,
            MAX(ra.created_at) AS ultima_gestion,
            rc.created_at,
            rc.updated_at
        FROM recovery_case rc
        INNER JOIN creditapplication ca ON ca.id = rc.credit_application_id
        INNER JOIN "user" u ON u.id = rc.user_id
        LEFT JOIN core_analyst_user au ON au.id = rc.assigned_to
        LEFT JOIN recovery_action ra ON ra.recovery_case_id = rc.id
    """

    where_query = ""
    params = ()

    if band_filter:
        where_query = " WHERE lower(rc.band) = lower(%s) "
        params = (band_filter,)

    group_order_query = """
        GROUP BY
            rc.id,
            rc.credit_application_id,
            rc.user_id,
            u.full_name,
            u.document,
            ca.product,
            ca.amount,
            ca.status,
            ca.disbursement_status,
            rc.overdue_amount,
            rc.days_past_due,
            rc.band,
            rc.status,
            rc.assigned_to,
            au.full_name,
            rc.created_at,
            rc.updated_at
        ORDER BY rc.days_past_due DESC, rc.overdue_amount DESC, rc.id ASC
    """

    with get_connection() as conn:
        rows = conn.execute(base_query + where_query + group_order_query, params).fetchall()

    return [normalize_row(row) for row in rows]


def get_recovery_summary():
    cases = list_recovery_cases()

    por_banda = {}
    for case in cases:
        banda = case.get("banda") or "Sin banda"
        if banda not in por_banda:
            por_banda[banda] = {
                "casos": 0,
                "saldo_vencido": 0
            }

        por_banda[banda]["casos"] += 1
        por_banda[banda]["saldo_vencido"] += float(case.get("saldo_vencido") or 0)

    for banda in por_banda:
        por_banda[banda]["saldo_vencido"] = round(por_banda[banda]["saldo_vencido"], 2)

    return {
        "total_casos": len(cases),
        "saldo_vencido_total": round(sum(float(c.get("saldo_vencido") or 0) for c in cases), 2),
        "gestion_activa": sum(1 for c in cases if (c.get("estado_gestion") or "").lower() not in ("cerrado", "recuperado")),
        "judicial": sum(1 for c in cases if (c.get("banda") or "").lower() == "judicial"),
        "castigo": sum(1 for c in cases if (c.get("banda") or "").lower() == "castigo"),
        "mora_critica": sum(1 for c in cases if int(c.get("dias_mora") or 0) >= 61),
        "por_banda": por_banda
    }


def get_recovery_actions(recovery_case_id: int):
    with get_connection() as conn:
        rows = conn.execute(
            """
            SELECT
                ra.id,
                ra.recovery_case_id,
                ra.action_type,
                ra.comment,
                ra.result,
                ra.created_by,
                au.full_name AS creado_por,
                ra.created_at
            FROM recovery_action ra
            LEFT JOIN core_analyst_user au ON au.id = ra.created_by
            WHERE ra.recovery_case_id = %s
            ORDER BY ra.created_at DESC, ra.id DESC
            """,
            (recovery_case_id,)
        ).fetchall()

    return [normalize_row(row) for row in rows]


def register_recovery_action(
    recovery_case_id: int,
    action_type: str,
    comment: str | None,
    result: str | None,
    created_by: int | None,
    status: str | None = None
):
    action_type = (action_type or "").strip()
    if not action_type:
        raise ValueError("El tipo de gestion es obligatorio.")

    with get_connection() as conn:
        case = conn.execute(
            """
            SELECT *
            FROM recovery_case
            WHERE id = %s
            FOR UPDATE
            """,
            (recovery_case_id,)
        ).fetchone()

        if not case:
            raise ValueError("Caso de recuperacion no encontrado.")

        action = conn.execute(
            """
            INSERT INTO recovery_action
            (recovery_case_id, action_type, comment, result, created_by, created_at)
            VALUES
            (%s, %s, %s, %s, %s, now())
            RETURNING *
            """,
            (
                recovery_case_id,
                action_type,
                comment,
                result or "Pendiente",
                created_by
            )
        ).fetchone()

        if status:
            conn.execute(
                """
                UPDATE recovery_case
                SET status = %s,
                    updated_at = now()
                WHERE id = %s
                """,
                (status, recovery_case_id)
            )
        else:
            conn.execute(
                """
                UPDATE recovery_case
                SET updated_at = now()
                WHERE id = %s
                """,
                (recovery_case_id,)
            )

        conn.commit()

    return {
        "accion": normalize_row(action),
        "historial": get_recovery_actions(recovery_case_id)
    }


def transition_to_judicial(recovery_case_id: int, created_by: int | None, comment: str | None = None):
    with get_connection() as conn:
        case = conn.execute(
            """
            SELECT *
            FROM recovery_case
            WHERE id = %s
            FOR UPDATE
            """,
            (recovery_case_id,)
        ).fetchone()

        if not case:
            raise ValueError("Caso de recuperacion no encontrado.")

        case_data = normalize_row(case)
        dias = int(case_data.get("days_past_due") or 0)

        if dias < 121:
            raise ValueError("Para transicion judicial se requieren al menos 121 dias de mora.")

        updated = conn.execute(
            """
            UPDATE recovery_case
            SET band = 'Judicial',
                status = 'Derivado a judicial',
                updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (recovery_case_id,)
        ).fetchone()

        action = conn.execute(
            """
            INSERT INTO recovery_action
            (recovery_case_id, action_type, comment, result, created_by, created_at)
            VALUES
            (%s, %s, %s, %s, %s, now())
            RETURNING *
            """,
            (
                recovery_case_id,
                "Expediente enviado a legal",
                comment or "Caso derivado a judicial por superar 121 dias de mora.",
                "Validado",
                created_by
            )
        ).fetchone()

        conn.commit()

    return {
        "caso": normalize_row(updated),
        "accion": normalize_row(action)
    }


def castigate_recovery_case(recovery_case_id: int, created_by: int | None, comment: str | None = None):
    with get_connection() as conn:
        case = conn.execute(
            """
            SELECT *
            FROM recovery_case
            WHERE id = %s
            FOR UPDATE
            """,
            (recovery_case_id,)
        ).fetchone()

        if not case:
            raise ValueError("Caso de recuperacion no encontrado.")

        case_data = normalize_row(case)
        dias = int(case_data.get("days_past_due") or 0)

        if dias <= 180:
            raise ValueError("Para castigo se requieren mas de 180 dias de mora.")

        updated = conn.execute(
            """
            UPDATE recovery_case
            SET band = 'Castigo',
                status = 'Propuesto para castigo',
                updated_at = now()
            WHERE id = %s
            RETURNING *
            """,
            (recovery_case_id,)
        ).fetchone()

        action = conn.execute(
            """
            INSERT INTO recovery_action
            (recovery_case_id, action_type, comment, result, created_by, created_at)
            VALUES
            (%s, %s, %s, %s, %s, now())
            RETURNING *
            """,
            (
                recovery_case_id,
                "Evaluacion de castigo",
                comment or "Caso propuesto para castigo por superar 180 dias de mora.",
                "Propuesto",
                created_by
            )
        ).fetchone()

        conn.commit()

    return {
        "caso": normalize_row(updated),
        "accion": normalize_row(action)
    }
