/*
============================================================
02_VALIDACION_FINAL_PROYECTO.sql
Ejecutar conectado a bd_core_financiero.
No inserta, no borra y no modifica datos.
Solo valida que todo se haya creado correctamente.
============================================================
*/

-- 1. Conexion
SELECT
    current_database() AS base_actual,
    current_user AS usuario_conectado,
    NOW() AS fecha_validacion;

-- 2. Resumen general
SELECT 'Clientes Homebanking' AS modulo, COUNT(*) AS total FROM public."user"
UNION ALL SELECT 'Cuentas bancarias', COUNT(*) FROM public.account
UNION ALL SELECT 'Movimientos bancarios', COUNT(*) FROM public.movement
UNION ALL SELECT 'Pagos de servicios', COUNT(*) FROM public.pagos
UNION ALL SELECT 'Solicitudes de credito', COUNT(*) FROM public.creditapplication
UNION ALL SELECT 'Desembolsos', COUNT(*) FROM public.credit_disbursement
UNION ALL SELECT 'Cronograma de cuotas', COUNT(*) FROM public.loan_schedule
UNION ALL SELECT 'Casos de mora / recuperacion', COUNT(*) FROM public.recovery_case
UNION ALL SELECT 'Gestiones de cobranza', COUNT(*) FROM public.recovery_action
UNION ALL SELECT 'Usuarios internos Core / RBAC', COUNT(*) FROM public.core_analyst_user;

-- 3. Indicadores de cartera
WITH cartera AS (
    SELECT
        COALESCE(SUM(ca.amount) FILTER (
            WHERE ca.disbursement_status ILIKE '%desembolsado%'
        ), 0) AS cartera_total,
        COUNT(*) FILTER (
            WHERE ca.disbursement_status ILIKE '%desembolsado%'
        ) AS creditos_desembolsados,
        COUNT(DISTINCT ca.user_id) FILTER (
            WHERE ca.disbursement_status ILIKE '%desembolsado%'
        ) AS clientes_con_cartera
    FROM public.creditapplication ca
),
mora AS (
    SELECT
        COALESCE(SUM(rc.overdue_amount), 0) AS cartera_vencida,
        COUNT(*) AS casos_mora
    FROM public.recovery_case rc
)
SELECT
    ROUND(c.cartera_total::numeric, 2) AS cartera_total,
    ROUND((c.cartera_total - m.cartera_vencida)::numeric, 2) AS cartera_vigente,
    ROUND(m.cartera_vencida::numeric, 2) AS cartera_vencida,
    ROUND((m.cartera_vencida / NULLIF(c.cartera_total, 0) * 100)::numeric, 2) AS ratio_mora_porcentaje,
    c.creditos_desembolsados,
    c.clientes_con_cartera,
    m.casos_mora
FROM cartera c
CROSS JOIN mora m;

-- 4. Clientes con datos principales
SELECT
    u.id AS cliente_id,
    u.document AS dni,
    u.full_name AS cliente,
    u.email,
    u.phone AS celular,
    COUNT(DISTINCT a.id) AS total_cuentas,
    ROUND(COALESCE(SUM(DISTINCT a.balance), 0)::numeric, 2) AS saldo_total,
    COUNT(DISTINCT m.id) AS total_movimientos,
    COUNT(DISTINCT p.id) AS total_pagos,
    COUNT(DISTINCT ca.id) AS total_creditos,
    COUNT(DISTINCT rc.id) AS casos_mora
FROM public."user" u
LEFT JOIN public.account a ON a.user_id = u.id
LEFT JOIN public.movement m ON m.account_id = a.id
LEFT JOIN public.pagos p ON p.user_id = u.id
LEFT JOIN public.creditapplication ca ON ca.user_id = u.id
LEFT JOIN public.recovery_case rc ON rc.user_id = u.id
WHERE u.role = 'CLIENTE'
GROUP BY u.id, u.document, u.full_name, u.email, u.phone
ORDER BY total_creditos DESC, casos_mora DESC, saldo_total DESC
LIMIT 100;

-- 5. Creditos por estado
SELECT
    ca.status AS estado_credito,
    ca.disbursement_status AS estado_desembolso,
    COUNT(*) AS cantidad,
    ROUND(SUM(ca.amount)::numeric, 2) AS monto_total
FROM public.creditapplication ca
GROUP BY ca.status, ca.disbursement_status
ORDER BY ca.status, ca.disbursement_status;

-- 6. Detalle de creditos con reglas de negocio
SELECT
    ca.id AS solicitud_id,
    u.document AS dni,
    u.full_name AS cliente,
    ca.product AS producto,
    ROUND(ca.amount::numeric, 2) AS monto,
    ca.months AS plazo_meses,
    ROUND(ca.monthly_income::numeric, 2) AS ingreso_mensual,
    ca.status AS estado_credito,
    ca.disbursement_status AS estado_desembolso,
    ca.scoring_score AS score,
    ROUND(ca.rds_ratio::numeric, 4) AS rds,
    ca.risk_level AS riesgo,
    ca.risk_semaphore AS semaforo,
    ca.approval_route AS ruta_aprobacion
