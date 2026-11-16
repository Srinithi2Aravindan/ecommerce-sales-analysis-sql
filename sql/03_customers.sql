

-- MILESTONE 4: WHO ARE OUR CUSTOMERS AND HOW DO THEY SHOP?

-- Objective:
-- Understand customer purchasing behaviour, spending patterns,
-- purchase frequency, customer segments and retention.
--
-- Database: PostgreSQL
-- Schema: ecom
-- Dataset period: 2026-03-16 to 2026-06-14



-- 1. CUSTOMER PURCHASE SUMMARY

-- Business Question:
-- How many customers made purchases, and how many
-- customers came back to purchase again?
SET search_path TO ecom;

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_purchasing_customers,

    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    ROUND(
        COUNT(*) FILTER (WHERE order_count > 1) * 100.0
        / COUNT(*),
        2
    ) AS repeat_customer_percentage

FROM customer_orders;


-- 2. ONE-TIME VS REPEAT CUSTOMER DISTRIBUTION
-- Business Question:
-- What percentage of purchasing customers purchased
-- only once versus more than once?

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time Customer'
        ELSE 'Repeat Customer'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_orders
GROUP BY 1
ORDER BY 1;



-- 3. CUSTOMER PURCHASE FREQUENCY DISTRIBUTION

-- Business Question:
-- How many customers placed 1, 2, 3 or more paid orders?


WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_paid_orders
    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    total_paid_orders,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_orders
GROUP BY total_paid_orders
ORDER BY total_paid_orders;



-- 4. TOP 10 CUSTOMERS BY TOTAL SPENDING

-- Business Question:
-- Which 10 customers generated the highest total
-- paid-order revenue?


SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS total_paid_orders,

    ROUND(SUM(total), 2) AS observed_spend

FROM orders
WHERE payment_status = 'paid'
GROUP BY customer_id
ORDER BY observed_spend DESC
LIMIT 10;



-- 5. SPENDING COMPARISON: ONE-TIME VS REPEAT CUSTOMERS

-- Business Question:
-- Do repeat customers spend more than one-time customers?


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_paid_orders > 1
            THEN 'Repeat Customer'
        ELSE 'One-time Customer'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(AVG(observed_spend), 2)
        AS average_customer_spend,

    ROUND(SUM(observed_spend), 2)
        AS total_segment_spend

FROM customer_orders
GROUP BY 1
ORDER BY 1;

-- 6. CUSTOMER SEGMENTATION BY PURCHASE FREQUENCY
-- Business Question:
-- How can customers be classified based on their
-- paid-order purchase frequency?
--
-- Segments:
-- One-time:          1 order
-- Occasional:        2-5 orders
-- Regular:           6-10 orders
-- Frequent:          11-20 orders
-- VIP / High-frequency: 21+ orders


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_paid_orders = 1
            THEN 'One-time'

        WHEN total_paid_orders BETWEEN 2 AND 5
            THEN 'Occasional'

        WHEN total_paid_orders BETWEEN 6 AND 10
            THEN 'Regular'

        WHEN total_paid_orders BETWEEN 11 AND 20
            THEN 'Frequent'

        ELSE 'VIP / High-frequency'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(AVG(observed_spend), 2)
        AS average_customer_spend,

    ROUND(SUM(observed_spend), 2)
        AS total_segment_spend

FROM customer_orders
GROUP BY 1
ORDER BY total_segment_spend DESC;



-- 7. TOP 20 VIP / HIGH-FREQUENCY CUSTOMERS BY TOTAL SPENDING

-- Business Question:
-- Who are the highest-spending customers among
-- customers with 21 or more paid orders

WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) >= 21
),
ranked_customers AS (
    SELECT
        customer_id,
        total_paid_orders,
        ROUND(observed_spend, 2) AS observed_spend,

        DENSE_RANK() OVER (
            ORDER BY observed_spend DESC
        ) AS customer_rank

    FROM customer_orders
)
SELECT *
FROM ranked_customers
ORDER BY customer_rank
LIMIT 20;



-- 8. TOP 20 CUSTOMERS BY AVERAGE ORDER VALUE (AOV)

-- Business Question:
-- Which customers have the highest average spending
-- per paid order?

WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend,

        ROUND(
            SUM(total) / COUNT(DISTINCT order_id),
            2
        ) AS average_order_value

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_paid_orders,
        ROUND(observed_spend, 2) AS observed_spend,
        average_order_value,

        DENSE_RANK() OVER (
            ORDER BY average_order_value DESC
        ) AS aov_rank

    FROM customer_orders
)
SELECT *
FROM ranked_customers
ORDER BY aov_rank
LIMIT 20;



-- 9. TOP 20 REPEAT CUSTOMERS BY AVERAGE ORDER VALUE

-- Business Question:
-- Among repeat customers, who has the highest
-- average spending per paid order?


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend,

        ROUND(
            SUM(total) / COUNT(DISTINCT order_id),
            2
        ) AS average_order_value

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id

    HAVING COUNT(DISTINCT order_id) > 1
),
ranked_customers AS (
    SELECT
        customer_id,
        total_paid_orders,
        ROUND(observed_spend, 2) AS observed_spend,
        average_order_value,

        DENSE_RANK() OVER (
            ORDER BY average_order_value DESC
        ) AS aov_rank

    FROM customer_orders
)
SELECT *
FROM ranked_customers
ORDER BY aov_rank, customer_id
LIMIT 20;



-- 10. TOP 10 REPEAT CUSTOMERS BY TOTAL SPENDING

