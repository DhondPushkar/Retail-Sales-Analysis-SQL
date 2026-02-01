USE Pushkar;

SELECT TOP 100 * 
FROM Sales
ORDER BY transactions_id ASC;

select count(*) from Sales;

-- Data cleaning

-- Check for NULL values in any of the specified columns
SELECT * 
FROM Sales
WHERE sale_time IS NULL
   OR sale_date IS NULL
   OR gender IS NULL
   OR category IS NULL
   OR quantiy IS NULL  -- Note: check spelling (should be 'quantity'?)
   OR cogs IS NULL
   OR total_sale IS NULL;

-- ANALYSIS: Count NULL values in each column
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(sale_time) AS sale_time_nulls,
    COUNT(*) - COUNT(sale_date) AS sale_date_nulls,
    COUNT(*) - COUNT(gender) AS gender_nulls,
    COUNT(*) - COUNT(category) AS category_nulls,
    COUNT(*) - COUNT(quantiy) AS quantiy_nulls,
    COUNT(*) - COUNT(cogs) AS cogs_nulls,
    COUNT(*) - COUNT(total_sale) AS total_sale_nulls
FROM Sales;

-- ANALYSIS: Count how many columns are NULL per row
SELECT 
    *,
    (CASE WHEN sale_time IS NULL THEN 1 ELSE 0 END +
     CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END +
     CASE WHEN gender IS NULL THEN 1 ELSE 0 END +
     CASE WHEN category IS NULL THEN 1 ELSE 0 END +
     CASE WHEN quantiy IS NULL THEN 1 ELSE 0 END +
     CASE WHEN cogs IS NULL THEN 1 ELSE 0 END +
     CASE WHEN total_sale IS NULL THEN 1 ELSE 0 END) AS null_count
FROM Sales
WHERE sale_time IS NULL
   OR sale_date IS NULL
   OR gender IS NULL
   OR category IS NULL
   OR quantiy IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL
ORDER BY null_count DESC;

-- STRATEGY 1: Delete rows with multiple NULL values (e.g., 3 or more NULLs)
-- First, see how many rows would be deleted
SELECT COUNT(*) AS rows_to_delete
FROM Sales
WHERE (CASE WHEN sale_time IS NULL THEN 1 ELSE 0 END +
       CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END +
       CASE WHEN gender IS NULL THEN 1 ELSE 0 END +
       CASE WHEN category IS NULL THEN 1 ELSE 0 END +
       CASE WHEN quantiy IS NULL THEN 1 ELSE 0 END +
       CASE WHEN cogs IS NULL THEN 1 ELSE 0 END +
       CASE WHEN total_sale IS NULL THEN 1 ELSE 0 END) >= 3;

-- Actually delete rows with 3 or more NULL values
-- DELETE FROM Sales
-- WHERE (CASE WHEN sale_time IS NULL THEN 1 ELSE 0 END +
--        CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END +
--        CASE WHEN gender IS NULL THEN 1 ELSE 0 END +
--        CASE WHEN category IS NULL THEN 1 ELSE 0 END +
--        CASE WHEN quantiy IS NULL THEN 1 ELSE 0 END +
--        CASE WHEN cogs IS NULL THEN 1 ELSE 0 END +
--        CASE WHEN total_sale IS NULL THEN 1 ELSE 0 END) >= 3;

-- STRATEGY 2: Fill single NULL values with appropriate defaults
-- Update NULL gender with most common gender
UPDATE Sales 
SET gender = (
    SELECT TOP 1 gender 
    FROM Sales 
    WHERE gender IS NOT NULL 
    GROUP BY gender 
    ORDER BY COUNT(*) DESC
)
WHERE gender IS NULL;

-- Update NULL category with most common category
UPDATE Sales 
SET category = (
    SELECT TOP 1 category 
    FROM Sales 
    WHERE category IS NOT NULL 
    GROUP BY category 
    ORDER BY COUNT(*) DESC
)
WHERE category IS NULL;

