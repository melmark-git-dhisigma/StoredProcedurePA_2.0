USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Coversheet_Trendline]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Coversheet_Trendline] @StartDate DATETIME,
                                                 @ENDDate   DATETIME,
                                                 @Studentid INT,
                                                 @SchoolId  INT
AS
  BEGIN
      SET nocount ON;

      DECLARE @SDate                 DATETIME,
              @EDate                 DATETIME,
              @SID                   INT,
              @BehaviorIDs           VARCHAR(500),
              @School                INT,
              @LCount                INT,
              @LoopBehavior          INT,
              @Cnt                   INT,
              @Frequency             INT,
              @Scoreid               INT,
              @NullcntFrequency      INT,
              @NullcntDuration       INT,
              @Breaktrendfrequencyid INT,
              @Breaktrenddurationid  INT,
              @NumOfTrend            INT,
              @TrendsectionNo        INT,
              @DateCnt               INT,
              @Midrate1              FLOAT,
              @Midrate2              FLOAT,
              @Slope                 FLOAT,
              @Const                 FLOAT,
              @Ids                   INT,
              @IdOfTrend             INT,
              @TMPBehavior           INT,
              @TMPDate               DATETIME,
              @TMPStartDate          DATETIME,
              @TMPCount              INT,
              @TMPLoopCount          INT,
              @TMPSesscnt            INT,
              @BehaviorOld           INT,
              @OldTMPDate            DATETIME,
              @Duration              INT,
			  @Behavior				 VARCHAR(500)	
      DECLARE @splt TABLE
        (
           data INT
        )

      SET @SDate=@StartDate
      SET @EDate=@ENDDate
      SET @SID=@Studentid
      SET @BehaviorIDs=@Behavior
      SET @School=@SchoolId
      SET @LCount=0
      SET @LoopBehavior=0
      SET @Cnt=1
      SET @Scoreid=0
      SET @NullcntFrequency=0
      SET @NullcntDuration=0
      SET @Breaktrendfrequencyid=1
      SET @Breaktrenddurationid=1
      SET @NumOfTrend=0
      SET @TrendsectionNo=0
      SET @TMPBehavior =0
      SET @TMPStartDate= @StartDate
      SET @TMPCount=0
      SET @TMPLoopCount=1
      SET @TMPSesscnt=1
      SET @BehaviorOld=0

      --=============[ New Section for Batch dynamic Updation - Start ] =================================================================================================================
      DECLARE @StdtAgg_splt TABLE
        (
           data INT
        )
      DECLARE @Counts INT

	  SET @BehaviorIDs= (SELECT STUFF((SELECT distinct ',' + CAST(MeasurementId AS VARCHAR(MAX)) FROM Behaviour
					WHERE StudentId=@SID 
					AND CONVERT(DATE,CreatedOn) BETWEEN @SDate AND @EDate
					FOR XML PATH('')), 1, 1, ''))

      INSERT INTO @StdtAgg_splt
      SELECT *
      FROM   Split(@BehaviorIDs, ',')

	  

      IF Object_id('tempdb..#Temp_StdtAggscores') IS NOT NULL
        DROP TABLE #temp_stdtaggscores

      CREATE TABLE #temp_stdtaggscores
        (
           [stdtaggscoreid]     [INT] IDENTITY(1, 1) NOT NULL,
           [schoolid]           [INT] NULL,
           [classid]            [INT] NULL,
           [studentid]          [INT] NULL,
           [aggredateddate]     [DATETIME] NULL,
           [measurementid]      [INT] NULL,
           [frequency]          [INT] NULL,
           [duration]           [FLOAT] NULL,
        )
      ON [PRIMARY]      

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
                   duration)
      SELECT schoolid,
             studentid,
             classid,
             measurementid,
             perioddate,
             frequncy,
             Round(durationmin, 2) DurationMin
      FROM   (SELECT schoolid,
                     studentid,
                     classid,
                     measurementid,
                     perioddate,
                     (SELECT Sum(frequencycount)
                      FROM   behaviour BR
                      WHERE  CONVERT(DATE, timeofevent) =
                             CONVERT(DATE, perioddate)
                             AND BR.measurementid = Behaviordata.measurementid)
                     AS
                     Frequncy,
                     (SELECT ( Sum(CONVERT(FLOAT, BR.duration)) ) / 60
                      FROM   behaviour BR
                      WHERE  CONVERT(DATE, timeofevent) =
                             CONVERT(DATE, perioddate)
                             AND BR.measurementid = Behaviordata.measurementid)
                     AS
                            DurationMin
                     
              FROM   (SELECT BDS.schoolid,
                             BDS.studentid,
                             BDS.classid,
                             BDS.measurementid,
                             BDS.period
                      FROM   behaviourdetails BDS
                             INNER JOIN class Cls
                                     ON Cls.classid = BDS.classid
                      WHERE  BDS.activeind IN( 'A', 'N' )
                             AND BDS.schoolid = @SchoolId
                             AND BDS.studentid = @Studentid
                             AND BDS.measurementid IN (SELECT *
                                                       FROM   @StdtAgg_splt)) AS
                     Behaviordata
                     ,
                     reportperiod
              WHERE  perioddate BETWEEN @StartDate AND @ENDDate
                     AND ( period <> 0
                            OR period IS NULL )) BEH

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
           aggdate       DATETIME
        );

      --SELECT ALL LESSON DETAILS BETWEEN STARTDATE AND ENDDATE FROM THE TABLE 'StdtAggScores' AND INSERT IT TO #AGGSCORE TABLE
      INSERT INTO @AGGSCORE
      SELECT DISTINCT measurementid,
                      frequency,
                      duration,
                      aggredateddate
      FROM   #temp_stdtaggscores
      WHERE  aggredateddate BETWEEN @SDate AND @EDate
             AND studentid = @SID
             AND schoolid = @School
             AND measurementid IN (SELECT *
                                   FROM   @splt)
      ORDER  BY measurementid,
                aggredateddate

      CREATE TABLE #temp
        (
           scoreid             INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           measurementid       INT,
           frequency           FLOAT,
           duration            FLOAT,
           aggredateddate      DATETIME,
           breaktrendfrequency INT,
           breaktrendduration  INT,
           xvalue              INT,
           trendfrequency      FLOAT,
           trendduration       FLOAT
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
                               duration
							   )
                  SELECT measurementid,
                         aggdate,
                         @TMPSesscnt,
                         frequency,
                         duration
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
                                     duration
									 )
                        SELECT measurementid,
                               aggdate,
                               @TMPSesscnt,
                               frequency,
                               duration
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

                 
                  SET @Scoreid=@Scoreid + 1
              END

            SET @Cnt=@Cnt + 1
            SET @LCount=@LCount - 1
        END

      DROP TABLE #temptype      

      --SELECT EACH TREND LINE SECTION FROM #TEMP AND CALCULATE TREND POINT VALUES
      SET @Cnt=0

      
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
			  			  

	CREATE TABLE #TEMPTREND
	(TENDID int PRIMARY KEY NOT NULL IDENTITY(1,1),
	MEASUREMENTID	INT,
	STARTTRENDFREQ	FLOAT,
	ENDTRENDFREQ	FLOAT,
	STARTTRENDDUR	FLOAT,	
	ENDTRENDDUR		FLOAT,
	MAXFREQ			INT,
	MAXDUR			INT,
	FREDELTAY		FLOAT,	
	DURELTAY		FLOAT,
	FREDELTAX		INT,
	DURELTAX		INT
	)

	INSERT INTO #TEMPTREND
	(
	MEASUREMENTID
	)
	SELECT DISTINCT  MEASUREMENTID FROM #temp AS MEASUREMENTID
	
	DECLARE @CNTTR INT
	DECLARE @MEID INT

	SET @CNTTR=(SELECT COUNT(TENDID) FROM #TEMPTREND)
	WHILE(@CNTTR>0)
	BEGIN
	SET @MEID=(SELECT MEASUREMENTID FROM #TEMPTREND WHERE TENDID=@CNTTR)
	UPDATE #TEMPTREND SET STARTTRENDFREQ =(SELECT TOP 1 trendfrequency FROM #temp WHERE MEASUREMENTID=@MEID AND trendfrequency IS NOT NULL ORDER BY aggredateddate ASC) WHERE MEASUREMENTID=@MEID	
	UPDATE #TEMPTREND SET ENDTRENDFREQ	 =(SELECT TOP 1 trendfrequency FROM #temp WHERE MEASUREMENTID=@MEID AND trendfrequency IS NOT NULL ORDER BY aggredateddate DESC) WHERE MEASUREMENTID=@MEID
	UPDATE #TEMPTREND SET STARTTRENDDUR  =(SELECT TOP 1 trendduration FROM #temp WHERE MEASUREMENTID=@MEID AND trendduration IS NOT NULL ORDER BY aggredateddate ASC) WHERE MEASUREMENTID=@MEID	
	UPDATE #TEMPTREND SET ENDTRENDDUR    =(SELECT TOP 1 trendduration FROM #temp WHERE MEASUREMENTID=@MEID AND trendduration IS NOT NULL ORDER BY aggredateddate DESC) WHERE MEASUREMENTID=@MEID
	
	UPDATE #TEMPTREND SET FREDELTAY=(ENDTRENDFREQ-STARTTRENDFREQ) WHERE MEASUREMENTID=@MEID
	UPDATE #TEMPTREND SET DURELTAY=(ENDTRENDDUR-STARTTRENDDUR) WHERE MEASUREMENTID=@MEID

	UPDATE #TEMPTREND SET MAXFREQ=(SELECT MAX(FREQUENCY) FROM #temp WHERE MEASUREMENTID=@MEID) WHERE MEASUREMENTID=@MEID
	UPDATE #TEMPTREND SET MAXDUR=(SELECT MAX(DURATION) FROM #temp WHERE MEASUREMENTID=@MEID) WHERE MEASUREMENTID=@MEID

	DECLARE @DELTAFQRSTX DATETIME
	DECLARE @DELTAFRQENX DATETIME
	DECLARE @DELFX INT
	DECLARE @DELTADURSTX DATETIME
	DECLARE @DELTADURENX DATETIME
	DECLARE @DELDX INT

	SET @DELTAFQRSTX=(SELECT TOP 1 aggredateddate FROM #temp WHERE MEASUREMENTID=@MEID AND trendfrequency IS NOT NULL
	 AND trendfrequency=(SELECT STARTTRENDFREQ FROM #TEMPTREND WHERE MEASUREMENTID=@MEID ) ORDER BY aggredateddate ASC)
	
	SET @DELTAFRQENX=(SELECT TOP 1 aggredateddate FROM #temp WHERE MEASUREMENTID=@MEID AND trendfrequency IS NOT NULL 
	AND trendfrequency=(SELECT ENDTRENDFREQ FROM #TEMPTREND WHERE MEASUREMENTID=@MEID ) ORDER BY aggredateddate DESC)
	
	SET @DELFX=DATEDIFF(DAY,@DELTAFQRSTX,@DELTAFRQENX)

	SET @DELTADURSTX=(SELECT TOP 1 aggredateddate FROM #temp WHERE MEASUREMENTID=@MEID AND trendduration IS NOT NULL 
	AND trendduration=(SELECT STARTTRENDDUR FROM #TEMPTREND WHERE MEASUREMENTID=@MEID ) ORDER BY aggredateddate ASC)
	
	SET @DELTADURENX=(SELECT TOP 1 aggredateddate FROM #temp WHERE MEASUREMENTID=@MEID AND trendduration IS NOT NULL 
	AND trendduration=(SELECT ENDTRENDDUR FROM #TEMPTREND WHERE MEASUREMENTID=@MEID ) ORDER BY aggredateddate DESC)
	
	SET @DELDX=DATEDIFF(DAY,@DELTADURSTX,@DELTADURENX)
		
	UPDATE #TEMPTREND SET FREDELTAX=@DELFX WHERE MEASUREMENTID=@MEID
	UPDATE #TEMPTREND SET DURELTAX=@DELDX WHERE MEASUREMENTID=@MEID	
	
	SET @CNTTR=@CNTTR-1
	END
		
	SELECT 
	MEASUREMENTID,
	MAXFREQ,
	MAXDUR,
	FREDELTAX,
	DURELTAX,
	FREDELTAY,
	DURELTAY

	FROM #TEMPTREND
	 
	  DROP TABLE #TEMPTREND
      DROP TABLE #temp_stdtaggscores
  END


GO
