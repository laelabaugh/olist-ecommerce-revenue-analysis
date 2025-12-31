-- =============================================================================
-- OLIST E-COMMERCE - DATA INSPECTION
-- =============================================================================

-- =============================================================================
-- SECTION 1: ROW COUNTS
-- =============================================================================

-- Count records in each table
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation;

-- =============================================================================
-- SECTION 2: NULL CHECKS
-- =============================================================================

-- Check for NULLs in customers
SELECT 
    'customers' AS table_name,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_city
FROM customers;

-- Check for NULLs in orders
SELECT 
    'orders' AS table_name,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_ts,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivery_date
FROM orders;

-- Check for NULLs in order_items
SELECT 
    'order_items' AS table_name,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price
FROM order_items;

-- =============================================================================
-- SECTION 3: PRIMARY KEY CHECKS
-- =============================================================================

-- Check customer_id is unique
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customers,
    CASE WHEN COUNT(*) = COUNT(DISTINCT customer_id) 
         THEN 'PASS' ELSE 'FAIL' END AS check_result
FROM customers;

-- Check order_id is unique
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    CASE WHEN COUNT(*) = COUNT(DISTINCT order_id) 
         THEN 'PASS' ELSE 'FAIL' END AS check_result
FROM orders;

-- Check product_id is unique
SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS unique_products,
    CASE WHEN COUNT(*) = COUNT(DISTINCT product_id) 
         THEN 'PASS' ELSE 'FAIL' END AS check_result
FROM products;

-- =============================================================================
-- SECTION 4: FOREIGN KEY CHECKS
-- =============================================================================

-- Check for order_items with missing orders
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for orders with missing customers
SELECT COUNT(*) AS orphan_orders
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Check for order_items with missing products
SELECT COUNT(*) AS missing_products
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check for order_items with missing sellers
SELECT COUNT(*) AS missing_sellers
FROM order_items oi
LEFT JOIN sellers s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- =============================================================================
-- SECTION 5: MIN/MAX VALUE CHECKS
-- =============================================================================

-- Price and freight ranges
SELECT 
    'price' AS field,
    MIN(price) AS min_value,
    MAX(price) AS max_value,
    ROUND(AVG(price), 2) AS avg_value,
    SUM(CASE WHEN price < 0 THEN 1 ELSE 0 END) AS negative_count
FROM order_items
UNION ALL
SELECT 
    'freight_value',
    MIN(freight_value),
    MAX(freight_value),
    ROUND(AVG(freight_value), 2),
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END)
FROM order_items;

-- Review score range (should be 1-5)
SELECT 
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score,
    ROUND(AVG(review_score), 2) AS avg_score,
    SUM(CASE WHEN review_score < 1 OR review_score > 5 THEN 1 ELSE 0 END) AS invalid_scores
FROM reviews;

-- Installment range
SELECT 
    MIN(payment_installments) AS min_installments,
    MAX(payment_installments) AS max_installments,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM payments;

-- =============================================================================
-- SECTION 6: DATE CHECKS
-- =============================================================================

-- Order date range
SELECT 
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order,
    ROUND(julianday(MAX(order_purchase_timestamp)) - 
          julianday(MIN(order_purchase_timestamp)), 0) AS days_span
FROM orders;

-- Check for future dates
SELECT COUNT(*) AS future_orders
FROM orders
WHERE order_purchase_timestamp > datetime('now');

-- Check for delivery before purchase (should be 0)
SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- =============================================================================
-- SECTION 7: CATEGORY CHECKS
-- =============================================================================

-- Order status breakdown
SELECT 
    order_status,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 2) AS pct
FROM orders
GROUP BY order_status
ORDER BY count DESC;

-- Payment type breakdown
SELECT 
    payment_type,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM payments), 2) AS pct
FROM payments
GROUP BY payment_type
ORDER BY count DESC;

-- Customer state breakdown
SELECT 
    customer_state,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers), 2) AS pct
FROM customers
GROUP BY customer_state
ORDER BY customers DESC;

-- =============================================================================
-- SECTION 8: DATA FILL RATES
-- =============================================================================

-- How complete is the delivery data?
SELECT 
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    ROUND(100.0 * SUM(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END) / 
          COUNT(*), 1) AS delivery_date_fill_pct
FROM orders
WHERE order_status = 'delivered';

-- How many delivered orders have reviews?
SELECT 
    'reviews' AS table_name,
    (SELECT COUNT(*) FROM orders WHERE order_status = 'delivered') AS delivered_orders,
    COUNT(*) AS reviews,
    ROUND(100.0 * COUNT(*) / 
          (SELECT COUNT(*) FROM orders WHERE order_status = 'delivered'), 1) AS review_rate_pct
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- =============================================================================
-- END
-- =============================================================================
