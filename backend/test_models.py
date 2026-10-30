from sqlalchemy import inspect

from app.db.database import engine
from app.shared.models.organisation import Organisation, OrganisationType


inspector = inspect(engine)

print("=== PostgreSQL tables ===")
print(inspector.get_table_names(schema="shared"))

print("\n=== Organisation model ===")
for column in Organisation.__table__.columns:
    print(f"{column.name}: {column.type}")

print("\n=== OrganisationType model ===")
for column in OrganisationType.__table__.columns:
    print(f"{column.name}: {column.type}")

print("\n=== Database Organisation table ===")
for column in inspector.get_columns("organisations", schema="shared"):
    print(f"{column['name']}: {column['type']}")