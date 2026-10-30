from sqlalchemy import text
from app.db.database import engine

with engine.connect() as conn:
    rows = conn.execute(text("""
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'agriculture'
          AND table_type = 'BASE TABLE'
        ORDER BY table_name
    """)).fetchall()

    if rows:
        for row in rows:
            print(row[0])
    else:
        print("No tables found in agriculture schema")
