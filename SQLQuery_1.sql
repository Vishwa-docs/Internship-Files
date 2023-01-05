/* Analysis of the Data */

-- Listing the properties of all the columns, like datatype
exec sp_help '[dsdb].[dbo].[supermarket_sales]';

/*
COGS : Cost of Goods Sold : Direct cost of producing products sold by business
Gross Margin Calculation : (Revenue - COGS) / Revenue x 100 : shows the percentage ratio of revenue you keep for each sale after all costs are deducted
*/

ALTER TABLE [dsdb].[dbo].[supermarket_sales] ADD GrossMargin AS CAST((((Unit_price * Quantity) - cogs)/ (Unit_price * Quantity))*100 AS Numeric (9,0));


/* PRELIMINARY ANALYSIS */
SELECT TOP (1000) * FROM [dsdb].[dbo].[supermarket_sales];
SELECT * FROM [dsdb].[dbo].[supermarket_sales] LIMIT;
SELECT * FROM [dsdb].[dbo].[supermarket_sales] ORDER BY Invoice_ID OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

-- Counting total Number of rows
SELECT COUNT(*) FROM [dsdb].[dbo].[supermarket_sales];

-- Counting number of distinct values
SELECT COUNT(DISTINCT Branch) AS Distinct_Branch, COUNT(DISTINCT City) AS Distinct_City FROM [dsdb].[dbo].[supermarket_sales];

-- What percentage of the totoal does each value account for
SELECT City, 
    COUNT(City) AS City_Count, 
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS Percentage_Of_City
FROM [dsdb].[dbo].[supermarket_sales]
GROUP BY City;
-- Max sales from Yangon

-- Descriptive Statistics of the Dataset
DECLARE @median1 INT;
DECLARE @median2 INT;

SELECT @median1 = (
 (SELECT MAX(Total) FROM
   (SELECT TOP 50 PERCENT Total FROM [dsdb].[dbo].[supermarket_sales] ORDER BY Total) AS BottomHalf)
 +
 (SELECT MIN(Total) FROM
   (SELECT TOP 50 PERCENT Total FROM [dsdb].[dbo].[supermarket_sales] ORDER BY Total DESC) AS TopHalf)
) / 2;

SELECT @median2 = (
 (SELECT MAX(gross_income) FROM
   (SELECT TOP 50 PERCENT gross_income FROM [dsdb].[dbo].[supermarket_sales] ORDER BY gross_income) AS BottomHalf)
 +
 (SELECT MIN(gross_income) FROM
   (SELECT TOP 50 PERCENT gross_income FROM [dsdb].[dbo].[supermarket_sales] ORDER BY gross_income DESC) AS TopHalf)
) / 2;


SELECT 'Total',
    SUM(Total) AS Total_Revenue,
    SUM(gross_income) AS Income
FROM [dsdb].[dbo].[supermarket_sales]
UNION
SELECT 'Mean',
    AVG(Total),
    AVG(gross_income)
FROM [dsdb].[dbo].[supermarket_sales]
UNION
SELECT 'Median',
    @median1,
    @median2
UNION
SELECT 'Standard Deviation',
    STDEV(Total),
    STDEV(gross_income)
FROM [dsdb].[dbo].[supermarket_sales];


-- Min and Max of the Data
SELECT 'Min',
    MIN(Total),
    MIN(gross_income)
FROM [dsdb].[dbo].[supermarket_sales]
UNION
SELECT 'Max',
    MAX(Total),
    MAX(gross_income)
FROM [dsdb].[dbo].[supermarket_sales];

SELECT CAST((((Unit_price * Quantity) - cogs)/ (Unit_price * Quantity))*100 AS Numeric (9,0))
FROM [dsdb].[dbo].[supermarket_sales];

SELECT CAST(((((Unit_price * Quantity) - cogs) + Tax_5)/ (Unit_price * Quantity))*100 AS Numeric (9,0))
FROM [dsdb].[dbo].[supermarket_sales];


SELECT Invoice_ID, Product_line, ((Unit_price * Quantity)) as Col, cogs, (ROUND((Unit_price * Quantity), 2) - cogs) as difference
FROM [dsdb].[dbo].[supermarket_sales]
ORDER BY difference DESC;


