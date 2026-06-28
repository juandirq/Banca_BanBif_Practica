from sqlalchemy import text
from app.db.session import engine

email = "juanito@gmail.com"
document = "60842575"

with engine.connect() as conn:
    rows = conn.execute(
        text("""
            SELECT id, document, full_name, email, phone, address, created_at
            FROM public."user"
            WHERE LOWER(email) = LOWER(:email)
               OR document = :document
            ORDER BY id
        """),
        {"email": email, "document": document},
    ).fetchall()

    if not rows:
        print("No existe usuario con ese correo ni documento.")
    else:
        print("Usuarios encontrados:")
        for row in rows:
            print(dict(row._mapping))
