USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spRetieveMain]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spRetieveMain]
@irID Varchar(50)

AS
BEGIN
       Select Info.*,Look.ddlValue, Look1.LocLvl1ID, Look2.LocLvl2ID, Look3.LocLvl3ID from UI_IrInfoList Info inner join UI_LookupTable Look on info.clientType=Look.ddlText inner join UI_LocationLevel1 Look1 on info.LocLvl1Name=Look1.LocLvl1Name inner join UI_LocationLevel2 Look2 on info.LocLvl2Name=Look2.LocLvl2Name inner join UI_LocationLevel3 Look3 on info.LocLvl3Name=Look3.LocLvl3Name  where Info.irID = @irID and (Look3.LocLvl1ID=look1.LocLvl1ID and Look2.LocLvl1ID=look1.LocLvl1ID) and Info.ActiveStatus='A';

END
GO
