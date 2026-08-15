local var_0_0 = class("LotteryUseConsumeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentNum = 1
	arg_1_0.times = arg_1_2.times
	arg_1_0.canSelectNums = arg_1_2.canSelectNums
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.maxNum = math.min(arg_1_0.canSelectNums, arg_1_0.times)
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
	arg_4_0:nodeByName("text_use_num"):setString(var_0_1:translation("LOTTERY_CONSUME_TEXT2"))
	arg_4_0:nodeByName("word_fanhui"):setString(var_0_1:translation("FAQ_RETURN"))
	arg_4_0:nodeByName("word_confirm"):setString(var_0_1:translation("SURE"))
	arg_4_0:nodeByName("max"):setString(var_0_1:translation("MAX"))
	arg_4_0:nodeByName("item_num"):setString(var_0_1:translation("LOTTERY_CONSUME_TEXT5") .. arg_4_0.times)
	arg_4_0:nodeByName("use_num"):setString(arg_4_0.currentNum)

	local var_4_0

	arg_4_0:nodeByName("btn_yes"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = string.format(var_0_1:translation("LOTTERY_CONSUME_TEXT12"), arg_4_0.currentNum)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_0, function()
				arg_4_0.callback(arg_4_0.currentNum)
				xyd.WindowManager.get():closeWindow(arg_4_0.name)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0.name)
		end
	end)
	arg_4_0:nodeByName("btn_max"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_4_0:nodeByName("btn_max"):setScale(0.9, 0.9)
		end

		if arg_8_1 == ccui.TouchEventType.moved then
			arg_4_0:nodeByName("btn_max"):setScale(1, 1)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:nodeByName("btn_max"):setScale(1, 1)

			arg_4_0.currentNum = arg_4_0.maxNum

			arg_4_0:updateNum()
		end
	end)

	local var_4_1 = cc.ui.UIPushButton.new({
		pressed = "windows/activities/1148/btn_jian2.png",
		disabled = "windows/activities/1148/btn_jian.png",
		normal = "windows/activities/1148/btn_jian.png"
	})

	var_4_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_1:setScale(1, 1)
	var_4_1:addTo(arg_4_0:nodeByName("btn_jian"))
	var_4_1:setName("jiandian")

	local var_4_2 = false

	var_4_1:onButtonPressed(function(arg_9_0)
		local var_9_0 = 0

		local function var_9_1()
			var_9_0 = var_9_0 + 0.03

			if arg_4_0.decreaseCurrentNum then
				arg_4_0:decreaseCurrentNum()
			end
		end

		local function var_9_2()
			var_9_0 = var_9_0 + 0.1

			if var_9_0 > 0.5 and var_9_0 <= 4 then
				var_4_2 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_9_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_9_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_2 = false
			end
		end

		var_4_2 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_9_2, 0.1)
	end)
	var_4_1:onButtonRelease(function(arg_12_0)
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
		pressed = "windows/activities/1148/btn_plus2.png",
		disabled = "windows/activities/1148/btn_plus.png",
		normal = "windows/activities/1148/btn_plus.png"
	})

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:setScale(1, 1)
	var_4_3:addTo(arg_4_0:nodeByName("btn_add"))
	var_4_3:setName("jiadian")

	local var_4_4 = false

	var_4_3:onButtonPressed(function(arg_13_0)
		local var_13_0 = 0

		local function var_13_1()
			var_13_0 = var_13_0 + 0.03

			if arg_4_0.addCurrentNum then
				arg_4_0:addCurrentNum()
			end
		end

		local function var_13_2()
			var_13_0 = var_13_0 + 0.1

			if var_13_0 > 0.5 and var_13_0 <= 4 then
				var_4_4 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_13_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_13_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_4 = false
			end
		end

		var_4_4 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_13_2, 0.1)
	end)
	var_4_3:onButtonRelease(function(arg_16_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_4 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
end

function var_0_0.addCurrentNum(arg_17_0)
	if arg_17_0.currentNum + 1 >= arg_17_0.maxNum then
		arg_17_0.currentNum = arg_17_0.maxNum
	else
		arg_17_0.currentNum = arg_17_0.currentNum + 1
	end

	arg_17_0:nodeByName("use_num"):setString(arg_17_0.currentNum)
	arg_17_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_18_0)
	if arg_18_0.currentNum - 1 <= 0 then
		arg_18_0.currentNum = 1
	else
		arg_18_0.currentNum = arg_18_0.currentNum - 1
	end

	arg_18_0:nodeByName("use_num"):setString(arg_18_0.currentNum)
	arg_18_0:updateNum()
end

function var_0_0.updateNum(arg_19_0)
	arg_19_0:nodeByName("use_num"):setString(arg_19_0.currentNum)
end

function var_0_0.didClose(arg_20_0)
	if arg_20_0.handler then
		if arg_20_0.handler[1] then
			var_0_2.unscheduleGlobal(arg_20_0.handler[1])
		end

		if arg_20_0.handler[2] then
			var_0_2.unscheduleGlobal(arg_20_0.handler[2])
		end
	end
end

return var_0_0
