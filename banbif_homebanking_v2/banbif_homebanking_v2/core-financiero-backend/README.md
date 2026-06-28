# CORE FINANCIERO BACKEND

Backend interno del Core Financiero BanBif.

Administra la evaluacion crediticia, reglas de negocio, roles internos, desembolsos, mora y recuperaciones.

## Tecnologia

- Python
- FastAPI
- PostgreSQL

## Estructura principal

- app: codigo principal del backend.
- .venv: entorno virtual local.
- .env: variables de configuracion.

## Ejecucion

Desde esta carpeta ejecutar:

.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001

Ruta de prueba:

http://127.0.0.1:8001/api/core/ping
