local var_0_0 = class("Sakura2018ExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySakura3Shop
local var_0_3 = {
	10,
	30,
	80
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA2018)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super.didClose(arg_3_0, arg_3_1)

	local var_3_0 = xyd.WindowManager.get():getWindow("sakura2018_fruit_factory")

	if var_3_0 and not tolua.isnull(var_3_0) then
		var_3_0:updatePoints()
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setBounceable(true)
	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()
	arg_4_0:updatePoints()
end

function var_0_0.scrollListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_0_2:count()
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.scrollList:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.scrollList:newItem()
		else
			var_5_1:removeAllChildren(true)
		end

		local var_5_2 = arg_5_0:createListContent(arg_5_3)
		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.updatePoints(arg_6_0)
	local var_6_0 = arg_6_0.sakura.details.base_info

	arg_6_0:nodeByName("own_score_txt"):setString(var_6_0.satisfy)
	arg_6_0:nodeByName("own_score_text"):setString(var_0_1:translation("SAKURA2018_OWN_POINT_TXT"))
end

function var_0_0.createListContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/sakura2018/exchange/exchange_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = xyd.tables.item
	local var_7_4 = var_0_2:itemId(arg_7_1)
	local var_7_5 = var_0_2:itemNum(arg_7_1)
	local var_7_6 = var_0_2:buyLimit(arg_7_1)
	local var_7_7 = var_0_2:cost(arg_7_1)
	local var_7_8 = var_7_3:name(var_7_4) .. "x" .. var_7_5

	var_7_2:getChildByName("name_txt"):setString(var_7_8)

	local var_7_9 = var_7_3:desc1(var_7_4)
	local var_7_10 = var_7_3:type(var_7_4)

	if var_7_10 == xyd.ItemType.STONE then
		local var_7_11 = xyd.tables.item:heroID(var_7_4)
		local var_7_12 = xyd.tables.hero:name(var_7_11)
		local var_7_13 = xyd.tables.hero:initialStar(var_7_11)
		local var_7_14 = var_0_3[var_7_13]

		if xyd.isSuperHero(var_7_11) then
			var_7_9 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_7_12)
		else
			var_7_9 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_7_14, var_7_12, var_7_12)
		end
	elseif var_7_10 == -1 then
		var_7_9 = xyd.tables.hero:getDes(var_7_4)
	end

	var_7_2:getChildByName("desc_txt"):setString(var_7_9)
	var_7_2:getChildByName("score_txt"):setString(string.format(var_0_1:translation("SAKURA2018_OWN_POINT_TXT1"), var_7_7))
	xyd.setItemBorder(var_7_2:getChildByName("icon_container"), var_7_4, false, false, var_7_5)

	local var_7_15 = true
	local var_7_16 = arg_7_0.sakura.details.buy_times
	local var_7_17 = arg_7_0.sakura.details.base_info

	var_7_2:getChildByName("times_txt"):setString("")

	if var_7_6 > 0 then
		var_7_2:getChildByName("times_txt"):setString(string.format(var_0_1:translation("SAKURA2018_EXCHANGE_LIMIT_TXT"), var_7_16[tostring(arg_7_1)] or 0, var_7_6))
	end

	if var_7_6 > 0 and var_7_16[tostring(arg_7_1)] and var_7_6 <= var_7_16[tostring(arg_7_1)] then
		var_7_15 = false
	elseif var_7_7 > var_7_17.satisfy then
		var_7_15 = false
	end

	local var_7_18 = var_7_2:getChildByName("exchange_btn")

	if not var_7_15 then
		var_7_18:setTouchEnabled(false)
		var_7_18:setBright(false)
		var_7_18:getChildByName("exchange_txt"):setVisible(false)
	end

	var_7_18:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			;({}).award_id = arg_7_1

			arg_7_0.activitiesModel:getActivityReward(xyd.Activities.Sakura2018, arg_7_1, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_7_0.sakura:handleResponse(arg_9_1)
					arg_7_0.selfPlayer:handleRewards(arg_9_1.awards)
					arg_7_0.scrollList:refreshList()
					arg_7_0:updatePoints()
				end
			end)
		end
	end)
	var_7_1:addTo(var_7_0)
	var_7_1:setAnchorPoint(cc.p(0, 0))
	var_7_0:setContentSize(var_7_2:getContentSize())
	var_7_1:setName("source")

	return var_7_0
end

function var_0_0.scrollListener(arg_10_0, arg_10_1)
	if arg_10_1.name == "began" then
		arg_10_0.scrollViewMoved_ = false
		arg_10_0.prevY_ = arg_10_1.y
	elseif arg_10_1.name == "moved" and 5 <= math.abs(arg_10_1.y - arg_10_0.prevY_) then
		arg_10_0.scrollViewMoved_ = true
	end
end

return var_0_0
