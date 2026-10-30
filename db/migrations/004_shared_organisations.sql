-- ============================================================
-- Keulder Platform
-- Migration: 004_shared_organisations.sql
-- Purpose: Shared organisation structure
-- ============================================================

-- ------------------------------------------------------------
-- Organisation types
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shared.organisation_types (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    code            VARCHAR(50) NOT NULL UNIQUE,

    name            VARCHAR(100) NOT NULL,

    description     TEXT,

    sort_order      INTEGER NOT NULL DEFAULT 0,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ------------------------------------------------------------
-- Organisations
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS shared.organisations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_id       UUID
                    REFERENCES shared.organisations(id)
                    ON DELETE RESTRICT,

    organisation_type_id
                    UUID NOT NULL
                    REFERENCES shared.organisation_types(id)
                    ON DELETE RESTRICT,

    name            VARCHAR(255) NOT NULL,

    legal_name      VARCHAR(255),

    registration_number
                    VARCHAR(255),

    country_code    CHAR(2),

    contact_email   VARCHAR(255),

    contact_phone   VARCHAR(100),

    website         VARCHAR(500),

    attributes      JSONB NOT NULL DEFAULT '{}'::JSONB,

    is_active       BOOLEAN NOT NULL DEFAULT TRUE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT organisations_not_self_parent
        CHECK (
            parent_id IS NULL
            OR parent_id <> id
        ),

    CONSTRAINT organisations_country_code_format
        CHECK (
            country_code IS NULL
            OR country_code ~ '^[A-Z]{2}$'
        )
);


-- ------------------------------------------------------------
-- Indexes
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_organisation_types_sort_order
    ON shared.organisation_types(sort_order);


CREATE INDEX IF NOT EXISTS idx_organisations_parent
    ON shared.organisations(parent_id);


CREATE INDEX IF NOT EXISTS idx_organisations_type
    ON shared.organisations(organisation_type_id);


CREATE INDEX IF NOT EXISTS idx_organisations_country
    ON shared.organisations(country_code);


CREATE INDEX IF NOT EXISTS idx_organisations_active
    ON shared.organisations(is_active);


CREATE INDEX IF NOT EXISTS idx_organisations_attributes
    ON shared.organisations
    USING GIN(attributes);