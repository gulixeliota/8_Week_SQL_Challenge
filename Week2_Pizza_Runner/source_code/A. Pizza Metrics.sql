--A. Pizza Metrics
--1. How many pizzas were ordered?

SELECT 
	COUNT(order_id) AS pizza_ordered
FROM ##customer_orders_temp

--2. How many unique customer orders were made?

SELECT
	COUNT(DISTINCT order_id) AS total_unique_order
FROM ##customer_orders_temp

--3. How many successful orders were delivered by each runner?

SELECT
	runner_id,
	COUNT(DISTINCT order_id) AS total_successfull_order
FROM ##runner_orders_temp
WHERE cancellation NOT LIKE '%Cancellation%'
GROUP BY runner_id

--4. How many of each type of pizza was delivered?

SELECT 
	o.pizza_id,
	COUNT(o.pizza_id) AS total_delivered_pizza
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY o.pizza_id

--5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT 
	o.customer_id,
	n.pizza_name,
	COUNT(o.pizza_id) AS total_ordered_pizza
FROM ##customer_orders_temp o
JOIN pizza_names n ON o.pizza_id = n.pizza_id
GROUP BY o.customer_id, n.pizza_name
ORDER BY o.customer_id, n.pizza_name

--6. What was the maximum number of pizzas delivered in a single order?
SELECT
	MAX(total_delivered_pizzas) AS max_pizza_num
FROM
(SELECT 
	o.order_id,
	COUNT(o.pizza_id) AS total_delivered_pizzas
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY o.order_id) AS pizza_per_order



--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	o.customer_id,
	SUM(
		CASE 
			WHEN o.exclusions != '0' OR o.extras != '0' THEN 1
			ELSE 0 END) AS at_least_1_change,
	SUM(
		CASE 
			WHEN o.exclusions = '0' AND o.extras = '0' THEN 1
			ELSE 0 END) AS total_no_change
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY o.customer_id

--8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	SUM(
		CASE 
			WHEN o.exclusions != '0' AND o.extras != '0' THEN 1
			ELSE 0 END) AS total_both_change
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
WHERE ro.cancellation NOT LIKE '%Cancellation%'


--9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	CONCAT(DATEPART(hour FROM order_time),' - ',DATEPART(hour FROM order_time) + 1) AS hour_of_day,
	COUNT(order_id) AS total_pizza_volumn
FROM ##customer_orders_temp
GROUP BY DATEPART(hour FROM order_time)
ORDER BY DATEPART(hour FROM order_time)


--10. What was the volume of orders for each day of the week?
SELECT 
	DATEPART(weekday FROM order_time) as weekday,
	DATENAME(weekday,order_time) as weekday_name,
	COUNT(order_id) AS total_pizza_volumn,
	ROUND(100.0 * CAST(COUNT(order_id) AS FLOAT) / SUM(COUNT(order_id)) OVER(),2) AS percentage_ordered_pizza
FROM ##customer_orders_temp
GROUP BY DATEPART(weekday FROM order_time), DATENAME(weekday,order_time)
ORDER BY DATEPART(weekday FROM order_time)
