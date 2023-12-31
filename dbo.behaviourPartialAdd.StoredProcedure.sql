USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[behaviourPartialAdd]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[behaviourPartialAdd]
@StartTime varchar(max),
@EndTime varchar(max),
@QueryToExe varchar(max)
as
begin
   create table #temp1(startTime varchar(Max),endTime varchar(Max))

   DECLARE @sItem VARCHAR(8000)
   DECLARE @eItem VARCHAR(8000)
   DECLARE @dItem VARCHAR(8000)
   
  
   WHILE CHARINDEX(',',@StartTime,0) <> 0
 BEGIN
 SELECT
  @sItem=RTRIM(LTRIM(SUBSTRING(@StartTime,1,CHARINDEX(',',@StartTime,0)-1))),
  @StartTime=RTRIM(LTRIM(SUBSTRING(@StartTime,CHARINDEX(',',@StartTime,0)+LEN(','),LEN(@StartTime)))),

    @eItem=RTRIM(LTRIM(SUBSTRING(@EndTime,1,CHARINDEX(',',@EndTime,0)-1))),
  @EndTime=RTRIM(LTRIM(SUBSTRING(@EndTime,CHARINDEX(',',@EndTime,0)+LEN(','),LEN(@EndTime))))
    
 IF LEN(@sItem) > 0
       INSERT INTO #temp1 values(@sItem,@eItem)
	   
 END

 IF LEN(@StartTime) > 0
	   INSERT INTO #temp1 values(@sItem,@eItem) -- Put the last item in
	
 exec(@QueryToExe);
-- select  1,5,#temp1.startTime,#temp1.endTime,cast(Call_Dates as date),'A','1',(SELECT Convert(Varchar,getdate(),100)),'false','1' from #temp1,SchoolCal,CalenderAllDate where ResidenceInd=(select ResidenceInd from Student where StudentId=1) and cast(Call_Dates as date) between cast('2013-05-16' as date)  and cast('2013-05-22' as date) and ((datename (dw, Call_Dates) = 'monday' and Weekday='monday') or (datename (dw, Call_Dates) = 'tuesday' and Weekday='tuesday') or (datename (dw, Call_Dates) = 'wednesday' and Weekday='wednesday') or (datename (dw, Call_Dates) = 'thursday' and Weekday='thursday') or (datename (dw, Call_Dates) = 'friday' and Weekday='friday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday')) and  cast(#temp1.startTime as datetime) > cast(SchoolCal.StartTime as datetime) and cast(#temp1.endTime as datetime) < cast(SchoolCal.EndTime as datetime) and Call_Dates not in (select HolDate from SchoolHoliday) and SchoolCal.SchoolId=1
   --select  2,1008,#temp1.startTime,#temp1.endTime,cast(Call_Dates as date),'A','1',(SELECT Convert(Varchar,getdate(),100)),'false','1' from #temp1,SchoolCal,CalenderAllDate where ResidenceInd=(select ResidenceInd from Student where StudentId=2) and cast(Call_Dates as date) between cast('01-09-2013' as date)  and cast('10-09-2013' as date) and ((datename (dw, Call_Dates) = 'monday' and Weekday='monday') or (datename (dw, Call_Dates) = 'tuesday' and Weekday='tuesday') or (datename (dw, Call_Dates) = 'wednesday' and Weekday='wednesday') or (datename (dw, Call_Dates) = 'thursday' and Weekday='thursday') or (datename (dw, Call_Dates) = 'friday' and Weekday='friday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday')) and  cast(#temp1.startTime as datetime) > cast(SchoolCal.StartTime as datetime) and cast(#temp1.endTime as datetime) < cast(SchoolCal.EndTime as datetime) and Call_Dates not in (select HolDate from SchoolHoliday) and SchoolCal.SchoolId=1
 -- select  1,3,#temp1.startTime,#temp1.endTime,CONVERT(datetime, Call_Dates),'A','1',(SELECT Convert(Varchar,getdate(),100)),'false','1' from #temp1,SchoolCal,CalenderAllDate where ResidenceInd=(select ResidenceInd from Student where StudentId=1) and CONVERT(datetime,Call_Dates,103) between CONVERT(datetime, '3/11/2013',103)  and CONVERT(datetime, '3/20/2013',103) and ((datename (dw, Call_Dates) = 'monday' and Weekday='monday') or (datename (dw, Call_Dates) = 'tuesday' and Weekday='tuesday') or (datename (dw, Call_Dates) = 'wednesday' and Weekday='wednesday') or (datename (dw, Call_Dates) = 'thursday' and Weekday='thursday') or (datename (dw, Call_Dates) = 'friday' and Weekday='friday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday')) and  cast(#temp1.startTime as datetime) > cast(SchoolCal.StartTime as datetime) and cast(#temp1.endTime as datetime) < cast(SchoolCal.EndTime as datetime) and Call_Dates not in (select HolDate from SchoolHoliday)
 -- select  1,14,#temp1.startTime,#temp1.endTime,CONVERT(datetime, Call_Dates),'A','1',(SELECT Convert(Varchar,getdate(),100)),'false','1' from #temp1,SchoolCal,CalenderAllDate where ResidenceInd=(select ResidenceInd from Student where StudentId=1) and CONVERT(datetime,Call_Dates,103) between CONVERT(datetime, '12-03-2013',103)  and CONVERT(datetime, '20-03-2013',103) and ((datename (dw, Call_Dates) = 'monday' and Weekday='monday') or (datename (dw, Call_Dates) = 'tuesday' and Weekday='tuesday') or (datename (dw, Call_Dates) = 'wednesday' and Weekday='wednesday') or (datename (dw, Call_Dates) = 'thursday' and Weekday='thursday') or (datename (dw, Call_Dates) = 'friday' and Weekday='friday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday')) 
   -- insert into BehaviourCalc(StudentId,MeasurmentId,StartTime,EndTime,[Date],ActiveInd,CreatedBy,CreatedOn,IOAFlag,IOAUser)   select  1,2,#temp1.startTime,#temp1.endTime,CONVERT(datetime, Call_Dates),'A','1',(SELECT Convert(Varchar,getdate(),100)),'false','1' from #temp1,SchoolCal,CalenderAllDate where ResidenceInd=(select ResidenceInd from Student where StudentId=1) and CONVERT(datetime,Call_Dates,103) between CONVERT(datetime, '11-03-2013',103)  and CONVERT(datetime, '21-03-2013',103) and ((datename (dw, Call_Dates) = 'monday' and Weekday='monday') or (datename (dw, Call_Dates) = 'tuesday' and Weekday='tuesday') or (datename (dw, Call_Dates) = 'wednesday' and Weekday='wednesday') or (datename (dw, Call_Dates) = 'thursday' and Weekday='thursday') or (datename (dw, Call_Dates) = 'friday' and Weekday='friday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday') or (datename (dw, Call_Dates) = 'saturday' and Weekday='saturday')) and  cast(#temp1.startTime as datetime) > cast(SchoolCal.StartTime as datetime) and cast(#temp1.endTime as datetime) < cast(SchoolCal.EndTime as datetime) and Call_Dates not in (select HolDate from SchoolHoliday)
end










GO
