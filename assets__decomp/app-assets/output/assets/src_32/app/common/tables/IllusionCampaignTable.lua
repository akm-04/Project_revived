local var_0_0 = class("IllusionCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.hero_name_ = {}
	arg_1_0.campaign_des_ = {}
	arg_1_0.skill_id_ = {}
	arg_1_0.fight_id_ = {}
	arg_1_0.model_id_ = {}
	arg_1_0.model_pic_ = {}
	arg_1_0.next_id_ = {}
	arg_1_0.is_open_ = {}
	arg_1_0.monster_id_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("paradise_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.hero_name_[var_2_0] = arg_2_0.boss_name_text
		arg_1_0.campaign_des_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.skill_id_[var_2_0] = {
			tonumber(arg_2_0.skill1),
			tonumber(arg_2_0.skill2),
			tonumber(arg_2_0.skill3),
			tonumber(arg_2_0.skill4)
		}
		arg_1_0.fight_id_[var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.model_id_[var_2_0] = tonumber(arg_2_0.model_id)
		arg_1_0.monster_id_[var_2_0] = tonumber(arg_2_0.monster_id)
		arg_1_0.model_pic_[var_2_0] = arg_2_0.model_black
		arg_1_0.next_id_[var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.is_open_[var_2_0] = tonumber(arg_2_0.if_hide) == 0
		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.heroName(arg_4_0, arg_4_1)
	return arg_4_0.hero_name_[arg_4_1] or ""
end

function var_0_0.campaignDes(arg_5_0, arg_5_1)
	return arg_5_0.campaign_des_[arg_5_1] or ""
end

function var_0_0.skillId(arg_6_0, arg_6_1)
	return arg_6_0.skill_id_[arg_6_1] or {}
end

function var_0_0.fightId(arg_7_0, arg_7_1)
	return arg_7_0.fight_id_[arg_7_1] or 0
end

function var_0_0.modelId(arg_8_0, arg_8_1)
	return arg_8_0.model_id_[arg_8_1] or 0
end

function var_0_0.tableID(arg_9_0, arg_9_1)
	return arg_9_0.monster_id_[arg_9_1] or 0
end

function var_0_0.modelPic(arg_10_0, arg_10_1)
	return arg_10_0.model_pic_[arg_10_1] or ""
end

function var_0_0.nextBoss(arg_11_0, arg_11_1)
	arg_11_1 = arg_11_0.next_id_[arg_11_1]

	while not arg_11_0.is_open_[arg_11_1] do
		arg_11_1 = arg_11_0.next_id_[arg_11_1]
	end

	return arg_11_1
end

return var_0_0
