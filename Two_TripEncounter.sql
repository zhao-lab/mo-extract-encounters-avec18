/*This code is from https://github.com/zhao-lab/mo-extract-encounters-avec18*/
/*This code is to find the trip encounter, in which two vehicles share spatial and temperal intersection*/


SET NOCOUNT ON;
Declare @@Gap int = 1
DECLARE @msg VARCHAR(50) 
IF OBJECT_ID('SP_Ding.dbo.Temp_Plus', 'U') IS NOT NULL Drop table SP_Ding.dbo.Temp_Plus


/******** This code run by a while loop. It is the same as is shown in the paper, yet more efficient*********/


/*ID-@@Gamp where gap = 1, generating a new table that is lagging a row. The purse is to compare two neghbor 
*/
Select   ID-@@Gap as ID_Plus
		,GpsStartTime
		,GpsEndTime
		Into SP_Ding.dbo.Temp_Plus
		from SP_Ding.dbo.QualifiedTrip 
		where ID-@@Gap>0
		order by ID_Plus

Alter table SP_Ding.dbo.Temp_Plus
Alter column ID_Plus integer Not null
Alter table SP_Ding.dbo.Temp_Plus
Add constraint PK_Plus Primary Key Clustered (ID_Plus)

IF OBJECT_ID('SP_Ding.dbo.ID_WithGap', 'U') IS NOT NULL Drop table SP_Ding.dbo.ID_WithGap
select T1.ID  --T1 is the Qulifiedtrip, the original one, to make sure the ID is original
into SP_Ding.dbo.ID_WithGap  --ID that have tripECT in Gap distance
from SP_Ding.dbo.QualifiedTrip  as T1,  SP_Ding.dbo.Temp_Plus as T2
where T1.ID = T2.ID_Plus and T1.GpsEndTime>T2.GpsStartTime



IF OBJECT_ID('SP_Ding.dbo.Trip_ECT_ASSEMBLE', 'U') IS NOT NULL Drop table SP_Ding.dbo.Trip_ECT_ASSEMBLE
select
      S1.Device as Device_1
	,S1.Trip as Trip_1
	,S2.Device as Device_2
	,S2.Trip as Trip_2
	,case When S1.[GpsStartTime]-S2.[GpsEndTime]>0 then S1.[GpsStartTime] else S2.[GpsStartTime] end as CommonStartTime
	,case When S1.[GpsEndTime]-S2.[GpsEndTime]<0 then S1.[GpsEndTime] else S2.[GpsEndTime] end as CommonEndTime 
	,S1.StartTime as StartTime_1
	,S2.StartTime as StartTime_2
	,S1.[GpsStartTime] as ST_1
	,S1.GpsEndTime as ED_1
	,S2.GpsStartTime as ST_2
	,S2.GpsEndTime as ED_2
	,S1.V_MAX as V_MAX_1
	,S2.V_MAX as V_MAX_2
	into SP_Ding.dbo.Trip_ECT_ASSEMBLE
	from SP_Ding.dbo.ID_WithGap as T1, SP_Ding.dbo.QualifiedTrip as S1,SP_Ding.dbo.QualifiedTrip as S2
	where S1.ID = T1.ID and T1.ID+@@Gap = S2.ID 




Declare @NewNum int
Set @NewNum = (select count(1) from SP_Ding.dbo.ID_WithGap)

While @NewNum > 0 
Begin
   set @Gap = @Gap + 1
   
   set @msg = CAST(@Gap AS VARCHAR) + ' + ' + CAST(@NewNum AS VARCHAR);
			   RAISERROR (@msg, 10, 0 ) with NOWAIT

  IF OBJECT_ID('SP_Ding.dbo.Temp_Plus', 'U') IS NOT NULL Drop table SP_Ding.dbo.Temp_Plus


  Select  ID-@Gap as ID_Plus
		,GpsStartTime
		,GpsEndTime
	 into SP_Ding.dbo.Temp_Plus
		from SP_Ding.dbo.QualifiedTrip 
		where ID>@Gap and ID in (select * from SP_Ding.dbo.ID_WithGap )
		order by ID

