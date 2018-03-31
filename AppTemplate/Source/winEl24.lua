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
		local telCapVal = string.format("%.1f", globVar.windows[1][1][8])
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
				if(globVar.windows[1][1][9] > 0)then --cap alert
					lcd.setColor(200,0,0)
				end	
				lcd.drawText(textwithCap,4, textCap, FONT_BIG)
			else
				if(globVar.windows[1][2][9] > 0)then -- voltage alert
					lcd.setColor(200,0,0)
				end	
				lcd.drawText(textwithVolt,4,textVolt,FONT_BIG)
			end
		else
			lcd.drawText(textwithCap,4, textCap, FONT_BIG)
		end
		lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
		-- Battery
		lcd.drawFilledRectangle(148, 33, 24, 7)	-- Top of Battery
		lcd.drawRectangle(134, 40, 52, 118)
		-- Level of Battery
		if((globVar.windows[1][1][9] > 0)or(globVar.windows[1][2][9] > 0)) then -- cap alert or voltage alert
			lcd.setColor(200,0,0) 
		else
			lcd.setColor(0,196,0)
		end
		chgH = 114 * telCapVal/100*1.02
		chgY = 158-chgH
		lcd.drawFilledRectangle(135, chgY, 50, chgH)
	
		lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])	
		lcd.drawText(textwithVolt,135,textVolt,FONT_BIG)
		lcd.drawRectangle(134, 40, 52, 118) -- frame of battery
		lcd.drawRectangle(134, 2, 52, 28, 6) --frame of percentage display
		collectgarbage()
	end	
end

--------------------------------------------------------------------
local WinEl = {init,drawBattery}
return WinEl