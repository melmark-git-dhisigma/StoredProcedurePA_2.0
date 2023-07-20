USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetInjuryType]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetInjuryType]
AS
BEGIN
	SELECT ddlText,ddlValue FROM UI_LookupTable WHERE activeStatus=1 AND qualifyingID='injuryType';
END
GO
