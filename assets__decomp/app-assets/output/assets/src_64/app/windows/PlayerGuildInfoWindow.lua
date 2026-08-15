local var_0_0 = class("PlayerGuildInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.level = arg_1_2.level
	arg_1_0.guildID = arg_1_2.guildID
	arg_1_0.guildName = arg_1_2.guildName
	arg_1_0.avatarID = arg_1_2.avatarID
	arg_1_0.avatarFrameID = arg_1_2.avatarFrameID
	arg_1_0.playerName = arg_1_2.playerName
	arg_1_0.conquerLev = arg_1_2.conquer_lev
	arg_1_0.conquerLoopID = arg_1_2.conquer_loop_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("guild_name_txt"):setString(var_0_1:translation("REGION_ARENA_TIP43"))
	arg_3_0:nodeByName("name"):setString(arg_3_0.playerName)

	if arg_3_0.conquerLev and arg_3_0.conquerLev > 0 then
		local var_3_0 = {
			x = 10,
			y = 0
		}

		xyd.setConquerLev(arg_3_0.conquerLev, arg_3_0:nodeByName("lev"), arg_3_0:nodeByName("dengjiquan"), var_3_0, true, nil, nil, arg_3_0.conquerLoopID)
	else
		arg_3_0:nodeByName("lev"):setString(arg_3_0.level)
	end

	if arg_3_0.guildID and arg_3_0.guildID ~= 0 then
		arg_3_0:nodeByName("guild_name"):setString(arg_3_0.guildName)
	else
		arg_3_0:nodeByName("guild_name"):setString(var_0_1:translation("GUILD_CHAT_ALERT"))
	end

	arg_3_0:nodeByName("guild_name"):setPositionX(arg_3_0:nodeByName("guild_name"):getPositionX())
	xyd.setPlayerAvatar(arg_3_0:nodeByName("avatar"), {
		showLevel = false,
		avatar_id = arg_3_0.avatarID,
		avatar_frame_id = arg_3_0.avatarFrameID
	})
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

return var_0_0
