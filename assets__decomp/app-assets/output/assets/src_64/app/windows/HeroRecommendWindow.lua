local var_0_0 = class("HeroRecommendWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 6
local var_0_3 = import("app.model.Hero")
local var_0_4 = {
	Total = 1,
	Sub = 2
}
local var_0_5 = {
	All = 1,
	UnCollected = 3,
	Collected = 2
}
local var_0_6 = {
	"TOTAL_TEXT",
	"COLLECTED_TEXT",
	"UNCOLLECTED_TEXT"
}
local var_0_7 = {
	{
		icon = "total_recommend_text.png",
		texts = xyd.split(var_0_1:translation("RECOMMEND_MAIN_TYPES_TEXT"), "#")
	},
	{
		icon = "sub_recommend_text.png",
		texts = xyd.split(var_0_1:translation("RECOMMEND_SUB_TYPES_TEXT"), "#")
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.recommendType = var_0_4.Total
	arg_1_0.filterType = var_0_5.All
	arg_1_0.isExtended = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.scroll = arg_3_0:nodeByName("scroll")
	arg_3_0.scrollConent = arg_3_0.scroll:getContentSize()
	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0.scrollConent.width, arg_3_0.scrollConent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))

	arg_3_0.typeContainer = arg_3_0:nodeByName("sub_container")
	arg_3_0.typeContent = arg_3_0.typeContainer:getContentSize()
	arg_3_0.typeList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0.typeContent.width, arg_3_0.typeContent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.typeContainer):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.typeList:setDelegate(handler(arg_3_0, arg_3_0.typeListDelegate))
	arg_3_0.typeList:reload()
	arg_3_0.typeList:setTouchType(true)
	arg_3_0.typeList:setViewCanNotScroll(true)
	arg_3_0:updateTypeContainer()
	arg_3_0:swapRecommendType(arg_3_0.recommendType)
	arg_3_0:setButtonClick()
end

function var_0_0.updateTypeContainer(arg_4_0)
	arg_4_0.typeList:reload()
end

function var_0_0.setButtonClick(arg_5_0)
	arg_5_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hero_recommend_rule")
		end
	end)
end

function var_0_0.swapRecommendType(arg_7_0, arg_7_1)
	if arg_7_0.recommendType == arg_7_1 then
		arg_7_0.isExtended = not arg_7_0.isExtended
		arg_7_0.filterType = arg_7_0.filterType or 1
	else
		arg_7_0.recommendType = arg_7_1
		arg_7_0.isExtended = true
		arg_7_0.filterType = 1
	end

	arg_7_0:changeFilterType(arg_7_0.filterType)
end

function var_0_0.changeFilterType(arg_8_0, arg_8_1)
	if arg_8_1 then
		arg_8_0.filterType = arg_8_1
	end

	if arg_8_0.recommendType == var_0_4.Total then
		if arg_8_0.filterType == 1 then
			arg_8_0.data = arg_8_0.heroRecommend.totalRankList
		elseif arg_8_0.filterType == 2 then
			arg_8_0.data = arg_8_0.heroRecommend.notSxRankList
		elseif arg_8_0.filterType == 3 then
			arg_8_0.data = arg_8_0.heroRecommend.sxRankList
		end
	end

	if arg_8_0.recommendType == var_0_4.Sub then
		if arg_8_0.filterType == var_0_5.All then
			arg_8_0.data = arg_8_0.heroRecommend.totalSubRankList
		elseif arg_8_0.filterType == var_0_5.Collected then
			arg_8_0.data = arg_8_0.heroRecommend.collectedSubRankList
		elseif arg_8_0.filterType == var_0_5.UnCollected then
			arg_8_0.data = arg_8_0.heroRecommend.unCollectedSubRankList
		end
	end

	arg_8_0.scrollList:reload()
	arg_8_0:updateTypeContainer()
end

