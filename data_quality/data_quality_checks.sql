-- ============================================================================
-- DATA QUALITY CHECKS
-- Global Defense & Conflict Intelligence Dashboard
--
-- Run after each pipeline refresh to validate data integrity across
-- Bronze, Silver, and Gold layers.
--
-- Categories:
--   1. Row count validation
--   2. Null checks on critical columns
--   3. Duplicate detection
--   4. Referential integrity
--   5. Business rule validation
-- ============================================================================


-- ============================================================================
-- 1. ROW COUNT VALIDATION
-- Ensures expected data volumes at each layer
-- ============================================================================
SELECT 'BRONZE LAYER' AS layer, 'bronze_arms_transfers' AS table_name, COUNT(*) AS row_count FROM bronze_arms_transfers
UNION ALL
SELECT 'BRONZE', 'bronze_arms_industry', COUNT(*) FROM bronze_arms_industry
UNION ALL
SELECT 'BRONZE', 'bronze_acled_conflict_events', COUNT(*) FROM bronze_acled_conflict_events
UNION ALL
SELECT 'BRONZE', 'bronze_milex_current_usd', COUNT(*) FROM bronze_milex_current_usd
UNION ALL
SELECT 'BRONZE', 'bronze_milex_share_gdp', COUNT(*) FROM bronze_milex_share_gdp
UNION ALL
SELECT 'BRONZE', 'bronze_milex_share_govt_spending', COUNT(*) FROM bronze_milex_share_govt_spending
UNION ALL
SELECT 'BRONZE', 'bronze_world_bank_indicators', COUNT(*) FROM bronze_world_bank_indicators
UNION ALL
SELECT 'SILVER', 'silver_countries', COUNT(*) FROM silver_countries
UNION ALL
SELECT 'SILVER', 'silver_calendar', COUNT(*) FROM silver_calendar
UNION ALL
SELECT 'SILVER', 'silver_weapon_categories', COUNT(*) FROM silver_weapon_categories
UNION ALL
SELECT 'SILVER', 'silver_political_eras', COUNT(*) FROM silver_political_eras
UNION ALL
SELECT 'SILVER', 'silver_arms_transfer', COUNT(*) FROM silver_arms_transfer
UNION ALL
SELECT 'SILVER', 'silver_arms_industry', COUNT(*) FROM silver_arms_industry
UNION ALL
SELECT 'SILVER', 'silver_milex', COUNT(*) FROM silver_milex
UNION ALL
SELECT 'SILVER', 'silver_world_bank', COUNT(*) FROM silver_world_bank
UNION ALL
SELECT 'SILVER', 'silver_acled_violence', COUNT(*) FROM silver_acled_violence
UNION ALL
SELECT 'GOLD', 'gold_trade_overview', COUNT(*) FROM gold_trade_overview
UNION ALL
SELECT 'GOLD', 'gold_imports_analysis', COUNT(*) FROM gold_imports_analysis
UNION ALL
SELECT 'GOLD', 'gold_exports_analysis', COUNT(*) FROM gold_exports_analysis
UNION ALL
SELECT 'GOLD', 'gold_defense_partnerships', COUNT(*) FROM gold_defense_partnerships
UNION ALL
SELECT 'GOLD', 'gold_spending_tradeoffs', COUNT(*) FROM gold_spending_tradeoffs
UNION ALL
SELECT 'GOLD', 'gold_conflict_events', COUNT(*) FROM gold_conflict_events
UNION ALL
SELECT 'GOLD', 'gold_top100_companies', COUNT(*) FROM gold_top100_companies
ORDER BY layer, table_name;


-- ============================================================================
-- 2. NULL CHECKS ON CRITICAL COLUMNS
-- Flags rows with missing values in columns that should never be null
-- ============================================================================

-- Arms transfers: supplier and recipient must exist
SELECT 'silver_arms_transfer' AS table_name, 'supplier_country_id' AS column_name, 
       COUNT(*) AS null_count
FROM silver_arms_transfer WHERE supplier_country_id IS NULL
UNION ALL
SELECT 'silver_arms_transfer', 'recipient_country_id', COUNT(*)
FROM silver_arms_transfer WHERE recipient_country_id IS NULL
UNION ALL
SELECT 'silver_arms_transfer', 'delivery_year', COUNT(*)
FROM silver_arms_transfer WHERE delivery_year IS NULL
UNION ALL
-- Trade overview: country name must exist
SELECT 'gold_trade_overview', 'country_name', COUNT(*)
FROM gold_trade_overview WHERE country_name IS NULL
UNION ALL
-- Defense partnerships: coordinates must exist for map
SELECT 'gold_defense_partnerships', 'source_lat', COUNT(*)
FROM gold_defense_partnerships WHERE source_lat IS NULL
UNION ALL
SELECT 'gold_defense_partnerships', 'target_lat', COUNT(*)
FROM gold_defense_partnerships WHERE target_lat IS NULL
UNION ALL
-- Spending tradeoffs: GDP should exist for meaningful analysis
SELECT 'gold_spending_tradeoffs', 'gdp_usd', COUNT(*)
FROM gold_spending_tradeoffs WHERE gdp_usd IS NULL
UNION ALL
-- Conflict events: event counts must exist
SELECT 'gold_conflict_events', 'total_events', COUNT(*)
FROM gold_conflict_events WHERE total_events IS NULL
UNION ALL
-- Top 100: rank and revenue must exist
SELECT 'gold_top100_companies', 'arms_revenue', COUNT(*)
FROM gold_top100_companies WHERE arms_revenue IS NULL;


