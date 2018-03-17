--[[
	---------------------------------------------------------
	Lua App template for Geierwallys dynamic telemetry screen library
	Makes flexible display adjustments possible. Users can create her own screenfiles
	2 telemetry pages adjustable by user over data files provided.
	Dynamic hardware detection and automatically loading of 14/16 or 24 screen lib 
	---------------------------------------------------------
	V1.1.1 Initial state prepares all functionalities of the app template except telemetry 
	       Telemetry is simulated for first function tests
	---------------------------------------------------------
--]]

--------------------------------------------------------------------------------
-- Locals for the application
local globVar =  nil--    global variables for application and screen library
local screen_lib = nil --depending on device loaded screen library
local config_lib = nil --loaded config library
local scrlib_Path = nil --path to screen lib
local config_Path = nil --path to config lib


--------------------------------------------------------------------------------
-- Application initializer

local function init(code,globVar_)
	globVar = globVar_
	globVar.appValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- calculated application values
	if(config_lib == nil)then -- initialize configurations, load datafile
		config_Path = "AppTempl/Tasks/ConfLib"
		config_lib = require(config_Path)
	end
	if(config_lib ~=nil)then
		local func = config_lib[1]  --init() 
		func(globVar,0) -- execute specific initializer of config lib
		package.loaded[config_Path]=nil -- unload config lib
		_G[config_Path]=nil
		config_lib = nil
		config_Path = nil
    end
	-- read device type for loading corresponding screen library
	local deviceType = system.getDeviceType()
	if(( deviceType == "JETI DC-24")or(deviceTypeF3K == "JETI DS-24"))then
		globVar.screenLib24 = 24 -- load screen library of DS / DC 24
	end
	-- Set language
	local lng=system.getLocale();
	local file = io.readall("Apps/AppTempl/lang/"..lng.."/locale.jsn")
	local obj = json.decode(file)  
	if(obj) then
		globVar.trans = obj
	end
	globVar.currentDate = system.getDateTime()
	if(screen_lib == nil)then
		scrlib_Path = "AppTempl/Tasks/ScrLib"..globVar.screenLib24..""
		screen_lib = require(scrlib_Path)
	end
	if(screen_lib ~=nil)then
		local func = screen_lib[1]  --init() 
		func(globVar) -- execute specific initializer of screen library
    end	
	globVar.model = system.getProperty("Model")
	globVar.nCell = system.pLoad("nCell",3)
	globVar.capa = system.pLoad("capa",2400)
	globVar.ECUType = system.pLoad("ECUType",1)
	globVar.ScrSwitch = system.pLoad("scrSwitch")

	-- ----only for simulation without connected telemetry
	-- SimCap = system.pLoad("SimCap")
	-- ----only for simulation without connected telemetry
	-- SimVolt = system.pLoad("SimVolt")
	-- ----only for simulation without connected telemetry
	-- SimRPM = system.pLoad("SimRPM")
end

--------------------------------------------------------------------
-- main config key event handler
--------------------------------------------------------------------

local function keyPressedTempl(key)
	local func = nil
	if(config_lib ~=nil)then
		if(globVar.currentForm == globVar.screenlibID) then
			func = config_lib[3]  --keyPressedScr()
			func(key) -- execute config event handler screen library
		else
			func = config_lib[2]  --keyPressed()
			if(func(key)==1) then -- execute config event handler app template
				init(1,globVar)	  -- close and unload config, reinitialize
				form.close()
			end
		end
	end	
end


--------------------------------------------------------------------
-- main display function
--------------------------------------------------------------------
local function initTempl(formID)
    globVar.currentForm=formID
	if(screen_lib ~= nil)then			--unload screen lib on open configuration
		package.loaded[scrlib_Path]=nil
		_G[scrlib_Path]=nil
		screen_lib = nil
		scrlib_Path = nil
	end
	if(config_lib == nil)then
		config_Path = "AppTempl/Tasks/ConfLib"
		config_lib = require(config_Path)
	end
	if(config_lib ~=nil)then
		local func = config_lib[1]  --init() 
		func(globVar,formID) -- execute specific initializer of config lib
    end
