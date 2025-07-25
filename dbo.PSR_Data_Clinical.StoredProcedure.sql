USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[PSR_Data_Clinical]    Script Date: 7/4/2025 1:21:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


alter Procedure [dbo].[PSR_Data_Clinical]
@StartDate DATETIME,
@EndDate DATETIME,
@StudentId INT,
@SchoolId INT

As 
Begin

SET NOCOUNT ON;

DECLARE @CNT INT, @TotalCNT INT, @EventName NVARCHAR(MAx), @BehvId INT, @BehvName VARCHAR(100),	@EvntDate DATE,
			  @Inactivedate datetime
SET @EndDate=@EndDate+ '23:59:59.998'

IF OBJECT_ID('tempdb..#Raw') IS NOT NULL  
DROP TABLE #Raw

CREATE Table #Raw
(
	ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),
	MeasurementId INT,
	EvntDate Date,
	Behaviour VARCHAR(50),
	Name VARCHAR(50),
	Time TIME,
	Frequency INT,
	Duration VARCHAR(50),
	YesOrNo VARCHAR(15),
	EventName NVARCHAR(MAX),
	StdtSessEventType VARCHAR(50)
);

CREATE NONCLUSTERED INDEX IDX_Raw_MeasurementId 
ON #Raw(MeasurementId);

CREATE NONCLUSTERED INDEX IDX_Raw_EvntDate 
ON #Raw(EvntDate);

CREATE NONCLUSTERED INDEX IDX_Raw_Behaviour 
ON #Raw(Behaviour);

CREATE NONCLUSTERED INDEX IDX_Raw_Time 
ON #Raw(Time);

INSERT INTO #Raw
SELECT B.MeasurementId ,
       CONVERT(date,B.TimeOfEvent)AS EvntDate,
	   BD.Behaviour,
	   U.UserFName + ' ' + UserLName AS Name,
	   CAST(B.TimeOfEvent AS TIME)AS Time,
	   (SELECT Sum(B.FrequencyCount)) AS Frequency, 
       Sum(Cast(B.Duration AS float)) AS Duration, 
       (CASE WHEN B.YesOrNo = 1 THEN 'Yes' WHEN B.YesOrNo = 0 THEN 'No' ELSE '' END) AS YesOrNo,
	   NULL AS EventName, NULL AS StdtSessEventType
FROM Behaviour B INNER JOIN BehaviourDetails BD ON B.MeasurementId = BD.MeasurementId 
INNER JOIN [USER] U ON U.UserId=B.ObserverId
WHERE B.StudentId = @StudentId and BD.ActiveInd IN('A', 'N') AND BD.SchoolId=@SchoolId AND B.TimeOfEvent BETWEEN @StartDate AND @EndDate
GROUP BY B.TimeOfEvent, B.MeasurementId,BD.Behaviour, B.observerid,B.YesOrNo,UserFName,UserLName
ORDER BY EvntDate,MeasurementId,Time;

-----------------EVENTS-------------------
CREATE TABLE #EVNT (ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT, BehvName VARCHAR(100))

CREATE NONCLUSTERED INDEX IDX_EVNT_MeasurementId 
ON #EVNT(MeasurementId);

CREATE NONCLUSTERED INDEX IDX_EVNT_BehvName 
ON #EVNT(BehvName);

INSERT INTO #EVNT 
	SELECT MeasurementId,Behaviour FROM BehaviourDetails WHERE StudentId=@StudentId AND SchoolId=@SchoolId AND ActiveInd IN('A','N')

