-- =========================================================
-- 00_reset_local.sql
-- Limpieza controlada de base local bd_core_financiero
-- Proyecto BanBif - Core + Homebanking
-- =========================================================

DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS recovery_action CASCADE;
DROP TABLE IF EXISTS recovery_case CASCADE;
DROP TABLE IF EXISTS loan_schedule CASCADE;
DROP TABLE IF EXISTS credit_disbursement CASCADE;
DROP TABLE IF EXISTS core_role_permission CASCADE;
DROP TABLE IF EXISTS core_permission CASCADE;
DROP TABLE IF EXISTS pagos CASCADE;
DROP TABLE IF EXISTS movement CASCADE;
DROP TABLE IF EXISTS creditapplication CASCADE;
DROP TABLE IF EXISTS account CASCADE;
DROP TABLE IF EXISTS core_analyst_user CASCADE;
DROP TABLE IF EXISTS "user" CASCADE;

DROP VIEW IF EXISTS cuentas CASCADE;
DROP VIEW IF EXISTS transacciones CASCADE;
DROP VIEW IF EXISTS solicitudes_prestamo CASCADE;
DROP VIEW IF EXISTS vw_pbi_clientes CASCADE;
DROP VIEW IF EXISTS vw_pbi_cuentas CASCADE;
DROP VIEW IF EXISTS vw_pbi_creditos CASCADE;
DROP VIEW IF EXISTS vw_pbi_pagos CASCADE;
DROP VIEW IF EXISTS vw_pbi_transacciones CASCADE;
DROP VIEW IF EXISTS vw_pbi_operaciones_banbif CASCADE;
DROP VIEW IF EXISTS vw_pbi_resumen_general CASCADE;
DROP VIEW IF EXISTS vw_pbi_mora CASCADE;
