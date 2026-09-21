
/* ================================================================================================
	PROJECT      : Superstore Sales & Profitability Analysis (SQL Server)
	AUTHOR       : Shivanand S. Mathapati
	DATASET      : Sample Superstore Dataset (9,994 records) (Kaggle)
	TOOLS USED   : Microsoft SQL Server, T-SQL (CTEs, Views, Window Functions, Subqueries)

	
	BUSINESS PROBLEM
	------------------------------------------------------------------------------------------------
	Our company has experienced strong sales growth but declining profitability. Analyze the data
	and identify the root causes, key issues, and actionable recommendations.


	SCRIPT STRUCTURE
	------------------------------------------------------------------------------------------------
	1. Database & schema setup
	2. Data validation (row counts, nulls, duplicates, invalid values) + primary key constraint
	3. Sales Analysis
	4. Profit Analysis
	5. Customer Analysis
	6. Product Analysis
	7. Geographical Analysis
	8. Shipping & Operations Analysis
	9. Discount Analysis
	10. Time Based Analysis
	11. Key Insights (Summary)
	12. Business Root Causes
	13. Actionable Recommendations
	================================================================================================ */


----------------------------- DATABASE & SCHEMA SETUP -----------------------------

-- CREATING DATABASE
CREATE DATABASE SQLSalesProject;
GO


-- USING DATABASE
USE SQLSalesProject;
GO


-- CREATING SCHEMA
CREATE SCHEMA Sales;
GO


-- DESCRIBING TABLE 'SUPERSTORE'
EXEC sp_help 'sales.superstore';


-- DISPLAYING TABLE DETAILS 
SELECT * FROM Sales.superstore;


-- COUNTING NO. OF ROWS PRESENT IN TABLE
SELECT COUNT(*) FROM Sales.superstore; -- 9994 Records


-- CREATING DUPLICATE OF ORIGINAL TABLE (FOR CLEANING)
SELECT *
INTO Sales.superstorecopy
FROM Sales.superstore;




----------------------------- DATA VALIDATION ------------------------------


-- ROW COUNT CHECK
SELECT
	COUNT(*) AS 'Total Rows'
FROM Sales.superstorecopy;
/* Table holds 9994 records. */


-- DUPLICATE ROW CHECK
SELECT
	RowID,
	COUNT(*) AS 'Occurrence'
FROM Sales.superstorecopy
GROUP BY RowID
HAVING COUNT(*) > 1;
/* No duplicate RowIDs were found, confirming that RowID uniquely identifies each record and is suitable for use as the Primary Key.
	(although a Primary Key is not required for this project). */


-- NULL CHECK ACROSS SOME KEY COLUMNS
SELECT
	SUM(CASE WHEN RowID IS NULL THEN 1 ELSE 0 END) AS 'Nulls in RowID',
	SUM(CASE WHEN OrderID IS NULL THEN 1 ELSE 0 END) AS 'Nulls in OrderID',
	SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS 'Nulls in OrderDate',
	SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS 'Nulls in CustomerID',
	SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS 'Nulls in ProductID',
	SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS 'Nulls in Sales',
	SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS 'Nulls in Profit',
	SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS 'Nulls in Discount',
	SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS 'Nulls in Quantity'
FROM Sales.superstorecopy;
/* No null values were found across all key business and transactional columns, confirming that the dataset is complete and suitable
	for sales, customer, product, profitability, and operational analysis. */



-- NEGATIVE OR INVALID VALUE CHECK
SELECT
	SUM(CASE WHEN Sales < 0 THEN 1 ELSE 0 END) AS 'Negative Sales',
	SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS 'Invalid Quantities',
	SUM(CASE WHEN ( Discount < 0 OR Discount > 1)THEN 1 ELSE 0 END) AS 'Invalid Discount',
	SUM(CASE WHEN ShipDate < OrderDate THEN 1 ELSE 0 END) AS 'Invalid OrderDate'
FROM Sales.superstorecopy;
/* No negative sales, invalid quantities, out-of-range discounts, or ship dates are greater than order dates were found,
	so confirming that the dataset satisfies key business rules and is suitable for analysis. */


-- DATE RANGE VALIDATION
SELECT
	MIN(OrderDate) AS 'First Order Date',
	MAX(OrderDate) AS 'Last Order Date',
	MIN(ShipDate) AS 'First Ship Date',
	MAX(ShipDate) AS 'Last Ship Date'
FROM Sales.superstorecopy;
/* The dataset covers four years of business transactions from January 2014 to December 2017. Shipping records extend to
	January 2018 due to orders placed at the end of 2017 that were delivered in the following year. */



---------------- PRIMARY KEY CONSTRAINT --------------------


ALTER TABLE Sales.superstorecopy
ALTER COLUMN RowID INT NOT NULL;
GO

ALTER TABLE Sales.superstorecopy
ADD CONSTRAINT pk_superstorecopy_rowid PRIMARY KEY (RowID)
GO
/* RowID is enforced as the Primary Key, ensuring that each record is uniquely identified and preventing duplicate or null values. */



------------------------ ANALYSIS ------------------------


-- NOW I AM USING ' SALES.SUPERSTORECOPY' TABLE
SELECT * FROM Sales.superstorecopy; -- 9994 Records


-- VERIFYING COLUMNS
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Sales' AND TABLE_NAME = 'superstorecopy';



----------------- SALES ANALYSIS -------------------------


-- TOTAL SALES
SELECT
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy;
/* The company generated total sales revenue of $2.30 million during the analysis period. */


-- TOTAL ORDERS
SELECT
	COUNT(DISTINCT OrderID) AS 'Total Orders'
FROM Sales.superstorecopy;
/* The dataset contains 5,009 unique orders. */


-- AVERAGE ORDER VALUE / AVERAGE SALES PER ORDER
SELECT
	ROUND(SUM(Sales)/COUNT(DISTINCT OrderID), 2) AS 'Avg Order Value'
FROM Sales.superstorecopy;
/* The average order value is $458.61, indicating the average revenue generated per order. */


-- LATEST YEAR SALES CONTRIBUTION VS PREVIOUS YEARS(ALL)
WITH YearSales AS (
SELECT
    YEAR(OrderDate) AS OrderYear,
    SUM(Sales) AS TotalSales
FROM Sales.superstorecopy
GROUP BY YEAR(OrderDate)
),
MaxYear AS (
SELECT
	MAX(OrderYear) AS LatestYear
FROM YearSales
),
PreSales AS (
SELECT
	SUM(TotalSales) AS PreviousSales
FROM YearSales ys
CROSS JOIN MaxYear my
WHERE ys.OrderYear < my.LatestYear
),
CurSales AS (
SELECT
	SUM(TotalSales) AS CurrentSales
FROM YearSales
)
SELECT
	CONCAT(ROUND(100*(cs.CurrentSales - ps.PreviousSales)/ps.PreviousSales, 2), '%') AS 'OverAll Sales Growth'
FROM CurSales cs
CROSS JOIN PreSales ps;
/* The latest year contributed sales equal to 46.88% of all previous years combined. */


-- TOTAL CUSTOMERS
SELECT
	COUNT(DISTINCT CustomerID) AS 'Total Customers'
FROM Sales.superstorecopy;
/* A total of 793 unique customers contributed to the overall sales revenue. */


-- AVERAGE SALES PER CUSTOMERS
SELECT
	ROUND(
		SUM(Sales)/COUNT(DISTINCT CustomerID),
	2) AS 'Avg Revenue per Customer'
FROM Sales.superstorecopy;
/* On average, each customer generated $2,896.85 in sales revenue during the analysis period. */


-- YEAR-OVER-YEAR (YOY) SALES GROWTH
WITH CTE AS(
SELECT
	YEAR(OrderDate) AS OrderYear,
	SUM(Sales) AS TotalSales
FROM Sales.superstorecopy
GROUP BY YEAR(OrderDate)
)
SELECT
	OrderYear AS 'Order Year',
	ROUND(TotalSales, 2) AS 'Total Sales',
	ROUND(LAG(TotalSales) OVER(ORDER BY OrderYear), 2) AS 'Previous Sales',
	ROUND(
		100 * (TotalSales - LAG(TotalSales) OVER(ORDER BY OrderYear)) / LAG(TotalSales) OVER(ORDER BY OrderYear),
	2) AS 'YoY Growth'
FROM CTE;
/* Sales declined by 2.83% in 2015 but rebounded strongly in 2016 with 29.47% growth, followed by a further 20.36% increase in 2017. */


-- SEASONAL SALES ANALYSIS / MONTHLY SALES ANALYSIS (OVERALL)
WITH CTE AS(
SELECT
	MONTH(OrderDate) AS 'MonthNo',
	DATENAME(MONTH, OrderDate) AS 'MonthName',
	SUM(Sales) AS 'TotalSales'
FROM Sales.superstorecopy
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
)
SELECT
	MonthName AS 'Order Month',
	ROUND(TotalSales, 2) AS 'Total Sales',
	ROUND(
		100 * (TotalSales - LAG(TotalSales) OVER(ORDER BY MonthNo)) / LAG(TotalSales) OVER(ORDER BY MonthNo),
	2) AS 'MoM Growth'
FROM CTE;
/* Sales exhibit strong seasonality, with September and November recording the highest growth rates of 93.44% and 75.95%, respectively.
	November generated the highest sales ($352.46K), while February recorded the lowest sales ($59.75K). */


-- MONTH-OVER-MONTH (MOM) SALES GROWTH ANALYSIS
WITH MSales AS(
SELECT
	YEAR(OrderDate) AS 'OrderYear',
	MONTH(OrderDate) AS 'MonthNo',
	DATENAME(MONTH, OrderDate) AS 'MonthName',
	SUM(Sales) AS 'TotalSales'
FROM Sales.superstorecopy
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
)
SELECT
	OrderYear AS 'Order Year',
	MonthName AS 'Order Month',
	ROUND(TotalSales, 2) AS 'Total Sales',
	ROUND(
		100 * (TotalSales - LAG(TotalSales) OVER(ORDER BY OrderYear, MonthNo)) / LAG(TotalSales) OVER(ORDER BY OrderYear, MonthNo),
	2) AS 'MoM Growth'
