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
				sensorLalist = {},--   list of all telemetry sensor labels  
                sensorIdlist = {},--   list of all telemetry sensor id's
                sensorPalist = {},--   list of all sensor parameters
				currentTime  = nil,--       current timestamp in milliseconds usefull for making own software timers
				currentDate  = nil,--       current date 
				screenLib24  = 14,--        if 24 the screen library of ds / dc 24 is loaded otherwise screen lib of the DC / DS 14 / 16
				trans = {},--               translations depending on set language
				sensors = {},--             list of all sensors for each screen area 2 sensors possible
				appValues = {},--           calculated values of application
				modelType = 2,--          	stroke or electro
				model = nil, --             Model Name
				windows	= {}, --		    all telemetry windows	
				txtColor = {},--            text and frame color
				initDone = false, --         initialization of library done
				secClock = false --         second clock for blinking text on failure
			   }

-------------------------------------------------------------------- 
-- Initialization
--------------------------------------------------------------------
local function init(code)
	if(initDelay == 0)then
		initDelay = system.getTimeCounter()
	end	
	if(main_lib ~= nil) then
		local func = main_lib[1]
		func(0,globVar) --init(0)
	end
end

--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop() 
	globVar.currentTime = system.getTimeCounter()
	 -- load current task
    if(main_lib == nil)then
		init(0)
		if((globVar.currentTime - initDelay > 5000)and(initDelay ~=0)) then
			if(appLoaded == false)then
				local memTxt = "max: "..globVar.mem.."K act: "..globVar.debugmem.."K"
				print(memTxt)
				main_lib = require("AppTempl/Tasks/AppMain")
				if(main_lib ~= nil)then
					appLoaded = true
					init(0)
					initDelay = 0
				end
				collectgarbage()
			end
		end
	else
		local func = main_lib[2] --loop()
		func() -- execute main loop
	end	
	globVar.debugmem = math.modf(collectgarbage('count'))
	if (globVar.mem < globVar.debugmem) then
		globVar.mem = globVar.debugmem
	end
end
 
--------------------------------------------------------------------
return { init=init, loop=loop, author="Geierwally", version=globVar.version, name="App Template"}