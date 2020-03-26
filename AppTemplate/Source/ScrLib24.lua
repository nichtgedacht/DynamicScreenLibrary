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
local prevCountDownTime = 100 -- for count down timer
local allertSet = false 
local timExpired = false
local modImage = nil
local prevInputVal = 0
local drWin = 2
local prevFailWindow = 0
local prevECUStat = 0
local maintTimerOn = 0 -- if 1 maintanance timer is running, otherwise not running
local remainingFuelDone = false

local function unloadMainWin()
	print("unloadMainWin")
	system.unregisterTelemetry(1)
	if(mainWin_Lib ~= nil)then
		package.loaded[lib_Path]=nil
		_G[lib_Path]=nil
		mainWin_Lib = nil
		lib_Path = nil
		collectgarbage('collect')
	end	
end
-------------------------------------------------------------------- 
-- Init function
-------------------------------------------------------------------- 
local function handleTimers(j,i,reset_)
	if(globVar.timLimits[globVar.windows[j][i][4]-30]>0)then
		globVar.windows[j][i][5] = globVar.timLimits[globVar.windows[j][i][4]-30]
	end
	local timerID = globVar.windows[j][i][4]-30
	local timVal = globVar.windows[j][i][4]
	local start = globVar.switches[1][timerID]
	local stopp = globVar.switches[2][timerID]
	local reset = globVar.switches[3][timerID]
	local preStart = {0,globVar.windows[j][i][5] * 60000,0,globVar.windows[j][i][5] * 1000} -- for preset start values
	local preLim = {globVar.windows[j][i][5] * 60000,0,globVar.windows[j][i][5] * 1000,0} -- for comparing limits
	local timeDif = globVar.currentTime - globVar.windows[j][i][6]
	local timeHour = 0
	local timeMin = 0	
	local timesec = 0
	local timeMs = 0
	local temp = 0

	if(start == nil)then
		globVar.windows[j][i][8] = nil
		globVar.windows[j][i][8] = "---"
	else
		if(1==system.getInputsVal(reset)or (reset_==1))then
			if(globVar.windows[j][i][7] ==0)then -- is timer switched off
				globVar.windows[j][i][10] = preStart[globVar.windows[j][i][3]] --preset start value in ms
				system.pSave("timer"..timerID.."",globVar.windows[j][i][10]) -- save timer value on reset
			end	
		else	
			if((1==system.getInputsVal(start))and (globVar.windows[j][i][7] == 0))then
				if (globVar.windows[j][i][3] %2 ==0)then --count down timer
					globVar.windows[j][i][6] =  globVar.currentTime - (preStart[globVar.windows[j][i][3]] - globVar.windows[j][i][10])--preset start time
				else
					globVar.windows[j][i][6] = globVar.currentTime - globVar.windows[j][i][10]--preset start time
				end	
				globVar.windows[j][i][7] = 1 --switch timer active
				timeDif =0
			end
		end
		if((1==system.getInputsVal(stopp))or((stopp == nil) and (1~=system.getInputsVal(start))))then
			system.pSave("timer"..timerID.."",globVar.windows[j][i][10]) -- save timer value on stopp
			globVar.windows[j][i][7] = 0 --switch timer off
		end
		local countDownTime = 100
	
		if(globVar.windows[j][i][7] == 1) then --timer is running
			if (globVar.windows[j][i][3] %2 ==0)then --count down timer
				globVar.windows[j][i][10] = preStart[globVar.windows[j][i][3]] - timeDif
				countDownTime = math.modf((globVar.windows[j][i][10]/1000) + 1)
			else									 --count up timer
				globVar.windows[j][i][10] = timeDif
				countDownTime = math.modf((preLim[globVar.windows[j][i][3]]-globVar.windows[j][i][10])/1000)
			end
		end

		if((countDownTime <11)and(countDownTime ~= prevCountDownTime))then
			if(countDownTime > 0)then
				if (system.isPlayback () == false) then
					system.playNumber(countDownTime,0) --audio remaining flight time
					prevCountDownTime = countDownTime
				end			
			else	
				globVar.windows[j][i][9] = 1--set alert active
				if((countDownTime % 10 ==0)or(countDownTime == 0))then	 
					system.vibration (true,2)  -- timer elapsedplay vibration
					prevCountDownTime = countDownTime
				end	
			end
		else
			globVar.windows[j][i][9] = 0--reset alert
		end	
	
		if(countDownTime <=0)then
			globVar.failWindow = j
			timExpired = true
		end
	
		globVar.windows[j][i][8] = nil
		local sign = " "
		if(globVar.windows[j][i][10]<0)then
			sign = nil
			sign = "-"
		end
		if (globVar.windows[j][i][3]<3)then		--hour:min:sec
			local temp = globVar.windows[j][i][10] / 3600000
			timeHour,temp = math.modf(temp)
			temp = temp *60
			timeMin,temp = math.modf(temp)	
			temp = temp *60
			timesec = math.modf(temp)
			globVar.windows[j][i][8] = string.format( "%s%02d:%02d:%02d",sign,math.abs(timeHour),math.abs(timeMin),math.abs(timesec) ) 
		else									--min:sec:sec/10
			timeMin,temp = math.modf(globVar.windows[j][i][10]/60000)
			temp = temp * 60
			timesec, temp = math.modf(temp)
			temp = temp * 100
			timeMs = math.modf(temp) 
			globVar.windows[j][i][8] = string.format( "%s%02d:%02d:%02d", sign,math.abs(timeMin),math.abs(timesec),math.abs(timeMs) ) 
		end	
	end
