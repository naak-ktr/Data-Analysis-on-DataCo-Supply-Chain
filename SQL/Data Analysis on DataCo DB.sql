USE dataco_db;

-- C) DATA ANALYSIS ON DATACO DB
/*  There are several insightful questions you can explore through SQL queries 
	and visualize using Power BI
    
    Data Analysis on DataCo DB data was done based on these sections
		1) SHIPMENT DELAY ANALYSIS
        2) LATE DELIVERY ANALYSIS
        3) INVENTORY ANALYSIS
        4) INVENTORY REPLENISHMENT ANALYSIS
        5) CUSTOMER ANALYSIS
        6) PRODUCT ANALYSIS
        7) GEOGRAPHICAL ANALYSIS
        8) DELIVERY PERFORMANCE ANALYSIS
        9) CUSTOMER LOCATION / TREND ANALYSIS
*/

-- 1) SHIPMENT DELAY ANALYSIS

-- 1.1) What is the average delay in shipment days for different shipping 
SELECT ShippingMode, AVG(RealShippingDays - ScheduledShipmentDays) AS Avg_Shipment_Delay
FROM Ordersprocessing
GROUP BY ShippingMode;

-- 1.2) How does the average shipment delay vary across different customer segments?



-- 2) LATE DELIVERY ANALYSIS

-- 2.1) How have late delivery rates changed over time? (e.g., monthly trend)
SELECT YEAR(o.ShippingDate) AS Year, MONTH(o.ShippingDate) AS Month,
       SUM(CASE WHEN op.DeliveryStatus = 'Late delivery' THEN 1 ELSE 0 END) AS Late_Deliveries,
       COUNT(*) AS Total_Deliveries,
       (SUM(CASE WHEN op.DeliveryStatus = 'Late delivery' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS Late_Delivery_Rate
FROM Orders o
JOIN Ordersprocessing op ON o.OrderID = op.OrderID
GROUP BY YEAR(o.ShippingDate), MONTH(o.ShippingDate)
ORDER BY Year, Month;


-- 2.2) What is the percentage of late deliveries in each market location?
WITH Late_Deliveries AS (
    SELECT o.MarketLocation, COUNT(*) AS Late_Deliveries_Count
    FROM Orders o
    JOIN Ordersprocessing op ON o.OrderID = op.OrderID
    WHERE op.DeliveryStatus = 'Late delivery'
    GROUP BY o.MarketLocation
)
SELECT ld.MarketLocation, ld.Late_Deliveries_Count, o.Total_Orders,
       (ld.Late_Deliveries_Count * 100.0) / o.Total_Orders AS Late_Delivery_Percentage
FROM Late_Deliveries ld
JOIN (
    SELECT MarketLocation, COUNT(*) AS Total_Orders
    FROM Orders o
    GROUP BY o.MarketLocation
) o ON ld.MarketLocation = o.MarketLocation; 


-- 3) INVENTORY ANALYSIS

-- 3.1) What are the top-selling products that are frequently out of stock?
WITH Inventory_Status AS (
    SELECT p.ProductName, COUNT(*) AS Orders_Count
    FROM Order_Item oi
    JOIN Product p ON oi.ProductCardId = p.ProductCardId
    JOIN Orders o ON oi.OrderID = o.OrderID
    WHERE oi.OrderItemQuantity = 0
    GROUP BY p.ProductName
)
SELECT i.ProductName, i.Orders_Count, p.ProductPrice
FROM Inventory_Status i
JOIN Product p ON i.ProductName = p.ProductName
ORDER BY i.Orders_Count DESC;

-- 3.2) What is the average inventory turnover rate for each product category?
SELECT p.ProductCardId, AVG(oi.OrderItemQuantity) AS Avg_Quantity,
       COUNT(DISTINCT oi.OrderItemID) AS Total_Orders
FROM Order_Item oi
JOIN Product p ON oi.ProductCardId = p.ProductCardId
GROUP BY p.Categoryid;

-- 4) INVENTORY REPLENSIHMENT ANALYSIS

-- 4.1) How long does it typically take to restock inventory after an out-of-stock event, broken down by product category?
WITH Out_of_Stock_Orders AS (
    SELECT oi.ProductCardId, p.Categoryid, o.OrderDate,
           LEAD(o.OrderDate) OVER (PARTITION BY oi.ProductCardId ORDER BY o.OrderDate) AS Next_Order_Date
    FROM Order_Item oi
    JOIN Orders o ON oi.OrderId = o.OrderId
    JOIN Product p ON oi.ProductCardId = p.ProductCardId
    WHERE oi.OrderItemQuantity = 0
)
SELECT Categoryid, AVG(DATEDIFF(day, OrderDate, Next_Order_Date)) AS Avg_Replenishment_Time
FROM Out_of_Stock_Orders
WHERE Next_Order_Date IS NOT NULL
GROUP BY Categoryid;

