USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[spGetBodyPartNurseITS]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetBodyPartNurseITS]
@bodyPartITS varchar(25)
AS 
BEGIN 
SELECT ddlText,ddlValue 
FROM UI_LookupTable 
WHERE qualifyingID = 'indInjury2' 
AND activeStatus=1 
and cascadingDdlID = @bodyPartITS
END
GO
