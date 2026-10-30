
BEGIN;

CREATE TABLE shared.devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name VARCHAR(255) NOT NULL,
    code VARCHAR(100),

    device_kind VARCHAR(20) NOT NULL DEFAULT 'physical',
    device_type VARCHAR(100) NOT NULL,

    manufacturer VARCHAR(255),
    model VARCHAR(255),
    serial_number VARCHAR(255),

    status VARCHAR(50) NOT NULL DEFAULT 'active',

    attributes JSONB NOT NULL DEFAULT '{}'::jsonb,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_devices_kind
        CHECK (device_kind IN ('physical', 'logical')),

    CONSTRAINT ck_devices_name_not_empty
        CHECK (LENGTH(TRIM(name)) > 0),

    CONSTRAINT ck_devices_type_not_empty
        CHECK (LENGTH(TRIM(device_type)) > 0),

    CONSTRAINT ck_devices_attributes_object
        CHECK (jsonb_typeof(attributes) = 'object')
);

CREATE INDEX ix_devices_device_type
    ON shared.devices (device_type);

CREATE INDEX ix_devices_status
    ON shared.devices (status);

CREATE INDEX ix_devices_is_active
    ON shared.devices (is_active);

CREATE INDEX ix_devices_attributes
    ON shared.devices USING GIN (attributes);

CREATE TABLE shared.asset_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    asset_id UUID NOT NULL
        REFERENCES shared.assets(id) ON DELETE RESTRICT,

    device_id UUID NOT NULL
        REFERENCES shared.devices(id) ON DELETE RESTRICT,

    relationship_type VARCHAR(50) NOT NULL DEFAULT 'monitors',

    installed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    removed_at TIMESTAMPTZ,

    attributes JSONB NOT NULL DEFAULT '{}'::jsonb,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT ck_asset_devices_dates
        CHECK (
            removed_at IS NULL
            OR removed_at >= installed_at
        ),

    CONSTRAINT ck_asset_devices_relationship
        CHECK (LENGTH(TRIM(relationship_type)) > 0),

    CONSTRAINT ck_asset_devices_attributes_object
        CHECK (jsonb_typeof(attributes) = 'object')
);

CREATE INDEX ix_asset_devices_asset_id
    ON shared.asset_devices (asset_id);

CREATE INDEX ix_asset_devices_device_id
    ON shared.asset_devices (device_id);

CREATE INDEX ix_asset_devices_relationship_type
    ON shared.asset_devices (relationship_type);

CREATE UNIQUE INDEX uq_asset_devices_active_pair
    ON shared.asset_devices (asset_id, device_id)
    WHERE removed_at IS NULL;

COMMIT;