-- Correlation

/******************************************/

/* TREND ANALYISIS */

-- Running Total : Cumulative sum of everything in the previous row
SELECT
   Branch, [Date], [Time], Total,
  SUM([Total]) OVER (PARTITION BY [Branch] ORDER BY [Date], [Time]) AS running_total
FROM [dsdb].[dbo].[supermarket_sales];
-- Partition by divides into logical groups
-- We are sorting by date and time


-- INCREASE or Decrease (Percent Change) PER TIME STAMP
WITH daily_sales_lag AS (
 SELECT
  Branch, [Date], [Time], Total,
  LAG([Total]) OVER (PARTITION BY [Branch] ORDER BY [Date], [Time]) AS previous_day_sales
  FROM [dsdb].[dbo].[supermarket_sales]
)
SELECT
    Branch, [Date], [Time], Total,
   COALESCE(ROUND((([Total] - previous_day_sales)/previous_day_sales) * 100, 2),0) AS percent_change
FROM daily_sales_lag;

-- The WITH is a COMMON TABLE EXPRESSION (CTE), a Temporary table
-- LAG : Takes the Previous Columns Data
-- COALSCE : 


-- 7 Day Sales ordering
WITH daily_sales_lag AS (
 SELECT
  *,
  LAG([Total], 7) OVER (PARTITION BY [Branch] ORDER BY [Date]) AS previous_day_sales
  FROM [dsdb].[dbo].[supermarket_sales]
)
SELECT
    *,
   COALESCE(ROUND((([Total] - previous_day_sales)/previous_day_sales) * 100, 2),0) AS percent_change
FROM daily_sales_lag
ORDER BY [Date], [Time];


/* SIMPLE MOVING AVERAGE (SMA) */
--  Unweighted mean of the previous n row values; it is calculated for each value in a given column.

SELECT
   *,
   AVG([Total]) OVER(PARTITION BY [Branch] ORDER BY [Date],[Time] ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) as SMA
FROM [dsdb].[dbo].[supermarket_sales];

-- ROW inside an OVER clause defines a window inside each partition.
-- Each window is defined as 7 rows (the 6 prior row values + the current row value)


/* Highest Number of Sales Total */
SELECT *,
  RANK() OVER (PARTITION BY [Branch] ORDER BY [Date],[Time] DESC) AS Rank
FROM [dsdb].[dbo].[supermarket_sales];
-- Ranked Over each branch


SELECT MAX([Date]) FROM [dsdb].[dbo].[supermarket_sales];
SELECT MIN([Date]) FROM [dsdb].[dbo].[supermarket_sales];


/* TREND ANALYSIS of Sales */
select Branch, 1.0*sum(CAST((x-xbar)*(y-ybar) AS bigint))/sum(CAST((x-xbar)*(x-xbar) AS bigint)) as Beta
from
(
    select Branch,
        avg(CAST([Total] AS bigint)) over(partition by Branch) as ybar,
        [Total] as y,
        avg(CAST(datediff(second,'2019-01-01',[Date]) as bigint)) over (partition by Branch) as xbar,
        CAST(datediff(second,'2019-01-01',[Date]) AS bigint) as x
    from [dsdb].[dbo].[supermarket_sales]
    where [Date]>='2019-01-01' and [Date]<'2019-04-01'
) as Calcs
group by Branch
having 1.0*sum(CAST((x-xbar)*(y-ybar) AS bigint))/sum(CAST((x-xbar)*(x-xbar) AS bigint))>0;


/* TREND ANALYSIS of Payment Method */
select Payment, 1.0*sum(CAST((x-xbar)*(y-ybar) AS bigint))/sum(CAST((x-xbar)*(x-xbar) AS bigint)) as Beta
from
(
    select Payment,
        avg(CAST([Total] AS bigint)) over(partition by Payment) as ybar,
        [Total] as y,
        avg(CAST(datediff(second,'2019-01-01',[Date]) as bigint)) over (partition by Payment) as xbar,
        CAST(datediff(second,'2019-01-01',[Date]) AS bigint) as x
    from [dsdb].[dbo].[supermarket_sales]
    where [Date]>='2019-01-01' and [Date]<'2019-04-01'
) as Calcs
group by Payment
having 1.0*sum(CAST((x-xbar)*(y-ybar) AS bigint))/sum(CAST((x-xbar)*(x-xbar) AS bigint))>0;


