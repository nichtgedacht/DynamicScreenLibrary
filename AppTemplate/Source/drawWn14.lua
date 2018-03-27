local globVar = {}

local function init (globVar_)
	globVar = globVar_
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
	local failColor = 0

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
					lcd.drawFilledRectangle(nextXoffs+1, nextYoffs+1, 128, txtyoffs[window[1]][1]-2)
					failColor = FONT_XOR 
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
				valTxt = window[8] -- draw text
			else
				valTxt = string.format("%."..math.modf(window[7]).."f",window[8])-- set telemetry value window[8] with precission of window[7]
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
				lcd.drawText(nextXoffs+63 - lcd.getTextWidth(FONT_MINI,window[2])/2,nextYoffs + txtyoffs[window[1]][2],window[2],FONT_MINI|failColor)
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
					lcd.drawText(nextXoffs+63 - lcd.getTextWidth(FONT_MINI,window[2])/2,nextYoffs + txtyoffs[window[1]][2],window[2],FONT_MINI|failColor)
				else
					labelXoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[2])+2 -- add x width of label 1 for left label
				end	

				labelXoffs =63 - labelXoffs/2									  -- calculate center	
				--draw left label 1 
				if(window[1]~=4)then
					if(window[1]==6)then --only window type 6, draw label left
						lcd.drawText(nextXoffs+3,nextYoffs + labelYoffs + win457Yoffs,window[2] ,FONT_MINI|failColor) 
					else
						if((window[1]==5)and(window[13]%2==0))then --draw label of window 5 only once
						else
							lcd.drawText(nextXoffs+labelXoffs,nextYoffs + labelYoffs + win457Yoffs,window[2] ,FONT_MINI|failColor)
						end	
					end	
					labelXoffs = labelXoffs+lcd.getTextWidth(FONT_MINI,window[2])+2
				end	
				if((window[9]>0)and(window[1]>3))then --failure display red
					if(globVar.secClock == true)then
						failColor = 0
					else
						failColor  = FONT_OR
					end
				end	
				if((window[1] == 4)or(window[1]==5))then 
					if(window[13]%2 ==0) then
						labelXoffs = win45Xoffs
					end	
				--draw label 2 for window type 4 and 5		
					lcd.drawText(nextXoffs+labelXoffs,nextYoffs + labelYoffs + win457Yoffs,window[14] ,FONT_MINI|failColor) 
					labelXoffs = labelXoffs+lcd.getTextWidth(FONT_MINI,window[14])+2
				end
			end
			--draw value
			lcd.drawText(nextXoffs + labelXoffs,nextYoffs + txtyoffs[window[1]][3]+ win457Yoffs,valTxt,txtyoffs[window[1]][4]|failColor)
			labelXoffs = labelXoffs + lcd.getTextWidth(txtyoffs[window[1]][4],valTxt)+2
			--draw unit except timer window
			if(window[4]<31)then
				lcd.drawText(nextXoffs + labelXoffs,nextYoffs + labelYoffs+ win457Yoffs,window[3],FONT_MINI|failColor)
			end	
			if((window[1] == 4)or(window[1]==5))then 
				if(window[13]%2 > 0) then
					win45Xoffs = labelXoffs + lcd.getTextWidth(FONT_MINI,window[3])+2 -- store x offset for next values in same line for window type 5 and 6
				end	
			end		
			if(window[1]== 2) then
			--draw min max values
				local minMaxTxt = string.format("min:%."..math.modf(window[7]).."f max:%."..math.modf(window[7]).."f",window[13],window[14])
				lcd.drawText(nextXoffs + 63 - lcd.getTextWidth(FONT_MINI,minMaxTxt)/2,nextYoffs + txtyoffs[window[1]][5],minMaxTxt,FONT_MINI|failColor)
			end
		end	
		lcd.setColor(globVar.txtColor[1],globVar.txtColor[2],globVar.txtColor[3])
	end	
end

--------------------------------------------------------------------
local drawWin14 = {init,drawWindow}
return drawWin14
