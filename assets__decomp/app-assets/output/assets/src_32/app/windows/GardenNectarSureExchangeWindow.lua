local var_0_0 = class("GardenNectarSureExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityGardenShop

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.buyNum = 1
	arg_1_0.id = arg_1_2.id
	arg_1_0.itemID = arg_1_2.itemID
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
	xyd.setItemBorder(arg_4_0:nodeByName("icon_container"), arg_4_0.itemID)
	arg_4_0:nodeByName("name_txt"):setString(xyd.tables.item:name(arg_4_0.itemID))
	arg_4_0:nodeByName("has_text"):setString(var_0_2:translation("GARDEN_PRICE_TEXT"))
	arg_4_0:nodeByName("total_cost_text"):setString(var_0_2:translation("TOTAL_COST_TEXT"))
	arg_4_0:nodeByName("select_buy_num_text"):setString(var_0_2:translation("GARDEN_SELECT_NUM_TEXT"))

	local var_4_0 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(arg_4_0.itemID)

	arg_4_0:nodeByName("own_num_txt"):setString(var_0_3:sellPrice(arg_4_0.id))
	arg_4_0:nodeByName("desc_txt"):setString(xyd.getItemDesc(arg_4_0.itemID))

	local var_4_1 = xyd.tables.asset:getIdByBackendName("nectar")

	arg_4_0:nodeByName("cost_icon"):loadTexture(xyd.tables.asset:transparentIcon(var_4_1))
	arg_4_0:updateNum()
end

function var_0_0.updateNum(arg_5_0)
	arg_5_0.canBuyNum = math.floor(arg_5_0.garden.selfDetails.nectar / var_0_3:sellPrice(arg_5_0.id))

	if arg_5_0.canBuyNum > xyd.tables.item:stack(arg_5_0.itemID) - arg_5_0.backpack:getItemNumByID(arg_5_0.itemID) then
		arg_5_0.canBuyNum = xyd.tables.item:stack(arg_5_0.itemID) - arg_5_0.backpack:getItemNumByID(arg_5_0.itemID)
	end

	if arg_5_0.canBuyNum < 0 then
		arg_5_0.canBuyNum = 0
	end

	local var_5_0 = var_0_3:buyLimit(arg_5_0.id) - (arg_5_0.garden.selfDetails.exchange_times[arg_5_0.id] or 0)

	if var_0_3:buyLimit(arg_5_0.id) > 0 and var_5_0 < arg_5_0.canBuyNum then
		arg_5_0.canBuyNum = var_5_0
	end

	if arg_5_0.buyNum > arg_5_0.canBuyNum then
		arg_5_0.buyNum = arg_5_0.canBuyNum
	end

	arg_5_0:nodeByName("sell_num_txt"):setString(arg_5_0.buyNum .. "/" .. arg_5_0.canBuyNum)
	arg_5_0:nodeByName("cost_num_txt"):setString(arg_5_0.buyNum * var_0_3:sellPrice(arg_5_0.id))
end

function var_0_0.addCurrentNum(arg_6_0)
	if arg_6_0.buyNum + 1 >= arg_6_0.canBuyNum then
		arg_6_0.buyNum = arg_6_0.canBuyNum
	else
		arg_6_0.buyNum = arg_6_0.buyNum + 1
	end

	arg_6_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_7_0)
	if arg_7_0.buyNum - 1 <= 0 then
		arg_7_0.buyNum = 1
	else
		arg_7_0.buyNum = arg_7_0.buyNum - 1
	end

	arg_7_0:updateNum()
end

