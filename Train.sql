-- Step 1: CREATE TABLE Train Superstore Dataset
DROP SCHEMA IF EXISTS public;

CREATE SCHEMA public;

DROP TABLE IF EXISTS public.TRAIN;

CREATE TABLE public.TRAIN (
	Row_ID INT PRIMARY KEY,
	Order_ID VARCHAR(50),
	Order_Date DATE,
	Ship_Date DATE,
	Ship_Mode VARCHAR(50),
	Customer_ID VARCHAR(50),
	Customer_Name VARCHAR(50),
	Segment VARCHAR(50),
	Country VARCHAR(50),
	City VARCHAR(50),
	State VARCHAR(50),
	Postal_Code VARCHAR(50),
	Region VARCHAR(50),
	Product_ID VARCHAR(50),
	Category VARCHAR(50),
	Sub_Category VARCHAR(50),
	Product_Name TEXT,
	Sales INT
);

--UPdate Train Sales datatype
ALTER TABLE public.TRAIN
ALTER COLUMN Sales TYPE NUMERIC(10,2) USING Sales::NUMERIC,
ALTER COLUMN Order_Date TYPE VARCHAR(10),
ALTER COLUMN  Ship_Date TYPE VARCHAR(10)
;

-- Step 2: import Train dataset csv file

COPY public.TRAIN
FROM 'G:/pgadmin SQL/train.csv'
WITH (
	FORMAT CSV,
	HEADER TRUE,
	DELIMITER ','
);

-- CHECK the Missing and Nulls Values 

SELECT * FROM public.TRAIN
WHERE Order_ID IS NULL 
	OR Product_ID IS NULL 
	OR Customer_ID IS NULL 
	OR Order_Date IS NULL
	OR Category IS NULL
	OR Sub_Category IS NULL
	OR Region IS NULL
	OR Sales IS NULL;

-- Total rows check Sales

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS missing_sales_count
FROM public.train;


-- Distinct vales are checked
SELECT
COUNT (*) AS Total_Transactions,
COUNT(DISTINCT Customer_ID) AS unique_customer_count,
COUNT(DISTINCT Product_ID) AS unique_customer_count
FROM public.TRAIN;

-- State Column me Case Inconsistency check karne ke liye:
SELECT 
    LOWER(State) AS state_lowercase,
    COUNT(DISTINCT State) AS different_case_variations,
    ARRAY_AGG(DISTINCT State) AS case_examples
FROM public.train
GROUP BY LOWER(State)
HAVING COUNT(DISTINCT State) > 1;

-- Permanent alteration
ALTER TABLE public.train 
ALTER COLUMN Order_Date TYPE DATE 
USING TO_DATE(Order_Date, 'DD/MM/YYYY');

-- Year wise trend check karna

SELECT
    EXTRACT(YEAR FROM Order_Date) AS Year,
    COUNT(*) AS Total_records,
    SUM(Sales) AS Total_Sales
FROM public.train
WHERE Order_Date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM Order_Date)
ORDER BY Year ASC;


-- Month wise trend check karna
SELECT
	TO_CHAR(Order_Date::DATE, 'MONTH') AS MONTH_NAME,
    EXTRACT(MONTH FROM Order_Date) AS MONTH_NUMBER,
    COUNT(*) AS Total_records,
    SUM(Sales) AS Total_Sales
FROM public.train
WHERE Order_Date IS NOT NULL
GROUP BY  
	TO_CHAR(Order_Date::DATE, 'MONTH'),
	EXTRACT(MONTH FROM Order_Date)
ORDER BY MONTH_NUMBER ASC;

-- combine check year-month trend
SELECT
	To_CHAR(Order_Date::DATE, 'YYYY-MM') AS Year_Month,
	COUNT(*) AS Total_records,
    SUM(Sales) AS Total_Sales
FROM public.train
WHERE Order_Date IS NOT NULL 
GROUP BY To_CHAR(Order_Date::DATE, 'YYYY-MM')
ORDER BY  Year_Month ASC;


--Category and Sub-Category Performance
WITH ranked_data AS (
    SELECT
        Category,
        Sub_Category,
        SUM(Sales) AS total_sales,
        DENSE_RANK() OVER(
            PARTITION BY Category
            ORDER BY SUM(Sales) DESC
        ) AS rank_number
    FROM public.train
    GROUP BY Category, Sub_Category
)
SELECT
    Category,
    Sub_Category,
    total_sales,
    rank_number
FROM ranked_data              
WHERE rank_number <= 10
ORDER BY Category, rank_number;

-- TOP 10 highest values customers
SELECT
    Category,
    Sub_Category,
    SUM(Sales) AS total_sales
FROM public.train
GROUP BY Category, Sub_Category
ORDER BY total_sales DESC
LIMIT 10;

-- region sales contribution
SELECT 
    Region,
    COUNT(DISTINCT Order_ID) AS total_orders,
    SUM(Sales) AS total_sales
FROM public.train
WHERE Region IS NOT NULL
GROUP BY Region
ORDER BY total_sales DESC;


SELECT * FROM public.TRAIN;
