USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardStaffClinicalNew]    Script Date: 7/8/2025 9:27:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DashboardStaffClinicalNew] 
@ParamClassid VARCHAR(MAX) = NULL,
@ParamStudid VARCHAR(MAX) = NULL,
@ParamUserid VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SetClassids VARCHAR(MAX),
            @SetStudids VARCHAR(MAX),
            @SetUserids VARCHAR(MAX)

    SET @SetClassids = @ParamClassid
    SET @SetStudids = @ParamStudid
    SET @SetUserids = @ParamUserid

    DECLARE @ClassSplt TABLE (data INT)
	IF @SetClassids IS NOT NULL AND LTRIM(RTRIM(@SetClassids)) <> ''
    INSERT INTO @ClassSplt SELECT * FROM Split(@SetClassids, ',') OPTION (MAXRECURSION 5000)

    DECLARE @StudSplt TABLE (data INT)
	IF @SetStudids IS NOT NULL AND LTRIM(RTRIM(@SetStudids)) <> ''
    INSERT INTO @StudSplt SELECT * FROM Split(@SetStudids, ',') OPTION (MAXRECURSION 5000)

    DECLARE @UserSplt TABLE (data INT)
	IF @SetUserids IS NOT NULL AND LTRIM(RTRIM(@SetUserids)) <> ''
    INSERT INTO @UserSplt SELECT * FROM Split(@SetUserids, ',') OPTION (MAXRECURSION 5000)

    DECLARE @MaxSesNumber INT
    SET @MaxSesNumber = (
        SELECT TOP 1 COUNT(b.MeasurementId) AS MaxSessionCount
        FROM Behaviour b
        WHERE b.StudentId IN (SELECT data FROM @StudSplt)
          AND ClassId IN (SELECT ClassId FROM BehaviourDetails WHERE Measurementid = b.measurementid)
          AND (b.FrequencyCount > 0 OR b.Duration > 0)
          AND CONVERT(VARCHAR(10), b.createdon, 120) = CONVERT(VARCHAR(10), GETDATE(), 120)
        GROUP BY b.ModifiedBy
        ORDER BY MaxSessionCount DESC
    )

    SELECT
        (SELECT CONCAT(UserLName, ', ', UserFName) FROM [USER] WHERE Userid = BHV.Observerid) AS StaffName,
        BHV.Observerid AS Staffid,
        BHVDET.ClassId AS Classid,
        (SELECT CONCAT(LastName, ', ', FirstName) FROM StudentPersonal WHERE StudentPersonalId = BHV.StudentId) AS StudentName,
        BHV.StudentId AS StudentId,
        BHV.MeasurementId AS MeasurementId,
        MeasurementCount = CASE
            WHEN EXISTS (
                SELECT 1 FROM Behaviour B1
                WHERE B1.MeasurementId = BHV.MeasurementId
                  AND B1.TimeOfEvent = BHV.TimeOfEvent
                  AND B1.Duration IS NULL 
				  AND B1.YesOrNo IS NULL
                  AND B1.FrequencyCount IS NOT NULL AND B1.FrequencyCount > 0

            ) THEN (
                SELECT SUM(FrequencyCount) FROM Behaviour B2
                WHERE B2.MeasurementId = BHV.MeasurementId
                  AND B2.TimeOfEvent = BHV.TimeOfEvent
                  AND B2.FrequencyCount IS NOT NULL AND B2.FrequencyCount > 0
                  AND B2.Duration IS NULL AND B2.YesOrNo IS NULL
            )
            WHEN EXISTS (
                SELECT 1 FROM Behaviour B3
                WHERE B3.MeasurementId = BHV.MeasurementId
                  AND B3.TimeOfEvent = BHV.TimeOfEvent
                  AND ((B3.Duration IS NOT NULL AND B3.Duration > 0)
                       OR (B3.YesOrNo = 1))
            ) THEN 1
            ELSE 0
        END,
        (SELECT CASE
            WHEN COUNT(BHV.MeasurementId) <= 4 THEN (SELECT SUBSTRING(Behaviour, 1, 4) FROM BehaviourDetails WHERE MeasurementId = BHV.MeasurementId)
            ELSE (SELECT Behaviour FROM BehaviourDetails WHERE MeasurementId = BHV.MeasurementId)
        END) AS BehaviourName,
        @MaxSesNumber AS MaxCount,
        BHVDET.Behaviour AS BehaviorNameToolTip
    FROM Behaviour BHV
    INNER JOIN BehaviourDetails BHVDET ON BHV.MeasurementId = BHVDET.MeasurementId
    WHERE (@SetUserids IS NULL OR BHV.Observerid IN (SELECT data FROM @UserSplt))
      AND (@SetStudids IS NULL OR BHV.StudentId IN (SELECT * FROM @StudSplt))
      AND (@SetClassids IS NULL OR BHV.Classid IN (SELECT * FROM @ClassSplt))
      AND CONVERT(VARCHAR(10), BHV.createdon, 120) = CONVERT(VARCHAR(10), GETDATE(), 120)
    GROUP BY BHV.Observerid, BHV.MeasurementId, BHV.StudentId, BHVDET.Behaviour, BHVDET.ClassId, BHV.TimeOfEvent
    ORDER BY StaffName
END
GO