end

local function handleMaintenanceTimer()
	if(1 == maintTimerOn) then

		local timeVal = globVar.currentTime - globVar.maintenStartTime + globVar.maintenTimer -- count maintanance timer value 
		local timehour = timeVal / 3600000
		local temp = 0
		timehour,temp = math.modf(timehour) -- maintanance timer in hours
		--check maintenance limits 
		if((0 < globVar.mainten[1])and(0 == timehour % globVar.mainten[1])and(0 == (globVar.maintenSet & 0x01)))then -- limit 1 reached and maintenSet not active
			globVar.maintenSet = globVar.maintenSet | 0x01
			system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
		elseif((0 < globVar.mainten[2])and(0 == timehour % globVar.mainten[2])and(0 == (globVar.maintenSet & 0x02)))then -- limit 2 reached and maintenSet not active
			globVar.maintenSet = globVar.maintenSet | 0x02
			system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
		elseif((0 < globVar.mainten[3])and(0 == timehour % globVar.mainten[3])and(0 == (globVar.maintenSet & 0x04)))then -- limit 3 reached and maintenSet not active
			globVar.maintenSet = globVar.maintenSet | 0x04
			system.pSave("MaintenanceSet",globVar.maintenSet) -- save maintanance necessary set value
		end

	end
	if(1==system.getInputsVal(globVar.maintCountSwitch)) then -- is switch Maintanance Timer active?
		if(0 == maintTimerOn)then
			globVar.maintenStartTime = globVar.currentTime -- preset maintenance start time
		end
		maintTimerOn = 1
	else
		if(1 == maintTimerOn)then
		    globVar.maintenTimer = globVar.currentTime - globVar.maintenStartTime + globVar.maintenTimer
			system.pSave("MaintenanceTimer",globVar.maintenTimer) -- save maintanance timer value
			globVar.maintenStartTime = 0	 -- reset maintenance start time
		end
		maintTimerOn = 0
	end
end


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
	elseif(globVar.windows[1][1][1]==4) then -- glider
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
			handleTimers(j,i,1)
		end
	end
end

