USE [_WIT-AdminDB]
GO

IF object_id('UpdateLocalDatabases') IS NULL
    EXEC ('create procedure dbo.UpdateLocalDatabases as select 1')

GO 

ALTER PROCEDURE [dbo].[UpdateLocalDatabases]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Version numeric(18,10)
	SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))
	
	-- Get Default Values for Backup
	DECLARE @DefaultPath varchar(265)
	DECLARE @MirrorPath varchar(265)
	DECLARE @ChangeBackupType varchar(1)
	DECLARE @Compress varchar(1)
	DECLARE @LogToTable varchar(1)
	DECLARE @CleanupMode varchar(25)
	DECLARE @CleanupTimeHours int

	SET @DefaultPath = (select [Value] FROM BackupSettings WHERE Setting = 'defaultpath')
	SET @MirrorPath = (select [Value] FROM BackupSettings WHERE Setting = 'mirrorpath')
	SET @ChangeBackupType = (select [Value] FROM BackupSettings WHERE Setting = 'ChangeBackupType')
	SET @Compress = (select [Value] FROM BackupSettings WHERE Setting = 'Compression')
	SET @LogToTable = (select [Value] FROM BackupSettings WHERE Setting = 'LogToTable')
	SET @CleanupMode = (select [Value] FROM BackupSettings WHERE Setting = 'CleanupMode')
	SET @CleanupTimeHours = (select [Value] FROM BackupSettings WHERE Setting = 'CleanupTimeHours')

    -- Insert Update DB Table
	IF @Version >= 14 BEGIN
		BEGIN TRAN
		MERGE INTO LocalDatabases as Dest
		USING
		(SELECT db.[name] AS DBName, 		
		CASE WHEN db.name IN('master','msdb','model') THEN 'S' ELSE 'U' END AS DatabaseType, db.recovery_model as Recoverymodel, ag.name as Availgroupname, 
		[master].sys.fn_hadr_backup_is_preferred_replica(db.name) as AvailGroupBackup
		FROM sys.databases as db
		left outer join (SELECT availability_databases_cluster.database_name, availability_groups.name
			FROM sys.availability_databases_cluster availability_databases_cluster
			INNER JOIN sys.availability_groups availability_groups ON availability_databases_cluster.group_id = availability_groups.group_id) as ag
			 on db.name = ag.database_name
		WHERE db.[name] <> 'tempdb' AND source_database_id IS NULL) as Src
		ON Dest.DBName = Src.DBName
		WHEN MATCHED THEN
			UPDATE SET
				Dest.Availgroupname = Src.Availgroupname,
				Dest.AvailGroupBackup = Src.AvailGroupBackup,
				Dest.Recoverymodel = Src.Recoverymodel,
				Dest.UpdateDate = getdate()
		WHEN NOT MATCHED By Target THEN
			INSERT (DBName, Databasetype,Availgroupname,Availgroupbackup,CreationDate,UpdateDate,Active,Recoverymodel,DefaultPath,MirrorPath,LogToTable,Compression,CleanupMode,CleanupTimeHours)
			Values
			 (Src.DBName,Src.DatabaseType,Src.Availgroupname,Src.Availgroupbackup,getdate(),getdate(),1,Src.Recoverymodel,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours)
		WHEN NOT MATCHED By Source THEN
			Update SET Active = 0
		;
		COMMIT TRAN
	END ELSE BEGIN
	-- SQL 2008
		BEGIN TRAN
		MERGE INTO LocalDatabases as Dest
		USING
		(SELECT db.[name] AS DBName, 		
		CASE WHEN db.name IN('master','msdb','model') THEN 'S' ELSE 'U' END AS DatabaseType, db.recovery_model as Recoverymodel, NULL as Availgroupname, 
		1 as AvailGroupBackup
		FROM sys.databases as db		
		WHERE db.[name] <> 'tempdb' AND source_database_id IS NULL) as Src
		ON Dest.DBName = Src.DBName
		WHEN MATCHED THEN
			UPDATE SET
				Dest.Availgroupname = Src.Availgroupname,
				Dest.AvailGroupBackup = Src.AvailGroupBackup,
				Dest.Recoverymodel = Src.Recoverymodel,
				Dest.UpdateDate = getdate()
		WHEN NOT MATCHED By Target THEN
			INSERT (DBName, Databasetype,Availgroupname,Availgroupbackup,CreationDate,UpdateDate,Active,Recoverymodel,DefaultPath,MirrorPath,LogToTable,Compression,CleanupMode,CleanupTimeHours)
			Values
			 (Src.DBName,Src.DatabaseType,Src.Availgroupname,Src.Availgroupbackup,getdate(),getdate(),1,Src.Recoverymodel,@DefaultPath,@MirrorPath,@LogToTable,@Compress,@CleanupMode,@CleanupTimeHours)
		WHEN NOT MATCHED By Source THEN
			Update SET Active = 0
		;
		COMMIT TRAN
	END

END
