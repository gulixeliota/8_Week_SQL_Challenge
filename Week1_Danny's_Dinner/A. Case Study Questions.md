# <p align="center" style="margin-top: 0px;">🍜 Case Study #1 - Danny's Diner 🍜


## Solution

I use ***SQL SERVER*** to do this project
View the complete syntax [here](https://github.com/gulixeliota/8_Week_SQL_Challenge/blob/main/Week1_Danny's_Dinner/source_code/Solutions.sql).

***

**1. What is the total amount each customer spent at the restaurant?**

````sql
SELECT 
	s.customer_id,
	SUM(price) as total_spent
FROM sales s
JOIN menu m ON s.product_id = m.product_id 
GROUP BY s.customer_id
````

#### Answer:
| customer_id | total_spent |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

***





**2. How many days has each customer visited the restaurant?**

````sql
SELECT
	customer_id,
	COUNT(DISTINCT order_date) AS visited_days
FROM sales 
GROUP BY customer_id
````

#### Answer:
| customer_id | visited_days |
|-------------|--------------|
| A           | 4            |
| B           | 6            |
| C           | 2            |

- Customer A visited 4 times.
- Customer B visited 6 times.
- Customer C visited 2 times.

***





**3. What was the first item from the menu purchased by each customer?**

````sql
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
	JOIN sales s ON m.product_id = s.product_id) AS rank_date
WHERE rnk = 1
````

#### Answer:
| customer_id | product_name | order_date |
|-------------|--------------|------------|
| A           | curry        | 2021-01-01 |
| A           | sushi        | 2021-01-01 |
| B           | curry        | 2021-01-01 |
| C           | ramen        | 2021-01-01 |


- Customer A placed an order for both curry and sushi simultaneously, making them the first items in the order.
- Customer B's first order is curry.
- Customer C's first order is ramen.

***





**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

````sql
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
		GROUP BY m.product_id,m.product_name) AS cnt_quantity) AS rank_quantity
WHERE rnk = 1
````

#### Answer:
| product_id | product_name | total_purchase_quantity |
|------------|--------------|-------------------------|
| 3          | ramen        | 8                       |


- Most purchased item on the menu is ramen 🍜 which is 8 times. 

***






**5. Which item was the most popular for each customer?**

````sql
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
		GROUP BY s.customer_id, m.product_id) AS cnt_quantity) AS rank_quantity
JOIN menu m1 ON sub2.product_id = m1.product_id
WHERE rnk = 1
````

*Each user may have more than 1 favourite item.*

#### Answer:

| customer_id | product_name | total_purchased_quantity |
|-------------|--------------|--------------------------|
| A           | ramen        | 3                        |
| B           | curry        | 2                        |
| B           | sushi        | 2                        |
| B           | ramen        | 2                        |
| C           | ramen        | 3                        |

- Customer A and C's favourite item is ramen.
- Customer B enjoys all items on the menu. He/she is a true foodie.

***






**6. Which item was purchased first by the customer after they became a member?**

```sql
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
```

#### Answer:
| customer_id | join_date  | order_date | product_id | product_name |
|-------------|------------|------------|------------|--------------|
| A           | 2021-01-07 | 2021-01-07 | 2          | curry        |
| B           | 2021-01-09 | 2021-01-11 | 1          | sushi        |

- Customer A's first order as a member is curry.
- Customer B's first order as a member is sushi.

***

**7. Which item was purchased just before the customer became a member?**

````sql
WITH CTE AS (
	SELECT 
		s.customer_id,
		mb.join_date,
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
	join_date,
	order_date,
	CTE2.product_id,
	m.product_name
FROM CTE2
JOIN menu m ON m.product_id = CTE2.product_id
WHERE rnk = 1
````

#### Answer:
| customer_id | join_date  | order_date | product_id | product_name |
|-------------|------------|------------|------------|--------------|
| A           | 2021-01-07 | 2021-01-01 | 1          | sushi        |
| A           | 2021-01-07 | 2021-01-01 | 2          | curry        |
| B           | 2021-01-09 | 2021-01-04 | 1          | sushi        |
| C           | NULL       | 2021-01-07 | 3          | ramen        |

Before becoming members:
- Customer A placed an order for both curry and sushi simultaneously
- Customer B's last order is curry.
- Customer C's last order is ramen. This is C's latest order because C is not a member yet

***

**8. What is the total items and amount spent for each member before they became a member?**

```sql
WITH price_detailed_table AS (
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
FROM price_detailed_table
GROUP BY customer_id
```

#### Answer:
| customer_id | total_items | total_amount |
|-------------|-------------|--------------|
| A           | 2           | 25           |
| B           | 3           | 40           |
| C           | 3           | 36           |


Before becoming members,
- Customer A spent $25 on 2 items.
- Customer B spent $40 on 3 items.
- Customer C has not yet joined as a member. So 36$ for 3 items is all he has used up to now

***

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?**

```sql
SELECT 
	s.customer_id,
	SUM(CASE WHEN m.product_name != 'Sushi' THEN m.price*10
	ELSE m.price*20 END) AS total_points
FROM sales s
JOIN menu m ON m.product_id = s.product_id
GROUP BY s.customer_id

```


#### Answer:
| customer_id | total_points |
|-------------|--------------|
| A           | 860          |
| B           | 940          |
| C           | 360          |

- Total points for Customer A is $860.
- Total points for Customer B is $940.
- Total points for Customer C is $360.

***

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?**

```sql
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
```

#### Answer:
| customer_id | total_points_at_the_end_of_January |
|-------------|------------------------------------|
| A           | 1370                               |
| B           | 940                                |


- Total points for Customer A is 1370.
- Total points for Customer B is 940.

***
