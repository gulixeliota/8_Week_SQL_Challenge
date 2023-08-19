-- Xử lý giá trị null của cột exclusions và extras
-- Tạo global temp table và đưa các giá trị đã được xử lý từ bảng customer_orders sang bảng ##customer_orders_temp (2 dấu ## để tạo bảng tạm global)
DROP TABLE IF EXISTS ##customer_orders_temp;
SELECT
	order_id,
	customer_id,
	pizza_id,
	CASE 
			WHEN exclusions is null OR exclusions = 'null' OR exclusions = ' ' THEN '0' 
			ELSE exclusions 
			END AS exclusions,  --Remove null values in exlusions and extras columns and replace with blank space ' '.
	CASE 
			WHEN extras is null OR extras = 'null' OR extras = ' ' THEN '0' 
			ELSE extras 
			END AS extras, --Remove null values in exlusions and extras columns and replace with blank space ' '.
	order_time
INTO ##customer_orders_temp --## để tạo Global Temp Table
FROM customer_orders


--In pickup_time column, remove nulls and replace with blank space ' '.
--In distance column, remove "km" and nulls and replace with blank space ' '.
--In duration column, remove "minutes", "minute" and nulls and replace with blank space ' '.
--In cancellation column, remove NULL and null and and replace with blank space ' '.-- 
--Change data type of distance columns from varchar to float
--Change data type of duration columns from varchar to INT
DROP TABLE IF EXISTS ##runner_orders_temp;
SELECT
	order_id,
	runner_id,
	CASE 
			WHEN pickup_time = 'null' THEN NULL
			ELSE pickup_time 
			END AS pickup_time,
	CAST(CASE 
			WHEN distance  LIKE 'null' THEN NULL
			WHEN distance  LIKE '%km%' THEN TRIM('km' FROM distance)
			ELSE distance
			END AS float) AS distance,
	CAST(CASE 
			WHEN duration  LIKE 'null' THEN NULL
			WHEN duration  LIKE '%minutes%' THEN TRIM('minutes' FROM duration)
			WHEN duration  LIKE '%minute%' THEN TRIM('minute' FROM duration)
			WHEN duration  LIKE '%mins%' THEN TRIM('mins' FROM duration)
			ELSE duration
			END AS INT) AS duration,
	CASE 
			WHEN cancellation = 'null' OR cancellation IS NULL THEN NULL
			ELSE cancellation
			END AS cancellation
INTO ##runner_orders_temp
FROM runner_orders

-- change data type from ##runner_orders_temp table
ALTER TABLE ##runner_orders_temp
	ALTER COLUMN pickup_time DATETIME

ALTER TABLE ##runner_orders_temp
	ALTER COLUMN distance FLOAT

ALTER TABLE ##runner_orders_temp
	ALTER COLUMN duration INT

ALTER TABLE pizza_names
	ALTER COLUMN pizza_name VARCHAR(20)

ALTER TABLE  ##customer_orders_temp
	ADD  record_id INT IDENTITY (1,1) 

ALTER TABLE pizza_toppings
	ALTER COLUMN topping_name VARCHAR(20)



