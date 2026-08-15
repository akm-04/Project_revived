local var_0_0 = class("AppBase")

var_0_0.APP_ENTER_BACKGROUND_EVENT = "APP_ENTER_BACKGROUND_EVENT"
var_0_0.APP_ENTER_FOREGROUND_EVENT = "APP_ENTER_FOREGROUND_EVENT"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	cc(arg_1_0):addComponent("components.behavior.EventProtocol"):exportMethods()

	arg_1_0.name = arg_1_1
	arg_1_0.packageRoot = arg_1_2 or "app"

	local var_1_0 = cc.Director:getInstance():getEventDispatcher()
	local var_1_1 = cc.EventListenerCustom:create(var_0_0.APP_ENTER_BACKGROUND_EVENT, handler(arg_1_0, arg_1_0.onEnterBackground))

	var_1_0:addEventListenerWithFixedPriority(var_1_1, 1)

	local var_1_2 = cc.EventListenerCustom:create(var_0_0.APP_ENTER_FOREGROUND_EVENT, handler(arg_1_0, arg_1_0.onEnterForeground))

	var_1_0:addEventListenerWithFixedPriority(var_1_2, 1)

	arg_1_0.snapshots_ = {}
	app = arg_1_0
end

function var_0_0.run(arg_2_0)
	return
end

function var_0_0.exit(arg_3_0)
	cc.Director:getInstance():endToLua()

	if device.platform == "windows" or device.platform == "mac" then
		os.exit()
	end
end

function var_0_0.enterScene(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	local var_4_0 = arg_4_0.packageRoot .. ".scenes." .. arg_4_1
	local var_4_1 = require(var_4_0).new(unpack(checktable(arg_4_2)))

	display.replaceScene(var_4_1, arg_4_3, arg_4_4, arg_4_5)
end

function var_0_0.createView(arg_5_0, arg_5_1, ...)
	local var_5_0 = arg_5_0.packageRoot .. ".views." .. arg_5_1

	return require(var_5_0).new(...)
end

function var_0_0.onEnterBackground(arg_6_0)
	arg_6_0:dispatchEvent({
		name = var_0_0.APP_ENTER_BACKGROUND_EVENT
	})
end

function var_0_0.onEnterForeground(arg_7_0)
	arg_7_0:dispatchEvent({
		name = var_0_0.APP_ENTER_FOREGROUND_EVENT
	})
end

return var_0_0
