--*************************************************************************--
-- Title: Module03 OLAP Destination Database
-- Desc:Drops and creates a DW database for module 03.
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- TODO: 2025-10-19, SBlack, Completed DW Creation Script
--*************************************************************************--
-- Create the database
Use Master;
go

If Exists(Select name from master.dbo.sysdatabases Where Name = 'DWEmployeeProjects')
Begin
	Use [master];
	Alter Database [DWEmployeeProjects] Set Single_User With Rollback Immediate;
	Drop Database [DWEmployeeProjects];
End;
go

Create Database DWEmployeeProjects; 
go

Use DWEmployeeProjects;
go

--********************************************************************--
-- Create the tables --
--********************************************************************--
-- Note: We have created the date dimension for you as an 
-- example of the expected code format. Try to be consistant!

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

-- TODO: Create Table DimCategories
Create Table DimCategories -- Created for Category Support
([CategoryKey] int IDENTITY(1,1) Constraint pkDimCategories Primary Key
,[CategoryID] int NOT NULL
,[CategoryName] varchar(100) NOT NULL
);
go

-- TODO: Create Table DimProjects
Create Table DimProjects
([ProjectKey] int IDENTITY(1,1) Constraint pkDimProjects Primary Key
,[ProjectID] int NOT NULL
,[ProjectName] varchar(100) NOT NULL
);
go

-- TODO: Create Table FactProjectsCategories -- Relationship fact table 
Create Table FactProjectsCategories
([ProjectKey] int NOT NULL
,[CategoryKey] int NOT NULL
);
go

-- TODO: Create Table DimEmployees
Create Table DimEmployees
([EmployeeKey] int IDENTITY(1,1) Constraint pkDimEmployees Primary Key
,[EmployeeID] int NOT NULL
,[EmployeeName] varchar(100) NOT NULL
);
go

-- TODO: Create Table FactEmployeeProjectHours -- Event Fact Table
Create Table FactEmployeeProjectHours
([EmployeeProjectHoursID] int NOT NULL
,[EmployeeKey] int NOT NULL
,[ProjectKey] int NOT NULL
,[DateKey] int NOT NULL
,[HoursWorked] decimal(4,2) NOT NULL
);
go

--********************************************************************--
-- Add the constraints --
--********************************************************************--
-- TODO: Uncomment this section once the tables are completed

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimEmployees
    Foreign Key([EmployeeKey]) References DimEmployees([EmployeeKey]);
go

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimProjects
    Foreign Key([ProjectKey]) References DimProjects([ProjectKey]);
go

Alter Table FactEmployeeProjectHours 
  Add Constraint FK_FactEmployeeProjectHours_DimDates
    Foreign Key([DateKey]) References DimDates([DateKey]);
go

Alter table FactProjectsCategories 
  Add Constraint FK_FactProjectsCategories_DimCategories
  Foreign Key(CategoryKey) References DimCategories(CategoryKey);
go

Alter table FactProjectsCategories
  Add Constraint FK_FactProjectsCategories_DimProjects
  Foreign Key(ProjectKey) References DimProjects(ProjectKey);
go



--[ Review the design ]--
--********************************************************************--
-- Note: This is advanced code and it is NOT expected that you should be able to read it yet. 
-- However, you will be able to by the end of the course! :-)
-- Meta Data Query:
With 
TablesAndColumns As (
Select  
  [SourceObjectName] = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
, [IS_NULLABLE]=[IS_NULLABLE]
, [DATA_TYPE] = Case [DATA_TYPE]
                When 'varchar' Then  [DATA_TYPE] + '(' + IIf(DATA_TYPE = 'int','', IsNull(Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)), '')) + ')'
                When 'nvarchar' Then [DATA_TYPE] + '(' + IIf(DATA_TYPE = 'int','', IsNull(Cast(CHARACTER_MAXIMUM_LENGTH as varchar(10)), '')) + ')'
                When 'money' Then [DATA_TYPE] + '(' + Cast(NUMERIC_PRECISION as varchar(10)) + ',' + Cast(NUMERIC_SCALE as varchar(10)) + ')'
                When 'decimal' Then [DATA_TYPE] + '(' + Cast(NUMERIC_PRECISION as varchar(10)) + ',' + Cast(NUMERIC_SCALE as varchar(10)) + ')'
                When 'float' Then [DATA_TYPE] + '(' + Cast(NUMERIC_PRECISION as varchar(10)) + ',' + Cast(NUMERIC_SCALE as varchar(10)) + ')'
                Else [DATA_TYPE]
                End                          
, [TABLE_NAME]
, [COLUMN_NAME]
, [ORDINAL_POSITION]
, [COLUMN_DEFAULT]
From Information_Schema.columns 
),
Constraints As (
Select 
 [SourceObjectName] = TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME + '.' + COLUMN_NAME
,[CONSTRAINT_NAME]
From [INFORMATION_SCHEMA].[CONSTRAINT_COLUMN_USAGE]
), 
IdentityColumns As (
Select 
 [ObjectName] = object_name(c.[object_id]) 
,[ColumnName] = c.[name]
,[IsIdentity] = IIF(is_identity = 1, 'Identity', Null)
From sys.columns as c Join Sys.tables as t on c.object_id = t.object_id
) 
Select 
  TablesAndColumns.[SourceObjectName]
, [IsNullable] = [Is_Nullable]
, [DataType] = [Data_Type] 
, [ConstraintName] = IsNull([CONSTRAINT_NAME], 'NA')
, [COLUMN_DEFAULT] = IsNull(IIF([IsIdentity] Is Not Null, 'Identity', [COLUMN_DEFAULT]), 'NA')
--, [ORDINAL_POSITION]
From TablesAndColumns 
Full Join Constraints On TablesAndColumns.[SourceObjectName]= Constraints.[SourceObjectName]
Full Join IdentityColumns On TablesAndColumns.COLUMN_NAME = IdentityColumns.[ColumnName]
                          And TablesAndColumns.TABLE_NAME = IdentityColumns.[ObjectName]
Where [TABLE_NAME] Not In (Select [TABLE_NAME] From [INFORMATION_SCHEMA].[VIEWS])
Order By [TABLE_NAME],[ORDINAL_POSITION]


