USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[BiweeklyExcelView]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[BiweeklyExcelView]
@StartDate datetime,
@ENDDate datetime,
@Studentid int,
@SchoolId int,
@ShowLessonBehavior varchar(5),
@FilterColumn BIT

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @TempStartDate datetime
	SET @TempStartDate=@StartDate
	DECLARE @TempENDDate datetime
	SET @TempENDDate=@ENDDate
	DECLARE @TempStudentid int
	SET @TempStudentid=@Studentid
	DECLARE @TempSchoolId int
	SET @TempSchoolId=@SchoolId
	DECLARE @TempShowLessonBehavior varchar(5)
	SET @TempShowLessonBehavior=@ShowLessonBehavior


	DECLARE @ColumDisplay BIT
	SET @ColumDisplay = @FilterColumn

	SET @TempENDDate=@TempENDDate+' 23:59:58.998'

CREATE TABLE #TempScores (
    FinalScore DECIMAL(10, 2),
    CalcID INT,
	CalcType VARCHAR(500),
	studid  int,
	classid int,
    EndDate DATE,
	lessonid int,
	schoolid int
);
	CREATE NONCLUSTERED INDEX IX_CalcID ON #TempScores (CalcID);
	CREATE NONCLUSTERED INDEX IX_CalcType ON #TempScores (CalcType);
	CREATE NONCLUSTERED INDEX IX_studid ON #TempScores (studid);
	CREATE NONCLUSTERED INDEX IX_classid ON #TempScores (classid);
		CREATE NONCLUSTERED INDEX IX_EndDate ON #TempScores (EndDate);
		CREATE NONCLUSTERED INDEX IX_lessonid ON #TempScores (lessonid);
		CREATE NONCLUSTERED INDEX IX_schoolid ON #TempScores (schoolid);

INSERT INTO #TempScores (FinalScore, CalcID, CalcType, studid, classid, EndDate, lessonid, schoolid)
SELECT Distinct 
    CASE 
        WHEN ds.CalcType in ('Total Duration','Frequency','Total Correct','Total Incorrect') THEN SUM(sc.Score)
        ELSE AVG(sc.Score)
    END AS FinalScore,
    ds.DSTempSetColCalcId AS CalcID,
	ds.CalcType AS CalcType,
	hdr.StudentId AS studid,
	hdr.StdtClassId AS classid,
    CAST(hdr.EndTs AS DATE) AS EndDate, -- Extracting the date part from EndTs
	hdr.LessonPlanId AS lessonid,
	hdr.SchoolId AS schoolid
FROM 
    StdtSessColScore sc 
INNER JOIN DSTempSetColCalc ds ON sc.DSTempSetColCalcid = ds.DSTempSetColCalcId 
INNER JOIN StdtSessionHdr hdr ON hdr.StdtSessionHdrId = sc.StdtSessionHdrId 
JOIN Class Cls ON Cls.ClassId = hdr.StdtClassId
WHERE 
    hdr.IOAInd = 'N' 
    AND hdr.SessMissTrailStus = 'N' 
    AND hdr.SessionStatusCd = 'S' 
    AND sc.Score >= 0 
    AND hdr.IsMaintanace = 0 
    AND hdr.EndTs >= @TempStartDate 
    AND hdr.EndTs <= @TempENDDate 
    AND hdr.StudentId = @TempStudentid 
    AND hdr.SchoolId = @TempSchoolId 
GROUP BY 
    ds.DSTempSetColCalcId, 
    CAST(hdr.EndTs AS DATE),
	hdr.LessonPlanId,
    ds.CalcType,
	hdr.StudentId,
	hdr.StdtClassId,
	hdr.SchoolId;

CREATE TABLE #TempScoresbehav (
    measureid int,
	CalcType VARCHAR(500),
	studid  int,
    EndDate DATE,
	frequency float,
	duration float
);
	CREATE NONCLUSTERED INDEX IX_measureid ON #TempScoresbehav (measureid);
	CREATE NONCLUSTERED INDEX IX_CalcType ON #TempScoresbehav (CalcType);
	CREATE NONCLUSTERED INDEX IX_studid ON #TempScoresbehav (studid);
	CREATE NONCLUSTERED INDEX IX_EndDate ON #TempScoresbehav (EndDate);

	

