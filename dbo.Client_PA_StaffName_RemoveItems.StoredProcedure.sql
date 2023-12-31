USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Client_PA_StaffName_RemoveItems]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Client_PA_StaffName_RemoveItems] 
@GetStudentID VARCHAR(5000)
	
AS
BEGIN
	
	SET NOCOUNT ON;	

 	DECLARE @StudPID TABLE 
	(
		StuID INT IDENTITY(1, 1) NOT NULL, 
		StdID INT,
		StuSchId INT,
		StuName VARCHAR(MAX),
		StuClass VARCHAR(MAX)
	)
	INSERT INTO @StudPID(StdID) SELECT * FROM Split(@GetStudentID,',') OPTION (MAXRECURSION 5000)


	DECLARE @RemoveItems TABLE 
	(
		rmvID INT IDENTITY(1, 1) NOT NULL, 
		remvitem VARCHAR(MAX)
	)

	--# [Section 1] #-- [Inserting Correct Names to Temporary table] -- START
	-------------------------------------------------------------------------
	INSERT @RemoveItems (remvitem) VALUES ('aa')
	INSERT @RemoveItems (remvitem) VALUES ('aaa')
	INSERT @RemoveItems (remvitem) VALUES ('aaaa')
	INSERT @RemoveItems (remvitem) VALUES ('asas')
	INSERT @RemoveItems (remvitem) VALUES ('asasa')
	INSERT @RemoveItems (remvitem) VALUES ('aaaaa')
	INSERT @RemoveItems (remvitem) VALUES ('aaaaaa')
	INSERT @RemoveItems (remvitem) VALUES ('aaaaaaa')
	INSERT @RemoveItems (remvitem) VALUES ('asasa-DD')
	INSERT @RemoveItems (remvitem) VALUES ('asasaLLL')
	INSERT @RemoveItems (remvitem) VALUES ('asasas')
	INSERT @RemoveItems (remvitem) VALUES ('asasas')
	INSERT @RemoveItems (remvitem) VALUES ('asasasHHH')
	INSERT @RemoveItems (remvitem) VALUES ('asasasKKK')
	INSERT @RemoveItems (remvitem) VALUES ('asasFF')
	INSERT @RemoveItems (remvitem) VALUES ('Aston A')
	INSERT @RemoveItems (remvitem) VALUES ('Aston B')
	INSERT @RemoveItems (remvitem) VALUES ('BB')
	INSERT @RemoveItems (remvitem) VALUES ('Burdett')
	INSERT @RemoveItems (remvitem) VALUES ('Carriage')
	INSERT @RemoveItems (remvitem) VALUES ('Carriage House')
	INSERT @RemoveItems (remvitem) VALUES ('CC')
	INSERT @RemoveItems (remvitem) VALUES ('Chichester')
	INSERT @RemoveItems (remvitem) VALUES ('Childen''s Nurse')
	INSERT @RemoveItems (remvitem) VALUES ('Children''s Nurse')
	INSERT @RemoveItems (remvitem) VALUES ('Collins')
	INSERT @RemoveItems (remvitem) VALUES ('Collins Drive')
	INSERT @RemoveItems (remvitem) VALUES ('DFG')
	INSERT @RemoveItems (remvitem) VALUES ('DFG')
	INSERT @RemoveItems (remvitem) VALUES ('DFG')
	INSERT @RemoveItems (remvitem) VALUES ('Dixon')
	INSERT @RemoveItems (remvitem) VALUES ('Dixon House')
	INSERT @RemoveItems (remvitem) VALUES ('Domenic Tribuiani')
	INSERT @RemoveItems (remvitem) VALUES ('ED A')
	INSERT @RemoveItems (remvitem) VALUES ('eduba')
	INSERT @RemoveItems (remvitem) VALUES ('Engle')
	INSERT @RemoveItems (remvitem) VALUES ('Engle House')
	INSERT @RemoveItems (remvitem) VALUES ('FDG')
	INSERT @RemoveItems (remvitem) VALUES ('FGH')	
	INSERT @RemoveItems (remvitem) VALUES ('Gallagher')
	INSERT @RemoveItems (remvitem) VALUES ('Gate')
	INSERT @RemoveItems (remvitem) VALUES ('Gate House')
	INSERT @RemoveItems (remvitem) VALUES ('Georgia Kayree')
	INSERT @RemoveItems (remvitem) VALUES ('Gergia Kayree')
	INSERT @RemoveItems (remvitem) VALUES ('Gerogia Kayree') 
	INSERT @RemoveItems (remvitem) VALUES ('Ghallager') 
	INSERT @RemoveItems (remvitem) VALUES ('HHH')
	INSERT @RemoveItems (remvitem) VALUES ('Holcomb')
	INSERT @RemoveItems (remvitem) VALUES ('hs')
	INSERT @RemoveItems (remvitem) VALUES ('Hunt Valley')
	INSERT @RemoveItems (remvitem) VALUES ('ICF-Aston B')
	INSERT @RemoveItems (remvitem) VALUES ('Kim Simonds')
	INSERT @RemoveItems (remvitem) VALUES ('Liz Cardin')
	INSERT @RemoveItems (remvitem) VALUES ('Lodge')
	INSERT @RemoveItems (remvitem) VALUES ('Lyons')
	INSERT @RemoveItems (remvitem) VALUES ('Martha')
	INSERT @RemoveItems (remvitem) VALUES ('Martha House')
	INSERT @RemoveItems (remvitem) VALUES ('Matthew')
	INSERT @RemoveItems (remvitem) VALUES ('Matthew House')
	INSERT @RemoveItems (remvitem) VALUES ('Meadowbrook')
	INSERT @RemoveItems (remvitem) VALUES ('Meadows')
	INSERT @RemoveItems (remvitem) VALUES ('Meaningful Day')
	INSERT @RemoveItems (remvitem) VALUES ('meaningful Day')
	INSERT @RemoveItems (remvitem) VALUES ('Melissa A')
	INSERT @RemoveItems (remvitem) VALUES ('Melissa A ICF')
	INSERT @RemoveItems (remvitem) VALUES ('Melissa B')
	INSERT @RemoveItems (remvitem) VALUES ('Melissa B ICF')
	INSERT @RemoveItems (remvitem) VALUES ('Miller A')
	INSERT @RemoveItems (remvitem) VALUES ('Miller B')
	INSERT @RemoveItems (remvitem) VALUES ('na')
	INSERT @RemoveItems (remvitem) VALUES ('na')
	INSERT @RemoveItems (remvitem) VALUES ('na')
	INSERT @RemoveItems (remvitem) VALUES ('Nancy Cook Cassandra Kodym')
	INSERT @RemoveItems (remvitem) VALUES ('Nancy Cook Cassandra Kodym')
	INSERT @RemoveItems (remvitem) VALUES ('PLF- Lodge')
	INSERT @RemoveItems (remvitem) VALUES ('PM QMRP')
	INSERT @RemoveItems (remvitem) VALUES ('pmqmrp')
	INSERT @RemoveItems (remvitem) VALUES ('pn')
	INSERT @RemoveItems (remvitem) VALUES ('Pogram Specialist')
	INSERT @RemoveItems (remvitem) VALUES ('Primry N')
	INSERT @RemoveItems (remvitem) VALUES ('ps')
	INSERT @RemoveItems (remvitem) VALUES ('R Program')
	INSERT @RemoveItems (remvitem) VALUES ('Radnor Crossing')
	INSERT @RemoveItems (remvitem) VALUES ('rba')
	INSERT @RemoveItems (remvitem) VALUES ('rba')
	INSERT @RemoveItems (remvitem) VALUES ('Residential BA')
	INSERT @RemoveItems (remvitem) VALUES ('Richard Road')
	INSERT @RemoveItems (remvitem) VALUES ('Richards Road')
	INSERT @RemoveItems (remvitem) VALUES ('Rosary Lane')
	INSERT @RemoveItems (remvitem) VALUES ('Royer Greaves School for The Blind')
	INSERT @RemoveItems (remvitem) VALUES ('Sacca')
	INSERT @RemoveItems (remvitem) VALUES ('Sacca House')
	INSERT @RemoveItems (remvitem) VALUES ('Salloh Janneh')
	INSERT @RemoveItems (remvitem) VALUES ('Salloh Kanneh')
	INSERT @RemoveItems (remvitem) VALUES ('Salloh Kanneh')
	INSERT @RemoveItems (remvitem) VALUES ('sasas')
	INSERT @RemoveItems (remvitem) VALUES ('sasasas')
	INSERT @RemoveItems (remvitem) VALUES ('sasasas')
	INSERT @RemoveItems (remvitem) VALUES ('sasasas')
	INSERT @RemoveItems (remvitem) VALUES ('sasasasDD')
	INSERT @RemoveItems (remvitem) VALUES ('sasasasGG')
	INSERT @RemoveItems (remvitem) VALUES ('sasasasMM')
	INSERT @RemoveItems (remvitem) VALUES ('sasasdd')
	INSERT @RemoveItems (remvitem) VALUES ('Schoemaker')
	INSERT @RemoveItems (remvitem) VALUES ('Seventh Ave')
	INSERT @RemoveItems (remvitem) VALUES ('Seventh Avenue')
	INSERT @RemoveItems (remvitem) VALUES ('Sherman')
	INSERT @RemoveItems (remvitem) VALUES ('Spruce A')
	INSERT @RemoveItems (remvitem) VALUES ('Spruce B')
	INSERT @RemoveItems (remvitem) VALUES ('Spruce B ICF')
	INSERT @RemoveItems (remvitem) VALUES ('sssaas')
	INSERT @RemoveItems (remvitem) VALUES ('sssaasJJJ')
	INSERT @RemoveItems (remvitem) VALUES ('Stanley Fallah')
	INSERT @RemoveItems (remvitem) VALUES ('Stanley Fallah')
	INSERT @RemoveItems (remvitem) VALUES ('Summit')
	INSERT @RemoveItems (remvitem) VALUES ('T Instructor')
	INSERT @RemoveItems (remvitem) VALUES ('Thomas')
	INSERT @RemoveItems (remvitem) VALUES ('ti')
	INSERT @RemoveItems (remvitem) VALUES ('Tori Bayliff')
	INSERT @RemoveItems (remvitem) VALUES ('U Clerk')
	INSERT @RemoveItems (remvitem) VALUES ('uc')
	INSERT @RemoveItems (remvitem) VALUES ('UCC')
	INSERT @RemoveItems (remvitem) VALUES ('VACANT')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant- See Jennie Labowitz')
	INSERT @RemoveItems (remvitem) VALUES ('Vacant- See Jennie Labowitz')
	INSERT @RemoveItems (remvitem) VALUES ('Valley View')
	INSERT @RemoveItems (remvitem) VALUES ('Wayne')
	INSERT @RemoveItems (remvitem) VALUES ('Weir Road')
	INSERT @RemoveItems (remvitem) VALUES ('Widener')
	-------------------------------------------------------------------------
	--# [Section 1] # -- [Inserting Correct Names to Temporary table] -- END
	
		
	DECLARE @StudentInc INT = 1
	DECLARE @StudentCount INT = (SELECT COUNT(StdID) FROM @StudPID)
	DECLARE @StudentID INT 

		
	--SELECT * FROM @StfTableNewName -- Verification of Original Names of Staff in Temp Table

	WHILE (@StudentInc <= @StudentCount)
	BEGIN
	
		SET @StudentID = (SELECT StdID FROM @StudPID WHERE StuID = @StudentInc)
		

		--# [Section 1A] # - [Temp Table Student Details Table Update] -- START
		-----------------------------------------------------------------------
		UPDATE @StudPID SET StuSchId = SP.SchoolId FROM StudentPersonal SP WHERE SP.StudentPersonalId = @StudentID
		UPDATE @StudPID SET StuName = CONCAT(SP.LastName,' '+SP.FirstName) FROM StudentPersonal SP WHERE SP.StudentPersonalId = @StudentID
		UPDATE @StudPID SET StuClass = (SELECT STUFF((SELECT ', '+CLS.ClassName FROM Placement PLC INNER JOIN Class CLS ON PLC.Location = CLS.ClassId WHERE (PLC.EndDate IS NULL OR PLC.EndDate IS NOT NULL) AND CLS.ActiveInd ='A' AND PLC.StudentPersonalId = @StudentID FOR XML PATH('')), 1, 1, ''))
		-----------------------------------------------------------------------
		--# [Section 1A] # - [Temp Table Student Details Table Update] -- END

		PRINT CHAR(10) + 'Update for Student ID ===> ' + CAST(@StudentID AS VARCHAR(500)) + ' [Initiated]'
		SELECT * FROM @StudPID WHERE StdID = @StudentID

		
		--# [Section 2] # - Student Table Original User Name Details Update] -- START
		-----------------------------------------------------------------------------
		---- (If verification required only)
		--SELECT SP.StudentPersonalId, SP.TeacherInstructor FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.TeacherInstructor = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.ProgramSpecialist FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.ProgramSpecialist = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.EDUBehaviorAnalyst FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.EDUBehaviorAnalyst = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.CurriculumCoordinator FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.CurriculumCoordinator = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.ResidentialProgram FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.ResidentialProgram = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.ProgramManagerQMRP FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.ProgramManagerQMRP = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.HouseSupervisor FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.HouseSupervisor = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.ResidentialBehaviorAnalyst FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.ResidentialBehaviorAnalyst = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.PrimaryNurse FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.PrimaryNurse = STN.StfsName WHERE SP.StudentPersonalId = @StudentID
		--SELECT SP.StudentPersonalId, SP.UnitClerk FROM StudentPersonal SP INNER JOIN @StfTableNewName STN ON SP.UnitClerk = STN.StfsName WHERE SP.StudentPersonalId = @StudentID

		UPDATE StudentPersonal SET TeacherInstructor = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.TeacherInstructor = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ProgramSpecialist = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.ProgramSpecialist = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET EDUBehaviorAnalyst = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.EDUBehaviorAnalyst = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET CurriculumCoordinator = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.CurriculumCoordinator = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ResidentialProgram = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.ResidentialProgram = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ProgramManagerQMRP = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.ProgramManagerQMRP = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET HouseSupervisor = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.HouseSupervisor = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ResidentialBehaviorAnalyst = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.ResidentialBehaviorAnalyst = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PrimaryNurse = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.PrimaryNurse = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET UnitClerk = NULL FROM StudentPersonal ST INNER JOIN @Removeitems STN ON ST.UnitClerk = STN.remvitem WHERE ST.StudentPersonalId = @StudentID
		-----------------------------------------------------------------------------
		--[Section 2 - Student Table Original User Name Details Update] -- END
		
		SELECT
		[Extent1].[StudentPersonalId] AS [StudentPersonalId],  
		[Extent1].[SchoolId] AS [SchoolId], 
		[Extent1].[LastName] +', '+ [FirstName] AS [StudentName], 		
		[Extent1].[TeacherInstructor] AS [TeacherInstructor], 
		[Extent1].[ProgramSpecialist] AS [ProgramSpecialist], 
		[Extent1].[EDUBehaviorAnalyst] AS [EDUBehaviorAnalyst], 
		[Extent1].[CurriculumCoordinator] AS [CurriculumCoordinator], 
		[Extent1].[ResidentialProgram] AS [ResidentialProgram], 
		[Extent1].[ProgramManagerQMRP] AS [ProgramManagerQMRP], 
		[Extent1].[HouseSupervisor] AS [HouseSupervisor], 
		[Extent1].[ResidentialBehaviorAnalyst] AS [ResidentialBehaviorAnalyst], 
		[Extent1].[PrimaryNurse] AS [PrimaryNurse], 
		[Extent1].[UnitClerk] AS [UnitClerk]
		FROM [dbo].[StudentPersonal] AS [Extent1]		
		WHERE [Extent1].StudentPersonalId = @StudentID and [Extent1].SchoolId = 2 -- Verification of Original Names Updated in the StudentPersonal Table


		PRINT 'Update for Student ID ===> ' + CAST(@StudentID AS VARCHAR(500)) + ' [Completed] ' + CHAR(10)

	SET @StudentInc = @StudentInc + 1
	END


END

GO