-- Business Question:
-- Which repeat customers generated the highest
-- total paid-order revenue?


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id

    HAVING COUNT(DISTINCT order_id) > 1
),
ranked_customers AS (
    SELECT
        customer_id,
        total_paid_orders,
        ROUND(observed_spend, 2) AS observed_spend,

        DENSE_RANK() OVER (
            ORDER BY observed_spend DESC
        ) AS spend_rank

    FROM customer_orders
)
SELECT *
FROM ranked_customers
ORDER BY spend_rank, customer_id
LIMIT 10;



-- 11. AVERAGE SPENDING BY CUSTOMER FREQUENCY SEGMENT

-- Business Question:
-- Do customers who purchase more frequently also
-- spend more on average?


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN total_paid_orders = 1
            THEN '1. One-time'

        WHEN total_paid_orders BETWEEN 2 AND 5
            THEN '2. Occasional'

        WHEN total_paid_orders BETWEEN 6 AND 10
            THEN '3. Regular'

        WHEN total_paid_orders BETWEEN 11 AND 20
            THEN '4. Frequent'

        ELSE '5. VIP / High-frequency'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(AVG(total_paid_orders), 2)
        AS average_orders_per_customer,

    ROUND(AVG(observed_spend), 2)
        AS average_customer_spend,

    ROUND(SUM(observed_spend), 2)
        AS total_segment_spend

FROM customer_orders
GROUP BY 1
ORDER BY 1;


-- 12. REVENUE CONTRIBUTION BY CUSTOMER SEGMENT

-- Business Question:
-- What percentage of total paid-order revenue
-- does each customer segment contribute?


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        SUM(total) AS observed_spend

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
),
customer_segments AS (
    SELECT
        CASE
            WHEN total_paid_orders = 1
                THEN 'One-time'

            WHEN total_paid_orders BETWEEN 2 AND 5
                THEN 'Occasional'

            WHEN total_paid_orders BETWEEN 6 AND 10
                THEN 'Regular'

            WHEN total_paid_orders BETWEEN 11 AND 20
                THEN 'Frequent'

            ELSE 'VIP / High-frequency'
        END AS customer_segment,

        observed_spend

    FROM customer_orders
),
segment_revenue AS (
    SELECT
        customer_segment,

        SUM(observed_spend) AS total_segment_spend

    FROM customer_segments
    GROUP BY customer_segment
)
SELECT
    customer_segment,

    ROUND(total_segment_spend, 2)
        AS total_segment_spend,

    ROUND(
        total_segment_spend * 100.0 /
        SUM(total_segment_spend) OVER (),
        2
    ) AS revenue_contribution_percentage

FROM segment_revenue
ORDER BY total_segment_spend DESC;



-- 13. ONE-TIME CUSTOMER CONVERSION OPPORTUNITY

-- Business Question:
-- How many customers made only one paid purchase
-- and could be targeted for a second-purchase campaign?


WITH customer_orders AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (
        WHERE total_paid_orders = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE total_paid_orders > 1
    ) AS repeat_customers,

    COUNT(*) AS total_purchasing_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE total_paid_orders = 1
        ) * 100.0 / COUNT(*),
        2
    ) AS one_time_customer_percentage

FROM customer_orders;



-- 14. CUSTOMER LAST PURCHASE DATE AND RECENCY

-- Business Question:
-- When did each customer last make a paid purchase?
-- How many days passed between that purchase and
-- the dataset end date?
--
-- Dataset end date: 2026-06-14


SELECT
    customer_id,

    COUNT(DISTINCT order_id) AS total_paid_orders,

    MAX(created_at)::date AS last_purchase_date,

    DATE '2026-06-14' - MAX(created_at)::date
        AS days_since_last_purchase

FROM orders
WHERE payment_status = 'paid'
GROUP BY customer_id
ORDER BY days_since_last_purchase DESC
LIMIT 20;



-- 15. CUSTOMER RECENCY SEGMENTATION

-- Business Question:
-- How many customers purchased recently, need attention
-- or may be at risk of becoming inactive?
--
-- Recency groups:
-- 0-30 days: Recently Active
-- 31-60 days: Needs Attention
-- 61-90 days: At Risk


WITH customer_recency AS (
    SELECT
        customer_id,

        COUNT(DISTINCT order_id) AS total_paid_orders,

        MAX(created_at)::date AS last_purchase_date,

        DATE '2026-06-14' - MAX(created_at)::date
            AS days_since_last_purchase

    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN days_since_last_purchase BETWEEN 0 AND 30
            THEN 'Recently Active (0-30 days)'

        WHEN days_since_last_purchase BETWEEN 31 AND 60
            THEN 'Needs Attention (31-60 days)'

        WHEN days_since_last_purchase BETWEEN 61 AND 90
            THEN 'At Risk (61-90 days)'

        ELSE 'Other'
    END AS recency_segment,

    COUNT(*) AS total_customers,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_recency
GROUP BY 1
ORDER BY 1;

-- 16. VIP CUSTOMER PROFILE: FREQUENCY AND AOV

-- Business Question:
-- What is the average purchase frequency and
-- average order value of VIP customers?

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS total_paid_orders,
        SUM(total) AS observed_spend
    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY customer_id
    HAVING COUNT(DISTINCT order_id) >= 21
)
SELECT
    COUNT(*) AS vip_customers,

    ROUND(AVG(total_paid_orders), 2)
        AS average_orders_per_customer,

    SUM(total_paid_orders) AS total_paid_orders,

    ROUND(AVG(observed_spend), 2)
        AS average_customer_spend,

    ROUND(
        SUM(observed_spend) / SUM(total_paid_orders),
        2
    ) AS average_order_value,

    ROUND(SUM(observed_spend), 2)
        AS total_vip_revenue

FROM customer_orders;

-- END OF MILESTONE 4

