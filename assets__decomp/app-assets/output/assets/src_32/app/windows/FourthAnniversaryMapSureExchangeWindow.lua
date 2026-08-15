local var_0_0 = class("FourthAnniversaryMapSureExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityAnni4thMapShopTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.fourthAnni = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.mapCoin = xyd.tables.misc:getValue("activity_anni4_campaign_shop_item")
	arg_1_0.mapCoinNum = arg_1_0.selfPlayer:getBackpack():getItemNumByID(arg_1_0.mapCoin)
	arg_1_0.buyNum = 1
	arg_1_0.id = arg_1_2.id
	arg_1_0.shopInfo = arg_1_2.shopInfo
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.handler = {}
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
	local var_4_0 = arg_4_0.id
	local var_4_1 = var_0_3:giftId(var_4_0)

	arg_4_0.itemIDs = xyd.tables.gift:items(var_4_1)

	local var_4_2 = xyd.tables.gift:itemNum(var_4_1)

	xyd.setItemAndAddTips(arg_4_0:nodeByName("icon_container"), arg_4_0.itemIDs[1], var_4_2[1])
	arg_4_0:nodeByName("name_txt"):setString(xyd.tables.item:name(arg_4_0.itemIDs[1]))

	local var_4_3 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_0.itemIDs[1])

	arg_4_0:nodeByName("own_num_txt"):setString(var_4_3)
	arg_4_0:updateNum()
end

function var_0_0.updateNum(arg_5_0)
	arg_5_0.canBuyNum = arg_5_0:getCanBuyNum()

	if arg_5_0.buyNum > arg_5_0.canBuyNum then
		arg_5_0.buyNum = arg_5_0.canBuyNum
	end

	arg_5_0:nodeByName("sell_num_txt"):setString(arg_5_0.buyNum .. "/" .. arg_5_0.canBuyNum)
	arg_5_0:nodeByName("cost_num_txt"):setString(arg_5_0.buyNum * var_0_3:price(arg_5_0.id))

	if (var_0_3:limitNum(arg_5_0.id) or 0) > 0 then
		arg_5_0:nodeByName("progress_txt"):setString("(" .. (arg_5_0.shopInfo[tostring(arg_5_0.id)] or 0) .. "/" .. var_0_3:limitNum(arg_5_0.id) .. ")")
	else
		arg_5_0:nodeByName("progress_txt"):setVisible(false)
	end
end

function var_0_0.getCanBuyNum(arg_6_0)
	arg_6_0.canBuyNum = math.floor(arg_6_0.mapCoinNum / var_0_3:price(arg_6_0.id))

	local var_6_0 = xyd.tables.item:stack(arg_6_0.itemIDs[1])

	if var_6_0 > 0 and arg_6_0.canBuyNum > var_6_0 - arg_6_0.backpack:getItemNumByID(arg_6_0.itemIDs[1]) then
		arg_6_0.canBuyNum = xyd.tables.item:stack(arg_6_0.itemIDs[1]) - arg_6_0.backpack:getItemNumByID(arg_6_0.itemIDs[1])
	end

	if arg_6_0.canBuyNum < 0 then
		arg_6_0.canBuyNum = 0
	end

	local var_6_1 = var_0_3:limitNum(arg_6_0.id) - (arg_6_0.shopInfo[tostring(arg_6_0.id)] or 0)

	if var_0_3:limitNum(arg_6_0.id) > 0 and var_6_1 < arg_6_0.canBuyNum then
		arg_6_0.canBuyNum = var_6_1
	end

	return arg_6_0.canBuyNum
end

function var_0_0.addCurrentNum(arg_7_0)
	if arg_7_0.buyNum + 1 >= arg_7_0.canBuyNum then
		arg_7_0.buyNum = arg_7_0.canBuyNum
	else
		arg_7_0.buyNum = arg_7_0.buyNum + 1
	end

	arg_7_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_8_0)
	if arg_8_0.buyNum - 1 <= 0 then
		arg_8_0.buyNum = 1
	else
		arg_8_0.buyNum = arg_8_0.buyNum - 1
	end

	arg_8_0:updateNum()
end

