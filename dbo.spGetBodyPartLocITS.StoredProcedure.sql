USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetBodyPartLocITS]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[spGetBodyPartLocITS] 
as 
Begin
 Select ddlValue,ddlText from UI_LookupTable where qualifyingID='indInjury1' and activeStatus=1;
End
GO
