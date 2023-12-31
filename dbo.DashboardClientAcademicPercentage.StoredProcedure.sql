USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[DashboardClientAcademicPercentage]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROCEDURE [dbo].[DashboardClientAcademicPercentage] @ParamClassid VARCHAR(MAX) = NULL,
												@ParamStudid VARCHAR(MAX) = NULL
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @SetClassids VARCHAR(MAX),
			@SetStudids	VARCHAR(MAX)
	SET @SetClassids = @ParamClassid
	SET @SetStudids = @ParamStudid

	DECLARE @DateToday VARCHAR(300) = (SELECT CONVERT(VARCHAR(10), GETDATE(), 120))

	--[ Inserting Classids Into Table ]--
	DECLARE @ClassSplt TABLE 
	( 
		data INT 
	) 
	INSERT INTO @ClassSplt 
	SELECT * 
	FROM Split(@SetClassids, ',') 
	OPTION (MAXRECURSION 5000)

	--SELECT data FROM @ClassSplt


	--[ Inserting Studentids Into Table ]--
	DECLARE @StudSplt TABLE 
	( 
		data INT 
	) 
	INSERT INTO @StudSplt 
	SELECT * 
	FROM Split(@SetStudids, ',')
	OPTION (MAXRECURSION 5000) 

	--SELECT data FROM @StudSplt



	IF(@SetClassids IS NOT NULL AND @SetStudids IS NOT NULL)
	BEGIN
		-- [PRINT 'Class and Stuid'] --
		SELECT  shd.lessonplanid AS LessonPlanId,
				(SELECT CASE
					WHEN Count(shd.SessionNbr) <= 4 THEN  (SELECT SUBSTRING(lessonplanname, 1, 8) From lessonplan where lessonplanid = shd.lessonplanid )
					ELSE (SELECT lessonplanname From lessonplan where lessonplanid = shd.lessonplanid )
				END) AS LessonName,
				Count(DISTINCT shd.lessonplanid) AS LessonCount,
				Count(shd.SessionNbr) AS SessionCount,
				(SELECT lessonplanname From lessonplan where lessonplanid = shd.lessonplanid ) AS LessonNameToolTip,
				shd.StdtClassId,
				shd.studentid AS StudentID,
				(SELECT CONCAT(lastname,+', '+FirstName) FROM StudentPersonal WHERE StudentPersonalID = studentid) AS StudentName,
				(SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday)) AS LessonsCompleted,
				(SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) AS LessonScheduled,
				(SELECT (CASE WHEN ((SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) >= (SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday))) THEN Isnull
						(CASE WHEN (SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) <> 0 THEN (CONVERT(VARCHAR(50), Round((CONVERT(FLOAT, (SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday))) / CONVERT(FLOAT, (SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ))) * 100, 0)))
							END, 0) 
						ELSE 0 
					END) FROM Stdtsessionhdr WHERE Studentid = Shd.StudentId AND CONVERT(VARCHAR(10), Modifiedon, 120) = @DateToday GROUP BY Studentid) AS Percentage
		FROM   stdtsessionhdr shd
		WHERE  studentid IN(select stdtid from stdtclass where stdtid IN (SELECT data FROM @StudSplt) and classid IN (SELECT data FROM @ClassSplt) and ActiveInd = 'A') 
				AND CONVERT(VARCHAR(10), createdon, 120) = @DateToday
				AND [sessionstatuscd] = 'S'
				AND StdtClassId IN (SELECT data FROM @ClassSplt)
		GROUP BY shd.studentid,shd.StdtClassId,shd.LessonPlanId
		ORDER BY StudentName
	END
	ELSE IF(@SetClassids IS NOT NULL AND @SetStudids IS NULL)
	BEGIN
		-- [PRINT 'Only clasid'] --
		SELECT  shd.lessonplanid AS LessonPlanId,
				(SELECT CASE
					WHEN Count(shd.SessionNbr) <= 4 THEN  (SELECT SUBSTRING(lessonplanname, 1, 8) From lessonplan where lessonplanid = shd.lessonplanid )
					ELSE (SELECT lessonplanname From lessonplan where lessonplanid = shd.lessonplanid )
				END) AS LessonName,
				Count(DISTINCT shd.lessonplanid) AS LessonCount,
				Count(shd.SessionNbr) AS SessionCount,
				(SELECT lessonplanname From lessonplan where lessonplanid = shd.lessonplanid ) AS LessonNameToolTip,
				shd.StdtClassId,
				shd.studentid AS StudentID,
				(SELECT CONCAT(lastname,+', '+FirstName) FROM StudentPersonal WHERE StudentPersonalID = studentid) AS StudentName,
				(SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday)) AS LessonsCompleted,
				(SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) AS LessonScheduled,
				(SELECT (CASE WHEN ((SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) >= (SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday))) THEN Isnull
						(CASE WHEN (SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) <> 0 THEN (CONVERT(VARCHAR(50), Round((CONVERT(FLOAT, (SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday))) / CONVERT(FLOAT, (SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ))) * 100, 0)))
							END, 0) 
						ELSE 0 
					END) FROM Stdtsessionhdr WHERE Studentid = Shd.StudentId AND CONVERT(VARCHAR(10), Modifiedon, 120) = @DateToday GROUP BY Studentid) AS Percentage
		FROM   stdtsessionhdr shd
		WHERE  studentid IN(select stdtid from stdtclass where classid IN (SELECT data FROM @ClassSplt) and ActiveInd = 'A') 
				AND CONVERT(VARCHAR(10), createdon, 120) = @DateToday
				AND [sessionstatuscd] = 'S'
				AND StdtClassId IN (SELECT data FROM @ClassSplt)
		GROUP BY shd.studentid,shd.StdtClassId,shd.LessonPlanId
		ORDER BY StudentName
	END
	ELSE
	BEGIN
		-- [PRINT 'Only Studid'] --
		SELECT  shd.lessonplanid AS LessonPlanId,
				(SELECT CASE
					WHEN Count(shd.SessionNbr) <= 4 THEN  (SELECT SUBSTRING(lessonplanname, 1, 8) From lessonplan where lessonplanid = shd.lessonplanid )
					ELSE (SELECT lessonplanname From lessonplan where lessonplanid = shd.lessonplanid )
				END) AS LessonName,
				Count(DISTINCT shd.lessonplanid) AS LessonCount,
				Count(shd.SessionNbr) AS SessionCount,
				(SELECT lessonplanname From lessonplan where lessonplanid = shd.lessonplanid ) AS LessonNameToolTip,
				shd.StdtClassId,
				shd.studentid AS StudentID,
				(SELECT CONCAT(lastname,+', '+FirstName) FROM StudentPersonal WHERE StudentPersonalID = studentid) AS StudentName,
				(SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday)) AS LessonsCompleted,
				(SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) AS LessonScheduled,
				(SELECT (CASE WHEN ((SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) >= (SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday))) THEN Isnull
						(CASE WHEN (SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ) <> 0 THEN (CONVERT(VARCHAR(50), Round((CONVERT(FLOAT, (SELECT COUNT(DISTINCT LessonPlanId) FROM StdtSessionHdr WHERE StudentId = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday AND SessionStatusCd = 'S' AND LessonPlanId IN(SELECT DISTINCT LPId FROM StdtLPSched where Stdtid = Shd.StudentId AND CONVERT(VARCHAR(10), CreatedOn, 120) = @DateToday))) / CONVERT(FLOAT, (SELECT COUNT(DISTINCT LPId) FROM  StdtLPSched AS SCH WHERE (Day = @DateToday) AND StdtId= Shd.StudentId ))) * 100, 0)))
							END, 0) 
						ELSE 0 
					END) FROM Stdtsessionhdr WHERE Studentid = Shd.StudentId AND CONVERT(VARCHAR(10), Modifiedon, 120) = @DateToday GROUP BY Studentid) AS Percentage
		FROM   stdtsessionhdr shd
		WHERE  studentid IN(select stdtid from stdtclass where stdtid IN (SELECT data FROM @StudSplt) and ActiveInd = 'A') 
				AND CONVERT(VARCHAR(10), createdon, 120) = @DateToday
				AND [sessionstatuscd] = 'S'
		GROUP BY shd.studentid,shd.StdtClassId,shd.LessonPlanId
		ORDER BY StudentName
	END

END

GO
