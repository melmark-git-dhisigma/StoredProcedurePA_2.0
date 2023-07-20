USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetPmpType]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetPmpType]
as 
Begin
 Select ddlValue,ddlText from UI_LookupTable WHERE qualifyingID = 'pmpType' AND activeStatus = 1 ORDER BY ddlValue;
End
GO
