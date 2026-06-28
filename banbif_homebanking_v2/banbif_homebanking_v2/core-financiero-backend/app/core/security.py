import os
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt


JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "cambia-esta-clave-en-env")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "120"))

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/core/auth/login")


def normalizar_rol(role: Optional[str]) -> str:
    if not role:
        return ""

    rol = (
        str(role)
        .strip()
        .lower()
        .replace("?", "a")
        .replace("?", "e")
        .replace("?", "i")
        .replace("?", "o")
        .replace("?", "u")
        .replace("?", "n")
        .replace("-", "_")
        .replace(" ", "_")
    )

    mapa_roles = {
        "admin": "admin",
        "administrador": "admin",

        # IMPORTANTE:
        # admin_agencia NO debe convertirse en admin.
        # Es un rol limitado para seguimiento/agencia.
        "admin_agencia": "admin_agencia",
        "administrador_agencia": "admin_agencia",

        "gerencia": "gerencia",
        "riesgos": "riesgos",
        "comite": "comite",
        "comite_creditos": "comite",

        "asesor": "asesor",

        "analista": "analista",
        "analista_n1": "analista",
        "analista_n2": "analista",
        "analista_n3": "analista",
        "analista_n4": "analista",
        "senior_creditos": "analista",

        "cliente": "cliente",
    }

    return mapa_roles.get(rol, rol)


def crear_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()

    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalido o expirado.",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])

        username = payload.get("sub")
        role = payload.get("role")

        if username is None or role is None:
            raise credentials_exception

        return {
            "id": payload.get("id"),
            "username": username,
            "full_name": payload.get("full_name"),
            "email": payload.get("email"),
            "role": role,
            "role_normalized": normalizar_rol(role),
        }

    except JWTError:
        raise credentials_exception


def requiere_rol(*roles_permitidos: str):
    roles_permitidos_normalizados = {normalizar_rol(r) for r in roles_permitidos}

    def validar_rol(current_user: dict = Depends(get_current_user)) -> dict:
        rol_usuario = current_user.get("role_normalized", "")

        if rol_usuario not in roles_permitidos_normalizados:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permisos para realizar esta accion."
            )

        return current_user

    return validar_rol
