
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.routes.auth_routes import get_current_user_id
from app.schemas.banking_schema import CreditRequest
from app.services.banking_service import request_credit

router = APIRouter(prefix="/api/creditos", tags=["Creditos"])


@router.post("/solicitar")
def request_new_credit(
    payload: CreditRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return request_credit(
        db,
        user_id,
        payload.product,
        payload.amount,
        payload.term_months,
        payload.monthly_income,
        payload.purpose,
        payload.location,
        payload.income_type,
        payload.income_category,
        payload.employment_type,
        payload.employment_months,
        payload.marital_status,
        payload.spouse_documents,
        payload.bad_credit_history,
    )
