# HISTORIAS DE USUARIO

## HU01 - Inicio de sesion del cliente

Como cliente, quiero ingresar al Homebanking con mi DNI y clave para consultar mis productos bancarios de forma segura.

Criterios de aceptacion:

* El sistema valida las credenciales del cliente.
* El sistema genera una sesion segura.
* El cliente accede solo a sus cuentas, movimientos y operaciones.

## HU02 - Consulta de resumen financiero

Como cliente, quiero ver mis cuentas, saldos y movimientos para conocer mi situacion bancaria.

Criterios de aceptacion:

* El sistema muestra las cuentas del cliente.
* El sistema muestra el saldo actualizado.
* El sistema muestra los movimientos registrados.

## HU03 - Pago de servicios

Como cliente, quiero pagar servicios desde mi cuenta para realizar operaciones sin acudir a una agencia.

Criterios de aceptacion:

* El cliente selecciona el servicio a pagar.
* El sistema valida saldo disponible.
* El sistema registra el movimiento de pago.

## HU04 - Transferencia y PLIN

Como cliente, quiero realizar transferencias o enviar dinero mediante PLIN para hacer operaciones digitales de forma rapida.

Criterios de aceptacion:

* El cliente ingresa los datos de la operacion.
* El sistema valida la cuenta y el saldo.
* El movimiento queda registrado en la base de datos.

## HU05 - Solicitud de credito

Como cliente, quiero solicitar un Prestamo Efectivo BanBif desde el Homebanking para que el banco evalue mi solicitud.

Criterios de aceptacion:

* El cliente selecciona el producto de credito.
* El sistema registra monto, plazo, ingreso y proposito.
* El credito queda como solicitud en evaluacion.
* La solicitud queda disponible para revision en el Core financiero.

## HU06 - Evaluacion crediticia

Como analista, quiero revisar las solicitudes de credito para aprobar, rechazar o derivar segun las reglas del banco.

Criterios de aceptacion:

* El analista visualiza las solicitudes asignadas.
* El sistema muestra score, RDS, riesgo, TEA, TCEA y seguro de desgravamen.
* El sistema muestra la recomendacion y ruta de aprobacion.
* El analista solo puede decidir segun su rol y autonomia.

## HU07 - Aprobacion y derivacion por nivel

Como analista, quiero que el sistema respete mi nivel de autonomia para decidir solo los creditos que corresponden a mi perfil.

Criterios de aceptacion:

* Analista Nivel 1 atiende casos dentro de su autonomia.
* Analista Nivel 2 atiende casos de mayor monto.
* Analista Nivel 3 atiende casos superiores o de mayor revision.
* Los casos que superan la autonomia se derivan a Comite o Gerencia.

## HU08 - Desembolso de credito

Como usuario de agencia, quiero desembolsar creditos aprobados para acreditar el monto en la cuenta del cliente.

Criterios de aceptacion:

* Solo agencia puede ejecutar el desembolso.
* El desembolso genera movimiento en la cuenta.
* El saldo del cliente se actualiza.
* Se genera o mantiene el cronograma de cuotas.

## HU09 - Consulta de mora

Como especialista de riesgos, quiero consultar la cartera morosa por bandas para priorizar la gestion de cobranza.

Criterios de aceptacion:

* El sistema muestra casos con dias de mora.
* El sistema permite diferenciar mora temprana, tardia, judicial y castigo.
* El sistema muestra indicadores de recuperaciones.

## HU10 - Registro de gestion de cobranza

Como especialista de riesgos, quiero registrar gestiones de cobranza para mantener historial de seguimiento por caso.

Criterios de aceptacion:

* El especialista registra la gestion realizada.
* El sistema guarda fecha, resultado y comentario.
* El historial queda asociado al caso de recuperacion.

## HU11 - Judicializacion

Como especialista de riesgos, quiero judicializar casos con mora critica para escalar el proceso de recuperacion.

Criterios de aceptacion:

* El sistema valida los dias de mora.
* Solo el rol de Riesgos puede ejecutar la accion.
* El caso cambia a estado judicial cuando corresponde.

## HU12 - Castigo

Como especialista de riesgos, quiero castigar casos judiciales con mora mayor a 180 dias para registrar el cierre contable del caso.

Criterios de aceptacion:

* El sistema valida que el caso cumpla el umbral de mora.
* Solo el rol autorizado puede ejecutar el castigo.
* El caso queda registrado como castigado.

## HU13 - Revision por Comite

Como miembro del Comite, quiero revisar solicitudes escaladas para tomar decisiones en casos superiores.

Criterios de aceptacion:

* El Comite visualiza casos derivados.
* El sistema muestra los datos de evaluacion crediticia.
* El Comite puede aprobar o rechazar segun corresponda.

## HU14 - Supervision por Gerencia

Como usuario de Gerencia, quiero supervisar casos superiores y revisar indicadores para controlar el desempeño del proceso crediticio.

Criterios de aceptacion:

* Gerencia puede revisar solicitudes y reportes.
* El sistema muestra informacion consolidada.
* Las acciones se controlan segun permisos del rol.
