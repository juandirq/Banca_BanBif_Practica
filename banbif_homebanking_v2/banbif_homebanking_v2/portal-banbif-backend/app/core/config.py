from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Portal BanBif Backend"
    app_env: str = "development"

    database_url: str

    jwt_secret_key: str = "dev_secret_key"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 120

    cors_origins: str = "http://localhost:5173,http://127.0.0.1:5173"

    class Config:
        env_file = ".env"


settings = Settings()


def get_cors_origins() -> list[str]:
    return [origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()]
