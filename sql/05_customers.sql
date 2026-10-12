USE olist;

-- Repeat Rate and one time buyers (KPIs 7 and 8)
WITH cust AS (
    SELECT c.customer_unique_id,
           COUNT(DISTINCT o.order_id) AS n_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                      AS unique_customers,
    SUM(n_orders = 1)                             AS one_time_customers,
    SUM(n_orders >= 2)                            AS repeat_customers,
    ROUND(100 * SUM(n_orders >= 2) / COUNT(*), 2) AS repeat_rate_pct,
    ROUND(100 * SUM(n_orders = 1)  / COUNT(*), 2) AS one_time_rate_pct
FROM cust;

-- New vs returning customers per month (KPI 9)
WITH first_order AS (
    SELECT c.customer_unique_id,
           MIN(o.order_purchase_timestamp) AS first_purchase
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY c.customer_unique_id
),
monthly AS (
    SELECT DISTINCT c.customer_unique_id,
           DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND o.order_purchase_timestamp >= '2018-04-01'
      AND o.order_purchase_timestamp <  '2018-09-01'
)
SELECT
    m.month,
    COUNT(*)                                                         AS active_customers,
    SUM(DATE_FORMAT(f.first_purchase, '%Y-%m') =  m.month)           AS new_customers,
    SUM(DATE_FORMAT(f.first_purchase, '%Y-%m') <> m.month)           AS returning_customers,
    ROUND(100 * SUM(DATE_FORMAT(f.first_purchase, '%Y-%m') = m.month)
          / COUNT(*), 2)                                             AS new_customer_rate_pct
FROM monthly m
JOIN first_order f ON m.customer_unique_id = f.customer_unique_id
GROUP BY m.month
ORDER BY m.month;

-- Review buckets, best to worst (KPI 12)
WITH one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT
    CASE r.review_score
        WHEN 5 THEN '5 Best'
        WHEN 4 THEN '4 Good'
        WHEN 3 THEN '3 Neutral'
        WHEN 2 THEN '2 Bad'
        ELSE        '1 Worst'
    END                                           AS bucket,
    COUNT(*)                                      AS orders,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM one_review r
JOIN orders o ON r.order_id = o.order_id
WHERE r.rn = 1
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY bucket
ORDER BY bucket DESC;

-- Average review score (KPI 10)
WITH one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT ROUND(AVG(r.review_score), 2) AS avg_review_score,
       COUNT(*)                      AS reviewed_orders
FROM one_review r
JOIN orders o ON r.order_id = o.order_id
WHERE r.rn = 1
  AND o.order_status NOT IN ('canceled', 'unavailable');
  
  
  
  