USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Referral_Dashboard]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Referral_Dashboard]
@QueueId int,
@SchoolId int,
@SType varchar(50)

AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @Queue int,
	@Referraltype int,
	@School int,
	@QueueType varchar(50)

	SET @Queue=@QueueId
	SET @School=@SchoolId

	IF(@QueueId<>0)
	BEGIN

	SET @QueueType=(SELECT QueueType FROM ref_Queue WHERE QueueId=@Queue)
	
            IF (@QueueType <> 'AV' AND @QueueType <> 'WL' AND @QueueType <> 'IL' AND @QueueType <> 'RL')
            BEGIN
SELECT ReferralId
			,ReferralName
			,BirthDate
			,Gender
			,Appdate
			,ImageUrl
			,Percentage
			,LastCompleted
			,CompletedBy
			,ActiveProcess
			,(SELECT QueueType FROM ref_Queue WHERE QueueId=(SELECT MasterId FROM ref_Queue WHERE QueueId=ActiveProcess)) QueueType
			 FROM ( 
	SELECT ReferralId
	,ReferralName
	,BirthDate
	,CASE WHEN Gender=1 THEN 'Male' ELSE  CASE WHEN Gender=2 THEN 'Female' END END Gender
	,Appdate
	,ImageUrl


    ,ROUND(((CONVERT(float,Refrl.CompletedStep)/CONVERT(float,Refrl.TotalProcess))*100),2) Percentage
	--Refrl.CompletedStep as Percentage

	,(SELECT QueueName 
	FROM ref_Queue 
	WHERE QueueId= (SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=Refrl.ReferralId 
	ORDER BY QueueStatusId DESC )) LastCompleted
	,(SELECT [UserLName]+','+[UserFName] UserName  
	FROM [User] 
	WHERE UserId= (SELECT TOP 1 CreatedBy 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=Refrl.ReferralId 
	ORDER BY QueueStatusId DESC )) CompletedBy 
	,
	
	
	ISNULL((SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='True' 
	AND SchoolId=@School 
	AND StudentPersonalId=Refrl.ReferralId 
	ORDER BY QueueStatusId DESC )  ,
	
	
	(SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=Refrl.ReferralId 
	ORDER BY QueueStatusId DESC )) ActiveProcess
	FROM 
	(SELECT spl.StudentPersonalId ReferralId
	,spl.SchoolId
	,ISNULL(CompletedStep,0) CompletedStep
	,(SELECT COUNT(*) 
	FROM ref_Queue 
	WHERE MasterId<>0 And MasterId<>1 ) TotalProcess
	,spl.LastName +','+spl.FirstName ReferralName
	,spl.BirthDate
	,spl.Gender
	,CONVERT(DATE,spl.AdmissionDate) Appdate
	,spl.ImageUrl 
	FROM StudentPersonal spl 
	INNER JOIN  



	(SELECT (SELECT COUNT(DISTINCT QueueId) FROM ref_QueueStatus WHERE QueueId IN 
 (SELECT QueueId FROM ref_Queue 	WHERE MasterId<>0 And MasterId<>1 ) AND Draft='N' And CurrentStatus='false' AND QueueProcess=
 (SELECT MAX(QueueProcess) FROM ref_QueueStatus WHERE  StudentPersonalId=Que.StudentPersonalId)
AND StudentPersonalId=Que.StudentPersonalId AND SchoolId=@School) CompletedStep




	,SchoolId
	,StudentPersonalId 
	FROM 
	(SELECT Que.QueueId
	,Qst.SchoolId
	,QSt.StudentPersonalId
	,QueueName
	,MasterId
	,QueueProcess 
	FROM ref_Queue Que 
	INNER JOIN 
	(SELECT * FROM (SELECT SchoolId
	,StudentPersonalId
	,QueueId
	,MAX(QueueProcess) QueueProcess 
	FROM ref_QueueStatus
	WHERE CurrentStatus='True'
	AND QueueId IN (SELECT QueueId 
	FROM ref_Queue 
	WHERE MasterId=@Queue) 
	AND (SELECT COUNT(*) 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='True' 
	AND SchoolId=@School 
	AND StudentPersonalId=StudentPersonalId 
	AND QueueId IN (SELECT QueueId FROM ref_Queue WHERE MasterId=@Queue))>0 
	AND SchoolId=@School
	GROUP BY SchoolId,StudentPersonalId,QueueId) QPR
	WHERE QueueProcess=(SELECT MAX(QueueProcess) FROM ref_QueueStatus 
	WHERE SchoolId=QPR.SchoolId AND StudentPersonalId=QPR.StudentPersonalId)) QSt 
	ON QSt.QueueId=Que.QueueId) QUE
	WHERE QUE.QueueId NOT IN (SELECT QueueId FROM ref_Queue 
	WHERE SchoolId=@School 
	AND (QueueType='AV' 
	OR QueueType='WL' 
	OR QueueType='IV')) 
	AND QUE.SchoolId=@School
	GROUP BY SchoolId,StudentPersonalId) RefStatus
	ON spl.StudentPersonalId=RefStatus.StudentPersonalId
	WHERE spl.StudentType='Referral' 
	AND spl.SchoolId=@School) Refrl) SET1 
	END



	ELSE IF (@QueueType = 'AV' OR @QueueType = 'WL' OR @QueueType = 'IL' )
	BEGIN
	SELECT ReferralId
			,ReferralName
			,BirthDate
			,Gender
			,Appdate
			,ImageUrl
			,Percentage
			,LastCompleted
			,CompletedBy
			,ActiveProcess
			,(SELECT QueueType FROM ref_Queue WHERE QueueId=(SELECT MasterId FROM ref_Queue WHERE QueueId=ActiveProcess)) QueueType
			 FROM (
	SELECT QS.StudentPersonalId ReferralId,SPL.LastName +','+ SPL.FirstName ReferralName,SPL.BirthDate,
	CASE WHEN SPL.Gender=1 THEN 'Male' ELSE  CASE WHEN SPL.Gender=2 THEN 'Female' END END Gender
	,CONVERT(DATE,SPL.AdmissionDate) 
	Appdate,SPL.ImageUrl,CONVERT(float,0) Percentage,'' LastCompleted,'' CompletedBy,-1 ActiveProcess FROM ref_QueueStatus QS 
	INNER JOIN StudentPersonal SPL ON QS.StudentPersonalId=SPL.StudentPersonalId WHERE QueueId=@Queue AND CurrentStatus='True' 
	AND SPL.StudentType='Referral' AND SPL.SchoolId=@School) SET2
	END
	ELSE IF (@QueueType = 'RL')
	BEGIN
	SELECT ReferralId
			,ReferralName
			,BirthDate
			,Gender
			,Appdate
			,ImageUrl
			,Percentage
			,LastCompleted
			,CompletedBy
			,ActiveProcess
			,(SELECT QueueType FROM ref_Queue WHERE QueueId=(SELECT MasterId FROM ref_Queue WHERE QueueId=ActiveProcess)) QueueType
			 FROM (
	SELECT QS.StudentPersonalId ReferralId,SPL.LastName +','+ SPL.FirstName ReferralName,SPL.BirthDate,CASE WHEN SPL.Gender=1 THEN 'Male' 
	ELSE  CASE WHEN SPL.Gender=2 THEN 'Female' END END Gender,CONVERT(DATE,SPL.AdmissionDate) 
	Appdate,SPL.ImageUrl,CONVERT(float,0) Percentage,(SELECT QueueName 
	FROM ref_Queue 
	WHERE QueueId= (SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=SPL.StudentPersonalId
	ORDER BY QueueStatusId DESC )) LastCompleted
	,(SELECT [UserLName]+','+[UserFName] UserName  
	FROM [User] 
	WHERE UserId= (SELECT TOP 1 CreatedBy 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=SPL.StudentPersonalId
	ORDER BY QueueStatusId DESC )) CompletedBy ,ISNULL((SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='True' 
	AND SchoolId=@School 
	AND StudentPersonalId=SPL.StudentPersonalId
	ORDER BY QueueStatusId DESC )  ,(SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=SPL.StudentPersonalId
	ORDER BY QueueStatusId DESC )) ActiveProcess FROM ref_QueueStatus QS 
	INNER JOIN StudentPersonal SPL ON QS.StudentPersonalId=SPL.StudentPersonalId WHERE QueueId=(SELECT QueueId FROM ref_Queue WHERE MasterId=@Queue)
	AND SPL.StudentType='Referral' AND SPL.SchoolId=@School
	) SET3
	END

	END
END




GO
