USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[GetStudentEvents]    Script Date: 11/04/2024 6:49:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetStudentEvents] 
	@studentId INT,
    @startDate DATETIME,
    @endDate DATETIME
AS
BEGIN
	DECLARE @MeasurementId INT;
	DECLARE @Behaviour NVARCHAR(MAX);
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	CREATE TABLE #TempResult (
MeasurementId INT ,
BehaviourName NVARCHAR(MAX),
EventName NVARCHAR(MAX),
);
CREATE NONCLUSTERED INDEX idx_tmp_measurementid ON #TempResult(MeasurementId);
	DECLARE StudentCursor CURSOR FOR
	
    SELECT ISNULL(MeasurementId,0) FROM BehaviourDetails WHERE StudentId = @studentId AND ActiveInd = 'A';

    OPEN StudentCursor;

    FETCH NEXT FROM StudentCursor INTO @MeasurementId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
	SELECT TOP 1 @Behaviour= Behaviour FROM BehaviourDetails WHERE MeasurementId = @MeasurementId
	INSERT INTO #TempResult (MeasurementId,BehaviourName,EventName)
	select @MeasurementId, @Behaviour, STUFF((select '; ' + CONVERT(VARCHAR(50), outr.EvntTs,101)+','+ outr.eventname from
 ( SELECT * FROM (SELECT * FROM  ((SELECT  SE.MeasurementId, SE.StdtSessEventId,  SE.EventName, 
 SE.StdtSessEventType, CONVERT(CHAR(10), SE.EvntTs,101) AS EvntTs,   B.Behaviour FROM  [StdtSessEvent] SE 
 LEFT JOIN LessonPlan L ON SE.LessonPlanId = L.LessonPlanId LEFT JOIN BehaviourDetails B ON 
 B.MeasurementId=SE.MeasurementId WHERE EventType='EV' AND SE.StudentId=@studentId AND SE.StdtSessEventType<>'Medication') 
 UNION ALL (SELECT  BIOA.MeasurementId, NULL AS StdtSessEventId,  'IOA '+CONVERT(nvarchar,ROUND(IOAPerc,0),0)+'% '++
 CASE WHEN BIOA.normalbehaviorid IS NULL THEN ((SELECT      TOP 1     Rtrim(    Ltrim(Upper(   US.userinitial)))
 FROM behaviour BH INNER JOIN [user] US  ON BH.createdby = US.userid WHERE BH.createdon BETWEEN Dateadd(minute, -5,
 BIOA.createdon) AND BIOA.createdon ORDER BY BH.createdon DESC)+'/'+ (SELECT TOP 1 Rtrim(Ltrim(Upper(US.userinitial)))
 FROM behaviorioadetails BI INNER JOIN [user] US ON BI.createdby = US.userid WHERE BI.createdon=BIOA.createdon
 ORDER BY BI.createdon DESC) ) ELSE (( SELECT Rtrim(Ltrim(Upper(US.userinitial))) FROM behaviour BH 
 INNER JOIN [user] US ON BH.createdby = US.userid WHERE BIOA.normalbehaviorid=BH.behaviourid)+'/'+ 
 ( SELECT Rtrim( Ltrim(Upper(US.userinitial))) FROM behaviorioadetails BI INNER JOIN [user] US ON 
 BI.createdby = US.userid INNER JOIN behaviour BH ON BH.behaviourid=BI.normalbehaviorid WHERE 
 BIOA.normalbehaviorid=BH.behaviourid)) END  AS EventName, 'Arrow notes' AS StdtSessEventType,  
 CONVERT(CHAR(10), BIOA.CreatedOn,101) AS EvntTs,   BHD.Behaviour FROM BehaviorIOADetails BIOA 
 LEFT JOIN BehaviourDetails BHD ON BIOA.MeasurementId=BHD.MeasurementId WHERE BIOA.StudentId=@studentId 
 AND IOAPerc IS NOT NULL AND BIOA.ActiveInd='A') )IOA )   ad  WHERE  ( ( ad.behaviour IS  NULL  
 AND ad.measurementid = 0 )OR ad.behaviour = (SELECT TOP 1 behaviour FROM   behaviourdetails WHERE  
 measurementid = @MeasurementId) )  AND ad.stdtsesseventtype IN( 'Arrow notes' )  AND 
 CONVERT(DATE, ad.evntts) >=  @startDate AND 
 CONVERT(DATE, ad.evntts) <=  @endDate )outr 
 FOR XML PATH('')),1,1,'') eventname 
 
  FETCH NEXT FROM StudentCursor INTO  @MeasurementId;
END
CLOSE StudentCursor;
    DEALLOCATE StudentCursor;
	SELECT * FROM #TempResult
	drop TABLE #TempResult
END
