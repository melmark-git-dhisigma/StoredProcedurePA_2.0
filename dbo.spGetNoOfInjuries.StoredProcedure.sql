USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetNoOfInjuries]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetNoOfInjuries]
AS
BEGIN
	Select ddlValue,ddlText from UI_LookupTable where qualifyingID='itsNumber' and activeStatus=1;
END
GO
