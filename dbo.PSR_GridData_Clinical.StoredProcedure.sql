USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[PSR_GridData_Clinical]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PSR_GridData_Clinical] @StartDate     DATETIME,
													  @EndDate       DATETIME,
													  @Studentid     INT,
													  @MeasurementId VARCHAR(100),
													  @TypeofClass   VARCHAR(50)
AS
  BEGIN
      SET nocount ON;
	  
	  DECLARE @StartDt DATETIME =@StartDate,
              @EndDt DATETIME =@EndDate,
              @Stdtid INT =@Studentid,
              @MesmentId VARCHAR(100) =@MeasurementId,
			  @TypeofCls VARCHAR(50) =@TypeofClass

      DECLARE @CNT           INT,
              @TotalCNT      INT,
              @EventName     NVARCHAR(max),
              @ClassTypeFlag VARCHAR(10),
			  @Inactivedate datetime


      IF( @TypeofCls = 'DAY' )
        BEGIN
            SET @ClassTypeFlag = '0'
        END
      ELSE IF ( @TypeofCls = 'RES' )
        BEGIN
            SET @ClassTypeFlag = '1'
        END
      ELSE
        BEGIN
            SET @ClassTypeFlag = '0,1'
        END

      SET @EndDt=@EndDt + ' 23:59:59.998'	 

	  PRINT @StartDt 
	  PRINT Convert(DATE,@StartDt)
	  PRINT @EndDt  
	  PRINT Convert(DATE,@EndDt)

      CREATE TABLE #raw
        (
           id            INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           measurementid INT,
           behaviorname  VARCHAR(100),
           behvdate      DATETIME,
           behvtime      DATETIME,
           username      VARCHAR(100),
           duration      VARCHAR(50),
           frequency     INT,
           yesorno       VARCHAR(10),
           eventname     NVARCHAR(max),
           eventtype     VARCHAR(50),
           classtype     VARCHAR(50),
        );

		---IOA TABLE----
		CREATE TABLE #ioaperc
        (
           id               INT PRIMARY KEY NOT NULL IDENTITY(1, 1),
           behaviour        VARCHAR(100),
           studentid        INT,
           createdon        DATE,
           createdby        INT,
           timeofevent      DATETIME,
           ioa              VARCHAR(50),
           normalbehaviorid INT,
           classid          INT
        )

		IF(@TypeofCls = 'DAY' or @TypeofCls = 'RES')
		BEGIN
				INSERT INTO #raw
				SELECT B.measurementid,
						null,
						B.timeofevent AS BehvDate,
						B.timeofevent AS BehvTime,						
						U.userfname + ' ' + U.userlname AS Username,
						null AS Duration,
						null AS Frequency,
						null AS YesOrNo,
						null AS EventName,
						null AS StdtSessEventType,
						--null AS ClassType
						(SELECT CASE
								WHEN residenceind = 0 THEN 'DAY'
								ELSE 'RES'
								END
						FROM   class
						WHERE  classid = B.classid) AS ClassType
				FROM   behaviour B
							INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
							INNER JOIN [user] U ON U.userid = B.observerid
							LEFT JOIN class C ON C.classid = B.classid
				WHERE B.StudentId = @Stdtid
						AND D.activeind IN( 'A', 'N' )
						AND B.timeofevent >= @StartDt
						AND B.timeofevent <= @EndDt
						AND B.measurementid = @MesmentId
						AND (C.residenceind IN (SELECT data
											   FROM Split(@ClassTypeFlag, ',')) OR C.ResidenceInd IS NULL)
				GROUP BY B.measurementid,
							D.behaviour,
							B.timeofevent,		 
							B.classid,
							U.userfname,
							U.userlname
				ORDER  BY B.measurementid,BehvDate,BehvTime


				UPDATE #raw
				SET behaviorname = D.behaviour,
					duration = (SELECT TOP 1 duration 
								FROM Behaviour 
								WHERE StudentId = @Stdtid AND MeasurementId = @MesmentId AND TimeOfEvent = behvtime AND TimeOfEvent = behvdate AND duration IS NOT NULL),
					frequency = (SELECT TOP 1 FrequencyCount 
								 FROM Behaviour 
								 WHERE StudentId = @Stdtid AND MeasurementId = @MesmentId AND TimeOfEvent = behvtime AND TimeOfEvent = behvdate AND FrequencyCount IS NOT NULL),
					yesorno = (SELECT TOP 1 YesOrNo
								FROM Behaviour 
								WHERE StudentId = @Stdtid AND MeasurementId = @MesmentId AND TimeOfEvent = behvtime AND TimeOfEvent = behvdate AND Yesorno IS NOT NULL)
					--classtype = (SELECT CASE
					--					WHEN residenceind = 0 THEN 'DAY'
					--					ELSE 'RES'
					--					END
					--			FROM   class
					--			WHERE  classid = B.classid) 
				FROM   behaviour B
							INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
							INNER JOIN [user] U ON U.userid = B.observerid
							LEFT JOIN class C ON C.classid = B.classid
				WHERE B.StudentId = @Stdtid 
						AND D.activeind IN( 'A', 'N' )
						AND B.timeofevent >= @StartDt
						AND B.timeofevent <= @EndDt
						AND B.measurementid = @MesmentId
						AND (C.residenceind IN (SELECT data 
											   FROM Split(@ClassTypeFlag, ',')) OR C.ResidenceInd IS NULL)


				  INSERT INTO #ioaperc
				  SELECT B.behaviour,
						 I.studentid,
						 I.createdon,
						 I.createdby,
						 I.timeofevent,
						 I.ioaperc,
						 I.normalbehaviorid,
						 I.classid
				  FROM   behaviorioadetails I
						 LEFT JOIN behaviourdetails B
								ON B.measurementid = I.measurementid
						 LEFT JOIN class C
								ON C.classid = I.classid
				  WHERE  I.studentid = @Stdtid
						 AND I.createdon >= @StartDt
						 AND I.createdon <= @EndDt
						 AND I.ioaperc IS NOT NULL
						 AND I.measurementid = @MesmentId
						 AND (C.residenceind IN (SELECT data
												FROM   Split(@ClassTypeFlag, ','))  OR C.ResidenceInd IS NULL)
				  ORDER  BY I.createdon
				  
		END
				
	    ELSE IF(@TypeofCls = 'DAY,RES')
		BEGIN
			    INSERT INTO #raw
				SELECT B.measurementid,
						null,
						B.timeofevent AS BehvDate,
						B.timeofevent AS BehvTime,						
						U.userfname + ' ' + U.userlname AS Username,
						null AS Duration,
						null AS Frequency,
						null AS YesOrNo,
						null AS EventName,
						null AS StdtSessEventType,
						--null AS ClassType
						(SELECT CASE
								WHEN residenceind = 0 THEN 'DAY'
								ELSE 'RES'
								END
						FROM   class
						WHERE  classid = B.classid) AS ClassType
				FROM   behaviour B
							INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
							INNER JOIN [user] U ON U.userid = B.observerid
							LEFT JOIN class C ON C.classid = B.classid
				WHERE B.StudentId = @Stdtid
						AND D.activeind IN( 'A', 'N' )
						AND B.timeofevent >= @StartDt
						AND B.timeofevent <= @EndDt
						AND B.measurementid = @MesmentId
						AND (C.residenceind IN (SELECT data 
											   FROM Split(@ClassTypeFlag, ',')) OR C.ResidenceInd IS NULL)
				GROUP BY B.measurementid,
							D.behaviour,
							B.timeofevent,		 
							B.classid,
							U.userfname,
							U.userlname
				ORDER  BY B.measurementid,BehvDate,BehvTime


				UPDATE #raw
				SET behaviorname = D.behaviour,
					duration = (SELECT TOP 1 duration 
								FROM Behaviour 
								WHERE StudentId = @Stdtid AND MeasurementId = @MesmentId AND TimeOfEvent = behvtime AND TimeOfEvent = behvdate AND duration IS NOT NULL),
					frequency = (SELECT TOP 1 FrequencyCount 
								 FROM Behaviour 
								 WHERE StudentId = @Stdtid AND MeasurementId = @MesmentId AND TimeOfEvent = behvtime AND TimeOfEvent = behvdate AND FrequencyCount IS NOT NULL),
					yesorno = (SELECT TOP 1 YesOrNo
								FROM Behaviour 
								WHERE StudentId = @Stdtid AND MeasurementId = @MesmentId AND TimeOfEvent = behvtime AND TimeOfEvent = behvdate AND Yesorno IS NOT NULL)
					--classtype = (SELECT CASE
					--					WHEN residenceind = 0 THEN 'DAY'
					--					ELSE 'RES'
					--					END
					--			FROM   class
					--			WHERE  classid = B.classid) 
				FROM   behaviour B
							INNER JOIN behaviourdetails D ON B.measurementid = D.measurementid
							INNER JOIN [user] U ON U.userid = B.observerid
							LEFT JOIN class C ON C.classid = B.classid
				WHERE B.StudentId = @Stdtid 
						AND D.activeind IN( 'A', 'N' )
						AND B.timeofevent >= @StartDt
						AND B.timeofevent <= @EndDt
						AND B.measurementid = @MesmentId
						AND (C.residenceind IN (SELECT data 
											   FROM Split(@ClassTypeFlag, ',')) OR C.ResidenceInd IS NULL)
				  INSERT INTO #ioaperc
				  SELECT B.behaviour,
						 I.studentid,
						 I.createdon,
						 I.createdby,
						 I.timeofevent,
						 I.ioaperc,
						 I.normalbehaviorid,
						 I.classid
				  FROM   behaviorioadetails I
						 LEFT JOIN behaviourdetails B
								ON B.measurementid = I.measurementid
						 LEFT JOIN class C
								ON C.classid = I.classid
				  WHERE  I.studentid = @Stdtid
						 AND I.createdon >= @StartDt
						 AND I.createdon <= @EndDt
						 AND I.ioaperc IS NOT NULL
						 AND I.measurementid = @MesmentId
				  ORDER  BY I.createdon
				  
		END

      ---------------EVENTS------------------- 

      	  SET @Inactivedate=(SELECT InactiveEvent FROM behaviourdetails WHERE measurementid=@MesmentId)
	  IF(@Inactivedate IS NOT NULL)
	  BEGIN
      INSERT INTO #raw
      SELECT @MesmentId,
             B.behaviour,
             E.evntts										 	   AS BehvDate,
             E.evntts						                       AS BehvTime, 
             U.userfname + ' ' + U.userlname                       AS Username,
             NULL                                                  AS Duration,
             NULL                                                  AS Frequency,
             NULL                                                  AS YesOrNo,
             E.eventname + ' '                                     AS EventName,
             E.stdtsesseventtype + ' '                             AS StdtSessEventType,
             (SELECT CASE
                       WHEN residenceind = 0 THEN 'DAY'
                       ELSE 'RES'
                     END
              FROM   class
              WHERE  classid = E.classid)                          AS ClassType
      FROM   stdtsessevent E
             LEFT JOIN behaviourdetails B
                    ON E.measurementid = B.measurementid
             LEFT JOIN [user] U
                    ON E.createdby = U.userid
             INNER JOIN class C
                     ON C.classid = E.classid
      WHERE  E.studentid = @Stdtid
             AND @StartDt <= E.evntts
             AND E.evntts <= @EndDt
			 AND convert(date,E.evntts)<convert(date,@Inactivedate) 
             AND E.eventtype = 'EV'
             AND E.stdtsesseventtype IN ( 'Major', 'Minor', 'Arrow notes' )
             AND E.measurementid IN ( @MesmentId, 0 )			 
             AND C.residenceind IN (SELECT data
                                    FROM   Split(@ClassTypeFlag, ','))


		  END

		  ELSE
	  BEGIN
      INSERT INTO #raw
      SELECT @MesmentId,
             B.behaviour,
             E.evntts										 	   AS BehvDate,
             E.evntts						                       AS BehvTime, 
             U.userfname + ' ' + U.userlname                       AS Username,
             NULL                                                  AS Duration,
             NULL                                                  AS Frequency,
             NULL                                                  AS YesOrNo,
             E.eventname + ' '                                     AS EventName,
             E.stdtsesseventtype + ' '                             AS StdtSessEventType,
             (SELECT CASE
                       WHEN residenceind = 0 THEN 'DAY'
                       ELSE 'RES'
                     END
              FROM   class
              WHERE  classid = E.classid)                          AS ClassType
      FROM   stdtsessevent E
             LEFT JOIN behaviourdetails B
                    ON E.measurementid = B.measurementid
             LEFT JOIN [user] U
                    ON E.createdby = U.userid
             INNER JOIN class C
                     ON C.classid = E.classid
      WHERE  E.studentid = @Stdtid
             AND @StartDt <= E.evntts
             AND E.evntts <= @EndDt
             AND E.eventtype = 'EV'
             AND E.stdtsesseventtype IN ( 'Major', 'Minor', 'Arrow notes' )
             AND E.measurementid IN ( @MesmentId, 0 )			 
             AND C.residenceind IN (SELECT data
                                    FROM   Split(@ClassTypeFlag, ','))

	   END
      -------------IOA%-------------------
	      
        
      DECLARE @IOA1      VARCHAR(50),
              @DATE      DATE,
              @NormalId  INT,
              @CREATD_ON DATETIME,
              @Time      DATETIME

      SET @TotalCNT= (SELECT Count(*)
                      FROM   #ioaperc)
      SET @CNT=1

      WHILE( @TotalCNT > 0 )
        BEGIN
            SET @DATE=(SELECT createdon
                       FROM   #ioaperc
                       WHERE  id = @CNT)
            SET @IOA1= (SELECT ioa
                        FROM   #ioaperc
                        WHERE  createdon = @DATE
                               AND id = @CNT)
            SET @NormalId = (SELECT normalbehaviorid
                             FROM   #ioaperc
                             WHERE  id = @CNT)

            IF( @NormalId IS NOT NULL )
              BEGIN
                  UPDATE #ioaperc
                  SET    ioa = 'IOA ' + CONVERT(NVARCHAR, Round(@IOA1, 0))
                               + '% '
                               + (SELECT Rtrim(Ltrim(Upper(U.userinitial)))
                                  FROM   behaviour B
                                         INNER JOIN [user] U
                                                 ON B.createdby = U.userid
                                  WHERE  B.behaviourid = @NormalId)
                               + '/'
                               + (SELECT TOP 1
                                 Rtrim(Ltrim(Upper(U.userinitial)))
                                  FROM   behaviorioadetails I
                                         INNER JOIN [user] U
                                                 ON I.createdby = U.userid
                                  WHERE  I.normalbehaviorid = @NormalId
                                  ORDER  BY I.createdon DESC)
                  WHERE  id = @CNT
              END
            ELSE
              BEGIN
                  SET @CREATD_ON=(SELECT createdon
                                  FROM   #ioaperc
                                  WHERE  id = @CNT)
                  SET @Time=Dateadd(minute, -5, @CREATD_ON)

                  UPDATE #ioaperc
                  SET    ioa = 'IOA ' + CONVERT(NVARCHAR, Round(@IOA1, 0))
                               + '% '
                               + (SELECT TOP 1
                                 Rtrim(Ltrim(Upper(U.userinitial)))
                                  FROM   behaviour B
                                         INNER JOIN [user] U
                                                 ON B.createdby = U.userid
                                  WHERE  B.createdon >= @Time
                                         AND B.createdon <= @CREATD_ON
                                  ORDER  BY B.createdon DESC)
                               + '/'
                               + (SELECT TOP 1
                                 Rtrim(Ltrim(Upper(U.userinitial)))
                                  FROM   behaviorioadetails I
                                         INNER JOIN [user] U
                                                 ON I.createdby = U.userid
                                  WHERE  I.createdon = @CREATD_ON
                                  ORDER  BY I.createdon DESC)
                  WHERE  id = @CNT
              END

            SET @TotalCNT=@TotalCNT - 1
            SET @CNT=@CNT + 1
        END

		  INSERT INTO #raw
		  SELECT @MesmentId,
				 P.behaviour,
				 P.createdon,
				 P.timeofevent  					AS BehvTime,
				 U.userfname + ' ' + U.userlname    AS Username,
				 NULL                               AS Duration,
				 NULL                               AS Frequency,
				 NULL                               AS YesOrNo,
				 P.ioa								AS EventName,
				 'Arrow notes'                      AS StdtSessEventType,
				 (SELECT CASE
						   WHEN residenceind = 0 THEN 'DAY'
						   ELSE 'RES'
						 END
				  FROM   class
				  WHERE  classid = P.classid)       AS ClassType
		  FROM   #ioaperc P
				 LEFT JOIN [user] U
						ON P.createdby = U.userid
		  WHERE  studentid = @Stdtid

		  DROP TABLE #ioaperc

    
		  SELECT CONVERT(DATE, behvdate) AS Behvdate,      
				 CONVERT(VARCHAR(15), CAST (behvtime AS TIME), 100) AS Behvtime,      
				 username,     
				 duration,       
				 frequency,      
				 yesorno,     
				 eventname,      
				 eventtype,      
				 classtype
		  FROM   #raw
		  ORDER  BY measurementid,
					behvdate,
					#raw.behvtime

  END 
GO
