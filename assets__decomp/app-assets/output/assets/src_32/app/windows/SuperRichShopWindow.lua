local var_0_0 = class("SuperRichShopWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityRichShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.shopIds = var_0_3:ids()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_ticket_num"):enableOutline(cc.c4b(195, 115, 0, 255), 2)

	local var_4_0 = arg_4_0:nodeByName("scroll")
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width, var_4_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
	arg_4_0:updateAsset()
end

function var_0_0.willClose(arg_5_0)
	var_0_0.super.willClose()
	arg_5_0:showMainTop(true)
end

function var_0_0.showMainTop(arg_6_0, arg_6_1)
	local var_6_0 = xyd.WindowManager.get():getWindow("garden")

	if var_6_0 and not tolua.isnull(var_6_0) then
		var_6_0:nodeByName("top_container"):setVisible(arg_6_1)
	end
end

function var_0_0.updateAsset(arg_7_0)
	arg_7_0:nodeByName("txt_ticket_num"):setString(arg_7_0.superRich.baseInfo.stamps)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" then
		local var_8_0 = 3

		if var_8_0 <= math.abs(arg_8_1.y - arg_8_0.prevY_) or var_8_0 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
			arg_8_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.shopIds
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.list:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.list:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = 260
		local var_9_2 = 403

		var_9_0:setItemSize(var_9_1, var_9_2)

		local var_9_3 = display.newNode()

		var_9_3:setContentSize(var_9_1, var_9_2)
		arg_9_0:createExchangeItem(var_9_3, arg_9_3)
		var_9_0:addContent(var_9_3)

		return var_9_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.createExchangeItem(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_0.shopIds[arg_10_2]
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/zillionaire/shop/exchange_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")
	local var_10_3 = var_0_3:item(var_10_0)
	local var_10_4 = var_0_3:itemNum(var_10_0)
	local var_10_5 = var_0_3:buyLimit(var_10_0)

	var_10_2:getChildByName("name_txt"):setString(xyd.tables.item:name(var_10_3))
	var_10_2:getChildByName("price_txt"):setString(var_0_3:cost(var_10_0))
	var_10_2:getChildByName("name_txt"):enableOutline(cc.c4b(222, 92, 37, 255), 2)

	if var_10_5 >= 0 then
		var_10_2:getChildByName("txt_limit"):setString(string.format(var_0_1:translation("SUPER_RICH_BUY_LIMIT_TEXT"), arg_10_0.superRich.baseInfo.exchange_times[var_10_0] .. "/" .. var_10_5))
	else
		var_10_2:getChildByName("txt_limit"):setVisible(false)
	end

	local var_10_6 = var_0_3:costType(var_10_0)

	if var_10_6 == 2 then
		local var_10_7 = xyd.tables.ecoType:getEcoPath("crystal")

		var_10_2:getChildByName("dice_small"):setSpriteFrame(xyd.AssetLoader.get():loadSprite(var_10_7):getSpriteFrame())
	end

	xyd.setItemAndAddTips(var_10_2:getChildByName("icon_container"), var_10_3, var_10_4)
	var_10_2:getChildByName("buy_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				idx = arg_10_2
			}

			if var_10_5 >= 0 and var_10_5 <= arg_10_0.superRich.baseInfo.exchange_times[var_10_0] then
				local var_11_1 = var_0_1:translation("SUPER_RICH_BUY_LIMIT_TIPS")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_1
				})

				return
			elseif var_10_6 == 1 and arg_10_0.superRich.baseInfo.stamps < var_0_3:cost(var_10_0) then
				local var_11_2 = var_0_1:translation("SUPER_RICH_STAMPS_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_2
				})

				return
			elseif var_10_6 == 2 and arg_10_0.selfPlayer.crystal < var_0_3:cost(var_10_0) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_12_0 = {}

					var_12_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
				end, nil, nil, arg_10_0.colorMode)
			end

			local function var_11_3()
				arg_10_0.superRich:monoplyShopBuy(var_11_0, function(arg_14_0, arg_14_1)
					if arg_14_0 == xyd.error.OK then
						arg_10_0.superRich.baseInfo.exchange_times = arg_14_1.exchange_times

						arg_10_0:updateAsset()
						arg_10_0.list:refreshList()
					end
				end)
			end

			if var_10_6 == 2 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("ACTIVITY_SUPER_RICH_BUY_ALERT"), var_0_3:cost(var_10_0), var_10_4, xyd.tables.item:name(var_10_3)), function()
					var_11_3()
				end, nil, nil, arg_10_0.colorMode)
			else
				var_11_3()
			end
		end
	end)
	var_10_1:addTo(arg_10_1)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	arg_10_1:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return arg_10_1
end

return var_0_0
