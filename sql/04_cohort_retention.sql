-- 04_cohort_retention.sql
-- Business question: do users come back after their first visit,
-- and do some acquisition channels bring more loyal users than others?
--
-- Cohort = the week (Monday start) of a user's first visit inside the window.
-- Users whose first touch happened BEFORE 2020-11-01 are excluded, so every
-- cohort contains genuinely new users.
-- Later cohorts have fewer observable weeks (data ends 2021-01-31) - expected.
-- Save the result as table: ga4_portfolio.cohort_retention

WITH activity AS (
  SELECT
    user_pseudo_id,
    traffic_source.source AS source,
    traffic_source.medium AS medium,
    user_first_touch_timestamp,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', event_date), WEEK(MONDAY)) AS activity_week
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

users AS (
  SELECT
    user_pseudo_id,
    ANY_VALUE(source)  AS source,
    ANY_VALUE(medium)  AS medium,
    MIN(activity_week) AS cohort_week
  FROM activity
  GROUP BY user_pseudo_id
  HAVING DATE(TIMESTAMP_MICROS(MIN(user_first_touch_timestamp))) >= DATE '2020-11-01'
),

user_weeks AS (
  SELECT DISTINCT
    u.user_pseudo_id,
    CASE
      WHEN u.medium = 'organic'                          THEN 'Organic Search'
      WHEN u.medium IN ('cpc', 'ppc', 'paid')            THEN 'Paid Search'
      WHEN u.medium = 'referral'                         THEN 'Referral'
      WHEN u.source = '(direct)' AND u.medium = '(none)' THEN 'Direct'
      WHEN u.medium IN ('<Other>', '(data deleted)')
        OR u.source IN ('<Other>', '(data deleted)')     THEN 'Other / Redacted'
      ELSE 'Other'
    END                                                   AS channel_group,
    u.cohort_week,
    DATE_DIFF(a.activity_week, u.cohort_week, WEEK(MONDAY)) AS week_number
  FROM users u
  JOIN activity a USING (user_pseudo_id)
),

cohort_counts AS (
  SELECT cohort_week, channel_group, week_number, COUNT(DISTINCT user_pseudo_id) AS active_users
  FROM user_weeks
  GROUP BY 1, 2, 3
  UNION ALL
  SELECT cohort_week, 'All channels', week_number, COUNT(DISTINCT user_pseudo_id)
  FROM user_weeks
  GROUP BY 1, 3
)

SELECT
  cohort_week,
  channel_group,
  week_number,
  active_users,
  FIRST_VALUE(active_users) OVER w                                AS cohort_size,
  ROUND(SAFE_DIVIDE(active_users, FIRST_VALUE(active_users) OVER w), 4) AS retention_rate
FROM cohort_counts
WHERE week_number BETWEEN 0 AND 12
WINDOW w AS (PARTITION BY cohort_week, channel_group ORDER BY week_number)
ORDER BY channel_group, cohort_week, week_number;
