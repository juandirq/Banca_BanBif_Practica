-- 02C_normalizar_roles_banbif.sql
-- Roles internos realistas para BanBif
-- Enfoque: Analista de Creditos por nivel de autonomia, escalamiento por monto/riesgo

-- =========================================================
-- 1. Normalizar usuarios internos existentes
-- =========================================================

UPDATE core_analyst_user
SET role = 'ANALISTA_N1',
    position_name = 'Analista de Creditos Nivel 1',
    approval_level = 1,
    max_approval_amount = 3000
WHERE username = 'ana.rojas';

UPDATE core_analyst_user
SET role = 'ANALISTA_N2',
    position_name = 'Analista de Creditos Nivel 2',
    approval_level = 2,
    max_approval_amount = 7000
WHERE username = 'luis.paredes';

UPDATE core_analyst_user
SET role = 'ANALISTA_N3',
    position_name = 'Analista de Creditos Nivel 3',
    approval_level = 3,
    max_approval_amount = 12000
WHERE username = 'maria.torres';

UPDATE core_analyst_user
SET role = 'ANALISTA_N4',
    position_name = 'Analista de Creditos Nivel 4',
    approval_level = 4,
    max_approval_amount = 25000
WHERE username = 'carlos.rivas';

UPDATE core_analyst_user
SET role = 'SENIOR_CREDITOS',
    position_name = 'Analista Senior de Creditos',
    approval_level = 5,
    max_approval_amount = 40000
WHERE username = 'lucia.salazar';

UPDATE core_analyst_user
SET role = 'RIESGOS',
    position_name = 'Especialista de Riesgos Crediticios',
    approval_level = 7,
    max_approval_amount = 100000
WHERE username = 'jorge.medina';

UPDATE core_analyst_user
SET role = 'COMITE',
    position_name = 'Comite de Creditos',
    approval_level = 9,
    max_approval_amount = 999999
WHERE username = 'comite.creditos';

UPDATE core_analyst_user
SET role = 'ADMIN',
    position_name = 'Administrador del Sistema',
    approval_level = 10,
    max_approval_amount = 999999
WHERE username = 'admin.core';

-- =========================================================
-- 2. Agregar Administrador de Agencia
-- =========================================================

INSERT INTO core_analyst_user (
    full_name,
    username,
    email,
    role,
    position_name,
    approval_level,
    max_approval_amount,
    password_hash,
    is_active
)
VALUES (
    'Patricia Valdez Rivas',
    'admin.agencia',
    'admin.agencia@banbif.local',
    'ADMIN_AGENCIA',
    'Administrador de Agencia',
    6,
    60000,
    crypt('123456', gen_salt('bf')),
    TRUE
)
ON CONFLICT (username)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    position_name = EXCLUDED.position_name,
    approval_level = EXCLUDED.approval_level,
    max_approval_amount = EXCLUDED.max_approval_amount,
    is_active = TRUE;

-- =========================================================
-- 3. Agregar Gerencia
-- =========================================================

INSERT INTO core_analyst_user (
    full_name,
    username,
    email,
    role,
    position_name,
    approval_level,
    max_approval_amount,
    password_hash,
    is_active
)
VALUES (
    'Gerencia de Finanzas BanBif',
    'gerencia.finanzas',
    'gerencia.finanzas@banbif.local',
    'GERENCIA',
    'Gerencia de Finanzas',
    8,
    150000,
    crypt('123456', gen_salt('bf')),
    TRUE
)
ON CONFLICT (username)
DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    position_name = EXCLUDED.position_name,
    approval_level = EXCLUDED.approval_level,
    max_approval_amount = EXCLUDED.max_approval_amount,
    is_active = TRUE;

-- =========================================================
-- 4. Limpiar permisos antiguos y nuevos para reconstruir matriz RBAC
-- =========================================================