-- Update NULL quantity with average quantity (rounded)
UPDATE Sales 
SET quantiy = (
    SELECT ROUND(AVG(CAST(quantiy AS FLOAT)), 0)
    FROM Sales 
    WHERE quantiy IS NOT NULL
)
WHERE quantiy IS NULL;

-- Update NULL cogs with average cogs
UPDATE Sales 
SET cogs = (
    SELECT AVG(cogs)
    FROM Sales 
    WHERE cogs IS NOT NULL
)
WHERE cogs IS NULL;

-- Update NULL total_sale with average total_sale
UPDATE Sales 
SET total_sale = (
    SELECT AVG(total_sale)
    FROM Sales 
    WHERE total_sale IS NOT NULL
)
WHERE total_sale IS NULL;

-- For date/time fields, you might want to use specific business logic
-- Example: Set NULL sale_date to a default date
-- UPDATE Sales 
-- SET sale_date = '2024-01-01'  -- or GETDATE() for current date
-- WHERE sale_date IS NULL;

-- Example: Set NULL sale_time to a default time
-- UPDATE Sales 
-- SET sale_time = '12:00:00'  -- or current time
-- WHERE sale_time IS NULL;

-- ORIGINAL DELETE QUERY (commented out for safety)
-- DELETE FROM Sales
-- WHERE sale_time IS NULL
--    OR sale_date IS NULL
--    OR gender IS NULL
--    OR category IS NULL
--    OR quantiy IS NULL
--    OR cogs IS NULL
--    OR total_sale IS NULL;

-- Data Exploration
SELECT COUNT(*) AS total_records FROM Sales; -- How many sales we have?
SELECT COUNT(DISTINCT customer_id) AS unique_customers FROM Sales; -- How many unique customers we have?
SELECT DISTINCT category FROM Sales; -- What categories do we have?

-- Additional useful queries
SELECT category, COUNT(*) AS count_per_category
FROM Sales
GROUP BY category
ORDER BY count_per_category DESC;

SELECT gender, COUNT(*) AS count_per_gender
FROM Sales
WHERE gender IS NOT NULL
GROUP BY gender;

-- Explore categories and products
SELECT 
    category,
    COUNT(*) AS transaction_count,
    ROUND(SUM(total_sale), 2) AS total_revenue,
    ROUND(AVG(total_sale), 2) AS avg_transaction_value,
    SUM(quantiy) AS total_quantity_sold,
    ROUND(AVG(CAST(quantiy AS FLOAT)), 2) AS avg_quantity_per_transaction,
    ROUND(MIN(total_sale), 2) AS min_transaction,
    ROUND(MAX(total_sale), 2) AS max_transaction
FROM Sales 
GROUP BY category 
ORDER BY total_revenue DESC;

-- Customer demographics analysis
SELECT 
    gender,
    COUNT(*) AS transactions,
    ROUND(SUM(total_sale), 2) AS total_spent,
    ROUND(AVG(total_sale), 2) AS avg_spent_per_transaction,
    CASE 
        WHEN AVG(age) - FLOOR(AVG(age)) >= 0.5 THEN CEILING(AVG(age))
        ELSE FLOOR(AVG(age))
    END AS avg_age,
    CAST(MIN(age) AS INT) AS youngest_customer,
    CAST(MAX(age) AS INT) AS oldest_customer,
    ROUND(AVG(total_sale) * COUNT(*), 2) AS total_contribution
FROM Sales 
WHERE gender IS NOT NULL AND age IS NOT NULL
GROUP BY gender
ORDER BY total_spent DESC;


-- Data analysis and bussiness key problems
-- Q.1 Write a SQL query to retrieve all columns for sales made on '2022-11-05'
SELECT *
FROM sales
WHERE sale_date = '2022-11-05';

