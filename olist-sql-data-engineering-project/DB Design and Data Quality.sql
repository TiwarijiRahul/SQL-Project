use EcommerceDB;
go
select * from customers;
select * from geolocation;
select * from order_items;
select * from order_payments;
select * from order_reviews;
select * from orders;
select * from products;
select * from product_category;
select * from sellers;
--------------------------------------


---Part A: Database Design & Data Quality

---Task -3---  Create tables with appropriate data types, primary keys, foreign keys, and constraints.

---Task - Create all required primary key in all the tables

-- Customers Table
ALTER TABLE customers
ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);

-- Orders Table
ALTER TABLE orders
add CONSTRAINT PK_orders PRIMARY KEY (order_id);
ALTER TABLE orders
add CONSTRAINT FK_orders_customers FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- Order Items Table (Composite PK)
ALTER TABLE order_items
ADD CONSTRAINT PK_order_items PRIMARY KEY (order_id,order_item_id);
ALTER TABLE order_items
ADD CONSTRAINT FK_order_items_orders FOREIGN KEY (order_id)
REFERENCES orders(order_id);
ALTER TABLE order_items
ADD CONSTRAINT FK_order_items_products FOREIGN KEY (product_id)
REFERENCES products(product_id);
ALTER TABLE order_items
ADD CONSTRAINT FK_order_items_sellers FOREIGN KEY (seller_id)
REFERENCES sellers(seller_id);

-- Products Table
ALTER TABLE products
ADD CONSTRAINT PK_products PRIMARY KEY (product_id);



-- Product Category Table
ALTER TABLE product_category
ADD CONSTRAINT PK_product_category PRIMARY KEY (product_category_name);

-- Sellers Table
ALTER TABLE sellers
ADD CONSTRAINT PK_sellers PRIMARY KEY (seller_id);


-- Order Payments Table (Composite PK)
ALTER TABLE order_payments
ADD CONSTRAINT PK_order_payments PRIMARY KEY (order_id, payment_sequential);
ALTER TABLE order_payments
ADD CONSTRAINT FK_order_payments_orders FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- Order Reviews Table
ALTER TABLE order_reviews
ADD CONSTRAINT PK_order_reviews PRIMARY KEY (review_id,order_id);
ALTER TABLE order_reviews
ADD CONSTRAINT FK_order_reviews_orders FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- Geolocation Table (Surrogate PK)
ALTER TABLE geolocation
ADD geolocation_id INT IDENTITY(1,1) PRIMARY KEY;

---Task -4---  	Write a SQL script to detect and remove duplicate customers while keeping the most recent record.
--Detect Duplicate id
select customer_unique_id, count(*) as duplicate_id
from customers
group by customer_unique_id
having count(*) >1;
----------------------


--Remove Duplicate customers

With Duplicate_customers as(
Select customer_id, customer_unique_id,
ROW_NUMBER() over(partition by customer_unique_id order by customer_id desc)
as row_num
from customers)
Delete  from Duplicate_customers 
where row_num>1;

----------------------------------------
----------------------------------------
-----Part - B Data Manuplation & Retrieval
--Taks -- 1. Insert cleaned data using transactions and demonstrate COMMIT and ROLLBACK.

--Transaction--
--Inserting cleaned data into customer table
BEGIN TRANSACTION;



INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('CUST001','U12345',06233,'Sao Paulo','SP'),
       ('CUST002','U67890',31000,'Belo Horizonte','MG');

COMMIT TRANSACTION;


-- Commit the transaction if everything is successful
COMMIT TRANSACTION;

-- RollBack Transaction

BEGIN TRANSACTION;

INSERT INTO customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
VALUES ('CUST001','U12345','06233','Sao Paulo','SP'); -- Duplicate PK


-- Something goes wrong, so rollback
ROLLBACK TRANSACTION;

--Task 2. Find customers who have the same email but different names/addresses

select a.customer_id, a.customer_unique_id, a.customer_city 
from customers as a
join customers as b
on a.customer_unique_id= b.customer_unique_id
and a.customer_city<>b.customer_city;


--Task 3.Identify orphan records referencing non-existent products or orders.

select oi.order_id
from order_items as oi
left join orders as o
on oi.order_id= o.order_id
where o.order_id is null;


