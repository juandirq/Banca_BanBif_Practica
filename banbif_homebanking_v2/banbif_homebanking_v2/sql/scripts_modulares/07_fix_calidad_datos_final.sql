-- 07_fix_calidad_datos_final.sql
-- Ajustes finales de calidad de datos para demo realista BanBif
-- Evita fechas futuras y corrige nombres con caracteres raros

-- 1. Corregir nombres demo con caracteres mal codificados
UPDATE "user"
SET full_name = 'Beatriz Nunez Arias'
WHERE full_name LIKE 'Beatriz%';

UPDATE "user"
SET full_name = 'Milagros Ramos Nunez'
WHERE full_name LIKE 'Milagros%';

-- 2. Evitar solicitudes de credito con fecha futura
UPDATE creditapplication
SET
    created_at = (
        CURRENT_DATE
        - ((id % 150) + 1 || ' days')::interval
    ),
    evaluated_at = (
        CURRENT_DATE
        - ((id % 150) || ' days')::interval
    )
WHERE created_at::date > CURRENT_DATE;

-- 3. Evitar pagos con fecha futura
UPDATE pagos
SET created_at = (
    CURRENT_DATE
    - ((id % 180) + 1 || ' days')::interval
    + interval '10 hours'
)
WHERE created_at::date > CURRENT_DATE;

-- 4. Evitar movimientos con fecha futura
UPDATE movement
SET created_at = (
    CURRENT_DATE
    - ((id % 180) + 1 || ' days')::interval
    + interval '9 hours'
)
WHERE created_at::date > CURRENT_DATE;

-- 5. Ajustar desembolsos futuros si existieran
UPDATE credit_disbursement d
SET created_at = c.evaluated_at + interval '1 day'
FROM creditapplication c
WHERE d.credit_application_id = c.id
  AND d.created_at::date > CURRENT_DATE;

-- 6. Auditoria
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
    'FIX_CALIDAD_DATOS_FINAL',
    'datos_demo',
    NULL,
    'Se corrigen fechas futuras y nombres con caracteres raros para una demo bancaria mas realista.'
);