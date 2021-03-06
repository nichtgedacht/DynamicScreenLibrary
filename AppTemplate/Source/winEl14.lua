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
local globVar = nil --global variables for application and screen library

local function init(globVar_)
	globVar = globVar_
end
-------------------------------------------------------------------- 
-- draw battery 
-------------------------------------------------------------------- 
local function drawBattery()
	if((globVar.windows[1][1][8]~= "---")and (globVar.windows[1][2][8] ~= "---"))then
		local telCapVal = math.modf(globVar.windows[1][1][8] *10)/10
		local textVolt = nil
		local textCap = string.format("%.0f%%",telCapVal)
		local textwithCap = 160 - lcd.getTextWidth(FONT_BIG, textCap) / 2
		
		if(globVar.windows[1][2][8]<10)then
			textVolt = string.format("%.2fV", globVar.windows[1][2][8])
		else
			textVolt = string.format("%.1fV", globVar.windows[1][2][8])
		end
		local textwithVolt = 160 - lcd.getTextWidth(FONT_BIG, textVolt) / 2
		-- Percentage Display
		if((globVar.windows[1][1][9] > 0)or(globVar.windows[1][2][9] > 0)) then -- cap alert or voltage alert
			if(globVar.secClock == true) then -- blink every second
				lcd.drawText(textwithCap,4, textCap, FONT_BIG)
			else
				if(globVar.windows[1][2][9] >0)then -- voltage alert
					lcd.drawText(textwithVolt,4,textVolt,FONT_BIG)
				end	
			end
		else
			lcd.drawText(textwithCap,4, textCap, FONT_BIG)
		end
																		  
		-- Battery
		lcd.drawFilledRectangle(148, 33, 24, 7)	-- Top of Battery
		-- Level of Battery
		local chgH = 114 * telCapVal/100*1.02
		local chgY = 158-chgH
		if(((globVar.windows[1][1][9] >0)or(globVar.windows[1][2][9] >0))and(globVar.secClock == true)) then -- cap alert or voltage alert
			lcd.drawFilledRectangle(135, chgY, 50, chgH,125)
		else
			lcd.drawFilledRectangle(135, chgY, 50, chgH)
		end
		lcd.drawText(textwithVolt,135,textVolt,FONT_BIG|FONT_XOR)
		lcd.drawRectangle(134, 40, 52, 118) -- frame of battery
		lcd.drawRectangle(134, 2, 52, 28, 6) --frame of percentage display
		collectgarbage()
	end
end

--------------------------------------------------------------------
local WinEl = {init,drawBattery}
return WinEl