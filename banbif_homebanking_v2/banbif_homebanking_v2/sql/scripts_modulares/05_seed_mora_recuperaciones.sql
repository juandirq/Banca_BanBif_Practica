-- 05_seed_mora_recuperaciones.sql
-- Mora / Recuperaciones R1, R2, R3
-- Proyecto BanBif - bd_core_financiero

-- Limpieza de mora demo anterior
DELETE FROM recovery_action;
DELETE FROM recovery_case;

-- Recalibrar cronograma:
-- Primero, cuotas vencidas antiguas se consideran pagadas, salvo casos seleccionados para mora.
UPDATE loan_schedule
SET
    status = CASE
        WHEN due_date < CURRENT_DATE THEN 'Pagado'
        ELSE 'Pendiente'
    END,
    paid_amount = CASE
        WHEN due_date < CURRENT_DATE THEN total_amount
        ELSE 0
    END,
    days_past_due = 0;

-- Seleccionar muestra realista de creditos en mora:
-- 6 de 43 desembolsados aprox. = 13.95%
WITH selected_mora AS (
    SELECT
        d.credit_application_id,
        c.user_id,
        ROW_NUMBER() OVER (ORDER BY d.credit_application_id) AS rn
    FROM credit_disbursement d
    JOIN creditapplication c ON c.id = d.credit_application_id
    ORDER BY d.credit_application_id
    LIMIT 6
),
mora_config AS (
    SELECT
        credit_application_id,
        user_id,
        rn,
        CASE rn
            WHEN 1 THEN 18
            WHEN 2 THEN 42
            WHEN 3 THEN 86
            WHEN 4 THEN 132
            WHEN 5 THEN 195
            ELSE 64
        END AS days_past_due
    FROM selected_mora
),
target_installment AS (
    SELECT DISTINCT ON (l.credit_application_id)
        l.id AS schedule_id,
        l.credit_application_id,
        mc.user_id,
        mc.rn,
        mc.days_past_due
    FROM loan_schedule l
    JOIN mora_config mc ON mc.credit_application_id = l.credit_application_id
    WHERE l.due_date < CURRENT_DATE
    ORDER BY l.credit_application_id, l.due_date DESC
)
UPDATE loan_schedule l
SET
    status = 'Vencido',
    paid_amount = 0,
    days_past_due = t.days_past_due
FROM target_installment t
WHERE l.id = t.schedule_id;

-- Crear casos de recuperaciones
WITH overdue AS (
    SELECT
        c.id AS credit_application_id,
        c.user_id,
        SUM(l.total_amount - l.paid_amount) AS overdue_amount,
        MAX(l.days_past_due) AS days_past_due
    FROM creditapplication c
    JOIN loan_schedule l ON l.credit_application_id = c.id
    WHERE l.status = 'Vencido'
    GROUP BY c.id, c.user_id
)
INSERT INTO recovery_case (
    credit_application_id,
    user_id,
    overdue_amount,
    days_past_due,
    band,
    status,
    assigned_to,
    created_at,
    updated_at
)
SELECT
    o.credit_application_id,
    o.user_id,
    ROUND(o.overdue_amount::numeric, 2)::double precision AS overdue_amount,
    o.days_past_due,
    CASE
        WHEN o.days_past_due BETWEEN 1 AND 30 THEN 'Preventiva'
        WHEN o.days_past_due BETWEEN 31 AND 60 THEN 'Temprana'
        WHEN o.days_past_due BETWEEN 61 AND 120 THEN 'Tardia'
        WHEN o.days_past_due BETWEEN 121 AND 180 THEN 'Judicial'
        ELSE 'Castigo'
    END AS band,
    CASE
        WHEN o.days_past_due > 180 THEN 'Propuesto para castigo'
        WHEN o.days_past_due >= 121 THEN 'Derivado a judicial'
        ELSE 'Activo'
    END AS status,
    CASE
        WHEN o.days_past_due > 180 THEN (SELECT id FROM core_analyst_user WHERE role = 'COMITE' LIMIT 1)
        WHEN o.days_past_due >= 121 THEN (SELECT id FROM core_analyst_user WHERE role = 'RIESGOS' LIMIT 1)
        WHEN o.days_past_due >= 61 THEN (SELECT id FROM core_analyst_user WHERE role = 'SUPERVISOR' LIMIT 1)
        ELSE (SELECT id FROM core_analyst_user WHERE role = 'ANALISTA_SENIOR' LIMIT 1)
    END AS assigned_to,
    now() - ((o.days_past_due / 3)::int || ' days')::interval AS created_at,
    now() AS updated_at
