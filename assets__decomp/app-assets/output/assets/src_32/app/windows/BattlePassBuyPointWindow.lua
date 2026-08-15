local var_0_0 = class("BattlePassBuyPointWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.battlePassReward
local var_0_4 = xyd.tables.gift
local var_0_5 = xyd.tables.misc
local var_0_6 = 9
local var_0_7 = var_0_5:getValue("battle_pass_limit_purchase_num")
local var_0_8 = {
	1,
	10,
	var_0_5:getValue("battle_pass_limit_purchase_level")
}
local var_0_9 = {
	var_0_5:getValue("battle_pass_1_level_price"),
	var_0_5:getValue("battle_pass_10_level_price"),
	var_0_5:getValue("battle_pass_limit_purchase_price")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.battlePass = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.handler = {}
	arg_1_0.currentNum = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	for iter_3_0 = 1, 3 do
		arg_3_0:shopItemLayout(iter_3_0)
	end

	arg_3_0:nodeByName("txt_num"):setString(arg_3_0.currentNum .. "/" .. var_0_6)

	local var_3_0 = false
	local var_3_1 = arg_3_0:nodeByName("btn_sub")

	var_3_1:setTouchEnabled(true)
	var_3_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			var_3_1:setScale(0.9)

			local var_4_0 = 0

			local function var_4_1()
				var_4_0 = var_4_0 + 0.03

				arg_3_0:decreaseCurrentNum()
			end

			local function var_4_2()
				var_4_0 = var_4_0 + 0.1

				if var_4_0 > 0.5 and var_4_0 <= 4 then
					var_3_0 = true

					arg_3_0:decreaseCurrentNum()
				elseif var_4_0 > 4 then
					arg_3_0.handler[2] = var_0_2.scheduleGlobal(var_4_1, 0.03)

					var_0_2.unscheduleGlobal(arg_3_0.handler[1])
				else
					var_3_0 = false
				end
			end

			var_3_0 = false
			arg_3_0.handler[1] = var_0_2.scheduleGlobal(var_4_2, 0.1)

			return true
		elseif arg_4_0.name == "ended" then
			var_3_1:setScale(1)

			if arg_3_0.handler[1] ~= nil then
				var_0_2.unscheduleGlobal(arg_3_0.handler[1])
			end

			if arg_3_0.handler[2] ~= nil then
				var_0_2.unscheduleGlobal(arg_3_0.handler[2])
			end

			if var_3_0 == false then
				arg_3_0:decreaseCurrentNum()
			end
		end
	end)

	local var_3_2 = arg_3_0:nodeByName("btn_add")

	var_3_2:setTouchEnabled(true)
	var_3_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			var_3_2:setScale(0.9)

			local var_7_0 = 0

			local function var_7_1()
				var_7_0 = var_7_0 + 0.03

				arg_3_0:addCurrentNum()
			end

			local function var_7_2()
				var_7_0 = var_7_0 + 0.1

				if var_7_0 > 0.5 and var_7_0 <= 4 then
					var_3_0 = true

					arg_3_0:addCurrentNum()
				elseif var_7_0 > 4 then
					arg_3_0.handler[2] = var_0_2.scheduleGlobal(var_7_1, 0.03)

					var_0_2.unscheduleGlobal(arg_3_0.handler[1])
				else
					var_3_0 = false
				end
			end

			var_3_0 = false
			arg_3_0.handler[1] = var_0_2.scheduleGlobal(var_7_2, 0.1)

			return true
		elseif arg_7_0.name == "ended" then
			var_3_2:setScale(1)

			if arg_3_0.handler[1] ~= nil then
				var_0_2.unscheduleGlobal(arg_3_0.handler[1])
			end

			if arg_3_0.handler[2] ~= nil then
				var_0_2.unscheduleGlobal(arg_3_0.handler[2])
			end

			if var_3_0 == false then
				arg_3_0:addCurrentNum()
			end
		end
	end)
end

