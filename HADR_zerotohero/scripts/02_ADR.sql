

--CREATE DATABASE OldReco;
--GO
--CREATE DATABASE NewReco;
--ALTER  DATABASE NewReco SET ACCELERATED_DATABASE_RECOVERY = ON;
--GO
----testing ADR

--session 1:
USE OldReco;
GO
DROP TABLE IF EXISTS dbo.fl1, dbo.fl2, dbo.fl3, dbo.fl4, dbo.fl5, dbo.fl6, dbo.fl7;
SELECT s2.* INTO dbo.fl1 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl2 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl3 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl4 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl5 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl6 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl7 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;

/*
--session 2:
USE NewReco;
GO
DROP TABLE IF EXISTS dbo.fl1, dbo.fl2, dbo.fl3, dbo.fl4, dbo.fl5, dbo.fl6, dbo.fl7;
SELECT s2.* INTO dbo.fl1 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl2 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl3 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl4 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl5 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl6 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;
SELECT s2.* INTO dbo.fl7 FROM sys.all_columns AS s1 CROSS JOIN sys.all_objects AS s2;

--kill in another session

--WAITFOR DELAY '00:02:30';
SHUTDOWN WITH NOWAIT;
*/