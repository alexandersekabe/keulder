
from app.db.database import SessionLocal
from app.services.maize_heat import calculate_maize_heat


with SessionLocal() as db:
    result = calculate_maize_heat(
        db=db,
        latitude=-29.0852,
        longitude=26.1596,
        threshold_c=30.0,
    )

print("Service result")
print(f"Days with data: {result['days_with_data']}")
print(f"Missing days: {result['missing_days']}")
print(f"Days above threshold: {result['days_above_threshold']}")
print(
    "Cumulative exceedance: "
    f"{result['cumulative_exceedance_c_days']:.2f} °C-days"
)

print("\nDaily results:")
for day in result["daily_results"]:
    print(day)
