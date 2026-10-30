
from sqlalchemy import inspect

from app.db.database import engine
from app.db.base import Base
import app.shared.models  # Registers the shared models


def main():
    inspector = inspect(engine)

    print("\nDATABASE INDEXES vs SQLALCHEMY MODEL INDEXES")
    print("=" * 65)

    for table in sorted(Base.metadata.tables.values(), key=lambda t: t.fullname):
        if table.schema != "shared":
            continue

        schema = table.schema
        table_name = table.name

        print(f"\n{schema}.{table_name}")
        print("-" * 65)

        # Indexes declared by SQLAlchemy
        model_indexes = {
            index.name: {
                "columns": tuple(column.name for column in index.columns),
                "unique": index.unique,
            }
            for index in table.indexes
        }

        # Unique constraints can also create database indexes,
        # but they are constraints rather than ordinary model indexes.
        database_indexes = inspector.get_indexes(
            table_name,
            schema=schema,
        )

        db_indexes = {
            index["name"]: {
                "columns": tuple(index.get("column_names") or []),
                "unique": index.get("unique", False),
                "type": index.get("dialect_options", {}).get(
                    "postgresql_using", "btree"
                ),
            }
            for index in database_indexes
        }

        print("MODEL DECLARATIONS:")
        if not model_indexes:
            print("  (No explicit indexes declared)")
        for name, details in sorted(model_indexes.items()):
            print(
                f"  {name}: columns={details['columns']}, "
                f"unique={details['unique']}"
            )

        print("\nDATABASE INDEXES:")
        if not db_indexes:
            print("  (No indexes reported)")
        for name, details in sorted(db_indexes.items()):
            print(
                f"  {name}: columns={details['columns']}, "
                f"unique={details['unique']}, "
                f"type={details['type']}"
            )

        model_names = set(model_indexes)
        database_names = set(db_indexes)

        print("\nNAME COMPARISON:")
        print("  Model indexes missing from DB:",
              sorted(model_names - database_names) or "None")
        print("  DB indexes not declared in model:",
              sorted(database_names - model_names) or "None")

    print("\nInspection complete. No database changes were made.")


if __name__ == "__main__":
    main()
