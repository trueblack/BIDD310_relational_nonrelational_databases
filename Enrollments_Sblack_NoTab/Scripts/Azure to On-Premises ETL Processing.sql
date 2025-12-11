--**************************************************************************--
-- Title: Azure to On-Premises ETL Processing
-- Desc: This file performs ETL processing from an Azure database to an on-premises database. 
-- Change Log: When,Who,What
-- 2025-11-26,RRoot,Created emo code
--**************************************************************************--

/*************************************************************************** 
NOTES: 
* In this demo we will look at two ways you can get source data from an 
  Azure database to an on-premises database: OPENROWSET() and Linked Servers.

* We will also illustrate two methods to perform the ETL processing:

  1. EXTRACT the data from Azure and LOAD it into staging tables, 
     then TRANSFORM the data before loading into the destination tables 
     using Transformation Views.

  2. Create Transformation Views to EXTRACT 
     and TRANSFORM the data before loading into the destination tables.

* We will use both methods in this demo to illustrate the options you have 
  when working with an Azure database with the following table:

  dbo.Students (Id, FirstName, LastName, Email)

* This code is intended for demo and learning purposes only. 
  Do not use in production environments without proper review and testing. 

SECURITY NOTE: Never store real passwords in plain text scripts.
- In production, use secure methods (Azure AD, secrets vaults,
  or credentials stored in SQL Server, not in code).

***************************************************************************/

-- ======================================================================= --
-- PART A. Setup Code
-- ======================================================================= --

-- First create a database named StudentEnrollments on AZURE cloud.
-- Then connect to the Azure database and run the following code to create
-- a source table and load sample data into it: 

-- IMPORTANT: You must connect to your Azure SQL Database instance and run:
-- Create Table dbo.Students 
--   ( Id int Not Null Identity Constraint pkStudents Primary Key
--   , FirstName nvarchar(40) Not Null
--   , LastName nvarchar(50) Not Null
--   , Email nvarchar(100) Not Null
-- );
-- Go
--
-- Insert Into dbo.Students 
-- (FirstName, LastName, Email) 
-- Values 
-- ('Bob', 'Smith', 'BSmith@gomail.com'),
-- ('Sue', 'Jones', 'SJones@gomail.com');
-- Go

-- Now run the following code on your LOCAL SQL Server instance to create a demo destination table: 
Use tempdb;
Go

If Object_Id('dbo.DimStudents') Is Not Null
  Drop Table dbo.DimStudents;
Go

-- Create the destination dimension table:
Create Table dbo.DimStudents 
( 
  StudentKey int Not Null Constraint pkDimStudents Primary Key Identity(1,1), -- AutoNumber
  StudentId int Not Null,
  StudentName nvarchar(100) Not Null,
  StudentEmail nvarchar(100) Not Null
);
Go

-- ======================================================================= --
-- PART B. Using OPENROWSET() with Staging Tables, ETL Views and Stored Procedures
-- ======================================================================= --

-- Run this on LOCAL SQL Server to enable Ad Hoc Distributed Queries using OPENROWSET()
sp_configure; -- See the current settings
Go

sp_configure 'show advanced option', 1; -- Show advanced settings
Reconfigure; -- Force the change
Go

sp_configure; -- Now you can see and access the advanced settings 
Go

sp_configure 'Ad Hoc Distributed Queries', 1; -- Turn ON Ad Hoc queries
Reconfigure; -- Force the change
Go

-- Before we continue, let's verify that OPENROWSET can extract data from Azure SQL Database
Select s.*  -- Select all columns
From OPENROWSET('MSOLEDBSQL',
'Server=bidd-23-25-s-black.database.windows.net;uid=biddadmin;pwd=P@$$w0rd;database=StudentEnrollments;', 
'Select * From dbo.Students') As s;  -- This is an alias for the source table
Go

-- Now, let's load the data into a staging table on-premises for further processing

-- Drop Staging Table if it exists
If OBJECT_ID('dbo.StagingStudents') IS NOT NULL
  Drop Table dbo.StagingStudents; 
Go

-- Create Staging Table
Create Table dbo.StagingStudents
(
  Id int Not Null,
  FirstName nvarchar(40) Not Null,
  LastName nvarchar(50) Not Null,
  Email nvarchar(100) Not Null
);
Go

-- Load data from Azure Database into the Staging Table using OPENROWSET()
Insert Into dbo.StagingStudents (Id, FirstName, LastName, Email) 
Select s.Id, s.FirstName, s.LastName, s.Email
From OPENROWSET('MSOLEDBSQL',
'Server=bidd-23-25-s-black.database.windows.net;uid=biddadmin;pwd=P@$$w0rd;database=StudentEnrollments;', 
'Select Id, FirstName, LastName, Email From dbo.Students') As s;
Go

-- Verify the data was loaded into the staging table
Select * From dbo.StagingStudents;
Go

-- Create a Transformation View to handle the transformation logic
Create or Alter View dbo.vETLDimStudents
As    
  Select 
    StudentId   = Id,                       -- Direct mapping
    StudentName = FirstName + ' ' + LastName, -- Transformation
    StudentEmail= Email                     -- Direct mapping
  From dbo.StagingStudents;
Go

-- Create a stored procedure to load the data into the destination table
Create or Alter Procedure dbo.pETLDimStudents
As
Begin
  Set Nocount On;

  Insert Into dbo.DimStudents (StudentId, StudentName, StudentEmail)
  Select StudentId, StudentName, StudentEmail
  From dbo.vETLDimStudents;
End
Go

-- Verify the data will be loaded into the destination table using the OPENROWSET + staging pattern
Truncate Table dbo.DimStudents; -- Clear existing data
Go

