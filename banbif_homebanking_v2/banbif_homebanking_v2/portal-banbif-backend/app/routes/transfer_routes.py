from decimal import Decimal

from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.routes.auth_routes import get_current_user_id
from app.schemas.banking_schema import TransferRequest, PlinTransferRequest
from app.services.banking_service import make_transfer

router = APIRouter(tags=["Transferencias"])


def row_to_dict(row) -> dict:
    return dict(row._mapping) if row else {}


def validate_token(token: str):
    if str(token or "").strip() != "123456":
        raise HTTPException(status_code=401, detail="Token Digital invalido.")


@router.post("/api/transferencias")
def transfer(
    payload: TransferRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return make_transfer(
        db,
        user_id,
        payload.from_account_id,
        payload.to_account_number,
        payload.amount,
        payload.description,
        payload.token_digital,
    )



@router.post("/api/transferencias/plin")
def transfer_plin_yape(
    payload: PlinTransferRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return make_transfer(
        db,
        user_id,
        payload.from_account_id,
        payload.phone,
        payload.amount,
        payload.description,
        payload.token_digital,
    )
