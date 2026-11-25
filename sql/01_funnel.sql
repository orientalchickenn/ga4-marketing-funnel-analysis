-- 01_funnel.sql
-- Business question: where in the purchase journey do sessions drop off,
-- and is it worse on some devices?
--
-- Method: closed session funnel. A session counts at a step only if it also
-- reached every earlier step in the same session:
--   1 Session -> 2 View item -> 3 Add to cart -> 4 Begin checkout -> 5 Purchase
-- Output is long format (one row per device x step) so Looker Studio can chart it directly.
-- Save the result as table: ga4_portfolio.funnel_by_device

WITH events AS (
  SELECT
    device.category AS device_category,
    CONCAT(
      user_pseudo_id, '-',
      CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)
    ) AS session_id,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

sessions AS (
  SELECT
    session_id,
    ANY_VALUE(device_category)                    AS device_category,
    MAX(IF(event_name = 'view_item', 1, 0))       AS viewed_item,
    MAX(IF(event_name = 'add_to_cart', 1, 0))     AS added_to_cart,
    MAX(IF(event_name = 'begin_checkout', 1, 0))  AS began_checkout,
    MAX(IF(event_name = 'purchase', 1, 0))        AS purchased
  FROM events
  WHERE session_id IS NOT NULL
  GROUP BY session_id
),

closed_funnel AS (
  SELECT
    device_category,
    1                                                        AS s1,
    viewed_item                                              AS s2,
    viewed_item * added_to_cart                              AS s3,
    viewed_item * added_to_cart * began_checkout             AS s4,
    viewed_item * added_to_cart * began_checkout * purchased AS s5
  FROM sessions
),

by_device AS (
  SELECT device_category, SUM(s1) AS s1, SUM(s2) AS s2, SUM(s3) AS s3, SUM(s4) AS s4, SUM(s5) AS s5
  FROM closed_funnel
  GROUP BY device_category
  UNION ALL
  SELECT 'All devices', SUM(s1), SUM(s2), SUM(s3), SUM(s4), SUM(s5)
  FROM closed_funnel
),

long_format AS (
  SELECT device_category, step.step_order, step.step_name, step.sessions
  FROM by_device,
  UNNEST([
    STRUCT(1 AS step_order, 'Session'        AS step_name, s1 AS sessions),
    STRUCT(2,               'View item',                   s2),
    STRUCT(3,               'Add to cart',                 s3),
    STRUCT(4,               'Begin checkout',              s4),
    STRUCT(5,               'Purchase',                    s5)
  ]) AS step
)

SELECT
  device_category,
  step_order,
  step_name,
  sessions,
  ROUND(SAFE_DIVIDE(sessions, FIRST_VALUE(sessions) OVER w), 4) AS pct_of_all_sessions,
  ROUND(SAFE_DIVIDE(sessions, LAG(sessions) OVER w), 4)         AS pct_of_previous_step,
  ROUND(1 - SAFE_DIVIDE(sessions, LAG(sessions) OVER w), 4)     AS drop_off_from_previous_step
FROM long_format
WINDOW w AS (PARTITION BY device_category ORDER BY step_order)
ORDER BY device_category, step_order;
