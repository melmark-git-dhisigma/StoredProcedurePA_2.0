USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ChainedSessionReport]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ChainedSessionReport]
@LessonPlanName varchar(max),
@StudentName varchar(500),
@StartDate datetime,
@EndDate datetime
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @LPName varchar(max),
	@SName varchar(500),
	@SDate datetime,
	@EDate datetime


	SET @LPName=@LessonPlanName
	SET @SName=@StudentName
	SET @SDate=DATEADD(DAY,-1,@StartDate)
	SET @EDate=DATEADD(DAY,1,@EndDate)

    SELECT 
	STP.StdtSessionStepId
	,CASE WHEN DCOL.ColTypeCd='Prompt' THEN (SELECT LookupName FROM LookUp WHERE LookupId=DTL.StepVal) ELSE DTL.StepVal END AS StepVal
	,DSTP.StepCd
	,DCOL.ColTypeCd
	,HDR.LessonPlanId
	,HDR.StartTs
	,HDR.EndTs
	,LP.LessonPlanName
	,HDR.StudentId
	,ST.StudentLname+' , '+ST.StudentFname AS StudentName
	,DCOL.ColName
	,(SELECT SetCd FROM DSTempSet WHERE DSTempSetId=HDR.CurrentSetId) CurrentSet
	,(SELECT StepCd FROM DSTempStep WHERE SortOrder=HDR.CurrentStepId AND DSTempSetId=HDR.CurrentSetId) CurrentStep
	,(SELECT LookupName FROM LookUp WHERE LookupId=HDR.CurrentPromptId) CurrentPrompt 
	FROM StdtSessionStep STP 
	INNER JOIN StdtSessionDtl DTL 
	ON STP.StdtSessionStepId=DTL.StdtSessionStepId
	INNER JOIN DSTempStep DSTP 
	ON DSTP.DSTempStepId=STP.DSTempStepId 
	INNER JOIN DSTempSetCol DCOL 
	ON DTL.DSTempSetColId=DCOL.DSTempSetColId
	INNER JOIN StdtSessionHdr HDR 
	ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId 
	INNER JOIN LessonPlan LP 
	ON LP.LessonPlanId=HDR.LessonPlanId
	INNER JOIN Student ST 
	ON ST.StudentId=HDR.StudentId
	WHERE HDR.SessionStatusCd='S'
	AND HDR.IOAInd='N'
	AND HDR.StartTs BETWEEN @SDate AND @EDate
	AND LP.LessonPlanName LIKE '%'+@LPName+'%'
	AND (ST.StudentFname LIKE '%'+@SName+'%' OR ST.StudentLname LIKE '%'+@SName+'%' OR ST.StudentLname+','+ST.StudentFname LIKE '%'+@SName+'%'
		OR ST.StudentFname+','+ST.StudentLname LIKE '%'+@SName+'%' OR ST.StudentLname+' '+ST.StudentFname LIKE '%'+@SName+'%' 
		OR ST.StudentFname+' '+ST.StudentLname LIKE '%'+@SName+'%')
END





GO
