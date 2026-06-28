from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.routes.auth_routes import get_current_user_id
from app.services.banking_service import get_full_dashboard

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])


@router.get("")
def dashboard(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user_id),
):
    return get_full_dashboard(db, user_id)
