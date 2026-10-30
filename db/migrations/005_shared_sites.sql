CREATE TABLE IF NOT EXISTS shared.sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    organisation_id UUID NOT NULL
        REFERENCES shared.organisations(id)
        ON DELETE RESTRICT,

    parent_site_id UUID
        REFERENCES shared.sites(id)
        ON DELETE RESTRICT,

    name VARCHAR(255) NOT NULL,

    code VARCHAR(100),

    site_type VARCHAR(50) NOT NULL,

    description TEXT,

    geo_area_id UUID
        REFERENCES shared.geo_areas(id)
        ON DELETE SET NULL,

    latitude NUMERIC(9,6),

    longitude NUMERIC(9,6),

    address TEXT,

    attributes JSONB NOT NULL DEFAULT '{}'::JSONB,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT sites_not_self_parent
        CHECK (
            parent_site_id IS NULL
            OR parent_site_id <> id
        ),

    CONSTRAINT sites_latitude_range
        CHECK (
            latitude IS NULL
            OR latitude BETWEEN -90 AND 90
        ),

    CONSTRAINT sites_longitude_range
        CHECK (
            longitude IS NULL
            OR longitude BETWEEN -180 AND 180
        )
);


CREATE INDEX IF NOT EXISTS idx_sites_organisation_id
    ON shared.sites(organisation_id);

CREATE INDEX IF NOT EXISTS idx_sites_parent_site_id
    ON shared.sites(parent_site_id);

CREATE INDEX IF NOT EXISTS idx_sites_geo_area_id
    ON shared.sites(geo_area_id);

CREATE INDEX IF NOT EXISTS idx_sites_site_type
    ON shared.sites(site_type);

CREATE INDEX IF NOT EXISTS idx_sites_is_active
    ON shared.sites(is_active);

CREATE INDEX IF NOT EXISTS idx_sites_attributes
    ON shared.sites USING GIN(attributes);


CREATE UNIQUE INDEX IF NOT EXISTS uq_sites_org_code
    ON shared.sites(organisation_id, code)
    WHERE code IS NOT NULL;