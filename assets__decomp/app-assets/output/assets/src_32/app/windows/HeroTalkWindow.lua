HeroTalkWindow = class("HeroTalkWindow", import("app.common.ui.BaseWindow"))

local var_0_0 = import("app.common.ui.SpineEffect")
local var_0_1 = import("framework.scheduler")
local var_0_2 = 1000
local var_0_3 = 0.5

function HeroTalkWindow.ctor(arg_1_0, arg_1_1, arg_1_2)
	HeroTalkWindow.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.dialog = arg_1_2.dialog
	arg_1_0.dialogId = arg_1_0.dialog.dialog_id
	arg_1_0.extraFavor = arg_1_0.dialog.extra_favor or false
	arg_1_0.isNotShowCard = arg_1_2.isNotShowCard
end

function HeroTalkWindow.checkFileExist(arg_2_0)
	return true
end

function HeroTalkWindow.speak(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = xyd.utf8len(arg_3_1)

	arg_3_0.showInOneTime = false
	arg_3_0.isOnSpeaking = true

	local var_3_1 = 0

	if arg_3_0.handler then
		var_0_1.unscheduleGlobal(arg_3_0.handler)

		arg_3_0.handler = nil
	end

	arg_3_0.handler = var_0_1.scheduleGlobal(function()
		var_3_1 = var_3_1 + 1

		if var_3_1 > var_3_0 and arg_3_0.handler or arg_3_0.showInOneTime == true then
			if not tolua.isnull(arg_3_2) then
				arg_3_2:setString(arg_3_1)
			end

			var_0_1.unscheduleGlobal(arg_3_0.handler)

			arg_3_0.isOnSpeaking = false

			return
		end

		local var_4_0 = xyd.getSplitUtf8Str(arg_3_1, 0, var_3_1 * 3)

		if not tolua.isnull(arg_3_2) then
			arg_3_2:setString(var_4_0)
		end
	end, arg_3_3)
end

function HeroTalkWindow.willOpen(arg_5_0, arg_5_1)
	HeroTalkWindow.super.willOpen(arg_5_0, arg_5_1)

	arg_5_0.cardContainer = arg_5_0:nodeByName("card_container")
	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_5_0.bg = arg_5_0:nodeByName("bg")

	arg_5_0:setBG()

	local var_5_0 = arg_5_0.hero:getTableID()

	if arg_5_0.hero:isAwaken() then
		var_5_0 = xyd.tables.hero:beforeAwaken(var_5_0)
	end

	if arg_5_0:checkFileExist() then
		arg_5_0.dialogTable_ = import("app.common.tables.DialogueTable").new(var_5_0)
		arg_5_0.dialogIdlist = arg_5_0.dialogTable_:getIdListByIdType(arg_5_0.dialogId)
		arg_5_0.playingIndex_ = 0
	end

	if arg_5_1.callback then
		arg_5_0.callback = arg_5_1.callback
	end

	arg_5_0.isOnSpeaking = false

	if arg_5_0:checkFileExist() then
		arg_5_0:hideOtherWindows()
		arg_5_0:layout()
	else
		xyd.WindowManager.get():closeWindow(arg_5_0)
	end

	arg_5_0:nodeByName("skip"):setVisible(false)

	if arg_5_0.dialogId == 0 then
		arg_5_0:nodeByName("card_container"):setVisible(false)
	end
end

function HeroTalkWindow.setBG(arg_6_0)
	if arg_6_0.bg then
		arg_6_0.bg:removeSelf()
	end

	arg_6_0.bg = xyd.SpriteLoader.new(xyd.tables.libraryBG:getBG(arg_6_0.library.bgRoom), nil, nil, xyd.DefaultImageType.BG_ROOM)

	arg_6_0.bg:setAnchorPoint(0, 0)
	arg_6_0.bg:addTo(arg_6_0, -1)
end

function HeroTalkWindow.didOpen(arg_7_0, arg_7_1)
	HeroTalkWindow.super.didOpen(arg_7_0, arg_7_1)

	if not arg_7_0:checkFileExist() then
		xyd.WindowManager.get():closeWindow("story")
	end

	arg_7_0:nodeByName("card_container"):setOpacity(0)
	arg_7_0:nodeByName("bottom"):setOpacity(0)
	arg_7_0:nodeByName("card_container"):runAction(cc.FadeIn:create(var_0_3))
	arg_7_0:nodeByName("bottom"):runAction(cc.FadeIn:create(var_0_3))
	arg_7_0:nodeByName("bottom"):runAction(cc.Sequence:create({
		cc.FadeIn:create(var_0_3),
		cc.CallFunc:create(function()
			if arg_7_0 then
				arg_7_0:nodeByName("box2"):setVisible(true)
				arg_7_0:nodeByName("name_box1"):setVisible(true)
				arg_7_0:nextPlay()
			end
		end)
	}))
end

function HeroTalkWindow.hideOtherWindows(arg_9_0)
	local var_9_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneBottomWnd)
	local var_9_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneTopWnd)

	if var_9_1 then
		var_9_1:setVisible(false)
	end

	if var_9_0 then
		var_9_0:setVisible(false)
	end
