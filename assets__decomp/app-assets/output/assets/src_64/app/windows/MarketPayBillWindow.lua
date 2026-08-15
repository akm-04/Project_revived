local var_0_0 = class("MarketPayBillWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.activitymarketitem
local var_0_4 = xyd.tables.activitymarketdiscount
local var_0_5 = {
	txt_pay = var_0_1:translation("ACTIVITY_MARKET_PAY"),
	txt_tips = var_0_1:translation("ACTIVITY_MARKET_TIPS4"),
	txt_restnum = var_0_1:translation("ACTIVITY_MARKET_TIPS5"),
	txt_reduce = var_0_1:translation("ACTIVITY_MARKET_TIPS6"),
	txt_usenum = var_0_1:translation("ACTIVITY_MARKET_TIPS7"),
	txt_empty = var_0_1:translation("ACTIVITY_MARKET_CART_EMPTY"),
	txt_pay_tips = var_0_1:translation("ACTIVITY_MARKET_PAY_TIPS"),
	txt_not_tickets = var_0_1:translation("ACTIVITY_MARKET_NOT_TICKETS"),
	txt_not_limit = var_0_1:translation("ACTIVITY_MARKET_NOT_ENOUGH")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.marketItemIds = var_0_3:ids()
	arg_1_0.marketDiscountIds = var_0_4:ids()
	arg_1_0.ticket = var_0_2:getValue("activity_market_item_id")
	arg_1_0.lastWinFunc = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list")

	var_2_0:removeAllChildren()

	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.itemList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.itemList_:setDelegate(handler(arg_2_0, arg_2_0.itemDelegate))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_5.txt_pay)
	xyd.Backend.get():request(xyd.mid.MARKET_GET_CART, nil, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK and arg_4_0.updateCart then
			arg_4_0:updateCart(arg_5_1)
			arg_4_0.itemList_:reload()
		end
	end)

	local var_4_0 = arg_4_0.backpack:getItemNumByID(arg_4_0.ticket)
	local var_4_1 = var_0_2:getValue("activity_market_discount_num")
	local var_4_2 = var_0_2:getValue("activity_market_item_num")

	arg_4_0.useNum = 0

	local var_4_3 = string.format(var_0_5.txt_usenum, arg_4_0.useNum, var_4_2)

	arg_4_0:nodeByName("txt_num"):setString(var_4_3)

	local var_4_4 = arg_4_0:nodeByName("btn_add")
	local var_4_5 = arg_4_0:nodeByName("btn_sub")

	var_4_4:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_4:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.ended or arg_6_1 == ccui.TouchEventType.canceled then
			var_4_4:setScale(1)

			if arg_4_0.useNum == var_4_2 or arg_4_0.useNum == var_4_0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5.txt_not_tickets
				})

				return
			end

			if not arg_4_0.canUseTicket then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5.txt_not_limit
				})

				return
			end

			arg_4_0.useNum = arg_4_0.useNum + 1
			var_4_3 = string.format(var_0_5.txt_usenum, arg_4_0.useNum, var_4_2)

			arg_4_0:nodeByName("txt_num"):setString(var_4_3)

			local var_6_0 = string.format(var_0_5.txt_restnum, var_4_0 - arg_4_0.useNum)

			arg_4_0:nodeByName("txt_rest"):setString(var_6_0)

			local var_6_1 = string.format(var_0_5.txt_reduce, arg_4_0.reduce + arg_4_0.useNum * var_4_1)

			arg_4_0:nodeByName("txt_have_reduce"):setString(var_6_1)
			arg_4_0:nodeByName("txt_cost"):setString(arg_4_0.cost - var_4_1 * arg_4_0.useNum)
		end
	end)
	var_4_5:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			var_4_5:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.ended or arg_7_1 == ccui.TouchEventType.canceled then
			var_4_5:setScale(1)

			if arg_4_0.useNum == 0 then
				return
			end

			arg_4_0.useNum = arg_4_0.useNum - 1
			var_4_3 = string.format(var_0_5.txt_usenum, arg_4_0.useNum, var_4_2)

			arg_4_0:nodeByName("txt_num"):setString(var_4_3)

			local var_7_0 = string.format(var_0_5.txt_restnum, var_4_0 - arg_4_0.useNum)

			arg_4_0:nodeByName("txt_rest"):setString(var_7_0)

			local var_7_1 = string.format(var_0_5.txt_reduce, arg_4_0.reduce + arg_4_0.useNum * var_4_1)

			arg_4_0:nodeByName("txt_have_reduce"):setString(var_7_1)
			arg_4_0:nodeByName("txt_cost"):setString(arg_4_0.cost - var_4_1 * arg_4_0.useNum)
		end
	end)

	local var_4_6 = arg_4_0:nodeByName("btn_check_out")

	arg_4_0:nodeByName("txt_check_out"):setString(var_0_5.txt_pay)
	var_4_6:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_4_6:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended or arg_8_1 == ccui.TouchEventType.canceled then
			var_4_6:setScale(1)

			if arg_4_0.canBuy then
				local var_8_0 = arg_4_0.cost - var_4_1 * arg_4_0.useNum

				if arg_4_0.cost and var_8_0 > arg_4_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_9_0 = {}

						var_9_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
					end, nil, nil, arg_4_0.colorMode)
				else
					local var_8_1 = string.format(var_0_5.txt_pay_tips, arg_4_0.cost - var_4_1 * arg_4_0.useNum)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_1, function()
						local var_10_0 = {}

						if arg_4_0.useNum == 0 then
							var_10_0 = nil
						else
							var_10_0.coupon_ids = {}
							var_10_0.coupon_nums = {}

							table.insert(var_10_0.coupon_ids, arg_4_0.ticket)
							table.insert(var_10_0.coupon_nums, arg_4_0.useNum)
						end

						xyd.Backend.get():request(xyd.mid.MARKET_PAY_THE_BILL, var_10_0, function(arg_11_0, arg_11_1)
							if arg_11_0 == xyd.error.OK then
								if arg_11_1 and arg_11_1.awards then
									arg_4_0.selfPlayer:handleRewards(arg_11_1.awards)
								end

								arg_4_0.backpack:setItemNumByID(arg_4_0.ticket, var_4_0 - arg_4_0.useNum)

								arg_4_0.useNum = 0
								var_4_3 = string.format(var_0_5.txt_usenum, arg_4_0.useNum, var_4_2)

								arg_4_0:nodeByName("txt_num"):setString(var_4_3)
								arg_4_0:updateCart(arg_11_1)
								arg_4_0.itemList_:reload()
								arg_4_0.lastWinFunc.update(arg_11_1)
							elseif arg_11_0 == xyd.error.ERROR and arg_11_1 and arg_11_1.extra_data then
								arg_4_0:updateCart(arg_11_1)
								arg_4_0.itemList_:reload()
								arg_4_0.lastWinFunc.update(arg_11_1)
							end
						end)
					end, nil, nil, arg_4_0.colorMode)
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5.txt_empty
				})
			end
		end
	end)
