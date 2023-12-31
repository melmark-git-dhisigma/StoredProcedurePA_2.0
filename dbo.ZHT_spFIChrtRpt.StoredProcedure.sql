USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spFIChrtRpt]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ZHT_spFIChrtRpt]
	@StudentID int,
	@RptStDate date,
	@RptEndDate date
AS
	BEGIN
	
	DECLARE @FirstDate DATE 
	DECLARE @LastDate DATE 
	set @FirstDate = @RptStDate
	set @LastDate = @RptEndDate

	DECLARE @CalendarMonths TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,cdate date)
INSERT @CalendarMonths VALUES( @FirstDate)
WHILE @FirstDate < @LastDate
BEGIN
SET @FirstDate = DATEADD(day,1, @FirstDate)
INSERT @CalendarMonths VALUES( @FirstDate)
END

Create Table #TempFIMain ([FIDate] date,[TotQty] int, [Goal] int)
	insert into #TempFIMain
select M.FIDate,sum(M.FIQty) as TotQty, G.Goal from ZHT_FIMainTable M 
left join ZHT_FIGoals G on M.FIGoalID=G.GoalID 
where M.StudentID=@StudentID and M.FIDate between @RptStDate and @rptEndDate and M.ActiveStatus='A' 
group by m.FIDate, G.Goal, M.FIDate  
order by  m.FIDate


Select cm.id,CAST(cm.cdate As nvarchar(50)) as cdate, fi.TotQty, fi.Goal from @CalendarMonths cm LEFT outer join #TempFIMain fi 
on cm.cdate=fi.FIDate order by cdate

drop table #TempFIMain

	END
GO
