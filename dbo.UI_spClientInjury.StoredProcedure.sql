USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spClientInjury]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UI_spClientInjury]
	@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@ChldorAdFlag int
AS
BEGIN

	IF(@ChldorAdFlag != 0)
	BEGIN
		IF(@ChldorAdFlag = 1)
		BEGIN
		SELECT I.irID,I.clientType, I.StudentName, convert(varchar,I.irDate,101) as irDt, convert(varchar,I.irTime,100) as irTimed, I.LocLvl1Name, I.LocLvl2Name, I.LocLvl3Name,I.SubmittedByName, I.SubmittedToSupervisorName,
I.ClientSustainInjuryQ,  J.BIRBehaviorInjury, J.BIRPMPInjury, J.BIRInjuryType, J.BIRInjuryLvl, J.TreatProv, N.InjLoc, N.InjBodyPart,
N.InjBodySide, N.InjColor, N.InjShape, N.InjSize, N.InjDesc, I.IncidentDesc, I.ProtectionAction, I.InfoNotcaptured 
FROM UI_IrInfoList I
INNER JOIN UI_Injury J ON I.IrMainID=J.IrMainID 
INNER JOIN UI_NumOfInjuries N ON J.InjuryID = N.InjuryID 
WHERE I.ActiveStatus='A' AND N.ActiveStatus='A' and I.irDate between @str1 and @str2 and (I.clientType = 'Children''s - Day' or I.clientType = 'Children''s - Residential' or I.clientType= 'RTF') and I.[clientType] =IIF(@PgmFlag=0, I.[clientType],@ProgramName) and
						I.[StudentID] =IIF(@StudentID=0,I.[StudentID],@StudentID) order by I.IrMainID desc
		END
		IF(@ChldorAdFlag = 2)
		BEGIN
		SELECT I.irID,I.clientType, I.StudentName,  convert(varchar,I.irDate,101) as irDt,convert(varchar,I.irTime,100) as irTimed, I.LocLvl1Name, I.LocLvl2Name, I.LocLvl3Name,I.SubmittedByName, I.SubmittedToSupervisorName,
I.ClientSustainInjuryQ,  J.BIRBehaviorInjury, J.BIRPMPInjury, J.BIRInjuryType, J.BIRInjuryLvl, J.TreatProv, N.InjLoc, N.InjBodyPart,
N.InjBodySide, N.InjColor, N.InjShape, N.InjSize, N.InjDesc, I.IncidentDesc, I.ProtectionAction, I.InfoNotcaptured 
FROM UI_IrInfoList I
INNER JOIN UI_Injury J ON I.IrMainID=J.IrMainID 
INNER JOIN UI_NumOfInjuries N ON J.InjuryID = N.InjuryID 
WHERE I.ActiveStatus='A' AND N.ActiveStatus='A' and I.irDate between @str1 and @str2 and (I.clientType = '6400 Adult Residential' or I.clientType = 'ICF/ID' or I.clientType= 'Adult - Day Only') and I.[clientType] =IIF(@PgmFlag=0, I.[clientType],@ProgramName) and
						I.[StudentID] =IIF(@StudentID=0,I.[StudentID],@StudentID) order by I.IrMainID desc
		END
	END
	IF(@ChldorAdFlag = 0)
	BEGIN
	SELECT I.irID,I.clientType, I.StudentName,  convert(varchar,I.irDate,101) as irDt, convert(varchar,I.irTime,100) as irTimed, I.LocLvl1Name, I.LocLvl2Name, I.LocLvl3Name,I.SubmittedByName, I.SubmittedToSupervisorName,
I.ClientSustainInjuryQ,  J.BIRBehaviorInjury, J.BIRPMPInjury, J.BIRInjuryType, J.BIRInjuryLvl, J.TreatProv, N.InjLoc, N.InjBodyPart,
N.InjBodySide, N.InjColor, N.InjShape, N.InjSize, N.InjDesc, I.IncidentDesc, I.ProtectionAction, I.InfoNotcaptured 
FROM UI_IrInfoList I
INNER JOIN UI_Injury J ON I.IrMainID=J.IrMainID 
INNER JOIN UI_NumOfInjuries N ON J.InjuryID = N.InjuryID 
WHERE I.ActiveStatus='A' AND N.ActiveStatus='A' and I.irDate between @str1 and @str2 and I.[clientType] =IIF(@PgmFlag=0, I.[clientType],@ProgramName) and I.[StudentID] =IIF(@StudentID=0,I.[StudentID],@StudentID) order by I.IrMainID desc
	END

END
GO
