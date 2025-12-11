/************************************************************** 
Title: Assignment05 Setup - Part 3
Description: This scipt fills the OLAP data warehouse database 
with data from the OLTP database for use with assignment 06.
ChangeLog: When,Who,What
20201118,RRoot,Created Script
**************************************************************/

USE [DWNorthwindLite];
Go

Set NoCount On;
--********************************************************************--
-- 1) Drop the FOREIGN KEY CONSTRAINTS and Clear the tables
--********************************************************************--
Alter Table [DWNorthwindLite].dbo.FactOrders -- The Many Child Table
	Drop Constraint [FK_FactOrders_DimProducts]; 
Alter Table [DWNorthwindLite].dbo.FactOrders -- The Many Child Table
	Drop Constraint [FK_FactOrders_DimCustomers]; 
Alter Table [DWNorthwindLite].dbo.FactOrders -- The Many Child Table
	Drop Constraint [FK_FactOrders_DimDates]; 

Truncate Table [DWNorthwindLite].dbo.DimProducts; -- The Single Parent Table
Truncate Table [DWNorthwindLite].dbo.DimCustomers; -- The Single Parent Table
Truncate Table [DWNorthwindLite].dbo.DimDates; -- The Single Parent Table
Truncate Table [DWNorthwindLite].dbo.FactOrders; -- The Single Child Table

--********************************************************************--
-- 2) FILL the Tables
--********************************************************************--

/****** [dbo].[DimProducts] ******/
INSERT INTO [DWNorthwindLite].dbo.DimProducts
SELECT
  [ProductID] = Products.ProductID
 ,[ProductName] = CAST(Products.ProductName as nVarchar(100))
 ,[ProductCategoryID] = Products.CategoryID
 ,[ProductCategoryName] = CAST(Categories.CategoryName as nVarchar(100))
 ,[StartDate] = -1
 ,[EndDate] = Null
 ,[IsCurrent] = 'Yes'
FROM [NorthwindLite].dbo.Categories
INNER JOIN [NorthwindLite].dbo.Products
ON Categories.CategoryID = Products.CategoryID;
Go
-- Select * From DimProducts

/****** [dbo].[DimCustomers] ******/
INSERT INTO [DWNorthwindLite].dbo.DimCustomers
SELECT
  [CustomerID] = [CustomerID]
, [CustomerName] = Cast([CompanyName] as nvarchar(100))
, [CustomerCity] = Cast([City] as nvarchar(100))
, [CustomerCountry] = Cast([Country] as nvarchar(100))
 ,[StartDate] = -1
 ,[EndDate] = Null
 ,[IsCurrent] = 'Yes'
FROM [NorthwindLite].[dbo].[Customers]
Go
-- Select * From DimCustomers

/****** [dbo].[DimDates] ******/
-- Create variables to hold the start and end date
Declare @StartDate datetime = '01/01/1990'
Declare @EndDate datetime = '12/31/1999' 

-- Use a while loop to add dates to the table
Declare @DateInProcess datetime
Set @DateInProcess = @StartDate

While @DateInProcess <= @EndDate
 Begin
 -- Add a row into the date dimension table for this date
 Insert Into DimDates 
 ( [DateKey], [USADateName], [MonthKey], [MonthName], [QuarterKey], [QuarterName], [YearKey], [YearName] )
 Values ( 
    Cast(Convert(nvarchar(50), @DateInProcess , 112) as int) -- [DateKey]
  , DateName( weekday, @DateInProcess ) + ', ' + Convert(nvarchar(50), @DateInProcess , 110) -- [USADateName]  
  , Left(Cast(Convert(nvarchar(50), @DateInProcess , 112) as int), 6) -- [MonthKey]   
  , DateName( MONTH, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [MonthName]
  ,  Cast(Cast(YEAR(@DateInProcess) as nvarchar(50))  + '0' + DateName( QUARTER,  @DateInProcess) as int) -- [QuarterKey]
  , 'Q' + DateName( QUARTER, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess) as nVarchar(50) ) -- [QuarterName] 
  , Year( @DateInProcess ) -- [YearKey]
  , Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [YearName] 
  )  
 -- Add a day and loop again
 Set @DateInProcess = DateAdd(d, 1, @DateInProcess)
 End

 -- 2e) Add additional lookup values to DimDates -- [This data will NOT WORK with SSAS Tabular due to conversion issues]
