# AUTOEVALUACION SEGUN RUBRICA

## Criterio 1 - Integracion Core <-> Homebanking

Nivel obtenido: Excelente - 4 pts.

Evidencia:

* El Homebanking y el Core financiero trabajan sobre la misma base de datos PostgreSQL local: `bd_core_financiero`.
* El cliente puede ingresar al Homebanking con sus credenciales.
* El sistema permite consultar cuentas, movimientos y credito.
* Las solicitudes de credito se registran en la base de datos compartida.
* El Core financiero muestra las solicitudes al analista correspondiente.
* El analista puede revisar la evaluacion crediticia, aprobar, rechazar o derivar segun la ruta asignada.
* El area de agencia puede realizar el desembolso de creditos aprobados.
* El desembolso genera movimiento en la cuenta y actualiza el saldo del cliente.
* El flujo se comporta como un proyecto integrado de extremo a extremo.

Observacion:

El proyecto cumple este criterio porque el Homebanking y el Core no funcionan como sistemas aislados, sino que comparten datos y participan en el mismo flujo de credito.

## Criterio 2 - Reglas de negocio del credito

Nivel obtenido: Excelente - 4 pts.

Evidencia:

* El producto principal evaluado es `Prestamo Efectivo BanBif`.
* El proposito del credito es `Libre disponibilidad`.
* El sistema usa TEA referencial de `89.90%`.
* El sistema usa TCEA referencial de `91.42%`.
* La evaluacion considera monto, plazo, ingreso mensual, cuota estimada, score y RDS.
* El sistema muestra si el credito tiene seguro de desgravamen o no, segun el caso.
* El RDS se calcula con la relacion entre cuota estimada e ingreso mensual.
* El sistema clasifica el riesgo mediante score crediticio y semaforo de riesgo.
* La ruta de aprobacion se asigna segun monto, riesgo, RDS y autonomia del rol.
* Existen rutas para Analista Nivel 1, Analista Nivel 2, Analista Nivel 3, Riesgos, Comite y Gerencia.
* El desembolso genera movimiento en cuenta y cronograma de pagos.
* Los 30 casos de prueba fueron adaptados a las reglas del proyecto BanBif.

Observacion:

El proyecto cumple este criterio porque la evaluacion del credito no es solo un registro simple, sino que aplica reglas de negocio para calcular cuota, RDS, riesgo, ruta de aprobacion y estado del credito.

## Criterio 3 - Seguridad y control de acceso por roles

Nivel obtenido: Excelente - 4 pts.

Evidencia:

* El sistema cuenta con login en Homebanking y en Core financiero.
* Se utiliza autenticacion con token JWT.
* Existen roles diferenciados para cliente y usuarios internos.
* Los roles internos configurados son: Analista Nivel 1, Analista Nivel 2, Analista Nivel 3, Agencia, Riesgos, Comite y Gerencia.
* Cada rol tiene permisos segun su responsabilidad.
* El analista solo puede actuar dentro de su nivel y autonomia.
* Agencia puede realizar desembolsos.
* Riesgos puede gestionar mora, judicializacion y castigo.
* Comite y Gerencia intervienen en casos superiores.
* Las acciones no permitidas son bloqueadas.
* Las pruebas consideran respuestas `401` cuando no existe token y `403` cuando el rol no tiene permiso.

Observacion:

El proyecto cumple este criterio porque no todos los usuarios pueden realizar las mismas acciones. Las operaciones se controlan por autenticacion y por permisos asociados al rol.

## Criterio 4 - Recuperaciones / Mora

Nivel obtenido: Excelente - 4 pts.

Evidencia:

* El sistema cuenta con modulo de recuperaciones.
* Se muestran indicadores de cartera, mora y casos en seguimiento.
* Existen casos de prueba con diferentes dias de atraso.
* Se manejan bandas de recuperacion como Temprana, Tardia, Judicial y Castigo.
* El sistema permite registrar gestiones de cobranza.
* El historial de gestiones queda registrado en `recovery_action`.
* Los casos de mora se relacionan con el credito y el cliente.
* Existen casos para gestion temprana, gestion intensiva, judicializacion y castigo.
* La judicializacion y el castigo se controlan por reglas y por permisos del rol de Riesgos.
* Los analistas pueden consultar, pero no deben ejecutar acciones reservadas para Riesgos.

Observacion:

El proyecto cumple este criterio porque el modulo de recuperaciones no solo consulta mora, sino que permite registrar gestiones y controlar transiciones de estado segun los dias de atraso y el rol autorizado.

## Criterio 5 - Calidad de datos, arquitectura y documentacion

Nivel obtenido: Excelente - 4 pts.

Evidencia:

* La base de datos mantiene relaciones entre clientes, cuentas, movimientos, creditos, desembolsos, cronogramas y recuperaciones.
* Se cargaron 30 casos de prueba para validar distintos escenarios del flujo crediticio.
* Los datos incluyen casos en evaluacion, aprobados, desembolsados, rechazados, con mora, judicializados y castigados.
* El sistema contempla productos de credito del banco, trabajando principalmente con `Prestamo Efectivo BanBif` para la validacion de los 30 casos.
* La arquitectura esta organizada en capas: frontend, backend, servicios/repositorios y base de datos.
* La documentacion esta organizada en carpetas por rubrica, requisitos, reglas de negocio, UML, evidencias, Power BI y scripts SQL.
* Los diagramas UML fueron actualizados segun el flujo final del sistema.
* Existen scripts SQL versionados para validar la base de datos y el funcionamiento del proyecto.
* Existen historias de usuario, requerimientos funcionales y requerimientos no funcionales.
* El proyecto incluye evidencias, capturas, pruebas de consola y validaciones.

Observacion:

El proyecto cumple este criterio porque cuenta con datos consistentes, arquitectura organizada y documentacion suficiente para sustentar el funcionamiento del sistema.
