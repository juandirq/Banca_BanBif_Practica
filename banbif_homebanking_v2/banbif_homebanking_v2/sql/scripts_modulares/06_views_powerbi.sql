-- 06_views_powerbi.sql
-- Vistas finales para Power BI / reportes
-- Proyecto BanBif - bd_core_financiero

DROP VIEW IF EXISTS vw_pbi_operaciones_banbif CASCADE;
DROP VIEW IF EXISTS vw_pbi_resumen_general CASCADE;
DROP VIEW IF EXISTS vw_pbi_mora CASCADE;
DROP VIEW IF EXISTS vw_pbi_transacciones CASCADE;
DROP VIEW IF EXISTS vw_pbi_pagos CASCADE;
DROP VIEW IF EXISTS vw_pbi_creditos CASCADE;
DROP VIEW IF EXISTS vw_pbi_cuentas CASCADE;
DROP VIEW IF EXISTS vw_pbi_clientes CASCADE;
DROP VIEW IF EXISTS vw_pbi_roles_core CASCADE;

CREATE OR REPLACE VIEW vw_pbi_clientes AS
SELECT
    u.id AS cliente_id,
    u.document AS documento,
    u.full_name AS cliente_nombre,
    u.email,
    u.phone AS telefono,
    u.address AS direccion,
    u.role AS rol,
    u.is_active AS activo,
    u.created_at AS fecha_registro,
    EXTRACT(YEAR FROM u.created_at)::int AS anio_registro
FROM "user" u;

CREATE OR REPLACE VIEW vw_pbi_cuentas AS
SELECT
    a.id AS cuenta_id,
    a.user_id AS cliente_id,
    u.full_name AS cliente_nombre,
    a.account_number AS numero_cuenta,
    a.account_type AS tipo_cuenta,
    a.currency AS moneda,
    a.balance AS saldo,
    a.status AS estado_cuenta,
    a.created_at AS fecha_creacion,
    EXTRACT(YEAR FROM a.created_at)::int AS anio
FROM account a
JOIN "user" u ON u.id = a.user_id;

CREATE OR REPLACE VIEW vw_pbi_transacciones AS
SELECT
    m.id AS transaccion_id,
    a.user_id AS cliente_id,
    u.full_name AS cliente_nombre,
    a.id AS cuenta_id,
    a.account_number AS numero_cuenta,
    m.operation_type AS tipo_operacion,
    m.description AS descripcion,
    m.amount AS monto,
    m.created_at AS fecha,
    EXTRACT(YEAR FROM m.created_at)::int AS anio,
    EXTRACT(MONTH FROM m.created_at)::int AS mes,
    TO_CHAR(m.created_at, 'YYYY-MM') AS anio_mes
FROM movement m
JOIN account a ON a.id = m.account_id
JOIN "user" u ON u.id = a.user_id;

CREATE OR REPLACE VIEW vw_pbi_pagos AS
SELECT
    p.id AS pago_id,
    p.user_id AS cliente_id,
    u.full_name AS cliente_nombre,
    p.account_id AS cuenta_id,
    a.account_number AS numero_cuenta,
    p.servicio,
    p.numero_contrato AS contrato,
    p.monto AS monto_pagado,
    p.estado AS estado_pago,
    p.created_at AS fecha_pago,
    EXTRACT(YEAR FROM p.created_at)::int AS anio,
    EXTRACT(MONTH FROM p.created_at)::int AS mes,
    TO_CHAR(p.created_at, 'YYYY-MM') AS anio_mes
FROM pagos p
JOIN "user" u ON u.id = p.user_id
LEFT JOIN account a ON a.id = p.account_id;

CREATE OR REPLACE VIEW vw_pbi_creditos AS
SELECT
    c.id AS solicitud_id,
    c.user_id AS cliente_id,
    u.full_name AS cliente_nombre,
    c.product AS producto,
    c.amount AS monto_solicitado,
    c.months AS plazo_meses,
    c.monthly_income AS ingreso_mensual,
    c.estimated_installment AS cuota_estimada,
    c.rds_ratio AS rds,
    ROUND((c.rds_ratio * 100)::numeric, 2) AS rds_porcentaje,
    c.scoring_score AS score,
    c.risk_level AS riesgo,
    c.risk_semaphore AS semaforo,
    c.approval_route AS ruta_aprobacion,
    c.required_approval_level AS nivel_requerido,
    c.status AS estado_credito,
    c.disbursement_status AS estado_desembolso,
    c.analyst_comment AS comentario_analista,
    c.created_at AS fecha_solicitud,
    c.evaluated_at AS fecha_evaluacion,
    au.full_name AS evaluado_por,
    au.position_name AS cargo_evaluador,
    au.max_approval_amount AS autonomia_evaluador,
    EXTRACT(YEAR FROM c.created_at)::int AS anio,
    EXTRACT(MONTH FROM c.created_at)::int AS mes,
    TO_CHAR(c.created_at, 'YYYY-MM') AS anio_mes
FROM creditapplication c
JOIN "user" u ON u.id = c.user_id
LEFT JOIN core_analyst_user au ON au.id = c.evaluated_by;

