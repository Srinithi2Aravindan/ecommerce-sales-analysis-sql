SELECT
    LOWER(status) AS order_status,
    payment_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY
    LOWER(status),
    payment_status
ORDER BY
    order_status,
    payment_status;