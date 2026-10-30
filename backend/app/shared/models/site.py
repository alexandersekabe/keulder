from __future__ import annotations
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from app.shared.models.asset import Asset

from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from sqlalchemy import Boolean, DateTime, ForeignKey, Numeric, String, Text, text
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.shared.models.organisation import Organisation

from app.db.base import Base


class Site(Base):
    __tablename__ = "sites"
    __table_args__ = {"schema": "shared"}

    id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )

    organisation_id: Mapped[UUID] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey(
            "shared.organisations.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    parent_site_id: Mapped[UUID | None] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey(
            "shared.sites.id",
            ondelete="RESTRICT",
        ),
        nullable=True,
    )

    name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )

    code: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )

    site_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    geo_area_id: Mapped[UUID | None] = mapped_column(
        PGUUID(as_uuid=True),
        ForeignKey(
            "shared.geo_areas.id",
            ondelete="SET NULL",
        ),
        nullable=True,
    )

    latitude: Mapped[Decimal | None] = mapped_column(
        Numeric(9, 6),
        nullable=True,
    )

    longitude: Mapped[Decimal | None] = mapped_column(
        Numeric(9, 6),
        nullable=True,
    )

    address: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    attributes: Mapped[dict[str, Any]] = mapped_column(
        JSONB,
        nullable=False,
        default=dict,
        server_default=text("'{}'::jsonb"),
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
        server_default=text("TRUE"),
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("NOW()"),
    )

    parent_site: Mapped["Site | None"] = relationship(
        "Site",
        remote_side="Site.id",
        back_populates="child_sites",
    )

    child_sites: Mapped[list["Site"]] = relationship(
        "Site",
        back_populates="parent_site",
    )

    organisation: Mapped["Organisation"] = relationship(
        "Organisation",
        back_populates="sites",
    )

    assets: Mapped[list["Asset"]] = relationship(
    "Asset",
    back_populates="site",
    )