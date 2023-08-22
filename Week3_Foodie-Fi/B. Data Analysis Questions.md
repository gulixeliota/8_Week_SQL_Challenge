#### B. Data Analysis Questions

**1. How many customers has Foodie-Fi ever had?**

To determine the number of customers for Foodie, I use COUNT in combination with DISTINCT

````sql
SELECT 
  COUNT(DISTINCT customer_id) AS total_customers 
FROM subscriptions
````

**Answer:**

| **total_customers** |
|---------------------|
| 1000                |

=> Foodie-Fi has 1,000 unique customers.

***
**2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value**

````sql
SELECT 
  DATEPART(M, start_date) monthly_part, 
  DATENAME(M, start_date) monthly_name, 
  COUNT(start_date) total_distribution 
FROM subscriptions s 
LEFT JOIN plans p ON p.plan_id = s.plan_id 
WHERE p.plan_name = 'trial' 
GROUP BY DATEPART(M, start_date), DATENAME(M, start_date) 
ORDER BY monthly_part
````

**Answer:**

| **monthly_part** | **monthly_name** | **total_distribution** |
|------------------|------------------|------------------------|
| 1                | January          | 88                     |
| 2                | February         | 68                     |
| 3                | March            | 94                     |
| 4                | April            | 81                     |
| 5                | May              | 88                     |
| 6                | June             | 79                     |
| 7                | July             | 89                     |
| 8                | August           | 88                     |
| 9                | September        | 87                     |
| 10               | October          | 79                     |
| 11               | November         | 75                     |
| 12               | December         | 84                     |

- Among all the months, March has the highest number of trial plans, while February has the lowest number of trial plans.


***
**3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name**


````sql
SELECT 
  plan_id, 
  plan_name, 
  SUM(events_2020) AS cnt_events_2020, 
  SUM(events_2021) AS cnt_events_2021 
FROM 
  (
    SELECT 
      p.plan_id, 
      p.plan_name, 
      CASE WHEN YEAR(s.start_date) = 2020 THEN 1 ElSE 0 END AS events_2020, 
      CASE WHEN YEAR(s.start_date) = 2021 THEN 1 ElSE 0 END AS events_2021 
    FROM plans p 
    LEFT JOIN subscriptions s ON p.plan_id = s.plan_id
  ) AS plants_per_year 
GROUP BY plan_id, plan_name 
ORDER BY plan_id, plan_name
````

**Answer:**

| **plan_id** | **plan_name** | **cnt_event_2020** | **cnt_event_2021** |
|-------------|---------------|--------------------|--------------------|
| 0           | trial         | 1000               | 0                  |
| 1           | basic monthly | 538                | 8                  |
| 2           | pro monthly   | 479                | 60                 |
| 3           | pro annual    | 195                | 63                 |
| 4           | churn         | 236                | 71                 |
***

- In 2021 there will be no new customers, this can be seen from null on trial.
- In 2021 fewer customers buy plans, or because the data shown is only until April 2021?

**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**

````sql
SELECT 
  COUNT(DISTINCT customer_id) AS total_churns, 
  CAST(COUNT(DISTINCT customer_id) AS float)* 100 /(SELECT COUNT(DISTINCT customer_id) FROM subscriptions) AS churn_percentage
FROM subscriptions 
WHERE plan_id = 4
````

**Answer:**

| **total_churns** | **churn_percentage** |
|------------------|----------------------|
| 307              | 30.7                 |

=> Percentage of customers who have churned is more than 30%. This is a pretty high rate, Foodie needs to find out what causes this churn rate.

***
**5. How many customers have churned straight after their initial free trial?**

````sql
WITH ranking AS (
  SELECT 
    s.customer_id, 
    s.plan_id, 
    p.plan_name, 
    s.start_date, 
    RANK() OVER(PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) AS rnk 
  FROM plans p 
  JOIN subscriptions s ON p.plan_id = s.plan_id
) 
SELECT 
  COUNT(DISTINCT customer_id) AS total_churn, 
  COUNT(DISTINCT customer_id)* 100 / (SELECT COUNT(DISTINCT customer_id) FROM ranking) AS percentage_churn 
FROM ranking 
WHERE 
  plan_name = 'churn' 
  AND rnk = 2
````

**Answer:**

| **total_churn** | **churn_percentage** |
|-----------------|----------------------|
| 92              | 9                    |

The churn rate after trial is about 9%
=> Most customers sign up for a new plan after trying it out.

***
**6. What is the number and percentage of customer plans after their initial free trial?**

````sql
WITH next_plan AS (
  SELECT 
    *, 
    LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date, plan_id) AS plans 
  FROM subscriptions
) 
SELECT 
  s.plans, 
  p.plan_name,
  COUNT(DISTINCT customer_id) AS total,
  (100 * CAST(COUNT(DISTINCT customer_id) AS float) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)) AS percentage 
FROM next_plan AS s 
LEFT JOIN plans p ON p.plan_id = s.plans 
WHERE 
  s.plan_id = 0 
  AND s.plans is not null 
GROUP BY s.plans, p.plan_name
ORDER BY s.plans, p.plan_name

