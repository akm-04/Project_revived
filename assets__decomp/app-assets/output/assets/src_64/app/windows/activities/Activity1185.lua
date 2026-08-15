local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.activitymarketitem
local var_0_4 = xyd.tables.activitymarketdiscount
local var_0_5 = xyd.tables.activitymarketdialogue
local var_0_6 = import("framework.scheduler")
local var_0_7 = {
	txt_pay = var_0_1:translation("ACTIVITY_MARKET_PAY"),
	txt_quanfuxianshou = var_0_1:translation("ACTIVITY_MARKET_ALL_UNLIMIT"),
	txt_gerenxianshou = var_0_1:translation("ACTIVITY_MARKET_PER_UNLIMIT"),
	txt_quanfu = var_0_1:translation("ACTIVITY_MARKET_LIMIT"),
	txt_geren = var_0_1:translation("ACTIVITY_MARKET_PER_LIMIT"),
	txt_cart = var_0_1:translation("ACTIVITY_MARKET_CART_EMPTY"),
	txt_overflow = var_0_1:translation("ACTIVITY_MARKET_OVERFLOW"),
	txt_oversub = var_0_1:translation("ACTIVITY_MARKET_OVER_SUB"),
	txt_tips = var_0_1:translation("ACTIVITY_MARKET_MAIN_TIPS")
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.details = arg_1_0.activity.details

	local var_1_0 = arg_1_0.details.item_states.all_buy_times
	local var_1_1 = arg_1_0.details.item_states.self_buy_times

	arg_1_0.marketItemIds = var_0_3:ids()
	arg_1_0.marketDiscountIds = var_0_4:ids()
	arg_1_0.cartItems = {}

	arg_1_0:initShowItems(var_1_0, var_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:initList()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if not arg_3_0.res or arg_3_0.res == 0 then
		print("No res available.")

		return
	end

	arg_3_0.container:getChildByName("txt_reduction"):setString(var_0_7.txt_tips)
	arg_3_0.container:getChildByName("container_chat"):setVisible(false)
	arg_3_0.container:getChildByName("shopping_cart"):getChildByName("txt_shopping_cart"):setVisible(false)
	arg_3_0.container:getChildByName("shopping_cart"):getChildByName("container_all_price"):setVisible(false)
	xyd.Backend.get():request(xyd.mid.MARKET_GET_CART, nil, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0:updateCart(arg_4_1)
			arg_3_0.itemList_:reload()
		end
	end)

	local function var_3_0()
		if arg_3_0.handle_ then
			var_0_6.unscheduleGlobal(arg_3_0.handle_)

			arg_3_0.handle_ = nil

			arg_3_0.container:getChildByName("container_chat"):setVisible(false)
		end

		arg_3_0.isRunning_ = false
	end

	local var_3_1, var_3_2 = arg_3_0.container:getChildByName("container_chat"):getPosition()
	local var_3_3 = display.newNode()

	var_3_3:setContentSize(300, 400)
	var_3_3:setAnchorPoint(0, 0)
	var_3_3:setPosition(var_3_1, var_3_2 - 100)
	var_3_3:setTouchEnabled(true)
	var_3_3:setTouchSwallowEnabled(false)
	var_3_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			local var_6_0 = var_0_5:ids()
			local var_6_1 = math.random(#var_6_0)
			local var_6_2 = var_0_5:content(var_6_1)

			if arg_3_0.isRunning_ then
				return
			end

			arg_3_0.isRunning_ = true

			arg_3_0.container:getChildByName("container_chat"):scale(0)

			local var_6_3 = cc.Sequence:create({
				cc.CallFunc:create(function()
					arg_3_0.container:getChildByName("container_chat"):setVisible(true)
					arg_3_0.container:getChildByName("container_chat"):getChildByName("txt_chat"):setString(var_6_2)
				end),
				cc.Spawn:create({
					cc.ScaleTo:create(0.2, 1),
					cc.FadeTo:create(0.2, 255)
				})
			})

			arg_3_0.container:getChildByName("container_chat"):runActionOnce(var_6_3)

			local var_6_4 = 4

			arg_3_0.handle_ = var_0_6.scheduleGlobal(function(arg_8_0)
				var_6_4 = var_6_4 - 1

				if var_6_4 <= 0 then
					var_3_0()
				end
			end, 1)
		end
	end)
	var_3_3:addTo(arg_3_0.container)

	local var_3_4 = arg_3_0.container:getChildByName("shopping_cart"):getChildByName("btn_check_out")

	var_3_4:getChildByName("txt_check_out"):setString(var_0_7.txt_pay)
	var_3_4:addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.began then
			var_3_4:setScale(0.9)
		elseif arg_9_1 == ccui.TouchEventType.ended or arg_9_1 == ccui.TouchEventType.canceled then
			var_3_4:setScale(1)

			local var_9_0 = {
				update = function(arg_10_0)
					local var_10_0 = arg_10_0.item_states.all_buy_times
					local var_10_1 = arg_10_0.item_states.self_buy_times

					arg_3_0:initShowItems(var_10_0, var_10_1)
					arg_3_0:updateCart(arg_10_0)
					arg_3_0.itemList_:reload()
				end
			}

			xyd.WindowManager.get():openWindow("market_pay_bill", var_9_0)
		end
	end)

	local var_3_5 = arg_3_0.container:getChildByName("btn_rule")

	var_3_5:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			var_3_5:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended or arg_11_1 == ccui.TouchEventType.canceled then
			var_3_5:setScale(1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "ACTIVITY_MARKET_RULE_TITLE",
				rule = "ACTIVITY_MARKET_RULE",
				style = xyd.RuleStyle.RED
			})
		end
	end)

	local var_3_6 = arg_3_0.container:getChildByName("shopping_cart"):getChildByName("icon_shopping_cart")

	var_3_6:setTouchEnabled(true)
	var_3_6:setTouchSwallowEnabled(false)
	var_3_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			var_3_6:setScale(0.9)

			return true
		elseif arg_12_0.name == "moved" then
			var_3_6:setScale(1)
		elseif arg_12_0.name == "ended" then
			var_3_6:setScale(1)

			local var_12_0 = {
				update = function(arg_13_0)
					local var_13_0 = arg_13_0.item_states.all_buy_times
					local var_13_1 = arg_13_0.item_states.self_buy_times

					arg_3_0:initShowItems(var_13_0, var_13_1)
					arg_3_0:updateCart(arg_13_0)
					arg_3_0.itemList_:reload()
				end
			}

			xyd.WindowManager.get():openWindow("market_shopping_cart", var_12_0)
		end
	end)
