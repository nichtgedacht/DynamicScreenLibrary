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
local config_tmpl = nil --loaded config template library
local config_scr = nil --loaded config screen library
local scrlib_Path = nil --path to screen lib
local config_tmplPath = nil --path to config template lib
local config_scrPath = nil --path to config screen lib
local loadScreenLib = false

local function storeDataFile()
	local file = io.open ("Apps/AppTempl/model/data/"..system.getProperty("ModelFile").."","w")
	local tmpWr1 = false
	local tmpWr2 = false
	local tmpString = nil
	if(file)then
		io.write(file,"[")
		for i in ipairs(globVar.windows)do
			if(tmpWr1 == false)then
				tmpWr1 = true
				io.write(file,"[")
			else
				io.write(file,",[")
			end
			tmpWr2 = false
			for j in ipairs(globVar.windows[i]) do
				if(tmpWr2 == false)then
					tmpWr2 = true
					tmpString = string.format("[%d,%d]",globVar.windows[i][j][10],globVar.windows[i][j][11])
				else
					tmpString = string.format(",[%d,%d]",globVar.windows[i][j][10],globVar.windows[i][j][11])
				end
				io.write(file,tmpString)
			end
			io.write(file,"]")
		end
		io.write(file,"]")
		io.close (file)
	end
				   
end
--------------------------------------------------------------------------------
-- Application initializer

