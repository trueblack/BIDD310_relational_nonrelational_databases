--*************************************************************************--
-- Title: DWStudentEnrollments ETL Process
-- Desc:This scipt creates views that shape the data to 
-- work with the SSAS tabular model.
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- Todo: 2025-12-05,SBlack,Completed File
--*************************************************************************--

Use DWStudentEnrollments;
go


/****** [dbo].[vDimDatesForTabular] ******/
Go
Create or Alter View vDimDatesForTabular
As
Select
	    [DateKey] = Convert(char(10),[DateKey], 110)
	   ,[FullDate]
	   ,[USADateName]
	   ,[MonthKey]
	   ,[MonthName]
	   ,[QuarterKey]
	   ,[QuarterName]
	   ,[YearKey]
	   ,[YearName] 
   From [DWStudentEnrollments].[dbo].[DimDates]
Go

/****** [dbo].[vDimStudentsForTabular] ******/
Go
Create Or Alter View vDimStudentsForTabular
As
	Select
	  [StudentKey]
	 ,[StudentId] 
     ,[StudentName]
	 ,[StudentEmail]
	From [DWStudentEnrollments].[dbo].[DimStudents]
Go

/****** [dbo].[DimClassesForTabular] ******/
Go
Create Or Alter View vDimClassesForTabular
As
	-- Todo: Complete Select Code 
	Select 
	  [ClassKey]
	 ,[ClassId] 
	 ,[ClassName] 
	 ,[CurrentClassPrice] 
	 ,[MaxCourseEnrollment]
	 ,[ClassroomId] 
	 ,[ClassroomName] 
	 ,[MaxClassroomSize] 
	 ,[DepartmentId] 
	 ,[DepartmentName] 
	From [DWStudentEnrollments].[dbo].[DimClasses]
Go


/****** [dbo].[vFactEnrollmentsForTabular] ******/
Go
Create Or Alter View vFactEnrollmentsForTabular
As
  -- Todo: Complete Select Code (Don't forget to return the Surrogate Keys!)
	Select 
	   [EnrollmentId] 
	  ,[EnrollmentDate] = Convert(char(10), [EnrollmentDate], 110)
	  ,[DateKey] = Convert(char(10), [DateKey], 110)
	  ,[StudentKey] 
	  ,[ClassKey] 
	  ,[EnrollmentPrice] 
	From [DWStudentEnrollments].[dbo].[FactEnrollments]
Go

--********************************************************************--
-- Review the results of this script
--********************************************************************--

-- Check table data
Select * From [dbo].[vDimStudentsForTabular];
Select * From [dbo].[vDimClassesForTabular];
Select * From [dbo].[vDimDatesForTabular];
Select * From [dbo].[vFactEnrollmentsForTabular];
Go