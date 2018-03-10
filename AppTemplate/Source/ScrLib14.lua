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

	if(1==system.getInputsVal(reset)or (reset_==1))then
		if(globVar.windows[j][i][7] ==0)then -- is timer switched off
			globVar.windows[j][i][8] = preStart[globVar.windows[j][i][3]] --preset start value in ms
			system.pSave("timer"..timerID.."",globVar.windows[j][i][8]) -- save timer value on reset
		end	
	else	
		if((1==system.getInputsVal(start))and (globVar.windows[j][i][7] == 0))then
			if (globVar.windows[j][i][3] %2 ==0)then --count down timer
				globVar.windows[j][i][6] =  globVar.currentTime - (preStart[globVar.windows[j][i][3]] - globVar.windows[j][i][8])--preset start time
			else
				globVar.windows[j][i][6] = globVar.currentTime - globVar.windows[j][i][8]--preset start time
			end	
			globVar.windows[j][i][7] = 1 --switch timer active
			timeDif =0
		end
	end
	if(1==system.getInputsVal(stopp))then
		system.pSave("timer"..timerID.."",globVar.windows[j][i][8]) -- save timer value on stopp
		globVar.windows[j][i][7] = 0 --switch timer off
	end
	
	local countDownTime = 100
	
	if(globVar.windows[j][i][7] == 1) then --timer is running
		if (globVar.windows[j][i][3] %2 ==0)then --count down timer
			globVar.windows[j][i][8] = preStart[globVar.windows[j][i][3]] - timeDif
			countDownTime = math.modf((globVar.windows[j][i][8]/1000) + 1)
		else									 --count up timer
			globVar.windows[j][i][8] = timeDif
			countDownTime = math.modf((preLim[globVar.windows[j][i][3]]-globVar.windows[j][i][8])/1000)
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
				system.playBeep(1,4000,500) -- timer elapsedplay beep
				prevCountDownTime = countDownTime
			end	
		end
	else
		globVar.windows[j][i][9] = 0--reset alert
	end	
	
	
	globVar.windows[j][i][14] = nil
	local sign = " "
	if(globVar.windows[j][i][8]<0)then
		sign = nil
		sign = "-"
	end
	if (globVar.windows[j][i][3]<3)then		--hour:min:sec
		local temp = globVar.windows[j][i][8] / 3600000
		timeHour,temp = math.modf(temp)
		temp = temp *60
		timeMin,temp = math.modf(temp)	
		temp = temp *60
		timesec = math.modf(temp)
		globVar.windows[j][i][14] = string.format( "%s%02d:%02d:%02d",sign,math.abs(timeHour),math.abs(timeMin),math.abs(timesec) ) 
	else									--min:sec:sec/10
		timeMin,temp = math.modf(globVar.windows[j][i][8]/60000)
		temp = temp * 60
		timesec, temp = math.modf(temp)
		temp = temp * 100
		timeMs = math.modf(temp) 
		globVar.windows[j][i][14] = string.format( "%s%02d:%02d:%02d", sign,math.abs(timeMin),math.abs(timesec),math.abs(timeMs) ) 
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
	elseif(globVar.windows[1][1][1]==2) then -- stroke
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
		globVar.windows[j][i][8]= system.pLoad("timer"..timerID.."",-1) -- preset timer value of window
		if(globVar.windows[j][i][8]==-1)then -- reset timer if value was not stored
			handleTimers(j,i,1)
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
					system.playBeep(1,4000,500)
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
					system.playBeep(1,4000,500)
					system.playNumber (window[8], 2,window[3],window[2]) --audio output of value, unit and label
					window[9]=2 --alert audio played
				end	
			end	
		end	
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
	local txtyoffs = {{57,2,16,FONT_MAXI},{57,2,16,FONT_BIG,39},{28,13,3,FONT_BIG},{41,2,16,FONT_BOLD,0},{41,6,2,FONT_BOLD,19},{156,6,2,FONT_BOLD,20},{57}} --{hight y for summary |start label text y|start value text y|Font| start text min max oder offsetText}
	if(mainWin_Lib~=nil)then
		local func = mainWin_Lib[2]  --draw main window 
		func() 
	end
	for i in ipairs(globVar.windows[winNr]) do --draw all configured telemetry windows
		local window = globVar.windows[winNr][i]
		if(((window[1]>3)and(window[13]==1))or(window[1]<=3)or (window[1]==7))then -- draw frame
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
			lcd.drawRectangle(nextXoffs, nextYoffs, 130, txtyoffs[window[1]][1],6) 
			if((window[9]>0)and(globVar.secClock == true))then --failure display red
				if(window[1]<4)then
					lcd.drawFilledRectangle(nextXoffs+1, nextYoffs+1, 128, txtyoffs[window[1]][1]-2,125)
					lcd.setColor(255,255,255) -- failure white font color
				end	
	        end
			prepNextYoffs = nextYoffs+txtyoffs[window[1]][1]+1 --calculate next y offset
			win457Yoffs = 0
			win45Xoffs = 0
		end	
		if(window[1]==7)then
		-- nothing to do  (image for the 24 transmitters)
		else
			local corVal = lcd.getTextHeight(txtyoffs[window[1]][4]) * 0.1
			labelYoffs = txtyoffs[window[1]][3] + lcd.getTextHeight(txtyoffs[window[1]][4])-lcd.getTextHeight(FONT_MINI) - corVal
			local valTxt =nil
			if(window[4]>29)then
				valTxt = window[14] -- draw text
			else
				valTxt = string.format("%."..math.modf(window[7]).."f",window[8])-- set telemetry value window[8] with precission of window[7]
			end