local function init(code,globVar_)
	globVar = globVar_
	globVar.appValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- calculated application values
	globVar.model = system.getProperty("Model")
	globVar.nCell = system.pLoad("nCell",3)
	globVar.capa = system.pLoad("capa",2400)
	globVar.ECUType = system.pLoad("ECUType",1)
	globVar.ScrSwitch = system.pLoad("scrSwitch")
	globVar.LockAlertSwitch = system.pLoad("LockAlertSwitch")
	globVar.maintCountSwitch = system.pLoad("MaintCountSwitch")
	globVar.mainten[1] = system.pLoad("Maintenance_1",0)
	globVar.mainten[2] = system.pLoad("Maintenance_2",0)
	globVar.mainten[3] = system.pLoad("Maintenance_3",0)
	globVar.maintenTimer = system.pLoad("MaintenanceTimer",0)
	globVar.maintenSet = system.pLoad("MaintenanceSet",0)
	config_tmplPath = "AppTempl/Tasks/ConfTmpl"
	config_tmpl = require(config_tmplPath)
	if(config_tmpl ~=nil)then
		local func = config_tmpl[3]  --init() 
		func(globVar) -- execute specific initializer of app template config
		package.loaded[config_tmplPath]=nil -- unload app template config
		_G[config_tmplPath]=nil
		config_tmpl = nil
		config_tmplPath = nil
		collectgarbage('collect')
    end
	-- read device type for loading corresponding screen library
	local deviceType = system.getDeviceType()

	if(( deviceType == "JETI DC-24")or(deviceType == "JETI DS-24"))then
		globVar.screenLib24 = 24 -- load screen library of DS / DC 24
	else
		globVar.screenLib24 = 14
	end
	
	local lng=system.getLocale();
	local file = io.readall("Apps/AppTempl/lang/"..lng.."/locale.jsn")
	local obj = json.decode(file)  
	if(obj) then
		globVar.trans = obj
	end
	globVar.currentDate = system.getDateTime()
	loadScreenLib = true;

	-- reset maintenance requests if done 
	if((globVar.mainten[1] > 0) and ( 1 < ((globVar.maintenTimer/3600000) % globVar.mainten[1]))and(0 < (globVar.maintenSet & 0x10)))then -- limit 1 maintenance done, reset request
		globVar.maintenSet = globVar.maintenSet & 0xee
		system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
	elseif((globVar.mainten[2] > 0) and ( 1 < ((globVar.maintenTimer/3600000)  % globVar.mainten[2]))and(0 < (globVar.maintenSet & 0x20)))then -- limit 2 maintenance done, reset request
		globVar.maintenSet = globVar.maintenSet & 0xdd
		system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
	elseif((globVar.mainten[3] > 0) and ( 1 < ((globVar.maintenTimer/3600000)  % globVar.mainten[3]))and(0 < (globVar.maintenSet & 0x40)))then -- limit 3 maintenance done, reset request
		globVar.maintenSet = globVar.maintenSet & 0xbb
		system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
	end
	
    -- yes no box maintenance done	
	if(1 ==  (globVar.maintenSet & 0x11)) then -- maintenance necessary but not done
		local memTxt = " "..globVar.trans.maint.."  "..globVar.mainten[1].."h"
		if(form.question(globVar.trans.maintDone,memTxt,globVar.trans.maintDes,0,false,0)==1)then
			globVar.maintenSet = globVar.maintenSet | 0x10
		    system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
		end
	elseif(2 ==  (globVar.maintenSet & 0x22)) then -- maintenance necessary but not done
		local memTxt = " "..globVar.trans.maint.."  "..globVar.mainten[2].."h"
		if(form.question(globVar.trans.maintDone,memTxt,globVar.trans.maintDes,0,false,0)==1)then
			globVar.maintenSet = globVar.maintenSet | 0x20
		    system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
		end
	elseif(4 ==  (globVar.maintenSet & 0x44)) then -- maintenance necessary but not done
		local memTxt = " "..globVar.trans.maint.."  "..globVar.mainten[3].."h"
		if(form.question(globVar.trans.maintDone,memTxt,globVar.trans.maintDes,0,false,0)==1)then
			globVar.maintenSet = globVar.maintenSet | 0x40
		    system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
		end	
	end	
	
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
	if(globVar.currentForm == globVar.screenlibID) then
		if(config_scr ~=nil)then
			func = config_scr[2]  --keyPressedScr()
			func(key) -- execute config event handler screen library
		end	
	else
		if(config_tmpl ~=nil)then
			func = config_tmpl[2]  --keyPressed()
			func(key)
			if((key == KEY_5) or (key == KEY_ESC) or (key == KEY_MENU))then -- execute config event handler app template
	globVar.debugmem = math.modf(collectgarbage('count'))
	print("config loaded: "..globVar.debugmem.."K")	
				if(config_scr ~= nil)then --unload screen lib config
				print("unload scrconf")
					package.loaded[config_scrPath]=nil
					_G[config_scrPath]=nil
					config_scr = nil
					config_scrPath = nil
				end
				if(config_tmpl ~=nil)then
				print("unload templconf")
					package.loaded[config_tmplPath]=nil -- unload app template config
					_G[config_tmplPath]=nil
					config_tmpl = nil
					config_tmplPath = nil
				end
				storeDataFile()
				collectgarbage('collect')
				form.close()
				loadScreenLib = true -- load screen lib on loop cycle
	globVar.debugmem = math.modf(collectgarbage('count'))
	print("config unloaded: "..globVar.debugmem.."K")		

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
		screen_lib.unloadMainWin()
		package.loaded[scrlib_Path]=nil
		_G[scrlib_Path]=nil
		screen_lib = nil
		scrlib_Path = nil
		collectgarbage('collect')
	end
	if(globVar.currentForm == globVar.templateAppID)then -- initialize template app config
		if(config_scr ~= nil)then
			package.loaded[config_scrPath]=nil
			_G[config_scrPath]=nil
			config_scr = nil
			config_scrPath = nil
			collectgarbage('collect')
		end

		if(config_tmpl == nil)then
			config_tmplPath = "AppTempl/Tasks/ConfTmpl"
			config_tmpl = require(config_tmplPath)
		end

		if(config_tmpl ~=nil)then
			local func = config_tmpl[1]  --init() 
			func(globVar,1) -- execute specific initializer of config app template
		end
		elseif(globVar.currentForm == globVar.screenlibID)then -- initialize screen config
		if(config_tmpl ~= nil)then
			package.loaded[config_tmplPath]=nil
			_G[config_tmplPath]=nil
			config_tmpl = nil
			config_tmplPath = nil
			collectgarbage('collect')
		end
		if(config_scr == nil)then
			config_scrPath = "AppTempl/Tasks/ConfScr"
			config_scr = require(config_scrPath)
		end
		if(config_scr ~=nil)then
			local func = config_scr[1]  --init() 
			func(globVar) -- execute specific initializer of config screen lib
		end
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
	
 	if((screen_lib ~= nil)and (globVar.initDone == true))then
		--system.unregisterForm(1);
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

		 --else
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
		end
		if( system.getTime() % 2 == 0 ) then -- blink every second
			globVar.secClock = true
		else
			globVar.secClock = false
		end
		local ltype1 =nil
		ltype1 = type(sensor1.value)
		if(sensor1 and sensor1.valid) then
			if(ltype1 == "number")then
			    globVar.appValues[11]= globVar.capa - sensor1.value -- remainning gas
				globVar.appValues[1] = ((globVar.appValues[11] * 100) / globVar.capa) --calculate capacity
				if (globVar.appValues[1] < 0) then
					globVar.appValues[1] = 0
				else
					if (globVar.appValues[1] > 100) then
						globVar.appValues[1] = 100
					end
				end
			else
				print("capsensfailed", sensor1.value, ltype1)
				globVar.appValues[1]= -1
			end
		else
			globVar.appValues[1]=0
		end	
		ltype1 = nil
		ltype1 = type(sensor2.value)
		if(sensor2 and sensor2.valid) then
			if(ltype1 == "number")then
				globVar.appValues[2] = (sensor2.value / globVar.nCell) --calculate cell voltage
			else
				print("Vsensfailed", sensor2.value, ltype1)
				globVar.appValues[2] = -1
			end
		else
			globVar.appValues[2] = 0
		end	
		
		screen_lib.loop()
		
    --***********************************************************---
	--*******add your own main loop functionalities here*********---
 
    --***********************************************************---
	else
		if(loadScreenLib == true)then
			loadScreenLib = false
			if(screen_lib == nil)then
				scrlib_Path = "AppTempl/Tasks/ScrLib"..globVar.screenLib24..""
				screen_lib = require(scrlib_Path)
			end
			if(screen_lib ~=nil)then
				screen_lib.init(globVar)
			end
    collectgarbage('collect')
	globVar.debugmem = math.modf(collectgarbage('count'))
	print("scrlib loaded: "..globVar.debugmem.."K")		
		end	
	end
    collectgarbage('collect')
	globVar.debugmem = math.modf(collectgarbage('count'))
	if (globVar.mem < globVar.debugmem) then
		globVar.mem = globVar.debugmem
		print("max Speicher Zyklus: "..globVar.mem.."K")		
	end
	local timeVal = globVar.maintenTimer
	if(globVar.maintenStartTime >0)then
		timeVal = globVar.currentTime - globVar.maintenStartTime + globVar.maintenTimer
	end	
	
	--comment in following lines for display maintenance timer on console
	--local temp = timeVal / 3600000
	--local timeHour = 0
	--local timeMin = 0	
	--local timesec = 0
	--timeHour,temp = math.modf(temp)
	--temp = temp *60
	--timeMin,temp = math.modf(temp)	
	--temp = temp *60
	--timesec = math.modf(temp)
	--local timestring = string.format( "%03d:%02d:%02d",math.abs(timeHour),math.abs(timeMin),math.abs(timesec) ) 
	--print(timestring)
end

--------------------------------------------------------------------
return {

	init = init,
	loop = loop
	
}	