function var_0_0.shopItemLayout(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_0.battlePass:getLevel()
	local var_10_1 = arg_10_0:nodeByName("bg_buy_" .. arg_10_1)
	local var_10_2 = arg_10_0:getItems(var_10_0, var_10_0 + var_0_8[arg_10_1])
	local var_10_3 = xyd.createLabel(18, cc.c3b(57, 64, 70))
	local var_10_4 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_14"), var_0_8[arg_10_1])
	local var_10_5 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_15"), var_10_0, var_10_0 + var_0_8[arg_10_1])

	var_10_1:getChildByName("txt_name"):setString(var_10_4)
	var_10_3:setAnchorPoint(0, 1)
	var_10_3:setWidth(300)
	var_10_3:setLineHeight(30)
	var_10_3:setString(var_10_5)
	var_10_3:setName("txt_desc")
	var_10_1:getChildByName("pos_desc"):addChild(var_10_3)

	local var_10_6 = var_10_1:getChildByName("list"):getContentSize()
	local var_10_7 = cc.ui.UITableView.new({
		itemGap = 17,
		size = var_10_6,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL
	}):addTo(var_10_1:getChildByName("list"))

	var_10_7:setName("list")
	arg_10_0:loadList(var_10_7, var_10_2)

	local var_10_8 = var_10_1:getChildByName("btn_buy")

	var_10_8:getChildByName("txt_price"):setString(var_0_9[arg_10_1])

	if arg_10_1 >= 2 then
		var_10_8:getChildByName("txt_original_price"):setString("(" .. var_0_9[1] * var_0_8[arg_10_1] .. ")")
	end

	if arg_10_1 == 3 then
		local var_10_9 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_16"), arg_10_0.battlePass:getLimitPurchaseBuyNum(), var_0_7)

		var_10_1:getChildByName("txt_limit"):setString(var_10_9)
	end

	var_10_8:addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			arg_10_0:buy(arg_10_1)
		end
	end)
end

