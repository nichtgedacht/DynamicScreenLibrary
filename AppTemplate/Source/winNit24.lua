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
-- draw fuel 
-------------------------------------------------------------------- 
local function drawFuel()
	local telCapVal = string.format("%.1f", globVar.windows[1][1][8])
	local textCap = string.format("%.0f%%",telCapVal)
	local textwithCap = 160 - lcd.getTextWidth(FONT_BIG, textCap) / 2
	--percentage display
	lcd.drawRectangle(134, 2, 52, 28, 6)
	--lcd.drawRectangle(135, 3, 50, 26, 5)
	if(globVar.windows[1][1][9] > 0) then -- fuel cap alert
		if(globVar.secClock == true) then -- blink every second
			lcd.setColor(200,0,0)
			lcd.drawText(textwithCap,4, textCap, FONT_BIG)
		end
	else
		lcd.drawText(textwithCap,4, textCap, FONT_BIG)
	end
	lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
	-- fuel
	lcd.drawRectangle(134, 33, 26, 126)
	-- level of fuel
	if(globVar.windows[1][1][9] > 0) then -- fuel cap alert
		lcd.setColor(200,0,0) 
	else
		lcd.setColor(0,196,0)
	end
	chgH = 122 * telCapVal/100*1.02
	chgY = 159-chgH
	lcd.drawFilledRectangle(135, chgY, 24, chgH)
	lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])	
	lcd.drawLine(135, 58, 159, 58)
	lcd.drawLine(135, 83, 159, 83)
	lcd.drawLine(135, 108, 159, 108)
	lcd.drawLine(135, 133, 159, 133)
	lcd.drawText(169,35,globVar.trans.full, FONT_BIG) 
	lcd.drawText(169,137,globVar.trans.empty, FONT_BIG) 
	
	--draw gas pump
	local xO = 168
	local yO = 89
	lcd.drawRectangle(xO+2, yO+1,8,15)
	lcd.drawRectangle(xO+3, yO+1,6,14)
	lcd.drawLine(xO+3,yO, xO+8, yO)
	lcd.drawLine(xO+4,yO+5, xO+7, yO+5)
	lcd.drawLine(xO+4,yO+6, xO+7, yO+6)
	lcd.drawLine(xO,yO+15, xO+1, yO+14)
	lcd.drawLine(xO + 11,yO+15, xO+10, yO+14)
	lcd.drawLine(xO + 11,yO+9, xO+11, yO+12)
	lcd.drawLine(xO + 13,yO+4, xO+13, yO+12)
	lcd.drawLine(xO + 11,yO+2, xO+12, yO+3)
	lcd.drawLine(xO + 11,yO+5, xO+12, yO+6)
	lcd.drawPoint(xO + 0,yO+15)
	lcd.drawPoint(xO + 1,yO+15)
	lcd.drawPoint(xO + 10,yO+15)
	lcd.drawPoint(xO + 11,yO+15)
	lcd.drawPoint(xO + 11,yO+4)
	lcd.drawPoint(xO + 10,yO+8)
	lcd.drawPoint(xO + 12,yO+13)
	
	
	lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])	
    collectgarbage()
end

--------------------------------------------------------------------
local WinNit = {init,drawFuel}
return WinNit