# SCRIPTS MODULARES

Esta carpeta contiene los scripts separados por partes usados para construir la base de datos del proyecto.

Su objetivo es dejar evidencia tecnica del proceso de creacion y carga de datos.

## Contenido

- Limpieza controlada de base local.
- Creacion del esquema.
- Roles y permisos.
- Usuarios internos del Core Financiero.
- Clientes, cuentas, movimientos y pagos.
- Creditos, scoring, RDS, desembolso y cronograma.
- Mora y recuperaciones.
- Vistas para Power BI.
- Ajustes finales de calidad de datos.
- Funcion automatica de scoring.

## Orden de referencia

1. `00_reset_local.sql`
2. `01_schema_local.sql`
3. `02_seed_roles_permisos.sql`
4. `02B_seed_usuarios_core.sql`
5. `02C_normalizar_roles_banbif.sql`
6. `03_seed_clientes_cuentas_operaciones.sql`
7. `03B_fix_pagos_servicios.sql`
8. `04_seed_creditos_scoring_desembolso.sql`
9. `05_seed_mora_recuperaciones.sql`
10. `06_views_powerbi.sql`
11. `07_fix_calidad_datos_final.sql`
12. `08_fix_scoring_automatico.sql`

## Nota

Para levantar toda la base de datos de forma directa se recomienda usar la carpeta `base_datos_integrada`.
