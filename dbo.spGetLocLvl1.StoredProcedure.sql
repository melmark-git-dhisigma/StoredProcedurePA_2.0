USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetLocLvl1]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[spGetLocLvl1] 
as 
Begin
 Select LocLvl1ID,LocLvl1Name from UI_LocationLevel1 WHERE activeStatusFlag = 1
End
GO
