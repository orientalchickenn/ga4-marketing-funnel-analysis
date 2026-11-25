-- 00_explore.sql
-- Purpose: get to know the dataset before analysing it.
-- Dataset: Google Merchandise Store, GA4 obfuscated sample (2020-11-01 to 2021-01-31)
-- Run each query separately in the BigQuery console.

-- 1) Date range and size
SELECT
  MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_day,
  MAX(PARSE_DATE('%Y%m%d', event_date)) AS last_day,
  COUNT(*)                              AS events,
  COUNT(DISTINCT user_pseudo_id)        AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';


-- 2) Which events exist, and how often
SELECT
  event_name,
  COUNT(*)                       AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY events DESC;


-- 3) Traffic source values (first-touch acquisition, stored per user)
SELECT
  traffic_source.source,
  traffic_source.medium,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY 1, 2
ORDER BY users DESC;


-- 4) Data quality: purchases with a missing transaction id or revenue
SELECT
  COUNT(*)                                                         AS purchase_events,
  COUNTIF(ecommerce.transaction_id IS NULL
          OR ecommerce.transaction_id = '(not set)')               AS missing_transaction_id,
  COUNTIF(ecommerce.purchase_revenue_in_usd IS NULL)               AS missing_revenue,
  COUNT(DISTINCT ecommerce.transaction_id)                         AS distinct_transactions
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  AND event_name = 'purchase';
