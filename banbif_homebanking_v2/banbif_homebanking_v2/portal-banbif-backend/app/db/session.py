from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings


def normalize_database_url(url: str) -> str:
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+psycopg://", 1)

    if "sslmode=" not in url:
        separator = "&" if "?" in url else "?"
        url = f"{url}{separator}sslmode=require"

    return url


database_url = normalize_database_url(settings.database_url)

engine = create_engine(
    database_url,
    echo=False,
    pool_pre_ping=True,
    pool_recycle=120,
    pool_size=5,
    max_overflow=5,
    pool_timeout=10,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def check_database_connection():
    with engine.connect() as conn:
        return conn.execute("SELECT NOW() AS current_time").fetchone()
