# BASE DE DATOS Y MODELO EN PGADMIN

Esta carpeta contiene evidencias tecnicas de la base de datos del proyecto BanBif Homebanking + Core Financiero.

La base de datos utilizada es `bd_core_financiero`, administrada en PostgreSQL y visualizada desde pgAdmin.

## Evidencias incluidas

### 01_modelo_pgadmin_general.png

Muestra el modelo general de la base de datos generado desde pgAdmin. En esta captura se observa la estructura completa de las tablas y sus relaciones principales.

### 02_modelo_pgadmin_detalle_creditos.png

Muestra el detalle de las tablas relacionadas con usuarios, cuentas y solicitudes de credito. En esta parte se evidencian tablas como `user`, `account`, `creditapplication`, `core_analyst_user`, permisos y registros de auditoria.

### 03_modelo_pgadmin_detalle_recuperaciones.png

Muestra el detalle de las tablas relacionadas con desembolsos, movimientos, cronograma de pagos y recuperaciones. En esta parte se evidencian tablas como `movement`, `credit_disbursement`, `loan_schedule`, `recovery_case` y `recovery_action`.

## Importancia de la evidencia

Estas capturas permiten demostrar que el proyecto cuenta con una base de datos estructurada y relacionada. Tambien evidencian que el Homebanking y el Core Financiero trabajan sobre una misma base de datos, permitiendo manejar clientes, cuentas, movimientos, creditos, desembolsos, cronogramas y recuperaciones.

## Tablas principales

* `user`: almacena la informacion de los clientes.
* `account`: almacena las cuentas bancarias.
* `movement`: almacena los movimientos de las cuentas.
* `creditapplication`: almacena las solicitudes de credito.
* `credit_disbursement`: almacena los desembolsos realizados.
* `loan_schedule`: almacena el cronograma de pagos.
* `recovery_case`: almacena los casos de mora y recuperacion.
* `recovery_action`: almacena las gestiones de cobranza.
* `core_analyst_user`: almacena los usuarios internos del Core Financiero.

## Conclusion

El modelo generado desde pgAdmin evidencia la organizacion de la base de datos y respalda el funcionamiento integrado del sistema BanBif Homebanking + Core Financiero.
