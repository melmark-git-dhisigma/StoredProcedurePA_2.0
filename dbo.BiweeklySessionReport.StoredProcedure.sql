USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[BiweeklySessionReport]    Script Date: 7/4/2025 1:21:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[BiweeklySessionReport]
@StartDate datetime,
@EndDate datetime,
@StudentId int,
@LessonPlan varchar(5000),
@SchoolId int,
@Event varchar(50),
@TrendType varchar(50),
@IncludeIOA varchar(50),
@ClsType varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	SET @EndDate=@EndDate+' 23:59:59.900'
	DECLARE @lsid table (lsid int)
	DECLARE @lessno int 
	INSERT INTO @lsid(lsid) SELECT * FROM Split(@LessonPlan,',') OPTION (MAXRECURSION 500)
	SET @lessno=(SELECT COUNT(*) FROM Split(@LessonPlan, ','));
	Declare @CNT int
	,@Rowcnt int
	,@Totalcnt int
	,@TMPCount int
	,@calctype varchar(50)
	,@CalcRptLabelLP varchar(500) 
	,@TMPLoopCount int
	,@LPid int
	,@ARROWCNT int
	,@ARROWID int
	,@CNTLP int
	,@Scoreid int 
	,@Breaktrendid int
	,@LCount int
	,@LoopLessonPlan int
	,@ClassType varchar(50)
	,@ColRptLabelLP varchar(500)
	,@RptLbl varchar(200)
	,@Score int
	,@Nullcnt int
	,@NumOfTrend int
	,@TrendsectionNo int
	,@DateCnt int
	,@Midrate1 float,
	@Midrate2 float,
	@Slope float,
	@Const float,
	@Ids int,
	@IdOfTrend int,
	@SUM_XI float,
	@SUM_YI float,
	@SUM_XX float,
	@SUM_XY float,
	@X1 float,
	@Y1 float,
	@Z1 float,
	@X2 float,
	@Y2 float,
	@Z2 float,
	@A float,
	@B float,
	@datePrev datetime,
	@dateCurr datetime,
	@XValue int
	,@EVNTCNT INT
	,@RNUM INT
	,@CalcRpt VARCHAR(200)
	,@CLCNT INT
	,@RPTCNT INT
	,@PScore FLOAT
	,@PDummy FLOAT
	,@SNbr INT
	,@SNbr2 INT
	,@CURLPID INT
	,@INDEX INT
	,@IOACNT INT
	,@IOAPer VARCHAR(50)
	,@HdrId INT
	,@SessDate DATETIME
	,@ArrowNote nvarchar(500)
	,@CurArrowNote nvarchar(500)
	,@Events varchar(50)

	IF OBJECT_ID('tempdb..#TEMP1') IS NOT NULL  
	BEGIN
		DROP TABLE #TEMP1	
	END
	
	CREATE TABLE #TEMP1(Scoreid int NOT NULL PRIMARY KEY IDENTITY(1,1),SessionDate datetime,Rownum int,SNbr int,StartTs datetime,CalcType varchar(50),ClassType varchar(50),Score float,LessonPlanId int
	,IOAPerc varchar(50),ArrowNote nvarchar(max),EventType varchar(50),EventName nvarchar(max),EvntTs datetime,EndTime datetime,Comment varchar(500)
	,PromptCnt int,CalcRptLabelLP VARCHAR(500),ClassNameType varchar(50),BreakTrendNo int,XValue int,Trend float,StdtSessionHdr int
	,DummyScore float NULL,LeftYaxis varchar(500) NULL,RightYAxis varchar(500) NULL,PromptCount int NULL,
	NonPercntCount int NULL,PercntCount int NULL,ColName varchar(200) NULL,RptLabel varchar(200) NULL,Color varchar(50),Shape varchar(50), Score1 float NULL, Score2 float NULL, 
	PreScore float NULL, PreDummy float NULL, MaxScore FLOAT NULL, MaxDummyScore FLOAT NULL, OVstatus bit  null, arrowupdate int null);

	CREATE NONCLUSTERED INDEX idx_temp1_lessonplanid ON #TEMP1 (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_temp1_calctype ON #TEMP1 (CalcType);
	CREATE NONCLUSTERED INDEX idx_temp1_scoreid ON #TEMP1 (Scoreid);
	CREATE NONCLUSTERED INDEX idx_temp1_sessiondate ON #TEMP1 (SessionDate);
	CREATE NONCLUSTERED INDEX idx_temp1_score ON #TEMP1 (Score);
	CREATE NONCLUSTERED INDEX idx_temp1_CalcRptLabelLP ON #TEMP1 (CalcRptLabelLP);

	IF (@ClsType='Day' OR @ClsType='Residence')
	BEGIN
		INSERT INTO #TEMP1(
		SessionDate
		,Rownum
		,SNbr
		,StartTs 
		,CalcType
		,ClassType
		,Score
		,LessonPlanId
		,IOAPerc
		,CalcRptLabelLP
		,ClassNameType
		,StdtSessionHdr)
		SELECT STARTDATE
			,ROW_NUMBER() OVER (PARTITION BY LessonPlanId, CalcRptLabelLP ORDER BY SNbr,STARTDATE ASC) AS RowNumber
			,SNbr		
			,EndTs 
			,CalcType
			,Residence
			,Score
			,LessonPlanId
			,IOAPERCENTAGE
			,CalcRptLabelLP
			,ClassNameType
			,StdtSessionHdrId
		  FROM (SELECT 
			CONVERT(DATE,HDR.EndTs) AS STARTDATE
			,HDR.SessionNbr AS SNbr
			,HDR.EndTs
			,CALC.CalcType
			,@ClsType AS Residence 
			,CASE WHEN CSR.Score =-1 THEN NULL ELSE CSR.Score END AS Score
			,HDR.LessonPlanId	
			,CASE WHEN @IncludeIOA='True' THEN CASE WHEN (SELECT IOAPerc FROM StdtSessionHdr WHERE IOASessionHdrId=HDR.StdtSessionHdrId AND CONVERT(DATE,EndTs) BETWEEN @StartDate AND @EndDate AND IOAPerc IS NOT NULL) IS NOT NULL THEN 'IOA '+(SELECT CONVERT(VARCHAR(50),ROUND(IOAPerc,0)) FROM StdtSessionHdr WHERE IOASessionHdrId=HDR.StdtSessionHdrId AND CONVERT(DATE,EndTs) BETWEEN @StartDate AND @EndDate AND IOAPerc IS NOT NULL)+'% ' ELSE NULL END ELSE NULL END IOAPERCENTAGE
			,(CONVERT(VARCHAR(50),HDR.LessonPlanId)
			+'@'+(SELECT CASE WHEN CALC.CalcRptLabel='' THEN CALC.CalcType ELSE CALC.CalcRptLabel END )
			+'@'+(SELECT ColName FROM DSTempSetCol WHERE DSTempSetColId= (SELECT DSTempSetColId FROM DSTempSetColCalc 
			      WHERE DSTempSetColCalc.DSTempSetColCalcId=CALC.DsTempSetColCalcId))
			+'@'+(SELECT CASE WHEN CALC.CalcRptLabel='' THEN '' ELSE CALC.CalcType END)
		     ) AS CalcRptLabelLP	
			,CASE WHEN CLS.ResidenceInd=1 THEN 'Residence' ELSE  'Day' END AS ClassNameType
			,HDR.StdtSessionHdrId
		 FROM StdtSessionHdr HDR
		INNER JOIN StdtSessColScore CSR ON HDR.StdtSessionHdrId=CSR.StdtSessionHdrId
		INNER JOIN DSTempSetColCalc CALC ON CSR.DSTempSetColCalcId=CALC.DSTempSetColCalcId
		INNER JOIN Class CLS ON HDR.StdtClassId=CLS.ClassId
		 WHERE HDR.StudentId=@StudentId  
			AND HDR.IOAInd='N' 
			AND HDR.SessMissTrailStus ='N' 
			AND HDR.SessionStatusCd='S'
			AND HDR.IsMaintanace=0
		AND HDR.LessonPlanId IN (select lsid from @lsid)
		AND HDR.SchoolId=@SchoolId
		AND HDR.EndTs<=@EndDate
		AND HDR.EndTs>=@StartDate 
		AND CALC.IncludeInGraph<>0
		AND CSR.CreatedOn BETWEEN @StartDate AND @EndDate
		AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 and (LessonPlanTypeResi=0 OR LessonPlanTypeResi IS NULL) THEN 'Day' 
			ELSE CASE WHEN (LessonPlanTypeDay=0 OR LessonPlanTypeDay IS NULL) and LessonPlanTypeResi=1 THEN 'Residence' END END  FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=
			HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClsType
		) SESS
		ORDER BY CalcRptLabelLP,LessonPlanId,EndTs
	END
	ELSE IF (@ClsType='Day,Residence')
	BEGIN
		INSERT INTO #TEMP1(
		SessionDate
		,Rownum
		,SNbr
		,StartTs 
		,CalcType
		,ClassType
		,Score
		,LessonPlanId
		,IOAPerc
		,CalcRptLabelLP
		,ClassNameType
		,StdtSessionHdr)
		SELECT STARTDATE
			,ROW_NUMBER() OVER (PARTITION BY LessonPlanId, CalcRptLabelLP ORDER BY STARTDATE,SNbr ASC) AS RowNumber
			,SNbr		
			,EndTs 
			,CalcType
			,Residence
			,Score
			,LessonPlanId
			,IOAPERCENTAGE
			,CalcRptLabelLP
			,ClassNameType
			,StdtSessionHdrId
		  FROM (SELECT 
			CONVERT(DATE,HDR.EndTs) AS STARTDATE
			,HDR.SessionNbr AS SNbr
			,HDR.EndTs
			,CALC.CalcType
			,@ClsType AS Residence 
			,CASE WHEN CSR.Score =-1 THEN NULL ELSE CSR.Score END AS Score
			,HDR.LessonPlanId	
			,CASE WHEN @IncludeIOA='True' THEN CASE WHEN (SELECT IOAPerc FROM StdtSessionHdr WHERE IOASessionHdrId=HDR.StdtSessionHdrId AND CONVERT(DATE,EndTs) BETWEEN @StartDate AND @EndDate AND IOAPerc IS NOT NULL) IS NOT NULL THEN 'IOA '+(SELECT CONVERT(VARCHAR(50),ROUND(IOAPerc,0)) FROM StdtSessionHdr WHERE IOASessionHdrId=HDR.StdtSessionHdrId AND CONVERT(DATE,EndTs) BETWEEN @StartDate AND @EndDate AND IOAPerc IS NOT NULL)+'% ' ELSE NULL END ELSE NULL END IOAPERCENTAGE
			,(CONVERT(VARCHAR(50),HDR.LessonPlanId)
			+'@'+(SELECT CASE WHEN CALC.CalcRptLabel='' THEN CALC.CalcType ELSE CALC.CalcRptLabel END )
			+'@'+(SELECT ColName FROM DSTempSetCol WHERE DSTempSetColId= (SELECT DSTempSetColId FROM DSTempSetColCalc 
			      WHERE DSTempSetColCalc.DSTempSetColCalcId=CALC.DsTempSetColCalcId))
	        +'@'+(SELECT CASE WHEN CALC.CalcRptLabel='' THEN '' ELSE CALC.CalcType END)
		 ) AS CalcRptLabelLP	
			,CASE WHEN CLS.ResidenceInd=1 THEN 'Residence' ELSE  'Day' END AS ClassNameType
			,HDR.StdtSessionHdrId
		 FROM StdtSessionHdr HDR
		INNER JOIN StdtSessColScore CSR ON HDR.StdtSessionHdrId=CSR.StdtSessionHdrId
		INNER JOIN DSTempSetColCalc CALC ON CSR.DSTempSetColCalcId=CALC.DSTempSetColCalcId
		INNER JOIN Class CLS ON HDR.StdtClassId=CLS.ClassId
		 WHERE HDR.StudentId=@StudentId  
			AND HDR.IOAInd='N' 
			AND HDR.SessMissTrailStus ='N' 
			AND HDR.SessionStatusCd='S'
			AND HDR.IsMaintanace=0
		AND HDR.LessonPlanId IN (select lsid from @lsid)
		AND HDR.SchoolId=@SchoolId
		AND HDR.EndTs<=@EndDate
		AND HDR.EndTs>=@StartDate 
		AND CSR.CreatedOn BETWEEN @StartDate AND @EndDate
		AND CALC.IncludeInGraph<>0
		AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 or LessonPlanTypeResi=1 THEN 'Day,Residence' 
			END  FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=
			HDR.LessonPlanId AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC)=@ClsType
		) SESS
	END
	
	UPDATE #TEMP1 SET RptLabel=(SELECT Data FROM SplitWithRow(#TEMP1.CalcRptLabelLP,'@') WHERE RWNMBER=2)

	CREATE TABLE #DURATN(ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),Score FLOAT,LessonPlanId INT,CalcRptLabelLP varchar(500))

	CREATE NONCLUSTERED INDEX idx_duratn_lessonplanid ON #DURATN (LessonPlanId);

	INSERT INTO #DURATN
	SELECT MAX(ISNULL(Score,-1)),LessonPlanId,CalcRptLabelLP FROM #TEMP1 WHERE CalcType IN ('Total Duration','Avg Duration') GROUP BY LessonPlanId,CalcRptLabelLP
	
	SET @TMPCount=(SELECT COUNT(ID) FROM #DURATN)
	SET @TMPLoopCount=1
	WHILE(@TMPCount>0)
	BEGIN
		IF(EXISTS(SELECT ID FROM #DURATN WHERE ID=@TMPLoopCount AND Score<>-1))
		BEGIN
			IF(EXISTS(SELECT ID FROM #DURATN WHERE ID=@TMPLoopCount AND Score<60))
			BEGIN
				UPDATE #TEMP1 SET RptLabel=RptLabel+' (In Seconds)' WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
				AND CalcRptLabelLP=(SELECT CalcRptLabelLP FROM #DURATN WHERE ID=@TMPLoopCount)
			END
			ELSE IF(EXISTS(SELECT ID FROM #DURATN WHERE ID=@TMPLoopCount AND Score<3600))
			BEGIN
				UPDATE #TEMP1 SET RptLabel=RptLabel+' (In Minutes)' WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
				AND CalcRptLabelLP=(SELECT CalcRptLabelLP FROM #DURATN WHERE ID=@TMPLoopCount)
				UPDATE #TEMP1 SET Score=Score/60 WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
				AND CalcRptLabelLP=(SELECT CalcRptLabelLP FROM #DURATN WHERE ID=@TMPLoopCount)
			END
			ELSE IF(EXISTS(SELECT ID FROM #DURATN WHERE ID=@TMPLoopCount AND Score>=3600))
			BEGIN
				UPDATE #TEMP1 SET RptLabel=RptLabel+' (In Hours)' WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
				AND CalcRptLabelLP=(SELECT CalcRptLabelLP FROM #DURATN WHERE ID=@TMPLoopCount)
				UPDATE #TEMP1 SET Score=Score/3600 WHERE LessonPlanId=(SELECT LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount) 
				AND CalcRptLabelLP=(SELECT CalcRptLabelLP FROM #DURATN WHERE ID=@TMPLoopCount)
			END
		END
		SET @TMPLoopCount=@TMPLoopCount+1
		SET @TMPCount=@TMPCount-1
	END
		
	DROP TABLE #DURATN
	
	UPDATE #TEMP1  SET NonPercntCount=(SELECT COUNT(DISTINCT CalcType) FROM #TEMP1 TMP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize') AND TMP.LessonPlanId=#TEMP1.LessonPlanId)
	
	UPDATE #TEMP1 SET PercntCount=(SELECT COUNT(DISTINCT CalcType) FROM #TEMP1 TMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
	'Avg Duration','Customize','Event') AND TMP.LessonPlanId=#TEMP1.LessonPlanId)

	
	UPDATE #TEMP1 SET ColName=(SELECT Data FROM [dbo].[SplitWithRow](#TEMP1.CalcRptLabelLP,'@') WHERE RWNMBER=3) WHERE CalcType<>'Event'
	
	--------------- Trend start---------------------

	CREATE TABLE #EVNT(ID INT PRIMARY KEY IDENTITY(1,1),LPID INT)

	CREATE NONCLUSTERED INDEX idx_evnt_lpid ON #EVNT (LPId);

	INSERT INTO #EVNT select lsid from @lsid
	
	SET @Cnt=(SELECT COUNT(ID) FROM #EVNT)	
	
	WHILE(@Cnt>0)
	BEGIN
		CREATE TABLE #LPARROW(ID int PRIMARY KEY NOT NULL IDENTITY(1,1),LESSONID int,CalcType VARCHAR(50),AggredatedDate datetime
		,ClassType VARCHAR(50),IOAPerc VARCHAR(50),ArrowNote NVARCHAR(500),
		StudentLname VARCHAR(200),EventType VARCHAR(50),EventName NVARCHAR(max),TimeStampForReport datetime,EndTime datetime,Comment VARCHAR(200));
	
		CREATE NONCLUSTERED INDEX idx_lparrow_TimeStampForReport ON #LPARROW (TimeStampForReport);
		IF('Arrow' in ( SELECT * FROM Split(@Event,',') ))
		begin
		INSERT INTO #LPARROW
		SELECT 
		[StdtSessEvent].LessonPlanId,
		'Event' CalcType
		,TimeStampForReport AS AggredatedDate
		,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
		'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE 
		LessonPlanId=([StdtSessEvent].LessonPlanId)
		  AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC) AS ClassType
		,NULL IOAPerc
		,EventName AS ArrowNote
		,Student.StudentLname
		,StdtSessEventType AS EventType
		,EventName
		,TimeStampForReport
		,EndTime
		,Comment FROM [dbo].[StdtSessEvent]
		INNER JOIN Student ON Student.StudentId=[StdtSessEvent].StudentId
		LEFT JOIN LessonPlan ON LessonPlan.LessonPlanId=[StdtSessEvent].LessonPlanId WHERE Student.StudentId=@StudentId AND [StdtSessEvent].LessonPlanId 
		IN ((SELECT LPID FROM #EVNT WHERE ID=@Cnt)) AND EventType='EV' AND EvntTs BETWEEN @StartDate AND @EndDate
		AND discardstatus is NULL
		AND StdtSessEventType='Arrow notes' 
		
		CREATE TABLE #LPARROWzero(ID int PRIMARY KEY NOT NULL IDENTITY(1,1),LESSONID int,CalcType VARCHAR(50),AggredatedDate datetime
		,ClassType VARCHAR(50),IOAPerc VARCHAR(50),ArrowNote NVARCHAR(500),
		StudentLname VARCHAR(200),EventType VARCHAR(50),EventName NVARCHAR(max),TimeStampForReport datetime,EndTime datetime,Comment VARCHAR(200));


		INSERT INTO #LPARROWzero
		SELECT 
		[StdtSessEvent].LessonPlanId,
		'Event' CalcType
		,TimeStampForReport AS AggredatedDate
		,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
		'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE 
		LessonPlanId=([StdtSessEvent].LessonPlanId)
		  AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC) AS ClassType
		,NULL IOAPerc
		,EventName AS ArrowNote
		,Student.StudentLname
		,StdtSessEventType AS EventType
		,EventName
		,TimeStampForReport
		,EndTime
		,Comment FROM [dbo].[StdtSessEvent]
		INNER JOIN Student ON Student.StudentId=[StdtSessEvent].StudentId
		LEFT JOIN LessonPlan ON LessonPlan.LessonPlanId=[StdtSessEvent].LessonPlanId WHERE Student.StudentId=@StudentId AND [StdtSessEvent].LessonPlanId 
		IN (0) AND EventType='EV' AND EvntTs BETWEEN @StartDate AND @EndDate
		AND discardstatus is NULL
		AND StdtSessEventType='Arrow notes' 
		CREATE TABLE #EVNTzero(ID INT PRIMARY KEY IDENTITY(1,1),LPID INT)
	CREATE NONCLUSTERED INDEX idx_evnt_lpidzero ON #EVNTzero (LPId);
	INSERT INTO #EVNTzero select lsid from @lsid
	Declare @cn int
	Declare @CNTs int 
	Declare @CNTzero int 
	declare @evzero int 
	set @CNTzero=1
	set @evzero=(SELECT COUNT(ID) FROM #LPARROWzero)
	SET @CNTs=1
	SET @cn=(SELECT COUNT(ID) FROM #EVNTzero)	
	Declare @zeroid int
	declare @less int 
	WHILE(@evzero>0)
	BEGIN
	set @zeroid=(select ID from #LPARROWzero Where ID=@CNTzero )
	WHILE(@cn>0)
	BEGIN
	set @less=(select LPID from #EVNTzero Where ID=@CNTs )
	if(EXISTS(select scoreid from #TEMP1 where LessonPlanId=@less))
	BEGIN
	insert into #LPARROW Select @less as LESSONID,
		 CalcType,AggredatedDate
		,ClassType,IOAPerc ,ArrowNote,
		StudentLname,EventType,EventName,TimeStampForReport ,EndTime ,Comment From #LPARROWzero 
		END
	SET @CNTs=@CNTs+1
		SET @cn=@cn-1
	
	END

	SET @CNTzero=@CNTzero+1
		SET @evzero=@evzero-1
	END
	DROP TABLE #EVNTzero
	DROP TABLE #LPARROWzero
		SET @ARROWCNT =(SELECT COUNT(ID) FROM #LPARROW)
		
		SET @ARROWID=1
		END
		WHILE(@ARROWCNT>0)
		BEGIN
			SET @CNTLP=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND   LessonPlanId=(SELECT LESSONID FROM #LPARROW WHERE ID=@ARROWID) AND CONVERT(DATE,SessionDate)=
			(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) )
			Declare @sc float
			--IF(@CNTLP>0)
			
			--BEGIN
			
			--	UPDATE top (1) #TEMP1 SET    ArrowNote=(SELECT STUFF((SELECT ','+CONVERT(NVARCHAR(MAX), EventName)  FROM (SELECT 
			--	 [EventName]  FROM #LPARROW 
			--	WHERE LESSONID=(SELECT LESSONID FROM #LPARROW WHERE ID=@ARROWID) AND  CONVERT(DATE,AggredatedDate)= CONVERT(DATE,SessionDate)
			--	) EName FOR XML PATH('')),1,1,'')) 
			--	WHERE LessonPlanId=(SELECT LESSONID FROM #LPARROW WHERE ID=@ARROWID) AND (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)=
			--	(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) 
			--	--SET @sc=(SELECT TOP 1 Score FROM #TEMP1 WHERE LessonPlanId=(SELECT LESSONID FROM #LPARROW WHERE ID=@ARROWID) AND CONVERT(DATE,SessionDate)=
			--	--(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) );
				
			--	--INSERT INTO #TEMP1 (LessonPlanId
			--	--,CalcType
			--	--,SessionDate
			--	--,ClassType
			--	--,IOAPerc
			--	--,ArrowNote
			--	--,EventType
			--	--,EventName
			--	--,EvntTs
			--	--,EndTime
			--	--,Comment
			--	--,Score
			--	--,ColName
			--	--,RptLabel)
			--	--SELECT LESSONID
			--	--,CalcType
			--	--,AggredatedDate
			--	--,ClassType
			--	--,IOAPerc
			--	--,ArrowNote --+'---------->' AS ArrowNote
			--	--,EventType
			--	--,NULL as EventName
			--	--,TimeStampForReport
			--	--,EndTime
			--	--,Comment
			--	--,(CASE WHEN @sc IS NULL THEN 0 ELSE @sc END) Score
			--	--,(SELECT TOP 1 TMP.ColName FROM #TEMP1 TMP WHERE TMP.LessonPlanId=LESSONID) ColName
			--	--,(SELECT TOP 1 TMP.RptLabel FROM #TEMP1 TMP WHERE TMP.LessonPlanId=LESSONID) RptLabel
			--	-- FROM #LPARROW WHERE ID=@ARROWID	 
			--	END
				IF(EXISTS(SELECT Scoreid FROM #TEMP1 WHERE LessonPlanId=(SELECT LESSONID FROM #LPARROW WHERE ID=@ARROWID)) and @Cnt=1 )
				BEGIN
				INSERT INTO #TEMP1 (LessonPlanId
				,CalcType
				,SessionDate
				,ClassType
				,IOAPerc
				,ArrowNote
				,EventType
				,EventName
				,EvntTs
				,EndTime
				,Comment
				,Score
				,ColName
				,RptLabel)
				SELECT LESSONID
				,CalcType
				,CONVERT(DATE,AggredatedDate)
				,ClassType
				,IOAPerc
				,ArrowNote --+'---------->' AS ArrowNote
				,EventType
				,NULL as EventName
				,TimeStampForReport
				,EndTime
				,Comment
				,0 AS Score
				,(SELECT TOP 1 TMP.ColName FROM #TEMP1 TMP WHERE TMP.LessonPlanId=LESSONID) ColName
				,(SELECT TOP 1 TMP.RptLabel FROM #TEMP1 TMP WHERE TMP.LessonPlanId=LESSONID) RptLabel
				 FROM #LPARROW WHERE ID=@ARROWID	 
			END
			SET @ARROWCNT=@ARROWCNT-1
			SET @ARROWID=@ARROWID+1
		END
		DROP TABLE #LPARROW	
		DECLARE @MajorMinor TABLE (MajorMinor Varchar(20))
		IF('Major' in ( SELECT * FROM Split(@Event,',') ))
			INSERT INTO @MajorMinor(MajorMinor) VALUES('Major')
		IF('Minor' in ( SELECT * FROM Split(@Event,',') ))
		BEGIN
			INSERT INTO @MajorMinor(MajorMinor) VALUES('Minor')
		END	
		IF(EXISTS(SELECT Scoreid FROM #TEMP1 WHERE LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt ) AND Score is not null AND CalcType<>'Event'))
		BEGIN
			INSERT INTO #TEMP1 (LessonPlanId
				,CalcType
				,SessionDate
				,ClassType
				,EventType
				,EventName
				,EvntTs
				,EndTime
				,Comment
				,Rownum
				,SNbr
				)
			SELECT distinct 
				(SELECT LPID FROM #EVNT WHERE ID=@Cnt)	
				,'Event' AS CalcType
				,CONVERT(DATE,EvntTs) AS AggredatedDate
				,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
				'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE 
				LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt)
				  AND StudentId=@StudentId AND SchoolId=@SchoolId ORDER BY StdtLessonPlanId DESC) AS ClassType
				 
				,CASE WHEN EXISTS(SELECT StdtSessEventId FROM StdtSessEvent where StdtSessEventType='Major' AND StdtSessEventType IN(SELECT MajorMinor FROM @MajorMinor)
				 and ((SessionNbr >0 AND SessionNbr=VNT.SessionNbr) OR (VNT.SessionNbr IS NULL)) AND (LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) OR LessonPlanId=0) AND StudentId=@StudentId and discardstatus is null AND EventName is not null and 
				 CONVERT(DATE,EvntTs) =CONVERT(DATE,VNT.EvntTs))  THEN 'Major' ELSE 'Minor' END AS EventType

				,CASE WHEN VNT.SessionNbr IS NOT NULL THEN (SELECT STUFF((SELECT  ', '+ EventName FROM (SELECT EventName  FROM [dbo].[StdtSessEvent] EVNT
				WHERE EVNT.StudentId=@StudentId AND EventType='EV' AND EVNT.discardstatus is null AND EventName is not null AND CONVERT(DATE,EVNT.EvntTs) =CONVERT(DATE,VNT.EvntTs) 
				AND StdtSessEventType<>'Arrow notes' AND StdtSessEventType IN(SELECT MajorMinor FROM @MajorMinor) AND EVNT.SessionNbr >0 AND EVNT.SessionNbr=VNT.SessionNbr AND (EVNT.LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) OR EVNT.LessonPlanId=0)) LP FOR XML PATH('')),1,1,'')) 
				ELSE (SELECT STUFF((SELECT  ', '+ EventName FROM (SELECT EventName  FROM [dbo].[StdtSessEvent] EVNT
				WHERE EVNT.StudentId=@StudentId AND EventType='EV' AND CONVERT(DATE,EVNT.EvntTs) =CONVERT(DATE,VNT.EvntTs) AND EVNT.discardstatus is null AND EventName is not null
				AND StdtSessEventType<>'Arrow notes' AND StdtSessEventType IN(SELECT MajorMinor FROM @MajorMinor) AND EVNT.SessionNbr IS NULL  AND (EVNT.LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) OR EVNT.LessonPlanId=0)) LP FOR XML PATH('')),1,1,''))  END EventName
				,CONVERT(DATE,EvntTs) EvntTs
				,NULL AS EndTime
				,NULL AS Comment
				,(CASE WHEN VNT.SessionNbr IS NOT NULL THEN (CASE WHEN (SELECT TOP 1 Rownum FROM #TEMP1 WHERE StdtSessionHdr = (SELECT StdtSessionHdrId FROM StdtSessionHdr WHERE SessionNbr= VNT.SessionNbr AND (LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) OR LessonPlanId=0) AND StudentId=@StudentId AND CONVERT(DATE,EndTs)=CONVERT(DATE,VNT.EvntTs))) IS NOT NULL 
					THEN(SELECT TOP 1 Rownum FROM #TEMP1 WHERE StdtSessionHdr = (SELECT StdtSessionHdrId FROM StdtSessionHdr WHERE SessionNbr= VNT.SessionNbr AND (LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) OR LessonPlanId=0) AND StudentId=@StudentId AND CONVERT (DATE,EndTs)=CONVERT(DATE,VNT.EvntTs)))
					ELSE (SELECT TOP 1 Rownum FROM #TEMP1 WHERE #TEMP1.LessonPlanId=VNT.LessonPlanId AND #TEMP1.SessionDate=CONVERT(DATE,VNT.EvntTs) AND VNT.SessionNbr>SNbr order by SNbr desc) END)	
				ELSE (null)  END ) AS Rownum
				,(CASE WHEN SessionNbr IS NOT NULL THEN SessionNbr
					ELSE (null) END)
				 FROM [dbo].[StdtSessEvent] VNT
				 WHERE VNT.StudentId=@StudentId AND discardstatus is null AND EventName is not null AND (VNT.LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) OR VNT.LessonPlanId=0) AND EventType='EV' AND EvntTs BETWEEN @StartDate AND @EndDate
				AND StdtSessEventType<>'Arrow notes' AND StdtSessEventType IN(SELECT MajorMinor FROM @MajorMinor) GROUP BY VNT.LessonPlanId,CONVERT(DATE,EvntTs),VNT.StdtSessEventType,VNT.SessionNbr,VNT.StudentId

		END

		 SET @Cnt=@Cnt-1
	END
    DROP TABLE #EVNT

	--SELECT Rownum,EventType,EventName from #TEMP1
	-----------------------------------------Probe Mode  events-------------------------------------------
	CREATE TABLE #Probe (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), RowNum INT, SessNbr INT, SessDate DATETIME, LessonId INT )
	INSERT INTO #Probe SELECT  Rownum, SNbr, SessionDate, LessonPlanId FROM #TEMP1 WHERE  EventName LIKE'%ProbeMode' AND CalcType='Event' order by LessonPlanId,Rownum
	DECLARE @NewSessDate1 DATETIME
	DECLARE @sessnmr int 
	SET @CNT= 1
	SET @Totalcnt= (SELECT COUNT(ID) FROM #Probe)
	WHILE(@Totalcnt>0)
	BEGIN
		SET @RNUM=(SELECT RowNum FROM #Probe WHERE ID=@CNT)
		SET @sessnmr=(SELECT SessNbr FROM #Probe WHERE ID=@CNT)
		SET @SessDate=(SELECT SessDate FROM #Probe WHERE ID=@CNT)
		SET @LPid=(SELECT LessonId FROM #Probe WHERE ID=@CNT)
		set @NewSessDate1=(SELECT Top 1  SessionDate FROM #TEMP1 WHERE SNbr=@sessnmr AND LessonPlanId=@LPid AND CalcType!='Event')
		if (@NewSessDate1 is not null)
		BEGIN
		
			if(@SessDate!=@NewSessDate1)
			BEGIN
				UPDATE #TEMP1 SET SessionDate=@NewSessDate1 WHERE SNbr=@sessnmr AND LessonPlanId=@LPid AND CalcType='Event' AND  EventName LIKE'%ProbeMode'
			END			
		END
		else
			delete from #TEMP1 where  EventName LIKE'%ProbeMode'  and SNbr=@sessnmr and SessionDate=@SessDate
		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
	END

	DROP TABLE #Probe
	
	-----------------------------------------End-------------------------------------------
	------------------------------------------avoid null session-------------------------------------------
	CREATE TABLE #NULLSESSION (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), SessNbr INT, LessonId INT)
	INSERT INTO #NULLSESSION select DISTINCT SNbr, LessonPlanId from #TEMP1 where CalcType<>'Event' and Score is null and DummyScore is null ORDER BY LessonPlanId,SNbr
	SET @CNT=1
	SET @Rowcnt=(SELECT COUNT(ID) FROM #NULLSESSION)
	WHILE (@Rowcnt>0)
	BEGIN
		SET @LPid=(SELECT LessonId FROM #NULLSESSION WHERE ID=@CNT)
		SET @SNbr=(SELECT SessNbr FROM #NULLSESSION WHERE ID=@CNT)
		SET @Totalcnt=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE LessonPlanId=@LPid AND SNbr=@SNbr AND (Score IS NOT NULL OR DummyScore IS NOT NULL))
		IF(@Totalcnt=0)
			DELETE FROM #TEMP1 WHERE LessonPlanId=@LPid AND SNbr=@SNbr and CalcType<>'Event'
		SET @CNT=@CNT+1
		SET @Rowcnt=@Rowcnt-1
	END
	DROP TABLE #NULLSESSION

	CREATE TABLE #NULLTEMP (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), CalcRptLabl VARCHAR(200), LessonId INT)
	INSERT INTO #NULLTEMP SELECT DISTINCT CalcRptLabelLP, LessonPlanId FROM #TEMP1 where CalcType<>'Event' ORDER BY LessonPlanId
	SET @CNT=1
	SET @Rowcnt=(SELECT COUNT(ID) FROM #NULLTEMP)
	WHILE (@Rowcnt>0)
	BEGIN
		SET @LPid=(SELECT LessonId FROM #NULLTEMP WHERE ID=@CNT)
		SET @CalcRptLabelLP=(SELECT CalcRptLabl FROM #NULLTEMP WHERE ID=@CNT) 
		SET @Totalcnt=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRptLabelLP)
		SET @CLCNT=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRptLabelLP AND Score IS NULL AND DummyScore IS NULL)
		IF (@Totalcnt=@CLCNT)
			DELETE FROM #TEMP1 WHERE LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRptLabelLP and CalcType<>'Event'
		SET @CNT=@CNT+1
		SET @Rowcnt=@Rowcnt-1
	END
	DROP TABLE #NULLTEMP

	-------------------------------------------------end-------------------------------------------------
	----------------------Remove the Arrow notes on dates when there are no sessions-----------------------
	--CREATE TABLE #ARROWNOTE (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), SessDate DATETIME, LessonId INT, ArrowNote NVARCHAR(500))
	--INSERT INTO #ARROWNOTE SELECT SessionDate,LessonPlanId, ArrowNote FROM #TEMP1 WHERE CalcType='Event' AND EventType='Arrow notes' 
	--	AND Rownum IS NULL ORDER BY LessonPlanId, SessionDate
	--	DECLARE @Scoreidcount int
	--SET @CNT= 1
	--SET @ARROWCNT= (SELECT COUNT(ID) FROM #ARROWNOTE)
	--WHILE(@ARROWCNT>0)
	--BEGIN
	--	SET @LPid=(SELECT LessonId FROM #ARROWNOTE WHERE ID=@CNT)
	--	SET @SessDate=(SELECT SessDate FROM #ARROWNOTE WHERE ID=@CNT)
	--	SET @ArrowNote=(SELECT ArrowNote FROM #ARROWNOTE WHERE ID=@CNT)
	--	SET @Scoreidcount=( SELECT COUNT(Scoreid) FROM #TEMP1 WHERE CONVERT(DATE,SessionDate)= CONVERT(DATE,@SessDate) AND LessonPlanId=@LPid)
	--	SET @Scoreid=( SELECT TOP 1 Scoreid FROM #TEMP1 WHERE CONVERT(DATE,SessionDate)= CONVERT(DATE,@SessDate) AND LessonPlanId=@LPid)
	--	IF (@Scoreid IS NOT NULL) 
	--		SET @CurArrowNote=( SELECT ArrowNote FROM #TEMP1 WHERE Scoreid=@Scoreid)

	--	IF (@CurArrowNote IS NULL)
	--		UPDATE #TEMP1 SET ArrowNote=@ArrowNote WHERE Scoreid=@Scoreid			
	--	ELSE
		
	--		UPDATE #TEMP1 SET ArrowNote=@CurArrowNote+', '+@ArrowNote WHERE Scoreid=@Scoreid
	--	DELETE FROM #TEMP1  WHERE CalcType='Event' AND EventType='Arrow notes' AND Rownum IS NULL AND CONVERT(DATE,SessionDate)= CONVERT(DATE,@SessDate) AND LessonPlanId=@LPid 
	--	SET @CNT=@CNT+1
	--	SET @ARROWCNT=@ARROWCNT-1
	--END
	--DROP TABLE #ARROWNOTE

	--------------------------------------------------------END-----------------------------------------------------------
	
--UPDATE #TEMP1
--SET ArrowNote = (
--    SELECT STRING_AGG(ArrowNote, ',')
--    FROM #TEMP1 AS tmp1
--    WHERE CONVERT(DATE,tmp1.SessionDate) = CONVERT(DATE,#TEMP1.SessionDate) and tmp1.CalcType='Event' and #TEMP1.CalcType='Event' and tmp1.ArrowNote is not null and  #TEMP1.ArrowNote is not null
--    GROUP BY CONVERT(DATE,tmp1.SessionDate) 
--);
--------------------------------------------------------Update Arrow note based on date-----------------------------------------------------------
UPDATE #TEMP1
SET ArrowNote = (
    SELECT STUFF((
        SELECT ',' + ISNULL(tmp1.ArrowNote, '')  
        FROM #TEMP1 AS tmp1
        WHERE CONVERT(DATE, tmp1.SessionDate) = CONVERT(DATE, #TEMP1.SessionDate)
		AND tmp1.LessonPlanId=#TEMP1.LessonPlanId
          AND tmp1.CalcType = 'Event' 
          AND tmp1.EventType = 'Arrow notes'  
        FOR XML PATH('')
    ), 1, 1, '')
)
WHERE CalcType = 'Event' 
  AND EventType = 'Arrow notes';  

 
CREATE TABLE #ArrowEVNT (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),  SessDate DATETIME,  ArrowNote VARCHAR(MAX), lessid int)
		CREATE NONCLUSTERED INDEX idx_ArrowEVNT_SessDate ON #ArrowEVNT (SessDate);

	INSERT INTO #ArrowEVNT SELECT DISTINCT CONVERT(DATE,SessionDate),ArrowNote,LessonPlanId FROM #TEMP1 WHERE  ArrowNote is not null
	
	SET @CNT= 1
	declare @lesnid int
	DECLARE @Arrow varchar(max)
	declare @count int
	SET @Totalcnt= (SELECT COUNT(ID) FROM #ArrowEVNT)
	WHILE(@Totalcnt>0)
	BEGIN
	SET @lesnid=(SELECT lessid FROM #ArrowEVNT WHERE ID=@CNT)
		SET @Arrow=(SELECT ArrowNote FROM #ArrowEVNT WHERE ID=@CNT)
		SET @SessDate=(SELECT SessDate FROM #ArrowEVNT WHERE ID=@CNT)
		SET @count=(select count(Scoreid) from #TEMP1 where ArrowNote=@Arrow and CONVERT(DATE,SessionDate)=@SessDate)
		If(@count>1)
		BEGIN
	DECLARE @selectednote int
	SET @selectednote=(Select Top 1 Scoreid from #TEMP1 where ArrowNote=@Arrow and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lesnid)
		Delete from #TEMP1 where Scoreid !=@selectednote and ArrowNote=@Arrow and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lesnid
		END	
		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
	END
	DROP TABLE #ArrowEVNT
		
	--------------------------------------------------------END-----------------------------------------------------------
	--------------------------- Event Move back to previous session when null event occure(Event Tracker)---------------------------
	--DECLARE @newrownum INT
	--DECLARE @newsamesnbr INT
	--DECLARE @newdate DATETIME
	--DECLARE @newsamedate DATETIME
	--DECLARE @newsessionnmbr INT
	--DECLARE @CurrentSessionDate DATETIME
	--CREATE TABLE #SEDATE (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), SessionDate DATE, SessNbr INT, Rownum INT, LPid INT)
	--INSERT INTO #SEDATE SELECT DISTINCT SessionDate, SNbr,Rownum,LessonPlanId FROM #TEMP1 ORDER BY LessonPlanId,SessionDate,SNbr

	--SET @Totalcnt=(SELECT COUNT(ID) FROM #SEDATE)
	--SET @CNT=1
	--DECLARE @evntid int
	--WHILE(@Totalcnt>0)
	--BEGIN
	--	SELECT @SNbr= SessNbr from #SEDATE WHERE ID=@CNT
	--	SELECT @LPid= LPid from #SEDATE WHERE ID=@CNT
	--	IF(@SNbr IS NULL)
	--	BEGIN
	--		SET @CurrentSessionDate = (SELECT SessionDate FROM #SEDATE WHERE ID=@CNT)		
	--		SET @newrownum=(SELECT TOP 1 Rownum FROM #TEMP1 WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate and SNbr is not null and Rownum is not null order by Rownum)	
	--		SET @newsessionnmbr=(SELECT TOP 1 SNbr FROM #TEMP1 WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate and SNbr is not null and Rownum is not null order by Rownum)
	--		if(@newsessionnmbr is not null and @newrownum is not null)
	--		UPDATE #TEMP1 SET snbr=@newsessionnmbr, Rownum=@newrownum
	--				WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate AND LessonPlanId=@LPid and SNbr is null and CalcType='Event'	
	--	END
			
	--	IF(@SNbr IS NULL)
	--	BEGIN	
	--		SET @CurrentSessionDate = (SELECT SessionDate FROM #SEDATE WHERE ID=@CNT)		
	--		--SET @newsessionnmbr=(SELECT SessNbr FROM #SEDATE WHERE ID=@CNT-1 and LPid=@LPid)
	--		SET @newrownum=(SELECT TOP 1 Rownum FROM #SEDATE WHERE ID<@CNT and SessNbr is not null and LPid=@LPid order by SessNbr desc)	
	--		SET @newsessionnmbr=(SELECT TOP 1 SessNbr FROM #SEDATE WHERE ID<@CNT and SessNbr is not null and LPid=@LPid order by SessNbr desc)
	--		SET @evntid= (SELECT TOP 1 ID FROM #SEDATE WHERE ID<@CNT and SessNbr is not null and LPid=@LPid order by SessNbr desc)
	--		--SET @newrownum=(SELECT Rownum FROM #SEDATE WHERE ID=@CNT-1 and LPid=@LPid)
	--		IF(@newsessionnmbr IS NOT NULL)
	--			UPDATE #TEMP1 SET snbr=@newsessionnmbr, Rownum=@newrownum,SessionDate=(SELECT SessionDate FROM #SEDATE WHERE ID=@evntid and LessonPlanId=@LPid)  
	--				WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate AND LessonPlanId=@LPid and SNbr is null and CalcType='Event'	
	--		ELSE
	--		begin
	--			if (@CurrentSessionDate=(select top 1 CONVERT(DATE,SessionDate) from #TEMP1 where LessonPlanId=@LPid and SNbr is not null 
	--			order by SessionDate asc))
	--			begin
	--				set @SNbr= (select top 1 SNbr from #TEMP1 WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate AND LessonPlanId=@LPid and SNbr is not null 
	--			order by SessionDate asc)
	--				set @RNUM= (select top 1 Rownum from #TEMP1 WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate AND LessonPlanId=@LPid)
	--				UPDATE #TEMP1 SET snbr=@SNbr, Rownum=@RNUM	WHERE CONVERT(DATE,SessionDate)=@CurrentSessionDate AND LessonPlanId=@LPid 
	--					and SNbr is null and CalcType='Event'
	--			end
	--			else
	--				delete from #TEMP1 WHERE SNbr is null and CalcType='Event' and LessonPlanId=@LPid and CONVERT(DATE,SessionDate)<
	--					(select top 1 CONVERT(DATE,SessionDate) from #TEMP1 where LessonPlanId=@LPid and SNbr is not null order by SessionDate asc)	
			
	--		end
	--	END
	--	SET @CNT=@CNT+1
	--	SET @Totalcnt=@Totalcnt-1
	--END
	--DROP TABLE #SEDATE
	

	----------------------------------------------------------END----------------------------------------------------
		CREATE TABLE #OVERRIDEEV (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), RowNum INT, SessNbr INT, SessDate DATETIME, LessonId INT )
	INSERT INTO #OVERRIDEEV SELECT Rownum, SNbr, SessionDate, LessonPlanId FROM #TEMP1 WHERE EventName LIKE '%(OV)' AND CalcType='Event' order by LessonPlanId
	DECLARE @NewSessDatenew DATETIME
	DECLARE @countsc int
	DECLARE @sess int
	DECLARE @newsess int
	DECLARE @newrow int
	SET @CNT= 1
	SET @Totalcnt= (SELECT COUNT(ID) FROM #OVERRIDEEV)
	WHILE(@Totalcnt>0)
	BEGIN
		SET @RNUM=(SELECT RowNum FROM #OVERRIDEEV WHERE ID=@CNT)
		SET @SessDate=(SELECT SessDate FROM #OVERRIDEEV WHERE ID=@CNT)
		SET @Sess=(SELECT SessNbr FROM #OVERRIDEEV WHERE ID=@CNT)
		SET @LPid=(SELECT LessonId FROM #OVERRIDEEV WHERE ID=@CNT)
		set @countsc=(SELECT COUNT(SNbr) from #TEMP1 Where SNbr=@Sess and CalcType!='Event' )

		if(@countsc=0)
		BEGIN
		SET @newsess=(select TOP 1 SNbr from #TEMP1 where SNbr<@Sess and  CalcType!='Event' and LessonPlanId=@LPid order by SNbr desc)
		SET @newrow=(select TOP 1 Rownum from #TEMP1 where SNbr<@Sess and  CalcType!='Event' and LessonPlanId=@LPid order by SNbr desc)
		SET @NewSessDatenew=(select TOP 1 SessionDate from #TEMP1 where SNbr<@Sess and  CalcType!='Event' and LessonPlanId=@LPid order by SNbr desc)
		IF(@newsess IS NOT NULL)
		UPDATE #TEMP1 SET 
			Rownum= @newrow, SNbr=@newsess,SessionDate=@NewSessDatenew, OVstatus=1 WHERE (Rownum=@RNUM OR Rownum is NULL) AND SNbr=@Sess AND SessionDate=@SessDate AND  LessonPlanId=@LPid AND CalcType='Event' AND EventName LIKE '%(OV)'
		END
		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
		END
	DROP Table	#OVERRIDEEV

	--------------------------------override should move back to prior session-------------------------------------
	CREATE TABLE #OVERRIDE (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), RowNum INT, SessNbr INT, SessDate DATETIME, LessonId INT )
	INSERT INTO #OVERRIDE SELECT Rownum, SNbr, SessionDate, LessonPlanId FROM #TEMP1 WHERE EventName LIKE '%(OV)' AND CalcType='Event' AND OVstatus is null order by LessonPlanId
	DECLARE @NewSessDate DATETIME
	SET @CNT= 1
	SET @Totalcnt= (SELECT COUNT(ID) FROM #OVERRIDE)
	WHILE(@Totalcnt>0)
	BEGIN
		SET @RNUM=(SELECT RowNum FROM #OVERRIDE WHERE ID=@CNT)
		SET @SessDate=(SELECT SessDate FROM #OVERRIDE WHERE ID=@CNT)
		SET @LPid=(SELECT LessonId FROM #OVERRIDE WHERE ID=@CNT)
		set @NewSessDate=(SELECT top 1 SessionDate FROM #TEMP1 WHERE Rownum=@RNUM-1 AND LessonPlanId=@LPid order by SessionDate desc)
		if (@NewSessDate is not null)
		BEGIN
			UPDATE #TEMP1 SET SessionDate=@NewSessDate,
			Rownum= (select top 1 Rownum from #TEMP1 where Rownum= @RNUM-1 AND LessonPlanId=@LPid order by SessionDate desc), 
			SNbr=(select top 1 SNbr from #TEMP1 where Rownum= @RNUM-1 AND LessonPlanId=@LPid order by SessionDate desc) WHERE Rownum=@RNUM AND LessonPlanId=@LPid AND CalcType='Event'
			END			

		else
			delete from #TEMP1 where EventName LIKE '%(OV)' AND CalcType='Event' and Rownum=@RNUM and SessionDate=@SessDate
		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
	END
	DELETE FROM #TEMP1 WHERE Rownum =0
	DROP TABLE #OVERRIDE

	--------------------------------------------------------END----------------------------------------------------
	
	--------------------------Avoid Repeating Arrow note----------------------------

--	UPDATE #TEMP1
--SET ArrowNote = (
--    SELECT STUFF((
--        SELECT ',' + ISNULL(tmp1.ArrowNote, '')  
--        FROM #TEMP1 AS tmp1
--        WHERE CONVERT(DATE, tmp1.SessionDate) = CONVERT(DATE, #TEMP1.SessionDate)
--		AND  tmp1.LessonPlanId=#TEMP1.LessonPlanId
--          AND tmp1.ArrowNote IS NOT NULL
--        FOR XML PATH('')
--    ), 1, 1, '')
--)
--WHERE ArrowNote IS NOT NULL; 
--CREATE TABLE #samearrow (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),  SessDate DATETIME,  ArrowNote VARCHAR(MAX), lessid int)
--		CREATE NONCLUSTERED INDEX idx_ArrowEVNT_SessDate ON #samearrow (SessDate);

--	INSERT INTO #samearrow SELECT DISTINCT CONVERT(DATE,SessionDate),ArrowNote,LessonPlanId FROM #TEMP1 WHERE  ArrowNote is not null

--	SET @CNT= 1
	declare @arrcount int
	DECLARE @Arrowval varchar(max)
	declare @count1 int
	declare @lid int
	declare @evntcount int
	--SET @Totalcnt= (SELECT COUNT(ID) FROM #samearrow)
	--WHILE(@Totalcnt>0)
	--BEGIN
	--SET @lid=(SELECT lessid FROM #samearrow WHERE ID=@CNT)
	--	SET @Arrowval=(SELECT ArrowNote FROM #samearrow WHERE ID=@CNT)
	--	SET @SessDate=(SELECT SessDate FROM #samearrow WHERE ID=@CNT)
	--	SET @count1=(select count(Scoreid) from #TEMP1 where ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate and LessonPlanId=@lid)
	--	SET @evntcount=(select count(Scoreid) from #TEMP1 where ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate and EventType='Arrow notes' and CalcType='Event'  and LessonPlanId=@lid)
	--	If(@count1>1)
	--	BEGIN
	--	if(@count1>@evntcount)
	--	Delete from #TEMP1 where  ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lid
	--	ELSE
	--	BEGIN
	--	if(@count1=@evntcount)
	--	BEGIN
	--	set @arrcount=(select COUNT(scoreid) from #TEMP1 WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)=@SessDate and EventType is null  and CalcType != 'Event' and LessonPlanId=@lid)
	--	if(@arrcount is not null)
	--	BEGIN
	--	UPDATE top (1) #TEMP1 SET ArrowNote = CASE 
 --                  WHEN ArrowNote IS NOT NULL THEN ArrowNote + ',' + @Arrowval
 --                  ELSE @Arrowval
	--	END
	--			WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)=@SessDate and EventType is null  and CalcType != 'Event' and LessonPlanId=@lid
	--	Delete from #TEMP1 where  ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lid
	--	END
	--	--ELSE
	--	--BEGIN
	--	--UPDATE top (1) #TEMP1 SET ArrowNote = CASE 
 -- --                 WHEN ArrowNote IS NOT NULL THEN ArrowNote + ',' + @Arrowval
 -- --                 ELSE @Arrowval
	--	--END
	--	--		WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)<@SessDate and EventType is null  and CalcType != 'Event' and LessonPlanId=@lid
	--	--Delete from #TEMP1 where  ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lid
	--	--END
	--	END
	--	END
	--	END
	--	ELSE
	--	BEGIN
	--	if(@count1=1)
	--	BEGIN
	--	set @arrcount=(select COUNT(scoreid) from #TEMP1 WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)=@SessDate and EventType is null  and CalcType != 'Event' and LessonPlanId=@lid)
			
	--	if(@arrcount >0)
	--	BEGIN
	--	UPDATE top (1) #TEMP1 SET ArrowNote =@Arrowval
	--			WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)=@SessDate and EventType is null  and CalcType != 'Event' and LessonPlanId=@lid
	--	Delete from #TEMP1 where  ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lid
	--	END
	--	--ELSE
	--	--BEGIN
	--	--UPDATE top (1) #TEMP1 SET ArrowNote = CASE 
 -- --                 WHEN ArrowNote IS NOT NULL THEN ArrowNote + ',' + @Arrowval
 -- --                 ELSE @Arrowval
 -- --              END
	--	--		WHERE (Score IS NOT NULL OR DummyScore IS NOT NULL) AND CONVERT(DATE,SessionDate)<@SessDate and EventType is null  and CalcType != 'Event' and LessonPlanId=@lid
	--	--Delete from #TEMP1 where  ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate AND EventType='Arrow notes' and CalcType='Event' and LessonPlanId=@lid
	--	--END
 --               END
	--	END	
	--	SET @CNT=@CNT+1
	--	SET @Totalcnt=@Totalcnt-1
	--END
	--DROP TABLE #samearrow

	--------------------------------------------------------END----------------------------------------------------
	
	--------------------------Avoid Repeating Events----------------------------	
	CREATE TABLE #RPT (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), RowNum INT, EType VARCHAR(50),EName NVARCHAR(MAX))

	CREATE NONCLUSTERED INDEX idx_rpt_rownum ON #RPT (Rownum);
	CREATE NONCLUSTERED INDEX idx_rpt_etype ON #RPT (EType);
	--CREATE NONCLUSTERED INDEX idx_rpt_ename ON #RPT (EName);

	INSERT INTO #RPT SELECT DISTINCT Rownum, EventType, EventName FROM #TEMP1 WHERE CalcType='Event' 
	DECLARE @EType VARCHAR(20)
	SET @CNT= 1
	SET @Totalcnt= (SELECT COUNT(*) FROM #RPT)
	WHILE(@Totalcnt>0)
	BEGIN
		SET @RNUM=(SELECT RowNum FROM #RPT WHERE ID=@CNT)
		SET @EType=(SELECT EType FROM #RPT WHERE ID=@CNT)
		SET @Events=(SELECT EName FROM #RPT WHERE ID=@CNT)
		SET @CalcRpt=(SELECT COUNT(RowNum) FROM #TEMP1 WHERE CalcType='Event' AND Rownum=@RNUM AND EventType=@EType AND EventName=@Events)
		IF (@CalcRpt>1)
		BEGIN
			DELETE FROM #TEMP1 WHERE Scoreid=(SELECT TOP 1 Scoreid  FROM #TEMP1 WHERE CalcType='Event' AND Rownum=@RNUM AND EventType=@EType AND EventName=@Events
				ORDER BY Scoreid DESC)
		END
		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
	END
	DROP TABLE #RPT

	----------------Remove null events--------------
	--DELETE FROM #TEMP1 WHERE CalcType='Event' and EventType is not null and EventName is null
	----------------END--------------
	----------------Arrow note and events (same date)--------------
	CREATE TABLE #arrowdata (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),  SessDate DATETIME,  ArrowNote VARCHAR(MAX), lessid int)
		CREATE NONCLUSTERED INDEX idx_ArrowEVNT_SessDate ON #arrowdata (SessDate);
	INSERT INTO #arrowdata SELECT DISTINCT CONVERT(DATE,SessionDate),ArrowNote,LessonPlanId FROM #TEMP1 WHERE  ArrowNote is not null and CalcType='Event'
	
	SET @CNT= 1
	SET @Totalcnt= (SELECT COUNT(ID) FROM #arrowdata)
	WHILE(@Totalcnt>0)
	BEGIN
	SET @lid=(SELECT lessid FROM #arrowdata WHERE ID=@CNT)
		SET @Arrowval=(SELECT ArrowNote FROM #arrowdata WHERE ID=@CNT)
		SET @SessDate=(SELECT SessDate FROM #arrowdata WHERE ID=@CNT)
		SET @evntcount=(select count(Scoreid) from #TEMP1 where  CONVERT(DATE,SessionDate)=@SessDate and Rownum is null and EventType in ('Major','Minor') and CalcType='Event'  and LessonPlanId=@lid)
		if(@evntcount>0)
		BEGIN
		UPDATE #TEMP1 set ArrowNote=@Arrowval, Score=0, arrowupdate=1 where CONVERT(DATE,SessionDate)=@SessDate and Rownum is null and EventType in ('Major','Minor') and CalcType='Event'  and LessonPlanId=@lid
		DELETE FROM #TEMP1 WHERE ArrowNote=@Arrowval and CONVERT(DATE,SessionDate)=@SessDate and EventType='Arrow notes' and CalcType='Event'  and LessonPlanId=@lid
		END
		
		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
	END
	DROP TABLE #arrowdata
	----------------END--------------


	----------------SAME ROW NUMBERS WITH DIFFERENT SESSION NUMBER--------------
	CREATE TABLE #ROWNUM (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), Scoreid INT, RowNum INT, SessNbr INT, LessonId INT )

	CREATE NONCLUSTERED INDEX idx_rownum_lessonid ON #ROWNUM (LessonId);
	CREATE NONCLUSTERED INDEX idx_rownum_rownum ON #ROWNUM (Rownum);
	CREATE NONCLUSTERED INDEX idx_rownum_sessnbr ON #ROWNUM (SessNbr);

	INSERT INTO #ROWNUM SELECT Scoreid,Rownum, SNbr, LessonPlanId FROM #TEMP1 WHERE CalcType='Event' and ArrowNote is null order by LessonPlanId,Rownum,SNbr
	DECLARE @NextRowNUM INT, @NextScoreId INT, @EventName nvarchar(max), @NextEventName nvarchar(max)

	SET @CNT= 1
	SET @LPid=(SELECT LessonId FROM #ROWNUM WHERE ID=@CNT)
	SET @Totalcnt= (SELECT COUNT(ID) FROM #ROWNUM)
	WHILE(@Totalcnt>0)
	BEGIN	
		SET @CURLPID=(SELECT LessonId FROM #ROWNUM WHERE ID=@CNT)
		IF(@LPid = @CURLPID)
		BEGIN
			SET @RNUM=(SELECT RowNum FROM #ROWNUM WHERE ID=@CNT AND LessonId=@CURLPID)
			SET @NextRowNUM=(SELECT RowNum FROM #ROWNUM WHERE ID=@CNT+1 AND LessonId=@CURLPID)
			SET @Scoreid=(SELECT Scoreid FROM #ROWNUM WHERE ID=@CNT AND LessonId=@CURLPID)
			SET @NextScoreId=(SELECT Scoreid FROM #ROWNUM WHERE ID=@CNT+1 AND LessonId=@CURLPID)
			IF (@RNUM=@NextRowNUM)
			BEGIN
				SET @EventName=(SELECT EventName FROM #TEMP1 WHERE Scoreid=@Scoreid AND LessonPlanId=@CURLPID)
				SET @NextEventName=(SELECT EventName FROM #TEMP1 WHERE Scoreid=@NextScoreId AND LessonPlanId=@CURLPID)
				UPDATE #TEMP1 SET EventName=(@EventName+', '+@NextEventName) WHERE Scoreid=@Scoreid AND LessonPlanId=@CURLPID

				DELETE FROM #TEMP1 WHERE Scoreid=@NextScoreId AND LessonPlanId=@CURLPID
			END
		END

		SET @CNT=@CNT+1
		SET @Totalcnt=@Totalcnt-1
	END
	DROP TABLE #ROWNUM

	--------------------------------------------------------END----------------------------------------------------

	--#TEMP1 SORTING BASED ON SESSION NUMBER

	CREATE TABLE #TEMPSESSION (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),RNum INT, SessNbr INT,LessonId INT)

	CREATE NONCLUSTERED INDEX idx_tempsession_lessonid ON #TEMPSESSION (LessonId);
	CREATE NONCLUSTERED INDEX idx_tempsession_sessnbr ON #TEMPSESSION (SessNbr);
	CREATE NONCLUSTERED INDEX idx_tempsession_rnum ON #TEMPSESSION (RNum);

	INSERT INTO #TEMPSESSION SELECT Rownum, SNbr,LessonPlanId FROM #TEMP1 ORDER BY LessonPlanId,SNbr
	SET @CURLPID=0
	SET @INDEX=1
	SET @CNT=1
	SET @Rowcnt=(SELECT COUNT(ID) FROM #TEMPSESSION)
	WHILE (@Rowcnt>0)
	BEGIN
		SET @LPid=(SELECT LessonId FROM #TEMPSESSION WHERE ID=@CNT)
		IF (@CURLPID!=@LPid)
		BEGIN
			SET @INDEX=1
			SET @SNbr=(SELECT SessNbr FROM #TEMPSESSION WHERE ID=@CNT)
			UPDATE #TEMP1 SET Rownum=@INDEX WHERE SNbr=@SNbr AND LessonPlanId=@LPid
		END
		ELSE
		BEGIN
			SET @SNbr=(SELECT SessNbr FROM #TEMPSESSION WHERE ID=@CNT)
			IF (@SNbr!=@SNbr2)
			BEGIN
				IF (@SNbr IS NOT NULL)
				BEGIN
					SET @INDEX=@INDEX+1
					UPDATE #TEMP1 SET Rownum=@INDEX WHERE SNbr=@SNbr AND LessonPlanId=@LPid
				END
			END
			ELSE
				UPDATE #TEMP1 SET Rownum=@INDEX WHERE SNbr=@SNbr AND LessonPlanId=@LPid					
		END
		SET @SNbr2=@SNbr
		SET @CURLPID=@LPid

		SET @CNT=@CNT+1
		SET @Rowcnt=@Rowcnt-1
	END
	DROP TABLE #TEMPSESSION

	
	--TO SEPERATE EACH TRENDLINE FROM THE TABLE #TEMP, ADD EACH PAGE SESSION TO #TEMPTYPE 
	CREATE TABLE #TEMPTYPE(ID int PRIMARY KEY NOT NULL IDENTITY(1,1),LPID int,Type VARCHAR(50),ClassType varchar(50),RptLabel varchar(500),ColRptLabelLP varchar(500));
	
	CREATE NONCLUSTERED INDEX idx_temptype_lpid ON #TEMPTYPE (LPId);
	CREATE NONCLUSTERED INDEX idx_temptype_type ON #TEMPTYPE (Type);
	CREATE NONCLUSTERED INDEX idx_temptype_classtype ON #TEMPTYPE (ClassType);
	CREATE NONCLUSTERED INDEX idx_temptype_rptlabel ON #TEMPTYPE (RptLabel);
	CREATE NONCLUSTERED INDEX idx_temptype_colrptlabellp ON #TEMPTYPE (ColRptLabelLP);
	
	INSERT INTO #TEMPTYPE SELECT DISTINCT LessonPlanId,CalcType,ClassType,RptLabel,CalcRptLabelLP FROM #TEMP1 WHERE CalcType<>'Event'
	 ORDER BY LessonPlanId,CalcType
	
	
	SET @Cnt=1
	SET @Breaktrendid=1
	
	SET @Nullcnt=0
	--FOR SEPERATING EACH TERAND LINE SECTION AND NUMBERED IT AS 1,2,3 ETC IN 'BreakTrendNo' COLUMN OF #TEMP TABLE
	SET @LCount=(SELECT COUNT(ID) FROM #TEMPTYPE)
	WHILE(@LCount>0)
	BEGIN	
		SET @Nullcnt=0
		SET @XValue= 1
		SET @CalcType=(SELECT Type FROM #TEMPTYPE WHERE ID=@Cnt)  
		SET @LoopLessonPlan=(SELECT LPID FROM #TEMPTYPE WHERE ID=@Cnt)
		SET @ClassType=(SELECT ClassType FROM #TEMPTYPE WHERE ID=@Cnt)
		SET @ColRptLabelLP=(SELECT ColRptLabelLP FROM #TEMPTYPE WHERE ID=@Cnt)
		SET @RptLbl=(SELECT RptLabel FROM #TEMPTYPE WHERE ID=@Cnt)
		SET @Scoreid=(SELECT TOP 1 Scoreid FROM #TEMP1 WHERE CalcType=@CalcType AND LessonPlanId=@LoopLessonPlan AND ClassType=@ClassType AND CalcRptLabelLP=@ColRptLabelLP order by SessionDate asc)
		WHILE(EXISTS(SELECT Scoreid FROM #TEMP1 WHERE LessonPlanId=@LoopLessonPlan AND ClassType=@ClassType AND Calctype=@CalcType AND Scoreid=@Scoreid AND CalcRptLabelLP=@ColRptLabelLP))
		BEGIN
			SET @Score=(SELECT ISNULL(CONVERT(int,Score),-1) FROM #TEMP1 WHERE Scoreid=@Scoreid)	
			SET @ARROWCNT=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE CalcType='Event' AND LessonPlanId=@LoopLessonPlan AND SessionDate=(SELECT SessionDate FROM #TEMP1 WHERE Scoreid=@Scoreid) AND Rownum=(SELECT Rownum FROM #TEMP1 WHERE Scoreid=@Scoreid))
			
			IF(@ARROWCNT>0 )
			BEGIN
				IF(@Score=-1)
				BEGIN
					SET @Breaktrendid=(SELECT ISNULL(MAX(BreakTrendNo),0) FROM #TEMP1)+1
				END
				ELSE
				BEGIN
					SET @Breaktrendid=(SELECT ISNULL(MAX(BreakTrendNo),0) FROM #TEMP1)+1
					SET @Nullcnt=0	
				END
			END
			
			IF(@Score=-1 AND ((@datePrev<=@dateCurr) OR @datePrev IS NULL))
			BEGIN	
				SET @Nullcnt=@Nullcnt+1	
			END
			ELSE IF(@Nullcnt>=5 AND @Score<>-1)
			BEGIN	
				SET @Breaktrendid=(SELECT ISNULL(MAX(BreakTrendNo),0) FROM #TEMP1)+1
				UPDATE #TEMP1 SET BreakTrendNo=@Breaktrendid WHERE Scoreid=@Scoreid
				SET @Nullcnt=0	
			END
			ELSE IF(@Score<>-1)
			BEGIN	
				IF(@LoopLessonPlan<>(SELECT LessonPlanId FROM #TEMP1 WHERE Scoreid=(@Scoreid-1)))
				BEGIN
					SET @Breaktrendid=@Breaktrendid+1
				END
				ELSE IF(@ColRptLabelLP<>(SELECT CalcRptLabelLP FROM #TEMP1 WHERE Scoreid=(@Scoreid-1)))
				BEGIN
					SET @Breaktrendid=@Breaktrendid+1
				END
				IF(@ARROWCNT=0 )
				BEGIN
					UPDATE #TEMP1 SET BreakTrendNo=@Breaktrendid WHERE Scoreid=@Scoreid
					SET @Nullcnt=0	
				END
			END	
			UPDATE #TEMP1 SET XValue=@XValue WHERE Scoreid=@Scoreid	
			SET @XValue= @XValue+1	
			SET @Scoreid=@Scoreid+1	
		END
		SET @Breaktrendid=@Breaktrendid+1
		SET @Cnt=@Cnt+1
		SET @LCount=@LCount-1
	END

	DROP TABLE #TEMPTYPE

	--SELECT EACH TREND LINE SECTION FROM #TEMP AND CALCULATE TREND POINT VALUES
	SET @Cnt=0
	IF(@TrendType='Quarter')
	BEGIN
		SET @NumOfTrend=(SELECT MAX(BreakTrendNo) FROM #TEMP1)
		
		WHILE(@NumOfTrend>0)
		BEGIN
			SET @Cnt=@Cnt+1
			SET @TrendsectionNo=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE BreakTrendNo=@Cnt)
			
			IF(@TrendsectionNo>2)
			BEGIN		
				CREATE TABLE #TRENDSECTION(Id int PRIMARY KEY NOT NULL IDENTITY(1,1),Trenddate datetime,Score float,Scoreid int);
				INSERT INTO #TRENDSECTION SELECT SessionDate,Score,Scoreid FROM #TEMP1 WHERE Scoreid BETWEEN (SELECT TOP 1 Scoreid FROM #TEMP1 WHERE 
				BreakTrendNo=@Cnt ORDER BY Scoreid) AND (SELECT TOP 1 Scoreid FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid DESC) AND Score IS NOT NULL
				
				IF((SELECT COUNT(Id) FROM #TRENDSECTION)%2=0)
					SET @DateCnt=((SELECT COUNT(*) FROM #TRENDSECTION)/2)+1
				ELSE
					SET @DateCnt=((SELECT COUNT(*) FROM #TRENDSECTION)/2)+2

				SET @Midrate1= (SELECT ((SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE Id BETWEEN 1 AND (SELECT COUNT(*)/2 FROM #TRENDSECTION) 
				ORDER BY Score) As A ORDER BY Score DESC) +(SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE 
				Id BETWEEN 1 AND (SELECT COUNT(*)/2 FROM #TRENDSECTION) ORDER BY Score DESC) As A ORDER BY Score Asc)) / 2 )

				SET @Midrate2=(SELECT ((SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE Id BETWEEN @DateCnt AND (SELECT COUNT(*) FROM #TRENDSECTION)
				ORDER BY Score) As A ORDER BY Score DESC) +(SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE 
				Id BETWEEN @DateCnt AND (SELECT COUNT(*) FROM #TRENDSECTION) ORDER BY Score DESC) As A ORDER BY Score Asc)) / 2 )

				--Applying Line Equation Y=mx+b To find Slope 'm' AND Constant 'b
				SET @Slope=(@Midrate2-@Midrate1)/((SELECT TOP 1 XValue FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid DESC)-(SELECT TOP 1 XValue 
				FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid))
				--b=y-mx
				SET @Const=@Midrate1-(@Slope*(SELECT TOP 1 XValue FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid))

				SET @Ids=(SELECT TOP 1 XValue FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid) --FIRST x value
				
				SET @IdOfTrend=(SELECT TOP 1 Scoreid FROM #TRENDSECTION ORDER BY Id)
				
				WHILE(@IdOfTrend<=(SELECT MAX(Scoreid) FROM #TRENDSECTION))	
				BEGIN	
					UPDATE #TEMP1 SET Trend=((@Slope*@Ids)+@Const) WHERE Scoreid=@IdOfTrend
					SET @IdOfTrend=@IdOfTrend+1
					SET @Ids=@Ids+1
				END	
				DROP TABLE #TRENDSECTION		
			END
			
			SET @NumOfTrend=@NumOfTrend-1
		END
	END
	ELSE IF(@Trendtype='Least')
	BEGIN
		SET @NumOfTrend=(SELECT MAX(BreakTrendNo) FROM #TEMP1)
		WHILE(@NumOfTrend>0)
		BEGIN
			SET @Cnt=@Cnt+1
			SET @TrendsectionNo=(SELECT COUNT(Scoreid) FROM #TEMP1 WHERE BreakTrendNo=@Cnt)

			IF(@TrendsectionNo>2)
			BEGIN	
			
				CREATE TABLE #TREND(Id int PRIMARY KEY NOT NULL IDENTITY(1,1),Trenddate datetime,Score float,Scoreid int,XVal int);
				INSERT INTO #TREND SELECT SessionDate,Score,Scoreid,XValue FROM #TEMP1 WHERE Scoreid BETWEEN (SELECT TOP 1 Scoreid FROM #TEMP1 WHERE 
				BreakTrendNo=@Cnt ORDER BY Scoreid) AND (SELECT TOP 1 Scoreid FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid DESC)
				
				SET @SUM_XI=(SELECT SUM(XVal) FROM #TREND) --SUM(xi)
				SET @SUM_YI=(SELECT SUM(Score) FROM #TREND) --SUM(yi)
				SET @SUM_XX=(SELECT SUM(XVal*XVal) FROM #TREND) --SUM(xi*xi)
				SET @SUM_XY=(SELECT SUM(XVal*Score) FROM #TREND) --SUM(xi*yi)

				--A*(SELECT COUNT(*) FROM #LEAST)+B*@SUM_XI=@SUM_YI --(a*M+b*SUM(xi)=SUM(yi))
				--A*@SUM_XI+B*@SUM_XX=@SUM_XY --(a*SUM(xi)+b*SUM(xi*xi)=SUM(xi*yi))

				SET @X1=(SELECT COUNT(ID) FROM #TREND)
				SET @Y1=@SUM_XI
				SET @Z1=@SUM_YI
				SET @X2=@SUM_XI
				SET @Y2=@SUM_XX
				SET @Z2=@SUM_XY

				--SLOPE CALCULATION (@B)
				IF((@Y1*@X2)>(@Y2*@X1))
				BEGIN
					SET @B=((@Z1*@X2)-(@Z2*@X1))/((@Y1*@X2)-(@Y2*@X1))
				END
				ELSE IF((@Y1*@X2)<(@Y2*@X1))
				BEGIN
					SET @B=((@Z2*@X1)-(@Z1*@X2))/((@Y2*@X1)-(@Y1*@X2))
				END
				
				SET @A=(@SUM_YI-(@B*@SUM_XI))/@X1 --Y INTERCEPT (@A)
				--Y=@Bx+@A
				SET @Ids=(SELECT TOP 1 XValue FROM #TEMP1 WHERE BreakTrendNo=@Cnt ORDER BY Scoreid) --FIRST x value
				SET @IdOfTrend=(SELECT TOP 1 Scoreid FROM #TREND ORDER BY Id)
				WHILE(@IdOfTrend<=(SELECT MAX(Scoreid) FROM #TREND))
				BEGIN	
					UPDATE #TEMP1 SET Trend=((@B*@Ids)+@A) WHERE Scoreid=@IdOfTrend
					SET @IdOfTrend=@IdOfTrend+1
					SET @Ids=@Ids+1
				END	

				DROP TABLE #TREND
			END	
			SET @NumOfTrend=@NumOfTrend-1
		END	
	END


	------------------------------- Trend End--------------------------------


	----///////////////////NEW CHANGE FOR TWO Y AXIS/////////////////////
	
	
	CREATE TABLE #TMPLP(ID int NOT NULL IDENTITY(1,1),LessonPlanId int,CalcType varchar(50));

	CREATE NONCLUSTERED INDEX idx_tmplp_lessonplanid ON #TMPLP (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_tmplp_calctype ON #TMPLP (CalcType);

	INSERT INTO #TMPLP SELECT DISTINCT LessonPlanId,CalcType FROM #TEMP1 WHERE CalcType<>'Event' ORDER BY CalcType
	CREATE TABLE #TMPLPCNT(ID int NOT NULL IDENTITY(1,1),LessonPlanId int,CalcTypeCNT INT);

	CREATE NONCLUSTERED INDEX idx_tmplpcnt_lessonplanid ON #TMPLPCNT (LessonPlanId);

	INSERT INTO #TMPLPCNT SELECT LessonPlanId,COUNT(1) AS CNT FROM #TMPLP GROUP BY LessonPlanId

	SET @TMPCount=(SELECT COUNT(ID) FROM #TMPLPCNT)
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
				WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
				
				UPDATE #TEMP1 SET RightYaxis=(SELECT STUFF((SELECT '/ '+ RptLabel FROM (SELECT DISTINCT RptLabel FROM #TEMP1 TMP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
				'Avg Duration','Customize') AND TMP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND (SELECT COUNT(*) FROM #TEMP1 TP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
				'Avg Duration','Customize') AND TP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>0) LP FOR XML PATH('')),1,1,''))
				WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
				
				UPDATE #TEMP1 SET LeftYaxis=(CASE WHEN LeftYaxis IS NULL THEN RightYaxis ELSE LeftYaxis END )  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
				UPDATE #TEMP1 SET RightYaxis=(CASE WHEN LeftYaxis=RightYaxis THEN NULL ELSE RightYaxis END )  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
				
				IF((SELECT COUNT(*) FROM #TEMP1 WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
				'Avg Duration','Customize') AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>=2)
				BEGIN
				
					UPDATE #TEMP1 SET LeftYaxis='Percent'  WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
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
				LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)  ORDER BY ID) AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)) 
				WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
				
				UPDATE #TEMP1 SET RightYaxis=(SELECT TOP 1 RptLabel FROM #TEMP1 WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE 
				LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) ORDER BY ID DESC ) AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)) 
				WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
			
			END
			ELSE
			BEGIN
				UPDATE #TEMP1 SET LeftYaxis=(SELECT TOP 1 RptLabel FROM #TEMP1 WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE 
				LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) ) AND LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)) 
				WHERE LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount) AND CalcType<>'Event'
			END
		END---
		SET @TMPLoopCount=@TMPLoopCount+1
		SET @TMPCount=@TMPCount-1
	END

	DROP TABLE #TMPLPCNT
	DROP TABLE #TMPLP
	--/////////////////////////////////////////////////////////////////


	------------- Coloring Fix start---------------------

	SET @CNTLP=1
	SET @ColRptLabelLP=''

	CREATE TABLE #COLORING (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),Lessonplanid int,ColRptLabelLP VARCHAR(500),Rownum int);

	CREATE NONCLUSTERED INDEX idx_coloring_lessonplanid ON #COLORING (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_coloring_colrptlabellp ON #COLORING (ColRptLabelLP);

	INSERT INTO #COLORING(Lessonplanid,ColRptLabelLP)
	SELECT DISTINCT LessonPlanId,CalcRptLabelLP  FROM #TEMP1 WHERE CalcRptLabelLP IS NOT NULL

	;WITH T
     AS (SELECT Rownum, Row_number() OVER (PARTITION BY Lessonplanid ORDER BY Lessonplanid ) AS RN FROM   #COLORING)
	UPDATE T
	SET Rownum = RN 	

	DECLARE db_cursor CURSOR FOR  
	SELECT ColRptLabelLP,Rownum
		 FROM #COLORING   
	  
	OPEN db_cursor;    
	  
	FETCH NEXT FROM db_cursor  
	INTO @ColRptLabelLP, @TMPCount; 	  

	WHILE @@FETCH_STATUS = 0   
	BEGIN 
		IF(@TMPCount=1)
		BEGIN
			SET @CNTLP=1
			UPDATE #TEMP1 SET Color='Blue' WHERE CalcRptLabelLP=@ColRptLabelLP
		END
		ELSE IF(@TMPCount=2)
		BEGIN
			UPDATE #TEMP1 SET Color='Red' WHERE CalcRptLabelLP=@ColRptLabelLP
		END
		ELSE
		BEGIN
			UPDATE #TEMP1 SET Color='Black' WHERE CalcRptLabelLP=@ColRptLabelLP
		END
		UPDATE #TEMP1 SET Shape=(SELECT Shape FROM Color WHERE ColorId=@CNTLP) WHERE CalcRptLabelLP=@ColRptLabelLP

		SET @CNTLP=@CNTLP+1
		FETCH NEXT FROM db_cursor INTO @ColRptLabelLP , @TMPCount;
	END   

	CLOSE db_cursor   
	DEALLOCATE db_cursor

	DROP TABLE #COLORING

	------------------- Coloring fix end ------------------------

	CREATE TABLE #COMBINE(ID int NOT NULL PRIMARY KEY IDENTITY(1,1),LessonPlanId int,Rownum int,SessionDate datetime)
	INSERT INTO #COMBINE
	SELECT DISTINCT LessonPlanId,Rownum,SessionDate FROM #TEMP1 WHERE CalcType='Event' and ArrowNote is not  null and EventType='Arrow notes' GROUP BY LessonPlanId,Rownum,SessionDate

	SET @CNT=1
	SET @CNTLP=(SELECT COUNT(ID) FROM #COMBINE)

	WHILE(@CNTLP>0)
	BEGIN
		SET @LPid=(SELECT LessonPlanId FROM #COMBINE WHERE ID=@CNT)
		SET @Rowcnt=(SELECT Rownum FROM #COMBINE WHERE ID=@CNT)
		SET @dateCurr=(SELECT CONVERT(DATE,SessionDate) FROM #COMBINE WHERE ID=@CNT) 

		UPDATE #TEMP1 SET EventName=
		(SELECT FORMAT(CONVERT(DATE,@dateCurr),'MM/dd')+','+ STUFF((SELECT  ', '+ EventName  FROM (SELECT EventName  FROM #TEMP1
		WHERE LessonPlanId=@LPid AND Rownum=@Rowcnt AND CONVERT(DATE,SessionDate) =@dateCurr AND CalcType='Event' and ArrowNote is not null and EventType='Arrow notes'
		) LP FOR XML PATH('')),1,1,''))
		WHERE LessonPlanId=@LPid AND Rownum=@Rowcnt AND CONVERT(DATE,SessionDate)=@dateCurr AND CalcType='Event' and ArrowNote is not null and EventType='Arrow notes'
		SET @CNT=@CNT+1
		SET @CNTLP=@CNTLP-1
	END
	DROP TABLE #COMBINE

	-----------------------update #TEMP1 with score1 and score2------------------------	

	CREATE TABLE #TEMPSCORE (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), LessonPlanId INT, Rownum INT, SessionDate DATE)
	INSERT INTO #TEMPSCORE SELECT DISTINCT LessonPlanId, Rownum, SessionDate FROM #TEMP1 WHERE CalcType='Event' 
	SET @CNT=1
	SET @EVNTCNT=(SELECT COUNT(ID) FROM #TEMPSCORE)
	WHILE(@EVNTCNT>0)
	BEGIN
		SET @RNUM=(SELECT Rownum FROM  #TEMPSCORE WHERE ID=@CNT)
		SET @LPid=(SELECT LessonPlanId FROM #TEMPSCORE WHERE ID=@CNT)	
		SET @dateCurr=(SELECT CONVERT(DATE,SessionDate) FROM #TEMPSCORE WHERE ID=@CNT)
		CREATE TABLE #TEMPCALCRPT (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),CalcRptLabelLP VARCHAR(200))
		INSERT INTO #TEMPCALCRPT SELECT CalcRptLabelLP FROM #TEMP1 WHERE CONVERT(DATE,SessionDate)=@dateCurr AND Rownum=@RNUM and LessonPlanId=@LPid and CalcRptLabelLP is not null
		SET @CLCNT=1
		SET @RPTCNT=(SELECT COUNT(ID) FROM #TEMPCALCRPT)
		WHILE(@RPTCNT>0)
		BEGIN
			SET @CalcRpt=(SELECT CalcRptLabelLP FROM #TEMPCALCRPT WHERE ID=@CLCNT)

			UPDATE #TEMP1 SET Score1=Score, Score2=DummyScore WHERE Rownum=@RNUM AND LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRpt
			
			SET @PScore=(SELECT Score FROM  #TEMP1 WHERE Rownum=@RNUM AND LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRpt AND Score IS NOT NULL)
			SET @PDummy=(SELECT DummyScore FROM  #TEMP1 WHERE Rownum=@RNUM AND LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRpt AND DummyScore IS NOT NULL)

			UPDATE #TEMP1 SET Score1=Score, Score2=DummyScore, PreScore=@PScore, PreDummy=@PDummy WHERE Rownum=@RNUM+1 AND LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRpt

			SET @CLCNT=@CLCNT+1
			SET @RPTCNT=@RPTCNT-1
		END
		DROP TABLE #TEMPCALCRPT

		CREATE TABLE #TEMPEXCEPTCALCRPT (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),CalcRptLabelLP VARCHAR(200))
		INSERT INTO #TEMPEXCEPTCALCRPT SELECT CalcRptLabelLP FROM #TEMP1 WHERE Rownum=@RNUM+1 and CalcRptLabelLP not IN (SELECT CalcRptLabelLP FROM #TEMP1 
			WHERE CONVERT(DATE,SessionDate)=@dateCurr AND Rownum=@RNUM and CalcRptLabelLP is not null) AND CalcRptLabelLP IS NOT NULL AND LessonPlanId=@LPid
		SET @CLCNT=1
		SET @RPTCNT=(SELECT COUNT(ID) FROM #TEMPEXCEPTCALCRPT)
		WHILE(@RPTCNT>0)
		BEGIN
			SET @CalcRpt=(SELECT CalcRptLabelLP FROM #TEMPEXCEPTCALCRPT WHERE ID=@CLCNT)
			SET @PScore=(SELECT TOP 1 Score FROM  #TEMP1 WHERE Rownum=@RNUM AND LessonPlanId=@LPid AND Score IS NOT NULL)
			SET @PDummy=(SELECT TOP 1 DummyScore FROM  #TEMP1 WHERE Rownum=@RNUM AND LessonPlanId=@LPid AND DummyScore IS NOT NULL)

			UPDATE #TEMP1 SET Score1=Score, Score2=DummyScore, PreScore=@PScore, PreDummy=@PDummy WHERE Rownum=@RNUM+1 AND LessonPlanId=@LPid AND CalcRptLabelLP=@CalcRpt

			SET @CLCNT=@CLCNT+1
			SET @RPTCNT=@RPTCNT-1
		END
		DROP TABLE #TEMPEXCEPTCALCRPT

		SET @CNT=@CNT+1
		SET @EVNTCNT=@EVNTCNT-1
	END
	DROP TABLE #TEMPSCORE
	--------------------------------------END----------------------------------------------	

	-----------------------------UPDATE IOAPerc WITH NORMALUSER AND IOA USER NAME------------------------------------

		CREATE TABLE #TEMPIOA (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), LessonPlanId INT, IOAPerc VARCHAR(50), StdtSessionHdrId INT)
		INSERT INTO #TEMPIOA SELECT LessonPlanId, IOAPerc, StdtSessionHdr FROM #TEMP1 WHERE IOAPerc IS NOT NULL ORDER BY LessonPlanId, StdtSessionHdr
		SET @CNT=1
		SET @IOACNT=(SELECT COUNT(ID) FROM #TEMPIOA)
		WHILE(@IOACNT>0)
		BEGIN
			SET @LPid =(SELECT LessonPlanId FROM #TEMPIOA WHERE ID=@CNT)
			SET @HdrId =(SELECT StdtSessionHdrId FROM #TEMPIOA WHERE ID=@CNT)
			SET @IOAPer =(SELECT IOAPerc FROM #TEMPIOA WHERE ID=@CNT)

			UPDATE #TEMP1 SET IOAPerc=@IOAPer+' '+ (SELECT RTRIM(LTRIM(UPPER(US.UserInitial))) AS IOALUser FROM StdtSessionHdr HDR INNER JOIN [USER] US ON HDR.IOAUserId = US.UserId 
				WHERE StdtSessionHdrId=@HdrId and IOAInd='N' AND LessonPlanId=@LPid AND StudentId=@StudentId)+'/'+(SELECT RTRIM(LTRIM(UPPER(US.UserInitial))) AS NormalLUser FROM StdtSessionHdr HDR 
				INNER JOIN [USER] US ON HDR.IOAUserId = US.UserId WHERE IOASessionHdrId=@HdrId and IOAInd='Y' AND LessonPlanId=@LPid AND StudentId=@StudentId)  
				WHERE StdtSessionHdr=@HdrId AND LessonPlanId=@LPid 
			if ((select Score from #TEMP1 WHERE StdtSessionHdr=@HdrId AND LessonPlanId=@LPid and scoreid=(select top (1) Scoreid from #TEMP1 where StdtSessionHdr=@HdrId AND LessonPlanId=@LPid)) is not null
			or (select DummyScore from #TEMP1 WHERE StdtSessionHdr=@HdrId AND LessonPlanId=@LPid and scoreid=(select top (1) Scoreid from #TEMP1 where StdtSessionHdr=@HdrId AND LessonPlanId=@LPid)) is not null)
				Update #TEMP1 set IOAPerc=NULL WHERE StdtSessionHdr=@HdrId AND LessonPlanId=@LPid and scoreid not in (select top (1) Scoreid from #TEMP1 where StdtSessionHdr=@HdrId AND LessonPlanId=@LPid)

			SET @CNT=@CNT+1
			SET @IOACNT=@IOACNT-1
		END
		DROP TABLE #TEMPIOA
	-----------------------------------------------END-------------------------------------------

	----------------------------------------UPDATE MaxScore and MaxDummyScore-------------------------------------------------
	CREATE TABLE #MAXSCORE(ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), LessonId INT)
	INSERT INTO #MAXSCORE SELECT DISTINCT LessonPlanId FROM #TEMP1
	DECLARE @MaxScore FLOAT, @MaxDummyScore FLOAT

	SET @CNT=1
	SET @LCount=(SELECT COUNT(ID) FROM #MAXSCORE)
	WHILE (@LCount>0)
	BEGIN
		SET @LPid=(SELECT LessonId FROM #MAXSCORE WHERE ID=@CNT)
		SET @MaxScore=(SELECT MAX(Score) FROM #TEMP1 WHERE LessonPlanId=@LPid)
		SET @MaxDummyScore=(SELECT MAX(DummyScore) FROM #TEMP1 WHERE LessonPlanId=@LPid)
		IF (@MaxScore IS NOT NULL OR @MaxDummyScore IS NOT NULL)
			UPDATE #TEMP1 SET MaxScore=@MaxScore, MaxDummyScore=@MaxDummyScore WHERE LessonPlanId=@LPid AND CalcType<>'Event'
		SET @CNT=@CNT+1
		SET @LCount=@LCount-1
	END
	DROP TABLE #MAXSCORE

	---------------------------------------------END---------------------------------------------------------------------------

	SELECT * FROM (	SELECT Scoreid,SessionDate,LessonPlanId,Rownum,CalcType,Score,IOAPerc,ArrowNote,EventType,EventName,CalcRptLabelLP,Trend,DummyScore,LeftYaxis,
		RightYAxis,NonPercntCount,PercntCount,ColName,RptLabel,Color,Shape,Score1,Score2,PreScore,PreDummy,MaxScore,MaxDummyScore
	,(SELECT TOP 1 LessonOrder FROM DSTempHdr WHERE LessonPlanId=#TEMP1.LessonPlanId AND StudentId=@StudentId ORDER BY LessonOrder DESC) LOrder,Rownum as NewRow, arrowupdate
	 FROM #TEMP1) LPO 
	 ORDER BY 
	 Lorder,CalcType,CalcRptLabelLP, Rownum, Scoreid 	
END



GO
