--********************************************************************************--
-- Title: Assignment01
-- Author: RRoot
-- Desc: This file demonstrates how to create a simple database with
--       tables and stored procedures
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File 
-- TODO: <Today's Date>,<YourNameHere>, Added code to create tables and stored procedures
--********************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment01DB_YourNameHere')
	 Begin 
	  Alter Database [Assignment01DB_YourNameHere] set Single_user With Rollback Immediate;
	  Drop Database Assignment01DB_YourNameHere;
	 End
	Create Database Assignment01DB_YourNameHere;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment01DB_YourNameHere;

/********************************************************************************
Overview: Create a normalized database with the following data. 

Course	Dates	Days	Start	End	Price	Student	Number	Email	Phone	Address	Signup Date	Paid
SQL1 - Winter	1/10/2030 to 1/24/2030 	T	6	8:50	399	Bob Smith	B-Smith-071	Bsmith@HipMail.com	(206)-111-2222	123 Main St. Seattle, WA., 98001	1/3/2030	399
SQL1 - Winter	1/10/2030 to 1/24/2030 	T	6	8:50	399	Sue Jones	S-Jones-003	SueJones@YaYou.com	(206)-231-4321	333 1st Ave. Seattle, WA., 98001	12/14/2029	349
SQL2 - Winter	1/31/2030 to 2/14/2030	T	6	8:50	399	Bob Smith	B-Smith-071	Bsmith@HipMail.com	(206)-111-2222	123 Main St. Seattle, WA., 98001	1/12/2030	399
SQL2 - Winter	1/31/2030 to 2/14/2030	T	6	8:50	399	Sue Jones	S-Jones-003	SueJones@YaYou.com	(206)-231-4321	333 1st Ave. Seattle, WA., 98001	12/14/2029	349


The database must include:
 1) Tables with foreign key constraints
 2) One insert transaction stored procedures per table
*******************************************************************************/

/** Create Tables ************************************************************/ 
Create Table Courses
 ([CourseID] int IDENTITY(1,1) NOT NULL
 ,[CourseName] nvarchar(100) NOT NULL
 ,[CourseStartDate] date NULL
 ,[CourseEndDate] date NULL
 ,[CourseStartTime] time NULL
 ,[CourseEndTime] time NULL
 ,[CourseDays] nvarchar(100) NULL
 ,[CourseCurrentPrice] money NULL
 );
go

Create Table Students
 ([StudentID] int IDENTITY(1,1) NOT NULL
 ,[StudentNumber] nvarchar(100) NOT NULL 
 ,[StudentFirstName] nvarchar(100) NOT NULL
 ,[StudentLastName] nvarchar(100) NOT NULL
 ,[StudentEmail] nvarchar(100) NOT NULL
 ,[StudentPhone] nvarchar(100) NOT NULL
 ,[StudentAddress1] nvarchar(100) NOT NULL
 ,[StudentAddress2] nvarchar(100) NULL
 ,[StudentCity] nvarchar(100) NOT NULL
 ,[StudentStateCode] nchar(2) NOT NULL
 ,[StudentZipCode] nvarchar(10) NOT NULL
 );
go

-- TODO: Create Table Enrollments
go

-- TODO: Create the Primary and Foreign Key Constraints -- 


/** Create the Insert Stored Procedures ************************************************************/ 

