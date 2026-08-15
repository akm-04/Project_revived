local var_0_0 = class("FourthAnniversaryMapShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityAnni4thMapShopTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.fourthAnni = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_1_0.shopIds = var_0_3:ids()
	arg_1_0.mapCoin = xyd.tables.misc:getValue("activity_anni4_campaign_shop_item")
	arg_1_0.shopInfo = arg_1_2
end

function var_0_0.updateAsset(arg_2_0)
	local var_2_0 = arg_2_0.selfPlayer:getBackpack():getItemNumByID(arg_2_0.mapCoin)

	arg_2_0:nodeByName("star_txt"):setString(var_2_0)
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer()
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("scroll")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0:nodeByName("star_txt"):enableOutline(cc.c4b(83, 175, 221, 255), 2)

	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.list:reload()
	arg_5_0:updateAsset()
end

function var_0_0.willClose(arg_6_0)
	var_0_0.super.willClose()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" then
		local var_7_0 = 3

		if var_7_0 <= math.abs(arg_7_1.y - arg_7_0.prevY_) or var_7_0 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
			arg_7_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.shopIds
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 269
		local var_8_2 = 429

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setContentSize(var_8_1, var_8_2)
		arg_8_0:createExchangeItem(var_8_3, arg_8_3)
		var_8_0:addContent(var_8_3)

		return var_8_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.createExchangeItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.shopIds[arg_9_2]
	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map_shop/exchange_item.csb")
	local var_9_2 = var_9_1:getChildByName("container")
	local var_9_3 = var_0_3:giftId(var_9_0)
	local var_9_4 = xyd.tables.gift:items(var_9_3)
	local var_9_5 = xyd.tables.gift:itemNum(var_9_3)
	local var_9_6 = var_0_3:limitNum(var_9_0)

	var_9_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_9_4[1]))
	var_9_2:getChildByName("price_txt"):setString(var_0_3:price(var_9_0))
	var_9_2:getChildByName("limit_txt"):enableOutline(cc.c4b(45, 152, 192, 255), 2)

	local function var_9_7()
		arg_9_0:updateAsset()
		var_9_2:getChildByName("limit_txt"):setString("(" .. (arg_9_0.shopInfo[tostring(var_9_0)] or 0) .. "/" .. var_9_6 .. ")")

		if arg_9_0.shopInfo[tostring(var_9_0)] == var_9_6 then
			var_9_2:getChildByName("exchange_btn"):setVisible(false)
		end
	end

	if var_9_6 > 0 then
		var_9_2:getChildByName("limit_txt"):setString("(" .. (arg_9_0.shopInfo[tostring(var_9_0)] or 0) .. "/" .. var_9_6 .. ")")
	else
		var_9_2:getChildByName("limit_txt"):setVisible(false)
	end

	if arg_9_0.shopInfo[tostring(var_9_0)] == var_9_6 then
		var_9_2:getChildByName("exchange_btn"):setVisible(false)
	end

	xyd.setItemAndAddTips(var_9_2:getChildByName("icon_container"), var_9_4[1], var_9_5[1])
	var_9_2:getChildByName("exchange_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_9_0.selfPlayer:getBackpack():getItemNumByID(arg_9_0.mapCoin) < var_0_3:price(var_9_0) then
				local var_11_0 = var_0_1:translation("FOURTH_ANNI_MAP_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			end

			local var_11_1 = {
				id = var_9_0,
				shopInfo = arg_9_0.shopInfo,
				callback = function(arg_12_0, arg_12_1)
					arg_9_0.shopInfo = arg_12_1.shop_buy_info

					var_9_7()
				end
			}

			xyd.WindowManager.get():openWindow("fourth_annni_map_sure_exchange", var_11_1)
		end
	end)
	var_9_1:addTo(arg_9_1)
	var_9_1:setAnchorPoint(cc.p(0, 0))
	arg_9_1:setContentSize(var_9_2:getContentSize())
	var_9_1:setName("source")

	return arg_9_1
end

return var_0_0
