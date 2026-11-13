-- ============================================================
-- Script: 01_create_schema.sql
-- Purpose: Create schema for the Retail Sales Data Warehouse
-- Fabric Item: Data Warehouse (RetailSalesDW)
-- DP-700 Skill: Ingest and Transform Data > Batch Data Processing
-- ============================================================

-- Create separate schemas for organization
CREATE SCHEMA IF NOT EXISTS dim;     -- Dimension tables
CREATE SCHEMA IF NOT EXISTS fact;    -- Fact tables
CREATE SCHEMA IF NOT EXISTS staging; -- Staging/loading tables
CREATE SCHEMA IF NOT EXISTS mart;    -- Reporting marts / views

GO

-- ============================================================
-- Verify schemas created
-- ============================================================
SELECT
    schema_id,
    name AS schema_name,
    GETDATE() AS created_check_time
FROM sys.schemas
WHERE name IN ('dim', 'fact', 'staging', 'mart')
ORDER BY schema_id;
