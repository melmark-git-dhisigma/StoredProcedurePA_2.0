USE [MelmarkNE]
GO
/****** Object:  StoredProcedure [dbo].[clientcontactreport]    Script Date: 5/27/2025 3:15:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[clientcontactreport] 

@HContactStudname varchar(500),
@HContactstatus varchar(50),
@HContactRelation varchar(500)

AS
BEGIN	
	SET NOCOUNT ON;	

	 IF Object_id('tempdb..#Temp_ClientRpt') IS NOT NULL
        DROP TABLE #Temp_ClientRpt

      CREATE TABLE #Temp_ClientRpt
        (
           [STDTCONTACTID]       [INT] IDENTITY(1, 1) NOT NULL,
           [STUDENTPERSONALID]   [INT] NULL,
           [SCHOOLID]            [INT] NULL,
           [CLIENTLAST]          [VARCHAR](100) NULL,
           [CLIENTFIRST]         [VARCHAR](100) NULL,
           [REFERRALNAME]        [VARCHAR](100) NULL,
           [DOB]                 [DATE] NULL,
           [ADMISSIONDATE]       [DATE] NULL,
		   [PROGRAM]             [VARCHAR](500) NULL,
		   [PLACEMENT]           [VARCHAR](500) NULL,
           [RELATIONSHIP]        [VARCHAR](100) NULL,
		   [RELATIONSHIPID]		 [INT] NULL,
           [CONTACTLAST]         [VARCHAR](100) NULL,
           [CONTACTFIRST]        [VARCHAR](100) NULL, 
		   [CONTACTNAME]         [VARCHAR](100) NULL,
           [TYPE]                [VARCHAR](50) NULL,
           [STREETNAME]          [VARCHAR](500) NULL,
		   [FLOOR]               [VARCHAR](500) NULL,
		   [CITY]                [VARCHAR](500) NULL,
           [PHONE]               [VARCHAR](50) NULL,
           [MOBILE]              [VARCHAR](50) NULL,
		   [ORGANIZATION]        [VARCHAR](500) NULL,
           [OCCUPATION]          [VARCHAR](500) NULL,
           [EMAIL]               [VARCHAR](500) NULL,
		   [EMERGENCY]           [VARCHAR](50) NULL,
		   [STATUS]              [INT] NULL,
		   [CLASSID]			 [INT] NULL
          
		  )
		  INSERT INTO #Temp_ClientRpt
		  ([STUDENTPERSONALID],
           [SCHOOLID],
           [CLIENTLAST],
           [CLIENTFIRST],
           [REFERRALNAME], 
           [DOB],          
           [ADMISSIONDATE],  
		   [PROGRAM],           
		   [PLACEMENT],         
           [RELATIONSHIP],      
		   [RELATIONSHIPID],		
           [CONTACTLAST],       
           [CONTACTFIRST],       
		   [CONTACTNAME],         
           [TYPE],               
           [STREETNAME],         
		   [FLOOR],              
		   [CITY],              
           [PHONE],             
           [MOBILE],              
		   [ORGANIZATION],       
           [OCCUPATION],          
           [EMAIL],               
		   [EMERGENCY],          
		   [STATUS],
		   [CLASSID] )

   SELECT		CP.StudentPersonalId AS STUDENTPERSONALID, 
				SP.SchoolId AS SCHOOLID, 
				SP.LastName AS CLIENTLAST,
				SP.FirstName AS CLIENTFIRST, 
				SP.LastName + ',' + SP.FirstName AS REFERRALNAME,
				CONVERT(VARCHAR(10), SP.BirthDate, 101) AS DOB,
				CONVERT(VARCHAR(10),SP.AdmissionDate, 101) AS ADMISSIONDATE, 
				NULL as PROGRAM,
				NULL as PLACEMENT,
				LP.LookupName AS RELATIONSHIP,
				LP.LookupId AS RELATIONSHIPID,
				CP.LastName as CONTACTLAST, 
				CP.FirstName AS CONTACTFIRST,
				CP.LastName + ',' + CP.FirstName AS CONTACTNAME,
				CASE WHEN StudentAddresRel.ContactSequence=1 THEN 'HOME' 
				ELSE CASE WHEN StudentAddresRel.ContactSequence=2 THEN 'WORK'
				ELSE CASE WHEN StudentAddresRel.ContactSequence=3 THEN 'OTHER' END END END AS TYPE,
				AddressList.streetname as STREETNAME,
				CASE WHEN AddressList.ApartmentType IS NULL THEN ' ' ELSE AddressList.ApartmentType END AS [FLOOR],
				CASE WHEN AddressList.City <>''
				THEN AddressList.City+','+(SELECT lookupname FROM [lookup] WHERE AddressList.StateProvince=LookupId)+' '+
				AddressList.PostalCode
				ELSE (SELECT lookupname FROM [lookup] where AddressList.StateProvince=LookupId)+' '+
				AddressList.PostalCode END  AS CITY,
				AddressList.Phone AS PHONE,
				AddressList.Mobile AS MOBILE,
				CASE WHEN StudentAddresRel.ContactSequence=2 THEN CP.Employer  ELSE 'NA' END,
				CASE WHEN StudentAddresRel.ContactSequence=2 THEN CP.Occupation ELSE 'NA' END,
				AddressList.PrimaryEmail AS EMAIL,
				CASE WHEN CP.IsEmergency=1 THEN 'YES' ELSE 'NO'END AS [EMERGENCY],
				NULL AS [STATUS],
				NULL as [CLASSID]


    FROM			  ContactPersonal AS CP INNER JOIN
                      StudentContactRelationship ON CP.ContactPersonalId = StudentContactRelationship.ContactPersonalId INNER JOIN
                      LookUp AS LP ON StudentContactRelationship.RelationshipId = LP.LookupId LEFT JOIN
                      StudentAddresRel ON CP.StudentPersonalId = StudentAddresRel.StudentPersonalId 
					  AND CP.ContactPersonalId = StudentAddresRel.ContactPersonalId LEFT JOIN
                      AddressList ON StudentAddresRel.AddressId = AddressList.AddressId INNER JOIN
                      StudentPersonal AS SP ON SP.StudentPersonalId = CP.StudentPersonalId
	WHERE     (StudentAddresRel.ContactSequence IN (1, 2, 3)) 
			  AND (CP.Status = 1)  
		      AND (SP.StudentType = 'Client') 
		      AND (CONVERT(INT,SP.ClientId)>0)
		      AND AddressList.StreetName<>' '
			


	UPDATE #Temp_ClientRpt SET PROGRAM= (SELECT STUFF((SELECT ','+LookupName
		FROM LookUp WHERE LookupId IN
		(SELECT DEPARTMENT FROM Placement PT inner join [Lookup] lkp on lkp.Lookupid = PT.DEPARTMENT inner join [Class] sdtc on sdtc.ClassId=PT.[Location] 
		WHERE (PT.EndDate IS NULL OR PT.EndDate>= cast (GETDATE() as DATE)) and Status=1 AND lkp.LookupType = 'Department'  AND
		PT.StudentPersonalId =#Temp_ClientRpt.StudentPersonalId)
		FOR XML PATH('')),1,1,''))


	UPDATE #Temp_ClientRpt SET PLACEMENT= (SELECT STUFF((SELECT ','+LookupName
		 FROM LookUp WHERE LookupId IN
		(SELECT PlacementType FROM Placement PT WHERE (PT.EndDate IS NULL OR PT.EndDate>= cast (GETDATE() as DATE)) and Status=1 and
		PT.StudentPersonalId =#Temp_ClientRpt.StudentPersonalId)
		FOR XML PATH('')),1,1,''))

	DECLARE @DischClass VARCHAR(MAX);
	SET @DischClass = (select Top 1 ClassId from Class where ClassCd='DSCH' and ActiveInd='A' and SchoolId IN (select top 1 SCHOOLID from #Temp_ClientRpt where SCHOOLID is not null))
	
	DECLARE @DischRsn VARCHAR(MAX);
	SET @DischRsn = (select Top 1 LookupId from LookUp where LookupCode='Discharge' and LookupType= 'Placement Reason' and ActiveInd='A' and SchoolId IN (select top 1 SCHOOLID from #Temp_ClientRpt where SCHOOLID is not null))

	UPDATE #Temp_ClientRpt SET CLASSID=(SELECT Top 1 Location FROM Placement PT WHERE PT.Location =@DischClass and Status=1 and PlacementReason =@DischRsn and
		PT.StudentPersonalId =#Temp_ClientRpt.StudentPersonalId )
	--UPDATE #Temp_ClientRpt SET CLASSID=(SELECT Top 1 Location FROM Placement PT WHERE PT.Location =@DischClass and Status=1 and
	--	PT.StudentPersonalId =#Temp_ClientRpt.StudentPersonalId)

	UPDATE #Temp_ClientRpt SET [STATUS]=1 where Placement IS NOT NULL
	UPDATE #Temp_ClientRpt SET [STATUS]=0 where Placement IS NULL
	UPDATE #Temp_ClientRpt SET [STATUS]=2 where CLASSID=@DischClass

	DECLARE @STUDNAMETBL table (STUDID int)
	DECLARE @RELATIONTBL table (RELID int)

	DECLARE @STUDSTATUSTBL table (STATID int)
	INSERT INTO @STUDSTATUSTBL(STATID) SELECT * FROM Split(@HContactstatus,',')

	IF(@HContactStudname='All')
		BEGIN
			INSERT INTO @STUDNAMETBL(STUDID) SELECT DISTINCT StudentPersonalId FROM #Temp_ClientRpt
		END

	ELSE
		BEGIN
			INSERT INTO @STUDNAMETBL(STUDID) SELECT * FROM Split(@HContactStudname,',')
		END

	IF(@HContactRelation='All')
		BEGIN
			INSERT INTO @RELATIONTBL(RELID) SELECT LookupId FROM LookUp WHERE LookupType='Relationship'
		END

	ELSE
		BEGIN
			INSERT INTO @RELATIONTBL(RELID) SELECT * FROM Split(@HContactRelation,',')
		END
	DELETE FROM #Temp_ClientRpt WHERE PROGRAM IS NULL AND STATUS <> 2;
	SELECT * FROM #Temp_ClientRpt 
		where STUDENTPERSONALID IN(SELECT * FROM @STUDNAMETBL) 
		AND [STATUS] IN (SELECT * FROM @STUDSTATUSTBL)
		AND RELATIONSHIPID IN(SELECT * FROM @RELATIONTBL)
		ORDER by REFERRALNAME asc

END

GO
