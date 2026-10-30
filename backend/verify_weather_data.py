
from sqlalchemy import text
from app.db.database import engine

query = text("""
    SELECT
        observation_date,
        temperature_min_c,
        temperature_mean_c,
        temperature_max_c,
        precipitation_mm,
        source_name
    FROM agriculture.daily_weather_observations
    ORDER BY observation_date
""")

with engine.connect() as connection:
    rows = connection.execute(query).fetchall()

print("Date       | Min °C | Mean °C | Max °C | Rain mm | Source")
print("-" * 75)

for row in rows:
    print(
        f"{row[0]} | {row[1]:6} | {row[2]:7} | "
        f"{row[3]:6} | {row[4]:7} | {row[5]}"
    )

print(f"\nTotal records: {len(rows)}")
