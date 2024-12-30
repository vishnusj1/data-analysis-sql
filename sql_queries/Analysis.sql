-- 1. Data Cleaning and Transformation

-- Rename columns for consistency and clarity
ALTER TABLE staging_sales RENAME COLUMN "Line Item" TO line_item;
ALTER TABLE staging_sales RENAME COLUMN "Delivery Date" TO delivery_date;
ALTER TABLE staging_sales RENAME COLUMN "Currency Code" TO currency_code;

-- Change column data types for consistency
ALTER TABLE staging_sales
ALTER COLUMN order_date TYPE DATE USING TO_DATE(order_date, 'MM/DD/YYYY');
ALTER TABLE staging_sales
ALTER COLUMN delivery_date TYPE DATE USING TO_DATE(delivery_date, 'MM/DD/YYYY');
ALTER TABLE staging_sales
ALTER COLUMN order_number TYPE INTEGER USING order_number::INTEGER;
ALTER TABLE staging_sales
ALTER COLUMN quantity TYPE INTEGER USING quantity::INTEGER;
ALTER TABLE staging_sales
ALTER COLUMN productkey TYPE INTEGER USING productkey::INTEGER;
ALTER TABLE staging_sales
ALTER COLUMN customerkey TYPE INTEGER USING customerkey::INTEGER;
ALTER TABLE staging_sales
ALTER COLUMN storekey TYPE INTEGER USING storekey::INTEGER;

-- Check for missing or invalid data
SELECT * FROM staging_sales WHERE productkey IS NULL OR quantity IS NULL;

-- Verify consistency with related tables
SELECT s.productkey
FROM staging_sales s
LEFT JOIN staging_products p ON s.productkey = p.productkey
WHERE p.productkey IS NULL;


-- 2. KPI's

-- Total Revenue Generated YTD
SELECT 
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue_ytd
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date;

-- YoY Revenue Growth
SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year,
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue,
    LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)) AS previous_revenue,
    ROUND(
        (ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) - 
         LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date))) 
         / NULLIF(LAG(ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2)) OVER (ORDER BY EXTRACT(YEAR FROM s.order_date)), 0) * 100, 2
    ) AS yoy_growth_percentage
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date)
ORDER BY year;

-- Profit and Profit Margin

-- Total Profit
SELECT 
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS total_profit
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date;

-- Profit Margin
SELECT 
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange) / SUM(s.quantity * p.unit_price * er.exchange) * 100, 2) AS profit_margin
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date;

-- 3. Revenue Analysis by Segment

-- By Region
SELECT 
    COALESCE(st.country, 'Online') AS region,
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue
FROM staging_sales s
LEFT JOIN staging_stores st ON s.store_key = st.store_key
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY region
ORDER BY total_revenue DESC;

-- 4. By Product Category
SELECT 
    p.category,
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 4. Operational Metrics

-- Avegare Delivery Time 
SELECT 
    ROUND(AVG(delivery_date - order_date), 2) AS avg_delivery_time
FROM staging_sales
WHERE delivery_date IS NOT NULL;


-- Seasonal Trends

-- Monthly Revenue Trends
CREATE OR REPLACE VIEW revenue_by_month AS
SELECT 
    EXTRACT(YEAR FROM s.order_date) AS year,
    EXTRACT(MONTH FROM s.order_date) AS month,
    ROUND(SUM(s.quantity * p.unit_price * er.exchange), 2) AS total_revenue
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY EXTRACT(YEAR FROM s.order_date), EXTRACT(MONTH FROM s.order_date)
ORDER BY year, month;

SELECT * FROM revenue_by_month;

-- 5. Additional Insights
-- Provide granular insights to inform business decisions.

-- Profit by Product

SELECT 
    p.product_name,
    ROUND(SUM(s.quantity * (p.unit_price - p.unit_cost) * er.exchange), 2) AS product_profit
FROM staging_sales s
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY p.product_name
ORDER BY product_profit DESC;


-- Online vs. In-Store AOV
SELECT 
    COALESCE(st.country, 'Online') AS sales_channel,
    ROUND(SUM(s.quantity * p.unit_price * er.exchange) / COUNT(DISTINCT s.order_number), 2) AS avg_order_value
FROM staging_sales s
LEFT JOIN staging_stores st ON s.store_key = st.store_key
JOIN staging_products p ON s.productkey = p.productkey
JOIN staging_exchange_rates er 
    ON s.currency_code = er.currency AND s.order_date = er.date
GROUP BY sales_channel
ORDER BY avg_order_value DESC;

--






