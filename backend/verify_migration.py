from sqlalchemy import inspect
from app.db.database import engine

inspector = inspect(engine)

for table in [
    "daily_weather_observations",
    "crop_heat_thresholds",
]:
    print(f"\nTable: agriculture.{table}")

    for column in inspector.get_columns(
        table,
        schema="agriculture",
    ):
        print(f"  {column['name']}: {column['type']}")