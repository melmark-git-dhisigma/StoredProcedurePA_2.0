USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetClientTypeList]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetClientTypeList]
as 
Begin
 Select ddlValue,ddlText from UI_LookupTable WHERE qualifyingID = 'clientType' AND activeStatus = 1 ORDER BY lookupID;
End
GO