end

function var_0_0.updateCart(arg_14_0, arg_14_1)
	local var_14_0 = {}

	if arg_14_1.cart_info then
		var_14_0 = arg_14_1.cart_info
	end

	local var_14_1 = 0
	local var_14_2 = 0
	local var_14_3

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.marketItemIds) do
		local var_14_4 = tostring(iter_14_1)

		if var_14_0[var_14_4] then
			arg_14_0.cartItems[iter_14_1] = var_14_0[var_14_4]
			var_14_1 = var_14_1 + var_14_0[var_14_4]
			var_14_2 = var_14_2 + var_14_0[var_14_4] * var_0_3:price(iter_14_1)
		else
			arg_14_0.cartItems[iter_14_1] = 0
		end
	end

	local var_14_5 = var_14_2

	for iter_14_2, iter_14_3 in ipairs(arg_14_0.marketDiscountIds) do
		if var_14_2 >= var_0_4:discountLimit(iter_14_3) then
			var_14_5 = var_14_2 - var_0_4:discountNum(iter_14_3)
		end
	end

	local function var_14_6(arg_15_0)
		local var_15_0 = "windows/activities/1185/word_yellow" .. arg_15_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_15_0)
	end

	local var_14_7 = arg_14_0.container:getChildByName("shopping_cart"):getChildByName("bg_num"):getChildByName("txt_num")

	var_14_7:setString(var_14_1)
	var_14_7:enableOutline(cc.c4b(114, 113, 113, 255), 2)

	local var_14_8 = arg_14_0.container:getChildByName("shopping_cart"):getChildByName("txt_shopping_cart")
	local var_14_9 = arg_14_0.container:getChildByName("shopping_cart"):getChildByName("container_all_price")

	if var_14_1 == 0 then
		var_14_8:setVisible(true)
		var_14_9:setVisible(false)
		var_14_8:setString(var_0_7.txt_cart)
	else
		var_14_8:setVisible(false)
		var_14_9:setVisible(true)
		var_14_9:getChildByName("txt_price"):setString(var_14_5)
		var_14_9:getChildByName("txt_yuanjia"):setString(var_14_2)
	end
