--[[
	---------------------------------------------------------
	Geierwallys dynamic telemetry screen library for DC/DS 14,16 and 24 transmitters
	dynamic configuration page for app template and screen libray
	---------------------------------------------------------
	V1.1.1 Initial state prepares all functionalities of the app template except telemetry 
	       Telemetry is simulated for first function tests
	---------------------------------------------------------
--]]
-------------------------------------------------------------------- 
-- local variables
-------------------------------------------------------------------- 
local globVar = nil --global variables for application and screen library
-- app template config
local datafiles = {}    --list of all data files
local configRow =1		--row of cap increase int box
local fileBoxIndex = 0	--ID select box data files
local fileIndex = 1     --index of data file list


-------------------------------------------------------------------- 
-- filehandling
-------------------------------------------------------------------- 
local function ECUTypeChanged(value)
    globVar.ECUType  = value --The value is local to this function and not global to script, hence it must be set explicitly.
	local file = io.readall("Apps/AppTempl/model/ECU_Data/"..value..".jsn") -- hardcoded for now
	globVar.ECUStat = {}
	globVar.ECUStat  = json.decode(file)
	system.pSave("ECUType",  globVar.ECUType)
end

local function loadDataFile()
print("loadDataFile")
	fileIndex = 1
	local file = nil
	for k in next,datafiles do datafiles[k] = nil end
	local datFile = system.pLoad("datFile","---")
	for name in dir("Apps/AppTempl/data") do
		if(#name >3) then
			table.insert(datafiles,name)
			if(name == datFile)then
				fileIndex = #datafiles
			end
		end
	end
    if(datFile == "---")then
		datFile = nil
		datFile = datafiles[1]
	end
	file = io.readall("Apps/AppTempl/data/"..datFile.."") --load datafile template

	if(file)then
		for i in next,globVar.windows do --delete window list 
			for k in next,globVar.windows[i] do globVar.windows[i][k] = nil end
			globVar.windows[i] = nil
		end	
		globVar.windows	= json.decode(file)
		
		-- replace any string with numbers if it contains digits and no letters (i.e. "120" but not "1/min")
		for i in next,globVar.windows do
			for k in next,globVar.windows[i] do
				for s in next, globVar.windows[i][k] do
					if ( string.match(globVar.windows[i][k][s], "%d") and not string.match(globVar.windows[i][k][s], "%a") ) then
						globVar.windows[i][k][s] = tonumber(globVar.windows[i][k][s])
					end
				end	
			end
		end
		
	end	
	file = nil
	file = io.readall("Apps/AppTempl/model/data/"..system.getProperty("ModelFile").." ") --load model specific data file
	if(file)then
		local sensors = json.decode(file)
		for i in next,globVar.windows do
			if(i<= #sensors)then
				for k in next,globVar.windows[i] do
					if(#sensors[i]==#globVar.windows[i])then --overwrite sensorID and sensorparam from model file
						globVar.windows[i][k][10] = sensors[i][k][1]
						globVar.windows[i][k][11] = sensors[i][k][2]
					end
				end
			end	
		end
	end	
	return datafiles
end

-------------------------------------------------------------------- 
-- app configuration
-------------------------------------------------------------------- 

local function numberOfCellsChanged(value)
	globVar.nCell = value
	system.pSave("nCell",value)
end
local function capaChanged(value)
	globVar.capa = value
	system.pSave("capa",globVar.capa)
end
local function capIncreaseChanged(value)
	globVar.capIncrease = value
	system.pSave("capIncrease",value)
	configRow = form.getFocusedRow()
	form.reinit(globVar.templateAppID)
end
local function dataFileChanged(value)
	if(form.question(globVar.trans.cont,globVar.trans.lTDat,globVar.trans.ovConf,0,false,0)==1)then
		fileIndex = value
		system.pSave("datFile",datafiles[fileIndex])
		loadDataFile()
	end
	if(globVar.windows[1][1][1]==3)then -- only for turbine
		ECUTypeChanged(globVar.ECUType)
	end	
    form.reinit(globVar.templateAppID)
end

local function ScrSwitchChanged(value)
	globVar.ScrSwitch = value
	system.pSave("scrSwitch",value)
end

local function SwitchLockAlertChanged(value)
	globVar.LockAlertSwitch = value
	system.pSave("LockAlertSwitch",value)
end

local function SwitchMaintCountChanged(value)
	globVar.maintCountSwitch = value
	system.pSave("MaintCountSwitch",value)
end

local function maint1Changed(value)
	globVar.mainten[1]  = value
	system.pSave("Maintenance_1",value)
end

local function maint2Changed(value)
	globVar.mainten[2]  = value
	system.pSave("Maintenance_2",value)
end

local function maint3Changed(value)
	globVar.mainten[3]  = value
	system.pSave("Maintenance_3",value)
end

-- ------only for simulation without connected telemetry
-- local function SimCapChanged(value)
	-- SimCap = value
	-- system.pSave("SimCap",value)
-- end
-- ------only for simulation without connected telemetry
-- local function SimVoltChanged(value)
	-- SimVolt = value
	-- system.pSave("SimVolt",value)
-- end
-- ------only for simulation without connected telemetry
-- local function SimRPMChanged(value)
	-- SimRPM = value
	-- system.pSave("SimRPM",value)
-- end

--***********************************************************---
--*************add your own button handler here**************---
--***********************************************************---
-- Take care of user's settings-changes


-------------------------------------------------------------------- 
-- app config page
--------------------------------------------------------------------
local function appConfig(globVar_)
	globVar = globVar_
	local datFile = system.pLoad("datFile","---")
	for k in next,datafiles do datafiles[k] = nil end
	for name in dir("Apps/AppTempl/data") do
		if(#name >3) then
			table.insert(datafiles,name)
			if(name == datFile)then
				fileIndex = #datafiles
			end
		end
	end	
	
	form.setTitle(globVar.trans.appName)
	form.setButton(1,"ScrLib",ENABLED)
	form.setButton(2,"ResTim",ENABLED)

	form.addRow(1)
	form.addLabel({label=globVar.trans.config,font=FONT_BOLD})

	form.addRow(2)
    form.addLabel({label="DataFile",width=170})
	fileBoxIndex = form.addSelectbox(datafiles,fileIndex,true,dataFileChanged,{width=170})
	
	if(#globVar.windows == 3)then
		form.addRow(2)
		form.addLabel({label="TeleScreen2"})
		form.addInputbox(globVar.ScrSwitch,true,ScrSwitchChanged)
	end
	
	if(globVar.windows[1][1][1] < 4) then 
	    if(globVar.windows[1][1][1] == 1) then --electro model 
			form.addRow(2)
			form.addLabel({label=globVar.trans.nCell,width=170})
			form.addIntbox(globVar.nCell,1,24,3,0,1,numberOfCellsChanged)
		end		

		form.addRow(2)
		form.addLabel({label=string.format("%s (%s)",globVar.trans.capa, globVar.windows[1][1][3]),width=170})
		form.addIntbox(globVar.capa,0,32767,2400,0,globVar.capIncrease,capaChanged)
			
		form.addRow(2)
		form.addLabel({label=globVar.trans.capInc,width=170})
		form.addIntbox(globVar.capIncrease,10,100,100,0,10,capIncreaseChanged)
		
		form.addRow(2)
		form.addLabel({label=globVar.trans.swLckAl})
		form.addInputbox(globVar.LockAlertSwitch,true,SwitchLockAlertChanged)
		
		form.addRow(2)
		form.addLabel({label=globVar.trans.swMaintCount})
		form.addInputbox(globVar.maintCountSwitch,true,SwitchMaintCountChanged)
		
		form.addRow(2)
		form.addLabel({label=globVar.trans.maint1,width=170})
		form.addIntbox(globVar.mainten[1],0,1000,100,0,globVar.capIncrease,maint1Changed)
		
		form.addRow(2)
		form.addLabel({label=globVar.trans.maint2,width=170})
		form.addIntbox(globVar.mainten[2],0,1000,100,0,globVar.capIncrease,maint2Changed)
		
		form.addRow(2)
		form.addLabel({label=globVar.trans.maint3,width=170})
		form.addIntbox(globVar.mainten[3],0,1000,100,0,globVar.capIncrease,maint3Changed)
	end
    --***********************************************************---
	--*******add your own app specific configuration here********---
	if(globVar.windows[1][1][1]==3)then
		local ECUTypeA = {"JetCat","Jakadofsky","HORNET","PBS","evoJet","AMT"}
		form.addRow(2)
		form.addLabel({label="ECU Typ", width=200})
		form.addSelectbox(ECUTypeA, globVar.ECUType, true, ECUTypeChanged)
	end	

	-- if(#globVar.sensors ==0)then
		-- form.addRow(1)
		-- form.addLabel({label="SensorSimulation",font=FONT_BOLD})
	
		-- if(globVar.windows[1][1][1] == 1) then --electro model
		-- ------only for simulation without connected telemetry
			-- form.addRow(2)
			-- form.addLabel({label="simCellVoltage"})
			-- form.addInputbox(SimVolt,true,SimVoltChanged)
		-- end
		-- ------only for simulation without connected telemetry
		-- form.addRow(2)
		-- form.addLabel({label="simCapacity"})
		-- form.addInputbox(SimCap,true,SimCapChanged)
		-- ------only for simulation without connected telemetry
		-- form.addRow(2)
		-- form.addLabel({label="simRPM"})
		-- form.addInputbox(SimRPM,true,SimRPMChanged)
	-- end
    --***********************************************************---
	-- version
	local timeVal = globVar.maintenTimer
	if(0 < globVar.maintenStartTime) then
		timeVal = globVar.currentTime - globVar.maintenStartTime + globVar.maintenTimer
	end	
	local temp = timeVal / 3600000
	local timeHour = 0
	local timeMin = 0	
	local timesec = 0
	timeHour,temp = math.modf(temp)
	temp = temp *60
	timeMin,temp = math.modf(temp)	
	temp = temp *60
	timesec = math.modf(temp)
	local timestring = string.format( "%03d:%02d:%02d",math.abs(timeHour),math.abs(timeMin),math.abs(timesec) ) 
	form.addRow(1)
	form.addLabel({label=""..timestring.."  Powered by Geierwally - "..globVar.version.."  Mem max: "..globVar.mem.."K",font=FONT_MINI, alignRight=true})
	form.setFocusedRow (configRow)
	configRow = 1
end


local function init(globVar_)
	globVar = globVar_
	globVar.capIncrease = system.pLoad("capIncrease",100)
	loadDataFile()
	appConfig(globVar)
	if(globVar.windows[1][1][1]==3)then -- only for turbine
		ECUTypeChanged(globVar.ECUType)
	end	
end


local function keyPressed(key)
	if(key==KEY_MENU or key==KEY_ESC or key == KEY_5) then
		globVar = nil
		datafiles = {}
		return(1) -- unload config
	elseif(key==KEY_1)then
	-- open with Key 1 the screen lib config
		form.reinit(globVar.screenlibID)
		return(0)
	elseif(key==KEY_2)then
    -- open yes no box for reset maintenance timer
		if(form.question(globVar.trans.ResTim,globVar.trans.Tim,globVar.trans.TimDes,0,false,0)==1)then
			globVar.maintenTimer = 0
		    system.pSave("MaintenanceTimer",globVar.maintenTimer) -- save maintanance necessary set value
		end	
	end
end	


--------------------------------------------------------------------
local ConfigLib = {appConfig,keyPressed,init}
return ConfigLib
