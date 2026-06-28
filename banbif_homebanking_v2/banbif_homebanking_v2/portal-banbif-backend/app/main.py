from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.core.config import settings, get_cors_origins
from app.db.session import engine

from app.routes.auth_routes import router as auth_router
from app.routes.dashboard_routes import router as dashboard_router
from app.routes.account_routes import router as account_router
from app.routes.transfer_routes import router as transfer_router
from app.routes.credit_routes import router as credit_router
from app.routes.payment_routes import router as payment_router
from app.routes.ahorros_routes import router as ahorros_router


app = FastAPI(
    title=settings.app_name,
    version="2.0.0",
    description="API limpia del Portal BanBif Home Banking",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def home():
    return {
        "message": "Portal BanBif Backend activo",
        "version": "2.0.0",
    }


@app.get("/api/ping")
def ping():
    return {
        "status": "ok",
        "message": "Backend conectado correctamente.",
    }


@app.get("/api/db-check")
def db_check():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT NOW() AS current_time")).fetchone()
        return {
            "database": "connected",
            "current_time": str(result[0]),
        }


app.include_router(auth_router)
app.include_router(dashboard_router)
app.include_router(account_router)
app.include_router(transfer_router)
app.include_router(credit_router)
app.include_router(payment_router)
app.include_router(ahorros_router)
# Router de transferencias agregado para PLIN y cuenta BanBif
from app.routes import transfer_routes as transfer_routes_fix
app.include_router(transfer_routes_fix.router)
