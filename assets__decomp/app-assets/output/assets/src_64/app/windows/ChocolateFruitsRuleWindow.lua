local var_0_0 = class("ChocolateFruitsRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = xyd.tables.activityChocolateFruit

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
		viewRect = cc.rect(0, 0, 520, 430),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_3_0:nodeByName("scroll")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setBounceable(true)

	arg_3_0.title = arg_3_1.title
	arg_3_0.rule = arg_3_1.rule

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title"):setString(var_0_1:translation(arg_4_0.title))
	arg_4_0:nodeByName("title"):enableOutline(cc.c4b(230, 61, 93, 255), 2)

	arg_4_0.labels = {}

	arg_4_0:createRuleLabel()

	for iter_4_0 = 1, #arg_4_0.labels do
		local var_4_0 = display.newNode()
		local var_4_1 = arg_4_0.list:newItem()
		local var_4_2 = display.newNode()

		arg_4_0.labels[iter_4_0]:addTo(var_4_2)
		arg_4_0.labels[iter_4_0]:setAnchorPoint(cc.p(0, 0))
		arg_4_0.labels[iter_4_0]:setPosition(0, 0)
		var_4_2:setContentSize(520, arg_4_0.labels[iter_4_0]:getContentSize().height)
		var_4_2:addTo(var_4_0)
		var_4_0:setContentSize(520, arg_4_0.labels[iter_4_0]:getContentSize().height + 20)
		var_4_1:addContent(var_4_0)
		var_4_1:setItemSize(520, arg_4_0.labels[iter_4_0]:getContentSize().height + 20)
		arg_4_0.list:addItem(var_4_1)
	end

	local var_4_3 = arg_4_0:getLabel(var_0_1:translation("ACTIVITY_ANNIVERSARY_DIGLETT_TYPE"))
	local var_4_4 = display.newNode()
	local var_4_5 = arg_4_0.list:newItem()
	local var_4_6 = display.newNode()

	var_4_3:setAnchorPoint(cc.p(0, 0))
	var_4_3:addTo(var_4_6)
	var_4_6:setContentSize(520, var_4_3:getContentSize().height)
	var_4_6:addTo(var_4_4)
	var_4_4:setContentSize(520, var_4_3:getContentSize().height + 20)
	var_4_5:addContent(var_4_4)
	var_4_5:setItemSize(520, var_4_3:getContentSize().height + 20)
	arg_4_0.list:addItem(var_4_5)

	local var_4_7 = display.newNode()
	local var_4_8 = arg_4_0.list:newItem()
	local var_4_9 = display.newNode()

	var_4_9:setContentSize(520, 300)

	local var_4_10 = var_0_3:ids()

	for iter_4_1 = 1, #var_4_10 do
		local var_4_11 = math.ceil(iter_4_1 / 3)
		local var_4_12 = (iter_4_1 - 1) % 3 + 1
		local var_4_13 = var_0_3:icon(iter_4_1)
		local var_4_14 = xyd.AssetLoader:get():loadSprite(var_4_13)

		var_4_14:setAnchorPoint(cc.p(0.5, 0))
		var_4_14:addTo(var_4_9)
		var_4_14:setPosition(cc.p((var_4_12 - 1) * 180 + 65, 110 * (2 - var_4_11) - 20))
		var_4_14:setScale(0.7)

		local var_4_15 = var_0_3:point(iter_4_1)
		local var_4_16 = arg_4_0:getLabel(var_0_1:translation("ACTIVITY_ANNIVERSARY_SCORE_TEXT") .. " " .. var_4_15, 24)

		var_4_16:setAnchorPoint(cc.p(0.5, 1))
		var_4_16:addTo(var_4_9)
		var_4_16:setPosition(cc.p((var_4_12 - 1) * 180 + 65, 110 * (2 - var_4_11) - 20))
	end

	var_4_7:setContentSize(520, 300)
	var_4_8:setContentSize(520, 300)
	var_4_9:addTo(var_4_7)
	var_4_8:addContent(var_4_7)
	arg_4_0.list:addItem(var_4_8)

	local var_4_17 = display.newNode()
	local var_4_18 = arg_4_0.list:newItem()
	local var_4_19 = display.newNode()
	local var_4_20 = {
		size = 24,
		color = cc.c3b(139, 68, 68)
	}
	local var_4_21 = xyd.AssetLoader.get():loadLabel(var_4_20)

	var_4_21:setDimensions(520, 0)
	var_4_21:setLineHeight(49)
	var_4_21:setString(var_0_1:translation("PARADISE_RULE_TEXT_8"))
	var_4_21:addTo(var_4_19)
	var_4_21:setAnchorPoint(cc.p(0, 0))
	var_4_21:setPosition(0, 0)
	var_4_19:setContentSize(520, var_4_21:getContentSize().height)
	var_4_19:addTo(var_4_17)
	var_4_17:setContentSize(520, var_4_21:getContentSize().height + 20 + 200)
	var_4_18:addContent(var_4_17)
	var_4_18:setItemSize(520, var_4_21:getContentSize().height + 20 + 200)
	arg_4_0.list:addItem(var_4_18)

	local var_4_22 = xyd.tables.activityFruitRank:ids()

	for iter_4_2 = 1, #var_4_22 do
		local var_4_23 = var_4_22[iter_4_2]
		local var_4_24 = display.newNode()
		local var_4_25 = arg_4_0.list:newItem()

		var_4_24:setContentSize(520, 80)
		arg_4_0:addAwardItem(var_4_24, var_4_23)
		var_4_25:addContent(var_4_24)
		var_4_25:setItemSize(520, var_4_24:getContentSize().height)
		arg_4_0.list:addItem(var_4_25)
	end

	arg_4_0.list:reload()
end

function var_0_0.addAwardItem(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = 0
	local var_5_1
	local var_5_2 = xyd.tables.activityFruitRank:range(arg_5_2)

	if arg_5_2 == 1 then
		var_5_1 = string.format(var_0_1:translation("ARENA_RULE_ITEM_TITLE_1"), var_5_2)
	else
		local var_5_3 = xyd.tables.activityFruitRank:range(arg_5_2 - 1)

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
		dimensions = cc.size(520, 0),
		text = var_5_1
	}
	local var_5_5 = xyd.AssetLoader.get():loadLabel(var_5_4)

	var_5_5:addTo(arg_5_1)
	var_5_5:setAnchorPoint(cc.p(0, 0))
	var_5_5:setPosition(0, 20)

	local var_5_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/chocolate_fruits/main/rank_award_item.csb")

	var_5_6:addTo(arg_5_1)
	var_5_6:setPosition(20, 0)
	var_5_6:setAnchorPoint(cc.p(0, 0))

	local var_5_7 = var_5_6:getChildByName("container")
	local var_5_8 = xyd.tables.gift:items(xyd.tables.activityFruitRank:gift(arg_5_2))
	local var_5_9 = xyd.tables.gift:itemNum(xyd.tables.activityFruitRank:gift(arg_5_2))

	for iter_5_0 = 1, 3 do
		xyd.setPositionBy(var_5_7:getChildByName("item" .. tostring(iter_5_0)), cc.p(55 * iter_5_0 - (iter_5_0 - 1) * 80 + 40, 0))
		xyd.setPositionBy(var_5_7:getChildByName("item" .. tostring(iter_5_0) .. "_num"), cc.p(55 * iter_5_0 - (iter_5_0 - 1) * 80 + 40, 0))
	end

	if #var_5_8 == 0 or var_5_8[1] == 0 then
		var_5_7:getChildByName("item1"):setVisible(false)
		var_5_7:getChildByName("item2"):setVisible(false)
		var_5_7:getChildByName("item3"):setVisible(false)
		var_5_7:getChildByName("item1_num"):setVisible(false)
		var_5_7:getChildByName("item2_num"):setVisible(false)
		var_5_7:getChildByName("item3_num"):setVisible(false)
	elseif #var_5_8 == 1 then
		local var_5_10 = var_5_7:getChildByName("item3")

		var_5_7:getChildByName("item3_num"):setString("x" .. var_5_9[1])
		xyd.setItemBorder(var_5_10, var_5_8[1])
		var_5_7:getChildByName("item2"):setVisible(false)
		var_5_7:getChildByName("item1"):setVisible(false)
		var_5_7:getChildByName("item2_num"):setVisible(false)
		var_5_7:getChildByName("item1_num"):setVisible(false)
	elseif #var_5_8 == 2 then
		local var_5_11 = var_5_7:getChildByName("item3")

		var_5_7:getChildByName("item3_num"):setString("x" .. var_5_9[1])
		xyd.setItemBorder(var_5_11, var_5_8[1])

		local var_5_12 = var_5_7:getChildByName("item2")

		var_5_7:getChildByName("item2_num"):setString("x" .. var_5_9[2])
		xyd.setItemBorder(var_5_12, var_5_8[2])
		var_5_7:getChildByName("item1"):setVisible(false)
		var_5_7:getChildByName("item1_num"):setVisible(false)
	elseif #var_5_8 == 3 then
		local var_5_13 = var_5_7:getChildByName("item3")

		var_5_7:getChildByName("item3_num"):setString("x" .. var_5_9[1])
		xyd.setItemBorder(var_5_13, var_5_8[1])

		local var_5_14 = var_5_7:getChildByName("item2")

		var_5_7:getChildByName("item2_num"):setString("x" .. var_5_9[2])
		xyd.setItemBorder(var_5_14, var_5_8[2])

		local var_5_15 = var_5_7:getChildByName("item1")

		var_5_7:getChildByName("item1_num"):setString("x" .. var_5_9[3])
		xyd.setItemBorder(var_5_15, var_5_8[3])
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
	local var_7_0 = var_0_1:translation(arg_7_0.rule)
	local var_7_1 = xyd.luaStringSplit(var_7_0, "|")

	for iter_7_0 = 1, #var_7_1 do
		local var_7_2 = {
			size = 24,
			color = cc.c3b(139, 68, 68)
		}
		local var_7_3 = xyd.AssetLoader.get():loadLabel(var_7_2)

		var_7_3:setMaxLineWidth(520)
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
