USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spSTRpt]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ZHT_spSTRpt]	
	@StudentID int,
	@RptStDate date,
	@RptEndDate date
	
AS
	
	begin
	DECLARE @FirstDate DATE 
	DECLARE @LastDate DATE 
	DECLARE @TimeHr int	

	set @FirstDate = DATEFROMPARTS(year(@RptStDate),month(@RptStDate),1)	 
	set @LastDate = DATEFROMPARTS(year(@RptEndDate),month(@RptEndDate),1)
	set @TimeHr = 0



	DECLARE @CalendarMonths TABLE(CaID INT IDENTITY(1,1) PRIMARY KEY,cdate date, cmmyy varchar(20), TopTimeHr int)
	WHILE @TimeHr<24
	BEGIN
	
	INSERT @CalendarMonths VALUES( @FirstDate, FORMAT(@FirstDate, 'MMM-yyyy'),@TimeHr)
	set @TimeHr = @TimeHr+1
	END

WHILE @FirstDate < @LastDate
BEGIN
SET @FirstDate = DATEADD(MONTH,1, @FirstDate)
Set @TimeHr = 0;

--INSERT @CalendarMonths VALUES( @FirstDate, FORMAT(@FirstDate, 'MMM-yyyy'))

WHILE @TimeHr<24
	BEGIN	
	INSERT @CalendarMonths VALUES( @FirstDate, FORMAT(@FirstDate, 'MMM-yyyy'),@TimeHr)
	set @TimeHr = @TimeHr+1
	END

END



set @TimeHr=0
DECLARE @24HrTbl TABLE (TimeID INT IDENTITY(1,1) PRIMARY KEY, Interval int)
WHILE @TimeHr<24
	BEGIN	
	INSERT @24HrTbl VALUES( @TimeHr)
	set @TimeHr = @TimeHr+1

	END


CREATE TABLE #TempSTMain([STYear] int, [STMonth] int, [STMnthYr] varchar(12),[STTopHr] int, [STCount] int)
insert into #TempSTMain

select YEAR(STDate) YEARoF, MONTH(STDate) MonthOF, FORMAT(STDate,'MMM-yyyy') as STMntYr,DATEPART(hh,sttime) as TopHrs,COUNT(*) STTot
from ZHT_STMainTable 
where StudentID=@StudentID and STDate between @RptStDate and @RptEndDate 
group by YEAR(STDate), MONTH(STDate), DATEPART(hh,sttime),FORMAT(STDate,'MMM-yyyy')

select AVG(STCount) as AvgST from #TempSTMain


select IntYear, IntMonth,STMntYr, [0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23] from
(select YEAR(cm.cdate) as IntYear, MONTH(cm.cdate) as IntMonth, CM.cmmyy as STMntYr,cast(CM.TopTimeHr as varchar) as IntTime,FI.STCount from @CalendarMonths CM 
LEFT JOIN #TempSTMain FI ON CM.cmmyy=FI.STMnthYr AND CM.TopTimeHr=FI.STTopHr) p 
pivot 
(sum(STCount) for IntTime in ([0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23])) as  pvt 
order by pvt.IntYear,pvt.IntMonth


drop table #TempSTMain


end
GO
