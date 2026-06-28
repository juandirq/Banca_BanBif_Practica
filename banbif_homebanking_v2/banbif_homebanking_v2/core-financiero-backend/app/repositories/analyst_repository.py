from app.database import get_connection, normalize_row


def login_analyst(username: str, password: str):
    with get_connection() as conn:
        row = conn.execute(
            """
            SELECT
                id,
                full_name,
                username,
                email,
                role,
                is_active,
                created_at
            FROM core_analyst_user
            WHERE username = %s
              AND is_active = TRUE
              AND password_hash = crypt(%s, password_hash)
            """,
            (username, password)
        ).fetchone()

    if not row:
        return None

    return normalize_row(row)
