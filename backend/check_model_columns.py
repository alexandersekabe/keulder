
from app.db.base import Base
import app.shared.models
from app.db.database import engine
from sqlalchemy import inspect

inspector = inspect(engine)

print("MODEL vs DATABASE")
print("=" * 55)

for table in Base.metadata.sorted_tables:
    model_columns = {column.name for column in table.columns}
    database_columns = {
        column["name"]
        for column in inspector.get_columns(
            table.name,
            schema=table.schema,
        )
    }

    missing = sorted(database_columns - model_columns)
    extra = sorted(model_columns - database_columns)

    print(f"\n{table.fullname}")
    print("  Model columns:   ", ", ".join(sorted(model_columns)))
    print("  Database columns:", ", ".join(sorted(database_columns)))
    print("  Missing in model:", ", ".join(missing) or "None")
    print("  Extra in model:  ", ", ".join(extra) or "None")
