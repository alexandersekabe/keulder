
from decimal import Decimal
from datetime import date

from sqlalchemy import text
from sqlalchemy.orm import Session


def calculate_maize_heat(
    db: Session,
    latitude: float,
    longitude: float,
    start_date: date,
    end_date: date,
    threshold_c: float = 30.0,
) -> dict:
    """Calculate daily maximum-temperature exceedance for a location."""

    threshold = Decimal(str(threshold_c))
    if start_date > end_date:
        raise ValueError("start_date must be on or before end_date.")

    if not Decimal("-90") <= Decimal(str(latitude)) <= Decimal("90"):
        raise ValueError("Latitude must be between -90 and 90.")

    if not Decimal("-180") <= Decimal(str(longitude)) <= Decimal("180"):
        raise ValueError("Longitude must be between -180 and 180.")

    if not Decimal("-100") <= threshold <= Decimal("100"):
        raise ValueError("Threshold must be between -100 and 100 °C.")


    query = text("""
        SELECT observation_date, temperature_max_c
        FROM agriculture.daily_weather_observations
        WHERE requested_latitude = :latitude
          AND requested_longitude = :longitude
          AND observation_date >= :start_date
          AND observation_date <= :end_date
        ORDER BY observation_date
    """)

    rows = db.execute(
        query,
        {
            "latitude": latitude,
            "longitude": longitude,
            "start_date": start_date,
            "end_date": end_date,
        },
    ).fetchall()

    if not rows:
        return {
            "latitude": latitude,
            "longitude": longitude,
            "threshold_c": float(threshold),
            "days_with_data": 0,
            "missing_days": 0,
            "days_above_threshold": 0,
            "cumulative_exceedance_c_days": 0.0,
            "daily_results": [],
        }

    daily_results = []
    missing_days = 0
    days_above_threshold = 0
    cumulative_exceedance = Decimal("0")

    for observation_date, maximum in rows:
        if maximum is None:
            missing_days += 1
            daily_results.append({
                "date": observation_date.isoformat(),
                "maximum_c": None,
                "exceedance_c": None,
                "above_threshold": None,
            })
            continue

        maximum = Decimal(str(maximum))
        exceedance = max(Decimal("0"), maximum - threshold)
        above_threshold = maximum > threshold

        if above_threshold:
            days_above_threshold += 1
            cumulative_exceedance += exceedance

        daily_results.append({
            "date": observation_date.isoformat(),
            "maximum_c": float(maximum),
            "exceedance_c": float(exceedance),
            "above_threshold": above_threshold,
        })

    return {
        "latitude": latitude,
        "longitude": longitude,
        "threshold_c": float(threshold),
        "days_with_data": len(rows) - missing_days,
        "missing_days": missing_days,
        "days_above_threshold": days_above_threshold,
        "cumulative_exceedance_c_days": float(cumulative_exceedance),
        "daily_results": daily_results,
        "interpretation": (
            "Screening indicator only; not proof of crop damage."
        ),
    }
