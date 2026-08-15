local var_0_0 = class("MarketShoppingCartWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.activitymarketitem
local var_0_4 = xyd.tables.activitymarketdiscount
local var_0_5 = 2
local var_0_6 = {
	txt_mingchen = var_0_1:translation("ACADEMY_ARENA_DETAIL_NAME"),
	txt_danjia = var_0_1:translation("ACTIVITY_MARKET_PRICE"),
	txt_shuliang = var_0_1:translation("ACTIVITY_MARKET_NUM"),
	txt_cart = var_0_1:translation("ACTIVITY_MARKET_CART_EMPTY"),
	txt_pay = var_0_1:translation("ACTIVITY_MARKET_PAY"),
	txt_overflow = var_0_1:translation("ACTIVITY_MARKET_OVERFLOW"),
	txt_oversub = var_0_1:translation("ACTIVITY_MARKET_OVER_SUB"),
	txt_maxdiscount = var_0_1:translation("ACTIVITY_MARKET_MAX_DISCOUNT"),
	txt_notdiscount = var_0_1:translation("ACTIVITY_MARKET_NOT_DISCOUNT"),
	txt_tips1 = var_0_1:translation("ACTIVITY_MARKET_TIPS1"),
	txt_tips2 = var_0_1:translation("ACTIVITY_MARKET_TIPS2"),
	txt_tips3 = var_0_1:translation("ACTIVITY_MARKET_TIPS3")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.marketItemIds = var_0_3:ids()
	arg_1_0.marketDiscountIds = var_0_4:ids()
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
	arg_3_0:addBlockLayer(nil, nil, true, function()
		if arg_3_0 and not tolua.isnull(arg_3_0) then
			arg_3_0:effectClose()
		end
	end)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_shopping_cart"):setVisible(false)
	arg_5_0:nodeByName("container_all_price"):setVisible(false)
	arg_5_0:nodeByName("txt_mingchen"):setString(var_0_6.txt_mingchen)
	arg_5_0:nodeByName("txt_danjia"):setString(var_0_6.txt_danjia)
	arg_5_0:nodeByName("txt_shuliang"):setString(var_0_6.txt_shuliang)
	arg_5_0:nodeByName("txt_mingchen2"):setString(var_0_6.txt_mingchen)
	arg_5_0:nodeByName("txt_danjia2"):setString(var_0_6.txt_danjia)
	arg_5_0:nodeByName("txt_shuliang2"):setString(var_0_6.txt_shuliang)
	arg_5_0:nodeByName("txt_tips1"):setString(var_0_6.txt_tips1)
	arg_5_0:nodeByName("txt_tips2"):setString(var_0_6.txt_tips2)
	arg_5_0:nodeByName("txt_tips3"):setString(var_0_6.txt_tips3)
	xyd.Backend.get():request(xyd.mid.MARKET_GET_CART, nil, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0:updateCart(arg_6_1)
			arg_5_0.itemList_:reload()
		end
	end)

	local var_5_0 = arg_5_0:nodeByName("container_cart"):getContentSize()
	local var_5_1, var_5_2 = arg_5_0:nodeByName("bg_manjian"):getPosition()
	local var_5_3, var_5_4 = arg_5_0:nodeByName("box"):getPosition()

	arg_5_0:nodeByName("bg_manjian"):setPosition(cc.p(var_5_1, var_5_2 - var_5_0.height))
	arg_5_0:nodeByName("box"):setPosition(cc.p(var_5_3, var_5_4 - var_5_0.height))

	local var_5_5 = 0.4
	local var_5_6 = cc.MoveTo:create(var_5_5, cc.p(var_5_1, var_5_2))

	arg_5_0:nodeByName("bg_manjian"):runActionOnce(var_5_6)

	local var_5_7 = cc.MoveTo:create(var_5_5, cc.p(var_5_3, var_5_4))

	arg_5_0:nodeByName("box"):runActionOnce(var_5_7)

	local var_5_8 = arg_5_0:nodeByName("icon_shopping_cart")

	var_5_8:setTouchEnabled(true)
	var_5_8:setTouchSwallowEnabled(false)
	var_5_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			var_5_8:setScale(0.9)

			return true
		elseif arg_7_0.name == "moved" then
			var_5_8:setScale(1)
		elseif arg_7_0.name == "ended" then
			var_5_8:setScale(1)
			arg_5_0:effectClose()
		end
	end)

	local var_5_9 = arg_5_0:nodeByName("btn_clear")

	var_5_9:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_5_9:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended or arg_8_1 == ccui.TouchEventType.canceled then
			var_5_9:setScale(1)
			xyd.Backend.get():request(xyd.mid.MARKET_CLEAR_CART, nil, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_5_0:updateCart(arg_9_1)
					arg_5_0.itemList_:reload()
				end
			end)
		end
	end)

	local var_5_10 = arg_5_0:nodeByName("btn_check_out")

	var_5_10:getChildByName("txt_check_out"):setString(var_0_6.txt_pay)
	var_5_10:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			var_5_10:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.ended or arg_10_1 == ccui.TouchEventType.canceled then
			var_5_10:setScale(1)

			local var_10_0 = arg_5_0.lastWinFunc

			xyd.WindowManager.get():openWindow("market_pay_bill", var_10_0)
			xyd.Backend.get():request(xyd.mid.MARKET_GET_CART, nil, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					if arg_5_0.lastWinFunc then
						arg_5_0.lastWinFunc.update(arg_11_1)
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = "error"
					})
				end

				local var_11_0 = xyd.tables.sound:getSound("ui_close_window")

				audio.playSound(var_11_0, false)
				xyd.WindowManager.get():closeWindow(arg_5_0.name)
			end)
		end
	end)
