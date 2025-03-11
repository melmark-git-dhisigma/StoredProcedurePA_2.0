USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[DSScoreZero]    Script Date: 11/04/2024 6:47:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DSScoreZero] 
@StudentId int,
@StartDate varchar(100),
@EndDate varchar(100)
AS
BEGIN
SELECT
	ClassId,
	NULL AS DSTempSetColCalcId,
	NULL AS ColName,
	EvntTs,
	CONVERT(VARCHAR(15),EvntTs,101)As PeriodDate,
	LessonPlanId,
	NULL AS CalcType,
	NULL AS ClassType,
	NULL AS Score1 ,
	'1' AS IsLP,
	'1' AS IncludeInGraph 	
FROM StdtSessEvent 
WHERE StudentId=@StudentId  AND @StartDate <= CONVERT(DATE,EvntTs) AND CONVERT(DATE,EvntTs) <= @EndDate AND EventType='EV' 
AND StdtSessEventType IN ('Major','Minor','Arrow notes')  AND LessonPlanId =0
ORDER BY EvntTs,LessonPlanId
END
