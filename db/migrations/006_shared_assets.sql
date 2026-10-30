CREATE TABLE IF NOT EXISTS shared.assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    site_id UUID NOT NULL
        REFERENCES shared.sites(id)
        ON DELETE RESTRICT,

    parent_asset_id UUID
        REFERENCES shared.assets(id)
        ON DELETE RESTRICT,

    name VARCHAR(255) NOT NULL,

    code VARCHAR(100),

    asset_type VARCHAR(50) NOT NULL,

    description TEXT,

    manufacturer VARCHAR(255),

    model VARCHAR(255),

    serial_number VARCHAR(255),

    status VARCHAR(50) NOT NULL DEFAULT 'active',

    attributes JSONB NOT NULL DEFAULT '{}'::JSONB,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT assets_not_self_parent
        CHECK (
            parent_asset_id IS NULL
            OR parent_asset_id <> id
        )
);


CREATE INDEX IF NOT EXISTS idx_assets_site_id
    ON shared.assets(site_id);

CREATE INDEX IF NOT EXISTS idx_assets_parent_asset_id
    ON shared.assets(parent_asset_id);

CREATE INDEX IF NOT EXISTS idx_assets_asset_type
    ON shared.assets(asset_type);

CREATE INDEX IF NOT EXISTS idx_assets_status
    ON shared.assets(status);

CREATE INDEX IF NOT EXISTS idx_assets_is_active
    ON shared.assets(is_active);

CREATE INDEX IF NOT EXISTS idx_assets_attributes
    ON shared.assets USING GIN(attributes);


CREATE UNIQUE INDEX IF NOT EXISTS uq_assets_site_code
    ON shared.assets(site_id, code)
    WHERE code IS NOT NULL;