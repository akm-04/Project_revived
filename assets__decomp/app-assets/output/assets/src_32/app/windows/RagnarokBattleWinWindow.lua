local var_0_0 = class("RagnarokBattleWinWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout(arg_2_1)
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.layout(arg_4_0, arg_4_1)
	arg_4_0:nodeByName("txt_ok"):setString(var_0_2:translation("SURE"))
	arg_4_0:nodeByName("txt_damage"):setString(var_0_2:translation("RAGNAROK_BOSS_23"))
	arg_4_0:nodeByName("txt_time"):setString(var_0_2:translation("RAGNAROK_BOSS_24"))
	arg_4_0:nodeByName("txt_dead"):setString(var_0_2:translation("RAGNAROK_BOSS_25"))
	arg_4_0:nodeByName("txt_all"):setString(var_0_2:translation("RAGNAROK_BOSS_28"))
	arg_4_0:nodeByName("txt_reward"):setString(var_0_2:translation("RAGNAROK_BOSS_29"))

	local var_4_0 = var_0_2:translation("RAGNAROK_BOSS_1")
	local var_4_1 = string.format(var_0_2:translation("RAGNAROK_BOSS_22"), var_4_0)

	arg_4_0:nodeByName("txt_title"):setString(var_4_1)
	arg_4_0:nodeByName("score_damage"):setString(arg_4_1.damage_score)
	arg_4_0:nodeByName("score_time"):setString(arg_4_1.time_score)
	arg_4_0:nodeByName("score_dead"):setString(arg_4_1.alive_score)
	arg_4_0:nodeByName("score_all"):setString(arg_4_1.total_score)

	if arg_4_1.carry_score then
		arg_4_0:nodeByName("txt_carry"):setString(var_0_2:translation("RAGNAROK_BOSS_26"))
		arg_4_0:nodeByName("score_carry"):setString(arg_4_1.carry_score)
	elseif arg_4_1.team_score then
		arg_4_0:nodeByName("txt_carry"):setString(var_0_2:translation("RAGNAROK_BOSS_27"))
		arg_4_0:nodeByName("score_carry"):setString(arg_4_1.team_score)
	else
		arg_4_0:nodeByName("score_carry"):setVisible(false)
		arg_4_0:nodeByName("txt_carry"):setVisible(false)
	end

	if arg_4_1.awards and next(arg_4_1.awards) then
		xyd.setItemAndAddTips(arg_4_0:nodeByName("reward"), arg_4_1.awards[1].table_id, arg_4_1.awards[1].item_num)
	end

	arg_4_0:nodeByName("txt_title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_0_1.new({
		size = 402
	}):addTo(arg_4_0:nodeByName("pos_line"))
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_ok"), nil, function()
		arg_4_0:close()
		xyd.WindowManager.get():closeWindow("ragnarok_battle")
	end)
end

return var_0_0
