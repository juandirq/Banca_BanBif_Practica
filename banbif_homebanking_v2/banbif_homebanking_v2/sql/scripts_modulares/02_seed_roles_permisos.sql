-- =========================================================
-- 02_seed_roles_permisos.sql
-- Roles, niveles internos, permisos RBAC y usuarios del Core
-- Proyecto BanBif - BD local bd_core_financiero
-- =========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- PERMISOS DEL CORE
-- =========================================================

INSERT INTO core_permission (code, description) VALUES
('CREDIT_VIEW', 'Ver solicitudes de credito'),
('CREDIT_EVALUATE', 'Evaluar scoring, RDS y riesgo crediticio'),
('CREDIT_APPROVE_LOW', 'Aprobar creditos de bajo monto'),
('CREDIT_APPROVE_MEDIUM', 'Aprobar creditos de monto medio'),
('CREDIT_APPROVE_HIGH', 'Aprobar creditos de monto alto'),
('CREDIT_SEND_COMMITTEE', 'Enviar solicitud a comite'),
('CREDIT_DISBURSE', 'Desembolsar credito aprobado'),
('RECOVERY_VIEW', 'Consultar cartera morosa'),
('RECOVERY_MANAGE', 'Registrar gestiones de cobranza'),
('RECOVERY_JUDICIAL', 'Derivar credito a judicial'),
('RECOVERY_WRITE_OFF', 'Castigar credito'),
('ADMIN_USERS', 'Administrar usuarios internos')
ON CONFLICT (code) DO UPDATE SET
description = EXCLUDED.description;

-- =========================================================
-- MATRIZ DE PERMISOS POR ROL
-- =========================================================

-- Asesor Junior 1: consulta y evalua casos pequeños
INSERT INTO core_role_permission (role, permission_code) VALUES
('ASESOR_JUNIOR_1', 'CREDIT_VIEW'),
('ASESOR_JUNIOR_1', 'CREDIT_EVALUATE'),
('ASESOR_JUNIOR_1', 'CREDIT_APPROVE_LOW')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Asesor Junior 2: casos pequeños y medianos iniciales
INSERT INTO core_role_permission (role, permission_code) VALUES
('ASESOR_JUNIOR_2', 'CREDIT_VIEW'),
('ASESOR_JUNIOR_2', 'CREDIT_EVALUATE'),
('ASESOR_JUNIOR_2', 'CREDIT_APPROVE_LOW'),
('ASESOR_JUNIOR_2', 'CREDIT_APPROVE_MEDIUM')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Analista Junior
INSERT INTO core_role_permission (role, permission_code) VALUES
('ANALISTA_JUNIOR', 'CREDIT_VIEW'),
('ANALISTA_JUNIOR', 'CREDIT_EVALUATE'),
('ANALISTA_JUNIOR', 'CREDIT_APPROVE_LOW'),
('ANALISTA_JUNIOR', 'CREDIT_APPROVE_MEDIUM')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Analista Senior
INSERT INTO core_role_permission (role, permission_code) VALUES
('ANALISTA_SENIOR', 'CREDIT_VIEW'),
('ANALISTA_SENIOR', 'CREDIT_EVALUATE'),
('ANALISTA_SENIOR', 'CREDIT_APPROVE_LOW'),
('ANALISTA_SENIOR', 'CREDIT_APPROVE_MEDIUM'),
('ANALISTA_SENIOR', 'CREDIT_APPROVE_HIGH'),
('ANALISTA_SENIOR', 'CREDIT_SEND_COMMITTEE'),
('ANALISTA_SENIOR', 'CREDIT_DISBURSE'),
('ANALISTA_SENIOR', 'RECOVERY_VIEW')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Supervisor
INSERT INTO core_role_permission (role, permission_code) VALUES
('SUPERVISOR', 'CREDIT_VIEW'),
('SUPERVISOR', 'CREDIT_EVALUATE'),
('SUPERVISOR', 'CREDIT_APPROVE_LOW'),
('SUPERVISOR', 'CREDIT_APPROVE_MEDIUM'),
('SUPERVISOR', 'CREDIT_APPROVE_HIGH'),
('SUPERVISOR', 'CREDIT_SEND_COMMITTEE'),
('SUPERVISOR', 'CREDIT_DISBURSE'),
('SUPERVISOR', 'RECOVERY_VIEW'),
('SUPERVISOR', 'RECOVERY_MANAGE')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Riesgos
INSERT INTO core_role_permission (role, permission_code) VALUES
('RIESGOS', 'CREDIT_VIEW'),
('RIESGOS', 'CREDIT_EVALUATE'),
('RIESGOS', 'CREDIT_APPROVE_HIGH'),
('RIESGOS', 'CREDIT_SEND_COMMITTEE'),
('RIESGOS', 'RECOVERY_VIEW'),
('RIESGOS', 'RECOVERY_MANAGE'),
('RIESGOS', 'RECOVERY_JUDICIAL')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Comite
INSERT INTO core_role_permission (role, permission_code) VALUES
('COMITE', 'CREDIT_VIEW'),
('COMITE', 'CREDIT_EVALUATE'),
('COMITE', 'CREDIT_APPROVE_HIGH'),
('COMITE', 'CREDIT_DISBURSE'),
('COMITE', 'RECOVERY_VIEW'),
('COMITE', 'RECOVERY_JUDICIAL'),
('COMITE', 'RECOVERY_WRITE_OFF')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Admin
INSERT INTO core_role_permission (role, permission_code) VALUES
('ADMIN', 'CREDIT_VIEW'),
('ADMIN', 'CREDIT_EVALUATE'),
('ADMIN', 'CREDIT_APPROVE_LOW'),
('ADMIN', 'CREDIT_APPROVE_MEDIUM'),
('ADMIN', 'CREDIT_APPROVE_HIGH'),
('ADMIN', 'CREDIT_SEND_COMMITTEE'),
('ADMIN', 'CREDIT_DISBURSE'),
('ADMIN_USERS', 'ADMIN_USERS'),
('ADMIN', 'RECOVERY_VIEW'),
('ADMIN', 'RECOVERY_MANAGE'),
('ADMIN', 'RECOVERY_JUDICIAL'),
('ADMIN', 'RECOVERY_WRITE_OFF'),
('ADMIN', 'ADMIN_USERS')
ON CONFLICT (role, permission_code) DO NOTHING;

