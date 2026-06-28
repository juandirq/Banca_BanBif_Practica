from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.security import decode_access_token
from app.schemas.auth_schema import LoginRequest, RegisterRequest
from app.services.auth_service import login_user, register_user


router = APIRouter(tags=["Autenticacion"])
security = HTTPBearer()


def public_user(user: dict) -> dict:
    blocked = {"password", "password_hash", "hashed_password", "contrasena"}
    return {k: v for k, v in user.items() if k not in blocked}


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    payload = decode_access_token(credentials.credentials)

    if not payload or "sub" not in payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalido.",
        )

    return int(payload["sub"])


@router.post("/api/login")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    return login_user(
        db,
        payload.identifier,
        payload.password,
    )


@router.post("/api/register")
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
    return register_user(
        db,
        payload.name,
        payload.email,
        payload.document,
        payload.password,
        payload.phone,
        payload.address,
    )


@router.get("/api/me")
def me(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    row = db.execute(
        text("""
            SELECT *
            FROM public."user"
            WHERE id = :user_id
            LIMIT 1
        """),
        {"user_id": user_id},
    ).fetchone()

    if not row:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado.",
        )

    return public_user(dict(row._mapping))


@router.post("/api/logout")
def logout():
    return {"message": "Sesion cerrada correctamente."}
