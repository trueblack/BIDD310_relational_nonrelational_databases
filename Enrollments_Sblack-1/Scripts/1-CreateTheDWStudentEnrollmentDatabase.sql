--**************************************************************************--
-- Title: Create the DWStudentEnrollments database
-- Desc: This file will drop and create the DWStudentEnrollments database. 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created starter code
-- 2025-12-01,SBlack,Modified DW Creation code
--**************************************************************************--
Set NoCount On;

USE [master]
If Exists (Select Name from SysDatabases Where Name = 'DWStudentEnrollments')
  Begin
   ALTER DATABASE DWStudentEnrollments SET SINGLE_USER WITH ROLLBACK IMMEDIATE
   DROP DATABASE DWStudentEnrollments
  End
Go
Create Database DWStudentEnrollments;
Go
USE DWStudentEnrollments;


--********************************************************************--
-- Create the Tables
--********************************************************************--

Create Table DimClasses -- Created for Class Support
([ClassKey] int IDENTITY(1,1) Constraint pkDimClasses Primary Key
,[ClassId] int NOT NULL
,[ClassName] varchar(100) NOT NULL
,[CurrentClassPrice] decimal(7,2) NOT NULL
,[MaxCourseEnrollment] int NOT NULL
,[ClassroomId] int NOT NULL
,[ClassroomName] varchar(100) NOT NULL
,[MaxClassroomSize] int NOT NULL
,[DepartmentId] int NOT NULL
,[DepartmentName] varchar(100) NOT NULL
);
go

Create Table DimStudents --Created for Student Support
([StudentKey] int IDENTITY(1,1) Constraint pkDimStudents Primary Key
,[StudentId] int NOT NULL
,[StudentName] varchar(100) NOT NULL
,[StudentEmail] varchar(100) NOT NULL
);
go

Create Table DimDates -- Created for Date Support
([DateKey] int Constraint pkDimDates Primary Key
,[FullDate] date NOT NULL
,[USADateName] varchar(100) NOT NULL
,[MonthKey] int NOT NULL
,[MonthName] varchar(100) NOT NULL
,[QuarterKey] int NOT NULL
,[QuarterName] varchar(100) NOT NULL
,[YearKey] int NOT NULL
,[YearName] varchar(100) NOT NULL
);
go

Create Table FactEnrollments --Relationship Fact Table
([EnrollmentId] int NOT NULL
,[EnrollmentDate] date NOT NULL
,[StudentKey] int NOT NULL
,[ClassKey] int NOT NULL
,[DateKey] int NOT NULL  
,[EnrollmentPrice] decimal(7,2) NOT NULL
);
go

--********************************************************************--
-- Create the FOREIGN KEY CONSTRAINTS
--********************************************************************--

Alter Table FactEnrollments 
  Add Constraint FK_FactEnrollments_DimClasses
    Foreign Key([ClassKey]) References DimClasses([ClassKey]);
go

Alter Table FactEnrollments 
  Add Constraint FK_FactEnrollments_DimStudents
    Foreign Key([StudentKey]) References DimStudents([StudentKey]);
go

Alter Table FactEnrollments 
     Add Constraint FK_FactEnrollments_DimDates
       Foreign Key([DateKey]) References DimDates([DateKey]);
go


--********************************************************************--
-- Create the Abstraction Layers
--********************************************************************--

-- Base Views

Create View vStudentEnrollments AS
    SELECT 
        s.StudentName,
        s.StudentEmail,
        c.ClassName,
        c.ClassroomName,
        c.DepartmentName,
        f.EnrollmentDate,
        f.EnrollmentPrice
    FROM FactEnrollments f
    INNER JOIN DimStudents s ON f.StudentKey = s.StudentKey
    INNER JOIN DimClasses c ON f.ClassKey = c.ClassKey
    INNER JOIN DimDates dt ON f.DateKey = dt.DateKey;

-- Metadata View
Go
Create or Alter View vMetaDataStudentEnrollments
As
Select Top 100 Percent
 [Source Table] = DB_Name() + '.' + SCHEMA_NAME(tab.[schema_id]) + '.' + object_name(tab.[object_id])
,[Source Column] =  col.[Name]
,[Source Type] = Case 
				When t.[Name] in ('char', 'nchar', 'varchar', 'nvarchar' ) 
				  Then t.[Name] + ' (' +  format(col.max_length, '####') + ')'                
				When t.[Name]  in ('decimal', 'money') 
				  Then t.[Name] + ' (' +  format(col.[precision], '#') + ',' + format(col.scale, '#') + ')'
				 Else t.[Name] 
                End 
,[Source Nullability] = iif(col.is_nullable = 1, 'Null', 'Not Null') 
From Sys.Types as t 
Join Sys.Columns as col 
 On t.system_type_id = col.system_type_id 
Join Sys.Tables tab
  On tab.[object_id] = col.[object_id]
And t.name <> 'sysname'
Order By [Source Table], col.column_id; 
go
Select * From vMetaDataStudentEnrollments;