function var_0_0.updateShopItem(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.battlePass:getLevel()
	local var_12_1 = arg_12_0:nodeByName("bg_buy_" .. arg_12_1)
	local var_12_2
	local var_12_3

	if arg_12_1 == 1 then
		local var_12_4 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_14"), var_0_8[arg_12_1] * arg_12_0.currentNum)

		var_12_2 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_15"), var_12_0, var_12_0 + var_0_8[arg_12_1] * arg_12_0.currentNum)
		var_12_3 = arg_12_0:getItems(var_12_0, var_12_0 + var_0_8[arg_12_1] * arg_12_0.currentNum)

		var_12_1:getChildByName("txt_name"):setString(var_12_4)
		var_12_1:getChildByName("btn_buy"):getChildByName("txt_price"):setString(var_0_9[arg_12_1] * arg_12_0.currentNum)
	else
		var_12_3 = arg_12_0:getItems(var_12_0, var_12_0 + var_0_8[arg_12_1])
		var_12_2 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_15"), var_12_0, var_12_0 + var_0_8[arg_12_1])
	end

	if arg_12_1 == 3 then
		local var_12_5 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_16"), arg_12_0.battlePass:getLimitPurchaseBuyNum(), var_0_7)

		var_12_1:getChildByName("txt_limit"):setString(var_12_5)
	end

	var_12_1:getChildByName("pos_desc"):getChildByName("txt_desc"):setString(var_12_2)
	arg_12_0:loadList(var_12_1:getChildByName("list"):getChildByName("list"), var_12_3)
end

function var_0_0.getItems(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {}
	local var_13_1 = {}

	for iter_13_0 = arg_13_1 + 1, arg_13_2 do
		local var_13_2, var_13_3 = var_0_3:getItem(iter_13_0)

		if var_13_2 and var_13_2 ~= 0 then
			if var_13_0[var_13_2] then
				var_13_0[var_13_2] = var_13_0[var_13_2] + var_13_3
			else
				var_13_0[var_13_2] = var_13_3
			end
		end

		local var_13_4, var_13_5 = var_0_3:getItem(iter_13_0, true)

		if var_13_4 and var_13_4 ~= 0 then
			if var_13_0[var_13_4] then
				var_13_0[var_13_4] = var_13_0[var_13_4] + var_13_5
			else
				var_13_0[var_13_4] = var_13_5
			end
		end
	end

	if next(var_13_0) then
		for iter_13_1, iter_13_2 in pairs(var_13_0) do
			table.insert(var_13_1, {
				item_id = iter_13_1,
				item_num = iter_13_2
			})
		end
	end

	return var_13_1
end

function var_0_0.loadList(arg_14_0, arg_14_1, arg_14_2)
	arg_14_1:removeAllItems()

	for iter_14_0 = 1, math.ceil(#arg_14_2 / 3) do
		local var_14_0 = arg_14_1:newItem()
		local var_14_1 = display.newNode()

		var_14_1:setContentSize(276, 78)

		for iter_14_1 = 1, 3 do
			local var_14_2 = (iter_14_0 - 1) * 3 + iter_14_1

			if not arg_14_2[var_14_2] then
				break
			end

			local var_14_3 = display.newNode()

			var_14_3:setContentSize(78, 78)
			xyd.setItemAndAddTips(var_14_3, arg_14_2[var_14_2].item_id, arg_14_2[var_14_2].item_num)
			var_14_3:setPosition((iter_14_1 - 1) * 99, 0)
			var_14_1:addChild(var_14_3)
		end

		var_14_0:addContent(var_14_1)
		var_14_0:setItemSize(276, 78)
		arg_14_1:addItem(var_14_0)
	end

	arg_14_1:reload()
end

function var_0_0.buy(arg_15_0, arg_15_1)
	if arg_15_1 == 1 then
		local var_15_0 = var_0_1:translation("BATTLE_PASS_TEXT_23")
		local var_15_1 = string.format(var_15_0, var_0_9[1] * arg_15_0.currentNum, var_0_8[1] * arg_15_0.currentNum)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_1, function()
			if arg_15_0.selfPlayer.crystal >= var_0_9[1] * arg_15_0.currentNum then
				arg_15_0.battlePass:buyLevel({
					is_discount = 0,
					lev = arg_15_0.currentNum
				}, function(arg_17_0, arg_17_1)
					if arg_17_0 == xyd.error.OK then
						for iter_17_0 = 1, 3 do
							arg_15_0:updateShopItem(iter_17_0)
						end
					end
				end)
			else
				local var_16_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_15_0.colorMode)
			end
		end, nil, 0, arg_15_0.colorMode)
	elseif arg_15_1 == 2 then
		local var_15_2 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_23"), var_0_9[2], var_0_8[2])

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_2, function()
			if arg_15_0.selfPlayer.crystal >= var_0_9[2] then
				arg_15_0.battlePass:buyLevel({
					is_discount = 1,
					lev = 10
				}, function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						for iter_20_0 = 1, 3 do
							arg_15_0:updateShopItem(iter_20_0)
						end
					end
				end)
			else
				local var_19_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_19_0, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_15_0.colorMode)
			end
		end, nil, 0, arg_15_0.colorMode)
	elseif arg_15_1 == 3 then
		if arg_15_0.battlePass:getLimitPurchaseBuyNum() >= var_0_7 then
			local var_15_3 = var_0_1:translation("BATTLE_PASS_TEXT_26")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_15_3
			})

			return
		end

		local var_15_4 = string.format(var_0_1:translation("BATTLE_PASS_TEXT_23"), var_0_9[3], var_0_8[3])

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_15_4, function()
			if arg_15_0.selfPlayer.crystal >= var_0_9[3] then
				arg_15_0.battlePass:buyLimitPurchase({}, function(arg_23_0, arg_23_1)
					if arg_23_0 == xyd.error.OK then
						for iter_23_0 = 1, 3 do
							arg_15_0:updateShopItem(iter_23_0)
						end
					end
				end)
			else
				local var_22_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_22_0, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_15_0.colorMode)
			end
		end, nil, 0, arg_15_0.colorMode)
	end
end

function var_0_0.decreaseCurrentNum(arg_25_0)
	if arg_25_0.currentNum <= 1 then
		return
	else
		arg_25_0.currentNum = arg_25_0.currentNum - 1
	end

	arg_25_0:updateNum()
end

function var_0_0.addCurrentNum(arg_26_0)
	if arg_26_0.currentNum >= var_0_6 then
		return
	else
		arg_26_0.currentNum = arg_26_0.currentNum + 1
	end

	arg_26_0:updateNum()
end

function var_0_0.updateNum(arg_27_0)
	arg_27_0:nodeByName("txt_num"):setString(arg_27_0.currentNum .. "/" .. var_0_6)
	arg_27_0:updateShopItem(1)
end

return var_0_0
