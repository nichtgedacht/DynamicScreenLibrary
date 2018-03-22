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
local globVar = {} --global variables for application and screen library
-- app template config
local datafiles = {}    --list of all data files
local configRow =1		--row of cap increase int box
local fileBoxIndex = 0	--ID select box data files
local fileIndex = 1     --index of data file list
local capIncrease = 100 --increase capacity config step with

-------------------------------------------------------------------- 
-- filehandling
-------------------------------------------------------------------- 

local function loadDataFile()
	local file = nil
	for k in next,datafiles do datafiles[k] = nil end
	for name in dir("Apps/AppTempl/data") do
		if(#name >3) then
		table.insert(datafiles,name)
		end
	end
	fileIndex = system.pLoad("fileIndex",1)
	if(fileIndex > #datafiles)then
		fileIndex = 1
	end
	file = io.readall("Apps/AppTempl/data/"..datafiles[fileIndex].." ") --load datafile template

	if(file)then
		for i in next,globVar.windows do --delete window list 
			for k in next,globVar.windows[i] do globVar.windows[i][k] = nil end
			globVar.windows[i] = nil
		end	
		globVar.windows	= json.decode(file)
	end	
	file = nil
	file = io.readall("Apps/AppTempl/model/data/"..system.getProperty("ModelFile").." ") --load model specific data file
	if(file)then
		local sensors = json.decode(file)
		for i in next,globVar.windows do
			for k in next,globVar.windows[i] do
				if(#sensors[i]==#globVar.windows[i])then --overwrite sensorID and sensorparam from model file
					globVar.windows[i][k][10] = sensors[i][k][1]
					globVar.windows[i][k][11] = sensors[i][k][2]
				end
			end
		end
	end	
	return datafiles
end


local function storeDataFile()
	local senslist = {{},{},{}}
	for i in ipairs(globVar.windows)do
		for j in ipairs(globVar.windows[i]) do
			table.insert(senslist[i],{1,1}) 
			senslist[i][j][1] = globVar.windows[i][j][10]
			senslist[i][j][2] = globVar.windows[i][j][11]
		end
	end
	local winListWrite = json.encode(senslist)
	local file = io.open ("Apps/AppTempl/model/data/"..system.getProperty("ModelFile").."","w")
	io.write(file,winListWrite)
	io.close (file)
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
	capIncrease = value
	system.pSave("capIncrease",value)
	configRow = form.getFocusedRow()
	form.reinit(globVar.templateAppID)
end
local function dataFileChanged()
	local fileIndex_ = form.getValue(fileBoxIndex)
	if(fileIndex_ > 1)then
		if(form.question(globVar.trans.cont,globVar.trans.lTDat,globVar.trans.ovConf,0,false,0)==1)then
			system.pSave("fileIndex",fileIndex_)
			loadDataFile()
		end
	end	
	storeDataFile()
    form.reinit(globVar.templateAppID)
end

local function ScrSwitchChanged(value)
	globVar.ScrSwitch = value
	system.pSave("scrSwitch",value)
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
local function ECUTypeChanged(value)
    globVar.ECUType  = value --The value is local to this function and not global to script, hence it must be set explicitly.
	system.pSave("ECUType",  globVar.ECUType)
end
-------------------------------------------------------------------- 
-- app config page
--------------------------------------------------------------------
local function appConfig(globVar_)
	globVar = globVar_
	capIncrease = system.pLoad("capIncrease",100)
	loadDataFile()

	form.setTitle(globVar.trans.appName)
	form.setButton(1,"ScrLib",ENABLED)

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
		form.addIntbox(globVar.capa,0,32767,2400,0,capIncrease,capaChanged)
			
		form.addRow(2)
		form.addLabel({label=globVar.trans.capInc,width=170})
		form.addIntbox(capIncrease,10,100,100,0,10,capIncreaseChanged)
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
	form.addRow(1)
	form.addLabel({label="Powered by Geierwally - "..globVar.version.."  Mem max: "..globVar.mem.."K",font=FONT_MINI, alignRight=true})
	form.setFocusedRow (configRow)
	configRow = 1
end

local function keyPressed(key)
	if(key==KEY_MENU or key==KEY_ESC or key == KEY_5) then
		return(1) -- unload config
	elseif(key==KEY_1)then
	-- open with Key 1 the screen lib config
		form.reinit(globVar.screenlibID)
		return(0)
	end
end	


--------------------------------------------------------------------
local ConfigLib = {appConfig,keyPressed}
return ConfigLib