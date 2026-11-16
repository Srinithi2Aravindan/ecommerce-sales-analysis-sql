-- Milestone 3: Revenue, AOV and Growth Analysis
-- File: 02_revenue.sql


SET search_path TO ecom;


-- 1. Overall Revenue and Average Order Value
-- Purpose: Calculate total paid revenue, paid orders and AOV.


SELECT
    COUNT(*) FILTER (
        WHERE payment_status = 'paid'
    ) AS paid_orders,

    ROUND(
        SUM(total) FILTER (
            WHERE payment_status = 'paid'
        ),
        2
    ) AS total_revenue,

    ROUND(
        (
            SUM(total) FILTER (
                WHERE payment_status = 'paid'
            )
            /
            COUNT(*) FILTER (
                WHERE payment_status = 'paid'
            )
        ),
        2
    ) AS average_order_value

FROM orders;

SELECT
    order_id,
    subtotal,
    discount,
    tax,
    shipping_fee,
    total
FROM orders
WHERE payment_status = 'paid'
LIMIT 5;


-- 2. Order Value Distribution
-- Purpose: Compare average, median, minimum and maximum
-- order values to understand the distribution.


SELECT
    COUNT(*) AS paid_orders,

    ROUND(AVG(total), 2) AS average_order_value,

    PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY total) AS median_order_value,

    MIN(total) AS minimum_order_value,

    MAX(total) AS maximum_order_value

FROM orders
WHERE payment_status = 'paid';

-- 3. Highest Value Orders
-- Purpose: Identify the 10 highest-value paid orders
-- for further investigation.

SELECT
    order_id,
    created_at,
    subtotal,
    discount,
    tax,
    shipping_fee,
    total
FROM orders
WHERE payment_status = 'paid'
ORDER BY total DESC
LIMIT 10;


-- 4. Monthly Revenue and AOV Trend
-- Purpose: Track monthly revenue, paid order volume
-- and average order value.


SELECT
    DATE_TRUNC('month', created_at)::DATE AS sales_month,

    COUNT(*) AS paid_orders,

    ROUND(SUM(total), 2) AS monthly_revenue,

    ROUND(AVG(total), 2) AS average_order_value

FROM orders
WHERE payment_status = 'paid'

GROUP BY 1
ORDER BY 1;


-- 5. Revenue Growth Driver Analysis
-- Purpose: Compare monthly revenue, order volume and AOV
-- with the previous month.

WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', created_at)::DATE AS sales_month,
        COUNT(*) AS paid_orders,
        SUM(total) AS monthly_revenue,
        AVG(total) AS average_order_value
    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY 1
),

monthly_comparison AS (
    SELECT
        sales_month,
        paid_orders,
        monthly_revenue,
        average_order_value,

        LAG(paid_orders) OVER (
            ORDER BY sales_month
        ) AS previous_orders,

        LAG(monthly_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_revenue,

        LAG(average_order_value) OVER (
            ORDER BY sales_month
        ) AS previous_aov

    FROM monthly_metrics
)

SELECT
    sales_month,
    paid_orders,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    ROUND(average_order_value, 2) AS average_order_value,

    ROUND(
        (paid_orders - previous_orders) * 100.0
        / NULLIF(previous_orders, 0), 2
    ) AS order_growth_percentage,

    ROUND(
        (monthly_revenue - previous_revenue) * 100.0
        / NULLIF(previous_revenue, 0), 2
    ) AS revenue_growth_percentage,

    ROUND(
        (average_order_value - previous_aov) * 100.0
        / NULLIF(previous_aov, 0), 2
    ) AS aov_growth_percentage

FROM monthly_comparison
ORDER BY sales_month;


-- 6. Average Items Per Order
-- Purpose: Understand how many items customers
-- purchase in each order.

SELECT
    COUNT(DISTINCT o.order_id) AS paid_orders,
    SUM(oi.qty) AS total_items_sold,

    ROUND(
        SUM(oi.qty)::NUMERIC /
        COUNT(DISTINCT o.order_id),
        2
    ) AS average_items_per_order,

    ROUND(
        SUM(oi.line_total) /
        SUM(oi.qty),
        2
    ) AS average_price_per_item

FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.payment_status = 'paid';


-- 7. Monthly AOV Composition
-- Purpose: Compare average items per order
-- and average item revenue across months.

WITH monthly_order_items AS (
    SELECT
        o.order_id,
        DATE_TRUNC('month', o.created_at)::DATE AS sales_month,
        SUM(oi.qty) AS total_units,
        SUM(oi.line_total) AS item_revenue

    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id

    WHERE o.payment_status = 'paid'

    GROUP BY
        o.order_id,
        DATE_TRUNC('month', o.created_at)::DATE
)

SELECT
    sales_month,
    COUNT(*) AS paid_orders,

    ROUND(
        AVG(total_units),
        2
    ) AS average_items_per_order,

    ROUND(
        SUM(item_revenue) / NULLIF(SUM(total_units), 0),
        2
    ) AS average_revenue_per_item,

    ROUND(
        SUM(item_revenue) / COUNT(*),
        2
    ) AS average_item_revenue_per_order

FROM monthly_order_items
GROUP BY sales_month
ORDER BY sales_month;


-- 8. Revenue Reconciliation
-- Purpose: Verify monthly revenue totals against
-- overall paid revenue.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', created_at)::DATE AS sales_month,
        SUM(total) AS monthly_revenue
    FROM orders
    WHERE payment_status = 'paid'
    GROUP BY 1
)

SELECT
    ROUND(SUM(monthly_revenue), 2) AS sum_of_monthly_revenue,

    (
        SELECT ROUND(SUM(total), 2)
        FROM orders
        WHERE payment_status = 'paid'
    ) AS overall_paid_revenue,

    ROUND(
        SUM(monthly_revenue) -
        (
            SELECT SUM(total)
            FROM orders
            WHERE payment_status = 'paid'
        ),
        2
    ) AS revenue_difference

FROM monthly_revenue;