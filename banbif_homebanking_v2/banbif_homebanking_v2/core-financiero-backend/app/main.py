import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.credit_routes import router as credit_router
from app.routes.recovery_routes import router as recovery_router
from app.routes.auth_routes import router as auth_router


app = FastAPI(
    title="Core Financiero BanBif",
    description="API interna del banco para scoring, riesgo, decision de creditos y acceso de analistas.",
    version="1.0.0",
)


cors_origins_env = os.getenv("CORS_ORIGINS", "")

cors_origins = [
    origin.strip()
    for origin in cors_origins_env.split(",")
    if origin.strip()
]

if not cors_origins:
    cors_origins = [
        "http://localhost:5174",
        "http://127.0.0.1:5174",
        "https://core-financiero-frontend.vercel.app",
    ]


app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def home():
    return {
        "mensaje": "Core Financiero BanBif activo",
        "documentacion": "/docs",
    }


app.include_router(credit_router)
app.include_router(recovery_router)
app.include_router(auth_router)


@app.get("/api/ping")
def ping():
    return {
        "status": "ok",
        "service": "core-financiero-backend",
    }