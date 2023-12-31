USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[Text_Based Data]    Script Date: 10/05/2023 5:08:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Text_Based Data] @StartDate    DATETIME,
                                 @ENDDate      DATETIME,
                                 @Studentid    INT,
                                 @LessonPlanId VARCHAR(100),
                                 @LPStatus     VARCHAR(50),
								 @LessonType   VARCHAR(30),
								 @Timestatus   INT
								 
AS
  BEGIN
      SET nocount ON;

				DECLARE		@Teachid int,
							@chaintype VARCHAR(30),
							@teachtype VARCHAR(30)

	DECLARE @LPSTS TABLE (LPSTS VARCHAR(50))
	INSERT INTO @LPSTS(LPSTS) SELECT * FROM Split(@LPStatus,',')

SET @Teachid=(SELECT top 1 TeachingProcId FROM DSTempHdr WHERE LessonPlanId = @LessonPlanId and
				StudentId is not null and 
				StatusId in(SELECT lookupid from [lookup] where LookUpType='TemplateStatus' AND LookupName in(SELECT * FROM @LPSTS)))

SET @teachtype=(SELECT LookupDesc FROM LookUp WHERE LookupId = @Teachid)

SET @chaintype=(SELECT top 1 skilltype FROM DSTempHdr WHERE LessonPlanId = @LessonPlanId and 
				StudentId is not null and 
				StatusId in(SELECT lookupid from [lookup] where LookUpType='TemplateStatus' AND LookupName in(SELECT * FROM @LPSTS)))

IF(@chaintype = 'Discrete' and @teachtype != 'Match-to-Sample')
	BEGIN 
		SELECT DISTINCT 
					Hdr.EndTs as Sessdate,		
					Hdr.SessionNbr as SessNo,
					Step.TrialNbr,
					(Step.TrialNbr+1) as TrialNo,										
					Col.ColName as Columname,
					--Dtl.StepVal AS columnMeasure,
					(select 
						case 
							when Col.ColTypeCd='Prompt' then (CASE WHEN Dtl.StepVal = -2 THEN 'Fail' ELSE (select lookupname from LookUp where LookupId = Dtl.StepVal) END)
							when Col.ColTypeCd='Frequency' then (CASE WHEN Dtl.StepVal = -1 THEN '  ' ELSE Dtl.Stepval END) 
							else  Dtl.StepVal
						end)
						AS columnMeasure,
					Step.Comments As Notes,					
					concat(Us.UserFName,' ',Us.UserLName) 
					as StaffName	,
					 concat(Dset.SetCd,' ', Dset.SetName)
					 as SetName ,
					' ' as StepName
  FROM StdtSessionStep Step 
 INNER JOIN StdtSessionHdr Hdr ON Hdr.StdtSessionHdrId=Step.StdtSessionHdrId 
 INNER JOIN  [User] Us on Us.UserId=Hdr.CreatedBy
 INNER JOIN  DSTempSet Dset on Dset.DSTempSetId=Hdr.CurrentSetId
 
  INNER JOIN StdtSessionDtl Dtl INNER JOIN DSTempSetCol Col 
  ON Col.DSTempSetColId=Dtl.DSTempSetColId 
  ON Dtl.StdtSessionStepId=Step.StdtSessionStepId
	WHERE 
		  Hdr.StudentId=@Studentid and hdr.LessonPlanId=@LessonPlanId 
		  and Dtl.ModifiedOn>=@StartDate and Dtl.ModifiedOn<=@ENDDate
	ORDER BY Hdr.SessionNbr,Step.TrialNbr

	END

	ELSE
		BEGIN

	  SELECT DISTINCT 
					Hdr.EndTs as Sessdate,		
					Hdr.SessionNbr as SessNo,
					Step.TrialNbr,
					(Step.TrialNbr+1) as TrialNo,										
					Col.ColName as Columname,
					--Dtl.StepVal AS columnMeasure,
					(select 
						case 
							when Col.ColTypeCd='Prompt' then (CASE WHEN Dtl.StepVal = -2 THEN 'Fail' ELSE (select lookupname from LookUp where LookupId = Dtl.StepVal) END)
							when Col.ColTypeCd='Frequency' then (CASE WHEN Dtl.StepVal = -1 THEN '  ' ELSE Dtl.Stepval END) 
							else  Dtl.StepVal
						end)
						AS columnMeasure,
					Step.Comments As Notes,
					concat(Us.UserFName,' ',Us.UserLName) as StaffName	,concat(Dset.SetCd,' ', Dset.SetName)as SetName,
					concat(Dstep.StepCd,' ', Dstep.StepName) as StepName
  FROM StdtSessionStep Step 
  INNER JOIN StdtSessionHdr Hdr ON Hdr.StdtSessionHdrId=Step.StdtSessionHdrId 
 INNER JOIN  [User] Us on Us.UserId=Hdr.CreatedBy
 INNER JOIN DSTempStep Dstep on step.DSTempStepId=Dstep.DSTempStepId
 INNER JOIN  DSTempSet Dset on Dstep.DSTempSetId=Dset.DSTempSetId
 
  INNER JOIN StdtSessionDtl Dtl INNER JOIN DSTempSetCol Col 
  ON Col.DSTempSetColId=Dtl.DSTempSetColId 
  ON Dtl.StdtSessionStepId=Step.StdtSessionStepId
	WHERE 
		  Hdr.StudentId=@Studentid and hdr.LessonPlanId=@LessonPlanId and Dtl.ModifiedOn>=@StartDate and Dtl.ModifiedOn<=@ENDDate
	ORDER BY Hdr.SessionNbr,Step.TrialNbr
	END

  END 

GO
