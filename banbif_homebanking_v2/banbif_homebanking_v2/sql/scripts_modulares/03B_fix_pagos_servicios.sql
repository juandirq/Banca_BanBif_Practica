-- 03B_fix_pagos_servicios.sql
-- Recalibra pagos demo para que existan los 6 servicios bancarios

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
),
demo_accounts AS (
    SELECT id
    FROM account
    WHERE user_id IN (SELECT id FROM demo_users)
)
DELETE FROM pagos
WHERE user_id IN (SELECT id FROM demo_users)
   OR account_id IN (SELECT id FROM demo_accounts);

INSERT INTO pagos (
    user_id,
    servicio,
    numero_contrato,
    monto,
    estado,
    created_at,
    account_id
)
SELECT
    a.user_id,
    servicios.nombre AS servicio,
    'CTR-' || a.id || '-' || anio.y || '-' || LPAD(mes.m::text, 2, '0') AS numero_contrato,
    ROUND(
        CASE servicios.nombre
            WHEN 'Luz' THEN (45 + random() * 190)
            WHEN 'Agua' THEN (25 + random() * 95)
            WHEN 'Internet' THEN (70 + random() * 150)
            WHEN 'Telefonia' THEN (35 + random() * 110)
            WHEN 'Tarjeta de credito' THEN (180 + random() * 980)
            ELSE (120 + random() * 720)
        END::numeric,
        2
    )::double precision AS monto,
    CASE
        WHEN (a.id + mes.m + anio.y) % 15 = 0 THEN 'Pendiente'
        ELSE 'Pagado'
    END AS estado,
    (
        make_date(anio.y, mes.m, 1)
        + ((a.id + mes.m) % 24 || ' days')::interval
        + interval '10 hours'
    ) AS created_at,
    a.id AS account_id
FROM account a
JOIN "user" u ON u.id = a.user_id
CROSS JOIN generate_series(2022, 2026) AS anio(y)
CROSS JOIN generate_series(1, 12) AS mes(m)
CROSS JOIN LATERAL (
    SELECT (ARRAY[
        'Luz',
        'Agua',
        'Internet',
        'Telefonia',
        'Tarjeta de credito',
        'Prestamo'
    ])[1 + ((a.id + mes.m + anio.y) % 6)] AS nombre
) servicios
WHERE u.email LIKE '%@demo.banbif.local'
  AND a.status = 'Activa'
  AND make_date(anio.y, mes.m, 1) <= CURRENT_DATE;

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
    'FIX_PAGOS_SERVICIOS',
    'pagos',
    NULL,
    'Recalibracion de pagos demo para incluir Luz, Agua, Internet, Telefonia, Tarjeta de credito y Prestamo.'
);