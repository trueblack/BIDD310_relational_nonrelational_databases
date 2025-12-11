--*************************************************************************--
-- Title: DWStudentEnrollments ETL Process
-- Desc:This file will drop and create an ETL process for DWStudentEnrollments. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- Todo: 2025-12-01,SBlack,Completed File
--*************************************************************************--

Use DWStudentEnrollments;
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
	  
	  Alter Table dbo.FactEnrollments Drop Constraint [FK_FactEnrollments_DimClasses];
	  Alter Table dbo.FactEnrollments Drop Constraint [FK_FactEnrollments_DimStudents];
	  Alter Table dbo.FactEnrollments Drop Constraint [FK_FactEnrollments_DimDates];
	  -- Alter Table [DWStudentEnrollments].dbo.FactEnrollments Drop Constraint [FK_FactEnrollments_DimDates];
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
	  -- Todo: Clear FactEnrollments;
	  Truncate Table [DWStudentEnrollments].[dbo].[FactEnrollments];
	  -- Todo: Clear DimDates;
	  Truncate Table [DWStudentEnrollments].[dbo].[DimDates];
	  -- Todo: Clear DimStudents;
	  Truncate Table [DWStudentEnrollments].[dbo].[DimStudents];
	  -- Todo: Clear DimClasses;
	  Truncate Table [DWStudentEnrollments].[dbo].[DimClasses];
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
-- Desc:This Sproc fills the DimStudents table. 
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
	  Declare @StartDate datetime = '01/01/2019';
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

/****** [dbo].[DimStudents] ******/
Go
Create Or Alter View vETLDimStudents
As
	Select
	  [StudentId] = Id
     ,[StudentName] = Cast((FirstName +  ' ' + LastName) as varchar(100))
	 ,[StudentEmail] = Email
	From StudentEnrollments.dbo.Students;
Go

Create Or Alter Proc pETLDimStudents
--*************************************************************************--
-- Desc:This Sproc fills the DimStudents table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-10-24,SBlack,Completed code to fill the DimStudents table. 
--*************************************************************************--
As 
Begin 
	Declare @RC int = 0;
	Declare @Message varchar(1000) 
  Begin Try
	  Begin Tran;
	    -- Todo: Add Insert-Select Code 
		Insert Into DimStudents
		( [StudentId], [StudentName], [StudentEmail] )
		 Select 
		   StudentId
		  ,StudentName
		  ,[StudentEmail]
		 From vETLDimStudents;
	    Set @Message = 'Filled DimStudents (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;
	  Exec pETLInsETLLog
 	       @ETLAction = 'pETLDimStudents'
 	      ,@ETLLogMessage = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
    Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsETLLog 
         @ETLAction = 'pETLDimStudents'
        ,@ETLLogMessage = @ErrorMessage;
    Set @RC = -1;
  End Catch
  Return @RC;
End
Go
 Exec pETLDimstudents; Select * From DimStudents; Select * From ETLLog;

/****** [dbo].[DimClasses] ******/
Go
Create Or Alter View vETLDimClasses
As
	-- Todo: Complete Select Code 
	Select 
	  [ClassId] = c.Id
	 ,[ClassName] = Cast(c.Name as varchar(100))
	 ,[CurrentClassPrice] = c.Price 
	 ,[MaxCourseEnrollment] = c.MaxSize
	 ,[ClassroomId] = c.ClassroomId
	 ,[ClassroomName] = Cast(cr.Name as varchar(100))
	 ,[MaxClassroomSize] = cr.MaxSize
	 ,[DepartmentId] = c.DepartmentId
	 ,[DepartmentName] = Cast(d.Name as varchar(100))
	From StudentEnrollments.dbo.Classes as c
	Inner Join [StudentEnrollments].[dbo].[Classrooms] as cr
		On [c].[ClassroomId] = [cr].[Id]
	Inner Join [StudentEnrollments].[dbo].[Departments] as d
		On [c].[DepartmentId] = [d].[Id]
Go

