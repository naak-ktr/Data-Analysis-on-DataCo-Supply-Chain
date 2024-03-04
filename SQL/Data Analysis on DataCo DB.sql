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
        8) SHIPPING MODE ANALYSIS
        9) ORDER ANALYSIS
*/

-- 1) SHIPMENT DELAY ANALYSIS

-- 1.1) What is the average delay in shipment days for different shipping mode and regions?
SELECT op.ShippingMode, o.OrderRegion,
	AVG(RealShippingDays - ScheduledShipmentDays) AS Avg_Shipment_Delay
FROM OrdersProcessing op
JOIN Orders o ON op.OrderId = o.OrderId
GROUP BY op.ShippingMode, o.OrderRegion;

-- 1.2) How does the average shipment delay vary across different market location?
SELECT o.MarketLocation,
       (COUNT(CASE WHEN op.DeliveryStatus = 'Shipping on time' THEN 1 END) * 100.0) / COUNT(*) AS On_Time_Delivery_Percentage,
       AVG(op.RealShippingDays) AS Avg_Delivery_Time
FROM Orders o
JOIN Ordersprocessing op ON o.OrderID = op.OrderID
GROUP BY o.MarketLocation;

-- 1.3) What is the average time take between shipment and delivery?
SELECT AVG(DATEDIFF(ShippingDate, OrderDate)) AS Avg_Order_Processing_Time
FROM Orders
WHERE ShippingDate IS NOT NULL;


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

WITH Monthly_Late_Deliveries AS (
    SELECT DATE_FORMAT(o.ShippingDate, '%Y-%m') AS Month,
           COUNT(CASE WHEN op.DeliveryStatus = 'Late delivery' THEN 1 END) AS Late_Deliveries_Count
    FROM Orders o
	JOIN Ordersprocessing op ON o.OrderID = op.OrderID 
    GROUP BY Month
)
SELECT Month,
       Late_Deliveries_Count,
       (Late_Deliveries_Count * 100.0) / SUM(Late_Deliveries_Count) OVER () AS Late_Delivery_Rate
FROM Monthly_Late_Deliveries;

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


-- 2.3) What is the late delivery rate for each shipping mode?
SELECT ShippingMode,
       (COUNT(CASE WHEN DeliveryStatus = 'Late delivery' THEN 1 END) * 100.0) / COUNT(*) AS Late_Delivery_Rate
FROM Ordersprocessing
GROUP BY ShippingMode;

-- 2.4) What is the percentage of late deliveries for each region?
SELECT o.OrderRegion,
       (COUNT(CASE WHEN op.DeliveryStatus = 'Late delivery' THEN 1 END) * 100.0) / COUNT(*) AS Late_Delivery_Rate
FROM Orders o
JOIN Ordersprocessing op ON o.OrderID = op.OrderID
GROUP BY o.OrderRegion;


-- 2.5) What is the percentage of orders shipped on time versus late, and how does it vary by market location?
WITH Delivery_Performance AS (
    SELECT o.MarketLocation,
           SUM(CASE WHEN op.DeliveryStatus = 'Shipping on time' THEN 1 ELSE 0 END) AS On_Time_Shipments,
           SUM(CASE WHEN op.DeliveryStatus = 'Late delivery' THEN 1 ELSE 0 END) AS Late_Shipments,
           COUNT(*) AS Total_Shipments
    FROM Orders o
    JOIN Ordersprocessing op ON o.OrderID = op.OrderID
    GROUP BY o.MarketLocation
)
SELECT MarketLocation,
       On_Time_Shipments,
       Late_Shipments,
       Total_Shipments,
       (On_Time_Shipments * 100.0) / Total_Shipments AS On_Time_Shipment_Percentage,
       (Late_Shipments * 100.0) / Total_Shipments AS Late_Shipment_Percentage
FROM Delivery_Performance;


-- 2.6) What are the main reasons for shipment cancellations, and how do they vary by order status?
SELECT OrderStatus, DeliveryStatus, COUNT(*) AS Cancellation_Count
FROM Ordersprocessing
WHERE DeliveryStatus = 'Shipping canceled'
GROUP BY OrderStatus, DeliveryStatus;

