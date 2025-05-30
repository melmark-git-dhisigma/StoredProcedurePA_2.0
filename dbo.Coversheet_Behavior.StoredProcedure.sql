USE [MelmarkNE1]
GO
/****** Object:  StoredProcedure [dbo].[Coversheet_Behavior]    Script Date: 4/15/2025 8:26:40 AM ******/
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

	DECLARE @SDate                 DATETIME,
              @EDate                 DATETIME,
              @SID                   INT,
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
              @Duration              INT,
			  @LOOP					 INT,
			  @MID					 INT
			  			   	
     
			 SET @SDate=@StartDate
			 SET @EDate=@ENDDate
			 SET @SID=@Studentid
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

--=============[ Declare @TempBehaviourIds Table Variable to Store the BehaviorIds of the student which is submitted in between the given date Range  ] =====================
        
	   DECLARE @TempBehaviourIds TABLE
		(
		  BehavId INT
		)
 
		INSERT INTO @TempBehaviourIds
		SELECT DISTINCT MeasurementId
		FROM Behaviour
		WHERE StudentId = @SID
		AND CONVERT(DATE, CreatedOn) BETWEEN @SDate AND @EDate;
     	   
--=============[ Create #temp_stdtaggscores temporary Table] =====================

		IF Object_id('tempdb..#Temp_StdtAggscores') IS NOT NULL
		DROP TABLE #temp_stdtaggscores

		CREATE TABLE #temp_stdtaggscores
		(
			[stdtaggscoreid]     INT IDENTITY(1, 1) NOT NULL,			
			[aggredateddate]     DATETIME,
			[measurementid]      INT,
			[frequency]          INT,
			[duration]           FLOAT,
		)

--=============[ INSERT BEHAVIOR DETAILS TO #temp_stdtaggscores TABLE] =====================	  
 
		INSERT INTO #temp_stdtaggscores
		 (measurementid, aggredateddate, frequency, duration)
		SELECT 			
			BDS.measurementid,
			RP.perioddate,
			SUM(BR.frequencycount) AS frequency, -- Sum frequency counts
			ROUND(SUM(CONVERT(FLOAT, BR.duration)) / 60, 2) AS DurationMin -- Sum duration in minutes
		FROM
			behaviourdetails BDS
		INNER JOIN 
			class Cls ON Cls.classid = BDS.classid
		INNER JOIN 
			reportperiod RP ON RP.perioddate BETWEEN @SDate AND @EDate
		LEFT JOIN 
			behaviour BR ON BR.measurementid = BDS.measurementid
						AND CONVERT(DATE, BR.timeofevent) = CONVERT(DATE, RP.perioddate)
		WHERE
			BDS.activeind IN ('A', 'N')
			AND BDS.schoolid = @School
			AND BDS.studentid = @SID
			AND BDS.measurementid IN (SELECT BehavId FROM @TempBehaviourIds)
			AND (RP.perioddate IS NOT NULL)
		GROUP BY 			
			BDS.measurementid,
			RP.perioddate
		ORDER  BY measurementid,
				  RP.perioddate
--=============[ INSERT BEHAVIOR DETAILS TO #TEMP TABLE] =====================	  
   
		IF Object_id('tempdb..#TEMP') IS NOT NULL
		DROP TABLE #temp

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

		

		;WITH NextDate AS (
    SELECT 
        measurementid, 
        MAX(aggredateddate) AS last_date
    FROM #temp_stdtaggscores
    GROUP BY measurementid
)
INSERT INTO #temp_stdtaggscores (measurementid, aggredateddate)
SELECT 
    NextDate.measurementid,
    DATEADD(DAY, 1, NextDate.last_date) AS new_aggredateddate
FROM NextDate
WHERE EXISTS (SELECT 1 FROM #temp_stdtaggscores WHERE measurementid = NextDate.measurementid)
 

INSERT INTO #temp
                                    (measurementid,
                                     aggredateddate,
                                     frequency,
                                     duration
									 )
                        SELECT measurementid,
                               aggredateddate,
                               frequency,
                               duration
                        FROM   #temp_stdtaggscores
						ORDER  BY measurementid,
                                  aggredateddate




    ;WITH CTE AS (
    SELECT 
        scoreid, 
        measurementid, 
        aggredateddate, 
        ROW_NUMBER() OVER (PARTITION BY measurementid ORDER BY aggredateddate) AS new_xvalue
    FROM #temp
    )
UPDATE #temp
SET xvalue = CTE.new_xvalue
FROM #temp m
JOIN CTE ON m.scoreid = CTE.scoreid
       AND m.measurementid = CTE.measurementid
       AND m.aggredateddate = CTE.aggredateddate;

     
   

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




	Declare @tmpTable table (SCOREIDC		INT PRIMARY KEY NOT NULL IDENTITY(1,1),
							MEASUREMENTIDC	INT,
							MAXFREQ			INT,
							MAXDUR			INT,
							FREDELTAXC		INT,
							DURELTAXC		INT,
							FREDELTAYC		FLOAT,
							DURELTAYC		FLOAT)


	Insert into @tmpTable	
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
	

	IF OBJECT_ID('tempdb..#TEMP2') IS NOT NULL  
	DROP TABLE #TEMP2

	IF OBJECT_ID('tempdb..#TEMPBEHAV') IS NOT NULL  
	DROP TABLE #TEMPBEHAV

	
CREATE TABLE #TEMPBEHAV(Scoreid int PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,BehaveDate DATETIME,Behavior VARCHAR(500),Frequency FLOAT,Duration FLOAT,GoalDesc VARCHAR(MAX),BasPerlvl VARCHAR(MAX),IEPObj VARCHAR(MAX));
--CREATE TABLE #TEMP2(Scoreid int PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,BehaveDate DATETIME,Behavior VARCHAR(500),Frequency FLOAT,Duration FLOAT,XVal int);

	--INSERT INTO #TEMPBEHAV SELECT * FROM (SELECT BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn) BehaviorDate,BDTS.Behaviour,CASE WHEN (BDTS.Frequency=1 AND BDTS.Duration=1) THEN 
	--CONVERT(FLOAT,(COUNT(BHR.Duration) + SUM(FrequencyCount)))/CONVERT(FLOAT,(COUNT(BHR.Duration) + COUNT(FrequencyCount))) ELSE CASE WHEN (BDTS.Duration=1)
	--THEN CONVERT(FLOAT,1)  ELSE  CONVERT(FLOAT,AVG(FrequencyCount)) END END AS Frequency,(AVG(CONVERT(float,BHR.Duration)))/60 AS DurationMin, BDTS.GoalDesc,BDTS.BehaviorBasPerfLvl,BDTS.BehaviorIEPObjctve FROM Behaviour BHR INNER JOIN BehaviourDetails BDTS ON 
	--BHR.MeasurementId=BDTS.MeasurementId WHERE BDTS.StudentId=@SID AND BDTS.ActiveInd='A' AND BDTS.[SchoolId]=@School AND CONVERT(DATE,BHR.CreatedOn) BETWEEN @SDATE 
	--AND @EDATE GROUP BY BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn),BDTS.Behaviour,BDTS.Frequency,BDTS.Duration,BDTS.GoalDesc,BDTS.BehaviorBasPerfLvl,BDTS.BehaviorIEPObjctve ) 
	--AS BEHAV ORDER BY MeasurementId

	INSERT INTO #TEMPBEHAV
SELECT * 
FROM (
    SELECT 
        BHR.MeasurementId,
        CONVERT(DATE, BHR.CreatedOn) AS BehaviorDate,
        BDTS.Behaviour,
        CASE 
            WHEN (BDTS.Frequency = 1 AND BDTS.Duration = 1) THEN 
                CONVERT(FLOAT, (COUNT(BHR.Duration) + SUM(FrequencyCount))) / 
                CONVERT(FLOAT, (COUNT(BHR.Duration) + COUNT(FrequencyCount)))
            ELSE 
                CASE 
                    WHEN (BDTS.Duration = 1) THEN 
                        CONVERT(FLOAT, 1)
                    ELSE 
                        CONVERT(FLOAT, AVG(FrequencyCount))
                END 
        END AS Frequency,
        (AVG(CONVERT(FLOAT, BHR.Duration))) / 60 AS DurationMin,
        BDTS.GoalDesc,
        BDTS.BehaviorBasPerfLvl,
        BDTS.BehaviorIEPObjctve
    FROM 
        Behaviour BHR
    INNER JOIN 
        BehaviourDetails BDTS ON BHR.MeasurementId = BDTS.MeasurementId
    WHERE 
        BDTS.StudentId = @SID 
        AND BDTS.ActiveInd = 'A' 
        AND BDTS.SchoolId = @School
        AND CONVERT(DATE, BHR.CreatedOn) BETWEEN @SDATE AND @EDATE
    GROUP BY 
        BHR.MeasurementId,
        CONVERT(DATE, BHR.CreatedOn),
        BDTS.Behaviour,
        BDTS.Frequency,
        BDTS.Duration,
        BDTS.GoalDesc,
        BDTS.BehaviorBasPerfLvl,
        BDTS.BehaviorIEPObjctve
) AS BEHAV
ORDER BY 
    MeasurementId;
	


	CREATE TABLE #TEMPBEHAV1
(
    Scoreid            INT PRIMARY KEY NOT NULL IDENTITY(1,1),
    MeasurementId      INT,
    Behaviour          VARCHAR(500),
    FRQDeltaX          FLOAT,
    FRQDeltaY          FLOAT,
    FRQSlope           FLOAT,
    DURDeltaX          FLOAT,
    DURDeltaY          FLOAT,
    DURSlope           FLOAT,
    FRQSharpDecrease   VARCHAR(1),
    FRQSlightDecrease  VARCHAR(1),
    FRQStable          VARCHAR(10),
    FRQSlightIncrease  VARCHAR(1),
    FRQSharpIncrease   VARCHAR(1),
    DURSharpDecrease   VARCHAR(1),
    DURSlightDecrease  VARCHAR(1),
    DURStable          VARCHAR(10),
    DURSlightIncrease  VARCHAR(1),
    DURSharpIncrease   VARCHAR(1),
    GoalDesc           VARCHAR(MAX),
    BasPerlvl          VARCHAR(MAX),
    IEPObj             VARCHAR(MAX),
    IOAPOINTS          VARCHAR(MAX),
    DAYCOUNT           VARCHAR(MAX),
    MAXY_ValueFRE      FLOAT,
    MAXY_ValueDUR      FLOAT
);



INSERT INTO #TEMPBEHAV1 
(
    MeasurementId,
    Behaviour,
    GoalDesc,
    BasPerlvl,
    IEPObj
)
SELECT DISTINCT 
    MeasurementId,
    Behaviour,
    GoalDesc,
    BehaviorBasPerfLvl,
    BehaviorIEPObjctve
FROM 
(
    SELECT 
        BHR.MeasurementId,
        CONVERT(DATE, BHR.CreatedOn) AS BehaviorDate,
        BDTS.Behaviour,
        CASE 
            WHEN (BDTS.Frequency = 1 AND BDTS.Duration = 1) THEN
                CONVERT(FLOAT, (COUNT(BHR.Duration) + SUM(FrequencyCount))) / 
                CONVERT(FLOAT, (COUNT(BHR.Duration) + COUNT(FrequencyCount)))
            ELSE 
                CASE 
                    WHEN (BDTS.Duration = 1) THEN CONVERT(FLOAT, 1)  
                    ELSE CONVERT(FLOAT, AVG(FrequencyCount)) 
                END 
        END AS Frequency,
        (AVG(CONVERT(FLOAT, BHR.Duration))) / 60 AS DurationMin,
        BDTS.GoalDesc,
        BDTS.BehaviorBasPerfLvl,
        BDTS.BehaviorIEPObjctve
    FROM 
        Behaviour BHR
    INNER JOIN 
        BehaviourDetails BDTS ON BHR.MeasurementId = BDTS.MeasurementId
    WHERE 
        BDTS.StudentId = @SID
        AND BDTS.ActiveInd = 'A'
        AND BDTS.[SchoolId] = @School
        AND CONVERT(DATE, BHR.CreatedOn) BETWEEN @SDate AND @EDate
    GROUP BY 
        BHR.MeasurementId,
        CONVERT(DATE, BHR.CreatedOn),
        BDTS.Behaviour,
        BDTS.Frequency,
        BDTS.Duration,
        BDTS.GoalDesc,
        BDTS.BehaviorBasPerfLvl,
        BDTS.BehaviorIEPObjctve
) AS BEHAV
ORDER BY 
    MeasurementId;


	--CREATE TABLE #TEMPBEHAV1(Scoreid int PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,Behaviour VARCHAR(500),FRQDeltaX FLOAT,FRQDeltaY FLOAT
	--,FRQSlope FLOAT,DURDeltaX FLOAT,DURDeltaY FLOAT,DURSlope FLOAT,FRQSharpDecrease VARCHAR(1),FRQSlightDecrease VARCHAR(1),FRQStable VARCHAR(10),FRQSlightIncrease VARCHAR(1),FRQSharpIncrease VARCHAR(1),
	--DURSharpDecrease VARCHAR(1),DURSlightDecrease VARCHAR(1),DURStable VARCHAR(10),DURSlightIncrease VARCHAR(1),DURSharpIncrease VARCHAR(1),GoalDesc VARCHAR(MAX),BasPerlvl VARCHAR(MAX),IEPObj VARCHAR(MAX),IOAPOINTS VARCHAR(MAX),DAYCOUNT VARCHAR(MAX),MAXY_ValueFRE float,MAXY_ValueDUR float);

	--INSERT INTO #TEMPBEHAV1(MeasurementId,Behaviour,GoalDesc,BasPerlvl,IEPObj) 
	--SELECT DISTINCT MeasurementId,Behaviour,GoalDesc, BehaviorBasPerfLvl, BehaviorIEPObjctve FROM (SELECT BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn) BehaviorDate,BDTS.Behaviour,CASE WHEN (BDTS.Frequency=1 AND BDTS.Duration=1) THEN 
	--CONVERT(FLOAT,(COUNT(BHR.Duration) + SUM(FrequencyCount)))/CONVERT(FLOAT,(COUNT(BHR.Duration) + COUNT(FrequencyCount))) ELSE CASE WHEN (BDTS.Duration=1)
	--THEN CONVERT(FLOAT,1)  ELSE  CONVERT(FLOAT,AVG(FrequencyCount)) END END AS Frequency,(AVG(CONVERT(float,BHR.Duration)))/60 AS DurationMin, BDTS.GoalDesc, BDTS.BehaviorBasPerfLvl, BDTS.BehaviorIEPObjctve FROM Behaviour BHR INNER JOIN BehaviourDetails BDTS ON 
	--BHR.MeasurementId=BDTS.MeasurementId WHERE BDTS.StudentId=@SID AND BDTS.ActiveInd='A' AND BDTS.[SchoolId]=@School AND  CONVERT(DATE,BHR.CreatedOn) BETWEEN @StartDate 
	--AND @ENDDate GROUP BY BHR.MeasurementId,CONVERT(DATE,BHR.CreatedOn),BDTS.Behaviour,BDTS.Frequency,BDTS.Duration,BDTS.GoalDesc,BDTS.BehaviorBasPerfLvl,BDTS.BehaviorIEPObjctve ) 
	--AS BEHAV ORDER BY MeasurementId

	
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
			SET @FREQ=(SELECT SUM(FrequencyCount) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@SDate AND CONVERT(DATE,CreatedOn)<=@EDate)
			SET @DAYCOUNT=(SELECT COUNT(DISTINCT(CONVERT(DATE,CreatedOn))) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@SDate AND CONVERT(DATE,CreatedOn)<=@EDate)
			UPDATE #TEMPBEHAV1 SET FRQSlope=ROUND((@FREQ/@DAYCOUNT),2) WHERE MeasurementId=@MID
			--PRINT CAST(@DAYCOUNT  as VARCHAR(max))+' -'+CAST(@MID as VARCHAR(max))
		END
		IF (@DUR = 1)
		BEGIN
			SET @DUR=(SELECT SUM(CONVERT(FLOAT, Duration)) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@SDate AND CONVERT(DATE,CreatedOn)<=@EDate)
			SET @DAYCOUNT=(SELECT COUNT(DISTINCT(CONVERT(DATE,CreatedOn))) FROM Behaviour WHERE MeasurementId=@MID AND CONVERT(DATE,CreatedOn)>=@SDate AND CONVERT(DATE,CreatedOn)<=@EDate)
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
	

	UPDATE #TEMPBEHAV1
