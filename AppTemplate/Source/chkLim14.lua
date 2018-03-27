local globVar = {}

local function init (globVar_)
	globVar = globVar_
end

local function handleTimers(j,i)
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

	if(1==system.getInputsVal(reset))then
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
	if(1==system.getInputsVal(stopp))then
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
				system.playBeep(1,4000,500) -- timer elapsedplay beep
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
-------------------------------------------------------------------- 
-- limit checks
-------------------------------------------------------------------- 
local function checkLimit(window)
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
local chkLim14 = {init,handleTimers,checkLimit}
return chkLim14