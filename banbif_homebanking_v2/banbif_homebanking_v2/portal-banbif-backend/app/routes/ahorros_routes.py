from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.routes.auth_routes import get_current_user_id
from app.schemas.banking_schema import DepositRequest
from app.services.banking_service import make_deposit

router = APIRouter(prefix="/api/ahorros", tags=["Ahorros"])


@router.post("/deposito")
def deposit(
    payload: DepositRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return make_deposit(
        db,
        user_id,
        payload.account_id,
        payload.amount,
        payload.description,
    )