end

function var_0_0.itemDelegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.showItems
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0
		local var_12_1 = arg_12_1:dequeueItem()

		if not var_12_1 then
			var_12_1 = arg_12_1:newItem()
		else
			var_12_1:removeAllChildren(false)
		end

		local var_12_2 = arg_12_0.showItems[arg_12_3]
		local var_12_3 = arg_12_0:createShowNode(var_12_2, arg_12_3)
		local var_12_4 = var_12_3:getChildByName("container"):getContentSize()
		local var_12_5 = display.newNode()

		var_12_5:setContentSize(var_12_4.width, var_12_4.height)
		var_12_3:addTo(var_12_5)
		var_12_3:setPosition(cc.p(0, 0))
		var_12_1:addContent(var_12_5)
		var_12_1:setItemSize(var_12_4.width, var_12_4.height)

		return var_12_1
	end
end

function var_0_0.createShowNode(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1185/item_bil.csb")
	local var_13_1 = var_13_0:getChildByName("container")
	local var_13_2 = var_13_1:getChildByName("icon")

	xyd.setItemAndAddTips(var_13_2, arg_13_1.itemId, arg_13_1.num)

	local var_13_3 = arg_13_1.name .. "  x  " .. arg_13_1.buyNum

	var_13_1:getChildByName("txt_name"):setString(var_13_3)

	local var_13_4 = arg_13_1.price * arg_13_1.buyNum

	var_13_1:getChildByName("txt_price"):setString(var_13_4)

	local var_13_5 = arg_13_0.backpack:getItemNumByID(arg_13_0.ticket)
	local var_13_6 = var_0_2:getValue("activity_market_discount_num")
	local var_13_7 = var_0_2:getValue("activity_market_item_num")
	local var_13_8 = var_13_1:getChildByName("btn_delete")

	var_13_8:addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			var_13_8:setScale(0.9)
		elseif arg_14_1 == ccui.TouchEventType.ended or arg_14_1 == ccui.TouchEventType.canceled then
			var_13_8:setScale(1)

			local var_14_0 = {
				slot_id = arg_13_1.id,
				num = arg_13_1.buyNum
			}

			xyd.Backend.get():request(xyd.mid.MARKET_DELETE_ITEM, var_14_0, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					arg_13_0.useNum = 0

					local var_15_0 = string.format(var_0_5.txt_usenum, arg_13_0.useNum, var_13_7)

					arg_13_0:nodeByName("txt_num"):setString(var_15_0)

					local var_15_1 = string.format(var_0_5.txt_restnum, var_13_5 + arg_13_0.useNum)

					arg_13_0:nodeByName("txt_rest"):setString(var_15_1)
					arg_13_0:updateCart(arg_15_1)
					arg_13_0.itemList_:reload()
					arg_13_0.lastWinFunc.update(arg_15_1)
				end
			end)
		end
	end)

	return var_13_0
