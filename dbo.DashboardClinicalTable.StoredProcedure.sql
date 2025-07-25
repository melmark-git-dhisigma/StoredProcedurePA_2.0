USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardClinicalTable]    Script Date: 7/8/2025 9:27:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DashboardClinicalTable]
    @ParamStartDate NVARCHAR(20),
    @ParamEndDate NVARCHAR(20),
    @StudentIds NVARCHAR(MAX), 
    @UserIds NVARCHAR(MAX),    
    @ClassIds NVARCHAR(MAX)    
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentIdTable TABLE (StudentId INT);
    DECLARE @UserIdTable TABLE (UserId INT);
    DECLARE @ClassIdTable TABLE (ClassId INT);
    DECLARE @StartDate DATE, @EndDate DATE;

    INSERT INTO @StudentIdTable (StudentId)
    SELECT * FROM Split(@StudentIds, ',') OPTION (MAXRECURSION 5000);

    INSERT INTO @UserIdTable (UserId)
    SELECT * FROM Split(@UserIds, ',') OPTION (MAXRECURSION 5000);

    INSERT INTO @ClassIdTable (ClassId)
    SELECT * FROM Split(@ClassIds, ',') OPTION (MAXRECURSION 5000);

    SET @StartDate = CONVERT(DATE, @ParamStartDate);
    SET @EndDate = CONVERT(DATE, @ParamEndDate);

    ;WITH ValidPlacements AS (
        SELECT DISTINCT StudentPersonalId
        FROM Placement
        WHERE (EndDate IS NULL OR CONVERT(DATE, EndDate) >= CONVERT(DATE, GETDATE()))
          AND Status = 1
    ),
    RawBehaviour AS (
        SELECT 
            b.StudentId,
            b.CreatedBy,
            CONVERT(DATE, b.CreatedOn) AS CreatedDate,
            b.MeasurementId,
            b.TimeOfEvent,
            b.FrequencyCount,
            b.Duration,
            b.YesOrNo,
			b.ClassId
        FROM Behaviour b
        INNER JOIN ValidPlacements vp ON b.StudentId = vp.StudentPersonalId
        WHERE CONVERT(DATE, b.CreatedOn) BETWEEN @StartDate AND @EndDate
    ),
    BehaviourCounts AS (
        SELECT
            StudentId,
            CreatedBy,
            CreatedDate,
            MeasurementId,
            TimeOfEvent,
			ClassId,
            CASE 
                WHEN SUM(CASE WHEN FrequencyCount IS NOT NULL AND Duration IS NULL AND YesOrNo IS NULL THEN 1 ELSE 0 END) > 0
                    THEN SUM(CASE WHEN FrequencyCount IS NOT NULL AND Duration IS NULL AND YesOrNo IS NULL THEN FrequencyCount ELSE 0 END)
                WHEN SUM(CASE WHEN (Duration IS NOT NULL AND Duration > 0) OR YesOrNo = 1 THEN 1 ELSE 0 END) > 0
                    THEN 1
                ELSE 0
            END AS BehaviourValue
        FROM RawBehaviour
        GROUP BY StudentId, CreatedBy, CreatedDate, MeasurementId, TimeOfEvent, ClassId
    )

    SELECT 
        (SELECT CONCAT(LastName, ', ', FirstName) 
         FROM StudentPersonal 
         WHERE StudentPersonalID = bc.StudentId) AS StudentName,
        c.ClassName,
        CONCAT(u.UserLName, ', ', u.UserFName) AS StaffName,
        SUM(bc.BehaviourValue) AS Count,
        bc.CreatedDate
    FROM (
        SELECT DISTINCT 
            StudentId, CreatedBy, CreatedDate, TimeOfEvent, MeasurementId, BehaviourValue, ClassId
        FROM BehaviourCounts
    ) bc
    INNER JOIN [User] u ON u.UserId = bc.CreatedBy
	  OUTER APPLY (
	    SELECT TOP 1 * 
		FROM StdtClass sc 
		WHERE sc.ClassId = bc.ClassId
		AND sc.StdtId = bc.StudentId 
		AND sc.ActiveInd = 'A' 
		AND sc.ClassId IN (SELECT ClassId FROM @ClassIdTable)
		ORDER BY sc.StdtClassId DESC 
		 ) sc
    INNER JOIN Class c ON sc.ClassId = c.ClassId
    WHERE 
		bc.ClassId	IN (SELECT ClassId FROM @ClassIdTable)
        AND bc.StudentId IN (SELECT StudentId FROM @StudentIdTable)
        AND bc.StudentId IN (SELECT StudentPersonalId FROM ValidPlacements)
        AND bc.CreatedBy IN (SELECT UserId FROM @UserIdTable)
    GROUP BY 
        bc.StudentId,bc.ClassId, c.ClassName, bc.CreatedDate, CONCAT(u.UserLName, ', ', u.UserFName);
END;
GO
