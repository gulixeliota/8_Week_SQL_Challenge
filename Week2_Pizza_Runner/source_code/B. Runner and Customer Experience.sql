-- B. Runner and Customer Experience

--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
	DATEPART(week FROM registration_date) AS week_period,
	COUNT(runner_id) AS total_runner
FROM runners
GROUP BY DATEPART(week FROM registration_date)

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
	DISTINCT 
	ro.runner_id,
	COUNT(DISTINCT o.order_id) AS total_order,
	ROUND(AVG(CAST(DATEDIFF(minute,o.order_time,ro.pickup_time) AS Float)),2) AS minute_diff
FROM ##customer_orders_temp o 
INNER JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id 
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY ro.runner_id



--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH pre_time_by_order AS (
	SELECT 
		o.order_id,
		COUNT(o.pizza_id) as number_of_pizzas,
		ROUND(AVG(CAST(DATEDIFF(minute,o.order_time,ro.pickup_time) AS Float)),2) AS avg_time
	FROM ##customer_orders_temp o 
	INNER JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id 
	WHERE ro.cancellation NOT LIKE '%Cancellation%'
	GROUP BY o.order_id, o.order_time, ro.pickup_time
)

SELECT 
	number_of_pizzas,
	CAST(AVG(avg_time) AS decimal(4,2)) AS average_total_prep_time,
	CAST(AVG(avg_time) / number_of_pizzas AS decimal(4,2)) AS average_prep_time_per_pizza
FROM pre_time_by_order
GROUP BY number_of_pizzas

--4. What was the average distance travelled for each customer?

SELECT
	o.customer_id,
	ROUND(AVG(CAST(ro.distance AS float)),2) AS avg_distance(km)
FROM ##customer_orders_temp o 
INNER JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id 
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY o.customer_id

--5. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
	MAX(duration) AS longest_delivery_time_mins,
	MIN(duration) AS shortest_delivery_time_mins,
	MAX(duration) - MIN(duration) as diff_delivery_times
FROM ##runner_orders_temp
WHERE cancellation NOT LIKE '%Cancellation%'

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
	runner_id,
	COUNT(order_id) AS total_delivers,
	ROUND(MIN(distance / CAST(duration AS FLOAT) * 60),2) AS min_speed,
	ROUND(MAX(distance / CAST(duration AS FLOAT) * 60),2) AS max_speed,
	ROUND(AVG(distance / CAST(duration AS FLOAT) * 60),2) AS avg_speed
FROM ##runner_orders_temp
WHERE cancellation NOT LIKE '%Cancellation%'
GROUP BY runner_id
ORDER BY runner_id

-- find speed per order_id of runner 2 
SELECT 
	order_id,
	ROUND(distance/(CAST(duration as float)/60),2) AS speed
FROM 
	##runner_orders_temp
WHERE runner_id = 2;

--7. What is the successful delivery percentage for each runner?
-- Solution 1:
SELECT runner_id,
       COUNT(order_id) AS total_orders,
       COUNT(pickup_time) AS successful_deliveries,
       CAST(COUNT(pickup_time) AS FLOAT) / CAST(COUNT(order_id) AS FLOAT) * 100 AS successful_delivery_percentage
FROM ##runner_orders_temp
GROUP BY runner_id



-- Solution 2:
WITH total_successfull_delivey AS ( 
	SELECT 
		runner_id,
		COUNT(DISTINCT order_id) as cnt_successfull_order
	FROM ##runner_orders_temp
	WHERE cancellation NOT LIKE '%Cancellation%'
	GROUP BY runner_id
),
total_delivery AS (
	SELECT 
		runner_id,
		COUNT(DISTINCT order_id) as cnt_order
	FROM ##runner_orders_temp
	GROUP BY runner_id
)

SELECT 
	t.runner_id,
	cnt_order,
	cnt_successfull_order,
	CAST(cnt_successfull_order AS float) * 100 / CAST(cnt_order AS float) AS successful_delivery_percentage
FROM total_delivery t
JOIN total_successfull_delivey s ON t.runner_id = s.runner_id