end

function HeroTalkWindow.layout(arg_10_0)
	arg_10_0:nodeByName("box1"):setVisible(false)
	arg_10_0:nodeByName("name_box2"):setVisible(false)
	arg_10_0:nodeByName("box2"):setVisible(false)
	arg_10_0:nodeByName("name_box1"):setVisible(false)
	arg_10_0:nodeByName("expression_bg"):setVisible(false)
	arg_10_0:nodeByName("expression_bg"):setLocalZOrder(10)

	arg_10_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

	local var_10_0 = display.newNode()

	var_10_0:setName("role")
	var_10_0:size(arg_10_0:getContentSize())
	var_10_0:setAnchorPoint(cc.p(0, 0))
	var_10_0:setPosition(cc.p(0, 0))
	var_10_0:addTo(arg_10_0, -1)

	arg_10_0.roleLayer_ = var_10_0

	arg_10_0:setTouchSwallowEnabled(false)

	arg_10_0.touchLayer_ = var_10_0:clone()

	arg_10_0.touchLayer_:addTo(arg_10_0)
	arg_10_0.touchLayer_:setTouchEnabled(true)
	arg_10_0.touchLayer_:setTouchSwallowEnabled(true)
	arg_10_0.touchLayer_:setLocalZOrder(15)
	arg_10_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "ended" and not arg_10_0.shaking_ then
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
	arg_10_0:nodeByName("skip"):setTouchSwallowEnabled(true)
	arg_10_0:nodeByName("skip"):setLocalZOrder(20)
	arg_10_0:nodeByName("skip"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_12_0, false)
			xyd.WindowManager.get():closeWindow(arg_10_0)
		end
	end)

	arg_10_0.scroll = arg_10_0:nodeByName("scroll")
	arg_10_0.scrollContent = arg_10_0.scroll:getContentSize()
	arg_10_0.optionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_10_0.scrollContent.width, arg_10_0.scrollContent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_10_0.scroll):onScroll(handler(arg_10_0, arg_10_0.scrollListener))

	arg_10_0.optionList:setDelegate(handler(arg_10_0, arg_10_0.optionListDelegate))
	arg_10_0.optionList:setBounceable(false)
end

function HeroTalkWindow.optionListDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #arg_13_0.chooseIds
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		local var_13_0 = arg_13_0.optionList:dequeueItem()

		if not var_13_0 then
			var_13_0 = arg_13_0.optionList:newItem()
		else
			var_13_0:removeAllChildren(true)
		end

		local var_13_1 = arg_13_0:createListContent(arg_13_0.chooseIds[arg_13_3])
		local var_13_2 = var_13_1:getWidth()
		local var_13_3 = var_13_1:getHeight()

		var_13_0:setItemSize(var_13_2, var_13_3)
		var_13_0:addContent(var_13_1)

		return var_13_0
	end
end

function HeroTalkWindow.createListContent(arg_14_0, arg_14_1)
	local var_14_0 = display.newNode()
	local var_14_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/story/option_item.csb")
	local var_14_2 = var_14_1:getChildByName("container")

	var_14_2:getChildByName("option_txt"):setString(arg_14_0.dialogTable_:buttonChoose(arg_14_1))
	var_14_2:getChildByName("option_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = {
				partner_id = arg_14_0.hero:getHeroID(),
				dialog_id = arg_14_0.dialogId,
				select_info = arg_14_0.dialogTable_:isReward(arg_14_1) .. "|" .. arg_14_1
			}

			arg_14_0.library:getTalkAward(var_15_0, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					if arg_16_1.dialog_info then
						arg_14_0.dialog.is_awarded = arg_16_1.dialog_info.is_awarded
						arg_14_0.dialog.select_id = arg_16_1.dialog_info.select_id
					end

					if arg_16_1.favor_degree then
						arg_14_0.hero:setFavorDegree(arg_16_1.favor_degree)
					end

					if arg_16_1.awards and #arg_16_1.awards > 0 then
						arg_14_0.selfPlayer:handleRewards(arg_16_1.awards)
					end

					arg_14_0.selectOption = arg_14_1

					arg_14_0:nextPlay()
				end
			end)
		end
	end)
	var_14_0:setAnchorPoint(cc.p(0, 0))
	var_14_0:setPosition(0, 0)
	var_14_1:addTo(var_14_0)
	var_14_1:setAnchorPoint(cc.p(0, 0))
	var_14_0:setContentSize(var_14_2:getContentSize())
	var_14_1:setName("source")

	return var_14_0
