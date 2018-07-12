
/* ------------------------------------------------------ CreateTables for Backupsolution  ----------------------------------------------- */
IF OBJECT_ID('BackupSettings', 'U') IS NOT NULL 
  DROP TABLE dbo.BackupSettings; 
GO

CREATE TABLE [dbo].[BackupSettings](
	[Setting] [varchar](256) NOT NULL,
	[Value] [varchar](256) NULL,
 CONSTRAINT [PK_BackupSettings] PRIMARY KEY CLUSTERED 
(
	[Setting] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO BackupSettings ( [Setting], [Value] ) VALUES
('ChangeBackupType', 'Y'), 
('CleanupMode', 'After_Backup'),
('CleanupTimeHours' , '840'),
('Compression','Y'),
('DefaultPath','\\FSQL-Bkp.isiflo.wstw.energy-it.net\FSQL_Bkp\SQL'),
('LogToTable','Y'),
('MirrorPath','\\RSQL-Bkp.isiresi.wstw.energy-it.net\RSQL_Bkp\SQL')

IF OBJECT_ID('LocalDatabases', 'U') IS NOT NULL 
  DROP TABLE dbo.LocalDatabases; 

CREATE TABLE [dbo].[LocalDatabases](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DBName] [varchar](265) NULL,
	[FullbackupDay] [varchar](10) NULL,
	[FullbackupStarttime] [datetime] NULL,
	[LogbackupInterval] [int] NULL,
	[LastbackupFull] [datetime] NULL,
	[LastbackupDiff] [datetime] NULL,
	[LastbackupLog] [datetime] NULL,
	[Recoverymodel] [tinyint] NULL,
	[Databasetype] [varchar](1) NULL,
	[DoBackup] [bit] NULL,
	[AvailgroupName] [varchar](256) NULL,
	[AvailgroupBackup] [bit] NULL,
	[CreationDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL,
	[Active] [bit] NULL,
	[DefaultPath] [varchar](255) NULL,
	[MirrorPath] [varchar](255) NULL,
	[LogToTable] [char](1) NULL,
	[Compression] [char](1) NULL,
	[CleanupMode] [varchar](25) NULL,
	[CleanupTimeHours] [int] NULL,
 CONSTRAINT [PK_Databases] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


ALTER TABLE [dbo].[LocalDatabases] ADD  CONSTRAINT [DF_Table_1_FullBackup]  DEFAULT ('Saturday') FOR [FullbackupDay]


ALTER TABLE [dbo].[LocalDatabases] ADD  CONSTRAINT [DF_Databases_FullbackupStarttime]  DEFAULT ('19:00:00') FOR [FullbackupStarttime]


ALTER TABLE [dbo].[LocalDatabases] ADD  CONSTRAINT [DF_Databases_LogbackupInterval]  DEFAULT ((4)) FOR [LogbackupInterval]


ALTER TABLE [dbo].[LocalDatabases] ADD  CONSTRAINT [DF_Databases_DoBackup]  DEFAULT ((1)) FOR [DoBackup]


ALTER TABLE [dbo].[LocalDatabases] ADD  CONSTRAINT [DF_LocalDatabases_Active]  DEFAULT ((1)) FOR [Active]
	
/*    --------------------------------------------------- Create Trigger  -----------------------------------------------       */
GO

IF object_id('_WIT_ResetBackupIfAGChanged') IS NULL
    EXEC ('CREATE TRIGGER [dbo].[_WIT_ResetBackupIfAGChanged] ON LocalDatabases AFTER UPDATE AS BEGIN select 1 END')
GO

ALTER TRIGGER [dbo].[_WIT_ResetBackupIfAGChanged]
   ON  [dbo].[LocalDatabases] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF UPDATE (Availgroupname) 
    BEGIN
        UPDATE LocalDatabases 
        SET LastbackupFull = Null,
           LastbackupDiff = Null,
		   LastbackupLog = Null
        FROM LocalDatabases S 
		INNER JOIN Inserted I ON S.DBName = I.DBName
		INNER JOIN Deleted D ON S.DBName = D.DBName                 
		WHERE ISNULL(D.Availgroupname,'') <> ISNULL(I.Availgroupname,'') 
		
    END 
END
GO

IF object_id('_WIT_ResetBackupIfRecoveryModelChanged') IS NULL
    EXEC ('CREATE TRIGGER [dbo].[_WIT_ResetBackupIfRecoveryModelChanged] ON LocalDatabases AFTER UPDATE AS BEGIN select 1 END')

GO

ALTER TRIGGER [dbo].[_WIT_ResetBackupIfRecoveryModelChanged]
   ON  [dbo].[LocalDatabases] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF UPDATE (RecoveryModel) 
    BEGIN
        UPDATE LocalDatabases 
        SET LastbackupFull = Null,
           LastbackupDiff = Null,
		   LastbackupLog = Null
        FROM LocalDatabases S 
		INNER JOIN Inserted I ON S.DBName = I.DBName
		INNER JOIN Deleted D ON S.DBName = D.DBName                 
		WHERE ISNULL(D.RecoveryModel,'') <> ISNULL(I.RecoveryModel,'') 
		
    END 
END
