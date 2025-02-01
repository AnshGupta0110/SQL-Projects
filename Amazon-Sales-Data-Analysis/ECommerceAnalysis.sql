
use ECommerceDB;




SELECT * FROM AmazonSale;



-- Checking Null Values, There are columns which consists Null values
--Why i am only checking these columns because, only these columns have not consist constraints "NOT NULL"
SELECT 
    COUNT(CASE WHEN Amount IS NULL OR Amount = '' THEN 1 END) AS Null_Amount,
    COUNT(CASE WHEN [currency] IS NULL OR [currency] = '' THEN 1 END) AS Null_Currency,
    COUNT(CASE WHEN [ship_city] IS NULL OR [ship_city] = '' THEN 1 END) AS Null_ship_city,
    COUNT(CASE WHEN [ship_state] IS NULL OR [ship_state] = '' THEN 1 END) AS Null_ship_state,
    COUNT(CASE WHEN [ship_postal_code] IS NULL OR [ship_postal_code] = '' THEN 1 END) AS Null_ship_postal_code,
    COUNT(CASE WHEN [ship_country] IS NULL OR [ship_country] = '' THEN 1 END) AS Null_ship_country,
    COUNT(CASE WHEN [fulfilled_by] IS NULL OR [fulfilled_by] = '' THEN 1 END) AS Null_fulfilled_by,
	COUNT(CASE WHEN [Unnamed_22] IS NULL OR [Unnamed_22] = '' THEN 1 END) AS Null_Unnamed_22,
    COUNT(CASE WHEN Courier_Status IS NULL OR Courier_Status = '' THEN 1 END) AS Null_Courier_Status
FROM AmazonSale;



/**
Creating view of cleaned data so that, it available for further analysis,
Here i am also handling Null Values 
Cleans missing values with COALESCE()
Removes records where critical data (Amount, currency) is missing
**/

CREATE VIEW Cleaned_AmazonSale AS 
SELECT 
    Order_ID,
    Date,
    Status,
    Fulfilment,
    Sales_Channel,
    ship_service_level,
    Style,
    SKU,
    Category,
    Size,
    ASIN,
    Qty,
    Amount,  
    currency,  
    COALESCE(ship_city, 'Not Provided') AS ship_city,
    COALESCE(ship_state, 'Not Provided') AS ship_state,
    COALESCE(ship_postal_code, 0) AS ship_postal_code,
    COALESCE(ship_country, 'Unknown') AS ship_country,
    COALESCE(fulfilled_by, 'Merchant') AS fulfilled_by,
    COALESCE(Courier_Status, 'Pending') AS Courier_Status
FROM AmazonSale
WHERE Amount IS NOT NULL AND currency IS NOT NULL;  -- Ensuring critical fields are present

-- if have to check view 
SELECT * FROM Cleaned_AmazonSale



-- Query 1 - Total Sales, Numbers of Order , and Amount in average orders spend by customers
-- checking where status is not 'Cancelled' or 'Refunded' so that we get actual insights
SELECT 
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    SUM(Amount) AS Total_Sales,
    ROUND(AVG(Amount), 2) AS AvgAmountPerOrder 
FROM Cleaned_AmazonSale
WHERE Status NOT IN ('Cancelled', 'Refunded');




-- Query 2 - Anlyzing Monthly Sales trend over time 
-- First Checking Status then fromating date 'yyyy-MM' and 
-- counting order id for orders, sum of amount for each month  
SELECT 
    FORMAT(Date, 'yyyy-MM') AS Month,
    COUNT(DISTINCT Order_ID) AS Order_Count,
    SUM(Amount) AS Monthly_Sales
FROM Cleaned_AmazonSale
WHERE Status NOT IN ('Cancelled', 'Refunded')
GROUP BY FORMAT(Date, 'yyyy-MM')
ORDER BY Month





-- Query 3 - Best-Selling Product Categories
-- To identify top performing categories, 
-- Checking status and group by according categories 
-- order them in descending order by revenue
SELECT 
    Category,
    COUNT(*) AS Total_Orders,
    SUM(Amount) AS Revenue
FROM Cleaned_AmazonSale
WHERE Status NOT IN ('Cancelled', 'Refunded')
GROUP BY Category
ORDER BY Revenue DESC;





-- Query 4 - Top 5 Cities by Revenue using CTE's
WITH CitySales AS (
    SELECT ship_city, 
	SUM(Amount) AS Total_Revenue
    FROM AmazonSale
	WHERE Status NOT IN ('Cancelled', 'Refunded')
    GROUP BY ship_city
)
SELECT TOP 5 * FROM CitySales ORDER BY Total_Revenue DESC;





-- Query 5 - Total Orders Cancelled & Cancellation Percentage  
SELECT 
    COUNT(*) AS Total_Orders,
    COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) AS Cancelled_Orders,
    ROUND((COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) * 100) / COUNT(*), 2) AS Cancelled_Percentage
FROM Cleaned_AmazonSale

-- Cancellation Analysis By Categories
SELECT 
    COUNT(*) AS Total_Orders,
    COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) AS Cancelled_Orders,
    ROUND((COUNT(CASE WHEN Status = 'Cancelled' THEN 1 END) * 100) / COUNT(*), 2) AS Cancelled_Percentage
FROM Cleaned_AmazonSale
GROUP BY Category;





-- Query 6 Revenue From Orders with Promotions
-- For Evaluateing promotion effectiveness.
SELECT 
    CASE 
        WHEN promotion_ids IS NOT NULL THEN 'With Promotion' 
        ELSE 'Without Promotion' 
    END AS Promotion_Status,
    COUNT(Order_ID) AS Order_Count,
    SUM(Amount) AS Total_Revenue
FROM AmazonSale
WHERE Status NOT IN ('Cancelled', 'Refunded')
GROUP BY CASE 
    WHEN promotion_ids IS NOT NULL THEN 'With Promotion' 
    ELSE 'Without Promotion' 
    END;





-- Query 7 - Top 10 Customers by Sales
SELECT TOP 10 
    Order_ID, 
    SUM(Amount) AS Total_Spending
FROM AmazonSale
WHERE Status NOT IN ('Cancelled', 'Refunded')
GROUP BY Order_ID
ORDER BY Total_Spending DESC;




