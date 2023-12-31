USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[sp_copyLessonPlan]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_copyLessonPlan]
	-- Add the parameters for the stored procedure here
	@pcopyLessonId int,
	@pIsStEdit int,
	@pIsCCEdit int

	
AS
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @newLessonId int,	        
	        @isStEdit int,
			@isCcEdit int,
	        @tempsetValue int,
			@countNumSets int,
			@currentSetId int,
			@copyLessonId int,
			@currentSetName varchar(MAX),
			@setorderId int,
			@setCreatedBy int,
			@setCreatedOn datetime,
			@newSetId int,
			@countNumStep int,
			@tempStepValue int,
			@currentStepId int,
			@currentStepName VARCHAR(MAX),
			@stepOrderId int,
			@stepCreatedBy int,
			@stepCreatedOn datetime,
			@newStepId int,
			@currentLE_DetailId int,
			@clockBg VARCHAR(MAX),
			@speed int,
			@isdigits Varchar(MAX),
			@le_CreatedBy int,
			@le_CreatedOn datetime,
			@newLe_DetailId int,
			@countLe_option int,
			@tempOptionValue int,
			@leopt_Objects VARCHAR(MAX),
			@leopt_Status VARCHAR(MAX),
			@leopt_CreatedBy int,
			@leopt_CreatedOn datetime
			

     SET @copyLessonId = @pcopyLessonId
	 SET @isStEdit = @pIsStEdit
	 SET @isCcEdit = @pIsCCEdit


	BEGIN try
	  begin transaction

	  SELECT * FROM LE_Lesson WHERE LessonId = @copyLessonId
	  INSERT INTO LE_Lesson(LessonName,Description,Keyword,LessonType,DomainId,NmbrSet,NmbrStep,IsDiscreate,IsST_Edit,IsCC_Edit,CreatedBy,CreatedOn) SELECT LessonName,Description,Keyword,LessonType,DomainId,NmbrSet,NmbrStep,IsDiscreate,@isStEdit,@isCcEdit,CreatedBy,CreatedOn FROM LE_Lesson WHERE LessonId = @copyLessonId
	  SET @newLessonId =  SCOPE_IDENTITY()  

	  SET @countNumSets = (SELECT COUNT(*) FROM LE_SetStep WHERE LessonId = @copyLessonId AND SetValue = 0)
	  SET @tempSetValue = 1

	          WHILE(@countNumSets > 0)
			  BEGIN

			   CREATE table #setTable(sId int Primary Key not null Identity(1,1),S_No int,S_Name VARCHAR(MAX),SetValue VARCHAR(MAX),LessonId int,OrderId int,CreatedBy int,CreatedOn Varchar(MAX));
			   INSERT INTO #setTable SELECT S_No,S_Name,SetValue,LessonId,OrderId,CreatedBy,CreatedOn FROM LE_SetStep WHERE LessonId = @copyLessonId AND SetValue = 0
			   SET @currentSetId = (SELECT S_No FROM #setTable WHERE sId = @tempsetValue)
			   SET @currentSetName = (SELECT S_Name FROM #setTable WHERE sId = @tempsetValue) 
			   SET @setorderId = (SELECT OrderId FROM #setTable WHERE sid = @tempsetValue)
			   SET @setCreatedBy = (SELECT CreatedBy FROM #setTable WHERE sId = @tempsetValue)
			   SET @setCreatedOn = (SELECT CreatedOn FROM #setTable WHERE sid = @tempsetValue)

			   INSERT into LE_SetStep(S_Name,SetValue,LessonId,OrderId,CreatedBy,CreatedOn) Values(@currentSetName,0,@newLessonId,@setorderId,@setCreatedBy,@setCreatedOn)
			   SET @newSetId = SCOPE_IDENTITY()

			   SET @countNumStep = (SELECT COUNT(*) FROM LE_SetStep WHERE LessonId = @copyLessonId AND SetValue = @currentSetId)
			   SET @tempStepValue = 1

			           WHILE(@countNumStep > 0)
					   BEGIN
					   CREATE TABLE #stepTable(stid int Primary Key IDENTITY(1,1)
					   ,S_No int
					   ,S_Name VARCHAR(50)
					   ,SetValue int
					   ,LessonId int
					   ,OrderId int
					   ,CreatedBy int
					   ,CreatedOn datetime
					   ,ModifiedBy int
					   ,ModifiedOn datetime);
					   INSERT into #stepTable SELECT S_No
					   ,S_Name
					   ,SetValue
					   ,LessonId
					   ,OrderId
					   ,CreatedBy
					   ,CreatedOn
					   ,ModifiedBy
					   ,ModifiedOn FROM LE_SetStep WHERE  SetValue = @currentSetId
					   SET @currentStepId = (SELECT S_No FROM #stepTable WHERE stId = @tempStepValue)
					   SET @currentStepName = (SELECT S_Name FROM #stepTable WHERE stId = @tempStepValue)
					   SET @stepOrderId = (SELECT OrderId FROM #stepTable WHERE stId = @tempStepValue)
					   SET @stepCreatedBy = (SELECT @stepCreatedBy FROM #stepTable WHERE stId = @tempStepValue)
					   SET @stepCreatedOn = (SELECT @stepCreatedOn FROM #stepTable WHERE stId = @tempStepValue)

					   INSERT INTO LE_SetStep(S_Name
					   ,LessonId
					   ,SetValue					
					   ,OrderId
					   ,CreatedBy
					   ,CreatedOn) Values(@currentStepName
					   ,@newLessonId
					   ,@newSetId
					   ,@stepOrderId
					   ,@stepCreatedBy
					   ,@stepCreatedOn)
					   SET @newStepId = SCOPE_IDENTITY()

					      
						  CREATE TABLE #Le_Detail(l_Id int Primary Key not null Identity(1,1),Le_DetailId int,LessonId int,SetValue int,StepValue int,NmbrObjects VARCHAR(MAX),ObjectId int,Speed VARCHAR(MAX),ClockBG VARCHAR(MAX),Isdigits VARCHAR(50),CreatedBy VARCHAR(MAX),CreatedOn VARCHAR(MAX));
						  INSERT into #Le_Detail SELECT Le_DetailId,LessonId,SetValue,StepValue,NmbrObjects,ObjectId,Speed,ClockBG,IsDigits,CreatedBy,CreatedOn FROM LE_LessonDetails WHERE StepValue = @currentStepId AND SetValue = @currentSetId
						  SET @currentLE_DetailId = (SELECT Le_DetailId FROM #Le_Detail WHERE l_Id = 1)
						  SET @clockBg = (SELECT ClockBG FROM #Le_Detail WHERE l_Id = 1)
						  SET @speed = (SELECT Speed FROM #Le_Detail WHERE l_Id = 1)
						  SET @isdigits = (SELECT Isdigits FROM #Le_Detail WHERE l_Id = 1)
						  SET @le_CreatedBy = (SELECT CreatedBy FROM #Le_Detail WHERE l_Id = 1)
						  SET @le_CreatedOn = (SELECT CreatedOn FROM #Le_Detail WHERE l_Id = 1)

						  INSERT INTO LE_LessonDetails(LessonId,SetValue,StepValue,Speed,ClockBG,IsDigits,CreatedBy,CreatedOn) VALUES(@newLessonId,@newSetId,@newStepId,@speed,@clockBg,@isdigits,@le_CreatedBy,@le_CreatedOn)
						  SET @newLe_DetailId = SCOPE_IDENTITY()

						  DROP TABLE #Le_Detail

						  SET @countLe_option = (SELECT COUNT(*) FROM LE_Options WHERE Le_DetailId = @currentLE_DetailId)
						  SET @tempOptionValue = 1

						           WHILE(@countLe_option > 0)
								   BEGIN


						           CREATE TABLE #Le_Option(lopt_Id int Primary Key not null Identity(1,1),Le_DetailId int,objects VARCHAR(MAX),Status VARCHAR(MAX),CreatedBy int,CreatedOn Varchar(MAX))
						           INSERT into #Le_Option SELECT Le_DetailId,Objects,Status,CreatedBy,CreatedOn FROM LE_Options WHERE Le_DetailId = @currentLE_DetailId
								   SET @leopt_Objects = (SELECT objects FROM #Le_Option WHERE lopt_Id = @tempOptionValue)
								   SET @leopt_Status = (SELECT Status FROM #Le_Option WHERE lopt_Id = @tempOptionValue)
								   SET @leopt_CreatedBy = (SELECT CreatedBy FROM #Le_Option WHERE lopt_Id = @tempOptionValue)
								   SET @le_CreatedOn = (SELECT CreatedOn FROM #Le_Option WHERE lopt_Id = @tempOptionValue)

								   INSERT INTO LE_Options(Le_DetailId,Objects,Status,CreatedBy,CreatedOn) VALUES(@newLe_DetailId,@leopt_Objects,@leopt_Status,@leopt_CreatedBy,@leopt_CreatedOn)

								   SET @tempOptionValue = @tempOptionValue + 1
								   SET @countLe_option = @countLe_option - 1
								   DROP TABLE #Le_Option 


						            END

                         SET @tempStepValue = @tempStepValue + 1
						 SET @countNumStep = @countNumStep - 1
						 DROP TABLE #stepTable  



					   END

			   SET @tempsetValue = @tempsetValue + 1
			   SET @countNumSets = @countNumSets - 1
			   DROP TABLE #setTable    		 
			  


			  END
   SELECT @newLessonId AS ResultString

	  commit
	  END try

	  BEGIN catch
	  Rollback
	  END catch

 END

	












GO
