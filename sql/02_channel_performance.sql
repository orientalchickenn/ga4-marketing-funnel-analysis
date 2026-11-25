-- 02_channel_performance.sql
-- Business question: which acquisition channels bring BUYERS, not just visitors?
--
-- Channel = the user's first-touch acquisition source/medium (GA4 `traffic_source`
-- is stored per user, so every session of a user belongs to the same channel).
-- Revenue is deduplicated by transaction_id, because the sample contains some
-- repeated purchase events.
-- Save the result as table: ga4_portfolio.channel_performance

WITH base AS (
  SELECT
    user_pseudo_id,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    CONCAT(
      user_pseudo_id, '-',
      CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)
    ) AS session_id,
    event_name,
    ecommerce.transaction_id         AS transaction_id,
    ecommerce.purchase_revenue_in_usd AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

user_channel AS (
  SELECT
    user_pseudo_id,
    ANY_VALUE(source) AS source,
    ANY_VALUE(medium) AS medium,
    COUNT(DISTINCT session_id) AS sessions
  FROM base
  GROUP BY user_pseudo_id
),

purchases AS (  -- one row per real transaction
  SELECT
    transaction_id,
    ANY_VALUE(user_pseudo_id) AS user_pseudo_id,
    MAX(revenue_usd)          AS revenue_usd
  FROM base
  WHERE event_name = 'purchase'
    AND transaction_id IS NOT NULL
    AND transaction_id != '(not set)'
  GROUP BY transaction_id
),

user_purchases AS (
  SELECT user_pseudo_id, COUNT(*) AS transactions, SUM(revenue_usd) AS revenue_usd
  FROM purchases
  GROUP BY user_pseudo_id
),

labelled AS (
  SELECT
    CASE
      WHEN uc.medium = 'organic'                          THEN 'Organic Search'
      WHEN uc.medium IN ('cpc', 'ppc', 'paid')            THEN 'Paid Search'
      WHEN uc.medium = 'referral'                         THEN 'Referral'
      WHEN uc.source = '(direct)' AND uc.medium = '(none)' THEN 'Direct'
      WHEN uc.medium IN ('<Other>', '(data deleted)')
        OR uc.source IN ('<Other>', '(data deleted)')     THEN 'Other / Redacted'
      ELSE 'Other'
    END AS channel_group,
    uc.user_pseudo_id,
    uc.sessions,
    IFNULL(up.transactions, 0) AS transactions,
    IFNULL(up.revenue_usd, 0)  AS revenue_usd
  FROM user_channel uc
  LEFT JOIN user_purchases up USING (user_pseudo_id)
)

SELECT
  channel_group,
  COUNT(*)                                                  AS users,
  SUM(sessions)                                             AS sessions,
  COUNTIF(transactions > 0)                                 AS purchasers,
  SUM(transactions)                                         AS transactions,
  ROUND(SUM(revenue_usd), 2)                                AS revenue_usd,
  ROUND(SAFE_DIVIDE(COUNTIF(transactions > 0), COUNT(*)), 4) AS user_conversion_rate,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), SUM(transactions)), 2) AS avg_order_value_usd,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 2)          AS revenue_per_user_usd,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), SUM(SUM(revenue_usd)) OVER ()), 4) AS share_of_revenue,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()), 4)                  AS share_of_users
FROM labelled
GROUP BY channel_group
ORDER BY revenue_usd DESC;
