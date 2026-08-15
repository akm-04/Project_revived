local var_0_0 = class("ManageMyGuildWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.parent = arg_1_2.parent
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("quit_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("quit_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0.guild.job == 0 or arg_3_0.guild.job == 2 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					xyd.tables.translation:translation("PLAYER_INFO_QUIT_ALERT")
				}, function(arg_5_0)
					arg_3_0.guild:quitTeam(function(arg_6_0)
						if arg_6_0 == xyd.error.OK then
							xyd.WindowManager.get():closeWindow("team")
							xyd.WindowManager.get():closeWindow(arg_3_0.parent)
							xyd.WindowManager.get():closeWindow(arg_3_0)

							return true
						end
					end)
				end, nil, nil, xyd.ColorMode.YELLOW)
			elseif arg_3_0.guild.job == 1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
					xyd.tables.translation:translation("PLAYER_INFO_CANT_QUIT_ALERT")
				}, nil, nil, nil, xyd.ColorMode.YELLOW)
			end
		end
	end)
	arg_3_0:nodeByName("search_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("search_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("read_guild")
		end
	end)
end

return var_0_0
