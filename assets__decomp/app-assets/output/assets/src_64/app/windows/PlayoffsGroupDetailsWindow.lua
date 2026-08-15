local var_0_0 = class("PlayoffsGroupDetailsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.groupid = arg_1_2.groupid
	arg_1_0.group_detail = arg_1_2.group_detail
	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
	arg_3_0:registerListener()
end

function var_0_0.layout(arg_4_0)
	for iter_4_0 = 1, 4 do
		arg_4_0:nodeByName("player_" .. iter_4_0 .. "_popularity_label"):setString(var_0_1:translation("PLAYOFFS_GROUP_TEXT1"))
		arg_4_0:nodeByName("player_" .. iter_4_0 .. "_groupinfo_label"):setString(var_0_1:translation("PLAYOFFS_GROUP_TEXT2"))
	end

	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_GROUP_TEXT_" .. arg_4_0.groupid))

	for iter_4_1 = 1, 4 do
		local var_4_0 = tostring(arg_4_0.PlayoffsModel.group_info[arg_4_0.groupid][iter_4_1])

		arg_4_0:nodeByName("player_" .. iter_4_1 .. "_popularity"):setString(arg_4_0.group_detail[var_4_0].fans)
		arg_4_0:nodeByName("player_" .. iter_4_1 .. "_group_wins"):setString(string.format(var_0_1:translation("PLAYOFFS_GROUP_TEXT3"), arg_4_0.group_detail[var_4_0].win_times))
		arg_4_0:nodeByName("player_" .. iter_4_1 .. "_name"):setString("(S" .. arg_4_0.PlayoffsModel.players_info[var_4_0].region .. ")" .. arg_4_0.PlayoffsModel.players_info[var_4_0].player_name)

		local var_4_1 = {
			conquerLev = arg_4_0.PlayoffsModel.players_info[var_4_0].conquer_lev,
			lev = arg_4_0.PlayoffsModel.players_info[var_4_0].lev,
			loopID = arg_4_0.PlayoffsModel.players_info[var_4_0].conquer_loop_id
		}

		xyd.setLev(arg_4_0:nodeByName("dengjiquan_" .. iter_4_1), var_4_1)

		if arg_4_0.PlayoffsModel.playoff_info.stage >= 3 and xyd.tableHaveElement(arg_4_0.PlayoffsModel.battle_status["3"], tonumber(var_4_0)) then
			arg_4_0:nodeByName("player_" .. iter_4_1 .. "_win"):setVisible(true)
		end

		local var_4_2 = arg_4_0.PlayoffsModel.players_info[var_4_0]

		xyd.setPlayerAvatar(arg_4_0:nodeByName("player_" .. iter_4_1 .. "_icon"), {
			avatar_id = var_4_2.avatar_id,
			avatar_frame_id = var_4_2.avatar_frame_id,
			playerInfo = var_4_2
		})
	end
end

function var_0_0.registerListener(arg_5_0)
	for iter_5_0 = 1, 4 do
		arg_5_0:nodeByName("player_" .. iter_5_0 .. "_info_button"):getChildByName("text_check"):setString(var_0_1:translation("CHECK"))
		arg_5_0:nodeByName("player_" .. iter_5_0 .. "_info_button"):addTouchEventListener(function(arg_6_0, arg_6_1)
			xyd.buttonScaleAnim(arg_6_0, arg_6_1)

			if arg_6_1 == ccui.TouchEventType.ended then
				local var_6_0 = tostring(arg_5_0.PlayoffsModel.group_info[arg_5_0.groupid][iter_5_0])

				xyd.WindowManager:get():openWindow("playoffs_player_info", arg_5_0.group_detail[var_6_0].player_id)
			end
		end)
	end
end

function var_0_0.updateFans(arg_7_0)
	for iter_7_0 = 1, 4 do
		local var_7_0 = tostring(arg_7_0.PlayoffsModel.group_info[arg_7_0.groupid][iter_7_0])

		arg_7_0:nodeByName("player_" .. iter_7_0 .. "_popularity"):setString(arg_7_0.PlayoffsModel.players_info[var_7_0].fans)
	end
end

return var_0_0
