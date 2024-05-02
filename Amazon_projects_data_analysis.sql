--Amazon Sales Analysis Projects 

-- Create the table so we can import the data

-- creating customers table
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
                            customer_id VARCHAR(25) PRIMARY KEY,
                            customer_name VARCHAR(25),
                            state VARCHAR(25)
);


-- creating sellers table
DROP TABLE IF EXISTS sellers;
CREATE TABLE sellers (
                        seller_id VARCHAR(25) PRIMARY KEY,
                        seller_name VARCHAR(25)
);


-- creating products table
DROP TABLE IF EXISTS products;
CREATE TABLE products (
                        product_id VARCHAR(25) PRIMARY KEY,
                        product_name VARCHAR(255),
                        Price FLOAT,
                        cogs FLOAT
);



-- creating orders table
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
                        order_id VARCHAR(25) PRIMARY KEY,
                        order_date DATE,
                        customer_id VARCHAR(25),  -- this is a foreign key from customers(customer_id)
                        state VARCHAR(25),
                        category VARCHAR(25),
                        sub_category VARCHAR(25),
                        product_id VARCHAR(25),   -- this is a foreign key from products(product_id)
                        price_per_unit FLOAT,
                        quantity INT,
                        sale FLOAT,
                        seller_id VARCHAR(25),    -- this is a foreign key from sellers(seller_id)
    
                        CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
                        CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),    
                        CONSTRAINT fk_sellers FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);



-- creating returns table
DROP TABLE IF EXISTS returns;
CREATE TABLE returns (
                        order_id VARCHAR(25),
                        return_id VARCHAR(25),
                        CONSTRAINT pk_returns PRIMARY KEY (order_id), --Q Primary key constraint
                        CONSTRAINT fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);



-- creating returns table
DROP TABLE IF EXISTS sales;
CREATE TABLE sales(
					id int PRIMARY KEY,
					order_date date,
					customer_name VARCHAR(25),
					state VARCHAR(25),
					category VARCHAR(25),
					sub_category VARCHAR(25),
					product_name VARCHAR(255),
					sales FLOAT,
					quantity INT,
					profit FLOAT
					);


-- Importing the data into the tables 

---------------------------------------------------------------------------------------
--Exploratory Data Analysis and Pre Processing
---------------------------------------------------------------------------------------


--Q  Checking total rows count

SELECT * FROM customers;
SELECT * FROM sellers;
SELECT * FROM products;
SELECT * FROM orders;
SELECT * FROM returns;
SELECT * FROM sales;

SELECT COUNT(*)
FROM customers;
SELECT COUNT(*)
FROM sellers;
SELECT COUNT(*)
FROM products;
SELECT COUNT(*)
FROM orders;
SELECT COUNT(*)
FROM returns;
SELECT COUNT(*)
FROM sales;

-- Checking if there any missing values for one of the table

SELECT COUNT(*)
FROM sales
WHERE id IS NULL 
   OR order_date IS NULL 
   OR customer_name IS NULL 
   OR state IS NULL 
   OR category IS NULL 
   OR sub_category IS NULL 
   OR product_name IS NULL 
   OR sales IS NULL 
   OR quantity IS NULL 
   OR profit IS NULL;

--  Checking for duplicate entry for one of the table

SELECT * FROM 
	(SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) as rn
FROM sales ) x
WHERE rn > 1;


---------------------------------------------------------------------------------------
-- Feature Engineering 
---------------------------------------------------------------------------------------


--  creating a year column
ALTER TABLE sales
ADD COLUMN YEAR VARCHAR(4);
-- adding year value into the year column
UPDATE sales
SET year = EXTRACT(YEAR FROM order_date);

-- creating a new column for the month 
ALTER TABLE sales
ADD COLUMN MONTH VARCHAR(15);

-- adding abbreviated month name  
UPDATE sales
SET month = TO_CHAR(order_date, 'mon');

-- adding new column as day_name
ALTER TABLE sales
ADD COLUMN day_name VARCHAR(15);

-- updating day name into the day column
UPDATE sales 
SET day_name = TO_CHAR(order_date, 'day');

SELECT TO_CHAR(order_date, 'day')
FROM sales;

----------------------------------------------------------------------------------------
-- Solving Business Problems 
----------------------------------------------------------------------------------------

--Q1. Retrieve the total number of customers in the database.

SELECT COUNT(DISTINCT customer_name) AS total_customers
FROM sales;

--Q2. Calculate the total number of sellers registered on Amazon.

SELECT COUNT(*) AS total_sellers
FROM sellers;


--Q3. List all unique product categories available.

SELECT DISTINCT category
FROM sales;

--Q4. Find the top 5 best-selling products by quantity sold.

SELECT product_name, SUM(quantity) AS total_quantity_sold
FROM sales
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

--Q5. Determine the total revenue generated from sales.

