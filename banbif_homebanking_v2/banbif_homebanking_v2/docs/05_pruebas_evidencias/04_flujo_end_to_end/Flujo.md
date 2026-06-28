# FLUJO END TO END - BANBIF HOMEBANKING + CORE FINANCIERO

Esta carpeta explica el flujo completo del proyecto BanBif Homebanking + Core Financiero.

El objetivo de este flujo es demostrar que el sistema no funciona como partes separadas, sino como una solucion integrada. El cliente realiza operaciones desde el Homebanking y el personal interno del banco gestiona la evaluacion, aprobacion, desembolso y seguimiento desde el Core Financiero.

## Descripcion del flujo

El flujo inicia cuando el cliente ingresa al Homebanking con su DNI y clave. Desde ahi puede consultar sus cuentas, movimientos y informacion relacionada con sus productos financieros.

Cuando el cliente registra o consulta un credito, la informacion queda guardada en la base de datos compartida `bd_core_financiero`. Esta misma base de datos tambien es utilizada por el Core Financiero, por eso la solicitud puede ser revisada por los usuarios internos del banco.

En el Core Financiero, el analista revisa la solicitud de credito y observa los datos principales del cliente y del prestamo. El sistema muestra informacion como el monto solicitado, plazo, ingreso mensual, cuota estimada, TEA, TCEA, RDS, score crediticio, nivel de riesgo y seguro de desgravamen.

Segun las reglas del banco, el credito puede ser aprobado, rechazado o derivado a otro nivel de revision. Los analistas de Nivel 1, Nivel 2 y Nivel 3 trabajan segun su autonomia. Los casos que superan la autonomia o requieren mayor evaluacion pueden pasar a Comite, Gerencia o Riesgos.

Cuando un credito es aprobado, el area de Agencia puede realizar el desembolso. Al desembolsar, el sistema registra el desembolso, genera un movimiento en la cuenta del cliente, actualiza el saldo y mantiene el cronograma de pagos.

Finalmente, el cliente puede volver al Homebanking y visualizar el movimiento del desembolso y el saldo actualizado. Esto confirma que el Homebanking y el Core Financiero trabajan conectados mediante la misma base de datos.

## Flujo resumido

1. El cliente ingresa al Homebanking.
2. El cliente consulta sus cuentas, movimientos o credito.
3. La informacion se guarda en la base de datos compartida.
4. El Core Financiero muestra la solicitud al analista.
5. El analista revisa la evaluacion crediticia.
6. El sistema muestra TEA, TCEA, cuota, RDS, score, riesgo y seguro de desgravamen.
7. El credito se aprueba, rechaza o deriva segun las reglas del banco.
8. Agencia realiza el desembolso si el credito fue aprobado.
9. El sistema registra el movimiento y actualiza el saldo del cliente.
10. El cliente visualiza la informacion actualizada desde Homebanking.

## Importancia del flujo

Este flujo permite evidenciar la integracion entre el Homebanking y el Core Financiero. Tambien muestra que el proyecto cumple con un proceso bancario completo, desde la atencion del cliente hasta la gestion interna del credito, incluyendo evaluacion, decision, desembolso y seguimiento.
