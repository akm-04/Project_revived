local var_0_0 = class("LotteryBuyConsumeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = import("app.common.ui.SplitLine")
local var_0_4 = 999

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentNum = 1
	arg_1_0.times = arg_1_2.times
	arg_1_0.handler = {}
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
	xyd.setItemBorder(arg_4_0:nodeByName("item"), xyd.tables.misc.activityLotteryConsumeItem)
	arg_4_0:nodeByName("item_name"):setString(xyd.tables.item:name(xyd.tables.misc.activityLotteryConsumeItem))
	arg_4_0:nodeByName("text_cost"):setString(var_0_1:translation("LOTTERY_CONSUME_TEXT1"))
	arg_4_0:nodeByName("text_buy_num"):setString(var_0_1:translation("LOTTERY_CONSUME_TEXT2"))
	arg_4_0:nodeByName("word_fanhui"):setString(var_0_1:translation("REGION_ARENA_TEXT_12"))
	arg_4_0:nodeByName("word_confirm"):setString(var_0_1:translation("SURE"))

	local var_4_0 = arg_4_0:nodeByName("line")

	var_0_3.new({
		size = 420
	}):addTo(var_4_0)
	arg_4_0:nodeByName("item_num"):setString(var_0_1:translation("LOTTERY_CONSUME_TEXT5") .. arg_4_0.times)
	arg_4_0:nodeByName("cost"):setString(xyd.tables.misc.activityLotteryConsumePrice)
	arg_4_0:nodeByName("buy_num"):setString(arg_4_0.currentNum)

	local var_4_1

	arg_4_0:nodeByName("btn_yes"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.selfPlayer.crystal < arg_4_0.currentNum * xyd.tables.misc.activityLotteryConsumePrice then
				local var_5_0 = var_0_1:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
					local var_6_0 = {}

					var_6_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_6_0)
				end, nil, nil, arg_4_0.colorMode)
			else
				local var_5_1 = string.format(var_0_1:translation("LOTTERY_CONSUME_TEXT4"), arg_4_0.currentNum * xyd.tables.misc.activityLotteryConsumePrice, arg_4_0.currentNum)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
					local var_7_0 = {
						num = arg_4_0.currentNum
					}

					xyd.Backend.get():request(xyd.mid.LOTTERY_CONSUME_BUY_ITEM, var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							local var_8_0 = xyd.WindowManager.get():getWindow("activities")

							if var_8_0 and var_8_0.openedActivities[xyd.Activities.LotteryConsume] then
								var_8_0.openedActivities[xyd.Activities.LotteryConsume].details.base_info = arg_8_1

								var_8_0.openedActivities[xyd.Activities.LotteryConsume]:updateWnd()
							end

							xyd.WindowManager.get():closeWindow(arg_4_0.name)
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

	local var_4_2 = cc.ui.UIPushButton.new({
		pressed = "windows/activities/1148/btn_jian2.png",
		disabled = "windows/activities/1148/btn_jian.png",
		normal = "windows/activities/1148/btn_jian.png"
	})

	var_4_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_2:setScale(1, 1)
	var_4_2:addTo(arg_4_0:nodeByName("btn_jian"))
	var_4_2:setName("jiandian")

	local var_4_3 = false

	var_4_2:onButtonPressed(function(arg_10_0)
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
				var_4_3 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_10_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_3 = false
			end
		end

		var_4_3 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_10_2, 0.1)
	end)
	var_4_2:onButtonRelease(function(arg_13_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_3 == false and arg_4_0.decreaseCurrentNum then
			arg_4_0:decreaseCurrentNum()
		end
	end)

	local var_4_4 = cc.ui.UIPushButton.new({
		pressed = "windows/activities/1148/btn_plus2.png",
		disabled = "windows/activities/1148/btn_plus.png",
		normal = "windows/activities/1148/btn_plus.png"
	})

	var_4_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_4:setScale(1, 1)
	var_4_4:addTo(arg_4_0:nodeByName("btn_add"))
	var_4_4:setName("jiadian")

	local var_4_5 = false

	var_4_4:onButtonPressed(function(arg_14_0)
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
				var_4_5 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_14_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_14_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_5 = false
			end
		end

		var_4_5 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_14_2, 0.1)
	end)
	var_4_4:onButtonRelease(function(arg_17_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_5 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
	arg_4_0:initChatBox()
end

function var_0_0.initChatBox(arg_18_0)
	local var_18_0 = xyd.AssetLoader.get()
	local var_18_1 = 24
	local var_18_2 = arg_18_0:nodeByName("bg_yellow")
	local var_18_3 = "windows/login/transparent.png"

	arg_18_0.chatBox_ = ccui.EditBox:create(var_18_2:getContentSize(), var_18_3)

	arg_18_0.chatBox_:setAnchorPoint(0, 0)
	arg_18_0.chatBox_:pos(0, 0):addTo(var_18_2)
	arg_18_0.chatBox_:setFont(var_18_0.FONT_NAME, var_18_1)
	arg_18_0.chatBox_:setPlaceholderFont(var_18_0.FONT_NAME, var_18_1)
	arg_18_0.chatBox_:setPlaceHolder(var_0_1:translation("CHAT_INPUT_MESSAGE"))
	arg_18_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_18_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_18_0.chatBox_:registerScriptEditBoxHandler(handler(arg_18_0, arg_18_0.inputboxEventHandler))
	arg_18_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_19_0, arg_19_1)
	if arg_19_1 == "return" then
		local var_19_0 = arg_19_0.chatBox_:getText()

		arg_19_0.chatBox_:setText("")

		local var_19_1 = math.floor(tonumber(var_19_0) or 0)

		arg_19_0:nodeByName("buy_num"):setVisible(true)

		if var_19_0 ~= "" then
			if var_19_1 then
				if var_19_1 <= var_0_4 and var_19_1 > 0 then
					arg_19_0.currentNum = math.ceil(var_19_1)

					arg_19_0:nodeByName("buy_num"):setString(arg_19_0.currentNum)
					arg_19_0:updateNum()
				else
					local var_19_2 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_19_2
					})

					return
				end

				return
			else
				local var_19_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_3
				})

				return
			end
		else
			return
		end
	elseif arg_19_1 == "began" then
		arg_19_0.chatBox_:setText("")
		arg_19_0:nodeByName("buy_num"):setVisible(false)
	end
