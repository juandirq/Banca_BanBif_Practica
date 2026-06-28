
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.routes.auth_routes import get_current_user_id
from app.schemas.banking_schema import PaymentRequest
from app.services.banking_service import register_payment

router = APIRouter(prefix="/api/pagos", tags=["Pagos"])


@router.post("")
def pay_service(
    payload: PaymentRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return register_payment(
        db,
        user_id,
        payload.account_id,
        payload.service,
        payload.contract_number,
        payload.amount,
        payload.token_digital,
    )