CREATE OR REPLACE VIEW vw_pbi_mora AS
SELECT
    rc.id AS caso_mora_id,
    rc.credit_application_id AS solicitud_id,
    rc.user_id AS cliente_id,
    u.full_name AS cliente_nombre,
    c.product AS producto,
    c.amount AS monto_credito,
    rc.overdue_amount AS monto_mora,
    rc.days_past_due AS dias_mora,
    rc.band AS banda_mora,
    rc.status AS estado_mora,
    au.full_name AS asignado_a,
    au.position_name AS cargo_asignado,
    rc.created_at AS fecha_creacion,
    rc.updated_at AS fecha_actualizacion,
    EXTRACT(YEAR FROM rc.created_at)::int AS anio
FROM recovery_case rc
JOIN "user" u ON u.id = rc.user_id
JOIN creditapplication c ON c.id = rc.credit_application_id
LEFT JOIN core_analyst_user au ON au.id = rc.assigned_to;

CREATE OR REPLACE VIEW vw_pbi_roles_core AS
SELECT
    au.id AS usuario_core_id,
    au.full_name AS nombre,
    au.username,
    au.role AS rol,
    au.position_name AS cargo,
    au.approval_level AS nivel_aprobacion,
    au.max_approval_amount AS monto_maximo_aprobacion,
    au.is_active AS activo,
    COUNT(rp.permission_code) AS total_permisos
FROM core_analyst_user au
LEFT JOIN core_role_permission rp ON rp.role = au.role
GROUP BY
    au.id,
    au.full_name,
    au.username,
    au.role,
    au.position_name,
    au.approval_level,
    au.max_approval_amount,
    au.is_active;

CREATE OR REPLACE VIEW vw_pbi_resumen_general AS
SELECT
    u.id AS cliente_id,
    u.full_name AS cliente_nombre,
    COUNT(DISTINCT a.id) AS total_cuentas,
    COALESCE(SUM(DISTINCT a.balance), 0) AS saldo_total,
    COUNT(DISTINCT m.id) AS total_transacciones,
    COUNT(DISTINCT p.id) AS total_pagos,
    COUNT(DISTINCT c.id) AS total_creditos,
    COUNT(DISTINCT d.id) AS total_desembolsos,
    COUNT(DISTINCT rc.id) AS total_casos_mora
FROM "user" u
LEFT JOIN account a ON a.user_id = u.id
LEFT JOIN movement m ON m.account_id = a.id
LEFT JOIN pagos p ON p.user_id = u.id
LEFT JOIN creditapplication c ON c.user_id = u.id
LEFT JOIN credit_disbursement d ON d.credit_application_id = c.id
LEFT JOIN recovery_case rc ON rc.user_id = u.id
GROUP BY u.id, u.full_name;

CREATE OR REPLACE VIEW vw_pbi_operaciones_banbif AS
SELECT
    'Transaccion' AS modulo,
    m.id AS operacion_id,
    u.id AS cliente_id,
    u.full_name AS cliente_nombre,
    m.operation_type AS tipo,
    m.description AS descripcion,
    m.amount AS monto,
    'Registrado' AS estado,
    m.created_at AS fecha,
    EXTRACT(YEAR FROM m.created_at)::int AS anio,
    TO_CHAR(m.created_at, 'YYYY-MM') AS anio_mes
FROM movement m
JOIN account a ON a.id = m.account_id
JOIN "user" u ON u.id = a.user_id

UNION ALL

SELECT
    'Pago' AS modulo,
    p.id AS operacion_id,
    u.id AS cliente_id,
    u.full_name AS cliente_nombre,
    p.servicio AS tipo,
    p.numero_contrato AS descripcion,
    p.monto AS monto,
    p.estado AS estado,
    p.created_at AS fecha,
    EXTRACT(YEAR FROM p.created_at)::int AS anio,
    TO_CHAR(p.created_at, 'YYYY-MM') AS anio_mes
FROM pagos p
JOIN "user" u ON u.id = p.user_id

UNION ALL

SELECT
    'Credito' AS modulo,
    c.id AS operacion_id,
    u.id AS cliente_id,
    u.full_name AS cliente_nombre,
    c.product AS tipo,
    c.purpose AS descripcion,
    c.amount AS monto,
    c.status AS estado,
    c.created_at AS fecha,
    EXTRACT(YEAR FROM c.created_at)::int AS anio,
    TO_CHAR(c.created_at, 'YYYY-MM') AS anio_mes
FROM creditapplication c
JOIN "user" u ON u.id = c.user_id

UNION ALL

SELECT
    'Mora' AS modulo,
    rc.id AS operacion_id,
    u.id AS cliente_id,
    u.full_name AS cliente_nombre,
    rc.band AS tipo,
    rc.status AS descripcion,
    rc.overdue_amount AS monto,
    rc.status AS estado,
    rc.created_at AS fecha,
    EXTRACT(YEAR FROM rc.created_at)::int AS anio,
    TO_CHAR(rc.created_at, 'YYYY-MM') AS anio_mes
FROM recovery_case rc
JOIN "user" u ON u.id = rc.user_id;

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
    'CREATE_POWERBI_VIEWS',
    'views',
    NULL,
    'Creacion de vistas finales para Power BI: clientes, cuentas, transacciones, pagos, creditos, mora, roles core y resumen general.'
);