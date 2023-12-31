USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spFIDataUpdates]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ZHT_spFIDataUpdates]
@LocID   INT,
@LocName    VARCHAR (150),
@StudentID      INT, 
@ClientName     VARCHAR (100),
@FIDate         DATE,
@FITime         TIME (7),
@FIQty          INT,
@Comments  VARCHAR(MAX),
@SubmittedID    INT,
@SubmitName     VARCHAR (100),
@SubmissionDate DATE,
@SubmissionTime TIME (7),
@FormStatus VARCHAR(1),
@ActiveStatus   VARCHAR (1),
@FIID INT,
@FIOffer INT,
@FITypeVal VARCHAR(5),
@FITypeTxt VARCHAR(10)

AS
BEGIN

declare @GoalID int
IF(@FIID=0)
BEGIN
SET @GoalID = (SELECT GoalID FROM ZHT_FIGoals WHERE StudentID=@StudentID AND ActiveStatus='A');

INSERT INTO [ZHT_FIMainTable] 
(LocID, LocName, StudentID, ClientName, FIDate, FITime, FIQty, Comments, SubmittedID, SubmitName, SubmissionDate, SubmissionTime, FormStatus,ActiveStatus, FIGoalID,FIOffer,FITypeVal,FITypeTxt) VALUES 
(@LocID, @LocName, @StudentID, @ClientName, @FIDate, @FITime, @FIQty, @Comments, @SubmittedID, @SubmitName, @SubmissionDate, @SubmissionTime, @FormStatus,@ActiveStatus, @GoalID,@FIOffer,@FITypeVal,@FITypeTxt);

SET @FIID = (select SCOPE_IDENTITY());

END
ELSE
BEGIN
UPDATE ZHT_FIMainTable SET FIQty=@FIQty, FIDate=@FIDate, FITime=@FITime, Comments=@Comments, ActiveStatus=@ActiveStatus, FormStatus=@FormStatus,FIOffer = @FIOffer,FITypeVal=@FITypeVal,FITypeTxt=@FITypeTxt WHERE FIid=@FIID;
END
INSERT INTO [ZHT_UpdateData] (ModuleName, ModuleID, UpdateFlag, UpdatedByID, UpdatedByName, UpdateDate, UpdateTime) VALUES ('FI',@FIID,@FormStatus,@SubmittedID,@SubmitName,@SubmissionDate,@SubmissionTime);

END
GO