local function init(globVar_)
	globVar = globVar_
	loadmainWindow()
	local bgr,bgg,bgb = lcd.getBgColor() -- set frame and text color depending on back ground color
	if (bgr+bgg+bgb)/3 >128 then
		globVar.txtColor = {0,0,0} 
	else
		globVar.txtColor = {255,255,255}
	end
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
	prevInputVal = system.getInputsVal(globVar.ScrSwitch)

	globVar.initDone = true
end

-------------------------------------------------------------------- 
-- limit checks
-------------------------------------------------------------------- 
local function checkLimit(window,mainIndex)
	local compareLogic = false
	if(((window[4]>29)and(window[4]<35))or(window[6]==window[5]))then
		return --no check tel val is text or alert is switched off
	end
	if(window[6]>window[5])then
		compareLogic = true
	end

	if ((((window[8] <= window[5])and compareLogic == true)or((window[8] >= window[5])and compareLogic == false)) and(window[9]==0)) then --value <= compare value and no alert
		aPrepare = true
		if(aTimeRunning == 0) then
			aDelay = globVar.currentTime + 2000
			aTimeRunning = 1
		else
			if(aDelay <= globVar.currentTime)then -- set alert after 4 sec
				window[9]=1 --set alert active
				if (system.isPlayback () == false) then
					system.vibration (true,2)
					system.playNumber (window[8], 2,window[3], window[2]) --audio output of value and unit
					window[9]=2 --alert audio played
				end	
			end
		end
	else
		if(window[9]>0) then-- alert is active 
			if(((window[8] >= window[6])and (compareLogic==true))or ((window[8] <= window[6])and (compareLogic==false))) then --value in range , reset alert
				window[9] = 0
			else
				if ((system.isPlayback () == false)and(window[9]==1)) then
					system.vibration (true,2)
					system.playNumber (window[8], 2,window[3],window[2]) --audio output of value, unit and label
					window[9]=2 --alert audio played
				end	
			end	
		end
	end
end

-------------------------------------------------------------------- 
-- Audio output remaining gasoline
-------------------------------------------------------------------- 
local function audioRemainGas()
	if((globVar.capa - globVar.appValues[11]>1)and (globVar.appValues[11] % globVar.capIncrease ==0) )then
		if ((system.isPlayback () == false)and (remainingFuelDone ==false)) then
			system.playNumber (globVar.appValues[11], 2,"ml","Capacity") --audio output of value, unit and label
			remainingFuelDone = true -- audio output was done
		end	
	else
		remainingFuelDone = false -- reset audio output done 
	end
end	