INSERT INTO #TempScoresbehav (measureid,CalcType,studid, EndDate,frequency,duration)
SELECT Distinct 
   beh.MeasurementId as measureid
	,CASE 
    WHEN bd.PartialInterval = 1 AND bd.IfPerInterval = 1 THEN '%Interval'
    WHEN bd.PartialInterval = 1 AND bd.IfPerInterval = 0 THEN 'SumTotal'
    WHEN bd.Frequency = 1 OR bd.YesOrNo = 1 THEN 'Frequency'
    ELSE 'Duration' END AS CalcType,
   beh.StudentId as studid,
      CAST(beh.CreatedOn AS DATE) as EndDate,
   CASE WHEN bd.PartialInterval = 1 AND bd.IfPerInterval = 1 THEN
				(SUM(CASE WHEN beh.YesOrNo = 1 THEN beh.FrequencyCount ELSE 0 END)  /
				NULLIF(COUNT(CASE WHEN beh.YesOrNo IS NOT NULL THEN 1 END), 0)) * 100
				ELSE (SELECT SUM(beh.FrequencyCount))
				END AS frequency
				,(SELECT (SUM(CONVERT(float,beh.Duration)))/60 )AS duration

FROM 
    BehaviourDetails bd inner join Behaviour beh on bd.MeasurementId=beh.MeasurementId where beh.StudentId=@TempStudentid and beh.CreatedOn<=@TempENDDate and beh.CreatedOn>=@TempStartDate
