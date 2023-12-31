USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[sp_DeleteForNonVT]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_DeleteForNonVT]
	-- Add the parameters for the stored procedure here	
	@pTempHeaderId int
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @tempColId int,
	@TempHeaderId int,
	@countColumn int,
	@tempValue int,
	@currentColVal int

	SET @TempHeaderId = @pTempHeaderId

    -- Insert statements for procedure here
	SET @countColumn = (SELECT COUNT(*) FROM DSTempSetCol WHERE DSTempHdrId = @TempHeaderId)
	SET @tempValue = 1  

	CREATE TABLE #colTable(cId int Primary Key not null Identity(1,1),DsTempSetColId int,DsTempHeaderId int);
	 INSERT INTO #colTable SELECT DsTempSetColId,DSTempHdrId FROM DSTempSetCol WHERE DSTempHdrId = @TempHeaderId 
	  WHILE(@countColumn > 0)
	  BEGIN	
	  
	  SET @currentColVal = (SELECT DsTempSetColId FROM #colTable WHERE cId = @tempValue)

	  DELETE FROM DSTempRule WHERE DSTempSetColId = @currentColVal

	  SET @tempValue = @tempValue + 1
	  SET @countColumn = @countColumn - 1

	  END

	  DROP TABLE #colTable

	 DELETE FROM DSTempSet WHERE DSTempHdrId = @TempHeaderId
     DELETE FROM DSTempStep WHERE DSTempHdrId = @TempHeaderId
	 DELETE FROM DSTempSetCol WHERE DSTempHdrId = @TempHeaderId   
	 UPDATE DSTempHdr SET VTLessonId = 0 WHERE DSTempHdrId = @TempHeaderId
	 
END










GO
