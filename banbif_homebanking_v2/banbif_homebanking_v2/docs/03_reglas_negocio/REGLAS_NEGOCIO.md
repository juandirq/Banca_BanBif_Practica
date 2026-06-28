# REGLAS DE NEGOCIO - BANBIF HOMEBANKING + CORE FINANCIERO

Este documento describe las reglas principales aplicadas en el flujo de credito, evaluacion, aprobacion, desembolso, mora, recuperaciones y seguridad del proyecto BanBif Homebanking + Core Financiero.

El sistema trabaja con una base de datos compartida:

`bd_core_financiero`

## Tablas principales

Las principales tablas usadas en el flujo son:

* `user`
* `account`
* `movement`
* `creditapplication`
* `credit_disbursement`
* `loan_schedule`
* `recovery_case`
* `recovery_action`
* `core_analyst_user`

---

## 1. Producto de credito

El producto principal usado para la validacion del proyecto es:

`Prestamo Efectivo BanBif`

El proposito del credito es:

`Libre disponibilidad`

Los casos de prueba trabajan con una tasa referencial del sistema:

* TEA referencial: `89.90%`
* TCEA referencial: `91.42%`

El sistema tambien registra si el credito cuenta con:

* Con seguro de desgravamen.
* Sin seguro de desgravamen.

El seguro de desgravamen se muestra como una condicion del credito en el detalle tecnico de la solicitud.

---

## 2. Regla de solicitud de credito

El cliente puede registrar una solicitud de credito desde el Homebanking.

La solicitud considera los siguientes datos:

* Producto.
* Monto solicitado.
* Plazo en meses.
* Ingreso mensual.
* Proposito del credito.
* Datos del cliente.
* Seguro de desgravamen, segun corresponda.

La solicitud se guarda en la tabla:

`creditapplication`

Estado inicial de una solicitud nueva:

`En evaluacion`

---

## 3. Formula de tasa efectiva mensual

Para calcular la cuota referencial, el sistema convierte la TEA a una tasa efectiva mensual.

Formula:

`TEM = (1 + TEA)^(1/12) - 1`

Donde:

* `TEA` es la tasa efectiva anual referencial.
* `TEM` es la tasa efectiva mensual.
* En el proyecto se usa TEA referencial de `89.90%`.

---

## 4. Formula de cuota estimada

La cuota estimada se calcula con el metodo de cuota fija.

Formula:

`Cuota = Monto * TEM / (1 - (1 + TEM)^(-n))`

Donde:

* `Monto` es el monto solicitado.
* `TEM` es la tasa efectiva mensual.
* `n` es el plazo en meses.

La cuota estimada se muestra en la evaluacion crediticia para que el analista pueda revisar la capacidad de pago del cliente.

---

## 5. Formula de RDS

El RDS mide la relacion entre la cuota estimada y el ingreso mensual del cliente.

Formula:

`RDS = Cuota estimada / Ingreso mensual`

En porcentaje:

`RDS (%) = (Cuota estimada / Ingreso mensual) * 100`

Uso del RDS:

* Permite medir la carga financiera del cliente.
* Influye en el nivel de riesgo.
* Apoya la recomendacion del sistema.
* Ayuda a definir si el caso puede aprobarse o debe derivarse.

En los datos de prueba, el RDS fue calibrado para mantenerse en valores controlados y coherentes con el perfil de cada caso.

---

## 6. Score crediticio

El score crediticio representa una evaluacion interna referencial del cliente.

Escala:

`0 a 100 puntos`

Interpretacion general:

|      Score | Riesgo referencial |
| ---------: | ------------------ |
|   80 a 100 | Bajo               |
|    70 a 79 | Medio              |
| Menor a 70 | Alto               |

Uso del score:

* Si el score es alto, el caso puede seguir evaluacion normal.
* Si el score es medio, puede requerir revision superior.
* Si el score es bajo, puede derivarse a Riesgos, Comite o ser rechazado.

---

## 7. Semaforo de riesgo

El semaforo de riesgo ayuda a interpretar el perfil de la solicitud.

El sistema toma en cuenta:

* Score crediticio.
* RDS.
* Monto solicitado.
* Riesgo referencial.
* Ruta de aprobacion.

Regla general:

| Riesgo | Semaforo | Accion                                  |
| ------ | -------- | --------------------------------------- |
| Bajo   | Verde    | Evaluacion normal                       |
| Medio  | Amarillo | Revision con mayor sustento             |
| Alto   | Rojo     | Derivacion, rechazo o revision superior |

---

## 8. Ruta de aprobacion

La ruta de aprobacion depende del monto, RDS, score, riesgo y autonomia del usuario interno.

Rutas principales:

