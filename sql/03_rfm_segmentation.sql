-- 03_rfm_segmentation.sql
-- Business question: who are our best customers, and who is slipping away?
--
-- RFM = Recency (days since last purchase), Frequency (number of orders),
-- Monetary (total spend). Scored 1-5, then mapped to marketing segments.
--
-- Note on Frequency: with only 3 months of data most buyers order once, so
-- NTILE would split identical "1 order" customers arbitrarily. Frequency
-- therefore uses fixed buckets: 1 order = 1, 2 orders = 3, 3+ orders = 5.
--
-- Final SELECT = segment summary (save as ga4_portfolio.rfm_segments).
-- For the customer-level table, replace the final SELECT with:
--   SELECT * FROM segmented   (save as ga4_portfolio.rfm_customers)

WITH purchases AS (
  SELECT
    ecommerce.transaction_id                     AS transaction_id,
    ANY_VALUE(user_pseudo_id)                    AS user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date))        AS purchase_date,
    MAX(ecommerce.purchase_revenue_in_usd)       AS revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name = 'purchase'
    AND ecommerce.transaction_id IS NOT NULL
    AND ecommerce.transaction_id != '(not set)'
  GROUP BY transaction_id
),

customers AS (
  SELECT
    user_pseudo_id,
    DATE_DIFF(DATE '2021-02-01', MAX(purchase_date), DAY) AS recency_days,
    COUNT(*)                                             AS frequency,
    ROUND(SUM(revenue_usd), 2)                           AS monetary_usd
  FROM purchases
  GROUP BY user_pseudo_id
  HAVING SUM(revenue_usd) > 0
),

scored AS (
  SELECT
    *,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- more recent = higher
    CASE WHEN frequency >= 3 THEN 5
         WHEN frequency = 2  THEN 3
         ELSE 1 END                            AS f_score,
    NTILE(5) OVER (ORDER BY monetary_usd ASC)  AS m_score   -- higher spend = higher
  FROM customers
),

segmented AS (
  SELECT
    *,
    CASE
      WHEN r_score >= 4 AND f_score >= 3 AND m_score >= 4 THEN '1 Champions'
      WHEN f_score >= 3                                   THEN '2 Loyal repeat buyers'
      WHEN r_score >= 4 AND m_score >= 4                  THEN '3 New big spenders'
      WHEN r_score >= 4                                   THEN '4 Recent low spenders'
      WHEN r_score <= 2 AND m_score >= 4                  THEN '5 At risk (high value)'
      ELSE                                                     '6 Hibernating'
    END AS segment
  FROM scored
)

SELECT
  segment,
  COUNT(*)                                                       AS customers,
  ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()), 4)         AS share_of_customers,
  ROUND(SUM(monetary_usd), 2)                                    AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(monetary_usd), SUM(SUM(monetary_usd)) OVER ()), 4) AS share_of_revenue,
  ROUND(AVG(recency_days), 1)                                    AS avg_recency_days,
  ROUND(AVG(frequency), 2)                                       AS avg_orders,
  ROUND(AVG(monetary_usd), 2)                                    AS avg_spend_usd
FROM segmented
GROUP BY segment
ORDER BY segment;
