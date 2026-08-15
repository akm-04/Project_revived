local var_0_0 = class("AllNightDarkGachaAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.callback = arg_1_2.callback
	arg_1_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(var_0_1:translation("TIP"))
	arg_3_0:nodeByName("txt_tip"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT8"))
	arg_3_0:nodeByName("txt_one"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT9"))
	arg_3_0:nodeByName("txt_ten"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT10"))

	local var_3_0 = var_0_2:getValue("activity_polar_night_gacha_cost")

	arg_3_0:nodeByName("txt_num_one"):setString(var_3_0)
	arg_3_0:nodeByName("txt_num_ten"):setString(var_3_0 * 10)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_one"), nil, function(arg_4_0)
		if arg_3_0.selfPlayer.crystal >= var_3_0 then
			arg_3_0.allNight:darkGachaBuy({
				times = 1
			}, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_3_0.selfPlayer:handleRewards(arg_5_1.awards)

					if arg_3_0.callback then
						arg_3_0.callback()
					end

					arg_3_0:close()
				end
			end)
		else
			local var_4_0 = var_0_1:translation("ZUANSHI_ABSENCE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_0, function()
				arg_3_0:close()
				xyd.WindowManager.get():closeWindow("all_night_dark_gacha")
				xyd.WindowManager.get():openWindow("vip_recharge")
			end)
		end
	end)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_ten"), nil, function(arg_7_0)
		if arg_3_0.selfPlayer.crystal >= var_3_0 * 10 then
			arg_3_0.allNight:darkGachaBuy({
				times = 10
			}, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_3_0.selfPlayer:handleRewards(arg_8_1.awards)

					if arg_3_0.callback then
						arg_3_0.callback()
					end

					arg_3_0:close()
				end
			end)
		else
			local var_7_0 = var_0_1:translation("ZUANSHI_ABSENCE")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
				arg_3_0:close()
				xyd.WindowManager.get():closeWindow("all_night_dark_gacha")
				xyd.WindowManager.get():openWindow("vip_recharge")
			end)
		end
	end)
end

function var_0_0.didOpen(arg_10_0)
	arg_10_0:addBlockLayer()
end

return var_0_0
