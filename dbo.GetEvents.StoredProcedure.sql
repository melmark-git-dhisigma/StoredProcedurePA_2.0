USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[GetEvents]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetEvents]
@StudentId int,
@SchoolId int,
@StartDate Datetime,
@EndDate Datetime

as

SELECT 'Phase lines' as Eventname,(SELECT STUFF((SELECT ', '+ EventName + ' (' + CONVERT(VARCHAR(50), EvntTs,103)+')' 
FROM StdtSessEvent 
WHERE CONVERT(DATE, EvntTs) BETWEEN @StartDate AND @EndDate AND  (StdtSessEventType='Major') 
AND StudentId=@StudentId  AND SchoolId=@SchoolId FOR XML PATH('')),1,1,'')) Eventdata
union all
SELECT 'Condition lines' as Eventname,(SELECT STUFF((SELECT ', '+ EventName + ' (' + CONVERT(VARCHAR(50), EvntTs,103)+')' 
FROM StdtSessEvent 
WHERE CONVERT(DATE, EvntTs) BETWEEN @StartDate AND @EndDate AND  (StdtSessEventType='Minor') 
AND StudentId=@StudentId AND SchoolId=@SchoolId FOR XML PATH('')),1,1,'')) Eventdata
union all
SELECT 'Arrow notes' as Eventname,(SELECT STUFF((SELECT ', '+ EventName + ' (' + CONVERT(VARCHAR(50), EvntTs,103)+')' 
FROM StdtSessEvent 
WHERE CONVERT(DATE, EvntTs) BETWEEN @StartDate AND @EndDate AND  (StdtSessEventType='Arrow notes') 
AND StudentId=@StudentId AND SchoolId=@SchoolId FOR XML PATH('')),1,1,'')) Eventdata
GO
