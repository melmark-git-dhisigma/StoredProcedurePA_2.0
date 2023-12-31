USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spAllUIWithoutDates]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UI_spAllUIWithoutDates]
		
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
				If(@ChldorAdFlag = 1)
					BEGIN
						select N.irID, N.IrMainID, N.clientType,t1.IncidentList ,N.StudentID,N.StudentName, IIF(t1.TotPMPCnt=0,NULL,t1.TotPMPCnt) as CntPmp, REPLACE((REPLACE(t1.PMPType,CHAR(13),' ')),CHAR(10),' ') as Restraint,iif(t1.TotPMPSec>0,concat(Format(t1.TotPMPSec/60,'0#'), ':', Format(t1.TotPMPSec%60,'0#')),NULL) as TotPMPDur, 
IIF(t1.TotStInj=0,NULL,t1.TotStInj) as CntStInj, REPLACE((REPLACE(t1.StaffInjuries,CHAR(13),' ')),CHAR(10),' ') AS StInj, 
IIF(t1.TotIndInjury=0,NULL,t1.TotIndInjury) as CntIndInj, REPLACE((REPLACE(t1.IndInjuries,CHAR(13),' ')),CHAR(10),' ') AS IndInj, CONVERT(varchar,N.irDate,101) as UIRDate, convert(varchar,N.irTime,100) as UIRTime, N.LocLvl1Name, N.LocLvl2Name, N.LocLvl3Name, N.SubmittedByName, N.SubmittedToSupervisorName, 
REPLACE((REPLACE(N.IncidentDesc,CHAR(13),' ')),CHAR(10),' ') as IRDesc, REPLACE((REPLACE(N.ProtectionAction,CHAR(13),' ')),CHAR(10),' ') as ProtectAction, REPLACE((REPLACE(N.InfoNotcaptured,CHAR(13),' ')),CHAR(10),' ') as InfoNtCaptured, Y.BIRBehaviorInjury, Y.BIRPMPInjury, N.StaffInjuryQ, N.ClientSustainInjuryQ from 
(SELECT 
 I.IrMainID, Results.BWR_ID, 
  STUFF((SELECT ';  ' + TypeOfPMP  
    FROM UI_PMP M
    WHERE (M.BWR_ID = Results.BWR_ID and M.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS PMPType,

(SELECT ((SUM(CAST(DurationPMPMin as int)))*60 + SUM(CAST(DurationPMPSec as int)))
FROM UI_PMP P1 
WHERE (P1.BWR_ID = Results.BWR_ID AND P1.ActiveStatus='A')) AS TotPMPSec,

STUFF((SELECT '; ' + IncidentTypeDesc  
    FROM UI_IncidentList IL
    WHERE (IL.irMainID = I.irMainID and IL.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS IncidentList,

  STUFF((SELECT '; ' + StaffName FROM UI_StaffInjury S1
    WHERE (S1.irMainID = S.irMainID and S1.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS StaffInjuries,

	(SELECT COUNT(DISTINCT PMPID)
FROM UI_PMP P2
WHERE (P2.BWR_ID = Results.BWR_ID AND P2.ActiveStatus='A')) AS TotPMPCnt,

	(SELECT COUNT(DISTINCT s2.StaffInjuryID) 
	FROM UI_StaffInjury S2 
	WHERE (S2.irMainID = S.irMainID and S2.ActiveStatus='A')) AS TotStInj,

	(select COUNT(DISTINCT NI1.NumOfInjID) from UI_NumOfInjuries NI1 WHERE (NI1.InjuryID = NI2.InjuryID and NI1.ActiveStatus='A')) AS TotIndInjury,
	   
	STUFF((SELECT ';  Injury Loc: ' + InjLoc  + ' | Body Part: ' + CAST(InjBodyPart AS VARCHAR(MAX)) + ' | Body Side: ' + CAST(InjBodySide AS VARCHAR(MAX))  
    FROM UI_NumOfInjuries NI
    WHERE (NI.InjuryID = NI2.InjuryID and NI.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS IndInjuries
FROM UI_IrInfoList I 
left join UI_Injury Inj1 on I.IrMainID=Inj1.IrMainID
left join UI_NumOfInjuries NI2 on Inj1.InjuryID=NI2.InjuryID 
left join UI_StaffInjury S on I.IrMainID=s.irMainID
 left join UI_BIWithRest B on I.IrMainID=B.IRMainID
 left join UI_PMP Results on B.BWR_ID=Results.BWR_ID 
where I.irDate between @str1 and @str2 and (I.clientType = 'Children''s - Day' or I.clientType = 'Children''s - Residential' or I.clientType= 'RTF')  and I.[clientType] =IIF(@PgmFlag=0, I.[clientType], @ProgramName) 
   and I.[StudentID] =IIF(@StudentID=0, I.[StudentID],@StudentID) and I.ActiveStatus='A' 
GROUP BY Results.BWR_ID,I.IrMainID,S.irMainID,NI2.InjuryID) t1 
inner join UI_IrInfoList N on N.IrMainID=t1.IrMainID 
left join  UI_Injury Y on N.IrMainID=Y.IrMainID
where N.ActiveStatus='A' 
order by N.IrMainID desc						

					END
				ELSE IF (@ChldorAdFlag = 2)
					BEGIN
					select N.irID, N.IrMainID, N.clientType,t1.IncidentList ,N.StudentID,N.StudentName, IIF(t1.TotPMPCnt=0,NULL,t1.TotPMPCnt) as CntPmp, REPLACE((REPLACE(t1.PMPType,CHAR(13),' ')),CHAR(10),' ') as Restraint,iif(t1.TotPMPSec>0, concat(Format(t1.TotPMPSec/60,'0#'), ':', Format(t1.TotPMPSec%60,'0#')),NULL) as TotPMPDur, 
IIF(t1.TotStInj=0,NULL,t1.TotStInj) as CntStInj, REPLACE((REPLACE(t1.StaffInjuries,CHAR(13),' ')),CHAR(10),' ') AS StInj, 
IIF(t1.TotIndInjury=0,NULL,t1.TotIndInjury) as CntIndInj, REPLACE((REPLACE(t1.IndInjuries,CHAR(13),' ')),CHAR(10),' ') AS IndInj, CONVERT(varchar,N.irDate,101) as UIRDate, convert(varchar,N.irTime,100) as UIRTime, N.LocLvl1Name, N.LocLvl2Name, N.LocLvl3Name, N.SubmittedByName, N.SubmittedToSupervisorName, 
REPLACE((REPLACE(N.IncidentDesc,CHAR(13),' ')),CHAR(10),' ') as IRDesc, REPLACE((REPLACE(N.ProtectionAction,CHAR(13),' ')),CHAR(10),' ') as ProtectAction, REPLACE((REPLACE(N.InfoNotcaptured,CHAR(13),' ')),CHAR(10),' ') as InfoNtCaptured, Y.BIRBehaviorInjury, Y.BIRPMPInjury, N.StaffInjuryQ, N.ClientSustainInjuryQ from 
(SELECT 
 I.IrMainID, Results.BWR_ID, 
  STUFF((SELECT '; ' + TypeOfPMP 
    FROM UI_PMP M
    WHERE (M.BWR_ID = Results.BWR_ID and M.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS PMPType,

(SELECT ((SUM(CAST(DurationPMPMin as int)))*60 + SUM(CAST(DurationPMPSec as int)))
FROM UI_PMP P1 
WHERE (P1.BWR_ID = Results.BWR_ID AND P1.ActiveStatus='A')) AS TotPMPSec,

STUFF((SELECT '; ' + IncidentTypeDesc  
    FROM UI_IncidentList IL
    WHERE (IL.irMainID = I.irMainID and IL.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS IncidentList,
  STUFF((SELECT '; ' + StaffName FROM UI_StaffInjury S1
    WHERE (S1.irMainID = S.irMainID and S1.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS StaffInjuries,

	(SELECT COUNT(DISTINCT PMPID)
FROM UI_PMP P2
WHERE (P2.BWR_ID = Results.BWR_ID AND P2.ActiveStatus='A')) AS TotPMPCnt,

	(SELECT COUNT(DISTINCT s2.StaffInjuryID) 
	FROM UI_StaffInjury S2 
	WHERE (S2.irMainID = S.irMainID and S2.ActiveStatus='A')) AS TotStInj,

	(select COUNT(DISTINCT NI1.NumOfInjID) from UI_NumOfInjuries NI1) AS TotIndInjury,
	
	STUFF((SELECT ';  Injury Loc: ' + InjLoc  + ' | Body Part: ' + CAST(InjBodyPart AS VARCHAR(MAX)) + ' | Body Side: ' + CAST(InjBodySide AS VARCHAR(MAX))  
    FROM UI_NumOfInjuries NI
    WHERE (NI.InjuryID = NI2.InjuryID and NI.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS IndInjuries
FROM UI_IrInfoList I 
left join UI_Injury Inj1 on I.IrMainID=Inj1.IrMainID
left join UI_NumOfInjuries NI2 on Inj1.InjuryID=NI2.InjuryID 
left join UI_StaffInjury S on I.IrMainID=s.irMainID
 left join UI_BIWithRest B on I.IrMainID=B.IRMainID
 left join UI_PMP Results on B.BWR_ID=Results.BWR_ID 
where I.irDate between @str1 and @str2 and (I.clientType = '6400 Adult Residential' or I.clientType = 'ICF/ID' or I.clientType= 'Adult - Day Only')  and I.[clientType] =IIF(@PgmFlag=0, I.[clientType], @ProgramName) 
   and I.[StudentID] =IIF(@StudentID=0, I.[StudentID],@StudentID) and I.ActiveStatus='A' 
GROUP BY Results.BWR_ID,I.IrMainID,S.irMainID,NI2.InjuryID) t1 
inner join UI_IrInfoList N on N.IrMainID=t1.IrMainID 
left join  UI_Injury Y on N.IrMainID=Y.IrMainID
where N.ActiveStatus='A' 
order by N.IrMainID desc						

				
					END
		    END
		ELSE IF(@ChldorAdFlag = 0)
		   BEGIN

					select N.irID, N.IrMainID, N.clientType,t1.IncidentList ,N.StudentID,N.StudentName, IIF(t1.TotPMPCnt=0,NULL,t1.TotPMPCnt) as CntPmp, REPLACE((REPLACE(t1.PMPType,CHAR(13),' ')),CHAR(10),' ') as Restraint,iif(t1.TotPMPSec>0,concat(Format(t1.TotPMPSec/60,'0#'), ':', Format(t1.TotPMPSec%60,'0#')),NULL) as TotPMPDur, 
IIF(t1.TotStInj=0,NULL,t1.TotStInj) as CntStInj, REPLACE((REPLACE(t1.StaffInjuries,CHAR(13),' ')),CHAR(10),' ') AS StInj, 
IIF(t1.TotIndInjury=0,NULL,t1.TotIndInjury) as CntIndInj, REPLACE((REPLACE(t1.IndInjuries,CHAR(13),' ')),CHAR(10),' ') AS IndInj, CONVERT(varchar,N.irDate,101) as UIRDate, convert(varchar,N.irTime,100) as UIRTime, N.LocLvl1Name, N.LocLvl2Name, N.LocLvl3Name, N.SubmittedByName,  N.SubmittedToSupervisorName, 
REPLACE((REPLACE(N.IncidentDesc,CHAR(13),' ')),CHAR(10),' ') as IRDesc, REPLACE((REPLACE(N.ProtectionAction,CHAR(13),' ')),CHAR(10),' ') as ProtectAction, REPLACE((REPLACE(N.InfoNotcaptured,CHAR(13),' ')),CHAR(10),' ') as InfoNtCaptured, Y.BIRBehaviorInjury, Y.BIRPMPInjury, N.StaffInjuryQ, N.ClientSustainInjuryQ from 
(SELECT 
 I.IrMainID, Results.BWR_ID, 
  STUFF((SELECT '; ' + TypeOfPMP 
    FROM UI_PMP M
    WHERE (M.BWR_ID = Results.BWR_ID and M.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS PMPType,

(SELECT ((SUM(CAST(DurationPMPMin as int)))*60 + SUM(CAST(DurationPMPSec as int)))
FROM UI_PMP P1 
WHERE (P1.BWR_ID = Results.BWR_ID AND P1.ActiveStatus='A')) AS TotPMPSec,

STUFF((SELECT '; ' + IncidentTypeDesc  
    FROM UI_IncidentList IL
    WHERE (IL.irMainID = I.irMainID and IL.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS IncidentList,

  STUFF((SELECT '; ' + StaffName 
    FROM UI_StaffInjury S1
    WHERE (S1.irMainID = S.irMainID and S1.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)'),1,2,'') AS StaffInjuries,

	(SELECT COUNT(DISTINCT PMPID)
FROM UI_PMP P2
WHERE (P2.BWR_ID = Results.BWR_ID AND P2.ActiveStatus='A')) AS TotPMPCnt,

	(SELECT COUNT(DISTINCT s2.StaffInjuryID) 
	FROM UI_StaffInjury S2 
	WHERE (S2.irMainID = S.irMainID and S2.ActiveStatus='A')) AS TotStInj,

	(select COUNT(DISTINCT NI1.NumOfInjID) from UI_NumOfInjuries NI1 WHERE (NI1.InjuryID = NI2.InjuryID and NI1.ActiveStatus='A')) AS TotIndInjury,

	STUFF((SELECT ';  Injury Loc: ' + InjLoc  + ' | Body Part: ' + CAST(InjBodyPart AS VARCHAR(MAX)) + ' | Body Side: ' + CAST(InjBodySide AS VARCHAR(MAX)) 
    FROM UI_NumOfInjuries NI
    WHERE (NI.InjuryID = NI2.InjuryID and NI.ActiveStatus='A') 
    FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)') ,1,2,'') AS IndInjuries

FROM UI_IrInfoList I 
left join UI_Injury Inj1 on I.IrMainID=Inj1.IrMainID
left join UI_NumOfInjuries NI2 on Inj1.InjuryID=NI2.InjuryID 
left join UI_StaffInjury S on I.IrMainID=s.irMainID
 left join UI_BIWithRest B on I.IrMainID=B.IRMainID
 left join UI_PMP Results on B.BWR_ID=Results.BWR_ID 
where I.irDate between @str1 and @str2 and I.[clientType] =IIF(@PgmFlag=0, I.[clientType], @ProgramName) 
   and I.[StudentID] =IIF(@StudentID=0, I.[StudentID],@StudentID) and I.ActiveStatus='A' 
GROUP BY Results.BWR_ID,I.IrMainID,S.irMainID,NI2.InjuryID) t1 
inner join UI_IrInfoList N on N.IrMainID=t1.IrMainID 
left join  UI_Injury Y on N.IrMainID=Y.IrMainID
where N.ActiveStatus='A' 
order by N.IrMainID desc
			
		    END
  

END
GO
