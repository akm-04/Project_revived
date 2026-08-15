local var_0_0 = class("ChocolateSlotMachineWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 35

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.times = arg_1_2.times
	arg_1_0.is_raise = arg_1_2.is_raise
	arg_1_0.is_coin = arg_1_2.is_coin
	arg_1_0.coinID = arg_1_2.coinID
	arg_1_0.raisePirce = xyd.tables.misc.activityChocolateSlotMachineDiamondCost
	arg_1_0.doublePrice = xyd.tables.misc.activityChocolateSlotMachineDoubleCost
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:updateRaise()
	arg_3_0:updateTxt()
	arg_3_0:nodeByName("btn_click"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("btn_click"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.is_raise = 1 - arg_3_0.is_raise

			arg_3_0:updateRaise()
		end
	end)
	arg_3_0:nodeByName("cancel_txt"):setString(var_0_1:translation("CANCEL"))
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("close"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("confirm_txt"):setString(var_0_1:translation("OK"))
	arg_3_0:nodeByName("btn_confirm"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("btn_confirm"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_3_0.is_coin then
				if arg_3_0.is_raise == 1 then
					arg_3_0.need_crystal = arg_3_0.times * arg_3_0.doublePrice
				else
					arg_3_0.need_crystal = 0
				end
			elseif arg_3_0.is_raise == 1 then
				arg_3_0.need_crystal = arg_3_0.times * arg_3_0.doublePrice + arg_3_0.times * arg_3_0.raisePirce
			else
				arg_3_0.need_crystal = arg_3_0.times * arg_3_0.raisePirce
			end

			if arg_3_0.selfPlayer.crystal < arg_3_0.need_crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_7_0 = {}

					var_7_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
				end, nil, nil, arg_3_0.colorMode)

				return
			else
				local var_6_0 = {
					times = arg_3_0.times,
					is_raise = arg_3_0.is_raise
				}

				arg_3_0.model:getChocolateSlot(var_6_0, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						if arg_3_0.is_coin then
							local var_8_0 = {
								itemID = arg_3_0.coinID,
								itemNum = arg_3_0.times
							}

							arg_3_0.selfPlayer:getBackpack():removeItem(var_8_0)
						end

						local var_8_1
						local var_8_2 = {}

						if arg_8_1 and arg_8_1.awards then
							var_8_1 = arg_8_1.award_times
							var_8_2.awards = arg_8_1.awards
							var_8_2.extra_awards = arg_8_1.extra_awards
							var_8_2.times = arg_3_0.times
							var_8_2.details = arg_8_1.details
						end

						local var_8_3 = xyd.WindowManager.get():getWindow("chocolate_slot_machine")

						if var_8_3 then
							var_8_3:updateCoinNum(var_8_1)
							var_8_3:getAwards(var_8_2)
						end
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = "出错了"
						})
					end
				end)
			end
		end
	end)
end

function var_0_0.updateRaise(arg_9_0)
	if arg_9_0.is_raise == 1 then
		arg_9_0:nodeByName("txt2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP8"))
		arg_9_0:nodeByName("gou"):setVisible(true)
	else
		arg_9_0:nodeByName("txt2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP2"))
		arg_9_0:nodeByName("gou"):setVisible(false)
	end
end

function var_0_0.updateTxt(arg_10_0)
	if arg_10_0.is_coin then
		arg_10_0:nodeByName("txt1"):setString(string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP12"), arg_10_0.times, arg_10_0.times))
	else
		arg_10_0:nodeByName("txt1"):setString(string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP1"), arg_10_0.times * arg_10_0.raisePirce, arg_10_0.times))
	end

	if arg_10_0.is_raise == 1 then
		arg_10_0:nodeByName("txt2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP8"))
	else
		arg_10_0:nodeByName("txt2"):setString(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP2"))
	end

	arg_10_0:nodeByName("txt3"):setString(string.format(var_0_1:translation("ACTIVITY_CHOCOLATE_SLOT_TIP3"), arg_10_0.times * arg_10_0.doublePrice))
end

return var_0_0
