USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Referral_NotificationsS]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Referral_NotificationsS]
@SchoolId int
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @School int

	
	SET @School=@SchoolId

	Select QueueId from ref_Queue
	
END




GO