end

function var_0_0.updateCart(arg_16_0, arg_16_1)
	local var_16_0 = {}

	if arg_16_1.cart_info then
		var_16_0 = arg_16_1.cart_info
	end

	local var_16_1 = 0
	local var_16_2 = 0
	local var_16_3
	local var_16_4 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_0.marketItemIds) do
		local var_16_5 = tostring(iter_16_1)

		if var_16_0[var_16_5] then
			local var_16_6 = {
				id = iter_16_1,
				buyNum = var_16_0[var_16_5]
			}

			table.insert(var_16_4, var_16_6)

			var_16_1 = var_16_1 + var_16_0[var_16_5]
			var_16_2 = var_16_2 + var_16_0[var_16_5] * var_0_3:price(iter_16_1)
		end
	end

	arg_16_0:initCartItems(var_16_4)

	local var_16_7 = 0
	local var_16_8 = var_16_2

	for iter_16_2, iter_16_3 in ipairs(arg_16_0.marketDiscountIds) do
		if var_16_2 >= var_0_4:discountLimit(iter_16_3) then
			var_16_8 = var_16_2 - var_0_4:discountNum(iter_16_3)
			var_16_7 = var_0_4:discountNum(iter_16_3)
		end
	end

	local var_16_9 = var_0_2:getValue("activity_market_discount_num")
	local var_16_10 = var_0_2:getValue("activity_market_discount_requirement")
	local var_16_11 = string.format(var_0_5.txt_tips, var_16_9, var_16_10)

	arg_16_0:nodeByName("txt_tips"):setString(var_16_11)

	local var_16_12 = arg_16_0.backpack:getItemNumByID(arg_16_0.ticket)
	local var_16_13 = string.format(var_0_5.txt_restnum, var_16_12)

	arg_16_0:nodeByName("txt_rest"):setString(var_16_13)

	arg_16_0.canUseTicket = false

	if var_16_2 >= 5000 then
		arg_16_0.canUseTicket = true
	end

	if var_16_1 == 0 then
		arg_16_0.canBuy = false
	else
		arg_16_0.canBuy = true
	end

	arg_16_0.cost = var_16_8
	arg_16_0.reduce = var_16_7

	arg_16_0:nodeByName("txt_cost"):setString(var_16_8)

	local var_16_14 = string.format(var_0_5.txt_reduce, var_16_7)

	arg_16_0:nodeByName("txt_have_reduce"):setString(var_16_14)
end

function var_0_0.initCartItems(arg_17_0, arg_17_1)
	arg_17_0.showItems = {}

	local var_17_0 = arg_17_1

	for iter_17_0, iter_17_1 in ipairs(var_17_0) do
		local var_17_1 = {
			id = iter_17_1.id,
			buyNum = iter_17_1.buyNum,
			itemId = var_0_3:itemId(iter_17_1.id),
			name = var_0_3:name(iter_17_1.id),
			num = var_0_3:num(iter_17_1.id),
			price = var_0_3:price(iter_17_1.id),
			allserverLimitNum = var_0_3:allserverLimitNum(iter_17_1.id),
			personalLimitNum = var_0_3:personalLimitNum(iter_17_1.id)
		}

		table.insert(arg_17_0.showItems, var_17_1)
	end
end

function var_0_0.scrollListener(arg_18_0, arg_18_1)
	if arg_18_1.name == "began" then
		arg_18_0.scrollViewMoved_ = false
		arg_18_0.prevY_ = arg_18_1.y
	elseif arg_18_1.name == "moved" and 10 <= math.abs(arg_18_1.y - arg_18_0.prevY_) then
		arg_18_0.scrollViewMoved_ = true
	end
end

return var_0_0
