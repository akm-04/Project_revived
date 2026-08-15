local var_0_0 = class("TwoYearsBonusItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.twoYearsMission
local var_0_3 = 60

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/two_years/two_years_bonus_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.twoYearsCampaignAward:reward(arg_4_1)
	local var_4_1 = xyd.tables.twoYearsCampaignAward:stars()

	if arg_4_0.starLabel then
		arg_4_0.starLabel:removeAllChildren()
		arg_4_0.starLabel:removeSelf()

		arg_4_0.starLabel = nil
	end

	local var_4_2, var_4_3 = arg_4_0.contentView_:nodeByName("star_num_node"):getPosition()

	arg_4_0.starLabel = xyd.AssetLoader.get():loadLabel(nil, "bonus")

	arg_4_0.starLabel:setString(tostring(var_4_1[arg_4_1]))
	arg_4_0.starLabel:addTo(arg_4_0)
	arg_4_0.starLabel:setPosition(var_4_2, var_4_3)
	arg_4_0.starLabel:setAnchorPoint(cc.p(0, 0.5))
	arg_4_0.contentView_:nodeByName("bonus_lev"):setString("Lv." .. arg_4_1)
	arg_4_0.contentView_:nodeByName("bonus_label"):setString(var_0_1:translation("REWARD"))
	arg_4_0.contentView_:nodeByName("tips_label1"):setString(var_0_1:translation("ANNI2_TIPS_TXT27"))
	arg_4_0.contentView_:nodeByName("tips_label2"):setString(var_0_1:translation("ANNI2_TIPS_TXT28"))

	local var_4_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_4_5 = xyd.tables.gift
	local var_4_6 = {}
	local var_4_7 = var_4_5:items(var_4_0)
	local var_4_8 = var_4_5:itemNum(var_4_0)
	local var_4_9 = var_4_5:mana(var_4_0)
	local var_4_10 = var_4_5:crystal(var_4_0)

	if var_4_10 > 0 then
		table.insert(var_4_6, {
			itemID = "-1",
			num = var_4_10
		})
	end

	if var_4_9 > 0 then
		table.insert(var_4_6, {
			itemID = "-2",
			num = var_4_9
		})
	end

	for iter_4_0 = 1, #var_4_7 do
		table.insert(var_4_6, {
			itemID = var_4_7[iter_4_0],
			num = var_4_8[iter_4_0]
		})
	end

	arg_4_0:initItems(var_4_6)
end

function var_0_0.initItems(arg_5_0, arg_5_1)
	local var_5_0 = 0

	for iter_5_0, iter_5_1 in pairs(arg_5_1) do
		local var_5_1 = display.newNode()

		var_5_1:setContentSize(55, 55)
		var_5_1:setAnchorPoint(0, 0)
		var_5_1:setPosition(var_5_0, 0)

		var_5_0 = var_5_0 + var_0_3

		xyd.setItemBorder(var_5_1, iter_5_1.itemID, nil, nil, iter_5_1.num)
		var_5_1:addTo(arg_5_0.contentView_:nodeByName("item_list"))
	end
end

local var_0_4 = class("TwoYearsBonusWindow", import("app.common.ui.BaseWindow"))
local var_0_5 = xyd.tables.translation
local var_0_6 = 200
local var_0_7 = 660
local var_0_8 = 450

function var_0_4.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_4.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	arg_6_0.showItemPos = 0
end

function var_0_4.willOpen(arg_7_0, arg_7_1)
	var_0_4.super.willOpen(arg_7_0, arg_7_1)
end

function var_0_4.didOpen(arg_8_0, arg_8_1)
	var_0_4.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:initListView()
	arg_8_0:updateBonusList()
end

function var_0_4.initListView(arg_9_0)
	arg_9_0.node = display.newNode()
	arg_9_0.listView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, arg_9_0:nodeByName("bonus_list"):getWidth(), arg_9_0:nodeByName("bonus_list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_9_0:nodeByName("bonus_list")):onScroll(handler(arg_9_0, arg_9_0.scrollListener))
end

function var_0_4.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrolling = false
		arg_10_0.prevX_ = arg_10_1.x
	elseif arg_10_1.name == "moved" and 20 <= math.abs(arg_10_1.x - arg_10_0.prevX_) then
		arg_10_0.scrolling = true
	end
end

function var_0_4.updateBonusList(arg_11_0)
	arg_11_0.listView_:removeAllItems()

	local var_11_0 = xyd.tables.twoYearsCampaignAward:stars()

	for iter_11_0 = 1, #var_11_0 do
		local var_11_1 = arg_11_0.listView_:newItem()
		local var_11_2 = 0
		local var_11_3 = var_0_0.new()

		var_11_3:setParams(iter_11_0)
		var_11_1:addContent(var_11_3)
		var_11_1:setItemSize(var_11_3:getContentSize().width, var_11_3:getContentSize().height)
		arg_11_0.listView_:addItem(var_11_1)
	end

	arg_11_0.listView_:reload()
end

function var_0_4.willClose(arg_12_0)
	return
end

return var_0_4