FROM public.creditapplication ca
JOIN public."user" u ON u.id = ca.user_id
ORDER BY ca.id DESC
LIMIT 150;

-- 7. Desembolsos
SELECT
    cd.id AS desembolso_id,
    ca.id AS solicitud_id,
    u.document AS dni,
    u.full_name AS cliente,
    ca.product AS producto,
    ROUND(ca.amount::numeric, 2) AS monto_credito,
    ca.status AS estado_credito,
    ca.disbursement_status AS estado_desembolso,
    cd.created_at AS fecha_desembolso
FROM public.credit_disbursement cd
JOIN public.creditapplication ca ON ca.id = cd.credit_application_id
JOIN public."user" u ON u.id = ca.user_id
ORDER BY cd.created_at DESC
LIMIT 100;

-- 8. Movimientos visibles en Homebanking
SELECT
    u.document AS dni,
    u.full_name AS cliente,
    a.account_number AS cuenta,
    m.operation_type AS tipo_operacion,
    m.description AS descripcion,
    ROUND(m.amount::numeric, 2) AS monto,
    m.created_at AS fecha
FROM public.movement m
JOIN public.account a ON a.id = m.account_id
JOIN public."user" u ON u.id = a.user_id
ORDER BY m.created_at DESC
LIMIT 150;

-- 9. Mora por bandas
SELECT
    rc.band AS banda_mora,
    COUNT(*) AS casos,
    ROUND(SUM(rc.overdue_amount)::numeric, 2) AS saldo_vencido,
    MIN(rc.days_past_due) AS min_dias_mora,
    MAX(rc.days_past_due) AS max_dias_mora
FROM public.recovery_case rc
GROUP BY rc.band
ORDER BY
    CASE rc.band
        WHEN 'Preventiva' THEN 1
        WHEN 'Temprana' THEN 2
        WHEN 'Tardia' THEN 3
        WHEN 'Judicial' THEN 4
        WHEN 'Castigo' THEN 5
        ELSE 9
    END;

-- 10. Detalle de recuperaciones
SELECT
    rc.id AS caso_id,
    ca.id AS solicitud_id,
    u.document AS dni,
    u.full_name AS cliente,
    ca.product AS producto,
    ROUND(rc.overdue_amount::numeric, 2) AS saldo_vencido,
    rc.days_past_due AS dias_mora,
    rc.band AS banda,
    rc.status AS estado_recuperacion,
    rc.created_at AS fecha_creacion
FROM public.recovery_case rc
JOIN public.creditapplication ca ON ca.id = rc.credit_application_id
JOIN public."user" u ON u.id = rc.user_id
ORDER BY rc.days_past_due DESC;

-- 11. Historial de gestiones
SELECT
    rc.id AS caso_id,
    u.full_name AS cliente,
    rc.band AS banda,
    rc.days_past_due AS dias_mora,
    ra.action_type AS tipo_gestion,
    ra.comment AS comentario,
    ra.result AS resultado,
    ra.created_at AS fecha_gestion
FROM public.recovery_action ra
JOIN public.recovery_case rc ON rc.id = ra.recovery_case_id
JOIN public."user" u ON u.id = rc.user_id
ORDER BY ra.created_at DESC
LIMIT 150;

-- 12. Casos listos para judicializar
SELECT
    rc.id AS caso_id,
    ca.id AS solicitud_id,
    u.document AS dni,
    u.full_name AS cliente,
    rc.band AS banda,
    rc.days_past_due AS dias_mora,
    ROUND(rc.overdue_amount::numeric, 2) AS saldo_vencido,
    rc.status AS estado
FROM public.recovery_case rc
JOIN public.creditapplication ca ON ca.id = rc.credit_application_id
JOIN public."user" u ON u.id = rc.user_id
WHERE rc.band = 'Tardia'
  AND rc.days_past_due >= 121
ORDER BY rc.days_past_due DESC;

-- 13. Casos listos para castigo
SELECT
    rc.id AS caso_id,
    ca.id AS solicitud_id,
    u.document AS dni,
    u.full_name AS cliente,
    rc.band AS banda,
    rc.days_past_due AS dias_mora,
    ROUND(rc.overdue_amount::numeric, 2) AS saldo_vencido,
    rc.status AS estado
FROM public.recovery_case rc
JOIN public.creditapplication ca ON ca.id = rc.credit_application_id
JOIN public."user" u ON u.id = rc.user_id
WHERE rc.band = 'Judicial'
  AND rc.days_past_due > 180
ORDER BY rc.days_past_due DESC;

-- 14. Usuarios Core / roles
SELECT *
FROM public.core_analyst_user
ORDER BY id;

-- 15. Vistas Power BI
SELECT table_name AS vista_powerbi
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name ILIKE 'vw_pbi%'
ORDER BY table_name;