-- 2.7) Are certain customer segments more prone to late deliveries?
SELECT c.CustomerSegment, COUNT(*) AS Late_Deliveries
FROM OrdersProcessing op
JOIN Orders o ON op.OrderId = o.OrderId
JOIN Customer c ON o.OrderCustomerId = c.CustomerId
WHERE op.DeliveryStatus = 'Late delivery'
GROUP BY c.CustomerSegment;



-- 3) INVENTORY ANALYSIS

-- KPI QUESTION
-- Q1: What is the overall average inventory turnover rate across all customer segment?
SELECT c.CustomerSegment, 
       AVG(oi.OrderItemQuantity) AS Avg_Inventory_Level
FROM Customer c
JOIN Orders o ON c.CustomerId = o.OrderCustomerId
JOIN Order_Item oi ON o.OrderId = oi.OrderId
GROUP BY c.CustomerSegment;

-- Q2: How does the on-time delivery rate vary across different product categories?
SELECT c.CategoryName, 
       (COUNT(CASE WHEN op.DeliveryStatus = 'Shipping on time' THEN op.OrderId END) * 100.0 / COUNT(op.OrderId)) AS On_Time_Delivery_Rate
FROM OrdersProcessing op
JOIN Orders o ON op.OrderId = o.OrderId
JOIN Order_Item oi ON o.OrderId = oi.OrderId
JOIN Product p ON oi.ProductCardId = p.ProductCardId
JOIN Category c ON p.CategoryId = c.CategoryId
GROUP BY c.CategoryName;


-- 3.1) What is the current inventory level of each product category
SELECT c.CategoryName, 
	COUNT(*) AS Inventory_Level
FROM Category c
JOIN Product p ON c.CategoryId = p.CategoryId
JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
JOIN Orders o ON oi.OrderId = o.OrderId
WHERE oi.OrderId IN (SELECT OrderId FROM Orders WHERE OrderStatus = 'COMPLETE')
GROUP BY c.CategoryName;


-- 3.2) What is the average number of days it takes to sell out the entire inventory for each product category?
SELECT c.CategoryName, 
       AVG(DATEDIFF(max_order_date, min_order_date)) AS Avg_Days_To_Sell_Out
FROM Category c
JOIN Product p ON c.CategoryId = p.CategoryId
JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
JOIN (
    SELECT ProductCardId,
           MIN(o.OrderDate) AS min_order_date,
           MAX(o.OrderDate) AS max_order_date
    FROM Orders o
    JOIN Order_Item oi ON o.OrderId = oi.OrderId
    GROUP BY ProductCardId
) AS order_dates ON p.ProductCardId = order_dates.ProductCardId
GROUP BY c.CategoryName;


-- 3.3) What is the average inventory turnover rate for each product category?
SELECT c.CategoryName,
       COUNT(DISTINCT o.OrderId) / COUNT(DISTINCT p.ProductCardId) AS Avg_Inventory_Turnover_Rate
FROM Category c
JOIN Product p ON c.CategoryId = p.CategoryId
JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
JOIN Orders o ON oi.OrderId = o.OrderId
GROUP BY c.CategoryName;


-- 3.4) What is the average inventory turnover rate for the entire inventory?
SELECT 
    SUM(oi.OrderItemQuantity) AS Total_Quantity,
    COUNT(DISTINCT oi.OrderId) AS Total_Orders,
    SUM(oi.OrderItemQuantity) / COUNT(DISTINCT oi.OrderId) AS Avg_Inventory_Turnover_Rate
FROM Order_Item oi;


-- 3.5) Which products have the highest sales volume relative to inventory levels, categorized by product category?
SELECT c.CategoryName, 
       p.ProductName,
       SUM(oi.OrderItemQuantity) AS Total_Sales,
       AVG(oi.OrderItemQuantity) AS Avg_Inventory_Level
FROM Product p
JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
JOIN Category c ON p.CategoryId = c.CategoryId
GROUP BY c.CategoryName, p.ProductName
ORDER BY (SUM(oi.OrderItemQuantity) / AVG(oi.OrderItemQuantity)) DESC;