-- Q.2 Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 4 in the month of Nov-2022
SELECT *
FROM sales
WHERE 
    category = 'Clothing'
    AND 
    FORMAT(CAST(sale_date AS DATE), 'yyyy-MM') = '2022-11'
    AND
    quantiy >= 4;

-- Q.3 Write a SQL query to calculate the total sales (total_sale) for each category.
SELECT 
    category,
    SUM(total_sale) AS net_sale,
    COUNT(*) AS total_orders
FROM sales
GROUP BY category;

-- Q.4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.
SELECT
    ROUND(AVG(CAST(age AS FLOAT)), 2) AS avg_age
FROM sales
WHERE category = 'Beauty';

-- Q.5 Write a SQL query to find all transactions where the total_sale is greater than 1000.
SELECT * 
FROM sales
WHERE total_sale > 1000;

-- Q.6 Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category.
SELECT 
    category,
    gender,
    COUNT(*) AS total_trans
FROM sales
GROUP BY category, gender
ORDER BY category;

-- Q.7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year
SELECT 
    year,
    month,
    avg_sale
FROM 
(    
    SELECT 
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month,
        AVG(total_sale) AS avg_sale,
        RANK() OVER(PARTITION BY YEAR(sale_date) ORDER BY AVG(total_sale) DESC) AS rank
    FROM sales
    GROUP BY YEAR(sale_date), MONTH(sale_date)
) AS t1
WHERE rank = 1
ORDER BY year;

-- Q.8 Write a SQL query to find the top 5 customers based on the highest total sales 
SELECT TOP 5
    customer_id,
    SUM(total_sale) AS total_sales
FROM sales
GROUP BY customer_id
ORDER BY total_sales DESC;

-- Q.9 Write a SQL query to find the number of unique customers who purchased items from each category.
SELECT 
    category,    
    COUNT(DISTINCT customer_id) AS cnt_unique_cs
FROM sales
GROUP BY category;

-- Q.10 Write a SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)
WITH hourly_sale AS
(
    SELECT *,
        CASE
            WHEN DATEPART(HOUR, sale_time) < 12 THEN 'Morning'
            WHEN DATEPART(HOUR, sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS shift
    FROM sales
)
SELECT 
    shift,
    COUNT(*) AS total_orders    
FROM hourly_sale
GROUP BY shift
ORDER BY 
    CASE shift 
        WHEN 'Morning' THEN 1 
        WHEN 'Afternoon' THEN 2 
        WHEN 'Evening' THEN 3 
    END;


-- Additional enhanced versions with better formatting:

-- Q.7 Enhanced - with month names and better formatting
SELECT 
    year,
    month_num,
    month_name,
    ROUND(avg_sale, 2) AS avg_sale
FROM 
(    
    SELECT 
        YEAR(sale_date) AS year,
        MONTH(sale_date) AS month_num,
        DATENAME(MONTH, sale_date) AS month_name,
        AVG(total_sale) AS avg_sale,
        RANK() OVER(PARTITION BY YEAR(sale_date) ORDER BY AVG(total_sale) DESC) AS rank
    FROM sales
    GROUP BY YEAR(sale_date), MONTH(sale_date), DATENAME(MONTH, sale_date)
) AS t1
WHERE rank = 1
ORDER BY year;

-- Q.8 Enhanced - with percentage of total sales
WITH customer_sales AS (
    SELECT 
        customer_id,
        SUM(total_sale) AS total_sales
    FROM sales
    GROUP BY customer_id
),
total_revenue AS (
    SELECT SUM(total_sale) AS overall_total
    FROM sales
)
SELECT TOP 5
    cs.customer_id,
    ROUND(cs.total_sales, 2) AS total_sales,
    ROUND((cs.total_sales * 100.0 / tr.overall_total), 2) AS percentage_of_total
FROM customer_sales cs
CROSS JOIN total_revenue tr
ORDER BY cs.total_sales DESC;







    







