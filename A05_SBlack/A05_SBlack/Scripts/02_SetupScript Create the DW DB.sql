/************************************************************** 
Title: Assignment05 Setup - Part 2
Description: This scipt creates an OLAP data warehouse database 
for use with assignment 05.
ChangeLog: When,Who,What
20201118,RRoot,Created Script
**************************************************************/

USE [master]
GO
If Exists (Select * from Sysdatabases Where Name = 'DWNorthwindLite')
	Begin 
		ALTER DATABASE [DWNorthwindLite] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE [DWNorthwindLite]
	End
GO
Create Database [DWNorthwindLite]
Go

--********************************************************************--
-- Create the Tables
--********************************************************************--
USE [DWNorthwindLite]
Go

/****** [dbo].[DimProducts] ******/
CREATE TABLE DWNorthwindLite.dbo.DimProducts(
	 ProductKey int	IDENTITY   		   NOT NULL
	,ProductID int			   		   NOT NULL
	,ProductName nVarchar(100) 		   NOT NULL
	,ProductCategoryID int	   		   NOT NULL
	,ProductCategoryName nVarchar(100) NOT NULL 
	,StartDate int			   		   NOT NULL
	,EndDate int			  		   NULL
	,IsCurrent char(3)		  		   NOT NULL
	CONSTRAINT PK_DimProducts PRIMARY KEY (ProductKey)
)
Go

/****** [dbo].[DimCustomers] ******/
CREATE TABLE DWNorthwindLite.dbo.DimCustomers(
	 CustomerKey int IDENTITY	   NOT NULL
	,CustomerID nchar(5)		   NOT NULL
	,CustomerName nVarchar(100)	   NOT NULL
	,CustomerCity nVarchar(100)	   NOT NULL
	,CustomerCountry nVarchar(100) NOT NULL
	,StartDate int				   NOT NULL
	,EndDate int				   NULL
	,IsCurrent char(3)			   NOT NULL
	CONSTRAINT PK_DimCustomers PRIMARY KEY (CustomerKey)
)
Go

/****** [dbo].[DimDates] ******/
CREATE TABLE DWNorthwindLite.dbo.DimDates(
	 DateKey int			   NOT NULL
	,USADateName nVarchar(100) NOT NULL
	,MonthKey int			   NOT NULL
	,MonthName nVarchar(100)   NOT NULL
	,QuarterKey int			   NOT NULL
	,QuarterName nVarchar(100) NOT NULL
	,YearKey int			   NOT NULL
	,YearName nVarchar(100)	   NOT NULL
	CONSTRAINT PK_DimDates PRIMARY KEY (DateKey)
)
Go

/****** [dbo].[FactOrders] ******/
CREATE TABLE DWNorthwindLite.dbo.FactOrders(
	 OrderID int				 NOT NULL
	,CustomerKey int			 NOT NULL
	,OrderDateKey int			 NOT NULL
	,ProductKey int				 NOT NULL
	,ActualOrderUnitPrice money	 NOT NULL
	,ActualOrderQuantity int	 NOT NULL
	CONSTRAINT PK_FactOrders PRIMARY KEY (OrderID,CustomerKey,OrderDateKey,ProductKey)
)
Go

--********************************************************************--
-- Create the FOREIGN KEY CONSTRAINTS
--********************************************************************--
ALTER TABLE DWNorthwindLite.dbo.FactOrders
  ADD CONSTRAINT FK_FactOrders_DimProducts
  FOREIGN KEY (ProductKey) REFERENCES DimProducts(ProductKey)

ALTER TABLE DWNorthwindLite.dbo.FactOrders
  ADD CONSTRAINT FK_FactOrders_DimCustomers
  FOREIGN KEY (CustomerKey) REFERENCES DimCustomers(CustomerKey)

ALTER TABLE DWNorthwindLite.dbo.FactOrders
  ADD CONSTRAINT FK_FactOrders_DimDates 
  FOREIGN KEY (OrderDateKey) REFERENCES DimDates(DateKey)

--********************************************************************--
-- Review the results of this script
--********************************************************************--
Select 'New database made with these objects:'
Select Name as [ObjectName] From SysObjects Where xtype in ('u', 'pk', 'f')
SELECT [TABLE_NAME]
      ,[COLUMN_NAME]
      ,[IS_NULLABLE]
      ,[DATA_TYPE]
      ,[CHARACTER_MAXIMUM_LENGTH]
      ,[NUMERIC_PRECISION]
      ,[NUMERIC_SCALE]
FROM [NorthwindLite].[INFORMATION_SCHEMA].[COLUMNS];
Go