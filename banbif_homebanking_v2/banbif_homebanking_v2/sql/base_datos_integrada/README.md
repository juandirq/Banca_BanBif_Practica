# BASE DE DATOS INTEGRADA

Esta carpeta contiene los scripts principales para crear y validar la base de datos completa del proyecto BanBif Homebanking + Core Financiero.

## Base de datos

`bd_core_financiero`

## Archivos

### 00_crear_base_datos.sql

Crea nuevamente la base de datos `bd_core_financiero`.

Debe ejecutarse conectado a la base `postgres`.

### 01_esquema_y_datos_banbif.sql

Crea el esquema completo y carga los datos principales del proyecto.

Incluye tablas, roles, permisos, usuarios internos, clientes, cuentas, movimientos, solicitudes de credito, scoring, RDS, desembolsos, cronograma, mora, recuperaciones, vistas Power BI y ajustes finales.

### 02_validacion_final.sql

Valida que la base de datos haya sido creada correctamente.

Este script no inserta, no borra y no modifica datos. Solo realiza consultas de comprobacion.

### ejecutar_base_datos.ps1

Script de apoyo para ejecutar el proceso desde PowerShell.

## Orden de ejecucion

1. Ejecutar `00_crear_base_datos.sql`.
2. Ejecutar `01_esquema_y_datos_banbif.sql`.
3. Ejecutar `02_validacion_final.sql`.
