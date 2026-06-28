/*
============================================================
00_CREAR_BASE_DATOS.sql
Ejecutar conectado a la base postgres.
Este script elimina y vuelve a crear bd_core_financiero.
============================================================
*/

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'bd_core_financiero'
  AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS bd_core_financiero;

CREATE DATABASE bd_core_financiero
WITH
    ENCODING = 'UTF8'
    TEMPLATE = template0;