end

function var_0_0.updateCart(arg_12_0, arg_12_1)
	local var_12_0 = {}

	if arg_12_1.cart_info then
		var_12_0 = arg_12_1.cart_info
	end

	local var_12_1 = 0
	local var_12_2 = 0
	local var_12_3
	local var_12_4 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.marketItemIds) do
		local var_12_5 = tostring(iter_12_1)

		if var_12_0[var_12_5] then
			local var_12_6 = {
				id = iter_12_1,
				buyNum = var_12_0[var_12_5],
				allBuyNum = arg_12_1.item_states.all_buy_times[iter_12_1],
				selfBuyNum = arg_12_1.item_states.self_buy_times[iter_12_1]
			}

			table.insert(var_12_4, var_12_6)

			var_12_1 = var_12_1 + var_12_0[var_12_5]
			var_12_2 = var_12_2 + var_12_0[var_12_5] * var_0_3:price(iter_12_1)
		end
	end

	arg_12_0:initCartItems(var_12_4)

	local var_12_7 = 0
	local var_12_8 = var_12_2

	for iter_12_2, iter_12_3 in ipairs(arg_12_0.marketDiscountIds) do
		if var_12_2 >= var_0_4:discountLimit(iter_12_3) then
			var_12_8 = var_12_2 - var_0_4:discountNum(iter_12_3)
			var_12_7 = iter_12_3
		end
	end

	if var_12_7 == 0 then
		arg_12_0:nodeByName("txt_tips1"):setString(var_0_6.txt_notdiscount)
		arg_12_0:nodeByName("txt_have_reduce"):setVisible(false)
		arg_12_0:nodeByName("txt_tips2"):setVisible(false)
		arg_12_0:nodeByName("txt_buy_more"):setVisible(false)
		arg_12_0:nodeByName("txt_tips3"):setVisible(false)
		arg_12_0:nodeByName("txt_will_reduce"):setVisible(false)
	elseif var_12_7 < #arg_12_0.marketDiscountIds then
		arg_12_0:nodeByName("txt_tips1"):setString(var_0_6.txt_tips1)
		arg_12_0:nodeByName("txt_have_reduce"):setVisible(true)
		arg_12_0:nodeByName("txt_have_reduce"):setString(var_0_4:discountNum(var_12_7))

		local var_12_9 = var_0_4:discountLimit(var_12_7 + 1) - var_12_2

		arg_12_0:nodeByName("txt_tips2"):setVisible(true)
		arg_12_0:nodeByName("txt_tips2"):setString(var_0_6.txt_tips2)
		arg_12_0:nodeByName("txt_buy_more"):setVisible(true)
		arg_12_0:nodeByName("txt_buy_more"):setString(var_12_9)
		arg_12_0:nodeByName("txt_tips3"):setVisible(true)
		arg_12_0:nodeByName("txt_will_reduce"):setVisible(true)
		arg_12_0:nodeByName("txt_will_reduce"):setString(var_0_4:discountNum(var_12_7 + 1))
	else
		arg_12_0:nodeByName("txt_tips1"):setString(var_0_6.txt_tips1)
		arg_12_0:nodeByName("txt_have_reduce"):setVisible(true)
		arg_12_0:nodeByName("txt_have_reduce"):setString(var_0_4:discountNum(var_12_7))
		arg_12_0:nodeByName("txt_tips2"):setVisible(true)
		arg_12_0:nodeByName("txt_tips2"):setString(var_0_6.txt_maxdiscount)
		arg_12_0:nodeByName("txt_buy_more"):setVisible(false)
		arg_12_0:nodeByName("txt_tips3"):setVisible(false)
		arg_12_0:nodeByName("txt_will_reduce"):setVisible(false)
	end

	local function var_12_10(arg_13_0)
		local var_13_0 = "windows/activities/1185/word_yellow" .. arg_13_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_13_0)
	end

	arg_12_0:nodeByName("txt_num"):setString(var_12_1)

	local var_12_11 = arg_12_0:nodeByName("txt_shopping_cart")
	local var_12_12 = arg_12_0:nodeByName("container_all_price")

	if var_12_1 == 0 then
		arg_12_0.canBuy = false

		var_12_11:setVisible(true)
		var_12_12:setVisible(false)
		var_12_11:setString(var_0_6.txt_cart)
	else
		arg_12_0.canBuy = true

		var_12_11:setVisible(false)
		var_12_12:setVisible(true)
		arg_12_0:nodeByName("txt_price"):setString(var_12_8)
		arg_12_0:nodeByName("txt_yuanjia"):setString(var_12_2)
	end
