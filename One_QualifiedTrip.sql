/*This code is from https://github.com/zhao-lab/mo-extract-encounters-avec18*/
/*This code sorts the qualified trip from the raw data. The latitude and longitude of the vehicle are set to a box */
/*boundary, and those trips with data lost are also eliminated */

IF OBJECT_ID('SP_Ding.dbo.QualifiedTrip', 'U') IS NOT NULL 
  DROP TABLE SP_Ding.dbo.QualifiedTrip



SELECT  ROW_NUMBER() over(order by min(D.GpsTimeWsu) ,max(D.GpsTimeWsu)) as ID 
		,D.Device					-- id of the driver/vehicle

		,D.Trip						-- id of the trip
								-- trip is start from ignition to the stall

		,(max(Time) - min(Time))/10 + 1 as dTime_X10	-- number of the timestep

		,count(Time) as Num_Row				-- number of the row

		,min(Time) as StartTime				-- the time when the trip starts

		,min(D.GpsTimeWsu) as GpsStartTime		-- the gpstime when the trip starts
								-- gps time is the absolute time

		,max(D.GpsTimeWsu) as GpsEndTime		-- the gpstime when the trip ends

		,min(LatitudeWsu) as La_MIN			-- the bottom boundary

		,max(LatitudeWsu) as La_MAX			-- the up boundary

		,min(LongitudeWsu) as Lo_MIN			-- the left boundary

		,max(LongitudeWsu) as Lo_MAX			-- the right boundary

		,max(GpsSpeedWsu) as V_MAX			-- the maxium velocity during the trip

  into  SP_Ding.dbo.QualifiedTrip
  FROM [SpFot].[dbo].[DataWsu] as D, SpFot.dbo.Summary as S
  Where S.Device = D.Device and S.Trip = D.Trip 
  group by D.Device, D.Trip
  Having count(Time) = (max(Time) - min(Time))/10 + 1   --No Time Miss
     and count(Time) > 10  -- The duration is more than 1 second
	 and min(D.LatitudeWsu) > 41.65 and max(D.LatitudeWsu)<44.5
	 and min(D.LongitudeWsu) > -86 and max(D.LongitudeWsu)<-82.37
  order by GpsStartTime,GpsEndTime


ALTER TABLE SP_Ding.dbo.QualifiedTrip ALTER COLUMN [ID] INTEGER NOT NULL
select top 1000 * from SP_Ding.dbo.QualifiedTrip
  

