-- 04_seed_creditos_scoring_desembolso.sql
-- Creditos, scoring, RDS, ruta de aprobacion, desembolso y cronograma
-- Proyecto BanBif - bd_core_financiero

-- Limpieza controlada de datos de creditos demo
WITH demo_users AS (
    SELECT id FROM "user" WHERE email LIKE '%@demo.banbif.local'
),
demo_credits AS (
    SELECT id FROM creditapplication WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM recovery_action
WHERE recovery_case_id IN (
    SELECT id FROM recovery_case WHERE credit_application_id IN (SELECT id FROM demo_credits)
);

WITH demo_users AS (
    SELECT id FROM "user" WHERE email LIKE '%@demo.banbif.local'
),
demo_credits AS (
    SELECT id FROM creditapplication WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM recovery_case
WHERE credit_application_id IN (SELECT id FROM demo_credits);

WITH demo_users AS (
    SELECT id FROM "user" WHERE email LIKE '%@demo.banbif.local'
),
demo_credits AS (
    SELECT id FROM creditapplication WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM loan_schedule
WHERE credit_application_id IN (SELECT id FROM demo_credits);

WITH demo_users AS (
    SELECT id FROM "user" WHERE email LIKE '%@demo.banbif.local'
),
demo_credits AS (
    SELECT id FROM creditapplication WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM credit_disbursement
WHERE credit_application_id IN (SELECT id FROM demo_credits);

DELETE FROM movement
WHERE description LIKE 'Desembolso de credito aprobado%';

WITH demo_users AS (
    SELECT id FROM "user" WHERE email LIKE '%@demo.banbif.local'
)
DELETE FROM creditapplication
WHERE user_id IN (SELECT id FROM demo_users);

-- Solicitudes de credito realistas
INSERT INTO creditapplication (
    user_id,
    product,
    amount,
    months,
    monthly_income,
    purpose,
    status,
    analyst_comment,
    created_at,
    estimated_installment,
    rds_ratio,
    scoring_score,
    risk_level,
    risk_semaphore,
    approval_route,
    required_approval_level,
    evaluated_by,
    evaluated_at,
    disbursement_status
)
SELECT
    u.id AS user_id,

    CASE
        WHEN u.id % 2 = 0 THEN 'Credito Personal'
        ELSE 'Credito MYPE'
    END AS product,

    CASE
        WHEN u.id % 10 IN (0, 1) THEN 2500
        WHEN u.id % 10 IN (2, 3) THEN 5500
        WHEN u.id % 10 IN (4, 5) THEN 9500
        WHEN u.id % 10 IN (6, 7) THEN 18000
        ELSE 35000
    END::double precision AS amount,

    CASE
        WHEN u.id % 4 = 0 THEN 12
        WHEN u.id % 4 = 1 THEN 18
        WHEN u.id % 4 = 2 THEN 24
        ELSE 36
    END AS months,

    CASE
        WHEN u.id % 8 = 0 THEN 1200
        WHEN u.id % 8 = 1 THEN 1800
        WHEN u.id % 8 = 2 THEN 2500
        WHEN u.id % 8 = 3 THEN 3200
        WHEN u.id % 8 = 4 THEN 4500
        WHEN u.id % 8 = 5 THEN 6000
        WHEN u.id % 8 = 6 THEN 900
        ELSE 3800
    END::double precision AS monthly_income,

    CASE
        WHEN u.id % 2 = 0 THEN 'Gastos personales y consolidacion de deuda'
        ELSE 'Capital de trabajo para negocio'
    END AS purpose,

    CASE
        WHEN score.score_final < 55 THEN 'Rechazado'
        WHEN score.rds > 0.45 THEN 'Rechazado'
        WHEN monto.amount_value >= 30000 THEN 'En comite'
        WHEN score.score_final BETWEEN 55 AND 64 THEN 'En evaluacion'
        ELSE 'Aprobado'
    END AS status,

    CASE
        WHEN score.score_final < 55 THEN 'Solicitud rechazada por score bajo.'
        WHEN score.rds > 0.45 THEN 'Solicitud rechazada por RDS alto.'
        WHEN monto.amount_value >= 30000 THEN 'Solicitud derivada a comite por monto alto.'
        WHEN score.score_final BETWEEN 55 AND 64 THEN 'Solicitud requiere revision adicional del analista.'
        ELSE 'Solicitud aprobada por score y capacidad de pago favorables.'
    END AS analyst_comment,

    (
        make_date(
            CASE
                WHEN u.id % 5 = 0 THEN 2022
                WHEN u.id % 5 = 1 THEN 2023
                WHEN u.id % 5 = 2 THEN 2024
                WHEN u.id % 5 = 3 THEN 2025
                ELSE 2026
            END,
            ((u.id % 12) + 1),
            1
        )
        + ((u.id % 24) || ' days')::interval
    ) AS created_at,

    score.cuota AS estimated_installment,
    score.rds AS rds_ratio,
    score.score_final AS scoring_score,

    CASE
        WHEN score.score_final >= 75 AND score.rds <= 0.30 THEN 'BAJO'
        WHEN score.score_final >= 60 AND score.rds <= 0.40 THEN 'MEDIO'
        ELSE 'ALTO'
    END AS risk_level,

    CASE
        WHEN score.score_final >= 75 AND score.rds <= 0.30 THEN 'VERDE'
        WHEN score.score_final >= 60 AND score.rds <= 0.40 THEN 'AMARILLO'
        ELSE 'ROJO'
    END AS risk_semaphore,

    CASE
        WHEN monto.amount_value <= 3000 THEN 'ASESOR_JUNIOR_1'
        WHEN monto.amount_value <= 7000 THEN 'ASESOR_JUNIOR_2'
        WHEN monto.amount_value <= 12000 THEN 'ANALISTA_JUNIOR'
        WHEN monto.amount_value <= 25000 THEN 'ANALISTA_SENIOR'
        ELSE 'COMITE'
    END AS approval_route,

    CASE
        WHEN monto.amount_value <= 3000 THEN 1
        WHEN monto.amount_value <= 7000 THEN 2
        WHEN monto.amount_value <= 12000 THEN 3
        WHEN monto.amount_value <= 25000 THEN 4
        ELSE 7
    END AS required_approval_level,

    evaluator.id AS evaluated_by,

    (
        make_date(
            CASE
                WHEN u.id % 5 = 0 THEN 2022
                WHEN u.id % 5 = 1 THEN 2023
                WHEN u.id % 5 = 2 THEN 2024
                WHEN u.id % 5 = 3 THEN 2025
                ELSE 2026
            END,
            ((u.id % 12) + 1),
            1
        )
        + ((u.id % 24) || ' days')::interval
        + interval '1 day'
    ) AS evaluated_at,

    CASE
        WHEN score.score_final >= 65
             AND score.rds <= 0.40
             AND monto.amount_value < 30000
        THEN 'Desembolsado'
        ELSE 'No desembolsado'
    END AS disbursement_status

FROM "user" u
CROSS JOIN LATERAL (
    SELECT
        CASE
            WHEN u.id % 10 IN (0, 1) THEN 2500
            WHEN u.id % 10 IN (2, 3) THEN 5500
            WHEN u.id % 10 IN (4, 5) THEN 9500
            WHEN u.id % 10 IN (6, 7) THEN 18000
            ELSE 35000
        END::double precision AS amount_value
) monto
CROSS JOIN LATERAL (
    SELECT
        CASE
            WHEN u.id % 4 = 0 THEN 12
            WHEN u.id % 4 = 1 THEN 18
            WHEN u.id % 4 = 2 THEN 24
            ELSE 36
        END AS months_value,
        CASE
            WHEN u.id % 8 = 0 THEN 1200
            WHEN u.id % 8 = 1 THEN 1800
            WHEN u.id % 8 = 2 THEN 2500
            WHEN u.id % 8 = 3 THEN 3200
            WHEN u.id % 8 = 4 THEN 4500
            WHEN u.id % 8 = 5 THEN 6000
            WHEN u.id % 8 = 6 THEN 900
            ELSE 3800
        END::double precision AS income_value
) datos
CROSS JOIN LATERAL (
    SELECT
        ROUND(((monto.amount_value / datos.months_value) * 1.18)::numeric, 2)::double precision AS cuota,
        ROUND((((monto.amount_value / datos.months_value) * 1.18) / NULLIF(datos.income_value, 0))::numeric, 4)::double precision AS rds,
        GREATEST(
            35,
            LEAST(
                95,
                (
                    70
                    + CASE WHEN datos.income_value >= 3000 THEN 12 ELSE -8 END
                    + CASE WHEN monto.amount_value <= 7000 THEN 8 ELSE -6 END
                    + CASE WHEN (((monto.amount_value / datos.months_value) * 1.18) / NULLIF(datos.income_value, 0)) <= 0.30 THEN 10 ELSE -12 END
                    + CASE WHEN u.id % 9 IN (0, 8) THEN -18 ELSE 0 END
                )
            )
        )::int AS score_final
) score
LEFT JOIN LATERAL (
    SELECT id
    FROM core_analyst_user
    WHERE approval_level >=
        CASE
            WHEN monto.amount_value <= 3000 THEN 1
            WHEN monto.amount_value <= 7000 THEN 2
            WHEN monto.amount_value <= 12000 THEN 3
            WHEN monto.amount_value <= 25000 THEN 4
            ELSE 7
        END
    ORDER BY approval_level
    LIMIT 1
) evaluator ON TRUE
WHERE u.email LIKE '%@demo.banbif.local';

-- Segunda solicitud para algunos clientes, para historial
INSERT INTO creditapplication (
    user_id,
    product,
    amount,
    months,
    monthly_income,
    purpose,
    status,
    analyst_comment,
    created_at,
    estimated_installment,
    rds_ratio,
    scoring_score,
    risk_level,
    risk_semaphore,
    approval_route,
    required_approval_level,
    evaluated_by,
    evaluated_at,
    disbursement_status
)
SELECT
    u.id,
    'Credito Personal',
    6500,
    18,
    2800,
    'Solicitud complementaria para historial crediticio',
    'Aprobado',
    'Cliente con historial y capacidad favorable.',
    DATE '2025-06-15' + ((u.id % 20) || ' days')::interval,
    ROUND(((6500 / 18.0) * 1.18)::numeric, 2)::double precision,
    ROUND(((((6500 / 18.0) * 1.18) / 2800)::numeric), 4)::double precision,
    78,
    'BAJO',
    'VERDE',
    'ASESOR_JUNIOR_2',
    2,
    (SELECT id FROM core_analyst_user WHERE role = 'ASESOR_JUNIOR_2' LIMIT 1),
    DATE '2025-06-16' + ((u.id % 20) || ' days')::interval,
    'Desembolsado'
FROM "user" u
WHERE u.email LIKE '%@demo.banbif.local'
  AND u.id % 4 = 0;

-- Registrar desembolsos para creditos aprobados y desembolsados
INSERT INTO credit_disbursement (
    credit_application_id,
    account_id,
    amount,
    status,
    disbursed_by,
    created_at
)
SELECT
    c.id,
    a.id AS account_id,
    c.amount,
    'Desembolsado',
    c.evaluated_by,
    c.evaluated_at + interval '1 day'
FROM creditapplication c
JOIN LATERAL (
    SELECT id
    FROM account
    WHERE user_id = c.user_id
      AND status = 'Activa'
    ORDER BY id
    LIMIT 1
) a ON TRUE
WHERE c.status = 'Aprobado'
  AND c.disbursement_status = 'Desembolsado';

-- Movimiento de desembolso visible en Homebanking
INSERT INTO movement (
    account_id,
    description,
    operation_type,
    amount,
    created_at
)
SELECT
    d.account_id,
    'Desembolso de credito aprobado #' || d.credit_application_id,
    'DESEMBOLSO_CREDITO',
    d.amount,
    d.created_at
FROM credit_disbursement d;

-- Aumentar saldo de las cuentas por desembolso
UPDATE account a
SET balance = balance + x.total_desembolsado
FROM (
    SELECT account_id, SUM(amount) AS total_desembolsado
    FROM credit_disbursement
    GROUP BY account_id
) x
WHERE a.id = x.account_id;

-- Cronograma de pagos para creditos desembolsados
INSERT INTO loan_schedule (
    credit_application_id,
    installment_number,
    due_date,
    principal_amount,
    interest_amount,
    total_amount,
    paid_amount,
    status,
    days_past_due,
    created_at
)
SELECT
    c.id,
    cuota.n,
    (d.created_at::date + (cuota.n || ' months')::interval)::date AS due_date,
    ROUND((c.amount / c.months)::numeric, 2)::double precision AS principal_amount,
    ROUND(((c.amount / c.months) * 0.18)::numeric, 2)::double precision AS interest_amount,
    ROUND(((c.amount / c.months) * 1.18)::numeric, 2)::double precision AS total_amount,
    CASE
        WHEN (d.created_at::date + (cuota.n || ' months')::interval)::date < CURRENT_DATE
             AND cuota.n % 6 <> 0
        THEN ROUND(((c.amount / c.months) * 1.18)::numeric, 2)::double precision
        ELSE 0
    END AS paid_amount,
    CASE
        WHEN (d.created_at::date + (cuota.n || ' months')::interval)::date < CURRENT_DATE
             AND cuota.n % 6 <> 0
        THEN 'Pagado'
        WHEN (d.created_at::date + (cuota.n || ' months')::interval)::date < CURRENT_DATE
             AND cuota.n % 6 = 0
        THEN 'Vencido'
        ELSE 'Pendiente'
    END AS status,
    CASE
        WHEN (d.created_at::date + (cuota.n || ' months')::interval)::date < CURRENT_DATE
             AND cuota.n % 6 = 0
        THEN (CURRENT_DATE - (d.created_at::date + (cuota.n || ' months')::interval)::date)
        ELSE 0
    END AS days_past_due,
    now()
FROM creditapplication c
JOIN credit_disbursement d ON d.credit_application_id = c.id
CROSS JOIN LATERAL generate_series(1, c.months) AS cuota(n);

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
    'SEED_CREDITOS_SCORING_DESEMBOLSO',
    'creditapplication',
    NULL,
    'Carga de solicitudes de credito con scoring, RDS, semaforo, ruta de aprobacion, desembolso y cronograma.'
);