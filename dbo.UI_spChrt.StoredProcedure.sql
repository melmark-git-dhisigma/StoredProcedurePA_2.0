USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spChrt]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UI_spChrt]
		@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@chrtnumber int
AS
BEGIN

	SET NOCOUNT ON;

	If(@chrtnumber = 1)
	BEGIN
	select * from(select st.[InjuryLevel],st.PMPResultedInjury
	from [UI_StaffInjury] st 
	inner join [UI_IrInfoList] info on st.IRMainID=info.IrMainID 
	where info.ActiveStatus='A' and st.ActiveStatus='A' and st.[InjuryDueToPMP]='Yes' and info.irDate between @str1 AND @str2
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID))As SourceTable 
	PIVOT (Count([InjuryLevel]) FOR InjuryLevel IN ([Minor (First Aid Only)],[Major (Beyond First Aid)],[No Staff Injury])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 2)
	BEGIN
	select * from (select pmp.TypeOfPMP,Inj.[BIRInjuryLvl] from [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_Injury] Inj on Inj.[irMainID]=bi.IRMainID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID 
	where info.[ActiveStatus]='A' and pmp.ClientInjury='yes' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A' 
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)) As SourceTable 	
	PIVOT (Count(BIRInjuryLvl) FOR BIRInjuryLvl IN ([First Aid Only],[Beyond First Aid])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 3)
	BEGIN
	
	select * from (select info.StudentName, pmp.TypeOfPMP,ROUND((CAST([DurationPMPMin] AS float)+ CAST([DurationPMPSec] AS float)/60),2) as duration from [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID 
	where info.[ActiveStatus]='A' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A'
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)) As SourceTable 
	PIVOT (Sum(Duration) FOR TypeOfPMP IN ([Helmet Application],[1 Person Stability Hold],[2 Person Stability Hold],[Floor Seated Stability Hold],[1 Person Stability Hold (Seated in a Vehicle)],[Carry],[Chair Stability Hold],[Supine (Face-Up) Hold],[Smaller Person Stability Hold],[2 Person Reverse Transport - Front Entry],[2 Person Reverse Transport - Back Entry],[2 Person Forward Transport])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 4)
	BEGIN
	select * from (select info.StudentName, pmp.TypeOfPMP from [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID 
	where info.[ActiveStatus]='A' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A'
		and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)) As SourceTable 
	PIVOT (Count(TypeOfPMP) FOR TypeOfPMP IN ([Helmet Application],[1 Person Stability Hold],[2 Person Stability Hold],[Floor Seated Stability Hold],[1 Person Stability Hold (Seated in a Vehicle)],[Carry],[Chair Stability Hold],[Supine (Face-Up) Hold],[Smaller Person Stability Hold],[2 Person Reverse Transport - Front Entry],[2 Person Reverse Transport - Back Entry],[2 Person Forward Transport])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 5)
	BEGIN
	select * from (select info.[LocLvl2Name], pmp.TypeOfPMP from [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID where info.[ActiveStatus]='A' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A'
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)) As SourceTable 
	PIVOT (Count(TypeOfPMP) FOR TypeOfPMP IN ([Helmet Application],[1 Person Stability Hold],[2 Person Stability Hold],[Floor Seated Stability Hold],[1 Person Stability Hold (Seated in a Vehicle)],[Carry],[Chair Stability Hold],[Supine (Face-Up) Hold],[Smaller Person Stability Hold],[2 Person Reverse Transport - Front Entry],[2 Person Reverse Transport - Back Entry],[2 Person Forward Transport])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 6)
	BEGIN
	select * from (select info.LocLvl2Name, pmp.TypeOfPMP,ROUND((CAST([DurationPMPMin] AS float)+ CAST([DurationPMPSec] AS float)/60),2) as Duration from [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID where info.[ActiveStatus]='A' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A'
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)) As SourceTable 
	PIVOT (Sum(Duration) FOR TypeOfPMP IN ([Helmet Application],[1 Person Stability Hold],[2 Person Stability Hold],[Floor Seated Stability Hold],[1 Person Stability Hold (Seated in a Vehicle)],[Carry],[Chair Stability Hold],[Supine (Face-Up) Hold],[Smaller Person Stability Hold],[2 Person Reverse Transport - Front Entry],[2 Person Reverse Transport - Back Entry],[2 Person Forward Transport])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 7)
	BEGIN
	select * from (select pmp.TypeOfPMP,info.clientType, month(info.irdate) as mont,YEAR(info.irdate) as yr from [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID where info.[ActiveStatus]='A' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A'
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)) As SourceTable 
	PIVOT (Count(TypeOfPMP) FOR clientType IN ([Children's - Day],[Children's - Residential],[RTF],[6400 Adult Residential],[ICF/ID],[Adult - Day Only])) AS PivotTa
	END
	ELSE IF(@chrtnumber = 8)
	BEGIN
	select pmp.TypeOfPMP as TypeOfPMP,Count(TypeOfPMP)  as Number FROM [UI_PMP] pmp 
	inner join [UI_BIWithRest] bi on pmp.[BWR_ID]=bi.BWR_ID 
	inner join [UI_IrInfoList] info on bi.IRMainID=info.IrMainID 
	inner join [UI_LookupTable] look on info.[clientType]=look.ddlText where info.[ActiveStatus]='A' and info.irDate between @str1 AND @str2 and pmp.ActiveStatus='A'
	and info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName)
	and info.[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID)
	and look.[qualifyingID]='clientType' and look.activeStatus=1  group by pmp.TypeOfPMP
	END

    
END
GO
