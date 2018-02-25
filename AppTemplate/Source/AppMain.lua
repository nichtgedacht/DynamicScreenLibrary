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
local nCell = 3--number of lipo cells
local capa = 0-- capacity 
local capIncrease = 100 --increase capacity config step with
local configRow =1		--row of cap increase int box
local fileBoxIndex = 0	--ID select box data files
local datafiles = {}
local fileIndex = 1

--------------------------------------------------------------------------------
-- Application initializer

local function loadDataFile()
	datafiles = {}
	for name in dir("Apps/AppTempl/data") do
		if(#name >3) then
		table.insert(datafiles,name)
		end
	end
	fileIndex = system.pLoad("fileIndex",1)
	local file = io.readall("Apps/AppTempl/data/"..datafiles[fileIndex].." ")
	if(file)then
	    globVar.windows = {}
		globVar.windows	= json.decode(file)
	end	
	return datafiles
end


local function init(code,globVar_)
	globVar = globVar_
	-- Read available sensors for user to select
	globVar.sensors[1] = system.pLoad("sensors1", {1,1})-- list of all binded sensors main
	globVar.sensors[2] = system.pLoad("sensors2", {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}) -- list of all binded sensors telemetry screen 1
	globVar.sensors[3] = system.pLoad("sensors3", {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}) -- list of all binded sensors telemetry screen 2
	globVar.appValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- calculated application values

	loadDataFile() -- load all screen data

	local sensors = system.getSensors()
	for i,sensor in ipairs(sensors) do
		if (sensor.label ~= "") then
			table.insert(globVar.sensorLalist, string.format("%s", sensor.label))
			table.insert(globVar.sensorIdlist, string.format("%s", sensor.id))
			table.insert(globVar.sensorPalist, string.format("%s", sensor.param))
		end
	end
	if(sensorIdlist == nil)then
		-- only for simulation 
		globVar.sensorLalist = {}
		globVar.sensorIdlist = {}
		globVar.sensorPalist = {}
		globVar.sensorLalist = {"Sens1","Sens2","Sens3","Sens4","Sens5","Sens6","Sens7","Sens8"}
		globVar.sensorIdlist = {121,122,123,124,125,126,127,128}
		globVar.sensorPalist = {221,222,223,224,225,226,227,228}
		-- only for simulation sensors
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
		screen_lib = require("AppTempl/Tasks/ScrLib"..globVar.screenLib24.."")
	end
	if(screen_lib ~=nil)then
		local func = screen_lib[1]  --init() 
		func(globVar) -- execute specific initializer of screen library
    end	
	globVar.model = system.getProperty("Model")
	nCell = system.pLoad("nCell",3)
	capIncrease = system.pLoad("capIncrease",100)
	capa = system.pLoad("capa",2400)
	----only for simulation without connected telemetry
	SimCap = system.pLoad("SimCap")
	----only for simulation without connected telemetry
	SimVolt = system.pLoad("SimVolt")
	----only for simulation without connected telemetry
	SimRPM = system.pLoad("SimRPM")
end

--------------------------------------------------------------------
-- main config key event handler
--------------------------------------------------------------------
local function keyPressed(key)
	if(key==KEY_MENU or key==KEY_ESC) then
		form.preventDefault()
	elseif(key==KEY_1)then
	-- open with Key 1 the screen lib config
		form.reinit(globVar.screenlibID)
--**************************************************************---
--**************add your own key handler here**************---

--**************************************************************---
	end
end	

local function keyPressedTempl(key)
	if(globVar.currentForm == globVar.screenlibID) then
		if(screen_lib ~=nil)then
			local func = screen_lib[3]  --keyPressed() 
			func(key) -- execute config event handler of screen library
		end
	else
		keyPressed(key)
	end
end

-------------------------------------------------------------------- 
-- app configbutton handler
--------------------------------------------------------------------

--***********************************************************---
--*************add your own button handler here**************---

local function numberOfCellsChanged(value)
	nCell = value
	system.pSave("nCell",value)
end
local function capaChanged(value)
	capa = value
	system.pSave("capa",capa)
end
local function capIncreaseChanged(value)
	capIncrease = value
	system.pSave("capIncrease",value)
	configRow = form.getFocusedRow()
	form.reinit(globVar.templateAppID)
end
local function dataFileChanged()
    system.pSave("fileIndex",form.getValue(fileBoxIndex))
    loadDataFile()
    if(screen_lib ~=nil)then
		local func = screen_lib[5]  --loadmainWindow() 
		func() -- execute config event handler of screen library
	end
    form.reinit(globVar.templateAppID)
end
------only for simulation without connected telemetry
local function SimCapChanged(value)
	SimCap = value
	system.pSave("SimCap",value)
end
------only for simulation without connected telemetry
local function SimVoltChanged(value)
	SimVolt = value
	system.pSave("SimVolt",value)
end
------only for simulation without connected telemetry
local function SimRPMChanged(value)
	SimRPM = value
	system.pSave("SimRPM",value)
end


--***********************************************************---

-------------------------------------------------------------------- 
-- app config page
--------------------------------------------------------------------
local function appConfig()
	form.setTitle(globVar.trans.appName)
	form.setButton(1,"ScrLib",ENABLED)

	form.addRow(1)
	form.addLabel({label=globVar.trans.config,font=FONT_BOLD})

	form.addRow(2)
    form.addLabel({label="DataFile",width=100})
	fileBoxIndex = form.addSelectbox(datafiles,fileIndex,true,dataFileChanged,{width=220})
	
	if(globVar.windows[1][1][1] < 3) then 
	    if(globVar.windows[1][1][1] == 1) then --electro model 
			form.addRow(2)
			form.addLabel({label=globVar.trans.nCell,width=220})
			form.addIntbox(nCell,1,24,3,0,1,numberOfCellsChanged)
		end		

		form.addRow(2)
		form.addLabel({label=string.format("%s (%s)",globVar.trans.capa, globVar.windows[1][1][3]),width=180})
		form.addIntbox(capa,0,32767,2400,0,capIncrease,capaChanged)
			
		form.addRow(2)
		form.addLabel({label=globVar.trans.capInc,width=220})
		form.addIntbox(capIncrease,10,100,100,0,10,capIncreaseChanged)
	end

    --***********************************************************---
	--*******add your own app specific configuration here********---
	form.addRow(1)
	form.addLabel({label="SensorSimulation",font=FONT_BOLD})
	
	if(globVar.windows[1][1][1] == 1) then --electro model
		------only for simulation without connected telemetry
		form.addRow(2)
		form.addLabel({label="simCellVoltage"})
		form.addInputbox(SimVolt,true,SimVoltChanged)
	end
	------only for simulation without connected telemetry
	form.addRow(2)
	form.addLabel({label="simCapacity"})
	form.addInputbox(SimCap,true,SimCapChanged)
	------only for simulation without connected telemetry
	form.addRow(2)
	form.addLabel({label="simRPM"})
	form.addInputbox(SimRPM,true,SimRPMChanged)
    --***********************************************************---
	-- version
	form.addRow(1)
	form.addLabel({label="Powered by Geierwally - "..globVar.version.."  Mem max: "..globVar.mem.."K",font=FONT_MINI, alignRight=true})
	form.setFocusedRow (configRow)
	configRow = 1
end

--------------------------------------------------------------------
-- main display function
--------------------------------------------------------------------
local function initTempl(formID)
    globVar.currentForm=formID
	if(formID == globVar.templateAppID) then
		appConfig()-- open app template config page 
	else
		if(screen_lib ~= nil) then
			local func = screen_lib[4]  --screenLibConfig() 
			func() -- open screenLib config page
		end	
	end
end

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop()
 	if((screen_lib ~= nil)and (globVar.initDone == true))then
		-- register config page of the app template 
		system.registerForm(1,MENU_MAIN,globVar.trans.appName,initTempl,keyPressedTempl,printForm);
		if(globVar.sensorIdlist[1] ~= "...") then
			local sensor1 = system.getSensorByID(globVar.sensorIdlist[globVar.sensors[1][1]],globVar.sensorPalist[globVar.sensors[1][1]]) -- read sensor
			local sensor2 = system.getSensorByID(globVar.sensorIdlist[globVar.sensors[1][2]],globVar.sensorPalist[globVar.sensors[1][2]]) -- read sensor
		end
		if( system.getTime() % 2 == 0 ) then -- blink every second
			globVar.secClock = true
		else
			globVar.secClock = false
		end
	------only for simulation without connected telemetry
		local sensor1 = {}
		local sensor2  = {}
		local CapSimVal = system.getInputsVal(SimCap)
		if(CapSimVal ~= nil)then
			sensor1["valid"] = true
			sensor1["value"] = 0
			CapSimVal = math.modf(CapSimVal*100) 
			CapSimVal = capa*CapSimVal/100
			sensor1.value = CapSimVal
		else
			sensor1["valid"] = false
			sensor1["value"] = 0
		end
		
		if(globVar.windows[1][1][1] == 1) then -- electro model
			local VoltSimVal = system.getInputsVal(SimVolt)
			if(VoltSimVal ~= nil)then
				sensor2["valid"] = true
				sensor2["value"] = 0
				VoltSimVal = math.modf(VoltSimVal*100) 
				VoltSimVal = 1 * VoltSimVal/100 + 3.2
				sensor2.value = VoltSimVal
			else
				sensor2["valid"] = false
				sensor2["value"] = 0
			end
		end
		
		local RPM_SimVal = system.getInputsVal(SimRPM)
		if(RPM_SimVal ~=nil)then
		globVar.appValues[3] = RPM_SimVal * 25000
		end
	------only for simulation without connected telemetry
		if(sensor1 and sensor1.valid) then
			globVar.appValues[1] = (((capa - sensor1.value) * 100) / capa) --calculate capacity
			if (globVar.appValues[1] < 0) then
				globVar.appValues[1] = 0
			else
				if (globVar.appValues[1] > 100) then
					globVar.appValues[1] = 100
				end
			end
		end	
		if(sensor2 and sensor2.valid) then
			globVar.appValues[2] = (sensor2.value / nCell) --calculate cell voltage
		end	
		
		local func = screen_lib[2] --
		func() -- execute specific screen library
		
    --***********************************************************---
	--*******add your own main loop functionalities here*********---

    --***********************************************************---
	else	
		system.unregisterForm(1);
	end	
    collectgarbage()
end

--------------------------------------------------------------------
local AppTemplate_Main = {init,loop}
return AppTemplate_Main
