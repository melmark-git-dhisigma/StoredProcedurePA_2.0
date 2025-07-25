USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[PSR_Data]    Script Date: 7/4/2025 1:21:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter PROCEDURE [dbo].[PSR_Data] @StartDate    DATETIME,
                                 @ENDDate      DATETIME,
                                 @Studentid    INT,
                                 @LessonPlanId VARCHAR(100),
                                 @LPStatus     VARCHAR(50),
								 @LessonType   VARCHAR(30),
								 @Timestatus   INT
AS
  BEGIN
      SET nocount ON;

	  DECLARE @ClassTypeFlag VARCHAR(30)
	  DECLARE @timestatbit INT = @Timestatus

		IF( @LessonType = 'DAY' )
	        BEGIN
		        SET @ClassTypeFlag = '0'
	        END
		ELSE IF ( @LessonType = 'RES' )
	        BEGIN
				SET @ClassTypeFlag = '1'
			END
		ELSE
			BEGIN
				SET @ClassTypeFlag = '0,1'
			END

      CREATE TABLE #raw
        (
           lessonname       VARCHAR(max),
           stdtsessionhdrid INT,
           sessdate         DATE,
           sesstime         TIME,
           sessnumber       INT,
           columnmeasure    NVARCHAR(max),
           setname          NVARCHAR(max),
           issetinmnt       VARCHAR(20),
           prompt           NVARCHAR(max),
           step             VARCHAR(100),
           ioa              VARCHAR(20),
           mistrial         VARCHAR(20),
		   mistrialrsn      VARCHAR(50),
           score            VARCHAR(50),
           eventname        NVARCHAR(max),
           eventtype        VARCHAR(50),
		   classtype		VARCHAR(50),
		   username			VARCHAR(max)
       );

		CREATE NONCLUSTERED INDEX idx_raw_studentid ON #raw (stdtsessionhdrid);
		CREATE NONCLUSTERED INDEX idx_raw_sessdate ON #raw (sessdate);
		--CREATE NONCLUSTERED INDEX idx_raw_lessonname ON #raw (lessonname);
		CREATE NONCLUSTERED INDEX idx_raw_sesstime ON #raw (sesstime);
		CREATE NONCLUSTERED INDEX idx_raw_sessnumber ON #raw (sessnumber);
		CREATE NONCLUSTERED INDEX idx_raw_classtype ON #raw (classtype);

      DECLARE @TempLESSON TABLE
        (
           id           INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           lessonname   VARCHAR(150),
           lessonplanid INT
        )

      INSERT INTO @TempLESSON
      SELECT TOP 1 DH.dstemplatename,
                   lessonplanid
      FROM   dstemphdr DH
             INNER JOIN lookup LU
                     ON DH.statusid = LU.lookupid
      WHERE  LU.lookupname IN (SELECT *
                               FROM   Split(@LPStatus, ','))
             AND studentid = @Studentid
             AND lessonplanid = @LessonPlanId
      ORDER  BY dstemphdrid DESC

      BEGIN
          INSERT INTO #raw
          SELECT TEMP.lessonname, 
					   hdr.stdtsessionhdrid, 
					   CONVERT(DATE, hdr.endts)                     SessDate, 
					   Cast(hdr.endts AS TIME)                      SessTime, 
					   hdr.sessionnbr                               AS SessNumber, 
					   CASE 
						 WHEN dcolcal.calctype IN ( 'Avg Duration', 'Total Duration' ) THEN 
						   CASE 
							 WHEN CASE 
									WHEN Hdr.ismaintanace = 0 THEN sc.score 
								  END < 60 THEN ( dSCol.colname + '-' + dcolcal.calctype ) 
							 ELSE 
							   CASE 
								 WHEN CASE 
										WHEN Hdr.ismaintanace = 0 THEN sc.score 
									  END < 3600 THEN ( dSCol.colname + '-' + dcolcal.calctype ) 
								 ELSE 
								   CASE 
									 WHEN CASE 
											WHEN Hdr.ismaintanace = 0 THEN sc.score 
										  END >= 3600 THEN ( 
									 dSCol.colname + '-' + dcolcal.calctype ) 
									 ELSE ( dSCol.colname + '-' + dcolcal.calctype ) 
								   END 
							   END 
						   END 
						 ELSE ( dSCol.colname + '-' + dcolcal.calctype ) 
					   END                                          ColumnMeasure, 
					   dset.setcd                                   SetName, 
					   CASE 
						 WHEN Hdr.ismaintanace = 1 THEN 'Yes' 
						 ELSE 'No' 
					   END                                          AS IsSetInMNT, 
					   look.lookupname                              AS Prompt, 
					   CASE 
						 WHEN DHDR.skilltype = 'Chained' 
							  AND DHDR.chaintype = 'Total Task' THEN 'Total Task' 
						 ELSE 
						   CASE 
							 WHEN DHDR.skilltype = 'Chained' 
								  AND DHDR.chaintype = 'Forward chain' THEN 
							 CONVERT(CHAR, Hdr.currentstepid) 
							 ELSE 
							   CASE 
								 WHEN DHDR.skilltype = 'Chained' 
									  AND DHDR.chaintype = 'Backward chain' THEN 
								 CONVERT(CHAR, Hdr.currentstepid) 
								 ELSE 
								   CASE 
									 WHEN DHDR.skilltype = 'Discrete' THEN 'Discrete' 
									 ELSE 'None' 
								   END 
							   END 
						   END 
					   END                                          AS Step, 
					   CASE 
						 WHEN hdr.ioaind = 'Y' THEN 'Yes' 
						 ELSE 'No' 
					   END                                          AS IOA, 
					   CASE 
						 WHEN hdr.sessmisstrailstus = 'Y' THEN 'Yes' 
						 ELSE 'No' 
					   END                                          AS Mistrial, 
					   hdr.SessMissTrailRsn AS MistrialRsn, 
					   CASE 
						 WHEN hdr.sessmisstrailstus = 'Y' THEN '' 
						 ELSE
						CASE 
						 WHEN Charindex('-', sc.score) > 0 THEN 'NA' 
						 ELSE 
						   CASE 
							 WHEN calctype IN ( 'Avg Duration', 'Total Duration' ) THEN 
							   CASE 
				   
								 WHEN sc.score >= 0 THEN
								 CASE WHEN @timestatbit = 0 THEN
											RIGHT('0' + CAST(CAST(sc.score AS INT) / 3600 AS VARCHAR), 2) + ':' +
											RIGHT('0' + CAST((CAST(sc.score AS INT) % 3600) / 60 AS VARCHAR), 2) + ':' +
											RIGHT('0' + CAST(CAST(sc.score AS INT) % 60 AS VARCHAR), 2)
									 
									 WHEN @timestatbit = 1 THEN CONVERT(VARCHAR(50), Round(( CASE WHEN sc.score >= 0 THEN sc.score END / 60 ), 2)) 
					
																					 
					   
							   
			  
				
					
																								   
										  --ELSE CONVERT(VARCHAR(50), Round(( CASE WHEN sc.score >= 0 THEN sc.score END / 3600 ), 2)) 
					  
																						  
						 
																			  
			   
				 
										  ELSE CONVERT(VARCHAR(50),sc.score)
										END
									END
			  
							 ELSE 
							   CASE 
								 WHEN sc.score >= 0 THEN CONVERT(VARCHAR(50), sc.score) 
							   END 
						   END 
						END   
						END                                          AS score, 
					   (SELECT Stuff((SELECT ',' + CONVERT(NVARCHAR(max), eventname) 
									  FROM   (SELECT [eventname] 
											  FROM   stdtsessevent 
											  WHERE  lessonplanid = hdr.lessonplanid 
													 AND hdr.sessionnbr = sessionnbr 
													 AND @StartDate <= evntts 
													 AND evntts <= @EndDate 
													 AND eventtype = 'EV' 
													 AND StudentId=@Studentid
													 AND discardstatus is NULL
													 AND EventName is not null
													 AND stdtsesseventtype IN ( 
														 'Major', 'Minor', 'Arrow notes' 
																			  )) 
											 EventName 
									  FOR xml path('')), 1, 1, '')) AS EventName, 
					   CASE 
						 WHEN (SELECT Count(stdtsesseventid) 
							   FROM   stdtsessevent 
							   WHERE  stdtsesseventtype = 'Major' 
									  AND sessionnbr = hdr.sessionnbr 
									  AND discardstatus is null
									  AND EventName is not null
									  AND StudentId=@Studentid
									  AND lessonplanid = hdr.lessonplanid) > 0 THEN 'Major' 
						 ELSE 
						   CASE 
							 WHEN (SELECT Count(stdtsesseventid) 
								   FROM   stdtsessevent 
								   WHERE  stdtsesseventtype = 'Minor' 
										  AND sessionnbr = hdr.sessionnbr 
										   AND discardstatus is null
										   AND EventName is not null
										   AND StudentId=@Studentid
										  AND lessonplanid = hdr.lessonplanid) > 0 THEN 'Minor' 
						   END 
					   END                                          AS StdtSessEventType, 
					   (SELECT CASE 
								 WHEN residenceind = 0 THEN 'DAY' 
								 ELSE 'RES' 
							   END 
						FROM   class 
						WHERE  classid = hdr.stdtclassid)           AS ClassType,
						CONCAT(usr.UserFname,', '+usr.UserLName) AS username 
				FROM   stdtsesscolscore sc 
					   INNER JOIN stdtsessionhdr hdr 
							   ON sc.stdtsessionhdrid = hdr.stdtsessionhdrid 
					   LEFT JOIN dstempsetcolcalc dcolcal 
							  ON sc.dstempsetcolcalcid = dcolcal.dstempsetcolcalcid 
					   LEFT JOIN dstempsetcol dSCol 
							  ON dSCol.dstempsetcolid = dcolcal.dstempsetcolid 
					   INNER JOIN dstempset dset 
							   ON hdr.currentsetid = dset.dstempsetid 
					   LEFT JOIN lookup look 
							  ON look.lookupid = hdr.currentpromptid 
					   INNER JOIN [dstemphdr] DHDR 
							   ON ( DHDR.dstemphdrid = hdr.dstemphdrid 
									AND DHDR.studentid = Hdr.studentid ) 
					   LEFT JOIN stdtsessevent sv 
							  ON ( hdr.studentid = sv.studentid 
								   AND hdr.dstemphdrid = sv.dstemphdrid 
								   AND hdr.sessionnbr = sv.sessionnbr ) 
					   INNER JOIN @TempLESSON TEMP 
							   ON TEMP.lessonplanid = DHDR.lessonplanid 
					   INNER JOIN class C 
							   ON C.classid = hdr.stdtclassid
					  INNER JOIN [User] usr
								ON sc.CreatedBy = usr.UserId  
				WHERE  hdr.studentid = @Studentid 
					   AND hdr.lessonplanid = @LessonPlanId 
					   AND CONVERT(DATE, hdr.endts) >= @StartDate 
					   AND CONVERT(DATE, hdr.endts) <= @ENDDate 
					   AND sv.discardstatus IS NULL
					   AND C.residenceind IN (SELECT data 
											  FROM   Split(@ClassTypeFlag, ',')) 
				GROUP  BY TEMP.lessonname, 
						  Hdr.sessionnbr, 
						  Hdr.stdtsessionhdrid, 
						  Hdr.endts, 
						  dSCol.colname, 
						  dcolcal.calctype, 
						  dset.setcd, 
						  Hdr.ismaintanace, 
						  look.lookupname, 
						  DHDR.skilltype, 
						  DHDR.chaintype, 
						  Hdr.currentstepid, 
						  hdr.ioaind, 
						  hdr.sessmisstrailstus, 
						  hdr.SessMissTrailRsn,
						  sc.score, 
						  hdr.lessonplanid, 
						  hdr.stdtclassid,usr.UserFname,usr.UserLName  
				ORDER  BY Hdr.sessionnbr 
  END

      ----------------------IOA%----------------------
      DECLARE @TEMPIOA TABLE
        (
           id               INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
           lessonplanid     INT,
           ioaperc          INT,
           stdtsessionhdrid INT,
           ioasessionhdrid  INT
        )

      INSERT INTO @TEMPIOA
      SELECT lessonplanid,
             CONVERT(VARCHAR(50), Round(ioaperc, 0)),
             stdtsessionhdrid,
             ioasessionhdrid
      FROM   stdtsessionhdr hdr INNER JOIN Class C
								ON C.ClassId = hdr.StdtClassId
      WHERE  studentid = @Studentid
             AND lessonplanid = @LessonPlanId
             AND endts >= @StartDate
             AND endts <= @ENDDate
             AND ioaperc IS NOT NULL
			 AND C.residenceind IN (SELECT data
								    FROM   Split(@ClassTypeFlag, ','))
      ORDER  BY lessonplanid,
                stdtsessionhdrid

      DECLARE @CNT       INT,
              @TotalCNT  INT,
              @LPid      INT,
              @HdrId     INT,
              @IOAHdrId  INT,
              @IOAPer    INT,
              @EventName VARCHAR(100)

      SET @CNT=1
      SET @TotalCNT=(SELECT Count(*)
                     FROM   @TEMPIOA)

      WHILE( @TotalCNT > 0 )
        BEGIN
            --SET @LPid =(SELECT LessonPlanId FROM #TEMPIOA WHERE ID=@CNT)
            --SET @HdrId =(SELECT StdtSessionHdrId FROM #TEMPIOA WHERE ID=@CNT)
            --SET @IOAHdrId=(SELECT IOASessionHdrId FROM #TEMPIOA WHERE ID=@CNT)
            --SET @IOAPer =(SELECT IOAPerc FROM #TEMPIOA WHERE ID=@CNT)
            SELECT @LPid = lessonplanid,
                   @HdrId = stdtsessionhdrid,
                   @IOAHdrId = ioasessionhdrid,
                   @IOAPer = ioaperc
            FROM   @TEMPIOA
            WHERE  id = @CNT

            UPDATE #raw
            SET    eventname = CONVERT(VARCHAR(50), @IOAPer) + '% '
                               + (SELECT Rtrim(Ltrim(Upper(US.userinitial))) AS
                                         IOALUser
                                  FROM   stdtsessionhdr HDR
                                         INNER JOIN [user] US
                                                 ON HDR.ioauserid = US.userid
                                  WHERE  stdtsessionhdrid = @IOAHdrId
                                         AND ioaind = 'N'
                                         AND lessonplanid = @LPid)
                               + '/'
                               + (SELECT Rtrim(Ltrim(Upper(US.userinitial))) AS
                                         NormalLUser
                                  FROM   stdtsessionhdr HDR
                                         INNER JOIN [user] US
                                                 ON HDR.ioauserid = US.userid
                                  WHERE  stdtsessionhdrid = @HdrId
                                         AND ioaind = 'Y'
                                         AND lessonplanid = @LPid),
                   eventtype = 'Arrow notes'
            WHERE  stdtsessionhdrid = @HdrId

            SET @CNT=@CNT + 1
            SET @TotalCNT=@TotalCNT - 1
        END

      --DROP TABLE #TEMPIOA
      ----------------LP modified and arrow notes----------------
      DECLARE @TEMPEvent TABLE
        (
           id              INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
           lessonplanid    INT,
           stdtsesseventid INT,
           evntts          DATETIME,
           ename           NVARCHAR(max),
           etype           VARCHAR(50)
        )

      INSERT INTO @TEMPEvent
      SELECT lessonplanid,
             stdtsesseventid,
             evntts,
             eventname,
             stdtsesseventtype
      FROM   stdtsessevent stdevnt INNER JOIN Class C 
								ON C.ClassId = stdevnt.ClassId 
      WHERE  studentid = @Studentid
             AND lessonplanid IN ( @LessonPlanId, 0 )
             AND evntts >= @StartDate
             AND evntts <= @ENDDate
			 AND stdevnt.discardstatus is NULL
             AND ( dstemphdrid IS NULL
                    OR eventname = 'LP modified' )
             AND eventtype = 'EV'
			 AND C.residenceind IN (SELECT data
								    FROM   Split(@ClassTypeFlag, ','))  
      ORDER  BY stdtsesseventid

      DECLARE @SessEventId INT,
              @LName       VARCHAR(150),
              @EType       VARCHAR(50)

      SET @CNT=1
      SET @TotalCNT=(SELECT Count(id)
                     FROM   @TEMPEvent)

      WHILE( @TotalCNT > 0 )
        BEGIN
            --SET @LPid =(SELECT LessonPlanId FROM #TEMPEvent WHERE ID=@CNT)
            --SET @SessEventId = (SELECT StdtSessEventId FROM #TEMPEvent WHERE ID=@CNT)
            --SET @EventName = (SELECT EName FROM #TEMPEvent WHERE ID=@CNT)
            --SET @LName=(SELECT LessonName FROM #TempLESSON WHERE LessonPlanId=@LPid)
            --SET @EType=(SELECT EType FROM #TEMPEvent WHERE ID=@CNT)
            SELECT @LPid = lessonplanid,
                   @SessEventId = stdtsesseventid,
                   @EventName = ename,
                   @EType = etype
            FROM   @TEMPEvent
            WHERE  id = @CNT

            SET @LName=(SELECT lessonname
                        FROM   @TempLESSON
                        WHERE  lessonplanid = @LPid)

            INSERT INTO #raw
            SELECT @LName                           AS LessonName,
                   NULL                             AS StdtSessionHdrId,
                   (SELECT CONVERT(DATE, evntts)
                    FROM   @TEMPEvent
                    WHERE  id = @CNT)               AS SessDate,
                   Cast((SELECT evntts
                         FROM   @TEMPEvent
                         WHERE  id = @CNT) AS TIME) AS SessTime,
                   NULL                             AS SessNumber,
                   NULL                             AS columnMeasure,
                   NULL                             AS SetName,
                   NULL                             AS IsSetInMNT,
                   NULL                             AS Prompt,
                   NULL                             AS Step,
                   NULL                             AS IOA,
                   NULL                             AS Mistrial,
				   NULL                             AS MistrialRsn,
                   NULL                             AS Score,
                   (SELECT ename
                    FROM   @TEMPEvent
                    WHERE  id = @CNT)               AS EventName,
                   @EType                           AS EventType,
				   NULL								AS classtype,
				   NULL								AS username   

            SET @CNT=@CNT + 1
            SET @TotalCNT=@TotalCNT - 1
        END

      --DROP TABLE #TempLESSON
      --------------------END--------------------
      DECLARE @cols  AS NVARCHAR(max),
              @query AS NVARCHAR(max)

      CREATE TABLE #columns
        (
           dcol VARCHAR(max)
        )

      INSERT INTO #columns
                  (dcol)
      SELECT DISTINCT '[' + columnmeasure + ']'
      FROM   #raw
      WHERE  columnmeasure IS NOT NULL

      SELECT @cols = COALESCE(@cols + ',', '') + dcol
      FROM   #columns

      DROP TABLE #columns

      SELECT lessonname,
             stdtsessionhdrid,
             sessdate,
             CONVERT(VARCHAR(15), sesstime, 100)SessTime,
             sessnumber,
			 classtype,
             columnmeasure,
             setname,
             issetinmnt,
             prompt,
             step,
             ioa,
             mistrial,
			 mistrialrsn,
             score,
             eventname,
             eventtype,
			 username
      FROM   #raw
	  --WHERE sessnumber IS NOT NULL --Commented for LP Modified to show
      ORDER  BY sessdate,
                #raw.sesstime,
                sessnumber

      DROP TABLE #raw
  END 


GO
