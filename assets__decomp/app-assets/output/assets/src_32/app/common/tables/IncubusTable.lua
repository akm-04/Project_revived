local var_0_0 = class("IncubusTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_list_ = {}
	arg_1_0.time_ = {}
	arg_1_0.countdown_ = {}
	arg_1_0.open_lv_ = {}
	arg_1_0.hero_ = {}
	arg_1_0.partner_ = {}
	arg_1_0.guard_ = {}
	arg_1_0.enemy_ = {}
	arg_1_0.debuff_ = {}
	arg_1_0.debuff2_ = {}
	arg_1_0.defeat_cost_ = {}
	arg_1_0.ban_list_ = {}
	arg_1_0.monster_show_ = {}
	arg_1_0.award_show_ = {}
	arg_1_0.dropbox_ = {}
	arg_1_0.hero_name_ = {}
	arg_1_0.add_hp_limit_ = {}
	arg_1_0.begin_txt_ = {}
	arg_1_0.win_txt_ = {}
	arg_1_0.lose_txt_ = {}
	arg_1_0.rewardBuffs_ = {}
	arg_1_0.punishBuffs_ = {}
	arg_1_0.img_ = {}
	arg_1_0.position_ = {}
	arg_1_0.dialogName_ = {}
	arg_1_0.node_ = {}
	arg_1_0.cure_ = {}
	arg_1_0.missionNum_ = {}
	arg_1_0.begin_name_ = {}
	arg_1_0.begin_img_ = {}
	arg_1_0.begin_position_ = {}
	arg_1_0.win_name_ = {}
	arg_1_0.win_img_ = {}
	arg_1_0.win_position_ = {}
	arg_1_0.lose_name_ = {}
	arg_1_0.lose_img_ = {}
	arg_1_0.lose_position_ = {}
	arg_1_0.warn_txt_ = {}
	arg_1_0.warn_name_ = {}
	arg_1_0.warn_img_ = {}
	arg_1_0.warn_position_ = {}

	import("app.common.tables.TableParser").parse("incubus.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.id_list_, var_2_0)

		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.countdown_[var_2_0] = arg_2_0.countdown
		arg_1_0.open_lv_[var_2_0] = tonumber(arg_2_0.open_lv)
		arg_1_0.partner_[var_2_0] = tonumber(arg_2_0.incubus_partner)
		arg_1_0.hero_[var_2_0] = tonumber(arg_2_0.incubus_partner2)
		arg_1_0.guard_[var_2_0] = {}
		arg_1_0.guard_[var_2_0][1] = tonumber(arg_2_0.incubus_guard1)
		arg_1_0.guard_[var_2_0][2] = tonumber(arg_2_0.incubus_guard2)
		arg_1_0.enemy_[var_2_0] = tonumber(arg_2_0.incubus_enemy)
		arg_1_0.debuff_[var_2_0] = tonumber(arg_2_0.debuff)
		arg_1_0.debuff2_[var_2_0] = tonumber(arg_2_0.debuff2)
		arg_1_0.defeat_cost_[var_2_0] = tonumber(arg_2_0.defeat_cost)
		arg_1_0.ban_list_[var_2_0] = xyd.splitToNumber(arg_2_0.ban_hero_id, "|")
		arg_1_0.monster_show_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_show, "|")
		arg_1_0.award_show_[var_2_0] = xyd.splitToNumber(arg_2_0.award_show, "|")
		arg_1_0.dropbox_[var_2_0] = xyd.splitToNumber(arg_2_0.incubus_dropbox, "|")
		arg_1_0.hero_name_[var_2_0] = arg_2_0.hero_name
		arg_1_0.add_hp_limit_[var_2_0] = arg_2_0.add_hp_limit
		arg_1_0.begin_txt_[var_2_0] = xyd.split(arg_2_0.dialogue_begin, "|")
		arg_1_0.win_txt_[var_2_0] = xyd.split(arg_2_0.dialogue_win, "|")
		arg_1_0.lose_txt_[var_2_0] = xyd.split(arg_2_0.dialogue_lose, "|")
		arg_1_0.rewardBuffs_[var_2_0] = xyd.splitToNumber(arg_2_0.buff_id, "|")
		arg_1_0.punishBuffs_[var_2_0] = xyd.splitToNumber(arg_2_0.debuff_id, "|")
		arg_1_0.img_[var_2_0] = xyd.split(arg_2_0.img, "|")
		arg_1_0.position_[var_2_0] = xyd.splitToNumber(arg_2_0.position, "|")
		arg_1_0.dialogName_[var_2_0] = xyd.split(arg_2_0.dialougue_hero_name, "|")
		arg_1_0.node_[var_2_0] = xyd.splitToNumber(arg_2_0.node, "|")
		arg_1_0.cure_[var_2_0] = xyd.splitToNumber(arg_2_0.cure, "|")
		arg_1_0.missionNum_[var_2_0] = xyd.splitToNumber(arg_2_0.mission_num, "|")
	end)

	local var_1_0 = {}

	for iter_1_0 = #arg_1_0.id_list_, 1, -1 do
		table.insert(var_1_0, arg_1_0.id_list_[iter_1_0])
	end

	arg_1_0.id_list_ = var_1_0

	import("app.common.tables.TableParser").parse("bloodline_incubus.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)

		arg_1_0.time_[var_3_0] = tonumber(arg_3_0.time)
		arg_1_0.countdown_[var_3_0] = arg_3_0.countdown
		arg_1_0.partner_[var_3_0] = tonumber(arg_3_0.incubus_partner)
		arg_1_0.hero_[var_3_0] = tonumber(arg_3_0.incubus_partner2)
		arg_1_0.guard_[var_3_0] = {}
		arg_1_0.guard_[var_3_0][1] = tonumber(arg_3_0.incubus_guard1)
		arg_1_0.guard_[var_3_0][2] = tonumber(arg_3_0.incubus_guard2)
		arg_1_0.enemy_[var_3_0] = tonumber(arg_3_0.incubus_enemy)
		arg_1_0.node_[var_3_0] = xyd.splitToNumber(arg_3_0.node, "|")
		arg_1_0.cure_[var_3_0] = xyd.splitToNumber(arg_3_0.cure, "|")
		arg_1_0.debuff_[var_3_0] = tonumber(arg_3_0.debuff)
		arg_1_0.debuff2_[var_3_0] = tonumber(arg_3_0.debuff2)
		arg_1_0.ban_list_[var_3_0] = xyd.splitToNumber(arg_3_0.ban_hero_id, "|")
		arg_1_0.add_hp_limit_[var_3_0] = arg_3_0.add_hp_limit
		arg_1_0.begin_txt_[var_3_0] = xyd.split(arg_3_0.dialogue_begin, "|")
		arg_1_0.begin_name_[var_3_0] = xyd.split(arg_3_0.dialogue_begin_name, "|")
		arg_1_0.begin_img_[var_3_0] = xyd.split(arg_3_0.dialogue_begin_img, "|")
		arg_1_0.begin_position_[var_3_0] = xyd.splitToNumber(arg_3_0.begin_position, "|")
		arg_1_0.win_txt_[var_3_0] = xyd.split(arg_3_0.dialogue_win, "|")
		arg_1_0.win_name_[var_3_0] = xyd.split(arg_3_0.dialogue_win_name, "|")
		arg_1_0.win_img_[var_3_0] = xyd.split(arg_3_0.dialogue_win_img, "|")
		arg_1_0.win_position_[var_3_0] = xyd.splitToNumber(arg_3_0.win_position, "|")
		arg_1_0.lose_txt_[var_3_0] = xyd.split(arg_3_0.dialogue_lose, "|")
		arg_1_0.lose_name_[var_3_0] = xyd.split(arg_3_0.dialogue_losename, "|")
		arg_1_0.lose_img_[var_3_0] = xyd.split(arg_3_0.lose_img, "|")
		arg_1_0.lose_position_[var_3_0] = xyd.splitToNumber(arg_3_0.lose_position, "|")
		arg_1_0.warn_txt_[var_3_0] = xyd.split(arg_3_0.health_warning, "|")
		arg_1_0.warn_name_[var_3_0] = xyd.split(arg_3_0.dialogue_warning_name, "|")
		arg_1_0.warn_img_[var_3_0] = xyd.split(arg_3_0.health_warning_img, "|")
		arg_1_0.warn_position_[var_3_0] = xyd.splitToNumber(arg_3_0.health_warning_position, "|")
	end)