Create Or Alter Proc pETLDimClasses
--*************************************************************************--
-- Desc:This Sproc fills the DimClasses table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-12-01,SBlack,Completed code to fill the DimClasses table. 
--*************************************************************************--
As 
Begin
	Declare @RC int = 0;
	Declare @Message varchar(1000) 
  Begin Try
	  Begin Tran;
      -- Todo: Add Insert-Select Code
	  	Insert Into DimClasses
		  ( [ClassId], [ClassName],[CurrentClassPrice]
		  ,[MaxCourseEnrollment],[ClassroomId],[ClassroomName]
		  ,[MaxClassroomSize],[DepartmentId],[DepartmentName])
		 Select
		   ClassId
		  ,ClassName
		  ,CurrentClassPrice
		  ,MaxCourseEnrollment
		  ,ClassroomId
		  ,ClassroomName
		  ,MaxClassroomSize
		  ,DepartmentId
		  ,DepartmentName
		 From vETLDimClasses;
	    Set @Message = 'Filled DimClasses (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;

      -- Todo: Add Logging Code
	   Exec pETLInsETLLog
 	       @ETLAction = 'pETLDimClasses'
 	      ,@ETLLogMessage = @Message;
    Set @RC = 1;
  End Try
  Begin Catch
    If @@TRANCOUNT > 0 Rollback;
      -- Todo: Add Logging Code
	Declare @ErrorMessage nvarchar(1000) = Error_Message();
    Exec pETLInsETLLog 
         @ETLAction = 'pETLDimClasses'
        ,@ETLLogMessage = @ErrorMessage;
   Set @RC = -1;
  End Catch
  Return @RC;
End
Go
 Exec pETLDimClasses; Select * From DimClasses; Select * From ETLLog;


/****** [dbo].[FactEnrollments] ******/
Go
Create Or Alter View vETLFactEnrollments
As
  -- Todo: Complete Select Code (Don't forget to return the Surrogate Keys!)
	Select 
	   [EnrollmentId] = e.Id
	  ,[EnrollmentDate] = e.Date
	  ,[DateKey] =  dd.DateKey
	  ,[StudentKey] = ds.StudentKey
	  ,[ClassKey] =  dc.ClassKey
	  ,[EnrollmentPrice] = e.Price
	From StudentEnrollments.dbo.Enrollments as e
	Inner Join [DWStudentEnrollments].[dbo].[DimClasses] as dc
		On [e].[ClassId] = [dc].[ClassId]
	Inner Join [DWStudentEnrollments].[dbo].[DimStudents] as ds
		On [e].[StudentId] = [ds].[StudentId]
	Inner Join [DWStudentEnrollments].[dbo].[DimDates] as dd
		On Cast(e.Date as Date) = dd.FullDate
	
Go

Create Or Alter Proc pETLFactEnrollments
--*************************************************************************--
-- Desc:This Sproc fills the FactEnrollments table. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created Sproc
-- Todo: 2025-12-01,SBlack,Completed code to fill the FactEnrollments table. 
--*************************************************************************--
As 
Begin
  Declare @RC int = 1;
  Declare @Message varchar(1000);
  Begin Try
      -- Todo: Add Transaction, Insert-Select, and Logging code
	  Begin Tran;
      -- Todo: Add Insert-Select Code
	  	Insert Into FactEnrollments
		  ( [EnrollmentId], [EnrollmentDate], [DateKey], [StudentKey], [ClassKey], [EnrollmentPrice] )
		 Select
		   [EnrollmentId]
		   ,[EnrollmentDate]
		   ,[DateKey]
		   ,[StudentKey]
		   ,[ClassKey]
		   ,[EnrollmentPrice]
		 From vETLFactEnrollments;
	    Set @Message = 'Filled FactEnrollments (' + Cast(@@RowCount as varchar(100)) + ' rows)';
	  Commit Tran;
	  Exec pETLInsETLLog
		 @ETLAction = 'pETLFactEnrollments'
		,@ETLLogMessage = @Message;
    Set @RC = 1
  End Try
  Begin Catch
    -- Todo: Add Transaction and Logging code
		If @@TRANCOUNT > 0 Rollback;
      -- Todo: Add Logging Code
		Declare @ErrorMessage nvarchar(1000) = Error_Message();
		Exec pETLInsETLLog 
         @ETLAction = 'pETLFactEnrollments'
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
     Alter Table FactEnrollments 
  Add Constraint FK_FactEnrollments_DimStudents
    Foreign Key(StudentKey) References DimStudents(StudentKey);


Alter Table FactEnrollments 
  Add Constraint FK_FactEnrollments_DimClasses
    Foreign Key(ClassKey) References DimClasses(ClassKey);


Alter Table FactEnrollments 
  Add Constraint FK_FactEnrollments_DimDates
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
Exec pETLDimStudents;
Exec pETLDimClasses;
Exec pETLDimDates;
Exec pETLFactEnrollments;
Exec pETLReplaceFks;
Select * From [ETLLog];
Go
-- Check table data
Select * From [dbo].[DimStudents];
Select * From [dbo].[DimClasses];
Select * From [DimDates];
Select * From [FactEnrollments];
Go