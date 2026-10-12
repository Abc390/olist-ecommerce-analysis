USE olist;
SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')            AS category,
    COUNT(*)                                                 AS units_sold,
    COUNT(DISTINCT o.order_id)                               AS orders,
    ROUND(SUM(oi.price + oi.freight_value), 2)               AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
                    ON p.product_category_name = t.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY category
ORDER BY revenue DESC;







SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')            AS category,
    COUNT(*)                                                 AS units_sold,
    ROUND(SUM(oi.price + oi.freight_value), 2)               AS revenue,
    ROUND(100 * SUM(oi.price + oi.freight_value)
          / SUM(SUM(oi.price + oi.freight_value)) OVER (), 2) AS pct_of_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
                    ON p.product_category_name = t.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY category
ORDER BY revenue DESC
LIMIT 10;


SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')            AS category,
    ROUND(SUM(CASE WHEN MONTH(o.order_purchase_timestamp) = 4
              THEN oi.price + oi.freight_value ELSE 0 END), 0) AS apr,
    ROUND(SUM(CASE WHEN MONTH(o.order_purchase_timestamp) = 5
              THEN oi.price + oi.freight_value ELSE 0 END), 0) AS may,
    ROUND(SUM(CASE WHEN MONTH(o.order_purchase_timestamp) = 6
              THEN oi.price + oi.freight_value ELSE 0 END), 0) AS jun,
    ROUND(SUM(CASE WHEN MONTH(o.order_purchase_timestamp) = 7
              THEN oi.price + oi.freight_value ELSE 0 END), 0) AS jul,
    ROUND(SUM(CASE WHEN MONTH(o.order_purchase_timestamp) = 8
              THEN oi.price + oi.freight_value ELSE 0 END), 0) AS aug,
    ROUND(SUM(oi.price + oi.freight_value), 0)               AS total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t
                    ON p.product_category_name = t.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY category
ORDER BY total DESC
LIMIT 10;