--Task 4.List customers who registered but never placed an order.

select c.customer_id
from customers as c
left join orders as o
on c.customer_id= o.customer_id
where o.customer_id is null;

--Task 5. Detect potential fraud where payment value differs from order total.

with potential_fraud as (
select order_id, sum(price) as total_price
from order_items 
group by order_id)

select ot.order_id,ot.total_price,op.payment_value
from potential_fraud as ot
join order_payments as op
on ot.order_id= op.order_id
where ot.total_price<>op.payment_value;

-----------------------------------------------------------

------Part C: Complex Aggregations -----------

--Task 1.Calculate monthly revenue with Month-over-Month growth percentage.
WITH monthly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year_,
        MONTH(o.order_purchase_timestamp) AS month_,
        SUM(op.payment_value) AS revenue
    FROM orders o
    JOIN order_payments op
        ON o.order_id = op.order_id
    GROUP BY
        YEAR(o.order_purchase_timestamp),
        MONTH(o.order_purchase_timestamp)
)

SELECT
    year_,
    month_,
    revenue,
    LAG(revenue) OVER (
        ORDER BY year_, month_
    ) AS previous_revenue
FROM monthly_revenue;

--Task 3. Calculate Customer Lifetime Value (CLV) and categorize customers.
select c.customer_id, sum(op.payment_value) as CLV
from customers as c
join orders as o
on c.customer_id= o.customer_id
join order_payments as op
on o.order_id= op.order_id
group by c.customer_id;

--Task 4. Create sales reports using ROLLUP or CUBE.
SELECT 
    s.seller_id,
    pc.product_category_name,
    SUM(oi.price) AS Total_Sales
FROM order_items AS oi
JOIN products AS p ON oi.product_id = p.product_id
JOIN product_category AS pc ON p.product_category_name = pc.product_category_name
JOIN sellers AS s ON oi.seller_id = s.seller_id
GROUP BY ROLLUP (s.seller_id, pc.product_category_name)
ORDER BY s.seller_id, pc.product_category_name;

--Task 5. Identify seasonal sales patterns by product category.

select
      pc.product_category_name,
      year(o.order_purchase_timestamp)as Year,
      month(o.order_purchase_timestamp) as month,
      sum(oi.price) as Total_sales
from order_items as oi
join orders as o on
oi.order_id= o.order_id
join products as p
on oi.product_id= p.product_id
join product_category as pc
on p.product_category_name= pc.product_category_name
group by pc.product_category_name, year(o.order_purchase_timestamp), MONTH(o.order_purchase_timestamp)
order by pc.product_category_name, Year, month;

-----------------------------------------------------------

------Part D: Mastering Joins -----------

-- Task 1. Create a customer 360-degree view joining multiple tables.

select
      c.customer_id,
      c.customer_unique_id,
      c.customer_state,
     
      count( o.order_id) as Total_orders,
      sum(op.payment_value) as Total_spent,
      avg(op.payment_value) as Avg_payment,
      avg(cast(orv.review_score as float)) as Avg_review_score,
      count( p.product_category_name) as Product_categories
from  customers as c
join orders as o
on c.customer_id= o.customer_id
join order_payments as op
on op.order_id= o.order_id
join order_reviews as orv
on orv.order_id= op.order_id
join order_items as oi
on oi.order_id=orv.order_id
join products as p
on p.product_id= oi.product_id
group by c.customer_id,customer_unique_id,c.customer_state
order by Total_spent desc;

-- 2. Find customers who bought electronics but never books.

select 
     c.customer_id,
     pc.product_category_name_english 
from customers as c
join orders as o
on o.customer_id= c.customer_id
join order_items as oi
on oi.order_id=o.order_id
join products as p
on p.product_id= oi.product_id
join product_category as pc
on p.product_category_name= pc.product_category_name

where pc.product_category_name_english = 'electronics'
and c.customer_id not in  (select c2.customer_id
from customers as c2
join orders as o2
on o2.customer_id= c2.customer_id
join order_items as oi2
on oi2.order_id=o2.order_id
join products as p2
on p2.product_id= oi2.product_id
join product_category as pc2
on p2.product_category_name= pc2.product_category_name

where pc2.product_category_name_english = 'books');