-- 4.2) What is the average time between restocking orders for products that frequently go out of stock?
WITH Out_of_Stock_Orders AS (
    SELECT oi.Product_Card_Id, o.Order_Date,
           LEAD(o.Order_Date) OVER (PARTITION BY oi.Product_Card_Id ORDER BY o.Order_Date) AS Next_Order_Date
    FROM Order_Items oi
    JOIN Orders o ON oi.Order_ID = o.Order_ID
    WHERE oi.Order_Item_Quantity = 0
)
SELECT Product_Card_Id, AVG(DATEDIFF(day, Order_Date, Next_Order_Date)) AS Avg_Replenishment_Time
FROM Out_of_Stock_Orders
WHERE Next_Order_Date IS NOT NULL
GROUP BY Product_Card_Id;


-- 5) CUSTOMER ANALYSIS

-- 5.1) What are the top 10 customers based on the total sales amount?
SELECT
    c.CustomerId,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(oi.Sales) AS TotalSales
FROM
    Customer c
    INNER JOIN Orders o ON c.CustomerId = o.OrderCustomerId
    INNER JOIN Order_Item oi ON o.OrderId = oi.OrderId
GROUP BY
    c.CustomerId, CustomerName
ORDER BY
    TotalSales DESC
LIMIT 10;

-- 5.2) Which customer segments generate the highest profit for the company?
SELECT c.CustomerSegment, SUM(o.OrderProfitPerOrder) AS Total_Profit
FROM Customer c
INNER JOIN Orders o ON c.CustomerId = o.OrderCustomerId
GROUP BY c.CustomerSegment
ORDER BY Total_Profit DESC;


-- 6) PRODUCT ANALYSIS

-- 6.1) What are the top 5 most profitable products?

SELECT
    p.ProductCardId,
    p.ProductName,
    SUM(oi.OrderItemProfitRatio * oi.OrderItemProductPrice) AS TotalProfit
FROM
    Product p
    INNER JOIN Order_Item oi ON p.ProductCardId = oi.ProdcutCardId
GROUP BY
    p.ProductCardId, p.ProductName
ORDER BY
    TotalProfit DESC;

-- 6.2) What are the top-selling products by quantity and revenue?  
SELECT p.ProductName, 
	SUM(oi.OrderItemQuantity) AS Total_Quantity, 
	SUM(oi.Sales) AS Total_Revenue
FROM Order_Item oi
JOIN Product p ON oi.ProductCardId = p.ProductCardId
GROUP BY p.ProductName
ORDER BY Total_Quantity DESC, Total_Revenue DESC;

-- 6.3) What is the average profit ratio for each product category?
SELECT
    c.CategoryName,
    AVG(oi.OrderItemProfitRatio) AS AvgProfitRatio
FROM
    Category c
    INNER JOIN Product p ON c.CategoryId = p.CategoryId
    INNER JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
GROUP BY
    c.CategoryName;

-- 7) ORDER ANALYSIS

-- 7.1) How does the average order profit vary across different shipping modes?
SELECT op.ShippingMode, AVG(o.OrderProfitPerOrder) AS Avg_Profit
FROM Ordersprocessing op
JOIN Ordersprocessing op ON op.OrderID = o.OrderID
GROUP BY op.ShippingMode;

-- 7.2) How many orders were shipped late for each shipping mode?
    
SELECT
    op.ShippingMode,
    COUNT(*) AS LateOrders
FROM
    OrdersProcessing op
WHERE
    op.LateDeliveryRisk = 1
GROUP BY
    op.ShippingMode;
 
 
-- 8) GEOGRAPHICAL ANALYSIS

-- 8.1) What are the total sales for each country?
SELECT
    o.OrderCountry,
    SUM(oi.Sales) AS TotalSales
FROM
    Orders o
    INNER JOIN Order_Item oi ON o.OrderId = oi.OrderId
GROUP BY
    o.OrderCountry
ORDER BY
    TotalSales DESC;

-- 8.2) What are the top regions in terms of sales revenue?
SELECT o.OrderRegion, SUM(oi.Sales) AS Total_Revenue
FROM Orders
GROUP BY o.OrderRegion
ORDER BY Total_Revenue DESC;
   

-- 9) TRENDS ANALYSIS
   
-- 9.1) How does the total sales amount vary over time?
SELECT 
    DATEPART(year, OrderDate) AS OrderYear,
    DATEPART(month, OrderDate) AS OrderMonth,
    SUM(Sales) AS TotalSales
FROM Orders
GROUP BY DATEPART(year, OrderDate), DATEPART(month, OrderDate)
ORDER BY OrderYear, OrderMonth;

