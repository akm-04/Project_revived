local var_0_0 = class("IllusionBattleResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rank = arg_1_2.rank
	arg_1_0.damage = math.floor(arg_1_2.damage or 0)
	arg_1_0.damageHighest = math.floor(arg_1_2.damageHighest or 0)
	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
	arg_1_0.petA = arg_1_2.petA
	arg_1_0.pre_name = arg_1_2.pre_name
	arg_1_0.pre_avatar = arg_1_2.pre_avatar
	arg_1_0.pre_avatar_frame = arg_1_2.pre_avatar_frame
	arg_1_0.pre_lev = arg_1_2.pre_lev
	arg_1_0.pre_damage = math.floor(arg_1_2.pre_damage or 0)
	arg_1_0.pre_rank = arg_1_2.pre_rank
	arg_1_0.conquer_lev = arg_1_2.conquer_lev
	arg_1_0.conquer_loop_id = arg_1_2.conquer_loop_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_continue"), nil, function()
		local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_4_0, false)
		arg_3_0:dispatchEvent({
			name = xyd.event.BATTLE_END_BACK_TO_MAIN
		})
	end)
	arg_3_0:nodeByName("rank_txt"):setString(var_0_2:translation("RANKING") .. var_0_2:translation("COLON"))
	arg_3_0:setRank(arg_3_0.rank, arg_3_0:nodeByName("rank_container"))
	arg_3_0:nodeByName("damage_txt"):setString(var_0_2:translation("PARADISE_THIS_DAMAGE"))
	arg_3_0:nodeByName("damage_num"):setString(arg_3_0.damage)
	arg_3_0:nodeByName("damage_highest_txt"):setString(var_0_2:translation("PARADISE_HISTORY_HIGHEST_DAMAGE"))
	arg_3_0:nodeByName("damage_highest_num"):setString(arg_3_0.damageHighest)
	arg_3_0:nodeByName("more_award_txt"):setString(var_0_2:translation("WORLD_BOSS_NEED_TO_OVER") .. var_0_2:translation("COLON"))
	arg_3_0:nodeByName("battle_result_txt"):setString(var_0_2:translation("FIGHT_OVER"))

	if arg_3_0.pre_rank == nil then
		arg_3_0:nodeByName("bottom_container"):setVisible(false)
	else
		arg_3_0:nodeByName("player_rank_txt"):setString(var_0_2:translation("HIS_RANK") .. var_0_2:translation("COLON"))
		arg_3_0:setRank(arg_3_0.pre_rank, arg_3_0:nodeByName("player_rank_container"))
		arg_3_0:nodeByName("player_damage_highest_txt"):setString(var_0_2:translation("PARADISE_HISTORY_HIGHEST_DAMAGE"))
		arg_3_0:nodeByName("player_damage_highest_num"):setString(arg_3_0.pre_damage)

		if arg_3_0.conquer_lev and arg_3_0.conquer_lev > 0 then
			xyd.setConquerLev(arg_3_0.conquer_lev, arg_3_0:nodeByName("lev"), arg_3_0:nodeByName("lev_icon"), nil, false, 0.85, nil, arg_3_0.conquer_loop_id)
		else
			arg_3_0:nodeByName("lev"):setString(arg_3_0.pre_lev)
		end

		arg_3_0:nodeByName("name_txt"):setString(arg_3_0.pre_name)
		xyd.setPlayerAvatar(arg_3_0:nodeByName("avatar_container"), {
			showLevel = false,
			avatar_id = arg_3_0.pre_avatar,
			avatar_frame_id = arg_3_0.pre_avatar_frame
		})
	end

	xyd.nodeEventSample(arg_3_0:nodeByName("data_btn"), nil, function()
		xyd.playButtonSound()
		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
			herosA = arg_3_0.fighterA,
			herosB = arg_3_0.fighterB,
			petA = arg_3_0.petA
		})
	end)
	arg_3_0:nodeByName("data_txt"):setString(var_0_2:translation("ILLUSION_DATA_TXT"))
end

function var_0_0.setRank(arg_6_0, arg_6_1, arg_6_2)
	arg_6_2:removeAllChildren()

	local var_6_0 = xyd.colorNumLabel(arg_6_1, "yellow1")

	var_6_0:setAnchorPoint(0, 0)
	var_6_0:addTo(arg_6_2)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