FROM MSales;
/* Sales exhibit strong seasonality, with consistent peaks in September–November
	and noticeable declines in January–February across multiple years. */


-- QUARTERLY SALES DISTRIBUTION ANALYSIS (OVERALL)
SELECT
	DATEPART(QUARTER, OrderDate) AS 'Quarter No',
	CONCAT(ROUND(SUM(Sales)/1000,2), 'K') AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY DATEPART(QUARTER, OrderDate)
ORDER BY [Quarter No];
/* Q4 is the strongest quarter, generating $878.08K in sales, while Q1 is the weakest at $359.68K. */


-- QUARTER-OVER-QUARTER (QOQ) SALES GROWTH ANALYSIS
WITH QSales AS(
SELECT
	YEAR(OrderDate) AS 'Order Year',
	DATEPART(QUARTER, OrderDate) AS 'Quarter',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY YEAR(OrderDate), DATEPART(QUARTER, OrderDate) 
)
SELECT
	*,
	ROUND(
		100 * ([Total Sales] - LAG([Total Sales]) OVER(ORDER BY [Order Year], Quarter))
		/
		NULLIF(
			LAG([Total Sales]) OVER(ORDER BY [Order Year], Quarter),
		0),
	2) AS 'QoQ Growth'
FROM QSales;
/* Q1 experiences consistent sales declines, while Q3 and Q4 drive growth.
	Q4 2017 was the best-performing quarter, generating $280.05K in sales. */


-- CATEGORY WISE SALES & CONTRIBUTION ANALYSIS
SELECT
	Category AS 'Category Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT('$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)',
	CONCAT(
		ROUND(
			100 * SUM(Sales)/SUM(SUM(Sales)) OVER(),
		2),
	' %') AS Contribution
FROM Sales.superstorecopy
GROUP BY Category
ORDER BY [Total Sales] DESC;
/* Technology is the highest revenue-generating category, contributing 36.4% of total sales ($836K), 
	followed by Furniture (32.3%) and Office Supplies (31.3%) */


-- TOP 10 STATES BY SALES
SELECT TOP (10)
	State AS 'State Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT('$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)'
FROM Sales.superstorecopy
GROUP BY State
ORDER BY [Total Sales] DESC;
/* California is the highest revenue-generating state with $458K in sales, followed by New York ($311K) and Texas ($170K).
	Together, these three states contribute a significant share of overall revenue. */


