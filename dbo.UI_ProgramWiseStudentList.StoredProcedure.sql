USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_ProgramWiseStudentList]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UI_ProgramWiseStudentList]
	
			@PgmFlag int,
			@ChldorAdFlag int,
			@ProgramName varchar(Max)

AS
BEGIN
	
	SET NOCOUNT ON;
	
	If (@PgmFlag =0 and  @ChldorAdFlag= 0)
	BEGIN   
	select distinct studentID as ClientID,StudentName as ClientName from [UI_IrInfoList] order by ClientName Asc
	END
	ELSE IF (@ChldorAdFlag =1)
	BEGIN

			IF(@PgmFlag= 0)
			BEGIN
			select distinct studentID as ClientID,StudentName as ClientName from [UI_IrInfoList] where  clientType = 'Children''s - Day' or clientType = 'Children''s - Residential' or clientType= 'RTF' and SubNumber !='R' order by ClientName Asc

			END
			ELSE
			BEGIN
			select distinct studentID as ClientID,StudentName as ClientName from [UI_IrInfoList] where  clientType = @ProgramName and SubNumber !='R' order by ClientName Asc

			END

	END
	ELSE IF (@ChldorAdFlag =2)
	BEGIN
		IF(@PgmFlag= 0)
			BEGIN

			select distinct studentID as ClientID,StudentName as ClientName from [UI_IrInfoList] where  clientType = '6400 Adult Residential' or clientType = 'ICF/ID ' or clientType= 'Adult - Day Only' and SubNumber !='R' order by ClientName Asc

			END
			ELSE
			BEGIN
			select distinct studentID as ClientID,StudentName as ClientName from [UI_IrInfoList] where  clientType = @ProgramName and SubNumber !='R' order by ClientName Asc

			END


	END
	ELSE IF(@PgmFlag != 0 and @ChldorAdFlag=0)
	BEGIN

	select distinct studentID as ClientID,StudentName as ClientName from [UI_IrInfoList] where  clientType = @ProgramName and SubNumber !='R' order by ClientName Asc
	
	END

	
END


GO
