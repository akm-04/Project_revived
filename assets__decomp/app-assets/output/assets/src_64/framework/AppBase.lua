local var_0_0 = class("AppBase")

function var_0_0.ctor(arg_1_0)
	local var_1_0 = cc.Director:getInstance():getEventDispatcher()
	local var_1_1 = cc.EventListenerCustom:create("APP_ENTER_BACKGROUND_EVENT", function()
		audio.pauseAll()
		arg_1_0:onEnterBackground()
	end)

	var_1_0:addEventListenerWithFixedPriority(var_1_1, 1)

	local var_1_2 = cc.EventListenerCustom:create("APP_ENTER_FOREGROUND_EVENT", function()
		audio.resumeAll()
		arg_1_0:onEnterForeground()
	end)

	var_1_0:addEventListenerWithFixedPriority(var_1_2, 1)

	app = arg_1_0
end

function var_0_0.run(arg_4_0)
	return
end

function var_0_0.exit(arg_5_0)
	cc.Director:getInstance():endToLua()

	if device.platform == "windows" or device.platform == "mac" then
		os.exit()
	end
end

function var_0_0.enterScene(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, ...)
	local var_6_0 = "app.scenes." .. arg_6_1
	local var_6_1 = require(var_6_0).new(...)

	display.replaceScene(var_6_1, arg_6_2, arg_6_3, arg_6_4)
end

function var_0_0.createView(arg_7_0, arg_7_1, ...)
	local var_7_0 = "app.views." .. arg_7_1

	return require(var_7_0).new(...)
end

function var_0_0.onEnterBackground(arg_8_0)
	return
end

function var_0_0.onEnterForeground(arg_9_0)
	return
end

return var_0_0
