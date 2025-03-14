USE [MelmarkNE1]
GO
/****** Object:  StoredProcedure [dbo].[IOAPercentage_Calculation]    Script Date: 3/11/2025 4:36:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[IOAPercentage_Calculation]
@NormalSessHdr int,
@IOASessHdr int
AS
BEGIN
	
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION	

	DECLARE @NormalSessHdrID int,
	@IOASessHdrID int,
	@Agreement int,
	@Disagreement int,
	@Total int,
	@ColumnNumber int,
	@ColumnType varchar(50),
	@NumberOfColumn int,
	@Cnt int,
	@StartLoopId int,
	@EndLoopId int,
	@IOAPer float,
	@SmallerTotal float,
	@LargerTotal float,
	@TempScrIOA float,
	@TempScrSess float,
	@IOAPercResult float,
	@IOASTEPVAL varchar(50),
	@NORMALSTEPVAL varchar(50),	
	@cntstep int,
	@IOAPernum float    

	SET @NormalSessHdrID=@NormalSessHdr
	SET @IOASessHdrID=@IOASessHdr
	SET @Agreement=0
	SET @Disagreement=0
	SET @Total=0
	SET @ColumnNumber=0	
	SET @ColumnType=''
	SET @NumberOfColumn=0
	SET @Cnt=1
	SET @StartLoopId=0
	SET @EndLoopId=0
	SET @IOAPernum=0	

	IF OBJECT_ID('tempdb..#Normal') IS NOT NULL  
	DROP TABLE #Normal
	IF OBJECT_ID('tempdb..#IOA') IS NOT NULL  
	DROP TABLE #IOA
	IF OBJECT_ID('tempdb..#COLUMN') IS NOT NULL  
	DROP TABLE #COLUMN

	CREATE TABLE #Normal(ID	int PRIMARY KEY NOT NULL IDENTITY(1,1),ColID int,Coltype varchar(50),Stepval varchar(50));
	CREATE TABLE #IOA(ID	int PRIMARY KEY NOT NULL IDENTITY(1,1),ColID int,Coltype varchar(50),Stepval varchar(50));
	CREATE TABLE #COLUMN(ID	int PRIMARY KEY NOT NULL IDENTITY(1,1),ColID int,IOAPerc float);

	INSERT INTO #Normal
	SELECT Dtl.DSTempSetColId,Col.ColTypeCd,Dtl.StepVal FROM (StdtSessionDtl Dtl INNER JOIN DSTempSetCol Col
	ON Col.DSTempSetColId=Dtl.DSTempSetColId) INNER JOIN StdtSessionStep Stp 
	ON Stp.StdtSessionStepId=Dtl.StdtSessionStepId 
	WHERE StdtSessionHdrId=@NormalSessHdrID ORDER BY Dtl.DSTempSetColId,Dtl.StdtSessionDtlId

	INSERT INTO #IOA
	SELECT Dtl.DSTempSetColId,Col.ColTypeCd,Dtl.StepVal FROM (StdtSessionDtl Dtl INNER JOIN DSTempSetCol Col
	ON Col.DSTempSetColId=Dtl.DSTempSetColId) INNER JOIN StdtSessionStep Stp 
	ON Stp.StdtSessionStepId=Dtl.StdtSessionStepId 
	WHERE StdtSessionHdrId=@IOASessHdrID ORDER BY Dtl.DSTempSetColId,Dtl.StdtSessionDtlId

	INSERT INTO #COLUMN 
	SELECT DISTINCT ColID,NULL FROM #Normal ORDER BY ColID

	SET @NumberOfColumn=(SELECT COUNT(DISTINCT ColID) FROM #Normal)
	WHILE(@NumberOfColumn>0)
	BEGIN
	SET @ColumnNumber=(SELECT ColID FROM #COLUMN WHERE ID=@Cnt)
	SET @cntstep=(SELECT COUNT(ID) FROM #Normal WHERE ColID=@ColumnNumber)
	SET @StartLoopId=(SELECT TOP 1 ID FROM #Normal WHERE ColID=@ColumnNumber ORDER BY ID)
	SET @EndLoopId =(SELECT TOP 1 ID FROM #Normal WHERE ColID=@ColumnNumber ORDER BY ID DESC)
	SET @ColumnType=(SELECT Coltype FROM #Normal WHERE ID=@StartLoopId)
	SET @Agreement=0
	SET @Disagreement=0	
	SET @IOAPernum=0
	SET @SmallerTotal=0.0
	SET @LargerTotal=0.0
	SET @TempScrIOA=0.0
	SET @TempScrSess=0.0

		
	WHILE(@StartLoopId<=@EndLoopId)
	BEGIN
	
	SET @NORMALSTEPVAL=''
	SET @IOASTEPVAL=''
	SET @NORMALSTEPVAL=(SELECT Stepval FROM #Normal WHERE ID=@StartLoopId)
	SET @IOASTEPVAL=(SELECT Stepval FROM #IOA WHERE ID=@StartLoopId)

	IF(@ColumnType='+/-' OR @ColumnType='Prompt' OR @ColumnType='Text')	
	BEGIN

	IF((@NORMALSTEPVAL<>'' OR @IOASTEPVAL<>'')AND(@NORMALSTEPVAL<>'0' OR @IOASTEPVAL<>'0')AND(@NORMALSTEPVAL<>'-1' OR @IOASTEPVAL<>'-1'))
	  BEGIN
	   IF(@NORMALSTEPVAL=@IOASTEPVAL)
		      BEGIN
			   SET @Agreement=@Agreement+1
	         END
	    ELSE 
		     BEGIN
			  SET @Disagreement=@Disagreement+1
	         END
	   END
	 END

	 ELSE
	   BEGIN
	   IF(@NORMALSTEPVAL='-1')
	          BEGIN
	            SET @NORMALSTEPVAL=0
	          END
	          IF(@IOASTEPVAL='-1')
	          BEGIN
	             SET @IOASTEPVAL=0
	           END

	       IF(@ColumnType='DURATION')
	       BEGIN
		   
	          SET @NORMALSTEPVAL=CONVERT(VARCHAR,(SELECT DATEDIFF(SECOND, '00:00:00', @NORMALSTEPVAL) AS Seconds))
	          SET @IOASTEPVAL=CONVERT(VARCHAR,(SELECT DATEDIFF(SECOND, '00:00:00', @IOASTEPVAL) AS Seconds))
	       END
	      IF((@NORMALSTEPVAL='0' AND @IOASTEPVAL='0'))
	      BEGIN
		  SET @IOAPernum=@IOAPernum+1        
		  END	  

	      ELSE
	      BEGIN
			 IF(CONVERT(INT, @NORMALSTEPVAL)>CONVERT(INT,@IOASTEPVAL))
	       BEGIN		   
	          SET @SmallerTotal= CONVERT(FLOAT, @IOASTEPVAL)
	          SET @LargerTotal=CONVERT(FLOAT, @NORMALSTEPVAL)
	        END
	       ELSE
	       BEGIN
	          SET @SmallerTotal=CONVERT(FLOAT, @NORMALSTEPVAL) 
	          SET @LargerTotal=CONVERT(FLOAT, @IOASTEPVAL )
	       END

	       SET @IOAPer=((@SmallerTotal/@LargerTotal))
	       SET @IOAPernum=@IOAPer+@IOAPernum
	       END
	      END
		  
	 SET @StartLoopId=@StartLoopId+1

	END	
	
	IF(@ColumnType='+/-' OR @ColumnType='Prompt' OR @ColumnType='Text')	
	BEGIN
	   IF(@Agreement=0 AND @Disagreement=0)
	     BEGIN
	       SET @IOAPer=100
		   UPDATE #COLUMN SET IOAPerc=@IOAPer WHERE ColID=@ColumnNumber
	     END
       ELSE
	      BEGIN
	         SET @IOAPer=(CONVERT(float,@Agreement)/(CONVERT(float,@Agreement)+CONVERT(float,@Disagreement)))*100
	         UPDATE #COLUMN SET IOAPerc=@IOAPer WHERE ColID=@ColumnNumber
	       END
	  END

	ELSE
	BEGIN
	SET @IOAPer=(CONVERT(float,@IOAPernum)/@cntstep)*100
	UPDATE #COLUMN SET IOAPerc=ROUND(@IOAPer, 0) WHERE ColID=@ColumnNumber
	END


	SET @NumberOfColumn=@NumberOfColumn-1
	SET @Cnt=@Cnt+1
	END

	SET @IOAPercResult=(SELECT AVG(IOAPerc) FROM #COLUMN)
	
	DROP TABLE #COLUMN
	DROP TABLE #Normal
	DROP TABLE #IOA

	UPDATE StdtSessionHdr SET IOAPerc=CONVERT(varchar(50),@IOAPercResult) WHERE StdtSessionHdrId IN (@NormalSessHdrID,@IOASessHdrID) AND IOAInd='Y'
	COMMIT
	END TRY
	BEGIN CATCH
	ROLLBACK
	END CATCH
	
END











GO
