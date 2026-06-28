from datetime import datetime
from sqlalchemy import text
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.core.security import verify_password, hash_password, create_access_token
from app.services.banking_service import get_dashboard_preview


def row_to_dict(row) -> dict:
    return dict(row._mapping) if row else {}


def get_user_id(user: dict):
    return user.get("id")


def find_user_by_identifier(db: Session, identifier: str) -> dict | None:
    row = db.execute(
        text("""
            SELECT *
            FROM public."user"
            WHERE LOWER(email) = LOWER(:identifier)
               OR document = :identifier
            LIMIT 1
        """),
        {"identifier": identifier},
    ).fetchone()

    return row_to_dict(row) if row else None


def public_user(user: dict) -> dict:
    blocked = {"password", "password_hash", "hashed_password", "contrasena"}
    return {k: v for k, v in user.items() if k not in blocked}


def login_user(db: Session, identifier: str, password: str) -> dict:
    user = find_user_by_identifier(db, identifier)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contrasena incorrectos.",
        )

    stored_password = user.get("password_hash")

    if not verify_password(password, stored_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuario o contrasena incorrectos.",
        )

    user_id = get_user_id(user)

    token = create_access_token(
        {
            "sub": str(user_id),
            "email": str(user.get("email", "")),
        }
    )

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": public_user(user),
        "dashboard_preview": get_dashboard_preview(db, user_id),
    }


def register_user(
    db: Session,
    name: str,
    email: str,
    document: str,
    password: str,
    phone: str | None = None,
    address: str | None = None,
) -> dict:
    try:
        name = (name or "").strip()
        email = (email or "").strip().lower()
        document = (document or "").strip()
        phone = (phone or "").strip()
        address = (address or "").strip()

        if len(name) < 3:
            raise HTTPException(status_code=400, detail="Ingresa un nombre completo valido.")

        if len(document) < 8:
            raise HTTPException(status_code=400, detail="El documento debe tener al menos 8 digitos.")

        if len(phone) != 9 or not phone.isdigit():
            raise HTTPException(status_code=400, detail="El telefono debe tener 9 digitos.")

        if len(password) < 6:
            raise HTTPException(status_code=400, detail="La contrasena debe tener al menos 6 caracteres.")

        existing_email = db.execute(
            text('SELECT id FROM public."user" WHERE LOWER(email) = LOWER(:email) LIMIT 1'),
            {"email": email},
        ).fetchone()

        if existing_email:
            raise HTTPException(
                status_code=400,
                detail="Ya existe un usuario registrado con ese correo.",
            )

        existing_document = db.execute(
            text('SELECT id FROM public."user" WHERE document = :document LIMIT 1'),
            {"document": document},
        ).fetchone()

        if existing_document:
            raise HTTPException(
                status_code=400,
                detail="Ya existe un usuario registrado con ese documento.",
            )

        clean_address = address if address else "Sin direccion registrada"

        row = db.execute(
            text("""
                INSERT INTO public."user"
                (document, full_name, email, password_hash, phone, address, created_at)
                VALUES
                (:document, :full_name, :email, :password_hash, :phone, :address, :created_at)
                RETURNING *
            """),
            {
                "document": document,
                "full_name": name,
                "email": email,
                "password_hash": hash_password(password),
                "phone": phone,
                "address": clean_address,
                "created_at": datetime.now(),
            },
        ).fetchone()

        db.commit()

        user = row_to_dict(row)
        user_id = get_user_id(user)

        token = create_access_token(
            {
                "sub": str(user_id),
                "email": str(user.get("email", "")),
            }
        )

        return {
            "access_token": token,
            "token_type": "bearer",
            "user": public_user(user),
            "dashboard_preview": get_dashboard_preview(db, user_id),
        }

    except HTTPException:
        db.rollback()
        raise

    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Error al registrar usuario: {str(e)}",
        )
