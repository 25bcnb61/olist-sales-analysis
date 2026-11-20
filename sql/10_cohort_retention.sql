WITH first_orders AS (
    SELECT c.customer_unique_id,
           DATE_TRUNC('month', MIN(o.order_purchase_timestamp)) AS cohort_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
activity AS (
    SELECT DISTINCT c.customer_unique_id,
           DATE_TRUNC('month', o.order_purchase_timestamp) AS order_month
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
),
cohort_data AS (
    SELECT f.cohort_month,
           ((EXTRACT(YEAR FROM a.order_month) - EXTRACT(YEAR FROM f.cohort_month)) * 12
            + (EXTRACT(MONTH FROM a.order_month) - EXTRACT(MONTH FROM f.cohort_month)))::int AS month_number,
           COUNT(DISTINCT a.customer_unique_id) AS customers
    FROM first_orders f
    JOIN activity a ON f.customer_unique_id = a.customer_unique_id
    GROUP BY 1, 2
)
SELECT cohort_month::date AS cohort,
       month_number,
       customers,
       ROUND(100.0 * customers / FIRST_VALUE(customers) OVER (PARTITION BY cohort_month ORDER BY month_number), 2) AS retention_pct
FROM cohort_data
WHERE cohort_month >= '2017-01-01'
  AND month_number <= 6
ORDER BY cohort_month, month_number;