DELETE FROM core_role_permission
WHERE role IN (
    'ASESOR_JUNIOR_1',
    'ASESOR_JUNIOR_2',
    'ANALISTA_JUNIOR',
    'ANALISTA_SENIOR',
    'SUPERVISOR',
    'ANALISTA_N1',
    'ANALISTA_N2',
    'ANALISTA_N3',
    'ANALISTA_N4',
    'SENIOR_CREDITOS',
    'ADMIN_AGENCIA',
    'GERENCIA',
    'RIESGOS',
    'COMITE',
    'ADMIN'
);

-- =========================================================
-- 5. Matriz de permisos RBAC por rol
-- =========================================================

INSERT INTO core_role_permission (role, permission_code) VALUES
-- Analista Nivel 1
('ANALISTA_N1', 'CREDIT_VIEW'),
('ANALISTA_N1', 'CREDIT_EVALUATE'),
('ANALISTA_N1', 'CREDIT_APPROVE_LOW'),

-- Analista Nivel 2
('ANALISTA_N2', 'CREDIT_VIEW'),
('ANALISTA_N2', 'CREDIT_EVALUATE'),
('ANALISTA_N2', 'CREDIT_APPROVE_LOW'),

-- Analista Nivel 3
('ANALISTA_N3', 'CREDIT_VIEW'),
('ANALISTA_N3', 'CREDIT_EVALUATE'),
('ANALISTA_N3', 'CREDIT_APPROVE_LOW'),
('ANALISTA_N3', 'CREDIT_APPROVE_MEDIUM'),

-- Analista Nivel 4
('ANALISTA_N4', 'CREDIT_VIEW'),
('ANALISTA_N4', 'CREDIT_EVALUATE'),
('ANALISTA_N4', 'CREDIT_APPROVE_LOW'),
('ANALISTA_N4', 'CREDIT_APPROVE_MEDIUM'),
('ANALISTA_N4', 'CREDIT_APPROVE_HIGH'),

-- Senior Creditos
('SENIOR_CREDITOS', 'CREDIT_VIEW'),
('SENIOR_CREDITOS', 'CREDIT_EVALUATE'),
('SENIOR_CREDITOS', 'CREDIT_APPROVE_LOW'),
('SENIOR_CREDITOS', 'CREDIT_APPROVE_MEDIUM'),
('SENIOR_CREDITOS', 'CREDIT_APPROVE_HIGH'),
('SENIOR_CREDITOS', 'CREDIT_DISBURSE'),
('SENIOR_CREDITOS', 'RECOVERY_VIEW'),

-- Administrador de Agencia
('ADMIN_AGENCIA', 'CREDIT_VIEW'),
('ADMIN_AGENCIA', 'CREDIT_EVALUATE'),
('ADMIN_AGENCIA', 'CREDIT_APPROVE_LOW'),
('ADMIN_AGENCIA', 'CREDIT_APPROVE_MEDIUM'),
('ADMIN_AGENCIA', 'CREDIT_APPROVE_HIGH'),
('ADMIN_AGENCIA', 'CREDIT_SEND_COMMITTEE'),
('ADMIN_AGENCIA', 'CREDIT_DISBURSE'),
('ADMIN_AGENCIA', 'RECOVERY_VIEW'),
('ADMIN_AGENCIA', 'RECOVERY_MANAGE'),

-- Riesgos
('RIESGOS', 'CREDIT_VIEW'),
('RIESGOS', 'CREDIT_EVALUATE'),
('RIESGOS', 'CREDIT_SEND_COMMITTEE'),
('RIESGOS', 'RECOVERY_VIEW'),
('RIESGOS', 'RECOVERY_MANAGE'),
('RIESGOS', 'RECOVERY_JUDICIAL'),

-- Gerencia
('GERENCIA', 'CREDIT_VIEW'),
('GERENCIA', 'CREDIT_EVALUATE'),
('GERENCIA', 'CREDIT_APPROVE_HIGH'),
('GERENCIA', 'CREDIT_SEND_COMMITTEE'),
('GERENCIA', 'CREDIT_DISBURSE'),
('GERENCIA', 'RECOVERY_VIEW'),
('GERENCIA', 'RECOVERY_MANAGE'),
('GERENCIA', 'RECOVERY_JUDICIAL'),

