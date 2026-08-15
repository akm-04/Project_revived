RecallStoryTalkWindow = class("RecallStoryTalkWindow", import("app.common.ui.BaseWindow"))

local var_0_0 = import("app.common.ui.SpineEffect")
local var_0_1 = import("framework.scheduler")
local var_0_2 = 1.5
local var_0_3 = {
	Right = 2,
	Left = 1,
	None = 0
}

function RecallStoryTalkWindow.ctor(arg_1_0, arg_1_1, arg_1_2)
	RecallStoryTalkWindow.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.talkId = 1001
end

function RecallStoryTalkWindow.playFadeIn(arg_2_0)
	arg_2_0:nodeByName("expression_left_bg"):setVisible(false)
	arg_2_0:nodeByName("expression_right_bg"):setVisible(false)

	local var_2_0 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255))

	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:addTo(arg_2_0)
	xyd.setCascadeOpacityEnabled(var_2_0, true)

	local var_2_1 = cc.FadeTo:create(1, 0)

	var_2_0:runAction(var_2_1)
end

function RecallStoryTalkWindow.playFadeOut(arg_3_0)
	local var_3_0 = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))

	var_3_0:setAnchorPoint(cc.p(0, 0))
	var_3_0:addTo(arg_3_0)

	local var_3_1 = cc.Sequence:create({
		cc.FadeTo:create(1, 255),
		cc.CallFunc:create(function()
			display.replaceScene(xyd.MainScene.new())
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end)
	})

	var_3_0:runAction(var_3_1)
end

function RecallStoryTalkWindow.checkFileExist(arg_5_0)
	return true
end

function RecallStoryTalkWindow.willOpen(arg_6_0, arg_6_1)
	RecallStoryTalkWindow.super.willOpen(arg_6_0, arg_6_1)

	arg_6_0.cardContainerLeft = arg_6_0:nodeByName("card_container_left")
	arg_6_0.cardContainerRight = arg_6_0:nodeByName("card_container_right")
	arg_6_0.cardContainerLeft.orgPos = cc.p(arg_6_0.cardContainerLeft:getPosition())
	arg_6_0.cardContainerRight.orgPos = cc.p(arg_6_0.cardContainerRight:getPosition())
	arg_6_0.talkTable_ = import("app.common.tables.RecallStoryTable").new(arg_6_0.talkId)
	arg_6_0.talkIdlist = arg_6_0.talkTable_:ids()
	arg_6_0.playingIndex_ = 0

	if arg_6_1 then
		if arg_6_1.callback then
			arg_6_0.callback = arg_6_1.callback
		end

		if arg_6_1.awards then
			arg_6_0.awards = arg_6_1.awards
		end

		arg_6_0.isPlayFadeOut = arg_6_1.is_play_fadeout
		arg_6_0.isPlayFadeIn = arg_6_1.is_play_fadein
	end

	if arg_6_0:checkFileExist() then
		arg_6_0:layout()
	else
		xyd.WindowManager.get():closeWindow(arg_6_0)
	end
end

function RecallStoryTalkWindow.didOpen(arg_7_0, arg_7_1)
	RecallStoryTalkWindow.super.didOpen(arg_7_0, arg_7_1)

	if arg_7_0:checkFileExist() then
		arg_7_0:nextPlay()
	else
		xyd.WindowManager.get():closeWindow(arg_7_0)
	end
end

function RecallStoryTalkWindow.didClose(arg_8_0, arg_8_1)
	RecallStoryTalkWindow.super.didClose(arg_8_0, arg_8_1)

	if arg_8_0.handler then
		var_0_1.unscheduleGlobal(arg_8_0.handler)

		arg_8_0.handler = nil
	end

	if arg_8_0.awards then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_8_0.awards)
	end

	if arg_8_0.callback then
		arg_8_0.callback()
	end
end

function RecallStoryTalkWindow.playCloseWindow(arg_9_0)
	if arg_9_0.isPlayFadeOut then
		arg_9_0:playFadeOut()
	else
		display.replaceScene(xyd.MainScene.new())
		xyd.WindowManager.get():closeWindow(arg_9_0)
	end
end

