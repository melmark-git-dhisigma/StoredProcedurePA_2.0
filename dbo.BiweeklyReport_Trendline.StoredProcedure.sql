USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[BiweeklyReport_Trendline]    Script Date: 7/4/2025 1:21:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



alter PROCEDURE [dbo].[BiweeklyReport_Trendline]
@StartDate DATETIME,
@ENDDate DATETIME,
@StudentId INT,
@SchoolId INT,
@LessonPlanid VARCHAR(MAX),
@Trendtype VARCHAR(50),
@Event VARCHAR(50),
--@LPStatus VARCHAR(50),
@ClsType VARCHAR(50),
@IncludeIOA VARCHAR(5)

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @TempStartDate datetime
	SET @TempStartDate=@StartDate
	DECLARE @TempENDDate datetime
	SET @TempENDDate=@ENDDate
	DECLARE @TempStudentid int
	SET @TempStudentid=@Studentid
	DECLARE @TempSchoolId int
	SET @TempSchoolId=@SchoolId
	DECLARE @TempLessonPlanid VARCHAR(MAX)
	SET @TempLessonPlanid=@LessonPlanid
	DECLARE @TempTrendtype VARCHAR(50)
	SET @TempTrendtype=@Trendtype
	DECLARE @TempEvent VARCHAR(50)
	SET @TempEvent=@Event
	DECLARE @TempClsType VARCHAR(50)
	SET @TempClsType=@ClsType
	DECLARE @TempIncludeIOA VARCHAR(5)
	SET @TempIncludeIOA=@IncludeIOA

	DECLARE @ARROWCNT INT,
	@ARROWID INT,
	@CNTLP INT,
	@LCount INT,
	@CalcType VARCHAR(50),
	@LoopLessonPlan INT,
	@ClassType VARCHAR(50),
	@Cnt INT,
	@Score INT,
	@Scoreid INT,
	@Nullcnt INT,
	@Breaktrendid INT,
	@NumOfTrend INT,
	@TrendsectionNo INT,
	@DateCnt INT,
	@Midrate1 FLOAT,
	@Midrate2 FLOAT,
	@Slope FLOAT,
	@Const FLOAT,
	@Ids INT,
	@IdOfTrend INT,
	@SUM_XI FLOAT,
	@SUM_YI FLOAT,
	@SUM_XX FLOAT,
	@SUM_XY FLOAT,
	@X1 FLOAT,
	@Y1 FLOAT,
	@Z1 FLOAT,
	@X2 FLOAT,
	@Y2 FLOAT,
	@Z2 FLOAT,
	@A FLOAT,
	@B FLOAT,
	@TMPLessonPlan INT,
	@TMPCalcType VARCHAR(50),
	@TMPClassType VARCHAR(50),
	@TMPDate DATETIME,
	@TMPStartDate DATETIME,
	@TMPCount INT,
	@TMPLoopCount INT,
	@TMPSesscnt INT,
	@Calc VARCHAR(50),
	@LessonPlanOld INT,
	@ClassOld VARCHAR(50),
	@OldTMPDate DATETIME,
	@RPTLabelOld VARCHAR(500),
	@RPTLabel VARCHAR(500),
	@ColRptLabelLPOld VARCHAR(500),
	@ColRptLabelLP VARCHAR(500),
	@RptLbl VARCHAR(500),
	@LessId INT,
	@TopColNam VARCHAR(500)
	SET @TempENDDate=@TempENDDate+ ' 23:59:59.900'
	SET @LCount=0
	SET @CalcType=''
	SET @LoopLessonPlan=0
	SET @ClassType=''
	SET @Cnt=1
	SET @Scoreid=0
	SET @Nullcnt=0
	SET @Breaktrendid=1
	SET @NumOfTrend=0
	SET @TrendsectionNo=0
	SET @TMPLessonPlan =0
	SET @TMPCalcType=''
	SET @TMPClassType =''
	SET @TMPStartDate= @TempStartDate
	SET @TMPCount=0
	SET @TMPLoopCount=1
	SET @TMPSesscnt=1
	SET @Calc=''
	SET @LessonPlanOld=0
	SET @ClassOld=''
	SET @TopColNam=''

	DECLARE @LSID TABLE (LSID INT)
	INSERT INTO @LSID(LSID) SELECT * FROM Split(@TempLessonPlanid,',') OPTION (MAXRECURSION 500)
	--DECLARE @LStat TABLE (LStat VARCHAR(50))
	--INSERT INTO @LStat(LStat) SELECT * FROM Split(@LPStatus,',')
	DECLARE @EVNT TABLE (EVNT VARCHAR(50))
	INSERT INTO @EVNT(EVNT) SELECT * FROM Split(@TempEvent,',')


	DECLARE @ClassTypeFlag VARCHAR(30)

		IF( @ClsType = 'Day' )
			BEGIN
				SET @ClassTypeFlag = '0'
			END
		ELSE IF ( @ClsType = 'Residence' )
			BEGIN
				SET @ClassTypeFlag = '1'
			END
		ELSE
			BEGIN
				SET @ClassTypeFlag = '0,1'
		END


	  --=============[ New Section for Batch dynamic Updation - Start ] =================================================================================================================
      DECLARE @Counts INT

      IF Object_id('tempdb..#Temp_StdtAggscores') IS NOT NULL
        DROP TABLE #temp_stdtaggscores

      CREATE TABLE #temp_stdtaggscores
        (
           [stdtaggscoreid]     [INT] IDENTITY(1, 1) NOT NULL,
           [schoolid]           [INT] NULL,
           [classid]            [INT] NULL,
           [studentid]          [INT] NULL,
           [dstempsetcolcalcid] [INT] NULL,
           [lessonplanid]       [INT] NULL,
           [calctype]           [VARCHAR](50) NULL,
           [classtype]          [VARCHAR](50) NULL,
           [score]              [FLOAT] NULL,
           [aggredateddate]     [DATETIME] NULL,
           [stdtsesseventid]    [INT] NULL,
           [eventname]          [VARCHAR](500) NULL,
           [ioaperc]            [VARCHAR](50) NULL,
           [measurementid]      [INT] NULL,
           [frequency]          [INT] NULL,
           [duration]           [FLOAT] NULL,
           [rate]               [FLOAT] NULL,
           [ioauser]            [INT] NULL,
           [ioafrequency]       [VARCHAR](50) NULL,
           [ioaduration]        [VARCHAR](50) NULL,
           [colrptlabellp]      [VARCHAR](max) NULL,
		   [collabel]           [VARCHAR](max) NULL)
      ON [PRIMARY]
      textimage_on [PRIMARY]

      --===========================================================================--
      -- TO INSERT DATA TO [dbo].#Temp_StdtAggscores TABLE FROM [dbo].[StdtSessColScore]
      --===========================================================================--
      INSERT INTO #temp_stdtaggscores
                  (schoolid,
                   studentid,
                   dstempsetcolcalcid,
                   aggredateddate,
                   lessonplanid,
                   calctype,
                   score,
                   classid,
                   classtype,
                   colrptlabellp,
				   collabel)
      SELECT schoolid,
             studentid,
             dstempsetcolcalcid,
             reportperiod.perioddate,
             lessonplanid,
             calctype,
             CASE
               WHEN calctype = 'Total Duration'
                     OR calctype = 'Frequency'
                     OR calctype = 'Total Correct'
                     OR calctype = 'Total Incorrect' THEN (SELECT Sum(sc.score)
                                                           FROM
               stdtsesscolscore sc
               INNER JOIN stdtsessionhdr
                          Hdr
                       ON Hdr.stdtsessionhdrid = sc.stdtsessionhdrid
               INNER JOIN class Cls
                       ON Cls.classid = Hdr.stdtclassid
               JOIN dstempsetcolcalc dcal
                 ON dcal.dstempsetcolcalcid = sc.dstempsetcolcalcid
                                                           WHERE
               sc.schoolid = StdCalcs.schoolid
               AND sc.studentid = StdCalcs.studentid
               AND sc.dstempsetcolcalcid = StdCalcs.dstempsetcolcalcid
               AND CONVERT(DATE, Hdr.endts) = CONVERT(DATE,
                                              reportperiod.perioddate)
               AND Hdr.lessonplanid = StdCalcs.lessonplanid
               AND dcal.calctype = StdCalcs.calctype
               AND Hdr.stdtclassid = StdCalcs.stdtclassid
               AND Hdr.ioaind = 'N'
               AND Hdr.sessmisstrailstus = 'N'
               AND Hdr.sessionstatuscd = 'S'
               AND sc.score >= 0
               AND Hdr.ismaintanace = 0
			   AND Cls.residenceind IN (SELECT data
				   FROM   Split(@ClassTypeFlag, ',')))
               ELSE (SELECT Avg(sc.score)
                     FROM   stdtsesscolscore sc
                            INNER JOIN stdtsessionhdr Hdr
                                    ON
                            Hdr.stdtsessionhdrid = sc.stdtsessionhdrid
                            INNER JOIN class Cls
                                    ON Cls.classid = Hdr.stdtclassid
                            JOIN dstempsetcolcalc dcal
                              ON dcal.dstempsetcolcalcid = sc.dstempsetcolcalcid
                     WHERE  sc.schoolid = StdCalcs.schoolid
                            AND sc.studentid = StdCalcs.studentid
                            AND
                    sc.dstempsetcolcalcid = StdCalcs.dstempsetcolcalcid
                            AND CONVERT(DATE, Hdr.endts) =
                                CONVERT(DATE,
                                reportperiod.perioddate)
                            AND Hdr.lessonplanid = StdCalcs.lessonplanid
                            AND dcal.calctype = StdCalcs.calctype
                            AND Hdr.stdtclassid = StdCalcs.stdtclassid
                            AND Hdr.ioaind = 'N'
                            AND Hdr.sessmisstrailstus = 'N'
                            AND Hdr.sessionstatuscd = 'S'
                            AND sc.score >= 0
                            AND Hdr.ismaintanace = 0
							AND Cls.residenceind IN (SELECT data
								FROM   Split(@ClassTypeFlag, ',')))
             END AS Score,
             stdtclassid,
             CASE
               WHEN residenceind = 1 THEN 'Residence'
               ELSE 'Day'
             END AS ClassType,
             ( CONVERT(VARCHAR(50), StdCalcs.lessonplanid)
               + '@'
               + (SELECT CASE
                           WHEN StdCalcs.calcrptlabel = ''
                                 OR StdCalcs.calcrptlabel IS NULL THEN
                           StdCalcs.calctype
                           ELSE StdCalcs.calcrptlabel
                         END)
               + '@'
               + (SELECT colname
                  FROM   dstempsetcol
                  WHERE  dstempsetcolid = (SELECT dstempsetcolid
                                           FROM   dstempsetcolcalc
                                           WHERE
				  dstempsetcolcalc.dstempsetcolcalcid = StdCalcs.dstempsetcolcalcid)) ), 
				  (SELECT colname
                  FROM   dstempsetcol
                  WHERE  dstempsetcolid = (SELECT dstempsetcolid
                                           FROM   dstempsetcolcalc
                                           WHERE
				  dstempsetcolcalc.dstempsetcolcalcid = StdCalcs.dstempsetcolcalcid))
				  FROM   (SELECT sc.schoolid,
					  sc.studentid,
					  sc.dstempsetcolcalcid,
					  dcal.calctype,
					  hdr.lessonplanid,
					  hdr.stdtclassid,
					  Cls.residenceind,
					  dcal.calcrptlabel
				  FROM   stdtsesscolscore sc
					  JOIN dstempsetcolcalc dcal
						ON dcal.dstempsetcolcalcid = sc.dstempsetcolcalcid
					  JOIN stdtsessionhdr hdr
						ON hdr.stdtsessionhdrid = sc.stdtsessionhdrid
					  JOIN class Cls
						ON Cls.classid = hdr.stdtclassid
				  WHERE  hdr.ioaind = 'N'
					  AND hdr.sessmisstrailstus = 'N'
					  AND sc.CreatedOn BETWEEN @TempStartDate AND @TempENDDate
					  AND hdr.EndTs BETWEEN @TempStartDate AND @TempENDDate
					  AND hdr.sessionstatuscd = 'S'
					  AND hdr.schoolid = @TempSchoolId
					  AND hdr.studentid = @TempStudentId
					  AND hdr.lessonplanid IN(SELECT lsid
											  FROM   @LSID)
				  GROUP  BY sc.schoolid,
						 sc.studentid,
						 sc.dstempsetcolcalcid,
						 dcal.calctype,
						 hdr.lessonplanid,
						 hdr.stdtclassid,
						 Cls.residenceind,
						 dcal.calcrptlabel) AS StdCalcs,
				  reportperiod
				  WHERE  perioddate BETWEEN @TempStartDate AND @TempENDDate
				  GROUP  BY StdCalcs.schoolid,
				  StdCalcs.studentid,
				  StdCalcs.lessonplanid,
				  StdCalcs.dstempsetcolcalcid,
				  reportperiod.perioddate,
				  StdCalcs.calctype,
				  StdCalcs.stdtclassid,
				  StdCalcs.residenceind,
				  StdCalcs.calcrptlabel


      UPDATE #temp_stdtaggscores
      SET    #temp_stdtaggscores.score = UPDATETBL.score
      FROM   #temp_stdtaggscores
             INNER JOIN (SELECT schoolid,
                                studentid,
                                dstempsetcolcalcid,
                                createdon,
                                modifiedon,
                                endts,
                                lessonplanid,
                                calctype,
                                CASE
                                  WHEN calctype = 'Total Duration'
                                        OR calctype = 'Frequency'
                                        OR calctype = 'Total Correct'
                                        OR calctype = 'Total Incorrect' THEN
                                  (SELECT Sum(sc.score)
                                   FROM   stdtsesscolscore sc
                                  INNER JOIN stdtsessionhdr
                                             Hdr
                                          ON
                                  Hdr.stdtsessionhdrid = sc.stdtsessionhdrid
                                  INNER JOIN class Cls
                                          ON Cls.classid = Hdr.stdtclassid
                                  JOIN dstempsetcolcalc dcal
                                    ON dcal.dstempsetcolcalcid =
                                       sc.dstempsetcolcalcid
                                                    WHERE
                                  sc.schoolid = StdCalcs.schoolid
                                  AND sc.studentid = StdCalcs.studentid
                                  AND
                        sc.dstempsetcolcalcid = StdCalcs.dstempsetcolcalcid
                                  AND Hdr.lessonplanid = StdCalcs.lessonplanid
                                  AND dcal.calctype = StdCalcs.calctype
                                  AND Hdr.stdtclassid = StdCalcs.stdtclassid
								  AND sc.CreatedOn BETWEEN @TempStartDate AND @TempENDDate
					              AND hdr.EndTs BETWEEN @TempStartDate AND @TempENDDate
                                  AND Hdr.ioaind = 'N'
                                  AND Hdr.sessmisstrailstus = 'N'
                                  AND Hdr.sessionstatuscd = 'S'
                                  AND sc.score >= 0
                                  AND Hdr.ismaintanace = 0
                                  AND CONVERT(DATE, Hdr.endts) =
                                      CONVERT(DATE, StdCalcs.endts)
									  AND Cls.residenceind IN (SELECT data
									  FROM   Split(@ClassTypeFlag, ',')))
                                  ELSE (SELECT Avg(sc.score)
                                        FROM   stdtsesscolscore sc
                                               INNER JOIN stdtsessionhdr Hdr
                                                       ON
      Hdr.stdtsessionhdrid = sc.stdtsessionhdrid
      INNER JOIN class Cls
              ON Cls.classid = Hdr.stdtclassid
      JOIN dstempsetcolcalc dcal
        ON dcal.dstempsetcolcalcid =
           sc.dstempsetcolcalcid
      WHERE  sc.schoolid = StdCalcs.schoolid
      AND sc.studentid = StdCalcs.studentid
      AND
      sc.dstempsetcolcalcid = StdCalcs.dstempsetcolcalcid
      AND Hdr.lessonplanid = StdCalcs.lessonplanid
      AND dcal.calctype = StdCalcs.calctype
      AND Hdr.stdtclassid = StdCalcs.stdtclassid
	  AND sc.CreatedOn BETWEEN @TempStartDate AND @TempENDDate
	  AND hdr.EndTs BETWEEN @TempStartDate AND @TempENDDate
      AND Hdr.ioaind = 'N'
      AND Hdr.sessmisstrailstus = 'N'
      AND Hdr.sessionstatuscd = 'S'
      AND sc.score >= 0
      AND Hdr.ismaintanace = 0
      AND CONVERT(DATE, Hdr.endts) =
          CONVERT(DATE, StdCalcs.endts)
		  AND Cls.residenceind IN (SELECT data
			  FROM   Split(@ClassTypeFlag, ',')))
      END AS Score,
      stdtclassid,
      CASE
      WHEN residenceind = 1 THEN 'Residence'
      ELSE 'Day'
      END AS ClassType
      FROM   (SELECT sc.schoolid,
      sc.studentid,
      sc.dstempsetcolcalcid,
      dcal.calctype,
      hdr.lessonplanid,
      hdr.stdtclassid,
      Cls.residenceind,
      hdr.createdon,
      hdr.isupdate,
      hdr.modifiedon,
      hdr.endts
      FROM   stdtsesscolscore sc
      JOIN dstempsetcolcalc dcal
      ON dcal.dstempsetcolcalcid = sc.dstempsetcolcalcid
      JOIN stdtsessionhdr hdr
      ON hdr.stdtsessionhdrid = sc.stdtsessionhdrid
      JOIN class Cls
      ON Cls.classid = hdr.stdtclassid
      WHERE  hdr.ioaind = 'N'
      AND hdr.sessmisstrailstus = 'N'
      AND hdr.sessionstatuscd = 'S'
      AND hdr.isupdate = 'true'
	  AND sc.CreatedOn BETWEEN @TempStartDate AND @TempENDDate
	  AND hdr.EndTs BETWEEN @TempStartDate AND @TempENDDate
      GROUP  BY sc.schoolid,
      sc.studentid,
      sc.dstempsetcolcalcid,
      dcal.calctype,
      hdr.lessonplanid,
      hdr.stdtclassid,
      Cls.residenceind,
      hdr.createdon,
      hdr.isupdate,
      hdr.modifiedon,
      hdr.endts) AS StdCalcs
      WHERE  StdCalcs.modifiedon BETWEEN @TempStartDate AND @TempENDDate
      AND StdCalcs.isupdate = 'true'
      GROUP  BY StdCalcs.schoolid,
      StdCalcs.studentid,
      StdCalcs.lessonplanid,
      StdCalcs.dstempsetcolcalcid,
      StdCalcs.createdon,
      StdCalcs.calctype,
      StdCalcs.stdtclassid,
      StdCalcs.residenceind,
      StdCalcs.modifiedon,
      StdCalcs.endts) UPDATETBL
      ON #temp_stdtaggscores.schoolid = UPDATETBL.schoolid
      AND #temp_stdtaggscores.studentid = UPDATETBL.studentid
      AND #temp_stdtaggscores.dstempsetcolcalcid =
      UPDATETBL.dstempsetcolcalcid
      AND CONVERT(DATE, #temp_stdtaggscores.aggredateddate) = CONVERT(DATE,
      UPDATETBL.endts)
      AND #temp_stdtaggscores.lessonplanid = UPDATETBL.lessonplanid
      AND #temp_stdtaggscores.calctype = UPDATETBL.calctype
      AND #temp_stdtaggscores.classid = UPDATETBL.stdtclassid


      CREATE TABLE #stg_ioa
        (
           id                 INT PRIMARY KEY IDENTITY(1, 1),
           ioaperc            VARCHAR(50),
           dstempsetcolcalcid INT,
           schoolid           INT,
           studentid          INT,
           lessonplanid       INT,
           stdtclassid        INT,
           createddate        DATE,
           normalusr          VARCHAR(100),
           ioausr             VARCHAR(100)
        );

      INSERT INTO #stg_ioa
      SELECT (SELECT TOP 1 Hdr.ioaperc
              FROM   stdtsessionhdr Hdr
                     INNER JOIN stdtsesscolscore CScr
                             ON Hdr.stdtsessionhdrid = CScr.stdtsessionhdrid
              WHERE  Hdr.ioaind = 'Y'
			         AND Hdr.StudentId=@TempStudentId
                     AND endts BETWEEN @TempStartDate AND @TempENDDate
					 And CScr.CreatedOn BETWEEN @TempStartDate AND @TempENDDate
                     AND CScr.dstempsetcolcalcid = DATA.dstempsetcolcalcid
                     AND CScr.schoolid = DATA.schoolid
                     AND CScr.studentid = DATA.studentid
                     AND Hdr.lessonplanid = DATA.lessonplanid
                     AND Hdr.stdtclassid = DATA.stdtclassid
                     AND CONVERT(DATE, endts) = DATA.endts
              ORDER  BY Hdr.stdtsessionhdrid DESC)IOAPerc,
             DATA.dstempsetcolcalcid,
             DATA.schoolid,
             DATA.studentid,
             DATA.lessonplanid,
             DATA.stdtclassid,
             DATA.endts,
             DATA.normalusr,
             DATA.ioausr
      FROM   (SELECT Hdr.ioaperc,
                     CScr.dstempsetcolcalcid,
                     CScr.schoolid,
                     CScr.studentid,
                     Hdr.lessonplanid,
                     Hdr.stdtclassid,
                     CONVERT(DATE, endts)
                     EndTs,
                     (SELECT userinitial
                      FROM   [user]
                      WHERE  userid = (SELECT createdby
                                       FROM   stdtsessionhdr
                                       WHERE  stdtsessionhdrid =
                                              Hdr.ioasessionhdrid))
                            NormalUsr,
                     (SELECT userinitial
                      FROM   [user]
                      WHERE  userid = Hdr.ioauserid)
                     IOAUsr
              FROM   stdtsessionhdr Hdr
                     INNER JOIN stdtsesscolscore CScr
                             ON Hdr.stdtsessionhdrid = CScr.stdtsessionhdrid
              WHERE  Hdr.ioaind = 'Y'
			         AND Hdr.StudentId=@TempStudentId
			         AND CScr.CreatedOn BETWEEN @TempStartDate AND @TempENDDate
                     AND endts BETWEEN @TempStartDate AND @TempENDDate) AS DATA

      --SET @Counts=1

      --WHILE( @Counts <= (SELECT Count(*)
      --                   FROM   #stg_ioa) )
      --  BEGIN
      --      UPDATE #temp_stdtaggscores
      --      SET    ioaperc = 'IOA ' + CONVERT(VARCHAR(50), (SELECT CONVERT(
      --                       DECIMAL
      --                       (3),
      --                       Round(ioaperc, 0))
      --                              FROM #stg_ioa WHERE id=@Counts)) + ' % '
      --                       + (SELECT normalusr
      --                          FROM   #stg_ioa
      --                          WHERE  id = @Counts)
      --                       + '/'
      --                       + (SELECT ioausr
      --                          FROM   #stg_ioa
      --                          WHERE  id = @Counts)
      --      WHERE  dstempsetcolcalcid = (SELECT dstempsetcolcalcid
      --                                   FROM   #stg_ioa
      --                                   WHERE  id = @Counts)
      --             AND schoolid = (SELECT schoolid
      --                             FROM   #stg_ioa
      --                             WHERE  id = @Counts)
      --             AND studentid = (SELECT studentid
      --                              FROM   #stg_ioa
      --                              WHERE  id = @Counts)
      --             AND lessonplanid = (SELECT lessonplanid
      --                                 FROM   #stg_ioa
      --                                 WHERE  id = @Counts)
      --             AND classid = (SELECT stdtclassid
      --                            FROM   #stg_ioa
      --                            WHERE  id = @Counts)
      --             AND CONVERT(DATE, aggredateddate) = (SELECT createddate
      --                                                  FROM   #stg_ioa
      --                                                  WHERE  id = @Counts)

      --      SET @Counts=@Counts + 1
      --  END

	     UPDATE #stg_ioa
            SET    ioaperc = 'IOA ' + CONVERT(VARCHAR(50), (SELECT CONVERT(
                             DECIMAL
                             (4),
                             Round(ioaperc, 0))))+' % '+normalusr+'/'+ioausr


UPDATE #temp_stdtaggscores
SET ioaperc=(select top 1 ioaperc from #stg_ioa where dstempsetcolcalcid=#temp_stdtaggscores.dstempsetcolcalcid
and studentid=#temp_stdtaggscores.studentid and lessonplanid=#temp_stdtaggscores.lessonplanid and classid=
#temp_stdtaggscores.classid and schoolid=#temp_stdtaggscores.schoolid and createddate=#temp_stdtaggscores.aggredateddate 
order by id desc)
--select * from #temp_stdtaggscores order by lessonplanid,dstempsetcolcalcid,aggredateddate
      DROP TABLE #stg_ioa

      --=============[ New Section for Batch dynamic Updation - End ] =================================================================================================================	  
	  --select * from #temp_stdtaggscores
	
	CREATE TABLE #AGGSCORE(ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),LessonPlanid INT,CalcType VARCHAR(50),Score FLOAT,AggDate DATETIME,ClassType VARCHAR(50),
	IOAPerc VARCHAR(50),ArrowNote NVARCHAR(500),RptLabel VARCHAR(500),ColRptLabelLP VARCHAR(500),CNT INT, IOA INT,ColLabel VARCHAR(500));

	--SELECT ALL LESSON DETAILS BETWEEN STARTDATE AND ENDDATE FROM THE TABLE 'StdtAggScores' AND INSERT IT TO #AGGSCORE TABLE	
	--IF (@TempClsType='Day' OR @TempClsType='Residence')
	--BEGIN	
		INSERT INTO #AGGSCORE
		SELECT AG.LessonPlanId
			,AG.CalcType
			,CASE WHEN AG.CalcType IN ('Avg Duration','Total Correct','Total Duration','Frequency','Total Incorrect') THEN SUM(Score) 
				ELSE AVG(Score) END AS Score
			,AggredatedDate
			,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
				'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM StdtLessonPlan WHERE LessonPlanId=AG.LessonPlanId 
				AND StudentId=@TempStudentId AND SchoolId=@TempSchoolId ORDER BY StdtLessonPlanId DESC) AS ClassType
			,CASE WHEN @TempIncludeIOA='true' THEN IOAPerc ELSE NULL END AS IOAPerc
			,EventName
			,CASE WHEN DSC.CalcRptLabel='' THEN AG.CalcType ELSE DSC.CalcRptLabel  END CalcRptLabel
			,ColRptLabelLP
			,0 AS CNT
			,CASE WHEN @TempIncludeIOA='true' THEN (select substring(REPLACE(IOAPerc,'%',''), 4, charindex(' ', REPLACE(IOAPerc,'%',''), 7) - 3)) 
				ELSE NULL END AS IOA
				,AG.collabel
		FROM #temp_stdtaggscores AG
		INNER JOIN DsTempSetColCalc DSC ON AG.DsTempSetColCalcId = DSC.DSTempSetColCalcId
		LEFT JOIN DSTempSetCol DC ON DC.DSTempSetColId = DSC.DSTempSetColId
		LEFT JOIN DSTempHdr DH ON DH.DSTempHdrId = DC.DSTempHdrId
		WHERE AG.AggredatedDate BETWEEN @TempStartDate AND @TempENDDate AND AG.StudentId=@TempStudentId AND AG.SchoolId=@TempSchoolId AND AG.LessonPlanId IN (SELECT LSID FROM @LSID)
			AND DSC.IncludeInGraph <> 0 AND AG.StdtSessEventId IS NULL and score is not null --<=============================================
			--AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 AND (LessonPlanTypeResi=0 OR LessonPlanTypeResi IS NULL) THEN 'Day' 
			--	ELSE CASE WHEN (LessonPlanTypeDay=0 OR LessonPlanTypeDay IS NULL) AND LessonPlanTypeResi=1 THEN 'Residence' END END  
			--	FROM StdtLessonPlan SL WHERE SL.LessonPlanId=AG.LessonPlanId AND SL.StudentId=@TempStudentId 
			--	AND SL.SchoolId=@TempSchoolId ORDER BY StdtLessonPlanId DESC)=@TempClsType
		GROUP BY AG.LessonPlanId,AG.ColRptLabelLP,DSC.CalcRptLabel,AG.CalcType,AG.AggredatedDate,ClassType,IOAPerc,EventName,AG.collabel
		ORDER BY AG.LessonPlanId,CalcType,AG.ColRptLabelLP,AggredatedDate
	--END
	--ELSE IF (@TempClsType='Day,Residence')
	--BEGIN
	--	INSERT INTO #AGGSCORE
	--	SELECT AG.LessonPlanId
	--		,AG.CalcType
	--		,CASE WHEN AG.CalcType IN ('Avg Duration','Total Correct','Total Duration','Frequency','Total Incorrect') THEN SUM(Score) 
	--			ELSE AVG(Score) END AS Score
	--		,AG.AggredatedDate
	--		,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
	--			'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM StdtLessonPlan WHERE LessonPlanId=AG.LessonPlanId 
	--			AND StudentId=@TempStudentId AND SchoolId=@TempSchoolId ORDER BY StdtLessonPlanId DESC) AS ClassType
	--		,CASE WHEN @TempIncludeIOA='true' THEN IOAPerc ELSE NULL END AS IOAPerc
	--		,EventName
	--		,CASE WHEN DSC.CalcRptLabel='' THEN AG.CalcType ELSE CalcRptLabel  END CalcRptLabel
	--		,ColRptLabelLP
	--		,0 AS CNT
	--		,CASE WHEN @TempIncludeIOA='true' THEN (select substring(REPLACE(IOAPerc,'%',''), 4, charindex(' ', REPLACE(IOAPerc,'%',''), 7) - 3)) ELSE NULL END AS IOA
	--		,AG.collabel
	--	FROM #temp_stdtaggscores AG
	--	INNER JOIN DsTempSetColCalc DSC ON AG.DsTempSetColCalcId = DSC.DSTempSetColCalcId
	--	LEFT JOIN DSTempSetCol DC ON DC.DSTempSetColId = DSC.DSTempSetColId
	--	LEFT JOIN DSTempHdr DH ON DH.DSTempHdrId = DC.DSTempHdrId
	--	WHERE AG.AggredatedDate BETWEEN @TempStartDate AND @TempENDDate AND AG.StudentId=@TempStudentId AND AG.SchoolId=@TempSchoolId AND AG.LessonPlanId IN (SELECT LSID FROM @LSID)
	--		AND DSC.IncludeInGraph <> 0 AND AG.StdtSessEventId IS NULL and score is not null --<=============================================
	--		AND (SELECT TOP 1  CASE WHEN LessonPlanTypeDay=1 or LessonPlanTypeResi=1 THEN 'Day,Residence' END  
	--			FROM [dbo].[StdtLessonPlan] WHERE StdtLessonPlan.LessonPlanId in (SELECT LSID FROM @LSID) AND StudentId=@TempStudentId AND SchoolId=@TempSchoolId 
	--			ORDER BY StdtLessonPlanId DESC)=@TempClsType
	--	GROUP BY AG.LessonPlanId,AG.ColRptLabelLP,CalcRptLabel,AG.CalcType,AggredatedDate,ClassType,IOAPerc,EventName,AG.collabel
	--	ORDER BY AG.LessonPlanId,AG.CalcType,AG.ColRptLabelLP,AG.AggredatedDate
	--END
			
	--SELECT * FROM #AGGSCORE --<=================================================================

	DELETE FROM #AGGSCORE WHERE LessonPlanid IN (SELECT LSID FROM (SELECT *,(SELECT COUNT(ID) FROM #AGGSCORE WHERE LessonPlanId=LSID) DateCnt ,
		(SELECT COUNT(ID) FROM #AGGSCORE WHERE LessonPlanId=LSID AND Score IS NULL) ScoreCnt FROM @LSID) Total WHERE DateCnt=ScoreCnt)	
	
	IF OBJECT_ID('tempdb..#NEWSCOREIOA_Temp') IS NOT NULL
	DROP TABLE #NEWSCOREIOA_Temp
	CREATE TABLE #NEWSCOREIOA_Temp (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),LessonPlanid INT,Score FLOAT,AggDate DATETIME,IOAPerc VARCHAR(50), CalcType VARCHAR(500),ColType VARCHAR(50));
	INSERT INTO #NEWSCOREIOA_Temp(ColType,AggDate,CalcType,LessonPlanid) SELECT ColLabel,AggDate,CalcType,LessonPlanid From #AGGSCORE WHERE Score IS NOT NULL OR IOA IS NOT NULL
		GROUP BY LessonPlanid,AggDate, CalcType,ColLabel		

	SELECT * INTO #Temp_Scores1 FROM (SELECT ID,CalcType,ColLabel,AggDate,LessonPlanid FROM #AGGSCORE A WHERE A.ColLabel = (SELECT TOP 1 Coltype FROM #NEWSCOREIOA_Temp NA WHERE A.ColLabel = NA.ColType AND A.AggDate = NA.AggDate AND A.LessonPlanid = NA.LessonPlanid)) as TempSet1	

	IF OBJECT_ID('tempdb..#NEWSCOREIOA2') IS NOT NULL
	DROP TABLE #NEWSCOREIOA2
	CREATE TABLE #NEWSCOREIOA2 (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),LessonPlanid INT,Score FLOAT,AggDate DATETIME,IOAPerc VARCHAR(50), CalcType VARCHAR(500),ColType VARCHAR(50));	
	INSERT INTO #NEWSCOREIOA2(ColType,AggDate,LessonPlanid,CalcType) SELECT ColLabel,AggDate,LessonPlanid,CalcType From #AGGSCORE GROUP BY LessonPlanid,AggDate,CalcType,ColLabel
	
	DECLARE @COUNTTest INT 
	DECLARE @IOACOUNT2 INT 

	SET @COUNTTest = (SELECT Count(*) FROM #Temp_Scores1)
	SET @IOACOUNT2 = 1

	WHILE( @COUNTTest > 0 )
	BEGIN
		DECLARE @Test VARCHAR(500) = (SELECT CalcType FROM #Temp_Scores1 where ID = @IOACOUNT2) 		
		DECLARE @Test1 VARCHAR(500) = (SELECT ColLabel FROM #Temp_Scores1 where ID = @IOACOUNT2) 							
		DECLARE @Test2 DATETIME = (SELECT AggDate FROM #Temp_Scores1 where ID = @IOACOUNT2) 	
		UPDATE t SET CalcType = @Test FROM #NEWSCOREIOA2 t WHERE t.ID = @IOACOUNT2 AND t.ColType = @Test1 AND t.AggDate = @Test2
		SET @COUNTTest=@COUNTTest - 1
		SET @IOACOUNT2=@IOACOUNT2 + 1
	END

	UPDATE #NEWSCOREIOA_Temp SET Score = (SELECT AVG(Score) FROM #AGGSCORE A WHERE A.AggDate = #NEWSCOREIOA_Temp.AggDate AND A.LessonPlanid = #NEWSCOREIOA_Temp.LessonPlanid AND A.ColLabel = #NEWSCOREIOA_Temp.ColType AND A.CalcType = #NEWSCOREIOA_Temp.CalcType),
	IOAPerc = (SELECT AVG(IOA) FROM #AGGSCORE A WHERE A.AggDate = #NEWSCOREIOA_Temp.AggDate AND A.LessonPlanid = #NEWSCOREIOA_Temp.LessonPlanid AND A.ColLabel = #NEWSCOREIOA_Temp.ColType AND A.CalcType = #NEWSCOREIOA_Temp.CalcType)

	--SELECT AVG(Score) FROM #AGGSCORE A WHERE A.AggDate = '2020-08-19 00:00:00.000' AND A.LessonPlanid = 26066 AND A.ColLabel = 'col3' AND A.CalcType = 'Total Correct'

	UPDATE #NEWSCOREIOA2 SET Score = (SELECT AVG(Score) FROM #AGGSCORE A WHERE A.AggDate = #NEWSCOREIOA2.AggDate AND A.LessonPlanid = #NEWSCOREIOA2.LessonPlanid AND A.ColLabel = #NEWSCOREIOA2.ColType AND A.CalcType = #NEWSCOREIOA2.CalcType),
	IOAPerc = (SELECT AVG(IOA) FROM #AGGSCORE A WHERE A.AggDate = #NEWSCOREIOA2.AggDate AND A.LessonPlanid = #NEWSCOREIOA2.LessonPlanid AND A.ColLabel = #NEWSCOREIOA2.ColType AND A.CalcType = #NEWSCOREIOA2.CalcType)


	--select * from #NEWSCOREIOA_Temp
	--select * from #NEWSCOREIOA2

	SELECT * INTO #test FROM(SELECT * FROM #AGGSCORE) AS IOAPercentUpdate 

	DELETE FROM #AGGSCORE WHERE AggDate IN (SELECT AggDate FROM (SELECT CalcType,AggDate,COUNT(1) RepeatCnt,ColRptLabelLP FROM #AGGSCORE GROUP BY CalcType,AggDate,ColRptLabelLP) 
		AggScr WHERE  RepeatCnt>=2) AND ColRptLabelLP IN (SELECT ColRptLabelLP FROM (SELECT CalcType,AggDate,COUNT(1) RepeatCnt,ColRptLabelLP FROM #AGGSCORE 
		GROUP BY CalcType,AggDate,ColRptLabelLP) AggScr WHERE  RepeatCnt>=2) AND Score IS NULL

	--UPDATE #AGGSCORE SET Score = (SELECT N.Score),IOAPerc = REPLACE(N.IOAPerc,(SELECT SUBSTRING(REPLACE(N.IOAPerc,'%',''), 4, CHARINDEX(' ', REPLACE(N.IOAPerc,'%',''), 7) - 3)),(SELECT N.IOAPerc))  
	--FROM #NEWSCOREIOA2 N WHERE #AGGSCORE.AggDate = N.AggDate AND N.LessonPlanid = #AGGSCORE.LessonPlanid AND N.CalcType = #AGGSCORE.CalcType AND N.ColType = #AGGSCORE.ColLabel

	UPDATE #AGGSCORE SET Score = (SELECT N.Score),IOAPerc = REPLACE(N.IOAPerc,(SELECT SUBSTRING(REPLACE(N.IOAPerc,'%',''), 4, CASE WHEN CHARINDEX(' ', REPLACE(N.IOAPerc,'%',''), 7) > 0 THEN CHARINDEX(' ', REPLACE(N.IOAPerc,'%',''), 7) - 3 ELSE CHARINDEX(' ', REPLACE(N.IOAPerc,'%','')) END) ),(SELECT N.IOAPerc))  
	FROM #NEWSCOREIOA2 N WHERE #AGGSCORE.AggDate = N.AggDate AND N.LessonPlanid = #AGGSCORE.LessonPlanid AND N.CalcType = #AGGSCORE.CalcType AND N.ColType = #AGGSCORE.ColLabel
  

	UPDATE #AGGSCORE SET IOAPerc = UPPER((SELECT STUFF(IOAPerc, 3,1,'A '))) WHERE IOAPerc IS NOT NULL

	UPDATE #AGGSCORE SET IOAPerc = (SELECT AG.IOAPerc) FROM #test AG WHERE #AGGSCORE.AggDate = AG.AggDate AND #AGGSCORE.LessonPlanid = AG.LessonPlanid AND AG.CalcType = #AGGSCORE.CalcType AND AG.ColRptLabelLP = #AGGSCORE.ColRptLabelLP AND AG.ColLabel = #AGGSCORE.ColLabel-- For IOAPercUpdate
    
	--SELECT * FROM #AGGSCORE --<=================================================================

	DELETE FROM #AGGSCORE WHERE ID NOT IN (SELECT MIN(ID) FROM #AGGSCORE GROUP BY AggDate,CalcType,LessonPlanid,ColLabel)  

	--SELECT * FROM #AGGSCORE --<=================================================================

	;WITH T
    AS (SELECT CNT, ROW_NUMBER() OVER (ORDER BY ID ) AS RN FROM #AGGSCORE)
	UPDATE T
	SET CNT = RN 

	IF OBJECT_ID('tempdb..#TEMP') IS NOT NULL  
	DROP TABLE #TEMP

	CREATE TABLE #TEMP(Scoreid INT PRIMARY KEY NOT NULL IDENTITY(1,1), LessonPlanId INT, CalcType VARCHAR(50), Score FLOAT, AggredatedDate DATETIME, ClassType VARCHAR(50),
		BreakTrendNo INT, XValue INT, Trend FLOAT, IOAPerc VARCHAR(50), ArrowNote NVARCHAR(500), EventType VARCHAR(50), EventName NVARCHAR(MAX), EvntTs DATETIME, EndTime DATETIME,
		Comment VARCHAR(500), RptLabel VARCHAR(500), ColRptLabelLP VARCHAR(500), DummyScore FLOAT NULL, LeftYaxis VARCHAR(500) NULL, RightYaxis VARCHAR(500) NULL,
		PromptCount INT NULL, NonPercntCount INT NULL, PercntCount INT NULL, ColName VARCHAR(200) NULL, Color VARCHAR(50), Shape VARCHAR(50));
	
	CREATE NONCLUSTERED INDEX idx_temp_LessonPlanId ON #TEMP (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_temp_CalcType ON #TEMP (CalcType);
	CREATE NONCLUSTERED INDEX idx_temp_AggredatedDate ON #TEMP (AggredatedDate);
	CREATE NONCLUSTERED INDEX idx_temp_ColRptLabelLP ON #TEMP (ColRptLabelLP);
	CREATE NONCLUSTERED INDEX idx_temp_Scoreid ON #TEMP (Scoreid);
	CREATE NONCLUSTERED INDEX idx_temp_BreakTrendNo ON #TEMP (BreakTrendNo);
	
	SET @TMPCount = (SELECT COUNT(ID) FROM #AGGSCORE)
	WHILE(@TMPCount>0)
	BEGIN
		SELECT @Calc = CalcType, @LessonPlanOld = LessonPlanid, @ClassOld = ClassType, @OldTMPDate = AggDate, @RPTLabelOld = RptLabel, @ColRptLabelLPOld = ColRptLabelLP
		FROM #AGGSCORE WHERE CNT=(@TMPLoopCount-1)

		SELECT @TMPCalcType = CalcType, @TMPClassType = ClassType, @TMPLessonPlan = LessonPlanid, @TMPDate = AggDate, @RPTLabel = RptLabel, @ColRptLabelLP = ColRptLabelLP
		FROM #AGGSCORE WHERE CNT=@TMPLoopCount	
		
		IF(@TMPDate<=@OldTMPDate)
		BEGIN
			WHILE(@OldTMPDate<=@TempENDDate)
			BEGIN
				SET @OldTMPDate=DATEADD(DAY,1,@OldTMPDate)
				INSERT INTO #TEMP (LessonPlanId,CalcType,AggredatedDate,ClassType,XValue,RptLabel,ColRptLabelLP) VALUES 
					( @LessonPlanOld,@Calc,@OldTMPDate,@ClassOld,@TMPSesscnt,@RPTLabelOld,@ColRptLabelLPOld)	
				SET @TMPSesscnt=@TMPSesscnt+1
			END
		END		
		IF(@ColRptLabelLPOld<>@ColRptLabelLP) 
		BEGIN		
			SET @TMPSesscnt=1
			SET @TMPStartDate=@TempStartDate		
		END
		ELSE IF(@TMPLessonPlan<>@LessonPlanOld)
		BEGIN
			SET @TMPSesscnt=1
			SET @TMPStartDate=@TempStartDate
		END
		SET @Calc=@TMPCalcType
		IF(@TMPDate=@TMPStartDate)
		BEGIN
			INSERT INTO #TEMP (LessonPlanId,CalcType,AggredatedDate,ClassType,XValue,Score,IOAPerc,ArrowNote,RptLabel,ColRptLabelLP) 
			SELECT LessonPlanid,CalcType,AggDate,ClassType,@TMPSesscnt,Score,IOAPerc,ArrowNote,RptLabel,ColRptLabelLP FROM #AGGSCORE WHERE CNT=@TMPLoopCount
			SET @TMPSesscnt=@TMPSesscnt+1
		END
		ELSE
		BEGIN
			WHILE(@TMPDate<>@TMPStartDate)
			BEGIN
				IF(@TMPDate>@TMPStartDate)
				BEGIN
					INSERT INTO #TEMP (LessonPlanId,CalcType,AggredatedDate,ClassType,XValue,RptLabel,ColRptLabelLP) VALUES 
						(@TMPLessonPlan,@TMPCalcType,@TMPStartDate,@TMPClassType,@TMPSesscnt,@RptLabel,@ColRptLabelLP)
					SET @TMPStartDate=DATEADD(DAY,1,@TMPStartDate)
				END
				ELSE
				BEGIN
					INSERT INTO #TEMP (LessonPlanId,CalcType,AggredatedDate,ClassType,XValue,RptLabel,ColRptLabelLP) VALUES 
						(@TMPLessonPlan,@TMPCalcType,@TMPDate,@TMPClassType,@TMPSesscnt,@RptLabel,@ColRptLabelLP)
					SET @TMPDate=DATEADD(DAY,1,@TMPDate)
				END	
				SET @TMPSesscnt=@TMPSesscnt+1
			END
			IF(@TMPDate=@TMPStartDate)
			BEGIN
				INSERT INTO #TEMP (LessonPlanId,CalcType,AggredatedDate,ClassType,XValue,Score,IOAPerc,ArrowNote,RptLabel,ColRptLabelLP) 
				SELECT LessonPlanid,CalcType,AggDate,ClassType,@TMPSesscnt,Score,IOAPerc,ArrowNote,RptLabel,ColRptLabelLP FROM #AGGSCORE WHERE CNT=@TMPLoopCount
				SET @TMPSesscnt=@TMPSesscnt+1
			END
		END

		SET @TMPLoopCount=@TMPLoopCount+1	
		SET @TMPCount=@TMPCount-1	
		SET @TMPStartDate=DATEADD(DAY,1,@TMPStartDate)	
		IF(@TMPCount=0)
		BEGIN
			WHILE(@TMPDate<=@TempENDDate)
			BEGIN
				SET @TMPDate=DATEADD(DAY,1,@TMPDate)
				INSERT INTO #TEMP (LessonPlanId,CalcType,AggredatedDate,ClassType,XValue,RptLabel,ColRptLabelLP) VALUES 
					( @TMPLessonPlan,@TMPCalcType,@TMPDate,@TMPClassType,@TMPSesscnt,@RptLabel,@ColRptLabelLP)	
				SET @TMPSesscnt=@TMPSesscnt+1
			END
		END
	END			

	--SELECT * FROM ##TEMP  --<=================================================================

	CREATE TABLE #DURATN(ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),Score FLOAT,LessonPlanId INT,ColRptLabelLP VARCHAR(500))
	
	CREATE NONCLUSTERED INDEX idx_duratn_LessonPlanId ON #DURATN (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_duratn_ColRptLabelLP ON #DURATN (ColRptLabelLP);
	
	INSERT INTO #DURATN
	SELECT MAX(ISNULL(Score,-1)),LessonPlanId,ColRptLabelLP FROM #TEMP WHERE CalcType IN ('Total Duration','Avg Duration') GROUP BY LessonPlanId,ColRptLabelLP
	
	SET @TMPCount=(SELECT COUNT(ID) FROM #DURATN)
	SET @TMPLoopCount=1
	WHILE(@TMPCount>0)
	BEGIN
		IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)<>-1)
		BEGIN
			DECLARE @RpL VARCHAR(500)
			SELECT @RpL = @RpL, @LessId = LessonPlanId FROM #DURATN WHERE ID=@TMPLoopCount

			IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)<60)
			BEGIN
				UPDATE #TEMP SET RptLabel=RptLabel+' (In Seconds)' WHERE LessonPlanId=@LessId AND ColRptLabelLP=@RpL
			END
			ELSE IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)<3600)
			BEGIN
				UPDATE #TEMP SET RptLabel=RptLabel+' (In Minutes)' WHERE LessonPlanId=@LessId AND ColRptLabelLP=@RpL
				UPDATE #TEMP SET Score=Score/60 WHERE LessonPlanId=@LessId AND ColRptLabelLP=@RpL
			END
			ELSE IF((SELECT Score FROM #DURATN WHERE ID=@TMPLoopCount)>=3600)
				BEGIN
					UPDATE #TEMP SET RptLabel=RptLabel+' (In Hours)' WHERE LessonPlanId=@LessId AND ColRptLabelLP=@RpL
					UPDATE #TEMP SET Score=Score/3600 WHERE LessonPlanId=@LessId AND ColRptLabelLP=@RpL
				END
		END
		SET @TMPLoopCount=@TMPLoopCount+1
		SET @TMPCount=@TMPCount-1
	END
	DROP TABLE #DURATN

	--///////////////////////////// Event Section ////////////////////////////////
	CREATE TABLE #EVNT(ID INT PRIMARY KEY IDENTITY(1,1),LPID INT)
	INSERT INTO #EVNT SELECT LSID FROM @LSID
	
	-- FOR ARROW NOTES
	IF('Arrow' IN ( SELECT EVNT FROM @EVNT))
	BEGIN
		SET @Cnt=(SELECT COUNT(ID) FROM #EVNT)
		SET @TopColNam=(SELECT TOP 1 ColRptLabelLP FROM #TEMP order by Scoreid desc)
		WHILE(@Cnt>0)
		BEGIN
			SET @LessId= (SELECT LPID FROM #EVNT WHERE ID=@Cnt)

			CREATE TABLE #LPARROW(ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),LESSONID INT, CalcType VARCHAR(50),AggredatedDate DATETIME, ClassType VARCHAR(50),
			ArrowNote NVARCHAR(500),EventType VARCHAR(50),EventName NVARCHAR(MAX),TimeStampForReport DATETIME,EndTime DATETIME,Comment VARCHAR(200));
		
			CREATE NONCLUSTERED INDEX idx_lparrow_LESSONID ON #LPARROW (LESSONID);
			CREATE NONCLUSTERED INDEX idx_lparrow_AggredatedDate ON #LPARROW (AggredatedDate);

			INSERT INTO #LPARROW
			SELECT @LessId AS LESSONID
				,'Event' CalcType
				,CONVERT(DATE,EvntTs) AS AggredatedDate
				,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
					'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE LessonPlanId=@LessId
					AND StudentId=@TempStudentId AND SchoolId=@TempSchoolId ORDER BY StdtLessonPlanId DESC) AS ClassType
				,EventName AS ArrowNote
				,null AS EventType
				,EventName
				,CONVERT(DATE,EvntTs)
				,EndTime
				,Comment 
			FROM [dbo].[StdtSessEvent]
			INNER JOIN StudentPersonal Student ON Student.StudentPersonalId=[StdtSessEvent].StudentId
			LEFT JOIN LessonPlan ON LessonPlan.LessonPlanId=[StdtSessEvent].LessonPlanId 
			WHERE Student.StudentPersonalId=@TempStudentId 
			AND [StdtSessEvent].LessonPlanId IN (0,@LessId) 
			AND EventType='EV' 
			AND EvntTs BETWEEN @TempStartDate AND @TempENDDate 
			AND StdtSessEventType='Arrow notes' 
			AND @TempEvent LIKE '%' + 'Arrow' + '%'
			AND discardstatus is NULL

			SET @ARROWCNT =(SELECT COUNT(ID) FROM #LPARROW)
			SET @ARROWID=1
			--SELECT * FROM #LPARROW
			WHILE(@ARROWCNT>0)
			BEGIN
				SELECT @LessId = LESSONID, @TMPDate = (SELECT CONVERT(DATE,AggredatedDate)) FROM #LPARROW WHERE ID=@ARROWID
				SET @CNTLP=(SELECT COUNT(Scoreid) FROM #TEMP WHERE LessonPlanId=@LessId AND CONVERT(DATE,AggredatedDate)= @TMPDate)		
				
					--UPDATE #TEMP SET ArrowNote=(SELECT STUFF((SELECT ','+CONVERT(NVARCHAR(MAX), EventName) FROM (SELECT [EventName] FROM #LPARROW WHERE LESSONID=@LessId 
					--AND CONVERT(DATE,AggredatedDate)=@TMPDate) EName FOR XML PATH('')),1,1,''))
					--WHERE LessonPlanId=@LessId AND CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) AND CalcType<>'Event'
					UPDATE #TEMP SET ArrowNote= case when ColRptLabelLP=@TopColNam then (SELECT STUFF((SELECT ','+CONVERT(NVARCHAR(MAX), EventName) FROM (SELECT [EventName] FROM #LPARROW WHERE LESSONID=@LessId 
					AND CONVERT(DATE,AggredatedDate)=@TMPDate) EName FOR XML PATH('')),1,1,'')) end 					
					WHERE LessonPlanId=@LessId AND CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) AND CalcType<>'Event' --AND ColRptLabelLP=@TopColNam
		

					/*INSERT INTO #TEMP (LessonPlanId
						,CalcType
						,AggredatedDate
						,ClassType					
						,ArrowNote
						,EventType
						,EventName
						,EvntTs
						,EndTime
						,Comment
						,Score
						)
					SELECT LESSONID
						,CalcType
						,AggredatedDate
						,ClassType
						,ArrowNote
						,EventType
						,EventName
						,TimeStampForReport
						,EndTime
						,Comment
						,0 AS Score
					FROM #LPARROW WHERE ID=@ARROWID*/

					DECLARE @scorestatus INT  = (SELECT TOP 1 score from #TEMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) AND EventName IS NULL)
					--PRINT @scorestatus

					DECLARE @arwnotstats VARCHAR(MAX) = (SELECT TOP 1 Arrownote FROM #TEMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID) AND EventName IS NULL)
					--SELECT @arwnotstatsdate = (SELECT TOP 1 CONVERT(DATE,AggredatedDate) FROM #TEMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #LPARROW WHERE ID=@ARROWID))
					--PRINT @arwnotstats
					--PRINT @arwnotstatsdate

					IF(@scorestatus IS NULL)
					BEGIN
						INSERT INTO #TEMP (LessonPlanId
						,CalcType
						,AggredatedDate
						,ClassType					
						,ArrowNote
						,EventType
						,EventName
						,EvntTs
						,EndTime
						,Comment
						,Score
						)
					SELECT LESSONID
						,CalcType
						,AggredatedDate
						,ClassType
						,ArrowNote
						,EventType
						,EventName
						,TimeStampForReport
						,EndTime
						,Comment
						,0 AS Score
					FROM #LPARROW WHERE ID=@ARROWID
					END

				SET @ARROWCNT=@ARROWCNT-1
				SET @ARROWID=@ARROWID+1
				END
			DROP TABLE #LPARROW	
			SET @Cnt=@Cnt-1
		END
	END

	--FOR Major AND Minor EVENTS
	DECLARE @MajorMinor TABLE (MajorMinor varchar(15))
	IF('Major' in ( SELECT EVNT FROM @EVNT))
		INSERT INTO @MajorMinor (MajorMinor) VALUES ('Major')
	IF('Minor' in ( SELECT EVNT FROM @EVNT))
		INSERT INTO @MajorMinor (MajorMinor) VALUES ('Minor')

	IF(('Major' IN ( SELECT EVNT FROM @EVNT)) OR ('Minor') IN ( SELECT EVNT FROM @EVNT))
	BEGIN
		SET @Cnt=(SELECT COUNT(ID) FROM #EVNT)
		WHILE(@Cnt>0)
		BEGIN
			SET @LessId= (SELECT LPID FROM #EVNT WHERE ID=@Cnt)
			--IF((SELECT COUNT(Scoreid) FROM #TEMP WHERE LessonPlanId=(SELECT LPID FROM #EVNT WHERE ID=@Cnt) AND CalcType<>'Event')>0)
			--BEGIN
				INSERT INTO #TEMP (LessonPlanId
					,CalcType
					,AggredatedDate
					,ClassType
					,EventType
					,EventName
					,EvntTs
					,ColRptLabelLP)
				SELECT @LessId	
					,'Event' AS CalcType
					,DATEADD(HOUR, 12, CONVERT(DATETIME,CONVERT(DATE,EvntTs))) AS AggredatedDate
					,(SELECT TOP 1 CASE WHEN LessonPlanTypeDay=1 AND LessonPlanTypeResi=1 THEN 'Day,Residence' ELSE CASE WHEN LessonPlanTypeDay=1 THEN 
						'Day' ELSE CASE WHEN LessonPlanTypeResi=1 THEN 'Residence' END END END FROM [dbo].[StdtLessonPlan] WHERE 
						LessonPlanId=@LessId AND StudentId=@TempStudentId AND SchoolId=@TempSchoolId ORDER BY StdtLessonPlanId DESC) as ClassType
					,CASE WHEN (SELECT COUNT(StdtSessEventId) FROM StdtSessEvent where StdtSessEventType='Major' AND StdtSessEventType IN (SELECT * FROM @MajorMinor)  
						AND (LessonPlanId=@LessId OR LessonPlanId=0) AND StudentId=@TempStudentId AND discardstatus is NULL and CONVERT(DATE,EvntTs) = CONVERT(DATE,SE.EvntTs)) >0 THEN 'Major' ELSE 'Minor' 
						END AS EventType
					,(SELECT FORMAT(CONVERT(DATE,EvntTs),'MM/dd')+','+ STUFF((SELECT  ', '+ EventName FROM (SELECT EventName  FROM StdtSessEvent S
						WHERE S.StudentId=@TempStudentId AND discardstatus is NULL AND EventType='EV' AND CONVERT(DATE,S.EvntTs) =CONVERT(DATE,SE.EvntTs) --AND StdtSessEventType<>'Arrow notes' 
						AND StdtSessEventType IN (SELECT MajorMinor FROM @MajorMinor)
						AND discardstatus is NULL
						AND (S.LessonPlanId=@LessId OR S.LessonPlanId=0)) LP FOR XML PATH('')),1,1,'')) EventName
					,CONVERT(DATE,EvntTs) EvntTs
					,(SELECT TOP 1 TMP.ColRptLabelLP FROM #TEMP TMP WHERE TMP.LessonPlanId=@LessId) ColRptLabelLP
				FROM StdtSessEvent SE
				WHERE SE.StudentId=@TempStudentId 
				AND (SE.LessonPlanId=@LessId OR SE.LessonPlanId=0) 
				AND EventType='EV' AND discardstatus is NULL
				AND EventName is not null
				AND EvntTs BETWEEN @TempStartDate AND @TempENDDate 
				AND StdtSessEventType IN (SELECT MajorMinor FROM @MajorMinor)
				GROUP BY SE.LessonPlanId,CONVERT(DATE,EvntTs),SE.StdtSessEventType, SE.eventname
		--END
		SET @Cnt=@Cnt-1
	END
	END
	DROP TABLE #EVNT
	--//////////////////////////// Event Section End /////////////////////////////
	
	--TO SEPERATE EACH TRENDLINE FROM THE TABLE #TEMP, ADD EACH PAGE SESSION TO #TEMPTYPE 
	CREATE TABLE #TEMPTYPE(ID INT PRIMARY KEY NOT NULL IDENTITY(1,1), LPID INT, Type VARCHAR(50), ClassType VARCHAR(50), RptLabel VARCHAR(500), ColRptLabelLP VARCHAR(500));
	CREATE NONCLUSTERED INDEX idx_temptype_LPID ON #TEMPTYPE (LPID);
	CREATE NONCLUSTERED INDEX idx_temptype_Type ON #TEMPTYPE (Type);
	CREATE NONCLUSTERED INDEX idx_temptype_ClassType ON #TEMPTYPE (ClassType);
	CREATE NONCLUSTERED INDEX idx_temptype_ColRptLabelLP ON #TEMPTYPE (ColRptLabelLP);
	
	INSERT INTO #TEMPTYPE SELECT LessonPlanId, CalcType, ClassType, RptLabel, ColRptLabelLP FROM #TEMP WHERE CalcType <> 'Event' 
		GROUP BY LessonPlanId, CalcType, ClassType, RptLabel, ColRptLabelLP ORDER BY LessonPlanId, CalcType
	
	CREATE TABLE #TEMPTYPE1(ID INT PRIMARY KEY NOT NULL IDENTITY(1,1), LPID INT, aggredateddate DATETIME);

	CREATE NONCLUSTERED INDEX idx_temptype1_LPID ON #TEMPTYPE1 (LPID);
	CREATE NONCLUSTERED INDEX idx_temptype1_aggredateddate ON #TEMPTYPE1 (aggredateddate);

	INSERT INTO #TEMPTYPE1 SELECT LessonPlanId,AggredatedDate FROM #TEMP WHERE CalcType = 'Event'  ORDER BY LessonPlanId,AggredatedDate

	SET @Cnt=1
	--FOR SEPERATING EACH TERAND LINE SECTION AND NUMBERED IT AS 1,2,3 ETC IN 'BreakTrendNo' COLUMN OF #TEMP TABLE
	SET @LCount = (SELECT COUNT(ID) FROM #TEMPTYPE)
	WHILE ( @LCount > 0 )
	BEGIN
		SELECT @CalcType = Type, @LoopLessonPlan = LPID, @ClassType = ClassType, @ColRptLabelLP = ColRptLabelLP, @RptLbl = RptLabel
		FROM #TEMPTYPE WHERE ID=@Cnt
		SET @Scoreid=(SELECT TOP 1 Scoreid FROM #TEMP WHERE CalcType=@CalcType AND LessonPlanId=@LoopLessonPlan AND ClassType=@ClassType AND ColRptLabelLP=@ColRptLabelLP)

		WHILE(EXISTS(SELECT Scoreid FROM #TEMP WHERE LessonPlanId=@LoopLessonPlan AND ClassType=@ClassType AND Calctype=@CalcType AND Scoreid=@Scoreid 
			AND ColRptLabelLP=@ColRptLabelLP))
		BEGIN
			SET @Score = (SELECT ISNULL(CONVERT(INT,Score),-1) FROM #TEMP WHERE Scoreid=@Scoreid)
			--IF(EXISTS(SELECT Scoreid FROM #TEMP WHERE CalcType = 'Event' AND LessonPlanId = @LoopLessonPlan AND AggredatedDate = DATEADD(HOUR,-12, (SELECT AggredatedDate FROM #TEMP 
			--	WHERE Scoreid = @Scoreid))))
			IF(EXISTS(SELECT * FROM #TEMPTYPE1 WHERE LPID = @LoopLessonPlan AND AggredatedDate = DATEADD(HOUR,-12,(SELECT AggredatedDate FROM #TEMP
			WHERE Scoreid = @Scoreid))))
			BEGIN
				IF( @Score = -1 )
				BEGIN
					SET @Breaktrendid=(SELECT ISNULL(MAX(BreakTrendNo),0) FROM #TEMP) + 1
				END
				ELSE
				BEGIN
					SET @Breaktrendid = (SELECT ISNULL(MAX(BreakTrendNo),0) FROM #TEMP) + 1
					UPDATE #TEMP SET BreakTrendNo = @Breaktrendid WHERE Scoreid = @Scoreid
					SET @Nullcnt = 0	
				END
			END
			IF(@Score = -1)
			BEGIN
				SET @Nullcnt=@Nullcnt+1	
			END
			ELSE IF(@Nullcnt >= 5 AND @Score <> -1)
			BEGIN	
				SET @Breaktrendid = (SELECT ISNULL(MAX(BreakTrendNo),0) FROM #TEMP) + 1
				UPDATE #TEMP SET BreakTrendNo = @Breaktrendid WHERE Scoreid = @Scoreid
				SET @Nullcnt = 0		
			END
			ELSE IF(@Score <> -1)
			BEGIN		
				UPDATE #TEMP SET BreakTrendNo = @Breaktrendid WHERE Scoreid = @Scoreid
				SET @Nullcnt = 0	
			END	

			SET @Scoreid = @Scoreid + 1	
		END

		SET @Breaktrendid = @Breaktrendid + 1
		SET @Cnt = @Cnt + 1
		SET @LCount = @LCount - 1
	END
	--select * from #TEMP order by Scoreid
	DROP TABLE #TEMPTYPE
	
	--SELECT EACH TREND LINE SECTION FROM #TEMP AND CALCULATE TREND POINT VALUES
	DECLARE @Xval INT
	SET @Cnt = 0
	IF(@TempTrendtype = 'Quarter')
	BEGIN
		SET @NumOfTrend=(SELECT COUNT(DISTINCT BreakTrendNo) FROM #TEMP)
		WHILE(@NumOfTrend > 0)
		BEGIN
			SET @Cnt=@Cnt + 1
			SET @TrendsectionNo = (SELECT COUNT(Scoreid) FROM #TEMP WHERE BreakTrendNo=@Cnt)
			
			IF(@TrendsectionNo > 2)
			BEGIN	
				CREATE TABLE #TRENDSECTION(Id INT PRIMARY KEY NOT NULL IDENTITY(1,1), Trenddate DATETIME, Score FLOAT, Scoreid INT);
				INSERT INTO #TRENDSECTION SELECT AggredatedDate, Score, Scoreid FROM #TEMP WHERE Scoreid BETWEEN (SELECT TOP 1 Scoreid FROM #TEMP WHERE 
					BreakTrendNo=@Cnt ORDER BY Scoreid) AND (SELECT TOP 1 Scoreid FROM #TEMP WHERE BreakTrendNo=@Cnt ORDER BY Scoreid DESC) AND Score IS NOT NULL
				
				IF((SELECT COUNT(Id) FROM #TRENDSECTION) % 2 = 0)
					SET @DateCnt=((SELECT COUNT(Id) FROM #TRENDSECTION) / 2) + 1
				ELSE
					SET @DateCnt=((SELECT COUNT(Id) FROM #TRENDSECTION) / 2) + 2
				SET @Midrate1= (SELECT ((SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE Id BETWEEN 1 AND (SELECT COUNT(Id)/2 FROM #TRENDSECTION) 
					ORDER BY Score) As A ORDER BY Score DESC) +(SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE 
					Id BETWEEN 1 AND (SELECT COUNT(Id)/2 FROM #TRENDSECTION) ORDER BY Score DESC) As A ORDER BY Score Asc)) / 2 )
				SET @Midrate2=(SELECT ((SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE Id BETWEEN @DateCnt AND (SELECT COUNT(Id) FROM #TRENDSECTION)
					ORDER BY Score) As A ORDER BY Score DESC) +(SELECT TOP 1 Score FROM (SELECT  TOP 50 PERCENT Score FROM #TRENDSECTION WHERE 
					Id BETWEEN @DateCnt AND (SELECT COUNT(Id) FROM #TRENDSECTION) ORDER BY Score DESC) As A ORDER BY Score Asc)) / 2 )

				IF(@TrendsectionNo > 2)
				BEGIN
					SET @Xval = (SELECT TOP 1 XValue FROM #TEMP WHERE BreakTrendNo=@Cnt ORDER BY Scoreid)
					--Applying Line Equation Y=mx+b To find Slope 'm' AND Constant 'b'
					SET @Slope = (@Midrate2-@Midrate1) / ((SELECT TOP 1 XValue FROM #TEMP WHERE BreakTrendNo=@Cnt ORDER BY Scoreid DESC)-@Xval)
					
					--b=y-mx
					SET @Const = @Midrate1 - (@Slope * @Xval)

					SET @Ids = @Xval --FIRST x value
					SET @IdOfTrend = (SELECT TOP 1 Scoreid FROM #TRENDSECTION ORDER BY Id)
					WHILE(@IdOfTrend <= (SELECT MAX(Scoreid) FROM #TRENDSECTION))
					BEGIN		
						UPDATE #TEMP SET Trend = ((@Slope * @Ids) + @Const) WHERE Scoreid = @IdOfTrend
						SET @IdOfTrend = @IdOfTrend + 1
						SET @Ids = @Ids + 1
					END	
					DROP TABLE #TRENDSECTION
				END	
			END
			SET @NumOfTrend=@NumOfTrend-1
		END
	END
	ELSE IF(@TempTrendtype='Least')
	BEGIN
		SET @NumOfTrend = (SELECT COUNT(DISTINCT BreakTrendNo) FROM #TEMP)
		WHILE(@NumOfTrend > 0)
		BEGIN
			SET @Cnt=@Cnt+1
			SET @TrendsectionNo = (SELECT COUNT(Scoreid) FROM #TEMP WHERE BreakTrendNo=@Cnt)

			IF(@TrendsectionNo > 2)
			BEGIN		
				CREATE TABLE #TREND(Id INT PRIMARY KEY NOT NULL IDENTITY(1,1), Trenddate DATETIME, Score FLOAT, Scoreid INT, XVal INT);

				CREATE NONCLUSTERED INDEX idx_trend_Scoreid ON #TREND (Scoreid);

				INSERT INTO #TREND SELECT AggredatedDate, Score, Scoreid, XValue FROM #TEMP WHERE Scoreid BETWEEN (SELECT TOP 1 Scoreid FROM #TEMP WHERE 
					BreakTrendNo=@Cnt ORDER BY Scoreid) AND (SELECT TOP 1 Scoreid FROM #TEMP WHERE BreakTrendNo=@Cnt ORDER BY Scoreid DESC)
	
				SET @SUM_XI=(SELECT SUM(XVal) FROM #TREND) --SUM(xi)
				SET @SUM_YI=(SELECT SUM(Score) FROM #TREND) --SUM(yi)
				SET @SUM_XX=(SELECT SUM(XVal*XVal) FROM #TREND) --SUM(xi*xi)
				SET @SUM_XY=(SELECT SUM(XVal*Score) FROM #TREND) --SUM(xi*yi)

				SET @X1=(SELECT COUNT(Id) FROM #TREND)
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

				SET @Ids=(SELECT TOP 1 XValue FROM #TEMP WHERE BreakTrendNo=@Cnt ORDER BY Scoreid) --FIRST x value
				SET @IdOfTrend=(SELECT TOP 1 Scoreid FROM #TREND ORDER BY Id)
				WHILE(@IdOfTrend<=(SELECT MAX(Scoreid) FROM #TREND))
				BEGIN		
					UPDATE #TEMP SET Trend=((@B*@Ids)+@A) WHERE Scoreid=@IdOfTrend
					SET @IdOfTrend=@IdOfTrend+1
					SET @Ids=@Ids+1
				END	
				DROP TABLE #TREND
			END	
			SET @NumOfTrend=@NumOfTrend-1
		END	
	END
	DROP TABLE #AGGSCORE
	
	----///////////////////NEW CHANGE FOR TWO Y AXIS/////////////////////		
	CREATE TABLE #TMPLP(ID INT NOT NULL IDENTITY(1,1), LessonPlanId INT, CalcType VARCHAR(50));

	CREATE NONCLUSTERED INDEX idx_tmplp_LessonPlanId ON #TMPLP (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_tmplp_CalcType ON #TMPLP (CalcType);

	INSERT INTO #TMPLP SELECT LessonPlanId, CalcType FROM #TEMP WHERE CalcType<>'Event' GROUP BY LessonPlanId, CalcType ORDER BY LessonPlanId,CalcType 
		
	CREATE TABLE #TMPLPCNT(ID INT NOT NULL IDENTITY(1,1), LessonPlanId INT, CalcTypeCNT INT);

	CREATE NONCLUSTERED INDEX idx_tmplpcnt_LessonPlanId ON #TMPLPCNT (LessonPlanId);

	INSERT INTO #TMPLPCNT SELECT LessonPlanId, COUNT(1) AS CNT FROM #TMPLP GROUP BY LessonPlanId		
		
	SET @TMPCount=(SELECT COUNT(ID) FROM #TMPLPCNT)
	SET @TMPLoopCount=1
	WHILE(@TMPCount>0)
	BEGIN
		SET @LessId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount)
		IF((SELECT CalcTypeCNT FROM #TMPLPCNT WHERE ID=@TMPLoopCount)>2)
		BEGIN
			IF((SELECT COUNT(Scoreid) FROM #TEMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency','Avg Duration','Customize')
				AND LessonPlanId=@LessId)>0)
			BEGIN
				UPDATE #TEMP SET DummyScore=Score WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency','Avg Duration','Customize') 
					AND LessonPlanId=@LessId

				UPDATE #TEMP SET Score = NULL WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency','Avg Duration','Customize') AND LessonPlanId=@LessId

				UPDATE #TEMP SET LeftYaxis=(SELECT STUFF((SELECT '/ '+ RptLabel FROM 
					(SELECT DISTINCT RptLabel FROM #TEMP TMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency','Avg Duration','Customize','Event') 
					AND TMP.LessonPlanId=@LessId AND (SELECT COUNT(Scoreid) FROM #TEMP TP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
					'Avg Duration','Customize') AND TP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>0) LP FOR XML PATH('')),1,1,'')) 
				WHERE #TEMP.LessonPlanId=@LessId AND CalcType <> 'Event'

				UPDATE #TEMP SET RightYaxis=(SELECT STUFF((SELECT '/ '+ RptLabel 
					FROM (SELECT DISTINCT RptLabel FROM #TEMP TMP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency','Avg Duration','Customize') 
					AND TMP.LessonPlanId=@LessId AND (SELECT COUNT(Scoreid) FROM #TEMP TP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
					'Avg Duration','Customize') AND TP.LessonPlanId=(SELECT LessonPlanId FROM #TMPLPCNT WHERE ID=@TMPLoopCount))>0) LP FOR XML PATH('')),1,1,'')) 
				WHERE #TEMP.LessonPlanId=@LessId AND CalcType <> 'Event'

				UPDATE #TEMP SET LeftYaxis=(CASE WHEN LeftYaxis IS NULL THEN RightYaxis ELSE LeftYaxis END) WHERE LessonPlanId=@LessId AND CalcType <> 'Event'
				UPDATE #TEMP SET RightYaxis=(CASE WHEN LeftYaxis=RightYaxis THEN NULL ELSE RightYaxis END) WHERE LessonPlanId=@LessId AND CalcType <> 'Event'

				IF((SELECT COUNT(Scoreid) FROM #TEMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency','Avg Duration','Customize') 
					AND LessonPlanId=@LessId)>=2)
				BEGIN
					UPDATE #TEMP SET LeftYaxis='Percent'  WHERE LessonPlanId=@LessId AND CalcType <> 'Event'
				END
			END
		END
		ELSE
		BEGIN
			IF((SELECT CalcTypeCNT FROM #TMPLPCNT WHERE ID=@TMPLoopCount)=2)
			BEGIN				
				UPDATE #TEMP SET DummyScore=Score WHERE LessonPlanId=@LessId AND CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=@LessId ORDER BY ID DESC) 				
				UPDATE #TEMP SET Score = NULL WHERE LessonPlanId=@LessId AND CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=@LessId ORDER BY ID DESC) 		
				UPDATE #TEMP SET LeftYaxis=(SELECT TOP 1 RptLabel FROM #TEMP WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=@LessId ORDER BY ID ) 
					AND LessonPlanId=@LessId) WHERE #TEMP.LessonPlanId=@LessId AND CalcType <> 'Event'
				UPDATE #TEMP SET RightYaxis=(SELECT TOP 1 RptLabel FROM #TEMP WHERE CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=@LessId ORDER BY ID DESC) 
					AND LessonPlanId=@LessId) WHERE #TEMP.LessonPlanId=@LessId AND CalcType <> 'Event'
			END
			ELSE
			BEGIN
				--UPDATE #TEMP SET LeftYaxis=(SELECT TOP 1 RptLabel FROM #TEMP WHERE 
				--CalcType = (SELECT TOP 1 CalcType FROM #TMPLP WHERE LessonPlanId=@LessId)) 
				--WHERE LessonPlanId=@LessId AND CalcType <> 'Event'

				UPDATE #TEMP SET LeftYaxis=RptLabel FROM #TEMP
				WHERE LessonPlanId=@LessId AND CalcType <> 'Event'
			END
		END
		SET @TMPLoopCount=@TMPLoopCount+1
		SET @TMPCount=@TMPCount-1
	END
		
	DROP TABLE #TMPLPCNT
	DROP TABLE #TMPLP
	--/////////////////////////////////////////////////////////////////
	
	UPDATE #TEMP  SET NonPercntCount=(SELECT COUNT(DISTINCT CalcType) FROM #TEMP TMP WHERE CalcType IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
		'Avg Duration','Customize') AND TMP.LessonPlanId=#TEMP.LessonPlanId)
	
	UPDATE #TEMP SET PercntCount=(SELECT COUNT(DISTINCT CalcType) FROM #TEMP TMP WHERE CalcType NOT IN ('Total Duration','Total Correct','Total Incorrect','Frequency',
		'Avg Duration','Customize','Event') AND TMP.LessonPlanId=#TEMP.LessonPlanId)

	UPDATE #TEMP SET ColName=(SELECT Data FROM [dbo].[SplitWithRow] (#TEMP.ColRptLabelLP,'@') WHERE RWNMBER=3) WHERE CalcType <> 'Event'
	

	------------- Coloring Fix start---------------------
	SET @CNTLP=1
	SET @ColRptLabelLP=''

	CREATE TABLE #COLORING (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), Lessonplanid INT, ColRptLabelLP VARCHAR(500), Rownum INT);

	CREATE NONCLUSTERED INDEX idx_coloring_LessonPlanId ON #COLORING (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_coloring_ColRptLabelLP ON #COLORING (ColRptLabelLP);

	INSERT INTO #COLORING(Lessonplanid, ColRptLabelLP) SELECT LessonPlanId, ColRptLabelLP FROM #TEMP WHERE ColRptLabelLP IS NOT NULL GROUP BY LessonPlanId,ColRptLabelLP

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
			UPDATE #TEMP SET Color='Blue' WHERE ColRptLabelLP=@ColRptLabelLP
		END
		ELSE IF(@TMPCount=2)
		BEGIN
			UPDATE #TEMP SET Color='Red' WHERE ColRptLabelLP=@ColRptLabelLP
		END
		ELSE
		BEGIN
			UPDATE #TEMP SET Color='Black' WHERE ColRptLabelLP=@ColRptLabelLP
		END
		
		UPDATE #TEMP SET Shape=(SELECT Shape FROM Color WHERE ColorId=@CNTLP) WHERE ColRptLabelLP=@ColRptLabelLP
		SET @CNTLP=@CNTLP+1
        FETCH NEXT FROM db_cursor INTO @ColRptLabelLP , @TMPCount;
	END   

	CLOSE db_cursor   
	DEALLOCATE db_cursor

	DROP TABLE #COLORING


	DECLARE @Date DATETIME

	CREATE TABLE #TAB(ID INT PRIMARY KEY NOT NULL IDENTITY(1,1), LessonPlanId INT, AggredatedDate DATETIME);

	CREATE NONCLUSTERED INDEX idx_tab_LessonPlanId ON #TAB (LessonPlanId);
	CREATE NONCLUSTERED INDEX idx_tab_AggredatedDate ON #TAB (AggredatedDate);

	INSERT INTO #TAB SELECT LessonPlanId, AggredatedDate FROM (SELECT LessonPlanId, AggredatedDate,COUNT(1) cnt FROM #TEMP WHERE CalcType='Event' 
		GROUP BY LessonPlanId, AggredatedDate) evnt WHERE cnt>1
	SET @Cnt=(SELECT COUNT(ID) FROM #TAB)	
	WHILE(@Cnt>0)
	BEGIN
		SELECT @LessId = LessonPlanId, @Date = AggredatedDate FROM #TAB WHERE ID=@Cnt
		UPDATE #TEMP SET Comment='1' WHERE EventType='Minor' AND CalcType='Event' AND LessonPlanId = @LessId AND AggredatedDate = @Date 
		SET @Cnt=@Cnt-1
	END

	-- To avoid IOA info appearing on Academic graphs twice when there is more than one measurements for a lesson.
	IF (@TempIncludeIOA='true')
	BEGIN
		CREATE TABLE #IOA (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), LessonId INT, AggDate DATE)

		CREATE NONCLUSTERED INDEX idx_ioa_LessonId ON #IOA (LessonId);
		CREATE NONCLUSTERED INDEX idx_ioa_AggDate ON #IOA (AggDate);

		INSERT INTO #IOA SELECT LessonPlanid, AggredatedDate FROM #TEMP WHERE IOAPerc IS NOT NULL
		SET @CNT=1
		DECLARE @IOACNT INT=(SELECT COUNT(ID) FROM #IOA)
		WHILE(@IOACNT>0)
		BEGIN
			SELECT @LessId = LessonId, @Date = AggDate FROM #IOA WHERE ID=@CNT

			IF ((SELECT Score FROM #TEMP WHERE AggredatedDate=@Date AND LessonPlanId=@LessId AND scoreid=(SELECT TOP (1) Scoreid FROM #TEMP WHERE AggredatedDate=@Date 
				AND LessonPlanId=@LessId ORDER BY scoreid DESC)) IS NOT NULL
				OR (SELECT DummyScore FROM #TEMP WHERE AggredatedDate=@Date AND LessonPlanId=@LessId AND scoreid=(SELECT TOP (1) Scoreid FROM #TEMP WHERE AggredatedDate=@Date 
				AND LessonPlanId=@LessId ORDER BY scoreid DESC)) IS NOT NULL)
					UPDATE #TEMP SET IOAPerc=NULL WHERE AggredatedDate=@Date AND LessonPlanId=@LessId AND scoreid NOT IN (SELECT TOP (1) Scoreid FROM #TEMP WHERE AggredatedDate=@Date 
					AND LessonPlanId=@LessId ORDER BY scoreid DESC)
			SET @CNT=@CNT+1
			SET @IOACNT=@IOACNT-1
		END
		DROP TABLE #IOA
	END

	SELECT * FROM	
	(SELECT Scoreid,LessonPlanId, CalcType, Score, AggredatedDate, ClassType, Trend, IOAPerc, ArrowNote, EventType, EventName, RptLabel, ColRptLabelLP, DummyScore, LeftYaxis, 
		RightYaxis, NonPercntCount,PercntCount,ColName, Color, Shape 		
		,(SELECT TOP 1 LessonOrder FROM DSTempHdr WHERE LessonPlanId=#TEMP.LessonPlanId AND StudentId=@TempStudentId ORDER BY LessonOrder DESC) LOrder
	FROM #TEMP
	) LPO
	ORDER BY LOrder,Scoreid
END


GO
