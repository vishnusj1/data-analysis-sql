SELECT * FROM STAGING_SALES ORDER BY order_date DESC; 

--- Cleaning Table and Columns
ALTER TABLE staging_sales RENAME COLUMN "Line Item" TO line_item;
ALTER TABLE staging_sales RENAME COLUMN "Delivery Date" TO delivery_date;
ALTER TABLE staging_sales RENAME COLUMN "Currency Code" TO currency_code;


-- Change Data Types -- 

ALTER TABLE staging_sales
ALTER COLUMN order_date TYPE DATE USING TO_DATE(order_date, 'MM/DD/YYYY');

ALTER TABLE staging_sales
ALTER COLUMN order_number TYPE INTEGER USING order_number::INTEGER;

ALTER TABLE staging_sales
ALTER COLUMN quantity TYPE INTEGER USING quantity::INTEGER;

ALTER TABLE staging_sales
ALTER COLUMN productkey TYPE INTEGER USING productkey::INTEGER;

ALTER TABLE staging_sales
ALTER COLUMN customerkey TYPE INTEGER USING customerkey::INTEGER;

-- END -- 


SELECT MAX(quantity) FROM staging_sales;

-- Check for data integrity -- 

SELECT s.productkey
FROM staging_sales s
LEFT JOIN staging_products p ON s.productkey = p.productkey
WHERE p.productkey IS NULL;

SELECT * FROM STAGING_SALES WHERE productkey IS NULL OR quantity IS NULL;

-- What are the KPI's?

-- Revenue Generate YTD--

-- Revenue = Sum of (product * quanitity * er)
SELECT 
	ROUND(SUM(s.quantity * p.unit_price * er.exchange),2) AS Revenue_Generated_YTD
FROM staging_sales s
JOIN staging_products p
	ON s.productkey = p.productkey
JOIN staging_exchange_rates er
	ON s.currency_code = er.currency
	AND s.order_date = er.date

-- Revenue YoY 
SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year, -- Extract the year from the order_date
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue, -- Calculate total revenue for the year
    LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)) AS previous_revenue, -- Get the previous year's revenue
    ROUND((ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) - 
           LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date))) 
          / 
          NULLIF(LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)), 0) * 100, 2) AS yoy_growth_percentage -- Calculate YoY Growth %
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date)
ORDER BY year;

-- YoY--

SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year,
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue,
    LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)) AS previous_revenue,
    ROUND((ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) - 
           LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date))) 
          / 
          LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)) * 100, 2) AS revenue_growth_rate
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date)
ORDER BY year;


-- Profit 
SELECT 
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS total_profit
FROM staging_sales s
JOIN staging_products p 
	ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
	ON s.currency_code = er.currency 
	AND s.order_date = er.date;

-- What is the Profit Margin?

SELECT 
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange) / SUM(s.quantity * p.unit_price * er.exchange) * 100, 2) AS profit_margin
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er ON s.currency_code = er.currency AND s.order_date = er.date;

-- 58%

-- What is the Yoy Profit Rate?

SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year, -- Extract the year from the order_date
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS total_profit, -- Calculate total profit for the year
    LAG(ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)) AS previous_profit, -- Get the previous year's profit
    ROUND((ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) - 
           LAG(ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date))) 
          / 
          NULLIF(LAG(ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)), 0) * 100, 2) AS yoy_profit_growth_percentage -- Calculate YoY Profit Growth %
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date)
ORDER BY year;

-- What are the revenue generated by different regions?
SELECT 
    COALESCE(st.country, 'Online') AS region, -- If the store_key is 0, set the region as 'Online'
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue -- Calculate total revenue
FROM staging_sales s
LEFT JOIN staging_stores st 
    ON s.store_key = st.store_key -- Match store_key for in-store sales
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY region
ORDER BY total_revenue DESC;


-- Product Analysis 
-- Sales for Product Category

SELECT 
    p.category,
    SUM(s.quantity * p.unit_price * er.exchange) AS total_sales_usd
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY p.category
ORDER BY total_sales_usd DESC;

-- Sales for Product Sub Category --
SELECT 
    p.subcategory,
    SUM(s.quantity * p.unit_price * er.exchange) AS total_sales_usd
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY p.subcategory
ORDER BY total_sales_usd DESC;
-- END --

-- Sales for Individual Products --
SELECT 
    p.product_name,
    SUM(s.quantity * p.unit_price * er.exchange) AS total_sales_usd
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY p.product_name
ORDER BY total_sales_usd DESC;
-- END --

-- Sales for Brands --
SELECT 
    p.brand,
    SUM(s.quantity * p.unit_price * er.exchange) AS total_sales_usd
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY p.brand
ORDER BY total_sales_usd DESC;
-- END --


-- Where are the customers located in --

SELECT c.country AS customer_country,
COUNT (DISTINCT c.customerkey) AS total_customers
FROM staging_customers c
LEFT JOIN staging_sales s ON c.customerkey = s.customerkey
GROUP BY c.country
ORDER BY total_customers DESC;

--- END ---

s.productkey, SUM(s.quantity) AS total_quantity
FROM staging_sales
GROUP BY productkey
ORDER BY total_quantity DESC;


--SEASONAL PATTERNS

-- How has Revenue and Profit changed over the years?

CREATE VIEW revenue_profit_by_year AS
SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year, -- Extract Year
    EXTRACT(MONTH FROM s.order_date) AS month, -- Extract Month
	COUNT(DISTINCT s.order_number) AS "Total Orders", -- Total Orders
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue, -- Monthly Revenue
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS total_profit -- Monthly Profit
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date), EXTRACT(MONTH FROM s.order_date)
ORDER BY year, month;

