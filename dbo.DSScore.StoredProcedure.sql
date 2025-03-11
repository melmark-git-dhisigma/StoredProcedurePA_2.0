USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[DSScore]    Script Date: 11/04/2024 6:47:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DSScore] 
@LessonId varchar(MAX),
@StudentId int,
@StartDate varchar(100),
@EndDate varchar(100)
AS
BEGIN
declare @lsid table (lsid int)

insert into @lsid(lsid) SELECT * FROM Split(@LessonId,',') OPTION (MAXRECURSION 500)

SELECT        hdr.StdtClassId AS ClassId, sc.DSTempSetColCalcId, DC.ColName, hdr.EndTs AS EvntTs, CONVERT(varchar, hdr.EndTs, 101) AS PeriodDate, hdr.LessonPlanId, 
                        CASE WHEN CalcType IN ('Avg Duration','Total Duration') THEN CASE WHEN Hdr.IsMaintanace = 0 THEN  CalcType + ' (In Seconds)' END Else CalcType END CalcType , CASE WHEN ResidenceInd = 1 THEN 'Residence' ELSE 'Day' END AS ClassType, 
                         CASE WHEN hdr.SessMissTrailStus = 'Y' THEN 'Mistrial' ELSE CASE WHEN CHARINDEX('-', CASE WHEN Hdr.IsMaintanace = 0 THEN sc.Score END) 
                         > 0 THEN 'NA' ELSE CASE WHEN CalcType IN ('Avg Duration', 'Total Duration') 
						 THEN  CASE WHEN  
                         Hdr.IsMaintanace = 0 THEN CONVERT(VARCHAR(50), sc.Score) END ELSE CASE WHEN sc.Score >= 0 AND Hdr.IsMaintanace = 0 THEN CONVERT(VARCHAR(50), sc.Score) END END END END AS Score1,
						
						  '1' AS IsLP, 
                         dcal.IncludeInGraph
FROM            StdtSessColScore AS sc INNER JOIN
                         DSTempSetColCalc AS dcal ON dcal.DSTempSetColCalcId = sc.DSTempSetColCalcId INNER JOIN
                         StdtSessionHdr AS hdr ON hdr.StdtSessionHdrId = sc.StdtSessionHdrId INNER JOIN
                         Class AS Cls ON Cls.ClassId = hdr.StdtClassId INNER JOIN
                         DSTempHdr AS DHDR ON DHDR.DSTempHdrId = hdr.DSTempHdrId LEFT OUTER JOIN
                         DSTempSetCol AS DC ON DC.DSTempSetColId = dcal.DSTempSetColId
WHERE        (hdr.SessionStatusCd = 'S') AND (DHDR.StudentId = @StudentId) AND (DHDR.LessonPlanId IN
                             (select lsid from @lsid)) AND (@StartDate <= CONVERT(DATE, hdr.EndTs)) AND (CONVERT(DATE, hdr.EndTs) <= @EndDate)
UNION ALL
SELECT        SE.ClassId, DC.DSTempSetColCalcId, DSC.ColName AS Colname, SE.EvntTs, CONVERT(VARCHAR, SE.EvntTs, 101) AS PeriodDate, SE.LessonPlanId, 
                         DC.CalcType, NULL AS ClassType, NULL AS Score1, '1' AS IsLP, DC.IncludeInGraph
FROM            DSTempSetCol AS DSC INNER JOIN
                         StdtSessEvent AS SE ON DSC.DSTempHdrId = SE.DSTempHdrId INNER JOIN
                         DSTempSetColCalc AS DC ON DSC.DSTempSetColId = DC.DSTempSetColId
WHERE        (SE.StudentId = @StudentId) AND (@StartDate <= CONVERT(DATE, SE.EvntTs)) AND (CONVERT(DATE, SE.EvntTs) <= @EndDate) AND (SE.EventType = 'EV') AND 
                         (SE.SessionNbr IS NULL)
						 ORDER BY EvntTs,LessonPlanId
END
