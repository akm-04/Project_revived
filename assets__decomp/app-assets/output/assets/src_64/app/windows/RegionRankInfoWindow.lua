local var_0_0 = class("RegionRankInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.level = arg_1_2.level
	arg_1_0.totalFight = arg_1_2.totalFight
	arg_1_0.winTimes = arg_1_2.winTimes
	arg_1_0.regionName = arg_1_2.regionName
	arg_1_0.point = arg_1_2.point
	arg_1_0.guildName = arg_1_2.guildName
	arg_1_0.avatarID = arg_1_2.avatarID
	arg_1_0.avatarFrameID = arg_1_2.avatarFrameID
	arg_1_0.playerName = arg_1_2.playerName
	arg_1_0.star = arg_1_2.star
	arg_1_0.region = arg_1_2.region
	arg_1_0.conquerLev = arg_1_2.conquer_lev
	arg_1_0.conquerLoopID = arg_1_2.conquer_loop_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:i18n()
	arg_2_0:layout()
end

function var_0_0.i18n(arg_3_0)
	arg_3_0:nodeByName("level_txt"):setString(var_0_1:translation("REGION_ARENA_TIP39"))
	arg_3_0:nodeByName("win_ratio_txt"):setString(var_0_1:translation("REGION_ARENA_TIP40"))
	arg_3_0:nodeByName("win_times_txt"):setString(var_0_1:translation("REGION_ARENA_TIP41"))
	arg_3_0:nodeByName("point_txt"):setString(var_0_1:translation("REGION_ARENA_TIP42"))
	arg_3_0:nodeByName("guild_name_txt"):setString(var_0_1:translation("REGION_ARENA_TIP43"))
	arg_3_0:nodeByName("server_name_txt"):setString(var_0_1:translation("REGION_ARENA_TIP44"))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("name"):setString(arg_4_0.playerName)

	if arg_4_0.conquerLev and arg_4_0.conquerLev > 0 then
		local var_4_0 = {
			x = 0,
			y = 0
		}

		xyd.setConquerLev(arg_4_0.conquerLev, arg_4_0:nodeByName("lev"), arg_4_0:nodeByName("dengjiquan"), var_4_0, true, nil, nil, arg_4_0.conquerLoopID)
	else
		arg_4_0:nodeByName("lev"):setString(arg_4_0.level)
	end

	arg_4_0:nodeByName("win_times"):setString(arg_4_0.winTimes)
	arg_4_0:nodeByName("server_name"):setString(arg_4_0.regionName .. "(S" .. arg_4_0.region .. ")")
	arg_4_0:nodeByName("point"):setString(arg_4_0.point)
	arg_4_0:nodeByName("guild_name"):setString(arg_4_0.guildName)

	if arg_4_0.totalFight > 0 then
		arg_4_0:nodeByName("win_ratio"):setString(tostring(math.floor(arg_4_0.winTimes / arg_4_0.totalFight * 100)) .. "%")
	else
		arg_4_0:nodeByName("win_ratio"):setString("N/A")
	end

	local var_4_1 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_4_0.star)

	if var_4_1 == xyd.tables.regionArenaLevel.level[#xyd.tables.regionArenaLevel.level] then
		arg_4_0:nodeByName("level"):setString(var_0_1:translation("REGION_ARENA_RULE6"))
	else
		arg_4_0:nodeByName("level"):setString("Lv." .. var_4_1)
	end

	xyd.setPlayerAvatar(arg_4_0:nodeByName("avatar"), {
		showLevel = false,
		avatar_id = arg_4_0.avatarID,
		avatar_frame_id = arg_4_0.avatarFrameID
	})
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayer()
end

return var_0_0