SELECT * FROM revenue_profit_by_year


-- REVENUE BY YEAR
CREATE OR REPLACE VIEW revenue_by_year AS
SELECT 
	EXTRACT (YEAR FROM s.order_date) AS "Year",
	EXTRACT(MONTH FROM s.order_date) AS "Month",
	COUNT(DISTINCT s.order_number) AS "Total Orders",
	SUM(s.quantity * p.unit_price * er.exchange) AS "Revenue Generated" --calculate revenue
FROM staging_sales AS s
JOIN staging_products AS p
	ON 	s.productkey = p.productkey
JOIN staging_exchange_rates AS er
	ON s.currency_code = er.currency
	AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date), EXTRACT(MONTH FROM s.order_date)
ORDER BY "Year", "Month";

SELECT * FROM revenue_by_year
--END--

-- ORDER DELIVERY TIME -- 

SELECT * FROM staging_sales

-- change delivery_date data type --
ALTER TABLE staging_sales
ALTER COLUMN delivery_date TYPE DATE USING TO_DATE(delivery_date, 'MM/DD/YYYY');
--end--


SELECT 
	order_number, line_item, order_date, delivery_date,
	(delivery_date - order_date) AS  "Delivery Days"
FROM staging_sales
WHERE delivery_date IS NOT NULL;

SELECT 
    ROUND(AVG(delivery_date - order_date)) AS avg_delivery_time
FROM staging_sales
WHERE delivery_date IS NOT NULL;

-- Over Years --

SELECT
	EXTRACT(YEAR FROM order_date) AS order_year,
	ROUND(AVG(delivery_date- order_date)) AS "Average Delivery Time"
FROM staging_sales
WHERE delivery_date IS NOT NULL
GROUP BY EXTRACT(YEAR from order_date)
ORDER BY order_year;

-- Over Months --

SELECT
	EXTRACT(YEAR FROM order_date) AS order_year,
	EXTRACT(MONTH FROM order_date) AS order_month,
	ROUND(AVG(delivery_date- order_date)) AS "Average Delivery Time"
FROM staging_sales
WHERE delivery_date IS NOT NULL
GROUP BY EXTRACT(YEAR from order_date), EXTRACT(MONTH from order_date)
ORDER BY order_year, order_month;

-- END -- 

-- What is the total sales volume?

SELECT 
    SUM(s.quantity) AS total_sales_volume -- Calculate the total quantity of products sold
FROM staging_sales s;


--What is the Average Order Value over the years?

SELECT 
    COUNT(DISTINCT s.order_number) AS total_orders, -- Total number of unique orders
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue, -- Total revenue
    ROUND(SUM(s.quantity * p.unit_price * er.exchange) / COUNT(DISTINCT s.order_number), 2) AS avg_order_value -- Calculate AOV
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date;

-- What is the AOV for each year?

SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year, -- Extract Year
    COUNT(DISTINCT s.order_number) AS total_orders, -- Total number of unique orders
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue, -- Total revenue
    ROUND(SUM(s.quantity * p.unit_price * er.exchange) / COUNT(DISTINCT s.order_number), 2) AS avg_order_value -- Calculate AOV
FROM staging_sales s
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date)
ORDER BY year;


-- AOV from online vs in-store sales -- 

-- Change data type first

SELECT DISTINCT store_key  FROM staging_sales ORDER BY store_key ASC;

ALTER TABLE staging_sales RENAME COLUMN storekey TO store_key;

ALTER TABLE staging_sales
ALTER COLUMN store_key TYPE INTEGER USING store_key::INTEGER

--

SELECT 
	st.store_key AS sales_channel,
	COUNT(DISTINCT s.order_number) AS total_orders,
	SUM (s.quantity * p.unit_price * er.exchange) AS total_revenue,
	SUM (s.quantity * p.unit_price * er.exchange) / COUNT(DISTINCT s.order_number) AS avg_order_value
FROM staging_sales s
JOIN staging_stores st
	ON s.store_key = st.store_key
JOIN staging_products p 
	ON s.productkey = p.productkey
JOIN staging_exchange_rates er
	ON s.currency_code = er.currency
	AND s.order_date = er.date
GROUP BY st.store_key
ORDER BY total_orders DESC;

--segment by region vs Online--
SELECT 
    COALESCE(st.country, 'Online') AS region,  -- Assign "Online" for online sales (store_key = 0)
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.quantity * p.unit_price * er.exchange) AS total_revenue,
    SUM(s.quantity * p.unit_price * er.exchange) / COUNT(DISTINCT s.order_number) AS avg_order_value
FROM staging_sales s
LEFT JOIN staging_stores st 
    ON s.store_key = st.store_key  -- Match store_key for in-store sales
JOIN staging_products p 
    ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency
    AND s.order_date = er.date
GROUP BY region
ORDER BY total_revenue DESC;


-- What are the gross profits for each product.

SELECT 
    p.product_name,
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS product_profit,
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange) / SUM(s.quantity * p.unit_price * er.exchange) * 100, 2) AS profit_margin
FROM staging_sales s
JOIN staging_products p 
	ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
	ON s.currency_code = er.currency 
	AND s.order_date = er.date
GROUP BY p.product_name
ORDER BY product_profit DESC;

-- What are the profit margins by region

SELECT 
    COALESCE(st.country, 'Online') AS region,
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS total_profit,
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange) / SUM(s.quantity * p.unit_price * er.exchange) * 100, 2) AS profit_margin
FROM staging_sales s
LEFT JOIN staging_stores st ON s.store_key = st.store_key
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY region
ORDER BY total_profit DESC;

-- END --