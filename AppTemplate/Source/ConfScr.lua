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
local focRow = 3
local imgFileName = nil -- img file for 24 transmitters
local imgfileIdx = 0    -- img file list index
local imgFile = {}

local function destroyLists()
	for k in next,sensList do sensList[k] = nil end
	for k in next,sensPaList do sensPaList[k] = nil end
	for k in next,winList do winList[k] = nil end
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
	if((globVar.windows[j][i][1]==7)or(globVar.windows[j][i][1]==8))then
		imgFileName = nil
		imgFileName = system.pLoad("imgFileName","---")
	else
		imgFileName = nil
	end
  end
  focRow = 4
  form.reinit(globVar.screenlibID)
end

local function sensorChanged()
	sensListIdx = form.getValue(sensorListBox)
	local j,i = calcWinIdx(winListIdx)
	if(sensListIdx < #sensList)then
		globVar.windows[j][i][10] = sensListIdx -- set sensorid to corresponding window 
		sensPaListIdx = 1 
		globVar.windows[j][i][11] = 1 -- preset parameter list index with first element
		focRow = 5
	end	
	form.reinit(globVar.screenlibID)
end

local function sensParChanged()
	sensPaListIdx = form.getValue(sensParListBox)
	if(sensPaListIdx < #sensPaList)then
		local j,i = calcWinIdx(winListIdx)
		globVar.windows[j][i][10] = sensListIdx -- set sensorid to corresponding window
		globVar.windows[j][i][11] = sensPaListIdx -- set sensor parameterid to corresponding window 
		focRow = 3
	end	
	form.reinit(globVar.screenlibID)
end

local function startSwitchChanged(value)
	globVar.switches[1][timListIdx] = value
	system.pSave("timStart"..timListIdx.."",value)
	focRow = 5
	form.reinit(globVar.screenlibID)
end

local function stoppSwitchChanged(value)
	globVar.switches[2][timListIdx] = value
	system.pSave("timStopp"..timListIdx.."",value)
	focRow = 6
	form.reinit(globVar.screenlibID)
end

local function resetSwitchChanged(value)
	globVar.switches[3][timListIdx] = value
	system.pSave("timReset"..timListIdx.."",value)
	focRow = 3
	form.reinit(globVar.screenlibID)
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

local function imgChanged(value)
	system.pSave("imgFileName",imgFile[value])
end
-------------------------------------------------------------------- 
-- screen lib config page
--------------------------------------------------------------------

local function screenLibConfig(globVar_)
	globVar = globVar_
	local j,i = calcWinIdx(winListIdx)
	local sensor = {}
	imgFile = {}
	imgfileIdx = 0
	destroyLists()

	if(globVar.screenLib24 == 24)then
		for name in dir("Apps/AppTempl/model/img") do
			if(#name >3) then
				table.insert(imgFile,name)
				if(imgFileName == name)then
					imgfileIdx = #imgFile
				end
			end
		end
		table.insert(imgFile,"---")
		if(imgfileIdx ==0)then
			imgfileIdx = #imgFile
		end
	end	
	
	for idx in ipairs(globVar.sensors) do 
		sensor = system.getSensorByID (globVar.sensors[idx],0)
		table.insert(sensList, string.format("%s", sensor.label))
	end
	table.insert(sensList,"---")
  	if(globVar.windows[j][i][10]>0)then
		sensListIdx = globVar.windows[j][i][10] --preset sensorlist index
		if (globVar.sensParam[sensListIdx]~=nil) then
			for idx in ipairs(globVar.sensParam[sensListIdx]) do 
				sensor = system.getSensorByID (globVar.sensors[sensListIdx],globVar.sensParam[sensListIdx][idx])
				table.insert(sensPaList, string.format("%s", sensor.label))
			end
		end	
	else
		sensListIdx = #sensList
	end
	table.insert(sensPaList,"---")
	if(globVar.windows[j][i][11]>0)then
		sensPaListIdx = globVar.windows[j][i][11] --preset parameterlist index
	else
		sensPaListIdx = #sensPaList
	end
	
	form.setTitle(globVar.trans.screenLib)
	form.addRow(1)
	form.addLabel({label=globVar.trans.config,font=FONT_BOLD})

	form.addRow(1)
	form.addLabel({label=globVar.trans.bindSens,font=FONT_BOLD})
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

	if(timListIdx==0)then
		if(imgFileName ~= nil)then
			form.addRow(2)   
			form.addLabel({label="Label",width=170})
			winListBox = form.addSelectbox(winList,winListIdx,true,windowChanged)
			form.addRow(2)
			form.addLabel({label="Image",width=170})
			imgListBox = form.addSelectbox(imgFile,imgfileIdx,true,imgChanged)
		else
			if( sensPaList[1] ~=nil) then
				form.addRow(2)   
				form.addLabel({label="Label",width=170})
				winListBox = form.addSelectbox(winList,winListIdx,true,windowChanged)
				form.addRow(2)
				form.addLabel({label="Sensor",width=170})
				sensorListBox = form.addSelectbox(sensList,sensListIdx,true,sensorChanged)
				form.addRow(2)
				form.addLabel({label="SensParam",width=170})
				sensParListBox = form.addSelectbox(sensPaList,sensPaListIdx,true,sensParChanged)
			end	
		end
	else
		form.addRow(2)   
		form.addLabel({label="Label",width=170})
		winListBox = form.addSelectbox(winList,winListIdx,true,windowChanged)
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
	form.setFocusedRow (focRow)
end 

-------------------------------------------------------------------- 
-- screen lib config key eventhandler
--------------------------------------------------------------------
local function keyPressedScr(key)
    if(key==KEY_5 or key==KEY_ESC) then
	  destroyLists()
      form.preventDefault()
      form.reinit(globVar.templateAppID)
    end
end 

--------------------------------------------------------------------
local ConfigScr = {screenLibConfig,keyPressedScr,destroyLists}
return ConfigScr