USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[EmergencyContacyPersonal-E]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[EmergencyContacyPersonal-E]
@SchoolId int,
@StudentId int

AS
BEGIN

                  
      Select distinct LK.LookupName as Relation, CP.LastName+','+cp.FirstName as Name, AL.AddressLine1+','+AL.AddressLine2+','+AL.AddressLine3 as Address,CP.PrimaryLanguage,  AL.Phone,AL.OtherPhone,AL.PrimaryEmail from AddressList AL 
             Inner Join StudentAddresRel ADR on AL.AddressId=ADR.AddressId
             Inner Join StudentPersonal SP on SP.StudentPersonalId=ADR.StudentPersonalId
			 inner join ContactPersonal CP on CP.StudentPersonalId=SP.StudentPersonalId
			 inner join StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
			 inner join [LookUp] LK on LK.LookupId=SCR.RelationshipId
      where ADR.ContactSequence=1  AND  AL.AddressType=1 AND SP.StudentPersonalId=1 And SP.StudentType='Client' 
		    And SP.SchoolId=@SchoolId And SP.StudentPersonalId=@StudentId

END










GO