--Task 3. List sellers and their best-selling product in each category.
            
WITH SellerSales AS (
    SELECT 
        s.seller_id,
        pc.product_category_name_english,
        oi.product_id,
        SUM(oi.price) AS Total_Sales
    FROM sellers AS s
    JOIN order_items AS oi ON s.seller_id = oi.seller_id
    JOIN products AS p ON oi.product_id = p.product_id
    JOIN product_category AS pc ON p.product_category_name = pc.product_category_name
    GROUP BY s.seller_id, pc.product_category_name_english, oi.product_id
),
RankedSellers AS (
    SELECT 
        seller_id,
        product_category_name_english,
        product_id,
        Total_Sales,
        ROW_NUMBER() OVER (
            PARTITION BY seller_id, product_category_name_english 
            ORDER BY Total_Sales DESC
        ) AS ranks
    FROM SellerSales
)
SELECT 
    seller_id,
    product_category_name_english,
    product_id,
    Total_Sales
FROM RankedSellers
WHERE ranks = 1
ORDER BY seller_id, product_category_name_english;

--Task 4. Perform market basket analysis using self-joins.

SELECT 
    p1.product_category_name AS Product_A,
    p2.product_category_name AS Product_B,
    COUNT(*) AS Frequency
FROM order_items AS oi1
JOIN order_items AS oi2 
    ON oi1.order_id = oi2.order_id 
    AND oi1.product_id <> oi2.product_id
JOIN products AS p1 ON oi1.product_id = p1.product_id
JOIN products AS p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_category_name, p2.product_category_name
ORDER BY Frequency DESC;

--Task 5. Identify orders with shipping delays.

select 
     order_id,
     order_status,
     order_purchase_timestamp,
     cast(order_estimated_delivery_date as Date) as delivery_date,
     cast(order_delivered_customer_date as Date) as delivered_date,
     DATEDIFF(DAY,order_estimated_delivery_date,order_delivered_customer_date) as shipping_delays
from orders
where order_delivered_customer_date> order_estimated_delivery_date;

-----------------------------------------------------------

------Part E: Subqueries & CTEs  -----------

--Task 1. Find customers spending above their state's average.

with Customer_spending_avg as (
     select
           c.customer_id,
           op.payment_value,
           c.customer_state,
           sum(op.payment_value) as Total_spent,
           avg(sum(op.payment_value))over (partition by c.customer_state) as state_avg
    from customers as c
    join orders as o
    on c.customer_id= o.customer_id
    join order_payments as op
    on op.order_id= o.order_id
    group by c.customer_id, op.payment_value,c.customer_state)
select * from Customer_spending_avg
where Total_spent>state_avg;

--Task 2.Get the 2nd highest revenue-generating product in each category.
with product_revenue as(
    select pc.product_category_name_english,
    p.product_id,
    sum(op.payment_value) as Total_revenue
    
    from order_payments as op
    join order_items as oi
    on op.order_id=oi.order_id
    join products as p
    on p.product_id= oi.product_id
    join product_category as pc
    on pc.product_category_name=p.product_category_name
    group by pc.product_category_name_english,p.product_id
    
),
ranked_products as(
select *,
DENSE_RANK()over(partition by product_category_name_english order by Total_revenue desc) as dens_rank
from product_revenue
)
select * from ranked_products
where dens_rank=2;

--Task 3. Create a product category hierarchy using recursive CTEs.
WITH CategoryHierarchy AS
(
    SELECT
        product_category_name,
        1 AS lvl
    FROM product_category
    WHERE product_category_name =
          (SELECT MIN(product_category_name)
           FROM product_category)

    UNION ALL

    SELECT
        pc.product_category_name,
        ch.lvl + 1
    FROM product_category pc
    JOIN CategoryHierarchy ch
      ON pc.product_category_name =
         (
            SELECT MIN(product_category_name)
            FROM product_category
            WHERE product_category_name > ch.product_category_name
         )
)
SELECT *
FROM CategoryHierarchy;

--Task 4. Find customers purchasing in 3+ consecutive months.

