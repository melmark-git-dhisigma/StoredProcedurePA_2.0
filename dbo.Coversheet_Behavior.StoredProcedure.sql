USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Coversheet_Behavior]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Coversheet_Behavior]
@StartDate datetime,
@ENDDate datetime,
@Studentid int,
@SchoolId int

AS
BEGIN

	Declare @tmpTable table (SCOREIDC		INT PRIMARY KEY NOT NULL IDENTITY(1,1),
							MEASUREMENTIDC	INT,
							MAXFREQ			INT,
							MAXDUR			INT,
							FREDELTAXC		INT,
							DURELTAXC		INT,
							FREDELTAYC		FLOAT,
							DURELTAYC		FLOAT)
	
	Insert into @tmpTable
	EXEC	[dbo].Coversheet_Trendline
			@StartDate = @StartDate,
			@ENDDate=@ENDDate, 
			@Studentid=@Studentid,
			@SchoolId=@SchoolId		
	SET NOCOUNT ON;


	DECLARE @CNT INT
	,@LOOP INT
	,@MID INT
	,@BDATE DATETIME
	,@XVAL INT
	,@Behavior VARCHAR(500)
	,@SDATE DATETIME
	,@EDATE DATETIME
	,@PREVMID INT
	,@PREVBHR VARCHAR(500)
	,@SID INT
	,@School INT


	SET @SDate=@StartDate
	SET @EDate=@ENDDate
	SET @SID=@Studentid
	SET @School=@SchoolId


	IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL  
	DROP TABLE #TEMP

	
