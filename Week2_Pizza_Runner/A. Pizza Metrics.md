# <p align="center" style="margin-top: 0px;">🍕 Case Study #2 - Pizza Runner 🍕


## Solution

- I use ***SQL SERVER*** to do this project
- View the complete syntax [here]().

***

## A. Pizza Metrics

**1. How many pizzas were ordered?**

````sql
SELECT 
	COUNT(order_id) AS pizza_ordered
FROM ##customer_orders_temp
````

#### Answer:

| **pizza_ordered** |
|-------------------|
| 14                |


***





**2. How many unique customer orders were made?**


````sql
SELECT
	COUNT(DISTINCT order_id) AS total_unique_order
FROM ##customer_orders_temp
````

#### Answer:

| **total_unique_order** |
|------------------------|
| 10                     |



***




**3. How many successful orders were delivered by each runner?**


````sql
SELECT
	runner_id,
	COUNT(DISTINCT order_id) AS total_successfull_order
FROM ##runner_orders_temp
WHERE cancellation NOT LIKE '%Cancellation%'
GROUP BY runner_id
````

#### Answer:

| **runner_id** | **total_successfull_order** |
|---------------|-----------------------------|
| 1             | 4                           |
| 2             | 3                           |
| 3             | 1                           |



***




**4. How many of each type of pizza was delivered?**


````sql
SELECT 
	o.pizza_id,
	COUNT(o.pizza_id) AS total_delivered_pizza
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
WHERE ro.cancellation NOT LIKE '%Cancellation%'
GROUP BY o.pizza_id
````

#### Answer:

| **pizza_id** | **total_delivered_pizza** |
|--------------|---------------------------|
| 1            | 9                         |
| 2            | 3                         |



***

**5. How many Vegetarian and Meatlovers were ordered by each customer?**



````sql
SELECT 
	o.customer_id,
	n.pizza_name,
	COUNT(o.pizza_id) AS total_ordered_pizza
FROM ##customer_orders_temp o
JOIN pizza_names n ON o.pizza_id = n.pizza_id
GROUP BY o.customer_id, n.pizza_name
ORDER BY o.customer_id, n.pizza_name
````

#### Answer:

| **customer_id** | **pizza_name** | **total_ordered_pizza** |
|-----------------|----------------|-------------------------|
| 101             | Meatlovers     | 2                       |
| 101             | Vegetarian     | 1                       |
| 102             | Meatlovers     | 2                       |
| 102             | Vegetarian     | 1                       |
| 103             | Meatlovers     | 3                       |
| 103             | Vegetarian     | 1                       |
| 104             | Meatlovers     | 3                       |
| 105             | Vegetarian     | 1                       |



***









**6. What was the maximum number of pizzas delivered in a single order?**



````sql
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
````

#### Answer:

| **max_pizza_num** |
|-------------------|
| 3                 |



***









**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**


````sql
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
````

#### Answer:

| **customer_id** | **at_least_1_change** | **total_no_change** |
|-----------------|-----------------------|---------------------|
| 101             | 0                     | 2                   |
| 102             | 0                     | 3                   |
| 103             | 3                     | 0                   |
| 104             | 2                     | 1                   |
| 105             | 1                     | 0                   |



***








**8. How many pizzas were delivered that had both exclusions and extras?**


````sql
SELECT
	SUM(
		CASE 
			WHEN o.exclusions != '0' AND o.extras != '0' THEN 1
			ELSE 0 END) AS total_both_change
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
WHERE ro.cancellation NOT LIKE '%Cancellation%'
````

#### Answer:

| **total_both_change** |
|-----------------------|
| 1                     |


***










**9. What was the total volume of pizzas ordered for each hour of the day?**



````sql
SELECT 
	CONCAT(DATEPART(hour FROM order_time),' - ',DATEPART(hour FROM order_time) + 1) AS hour_of_day,
	COUNT(order_id) AS total_pizza_volumn
FROM ##customer_orders_temp
GROUP BY DATEPART(hour FROM order_time)
ORDER BY DATEPART(hour FROM order_time)
````

#### Answer:

| **hour_of_day** | **total_pizza_volumn** |
|-----------------|------------------------|
| 11 - 12         | 1                      |
| 13 - 14         | 3                      |
| 18 - 19         | 3                      |
| 19 - 20         | 1                      |
| 21 - 22         | 3                      |
| 23 - 24         | 3                      |


***









**10. What was the volume of orders for each day of the week?**



````sql
SELECT 
	DATEPART(weekday FROM order_time) as weekday,
	DATENAME(weekday,order_time) as weekday_name,
	COUNT(order_id) AS total_pizza_volumn,
	ROUND(100.0 * CAST(COUNT(order_id) AS FLOAT) / SUM(COUNT(order_id)) OVER(),2) AS percentage_ordered_pizza
FROM ##customer_orders_temp
GROUP BY DATEPART(weekday FROM order_time), DATENAME(weekday,order_time)
ORDER BY DATEPART(weekday FROM order_time)
````

#### Answer:

| **weekday** | **weekday_name** | **total_pizza_volumn** | **percentage_ordered_pizza** |
|-------------|------------------|------------------------|------------------------------|
| 4           | Wednesday        | 5                      | 35.71                        |
| 5           | Thursday         | 3                      | 21.43                        |
| 6           | Friday           | 1                      | 7.14                         |
| 7           | Saturday         | 5                      | 35.71                        |


***