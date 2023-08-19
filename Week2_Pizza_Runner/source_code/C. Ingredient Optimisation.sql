-- C. Ingredient Optimisation

-- create global temp table ##exclusions
DROP TABLE IF EXISTS ##exclusions
SELECT 
	record_id,
	CAST(TRIM(VALUE) AS INT) AS exclusions
INTO ##exclusions
FROM ##customer_orders_temp o
	CROSS APPLY STRING_SPLIT(CAST(exclusions AS varchar(20)),',')

-- create global temp table ##extras
DROP TABLE IF EXISTS ##extras
SELECT 
	record_id,
	CAST(TRIM(VALUE) AS INT) AS extras
INTO ##extras
FROM ##customer_orders_temp
	CROSS APPLY STRING_SPLIT(CAST(extras AS varchar(20)),',')

-- create global temp table ##pizza_recipes
DROP TABLE IF EXISTS ##pizza_recipes
SELECT pizza_id,
       CAST(TRIM(value) AS INT) AS topping_id
INTO   ##pizza_recipes
FROM   pizza_recipes 
CROSS  APPLY STRING_SPLIT(CAST(toppings AS varchar(20)), ',')

-- create global temp table ##clean_pizza_toppings
SELECT	p.pizza_id, p.topping_id, pt.topping_name
INTO ##clean_pizza_toppings
FROM 
     pizza_recipes1 as p
JOIN pizza_toppings as pt
     ON p.topping_id = pt.topping_id;


--1. What are the standard ingredients for each pizza?
WITH topping_cte AS (
	SELECT 
		pr.pizza_id,
		CAST(TRIM(value) AS INT) AS topping_id  
	FROM pizza_recipes pr
		CROSS APPLY STRING_SPLIT(cast(toppings as varchar(20)), ',')
)
SELECT 
	t.pizza_id,
	STRING_AGG(CAST(pt.topping_name AS VARCHAR(20)), ', ') AS topping
FROM topping_cte t
JOIN pizza_toppings pt ON t.topping_id = pt.topping_id
GROUP BY t.pizza_id

--2. What was the most commonly added extra?
SELECT TOP 1
	pt.topping_name,
	COUNT(e.extras) AS cnt_extras
FROM ##extras e
JOIN pizza_toppings pt ON pt.topping_id =  e.extras
WHERE e.extras != 0
GROUP BY pt.topping_name
ORDER BY COUNT(e.extras) DESC


--3. What was the most common exclusion?

SELECT TOP 1
	pt.topping_name,
	COUNT(e.exclusions) AS cnt_extras
FROM ##exclusions e
JOIN pizza_toppings pt ON pt.topping_id =  e.exclusions
WHERE e.exclusions != 0
GROUP BY pt.topping_name
ORDER BY COUNT(e.exclusions) DESC


--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
		--Meat Lovers
		--Meat Lovers - Exclude Beef
		--Meat Lovers - Extra Bacon
		--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH exclusions AS (
                    SELECT a.record_id,
                           STRING_AGG(t.topping_name, ', ') AS exclusions
                    FROM   ##exclusions AS a
                    JOIN   pizza_toppings AS t
                    ON     a.exclusions = t.topping_id
                    GROUP  BY a.record_id
                    ),
         extras AS ( 
                    SELECT b.record_id,
                           STRING_AGG(t.topping_name, ', ') AS extras
                    FROM   ##extras AS b
                    JOIN   pizza_toppings AS t
                    ON     b.extras = t.topping_id
                    GROUP  BY b.record_id
                    )
SELECT c.order_id,
       c.customer_id,
       c.pizza_id,
       c.exclusions,
       c.extras,
       c.order_time,
       CASE 
           WHEN c.exclusions = '0' AND c.extras = '0' THEN n.pizza_name
           WHEN c.exclusions <> '0' AND c.extras = '0' THEN CONCAT(n.pizza_name, ' - Exclude', ' ', e.exclusions)
           WHEN c.exclusions = '0' AND c.extras <> '0' THEN CONCAT(n.pizza_name, ' - Extra', ' ', x.extras)
           ELSE CONCAT(n.pizza_name, ' - Exclude', ' ', e.exclusions, ' - Extra', ' ', x.extras) 
       END AS order_item
