USE [_WIT-AdminDB]
GO

IF object_id('WIT_AutomatischesBackup') IS NULL
    EXEC ('create procedure dbo.WIT_AutomatischesBackup as select 1')
GO

ALTER Procedure [dbo].[WIT_AutomatischesBackup] 
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get Default Values for Backup
	DECLARE @DefaultPath varchar(265)
	DECLARE @MirrorPath varchar(265)
	DECLARE @ChangeBackupType varchar(1)
	DECLARE @Compress varchar(1)
	DECLARE @LogToTable varchar(1)
	DECLARE @CleanupMode varchar(25)
	DECLARE @CleanupTimeHours int

    -- Insert Update DB Table
	exec .dbo.UpdateLocalDatabases	
	
	-- For each DB check if Backup necessary
	-- FULL
	-- if no Backup was done (LastBackupFull is NULL)
	-- if Day and Time ist set
	-- if Active = True 
	-- if in Availgroup and Server is backup prefered
	DECLARE @retVal int
	DECLARE @DB varchar(265)
	DECLARE C cursor for 
			Select distinct DBName,DefaultPath,MirrorPath,LogToTable,Compression,CleanupMode,CleanupTimeHours
			from localdatabases where
			(Active = 1) and
			(Dobackup = 1) and (AvailgroupBackup = 1) and 
			((Lastbackupfull is null) or (
				(datename(w,Getdate()) = FullBackupDay) and
				( (Lastbackupfull is null) or 
					((cast (getdate() as float) - floor(cast(getdate() as float)) > cast (FullBackupStartTime as float) - floor(cast (FullBackupStartTime as float))) 
						and Lastbackupfull < DATEADD(dd, DATEDIFF(dd, 0, getdate()), 0)	)
				)))
	open c
	FETCH NEXT FROM c INTO @DB,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours
	WHILE @@FETCH_STATUS = 0 BEGIN

		EXEC @RetVal = DatabaseBackup
				@Databases = @DB,
				@Directory = @DefaultPath,
				@MirrorDirectory = @MirrorPath,
				@BackupType = N'FULL',
				@CleanupTime = @CleanupTimeHours,
				@CleanupMode = @CleanupMode,
				@MirrorCleanupTime = @CleanupTimeHours,
				@MirrorCleanupMode = @CleanupMode,
				@Compress = @Compress,
				@ChangeBackupType = @ChangeBackupType,
				@LogToTable = @LogToTable

		IF @RetVal = 0 BEGIN
			Update localDatabases SET LastbackupFull = getdate() WHERE DBName = @DB
		END
		FETCH NEXT FROM c INTO @DB,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours
	END
	CLOSE c
	DEALLOCATE c
		
	-- DIFF
	-- if Full was done and all other days
	DECLARE C cursor for 
		Select DBName,DefaultPath,MirrorPath,LogToTable,Compression,CleanupMode,CleanupTimeHours
		from localdatabases
		where
		(Active = 1) and
		(Dobackup = 1) and (AvailgroupBackup = 1) and (datename(w,Getdate()) <> FullBackupDay) and
		(Lastbackupfull < DATEADD(dd, DATEDIFF(dd, 0, getdate()), 0))  
		and (cast (getdate() as float) - floor(cast(getdate() as float)) > cast (FullBackupStartTime as float) - floor(cast (FullBackupStartTime as float))) 
		and (ISNULL(LastBackupDiff,DATEADD(d,-1,Getdate())) < DATEADD(dd, DATEDIFF(dd, 0, getdate()), 0))
	open c
	FETCH NEXT FROM c INTO @DB,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours
	WHILE @@FETCH_STATUS = 0 BEGIN

		EXEC @RetVal = DatabaseBackup
				@Databases = @DB,
				@Directory = @DefaultPath,
				@MirrorDirectory = @MirrorPath,
				@BackupType = N'DIFF',
				@CleanupTime = @CleanupTimeHours,
				@CleanupMode = @CleanupMode,
				@MirrorCleanupTime = @CleanupTimeHours,
				@MirrorCleanupMode = @CleanupMode,
				@Compress = @Compress,
				@ChangeBackupType = @ChangeBackupType,
				@LogToTable = @LogToTable
			
		IF @RetVal = 0 BEGIN
			Update localDatabases SET LastbackupDiff = getdate() WHERE DBName = @DB

		END
		FETCH NEXT FROM c INTO @DB,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours
	END
	CLOSE c
	DEALLOCATE c
	
	-- TLOG
        -- if last Backup time >= LogbackupInterval
	DECLARE C cursor for 
		Select DBName,DefaultPath,MirrorPath,LogToTable,Compression,CleanupMode,CleanupTimeHours
		from localdatabases 
		where
		(Active = 1) and
		(Dobackup = 1) 
		and (AvailgroupBackup = 1) 
		and (Recoverymodel = 1) 
		and (not (LastBackupFull is null)) 
		and DATEDIFF(hh,ISNULL(LastbackupLog,DATEADD(hh,LogbackupInterval * -2,getdate())),getdate()) >= LogbackupInterval 
	open c
	FETCH NEXT FROM c INTO @DB,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours
	WHILE @@FETCH_STATUS = 0 BEGIN

		EXEC @RetVal = DatabaseBackup
				@Databases = @DB,
				@Directory = @DefaultPath,
				@MirrorDirectory = @MirrorPath,
				@BackupType = N'LOG',
				@CleanupTime = @CleanupTimeHours,
				@CleanupMode = @CleanupMode,
				@MirrorCleanupTime = @CleanupTimeHours,
				@MirrorCleanupMode = @CleanupMode,
				@Compress = @Compress,
				@ChangeBackupType = @ChangeBackupType,
				@LogToTable = @LogToTable
				
		IF @RetVal = 0 BEGIN
			Update localDatabases SET LastbackupLog = getdate() WHERE DBName = @DB
		END
		FETCH NEXT FROM c INTO @DB,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours
	END
	CLOSE c
	DEALLOCATE c
	
END