-- 3.6) Which products have been in stock for the longest duration without being sold?
-- Note: Inventory Age = Difference in Days between the maximum order date (when the product was sold) and the minimum order date (when the product was added to inventory).
WITH Inventory_Age AS (
    SELECT p.CategoryId, 
           p.ProductName,
           DATEDIFF(MAX(o.OrderDate), MIN(o.OrderDate)) AS Inventory_Age
    FROM Product p
    JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
    JOIN Orders o ON oi.OrderId = o.OrderId
    GROUP BY p.CategoryId, p.ProductName
)
SELECT c.CategoryName, 
       ia.ProductName,
       ia.Inventory_Age
FROM Inventory_Age ia
JOIN Category c ON ia.CategoryId = c.CategoryId
ORDER BY ia.Inventory_Age DESC;


-- 4.4) How many times does the inventory turn over in a year for each product category?
SELECT c.CategoryName, 
       COUNT(DISTINCT oi.OrderId) / COUNT(DISTINCT p.ProductCardId) AS Inventory_Turnover_Rate
FROM Product p
LEFT JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
LEFT JOIN Category c ON p.CategoryId = c.CategoryId
LEFT JOIN Orders o ON oi.OrderId = o.OrderId
WHERE o.OrderStatus = 'COMPLETE'
GROUP BY c.CategoryName;


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
    INNER JOIN Order_Item oi ON p.ProductCardId = oi.ProductCardId
GROUP BY
    p.ProductCardId, p.ProductName
ORDER BY
    TotalProfit DESC
LIMIT 5;

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
    
-- 6.3) What are the top-selling products based on total sales amount?
SELECT 
    p.ProductName,
    SUM(oi.OrderItemTotal) AS Total_Sales
FROM Order_Item oi
JOIN Product p ON oi.ProductCardId = p.ProductCardId
GROUP BY p.ProductName
ORDER BY Total_Sales DESC;


-- 7) GEOGRAPHICAL SALES ANALYSIS
    
-- 7.1) What are the total sales for each country?
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

-- 7.2) What are the top regions in terms of sales revenue?
SELECT o.OrderRegion, SUM(oi.Sales) AS Total_Revenue
FROM Orders o
JOIN Order_Item oi ON o.OrderId = oi.OrderId
GROUP BY o.OrderRegion
ORDER BY Total_Revenue DESC;
 
 
-- 8) SHIPPING MODE ANALYSIS

-- 8.1) What is the average profit per order for each shipping mode?
SELECT op.ShippingMode, 
       AVG(o.OrderProfitPerOrder) AS Avg_Profit_Per_Order
FROM OrdersProcessing op
JOIN Orders o ON op.OrderId = o.OrderId
GROUP BY op.ShippingMode;


-- 8.2) How many orders were shipped late for each shipping mode?
    
SELECT
    op.ShippingMode,
    COUNT(*) AS LateOrders
FROM
    OrdersProcessing op
WHERE
    op.LateDeliveryRisk = 1
GROUP BY
    op.ShippingMode;

-- 8.3) Which shipping mode is associated with the highest profit per order?
SELECT op.ShippingMode, AVG(o.OrderProfitPerOrder) AS Avg_Profit_Per_Order
FROM OrdersProcessing op
JOIN Orders o ON op.OrderId = o.OrderId
GROUP BY op.ShippingMode
ORDER BY Avg_Profit_Per_Order DESC;
   
   
   
-- 9) ORDER ANALYSIS

-- KPI
-- Q1: What is the distribution of order statuses for all orders?
SELECT OrderStatus, 
       (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Orders)) AS Percentage_Order_Status
FROM OrdersProcessing
GROUP BY OrderStatus;

-- 9.1) What is the percentage distribution of different order statuses?
SELECT 
    op.OrderStatus,
    COUNT(*) AS Orders_Count,
    (COUNT(*) * 100.0) / (SELECT COUNT(*) FROM OrdersProcessing) AS Status_Percentage
FROM OrdersProcessing op
GROUP BY op.OrderStatus;

-- 9.2) What is the average processing time for each shipping mode?
SELECT ShippingMode, 
       AVG(RealShippingDays) AS Avg_Processing_Time
FROM Ordersprocessing
GROUP BY ShippingMode;