USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ValidateAsmnt]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE

PROCEDURE [dbo].[ValidateAsmnt] (@SchoolId INT,@AsmntName VARCHAR(50)) AS

BEGIN
DECLARE
@temp_validation TABLE
(
[GoalName] [varchar](50) NULL,
[AsmntName] [varchar](50) NULL,
[AsmntCat] [varchar](100) NULL,
[AsmntSubCat] [varchar](100) NULL,
[AsmntQId] [varchar](50) NULL,
[Comment] [varchar](50) NULL
);

INSERT
INTO @temp_validation
(
[GoalName] ,
[AsmntName] ,
[AsmntCat] ,
[AsmntSubCat] ,
[AsmntQId] ,
[Comment] )
SELECT
Stg.[GoalName] ,
Stg.[AsmntName] ,
Stg.[AsmntCat] ,
Stg.[AsmntSubCat],
Stg.[AsmntQId] ,
'Invalid Skill'
FROM
[AsmntTempStg] Stg

LEFT JOIN Goal G
ON
Stg.GoalName = G.GoalName
AND
G.GoalTypeId = (SELECT GoalTypeId FROM GoalType WHERE GoalTypeName ='Academic Goals')
AND
Stg.SchoolId = @SchoolId
WHERE
G.GoalName IS NULL;


DECLARE
@temp_mismatchQtns TABLE
(
[TempGoal] [varchar](50) NULL,
[TempAsmnt] [varchar](50) NULL,
[TempCat] [varchar](100) NULL,
[TempSubCat] [varchar](100) NULL,
[TempQId] [varchar](50) NULL,
[TempCmt] [varchar](50) NULL,
[LPGoal] [varchar](50) NULL,
[LPAsmnt] [varchar](50) NULL,
[LPCat] [varchar](100) NULL,
[LPSubCat] [varchar](100) NULL,
[LPQId] [varchar](50) NULL,
[ActiveInd] [varchar](1) NULL,
[LPCmt] [varchar](50) NULL
);
INSERT
INTO @temp_mismatchQtns
(
[TempGoal],
[TempAsmnt],
[TempCat],
[TempSubCat],
[TempQId],
[TempCmt],
[LPGoal],
[LPAsmnt],
[LPCat],
[LPSubCat],
[LPQId],
[ActiveInd],
[LPCmt])

	/*SELECT Temp.[GoalName],Temp.[AsmntName],Temp.[AsmntCat],Temp.[AsmntSubCat],Temp.[AsmntQId],'InvalidTempQtn',
	Gl.[GoalName],LP.[AsmntName],LP.[AsmntCat],LP.[AsmntSubCat],LP.[AsmntQId],'InvalidLPQtn'
	FROM AsmntTempStg Temp 
	FULL OUTER JOIN (AsmntLPRel LP INNER JOIN Goal Gl ON Gl.GoalId=LP.GoalId)
	ON REPLACE(Gl.GoalName,'_',' ')=REPLACE(Temp.GoalName,'_',' ') 
	AND LP.AsmntName=Temp.AsmntName 
	AND REPLACE(LP.AsmntCat,'_',' ')=REPLACE(Temp.AsmntCat,'_',' ') 
	AND ISNULL(REPLACE(LP.AsmntSubCat,'_',' '),'')=ISNULL(REPLACE(Temp.AsmntSubCat,'_',' '),'') 
	AND LP.AsmntQId=Temp.AsmntQId
	WHERE (Temp.AsmntName=@AsmntName OR LP.AsmntName=@AsmntName) AND ISNULL(Temp.AsmntQId,'')<>ISNULL(LP.AsmntQId,'')
	AND ISNULL(Temp.AsmntName,'')<>ISNULL(LP.AsmntName,'') AND ISNULL(Temp.AsmntCat,'')<>ISNULL(LP.AsmntCat,'')
	GROUP BY Temp.[GoalName],Temp.[AsmntName],Temp.[AsmntCat],Temp.[AsmntSubCat],Temp.[AsmntQId],
	Gl.[GoalName],LP.[AsmntName],LP.[AsmntCat],LP.[AsmntSubCat],LP.[AsmntQId]*/
	
	SELECT Temp.[GoalName],Temp.[AsmntName],Temp.[AsmntCat],Temp.[AsmntSubCat],Temp.[AsmntQId],'InvalidTempQtn',
	Gl.[GoalName],LP.[AsmntName],LP.[AsmntCat],LP.[AsmntSubCat],LP.[AsmntQId],LP.ActiveInd,'InvalidLPQtn'
	FROM AsmntTempStg Temp 
	FULL OUTER JOIN (AsmntLPRel LP INNER JOIN Goal Gl ON Gl.GoalId=LP.GoalId)
	ON REPLACE(Gl.GoalName,'_',' ')=REPLACE(Temp.GoalName,'_',' ') 
	AND LP.AsmntName=Temp.AsmntName 
	AND REPLACE(LP.AsmntCat,'_',' ')=REPLACE(Temp.AsmntCat,'_',' ') 
	AND ISNULL(REPLACE(LP.AsmntSubCat,'_',' '),'')=ISNULL(REPLACE(Temp.AsmntSubCat,'_',' '),'') 
	AND LP.AsmntQId=Temp.AsmntQId
	WHERE (Temp.AsmntName=@AsmntName OR LP.AsmntName=@AsmntName)
	GROUP BY Temp.[GoalName],Temp.[AsmntName],Temp.[AsmntCat],Temp.[AsmntSubCat],Temp.[AsmntQId],
	Gl.[GoalName],LP.[AsmntName],LP.[AsmntCat],LP.[AsmntSubCat],LP.[AsmntQId],LP.ActiveInd


SELECT DISTINCT GoalName FROM @temp_validation;
SELECT LPCat,LPSubCat,LPGoal,LPQId FROM @temp_mismatchQtns WHERE TempAsmnt IS NULL AND ActiveInd='A'
SELECT TempCat,TempSubCat,TempGoal,TempQId FROM @temp_mismatchQtns WHERE LPAsmnt IS NULL
SELECT DISTINCT G.GoalId,G.GoalName FROM Goal G INNER JOIN @temp_mismatchQtns temp ON G.GoalName=temp.TempGoal
SELECT LPCat,LPSubCat,LPGoal,LPQId FROM @temp_mismatchQtns WHERE TempAsmnt IS NOT NULL AND LPAsmnt IS NOT NULL AND ActiveInd='N'
END

;










GO