FROM overdue o;

-- Registrar gestiones de cobranza R2
INSERT INTO recovery_action (
    recovery_case_id,
    action_type,
    comment,
    result,
    created_by,
    created_at
)
SELECT
    rc.id,
    CASE
        WHEN rc.band = 'Preventiva' THEN 'Llamada preventiva'
        WHEN rc.band = 'Temprana' THEN 'SMS y llamada de cobranza'
        WHEN rc.band = 'Tardia' THEN 'Negociacion de compromiso'
        WHEN rc.band = 'Judicial' THEN 'Derivacion judicial'
        ELSE 'Evaluacion de castigo'
    END AS action_type,
    CASE
        WHEN rc.band = 'Preventiva' THEN 'Se recuerda al cliente regularizar la cuota vencida.'
        WHEN rc.band = 'Temprana' THEN 'Cliente contactado para coordinar fecha de pago.'
        WHEN rc.band = 'Tardia' THEN 'Se propone compromiso de pago y seguimiento semanal.'
        WHEN rc.band = 'Judicial' THEN 'Caso derivado a area legal por superar 121 dias de atraso.'
        ELSE 'Caso propuesto para castigo por superar 180 dias de atraso.'
    END AS comment,
    CASE
        WHEN rc.band IN ('Preventiva', 'Temprana') THEN 'Contacto exitoso'
        WHEN rc.band = 'Tardia' THEN 'Compromiso pendiente'
        WHEN rc.band = 'Judicial' THEN 'Derivado'
        ELSE 'Propuesto'
    END AS result,
    rc.assigned_to AS created_by,
    rc.created_at + interval '1 day'
FROM recovery_case rc;

-- Segunda gestion para casos no preventivos
INSERT INTO recovery_action (
    recovery_case_id,
    action_type,
    comment,
    result,
    created_by,
    created_at
)
SELECT
    rc.id,
    CASE
        WHEN rc.band = 'Temprana' THEN 'Recordatorio de pago'
        WHEN rc.band = 'Tardia' THEN 'Visita / seguimiento intensivo'
        WHEN rc.band = 'Judicial' THEN 'Expediente enviado a legal'
        ELSE 'Revision de castigo'
    END AS action_type,
    CASE
        WHEN rc.band = 'Temprana' THEN 'Se envia recordatorio por canal digital.'
        WHEN rc.band = 'Tardia' THEN 'Se registra gestion adicional por mora tardia.'
        WHEN rc.band = 'Judicial' THEN 'Se confirma que el expediente cumple umbral judicial.'
        ELSE 'Se valida antiguedad mayor a 180 dias para castigo.'
    END AS comment,
    CASE
        WHEN rc.band = 'Temprana' THEN 'Pendiente'
        WHEN rc.band = 'Tardia' THEN 'En seguimiento'
        WHEN rc.band = 'Judicial' THEN 'Validado'
        ELSE 'Validado'
    END AS result,
    rc.assigned_to,
    rc.created_at + interval '3 days'
FROM recovery_case rc
WHERE rc.band <> 'Preventiva';

INSERT INTO audit_log (
    actor_type,
    actor_id,
    action,
    entity,
    entity_id,
    detail
)
VALUES (
    'SYSTEM',
    NULL,
    'SEED_MORA_RECUPERACIONES',
    'recovery_case/recovery_action',
    NULL,
    'Carga de casos de mora con bandas R1, gestiones R2 y transiciones judicial/castigo R3.'
);