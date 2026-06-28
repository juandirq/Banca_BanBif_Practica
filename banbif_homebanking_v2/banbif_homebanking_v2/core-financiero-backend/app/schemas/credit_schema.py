from typing import Optional
from pydantic import BaseModel


class DecisionRequest(BaseModel):
    decision: str
    observacion: Optional[str] = None
    analista: Optional[str] = None
