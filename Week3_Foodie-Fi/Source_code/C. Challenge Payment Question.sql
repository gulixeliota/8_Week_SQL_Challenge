-- C.Challenge Payment Question
WITH join_table AS (
	select 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date payment_date,
		s.start_date,
		LEAD(s.start_date, 1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) next_date,
		p.price amount
	from subscriptions s
	left join plans p on p.plan_id = s.plan_id
)
	SELECT 
		customer_id,
		plan_id,
		plan_name,
		payment_date,
		start_date,
		case when next_date IS NULL or next_date > '20201231' then '20201231' else next_date end next_date,
		amount
	FROM join_table
	WHERe plan_name NOT IN ('trial','churn')
