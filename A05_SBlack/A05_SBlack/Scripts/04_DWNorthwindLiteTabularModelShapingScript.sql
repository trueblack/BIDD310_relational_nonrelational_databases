/************************************************************** 
Title: Assignment05 Setup - Part 4
Description: This scipt creates views that shape the data to 
work with the SSAS tabular model in assignment 06.
ChangeLog: When,Who,What
20201118,RRoot,Created Script
**************************************************************/

Use [DWNorthwindLite];
go

Create or Alter View vDimCustomersForTabularModel
As
Select
 [CustomerKey]
,[CustomerID]
,[CustomerName]
,[CustomerCity]
,[CustomerCountry]
--, [StartDate], [EndDate], [IsCurrent]
From [DWNorthwindLite].[dbo].[DimCustomers]
go

Create or Alter View vDimProductsForTabularModel
As
Select
 [ProductKey]
,[ProductID]
,[ProductName]
,[ProductCategoryID]
,[ProductCategoryName]
--, [StartDate], [EndDate], [IsCurrent]
from [DWNorthwindLite].[dbo].[DimProducts]
go

Create or Alter View vDimDatesForTabularModel
As
Select  
-- NOTE: Since SSAS Tabluar Model cannot automatically convert the ISO/ANSI integer format for dates 
-- to a Date datatype we must convert it ourselves.
 [DateKey] = Cast(Cast(IIF([DateKey] > 0, [DateKey], '1900010' + str(abs([DateKey]),1)) as char(8)) as date)
,[WeekdayAndDate] = [USADateName]
,[Month] = [MonthName]
,[Quarter] = [QuarterName]
,[Year] = [YearName]
--,[Test] = '1900010' + str(abs([DateKey]),1) --< This will convert -1 and -2 to 19000101 and 19000102
-- Without it, SSAS will try to convert both to the same date and it will violate being unique dates!
From [DWNorthwindLite].[dbo].[DimDates]
go

Create or Alter View vFactOrdersForTabularModel
As
Select 
 [OrderID]
,[CustomerKey]
,[OrderDateKey] =  Cast(Cast(IIF([OrderDateKey] > 0, [OrderDateKey], 19000101) as char(8)) as date)
,[ProductKey]
,[ActualOrderUnitPrice]
,[ActualOrderQuantity]
,[DerivedExtendedOrderPrice] = [ActualOrderUnitPrice] * [ActualOrderQuantity] --< New Column
From [DWNorthwindLite].[dbo].[FactOrders]
go


--********************************************************************--
-- Review the results of this script
--********************************************************************--
Select * from vDimCustomersForTabularModel;
Select * from vDimProductsForTabularModel;
Select * from vDimDatesForTabularModel;
Select * from vFactOrdersForTabularModel;
