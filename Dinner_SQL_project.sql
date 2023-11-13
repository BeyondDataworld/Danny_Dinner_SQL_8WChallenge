use projects;
/*
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  */
  
select * from [dbo].[sales];
select * from [dbo].[menu];
select * from [dbo].[members];

--1 What is the total amount each customer spent at the restaurant?
select
	distinct(s.customer_id) as customers,
	sum(mu.price) as total_price
from
	sales s
join
	menu mu on mu.product_id = s.product_id
group by
	s.customer_id
order by
	2 desc;

--2 How many days has each customer visited the restaurant?
select
	distinct(customer_id) as customer,
	count(order_date) as no_of_days
from
	sales
group by
	customer_id;

--3 What was the first item from the menu purchased by each customer?

select
	distinct(customer_id),
	product_name
from
	(
select
	s.customer_id,
	s.order_date,
	mu.product_name,
	dense_rank() over(partition by s.customer_id order by s.order_date asc) as rn
from
	sales s
join
	menu mu on mu.product_id = s.product_id
) as low_level
where
rn = 1;

--4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select
	distinct(s.customer_id) as customers,
	mu.product_name,
	count(mu.product_name) as no_of_products,
	DENSE_RANK() over(partition by s.customer_id order by count(mu.product_name) desc) as rn
from
	sales s
join
	menu mu on mu.product_id = s.product_id
group by
	s.customer_id, mu.product_name;

--5 Which item was the most popular for each customer?
select
	distinct (customers),
	product_name
from
(
select
	distinct(s.customer_id) as customers,
	mu.product_name,
	count(mu.product_name) as no_of_products,
	DENSE_RANK() over(partition by s.customer_id order by count(mu.product_name) desc) as rn
from
	sales s
join
	menu mu on mu.product_id = s.product_id
group by
	s.customer_id, mu.product_name
) as low_level
where
	rn = 1;

--6 Which item was purchased first by the customer after they became a member?
with cte as(
select
	distinct (s.customer_id) as customers,
	mu.product_name,
	s.order_date,
	row_number() over(partition by s.customer_id order by s.order_date asc) as rn
from
	sales s
join
	menu mu on mu.product_id = s.product_id
join
	members ms on ms.customer_id = s.customer_id
where
	s.order_date > ms.join_date
)
select
	customers,
	product_name
from
	cte
where
	rn =1;
	

--7 Which item was purchased just before the customer became a member?
with cte as(
select
	distinct (s.customer_id) as customers,
	mu.product_name,
	s.order_date,
	row_number() over(partition by s.customer_id order by s.order_date asc) as rn
from
	sales s
join
	menu mu on mu.product_id = s.product_id
join
	members ms on ms.customer_id = s.customer_id
where
	s.order_date < ms.join_date
)
select
	customers,
	product_name
from
	cte
where
	rn >= 2;

--8 What is the total items and amount spent for each member before they became a member?

select
	distinct (s.customer_id) as customers,
	count(mu.product_name) as total_products,
	sum(mu.price) as total_price
from
	sales s
join
	menu mu on mu.product_id = s.product_id
join
	members ms on ms.customer_id = s.customer_id
where
	s.order_date < ms.join_date
group by
	s.customer_id;

--9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
	customers,
	sum(case when product_name = 'sushi' then total_price * 20 
	else total_price *10 end) as total_points
from
(
select
	distinct (s.customer_id) as customers,
	mu.product_name,
	count(s.product_id) as no_of_itmes,
	sum(mu.price) as total_price
from
	sales s
join
	menu mu on s.product_id = mu.product_id
group by
	s.customer_id, mu.product_name
) as row_level
group by
	customers
order by
	1 asc;

--10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select
	customers,
	sum(total_price) * 20 as total_points
from
(
select
	distinct (s.customer_id) as customers,
	mu.product_name,
	s.order_date,
	count(s.product_id) as no_of_itmes,
	sum(mu.price) as total_price
from
	sales s
join
	menu mu on s.product_id = mu.product_id
join
	members me on s.customer_id = me.customer_id
where
	me.join_date <= s.order_date
group by
	s.customer_id, mu.product_name, s.order_date
) row_level

group by
	customers;


	-- Bonus Questions
--11 Create Table with marking customer as memeber Y or N based on their joining date.

select
	s.customer_id,
	s.order_date,
	mu.product_name,
	mu.price,
	case when s.order_date >= me.join_date THEN 'Y' else 'N' end as members
from
	sales s
join
	menu mu on s.product_id = mu.product_id
left join
	members me on s.customer_id = me.customer_id;

--12 Ranking products but only those customers who are members, nonmebers should have Null ranking

select
	customers,
	orders,
	products,
	price,
	members,
	case when members = 'Y' then rank() over(partition by customers, members order by orders) else null end as ranking
from
(
select
	s.customer_id as customers,
	s.order_date as orders,
	mu.product_name as products,
	mu.price as price,
	(case when s.order_date >= me.join_date THEN 'Y' else 'N' end) as members
from
	sales s
join
	menu mu on s.product_id = mu.product_id
left join
	members me on s.customer_id = me.customer_id
) as row_level;

