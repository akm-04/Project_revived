local var_0_0 = class("SnowGachaBuyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.snowGachaBuy

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.snowModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("tip1"):setString(var_0_1:translation("SNOW_GACHA_BUY_TIP1"))
	arg_2_0:nodeByName("tip2"):setString(var_0_1:translation("SNOW_GACHA_BUY_TIP2"))
	arg_2_0:nodeByName("tip3"):setString(string.format(var_0_1:translation("SNOW_GACHA_BUY_TIP3"), var_0_2:coin(2)))
	arg_2_0:nodeByName("tip4"):setString(var_0_1:translation("SNOW_GACHA_BUY_TIP4"))

	for iter_2_0 = 1, 2 do
		arg_2_0:nodeByName("buy_btn" .. iter_2_0):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_3_0 = var_0_2:cost(iter_2_0)
				local var_3_1 = var_0_2:coin(iter_2_0)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("SNOW_GACHA_BUY_CONFIRM_TIP"), var_3_0, var_3_1), function()
					if arg_2_0.player.crystal < var_3_0 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
						end, nil, nil, arg_2_0.colorMode)
					else
						arg_2_0:buy(iter_2_0)
					end
				end, nil, 0, arg_2_0.colorMode)
			end
		end)
	end
end

function var_0_0.buy(arg_6_0, arg_6_1)
	arg_6_0.snowModel:gachaBuy(arg_6_1, function(arg_7_0)
		arg_6_0.snowModel:updateBaseInfo(arg_7_0.base_info)

		local var_7_0 = xyd.WindowManager.get():getWindow("snow_gacha", {})

		if var_7_0 then
			var_7_0:update()
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("BUY_SUCCESS")
		})
	end)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