-- TOP 10 CITIES BY SALES
SELECT TOP(10)
	City,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT('$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)'
FROM Sales.superstorecopy
GROUP BY City
ORDER BY [Total Sales] DESC;
/* New York City is the highest revenue-generating city with $256K in sales, followed by Los Angeles ($176K) and Seattle ($120K).
	These cities serve as key revenue hubs for the business. */


-- TOP 10 PRODUCTS BY SALES
SELECT TOP (10)
	ProductName AS 'Product Name',
	ROUND(SUM(Sales), 0) AS 'Total Sales',
	CONCAT('$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)'
FROM Sales.superstorecopy
GROUP BY ProductName
ORDER BY [Total Sales] DESC;
/* Canon imageCLASS 2200 Advanced Copier is the highest revenue-generating product, contributing $62K in sales. */


-- BOTTOM 10 PRODUCTS BY SALES
SELECT TOP (10)
	ProductName AS 'Product Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY ProductName
ORDER BY [Total Sales] ASC;
/* Several products recorded negligible sales, with the lowest-selling product generating only $1.62 in revenue. */


-- CATEGORY WISE TOP 05 BEST SELLING PRODUCTS BY SALES
WITH rnk AS (
SELECT
	Category,
	ProductName,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	RANK() OVER(PARTITION BY Category ORDER BY SUM(Sales) DESC) AS rn
FROM Sales.superstorecopy
GROUP BY Category, ProductName
)
SELECT *
FROM rnk
WHERE rn <= 5;
/* Technology products dominate revenue generation, with the Canon imageCLASS 2200 Advanced Copier leading all products at $62K in sales.
	Office Supplies and Furniture also have a few standout products that contribute significantly to category revenue. */


-- CUSTOMER SEGMENT WISE SALES & CONTRIBUTION ANALYSIS
SELECT
	Segment,
	ROUND(SUM(sales), 2) AS 'Total Sales', -- SUM(Sales) = sales for each segment 
	CONCAT(
	ROUND(
		100*SUM(Sales)/SUM(SUM(Sales)) OVER(),  -- SUM(SUM(Sales)) = Total sales across all the segments.
		2),
		' %') AS SalesContribution 
FROM Sales.superstorecopy
GROUP BY Segment
ORDER BY [Total Sales] DESC;
/* The Consumer segment is the primary revenue driver, contributing 50.56% of total sales ($1.16M - half of total sales).
	Corporate and Home Office segments contribute 30.74% and 18.70%, respectively. */


-- REGION WISE SALES & CONTRIBUTION ANALYSIS
SELECT
	Region,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT('$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)',
	CONCAT( ROUND(100 * SUM(Sales)/SUM(SUM(Sales)) OVER(), 2), ' %') AS Contribution
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Total Sales] DESC;
/* The West region is the highest revenue-generating region, contributing 31.58% of total sales ($725K),
	followed closely by the East region at 29.55% ($679K). Together, these two regions account for over 61% of total revenue. */


-- SALES BY CUSTOMER SEGMENT & REGION
SELECT
	Region,
	Segment,
	ROUND(SUM(Sales), 0) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY Region, Segment
ORDER BY Region, Segment;
/* The Consumer segment generates the highest sales across all regions, with the West ($363K) and East ($351K) regions
	contributing the most revenue. Home Office is the smallest segment in every region. */


-- SUB CATEGORY WISE SALES & CONTRIBUTION ANALYSIS
SELECT
	SubCategory,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT('$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)',
	CONCAT( ROUND(100 * SUM(Sales)/SUM(SUM(Sales)) OVER(), 2), ' %') AS Contribution
FROM Sales.superstorecopy
GROUP BY SubCategory
ORDER BY [Total Sales] DESC;
/* Phones and Chairs are the highest revenue-generating sub-categories, each contributing around 14% of total sales. */


-- SHIP MODE SALES ANALYSIS
SELECT
	ShipMode,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT(
		ROUND(
			100 * SUM(Sales)/SUM(SUM(Sales)) OVER(),
		2),
	' %') AS SalesContribution
FROM Sales.superstorecopy
GROUP BY ShipMode
ORDER BY [Total Sales] DESC;
/* Standard Class is the most preferred shipping mode, generating 59.12% of total sales ($1.36M).
	and Same Day delivery contributes only 5.59% of sales, indicating limited demand for shipping. */


-- TOP 10 CUSTOMERS BY SALES
SELECT TOP (10)
	CustomerName AS 'Customer Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	CONCAT( '$ ', ROUND(SUM(Sales)/1000, 0), 'K') AS 'Total Sales(K)'
FROM Sales.superstorecopy
GROUP BY CustomerName
ORDER BY [Total Sales] DESC;
/* Sean Miller is the top customer by sales, generating $25K in revenue, but contributes a loss instead of a profit. */


-- CUMULATIVE SALES ACROSS ENTIRE BUSINESS
WITH MonthSales AS (
SELECT
	YEAR(OrderDate) AS 'Order Year',
	MONTH(OrderDate) AS 'MonthNo',
	DATENAME(MONTH, OrderDate) AS 'Order Month',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
)
SELECT
	[Order Year],
	[Order Month],
	[Total Sales],
	ROUND(
		SUM([Total Sales]) OVER(ORDER BY [Order Year], MonthNo ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
	2) AS 'Running Total'
FROM MonthSales;


-- RUNNING TOTAL SALES TREND (YEAR-TO-DATE SALES TREND) ANALYSIS
WITH MonthSales AS (
SELECT
	YEAR(OrderDate) AS 'Order Year',
	MONTH(OrderDate) AS 'MonthNo',
	DATENAME(MONTH, OrderDate) AS 'Order Month',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY YEAR(OrderDate), MONTH(OrderDate), DATENAME(MONTH, OrderDate)
)
SELECT
	[Order Year],
	[Order Month],
	[Total Sales],
	ROUND(
		SUM([Total Sales]) OVER(PARTITION BY [Order Year] ORDER BY [Order Year], MonthNo ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
	2) AS 'YTD Sales'
FROM MonthSales;


-- MONTH-TO-DATE(MTD) SALES TREND ANALYSIS
SELECT
	OrderDate,
	ROUND(Sales, 2) AS 'Total Sales',
	ROUND(
		SUM(Sales) OVER(PARTITION BY YEAR(OrderDate), MONTH(OrderDate) ORDER BY OrderDate),
	2) AS 'MTD Sales'
FROM Sales.superstorecopy;





-------------------------- PROFIT ANALYSIS --------------------------------


--TOTAL PROFIT
SELECT
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	CONCAT('$ ', ROUND(SUM(Profit)/1000, 2), 'K') AS 'Total Profit(K)'
FROM Sales.superstorecopy;
/* The business generated a total profit of $286.82K during the analysis period. */


-- PROFIT MARGIN
SELECT
	CONCAT(
		ROUND(100 * (SUM(Profit) / SUM(Sales)), 2),
	' %') AS 'Profit Margin'
FROM Sales.superstorecopy;
/* The business achieved a profit margin of 12.49%, meaning it retained approximately $12.49 in profit for every $100 of sales */


-- AVERAGE DISCOUNT
SELECT
	CONCAT(
		ROUND(100 * AVG(Discount), 2),
	' %') AS 'Avg Discount'
FROM Sales.superstorecopy;
/* Customers received an average discount of 15.62% across all orders. */


-- HOW MANY ORDERS MAKING PROFIT LOSS (LOSS MAKING ORDERS)
SELECT
	COUNT(DISTINCT OrderID) AS 'Loss Making Orders'
FROM Sales.superstorecopy
WHERE Profit < 0;
/* Out of 5,009 total orders, 1,318 orders (~ 26%) generated a loss during the analysis period */


-- PROFIT PER ORDER
SELECT
	ROUND (SUM(Profit) / COUNT(DISTINCT OrderID), 2) AS 'Profit per Order'
FROM Sales.superstorecopy;
/* On average, every order contributed $57.26 to the overall profit. */


-- REGION WISE PROFIT & CONTRIBUTION ANALYSIS
SELECT
	Region,
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(
		100 * SUM(Profit) / SUM(SUM(Profit)) OVER(),
	2) AS Contribution
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Total Profit] DESC;
/* The West region is the most profitable region, contributing 37.8% of total profit ($108.4K),
	followed by the East region at 31.9% ($91.5K). Together, these two regions generate nearly 70% of overall profit. */


-- SHIP MODE WISE PROFIT & CONTRIBUTION ANALYSIS
SELECT
	ShipMode AS 'Ship Mode',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(100 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS 'Contribution %',
	ROUND(100 * SUM(Profit) / SUM(Sales), 2) AS 'Profit Margin %'
FROM Sales.superstorecopy
GROUP BY ShipMode
ORDER BY [Total Profit] DESC;
/* Standard Class generates the highest profit, while First Class has the highest profit margin (contributes less profit) */


-- CUSTOMER SEGMENT WISE PROFIT & CONTRIBUTION ANALYSIS
SELECT
	Segment,
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(
		100 * SUM(Profit) / SUM(SUM(Profit)) OVER(),
	2) AS 'Contribution %'
FROM Sales.superstorecopy
GROUP BY Segment
ORDER BY [Total Profit] DESC;
/* The Consumer segment is the most profitable segment, generating $134.1K in profit and contributing 46.76% of total profit. */


-- CATEGORY WISE PROFIT & CONTRIBUTION ANALYSIS
SELECT
	Category,
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(
		100 * SUM(Profit) / SUM(SUM(Profit)) OVER(),
	2) AS 'Contribution %'
FROM Sales.superstorecopy
GROUP BY Category
ORDER BY [Total Profit] DESC;
/* Technology is the most profitable category, contributing 50.71% of total profit ($145.45K),
	followed by Office Supplies at 42.71%. Furniture contributes only 6.58% of total profit despite generating over $742K in sales. */


-- SUB CATEGORY WISE PROFIT & CONTRIBUTION ANALYSIS
SELECT
	SubCategory,
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(
		100 * SUM(Profit) / SUM(SUM(Profit)) OVER(),
	2) AS 'Contribution %'
FROM Sales.superstorecopy
GROUP BY SubCategory
ORDER BY [Total Profit] DESC;
/* Copiers are the most profitable sub-category, contributing 19.39% of total profit, followed by Phones and Accessories.
	Although Tables and Chairs are among the highest sales-generating sub-categories,
	Tables are the largest loss-making sub-category, while Chairs remain profitable.
	Tables, Bookcases, and Supplies negatively impact overall profitability. */


-- TOP 10 STATES BY PROFIT
SELECT TOP (10)
	State,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY State
ORDER BY [Total Profit] DESC;
/* California is the most profitable state, generating the highest total profit, followed by New York */


-- PROFIT LOSS MAKING STATES
SELECT
	State,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY State
HAVING SUM(Profit) < 0
ORDER BY [Total Profit] ASC;
/* Approximately 20% of states (10 out of 49) generated negative profit, with Texas contributing the largest total loss.*/


-- TOP 10 CITIES BY PROFIT
SELECT TOP (10)
	City,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY City
ORDER BY [Total Profit] DESC;
/* New York City is the most profitable city, generating the highest total profit among all 531 cities. */


-- PROFIT LOSS MAKING CITIES
SELECT
	City,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY City
HAVING SUM(Profit) < 0
ORDER BY [Total Profit] ASC;
/* Out of 531 cities, 116 cities (22%) are loss-making.
	Philadelphia (Pennsylvania state), records the highest loss (-$13.84K), making it the least profitable city. */


-- TOP 10 PRODUCTS BY PROFIT
SELECT TOP (10)
	ProductName,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY ProductName
ORDER BY [Total Profit] DESC;
/* The Canon imageCLASS 2200 Advanced Copier is both the highest sales-generating and most profitable product. */



-- LOSS MAKING PRODUCTS
SELECT
	ProductID,
	ProductName AS 'Product Name',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY ProductID, ProductName
HAVING SUM(Profit) < 0
ORDER BY [Total Profit];
/* A total of 305 products are loss-making,
with the Cubify CubeX 3D Printer Double Head Print recording the highest loss (-$8.88K) among all products. */


-- TOP 10 CUSTOMERS BY PROFIT
SELECT TOP(10)
	CustomerName AS 'Customer Name',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY CustomerName
ORDER BY [Total Profit] DESC;
/* Tamara Chand is the most profitable customer, generating $8.98K in profit,
	followed by Raymond Buch ($6.98K) and Sanjit Chand ($5.76K).
	While Sean Miller is the highest sales-generating customer, Tamara Chand is the most profitable customer,
	showing that higher sales do not always result in higher profit. */


-- BOTTOM 10 CUSTOMERS BY PROFIT / CUSTOMERS WHO ARE MAKING LOSS
SELECT TOP(10)
	CustomerName AS 'Customer Name',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY CustomerName
ORDER BY [Total Profit] ASC; 
/* Sean Miller is the highest sales-generating customer but appears among the bottom 10 customers by profit, 
	indicating that high sales do not always lead to high profit. */





------------------- CUSTOMER ANALYSIS ----------------------------



-- TOTAL CUSTOMERS
SELECT
	COUNT(DISTINCT CustomerID) AS 'Total Customers'
FROM Sales.superstorecopy;
/* The business served 793 unique customers during the analysis period */


-- AVERAGE SALES PER CUSTOMER
SELECT
	ROUND( SUM(Sales) / COUNT(DISTINCT CustomerID), 2) AS 'Avg Sales per Customer'
FROM Sales.superstorecopy;
/* Each customer contributed an average of $2.9K in sales. */



-- AVERAGE ORDERS PER CUSTOMER
SELECT
	ROUND( COUNT(DISTINCT OrderID) / COUNT(DISTINCT CustomerID), 2) AS 'Avg Sales per Customer'
FROM Sales.superstorecopy;
/* Each customer placed an average of 6 orders. */


-- REPEAT CUSTOMERS (%)
WITH CustomerOrders AS (
SELECT
	CustomerID,
	COUNT(DISTINCT OrderID) AS 'Total Orders'
FROM Sales.superstorecopy
GROUP BY CustomerID
)
SELECT
	COUNT(*) AS 'Repeat Customers',
	CAST(
		100.00 * COUNT(*) / (SELECT COUNT(DISTINCT CustomerID) FROM Sales.superstorecopy)
	AS DECIMAL(5,2)) AS 'Repeat Customers(%)'
FROM CustomerOrders
WHERE [Total Orders] > 1;
/* 98.49% of customers (781) placed more than one order, indicating a strong repeat purchase rate and high customer retention. */


-- TOP CUSTOMER VALUE
SELECT TOP(1)
	CustomerID,
	CustomerName AS 'Customer Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY CustomerID, CustomerName
ORDER BY [Total Sales] DESC;
/* Sean Miller is the highest-value customer, generating $25.04K in total sales. */


-- SEGMENT WISE CUSTOMERS & SALES CONTRIBUTION
SELECT
	Segment,
	COUNT(DISTINCT CustomerID) AS 'Total Customers',
	ROUND(100* SUM(Sales) / SUM(SUM(Sales)) OVER(), 2) AS 'Sales (%)'
FROM Sales.superstorecopy
GROUP BY Segment;
GO
/* Consumer is the largest and most valuable customer segment, contributing over half (50.56%) of total sales. */


-- CUSTOMERS DETAILS
CREATE VIEW Sales.vw_customersdetails AS
SELECT
	CustomerID,
	CustomerName,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	COUNT(DISTINCT OrderID) AS 'Total Orders',
	CASE
		WHEN SUM(PRofit) > 0 THEN 'Profit'
		ELSE 'Loss'
	END AS 'Profit Status'
FROM Sales.superstorecopy
GROUP BY CustomerID, CustomerName;
GO

-- CUSTOMERS DETAILS
SELECT *
FROM Sales.vw_customersdetails
ORDER BY [Total Sales] DESC;


-- TOP 10 CUSTOMERS BY SALES
SELECT TOP(10)
	CustomerID,
	CustomerName,
	[Total Sales]
FROM Sales.vw_customersdetails
ORDER BY [Total Sales] DESC;


-- BOTTOM 10 CUSTOMERS BY SALES
SELECT TOP(10)
	CustomerID,
	CustomerName,
	[Total Sales]
FROM Sales.vw_customersdetails
ORDER BY [Total Sales] ASC;


-- LOSS MAKING CUSTOMERS
SELECT *
FROM Sales.vw_customersdetails
WHERE [Profit Status] = 'Loss'
ORDER BY [Total Profit] ASC;
/* Sean Miller is the highest revenue-generating customer ($25.04K sales) but remains loss-making,
	while Cindy Stewart is the most unprofitable customer with a loss of $6.63K. */


-- CUSTOMER CONCENTRATION (80/20 RULE) OR TOP 20 % CUSTOMERS SALES CONTRIBUTION
WITH CustomerSales AS (
SELECT
	CustomerID,
	SUM(Sales) AS 'Total Sales',
	COUNT(CustomerID) OVER() AS 'Total Customers',
	ROW_NUMBER() OVER(ORDER BY SUM(Sales) DESC) AS 'rnk'
FROM Sales.superstorecopy
GROUP BY CustomerID
)
SELECT
	CASE
		WHEN rnk <= CEILING([Total Customers]*0.20)  -- CEILING = Rounds a number 'UP' to the nearest whole number.
		THEN 'Top 20% Customers'
		ELSE 'Remaining 80% Customers'
	END AS 'Customer Group',
	ROUND(
		100 * SUM([Total Sales]) / SUM(SUM([Total Sales])) OVER(),
	2) AS 'Sales Contribution (%)'
FROM CustomerSales
GROUP BY CASE
		WHEN rnk <= CEILING([Total Customers]*0.20)
		THEN 'Top 20% Customers'
		ELSE 'Remaining 80% Customers'
	END
ORDER BY [Sales Contribution (%)] ASC;
/* The top 20% of customers contribute 48.15% of total sales, while the remaining 80% contribute 51.85%.
	This indicates that revenue is relatively concentrated among a small group of high-value customers. */


-- NEW VS RETURNING CUSTOMERS
WITH CustomerStatus AS (
SELECT
	CustomerID,
	CASE
		WHEN COUNT(DISTINCT OrderID) > 1 THEN 'Returning'
		ELSE 'New'
	END AS 'Customers Status'
FROM Sales.superstorecopy
GROUP BY CustomerID
)
SELECT
	[Customers Status],
	CAST(
		100.00 * COUNT(*) / SUM(COUNT(*)) OVER()
	AS DECIMAL(5,2)) AS 'Customers(%)'
FROM CustomerStatus
GROUP BY [Customers Status];
/* Nearly all customers (98.49%) are returning customers, demonstrating high customer loyalty and retention. */





-------------------- PRODUCT ANALYSIS --------------------------


-- TOTAL PRODUCTS
SELECT
	COUNT(DISTINCT ProductID)
FROM Sales.superstorecopy;
/* The business sold 1,862 unique products across all categories. */


-- BEST SELLING PRODUCT
SELECT TOP(1)
	ProductID,
	ProductName AS 'Product Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY ProductID, ProductName
ORDER BY [Total Sales] DESC;
/* Canon imageCLASS 2200 Advanced Copier is the top-selling product with $61.60K in sales. */


-- MOST PROFITABLE PRODUCT
SELECT TOP(1)
	ProductID,
	ProductName AS 'Product Name',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY ProductID, ProductName
ORDER BY [Total Profit] DESC;
/* Canon imageCLASS 2200 Advanced Copier is the most profitable product, generating $25.20K in profit. */


-- AVERAGE PROFIT MARGIN PER PRODUCT
WITH ProfitMargin AS (
SELECT
	ProductID,
	100 * (SUM(Profit) / SUM(Sales)) AS 'Profit Margin'
FROM Sales.superstorecopy
GROUP BY ProductID
HAVING SUM(Sales) > 0
)
SELECT
	ROUND(AVG([Profit Margin]), 2) AS 'Avg. Profit Margin per Product'
FROM ProfitMargin;
/* Average profit margin per product is 19.6% & the overall business profit margin is lower at 12.49%. */


-- LOSS MAKING PRODUCTS
SELECT
	ProductID,
	ProductName AS 'Product Name',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY ProductID, ProductName
HAVING SUM(Profit) < 0
ORDER BY [Total Profit];
/* 305 products are unprofitable overall. */


-- PRODUCTS WITH AT LIST ONE LOSS MAKING SALE
SELECT 
	COUNT(DISTINCT ProductID) AS 'Loss Making Products'
FROM Sales.superstorecopy
WHERE Profit < 0;
/* 762 products experienced at least one loss-making sale. */
/* Although only 300 products are unprofitable overall, 762 products experienced at least one loss-making sale. */

-- AVERAGE SALES PER PRODUCT
SELECT
	ROUND( SUM(Sales) / COUNT(DISTINCT ProductID), 2) AS 'Avg Sales per Product'
FROM Sales.superstorecopy;
/* On average, each product contributes $1,233.73 in sales. */


-- AVERAGE PROFIT PER PRODUCT
SELECT
	ROUND( SUM(Profit) / COUNT(DISTINCT ProductID), 2) AS 'Avg Profit per Product'
FROM Sales.superstorecopy;
/* While each product generates an average sales value of $1,233.73 and an average profit of $154.04, 
	approximately 41% of products are loss-making, indicating that profitability is concentrated among a small set of products. */


-- TOTAL CATEGORIES AND SUB CATEGORIES
SELECT
	COUNT(DISTINCT Category) AS 'Total Categories',
	COUNT(DISTINCT SubCategory) AS 'Total Sub-Categories'
FROM Sales.superstorecopy;
/* The product portfolio consists of 3 categories and 17 sub-categories. */


-- MOST SELLING CATEGORY
SELECT TOP(1)
	Category AS 'Most Selling Category',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY Category
ORDER BY [Total Sales] DESC;


-- MOST PROFITABLE CATEGORY
SELECT TOP(1)
	Category AS 'Most Profitable Category',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY Category
ORDER BY [Total Profit] DESC;
/* Technology is both the highest-selling and most profitable category, generating $836.15K in sales and $145.45K in profit, 
	making it the strongest-performing category in the business. */


-- MOST SELLING SUB CATEGORY
SELECT TOP(1)
	SubCategory AS 'Most Selling Sub Category',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY SubCategory
ORDER BY [Total Sales] DESC;


-- MOST PROFITABLE SUB CATEGORY
SELECT TOP(1)
	SubCategory AS 'Most Profitable Sub Category',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY SubCategory
ORDER BY [Total Profit] DESC;
/* Phones is the highest-selling sub-category, generating $330.01K in sales, while Copiers is the most profitable sub-category, 
	contributing $55.62K in profit. This indicates that the highest revenue-generating products are not always the most profitable. */


-- LOSS MAKING SUB CATEGORIES
SELECT
	SubCategory AS 'Loss Making Sub Categories',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY SubCategory
HAVING SUM(Profit) < 0
ORDER BY [Total Profit] ASC;
GO
/* Tables, Bookcases, and Supplies are the only loss-making sub-categories.
	Among them, Tables records the highest loss of $17.31K, making it the biggest drag on overall profitability. */


-- PRODUCT DETAILS
CREATE VIEW Sales.vw_ProductDetails AS
SELECT
	ProductID,
	ProductName AS 'Product Name',
	Category,
	SubCategory AS 'Sub Category',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	COUNT(DISTINCT OrderID) AS 'Total Orders',
	SUM(Quantity) AS 'Quantity Sold'
FROM Sales.superstorecopy
GROUP BY ProductID, ProductName, Category, SubCategory;
GO


-- PRODUCT DETAILS
SELECT *
FROM Sales.vw_ProductDetails
ORDER BY [Total Sales] DESC;


-- TOP 10 PRODUCTS BY SALES
SELECT TOP(10)
	[Product Name],
	[Total Sales]
FROM Sales.vw_ProductDetails
ORDER BY [Total Sales] DESC;


-- TOP 10 PRODUCTS BY PROFIT
SELECT TOP(10)
	[Product Name],
	[Total Profit]
FROM Sales.vw_ProductDetails
ORDER BY [Total Profit] DESC;


-- AVERAGE PROFIT MARGIN BY CATEGORY
SELECT
	Category,
	ROUND(100.0*SUM(Profit)/SUM(Sales), 2) AS 'Profit Margin'
FROM Sales.superstorecopy
GROUP BY Category
ORDER BY [Profit Margin] DESC;
/* Technology has the highest overall profit margin at 17.40%, closely followed by Office Supplies at 17.04%. */


-- AVERAGE PROFIT MARGIN PER PRODUCT BY CATEGORY
WITH ProfitMargin AS(
SELECT
	ProductID,
    Category,
    100.0 * SUM(Profit) / SUM(Sales) AS 'Profit Margin'
FROM Sales.superstorecopy
GROUP BY ProductID, Category
)
SELECT
	Category,
	ROUND(AVG([Profit Margin]), 2) AS 'Avg. Profit Margin per Product by Category'
FROM ProfitMargin
GROUP BY Category
ORDER BY [Avg. Profit Margin per Product by Category] DESC;
/* Office Supplies has the highest average profit margin per product at 25.51%, followed by Technology at 14.46%.
	Furniture records the lowest average product profit margin at 8.10%. */

/*Average Product Profit Margin by Category: Office Supplies (25.51%) > Technology (14.46%) > Furniture (8.10%)
	Overall Category Profit Margin: Technology (17.40%) > Office Supplies (17.04%) > Furniture (2.54%). */






---------------------- GEOGRAPHICAL ANALYSIS ---------------------------


-- TOTAL STATES
SELECT
	COUNT(DISTINCT State) AS 'Total States'
FROM Sales.superstorecopy;


-- TOTAL CITIES
SELECT
	COUNT(DISTINCT City) AS 'Total Cities'
FROM Sales.superstorecopy;


-- AVERAGE SALES PER STATE
SELECT
	ROUND(
		SUM(Sales)/COUNT(DISTINCT State),
	2) AS 'Avg. Sales per State'
FROM Sales.superstorecopy;


-- AVERAGE PROFIT PER STATE
SELECT
	ROUND(
		SUM(Profit)/COUNT(DISTINCT State),
	2) AS 'Avg. Profit per State'
FROM Sales.superstorecopy;


-- HIGHEST SALES GENERATING REGION
SELECT TOP(1)
	Region,
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Total Sales] DESC;


-- LOWEST SALES GENERATING REGION
SELECT TOP(1)
	Region,
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Total Sales] ASC;


-- MOST PROFITABLE REGION
SELECT TOP(1)
	Region,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Total Profit] DESC;


-- LEAST PROFITABLE REGION
SELECT TOP(1)
	Region,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Total Profit] ASC;


-- STATES CONTRIBUTION TO TOTAL SALES
SELECT
	State AS 'State Name',
	ROUND(
		100.0 * SUM(Sales)/SUM(SUM(Sales)) OVER(),
	2) AS 'Contribution(%)'
FROM Sales.superstorecopy
GROUP BY State
ORDER BY [Contribution(%)] DESC;


-- STATES CONTRIBUTION TO TOTAL PROFIT
SELECT
	State AS 'State Name',
	ROUND(
		100.0 * SUM(Profit)/SUM(SUM(Profit)) OVER(),
	2) AS 'Contribution(%)'
FROM Sales.superstorecopy
GROUP BY State
ORDER BY [Contribution(%)] DESC;


-- CITIES CONTRIBUTION TO TOTAL SALES
SELECT
	City AS 'City Name',
	ROUND(
		100.0 * SUM(Sales)/SUM(SUM(Sales)) OVER(),
	2) AS 'Contribution(%)'
FROM Sales.superstorecopy
GROUP BY City
ORDER BY [Contribution(%)] DESC;


-- CITIES CONTRIBUTION TO TOTAL PROFIT
SELECT
	City AS 'City Name',
	ROUND(
		100.0 * SUM(Profit)/SUM(SUM(Profit)) OVER(),
	2) AS 'Contribution(%)'
FROM Sales.superstorecopy
GROUP BY City
ORDER BY [Contribution(%)] DESC;


-- REGION WISE SALES CONTRIBUTION
SELECT
	Region,
	ROUND(
		100.0 * SUM(Sales)/SUM(SUM(Sales)) OVER(),
	2) AS 'Contribution(%)'
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Contribution(%)] DESC;


