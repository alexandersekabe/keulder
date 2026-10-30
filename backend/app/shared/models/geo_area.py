
import uuid
from datetime import datetime
from decimal import Decimal
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class GeoAreaType(Base):
    __tablename__ = "geo_area_types"
    __table_args__ = {"schema": "shared"}

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    code: Mapped[str] = mapped_column(
        String(50), nullable=False, unique=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, server_default=text("0")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
    )

    areas: Mapped[list["GeoArea"]] = relationship(
        back_populates="area_type"
    )


class GeoArea(Base):
    __tablename__ = "geo_areas"
    __table_args__ = (
        CheckConstraint(
            "parent_id IS NULL OR parent_id <> id",
            name="geo_areas_not_self_parent",
        ),
        CheckConstraint(
            "latitude IS NULL OR (latitude >= -90 AND latitude <= 90)",
            name="geo_areas_latitude_range",
        ),
        CheckConstraint(
            "longitude IS NULL OR (longitude >= -180 AND longitude <= 180)",
            name="geo_areas_longitude_range",
        ),
        CheckConstraint(
            "population IS NULL OR population >= 0",
            name="geo_areas_population_positive",
        ),
        CheckConstraint(
            "area_km2 IS NULL OR area_km2 >= 0",
            name="geo_areas_area_positive",
        ),
        CheckConstraint(
            "country_code IS NULL OR country_code ~ '^[A-Z]{2}$'",
            name="geo_areas_country_code_format",
        ),
        Index("idx_geo_areas_parent", "parent_id"),
        Index("idx_geo_areas_type", "type_id"),
        Index("idx_geo_areas_country", "country_code"),
        Index("idx_geo_areas_attributes", "attributes", postgresql_using="gin"),
        {"schema": "shared"},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("shared.geo_areas.id", ondelete="RESTRICT"),
    )
    type_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("shared.geo_area_types.id", ondelete="RESTRICT"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    official_name: Mapped[str | None] = mapped_column(String(255))
    country_code: Mapped[str | None] = mapped_column(String(2))
    latitude: Mapped[Decimal | None] = mapped_column(Numeric(9, 6))
    longitude: Mapped[Decimal | None] = mapped_column(Numeric(9, 6))

    # PostGIS geography/geometry columns are left out of the ORM
    # until their spatial mappings are configured explicitly.

    population: Mapped[int | None] = mapped_column(BigInteger)
    area_km2: Mapped[Decimal | None] = mapped_column(Numeric(14, 4))
    timezone: Mapped[str | None] = mapped_column(String(100))
    attributes: Mapped[dict[str, Any]] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'{}'::jsonb"),
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("true")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
    )

    parent: Mapped["GeoArea | None"] = relationship(
        back_populates="children",
        remote_side="GeoArea.id",
        foreign_keys=[parent_id],
    )
    children: Mapped[list["GeoArea"]] = relationship(
        back_populates="parent",
        foreign_keys=[parent_id],
    )
    area_type: Mapped[GeoAreaType] = relationship(
        back_populates="areas"
    )

class GeoAreaIdentifier(Base):
    __tablename__ = "geo_area_identifiers"
    __table_args__ = (
        Index(
            "idx_geo_area_identifiers_area",
            "geo_area_id",
        ),
        UniqueConstraint(
            "source",
            "identifier",
            name="geo_area_identifier_unique",
        ),
        {"schema": "shared"},
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    geo_area_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("shared.geo_areas.id", ondelete="CASCADE"),
        nullable=False,
    )

    source: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    identifier: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    attributes: Mapped[dict[str, Any]] = mapped_column(
        JSONB,
        nullable=False,
        server_default=text("'{}'::jsonb"),
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("now()"),
    )