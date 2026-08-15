local var_0_0 = class("ChocolateSpeakWindow", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.container = arg_2_1.container
	arg_2_0.touchPosition = arg_2_1.touchPosition
	arg_2_0.touchAreaSize = arg_2_1.touchAreaSize
	arg_2_0.msgs = arg_2_1.msgs
	arg_2_0.sounds = arg_2_1.sounds
	arg_2_0.times = arg_2_1.times
	arg_2_0.heroTableID = arg_2_1.heroTableID
	arg_2_0.noTouch = arg_2_1.noTouch
	arg_2_0.name = arg_2_1.name
	arg_2_0.speakIndex = 0
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:contentView()
end

function var_0_0.setMsgsParams(arg_3_0, arg_3_1)
	arg_3_0.msgs = arg_3_1
end

function var_0_0.contentView(arg_4_0)
	if arg_4_0.contentView_ == nil then
		arg_4_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate/award_pools/pool/talks_container.csb")

		arg_4_0.messageBoxContainer = var_4_0:getChildByName("container")

		arg_4_0.contentView_:setupContentView_(var_4_0)
		arg_4_0.contentView_:addTo(arg_4_0):setAnchorPoint(0.5, 0.5)
		arg_4_0.contentView_:setTouchSwallowEnabled(false)
	end

	arg_4_0:setMessageBoxVisible(false)
	arg_4_0.contentView_:setTouchEnabled(true)
	arg_4_0.messageBoxContainer:getChildByName("partner"):enableOutline(cc.c4b(158, 76, 189, 255), 2)
	arg_4_0.messageBoxContainer:getChildByName("partner"):setString(arg_4_0.name)

	if arg_4_0.touchAreaSize and not arg_4_0.noTouch then
		arg_4_0:addDialogForContainer(arg_4_0.container)
	end

	return arg_4_0.contentView_
end

function var_0_0.addDialogForContainer(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()

	var_5_0:setTouchEnabled(true)
	var_5_0:setContentSize(arg_5_0.touchAreaSize)
	var_5_0:addTo(arg_5_0)
	var_5_0:setPosition(arg_5_0.touchPosition)
	var_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			arg_5_0:onclick()
		end
	end)
	arg_5_0:removeDelay()
end

function var_0_0.npcSpeak(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.delay then
		arg_7_0:removeDelay()
	end

	local var_7_0 = arg_7_0.messageBoxContainer

	var_7_0:getChildByName("message_node"):removeAllChildren()

	local var_7_1 = {
		size = 20,
		color = cc.c3b(177, 76, 202)
	}
	local var_7_2 = xyd.AssetLoader.get():loadLabel(var_7_1)

	var_7_2:setMaxLineWidth(360)
	var_7_2:setString(arg_7_1)
	var_7_2:setAnchorPoint(cc.p(0, 0))
	var_7_2:addTo(var_7_0:getChildByName("message_node"))

	local var_7_3 = var_7_2:getContentSize().height
	local var_7_4 = var_7_2:getContentSize().width

	var_7_0:getChildByName("message_node"):height(var_7_3)
	var_7_0:getChildByName("message_node"):setPositionY(var_7_0:getChildByName("message_node"):getPositionY())
	arg_7_0:setMessageBoxVisible(true)

	arg_7_0.delay = var_0_2.performWithDelayGlobal(function()
		if not tolua.isnull(arg_7_0) then
			arg_7_0:setMessageBoxVisible(false)
		end
	end, arg_7_2)
end

function var_0_0.removeDelay(arg_9_0)
	arg_9_0:setMessageBoxVisible(false)

	if arg_9_0.delay ~= nil then
		var_0_2.unscheduleGlobal(arg_9_0.delay)

		arg_9_0.delay = nil
	end
end

function var_0_0.setMessageBoxVisible(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.messageBoxContainer

	if arg_10_1 then
		var_10_0:getChildByName("message_node"):setVisible(true)
		var_10_0:getChildByName("duihua_bg"):setVisible(true)
		var_10_0:getChildByName("partner"):setVisible(true)
	else
		var_10_0:getChildByName("message_node"):setVisible(false)
		var_10_0:getChildByName("duihua_bg"):setVisible(false)
		var_10_0:getChildByName("partner"):setVisible(false)
	end
end

function var_0_0.onclick(arg_11_0)
	xyd.AssetDownload.get():preloadCharacterSound({
		arg_11_0.heroTableID
	}, function()
		local var_12_0 = xyd.WindowManager.get():getWindow("tujian_herodetail")

		if var_12_0 and var_12_0.voiceBtnHandler then
			for iter_12_0 = 1, 3 do
				var_12_0.voiceBtnContainer:getChildByName("icon" .. iter_12_0):setVisible(iter_12_0 == 3)
			end

			var_0_2.unscheduleGlobal(var_12_0.voiceBtnHandler)

			var_12_0.voiceBtnHandler = nil
		end

		if arg_11_0.msgs ~= nil and #arg_11_0.msgs > 0 then
			if arg_11_0.speakIndex == 0 then
				arg_11_0.speakIndex = math.random(#arg_11_0.msgs)
			else
				arg_11_0.speakIndex = xyd.randomIndex(arg_11_0.speakIndex, #arg_11_0.msgs)
			end

			local var_12_1 = arg_11_0.speakIndex

			arg_11_0:npcSpeak(arg_11_0.msgs[var_12_1], arg_11_0.times[var_12_1])

			if arg_11_0.sounds and arg_11_0.sounds[var_12_1] ~= "" and arg_11_0.times[var_12_1] and arg_11_0.times[var_12_1] > 0 then
				arg_11_0.selfPlayer:playHeroSound(arg_11_0.sounds[var_12_1], arg_11_0.times[var_12_1])
			end
		end
	end)
end

function var_0_0.specialDialog(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	arg_13_0:npcSpeak(arg_13_2, arg_13_3)

	if arg_13_1 ~= "" and arg_13_3 > 0 then
		arg_13_0.selfPlayer:playHeroSound(arg_13_1, arg_13_3)
	end
end

return var_0_0