print("debug_1", valTxt)
			labelXoffs = lcd.getTextWidth(txtyoffs[window[1]][4],valTxt)+2 -- add x width of value
			if(window[4]<31)then
print("debug_2", window[3])
				labelXoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[3])+2-- add x width of unit except timer window
			end	
			if(window[1]<3)then 
			    --draw center label for window types 1,2 
print("debug_3", window[2])
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
print("debug_4", window[14])
					labelXoffs = 2*(labelXoffs + lcd.getTextWidth(FONT_MINI,window[14]))+2 -- add x width of label 2 for left label and multiply with 2 for 2 values in x
				end
				--draw center label for window 4
				if(window[1]==4)then 
print("debug_5", window[2])
					lcd.drawText(nextXoffs+63 - lcd.getTextWidth(FONT_MINI,window[2])/2,nextYoffs + txtyoffs[window[1]][2],window[2],FONT_MINI)
				else
print("debug_6", window[2])
					labelXoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[2])+2 -- add x width of label 1 for left label
				end	

				labelXoffs =63 - labelXoffs/2									  -- calculate center	
				--draw left label 1 
				if(window[1]~=4)then
					if(window[1]==6)then --only window type 6, draw label left
						lcd.drawText(nextXoffs+3,nextYoffs + labelYoffs + win457Yoffs,window[2] ,FONT_MINI) 
					else
						lcd.drawText(nextXoffs+labelXoffs,nextYoffs + labelYoffs + win457Yoffs,window[2] ,FONT_MINI) 
					end	
print("debug_7", window[2])
					labelXoffs = labelXoffs+lcd.getTextWidth(FONT_MINI,window[2])+2
				end	
				if((window[9]>0)and(window[1]>3))then --failure display red
					if(globVar.secClock == true)then
						lcd.setColor(0,0,0) -- failure black font color blinking
					else
						local bgr,bgg,bgb = lcd.getBgColor()
						lcd.setColor(255,255,255) -- back ground color as font color blinking
					end
				end	
				if((window[1] == 4)or(window[1]==5))then 
					if(window[13]%2 ==0) then
						labelXoffs = win45Xoffs
					end	
				--draw label 2 for window type 4 and 5		
					lcd.drawText(nextXoffs+labelXoffs,nextYoffs + labelYoffs + win457Yoffs,window[14] ,FONT_MINI) 
print("debug_8", window[14])
					labelXoffs = labelXoffs+lcd.getTextWidth(FONT_MINI,window[14])+2
				end
			end
			--draw value
			lcd.drawText(nextXoffs + labelXoffs,nextYoffs + txtyoffs[window[1]][3]+ win457Yoffs,valTxt,txtyoffs[window[1]][4])
print("debug_9", valTxt)
			labelXoffs = labelXoffs + lcd.getTextWidth(txtyoffs[window[1]][4],valTxt)+2
			--draw unit except timer window
			if(window[4]<31)then
				lcd.drawText(nextXoffs + labelXoffs,nextYoffs + labelYoffs+ win457Yoffs,window[3],FONT_MINI)
			end	
			if((window[1] == 4)or(window[1]==5))then 
				if(window[13]%2 > 0) then
print("debug_10", window[3])
					win45Xoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[3])+2 -- store x offset for next values in same line for window type 5 and 6
				end	
			end		
			if(window[1]== 2) then
			--draw min max values
				local minMaxTxt = string.format("min:%."..math.modf(window[7]).."f max:%."..math.modf(window[7]).."f",window[13],window[14])
print("debug_11", minMaxTxt)
				lcd.drawText(nextXoffs + 63 - lcd.getTextWidth(FONT_MINI,minMaxTxt)/2,nextYoffs + txtyoffs[window[1]][5],minMaxTxt,FONT_MINI)
			end
		end	
		lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
	end	
end

local function printTelemetry() 
	lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
	drawWindow(2) --draw first telemetry window
end		

local function printTelemetry2() 
	lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
	drawWindow(3) --draw second telemetry window
end	

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop()
	if(globVar.initDone == true) then
		system.registerTelemetry(1," "..globVar.model.." Scr1",4,printTelemetry)
		if(#globVar.windows == 3)then
			system.registerTelemetry(2," "..globVar.model.." Scr2",4,printTelemetry2)
		else
			system.unregisterTelemetry(2)
		end
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
					elseif(globVar.windows[j][i][4]>30)then -- value is one of the timers
						handleTimers(j,i,0)
					else                                 -- value from application
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
					checkLimit(globVar.windows[j][i],j)
				end	
			end
		end
		if(aPrepare == false)then
			aTimeRunning = 0 --no alert in preparation, reset running alert delay
		end
	end	
end
--------------------------------------------------------------------
local ScreenLib = {init,loop}
return ScreenLib

