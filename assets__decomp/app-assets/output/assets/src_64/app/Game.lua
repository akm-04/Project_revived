require("config")
require("cocos.init")
require("framework.init")

local var_0_0 = require("framework.scheduler")
local var_0_1 = class("Game", cc.mvc.AppBase)
local var_0_2 = "version.json"
local var_0_3 = "__version_json_init__"

function var_0_1.version_json_init_check(arg_1_0)
	if #(cc.UserDefault:getInstance():getStringForKey(var_0_3) or "") ~= 0 then
		return
	end

	if not cc.FileUtils:getInstance():isFileExist(xyd.versionUpdatePath .. var_0_2) and not cc.FileUtils:getInstance():isFileExist(xyd.versionUpdatePath .. "src/" .. var_0_2) then
		return
	end

	return true
end

function var_0_1.ctor(arg_2_0)
	var_0_1.super.ctor(arg_2_0)
	math.randomseed(os.time())
end

function var_0_1.run(arg_3_0)
	if arg_3_0:version_json_init_check() then
		if restart_game then
			restart_game()
		else
			xyd.exitProgram()
		end

		return
	end

	require("app.xinyoudi")
	arg_3_0:registerEngineEvents_()
	arg_3_0:setupScreen_()
	cc.Director:getInstance():replaceScene(xyd.LoadingScene.new())
	cc.Device:setKeepScreenOn(true)
end

function var_0_1.onEnterBackground(arg_4_0)
	var_0_1.super.onEnterBackground(arg_4_0)
	audio.pauseAll()

	if device.platform ~= "windows" then
		cc.Director:getInstance():purgeCachedData()
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = cc.mvc.AppBase.APP_ENTER_BACKGROUND_EVENT
	})
end

function var_0_1.onEnterForeground(arg_5_0)
	var_0_1.super.onEnterForeground(arg_5_0)
	audio.resumeAll()
	xyd.EventDispatcher.get():dispatchEvent({
		name = cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT
	})
end

function var_0_1.registerEngineEvents_(arg_6_0)
	xyd.EngineNotificationCenter:get():setHandler(function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.EngineNotificationType.CRASH then
			xyd.db.errorLog:add(arg_7_1.traceback, true, arg_7_1.dump_file)
		elseif arg_7_0 == xyd.EngineNotificationType.ERROR_REPORT then
			xyd.db.errorLog:add(arg_7_1.traceback)
		elseif arg_7_0 == xyd.EngineNotificationType.LOW_MEMORY then
			cc.Director:getInstance():purgeCachedData()
		end
	end)
end

function var_0_1.setupScreen_(arg_8_0)
	local var_8_0 = cc.Director:getInstance()

	var_8_0:setDisplayStats(xyd.isDebug())
	var_8_0:setAnimationInterval(1 / xyd.tables.misc.fps)

	if xyd.isDebug() then
		-- block empty
	end

	local var_8_1 = var_8_0:getOpenGLView()
	local var_8_2 = var_8_1:getFrameSize()
	local var_8_3 = cc.ResolutionPolicy.UNKNOWN
	local var_8_4 = var_8_2.width / var_8_2.height < xyd.tables.misc.minimumResolutionRatio

	if var_8_4 then
		var_8_3 = cc.ResolutionPolicy.FIXED_WIDTH
	else
		var_8_3 = cc.ResolutionPolicy.FIXED_HEIGHT
	end

	var_8_0:setContentScaleFactor(xyd.tables.misc.contentScaleFactor)
	var_8_1:setDesignResolutionSize(xyd.tables.misc.designWidth, xyd.tables.misc.designHeight, var_8_3)

	local var_8_5 = var_8_0:getVisibleSize()

	if var_8_4 then
		var_8_5.height = xyd.tables.misc.designHeight / xyd.tables.misc.designWidth * var_8_5.width
	else
		var_8_5.width = xyd.tables.misc.designWidth / xyd.tables.misc.designHeight * var_8_5.height
	end

	var_8_5.width = xyd.tables.misc.designWidth
	xyd.STAGE_WIDTH = var_8_5.width
	xyd.STAGE_HEIGHT = var_8_5.height
	xyd.UNLIMIT_STAGE_WIDTH = xyd.STAGE_WIDTH / 0.6
	xyd.UNLIMIT_STAGE_HEIGHT = xyd.STAGE_HEIGHT / 0.6
end

_G.__old_traceback = debug.traceback

function debug.traceback(...)
	local var_9_0 = __old_traceback(...) .. "\n"
	local var_9_1 = {
		debug.getinfo(0, "nSl"),
		debug.getinfo(1, "nSl"),
		debug.getinfo(2, "nSl"),
		debug.getinfo(3, "nSl"),
		debug.getinfo(4, "nSl"),
		debug.getinfo(5, "nSl"),
		debug.getinfo(6, "nSl")
	}
	local var_9_2 = string.format("platform: %s\n", device.platform)

	for iter_9_0, iter_9_1 in ipairs(var_9_1) do
		var_9_2 = string.format("%s    LUA ERROR PATH%d: %s : %d  %s\n", var_9_2, iter_9_0 - 1, iter_9_1.source, iter_9_1.currentline, iter_9_1.name or "")
	end

	return var_9_2 .. var_9_0
end

return var_0_1
