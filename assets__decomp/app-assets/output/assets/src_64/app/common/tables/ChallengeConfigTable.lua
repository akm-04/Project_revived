local var_0_0 = class("ChallengeConfigTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.challengeName_ = {}
	arg_1_0.nextChallenge_ = {}
	arg_1_0.challengeTypedes_ = {}
	arg_1_0.skillType1_ = {}
	arg_1_0.skillTranslation1_ = {}
	arg_1_0.skillType2_ = {}
	arg_1_0.skillTranslation2_ = {}
	arg_1_0.dailyLimit_ = {}
	arg_1_0.itemDisplay_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.challenges_ = {}
	arg_1_0.energyCost_ = {}
	arg_1_0.lastCampEighty_ = {}
	arg_1_0.lastCampEightyFive_ = {}
	arg_1_0.lastCampNinety_ = {}
	arg_1_0.heroRecommend_ = {}
	arg_1_0.monster_ = {}
	arg_1_0.modleScale_ = {}
	arg_1_0.battleModleScale_ = {}
	arg_1_0.upPosition_ = {}
	arg_1_0.type_ = {}

	import("app.common.tables.TableParser").parse("challenge_config.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.challenge_id)

		arg_1_0.challengeName_[var_2_0] = arg_2_0.challenge_type_name
		arg_1_0.nextChallenge_[var_2_0] = tonumber(arg_2_0.next_challenge_id)
		arg_1_0.challengeTypedes_[var_2_0] = arg_2_0.challenge_type_des
		arg_1_0.skillType1_[var_2_0] = arg_2_0.skill_title1
		arg_1_0.skillTranslation1_[var_2_0] = arg_2_0.skill_translation1
		arg_1_0.skillType2_[var_2_0] = arg_2_0.skill_title2
		arg_1_0.skillTranslation2_[var_2_0] = arg_2_0.skill_translation2
		arg_1_0.dailyLimit_[var_2_0] = arg_2_0.daily_limit
		arg_1_0.itemDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.challenges_[var_2_0] = xyd.splitToNumber(arg_2_0.challenges, "|")
		arg_1_0.energyCost_[var_2_0] = tonumber(arg_2_0.energy_cost)
		arg_1_0.lastCampEighty_[var_2_0] = tonumber(arg_2_0.last_campaign_80)
		arg_1_0.lastCampEightyFive_[var_2_0] = tonumber(arg_2_0.last_campaign_85)
		arg_1_0.lastCampNinety_[var_2_0] = tonumber(arg_2_0.last_campaign_90)
		arg_1_0.heroRecommend_[var_2_0] = xyd.splitToNumber(arg_2_0.hero_recommend, "|")
		arg_1_0.monster_[var_2_0] = tonumber(arg_2_0.monster_modle)
		arg_1_0.modleScale_[var_2_0] = tonumber(arg_2_0.modle_scale)
		arg_1_0.battleModleScale_[var_2_0] = tonumber(arg_2_0.battle_modle_scale)
		arg_1_0.upPosition_[var_2_0] = tonumber(arg_2_0.modle_postion)

		local var_2_1 = tonumber(arg_2_0.type)

		if arg_1_0.type_[var_2_1] == nil then
			arg_1_0.type_[var_2_1] = {}
		end

		table.insert(arg_1_0.type_[var_2_1], var_2_0)
	end)
end

function var_0_0.heroCount(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or {}
end

function var_0_0.upPosition(arg_4_0, arg_4_1)
	return arg_4_0.upPosition_[arg_4_1] or 0
end

function var_0_0.battleModleScale(arg_5_0, arg_5_1)
	return arg_5_0.battleModleScale_[arg_5_1] or 0
end

function var_0_0.modleScale(arg_6_0, arg_6_1)
	return arg_6_0.modleScale_[arg_6_1] or 0
end

function var_0_0.monster(arg_7_0, arg_7_1)
	return arg_7_0.monster_[arg_7_1] or 0
end

function var_0_0.hero_recommend(arg_8_0, arg_8_1)
	return arg_8_0.heroRecommend_[arg_8_1] or 0
end

function var_0_0.challengeName(arg_9_0, arg_9_1)
	return arg_9_0.challengeName_[arg_9_1] or {}
end

function var_0_0.nextChallenge(arg_10_0, arg_10_1)
	return arg_10_0.nextChallenge_[arg_10_1] or 0
end

function var_0_0.challengeTypedes(arg_11_0, arg_11_1)
	return arg_11_0.challengeTypedes_[arg_11_1] or {}
end

function var_0_0.skillType1(arg_12_0, arg_12_1)
	return arg_12_0.skillType1_[arg_12_1] or {}
end

function var_0_0.skillTranslation1(arg_13_0, arg_13_1)
	return arg_13_0.skillTranslation1_[arg_13_1] or {}
end

function var_0_0.skillType2(arg_14_0, arg_14_1)
	return arg_14_0.skillType2_[arg_14_1] or {}
end

function var_0_0.skillTranslation2(arg_15_0, arg_15_1)
	return arg_15_0.skillTranslation2_[arg_15_1] or {}
end

function var_0_0.dailyLimit(arg_16_0, arg_16_1)
	return arg_16_0.dailyLimit_[arg_16_1] or 0
end

function var_0_0.itemDisplay(arg_17_0, arg_17_1)
	return arg_17_0.itemDisplay_[arg_17_1] or 0
end

function var_0_0.icon(arg_18_0, arg_18_1)
	return arg_18_0.icon_[arg_18_1] or {}
end

function var_0_0.challenges(arg_19_0, arg_19_1)
	return arg_19_0.challenges_[arg_19_1] or {}
end

function var_0_0.energyCost(arg_20_0, arg_20_1)
	return arg_20_0.energyCost_[arg_20_1] or 0
end

function var_0_0.lastCampEighty(arg_21_0, arg_21_1)
	return arg_21_0.lastCampEighty_[arg_21_1] or 0
end

function var_0_0.lastCampEightyFive(arg_22_0, arg_22_1)
	return arg_22_0.lastCampEightyFive_[arg_22_1] or 0
end

function var_0_0.lastCampNinety(arg_23_0, arg_23_1)
	return arg_23_0.lastCampNinety_[arg_23_1] or 0
end

return var_0_0
