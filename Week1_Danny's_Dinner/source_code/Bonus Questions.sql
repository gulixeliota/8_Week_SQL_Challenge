--  Join All The Things
SELECT
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	CASE 
		WHEN s.order_date >= mb.join_date THEN 'Y'
		ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id


-- Rank All The Things
WITH members1 AS (
	SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		CASE 
			WHEN s.order_date >= mb.join_date THEN 'Y'
			ELSE 'N' END AS member
	FROM sales s
	JOIN menu m ON s.product_id = m.product_id
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
)
SELECT *,
	CASE 
		WHEN member = 'Y' 
		THEN RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date) END AS ranking
FROM members1
ORDER BY customer_id, order_date, product_name