| Condicion general                         | Ruta               |
| ----------------------------------------- | ------------------ |
| Monto hasta S/ 10,000 y riesgo bajo       | Analista Nivel 1   |
| Monto hasta S/ 25,000 y riesgo controlado | Analista Nivel 2   |
| Monto hasta S/ 60,000 o revision superior | Analista Nivel 3   |
| Riesgo alto o excepcion de riesgo         | Area de Riesgos    |
| Caso superior o escalado                  | Comite de Creditos |
| Caso ejecutivo o de mayor supervision     | Gerencia           |

El sistema puede recomendar:

* `APROBAR`
* `RECHAZAR`
* `DERIVAR A ANALISTA N2`
* `DERIVAR A ANALISTA N3`
* `DERIVAR A RIESGOS`
* `DERIVAR A COMITE`

---

## 9. Autonomia por rol

Cada rol tiene una responsabilidad distinta dentro del Core financiero.

| Rol              | Funcion principal                            |
| ---------------- | -------------------------------------------- |
| Analista Nivel 1 | Evalua casos simples y de bajo monto         |
| Analista Nivel 2 | Evalua casos de monto medio                  |
| Analista Nivel 3 | Evalua casos superiores o con mayor revision |
| Agencia          | Ejecuta desembolsos aprobados                |
| Riesgos          | Gestiona mora, judicializacion y castigo     |
| Comite           | Revisa casos escalados                       |
| Gerencia         | Supervisa y revisa casos superiores          |

El sistema debe impedir que un usuario realice acciones fuera de su rol.

Si el rol no tiene permiso, el backend responde:

`403 Forbidden`

---

## 10. Regla de aprobacion

Un credito puede aprobarse cuando:

* La solicitud tiene datos suficientes.
* Existe ingreso mensual registrado.
* El RDS es aceptable.
* El score no representa riesgo critico.
* El usuario tiene rol y autonomia para decidir.
* La ruta asignada corresponde al perfil conectado.

Estado resultante:

`Aprobado`

---

## 11. Regla de rechazo

Un credito puede rechazarse cuando:

* La capacidad de pago no es suficiente.
* El score es bajo.
* El RDS es demasiado alto.
* El riesgo supera la politica interna.
* La informacion o sustento no es suficiente.
* El analista o instancia correspondiente registra la decision.

Estado resultante:

`Rechazado`

---

## 12. Regla de derivacion

Una solicitud puede derivarse cuando:

* El monto supera la autonomia del usuario conectado.
* El riesgo necesita una revision superior.
* El score o RDS requieren mayor sustento.
* La politica interna exige revision de otro nivel.
* El caso debe ser revisado por Comite o Gerencia.

Estados o rutas posibles:

* `ANALISTA_N2`
* `ANALISTA_N3`
* `RIESGOS`
* `COMITE`
* `GERENCIA`

---

## 13. Regla de desembolso

Un credito solo puede desembolsarse si cumple:

* Estado del credito: `Aprobado`.
* Estado de desembolso: `No desembolsado`.
* Existe una cuenta activa del cliente.
* El usuario tiene rol de Agencia o rol permitido para desembolso.

Al desembolsar:

1. Se registra el desembolso en `credit_disbursement`.
2. Se suma el monto a `account.balance`.
3. Se registra un movimiento en `movement`.
4. El cliente visualiza el abono en Homebanking.
5. Se genera o mantiene el cronograma en `loan_schedule`.

Formula:

`Nuevo saldo = Saldo actual + Monto desembolsado`

---

## 14. Regla de cronograma de pagos

El cronograma se registra en:

`loan_schedule`

Cada cuota contiene:

* Numero de cuota.
* Fecha de vencimiento.
* Capital.
* Interes.
* Total de cuota.
* Monto pagado.
* Estado.
* Dias de mora.

Estados posibles:

* `Pendiente`
* `Vencida`
* `Pagado`

---

## 15. Regla de mora

La mora se determina segun los dias de atraso de una cuota o credito.

Formula:

`Dias de mora = Fecha actual - Fecha de vencimiento`

Si el resultado es mayor que cero, la cuota puede considerarse vencida.

La mora se usa para:

* Clasificar casos.
* Calcular indicadores.
* Activar recuperaciones.
* Evaluar judicializacion o castigo.

---

## 16. Bandas de recuperacion

Las bandas de recuperacion permiten ordenar los casos morosos.

| Banda      |                             Dias de mora | Uso principal               |
| ---------- | ---------------------------------------: | --------------------------- |
| Preventiva | Sin atraso critico o seguimiento inicial | Revision preventiva         |
| Temprana   |                              1 a 60 dias | Gestion inicial o intensiva |
| Tardia     |                            61 a 120 dias | Gestion intensiva           |
| Judicial   |                           Desde 121 dias | Derivacion judicial         |
| Castigo    |                         Mayor a 180 dias | Castigo contable            |