-------------------------------------------------------------------- 
-- Draw the telemetry windows
-------------------------------------------------------------------- 
local function drawWindow(winNr)
	local nextYoffs = 2     -- calculating Y offsets for window draw
	local nextXoffs = 2     -- calculating X offsets for window draw
	local win45Xoffs = 0	-- X offset for window type 4 and 5  (two values in one line)
	local win457Yoffs = 0   -- Y offset for windwo type 4, 5 and 7 (more lines in one window)
	local prepNextYoffs = 2
	local labelXoffs = 2
	local labelYoffs = 2
	local txtyoffs = {{57,2,16,FONT_MAXI},{57,2,16,FONT_BIG,39},{28,13,3,FONT_BIG},{41,2,16,FONT_BOLD,0},{41,6,2,FONT_BOLD,19},{156,6,2,FONT_BOLD,20},{57},{116}} --{hight y for summary |start label text y|start value text y|Font| start text min max oder offsetText}
	if(mainWin_Lib~=nil)then
		local func = mainWin_Lib[2]  --draw main window 
		func() 
	end
	for i in ipairs(globVar.windows[winNr]) do --draw all configured telemetry windows
		local window = globVar.windows[winNr][i]
		if(winNr > 1)then
			if(((window[1]>3)and(window[13]==1))or(window[1]<=3)or (window[1]==7)or (window[1]==8))then -- draw frame
				nextYoffs = prepNextYoffs
				if(160 - nextYoffs < txtyoffs[window[1]][1] ) then --not enough place for configured window
					if(nextXoffs ==2)then
						nextXoffs = 188
						nextYoffs = 2
					else
						system.messageBox ("Data file format failure",10)
						return
					end	
				end
				labelXoffs = 2
				if((window[9]>0)and(globVar.secClock == true))then --failure display red
					lcd.setColor(200,0,0) -- failure red rectangle color
					if(window[1]<4)then
						lcd.drawFilledRectangle(nextXoffs+1, nextYoffs+1, 128, txtyoffs[window[1]][1]-2)
						lcd.setColor(255,255,255) -- failure white font color
					end	
				end
				prepNextYoffs = nextYoffs+txtyoffs[window[1]][1]+1 --calculate next y offset
				win457Yoffs = 0
				win45Xoffs = 0
			end	
			if((window[1]==7)or(window[1]==8))then
				if(modImage~=nil)then
					local imageX = nextXoffs+65 - modImage.width/2
					local imageY = nextYoffs + txtyoffs[window[1]][1]/2 - modImage.height/2
					lcd.drawImage (imageX, imageY,modImage)
				else
					local imgFileName = system.pLoad("imgFileName","---")
					modImage = lcd.loadImage("Apps/AppTempl/model/img/"..imgFileName.."")
				end
			else
				local corVal = lcd.getTextHeight(txtyoffs[window[1]][4]) * 0.1
				labelYoffs = txtyoffs[window[1]][3] + lcd.getTextHeight(txtyoffs[window[1]][4])-lcd.getTextHeight(FONT_MINI) - corVal
				local valTxt =nil
				local ltype1 =nil
				local ltype2 =nil
				if(window[4]>29)then
					valTxt = window[8] -- draw text
				else
					ltype1 = type(window[8])
					ltype2 = type(window[7])
					if(ltype1=="number" and ltype2=="number")then
						valTxt = string.format("%."..math.modf(window[7]).."f",window[8])-- set telemetry value window[8] with precission of window[7]
					else
						valTxt = "---"
					-- print(window[8], ltype1)
					end
				end
				if(window[4]==35)then -- text window for turbine data texttype is font bolt
					if(window[1]==1)then
						txtyoffs[window[1]][4] = FONT_BIG
					else
						txtyoffs[window[1]][4] = FONT_BOLD
					end
				end
				labelXoffs = lcd.getTextWidth(txtyoffs[window[1]][4],valTxt)+2 -- add x width of value

				if(window[4]<31)then
					labelXoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[3])+2-- add x width of unit except timer window
				end	
				if(window[1]<3)then 
					--draw center label for window types 1,2 
					lcd.drawText(nextXoffs+63 - lcd.getTextWidth(FONT_MINI,window[2])/2,nextYoffs + txtyoffs[window[1]][2],window[2],FONT_MINI)
					labelXoffs =63 - labelXoffs/2				
				else
					if(window[1]>4) then -- calculate next Y text position for window types 4,5 and 6
						if(window[1]==5)then
							if(window[13]>2)then
								win457Yoffs = txtyoffs[window[1]][5]
							else
								win457Yoffs = 0	
							end
						else
							win457Yoffs = (window[13]-1) * txtyoffs[window[1]][5]
						end	
					end
					if((window[1] == 4)or(window[1]==5))then -- add x width of label 2 for window types 4 and 5
						labelXoffs = 2*(labelXoffs + lcd.getTextWidth(FONT_MINI,window[14]))+2 -- add x width of label 2 for left label and multiply with 2 for 2 values in x
					end
					--draw center label for window 4
					if(window[1]==4)then 
						lcd.drawText(nextXoffs+63 - lcd.getTextWidth(FONT_MINI,window[2])/2,nextYoffs + txtyoffs[window[1]][2],window[2],FONT_MINI)
					else
						labelXoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[2])+2 -- add x width of label 1 for left label
					end	

					labelXoffs =63 - labelXoffs/2									  -- calculate center	
					--draw left label 1 
					if(window[1]~=4)then
						if(window[1]==6)then --only window type 6, draw label left
							lcd.drawText(nextXoffs+3,nextYoffs + labelYoffs + win457Yoffs,window[2] ,FONT_MINI) 
						else
							if((window[1]==5)and(window[13]%2==0))then --draw label of window 5 only once
							else
								lcd.drawText(nextXoffs+labelXoffs,nextYoffs + labelYoffs + win457Yoffs,window[2] ,FONT_MINI) 
							end	
						end	
						labelXoffs = labelXoffs+lcd.getTextWidth(FONT_MINI,window[2])+2
					end	
					if((window[9]>0)and(window[1]>3))then --failure display red
						if(globVar.secClock == true)then
							lcd.setColor(200,0,0) -- failure red font color blinking
						else
							local bgr,bgg,bgb = lcd.getBgColor()
							lcd.setColor(bgr,bgg,bgb) -- back ground color as font color blinking
						end
					end	
					if((window[1] == 4)or(window[1]==5))then 
						if(window[13]%2 ==0) then
							labelXoffs = win45Xoffs
						end	
					--draw label 2 for window type 4 and 5		
						lcd.drawText(nextXoffs+labelXoffs,nextYoffs + labelYoffs + win457Yoffs,window[14] ,FONT_MINI) 
						labelXoffs = labelXoffs+lcd.getTextWidth(FONT_MINI,window[14])+2
					end
				end
				--draw value
				lcd.drawText(nextXoffs + labelXoffs,nextYoffs + txtyoffs[window[1]][3]+ win457Yoffs,valTxt,txtyoffs[window[1]][4])
				labelXoffs = labelXoffs + lcd.getTextWidth(txtyoffs[window[1]][4],valTxt)+2
				--draw unit except timer window
				if(window[4]<31)then
					lcd.drawText(nextXoffs + labelXoffs,nextYoffs + labelYoffs+ win457Yoffs,window[3],FONT_MINI)
				end	
				if((window[1] == 4)or(window[1]==5))then 
					if(window[13]%2 > 0) then
						win45Xoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[3])+2 -- store x offset for next values in same line for window type 5 and 6
					end	
				end		
				if(window[1]== 2) then
				--draw min max values
					local minMaxTxt = string.format("min:%."..math.modf(window[7]).."f max:%."..math.modf(window[7]).."f",window[13],window[14])
					lcd.drawText(nextXoffs + 63 - lcd.getTextWidth(FONT_MINI,minMaxTxt)/2,nextYoffs + txtyoffs[window[1]][5],minMaxTxt,FONT_MINI)
				end
			end	
			lcd.drawRectangle(nextXoffs, nextYoffs, 130, txtyoffs[window[1]][1],6) 
			lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
		end
	end	
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
		if(globVar.failWindow >1)then
			drWin = globVar.failWindow
		end	
	end
	drawWindow(drWin)
