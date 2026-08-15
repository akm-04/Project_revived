local var_0_0 = class("TeamDrinkOthersWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.misc.drinkInvite1

	if arg_3_0.guild.drink_status == 1 or arg_3_0.guild.drink_status == 3 then
		arg_3_0:nodeByName("tili_mum_1"):setString("0")
	else
		arg_3_0:nodeByName("tili_mum_1"):setString(var_3_0)
	end

	arg_3_0:nodeByName("cost_num_1"):setString(xyd.tables.misc.drinkCost1)
	arg_3_0:nodeByName("title_words"):setString(var_0_2:translation("TEAM_DRINK_OTHERS_TITLE"))

	for iter_3_0 = 1, 2 do
		arg_3_0:nodeByName("cost_words_" .. iter_3_0):setString(var_0_2:translation("DRINK_MONEY_COST"))
		arg_3_0:nodeByName("tili_words_" .. iter_3_0):setString(var_0_2:translation("WILL_GET") .. var_0_2:translation("COLON"))
	end

	arg_3_0:nodeByName("drinks_icon"):setTouchEnabled(true)
	arg_3_0:nodeByName("drinks_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "ended" then
			xyd.playButtonSound()
			arg_3_0:nodeByName("drinks_icon"):setScale(1)

			local var_4_0 = var_0_2:translation("DRINK_COCKTAIL")
			local var_4_1 = var_0_2:translation("COIN")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("TEAM_DRINK_BUY_ALERT"), xyd.tables.misc.drinkBuyNum1, var_4_0, xyd.tables.misc.drinkCost1, var_4_1), function()
				if arg_3_0.player.mana < xyd.tables.misc.drinkCost1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("JINBI_ABSENCE"), function()
						local var_6_0 = xyd.FunctionID.ID_GOLD_HAND

						if arg_3_0.player:isFuncOpen(var_6_0) == true then
							xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
						else
							local var_6_1 = xyd.tables.functionOpen:level(var_6_0)
							local var_6_2 = string.format(stringLocalizer:translation("FUNCTION_OPEN_TIP_LEVEL"), var_6_1)

							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_6_2
							})
						end
					end, nil, nil, arg_3_0.colorMode)
				else
					local var_5_0 = {
						type = 2
					}
					local var_5_1 = "" .. string.format(var_0_2:translation("TEAM_DRINK_BUY_IS_OK"), var_4_0)
					local var_5_2 = arg_3_0.guild.drink_status

					if arg_3_0.guild.normal_have_drink == 0 then
						arg_3_0.guild:buyDrink(var_5_0, function(arg_7_0, arg_7_1)
							local var_7_0 = arg_7_1.energy_award

							if var_5_2 == 0 or var_5_2 == 2 then
								arg_3_0:nodeByName("tili_mum_1"):setString("0")

								var_5_1 = var_5_1 .. string.format(var_0_2:translation("TEAM_DRINK_GET_ENERGY"), var_7_0)
							end

							var_5_1 = var_5_1 .. var_0_2:translation("TEAM_DRINK_IS_FIRST")

							if arg_7_0 == xyd.error.OK then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.DRINK_NOTIF
								})
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_1, function()
									arg_3_0.guild:loadDrinkInfo(function(arg_9_0, arg_9_1)
										if arg_9_0 == xyd.error.OK then
											xyd.WindowManager.get():openWindow("drink_self")
											xyd.WindowManager.get():closeWindow(arg_3_0)
										end
									end)
								end, nil, nil, arg_3_0.colorMode)

								return true
							end
						end)
					else
						arg_3_0.guild:buyDrink(var_5_0, function(arg_10_0, arg_10_1)
							local var_10_0 = arg_10_1.energy_award

							if var_5_2 == 0 or var_5_2 == 2 then
								arg_3_0:nodeByName("tili_mum_1"):setString("0")

								var_5_1 = var_5_1 .. string.format(var_0_2:translation("TEAM_DRINK_GET_ENERGY"), var_10_0)
							end

							if arg_10_0 == xyd.error.OK then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.DRINK_NOTIF
								})
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_5_1, nil, nil, nil, arg_3_0.colorMode)

								return true
							end
						end)
					end
				end
			end, nil, 0, arg_3_0.colorMode)

			return true
		elseif arg_4_0.name == "began" then
			arg_3_0:nodeByName("drinks_icon"):setScale(0.9)

			return true
		end
	end)

	local var_3_1 = xyd.tables.misc.drinkInvite2

	if arg_3_0.guild.drink_status == 2 or arg_3_0.guild.drink_status == 3 then
		arg_3_0:nodeByName("tili_mum_2"):setString("0")
	else
		arg_3_0:nodeByName("tili_mum_2"):setString(var_3_1)
	end

	arg_3_0:nodeByName("cost_num_2"):setString(xyd.tables.misc.drinkCost2)
	arg_3_0:nodeByName("red_icon"):setTouchEnabled(true)
	arg_3_0:nodeByName("red_icon"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "ended" then
			xyd.playButtonSound()
			arg_3_0:nodeByName("red_icon"):setScale(1)

			local var_11_0 = var_0_2:translation("DRINK_WINE")
			local var_11_1 = var_0_2:translation("CRYSTAL")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("TEAM_DRINK_BUY_ALERT"), xyd.tables.misc.drinkBuyNum2, var_11_0, xyd.tables.misc.drinkCost2, var_11_1), function()
				if arg_3_0.player.crystal < xyd.tables.misc.drinkCost2 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
						xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
					end, nil, nil, arg_3_0.colorMode)
				else
					local var_12_0 = {
						type = 3
					}
					local var_12_1 = "" .. string.format(var_0_2:translation("TEAM_DRINK_BUY_IS_OK"), var_11_0)
					local var_12_2 = arg_3_0.guild.drink_status

					if arg_3_0.guild.special_have_drink == 0 then
						arg_3_0.guild:buyDrink(var_12_0, function(arg_14_0, arg_14_1)
							local var_14_0 = arg_14_1.energy_award

							if var_12_2 == 0 or var_12_2 == 1 then
								arg_3_0:nodeByName("tili_mum_2"):setString("0")

								var_12_1 = var_12_1 .. string.format(var_0_2:translation("TEAM_DRINK_GET_ENERGY"), var_14_0)
							end

							var_12_1 = var_12_1 .. var_0_2:translation("TEAM_DRINK_IS_FIRST")

							if arg_14_0 == xyd.error.OK then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.DRINK_NOTIF
								})
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_1, function()
									arg_3_0.guild:loadDrinkInfo(function(arg_16_0, arg_16_1)
										if arg_16_0 == xyd.error.OK then
											xyd.WindowManager.get():openWindow("drink_self")
											xyd.WindowManager.get():closeWindow(arg_3_0)
										end
									end)
								end, nil, nil, arg_3_0.colorMode)

								return true
							end
						end)
					else
						arg_3_0.guild:buyDrink(var_12_0, function(arg_17_0, arg_17_1)
							local var_17_0 = arg_17_1.energy_award

							if var_12_2 == 0 or var_12_2 == 1 then
								arg_3_0:nodeByName("tili_mum_2"):setString("0")

								var_12_1 = var_12_1 .. string.format(var_0_2:translation("TEAM_DRINK_GET_ENERGY"), var_17_0)
							end

							if arg_17_0 == xyd.error.OK then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.DRINK_NOTIF
								})
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_12_1, nil, nil, nil, arg_3_0.colorMode)

								return true
							end
						end)
					end
				end
			end, nil, 0, arg_3_0.colorMode)
		elseif arg_11_0.name == "began" then
			arg_3_0:nodeByName("red_icon"):setScale(0.9)
		end

		return true
	end)
end

function var_0_0.didOpen(arg_18_0, arg_18_1)
	arg_18_0:addBlockLayer()
	var_0_0.super:didOpen(arg_18_1)
	arg_18_0:nodeByName("close_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			local var_19_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_19_0, false)
			xyd.WindowManager.get():closeWindow(arg_18_0)
		end
	end)
end

return var_0_0
