USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardAcademicTable]    Script Date: 7/8/2025 9:27:56 AM ******/
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
    @StudentIds NVARCHAR(MAX),  
    @UserIds NVARCHAR(MAX),     
    @ParamMistrial BIT,         
    @ClassIds NVARCHAR(MAX)     
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentIdTable TABLE (StudentId INT);
    DECLARE @UserIdTable TABLE (UserId INT);
    DECLARE @ClassIdTable TABLE (ClassId INT);
	DECLARE @StartDate DATE;
	DECLARE @EndDate DATE;

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
    SELECT 
        (SELECT CONCAT(LastName, ', ', FirstName) 
         FROM StudentPersonal 
         WHERE StudentPersonalID = s.StudentId) AS StudentName,
		(SELECT Classname from Class where ClassId = s.stdtclassid) as ClassName,
		CONCAT(U.UserLName,', '+ U.UserFName) AS StaffName,
        COUNT(s.StdtSessionHdrId) AS Count,
        CONVERT(DATE, s.ModifiedOn) AS CreatedDate
    FROM StdtSessionHdr s
	OUTER APPLY (
	    SELECT TOP 1 * 
		FROM StdtClass sc 
		WHERE sc.ClassId = s.StdtClassId 
		AND sc.StdtId = s.StudentId 
		AND sc.ActiveInd = 'A' 
		AND sc.ClassId IN (SELECT ClassId FROM @ClassIdTable)
		ORDER BY sc.StdtClassId DESC 
		 ) sc
	INNER JOIN [User] U 
		ON U.UserId = s.ModifiedBy
	CROSS APPLY (
    SELECT TOP 1 *
    FROM Placement pl
    WHERE pl.StudentPersonalId = s.StudentId
      AND (pl.StartDate IS NULL OR CONVERT(DATE, s.ModifiedOn) >= CONVERT(DATE, pl.StartDate))
      AND (pl.EndDate IS NULL OR CONVERT(DATE, s.ModifiedOn) <= CONVERT(DATE, pl.EndDate))
      AND pl.Status = 1 
    ORDER BY pl.PlacementId DESC
) pl
    WHERE 
        s.SessionStatusCd = 'S'
		AND s.StdtClassId IN (SELECT ClassId FROM @ClassIdTable)
        AND CONVERT(DATE,s.ModifiedOn) BETWEEN @StartDate AND @EndDate
        AND (s.StudentId IN (SELECT StudentId FROM @StudentIdTable) 
             AND s.StudentId IN (SELECT DISTINCT StdtId FROM StdtClass WHERE ActiveInd = 'A'))
        AND s.ModifiedBy IN (SELECT UserId FROM @UserIdTable)
		AND (pl.EndDate IS NULL OR CONVERT(DATE,pl.EndDate) >= CONVERT(DATE,GETDATE()))
		AND pl.Status = 1
        AND (@ParamMistrial = 1 OR s.SessMissTrailStus = 'N')
		AND sc.StdtClassId IS NOT NULL
    GROUP BY s.StudentId,s.StdtClassId, CONVERT(DATE, s.ModifiedOn), CONCAT(U.UserLName,', '+ U.UserFName);
END;

GO
