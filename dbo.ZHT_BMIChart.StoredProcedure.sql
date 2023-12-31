USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_BMIChart]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[ZHT_BMIChart] 
	@StudentID int,
	@TypeOfChart Varchar(10)	
AS
BEGIN
	
	SET NOCOUNT ON;

	--Get age from birthdate

	DECLARE @Now  datetime, @Dob datetime
	set @Dob = (select top 1 Birthdate from StudentPersonal where StudentPersonalId=@StudentID and PlacementStatus='A')
	SELECT   @Now=(select convert(varchar(10), Getdate(), 120))

	DECLARE @Gender int
	select @Gender = (Select top 1 Gender from StudentPersonal where StudentPersonalId=@StudentID and PlacementStatus='A')

	DECLARE @ClientAge int
	Set @ClientAge =(SELECT (CONVERT(int,CONVERT(char(8),@Now,112))-CONVERT(char(8),@Dob,112))/10000 AS AgeIntYears)

	DECLARE @CdcTbl TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,CDCAge float,[P3] float,[P5] float,[P10] float,[P25] float,[P50] float,[P75] float,[P85] float,[P90] float,[P95] float,[P97] float,StudentBMI float)
	insert into @CdcTbl
	select Round([AgeOrST],0),[P3],[P5],[P10],[P25],[P50],[P75],[P85],[P90],[P95],[P97],NULL from [ZHT_CDCGrowthDt] where DtType =@TypeOfChart and Gender=@Gender

	IF(@TypeOfChart = 'BMI')
	BEGIN
	update t1 set t1.StudentBMI=t2.BMI from @CdcTbl t1 inner join ZHT_BMIMainTable t2 on t1.CDCAge=t2.AgeInMnthAtBMI where t2.studentID=@StudentID and t2.ActiveStatus='A'
	 END
	 ELSE IF(@TypeOfChart = 'Weight')
	 BEGIN
	 DECLARE @KgTable TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,kgWeight Float,AgeInMnthAtBMI int )
	 insert into @KgTable
	 select ([weight] * 0.45),AgeInMnthAtBMI from ZHT_BMIMainTable where studentID=@StudentID and ActiveStatus='A'

	update t1 set t1.StudentBMI=t2.kgWeight from @CdcTbl t1 inner join @KgTable t2 on t1.CDCAge=t2.AgeInMnthAtBMI 
	 END
	  ELSE IF(@TypeOfChart = 'Height')
	 BEGIN
	update t1 set t1.StudentBMI=t2.HeightIncm from @CdcTbl t1 inner join ZHT_BMIMainTable t2 on t1.CDCAge=t2.AgeInMnthAtBMI where t2.studentID=@StudentID and t2.ActiveStatus='A'
	 END

	select * from @CdcTbl
   
   

END






GO