function var_0_0.didOpen(arg_9_0)
	arg_9_0:addBlockLayer()

	local var_9_0 = cc.ui.UIPushButton.new({
		pressed = "windows/anniversary4th/gold_catch/gold_shop/btn_sub.png",
		disabled = "windows/anniversary4th/gold_catch/gold_shop/btn_sub.png",
		normal = "windows/anniversary4th/gold_catch/gold_shop/btn_sub.png"
	})

	var_9_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_0:setScale(1, 1)
	var_9_0:addTo(arg_9_0:nodeByName("decrease_pos"))
	var_9_0:setName("jiandian")

	local var_9_1 = false

	var_9_0:onButtonPressed(function(arg_10_0)
		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_9_0.decreaseCurrentNum then
				arg_9_0:decreaseCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_9_1 = true

				if arg_9_0.decreaseCurrentNum then
					arg_9_0:decreaseCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_9_0.handler[2] = var_0_1.scheduleGlobal(var_10_1, 0.03)

				var_0_1.unscheduleGlobal(arg_9_0.handler[1])
			else
				var_9_1 = false
			end
		end

		var_9_1 = false
		arg_9_0.handler[1] = var_0_1.scheduleGlobal(var_10_2, 0.1)
	end)
	var_9_0:onButtonRelease(function(arg_13_0)
		if arg_9_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_9_0.handler[1])
		end

		if arg_9_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_9_0.handler[2])
		end

		if var_9_1 == false and arg_9_0.decreaseCurrentNum then
			arg_9_0:decreaseCurrentNum()
		end
	end)

	local var_9_2 = cc.ui.UIPushButton.new({
		pressed = "windows/anniversary4th/gold_catch/gold_shop/btn_add.png",
		disabled = "windows/anniversary4th/gold_catch/gold_shop/btn_add.png",
		normal = "windows/anniversary4th/gold_catch/gold_shop/btn_add.png"
	})

	var_9_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_2:setScale(1, 1)
	var_9_2:addTo(arg_9_0:nodeByName("increase_pos"))
	var_9_2:setName("jiadian")

	local var_9_3 = false

	var_9_2:onButtonPressed(function(arg_14_0)
		local var_14_0 = 0

		local function var_14_1()
			var_14_0 = var_14_0 + 0.03

			if arg_9_0.addCurrentNum then
				arg_9_0:addCurrentNum()
			end
		end

		local function var_14_2()
			var_14_0 = var_14_0 + 0.1

			if var_14_0 > 0.5 and var_14_0 <= 4 then
				var_9_3 = true

				if arg_9_0.addCurrentNum then
					arg_9_0:addCurrentNum()
				end
			elseif var_14_0 > 4 then
				arg_9_0.handler[2] = var_0_1.scheduleGlobal(var_14_1, 0.03)

				var_0_1.unscheduleGlobal(arg_9_0.handler[1])
			else
				var_9_3 = false
			end
		end

		var_9_3 = false
		arg_9_0.handler[1] = var_0_1.scheduleGlobal(var_14_2, 0.1)
	end)
	var_9_2:onButtonRelease(function(arg_17_0)
		if arg_9_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_9_0.handler[1])
		end

		if arg_9_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_9_0.handler[2])
		end

		if var_9_3 == false and arg_9_0.addCurrentNum then
			arg_9_0:addCurrentNum()
		end
	end)
	arg_9_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("exchange_btn"), arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_18_0 = xyd.tables.item:stack(arg_9_0.itemIDs[1])

			if var_18_0 > 0 and var_18_0 <= arg_9_0.backpack:getItemNumByID(arg_9_0.itemIDs[1]) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("SHOP_BACKPACK_IS_FULL")
				})

				return
			elseif arg_9_0.buyNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("BUY_NUM_LESS_THAN_ONE")
				})

				return
			end

			local var_18_1 = {
				slot_id = arg_9_0.id,
				num = arg_9_0.buyNum
			}

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_2:translation("FOURTH_ANNI_MAP_SHOP_BUY"), arg_9_0.buyNum * var_0_3:price(arg_9_0.id), arg_9_0.buyNum, xyd.tables.item:name(arg_9_0.itemIDs[1]))
			}, function()
				arg_9_0.fourthAnni:mapShoppingBuy(var_18_1, function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						arg_9_0.backpack:addItemsByID(arg_9_0.mapCoin, -(arg_9_0.buyNum * var_0_3:price(arg_9_0.id)))
						arg_9_0.selfPlayer:handleRewards(arg_20_1.awards)

						arg_9_0.shopInfo = arg_20_1.shop_buy_info

						if arg_9_0.callback then
							arg_9_0.callback(arg_20_0, arg_20_1)
						end

						xyd.WindowManager.get():closeWindow(arg_9_0)
					end
				end)
			end, nil, nil, xyd.ColorMode.RED)
		end
	end)
	arg_9_0:nodeByName("max_button"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("max_button"), arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_9_0.buyNum = arg_9_0.canBuyNum

			arg_9_0:updateNum()
		end
	end)
end

function var_0_0.didClose(arg_22_0)
	if arg_22_0.handler then
		if arg_22_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_22_0.handler[1])
		end

		if arg_22_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_22_0.handler[2])
		end
	end
end

return var_0_0
