USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[BiweeklySessionReport_Backup]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[BiweeklySessionReport_Backup]
@StartDate datetime,
@EndDate datetime,
@StudentId int,
@LessonPlan varchar(5000),
@SchoolId int
--@Events varchar(50),
--@IncludeIOA varchar(50),
--@IncludeTrend varchar(50)


AS
BEGIN
	
	SET NOCOUNT ON;



	Declare @SDate datetime
	,@EDate datetime
	,@Sid int
	,@LessonId varchar(250)
	,@School int
	,@Datestart datetime
	,@Dateend datetime
	,@CNT int
	,@Rowcnt int
	,@Totalcnt int
	,@TMPCount int
	,@calctype varchar(50)
	,@DSTempSetColCalcId int 
	,@TMPLoopCount int
	,@LPid int
	,@LPold int
	,@calctypeOld varchar(50)
	,@ColnameOld VARCHAR(500)
	,@Colname VARCHAR(500)
	


	SET @SDate=@StartDate
	SET @EDate=@EndDate
	SET @Sid=@StudentId
	SET @LessonId=@LessonPlan
	SET @School=@SchoolId
	

	IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL  
	DROP TABLE #TEMP


	CREATE TABLE #TEMP(ID int PRIMARY KEY NOT NULL IDENTITY(1,1),LessonPlanid int,CalcType varchar(50),classtype varchar(50),DSTempSetColCalcId int
	,ClassNameType varchar(50));

	INSERT INTO #TEMP
	SELECT DISTINCT LessonPlanId,CalcType,ResidenceInd,DSTempSetColCalcId,ClassType FROM
	(SELECT  CONVERT(DATE,HDR.StartTs) AS STARTDATE
	,ROW_NUMBER() OVER (PARTITION BY CONVERT(DATE,HDR.StartTs),CAL.CalcType ORDER BY HDR.StdtSessionHdrId) AS RowNumber
	,CAL.CalcType
	,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
	'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=
	 HDR.LessonPlanId AND StudentId=@Sid AND SchoolId=@School ORDER BY StdtLessonPlanId DESC) AS ResidenceInd 
	,HDR.LessonPlanId
	,CAL.DSTempSetColCalcId	
	,CASE WHEN CLS.ResidenceInd=1 THEN 'Residence' ELSE  'Day' END AS ClassType
	FROM StdtSessionHdr HDR 
	INNER JOIN StdtSessColScore CSR 
	ON HDR.StdtSessionHdrId=CSR.StdtSessionHdrId 
	INNER JOIN DSTempSetColCalc CAL 
	ON CSR.DSTempSetColCalcId=CAL.DSTempSetColCalcId
	INNER JOIN Class CLS 
	ON CLS.ClassId=HDR.StdtClassId 
	WHERE HDR.IOAInd='N' 
	AND HDR.SessMissTrailStus ='N' 
	AND HDR.SessionStatusCd='S'
	--AND HDR.IsMaintanace=0
	AND CONVERT(DATE,HDR.StartTs) BETWEEN @SDate AND @EDate
	AND HDR.StudentId=@Sid
	AND HDR.LessonPlanId IN (SELECT * FROM Split(@LessonId,','))
	AND HDR.SchoolId=@School
	AND (CAL.IncludeInGraph <>0)
	--AND CAL.IncludeInGraph = '1'
	--AND (CAL.CalcType<>'Total Correct' AND CAL.CalcType<>'Total Incorrect')
	) SESSIONDATA ORDER BY LessonPlanId


	

	
	CREATE TABLE #TEMP1(Scoreid int NOT NULL PRIMARY KEY IDENTITY(1,1),SessionDate datetime,Rownum int,StartTs datetime,CalcType varchar(50),ClassType varchar(50),Score float,LessonPlanId int,LessonPlanName varchar(500)
	,IOAPerc varchar(50),ArrowNote varchar(500),EventType varchar(50),EventName varchar(500),EvntTs datetime,EndTime datetime,Comment varchar(500),StudentName varchar(200)
	,PromptCnt int,DSTempSetColCalcId int,ClassNameType varchar(50));
	
	SET @Totalcnt=(SELECT COUNT(*) FROM #TEMP)	
	SET @Rowcnt=1
	WHILE(@Totalcnt>0)
	BEGIN

	SET @Datestart=@SDate
	SET @Dateend=@EDate

	WHILE(@Datestart<=@Dateend)
	BEGIN

	SET @calctype=(SELECT CalcType FROM #TEMP WHERE ID=@Rowcnt)
	SET @DSTempSetColCalcId=(SELECT DSTempSetColCalcId FROM #TEMP WHERE ID=@Rowcnt)
	SET @CNT=(SELECT COUNT(*) FROM (SELECT  CONVERT(DATE,HDR.StartTs) AS STARTDATE	
	FROM StdtSessionHdr HDR 
	INNER JOIN StdtSessColScore CSR 
	ON HDR.StdtSessionHdrId=CSR.StdtSessionHdrId 
	INNER JOIN DSTempSetColCalc CAL 
	ON CSR.DSTempSetColCalcId=CAL.DSTempSetColCalcId
	INNER JOIN Class CLS 
	ON CLS.ClassId=HDR.StdtClassId 
	WHERE HDR.IOAInd='N' 
	AND HDR.SessMissTrailStus ='N'
	AND HDR.SessionStatusCd='S'
	--AND HDR.IsMaintanace=0
	AND CONVERT(DATE,HDR.StartTs) =CONVERT(DATE,@Datestart)
	AND HDR.StudentId=@Sid
	AND HDR.LessonPlanId = (SELECT LessonPlanid FROM #TEMP WHERE ID=@Rowcnt)
	AND HDR.SchoolId=@School
	AND CAL.DSTempSetColCalcId=@DSTempSetColCalcId
	--AND CLS.ResidenceInd=(SELECT ResidenceInd FROM #TEMP WHERE ID=@Rowcnt)
	) DATA )

	IF(@CNT>0)
	BEGIN

	INSERT INTO #TEMP1
	SELECT CONVERT(DATE,HDER.StartTs) AS STARTDATE
	,ROW_NUMBER() OVER (PARTITION BY CONVERT(DATE,HDER.StartTs),@calctype ORDER BY HDER.StdtSessionHdrId) AS RowNumber
	,HDER.StartTs
	,@calctype
	,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
	'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=
	HDER.LessonPlanId AND StudentId=@Sid AND SchoolId=@School ORDER BY StdtLessonPlanId DESC) AS Residence 
	,COLSCORE.Score
	,HDER.LessonPlanId
	,NULL LessonName
	,CASE WHEN COLSCORE.IOAPERC IS NOT NULL THEN 'IOA '+COLSCORE.IOAPERC+' %' ELSE NULL END IOAPERCENTAGE,NULL ANOTE,NULL ETYPE,NULL ENAME
	,NULL EVNTTS,NULL ENDTIME,NULL COMMENT,NULL SNAME,NULL PCNT,@DSTempSetColCalcId
	,CASE WHEN CLS.ResidenceInd=1 THEN 'Residence' ELSE  'Day' END AS ClassNameType
	FROM (SELECT HDR.StdtSessionHdrId, (SELECT IOAPerc FROM StdtSessionHdr WHERE IOASessionHdrId=HDR.StdtSessionHdrId) IOAPERC,CASE WHEN (SELECT COUNT(StdtSessionHdrId) FROM 
	StdtSessColScore CSR INNER JOIN DSTempSetColCalc CAL 
	ON CSR.DSTempSetColCalcId=CAL.DSTempSetColCalcId WHERE StdtSessionHdrId=HDR.StdtSessionHdrId
	AND CAL.CalcType=@calctype)>1 THEN (SELECT AVG(CSR.Score) FROM 
	StdtSessColScore CSR INNER JOIN DSTempSetColCalc CAL 
	ON CSR.DSTempSetColCalcId=CAL.DSTempSetColCalcId WHERE StdtSessionHdrId=HDR.StdtSessionHdrId
	AND CAL.CalcType=@calctype AND CSR.Score>=0) ELSE (SELECT CSR.Score FROM 
	StdtSessColScore CSR INNER JOIN DSTempSetColCalc CAL 
	ON CSR.DSTempSetColCalcId=CAL.DSTempSetColCalcId WHERE StdtSessionHdrId=HDR.StdtSessionHdrId
	AND CAL.CalcType=@calctype AND CSR.Score>=0) END AS Score FROM StdtSessionHdr HDR  WHERE HDR.IOAInd='N' 
	AND HDR.SessMissTrailStus ='N' 
	AND HDR.SessionStatusCd='S'
	--AND HDR.IsMaintanace=0
	AND CONVERT(DATE,HDR.StartTs) =CONVERT(DATE,@Datestart)
	AND HDR.StudentId=@Sid
	AND HDR.LessonPlanId = (SELECT LessonPlanid FROM #TEMP WHERE ID=@Rowcnt)
	AND HDR.SchoolId=@School
	GROUP BY HDR.StdtSessionHdrId) COLSCORE
	INNER JOIN StdtSessionHdr HDER ON HDER.StdtSessionHdrId=COLSCORE.StdtSessionHdrId
	INNER JOIN Class CLS 
	ON CLS.ClassId=HDER.StdtClassId 
	--WHERE CLS.ResidenceInd=(SELECT ResidenceInd FROM #TEMP WHERE ID=@Rowcnt)
	

	END
	ELSE
	BEGIN
	INSERT INTO #TEMP1 SELECT CONVERT(DATE,@Datestart),NULL,CONVERT(datetime,@Datestart),CalcType,
	classtype AS ClassType,NULL,LessonPlanid,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,DSTempSetColCalcId,ClassNameType FROM #TEMP WHERE ID=@Rowcnt
	END

	SET @Datestart=DATEADD(DAY,1,@Datestart)
	END

	SET @Rowcnt=@Rowcnt+1
	SET @Totalcnt=@Totalcnt-1
	END
	
	SET @TMPCount = (SELECT COUNT(*) FROM #TEMP)
	WHILE(@TMPCount>0)
	BEGIN
	UPDATE #TEMP1 SET --LessonPlanName=(SELECT LessonPlanName FROM LessonPlan WHERE LessonPlanId=(SELECT LessonPlanId FROM #TEMP WHERE ID=@TMPCount))
	LessonPlanName= (CASE WHEN (SELECT DSH.DSTemplateName FROM DSTempHdr DSH INNER JOIN LessonPlan DLP ON DSH.LessonPlanId = DLP.LessonPlanId WHERE StatusId =
  (SELECT LookupId FROM LookUp WHERE LookupType = 'TemplateStatus' AND LookupName = 'Inactive') AND DSTempHdrId = (SELECT TOP 1 DSTempHdrId FROM DSTempHdr 
  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TEMP WHERE ID=@TMPCount) AND StudentId=@Sid ORDER BY DSTempHdrId DESC) AND 
  DSMode = 'INACTIVE' ) IS NULL THEN (SELECT DSH.DSTemplateName FROM DSTempHdr DSH INNER JOIN LessonPlan DLP ON DSH.LessonPlanId = DLP.LessonPlanId 
  AND DSTempHdrId = (SELECT TOP 1 DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=(SELECT LessonPlanId FROM #TEMP WHERE ID=@TMPCount) AND StudentId=@Sid 
  ORDER BY DSTempHdrId DESC)) ELSE (SELECT DSH.DSTemplateName FROM DSTempHdr DSH INNER JOIN LessonPlan DLP ON DSH.LessonPlanId = DLP.LessonPlanId 
  AND DSTempHdrId = (SELECT TOP 1 DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=(SELECT LessonPlanId FROM #TEMP WHERE ID=@TMPCount) AND StudentId=@Sid 
  ORDER BY DSTempHdrId DESC)) + ' (Inactive)' END) 
	,StudentName=(SELECT StudentLname+','+StudentFname AS SName FROM Student WHERE StudentId=@Sid)	
	WHERE LessonPlanId=(SELECT LessonPlanId FROM #TEMP WHERE ID=@TMPCount)
	SET @TMPCount=@TMPCount-1
	END

	

	DROP TABLE #TEMP


	ALTER TABLE #TEMP1 ADD DummyScore float NULL,LeftYaxis varchar(500) NULL, RightYaxis varchar(500) NULL,PromptCount int NULL,
	NonPercntCount int NULL,PercntCount int NULL,ColName varchar(200) NULL,RptLabel varchar(200) NULL,Color varchar(50),Shape varchar(50);
	UPDATE #TEMP1 SET RptLabel=(SELECT CASE WHEN [CalcRptLabel]='' THEN [CalcType] ELSE [CalcRptLabel] END AS [CalcRptLabel] FROM 
	[dbo].[DSTempSetColCalc] WHERE [DSTempSetColCalcId]=#TEMP1.DsTempSetColCalcId)


	CREATE TABLE #DURATN(ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),Score FLOAT,LessonPlanId INT,DsTempSetColCalcId INT)

	INSERT INTO #DURATN
	SELECT MAX(ISNULL(Score,-1)),LessonPlanId,DsTempSetColCalcId FROM #TEMP1 WHERE CalcType IN ('Total Duration','Avg Duration') GROUP BY LessonPlanId,DsTempSetColCalcId
	
	SET @TMPCount=(SELECT COUNT(*) FROM #DURATN)
		SET @TMPLoopCount=1
		WHILE(@TMPCount>0)
		BEGIN
		IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)<>-1)
		BEGIN
		IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)<60)
		BEGIN
		UPDATE #TEMP1 SET RptLabel=RptLabel+' (In Seconds)' WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
		AND DsTempSetColCalcId=(SELECT DsTempSetColCalcId FROM #DURATN WHERE ID=@TMPLoopCount)
		END
		ELSE IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)<3600)
		BEGIN
		UPDATE #TEMP1 SET RptLabel=RptLabel+' (In Minutes)' WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
		AND DsTempSetColCalcId=(SELECT DsTempSetColCalcId FROM #DURATN WHERE ID=@TMPLoopCount)
		UPDATE #TEMP1 SET Score=Score/60 WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
		AND DsTempSetColCalcId=(SELECT DsTempSetColCalcId FROM #DURATN WHERE ID=@TMPLoopCount)
		END
		ELSE IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)>=3600)
		BEGIN
		UPDATE #TEMP1 SET RptLabel=RptLabel+' (In Hours)' WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
		AND DsTempSetColCalcId=(SELECT DsTempSetColCalcId FROM #DURATN WHERE ID=@TMPLoopCount)
		UPDATE #TEMP1 SET Score=Score/3600 WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
		AND DsTempSetColCalcId=(SELECT DsTempSetColCalcId FROM #DURATN WHERE ID=@TMPLoopCount)
		END
		END
		SET @TMPLoopCount=@TMPLoopCount+1
		SET @TMPCount=@TMPCount-1
		END
	
	DROP TABLE #DURATN

	----///////////////////NEW CHANGE FOR TWO Y AXIS/////////////////////
		
		
		CREATE TABLE #TMPLP(ID int NOT NULL IDENTITY(1,1),LessonPlanId int,CalcType varchar(50));
		INSERT INTO #TMPLP SELECT DISTINCT LessonPlanId,CalcType FROM #TEMP1
		CREATE TABLE #TMPLPCNT(ID int NOT NULL IDENTITY(1,1),LessonPlanId int,CalcTypeCNT INT);
		INSERT INTO #TMPLPCNT SELECT LessonPlanId,COUNT(1) AS CNT FROM #TMPLP GROUP BY LessonPlanId

		SET @TMPCount=(SELECT COUNT(*) FROM #TMPLPCNT)
		SET @TMPLoopCount=1
		WHILE(@TMPCount>0)
		BEGIN
		IF((SELECT CalcTypeCNT FROM #TMPLPCNT WHERE ID=@TMPLoopCount)>2)
		BEGIN
		IF((SELECT COUNT(*) FROM #TEMP1 WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>0)
		BEGIN
	
	UPDATE #TEMP1 SET DummyScore=Score WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)

	UPDATE #TEMP1 SET Score = NULL WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)

	UPDATE #TEMP1 SET LeftYaxis=(SELECT STUFF((SELECT '/ '+ RptLabel FROM (SELECT DISTINCT RptLabel FROM #TEMP1 TMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize','Event') AND TMP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND (SELECT COUNT(*) FROM #TEMP1 TP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND TP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>0) LP FOR XML PATH('')),1,1,'')) 
	WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)

	UPDATE #TEMP1 SET RightYaxis=(SELECT STUFF((SELECT '/ '+ RptLabel FROM (SELECT DISTINCT RptLabel FROM #TEMP1 TMP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND TMP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND (SELECT COUNT(*) FROM #TEMP1 TP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND TP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>0) LP FOR XML PATH('')),1,1,''))
	WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
	
	UPDATE #TEMP1 SET LeftYaxis=(CASE WHEN LeftYaxis IS NULL THEN RightYaxis ELSE LeftYaxis END )  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
	UPDATE #TEMP1 SET RightYaxis=(CASE WHEN LeftYaxis=RightYaxis THEN NULL ELSE RightYaxis END )  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
	
	IF((SELECT COUNT(*) FROM #TEMP1 WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>=2)
	BEGIN
	UPDATE #TEMP1 SET LeftYaxis='Percent'  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
	END
		END
		END
		ELSE
		BEGIN
		IF((SELECT CalcTypeCNT FROM #TMPLPCNT WHERE ID=@TMPLoopCount)=2)
		BEGIN
		UPDATE #TEMP1 SET DummyScore=Score WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) ORDER BY ID DESC) 		
		AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
		UPDATE #TEMP1 SET Score = NULL WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) ORDER BY ID DESC) 
		AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
		UPDATE #TEMP1 SET LeftYaxis=(SELECT TOP 1 RptLabel FROM #TEMP1 WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE 
		LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) ORDER BY ID DESC) AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)) 
		WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
		
		UPDATE #TEMP1 SET RightYaxis=(SELECT TOP 1 RptLabel FROM #TEMP1 WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE 
		LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) ORDER BY ID ) AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)) 
		WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)

		END

		ELSE
		BEGIN
		UPDATE #TEMP1 SET LeftYaxis=(SELECT TOP 1 RptLabel FROM #TEMP1 WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE 
		LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) )) 
		WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) 
		
		END
		END
		SET @TMPLoopCount=@TMPLoopCount+1
		SET @TMPCount=@TMPCount-1
		END

		DROP TABLE #TMPLPCNT
		DROP TABLE #TMPLP
--/////////////////////////////////////////////////////////////////

	
	
	UPDATE #TEMP1 SET PromptCount=(SELECT COUNT(*) FROM DSTempPrompt WHERE DSTempHdrId= (SELECT [DSTempHdrId] FROM [dbo].[DSTempSetCol] WHERE 
	[DSTempSetColId]=(SELECT [DSTempSetColId] FROM [dbo].[DSTempSetColCalc] WHERE [DSTempSetColCalcId]=#TEMP1.DsTempSetColCalcId)))
	

	
	UPDATE #TEMP1  SET NonPercntCount=(SELECT COUNT(DISTINCT CalcType) FROM #TEMP1 TMP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND TMP.LessonPlanId=#TEMP1.LessonPlanId)

	
	UPDATE #TEMP1 SET PercntCount=(SELECT COUNT(DISTINCT CalcType) FROM #TEMP1 TMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize','Event') AND TMP.LessonPlanId=#TEMP1.LessonPlanId)

	
	UPDATE #TEMP1 SET ColName=(SELECT [ColName] FROM [dbo].[DSTempSetCol] WHERE [DSTempSetColId]=(SELECT [DSTempSetColId] FROM [dbo].[DSTempSetColCalc] WHERE [DSTempSetColCalcId]=#TEMP1.DsTempSetColCalcId))

	UPDATE #TEMP1 SET ClassType=CASE WHEN ClassType='Day,Residence' THEN ClassNameType ELSE ClassType END 

	
	------------- Coloring Fix start---------------------

	--SET @Cnt=(SELECT COUNT(*) FROM #TEMP)
	SET @TMPCount=1
	SET @Totalcnt=0

	CREATE TABLE #COLORING (ID INT NOT NULL PRIMARY KEY IDENTITY

(1,1),DsTempSetColCalcId INT);
	INSERT INTO #COLORING
	SELECT DISTINCT DsTempSetColCalcId  FROM #TEMP1 

	DECLARE db_cursor CURSOR FOR  
	SELECT DsTempSetColCalcId FROM #COLORING 

	OPEN db_cursor   
	FETCH NEXT FROM db_cursor INTO @Totalcnt   

WHILE @@FETCH_STATUS = 0   
BEGIN 
--SELECT @CNTLP
	UPDATE #TEMP1 SET Color=(SELECT ColorCode FROM Color WHERE 

ColorId=@TMPCount),Shape=(SELECT Shape FROM Color WHERE ColorId=@TMPCount) WHERE 

DsTempSetColCalcId=@Totalcnt
	SET @TMPCount=@TMPCount+1
        

       FETCH NEXT FROM db_cursor INTO @Totalcnt   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor


DROP TABLE #COLORING


------------------- Coloring fix end ------------------------

	--SET @CNT=(SELECT COUNT(*) FROM #TEMP1)
	--SET @TMPCount=1
	--SET @Totalcnt=1
	--WHILE(@CNT>0)
	--BEGIN
	--SET @LPid=(SELECT LessonPlanId FROM #TEMP1 WHERE Scoreid=@Totalcnt)
	--SET @LPold=(SELECT LessonPlanId FROM #TEMP1 WHERE Scoreid=(@Totalcnt-1))
	--SET @calctype=(SELECT CalcType FROM #TEMP1 WHERE Scoreid=@Totalcnt)
	--SET @calctypeOld=(SELECT CalcType FROM #TEMP1 WHERE Scoreid=(@Totalcnt-1))	
	--SET @Colname=(SELECT ColName FROM #TEMP1 WHERE Scoreid=@Totalcnt)
	--SET @ColnameOld=(SELECT ColName FROM #TEMP1 WHERE Scoreid=(@Totalcnt-1))	

	--IF((@LPid<>@LPold) OR (@calctype<>@calctypeOld) OR (@Colname<>@ColnameOld))
	--BEGIN
	--SET @TMPCount=@TMPCount+1
	--END
	--UPDATE #TEMP1 SET Color=(SELECT ColorCode FROM Color WHERE ColorId=@TMPCount),Shape=(SELECT Shape FROM Color WHERE ColorId=@TMPCount) WHERE Scoreid=@Totalcnt
	--SET @CNT=@CNT-1
	--SET @Totalcnt=@Totalcnt+1
	--END
	SELECT *,(SELECT TOP 1 ('Tx: ' + (SELECT LookupName FROM LookUp WHERE LookupId= [TeachingProcId]) + ';' + (SELECT LookupName FROM LookUp WHERE LookupId= [PromptTypeId])) Treatment FROM DSTempHdr  HDR
WHERE LessonPlanId=#TEMP1.LessonPlanId AND StudentId=@Sid 
AND StatusId IN ((SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Approved'),
(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Expired'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Deleted'),
(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Inactive'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Maintenance'))
ORDER BY DSTempHdrId DESC) Treatment
,(SELECT TOP 1 'Correct Response: '+StudCorrRespDef FROM DSTempHdr WHERE LessonPlanId=#TEMP1.LessonPlanId AND StudentId=@Sid AND StudCorrRespDef<>'' AND
 StatusId IN ((SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Approved'),
(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Expired'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Deleted'),
(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Inactive'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Maintenance'))
ORDER BY DSTempHdrId DESC) Deftn FROM #TEMP1
--	SELECT *,(SELECT TOP 1 ('Tx: ' + (SELECT LookupName FROM LookUp WHERE LookupId= [TeachingProcId]) + ';' + (SELECT LookupName FROM LookUp WHERE LookupId= [PromptTypeId])) Treatment FROM DSTempHdr  HDR
--WHERE LessonPlanId=MAINTBL.LessonPlanId AND StudentId=@Sid 
--AND StatusId IN ((SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Approved'),
--(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Expired'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Deleted'),
--(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Inactive'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Maintenance'))
--ORDER BY DSTempHdrId DESC) Treatment
--,(SELECT TOP 1 'Correct Response: '+StudCorrRespDef FROM DSTempHdr WHERE LessonPlanId=MAINTBL.LessonPlanId AND StudentId=@Sid AND StudCorrRespDef<>'' AND
-- StatusId IN ((SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Approved'),
--(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Expired'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Deleted'),
--(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Inactive'),(SELECT LookupId FROM LookUp WHERE LookupType='TemplateStatus' AND LookupName='Maintenance'))
--ORDER BY DSTempHdrId DESC) Deftn FROM (SELECT *,s_index = ROW_NUMBER() OVER(PARTITION BY DsTempSetColCalcId,SessionDate ORDER BY DsTempSetColCalcId,SessionDate) 
--	FROM (SELECT DISTINCT SessionDate,Rownum,StartTs,CalcType,ClassType,Score,LessonPlanId,LessonPlanName,IOAPerc,ArrowNote,EventType,EventName,EvntTs,EndTime,
--	Comment,StudentName,PromptCnt,DSTempSetColCalcId,ClassNameType,DummyScore,LeftYaxis, RightYaxis,PromptCount,
--	NonPercntCount,PercntCount,ColName,RptLabel,Color,Shape FROM #TEMP1	)DATA) MAINTBL WHERE s_index=1



	

	
END



GO
