USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Update_StudentStatus_Automatically]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Update_StudentStatus_Automatically]
	@StudentId int = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @LOOP INT,
	@CNT INT,
	@SPID INT,
	@PLCRSN VARCHAR(50),
	@PLMNTRSN INT

	CREATE TABLE #STATUS(ID INT NOT NULL PRIMARY KEY IDENTITY(1,1), PlacementReason INT,StudentPersonalId INT,StartDate DATE,EndDate DATE)

	IF(@StudentId IS NULL)

	BEGIN
	INSERT INTO #STATUS SELECT PlacementReason,StudentPersonalId,StartDate,EndDate FROM Placement  WHERE Status = 1 AND 
	PlacementReason IS NOT NULL ORDER BY StudentPersonalId,PlacementReason
	END

	ELSE

	BEGIN
	INSERT INTO #STATUS SELECT PlacementReason,StudentPersonalId,StartDate,EndDate FROM Placement WHERE StudentPersonalId =@StudentId 
	AND Status = 1 AND PlacementReason IS NOT NULL	ORDER BY PlacementReason
	END

	IF((SELECT COUNT(*) FROM #STATUS)=0)
	BEGIN
	UPDATE StudentPersonal SET [PlacementStatus]='A' WHERE StudentPersonalId=@StudentId
	END
	

	CREATE TABLE #StudentPers (ID INT NOT NULL PRIMARY KEY IDENTITY(1,1),StudentPersonalId INT)
	INSERT INTO #StudentPers SELECT DISTINCT StudentPersonalId  FROM #STATUS
	
	SET @LOOP=(SELECT COUNT(*) FROM #StudentPers)
	SET @CNT=1
	WHILE(@LOOP>0)
	BEGIN

	SET @SPID=(SELECT StudentPersonalId FROM #StudentPers WHERE ID=@CNT)
	
	 IF((SELECT COUNT(*) FROM #STATUS WHERE StudentPersonalId=@SPID AND PlacementReason=(SELECT LookupId FROM LookUp WHERE LookupType='Placement Reason' AND
	 LookupDesc='On-Hold') AND ((CONVERT(DATE,StartDate)<=CONVERT(DATE,GETDATE()) AND CONVERT(DATE,GETDATE())<=CONVERT(DATE,EndDate)) 
	 OR (CONVERT(DATE,StartDate)<=CONVERT(DATE,GETDATE()) AND EndDate IS NULL)))>0)
	 BEGIN
	 UPDATE StudentPersonal SET [PlacementStatus]='H' WHERE StudentPersonalId=@SPID
	 END

	 ELSE IF((SELECT COUNT(*) FROM #STATUS WHERE StudentPersonalId=@SPID AND PlacementReason=(SELECT LookupId FROM LookUp WHERE LookupType='Placement Reason' AND
	 LookupDesc='Inactive') AND (CONVERT(DATE,StartDate)<=CONVERT(DATE,GETDATE()) AND CONVERT(DATE,GETDATE())<=CONVERT(DATE,EndDate)))>0)
	 BEGIN
	 UPDATE StudentPersonal SET [PlacementStatus]='I' WHERE StudentPersonalId=@SPID
	 END 

	 ELSE IF((SELECT COUNT(*) FROM #STATUS WHERE StudentPersonalId=@SPID AND ((CONVERT(DATE,StartDate)<=CONVERT(DATE,GETDATE()) AND 
	 CONVERT(DATE,GETDATE())<=CONVERT(DATE,EndDate)) OR (CONVERT(DATE,StartDate)<=CONVERT(DATE,GETDATE()) AND EndDate IS NULL)))=0)
	 BEGIN
	 SET @PLMNTRSN=(SELECT PlacementReason FROM (SELECT TOP 1 CONVERT(DATE,MAX(EndDate)) EndDate,PlacementReason FROM Placement   GROUP BY StudentPersonalId,PlacementReason,Status
	 HAVING StudentPersonalId= @SPID AND CONVERT(DATE,MAX(EndDate))<CONVERT(DATE,GETDATE()) AND Status=1 and PlacementReason IS NOT NULL ORDER BY EndDate DESC )PlcStatus)
	 SET @PLCRSN= (SELECT LookUpDesc FROM LookUp WHERE LookUpId=@PLMNTRSN)
	 IF(@PLCRSN='Inactive')
	 BEGIN
	 UPDATE StudentPersonal SET [PlacementStatus]='I' WHERE StudentPersonalId=@SPID
	 END
	 ELSE IF(@PLCRSN='On-Hold')
	 BEGIN
	 UPDATE StudentPersonal SET [PlacementStatus]='A' WHERE StudentPersonalId=@SPID
	 END
	 ELSE 
	 BEGIN
	 UPDATE StudentPersonal SET [PlacementStatus]='A' WHERE StudentPersonalId=@SPID
	 END
	 END 

	 ELSE 
	 BEGIN
	 UPDATE StudentPersonal SET [PlacementStatus]='A' WHERE StudentPersonalId=@SPID
	 END
	
	SET @CNT=@CNT+1
	SET @LOOP=@LOOP-1
	END

	DROP TABLE #STATUS
	DROP TABLE #StudentPers
   
END

GO