end

function HeroTalkWindow.nextPlay(arg_17_0)
	if arg_17_0:getNextId() > 0 and arg_17_0.playingIndex_ ~= arg_17_0:getNextId() then
		arg_17_0.playingIndex_ = arg_17_0:getNextId()
		arg_17_0.selectOption = 0
	elseif arg_17_0:getNextId() == -1 then
		if arg_17_0.dialogTable_:isReward(arg_17_0.playingIndex_) > 0 and arg_17_0.dialog.is_awarded == 0 then
			local var_17_0 = {
				partner_id = arg_17_0.hero:getHeroID(),
				dialog_id = arg_17_0.dialogId
			}

			arg_17_0.library:getTalkAward(var_17_0, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					if arg_18_1.dialog_info then
						arg_17_0.dialog.is_awarded = arg_18_1.dialog_info.is_awarded
					end

					if arg_18_1.favor_degree then
						arg_17_0.hero:setFavorDegree(arg_18_1.favor_degree)
					end

					if arg_18_1.awards and #arg_18_1.awards > 0 then
						arg_17_0.selfPlayer:handleRewards(arg_18_1.awards)
					end

					xyd.WindowManager.get():closeWindow(arg_17_0)
				end
			end)
		else
			xyd.WindowManager.get():closeWindow(arg_17_0)
		end

		return
	else
		return
	end

	arg_17_0.chooseIds = arg_17_0.dialogTable_:turnId(arg_17_0.playingIndex_)

	if #arg_17_0.chooseIds < 2 or arg_17_0.dialog.select_id then
		arg_17_0.chooseIds = {}
	end

	arg_17_0.optionList:reload()
	arg_17_0:update()
end

function HeroTalkWindow.getNextId(arg_19_0)
	local var_19_0 = 0
	local var_19_1 = arg_19_0.dialogTable_:turnId(arg_19_0.playingIndex_)

	if arg_19_0.playingIndex_ == 0 then
		var_19_0 = arg_19_0.dialogTable_:getFirstIdByType(arg_19_0.dialogId)
	elseif arg_19_0.selectOption and arg_19_0.selectOption > 0 then
		var_19_0 = arg_19_0.selectOption
	elseif #var_19_1 == 1 then
		var_19_0 = var_19_1[1]
	elseif #var_19_1 > 1 then
		if arg_19_0.dialog.select_id then
			var_19_0 = arg_19_0.dialog.select_id
		else
			var_19_0 = arg_19_0.playingIndex_
		end
	end

	return var_19_0
end

function HeroTalkWindow.update(arg_20_0)
	local var_20_0 = arg_20_0.playingIndex_

	if arg_20_0.dialogTable_:people(var_20_0) == 1 then
		arg_20_0:nodeByName("label_name1"):setString(arg_20_0.hero:getName())
	else
		arg_20_0:nodeByName("label_name1"):setString(arg_20_0.selfPlayer.playerName)
	end

	local var_20_1 = arg_20_0.dialogTable_:getExpression(var_20_0)
	local var_20_2 = xyd.tables.expression:expression(var_20_1)
	local var_20_3 = arg_20_0:nodeByName("expression_bg")

	var_20_3:removeAllChildren()

	if arg_20_0.effect and not tolua.isnull(arg_20_0.effect) then
		arg_20_0.effect:removeFromParent()

		arg_20_0.effect = nil
	end

	if arg_20_0.extraFavor then
		local var_20_4 = "skeletons/adventure/adventure_amour_up_light"

		arg_20_0.effect2 = var_0_0.new(var_20_4 .. ".json", var_20_4 .. ".atlas", 1)

		arg_20_0.effect2:setAnchorPoint(cc.p(0.5, 0.5))
		arg_20_0.effect2:addTo(arg_20_0:nodeByName("extra_favor"))
		arg_20_0.effect2:setPosition(cc.p(0, 0))
		arg_20_0.effect2:setName("effect2")
	end

	if var_20_1 and var_20_1 > 0 and var_20_2 and var_20_2 ~= "" then
		var_20_3:setVisible(true)
		arg_20_0:nodeByName("bottom"):setVisible(false)

		local var_20_5 = var_20_2 .. ".json"
		local var_20_6 = var_20_2 .. ".atlas"

		arg_20_0.effect = var_0_0.new(var_20_5, var_20_6, 1)

		arg_20_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_20_0.effect:addTo(var_20_3)
		arg_20_0.effect:setPosition(cc.p(var_20_3:getContentSize().width / 2, var_20_3:getContentSize().height / 2))
		arg_20_0.effect:setName("effect")

		arg_20_0.isPlayEffect = true

		arg_20_0.effect:play(function()
			arg_20_0:onEffectEnded()
		end, false)
	else
		if arg_20_0.extraFavor then
			arg_20_0.effect2:play(nil, false)
		end

		arg_20_0:speak(arg_20_0.dialogTable_:getDialog(var_20_0), arg_20_0:nodeByName("text"), xyd.tables.misc.dialogSpeed)
	end

	arg_20_0:updateCardContainer()
