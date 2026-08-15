local var_0_0 = class("RecommendWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.listItems = arg_1_2.listItems
	arg_1_0.nextLevItems = arg_1_2.nextLevItems
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.initialRecommendList(arg_3_0)
	arg_3_0.recommendListItems = {}
	arg_3_0.recommendNextLevListItems = {}

	local var_3_0 = arg_3_0.selfPlayer.lev

	for iter_3_0 = 1, #arg_3_0.listItems do
		local var_3_1 = arg_3_0.listItems[iter_3_0].itemID
		local var_3_2 = {}

		for iter_3_1, iter_3_2 in pairs(arg_3_0.selfPlayer.heros_) do
			if iter_3_2:getLevel() >= var_3_0 - 10 and iter_3_2:getColor() >= 10 and iter_3_2:getItemHeroHasNotEquip(var_3_1) then
				table.insert(var_3_2, iter_3_2)
			end
		end

		if #var_3_2 > 0 then
			table.insert(arg_3_0.recommendListItems, {
				itemID = var_3_1,
				heroList = var_3_2
			})
		end
	end

	table.sort(arg_3_0.recommendListItems, function(arg_4_0, arg_4_1)
		return #arg_4_1.heroList < #arg_4_0.heroList
	end)

	local var_3_3 = {}

	for iter_3_3 = 1, #arg_3_0.nextLevItems do
		local var_3_4 = arg_3_0.nextLevItems[iter_3_3].itemID
		local var_3_5 = {}

		for iter_3_4, iter_3_5 in pairs(arg_3_0.selfPlayer.heros_) do
			if iter_3_5:getLevel() >= var_3_0 - 10 and iter_3_5:getColor() >= 10 and iter_3_5:getItemHeroHasNotEquip(var_3_4) then
				table.insert(var_3_5, iter_3_5)
			end
		end

		if #var_3_5 > 0 then
			table.insert(arg_3_0.recommendNextLevListItems, {
				itemID = var_3_4,
				heroList = var_3_5
			})
		end
	end

	table.sort(arg_3_0.recommendNextLevListItems, function(arg_5_0, arg_5_1)
		return #arg_5_1.heroList < #arg_5_0.heroList
	end)

	for iter_3_6 = 1, math.min(#arg_3_0.recommendListItems, var_0_2) do
		table.sort(arg_3_0.recommendListItems[iter_3_6].heroList, function(arg_6_0, arg_6_1)
			return xyd.heroNormalSort(arg_6_0, arg_6_1) or false
		end)
	end

	for iter_3_7 = 1, math.min(#arg_3_0.recommendNextLevListItems, var_0_2) do
		table.sort(arg_3_0.recommendNextLevListItems[iter_3_7].heroList, function(arg_7_0, arg_7_1)
			return xyd.heroNormalSort(arg_7_0, arg_7_1) or false
		end)
	end
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = xyd.EventCentreBuildingType.DESK

	arg_8_0:nodeByName("txt_title"):setString(xyd.tables.eventCentreTable:name(var_8_0))
	arg_8_0:nodeByName("equip_text"):setString(var_0_1:translation("ITEM_EQUIP"))
	arg_8_0:nodeByName("equip_hero_text"):setString(var_0_1:translation("EQUIP_HERO_TEXT"))
	arg_8_0:initialRecommendList()

	arg_8_0.scroll = arg_8_0:nodeByName("scroll")

	local var_8_1 = arg_8_0.scroll:getContentSize()

	arg_8_0.recommendList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 10, var_8_1.width, var_8_1.height - 10),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_8_0.scroll):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.recommendList:setBounceable(false)
	arg_8_0:recommendListLayout()
end

function var_0_0.recommendListLayout(arg_9_0)
	local var_9_0 = math.min(#arg_9_0.recommendListItems, var_0_2)
	local var_9_1 = math.min(#arg_9_0.recommendNextLevListItems, var_0_2)

	for iter_9_0 = 1, var_9_0 + var_9_1 do
		local var_9_2
		local var_9_3 = arg_9_0.recommendList:dequeueItem()

		if not var_9_3 then
			var_9_3 = arg_9_0.recommendList:newItem()
		else
			var_9_3:removeAllChildren(false)
		end

		local var_9_4 = arg_9_0.recommendListItems[iter_9_0]
		local var_9_5 = false

		if var_9_0 < iter_9_0 then
			var_9_4 = arg_9_0.recommendNextLevListItems[iter_9_0 - math.min(#arg_9_0.recommendListItems, var_0_2)]
			var_9_5 = true
		end

		local var_9_6 = arg_9_0:createListContent(var_9_4, var_9_5)
		local var_9_7 = var_9_6:getWidth()
		local var_9_8 = var_9_6:getHeight()

		var_9_3:setItemSize(var_9_7, var_9_8)
		var_9_3:addContent(var_9_6)
		var_9_6:setPositionY(5)
		arg_9_0.recommendList:addItem(var_9_3)
		arg_9_0.recommendList:reload()
	end
end

function var_0_0.createListContent(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/event_centre/production_table/recommend_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")

	var_10_0:setAnchorPoint(cc.p(0, 0))
	var_10_0:setPosition(0, 0)
	xyd.setItemBorder(var_10_2:getChildByName("item_container"), arg_10_1.itemID, nil, arg_10_2)

	for iter_10_0 = 1, math.min(#arg_10_1.heroList, var_0_2) do
		xyd.setAvatarBorderNewUI(arg_10_1.heroList[iter_10_0], var_10_2:getChildByName("hero_" .. iter_10_0), nil, nil, nil, nil)
	end

	var_10_2:getChildByName("need_num_txt"):setString(string.format(var_0_1:translation("NEED_NUM_TEXT"), #arg_10_1.heroList))
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
	arg_11_0:addBlockLayer()
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevX_ = arg_12_1.x
	elseif arg_12_1.name == "moved" and 20 <= math.abs(arg_12_1.x - arg_12_0.prevX_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

return var_0_0