Alter table SP_Ding.dbo.Temp_Plus
Alter column ID_Plus integer Not null
Alter table SP_Ding.dbo.Temp_Plus
Add constraint PK_Plus Primary Key Clustered (ID_Plus)
 
 
IF OBJECT_ID('SP_Ding.dbo.ID_WithGap', 'U') IS NOT NULL Drop table SP_Ding.dbo.ID_WithGap
select T1.ID  --T1 is the Qulifiedtrip, the original one, to make sure the ID is original
into SP_Ding.dbo.ID_WithGap  --ID that have tripECT in Gap distance
from SP_Ding.dbo.QualifiedTrip  as T1,  SP_Ding.dbo.Temp_Plus as T2
where T1.ID = T2.ID_Plus and T1.GpsEndTime>T2.GpsStartTime


Insert into SP_Ding.dbo.Trip_ECT_ASSEMBLE
select
     S1.Device as Device_1
	,S1.Trip as Trip_1
	,S2.Device as Device_2
	,S2.Trip as Trip_2
	,case When S1.[GpsStartTime]-S2.[GpsEndTime]>0 then S1.[GpsStartTime] else S2.[GpsStartTime] end as CommonStartTime
	,case When S1.[GpsEndTime]-S2.[GpsEndTime]<0 then S1.[GpsEndTime] else S2.[GpsEndTime] end as CommonEndTime 
	,S1.StartTime as StartTime_1
	,S2.StartTime as StartTime_2
	,S1.[GpsStartTime] as ST_1
	,S1.GpsEndTime as ED_1
	,S2.GpsStartTime as ST_2
	,S2.GpsEndTime as ED_2
	,S1.V_MAX as V_MAX_1
	,S2.V_MAX as V_MAX_2

	from SP_Ding.dbo.ID_WithGap as T1, SP_Ding.dbo.QualifiedTrip as S1,SP_Ding.dbo.QualifiedTrip as S2
	where S1.ID = T1.ID and S2.ID = cast((T1.ID + @Gap) as int)



Set @NewNum = (select count(1) from SP_Ding.dbo.ID_WithGap )
End

GO

Drop table SP_Ding.dbo.Temp_Plus
Drop table SP_Ding.dbo.ID_WithGap

IF OBJECT_ID('SP_Ding.dbo.TripEncounter_Pre', 'U') IS NOT NULL 
  DROP TABLE SP_Ding.dbo.TripEncounter_Pre
  Select 
       T.[Device_1]
      ,T.[Trip_1]
      ,T.[Device_2]
      ,T.[Trip_2]
      ,T.[CommonStartTime]
      ,T.[CommonEndTime]
	  ,T.StartTime_1
	  ,T.StartTime_2
      ,ceiling((T.[CommonStartTime] - T.[ST_1])/100) as D_SS_1
	  ,ceiling((T.[CommonStartTime] - T.[ST_2])/100) as D_SS_2
	  ,ceiling((T.[CommonEndTime] - T.[CommonStartTime])/100) as D_CommonSE
      ,T.[V_MAX_1]
      ,T.[V_MAX_2]
  into SP_Ding.dbo.TripEncounter_Pre 
  from SP_Ding.dbo.Trip_ECT_ASSEMBLE as T
  
  order by Device_1,Trip_1,Device_2,Trip_2


  IF OBJECT_ID('SP_Ding.dbo.TripEncounter', 'U') IS NOT NULL 
  DROP TABLE SP_Ding.dbo.TripEncounter
  select Device_1
		,Trip_1
		,Device_2
		,Trip_2
		,StartTime_1+D_SS_1*10 as StartTime_1
		,StartTime_1+(D_SS_1+D_CommonSE)*10 as EndTime_1
		,StartTime_2+D_SS_2*10 as StartTime_2
		,StartTime_2+(D_SS_2+D_CommonSE)*10 as EndTime_2
		,ceiling(900/(V_MAX_1+V_MAX_2)) as TimeIntv
		into SP_Ding.dbo.TripEncounter
		from SP_Ding.dbo.TripEncounter_Pre

   Drop TABLE SP_Ding.dbo.Trip_ECT_ASSEMBLE
   DROP TABLE SP_Ding.dbo.TripEncounter_Pre
   select top 1000 * from SP_Ding.dbo.TripEncounter
  