from decimal import Decimal

from sqlalchemy import text
from app.db.database import engine


# PROVISIONAL SCREENING SETTING — NOT A VALIDATED CROP THRESHOLD
HEAT_THRESHOLD_C = Decimal("30.0")

# Coordinates originally requested from the weather provider.
REQUESTED_LATITUDE = -29.0852
REQUESTED_LONGITUDE = 26.1596

query = text("""
    SELECT
        observation_date,
        temperature_max_c
    FROM agriculture.daily_weather_observations
    WHERE requested_latitude = :latitude
      AND requested_longitude = :longitude
    ORDER BY observation_date
""")

with engine.connect() as connection:
    rows = connection.execute(
        query,
        {
            "latitude": REQUESTED_LATITUDE,
            "longitude": REQUESTED_LONGITUDE,
        },
    ).fetchall()


if not rows:
    raise SystemExit("No weather records found for these coordinates.")

valid_days = 0
missing_days = 0
heat_stress_days = 0
cumulative_exceedance_c_days = Decimal("0")

print("MAIZE HEAT-EXPOSURE SCREENING")
print(f"Provisional threshold: {HEAT_THRESHOLD_C} °C")
print("Indicator: daily maximum temperature")
print("-" * 75)
print("Date       | Max °C | Exceedance °C | Above threshold?")
print("-" * 75)

for observation_date, maximum in rows:
    if maximum is None:
        missing_days += 1
        print(f"{observation_date} | Missing temperature data")
        continue

    valid_days += 1
    maximum = Decimal(str(maximum))

    exceedance = max(
        Decimal("0"),
        maximum - HEAT_THRESHOLD_C,
    )

    exceeded = maximum > HEAT_THRESHOLD_C

    if exceeded:
        heat_stress_days += 1
        cumulative_exceedance_c_days += exceedance

    print(
        f"{observation_date} | "
        f"{maximum:6.2f} | "
        f"{exceedance:13.2f} | "
        f"{'YES' if exceeded else 'NO'}"
    )

print("-" * 75)
print(f"Days with temperature data: {valid_days}")
print(f"Days with missing temperature: {missing_days}")
print(f"Days above threshold: {heat_stress_days}")
print(
    "Cumulative temperature exceedance: "
    f"{cumulative_exceedance_c_days:.2f} °C-days"
)

print()
print(
    "CAUTION: These are screening indicators, not proof of crop damage. "
    "The threshold is provisional and does not account for crop growth stage, "
    "duration of exposure, or other environmental conditions."
)