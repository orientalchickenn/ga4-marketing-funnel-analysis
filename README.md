# E-commerce Marketing Funnel & Channel Performance Analysis

**Tools:** SQL (Google BigQuery) · Google Sheets · d3.js dashboard · GA4 event data  
**Author:** Kenneth Ezekiel Sunardibuana

> 📊 **Dashboard:** https://claude.ai/artifact/5yk9VUqYsFuxjpbkRfMdqK

The dashboard follows a consulting-report structure: headline KPIs, an executive summary,
six numbered exhibits each titled with its finding, and a prioritised recommendations table.
The exact numbers behind every exhibit are in [`results/`](results/) as CSV files.

## Business problem

An online store spends money and effort bringing visitors in through search, ads,
referrals and direct traffic. Marketing needs to know:

1. **Where do shoppers drop out** between viewing a product and paying?
2. **Which channels bring buyers**, not just visitors?
3. **Who are the most valuable customers**, and who is at risk of leaving?
4. **Do visitors come back**, and does that depend on how they found the store?

## Data

[Google Merchandise Store GA4 sample](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset)
(`bigquery-public-data.ga4_obfuscated_sample_ecommerce`): real, obfuscated event data
from Google's official merchandise store, **1 Nov 2020 – 31 Jan 2021**.
One row per event (page view, view item, add to cart, purchase...) with nested
event parameters, device, country, first-touch traffic source and e-commerce revenue.

## Approach

| Step | File | What it does |
|---|---|---|
| 0 | [`sql/00_explore.sql`](sql/00_explore.sql) | Date range, event types, traffic sources, data-quality checks |
| 1 | [`sql/01_funnel.sql`](sql/01_funnel.sql) | Closed session funnel (session → view item → cart → checkout → purchase) by device |
| 2 | [`sql/02_channel_performance.sql`](sql/02_channel_performance.sql) | Users, conversion rate, revenue, AOV and revenue share per acquisition channel |
| 3 | [`sql/03_rfm_segmentation.sql`](sql/03_rfm_segmentation.sql) | RFM scoring and customer segments (Champions, At risk, ...) |
| 4 | [`sql/04_cohort_retention.sql`](sql/04_cohort_retention.sql) | Weekly retention cohorts, overall and by channel |
| 5 | [`sql/05_device_country.sql`](sql/05_device_country.sql) | Conversion and order value by device and country |

**Key SQL techniques:** `UNNEST` of nested GA4 event parameters, session keys built from
`user_pseudo_id` + `ga_session_id`, window functions (`LAG`, `FIRST_VALUE`, `NTILE`,
share-of-total), transaction de-duplication, long-format outputs for BI tools.

## Key findings

Full numbers: [`results/summary.md`](results/summary.md).

1. **The leak is before the cart, not at checkout.** Of 360,129 sessions, only 21.4% viewed a
   product and **80.3% of product viewers never added to cart**. Once shoppers start checkout,
   47.8% complete the purchase. Session-to-purchase conversion is 0.79%.
2. **Mobile is not the problem.** Mobile converts as well as desktop (0.82% vs 0.77% of
   sessions; 1.41% vs 1.35% of users), and every funnel step is within about 2 points across devices.
3. **Organic Search brings the most traffic; Referral brings the most valuable users.**
   Organic is 36.5% of users but 27.7% of revenue ($0.87 per user). Referral is 15.8% of users
   but 22.2% of revenue, with the best conversion (1.86%) and revenue per user ($1.60, about 1.8× organic).
4. **Paid Search underperforms on every metric except order size.** It has the lowest user
   conversion (0.89%), the lowest revenue per user ($0.77) and the weakest week-1 retention (2.1% vs
   5.4% for Referral), even though its average order value is the highest ($79.46).
5. **A fifth of revenue sits with customers who are slipping away.** 466 "At risk (high value)"
   customers (12.6% of buyers) generated 21.2% of revenue, averaging $140 each, but last bought
   about 68 days before the end of the data. Only 439 buyers (11.9%) ordered more than once.

## Recommendations

1. **Fix product pages first, not checkout.** Test what stops viewers from adding to cart
   (price and shipping visibility, product images, reviews, stock). Success metric: view-item →
   add-to-cart rate, currently 19.7%.
2. **Grow referral, review paid search.** Invest in the referral sources that already convert
   best (partners, affiliates, content links). Audit paid-search keywords and landing pages before
   adding budget; judge it on revenue per user, not clicks.
3. **Run a win-back campaign for the 466 at-risk, high-value customers**, e.g. a personalised
   email with new arrivals or a time-limited offer. Success metric: share of the segment that
   buys again within 30 days.
4. **Turn first orders into second orders.** With 88% of buyers ordering once, a post-purchase
   email sequence aimed at "New big spenders" (434 customers, $130 average) is the cheapest
   source of repeat revenue.

## Limitations

- **Obfuscated sample:** some values are replaced with `<Other>` or `(data deleted)`; Google
  notes the data is anonymised, so absolute numbers should not be treated as the real store's.
- **Three months only:** most buyers order once, so RFM frequency uses fixed buckets and
  retention for later cohorts is truncated.
- **First-touch attribution:** the channel is the user's first acquisition source, not the
  source of each session or the last click before purchase.
- **"Other / Redacted" channel:** 19% of users have a source hidden by Google's obfuscation, so
  channel shares for the named channels are understated.
- **Closed funnel:** purchases made in a session without a `view_item` event are not counted
  in the funnel (they are still counted in the channel and RFM revenue).

## How to reproduce

1. Open the [BigQuery console](https://console.cloud.google.com/bigquery) with a Google account
   (the free **BigQuery sandbox** needs no credit card; these queries use well under the 1 TB/month free tier).
2. Create a project, then a dataset named `ga4_portfolio`.
3. Run each file in `sql/` in order. For files 01–05: **Save results → BigQuery table** in
   `ga4_portfolio`, using the table name in the file's header comment.
4. In Looker Studio, add each saved table as a BigQuery data source and build the pages below.

## Dashboard layout (Looker Studio)

| Page | Source table | Charts |
|---|---|---|
| **1. Overview & Funnel** | `funnel_by_device` | KPI cards (sessions, purchases, conversion), funnel bar chart (`step_name` × `sessions`), device filter, drop-off table |
| **2. Channels** | `channel_performance` | Bar: users vs revenue share per channel; table: conversion rate, AOV, revenue per user |
| **3. Customers (RFM)** | `rfm_segments` | Bar: customers vs revenue share per segment; table of segment averages |
| **4. Retention** | `cohort_retention` | Pivot table heatmap: `cohort_week` × `week_number`, value `retention_rate`; channel filter |
| **5. Devices & Markets** | `device_country` | Geo map by revenue; table of top countries by conversion |