end

function var_0_0.initCartItems(arg_14_0, arg_14_1)
	arg_14_0.showItems = {}

	local var_14_0 = arg_14_1

	for iter_14_0, iter_14_1 in ipairs(var_14_0) do
		local var_14_1 = {
			id = iter_14_1.id,
			buyNum = iter_14_1.buyNum,
			itemId = var_0_3:itemId(iter_14_1.id),
			name = var_0_3:name(iter_14_1.id),
			num = var_0_3:num(iter_14_1.id),
			price = var_0_3:price(iter_14_1.id),
			allserverLimitNum = var_0_3:allserverLimitNum(iter_14_1.id),
			personalLimitNum = var_0_3:personalLimitNum(iter_14_1.id),
			allBuyNum = iter_14_1.allBuyNum,
			selfBuyNum = iter_14_1.selfBuyNum
		}

		table.insert(arg_14_0.showItems, var_14_1)
	end
end

function var_0_0.itemDelegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return math.ceil(#arg_15_0.showItems / var_0_5)
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_0
		local var_15_1 = arg_15_1:dequeueItem()

		if not var_15_1 then
			var_15_1 = arg_15_1:newItem()
		else
			var_15_1:removeAllChildren(false)
		end

		local var_15_2 = display.newNode()

		var_15_2:setContentSize(880, 60)

		for iter_15_0 = 1, var_0_5 do
			local var_15_3 = (arg_15_3 - 1) * var_0_5 + iter_15_0

			if arg_15_0.showItems[var_15_3] then
				local var_15_4 = arg_15_0:createShowNode(var_15_3)
				local var_15_5 = var_15_4:getChildByName("container"):getContentSize()

				var_15_4:addTo(var_15_2)
				var_15_4:setPosition(cc.p(var_15_5.width * (iter_15_0 - 1), 0))
			end
		end

		var_15_1:addContent(var_15_2)
		var_15_1:setItemSize(880, 60)

		return var_15_1
	end
end

function var_0_0.createShowNode(arg_16_0, arg_16_1)
	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1185/item_cart.csb")
	local var_16_1 = var_16_0:getChildByName("container")
	local var_16_2 = arg_16_0.showItems[arg_16_1]

	var_16_1:getChildByName("txt_icon_price"):setString(var_16_2.price)
	var_16_1:getChildByName("txt_icon_name"):setString(var_16_2.name)
	var_16_1:getChildByName("txt_icon_num"):setString(var_16_2.buyNum)

	local var_16_3 = var_16_1:getChildByName("btn_add")
	local var_16_4 = var_16_1:getChildByName("btn_sub")

	var_16_3:addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.began then
			var_16_3:setScale(0.9)
		elseif arg_17_1 == ccui.TouchEventType.ended or arg_17_1 == ccui.TouchEventType.canceled then
			var_16_3:setScale(1)

			local var_17_0 = var_0_6.txt_overflow

			if var_16_2.personalLimitNum ~= -1 and var_16_2.selfBuyNum + arg_16_0.showItems[arg_16_1].buyNum + 1 > var_16_2.personalLimitNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_0
				})

				return
			end

			if var_16_2.allserverLimitNum ~= -1 and var_16_2.allBuyNum + arg_16_0.showItems[arg_16_1].buyNum + 1 > var_16_2.allserverLimitNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_17_0
				})

				return
			end

			local var_17_1 = {
				slot_id = var_16_2.id
			}

			var_17_1.num = 1

			xyd.Backend.get():request(xyd.mid.MARKET_ADD_TO_CART, var_17_1, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					arg_16_0:updateCart(arg_18_1)
					var_16_1:getChildByName("txt_icon_num"):setString(arg_16_0.showItems[arg_16_1].buyNum)
				end
			end)
		end
	end)
	var_16_4:addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.began then
			var_16_4:setScale(0.9)
		elseif arg_19_1 == ccui.TouchEventType.ended or arg_19_1 == ccui.TouchEventType.canceled then
			var_16_4:setScale(1)

			if var_16_2.buyNum - 1 < 0 then
				local var_19_0 = var_0_6.txt_oversub

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_0
				})
			else
				local var_19_1 = {
					slot_id = var_16_2.id
				}

				var_19_1.num = 1

				xyd.Backend.get():request(xyd.mid.MARKET_DELETE_ITEM, var_19_1, function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						arg_16_0:updateCart(arg_20_1)
						arg_16_0.itemList_:reload()
					end
				end)
			end
		end
	end)

	return var_16_0