FROM  ##customer_orders_temp AS c 
LEFT  JOIN exclusions AS e
ON    c.record_id = e.record_id
LEFT  JOIN extras AS x
ON    c.record_id = x.record_id
LEFT  JOIN  pizza_names AS n
ON    c.pizza_id = n.pizza_id

--5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
		--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
SELECT * FROM ##customer_orders_temp
SELECT * FROM ##pizza_recipes
SELECT * FROM pizza_toppings
SELECT * FROM ##extras
SELECT * FROM ##exclusions

WITH detailed_order AS (
		SELECT 
			o.order_id,
			o.pizza_id,
			o.exclusions,
			o.extras,
			pr.topping_id,
			pt.topping_name,
			o.record_id,
			CAST(TRIM(value) AS INT) AS extras_id
		FROM ##customer_orders_temp o
		JOIN ##pizza_recipes pr ON pr.pizza_id = o.pizza_id
		JOIN pizza_toppings pt ON pt.topping_id = pr.topping_id
			CROSS APPLY STRING_SPLIT(cast(o.extras as varchar(20)), ',')
),
 A AS (
		SELECT 
			order_id,
			pizza_id,
			CAST(TRIM(value) AS INT) AS exclusions_id,
			extras_id,
			topping_id,
			topping_name,
			record_id
		FROM detailed_order
			CROSS APPLY STRING_SPLIT(cast(exclusions as varchar(20)), ',')
),
B AS (SELECT 
	order_id,
	pizza_id,
	exclusions_id,
	extras_id,
	CASE WHEN exclusions_id = topping_id THEN ''
	WHEN extras_id = topping_id THEN CONCAT('2x',topping_name)
	ELSE topping_name END AS topping_name
FROM A)
SELECT
	order_id, B.pizza_id, exclusions_id, extras_id, 
	CONCAT(pn.pizza_name,': ',STRING_AGG(topping_name,', ')) as ingredients_list
FROM B
JOIN pizza_names pn ON B.pizza_id = pn.pizza_id
GROUP BY order_id, B.pizza_id, exclusions_id, extras_id,pn.pizza_name,topping_name





SELECT
	order_id,
	pizza_id,
	exclusions,
	extras,
	STRING_AGG(topping_name,',') 
FROM detailed_order
GROUP BY order_id, pizza_id, exclusions, extras


--6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH detailed_order AS (
		SELECT 
			o.order_id,
			o.pizza_id,
			o.exclusions,
			o.extras,
			pr.topping_id,
			pt.topping_name,
			o.record_id
		FROM ##customer_orders_temp o
		JOIN ##pizza_recipes pr ON pr.pizza_id = o.pizza_id
		JOIN pizza_toppings pt ON pt.topping_id = pr.topping_id
),
count_extras AS (
		SELECT 
			extras,
			COUNT(*) as extras_num
		FROM ##extras
		GROUP BY extras
),
count_exclusions AS (
		SELECT 
			exclusions,
			COUNT(*) as exclusions_num
		FROM ##exclusions
		GROUP BY exclusions
),
detailed_topping AS (
		SELECT 
			topping_id,
			topping_name,
			COUNT(topping_name) AS topping_num
		FROM detailed_order do
		GROUP BY topping_id,topping_name
)
SELECT 
	dt.topping_id,
	dt.topping_name,
	dt.topping_num AS topping_num_normal,
	CASE 
		WHEN ext.extras_num is NULL THEN 0 ELSE ext.extras_num END AS extras_num,
	CASE 
		WHEN exc.exclusions_num is NULL THEN 0 ELSE exc.exclusions_num END AS exclusions_num,
	dt.topping_num + CASE WHEN ext.extras_num is NULL THEN 0 ELSE ext.extras_num END - CASE WHEN exc.exclusions_num is NULL THEN 0 ELSE exc.exclusions_num END AS last_topping_num
FROM detailed_topping dt
LEFT JOIN count_extras ext ON ext.extras = dt.topping_id
LEFT JOIN count_exclusions exc ON exc.exclusions = dt.topping_id
ORDER BY last_topping_num DESC