end

function HeroTalkWindow.onEffectEnded(arg_22_0)
	local var_22_0 = arg_22_0.playingIndex_

	arg_22_0.isPlayEffect = false

	arg_22_0:nodeByName("text"):setString("")
	arg_22_0:nodeByName("bottom"):setVisible(true)

	if arg_22_0.extraFavor then
		arg_22_0.effect2:play(nil, false)
	end

	arg_22_0:speak(arg_22_0.dialogTable_:getDialog(var_22_0), arg_22_0:nodeByName("text"), xyd.tables.misc.dialogSpeed)
	arg_22_0:nodeByName("expression_bg"):setVisible(false)
end

function HeroTalkWindow.updateCardContainer(arg_23_0)
	local var_23_0 = arg_23_0.hero
	local var_23_1, var_23_2, var_23_3 = arg_23_0.library:getCardIDInfoBaseOnCardState(var_23_0, arg_23_0.library.cardState)
	local var_23_4 = xyd.getTransparentCard(var_23_0, xyd.SkinDynamicPosType.LIBRARY)

	if not var_23_4 then
		return
	end

	if arg_23_0.cardContainer:getChildByName("sprite") then
		arg_23_0.cardContainer:removeChildByName("sprite")
	end

	if arg_23_0.dialogId ~= 0 then
		arg_23_0:nodeByName("skip"):setVisible(true)
	end

	if not arg_23_0.isNotShowCard then
		arg_23_0.cardContainer:addChild(var_23_4)
		var_23_4:setName("sprite")
		var_23_4:setAnchorPoint(cc.p(0, 0))
		var_23_4:setTouchEnabled(false)
	else
		arg_23_0:nodeByName("skip"):setVisible(false)
	end

	if arg_23_0:getNextId() == -1 then
		arg_23_0:nodeByName("skip"):setVisible(false)
	end
end

function HeroTalkWindow.iconFilter(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	if not arg_24_1 or not arg_24_2 then
		return
	end

	if arg_24_3 then
		arg_24_1:hide()
		arg_24_2:hide()
	else
		arg_24_2:hide()
		arg_24_1:show()
	end
end

function HeroTalkWindow.gray(arg_25_0, arg_25_1)
	local var_25_0 = cc.TintBy:create(0, 200, 200, 200)

	arg_25_1:runActionOnce(var_25_0)
end

function HeroTalkWindow.didClose(arg_26_0, arg_26_1)
	HeroTalkWindow.super.didClose(arg_26_0, arg_26_1)

	if arg_26_0.handler then
		var_0_1.unscheduleGlobal(arg_26_0.handler)

		arg_26_0.handler = nil
	end

	local var_26_0 = xyd.WindowManager.get():getWindow("hero_dialog")

	if var_26_0 and not tolua.isnull(var_26_0) then
		var_26_0:playTalk()
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_FAVOR_INFO
	})
end

function HeroTalkWindow.scrollListener(arg_27_0, arg_27_1)
	if arg_27_1.name == "began" then
		arg_27_0.startClick_ = true
		arg_27_0.prevY_ = arg_27_1.y
	elseif arg_27_1.name == "moved" and 20 <= math.abs(arg_27_1.y - arg_27_0.prevY_) then
		arg_27_0.startClick_ = false
	end
end

return HeroTalkWindow
