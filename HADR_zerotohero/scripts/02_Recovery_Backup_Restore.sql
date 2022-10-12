--Backup and Restore
--Make sure the SQL2017 instance is up and running.
--Local path: c:\temp\sqlha
--preparing the environment:
USE [master]
RESTORE DATABASE [AdventureWorks] FROM  DISK = N'C:\Temp\sqlHA\adventure-works.bak' 
WITH  FILE = 1,  
MOVE N'AdventureWorks2008R2_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks2008r2.mdf',  
MOVE N'AdventureWorks2008R2_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks_log.LDF',  
NOUNLOAD,  STATS = 5,replace

GO
----------------------------------------------------------------------
--what is my recovery model?


select name,recovery_model_desc
from sys.databases

--let's change to FULL
alter database AdventureWorks set recovery FULL;

--what is my recovery model again?
select name,recovery_model_desc
from sys.databases

--how much space are my logs taking?
dbcc sqlperf(logspace);

--how are my VLfs
dbcc loginfo;

--wth is in my LOG?
SELECT
 [Current LSN],
 [Transaction ID],
 [Operation],
  [Transaction Name],
 [CONTEXT],
 [AllocUnitName],
 [Page ID],
 [Slot ID],
 [Begin Time],
 [End Time],
 [Number of Locks],
 [Lock Information]
FROM sys.fn_dblog(NULL,NULL)
WHERE Operation IN
   ('LOP_INSERT_ROWS','LOP_MODIFY_ROW',
    'LOP_DELETE_ROWS','LOP_BEGIN_XACT','LOP_COMMIT_XACT')

--let's test some data:
--create table
--drop table dbo.Pombo
create table dbo.Pombo
(id uniqueidentifier default (newid())
,firstname varchar(200)
,lastname varchar(200)
)
GO

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 1000

select * from dbo.Pombo;


--wth is in my LOG Now?
SELECT
 [Current LSN],
 [Transaction ID],
 [Operation],
  [Transaction Name],
 [CONTEXT],
 [AllocUnitName],
 [Page ID],
 [Slot ID],
 [Begin Time],
 [End Time],
 [Number of Locks],
 [Lock Information]
FROM sys.fn_dblog(NULL,NULL)
WHERE Operation IN
   ('LOP_INSERT_ROWS','LOP_MODIFY_ROW',
    'LOP_DELETE_ROWS','LOP_BEGIN_XACT','LOP_COMMIT_XACT')

--Again:
--how much space are my logs taking?
dbcc sqlperf(logspace);

--how are my VLfs
dbcc loginfo;

--can I truncate it?
select name,log_reuse_wait_desc
from sys.databases;

-------------------------------------------------------------------------------
--My DB is in FULL right?
select name,recovery_model_desc
from sys.databases

--So, issue a log backup:
backup log AdventureWorks to disk='c:\temp\sqlha\bkp\AdventureWorks_446.trn'

--This is the Fake FULL Recovery Mode
--Issue a FULL Backup, then a Log backup:
backup database AdventureWorks to disk='c:\temp\sqlha\bkp\AdventureWorks_0912.bak'

backup log AdventureWorks to disk='c:\temp\sqlha\bkp\AdventureWorks_0538.trn'

--OK, now we're at FULL Recovery Model!
--let's see the vlfs:
dbcc loginfo;
dbcc sqlperf(logspace)

--most are truncated, interesting!
--let's fill it up a bit
alter database AdventureWorks modify file (name=AdventureWorks2008R2_Log, filegrowth= 0MB)

--let's fill it up!

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 10000


--can I truncate it?
select name,log_reuse_wait_desc
from sys.databases;

--let's see the vlfs:
dbcc loginfo;

--the MOST correct way for truncating it:
backup log AdventureWorks to disk='c:\temp\sqlha\bkp\AdventureWorks_02.trn'

--can I truncate it?
select name,log_reuse_wait_desc
from sys.databases;