-- REGION WISE PROFIT CONTRIBUTION
SELECT
	Region,
	ROUND(
		100.0 * SUM(Profit)/SUM(SUM(Profit)) OVER(),
	2) AS 'Contribution(%)'
FROM Sales.superstorecopy
GROUP BY Region
ORDER BY [Contribution(%)] DESC;


-- MOST PROFITABLE STATE
SELECT TOP(1)
	State,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY State
ORDER BY [Total Profit] DESC;


-- HIGHEST SALES GENERATING STATE
SELECT TOP(1)
	State,
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY State
ORDER BY [Total Sales] DESC;


-- MOST PROFITABLE CITY
SELECT TOP(1)
	City,
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.superstorecopy
GROUP BY City
ORDER BY [Total Profit] DESC;


-- HIGHEST SALES GENERATING CITY
SELECT TOP(1)
	City,
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.superstorecopy
GROUP BY City
ORDER BY [Total Sales] DESC;
GO




---------------------- SHIPPING & OPERATION ANALYSIS ----------------------------


-- AVERAGE DELIVERY DAYS
CREATE VIEW Sales.vw_ShippingDetails AS
SELECT
	OrderID,
	OrderDate,
	ShipDate,
	ShipMode,
	DATEDIFF(DAY, OrderDate, ShipDate) AS 'DeliveryDays',
	CASE
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) < =
             CASE
                 WHEN ShipMode = 'Same Day' THEN 1
                 WHEN ShipMode = 'First Class' THEN 3
                 WHEN ShipMode = 'Second Class' THEN 4
                 WHEN ShipMode = 'Standard Class' THEN 5
             END
        THEN 1
        ELSE 0
    END AS 'OnTimeLate',

    CASE
        WHEN DATEDIFF(DAY, OrderDate, ShipDate) <=
             CASE
                 WHEN ShipMode = 'Same Day' THEN 1
                 WHEN ShipMode = 'First Class' THEN 3
                 WHEN ShipMode = 'Second Class' THEN 4
                 WHEN ShipMode = 'Standard Class' THEN 5
             END
        THEN 'On Time Delivery'
        ELSE 'Late Delivery'
    END AS 'OnTimeLateStatus',
	CustomerID,
	CustomerName,
	Segment,
	Region,
	State,
	City,
	ProductID,
	ProductName,
	Category,
	SubCategory,
	Sales,
	Profit,
	Quantity,
	Discount
