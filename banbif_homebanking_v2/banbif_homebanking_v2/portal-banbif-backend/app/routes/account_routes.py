from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.routes.auth_routes import get_current_user_id
from app.schemas.banking_schema import CreateAccountRequest
from app.services.banking_service import create_account

router = APIRouter(prefix="/api/cuentas", tags=["Cuentas"])


@router.post("/crear")
def create_new_account(
    payload: CreateAccountRequest,
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return create_account(db, user_id, payload.account_type, payload.currency)
