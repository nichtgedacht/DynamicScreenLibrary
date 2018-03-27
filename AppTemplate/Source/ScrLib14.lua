--[[
	---------------------------------------------------------
	Geierwallys dynamic telemetry screen library for DC/DS 24 transmitters
	Makes flexible display adjustments possible. Users can create her own screenfiles
	2 telemetry pages adjustable by user over data files provided.
	---------------------------------------------------------
	V1.1.1 Initial state prepares all functionalities of the app template except telemetry 
	       Telemetry is simulated for first function tests
	---------------------------------------------------------
--]]
--Configuration
-- Local variables
local globVar = {} --global variables for application and screen library
local aTimeRunning = 0 --alert delay is running
local aDelay = 0  --voltage alert delay
local aPrepare = false -- alert in preparation
local mainWin_Lib = nil  -- main window
local lib_Path = nil     -- path to last loaded main win library
local drawWin_Lib = nil  -- draw telemetry handler
local drawWin_Path = nil -- path to draw telemetry handler
local chkLim_Lib = nil	 -- limit and timer handler
local chkLim_Path = nil  -- path to limit and timer handler
local prevCountDownTime = 100 -- for count down timer
local allertSet = false 
local timExpired = false
local prevInputVal = 0
local drWin = 2			-- screen page number 2 or 3 
local prevFailWindow = 0 -- last failed screen page number
local drawWin = true    -- toggle draw window and handle timers and limits for reducing storage


-------------------------------------------------------------------- 
-- storage manager
-------------------------------------------------------------------- 

local function unloadMainWin()
	system.unregisterTelemetry(1)
	if(mainWin_Lib ~= nil)then
		package.loaded[lib_Path]=nil
		_G[lib_Path]=nil
		mainWin_Lib = nil
		lib_Path = nil
		collectgarbage('collect')
	end	
	if(chkLim_Lib ~= nil)then
		package.loaded[chkLim_Path]=nil
		_G[chkLim_Path]=nil
		chkLim_Lib = nil
		chkLim_Path = nil
		collectgarbage('collect')
	end	
	if(drawWin_Lib ~= nil)then
		package.loaded[drawWin_Path]=nil
		_G[drawWin_Path]=nil
		drawWin_Lib = nil
		drawWin_Path = nil
		collectgarbage('collect')
	end	
											globVar.debugmem = math.modf(collectgarbage('count'))
	print("scrLibEmpty_1: "..globVar.debugmem.."K")	

end

local function toggleHandler()
	if(drawWin == false)then
		drawWin = true
		if(chkLim_Lib ~= nil)then
			package.loaded[chkLim_Path]=nil
			_G[chkLim_Path]=nil
			chkLim_Lib = nil
			chkLim_Path = nil
			collectgarbage('collect')
		end	
		drawWin_Path = "AppTempl/Tasks/drawWn14"
		drawWin_Lib = require(drawWin_Path)
		local func = drawWin_Lib[1]  --init() 
		func(globVar) -- execute specific initializer 
	else
		drawWin = false
		if(drawWin_Lib ~= nil)then
			package.loaded[drawWin_Path]=nil
			_G[drawWin_Path]=nil
			drawWin_Lib = nil
			drawWin_Path = nil
			collectgarbage('collect')
		end	
		chkLim_Path = "AppTempl/Tasks/chkLim14"
		chkLim_Lib = require(chkLim_Path)
		local func = chkLim_Lib[1]  --init() 
		func(globVar) -- execute specific initializer 
	end
end
-------------------------------------------------------------------- 
-- Init function
-------------------------------------------------------------------- 


local function loadmainWindow()
	if(mainWin_Lib ~= nil)then
		package.loaded[lib_Path]=nil
		_G[lib_Path]=nil
		mainWin_Lib = nil
		lib_Path = nil
		collectgarbage('collect')
	end	
	if(globVar.windows[1][1][1]==1) then -- electro
		lib_Path = "AppTempl/Tasks/winEl"..globVar.screenLib24..""
	elseif((globVar.windows[1][1][1]==2)or(globVar.windows[1][1][1]==3)) then -- stroke or turbine
		lib_Path = "AppTempl/Tasks/winNit"..globVar.screenLib24..""
	elseif(globVar.windows[1][1][1]==3) then -- glider
	end
	mainWin_Lib = require(lib_Path)
	if(mainWin_Lib~=nil)then
		local func = mainWin_Lib[1]  --init() 
		func(globVar) -- execute init of main window
	end
end

local function setTx_Tim(j,i)
	if((globVar.windows[j][i][4]>30) and (globVar.windows[j][i][4]<35))then
		local timerID = globVar.windows[j][i][4]-30
		globVar.windows[j][i][10]= system.pLoad("timer"..timerID.."",-1) -- preset timer value of window
		if(globVar.windows[j][i][10]==-1)then -- reset timer if value was not stored
			local preStart = {0,globVar.windows[j][i][5] * 60000,0,globVar.windows[j][i][5] * 1000} -- for preset start values
			if(globVar.windows[j][i][7] ==0)then -- is timer switched off
				globVar.windows[j][i][10] = preStart[globVar.windows[j][i][3]] --preset start value in ms
				system.pSave("timer"..timerID.."",globVar.windows[j][i][10]) -- save timer value on reset
			end	
		end
	end
end

