

-- PROJECT: E-commerce Data Analysis
-- MILESTONE 2: Get the Lay of the Land
-- FILE: 01_exploration.sql
-- PURPOSE: Explore database structure, business scale,
--          customer behaviour, order status and relationships.


-- 1. SET DATABASE SCHEMA


SET search_path TO ecom;


-- 2. DATABASE TABLE INVENTORY
-- Business question: What tables are available in this database?


SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'ecom'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;



-- 3. CORE TABLE COLUMN INVENTORY
-- Business question: What information does each core table store?

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'ecom'
  AND table_name IN (
      'customers',
      'orders',
      'order_items',
      'products'
  )
ORDER BY table_name, ordinal_position;



-- 4. BUSINESS SCALE

-- 4.1 Total number of orders

SELECT
    COUNT(*) AS total_orders
FROM orders;


-- 4.2 Total registered customers

SELECT
    COUNT(*) AS total_customers
FROM customers;


-- 4.3 Total products

SELECT
    COUNT(*) AS total_products
FROM products;


-- 5. ORDER DATE RANGE
-- Business question: What period does the available order data cover?


SELECT
    MIN(created_at) AS first_order_date,
    MAX(created_at) AS latest_order_date
FROM orders;



-- 6. CUSTOMER PURCHASE BEHAVIOUR
-- Business question: How many purchasing customers are repeat buyers?


SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_count > 1
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_percentage

FROM (
    SELECT
        customer_id,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) AS customer_orders;



-- 7. ORDER STATUS ANALYSIS

-- 7.1 Raw order status breakdown
-- Business question: How are orders distributed across statuses?

SELECT
    status,
    COUNT(*) AS order_count
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- 7.2 Normalized order status breakdown
-- Business question: Are inconsistent capitalizations affecting counts?
-- LOWER() combines values such as shipped, SHIPPED and Shipped.

SELECT
    LOWER(status) AS normalized_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY LOWER(status)
ORDER BY order_count DESC;



-- 8. PAYMENT STATUS ANALYSIS
-- Business question: How many orders are paid or failed?


SELECT
    payment_status,
    COUNT(*) AS payment_count
FROM orders
GROUP BY payment_status
ORDER BY payment_count DESC;



-- 9. ORDER STATUS VS PAYMENT STATUS
-- Business question: How do order lifecycle and payment outcomes relate?


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


-- 10. RELATIONSHIP VALIDATION
-- Purpose: Identify records without matching parent records.


-- 10.1 Orders -> Customers
-- Business question: Does every order have a matching customer?

SELECT
    COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 10.2 Order Items -> Orders
-- Business question: Does every order item belong to an existing order?

SELECT
    COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 10.3 Order Items -> Product Variants
-- Business question: Does every order item reference an existing variant?

SELECT
    COUNT(*) AS orphan_variants
FROM order_items oi
LEFT JOIN product_variants pv
    ON oi.variant_id = pv.variant_id
WHERE pv.variant_id IS NULL;


-- 10.4 Products -> Brands
-- Business question: Does every product have a matching brand?

SELECT
    COUNT(*) AS orphan_products
FROM products p
LEFT JOIN brands b
    ON p.brand_id = b.brand_id
WHERE b.brand_id IS NULL;


-- 10.5 Products -> Categories
-- Business question: Does every product have a matching category?

SELECT
    COUNT(*) AS orphan_categories
FROM products p
LEFT JOIN categories c
    ON p.category_id = c.category_id
WHERE c.category_id IS NULL;


-- 10.6 Product Variants -> Products
-- Business question: Does every variant belong to an existing product?

SELECT
    COUNT(*) AS orphan_product_variants
FROM product_variants pv
LEFT JOIN products p
    ON pv.product_id = p.product_id
WHERE p.product_id IS NULL;



-- 11. PRODUCT ID UNIQUENESS CHECK
-- Business question: Are product IDs unique in the products table?

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM products;


-- =========================================
--  PRODUCT CATEGORY ANALYSIS
-- =========================================

-- 1. Count products in each category

SELECT
    category_id,
    COUNT(*) AS product_count
FROM products
GROUP BY category_id
ORDER BY product_count DESC;


-- 2. Inspect category table columns

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'ecom'
  AND table_name = 'categories'
ORDER BY ordinal_position;

-- 3. Product count by category name

SELECT
    c.category_id,
    c.category_name,
    COUNT(p.product_id) AS product_count
FROM categories c
LEFT JOIN products p
    ON c.category_id = p.category_id
GROUP BY
    c.category_id,
    c.category_name
ORDER BY product_count DESC;

-- 4. Understand parent-child category hierarchy

SELECT
    c.category_id,
    c.category_name,
    c.parent_id,
    p.category_name AS parent_category
FROM categories c
LEFT JOIN categories p
    ON c.parent_id = p.category_id
ORDER BY
    c.parent_id NULLS FIRST,
    c.category_id;

-- FINDING:
-- 4 parent categories: Apparel, Electronics, Beauty, Home.
-- 14 subcategories contain all 4,000 products.
-- Parent categories have zero directly assigned products.

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'ecom'
  AND table_name = 'brands'
ORDER BY ordinal_position;

-- 5. Product distribution by brand

SELECT
    b.brand_id,
    b.brand_name,
    COUNT(p.product_id) AS product_count
FROM brands b
LEFT JOIN products p
    ON b.brand_id = p.brand_id
GROUP BY
    b.brand_id,
    b.brand_name
ORDER BY product_count DESC;

-- 6. Check product brand assignment

SELECT
    COUNT(*) AS total_products,
    COUNT(brand_id) AS products_with_brand,
    COUNT(*) - COUNT(brand_id) AS products_without_brand,
    COUNT(DISTINCT brand_id) AS unique_brands
FROM products;

-- 8. Verify missing product activity status

SELECT
    COUNT(*) FILTER (
        WHERE is_active IS TRUE
    ) AS active_products,

    COUNT(*) FILTER (
        WHERE is_active IS FALSE
    ) AS inactive_products,

    COUNT(*) FILTER (
        WHERE is_active IS NULL
    ) AS unknown_status_products

FROM products;