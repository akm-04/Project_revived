local var_0_0 = class("SpeakCell", function()
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
	arg_2_0.lastFunc = arg_2_1.lastFunc
	arg_2_0.nextFunc = arg_2_1.nextFunc
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

		local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/talks_container/talks_container.csb")

		arg_4_0.messageBoxContainer = var_4_0:getChildByName("container")

		arg_4_0.contentView_:setupContentView_(var_4_0)
		arg_4_0.contentView_:addTo(arg_4_0):setAnchorPoint(0.5, 0.5)
		arg_4_0.contentView_:setTouchSwallowEnabled(false)
	end

	arg_4_0:setMessageBoxVisible(false)
	arg_4_0.contentView_:setTouchEnabled(true)

	if arg_4_0.touchAreaSize and not arg_4_0.noTouch then
		if arg_4_0.lastFunc and arg_4_0.nextFunc then
			arg_4_0:addDialogForContainer2(arg_4_0.container)
		else
			arg_4_0:addDialogForContainer(arg_4_0.container)
		end
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

function var_0_0.addDialogForContainer2(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = 0

	var_7_0:setTouchEnabled(true)
	var_7_0:setContentSize(arg_7_0.touchAreaSize)
	var_7_0:addTo(arg_7_0)
	var_7_0:setPosition(arg_7_0.touchPosition)
	var_7_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			var_7_1 = arg_8_0.x

			return true
		elseif arg_8_0.name == "ended" then
			if arg_8_0.x - var_7_1 > 50 then
				arg_7_0.lastFunc()
			elseif arg_8_0.x - var_7_1 < -50 then
				arg_7_0.nextFunc()
			else
				arg_7_0:onclick()
			end
		end
	end)
	arg_7_0:removeDelay()
end

function var_0_0.npcSpeak(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_0.delay then
		arg_9_0:removeDelay()
	end

	local var_9_0 = arg_9_0.messageBoxContainer

	var_9_0:getChildByName("message_node"):removeAllChildren()

	local var_9_1 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_9_2 = xyd.AssetLoader.get():loadLabel(var_9_1)

	var_9_2:setMaxLineWidth(300)
	var_9_2:setString(arg_9_1)
	var_9_2:setAnchorPoint(cc.p(0, 0))
	var_9_2:addTo(var_9_0:getChildByName("message_node"))

	local var_9_3 = var_9_2:getContentSize().height
	local var_9_4 = var_9_2:getContentSize().width

	var_9_0:getChildByName("duihua_bg"):height((var_9_3 + 25) / 0.72)
	var_9_0:getChildByName("duihua_bg"):width(var_9_4 + 65)
	var_9_0:getChildByName("message_node"):height(var_9_3)
	var_9_0:getChildByName("message_node"):setPositionY(var_9_0:getChildByName("duihua_bg"):getPositionY() - 10)
	arg_9_0:setMessageBoxVisible(true)

	arg_9_0.delay = var_0_2.performWithDelayGlobal(function()
		if not tolua.isnull(arg_9_0) then
			arg_9_0:setMessageBoxVisible(false)
		end
	end, arg_9_2)
end

function var_0_0.removeDelay(arg_11_0)
	arg_11_0:setMessageBoxVisible(false)

	if arg_11_0.delay ~= nil then
		var_0_2.unscheduleGlobal(arg_11_0.delay)

		arg_11_0.delay = nil
	end
end

function var_0_0.setMessageBoxVisible(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.messageBoxContainer

	if arg_12_1 then
		var_12_0:getChildByName("message_node"):setVisible(true)
		var_12_0:getChildByName("duihua_bg"):setVisible(true)
	else
		var_12_0:getChildByName("message_node"):setVisible(false)
		var_12_0:getChildByName("duihua_bg"):setVisible(false)
	end
end

function var_0_0.onclick(arg_13_0)
	xyd.AssetDownload.get():preloadCharacterSound({
		arg_13_0.heroTableID
	}, function()
		local var_14_0 = xyd.WindowManager.get():getWindow("tujian_herodetail")

		if var_14_0 and var_14_0.voiceBtnHandler then
			for iter_14_0 = 1, 3 do
				var_14_0.voiceBtnContainer:getChildByName("icon" .. iter_14_0):setVisible(iter_14_0 == 3)
			end

			var_0_2.unscheduleGlobal(var_14_0.voiceBtnHandler)

			var_14_0.voiceBtnHandler = nil
		end

		if arg_13_0.msgs ~= nil and #arg_13_0.msgs > 0 then
			if arg_13_0.speakIndex == 0 then
				arg_13_0.speakIndex = math.random(#arg_13_0.msgs)
			else
				arg_13_0.speakIndex = xyd.randomIndex(arg_13_0.speakIndex, #arg_13_0.msgs)
			end

			local var_14_1 = arg_13_0.speakIndex

			arg_13_0:npcSpeak(arg_13_0.msgs[var_14_1], arg_13_0.times[var_14_1])

			if arg_13_0.sounds and arg_13_0.sounds[var_14_1] ~= "" and arg_13_0.times[var_14_1] and arg_13_0.times[var_14_1] > 0 then
				arg_13_0.selfPlayer:playHeroSound(arg_13_0.sounds[var_14_1], arg_13_0.times[var_14_1])
			end
		end
	end)
end

function var_0_0.specialDialog(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	arg_15_0:npcSpeak(arg_15_2, arg_15_3)

	if arg_15_1 ~= "" and arg_15_3 > 0 then
		arg_15_0.selfPlayer:playHeroSound(arg_15_1, arg_15_3)
	end
end

return var_0_0