SET 
    DURStable = CASE 
                    WHEN EXISTS (
                        SELECT 1
                        FROM BehaviourDetails BD
                        WHERE BD.MeasurementId = #TEMPBEHAV1.MeasurementId
                          AND BD.Duration = 0
                          AND BD.StudentId = @SID
                    ) THEN 'N/A'
                    ELSE DURStable
                END,
    DURSlope = CASE 
                    WHEN EXISTS (
                        SELECT 1
                        FROM BehaviourDetails BD
                        WHERE BD.MeasurementId = #TEMPBEHAV1.MeasurementId
                          AND BD.Duration = 0
                          AND BD.StudentId = @SID
                    ) THEN 'N/A'
                    ELSE DURSlope
                END,
    FRQStable = CASE 
                    WHEN EXISTS (
                        SELECT 1
                        FROM BehaviourDetails BD
                        WHERE BD.MeasurementId = #TEMPBEHAV1.MeasurementId
                          AND BD.Frequency = 0
                          AND BD.StudentId = @SID
                          AND BD.YesOrNo = 0
                    ) THEN 'N/A'
                    ELSE FRQStable
                END,
    FRQSlope = CASE 
                    WHEN EXISTS (
                        SELECT 1
                        FROM BehaviourDetails BD
                        WHERE BD.MeasurementId = #TEMPBEHAV1.MeasurementId
                          AND BD.Frequency = 0
                          AND BD.StudentId = @SID
                          AND BD.YesOrNo = 0
                    ) THEN 'N/A'
                    ELSE FRQSlope
                END
