
-- ============================================================
-- Keulder Platform
-- Migration: 003_shared_geography.sql
-- Purpose: Shared geographic reference data
-- Requires: 001_extensions.sql, 002_schemas.sql
-- ============================================================

-- ------------------------------------------------------------
-- Geographic area types
-- Examples: continent, country, province, district, city,
--           village, suburb
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shared.geo_area_types (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(50) NOT NULL UNIQUE,
    name            VARCHAR(100) NOT NULL,
    description     TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------
-- Geographic areas
-- Supports hierarchical areas and spatial data.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shared.geo_areas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_id       UUID
                    REFERENCES shared.geo_areas(id)
                    ON DELETE RESTRICT,

    type_id         UUID NOT NULL
                    REFERENCES shared.geo_area_types(id)
                    ON DELETE RESTRICT,

    name            VARCHAR(255) NOT NULL,
    official_name   VARCHAR(255),
    country_code    CHAR(2),

    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),

    point           geography(Point,4326),
    boundary        geometry(MultiPolygon,4326),

    population      BIGINT,
    area_km2        NUMERIC(14,4),
    timezone        VARCHAR(100),

    attributes      JSONB NOT NULL DEFAULT '{}'::JSONB,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT geo_areas_not_self_parent
        CHECK (parent_id IS NULL OR parent_id <> id),

    CONSTRAINT geo_areas_country_code_format
        CHECK (
            country_code IS NULL
            OR country_code ~ '^[A-Z]{2}$'
        ),

    CONSTRAINT geo_areas_latitude_range
        CHECK (
            latitude IS NULL
            OR (latitude >= -90 AND latitude <= 90)
        ),

    CONSTRAINT geo_areas_longitude_range
        CHECK (
            longitude IS NULL
            OR (longitude >= -180 AND longitude <= 180)
        ),

    CONSTRAINT geo_areas_population_positive
        CHECK (population IS NULL OR population >= 0),

    CONSTRAINT geo_areas_area_positive
        CHECK (area_km2 IS NULL OR area_km2 >= 0)
);

-- ------------------------------------------------------------
-- External identifiers
-- Allows multiple external systems to identify the same area.
-- Each source/identifier pair must be unique.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shared.geo_area_identifiers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    geo_area_id     UUID NOT NULL
                    REFERENCES shared.geo_areas(id)
                    ON DELETE CASCADE,

    source          VARCHAR(100) NOT NULL,
    identifier      VARCHAR(255) NOT NULL,

    attributes      JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT geo_area_identifier_unique
        UNIQUE (source, identifier)
);

-- ------------------------------------------------------------
-- Indexes: geographic area types
-- ------------------------------------------------------------

-- The UNIQUE constraint on code already creates an index.

-- ------------------------------------------------------------
-- Indexes: geographic areas
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_geo_areas_parent
    ON shared.geo_areas(parent_id);

CREATE INDEX IF NOT EXISTS idx_geo_areas_type
    ON shared.geo_areas(type_id);

CREATE INDEX IF NOT EXISTS idx_geo_areas_country
    ON shared.geo_areas(country_code);

CREATE INDEX IF NOT EXISTS idx_geo_areas_attributes
    ON shared.geo_areas USING GIN(attributes);

CREATE INDEX IF NOT EXISTS idx_geo_areas_point
    ON shared.geo_areas USING GIST(point);

CREATE INDEX IF NOT EXISTS idx_geo_areas_boundary
    ON shared.geo_areas USING GIST(boundary);

-- ------------------------------------------------------------
-- Indexes: external identifiers
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_geo_area_identifiers_area
    ON shared.geo_area_identifiers(geo_area_id);
