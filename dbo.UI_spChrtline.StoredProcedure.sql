USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spChrtline]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Khyati Desai
-- Create date: March 30, 2021
-- Description:	Line Charts for student and staff injuries
-- =============================================
CREATE PROCEDURE [dbo].[UI_spChrtline]
		@StDate datetime,
		@EndDate datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int,
		@ChrtNo int
AS
BEGIN

	SET NOCOUNT ON;
	IF (@ChrtNo=1)
	BEGIN
	select count(case when U.ClientSustainInjuryQ='Yes' then 1 end) as IndInjury,COUNT(case when I.birpmpinjuryval='yes' then 1 end) as pmpInjury,MONTH(irDate) as TMonth,YEAR(irDate) as TYear 
from UI_IrInfoList U 
inner join UI_Injury I on U.IrMainID=I.IrMainID 
inner join UI_IncidentTypeIReport R on U.IncidentTypesID=R.IncidentTypesID 
where U.ClientSustainInjuryQ='Yes' and U.ActiveStatus='A' 
and U.irDate between @StDate and @EndDate 
and U.clientType =IIF(@PgmFlag=0,U.clientType,@ProgramName) 
and U.StudentID =IIF(@StudentID=0, U.StudentID,@StudentID)
Group by YEAR(irDate),MONTH(irDate) order by YEAR(irDate),MONTH(irDate)

	END
	if(@ChrtNo=2)
	BEGIN
	select count(S.irmainid) as StaffInjury,
count(case when S.InjuryDueToPMP='Yes' then 1 end) as PMPInjury,
count(case when S.InjuryDueToBehavior='Yes' then 1 end) as BehInjury, 
MONTH(I.irDate) as TMonth,YEAR(I.irDate) as TYear
from UI_IrInfoList I 
inner join UI_StaffInjury S on I.IrMainID=S.irMainID 
where I.irDate between @StDate and @EndDate 
and S.ActiveStatus='A' and I.ActiveStatus='A' 
and I.clientType =IIF(@PgmFlag=0,I.clientType,@ProgramName) 
and I.StudentID =IIF(@StudentID=0, I.StudentID,@StudentID)
Group by YEAR(irDate),MONTH(irDate) 
order by YEAR(irDate),MONTH(irDate)
END

    
END
GO
