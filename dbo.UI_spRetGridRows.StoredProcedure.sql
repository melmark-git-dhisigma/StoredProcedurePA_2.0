USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spRetGridRows]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UI_spRetGridRows]
	@MainID int,
	@QueryID varchar(50)
AS

BEGIN

	IF @QueryID='allegedGrid'
	BEGIN
	SELECT A.AbuseNeglect_ID as AbuseNeglectID,A.[StaffMemberName] as [Staff Member], A.[StaffPosition] as [Position] from [UI_AbuseNeglectWitness] A INNER JOIN [UI_IncidentList] I on A.[incidentListID]=I.[incidentListID] where A.[irMainID] = @MainID and I.[incidentType]='abuse' and A.ActiveStatus='A';
	END

	ELSE IF @QueryID='allegedNeglectGrid'
	BEGIN
	SELECT A.AbuseNeglect_ID as AbuseNeglectID,A.[StaffMemberName] as [Staff Member], A.[StaffPosition] as [Position] from [UI_AbuseNeglectWitness] A INNER JOIN [UI_IncidentList] I on A.[incidentListID]=I.[incidentListID] where A.[irMainID] = @MainID and I.[incidentType]='neglect' and A.ActiveStatus='A';
	END

	ELSE IF @QueryID='gridPMPMainTable'
	BEGIN
	SELECT pmp.[PMPID] as PMPID, pmp.[TypeOfPMP] as [Type Of PMP],convert(varchar,pmp.[TimeOfPMP],100) as [Time of Day],pmp.ClientInjury as [Client Injured in PMP],CONCAT(RIGHT(CONCAT('0', [DurationPMPMin]), 2),':',RIGHT(CONCAT('0', [DurationPMPSec]), 2)) as [Duration (Min:Sec)],pmp.[NumOfStaff] as [No of Staff],pmp.[NameStaffPMP] as [Staff involved in PMP] FROM UI_PMP pmp INNER JOIN [UI_BIWithRest] BI on pmp.BWR_ID=BI.BWR_ID where [irMainID] = @MainID and ActiveStatus='A';
	END

	ELSE IF @QueryID='gridAddIndInjury'
	BEGIN
	SELECT [NumOfInjID],[InjLoc] as [Injury Location],[InjBodyPart] as [Body Part with Injury],[InjBodySide] as [Body Side], [InjColor] AS [Injury Color],[InjShape] as [Injury Shape],[InjSize] as [Injury Size],InjDesc as [Injury Description] FROM [UI_NumOfInjuries] where [InjuryID] = @MainID;
	END

	ELSE IF @QueryID='gridAdditionalNotification'
	BEGIN
	SELECT [InjStaffNotiID],[StaffAddInfo] as Staff,CONVERT(varchar(10),AddNotiDate) as [Date Of Notification] FROM [UI_InjStaffAddNotify] where [InjuryID] = @MainID and [ActiveStatus]='A';
	END

	ELSE IF @QueryID='gridAddAIRITS'
	BEGIN
	SELECT [NursNumOfInjID],[NurLoc] as [Injury Location],[NurBodyPart] as [Body Part with Injury],[NurBodySide] as [Body Side], [NursNumOfInjITS] AS [No Of Injuries],[NursInjTypeITS] as [Injury Type],[NursInjSeverityITS] as [Severity Of Injury],NursInjComments as [Comments] FROM [UI_NursNumOfInjuries] where [InjuryID] = @MainID and ActiveStatus='A';
	END
	
	ELSE IF @QueryID='gridAddPHDrAppointment'
	BEGIN
	SELECT ERAppoinmentID, CONVERT(VARCHAR(10),[AptDate]) as [Appointment Date],[AptDrName] as [Name of the Doctor],[AptOutcome] as [Appointment Outcome] FROM [UI_ERAppointment] where [irMainID] = @MainID and ActiveStatus='A';
	END

	ELSE IF @QueryID='gridAddPHMedicationChanges'
	BEGIN
	SELECT ERMedChangesID, [MedicationName] as [Name of the Medication],[MedicationChanges] as [Changes that were Noted and Explained] FROM [UI_ERMedChanges] where [irMainID] = @MainID and activestatus='A'
	END

	ELSE IF @QueryID='gridStaffWitness'
	BEGIN
	SELECT AbuseNeglect_ID as AbuseNeglectID,StaffMemberName as [Staff Member] ,StaffPosition as Position FROM UI_AbuseNeglectWitness where [irMainID] = @MainID and [incidentListID] IS NULL and ActiveStatus='A';
	END

	ELSE IF @QueryID='gridStaffInjuries'
	BEGIN
	SELECT StaffInjuryID, StaffName as [Staff Member Injured] ,[InjuryLevel] as [Injury Level],[InjuryDueToBehavior] as [Injury Due To Behavior],[InjuryDueToPMP] as [Injury Due To PMP],[PMPResultedInjury] as [PMP which resulted in Injury] FROM [UI_StaffInjury] where [irMainID] = @MainID and ActiveStatus='A';
	END

	ELSE IF @QueryID='familyNotificationGrid'
	BEGIN
	SELECT Fam_ID as FamID, [FamMemberName] as [Family Member],[ClientRelation] as [Relationship To The Client],[NotifiedByStaffName] as [Notified By], CONVERT(varchar(10),FamNotificationDate,101) AS [Date Of Notification],convert(varchar(10),[FamNotificationTime],100) as [Time Of Notification],[NotificationType] as [Type Of Notification] FROM [UI_FamilyNote] where [irMainID] = @MainID and ActiveStatus='A'
	END

	ELSE IF @QueryID='externalNotifyGrid'
	BEGIN
	SELECT ExtNotify_ID as ExtNotifyID,ExtPersonName as [External Person],OrgName as Organization,ExtNotifyBy as [Notified By],CONVERT(varchar(10),ExtNotifyDate) as [Date Of Notification],convert(varchar,ExtNotifyTime,100) as [Time Of Notification],ExtNotifyType as [Type Of Notification] FROM UI_ExtNotify where [irMainID] = @MainID and ActiveStatus='A';
	END

	ELSE IF @QueryID = 'gridStatusUpdate'
	BEGIN
	SELECT StatusUpdateID, CONVERT(varchar(10),StatusDate) as [Status Date] ,[StaffName] as [Status Updated By],[StatusUpdateDetail] as [Status Details] FROM [UI_StatusUpdate] where [IrMainID] = @MainID and ActiveStatus='A';
	END
	
END



/****** Object:  StoredProcedure [dbo].[spSubmitIR]    Script Date: 1/7/2021 9:55:14 AM ******/
SET ANSI_NULLS ON
GO
