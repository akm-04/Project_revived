local var_0_0 = class("ActivityConsumeExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityConsumePoolExchange
local var_0_4 = xyd.tables.gift
local var_0_5 = {
	10,
	30,
	80
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_2.details
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("exchange_title"):setString(var_0_2:translation("SUMMER_TEXT_1"))

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
		return var_0_3:count()
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
	arg_6_0:nodeByName("point_txt"):setString(string.format(var_0_2:translation("CURRENT_POINT_TEXT"), arg_6_0.details.base_info.point))
end

function var_0_0.createListContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()
	local var_7_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1168/exchange/exchange_item.csb")
	local var_7_2 = var_7_1:getChildByName("container")
	local var_7_3 = var_0_3:gift(arg_7_1)
	local var_7_4 = var_0_4:items(var_7_3)
	local var_7_5 = var_0_4:itemNum(var_7_3)
	local var_7_6 = xyd.tables.item
	local var_7_7 = var_7_4[1]
	local var_7_8 = var_7_5[1]
	local var_7_9 = var_0_3:buyLimit(arg_7_1)
	local var_7_10 = var_0_3:pt(arg_7_1)
	local var_7_11 = arg_7_0.details.base_info.buy_limit
	local var_7_12 = var_7_6:name(var_7_7) .. "x" .. var_7_8

	var_7_2:getChildByName("name_txt"):setString(var_7_12)

	if var_7_9 > 0 then
		var_7_2:getChildByName("only_once_text"):setString(string.format(var_0_2:translation("LOTTERY_CONSUME_TEXT7"), var_7_9, var_7_11[arg_7_1]))
		var_7_2:getChildByName("only_once_text"):setPositionX(var_7_2:getChildByName("name_txt"):getPositionX() + var_7_2:getChildByName("name_txt"):getContentSize().width + 10)
	else
		var_7_2:getChildByName("only_once_text"):setString("")
	end

	local var_7_13 = var_0_1.new({
		size = 410
	})

	var_7_13:addTo(var_7_2)
	var_7_13:setAnchorPoint(0.5, 0.5)
	var_7_13:setPosition(cc.p(333, 85))

	local var_7_14 = var_7_6:desc1(var_7_7)

	if var_7_6:type(var_7_7) == xyd.ItemType.STONE then
		local var_7_15 = xyd.tables.item:heroID(var_7_7)
		local var_7_16 = xyd.tables.hero:name(var_7_15)
		local var_7_17 = xyd.tables.hero:initialStar(var_7_15)
		local var_7_18 = var_0_5[var_7_17]

		if xyd.isSuperHero(var_7_15) then
			var_7_14 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_7_16)
		else
			var_7_14 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_7_18, var_7_16, var_7_16)
		end
	end

	var_7_2:getChildByName("desc_txt"):setString(var_7_14)
	var_7_2:getChildByName("cost_txt"):setString(tostring(var_7_10) .. var_0_2:translation("POINT_TEXT2"))
	xyd.setSpecialItemBorderNewUI(var_7_2:getChildByName("icon_container"), var_7_7, false, false, var_7_8)

	if var_0_3:rare(arg_7_1) == 1 then
		local var_7_19 = xyd.AssetLoader.get():loadSprite("windows/activities/1168/exchange/most_rare.png")

		var_7_19:setScale(0.85)
		var_7_19:addTo(var_7_2:getChildByName("icon_container"))
		var_7_19:setAnchorPoint(cc.p(0, 1))
		var_7_19:setPosition(0, 85)
	end

	local var_7_20 = true

	if var_7_9 > 0 and var_7_11[arg_7_1] and var_7_9 <= var_7_11[arg_7_1] then
		var_7_20 = false
	elseif var_7_10 > arg_7_0.details.base_info.point then
		var_7_20 = false
	end

	if var_0_3:rare(arg_7_1) == 1 and arg_7_0.details.base_info.special_times > 0 then
		var_7_20 = false
	end

	local var_7_21 = var_7_2:getChildByName("exchange_btn")

	var_7_21:getChildByName("exchange_gray"):setString(xyd.tables.translation:translation("EXCHANGE"))
	var_7_21:getChildByName("exchange_txt"):setString(xyd.tables.translation:translation("EXCHANGE"))
	var_7_21:getChildByName("exchange_gray"):setVisible(false)
	var_7_21:getChildByName("exchange_txt"):setVisible(false)

	if not var_7_20 then
		var_7_21:setTouchEnabled(false)
		var_7_21:setBright(false)
		var_7_21:getChildByName("exchange_gray"):setVisible(true)
	else
		var_7_21:getChildByName("exchange_txt"):setVisible(true)
	end

	var_7_21:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_7_21:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_7_21:setScale(1)
			xyd.playButtonSound()

			local var_8_0 = {
				id = arg_7_1
			}

			xyd.Backend.get():request(xyd.mid.ACTIVITY_CONSUME_EXCHANGE, var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					if arg_9_1.awards then
						arg_7_0.selfPlayer:handleRewards(arg_9_1.awards)
					end

					if arg_9_1.base_info then
						arg_7_0.details.base_info = arg_9_1.base_info

						arg_7_0.scrollList:refreshList()
						arg_7_0:updatePoints()
					end
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