-- Corregir si se insertó una fila accidental con role ADMIN_USERS
DELETE FROM core_role_permission WHERE role = 'ADMIN_USERS' AND permission_code = 'ADMIN_USERS';

-- =========================================================
-- USUARIOS INTERNOS DEL CORE
-- clave demo para todos: 123456
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
VALUES
(
    'Ana Rojas',
    'ana.rojas',
    'ana.rojas@banbif.local',
    'ASESOR_JUNIOR_1',
    'Asesor Junior 1',
    1,
    3000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Luis Paredes',
    'luis.paredes',
    'luis.paredes@banbif.local',
    'ASESOR_JUNIOR_2',
    'Asesor Junior 2',
    2,
    7000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Maria Torres',
    'maria.torres',
    'maria.torres@banbif.local',
    'ANALISTA_JUNIOR',
    'Analista Junior',
    3,
    12000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Carlos Rivas',
    'carlos.rivas',
    'carlos.rivas@banbif.local',
    'ANALISTA_SENIOR',
    'Analista Senior',
    4,
    25000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Lucia Salazar',
    'lucia.salazar',
    'lucia.salazar@banbif.local',
    'SUPERVISOR',
    'Supervisor de Creditos',
    5,
    50000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Jorge Medina',
    'jorge.medina',
    'jorge.medina@banbif.local',
    'RIESGOS',
    'Especialista de Riesgos',
    6,
    100000,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Comite Creditos',
    'comite.creditos',
    'comite.creditos@banbif.local',
    'COMITE',
    'Comite de Creditos',
    7,
    999999,
    crypt('123456', gen_salt('bf')),
    TRUE
),
(
    'Administrador Core',
    'admin.core',
    'admin.core@banbif.local',
    'ADMIN',
    'Administrador del Sistema',
    8,
    999999,
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
    password_hash = EXCLUDED.password_hash,
    is_active = TRUE;

-- =========================================================
-- AUDITORIA INICIAL
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
    'SEED_ROLES_PERMISOS',
    'core_analyst_user',
    NULL,
    'Carga inicial de roles, permisos, niveles de aprobacion y usuarios internos del core.'
);