function RecallStoryTalkWindow.layout(arg_10_0)
	arg_10_0:nodeByName("box1"):setVisible(false)
	arg_10_0:nodeByName("name_box2"):setVisible(false)
	arg_10_0:nodeByName("box2"):setVisible(false)
	arg_10_0:nodeByName("name_box1"):setVisible(false)
	arg_10_0:nodeByName("bottom"):setLocalZOrder(100)
	arg_10_0:nodeByName("close"):setLocalZOrder(100)
	arg_10_0:nodeByName("expression_left_bg"):setLocalZOrder(20)
	arg_10_0:nodeByName("expression_right_bg"):setLocalZOrder(20)

	local var_10_0 = {
		size = 32,
		color = cc.c3b(255, 255, 255)
	}

	arg_10_0.message = xyd.AssetLoader.get():loadLabel(var_10_0)

	arg_10_0.message:setMaxLineWidth(900)
	arg_10_0.message:setLineBreakWithoutSpace(true)
	arg_10_0.message:addTo(arg_10_0:nodeByName("bottom"))
	arg_10_0.message:setAnchorPoint(cc.p(0, 1))
	arg_10_0.message:setPosition(cc.p(190, 130))
	arg_10_0:nodeByName("text"):setVisible(false)

	local var_10_1 = display.newNode()

	var_10_1:setName("role")
	var_10_1:size(arg_10_0:getContentSize())
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_1:setPosition(cc.p(0, 0))
	var_10_1:addTo(arg_10_0, -1)

	arg_10_0.roleLayer_ = var_10_1

	arg_10_0:setTouchSwallowEnabled(false)

	arg_10_0.touchLayer_ = var_10_1:clone()

	arg_10_0.touchLayer_:addTo(arg_10_0)
	arg_10_0.touchLayer_:setTouchEnabled(true)
	arg_10_0.touchLayer_:setTouchSwallowEnabled(true)
	arg_10_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "ended" then
			if arg_10_0.isOnSpeaking then
				arg_10_0.showInOneTime = true
			elseif arg_10_0.isPlayEffect then
				if arg_10_0.effect and not tolua.isnull(arg_10_0.effect) then
					arg_10_0.effect:stop()
				end

				arg_10_0:onEffectEnded()
			else
				arg_10_0:nextPlay()
			end
		end

		return true
	end)
	arg_10_0:nodeByName("close"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_12_0, false)
			arg_10_0:playCloseWindow()
		end
	end)
end

