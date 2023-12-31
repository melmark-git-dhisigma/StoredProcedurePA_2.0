USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[StudentMoreDetailsNE_bkup2022jun02]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  PROCEDURE [dbo].[StudentMoreDetailsNE_bkup2022jun02]
@SchoolId int,
@StudentId int,
@Type  varchar(50)

AS
BEGIN

IF(@Type='SD')

	BEGIN
					Select EC.FirstName+' '+EC.LastName+','+EC.Title as FullName,EC.Phone from EmergencyContactSchool EC  
					Where EC.StudentPersonalId=@StudentId And EC.SchoolId=@SchoolId

	END

ELSE IF(@Type='ED')

	BEGIN
					 SELECT LK.LookupName as Relation,CP.LastName+','+cp.FirstName as Name,CP.PrimaryLanguage,
					 CASE WHEN AL.StreetName IS NULL THEN '' ELSE AL.StreetName+',' END+
					 CASE WHEN AL.ApartmentType IS NULL THEN '' ELSE AL.ApartmentType+',' END+
					 CASE WHEN AL.City IS NULL THEN '' ELSE AL.City END AS Address,AL.Phone,AL.OtherPhone,AL.PrimaryEmail FROM AddressList AL
					INNER JOIN [StudentAddresRel] ADR ON ADR.AddressId=AL.AddressId
					INNER JOIN StudentPersonal SP ON ADR.StudentPersonalId=SP.StudentPersonalId
					LEFT JOIN ContactPersonal CP ON ADR.ContactPersonalId=CP.ContactPersonalId
					INNER JOIN  StudentContactRelationship SCR on SCR.ContactPersonalId=CP.ContactPersonalId
					INNER JOIN  LookUp LK on LK.LookupId=SCR.RelationshipId
					WHERE SP.SchoolId=@SchoolId AND SP.StudentPersonalId=@StudentId AND ContactSequence=1      
	END

ELSE IF(@Type='SM')

	BEGIN

	      --           SELECT dbo.StudentPersonal.LastName+','+ dbo.StudentPersonal.FirstName+','+ dbo.StudentPersonal.MiddleName as  Name,
				   --      dbo.AddressList.AddressLine1+','+AddressList.AddressLine2+','+AddressList.AddressLine3 as Address, dbo.StudentPersonal.NickName, 
						 --dbo.StudentPersonal.CountryOfCitizenship, CONVERT(VARCHAR(10),dbo.StudentPersonal.BirthDate,101) as BirthDate  , dbo.StudentPersonal.Height, dbo.StudentPersonal.Weight, dbo.StudentPersonal.HairColor, dbo.StudentPersonal.EyeColor, 
       --                  dbo.StudentPersonal.MaritalStatus, dbo.StudentPersonal.PrimaryLanguage, dbo.StudentPersonal.DistingushingMarks, 
       --                  dbo.StudentPersonal.MaritalStatusofBothParents, dbo.StudentPersonal.StudentType, dbo.StudentPersonal.SchoolId, dbo.StudentPersonal.ImageUrl, 
       --                  CASE WHEN dbo.StudentPersonal.Gender=1 THEN 'Male' ELSE 'Female' END AS Gender, CONVERT(VARCHAR(10),dbo.StudentPersonal.AdmissionDate,101) as  AdmissionDate, dbo.StudentAddresRel.ContactSequence,LookUp.LookupName as Race
       --              FROM   dbo.StudentPersonal INNER JOIN
       --                  dbo.StudentAddresRel ON dbo.StudentPersonal.StudentPersonalId = dbo.StudentAddresRel.StudentPersonalId INNER JOIN
       --                  dbo.AddressList ON dbo.StudentAddresRel.AddressId = dbo.AddressList.AddressId LEFT JOIN
       --                  dbo.LookUp ON dbo.StudentPersonal.RaceId = dbo.LookUp.LookupId 
				   --  Where  dbo.StudentAddresRel.ContactSequence=0 And StudentPersonal.StudentType='Client' 
						 --And dbo.StudentPersonal.SchoolId=@SchoolId And dbo.StudentPersonal.StudentPersonalId=@StudentId

						 SELECT dbo.StudentPersonal.LastName+','+ dbo.StudentPersonal.FirstName+','+ dbo.StudentPersonal.MiddleName as  Name,
