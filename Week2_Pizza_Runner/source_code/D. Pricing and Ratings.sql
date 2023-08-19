-- D. Pricing and Ratings

--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT 
	SUM(CASE 
		WHEN pn.pizza_name = 'Meatlovers' THEN  12
		ELSE 10 END) AS total_earning
FROM ##customer_orders_temp o 
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id	
JOIN pizza_names pn ON pn.pizza_id = o.pizza_id
WHERE ro.pickup_time is NOT NULL	



--2. What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra

WITH detail_fee AS (
			SELECT 
				o.pizza_id,
				pn.pizza_name,
				CASE 
					WHEN pn.pizza_name = 'Meatlovers' THEN COUNT(o.pizza_id) * 12
					ELSE COUNT(o.pizza_id) * 10 END AS total_money
			FROM ##customer_orders_temp o
			JOIN pizza_names pn ON pn.pizza_id = o.pizza_id
			JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id	
			WHERE ro.pickup_time is NOT NULL
			GROUP BY o.pizza_id, pn.pizza_name
),
extras_num AS (
			SELECT 
				o.pizza_id,
				pn.pizza_name,
				COUNT(ext.extras) * 1 AS total_extras_fee
			FROM ##customer_orders_temp o
			JOIN ##extras ext ON ext.record_id = o.record_id
			JOIN pizza_names pn ON pn.pizza_id = o.pizza_id
			JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id	
			WHERE ro.pickup_time is NOT NULL AND ext.extras != '0'
			GROUP BY o.pizza_id, pn.pizza_name
)
SELECT
	SUM(total_money + total_extras_fee) AS total_earning 
FROM detail_fee df
JOIN extras_num ex ON df.pizza_id = ex.pizza_id


--3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE runner_ratings (
   order_id INT,
   rating INT,
   comment VARCHAR(160), 
   rating_date DATETIME
)

INSERT INTO runner_ratings 
VALUES (1, 5, 'perfect', '2020-01-01 20:00:00.000'),
       (2, 5, '', '2020-01-01 20:00:00.000'),
       (3, 3, 'runner got lost', '2020-01-03 02:02:00.000'),
       (4, 4, '', '2020-01-04 16:25:12.000'),
       (5, 2, 'came late and food was cold', '2020-01-08 23:03:00.000'),
       (7, 5, 'came sooner than expected', '2020-01-08 22:55:00.000'),
       (8, 4, '', '2020-01-10 01:00:00.000'),
       (10, 4, '', '2020-01-11 20:00:00.000') 


-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas
SELECT 
	o.customer_id,
	o.order_id,
	ro.runner_id,
	o.order_time,
	ro.pickup_time,
	DATEDIFF(minute,o.order_time,ro.pickup_time) AS time_between_order_and_pickup,
	duration as delivery_duration,
	ROUND(distance / (CAST(duration AS float) / 60),2) AS avg_speed,
	COUNT(ro.order_id) AS number_of_pizzas
FROM ##customer_orders_temp o
JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id
JOIN runner_ratings rr ON rr.order_id = o.order_id
GROUP BY o.customer_id, o.order_id, ro.runner_id, o.order_time, ro.pickup_time,distance, duration


--5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH finance AS (
		SELECT 
			o.order_id,
			SUM(CASE 
					WHEN pn.pizza_name = 'Meatlovers' THEN 12
					ELSE 10 END) AS pizza_price,
			distance * 0.3 AS delivery_fee
		FROM ##customer_orders_temp o 
		JOIN ##runner_orders_temp ro ON o.order_id = ro.order_id	
		JOIN pizza_names pn ON pn.pizza_id = o.pizza_id
		WHERE ro.pickup_time is NOT NULL
		GROUP BY o.order_id, distance
)	
SELECT 
	SUM(pizza_price) AS revenue,
	SUM(delivery_fee) AS delivery_cost,
	SUM(pizza_price) - SUM(delivery_fee) AS profit
FROM finance