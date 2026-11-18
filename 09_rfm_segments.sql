WITH rfm_base AS (
    SELECT c.customer_unique_id,
           MAX(o.order_purchase_timestamp) AS last_purchase,
           COUNT(DISTINCT o.order_id) AS frequency,
           SUM(oi.price) AS monetary
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scored AS (
    SELECT customer_unique_id,
           (SELECT MAX(order_purchase_timestamp) FROM orders)::date - last_purchase::date AS recency_days,
           frequency,
           monetary,
           NTILE(5) OVER (ORDER BY last_purchase) AS r_score,
           NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
),
segmented AS (
    SELECT *,
           CASE
               WHEN frequency >= 2 AND r_score >= 3 THEN 'Active repeat buyers'
               WHEN r_score >= 4 AND m_score >= 4 THEN 'New high spenders'
               WHEN r_score >= 4 THEN 'Recent low spenders'
               WHEN r_score <= 2 AND m_score >= 4 THEN 'At-risk high spenders'
               WHEN r_score <= 2 THEN 'Lost'
               ELSE 'Mid-tier'
           END AS segment
    FROM rfm_scored
)
SELECT segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
       ROUND(AVG(monetary), 2) AS avg_spend,
       ROUND(AVG(recency_days)) AS avg_days_since_last_order
FROM segmented
GROUP BY segment
ORDER BY customers DESC;