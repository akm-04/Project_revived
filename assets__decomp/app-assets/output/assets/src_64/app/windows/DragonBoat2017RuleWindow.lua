local var_0_0 = class("DragonBoat2017RuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityDragonshipReward

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT2017)
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 700, 400),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("DRAGONBOAT2_RULE_TITLE"))
	arg_4_0:nodeByName("close_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("left_hua"):setPositionX(arg_4_0:nodeByName("left_hua"):getPositionX() - 40)
	arg_4_0:nodeByName("right_hua"):setPositionX(arg_4_0:nodeByName("right_hua"):getPositionX() + 40)

	local var_4_0 = arg_4_0:createRuleLabel()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.list:newItem()
		local var_4_3 = display.newNode()

		var_4_0[iter_4_0]:addTo(var_4_3)
		var_4_0[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		var_4_0[iter_4_0]:setPosition(0, 0)
		var_4_3:setContentSize(700, var_4_0[iter_4_0]:getContentSize().height)
		var_4_3:addTo(var_4_1)
		var_4_1:setContentSize(700, var_4_0[iter_4_0]:getContentSize().height + 20)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(700, var_4_0[iter_4_0]:getContentSize().height + 20)
		arg_4_0.list:addItem(var_4_2)
	end

	arg_4_0:updateReward()
	arg_4_0.list:reload()
end

function var_0_0.createRuleLabel(arg_6_0)
	local var_6_0 = var_0_1:translation("DRAGONBOAT2_RULE_TEXT")
	local var_6_1 = arg_6_0.dragonBoatModel.baseInfo.daily_ticket_num
	local var_6_2 = string.format(var_6_0, var_6_1)
	local var_6_3 = xyd.luaStringSplit(var_6_2, "|")
	local var_6_4 = {}

	for iter_6_0 = 1, #var_6_3 do
		local var_6_5 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_6_6 = xyd.AssetLoader.get():loadLabel(var_6_5)

		var_6_6:setMaxLineWidth(700)
		var_6_6:setLineHeight(49)
		var_6_6:setString(var_6_3[iter_6_0])
		table.insert(var_6_4, var_6_6)
	end

	return var_6_4
end

function var_0_0.updateReward(arg_7_0)
	local var_7_0 = arg_7_0.list:newItem()
	local var_7_1 = {
		size = 24,
		color = cc.c3b(210, 84, 16)
	}
	local var_7_2 = xyd.AssetLoader.get():loadLabel(var_7_1)

	var_7_2:setMaxLineWidth(700)
	var_7_2:setLineHeight(49)
	var_7_2:setString(var_0_1:translation("ACTIVITY_DRAGONBOAT_MAIL_TITLE"))
	var_7_0:addContent(var_7_2)
	var_7_0:setItemSize(700, var_7_2:getContentSize().height + 20)
	arg_7_0.list:addItem(var_7_0)
	arg_7_0:updateRewardItem()
end

function var_0_0.updateRewardItem(arg_8_0)
	local var_8_0 = var_0_2:RewardCount()

	for iter_8_0 = 1, var_8_0 do
		local var_8_1 = arg_8_0.list:newItem()
		local var_8_2 = display.newNode()

		var_8_2:setContentSize(700, 80)

		local var_8_3 = var_0_2:range(iter_8_0)
		local var_8_4 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_8_5 = xyd.AssetLoader.get():loadLabel(var_8_4)

		if var_8_3[1] == var_8_3[2] then
			local var_8_6 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_8_3[1])

			var_8_5:setString(var_8_6)
		else
			local var_8_7 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_8_3[1], var_8_3[2])

			var_8_5:setString(var_8_7)
		end

		var_8_5:addTo(var_8_2)
		var_8_5:setAnchorPoint(cc.p(0, 0.5))
		var_8_5:setPosition(50, 40)

		local var_8_8 = var_0_2:item(iter_8_0)
		local var_8_9 = var_0_2:itemNum(iter_8_0)

		for iter_8_1 = 1, #var_8_8 do
			local var_8_10 = display.newNode()

			var_8_10:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_8_10, var_8_8[iter_8_1])
			var_8_10:addTo(var_8_2)
			var_8_10:setAnchorPoint(cc.p(0.5, 0.5))
			var_8_10:setPosition(250 + (iter_8_1 - 1) * 150, 40)

			local var_8_11 = {
				size = 24,
				color = cc.c3b(255, 255, 255)
			}
			local var_8_12 = xyd.AssetLoader.get():loadLabel(var_8_11)

			var_8_12:setString("x" .. var_8_9[iter_8_1])
			var_8_12:addTo(var_8_2)
			var_8_12:setAnchorPoint(cc.p(0, 0.5))
			var_8_12:setPosition(290 + (iter_8_1 - 1) * 150, 40)
		end

		var_8_1:addContent(var_8_2)
		var_8_1:setItemSize(700, 80)
		arg_8_0.list:addItem(var_8_1)
	end
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
