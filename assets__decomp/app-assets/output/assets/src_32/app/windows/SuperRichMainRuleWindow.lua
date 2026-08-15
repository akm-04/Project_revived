local var_0_0 = class("SuperRichMainRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = xyd.tables.activityDiglettType

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

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 680, 480),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.labels = {}

	arg_4_0:createRuleLabel()

	for iter_4_0 = 1, #arg_4_0.labels do
		local var_4_0 = display.newNode()
		local var_4_1 = arg_4_0.list:newItem()
		local var_4_2 = display.newNode()

		arg_4_0.labels[iter_4_0]:addTo(var_4_2)
		arg_4_0.labels[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		arg_4_0.labels[iter_4_0]:setPosition(0, 0)
		var_4_2:setContentSize(620, arg_4_0.labels[iter_4_0]:getContentSize().height)
		var_4_2:addTo(var_4_0)
		var_4_0:setContentSize(620, arg_4_0.labels[iter_4_0]:getContentSize().height + 20)
		var_4_1:addContent(var_4_0)
		var_4_1:setItemSize(620, arg_4_0.labels[iter_4_0]:getContentSize().height + 20)
		arg_4_0.list:addItem(var_4_1)
	end

	local var_4_3 = display.newNode()
	local var_4_4 = arg_4_0.list:newItem()
	local var_4_5 = display.newNode()
	local var_4_6 = {
		size = 24,
		color = cc.c3b(139, 68, 68)
	}
	local var_4_7 = xyd.AssetLoader.get():loadLabel(var_4_6)

	var_4_7:setDimensions(620, 0)
	var_4_7:setLineHeight(49)
	var_4_7:setString(var_0_1:translation("ACTIVITY_RICH_MAIL_TITLE"))
	var_4_7:addTo(var_4_5)
	var_4_7:setAnchorPoint(cc.p(0, 0))
	var_4_7:setPosition(0, 0)
	var_4_5:setContentSize(620, var_4_7:getContentSize().height)
	var_4_5:addTo(var_4_3)
	var_4_3:setContentSize(620, var_4_7:getContentSize().height + 20)
	var_4_4:addContent(var_4_3)
	var_4_4:setItemSize(620, var_4_7:getContentSize().height + 20)
	arg_4_0.list:addItem(var_4_4)

	local var_4_8 = xyd.tables.activityRichRangeReward:ids()

	for iter_4_1 = 1, #var_4_8 do
		local var_4_9 = var_4_8[iter_4_1]
		local var_4_10 = display.newNode()
		local var_4_11 = arg_4_0.list:newItem()

		var_4_10:setContentSize(620, 80)
		arg_4_0:addAwardItem(var_4_10, var_4_9)
		var_4_11:addContent(var_4_10)
		var_4_11:setItemSize(620, var_4_10:getContentSize().height)
		arg_4_0.list:addItem(var_4_11)
	end

	arg_4_0.list:reload()
end

function var_0_0.addAwardItem(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0
	local var_5_1
	local var_5_2 = xyd.tables.activityRichRangeReward:range(arg_5_2)

	if arg_5_2 == 1 then
		var_5_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_5_2)
	else
		local var_5_3 = xyd.tables.activityRichRangeReward:range(arg_5_2 - 1)

		if var_5_2 - var_5_3 > 1 then
			var_5_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_2"), var_5_3 + 1, var_5_2)
		else
			var_5_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_5_2)
		end
	end

	local var_5_4 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = x,
		y = y,
		color = cc.c3b(139, 68, 68),
		dimensions = cc.size(620, 0),
		text = var_5_1
	}
	local var_5_5 = xyd.AssetLoader.get():loadLabel(var_5_4)

	var_5_5:addTo(arg_5_1)
	var_5_5:setAnchorPoint(cc.p(0, 0))
	var_5_5:setPosition(0, 20)

	local var_5_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/zillionaire/rule/rank_award_item.csb")

	var_5_6:addTo(arg_5_1)
	var_5_6:setPosition(60, 0)
	var_5_6:setAnchorPoint(cc.p(0, 0))

	local var_5_7 = var_5_6:getChildByName("container")
	local var_5_8 = clone(xyd.tables.activityRichRangeReward:itemIds(arg_5_2))
	local var_5_9 = clone(xyd.tables.activityRichRangeReward:itemNums(arg_5_2))
	local var_5_10 = xyd.tables.activityRichRangeReward:crystal(arg_5_2)

	if var_5_10 > 0 then
		table.insert(var_5_8, -1)
		table.insert(var_5_9, var_5_10)
	end

	for iter_5_0 = 1, 3 do
		xyd.setPositionBy(var_5_7:getChildByName("item" .. tostring(iter_5_0)), cc.p(55 * iter_5_0 - (iter_5_0 - 1) * 70, 0))
		xyd.setPositionBy(var_5_7:getChildByName("item" .. tostring(iter_5_0) .. "_num"), cc.p(55 * iter_5_0 - (iter_5_0 - 1) * 70, 0))
	end

	if #var_5_8 == 0 or var_5_8[1] == 0 then
		var_5_7:getChildByName("item1"):setVisible(false)
		var_5_7:getChildByName("item2"):setVisible(false)
		var_5_7:getChildByName("item3"):setVisible(false)
		var_5_7:getChildByName("item1_num"):setVisible(false)
		var_5_7:getChildByName("item2_num"):setVisible(false)
		var_5_7:getChildByName("item3_num"):setVisible(false)
	elseif #var_5_8 == 1 then
		local var_5_11 = var_5_7:getChildByName("item3")

		var_5_7:getChildByName("item3_num"):setString("x" .. var_5_9[1])
		xyd.setItemBorder(var_5_11, var_5_8[1])
		var_5_7:getChildByName("item2"):setVisible(false)
		var_5_7:getChildByName("item1"):setVisible(false)
		var_5_7:getChildByName("item2_num"):setVisible(false)
		var_5_7:getChildByName("item1_num"):setVisible(false)
	elseif #var_5_8 == 2 then
		local var_5_12 = var_5_7:getChildByName("item3")

		var_5_7:getChildByName("item3_num"):setString("x" .. var_5_9[1])
		xyd.setItemBorder(var_5_12, var_5_8[1])

		local var_5_13 = var_5_7:getChildByName("item2")

		var_5_7:getChildByName("item2_num"):setString("x" .. var_5_9[2])
		xyd.setItemBorder(var_5_13, var_5_8[2])
		var_5_7:getChildByName("item1"):setVisible(false)
		var_5_7:getChildByName("item1_num"):setVisible(false)
	elseif #var_5_8 == 3 then
		local var_5_14 = var_5_7:getChildByName("item3")

		var_5_7:getChildByName("item3_num"):setString("x" .. var_5_9[1])
		xyd.setItemBorder(var_5_14, var_5_8[1])

		local var_5_15 = var_5_7:getChildByName("item2")

		var_5_7:getChildByName("item2_num"):setString("x" .. var_5_9[2])
		xyd.setItemBorder(var_5_15, var_5_8[2])

		local var_5_16 = var_5_7:getChildByName("item1")

		var_5_7:getChildByName("item1_num"):setString("x" .. var_5_9[3])
		xyd.setItemBorder(var_5_16, var_5_8[3])
	end
end

function var_0_0.getLabel(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {
		color = arg_6_3 or cc.c3b(139, 68, 68),
		size = arg_6_2 or 24
	}
	local var_6_1 = xyd.AssetLoader.get():loadLabel(var_6_0)

	var_6_1:setMaxLineWidth(700)
	var_6_1:setLineHeight(49)
	var_6_1:setString(arg_6_1)

	return var_6_1
end

function var_0_0.createRuleLabel(arg_7_0)
	local var_7_0 = var_0_1:translation("ACTIVITY_RICH_RULE_TEXT")

	dump(var_7_0)

	local var_7_1 = xyd.luaStringSplit(var_7_0, "|")

	for iter_7_0 = 1, #var_7_1 do
		local var_7_2 = {
			size = 24,
			color = cc.c3b(139, 68, 68)
		}
		local var_7_3 = xyd.AssetLoader.get():loadLabel(var_7_2)

		var_7_3:setMaxLineWidth(620)
		var_7_3:setLineHeight(49)
		var_7_3:setString(var_7_1[iter_7_0])
		table.insert(arg_7_0.labels, var_7_3)
	end
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