Insert Into [DWNorthwindLite].[dbo].[DimDates] 
  ( [DateKey]
  , [USADateName]
  , [MonthKey]
  , [MonthName]
  , [QuarterKey]
  , [QuarterName]
  , [YearKey]
  , [YearName] )
  Select 
    [DateKey] = -1
  , [DateName] = Cast('Unknown Day' as nVarchar(50) )
  , [Month] = -1
  , [MonthName] = Cast('Unknown Month' as nVarchar(50) )
  , [Quarter] =  -1
  , [QuarterName] = Cast('Unknown Quarter' as nVarchar(50) )
  , [Year] = -1
  , [YearName] = Cast('Unknown Year' as nVarchar(50) )
  Union
  Select 
    [DateKey] = -2
  , [DateName] = Cast('Corrupt Day' as nVarchar(50) )
  , [Month] = -2
  , [MonthName] = Cast('Corrupt Month' as nVarchar(50) )
  , [Quarter] =  -2
  , [QuarterName] = Cast('Corrupt Quarter' as nVarchar(50) )
  , [Year] = -2
  , [YearName] = Cast('Corrupt Year' as nVarchar(50) )
Go
 Select * From DimDates

/****** [dbo].[FactOrders] ******/
INSERT INTO [DWNorthwindLite].dbo.FactOrders
SELECT  
  [OrderID] = Orders.OrderID
, [CustomerKey] = DimCustomers.CustomerKey
, [OrderDateKey] = DimDates.DateKey
, [ProductKey] = DimProducts.ProductKey
, [ActualOrderUnitPrice] = OrderDetails.UnitPrice
, [ActualOrderQuantity] = OrderDetails.Quantity
FROM   [NorthwindLite].dbo.Orders
INNER JOIN  [DWNorthwindLite].dbo.DimCustomers
	ON DimCustomers.CustomerID = Orders.CustomerID 
INNER JOIN [NorthwindLite].dbo.OrderDetails 
	ON Orders.OrderID = OrderDetails.OrderID 
INNER JOIN [DWNorthwindLite].dbo.DimProducts
	ON OrderDetails.ProductID = DimProducts.ProductID
INNER JOIN [DWNorthwindLite].dbo.DimDates
	On DimDates.DateKey = isNull(Convert(nvarchar(50), Orders.OrderDate, 112), '-1')
Go

--********************************************************************--
-- 3) Re-Create the FOREIGN KEY CONSTRAINTS
--********************************************************************--
ALTER TABLE DWNorthwindLite.dbo.FactOrders -- The Many Child Table 
  ADD CONSTRAINT FK_FactOrders_DimProducts
  FOREIGN KEY (ProductKey) REFERENCES DimProducts(ProductKey); -- The Single Parent Table

ALTER TABLE DWNorthwindLite.dbo.FactOrders
  ADD CONSTRAINT FK_FactOrders_DimCustomers
  FOREIGN KEY (CustomerKey) REFERENCES DimCustomers(CustomerKey)

ALTER TABLE DWNorthwindLite.dbo.FactOrders
  ADD CONSTRAINT FK_FactOrders_DimDates 
  FOREIGN KEY (OrderDateKey) REFERENCES DimDates(DateKey)

--********************************************************************--
-- Review the results of this script
--********************************************************************--
Select * from [dbo].[DimProducts];
Select * from [dbo].[DimCustomers];
Select * from [dbo].[DimDates];
Select * from [dbo].[FactOrders];