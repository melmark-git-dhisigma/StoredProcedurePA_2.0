USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[DSSessionData]    Script Date: 11/04/2024 6:48:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE[dbo].[DSSessionData]
	@LessonId varchar(MAX),
@StudentId int,
@StartDate varchar(100),
@EndDate varchar(100)
AS
BEGIN
	declare @lsid table (lsid int)
insert into @lsid(lsid) SELECT * FROM Split(@LessonId,',') OPTION (MAXRECURSION 500)
SELECT EndTs as time1,
	CONVERT(varchar(15),  CAST(EndTs AS TIME), 100) StartTs,
	CONVERT(VARCHAR(10),EndTs,101) SessPeriodDate,
	SH.LessonPlanId,
	DS.SetCd AS CurrentSet,
	LU.LookupName AS CurrentPrompt,
	(SELECT STUFF((SELECT ','+CONVERT(NVARCHAR(MAX), EventName)  FROM (SELECT [EventName]  FROM StdtSessEvent WHERE LessonPlanId=SH.LessonPlanId AND SH.SessionNbr=SessionNbr 
		AND @StartDate <= CONVERT(DATE,EvntTs) AND CONVERT(DATE,EvntTs) <= @EndDate AND EventType='EV' AND StdtSessEventType IN ('Major','Minor','Arrow notes') ) EventName FOR XML PATH('')),1,1,'')) 
		AS EventName,
	CASE WHEN (SELECT COUNT(*) FROM StdtSessEvent where StdtSessEventType='Major' and SessionNbr=SH.SessionNbr AND LessonPlanId=SH.LessonPlanId ) >0 
		THEN 'Major' 
	ELSE CASE WHEN (SELECT COUNT(*) FROM StdtSessEvent where StdtSessEventType='Minor' and SessionNbr=SH.SessionNbr AND LessonPlanId=SH.LessonPlanId )>0 
		THEN 'Minor' END END AS StdtSessEventType
		,(SELECT CONCAT(UserFname,', '+UserLName) from [User] where userid = SH.ModifiedBy) as UserName
FROM StdtSessionHdr SH LEFT JOIN DSTempSet DS ON DS.DSTempSetId = SH.CurrentSetId	
	RIGHT JOIN StdtSessEvent SE ON SE.DSTempHdrId=SH.DSTempHdrId
	LEFT JOIN LookUp LU ON LU.LookupId=SH.CurrentPromptId
WHERE SessionStatusCd='S' AND IOAInd='N' AND  SH.StudentId=@StudentId AND @StartDate <= CONVERT(DATE,EndTs) AND CONVERT(DATE,EndTs) <= @EndDate 	
	AND SH.LessonPlanId IN (select lsid from @lsid)
GROUP BY SH.LessonPlanId,SH.SessionNbr,SetCd,LU.LookupName,EndTs,SH.ModifiedBy
UNION ALL
SELECT EndTs as time1,
	CONVERT(varchar(15),  CAST(EndTs AS TIME), 100) StartTs,
	CONVERT(varchar,EndTs,101) As SessPeriodDate, 
	LessonPlanId,
	DS.SetCd AS CurrentSet,
	LU.LookupName AS CurrentPrompt,
	('IOA '+CONVERT(nvarchar,ROUND(IOAPerc,0),0)+'% '+(SELECT RTRIM(LTRIM(UPPER(UserInitial))) From [User] US WHERE US.UserId=(SELECT IOAUserId 
		FROM StdtSessionHdr Hdr WHERE Hdr.StdtSessionHdrId=SH.IOASessionHdrId AND Hdr.IOAInd='N'))+'/'+
		(SELECT RTRIM(LTRIM(UPPER(UserInitial))) From [User] US where SH.IOAUserId=US.UserId AND SH.IOAInd='Y'))EventName,
	StdtSessEventType='ArrowNote',
	(SELECT CONCAT(UserFname,', '+UserLName) from [User] where userid = SH.ModifiedBy) as UserName
FROM  StdtSessionHdr SH LEFT JOIN DSTempSet DS ON DS.DSTempSetId = SH.CurrentSetId	
	LEFT JOIN LookUp LU ON LU.LookupId=SH.CurrentPromptId 
WHERE StudentId=@StudentId  AND  @StartDate <= CONVERT(DATE,EndTs)  AND CONVERT(DATE,EndTs) <= @EndDate AND IOAInd='Y' 
	AND LessonPlanId IN (select lsid from @lsid) AND IOAPerc IS NOT NULL
UNION ALL
SELECT EvntTs as time1,
	CONVERT(varchar(15),  CAST(EvntTs AS TIME), 100) StartTs,
	CONVERT(varchar,EvntTs,101) As SessPeriodDate,
	LessonPlanId,
	NULL AS CurrentSet,
	NULL AS CurrentPrompt,
	EventName,
	StdtSessEventType,
	NULL
FROM [dbo].[StdtSessEvent] 
WHERE StudentId=@StudentId  AND @StartDate <= CONVERT(DATE,EvntTs) AND CONVERT(DATE,EvntTs) <= @EndDate AND EventType='EV' AND SessionNbr IS NULL
	AND StdtSessEventType IN ('Major','Minor','Arrow notes') AND LessonPlanId IN (select lsid from @lsid)
ORDER BY time1,LessonPlanId
END