function var_0_0.scrollListDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		if arg_9_0.recommendType == var_0_4.Total then
			return math.ceil((#arg_9_0.data - 3) / var_0_2) + 1
		else
			return #table.keys(arg_9_0.data)
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0
		local var_9_1 = arg_9_0.scrollList:dequeueItem()

		if not var_9_1 then
			var_9_1 = arg_9_0.scrollList:newItem()
		else
			var_9_1:removeAllChildren(true)
		end

		local var_9_2

		if arg_9_0.recommendType == var_0_4.Total then
			if arg_9_3 == 1 then
				var_9_2 = arg_9_0:createTotalTop3Content()
			else
				var_9_2 = arg_9_0:createTotalContent(arg_9_3)
			end
		elseif arg_9_0.recommendType == var_0_4.Sub then
			var_9_2 = arg_9_0:createSubListContent(arg_9_3)
		end

		local var_9_3 = var_9_2:getHeight()

		var_9_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_1:setItemSize(880, var_9_3 + 10)
		var_9_1:addContent(var_9_2)
		var_9_2:setPosition(cc.p(440, var_9_3 / 2 + 10))

		return var_9_1
	end
end

function var_0_0.typeListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #var_0_7
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.typeList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.typeList:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		local var_10_2 = arg_10_0:createMainTypeContent(arg_10_3)
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4 + 10)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.createSubTypeContent(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = display.newNode()
	local var_11_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/main/sub_type_item.csb")
	local var_11_2 = var_11_1:getChildByName("container")
	local var_11_3 = var_0_7[arg_11_1]

	var_11_2:getChildByName("text_subtype"):setString(var_11_3.texts[arg_11_2])

	if arg_11_1 == arg_11_0.recommendType and arg_11_2 == arg_11_0.filterType then
		var_11_2:getChildByName("text_subtype"):setColor(cc.c4b(255, 80, 80))
		var_11_2:getChildByName("bg2"):setVisible(true)
		var_11_2:getChildByName("bg1"):setVisible(false)
	else
		var_11_2:getChildByName("bg2"):setVisible(false)
		var_11_2:getChildByName("bg1"):setVisible(true)
	end

	var_11_1:setTouchEnabled(true)
	var_11_1:setTouchSwallowEnabled(false)
	var_11_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			return true
		elseif arg_12_0.name == "ended" then
			if arg_11_0.filterType == arg_11_2 then
				return
			end

			arg_11_0:updateTypeContainer()
			arg_11_0:changeFilterType(arg_11_2)
		end
	end)
	var_11_1:addTo(var_11_0)
	var_11_1:setAnchorPoint(cc.p(0, 0))
	var_11_0:setContentSize(var_11_2:getContentSize())
	var_11_1:setName("source")

	return var_11_0
end

function var_0_0.createMainTypeContent(arg_13_0, arg_13_1)
	local var_13_0 = var_0_7[arg_13_1]
	local var_13_1 = display.newNode()
	local var_13_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/main/type_item.csb")

	var_13_2:addTo(var_13_1)
	var_13_2:setAnchorPoint(cc.p(0, 0))

	local var_13_3 = var_13_2:getChildByName("container")

	xyd.AssetLoader.get():loadSprite("windows/hero_recommend/main/" .. var_13_0.icon):addTo(var_13_3:getChildByName("text_pos"))

	if arg_13_0.recommendType == arg_13_1 then
		var_13_3:getChildByName("recommend_btn1"):setVisible(false)
		var_13_3:getChildByName("recommend_btn2"):setVisible(true)
	else
		var_13_3:getChildByName("recommend_btn1"):setVisible(true)
		var_13_3:getChildByName("recommend_btn2"):setVisible(false)
	end

	var_13_2:setTouchEnabled(true)
	var_13_2:setTouchSwallowEnabled(false)
	var_13_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			arg_13_0.orgPos = arg_14_0

			return true
		elseif arg_14_0.name == "ended" then
			if xyd.getDistance(arg_14_0, arg_13_0.orgPos) > 5 then
				return
			end

			arg_13_0:swapRecommendType(arg_13_1)
			arg_13_0:updateTypeContainer()
		end
	end)

	local var_13_4 = 60

	if arg_13_0.recommendType == arg_13_1 and arg_13_0.isExtended then
		for iter_13_0 = 1, #var_13_0.texts do
			var_13_4 = var_13_4 + 65

			local var_13_5 = arg_13_0:createSubTypeContent(arg_13_1, iter_13_0)

			var_13_5:addTo(var_13_1)
			var_13_5:setAnchorPoint(cc.p(0.5, 0))
			var_13_5:setPositionY((#var_13_0.texts - iter_13_0) * 65)
			var_13_5:setPositionX(var_13_3:getContentSize().width / 2)
		end
	end

	var_13_1:setContentSize(var_13_3:getContentSize().width, var_13_4)
	var_13_2:setPositionY(var_13_4 - 60)

	return var_13_1
end

function var_0_0.createTotalTop3Content(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.data
	local var_15_1 = display.newNode()
	local var_15_2 = 50
	local var_15_3 = 10
	local var_15_4 = 250

	var_15_1:setContentSize(880, 400)

	for iter_15_0 = 1, 3 do
		if iter_15_0 <= #var_15_0 then
			local var_15_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/main/top3_item.csb")
			local var_15_6 = var_15_5:getChildByName("container")

			var_15_5:addTo(var_15_1)
			var_15_5:setAnchorPoint(cc.p(0, 0))
			var_15_5:setPosition(cc.p(var_15_2, var_15_3))

			var_15_2 = var_15_2 + var_15_4

			local var_15_7 = var_15_0[iter_15_0].table_id
			local var_15_8 = var_15_0[iter_15_0].recommend_score
			local var_15_9 = xyd.AssetLoader.get():loadSprite("windows/hero_recommend/main/circle" .. iter_15_0 .. ".png")

			var_15_9:setAnchorPoint(cc.p(0.5, 0))
			var_15_9:addTo(var_15_6:getChildByName("model_pos"))
			var_15_9:setPositionY(0)

			local var_15_10 = var_0_3.new()

			var_15_10:populateWithTableID(var_15_7)

			local var_15_11 = var_15_10:getTableID()
			local var_15_12 = var_15_10:getHeroModel()

			var_15_12:addTo(var_15_6:getChildByName("model_pos"))
			var_15_12:setScale(0.8)
			var_15_6:getChildByName("score_txt"):setString(var_15_8)
			var_15_6:getChildByName("name_txt"):setString(var_15_10:getName())
			arg_15_0:getRankIcon(var_15_0[iter_15_0].rank):addTo(var_15_6:getChildByName("rank_pos"))

			local var_15_13 = var_15_10:getHeroType()
			local var_15_14
			local var_15_15 = var_15_13 == xyd.HeroType.WISE and "windows/hero_recommend/main/wise_2.png" or var_15_13 == xyd.HeroType.STRENGTH and "windows/hero_recommend/main/strength_2.png" or "windows/hero_recommend/main/agile_2.png"
			local var_15_16 = xyd.AssetLoader.get():loadSprite(var_15_15)

			var_15_16:addTo(var_15_6:getChildByName("name_bg"))
			var_15_16:setPositionY(var_15_6:getChildByName("name_bg"):getContentSize().height / 2)
			var_15_16:setScale(0.7)
			var_15_5:setTouchEnabled(true)
			var_15_5:setTouchSwallowEnabled(false)
			var_15_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
				if arg_16_0.name == "began" then
					return true
				elseif arg_16_0.name == "ended" and not arg_15_0.scrollViewMoved_ then
					arg_15_0.heroRecommend:toRecommendDetailWindow(var_15_7)
				end
			end)
		end
	end

	return var_15_1
end

function var_0_0.createTotalContent(arg_17_0, arg_17_1)
	local var_17_0 = display.newNode()
	local var_17_1 = 30
	local var_17_2 = 5
	local var_17_3 = 140

	var_17_0:setContentSize(880, 170)

	local var_17_4 = arg_17_0.data

	for iter_17_0 = 1, var_0_2 do
		local var_17_5 = (arg_17_1 - 2) * var_0_2 + 3 + iter_17_0

		if var_17_5 <= #var_17_4 then
			local var_17_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/main/recommend_item.csb")
			local var_17_7 = var_17_6:getChildByName("container")

			var_17_6:addTo(var_17_0)
			var_17_6:setAnchorPoint(cc.p(0, 0))
			var_17_6:setPosition(cc.p(var_17_1, var_17_2))

			var_17_1 = var_17_1 + var_17_3

			local var_17_8 = var_17_4[var_17_5].table_id
			local var_17_9 = var_17_4[var_17_5].recommend_score
			local var_17_10 = var_0_3.new()

			var_17_10:populateWithTableID(var_17_8)
			var_17_7:getChildByName("name_txt"):setString(var_17_10:getName())
			var_17_7:getChildByName("score_txt"):setString(var_17_9)
			xyd.setAvatarBorder(var_17_10, var_17_7:getChildByName("icon_container"))
			arg_17_0:getRankIcon(var_17_4[var_17_5].rank):addTo(var_17_7:getChildByName("rank_pos"))
			var_17_6:setTouchEnabled(true)
			var_17_6:setTouchSwallowEnabled(false)
			var_17_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
				if arg_18_0.name == "began" then
					return true
				elseif arg_18_0.name == "ended" and not arg_17_0.scrollViewMoved_ then
					arg_17_0.heroRecommend:toRecommendDetailWindow(var_17_8)
				end
			end)
		end
	end

	return var_17_0
end

function var_0_0.getRankIcon(arg_19_0, arg_19_1)
	if arg_19_1 <= 3 then
		local var_19_0 = xyd.AssetLoader.get():loadSprite("windows/single_day/rank/" .. arg_19_1 .. ".png")

		var_19_0:setAnchorPoint(cc.p(0, 0.5))

		return var_19_0
	else
		local var_19_1 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

		var_19_1:setString(arg_19_1)
		var_19_1:setAnchorPoint(cc.p(0, 0.5))
		var_19_1:setLocalZOrder(20)

		return var_19_1
	end
end

function var_0_0.createSubListContent(arg_20_0, arg_20_1)
	local var_20_0 = table.keys(arg_20_0.data)[arg_20_1]
	local var_20_1 = arg_20_0.data[var_20_0]
	local var_20_2 = display.newNode()
	local var_20_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/main/recommend_sub_item.csb")
	local var_20_4 = var_20_3:getChildByName("container")
	local var_20_5 = 0
	local var_20_6 = 0
	local var_20_7 = 110

	for iter_20_0 = 1, 5 do
		if iter_20_0 <= #var_20_1 then
			local var_20_8 = display.newNode()

			var_20_8:setContentSize(100, 100)
			var_20_8:setAnchorPoint(cc.p(0, 0.5))
			var_20_8:addTo(var_20_4:getChildByName("item_pos"))
			var_20_8:setPosition(cc.p(var_20_5, var_20_6))

			var_20_5 = var_20_5 + var_20_7

			local var_20_9 = var_20_1[iter_20_0]
			local var_20_10 = var_20_9.table_id
			local var_20_11 = var_0_3.new()

			var_20_11:populateWithTableID(var_20_10)
			xyd.setAvatarBorder(var_20_11, var_20_8)

			local var_20_12 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

			var_20_12:setString(var_20_9.rank)
			var_20_12:setAnchorPoint(cc.p(0, 1))
			var_20_12:addTo(var_20_8)
			var_20_12:setPosition(cc.p(0, 100))
			var_20_12:setLocalZOrder(20)
			var_20_12:setScale(0.8)
			var_20_8:setTouchEnabled(true)
			var_20_8:setTouchSwallowEnabled(false)
			var_20_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
				if arg_21_0.name == "began" then
					return true
				elseif arg_21_0.name == "ended" and not arg_20_0.scrollViewMoved_ then
					arg_20_0.heroRecommend:toRecommendDetailWindow(var_20_10)
				end
			end)
		end
	end

	var_20_4:getChildByName("detail_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_22_0 = {
				type = var_20_0,
				rank_data = var_20_1
			}

			xyd.WindowManager.get():openWindow("hero_recommend_rank", var_22_0)
		end
	end)

	local var_20_13 = xyd.tables.heroRecommendType:icon(tonumber(var_20_0))

	if var_20_13 ~= "" then
		local var_20_14 = xyd.AssetLoader.get():loadSprite(var_20_13)

		var_20_14:addTo(var_20_4:getChildByName("item_pos"))
		var_20_14:setPosition(cc.p(-70, 0))
		var_20_14:setScale(0.6)
	end

	local var_20_15 = xyd.tables.heroRecommendType:nameIcon1(tonumber(var_20_0))

	if var_20_15 ~= "" then
		local var_20_16 = xyd.AssetLoader.get():loadSprite(var_20_15)

		var_20_16:addTo(var_20_4:getChildByName("item_pos"))
		var_20_16:setPosition(cc.p(-70, -30))
	end

	var_20_3:addTo(var_20_2)
	var_20_3:setAnchorPoint(cc.p(0, 0))
	var_20_2:setContentSize(var_20_4:getContentSize())
	var_20_3:setName("source")

	return var_20_2
end

function var_0_0.scrollListener(arg_23_0, arg_23_1)
	if arg_23_1.name == "began" then
		arg_23_0.scrollViewMoved_ = false
		arg_23_0.prevY_ = arg_23_1.y
	elseif arg_23_1.name == "moved" and 5 <= math.abs(arg_23_1.y - arg_23_0.prevY_) then
		arg_23_0.scrollViewMoved_ = true
	end
end

return var_0_0
