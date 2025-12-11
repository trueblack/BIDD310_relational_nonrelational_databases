--*************************************************************************--
-- Title: Module03 SIMPLISTIC ETL Process
-- Desc: Creates ETL objects and loads the DW database with test data for module 03. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
--*************************************************************************--

print 'Important:
This file should run and fill up the data warehouse without errors. 
If you get error messages, then your data warehouse is off and needs to be adjusted. 
Make those adjustments and try again.'

Use DWEmployeeProjects;
go

Set NoCount On;
go

--1)  Clear the data from all DW tables. 
--*************************************************************************--

Alter table FactProjectsCategories Drop Constraint FK_FactProjectsCategories_DimCategories;
Alter table FactProjectsCategories Drop Constraint FK_FactProjectsCategories_DimProjects;
Alter Table FactEmployeeProjectHours Drop Constraint FK_FactEmployeeProjectHours_DimEmployees;
Alter Table FactEmployeeProjectHours Drop Constraint FK_FactEmployeeProjectHours_DimProjects;
Alter Table FactEmployeeProjectHours Drop Constraint FK_FactEmployeeProjectHours_DimDates;
go

Truncate Table FactEmployeeProjectHours;
Truncate Table FactProjectsCategories;
Truncate Table DimDates;	   
Truncate Table DimEmployees;	  
Truncate Table DimProjects;
Truncate Table DimCategories;
go

-- 2) FILL the Tables
--********************************************************************--

/****** [dbo].[DimDates] ******/
-- Create variables to hold the start and end date
Declare @StartDate datetime = '01/01/2020';
Declare @EndDate datetime = '12/31/2020'; 
Declare @DateInProcess datetime;
Declare @TotalRows int = 0;

-- Use a while loop to add dates to the table
Set @DateInProcess = @StartDate;

While @DateInProcess <= @EndDate
	Begin
	  -- Add a row into the date dimensiOn table for this date
	  Begin Tran;
	    Insert Into DimDates 
	    ( [DateKey], [FullDate], [USADateName], [MonthKey], [MonthName], [QuarterKey], [QuarterName], [YearKey], [YearName] )
	    Values ( 
	   	  Cast(Convert(nvarchar(50), @DateInProcess , 112) as int) -- [DateKey]
	    ,@DateInProcess -- [FullDate]
	    ,DateName( weekday, @DateInProcess ) + ', ' + Convert(nvarchar(50), @DateInProcess , 110) -- [USADateName]  
	    ,Left(Cast(Convert(nvarchar(50), @DateInProcess , 112) as int), 6) -- [MonthKey]   
	    ,DateName( MONTH, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [MonthName]
	    , Cast(Cast(YEAR(@DateInProcess) as nvarchar(50))  + '0' + DateName( QUARTER,  @DateInProcess) as int) -- [QuarterKey]
	    ,'Q' + DateName( QUARTER, @DateInProcess ) + ', ' + Cast( Year(@DateInProcess) as nVarchar(50) ) -- [QuarterName] 
	    ,Year( @DateInProcess ) -- [YearKey]
	    ,Cast( Year(@DateInProcess ) as nVarchar(50) ) -- [YearName] 
	    ); 
	    -- Add a day and loop again
	    Set @DateInProcess = DateAdd(d, 1, @DateInProcess);
	  Commit Tran;
  Set @TotalRows += 1;
End -- While 
-- Select * From DimDates

/****** [dbo].[DimEmployees] ******/
Insert Into DimEmployees
(EmployeeID, EmployeeName)
Select
 [EmployeeID] = ID
,[EmployeeName] = Cast((FName +  ' ' + LName) as varchar(100))
From EmployeeProjects.dbo.Employees;
Go

/****** [dbo].[DimCategories] ******/
Insert Into DimCategories(CategoryID, CategoryName)
Select 
[CategoryID] = ID
,[CategoryName] = Cast([Name] as varchar(100))
From DWEmployeeProjects.dbo.DimCategories;
Go

/****** [dbo].[DimProjects] ******/
Insert Into DimProjects	(ProjectID, ProjectName)
Select 
	 [ProjectID] = ID
  ,[ProjectName] = Cast([Name] as varchar(100))
From  EmployeeProjects.dbo.Projects;
Go

/****** [dbo].[FactProjectsCategories] ******/
Insert Into FactProjectsCategories(CategoryKey, ProjectKey)
Select 
   [CategoryKey] -- surrogate key
  ,[ProjectKey]  -- surrogate key (Note the key values are in the 10s)
From DWEmployeeProjects.dbo.ProjectsCategories as pc
Join DimCategories as dc
  On pc.CategoryID = dc.CategoryID -- Join to lookup surrogate key
Join DimProjects as dp
  On pc.ProjectID = dp.ProjectID; -- Join to lookup surrogate key
Go

/****** [dbo].[FactEmployeeProjectHours] ******/
Insert Into FactEmployeeProjectHours(EmployeeProjectHoursID, EmployeeKey, ProjectKey, DateKey, HoursWorked)
Select 
  [EmployeeProjectHoursID] = EmployeeProjectHoursID
  ,EmployeeKey =  de.EmployeeKey
  ,ProjectKey = dp.ProjectKey
  ,DateKey =  dd.DateKey
  ,HoursWorked = Hrs
From EmployeeProjects.dbo.EmployeeProjectHours as eph
Join DimDates as dd
  On Cast(Convert(nvarchar(50), eph.[Date], 112) as int) = dd.DateKey
Join DimEmployees as de
  On eph.EmployeeID = de.EmployeeID
Join DimProjects as dp
  On eph.ProjectID = dp.ProjectID
Go

-- 3) Re-Create the Foreign Key CONSTRAINTS
--********************************************************************--
Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimEmployees
    Foreign Key([EmployeeKey]) References DimEmployees([EmployeeKey]);

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimProjects
    Foreign Key([ProjectKey]) References DimProjects([ProjectKey]);

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimDates
    Foreign Key([DateKey]) References DimDates([DateKey]);

Alter table FactProjectsCategories 
  Add Constraint FK_FactProjectsCategories_DimCategories
  Foreign Key(CategoryKey) References DimCategories(CategoryKey);

Alter table FactProjectsCategories
  Add Constraint FK_FactProjectsCategories_DimProjects
  Foreign Key(ProjectKey) References DimProjects(ProjectKey);
Go

-- Review the results of this script
--********************************************************************--
Select * From [DimDates];
Select * From [dbo].[DimEmployees];
Select * From [dbo].[DimCategories];
Select * From [dbo].[DimProjects];
Select * From FactProjectsCategories
Select * From [FactEmployeeProjectHours];
Go