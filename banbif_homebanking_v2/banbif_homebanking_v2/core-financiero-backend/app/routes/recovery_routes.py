from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from app.core.security import requiere_rol
from app.repositories.recovery_repository import (
    get_recovery_summary,
    list_recovery_cases,
    get_recovery_actions,
    register_recovery_action,
    transition_to_judicial,
    castigate_recovery_case
)


router = APIRouter(prefix="/api/core/recuperaciones", tags=["Recuperaciones y mora"])


ROLES_RECUPERACIONES = (
    "admin",
    "administrador",
    "admin_agencia",
    "gerencia",
    "riesgos",
    "comite",
    "comit?",
    "analista",
    "asesor"
)


ROLES_RECUPERACIONES_GESTION = (
    "riesgos",
)

ROLES_ESCALAMIENTO = (
    "riesgos",
)


class RecoveryActionRequest(BaseModel):
    action_type: str
    comment: Optional[str] = None
    result: Optional[str] = "Pendiente"
    status: Optional[str] = None


class RecoveryTransitionRequest(BaseModel):
    comment: Optional[str] = None


@router.get("/resumen")
def resumen_recuperaciones(current_user: dict = Depends(requiere_rol(*ROLES_RECUPERACIONES))):
    try:
        return {
            "usuario": current_user,
            "resumen": get_recovery_summary()
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo obtener el resumen de recuperaciones: {str(e)}"
        )


@router.get("/cartera")
def cartera_recuperaciones(
    banda: Optional[str] = Query(default=None),
    current_user: dict = Depends(requiere_rol(*ROLES_RECUPERACIONES))
):
    try:
        casos = list_recovery_cases(banda)

        return {
            "usuario": current_user,
            "total": len(casos),
            "banda": banda or "TODAS",
            "casos": casos
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo obtener la cartera en mora: {str(e)}"
        )


@router.get("/{recovery_case_id}/gestiones")
def historial_gestiones(
    recovery_case_id: int,
    current_user: dict = Depends(requiere_rol(*ROLES_RECUPERACIONES))
):
    try:
        return {
            "usuario": current_user,
            "recovery_case_id": recovery_case_id,
            "gestiones": get_recovery_actions(recovery_case_id)
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo obtener el historial de gestiones: {str(e)}"
        )


@router.post("/{recovery_case_id}/gestion")
def registrar_gestion(
    recovery_case_id: int,
    body: RecoveryActionRequest,
    current_user: dict = Depends(requiere_rol(*ROLES_RECUPERACIONES_GESTION))
):
    try:
        resultado = register_recovery_action(
            recovery_case_id=recovery_case_id,
            action_type=body.action_type,
            comment=body.comment,
            result=body.result,
            created_by=current_user.get("id"),
            status=body.status
        )

        return {
            "mensaje": "Gestion de cobranza registrada correctamente.",
            "usuario": current_user,
            "resultado": resultado
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo registrar la gestion: {str(e)}"
        )


@router.post("/{recovery_case_id}/judicial")
def derivar_judicial(
    recovery_case_id: int,
    body: RecoveryTransitionRequest | None = None,
    current_user: dict = Depends(requiere_rol(*ROLES_ESCALAMIENTO))
):
    try:
        resultado = transition_to_judicial(
            recovery_case_id=recovery_case_id,
            created_by=current_user.get("id"),
            comment=body.comment if body else None
        )

        return {
            "mensaje": "Caso derivado a cobranza judicial correctamente.",
            "usuario": current_user,
            "resultado": resultado
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo derivar a judicial: {str(e)}"
        )


@router.post("/{recovery_case_id}/castigar")
def castigar_caso(
    recovery_case_id: int,
    body: RecoveryTransitionRequest | None = None,
    current_user: dict = Depends(requiere_rol(*ROLES_ESCALAMIENTO))
):
    try:
        resultado = castigate_recovery_case(
            recovery_case_id=recovery_case_id,
            created_by=current_user.get("id"),
            comment=body.comment if body else None
        )

        return {
            "mensaje": "Caso propuesto para castigo correctamente.",
            "usuario": current_user,
            "resultado": resultado
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo castigar el caso: {str(e)}"
        )
