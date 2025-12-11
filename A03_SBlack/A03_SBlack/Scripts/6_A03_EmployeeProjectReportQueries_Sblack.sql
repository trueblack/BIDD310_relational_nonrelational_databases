--*************************************************************************--
-- Title: Module03-Data Warehouse Report Queries -- ANSWERS
-- Desc: Code for module 3's assignment 
-- Change Log: When,Who,What
-- 2020-01-01,RRoot,Created File
-- TODO: <Date>,<YourNameHere>,Completed File
--*************************************************************************--

-- IMPORTANT: Remember to use the Surragote Keys and not the original IDs

Use DWEmployeeProjects;
go

-- Let's look at the data before we start writing test quieries
Create or Alter View vHoursByProjectAndCategory
As
  Select
     c.CategoryKey 
    ,c.CategoryName
    ,p.ProjectKey
    ,p.ProjectName
    ,HoursWorked
  From [FactEmployeeProjectHours] as eph
  Join [DimProjects] as p 
    On eph.ProjectKey = p.ProjectKey
  Join [FactProjectsCategories] as pc 
    On p.ProjectKey = pc.ProjectKey
  Join [DimCategories] as c 
    On pc.CategoryKey = c.CategoryKey;
go

Select * From vHoursByProjectAndCategory Order By CategoryName;
go

------------------------------------------------------------------------------------------------------------------
-- TODO 1: SELECT the total hours worked on all projects into a temporary table called #TotalByProject. 
------------------------------------------------------------------------------------------------------------------
If Object_ID('tempdb..#TotalByProject') is not null Drop Table #TotalByProject;
go

SELECT [TotalHours] = Sum(fh.HoursWorked)
Into #TotalByProject

FROM  
	( -- filtered hours
	Select
        DISTINCT ProjectKey
        ,HoursWorked 
    From vHoursByProjectAndCategory
	) fh


go
Select [TotalHours] From #TotalByProject;
go

/* Expected Results *************************************************************

TotalHours
------------
10

********************************************************************************/



------------------------------------------------------------------------------------------------------------------
-- TODO 2: SELECT the total hours worked on all Categories into a temporary table called #TotalByCategory. 
------------------------------------------------------------------------------------------------------------------
If Object_ID('tempdb..#TotalByCategory') is not null Drop Table #TotalByCategory;
go

SELECT [TotalHours] = Sum(fh.HoursWorked)
	Into #TotalByCategory

FROM  
	( -- filtered hours
	Select
        Distinct CategoryKey
        ,HoursWorked 
    From vHoursByProjectAndCategory
	) fh

go

Select [TotalHours] From #TotalByCategory;
go


/* Expected Results *************************************************************

TotalHours
------------
15

********************************************************************************/

------------------------------------------------------------------------------------------------------------------
-- TODO 3: SELECT the total hours worked along with the total hours worked by categories.
-- ADD a column that show the relative percentages
-- SAVE the data in a reporting table called rptCategoryContributions.
------------------------------------------------------------------------------------------------------------------

If (Object_ID('rptCategoryContributions') is not null) Drop Table rptCategoryContributions;
go
Declare @TotalHours int
  Select @TotalHours = [TotalHours] From #TotalByCategory; 
  Select 
    CategoryKey
    ,CategoryName
	,[TotalHoursByCategory] = Sum(HoursWorked) 
    ,@TotalHours as TotalHours
	,[PercentByCategory] = Format((Sum(HoursWorked) * 1.0) /@TotalHours , '00.00%')
   Into rptCategoryContributions
From vHoursByProjectAndCategory
Group By CategoryKey, CategoryName
go

Select * From rptCategoryContributions;
go

/* Selecting the table will return these Results *******************************

CategoryKey CategoryName   TotalHoursByCategory  TotalHours  PercentByCategory
----------- -------------  --------------------- ----------- ----------------- 
1           Planning       7.00                  15          46.67%
2           Implementation 8.00                  15          53.33%  
********************************************************************************/



------------------------------------------------------------------------------------------------------------------
-- TODO 4: SELECT the total hours worked along with the total hours worked by Projects.
-- ADD a column that show the relative percentages
-- SAVE the data in a reporting table called rptProjectContributions.
------------------------------------------------------------------------------------------------------------------

If (Object_ID('rptProjectContributions') is not null) Drop Table rptProjectContributions;
go

Declare @TotalHours int
  Select @TotalHours = [TotalHours] From #TotalByProject; 
   Select 
    ProjectKey
    ,ProjectName
	,[TotalHoursByProject] = Sum(HoursWorked) 
    ,@TotalHours as TotalHours
	, [PercentByProject] = Format((Sum(HoursWorked) * 1.0) /@TotalHours , '00.00%')
	INTO rptProjectContributions
	from (
	Select Distinct ProjectKey, ProjectName, HoursWorked
	From vHoursByProjectAndCategory
	) as uph
Group By ProjectName, ProjectKey
go

Select * From rptProjectContributions;

/* Selecting the table should return these Results *******************************

(3 row(s) affected)
ProjectKey  ProjectName        TotalHoursByProject  TotalHours  PercentByProject
----------- -----------------  -------------------- ----------- ----------------
1	          DW Planing	     2.00	               10	         20.00%
2	          DW Implementation	 3.00	               10	         30.00%
3	          DW Documentation	 5.00	               10	         50.00%
********************************************************************************/


------------------------------------------------------------------------------------------------------------------
-- TODO 5: SELECT the relative percentages of both categories and projects.
-- Insert the results into a reporting table rptTotalPrecentagesForProjectsAndCategories.
------------------------------------------------------------------------------------------------------------------
/* Hints:
    Use the vHoursByProjectAndCategory view to join the data
    Select * From rptCategoryContributions;
    Select * From rptProjectContributions;
    Select * From vHoursByProjectAndCategory Order By CategoryKey, ProjectKey;
    Use Select-Into
*/

If (Object_ID('rptTotalPrecentagesForProjectsAndCategories') is not null) Drop Table rptTotalPrecentagesForProjectsAndCategories;
go

SELECT
    c.CategoryName,
    c.TotalHoursByCategory,
    c.PercentByCategory,
    p.ProjectName,
    p.TotalHoursByProject,
    p.PercentByProject,
    v.HoursWorked
Into rptTotalPrecentagesForProjectsAndCategories

FROM rptCategoryContributions c
INNER JOIN vHoursByProjectAndCategory v 
    ON c.CategoryName = v.CategoryName
INNER JOIN rptProjectContributions p 
    ON p.ProjectName = v.ProjectName

go

Select * From rptTotalPrecentagesForProjectsAndCategories;
go

/* Selecting the table should return these Results *******************************************************************************************

CategoryName          TotalHoursByCategory  PercentByCategory   ProjectName         TotalHoursByProject   PercentByProject  TotalProjectHours
--------------------  --------------------- ------------------- ------------------- --------------------  ----------------  -----------------
Planning	            7.00	                46.67%	            DW Planing	        2.00	                20.00%	          10
Planning	            7.00	                46.67%	            DW Documentation	  5.00	                50.00%	          10
Implementation	      8.00	                53.33%	            DW Implementation	  3.00	                30.00%	          10
Implementation	      8.00	                53.33%	            DW Documentation	  5.00	                50.00%	          10
********************************************************************************************************************************************/

