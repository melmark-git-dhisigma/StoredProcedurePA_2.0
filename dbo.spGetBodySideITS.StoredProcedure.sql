USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetBodySideITS]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[spGetBodySideITS] 
as 
Begin
 Select ddlValue,ddlText from UI_LookupTable where qualifyingID='indInjury3' and activeStatus=1;
End
GO