end		
--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop()
	if(globVar.initDone == true) then
		allertSet = false
		timExpired = false
		system.registerTelemetry(1," "..globVar.model.." Scr1",4,printTelemetry)
		aPrepare = false
		local sensor = {}
		local sensID = nil
		local sensPar = nil
		local inputVal = system.getInputsVal(globVar.LockAlertSwitch)

		for j in ipairs(globVar.windows)do
			for i in ipairs(globVar.windows[j]) do --check limits of main window
				if(globVar.windows[j][i][1]==2)then -- reset screen min max values
					globVar.windows[j][i][13]=0 
					globVar.windows[j][i][14]=0
				end					
				if((globVar.windows[j][i][4]>30)and(globVar.windows[j][i][4]<35))then -- value is one of the timers
					handleTimers(j,i,0)
				else	
					sensID = globVar.windows[j][i][10]
					sensPar = globVar.windows[j][i][11] 
					if((sensID >0)and (sensPar >0))then
						if(globVar.windows[j][i][4]>0) then 
							if(globVar.windows[j][i][4]==30)then -- value is GPS Coordinate
								sensor = {}
								if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
									sensor = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])
									if(sensor and sensor.valid and sensor.type ==9) then
										globVar.windows[j][i][8] = nil -- reset screen value
										local nesw = {"N", "E", "S", "W"}
										globVar.windows[j][i][3] = nil
										globVar.windows[j][i][3] = nesw[sensor.decimals+1]
										local minutes = (sensor.valGPS & 0xFFFF) * 0.001
										local degs = (sensor.valGPS >> 16) & 0xFF
										globVar.windows[j][i][8] = string.format("%d° %.3f'",degs,minutes)
									end
								end
							elseif((globVar.windows[j][i][4]==35)and(globVar.windows[1][1][1]==3))then --reserved for turbine status	
								if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
									sensor = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])
									if(sensor)then
										if(sensor.value <0)then
											globVar.windows[j][i][9] = 1 --set turbine alert
										else
											globVar.windows[j][i][9] = 0 --reset turbine alert
										end
										globVar.windows[j][i][8] = nil
										if(globVar.ECUStat ~= nil)then
											if(#globVar.ECUStat >= sensor.value) then
												local ECUStat_ =  math.modf(sensor.value)
												if (prevECUStat~= ECUStat_)then
												    if (system.isPlayback () == false) then --audio turbine state
														prevECUStat = ECUStat_
														if(system.getLocale()=="de")then
															system.playFile("Apps/AppTempl/model/ECU_Data/Audio/de/"..globVar.ECUType.."/"..ECUStat_..".wav",AUDIO_QUEUE)
														else
															system.playFile("Apps/AppTempl/model/ECU_Data/Audio/en/"..globVar.ECUType.."/"..ECUStat_..".wav",AUDIO_QUEUE)
														end
													end		
												end
												globVar.windows[j][i][8] = globVar.ECUStat[""..ECUStat_..""]
											end
										end	
									end	
								end	
							else 					-- value from application
								globVar.windows[j][i][8] = nil
								globVar.windows[j][i][8] = globVar.appValues[globVar.windows[j][i][4]] --set app value 
							end	
						else				-- value from telemetry sensor
							sensor = {}
							globVar.windows[j][i][8] = nil
							globVar.windows[j][i][8] = 0 -- reset screen value
							if((globVar.sensors[sensID]~=nil)and(globVar.sensParam[sensID][sensPar] ~=nil)) then
								sensor = system.getSensorByID (globVar.sensors[sensID],globVar.sensParam[sensID][sensPar])
							end
							if(sensor and sensor.valid) then
								globVar.windows[j][i][8] = nil
								globVar.windows[j][i][8] = sensor.value --set sensor value
								if(globVar.windows[j][i][1]==2)then -- store min max values
									globVar.windows[j][i][13]=sensor.min
									globVar.windows[j][i][14]=sensor.max
								end
							end
						end

						if((sensor and sensor.valid)or(type(globVar.appValues[globVar.windows[j][i][4]])=="number")) then
							if((inputVal ~= nil)and(inputVal ~= 1))then -- is output alert locked?
								local ltype = type(globVar.windows[j][i][8])
								if (ltype == "number")then
									checkLimit(globVar.windows[j][i],j)
								else
									--print("limit check failed frame",j,i)
								end
						    end
						end
					else
						globVar.windows[j][i][8] = nil
						globVar.windows[j][i][8] = "---"
					end
				end
				if(globVar.windows[j][i][9]>0)then
					globVar.failWindow = j
					allertSet = true
				end	
			end
		end
		handleMaintenanceTimer()
		if((inputVal ~= nil)and(inputVal ~= 1))then -- is output alert and audio output locked?
			audioRemainGas()
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

return {

	init = init,
	loop = loop,
	unloadMainWin = unloadMainWin

}	


