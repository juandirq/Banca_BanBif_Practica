# HOMEBANKING BACKEND

Backend del Homebanking BanBif.

Permite el acceso del cliente, consulta de cuentas, movimientos, pagos y datos relacionados al credito.

## Tecnologia

- Python
- FastAPI
- PostgreSQL

## Estructura principal

- app: codigo principal del backend.
- venv: entorno virtual local.
- .env: variables de configuracion.
- requirements.txt: dependencias del backend.

## Ejecucion

Desde esta carpeta ejecutar:

.\venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000

Ruta de prueba:

http://127.0.0.1:8000/api/ping
