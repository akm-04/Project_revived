local var_0_0 = class("BattleTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.fight1_ = {}
	arg_1_0.fight2_ = {}
	arg_1_0.fight3_ = {}
	arg_1_0.dropWeight_ = {}
	arg_1_0.preBattleShow_ = {}
	arg_1_0.storyBefore_ = {}
	arg_1_0.storyVictory_ = {}
	arg_1_0.storyLose_ = {}
	arg_1_0.storyHeroes_ = {}
	arg_1_0.specialBefore_ = {}
	arg_1_0.specialVictory_ = {}
	arg_1_0.specialLose_ = {}
	arg_1_0.monsters_ = {}
	arg_1_0.maps_ = {}
	arg_1_0.name_ = {}
	arg_1_0.levLimit_ = {}
	arg_1_0.sounds_ = {}
	arg_1_0.modeType_ = {}
	arg_1_0.protectedHero_ = {}
	arg_1_0.timingOfReinforcement_ = {}
	arg_1_0.killingHero_ = {}
	arg_1_0.killingNumber_ = {}
	arg_1_0.timeLimit_ = {}
	arg_1_0.campaignType_ = {}
	arg_1_0.assistPartner_ = {}
	arg_1_0.assistStory_ = {}
	arg_1_0.specialMonsterWave_ = {}
	arg_1_0.specialMonsterBuff_ = {}
	arg_1_0.escapeEnemy_ = {}
	arg_1_0.escapeStory_ = {}
	arg_1_0.campaignLimit_ = {}
	arg_1_0.extraMonsterBuffers_ = {}
	arg_1_0.reinforcePartnerIds_ = {}
	arg_1_0.reinforcePartnerRatios_ = {}

	import("app.common.tables.TableParser").parse("battle.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.fight_id)

		arg_1_0.fight1_[var_2_0] = xyd.splitToNumber(arg_2_0.fight_1, "|")
		arg_1_0.fight2_[var_2_0] = xyd.splitToNumber(arg_2_0.fight_2, "|")
		arg_1_0.fight3_[var_2_0] = xyd.splitToNumber(arg_2_0.fight_3, "|")
		arg_1_0.monsters_[var_2_0] = {}

		table.insert(arg_1_0.monsters_[var_2_0], arg_1_0.fight1_[var_2_0] or {})
		table.insert(arg_1_0.monsters_[var_2_0], arg_1_0.fight2_[var_2_0] or {})
		table.insert(arg_1_0.monsters_[var_2_0], arg_1_0.fight3_[var_2_0] or {})

		arg_1_0.dropWeight_[var_2_0] = xyd.splitToNumber(arg_2_0.drop_weight, "|")
		arg_1_0.preBattleShow_[var_2_0] = xyd.splitToNumber(arg_2_0.pre_battle_show, "|")
		arg_1_0.storyBefore_[var_2_0] = tonumber(arg_2_0.prewar_story)
		arg_1_0.storyVictory_[var_2_0] = tonumber(arg_2_0.victory_story)
		arg_1_0.storyLose_[var_2_0] = tonumber(arg_2_0.defeat_story)
		arg_1_0.storyHeroes_[var_2_0] = xyd.splitToNumber(arg_2_0.special_partner_id, "|")
		arg_1_0.specialBefore_[var_2_0] = xyd.splitToNumber(arg_2_0.special_prewar_story, "|")
		arg_1_0.specialVictory_[var_2_0] = xyd.splitToNumber(arg_2_0.special_victory_story, "|")
		arg_1_0.specialLose_[var_2_0] = xyd.splitToNumber(arg_2_0.special_defeat_story, "|")
		arg_1_0.maps_[var_2_0] = xyd.split(arg_2_0.map_images, "|")
		arg_1_0.name_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.campaignType_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.levLimit_[var_2_0] = tonumber(arg_2_0.level_limit)
		arg_1_0.sounds_[var_2_0] = arg_2_0.campaign_bgm
		arg_1_0.modeType_[var_2_0] = tonumber(arg_2_0.mode_type)
		arg_1_0.protectedHero_[var_2_0] = tonumber(arg_2_0.protected_hero_id)
		arg_1_0.timingOfReinforcement_[var_2_0] = xyd.splitToNumber(arg_2_0.timing_of_reinforcement, "|")
		arg_1_0.killingHero_[var_2_0] = tonumber(arg_2_0.killing_hero_id)
		arg_1_0.killingNumber_[var_2_0] = tonumber(arg_2_0.killing_number)
		arg_1_0.timeLimit_[var_2_0] = xyd.splitToNumber(arg_2_0.time_limit, "|")
		arg_1_0.assistPartner_[var_2_0] = xyd.splitToNumber(arg_2_0.assist_partner, "|")
		arg_1_0.assistStory_[var_2_0] = tonumber(arg_2_0.assist_story)
		arg_1_0.specialMonsterWave_[var_2_0] = xyd.splitToNumber(arg_2_0.number_wave, "|")
		arg_1_0.specialMonsterBuff_[var_2_0] = xyd.splitToNumber(arg_2_0.buff_monster, "|")
		arg_1_0.escapeStory_[var_2_0] = tonumber(arg_2_0.escape_story)
		arg_1_0.escapeEnemy_[var_2_0] = tonumber(arg_2_0.escape_enemy)
		arg_1_0.campaignLimit_[var_2_0] = xyd.splitToNumber(arg_2_0.campaign_limit, "|")
		arg_1_0.extraMonsterBuffers_[var_2_0] = xyd.splitToNumber(arg_2_0.extra_monster_buffers, "|")
		arg_1_0.reinforcePartnerIds_[var_2_0] = xyd.splitToNumber(arg_2_0.reinforce_partner_ids, "|")
		arg_1_0.reinforcePartnerRatios_[var_2_0] = xyd.splitToNumber(arg_2_0.reinforce_partner_ratios, "|")
	end)
end

function var_0_0.fight1(arg_3_0, arg_3_1)
	return arg_3_0.fight1_[arg_3_1] or {}
end

function var_0_0.fight2(arg_4_0, arg_4_1)
	return arg_4_0.fight2_[arg_4_1] or {}
end

function var_0_0.fight3(arg_5_0, arg_5_1)
	return arg_5_0.fight3_[arg_5_1] or {}
end

function var_0_0.monsters(arg_6_0, arg_6_1, arg_6_2)
	if arg_6_2 then
		return arg_6_0.monsters_[arg_6_1][arg_6_2]
	end

	return arg_6_0.monsters_[arg_6_1]
end

function var_0_0.dropWeight(arg_7_0, arg_7_1)
	return arg_7_0.dropWeight_[arg_7_1] or {}
end

function var_0_0.preBattleShow(arg_8_0, arg_8_1)
	return arg_8_0.preBattleShow_[arg_8_1] or {}
end

function var_0_0.storyBefore(arg_9_0, arg_9_1)
	return arg_9_0.storyBefore_[arg_9_1] or 0
end

function var_0_0.storyVictory(arg_10_0, arg_10_1)
	return arg_10_0.storyVictory_[arg_10_1] or 0
end

function var_0_0.storyLose(arg_11_0, arg_11_1)
	return arg_11_0.storyLose_[arg_11_1] or 0
end

function var_0_0.storyHeroes(arg_12_0, arg_12_1)
	return arg_12_0.storyHeroes_[arg_12_1] or {}
end

function var_0_0.specialBefore(arg_13_0, arg_13_1)
	return arg_13_0.specialBefore_[arg_13_1] or {}
end

function var_0_0.specialVictory(arg_14_0, arg_14_1)
	return arg_14_0.specialVictory_[arg_14_1] or {}
end

function var_0_0.specialLose(arg_15_0, arg_15_1)
	return arg_15_0.specialLose_[arg_15_1] or {}
end

function var_0_0.maps(arg_16_0, arg_16_1)
	return arg_16_0.maps_[arg_16_1] or {}
end

function var_0_0.name(arg_17_0, arg_17_1)
	return arg_17_0.name_[arg_17_1] or ""
end

function var_0_0.levLimit(arg_18_0, arg_18_1)
	return arg_18_0.levLimit_[arg_18_1] or 0
end

function var_0_0.sounds(arg_19_0, arg_19_1)
	return arg_19_0.sounds_[arg_19_1] or ""
end

function var_0_0.modeType(arg_20_0, arg_20_1)
	return arg_20_0.modeType_[arg_20_1] or 0
end

function var_0_0.protectedHero(arg_21_0, arg_21_1)
	return arg_21_0.protectedHero_[arg_21_1] or 0
end

function var_0_0.timingOfReinforcement(arg_22_0, arg_22_1)
	return arg_22_0.timingOfReinforcement_[arg_22_1] or {}
end

function var_0_0.killingHero(arg_23_0, arg_23_1)
	return arg_23_0.killingHero_[arg_23_1] or 0
end

function var_0_0.killingNumber(arg_24_0, arg_24_1)
	return arg_24_0.killingNumber_[arg_24_1] or 0
end

function var_0_0.timeLimit(arg_25_0, arg_25_1)
	return arg_25_0.timeLimit_[arg_25_1] or {}
end

function var_0_0.campaignType(arg_26_0, arg_26_1)
	return arg_26_0.campaignType_[arg_26_1] or 0
end

function var_0_0.assistPartner(arg_27_0, arg_27_1)
	return arg_27_0.assistPartner_[arg_27_1] or {}
end

function var_0_0.assistStory(arg_28_0, arg_28_1)
	return arg_28_0.assistStory_[arg_28_1] or 0
end

function var_0_0.specialMonsterWave(arg_29_0, arg_29_1)
	return arg_29_0.specialMonsterWave_[arg_29_1] or {}
end

function var_0_0.specialMonsterBuff(arg_30_0, arg_30_1)
	return arg_30_0.specialMonsterBuff_[arg_30_1] or {}
end

function var_0_0.escapeEnemy(arg_31_0, arg_31_1)
	return arg_31_0.escapeEnemy_[arg_31_1] or 0
end

function var_0_0.escapeStory(arg_32_0, arg_32_1)
	return arg_32_0.escapeStory_[arg_32_1] or 0
end

function var_0_0.campaignLimit(arg_33_0, arg_33_1)
	return arg_33_0.campaignLimit_[arg_33_1] or {}
end

function var_0_0.extraMonsterBuffers(arg_34_0, arg_34_1)
	return arg_34_0.extraMonsterBuffers_[arg_34_1] or {}
end

function var_0_0.reinforcePartnerIds(arg_35_0, arg_35_1)
	return arg_35_0.reinforcePartnerIds_[arg_35_1] or {}
end

function var_0_0.reinforcePartnerRatios(arg_36_0, arg_36_1)
	return arg_36_0.reinforcePartnerRatios_[arg_36_1] or {}
end

return var_0_0
