USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardAcademicTable]    Script Date: 4/25/2025 1:12:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DashboardAcademicTable]
    @ParamStartDate NVARCHAR(20),
    @ParamEndDate NVARCHAR(20),
    @StudentIds NVARCHAR(MAX),  -- Comma-separated list of StudentIds
    @UserIds NVARCHAR(MAX),     -- Comma-separated list of UserIds (ModifiedBy)
    @ParamMistrial BIT,         -- 1 to include all, 0 to filter 'N' values in SessMissTrailStus
    @ClassIds NVARCHAR(MAX)     -- Comma-separated list of ClassIds
AS
BEGIN
    SET NOCOUNT ON;

    -- Table variables to store separated IDs
    DECLARE @StudentIdTable TABLE (StudentId INT);
    DECLARE @UserIdTable TABLE (UserId INT);
    DECLARE @ClassIdTable TABLE (ClassId INT);
	DECLARE @StartDate DATE;
	DECLARE @EndDate DATE;

    -- Insert split values into respective table variables
    INSERT INTO @StudentIdTable (StudentId)
    SELECT * 
	FROM Split(@StudentIds, ',')
	OPTION (MAXRECURSION 5000) 

    INSERT INTO @UserIdTable (UserId)
    SELECT * 
	FROM Split(@UserIds, ',')
	OPTION (MAXRECURSION 5000) 

    INSERT INTO @ClassIdTable (ClassId)
    SELECT * 
	FROM Split(@ClassIds, ',')
	OPTION (MAXRECURSION 5000) 

	SET @StartDate = CONVERT(DATE,@ParamStartDate);
	SET @EndDate = CONVERT(DATE,@ParamEndDate);
    -- Query to fetch the required data
    SELECT 
        (SELECT CONCAT(LastName, ', ', FirstName) 
         FROM StudentPersonal 
         WHERE StudentPersonalID = s.StudentId) AS StudentName,
        c.ClassName,
		CONCAT(U.UserLName,', '+ U.UserFName) AS StaffName,
        COUNT(s.StdtSessionHdrId) AS Count,
        CONVERT(DATE, s.ModifiedOn) AS CreatedDate
    FROM StdtSessionHdr s
    INNER JOIN StdtClass sc 
        ON s.StudentId = sc.StdtId 
        AND sc.ActiveInd = 'A'
        AND sc.ClassId IN (SELECT ClassId FROM @ClassIdTable)  -- Filtering by ClassId
    INNER JOIN Class c 
        ON sc.ClassId = c.ClassId
	INNER JOIN [User] U 
		ON U.UserId = s.ModifiedBy
    WHERE 
        s.SessionStatusCd = 'S'
        AND CONVERT(DATE,s.ModifiedOn) BETWEEN @StartDate AND @EndDate
        AND (s.StudentId IN (SELECT StudentId FROM @StudentIdTable) 
             AND s.StudentId IN (SELECT DISTINCT StdtId FROM StdtClass WHERE ActiveInd = 'A'))
        AND s.ModifiedBy IN (SELECT UserId FROM @UserIdTable)
        AND (@ParamMistrial = 1 OR s.SessMissTrailStus = 'N') -- If 1, ignore this filter, else check for 'N'
    GROUP BY s.StudentId, c.ClassName, CONVERT(DATE, s.ModifiedOn), CONCAT(U.UserLName,', '+ U.UserFName);
END;

GO
