local var_0_0 = class("ActivityContractBuyTicketWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.buyTimes = arg_1_2.buyTimes
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.itemID = xyd.tables.misc:getValue("activity_tie_summon_item")
	arg_1_0.currentNum = 1
	arg_1_0.maxNum = xyd.tables.misc:getValue("activity_tie_ticket_buy_limit") - arg_1_0.buyTimes
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	xyd.setItemBorder(arg_3_0:nodeByName("icon"), arg_3_0.itemID)
	arg_3_0:nodeByName("text_num"):setString(arg_3_0.currentNum .. "/" .. arg_3_0.maxNum)
	arg_3_0:nodeByName("text_name"):setString(xyd.tables.item:name(arg_3_0.itemID))
	arg_3_0:nodeByName("text_own"):setString(var_0_2:translation("ACTIVITY_CONTRACT_TEXT_13"))
	arg_3_0:nodeByName("text_own_num"):setString(arg_3_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc:getValue("activity_tie_summon_item")))
	arg_3_0:nodeByName("text_tip"):setString(var_0_2:translation("ACTIVITY_CONTRACT_TEXT_14"))
	arg_3_0:nodeByName("text_ok"):setString(var_0_2:translation("OK"))
	arg_3_0:nodeByName("text_cancel"):setString(var_0_2:translation("CANCEL"))
	arg_3_0:nodeByName("text_max"):setString(var_0_2:translation("MAX"))

	local var_3_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_3_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_0:setScale(1, 1)
	var_3_0:addTo(arg_3_0:nodeByName("background"))
	var_3_0:setPosition(arg_3_0:nodeByName("btn_minus"):getPosition())
	arg_3_0:nodeByName("btn_minus"):setVisible(false)
	var_3_0:setName("jiandian")

	local var_3_1 = false

	var_3_0:onButtonPressed(function(arg_4_0)
		var_3_0:setScale(0.9)

		local var_4_0 = 0

		local function var_4_1()
			var_4_0 = var_4_0 + 0.03

			if arg_3_0.decreaseCurrentNum then
				arg_3_0:decreaseCurrentNum()
			end
		end

		local function var_4_2()
			var_4_0 = var_4_0 + 0.1

			if var_4_0 > 0.5 and var_4_0 <= 4 then
				var_3_1 = true

				if arg_3_0.decreaseCurrentNum then
					arg_3_0:decreaseCurrentNum()
				end
			elseif var_4_0 > 4 then
				arg_3_0.handler[2] = var_0_1.scheduleGlobal(var_4_1, 0.03)

				var_0_1.unscheduleGlobal(arg_3_0.handler[1])
			else
				var_3_1 = false
			end
		end

		var_3_1 = false
		arg_3_0.handler[1] = var_0_1.scheduleGlobal(var_4_2, 0.1)
	end)
	var_3_0:onButtonRelease(function(arg_7_0)
		var_3_0:setScale(1)

		if arg_3_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[1])
		end

		if arg_3_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[2])
		end

		if var_3_1 == false and arg_3_0.decreaseCurrentNum then
			arg_3_0:decreaseCurrentNum()
		end
	end)

	local var_3_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_3_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_2:setScale(1, 1)
	var_3_2:addTo(arg_3_0:nodeByName("background"))
	var_3_2:setPosition(arg_3_0:nodeByName("btn_add"):getPosition())
	arg_3_0:nodeByName("btn_add"):setVisible(false)
	var_3_2:setName("jiadian")

	local var_3_3 = false

	var_3_2:onButtonPressed(function(arg_8_0)
		var_3_2:setScale(0.9)

		local var_8_0 = 0

		local function var_8_1()
			var_8_0 = var_8_0 + 0.03

			if arg_3_0.addCurrentNum then
				arg_3_0:addCurrentNum()
			end
		end

		local function var_8_2()
			var_8_0 = var_8_0 + 0.1

			if var_8_0 > 0.5 and var_8_0 <= 4 then
				var_3_3 = true

				if arg_3_0.addCurrentNum then
					arg_3_0:addCurrentNum()
				end
			elseif var_8_0 > 4 then
				arg_3_0.handler[2] = var_0_1.scheduleGlobal(var_8_1, 0.03)

				var_0_1.unscheduleGlobal(arg_3_0.handler[1])
			else
				var_3_3 = false
			end
		end

		var_3_3 = false
		arg_3_0.handler[1] = var_0_1.scheduleGlobal(var_8_2, 0.1)
	end)
	var_3_2:onButtonRelease(function(arg_11_0)
		var_3_2:setScale(1)

		if arg_3_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[1])
		end

		if arg_3_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[2])
		end

		if var_3_3 == false and arg_3_0.addCurrentNum then
			arg_3_0:addCurrentNum()
		end
	end)
	arg_3_0:nodeByName("btn_max"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_3_0.currentNum = arg_3_0.maxNum

			arg_3_0:nodeByName("text_num"):setString(arg_3_0.currentNum .. "/" .. arg_3_0.maxNum)
		end
	end)
	arg_3_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = xyd.tables.misc:getValue("activity_tie_ticket_price")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("ACTIVITY_CONTRACT_TEXT_17"), arg_3_0.currentNum, arg_3_0.currentNum * var_13_0), function()
				if arg_3_0.selfPlayer.crystal < var_13_0 * arg_3_0.currentNum then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
						local var_15_0 = {}

						var_15_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
					end, nil, nil, xyd.ColorMode.PURPLE)

					return
				end

				local var_14_0 = {
					num = arg_3_0.currentNum
				}

				xyd.Backend.get():request(xyd.mid.ACTIVITY_CONTRACT_BUG_TICKET, var_14_0, function(arg_16_0, arg_16_1)
					if arg_16_0 == xyd.error.OK then
						arg_3_0.selfPlayer:handleRewards(arg_16_1.awards)

						local var_16_0 = xyd.WindowManager.get():getWindow("activities")

						if var_16_0 then
							local var_16_1 = var_16_0.openedActivities[xyd.Activities.Contract]

							if var_16_1 then
								var_16_1.buyTimes = arg_16_1.buy_times
								var_16_1.activity.details.buy_times = arg_16_1.buy_times
							end
						end

						arg_3_0:close()
					end
				end)
			end, nil, 0, xyd.ColorMode.PURPLE)
		end
	end)
	arg_3_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0:close()
		end
	end)
end

function var_0_0.addCurrentNum(arg_18_0)
	if arg_18_0.currentNum + 1 >= arg_18_0.maxNum then
		arg_18_0.currentNum = arg_18_0.maxNum
	else
		arg_18_0.currentNum = arg_18_0.currentNum + 1
	end

	arg_18_0:nodeByName("text_num"):setString(arg_18_0.currentNum .. "/" .. arg_18_0.maxNum)
end

function var_0_0.decreaseCurrentNum(arg_19_0)
	if arg_19_0.currentNum - 1 <= 0 then
		arg_19_0.currentNum = 1
	else
		arg_19_0.currentNum = arg_19_0.currentNum - 1
	end

	arg_19_0:nodeByName("text_num"):setString(arg_19_0.currentNum .. "/" .. arg_19_0.maxNum)
end

function var_0_0.didOpen(arg_20_0)
	arg_20_0:addBlockLayer()
end

return var_0_0
