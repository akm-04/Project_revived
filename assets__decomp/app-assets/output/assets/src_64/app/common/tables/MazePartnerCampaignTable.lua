local var_0_0 = class("MazePartnerCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.monsterBattleId_ = {}
	arg_1_0.monsterDisplay_ = {}
	arg_1_0.awardShow_ = {}
	arg_1_0.banList_ = {}

	import("app.common.tables.TableParser").parse("maze_partner_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = xyd.split(arg_2_0.monster_battle_id, "|")

		arg_1_0.monsterBattleId_[var_2_0] = {}
		arg_1_0.awardShow_[var_2_0] = xyd.splitToNumber(arg_2_0.award_show, "|")
		arg_1_0.monsterDisplay_[var_2_0] = {}

		for iter_2_0, iter_2_1 in ipairs(var_2_1) do
			table.insert(arg_1_0.monsterBattleId_[var_2_0], xyd.splitToNumber(var_2_1[iter_2_0], ","))
		end

		local var_2_2 = xyd.split(arg_2_0.monster_display, "|")

		for iter_2_2, iter_2_3 in ipairs(var_2_2) do
			table.insert(arg_1_0.monsterDisplay_[var_2_0], xyd.splitToNumber(var_2_2[iter_2_2], ","))
		end

		arg_1_0.banList_[var_2_0] = xyd.splitToNumber(arg_2_0.ban_hero_id, "|")
	end)
end

function var_0_0.campaignDesc(arg_3_0, arg_3_1)
	return arg_3_0.campaignDesc_[arg_3_1] or 0
end

function var_0_0.monsterDisplay(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.monsterBattleId_) do
		for iter_4_2, iter_4_3 in ipairs(iter_4_1) do
			for iter_4_4, iter_4_5 in ipairs(iter_4_3) do
				if iter_4_5 == arg_4_1 then
					return arg_4_0.monsterDisplay_[iter_4_0][iter_4_2][iter_4_4]
				end
			end
		end
	end

	return 0
end

function var_0_0.awards(arg_5_0, arg_5_1)
	return arg_5_0.awardShow_[arg_5_1] or {}
end

function var_0_0.banList(arg_6_0, arg_6_1)
	return arg_6_0.banList_[arg_6_1]
end

return var_0_0
