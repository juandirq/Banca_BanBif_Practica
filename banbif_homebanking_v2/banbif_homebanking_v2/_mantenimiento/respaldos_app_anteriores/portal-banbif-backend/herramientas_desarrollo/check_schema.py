from sqlalchemy import text
from app.db.session import engine

tables = ["user", "account", "movement", "creditapplication", "pagos"]

with engine.connect() as conn:
    print("\n=== REVISION DE TABLAS BANBIF ===\n")

    for table in tables:
        exists = conn.execute(
            text("""
                SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                    AND table_name = :table
                )
            """),
            {"table": table},
        ).scalar()

        if not exists:
            print(f"[NO EXISTE] {table}")
            continue

        print(f"[OK] {table}")

        columns = conn.execute(
            text("""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = 'public'
                AND table_name = :table
                ORDER BY ordinal_position
            """),
            {"table": table},
        ).fetchall()

        for col in columns:
            print(f"   - {col[0]} ({col[1]})")

        print()