FROM Sales.superstorecopy;
GO


-- SHIPPING DETAILS
SELECT *
FROM Sales.vw_ShippingDetails;


-- AVERAGE DELIVERY DAYS
SELECT
	ROUND(AVG(CAST(DeliveryDays AS FLOAT)), 0) AS 'Avg. Delivery Days'
FROM Sales.vw_ShippingDetails;
/* Orders are delivered in an average of 4 days */


-- TOTAL ORDERS SHIPPED
SELECT
	COUNT(DISTINCT OrderID)
FROM Sales.vw_ShippingDetails;


-- ON-TIME DELIVERY RATE %
SELECT
	CAST(100.00 * SUM(OnTimeLate)/COUNT(*) AS DECIMAL(5,2)) AS 'On Time Delivery Rate'
FROM Sales.vw_ShippingDetails;
/* 77.45% of orders were delivered on time, indicating a reliable shipping process.
	However, 22.55% of orders experienced delays, suggesting opportunities to improve delivery performance. */


-- MOST USED SHIP MODE
SELECT TOP(1)
	ShipMode,
	COUNT(DISTINCT OrderID) AS 'Total Orders'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Total Orders] DESC;
/* Standard Class is the most used shipping mode with 2,994 orders (Out of 5009 Orders).
	This suggests that customers prioritize cost-effective shipping over faster delivery services such as First Class or Same Day. */



-- AVERAGE ORDER VALUE
SELECT
	ROUND(SUM(Sales)/COUNT(DISTINCT OrderID), 2) AS 'Avg. Order Value'
FROM Sales.vw_ShippingDetails;
/* The Average order value is $458.61. */


-- AVERAGE SHIPPING DAYS BY SHIP MODE
SELECT
	ShipMode AS 'Ship Mode',
	ROUND(AVG(CAST(DeliveryDays AS FLOAT)), 0) AS 'Avg. Delivery Days'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Avg. Delivery Days] ASC;
/* Same Day is the fastest shipping mode, while Standard Class
	has the highest average delivery time among all shipping modes. */



-- FASTEST SHIPPING MODE
SELECT TOP(1)
	ShipMode AS 'Fastest Ship Mode',
	ROUND(AVG(CAST(DeliveryDays AS FLOAT)), 0) AS 'Avg. Delivery Days'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Avg. Delivery Days] ASC;
/* Same Day is the fastest shipping mode, providing the shortest average delivery time to customers. */



-- SLOWEST SHIPPING MODE
SELECT TOP(1)
	ShipMode AS 'Slowest Ship Mode',
	ROUND(AVG(CAST(DeliveryDays AS FLOAT)), 0) AS 'Avg. Delivery Days'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Avg. Delivery Days] DESC;
/* Standard Class is the slowest shipping mode, recording the
	highest average delivery time among all shipping options. */



-- ORDERS DELIVERED WITHIN 2 DAYS
SELECT
	COUNT(DISTINCT OrderID) AS 'Orders Delivered within 2 days',
	CAST(
		100.0 * COUNT(DISTINCT OrderID) / (SELECT COUNT(DISTINCT OrderID) FROM Sales.superstorecopy)
	AS DECIMAL(5, 2)) AS 'Orders %'
FROM Sales.vw_ShippingDetails
WHERE DeliveryDays < 3;
/* 1,109 orders (22.14% of total orders) were delivered within 2 days.
	Roughly 1 in 5 orders reaches customers within 2 days. */


-- DELAYED ORDERS DELIVERY (MORE THAN 5 DAYS)
SELECT
	COUNT(DISTINCT OrderID) AS 'Delayed Orders',
	CAST(
		100.0 * COUNT(DISTINCT OrderID) / (SELECT COUNT(DISTINCT OrderID) FROM Sales.superstorecopy)
	AS DECIMAL(5, 2)) AS 'Orders %'
FROM Sales.vw_ShippingDetails
WHERE DeliveryDays > 5;
/* A total of 904 orders (18.05% of all orders) took more than 5 days to be delivered. */

/* 22.14% of orders were delivered within 2 days, while 18.05% took more than 5 days. */


-- SHIP MODE WISE SALES & CONTRIBUTION ANALYSIS
SELECT
	ShipMode AS 'Ship Mode',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND( 100 * SUM(Sales) / SUM(SUM(Sales)) OVER(), 2) AS 'Contribution %'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Total Sales] DESC;


-- SHIP MODE WISE PROFIT & CONTRIBUTION ANALYSIS
SELECT
	ShipMode AS 'Ship Mode',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND( 100 * SUM(Profit) / SUM(SUM(Profit)) OVER(), 2) AS 'Contribution %'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Total Profit] DESC;


-- SHIP MODE WISE TOTAL ORDERS
SELECT
	ShipMode AS 'Ship Mode',
	COUNT(DISTINCT OrderID) AS 'Total Orders'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Total Orders] DESC;


-- SHIP MODE WISE QUANTITY SOLD
SELECT
	ShipMode AS 'Ship Mode',
	SUM(Quantity) AS 'Total Quantity Sold'
FROM Sales.vw_ShippingDetails
GROUP BY ShipMode
ORDER BY [Total Quantity Sold] DESC;


-- REGION WISE AVERAGE SHIPPING DAYS
SELECT
	Region,
	ROUND(AVG(CAST(DeliveryDays AS FLOAT)), 0) AS 'Avg. Delivery Days'
FROM Sales.vw_ShippingDetails
GROUP BY Region
ORDER BY [Avg. Delivery Days] ASC;


-- STATE WISE AVERAGE SHIPPING DAYS
SELECT
	State,
	ROUND(AVG(CAST(DeliveryDays AS FLOAT)), 0) AS 'Avg. Delivery Days'
