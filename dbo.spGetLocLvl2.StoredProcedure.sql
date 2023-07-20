USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetLocLvl2]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[spGetLocLvl2]
@LocLvl1ID int
as 
Begin
 Select * from UI_LocationLevel2 
 where LocLvl1ID = @LocLvl1ID AND lvl2ActiveStatusFlag = 1 ORDER BY LocLvl2Name
End
GO