-- Top 10 Selling Products
WITH Revenue AS (
    SELECT
    SUM((CAST([Unit_price] * [Quantity] AS bigint))) AS Revenue_Order, [Product_line]
    FROM [dsdb].[dbo].[supermarket_sales]
    GROUP BY [Product_line]
)
SELECT TOP(10) * FROM Revenue
ORDER BY [Revenue_Order] DESC
GO


/* ADD ALL THE FOREIGN KEYS */
ALTER TABLE [dsdbnew].[dbo].[OrderDetails]
ADD FOREIGN KEY ([OrderID]) REFERENCES [dsdbnew].[dbo].[Orders]([OrderID]), 
FOREIGN KEY ([ProductID]) REFERENCES [dsdbnew].[dbo].[Products]([ProductID]);

ALTER TABLE [dsdbnew].[dbo].[Orders]
ADD FOREIGN KEY ([CustomerID]) REFERENCES [dsdbnew].[dbo].[Customers]([CustomerID]), 
FOREIGN KEY ([EmployeeID]) REFERENCES [dsdbnew].[dbo].[Employees]([E    mployeeID]),
FOREIGN KEY ([ShipperID]) REFERENCES [dsdbnew].[dbo].[Shippers]([ShipperID]);

ALTER TABLE [dsdbnew].[dbo].[Products]
ADD FOREIGN KEY ([SupplierID]) REFERENCES [dsdbnew].[dbo].[Suppliers]([SupplierID]),
FOREIGN KEY ([CategoryID]) REFERENCES [dsdbnew].[dbo].[Categories]([CategoryID]);


/* DESCRIBE THE DATABASE (Tablewise) */
EXEC SP_HELP '[dsdbnew].[dbo].[Products]';
SELECT * FROM information_schema.columns WHERE table_schema = 'dsdbnew' ORDER BY TABLE_NAME, ORDINAL_POSITION


SELECT TOP (100) * FROM [dsdbnew].[dbo].[Products] AS Prod
INNER JOIN [dsdbnew].[dbo].[Categories] AS Cat
ON [Prod].[CategoryID] = [Cat].[CategoryID]
ORDER BY Cat.CategoryID;

SELECT * FROM [dsdbnew].[dbo].[Products] LIMIT;
SELECT * FROM [dsdbnew].[dbo].[Products] ORDER BY CategoryID OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;


-- Counting total Number of Orders (Example)
SELECT COUNT(*) FROM [dsdbnew].[dbo].[Orders];

-- Counting number of distinct values
SELECT COUNT(DISTINCT Cust.[CustomerName]) AS Distinct_Name, 
COUNT(DISTINCT Emp.[EmployeeID]) AS Distinct_Employee,
COUNT(DISTINCT Prod.[ProductName]) AS Distinct_Product
FROM [dsdbnew].[dbo].[Customers] AS Cust, [dsdbnew].[dbo].[Employees] AS Emp, [dsdbnew].[dbo].[Products] AS Prod;

-- What percentage of the total does each value account for
SELECT OrdDet.Quantity, 
    COUNT(OrdDet.Quantity) AS Order_Quantity, 
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS Percentage_Of_Order
FROM [dsdbnew].[dbo].[Orders] AS Ord
INNER JOIN [dsdbnew].[dbo].[OrderDetails] AS OrdDet
ON Ord.OrderID = OrdDet.OrderID
GROUP BY Ord.OrderID, OrdDet.Quantity;


-- Descriptive Statistics of the Dataset
DECLARE @median1 INT;