CREATE TABLE #TEMPBEHAV(Scoreid int PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,BehaveDate DATETIME,Behavior VARCHAR(500),Frequency FLOAT,Duration FLOAT,GoalDesc VARCHAR(MAX),BasPerlvl VARCHAR(MAX),IEPObj VARCHAR(MAX));
CREATE TABLE #TEMP(Scoreid int PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,BehaveDate DATETIME,Behavior VARCHAR(500),Frequency FLOAT,Duration FLOAT,XVal int);

	INSERT INTO #TEMPBEHAV SELECT * FROM (SELECT BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn) BehaviorDate,BDTS.Behaviour,CASE WHEN (BDTS.Frequency=1 AND BDTS.Duration=1) THEN 
	CONVERT(FLOAT,(COUNT(BHR.Duration) + SUM(FrequencyCount)))/CONVERT(FLOAT,(COUNT(BHR.Duration) + COUNT(FrequencyCount))) ELSE CASE WHEN (BDTS.Duration=1)
	THEN CONVERT(FLOAT,1)  ELSE  CONVERT(FLOAT,AVG(FrequencyCount)) END END AS Frequency,(AVG(CONVERT(float,BHR.Duration)))/60 AS DurationMin, BDTS.GoalDesc,BDTS.BehaviorBasPerfLvl,BDTS.BehaviorIEPObjctve FROM Behaviour BHR INNER JOIN BehaviourDetails BDTS ON 
	BHR.MeasurementId=BDTS.MeasurementId WHERE BDTS.StudentId=@SID AND BDTS.ActiveInd='A' AND BDTS.[SchoolId]=@School AND CONVERT(DATE,BHR.CreatedOn) BETWEEN @SDATE 
	AND @EDATE GROUP BY BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn),BDTS.Behaviour,BDTS.Frequency,BDTS.Duration,BDTS.GoalDesc,BDTS.BehaviorBasPerfLvl,BDTS.BehaviorIEPObjctve ) 
	AS BEHAV ORDER BY MeasurementId
	--SELECT * FROM #TEMPBEHAV
	SET @CNT=(SELECT COUNT(*) FROM #TEMPBEHAV)
	SET @LOOP=1
	SET @XVAL=1
	--SET @SDATE=(@SDATE)
	--SET @EDATE=(SELECT @EDATE)
	WHILE(@CNT>0)
	BEGIN
	SELECT @MID=MeasurementId,@BDATE=BehaveDate,@Behavior=Behavior FROM #TEMPBEHAV WHERE Scoreid=@LOOP	
	IF((SELECT TOP 1 MeasurementId FROM #TEMP ORDER BY Scoreid DESC)<>@MID)
	BEGIN
	WHILE(@SDATE<=@EDATE)
	BEGIN
	INSERT INTO #TEMP SELECT @PREVMID,@SDATE,@PREVBHR,NULL,NULL,@XVAL
	SET @SDATE=(SELECT CONVERT(DATE,DATEADD(day,1,@SDATE)))
	SET @XVAL=@XVAL+1
	END
	SET @SDATE=@StartDate
	SET @XVAL=1	
	END
	WHILE(@SDATE<@BDATE)
	BEGIN
	INSERT INTO #TEMP SELECT @MID,@SDATE,@Behavior,NULL,NULL,@XVAL
	SET @SDATE=(SELECT CONVERT(DATE,DATEADD(day,1,@SDATE)))
	SET @XVAL=@XVAL+1
	END
	INSERT INTO #TEMP SELECT MeasurementId,BehaveDate,Behavior,Frequency,Duration,@XVAL FROM #TEMPBEHAV WHERE Scoreid=@LOOP	
	SET @SDATE=(SELECT CONVERT(DATE,DATEADD(day,1,@SDATE)))
	SET @XVAL=@XVAL+1
	SET @LOOP=@LOOP+1
	SET @CNT=@CNT-1
	SET @PREVMID=@MID
	SET @PREVBHR=@Behavior

	IF(@CNT=0)
	BEGIN
	WHILE(@SDATE<=@EDATE)
	BEGIN
	INSERT INTO #TEMP SELECT @PREVMID,@SDATE,@PREVBHR,NULL,NULL,@XVAL
	SET @SDATE=(SELECT CONVERT(DATE,DATEADD(day,1,@SDATE)))
	SET @XVAL=@XVAL+1
	END
	END
	END
	
	

	CREATE TABLE #TEMPBEHAV1(Scoreid int PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,Behaviour VARCHAR(500),FRQDeltaX FLOAT,FRQDeltaY FLOAT
	,FRQSlope FLOAT,DURDeltaX FLOAT,DURDeltaY FLOAT,DURSlope FLOAT,FRQSharpDecrease VARCHAR(1),FRQSlightDecrease VARCHAR(1),FRQStable VARCHAR(10),FRQSlightIncrease VARCHAR(1),FRQSharpIncrease VARCHAR(1),
	DURSharpDecrease VARCHAR(1),DURSlightDecrease VARCHAR(1),DURStable VARCHAR(10),DURSlightIncrease VARCHAR(1),DURSharpIncrease VARCHAR(1),GoalDesc VARCHAR(MAX),BasPerlvl VARCHAR(MAX),IEPObj VARCHAR(MAX),IOAPOINTS VARCHAR(MAX),DAYCOUNT VARCHAR(MAX),MAXY_ValueFRE float,MAXY_ValueDUR float);

	INSERT INTO #TEMPBEHAV1(MeasurementId,Behaviour,GoalDesc,BasPerlvl,IEPObj) 
	SELECT DISTINCT MeasurementId,Behaviour,GoalDesc, BehaviorBasPerfLvl, BehaviorIEPObjctve FROM (SELECT BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn) BehaviorDate,BDTS.Behaviour,CASE WHEN (BDTS.Frequency=1 AND BDTS.Duration=1) THEN 
	CONVERT(FLOAT,(COUNT(BHR.Duration) + SUM(FrequencyCount)))/CONVERT(FLOAT,(COUNT(BHR.Duration) + COUNT(FrequencyCount))) ELSE CASE WHEN (BDTS.Duration=1)
	THEN CONVERT(FLOAT,1)  ELSE  CONVERT(FLOAT,AVG(FrequencyCount)) END END AS Frequency,(AVG(CONVERT(float,BHR.Duration)))/60 AS DurationMin, BDTS.GoalDesc, BDTS.BehaviorBasPerfLvl, BDTS.BehaviorIEPObjctve FROM Behaviour BHR INNER JOIN BehaviourDetails BDTS ON 
	BHR.MeasurementId=BDTS.MeasurementId WHERE BDTS.StudentId=@SID AND BDTS.ActiveInd='A' AND BDTS.[SchoolId]=@School AND  CONVERT(DATE,BHR.CreatedOn) BETWEEN @StartDate 
	AND @ENDDate GROUP BY BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn),BDTS.Behaviour,BDTS.Frequency,BDTS.Duration,BDTS.GoalDesc,BDTS.BehaviorBasPerfLvl,BDTS.BehaviorIEPObjctve ) 
	AS BEHAV ORDER BY MeasurementId

	SET @CNT=(SELECT COUNT(*) FROM #TEMPBEHAV1)
	SET @LOOP=1
	DECLARE @FREQ FLOAT, @YesNo INT, @DUR FLOAT, @DAYCOUNT INT
	WHILE(@LOOP<=@CNT)
	BEGIN
		SELECT @MID=MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP
		SELECT @FREQ=Frequency,@YesNo=YesOrNo,@DUR=Duration  FROM BehaviourDetails WHERE MeasurementId=@MID
		IF (@FREQ = 1 OR @YesNo = 1)
		BEGIN
		UPDATE #TEMPBEHAV1 
		set MAXY_ValueFRE=(select MAXFREQ from @tmpTable  WHERE MEASUREMENTIDC=@MID) WHERE MeasurementId=@MID 
		END
		IF (@DUR = 1)
		BEGIN
		UPDATE #TEMPBEHAV1 
		set MAXY_ValueDUR=(select MAXDUR from @tmpTable  WHERE MEASUREMENTIDC=@MID) WHERE MeasurementId=@MID 		
		END
		SET @LOOP=@LOOP+1
	END

	SET @CNT=(SELECT COUNT(*) FROM #TEMPBEHAV1)
	SET @LOOP=1
	WHILE(@CNT>0)
	BEGIN
	IF((SELECT COUNT(*) FROM #TEMPBEHAV WHERE MeasurementId=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP))>1)
	BEGIN



	UPDATE #TEMPBEHAV1 
	SET FRQDeltaY=(Select FREDELTAYC from @tmpTable	where MEASUREMENTIDC=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)) 
	WHERE MeasurementId=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)

	UPDATE #TEMPBEHAV1 
	SET FRQDeltaX=(Select FREDELTAXC from @tmpTable where MEASUREMENTIDC=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)) 
	WHERE MeasurementId=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)	

	UPDATE #TEMPBEHAV1 SET FRQSlope=CASE WHEN FRQDeltaX<>0 THEN ROUND(CONVERT(FLOAT,(FRQDeltaY/FRQDeltaX)),2) ELSE 0 END WHERE Scoreid=@LOOP
	
	UPDATE #TEMPBEHAV1 SET FRQSlope=CASE WHEN FRQDeltaY<>0 THEN(FRQSlope/MAXY_ValueFRE)/(1.776/FRQDeltaX) ELSE 0 END WHERE Scoreid=@LOOP
	
	UPDATE #TEMPBEHAV1 
	SET DURDeltaY=(Select DURELTAYC from @tmpTable where MEASUREMENTIDC=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP))
	WHERE MeasurementId=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)

	UPDATE #TEMPBEHAV1 
	SET DURDeltaX=(Select DURELTAXC from @tmpTable where MEASUREMENTIDC=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)) 
	WHERE MeasurementId=(SELECT MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP)

	 
	UPDATE #TEMPBEHAV1 SET DURSlope=CASE WHEN DURDeltaX<>0 THEN ROUND(CONVERT(FLOAT,(DURDeltaY/DURDeltaX)),2) ELSE 0 END WHERE Scoreid=@LOOP
	
	UPDATE #TEMPBEHAV1 SET DURSlope=CASE WHEN (DURDeltaY<>0 and MAXY_ValueDUR<>0) THEN(DURSlope/(MAXY_ValueDUR/60))/(1.776/DURDeltaX) ELSE 0 END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET FRQSharpDecrease=CASE WHEN FRQSlope<>0 THEN CASE WHEN FRQSlope<= TAN (-15 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET DURSharpDecrease=CASE WHEN DURSlope<>0 THEN CASE WHEN DURSlope<= TAN (-15 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET FRQSlightDecrease=CASE WHEN FRQSlope<>0 THEN CASE WHEN TAN (-15 * (PI() / 180))<FRQSlope AND FRQSlope<= TAN (-2 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET DURSlightDecrease=CASE WHEN DURSlope<>0 THEN CASE WHEN TAN (-15 * (PI() / 180))<DURSlope AND DURSlope<=TAN (-2 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET FRQStable=CASE WHEN TAN (-2 * (PI() / 180))<FRQSlope AND FRQSlope< TAN (2 * (PI() / 180)) THEN 'X' END  WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET DURStable=CASE WHEN TAN (-2 * (PI() / 180))<DURSlope AND DURSlope< TAN (2 * (PI() / 180)) THEN 'X' END  WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET FRQSlightIncrease=CASE WHEN FRQSlope<>0 THEN CASE WHEN TAN (2 * (PI() / 180))<=FRQSlope AND FRQSlope< TAN (15 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET DURSlightIncrease=CASE WHEN DURSlope<>0 THEN CASE WHEN TAN (2 * (PI() / 180))<=DURSlope AND DURSlope< TAN (15 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET FRQSharpIncrease=CASE WHEN FRQSlope<>0 THEN CASE WHEN FRQSlope >= TAN (15 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	UPDATE #TEMPBEHAV1 SET DURSharpIncrease=CASE WHEN DURSlope<>0 THEN CASE WHEN DURSlope >= TAN (15 * (PI() / 180)) THEN 'X' END END WHERE Scoreid=@LOOP

	END
	SET @LOOP=@LOOP+1
	SET @CNT=@CNT-1
	END

	--NEW ADF AND ADD CALCULATION
	--DECLARE @FREQ FLOAT, @YesNo INT, @DUR FLOAT, @DAYCOUNT INT
	SET @CNT=(SELECT COUNT(*) FROM #TEMPBEHAV1)
	SET @LOOP=1
	WHILE(@CNT>0)
	BEGIN
		SELECT @MID=MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP
		SELECT @FREQ=Frequency,@YesNo=YesOrNo,@DUR=Duration  FROM BehaviourDetails WHERE MeasurementId=@MID
		IF (@FREQ = 1 OR @YesNo = 1)
		BEGIN
			SET @FREQ=(SELECT SUM(FrequencyCount) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@StartDate AND CONVERT(DATE,CreatedOn)<=@ENDDate)
			SET @DAYCOUNT=(SELECT COUNT(DISTINCT(CONVERT(DATE,CreatedOn))) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@StartDate AND CONVERT(DATE,CreatedOn)<=@ENDDate)
			UPDATE #TEMPBEHAV1 SET FRQSlope=ROUND((@FREQ/@DAYCOUNT),2) WHERE MeasurementId=@MID
			--PRINT CAST(@DAYCOUNT  as VARCHAR(max))+' -'+CAST(@MID as VARCHAR(max))
		END
		IF (@DUR = 1)
		BEGIN
			SET @DUR=(SELECT SUM(CONVERT(FLOAT, Duration)) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@StartDate AND CONVERT(DATE,CreatedOn)<=@ENDDate)
			SET @DAYCOUNT=(SELECT COUNT(DISTINCT(CONVERT(DATE,CreatedOn))) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@StartDate AND CONVERT(DATE,CreatedOn)<=@ENDDate)
			UPDATE #TEMPBEHAV1 SET DURSlope=ROUND(((@DUR/60)/@DAYCOUNT),2) WHERE MeasurementId=@MID
			--PRINT CAST(@DAYCOUNT  as VARCHAR(max))+' -'+CAST(@MID as VARCHAR(max))
		END
		SET @LOOP=@LOOP+1
		SET @CNT=@CNT-1
	END

	ALTER TABLE #TEMPBEHAV1 
	ALTER COLUMN FRQSlope VARCHAR(50)
	ALTER TABLE #TEMPBEHAV1 
	ALTER COLUMN DURSlope VARCHAR(50)

	
	UPDATE #TEMPBEHAV1 SET FRQSlope=FRQSlope+' ADF' WHERE FRQSlope IS NOT NULL
	UPDATE #TEMPBEHAV1 SET DURSlope=DURSlope+' ADD' WHERE DURSlope IS NOT NULL
	UPDATE #TEMPBEHAV1 SET FRQSlope='No Data In Range' WHERE FRQSlope IS NULL
	UPDATE #TEMPBEHAV1 SET DURSlope='No Data In Range' WHERE DURSlope IS  NULL
	
	SET @CNT=(SELECT COUNT(*) FROM #TEMPBEHAV1)
	SET @LOOP=1
	WHILE(@LOOP<=@CNT)
	BEGIN
		SELECT @MID=MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP
		
	        UPDATE #TEMPBEHAV1 SET FRQStable='N/A',FRQSlope='N/A' WHERE MeasurementId=@MID and MeasurementId in(  select MeasurementId from BehaviourDetails where frequency=0 and StudentId=@SID and YesOrNo=0)
			UPDATE #TEMPBEHAV1 SET DURStable='N/A',DURSlope='N/A' WHERE MeasurementId=@MID and MeasurementId in(  select MeasurementId from BehaviourDetails where Duration=0 and StudentId=@SID)
			
			SET @LOOP= @LOOP+1
			END


	--ALTER TABLE #TEMPBEHAV1 ADD IOAPOINTS VARCHAR(MAX)
	--ALTER TABLE #TEMPBEHAV1 ADD DAYCOUNT VARCHAR(MAX)

	SET @CNT=(SELECT COUNT(*) FROM #TEMPBEHAV1)
	SET @LOOP=1
	WHILE(@LOOP<=@CNT)
	BEGIN
		SELECT @MID=MeasurementId FROM #TEMPBEHAV1 WHERE Scoreid=@LOOP
		
		--PRINT @CNT+@MID+@LOOP
		DECLARE @IOA_VAL VARCHAR(MAX) = (SELECT STUFF ((SELECT TOP 2 '-'+CAST(EvntTs AS VARCHAR(500))+'_'+CAST(EventName AS VARCHAR(500))
										FROM   (SELECT *
												FROM   ((SELECT SE.lessonplanid,
																SE.measurementid,
																SE.stdtsesseventid,
																NULL                              AS StdtSessionHdrId,
																SE.eventname,
																CASE
																  WHEN (SELECT Count(dstemphdrid)
																		FROM   dstemphdr DH
																			   LEFT JOIN lookup LU
																					  ON DH.statusid = LU.lookupid
																		WHERE  lessonplanid = SE.lessonplanid
																			   AND studentid = SE.studentid
																			   AND lookupname IN (
																				   'Approved', 'Maintenance' )
																			   AND lookuptype = 'TemplateStatus') > 0
																THEN
																  (SELECT TOP 1 dstemplatename
																   FROM   dstemphdr DH
																  LEFT JOIN lookup LU
																		 ON DH.statusid = LU.lookupid
																  WHERE
																  lessonplanid = SE.lessonplanid
																  AND studentid = SE.studentid
																  AND lookupname IN ( 'Approved', 'Maintenance' )
																  AND lookuptype = 'TemplateStatus'
																  ORDER  BY
																  DH.dstemphdrid DESC)
																  ELSE (SELECT TOP 1 dstemplatename
																		FROM   dstemphdr
																		WHERE  lessonplanid = SE.lessonplanid
																			   AND studentid = SE.studentid
																		ORDER  BY dstemphdrid DESC)
																END                               LessonPlanName,
																SE.stdtsesseventtype,
																SE.comment,
																CONVERT(CHAR(10), SE.evntts, 101) AS EvntTs,
																CASE
																  WHEN SE.createdon IS NULL THEN SE.evntts
																  ELSE SE.createdon
																END                               AS CreatedOn,
																SE.modifiedon,
																NULL                              AS BehaviorIOAId,
																B.behaviour
														 FROM   [stdtsessevent] SE
																LEFT JOIN lessonplan L
																	   ON SE.lessonplanid = L.lessonplanid
																LEFT JOIN behaviourdetails B
																	   ON B.measurementid = SE.measurementid
														 WHERE  eventtype = 'EV'
																AND SE.studentid = 1316
																AND SE.stdtsesseventtype <> 'Medication')
														UNION ALL
														(SELECT SH.lessonplanid,
																NULL                                  AS MeasurementId,
																NULL                                  AS StdtSessEventId
																,
																stdtsessionhdrid,
																'IOA '
																+ CONVERT(NVARCHAR, Round(ioaperc, 0), 0) + '% ' + (
																(SELECT Rtrim(Ltrim(Upper(userinitial)))
																 FROM   [user] US
																 WHERE  US.userid = (SELECT
																		createdby
																					 FROM
																		stdtsessionhdr Hdr
																					 WHERE
																		Hdr.stdtsessionhdrid = SH.ioasessionhdrid
																		AND SH.ioaind = 'Y'))
																+ '/'
																+ (SELECT Rtrim(Ltrim(Upper(userinitial)))
																   FROM   [user] US
																   WHERE  SH.ioauserid = US.userid) ) AS EventName,
																CASE
																  WHEN (SELECT Count(dstemphdrid)
																		FROM   dstemphdr DH
																			   LEFT JOIN lookup LU
																					  ON DH.statusid = LU.lookupid
																		WHERE  lessonplanid = SH.lessonplanid
																			   AND studentid = SH.studentid
																			   AND lookupname IN (
																				   'Approved', 'Maintenance' )
																			   AND lookuptype = 'TemplateStatus') > 0
																THEN
																  (SELECT TOP 1 dstemplatename
																   FROM   dstemphdr DH
																  LEFT JOIN lookup LU
																		 ON DH.statusid = LU.lookupid
																  WHERE
																  lessonplanid = SH.lessonplanid
																  AND studentid = SH.studentid
																  AND lookupname IN ( 'Approved', 'Maintenance' )
																  AND lookuptype = 'TemplateStatus'
																  ORDER  BY
																  DH.dstemphdrid DESC)
																  ELSE (SELECT TOP 1 dstemplatename
																		FROM   dstemphdr
																		WHERE  lessonplanid = SH.lessonplanid
																			   AND studentid = SH.studentid
																		ORDER  BY dstemphdrid DESC)
																END                                   LessonPlanName,
																'Arrow notes'                         AS
																StdtSessEventType,
																SH.comments                           AS Comment,
																CONVERT(CHAR(10), SH.endts, 101)      AS EvntTs,
																SH.createdon,
																SH.modifiedon,
																NULL                                  AS BehaviorIOAId,
																NULL                                  AS Behaviour
														 FROM   stdtsessionhdr SH
																LEFT JOIN lessonplan
																	   ON SH.lessonplanid = lessonplan.lessonplanid
														 WHERE  SH.ioaperc IS NOT NULL
																AND SH.ioaind = 'Y'
																AND SH.sessionstatuscd = 'S'
																AND SH.studentid = 1316)
														UNION ALL
														(SELECT NULL                                   AS LessonPlanId,
																BIOA.measurementid,
																NULL                                   AS
																StdtSessEventId,
																NULL                                   AS
																StdtSessionHdrId,
																'IOA '
																+ CONVERT(NVARCHAR, Round(ioaperc, 0), 0) + '% '
																+ CASE WHEN BIOA.normalbehaviorid IS NULL THEN ((SELECT
																TOP 1
																Rtrim(
																Ltrim(Upper(
																US.userinitial))) FROM behaviour BH INNER JOIN [user] US
																ON
																BH.createdby
																=
																US.userid WHERE BH.createdon BETWEEN
																Dateadd(minute, -5, BIOA.createdon)
																AND
																BIOA.createdon ORDER BY BH.createdon DESC)+'/'+ (SELECT
																TOP 1
																Rtrim(Ltrim(Upper(US.userinitial))) FROM
																behaviorioadetails BI
																INNER
																JOIN [user]
																US ON BI.createdby =
																US.userid WHERE BI.createdon=BIOA.createdon ORDER BY
																BI.createdon DESC)
																)
																ELSE ((
																SELECT
																Rtrim(Ltrim(Upper(US.userinitial))) FROM behaviour BH
																INNER
																JOIN [user]
																US ON
																BH.createdby = US.userid WHERE
																BIOA.normalbehaviorid=BH.behaviourid)+'/'+ (
																SELECT Rtrim(
																Ltrim(Upper(US.userinitial))) FROM behaviorioadetails BI
																INNER
																JOIN
																[user] US ON
																BI.createdby = US.userid INNER JOIN behaviour BH ON
																BH.behaviourid=BI.normalbehaviorid WHERE
																BIOA.normalbehaviorid=BH.behaviourid))
																END                                    AS EventName,
																NULL                                   AS LessonPlanName
																,
																'Arrow notes'
																AS StdtSessEventType,
																NULL                                   AS Comment,
																CONVERT(CHAR(10), BIOA.createdon, 101) AS EvntTs,
																BIOA.createdon,
																BIOA.modifiedon,
																BIOA.behaviorioaid,
																BHD.behaviour
														 FROM   behaviorioadetails BIOA
																LEFT JOIN behaviourdetails BHD
																	   ON BIOA.measurementid = BHD.measurementid
														 WHERE  BIOA.studentid = @Studentid
																AND ioaperc IS NOT NULL
																AND BIOA.activeind = 'A'))IOA) ad
										WHERE  ( ( ad.behaviour IS NULL
												   AND ad.measurementid = 0 )
												  OR ad.behaviour IN(SELECT behaviour
																	 FROM   behaviourdetails
																	 WHERE  studentid = @Studentid) )
											   AND ad.stdtsesseventtype IN( 'Arrow notes' ) AND MeasurementId = @MID
											   --AND Convert(date,ad.EvntTs)>= @StartDate AND Convert(date,ad.EvntTs)<= @ENDDate
										ORDER  BY ad.createdon DESC FOR XML PATH('')), 1, 1, ''))

			
			UPDATE #TEMPBEHAV1 SET IOAPOINTS = @IOA_VAL WHERE MeasurementId = @MID

			--SELECT COUNT(MeasurementId) AS DayCount FROM #TEMPBEHAV WHERE  MeasurementId = @MID  GROUP BY MeasurementId
			--SELECT COUNT(MeasurementId) AS DayCount,MeasurementId FROM #TEMPBEHAV GROUP BY MeasurementId
			UPDATE #TEMPBEHAV1 SET DAYCOUNT = CAST((SELECT COUNT(MeasurementId) FROM #TEMPBEHAV WHERE  MeasurementId = @MID /*AND (Frequency>0 OR Duration>0)*/  GROUP BY MeasurementId) AS VARCHAR(MAX))+' days' WHERE MeasurementId = @MID AND (FRQSlope IS NOT NULL OR DURSlope IS NOT NULL)
			UPDATE  #TEMPBEHAV1 SET DAYCOUNT=DAYCOUNT+'- Too few for Trends' where DAYCOUNT='1 days'
		SET @LOOP += 1
	END


	
	--=======================================================

	SELECT * FROM #TEMPBEHAV1
	DROP TABLE #TEMPBEHAV
	DROP TABLE #TEMPBEHAV1
	DROP TABLE #TEMP

	--SELECT TAN (-15 * (PI() / 180)),TAN (-2 * (PI() / 180)),TAN (2 * (PI() / 180)),TAN (15 * (PI() / 180)),TAN (15 * (PI() / 180))
	
	

END


GO