WHERE MeasurementId IN (
    SELECT MeasurementId
    FROM BehaviourDetails
    WHERE (Duration = 0 AND StudentId = @SID)
       OR (Frequency = 0 AND StudentId = @SID AND YesOrNo = 0)
);

			UPDATE #TEMPBEHAV1
SET DAYCOUNT = CAST((
    SELECT COUNT(MeasurementId)
    FROM #TEMPBEHAV 
    WHERE MeasurementId = #TEMPBEHAV1.MeasurementId -- Reference MeasurementId from the current row of #TEMPBEHAV1
    GROUP BY MeasurementId
) AS VARCHAR(MAX)) + ' days'
WHERE EXISTS (
    SELECT 1
    FROM #TEMPBEHAV
    WHERE MeasurementId = #TEMPBEHAV1.MeasurementId -- Ensure we are updating only the relevant rows
);

UPDATE  #TEMPBEHAV1 SET DAYCOUNT=DAYCOUNT+'- Too few for Trends' where DAYCOUNT='1 days'

			UPDATE #TEMPBEHAV1
SET IOAPOINTS = (
    SELECT STUFF(
        (
            SELECT TOP 2 
                '-' + CAST(EvntTs AS VARCHAR(500)) + '_' + CAST(EventName AS VARCHAR(500))
            FROM (
                SELECT 
                    'IOA ' + CONVERT(NVARCHAR, ROUND(ioaperc, 0), 0) + '% ' +
                    CASE 
                        WHEN BIOA.normalbehaviorid IS NULL THEN 
                            -- Constructing EventName for NULL normalbehaviorid
                            (
                                SELECT TOP 1 
                                    RTRIM(LTRIM(UPPER(US.userinitial)))
                                FROM behaviour BH
                                INNER JOIN [user] US ON BH.createdby = US.userid
                                WHERE BH.createdon BETWEEN DATEADD(MINUTE, -5, BIOA.createdon) AND BIOA.createdon
                                ORDER BY BH.createdon DESC
                            ) + '/' + 
                            (
                                SELECT TOP 1 
                                    RTRIM(LTRIM(UPPER(US.userinitial)))
                                FROM behaviorioadetails BI
                                INNER JOIN [user] US ON BI.createdby = US.userid
                                WHERE BI.createdon = BIOA.createdon
                                ORDER BY BI.createdon DESC
                            )
                        ELSE
                            -- Constructing EventName when normalbehaviorid is NOT NULL
                            (
                                SELECT 
                                    RTRIM(LTRIM(UPPER(US.userinitial)))
                                FROM behaviour BH
                                INNER JOIN [user] US ON BH.createdby = US.userid
                                WHERE BIOA.normalbehaviorid = BH.behaviourid
                            ) + '/' +
                            (
                                SELECT 
                                    RTRIM(LTRIM(UPPER(US.userinitial)))
                                FROM behaviorioadetails BI
                                INNER JOIN [user] US ON BI.createdby = US.userid
                                INNER JOIN behaviour BH ON BH.behaviourid = BI.normalbehaviorid
                                WHERE BIOA.normalbehaviorid = BH.behaviourid
                            )
                    END AS EventName,
                    CONVERT(CHAR(10), BIOA.createdon, 101) AS EvntTs,
					BIOA.createdon AS EventDate
                FROM behaviorioadetails BIOA
                LEFT JOIN behaviourdetails BHD ON BIOA.measurementid = BHD.measurementid
                WHERE BIOA.studentid = @SID
                  AND ioaperc IS NOT NULL
                  AND BIOA.activeind = 'A'
                  AND BIOA.MeasurementId = #TEMPBEHAV1.MeasurementId  -- Reference MeasurementId from the table itself
                  AND CONVERT(CHAR(10), BIOA.createdon, 101) BETWEEN @SDate AND @EDate
            ) AS EventData 
            ORDER BY EventDate DESC
            FOR XML PATH('')
        ), 1, 1, ''
    ) AS IOA_Val)
WHERE MeasurementId = #TEMPBEHAV1.MeasurementId; -- Ensures you update the correct row
	
	--=======================================================

	SELECT * FROM #TEMPBEHAV1
	DROP TABLE #TEMPBEHAV
	DROP TABLE #TEMPBEHAV1
	DROP TABLE #TEMP

END


GO
