USE olist;

-- Overall delivery KPIs (KPIs 4 and 5)
SELECT
    COUNT(*)                                                    AS delivered_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date,
                       order_purchase_timestamp)), 1)           AS avg_delivery_days,
    ROUND(100 * SUM(DATE(order_delivered_customer_date)
                    <= DATE(order_estimated_delivery_date)) / COUNT(*), 2) AS on_time_rate_pct,
    ROUND(100 * SUM(DATE(order_delivered_customer_date)
                    >  DATE(order_estimated_delivery_date)) / COUNT(*), 2) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;
  
  
  -- Monthly delivery trend, April to August 2018
  SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')              AS month,
    COUNT(*)                                                    AS delivered_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date,
                       order_purchase_timestamp)), 1)           AS avg_delivery_days,
    ROUND(100 * SUM(DATE(order_delivered_customer_date)
                    > DATE(order_estimated_delivery_date)) / COUNT(*), 2) AS late_rate_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp >= '2018-04-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY month;

-- States from fastest to slowest (Problem 3)
SELECT
    c.customer_state                                            AS state,
    COUNT(*)                                                    AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 1)         AS avg_delivery_days,
    ROUND(100 * SUM(DATE(o.order_delivered_customer_date)
                    > DATE(o.order_estimated_delivery_date)) / COUNT(*), 2) AS late_rate_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 30
ORDER BY avg_delivery_days;


-- Sellers from fastest to slowest (Problem 3)
WITH order_seller AS (
    SELECT DISTINCT order_id, seller_id
    FROM order_items
)
SELECT
    os.seller_id,
    COUNT(*)                                                    AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp)), 1)         AS avg_delivery_days,
    ROUND(100 * SUM(DATE(o.order_delivered_customer_date)
                    > DATE(o.order_estimated_delivery_date)) / COUNT(*), 2) AS late_rate_pct
FROM orders o
JOIN order_seller os ON o.order_id = os.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY os.seller_id
HAVING COUNT(*) >= 30
ORDER BY avg_delivery_days
LIMIT 10;


-- Do late deliveries lower review scores? (Problem 5)
WITH one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT
    CASE WHEN DATE(o.order_delivered_customer_date)
              <= DATE(o.order_estimated_delivery_date)
         THEN 'On time' ELSE 'Late' END                         AS delivery_status,
    COUNT(*)                                                    AS orders,
    ROUND(AVG(r.review_score), 2)                               AS avg_review_score,
    ROUND(100 * SUM(r.review_score <= 2) / COUNT(*), 2)         AS pct_bad_or_worst
FROM orders o
JOIN one_review r ON o.order_id = r.order_id AND r.rn = 1
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY delivery_status;