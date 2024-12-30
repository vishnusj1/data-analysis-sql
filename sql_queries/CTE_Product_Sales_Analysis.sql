WITH ProductSalesSummary AS (
    SELECT 
        p.category,
        p.subcategory,
        p.product_name,
        p.brand,
        SUM(s.quantity * p.unit_price * er.exchange) AS total_sales_usd,
		SUM(s.quantity * p.unit_price * er.exchange) * 100.0 / 
        	SUM(SUM(s.quantity * p.unit_price * er.exchange)) OVER () AS sales_percentage
    FROM staging_sales s
    JOIN staging_products p 
        ON s.productkey = p.productkey
    JOIN staging_exchange_rates er 
        ON s.currency_code = er.currency
        AND s.order_date = er.date
    GROUP BY p.category, p.subcategory, p.product_name, p.brand
)

-- Sales for Product Category
SELECT 
    category,
    SUM(total_sales_usd) AS total_sales_usd,
	SUM(sales_percentage) AS sales_percentage
FROM ProductSalesSummary
GROUP BY category
ORDER BY sales_percentage DESC;

-- Sales for Product Sub Category
SELECT 
    subcategory,
    SUM(total_sales_usd) AS total_sales_usd
FROM ProductSalesSummary
GROUP BY subcategory
ORDER BY total_sales_usd DESC;

-- Sales for Individual Products
SELECT 
    product_name,
    SUM(total_sales_usd) AS total_sales_usd
FROM ProductSalesSummary
GROUP BY product_name
ORDER BY total_sales_usd DESC;

-- Sales for Brands
SELECT 
    brand,
    SUM(total_sales_usd) AS total_sales_usd
FROM ProductSalesSummary
GROUP BY brand
ORDER BY total_sales_usd DESC;