-- Comite
('COMITE', 'CREDIT_VIEW'),
('COMITE', 'CREDIT_EVALUATE'),
('COMITE', 'CREDIT_APPROVE_HIGH'),
('COMITE', 'CREDIT_DISBURSE'),
('COMITE', 'RECOVERY_VIEW'),
('COMITE', 'RECOVERY_JUDICIAL'),
('COMITE', 'RECOVERY_WRITE_OFF'),

-- Admin Sistema
('ADMIN', 'CREDIT_VIEW'),
('ADMIN', 'CREDIT_EVALUATE'),
('ADMIN', 'CREDIT_APPROVE_LOW'),
('ADMIN', 'CREDIT_APPROVE_MEDIUM'),
('ADMIN', 'CREDIT_APPROVE_HIGH'),
('ADMIN', 'CREDIT_SEND_COMMITTEE'),
('ADMIN', 'CREDIT_DISBURSE'),
('ADMIN', 'RECOVERY_VIEW'),
('ADMIN', 'RECOVERY_MANAGE'),
('ADMIN', 'RECOVERY_JUDICIAL'),
('ADMIN', 'RECOVERY_WRITE_OFF'),
('ADMIN', 'ADMIN_USERS')
ON CONFLICT (role, permission_code) DO NOTHING;

-- =========================================================
-- 6. Actualizar ruta de aprobacion de creditos
-- =========================================================

UPDATE creditapplication
SET approval_route = CASE
    WHEN status = 'En comite' THEN 'COMITE'
    WHEN risk_level = 'ALTO' AND amount > 12000 THEN 'RIESGOS'
    WHEN amount <= 3000 THEN 'ANALISTA_N1'
    WHEN amount <= 7000 THEN 'ANALISTA_N2'
    WHEN amount <= 12000 THEN 'ANALISTA_N3'
    WHEN amount <= 25000 THEN 'ANALISTA_N4'
    WHEN amount <= 40000 THEN 'SENIOR_CREDITOS'
    WHEN amount <= 60000 THEN 'ADMIN_AGENCIA'
    WHEN amount <= 150000 THEN 'GERENCIA'
    ELSE 'COMITE'
END,
required_approval_level = CASE
    WHEN status = 'En comite' THEN 9
    WHEN risk_level = 'ALTO' AND amount > 12000 THEN 7
    WHEN amount <= 3000 THEN 1
    WHEN amount <= 7000 THEN 2
    WHEN amount <= 12000 THEN 3
    WHEN amount <= 25000 THEN 4
    WHEN amount <= 40000 THEN 5
    WHEN amount <= 60000 THEN 6
    WHEN amount <= 150000 THEN 8
    ELSE 9
END;

-- =========================================================
-- 7. Reasignar evaluador segun nueva ruta
-- =========================================================

UPDATE creditapplication c
SET evaluated_by = (
    SELECT au.id
    FROM core_analyst_user au
    WHERE au.role = c.approval_route
    ORDER BY au.approval_level
    LIMIT 1
)
WHERE c.approval_route IN (
    'ANALISTA_N1',
    'ANALISTA_N2',
    'ANALISTA_N3',
    'ANALISTA_N4',
    'SENIOR_CREDITOS',
    'ADMIN_AGENCIA',
    'RIESGOS',
    'GERENCIA',
    'COMITE'
);

-- =========================================================
-- 8. Auditoria
-- =========================================================

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
    'NORMALIZAR_ROLES_BANBIF',
    'core_analyst_user/core_role_permission/creditapplication',
    NULL,
    'Se normaliza la estructura interna a Analista de Creditos por niveles de autonomia, con escalamiento a Senior, Administrador de Agencia, Riesgos, Gerencia y Comite.'
);