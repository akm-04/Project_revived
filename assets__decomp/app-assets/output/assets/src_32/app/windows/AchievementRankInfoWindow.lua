local var_0_0 = class("AchievementRankInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.level = arg_1_2.level
	arg_1_0.rank = arg_1_2.rank
	arg_1_0.avatarID = arg_1_2.avatarID
	arg_1_0.avatarFrameID = arg_1_2.avatarFrameID
	arg_1_0.playerName = arg_1_2.playerName
	arg_1_0.regionName = arg_1_2.regionName
	arg_1_0.region = arg_1_2.region
	arg_1_0.achievementLevel = arg_1_2.achievementLevel
	arg_1_0.conquerLev = arg_1_2.conquer_lev
	arg_1_0.conquerLoopID = arg_1_2.conquer_loop_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("player_name_txt"):setString(arg_3_0.playerName)

	if arg_3_0.conquerLev and arg_3_0.conquerLev > 0 then
		xyd.setConquerLev(arg_3_0.conquerLev, arg_3_0:nodeByName("lev_txt"), arg_3_0:nodeByName("dengjiquan"), nil, nil, nil, nil, arg_3_0.conquerLoopID)
	else
		arg_3_0:nodeByName("lev_txt"):setString(arg_3_0.level)
	end

	arg_3_0:nodeByName("achievement_lev_text"):setString(var_0_1:translation("ACHIEVEMENT_LEVEL_TEXT"))
	arg_3_0:nodeByName("region_txt"):setString(arg_3_0.regionName .. "(S" .. arg_3_0.region .. ")")
	arg_3_0:nodeByName("region_text"):setString(var_0_1:translation("REGION_ARENA_TIP44"))
	arg_3_0:nodeByName("achievement_title_text"):setString(var_0_1:translation("ACHIEVEMENT_TITLE_TEXT"))
	arg_3_0:nodeByName("achievement_title_txt"):setString(xyd.tables.achievementLevel:levelName(arg_3_0.achievementLevel))
	xyd.setPlayerAvatar(arg_3_0:nodeByName("avatar"), {
		showLevel = false,
		avatar_id = arg_3_0.avatarID,
		avatar_frame_id = arg_3_0.avatarFrameID
	})
	arg_3_0:nodeByName("achievement_lev_txt"):setString(arg_3_0.achievementLevel)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
	arg_4_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

return var_0_0
