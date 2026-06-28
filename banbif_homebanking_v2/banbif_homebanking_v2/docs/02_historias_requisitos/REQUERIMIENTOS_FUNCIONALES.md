# REQUERIMIENTOS FUNCIONALES Y NO FUNCIONALES

## Requerimientos funcionales

RF01. El sistema debe permitir el inicio de sesion de clientes en el Homebanking.

RF02. El sistema debe permitir el inicio de sesion de usuarios internos en el Core financiero.

RF03. El cliente debe poder consultar sus cuentas, saldos y movimientos.

RF04. El cliente debe poder realizar pagos de servicios desde el Homebanking.

RF05. El cliente debe poder realizar transferencias o pagos mediante PLIN.

RF06. El cliente debe poder solicitar un `Prestamo Efectivo BanBif`.

RF07. El credito debe registrar monto, plazo, ingreso mensual, producto y proposito.

RF08. El proposito del credito debe registrarse como `Libre disponibilidad`.

RF09. El sistema debe manejar TEA referencial de `89.90%`.

RF10. El sistema debe manejar TCEA referencial de `91.42%`.

RF11. El sistema debe mostrar si el credito tiene seguro de desgravamen o no, segun el caso.

RF12. El sistema debe calcular o mostrar la cuota estimada del credito.

RF13. El sistema debe calcular el RDS usando la relacion entre cuota estimada e ingreso mensual.

RF14. El sistema debe calcular o mostrar score crediticio y nivel de riesgo.

RF15. El sistema debe mostrar un semaforo de riesgo para apoyar la evaluacion.

RF16. El Core financiero debe recibir y mostrar las solicitudes registradas en la base de datos compartida.

RF17. El analista debe poder revisar el detalle tecnico de la solicitud.

RF18. El analista debe poder aprobar, rechazar o derivar solicitudes segun su rol y autonomia.

RF19. El sistema debe manejar rutas para Analista Nivel 1, Analista Nivel 2, Analista Nivel 3, Riesgos, Comite y Gerencia.

RF20. El sistema debe bloquear decisiones cuando el usuario no tiene autonomia suficiente.

RF21. El area de agencia debe poder desembolsar creditos aprobados.

RF22. El desembolso debe generar un movimiento en la cuenta del cliente.

RF23. El desembolso debe actualizar el saldo de la cuenta del cliente.

RF24. El sistema debe generar o mantener el cronograma de cuotas del credito.

RF25. El modulo de recuperaciones debe mostrar casos de mora.

RF26. El modulo de recuperaciones debe permitir filtrar casos por bandas de recuperacion.

RF27. El especialista de riesgos debe poder registrar gestiones de cobranza.

RF28. El sistema debe guardar el historial de gestiones en `recovery_action`.

RF29. El sistema debe permitir judicializar casos que cumplan la condicion de mora critica.

RF30. El sistema debe permitir castigar casos judiciales con mora mayor a 180 dias.

RF31. Las acciones de judicializacion y castigo deben estar restringidas al rol de Riesgos.

RF32. El sistema debe bloquear acciones no permitidas por rol.

RF33. El sistema debe devolver `401` cuando no exista token de autenticacion.

RF34. El sistema debe devolver `403` cuando el rol no tenga permiso.

RF35. Power BI debe conectarse a vistas o consultas de la base de datos.

RF36. El sistema debe contar con datos de prueba para validar distintos escenarios del flujo crediticio.

## Requerimientos no funcionales

RNF01. El Homebanking y el Core financiero deben usar una sola base de datos compartida.

RNF02. La base de datos principal debe ser PostgreSQL local: `bd_core_financiero`.

RNF03. El proyecto debe separar frontend, backend y base de datos.

RNF04. El backend debe organizar la logica en rutas, servicios, repositorios y base de datos.

RNF05. Las acciones criticas deben validarse en backend, no solo en frontend.

RNF06. El sistema debe aplicar control de acceso por roles.

RNF07. La autenticacion debe manejarse mediante JWT.

RNF08. Los datos de prueba deben ser sinteticos, coherentes y calibrados.

RNF09. La documentacion debe estar ordenada segun los criterios de la rubrica.

RNF10. Los diagramas UML deben estar actualizados al flujo final del proyecto.

RNF11. Los scripts SQL deben estar versionados y ser ejecutables.

RNF12. Las evidencias deben incluir pruebas, capturas, salidas de consola y validaciones.

RNF13. El sistema debe mostrar mensajes claros cuando una accion no este permitida.

RNF14. El sistema debe mantener consistencia entre creditos, cuentas, movimientos, desembolsos, cronogramas y recuperaciones.

RNF15. El proyecto debe permitir una demostracion completa del flujo end-to-end.
