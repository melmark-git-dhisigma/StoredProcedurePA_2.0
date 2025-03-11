USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[DSEventSessionZero]    Script Date: 11/04/2024 6:46:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DSEventSessionZero] 
@LessonId varchar(MAX),
@StudentId int,
@StartDate varchar(100),
@EndDate varchar(100)
AS
BEGIN
declare @lsid table (lsid int)
insert into @lsid(lsid) SELECT * FROM Split(@LessonId,',') OPTION (MAXRECURSION 500)
SELECT 	ClassId,
	EvntTs,
	CONVERT(varchar,EvntTs,101) As PeriodDate,
	LessonPlanId,
	NULL AS Score1,
	'1' AS IsLP,
	'1' AS IncludeInGraph 
FROM [dbo].[StdtSessEvent] 
WHERE StudentId=@StudentId  AND @StartDate <= CONVERT(DATE,EvntTs) AND CONVERT(DATE,EvntTs) <= @EndDate AND EventType='EV' AND SessionNbr IS NULL AND DSTempHdrId IS NULL
	AND StdtSessEventType IN ('Major','Minor','Arrow notes') AND LessonPlanId IN (select lsid from @lsid) 
ORDER BY EvntTs,LessonPlanId
END