end

function var_0_0.id_list(arg_4_0)
	return arg_4_0.id_list_
end

function var_0_0.time(arg_5_0, arg_5_1)
	return arg_5_0.time_[arg_5_1] or 0
end

function var_0_0.countdown(arg_6_0, arg_6_1)
	return arg_6_0.countdown_[arg_6_1] or 0
end

function var_0_0.openLev(arg_7_0, arg_7_1)
	return arg_7_0.open_lv_[arg_7_1] or 0
end

function var_0_0.hero(arg_8_0, arg_8_1)
	return arg_8_0.hero_[arg_8_1] or 0
end

function var_0_0.partner(arg_9_0, arg_9_1)
	return arg_9_0.partner_[arg_9_1] or 0
end

function var_0_0.guard(arg_10_0, arg_10_1)
	return arg_10_0.guard_[arg_10_1] or {}
end

function var_0_0.enemy(arg_11_0, arg_11_1)
	return arg_11_0.enemy_[arg_11_1] or 0
end

function var_0_0.debuff(arg_12_0, arg_12_1)
	return arg_12_0.debuff_[arg_12_1] or 0
end

function var_0_0.debuff2(arg_13_0, arg_13_1)
	return arg_13_0.debuff2_[arg_13_1] or 0
end

function var_0_0.defeatCost(arg_14_0, arg_14_1)
	return arg_14_0.defeat_cost_[arg_14_1] or 0