Exec dbo.pETLDimStudents; -- Load data using OPENROWSET + staging method
Go

Select * From dbo.DimStudents; -- Verify the data was loaded
Go

-- ======================================================================= --
-- PART C. Using Linked Server with Staging Tables, ETL Views, and Stored Procedures
-- ======================================================================= --

-- Reset the linked server if it already exists
If Exists (Select * From sys.servers Where name = N'AzureLinkedServerName')
Begin
  Exec master.dbo.sp_dropserver 
    @server = N'AzureLinkedServerName', 
    @droplogins = 'droplogins';
End
Go

-- Create a Linked Server to the Azure SQL Database
Exec master.dbo.sp_addlinkedserver 
    @server   = N'AzureLinkedServerName',  -- A name you choose for the linked server
    @srvproduct = N'',
    @provider = N'MSOLEDBSQL',             -- Use the modern OLE DB driver
    @datasrc  = N'25-26-final.database.windows.net', -- Your Azure server name
    @catalog  = N'StudentEnrollments';     -- The specific database name
Go

-- Configure credentials for the linked server
Exec master.dbo.sp_addlinkedsrvlogin 
    @rmtsrvname = N'AzureLinkedServerName', 
    @useself    = N'FALSE', 
    @rmtuser    = N'BIDDAdmin',   -- Your Azure SQL login name (Change this to your login)
    @rmtpassword= N'P@$$w0rd';    -- Your Azure SQL password (Change this to your password)
Go

-- Let's verify that we can read data from the Azure database using the linked server
Select * From AzureLinkedServerName.StudentEnrollments.dbo.Students; -- Verify current data

-- Now, let's load the data into our on-premises staging table from the Azure linked server.
-- Note: This code does the same logical thing as the OPENROWSET() method but uses the linked server instead.

-- Clear the staging table's data
Truncate Table dbo.StagingStudents;
Go

-- Load Data from Azure Database into the Staging Table using Linked Server
Insert Into dbo.StagingStudents (Id, FirstName, LastName, Email)
Select Id, FirstName, LastName, Email
From AzureLinkedServerName.StudentEnrollments.dbo.Students;
Go

-- Verify the data was loaded into the staging table
Select * From dbo.StagingStudents;
Go

-- We can now use our existing transformation view and stored procedure to load the dimension
Truncate Table dbo.DimStudents; -- Clear existing data
Go

Exec dbo.pETLDimStudents;  -- Still reading from dbo.vETLDimStudents (which points at StagingStudents)
Go

Select * From dbo.DimStudents; -- Verify the data was loaded
Go

-- ======================================================================= --
-- PART D. Using a Linked Server, ETL Views, and Stored Procedures Without Staging Tables
-- ======================================================================= --

-- NOTES: 
-- * A staging table is not strictly needed when using the linked server.
-- * Instead, you can create transformation views that read directly from the linked server.
-- * This method will not work with the OPENROWSET() function since you cannot use OPENROWSET() in a view.

-- Drop Staging Table if it exists and we no longer need it
If OBJECT_ID('dbo.StagingStudents', 'U') IS NOT NULL
  Drop Table dbo.StagingStudents;
Go

-- Now, let's change the existing view to use the linked server directly (no staging)
Create or Alter View dbo.vETLDimStudents
As
  Select
    StudentId   = s.Id,
    StudentName = s.FirstName + ' ' + s.LastName,
    StudentEmail= s.Email
  From AzureLinkedServerName.StudentEnrollments.dbo.Students As s;
Go

-- Verify the data will still be loaded into the destination table,
-- but this time without using a staging table
Truncate Table dbo.DimStudents; -- Clear existing data
Go

Exec dbo.pETLDimStudents; -- Load data using linked server without staging
Go

Select * From dbo.DimStudents; -- Verify the data was loaded
Go

-- ======================================================================= --
-- PART E. Cleanup Objects as Needed
-- ======================================================================= --

-- Drop staging table and view if no longer needed
If OBJECT_ID('dbo.StagingStudents', 'U') IS NOT NULL
  Drop Table dbo.StagingStudents; 
Go  

If OBJECT_ID('dbo.vETLDimStudents') IS NOT NULL
  Drop View dbo.vETLDimStudents;  
Go

-- Drop stored procedure if no longer needed
If OBJECT_ID('dbo.pETLDimStudents') IS NOT NULL
  Drop Procedure dbo.pETLDimStudents;
Go  

-- Now that we are done with the Ad Hoc queries, we can disable it for security.
-- It's a good practice to turn it off when not in use.
sp_configure 'Ad Hoc Distributed Queries', 0; -- Turn OFF Ad Hoc queries
Reconfigure; -- Force the change
Go

-- We can also clean up the linked server if no longer needed
Exec master.dbo.sp_dropserver 
    @server = N'AzureLinkedServerName', 
    @droplogins = 'droplogins';
Go

-- ======================================================================= --
-- End of Demo
-- ======================================================================= --

-- NOTES: 
-- * Not using a staging table will not work with the OPENROWSET() function since you cannot use OPENROWSET() in your ETL view.
-- * Using a staging table does add an extra step to the ETL process, but it can provide more control over the data 
--   and allow for data validation before loading into the destination tables.
-- * Both methods illustrated in this demo can be used to perform ETL processing
--   from an Azure SQL Database to an on-premises SQL Server database.
-- * On the job, the choice of method depends on your specific requirements, security considerations,
--   and performance needs. For our course, you can choose either method based on what makes the most sense to you.
-- * Using linked servers simplifies the process by eliminating the need for staging tables
--   but may have performance implications depending on the volume of data and network latency. 
-- * Always consider security best practices when connecting to cloud databases,
--   including using secure authentication methods and protecting sensitive information.