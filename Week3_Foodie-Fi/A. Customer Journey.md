
```sql
SELECT 
	s.customer_id,
	p.plan_name,
	s.start_date,
	DATEDIFF(day, LAG(s.start_date,1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date),s.start_date) as days_diff,
	DATEDIFF(month, LAG(s.start_date,1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date),s.start_date) as days_diff
FROM   subscriptions AS s
JOIN   plans AS p
ON     s.plan_id = p.plan_id
WHERE  s.customer_id IN (1,2,11,13,15,16,18,19)
```


***

📄Next Section: [B. Data Analysis Questions](https://github.com/gulixeliota/8_Week_SQL_Challenge/blob/main/Week3_Foodie-Fi/B.%20Data%20Analysis%20Questions.md) ⏭