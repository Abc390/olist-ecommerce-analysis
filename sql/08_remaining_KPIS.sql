-- Query 1: Cancellation rate (KPI 6)
SELECT
    COUNT(*)                                              AS total_orders,
    SUM(order_status = 'canceled')                        AS canceled_orders,
    ROUND(100 * SUM(order_status = 'canceled') / COUNT(*), 2) AS cancellation_rate_pct
FROM orders;

-- Query 2: Cancellation rate by month, Apr to Aug 2018
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')        AS month,
    COUNT(*)                                              AS total_orders,
    SUM(order_status = 'canceled')                        AS canceled_orders,
    ROUND(100 * SUM(order_status = 'canceled') / COUNT(*), 2) AS cancellation_rate_pct
FROM orders
WHERE order_purchase_timestamp >= '2018-04-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY month;

-- Query 3: Active sellers (KPI 13)
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')      AS month,
    COUNT(DISTINCT oi.seller_id)                          AS active_sellers
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY month;

SELECT COUNT(DISTINCT oi.seller_id) AS active_sellers_apr_aug_2018
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01';
  
--  Query 4: Payment mix (KPI 14)
SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id)                            AS orders,
    ROUND(SUM(p.payment_value), 2)                        AS payment_value,
    ROUND(100 * SUM(p.payment_value)
          / SUM(SUM(p.payment_value)) OVER (), 2)         AS pct_of_payment_value
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2018-04-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY p.payment_type
ORDER BY payment_value DESC;
