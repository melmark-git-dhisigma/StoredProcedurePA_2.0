USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[StudentMoreDetailsPA]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StudentMoreDetailsPA]
@SchoolId int,
@StudentId int,
@Type  varchar(50)

AS
BEGIN



-- Basic Information
IF (@Type='BI')
BEGIN
SELECT LastName+''+FirstName AS StudentName
,CASE WHEN Gender=1 THEN 'Male' ELSE 'Female' END AS Gender
,CONVERT(Varchar(10),Birthdate,101) AS Birthdate
,CASE WHEN SP.ModifiedOn IS NULL THEN CONVERT(Varchar(10),SP.CreatedOn,101) ELSE CONVERT(Varchar(10),SP.ModifiedOn,101) END AS DateUpdated 
,ISNULL(AL.ApartmentType,'')+','+ISNULL(AL.StreetName,'') +','+ISNULL(AL.City,'') as StudAddress
,AL.Phone
 FROM StudentPersonal SP
INNER JOIN [dbo].[StudentAddresRel] SAR ON SP.StudentPersonalId=SAR.StudentPersonalId
INNER JOIN AddressList AL ON SAR.AddressId=AL.AddressId WHERE SP.StudentPersonalId=@StudentId AND SP.SchoolId=@SchoolId
AND SAR.ContactSequence=0 AND SP.StudentType='Client' 
END



--Funding Resource
ELSE IF(@Type='FR')
BEGIN
SELECT Nameofcontact FROM ref_CallLogs  Where CallLogId In (SELECT MAX(CallLogId) FROM ref_CallLogs   WHERE StudentId=@StudentId AND SchoolId=@SchoolId AND Type='FV')
END


-- Primary Contact
ELSE IF(@Type='PC')
BEGIN
Select distinct 
AL.ApartmentType+','+AL.StreetName+','+AL.City AS PrimaryContactAddress
,AL.Phone AS HomePhone,AL.OtherPhone AS WorkPhone,AL.Mobile AS CellPhone,AL.PrimaryEmail 
AS Email from StudentPersonal SP
inner join ContactPersonal CP on CP.StudentPersonalId=SP.StudentPersonalId
inner join StudentAddresRel SAR on SAR.ContactPersonalId=CP.ContactPersonalId
inner join AddressList AL on AL.AddressId=SAR.AddressId
inner join StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
inner join [LookUp] LK on LK.LookupId=SCR.RelationshipId
inner join StudentPersonalPA SPP on SPP.StudentPersonalId=SP.StudentPersonalId
                     where SAR.ContactSequence=1  AND SP.StudentPersonalId=@StudentId And SP.StudentType='Client' 
						And SP.SchoolId=@SchoolId  AND LK.LookupName='Primary Contact' AND CP.Status=1
END



--Legal Guardian 1
ELSE IF(@Type='LG1')
BEGIN
Select distinct 
AL.ApartmentType+','+AL.StreetName+','+AL.City AS PrimaryContactAddress
,AL.Phone AS HomePhone,AL.OtherPhone AS WorkPhone,AL.Mobile AS CellPhone,AL.PrimaryEmail 
AS Email from StudentPersonal SP
inner join ContactPersonal CP on CP.StudentPersonalId=SP.StudentPersonalId
inner join StudentAddresRel SAR on SAR.ContactPersonalId=CP.ContactPersonalId
inner join AddressList AL on AL.AddressId=SAR.AddressId
inner join StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
inner join [LookUp] LK on LK.LookupId=SCR.RelationshipId
inner join StudentPersonalPA SPP on SPP.StudentPersonalId=SP.StudentPersonalId
                     where SAR.ContactSequence=1  AND SP.StudentPersonalId=@StudentId And SP.StudentType='Client' 
						And SP.SchoolId=@SchoolId And LK.LookupName='Legal Guardian 1' AND CP.Status=1 
END



--Legal Guardian 2
ELSE IF(@Type='LG2')
BEGIN
Select distinct 
AL.ApartmentType+','+AL.StreetName+','+AL.City AS PrimaryContactAddress
,AL.Phone AS HomePhone,AL.OtherPhone AS WorkPhone,AL.Mobile AS CellPhone,AL.PrimaryEmail 
AS Email from StudentPersonal SP
inner join ContactPersonal CP on CP.StudentPersonalId=SP.StudentPersonalId
inner join StudentAddresRel SAR on SAR.ContactPersonalId=CP.ContactPersonalId
inner join AddressList AL on AL.AddressId=SAR.AddressId
inner join StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
inner join [LookUp] LK on LK.LookupId=SCR.RelationshipId
inner join StudentPersonalPA SPP on SPP.StudentPersonalId=SP.StudentPersonalId
                     where SAR.ContactSequence=1  AND  SP.StudentType='Client' 
						And SP.SchoolId=@SchoolId And SP.StudentPersonalId=@StudentId  AND LK.LookupName='Legal Guardian 2' AND CP.Status=1
END