--let's see the vlfs:
dbcc loginfo;


--let's fill it up again!

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 10000

--the not so correct way for truncating it:
--you just lost recoverability 

backup log AdventureWorks to disk='nul'

--can I truncate it?
select name,log_reuse_wait_desc
from sys.databases;

--let's see the vlfs:
dbcc loginfo;

--let's fill it up again!

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 10000

--can I truncate it?
select name,log_reuse_wait_desc
from sys.databases;

--let's see the vlfs:
dbcc loginfo;

--the wrong (I'll cut your hand if I see you dong that) way for truncating it:

alter database Adventureworks set recovery simple;
go
alter database Adventureworks set recovery full;

--can I truncate it?
select name,log_reuse_wait_desc
from sys.databases;

--let's see the vlfs:
dbcc loginfo;

--you just lost recoverability.... again! 
--you also lost your last FULL Backup's use, congrats!
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

--let's test throtling the backup

--Now create the Large AdventureWorks:

----------------------------------------------------------------------------------------------
RESTORE DATABASE [AdventureWorksLarge] FROM  DISK = N'C:\Temp\sqlHA\adventure-works.bak' 
WITH  FILE = 1,  
MOVE N'AdventureWorks2008R2_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks2008r2large.mdf',  
MOVE N'AdventureWorks2008R2_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorkslarge_log.LDF',  
NOUNLOAD,  STATS = 5,REPLACE

GO

--run the create enlarged adventureworks tables.sql script
--this was created by Jonathan M. Kehayias, SQLskills.com
/*

USE AdventureWorksLarge
GO

IF OBJECT_ID('Sales.SalesOrderHeaderEnlarged') IS NOT NULL
	DROP TABLE Sales.SalesOrderHeaderEnlarged;
GO

CREATE TABLE Sales.SalesOrderHeaderEnlarged
	(
	SalesOrderID int NOT NULL IDENTITY (1, 1) NOT FOR REPLICATION,
	RevisionNumber tinyint NOT NULL,
	OrderDate datetime NOT NULL,
	DueDate datetime NOT NULL,
	ShipDate datetime NULL,
	Status tinyint NOT NULL,
	OnlineOrderFlag dbo.Flag NOT NULL,
	SalesOrderNumber  AS (isnull(N'SO'+CONVERT([nvarchar](23),[SalesOrderID],0),N'*** ERROR ***')),
	PurchaseOrderNumber dbo.OrderNumber NULL,
	AccountNumber dbo.AccountNumber NULL,
	CustomerID int NOT NULL,
	SalesPersonID int NULL,
	TerritoryID int NULL,
	BillToAddressID int NOT NULL,
	ShipToAddressID int NOT NULL,
	ShipMethodID int NOT NULL,
	CreditCardID int NULL,
	CreditCardApprovalCode varchar(15) NULL,
	CurrencyRateID int NULL,
	SubTotal money NOT NULL,
	TaxAmt money NOT NULL,
	Freight money NOT NULL,
	TotalDue  AS (isnull(([SubTotal]+[TaxAmt])+[Freight],(0))),
	Comment nvarchar(128) NULL,
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT Sales.SalesOrderHeaderEnlarged ON
GO
INSERT INTO Sales.SalesOrderHeaderEnlarged (SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate)
SELECT SalesOrderID, RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, rowguid, ModifiedDate 
FROM Sales.SalesOrderHeader WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT Sales.SalesOrderHeaderEnlarged OFF

GO
ALTER TABLE Sales.SalesOrderHeaderEnlarged ADD CONSTRAINT
	PK_SalesOrderHeaderEnlarged_SalesOrderID PRIMARY KEY CLUSTERED 
	(
	SalesOrderID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO

CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderEnlarged_rowguid ON Sales.SalesOrderHeaderEnlarged
	(
	rowguid
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderHeaderEnlarged_SalesOrderNumber ON Sales.SalesOrderHeaderEnlarged
	(
	SalesOrderNumber
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderEnlarged_CustomerID ON Sales.SalesOrderHeaderEnlarged
	(
	CustomerID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeaderEnlarged_SalesPersonID ON Sales.SalesOrderHeaderEnlarged
	(
	SalesPersonID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF OBJECT_ID('Sales.SalesOrderDetailEnlarged') IS NOT NULL
	DROP TABLE Sales.SalesOrderDetailEnlarged;
GO
CREATE TABLE Sales.SalesOrderDetailEnlarged
	(
	SalesOrderID int NOT NULL,
	SalesOrderDetailID int NOT NULL IDENTITY (1, 1),
	CarrierTrackingNumber nvarchar(25) NULL,
	OrderQty smallint NOT NULL,
	ProductID int NOT NULL,
	SpecialOfferID int NOT NULL,
	UnitPrice money NOT NULL,
	UnitPriceDiscount money NOT NULL,
	LineTotal  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	rowguid uniqueidentifier NOT NULL ROWGUIDCOL,
	ModifiedDate datetime NOT NULL
	)  ON [PRIMARY]
GO

SET IDENTITY_INSERT Sales.SalesOrderDetailEnlarged ON
GO
INSERT INTO Sales.SalesOrderDetailEnlarged (SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
SELECT SalesOrderID, SalesOrderDetailID, CarrierTrackingNumber, OrderQty, ProductID, SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate 
FROM Sales.SalesOrderDetail WITH (HOLDLOCK TABLOCKX)
GO
SET IDENTITY_INSERT Sales.SalesOrderDetailEnlarged OFF
GO
ALTER TABLE Sales.SalesOrderDetailEnlarged ADD CONSTRAINT
	PK_SalesOrderDetailEnlarged_SalesOrderID_SalesOrderDetailID PRIMARY KEY CLUSTERED 
	(
	SalesOrderID,
	SalesOrderDetailID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
CREATE UNIQUE NONCLUSTERED INDEX AK_SalesOrderDetailEnlarged_rowguid ON Sales.SalesOrderDetailEnlarged
	(
	rowguid
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_SalesOrderDetailEnlarged_ProductID ON Sales.SalesOrderDetailEnlarged
	(
	ProductID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


BEGIN TRANSACTION


DECLARE @TableVar TABLE
(OrigSalesOrderID int, NewSalesOrderID int)

INSERT INTO Sales.SalesOrderHeaderEnlarged 
	(RevisionNumber, OrderDate, DueDate, ShipDate, Status, OnlineOrderFlag, 
	 PurchaseOrderNumber, AccountNumber, CustomerID, SalesPersonID, TerritoryID, 
	 BillToAddressID, ShipToAddressID, ShipMethodID, CreditCardID, 
	 CreditCardApprovalCode, CurrencyRateID, SubTotal, TaxAmt, Freight, Comment, 
	 rowguid, ModifiedDate)
OUTPUT inserted.Comment, inserted.SalesOrderID
	INTO @TableVar
SELECT RevisionNumber, DATEADD(dd, number, OrderDate) AS OrderDate, 
	 DATEADD(dd, number, DueDate),  DATEADD(dd, number, ShipDate), 
	 Status, OnlineOrderFlag, 
	 PurchaseOrderNumber, 
	 AccountNumber, 
	 CustomerID, SalesPersonID, TerritoryID, BillToAddressID, 
	 ShipToAddressID, ShipMethodID, CreditCardID, CreditCardApprovalCode, 
	 CurrencyRateID, SubTotal, TaxAmt, Freight, SalesOrderID, 
	 NEWID(), DATEADD(dd, number, ModifiedDate)
FROM Sales.SalesOrderHeader AS soh WITH (HOLDLOCK TABLOCKX)
CROSS JOIN (
		SELECT number
		FROM (	SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
			UNION
				SELECT TOP 10 number
				FROM master.dbo.spt_values
				WHERE type = N'P'
				  AND number < 1000
				ORDER BY NEWID() DESC 
		  ) AS tab
) AS Randomizer
ORDER BY OrderDate, number

INSERT INTO Sales.SalesOrderDetailEnlarged 
	(SalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, 
	 SpecialOfferID, UnitPrice, UnitPriceDiscount, rowguid, ModifiedDate)
SELECT 
	tv.NewSalesOrderID, CarrierTrackingNumber, OrderQty, ProductID, 
	SpecialOfferID, UnitPrice, UnitPriceDiscount, NEWID(), ModifiedDate 
FROM Sales.SalesOrderDetail AS sod
JOIN @TableVar AS tv
	ON sod.SalesOrderID = tv.OrigSalesOrderID
ORDER BY sod.SalesOrderDetailID

COMMIT
*/
---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------
--no compress
Backup database AdventureWorksLarge to disk='C:\Temp\sqlHA\bkp\AdventureWorksLarge.bak'
with stats=5
--rough 12 secs

--compress
Backup database AdventureWorksLarge to disk='C:\Temp\sqlHA\bkp\AdventureWorksLarge_compress.bak'
with stats=5,compression
--6 secs

--force more buffers
Backup database AdventureWorksLarge to disk='C:\Temp\sqlHA\bkp\AdventureWorksLarge_compress_quick.bak'
with stats=5,maxtransfersize=4194304,blocksize=65536,buffercount=20,format

--force more buffers nocompress
Backup database AdventureWorksLarge to disk='C:\Temp\sqlHA\bkp\AdventureWorksLarge_compress_quick.bak'
with stats=5,maxtransfersize=4194304,blocksize=65536,buffercount=2,format
--better eh?

---------------------------------------------------------------------------------------------
--simple restore to a different DB
Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks.bak'
with stats=5,compression;

restore database AdventureWorks2 from disk='C:\Temp\sqlHA\bkp\AdventureWorks.bak'
with stats=5;
--why the failure?
--modify the placement of the files!
--check the contents:
restore headeronly from disk='C:\Temp\sqlHA\bkp\AdventureWorks.bak';

--check the files in it:
restore filelistonly from disk='C:\Temp\sqlHA\bkp\AdventureWorks.bak';

/*
RESTORE DATABASE [AdventureWorksCopy] FROM DISK = 'c:\mssql\backup\yukon\AW2K5_Full.bak'
WITH CHECKSUM,
MOVE 'AdventureWorks_Data' TO 'c:\mssql\data\yukon\AdventureWorksCopy_Data.mdf',
MOVE 'AdventureWorks_Log' TO 'c:\mssql\log\yukon\AdventureWorksCopy_Log.ldf',
RECOVERY, REPLACE, STATS = 10;
*/

RESTORE DATABASE [AdventureWorks2] FROM DISK = 'C:\Temp\sqlHA\bkp\AdventureWorks.bak' with
MOVE 'AdventureWorks2008R2_Data' TO 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks2008r2_2.mdf',
MOVE 'AdventureWorks2008R2_Log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks_log_2.LDF',
RECOVERY, REPLACE, STATS = 10;

--simple restore to the same DB
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks.bak'
with stats=5,replace;
--why failure? 
--check sessions:
select * from sys.dm_exec_sessions where db_name(database_id)='AdventureWorks'
--kill it!
kill 76

--try again!
use master
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace;
-------------------------------------------------------------------------------------
--restore with differential

Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,compression,format;

--add some data:
use AdventureWorks;
GO
--create table
--drop table dbo.pombo;
create table dbo.Pombo
(id uniqueidentifier default (newid())
,firstname varchar(200)
,lastname varchar(200)
)
GO

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 1000

select * from dbo.Pombo;

--backup differential:
Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
with stats=5,compression,differential;

--restore and check data:
use master
GO
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace;

--check data:
use AdventureWorks
GO
select * from dbo.Pombo;

--now the right way:
use master
GO
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace,norecovery;

restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
with stats=5,replace,recovery;

use AdventureWorks
GO
select * from dbo.Pombo;

--restore with LOG files
--drop table dbo.pombo;
alter database AdventureWorks set recovery FULL;
GO
Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,compression;

use AdventureWorks
GO
--create table
--drop table dbo.pombo;
create table dbo.Pombo
(id uniqueidentifier default (newid())
,firstname varchar(200)
,lastname varchar(200)
)
GO

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 1000

select * from dbo.Pombo;

--Backup differential:
Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
with stats=5,compression,differential;

--Add more data:
insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 2000

select * from dbo.Pombo;

--backup the log:
Backup log AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_1.trn'
with stats=5,compression;


--restore with DIFF and LOG:
use master
GO
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace,norecovery;

restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
with stats=5,replace,norecovery;

restore log AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_1.trn'
with stats=5,replace,recovery;

use AdventureWorks
GO
select * from dbo.Pombo;

--restore with only the LOG:
use master
GO
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace,norecovery;

restore log AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_1.trn'
with stats=5,replace,recovery;

use AdventureWorks
GO
select * from dbo.Pombo;

--The F?
--Why we have the same number of rows?
---------------------------------------------------------------------------------------------------
--salvaging a destroyed database, but we still have the LDF
--add more data:
Use AdventureWorks
GO
insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')
GO 200

select * from dbo.Pombo;

--kill the instance!
--shutdown with nowait
--remove the MDF manually
--C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA
--startup the instance
--
use master
GO
dbcc checkdb(AdventureWorks) with no_infomsgs
GO
sp_readerrorlog
GO

Backup log AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_2.trn'
with stats=5,compression,continue_after_error;

--recover that thing!
use master
GO
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace,norecovery;

restore log AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_1.trn'
with stats=5,replace,norecovery;


restore log AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_2.trn'
with stats=5,replace,recovery;

--check the data
Use AdventureWorks
GO
select * from dbo.Pombo;

--Check the data as we restore it:

use master
GO
restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace,standby='C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWStand.std';

Use AdventureWorks
GO
select * from dbo.Pombo;

use master
GO
restore log AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_1.trn'
with stats=5,replace,standby='C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWStand.std';

Use AdventureWorks
GO
select * from dbo.Pombo;

use master
GO
restore log AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_log_2.trn'
with stats=5,replace,standby='C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWStand.std';

Use AdventureWorks
GO
select * from dbo.Pombo;

use master
GO
restore database AdventureWorks with Recovery;

--The Copy_only backup
--stat over:
USE [master]
RESTORE DATABASE [AdventureWorks] FROM  DISK = N'C:\Temp\sqlHA\adventure-works.bak' 
WITH  FILE = 1,  
MOVE N'AdventureWorks2008R2_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks2008r2.mdf',  
MOVE N'AdventureWorks2008R2_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL14.SQL2017\MSSQL\DATA\AdventureWorks_log.LDF',  
NOUNLOAD,  STATS = 5,replace

alter database AdventureWorks set recovery FULL;
alter database AdventureWorks set recovery Simple;
alter database AdventureWorks set recovery FULL;

--backup full with COPY_ONLY:
Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,compression,copy_only;

--diff backup:
Backup database AdventureWorks to disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
with stats=5,compression,differential;

restore headeronly from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
restore headeronly from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'



restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
with stats=5,replace,norecovery;

restore database AdventureWorks from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
with stats=5,replace,recovery;
--why?

--check again:
restore headeronly from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1_diff.bak'
restore headeronly from disk='C:\Temp\sqlHA\bkp\AdventureWorks_1.bak'
restore headeronly from disk='C:\Temp\sqlHA\adventure-works.bak' 


--ADDR (go to SQL2019)

