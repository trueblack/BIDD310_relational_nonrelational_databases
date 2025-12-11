--*************************************************************************--
-- Title: DWEmployeeProjects ETL Process
-- Desc:This file will drop and create an ETL process for DWEmployeeProjects. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- Todo: 2025-10-24,SBlack,Completed File
--*************************************************************************--

Use DWEmployeeProjects;
go

--********************************************************************--
-- 0) Create ETL Logging objects
--********************************************************************--
If NOT Exists(Select * From Sys.tables where Name = 'ETLLog')
  Create Table ETLLog
  (ETLLogID int identity Primary Key
  ,ETLDateAndTime datetime Default GetDate()
  ,ETLAction varchar(100)
  ,ETLLogMessage varchar(2000)
  );
go
 --Truncate Table ETLLog; -- Used to clear table in demo

Create or Alter View vETLLog
As
 Select
  ETLLogID
 ,ETLDate = Format(ETLDateAndTime, 'D', 'en-us')
 ,ETLTime = Format(Cast(ETLDateAndTime as datetime2), 'HH:mm', 'en-us')
 ,ETLAction
 ,ETLLogMessage
 From ETLLog;
go

 --Select * FRom vETLLog;

Create or Alter Proc pETLInsETLLog
 (@ETLAction varchar(100), @ETLLogMessage varchar(2000))
--*************************************************************************--
-- Desc:This Sproc create a admin table for logging ETL metadata. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As
Begin
  Declare @RC int = 0;
  Begin Try
    Begin Tran;
      Insert Into ETLLog
       (ETLAction,ETLLogMessage)
      Values
       (@ETLAction,@ETLLogMessage);
	Commit Tran;
    Set @RC = 1; 
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
    Print Error_Message(); -- NOTE this is PRESENTATION CODE and will only be used for testing!
    Set @RC = -1;
  End Catch
  Return @RC;
End
go

--********************************************************************--
-- 1) Drop the Foreign Key CONSTRAINTS and Clear the tables
--********************************************************************--
Go
Create Or Alter Proc pETLDropFks
--*************************************************************************--
-- Desc:This Sproc drops the DW foreign keys. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-10-24,SBlack,Added code to drop more FKs
--*************************************************************************--
As 
Begin
  Declare @RC int = 0;
  Begin Try
	 Begin Tran;
	  
	  Alter Table dbo.FactEmployeeProjectHours Drop Constraint [FK_FactEmployeeProjectHours_DimEmployees];
	  Alter Table dbo.FactEmployeeProjectHours Drop Constraint [FK_FactEmployeeProjectHours_DimProjects];
	  Alter Table dbo.FactEmployeeProjectHours Drop Constraint [FK_FactEmployeeProjectHours_DimDates];
	  -- Alter Table [DWEmployeeProjects].dbo.FactEmployeeProjectHours Drop Constraint [FK_FactEmployeeProjectHours_DimDates];
	 Commit Tran;
	 Exec pETLInsETLLog
	        @ETLAction = 'pETLDropFks'
	       ,@ETLLogMessage = 'Dropped Foreign Keys';
     Set @RC = 1;
  End Try
  Begin Catch
	If @@TRANCOUNT > 0 Rollback;  
    Declare @ErrorMessage nvarchar(1000) = Error_Message()
	  Exec pETLInsETLLog 
	      @ETLAction = 'pETLDropFks'
	     ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

Go
Create Or Alter Proc pETLTruncateTables
--*************************************************************************--
-- Desc:This Sproc clears the data from all DW tables. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Completed code to clear all table data
--*************************************************************************--
As 
Begin
	Declare @RC int = 0;
  Begin Try
	Begin Tran;
	  -- Todo: Clear FactEmployeeProjectHours;
	  Truncate Table [DWEmployeeProjects].[dbo].[FactEmployeeProjectHours];
	  -- Todo: Clear DimDates;
	  Truncate Table [DWEmployeeProjects].[dbo].[DimDates];
	  -- Todo: Clear DimEmployees;
	  Truncate Table [DWEmployeeProjects].[dbo].[DimEmployees];
	  -- Todo: Clear DimProjects;
	  Truncate Table [DWEmployeeProjects].[dbo].[DimProjects];
	Commit Tran;
	Exec pETLInsETLLog
	        @ETLAction = 'pETLTruncateTables'
	       ,@ETLLogMessage = 'Truncated Tables';
    Set @RC = 1;
  End Try
  Begin Catch
	If @@TRANCOUNT > 0 Rollback;  
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
	Exec pETLInsETLLog 
	        @ETLAction = 'pETLTruncateTables'
	       ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

--********************************************************************--
-- 2) FILL the Tables
--********************************************************************--

