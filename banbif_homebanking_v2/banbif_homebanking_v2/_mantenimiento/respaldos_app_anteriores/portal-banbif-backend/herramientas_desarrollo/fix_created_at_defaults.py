from sqlalchemy import text
from app.db.session import engine

with engine.begin() as conn:
    conn.execute(text('ALTER TABLE public."user" ALTER COLUMN created_at SET DEFAULT NOW();'))
    conn.execute(text('ALTER TABLE public.account ALTER COLUMN created_at SET DEFAULT NOW();'))
    conn.execute(text('ALTER TABLE public.movement ALTER COLUMN created_at SET DEFAULT NOW();'))
    conn.execute(text('ALTER TABLE public.creditapplication ALTER COLUMN created_at SET DEFAULT NOW();'))
    conn.execute(text('ALTER TABLE public.pagos ALTER COLUMN created_at SET DEFAULT NOW();'))

print("Defaults de created_at configurados correctamente.")