-- ============================================================================
-- 3. DUPLICATE DETECTION
-- Ensures primary key integrity and no duplicate business records
-- ============================================================================

-- Duplicate trade IDs in silver
SELECT 'silver_arms_transfer: duplicate trade_id' AS check_name, COUNT(*) AS duplicates
FROM (
    SELECT trade_id, COUNT(*) AS cnt
    FROM silver_arms_transfer
    GROUP BY trade_id
    HAVING COUNT(*) > 1
) dups
UNION ALL
-- Duplicate country entries
SELECT 'silver_countries: duplicate country_name', COUNT(*)
FROM (
    SELECT country_name, COUNT(*) AS cnt
    FROM silver_countries
    GROUP BY country_name
    HAVING COUNT(*) > 1
) dups
UNION ALL
-- Duplicate partnerships
SELECT 'gold_defense_partnerships: duplicate supplier-recipient pairs', COUNT(*)
FROM (
    SELECT supplier_country_id, recipient_country_id, COUNT(*) AS cnt
    FROM gold_defense_partnerships
    GROUP BY supplier_country_id, recipient_country_id
    HAVING COUNT(*) > 1
) dups
UNION ALL
-- Duplicate company rankings
SELECT 'gold_top100_companies: duplicate ranks', COUNT(*)
FROM (
    SELECT rank, COUNT(*) AS cnt
    FROM gold_top100_companies
    GROUP BY rank
    HAVING COUNT(*) > 1
) dups;


-- ============================================================================
-- 4. REFERENTIAL INTEGRITY
-- Validates foreign key relationships between Silver and Gold layers
-- ============================================================================

-- Arms transfers referencing non-existent countries
SELECT 'silver_arms_transfer → silver_countries (supplier): orphan records' AS check_name,
       COUNT(*) AS orphan_count
FROM silver_arms_transfer sat
WHERE NOT EXISTS (
    SELECT 1 FROM silver_countries sc WHERE sc.country_id = sat.supplier_country_id
)
UNION ALL
SELECT 'silver_arms_transfer → silver_countries (recipient): orphan records',
       COUNT(*)
FROM silver_arms_transfer sat
WHERE NOT EXISTS (
    SELECT 1 FROM silver_countries sc WHERE sc.country_id = sat.recipient_country_id
)
UNION ALL
-- Weapon categories referencing non-existent categories
SELECT 'silver_arms_transfer → silver_weapon_categories: orphan records',
       COUNT(*)
FROM silver_arms_transfer sat
WHERE NOT EXISTS (
    SELECT 1 FROM silver_weapon_categories swc WHERE swc.weapon_category_id = sat.weapon_category_id
)
UNION ALL
-- Political eras referencing non-existent countries
SELECT 'silver_political_eras → silver_countries: orphan records',
       COUNT(*)
FROM silver_political_eras spe
WHERE NOT EXISTS (
    SELECT 1 FROM silver_countries sc WHERE sc.country_id = spe.country_id
);


-- ============================================================================
-- 5. BUSINESS RULE VALIDATION
-- Checks domain-specific rules and data ranges
-- ============================================================================

-- Correlation values must be between -1 and 1
SELECT 'gold_conflict_events: correlation out of range [-1,1]' AS check_name,
       COUNT(*) AS violations
FROM gold_conflict_events
WHERE spending_conflict_correlation IS NOT NULL
  AND (spending_conflict_correlation < -1 OR spending_conflict_correlation > 1)
UNION ALL
-- Budget crowding index should not be negative
SELECT 'gold_spending_tradeoffs: negative budget_crowding_index', COUNT(*)
FROM gold_spending_tradeoffs
WHERE budget_crowding_index < 0
UNION ALL
-- Arms revenue percentage should be 0-100
SELECT 'gold_top100_companies: arms_revenue_pct out of range [0,100]', COUNT(*)
FROM gold_top100_companies
WHERE arms_revenue_pct < 0 OR arms_revenue_pct > 100
UNION ALL
-- Partnership strength should be positive
SELECT 'gold_defense_partnerships: negative partnership_strength', COUNT(*)
FROM gold_defense_partnerships
WHERE partnership_strength < 0
UNION ALL
-- Year range validation (project scope: 1998-2025)
SELECT 'silver_arms_transfer: delivery_year out of range', COUNT(*)
FROM silver_arms_transfer
WHERE delivery_year < 1998 OR delivery_year > 2025
UNION ALL
-- Market share should sum to ~100% per year
SELECT 'gold_exports_analysis: market_share_pct sum deviates from 100', COUNT(*)
FROM (
    SELECT year, ABS(SUM(market_share_pct) - 100) AS deviation
    FROM gold_exports_analysis
    GROUP BY year
    HAVING ABS(SUM(market_share_pct) - 100) > 1
) dev;
