USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_LastBMReport]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[ZHT_LastBMReport] 
		@ResInd int
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @BMtbl1 TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName varchar(40),BMDate DateTime,BMType Varchar(20))
	DECLARE @ResClass TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ResName Varchar(50))
	--Get Number of hours from the last BM when option All is chosen and @ResInd is 2
	If(@ResInd = 2)
	BEGIN 
	--DECLARE @BMtbl1 TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName varchar(40),BMDate DateTime,BMType Varchar(20))
	Insert @BMtbl1
    select ClientName,CAST(BMDate as DATETIME) + CAST(BMTime as DATETIME),BMCodeType from ZHT_BMMain where BMCodeType<>'No BM'
	--select * from @BMtbl1
	END
	ELSE If (@ResInd = 1)
	BEGIN
	
	Insert @ResClass
	select ClassName from Class where ActiveInd='A' and ResidenceInd=@ResInd
	--select * from @ResClass

	--Get Number of hours from the last BM
	--DECLARE @BMtbl1 TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName varchar(40),BMDate DateTime,BMType Varchar(20))
	Insert @BMtbl1
    select ClientName,CAST(BMDate as DATETIME) + CAST(BMTime as DATETIME),BMCodeType from ZHT_BMMain BM inner join @ResClass res on BM.ProgramName=res.ResName where BMCodeType<>'No BM'
	--select * from @BMtbl1
	END
	ELSE IF(@ResInd = 0)
	BEGIN
	
	Insert @ResClass
	select ClassName from Class where ActiveInd='A' and ResidenceInd=1

	DECLARE @Resclient TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName Varchar(40))
	Insert  @Resclient
	select ClientName from ZHT_BMMain zbm inner join @ResClass rs on zbm.ProgramName = rs.ResName

	Insert @BMtbl1
    --select ClientName,CAST(BMDate as DATETIME) + CAST(BMTime as DATETIME),BMCodeType from ZHT_BMMain BM inner join @ResClass res on BM.ProgramName=res.ResName where BMCodeType<>'No BM' 
	
	select ClientName,CAST(BMDate as DATETIME) + CAST(BMTime as DATETIME),BMCodeType from ZHT_BMMain where BMCodeType<>'No BM'and ClientName NOT IN (select ClientName from @Resclient)

	END
	

	DECLARE @BMtbl2 TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName Varchar(40),MaxBMDate Datetime)
	Insert  @BMtbl2
	SELECT ClientName,MAX(BMdate) from @BMtbl1 GROUP BY ClientName

	--select * from @BMtbl2
	
	DECLARE @BMtbl3 TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName Varchar(40),MaxBMDate Datetime,BMHourDiff float)
	Insert  @BMtbl3
	select ClientName,MaxBMDate,DATEDIFF(hour,MaxBMDate,GetDate()) from @BMtbl2

	--select * from @BMtbl3

	--Get days missed from the last day of BM
		
	DECLARE @BMNoBM TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName Varchar(40),BMNoBMDate DateTime,BMType varchar(20))
	Insert @BMNoBM
	select ClientName,CAST(BMDate as DATETIME) + CAST(BMTime as DATETIME),BMCodeType from ZHT_BMMain where BMCodeType='No BM'
	
	DECLARE @BMtbl5 TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,ClientName Varchar(40),BMNoBMDate DateTime,BMHourDiff DateTime,NBMCont int)
	insert @BMtbl5
	select tb3.ClientName, tb3.MaxBMDate, tb3.BMHourDiff,COALESCE(Count(BM.BMType),0) from @BMtbl3 tb3 
	Left outer join @BMNoBM BM on tb3.ClientName=BM.ClientName where BM.BMNoBMDate>tb3.MaxBMDate group by tb3.ClientName, tb3.MaxBMDate, tb3.BMHourDiff 

	select tb3.ClientName,tb3.MaxBMDate,tb3.BMHourDiff,COALESCE(tb5.NBMCont, 0) as NumberOfNoBM from @BMtbl3 tb3 left join @BMtbl5 tb5 on tb3.ClientName=tb5.ClientName where tb3.BMHourDiff>24 and tb3.BMHourDiff<365 order by tb3.BMHourDiff Desc
	

END






GO
