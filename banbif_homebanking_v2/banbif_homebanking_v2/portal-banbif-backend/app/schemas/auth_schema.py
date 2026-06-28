from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    identifier: str
    password: str


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    document: str
    password: str
    phone: str | None = None
    address: str | None = None
