
from decimal import Decimal
from typing import Optional, Union
from pydantic import BaseModel


class CreateAccountRequest(BaseModel):
    account_type: str = "Cuenta Ahorro Digital"
    currency: str = "PEN"


class TransferRequest(BaseModel):
    from_account_id: Union[int, str]
    to_account_number: str
    amount: Decimal
    description: str = "Transferencia bancaria"
    token_digital: str


class CreditRequest(BaseModel):
    product: str = "Prestamo Efectivo BanBif"
    amount: Decimal
    term_months: int
    monthly_income: Decimal
    purpose: str = "Libre disponibilidad"
    location: str = "Lima"
    income_type: str = "fijo"
    income_category: str = "5ta"
    employment_type: str = "dependiente"
    employment_months: int = 12
    marital_status: str = "soltero"
    spouse_documents: str = "no"
    bad_credit_history: str = "no"


class PaymentRequest(BaseModel):
    account_id: int
    service: str
    contract_number: str
    amount: Decimal
    token_digital: str


class DepositRequest(BaseModel):
    account_id: int
    amount: Decimal
    description: str = "Deposito de ahorros"


class PlinTransferRequest(BaseModel):
    from_account_id: Union[int, str]
    phone: str
    amount: Decimal
    description: str = "Transferencia PLIN"
    token_digital: str

