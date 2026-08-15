local var_0_0 = class("NianBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.campaign_name = {}
	arg_1_0.skill1 = {}
	arg_1_0.skill2 = {}
	arg_1_0.skill3 = {}
	arg_1_0.skill4 = {}
	arg_1_0.need_brave = {}
	arg_1_0.rewardItem = {}
	arg_1_0.campaign_des = {}
	arg_1_0.name = {}
	arg_1_0.open_explain = {}
	arg_1_0.model_id = {}
	arg_1_0.monster_id = {}
	arg_1_0.fight_id = {}
	arg_1_0.id_ = {}

	import("app.common.tables.TableParser").parse("newyear_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.campaign_name[var_2_0] = arg_2_0.campaign_name
		arg_1_0.skill1[var_2_0] = tonumber(arg_2_0.skill1)
		arg_1_0.skill2[var_2_0] = tonumber(arg_2_0.skill2)
		arg_1_0.skill3[var_2_0] = tonumber(arg_2_0.skill3)
		arg_1_0.skill4[var_2_0] = tonumber(arg_2_0.skill4)
		arg_1_0.need_brave[var_2_0] = arg_2_0.boss_brave_node
		arg_1_0.rewardItem[var_2_0] = tonumber(arg_2_0.reward_item)
		arg_1_0.campaign_des[var_2_0] = arg_2_0.campaign_des
		arg_1_0.name[var_2_0] = arg_2_0.name
		arg_1_0.open_explain[var_2_0] = arg_2_0.open_explain
		arg_1_0.model_id[var_2_0] = tonumber(arg_2_0.model_id)
		arg_1_0.monster_id[var_2_0] = tonumber(arg_2_0.monster_id)
		arg_1_0.fight_id[var_2_0] = tonumber(arg_2_0.fight_id)
	end)
end

function var_0_0.modelID(arg_3_0, arg_3_1)
	return arg_3_0.model_id[arg_3_1] or 0
end

function var_0_0.monsterID(arg_4_0, arg_4_1)
	return arg_4_0.monster_id[arg_4_1] or 0
end

function var_0_0.words(arg_5_0, arg_5_1)
	return arg_5_0.words_[arg_5_1] or nil
end

return var_0_0
