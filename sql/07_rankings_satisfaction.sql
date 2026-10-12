USE olist;

-- Query 1: Top 10 products by units sold (R2)
SELECT
    oi.product_id,
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')          AS category,
    COUNT(*)                                               AS units_sold,
    ROUND(SUM(oi.price + oi.freight_value), 2)             AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
                    ON p.product_category_name = t.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY oi.product_id, category
ORDER BY units_sold DESC, revenue DESC
LIMIT 10;


-- Query 2: Top 10 sellers by revenue (R3)
SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(*)                                               AS units_sold,
    COUNT(DISTINCT o.order_id)                             AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)             AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s      ON oi.seller_id = s.seller_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY oi.seller_id, s.seller_state
ORDER BY revenue DESC
LIMIT 10;

-- Query 3: States by revenue (R4)
SELECT
    c.customer_state                                       AS state,
    COUNT(DISTINCT o.order_id)                             AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)             AS revenue,
    ROUND(100 * SUM(oi.price + oi.freight_value)
          / SUM(SUM(oi.price + oi.freight_value)) OVER (), 2) AS pct_of_revenue
FROM orders o
JOIN customers c    ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- Query 4: Satisfaction by state (R6)
WITH one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
)
SELECT
    c.customer_state                                       AS state,
    COUNT(*)                                               AS reviewed_orders,
    ROUND(AVG(r.review_score), 2)                          AS avg_review_score,
    ROUND(100 * SUM(r.review_score <= 2) / COUNT(*), 2)    AS pct_bad_or_worst
FROM orders o
JOIN customers c  ON o.customer_id = c.customer_id
JOIN one_review r ON o.order_id = r.order_id AND r.rn = 1
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_state
HAVING COUNT(*) >= 30
ORDER BY avg_review_score;

-- Query 5: The 10 least satisfying categories (R6)
WITH one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
),
order_cat AS (
    SELECT DISTINCT oi.order_id,
           COALESCE(t.product_category_name_english,
                    p.product_category_name, 'unknown')    AS category
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
                    ON p.product_category_name = t.product_category_name
)
SELECT
    oc.category,
    COUNT(*)                                               AS reviewed_orders,
    ROUND(AVG(r.review_score), 2)                          AS avg_review_score,
    ROUND(100 * SUM(r.review_score <= 2) / COUNT(*), 2)    AS pct_bad_or_worst
FROM order_cat oc
JOIN orders o     ON oc.order_id = o.order_id
JOIN one_review r ON oc.order_id = r.order_id AND r.rn = 1
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY oc.category
HAVING COUNT(*) >= 30
ORDER BY avg_review_score ASC
LIMIT 10;

-- Query 6: The 10 least satisfying sellers (R6)
WITH one_review AS (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (PARTITION BY order_id
                              ORDER BY review_answer_timestamp DESC) AS rn
    FROM order_reviews
),
order_seller AS (
    SELECT DISTINCT order_id, seller_id
    FROM order_items
)
SELECT
    os.seller_id,
    COUNT(*)                                               AS reviewed_orders,
    ROUND(AVG(r.review_score), 2)                          AS avg_review_score,
    ROUND(100 * SUM(r.review_score <= 2) / COUNT(*), 2)    AS pct_bad_or_worst
FROM order_seller os
JOIN orders o     ON os.order_id = o.order_id
JOIN one_review r ON os.order_id = r.order_id AND r.rn = 1
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY os.seller_id
HAVING COUNT(*) >= 30
ORDER BY avg_review_score ASC
LIMIT 10;
