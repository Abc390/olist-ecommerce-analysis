USE olist;
DROP TABLE IF EXISTS order_summary;

CREATE TABLE order_summary AS
WITH item_totals AS (
    SELECT order_id,
           COUNT(*)                   AS n_items,
           SUM(price + freight_value) AS revenue
    FROM order_items
    GROUP BY order_id
),
one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    DATE(o.order_purchase_timestamp)                        AS purchase_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')        AS purchase_month,
    CASE WHEN o.order_status IN ('canceled', 'unavailable')
         THEN 0 ELSE 1 END                                  AS is_valid,
    it.n_items,
    ROUND(it.revenue, 2)                                    AS revenue,
    CASE WHEN o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
          AND o.order_estimated_delivery_date IS NOT NULL
         THEN DATEDIFF(o.order_delivered_customer_date,
                       o.order_purchase_timestamp) END      AS delivery_days,
    CASE WHEN o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
          AND o.order_estimated_delivery_date IS NOT NULL
         THEN CASE WHEN DATE(o.order_delivered_customer_date)
                        > DATE(o.order_estimated_delivery_date)
                   THEN 1 ELSE 0 END END                    AS is_late,
    r.review_score
FROM orders o
JOIN customers c        ON o.customer_id = c.customer_id
LEFT JOIN item_totals it ON o.order_id = it.order_id
LEFT JOIN one_review r   ON o.order_id = r.order_id AND r.rn = 1;

SELECT COUNT(*) AS rows_in_table, COUNT(DISTINCT order_id) AS distinct_orders
FROM order_summary;

SELECT COUNT(*) AS total_orders, ROUND(SUM(revenue), 2) AS revenue
FROM order_summary
WHERE is_valid = 1
  AND revenue IS NOT NULL
  AND purchase_date >= '2018-04-01' AND purchase_date < '2018-09-01';
  
  
  DROP TABLE IF EXISTS item_summary;

CREATE TABLE item_summary AS
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    s.seller_state,
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')            AS category,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')        AS purchase_month,
    c.customer_state,
    o.order_status,
    CASE WHEN o.order_status IN ('canceled', 'unavailable')
         THEN 0 ELSE 1 END                                  AS is_valid,
    oi.price,
    oi.freight_value,
    ROUND(oi.price + oi.freight_value, 2)                   AS revenue
FROM order_items oi
JOIN orders o    ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p  ON oi.product_id = p.product_id
JOIN sellers s   ON oi.seller_id = s.seller_id
LEFT JOIN product_category_name_translation t
                 ON p.product_category_name = t.product_category_name;
  
  SELECT COUNT(*) AS rows_in_table FROM item_summary;
  
  