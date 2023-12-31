USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Text_Based Data_bkup02may2022]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Text_Based Data_bkup02may2022] @StartDate    DATETIME,
                                 @ENDDate      DATETIME,
                                 @Studentid    INT,
                                 @LessonPlanId VARCHAR(100),
                                 @LPStatus     VARCHAR(50),
								 @LessonType   VARCHAR(30),
								 @Timestatus   INT
AS
  BEGIN
      SET nocount ON;

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
					Step.Comments As Notes	
  FROM StdtSessionStep Step 
  INNER JOIN StdtSessionHdr Hdr ON Hdr.StdtSessionHdrId=Step.StdtSessionHdrId 
  INNER JOIN StdtSessionDtl Dtl INNER JOIN DSTempSetCol Col 
  ON Col.DSTempSetColId=Dtl.DSTempSetColId 
  ON Dtl.StdtSessionStepId=Step.StdtSessionStepId
	WHERE 
		  Hdr.StudentId=@Studentid and hdr.LessonPlanId=@LessonPlanId and Dtl.ModifiedOn>=@StartDate and Dtl.ModifiedOn<=@ENDDate
	ORDER BY Hdr.SessionNbr,Step.TrialNbr

  END 
GO
