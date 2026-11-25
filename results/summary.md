# Results snapshot

Output of the queries in `sql/`, run in BigQuery on 2026-11-25 against
`bigquery-public-data.ga4_obfuscated_sample_ecommerce` (2020-11-01 – 2021-01-31).
Revenue is in USD as stored in the obfuscated sample, so treat absolute amounts as illustrative.

## 1. Funnel (closed, per session)

| Step | All devices | % of sessions | % of previous step | Desktop | Mobile | Tablet |
|---|---:|---:|---:|---:|---:|---:|
| Session | 360,129 | 100% | — | 208,942 | 143,185 | 8,002 |
| View item | 77,020 | 21.4% | 21.4% | 44,819 | 30,501 | 1,700 |
| Add to cart | 15,173 | 4.2% | 19.7% | 8,780 | 6,072 | 321 |
| Begin checkout | 5,959 | 1.65% | 39.3% | 3,425 | 2,404 | 130 |
| Purchase | 2,848 | 0.79% | 47.8% | 1,606 | 1,180 | 62 |

Session → purchase: desktop 0.77%, mobile 0.82%, tablet 0.77%.

## 2. Channels (first-touch acquisition)

| Channel | Users | Share of users | Purchasers | User conv. | Revenue | Share of revenue | AOV | Revenue / user |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Organic Search | 98,490 | 36.5% | 1,103 | 1.12% | $85,246 | 27.7% | $65.12 | $0.87 |
| Other / Redacted | 52,064 | 19.3% | 884 | 1.70% | $75,418 | 24.5% | $68.94 | $1.45 |
| Direct | 63,463 | 23.5% | 803 | 1.27% | $68,911 | 22.4% | $72.16 | $1.09 |
| Referral | 42,754 | 15.8% | 794 | 1.86% | $68,295 | 22.2% | $70.92 | $1.60 |
| Paid Search | 13,383 | 5.0% | 119 | 0.89% | $10,330 | 3.4% | $79.46 | $0.77 |

## 3. RFM customer segments (3,701 buyers, $308,200 revenue)

| Segment | Customers | Share of customers | Revenue | Share of revenue | Avg days since last order | Avg orders | Avg spend |
|---|---:|---:|---:|---:|---:|---:|---:|
| Champions | 149 | 4.0% | $30,251 | 9.8% | 31.3 | 2.97 | $203.03 |
| Loyal repeat buyers | 290 | 7.8% | $46,135 | 15.0% | 54.6 | 2.58 | $159.09 |
| New big spenders | 434 | 11.7% | $56,512 | 18.3% | 25.2 | 1.00 | $130.21 |
| Recent low spenders | 849 | 22.9% | $29,039 | 9.4% | 28.0 | 1.00 | $34.20 |
| At risk (high value) | 466 | 12.6% | $65,378 | 21.2% | 67.6 | 1.00 | $140.30 |
| Hibernating | 1,513 | 40.9% | $80,885 | 26.2% | 61.2 | 1.00 | $53.46 |

## 4. Retention (share of new users active again N weeks after their first week)

Only cohorts with N full weeks of observable data are included.

| Channel | Week 1 | Week 2 | Week 4 |
|---|---:|---:|---:|
| All channels | 3.80% | 1.53% | 0.90% |
| Referral | 5.43% | 2.27% | 1.36% |
| Other / Redacted | 4.91% | 1.91% | 1.14% |
| Direct | 3.62% | 1.43% | 0.82% |
| Organic Search | 2.91% | 1.19% | 0.69% |
| Paid Search | 2.07% | 0.83% | 0.57% |

## 5. Devices and top markets (segments with ≥100 users)

| Device | Users | Purchasers | User conv. | Revenue |
|---|---:|---:|---:|---:|
| Desktop | 156,427 | 2,107 | 1.35% | $175,735 |
| Mobile | 106,965 | 1,506 | 1.41% | $122,622 |
| Tablet | 4,598 | 52 | 1.13% | $4,058 |

| Country | Users | Purchasers | User conv. | Revenue |
|---|---:|---:|---:|---:|
| United States | 120,313 | 1,638 | 1.36% | $135,989 |
| India | 25,761 | 345 | 1.34% | $29,219 |
| Canada | 20,582 | 299 | 1.45% | $27,075 |
| United Kingdom | 8,641 | 120 | 1.39% | $9,853 |
| France | 5,462 | 86 | 1.57% | $5,893 |
| Spain | 5,112 | 78 | 1.53% | $6,864 |
| Germany | 4,929 | 63 | 1.28% | $4,859 |
| China | 4,701 | 55 | 1.17% | $5,133 |
| Taiwan | 4,646 | 60 | 1.29% | $3,571 |
| Italy | 3,729 | 43 | 1.15% | $4,408 |
