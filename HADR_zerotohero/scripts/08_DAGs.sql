--on both
CREATE ENDPOINT endpoint_hadr
    STATE = STARTED  
    AS TCP ( LISTENER_PORT = 5022 )  
    FOR DATABASE_MIRRORING (ROLE = ALL);
GO  

--on secondary
alter availability group [scorpio_ag] join

alter availability group [scorpio_ag] grant create any database

--grant on endpoints

create login [solar1\Aquila_Lab06$] from windows

grant connect on endpoint::[endpoint_hadr] to [solar1\Aquila_Lab06$]

create login [solar1\Mercury_Lab05$] from windows

grant connect on endpoint::[endpoint_hadr] to [solar1\Mercury_Lab05$]

---------------------------------------------------------------------
--create the Primary and Secondary AGs
--create the distributed

create AVAILABILITY GROUP [DIST-SOLAR-AG] 
with (distributed)
AVAILABILITY GROUP ON 
      'moon_ag' WITH   
      (  
         LISTENER_URL = 'tcp://192.168.100.32:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      ),  
      'scorpio_ag' WITH   
      (  
         LISTENER_URL = 'tcp://192.168.130.31:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      );   
GO


alter AVAILABILITY GROUP [DIST-SOLAR-AG] 
join
AVAILABILITY GROUP ON 
      'moon_ag' WITH   
      (  
         LISTENER_URL = 'tcp://192.168.100.32:5022',   
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      ),  
      'scorpio_ag' WITH   
      (  
         LISTENER_URL = 'tcp://192.168.130.31:5022',  
         AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,  
         FAILOVER_MODE = MANUAL,  
         SEEDING_MODE = AUTOMATIC  
      );   
GO

--grants on endpoints to connect


create login [SOLAR1\EARTH_LAB02$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\EARTH_LAB02$]

GO
create login [SOLAR1\MARS_LAB01$] from windows
GO
grant connect on endpoint::[endpoint_hadr] to [SOLAR1\MARS_LAB01$]

--on primary
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