function RecallStoryTalkWindow.speak(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = xyd.utf8len(arg_13_1)

	arg_13_0.showInOneTime = false
	arg_13_0.isOnSpeaking = true

	local var_13_1 = 0

	if arg_13_0.handler then
		var_0_1.unscheduleGlobal(arg_13_0.handler)

		arg_13_0.handler = nil
	end

	arg_13_0.handler = var_0_1.scheduleGlobal(function()
		var_13_1 = var_13_1 + 1

		if var_13_1 > var_13_0 and arg_13_0.handler or arg_13_0.showInOneTime == true then
			if not tolua.isnull(arg_13_2) then
				arg_13_2:setString(arg_13_1)
			end

			var_0_1.unscheduleGlobal(arg_13_0.handler)

			arg_13_0.isOnSpeaking = false

			return
		end

		local var_14_0 = xyd.getSplitUtf8Str(arg_13_1, 0, var_13_1 * 3)

		if not tolua.isnull(arg_13_2) then
			arg_13_2:setString(var_14_0)
		end
	end, arg_13_3)
end

function RecallStoryTalkWindow.nextPlay(arg_15_0)
	arg_15_0.playingIndex_ = arg_15_0.playingIndex_ + 1

	if arg_15_0.playingIndex_ > #arg_15_0.talkIdlist then
		arg_15_0:playCloseWindow()

		return
	end

	arg_15_0:update()
end

function RecallStoryTalkWindow.update(arg_16_0)
	local var_16_0 = arg_16_0.talkIdlist[arg_16_0.playingIndex_]

	arg_16_0:nodeByName("bottom"):setVisible(false)
	arg_16_0:updateCardContainer(var_16_0)
	arg_16_0:nodeByName("expression_left_bg"):setVisible(false)
	arg_16_0:nodeByName("expression_right_bg"):setVisible(false)
	arg_16_0:nodeByName("expression_left_bg"):removeAllChildren(true)
	arg_16_0:nodeByName("expression_right_bg"):removeAllChildren(true)

	local var_16_1 = arg_16_0.talkTable_:expression(var_16_0)
	local var_16_2 = xyd.tables.expression:expression(var_16_1)
	local var_16_3

	if arg_16_0.talkTable_:position(var_16_0) == var_0_3.Left then
		var_16_3 = arg_16_0:nodeByName("expression_left_bg")
	else
		var_16_3 = arg_16_0:nodeByName("expression_right_bg")
	end

	if arg_16_0.effect and not tolua.isnull(arg_16_0.effect) then
		arg_16_0.effect:removeFromParent()

		arg_16_0.effect = nil
	end

	if var_16_1 and var_16_1 > 0 and var_16_2 and var_16_2 ~= "" then
		var_16_3:setVisible(true)

		local var_16_4 = var_16_2 .. ".json"
		local var_16_5 = var_16_2 .. ".atlas"

		arg_16_0.effect = var_0_0.new(var_16_4, var_16_5, 1)

		arg_16_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_16_0.effect:addTo(var_16_3)
		arg_16_0.effect:setPosition(cc.p(var_16_3:getContentSize().width / 2, var_16_3:getContentSize().height / 2))
		arg_16_0.effect:setName("effect")

		arg_16_0.isPlayEffect = true

		arg_16_0.effect:play(function()
			arg_16_0:onEffectEnded()
		end, false)
	else
		arg_16_0:playSpeak(var_16_0)
	end
end

function RecallStoryTalkWindow.onEffectEnded(arg_18_0)
	local var_18_0 = arg_18_0.talkIdlist[arg_18_0.playingIndex_]

	arg_18_0.isPlayEffect = false

	if arg_18_0.talkTable_:position(var_18_0) == var_0_3.Left then
		parent = arg_18_0:nodeByName("expression_left_bg")
	else
		parent = arg_18_0:nodeByName("expression_right_bg")
	end

	arg_18_0:playSpeak(var_18_0)
	parent:setVisible(false)
end

function RecallStoryTalkWindow.playSpeak(arg_19_0, arg_19_1)
	arg_19_0:updateTalkBox(arg_19_1)

	local var_19_0 = xyd.tables.misc.dialogSpeed

	arg_19_0:speak(arg_19_0.talkTable_:dialog(arg_19_1), arg_19_0.message, var_19_0)
end

function RecallStoryTalkWindow.updateTalkBox(arg_20_0, arg_20_1)
	arg_20_0.message:setString("")

	if arg_20_0.talkTable_:position(arg_20_1) == var_0_3.Left then
		arg_20_0:nodeByName("box1"):setVisible(false)
		arg_20_0:nodeByName("name_box2"):setVisible(false)
		arg_20_0:nodeByName("label_name2"):setVisible(false)
		arg_20_0:nodeByName("box2"):setVisible(true)
		arg_20_0:nodeByName("name_box1"):setVisible(true)
		arg_20_0:nodeByName("label_name1"):setVisible(true)
		arg_20_0:nodeByName("label_name1"):setString(arg_20_0:getName(arg_20_1))
	elseif arg_20_0.talkTable_:position(arg_20_1) == var_0_3.Right then
		arg_20_0:nodeByName("box1"):setVisible(true)
		arg_20_0:nodeByName("name_box2"):setVisible(true)
		arg_20_0:nodeByName("label_name2"):setVisible(true)
		arg_20_0:nodeByName("box2"):setVisible(false)
		arg_20_0:nodeByName("name_box1"):setVisible(false)
		arg_20_0:nodeByName("label_name1"):setVisible(false)
		arg_20_0:nodeByName("label_name2"):setString(arg_20_0:getName(arg_20_1))
	else
		arg_20_0:nodeByName("box1"):setVisible(false)
		arg_20_0:nodeByName("name_box2"):setVisible(false)
		arg_20_0:nodeByName("label_name2"):setVisible(false)
		arg_20_0:nodeByName("box2"):setVisible(true)
		arg_20_0:nodeByName("name_box1"):setVisible(false)
		arg_20_0:nodeByName("label_name1"):setVisible(false)
	end

	arg_20_0:nodeByName("bottom"):setVisible(true)
end

function RecallStoryTalkWindow.getName(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_0.talkTable_:name(arg_21_1)

	if var_21_0:find("=playername=") then
		var_21_0 = arg_21_0:getPlayerName()
	end

	return var_21_0
end

function RecallStoryTalkWindow.getPlayerName(arg_22_0)
	local var_22_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_22_0.playerName or #var_22_0.playerName == 0 then
		return " "
	end

	return var_22_0.playerName
end

function RecallStoryTalkWindow.updateCardContainer(arg_23_0, arg_23_1)
	if arg_23_0.talkTable_:position(arg_23_1) == var_0_3.Left then
		arg_23_0.cardContainerLeft:setLocalZOrder(10)
		arg_23_0.cardContainerRight:setLocalZOrder(0)
	else
		arg_23_0.cardContainerLeft:setLocalZOrder(0)
		arg_23_0.cardContainerRight:setLocalZOrder(10)
	end

	transition.stopTarget(arg_23_0.cardContainerLeft)
	transition.stopTarget(arg_23_0.cardContainerRight)
	arg_23_0.cardContainerLeft:setPosition(arg_23_0.cardContainerLeft.orgPos)
	arg_23_0.cardContainerRight:setPosition(arg_23_0.cardContainerRight.orgPos)

	local var_23_0 = arg_23_0.talkTable_:lImg(arg_23_1)

	if var_23_0 ~= arg_23_0.talkTable_:lImg(arg_23_1 - 1) or arg_23_0.talkTable_:position(arg_23_1) ~= arg_23_0.talkTable_:position(arg_23_1 - 1) then
		if arg_23_0.cardContainerLeft:getChildByName("left_sprite") and not tolua.isnull(arg_23_0.cardContainerLeft:getChildByName("left_sprite")) then
			arg_23_0.cardContainerLeft:removeChildByName("left_sprite")
		end

		if var_23_0 and var_23_0 > 0 then
			local var_23_1 = xyd.SpriteLoader.new("images/home_card/" .. var_23_0 .. ".png", nil, extra_params, xyd.DefaultImageType.HOME_CARD)

			if not var_23_1 then
				return
			end

			if arg_23_0.talkTable_:position(arg_23_1) ~= var_0_3.Left then
				arg_23_0:gray(var_23_1)
			end

			arg_23_0.cardContainerLeft:addChild(var_23_1)
			var_23_1:setName("left_sprite")
			var_23_1:setAnchorPoint(cc.p(0.5, 0))
			var_23_1:setPosition(cc.p(arg_23_0.cardContainerLeft:getContentSize().width / 2, 0))
			var_23_1:setTouchEnabled(false)
		end
	end

	local var_23_2 = arg_23_0.talkTable_:rImg(arg_23_1)

	if var_23_2 ~= arg_23_0.talkTable_:rImg(arg_23_1 - 1) or arg_23_0.talkTable_:position(arg_23_1) ~= arg_23_0.talkTable_:position(arg_23_1 - 1) then
		if arg_23_0.cardContainerRight:getChildByName("right_sprite") and not tolua.isnull(arg_23_0.cardContainerRight:getChildByName("right_sprite")) then
			arg_23_0.cardContainerRight:removeChildByName("right_sprite")
		end

		if var_23_2 and var_23_2 > 0 then
			local var_23_3 = xyd.SpriteLoader.new("images/home_card/" .. var_23_2 .. ".png", nil, nil, xyd.DefaultImageType.HOME_CARD)

			if not var_23_3 then
				return
			end

			if arg_23_0.talkTable_:position(arg_23_1) ~= var_0_3.Right then
				arg_23_0:gray(var_23_3)
			end

			arg_23_0.cardContainerRight:addChild(var_23_3)
			var_23_3:setName("right_sprite")
			var_23_3:setAnchorPoint(cc.p(0.5, 0))
			var_23_3:setPosition(cc.p(arg_23_0.cardContainerRight:getContentSize().width / 2, 0))
			var_23_3:setTouchEnabled(false)
		end
	end

	if var_23_0 > 0 and var_23_2 == 0 then
		arg_23_0.cardContainerLeft:setPosition(arg_23_0:nodeByName("middle_pos"):getPosition())
	elseif var_23_2 > 0 and var_23_0 == 0 then
		arg_23_0.cardContainerRight:setPosition(arg_23_0:nodeByName("middle_pos"):getPosition())
	else
		arg_23_0.cardContainerLeft:setPosition(arg_23_0:nodeByName("left_pos"):getPosition())
		arg_23_0.cardContainerRight:setPosition(arg_23_0:nodeByName("right_pos"):getPosition())
	end

	local var_23_4 = arg_23_0.talkTable_:movement(arg_23_1)
	local var_23_5 = arg_23_0.talkTable_:position(arg_23_1)
	local var_23_6

	if var_23_5 == 1 then
		var_23_6 = arg_23_0.cardContainerLeft
	elseif var_23_5 == 2 then
		var_23_6 = arg_23_0.cardContainerRight
	end

	if var_23_6 then
		if var_23_4 == 1 then
			local var_23_7 = xyd.Shake:create(1, 2)

			var_23_6:runAction(var_23_7)
		elseif var_23_4 == 2 then
			local var_23_8 = cc.p(var_23_6:getPosition())

			if var_23_5 == 2 then
				var_23_6:setPositionX(1620)
			else
				var_23_6:setPositionX(-340)
			end

			local var_23_9 = cc.JumpTo:create(0.9, var_23_6.orgPos, 100, 3)

			var_23_6:runAction(var_23_9)
		end
	end
end

function RecallStoryTalkWindow.gray(arg_24_0, arg_24_1)
	local var_24_0 = cc.TintTo:create(0, 70, 70, 70)

	arg_24_1:runActionOnce(var_24_0)
end

return RecallStoryTalkWindow
