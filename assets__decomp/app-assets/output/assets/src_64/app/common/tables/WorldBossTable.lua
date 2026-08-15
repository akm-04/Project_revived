local var_0_0 = class("WorldBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.campaign_name = {}
	arg_1_0.skill1 = {}
	arg_1_0.skill2 = {}
	arg_1_0.skill3 = {}
	arg_1_0.skill4 = {}
	arg_1_0.need_brave = {}
	arg_1_0.campaign_des = {}
	arg_1_0.name = {}
	arg_1_0.open_explain = {}
	arg_1_0.model_id = {}
	arg_1_0.monster_id = {}
	arg_1_0.stone = {}
	arg_1_0.open_function = {}
	arg_1_0.fight_id = {}
	arg_1_0.ids_ = {}
	arg_1_0.boss_id = {}

	local var_1_0 = 1

	import("app.common.tables.TableParser").parse("dungeon_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		if var_2_0 > 10010 and var_2_0 < 10016 then
			table.insert(arg_1_0.boss_id, var_2_0)

			arg_1_0.boss_num = var_1_0
			arg_1_0.ids_[var_2_0] = var_1_0
			var_1_0 = var_1_0 + 1
			arg_1_0.campaign_name[var_2_0] = arg_2_0.campaign_name
			arg_1_0.skill1[var_2_0] = tonumber(arg_2_0.skill1)
			arg_1_0.skill2[var_2_0] = tonumber(arg_2_0.skill2)
			arg_1_0.skill3[var_2_0] = tonumber(arg_2_0.skill3)
			arg_1_0.skill4[var_2_0] = tonumber(arg_2_0.skill4)
			arg_1_0.need_brave[var_2_0] = arg_2_0.dungeon_brave_node
			arg_1_0.campaign_des[var_2_0] = arg_2_0.campaign_des
			arg_1_0.name[var_2_0] = arg_2_0.name
			arg_1_0.open_explain[var_2_0] = arg_2_0.open_explain
			arg_1_0.model_id[var_2_0] = arg_2_0.model_id
			arg_1_0.monster_id[var_2_0] = arg_2_0.monster_id
			arg_1_0.stone[var_2_0] = tonumber(arg_2_0.defeat_stone)
			arg_1_0.open_function[var_2_0] = arg_2_0.open_function
			arg_1_0.fight_id[var_2_0] = tonumber(arg_2_0.fight_id)
		end
	end)
end

function var_0_0.words(arg_3_0, arg_3_1)
	return arg_3_0.words_[arg_3_1] or nil
end

return var_0_0