local function init(globVar_)
	globVar = globVar_
	loadmainWindow()
	globVar.txtColor = {0,0,0} --set black color
	for i in ipairs(globVar.windows[2]) do
		setTx_Tim(2,i) -- preset Timerindex of window
	end	
	if(#globVar.windows == 3) then
		for i in ipairs(globVar.windows[3]) do
			setTx_Tim(3,i)-- preset Timerindex of window
		end	
	end
	local  i = 1
	while i<5 do
		globVar.switches[1][i] = system.pLoad("timStart"..i.."",nil)
		globVar.switches[2][i] = system.pLoad("timStopp"..i.."",nil)
		globVar.switches[3][i] = system.pLoad("timReset"..i.."",nil)
		globVar.timLimits[i] = system.pLoad("timLimit"..i.."",0)
		i=i+1
	end
	globVar.initDone = true
end



local function printTelemetry() 
	lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
	local inputVal = system.getInputsVal(globVar.ScrSwitch)
	if(inputVal ~= prevInputVal)then
		prevInputVal = inputVal
		if(inputVal == 1)then
			drWin = 3
		else
			drWin = 2
		end
	end	
	if(globVar.failWindow ~= prevFailWindow)then
		prevFailWindow = globVar.failWindow
		if(globVar.failWindow ~=0)then
			drWin = globVar.failWindow
		end	
	end
	if(drawWin == true)then
		local func = drawWin_Lib[2] -- drawWindow(drWin) 
		func(drWin) 
		if(mainWin_Lib~=nil)then
			func = nil
			func = mainWin_Lib[2]  --draw main window 
			func() 
		end
	end	
end		
	

-------------------------------------------------------------------------------
-- Configure turbine status lookup
local function getECUStatus(value)
	local file = io.readall("Apps/AppTempl/model/ECU_Data/"..globVar.ECUType..".jsn") -- hardcoded for now
	local status = nil
	local obj  = json.decode(file)
	if(obj) then
		status = obj[""..math.modf(value)..""]
	end
	return(status)
end

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop()
	if(globVar.initDone == true) then
		system.registerTelemetry(1," "..globVar.model.." Scr1",4,printTelemetry)
		toggleHandler()
		allertSet = false
		timExpired = false
		aPrepare = false
		local sensor = {}
		local sensID = nil
		local sensPar = nil
		for j in ipairs(globVar.windows)do
			for i in ipairs(globVar.windows[j]) do --check limits of main window
				if(globVar.windows[j][i][1]==2)then -- reset screen min max values
					globVar.windows[j][i][13]=0 
					globVar.windows[j][i][14]=0
				end					
				sensID = globVar.windows[j][i][10]
				sensPar = globVar.windows[j][i][11] 
				if(globVar.windows[j][i][4]>0) then 
				
					if(globVar.windows[j][i][4]==30)then -- value is GPS Coordinate
						globVar.windows[j][i][8] = 0 -- reset screen value
						sensor = {}
							if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
							sensor = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])
							if(sensor and sensor.valid and sensor.type ==9) then
								local nesw = {"N", "E", "S", "W"}
								globVar.windows[j][i][3] = nil
								globVar.windows[j][i][14] = nil
								globVar.windows[j][i][3] = nesw[sensor.decimals+1]
								globVar.windows[j][i][8] = sensor.valGPS --set sensor GPSvalue
								local minutes = (sensor.valGPS & 0xFFFF) * 0.001
								local degs = (sensor.valGPS >> 16) & 0xFF
								globVar.windows[j][i][14] = string.format("%s %d° %f'", sensor.label,degs,minutes)
							end
						end
					elseif((globVar.windows[j][i][4]>30)and(globVar.windows[j][i][4]<35))then -- value is one of the timers
						if(drawWin == false)then
							local func = chkLim_Lib[2] -- handleTimers(j,i)
							func(j,i) 
						end	
					elseif(globVar.windows[j][i][4]==35)then --reserved for turbine status	
						if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
							sensor = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])
							if(sensor)then
								if(sensor.value <0)then
									globVar.windows[j][i][9] = 1 --set turbine alert
								else
									globVar.windows[j][i][9] = 0 --reset turbine alert
								end
								globVar.windows[j][i][8] = nil
								globVar.windows[j][i][8] = getECUStatus(sensor.value)

							end	
						end	
					else 					-- value from application
						globVar.windows[j][i][8] = globVar.appValues[globVar.windows[j][i][4]] --set app value 
					end	
				else				-- value from telemetry sensor
					sensor = {}
					globVar.windows[j][i][8] = 0 -- reset screen value
					if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
						sensor = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])
					end
					if(sensor and sensor.valid) then
						globVar.windows[j][i][8] = sensor.value --set sensor value
						if(globVar.windows[j][i][1]==2)then -- store min max values
							globVar.windows[j][i][13]=sensor.min
							globVar.windows[j][i][14]=sensor.max
						end
					end
				end
				if(sensor and sensor.valid) then
					if(drawWin == false)then
						local func = chkLim_Lib[3] -- checkLimit(globVar.windows[j][i])
						func(globVar.windows[j][i]) 
					end	
				end	
				if(globVar.windows[j][i][9]>0)then
					globVar.failWindow = j
					allertSet = true
				end	

			end
		end
		if(aPrepare == false)then
			aTimeRunning = 0 --no alert in preparation, reset running alert delay
		end

		if((allertSet == false)and(timExpired == false))then
			globVar.failWindow = 0
		end
	end	
end
--------------------------------------------------------------------
local ScreenLib = {init,loop,unloadMainWin}
return ScreenLib