SELECT SUM(sales) AS total_revenue
FROM sales;


--Q6. List all customers who have made at least one return.

SELECT DISTINCT C.CUSTOMER_NAME
FROM
ORDERS O INNER JOIN RETURNS R
ON O.ORDER_ID = R.ORDER_ID
INNER JOIN CUSTOMERS C
ON O.CUSTOMER_ID= C.CUSTOMER_ID;

--Q7. Calculate the average price of products sold.

SELECT DISTINCT product_name,AVG(price)
FROM PRODUCTS
GROUP BY PRODUCT_NAME
order by 1 asc

--Q8. Identify the top 3 states with the highest total sales.

SELECT state, SUM(sale) AS total_sales
FROM orders
GROUP BY state
ORDER BY total_sales DESC
LIMIT 3;

--Q9. Find the product category with the highest average sale price.

SELECT category, AVG(sale) AS avg_sales
FROM orders
GROUP BY category
ORDER BY avg_sales DESC
LIMIT 1;

--Q10. List all orders with a sale amount greater than $100.

select * from orders
where sale>100


--Q11. Calculate the total number of returns processed.

SELECT COUNT(DISTINCT return_id) AS total_returns_processed
FROM returns;

--Q12. Identify the top-selling seller based on total sales amount.

SELECT seller_id, SUM(sale) AS total_sales_amount
FROM orders
GROUP BY seller_id
ORDER BY total_sales_amount DESC
LIMIT 1;


--Q13. List the products with the highest quantity sold in each category.

WITH RankedProducts AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY quantity DESC) AS rank
    FROM orders
)
SELECT product_id, category, quantity
FROM RankedProducts
WHERE rank = 1;

--Q14. Determine the average sale amount per order.


SELECT order_id, AVG(sale) AS average_sale_amount_per_order
FROM orders
GROUP BY order_id;

--Q15. Find the top 5 customers who have spent the most money.

SELECT customer_id, SUM(sale) AS total_spent
FROM orders
GROUP BY customer_id
ORDER BY total_spent DESC
LIMIT 5;


--Q16. Calculate the total number of orders placed in each state.

SELECT state, COUNT(*) AS total_orders
FROM orders
GROUP BY state;


--Q17.Identify the product sub-category with the highest total sales.

SELECT sub_category, SUM(sale) AS total_sales
FROM orders
GROUP BY sub_category
ORDER BY total_sales DESC
LIMIT 1;


--Q18. Top 5 products whose revenue has decreased in comparison to previous year.

WITH py1 
AS (
	SELECT
		product_name,
		SUM(sales) as revenue
	FROM sales
	WHERE year = '2023'
	GROUP BY 1
),
py2 
AS	(
	SELECT
		product_name,
		SUM(sales) as revenue
	FROM sales
	WHERE year = '2022'
	GROUP BY 1
)
SELECT
	py1.product_name,
	py1.revenue as current_revenue,
	py2.revenue as prev_revenue,
	(py1.revenue / py2.revenue) as revenue_decreased_ratio
FROM py1
JOIN py2
ON py1.product_name = py2.product_name
WHERE py1.revenue < py2.revenue
ORDER BY 2 DESC
LIMIT 5;


--Q19. Determine the month with the highest number of orders.

SELECT 
	(month ||'-' || year) month_name, --Q for mysql CONCAT()
	COUNT(id)
FROM sales
GROUP BY 1
ORDER BY 2 DESC;

--Q20. Calculate the profit margin percentage for each sale (Profit divided by Sales).

SELECT 
	profit/sales as profit_mergin
FROM sales

--Q21. Calculate the percentage contribution of each sub-category to 
--Q the total sales amount for the year 2023.

WITH CTE
	AS (SELECT
			sub_category,
			SUM(sales) as revenue_per_category
		FROM sales
		WHERE year = '2023'
		GROUP BY 1

)

SELECT	
	sub_category,
	(revenue_per_category / total_sales * 100)
FROM cte
CROSS JOIN
(SELECT SUM(sales) AS total_sales FROM sales WHERE year = '2023') AS cte1;

--Q22. List the orders with the highest quantity of products purchased.

SELECT order_id, SUM(quantity) AS total_quantity_purchased
FROM orders
GROUP BY order_id
ORDER BY total_quantity_purchased DESC
LIMIT 1;

--Q23. Calculate the average sale amount for each product category.
SELECT category, AVG(sale) AS average_sale_amount
FROM orders
GROUP BY category;


--Q24. Find the top-selling seller based on the number of orders processed
SELECT seller_id, COUNT(*) AS total_orders_processed
FROM orders
GROUP BY seller_id
ORDER BY total_orders_processed DESC
LIMIT 1;

--Q25. Identify the customers who have made returns more than once.
SELECT customer_id, COUNT(return_id) AS return_count
FROM returns
GROUP BY customer_id
HAVING COUNT(return_id) > 1;


