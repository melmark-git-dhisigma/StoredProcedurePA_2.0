USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[WBC_spPhotosReport]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[WBC_spPhotosReport]
              @ClassID int,
              @ClientID int,       
       @StartDate date,
       @EndDate date
AS
BEGIN
       select W.WBCID,W.ClientName,L1.BodyPartIDLvl1 as [BodyLevel1], L1.BodyPartIDLvl2 as [BodyLevel2], L1.BodyPartIDLvl3 as [BodyLevel3], L1.LabelLocFtorBk as [BodyView],W.IdentifiedInitials,convert(varchar(15),
       W.IdentifiedDate,101) as [IdentifiedDate], 
       CONVERT(varchar(15),W.IdentifiedTime,100) as IdentifiedTime, 
       W.SubmittedByName,convert(varchar(15),W.SubmittedByDate,101) as [SubmittedByDate], 
       CONVERT(varchar(15),W.SubmittedByTime,100) as [SubmittedByTime],p.* 
from WBC_MainDataTable W 
join WBC_LookupTable L1 on W.LabelID=L1.LabelNo
join WBC_PicTable P on W.WBCID=P.WBCID and P.ImageStatus='A' and p.ActiveStatus='A' where W.StudentID=@ClientID and (W.IdentifiedDate between @StartDate and @EndDate)

END
GO
