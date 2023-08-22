# <p align="center" style="margin-top: 0px;">🍕 Case Study #2 - Pizza Runner 🍕

<p align="left"> Using Microsoft SQL Server </p>

# Solution

- View the complete syntax [here]().

***

## B. Runner and Customer Experience

**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**

````sql
SELECT
	DATEPART(week FROM registration_date) AS week_period,
	COUNT(runner_id) AS total_runner
FROM runners
GROUP BY DATEPART(week FROM registration_date)
````

*Answer:*

| **week_period** | **total_runner** |
|-----------------|------------------|
| 1               | 1                |
| 2               | 2                |
| 3               | 1                |


***





**2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?**

````sql
SELECT 
	DISTINCT 
	ro.runner_id,
	COUNT(DISTINCT o.order_id) AS total_order,
	ROUND(AVG(CAST(DATEDIFF(minute,o.order_time,ro.pickup_time) AS Float)),2) AS minute_diff
FROM ##customer_orders_temp o 
INNER JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id 
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY ro.runner_id
````

*Answer:*

| **runner_id** | **total_order** | **minute_diff** |
|---------------|-----------------|-----------------|
| 1             | 4               | 15.67           |
| 2             | 3               | 24.2            |
| 3             | 1               | 10              |

The average time required for runner 1 to take an order is 15.67 minutes. (Total 4 orders)
The average time required for runner 2 to take an order is 24.2 minutes. (Total 3 orders)
The average time required for runner 3 to take an order is 10 minutes. (Total 1 order)

***






**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**

````sql
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
````

*Answer:*

| **number_of_pizzas** | **average_total_prep_time** | **average_prep_time_per_pizza** |
|----------------------|-----------------------------|---------------------------------|
| 1                    | 12.20                       | 12.20                           |
| 2                    | 18.50                       | 9.25                            |
| 3                    | 30.00                       | 10.00                           |

* Look at the result, we see the number of pizzas does have relationship with preparation time.
The more pizzas ordered, the longer preparation time.

***






**4. What was the average distance travelled for each customer?**

````sql
SELECT
	o.customer_id,
	ROUND(AVG(CAST(ro.distance AS float)),2) AS avg_distance(km)
FROM ##customer_orders_temp o 
INNER JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id 
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY o.customer_id
````

*Answer:*

| **customer_id** | **avg_distance(km)** |
|-----------------|----------------------|
| 101             | 20                   |
| 102             | 16.73                |
| 103             | 23.4                 |
| 104             | 10                   |
| 105             | 25                   |

***




**5. What was the difference between the longest and shortest delivery times for all orders?**

````sql
SELECT 
	MAX(duration) AS longest_delivery_time_mins,
	MIN(duration) AS shortest_delivery_time_mins,
	MAX(duration) - MIN(duration) as diff_delivery_times
FROM ##runner_orders_temp
WHERE cancellation NOT LIKE '%Cancellation%'
````

*Answer:*

| **longest_delivery_time_mins** | **shortest_delivery_time_mins** | **diff_delivery_times** |
|--------------------------------|---------------------------------|-------------------------|
| 40                             | 10                              | 30                      |

=> **30 minutes** is the difference between the longest and shortest delivery times for all orders

***






**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**

* We calculate the runners' average speed with calculation unit is km/h:

````sql
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
````

*Answer:*

| **runner_id** | **total_delivers** | **min_speed** | **max_speed** | **avg_speed** |
|---------------|--------------------|---------------|---------------|---------------|
| 1             | 4                  | 37.5          | 60            | 45.54         |
| 2             | 3                  | 35.1          | 93.6          | 62.9          |
| 3             | 1                  | 40            | 40            | 40            |

* From the result, we could see the runner_id = 3 has the lowest speed, it might because he is newbie.

* We also could see runner_id 2 is much faster than other two, we could take a look at his orders to have more insights:

````sql
SELECT 
	order_id,
	ROUND(distance/(duration/60),2) AS speed
FROM 
	new_runner_orders
WHERE runner_id = 2;
````

| **order_id** | **speed** |
|--------------|-----------|
| 4            | 35.10     |
| 7            | 60.00     |
| 8            | 93.60     |
| 9            | NULL      |

* We could see with order_id = 8, the runner 2 might violate the law with a too high speed which could bring good experience to customer but actually could harm the runner as well as the business.

***




**7. What is the successful delivery percentage for each runner?**

````sql
-- Solution 1:
SELECT runner_id,
       COUNT(order_id) AS total_orders,
       COUNT(pickup_time) AS successful_deliveries,
       CAST(COUNT(pickup_time) AS FLOAT) / CAST(COUNT(order_id) AS FLOAT) * 100 AS successful_delivery_percentage
FROM ##runner_orders_temp
GROUP BY runner_id
````

````sql
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
````

*Answer:*

| **runner_id** | **cnt_order** | **cnt_successfull_order** | **successful_delivery_percentage** |
|---------------|---------------|---------------------------|------------------------------------|
| 1             | 4             | 4                         | 100                                |
| 2             | 4             | 3                         | 75                                 |
| 3             | 2             | 1                         | 50                                 |


***

📄Next Section: [C. Ingredient Optimisation](https://github.com/gulixeliota/8_Week_SQL_Challenge/blob/main/Week2_Pizza_Runner/C.%20Ingredient%20Optimisation.md) ⏭