end

function var_0_0.initList(arg_16_0)
	local var_16_0 = arg_16_0.container:getChildByName("list")

	var_16_0:removeAllChildren()

	local var_16_1 = var_16_0:getContentSize()

	arg_16_0.itemList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_16_1.width, var_16_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_16_0):onScroll(handler(arg_16_0, arg_16_0.scrollListener))

	arg_16_0.itemList_:setDelegate(handler(arg_16_0, arg_16_0.itemDelegate))
end

function var_0_0.initShowItems(arg_17_0, arg_17_1, arg_17_2)
	arg_17_0.showItems = {}

	for iter_17_0, iter_17_1 in ipairs(arg_17_0.marketItemIds) do
		local var_17_0 = {
			id = iter_17_1,
			itemId = var_0_3:itemId(iter_17_1),
			name = var_0_3:name(iter_17_1),
			num = var_0_3:num(iter_17_1),
			price = var_0_3:price(iter_17_1),
			allserverLimitNum = var_0_3:allserverLimitNum(iter_17_1),
			personalLimitNum = var_0_3:personalLimitNum(iter_17_1),
			allBuyNum = arg_17_1[iter_17_1],
			selfBuyNum = arg_17_2[iter_17_1]
		}

		if var_17_0.allserverLimitNum == -1 then
			var_17_0.allSort = 0
		elseif var_17_0.allserverLimitNum > arg_17_1[iter_17_1] then
			var_17_0.allSort = 0
		else
			var_17_0.allSort = 2
		end

		if var_17_0.personalLimitNum == -1 then
			var_17_0.selfSort = 0
		elseif var_17_0.personalLimitNum > arg_17_2[iter_17_1] then
			var_17_0.selfSort = 0
		else
			var_17_0.selfSort = 1
		end

		table.insert(arg_17_0.showItems, var_17_0)
	end

	table.sort(arg_17_0.showItems, function(arg_18_0, arg_18_1)
		local var_18_0 = arg_18_0.selfSort + arg_18_0.allSort
		local var_18_1 = arg_18_1.selfSort + arg_18_1.allSort

		if var_18_0 == var_18_1 then
			return arg_18_0.id < arg_18_1.id
		else
			return var_18_0 < var_18_1
		end
	end)
end

function var_0_0.itemDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return #arg_19_0.showItems
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		local var_19_0
		local var_19_1 = arg_19_1:dequeueItem()

		if not var_19_1 then
			var_19_1 = arg_19_1:newItem()
		else
			var_19_1:removeAllChildren(false)
		end

		local var_19_2 = arg_19_0.showItems[arg_19_3]
		local var_19_3 = arg_19_0:createShowNode(var_19_2, arg_19_3)
		local var_19_4 = var_19_3:getChildByName("container"):getContentSize()
		local var_19_5 = display.newNode()

		var_19_5:setContentSize(var_19_4.width, var_19_4.height)
		var_19_3:addTo(var_19_5)
		var_19_3:setPosition(cc.p(0, 0))
		var_19_1:addContent(var_19_5)
		var_19_1:setItemSize(var_19_4.width, var_19_4.height + 6)

		return var_19_1
	end
end