end

function var_0_0.addCurrentNum(arg_20_0)
	if arg_20_0.currentNum + 1 >= var_0_4 then
		arg_20_0.currentNum = var_0_4
	else
		arg_20_0.currentNum = arg_20_0.currentNum + 1
	end

	arg_20_0:nodeByName("buy_num"):setString(arg_20_0.currentNum)
	arg_20_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_21_0)
	if arg_21_0.currentNum - 1 <= 0 then
		arg_21_0.currentNum = 1
	else
		arg_21_0.currentNum = arg_21_0.currentNum - 1
	end

	arg_21_0:nodeByName("buy_num"):setString(arg_21_0.currentNum)
	arg_21_0:updateNum()
end

function var_0_0.updateNum(arg_22_0)
	arg_22_0:nodeByName("buy_num"):setString(arg_22_0.currentNum)
	arg_22_0:nodeByName("cost"):setString(arg_22_0.currentNum * xyd.tables.misc.activityLotteryConsumePrice)
end

function var_0_0.didClose(arg_23_0)
	if arg_23_0.handler then
		if arg_23_0.handler[1] then
			var_0_2.unscheduleGlobal(arg_23_0.handler[1])
		end

		if arg_23_0.handler[2] then
			var_0_2.unscheduleGlobal(arg_23_0.handler[2])
		end
	end
end

return var_0_0
