/*
============================================================
01_TODO_SCHEMA_Y_DATOS.sql
Base destino: bd_core_financiero

Este archivo unifica schema, seeds, roles, usuarios Core,
clientes, cuentas, movimientos, pagos, creditos, desembolsos,
mora, recuperaciones, Power BI y fixes finales.

Generado: 20260609_231041
============================================================
*/



-- ============================================================
-- INICIO: 01_schema_local.sql
-- ============================================================


-- =========================================================
-- 01_schema_local.sql
-- Esquema local PostgreSQL para Proyecto BanBif
-- Core Financiero + Homebanking integrados
-- BD: bd_core_financiero
-- =========================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- CLIENTES HOMEBANKING
-- Tabla compatible con el portal actual
-- =========================================================

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    document VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    role VARCHAR(30) NOT NULL DEFAULT 'CLIENTE',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- CUENTAS
-- Compatible con portal actual
-- =========================================================

CREATE TABLE account (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    account_number VARCHAR(30) UNIQUE NOT NULL,
    account_type VARCHAR(60) NOT NULL DEFAULT 'Cuenta Ahorro Digital',
    currency VARCHAR(10) NOT NULL DEFAULT 'PEN',
    balance DOUBLE PRECISION NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'Activa',
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- MOVIMIENTOS
-- Compatible con portal actual
-- =========================================================

CREATE TABLE movement (
    id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    operation_type VARCHAR(40) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- USUARIOS INTERNOS DEL CORE
-- Incluye rol, cargo, nivel y monto maximo de aprobacion
-- =========================================================

CREATE TABLE core_analyst_user (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    username VARCHAR(80) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE,
    role VARCHAR(40) NOT NULL DEFAULT 'ANALISTA',
    position_name VARCHAR(80) NOT NULL DEFAULT 'Analista de Creditos',
    approval_level INTEGER NOT NULL DEFAULT 1,
    max_approval_amount DOUBLE PRECISION NOT NULL DEFAULT 10000,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- PERMISOS PARA RBAC
-- Matriz de permisos por rol
-- =========================================================

CREATE TABLE core_permission (
    id SERIAL PRIMARY KEY,
    code VARCHAR(80) UNIQUE NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE core_role_permission (
    id SERIAL PRIMARY KEY,
    role VARCHAR(40) NOT NULL,
    permission_code VARCHAR(80) NOT NULL REFERENCES core_permission(code) ON DELETE CASCADE,
    UNIQUE(role, permission_code)
);

-- =========================================================
-- SOLICITUDES DE CREDITO
-- Compatible con tu app actual, pero ampliada para rubrica
-- =========================================================

CREATE TABLE creditapplication (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    product VARCHAR(80) NOT NULL,
    amount DOUBLE PRECISION NOT NULL,
    months INTEGER NOT NULL,
    monthly_income DOUBLE PRECISION NOT NULL,
    purpose TEXT,
    status VARCHAR(40) NOT NULL DEFAULT 'En evaluacion',
    analyst_comment TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),

    -- Campos nuevos para reglas de negocio
    estimated_installment DOUBLE PRECISION DEFAULT 0,
    rds_ratio DOUBLE PRECISION DEFAULT 0,
    scoring_score INTEGER DEFAULT 0,
    risk_level VARCHAR(20) DEFAULT 'SIN EVALUAR',
    risk_semaphore VARCHAR(20) DEFAULT 'GRIS',
    approval_route VARCHAR(80) DEFAULT 'PENDIENTE',
    required_approval_level INTEGER DEFAULT 1,
    evaluated_by INTEGER REFERENCES core_analyst_user(id),
    evaluated_at TIMESTAMP WITHOUT TIME ZONE,
    disbursement_status VARCHAR(40) NOT NULL DEFAULT 'No desembolsado'
);

-- =========================================================
-- PAGOS DE SERVICIOS
-- Compatible con portal actual
-- =========================================================

CREATE TABLE pagos (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    servicio VARCHAR(80) NOT NULL,
    numero_contrato VARCHAR(80),
    monto DOUBLE PRECISION NOT NULL,
    estado VARCHAR(40) NOT NULL DEFAULT 'Pagado',
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    account_id INTEGER REFERENCES account(id) ON DELETE SET NULL
);

-- =========================================================
-- DESEMBOLSO DE CREDITO
-- Cubre flujo Core -> Homebanking
-- =========================================================

CREATE TABLE credit_disbursement (
    id SERIAL PRIMARY KEY,
    credit_application_id INTEGER NOT NULL UNIQUE REFERENCES creditapplication(id) ON DELETE CASCADE,
    account_id INTEGER NOT NULL REFERENCES account(id) ON DELETE CASCADE,
    movement_id INTEGER REFERENCES movement(id) ON DELETE SET NULL,
    amount DOUBLE PRECISION NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'Desembolsado',
    disbursed_by INTEGER REFERENCES core_analyst_user(id),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- CRONOGRAMA DE PAGOS
-- Cubre desembolso con cronograma
-- =========================================================

CREATE TABLE loan_schedule (
    id SERIAL PRIMARY KEY,
    credit_application_id INTEGER NOT NULL REFERENCES creditapplication(id) ON DELETE CASCADE,
    installment_number INTEGER NOT NULL,
    due_date DATE NOT NULL,
    principal_amount DOUBLE PRECISION NOT NULL,
    interest_amount DOUBLE PRECISION NOT NULL,
    total_amount DOUBLE PRECISION NOT NULL,
    paid_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    status VARCHAR(40) NOT NULL DEFAULT 'Pendiente',
    days_past_due INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    UNIQUE(credit_application_id, installment_number)
);

-- =========================================================
-- RECUPERACIONES / MORA
-- R1 consulta por bandas
-- R2 registro de gestiones
-- R3 judicial / castigo
-- =========================================================

CREATE TABLE recovery_case (
    id SERIAL PRIMARY KEY,
    credit_application_id INTEGER NOT NULL REFERENCES creditapplication(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    overdue_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    days_past_due INTEGER NOT NULL DEFAULT 0,
    band VARCHAR(40) NOT NULL DEFAULT 'Preventiva',
    status VARCHAR(40) NOT NULL DEFAULT 'Activo',
    assigned_to INTEGER REFERENCES core_analyst_user(id),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

CREATE TABLE recovery_action (
    id SERIAL PRIMARY KEY,
    recovery_case_id INTEGER NOT NULL REFERENCES recovery_case(id) ON DELETE CASCADE,
    action_type VARCHAR(80) NOT NULL,
    comment TEXT,
    result VARCHAR(80),
    created_by INTEGER REFERENCES core_analyst_user(id),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- AUDITORIA
-- Para acciones críticas del core
-- =========================================================

CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    actor_type VARCHAR(40) NOT NULL,
    actor_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(80),
    entity_id INTEGER,
    detail TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- =========================================================
-- INDICES
-- =========================================================

CREATE INDEX idx_user_email ON "user"(email);
CREATE INDEX idx_user_document ON "user"(document);

CREATE INDEX idx_account_user_id ON account(user_id);
CREATE INDEX idx_account_number ON account(account_number);

CREATE INDEX idx_movement_account_created ON movement(account_id, created_at);
CREATE INDEX idx_movement_type ON movement(operation_type);

CREATE INDEX idx_credit_user_created ON creditapplication(user_id, created_at);
CREATE INDEX idx_credit_status ON creditapplication(status);
CREATE INDEX idx_credit_risk ON creditapplication(risk_level);
CREATE INDEX idx_credit_route ON creditapplication(approval_route);

CREATE INDEX idx_pagos_user_created ON pagos(user_id, created_at);
CREATE INDEX idx_pagos_account_created ON pagos(account_id, created_at);
CREATE INDEX idx_pagos_servicio ON pagos(servicio);

CREATE INDEX idx_schedule_credit ON loan_schedule(credit_application_id);
CREATE INDEX idx_schedule_status ON loan_schedule(status);
CREATE INDEX idx_schedule_days_past_due ON loan_schedule(days_past_due);

CREATE INDEX idx_recovery_band ON recovery_case(band);
CREATE INDEX idx_recovery_status ON recovery_case(status);
CREATE INDEX idx_recovery_days ON recovery_case(days_past_due);

CREATE INDEX idx_audit_action ON audit_log(action);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- =========================================================
-- VISTAS BASE EN ESPAÑOL
-- Para proyecto / consultas simples
-- =========================================================

CREATE OR REPLACE VIEW cuentas AS
SELECT
    a.id AS cuenta_id,
    a.user_id,
    u.full_name AS cliente,
    a.account_number AS numero_cuenta,
    a.account_type AS tipo,
    a.currency AS moneda,
    a.balance AS saldo,
    a.status AS estado,
    a.created_at AS fecha_creacion
FROM account a
JOIN "user" u ON u.id = a.user_id;

CREATE OR REPLACE VIEW transacciones AS
SELECT
    m.id AS transaccion_id,
    a.user_id,
    u.full_name AS cliente,
    a.account_number AS numero_cuenta,
    m.operation_type AS tipo,
    m.description AS descripcion,
    m.amount AS monto,
    m.created_at AS fecha
FROM movement m
JOIN account a ON a.id = m.account_id
JOIN "user" u ON u.id = a.user_id;

CREATE OR REPLACE VIEW solicitudes_prestamo AS
SELECT
    c.id AS solicitud_id,
    c.user_id,
    u.full_name AS cliente,
    c.product AS producto,
    c.amount AS monto,
    c.months AS plazo_meses,
    c.monthly_income AS ingreso_mensual,
    c.purpose AS proposito,
    c.status AS estado,
    c.analyst_comment AS comentario_analista,
    c.estimated_installment AS cuota_estimada,
    c.rds_ratio AS rds,
    c.scoring_score AS score,
    c.risk_level AS riesgo,
    c.risk_semaphore AS semaforo,
    c.approval_route AS ruta_aprobacion,
    c.disbursement_status AS estado_desembolso,
    c.created_at AS fecha_solicitud
FROM creditapplication c
JOIN "user" u ON u.id = c.user_id;



-- ============================================================
-- FIN: 01_schema_local.sql
-- ============================================================




-- ============================================================
-- INICIO: 01_agregar_cliente_detalle_credito.sql
-- ============================================================



BEGIN;

ALTER TABLE public.creditapplication
ADD COLUMN IF NOT EXISTS cliente_nombre TEXT;

ALTER TABLE public.creditapplication
ADD COLUMN IF NOT EXISTS cliente_dni TEXT;

ALTER TABLE public.creditapplication
ADD COLUMN IF NOT EXISTS cliente_email TEXT;

ALTER TABLE public.creditapplication
ADD COLUMN IF NOT EXISTS cliente_celular TEXT;

UPDATE public.creditapplication ca
SET
    cliente_nombre = u.full_name,
    cliente_dni = u.document,
    cliente_email = u.email,
    cliente_celular = u.phone
FROM public."user" u
WHERE u.id = ca.user_id;

UPDATE public.creditapplication ca
SET analyst_comment =
    'Datos del titular. ' ||
    'Cliente: ' || u.full_name || '. ' ||
    'DNI: ' || u.document || '. ' ||
    'Correo: ' || u.email || '. ' ||
    'Celular: ' || COALESCE(u.phone, 'No registrado') || '. ' ||
    ca.analyst_comment
FROM public."user" u
WHERE u.id = ca.user_id
  AND ca.analyst_comment IS NOT NULL
  AND ca.analyst_comment NOT ILIKE '%DNI:%';

CREATE OR REPLACE FUNCTION public.fn_creditapplication_cliente_info()
RETURNS trigger AS $$
DECLARE
    v_full_name TEXT;
    v_document TEXT;
    v_email TEXT;
    v_phone TEXT;
BEGIN
    SELECT full_name, document, email, phone
    INTO v_full_name, v_document, v_email, v_phone
    FROM public."user"
    WHERE id = NEW.user_id;

    IF v_document IS NOT NULL THEN
        NEW.cliente_nombre := COALESCE(NEW.cliente_nombre, v_full_name);
        NEW.cliente_dni := COALESCE(NEW.cliente_dni, v_document);
        NEW.cliente_email := COALESCE(NEW.cliente_email, v_email);
        NEW.cliente_celular := COALESCE(NEW.cliente_celular, v_phone);

        IF NEW.analyst_comment IS NOT NULL
           AND NEW.analyst_comment NOT ILIKE '%DNI:%' THEN
            NEW.analyst_comment :=
                'Datos del titular. ' ||
                'Cliente: ' || v_full_name || '. ' ||
                'DNI: ' || v_document || '. ' ||
                'Correo: ' || v_email || '. ' ||
                'Celular: ' || COALESCE(v_phone, 'No registrado') || '. ' ||
                NEW.analyst_comment;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_creditapplication_cliente_info ON public.creditapplication;

CREATE TRIGGER trg_creditapplication_cliente_info
BEFORE INSERT OR UPDATE OF user_id, analyst_comment
ON public.creditapplication
FOR EACH ROW
EXECUTE FUNCTION public.fn_creditapplication_cliente_info();

COMMIT;

SELECT
    id,
    user_id,
    cliente_nombre,
    cliente_dni,
    cliente_email,
    cliente_celular,
    LEFT(COALESCE(analyst_comment, ''), 250) AS detalle
FROM public.creditapplication
ORDER BY id DESC
LIMIT 5;



-- ============================================================
-- FIN: 01_agregar_cliente_detalle_credito.sql
-- ============================================================




-- ============================================================
-- INICIO: 02_seed_roles_permisos.sql
-- ============================================================


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



-- ============================================================
-- FIN: 02_seed_roles_permisos.sql
-- ============================================================




-- ============================================================
-- INICIO: 02B_seed_usuarios_core.sql
-- ============================================================


-- 02B_seed_usuarios_core.sql
-- Usuarios internos del banco
-- Clave demo para todos: 123456

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
    'Ana Rojas Valdivia',
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
    'Luis Paredes Huaman',
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
    'Maria Torres Salinas',
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
    'Carlos Rivas Delgado',
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
    'Lucia Salazar Montalvo',
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
    'Jorge Medina Cardenas',
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
    'Comite de Creditos BanBif',
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
    'Administrador Core BanBif',
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
    'SEED_USUARIOS_CORE',
    'core_analyst_user',
    NULL,
    'Carga de usuarios internos con niveles de asesor, analista, riesgos, comite y administrador.'
);


-- ============================================================
-- FIN: 02B_seed_usuarios_core.sql
-- ============================================================




-- ============================================================
-- INICIO: 02C_normalizar_roles_analistas.sql
-- ============================================================


-- 02C_normalizar_roles_analistas.sql
-- Normaliza roles internos a Analista de Creditos por niveles
-- Enfoque: autonomia de aprobacion por monto y riesgo

-- 1. Actualizar usuarios internos
UPDATE core_analyst_user
SET
    role = 'ANALISTA_N1',
    position_name = 'Analista de Creditos Nivel 1'
WHERE username = 'ana.rojas';

UPDATE core_analyst_user
SET
    role = 'ANALISTA_N2',
    position_name = 'Analista de Creditos Nivel 2'
WHERE username = 'luis.paredes';

UPDATE core_analyst_user
SET
    role = 'ANALISTA_N3',
    position_name = 'Analista de Creditos Nivel 3'
WHERE username = 'maria.torres';

UPDATE core_analyst_user
SET
    role = 'ANALISTA_N4',
    position_name = 'Analista de Creditos Nivel 4'
WHERE username = 'carlos.rivas';

-- 2. Normalizar permisos RBAC
UPDATE core_role_permission
SET role = 'ANALISTA_N1'
WHERE role = 'ASESOR_JUNIOR_1';

UPDATE core_role_permission
SET role = 'ANALISTA_N2'
WHERE role = 'ASESOR_JUNIOR_2';

UPDATE core_role_permission
SET role = 'ANALISTA_N3'
WHERE role = 'ANALISTA_JUNIOR';

UPDATE core_role_permission
SET role = 'ANALISTA_N4'
WHERE role = 'ANALISTA_SENIOR';

-- 3. Normalizar rutas de aprobacion en creditos ya creados
UPDATE creditapplication
SET approval_route = 'ANALISTA_N1'
WHERE approval_route = 'ASESOR_JUNIOR_1';

UPDATE creditapplication
SET approval_route = 'ANALISTA_N2'
WHERE approval_route = 'ASESOR_JUNIOR_2';

UPDATE creditapplication
SET approval_route = 'ANALISTA_N3'
WHERE approval_route = 'ANALISTA_JUNIOR';

UPDATE creditapplication
SET approval_route = 'ANALISTA_N4'
WHERE approval_route = 'ANALISTA_SENIOR';

-- 4. Auditoria
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
    'NORMALIZAR_ROLES_ANALISTAS',
    'core_analyst_user/core_role_permission/creditapplication',
    NULL,
    'Se normalizan roles internos a Analista de Creditos Nivel 1-4, manteniendo Supervisor, Riesgos, Comite y Admin.'
);


-- ============================================================
-- FIN: 02C_normalizar_roles_analistas.sql
-- ============================================================




-- ============================================================
-- INICIO: 02C_normalizar_roles_banbif.sql
-- ============================================================


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


-- ============================================================
-- FIN: 02C_normalizar_roles_banbif.sql
-- ============================================================




-- ============================================================
-- INICIO: 03_seed_clientes_cuentas_operaciones.sql
-- ============================================================


-- 03_seed_clientes_cuentas_operaciones.sql
-- Clientes, cuentas, movimientos y pagos realistas
-- Proyecto BanBif - bd_core_financiero
-- Clave demo para clientes principales: 123456

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- LIMPIEZA SOLO DE DATOS DEMO DE CLIENTES
-- No toca usuarios internos del core
-- =========================================================

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
DELETE FROM movement
WHERE account_id IN (SELECT id FROM demo_accounts);

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
)
DELETE FROM creditapplication
WHERE user_id IN (SELECT id FROM demo_users);

WITH demo_users AS (
    SELECT id
    FROM "user"
    WHERE email LIKE '%@demo.banbif.local'
)
DELETE FROM account
WHERE user_id IN (SELECT id FROM demo_users);

DELETE FROM "user"
WHERE email LIKE '%@demo.banbif.local';

-- =========================================================
-- CLIENTES DEMO REALISTAS
-- =========================================================

INSERT INTO "user" (
    document,
    full_name,
    email,
    password_hash,
    phone,
    address,
    role,
    is_active,
    created_at
)
SELECT
    '7' || LPAD(i::text, 7, '0') AS document,
    nombres.nombre AS full_name,
    'cliente.demo' || LPAD(i::text, 2, '0') || '@demo.banbif.local' AS email,
    crypt('123456', gen_salt('bf')) AS password_hash,
    '9' || LPAD((60000000 + i)::text, 8, '0') AS phone,
    direcciones.direccion AS address,
    'CLIENTE' AS role,
    TRUE AS is_active,
    (
        CASE
            WHEN i % 5 = 0 THEN DATE '2022-02-15'
            WHEN i % 5 = 1 THEN DATE '2023-05-10'
            WHEN i % 5 = 2 THEN DATE '2024-08-20'
            WHEN i % 5 = 3 THEN DATE '2025-03-12'
            ELSE DATE '2026-01-18'
        END
        + ((i % 25) || ' days')::interval
    ) AS created_at
FROM generate_series(1, 60) AS i
CROSS JOIN LATERAL (
    SELECT (ARRAY[
        'Carlos Mendoza Alvarez',
        'Lucia Fernandez Quispe',
        'Miguel Torres Huaman',
        'Valeria Rojas Medina',
        'Andres Salazar Poma',
        'Camila Herrera Flores',
        'Diego Paredes Soto',
        'Sofia Castillo Ramos',
        'Jorge Ramirez Loayza',
        'Daniela Vargas Salas',
        'Sebastian Morales Vega',
        'Natalia Flores Palacios',
        'Renato Caceres Molina',
        'Andrea Medina Arias',
        'Bruno Aguilar Rios',
        'Mariana Lozano Cueva',
        'Esteban Vega Romero',
        'Paula Navarro Fuentes',
        'Hugo Campos Leon',
        'Fiorella Reyes Gonzales',
        'Raul Quintana Bravo',
        'Gabriela Leon Chavez',
        'Mateo Silva Ponce',
        'Alessandra Ponce Meza',
        'Rodrigo Chavez Lujan',
        'Fernanda Molina Vera',
        'Eduardo Prieto Solis',
        'Carolina Valdez Rivas',
        'Oscar Benavides Torres',
        'Milagros Ramos NuÃ±ez',
        'Ivan Cordova Herrera',
        'Patricia Meza Delgado',
        'Luis Carranza Ortiz',
        'Claudia Roman Vargas',
        'Emilio Fuentes Diaz',
        'Rosa Palacios Espinoza',
        'Alonso Gutierrez Mendez',
        'Karla Espinoza Calderon',
        'Fernando Villanueva Robles',
        'Tamara Leon Valverde',
        'Julio Salinas Cardenas',
        'Monica Huerta Aguilar',
        'Victor Zamora Paredes',
        'Elena Bustamante Soto',
        'Ricardo Tapia Roman',
        'Rocio Andrade Vargas',
        'Manuel Herrera Caceres',
        'Carmen Valdivia Ramos',
        'Gustavo Cueva Medina',
        'Patricia Quiroz Torres',
        'Alberto Rojas Salcedo',
        'Marisol Campos Silva',
        'Nicolas Figueroa Bravo',
        'Diana Pizarro Flores',
        'Arturo Delgado Meza',
        'Beatriz NuÃ±ez Arias',
        'Cristian Vera Palacios',
        'Lorena Quispe Lozano',
        'Hector Ramos Poma',
        'Vanessa Molina Salas'
    ])[i] AS nombre
) nombres
CROSS JOIN LATERAL (
    SELECT (ARRAY[
        'Av. Javier Prado 1250 - Lima',
        'Av. Arequipa 2450 - Lima',
        'Jr. Real 340 - Huancayo',
        'Av. Los Incas 780 - Cusco',
        'Calle Comercio 450 - Arequipa',
        'Av. Guardia Civil 1150 - Lima',
        'Jr. Puno 220 - Juliaca',
        'Av. San Martin 980 - Trujillo',
        'Calle Grau 150 - Chiclayo',
        'Av. Universitaria 2010 - Lima'
    ])[1 + (i % 10)] AS direccion
) direcciones;

-- =========================================================
-- CUENTAS
-- Una cuenta principal por cliente y segunda cuenta para algunos
-- =========================================================

INSERT INTO account (
    user_id,
    account_number,
    account_type,
    currency,
    balance,
    status,
    created_at
)
SELECT
    u.id,
    '191' || LPAD(u.id::text, 9, '0') AS account_number,
    CASE
        WHEN u.id % 4 = 0 THEN 'Cuenta Corriente'
        ELSE 'Cuenta Ahorro Digital'
    END AS account_type,
    'PEN' AS currency,
    ROUND((850 + (u.id % 17) * 280 + random() * 1600)::numeric, 2)::double precision AS balance,
    'Activa' AS status,
    u.created_at + interval '1 day'
FROM "user" u
WHERE u.email LIKE '%@demo.banbif.local';

-- Segunda cuenta para aproximadamente un tercio
INSERT INTO account (
    user_id,
    account_number,
    account_type,
    currency,
    balance,
    status,
    created_at
)
SELECT
    u.id,
    '192' || LPAD(u.id::text, 9, '0') AS account_number,
    'Cuenta Ahorro Digital' AS account_type,
    'PEN' AS currency,
    ROUND((400 + (u.id % 11) * 210 + random() * 1200)::numeric, 2)::double precision AS balance,
    'Activa' AS status,
    u.created_at + interval '8 days'
FROM "user" u
WHERE u.email LIKE '%@demo.banbif.local'
  AND u.id % 3 = 0;

-- Algunas cuentas inactivas para realismo, sin afectar mayorÃ­a
UPDATE account
SET status = 'Inactiva'
WHERE id IN (
    SELECT a.id
    FROM account a
    JOIN "user" u ON u.id = a.user_id
    WHERE u.email LIKE '%@demo.banbif.local'
      AND a.id % 37 = 0
);

-- =========================================================
-- MOVIMIENTOS HISTORICOS 2022-2026
-- Operaciones bancarias realistas
-- =========================================================

INSERT INTO movement (
    account_id,
    description,
    operation_type,
    amount,
    created_at
)
SELECT
    a.id,
    CASE ops.tipo
        WHEN 'DEPOSITO' THEN 'Deposito recibido en cuenta'
        WHEN 'TRANSFERENCIA' THEN 'Transferencia a cuenta BanBif'
        WHEN 'PAGO' THEN 'Pago de servicio desde Homebanking'
        ELSE 'Retiro / consumo bancario'
    END AS description,
    ops.tipo AS operation_type,
    ROUND(
        CASE ops.tipo
            WHEN 'DEPOSITO' THEN (600 + random() * 2600)
            WHEN 'TRANSFERENCIA' THEN (80 + random() * 1200)
            WHEN 'PAGO' THEN (35 + random() * 450)
            ELSE (50 + random() * 750)
        END::numeric,
        2
    )::double precision AS amount,
    (
        make_date(anio.y, mes.m, 1)
        + ((a.id + mes.m + ops.orden) % 25 || ' days')::interval
        + ((ops.orden * 3) || ' hours')::interval
    ) AS created_at
FROM account a
JOIN "user" u ON u.id = a.user_id
CROSS JOIN generate_series(2022, 2026) AS anio(y)
CROSS JOIN generate_series(1, 12) AS mes(m)
CROSS JOIN (
    VALUES
        (1, 'DEPOSITO'),
        (2, 'TRANSFERENCIA'),
        (3, 'PAGO'),
        (4, 'RETIRO')
) AS ops(orden, tipo)
WHERE u.email LIKE '%@demo.banbif.local'
  AND a.status = 'Activa'
  AND make_date(anio.y, mes.m, 1) <= CURRENT_DATE
  AND (
        ops.tipo IN ('DEPOSITO', 'PAGO')
        OR (a.id + mes.m + anio.y + ops.orden) % 2 = 0
      );

-- =========================================================
-- PAGOS DE SERVICIOS HISTORICOS
-- =========================================================

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
  AND make_date(anio.y, mes.m, 1) <= CURRENT_DATE
  AND (a.id + mes.m + anio.y) % 2 = 0;

-- =========================================================
-- AUDITORIA
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
    'SEED_CLIENTES_CUENTAS_OPERACIONES',
    'user/account/movement/pagos',
    NULL,
    'Carga de clientes, cuentas, movimientos y pagos historicos realistas 2022-2026.'
);


-- ============================================================
-- FIN: 03_seed_clientes_cuentas_operaciones.sql
-- ============================================================




-- ============================================================
-- INICIO: 03B_fix_pagos_servicios.sql
-- ============================================================


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


-- ============================================================
-- FIN: 03B_fix_pagos_servicios.sql
-- ============================================================




-- ============================================================
-- INICIO: 04_seed_creditos_scoring_desembolso.sql
-- ============================================================


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


-- ============================================================
-- FIN: 04_seed_creditos_scoring_desembolso.sql
-- ============================================================




-- ============================================================
-- INICIO: 05_seed_mora_recuperaciones.sql
-- ============================================================


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


-- ============================================================
-- FIN: 05_seed_mora_recuperaciones.sql
-- ============================================================




-- ============================================================
-- INICIO: 06_views_powerbi.sql
-- ============================================================


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


-- ============================================================
-- FIN: 06_views_powerbi.sql
-- ============================================================




-- ============================================================
-- INICIO: 07_fix_calidad_datos_final.sql
-- ============================================================


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


-- ============================================================
-- FIN: 07_fix_calidad_datos_final.sql
-- ============================================================




-- ============================================================
-- INICIO: 08_fix_scoring_automatico.sql
-- ============================================================


-- 08_fix_scoring_automatico.sql
-- Calcula score, RDS, semaforo y ruta cuando una solicitud no tiene evaluacion

CREATE OR REPLACE FUNCTION fn_credit_scoring_defaults()
RETURNS trigger AS $$
DECLARE
    v_cuota numeric;
    v_rds numeric;
    v_score integer;
    v_riesgo text;
    v_semaforo text;
    v_ruta text;
    v_nivel integer;
BEGIN
    v_cuota := ROUND(
        (COALESCE(NEW.amount, 0)::numeric * 1.18) / NULLIF(COALESCE(NEW.months, 12), 0),
        2
    );

    v_rds := ROUND(
        v_cuota / NULLIF(COALESCE(NEW.monthly_income, 0)::numeric, 0),
        4
    );

    IF v_rds IS NULL THEN
        v_rds := 0;
    END IF;

    v_score := CASE
        WHEN v_rds <= 0.25 AND COALESCE(NEW.amount, 0) <= 7000 THEN 92
        WHEN v_rds <= 0.35 AND COALESCE(NEW.amount, 0) <= 12000 THEN 78
        WHEN v_rds <= 0.45 THEN 64
        WHEN v_rds <= 0.60 THEN 52
        ELSE 38
    END;

    IF COALESCE(NEW.amount, 0) > 25000 THEN
        v_score := v_score - 6;
    END IF;

    IF v_score < 0 THEN
        v_score := 0;
    END IF;

    v_riesgo := CASE
        WHEN v_score >= 80 THEN 'BAJO'
        WHEN v_score >= 55 THEN 'MEDIO'
        ELSE 'ALTO'
    END;

    v_semaforo := CASE
        WHEN v_riesgo = 'BAJO' THEN 'VERDE'
        WHEN v_riesgo = 'MEDIO' THEN 'AMARILLO'
        ELSE 'ROJO'
    END;

    v_ruta := CASE
        WHEN COALESCE(NEW.status, '') = 'En comite' THEN 'COMITE'
        WHEN v_riesgo = 'ALTO' AND COALESCE(NEW.amount, 0) > 12000 THEN 'RIESGOS'
        WHEN COALESCE(NEW.amount, 0) <= 3000 THEN 'ANALISTA_N1'
        WHEN COALESCE(NEW.amount, 0) <= 7000 THEN 'ANALISTA_N2'
        WHEN COALESCE(NEW.amount, 0) <= 12000 THEN 'ANALISTA_N3'
        WHEN COALESCE(NEW.amount, 0) <= 25000 THEN 'ANALISTA_N4'
        WHEN COALESCE(NEW.amount, 0) <= 40000 THEN 'SENIOR_CREDITOS'
        WHEN COALESCE(NEW.amount, 0) <= 60000 THEN 'ADMIN_AGENCIA'
        WHEN COALESCE(NEW.amount, 0) <= 150000 THEN 'GERENCIA'
        ELSE 'COMITE'
    END;

    v_nivel := CASE
        WHEN v_ruta = 'ANALISTA_N1' THEN 1
        WHEN v_ruta = 'ANALISTA_N2' THEN 2
        WHEN v_ruta = 'ANALISTA_N3' THEN 3
        WHEN v_ruta = 'ANALISTA_N4' THEN 4
        WHEN v_ruta = 'SENIOR_CREDITOS' THEN 5
        WHEN v_ruta = 'ADMIN_AGENCIA' THEN 6
        WHEN v_ruta = 'RIESGOS' THEN 7
        WHEN v_ruta = 'GERENCIA' THEN 8
        WHEN v_ruta = 'COMITE' THEN 9
        ELSE 1
    END;

    NEW.estimated_installment := COALESCE(NEW.estimated_installment, v_cuota::double precision);
    NEW.rds_ratio := COALESCE(NULLIF(NEW.rds_ratio, 0), v_rds::double precision);
    NEW.scoring_score := COALESCE(NULLIF(NEW.scoring_score, 0), v_score);
    NEW.risk_level := COALESCE(NULLIF(TRIM(NEW.risk_level), ''), v_riesgo);
    NEW.risk_semaphore := COALESCE(NULLIF(TRIM(NEW.risk_semaphore), ''), v_semaforo);
    NEW.approval_route := COALESCE(NULLIF(TRIM(NEW.approval_route), ''), v_ruta);
    NEW.required_approval_level := COALESCE(NULLIF(NEW.required_approval_level, 0), v_nivel);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_credit_scoring_defaults ON creditapplication;

CREATE TRIGGER trg_credit_scoring_defaults
BEFORE INSERT OR UPDATE OF amount, months, monthly_income, status
ON creditapplication
FOR EACH ROW
EXECUTE FUNCTION fn_credit_scoring_defaults();

UPDATE creditapplication
SET
    estimated_installment = NULL,
    rds_ratio = 0,
    scoring_score = 0,
    risk_level = NULL,
    risk_semaphore = NULL,
    approval_route = NULL,
    required_approval_level = NULL
WHERE
    scoring_score IS NULL
    OR scoring_score = 0
    OR risk_level IS NULL
    OR TRIM(COALESCE(risk_level, '')) = ''
    OR approval_route IS NULL
    OR TRIM(COALESCE(approval_route, '')) = '';

UPDATE creditapplication
SET amount = amount
WHERE
    scoring_score IS NULL
    OR scoring_score = 0
    OR risk_level IS NULL
    OR TRIM(COALESCE(risk_level, '')) = ''
    OR approval_route IS NULL
    OR TRIM(COALESCE(approval_route, '')) = '';

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
    'FIX_SCORING_AUTOMATICO',
    'creditapplication',
    NULL,
    'Se agrega trigger para calcular score, RDS, semaforo, ruta y nivel requerido en solicitudes nuevas o incompletas.'
);


-- ============================================================
-- FIN: 08_fix_scoring_automatico.sql
-- ============================================================



