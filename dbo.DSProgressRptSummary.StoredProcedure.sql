USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[DSProgressRptSummary]    Script Date: 11/04/2024 6:46:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DSProgressRptSummary]
@LessonId varchar(MAX),
@LPStatus varchar(100),
@StudentId int,
@StartDate varchar(100),
@EndDate varchar(100)

AS
BEGIN
DECLARE @Approved INT,@Maintenance INT,@Inactive INT
SELECT 
@Approved=CASE WHEN LookupName='Approved' THEN LookupId ELSE @Approved END
,@Maintenance=CASE WHEN LookupName='Maintenance' THEN LookupId ELSE @Maintenance END 
,@Inactive=CASE WHEN LookupName='Inactive' THEN LookupId ELSE @Inactive END 
FROM
Lookup WHERE LookupType='TemplateStatus' AND LookupName IN('Approved','Maintenance','Inactive') 

declare @slpst table (ss varchar(50)) 
insert into @slpst (ss) SELECT * FROM Split(@LPStatus,',') OPTION (MAXRECURSION 500)
declare @t_lessonplans table (ls int)
insert into @t_lessonplans (ls) SELECT * FROM Split(@LessonId,',') OPTION (MAXRECURSION 500) 

SELECT DISTINCT StudentId
	,StdtClassId AS ClassId
	,DSTempSetColCalcId
	,ColName
	,CONVERT(varchar,ReportPeriod.PeriodDate,101) AS PeriodDate

	,LessonName
	,LessonPlanId
	,CalcType
	,ClassType
	,CASE WHEN CONVERT(DATE, EndTs) =PeriodDate THEN Score END AS Score
	,IsLP
	,IncludeInGraph
	,ReportPeriod.PeriodDate AS SortDate
	,LessonOrder
	 FROM (
SELECT sc.StudentId
	,sc.DSTempSetColCalcId
	,CASE WHEN CalcType IN ('Avg Duration','Total Duration') THEN CASE WHEN  Hdr.IsMaintanace=0 THEN CalcType+ ' (In Seconds)' END Else CalcType END CalcType
	,ColName
	,hdr.EndTs
	
	,hdr.StdtClassId
	,hdr.LessonPlanId
	,(SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE LessonPlanId=hdr.LessonPlanId AND StudentId=@StudentId AND StatusId IN(SELECT  ss  FROM @slpst) ORDER BY DSTempHdr.DSTempHdrId DESC) AS LessonName
	,CASE WHEN ResidenceInd=1 THEN 'Residence' ELSE 'Day' END AS ClassType
	,dcal.IncludeInGraph
	,'1' AS IsLP
	,DHDR.LessonOrder
	,CASE WHEN CalcType IN ('Avg Duration','Total Duration') THEN CASE WHEN Hdr.IsMaintanace=0 THEN sc.Score END
	Else sc.Score END Score
	,CONVERT(DATE, hdr.EndTs) AS SortDate
FROM StdtSessionHdr hdr INNER JOIN DSTempHdr DHDR ON hdr.DSTempHdrId=DHDR.DSTempHdrId
--INNER JOIN LookUp LU ON LU.LookupId=DHDR.StatusId 
INNER JOIN StdtSessColScore  sc ON sc.StdtSessionHdrId=hdr.StdtSessionHdrId
INNER JOIN DSTempSetColCalc dcal ON dcal.DSTempSetColCalcId = sc.DSTempSetColCalcId
INNER JOIN Class Cls ON Cls.ClassId=hdr.StdtClassId
LEFT JOIN DSTempSetCol DC ON DC.DSTempSetColId=DCAL.DSTempSetColId		  
WHERE hdr.IOAInd='N' AND hdr.SessMissTrailStus ='N' AND hdr.SessionStatusCd='S' AND DHDR.StudentId=@StudentId AND DHDR.LessonPlanId IN (SELECT ls from @t_lessonplans )
	--AND LU.LookupType='TemplateStatus' AND LU.LookupName IN ( select ss from  @slpst )
	)AS StdCalcs,ReportPeriod
WHERE  StdCalcs.StudentId=@StudentId AND PeriodDate>=@StartDate AND PeriodDate<=@EndDate 
ORDER BY SortDate, LessonOrder
END
