local var_0_0 = class("SummerExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySummerGoldfishShop
local var_0_3 = {
	10,
	30,
	80
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(true)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("SUMMER_TEXT_1"))
	arg_3_0:updatePoints()
end

function var_0_0.scrollListDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return var_0_2:count()
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

function var_0_0.updatePoints(arg_5_0)
	local var_5_0 = arg_5_0.summer.details.goldfish_info

	arg_5_0:nodeByName("point_txt"):setString(string.format(var_0_1:translation("CURRENT_POINT_TEXT"), var_5_0.point))
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()

	if var_0_2:vipLimit(arg_6_1) > arg_6_0.selfPlayer.vip then
		return var_6_0
	end

	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/summer/fish/exchange_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3 = xyd.tables.item
	local var_6_4 = var_0_2:item(arg_6_1)
	local var_6_5 = var_0_2:num(arg_6_1)
	local var_6_6 = var_0_2:buyLimit(arg_6_1)
	local var_6_7 = var_0_2:pt(arg_6_1)
	local var_6_8 = var_6_3:name(var_6_4) .. "x" .. var_6_5

	if var_6_6 > 0 then
		var_6_2:getChildByName("limit_txt"):setString(string.format(var_0_1:translation("FIREWORK_TEXT_14"), var_6_6))
	else
		var_6_2:getChildByName("limit_txt"):setString("")
	end

	var_6_2:getChildByName("name_txt"):setString(var_6_8)

	local var_6_9 = import("app.common.ui.SplitLine")
	local var_6_10 = var_6_2:getChildByName("line")

	var_6_9.new({
		size = var_6_10:getWidth()
	}):addTo(var_6_10)

	local var_6_11 = var_6_3:desc1(var_6_4)

	if var_6_3:type(var_6_4) == xyd.ItemType.STONE then
		local var_6_12 = xyd.tables.item:heroID(var_6_4)
		local var_6_13 = xyd.tables.hero:name(var_6_12)
		local var_6_14 = xyd.tables.hero:initialStar(var_6_12)
		local var_6_15 = var_0_3[var_6_14]

		if xyd.isSuperHero(var_6_12) then
			var_6_11 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_6_13)
		else
			var_6_11 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_6_15, var_6_13, var_6_13)
		end
	end

	var_6_2:getChildByName("desc_txt"):setString(var_6_11)
	var_6_2:getChildByName("only_once_text"):setString(tostring(var_6_7) .. var_0_1:translation("POINT_TEXT2"))
	xyd.setItemBorder(var_6_2:getChildByName("icon_container"), var_6_4, false, false, var_6_5)

	local var_6_16 = true
	local var_6_17 = arg_6_0.summer.details.goldfish_info

	if var_6_6 > 0 and var_6_17.buy_info[tostring(arg_6_1)] and var_6_6 <= var_6_17.buy_info[tostring(arg_6_1)] then
		var_6_16 = false
	elseif var_6_7 > var_6_17.point then
		var_6_16 = false
	end

	local var_6_18 = var_6_2:getChildByName("exchange_btn")

	var_6_18:getChildByName("exchange_txt"):setString(var_0_1:translation("EXCHANGE"))

	if not var_6_16 then
		var_6_18:setTouchEnabled(false)
		var_6_18:setBright(false)
		var_6_18:getChildByName("exchange_txt"):setColor(cc.c3b(92, 92, 92))
	else
		var_6_18:setTouchEnabled(true)
		var_6_18:setBright(true)
		var_6_18:getChildByName("exchange_txt"):setColor(cc.c3b(123, 55, 0))
	end

	var_6_18:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				award_id = arg_6_1
			}

			arg_6_0.summer:buyGoldfishItem(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_6_0.selfPlayer:handleRewards(arg_8_1.awards)
					arg_6_0.scrollList:refreshList()
					arg_6_0:updatePoints()
				end
			end)
		end
	end)
	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.scrollListener(arg_9_0, arg_9_1)
	if arg_9_1.name == "began" then
		arg_9_0.scrollViewMoved_ = false
		arg_9_0.prevY_ = arg_9_1.y
	elseif arg_9_1.name == "moved" and 5 <= math.abs(arg_9_1.y - arg_9_0.prevY_) then
		arg_9_0.scrollViewMoved_ = true
	end
end

return var_0_0
