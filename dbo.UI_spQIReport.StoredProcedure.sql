USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spQIReport]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[UI_spQIReport]
	@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@ChldorAdFlag int
AS
BEGIN
SET NOCOUNT ON;

IF(@ChldorAdFlag != 0)
		   BEGIN
				If(@ChldorAdFlag = 1)
					BEGIN
				Select [IrID],[incidentType],[StudentName],clientType,[LocLvl2Name],irDate,irTime,[IncidentDesc],
						[ProtectionAction],[InvestigationNeeded],[InvestAddInfo],[InvestigatorName]
							,COALESCE([StaffNameOnAL1],'N/A') as StaffNameOnAL1
							  ,COALESCE([StaffNameOnAL2],'N/A') as StaffNameOnAL2
							 ,[InvestigationReportDate]
							  ,[InvestigationReviewDate]
							  ,COALESCE(HROutcome, 'N/A') as HROutcome
							  ,[Outcome]
							  ,[HCSISFinalizedDate]
							  ,[QIComments]
							  ,[CorrectiveAction1]
							  ,[ResponsibleParty1Name]
							  ,[ResponsibleParty1ID]
							  ,[TargetDate1]
							  ,[CompletedDate1]
							  ,[CorrectiveAction2]
							  ,[ResponsibleParty2Name]
							  ,[ResponsibleParty2ID]
							  ,[TargetDate2]
							  ,[CompletedDate2]
							  ,[CorrectiveAction3]
							  ,[ResponsibleParty3Name]
							  ,[ResponsibleParty3ID]
							  ,[TargetDate3]
							  ,[CompletedDate3] from 
						(SELECT DISTINCT
							  [irMainID]
							, STUFF((
								SELECT N', ' + CAST([incidentType] AS VARCHAR(255))
								FROM [UI_IncidentList] f2
								WHERE f1.[irMainID] = f2.[irMainID] and ActiveStatus='A' ---- string with grouping by fileid
								FOR XML PATH ('')), 1, 2, '') AS [incidentType]
						FROM [UI_IncidentList] f1  where ActiveStatus='A' ) t1 
						INNER Join
						(select info.[IrMainID],info.irID,info.[StudentID],[StudentName],info.clientType,info.[LocLvl2Name],info.irDate,info.irTime,info.[IncidentDesc],
						info.[ProtectionAction],[InvestigationNeeded],[InvestAddInfo]
							  ,[InvestigatorName]
							  ,[StaffNameOnAL1]
							  ,[StaffNameOnAL2]
							 ,[InvestigationReportDate]
							  ,[InvestigationReviewDate]
							  ,[HROutcome]
							  ,[Outcome]
							  ,[HCSISFinalizedDate]
							  ,[QIComments]
							  ,[CorrectiveAction1]
							  ,[ResponsibleParty1Name]
							  ,[ResponsibleParty1ID]
							  ,[TargetDate1]
							  ,[CompletedDate1]
							  ,[CorrectiveAction2]
							  ,[ResponsibleParty2Name]
							  ,[ResponsibleParty2ID]
							  ,[TargetDate2]
							  ,[CompletedDate2]
							  ,[CorrectiveAction3]
							  ,[ResponsibleParty3Name]
							  ,[ResponsibleParty3ID]
							  ,[TargetDate3]
							  ,[CompletedDate3] from [UI_IrInfoList] info 
						inner join [UI_QIInvestigation] qi on info.IrMainID=qi.IrMainID) t2
						ON t1.irMainID=t2.irMainID
						where t2.irDate between @str1 and @str2 and (t2.clientType = 'Children''s - Day' or t2.clientType = 'Children''s - Residential' or t2.clientType= 'RTF') and
						t2.[clientType] =IIF(@PgmFlag=0, t2.[clientType],@ProgramName) and
						t2.[StudentID] =IIF(@StudentID=0,t2.[StudentID],@StudentID)			
						order by [IrID] desc
					END
				ELSE IF (@ChldorAdFlag = 2)
					BEGIN
				Select [IrID],[incidentType],[StudentName],clientType,[LocLvl2Name],irDate,irTime,[IncidentDesc],
						[ProtectionAction],[InvestigationNeeded],[InvestAddInfo],[InvestigatorName]
							,COALESCE([StaffNameOnAL1],'N/A') as StaffNameOnAL1
							  ,COALESCE([StaffNameOnAL2],'N/A') as StaffNameOnAL2
							 ,[InvestigationReportDate]
							  ,[InvestigationReviewDate]
							  ,COALESCE(HROutcome, 'N/A') as HROutcome
							  ,[Outcome]
							  ,[HCSISFinalizedDate]
							  ,[QIComments]
							  ,[CorrectiveAction1]
							  ,[ResponsibleParty1Name]
							  ,[ResponsibleParty1ID]
							  ,[TargetDate1]
							  ,[CompletedDate1]
							  ,[CorrectiveAction2]
							  ,[ResponsibleParty2Name]
							  ,[ResponsibleParty2ID]
							  ,[TargetDate2]
							  ,[CompletedDate2]
							  ,[CorrectiveAction3]
							  ,[ResponsibleParty3Name]
							  ,[ResponsibleParty3ID]
							  ,[TargetDate3]
							  ,[CompletedDate3] from 
						(SELECT DISTINCT
							  [irMainID]
							, STUFF((
								SELECT N', ' + CAST([incidentType] AS VARCHAR(255))
								FROM [UI_IncidentList] f2
								WHERE f1.[irMainID] = f2.[irMainID] and ActiveStatus='A' ---- string with grouping by fileid
								FOR XML PATH ('')), 1, 2, '') AS [incidentType]
						FROM [UI_IncidentList] f1  where ActiveStatus='A' ) t1 
						INNER Join
						(select info.[IrMainID],info.irID,info.[StudentID],[StudentName],info.clientType,info.[LocLvl2Name],info.irDate,info.irTime,info.[IncidentDesc],
						info.[ProtectionAction],[InvestigationNeeded],[InvestAddInfo]
							  ,[InvestigatorName]
							  ,[StaffNameOnAL1]
							  ,[StaffNameOnAL2]
							 ,[InvestigationReportDate]
							  ,[InvestigationReviewDate]
							  ,[HROutcome]
							  ,[Outcome]
							  ,[HCSISFinalizedDate]
							  ,[QIComments]
							  ,[CorrectiveAction1]
							  ,[ResponsibleParty1Name]
							  ,[ResponsibleParty1ID]
							  ,[TargetDate1]
							  ,[CompletedDate1]
							  ,[CorrectiveAction2]
							  ,[ResponsibleParty2Name]
							  ,[ResponsibleParty2ID]
							  ,[TargetDate2]
							  ,[CompletedDate2]
							  ,[CorrectiveAction3]
							  ,[ResponsibleParty3Name]
							  ,[ResponsibleParty3ID]
							  ,[TargetDate3]
							  ,[CompletedDate3] from [UI_IrInfoList] info 
						inner join [UI_QIInvestigation] qi on info.IrMainID=qi.IrMainID) t2
						ON t1.irMainID=t2.irMainID
						where t2.irDate between @str1 and @str2 and (t2.clientType = '6400 Adult Residential' or t2.clientType = 'ICF/ID' or t2.clientType= 'Adult - Day Only') and
						t2.[clientType] =IIF(@PgmFlag=0, t2.[clientType],@ProgramName) and
						t2.[StudentID] =IIF(@StudentID=0, t2.[StudentID],@StudentID)			
						order by [IrID] desc
					END
		    END
		ELSE IF(@ChldorAdFlag = 0)
		   BEGIN
		Select [IrID],[incidentType],[StudentName],clientType,[LocLvl2Name],irDate,irTime,[IncidentDesc],
						[ProtectionAction],[InvestigationNeeded],[InvestAddInfo],[InvestigatorName]
							,COALESCE([StaffNameOnAL1],'N/A') as StaffNameOnAL1
							  ,COALESCE([StaffNameOnAL2],'N/A') as StaffNameOnAL2
							 ,[InvestigationReportDate]
							  ,[InvestigationReviewDate]
							  ,COALESCE(HROutcome, 'N/A') as HROutcome
							  ,[Outcome]
							  ,[HCSISFinalizedDate]
							  ,[QIComments]
							  ,[CorrectiveAction1]
							  ,[ResponsibleParty1Name]
							  ,[ResponsibleParty1ID]
							  ,[TargetDate1]
							  ,[CompletedDate1]
							  ,[CorrectiveAction2]
							  ,[ResponsibleParty2Name]
							  ,[ResponsibleParty2ID]
							  ,[TargetDate2]
							  ,[CompletedDate2]
							  ,[CorrectiveAction3]
							  ,[ResponsibleParty3Name]
							  ,[ResponsibleParty3ID]
							  ,[TargetDate3]
							  ,[CompletedDate3] from 
						(SELECT DISTINCT
							  [irMainID]
							, STUFF((
								SELECT N', ' + CAST([incidentType] AS VARCHAR(255))
								FROM [UI_IncidentList] f2
								WHERE f1.[irMainID] = f2.[irMainID] and ActiveStatus='A' ---- string with grouping by fileid
								FOR XML PATH ('')), 1, 2, '') AS [incidentType]
						FROM [UI_IncidentList] f1  where ActiveStatus='A' ) t1 
						INNER Join
						(select info.[IrMainID],info.irID,info.[StudentID],[StudentName],info.clientType,info.[LocLvl2Name],info.irDate,info.irTime,info.[IncidentDesc],
						info.[ProtectionAction],[InvestigationNeeded],[InvestAddInfo]
							  ,[InvestigatorName]
							  ,[StaffNameOnAL1]
							  ,[StaffNameOnAL2]
							 ,[InvestigationReportDate]
							  ,[InvestigationReviewDate]
							  ,[HROutcome]
							  ,[Outcome]
							  ,[HCSISFinalizedDate]
							  ,[QIComments]
							  ,[CorrectiveAction1]
							  ,[ResponsibleParty1Name]
							  ,[ResponsibleParty1ID]
							  ,[TargetDate1]
							  ,[CompletedDate1]
							  ,[CorrectiveAction2]
							  ,[ResponsibleParty2Name]
							  ,[ResponsibleParty2ID]
							  ,[TargetDate2]
							  ,[CompletedDate2]
							  ,[CorrectiveAction3]
							  ,[ResponsibleParty3Name]
							  ,[ResponsibleParty3ID]
							  ,[TargetDate3]
							  ,[CompletedDate3] from [UI_IrInfoList] info 
						inner join [UI_QIInvestigation] qi on info.IrMainID=qi.IrMainID) t2
						ON t1.irMainID=t2.irMainID
						where t2.irDate between @str1 and @str2 and t2.[clientType] =IIF(@PgmFlag=0,t2.[clientType],@ProgramName) and
						t2.[StudentID] =IIF(@StudentID=0, t2.[StudentID],@StudentID)			
						order by [IrID] desc
			
		    END
  
END





GO