SET @CNT=1 
SET @TotalCNT=(SELECT COUNT(ID) FROM #EVNT)
WHILE(@TotalCNT>0)
BEGIN
	SELECT @BehvId = MeasurementId, @BehvName = BehvName FROM #EVNT WHERE ID=@CNT
		SET @Inactivedate=(SELECT InactiveEvent FROM behaviourdetails WHERE measurementid=@BehvId)
	  IF(@Inactivedate IS NOT NULL)
	  BEGIN
	INSERT INTO #Raw (MeasurementId,EvntDate,Behaviour,Name,Time,EventName,StdtSessEventType)
	SELECT @BehvId AS MeasurementId,
		CONVERT(DATE,E.EvntTs) AS EvntDate,
		@BehvName AS Behaviour,
		U.UserFName + ' ' + U.UserLName AS Name,		  	   
		CAST(E.EvntTs AS TIME)AS Time,
		E.EventName+' ' AS EventName,
		E.StdtSessEventType+' ' AS StdtSessEventType	
	FROM StdtSessEvent E 
	LEFT JOIN BehaviourDetails B ON E.MeasurementId=B.MeasurementId
	LEFT JOIN [User] U ON E.CreatedBy=U.UserId 
	WHERE E.StudentId=@StudentId AND E.SchoolId=@SchoolId AND E.EventType='EV' 
	AND E.discardstatus is NULL
	AND convert(date,E.evntts)<convert(date,@Inactivedate)  AND E.EvntTs BETWEEN @StartDate AND @EndDate
		AND E.StdtSessEventType IN ('Major','Minor','Arrow notes') AND E.MeasurementId IN (@BehvId,0)

	SET @CNT=@CNT+1
	END
	ELSE
	BEGIN
	INSERT INTO #Raw (MeasurementId,EvntDate,Behaviour,Name,Time,EventName,StdtSessEventType)
	SELECT @BehvId AS MeasurementId,
		CONVERT(DATE,E.EvntTs) AS EvntDate,
		@BehvName AS Behaviour,
		U.UserFName + ' ' + U.UserLName AS Name,		  	   
		CAST(E.EvntTs AS TIME)AS Time,
		E.EventName+' ' AS EventName,
		E.StdtSessEventType+' ' AS StdtSessEventType	
	FROM StdtSessEvent E 
	LEFT JOIN BehaviourDetails B ON E.MeasurementId=B.MeasurementId
	LEFT JOIN [User] U ON E.CreatedBy=U.UserId 
	WHERE E.StudentId=@StudentId AND E.SchoolId=@SchoolId AND E.EventType='EV' AND E.EvntTs BETWEEN @StartDate AND @EndDate
	AND E.discardstatus is NULL
	AND E.StdtSessEventType IN ('Major','Minor','Arrow notes') AND E.MeasurementId IN (@BehvId,0)

	SET @CNT=@CNT+1
	END
	SET @TotalCNT=@TotalCNT-1
END
DROP TABLE #EVNT

---------------IOA%-------------------
IF OBJECT_ID('tempdb..#IOAPERCE') IS NOT NULL  
DROP TABLE #IOAPERCE
CREATE TABLE #IOAPERCE(ID INT PRIMARY KEY NOT NULL IDENTITY(1,1),MeasurementId INT,BehaviorName VARCHAR(50), CreatedOn DATETIME,CreatedBy INT,IOA VARCHAR(50),NormalBehaviorId INT)

CREATE NONCLUSTERED INDEX IDX_IOAPERCE_MeasurementId 
ON #IOAPERCE(MeasurementId);

CREATE NONCLUSTERED INDEX IDX_IOAPERCE_BehaviorName 
ON #IOAPERCE(BehaviorName);

CREATE NONCLUSTERED INDEX IDX_IOAPERCE_CreatedOn 
ON #IOAPERCE(CreatedOn);

INSERT INTO #IOAPERCE SELECT I.MeasurementId, B.Behaviour, I.CreatedOn,I.CreatedBy, I.IOAPerc, I.NormalBehaviorId 
	FROM BehaviorIOADetails I LEFT JOIN BehaviourDetails B ON I.MeasurementId=B.MeasurementId
	WHERE I.IOAPerc IS NOT NULL AND I.StudentId=@StudentId AND CONVERT(DATE,I.CreatedOn) BETWEEN @StartDate AND @EndDate 
	ORDER BY MeasurementId
DECLARE @CREATD_BY VARCHAR(50), @CREATD_ON DATETIME, @Time DATETIME, @IOA VARCHAR(50), @NormalId INT

SET @TotalCNT= (SELECT COUNT(*) FROM #IOAPERCE)
SET @CNT=1
WHILE(@TotalCNT>=0)
BEGIN
	SELECT @BehvId = MeasurementId, @EvntDate = CONVERT(DATE,CreatedOn), @CREATD_BY=CreatedBy, @CREATD_ON=CreatedOn, @NormalId=NormalBehaviorId FROM #IOAPERCE WHERE ID=@CNT
	SET @Time=DATEADD(minute, -5, @CREATD_ON)
	SET @IOA= (SELECT IOA FROM #IOAPERCE WHERE MeasurementId=@BehvId AND CONVERT(DATE,CreatedOn)=@EvntDate AND ID=@CNT)

	IF(@NormalId IS NOT NULL)
	BEGIN
		UPDATE #IOAPERCE SET IOA='IOA '+CONVERT(NVARCHAR,ROUND(@IOA,0)) +'% '+ (SELECT RTRIM(LTRIM(UPPER(US.UserInitial))) FROM Behaviour B
			INNER JOIN [USER] US ON B.CreatedBy = US.UserId WHERE B.BehaviourId = @NormalId)+'/'
			+(SELECT TOP 1 RTRIM(LTRIM(UPPER(US.UserInitial))) FROM BehaviorIOADetails I 
			INNER JOIN [USER] US ON I.CreatedBy = US.UserId 
			WHERE I.NormalBehaviorId = @NormalId ORDER BY I.CreatedOn DESC) WHERE ID=@CNT
	END
	ELSE
	BEGIN
		UPDATE #IOAPERCE SET IOA='IOA '+CONVERT(NVARCHAR,ROUND(@IOA,0)) +'% '+ (SELECT TOP 1 RTRIM(LTRIM(UPPER(US.UserInitial))) FROM Behaviour B 
			INNER JOIN [USER] US ON B.CreatedBy = US.UserId WHERE B.CreatedOn >= @Time AND B.CreatedOn <=@CREATD_ON  ORDER BY B.CreatedOn DESC)+'/'
			+(SELECT TOP 1 RTRIM(LTRIM(UPPER(US.UserInitial))) FROM BehaviorIOADetails I 
			INNER JOIN [USER] US ON I.CreatedBy = US.UserId 
			WHERE I.CreatedOn=@CREATD_ON ORDER BY I.CreatedOn DESC) WHERE ID=@CNT
	END
	SET @TotalCNT=@TotalCNT-1
	SET @CNT=@CNT+1
END

INSERT INTO #Raw (MeasurementId, EvntDate, Behaviour, Time, EventName, StdtSessEventType) 
(SELECT MeasurementId,
	CONVERT(DATE,CreatedOn) AS EvntDate,
	BehaviorName,
	CAST(CreatedOn AS TIME)AS Time,
	IOA AS EventName,'
	Arrow notes' AS StdtSessEventType
FROM #IOAPERCE)

SELECT ID,MeasurementId, CONVERT(varchar,EvntDate,101) EvntDate, Behaviour, Name, CONVERT(varchar(15),CAST(TIME AS Time),100)AS Time, Frequency, Duration, YesOrNo, EventName, 
	StdtSessEventType FROM #Raw R
ORDER BY R.EvntDate,R.MeasurementId,R.Time

END






GO