CASE WHEN AddressList.StreetName IS NULL THEN '' ELSE AddressList.StreetName+',' END +
CASE WHEN dbo.AddressList.ApartmentType IS NULL THEN ''ELSE dbo.AddressList.ApartmentType+',' END+
CASE WHEN dbo.AddressList.City IS NULL THEN '' ELSE dbo.AddressList.City+',' END+
CASE WHEN dbo.AddressList.StateProvince IS NULL THEN '' ELSE (SELECT LookupName FROM LookUp WHERE LookupId= dbo.AddressList.StateProvince)+',' END+
CASE WHEN dbo.AddressList.PostalCode IS NULL THEN '' ELSE dbo.AddressList.PostalCode+',' END +
CASE WHEN dbo.AddressList.[County] IS NULL THEN '' ELSE dbo.AddressList.[County]+',' END+
CASE WHEN dbo.AddressList.[CountryId] IS NULL THEN '' ELSE (SELECT LookupName FROM LookUp WHERE LookupId= dbo.AddressList.[CountryId]) END
 as Address, dbo.StudentPersonal.NickName, 
						 CASE WHEN dbo.StudentPersonal.CitizenshipStatus=1014 THEN 'Dual national'
						  ELSE
						  CASE WHEN dbo.StudentPersonal.CitizenshipStatus=1015 THEN 'Non-resident alien'
						  ELSE
						  CASE WHEN dbo.StudentPersonal.CitizenshipStatus=1016 THEN 'Resident alien'
						  ELSE
						  CASE WHEN dbo.StudentPersonal.CitizenshipStatus=9999 THEN 'United States Citizen'
						  END
						  END
						  END
						  END AS CountryOfCitizenship,
						  CONVERT(VARCHAR(10),dbo.StudentPersonal.BirthDate,101) as BirthDate  , dbo.StudentPersonal.Height, dbo.StudentPersonal.Weight, dbo.StudentPersonal.HairColor, dbo.StudentPersonal.EyeColor, 
                         dbo.StudentPersonal.PrimaryLanguage, dbo.StudentPersonal.DistingushingMarks,
                         dbo.StudentPersonal.MaritalStatusofBothParents, 
                         CASE WHEN dbo.StudentPersonal.Gender=1 THEN 'Male' ELSE 'Female' END AS Gender, CONVERT(VARCHAR(10),dbo.StudentPersonal.AdmissionDate,101) as  AdmissionDate,dbo.StudentPersonal.PlaceOfBirth,
						  dbo.StudentPersonal.ImageUrl,dbo.StudentPersonal.LegalCompetencyStatus,dbo.StudentPersonal.GuardianShip,
						   dbo.StudentPersonal.OtherStateAgenciesInvolvedWithStudent,dbo.StudentPersonal.CaseManagerResidential,
						   dbo.StudentPersonal.CaseManagerEducational,LookUp.LookupName as Race
                     FROM   dbo.StudentPersonal INNER JOIN
                         dbo.StudentAddresRel ON dbo.StudentPersonal.StudentPersonalId = dbo.StudentAddresRel.StudentPersonalId INNER JOIN
                         dbo.AddressList ON dbo.StudentAddresRel.AddressId = dbo.AddressList.AddressId LEFT JOIN
                         dbo.LookUp ON dbo.StudentPersonal.RaceId = dbo.LookUp.LookupId 
				     Where  dbo.StudentAddresRel.ContactSequence=0 And StudentPersonal.StudentType='Client' 
						 --And dbo.StudentPersonal.SchoolId=1 And dbo.StudentPersonal.StudentPersonalId=1302
						 And dbo.StudentPersonal.SchoolId=@SchoolId And dbo.StudentPersonal.StudentPersonalId=@StudentId

	END

