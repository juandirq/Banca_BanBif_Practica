from fastapi import APIRouter, HTTPException

from app.core.security import crear_access_token
from app.repositories.analyst_repository import login_analyst
from app.schemas.auth_schema import AnalystLoginRequest


router = APIRouter(prefix="/api/core/auth", tags=["Autenticacion interna"])


@router.post("/login")
def login(body: AnalystLoginRequest):
    analyst = login_analyst(
        body.username.strip(),
        body.password.strip()
    )

    if not analyst:
        raise HTTPException(
            status_code=401,
            detail="Credenciales internas incorrectas."
        )

    access_token = crear_access_token(
        {
            "sub": analyst["username"],
            "id": analyst["id"],
            "full_name": analyst["full_name"],
            "email": analyst["email"],
            "role": analyst["role"],
        }
    )

    return {
        "mensaje": "Acceso interno autorizado",
        "access_token": access_token,
        "token_type": "bearer",
        "analyst": analyst
    }
