local var_0_0 = class("OccultStoryTalkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = 1.5
local var_0_4 = {
	Right = 2,
	Left = 1,
	None = 0
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.tableName = arg_1_2.table_name
	arg_1_0.talkId = arg_1_2.talk_id
end

function var_0_0.playFadeIn(arg_2_0)
	local var_2_0 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255))

	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:addTo(arg_2_0)
	xyd.setCascadeOpacityEnabled(var_2_0, true)

	local var_2_1 = cc.FadeTo:create(1, 0)

	var_2_0:runAction(var_2_1)
end

function var_0_0.playFadeOut(arg_3_0)
	local var_3_0 = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))

	var_3_0:setAnchorPoint(cc.p(0, 0))
	var_3_0:addTo(arg_3_0)

	local var_3_1 = cc.Sequence:create({
		cc.FadeTo:create(1, 255),
		cc.CallFunc:create(function()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end)
	})

	var_3_0:runAction(var_3_1)
end

function var_0_0.checkFileExist(arg_5_0)
	return true
end

function var_0_0.willOpen(arg_6_0, arg_6_1)
	var_0_0.super.willOpen(arg_6_0, arg_6_1)

	arg_6_0.cardContainerLeft = arg_6_0:nodeByName("card_container_left")
	arg_6_0.cardContainerRight = arg_6_0:nodeByName("card_container_right")
	arg_6_0.talkTable_ = import("app.common.tables.CreatsStoryTable").new(arg_6_0.tableName)
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

	if arg_6_0.isPlayFadeIn then
		arg_6_0:playFadeIn()
	end

	if arg_6_0:checkFileExist() then
		arg_6_0:layout()
	else
		xyd.WindowManager.get():closeWindow(arg_6_0)
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super.didOpen(arg_7_0, arg_7_1)

	if arg_7_0:checkFileExist() then
		arg_7_0:nextPlay()
	else
		xyd.WindowManager.get():closeWindow(arg_7_0)
	end
end

function var_0_0.didClose(arg_8_0, arg_8_1)
	var_0_0.super.didClose(arg_8_0, arg_8_1)

	if arg_8_0.handler then
		var_0_2.unscheduleGlobal(arg_8_0.handler)

		arg_8_0.handler = nil
	end

	if arg_8_0.awards then
		xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_8_0.awards)
	end

	if arg_8_0.callback then
		arg_8_0.callback()
	end
end

function var_0_0.playCloseWindow(arg_9_0)
	if arg_9_0.isPlayFadeOut then
		arg_9_0:playFadeOut()
	else
		xyd.WindowManager.get():closeWindow(arg_9_0)
	end
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("name_box2"):setVisible(false)
	arg_10_0:nodeByName("name_box1"):setVisible(false)
	arg_10_0:nodeByName("bottom"):setLocalZOrder(100)

	local var_10_0 = {
		size = 28,
		color = cc.c3b(15, 15, 15)
	}

	arg_10_0.message = xyd.AssetLoader.get():loadLabel(var_10_0)

	arg_10_0.message:setMaxLineWidth(900)
	arg_10_0.message:setLineBreakWithoutSpace(true)
	arg_10_0.message:addTo(arg_10_0:nodeByName("bottom"))
	arg_10_0.message:setAnchorPoint(cc.p(0, 1))
	arg_10_0.message:setPosition(cc.p(190, 155))
	arg_10_0:nodeByName("text"):setVisible(false)

	arg_10_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

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
end