end

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop()
	local sensor1 = {}
	local sensor2 = {}
	local sensID = 0
	local sensPar = 0

	system.registerForm(1,MENU_MAIN,globVar.trans.appName,initTempl,keyPressedTempl,printForm);
	--system.unregisterForm(1);
	
 	if((screen_lib ~= nil)and (globVar.initDone == true))then
		-- register config page of the app template 
		local txTel = system.getTxTelemetry()
		globVar.appValues[3]= txTel.rx1Voltage
		globVar.appValues[4]= txTel.rx2Voltage
		globVar.appValues[5]= txTel.rx1Percent
		globVar.appValues[6]= txTel.rx2Percent
		globVar.appValues[7]= txTel.RSSI[1]
		globVar.appValues[8]= txTel.RSSI[2]
		globVar.appValues[9]= txTel.RSSI[3]
		globVar.appValues[10]= txTel.RSSI[4]

		sensID = globVar.windows[1][1][10]
		sensPar = globVar.windows[1][1][11] 
		if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
			sensor1 = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])	
		end
		if(globVar.windows[1][1][1]==1)then
			sensID = globVar.windows[1][2][10]
			sensPar = globVar.windows[1][2][11] 
			if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
				sensor2 = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])	
			end
		end	
		-- else
	-- ------only for simulation without connected telemetry
			-- sensor1 = {}
			-- sensor2  = {}
			-- local CapSimVal = system.getInputsVal(SimCap)
			-- if(CapSimVal ~= nil)then
				-- sensor1["valid"] = true
				-- sensor1["value"] = 0
				-- CapSimVal = math.modf(CapSimVal*100) 
				-- CapSimVal = globVar.capa*CapSimVal/100
				-- sensor1.value = CapSimVal
			-- else
				-- sensor1["valid"] = false
				-- sensor1["value"] = 0
			-- end
		
			-- if(globVar.windows[1][1][1] == 1) then -- electro model
				-- local VoltSimVal = system.getInputsVal(SimVolt)
				-- if(VoltSimVal ~= nil)then
					-- sensor2["valid"] = true
					-- sensor2["value"] = 0
					-- VoltSimVal = math.modf(VoltSimVal*100) 
					-- VoltSimVal = 1 * VoltSimVal/100 + 3.2
					-- sensor2.value = VoltSimVal
				-- else
					-- sensor2["valid"] = false
					-- sensor2["value"] = 0
				-- end
			-- end
		
			-- local RPM_SimVal = system.getInputsVal(SimRPM)
			-- if(RPM_SimVal ~=nil)then
			-- globVar.appValues[3] = RPM_SimVal * 25000
			-- end
	-- ------only for simulation without connected telemetry
	--	end
		if( system.getTime() % 2 == 0 ) then -- blink every second
			globVar.secClock = true
		else
			globVar.secClock = false
		end
		if(sensor1 and sensor1.valid) then
			globVar.appValues[1] = (((globVar.capa - sensor1.value) * 100) / globVar.capa) --calculate capacity
			if (globVar.appValues[1] < 0) then
				globVar.appValues[1] = 0
			else
				if (globVar.appValues[1] > 100) then
					globVar.appValues[1] = 100
				end
			end
		else
			globVar.appValues[1]=0
		end	
		if(sensor2 and sensor2.valid) then
			globVar.appValues[2] = (sensor2.value / globVar.nCell) --calculate cell voltage
		else
			globVar.appValues[2] = 0
		end	
		
		local func = screen_lib[2] --
		func() -- execute specific screen library
		
    --***********************************************************---
	--*******add your own main loop functionalities here*********---

    --***********************************************************---
	end
    collectgarbage()
end

--------------------------------------------------------------------
local AppTemplate_Main = {init,loop}
return AppTemplate_Main