/****** [dbo].[DimDates] ******/
Go
Create or Alter Proc pETLDimDates
--*************************************************************************--
-- Desc:This Sproc fills the DimEmployees table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
--*************************************************************************--
As 
Begin
  Declare @RC int = 1;
  Declare @Message varchar(1000) 
  Set NoCount On; -- This will remove the 1 row affected msg in the While loop;
  Begin Try
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
    
	-- 2e) Add additional lookup values to DimDates
	 Begin Tran;
	 Insert Into DimDates 
	   ([DateKey]
	   ,[FullDate]
	   ,[USADateName]
	   ,[MonthKey]
	   ,[MonthName]
	   ,[QuarterKey]
	   ,[QuarterName]
	   ,[YearKey]
	   ,[YearName] )
	   Select 
		  [DateKey] = -1
	   ,[FullDate] = '19000101'
	   ,[DateName] = Cast('Unknown Day' as nVarchar(50) )
	   ,[MonthKey] = -1
	   ,[MonthName] = Cast('Unknown Month' as nVarchar(50) )
	   ,[QuarterKey] =  -1
	   ,[QuarterName] = Cast('Unknown Quarter' as nVarchar(50) )
	   ,[YearKey] = -1
	   ,[YearName] = Cast('Unknown Year' as nVarchar(50) )
	   Union
	   Select 
		  [DateKey] = -2
	   ,[FullDate] = '19000102'
	   ,[DateName] = Cast('Corrupt Day' as nVarchar(50) )
	   ,[MonthKey] = -2
	   ,[MonthName] = Cast('Corrupt Month' as nVarchar(50) )
	   ,[QuarterKey] =  -2
	   ,[QuarterName] = Cast('Corrupt Quarter' as nVarchar(50) )
	   ,[YearKey] = -2
	   ,[YearName] = Cast('Corrupt Year' as nVarchar(50) );
	  Commit Tran;
    Set @TotalRows += 2;

	  Set @Message = 'Filled DimDates (' + Cast(@TotalRows as varchar(100)) + ' rows)';
	  Exec pETLInsETLLog
	        @ETLAction = 'pETLDimDates'
	       ,@ETLLogMessage = @Message;
  End Try
  Begin Catch
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
	  Exec pETLInsETLLog 
	        @ETLAction = 'pETLDimDates'
	       ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Set NoCount Off;
  Return @RC;
End
Go
 --Select * From DimDates

/****** [dbo].[DimEmployees] ******/
Go
Create Or Alter View vETLDimEmployees
As
	Select
	  [EmployeeID] = ID
     ,[EmployeeName] = Cast((FName +  ' ' + LName) as varchar(100))
	From EmployeeProjects.dbo.Employees;
Go

Create Or Alter Proc pETLDimEmployees
--*************************************************************************--
-- Desc:This Sproc fills the DimEmployees table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-10-24,SBlack,Completed code to fill the DimEmployees table. 
--*************************************************************************--
As 
Begin 
	Declare @RC int = 0;
	Declare @Message varchar(1000) 
  Begin Try
	  Begin Tran;
	    -- Todo: Add Insert-Select Code 
		Insert Into DimEmployees
		( [EmployeeID], [EmployeeName] )
		 Select 
		   EmployeeID
		  ,EmployeeName
		 From vETLDimEmployees;
	    Set @Message = 'Filled DimEmployees (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;
	  Exec pETLInsETLLog
 	       @ETLAction = 'pETLDimEmployees'
 	      ,@ETLLogMessage = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsETLLog 
         @ETLAction = 'pETLDimEmployees'
        ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
 Exec pETLDimEmployees; Select * From DimEmployees; Select * From ETLLog;

/****** [dbo].[DimProjects] ******/
Go
Create Or Alter View vETLDimProjects
As
	-- Todo: Complete Select Code 
	Select 
	  [ProjectID] = ID
	 ,[ProjectName] = Cast(Name as varchar(100))
	From EmployeeProjects.dbo.Projects;
Go

Create Or Alter Proc pETLDimProjects
--*************************************************************************--
-- Desc:This Sproc fills the DimProjects table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-10-24,SBlack,Completed code to fill the DimProjects table. 
--*************************************************************************--
As 
Begin
	Declare @RC int = 0;
	Declare @Message varchar(1000) 
  Begin Try
	  Begin Tran;
      -- Todo: Add Insert-Select Code
	  	Insert Into DimProjects
		  ( [ProjectID], [ProjectName] )
		 Select
		   ProjectID
		  ,ProjectName
		 From vETLDimProjects;
	    Set @Message = 'Filled DimProjects (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;

      -- Todo: Add Logging Code
	   Exec pETLInsETLLog
 	       @ETLAction = 'pETLDimProjects'
 	      ,@ETLLogMessage = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
      -- Todo: Add Logging Code
	Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsETLLog 
         @ETLAction = 'pETLDimProjects'
        ,@ETLLogMessage = @ErrorMessage;
   Set @RC = -1;
  End Catch
  Return @RC;
