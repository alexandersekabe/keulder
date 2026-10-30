
-- ============================================================
-- Keulder Platform
-- Migration: 008_shared_integrity.sql
-- Purpose: Shared data integrity and automatic timestamps
-- Requires: Migrations 001 through 007
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Coordinate pair integrity
-- Latitude and longitude must both be present or both NULL.
-- ------------------------------------------------------------

ALTER TABLE shared.geo_areas
    ADD CONSTRAINT geo_areas_coordinate_pair
    CHECK (
        (latitude IS NULL AND longitude IS NULL)
        OR
        (latitude IS NOT NULL AND longitude IS NOT NULL)
    );

ALTER TABLE shared.sites
    ADD CONSTRAINT sites_coordinate_pair
    CHECK (
        (latitude IS NULL AND longitude IS NULL)
        OR
        (latitude IS NOT NULL AND longitude IS NOT NULL)
    );

-- ------------------------------------------------------------
-- 2. Ensure geographic point and coordinate consistency
--
-- If point alone changes, coordinates are derived from it.
-- If coordinates alone change, point is derived from them.
-- If both change, they must agree.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION shared.sync_geo_area_point()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    point_changed BOOLEAN;
    coordinates_changed BOOLEAN;
    point_latitude NUMERIC;
    point_longitude NUMERIC;
BEGIN
    point_changed :=
        TG_OP = 'INSERT'
        OR NEW.point IS DISTINCT FROM OLD.point;

    coordinates_changed :=
        TG_OP = 'INSERT'
        OR NEW.latitude IS DISTINCT FROM OLD.latitude
        OR NEW.longitude IS DISTINCT FROM OLD.longitude;

    IF TG_OP = 'INSERT' THEN
        IF NEW.point IS NOT NULL THEN
            point_latitude :=
                ST_Y(NEW.point::geometry)::NUMERIC;
            point_longitude :=
                ST_X(NEW.point::geometry)::NUMERIC;

            IF NEW.latitude IS NULL AND NEW.longitude IS NULL THEN
                NEW.latitude := point_latitude;
                NEW.longitude := point_longitude;
            ELSIF
                abs(NEW.latitude - point_latitude) > 0.000001
                OR abs(NEW.longitude - point_longitude) > 0.000001
            THEN
                RAISE EXCEPTION
                    'Point conflicts with latitude/longitude';
            END IF;

        ELSIF NEW.latitude IS NOT NULL
          AND NEW.longitude IS NOT NULL THEN
            NEW.point := ST_SetSRID(
                ST_MakePoint(NEW.longitude, NEW.latitude),
                4326
            )::geography;
        END IF;

        RETURN NEW;
    END IF;

    IF point_changed AND coordinates_changed THEN
        IF NEW.point IS NULL
           AND NEW.latitude IS NULL
           AND NEW.longitude IS NULL THEN
            RETURN NEW;
        ELSIF NEW.point IS NULL
           OR NEW.latitude IS NULL
           OR NEW.longitude IS NULL THEN
            RAISE EXCEPTION
                'Point and coordinates must be supplied consistently';
        END IF;

        point_latitude :=
            ST_Y(NEW.point::geometry)::NUMERIC;
        point_longitude :=
            ST_X(NEW.point::geometry)::NUMERIC;

        IF abs(NEW.latitude - point_latitude) > 0.000001
           OR abs(NEW.longitude - point_longitude) > 0.000001 THEN
            RAISE EXCEPTION
                'Point conflicts with latitude/longitude';
        END IF;

    ELSIF point_changed THEN
        IF NEW.point IS NULL THEN
            NEW.latitude := NULL;
            NEW.longitude := NULL;
        ELSE
            NEW.latitude :=
                ST_Y(NEW.point::geometry)::NUMERIC;
            NEW.longitude :=
                ST_X(NEW.point::geometry)::NUMERIC;
        END IF;

    ELSIF coordinates_changed THEN
        IF NEW.latitude IS NULL AND NEW.longitude IS NULL THEN
            NEW.point := NULL;
        ELSIF NEW.latitude IS NOT NULL
          AND NEW.longitude IS NOT NULL THEN
            NEW.point := ST_SetSRID(
                ST_MakePoint(NEW.longitude, NEW.latitude),
                4326
            )::geography;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_geo_areas_sync_point
BEFORE INSERT OR UPDATE OF point, latitude, longitude
ON shared.geo_areas
FOR EACH ROW
EXECUTE FUNCTION shared.sync_geo_area_point();

-- ------------------------------------------------------------
-- 3. Automatically maintain updated_at
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION shared.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_geo_areas_updated_at
BEFORE UPDATE ON shared.geo_areas
FOR EACH ROW EXECUTE FUNCTION shared.set_updated_at();

CREATE TRIGGER trg_organisations_updated_at
BEFORE UPDATE ON shared.organisations
FOR EACH ROW EXECUTE FUNCTION shared.set_updated_at();

CREATE TRIGGER trg_sites_updated_at
BEFORE UPDATE ON shared.sites
FOR EACH ROW EXECUTE FUNCTION shared.set_updated_at();

CREATE TRIGGER trg_assets_updated_at
BEFORE UPDATE ON shared.assets
FOR EACH ROW EXECUTE FUNCTION shared.set_updated_at();

CREATE TRIGGER trg_devices_updated_at
BEFORE UPDATE ON shared.devices
FOR EACH ROW EXECUTE FUNCTION shared.set_updated_at();

COMMIT;
