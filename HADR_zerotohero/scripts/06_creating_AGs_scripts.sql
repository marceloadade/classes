--Some AG creation 
CREATE ENDPOINT endpoint_hadr
    STATE = STARTED  
    AS TCP ( LISTENER_PORT = 5022 )  
    FOR DATABASE_MIRRORING (ROLE = ALL);
GO  

sp_readerrorlog

Database Mirroring login attempt by user 'SOLAR1\EARTH_LAB02$.' failed with error: 'Connection handshake failed. The login 'SOLAR1\EARTH_LAB02$' 
does not have CONNECT permission on the endpoint. State 84.'.  [CLIENT: 192.168.100.12]


create login [SOLAR1\EARTH_LAB02$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\EARTH_LAB02$]

--drop AVAILABILITY GROUP [Summit_AG_2019]
CREATE AVAILABILITY GROUP [Summit_AG_2019]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
DB_FAILOVER = ON,
DTC_SUPPORT = NONE,
REQUIRED_SYNCHRONIZED_SECONDARIES_TO_COMMIT = 0)
FOR 
REPLICA ON N'Mercury_Lab05\LAB2022' WITH (ENDPOINT_URL = N'TCP://Mercury_Lab05.solar1.com:5044', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, SESSION_TIMEOUT = 10, BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL), SECONDARY_ROLE(ALLOW_CONNECTIONS = YES)),
	N'Aquila_Lab06\LAB2022' WITH (ENDPOINT_URL = N'TCP://Aquila_Lab06.solar1.com:5044', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, SESSION_TIMEOUT = 10, BACKUP_PRIORITY = 50, SEEDING_MODE = AUTOMATIC, PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL), SECONDARY_ROLE(ALLOW_CONNECTIONS = YES));
GO
  

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


backup database andromeda to disk='nul'


CREATE ENDPOINT endpoint_hadr
    STATE = STARTED  
    AS TCP ( LISTENER_PORT = 5022 )  
    FOR DATABASE_MIRRORING (ROLE = ALL);
GO  


alter availability group [ag_pluto] join;

alter availability group [ag_pluto] grant create any database;


create login [SOLAR1\EARTH_LAB02$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\EARTH_LAB02$]

GO
create login [SOLAR1\MARS_LAB01$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\MARS_LAB01$]


select * from dbo.Pombo;

CREATE ENDPOINT endpoint_hadr
    STATE = STARTED  
    AS TCP ( LISTENER_PORT = 5022 )  
    FOR DATABASE_MIRRORING (ROLE = ALL);
GO  

alter availability group [ag_pluto] join;

alter availability group [ag_pluto] grant create any database;


create login [SOLAR1\EARTH_LAB02$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\EARTH_LAB02$]

GO
create login [SOLAR1\MARS_LAB01$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\MARS_LAB01$]

GO
create login [SOLAR1\MARS_LAB01$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\MARS_LAB01$]


select * from dbo.Pombo;

insert into dbo.Pombo (firstname,lastname)values('Pombo','FicticiousName')



