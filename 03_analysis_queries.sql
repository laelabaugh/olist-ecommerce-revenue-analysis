-- =============================================================================
-- OLIST E-COMMERCE - ANALYSIS QUERIES
-- =============================================================================

-- =============================================================================
-- SECTION 1: KEY METRICS
-- =============================================================================

-- Main KPIs (96,518 orders, R$21.46M revenue, R$222 AOV, 4.26 avg rating)
SELECT 
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

-- Satisfaction rate (80.2%)
SELECT 
    ROUND(100.0 * SUM(CASE WHEN review_score >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) AS satisfaction_rate_pct
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- Cancellation rate (1.43%)
SELECT 
    ROUND(100.0 * SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) / COUNT(*), 2) AS cancel_rate_pct
FROM orders;

-- =============================================================================
-- SECTION 2: SALES TRENDS
-- =============================================================================

-- Monthly revenue
SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value) / 1000000, 2) AS revenue_millions
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- Peak month: November 2017 (R$1.54M, +72% vs average)
WITH monthly AS (
    SELECT 
        strftime('%Y-%m', o.order_purchase_timestamp) AS month,
        SUM(oi.price + oi.freight_value) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT 
    month,
    ROUND(revenue / 1000000, 2) AS revenue_millions,
    ROUND((revenue / AVG(revenue) OVER() - 1) * 100, 0) AS vs_avg_pct
FROM monthly
ORDER BY revenue DESC
LIMIT 5;

-- Day of week pattern (weekdays ~25% higher than weekends)
SELECT 
    CASE CAST(strftime('%w', o.order_purchase_timestamp) AS INTEGER)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_of_week,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 0) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY CAST(strftime('%w', o.order_purchase_timestamp) AS INTEGER)
ORDER BY CAST(strftime('%w', o.order_purchase_timestamp) AS INTEGER);

-- =============================================================================
-- SECTION 3: REGIONAL PERFORMANCE
-- =============================================================================

-- Revenue by state (SP = 34.2%, RJ = 11.5%, MG = 9.6%)
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value) / 1000000, 2) AS revenue_millions,
    ROUND(100.0 * SUM(oi.price + oi.freight_value) / 
          (SELECT SUM(price + freight_value) FROM order_items), 1) AS share_pct
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue_millions DESC;

-- Top 3 states = 55% of revenue
SELECT 
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(price + freight_value) FROM order_items), 1) AS top3_share_pct
FROM (
    SELECT SUM(oi.price + oi.freight_value) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state
    ORDER BY revenue DESC
    LIMIT 3
);

-- Regional breakdown (Southeast = 58%)
SELECT 
    CASE 
        WHEN c.customer_state IN ('SP', 'RJ', 'MG', 'ES') THEN 'Southeast'
        WHEN c.customer_state IN ('RS', 'PR', 'SC') THEN 'South'
        WHEN c.customer_state IN ('BA', 'PE', 'CE', 'MA', 'PB', 'RN', 'AL', 'SE', 'PI') THEN 'Northeast'
        WHEN c.customer_state IN ('DF', 'GO', 'MT', 'MS') THEN 'Central-West'
        WHEN c.customer_state IN ('PA', 'AM', 'RO', 'AC', 'AP', 'RR', 'TO') THEN 'North'
    END AS region,
    ROUND(SUM(oi.price + oi.freight_value) / 1000000, 2) AS revenue_millions,
    ROUND(100.0 * SUM(oi.price + oi.freight_value) / 
          (SELECT SUM(price + freight_value) FROM order_items), 0) AS share_pct,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(AVG(julianday(o.order_delivered_customer_date) - 
              julianday(o.order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY region
ORDER BY revenue_millions DESC;

-- =============================================================================
-- SECTION 4: PRODUCT CATEGORIES
-- =============================================================================

-- Top categories (Furniture = R$3.54M/16%, Bed Bath = R$2.57M/11.6%, Computers = R$2.38M/10.7%)
SELECT 
    p.product_category_name AS category,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.price + oi.freight_value) / 1000000, 2) AS revenue_millions,
    ROUND(100.0 * SUM(oi.price + oi.freight_value) / 
          (SELECT SUM(price + freight_value) FROM order_items), 1) AS share_pct,
    ROUND(AVG(oi.price), 0) AS avg_price
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue_millions DESC
LIMIT 10;

-- Top 3 categories = 38% of revenue
SELECT 
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(price + freight_value) FROM order_items), 1) AS top3_share_pct
FROM (
    SELECT SUM(oi.price + oi.freight_value) AS revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY p.product_category_name
    ORDER BY revenue DESC
    LIMIT 3
);

