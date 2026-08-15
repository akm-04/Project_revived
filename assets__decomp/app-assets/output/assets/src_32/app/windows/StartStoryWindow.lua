local var_0_0 = class("StartStoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.loadingTip
local var_0_3 = xyd.tables.translation
local var_0_4 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	xyd.EventDispatcher.get():addEventListener(cc.mvc.AppBase.APP_ENTER_BACKGROUND_EVENT, handler(arg_2_0, arg_2_0.enter_bg_))
	xyd.EventDispatcher.get():addEventListener(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_2_0, arg_2_0.enter_fg_))

	arg_2_0.seekTime = 0
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:scheduleHandler()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	return
end

function var_0_0.scheduleHandler(arg_5_0)
	arg_5_0.handler = var_0_4.scheduleUpdateGlobal(handler(arg_5_0, arg_5_0.loop))
end

function var_0_0.enter_bg_(arg_6_0, arg_6_1)
	if arg_6_0.videoPlayer_ then
		arg_6_0.afterTime = os.time()

		arg_6_0.videoPlayer_:pause()
	end
end

function var_0_0.enter_fg_(arg_7_0, arg_7_1)
	if arg_7_0.videoPlayer_ then
		if arg_7_0.afterTime and arg_7_0.preTime then
			arg_7_0.seekTime = arg_7_0.afterTime - arg_7_0.preTime + arg_7_0.seekTime
		end

		arg_7_0.videoPlayer_:seekTo(arg_7_0.seekTime)
		arg_7_0:play()
	end
end

function var_0_0.loop(arg_8_0)
	if arg_8_0.background_ == nil then
		arg_8_0.background_ = xyd.AssetLoader.get():loadSprite("images/startup.png")

		arg_8_0.background_:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_8_0, -1)
	end

	arg_8_0:nodeByName("text_tip"):setString(arg_8_0:getTip())
	arg_8_0:nodeByName("text_loading"):setString(var_0_3:translation("BATTLE_LOADING"))

	arg_8_0.count = arg_8_0.count or 0

	if arg_8_0.count < 1 then
		arg_8_0.count = arg_8_0.count + 1

		if not arg_8_0 or tolua.isnull(arg_8_0) then
			return
		end

		local var_8_0 = arg_8_0:nodeByName("effect_container")

		if not arg_8_0.effect_ then
			local var_8_1 = "skeletons/ui_effect/battle_loading/battle_loading"
			local var_8_2 = var_8_1 .. ".json"
			local var_8_3 = var_8_1 .. ".atlas"

			arg_8_0.effect_ = var_0_1.new(var_8_2, var_8_3, 1)

			arg_8_0.effect_:align(display.CENTER, var_8_0:getWidth() / 2, var_8_0:getHeight() / 2)
			arg_8_0.effect_:addTo(var_8_0)
		end

		arg_8_0.effect_:play(nil, true)
	elseif arg_8_0.count < 2 then
		arg_8_0.count = arg_8_0.count + 1

		arg_8_0:layout()
	elseif arg_8_0.handler ~= nil then
		var_0_4.unscheduleGlobal(arg_8_0.handler)

		arg_8_0.handler = nil
	end
end

function var_0_0.layout(arg_9_0)
	if device.platform == "ios" then
		arg_9_0:layoutIOS()
	elseif device.platform == "android" then
		arg_9_0:layoutAndroid()
	else
		arg_9_0:endPlay()
	end
end

function var_0_0.layoutAndroid(arg_10_0)
	if not ccexp.VideoPlayer then
		arg_10_0:endPlay()

		return
	end

	arg_10_0.videoPlayer_ = ccexp.VideoPlayer:create()

	if arg_10_0.videoPlayer_ == nil then
		arg_10_0:endPlay()

		return
	end

	arg_10_0.videoPlayer_:size(arg_10_0:getWidth(), arg_10_0:getHeight())

	local var_10_0 = cc.FileUtils:getInstance():fullPathForFilename(xyd.versionUpdatePath .. "res/video/start.mp4")

	if not io.exists(var_10_0) then
		var_10_0 = "res/video/start.mp4"
	end

	arg_10_0.videoPlayer_:setFileName(var_10_0)
	arg_10_0.videoPlayer_:setKeepAspectRatioEnabled(true)
	arg_10_0.videoPlayer_:setFullScreenEnabled(true)
	arg_10_0.videoPlayer_:addTo(arg_10_0:nodeByName("movie"))
	arg_10_0.videoPlayer_:align(display.CENTER, arg_10_0:getWidth() / 2, arg_10_0:getHeight() / 2)
	arg_10_0:play()
end

function var_0_0.layoutIOS(arg_11_0)
	local var_11_0 = cc.FileUtils:getInstance():fullPathForFilename(xyd.versionUpdatePath .. "res/video/start.mp4")

	if not io.exists(var_11_0) then
		var_11_0 = cc.FileUtils:getInstance():fullPathForFilename("res/video/start.mp4")
	end

	luaoc.callStaticMethod("SdkIOS", "playVideo", {
		file_path = var_11_0,
		callback = function()
			arg_11_0:endPlay()
		end
	})
end

function var_0_0.play(arg_13_0)
	local function var_13_0(arg_14_0, arg_14_1)
		if arg_14_1 == ccexp.VideoPlayerEvent.PLAYING then
			-- block empty
		elseif arg_14_1 == ccexp.VideoPlayerEvent.PAUSED then
			arg_13_0:endPlay()
		elseif arg_14_1 == ccexp.VideoPlayerEvent.STOPPED then
			arg_13_0:endPlay()
		elseif arg_14_1 == ccexp.VideoPlayerEvent.COMPLETED then
			arg_13_0:endPlay()
		end
	end

	arg_13_0.videoPlayer_:addEventListener(var_13_0)

	arg_13_0.preTime = os.time()

	arg_13_0.videoPlayer_:play()
end

function var_0_0.endPlay(arg_15_0)
	if arg_15_0.handler ~= nil then
		var_0_4.unscheduleGlobal(arg_15_0.handler)

		arg_15_0.handler = nil
	end

	xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_BEFORE_STORY)
	xyd.StoryData.get():persist()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.PLAY_GUIDE,
		params = {
			guide_id = xyd.GuideStoryType.GUIDE_START
		}
	})
	display.replaceScene(xyd.MainScene.new())
	xyd.WindowManager.get():closeWindow("start_story")
end

function var_0_0.getTip(arg_16_0)
	math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 6)))

	local var_16_0 = math.random(var_0_2:tipNum())

	arg_16_0.tipText = var_0_2:tip(var_16_0)

	return arg_16_0.tipText
end

return var_0_0