with Monthly_purchse as (
select 
     customer_id, 
     year(order_purchase_timestamp) as purchase_year,
     month(order_purchase_timestamp) as purchase_month
     from orders
     group by customer_id, year(order_purchase_timestamp),month(order_purchase_timestamp)
),
Month_gap as (
select
      customer_id, purchase_year,purchase_month,
      lag(purchase_month) over(partition by customer_id order by purchase_year, purchase_month) as prev_month
      from Monthly_purchse
),
consecutive_month as (
select 
      customer_id, purchase_year,purchase_month,
      case when purchase_month - prev_month=1 then 1 else 0 end as is_consecutive
      from Month_gap
)
select customer_id,
count(*) as consecutive_months
from consecutive_month
where is_consecutive=1
group by customer_id
having count(*)>=3;

-----------------------------------------------------------

------Part F: Advanced Window Functions   -----------

-- Task 1. Calculate a 7-day moving average of daily order count.


WITH daily_orders AS
(
    SELECT
        CAST(order_purchase_timestamp AS DATE) AS order_date,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY CAST(order_purchase_timestamp AS DATE)
)
SELECT
    order_date,
    order_count,
    AVG(order_count * 1.0) OVER(
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7_days
FROM daily_orders;

--Task 2. Find gaps between consecutive customer orders using LAG().

WITH order_gaps AS
(
    SELECT
        customer_id,
        order_purchase_timestamp,
        LAG(order_purchase_timestamp) OVER
        (
            PARTITION BY customer_id
            ORDER BY order_purchase_timestamp
        ) AS prev_order
    FROM orders
)
SELECT
    customer_id,
    order_purchase_timestamp,
    prev_order,
    DATEDIFF(
        DAY,
        prev_order,
        order_purchase_timestamp
    ) AS gap_days
FROM order_gaps;

--Task 3. Rank sellers by revenue within each state.
with Sellers_Rank as (
select
     s.seller_id,
     s.seller_state,
     sum(op.payment_value) as Total_revenue,
     rank() over(partition by s.seller_state order by sum(op.payment_value) desc) as Ranked
from order_payments as op
join order_items as oi
on op.order_id= oi.order_id
join sellers as s
on s.seller_id= oi.seller_id
group by s.seller_id, s.seller_state
)
select * from Sellers_Rank;

--Task 4. Calculate running revenue totals and percentage contribution.

With daily_revenue as (
select
     cast(o.order_purchase_timestamp as date) as order_date,
     sum(op.payment_value) as revenue
     from orders as o
     join order_payments as op
     on o.order_id= op.order_id
     group by cast(o.order_purchase_timestamp as date)
)
select 
      order_date,
      revenue,
      sum(revenue) over(order by order_date) as running_total,
      revenue*100.0/sum(revenue) over() as percentage_contribution
from daily_revenue;

-----------------------------------------------------------

------Part G: Stored Procedures & Optimization   -----------

--Task 1. Create a stored procedure for dynamic discount calculation.
CREATE PROCEDURE CalculateDiscount
    @OrderAmount DECIMAL(10,2)
AS
BEGIN

    DECLARE @DiscountPercent DECIMAL(5,2);

    SET @DiscountPercent =
    CASE
        WHEN @OrderAmount < 100 THEN 0
        WHEN @OrderAmount < 500 THEN 5
        WHEN @OrderAmount < 1000 THEN 10
        ELSE 15
    END;

    SELECT
        @OrderAmount AS OrderAmount,
        @DiscountPercent AS DiscountPercent,
        @OrderAmount * @DiscountPercent / 100 AS DiscountAmount,
        @OrderAmount -
        (@OrderAmount * @DiscountPercent / 100) AS FinalAmount;

END;
EXEC CalculateDiscount 1200;

--Task 2. Optimize slow queries using EXPLAIN ANALYZE and indexes.

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    o.order_id,
    c.customer_id,
    c.customer_city
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id;


CREATE INDEX idx_customers_city
ON customers(customer_city);

CREATE INDEX idx_orders_customer
ON orders(customer_id);
----------------------------------------------------------
----------------------------------------------------------
----------------------------------------------------------
----------------------------------------------------------
select * from customers;
select * from order_items;
select * from order_payments;
select * from order_reviews;
select * from orders;
select * from products;
select * from product_category;
select * from sellers;