end

function var_0_0.effectClose(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("container_cart"):getContentSize()
	local var_21_1, var_21_2 = arg_21_0:nodeByName("bg_manjian"):getPosition()
	local var_21_3, var_21_4 = arg_21_0:nodeByName("box"):getPosition()
	local var_21_5 = 0.2
	local var_21_6 = cc.MoveTo:create(var_21_5, cc.p(var_21_1, var_21_2 - var_21_0.height))

	arg_21_0:nodeByName("bg_manjian"):runActionOnce(var_21_6, false, function()
		local var_22_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_22_0, false)
		xyd.WindowManager.get():closeWindow(arg_21_0.name)
	end)

	local var_21_7 = cc.MoveTo:create(var_21_5, cc.p(var_21_3, var_21_4 - var_21_0.height))

	arg_21_0:nodeByName("box"):runActionOnce(var_21_7)
	xyd.Backend.get():request(xyd.mid.MARKET_GET_CART, nil, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK then
			if arg_21_0.lastWinFunc then
				arg_21_0.lastWinFunc.update(arg_23_1)
			end
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = "error"
			})
		end
	end)
end

function var_0_0.scrollListener(arg_24_0, arg_24_1)
	if arg_24_1.name == "began" then
		arg_24_0.scrollViewMoved_ = false
		arg_24_0.prevY_ = arg_24_1.y
	elseif arg_24_1.name == "moved" and 10 <= math.abs(arg_24_1.y - arg_24_0.prevY_) then
		arg_24_0.scrollViewMoved_ = true
	end
end

return var_0_0
