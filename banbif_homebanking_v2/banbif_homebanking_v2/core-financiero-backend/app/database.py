import os
from datetime import date, datetime
from decimal import Decimal
from typing import Any

import psycopg
from psycopg.rows import dict_row
from dotenv import load_dotenv


load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("Falta DATABASE_URL en el archivo .env")


def get_connection():
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)


def jsonable(value: Any):
    if isinstance(value, Decimal):
        return float(value)

    if isinstance(value, (datetime, date)):
        return value.isoformat()

    return value


def normalize_row(row: dict):
    return {key: jsonable(value) for key, value in row.items()}