function var_0_0.didOpen(arg_8_0)
	arg_8_0:addBlockLayer()

	local var_8_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/-_button2.png",
		disabled = "windows/button/-_button2.png",
		normal = "windows/button/-_button1.png"
	})

	var_8_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_0:setScale(1, 1)
	var_8_0:addTo(arg_8_0:nodeByName("decrease_pos"))
	var_8_0:setName("jiandian")

	local var_8_1 = false

	var_8_0:onButtonPressed(function(arg_9_0)
		local var_9_0 = 0

		local function var_9_1()
			var_9_0 = var_9_0 + 0.03

			if arg_8_0.decreaseCurrentNum then
				arg_8_0:decreaseCurrentNum()
			end
		end

		local function var_9_2()
			var_9_0 = var_9_0 + 0.1

			if var_9_0 > 0.5 and var_9_0 <= 4 then
				var_8_1 = true

				if arg_8_0.decreaseCurrentNum then
					arg_8_0:decreaseCurrentNum()
				end
			elseif var_9_0 > 4 then
				arg_8_0.handler[2] = var_0_1.scheduleGlobal(var_9_1, 0.03)

				var_0_1.unscheduleGlobal(arg_8_0.handler[1])
			else
				var_8_1 = false
			end
		end

		var_8_1 = false
		arg_8_0.handler[1] = var_0_1.scheduleGlobal(var_9_2, 0.1)
	end)
	var_8_0:onButtonRelease(function(arg_12_0)
		if arg_8_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[1])
		end

		if arg_8_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[2])
		end

		if var_8_1 == false and arg_8_0.decreaseCurrentNum then
			arg_8_0:decreaseCurrentNum()
		end
	end)

	local var_8_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/add_button2.png",
		disabled = "windows/button/add_button2.png",
		normal = "windows/button/add_button1.png"
	})

	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:setScale(1, 1)
	var_8_2:addTo(arg_8_0:nodeByName("increase_pos"))
	var_8_2:setName("jiadian")

	local var_8_3 = false

	var_8_2:onButtonPressed(function(arg_13_0)
		local var_13_0 = 0

		local function var_13_1()
			var_13_0 = var_13_0 + 0.03

			if arg_8_0.addCurrentNum then
				arg_8_0:addCurrentNum()
			end
		end

		local function var_13_2()
			var_13_0 = var_13_0 + 0.1

			if var_13_0 > 0.5 and var_13_0 <= 4 then
				var_8_3 = true

				if arg_8_0.addCurrentNum then
					arg_8_0:addCurrentNum()
				end
			elseif var_13_0 > 4 then
				arg_8_0.handler[2] = var_0_1.scheduleGlobal(var_13_1, 0.03)

				var_0_1.unscheduleGlobal(arg_8_0.handler[1])
			else
				var_8_3 = false
			end
		end

		var_8_3 = false
		arg_8_0.handler[1] = var_0_1.scheduleGlobal(var_13_2, 0.1)
	end)
	var_8_2:onButtonRelease(function(arg_16_0)
		if arg_8_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[1])
		end

		if arg_8_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_8_0.handler[2])
		end

		if var_8_3 == false and arg_8_0.addCurrentNum then
			arg_8_0:addCurrentNum()
		end
	end)
	arg_8_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.backpack:getItemNumByID(arg_8_0.itemID) >= xyd.tables.item:stack(arg_8_0.itemID) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("SHOP_BACKPACK_IS_FULL")
				})

				return
			elseif arg_8_0.buyNum == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("BUY_NUM_LESS_THAN_ONE")
				})

				return
			end

			local var_17_0 = {
				idx = arg_8_0.id,
				num = arg_8_0.buyNum
			}

			arg_8_0.garden:gardenExchange(var_17_0, function(arg_18_0, arg_18_1)
				if arg_18_0 == xyd.error.OK then
					if arg_18_1.awards then
						arg_8_0.selfPlayer:handleRewards(arg_18_1.awards)
					end

					arg_8_0.garden.selfDetails.exchange_times[arg_8_0.id] = (arg_8_0.garden.selfDetails.exchange_times[arg_8_0.id] or 0) + var_17_0.num

					if arg_8_0.callback then
						arg_8_0.callback()
					end

					xyd.WindowManager.get():closeWindow(arg_8_0)
				end

				if callback then
					callback(arg_18_0, arg_18_1)
				end
			end)
		end
	end)
end

function var_0_0.didClose(arg_19_0)
	if arg_19_0.handler then
		if arg_19_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_19_0.handler[1])
		end

		if arg_19_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_19_0.handler[2])
		end
	end
end

return var_0_0
