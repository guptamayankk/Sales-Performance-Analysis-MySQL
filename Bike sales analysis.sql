SELECT * FROM fact_sales;
SELECT * FROM dim_products;
SELECT * FROM dim_customers;

update fact_sales 
set order_date = NULL
where  order_date = "" ;

-- Find the date of first and last order
-- How many years of sales are available

select min(order_date) as first_order_date, max(order_date) as last_order_date,
timestampdiff(year, min(order_date), max(order_date)) as order_range_years
from fact_sales;

-- Find the total no. of orders

select count(distinct order_number) as total_orders from fact_sales;


-- which 5 products generate the highest revenue?

with cte as (select p.product_name, sum(s.sales_amount) as total_revenue,
row_number() over(order by sum(s.sales_amount) desc) as ranking from dim_products p
right join fact_sales s on p.product_key = s.product_key 
group by p.product_name)
select * from cte where ranking <= 5;

-- Sales analysis over the month

select year(order_date) as order_year, month(order_date) as order_month , sum(sales_amount) as total_sales, 
count(distinct customer_key) as toal_customers, sum(quantity) as total_quantity
from fact_sales group by  order_month order by order_month;

-- calculate the total sales per month and running total sales over time

with cte as (select month(order_date) as month_no , sum(sales_amount) as total_sales  from fact_sales 
group by month_no)
select month_no, total_sales, sum(total_sales) over(order by month_no) as running_total from cte;

-- which categories contribute the most to overall sales 
with cte as (select p.category, sum(s.sales_amount) as total_sales from fact_sales s left join 
dim_products p on s.product_key = p.product_key
group by p.category)
select category, total_sales, sum(total_sales) over() as overall_sales, 
concat(round((total_sales/sum(total_sales) over())*100,2),'%')  as percentage_of_total from cte 
order by total_sales desc;

-- Explore all categories "		"The Major Divisions".

SELECT DISTINCT category, subcategory, product_name FROM dim_products;

-- Find the avg cost in each category

select category, avg(cost) as avg_cost from dim_products 
group by category order by avg_cost desc;

-- Find the total revenue generated for each category

select p.category, sum(s.sales_amount) as total_revenue from dim_products p
right join fact_sales s on p.product_key = s.product_key 
group by p.category order by total_revenue desc;

-- Analyze the yearly performance of products by comparing their sales to both the average sales performance 
-- of the product and the previous year's sales 

with cte as (select year(s.order_date) as year_no, p.product_name, sum(s.sales_amount) as total_sales
from dim_products p
right join fact_sales s on p.product_key = s.product_key where s.order_date is not null
group by year_no, p.product_name)
select year_no, product_name, total_sales, avg(total_sales) over(partition by product_name) avg_sales, 
total_sales- avg(total_sales) over(partition by product_name) avg_diff ,
case when total_sales- avg(total_sales) over(partition by product_name) > 0 then 'above_avg'
     when total_sales- avg(total_sales) over(partition by product_name) < 0 then 'below_avg'
     else 'avg'
end 'avg_change',
-- year over year analysis
lag(total_sales) over(partition by product_name order by year_no) as py_sales,
total_sales - lag(total_sales) over(partition by product_name order by year_no) as py_diff,
case when total_sales - lag(total_sales) over(partition by product_name order by year_no) > 0 then 'increasing'
     when total_sales - lag(total_sales) over(partition by product_name order by year_no) < 0 then 'decreasing'
     else 'No change'
end py_change
from cte;

-- segment products into cost ranges and count how many products fall into each segment

with cte as (select product_key, product_name, cost,
case when cost < 100 then 'Below 100'
     when cost between 100 and 500 then '100-500'
     when cost between 500 and 1000 then '500-1000'
     else 'above 1000'
end cost_range
from dim_products)
select cost_range, count(product_key) as total_products
from cte group by cost_range  order by total_products desc;

-- Find age of customers.

SELECT timestampdiff(YEAR, birthdate, CURDATE()) as AGE FROM dim_customers;

-- Explore all countries where our customers come from.

SELECT DISTINCT country from dim_customers;

-- Find the total no. of customers by country

select country, count(customer_key) as total_customers from dim_customers 
group by country order by total_customers desc;

-- group customers into three segments based on their spending behaviour:
--  VIP: at least 12 months of history and spending more than 5000.
-- Regular: at least 12 months of history but spending 5000 or less.
-- New: lifespan less than 12 months.
-- and find the totlal no of customers by each group

with cte as (select c.customer_key, sum(s.sales_amount) as total_spending ,
min(order_date) as first_order , max(order_date) as last_order,
timestampdiff(month, min(order_date), max(order_date)) as lifespan,
case when sum(s.sales_amount) > 5000 and timestampdiff(month, min(order_date), max(order_date)) >12 then 'VIP'
     when sum(s.sales_amount) <= 5000 and timestampdiff(month, min(order_date), max(order_date))>=12 then 'Regular'
     else 'New'
end 'customer_segment'
from dim_customers c right join
fact_sales s on c.customer_key = s.customer_key 
group by c.customer_key)
select customer_segment, count(customer_key) as total_customers from cte 
group by customer_segment




















