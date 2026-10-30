-- ============================================================
-- Keulder Platform
-- Seed: 002_shared_organisation_types.sql
-- Purpose: Initial organisation types
-- ============================================================

INSERT INTO shared.organisation_types
    (code, name, description, sort_order)
VALUES
    (
        'company',
        'Company',
        'Commercial business or corporate organisation',
        10
    ),
    (
        'government',
        'Government',
        'Government institution or public authority',
        20
    ),
    (
        'municipality',
        'Municipality',
        'Municipal government or local authority',
        30
    ),
    (
        'department',
        'Department',
        'Department or division within an organisation',
        40
    ),
    (
        'farm',
        'Farm',
        'Agricultural farming organisation or operation',
        50
    ),
    (
        'cooperative',
        'Cooperative',
        'Member-owned cooperative organisation',
        60
    ),
    (
        'utility',
        'Utility',
        'Electricity, water or other utility organisation',
        70
    ),
    (
        'research',
        'Research Institution',
        'Research, scientific or experimental organisation',
        80
    ),
    (
        'nonprofit',
        'Nonprofit',
        'Nonprofit or community organisation',
        90
    ),
    (
        'other',
        'Other',
        'Other organisation type not covered above',
        100
    )
ON CONFLICT (code) DO NOTHING;