-- Support Coordinator
ELSE IF(@Type='SC')
BEGIN
Select distinct 
AL.ApartmentType+','+AL.StreetName+','+AL.City AS PrimaryContactAddress
,AL.Phone AS HomePhone,AL.OtherPhone AS WorkPhone,AL.Mobile AS CellPhone,AL.PrimaryEmail 
AS Email from StudentPersonal SP
inner join ContactPersonal CP on CP.StudentPersonalId=SP.StudentPersonalId
inner join StudentAddresRel SAR on SAR.ContactPersonalId=CP.ContactPersonalId
inner join AddressList AL on AL.AddressId=SAR.AddressId
inner join StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
inner join [LookUp] LK on LK.LookupId=SCR.RelationshipId
inner join StudentPersonalPA SPP on SPP.StudentPersonalId=SP.StudentPersonalId
                     where SAR.ContactSequence=1  And SP.StudentType='Client' 
						And SP.SchoolId=@SchoolId And SP.StudentPersonalId=@StudentId  AND LK.LookupName='Support Coordinator' AND CP.Status=1
END



-- Advocate
ELSE IF(@Type='ADV')
BEGIN
Select distinct 
AL.ApartmentType+','+AL.StreetName+','+AL.City AS PrimaryContactAddress
,AL.Phone AS HomePhone,AL.OtherPhone AS WorkPhone,AL.Mobile AS CellPhone,AL.PrimaryEmail 
AS Email from StudentPersonal SP
inner join ContactPersonal CP on CP.StudentPersonalId=SP.StudentPersonalId
inner join StudentAddresRel SAR on SAR.ContactPersonalId=CP.ContactPersonalId
inner join AddressList AL on AL.AddressId=SAR.AddressId
inner join StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
inner join [LookUp] LK on LK.LookupId=SCR.RelationshipId
inner join StudentPersonalPA SPP on SPP.StudentPersonalId=SP.StudentPersonalId
                     where SAR.ContactSequence=1  And SP.StudentType='Client' 
						And SP.SchoolId=@SchoolId And SP.StudentPersonalId=@StudentId  AND LK.LookupName='Advocate' AND CP.Status=1
END


-- Behaviors PA--
ELSE IF(@type='BPA')
BEGIN
SELECT BP.behaviourname,BP.ParentId FROM BehavioursPA BP inner join
BehaveLookup BL ON bl.BehaviouralId=bp.ParentId
WHERE BP.SchoolId=@SchoolId and BP.StudentPersonalId=@StudentId ORDER BY ParentId ASC
END

-- Behaviors PA Export--
ELSE IF(@type='BPAE')
BEGIN
SELECT BP.behaviourname FROM BehavioursPA BP inner join
BehaveLookup BL ON bl.BehaviouralId=bp.ParentId
WHERE BP.SchoolId=@SchoolId and BP.StudentPersonalId=@StudentId ORDER BY ParentId ASC
END




-- Diagnosis
ELSE IF(@Type='DIA')
BEGIN
SELECT [Diaganoses] FROM StudentPersonal SP INNER JOIN [dbo].[DiaganosesPA] DPA ON SP.StudentPersonalId=DPA.StudentPersonalId
WHERE SP.StudentPersonalId=@StudentId AND SP.SchoolId=@SchoolId
END


-- Level of Supervision
ELSE IF(@Type='LS')
BEGIN
SELECT [Bathroom]
,[OnCampus]
,[WhenTranspoting]
,[OffCampus]
,[PoolOrSwimming]
,[Van]
,[CommonAreas]
,[ho_BedroomAwake]
,[ho_BedroomAsleep]
,[dy_TaskOrBreak]
,[dy_TransitionInside]
,[dy_TransitionUnevenGround]
,[RiskOfResistance]
,[Mobility]
,[NeedForExtraHelp]
,[ResponseToInstruction]
,[Consciousness]
,[WalkingResponses]
,[Allergies]
,[Seizures]
,[Diet]
,SPA.[Other]
,[FundingSource]
 FROM StudentPersonalPA SPA INNER JOIN StudentPersonal SP ON SP.StudentPersonalId=SPA.StudentPersonalId
WHERE SP.StudentPersonalId=@StudentId AND SP.SchoolId=@SchoolId
END



-- ADAPTIVE EQUIPMENT 
ELSE IF(@Type='AE')
BEGIN
SELECT [Item]
,[ScheduleForUse]
,[StorageLocation]
,[CleaningInstruction] FROM [dbo].[AdaptiveEquipment] WHERE [StudentPersonalId]=@StudentId AND SchoolId=@SchoolId
END


--BASIC BEHAVIORAL INFORMATION
ELSE IF(@Type='BBI')
BEGIN
SELECT [TargetBehavior]
,[Definition]
,[Antecedent]
,[FCT]
,[Consequence] FROM [dbo].[BasicBehavioralInformation] WHERE [StudentPersonalId]=@StudentId AND SchoolId=@SchoolId
END

END










GO
