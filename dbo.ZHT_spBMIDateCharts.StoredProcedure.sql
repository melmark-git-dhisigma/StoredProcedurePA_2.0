USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spBMIDateCharts]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =================================================================
-- Author:		Khyati Desai
-- Create date: October 11, 2021
-- Description:	ZHT_spBMIDateCharts is a stored procedure used in 
-- HTReports page for BMI Charts, Weight Charts and Height Charts.
-- User to provide start date, End Date and Client Name/Location
-- =================================================================
CREATE PROCEDURE [dbo].[ZHT_spBMIDateCharts]
	-- Add the parameters for the stored procedure here
	@StartDate Date,
	@EndDate Date,
	@ClientName varchar,
	@ChrtType varchar(10),
	@LocationName varchar
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select * from ZHT_BMIMainTable
END
GO