function var_0_0.speak(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = xyd.utf8len(arg_12_1)

	arg_12_0.showInOneTime = false
	arg_12_0.isOnSpeaking = true

	local var_12_1 = 0

	if arg_12_0.handler then
		var_0_2.unscheduleGlobal(arg_12_0.handler)

		arg_12_0.handler = nil
	end

	arg_12_0.handler = var_0_2.scheduleGlobal(function()
		var_12_1 = var_12_1 + 1

		if var_12_1 > var_12_0 and arg_12_0.handler or arg_12_0.showInOneTime == true then
			if not tolua.isnull(arg_12_2) then
				arg_12_2:setString(arg_12_1)
			end

			var_0_2.unscheduleGlobal(arg_12_0.handler)

			arg_12_0.isOnSpeaking = false

			return
		end

		local var_13_0 = xyd.getSplitUtf8Str(arg_12_1, 0, var_12_1 * 3)

		if not tolua.isnull(arg_12_2) then
			arg_12_2:setString(var_13_0)
		end
	end, arg_12_3)
end

function var_0_0.nextPlay(arg_14_0)
	arg_14_0.playingIndex_ = arg_14_0.playingIndex_ + 1

	if arg_14_0.playingIndex_ > #arg_14_0.talkIdlist then
		arg_14_0:playCloseWindow()

		return
	end

	arg_14_0:update()
end

function var_0_0.update(arg_15_0)
	local var_15_0 = arg_15_0.talkIdlist[arg_15_0.playingIndex_]

	if arg_15_0.talkTable_:bg(var_15_0) == 1 then
		if not arg_15_0.coverBg then
			arg_15_0.coverBg = cc.LayerColor:create(cc.c4b(0, 0, 0, 255))

			arg_15_0.coverBg:addTo(arg_15_0:nodeByName("background"))
		else
			arg_15_0.coverBg:setVisible(true)
		end
	elseif arg_15_0.coverBg then
		arg_15_0.coverBg:setVisible(false)
	end

	arg_15_0:nodeByName("bottom"):setVisible(false)
	arg_15_0:updateCardContainer(var_15_0)

	local var_15_1 = arg_15_0.talkTable_:expression(var_15_0)
	local var_15_2 = xyd.tables.expression:expression(var_15_1)

	if arg_15_0.effect and not tolua.isnull(arg_15_0.effect) then
		arg_15_0.effect:removeFromParent()

		arg_15_0.effect = nil
	end

	if var_15_1 and var_15_1 > 0 and var_15_2 and var_15_2 ~= "" then
		-- block empty
	else
		arg_15_0:playSpeak(var_15_0)
	end
end

function var_0_0.onEffectEnded(arg_16_0)
	local var_16_0 = arg_16_0.talkIdlist[arg_16_0.playingIndex_]

	arg_16_0.isPlayEffect = false

	arg_16_0:playSpeak(var_16_0)
end

function var_0_0.playSpeak(arg_17_0, arg_17_1)
	arg_17_0:updateTalkBox(arg_17_1)

	local var_17_0 = xyd.tables.misc.dialogSpeed

	arg_17_0:speak(arg_17_0.talkTable_:dialog(arg_17_1), arg_17_0.message, var_17_0)
end

function var_0_0.updateTalkBox(arg_18_0, arg_18_1)
	arg_18_0.message:setString("")

	if arg_18_0.talkTable_:position(arg_18_1) == var_0_4.Left then
		arg_18_0:nodeByName("name_box2"):setVisible(false)
		arg_18_0:nodeByName("label_name2"):setVisible(false)
		arg_18_0:nodeByName("name_box1"):setVisible(true)
		arg_18_0:nodeByName("label_name1"):setVisible(true)
		arg_18_0:nodeByName("label_name1"):setString(arg_18_0:getName(arg_18_1))
	elseif arg_18_0.talkTable_:position(arg_18_1) == var_0_4.Right then
		arg_18_0:nodeByName("name_box2"):setVisible(true)
		arg_18_0:nodeByName("label_name2"):setVisible(true)
		arg_18_0:nodeByName("name_box1"):setVisible(false)
		arg_18_0:nodeByName("label_name1"):setVisible(false)
		arg_18_0:nodeByName("label_name2"):setString(arg_18_0:getName(arg_18_1))
	else
		arg_18_0:nodeByName("name_box2"):setVisible(false)
		arg_18_0:nodeByName("label_name2"):setVisible(false)
		arg_18_0:nodeByName("name_box1"):setVisible(false)
		arg_18_0:nodeByName("label_name1"):setVisible(false)
	end

	arg_18_0:nodeByName("bottom"):setVisible(true)
end

function var_0_0.getName(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0.talkTable_:name(arg_19_1)

	if var_19_0:find("=playername=") then
		var_19_0 = arg_19_0:getPlayerName()
	end

	return var_19_0
end

function var_0_0.getPlayerName(arg_20_0)
	local var_20_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_20_0.playerName or #var_20_0.playerName == 0 then
		return " "
	end

	return var_20_0.playerName
end

function var_0_0.updateCardContainer(arg_21_0, arg_21_1)
	if arg_21_0.talkTable_:position(arg_21_1) == var_0_4.Left then
		arg_21_0.cardContainerLeft:setLocalZOrder(10)
		arg_21_0.cardContainerRight:setLocalZOrder(0)
	else
		arg_21_0.cardContainerLeft:setLocalZOrder(0)
		arg_21_0.cardContainerRight:setLocalZOrder(10)
	end

	local var_21_0 = arg_21_0.talkTable_:leftImg(arg_21_1)

	if var_21_0 ~= arg_21_0.talkTable_:leftImg(arg_21_1 - 1) or arg_21_0.talkTable_:position(arg_21_1) ~= arg_21_0.talkTable_:position(arg_21_1 - 1) then
		if arg_21_0.cardContainerLeft:getChildByName("left_sprite") and not tolua.isnull(arg_21_0.cardContainerLeft:getChildByName("left_sprite")) then
			arg_21_0.cardContainerLeft:removeChildByName("left_sprite")
		end

		if var_21_0 and var_21_0 > 0 then
			local var_21_1 = xyd.SpriteLoader.new("images/home_card/" .. var_21_0 .. ".png", nil, nil, xyd.DefaultImageType.HOME_CARD)

			if not var_21_1 then
				return
			end

			if arg_21_0.talkTable_:position(arg_21_1) ~= var_0_4.Left then
				arg_21_0:gray(var_21_1)
			end

			arg_21_0.cardContainerLeft:addChild(var_21_1)
			var_21_1:setName("left_sprite")
			var_21_1:setAnchorPoint(cc.p(0.5, 0))
			var_21_1:setPosition(cc.p(arg_21_0.cardContainerLeft:getContentSize().width / 2, 0))
			var_21_1:setTouchEnabled(false)
		end
	end

	local var_21_2 = arg_21_0.talkTable_:rightImg(arg_21_1)

	if var_21_2 ~= arg_21_0.talkTable_:rightImg(arg_21_1 - 1) or arg_21_0.talkTable_:position(arg_21_1) ~= arg_21_0.talkTable_:position(arg_21_1 - 1) then
		if arg_21_0.cardContainerRight:getChildByName("right_sprite") and not tolua.isnull(arg_21_0.cardContainerRight:getChildByName("right_sprite")) then
			arg_21_0.cardContainerRight:removeChildByName("right_sprite")
		end

		if var_21_2 and var_21_2 > 0 then
			local var_21_3 = xyd.SpriteLoader.new("images/home_card/" .. var_21_2 .. ".png", nil, nil, xyd.DefaultImageType.HOME_CARD)

			if not var_21_3 then
				return
			end

			if arg_21_0.talkTable_:position(arg_21_1) ~= var_0_4.Right then
				arg_21_0:gray(var_21_3)
			end

			arg_21_0.cardContainerRight:addChild(var_21_3)
			var_21_3:setName("right_sprite")
			var_21_3:setAnchorPoint(cc.p(0.5, 0))
			var_21_3:setPosition(cc.p(arg_21_0.cardContainerRight:getContentSize().width / 2, 0))
			var_21_3:setTouchEnabled(false)
		end
	end

	if var_21_0 > 0 and var_21_2 == 0 then
		arg_21_0.cardContainerLeft:setPosition(arg_21_0:nodeByName("middle_pos"):getPosition())
	elseif var_21_2 > 0 and var_21_0 == 0 then
		arg_21_0.cardContainerRight:setPosition(arg_21_0:nodeByName("middle_pos"):getPosition())
	else
		arg_21_0.cardContainerLeft:setPosition(arg_21_0:nodeByName("left_pos"):getPosition())
		arg_21_0.cardContainerRight:setPosition(arg_21_0:nodeByName("right_pos"):getPosition())
	end
end

function var_0_0.gray(arg_22_0, arg_22_1)
	local var_22_0 = cc.TintTo:create(0, 70, 70, 70)

	arg_22_1:runActionOnce(var_22_0)
end

return var_0_0
