USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[sp_InsertSetStepForVTool]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_InsertSetStepForVTool]
	-- Add the parameters for the stored procedure here
	 @pTempHeadrId int,
	 @pVTLessonId int,
	 @pcreatedBy int,
	 @pschoolId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @countSet int,
	        @countStep int,
			@tempSetValue int,
			@setDataFill int,
			@currentSetId int,
			@currentSetName varchar(MAX),
			@currentStepName varchar(MAX),
			@DsTempSetId int,
			@countSteponCurrentSet int,
			@tempStepValue int,
			@currentStepId int,
			@setSortOrder int,
			@stepSortOrder int,
			@countColumn int,
			@tempColVal int,
			@currentColVal int,
			 @TempHeadrId int,
	 @VTLessonId int,
	 @createdBy int,
	 @schoolId int,
	 @DsColIdPlus int,
	 @DsColIdDur int
		
     SET @TempHeadrId = @pTempHeadrId
	 SET @VTLessonId = @pVTLessonId
	 SET @createdBy = @pcreatedBy 
	 SET @schoolId =@pschoolId 

 BEGIN try
 begin transaction
    -- Insert statements for procedure here
 SET @countSet = (SELECT COUNT(*) FROM LE_SetStep WHERE LessonId = @VTLessonId AND SetValue = 0)
 SET @countStep = (SELECT COUNT(*) FROM LE_SetStep WHERE LessonId = @VTLessonId AND SetValue != 0)
 
 DELETE FROM DSTempSet WHERE DSTempHdrId = @TempHeadrId
 DELETE FROM DSTempStep WHERE DSTempHdrId = @TempHeadrId
 UPDATE DSTempHdr SET VTLessonId = @VTLessonId WHERE DSTempHdrId = @TempHeadrId
 UPDATE DSTempHdr SET IsVisualTool = 1 WHERE DSTempHdrId = @TempHeadrId

 SET @tempSetValue = 1
 SET @setSortOrder = 1
  while(@countSet > 0)
     BEGIN
	   
	       
	        --SET @setDataFill = (SELECT * FROM LE_SetStep WHERE LessonId = @VTLessonId AND SetValue = 0)

	         CREATE table #setTable(sId int Primary Key not null Identity(1,1),S_No int,S_Name VARCHAR(MAX),SetValue VARCHAR(MAX),LessonId int,OrderId int);
	         INSERT INTO #setTable SELECT S_No,S_Name,SetValue,LessonId,OrderId FROM LE_SetStep WHERE LessonId = @VTLessonId AND SetValue = 0
	         SET @currentSetId = (SELECT S_No FROM #setTable WHERE sId = @tempSetValue)
			 SET @currentSetName = (SELECT S_Name FROM #setTable WHERE sId = @tempSetValue)

	         INSERT INTO DSTempSet(SchoolId,DSTempHdrId,VTSetId,SetCd,SortOrder,ActiveInd,CreatedBy,CreatedOn) VALUES(@schoolId,@TempHeadrId,@currentSetId,@currentSetName,@setSortOrder,'A',@createdBy,GETDATE())
	         SET @DsTempSetId = SCOPE_IDENTITY()

			 SET @countSteponCurrentSet = (SELECT COUNT(*) FROM LE_SetStep WHERE SetValue = @currentSetId)
	         SET @tempStepValue = 1
			 SET @stepSortOrder = 1
			        while(@countSteponCurrentSet > 0)
			            BEGIN

				        	
							CREATE TABLE #stepTable(stId int Primary Key not null Identity(1,1),S_No int,S_Name VARCHAR(MAX),SetValue VARCHAR(MAX),LessonId int,OrderId int);
							INSERT INTO #stepTable SELECT S_No,S_Name,SetValue,LessonId,OrderId FROM LE_SetStep WHERE SetValue = @currentSetId
							SET @currentStepId = (SELECT S_No FROM #stepTable WHERE stId = @tempStepValue)
							SET @currentSetName = (SELECT S_Name FROM #stepTable WHERE stId = @tempStepValue)

							INSERT INTO DSTempStep(SchoolId,DSTempHdrId,DSTempSetId,VTStepId,StepCd,SortOrder,ActiveInd,CreatedBy,CreatedOn) VALUES(@schoolId,@TempHeadrId,@DsTempSetId,@currentStepId,@currentSetName,@stepSortOrder,'A',@createdBy,GETDATE())
							
							SET @tempStepValue = @tempStepValue + 1
							SET @countSteponCurrentSet = @countSteponCurrentSet - 1	
							SET @stepSortOrder = @stepSortOrder + 1

							DROP Table #stepTable
			    

			              END
           
		      SET @tempSetValue = @tempSetValue + 1
			  SET @countSet = @countSet - 1
			  SET @setSortOrder = @setSortOrder + 1
 
   DROP TABLE #setTable

       END

 DELETE FROM DSTempSetCol WHERE DSTempHdrId = @TempHeadrId


 SET @countColumn = (SELECT COUNT(*) FROM DSTempSetCol WHERE DSTempHdrId = @TempHeadrId)
 SET @tempColVal = 1
     
	   WHILE(@countColumn > 0)
	    BEGIN
	  
	 CREATE TABLE #colTable(cId int Primary Key not null Identity(1,1),DsTempSetColId int,DsTempHeaderId int);
	 INSERT INTO #colTable SELECT DSTempSetColId,DSTempHdrId FROM DSTempSetCol WHERE DSTempHdrId = @TempHeadrId 
	  
	  SET @currentColVal = (SELECT DsTempSetColId FROM #colTable WHERE cId = @tempColVal)

	  DELETE FROM DSTempRule WHERE DSTempSetColId = @currentColVal

	  SET @tempColVal = @tempColVal + 1
	  SET @countColumn = @countColumn - 1

	  END

 INSERT into DSTempSetCol(SchoolId,DSTempHdrId,ColName,ColTypeCd,CorrResp,IncMisTrialInd,ActiveInd,CreatedBy,CreatedOn) VALUES(@schoolId,@TempHeadrId,'Column1','+/-','+',0,'A',@createdBy,GETDATE())
 SET @DsColIdPlus = SCOPE_IDENTITY()
 Insert Into DSTempSetColCalc (SchoolId,DSTempSetColId,CalcType,CalcRptLabel,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn,ActiveInd) VALUES(@schoolId,@DsColIdPlus,'%Accuracy','%Accuracy',@createdBy,getdate(),@createdBy,getdate(),'A')  	 
 INSERT into DSTempSetCol(SchoolId,DSTempHdrId,ColName,ColTypeCd,IncMisTrialInd,ActiveInd,CreatedBy,CreatedOn) VALUES(@schoolId,@TempHeadrId,'Column2','Duration',0,'A',@createdBy,GETDATE())	 
 SET @DsColIdDur = SCOPE_IDENTITY()
 Insert Into DSTempSetColCalc (SchoolId,DSTempSetColId,CalcType,CalcRptLabel,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn,ActiveInd) VALUES(@schoolId,@DsColIdDur,'Total Duration','Total Duration',@createdBy,getdate(),@createdBy,getdate(),'A')  	 
commit
END try
BEGIN catch
RollBack
END catch
END













GO