FROM Sales.vw_ShippingDetails
GROUP BY State
ORDER BY [Avg. Delivery Days] ASC;


-- SALES BY SHIPPING DAYS
SELECT
	DeliveryDays AS 'Delivery days',
	ROUND(SUM(Sales), 2) as 'Total Sales'
FROM Sales.vw_ShippingDetails
GROUP BY DeliveryDays
ORDER BY [Total Sales] DESC;


-- PROFIT BY SHIPPING DAYS
SELECT
	DeliveryDays AS 'Delivery days',
	ROUND(SUM(Profit), 2) as 'Total Profit'
FROM Sales.vw_ShippingDetails
GROUP BY DeliveryDays
ORDER BY [Total Profit] DESC;


-- DELIVERY STATUS WISE SALES
SELECT
	OnTimeLateStatus AS 'Delivery Status',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.vw_ShippingDetails
GROUP BY OnTimeLateStatus
ORDER BY [Total Sales] DESC;


-- DELIVERY STATUS WISE PROFIT
SELECT
	OnTimeLateStatus AS 'Delivery Status',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_ShippingDetails
GROUP BY OnTimeLateStatus
ORDER BY [Total Profit] DESC;


-- DELIVERY STATUS WISE QUANTITY SOLD
SELECT
	OnTimeLateStatus AS 'Delivery Status',
	SUM(Quantity) AS 'Total Quantity Sold'
FROM Sales.vw_ShippingDetails
GROUP BY OnTimeLateStatus
ORDER BY [Total Quantity Sold] DESC;


-- DELIVERY STATUS WISE ORDERS
SELECT
	OnTimeLateStatus AS 'Delivery Status',
	COUNT(DISTINCT OrderID) AS 'Total Orders'
FROM Sales.vw_ShippingDetails
GROUP BY OnTimeLateStatus
ORDER BY [Total Orders] DESC;
GO




-------------------------- DISCOUNT ANALYSIS ------------------------------


-- DISCOUNT DETAILS
CREATE VIEW Sales.vw_DiscountDetails AS
SELECT
	OrderID,
	ProductID,
	ProductName,
	Category,
	SubCategory,
	CustomerID,
	CustomerName,
	Segment,
	Region,
	State,
	City,
	Sales,
	Profit,
	Quantity,
	Discount,
	CASE
		WHEN Discount = 0 THEN 'No Discount'
		WHEN Discount <= 0.1 THEN '0-10%'
		WHEN Discount <= 0.3 THEN '10-30%'
		WHEN Discount <= 0.5 THEN '30-50%'
		ELSE '50%+'
	END AS 'DiscountBand',
	CASE
		WHEN Discount = 0 THEN 1
		WHEN Discount <= 0.1 THEN 2
		WHEN Discount <= 0.3 THEN 3
		WHEN Discount <= 0.5 THEN 4
		ELSE 5
	END AS 'SortOrder',
	CASE
		WHEN Profit > 0 THEN 'Profit'
		ELSE 'Loss'
	END AS 'ProfitStatus'
FROM Sales.superstorecopy;
GO



-- DISCOUNT DETAILS
SELECT *
FROM Sales.vw_DiscountDetails;


-- AVERAGE DISCOUNT
SELECT
	ROUND(100 * AVG(Discount), 2) AS 'Avg. Discount'
FROM Sales.vw_DiscountDetails;
/* The average discount offered is 15.62%. */



-- TOTAL DISCOUNT AMOUNT
SELECT
	ROUND(SUM(Sales * Discount), 2) AS 'Total Discount Amount'
FROM Sales.vw_DiscountDetails;
/* The business offered $322.58K in discounts, equivalent to approximately 14% of total sales revenue. */


-- LET'S FIND AS DISCOUNT INCREASES, DOES PROFIT INCREASE OR DECREASE? (PROFIT IMPACT BY DISCOUNT BAND)
SELECT
	DiscountBand,
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	CASE
		WHEN SUM(Profit) > 0 THEN 'Profit'
		ELSE 'Loss'
	END AS 'Profit Status'
FROM Sales.vw_DiscountDetails
GROUP BY DiscountBand, SortOrder
ORDER BY SortOrder ASC;
/* Profit decreases as discount levels increase. Orders with no discount generate the highest profit ($320.99K), 
	while discounts above 30% result in overall losses. */


-- SALES DISTRIBUTION ACROSS DISCOUNT BAND
SELECT
	DiscountBand AS 'Discount',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(100 * SUM(Sales) / SUM(SUM(Sales)) OVER(), 2) AS 'Contribution %'
FROM Sales.vw_DiscountDetails
GROUP BY DiscountBand
ORDER BY SUM(Sales) DESC;
/* Nearly half of all sales revenue (47.36%) comes from orders with no discount, making it the largest contributor to overall sales.
	while 10-30% discounted orders contribute 36.85%. Orders with discounts above 30% generate only 15.8% of sales. */


-- CATEGORY WISE AVERAGE DISCOUNT, SALES & PROFIT ANALYSIS
SELECT
	Category,
	ROUND(100 * AVG(Discount),1) AS 'Avg. Discount',
	ROUND(100 * SUM(Sales)/SUM(SUM(Sales)) OVER(),2) AS 'Total Sales',
	ROUND(100 * SUM(Profit)/SUM(SUM(Profit)) OVER(),2) AS 'Total Profit'
FROM Sales.vw_DiscountDetails
GROUP BY Category
ORDER BY [Avg. Discount] DESC;
/* Furniture has the highest average discount (17.4%) but contributes only 6.58% of total profit.
	Technology offers the lowest discount (13.2%) and generates the highest profit contribution (50.71%). */



-- SUB CATEGORY WISE AVERAGE DISCOUNT, SALES & PROFIT ANALYSIS
SELECT
	SubCategory,
	ROUND(100 * AVG(Discount),1) AS 'Avg. Discount',
	ROUND(100 * SUM(Sales)/SUM(SUM(Sales)) OVER(),2) AS 'Total Sales',
	ROUND(100 * SUM(Profit)/SUM(SUM(Profit)) OVER(),2) AS 'Total Profit'
FROM Sales.vw_DiscountDetails
GROUP BY SubCategory
ORDER BY [Avg. Discount] DESC;
/* Binders receive the highest average discount (37.2%) yet contribute only 10.54% of total profit.
	Tables and Bookcases are among the most heavily discounted sub-categories and remain loss-making.
	Copiers stand out as the most profitable sub-category, contributing 19.39% of total profit with a moderate average discount of 16.2%. */


-- DISCOUNTED VS NON DISCOUNTED ORDERS
WITH DiscountStatus AS (
	SELECT
		OrderID,
		CASE
			WHEN MAX(Discount) > 0 THEN 'Discounted'
			ELSE 'Non Discounted'
		END AS 'OrderType'
	FROM Sales.vw_DiscountDetails
	GROUP BY OrderID
)
SELECT
	OrderType AS 'Order Type',
	COUNT(*) AS 'Total Orders',
	CAST(100.00 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5, 2)) AS 'Orders %'
FROM DiscountStatus
GROUP BY OrderType
ORDER BY [Total Orders] DESC;
/* Out of 5,009 total orders, 2,954 orders (58.97%) contained at least one discounted product,
	while 2,055 orders (41.03%) were completed without any discounts.
	Nearly 6 out of 10 orders involving promotional pricing (include a discount). */


-- HIGH DISCOUNTED ORDERS ( > 30%)
SELECT
	COUNT(DISTINCT OrderID) AS 'High Discounted Orders'
FROM Sales.vw_DiscountDetails
WHERE Discount > 0.30;
/* 1,020 orders (20.36% of total orders) received discounts above 30%. */


-- TOP 10 MOST DISCOUNTED PRODUCTS
SELECT TOP(10)
	ProductID,
	ProductName AS 'Product Name',
	ROUND(100.0 * AVG(Discount), 2) AS 'Avg. Discount',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	COUNT(DISTINCT OrderID) AS 'Total Orders'
FROM Sales.vw_DiscountDetails
GROUP BY ProductID, ProductName
ORDER BY [Avg. Discount] DESC;
/* The most heavily discounted products received average discounts ranging from 70% to 80%, and nearly all generated negative profits.
	The highest discounted product (Eureka Disposable Bags) received an 80% discount. */


-- LOSS MAKING ORDERS WITH DISCOUNT
SELECT
	COUNT(DISTINCT OrderID) AS 'Loss Making Orders'
FROM Sales.vw_DiscountDetails
WHERE Discount > 0 AND Profit < 0;
/* 1,318 orders generated negative profit. */


-- LOSS MAKING PRODUCTS BY DISCOUNT BAND
SELECT
	DiscountBand AS 'Discount',
	COUNT(DISTINCT ProductID) AS 'Loss Making Products'
FROM Sales.vw_DiscountDetails
WHERE Profit < 0
GROUP BY DiscountBand;
/* The number of loss-making products increases significantly as discount levels rise.
	380 loss-making products fall into the 50%+ discount band, the highest among all discount categories. */


-- AVERAGE PROFIT MARGIN BY DISCOUNT BAND
SELECT
	DiscountBand AS 'Discount',
	ROUND(100 * AVG(Profit/Sales), 2) AS 'Profit Margin'
FROM Sales.vw_DiscountDetails
GROUP BY DiscountBand, SortOrder
ORDER BY SortOrder;
/* Profit margins decrease significantly as discounts increase.
	Orders with discounts above 30% generate negative profit margin. */


-- DISCOUNT VS PROFIT ANALYSIS
SELECT
	DiscountBand,
	ROUND(100 * AVG(Discount), 2) AS 'Avg. Discount',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_DiscountDetails
GROUP BY DiscountBand, SortOrder
ORDER BY SortOrder;
GO
/* Profitability decreases as discount levels increase. 'No discount' orders generated $320.99K profit,
	while discount above 30% resulted in combined losses exceeding $134.95K.
	Discounts up to 30% remain profitable, but discounts exceeding 30% consistently destroy value. */





