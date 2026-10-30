import json
from pathlib import Path
from datetime import date
from decimal import Decimal

from sqlalchemy import text
from app.db.database import engine


DATA_FILE = Path(__file__).parent / "weather_test_data.json"

# Coordinates originally requested from Open-Meteo.
REQUESTED_LATITUDE = -29.0852
REQUESTED_LONGITUDE = 26.1596

with DATA_FILE.open(encoding="utf-8-sig") as file:
    weather = json.load(file)

daily = weather["daily"]
dates = daily["time"]

# Validate that every variable has exactly one value per date.
variables = [
    "temperature_2m_mean",
    "temperature_2m_max",
    "temperature_2m_min",
    "precipitation_sum",
]

for variable in variables:
    if len(daily[variable]) != len(dates):
        raise ValueError(
            f"{variable} has {len(daily[variable])} values "
            f"for {len(dates)} dates"
        )

records = []

for index, day in enumerate(dates):
    minimum = daily["temperature_2m_min"][index]
    mean = daily["temperature_2m_mean"][index]
    maximum = daily["temperature_2m_max"][index]
    precipitation = daily["precipitation_sum"][index]

    # Reject invalid or incomplete daily records.
    if any(value is None for value in (
        minimum, mean, maximum, precipitation
    )):
        raise ValueError(f"Incomplete weather record for {day}")

    if not minimum <= mean <= maximum:
        raise ValueError(f"Inconsistent temperatures for {day}")

    if precipitation < 0:
        raise ValueError(f"Negative precipitation for {day}")

    records.append({
        "observation_date": date.fromisoformat(day),
        "requested_latitude": REQUESTED_LATITUDE,
        "requested_longitude": REQUESTED_LONGITUDE,
        "provider_latitude": weather["latitude"],
        "provider_longitude": weather["longitude"],
        "source_name": "Open-Meteo",
        "source_dataset": "historical_archive_api",
        "data_type": "historical",
        "data_basis": "model_reanalysis",
        "temperature_mean_c": Decimal(str(mean)),
        "temperature_max_c": Decimal(str(maximum)),
        "temperature_min_c": Decimal(str(minimum)),
        "precipitation_mm": Decimal(str(precipitation)),
        "timezone_name": weather["timezone"],
        "source_metadata": json.dumps({
            "elevation_m": weather.get("elevation"),
            "model_selection": "API default; exact model not recorded",
            "variables": variables,
        }),
    })

insert_sql = text("""
    INSERT INTO agriculture.daily_weather_observations (
        observation_date,
        requested_latitude,
        requested_longitude,
        provider_latitude,
        provider_longitude,
        source_name,
        source_dataset,
        data_type,
        data_basis,
        temperature_mean_c,
        temperature_max_c,
        temperature_min_c,
        precipitation_mm,
        timezone_name,
        source_metadata
    )
    SELECT
        :observation_date,
        :requested_latitude,
        :requested_longitude,
        :provider_latitude,
        :provider_longitude,
        :source_name,
        :source_dataset,
        :data_type,
        :data_basis,
        :temperature_mean_c,
        :temperature_max_c,
        :temperature_min_c,
        :precipitation_mm,
        :timezone_name,
        CAST(:source_metadata AS jsonb)
    WHERE NOT EXISTS (
        SELECT 1
        FROM agriculture.daily_weather_observations existing
        WHERE existing.observation_date = :observation_date
          AND existing.requested_latitude = :requested_latitude
          AND existing.requested_longitude = :requested_longitude
          AND existing.source_name = :source_name
          AND existing.source_dataset = :source_dataset
    )
    RETURNING id, observation_date
""")

with engine.begin() as connection:
    inserted = []

    for record in records:
        result = connection.execute(insert_sql, record)
        inserted.extend(result.fetchall())

print(f"Validated records: {len(records)}")
print(f"New records inserted: {len(inserted)}")

for row in inserted:
    print(f"  {row.observation_date}: {row.id}")