from fastapi import APIRouter, HTTPException, Depends

from app.core.security import get_current_user, requiere_rol
from app.repositories.credit_repository import (
    db_check,
    get_credit_columns,
    list_credit_applications,
    get_credit_application,
    update_credit_decision,
    disburse_credit_application
)
from app.schemas.credit_schema import DecisionRequest


router = APIRouter(prefix="/api/core", tags=["Core financiero"])


ROLES_INTERNOS = (
    "asesor",
    "analista",
    "administrador",
    "admin",
    "admin_agencia",
    "riesgos",
    "comite",
    "comit?",
    "gerencia"
)

ROLES_DECISION = (
    "asesor",
    "analista",
    "riesgos",
    "comite",
    "comit?",
    "gerencia"
)

ROLES_ADMIN = (
    "administrador",
    "admin",
    "gerencia"
)

ROLES_DESEMBOLSO = (
    "admin_agencia",
)


@router.get("/ping")
def ping():
    return {
        "ok": True,
        "servicio": "core-financiero-backend",
        "mensaje": "Core financiero activo"
    }


@router.get("/me")
def me(current_user: dict = Depends(get_current_user)):
    return {
        "ok": True,
        "usuario": current_user
    }


@router.get("/db-check")
def check_database(current_user: dict = Depends(requiere_rol(*ROLES_ADMIN))):
    try:
        return {
            "status": "connected",
            "usuario": current_user,
            "data": db_check()
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo conectar a la base de datos: {str(e)}"
        )


@router.get("/columnas-creditos")
def columnas_creditos(current_user: dict = Depends(requiere_rol(*ROLES_ADMIN))):
    try:
        return {
            "tabla": "creditapplication",
            "usuario": current_user,
            "columnas": get_credit_columns()
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudieron leer las columnas: {str(e)}"
        )


@router.get("/solicitudes")
def listar_solicitudes(current_user: dict = Depends(requiere_rol(*ROLES_INTERNOS))):
    try:
        solicitudes = list_credit_applications()

        return {
            "total": len(solicitudes),
            "usuario": current_user,
            "solicitudes": solicitudes
        }

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudieron listar las solicitudes: {str(e)}"
        )


@router.get("/solicitudes/{solicitud_id}")
def obtener_solicitud(
    solicitud_id: str,
    current_user: dict = Depends(requiere_rol(*ROLES_INTERNOS))
):
    try:
        solicitud = get_credit_application(solicitud_id)

        if not solicitud:
            raise HTTPException(
                status_code=404,
                detail="Solicitud no encontrada"
            )

        return {
            "usuario": current_user,
            "solicitud": solicitud
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo obtener la solicitud: {str(e)}"
        )


@router.get("/solicitudes/{solicitud_id}/scoring")
def scoring_solicitud(
    solicitud_id: str,
    current_user: dict = Depends(requiere_rol(*ROLES_INTERNOS))
):
    try:
        solicitud = get_credit_application(solicitud_id)

        if not solicitud:
            raise HTTPException(
                status_code=404,
                detail="Solicitud no encontrada"
            )

        return {
            "solicitud_id": solicitud_id,
            "usuario": current_user,
            "scoring": solicitud["scoring"]
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo calcular scoring: {str(e)}"
        )


@router.post("/solicitudes/{solicitud_id}/decision")
def tomar_decision(
    solicitud_id: str,
    body: DecisionRequest,
    current_user: dict = Depends(requiere_rol(*ROLES_DECISION))
):
    decision_raw = body.decision.strip().lower()

    decisiones_validas = {
        "aprobar": "Aprobado",
        "aprobado": "Aprobado",
        "rechazar": "Rechazado",
        "rechazado": "Rechazado",
        "evaluacion": "En evaluacion",
        "en evaluacion": "En evaluacion",
        "en_evaluacion": "En evaluacion",
        "pendiente": "En evaluacion",
        "comite": "En comite",
        "comit?": "En comite",
        "en comite": "En comite",
        "en comit?": "En comite",
        "en_comite": "En comite",
        "derivar comite": "En comite",
        "derivar_a_comite": "En comite"
    }

    if decision_raw not in decisiones_validas:
        raise HTTPException(
            status_code=400,
            detail="Decision invalida. Usa: aprobado, rechazado, en evaluacion o comite."
        )

    nuevo_estado = decisiones_validas[decision_raw]

    try:
        solicitud = update_credit_decision(
            solicitud_id,
            nuevo_estado,
            body.observacion
        )

        if not solicitud:
            raise HTTPException(
                status_code=404,
                detail="Solicitud no encontrada"
            )

        return {
            "mensaje": "Decision registrada correctamente",
            "decision": nuevo_estado,
            "observacion": body.observacion,
            "analista": current_user,
            "solicitud": solicitud
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo registrar la decision: {str(e)}"
        )


@router.post("/solicitudes/{solicitud_id}/desembolsar")
def desembolsar_solicitud(
    solicitud_id: str,
    current_user: dict = Depends(requiere_rol(*ROLES_DESEMBOLSO))
):
    try:
        resultado = disburse_credit_application(
            solicitud_id,
            current_user.get("id")
        )

        if not resultado:
            raise HTTPException(
                status_code=404,
                detail="Solicitud no encontrada"
            )

        return {
            "mensaje": "Desembolso registrado correctamente. El saldo y movimientos del cliente fueron actualizados.",
            "usuario": current_user,
            "resultado": resultado
        }

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e)
        )

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo registrar el desembolso: {str(e)}"
        )
