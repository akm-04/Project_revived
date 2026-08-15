local var_0_0 = class("RagnarokMapStoryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.misc
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 1
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = xyd.tables.ragnarokMapStoryTable
local var_0_9 = xyd.tables.activityAnni4thCampaignTable
local var_0_10 = -100
local var_0_11 = 440
local var_0_12 = {
	x = 100,
	y = 180
}
local var_0_13 = {
	ONE = var_0_9:nextCampaign(var_0_9:startPoints()[1])[1],
	TWO = var_0_9:nextCampaign(var_0_9:startPoints()[1])[2]
}
local var_0_14 = {
	TWO = 3,
	ONE = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dialogueID = arg_1_2.dialogueID
	arg_1_0.dialogData_ = var_0_8:getStoryIDsByDialogueID(arg_1_0.dialogueID)
	arg_1_0.eventParams = arg_1_2.eventParams
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.notSendMid = arg_1_2.notSendMid or false
	arg_1_0.story = nil
	arg_1_0.dialogueIDs = {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	if arg_2_1.showBG then
		local var_2_0 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/map_story/bg.png")

		var_2_0:setAnchorPoint(cc.p(0, 0))
		arg_2_0:nodeByName("bg"):addChild(var_2_0)
		arg_2_0:nodeByName("bg"):setVisible(arg_2_1.showBG or false)
	end

	arg_2_0:layout()

	arg_2_0.canTouch = false

	arg_2_0:performWithDelay(function()
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0.canTouch = true
		end
	end, 1)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)

	arg_4_0.currentID = arg_4_0.dialogData_[1]
	arg_4_0.nextIDs = var_0_8:turnID(arg_4_0.currentID)

	arg_4_0:nextPlay()
end

function var_0_0.layout(arg_5_0)
	arg_5_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

	local var_5_0 = display.newNode()

	var_5_0:setName("role")
	var_5_0:size(arg_5_0:getContentSize())
	var_5_0:setAnchorPoint(cc.p(0, 0))
	var_5_0:setPosition(cc.p(0, 0))
	var_5_0:addTo(arg_5_0:nodeByName("node_role"))

	arg_5_0.roleLayer_ = var_5_0
	arg_5_0.touchLayer_ = var_5_0:clone()

	arg_5_0.touchLayer_:addTo(arg_5_0, 1)
	arg_5_0.touchLayer_:setTouchEnabled(true)
	arg_5_0.touchLayer_:setTouchSwallowEnabled(false)
	arg_5_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" and arg_5_0.canTouch then
			if arg_5_0.isPlayEffect then
				if arg_5_0.effect and not tolua.isnull(arg_5_0.effect) then
					arg_5_0.effect:stop()
				end

				arg_5_0:onEffectEnded()
			else
				arg_5_0:nextPlay()
			end
		end

		return true
	end)

	arg_5_0.optionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("list"):getWidth(), arg_5_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list"))

	arg_5_0.optionList:setDelegate(handler(arg_5_0, arg_5_0.optionListDelegate))
	arg_5_0.optionList:setBounceable(false)
end

function var_0_0.optionListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.nextIDs
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0 = arg_7_0.optionList:dequeueItem()

		if not var_7_0 then
			var_7_0 = arg_7_0.optionList:newItem()
		else
			var_7_0:removeAllChildren(true)
		end

		local var_7_1 = arg_7_0:createListContent(arg_7_0.nextIDs[arg_7_3])
		local var_7_2 = var_7_1:getWidth()
		local var_7_3 = var_7_1:getHeight()

		var_7_0:setItemSize(var_7_2, var_7_3 + 15)
		var_7_0:addContent(var_7_1)

		return var_7_0
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1199/map_story/story_item.csb")
	local var_8_2 = var_8_1:getChildByName("btn")
	local var_8_3 = var_0_8:buttonChoose(arg_8_1)
	local var_8_4 = string.gsub(var_8_3, "=playername=", arg_8_0.selfPlayer.playerName)
	local var_8_5 = var_8_2:getChildByName("txt")

	var_8_5:setString(var_8_4)
	var_8_5:enableOutline(cc.c4b(42, 42, 42, 255), 2)

	local var_8_6 = var_8_2:getChildByName("txt"):getWidth()
	local var_8_7 = 400

	if var_8_7 < var_8_6 then
		var_8_5:setFontSize(var_8_5:getFontSize() * var_8_7 / var_8_6)
	end

	var_8_2:addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0.currentID = arg_8_1

			local var_9_0 = var_0_8:typeID(arg_8_0.currentID)

			if var_9_0 == var_0_14.ONE then
				local var_9_1 = {
					campaign_id = var_0_13.ONE
				}

				arg_8_0.fourthAnniversary:mapChooseStory(var_9_1, function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						arg_8_0.story = arg_10_1.base_info.story_type
						arg_8_0.nextIDs = var_0_8:turnID(arg_8_0.currentID)

						arg_8_0:nextPlay()
						arg_8_0.optionList:setVisible(false)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = "error"
						})
					end
				end)
			elseif var_9_0 == var_0_14.TWO then
				local var_9_2 = {
					campaign_id = var_0_13.TWO
				}

				arg_8_0.fourthAnniversary:mapChooseStory(var_9_2, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						arg_8_0.story = arg_11_1.base_info.story_type
						arg_8_0.nextIDs = var_0_8:turnID(arg_8_0.currentID)

						arg_8_0:nextPlay()
						arg_8_0.optionList:setVisible(false)
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = "error"
						})
					end
				end)
			end
		end
	end)
	var_8_0:setAnchorPoint(cc.p(0, 0))
	var_8_0:setPosition(0, 0)
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_0:setContentSize(var_8_2:getContentSize())

	return var_8_0
