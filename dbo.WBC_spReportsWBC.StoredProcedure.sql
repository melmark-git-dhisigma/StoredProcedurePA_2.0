USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[WBC_spReportsWBC]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[WBC_spReportsWBC]
	@ClientID int,
	@ClassId int, 
	@StartDate date,
	@EndDate date
AS
	BEGIN

	IF @ClientID<>0
	BEGIN
select W.ClientName as [Client Name],W.LabelID, L7.BodyPartIDLvl1 as [Body Level 1], L7.BodyPartIDLvl2 as [Body Level 2], L7.BodyPartIDLvl3 as [Body Level 3], L7.LabelLocFtorBk as [Body View], W.IdentifiedInitials as [Identified Initials], convert(varchar(15),W.IdentifiedDate,101) as [Identified Date],convert(varchar(15),W.IdentifiedTime,100) as [Identified Time], W.SubmittedByName as [Submitted By], L2.DdlText as [Family Notified], convert(varchar(15),W.FamilyNotifyDate,101) as [Family Notify Date], convert(varchar(15), W.FamilyNotifyTime,100) as [Family Notify Time], L3.DdlText as [UIR Entered], W.UIRNumber as [UIR Number], convert(varchar(15),W.UIDate,101) as [UI Date], convert(varchar(15), W.UITime,100) as [UI Time], L4.DdlText as [Nurse Notified], W.NurseNotifyName as [Nurse Name], convert(varchar(15),W.NurseNotifyDate,101) as [Nurse Notify Date], convert(varchar(15),W.NurseNotifyTime,100) as [Nurse Notify Time], L5.DdlText as [Admin Notified], W.AdminNotifyName as [Admin Name], convert(varchar(15),W.AdminNotifyDate,101) as [Admin Notify Date], convert(varchar(15),W.AdminNotifyTime,100) as [Admin Notify Time], W.InjuryLocText as [Injury Loc], W.InjuryOriginText as [Injury Origin], W.InjuryTypeText as [Injury Type], L6.DdlText as [SI Trauma Completed],W.AdditionalNotes as [Additional Notes], L1.DdlText as [WBC Status], convert(varchar(15),W.SubmittedByDate,101) as [Submitted Date], convert(varchar(15),W.SubmittedByTime,100) as [Submitted Time] 
	from WBC_MainDataTable W 
	join WBC_LookupTable L1 on w.WBCStatus = L1.DdlValue
	join WBC_LookupTable L2 on W.FamilyNotify=L2.DdlValue 
	join WBC_LookupTable L3 on W.UICompleted=L3.DdlValue 
	join WBC_LookupTable L4 on W.NurseNotify=L4.DdlValue
	join WBC_LookupTable L5 on W.AdminNotify=L5.DdlValue 
	join WBC_LookupTable L6 on W.SITrauma=L6.DdlValue 
	join WBC_LookupTable L7 on W.LabelID=L7.LabelNo
	where L1.QualifyingID= 'WBCStatus' and L2.QualifyingID='WBCFlags' and L3.QualifyingID='WBCFlags' 
	and L4.QualifyingID='WBCFlags' and L5.QualifyingID='WBCFlags' and L6.QualifyingID='WBCFlags' 
	and W.ActiveStatus='A' and W.StudentID =@ClientID  AND IdentifiedDate BETWEEN @StartDate AND @EndDate order by IdentifiedDate asc
	END

	ELSE IF @ClientID=0 
	BEGIN
select W.ClientName as [Client Name],W.LabelID, L7.BodyPartIDLvl1 as [Body Level 1], L7.BodyPartIDLvl2 as [Body Level 2], L7.BodyPartIDLvl3 as [Body Level 3], L7.LabelLocFtorBk as [Body View], W.IdentifiedInitials as [Identified Initials], convert(varchar(15),W.IdentifiedDate,101) as [Identified Date],convert(varchar(15),W.IdentifiedTime,100) as [Identified Time], W.SubmittedByName as [Submitted By], L2.DdlText as [Family Notified], convert(varchar(15),W.FamilyNotifyDate,101) as [Family Notify Date], convert(varchar(15), W.FamilyNotifyTime,100) as [Family Notify Time], L3.DdlText as [UIR Entered], W.UIRNumber as [UIR Number], convert(varchar(15),W.UIDate,101) as [UI Date], convert(varchar(15), W.UITime,100) as [UI Time], L4.DdlText as [Nurse Notified], W.NurseNotifyName as [Nurse Name], convert(varchar(15),W.NurseNotifyDate,101) as [Nurse Notify Date], convert(varchar(15),W.NurseNotifyTime,100) as [Nurse Notify Time], L5.DdlText as [Admin Notified], W.AdminNotifyName as [Admin Name], convert(varchar(15),W.AdminNotifyDate,101) as [Admin Notify Date], convert(varchar(15),W.AdminNotifyTime,100) as [Admin Notify Time], W.InjuryLocText as [Injury Loc], W.InjuryOriginText as [Injury Origin], W.InjuryTypeText as [Injury Type], L6.DdlText as [SI Trauma Completed],W.AdditionalNotes as [Additional Notes], L1.DdlText as [WBC Status], convert(varchar(15),W.SubmittedByDate,101) as [Submitted Date], convert(varchar(15),W.SubmittedByTime,100) as [Submitted Time]
	from WBC_MainDataTable W 
	join WBC_LookupTable L1 on w.WBCStatus = L1.DdlValue
	join WBC_LookupTable L2 on W.FamilyNotify=L2.DdlValue 
	join WBC_LookupTable L3 on W.UICompleted=L3.DdlValue 
	join WBC_LookupTable L4 on W.NurseNotify=L4.DdlValue
	join WBC_LookupTable L5 on W.AdminNotify=L5.DdlValue 
	join WBC_LookupTable L6 on W.SITrauma=L6.DdlValue 
	join WBC_LookupTable L7 on W.LabelID=L7.LabelNo
	where L1.QualifyingID= 'WBCStatus' and L2.QualifyingID='WBCFlags' and L3.QualifyingID='WBCFlags' 
	and L4.QualifyingID='WBCFlags' and L5.QualifyingID='WBCFlags' and L6.QualifyingID='WBCFlags' 
	and W.ActiveStatus='A' and W.StudentID in (select S.StudentPersonalId as ClientName 
	from StudentPersonal S left join Placement P on S.StudentPersonalId=P.StudentPersonalId 
	where StudentType='Client' and P.Location=@ClassId and P.Status=1  
	and s.PlacementStatus='A' and (p.EndDate is null or p.EndDate > GETDATE()))  AND IdentifiedDate BETWEEN @StartDate AND @EndDate
	order by IdentifiedDate asc
	END

	END

GO
