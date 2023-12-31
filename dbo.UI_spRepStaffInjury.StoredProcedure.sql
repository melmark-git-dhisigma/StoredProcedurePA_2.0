USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spRepStaffInjury]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

--22Oct20 Added Cols for InjuryDueToBehavior and InjuryDueToPMP
--22Oct20 Added Cols for PMPResultedInjury
--04Apr22 Added filter for Staff Name
--15Apr22 Fixed Children's Query removed extra where clause of studentid

CREATE PROCEDURE [dbo].[UI_spRepStaffInjury]
		@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@ChldorAdFlag int,
		@StaffID int
	
AS
BEGIN

	SET NOCOUNT ON;

	IF(@ChldorAdFlag != 0)
		   BEGIN
				If(@ChldorAdFlag = 1)
					BEGIN
				SELECT ir.[irID],CONVERT(varchar,ir.irDate,101) as UIRDate,CONVERT(varchar,ir.[irTime],100) AS UITime,ir.StudentName,ir.SubmittedByName,ir.[clientType],ir.[LocLvl1Name],ir.[LocLvl2Name],ir.[LocLvl3Name], ir.SubmittedToSupervisorName, st.[StaffName], st.InjuryLevel, st.InjuryDueToBehavior, st.InjuryDueToPMP, st.PMPResultedInjury  
					FROM [UI_IrInfoList] ir inner join [UI_StaffInjury] st on ir.[IrMainID]=st.[IrMainID] where ir.ActiveStatus='A' and st.ActiveStatus='A' and [irDate] between @str1 and @str2 and (ir.clientType = 'Children''s - Day' or ir.clientType = 'Children''s - Residential' or ir.clientType= 'RTF') and
					ir.[clientType] =IIF(@PgmFlag=0, ir.[clientType], @ProgramName) and
					ir.[StudentID] =IIF(@StudentID=0, ir.[StudentID],@StudentID) and 
					st.[StaffID] = IIF(@StaffID=0,st.[StaffID],@StaffID)
					order by ir.[IrID] desc
					END
				ELSE IF (@ChldorAdFlag = 2)
					BEGIN
					SELECT ir.[irID], CONVERT(varchar,ir.irDate,101) as UIRDate, CONVERT(varchar,ir.[irTime],100) AS UITime, ir.StudentName, ir.SubmittedByName, ir.[clientType], ir.[LocLvl1Name], ir.[LocLvl2Name], ir.[LocLvl3Name], ir.SubmittedToSupervisorName, st.[StaffName], st.InjuryLevel, st.InjuryDueToBehavior, st.InjuryDueToPMP, st.PMPResultedInjury  
					FROM [UI_IrInfoList] ir inner join [UI_StaffInjury] st on ir.[IrMainID]=st.[IrMainID] where ir.ActiveStatus='A' and st.ActiveStatus='A' and [irDate] between @str1 and @str2 and (ir.clientType = '6400 Adult Residential' or ir.clientType = 'ICF/ID' or ir.clientType= 'Adult - Day Only') and 
					ir.[clientType] =IIF(@PgmFlag=0, ir.[clientType], @ProgramName) and
					ir.[StudentID] =IIF(@StudentID=0, ir.[StudentID],@StudentID) and 
					st.[StaffID] = IIF(@StaffID=0,st.[StaffID],@StaffID)
					 order by ir.[IrID] desc
					END
		    END
		ELSE IF(@ChldorAdFlag = 0)
		   BEGIN
				SELECT ir.[irID], CONVERT(varchar,ir.irDate,101) as UIRDate, CONVERT(varchar,ir.[irTime],100) AS UITime, ir.StudentName, ir.SubmittedByName, ir.[clientType], ir.[LocLvl1Name], ir.[LocLvl2Name], ir.[LocLvl3Name], ir.SubmittedToSupervisorName, st.[StaffName], st.InjuryLevel, st.InjuryDueToBehavior, st.InjuryDueToPMP, st.PMPResultedInjury  
				FROM [UI_IrInfoList] ir inner join [UI_StaffInjury] st on ir.[IrMainID]=st.[IrMainID] where ir.ActiveStatus='A' and st.ActiveStatus='A' and [irDate] between @str1 and @str2 and
				ir.[clientType] =IIF(@PgmFlag=0, ir.[clientType], @ProgramName) and
				ir.[StudentID] =IIF(@StudentID=0,ir.[StudentID],@StudentID) and 
				st.[StaffID] = IIF(@StaffID=0,st.[StaffID],@StaffID)
			
			order by ir.[IrID] desc
			
		    END


END


GO
