local var_0_0 = class("HeroRecommendRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 7
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.type = arg_1_2.type
	arg_1_0.rankData = arg_1_2.rank_data
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("desc_text"):setString(var_0_1:translation("HERO_RECOMMEND_SELECT_TEXT"))

	local var_3_0 = string.format(var_0_1:translation("RECOMMEND_RANK_TITLE_TEXT"), xyd.tables.heroRecommendType:name(tonumber(arg_3_0.type)))

	arg_3_0:nodeByName("title_txt"):setString(var_3_0)

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_1 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return math.ceil(#arg_4_0.rankData / var_0_2)
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_0.scrollList:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_0.scrollList:newItem()
		else
			var_4_1:removeAllChildren(true)
		end

		local var_4_2 = arg_4_0:createListContent(arg_4_3)
		local var_4_3 = var_4_2:getWidth()
		local var_4_4 = var_4_2:getHeight()

		var_4_1:setItemSize(var_4_3, var_4_4)
		var_4_1:addContent(var_4_2)

		return var_4_1
	end
end

function var_0_0.createListContent(arg_5_0, arg_5_1)
	local var_5_0 = display.newNode()
	local var_5_1 = 20
	local var_5_2 = 5
	local var_5_3 = 110

	var_5_0:setContentSize(800, 100)

	local var_5_4 = arg_5_0.totalRankList

	for iter_5_0 = 1, var_0_2 do
		if (arg_5_1 - 1) * var_0_2 + iter_5_0 <= #arg_5_0.rankData then
			local var_5_5 = arg_5_0.rankData[(arg_5_1 - 1) * var_0_2 + iter_5_0]
			local var_5_6 = display.newNode()

			var_5_6:setContentSize(90, 90)
			var_5_6:setAnchorPoint(cc.p(0, 0))
			var_5_6:addTo(var_5_0)
			var_5_6:setPosition(cc.p(var_5_1, var_5_2))

			var_5_1 = var_5_1 + var_5_3

			local var_5_7 = var_5_5.table_id
			local var_5_8 = var_0_3.new()

			var_5_8:populateWithTableID(var_5_7)
			xyd.setAvatarBorder(var_5_8, var_5_6)

			local var_5_9 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

			var_5_9:setString(var_5_5.rank)
			var_5_9:setAnchorPoint(cc.p(0, 1))
			var_5_9:addTo(var_5_6)
			var_5_9:setPosition(cc.p(0, 90))
			var_5_9:setLocalZOrder(20)
			var_5_9:setScale(0.8)
			var_5_6:setTouchEnabled(true)
			var_5_6:setTouchSwallowEnabled(false)
			var_5_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
				if arg_6_0.name == "began" then
					return true
				elseif arg_6_0.name == "ended" and not arg_5_0.scrollViewMoved_ then
					arg_5_0.heroRecommend:toRecommendDetailWindow(var_5_7)
				end
			end)
		end
	end

	return var_5_0
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" and 5 <= math.abs(arg_7_1.y - arg_7_0.prevY_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

return var_0_0
