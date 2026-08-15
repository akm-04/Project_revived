local var_0_0 = class("MazeCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.bossName_ = {}
	arg_1_0.campaignDesc_ = {}
	arg_1_0.fightID_ = {}
	arg_1_0.modelID_ = {}
	arg_1_0.skills_ = {}
	arg_1_0.monsterID_ = {}

	import("app.common.tables.TableParser").parse("maze_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.boss_id)

		arg_1_0.bossName_[var_2_0] = tonumber(arg_2_0.name)
		arg_1_0.campaignDesc_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.fightID_[var_2_0] = arg_2_0.fight_id
		arg_1_0.modelID_[var_2_0] = arg_2_0.model_id
		arg_1_0.monsterID_[var_2_0] = tonumber(arg_2_0.monster_id)
		arg_1_0.skills_[var_2_0] = {}

		for iter_2_0 = 1, 4 do
			table.insert(arg_1_0.skills_[var_2_0], tonumber(arg_2_0["skill" .. iter_2_0]))
		end
	end)
end

function var_0_0.campaignDesc(arg_3_0, arg_3_1)
	return arg_3_0.campaignDesc_[arg_3_1] or 0
end

function var_0_0.bossName(arg_4_0, arg_4_1)
	return arg_4_0.bossName_[arg_4_1] or ""
end

function var_0_0.fightID(arg_5_0, arg_5_1)
	return arg_5_0.fightID_[arg_5_1]
end

function var_0_0.modelID(arg_6_0, arg_6_1)
	return arg_6_0.modelID_[arg_6_1]
end

function var_0_0.tableID(arg_7_0, arg_7_1)
	return arg_7_0.monsterID_[arg_7_1]
end

function var_0_0.skills(arg_8_0, arg_8_1)
	return arg_8_0.skills_[arg_8_1]
end

return var_0_0
