#● Customer Analysis
#1. Find the total number of unique customers.
use retail;
select count(*) from customers;
SELECT COUNT(distinct customer_id) AS total_unique_customers
FROM customers;

#2. Identify the top 5 states with the highest number of customers. 
SELECT customer_state, COUNT(*) AS num_customers
FROM customers
GROUP BY customer_state
ORDER BY num_customers DESC
LIMIT 5;

# - Calculate customer retention rate (customers who placed more than 1 order).
WITH cust_orders AS (
  SELECT customer_id, COUNT(*) AS orders_count
  FROM orders
  GROUP BY customer_id
)
SELECT
SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
COUNT(*) AS total_customers,
ROUND(100.0 * SUM(CASE WHEN orders_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS retention_rate_pct
FROM cust_orders;

# - Find customers who gave the lowest review scores more than twice.
SET @min_score := (SELECT MIN(review_score) FROM order_review);

SELECT o.customer_id, c.customer_city, c.customer_state, COUNT(*) AS times_low_score
FROM order_review r
JOIN orders o ON r.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE r.review_score = @min_score
GROUP BY o.customer_id, c.customer_city, c.customer_state
HAVING COUNT(*) > 2;


#Order & Delivery Analysis

#1. Count the total number of delivered vs. canceled orders.
SELECT order_status, COUNT(*) AS cnt
FROM orders
GROUP BY order_status;

#2. Calculate the average delivery time for delivered orders.
SELECT
  ROUND(AVG(
    TIMESTAMPDIFF(SECOND,
      STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
      STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
    )/86400.0
  ), 2) AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_status = 'delivered';

#3. Identify the top 5 cities with the fastest delivery times.
SELECT c.customer_city,
       ROUND(AVG(TIMESTAMPDIFF(SECOND,
         STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
         STR_TO_DATE(o.order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
       )/86400.0), 2) AS avg_delivery_days,
       COUNT(*) AS orders_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_status = 'delivered'
GROUP BY c.customer_city
HAVING COUNT(*) >= 10   -- optional: require min sample size
ORDER BY avg_delivery_days ASC
LIMIT 5;

#4. Determine the percentage of orders delivered late vs. estimated date. - Find the month with the maximum number of orders.
SELECT
  SUM(CASE WHEN STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s') > STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s') THEN 1 ELSE 0 END) AS late_count,
  SUM(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END) AS delivered_count,
  ROUND(100.0 * SUM(CASE WHEN STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s') > STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s') THEN 1 ELSE 0 END) /
        NULLIF(SUM(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 ELSE 0 END),0), 2) AS pct_late
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

SELECT
  DATE_FORMAT(STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'), '%Y-%m') AS month,
  COUNT(*) AS orders_count
FROM orders
GROUP BY month
ORDER BY orders_count DESC
LIMIT 1;


#● Product & Category Analysis.

#1. Find the top 10 most sold product categories.
SELECT p.`product category` AS category, COUNT(*) AS units_sold
FROM order_item oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.`product category`
ORDER BY units_sold DESC
LIMIT 10;


#2. Calculate average weight, length, height, and width for products in each category.

SELECT
  p.`product category` AS category,
  ROUND(AVG(CAST(NULLIF(p.product_weight_g, '') AS DECIMAL(10,2))), 2) AS avg_weight_g,
  ROUND(AVG(CAST(NULLIF(p.product_length_cm, '') AS DECIMAL(10,2))), 2) AS avg_length_cm,
  ROUND(AVG(CAST(NULLIF(p.product_height_cm, '') AS DECIMAL(10,2))), 2) AS avg_height_cm,
  ROUND(AVG(CAST(NULLIF(p.product_width_cm, '') AS DECIMAL(10,2))), 2) AS avg_width_cm
FROM products p
GROUP BY p.`product category`;

#- Identify products with the highest freight-to-price ratio.
-- Per order_item instance:
SELECT oi.order_id, oi.order_item_id, oi.product_id,
       CAST(oi.freight_value AS DECIMAL(10,2)) / NULLIF(CAST(NULLIF(oi.price,'') AS DECIMAL(10,2)),0) AS freight_to_price
FROM order_item oi
WHERE CAST(NULLIF(oi.price,'') AS DECIMAL(10,2)) IS NOT NULL
ORDER BY freight_to_price DESC
LIMIT 20;

-- Or aggregate per product:
SELECT p.product_id, p.`product category`, ROUND(AVG(CAST(oi.freight_value AS DECIMAL(10,2))/NULLIF(CAST(NULLIF(oi.price,'') AS DECIMAL(10,2)),0)),4) AS avg_freight_to_price,
       COUNT(*) AS sales_count
FROM order_item oi
JOIN products p ON oi.product_id = p.product_id
WHERE CAST(NULLIF(oi.price,'') AS DECIMAL(10,2)) > 0
GROUP BY p.product_id, p.`product category`
ORDER BY avg_freight_to_price DESC
LIMIT 20;

#3. Find the top 3 products (by revenue) in each category.
WITH prod_revenue AS (
  SELECT
    p.product_id,
    p.`product category` AS category,
    SUM(CAST(NULLIF(oi.price,'') AS DECIMAL(12,2))) AS revenue
  FROM order_item oi
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY p.product_id, p.`product category`
)
SELECT product_id, category, revenue
FROM (
  SELECT pr.*,
         ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
  FROM prod_revenue pr
) t
WHERE rn <= 3
ORDER BY category, rn;


#● Payment & Revenue Analysis
#1. Find the most common payment type.
SELECT payment_type, COUNT(*) AS cnt
FROM payments
GROUP BY payment_type
ORDER BY cnt DESC
LIMIT 1;


#2. Calculate revenue by payment type.
SELECT payment_type, ROUND(SUM(payment_value),2) AS revenue
FROM payments
GROUP BY payment_type
ORDER BY revenue DESC;

#3. Determine the average number of installments for credit card payments. 
SELECT ROUND(AVG(payment_installments),2) AS avg_installments
FROM payments
WHERE LOWER(payment_type) LIKE '%credit%';

#- Find the top 5 highest-value orders and their payment details.
WITH order_paid AS (
  SELECT order_id, SUM(payment_value) AS total_paid
  FROM payments
  GROUP BY order_id
)
SELECT p.*
FROM payments p
JOIN (
  SELECT order_id
  FROM order_paid
  ORDER BY total_paid DESC
  LIMIT 5
) top5 ON p.order_id = top5.order_id
ORDER BY p.order_id, p.payment_sequential;

#● Review Analysis
#1. Find the average review score per product category.
SELECT pr.`product category` AS category,
       ROUND(AVG(r.review_score), 2) AS avg_review_score,
       COUNT(*) AS review_count
FROM order_review r
JOIN orders o ON r.order_id = o.order_id
JOIN order_item oi ON o.order_id = oi.order_id
JOIN products pr ON oi.product_id = pr.product_id
GROUP BY pr.`product category`
ORDER BY avg_review_score DESC;

#2. Identify sellers consistently receiving reviews below 3.
SELECT s.seller_id, s.seller_city, s.seller_state,
       ROUND(AVG(r.review_score),2) AS avg_score,
       COUNT(*) AS reviews_count
FROM order_review r
JOIN orders o ON r.order_id = o.order_id
JOIN order_item oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
HAVING avg_score < 3 AND COUNT(*) >= 5
ORDER BY avg_score ASC;

#3. Determine if there is a correlation between delivery time and review score
WITH t AS (
  SELECT
    r.review_score,
    TIMESTAMPDIFF(SECOND,
      STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
      STR_TO_DATE(o.order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
    )/86400.0 AS delivery_days
  FROM order_review r
  JOIN orders o ON r.order_id = o.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
)
SELECT
  ROUND(
    (
      SUM((delivery_days - (SELECT AVG(delivery_days) FROM t)) * (review_score - (SELECT AVG(review_score) FROM t)))
    ) / 
    (SQRT(SUM(POWER(delivery_days - (SELECT AVG(delivery_days) FROM t), 2))) * SQRT(SUM(POWER(review_score - (SELECT AVG(review_score) FROM t), 2)))),
  4) AS pearson_corr
FROM t;

#- Find the distribution of review scores across states.
SELECT c.customer_state, r.review_score, COUNT(*) AS cnt
FROM order_review r
JOIN orders o ON r.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state, r.review_score
ORDER BY c.customer_state, r.review_score;

#● Seller & Location Analysis

#1. Count the number of sellers per state.
SELECT seller_state, COUNT(*) AS num_sellers
FROM sellers
GROUP BY seller_state
ORDER BY num_sellers DESC;


#2. Find sellers with the highest total sales revenue.
SELECT s.seller_id, s.seller_city, s.seller_state,
       ROUND(SUM(CAST(NULLIF(oi.price,'') AS DECIMAL(12,2))),2) AS total_revenue,
       COUNT(*) AS items_sold
FROM order_item oi
JOIN sellers s ON oi.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY total_revenue DESC
LIMIT 20;

#3. Identify the top 5 cities with the highest seller density.
SELECT seller_city, COUNT(*) AS sellers_count
FROM sellers
GROUP BY seller_city
ORDER BY sellers_count DESC
LIMIT 5;

#4. Match customers and sellers by ZIP code to find local transactions.
SELECT o.order_id, o.customer_id, c.customer_city, c.customer_zip_code_prefix,
       oi.seller_id, s.seller_city, s.seller_zip_code_prefix
FROM orders o
JOIN order_item oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE s.seller_zip_code_prefix = c.customer_zip_code_prefix;

#● Advanced Analytics
#1. Calculate monthly revenue growth and plot a trend line.
WITH monthly_revenue AS (
  SELECT
    DATE_FORMAT(STR_TO_DATE(o.order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'), '%Y-%m') AS month,
    SUM(CAST(NULLIF(oi.price,'') AS DECIMAL(14,2))) AS revenue
  FROM orders o
  JOIN order_item oi ON o.order_id = oi.order_id
  GROUP BY month
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month), 0), 2) AS pct_growth
FROM monthly_revenue
ORDER BY month;

#2. Analyze customer purchase frequency (one-time vs. repeat). 
WITH cust_orders AS (
  SELECT customer_id, COUNT(*) AS order_count
  FROM orders
  GROUP BY customer_id
)
SELECT
  SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time_customers,
  SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat_customers,
  COUNT(*) AS total_customers,
  ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS repeat_pct
FROM cust_orders;

#- Find the contribution percentage of each product category to overall revenue. 
WITH category_rev AS (
  SELECT p.`product category` AS category, SUM(CAST(NULLIF(oi.price,'') AS DECIMAL(14,2))) AS revenue
  FROM order_item oi
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY p.`product category`
), total_rev AS (
  SELECT SUM(revenue) AS total_revenue FROM category_rev
)
SELECT
  cr.category,
  cr.revenue,
  ROUND(100.0 * cr.revenue / tr.total_revenue, 2) AS pct_of_total
FROM category_rev cr CROSS JOIN total_rev tr
ORDER BY cr.revenue DESC;

#- Identify the top 3 sellers in each state by revenue.
WITH seller_rev AS (
  SELECT s.seller_id, s.seller_state, s.seller_city,
         SUM(CAST(NULLIF(oi.price,'') AS DECIMAL(14,2))) AS revenue
  FROM order_item oi
  JOIN sellers s ON oi.seller_id = s.seller_id
  GROUP BY s.seller_id, s.seller_state, s.seller_city
)
SELECT seller_id, seller_state, seller_city, revenue
FROM (
  SELECT sr.*,
         ROW_NUMBER() OVER (PARTITION BY seller_state ORDER BY revenue DESC) AS rn
  FROM seller_rev sr
) t
WHERE rn <= 3
ORDER BY seller_state, revenue DESC;
