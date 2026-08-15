local var_0_0 = class("ArenaRefreshWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.arena_ = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("refresh"):setString(xyd.tables.translation:translation("REFRESH"))
	arg_4_0:nodeByName("keeprefresh"):setString(xyd.tables.translation:translation("KEEP_BUFF_REFRESH"))
	arg_4_0:nodeByName("cost"):setString(xyd.tables.misc.arenaRefreshCrystal)
	arg_4_0:nodeByName("sure"):setString(xyd.tables.translation:translation("SURE_REFRESH"))
	arg_4_0:nodeByName("willdispare"):setString(xyd.tables.translation:translation("REFRESH_LOSE_BUFF"))
end

function var_0_0.soundButtonClick(arg_5_0, arg_5_1, arg_5_2)
	var_0_0.super.soundButtonClick(arg_5_0, arg_5_1, arg_5_2)

	if arg_5_2 == ccui.TouchEventType.ended then
		local var_5_0 = arg_5_1:getName()

		if var_5_0 == "refresh_button" then
			local var_5_1 = arg_5_0.arena_.playerRefreshTime_ + xyd.tables.misc.arenaRefreshDuration - xyd.ServerTime.get():getServerTime()

			if var_5_1 > 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(xyd.tables.translation:translation("NEXT_REFRESH_TIME"), var_5_1), function(arg_6_0)
					return
				end, nil, nil, arg_5_0.colorMode)
			else
				arg_5_0.arena_:refreshArenaPlayerList(function(arg_7_0)
					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():getWindow("arena"):switchShowListTo(xyd.ArenaType.PLAYER, true)
						xyd.WindowManager.get():closeWindow("arena_refresh")
					end
				end, false)
			end
		elseif var_5_0 == "keep_refresh_button" then
			if arg_5_0.player_.crystal < xyd.tables.misc.arenaRefreshCrystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("LACK_OF_CRYSTAL"), function(arg_8_0)
					return
				end, nil, nil, arg_5_0.colorMode)
			else
				arg_5_0.arena_:refreshArenaPlayerList(function(arg_9_0)
					if arg_9_0 == xyd.error.OK then
						xyd.WindowManager.get():getWindow("arena"):layoutPlayerRelate()
						xyd.WindowManager.get():getWindow("arena"):switchShowListTo(xyd.ArenaType.PLAYER, true)
						xyd.WindowManager.get():closeWindow("arena_refresh")
					end
				end, true)
			end
		end
	end
end

return var_0_0
