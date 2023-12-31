USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Client_Dashboard]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Client_Dashboard]
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

	
            BEGIN

	SELECT ReferralId
			,ReferralName
			,BirthDate
			,Gender
			,Appdate
			,ImageUrl
			, Percentage
			,(SELECT QueueName 
	FROM ref_Queue 
	WHERE QueueId= (SELECT TOP 1 QueueId 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId= @School
	AND StudentPersonalId=SET2.ReferralId 
	ORDER BY QueueStatusId DESC )) LastCompleted
			,CompletedBy
			,ActiveProcess
			,(SELECT QueueType FROM ref_Queue WHERE QueueId=(SELECT MasterId FROM ref_Queue WHERE QueueId=ActiveProcess)) QueueType
			 FROM (
	SELECT QS.StudentPersonalId ReferralId,SPL.LastName +','+ SPL.FirstName ReferralName,SPL.BirthDate,
	CASE WHEN SPL.Gender=1 THEN 'Male' ELSE  CASE WHEN SPL.Gender=2 THEN 'Female' END END Gender
	,CONVERT(DATE,SPL.CreatedOn) Appdate
	,SPL.ImageUrl
	,CONVERT(float,0) Percentage
	,'' LastCompleted
	,(SELECT [UserLName]+','+[UserFName] UserName  
	FROM [User] 
	WHERE UserId= (SELECT TOP 1 CreatedBy 
	FROM ref_QueueStatus 
	WHERE CurrentStatus='False' 
	AND Draft='N' 
	AND SchoolId=@School 
	AND StudentPersonalId=SPL.StudentPersonalId
	ORDER BY QueueStatusId DESC )) CompletedBy
	,(select QueueId from ref_Queue where QueueType='CL') ActiveProcess FROM ref_QueueStatus QS 
	INNER JOIN StudentPersonal SPL ON QS.StudentPersonalId=SPL.StudentPersonalId WHERE QueueId=@Queue 
	AND SPL.StudentType='Client' AND SPL.SchoolId=@School) SET2

	

	END
END


GO
