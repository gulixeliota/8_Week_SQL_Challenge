# <p align="center" style="margin-top: 0px;">🍜 Case Study #1 - Danny's Diner 🍜

<p align="left"> Using Microsoft SQL Server </p>

# Solution

- View the complete syntax [here](https://github.com/gulixeliota/8_Week_SQL_Challenge/blob/main/Week1_Danny's_Dinner/source_code/Bonus%20Questions.sql).

***

## B. Runner and Customer Experience


**1. Join All The Things**
Create basic data tables that his team can use to quickly derive insights without needing to join the underlying tables using SQL.

```sql
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
```

**Answer:**

| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |


***


**2. Rank All The Things**

- Rank orders by order_date after becoming a member. 
- Orders before becoming a member will be NULL


```sql
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
```

**Answer:**

| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL

***

📄Back to Overview: [Case Study #1: Danny's Diner](https://github.com/gulixeliota/8_Week_SQL_Challenge/blob/main/Week1_Danny's_Dinner/README.md) ⏭

📄Next Challenge: [Week 2: Pizza Runner](https://github.com/gulixeliota/8_Week_SQL_Challenge/tree/main/Week2_Pizza_Runner) ⏭