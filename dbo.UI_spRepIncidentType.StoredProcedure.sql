USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spRepIncidentType]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UI_spRepIncidentType]
		@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@ChldorAdFlag int,
		@str6 varchar(100)
AS
BEGIN
		SET NOCOUNT ON;

		IF(@ChldorAdFlag != 0)
		   BEGIN
				If(@ChldorAdFlag = 1)
					BEGIN
					SELECT ir.[irID],ir.[irDate],ir.[irTime],ir.StudentName,ir.SubmittedByName,ir.[clientType],ir.[LocLvl1Name],ir.[LocLvl2Name],ir.[LocLvl3Name],ir.SubmittedToSupervisorName,IP.[incidentType] 
					FROM [UI_IrInfoList] ir inner join [UI_IncidentList] IP on ir.[IrMainID]=IP.[IrMainID] 
					where ir.ActiveStatus='A' and ip.[ActiveStatus]='A' and Ip.[incidentType]=@str6 and ir.[irDate] between @str1 and @str2 and (ir.clientType = 'Children''s - Day' or ir.clientType = 'Children''s - Residential' or ir.clientType= 'RTF') and
					[clientType] =IIF(@PgmFlag=0, [clientType], @ProgramName) and
					[StudentID] =IIF(@StudentID=0, [StudentID],@StudentID)
					 order by [IrID] desc
					END
				ELSE IF (@ChldorAdFlag = 2)
					BEGIN

						SELECT ir.[irID],ir.[irDate],ir.[irTime],ir.StudentName,ir.SubmittedByName,ir.[clientType],ir.[LocLvl1Name],ir.[LocLvl2Name],ir.[LocLvl3Name],ir.SubmittedToSupervisorName,IP.[incidentType] 
					FROM [UI_IrInfoList] ir inner join [UI_IncidentList] IP on ir.[IrMainID]=IP.[IrMainID] 
					where ir.ActiveStatus='A' and ip.[ActiveStatus]='A' and Ip.[incidentType]=@str6 and ir.[irDate] between @str1 and @str2 and  (ir.clientType = '6400 Adult Residential' or ir.clientType = 'ICF/ID' or ir.clientType= 'Adult - Day Only')  and
					[clientType] =IIF(@PgmFlag=0, [clientType], @ProgramName) and
					[StudentID] =IIF(@StudentID=0, [StudentID],@StudentID)
					 order by [IrID] desc
					END
		    END
		ELSE IF(@ChldorAdFlag = 0)
		   BEGIN
				  SELECT ir.[irID],ir.[irDate],ir.[irTime],ir.StudentName,ir.SubmittedByName,ir.[clientType],ir.[LocLvl1Name],ir.[LocLvl2Name],ir.[LocLvl3Name],ir.SubmittedToSupervisorName,IP.[incidentType] 
		  FROM [UI_IrInfoList] ir inner join [UI_IncidentList] IP on ir.[IrMainID]=IP.[IrMainID] 
		  where ir.ActiveStatus='A' and ip.[ActiveStatus]='A' and Ip.[incidentType]=@str6 and ir.[irDate] between @str1 and @str2 and
		  	[clientType] =IIF(@PgmFlag=0, [clientType], @ProgramName) and
			[StudentID] =IIF(@StudentID=0, [StudentID],@StudentID)
		  
		   order by [IrID] desc
			
		    END
  
END



GO