end

function var_0_0.banList(arg_15_0, arg_15_1)
	return arg_15_0.ban_list_[arg_15_1] or {}
end

function var_0_0.monsterShow(arg_16_0, arg_16_1)
	return arg_16_0.monster_show_[arg_16_1] or {}
end

function var_0_0.awardShow(arg_17_0, arg_17_1)
	return arg_17_0.award_show_[arg_17_1] or {}
end

function var_0_0.dropbox(arg_18_0, arg_18_1)
	return arg_18_0.dropbox_[arg_18_1] or {}
end

function var_0_0.name(arg_19_0, arg_19_1)
	return arg_19_0.hero_name_[arg_19_1] or ""
end

function var_0_0.addHpLimit(arg_20_0, arg_20_1)
	return arg_20_0.add_hp_limit_[arg_20_1] or 0
end

function var_0_0.begin(arg_21_0, arg_21_1)
	return arg_21_0.begin_txt_[arg_21_1] or {}
end

function var_0_0.beginName(arg_22_0, arg_22_1)
	return arg_22_0.begin_name_[arg_22_1] or {}
end

function var_0_0.beginImg(arg_23_0, arg_23_1)
	return arg_23_0.begin_img_[arg_23_1] or {}
end

function var_0_0.beginPosition_(arg_24_0, arg_24_1)
	return arg_24_0.begin_position_[arg_24_1] or {}
end

function var_0_0.win(arg_25_0, arg_25_1)
	return arg_25_0.win_txt_[arg_25_1] or {}
end

function var_0_0.winName(arg_26_0, arg_26_1)
	return arg_26_0.win_name_[arg_26_1] or {}
end

function var_0_0.winImg(arg_27_0, arg_27_1)
	return arg_27_0.win_img_[arg_27_1] or {}
end

function var_0_0.winPosition(arg_28_0, arg_28_1)
	return arg_28_0.win_position_[arg_28_1] or {}
end

function var_0_0.lose(arg_29_0, arg_29_1)
	return arg_29_0.lose_txt_[arg_29_1] or {}
end

function var_0_0.loseName(arg_30_0, arg_30_1)
	return arg_30_0.lose_name_[arg_30_1] or {}
end

function var_0_0.loseImg(arg_31_0, arg_31_1)
	return arg_31_0.lose_img_[arg_31_1] or {}
end

function var_0_0.losePosition(arg_32_0, arg_32_1)
	return arg_32_0.lose_position_[arg_32_1] or {}
end

function var_0_0.warn(arg_33_0, arg_33_1)
	return arg_33_0.warn_txt_[arg_33_1] or {}
end

function var_0_0.warnName(arg_34_0, arg_34_1)
	return arg_34_0.warn_name_[arg_34_1] or {}
end

function var_0_0.warnImg(arg_35_0, arg_35_1)
	return arg_35_0.warn_img_[arg_35_1] or {}
end

function var_0_0.warnPosition(arg_36_0, arg_36_1)
	return arg_36_0.warn_position_[arg_36_1] or {}
end

function var_0_0.rewardBuffs(arg_37_0, arg_37_1)
	return arg_37_0.rewardBuffs_[arg_37_1] or {}
end

function var_0_0.punishBuffs(arg_38_0, arg_38_1)
	return arg_38_0.punishBuffs_[arg_38_1] or {}
end

function var_0_0.img(arg_39_0, arg_39_1)
	return arg_39_0.img_[arg_39_1] or {}
end

function var_0_0.position(arg_40_0, arg_40_1)
	return arg_40_0.position_[arg_40_1] or {}
end

function var_0_0.dialogName(arg_41_0, arg_41_1)
	return arg_41_0.dialogName_[arg_41_1] or ""
end

function var_0_0.node(arg_42_0, arg_42_1)
	return arg_42_0.node_[arg_42_1] or {}
end

function var_0_0.cure(arg_43_0, arg_43_1)
	return arg_43_0.cure_[arg_43_1] or {}
end

function var_0_0.missionNum(arg_44_0, arg_44_1)
	return arg_44_0.missionNum_[arg_44_1] or {}
end

return var_0_0
