USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spRepReject]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[UI_spRepReject]
		@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@ChldorAdFlag int
		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF(@ChldorAdFlag != 0)
		   BEGIN
				If(@ChldorAdFlag = 1)
					BEGIN
					SELECT [irID],[irDate],[irTime],StudentName,SubmittedByName,[clientType],[LocLvl1Name],[LocLvl2Name],[LocLvl3Name],SubmittedToSupervisorName,[RejectionReason],[RejectedByName] FROM [UI_IrInfoList]  where ActiveStatus='A' and subNumber='R' and [irDate] between @str1 and @str2 and (clientType = 'Children''s - Day' or clientType = 'Children''s - Residential' or clientType= 'RTF') and
					[clientType] =IIF(@PgmFlag=0, [clientType], @ProgramName) and
					[StudentID] =IIF(@StudentID=0, [StudentID],@StudentID)
					
					order by [IrID] desc
					END
				ELSE IF (@ChldorAdFlag = 2)
					BEGIN
					SELECT [irID],[irDate],[irTime],StudentName,SubmittedByName,[clientType],[LocLvl1Name],[LocLvl2Name],[LocLvl3Name],SubmittedToSupervisorName,[RejectionReason],[RejectedByName] FROM [UI_IrInfoList]  where ActiveStatus='A' and subNumber='R' and [irDate] between @str1 and @str2 and (clientType = '6400 Adult Residential' or clientType = 'ICF/ID' or clientType= 'Adult - Day Only') and
					[clientType] =IIF(@PgmFlag=0, [clientType], @ProgramName) and
					[StudentID] =IIF(@StudentID=0, [StudentID],@StudentID)
					
					 order by [IrID] desc
					END
		    END
		ELSE IF(@ChldorAdFlag = 0)
		   BEGIN
					SELECT [irID],[irDate],[irTime],StudentName,SubmittedByName,[clientType],[LocLvl1Name],[LocLvl2Name],[LocLvl3Name],SubmittedToSupervisorName,[RejectionReason],[RejectedByName] FROM [UI_IrInfoList]  where ActiveStatus='A' and subNumber='R' and [irDate] between @str1 and @str2  and
					[clientType] =IIF(@PgmFlag=0, [clientType], @ProgramName) and
					[StudentID] =IIF(@StudentID=0, [StudentID],@StudentID)
					
					order by [IrID] desc
			
		    END
  


END

GO
