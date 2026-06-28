# BANBIF HOMEBANKING + CORE FINANCIERO

Proyecto web que integra un Homebanking para clientes y un Core Financiero interno para la gestion de creditos.

Ambos sistemas trabajan con la misma base de datos PostgreSQL:

bd_core_financiero

## Estructura principal

### core-financiero-backend

Backend interno del Core Financiero. Administra evaluacion crediticia, reglas de negocio, roles internos, desembolsos, mora y recuperaciones.

### core-financiero-frontend

Frontend interno del Core Financiero. Permite revisar solicitudes, evaluar creditos, aprobar, rechazar, derivar, desembolsar y gestionar recuperaciones.

### portal-banbif-backend

Backend del Homebanking. Permite el acceso del cliente, consulta de cuentas, movimientos, pagos y datos relacionados al credito.

### portal-banbif-frontend

Frontend del Homebanking. Permite al cliente ingresar al sistema, consultar cuentas, revisar movimientos y visualizar informacion relacionada a sus productos financieros.

### sql

Contiene los scripts de base de datos del proyecto.

### docs

Contiene la documentacion, reglas de negocio, UML, evidencias y archivos de entrega.

## Ejecucion rapida

Se deben ejecutar cuatro servicios en terminales separadas.

### Core backend

cd core-financiero-backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001

### Homebanking backend

cd portal-banbif-backend
.\venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000

### Homebanking frontend

cd portal-banbif-frontend
npm.cmd run dev

URL: http://localhost:5173

### Core frontend

cd core-financiero-frontend
npm.cmd run dev

URL: http://localhost:5174

## Usuarios de prueba

Homebanking: clientes 71000001 hasta 71000030, clave 123456.

Core Financiero:
- Analista Nivel 1: 40123456 / 123456
- Analista Nivel 2: 40234567 / 123456
- Analista Nivel 3: 40345678 / 123456
- Agencia: 40678901 / 123456
- Riesgos: 40789012 / 123456
- Comite: 40890123 / 123456
- Gerencia: 40901234 / 123456
