USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spFIRptNDChrts]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ZHT_spFIRptNDChrts]
	@LocID int,
	@StudentID int,
	@RptStDate date,
	@RptEndDate date,
	@RptNo int
AS
	BEGIN
	if(@RptNo = 1)
	BEGIN
	IF(@StudentID != 0)
	BEGIN
	select F.FIid, F.ClientName, F.LocName, convert(varchar, F.FIDate,101) as FInDate, convert(varchar, F.FITime,100) as FInTime, F.FIOffer, F.FIQty, F.FITypeTxt, F.Comments, F.SubmitName, convert(varchar,F.SubmissionDate,101) as SubmitDate, convert(varchar,F.SubmissionTime,100) as SubmitTime, G.Goal from ZHT_FIMainTable F left join ZHT_FIGoals G on F.FIGoalID=G.GoalID where F.ActiveStatus='A' and F.StudentID= @StudentID and F.FIDate between @RptStDate and @RptEndDate order by FIDate DESC, FITime DESC
	END
	ELSE IF(@LocID != 0)
	BEGIN
	select F.FIid, F.ClientName, F.LocName, convert(varchar, F.FIDate,101) as FInDate, convert(varchar, F.FITime,100) as FInTime, F.FIOffer, F.FIQty, F.FITypeTxt, F.Comments, F.SubmitName, convert(varchar,F.SubmissionDate,101) as SubmitDate, convert(varchar,F.SubmissionTime,100) as SubmitTime, G.Goal 
	from ZHT_FIMainTable F left join ZHT_FIGoals G on F.FIGoalID=G.GoalID 
	where F.ActiveStatus='A' and F.StudentID IN 
	(select S.StudentPersonalId 
	from StudentPersonal S 
	left join Placement P on S.StudentPersonalId=P.StudentPersonalId 
	where StudentType='Client' and P.Location= @LocID and P.Status=1  and s.PlacementStatus='A' 
	and (p.EndDate is null or p.EndDate > GETDATE())) and F.FIDate between @RptStDate and @RptEndDate 
	order by FIDate DESC, FITime DESC
	END
	ELSE
	BEGIN
	select F.FIid, F.ClientName, F.LocName, convert(varchar, F.FIDate,101) as FInDate, convert(varchar, F.FITime,100) as FInTime, F.FIOffer, F.FIQty, F.FITypeTxt, F.Comments, F.SubmitName, convert(varchar,F.SubmissionDate,101) as SubmitDate, convert(varchar,F.SubmissionTime,100) as SubmitTime, G.Goal from ZHT_FIMainTable F left join ZHT_FIGoals G on F.FIGoalID=G.GoalID where F.ActiveStatus='A' and F.FIDate between @RptStDate and @RptEndDate order by FIDate DESC, FITime DESC
	END
	END

	ELSE if(@RptNo = 2)
	begin
	DECLARE @FirstDate DATE 
	DECLARE @LastDate DATE 
	set @FirstDate = @RptStDate
	set @LastDate = @RptEndDate

	DECLARE @CalendarMonths TABLE(CaID INT IDENTITY(1,1) PRIMARY KEY,cdate date)
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
where M.StudentID=@StudentID and M.FIDate between @RptStDate and @RptEndDate and M.ActiveStatus='A' 
group by m.FIDate, G.Goal, M.FIDate  
order by  m.FIDate


Select cm.CaID,CAST(cm.cdate As nvarchar(50)) as cdate, fi.TotQty, fi.Goal from @CalendarMonths cm LEFT outer join #TempFIMain fi 
on cm.cdate=fi.FIDate order by cdate

drop table #TempFIMain
end
	END
GO
