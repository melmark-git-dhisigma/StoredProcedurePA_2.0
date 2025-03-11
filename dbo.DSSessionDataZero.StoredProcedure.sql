USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[DSSessionDataZero]    Script Date: 11/04/2024 6:48:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DSSessionDataZero]
	@StudentId int,
@StartDate varchar(100),
@EndDate varchar(100)
AS
BEGIN
	SELECT EvntTs as time1,
	CONVERT(varchar(15),  CAST(EvntTs AS TIME), 100) StartTs,
	CONVERT(varchar,EvntTs,101) As SessPeriodDate,
	LessonPlanId,
	NULL AS CurrentSet,
	NULL AS CurrentPrompt,
	EventName,
	StdtSessEventType 
FROM [dbo].[StdtSessEvent] 
WHERE StudentId=@StudentId  AND @StartDate <= CONVERT(DATE,EvntTs) AND CONVERT(DATE,EvntTs) <= @EndDate AND EventType='EV' 
	AND StdtSessEventType IN ('Major','Minor','Arrow notes') AND LessonPlanId =0
order by SessPeriodDate
END
