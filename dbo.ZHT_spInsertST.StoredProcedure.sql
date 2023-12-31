USE [MelmarkPA2]
GO
/****** Object:  StoredProcedure [dbo].[ZHT_spInsertST]    Script Date: 7/20/2023 4:46:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ZHT_spInsertST]
                @STID int,
                @StudentID int,
                @ClientName varchar(250),
                @ActiveStatus varchar(1),
                @SeizureDate date,
                @SeizureTime time(7),
                @SeizureDurMin int,
                @SeizureDurSec int, 
                @Unconscious bit,
                @Incontinent bit,
                @Breathe bit, 
                @Speech bit,
                @Flush bit,
                @Cyanotic bit,
                @Cry bit,
                @Limp bit,
                @Rigid bit,
                @Spastic bit,
                @Up bit,
                @Down bit,
                @Right bit,
                @Left bit,
                @Staring bit,
                @Face bit,
                @Body bit,
                @SideL bit,
                @SideR bit,
                @LimbL bit,
                @LimbR bit,
                @Head bit,
                @OtherAb bit,
                @TxtOthAb varchar(max),
                @Asleep bit,
                @Drowsy bit,
                @Confused bit,
                @Self bit,
                @Precipitating varchar(max),
                @Comments varchar(max),        
                @VNS bit,
                @VNS1Time bit,
                @VNS2Time bit,
                @VNS3Time bit,
                @VNS4Time bit,
                @VNS5Time bit,
                @VNSNATime bit,
                
                @VNS1Swipe bit,
                @VNS2Swipe bit,
                @VNS3Swipe bit,
                @VNS4Swipe bit,
                @VNS5Swipe bit,
                
                @NurseNotify bit,
                @NurseID int,
                @NurseName varchar(250),
                @NurseDate date,
                @NurseTime time(7),
                
                @SubmittedByID int,
                @SubmittedByName varchar(250),
                @SubmitDate date,
                @SubmitTime time(7),
                @STstatus varchar(1),
                @DiastatVal varchar(20),
                @Call911Val bit,
                @PlacementVal VARCHAR(25),
                @PlacementTxt VARCHAR(200)
                
                                
AS
                BEGIN
                if(@STstatus = 'S')
                BEGIN
                INSERT INTO [dbo].[ZHT_STMainTable]
           ([StudentID], [ClientName], [STDate], [STTime], [STDurMin], [STDurSec], [SubmittedByID], [SubmittedByName], [SubmissionDate],[SubmissionTime], [Unconsious],[Incontinent], [BreatheNormal], [Speech], [Flushed], [Cyanotic], [Epileptic], [Limp], [Rigid], [Spastic], [EyeUp], [EyeDown],[EyeLeft], [EyeRight],[EyeStare],[Face],[Body],[LSide],[RSide],[LLimb],[RLimb],[Head],[AbOther],[AbExplain], [Asleep], [Drowsy], [Confused], [Self], [VNS], [VNS1Time], [VNS2Time], [VNS3Time], [VNS4Time], [VNS5Time], [VNSNA], [VNS1Swipe], [VNS2Swipe], [VNS3Swipe], [VNS4Swipe], [VNS5Swipe], [NurseNotify], [NurseID], [NurseName], [NurseDate], [NurseTime],[Precipitating], [Comments], [STStatus], [ActiveStatus],[DiastatVal],[Call911Val],[PlacementVal],[PlacementTxt])
     VALUES
           (@StudentID,@ClientName,@SeizureDate,@SeizureTime,RIGHT(CONCAT('0', CAST(@SeizureDurMin AS VARCHAR(2))),2), RIGHT(CONCAT('0', CAST(@SeizureDurSec AS VARCHAR(2))),2), @SubmittedByID, @SubmittedByName, @SubmitDate, @SubmitTime, @Unconscious, @Incontinent, @Breathe, @Speech, @Flush, @Cyanotic, @Cry, @Limp, @Rigid, @Spastic, @Up, @Down, @Left, @Right, @Staring, @Face, @Body, @SideL, @SideR, @LimbL, @LimbR, @Head, @OtherAb, @TxtOthAb, @Asleep, @Drowsy, @Confused, @Self, @VNS, @VNS1Time, @VNS2Time, @VNS3Time, @VNS4Time, @VNS5Time, @VNSNATime, @VNS1Swipe, @VNS2Swipe, @VNS3Swipe, @VNS4Swipe, @VNS5Swipe, @NurseNotify, @NurseID, @NurseName, @NurseDate, @NurseTime,@Precipitating, @Comments, @STstatus, @ActiveStatus,@DiastatVal, @Call911Val,@PlacementVal,@PlacementTxt)

                SELECT @STID = SCOPE_IDENTITY();        
                INSERT INTO [dbo].[ZHT_UpdateData] (ModuleName,ModuleID,UpdateFlag,UpdatedByID,UpdatedByName,UpdateDate,UpdateTime) values('ST',@STID,@STstatus,@SubmittedByID,@SubmittedByName,@SubmitDate,@SubmitTime);         


                END
                ELSE
                BEGIN

                UPDATE [dbo].[ZHT_STMainTable] SET 
                [STDate]=@SeizureDate, [STTime]=@SeizureTime, [STDurMin]=RIGHT(CONCAT('0', CAST(@SeizureDurMin AS VARCHAR(2))),2),
                [STDurSec]=RIGHT(CONCAT('0', CAST(@SeizureDurSec AS VARCHAR(2))),2), [Unconsious] = @Unconscious, [Incontinent] = @Incontinent, 
                [BreatheNormal] = @Breathe, [Speech] = @Speech, [Flushed] = @Flush, [Cyanotic] = @Cyanotic, [Epileptic] = @Cry, [Limp] = @Limp, 
                [Rigid] = @Rigid, [Spastic] = @Spastic, [EyeUp] = @Up, [EyeDown] = @Down, [EyeLeft] = @Left, [EyeRight] = @Right, [EyeStare] = @Staring, 
                [Face] = @Face, [Body] = @Body, [LSide] = @SideL, [RSide] = @SideR, [LLimb] = @LimbL, [RLimb] = @LimbR, [Head] = @Head, [AbOther] = @OtherAb,
                [AbExplain] = @TxtOthAb, [Asleep] = @Asleep, [Drowsy] = @Drowsy, [Confused] = @Confused, [Self] = @Self, [VNS] = @VNS, [VNS1Time] = @VNS1Time,
                [VNS2Time] = @VNS2Time, [VNS3Time] = @VNS3Time, [VNS4Time] = @VNS4Time, [VNS5Time] = @VNS5Time, [VNSNA] = @VNSNATime, [VNS1Swipe] = @VNS1Swipe,
                [VNS2Swipe] = @VNS2Swipe, [VNS3Swipe] = @VNS3Swipe, [VNS4Swipe] = @VNS4Swipe, [VNS5Swipe] = @VNS5Swipe, [NurseNotify] = @NurseNotify, 
                [NurseID] = @NurseID, [NurseName] = @NurseName, [NurseDate] = @NurseDate, [NurseTime] = @NurseTime, [Precipitating] = @Precipitating, 
                [Comments] = @Comments, [STStatus] = @STstatus, [DiastatVal] = @DiastatVal, [Call911Val]=@Call911Val where STID=@STID;

                INSERT INTO [dbo].[ZHT_UpdateData] (ModuleName,ModuleID,UpdateFlag,UpdatedByID,UpdatedByName,UpdateDate,UpdateTime) values('ST',@STID,@STstatus,@SubmittedByID,@SubmittedByName,@SubmitDate,@SubmitTime);         

                END
                                                
                END

GO
