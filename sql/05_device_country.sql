-- 05_device_country.sql
-- Business question: which devices and markets convert best, and where is
-- traffic high but sales low (an opportunity or a problem)?
-- Save the result as table: ga4_portfolio.device_country

WITH base AS (
  SELECT
    user_pseudo_id,
    device.category                    AS device_category,
    geo.country                        AS country,
    event_name,
    ecommerce.transaction_id           AS transaction_id,
    ecommerce.purchase_revenue_in_usd  AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

purchases AS (
  SELECT
    transaction_id,
    ANY_VALUE(user_pseudo_id)  AS user_pseudo_id,
    ANY_VALUE(device_category) AS device_category,
    ANY_VALUE(country)         AS country,
    MAX(revenue_usd)           AS revenue_usd
  FROM base
  WHERE event_name = 'purchase'
    AND transaction_id IS NOT NULL
    AND transaction_id != '(not set)'
  GROUP BY transaction_id
),

traffic AS (
  SELECT device_category, country, COUNT(DISTINCT user_pseudo_id) AS users
  FROM base
  GROUP BY 1, 2
),

sales AS (
  SELECT
    device_category,
    country,
    COUNT(DISTINCT user_pseudo_id) AS purchasers,
    COUNT(*)                       AS transactions,
    SUM(revenue_usd)               AS revenue_usd
  FROM purchases
  GROUP BY 1, 2
)

SELECT
  t.device_category,
  t.country,
  t.users,
  IFNULL(s.purchasers, 0)                                   AS purchasers,
  IFNULL(s.transactions, 0)                                 AS transactions,
  ROUND(IFNULL(s.revenue_usd, 0), 2)                        AS revenue_usd,
  ROUND(SAFE_DIVIDE(IFNULL(s.purchasers, 0), t.users), 4)   AS user_conversion_rate,
  ROUND(SAFE_DIVIDE(s.revenue_usd, s.transactions), 2)      AS avg_order_value_usd
FROM traffic t
LEFT JOIN sales s USING (device_category, country)
WHERE t.users >= 100   -- ignore tiny segments; their rates are noise
ORDER BY t.users DESC;
