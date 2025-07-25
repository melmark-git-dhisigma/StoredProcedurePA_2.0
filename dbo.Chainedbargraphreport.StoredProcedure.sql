USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Chainedbargraphreport]    Script Date: 7/4/2025 1:21:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


 alter PROCEDURE [dbo].[Chainedbargraphreport]
     
	 @LessonPlanId int
	, @PromptType varchar(15)
	, @StudentId int
	, @SchoolId int
	, @SDate datetime
	, @DSTempHdrId int
	, @EDate datetime
	, @ClassType varchar(15)

AS
BEGIN	
	SET NOCOUNT ON;
Declare @CNT INT	
	, @RCNT INT
	, @SessNbr INT
	, @CSessNbr INT
	, @Step INT		
	, @CStep INT	
	, @ID INT
	, @DIFF INT	
	, @CSOrder INT
	, @COLOR VARCHAR(15)
	, @SOrdr INT	
	, @Coff INT
	, @EVNT NVARCHAR(MAX)
	, @HdrId int
	, @CHdrId int
	, @cntc int
	, @ctype varchar(50)
	, @clstype varchar(50)
	

	SET @EDate=@EDate +'23:59:59:998'
	SET @ctype=(SELECT TOP (1) CASE WHEN LessonPlanTypeDay = 1 AND LessonPlanTypeResi = 1 
				THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay = 1 THEN 'Day' 
				ELSE CASE WHEN LessonPlanTypeResi = 1 THEN 'Residence' END END END AS Expr1
				FROM StdtLessonPlan WHERE (LessonPlanId = @LessonPlanId) AND (StudentId = @StudentId) AND (SchoolId = @SchoolId)
				ORDER BY StdtLessonPlanId DESC)


IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL  
DROP TABLE #TEMP	

CREATE TABLE #TEMP (RNumber INT NOT NULL PRIMARY KEY IDENTITY(1,1), SessNbr INT, LessonPlanId INT, StudentId INT, StartTs DATETIME,  StepVal VARCHAR(250), 
	Prompt VARCHAR(250), ShortName VARCHAR(210), StepName INT, StdtSessionDtlId INT, StdtSessionStepId INT, CurrentPrompt VARCHAR(250), ColTypeCd VARCHAR(210), 
	StudentFname VARCHAR(250), StudentLname VARCHAR(250), DSTempHdrId INT, LessonPlanName VARCHAR(250), ClassType VARCHAR(250), ChainType VARCHAR(250), 
	EventName NVARCHAR(MAX), SOrder INT, Color VARCHAR(15), Offset INT)

CREATE NONCLUSTERED INDEX IX_TEMP_SOrder ON #TEMP (SOrder);

