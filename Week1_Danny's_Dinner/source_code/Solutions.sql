-- Solved on SQL SERVER by Cao Minh Duc, August, 13, 2023
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id,
	SUM(price) as total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id 
GROUP BY s.customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
	COUNT(DISTINCT order_date) AS visited_days
FROM sales 
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
SELECT 
	DISTINCT customer_id,
	product_name,
	order_date
FROM
	(SELECT
		s.customer_id,
		m.product_name,
		s.order_date,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
	FROM menu m
	JOIN sales s ON m.product_id = s.product_id) AS sub
WHERE rnk = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	product_id,
	product_name,
	total_purchased_quantity
FROM
	(SELECT 
		*,
		RANK() OVER(ORDER BY total_purchased_quantity DESC) AS rnk
	FROM
		(SELECT
			m.product_id,
			m.product_name,
			COUNT(order_date) AS total_purchased_quantity
		FROM menu m
		JOIN sales s ON m.product_id = s.product_id
		GROUP BY m.product_id,m.product_name) AS sub1) AS sub2
WHERE rnk = 1

-- 5. Which item was the most popular for each customer?
SELECT
	customer_id,
	m1.product_name,
	total_purchased_quantity
FROM
	(SELECT
		*,
		RANK() OVER(PARTITION BY customer_id ORDER BY total_purchased_times DESC) AS rnk
	FROM
		(SELECT
			s.customer_id,
			m.product_id,
			COUNT(*) AS total_purchased_quantity
		FROM menu m
		JOIN sales s ON m.product_id = s.product_id
		GROUP BY s.customer_id, m.product_id) AS sub1) AS sub2
JOIN menu m1 ON sub2.product_id = m1.product_id
WHERE rnk = 1


-- 6. Which item was purchased first by the customer after they became a member?
--Note: In this question, the orders made during the join date are counted within the first order as well
WITH CTE AS (
	SELECT 
		s.customer_id,
		mb.join_date,
		s.order_date,
		s.product_id
	FROM sales s
	JOIN members mb ON s.customer_id = mb.customer_id
	AND s.order_date >= mb.join_date
	),
CTE2 AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk
	FROM CTE)
SELECT 
	customer_id,
	join_date,
	order_date,
	CTE2.product_id,
	m.product_name
FROM CTE2
JOIN menu m ON m.product_id = CTE2.product_id
WHERE rnk = 1

-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS (
	SELECT 
		s.customer_id,
		s.order_date,
		s.product_id
	FROM sales s
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date OR mb.join_date is null
	),
CTE2 AS (
	SELECT
		*,
		RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rnk
	FROM CTE)
SELECT 
	customer_id,
	order_date,
	CTE2.product_id,
	m.product_name
FROM CTE2
JOIN menu m ON m.product_id = CTE2.product_id
WHERE rnk = 1

-- 8. What is the total items and amount spent for each member before they became a member?
WITH CTE AS (
	SELECT 
		s.customer_id,
		s.order_date,
		s.product_id,
		m.price
	FROM sales s
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
	JOIN menu m ON m.product_id = s.product_id
	WHERE s.order_date < mb.join_date OR mb.join_date is NULL
	)
SELECT
	customer_id,
	COUNT(product_id) AS total_items,
	SUM(price) AS total_amount
FROM CTE
GROUP BY customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
	s.customer_id,
	SUM(CASE WHEN m.product_name != 'Sushi' THEN m.price*10
	ELSE m.price*20 END) AS total_points
FROM sales s
JOIN menu m ON m.product_id = s.product_id
GROUP BY s.customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH CTE AS (
	SELECT 
		s.customer_id,
		m.product_name,
		s.order_date,
		mb.join_date,
		DATEADD(day,7,mb.join_date) AS first_week_after_joining_program,
		m.price,
		CASE 
			WHEN m.product_name = 'Sushi' OR s.order_date BETWEEN mb.join_date AND DATEADD(day,7,mb.join_date) THEN m.price*20
			ELSE m.price*10 END as total_points
	FROM sales s
	JOIN menu m ON m.product_id = s.product_id
	JOIN members mb ON mb.customer_id = s.customer_id)

SELECT 
	customer_id,
	SUM(total_points) as total_points_at_the_end_of_January
FROM CTE
WHERE DATEPART(month,order_date) = 01 
	AND customer_id IN ('A','B')
GROUP BY customer_id


