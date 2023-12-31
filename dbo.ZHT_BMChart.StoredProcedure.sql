USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_BMChart]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[ZHT_BMChart]
	@str1 date,
	@str2 date,
	@StudentID int

AS
BEGIN

	SET NOCOUNT ON;

DECLARE @FirstDate DATE 
	DECLARE @LastDate DATE 
	set @FirstDate = @str1
	set @LastDate = @str2


DECLARE @CalendarMonths TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,cdate date)
INSERT @CalendarMonths VALUES( @FirstDate)
WHILE @FirstDate < @LastDate
BEGIN
SET @FirstDate = DATEADD( day,1, @FirstDate)
INSERT @CalendarMonths VALUES( @FirstDate)
END

Create Table #TempBMMain ([BMDate] date,[BMCodeType] varchar(50), [BMTime] Time)
	insert into #TempBMMain
	Select BMDate, [BMCodeType],BMTime from ZHT_BMMain where ActiveInd='A' and ClientID=@StudentID
	
Select CAST(cm.cdate As nvarchar(50)) as cdate,case bm.BMCodeType when 'No BM' THEN bm.BMCodeType when 'LOA' THEN bm.BMCodeType  ELSE (ISNULL(CONVERT(varchar(15),CAST(BMTime AS TIME),100),'0')) END as BMTime, ISNULL(bm.BMCodeType,'0') as BMType from @CalendarMonths cm LEFT outer join #TempBMMain bm 
on cm.cdate=bm.BMDate order by cdate
drop table #TempBMMain
END





GO
