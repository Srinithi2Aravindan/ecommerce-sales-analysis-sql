# Ecommerce Sales Analysis with SQL

**Analyst:** Srinithi Aravindan

**Project Goal:** Analyze ecommerce transaction data using PostgreSQL and document actionable insights on business performance, revenue trends and customer segmentation to support data-driven business decisions.

## Repository Structure

- `sql/`: Clean, commented SQL queries with business context.
- `findings/`: Markdown reports answering core stakeholder questions.

## Project Overview

This project explores an ecommerce database containing 40,000 orders from 10,000 registered customers, covering March 16 to June 14, 2026.

The analysis uses PostgreSQL to investigate business operations, evaluate revenue performance, understand customer purchasing patterns and identify opportunities to improve customer retention.

## Tools & Technologies

- PostgreSQL
- SQL
- Visual Studio Code
- SQLTools Extension

## Dataset Overview

|          Metric               | Value  |
|-------------------------------|--------|
|          Total orders         | 40,000 |
|          Registered customers | 10,000 |
| Customers with order activity | 8,800  |
|       Paid orders             | 37,822 |
|        Failed payments        | 2,178  |
|          Products             | 4,000  |
|           Brands              | 120    |
|          Categories           | 18     |
|     Observation period        | March 16 – June 14, 2026 |

## Business Analysis & Key Findings

### 1. Business Overview

Explored database structure, customer activity, order and payment statuses, and product catalogue information.

Key findings:
- 8,800 customers placed at least one order.
- 3,801 customers made repeat purchases based on order activity.
- 96.68% of products were active.
- All 2,178 failed-payment records were associated with cancelled orders.

Detailed report: [`01_business_overview.md`](findings/01_business_overview.md)

### 2. Business Health Analysis

Evaluated paid revenue, monthly performance, Average Order Value (AOV), basket composition and data quality.

Key findings:
- Total paid revenue: **₹28.29 crore**.
- Total paid orders: **37,822**.
- Overall AOV: **₹7,478.70**.
- April recorded the highest revenue at ₹12.31 crore.
- Average basket size was 2.65 items per paid order.

Detailed report: [`02_business_health.md`](findings/02_business_health.md)

### 3. Customer Segmentation & Marketing Insights

Analysed customer purchase frequency, one-time and repeat purchasing behaviour, spending patterns and segment-level revenue contribution.

Key findings:
- 8,438 customers made at least one paid purchase.
- Repeat customers contributed **87.63% of total paid revenue**.
- One-time customers represented 55.45% of purchasing customers.
- VIP customers represented 2.82% of purchasing customers but generated 28.83% of revenue.
- VIP and Regular customers together contributed 55.38% of total paid revenue.

Detailed report: [`03_customer_segments.md`](findings/03_customer_segments.md)

## Executive Summary

The analysis highlights three major business observations:

1. **Revenue performance:** The business generated ₹28.29 crore in paid revenue, with order volume being the primary driver of monthly revenue fluctuations.
2. **Customer retention:** Repeat customers accounted for 87.63% of paid revenue, demonstrating their importance to business performance.
3. **High-value segments:** VIP and Regular customers together generated 55.38% of total paid revenue, making customer retention a key marketing priority.

For detailed findings and recommendations, see [`00_executive_summary.md`](findings/00_executive_summary.md).

## Business Recommendations

- Improve second-purchase conversion among one-time customers.
- Introduce loyalty and personalized retention campaigns for VIP and Regular customers.
- Monitor paid order volume, AOV and basket composition to understand revenue changes.
- Evaluate marketing campaigns using repeat purchase rate, customer revenue and second-purchase conversion.

## How to Reproduce the Analysis

1. Install PostgreSQL and Visual Studio Code.
2. Configure a PostgreSQL connection using SQLTools or another PostgreSQL client.
3. Load the ecommerce dataset into PostgreSQL.
4. Ensure the database schema is named `ecom`, or modify the SQL search path.
5. Open the SQL scripts in the `sql/` directory.
6. Execute the scripts to reproduce the analysis.
7. Refer to the corresponding Markdown reports in `findings/` for business interpretations.

Each SQL script should begin with:

```sql
SET search_path TO ecom;
```

## Limitations & Future Analysis

The dataset covers approximately three months, which is insufficient to establish long-term trends or seasonality. March and June are partial months, so direct comparisons with complete months should be interpreted carefully.

Further analysis could explore:
- Product and category-level revenue performance.
- Brand-level sales contribution.
- Customer cohort retention.
- Long-term customer lifetime value.
- Seasonality using at least 12 months of transaction data.

## Project Outcome

This project demonstrates practical SQL skills in data exploration, aggregation, revenue analysis, customer segmentation and business interpretation. It connects database analysis with actionable recommendations for ecommerce business stakeholders.