Un caso puede permanecer en una banda hasta que el usuario autorizado ejecute la transicion correspondiente. Esto permite validar reglas y permisos.

---

## 17. Ratio de mora

El ratio de mora mide la proporcion de cartera vencida frente al total de cartera.

Formula:

`Ratio de mora = Cartera vencida / Cartera total`

En porcentaje:

`Ratio de mora (%) = (Cartera vencida / Cartera total) * 100`

Uso:

* Se muestra como indicador de seguimiento.
* Permite evaluar el estado de la cartera.
* Apoya el modulo de recuperaciones y el dashboard.

---

## 18. Regla de recuperaciones

Un caso entra al modulo de recuperaciones cuando:

* Existe un credito desembolsado.
* Existe deuda vencida o atraso.
* Se registran dias de mora.
* El caso se encuentra en `recovery_case`.

Datos principales:

* Cliente.
* Solicitud de credito.
* Monto vencido.
* Dias de mora.
* Banda.
* Estado de gestion.
* Usuario asignado.

---

## 19. Regla de gestion de cobranza

Las gestiones de cobranza se registran en:

`recovery_action`

Ejemplos de gestion:

* Contacto telefonico.
* Seguimiento de cobranza.
* Compromiso de pago.
* Observacion del caso.
* Derivacion judicial.
* Propuesta de castigo.

El registro permite mantener historial de acciones por caso.

---

## 20. Regla de judicializacion

Un caso puede judicializarse cuando:

* Presenta mora critica.
* Cumple el umbral de dias establecido.
* Tiene una situacion que requiere escalamiento.
* El usuario tiene rol de Riesgos.

Condicion referencial:

`days_past_due >= 121`

Resultado esperado:

`band = Judicial`

Tambien se registra una gestion en `recovery_action`.

Si el usuario no tiene permiso:

`403 Forbidden`

---

## 21. Regla de castigo

Un caso puede castigarse cuando:

* El caso se encuentra en etapa judicial o cumple condicion de mora avanzada.
* Presenta atraso mayor a 180 dias.
* El usuario tiene rol de Riesgos.
* La accion queda registrada como parte del seguimiento.

Condicion referencial:

`days_past_due > 180`

Resultado esperado:

`band = Castigo`

Tambien se registra una gestion en `recovery_action`.

Si el usuario no tiene permiso:

`403 Forbidden`

---

## 22. Reglas de seguridad RBAC + JWT

El sistema usa autenticacion con JWT y control de acceso por roles.

Reglas principales:

| Situacion                    | Respuesta               |
| ---------------------------- | ----------------------- |
| Sin token                    | `401 Not authenticated` |
| Token invalido               | `401 Not authenticated` |
| Token valido, rol incorrecto | `403 Forbidden`         |
| Token valido, rol correcto   | Permite accion          |

Roles principales:

* Cliente.
* Analista Nivel 1.
* Analista Nivel 2.
* Analista Nivel 3.
* Agencia.
* Riesgos.
* Comite.
* Gerencia.
* Admin Core.

Acciones protegidas:

* Evaluar credito.
* Aprobar credito.
* Rechazar credito.
* Derivar credito.
* Resolver Comite.
* Desembolsar.
* Registrar gestion de cobranza.
* Judicializar.
* Castigar.

---

## 23. Regla de integracion Core - Homebanking

El flujo integrado se valida de la siguiente manera:

1. El cliente ingresa al Homebanking.
2. El cliente consulta o solicita credito.
3. La solicitud se guarda en `creditapplication`.
4. El Core financiero lee la solicitud desde la misma base de datos.
5. El analista revisa la evaluacion crediticia.
6. El Core aprueba, rechaza o deriva.
7. Agencia desembolsa si corresponde.
8. Se actualiza `account.balance`.
9. Se registra `movement`.
10. El Homebanking muestra el saldo y movimiento actualizado.

Esto demuestra que ambos sistemas trabajan como un proyecto integrado.

---

## 24. Regla de datos de prueba

Los datos usados son sinteticos y se emplean solo para validar el funcionamiento del sistema.

Caracteristicas:

* DNI de 8 digitos.
* Nombres completos.
* Correos coherentes.
* Cuentas bancarias.
* Movimientos.
* Creditos en distintos estados.
* Desembolsos.
* Cronogramas de pago.
* Casos de mora.
* Gestiones de cobranza.
* Casos judicializados y castigados.

El sistema cuenta con 30 casos de prueba alineados al flujo del proyecto BanBif.

Objetivo:

Demostrar el funcionamiento del sistema sin usar informacion personal real.
