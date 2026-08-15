local var_0_0 = class("PlayoffsVSReadyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.A_player_info = arg_1_2.A_player_info
	arg_1_0.B_player_info = arg_1_2.B_player_info
	arg_1_0.A_player_id = arg_1_2.A_player_id
	arg_1_0.B_player_id = arg_1_2.B_player_id
	arg_1_0.room_key = arg_1_2.room_key
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("id_1"):setString(arg_4_0.A_player_id)
	arg_4_0:nodeByName("id_2"):setString(arg_4_0.B_player_id)
	arg_4_0:nodeByName("guild_1"):setString(arg_4_0.A_player_info.guild_name)
	arg_4_0:nodeByName("guild_2"):setString(arg_4_0.B_player_info.guild_name)
	arg_4_0:nodeByName("server_1"):setString(arg_4_0.A_player_info.region)
	arg_4_0:nodeByName("server_2"):setString(arg_4_0.B_player_info.region)

	for iter_4_0 = 1, 2 do
		arg_4_0:nodeByName("guild_" .. iter_4_0 .. "_label"):setString(var_0_1:translation("PLAYOFFS_PLAYER_INFO_TEXT1"))
		arg_4_0:nodeByName("server_" .. iter_4_0 .. "_label"):setString(var_0_1:translation("REGION_ARENA_TIP10"))
	end

	arg_4_0:nodeByName("lv_1"):setString(arg_4_0.A_player_info.lev)
	arg_4_0:nodeByName("lv_2"):setString(arg_4_0.B_player_info.lev)
	arg_4_0:nodeByName("name_1"):setString(arg_4_0.A_player_info.player_name)
	arg_4_0:nodeByName("name_2"):setString(arg_4_0.B_player_info.player_name)
	xyd.setPlayerAvatar(arg_4_0:nodeByName("icon_1"), {
		avatar_id = arg_4_0.A_player_info.avatar_id,
		avatar_frame_id = arg_4_0.A_player_info.avatar_frame_id
	})
	xyd.setPlayerAvatar(arg_4_0:nodeByName("icon_2"), {
		avatar_id = arg_4_0.B_player_info.avatar_id,
		avatar_frame_id = arg_4_0.B_player_info.avatar_frame_id
	})
	arg_4_0:nodeByName("text_ready"):setString(var_0_1:translation("PARADISE_TEXT_1"))
	arg_4_0:nodeByName("ready_button"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = {
				room_key = arg_4_0.room_key
			}

			xyd.Backend.get():request(xyd.mid.PLAYOFFS_READY, var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0:nodeByName("ready_button"):setVisible(false)
				end
			end)
		end
	end)
end

function var_0_0.updateReadyFlag(arg_7_0, arg_7_1)
	if arg_7_1.A_prepared == 1 then
		arg_7_0:nodeByName("ready_1"):setVisible(true)
	end

	if arg_7_1.B_prepared == 1 then
		arg_7_0:nodeByName("ready_2"):setVisible(true)
	end
end

return var_0_0
