# MATRIZ DE EVIDENCIAS

Esta matriz resume las evidencias principales del proyecto BanBif Homebanking + Core Financiero, organizadas segun los criterios de evaluacion de la rubrica.

---

## Criterio 1: Integracion Core - Homebanking

**Estado:** Cumple

**Evidencias:**

1. Homebanking y Core financiero usan la misma base de datos: `bd_core_financiero`.

   * Ubicacion: PostgreSQL / configuracion backend.

2. El cliente ingresa al Homebanking y consulta sus datos financieros.

   * Ubicacion: pantalla Homebanking.

3. La solicitud de credito se visualiza en el Core financiero.

   * Ubicacion: Homebanking Creditos / Core Bandeja.

4. El desembolso genera movimiento y actualiza el saldo del cliente.

   * Ubicacion: tablas `movement`, `credit_disbursement` y cuenta del cliente.

5. El saldo y los movimientos se reflejan en el Homebanking.

   * Ubicacion: pantalla de cuenta y movimientos.

---

## Criterio 2: Reglas de negocio del credito

**Estado:** Cumple

**Evidencias:**

1. Producto configurado como `Prestamo Efectivo BanBif`.

   * Ubicacion: Core Evaluacion Crediticia.

2. Proposito configurado como `Libre disponibilidad`.

   * Ubicacion: detalle tecnico de solicitud.

3. TEA referencial de `89.90%` y TCEA referencial de `91.42%`.

   * Ubicacion: detalle tecnico de solicitud.

4. Seguro de desgravamen visible en el detalle tecnico.

   * Ubicacion: Core Evaluacion Crediticia.

5. Calculo de cuota estimada, RDS, score y riesgo.

   * Ubicacion: Core Evaluacion Crediticia.

6. Ruta de aprobacion por monto, RDS, score y rol.

   * Ubicacion: Core Bandeja / Evaluacion.

7. Cronograma generado despues del desembolso.

   * Ubicacion: tabla `loan_schedule`.

---

## Criterio 3: Seguridad RBAC + JWT

**Estado:** Cumple

**Evidencias:**

1. Login con token JWT.

   * Ubicacion: `/api/auth/login` y `/api/core/auth/login`.

2. Usuario sin token recibe respuesta `401`.

   * Ubicacion: auditoria RBAC.

3. Usuario con rol no permitido recibe respuesta `403`.

   * Ubicacion: auditoria RBAC.

4. Analistas N1, N2 y N3 operan segun autonomia.

   * Ubicacion: Core Evaluacion Crediticia.

5. Agencia puede realizar desembolsos.

   * Ubicacion: Core Desembolsos.

6. Riesgos puede gestionar mora, judicializacion y castigo.

   * Ubicacion: Core Recuperaciones.

7. Comite y Gerencia intervienen en casos superiores.

   * Ubicacion: Core Comite / Gerencia.

---

## Criterio 4: Recuperaciones / Mora

**Estado:** Cumple

**Evidencias:**

1. Consulta de KPIs y casos en mora.

   * Ubicacion: Core Recuperaciones.

2. Filtros por banda de recuperacion.

   * Ubicacion: Core Recuperaciones.

3. Registro de gestion de cobranza.

   * Ubicacion: tabla `recovery_action`.

4. Historial de gestiones por caso.

   * Ubicacion: Core Recuperaciones / `recovery_action`.

5. Casos para judicializacion.

   * Ubicacion: tabla `recovery_case`.

6. Casos para castigo.

   * Ubicacion: tabla `recovery_case`.

---

## Criterio 5: Calidad de datos, arquitectura y documentacion

**Estado:** Cumple

**Evidencias:**

1. Se cargaron 30 casos de prueba alineados a BanBif.

   * Ubicacion: validacion SQL / Core Bandeja.

2. Los datos incluyen clientes, cuentas, creditos, movimientos, desembolsos, cronogramas y mora.

   * Ubicacion: PostgreSQL / scripts SQL.

3. El proyecto separa frontend, backend y base de datos.

   * Ubicacion: estructura del proyecto.

4. Las historias de usuario y requisitos estan documentados.

   * Ubicacion: `02_historias_requisitos`.

5. Las reglas de negocio estan documentadas.

   * Ubicacion: `03_reglas_negocio`.

6. Los diagramas UML estan actualizados.

   * Ubicacion: `04_arquitectura_uml`.

7. Las pruebas y evidencias estan guardadas.

   * Ubicacion: `05_pruebas_evidencias`.

8. Las vistas e indicadores de Power BI estan documentados.

   * Ubicacion: `06_powerbi`.

9. Los scripts SQL estan versionados.

   * Ubicacion: `07_scripts_sql`.

---

## Resumen general

| Criterio                                       | Estado |
| ---------------------------------------------- | ------ |
| Integracion Core - Homebanking                 | Cumple |
| Reglas de negocio del credito                  | Cumple |
| Seguridad RBAC + JWT                           | Cumple |
| Recuperaciones / Mora                          | Cumple |
| Calidad de datos, arquitectura y documentacion | Cumple |
