USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardClinicalTable]    Script Date: 4/25/2025 1:12:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DashboardClinicalTable]
    @ParamStartDate NVARCHAR(20),
    @ParamEndDate NVARCHAR(20),
    @StudentIds NVARCHAR(MAX), -- Comma-separated list of StudentIds
    @UserIds NVARCHAR(MAX),    -- CreatedBy user ID
    @ClassIds NVARCHAR(MAX)    -- Class ID filter
AS
BEGIN
    SET NOCOUNT ON;
    -- Table variables to store parsed IDs
    DECLARE @StudentIdTable TABLE (StudentId INT);
    DECLARE @UserIdTable TABLE (UserId INT);
    DECLARE @ClassIdTable TABLE (ClassId INT);
	DECLARE @StartDate DATE
	DECLARE @EndDate DATE

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

	SET @StartDate = CONVERT(DATE,@ParamStartDate)
	SET @EndDate = CONVERT(DATE,@ParamEndDate)
    -- Query to fetch required data
    SELECT 
        (SELECT CONCAT(LastName, ', ', FirstName) 
         FROM StudentPersonal 
         WHERE StudentPersonalID = b.StudentId) AS StudentName,
        c.ClassName,
		CONCAT(U.UserLName,', '+ U.UserFName) AS StaffName,
        CASE 
    WHEN SUM(CASE WHEN b.FrequencyCount IS NOT NULL THEN 1 ELSE 0 END) > 0 
         THEN SUM(CASE WHEN b.FrequencyCount IS NOT NULL THEN b.FrequencyCount ELSE 0 END)
    WHEN SUM(CASE WHEN (b.Duration IS NOT NULL AND b.Duration <> 0)
                   OR (b.YesOrNo IS NOT NULL AND b.YesOrNo <> 0) 
              THEN 1 ELSE 0 END) > 0 
         THEN 1
    ELSE 0
END AS Count,
        CONVERT(DATE, b.CreatedOn) AS CreatedDate
    FROM Behaviour b
    INNER JOIN StdtClass sc 
        ON b.StudentId = sc.StdtId 
        AND sc.ActiveInd = 'A'
        AND sc.ClassId IN (SELECT ClassId FROM @ClassIdTable)  -- Filtering by ClassId
    INNER JOIN Class c 
        ON sc.ClassId = c.ClassId
		INNER JOIN [User] U 
		ON U.UserId = b.CreatedBy
    WHERE 
        CONVERT(DATE,b.CreatedOn) BETWEEN @StartDate AND @EndDate
        AND (b.StudentId IN (SELECT StudentId FROM @StudentIdTable) OR b.StudentId IN (SELECT DISTINCT StdtId FROM StdtClass WHERE ActiveInd = 'A'))
        AND b.CreatedBy IN (SELECT UserId FROM @UserIdTable)
    GROUP BY b.StudentId, c.ClassName, CONVERT(DATE, b.CreatedOn), CONCAT(U.UserLName,', '+ U.UserFName), b.TimeOfEvent;;
END;

GO
