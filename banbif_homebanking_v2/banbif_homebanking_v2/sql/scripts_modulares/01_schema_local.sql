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
-- Para profesor / consultas simples
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
