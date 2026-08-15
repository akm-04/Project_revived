local var_0_0 = class("DiceBuyConsumeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = 999

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentNum = 1
	arg_1_0.diceItemNum = arg_1_2.diceItemNum
	arg_1_0.nowBuyTime = arg_1_2.nowBuyTime
	arg_1_0.totalBuyPrice = 0
	arg_1_0.handler = {}
	arg_1_0.buyPrice = {
		{
			10,
			20,
			50,
			80,
			100
		},
		{
			20,
			50,
			80,
			100,
			100
		},
		{
			50,
			80,
			100,
			100,
			100
		},
		{
			80,
			100,
			100,
			100,
			100
		}
	}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("item"):removeAllChildren()
	xyd.setItemBorder(arg_4_0:nodeByName("item"), xyd.tables.misc.activityRichDiceItem)
	arg_4_0:nodeByName("item_name"):setString(var_0_1:translation("ACTIVITY_RICH_DICE"))
	arg_4_0:nodeByName("text_cost"):setString(var_0_1:translation("SUPER_RICH_DICE_TEXT1"))
	arg_4_0:nodeByName("item_buy_num"):setString(var_0_1:translation("SUPER_RICH_DICE_TEXT2"))
	arg_4_0:nodeByName("item_num_txt"):setString(var_0_1:translation("SUPER_RICH_DICE_TEXT3"))
	arg_4_0:nodeByName("item_num"):setString(arg_4_0.diceItemNum)
	arg_4_0:nodeByName("buy_num"):setString(arg_4_0.currentNum)

	local var_4_0

	arg_4_0:nodeByName("btn_yes"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:updateNum()

			if arg_4_0.selfPlayer.crystal < arg_4_0.totalBuyPrice then
				local var_5_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
					local var_6_0 = {}

					var_6_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
				end, nil, nil, arg_4_0.colorMode)
			else
				local var_5_1 = string.format(var_0_1:translation("ACTIVITY_RICH_DICE_TIP"), arg_4_0.totalBuyPrice, arg_4_0.currentNum)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
					local var_7_0 = {
						num = arg_4_0.currentNum
					}

					arg_4_0.superRich:monoplyBuyDice(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							xyd.WindowManager.get():closeWindow(arg_4_0)
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			end
		end
	end)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0.name)
		end
	end)

	local var_4_1 = cc.ui.UIPushButton.new({
		pressed = "windows/zillionaire/shop/minus4.png",
		disabled = "windows/zillionaire/shop/minus3.png",
		normal = "windows/zillionaire/shop/minus3.png"
	})

	var_4_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_1:setScale(1, 1)
	var_4_1:addTo(arg_4_0:nodeByName("btn_minus1"))
	var_4_1:setName("jiandian")

	local var_4_2 = false

	var_4_1:onButtonPressed(function(arg_10_0)
		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_4_0.decreaseCurrentNum then
				arg_4_0:decreaseCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_4_2 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_10_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_2 = false
			end
		end

		var_4_2 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_10_2, 0.1)
	end)
	var_4_1:onButtonRelease(function(arg_13_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_2 == false and arg_4_0.decreaseCurrentNum then
			arg_4_0:decreaseCurrentNum()
		end
	end)

	local var_4_3 = cc.ui.UIPushButton.new({
		pressed = "windows/zillionaire/shop/plus4.png",
		disabled = "windows/zillionaire/shop/plus3.png",
		normal = "windows/zillionaire/shop/plus3.png"
	})

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:setScale(1, 1)
	var_4_3:addTo(arg_4_0:nodeByName("btn_add1"))
	var_4_3:setName("jiadian")
	var_4_3:onButtonPressed(function(arg_14_0)
		local var_14_0 = 0

		local function var_14_1()
			var_14_0 = var_14_0 + 0.03

			if arg_4_0.addCurrentNum then
				arg_4_0:addCurrentNum()
			end
		end

		local function var_14_2()
			var_14_0 = var_14_0 + 0.1

			if var_14_0 > 0.5 and var_14_0 <= 4 then
				var_4_2 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_14_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_14_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_2 = false
			end
		end

		var_4_2 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_14_2, 0.1)
	end)
	var_4_3:onButtonRelease(function(arg_17_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_2 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
	arg_4_0:updateNum()
end

function var_0_0.addCurrentNum(arg_18_0)
	if arg_18_0.currentNum + 1 >= var_0_3 then
		arg_18_0.currentNum = var_0_3
	else
		arg_18_0.currentNum = arg_18_0.currentNum + 1
	end

	arg_18_0:nodeByName("buy_num"):setString(arg_18_0.currentNum)
	arg_18_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_19_0)
	if arg_19_0.currentNum - 1 <= 0 then
		arg_19_0.currentNum = 1
	else
		arg_19_0.currentNum = arg_19_0.currentNum - 1
	end

	arg_19_0:nodeByName("buy_num"):setString(arg_19_0.currentNum)
	arg_19_0:updateNum()
end

function var_0_0.updateNum(arg_20_0)
	arg_20_0:nodeByName("buy_num"):setString(arg_20_0.currentNum)

	local var_20_0 = 0

	if arg_20_0.nowBuyTime > 4 then
		arg_20_0.totalBuyPrice = arg_20_0.currentNum * xyd.tables.misc.activityRichDiceCost

		arg_20_0:nodeByName("cost"):setString(arg_20_0.totalBuyPrice)
	else
		for iter_20_0 = 1, arg_20_0.currentNum do
			if arg_20_0.currentNum <= 5 then
				var_20_0 = arg_20_0.buyPrice[arg_20_0.nowBuyTime][iter_20_0] + var_20_0
				arg_20_0.totalBuyPrice = var_20_0
			else
				var_20_0 = var_20_0 + xyd.tables.misc.activityRichDiceCost
				arg_20_0.totalBuyPrice = var_20_0
			end
		end

		if arg_20_0.currentNum > 5 then
			arg_20_0.totalBuyPrice = var_20_0 - 240
		end

		arg_20_0:nodeByName("cost"):setString(arg_20_0.totalBuyPrice)
	end
end

function var_0_0.didClose(arg_21_0)
	if arg_21_0.handler then
		if arg_21_0.handler[1] then
			var_0_2.unscheduleGlobal(arg_21_0.handler[1])
		end

		if arg_21_0.handler[2] then
			var_0_2.unscheduleGlobal(arg_21_0.handler[2])
		end
	end
end

return var_0_0