IF (@ClassType = 'Day' OR @ClassType = 'Residence')
	BEGIN

	IF(@PromptType='Current')
	BEGIN
		INSERT INTO #TEMP(
			SessNbr
			, LessonPlanId
			, StudentId
			, StartTs
			, StepVal	
			, Prompt
			, ShortName		
			, StepName
			, StdtSessionDtlId
			, StdtSessionStepId
			, CurrentPrompt
			, ColTypeCd
			, StudentFname
			, StudentLname
			, DSTempHdrId
			, LessonPlanName
			, ClassType
			, ChainType
			, SOrder
		)
		SELECT  DISTINCT
			HDR.SessionNbr AS SessNbr
			, HDR.LessonPlanId
			, HDR.StudentId
			, HDR.EndTs
			, DTL.StepVal	
			, LK.LookupName AS Prompt
			, LK.LookupDesc AS ShortName		
			, DSTS.SortOrder AS StepName
			, DTL.StdtSessionDtlId
			, DTL.StdtSessionStepId
			, DTL.CurrentPrompt
			, SCOL.ColTypeCd
			, STD.FirstName
			, STD.LastName
			, HDR.DSTempHdrId 
			, (SELECT DSTemplateName FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS LessonPlanName			
			, @ctype AS ClassType
			, (SELECT ChainType FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS ChainType				
			, LK.SortOrder 
		FROM StdtSessionStep STP
			INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
			INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId
			INNER JOIN LookUp LK ON LK.LookupId= DTL.CurrentPrompt
			INNER JOIN DSTempSetCol AS SCOL ON DTL.DSTempSetColId = SCOL.DSTempSetColId 
			INNER JOIN DSTempSetColCalc AS CALC ON DTL.DSTempSetColId = CALC.DSTempSetColId
			LEFT JOIN DSTempStep DSTS ON DSTS.DSTempStepId = STP.DSTempStepId
			INNER JOIN StudentPersonal AS STD ON HDR.StudentId = STD.StudentPersonalId 
			INNER JOIN LessonPlan AS LP ON HDR.LessonPlanId = LP.LessonPlanId 
			INNER JOIN Class AS CLS ON CLS.ClassId = HDR.StdtClassId 
		WHERE HDR.StudentId=@StudentId 
		      AND HDR.LessonPlanId=@LessonPlanId 
			  AND (HDR.EndTs BETWEEN @SDate AND @EDate)
			  AND dtl.SessionStatusCd='N' 
			  AND  SCOL.ColTypeCd='Prompt'  
			  AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			  AND DTL.ModifiedOn BETWEEN @SDate AND @EDate
			  AND(SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 and (LessonPlanTypeResi=0 OR LessonPlanTypeResi IS NULL) THEN 'Day' 
		ELSE CASE WHEN (LessonPlanTypeDay=0 OR LessonPlanTypeDay IS NULL) and LessonPlanTypeResi=1 THEN 'Residence' END 
		END  FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClassType
	END

	ELSE IF(@PromptType='Step')
	BEGIN
		INSERT INTO #TEMP(
			SessNbr
			, LessonPlanId
			, StudentId
			, StartTs
			, StepVal	
			, Prompt
			, ShortName		
			, StepName
			, StdtSessionDtlId
			, StdtSessionStepId
			, CurrentPrompt
			, ColTypeCd
			, StudentFname
			, StudentLname
			, DSTempHdrId
			, LessonPlanName
			, ClassType
			, ChainType
			, SOrder
		)
		SELECT  DISTINCT
			HDR.SessionNbr AS SessNbr
			, HDR.LessonPlanId
			, HDR.StudentId
			, HDR.EndTs
			, DTL.StepVal	
			, LK.LookupName AS Prompt
			, LK.LookupDesc AS ShortName		
			, DSTS.SortOrder AS StepName
			, DTL.StdtSessionDtlId
			, DTL.StdtSessionStepId
			, DTL.CurrentPrompt
			, SCOL.ColTypeCd
			, STD.FirstName
			, STD.LastName
			, HDR.DSTempHdrId
			, (SELECT DSTemplateName FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS LessonPlanName				
			, @ctype AS ClassType
			, (SELECT ChainType FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS ChainType				
			, LK.SortOrder 
		FROM StdtSessionStep STP
			INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
			INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId
			INNER JOIN LookUp LK ON cast(LookupId as nvarchar(255))= DTL.StepVal
			INNER JOIN DSTempSetCol AS SCOL ON DTL.DSTempSetColId = SCOL.DSTempSetColId 
			INNER JOIN DSTempSetColCalc AS CALC ON DTL.DSTempSetColId = CALC.DSTempSetColId
			LEFT JOIN DSTempStep DSTS ON DSTS.DSTempStepId = STP.DSTempStepId
			INNER JOIN StudentPersonal AS STD ON HDR.StudentId = STD.StudentPersonalId 
			INNER JOIN LessonPlan AS LP ON HDR.LessonPlanId = LP.LessonPlanId 
			INNER JOIN Class AS CLS ON CLS.ClassId = HDR.StdtClassId 
		WHERE HDR.StudentId=@StudentId 
		      AND HDR.LessonPlanId=@LessonPlanId 
			  AND (HDR.EndTs BETWEEN @SDate AND @EDate)
			  AND dtl.SessionStatusCd='N' 
			  AND  SCOL.ColTypeCd='Prompt' 
			  AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			  AND DTL.ModifiedOn BETWEEN @SDate AND @EDate
			  AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 and (LessonPlanTypeResi=0 OR LessonPlanTypeResi IS NULL) THEN 'Day' 
		ELSE CASE WHEN (LessonPlanTypeDay=0 OR LessonPlanTypeDay IS NULL) and LessonPlanTypeResi=1 THEN 'Residence' END 
		END  FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClassType

	END

	SET @CNT =(SELECT COUNT(RNumber) FROM #TEMP)
	IF (@CNT=0)
	BEGIN

			INSERT INTO #TEMP(
				SessNbr
				, LessonPlanId
				, StudentId
				, StartTs
				, StepVal	
				, Prompt
				, ShortName			
				, StepName
				, StdtSessionDtlId
				, StdtSessionStepId
				, CurrentPrompt
				, ColTypeCd
				, StudentFname
				, StudentLname
				, DSTempHdrId
				, LessonPlanName
				, ClassType
				, ChainType
				, SOrder
			)
			SELECT  DISTINCT
				HDR.SessionNbr AS SessNbr
				, HDR.LessonPlanId
				, HDR.StudentId
				, HDR.EndTs
				, DTL.StepVal	
				, LK.LookupName AS Prompt
				, LK.LookupDesc AS ShortName			
				, DSTS.SortOrder AS StepName
				, DTL.StdtSessionDtlId
				, DTL.StdtSessionStepId
				, DTL.CurrentPrompt
				, SCOL.ColTypeCd	
				, STD.FirstName
				, STD.LastName
				, HDR.DSTempHdrId
				, (SELECT DSTemplateName FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS LessonPlanName				
				, @ctype AS ClassType
				, (SELECT ChainType FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS ChainType 						
				, LK.SortOrder 
			FROM StdtSessionStep STP
				INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
				INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId	
				INNER JOIN DSTempSetCol AS SCOL ON DTL.DSTempSetColId = SCOL.DSTempSetColId 
				INNER JOIN DSTempSetColCalc AS CALC ON DTL.DSTempSetColId = CALC.DSTempSetColId 
				INNER JOIN LookUp LK ON LK.LookupId=HDR.CurrentPromptId
				LEFT JOIN DSTempStep AS DSTS ON DSTS.DSTempStepId = STP.DSTempStepId			
				INNER JOIN StudentPersonal AS STD ON HDR.StudentId = STD.StudentPersonalId 
				INNER JOIN LessonPlan AS LP ON HDR.LessonPlanId = LP.LessonPlanId 
				INNER JOIN Class AS CLS ON CLS.ClassId = HDR.StdtClassId 
			WHERE 
				(HDR.StudentId = @StudentId) 
				AND (HDR.LessonPlanId = @LessonPlanId) 
				AND (HDR.SessMissTrailStus = 'N') 
				AND (HDR.IOAInd = 'N') 
				AND (HDR.SessionStatusCd = 'S') 
				AND (HDR.IsMaintanace = 0) 
				AND (CLS.ActiveInd = 'A') 
				AND (HDR.SchoolId = @SchoolId) AND (HDR.EndTs BETWEEN @SDate AND @EDate)
				AND dtl.SessionStatusCd='N' 
				AND  SCOL.ColTypeCd='+/-' 
				AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			    AND DTL.ModifiedOn BETWEEN @SDate AND @EDate
			    AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 and (LessonPlanTypeResi=0 OR LessonPlanTypeResi IS NULL) THEN 'Day' 
		ELSE CASE WHEN (LessonPlanTypeDay=0 OR LessonPlanTypeDay IS NULL) and LessonPlanTypeResi=1 THEN 'Residence' END 
		END  FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClassType
	END

END

	ELSE IF (@ClassType = 'Day,Residence')
	BEGIN

	IF(@PromptType='Current')
	BEGIN
		INSERT INTO #TEMP(
			SessNbr
			, LessonPlanId
			, StudentId
			, StartTs
			, StepVal	
			, Prompt
			, ShortName		
			, StepName
			, StdtSessionDtlId
			, StdtSessionStepId
			, CurrentPrompt
			, ColTypeCd
			, StudentFname
			, StudentLname
			, DSTempHdrId
			, LessonPlanName
			, ClassType
			, ChainType
			, SOrder
		)
		SELECT  DISTINCT
			HDR.SessionNbr AS SessNbr
			, HDR.LessonPlanId
			, HDR.StudentId
			, HDR.EndTs
			, DTL.StepVal	
			, LK.LookupName AS Prompt
			, LK.LookupDesc AS ShortName		
			, DSTS.SortOrder AS StepName
			, DTL.StdtSessionDtlId
			, DTL.StdtSessionStepId
			, DTL.CurrentPrompt
			, SCOL.ColTypeCd
			, STD.FirstName
			, STD.LastName
			, HDR.DSTempHdrId 
			, (SELECT DSTemplateName FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS LessonPlanName			
			, @ctype AS ClassType
			, (SELECT ChainType FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS ChainType				
			, LK.SortOrder 
		FROM StdtSessionStep STP
			INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
			INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId
			INNER JOIN LookUp LK ON LK.LookupId= DTL.CurrentPrompt
			INNER JOIN DSTempSetCol AS SCOL ON DTL.DSTempSetColId = SCOL.DSTempSetColId 
			INNER JOIN DSTempSetColCalc AS CALC ON DTL.DSTempSetColId = CALC.DSTempSetColId
			LEFT JOIN DSTempStep DSTS ON DSTS.DSTempStepId = STP.DSTempStepId
			INNER JOIN StudentPersonal AS STD ON HDR.StudentId = STD.StudentPersonalId 
			INNER JOIN LessonPlan AS LP ON HDR.LessonPlanId = LP.LessonPlanId 
			INNER JOIN Class AS CLS ON CLS.ClassId = HDR.StdtClassId 
		WHERE HDR.StudentId=@StudentId 
		      AND HDR.LessonPlanId=@LessonPlanId 
			  AND (HDR.EndTs BETWEEN @SDate AND @EDate)
			  AND dtl.SessionStatusCd='N' 
			  AND  SCOL.ColTypeCd='Prompt' 
			  AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			  AND DTL.ModifiedOn BETWEEN @SDate AND @EDate
			  AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 OR LessonPlanTypeResi=1 THEN 'Day,Residence' END  FROM [dbo].[StdtLessonPlan] 
		WHERE LessonPlanId= HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClassType
	END

	ELSE IF(@PromptType='Step')
	BEGIN
		INSERT INTO #TEMP(
			SessNbr
			, LessonPlanId
			, StudentId
			, StartTs
			, StepVal	
			, Prompt
			, ShortName		
			, StepName
			, StdtSessionDtlId
			, StdtSessionStepId
			, CurrentPrompt
			, ColTypeCd
			, StudentFname
			, StudentLname
			, DSTempHdrId
			, LessonPlanName
			, ClassType
			, ChainType
			, SOrder
		)
		SELECT  DISTINCT
			HDR.SessionNbr AS SessNbr
			, HDR.LessonPlanId
			, HDR.StudentId
			, HDR.EndTs
			, DTL.StepVal	
			, LK.LookupName AS Prompt
			, LK.LookupDesc AS ShortName		
			, DSTS.SortOrder AS StepName
			, DTL.StdtSessionDtlId
			, DTL.StdtSessionStepId
			, DTL.CurrentPrompt
			, SCOL.ColTypeCd
			, STD.FirstName
			, STD.LastName
			, HDR.DSTempHdrId
			, (SELECT DSTemplateName FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS LessonPlanName				
			, @ctype AS ClassType
			, (SELECT ChainType FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS ChainType				
			, LK.SortOrder 
		FROM StdtSessionStep STP
			INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
			INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId
			INNER JOIN LookUp LK ON cast(LookupId as nvarchar(255))= DTL.StepVal
			INNER JOIN DSTempSetCol AS SCOL ON DTL.DSTempSetColId = SCOL.DSTempSetColId 
			INNER JOIN DSTempSetColCalc AS CALC ON DTL.DSTempSetColId = CALC.DSTempSetColId
			LEFT JOIN DSTempStep DSTS ON DSTS.DSTempStepId = STP.DSTempStepId
			INNER JOIN StudentPersonal AS STD ON HDR.StudentId = STD.StudentPersonalId 
			INNER JOIN LessonPlan AS LP ON HDR.LessonPlanId = LP.LessonPlanId 
			INNER JOIN Class AS CLS ON CLS.ClassId = HDR.StdtClassId 
		WHERE HDR.StudentId=@StudentId 
		      AND HDR.LessonPlanId=@LessonPlanId 
			  AND (HDR.EndTs BETWEEN @SDate AND @EDate)
			  AND dtl.SessionStatusCd='N' 
			  AND  SCOL.ColTypeCd='Prompt' 
			  AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			  AND DTL.ModifiedOn BETWEEN @SDate AND @EDate
			  AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 OR LessonPlanTypeResi=1 THEN 'Day,Residence' END  FROM [dbo].[StdtLessonPlan] 
		WHERE LessonPlanId= HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClassType

	END

	SET @CNT =(SELECT COUNT(RNumber) FROM #TEMP)
	IF (@CNT=0)
	BEGIN

			INSERT INTO #TEMP(
				SessNbr
				, LessonPlanId
				, StudentId
				, StartTs
				, StepVal	
				, Prompt
				, ShortName			
				, StepName
				, StdtSessionDtlId
				, StdtSessionStepId
				, CurrentPrompt
				, ColTypeCd
				, StudentFname
				, StudentLname
				, DSTempHdrId
				, LessonPlanName
				, ClassType
				, ChainType
				, SOrder
			)
			SELECT  DISTINCT
				HDR.SessionNbr AS SessNbr
				, HDR.LessonPlanId
				, HDR.StudentId
				, HDR.EndTs
				, DTL.StepVal	
				, LK.LookupName AS Prompt
				, LK.LookupDesc AS ShortName			
				, DSTS.SortOrder AS StepName
				, DTL.StdtSessionDtlId
				, DTL.StdtSessionStepId
				, DTL.CurrentPrompt
				, SCOL.ColTypeCd	
				, STD.FirstName
				, STD.LastName
				, HDR.DSTempHdrId
				, (SELECT DSTemplateName FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS LessonPlanName				
				, @ctype AS ClassType
				, (SELECT ChainType FROM DSTempHdr WHERE DSTempHdrId = @DSTempHdrId) AS ChainType 						
				, LK.SortOrder 
			FROM StdtSessionStep STP
				INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
				INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId	
				INNER JOIN DSTempSetCol AS SCOL ON DTL.DSTempSetColId = SCOL.DSTempSetColId 
				INNER JOIN DSTempSetColCalc AS CALC ON DTL.DSTempSetColId = CALC.DSTempSetColId 
				INNER JOIN LookUp LK ON LK.LookupId=HDR.CurrentPromptId
				LEFT JOIN DSTempStep AS DSTS ON DSTS.DSTempStepId = STP.DSTempStepId			
				INNER JOIN StudentPersonal AS STD ON HDR.StudentId = STD.StudentPersonalId 
				INNER JOIN LessonPlan AS LP ON HDR.LessonPlanId = LP.LessonPlanId 
				INNER JOIN Class AS CLS ON CLS.ClassId = HDR.StdtClassId 
			WHERE 
				(HDR.StudentId = @StudentId) 
				AND (HDR.LessonPlanId = @LessonPlanId) 
				AND (HDR.SessMissTrailStus = 'N') 
				AND (HDR.IOAInd = 'N') 
				AND (HDR.SessionStatusCd = 'S') 
				AND (HDR.IsMaintanace = 0) 
				AND (CLS.ActiveInd = 'A') 
				AND (HDR.SchoolId = @SchoolId) 
				AND (HDR.EndTs BETWEEN @SDate AND @EDate)
				AND dtl.SessionStatusCd='N' 
				AND  SCOL.ColTypeCd='+/-' 
				AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			    AND DTL.ModifiedOn BETWEEN @SDate AND @EDate
			    AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 OR LessonPlanTypeResi=1 THEN 'Day,Residence' END  FROM [dbo].[StdtLessonPlan] 
		WHERE LessonPlanId= HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClassType
	END

END

---------------------------UPDATE COLOR-------------------------------

CREATE TABLE #COLOR (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), Prompt VARCHAR(250), SortOrder INT)
INSERT INTO #COLOR SELECT DISTINCT Prompt, SOrder FROM #TEMP ORDER BY SOrder
SET @CNT=(SELECT COUNT(ID) FROM #COLOR)
SET @cntc=@CNT

IF (@CNT > 0)
BEGIN
	SET @DIFF=ROUND((44/@CNT),2)
	SET @ID=1

	WHILE(@CNT>0)
	BEGIN
		SET @SOrdr=(SELECT SortOrder FROM #COLOR WHERE ID=@ID)
		SET @CSOrder=((@DIFF * (@ID - 1)) +1)
		IF(@ID=@cntc)
		BEGIN
		SET @CSOrder=44
		END
		SET @COLOR=(SELECT LookupName FROM LookUp WHERE LookupType='Color-Code' AND SortOrder=@CSOrder)
		UPDATE #TEMP SET Color=@COLOR WHERE SOrder=@SOrdr
		SET @ID=@ID+1
		SET @CNT=@CNT-1
	END
END
DROP TABLE #COLOR


------------------------------------END UPDATE COLOR-------------------------------------------------


IF OBJECT_ID('tempdb..#STEP') IS NOT NULL  
DROP TABLE #STEP

CREATE TABLE #STEP (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), SNbr INT, CStep INT, HdrId int)

CREATE NONCLUSTERED INDEX IX_STEP_HdrId ON #STEP (HdrId);

INSERT INTO #STEP SELECT SessionNbr, CurrentStepId, DSTempHdrId 
	   FROM StdtSessionHdr 
	   WHERE StudentId=@StudentId and LessonPlanId=@LessonPlanId and (DSTempHdrId IS NOT NULL )
	   AND EndTs BETWEEN @SDate AND @EDate order by StdtSessionHdrId asc

SET @CNT= (SELECT COUNT(ID) FROM #STEP)
SET @RCNT=1
SET @Step=(SELECT CStep FROM #STEP WHERE ID=@RCNT)
set @HdrId=(select HdrId from #STEP WHERE ID=@RCNT)
WHILE (@CNT>0)
BEGIN
	SET @CStep=(SELECT CStep FROM #STEP WHERE ID=@RCNT)
	IF(@Step!=@CStep)	
	BEGIN
		SET @SessNbr=(SELECT SNbr FROM #STEP WHERE ID=@RCNT)		
		UPDATE #TEMP SET EventName=(SELECT top 1 EventName FROM StdtSessEvent WHERE SessionNbr=@SessNbr-1 AND LessonPlanId=@LessonPlanId AND StudentId=@StudentId AND discardstatus is NULL 
			AND EvntTs BETWEEN @SDate AND @EDate and (DSTempHdrId IS NOT NULL)), Offset=(SELECT top 1 SessionNbr + 1 FROM StdtSessEvent 
				WHERE SessionNbr=@SessNbr-1 AND LessonPlanId=@LessonPlanId AND StudentId=@StudentId AND discardstatus is NULL AND EvntTs BETWEEN @SDate AND @EDate and (DSTempHdrId IS NOT NULL)) 
			WHERE SessNbr=@SessNbr and (DSTempHdrId IS NOT NULL )

		-------------------------- FOR SET EVENT (OV)-----------------------------
		SET @EVNT=(SELECT top 1 EventName FROM StdtSessEvent WHERE SessionNbr=@SessNbr AND LessonPlanId=@LessonPlanId AND StudentId=@StudentId AND discardstatus is NULL 
			AND EvntTs BETWEEN @SDate AND @EDate and (DSTempHdrId IS NOT NULL))

		IF(@EVNT LIKE '%(OV)') 
			UPDATE #TEMP SET EventName=@EVNT, Offset=(SELECT top 1 SessionNbr FROM StdtSessEvent WHERE SessionNbr=@SessNbr AND LessonPlanId=@LessonPlanId 
				AND StudentId=@StudentId AND discardstatus is NULL AND EvntTs BETWEEN @SDate AND @EDate and (DSTempHdrId IS NOT NULL)) 
				WHERE SessNbr=@SessNbr and (DSTempHdrId IS NOT NULL )		
		SET @Step=@CStep		
	END
	------------------------LP Modified-------------------------------
	SET @CHdrId=(SELECT HdrId FROM #STEP WHERE ID=@RCNT)
	IF(@HdrId!=@CHdrId)	
	BEGIN
		SET @SessNbr=(SELECT SNbr FROM #STEP WHERE ID=@RCNT)		
		UPDATE #TEMP SET EventName=(SELECT top 1 EventName FROM StdtSessEvent WHERE SessionNbr=@SessNbr-1 AND LessonPlanId=@LessonPlanId AND StudentId=@StudentId AND discardstatus is NULL 
			AND EvntTs BETWEEN @SDate AND @EDate and (DSTempHdrId IS NOT NULL )), Offset=@SessNbr WHERE SessNbr=@SessNbr and (DSTempHdrId IS NOT NULL )
		SET @HdrId=@CHdrId		
	END

	SET @RCNT=@RCNT+1
	SET @CNT=@CNT-1
END

DROP TABLE #STEP

--------------------------END UPDATE EVENT----------------------------

--------------INSERT OFFSET AND SESSNBR TO ALL OTHER STEPS-------------
IF OBJECT_ID('tempdb..#OFFSET') IS NOT NULL  
DROP TABLE #OFFSET
CREATE TABLE #OFFSET (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), OffSet INT)
INSERT INTO #OFFSET SELECT DISTINCT Offset FROM #TEMP WHERE Offset>0



---------------------------insert OFFSET AND SESSNBR to all step from 1 to max-------------

SET @Coff=(SELECT COUNT(ID) FROM #OFFSET)
SET @CNT=1
WHILE(@Coff>0)
BEGIN
	SET @SessNbr=(SELECT OffSet FROM #OFFSET WHERE ID= @CNT)

	SET @CStep=(SELECT MAX(SortOrder) FROM DSTempStep DS INNER JOIN StdtSessionStep STP ON DS.DSTempStepId=STP.DSTempStepId 
		INNER JOIN StdtSessionHdr HDR ON HDR.StdtSessionHdrId=STP.StdtSessionHdrId
		INNER JOIN StdtSessionDtl DTL ON DTL.StdtSessionStepId=STP.StdtSessionStepId
		WHERE HDR.LessonPlanId=@LessonPlanId 
		      AND HDR.StudentId=@StudentId 
			  AND (HDR.EndTs BETWEEN @SDate AND @EDate)
			  AND STP.ModifiedOn BETWEEN @SDate AND @EDate
			  AND DTL.ModifiedOn BETWEEN @SDate AND @EDate)
			  
	SET @RCNT=1
	WHILE(@CStep>0)
	BEGIN
		SET @Step=@RCNT
		INSERT INTO #TEMP(StepName,Offset) VALUES(@Step,@SessNbr)
		SET @RCNT=@RCNT+1
		SET @CStep=@CStep-1
	END
	SET @CNT=@CNT+1
	SET @Coff=@Coff-1
END

DROP TABLE #OFFSET

-------------------------------UPDATE LAST STEP WITH EVENT NAME----------------------------
IF OBJECT_ID('tempdb..#OFFSETS') IS NOT NULL  
DROP TABLE #OFFSETS
CREATE TABLE #OFFSETS (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), OffSet INT,EventName NVARCHAR(MAX))
INSERT INTO #OFFSETS SELECT DISTINCT Offset,EventName FROM #TEMP WHERE Offset>0 AND EventName IS NOT NULL

UPDATE #TEMP SET EventName = NULL
SET @Step=(SELECT MAX(StepName) FROM #TEMP)
SET @CNT=1
SET @Coff=(SELECT COUNT(ID) FROM #OFFSETS)
WHILE(@Coff>0)
BEGIN
	UPDATE #TEMP SET EventName=(SELECT EventName FROM #OFFSETS WHERE ID=@CNT) WHERE StepName=@Step AND Offset=(SELECT OffSet FROM #OFFSETS WHERE ID=@CNT)
		AND SessNbr IS NULL
	SET @CNT=@CNT+1
	SET @Coff=@Coff-1
END
DROP TABLE #OFFSETS

---------------------------Update #TEMP with EventName LP Modified-----------------------------------------

SET @Step=(SELECT MAX(StepName) FROM #TEMP)
UPDATE #TEMP SET EventName='LP modified' WHERE StepName=@Step AND EventName IS NULL AND SessNbr IS NULL


---------------------------Update StepName(SortOrder) in #TEMP with Row Number Start-----------------------------------------

		IF OBJECT_ID('tempdb..#Temprank') IS NOT NULL
		DROP TABLE #Temprank

		CREATE TABLE #Temprank(SortOrder int ,Ranks int)
		INSERT INTO #Temprank 
		SELECT sortorder,ROW_NUMBER() OVER (ORDER BY SortOrder)
		FROM  DSTempParentStep 
		WHERE DSTempParentStepId IN (SELECT DSTempParentStepId FROM DSTempStep WHERE DSTempHdrId=@DSTempHdrId AND ActiveInd = 'A') 
		      AND DSTempHdrId=@DSTempHdrId and ActiveInd='A'

		UPDATE #TEMP
		SET #TEMP.StepName = #Temprank.Ranks
		FROM #TEMP
		JOIN #Temprank
		ON #TEMP.StepName = #Temprank.SortOrder

---------------------------Update StepName(SortOrder) in #TEMP with Row Number End-----------------------------------------

        SELECT RNumber,SessNbr,LessonPlanId,StudentId,StartTs,StepVal,Prompt,ShortName,StepName,StdtSessionDtlId,StdtSessionStepId,CurrentPrompt,ColTypeCd, 
	           StudentLname+', '+StudentFname as StudentName,DSTempHdrId,LessonPlanName,ClassType,ChainType,EventName,SOrder,Color,Offset
			   , (SELECT TOP 1 ('Tx: ' + (SELECT LookupName FROM LookUp WHERE LookupId= [TeachingProcId]) + ';' + (SELECT LookupName FROM LookUp WHERE LookupId= [PromptTypeId]))
			    Treatment FROM DSTempHdr  HDR left join lookup lp on HDR.StatusId=Lp.LookupId 
				WHERE HDR.LessonPlanId= @LessonPlanId AND HDR.StudentId= @StudentId AND LookupName in ('Approved','Expired','Deleted','Inactive','Maintenance') 
				and LookupType='TemplateStatus'ORDER BY DSTempHdrId DESC) Treatment

			, (SELECT TOP 1 'Correct Response: '+StudCorrRespDef FROM DSTempHdr HDR Left join LookUp lp on HDR.StatusId=lp.LookupId
			    WHERE HDR.LessonPlanId= @LessonPlanId AND HDR.StudentId= @StudentId AND StudCorrRespDef<>'' AND 
				 LookupType='TemplateStatus' AND LookupName in('Approved','Expired','Deleted','Inactive','Maintenance')				
				ORDER BY DSTempHdrId DESC) Deftn
FROM #TEMP 
order by RNumber

END
GO
