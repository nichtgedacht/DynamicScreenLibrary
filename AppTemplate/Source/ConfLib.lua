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

-- screen lib config
local winList = {} -- all windows
local sensList = {} -- all sensor labels
local sensPaList = {} -- all sensor parameter labels for selected sensor
local winListBox = nil -- ID of the windows label list box
local winListIdx = 1 -- index of label list box
local sensorListBox = nil -- ID of the sensor list box
local sensParListBox = nil -- ID of sensor param list box
local sensListIdx = 1 -- index of sensor list box
local sensPaListIdx = 1 -- index of sesor parameter list box
local timListIdx = 0 -- index of timer list

-------------------------------------------------------------------- 
-- filehandling
-------------------------------------------------------------------- 

local function loadDataFile()
	local file = nil
	for k in next,datafiles do datafiles[k] = nil end
	--local modelDatFile = ""..globVar.model..".jsn"
	table.insert(datafiles,system.getProperty("ModelFile"))
	for name in dir("Apps/AppTempl/data") do
		if(#name >3) then
		table.insert(datafiles,name)
		end
	end
	fileIndex = system.pLoad("fileIndex",1)
	if(fileIndex ==1)then
		file = io.readall("Apps/AppTempl/model/data/"..datafiles[1].." ") --load model specific data file
	end	
	if(file==nil)then
		if((fileIndex-1) > #datafiles or (fileIndex==1))then
			fileIndex = 2
		end
		file = io.readall("Apps/AppTempl/data/"..datafiles[fileIndex].." ") --load datafile template
	end	
	if(file)then
		for i in next,globVar.windows do --delete window list 
			for k in next,globVar.windows[i] do globVar.windows[i][k] = nil end
			globVar.windows[i] = nil
		end	
		globVar.windows	= json.decode(file)
	end	
	return datafiles
end

local function storeDataFile()
	local winListWrite = json.encode(globVar.windows)
	local file = io.open ("Apps/AppTempl/model/data/"..system.getProperty("ModelFile").."","w")
	io.write(file,winListWrite)
	io.close (file)
	system.pSave("fileIndex",1)
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
			fileIndex_ = 1
			system.pSave("fileIndex",fileIndex_)
		end
	end	
	storeDataFile()
    form.reinit(globVar.templateAppID)
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

-------------------------------------------------------------------- 
-- app config page
--------------------------------------------------------------------
local function appConfig()
	form.setTitle(globVar.trans.appName)
	form.setButton(1,"ScrLib",ENABLED)

	form.addRow(1)
	form.addLabel({label=globVar.trans.config,font=FONT_BOLD})

	form.addRow(2)
    form.addLabel({label="DataFile",width=170})
	fileBoxIndex = form.addSelectbox(datafiles,fileIndex,true,dataFileChanged,{width=170})
	
	if(globVar.windows[1][1][1] < 3) then 
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
-- screen lib configuration
-------------------------------------------------------------------- 
local function calcWinIdx(idx)
	local calc = 0
	
	for i in ipairs(globVar.windows) do
		for j in ipairs(globVar.windows[i]) do
			calc = calc +1
			if(calc == idx)then
				return i,j
			end
		end
	end
end

local function windowChanged()
  winListIdx = form.getValue(winListBox)
  local j,i = calcWinIdx(winListIdx)
  if((globVar.windows[j][i][4]>30)and(globVar.windows[j][i][4]<35))then
	timListIdx = math.modf(globVar.windows[j][i][4]-30) -- activate timer config
  else
	timListIdx = 0                           -- activate sensor config
  end
  form.reinit(globVar.screenlibID)
end

local function sensorChanged()
	sensListIdx = form.getValue(sensorListBox)
	local j,i = calcWinIdx(winListIdx)
	globVar.windows[j][i][10] = sensListIdx -- set sensorid to corresponding window 
	storeDataFile()
end

local function sensParChanged()
	sensPaListIdx = form.getValue(sensParListBox)
	local j,i = calcWinIdx(winListIdx)
	globVar.windows[j][i][11] = sensPaListIdx -- set sensor parameterid to corresponding window 
	storeDataFile()
end

local function startSwitchChanged(value)
	globVar.switches[1][timListIdx] = value
	system.pSave("timStart"..timListIdx.."",value)
end

local function stoppSwitchChanged(value)
	globVar.switches[2][timListIdx] = value
	system.pSave("timStopp"..timListIdx.."",value)
end

local function resetSwitchChanged(value)
	globVar.switches[3][timListIdx] = value
	system.pSave("timReset"..timListIdx.."",value)
end

local function limitChanged(value)
	globVar.timLimits[timListIdx] = value
	system.pSave("timLimit"..timListIdx.."",value)
	local j,i = calcWinIdx(winListIdx)
	globVar.windows[j][i][5] = value
	if(globVar.windows[j][i][7] ==0)then -- is timer switched off
		local preStart = {0,globVar.windows[j][i][5] * 60000,0,globVar.windows[j][i][5] * 1000} -- for preset start values
		local timerID = globVar.windows[j][i][4]-30
		globVar.windows[j][i][8] = preStart[globVar.windows[j][i][3]] --preset start value in ms
		system.pSave("timer"..timerID.."",globVar.windows[j][i][8]) -- save timer value on reset
	end	
end

-------------------------------------------------------------------- 
-- screen lib config page
--------------------------------------------------------------------

local function screenLibConfig()

	local j,i = calcWinIdx(winListIdx)
	local sensor = {}

	for k in next,sensList do sensList[k] = nil end
	for k in next,sensPaList do sensPaList[k] = nil end
	for k in next,winList do winList[k] = nil end

	sensListIdx = globVar.windows[j][i][10] --preset sensorlist index
	for idx in ipairs(globVar.sensors) do 
		sensor = system.getSensorByID (globVar.sensors[idx],0)
		table.insert(sensList, string.format("%s", sensor.label))
	end
	sensPaListIdx = globVar.windows[j][i][11] --preset parameterlist index
	if (globVar.sensParam[sensListIdx]~=nil) then
		for idx in ipairs(globVar.sensParam[sensListIdx]) do 
			sensor = system.getSensorByID (globVar.sensors[sensListIdx],globVar.sensParam[sensListIdx][idx])
			table.insert(sensPaList, string.format("%s", sensor.label))
		end
	end
  
	form.setTitle(globVar.trans.screenLib)
	form.addRow(1)
	form.addLabel({label=globVar.trans.config,font=FONT_BOLD})

	form.addRow(1)
	form.addLabel({label=globVar.trans.bindSens,font=FONT_BOLD})


	if( sensPaList[1] ~=nil) then
		for i in ipairs(globVar.windows[1]) do
			table.insert(winList,globVar.windows[1][i][2])	
		end		
		for i in ipairs(globVar.windows[2]) do
			if((globVar.windows[2][i][4]>0)and(globVar.windows[2][i][4]<11))then
				table.insert(winList,"***"..globVar.windows[2][i][2].."***")
			else
				table.insert(winList,globVar.windows[2][i][2])
			end			
		end	
		if(#globVar.windows == 3) then
			for i in ipairs(globVar.windows[3]) do
				if((globVar.windows[3][i][4]>0)and(globVar.windows[3][i][4]<11))then					
					table.insert(winList,"***"..globVar.windows[3][i][2].."***")
				else
					table.insert(winList,globVar.windows[3][i][2])
				end			
			end	
		end
		form.addRow(2)   
		form.addLabel({label="Label",width=170})
		winListBox = form.addSelectbox(winList,winListIdx,true,windowChanged)
		if(timListIdx==0)then
			form.addRow(2)
			form.addLabel({label="Sensor",width=170})
			sensorListBox = form.addSelectbox(sensList,sensListIdx,true,sensorChanged)

			form.addRow(2)
			form.addLabel({label="SensParam",width=170})
			sensParListBox = form.addSelectbox(sensPaList,sensPaListIdx,true,sensParChanged)
		end	
	end	

	if(timListIdx>0)then
		form.addRow(2)
		form.addLabel({label="Start "..timListIdx..""})
		form.addInputbox(globVar.switches[1][timListIdx],true,startSwitchChanged)
		form.addRow(2)
		form.addLabel({label="Stopp "..timListIdx..""})
		form.addInputbox(globVar.switches[2][timListIdx],true,stoppSwitchChanged)
		form.addRow(2)
		form.addLabel({label="Reset "..timListIdx..""})
		form.addInputbox(globVar.switches[3][timListIdx],true,resetSwitchChanged)
		form.addRow(2)
		local j,i = calcWinIdx(winListIdx)
		if(globVar.timLimits[timListIdx]==0) then
			globVar.timLimits[timListIdx]=globVar.windows[j][i][5]
		end
		local labeltxt = "Limit "
		local unit = " min"
		if(globVar.windows[j][i][3] % 2 ==0)then
			labeltxt = nil
			labeltxt = "Preset "
		end
		if(globVar.windows[j][i][3]>2)then
			unit = nil
			unit = " s"
		end
		form.addLabel({label=""..labeltxt..""..timListIdx..""..unit..""})
		form.addIntbox(globVar.timLimits[timListIdx],0,1000,globVar.windows[j][i][5],0,1,limitChanged)
    end	
	-- version
	form.addRow(1)
	form.addLabel({label="Powered by Geierwally - "..globVar.version.."  Mem max: "..globVar.mem.."K",font=FONT_MINI, alignRight=true})
	form.setFocusedRow (3)
end 

-------------------------------------------------------------------- 
-- screen lib config key eventhandler
--------------------------------------------------------------------
local function keyPressedScr(key)
    if(key==KEY_5 or key==KEY_ESC) then
      form.preventDefault()
      form.reinit(globVar.templateAppID)
	  for k in next,winList do winList[k] = nil end
    end
end 

-------------------------------------------------------------------- 
-- config init
--------------------------------------------------------------------
local function init(globVar_,formID)
	globVar = globVar_
	capIncrease = system.pLoad("capIncrease",100)
	loadDataFile()
	if(formID == globVar.templateAppID) then
		appConfig()-- open app template config page 
	elseif(formID == globVar.screenlibID) then
		screenLibConfig() -- open screen lib config page
	end
end
--------------------------------------------------------------------
local ConfigLib = {init,keyPressed,keyPressedScr}
return ConfigLib