function var_0_0.createShowNode(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1185/item_goods.csb")
	local var_20_1 = var_20_0:getChildByName("container")
	local var_20_2

	if arg_20_1.allserverLimitNum == -1 then
		var_20_2 = var_0_7.txt_quanfuxianshou
	else
		var_20_2 = var_0_7.txt_quanfu .. "(" .. arg_20_1.allBuyNum .. "/" .. arg_20_1.allserverLimitNum .. ")"
	end

	var_20_1:getChildByName("txt_quanfu"):setString(var_20_2)

	local var_20_3

	if arg_20_1.personalLimitNum == -1 then
		var_20_3 = var_0_7.txt_gerenxianshou
	else
		var_20_3 = var_0_7.txt_geren .. "(" .. arg_20_1.selfBuyNum .. "/" .. arg_20_1.personalLimitNum .. ")"
	end

	var_20_1:getChildByName("txt_geren"):setString(var_20_3)
	var_20_1:getChildByName("txt_price"):setString(arg_20_1.price)

	local var_20_4 = var_20_1:getChildByName("icon_goods")

	xyd.setItemAndAddTips(var_20_4, arg_20_1.itemId, arg_20_1.num)
	var_20_1:getChildByName("txt_num"):setString(arg_20_0.cartItems[arg_20_1.id])

	local var_20_5 = var_20_1:getChildByName("btn_add")
	local var_20_6 = var_20_1:getChildByName("btn_sub")

	var_20_5:addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.began then
			var_20_5:setScale(0.9)
		elseif arg_21_1 == ccui.TouchEventType.ended or arg_21_1 == ccui.TouchEventType.canceled then
			var_20_5:setScale(1)

			local var_21_0 = var_0_7.txt_overflow

			if arg_20_1.personalLimitNum ~= -1 and arg_20_1.selfBuyNum + arg_20_0.cartItems[arg_20_1.id] + 1 > arg_20_1.personalLimitNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_21_0
				})

				return
			end

			if arg_20_1.allserverLimitNum ~= -1 and arg_20_1.allBuyNum + arg_20_0.cartItems[arg_20_1.id] + 1 > arg_20_1.allserverLimitNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_21_0
				})

				return
			end

			local var_21_1 = {
				slot_id = arg_20_1.id
			}

			var_21_1.num = 1

			xyd.Backend.get():request(xyd.mid.MARKET_ADD_TO_CART, var_21_1, function(arg_22_0, arg_22_1)
				if arg_22_0 == xyd.error.OK then
					arg_20_0:updateCart(arg_22_1)
					var_20_1:getChildByName("txt_num"):setString(arg_20_0.cartItems[arg_20_1.id])
				end
			end)
		end
	end)
	var_20_6:addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.began then
			var_20_6:setScale(0.9)
		elseif arg_23_1 == ccui.TouchEventType.ended or arg_23_1 == ccui.TouchEventType.canceled then
			var_20_6:setScale(1)

			if arg_20_0.cartItems[arg_20_1.id] - 1 < 0 then
				local var_23_0 = var_0_7.txt_oversub

				xyd.WindowManager.get():openWindow("toast", {
					message = var_23_0
				})
			else
				local var_23_1 = {
					slot_id = arg_20_1.id
				}

				var_23_1.num = 1

				xyd.Backend.get():request(xyd.mid.MARKET_DELETE_ITEM, var_23_1, function(arg_24_0, arg_24_1)
					if arg_24_0 == xyd.error.OK then
						arg_20_0:updateCart(arg_24_1)
						var_20_1:getChildByName("txt_num"):setString(arg_20_0.cartItems[arg_20_1.id])
					end
				end)
			end
		end
	end)

	if arg_20_1.allSort == 2 or arg_20_1.selfSort == 1 then
		var_20_0:getChildByName("container_grey"):setVisible(true)
		var_20_0:getChildByName("container_grey"):setTouchSwallowEnabled(false)
	else
		var_20_0:getChildByName("container_grey"):setVisible(false)
	end

	return var_20_0
end

function var_0_0.scrollListener(arg_25_0, arg_25_1)
	if arg_25_1.name == "began" then
		arg_25_0.scrollViewMoved_ = false
		arg_25_0.prevY_ = arg_25_1.y
	elseif arg_25_1.name == "moved" and 10 <= math.abs(arg_25_1.y - arg_25_0.prevY_) then
		arg_25_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_26_0)
	if arg_26_0.handle_ then
		var_0_6.unscheduleGlobal(arg_26_0.handle_)

		arg_26_0.handle_ = nil
		arg_26_0.isRunning_ = false
	end
end

return var_0_0
