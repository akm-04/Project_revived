local var_0_0 = class("ActivityBalloonBuyDartWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.currentNum = 1
	arg_1_0.price = var_0_4:getValue("activity_balloon_diamond_price")
	arg_1_0.maxNum = math.max(math.floor(arg_1_0.selfPlayer.crystal / arg_1_0.price), 1)
	arg_1_0.itemID = var_0_4:getValue("activity_balloon_item_id")
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
	arg_2_0:initBtns()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_1"):setString(var_0_3:translation("ACTIVITY_BALLOON_TEXT_10"))
	arg_4_0:nodeByName("txt_2"):setString(var_0_3:translation("ACTIVITY_BALLOON_TEXT_11"))
	arg_4_0:nodeByName("txt_3"):setString(var_0_3:translation("ACTIVITY_BALLOON_TEXT_12"))
	arg_4_0:nodeByName("txt_4"):setString(var_0_3:translation("ACTIVITY_BALLOON_TEXT_13"))
	arg_4_0:nodeByName("txt_max"):setString(var_0_3:translation("ACTIVITY_BALLOON_TEXT_14"))
	arg_4_0:nodeByName("txt_buy"):setString(var_0_3:translation("ACTIVITY_BALLOON_TEXT_15"))
	xyd.setItemAndAddTips(arg_4_0:nodeByName("item"), arg_4_0.itemID)
	arg_4_0:nodeByName("txt_name"):setString(xyd.tables.item:name(arg_4_0.itemID))
	arg_4_0:nodeByName("txt_num"):setString(arg_4_0.backpack:getItemNumByID(arg_4_0.itemID))

	local var_4_0 = var_0_1.new({
		size = 402
	})

	arg_4_0:nodeByName("pos_line"):addChild(var_4_0)
	arg_4_0:updateCurrentNum()
end

function var_0_0.initBtns(arg_5_0)
	arg_5_0:nodeByName("btn_shop"):setVisible(false)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_shop"), nil, function()
		if arg_5_0.activities:isActivityOpen(xyd.Activities.MonthLimit2) then
			xyd.WindowManager.get():openWindow("month_limit2")
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_3:translation("ACTIVITY_NO_OPEN")
			})
		end
	end)

	local var_5_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_5_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_0:setScale(1, 1)
	var_5_0:addTo(arg_5_0:nodeByName("btn_sub"))
	var_5_0:setName("jiandian")

	local var_5_1 = false

	var_5_0:onButtonPressed(function(arg_7_0)
		var_5_0:setScale(0.9)

		local var_7_0 = 0

		local function var_7_1()
			var_7_0 = var_7_0 + 0.03

			if arg_5_0.decreaseCurrentNum then
				arg_5_0:decreaseCurrentNum()
			end
		end

		local function var_7_2()
			var_7_0 = var_7_0 + 0.1

			if var_7_0 > 0.5 and var_7_0 <= 4 then
				var_5_1 = true

				if arg_5_0.decreaseCurrentNum then
					arg_5_0:decreaseCurrentNum()
				end
			elseif var_7_0 > 4 then
				arg_5_0.handler[2] = var_0_2.scheduleGlobal(var_7_1, 0.03)

				var_0_2.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_1 = false
			end
		end

		var_5_1 = false
		arg_5_0.handler[1] = var_0_2.scheduleGlobal(var_7_2, 0.1)
	end)
	var_5_0:onButtonRelease(function(arg_10_0)
		var_5_0:setScale(1)

		if arg_5_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_1 == false and arg_5_0.decreaseCurrentNum then
			arg_5_0:decreaseCurrentNum()
		end
	end)

	local var_5_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_5_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_2:setScale(1, 1)
	var_5_2:addTo(arg_5_0:nodeByName("btn_add"))
	var_5_2:setName("jiadian")

	local var_5_3 = false

	var_5_2:onButtonPressed(function(arg_11_0)
		var_5_2:setScale(0.9)

		local var_11_0 = 0

		local function var_11_1()
			var_11_0 = var_11_0 + 0.03

			if arg_5_0.addCurrentNum then
				arg_5_0:addCurrentNum()
			end
		end

		local function var_11_2()
			var_11_0 = var_11_0 + 0.1

			if var_11_0 > 0.5 and var_11_0 <= 4 then
				var_5_3 = true

				if arg_5_0.addCurrentNum then
					arg_5_0:addCurrentNum()
				end
			elseif var_11_0 > 4 then
				arg_5_0.handler[2] = var_0_2.scheduleGlobal(var_11_1, 0.03)

				var_0_2.unscheduleGlobal(arg_5_0.handler[1])
			else
				var_5_3 = false
			end
		end

		var_5_3 = false
		arg_5_0.handler[1] = var_0_2.scheduleGlobal(var_11_2, 0.1)
	end)
	var_5_2:onButtonRelease(function(arg_14_0)
		var_5_2:setScale(1)

		if arg_5_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[1])
		end

		if arg_5_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_5_0.handler[2])
		end

		if var_5_3 == false and arg_5_0.addCurrentNum then
			arg_5_0:addCurrentNum()
		end
	end)
	arg_5_0:nodeByName("btn_max"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			arg_5_0.currentNum = arg_5_0.maxNum

			arg_5_0:updateCurrentNum()
		end
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("btn_buy"), nil, function()
		local var_16_0 = string.format(var_0_3:translation("ACTIVITY_BALLOON_TEXT_17"), arg_5_0.currentNum * arg_5_0.price, arg_5_0.currentNum)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_0, function()
			if arg_5_0.selfPlayer.crystal >= arg_5_0.currentNum * arg_5_0.price then
				xyd.Backend.get():request(xyd.mid.BALLOON_BUY, {
					num = arg_5_0.currentNum
				}, function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						arg_5_0.backpack:addItemsByID(arg_5_0.itemID, arg_5_0.currentNum)
						arg_5_0.callback()
						arg_5_0:close()
					end
				end)
			else
				local var_17_0 = var_0_3:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_17_0, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end)
			end
		end, nil, 0)
	end)
end

function var_0_0.addCurrentNum(arg_20_0)
	if arg_20_0.currentNum < arg_20_0.maxNum then
		arg_20_0.currentNum = arg_20_0.currentNum + 1
	else
		return
	end

	arg_20_0:updateCurrentNum()
end

function var_0_0.decreaseCurrentNum(arg_21_0)
	if arg_21_0.currentNum > 1 then
		arg_21_0.currentNum = arg_21_0.currentNum - 1
	else
		return
	end

	arg_21_0:updateCurrentNum()
end

function var_0_0.updateCurrentNum(arg_22_0)
	arg_22_0:nodeByName("txt_buy_num"):setString(arg_22_0.currentNum .. "/" .. arg_22_0.maxNum)
	arg_22_0:nodeByName("txt_price"):setString(arg_22_0.currentNum * arg_22_0.price)
end

return var_0_0
