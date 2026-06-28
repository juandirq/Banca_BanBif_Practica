# SQL - BANBIF HOMEBANKING + CORE FINANCIERO

Esta carpeta contiene los scripts de base de datos del proyecto BanBif Homebanking + Core Financiero.

La base de datos utilizada por el sistema es:

`bd_core_financiero`

## Estructura

### base_datos_integrada

Contiene los scripts principales para construir la base de datos completa del proyecto.

Esta carpeta concentra la creacion de la base, el esquema, los datos, los roles, los creditos, los desembolsos, el cronograma de pagos, recuperaciones, vistas para Power BI y validaciones finales.

### scripts_modulares

Contiene los scripts separados por partes.

Sirve como respaldo tecnico para revisar el armado de la base paso a paso: esquema, roles, usuarios, clientes, cuentas, movimientos, creditos, mora, recuperaciones, Power BI y ajustes finales.

## Orden recomendado

Para levantar o revisar la base completa se debe usar la carpeta:

`base_datos_integrada`

Orden de ejecucion:

1. `00_crear_base_datos.sql`
2. `01_esquema_y_datos_banbif.sql`
3. `02_validacion_final.sql`

Tambien se puede usar el archivo:

`ejecutar_base_datos.ps1`

para ejecutar el proceso desde PowerShell.

## Nota

La carpeta `scripts_modulares` queda como respaldo tecnico del proceso separado por partes. Para la revision principal se recomienda usar `base_datos_integrada`.