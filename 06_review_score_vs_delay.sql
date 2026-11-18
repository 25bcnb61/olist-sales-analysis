SELECT CASE
         WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN '1. On time or early'
         WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date + INTERVAL '3 days' THEN '2. Up to 3 days late'
         WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date + INTERVAL '7 days' THEN '3. 4-7 days late'
         ELSE '4. More than 7 days late'
       END AS delivery_status,
       COUNT(*) AS reviews,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 1;