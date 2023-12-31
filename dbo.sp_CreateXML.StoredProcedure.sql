USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[sp_CreateXML]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_CreateXML]
AS Begin
SELECT  
        (
            SELECT COLUMN_NAME as Name,
			DATA_TYPE as DataType,
			CASE(DATA_TYPE) WHEN 'date' THEN 'Text' WHEN 'varchar' THEN 'Radio' ELSE 'Drop' END as Contol
            FROM INFORMATION_SCHEMA.COLUMNS			
            For XML PATH ('Column'),root('columns'), type
        )
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Student'
ORDER BY TABLE_NAME ASC
For XML PATH ('LookUp'),Root('Tables')


END








GO