````

**Answer:**

| **plans** | **plan_name** | **plan_num** | **plan_percentage** |
|-----------|---------------|--------------|---------------------|
| 1         | basic monthly | 546          | 54.6                |
| 2         | pro monthly   | 325          | 32.5                |
| 3         | pro annual    | 37           | 3.7                 |
| 4         | churn         | 92           | 9.2                 |
***


**7. What is the customer count of all 5 plan_name values at 2020-12-31?**

````sql
WITH customer_plans AS (
						SELECT customer_id,
                               plan_id,
                               start_date,
                               RANK() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rank
                        FROM   subscriptions
                        WHERE  start_date <= '2020-12-31'
),
   total_customers AS (
                       SELECT COUNT(DISTINCT customer_id) AS total_customers
                       FROM   subscriptions
                       WHERE  start_date <= '2020-12-31'
)
SELECT p.plan_name,
       COUNT(c.customer_id) AS customer_count
FROM total_customers AS t,
     customer_plans AS c
JOIN plans AS p ON c.plan_id = p.plan_id
WHERE c.rank = 1
GROUP BY p.plan_name, t.total_customers
ORDER BY customer_count DESC
````

**Answer:**

| **plan_name** | **customer_count** |
|---------------|--------------------|
| pro monthly   | 326                |
| churn         | 236                |
| basic monthly | 224                |
| pro annual    | 195                |
| trial         | 19                 |
***




**8. How many customers have upgraded to an annual plan in 2020?**

````sql
SELECT 
	COUNT(DISTINCT s.customer_id) total_customers
FROM subscriptions s
LEFT JOIN plans p ON p.plan_id = s.plan_id
WHERE p.plan_name = 'pro annual'
	AND YEAR(s.start_date) = 2020
````

**Answer:**

| **total_customers** |
|---------------------|
| 195                 |

***







**9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?**

````sql
WITH annual_plan_date AS (
	SELECT 
		*, 
		LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date, plan_id) AS plans
	FROM subscriptions
	WHERE customer_id IN (SELECT customer_id FROM subscriptions WHERE plan_id = 3)
		AND plan_id =0 OR plan_id =3
)
SELECT
	AVG(DATEDIFF(day,start_date,plans)) as days
FROM annual_plan_date
WHERE plans is not NULL
````

**Answer:**

| **days** |
|----------|
| 104      |
***



**10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)**

```sql
WITH
	trial AS--trial plan
	(
		SELECT 
			s.customer_id,
			s.start_date trial_date
		FROM subscriptions s
		LEFT JOIN plans p ON p.plan_id = s.plan_id
		WHERE p.plan_name = 'trial'
),
	annual AS--annual plan
	(
		SELECT 
			s.customer_id,
			s.start_date annual_date
		FROM subscriptions s
		LEFT JOIN plans p ON p.plan_id = s.plan_id
		WHERE p.plan_name = 'pro annual'
),
	diff AS--day difference
	(
		SELECT 
			DATEDIFF(D, t.trial_date, a.annual_date) days
		FROM trial t
		LEFT JOIN annual a ON t.customer_id = a.customer_id
		WHERE a.annual_date is not null
),
	bucket AS --bucket
	(
		SELECT *, 
			FLOOR(days/30) bucket
		FROM diff
)
SELECT
	CONCAT((bucket * 30) + 1, ' - ', (bucket + 1) * 30, ' days ') AS days,
	COUNT(days) total,
	CEILING(AVG(CAST(days AS float))) AS avg_days
FROM bucket
GROUP BY bucket
```

**Answer:**

 | **days**       | **total** | **avg_days** |
 |----------------|-----------|--------------|
 | 1 - 30 days    | 48        | 10           |
 | 31 - 60 days   | 25        | 42           |
 | 61 - 90 days   | 33        | 71           |
 | 91 - 120 days  | 35        | 100          |
 | 121 - 150 days | 43        | 134          |
 | 151 - 180 days | 35        | 162          |
 | 181 - 210 days | 27        | 191          |
 | 211 - 240 days | 4         | 225          |
 | 241 - 270 days | 5         | 258          |
 | 271 - 300 days | 1         | 285          |
 | 301 - 330 days | 1         | 327          |
 | 331 - 360 days | 1         | 346          |






**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**

````sql
WITH pro_monthly AS (
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date as pro_monthly_date
	FROM subscriptions s
	JOIN plans p ON p.plan_id = s.plan_id
	WHERE YEAR(s.start_date) = 2020
		AND s.plan_id = 2
),
basic_monthly AS (
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date as basic_monthly_date
	FROM subscriptions s
	JOIN plans p ON p.plan_id = s.plan_id
	WHERE YEAR(s.start_date) = 2020
		AND s.plan_id = 1
)

SELECT 
	count(*) as dowgrade
FROM pro_monthly pm
JOIN basic_monthly bm ON pm.customer_id = bm.customer_id
WHERE basic_monthly_date >  pro_monthly_date
````

**Answer:**

| **dowgrade** |
|--------------|
| 0            |

=> There is no customers downgraded from a pro monthly to a basic monthly plan in 2020.