GROUP BY 
    beh.MeasurementId, 
        CAST(beh.CreatedOn AS DATE),
	 bd.PartialInterval, 
	 bd.IfPerInterval,
	 bd.Frequency,
	 bd.YesOrNo,
	 beh.StudentId


	CREATE TABLE #Lesson(ID	int PRIMARY KEY NOT NULL IDENTITY(1,1)
	,ClassId INT
	,DSTempSetColCalcId INT
	,ColName varchar(150)
	,PeriodDate varchar(20)
	,LessonPlanId INT
	,LessonName varchar(150)
	,CalcType varchar(50)
	,Score float
	,Duration float
	,Frequency float
	,Interval float
	,IsLP varchar(3)
	,LessonOrder INT
	,SortDate DATETIME
	,IsDuration BIT
	,IsFrequency BIT
	,IsYesNo BIT);

	CREATE NONCLUSTERED INDEX IX_Lesson_ClassId ON #Lesson (ClassId);
	CREATE NONCLUSTERED INDEX IX_Lesson_PeriodDate ON #Lesson (PeriodDate);
	CREATE NONCLUSTERED INDEX IX_Lesson_LessonPlanId ON #Lesson (LessonPlanId);
	CREATE NONCLUSTERED INDEX IX_Lesson_SortDate ON #Lesson (SortDate);
	CREATE NONCLUSTERED INDEX IX_Lesson_DSTempSetColCalcId ON #Lesson (DSTempSetColCalcId);
		CREATE NONCLUSTERED INDEX IX_Lesson_LessonOrder ON #Lesson (LessonOrder);

	DECLARE @Approved INT,@Maintenance INT,@Inactive INT
	SELECT 
		@Approved=CASE WHEN LookupName='Approved' THEN LookupId ELSE @Approved END
		,@Maintenance=CASE WHEN LookupName='Maintenance' THEN LookupId ELSE @Maintenance END 
		,@Inactive=CASE WHEN LookupName='Inactive' THEN LookupId ELSE @Inactive END 
	FROM
	Lookup WHERE LookupType='TemplateStatus' AND LookupName IN('Approved','Maintenance','Inactive')

	IF (@ColumDisplay = 0)
	BEGIN
		
		If(@TempShowLessonBehavior LIKE '%1%')
		BEGIN
			INSERT INTO #Lesson(ClassId,DSTempSetColCalcId,ColName,PeriodDate,LessonPlanId,LessonName,CalcType,Score,IsLP,LessonOrder,SortDate)
				SELECT DISTINCT  StdtClassId AS ClassId
				,DSTempSetColCalcId
				,(SELECT ColName FROM DSTempSetCol WHERE DSTempSetColId=StdCalcs.DSTempSetColId) ColName
				,CONVERT(varchar,ReportPeriod.PeriodDate,101) AS PeriodDate
				,LessonPlanId
				,CASE WHEN EXISTS(SELECT DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Approved) THEN (SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Approved) 
			ELSE CASE WHEN EXISTS(SELECT DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Maintenance) THEN (SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Maintenance)
			ELSE CASE WHEN EXISTS(SELECT TOP 1 DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Inactive ORDER BY DSTempHdr.DSTempHdrId DESC) THEN (SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE DSTempHdr.LessonPlanId=StdCalcs.LessonPlanId AND DSTempHdr.StudentId=StdCalcs.StudentId AND StatusId=@Inactive ORDER BY DSTempHdr.DSTempHdrId DESC) END END END AS LessonName
				,CASE 
				WHEN CalcType IN ('Avg Duration', 'Total Duration') THEN
					CASE 
						WHEN StdCalcs.MaxDur IS NOT NULL THEN 
							CASE 
								WHEN StdCalcs.MaxDur < 60 THEN CalcType + ' (In Seconds)' 
								WHEN StdCalcs.MaxDur < 3600 THEN CalcType + ' (In Minutes)' 
								WHEN StdCalcs.MaxDur >= 3600 THEN CalcType + ' (In Hours)' 
								ELSE CalcType 
							END
						ELSE CalcType
					END
				ELSE CalcType
			END AS CalcType
				,(select top 1  FinalScore from #TempScores where  CalcID=StdCalcs.DSTempSetColCalcId and lessonid=StdCalcs.LessonPlanId and studid=StdCalcs.StudentId and  CONVERT(DATE,EndDate)=CONVERT(DATE,ReportPeriod.PeriodDate) and CalcType=StdCalcs.CalcType and schoolid=StdCalcs.SchoolId and classid=StdCalcs.StdtClassId )as score
				,'1' AS IsLP
				,(SELECT TOP 1 LessonOrder FROM DSTempHdr WHERE DSTempHdr.LessonPlanId=StdCalcs.LessonPlanId 
				AND DSTempHdr.StudentId=StdCalcs.Studentid ) LessonOrder
				,PeriodDate AS SortDate
					FROM (
				SELECT  
				sc.SchoolId
				,sc.StudentId
				,sc.DSTempSetColCalcId
				,dcal.CalcType 
				,dcal.DSTempSetColId
				,hdr.LessonPlanId
				,hdr.StdtClassId
				,Cls.ResidenceInd
				,(SELECT ROUND(MAX(Isc.Score),2) FROM StdtSessColScore  Isc
				INNER JOIN StdtSessionHdr IHdr ON IHdr.StdtSessionHdrId=Isc.StdtSessionHdrId
				INNER JOIN Class ICls ON ICls.ClassId=IHdr.StdtClassId
				JOIN DSTempSetColCalc Idcal
				ON Idcal.DSTempSetColCalcId = Isc.DSTempSetColCalcId WHERE Isc.SchoolId=sc.SchoolId AND Isc.StudentId=sc.StudentId
				AND Isc.DSTempSetColCalcId=sc.DSTempSetColCalcId 
				AND IHdr.LessonPlanId=hdr.LessonPlanId AND Idcal.CalcType=dcal.CalcType AND IHdr.StdtClassId=hdr.StdtClassId
				AND IHdr.IOAInd='N' AND IHdr.SessMissTrailStus ='N' AND IHdr.SessionStatusCd='S' AND Isc.Score>=0 AND IHdr.IsMaintanace=0
				AND @TempStartDate <= IHdr.EndTs AND 
			IHdr.EndTs <= @TempENDDate)	MaxDur	
				FROM StdtSessColScore  sc
				JOIN DSTempSetColCalc dcal
				ON dcal.DSTempSetColCalcId = sc.DSTempSetColCalcId
				JOIN StdtSessionHdr hdr 
				ON hdr.StdtSessionHdrId=sc.StdtSessionHdrId
				JOIN Class Cls ON Cls.ClassId=hdr.StdtClassId
				LEFT JOIN DSTempHdr dhdr ON dhdr.DSTempHdrId=hdr.DSTempHdrId
				LEFT JOIN LookUp lp ON lp.LookupId = dhdr.StatusId
				WHERE sc.SchoolId=@TempSchoolId AND sc.StudentId=@TempStudentid AND hdr.IOAInd='N' AND hdr.SessMissTrailStus ='N' AND hdr.SessionStatusCd='S' AND 
				hdr.LessonPlanId in(select distinct LessonPlanId from DSTempHdr where StudentId=@TempStudentid) AND
				lp.LookupType='TemplateStatus' AND lp.LookupName in('Approved','Inactive','Maintenance')
				GROUP BY 
				sc.SchoolId
				,sc.StudentId
				,sc.DSTempSetColCalcId
				,dcal.CalcType
				,dcal.DSTempSetColId
				,hdr.LessonPlanId
				,hdr.StdtClassId
				,Cls.ResidenceInd
					) AS StdCalcs
				,ReportPeriod
				WHERE @TempStartDate <= ReportPeriod.PeriodDate AND ReportPeriod.PeriodDate <= @TempENDDate
				GROUP BY 
				StdCalcs.SchoolId
				,StdCalcs.StudentId
				,StdCalcs.LessonPlanId
				,StdCalcs.DSTempSetColCalcId
				,StdCalcs.DSTempSetColId
				,ReportPeriod.PeriodDate
				,StdCalcs.CalcType
				,StdCalcs.StdtClassId 
				,StdCalcs.ResidenceInd
				,StdCalcs.MaxDur ;
		END


		
		If(@TempShowLessonBehavior LIKE '%0%')
		BEGIN
			INSERT INTO #Lesson(ClassId,PeriodDate,LessonPlanId,LessonName,CalcType,Duration,Frequency,Interval,IsLP,LessonOrder,SortDate,IsDuration,IsFrequency,IsYesNo)
				SELECT DISTINCT  FREQUENCY.ClassId ClassId
				,CONVERT(varchar, FREQUENCY.PeriodDate,101) PeriodDate
				,FREQUENCY.MeasurementId AS LessonPlanId
				,(SELECT Behaviour FROM BehaviourDetails WHERE MeasurementId=FREQUENCY.MeasurementId) LessonName
				,CalcType
				, ROUND(FREQUENCY.DurationMin,2)  AS Duration			
				,CASE WHEN CalcType='%Interval' THEN NULL ELSE ROUND(FREQUENCY.Frequncy,2) END AS Frequency
				,CASE WHEN CalcType='%Interval' THEN ROUND(FREQUENCY.Frequncy,2) ELSE NULL END AS Interval
				,'0' AS IsLP
				,'1000' AS LessonOrder
				,FREQUENCY.PeriodDate AS SortDate
				,FREQUENCY.IsDuration
				,FREQUENCY.IsFrequency
				,FREQUENCY.IsYesNo
				FROM(SELECT BEHAVIOR.ClassId
				,PeriodDate
				,BEHAVIOR.MeasurementId
				,(SELECT Behaviour FROM BehaviourDetails WHERE MeasurementId=BEHAVIOR.MeasurementId) LessonName
				,BEHAVIOR.Type CalcType
				,(SELECT TOP 1 frequency from #TempScoresbehav where measureid=BEHAVIOR.MeasurementId and Convert(DATE,EndDate)=Convert(DATE,BEHAVIOR.PeriodDate) ) as Frequncy,
				(SELECT TOP 1 duration from #TempScoresbehav where measureid=BEHAVIOR.MeasurementId and Convert(DATE,EndDate)=Convert(DATE,BEHAVIOR.PeriodDate) ) as DurationMin
				,ClassType
				,BEHAVIOR.IsFrequency AS IsFrequency
				,BEHAVIOR.IsDuration AS IsDuration
				,BEHAVIOR.IsYesNo AS IsYesNo
				FROM (
				SELECT ALLBEHAVIOR.ResidenceInd
				,ALLBEHAVIOR.PartialInterval
				,ALLBEHAVIOR.Period
				,ALLBEHAVIOR.NumOfTimes
				,ALLBEHAVIOR.ClassId
				,ALLBEHAVIOR.MeasurementId
				,ALLBEHAVIOR.PeriodDate
				,CASE WHEN ALLBEHAVIOR.ResidenceInd=1 
				THEN 'Residence' 
				ELSE 'Day' END ClassType
				,CASE 
    WHEN ALLBEHAVIOR.inter = 1 AND ALLBEHAVIOR.perinter = 1 THEN '%Interval'
    WHEN ALLBEHAVIOR.inter = 1 AND ALLBEHAVIOR.perinter = 0 THEN 'SumTotal'
    WHEN ALLBEHAVIOR.IsFrequency = 1 OR ALLBEHAVIOR.IsYesNo = 1 THEN 'Frequency'
    ELSE 'Duration'
	END AS Type
				,ALLBEHAVIOR.IsFrequency
				,ALLBEHAVIOR.IsDuration	
				,ALLBEHAVIOR.IsYesNo
				FROM (SELECT Behaviordata.ClassId
				,Behaviordata.MeasurementId
				,ReportPeriod.PeriodDate
				,Behaviordata.PartialInterval
				,Behaviordata.ResidenceInd
				,Behaviordata.Period
				,Behaviordata.NumOfTimes
				,Behaviordata.IsFrequency
				,Behaviordata.IsDuration	
				,Behaviordata.IsYesNo
				,Behaviordata.PartialInterval as inter
				,Behaviordata.IfPerInterval as perinter
				FROM
				(SELECT BDS.ClassId
				,BDS.MeasurementId
				,BDS.PartialInterval
				,Cls.ResidenceInd
				,BDS.Period,BDS.NumOfTimes
				,BDS.Frequency IsFrequency
				,BDS.Duration IsDuration
				,BDS.YesOrNo IsYesNo
				,BDS.IfPerInterval
				FROM BehaviourDetails BDS
				LEFT JOIN  Behaviour BR 
				ON BR.MeasurementId=BDS.MeasurementId 
				LEFT JOIN Class Cls 
				ON Cls.ClassId=BDS.ClassId 
				WHERE BDS.ActiveInd IN ('A', 'N') AND BDS.StudentId=@TempStudentid AND BDS.SchoolId=@TempSchoolId
				GROUP BY BDS.ClassId
				,BR.CreatedOn
				,BDS.MeasurementId
				,BDS.PartialInterval
				,Cls.ResidenceInd
				,BDS.Period
				,BDS.NumOfTimes
				,BDS.Frequency
				,BDS.Duration
				,BDS.YesOrNo 
				,BDS.IfPerInterval) AS Behaviordata,ReportPeriod
				WHERE @TempStartDate <= ReportPeriod.PeriodDate AND 
				ReportPeriod.PeriodDate <= @TempENDDate AND (Period <>0 OR Period IS NULL)) AS ALLBEHAVIOR) BEHAVIOR)FREQUENCY;
		END

		--SELECT ColName,PeriodDate,LessonPlanId,LessonName,CalcType
		--,CASE WHEN CHARINDEX('Minutes',CalcType)>0 THEN ROUND((Score/60),2)  ELSE CASE WHEN CHARINDEX('Hours',CalcType)>0 THEN ROUND((Score/3600),2)  ELSE Score END END Score
		--,Duration,Frequency,Interval,IsLP,IsDuration,IsFrequency,IsYesNo FROM #Lesson ORDER BY SortDate, LessonOrder

	END
	ELSE IF(@ColumDisplay = 1)
	BEGIN

		If(@TempShowLessonBehavior LIKE '%1%')
		BEGIN
			INSERT INTO #Lesson(ClassId,DSTempSetColCalcId,ColName,PeriodDate,LessonPlanId,LessonName,CalcType,Score,IsLP,LessonOrder,SortDate)
				SELECT DISTINCT  StdtClassId AS ClassId
				,DSTempSetColCalcId
				,(SELECT ColName FROM DSTempSetCol WHERE DSTempSetColId=StdCalcs.DSTempSetColId) ColName
				,CONVERT(varchar,ReportPeriod.PeriodDate,101) AS PeriodDate
				,LessonPlanId
				,CASE WHEN EXISTS(SELECT DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Approved) THEN (SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Approved) 
			ELSE CASE WHEN EXISTS(SELECT DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Maintenance) THEN (SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Maintenance)
			ELSE CASE WHEN EXISTS(SELECT TOP 1 DSTempHdrId FROM DSTempHdr WHERE LessonPlanId=StdCalcs.LessonPlanId AND StudentId=StdCalcs.StudentId AND StatusId=@Inactive ORDER BY DSTempHdr.DSTempHdrId DESC) THEN (SELECT TOP 1 DSTemplateName FROM DSTempHdr WHERE DSTempHdr.LessonPlanId=StdCalcs.LessonPlanId AND DSTempHdr.StudentId=StdCalcs.StudentId AND StatusId=@Inactive ORDER BY DSTempHdr.DSTempHdrId DESC) END END END AS LessonName
				,CASE 
    WHEN CalcType IN ('Avg Duration', 'Total Duration') THEN
        CASE 
            WHEN StdCalcs.MaxDur IS NOT NULL THEN 
                CASE 
                    WHEN StdCalcs.MaxDur < 60 THEN CalcType + ' (In Seconds)' 
                    WHEN StdCalcs.MaxDur < 3600 THEN CalcType + ' (In Minutes)' 
                    WHEN StdCalcs.MaxDur >= 3600 THEN CalcType + ' (In Hours)' 
                    ELSE CalcType 
                END
            ELSE CalcType
        END
    ELSE CalcType
END AS CalcType
				,(select   FinalScore from #TempScores where  CalcID=StdCalcs.DSTempSetColCalcId and lessonid=StdCalcs.LessonPlanId and studid=StdCalcs.StudentId and  CONVERT(DATE,EndDate)=CONVERT(DATE,ReportPeriod.PeriodDate) and CalcType=StdCalcs.CalcType and schoolid=StdCalcs.SchoolId and classid=StdCalcs.StdtClassId )as score
				
				,'1' AS IsLP
				,(SELECT TOP 1 LessonOrder FROM DSTempHdr WHERE DSTempHdr.LessonPlanId=StdCalcs.LessonPlanId 
				AND DSTempHdr.StudentId=StdCalcs.Studentid ) LessonOrder
				,PeriodDate AS SortDate
					FROM (
				SELECT  
				sc.SchoolId
				,sc.StudentId
				,sc.DSTempSetColCalcId
				,dcal.CalcType 
				,dcal.DSTempSetColId
				,hdr.LessonPlanId
				,hdr.StdtClassId
				,Cls.ResidenceInd
				,(SELECT ROUND(MAX(Isc.Score),2) FROM StdtSessColScore  Isc
				INNER JOIN StdtSessionHdr IHdr ON IHdr.StdtSessionHdrId=Isc.StdtSessionHdrId
				INNER JOIN Class ICls ON ICls.ClassId=IHdr.StdtClassId
				JOIN DSTempSetColCalc Idcal
				ON Idcal.DSTempSetColCalcId = Isc.DSTempSetColCalcId WHERE Isc.SchoolId=sc.SchoolId AND Isc.StudentId=sc.StudentId
				AND Isc.DSTempSetColCalcId=sc.DSTempSetColCalcId 
				AND IHdr.LessonPlanId=hdr.LessonPlanId AND Idcal.CalcType=dcal.CalcType AND IHdr.StdtClassId=hdr.StdtClassId
				AND IHdr.IOAInd='N' AND IHdr.SessMissTrailStus ='N' AND IHdr.SessionStatusCd='S' AND Isc.Score>=0 AND IHdr.IsMaintanace=0
				AND @TempStartDate <= IHdr.EndTs AND 
				IHdr.EndTs <= @TempENDDate)	MaxDur	
				FROM StdtSessColScore  sc
				JOIN DSTempSetColCalc dcal
				ON dcal.DSTempSetColCalcId = sc.DSTempSetColCalcId
				JOIN StdtSessionHdr hdr 
				ON hdr.StdtSessionHdrId=sc.StdtSessionHdrId
				JOIN Class Cls ON Cls.ClassId=hdr.StdtClassId
				LEFT JOIN DSTempHdr dhdr ON dhdr.DSTempHdrId=hdr.DSTempHdrId
				LEFT JOIN LookUp lp ON lp.LookupId = dhdr.StatusId
				WHERE sc.SchoolId=@TempSchoolId AND sc.StudentId=@TempStudentid AND hdr.IOAInd='N' AND hdr.SessMissTrailStus ='N' AND hdr.SessionStatusCd='S' AND 
				hdr.LessonPlanId in(select distinct LessonPlanId from DSTempHdr where StudentId=@TempStudentid) AND
				lp.LookupType='TemplateStatus' AND lp.LookupName in('Approved','Inactive','Maintenance') AND CONVERT(DATE, hdr.endts) >= @TempStartDate AND CONVERT(DATE, hdr.endts) <= @TempENDDate
				GROUP BY 
				sc.SchoolId
				,sc.StudentId
				,sc.DSTempSetColCalcId
				,dcal.CalcType
				,dcal.DSTempSetColId
				,hdr.LessonPlanId
				,hdr.StdtClassId
				,Cls.ResidenceInd
					) AS StdCalcs
				,ReportPeriod
				WHERE @TempStartDate <= ReportPeriod.PeriodDate AND ReportPeriod.PeriodDate <= @TempENDDate 
				GROUP BY 
				StdCalcs.SchoolId
				,StdCalcs.StudentId
				,StdCalcs.LessonPlanId
				,StdCalcs.DSTempSetColCalcId
				,StdCalcs.DSTempSetColId
				,ReportPeriod.PeriodDate
				,StdCalcs.CalcType
				,StdCalcs.StdtClassId 
				,StdCalcs.ResidenceInd
				,StdCalcs.MaxDur ;
		END

		If(@TempShowLessonBehavior LIKE '%0%')
		BEGIN
			INSERT INTO #Lesson(ClassId,PeriodDate,LessonPlanId,LessonName,CalcType,Duration,Frequency,Interval,IsLP,LessonOrder,SortDate,IsDuration,IsFrequency,IsYesNo)
				SELECT DISTINCT  FREQUENCY.ClassId ClassId
				,CONVERT(varchar, FREQUENCY.PeriodDate,101) PeriodDate
				,FREQUENCY.MeasurementId AS LessonPlanId
				,(SELECT Behaviour FROM BehaviourDetails WHERE MeasurementId=FREQUENCY.MeasurementId) LessonName
				,CalcType
				, ROUND(FREQUENCY.DurationMin,2)  AS Duration			
				,CASE WHEN CalcType='%Interval' THEN NULL ELSE ROUND(FREQUENCY.Frequncy,2) END AS Frequency
				,CASE WHEN CalcType='%Interval' THEN ROUND(FREQUENCY.Frequncy,2) ELSE NULL END AS Interval
				,'0' AS IsLP
				,'1000' AS LessonOrder
				,FREQUENCY.PeriodDate AS SortDate
				,FREQUENCY.IsDuration
				,FREQUENCY.IsFrequency
				,FREQUENCY.IsYesNo
				FROM(SELECT BEHAVIOR.ClassId
				,PeriodDate
				,BEHAVIOR.MeasurementId
				,(SELECT Behaviour FROM BehaviourDetails WHERE MeasurementId=BEHAVIOR.MeasurementId) LessonName
				,BEHAVIOR.Type CalcType,
				(SELECT TOP 1 frequency from #TempScoresbehav where measureid=BEHAVIOR.MeasurementId and Convert(DATE,EndDate)=Convert(DATE,BEHAVIOR.PeriodDate) ) as Frequncy,
				(SELECT TOP 1 duration from #TempScoresbehav where measureid=BEHAVIOR.MeasurementId and Convert(DATE,EndDate)=Convert(DATE,BEHAVIOR.PeriodDate) ) as DurationMin
				,ClassType
				,BEHAVIOR.IsFrequency AS IsFrequency
				,BEHAVIOR.IsDuration AS IsDuration
				,BEHAVIOR.IsYesNo AS IsYesNo
				FROM (
				SELECT ALLBEHAVIOR.ResidenceInd
				,ALLBEHAVIOR.PartialInterval
				,ALLBEHAVIOR.Period
				,ALLBEHAVIOR.NumOfTimes
				,ALLBEHAVIOR.ClassId
				,ALLBEHAVIOR.MeasurementId
				,ALLBEHAVIOR.PeriodDate
				,CASE WHEN ALLBEHAVIOR.ResidenceInd=1 
				THEN 'Residence' 
				ELSE 'Day' END ClassType
				,CASE 
    WHEN ALLBEHAVIOR.inter = 1 AND ALLBEHAVIOR.perinter = 1 THEN '%Interval'
    WHEN ALLBEHAVIOR.inter = 1 AND ALLBEHAVIOR.perinter = 0 THEN 'SumTotal'
    WHEN ALLBEHAVIOR.IsFrequency = 1 OR ALLBEHAVIOR.IsYesNo = 1 THEN 'Frequency'
    ELSE 'Duration'
	END AS Type

				,ALLBEHAVIOR.IsFrequency
				,ALLBEHAVIOR.IsDuration	
				,ALLBEHAVIOR.IsYesNo
				FROM (SELECT Behaviordata.ClassId
				,Behaviordata.MeasurementId
				,ReportPeriod.PeriodDate
				,Behaviordata.PartialInterval
				,Behaviordata.ResidenceInd
				,Behaviordata.Period
				,Behaviordata.NumOfTimes
				,Behaviordata.IsFrequency
				,Behaviordata.IsDuration	
				,Behaviordata.IsYesNo
				,Behaviordata.PartialInterval as inter
				,Behaviordata.IfPerInterval as perinter
				FROM
				(SELECT BDS.ClassId
				,BDS.MeasurementId
				,BDS.PartialInterval
				,Cls.ResidenceInd
				,BDS.Period,BDS.NumOfTimes
				,BDS.Frequency IsFrequency
				,BDS.Duration IsDuration
				,BDS.YesOrNo IsYesNo
				,BDS.IfPerInterval
				FROM BehaviourDetails BDS
				LEFT JOIN  Behaviour BR 
				ON BR.MeasurementId=BDS.MeasurementId 
				LEFT JOIN Class Cls 
				ON Cls.ClassId=BDS.ClassId 
				WHERE BDS.ActiveInd IN ('A', 'N') AND BDS.StudentId=@TempStudentid AND BDS.SchoolId=@TempSchoolId AND CONVERT(DATE, BR.TimeOfEvent) >= @TempStartDate AND CONVERT(DATE, BR.TimeOfEvent) <= @TempENDDate
				GROUP BY BDS.ClassId
				,BR.CreatedOn
				,BDS.MeasurementId
				,BDS.PartialInterval
				,Cls.ResidenceInd
				,BDS.Period
				,BDS.NumOfTimes
				,BDS.Frequency
				,BDS.Duration
				,BDS.YesOrNo 
				,BDS.IfPerInterval) AS Behaviordata,ReportPeriod
				WHERE @TempStartDate <= ReportPeriod.PeriodDate AND 
				ReportPeriod.PeriodDate <= @TempENDDate AND (Period <>0 OR Period IS NULL)) AS ALLBEHAVIOR) BEHAVIOR)FREQUENCY;
		END

		--SELECT ColName,PeriodDate,LessonPlanId,LessonName,CalcType
		--,CASE WHEN CHARINDEX('Minutes',CalcType)>0 THEN ROUND((Score/60),2)  ELSE CASE WHEN CHARINDEX('Hours',CalcType)>0 THEN ROUND((Score/3600),2)  ELSE Score END END Score
		--,Duration,Frequency,Interval,IsLP,IsDuration,IsFrequency,IsYesNo FROM #Lesson ORDER BY SortDate, LessonOrder


	END

		SELECT ColName,PeriodDate,LessonPlanId,LessonName,CalcType
		,CASE WHEN CHARINDEX('Minutes',CalcType)>0 THEN ROUND((Score/60),2)  ELSE CASE WHEN CHARINDEX('Hours',CalcType)>0 THEN ROUND((Score/3600),2)  ELSE Score END END Score
		,Duration,Frequency,Interval,IsLP,IsDuration,IsFrequency,IsYesNo FROM #Lesson ORDER BY SortDate, LessonOrder
	DROP TABLE  #Lesson;
	DROP TABLE #TempScores;
	DROP TABLE #TempScoresbehav
END

GO