-- [Courses] --
Create or Alter Procedure pInsCourses
( @CourseName nVarchar(100) 
, @CourseStartDate date
, @CourseEndDate date 
, @CourseStartTime time
, @CourseEndTime time 
, @CourseDays nvarchar(100)
, @CourseCurrentPrice money
)
-- Author: RRoot
-- Desc: Processes Inserts for Course Data
-- Change Log: When,Who,What
-- 2030-01-01,RRoot,Created Sproc.
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
   -- Transaction Code --
    Insert Into Courses
	 (CourseName, CourseStartDate, CourseEndDate, CourseStartTime, CourseEndTime, CourseDays, CourseCurrentPrice)
     Values 
	 (@CourseName, @CourseStartDate, @CourseEndDate,@CourseStartTime, @CourseEndTime, @CourseDays, @CourseCurrentPrice);
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If @@Trancount > 0 Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- [Students] --
Create or Alter Procedure pInsStudents
( @StudentNumber nvarchar(100)
, @StudentFirstName nvarchar(100)
, @StudentLastName nvarchar(100)
, @StudentEmail nvarchar(100)
, @StudentPhone nvarchar(100)
, @StudentAddress1 nvarchar(100)
, @StudentAddress2 nvarchar(100)
, @StudentCity nvarchar(100)
, @StudentStateCode nchar(2)
, @StudentZipCode nchar(10)
)
-- Author: RRoot
-- Desc: Processes Inserts for Student Data
-- Change Log: When,Who,What
-- 2018-08-29,RRoot,Created Sproc.
AS
 Begin
  Declare @RC int = 0;
  Begin Try
   Begin Transaction 
   -- Transaction Code --
    Insert Into Students 
	( StudentNumber
	, StudentFirstName
	, StudentLastName
	, StudentEmail
	, StudentPhone
	, StudentAddress1
	, StudentAddress2
	, StudentCity
	, StudentStateCode
	, StudentZipCode)
     Values
	( @StudentNumber
	, @StudentFirstName
	, @StudentLastName
	, @StudentEmail
	, @StudentPhone
	, @StudentAddress1
	, @StudentAddress2
	, @StudentCity
	, @StudentStateCode
	, @StudentZipCode
	)
   Commit Transaction
   Set @RC = +1
  End Try
  Begin Catch
   If @@Trancount > 0 Rollback Transaction
   Print Error_Message()
   Set @RC = -1
  End Catch
  Return @RC;
 End
go

-- [Enrollments] --
-- TODO: Create Procedure pInsEnrollments



-- Add data using the insert stored procedures ************************************************************/  

-- [Courses] --
Declare @Status int -- Holds Return Code data
Exec @Status = pInsCourses
	 @CourseName = 'SQL1 - Winter' 
	,@CourseStartDate = '20300110'
	,@CourseEndDate = '20300124'
	,@CourseStartTime = '18:00:00'
	,@CourseEndTime = '20:50:00'
  ,@CourseDays = 'Th'
	,@CourseCurrentPrice = $399;
Select Case @Status
	When +1 Then 'Insert to Courses was successful!'
	When -1 Then 'Insert to Courses failed!' 
  End
go

Declare @Status int -- Holds Return Code data
Exec @Status = pInsCourses
	 @CourseName = 'SQL2 - Winter' 
	,@CourseStartDate = '20300131'
	,@CourseEndDate = '20300214'
	,@CourseStartTime = '18:00:00'
	,@CourseEndTime = '20:50:00'
  ,@CourseDays = 'Th'
	,@CourseCurrentPrice = $399;
Select Case @Status
	When +1 Then 'Insert to Courses was successful!'
	When -1 Then 'Insert to Courses failed!' 
  End
go
Select * From Courses;

-- [Students] --
Declare @Status int -- Holds Return Code data
Exec @Status = pInsStudents
     @StudentNumber = 'B-Smith-071'
    ,@StudentFirstName = 'Bob'
    ,@StudentLastName = 'Smith'
    ,@StudentEmail = 'BSmith@HipMail.com'
    ,@StudentPhone = '2061112222'
    ,@StudentAddress1 = '123 Main St.'
    ,@StudentAddress2 = Null
    ,@StudentCity = 'Seattle'
    ,@StudentStateCode = 'WA'
    ,@StudentZipCode = '98001'
Select Case @Status
	When +1 Then 'Insert to Students was successful!'
	When -1 Then 'Insert failed! Common Issues: Duplicate Data'
	End as [Status];
go

Declare @Status int -- Holds Return Code data
Exec @Status = pInsStudents
     @StudentNumber = 'S-Jones-003'
    ,@StudentFirstName = 'Sue'
    ,@StudentLastName = 'Jones'
    ,@StudentEmail = 'SJones@YaYou.com'
    ,@StudentPhone = '2062314321'
    ,@StudentAddress1 = '333 1st Ave.'
    ,@StudentAddress2 = Null
    ,@StudentCity = 'Seattle'
    ,@StudentStateCode = 'WA'
    ,@StudentZipCode = '98001'
Select Case @Status
	When +1 Then 'Insert to Students was successful!'
	When -1 Then 'Insert failed!'
	End as [Status];
go

Select * From Students;
go

-- [Enrollments] --
-- TODO: Use pInsEnrollments to add data

-- Select * From Enrollments;
go