-- Category satisfaction scores
SELECT 
    p.product_category_name AS category,
    COUNT(r.review_id) AS reviews,
    ROUND(AVG(r.review_score), 2) AS avg_score
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
HAVING reviews >= 500
ORDER BY avg_score DESC;

-- =============================================================================
-- SECTION 5: CUSTOMER SEGMENTS
-- =============================================================================

-- Purchase frequency (1 order = 57.7%, 2 orders = 29.2%, 3+ = 13.1%)
-- Repeat customers (42%) generate 64% of revenue
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN '1 order'
        WHEN order_count = 2 THEN '2 orders'
        ELSE '3+ orders'
    END AS segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS pct_customers,
    ROUND(SUM(total_spent) / 1000000, 1) AS revenue_millions,
    ROUND(AVG(total_spent), 0) AS avg_ltv
FROM customer_orders
GROUP BY segment
ORDER BY segment;

-- Repeat customer revenue share (64%)
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price + oi.freight_value) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    ROUND(100.0 * SUM(CASE WHEN order_count >= 2 THEN total_spent END) / SUM(total_spent), 0) AS repeat_revenue_pct
FROM customer_orders;

-- =============================================================================
-- SECTION 6: PAYMENT METHODS
-- =============================================================================

-- Payment breakdown (credit card = 74%, boleto = 19%)
SELECT 
    payment_type,
    COUNT(*) AS transactions,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 0) AS pct,
    ROUND(AVG(payment_value), 0) AS avg_value
FROM payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY payment_type
ORDER BY transactions DESC;

-- Installment usage (35% pay in full, 40% use 2-4, 25% use 5-12)
SELECT 
    CASE 
        WHEN payment_installments = 1 THEN '1 (full)'
        WHEN payment_installments BETWEEN 2 AND 4 THEN '2-4'
        WHEN payment_installments >= 5 THEN '5-12'
    END AS installment_group,
    COUNT(*) AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 0) AS pct
FROM payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered' 
  AND payment_type = 'credit_card'
GROUP BY installment_group
ORDER BY installment_group;

-- Average installments (3.4)
SELECT ROUND(AVG(payment_installments), 1) AS avg_installments
FROM payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered' 
  AND payment_type = 'credit_card';

-- =============================================================================
-- SECTION 7: CUSTOMER SATISFACTION
-- =============================================================================

-- Review distribution (5 stars = 65%, 4 stars = 15%, etc.)
SELECT 
    review_score,
    COUNT(*) AS reviews,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 1) AS pct
FROM reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY review_score
ORDER BY review_score DESC;

-- Delivery timing vs satisfaction (both ~80%, no major difference)
SELECT 
    CASE 
        WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) 
        THEN 'On-time/Early'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS reviews,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    ROUND(100.0 * SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) AS satisfaction_pct
FROM orders o
JOIN reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;

-- =============================================================================
-- SECTION 8: SELLER ANALYSIS
-- =============================================================================

-- Sellers by state
SELECT 
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS sellers,
    ROUND(100.0 * COUNT(DISTINCT s.seller_id) / (SELECT COUNT(*) FROM sellers), 0) AS pct
FROM sellers s
GROUP BY s.seller_state
ORDER BY sellers DESC
LIMIT 10;

-- =============================================================================
-- END
-- =============================================================================
