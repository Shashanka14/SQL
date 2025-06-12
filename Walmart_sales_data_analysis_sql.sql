#Walmart_sales_data_analysis_sql
-- Data Wrangling: This is the first step where inspection of data is done.
-- Build a database
-- Create table and insert the data.
-- There are no null values in our database as in creating the tables, we set NOT NULL for each field, hence null values are filtered out.

-- Create database
CREATE DATABASE IF NOT EXISTS walmartSales;


-- Create table
CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT,
    gross_income DECIMAL(12, 4),
    rating FLOAT
);


SELECT * FROM sales;


-- Feature Engineering: This will help use generate some new columns from existing ones.

-- Add a new column named time_of_day to give insight of sales in the Morning, Afternoon and Evening. 
-- This will help answer the question on which part of the day most sales are made.

SELECT
	time,
	(CASE
		WHEN time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN time BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END) AS time_of_day
FROM sales;

ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

UPDATE sales
SET time_of_day = (
	CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
);


-- Add a new column named day_name that contains the extracted days of the week on which the given transaction took place (Mon, Tue, Wed, Thur, Fri).
-- This will help answer the question on which week of the day each branch is busiest.

SELECT
	date,
	DAYNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(date);


-- Add a new column named month_name that contains the extracted months of the year on which the given transaction took place (Jan, Feb, Mar...). 
-- This will help determine which month of the year has the most sales and profit.

SELECT 
date, MONTHNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales 
SET month_name = MONTHNAME(date);


-- Exploratory Data Analysis (EDA): Exploratory data analysis is done to answer the questions and aims of this project.

-- --------------------------------------------------------------Generic Questions--------------------------------------------------------------------

-- Q1. How many unique cities does the data have?
SELECT 
	DISTINCT city
FROM sales;

-- Q2. In which city is each branch?
SELECT 
	DISTINCT branch
FROM sales;

SELECT 
	DISTINCT city,branch
FROM sales;


-- Questions on the Products

-- Q3. How many unique product lines does the data have?

SELECT 
DISTINCT(product_line)
FROM sales;

SELECT 
COUNT(DISTINCT(product_line))
FROM sales;

-- Q4. What is the most common payment method?

SELECT 
payment, COUNT(*)
FROM sales
GROUP BY payment; 

SELECT payment, COUNT(*) AS payment_method_count
FROM sales
GROUP BY payment
HAVING COUNT(*) = (SELECT COUNT(*) AS max_count
    FROM sales
    GROUP BY payment
    ORDER BY max_count DESC
    LIMIT 1
    ); 
    
-- Q5. What is the most selling product line?

SELECT product_line, COUNT(*) AS product_line_count
FROM sales
GROUP BY product_line
HAVING product_line_count= (
	SELECT 
	 COUNT(*) max_count
	FROM sales
	GROUP BY product_line
	ORDER BY max_count DESC
	LIMIT 1
    );
    
-- Q6. What is the total revenue by month?

SELECT 
	month_name as month, 
	SUM(total) as total_revenue
FROM sales
GROUP BY month
ORDER BY total_revenue desc;

-- Q7. What month had the largest COGS?

 SELECT 
	month_name AS month, 
    SUM(cogs) AS COGS
FROM sales
GROUP BY month_name
ORDER BY COGS DESC
LIMIT 1;

-- Q8. What product line had the largest revenue?

SELECT product_line, total_revenue
FROM (
	SELECT product_line, SUM(total) AS total_revenue
	FROM sales
	GROUP BY product_line
    ) AS revenue_by_product
WHERE total_revenue = (
	SELECT MAX(total_revenue)
	FROM(
		SELECT 
		SUM(total) AS total_revenue
		FROM sales
		GROUP BY product_line
	) AS max_revenue
);

-- Q9. What is the city with the largest revenue?

SELECT city, total_revenue
FROM (
	SELECT city,SUM(total) AS total_revenue
		FROM sales
		GROUP BY city
        ) AS revenue_by_city
WHERE total_revenue = (
	SELECT MAX(total_revenue)
	FROM(
		SELECT
			SUM(total) AS total_revenue
		FROM sales
		GROUP BY city 
		ORDER BY total_revenue DESC
		)AS max_revenue
	);
    
-- Q10. What product line had the largest VAT?

SELECT product_line, VAT
FROM (
	SELECT product_line,SUM(tax_pct) AS VAT
    FROM sales
    GROUP BY product_line
    ) AS VAT_by_product
    WHERE VAT =(
	SELECT MAX(VAT)
	FROM (
		SELECT SUM(tax_pct) AS VAT
		FROM sales
		GROUP BY product_line
		) AS max_vat
        );

-- Q11. Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales.

