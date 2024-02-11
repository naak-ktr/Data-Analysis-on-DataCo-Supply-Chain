-- SQL PROJECT: DATABASE DESIGN FOR A SUPPLY CHAIN COMPANY (DataCo)

/*
PROJECT OVERVIEW
------------------

This project requires us to build a simple database to help us track and manage customer orders 
of a supply chain company called DataCo. The system will provide insights into sales 
performance, delivery status, and customer behavior, enabling better decision-making for 
the organization. This system aims to streamline the entire supply chain process, 
from order placement to product delivery, thus enhancing overall operational efficiency.

INSTRUCTIONS
------------------

The Database should contain the following tables:
1) Order
2) Customer
3) Product
4) Category
5) OrderItem
6) Department
7) Shipping Mode

*/
-- CREATE A DATABASE FOR DATACO SUPPLY CHAIN MANAGEMENT SYSTEM
CREATE DATABASE DataCo_DB 
DEFAULT CHARACTER SET utf8mb4;

-- TO ENSURE THE DATABASE WAS CREATED
SHOW DATABASES;

-- TO MAKE IT THE ACTIVE DATABASE
USE DataCo_DB;

------------------------------------------------------------------------------------------------

-- A) CREATING TABLES

-- CREATING THE TABLE
/* 
The data is in a CSV file and after observing the data, I figured out that the data is non-normalized and it 
would normalized after importing the data to a table. 

The next step is to create a table
*/
-- to make the dataco_db database the active database 
USE dataco_db;

-- INSERTING DATA INTO THE CREATED TABLE
/* 
Currently, the dataset sits in my local device so I could either use the 
- Table Data Import WIzard
- Use a query to load the data from your local device

The Table Data Import Wizard was used because I was having diffulties scaling through this error

"ERROR: 3948: Loading local data is disabled; this must be enabled on both the client and server sides"

but this is the code to load using MySQL Command Prompt

Note: Make sure to insert the desired CSV table under this path to enable this code to run under MySQL Coomand Line Client (Run as admin)
'/ProgramData/MySQL/MySQL Server 8.0/Data/dataco_db'
*/

LOAD DATA LOCAL INFILE 'C/ProgramData/MySQL/MySQL Server 8.0/Data/dataco_db/DataCo Supply Chain Dataset.csv' -- table path
INTO TABLE TblDataCo
FIELDS TERMINATED BY ',' -- csv file
ENCLOSED BY '"' -- for the strings
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- ignore the headers

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';

-- to check the table for the loaded data
SELECT *
FROM TblDataCo;

--- 1) CREATE ORDERS TABLE

DROP TABLE IF EXISTS Orders;

CREATE TABLE Orders(
	OrderId VARCHAR(255),
    OrderCustomerId VARCHAR(255),
    OrderDate DATE,
    OrderStatus VARCHAR(255),
	OrderProfitPerOrder DECIMAL(10, 2),
    MarketLocation VARCHAR(255),
    OrderCity VARCHAR(255),
    OrderState VARCHAR(255),
    OrderCountry VARCHAR(255),
    OrderRegion VARCHAR(255),
    ShippingDate DATE,
    DepartmentId INTEGER,
    PRIMARY KEY(OrderId),
    FOREIGN KEY(DepartmentId) REFERENCES Department(DepartmentId)
    );
    
SHOW VARIABLES WHERE Variable_Name LIKE "%dir" ;

 
-- Loading data into the Orders Table since 
LOAD DATA LOCAL INFILE 'C/ProgramData/MySQL/MySQL Server 8.0/Data/dataco_db/orders.csv'
INTO TABLE Orders
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS; -- Skip header row if present

SHOW GRANTS;

-- 2) CREATE CUSTOMER TABLE

DROP TABLE IF EXISTS Customer;

CREATE TABLE Customer (
	CustomerId VARCHAR(255),
    FirstName VARCHAR(255),
    LastName VARCHAR(255),
    CustomerCity VARCHAR(255),
    CustomerCountry VARCHAR(255),
    CustomerState VARCHAR(255),
    CustomerStreet VARCHAR(255) NOT NULL,
    CustomerZipCode VARCHAR(255),
    Latitude DECIMAL(10, 6),
    Longitude DECIMAL(10, 6),
    CustomerSegment VARCHAR(255),
    CustomerEmail VARCHAR(255),
    CustomerPassword VARCHAR(255),
    PRIMARY KEY (CustomerId)
    );
    
-- 3) CREATE PRODUCT TABLE

DROP TABLE IF EXISTS Product;

CREATE TABLE Product (
	ProductCardId VARCHAR(255),
    Categoryid VARCHAR(255) NOT NULL,
    ProductName VARCHAR(255),
    ProductDesc VARCHAR(255),
    ProductImage VARCHAR(255),
    ProductPrice DECIMAL(10, 2),
    ProductStatus VARCHAR(255) NOT NULL,
    PRIMARY KEY (ProductCardId)
    );
    
-- 4) CREATE CATEGORY TABLE

DROP TABLE IF EXISTS Category;

CREATE TABLE Category (
	CategoryId VARCHAR(255),
    CategoryName VARCHAR(255),
    PRIMARY KEY (CategoryId)
    );
    
    
