USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spPMPList]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UI_spPMPList]
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
select  I.irID,I.clientType, I.StudentName, convert(varchar,I.irDate,101) as irDt, convert(varchar,I.irTime,100) as irTimed, 
I.LocLvl1Name, I.LocLvl2Name, I.LocLvl3Name,I.SubmittedByName, I.SubmittedToSupervisorName,
I.ClientSustainInjuryQ, I.IncidentDesc, I.ProtectionAction, I.InfoNotcaptured,P.TypeOfPMP,convert(varchar,P.TimeOfPMP,100) as PMPTime, P.ClientInjury, CONCAT(P.DurationPMPMin,':',P.DurationPMPSec) AS PMPDuration, P.NumOfStaff, P.NameStaffPMP 
from UI_IrInfoList I 
join UI_BIWithRest B on B.IRMainID=I.IrMainID
join UI_PMP P on P.BWR_ID=B.BWR_ID 
where I.ActiveStatus='A' and P.ActiveStatus='A' and I.irDate between @str1 and @str2 and (I.clientType = 'Children''s - Day' or I.clientType = 'Children''s - Residential' or I.clientType= 'RTF') and I.[clientType] =IIF(@PgmFlag=0, I.[clientType],@ProgramName) and
						I.[StudentID] =IIF(@StudentID=0,I.[StudentID],@StudentID) order by I.IrMainID desc
		END
		IF(@ChldorAdFlag = 2)
		BEGIN
		select  I.irID,I.clientType, I.StudentName, convert(varchar,I.irDate,101) as irDt, convert(varchar,I.irTime,100) as irTimed, 
I.LocLvl1Name, I.LocLvl2Name, I.LocLvl3Name,I.SubmittedByName, I.SubmittedToSupervisorName,
I.ClientSustainInjuryQ, I.IncidentDesc, I.ProtectionAction, I.InfoNotcaptured,P.TypeOfPMP,convert(varchar,P.TimeOfPMP,100) as PMPTime, P.ClientInjury, CONCAT(P.DurationPMPMin,':',P.DurationPMPSec) AS PMPDuration, P.NumOfStaff, P.NameStaffPMP 
from UI_IrInfoList I 
join UI_BIWithRest B on B.IRMainID=I.IrMainID
join UI_PMP P on P.BWR_ID=B.BWR_ID 
where I.ActiveStatus='A' and P.ActiveStatus='A' and I.irDate between @str1 and @str2 and (I.clientType = '6400 Adult Residential' or I.clientType = 'ICF/ID' or I.clientType= 'Adult - Day Only') and I.[clientType] =IIF(@PgmFlag=0, I.[clientType],@ProgramName) and
						I.[StudentID] =IIF(@StudentID=0,I.[StudentID],@StudentID) order by I.IrMainID desc
		END
	END
	IF(@ChldorAdFlag = 0)
	BEGIN
	select  I.irID,I.clientType, I.StudentName, convert(varchar,I.irDate,101) as irDt, convert(varchar,I.irTime,100) as irTimed, 
I.LocLvl1Name, I.LocLvl2Name, I.LocLvl3Name,I.SubmittedByName, I.SubmittedToSupervisorName,
I.ClientSustainInjuryQ, I.IncidentDesc, I.ProtectionAction, I.InfoNotcaptured,P.TypeOfPMP,convert(varchar,P.TimeOfPMP,100) as PMPTime, P.ClientInjury, CONCAT(P.DurationPMPMin,':',P.DurationPMPSec) AS PMPDuration, P.NumOfStaff, P.NameStaffPMP 
from UI_IrInfoList I 
join UI_BIWithRest B on B.IRMainID=I.IrMainID
join UI_PMP P on P.BWR_ID=B.BWR_ID 
where I.ActiveStatus='A' and P.ActiveStatus='A' and I.irDate between @str1 and @str2 and I.[clientType] =IIF(@PgmFlag=0, I.[clientType],@ProgramName) and I.[StudentID] =IIF(@StudentID=0,I.[StudentID],@StudentID) 
order by I.IrMainID desc
	END

END
GO