SELECT product_line,
       CASE
           WHEN total_sales > average_sales THEN 'Good'
           ELSE 'Bad'
       END AS sales_category
FROM (
    SELECT product_line, SUM(total) AS total_sales,
           AVG(SUM(total)) OVER () AS average_sales
    FROM sales
    GROUP BY product_line
) AS product_sales;

-- Q12. Which branch sold more products than average product sold? 

SELECT branch, total_sales
FROM(
	SELECT branch, SUM(quantity) AS total_sales, AVG(SUM(quantity)) OVER() AS avg_sales
	FROM sales
	GROUP BY branch) AS branch_sales
WHERE total_sales > avg_sales;


-- Q13. What is the most common product line by gender?

SELECT gender, product_line
FROM(
	SELECT gender, product_line,
		ROW_NUMBER() OVER (PARTITION BY gender ORDER BY count DESC) AS rnk
	FROM	
			(
			SELECT product_line, gender, COUNT(*) AS count
			FROM sales
			GROUP BY product_line, gender
			) AS gender_product_count
		) As ranked_data
	WHERE rnk=1;
    
-- Q14. What is the average rating of each product line?

SELECT product_line, ROUND(AVG(rating),2) AS average_rating
FROM sales
GROUP BY product_line;


-- ----------------------------------------------------------Questions on the Sales-------------------------------------------------------------------------

-- Q15. Number of sales made in each time of the day per weekday

SELECT  day_name, time_of_day,COUNT(*) as sales_count
FROM sales
GROUP BY day_name,time_of_day
ORDER BY  
		CASE 
        WHEN day_name = 'Sunday' THEN 1
        WHEN day_name = 'Monday' THEN 2
        WHEN day_name = 'Tuesday' THEN 3
        WHEN day_name = 'Wednesday' THEN 4
        WHEN day_name = 'Thursday' THEN 5
        WHEN day_name = 'Friday' THEN 6
        ELSE 7
    END,
    time_of_day;

-- Q16. Which of the customer types brings the most revenue?

SELECT customer_type, SUM(total) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC
LIMIT 1;

-- Q17. Which city has the largest tax percent/ VAT (Value Added Tax)?

SELECT
	city, ROUND(AVG(tax_pct), 2) AS avg_tax_pct
FROM sales
GROUP BY city 
ORDER BY avg_tax_pct DESC
LIMIT 1;

-- Q18. Which customer type pays the most in VAT?

SELECT customer_type, SUM(tax_pct) AS VAT
FROM sales 
GROUP BY customer_type
ORDER BY VAT DESC
LIMIT 1;

-- ------------------------------------------------------------Questions on the Customers-------------------------------------------------------------


-- Q19. How many unique customer types does the data have?

SELECT 
	COUNT(DISTINCT customer_type) AS unique_customer_types
FROM sales;

-- Q20. How many unique payment methods does the data have?

SELECT 
	COUNT(DISTINCT payment) AS unique_payment_methods
FROM sales;

-- Q21. What is the most common customer type?

SELECT customer_type, COUNT(*) AS type_count
FROM sales
GROUP BY customer_type
ORDER BY type_count DESC
LIMIT 1;

-- Q22. Which customer type buys the most?

SELECT customer_type, SUM(total) AS total_purchases
FROM sales
GROUP BY customer_type
ORDER BY total_purchases DESC
LIMIT 1;

-- Q23. What is the gender of most of the customers?

SELECT gender, COUNT(*) gender_count
FROM sales
GROUP BY gender
ORDER BY gender_count DESC
LIMIT 1;

-- Q24. What is the gender distribution per branch?

SELECT branch, gender, COUNT(*) as gender_count
FROM sales
GROUP BY branch, gender
ORDER BY gender_count DESC;

-- Q25. Which time of the day do customers give most ratings?

SELECT time_of_day, COUNT(rating) AS rating_count
FROM sales
GROUP BY time_of_day
ORDER BY rating_count DESC 
LIMIT 1;

-- Q26. Which time of the day do customers give most ratings per branch?

SELECT branch, time_of_day, COUNT(rating) AS rating_count
FROM sales
GROUP BY  branch, time_of_day
ORDER BY rating_count  DESC;

-- Q27. Which day of the week has the best avg ratings?

SELECT 
    day_name,AVG(rating) AS avg_rating
FROM 
   sales
GROUP BY 
    day_name
ORDER BY 
    avg_rating DESC
LIMIT 1;

-- Q28. Which day of the week has the best average ratings per branch?

SELECT 
    branch,
	day_name,
    AVG(rating) AS avg_rating
FROM 
    sales
GROUP BY 
    branch, day_name
ORDER BY 
    branch, avg_rating DESC;
