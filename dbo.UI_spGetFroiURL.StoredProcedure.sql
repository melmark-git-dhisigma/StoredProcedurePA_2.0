USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[UI_spGetFroiURL]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Khyati Desai
-- Create date: June 08 2022
-- Description:	Get the URL for FROI
-- =============================================
CREATE PROCEDURE [dbo].[UI_spGetFroiURL]	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	Select 'http://froi/FROIForm?num=&UINum=';
	
    
END
GO