End
Go
 Exec pETLDimProjects; Select * From DimProjects; Select * From ETLLog;


/****** [dbo].[FactOrders] ******/
Go
Create Or Alter View vETLFactEmployeeProjectHours
As
  -- Todo: Complete Select Code (Don't forget to return the Surrogate Keys!)
	Select 
	   [EmployeeProjectHoursID] = EmployeeProjectHoursID
	  ,[EmployeeKey] =  de.EmployeeKey
	  ,[ProjectKey] = dp.ProjectKey
	  ,[DateKey] =  dd.DateKey
	  ,[HoursWorked] = eph.Hrs
	From EmployeeProjects.dbo.EmployeeProjectHours as eph
	Inner Join [DWEmployeeProjects].[dbo].[DimProjects] as dp
		On [eph].[ProjectID] = [dp].[ProjectID]
	Inner Join [DWEmployeeProjects].[dbo].[DimEmployees] as de
		On [eph].[EmployeeID] = [de].[EmployeeID]
	Inner Join [DWEmployeeProjects].[dbo].[DimDates] as dd
		On Cast(eph.Date as date) = dd.FullDate
Go

Create Or Alter Proc pETLFactEmployeeProjectHours
--*************************************************************************--
-- Desc:This Sproc fills the FactEmployeeProjectHours table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-10-25,SBlack,Completed code to fill the FactEmployeeProjectHours table. 
--*************************************************************************--
As 
Begin
  Declare @RC int = 1;
  Declare @Message varchar(1000);
  Begin Try
      -- Todo: Add Transaction, Insert-Select, and Logging code
	  Begin Tran;
      -- Todo: Add Insert-Select Code
	  	Insert Into FactEmployeeProjectHours
		  ( [EmployeeProjectHoursID], [EmployeeKey], [ProjectKey], [DateKey], [HoursWorked] )
		 Select
		   [EmployeeProjectHoursID]
		   ,[EmployeeKey]
		   ,[ProjectKey]
		   ,[DateKey]
		   ,[HoursWorked]
		 From vETLFactEmployeeProjectHours;
	    Set @Message = 'Filled FactEmployeeProjectHours (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;
	  Exec pETLInsETLLog
		 @ETLAction = 'pETLFactEmployeeProjectHours'
		,@ETLLogMessage = @Message;
    Set @RC = 1
  End Try
  Begin Catch
    -- Todo: Add Transaction and Logging code
		If @@TRANCOUNT > 0 Rollback;
      -- Todo: Add Logging Code
		Declare @ErrorMessage nvarchar(1000) = Error_Message();
		Exec pETLInsETLLog 
         @ETLAction = 'pETLFactEmployeeProjectHours'
        ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go

--********************************************************************--
-- 3) Re-Create the Foreign Key Constraints
--********************************************************************--
Go
Create Or Alter Proc pETLReplaceFks
--*************************************************************************--
-- Desc:This Sproc replaces the DW foreign keys. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: <Date>,<Name>,Added code to replace more FKs
--*************************************************************************--
As 
Begin
  -- Todo: Add FK and Logging Code 

  Declare @RC int = 1;
  Begin Try
	Begin Tran;
     Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimEmployees
    Foreign Key(EmployeeKey) References DimEmployees(EmployeeKey);


Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimProjects
    Foreign Key(ProjectKey) References DimProjects(ProjectKey);


Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimDates
    Foreign Key(DateKey) References DimDates(DateKey);
	
	Commit Tran;
	Exec pETLInsETLLog
		 @ETLAction = 'pETLReplaceFks'
		,@ETLLogMessage = 'Replaced Foreign Keys';
	Set @RC = 1;
  End Try
  Begin Catch
  	If @@TRANCOUNT > 0 Rollback;
	Declare @ErrorMessage nvarchar(1000) = Error_Message();
		Exec pETLInsETLLog 
         @ETLAction = 'pETLReplaceFks'
        ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
--********************************************************************--
-- Review the results of this script
--********************************************************************--
Exec pETLDropFks;
Exec pETLTruncateTables;
Exec pETLDimEmployees;
Exec pETLDimProjects;
Exec pETLDimDates;
Exec pETLFactEmployeeProjectHours;
Exec pETLReplaceFks;
Select * From [ETLLog];
Go
-- Check table data
Select * From [dbo].[DimEmployees];
Select * From [dbo].[DimProjects];
Select * From [DimDates];
Select * From [FactEmployeeProjectHours];
Go