USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[Client_PA_StaffName_Update(NewMethod)]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Client_PA_StaffName_Update(NewMethod)] 
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


	DECLARE @StfTableNewName TABLE 
	(
		StfID INT IDENTITY(1, 1) NOT NULL, 
		StfsName VARCHAR(MAX),
		StfsNewName VARCHAR(MAX)
	)

	--# [Section 1] #-- [Inserting Correct Names to Temporary table] -- START
	-------------------------------------------------------------------------
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Aaron Pierre', 'Aaron Pierre')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Abbey Markovich', 'Abigail Markovich')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Abby Markovich', 'Abigail Markovich')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Abdul Bundu', 'Abdul Bundu')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Abigail Dikenah', 'Abigail Dikenah')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Adam Golden', 'Adam Golden')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Adeyemi Adeyiga', 'Adeyemi Adeyiga')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Aisha Peltier', 'Aisha Peltier')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Alex Held', 'Alex Held')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Allan Miller', 'Allan Miller')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Allusine Kamara', 'Alusine Kamara')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Allusine Kamra', 'Alusine Kamara')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Alusne Kamara', 'Alusine Kamara')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Amanda Finlay', 'Amanda Finlay')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Amanda Lawn', 'Amanda Lawn')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Amelia Scott', 'Amelia Scott')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Amy Dempsey', 'Amy Dempsey') 
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Amy Depmsey', 'Amy Dempsey')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Amy Dempsy', 'Amy Dempsey')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Andrew Grasso', 'Andrew Grasso')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Anna Eisenberg', 'Anna Eisenberger')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Anna Eisenberger', 'Anna Eisenberger')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Anna Van Dam', 'Anna VanDam')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('BeckyLatchford', 'Rebecca Latchford')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Boradfuerher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Broadfeuher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Broadfeurher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Broadfuerher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Broadfuher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Broadfurher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Brodferher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Brodfeuher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Brodfeurher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Brodfuehrer', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Brodfuerher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ben Brodfuher', 'Ben Brodfuehrer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Beth Briggs', 'Beth Briggs')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Bethany Rose', 'Bethany Rose')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Bonnie Warren', 'Bonnie Warren')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Brian Hinchcliffe', 'Brian Hinchcliffe')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Brian Hinchcliffe', 'Brian Hinchcliffe')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Briana Finch', 'Briana Finch')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Brianna Finch', 'Briana Finch')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Brittani Moss', 'Brittani Moss')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Brittney Paye', 'Brittney Paye')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Brittni May', 'Brittni May')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Cairlin Harrington', 'Caitlin Harrington')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Caitlin Harington', 'Caitlin Harrington')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Caitlin Harrington', 'Caitlin Harrington')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Caitlin Sullivan', 'Caitlin Harrington')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Caitlyn Harrington', 'Caitlin Harrington')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Caityln Harrington', 'Caitlin Harrington')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Chantal Wildman', 'Chantal Wildman') 
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Charye Tarlue', 'Charlotte Laurie') 
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Charlotte Laurie', 'Charlotte Laurie')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Cheryl Allison-Webber', 'Cheryl Webber')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Chris Cornine', 'Christopher Cornine')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Chrisitne Wolf', 'Christine Wolfe')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Christian Jones', 'Christian Jones')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Christiana Skinner Walker', 'Christiana Skinner-Walker')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Christiana Skinner-Walker', 'Christiana Skinner-Walker')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Christine Johnson', 'Christine Johnson')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Christine Wolfe', 'Christine Wolfe')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Christopher Cornine', 'Christopher Cornine')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Chrystine Karama', 'Chrystine Karama')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Churye Tarlue', 'Churye Tarlue')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Claudia Baker', 'Claudia Baker')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Comfort Ibare-Jones', 'Comfort Ibare-Jones')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Corie Salter', 'Corie Salter')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Cortney Crockett', 'Cortney Crockett')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Cyndie Burke', 'Cyndie Burke')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Dan Bebernitz', 'Daniel Bebernitz')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Dana Sundo', 'Dana Sundo')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Daniel Bebernitz', 'Daniel Bebernitz')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Danielle Jubic', 'Danielle Jubic')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Dara Parris', 'Dara Parris')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Dashay Love', 'Dashay Love')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Dave Haneman', 'David Haneman')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Deb Murray', 'Debra Murray')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Deborah Haga', 'Deborah Haga')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Elizabeth Briggs-Varallo', 'Elizabeth Briggs-Varallo')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Elizabeth Luna', 'Elizabeth Luna')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Elizabeth Middlecamp', 'Elizabeth Middlecamp') 
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Elizabeth Moore', 'Elizabeth Moore')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Elizabrth Middlecamp', 'Elizabeth Middlecamp')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erica Hanstein', 'Erica Yelson')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erica Heinstein', 'Erica Yelson')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erica Harriot', 'Erica Harriott')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erica Yelson', 'Erica Yelson')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erin Harrison', 'Erin Harrison')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erin Harriso', 'Erin Harrison')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erin Smith', 'Erin Smith')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Erin Way', 'Erin Way')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Evelyn Gilsky', 'Evelyn Gilsky')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Evie Gilsky', 'Evelyn Gilsky')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Evita Vincent', 'Evita Vincent')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Felisa Leonard', 'Felisa Leonard')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Florence Jossy', 'Florence Jossy')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Frances DiProspero', 'Frances DiProspero')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Gail Switzer', 'Gail Switzer')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Gene Lites', 'Gene Lites')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Gene Littes', 'Gene Lites')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Gina Cheng', 'Gina Cheng')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Greater Nyamayaro', 'Greater Nyamayaro')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Hatim Ali', 'Hatim Ali')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Heather Bennett', 'Heather Bennett')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Helena Johnson', 'Helena Johnson')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Herra Degefa', 'Herra Degefa')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Herra Degeffa', 'Herra Degefa')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Hilalry Viola', 'Hillary Viola')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Hillary Viola', 'Hillary Viola')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Hllary Viola', 'Hillary Viola')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ibilola Adeyemi', 'Ibilola Adeyemi')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('IIbliola Adeyemi', 'Ibilola Adeyemi')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Iris Miller', 'Iris Miller')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Irma Hyka', 'Irma Hyka')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jacob Moye', 'Jacob Moye')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('James Martyn', 'James Martyn')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jamill Jones', 'Jamill Jones')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jarrett Cutsler', 'Jarrett Cutsler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jay Salee', 'Jay Salee')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jenessa Holser', 'Jenessa Hosler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jenessa Hosler', 'Jenessa Hosler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jenessa Hossler', 'Jenessa Hosler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jennesa Holser', 'Jenessa Hosler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jennfer Adams', 'Jennifer Adams')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jennifer Adams', 'Jennifer Adams')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jennifer Campbell', 'Jennifer Campbell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jennifer Quigley', 'Jennifer Quigley')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jennifer Roma', 'Jennifer Roma')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jessica Arndt', 'Jessica Arndt')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jessica Mercante', 'Jessica Mercante')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jill Pesansky', 'Jill Pesansky')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Jocob Moye', 'Jacob Moye')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Judy Schlosser', 'Judy Schlosser')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kelly Mieczkowski', 'Kelly Mieczkowski')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kelly Mulhall', 'Kelly Mulhall')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kelly Mullhall', 'Kelly Mulhall')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kelsey Hunter', 'Kelsey Hunter')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kevin Sigler', 'Kevin Sigler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kim Beebe', 'Kimberly Beebe')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kristen LeFevre', 'Kristin LeFevre')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kristin LeFevre', 'Kristin LeFevre')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Krystina Cassidy', 'Krystina Cassidy')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Kylee Formento', 'Kylee Formento')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lara Newkirk', 'Lara Newkirk')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('LaTanya Gans', 'Latanya Gans')	
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Laura Ann Patton', 'Lauraanne Patton')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Laura Diaz', 'Laura Diaz')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('LauraAnn Patton', 'Lauraanne Patton')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lauraanne Patton', 'Lauraanne Patton')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lauren Carson', 'Lauren Carson')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lauren Cook', 'Lauren Cook')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lee Fowler', 'Lee Fowler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lindsey Ritter', 'Lindsey Feeley')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Liz Dayton', 'Liz Dayton')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Liz Middlecamp', 'Elizabeth Middlecamp')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Louise ODonnell', 'Louise O''Donnell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Louie O''Donnell', 'Louise O''Donnell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Louise O''Donnell', 'Louise O''Donnell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lydia Bunda', 'Lydia Bunda')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lydia Shoriwa', 'Lydia Shoriwa')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lydis Shoriwa', 'Lydia Shoriwa')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Lynne Smiley', 'Lynne Smiley')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Maddi Alfred', 'Maddi Alfred')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Maria Loftus', 'Maria Loftus')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Marianna Maggiore', 'Marianna Maggiore')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mariannna Maggiore', 'Marianna Maggiore')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mary Easton', 'Mary Elizabeth Easton')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mary Elizabeth Easton', 'Mary Elizabeth Easton')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mary Odira', 'Mary Odira')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mary Parris', 'Mary Parris')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Matt Callan', 'Matthew Callan')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Matthew Callan', 'Matthew Callan')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Meaghan Chirinos', 'Meaghan Chirinos')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Megan Kapinos', 'Megan Kapinos')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Megan Riley', 'Megan Riley')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Michael Kiotis', 'Michael Kiotis')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Michael Roesch', 'Michael Roesch')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mike Kiotis', 'Michael Kiotis')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mike Roesch', 'Michael Roesch')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Monica Crimi', 'Monica Crimi')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Morgan Benner', 'Morgan Benner')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Mustapha Kanneh', 'Mustapha Kanneh')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Nadia Campbell', 'Nadine Campbell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Nadine Campbell', 'Nadine Campbell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Natalie Baker', 'Natalie Baker')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Natalie Tweh', 'Natalie Tweh')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Niki Buckner', 'Niki Buckner')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Nivause Julmice', 'Nivause Julmice')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Patricia Carey', 'Patricia Carey')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Pennah Karnuah', 'Penneh Karnuah')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Penneh Karnuah', 'Penneh Karnuah')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Polly Cutler', 'Polly Cutler')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Pricilla Browne', 'Priscilla Browne')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Priscilla Brown', 'Priscilla Browne')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Priscilla Browne', 'Priscilla Browne')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ranisha Childress', 'Ranisha Childress')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Ranisha Chindress', 'Ranisha Childress')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Rebecca Latchford', 'Rebecca Latchford')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Rebecca Zelonis', 'Rebecca Zelonis')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Robin Holts cover Tue-Thur', 'Robin Holts')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sam Hundeyin', 'Samuel Hundeyin')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Samantha Russo', 'Samantha Russo')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Samuel Hundeyin', 'Samuel Hundeyin')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sarah Fabian', 'Sarah Fabian')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sarah Maher', 'Sarah Maher')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Shaleea Curtis-Raford', 'Shaleeta Curtis-Radford')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Shaleeta Curtis Radford', 'Shaleeta Curtis-Radford')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Shaleeta Curtis-Radford', 'Shaleeta Curtis-Radford')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Shawn Feeley', 'Shawn Feeley')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sheila Klick', 'Sheila Klick')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sherell Lawrence', 'Sherrell Lawrence')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sherrell Lawrence', 'Sherrell Lawrence')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Stephanie Bearish', 'Stephanie Bearish')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Stephanie Berish', 'Stephanie Bearish')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Stephanie Coward', 'Stephanie Coward')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Stephanie Delpapa', 'Stephanie Delpapa')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Stephanie Fell', 'Stephanie Fell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Stephanie Howell', 'Stephanie Howell')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Steve George - Day Maddie Alfred - Night', 'Steven George')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Steven George', 'Steven George')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sue DelPrato', 'Sue Delprato')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sue Graves', 'Sue Graves')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sulaiman Johnny', 'Sulaiman Johnny')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Sunday Adebayo', 'Sunday Adebayo')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Tamar Smith', 'Tamar Smith')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Tamara Watkins', 'Tamara Watkins')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Tashi Rowe', 'Tashai Rowe')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Tonya Hough', 'Tanya Hough')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Vanessa Rogers', 'Vanessa Rogers')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Veronica Greiner', 'Veronica Greiner')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Verusca Lutz', 'Verusca Lutz')
	INSERT INTO @StfTableNewName(StfsName,StfsNewName) VALUES ('Will Gree', 'Will Gree')
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

		UPDATE StudentPersonal SET TeacherInstructor = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.TeacherInstructor = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ProgramSpecialist = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.ProgramSpecialist = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET EDUBehaviorAnalyst = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.EDUBehaviorAnalyst = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET CurriculumCoordinator = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.CurriculumCoordinator = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ResidentialProgram = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.ResidentialProgram = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ProgramManagerQMRP = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.ProgramManagerQMRP = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET HouseSupervisor = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.HouseSupervisor = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET ResidentialBehaviorAnalyst = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.ResidentialBehaviorAnalyst = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PrimaryNurse = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.PrimaryNurse = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET UnitClerk = STN.StfsNewName FROM StudentPersonal ST INNER JOIN @StfTableNewName STN ON ST.UnitClerk = STN.StfsName WHERE ST.StudentPersonalId = @StudentID
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


		--[Section 3 - Student Table Userids adn Position Details Update] -- START
		--------------------------------------------------------------------------
		---- (If verification required only)
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Teacher Instructor') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.TeacherInstructor = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Program Specialist') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ProgramSpecialist = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'EDU Behavior Analyst') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.EDUBehaviorAnalyst = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Curriculum Coordinator') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.CurriculumCoordinator = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Residential Program') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ResidentialProgram = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Program Manager QMRP') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ProgramManagerQMRP = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'House Supervisor') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.HouseSupervisor = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Residential Behavior Analyst') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ResidentialBehaviorAnalyst = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Primary Nurse') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.PrimaryNurse = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		--SELECT 'S'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Unit Clerk') AS VARCHAR(500))+','+'P'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.UnitClerk = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))
		
		
		UPDATE StudentPersonal SET PositionStaff1  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Teacher Instructor') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.TeacherInstructor = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff2  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Program Specialist') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ProgramSpecialist = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff3  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'EDU Behavior Analyst') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.EDUBehaviorAnalyst = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff4  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Curriculum Coordinator') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.CurriculumCoordinator = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff5  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Residential Program') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ResidentialProgram = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff6  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Program Manager QMRP') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ProgramManagerQMRP = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff7  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'House Supervisor') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.HouseSupervisor = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff8  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Residential Behavior Analyst') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.ResidentialBehaviorAnalyst = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		UPDATE StudentPersonal SET PositionStaff9  = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Primary Nurse') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.PrimaryNurse = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID		
		UPDATE StudentPersonal SET PositionStaff10 = (SELECT 'P'+CAST((SELECT LookupId FROM LookUp WHERE LookupType = 'StaffPositionLabelPA' and LookupName = 'Unit Clerk') AS VARCHAR(500))+','+'S'+CAST((SELECT UR.UserId from [User] UR INNER JOIN StudentPersonal SP ON SP.UnitClerk = CONCAT(UR.UserFName,' '+UR.UserLname) WHERE SP.StudentPersonalId = @StudentID AND UR.ActiveInd ='A')AS VARCHAR(500))) WHERE StudentPersonalId = @StudentID
		--------------------------------------------------------------------------
		--[Section 3 - Student Table Userids adn Position Details Update] -- END


		SELECT
		[Extent1].[StudentPersonalId] AS [StudentPersonalId], 
		[Extent1].[SchoolId] AS [SchoolId], 
		[Extent1].[LastName] +', '+ [FirstName] AS [StudentName], 
		[Extent1].[PositionStaff1] AS [PositionStaff1],
		[Extent1].[PositionStaff2] AS [PositionStaff2],
		[Extent1].[PositionStaff3] AS [PositionStaff3],
		[Extent1].[PositionStaff4] AS [PositionStaff4],
		[Extent1].[PositionStaff5] AS [PositionStaff5],
		[Extent1].[PositionStaff6] AS [PositionStaff6],
		[Extent1].[PositionStaff7] AS [PositionStaff7],
		[Extent1].[PositionStaff8] AS [PositionStaff8],
		[Extent1].[PositionStaff9] AS [PositionStaff9],
		[Extent1].[PositionStaff10] AS [PositionStaff10]
		FROM [dbo].[StudentPersonal] AS [Extent1]		
		WHERE [Extent1].StudentPersonalId = @StudentID and [Extent1].SchoolId = 2  -- Verification of User ids and positions Updated in the StudentPersonal Table

		PRINT 'Update for Student ID ===> ' + CAST(@StudentID AS VARCHAR(500)) + ' [Completed] ' + CHAR(10)

	SET @StudentInc = @StudentInc + 1
	END


END

GO