----------------------- TIME BASED ANALYSIS -----------------------


CREATE VIEW Sales.vw_TimeAnalysis AS
SELECT
	OrderID,
	OrderDate,
	YEAR(OrderDate) AS 'OrderYear',
	MONTH(OrderDate) AS 'MonthNo',
	DATENAME(MONTH, OrderDate) AS 'MonthName',
	DATEPART(QUARTER, OrderDate) AS 'QuarterNo',
	CONCAT('Q', DATEPART(QUARTER, OrderDate)) AS 'Quarter',
	ShipMode,
	ProductID,
	ProductName,
	Category,
	SubCategory,
	Region,
	State,
	City,
	Sales,
	Profit,
	Quantity,
	Discount
FROM Sales.superstorecopy;
GO


-- TIME BASED ANALYSIS
SELECT *
FROM Sales.vw_TimeAnalysis;



-- YEARLY SALES, PROFIT, ORDERS & QUANTITY SOLD
SELECT
	OrderYear AS 'Order Year',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(100 * SUM(Profit) / SUM(Sales), 2) AS 'Profit Margin %',
	COUNT(DISTINCT OrderID) AS 'Total Orders',
	SUM(Quantity) AS 'Total Quantity Sold'
FROM Sales.vw_TimeAnalysis
GROUP BY OrderYear
ORDER BY [Order Year] ASC;
/* The business experienced strong growth between 2014 and 2017, with
	Total sales increased from $484.25K to $733.22K (+51.4%) and total profit grew from $49.54K to $93.86K (+89.5%).
	While 2017 recorded the highest sales, profit margin peaked in 2016 (13.43%) before slightly declining in 2017(12.8%). */


-- QUATERLY SALES, PROFIT, ORDERS & QUANTITY SOLD
SELECT
	Quarter,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(100 * SUM(Profit) / SUM(Sales), 2) AS 'Profit Margin %',
	COUNT(DISTINCT OrderID) AS 'Total Orders',
	SUM(Quantity) AS 'Total Quantity Sold'
FROM Sales.vw_TimeAnalysis
GROUP BY Quarter
ORDER BY Quarter ASC;
/* Q4 is the strongest performing quarter, generating the highest sales ($878.08K), profit ($111.04K), orders (1,872), and
	quantity sold (14,298). The steady increase from Q1 to Q4 indicates strong seasonal demand and year-end business growth. */


-- MONTHLY SALES, PROFIT, ORDERS & QUANTITY SOLD
SELECT
	MonthName AS 'Month Name',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(100 * SUM(Profit) / SUM(Sales), 2) AS 'Profit Margin %',
	COUNT(DISTINCT OrderID) AS 'Total Orders',
	SUM(Quantity) AS 'Total Quantity Sold'
FROM Sales.vw_TimeAnalysis
GROUP BY MonthName, MonthNo
ORDER BY MonthNo ASC;
/* February recorded the highest profit margin (17.23%), 
	November recorded the highest sales ($352.46K) and order volume (753 orders), 
	while December generated the highest monthly profit ($43.79K). 
	September, November, and December collectively represent the strongest business period, 
	highlighting the importance of year-end demand and promotional activities. */


-- YEAR OVER YEAR (YOY) SALES GROWTH
WITH YearOrderSales AS (
	SELECT
		OrderYear,
		SUM(Sales) AS 'TotalSales'
	FROM Sales.vw_TimeAnalysis
	GROUP BY OrderYear
)
SELECT
	OrderYear AS 'Order Year',
	ROUND([TotalSales], 2) AS 'Total Sales',
	ROUND(
		100 * ([TotalSales] - LAG([TotalSales]) OVER(ORDER BY OrderYear)) / LAG([TotalSales]) OVER(ORDER BY OrderYear),
	2) AS 'YoY Growth %'
FROM YearOrderSales;
/* After a slight decline in 2015 (-2.83%), the business experienced strong recovery and sustained growth over the next two years. 
	Sales grew by 29.47% in 2016 and 20.36% in 2017, indicating successful expansion and increasing customer demand. */



-- SEASONALITY SALES GROWTH ANALYSIS / MONTH OVER MONTH (MOM) SALES GROWTH
WITH MonthOrderSales AS (
	SELECT
		MonthNo,
		MonthName,
		SUM(Sales) AS 'TotalSales'
	FROM Sales.vw_TimeAnalysis
	GROUP BY MonthNo, MonthName
)
SELECT
	MonthName AS 'Month Name',
	ROUND([TotalSales], 2) AS 'Total Sales',
	ROUND(
		100 * (TotalSales - LAG(TotalSales) OVER(ORDER BY MonthNo)) / LAG(TotalSales) OVER(ORDER BY MonthNo),
	2) AS 'MoM Growth %'
FROM MonthOrderSales;
/* Monthly sales show strong seasonality with significant fluctuations. March (+243.10%), September (+93.44%), and November (+75.95%)
	recorded the highest growth rates, while February (-37.05%) and October (-34.89%) experienced the largest declines. */


-- QUARTER OVER QUARTER (QOQ) SALES GROWTH ANALYSIS
WITH QuarterOrderSales AS (
	SELECT
		QuarterNo,
		Quarter,
		SUM(Sales) AS 'TotalSales'
	FROM Sales.vw_TimeAnalysis
	GROUP BY QuarterNo, Quarter
)
SELECT
	Quarter,
	ROUND([TotalSales], 2) AS 'Total Sales',
	ROUND(
		100 * (TotalSales - LAG(TotalSales) OVER(ORDER BY QuarterNo)) / LAG(TotalSales) OVER(ORDER BY QuarterNo),
	2) AS 'QoQ Growth %'
FROM QuarterOrderSales;
/* Sales increased consistently throughout the year, with QoQ growth accelerating from 23.86% in Q2 to 37.80% in Q3 and
	reached its highest level in Q4 (43.03%) The strongest business performance occurred in the second half of the year,
	particularly during Q4. */


-- YEAR OVER YEAR (YOY) PROFIT GROWTH ANALYSIS
WITH YearProfit AS (
	SELECT
		OrderYear,
		SUM(Profit) AS 'TotalProfit'
	FROM Sales.vw_TimeAnalysis
	GROUP BY OrderYear
)
SELECT
	OrderYear AS 'Order Year',
	ROUND(TotalProfit, 2) AS 'Total Profit',
	ROUND(
		100 * (TotalProfit - LAG(TotalProfit) OVER(ORDER BY OrderYear)) / LAG(TotalProfit) OVER(ORDER BY OrderYear),
	2) AS 'YoY Profit Growth %'
FROM YearProfit;
/* Profit increased consistently from 2014 to 2017, with the strongest growth recorded in 2016 (+32.74%).
	Although profits reached a record high in 2017 with growth rate slowed to 14.75%. */



-- SEASONALITY PROFIT GROWTH ANALYSIS / MONTH OVER MONTH (MOM) PROFIT GROWTH
WITH MonthlyProfit AS (
	SELECT
		MonthNo,
		MonthName,
		SUM(Profit) AS 'TotalProfit'
	FROM Sales.vw_TimeAnalysis
	GROUP BY MonthNo, MonthName
)
SELECT
	MonthName AS 'Month Name',
	ROUND([TotalProfit], 2) AS 'Total Profit',
	ROUND(
		100 * (TotalProfit - LAG(TotalProfit) OVER(ORDER BY MonthNo)) / LAG(TotalProfit) OVER(ORDER BY MonthNo),
	2) AS 'MoM Profit Growth %'
FROM MonthlyProfit;
/* Monthly profit shows considerable volatility throughout the year. March recorded the highest profit growth (+177.76%),
	while April experienced the largest decline (-59.48%). Profit performance strengthened significantly in the second half of the year,
	with December generating the highest monthly profit ($43.79K). */


-- QUARTER OVER QUARTER (QOQ) SALES GROWTH ANALYSIS
WITH QuarterlyProfit AS (
	SELECT
		QuarterNo,
		Quarter,
		SUM(Profit) AS 'TotalProfit'
	FROM Sales.vw_TimeAnalysis
	GROUP BY QuarterNo, Quarter
)
SELECT
	Quarter,
	ROUND([TotalProfit], 2) AS 'Total Profit',
	ROUND(
		100 * (TotalProfit - LAG(TotalProfit) OVER(ORDER BY QuarterNo)) / LAG(TotalProfit) OVER(ORDER BY QuarterNo),
	2) AS 'QoQ Profit Growth %'
FROM QuarterlyProfit;
/* Profit increased consistently throught the year, with growth accelerating from 15.12% in Q2 to 53.23% in Q4.
	The strongest profitability was achieved in Q4, highlighting the importance of year-end demand and seasonal business activity. */



-- BEST SALES MONTH
SELECT TOP(1)
	MonthName AS 'Best Sales Month',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.vw_TimeAnalysis
GROUP BY MonthName
ORDER BY [Total Sales] DESC;
/* November was the highest revenue-generating month, recording total sales of $352.46K. */


-- WORST SALES MONTH
SELECT TOP(1)
	MonthName AS 'Worst Sales Month',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.vw_TimeAnalysis
GROUP BY MonthName
ORDER BY [Total Sales] ASC;
/* February recorded the lowest sales of $59.75K, making it the weakest revenue-generating month of the year.
	However, despite lower sales, it achieved the highest profit margin (17.23%). */


-- BEST PROFIT MONTH
SELECT TOP(1)
	MonthName AS 'Best Profit Month',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_TimeAnalysis
GROUP BY MonthName
ORDER BY [Total Profit] DESC;
/* December was the most profitable month, generating $43.79K in profit. (although November achieved the highest sales). */


-- WORST PROFIT MONTH
SELECT TOP(1)
	MonthName AS 'Worst Profit Month',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_TimeAnalysis