-- 5) CREATE ORDER_ITEM TABLE

DROP TABLE IF EXISTS Order_Item;

CREATE TABLE Order_Item (
	OrderItemId  VARCHAR(255),
    OrderId VARCHAR(255) NOT NULL,
    ProdcutCardId VARCHAR(255),
    OrderItemCardprodId VARCHAR(255),
    OrderItemDiscount DECIMAL(10, 2),
    OrderItemDiscountRate DECIMAL(5, 2),
    OrderItemProductPrice DECIMAL(10, 2),
    OrderItemProfitRatio DECIMAL(5, 2),
    OrderItemQuantity INT,
	OrderItemTotal DECIMAL(10, 2),
    Sales DECIMAL(10, 2),
    OrderProfitPerOrder DECIMAL(10, 2),
    PRIMARY KEY (OrderItemId)
    );
    
    
-- 6) CREATE DEPARTMENT TABLE

DROP TABLE IF EXISTS Department;

CREATE TABLE Department (
	DepartmentId INT,
    DepartmentName VARCHAR(255),
    PRIMARY KEY (DepartmentId)
    );
    

-- 7) CREATE ORDERS PROCESSING TABLE

DROP TABLE IF EXISTS OrdersProcessing;

CREATE TABLE OrdersProcessing (
	OrderId VARCHAR(255),
    TransactionType VARCHAR(255),
    RealShippingDays INT,
    ScheduledShipmentDays INT,
    BenefitPerOrder DECIMAL(10, 2),
    ShippingMode VARCHAR(255),
    DeliveryStatus VARCHAR(255),
    OrderStatus VARCHAR(255),
    LateDeliveryRisk BOOLEAN,
    PRIMARY KEY (OrderId)
    );    
    
    
-- TO VERIFY IF ALL THE TABLES WERE CREATED 
SELECT * 
FROM information_schema.columns
WHERE TABLE_SCHEMA = "dataco_db";
    

    
-- B) ALTERING TABLE CONSTRAINTS


-- 1) ORDERS TABLE FOREIGN KEY: CustomerId
/*
For the `CustomerId` column in the foreign key, the rule to create this foreign key is given below

RULE APPLIED
When the record in the Customer table is updated or deleted, the record in the Orders table will also be updated or
deleted accordingly. 

*/

-- Altering the Orders table to add foreign key
ALTER TABLE Orders 
  ADD CONSTRAINT customer_fk 
  FOREIGN KEY (OrderCustomerId) 
  REFERENCES Customer(CustomerId) 
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  

-- 2) ORDER_ITEM TABLE FOREIGN KEY: OrderId
/*
For the `OrderId` column in the foreign key, the rule to create this foreign key is given below

RULE APPLIED
When the record in the Order table is updated or deleted, the record in the Order_Item table will also be updated or
deleted accordingly. 

*/

-- Altering the Order_Item table to add foreign key
ALTER TABLE Order_Item 
  ADD CONSTRAINT order_item_fk
  FOREIGN KEY (OrderId) 
  REFERENCES Orders(OrderId) 
  ON DELETE CASCADE
  ON UPDATE CASCADE;
 


-- 3) Altering the Orders_Processing table to add foreign key (OrderId)
/*
For the `OrderId` column in the foreign key, the rule to create this foreign key is given below

RULE APPLIED
When the record in the Order table is updated or deleted, the record in the Orders_Processing table 
will also be updated or deleted accordingly. 

*/
ALTER TABLE OrdersProcessing
  ADD CONSTRAINT orders_processing_fk
  FOREIGN KEY (OrderId) 
  REFERENCES Orders(OrderId) 
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
-- 4) Altering the Product table to add foreign key (CategoryId)
/*
For the `CategoryId` column in the foreign key, the rule to create this foreign key is given below

RULE APPLIED
When the record in the Category table is updated or deleted, the record in the Product table 
will also be updated or deleted accordingly. 

*/
ALTER TABLE Product
  ADD CONSTRAINT product_fk
  FOREIGN KEY (CategoryId) 
  REFERENCES Category(CategoryId) 
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  

-- 5) Altering the Order table to add foreign key (DepartmentId)
/*
For the `DepartmentId` column in the foreign key, the rule to create this foreign key is given below

RULE APPLIED
When the record in the Department table is updated or deleted, the record in the Order table 
will also be updated or deleted accordingly. 

*/
ALTER TABLE Orders
  ADD CONSTRAINT department_fk
  FOREIGN KEY (DepartmentId) 
  REFERENCES Department(DepartmentId) 
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
-- 6) Altering the Order table to add foreign key (ProductCardId)
/*
For the `ProductCardId` column in the foreign key, the rule to create this foreign key is given below

RULE APPLIED
When the record in the Product table is updated or deleted, the record in the Order_Item table 
will also be updated or deleted accordingly. 

*/
ALTER TABLE Order_Item
  ADD CONSTRAINT product_card_fk
  FOREIGN KEY (ProdcutCardId) 
  REFERENCES Product(ProductCardId) 
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
-- To check if the tables were created and constraints are properly placed
DESCRIBE orders;
DESCRIBE order_item;
DESCRIBE customer;
DESCRIBE product;
DESCRIBE category;
DESCRIBE department;