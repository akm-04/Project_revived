local var_0_0 = class("ActivitySingleMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.req_ = {}
	arg_1_0.battleId_ = {}
	arg_1_0.bossName_ = {}
	arg_1_0.skillTitle1_ = {}
	arg_1_0.skillTitle2_ = {}
	arg_1_0.skillTranslation1_ = {}
	arg_1_0.skillTranslation2_ = {}
	arg_1_0.heroRecommend_ = {}

	import("app.common.tables.TableParser").parse("activity_single_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.req_[var_2_0] = xyd.splitToNumber(arg_2_0.req, "|")
		arg_1_0.battleId_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.bossName_[var_2_0] = arg_2_0.boss_name
		arg_1_0.skillTitle1_[var_2_0] = arg_2_0.skill_title1
		arg_1_0.skillTitle2_[var_2_0] = arg_2_0.skill_title2
		arg_1_0.skillTranslation1_[var_2_0] = arg_2_0.skill_translation1
		arg_1_0.skillTranslation2_[var_2_0] = arg_2_0.skill_translation2
		arg_1_0.heroRecommend_[var_2_0] = xyd.splitToNumber(arg_2_0.hero_recommend, "|")
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or ""
end

function var_0_0.req(arg_5_0, arg_5_1)
	return arg_5_0.req_[arg_5_1] or {}
end

function var_0_0.battleId(arg_6_0, arg_6_1)
	return arg_6_0.battleId_[arg_6_1] or 0
end

function var_0_0.bossName(arg_7_0, arg_7_1)
	return arg_7_0.bossName_[arg_7_1] or ""
end

function var_0_0.skillTitle1(arg_8_0, arg_8_1)
	return arg_8_0.skillTitle1_[arg_8_1] or ""
end

function var_0_0.skillTitle2(arg_9_0, arg_9_1)
	return arg_9_0.skillTitle2_[arg_9_1] or ""
end

function var_0_0.skillTranslation1(arg_10_0, arg_10_1)
	return arg_10_0.skillTranslation1_[arg_10_1] or ""
end

function var_0_0.skillTranslation2(arg_11_0, arg_11_1)
	return arg_11_0.skillTranslation2_[arg_11_1] or ""
end

function var_0_0.heroRecommend(arg_12_0, arg_12_1)
	return arg_12_0.heroRecommend_[arg_12_1] or {}
end

return var_0_0
