USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_BMEmail]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[ZHT_BMEmail]

AS
BEGIN
	SET NOCOUNT ON;

	--No data Students for past 3 days, no entry in the BM table
	DECLARE @FirstDate DATE 
	DECLARE @LastDate DATE 
	set @FirstDate = DATEADD(day, -3, GETDATE())
	set @LastDate = GETDATE()
	DECLARE @CalendarMonths TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,cdate date)
	INSERT @CalendarMonths VALUES( @FirstDate)
	WHILE @FirstDate < @LastDate
	BEGIN
	SET @FirstDate = DATEADD( day,1, @FirstDate)
	INSERT @CalendarMonths VALUES( @FirstDate)
	END
	
	DECLARE @BMTable TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,studentname varchar(100),StudentID int,bmdate date,bmtype varchar(50))
	INSERT @BMTable
	SELECT ClientName,ClientID,BMDate,BMCodeType
	FROM    ZHT_BMMain 
	WHERE   BMDate >= DATEADD(day, -4, GETDATE()) and ActiveInd='A'

	DECLARE @StdN TABLE (ClientName varchar(100))
	INSERT @StdN
	SELECT DISTINCT ClientName from ZHT_BMMain where BMDate >= DATEADD(day, -30, GETDATE()) and ActiveInd='A'
	
	SELECT ClientName FROM @StdN st
	WHERE NOT EXISTS 
		(SELECT studentname 
		 FROM @BMTable bm
		 WHERE st.ClientName = bm.studentname)

		--Students with No BMs and missed dates
	DECLARE @result1 TABLE(cdate date,studentname varchar(100),bmdate date,bmtype varchar(50),bmcomments nvarchar(Max))
	Insert @result1	
	Select CAST(cl.cdate As nvarchar(50)) as cdate,bm.ClientName,bm.BMDate,ISNULL(BMCodeType,'empty') as bmtype,bm.BMComments from @CalendarMonths cl inner join ZHT_BMMain bm on cl.cdate=bm.BMDate where bm.ActiveInd='A'

	DECLARE @EliStudents TABLE(stdname varchar(50))
	Insert @EliStudents
	select studentname from @result1 where bmtype<>'No BM' and bmtype<>'empty' and bmtype <> 'Type1' and bmtype <> 'Type2'and bmtype <> 'Type6' and bmtype <> 'Type7'

	DELETE FROM @result1
	WHERE studentname IN(SELECT stdname FROM @EliStudents) or cdate=CAST(GETDATE() as Date);
	select * from @result1

	insert into [ZHT_BMNotifEmail] values (GETDATE(),LTRIM(RIGHT(CONVERT(VARCHAR(20), GETDATE(), 100), 7)),'Y')

	select Distinct studentname from @result1 where studentname is not null
END










GO
