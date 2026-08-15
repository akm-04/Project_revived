local var_0_0 = class("WarCampCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.heroName_ = {}
	arg_1_0.campaignDes_ = {}
	arg_1_0.skillId_ = {}
	arg_1_0.fightId_ = {}
	arg_1_0.modelId_ = {}
	arg_1_0.modelPic_ = {}
	arg_1_0.campaignType_ = {}
	arg_1_0.cityId_ = {}
	arg_1_0.name_ = {}
	arg_1_0.monsterId_ = {}

	import("app.common.tables.TableParser").parse("camp_war_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.heroName_[var_2_0] = arg_2_0.boss_name_text
		arg_1_0.campaignDes_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.skillId_[var_2_0] = {
			tonumber(arg_2_0.skill1),
			tonumber(arg_2_0.skill2),
			tonumber(arg_2_0.skill3),
			tonumber(arg_2_0.skill4)
		}
		arg_1_0.fightId_[var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.modelId_[var_2_0] = tonumber(arg_2_0.model_id)
		arg_1_0.modelPic_[var_2_0] = arg_2_0.model_black
		arg_1_0.campaignType_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.cityId_[var_2_0] = tonumber(arg_2_0.city_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.monsterId_[var_2_0] = tonumber(arg_2_0.monster_id)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.heroName(arg_4_0, arg_4_1)
	return arg_4_0.heroName_[arg_4_1] or ""
end

function var_0_0.campaignDes(arg_5_0, arg_5_1)
	return arg_5_0.campaignDes_[arg_5_1] or ""
end

function var_0_0.skillId(arg_6_0, arg_6_1)
	return arg_6_0.skillId_[arg_6_1] or {}
end

function var_0_0.fightId(arg_7_0, arg_7_1)
	return arg_7_0.fightId_[arg_7_1] or 0
end

function var_0_0.campaignType(arg_8_0, arg_8_1)
	return arg_8_0.campaignType_[arg_8_1] or 0
end

function var_0_0.cityId(arg_9_0, arg_9_1)
	return arg_9_0.cityId_[arg_9_1] or 0
end

function var_0_0.modelId(arg_10_0, arg_10_1)
	return arg_10_0.modelId_[arg_10_1] or 0
end

function var_0_0.modelPic(arg_11_0, arg_11_1)
	return arg_11_0.modelPic_[arg_11_1] or ""
end

function var_0_0.monsterId(arg_12_0, arg_12_1)
	return arg_12_0.monsterId_[arg_12_1] or 0
end

return var_0_0
