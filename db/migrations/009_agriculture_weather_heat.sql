
BEGIN;

CREATE SCHEMA IF NOT EXISTS agriculture;

-- Daily weather data supplied by an external source.
CREATE TABLE agriculture.daily_weather_observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    observation_date DATE NOT NULL,

    -- Coordinates requested from the provider.
    requested_latitude DOUBLE PRECISION NOT NULL,
    requested_longitude DOUBLE PRECISION NOT NULL,

    -- Coordinates of the provider's returned grid point, if supplied.
    provider_latitude DOUBLE PRECISION,
    provider_longitude DOUBLE PRECISION,

    source_name TEXT NOT NULL,
    source_dataset TEXT NOT NULL,
    data_type TEXT NOT NULL,
    data_basis TEXT NOT NULL,
  
    temperature_mean_c NUMERIC(5,2),
    temperature_max_c NUMERIC(5,2),
    temperature_min_c NUMERIC(5,2),
    precipitation_mm NUMERIC(8,2),

    timezone_name TEXT NOT NULL,
    source_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,

    retrieved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_weather_latitude
        CHECK (requested_latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_weather_longitude
        CHECK (requested_longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_weather_provider_latitude
        CHECK (
            provider_latitude IS NULL
            OR provider_latitude BETWEEN -90 AND 90
        ),
    CONSTRAINT ck_weather_provider_longitude
        CHECK (
            provider_longitude IS NULL
            OR provider_longitude BETWEEN -180 AND 180
        ),
    CONSTRAINT ck_weather_temperature_order

        CHECK (
            temperature_min_c IS NULL
            OR temperature_max_c IS NULL
            OR temperature_min_c <= temperature_max_c
        ),

    CONSTRAINT ck_weather_mean_temperature
        CHECK (
            temperature_mean_c IS NULL
            OR temperature_min_c IS NULL
            OR temperature_max_c IS NULL
            OR (
                temperature_min_c <= temperature_mean_c
                AND temperature_mean_c <= temperature_max_c
            )
        ),

CONSTRAINT ck_weather_precipitation
        CHECK (precipitation_mm IS NULL OR precipitation_mm >= 0)
);

CREATE INDEX ix_weather_date
    ON agriculture.daily_weather_observations (observation_date);

CREATE INDEX ix_weather_source_date
    ON agriculture.daily_weather_observations
       (source_name, observation_date);


-- Configurable temperature thresholds for crops and growth stages.
CREATE TABLE agriculture.crop_heat_thresholds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    crop_code TEXT NOT NULL,
    growth_stage_code TEXT NOT NULL,
    threshold_type TEXT NOT NULL,
    temperature_c NUMERIC(5,2) NOT NULL,

    evidence_status TEXT NOT NULL,
    evidence_source TEXT,
    notes TEXT,

    valid_from DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_to DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ck_crop_heat_evidence_status
        CHECK (
            evidence_status IN (
                'provisional',
                'research_supported',
                'locally_validated'
            )
        ),
    CONSTRAINT ck_crop_heat_validity
        CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE INDEX ix_crop_heat_lookup
    ON agriculture.crop_heat_thresholds
       (crop_code, growth_stage_code, threshold_type);

COMMIT;
