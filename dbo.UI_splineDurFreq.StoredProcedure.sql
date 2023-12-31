USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_splineDurFreq]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[UI_splineDurFreq]
		@str1 datetime,
		@str2 datetime,
		@StudentID int,
		@ProgramName nvarchar(Max),
		@PgmFlag int
	
AS
BEGIN
	
	SET NOCOUNT ON;
		DECLARE @firstresult TABLE (mont int,yea int,Val int, Duration float, Average float)
		insert into @firstresult
		select TMonth,TYear,COUNT(*) as val,SUM(Duration) as Duration,SUM(Duration)/COUNT(*) as Average from (select MONTH(irDate) as TMonth,YEAR(irDate) as TYear,ROUND((CAST(pm.[DurationPMPMin] AS float)+ CAST(pm.[DurationPMPSec] AS float)/60),2) as Duration from UI_PMP pm inner join UI_BIWithRest bwr on pm.BWR_ID=bwr.BWR_ID
		inner join [UI_IrInfoList] info on bwr.IRMainID=info.IrMainID
		inner join UI_IncidentTypeIReport irrep  on info.IncidentTypesID=irrep.IncidentTypesID  where info.irDate between @str1 AND @str2 and irrep.birWRest=1 and info.ActiveStatus= 'A' and pm.ActiveStatus='A' and
		info.[clientType] =IIF(@PgmFlag=0,info.[clientType],@ProgramName) and
		[StudentID] =IIF(@StudentID=0, info.[StudentID],@StudentID))itemnames Group by TYear,TMonth order by TYear,TMonth

		DECLARE @FirstDate DATE = @str1
		DECLARE @LastDate Date = @str2
		DECLARE @CalendarMonths TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,cdate date)
		INSERT @CalendarMonths VALUES( @FirstDate)
		WHILE @FirstDate < @LastDate
		BEGIN
		SET @FirstDate = DATEADD( day,1, @FirstDate)
		INSERT @CalendarMonths VALUES( @FirstDate)
		END
		DECLARE @AllMonths TABLE (MID INT IDENTITY(1,1) PRIMARY KEY,Mn int,yr int)
		insert into @AllMonths select month(cdate),YEAR(cdate) from @CalendarMonths

		DECLARE @Finaltbl TABLE (Mn int,yr int)
		insert into @Finaltbl select Mn,yr from @AllMonths group by Mn,yr 

		
		select ft.Mn as TMonth,ft.yr as TYear,ISNULL(fr.Val,0) as val,ISNULL(ROUND(CAST(fr.Duration AS float),2),0) as Duration,ISNULL(ROUND(CAST(fr.Average AS float),2),0) AS Average from @Finaltbl ft 
		left join @firstresult fr on ft.Mn=fr.mont AND ft.yr=fr.yea order by ft.yr,ft.Mn asc

  

END




GO