ELSE IF(@Type='IN')--Medical and Insurance2

		BEGIN
	
			SELECT InsuranceType,PolicyNumber,PolicyHolder FROM Insurance where SchoolId=@SchoolId And StudentPersonalId=@StudentId
		
		END


		
ELSE IF(@Type='INEX')--Medical and Insurance Export

		BEGIN
	
			SELECT InsuranceType,PolicyNumber,PolicyHolder FROM Insurance where SchoolId=0 And StudentPersonalId=@StudentId and PreferType='Primary'
		
		END

ELSE IF(@Type='MT')--Medical and Insurance3

		BEGIN

				Select  CONVERT(VARCHAR(10),DateOfLastPhysicalExam,101) as DateOfLastPhysicalExam,MedicalConditionsDiagnosis,Allergies,CurrentMedications,SelfPreservationAbility,
					SignificantBehaviorCharacteristics,Capabilities,Limitations,Preferances from MedicalAndInsurance
				Where SchoolId=@SchoolId And StudentPersonalId=@StudentId

		END

		ELSE IF(@Type='IEP')--IEP

		BEGIN

				Select  IEPReferralFullName+','+IEPReferralTitle AS Name,IEPReferralPhone,IEPReferralReferrinAgency AS RAgency,IEPReferralSourceofTuition AS RTuition
					 from StudentPersonal
				Where SchoolId=@SchoolId And StudentPersonalId=@StudentId

		END


ELSE IF(@Type='DD')--Education History--

		BEGIN

				Select CONVERT(VARCHAR(10),DateInitiallyEligibleforSpecialEducation,101) as DateInitiallyEligibleforSpecialEducation, CONVERT(VARCHAR(10),DateofMostRecentSpecialEducationEvaluations,101) as DateofMostRecentSpecialEducationEvaluations ,CONVERT(VARCHAR(10),DateofNextScheduled3YearEvaluation,101) as DateofNextScheduled3YearEvaluation,CONVERT(VARCHAR(10),CurrentIEPStartDate,101) as CurrentIEPStartDate,CONVERT(VARCHAR(10),CurrentIEPExpirationDate,101) as CurrentIEPExpirationDate
				from StudentPersonal Where SchoolId=@SchoolId And StudentPersonalId=@StudentId

		END

ELSE IF(@Type='DI')--Dicharge Information--

		BEGIN

				Select CONVERT(VARCHAR(10),DischargeDate,101) as DischargeDate,LocationAfterDischarge,MelmarkNewEnglandsFollowUpResponsibilities from StudentPersonal Where SchoolId=@SchoolId And StudentPersonalId=@StudentId

		END

ELSE IF(@Type='PP')--Primary Physician--

		BEGIN

				SELECT MI.LastName+','+MI.FirstName as  Name ,OfficePhone ,Adr.AddressLine1+','+Adr.AddressLine2+','+Adr.AddressLine3 as Address  
				FROM MedicalAndInsurance MI left Join AddressList Adr on MI.AddressId=Adr.AddressId Where SchoolId=@SchoolId And StudentPersonalId=@StudentId
		
		END

ELSE IF(@Type='SA')--School Attended--

		BEGIN

		Select SchoolName,CONVERT(VARCHAR(10),DateFrom,101)+'-'+CASE WHEN CONVERT(VARCHAR(10),DateTo,101) IS NULL
		THEN 'Present' ELSE  CONVERT(VARCHAR(10),DateTo,101) END as DateAttended,
		CASE WHEN Address1 IS NULL THEN '' ELSE Address1+',' END +CASE WHEN Address2 IS NULL THEN '' ELSE Address2+',' END 
		+ CASE WHEN City IS NULL THEN '' ELSE City+',' END+ CASE WHEN State IS NULL THEN '' ELSE (SELECT LookupName FROM LookUp WHERE LookupId=State) END
		as Address from SchoolsAttended where  
		SchoolId=@SchoolId And StudentPersonalId=@StudentId

		END

END














GO
