USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spDelGridRows]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UI_spDelGridRows]
	@MainID int,
	@QueryID varchar(50)
AS
BEGIN

	IF @QueryID='allegedGrid'
	BEGIN
	UPDATE UI_AbuseNeglectWitness SET ActiveStatus='D' WHERE AbuseNeglect_ID=@MainID;	
	END

	ELSE IF @QueryID='allegedNeglectGrid'
	BEGIN
	UPDATE UI_AbuseNeglectWitness SET ActiveStatus='D' WHERE AbuseNeglect_ID=@MainID;	
	END

	ELSE IF @QueryID='gridPMPMainTable'
	BEGIN
	Update UI_PMP set ActiveStatus='D' where PMPID=@MainID;
	END

	ELSE IF @QueryID='gridAddIndInjury'
	BEGIN	
	UPDATE UI_NumOfInjuries SET ActiveStatus='D' WHERE NumOfInjID=@MainID;
	END

	ELSE IF @QueryID='gridAdditionalNotification'
	BEGIN	
	UPDATE UI_InjStaffAddNotify SET ActiveStatus='D' WHERE InjStaffNotiID = @MainID;
	END

	ELSE IF @QueryID='gridAddAIRITS'
	BEGIN	
	UPDATE [UI_NursNumOfInjuries] SET ActiveStatus='D' WHERE NursNumOfInjID = @MainID;
	END
	
	ELSE IF @QueryID='gridAddPHDrAppointment'
	BEGIN	
	UPDATE [UI_ERAppointment] SET ActiveStatus='D' where ERAppoinmentID = @MainID;
	END

	ELSE IF @QueryID='gridAddPHMedicationChanges'
	BEGIN	
	UPDATE [UI_ERMedChanges] SET activestatus='D' where ERMedChangesID = @MainID;
	END

	ELSE IF @QueryID='gridStaffWitness'
	BEGIN	
	UPDATE UI_AbuseNeglectWitness SET ActiveStatus='D' where AbuseNeglect_ID = @MainID;
	END

	ELSE IF @QueryID='gridStaffInjuries'
	BEGIN	
	UPDATE UI_StaffInjury SET ActiveStatus='D' where StaffInjuryID=@MainID;
	END

	ELSE IF @QueryID='familyNotificationGrid'
	BEGIN
	UPDATE UI_FamilyNote SET ActiveStatus='D' WHERE Fam_ID=@MainID;	
	END

	ELSE IF @QueryID='externalNotifyGrid'
	BEGIN
	UPDATE UI_ExtNotify SET ActiveStatus='D' WHERE ExtNotify_ID=@MainID;	
	END

	ELSE IF @QueryID = 'gridStatusUpdate'
	BEGIN
	update UI_StatusUpdate set ActiveStatus='D' where StatusUpdateID=@MainID;
	END
	
	
END
GO
