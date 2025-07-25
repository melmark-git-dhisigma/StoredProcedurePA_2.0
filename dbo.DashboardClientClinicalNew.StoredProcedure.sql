USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardClientClinicalNew]    Script Date: 7/8/2025 9:27:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DashboardClientClinicalNew] 
@ParamClassid VARCHAR(MAX) = NULL,
@ParamStudid VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClassSplt TABLE (data INT)
    DECLARE @StudSplt TABLE (data INT)

    IF @ParamClassid IS NOT NULL AND LTRIM(RTRIM(@ParamClassid)) <> ''
        INSERT INTO @ClassSplt SELECT * FROM Split(@ParamClassid, ',') OPTION (MAXRECURSION 5000)

    IF @ParamStudid IS NOT NULL AND LTRIM(RTRIM(@ParamStudid)) <> ''
        INSERT INTO @StudSplt SELECT * FROM Split(@ParamStudid, ',') OPTION (MAXRECURSION 5000)

    DECLARE @MaxSesNumber INT
    SET @MaxSesNumber = (
        SELECT TOP 1 COUNT(*) AS MaxSessionCount
        FROM Behaviour b
        WHERE (@ParamStudid IS NULL OR b.StudentId IN (SELECT data FROM @StudSplt))
            AND (@ParamClassid IS NULL OR b.ClassId IN (SELECT data FROM @ClassSplt))
            AND (b.FrequencyCount IS NOT NULL OR b.Duration IS NOT NULL)
            AND CONVERT(VARCHAR(10), b.CreatedOn, 120) = CONVERT(VARCHAR(10), GETDATE(), 120)
        GROUP BY b.StudentId
        ORDER BY MaxSessionCount DESC
    )

    SELECT 
        BHV.MeasurementId,
        BHV.StudentId,
        BD.ClassId,
        CASE 
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
        END AS BehaviourSession,
        CASE 
            WHEN COUNT(BHV.MeasurementId) <= 4 THEN SUBSTRING(BD.Behaviour, 1, 4)
            ELSE BD.Behaviour 
        END AS BehaviourName,
        BD.Behaviour AS BehaviorNameToolTip,
        (SELECT CONCAT(LastName, ', ', FirstName) FROM StudentPersonal WHERE StudentPersonalId = BHV.StudentId) AS StudentName,
        @MaxSesNumber AS MaxCount
    FROM Behaviour BHV
    INNER JOIN BehaviourDetails BD ON BHV.MeasurementId = BD.MeasurementId
    WHERE (@ParamStudid IS NULL OR BHV.StudentId IN (SELECT data FROM @StudSplt))
      AND (@ParamClassid IS NULL OR BHV.ClassId IN (SELECT data FROM @ClassSplt))
      AND CONVERT(VARCHAR(10), BHV.CreatedOn, 120) = CONVERT(VARCHAR(10), GETDATE(), 120)
    GROUP BY BHV.MeasurementId, BHV.StudentId, BD.Behaviour, BD.ClassId, BHV.TimeOfEvent
    ORDER BY StudentName
END
GO
