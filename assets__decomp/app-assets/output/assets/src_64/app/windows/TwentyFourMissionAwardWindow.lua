local var_0_0 = class("TwentyFourMissionAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTwentyFourMission
local var_0_3 = xyd.tables.misc:getValue("activity_twenty_four_skin")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selectIndex = 1

	if arg_1_2 then
		arg_1_0.canAward = arg_1_2.canAward
		arg_1_0.activity = arg_1_2.activity
	else
		arg_1_0.canAward = false
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0.list:setBounceable(true)
	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0.list:reload()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("ACTIVITY_TWENTY_FOUR_TEXT_4"))
	arg_3_0:nodeByName("ok_text"):setString(var_0_1:translation("ACTIVITY_TWENTY_FOUR_TEXT_5"))
	arg_3_0:nodeByName("tips"):setString(var_0_1:translation("ACTIVITY_TWENTY_FOUR_TEXT_6"))
	arg_3_0:nodeByName("title"):enableOutline(cc.c4b(104, 67, 37, 255), 2)
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("ok_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0 = {
				skinItem = var_0_3[arg_3_0.selectIndex],
				skinItemIndex = arg_3_0.selectIndex,
				activity = arg_3_0.activity
			}

			xyd.WindowManager.get():openWindow("activity_twenty_four_mission_confirm", var_4_0)
		end
	end)

	local var_3_0 = arg_3_0.canAward

	arg_3_0:nodeByName("tips"):setVisible(not var_3_0)
	arg_3_0:nodeByName("ok_btn"):setVisible(var_3_0)
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = var_0_3

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #var_5_0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		if arg_5_3 > #var_5_0 then
			return
		end

		local var_5_1 = arg_5_0.list:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.list:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = var_5_0[arg_5_3]
		local var_5_3 = display.newNode()

		arg_5_0:initCell(var_5_3, var_5_2, arg_5_3)

		local var_5_4 = display.newNode()

		var_5_4:addChild(var_5_3)
		var_5_4:setContentSize(var_5_3:getContentSize())
		var_5_1:setItemSize(var_5_3:getContentSize().width, var_5_3:getContentSize().height)
		var_5_1:addContent(var_5_4)

		return var_5_1
	end
end

function var_0_0.initCell(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1179/award_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = arg_6_2

	var_6_1:getChildByName("type_text"):setString(xyd.tables.item:name(var_6_2))

	local var_6_3 = xyd.tables.skinSkill:getModelID(var_6_2)
	local var_6_4 = xyd.tables.model:card(var_6_3)
	local var_6_5 = xyd.SpriteLoader.new(var_6_4, nil, nil, xyd.DefaultImageType.HERO_CARD, var_6_1:getChildByName("card_container"))

	xyd.displaySpriteOnContainer(var_6_5, var_6_1:getChildByName("card_container"))

	local var_6_6 = var_6_1:getChildByName("skill_icon")
	local var_6_7 = xyd.tables.skinSkill:getSkillID(var_6_2)

	if var_6_7 and var_6_7 ~= 0 then
		xyd.setSkillBorder(var_6_6, var_6_7, 1)

		local var_6_8 = {
			has_jiantou = false,
			id = var_6_7
		}

		var_6_6:setTouchEnabled(true)
		var_6_6:setTouchSwallowEnabled(true)
		var_6_6:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.began then
				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_7_0 = xyd.WindowManager.get():openWindow("skill_tips", var_6_8)

					xyd.adaptToWorldPosition(var_6_6, var_7_0)
				end

				return true
			elseif arg_7_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	else
		var_6_6:removeAllChildren()
	end

	if not arg_6_0.canAward then
		var_6_1:getChildByName("choose"):setVisible(false)
	else
		if arg_6_3 == arg_6_0.selectIndex then
			arg_6_0.select = var_6_1:getChildByName("choose")

			var_6_1:getChildByName("choose"):setVisible(true)
		else
			var_6_1:getChildByName("choose"):setVisible(false)
		end

		arg_6_1:setTouchEnabled(true)
		arg_6_1:setTouchSwallowEnabled(false)
		arg_6_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "began" then
				-- block empty
			elseif arg_8_0.name == "moved" then
				-- block empty
			elseif arg_8_0.name == "ended" then
				xyd.playButtonSound()

				if arg_6_0.select and not tolua.isnull(arg_6_0.select) then
					arg_6_0.select:setVisible(false)
				end

				arg_6_0.select = var_6_1:getChildByName("choose")

				arg_6_0.select:setVisible(true)

				arg_6_0.selectIndex = arg_6_3
			end

			return true
		end)
	end

	local var_6_9 = var_6_1:getContentSize()

	arg_6_1:setContentSize(var_6_9.width + 30, var_6_9.height)
	arg_6_1:addChild(var_6_0)
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
