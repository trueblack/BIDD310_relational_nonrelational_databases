--*************************************************************************--
-- Title: Module 3 - OLTP Source Database
-- Desc: Drops and creates a source database for module 03.
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
--*************************************************************************--
-- Create the database
Use Master;
go
If Exists(Select name from master.dbo.sysdatabases Where Name = 'EmployeeProjects')
Begin
	Use [master];
	Alter Database [EmployeeProjects] Set Single_User With Rollback Immediate;
	Drop Database [EmployeeProjects];
End;
go

Create Database EmployeeProjects; 
go

Use EmployeeProjects;
go

--********************************************************************--
-- Create the tables --
--********************************************************************--

Create Table Categories
([ID] int Constraint pkCategories Primary Key Identity
,[Name] varchar(17) NOT NULL
,[Desc] varchar(300) NOT NULL
);
go

Create Table Projects
([ID] int Constraint pkProjects Primary Key Identity(100, 100) -- Using 100s to make the IDs stand out for demo!
,[Name] varchar(33) NOT NULL
,[Desc] varchar(300) NOT NULL
);
go

Create Table ProjectsCategories
([CategoryID] int NOT NULL
,[ProjectID] int NOT NULL 
Constraint pkProjectsCategories Primary Key ([CategoryID],[ProjectID])
);
go


Create Table Employees
([ID] int Constraint pkEmployees Primary Key Identity
,[FName] varchar(15) NOT NULL
,[LName] varchar(20) NOT NULL
,[Address] varchar(100) NOT NULL
,[City] varchar(50) NOT NULL
,[State] char(2) NOT NULL
,[Zipcode] char(5) NOT NULL
);
go

Create Table EmployeeProjectHours
([EmployeeProjectHoursID] int Constraint pkEmployeeProjectHours Primary Key Identity
,[EmployeeID] int NOT NULL 
,[ProjectID] int NOT NULL 
,[Date] date NOT NULL 
,[Hrs] decimal(4,2) NOT NULL 
);
go

--********************************************************************--
-- Add the constraints --
--********************************************************************--

Alter Table EmployeeProjectHours 
  Add Constraint FK_EmployeeProjectHours_Employees
  Foreign Key (EmployeeID) References Employees(ID);
go

Alter table EmployeeProjectHours 
  Add Constraint FK_EmployeeProjectHours_Projects
  Foreign Key(ProjectID) References Projects(ID);
go

Alter table ProjectsCategories 
  Add Constraint FK_ProjectsCategories_Categories
  Foreign Key(CategoryID) References Categories(ID);
go

Alter table ProjectsCategories
  Add Constraint FK_ProjectsCategories_Projects
  Foreign Key(ProjectID) References Projects(ID);
go

--********************************************************************--
-- Fill the tables with mockup data --
--********************************************************************--
-- Fictitious Random Data was generated using the app at https://www.mockaroo.com/
Set NoCount On;														
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Roselin', 'Habershon', '00441 Briar Crest Lane', 'San Jose', 'CA', '95123');
Insert Into Employees (FName, LName, Address, City, State, Zipcode) Values ('Samuel', 'Kwietek', '9367 Pennsylvania Junction', 'Los Angeles', 'CA', '90010');
go

Insert into Categories (Name, [Desc]) values ('Planning', 'Planing Phase');
Insert into Categories (Name, [Desc]) values ('Implementation', 'Implementation Phase');
go

Insert into Projects (Name, [Desc]) values ('DW Planing', 'DW Planing project');
Insert into Projects (Name, [Desc]) values ('DW Implementation', 'DW Implementation project');
Insert into Projects (Name, [Desc]) values ('DW Documentation', 'Document Update project');
go	
	
Insert into ProjectsCategories (CategoryID, ProjectID) values (1,100);
Insert into ProjectsCategories (CategoryID, ProjectID) values (2,200);
Insert into ProjectsCategories (CategoryID, ProjectID) values (1,300); -- Many to Many
Insert into ProjectsCategories (CategoryID, ProjectID) values (2,300); -- Many to Many
go

Insert Into EmployeeProjectHours (EmployeeID, ProjectID, Date, Hrs ) Values (1, 100, '01/01/2020', 2);
Insert Into EmployeeProjectHours(EmployeeID, ProjectID, Date, Hrs) Values (2, 200, '01/01/2020', 3);
Insert Into EmployeeProjectHours (EmployeeID, ProjectID, Date, Hrs) Values (1, 300, '01/02/2020', 5);
go																					



--********************************************************************--
-- Show the metadata and data of the source database
--********************************************************************--
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


Select * From Categories;
Select * From ProjectsCategories;
Select * From Projects;
Select * From Employees;
Select * From EmployeeProjectHours;
go