SELECT @median1 = (
 (SELECT MAX(Price) FROM
   (SELECT TOP 50 PERCENT Price FROM [dsdbnew].[dbo].[Products] ORDER BY Price) AS BottomHalf)
 +
 (SELECT MIN(Price) FROM
   (SELECT TOP 50 PERCENT Price FROM [dsdbnew].[dbo].[Products] ORDER BY Price DESC) AS TopHalf)
) / 2;

SELECT 'Total',
    SUM(Price) AS Total_Revenue
FROM [dsdbnew].[dbo].[Products]
UNION
SELECT 'Mean',
    AVG(Price)
FROM [dsdbnew].[dbo].[Products]
UNION
SELECT 'Median',
    @median1
UNION
SELECT 'Standard Deviation',
    STDEV(Price)
FROM [dsdbnew].[dbo].[Products];

-- Max and Min Price by Category
WITH allProducts AS (
SELECT  Prod.Price, Cat.CategoryName,
        ROW_NUMBER() OVER (PARTITION BY Cat.CategoryName ORDER BY Prod.Price DESC) ROW_NUM
FROM [dsdbnew].[dbo].[Products] AS Prod,[dsdbnew].[dbo].[Categories] AS Cat)

SELECT *
FROM allProducts
WHERE ROW_NUM = 1
ORDER BY allProducts.Price;


WITH allProducts AS (
SELECT  Prod.Price, Cat.CategoryName,
        ROW_NUMBER() OVER (PARTITION BY Cat.CategoryName ORDER BY Prod.Price DESC) ROW_NUM
FROM [dsdbnew].[dbo].[Products] AS Prod,[dsdbnew].[dbo].[Categories] AS Cat)

SELECT *
FROM allProducts
ORDER BY allProducts.Price DESC;


-- Total Number of Sales
SELECT YEAR([Date]) AS Year, DATENAME(MONTH, ([Date])) AS Month_Name, MONTH([Date]) AS [Month], COUNT([Total]) AS Count_of_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), DATENAME(MONTH, ([Date])), MONTH([Date])
ORDER BY [Month]; -- TRENDS SHOULD BEALIGNED WITH MONTH

-- Total Amount earned
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, ROUND(SUM([Total]), 2) AS Total_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), MONTH([Date])
ORDER BY Total_Sales DESC;

-- Trend By Payment Method (AMOUNT)
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, [Payment], ROUND(SUM([Total]), 2) AS Total_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), MONTH([Date]), [Payment]
ORDER BY MONTH([Date]), Total_Sales DESC;

-- Trend By Payment Method (No Of Transactions)
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, [Payment], COUNT([Total]) AS Count_Of_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), MONTH([Date]), [Payment]
ORDER BY MONTH([Date]), Count_Of_Sales DESC;


-- Trend By Branch (AMOUNT)
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, [Branch], CAST(SUM([Total]) AS bigint) AS Total_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), MONTH([Date]), [Branch]
ORDER BY MONTH([Date]), Total_Sales DESC;

-- Trend By Branch (No Of Transactions)
SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, [Branch], COUNT([Total]) AS Count_Of_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), MONTH([Date]), [Branch]
ORDER BY MONTH([Date]), Count_Of_Sales DESC;


-- Normalizing the column
EXEC ('CREATE VIEW temp_view AS SELECT YEAR([Date]) AS Year, MONTH([Date]) AS Month, [Branch], ROUND(SUM([Total]), 2) AS Sum_Of_Sales 
FROM [dsdb].[dbo].[supermarket_sales]  
GROUP BY YEAR([Date]), MONTH([Date]), [Branch]')
SELECT * FROM temp_view;

DROP VIEW temp_view;

DECLARE @min AS DECIMAL(10, 10)
DECLARE @max AS DECIMAL(10, 10)

SET @min = (SELECT ROUND(MIN(Sum_Of_Sales), 2) FROM temp_view)
SET @max = (SELECT MAX(CAST(SUM([Total]) AS bigint)) FROM [dsdb].[dbo].[supermarket_sales])

SELECT ROUND(SUM([Total]), 2), ((ROUND(SUM([Total]), 2) - @min) / (@max - @min)) AS Normalized_Column
FROM [dsdb].[dbo].[supermarket_sales]

