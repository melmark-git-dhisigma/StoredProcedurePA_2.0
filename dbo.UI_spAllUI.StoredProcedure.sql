USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spAllUI]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UI_spAllUI]

@firstdate datetime,
@seconddate datetime

AS
BEGIN

Select [IrID],[incidentType],[StudentName],clientType,irDate,irTime,[IncidentDesc],[LocLvl1Name],[LocLvl2Name]
      ,[LocLvl3Name],[ProtectionAction],[StaffInjuryQ],[ClientSustainInjuryQ]
 from 
(SELECT DISTINCT
      [irMainID]
    , STUFF((
        SELECT N', ' + CAST([incidentType] AS VARCHAR(255))
        FROM [UI_IncidentList] f2
        WHERE f1.[irMainID] = f2.[irMainID] and ActiveStatus='A'---- string with grouping by fileid
        FOR XML PATH ('')), 1, 2, '') AS [incidentType]
FROM [UI_IncidentList] f1 where ActiveStatus='A') t1
INNER Join
[UI_IrInfoList] t2
ON t1.irMainID=t2.irMainID where t2.irDate between @firstdate AND @seconddate and t2.ActiveStatus='A'


END
GO
