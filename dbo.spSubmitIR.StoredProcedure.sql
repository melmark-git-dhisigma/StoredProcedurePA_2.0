USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spSubmitIR]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spSubmitIR]
@clientType varchar(50),
@studentName varchar(100),
@studentFirstName varchar(50),
@studentLastName varchar(50),
@irdate date,
@irTime time,
@LocLvl1Name varchar(50),
@LocLvl2Name varchar(50),
@LocLvl3Name varchar(50),
@IncidentTypesID int,
@SubmissionDate date,
@SubmissionTime time,
@IncidentDesc varchar(max),
@ProtectionAction varchar(max),
@IRWitnessQ varchar(50),
@StaffInjuryQ varchar(50),
@ClientSustainInjuryQ varchar(50),
@SubmittedForQ varchar(50),
@SubmittedToFirstName varchar(50),
@SubmittedToLastName varchar (50),
@familyNotificationQ varchar(50),
@ExtNotificatonQ varchar(50),
@InfoNotcaptured varchar(max), 
@SubmittedForFName varchar(50),
@SubmittedForLName varchar(50),
@SubmittedForFullName varchar(100),
@FamNotNotifiedReason varchar(50),
@FamNotNotifiedOtherReason varchar(max),
@AggressorStudentName varchar(100),
@AggressorStudentFName varchar(50),
@AggressorStudentLName varchar(50),
@FallRiskAssessment varchar(50),
@SuicideVal varchar(15),
@SuicideText varchar(20),
@SubmittedByFName varchar(50),
@SubmittedByLName varchar(50),
@SubNumber varchar(2),
@NoEmailFName varchar(50),
@NoEmailLName varchar(50),
@NoEmailDate date,
@NoEmailTime time(7),
@NoEmail bit,
@FROI bit

AS
BEGIN
declare @StudentPersonalId int,
@SubmitToSupervisorID int, 
@SubmitForID int, 
@aggressorID int,
@SubmitByID int,
@NoEmailID int

select @StudentPersonalId = (select StudentPersonalId from StudentPersonal where FirstName = @studentFirstName and LastName=@studentLastName and PlacementStatus='A' and StudentType='Client')
select @SubmitToSupervisorID = (select UserId from [User] where UserFName = @SubmittedToFirstName and UserLName=@SubmittedToLastName and ActiveInd='A')
select @SubmitForID = (select UserId from [User] where UserFName = @SubmittedForFName and UserLName=@SubmittedForLName and ActiveInd='A')
select @SubmitByID = (select UserId from [User] where UserFName = @SubmittedByFName and UserLName=@SubmittedByLName and ActiveInd='A')
select @aggressorID = (select StudentPersonalId from StudentPersonal where FirstName = @AggressorStudentFName and LastName = @AggressorStudentLName and PlacementStatus='A' and StudentType='Client')
select @NoEmailID = (select UserId from [User] where UserFName = @NoEmailFName and UserLName=@NoEmailLName and ActiveInd='A')


INSERT INTO [dbo].[UI_IrInfoList]
           ([clientType],[StudentID],[StudentName],[irDate],[irTime],[LocLvl1Name],[LocLvl2Name],[LocLvl3Name]
           ,[IncidentTypesID],[SubmissionDate],[SubmissionTime],[IncidentDesc],[ProtectionAction],
		   [SubmittedTo],[SubmittedToSupervisorName],[IRWitnessQ],[StaffInjuryQ],
		   [ClientSustainInjuryQ],[SubmittedForQ],[familyNotificationQ],[ExtNotifyQ],[InfoNotcaptured],
		   [SubmittedFor],[SubmittedForName],[FamNotNotifiedReason],[FamNotNotifiedOtherReason],[AggressorStudentID],[AggressorStudentName],[FallRiskAssessment],[SuicideVal],[SuicideText],[Submittedby],[SubmittedByName],[SubNumber],[ActiveStatus],[NoEmail],[NoEmailSubmitID],[NoEmailSubmitName],[NoEmailDate],[NoEmailTime],[FROI])
     
select @clientType,@StudentPersonalId,@studentName,@irdate, @irTime, @LocLvl1Name, @LocLvl2Name, @LocLvl3Name, @IncidentTypesID,
@SubmissionDate, @SubmissionTime, @IncidentDesc, @ProtectionAction,
 @SubmitToSupervisorID,(select @SubmittedToFirstName + ' ' + @SubmittedToLastName) as SubmitToSupervisorName, 
@IRWitnessQ,@StaffInjuryQ,@ClientSustainInjuryQ,@SubmittedForQ,@familyNotificationQ,@ExtNotificatonQ,
@InfoNotcaptured,@SubmitForID,@SubmittedForFullName,@FamNotNotifiedReason,@FamNotNotifiedOtherReason,@aggressorID,@AggressorStudentName,@FallRiskAssessment, @SuicideVal, @SuicideText, @SubmitByID, (select @SubmittedByFName + ' ' + @SubmittedByLName) as SubmittedByName, @SubNumber,'A',@NoEmail,@NoEmailID,(select @NoEmailFName + ' ' + @NoEmailLName),@NoEmailDate,@NoEmailTime,@FROI


declare @mainID int
select @mainID = SCOPE_IDENTITY()

INSERT INTO UI_UpdateData (irMainID,updateDate,updateTime,updatedByID,updatedByName,reportFlag)   select @mainID, @SubmissionDate, @SubmissionTime, @SubmitByID, (select @SubmittedByFName + ' ' + @SubmittedByLName) as updateName, @SubNumber


RETURN @mainID

END
GO
