--[[
	---------------------------------------------------------
	Lua App template for Geierwallys dynamic telemetry screen library
	Makes flexible display adjustments possible. Users can create her own screenfiles
	2 telemetry pages adjustable by user over data files provided.
	Dynamic hardware detection and automatically loading of 14/16 or 24 screen lib 
	---------------------------------------------------------
	V1.1.1 Initial state prepares all functionalities of the app template except telemetry 
	       Telemetry is simulated for first function tests
	---------------------------------------------------------
--]]
--Configuration
--Local variables
local appLoaded = false
local main_lib = nil  -- lua main script
local initDelay = 0
local globVar ={--                          main version | version of screenlib | version of the app (or template) 
				version = "V1.1.1", --      version of the app 1.             1.                     1
				mem = 0,--                  maximum of used storage
				debugmem = 0,--             used storage
				templateAppID = 1,--        id of template app config page
				screenlibID = 2, --         id of screenlib config page
				currentForm = nil,  --      last loaded display
				currentTime  = nil,--       current timestamp in milliseconds usefull for making own software timers
				currentDate  = nil,--       current date 
				screenLib24  = 14,--        if 24 the screen library of ds / dc 24 is loaded otherwise screen lib of the DC / DS 14 / 16
				trans = {},--               translations depending on set language
				appValues = {},--           calculated values of application
				modelType = 2,--          	stroke or electro
				model = nil, --             Model Name
				windows	= {}, --		    all telemetry windows	
				txtColor = {},--            text and frame color
				initDone = false, --        initialization of library done
				secClock = false, --        second clock for blinking text on failure
			    nCell = 1, --				number of lipo cells
				capa = 0,-- 					capacity 
				switches = {{nil,nil,nil,nil},{nil,nil,nil,nil},{nil,nil,nil,nil}}, -- start, stopp, reset switches for timers 1 - 4
				timLimits = {0,0,0,0},--    timer limits or preset values depending on count up / count down configuration
				sensors = {}, --			all sensor iDs
				sensParam = {}, --          all sensor parameter
				failWindow = 0, --          draw telemetry window with failure
				ECUType = 1, --				ECU Turbine Type
				ScrSwitch = nil --			switch between telemetry pages active , page2, otherwise page1
			   }

-------------------------------------------------------------------- 
-- 
--------------------------------------------------------------------
local function init(code)
	if(code ==1)then
		if(initDelay == 0)then
			initDelay = system.getTimeCounter()
		end	
		if(main_lib ~= nil) then
			local func = main_lib[1]
			func(0,globVar) --init(0)
		end
	end	
end

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop() 
	globVar.currentTime = system.getTimeCounter()
	 -- load current task
    if(main_lib == nil)then
		init(1)
		if((globVar.currentTime - initDelay > 5)and(initDelay ~=0)) then
			if(appLoaded == false)then
				if(globVar.sensors[1]~=nil)then
	globVar.debugmem = math.modf(collectgarbage('count'))
	print("Speicher vor Laden der ScreenLib: "..globVar.debugmem.."K")	
					main_lib = require("AppTempl/Tasks/AppMain")
					if(main_lib ~= nil)then
						appLoaded = true
						init(1)
						initDelay = 0
					end
					collectgarbage()
				else
					local memTxt = "max: "..globVar.mem.."K act: "..globVar.debugmem.."K"
					print(memTxt)
				
					local sensors_ = system.getSensors() -- read in all sensor data
					local sensPar = {}
					for k in next,globVar.sensors do globVar.sensors[k] = nil end
					for k in next,globVar.sensParam do globVar.sensParam[k] = nil end
					for idx,sensor in ipairs(sensors_) do
						if(sensor.param == 0) then
							if(sensPar[1] ~=nil)then
								table.insert(globVar.sensParam,sensPar)
								sensPar = {}
							end
							table.insert(globVar.sensors,sensor.id)
						else
							table.insert(sensPar,sensor.param)
						end
					end	
					if(sensPar[1]~=nil)then
						table.insert(globVar.sensParam,sensPar)
					end	

				end
			end	
		end	
	else
		local func = main_lib[2] --loop()
		func() -- execute main loop
	end	
	globVar.debugmem = math.modf(collectgarbage('count'))
	if (globVar.mem < globVar.debugmem) then
		globVar.mem = globVar.debugmem
		print("max Speicher Zyklus: "..globVar.mem.."K")		
	end
end
 
--------------------------------------------------------------------
return { init=init, loop=loop, author="Geierwally", version=globVar.version, name="App Template"}