USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spDeleteGV]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ZHT_spDeleteGV]
	@SubmittedDate date,
	@SubmittedTime time,
	@SubmittedByID varchar(50),
	@SubmittedByName varchar(200),
	@ActiveStatus varchar(2),
	@ModID varchar(15),
	@Module varchar(25)
AS
	BEGIN
	if(@Module='BMI')
	BEGIN
	update [ZHT_BMIMainTable] set ActiveStatus=@ActiveStatus where BMIID=@ModID;
	INSERT INTO [dbo].[ZHT_UpdateData] (ModuleName,ModuleID,UpdateFlag,UpdatedByID,UpdatedByName,UpdateDate,UpdateTime) values(@Module,@ModID,@ActiveStatus,@SubmittedByID,@SubmittedByName,@SubmittedDate,@SubmittedTime);
	END
	ELSE if(@Module='ST')
	BEGIN
	UPDATE [ZHT_STMainTable] SET ActiveStatus=@ActiveStatus WHERE STID=@ModID;
	INSERT INTO [dbo].[ZHT_UpdateData] (ModuleName,ModuleID,UpdateFlag,UpdatedByID,UpdatedByName,UpdateDate,UpdateTime) values(@Module,@ModID,@ActiveStatus,@SubmittedByID,@SubmittedByName,@SubmittedDate,@SubmittedTime);
	END
	END

GO
