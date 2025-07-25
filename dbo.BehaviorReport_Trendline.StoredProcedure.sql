USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[BehaviorReport_Trendline]    Script Date: 7/4/2025 1:21:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[BehaviorReport_Trendline] @StartDate DATETIME,
                                                 @ENDDate   DATETIME,
                                                 @Studentid INT,
                                                 @SchoolId  INT,
                                                 @Behavior  VARCHAR(500),
                                                 @Trendtype VARCHAR(50),
                                                 @Event     VARCHAR(50),
												 @ClassType VARCHAR(500)
AS
  BEGIN
      SET nocount ON;

      DECLARE @SDate                 DATETIME,
              @EDate                 DATETIME,
              @SID                   INT,
              @BehaviorIDs           VARCHAR(500),
              @School                INT,
              @LCount                INT,
              @TempLPId              INT,
              @LoopBehavior          INT,
              --@ClassType             VARCHAR(50),
			  @Evnt			 VARCHAR(50),
			  @ClsType       VARCHAR(50),
			  @ClassTypeFlag VARCHAR(50),
              @Cnt                   INT,
              @Frequency             INT,
              @Scoreid               INT,
              @NullcntFrequency      INT,
              @NullcntDuration       INT,
              @Breaktrendfrequencyid INT,
              @Breaktrenddurationid  INT,
              @BreakTrenddate        DATETIME,
              @TType                 VARCHAR(50),
              @NumOfTrend            INT,
              @TrendsectionNo        INT,
              @DateCnt               INT,
              @Midrate1              FLOAT,
              @Midrate2              FLOAT,
              @Slope                 FLOAT,
              @Const                 FLOAT,
              @Ids                   INT,
              @IdOfTrend             INT,
              @SUM_XI                FLOAT,
              @SUM_YI                FLOAT,
              @SUM_XX                FLOAT,
              @SUM_XY                FLOAT,
              @X1                    FLOAT,
              @Y1                    FLOAT,
              @Z1                    FLOAT,
              @X2                    FLOAT,
              @Y2                    FLOAT,
              @Z2                    FLOAT,
              @A                     FLOAT,
              @B                     FLOAT,
              @TMPBehavior           INT,
              @TMPClassType          VARCHAR(50),
              @TMPDate               DATETIME,
              @TMPStartDate          DATETIME,
              @TMPEndDate            DATETIME,
              @TMPCount              INT,
              @TMPLoopCount          INT,
              @TMPSesscnt            INT,
              @BehaviorOld           INT,
              @OldTMPDate            DATETIME,
              @Duration              INT,
              @CNTBEHAV              INT,
              @ARROWCNT              INT,
              @ARROWID               INT,
              @CNTBEHAVLP            INT,
              @DupEvent              INT,
              @SumTotal              INT,
              @PerInterval           FLOAT,
			  @PerOppo               FLOAT,
              @COUNT                 INT,
              @FRQ_CNT               INT,
              @MID                   INT,
              @FRQ                   INT,
              @DATE                  DATE,
              @IOACOUNT              INT,
              @IOAfrq                FLOAT,
              @IOAdur                FLOAT,
              @CREATD_ON             DATETIME,
              @Time                  DATETIME,
              @CREATD_BY             VARCHAR(50)
      DECLARE @splt TABLE
        (
           data INT
        )

      SET @SDate=@StartDate
      SET @EDate=@ENDDate+ ' 23:59:59.900'
      SET @SID=@Studentid
      SET @BehaviorIDs=@Behavior
      SET @School=@SchoolId
      SET @LCount=0
      SET @TempLPId=0
      SET @LoopBehavior=0
	  SET @ClsType=@ClassType
	  SET @Evnt=@Event
      --SET @ClassType=''
      SET @Cnt=1
      SET @Scoreid=0
      SET @NullcntFrequency=0
      SET @NullcntDuration=0
      SET @Breaktrendfrequencyid=1
      SET @Breaktrenddurationid=1
      SET @TType=@Trendtype
      SET @NumOfTrend=0
      SET @TrendsectionNo=0
      SET @TMPBehavior =0
      SET @TMPClassType =''
      SET @TMPStartDate= @StartDate
      SET @TMPEndDate =@ENDDate+ ' 23:59:59.900'
      SET @TMPCount=0
      SET @TMPLoopCount=1
      SET @TMPSesscnt=1
      SET @BehaviorOld=0

      --=============[ New Section for Batch dynamic Updation - Start ] =================================================================================================================
      	
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
	  
	  DECLARE @StdtAgg_splt TABLE
        (
		id INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           data INT
        )
      DECLARE @Counts INT

	  DECLARE @BehCount INT

      INSERT INTO @StdtAgg_splt
      SELECT *
      FROM   Split(@BehaviorIDs, ',')

	  SET @BehCount = (SELECT Count(*)
                      FROM   @StdtAgg_splt)

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
           [colrptlabellp]      [VARCHAR](max) NULL
        )
      ON [PRIMARY]
      textimage_on [PRIMARY]

      --========================================================--
      --INSERT BEHAVIOR DETAILS TO [dbo].[StdtAggScores] TABLE
      --========================================================--
      INSERT INTO #temp_stdtaggscores
                  (schoolid,
                   studentid,
                   classid,
                   measurementid,
                   aggredateddate,
                   frequency,
                   duration,
                   classtype,
                   rate)
      SELECT schoolid,
             studentid,
             classid,
             measurementid,
             perioddate,
             frequncy,
             Round(durationmin, 2) DurationMin,
             classtype,
             Round(( CASE
                       WHEN frequncy IS NOT NULL
                            AND frequncy <> 0 THEN
                         CASE
                           WHEN partialinterval = 'True' THEN
                           CONVERT(FLOAT, frequncy) /
                           (
                           CONVERT(FLOAT,
                           ( period * numoftimes
                           ))
                           )
                           --/60
                           ELSE CONVERT(FLOAT, frequncy) / ( (
                                CONVERT(FLOAT, (SELECT
                                Datediff(hh, CONVERT(
                                DATETIME, starttime
                                             ),
                                CONVERT(
                                  DATETIME, endtime))
                                                FROM   schoolcal
                                                WHERE
                                weekday = (SELECT Datename
                                          (dw, perioddate)
                                          )
                                AND schoolcal.residenceind
                                    = BEH.residenceind
                                AND schoolcal.schoolid =
                                    BEH.schoolid)) ) * 60
                                   )
                         END
                     END ), 2)     AS Rate
      FROM   (SELECT BDS.schoolid,
                     BDS.studentid,
                     BDS.classid,
                     BDS.measurementid,
                     CONVERT(DATETIME,CONVERT(
                                  DATE,B.timeofevent)) as perioddate,
                     BDS.period,
                     CASE
                               WHEN BDS.numoftimes = 0 THEN 1
                               ELSE BDS.numoftimes
                             END AS NumOfTimes,
                     Cls.residenceind,
                     --(SELECT Sum(frequencycount)
                     -- FROM   behaviour BR
                     -- WHERE  CONVERT(DATE, timeofevent) =
                     --        CONVERT(DATE, TimeOfEvent)
                     --        AND BR.measurementid = BDS.measurementid)
                     0 AS
                     Frequncy,
                     --(SELECT ( Sum(CONVERT(FLOAT, BR.duration)) ) / 60
                     -- FROM   behaviour BR
                     -- WHERE  CONVERT(DATE, timeofevent) =
                     --        CONVERT(DATE, TimeOfEvent)
                     --        AND BR.measurementid = BDS.measurementid)
                     0 AS
                            DurationMin,
                     --CASE
                     --  WHEN Cls.residenceind = 1 THEN 'Residence'
                     --  ELSE 'Day'
                     --END
                     @ClsType as ClassType,
                     BDS.partialinterval
              FROM   behaviour B
							INNER JOIN 
			  behaviourdetails BDS ON B.measurementid = BDS.measurementid
                     INNER JOIN class Cls
                         ON Cls.classid = BDS.classid
                      WHERE  BDS.activeind IN( 'A', 'N' )
                             AND BDS.schoolid = @School
                             AND BDS.studentid = @SID
							 AND B.timeofevent >= @SDate
						AND B.timeofevent <= @EDate
						AND B.measurementid IN (SELECT data
                                               FROM   @StdtAgg_splt)
						--AND Cls.residenceind IN (SELECT data
				  		--FROM   Split(@ClassTypeFlag, ','))

                     --AND rp.perioddate BETWEEN @StartDate AND @ENDDate
                     --AND ( rp.period <> 0
                            --OR rp.period IS NULL )
							GROUP BY B.measurementid,
							BDS.behaviour,
							CONVERT(
                                  DATE,B.timeofevent),		 
							B.classid,
							BDS.ClassId,
							BDS.SchoolId,
							BDS.StudentId,
							BDS.MeasurementId,
							BDS.Period,
							BDS.NumOfTimes,
							cls.ResidenceInd,
							BDS.PartialInterval) BEH

							DECLARE @TotalCNT INT,
							@MeasurementId INT
							SET @TotalCNT= (SELECT Count(*)
                      FROM   @StdtAgg_splt)
      DECLARE @MesCNT INT =1

      WHILE( @MesCNT <= @TotalCNT)
        BEGIN
		SET @MeasurementId = (SELECT data
                             FROM   @StdtAgg_splt
                             WHERE  id = @MesCNT)
		UPDATE #temp_stdtaggscores

		SET frequency = (SELECT SUM(B.FrequencyCount) FROM behaviour B INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
															            LEFT JOIN class C ON C.classid = B.classid
													  WHERE B.StudentId = @SID AND D.activeind IN( 'A', 'N' )											   
																						AND B.measurementid = @MeasurementId
																						AND B.timeofevent >= @SDate
																						AND B.timeofevent <= @EDate
																						AND B.StudentId=@SID
																						AND B.FrequencyCount IS NOT NULL 
																						AND CONVERT(DATE,#temp_stdtaggscores.aggredateddate) = CONVERT(DATE,B.TimeOfEvent)
																						AND C.residenceind IN (SELECT data FROM   Split(@ClassTypeFlag, ','))

													  GROUP BY B.MeasurementId)
		WHERE #temp_stdtaggscores.measurementid = @MeasurementId
		
		
		UPDATE #temp_stdtaggscores
		SET duration = (SELECT ROUND((SELECT Sum(CONVERT(FLOAT, b.duration))/60) ,2) FROM behaviour B INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
																									  LEFT JOIN class C ON C.classid = B.classid
																					WHERE B.StudentId = @SID AND D.activeind IN( 'A', 'N' )											   
																													AND B.measurementid = @MeasurementId
																													AND B.timeofevent >= @SDate
																													AND B.timeofevent <= @EDate
																													AND B.StudentId=@SID
																													AND B.duration IS NOT NULL 
																													AND CONVERT(DATE,#temp_stdtaggscores.aggredateddate) = CONVERT(DATE,B.TimeOfEvent)
																													AND C.residenceind IN (SELECT data FROM   Split(@ClassTypeFlag, ','))
																					GROUP BY B.MeasurementId)
	   WHERE #temp_stdtaggscores.measurementid = @MeasurementId

		--UPDATE #temp_stdtaggscores
		--SET rate = Round(( CASE WHEN #temp_stdtaggscores.frequency IS NOT NULL AND #temp_stdtaggscores.frequency <> 0 
		--				THEN CASE WHEN partialinterval = 'True' THEN CONVERT(FLOAT, #temp_stdtaggscores.frequency) / ( CONVERT(FLOAT, ( period * numoftimes ))) --/60
		--				ELSE CONVERT(FLOAT, #temp_stdtaggscores.frequency) / ((CONVERT(FLOAT, (SELECT Datediff(hh, CONVERT( DATETIME, starttime), CONVERT(DATETIME, endtime)) FROM   schoolcal
  --                              WHERE weekday = (SELECT Datename (dw, d.PartialInterval))
		--						AND schoolcal.residenceind = c.residenceind
		--						AND schoolcal.schoolid = d.schoolid)) ) * 60) 
		--				END 
		--			END ), 2)
		--FROM   behaviour B INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
		--			LEFT JOIN class C ON C.classid = B.classid
		--	WHERE B.StudentId = @StudentId AND D.activeind IN( 'A', 'N' )
		--						AND B.timeofevent >= @StartDate
		--						AND B.timeofevent <= @EndDate
		--						AND B.measurementid = @MeasurementId
		--				--AND (C.residenceind IN (SELECT data 
		--				--					   FROM Split(@ClassTypeFlag, ',')) OR C.ResidenceInd IS NULL)

		--	SET @TotalCNT=@TotalCNT - 1
            SET @MesCNT=@MesCNT + 1
		END

      --========================================================--
      -- Update Behavior IOA value to [dbo].[StdtAggScores] TABLE
      --========================================================--
      CREATE TABLE #temps
        (
           id             INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           ioafrequency   VARCHAR(50),
           ioaduration    VARCHAR(50),
           schoolid       INT,
           studentid      INT,
           measurementid  INT,
           dateofbahavior DATETIME,
           ioauser        INT
        );

      --/*
      INSERT INTO #temps
      SELECT CASE
               WHEN ( PARTIAL.frequncy ) > ( PARTIALIOA.frequncy ) THEN Round((
               ( CONVERT(FLOAT, ( PARTIALIOA.frequncy )) / CONVERT(FLOAT,
             ( PARTIAL.frequncy
             )
             )
             ) * 100 ), 2)
               ELSE Round(( ( CONVERT(FLOAT, ( PARTIAL.frequncy )) /
                              CONVERT(FLOAT, (
                              PARTIALIOA.frequncy
                                             ))
                            ) * 100 ), 2)
             END AS IOAFrequency,
             CASE
               WHEN ( PARTIAL.durationmin ) > ( PARTIALIOA.durationmin ) THEN
               Round((
               ( CONVERT(FLOAT, ( PARTIALIOA.durationmin )) / CONVERT(FLOAT,
                         (
                     PARTIAL.durationmin
                     )) ) * 100 ), 2)
               ELSE Round(( ( CONVERT(FLOAT, ( PARTIAL.durationmin )) /
                              CONVERT(FLOAT, (
                                             PARTIALIOA.durationmin )) ) * 100 )
                    ,
                    2)
             END AS IOADuration,
             PARTIAL.schoolid,
             PARTIAL.studentid,
             PARTIAL.measurementid,
             PARTIAL.date,
             PARTIALIOA.ioauser
      FROM   (SELECT Sum(BHR.frequencycount)                AS Frequncy,
                     Sum(CONVERT(FLOAT, BHR.duration)) / 60 AS DurationMin,
                     CALC.starttime,
                     CALC.endtime,
                     CALC.date,
                     BDS.studentid,
                     BDS.schoolid,
                     BDS.measurementid
              FROM   behaviourcalc CALC
                     INNER JOIN behaviour BHR
                             ON CALC.measurmentid = BHR.measurementid
                     INNER JOIN behaviourdetails BDS
                             ON BDS.measurementid = BHR.measurementid
					 INNER JOIN class Cls
                       ON Cls.classid = BDS.classid
              WHERE  ispartial = 1
                     AND observerid != ioauser
                     AND CONVERT(DATE, BHR.createdon) = CONVERT(DATE, CALC.date)
                     AND CALC.activeind IN ( 'N', 'A' )
                     AND CONVERT(TIME, BHR.createdon) BETWEEN
                         CONVERT(TIME, CALC.starttime) AND CONVERT(
                         TIME, CALC.endtime)
                     AND BHR.createdon >= @SDate
                     AND CALC.measurmentid IN (SELECT data
                                               FROM   @StdtAgg_splt)
					AND Cls.residenceind IN (SELECT data
				   FROM   Split(@ClassTypeFlag, ','))
              --<============================== added conditon
              GROUP  BY BDS.studentid,
                        BDS.schoolid,
                        BDS.measurementid,
                        BDS.frequency,
                        BDS.duration,
                        CALC.starttime,
                        CALC.endtime,
                        CALC.date) PARTIAL
             JOIN (SELECT Sum(BHR.frequencycount)                AS Frequncy,
                          Sum(CONVERT(FLOAT, BHR.duration)) / 60 AS DurationMin,
                          CALC.starttime,
                          CALC.endtime,
                          CALC.date,
                          BDS.studentid,
                          BDS.schoolid,
                          BDS.measurementid,
                          ioauser
                   FROM   behaviourcalc CALC
                          INNER JOIN behaviour BHR
                                  ON CALC.measurmentid = BHR.measurementid
                          INNER JOIN behaviourdetails BDS
                                  ON BDS.measurementid = BHR.measurementid
						  INNER JOIN class Cls
                       ON Cls.classid = BDS.classid
                   WHERE  ispartial = 1
                          AND ioaflag = 1
                          AND observerid = ioauser
                          AND CONVERT(DATE, BHR.createdon) =
                              CONVERT(DATE, CALC.date)
                          AND CALC.activeind IN ( 'N', 'A' )
                          AND CONVERT(TIME, BHR.createdon) BETWEEN
                              CONVERT(TIME, CALC.starttime) AND CONVERT(
                              TIME, CALC.endtime)
                          AND BHR.createdon >= @SDate
                          AND CALC.measurmentid IN (SELECT data
                                                    FROM   @StdtAgg_splt)
						  AND Cls.residenceind IN (SELECT data
				   FROM   Split(@ClassTypeFlag, ','))
                   --<============================== added conditon
                   GROUP  BY BDS.studentid,
                             BDS.schoolid,
                             BDS.measurementid,
                             BDS.frequency,
                             BDS.duration,
                             CALC.starttime,
                             CALC.endtime,
                             CALC.date,
                             ioauser) PARTIALIOA
               ON 1 = 1

      SET @Counts=1

      WHILE( @Counts <= (SELECT Count(*)
                         FROM   #temps) )
        BEGIN
            UPDATE #temp_stdtaggscores
            SET    ioafrequency = 'IOA ' + CONVERT(VARCHAR(50), (SELECT CONVERT(
                                  DECIMAL(
                                  3), Round(
                                         ioafrequency, 0)
                                         ) FROM #temps WHERE id=@Counts)) + ' %'
                   ,
                   ioaduration = 'IOA ' + CONVERT(VARCHAR(50
                                 ), (SELECT CONVERT(
                                 DECIMAL
                                 (3
                                 ),
                                 Round(
                                 ioaduration, 0))
                                 FROM #temps WHERE id=@Counts)) + ' %',
                   ioauser = (SELECT ioauser
                              FROM   #temps
                              WHERE  id = @Counts)
            WHERE  schoolid = (SELECT schoolid
                               FROM   #temps
                               WHERE  id = @Counts)
                   AND studentid = (SELECT studentid
                                    FROM   #temps
                                    WHERE  id = @Counts)
                   AND measurementid = (SELECT measurementid
                                        FROM   #temps
                                        WHERE  id = @Counts)
                   AND aggredateddate = (SELECT dateofbahavior
                                         FROM   #temps
                                         WHERE  id = @Counts)

            SET @Counts=@Counts + 1
        END

      DROP TABLE #temps

      --*/
      CREATE TABLE #temp1
        (
           id             INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           ioafrequency   VARCHAR(50),
           ioaduration    VARCHAR(50),
           schoolid       INT,
           studentid      INT,
           measurementid  INT,
           dateofbahavior DATETIME,
           ioauser        INT
        );

      INSERT INTO #temp1
      SELECT CASE
               WHEN ( NONPARTIAL.frequncy ) > ( NONPARTIALIOA.frequncy ) THEN
               Round(( ( CONVERT(FLOAT, ( NONPARTIALIOA.frequncy )) / CONVERT(
                         FLOAT, (
             NONPARTIAL.frequncy
             )) ) * 100 ), 2)
               ELSE Round(( ( CONVERT(FLOAT, ( NONPARTIAL.frequncy )) /
                              CONVERT(FLOAT, (
                                             NONPARTIALIOA.frequncy )) ) * 100 )
                    ,
                    2)
             END AS IOAFrequency,
             CASE
               WHEN ( NONPARTIAL.durationmin ) > ( NONPARTIALIOA.durationmin )
             THEN
               Round(( ( CONVERT(FLOAT, ( NONPARTIALIOA.durationmin )) /
                         CONVERT(FLOAT, (
             NONPARTIAL.durationmin
             )) ) * 100 ), 2)
               ELSE Round(( ( CONVERT(FLOAT, ( NONPARTIAL.durationmin )) /
                                             CONVERT(FLOAT, (
                                             NONPARTIALIOA.durationmin )) ) *
                            100
                          ), 2
                    )
             END AS IOADuration,
             NONPARTIAL.schoolid,
             NONPARTIAL.studentid,
             NONPARTIAL.measurementid,
             NONPARTIAL.date,
             NONPARTIALIOA.ioauser
      FROM   (SELECT Sum(BHR.frequencycount)                AS Frequncy,
                     Sum(CONVERT(FLOAT, BHR.duration)) / 60 AS DurationMin,
                     CALC.starttime,
                     CALC.endtime,
                     CALC.date,
                     BDS.studentid,
                     BDS.schoolid,
                     BDS.measurementid
              FROM   behaviourcalc CALC
                     INNER JOIN behaviour BHR
                             ON CALC.measurmentid = BHR.measurementid
                     INNER JOIN behaviourdetails BDS
                             ON BDS.measurementid = BHR.measurementid
					 INNER JOIN class Cls
                       ON Cls.classid = BDS.classid
              WHERE  ispartial = 0
                     AND observerid != ioauser
                     AND CONVERT(DATE, BHR.createdon) = CONVERT(DATE, CALC.date)
                     AND CALC.activeind IN ( 'N', 'A' )
                     AND CONVERT(TIME, BHR.createdon) BETWEEN
                         CONVERT(TIME, CALC.starttime) AND CONVERT(
                         TIME, CALC.endtime)
                     AND BHR.createdon >= @SDate
					 AND BHR.StudentId=@SID
                     AND CALC.measurmentid IN (SELECT data
                                               FROM   @StdtAgg_splt)
					AND Cls.residenceind IN (SELECT data
				   FROM   Split(@ClassTypeFlag, ','))
              --<============================== added conditon
              GROUP  BY BDS.studentid,
                        BDS.schoolid,
                        BDS.measurementid,
                        BDS.frequency,
                        BDS.duration,
                        CALC.starttime,
                        CALC.endtime,
                        CALC.date) NONPARTIAL
             JOIN (SELECT Sum(BHR.frequencycount)                AS Frequncy,
                          Sum(CONVERT(FLOAT, BHR.duration)) / 60 AS DurationMin,
                          CALC.starttime,
                          CALC.endtime,
                          CALC.date,
                          BDS.studentid,
                          BDS.schoolid,
                          BDS.measurementid,
                          ioauser
                   FROM   behaviourcalc CALC
                          INNER JOIN behaviour BHR
                                  ON CALC.measurmentid = BHR.measurementid
                          INNER JOIN behaviourdetails BDS
                                  ON BDS.measurementid = BHR.measurementid
						  INNER JOIN class Cls
                       ON Cls.classid = BDS.classid
                   WHERE  ispartial = 0
                          AND ioaflag = 1
                          AND observerid = ioauser
                          AND CONVERT(DATE, BHR.createdon) =
                              CONVERT(DATE, CALC.date)
                          AND CALC.activeind IN ( 'N', 'A' )
                          AND CONVERT(TIME, BHR.createdon) BETWEEN
                              CONVERT(TIME, CALC.starttime) AND CONVERT(
                              TIME, CALC.endtime)
                          AND BHR.createdon >= @EDate
						  AND BHR.StudentId=@SID
                          --AND BHR.CreatedOn >= @LoadDate --(Removed beacuse it is for in batch mode)
                          AND CALC.measurmentid IN (SELECT data
                                                    FROM   @StdtAgg_splt)
						  AND Cls.residenceind IN (SELECT data
				   FROM   Split(@ClassTypeFlag, ','))
                   --<============================== added conditon
                   GROUP  BY BDS.studentid,
                             BDS.schoolid,
                             BDS.measurementid,
                             BDS.frequency,
                             BDS.duration,
                             CALC.starttime,
                             CALC.endtime,
                             CALC.date,
                             ioauser) NONPARTIALIOA
               ON 1 = 1

      SET @Counts=1

      WHILE( @Counts <= (SELECT Count(*)
                         FROM   #temp1) )
        BEGIN
            UPDATE #temp_stdtaggscores
            SET    ioafrequency = 'IOA '
                                  + (SELECT CONVERT(DECIMAL(3),
                                            Round(ioafrequency, 0)
                                            )
                                     FROM   #temp1
                                     WHERE  id = @Counts)
                                  + ' %',
                   ioaduration = 'IOA '
                                 + (SELECT CONVERT(DECIMAL(3),
                                           Round(ioaduration, 0))
                                    FROM   #temp1
                                    WHERE  id = @Counts)
                                 + ' %',
                   ioauser = (SELECT ioauser
                              FROM   #temp1
                              WHERE  id = @Counts)
            WHERE  schoolid = (SELECT schoolid
                               FROM   #temp1
                               WHERE  id = @Counts)
                   AND studentid = (SELECT studentid
                                    FROM   #temp1
                                    WHERE  id = @Counts)
                   AND measurementid = (SELECT measurementid
                                        FROM   #temp1
                                        WHERE  id = @Counts)
                   AND aggredateddate = (SELECT dateofbahavior
                                         FROM   #temp1
                                         WHERE  id = @Counts)

            SET @Counts=@Counts + 1
        END

      DROP TABLE #temp1

      ----select * from #Temp_StdtAggscores
      --=============[ New Section for Batch dynamic Updation - End ] =================================================================================================================
      IF Object_id('tempdb..#TEMP') IS NOT NULL
        DROP TABLE #temp

      INSERT INTO @splt
      SELECT *
      FROM   Split(@BehaviorIDs, ',')

      DECLARE @AGGSCORE TABLE
        (
           id            INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           measurementid INT,
           frequency     INT,
           duration      FLOAT,
           rate          FLOAT,
           aggdate       DATETIME,
           ioafrequency  VARCHAR(50),
           ioaduration   VARCHAR(50),
           arrownote     VARCHAR(500),
           classtype     VARCHAR(50)
        );

      --SELECT ALL LESSON DETAILS BETWEEN STARTDATE AND ENDDATE FROM THE TABLE 'StdtAggScores' AND INSERT IT TO #AGGSCORE TABLE
      INSERT INTO @AGGSCORE
      SELECT DISTINCT measurementid,
                      frequency,
                      duration,
                      rate,
                      aggredateddate,
                      ioafrequency,
                      ioaduration,
                      eventname,
                      classtype
      FROM   #temp_stdtaggscores
      WHERE  aggredateddate BETWEEN @SDate AND @EDate
             AND studentid = @SID
             AND schoolid = @School
             AND stdtsesseventid IS NULL
             AND measurementid IN (SELECT *
                                   FROM   @splt)
      ORDER  BY measurementid,
                aggredateddate

      --SELECT * FROM #AGGSCORE
      CREATE TABLE #temp
        (
           scoreid             INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           measurementid       INT,
           frequency           FLOAT,
           duration            FLOAT,
           rate                FLOAT,
           ioapercfrq          VARCHAR(50),
           ioapercdur          VARCHAR(50),
           aggredateddate      DATETIME,
           breaktrendfrequency INT,
           breaktrendduration  INT,
           xvalue              INT,
           trendfrequency      FLOAT,
           trendduration       FLOAT,
           ioafrequency        VARCHAR(50),
           ioaduration         VARCHAR(50),
           behaviour           VARCHAR(500),
           arrownote           VARCHAR(500),
           eventtype           VARCHAR(50),
           eventname           NVARCHAR(max),
           evntts              DATETIME,
           endtime             DATETIME,
           comment             VARCHAR(500),
           classtype           VARCHAR(50),
           frqstat             INT
        );

      SET @TMPCount = (SELECT Count(*)
                       FROM   @AGGSCORE)

      WHILE( @TMPCount > 0 )
        BEGIN
            SELECT @BehaviorOld = measurementid,
                   @OldTMPDate = aggdate
            FROM   @AGGSCORE
            WHERE  id = ( @TMPLoopCount - 1 )

            SELECT @TMPBehavior = measurementid,
                   @TMPDate = aggdate
            FROM   @AGGSCORE
            WHERE  id = @TMPLoopCount

            --SET @TMPBehavior=(SELECT MeasurementId FROM #AGGSCORE WHERE ID=@TMPLoopCount)
            --SET @TMPDate=(SELECT AggDate FROM #AGGSCORE WHERE ID=@TMPLoopCount)
            IF( @TMPDate <= @OldTMPDate )
              BEGIN
                  WHILE( @OldTMPDate <= @EDate )
                    BEGIN
                        SET @OldTMPDate=Dateadd(day, 1, @OldTMPDate)

                        INSERT INTO #temp
                                    (measurementid,
                                     aggredateddate,
                                     xvalue)
                        VALUES      ( @BehaviorOld,
                                      @OldTMPDate,
                                      @TMPSesscnt)

                        SET @TMPSesscnt=@TMPSesscnt + 1
                    END
              END

            IF( @TMPBehavior <> @BehaviorOld )
              BEGIN
                  SET @TMPSesscnt=1
                  SET @TMPStartDate=@SDate
              END
            ELSE IF( @TMPBehavior <> @BehaviorOld )
              BEGIN
                  SET @TMPSesscnt=1
                  SET @TMPStartDate=@SDate
              END

            SET @BehaviorOld=@TMPBehavior

            IF( @TMPDate = @TMPStartDate )
              BEGIN
                  INSERT INTO #temp
                              (measurementid,
                               aggredateddate,
                               xvalue,
                               frequency,
                               duration,
                               rate,
                               ioafrequency,
                               ioaduration,
                               arrownote)
                  SELECT measurementid,
                         aggdate,
                         @TMPSesscnt,
                         frequency,
                         duration,
                         rate,
                         ioafrequency,
                         ioaduration,
                         arrownote
                  FROM   @AGGSCORE
                  WHERE  id = @TMPLoopCount

                  SET @TMPSesscnt=@TMPSesscnt + 1
              END
            ELSE
              BEGIN
                  WHILE( @TMPDate <> @TMPStartDate )
                    BEGIN
                        IF( @TMPDate > @TMPStartDate )
                          BEGIN
                              INSERT INTO #temp
                                          (measurementid,
                                           aggredateddate,
                                           xvalue)
                              VALUES      (@TMPBehavior,
                                           @TMPStartDate,
                                           @TMPSesscnt)

                              SET @TMPStartDate=Dateadd(day, 1, @TMPStartDate)
                          END
                        ELSE
                          BEGIN
                              INSERT INTO #temp
                                          (measurementid,
                                           aggredateddate,
                                           xvalue)
                              VALUES      (@TMPBehavior,
                                           @TMPDate,
                                           @TMPSesscnt)

                              SET @TMPDate=Dateadd(day, 1, @TMPDate)
                          END

                        SET @TMPSesscnt=@TMPSesscnt + 1
                    END

                  IF( @TMPDate = @TMPStartDate )
                    BEGIN
                        INSERT INTO #temp
                                    (measurementid,
                                     aggredateddate,
                                     xvalue,
                                     frequency,
                                     duration,
                                     rate,
                                     ioafrequency,
                                     ioaduration,
                                     arrownote)
                        SELECT measurementid,
                               aggdate,
                               @TMPSesscnt,
                               frequency,
                               duration,
                               rate,
                               ioafrequency,
                               ioaduration,
                               arrownote
                        FROM   @AGGSCORE
                        WHERE  id = @TMPLoopCount

                        SET @TMPSesscnt=@TMPSesscnt + 1
                    END
              END

            SET @TMPLoopCount=@TMPLoopCount + 1
            SET @TMPCount=@TMPCount - 1
            SET @TMPStartDate=Dateadd(day, 1, @TMPStartDate)

            IF( @TMPCount = 0 )
              BEGIN
                  WHILE( @TMPDate <= @EDate )
                    BEGIN
                        SET @TMPDate=Dateadd(day, 1, @TMPDate)

                        INSERT INTO #temp
                                    (measurementid,
                                     aggredateddate,
                                     xvalue)
                        VALUES      ( @TMPBehavior,
                                      @TMPDate,
                                      @TMPSesscnt)

                        SET @TMPSesscnt=@TMPSesscnt + 1
                    END
              END
        END

      --UPDATE #TEMP SET Frequency=0 WHERE Frequency IS NULL AND CONVERT(DATE,AggredatedDate) IN (SELECT CONVERT(DATE,EvntTs) FROM 
      --StdtSessEvent WHERE EventType='CH' AND StudentId=@SID)
      --UPDATE #TEMP SET Duration=0 WHERE Duration IS NULL AND MeasurementId IN (SELECT MeasurementId FROM BehaviourDetails WHERE Duration='true'
      --AND MeasurementId IN (SELECT DISTINCT MeasurementId FROM #TEMP)) AND CONVERT(DATE,AggredatedDate) IN (SELECT CONVERT(DATE,EvntTs) FROM 
      --StdtSessEvent WHERE EventType='CH' AND StudentId=@SID)
      CREATE TABLE #tmp
        (
           id             INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           measurementid  INT,
           aggredateddate DATE,
           type           VARCHAR(10)
        )

		CREATE NONCLUSTERED INDEX idx_tmp_measurementid ON #tmp(measurementid);
		CREATE NONCLUSTERED INDEX idx_tmp_aggredateddate ON #tmp(aggredateddate);
		CREATE NONCLUSTERED INDEX idx_tmp_type ON #tmp(type);

      INSERT INTO #tmp
                  (measurementid,
                   aggredateddate,
                   type)
      SELECT 0                     MeasurementId,
             CONVERT(DATE, evntts) AggredatedDate,
             stdtsesseventtype
      FROM   [dbo].[stdtsessevent]
      WHERE  studentid = @SID
             AND [stdtsessevent].[measurementid] IN ( 0 )
             AND eventtype = 'EV'
             AND evntts BETWEEN @SDate AND @EDate
             AND stdtsesseventtype <> 'Arrow notes'
			 AND discardstatus is NULL

      INSERT INTO #tmp
                  (measurementid,
                   aggredateddate,
                   type)
      SELECT [stdtsessevent].[measurementid],
             CONVERT(DATE, evntts) AggredatedDate,
             stdtsesseventtype
      FROM   [dbo].[stdtsessevent]
      WHERE  studentid = @SID
             AND [stdtsessevent].[measurementid] IN (SELECT *
                                                     FROM   @splt)
             AND eventtype = 'EV'
             AND evntts BETWEEN @SDate AND @EDate
             AND stdtsesseventtype <> 'Arrow notes'
			 AND discardstatus is NULL

      CREATE TABLE #evnt
        (
           id   INT PRIMARY KEY IDENTITY(1, 1),
           lpid INT
        )

      INSERT INTO #evnt
      SELECT *
      FROM   @splt

      SET @CNTBEHAV=(SELECT Count(*)
                     FROM   #evnt)

      WHILE( @CNTBEHAV > 0 )
        BEGIN
            CREATE TABLE #lparrow
              (
                 id                 INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
                 lessonid           INT,
                 aggredateddate     DATETIME,
                 ioafreqperc        VARCHAR(50),
                 ioadurperc         VARCHAR(50),
                 behavname          VARCHAR(200),
                 arrownote          VARCHAR(500),
                 eventtype          VARCHAR(50),
                 eventname          NVARCHAR(max),
                 timestampforreport DATETIME,
                 endtime            DATETIME,
                 comment            VARCHAR(200)
              );

            INSERT INTO #lparrow
            SELECT (SELECT lpid
                    FROM   #evnt
                    WHERE  id = @CNTBEHAV)                            AS BehavId
                   ,
				   CONVERT(DATE,EvntTs) AggredatedDate,
                   NULL                                               IOAFreq,
                   NULL                                               IOADur,
                   (SELECT [behaviour]
                    FROM   [dbo].[behaviourdetails]
                    WHERE  [measurementid] = (SELECT lpid
                                              FROM   #evnt
                                              WHERE  id = @CNTBEHAV)) BehavName,
                   eventname                                          AS
                   ArrowNote
                   ,
                   stdtsesseventtype
                   AS EventType,
                   eventname,
                   timestampforreport,
                   [stdtsessevent].endtime,
                   comment
            FROM   [dbo].[stdtsessevent]
                   INNER JOIN studentpersonal student
                           ON student.StudentPersonalId = [stdtsessevent].studentid
                   LEFT JOIN [dbo].[behaviourdetails]
                          ON [dbo].[behaviourdetails].[measurementid] =
                             [stdtsessevent].[measurementid]
            WHERE  student.StudentPersonalId = @SID
                   AND [stdtsessevent].[measurementid] IN ( 0 )
                   AND eventtype = 'EV'
                   AND evntts BETWEEN @SDate AND @EDate
                   AND stdtsesseventtype = 'Arrow notes'
                   AND @Evnt LIKE '%' + 'Arrow' + '%'
				   AND discardstatus is NULL

            INSERT INTO #lparrow
            SELECT [stdtsessevent].[measurementid],
				   CONVERT(DATE,EvntTs) AggredatedDate,
                   NULL                                               IOAFreq,
                   NULL                                               IOADur,
                   (SELECT [behaviour]
                    FROM   [dbo].[behaviourdetails]
                    WHERE  [measurementid] = (SELECT lpid
                                              FROM   #evnt
                                              WHERE  id = @CNTBEHAV)) BehavName,
                   eventname                                          AS
                   ArrowNote
                   ,
                   stdtsesseventtype
                   AS EventType,
                   eventname,
                   timestampforreport,
                   [stdtsessevent].endtime,
                   comment
            FROM   [dbo].[stdtsessevent]
                   INNER JOIN StudentPersonal  student
                           ON student.StudentPersonalId = [stdtsessevent].studentid
                   LEFT JOIN [dbo].[behaviourdetails]
                          ON [dbo].[behaviourdetails].[measurementid] =
                             [stdtsessevent].[measurementid]
            WHERE  student.StudentPersonalId = @SID
                   AND [stdtsessevent].[measurementid] IN
                       (SELECT lpid
                        FROM   #evnt
                        WHERE  id = @CNTBEHAV)
                   AND eventtype = 'EV'
                   AND evntts BETWEEN @SDate AND @EDate
                   AND stdtsesseventtype = 'Arrow notes'
                   AND @Evnt LIKE '%' + 'Arrow' + '%'
				   AND discardstatus is NULL

            SET @ARROWCNT =(SELECT Count(*)
                            FROM   #lparrow)
            SET @ARROWID=1

            WHILE( @ARROWCNT > 0 )
              BEGIN
                  SET @CNTBEHAVLP=(SELECT Count(*)
                                   FROM   #temp
                                   WHERE  [measurementid] =
                                          (SELECT lessonid
                                           FROM   #lparrow
                                           WHERE  id = @ARROWID)
                                          AND CONVERT(DATE, aggredateddate) =
                                              (SELECT
                                              CONVERT(DATE, aggredateddate)
                                              FROM
                                              #lparrow
                                              WHERE
                                              id
                                              =
                                              @ARROWID
                                              ))

                  --IF(@CNTBEHAVLP>0)
                  --BEGIN  
                  UPDATE #temp
                  SET    arrownote = (SELECT Stuff((SELECT ',' + CONVERT(VARCHAR
                                                           (
                                                           500),
                                                           eventname)
                                                    FROM   (SELECT eventname
                                                            FROM   #lparrow
                                                            WHERE
                                                   lessonid = (SELECT
                                                   lessonid
                                                               FROM
                                                   #lparrow
                                                               WHERE
                                                   id
                                                              =
                                                              @ARROWID
                                                   )
                                                   AND CONVERT(DATE,
                                                       aggredateddate)
                                                       =
                                                       (SELECT
                                                       CONVERT(DATE,
                                                       aggredateddate)
                                                       FROM
                                                       #lparrow
                                                       WHERE  id =
                                                       @ARROWID
                                                       )
                                                           )
                                                           EName
                                                    FOR xml path('')), 1, 1, '')
                                     )
                  --+'---------->'
                  WHERE  [measurementid] = (SELECT lessonid
                                            FROM   #lparrow
                                            WHERE  id = @ARROWID)
                         AND CONVERT(DATE, aggredateddate) =
                             (SELECT
                             CONVERT(DATE, aggredateddate)
                                                              FROM   #lparrow
                                                              WHERE  id =
                             @ARROWID)

                  --END
                  --ELSE

				  DECLARE @scorestatus1 INT = (SELECT TOP 1 frequency FROM #temp WHERE [measurementid] = (SELECT lessonid FROM #lparrow WHERE id = @ARROWID) AND CONVERT(DATE, aggredateddate) = (SELECT CONVERT(DATE, aggredateddate) FROM #lparrow WHERE id = @ARROWID) AND eventname IS NULL)
				  DECLARE @scorestatus2 INT = (SELECT TOP 1 duration FROM #temp WHERE [measurementid] = (SELECT lessonid FROM #lparrow WHERE id = @ARROWID) AND CONVERT(DATE, aggredateddate) = (SELECT CONVERT(DATE, aggredateddate) FROM #lparrow WHERE id = @ARROWID) AND eventname IS NULL)


                  IF( @scorestatus1 IS NULL
                      AND @scorestatus2 IS NULL )
                    BEGIN
                        INSERT INTO #temp
                                    (measurementid,
                                     frequency,
                                     aggredateddate,
                                     ioafrequency,
                                     ioaduration,
                                     behaviour,
                                     arrownote,
                                     eventtype,
                                     eventname,
                                     evntts,
                                     endtime,
                                     comment)
                        SELECT lessonid,
                               0    Frequency,
                               aggredateddate,
                               NULL IOAFrequency,
                               NULL IOADuration,
                               behavname,
                               arrownote --+'---------->' AS ArrowNote
                               ,
                               eventtype,
                               eventname,
                               timestampforreport,
                               endtime,
                               comment
                        FROM   #lparrow
                        WHERE  id = @ARROWID
                    END

                  SET @ARROWCNT=@ARROWCNT - 1
                  SET @ARROWID=@ARROWID + 1
              END

            DROP TABLE #lparrow

			DECLARE @MajorMinor TABLE (MajorMinor varchar(15))
			IF(@Evnt LIKE '%' + 'Major' + '%')
		INSERT INTO @MajorMinor (MajorMinor) VALUES ('Major')
		IF(@Evnt LIKE '%' + 'Minor' + '%')
		INSERT INTO @MajorMinor (MajorMinor) VALUES ('Minor')

            IF( (SELECT Count(*)
                 FROM   #temp
                 WHERE  measurementid = (SELECT lpid
                                         FROM   #evnt
                                         WHERE  id = @CNTBEHAV)) > 0 )
              BEGIN
                  INSERT INTO #temp
                              (measurementid,
                               aggredateddate,
                               ioafrequency,
                               ioaduration,
                               behaviour,
                               arrownote,
                               eventtype,
                               eventname,
                               evntts,
                               endtime,
                               comment,
                               classtype)
                  SELECT (SELECT lpid
                          FROM   #evnt
                          WHERE  id = @CNTBEHAV)
                         MeasurementId,
                         Dateadd(hour, 0, CONVERT(DATETIME,
                                            CONVERT(DATE, evntts
                                            )))
                         AS
                         AggredatedDate
                         --,DATEADD(HOUR,1, CONVERT(DATE,EvntTs)) AS AggredatedDate
                         ,
                         NULL
                         IOAFrequency
                         ,
                         NULL
                         IOADuration,
                         (SELECT [behaviour]
                          FROM   [dbo].[behaviourdetails]
                          WHERE  [measurementid] = (SELECT lpid
                                                    FROM   #evnt
                                                    WHERE  id = @CNTBEHAV))
                         BehavName,
                         NULL
                         AS
                         ArrowNote
                         ,
                         stdtsesseventtype
                         AS
                         EventType,
                         (SELECT Format(CONVERT(DATE, evntts), 'MM/dd') + ','
                                 + Stuff((SELECT ', '+ eventname FROM (SELECT
                                 eventname
                                 FROM
                                 [dbo].[stdtsessevent] EVNT WHERE
                                 EVNT.studentid=@SID
                                 AND
                                 eventtype='EV'
                                 AND
                                 CONVERT(DATE, EVNT.evntts)
                                 =CONVERT(DATE, VNT.evntts)
                                 AND EVNT.StdtSessEventType=VNT.StdtSessEventType
								 AND stdtsesseventtype in(SELECT MajorMinor FROM @MajorMinor)
								 AND discardstatus is NULL
                                 AND stdtsesseventtype<>'Arrow notes' AND
                                 (EVNT.measurementid=(SELECT
                                 lpid FROM
                                 #evnt WHERE id=@CNTBEHAV) OR
                                 EVNT.measurementid=0))
                                 LP
                                 FOR
                                 xml
                                 path(''))
                                 , 1, 1,
                                 ''))
                         EventName,
                         CONVERT(DATE, evntts)
                         EvntTs
                         ,
                         NULL
                         AS
                         EndTime,
                         NULL
                         AS
                         Comment,
                         (SELECT CASE
                                   WHEN residenceind = 1 THEN 'Residence'
                                   ELSE 'Day'
                                 END AS ClassType
                          FROM   class
                          WHERE  classid = VNT.classid)
                         ClassType
                  FROM   [dbo].[stdtsessevent] VNT
                  WHERE  VNT.studentid = @SID
                         AND ( VNT.measurementid = (SELECT lpid
                                                    FROM   #evnt
                                                    WHERE  id = @CNTBEHAV)
                                OR VNT.measurementid = 0 )
                         AND eventtype = 'EV'
                         AND evntts BETWEEN @SDate AND @EDate
                         AND stdtsesseventtype <> 'Arrow notes'
						 AND stdtsesseventtype in(SELECT MajorMinor FROM @MajorMinor)
						 AND discardstatus is NULL
                  GROUP  BY VNT.measurementid,
                            CONVERT(DATE, evntts),
                            VNT.stdtsesseventtype,
                            VNT.classid
              END

            SET @CNTBEHAV=@CNTBEHAV - 1
        END

      DROP TABLE #evnt

      --TO SEPERATE EACH TRENDLINE FROM THE TABLE #TEMP, ADD EACH PAGE SESSION TO #TEMPTYPE 
      CREATE TABLE #temptype
        (
           id         INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           behaviorid INT
        );

      INSERT INTO #temptype
      SELECT DISTINCT measurementid
      FROM   #temp

      SET @Cnt=1
      --FOR SEPERATING EACH TERAND LINE SECTION AND NUMBERED IT AS 1,2,3 ETC IN 'BreakTrendFrequency' COLUMN OF #TEMP TABLE
      SET @LCount=(SELECT Count(*)
                   FROM   #temptype)

      WHILE( @LCount > 0 )
        BEGIN
            SET @LoopBehavior=(SELECT behaviorid
                               FROM   #temptype
                               WHERE  id = @Cnt)
            SET @Scoreid=(SELECT TOP 1 scoreid
                          FROM   #temp
                          WHERE  measurementid = @LoopBehavior)

            WHILE( (SELECT Count(*)
                    FROM   #temp
                    WHERE  measurementid = @LoopBehavior
                           AND scoreid = @Scoreid) > 0 )
              BEGIN
                  SET @Frequency=(SELECT Isnull(CONVERT(INT, frequency), -1)
                                  FROM   #temp
                                  WHERE  scoreid = @Scoreid)
                  SET @Duration=(SELECT Isnull(CONVERT(FLOAT, duration), -1)
                                 FROM   #temp
                                 WHERE  scoreid = @Scoreid)

                  IF( (SELECT Count(*)
                       FROM   #temp
                       WHERE  measurementid = @LoopBehavior
                              AND aggredateddate = Dateadd(hour, -12, (SELECT
                                                   aggredateddate
                                                                       FROM
                                                   #temp
                                                                       WHERE
                                                   scoreid = @Scoreid))
                      )
                        > 0 )
                    BEGIN
                        IF( @Frequency = -1 )
                          BEGIN
                              SET @Breaktrendfrequencyid=(SELECT
                              Isnull(Max(breaktrendfrequency), 0)
                                                          FROM   #temp)
                                                         + 1
                          END
                        ELSE
                          BEGIN
                              SET @Breaktrendfrequencyid=(SELECT
                              Isnull(Max(breaktrendfrequency), 0)
                                                          FROM   #temp)
                                                         + 1

                              UPDATE #temp
                              SET    breaktrendfrequency =
                                     @Breaktrendfrequencyid
                              WHERE  scoreid = @Scoreid

                              SET @NullcntFrequency=0
                          END
                    END

                  IF( (SELECT Count(*)
                       FROM   #temp
                       WHERE  measurementid = @LoopBehavior
                              AND aggredateddate = Dateadd(hour, -12, (SELECT
                                                   aggredateddate
                                                                       FROM
                                                   #temp
                                                                       WHERE
                                                   scoreid = @Scoreid))
                      )
                        > 0 )
                    BEGIN
                        IF( @Duration = -1 )
                          BEGIN
                              SET @Breaktrenddurationid=(SELECT
                              Isnull(Max(breaktrendduration), 0)
                                                         FROM   #temp)
                                                        + 1
                          END
                        ELSE
                          BEGIN
                              SET @Breaktrenddurationid=(SELECT
                              Isnull(Max(breaktrendduration), 0)
                                                         FROM   #temp)
                                                        + 1

                              UPDATE #temp
                              SET    breaktrendduration = @Breaktrenddurationid
                              WHERE  scoreid = @Scoreid

                              SET @NullcntDuration=0
                          END
                    END

                  IF( @Frequency = -1 )
                    BEGIN
                        SET @NullcntFrequency=@NullcntFrequency + 1
                    END
                  ELSE IF( @NullcntFrequency > 5
                      AND @Frequency <>- 1 )
                    BEGIN
                        SET @Breaktrendfrequencyid=(SELECT
                        Isnull(Max(breaktrendfrequency), 0)
                                                    FROM   #temp)
                                                   + 1

                        UPDATE #temp
                        SET    breaktrendfrequency = @Breaktrendfrequencyid
                        WHERE  scoreid = @Scoreid

                        SET @NullcntFrequency=0
                    END
                  ELSE IF( @Frequency <>- 1 )
                    BEGIN
                        IF( (SELECT Isnull(Max(breaktrendfrequency), 0)
                             FROM   #temp) <> 0 )
                          BEGIN
                              IF( (SELECT measurementid
                                   FROM   #temp
                                   WHERE  scoreid = @Scoreid) <>
                                  (SELECT TOP 1 measurementid
                                   FROM   #temp
                                   WHERE
                                  breaktrendfrequency = (SELECT
                                  Isnull(Max(breaktrendfrequency), 0)
                                                         FROM   #temp))
                                )
                                BEGIN
                                    SET @Breaktrendfrequencyid=
                                    @Breaktrendfrequencyid + 1
                                END
                          END

                        UPDATE #temp
                        SET    breaktrendfrequency = @Breaktrendfrequencyid
                        WHERE  scoreid = @Scoreid

                        SET @NullcntFrequency=0
                    END

                  IF( @Duration = -1 )
                    BEGIN
                        SET @NullcntDuration=@NullcntDuration + 1
                    END
                  ELSE IF( @NullcntDuration > 5
                      AND @Duration <>- 1 )
                    BEGIN
                        SET @Breaktrenddurationid=(SELECT
                        Isnull(Max(breaktrendduration), 0)
                                                   FROM   #temp)
                                                  + 1

                        UPDATE #temp
                        SET    breaktrendduration = @Breaktrenddurationid
                        WHERE  scoreid = @Scoreid

                        SET @NullcntDuration=0
                    END
                  ELSE IF( @Duration <>- 1 )
                    BEGIN
                        IF( (SELECT Isnull(Max(breaktrendduration), 0)
                             FROM   #temp) <> 0 )
                          BEGIN
                              IF( (SELECT measurementid
                                   FROM   #temp
                                   WHERE  scoreid = @Scoreid) <>
                                  (SELECT TOP 1 measurementid
                                   FROM   #temp
                                   WHERE
                                  breaktrendduration = (SELECT
                                  Isnull(Max(breaktrendduration), 0)
                                                        FROM   #temp))
                                )
                                BEGIN
                                    SET @Breaktrenddurationid=
                                    @Breaktrenddurationid + 1
                                END
                          END

                        UPDATE #temp
                        SET    breaktrendduration = @Breaktrenddurationid
                        WHERE  scoreid = @Scoreid

                        SET @NullcntDuration=0
                    END

                  -------------------------------------------------------------------------------------
                  --IF CHARINDEX('Major',@Event) > 0
                  --BEGIN
                  ----   select @Scoreid as scoreid
                  ----SELECT CONVERT(DATE,AggredatedDate) aggdate FROM #TEMP WHERE Scoreid=@Scoreid
                  ----SELECT COUNT(*) FROM #TMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #TEMP WHERE Scoreid=@Scoreid) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type='Major'
                  ----SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)=CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Major'
                  ----SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)= CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Major'
                  --IF((SELECT COUNT(*) FROM #TMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #TEMP WHERE Scoreid=@Scoreid) 
                  --AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Major')>0)
                  --BEGIN
                  --IF((SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)=CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  --AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Major')>0)
                  --BEGIN
                  --UPDATE #TEMP SET BreakTrendFrequency = NULL  WHERE Scoreid=@Scoreid
                  --SET @NullcntDuration=0
                  --UPDATE #TEMP SET BreakTrendDuration=NULL WHERE Scoreid=@Scoreid
                  --SET @NullcntDuration=0
                  --END
                  --END  
                  ----ELSE IF((SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)= CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Major')>0)
                  ----BEGIN
                  ----SET @Breaktrendfrequencyid=(SELECT ISNULL(MAX(BreakTrendFrequency),0) FROM #TEMP)+1
                  ----UPDATE #TEMP SET BreakTrendFrequency=@Breaktrendfrequencyid WHERE Scoreid=@Scoreid
                  ----SET @NullcntFrequency=0  
                  ----SET @Breaktrenddurationid=(SELECT ISNULL(MAX(BreakTrendDuration),0) FROM #TEMP)+1
                  ----UPDATE #TEMP SET BreakTrendDuration=@Breaktrenddurationid WHERE Scoreid=@Scoreid
                  ----SET @NullcntDuration=0
                  ----END
                  --END
                  --IF CHARINDEX('Minor',@Event) > 0
                  --BEGIN
                  ----select @Scoreid as scoreid
                  ----SELECT CONVERT(DATE,AggredatedDate) aggdate FROM #TEMP WHERE Scoreid=@Scoreid
                  ----SELECT COUNT(*) FROM #TMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #TEMP WHERE Scoreid=@Scoreid) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Minor'
                  ----SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)=CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Minor'
                  ----SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)= CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Minor'
                  --IF((SELECT COUNT(*) FROM #TMP WHERE CONVERT(DATE,AggredatedDate)=(SELECT CONVERT(DATE,AggredatedDate) FROM #TEMP WHERE Scoreid=@Scoreid) 
                  --AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Minor')>0)
                  --BEGIN
                  --IF((SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)=CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  --AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Minor')>0)
                  --BEGIN
                  --UPDATE #TEMP SET BreakTrendFrequency=NULL WHERE Scoreid=@Scoreid
                  --SET @NullcntDuration=0
                  --UPDATE #TEMP SET BreakTrendDuration=NULL WHERE Scoreid=@Scoreid
                  --SET @NullcntDuration=0
                  --END
                  --END  
                  ----ELSE IF((SELECT COUNT(*) FROM #TMP WHERE  CONVERT(DATE,AggredatedDate)= CONVERT(DATE,(SELECT AggredatedDate FROM #TEMP WHERE Scoreid=(@Scoreid-1))) 
                  ----AND (MeasurementId=(SELECT MeasurementId FROM #TEMP WHERE Scoreid=@Scoreid) OR MeasurementId=0) AND Type ='Minor')>0)
                  ----BEGIN
                  ----SET @Breaktrendfrequencyid=(SELECT ISNULL(MAX(BreakTrendFrequency),0) FROM #TEMP)+1
                  ----UPDATE #TEMP SET BreakTrendFrequency=@Breaktrendfrequencyid WHERE Scoreid=@Scoreid
                  ----SET @NullcntFrequency=0  
                  ----SET @Breaktrenddurationid=(SELECT ISNULL(MAX(BreakTrendDuration),0) FROM #TEMP)+1
                  ----UPDATE #TEMP SET BreakTrendDuration=@Breaktrenddurationid WHERE Scoreid=@Scoreid
                  ----SET @NullcntDuration=0
                  ----END
                  --END
                  -------------------------------------------------------------------------------------
                  SET @Scoreid=@Scoreid + 1
              END

            SET @Cnt=@Cnt + 1
            SET @LCount=@LCount - 1
        END

      DROP TABLE #temptype

      DROP TABLE #tmp

      --SELECT EACH TREND LINE SECTION FROM #TEMP AND CALCULATE TREND POINT VALUES
      SET @Cnt=0

      IF( @TType = 'Quarter' )
        BEGIN
            SET @NumOfTrend=(SELECT Count(DISTINCT breaktrendfrequency)
                             FROM   #temp)

            WHILE( @NumOfTrend > 0 )
              BEGIN
                  SET @Cnt=@Cnt + 1
                  SET @TrendsectionNo=(SELECT Count(*)
                                       FROM   #temp
                                       WHERE  breaktrendfrequency = @Cnt)

                  IF( @TrendsectionNo > 2 )
                    BEGIN
                        CREATE TABLE #trendsection
                          (
                             id        INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
                             trenddate DATETIME,
                             frequency FLOAT,
                             scoreid   INT
                          );

                        INSERT INTO #trendsection
                        SELECT aggredateddate,
                               CONVERT(FLOAT, frequency),
                               scoreid
                        FROM   #temp
                        WHERE  scoreid BETWEEN (SELECT TOP 1 scoreid
                                                FROM   #temp
                                                WHERE
                               breaktrendfrequency = @Cnt
                                                ORDER  BY scoreid) AND
                                               (SELECT TOP 1 scoreid
                                                FROM   #temp
                                                WHERE
                                               breaktrendfrequency = @Cnt
                                                                        ORDER
                                               BY
                                               scoreid
                                               DESC
                                               )

                        IF( (SELECT Count(*)
                             FROM   #trendsection)%2 = 0 )
                          SET @DateCnt=( (SELECT Count(*)
                                          FROM   #trendsection) / 2 ) + 1
                        ELSE
                          SET @DateCnt=( (SELECT Count(*)
                                          FROM   #trendsection) / 2 ) + 2

                        SET @Midrate1= (SELECT ( (SELECT TOP 1 frequency
                                                  FROM   (SELECT TOP 50 PERCENT
                                                         frequency
                                                          FROM   #trendsection
                                                          WHERE
                                                 id BETWEEN 1 AND (
                                                 SELECT
                                                            Count(*) / 2
                                                                   FROM
                                                            #trendsection)
                                                 AND frequency IS NOT NULL
                                                          ORDER  BY frequency)
                                                         AS
                                                         A
                                                  ORDER  BY frequency DESC)
                                                 + (SELECT TOP 1 frequency
                                                    FROM   (SELECT TOP 50
                                                           PERCENT
                                                           frequency
                                                            FROM   #trendsection
                                                            WHERE
                                                   id BETWEEN 1 AND
                                                   (SELECT Count(*)
                                                   / 2
                                                    FROM
                                                              #trendsection)
                                                   AND frequency IS NOT NULL
                                                            ORDER  BY
                                                           frequency DESC)
                                                           AS
                                                           A
                                                    ORDER  BY frequency ASC) ) /
                                               2
                                       )
                        SET @Midrate2= (SELECT ( (SELECT TOP 1 frequency
                                                  FROM   (SELECT TOP 50 PERCENT
                                                         frequency
                                                          FROM   #trendsection
                                                          WHERE
                                                 id BETWEEN @DateCnt AND
                                                            (
                                                            SELECT
                                                            Count(*
                                                            )
                                                            FROM
                                                            #trendsection)
                                                 AND frequency IS NOT NULL
                                                          ORDER  BY frequency)
                                                         AS
                                                         A
                                                  ORDER  BY frequency DESC)
                                                 + (SELECT TOP 1 frequency
                                                    FROM   (SELECT TOP 50
                                                           PERCENT
                                                           frequency
                                                            FROM   #trendsection
                                                            WHERE
                                                   id BETWEEN @DateCnt
                                                   AND (
                                                              SELECT
                                                              Count
                                                              (
                                                              *)
                                                              FROM
                                                              #trendsection)
                                                   AND frequency IS NOT NULL
                                                            ORDER  BY
                                                           frequency DESC)
                                                           AS
                                                           A
                                                    ORDER  BY frequency ASC) ) /
                                               2
                                       )

                        IF( @TrendsectionNo > 2 )
                          BEGIN
                              --Applying Line Equation Y=mx+b To find Slope 'm' AND Constant 'b'
                              SET @Slope=( @Midrate2 - @Midrate1 ) / (
                                                    (SELECT TOP 1 xvalue
                                                                        FROM
                                                    #temp
                                                                        WHERE
                                                    breaktrendfrequency = @Cnt
                                                                        ORDER
                                                    BY
                                                    scoreid
                                                    DESC
                                                    ) -
                                                    (SELECT TOP 1 xvalue
                                                     FROM   #temp
                                                     WHERE
                                                    breaktrendfrequency = @Cnt
                                                    ORDER
                                                    BY
                                                    scoreid) )
                              --b=y-mx
                              SET @Const=@Midrate1 - ( @Slope * (SELECT TOP 1
                                                                xvalue
                                                                 FROM   #temp
                                                                 WHERE
                                                       breaktrendfrequency
                                                       =
                                                       @Cnt
                                                                 ORDER  BY
                                                                scoreid
                                                                ) )
                              SET @Ids=(SELECT TOP 1 xvalue
                                        FROM   #temp
                                        WHERE  breaktrendfrequency = @Cnt
                                        ORDER  BY scoreid) --FIRST x value
                              SET @IdOfTrend=(SELECT TOP 1 scoreid
                                              FROM   #trendsection
                                              ORDER  BY id)

                              WHILE( @IdOfTrend <= (SELECT Max(scoreid)
                                                    FROM   #trendsection) )
                                BEGIN
                                    UPDATE #temp
                                    SET    trendfrequency = (
                                           ( @Slope * @Ids ) +
                                           @Const
                                                            )
                                    WHERE  scoreid = @IdOfTrend

                                    SET @IdOfTrend=@IdOfTrend + 1
                                    SET @Ids=@Ids + 1
                                END
                          END

                        DROP TABLE #trendsection
                    END

                  SET @NumOfTrend=@NumOfTrend - 1
              END

            --------------------------------------------------------
            SET @Cnt=0
            SET @NumOfTrend=(SELECT Count(DISTINCT breaktrendduration)
                             FROM   #temp)

            WHILE( @NumOfTrend > 0 )
              BEGIN
                  SET @Cnt=@Cnt + 1
                  SET @TrendsectionNo=(SELECT Count(*)
                                       FROM   #temp
                                       WHERE  breaktrendduration = @Cnt)

                  IF( @TrendsectionNo > 2 )
                    BEGIN
                        DECLARE @TRENDS TABLE
                          (
                             id        INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
                             trenddate DATETIME,
                             duration  FLOAT,
                             scoreid   INT
                          );

                        INSERT INTO @TRENDS
                        SELECT aggredateddate,
                               CONVERT(FLOAT, duration),
                               scoreid
                        FROM   #temp
                        WHERE  scoreid BETWEEN (SELECT TOP 1 scoreid
                                                FROM   #temp
                                                WHERE  breaktrendduration = @Cnt
                                                ORDER  BY scoreid) AND
                                               (SELECT TOP 1 scoreid
                                                FROM   #temp
                                                WHERE
                                               breaktrendduration = @Cnt
                                                                        ORDER
                                               BY
                                               scoreid
                                               DESC
                                               )

                        IF( (SELECT Count(*)
                             FROM   @TRENDS)%2 = 0 )
                          SET @DateCnt=( (SELECT Count(*)
                                          FROM   @TRENDS) / 2 ) + 1
                        ELSE
                          SET @DateCnt=( (SELECT Count(*)
                                          FROM   @TRENDS) / 2 ) + 2

                        SET @Midrate1= (SELECT ( (SELECT TOP 1 duration
                                                  FROM   (SELECT TOP 50 PERCENT
                                                         duration
                                                          FROM   @TRENDS
                                                          WHERE
                                                 id BETWEEN 1 AND
                                                 (
                                                 SELECT
                                                            Count(
                                                 *) /
                                                            2
                                                 FROM
                                                            @TRENDS)
                                                 AND duration IS NOT
                                                     NULL
                                                          ORDER  BY duration) AS
                                                         A
                                                  ORDER  BY duration DESC)
                                                 + (SELECT TOP 1 duration
                                                    FROM   (SELECT TOP 50
                                                           PERCENT
                                                           duration
                                                            FROM   @TRENDS
                                                            WHERE
                                                   id BETWEEN 1 AND
                                                   (SELECT Count(*)
                                                   / 2
                                                    FROM   @TRENDS)
                                                   AND duration IS NOT
                                                       NULL
                                                            ORDER  BY duration
                                                           DESC)
                                                           AS
                                                           A
                                                    ORDER  BY duration ASC) ) /
                                               2)
                        SET @Midrate2= (SELECT ( (SELECT TOP 1 duration
                                                  FROM   (SELECT TOP 50 PERCENT
                                                         duration
                                                          FROM   @TRENDS
                                                          WHERE
                                                 id BETWEEN @DateCnt
                                                 AND
                                                            (
                                                            SELECT
                                                            Count(*
                                                            )
                                                            FROM
                                                            @TRENDS
                                                            )
                                                 AND duration IS NOT
                                                     NULL
                                                          ORDER  BY duration) AS
                                                         A
                                                  ORDER  BY duration DESC)
                                                 + (SELECT TOP 1 duration
                                                    FROM   (SELECT TOP 50
                                                           PERCENT
                                                           duration
                                                            FROM   @TRENDS
                                                            WHERE
                                                   id BETWEEN @DateCnt
                                                   AND (
                                                              SELECT
                                                              Count
                                                              (
                                                              *)
                                                              FROM
                                                              @TRENDS)
                                                   AND duration IS NOT
                                                       NULL
                                                            ORDER  BY duration
                                                           DESC)
                                                           AS
                                                           A
                                                    ORDER  BY duration ASC) ) /
                                               2)

                        IF( @TrendsectionNo > 2 )
                          BEGIN
                              --Applying Line Equation Y=mx+b To find Slope 'm' AND Constant 'b'
                              SET @Slope=( @Midrate2 - @Midrate1 ) / (
                                                    (SELECT TOP 1 xvalue
                                                                        FROM
                                                    #temp
                                                                        WHERE
                                                    breaktrendduration = @Cnt
                                                                        ORDER
                                                    BY
                                                    scoreid
                                                    DESC
                                                    ) -
                                                    (SELECT TOP 1 xvalue
                                                     FROM   #temp
                                                     WHERE
                                                    breaktrendduration = @Cnt
                                                    ORDER
                                                    BY
                                                    scoreid) )
                              --b=y-mx
                              SET @Const=@Midrate1 - ( @Slope * (SELECT TOP 1
                                                                xvalue
                                                                 FROM   #temp
                                                                 WHERE
                                                       breaktrendduration =
                                                       @Cnt
                                                                 ORDER  BY
                                                                scoreid
                                                                ) )
                              SET @Ids=(SELECT TOP 1 xvalue
                                        FROM   #temp
                                        WHERE  breaktrendduration = @Cnt
                                        ORDER  BY scoreid) --FIRST x value
                              SET @IdOfTrend=(SELECT TOP 1 scoreid
                                              FROM   @TRENDS
                                              ORDER  BY id)

                              WHILE( @IdOfTrend <= (SELECT Max(scoreid)
                                                    FROM   @TRENDS) )
                                BEGIN
                                    UPDATE #temp
                                    SET    trendduration = ( ( @Slope * @Ids ) +
                                                             @Const
                                                           )
                                    WHERE  scoreid = @IdOfTrend

                                    SET @IdOfTrend=@IdOfTrend + 1
                                    SET @Ids=@Ids + 1
                                END
                          END
                    --DROP TABLE #TRENDS
                    END

                  SET @NumOfTrend=@NumOfTrend - 1
              END
        END

      SET @TMPCount = (SELECT Count(*)
                       FROM   #temp)

      WHILE( @TMPCount > 0 )
        BEGIN
            UPDATE #temp
            SET    behaviour = (SELECT behaviour
                                FROM   behaviourdetails
                                WHERE  measurementid = (SELECT measurementid
                                                        FROM   #temp
                                                        WHERE
                                       scoreid = @TMPCount
                                                       ))
            WHERE  scoreid = @TMPCount

            SET @TMPCount=@TMPCount - 1
        END

      IF( (SELECT Count(*)
           FROM   @AGGSCORE) > 0 )
        BEGIN
            UPDATE #temp
            SET    classtype = (SELECT classtype
                                FROM   @AGGSCORE
                                WHERE  id = 1)
        END

      --DROP TABLE #AGGSCORE
      ----------------------Update frq sumtotal and interval status---------------------
      --For Frequency
      UPDATE #temp
      SET    frqstat = 0
      WHERE  measurementid IN (SELECT measurementid
                               FROM   behaviourdetails
                               WHERE  frqstat = 1
                                       OR ( partialinterval = 0
                                            AND yesorno = 1 ))

      --For Sum Total
      UPDATE #temp
      SET    frqstat = 1
      WHERE  measurementid IN(SELECT measurementid
                              FROM   behaviourdetails
                              WHERE  yesorno = 1
                                     AND ( ( partialinterval = 1
                                             AND ifperinterval = 0 )
                                            OR ( partialinterval = 1
                                                 AND ifperinterval IS NULL ) ))

      --For %Interval
      UPDATE #temp
      SET    frqstat = 2
      WHERE  measurementid IN (SELECT measurementid
                               FROM   behaviourdetails
                               WHERE  partialinterval = 1
                                      AND yesorno = 1
                                      AND ifperinterval = 1)

	  --For %Opportunities
      UPDATE #temp
      SET    frqstat = 3
      WHERE  measurementid IN (SELECT measurementid
                               FROM   behaviourdetails
                               WHERE  partialinterval = 0
                                      AND yesorno = 1
                                      AND ifperinterval = 0
									  AND Opportunities=1)

      --------------------------------Update Sumtotal and %Interval values-------------------------------------
      --Update Sum Total
      CREATE TABLE #updatesum
        (
           id        INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           createdon DATE,
           measurid  INT
        )

      --INSERT INTO #UPDATESUM SELECT MeasurementId,CreatedOn FROM BehaviourDetails WHERE PartialInterval=1 AND YesOrNo=1 AND IfPerInterval=0 AND StudentId=@SID
      INSERT INTO #updatesum
      SELECT DISTINCT CONVERT(DATE, BH.createdon),
                      BH.measurementid
      FROM   behaviour BH
             INNER JOIN behaviourdetails BD
                     ON BD.measurementid = BH.measurementid
      WHERE  BD.yesorno = 1
             AND ( ( partialinterval = 1
                     AND ifperinterval = 0 )
                    OR ( partialinterval = 1
                         AND ifperinterval = NULL ) )
             AND BD.studentid = @SID
             AND BH.createdon BETWEEN @SDate AND @EDate
      ORDER  BY measurementid

      SET @COUNT= (SELECT Count(*)
                   FROM   #updatesum)
      SET @FRQ_CNT=1

      WHILE ( @COUNT >= 0 )
        BEGIN
            SET @MID=(SELECT measurid
                      FROM   #updatesum
                      WHERE  id = @FRQ_CNT)
            SET @DATE=(SELECT CONVERT(DATE, createdon)
                       FROM   #updatesum
                       WHERE  id = @FRQ_CNT)
            SET @FRQ=(SELECT Sum(frequencycount)
                      FROM   behaviour BH
                             INNER JOIN behaviourdetails BD
                                     ON BD.measurementid = BH.measurementid
									 INNER JOIN class Cls
                       								ON Cls.classid = BH.classid
                      WHERE  CONVERT(DATE, BH.createdon) = @DATE
                             AND BD.partialinterval = 1
                             AND BD.yesorno = 1
                             AND ifperinterval = 0
							 AND Cls.residenceind IN (SELECT data
				           					FROM   Split(@ClassTypeFlag, ','))
                             AND BD.measurementid = @MID)

            UPDATE #temp
            SET    frequency = @FRQ
            WHERE  measurementid = @MID
                   AND frqstat = 1
                   AND CONVERT(DATE, aggredateddate) = @DATE

            SET @COUNT=@COUNT - 1
            SET @FRQ_CNT=@FRQ_CNT + 1
        END

      DROP TABLE #updatesum

      --Update %Interval
      CREATE TABLE #updateinterval
        (
           id        INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           createdon DATE,
           measurid  INT
        )

		CREATE NONCLUSTERED INDEX idx_updateinterval_createdon ON #updateinterval(createdon);
		CREATE NONCLUSTERED INDEX idx_updateinterval_measurid ON #updateinterval(measurid);

      --INSERT INTO #UPDATEINTERVAL SELECT MeasurementId,CreatedOn FROM BehaviourDetails WHERE PartialInterval=1 AND YesOrNo=1 AND IfPerInterval=1 AND StudentId=@SID
      INSERT INTO #updateinterval
      SELECT DISTINCT CONVERT(DATE, BH.createdon),
                      BH.measurementid
      FROM   behaviour BH
             INNER JOIN behaviourdetails BD
                     ON BD.measurementid = BH.measurementid
      WHERE  partialinterval = 1
             AND BD.yesorno = 1
             AND ifperinterval = 1
             AND BD.studentid = @SID
             AND CONVERT(DATE, BH.createdon) BETWEEN @SDate AND @EDate
      ORDER  BY measurementid

      SET @COUNT= (SELECT Count(*)
                   FROM   #updateinterval)
      SET @FRQ_CNT=1

      WHILE ( @COUNT >= 0 )
        BEGIN
            SET @MID=(SELECT measurid
                      FROM   #updateinterval
                      WHERE  id = @FRQ_CNT)
            SET @DATE=(SELECT CONVERT(DATE, createdon)
                       FROM   #updateinterval
                       WHERE  id = @FRQ_CNT)
            SET @PerInterval=(SELECT TOP 1 CONVERT(FLOAT,
                                           (SELECT Sum(frequencycount)
                                            FROM   behaviour BH
                                          	INNER JOIN behaviourdetails BD
                                                   ON BD.measurementid = BH.measurementid
											INNER JOIN class Cls
                       								ON Cls.classid = BH.classid
                                           WHERE
                                           CONVERT(DATE, BH.createdon) = @DATE
                                           --AND BH.yesorno = 1
                                           AND BD.partialinterval = 1
                                           AND BD.yesorno = 1
                                           AND ifperinterval = 1
										   AND Cls.residenceind IN (SELECT data
				           					FROM   Split(@ClassTypeFlag, ','))
                                           AND BD.measurementid = @MID)) /
                                                   CONVERT(FLOAT,
                                                   (SELECT Count (*
                                                   )
                                                    FROM
                                                   behaviour
                                                                   WHERE
                                                   CONVERT(DATE, createdon) =
                                                   @DATE
                                                   AND measurementid = @MID
                                                   AND yesorno IS NOT NULL))
                                           * 100
                              FROM   behaviour
                              WHERE  CONVERT(DATE, createdon) = @DATE
                                     AND measurementid = @MID
                                     AND yesorno IS NOT NULL)
            SET @PerInterval= Round(@PerInterval, 2)

            UPDATE #temp
            SET    frequency = @PerInterval
            WHERE  measurementid = @MID
                   AND frqstat = 2
                   AND CONVERT(DATE, aggredateddate) = @DATE

            SET @COUNT=@COUNT - 1
            SET @FRQ_CNT=@FRQ_CNT + 1
        END

      DROP TABLE #updateinterval

	  --Update %Opportunities
      CREATE TABLE #updateopportunities
        (
           id        INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           createdon DATE,
           measurid  INT
        )

		CREATE NONCLUSTERED INDEX idx_updateopportunities_createdon ON #updateopportunities(createdon);
		CREATE NONCLUSTERED INDEX idx_updateopportunities_measurid ON #updateopportunities(measurid);

		INSERT INTO #updateopportunities
      SELECT DISTINCT CONVERT(DATE, BH.createdon),
                      BH.measurementid
      FROM   behaviour BH
             INNER JOIN behaviourdetails BD
                     ON BD.measurementid = BH.measurementid
      WHERE  partialinterval = 0
             AND BD.yesorno = 1
             AND ifperinterval = 0
			 AND Opportunities = 1
             AND BD.studentid = @SID
             AND CONVERT(DATE, BH.createdon) BETWEEN @SDate AND @EDate
      ORDER  BY measurementid

      SET @COUNT= (SELECT Count(*)
                   FROM   #updateopportunities)
      SET @FRQ_CNT=1

	   WHILE ( @COUNT >= 0 )
        BEGIN
		
            SET @MID=(SELECT measurid
                      FROM   #updateopportunities
                      WHERE  id = @FRQ_CNT)
            SET @DATE=(SELECT CONVERT(DATE, createdon)
                       FROM   #updateopportunities
                       WHERE  id = @FRQ_CNT)
            SET @PerOppo=(SELECT TOP 1 CONVERT(FLOAT,
                                           (SELECT Sum(frequencycount)
                                            FROM   behaviour BH
                                          	INNER JOIN behaviourdetails BD
                                                   ON BD.measurementid = BH.measurementid
											INNER JOIN class Cls
                       								ON Cls.classid = BH.classid
                                           WHERE
                                           CONVERT(DATE, BH.createdon) = @DATE
                                           --AND BH.yesorno = 1
                                           AND BD.partialinterval = 0
                                           AND BD.yesorno = 1
                                           AND ifperinterval = 0
										   AND Opportunities=1
										   AND Cls.residenceind IN (SELECT data
				           					FROM   Split(@ClassTypeFlag, ','))
                                           AND BD.measurementid = @MID)) /
                                                   CONVERT(FLOAT,
                                                   (SELECT Count (*
                                                   )
                                                    FROM
                                                   behaviour
                                                                   WHERE
                                                   CONVERT(DATE, createdon) =
                                                   @DATE
                                                   AND measurementid = @MID
                                                   AND yesorno IS NOT NULL))
                                           * 100
                              FROM   behaviour
                              WHERE  CONVERT(DATE, createdon) = @DATE
                                     AND measurementid = @MID
                                     AND yesorno IS NOT NULL)
									
								PRINT @DATE
								PRINT @ClassTypeFlag	
            SET @PerOppo= Round(@PerOppo, 2)
			
			
            UPDATE #temp
            SET    frequency = @PerOppo
            WHERE  measurementid = @MID
                   AND frqstat = 3
                   AND CONVERT(DATE, aggredateddate) = @DATE

            SET @COUNT=@COUNT - 1
            SET @FRQ_CNT=@FRQ_CNT + 1
        END
		
      DROP TABLE #updateopportunities

      --IOA % calculation for freq and duration
      DECLARE @IOAPERC TABLE
        (
           id        INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           createdon DATETIME,
           measurid  INT,
           createdby INT
        )

      INSERT INTO @IOAPERC
      SELECT DISTINCT CONVERT(DATETIME, createdon),
                      measurementid,
                      createdby
      FROM   behaviorioadetails
      WHERE  CONVERT(DATE, createdon) BETWEEN @SDate AND @EDate
             AND ioaperc IS NOT NULL
             AND measurementid IN(SELECT DISTINCT measurementid
                                  FROM   #temp)
      ORDER  BY measurementid

      SET @COUNT= (SELECT Count(*)
                   FROM   @IOAPERC)
      SET @IOACOUNT=1

      WHILE( @COUNT >= 0 )
        BEGIN
            SET @MID=(SELECT measurid
                      FROM   @IOAPERC
                      WHERE  id = @IOACOUNT)
            SET @DATE=(SELECT CONVERT(DATE, createdon)
                       FROM   @IOAPERC
                       WHERE  id = @IOACOUNT)
            SET @CREATD_BY=(SELECT createdby
                            FROM   @IOAPERC
                            WHERE  id = @IOACOUNT)
            SET @CREATD_ON=(SELECT CONVERT(DATETIME, createdon)
                            FROM   @IOAPERC
                            WHERE  id = @IOACOUNT)
            SET @Time=Dateadd(minute, -5, @CREATD_ON)
            SET @IOAfrq=(SELECT Round(Avg(CONVERT(FLOAT, ioaperc)), 0)
                         FROM   behaviorioadetails
                         WHERE  frequencycount IS NOT NULL
                                AND duration IS NULL
                                AND measurementid = @MID
                                AND CONVERT(DATE, createdon) = @DATE)
            SET @IOAdur=(SELECT Round(Avg(CONVERT(FLOAT, ioaperc)), 0)
                         FROM   behaviorioadetails
                         WHERE  duration IS NOT NULL
                                AND frequencycount IS NULL
                                AND measurementid = @MID
                                AND CONVERT(DATE, createdon) = @DATE)

            UPDATE #temp
            SET    ioapercfrq = 'IOA ' + CONVERT(VARCHAR(10), @IOAfrq) + '%',
                   ioapercdur = 'IOA ' + CONVERT(VARCHAR(10), @IOAdur) + '%'
            --, EventType='Arrow notes',
            --IOAFrequency=CONVERT(VARCHAR,@IOAfrq), IOADuration=CONVERT(VARCHAR,@IOAdur) 
            WHERE  CONVERT(DATE, aggredateddate) = @DATE
                   AND measurementid = @MID

            UPDATE #temp
            SET    ioapercfrq = ( ioapercfrq + ' '
                                  + (SELECT TOP 1 Rtrim(Ltrim(
                                                  Upper(US.userinitial)))
                                     FROM   behaviour BH
                                            INNER JOIN [user] US
                                                    ON BH.createdby = US.userid
													INNER JOIN behaviorioadetails BI
                                                    ON BI.NormalBehaviorId = BH.BehaviourId
                                     WHERE 
									  --BH.createdon BETWEEN
           --                                 @Time AND @CREATD_ON
										  BI.NormalBehaviorId = BH.BehaviourId
											AND
											 BH.StudentId = @Studentid
                                     ORDER  BY BH.createdon DESC)
                                  + '/'
                                  + (SELECT TOP 1 Rtrim(Ltrim(
                                                  Upper(US.userinitial)))
                                     FROM   behaviorioadetails BI
                                            INNER JOIN [user] US
                                                    ON BI.createdby = US.userid
                                     WHERE  BI.createdon = @CREATD_ON
									 AND BI.StudentId = @Studentid
                                     ORDER  BY BI.createdon DESC) )
            WHERE  CONVERT(DATE, aggredateddate) = @DATE
                   AND measurementid = @MID

            UPDATE #temp
            SET    ioapercdur = ( ioapercdur + ' '
                                  + (SELECT TOP 1 Rtrim(Ltrim(
                                                  Upper(US.userinitial)))
                                     FROM   behaviour BH
                                            INNER JOIN [user] US
                                                    ON BH.createdby = US.userid
													INNER JOIN behaviorioadetails BI
                                                    ON BI.NormalBehaviorId = BH.BehaviourId
                                     WHERE  
									 --BH.createdon BETWEEN
          --                                  @Time AND @CREATD_ON
						  BI.NormalBehaviorId = BH.BehaviourId
											AND BH.StudentId = @Studentid
                                     ORDER  BY BH.createdon DESC)
                                  + '/'
                                  + (SELECT TOP 1 Rtrim(Ltrim(
                                                  Upper(US.userinitial)))
                                     FROM   behaviorioadetails BI
                                            INNER JOIN [user] US
                                                    ON BI.createdby = US.userid
                                     WHERE  BI.createdon = @CREATD_ON
									 AND BI.StudentId = @Studentid
                                     ORDER  BY BI.createdon DESC) )
            WHERE  CONVERT(DATE, aggredateddate) = @DATE
                   AND measurementid = @MID

            SET @COUNT=@COUNT - 1
            SET @IOACOUNT=@IOACOUNT + 1
        END

      --DROP TABLE #IOAPERC
      -------------------------------UPDATE FREQUENCY AND DURATION-------------------------------------------------
      --UPDATE #TEMP SET Frequency=0 WHERE Frequency IS NULL AND CONVERT(DATE,AggredatedDate) IN (SELECT CONVERT(DATE,EvntTs) FROM 
      --StdtSessEvent WHERE EventType='CH' AND StudentId=@SID) --AND FrqStat=0
      --UPDATE #TEMP SET Duration=0 WHERE Duration IS NULL AND MeasurementId IN (SELECT MeasurementId FROM BehaviourDetails WHERE Duration='true'
      --AND MeasurementId IN (SELECT DISTINCT MeasurementId FROM #TEMP)) AND CONVERT(DATE,AggredatedDate) IN (SELECT CONVERT(DATE,EvntTs) FROM 
      --StdtSessEvent WHERE EventType='CH' AND StudentId=@SID) --AND FrqStat=0
      -------------------------------------------------------------------------------------

	  --Update #temp set frequency=0 where frequency is null and eventtype in('major','minor')
      	  

	  --MAJOR_MINOR Y AXIS FIX - SECTION START

	  DECLARE @SpltBehIds TABLE
	  (
	    dataid INT IDENTITY (1,1), 
		data INT
	  )      
      INSERT INTO @SpltBehIds SELECT * FROM Split(@BehaviorIDs, ',')

	  DECLARE @BehTotalCount INT =  0,
			  @BehLoopInc INT = 1,
			  @ScoreFreq VARCHAR(500) = NULL,
			  @ScoreDur VARCHAR(500) = NULL,
			  @BehvrID INT = 0

	  SET @BehTotalCount = (SELECT COUNT(*) FROM  @SpltBehIds)
	  
	  WHILE (@BehLoopInc <= @BehTotalCount)
	  BEGIN
		 SET @BehvrID = (SELECT data FROM @SpltBehIds WHERE dataid = @BehLoopInc)
		 SET @ScoreFreq = (SELECT MAX(frequency) FROM #temp WHERE measurementid = @BehvrID AND frequency IS NOT NULL)
	     SET @ScoreDur = (SELECT MAX(duration) FROM #temp WHERE measurementid = @BehvrID AND duration IS NOT NULL)

		 IF((@ScoreFreq IS NULL) AND (@ScoreDur IS NOT NULL))
		 BEGIN
			UPDATE #temp SET #temp.frequency = tm.duration FROM #temp, #temp tm WHERE tm.measurementid = @BehvrID and #temp.aggredateddate = tm.aggredateddate and #temp.measurementid = @BehvrID and  #temp.eventtype in('major','minor')
		 END
		 ELSE IF((@ScoreFreq IS NULL) AND (@ScoreDur IS NULL))
		 BEGIN
			DELETE FROM #TEMP WHERE eventtype in('major','minor') AND measurementid = @BehvrID			
		 END
		 ELSE IF((@ScoreFreq IS NOT NULL) AND (@ScoreDur IS NULL))
		 BEGIN					
		 UPDATE #temp SET #temp.frequency = tm.frequency FROM #temp, #temp tm WHERE tm.measurementid = @BehvrID and #temp.aggredateddate = tm.aggredateddate and #temp.measurementid = @BehvrID	and  #temp.eventtype in('major','minor')
		 END
		 ELSE IF((@ScoreFreq IS NOT NULL) AND (@ScoreDur IS NOT NULL))
		 BEGIN					
		 UPDATE #temp SET #temp.frequency = tm.frequency,#temp.duration = tm.duration FROM #temp, #temp tm WHERE tm.measurementid = @BehvrID and #temp.aggredateddate = tm.aggredateddate and #temp.measurementid = @BehvrID and  #temp.eventtype in('major','minor')
		 END

		 SET @BehLoopInc = @BehLoopInc + 1;
	  END
	    --MAJOR_MINOR Y AXIS FIX - SECTION -- END

		DECLARE @ClsTypeCommon VARCHAR(500) = NULL
		SET @ClsTypeCommon = (SELECT TOP 1 #Temp.classtype FROM #Temp where classtype IN (SELECT data FROM Split(@ClassTypeFlag, ',')) GROUP BY #Temp.classtype ORDER BY COUNT(*) DESC)

		IF(@ClsTypeCommon is not null)
		BEGIN
			Update #temp SET #Temp.classtype=@ClsTypeCommon where #Temp.eventtype is not null and #Temp.classtype is null
		END
		ELSE IF( @ClsType = 'Day' )
        BEGIN
            Update #temp SET #Temp.classtype='Day' where #Temp.eventtype is not null and #Temp.classtype is null
        END
		ELSE IF ( @ClsType = 'Residence' )
        BEGIN
            Update #temp SET #Temp.classtype='Residence' where #Temp.eventtype is not null and #Temp.classtype is null
        END
		ELSE
        BEGIN
            Update #temp SET #Temp.classtype='Day' where #Temp.eventtype is not null and #Temp.classtype is null
        END
 	  
	  SELECT *,
             (SELECT duration
              FROM   behaviourdetails
              WHERE  measurementid = #temp.measurementid)       DuratnStat,
             (SELECT behavdefinition
              FROM   behaviourdetails BDS
              WHERE  BDS.measurementid = #temp.measurementid)   Deftn,
             'Stgy: '
             + (SELECT behavstrategy
                FROM   behaviourdetails BDS
                WHERE  BDS.measurementid = #temp.measurementid) Stratgy
      FROM   #temp
      ORDER  BY measurementid,
                aggredateddate,
                xvalue

      DROP TABLE #temp_stdtaggscores
  END


GO