end

function var_0_0.nextPlay(arg_12_0)
	if arg_12_0.currentID == -1 then
		arg_12_0:onEnded()

		return
	end

	arg_12_0:update()
end

function var_0_0.update(arg_13_0)
	table.insert(arg_13_0.dialogueIDs, arg_13_0.currentID)

	local var_13_0 = var_0_8:dialog(arg_13_0.currentID)
	local var_13_1 = string.gsub(var_13_0, "=playername=", arg_13_0.selfPlayer.playerName)
	local var_13_2 = var_0_8:name(arg_13_0.currentID)
	local var_13_3 = string.gsub(var_13_2, "=playername=", arg_13_0.selfPlayer.playerName)
	local var_13_4 = var_0_8:img(arg_13_0.currentID)[1]
	local var_13_5 = var_0_8:position(arg_13_0.currentID)

	if var_13_5 == var_0_3 then
		if arg_13_0.leftIcon_ ~= var_13_4 then
			arg_13_0.leftIcon_ = var_13_4

			if arg_13_0.roleLeft1_ and not tolua.isnull(arg_13_0.roleLeft1_) then
				arg_13_0.roleLeft1_:removeSelf()
				arg_13_0.roleLeft2_:removeSelf()
			end

			if var_13_4 then
				local var_13_6 = xyd.SpriteLoader.new(var_13_4, nil, nil, xyd.DefaultImageType.HOME_CARD)
				local var_13_7 = xyd.SpriteLoader.new(var_13_4, nil, nil, xyd.DefaultImageType.HOME_CARD)

				var_13_6:addTo(arg_13_0.roleLayer_, 1)
				var_13_7:addTo(arg_13_0.roleLayer_, -1)
				var_13_6:setAnchorPoint(cc.p(0, 0))
				var_13_7:setAnchorPoint(cc.p(0, 0))
				var_13_6:pos(var_0_10, 0)
				var_13_7:pos(var_0_10, 0)

				arg_13_0.roleLeft1_ = var_13_6
				arg_13_0.roleLeft2_ = var_13_7

				arg_13_0:gray(arg_13_0.roleLeft2_)
			end
		end

		arg_13_0:iconFilter(arg_13_0.roleLeft1_, arg_13_0.roleLeft2_, false)
		arg_13_0:iconFilter(arg_13_0.roleRight1_, arg_13_0.roleRight2_, true)
		arg_13_0:nodeByName("name_box1"):setVisible(true)
		arg_13_0:nodeByName("label_name1"):setString(var_13_3)
		arg_13_0:nodeByName("label_name1"):setVisible(true)
		arg_13_0:nodeByName("name_box2"):setVisible(false)
		arg_13_0:nodeByName("label_name2"):setVisible(false)
	else
		if arg_13_0.rightIcon_ ~= var_13_4 then
			arg_13_0.rightIcon_ = var_13_4

			if arg_13_0.roleRight1_ and not tolua.isnull(arg_13_0.roleRight1_) then
				arg_13_0.roleRight1_:removeSelf()
				arg_13_0.roleRight2_:removeSelf()
			end

			if var_13_4 then
				local var_13_8 = xyd.SpriteLoader.new(var_13_4, nil, nil, xyd.DefaultImageType.HOME_CARD)
				local var_13_9 = xyd.SpriteLoader.new(var_13_4, nil, nil, xyd.DefaultImageType.HOME_CARD)

				var_13_8:addTo(arg_13_0.roleLayer_, 1)
				var_13_9:addTo(arg_13_0.roleLayer_, -1)
				var_13_8:setAnchorPoint(cc.p(0, 0))
				var_13_9:setAnchorPoint(cc.p(0, 0))
				var_13_8:pos(var_0_11, 0)
				var_13_9:pos(var_0_11, 0)

				arg_13_0.roleRight1_ = var_13_8
				arg_13_0.roleRight2_ = var_13_9

				arg_13_0:gray(arg_13_0.roleRight2_)
			end
		end

		arg_13_0:iconFilter(arg_13_0.roleLeft1_, arg_13_0.roleLeft2_, true)
		arg_13_0:iconFilter(arg_13_0.roleRight1_, arg_13_0.roleRight2_, false)
		arg_13_0:nodeByName("name_box2"):setVisible(true)
		arg_13_0:nodeByName("label_name2"):setString(var_13_3)
		arg_13_0:nodeByName("label_name2"):setVisible(true)
		arg_13_0:nodeByName("name_box1"):setVisible(false)
		arg_13_0:nodeByName("label_name1"):setVisible(false)
	end

	local var_13_10 = var_0_8:expression(arg_13_0.currentID)
	local var_13_11 = xyd.tables.expression:expression(var_13_10)
	local var_13_12

	if var_13_5 == var_0_3 then
		var_13_12 = arg_13_0.roleLeft1_
	else
		var_13_12 = arg_13_0.roleRight1_
	end

	if arg_13_0.effect and not tolua.isnull(arg_13_0.effect) then
		arg_13_0.effect:removeFromParent()

		arg_13_0.effect = nil
	end

	if var_13_10 and var_13_10 > 0 and var_13_11 and var_13_11 ~= "" then
		var_13_12:setVisible(true)
		arg_13_0:nodeByName("bottom"):setVisible(false)

		local var_13_13 = var_13_11 .. ".json"
		local var_13_14 = var_13_11 .. ".atlas"

		arg_13_0.effect = var_0_1.new(var_13_13, var_13_14, 1)

		arg_13_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_13_0.effect:addTo(var_13_12)
		arg_13_0.effect:setPosition(cc.p(var_13_12:getContentSize().width / 2 + var_0_12.x, var_13_12:getContentSize().height / 2 + var_0_12.y))
		arg_13_0.effect:setName("effect")

		arg_13_0.isPlayEffect = true

		arg_13_0.effect:play(function()
			arg_13_0:onEffectEnded()
		end, false)
	else
		arg_13_0:playSpeak(var_13_1)
	end