GROUP BY MonthName
ORDER BY [Total Profit] ASC;
/* January recorded the lowest profit of $9.13K, making it the weakest month in terms of profitability. */


-- YEARLY BEST SALES MONTH
WITH SalesRank AS (
	SELECT
		OrderYear,
		MonthName,
		SUM(Sales) AS 'TotalSales',
		ROW_NUMBER() OVER(PARTITION BY OrderYear ORDER BY SUM(Sales) DESC) AS 'rnk'
	FROM Sales.vw_TimeAnalysis
	GROUP BY OrderYear, MonthName
)
SELECT
	OrderYear AS 'Order Year',
	MonthName AS 'Best Sales Month',
	ROUND(TotalSales, 2) AS 'Total Sales',
	CONCAT(ROUND(TotalSales/1000, 0), 'K') AS 'Total Sales(K)'
FROM SalesRank
WHERE rnk = 1;


-- YEARLY BEST PROFIT MONTH
WITH ProfitRank AS (
	SELECT
		OrderYear,
		MonthName,
		SUM(Profit) AS 'TotalProfit',
		ROW_NUMBER() OVER(PARTITION BY OrderYear ORDER BY SUM(Profit) DESC) AS 'rnk'
	FROM Sales.vw_TimeAnalysis
	GROUP BY OrderYear, MonthName
)
SELECT
	OrderYear AS 'Order Year',
	MonthName AS 'Best Profit Month',
	ROUND(TotalProfit, 2) AS 'Total Profit'
FROM ProfitRank
WHERE rnk = 1;


-- HIGHEST SALES YEAR
SELECT TOP(1)
	OrderYear AS 'Highest Sales Year',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.vw_TimeAnalysis
GROUP BY OrderYear
ORDER BY [Total Sales] DESC;
/* 2017 was the highest revenue-generating year, achieving total sales of $733.22K. */


-- HIGHEST PROFIT YEAR
SELECT TOP(1)
	OrderYear AS 'Highest Profit Year',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_TimeAnalysis
GROUP BY OrderYear
ORDER BY [Total Profit] DESC;
/* 2017 was the most profitable year, generating a total profit of $93.86K. */


-- HIGHEST SALES DAY
SELECT TOP(1)
	OrderDate AS 'Highest Sales Day',
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_TimeAnalysis
GROUP BY OrderDate
ORDER BY [Total Sales] DESC;
/* March 18, 2014 was the highest revenue-generating day in the dataset, recording total sales of $28.11K. */

-- TOP PRODUCTS ON HIGHEST SALES DAY
SELECT
	ProductID,
	ProductName,
	ROUND(SUM(Sales), 2) AS 'Total Sales',
	ROUND(SUM(Profit), 2) AS 'Total Profit'
FROM Sales.vw_TimeAnalysis
WHERE OrderDate = ( SELECT TOP(1) OrderDate
					FROM Sales.vw_TimeAnalysis
					GROUP BY OrderDate
					ORDER BY SUM(Sales) DESC)
GROUP BY ProductID, ProductName
ORDER BY [Total Sales] DESC;


-- HIGHEST PROFIT DAY
SELECT TOP(1)
	OrderDate AS 'Highest Profit Day',
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.vw_TimeAnalysis
GROUP BY OrderDate
ORDER BY [Total Profit] DESC;
/* October 2, 2016 was the most profitable day in the dataset, generating $8.74K in profit. */


-- TOP PRODUCTS ON HIGHEST PROFIT DAY
SELECT
	ProductID,
	ProductName,
	ROUND(SUM(Profit), 2) AS 'Total Profit',
	ROUND(SUM(Sales), 2) AS 'Total Sales'
FROM Sales.vw_TimeAnalysis
WHERE OrderDate = ( SELECT TOP(1) OrderDate
					FROM Sales.vw_TimeAnalysis
					GROUP BY OrderDate
					ORDER BY SUM(Profit) DESC)
GROUP BY ProductID, ProductName
ORDER BY [Total Profit] DESC;






 /* ================================================================================================
	BUSINESS PROBLEM
	================================================================================================
	Our company has experienced strong sales growth but declining profitability. Analyze the data
	and identify the root causes, key issues, and actionable recommendations.
 
 
	================================================================================================
	KEY INSIGHTS (SUMMARY)
	================================================================================================
	1. Sales increased every year, but profit margin declined in 2017 despite strong revenue growth.
	2. Discounts above 30% negatively impact profitability, and total discounts ($322.58K) exceeded total profit earned ($286.82K).
	3. Furniture generated high sales but contributed only 6.58% of total profit due to heavy discounting.
	4. Texas recorded the highest loss, while Ohio and Colorado reported the lowest profit margins.
	5. 1,318 out of 5,009 orders (26.3%) were loss-making, indicating a recurring profitability issue.
	6. High sales do not always lead to high profits. The top customer by sales was not among the most profitable customers.
	7. Copiers generated 19.39% of total profit despite relatively low discounts (16.2%), proving that strong
		profitability can be achieved without heavy discounting.
	8. Q4 recorded the highest sales and profit growth, indicating that seasonality is not the main cause of profitability issues.
	9. The top 20% of customers contributed a disproportionately large share of total revenue, highlighting strong customer concentration.
 
	
	================================================================================================
	BUSINESS ROOT CAUSES
	================================================================================================

	ROOT CAUSE - 1 : DISCOUNTING IS THE BIGGEST REASON FOR LOW PROFIT
	------------------------------------------------------------------------------------------------
	1. Profit margins become negative when discounts exceed 30%.
	2. A total of 1,020 orders (20.4% of all orders) received discounts above 30%, meaning one out of every five orders
		was sold at a heavily discounted price.
	3. The company gave away $322.58K in discounts, which is higher than the total profit of $286.82K earned during the same period.
	4. Out of 5,009 orders, 1,318 orders (26%) resulted in a loss. The number of loss-making products increased significantly as
		discount levels increased, with 380 loss-making products in the 50%+ discount band alone.
	5. Products discounted 70-80% (e.g. Eureka Disposable get 80%) are almost loss-making.


	ROOT CAUSE - 2 : FURNITURE HAS LOW PROFITABILITY
	------------------------------------------------------------------------------------------------
	6. Furniture received the highest average discount (17.4%) but contributed only 6.58% of total profit, despite generating over $742K in sales.
	7. Technology received the lowest average discount (13.2%) and generated the highest profit contribution (50.71%).
	8. Tables generated high sales but resulted in an overall loss due to heavy discounting.
	9. Copiers generated 19.39% of total profit with relatively low discounts(16.2%), showing that premium products are hghly profitable.


	ROOT CAUSE - 3 : HIGH SALES DO NOT ALWAYS MEAN HIGH PROFIT
	------------------------------------------------------------------------------------------------
	10. Sean Miller was the top customer by sales ($25K) but ranked among the bottom 10 customers by profit,
		showing that high sales do not always lead to high profits.
	11. Tamara Chand was the most profitable customer, generating $8.98K in profit despite not being among the top customers by sales.


	ROOT CAUSE - 4 : LOSSES ARE CONCENTRATED IN A FEW STATES
	------------------------------------------------------------------------------------------------
	12. 10 of 49 states (~20%) are net loss-making, with Texas (-$25.73K) posting the largest state-level loss.
	13. Ohio and Colorado had the lowest profit margins (-21.69% and -20.33%).
	14. The top 10 loss-making states generated $705.7K in sales but operated at a combined profit margin of -13.9%.
	15. 116 of 531 cities (22%) are loss-making, led by Philadelphia (-$13.84K) - losses are broad-based, not isolated outliers.


	ROOT CAUSE - 5 : SEASONALITY IS NOT THE MAIN CAUSE OF LOW PROFITS
	------------------------------------------------------------------------------------------------
	16. Q4 generated the highest sales ($878K) and the strongest profit growth (53.23% QoQ),
		indicating that demand is strong and seasonality is not the main cause of profitability issues.
	17. December was the most profitable month ($43.79K), even though November generated the highest sales,
		showing that higher sales do not always lead to higher profits.
	18. February recorded the lowest sales ($59.75K) but achieved the highest profit margin (17.23%),
		showing that strong profitability can be maintained even with lower sales.


	ROOT CAUSE - 6 : A HIGH NUMBER OF ORDERS ARE LOSS-MAKING
	------------------------------------------------------------------------------------------------
	19. 1,318 out of 5,009 orders (26.3%) were loss-making, meaning more than one in every four orders generated a loss.
		This indicates a recurring profitability issue rather than isolated cases.



	================================================================================================
	ACTIONABLE RECOMMENDATIONS
	================================================================================================
	1. Limit discounts above 30% and require approval for higher discounts to protect profit margins.
		[Addresses: High Discounts]
	2. Review products receiving very high discounts (50%+), as many of them are generating losses.
		[Addresses: High Discounts]
	3. Reassess pricing and discount strategies for Furniture, especially Tables, to improve category profitability.
		[Addresses: Furniture Profitability]
	4. Use successful categories such as Technology and Copiers as pricing benchmarks, since they
		maintain strong profitability with lower discounts.
		[Addresses: Furniture Profitability]
	5. Focus on customer profitability in addition to sales revenue when managing key customer accounts.
		[Addresses: Sales vs Profit]
	6. Conduct detailed margin reviews for Texas, Ohio, and Colorado to identify the causes of persistent losses.
		[Addresses: Geographic Losses]
	7. Review pricing and discount policies in loss-making states and cities to improve regional profitability.
		[Addresses: Geographic Losses]
	8. Prioritize improvements in pricing and discount management rather than seasonal promotions,
		as demand remains strong throughout peak periods. [Addresses: Seasonality]
	9. Implement profit-margin checks before approving orders to reduce the number of loss-making transactions.
		[Addresses: Loss-Making Orders]
*/