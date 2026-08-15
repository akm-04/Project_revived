local var_0_0 = class("DragonBoatRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5
local var_0_3 = 90001340

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
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
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("day_award_txt"):setString(var_0_1:translation("DRAGONBOAT_RANK_AWARD"))

	local var_4_0 = xyd.tables.gift:items(var_0_3)
	local var_4_1 = xyd.tables.gift:itemNum(var_0_3)
	local var_4_2 = xyd.tables.gift:crystal(var_0_3)

	arg_4_0:setItemAndAddTips(arg_4_0:nodeByName("champion_award1"), var_4_0[1], var_4_1[1])
	arg_4_0:setItemAndAddTips(arg_4_0:nodeByName("champion_award2"), var_4_0[2], var_4_1[2])
	arg_4_0:setItemAndAddTips(arg_4_0:nodeByName("champion_award3"), -1, var_4_2)

	local var_4_3 = arg_4_0:nodeByName("rule_scoll"):getContentSize()

	arg_4_0.ruleScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(20, 0, var_4_3.width - 20, var_4_3.height - 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("rule_scoll")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.ruleScroll:setBounceable(true)
	arg_4_0.ruleScroll:setDelegate(handler(arg_4_0, arg_4_0.ruleScrollDelegate))
	arg_4_0.ruleScroll:reload()

	local var_4_4 = arg_4_0:nodeByName("rank_award_scroll"):getContentSize()

	arg_4_0.rewardScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_4.width, var_4_4.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("rank_award_scroll")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.rewardScroll:setBounceable(true)
	arg_4_0.rewardScroll:setDelegate(handler(arg_4_0, arg_4_0.rewardScrollDelegate))
	arg_4_0.rewardScroll:reload()
end

function var_0_0.createLabel(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {
		font = "fonts/main_font.ttf",
		size = 22,
		color = arg_5_3 or cc.c3b(255, 255, 255)
	}
	local var_5_1 = xyd.AssetLoader.get():loadLabel(var_5_0)

	var_5_1:setMaxLineWidth(440)
	var_5_1:setString(arg_5_2)

	return var_5_1
end

function var_0_0.ruleScrollDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_0_2
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_0 = arg_6_0.ruleScroll:dequeueItem()

		if not var_6_0 then
			var_6_0 = arg_6_0.ruleScroll:newItem()
		else
			var_6_0:removeAllChildren(true)
		end

		local var_6_1 = arg_6_0:creatRuleContainerContent(arg_6_3)
		local var_6_2 = var_6_1:getWidth()
		local var_6_3 = var_6_1:getHeight()

		var_6_0:setItemSize(var_6_2, var_6_3)
		var_6_0:addContent(var_6_1)

		return var_6_0
	end
end

function var_0_0.rewardScrollDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return 10
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0 = arg_7_0.rewardScroll:dequeueItem()

		if not var_7_0 then
			var_7_0 = arg_7_0.rewardScroll:newItem()
		else
			var_7_0:removeAllChildren(true)
		end

		local var_7_1 = arg_7_0:creatRewardContainerContent(arg_7_3)
		local var_7_2 = var_7_1:getWidth()
		local var_7_3 = var_7_1:getHeight()

		var_7_0:setItemSize(var_7_2, var_7_3)
		var_7_0:addContent(var_7_1)

		return var_7_0
	end
end

function var_0_0.creatRuleContainerContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = var_0_1:translation("DRAGONBOAT_RULE_TITLE" .. arg_8_1)
	local var_8_2 = var_0_1:translation("DRAGONBOAT_RULE_TEXT" .. arg_8_1)
	local var_8_3 = cc.c3b(205, 127, 49)
	local var_8_4 = arg_8_0:createLabel(arg_8_1, var_8_1, var_8_3)
	local var_8_5 = arg_8_0:createLabel(arg_8_1, var_8_2)

	var_8_4:addTo(var_8_0)
	var_8_4:setAnchorPoint(cc.p(0, 0))
	var_8_5:addTo(var_8_0)
	var_8_5:setAnchorPoint(cc.p(0, 0))
	var_8_5:setPosition(cc.p(0, 0))
	var_8_4:setPosition(0, var_8_5:getContentSize().height + 10)
	var_8_0:setContentSize(440, var_8_4:getContentSize().height + var_8_5:getContentSize().height + 20)

	return var_8_0
end

function var_0_0.creatRewardContainerContent(arg_9_0, arg_9_1)
	local var_9_0 = display.newNode()
	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1060/dragon_boat_rule/award_item.csb")
	local var_9_2 = var_9_1:getChildByName("container")
	local var_9_3 = xyd.tables.activityDragonReward:range(arg_9_1)

	if var_9_3 <= 3 then
		local var_9_4 = "windows/activities/1060/dragon_boat_rule/rank0" .. var_9_3 .. ".png"
		local var_9_5 = xyd.AssetLoader:get():loadSprite(var_9_4)

		var_9_5:setScale(0.5)
		var_9_5:setAnchorPoint(cc.p(0.5, 0.5))

		local var_9_6 = var_9_2:getChildByName("rank"):getContentSize().width / 2

		var_9_5:addTo(var_9_2:getChildByName("rank"))
		var_9_5:setPosition(cc.p(var_9_6, var_9_6))
	end

	if var_9_3 > 3 then
		sprite = xyd.AssetLoader.get():loadLabel(nil, "bonus")

		sprite:setString(var_9_3)
		sprite:setScale(0.7)
		sprite:setAnchorPoint(cc.p(0.5, 0.5))

		local var_9_7 = var_9_2:getChildByName("rank"):getContentSize().width / 2

		sprite:addTo(var_9_2:getChildByName("rank"))
		sprite:setPosition(cc.p(var_9_7, var_9_7))
	end

	local var_9_8 = xyd.splitToNumber(xyd.tables.activityDragonReward:item(arg_9_1), "|")
	local var_9_9 = xyd.splitToNumber(xyd.tables.activityDragonReward:itemNum(arg_9_1), "|")

	arg_9_0:setItemAndAddTips(var_9_2:getChildByName("reward_1"), var_9_8[1], var_9_9[1])
	arg_9_0:setItemAndAddTips(var_9_2:getChildByName("reward_2"), var_9_8[2], var_9_9[2])
	arg_9_0:setItemAndAddTips(var_9_2:getChildByName("reward_3"), var_9_8[3], var_9_9[3])
	var_9_1:addTo(var_9_0)
	var_9_1:setAnchorPoint(cc.p(0, 0))
	var_9_0:setContentSize(var_9_2:getContentSize())
	var_9_1:setName("source")

	return var_9_0
end

function var_0_0.setItemAndAddTips(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1:getContentSize().height
	local var_10_1 = display.newNode()

	var_10_1:setContentSize(var_10_0, var_10_0)

	local var_10_2 = xyd.tables.item:type(arg_10_2)

	xyd.setItemBorder(var_10_1, arg_10_2, nil, nil, arg_10_3)
	var_10_1:addTo(arg_10_1)
	var_10_1:setAnchorPoint(cc.p(0, 0))

	local var_10_3 = {
		id = arg_10_2,
		lev = xyd.tables.item:level(arg_10_2)
	}

	if xyd.tables.item:type(arg_10_2) == -1 then
		var_10_3.tipsType = 0
		var_10_3.desc1 = xyd.tables.hero:getDes(arg_10_2)
	elseif specialItem then
		var_10_3.tipsType = 1
		var_10_3.id = -3
	else
		var_10_3.tipsType = 1
		var_10_3.desc1 = xyd.tables.item:desc1(arg_10_2)
		var_10_3.desc2 = xyd.tables.item:desc2(arg_10_2)
	end

	var_10_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_10_2)
	var_10_3.name = xyd.tables.item:name(arg_10_2)

	arg_10_0:addTips(var_10_1, var_10_3)
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

return var_0_0