end

function var_0_0.playSpeak(arg_15_0, arg_15_1)
	arg_15_0:nodeByName("bottom"):setVisible(true)
	arg_15_0:nodeByName("text"):setString(arg_15_1)

	if #arg_15_0.nextIDs > 1 then
		arg_15_0.optionList:setVisible(true)
		arg_15_0.optionList:reload()
		arg_15_0.touchLayer_:setTouchEnabled(false)
	else
		arg_15_0.optionList:setVisible(false)

		arg_15_0.currentID = arg_15_0.nextIDs[1]
		arg_15_0.nextIDs = var_0_8:turnID(arg_15_0.currentID)

		arg_15_0.touchLayer_:setTouchEnabled(true)
	end
end

function var_0_0.onEffectEnded(arg_16_0)
	local var_16_0 = var_0_8:dialog(arg_16_0.currentID)
	local var_16_1 = string.gsub(var_16_0, "=playername=", arg_16_0.selfPlayer.playerName)

	arg_16_0:playSpeak(var_16_1)

	if arg_16_0.effect and not tolua.isnull(arg_16_0.effect) then
		arg_16_0.effect:stop()
		arg_16_0.effect:setVisible(false)

		arg_16_0.isPlayEffect = false
	end
end

function var_0_0.iconFilter(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	if not arg_17_1 or tolua.isnull(arg_17_1) or not arg_17_2 or tolua.isnull(arg_17_2) then
		return
	end

	if arg_17_3 then
		arg_17_1:hide()
		arg_17_2:show()
	else
		arg_17_2:hide()
		arg_17_1:show()
	end
end

function var_0_0.gray(arg_18_0, arg_18_1)
	local var_18_0 = cc.TintBy:create(0, 200, 200, 200)

	arg_18_1:runActionOnce(var_18_0)
end

function var_0_0.onEnded(arg_19_0)
	if arg_19_0.callback then
		arg_19_0.callback(arg_19_0.story)
	end

	local var_19_0 = xyd.WindowManager.get():getWindow("activity_ragnarok_map_story")

	if var_19_0 and not tolua.isnull(var_19_0) then
		xyd.WindowManager.get():closeWindow("activity_ragnarok_map_story")
	end
end

function var_0_0.willClose(arg_20_0)
	local var_20_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
	local var_20_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

	if var_20_1 then
		var_20_1:setVisible(true)
	end

	if var_20_0 then
		var_20_0:setVisible(true)
	end

	arg_20_0:dispatchEvent({
		name = xyd.event.DIALOG_COMPLETE
	})
end

return var_0_0
