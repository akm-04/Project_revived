local var_0_0 = class("ActivitySakuraCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.campaignId_ = {}
	arg_1_0.energyCost_ = {}
	arg_1_0.items_ = {}
	arg_1_0.itemNums_ = {}
	arg_1_0.fightId_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura_security.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.level)

		arg_1_0.campaignId_[var_2_0] = {}

		for iter_2_0 = 1, 7 do
			arg_1_0.campaignId_[var_2_0][iter_2_0] = tonumber(arg_2_0["day" .. iter_2_0])
		end
	end)
	import("app.common.tables.TableParser").parse("activity_sakura_campaign.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.campaign_id)

		arg_1_0.energyCost_[var_3_0] = tonumber(arg_3_0.energy_cost)
		arg_1_0.items_[var_3_0] = xyd.splitToNumber(arg_3_0.items, "|")
		arg_1_0.itemNums_[var_3_0] = xyd.splitToNumber(arg_3_0.item_nums, "|")
		arg_1_0.fightId_[var_3_0] = tonumber(arg_3_0.fight_id)
	end)
end

function var_0_0.energyCost(arg_4_0, arg_4_1, arg_4_2)
	return arg_4_0.energyCost_[arg_4_0.campaignId_[arg_4_1][arg_4_2]] or 0
end

function var_0_0.items(arg_5_0, arg_5_1, arg_5_2)
	return arg_5_0.items_[arg_5_0.campaignId_[arg_5_1][arg_5_2]] or 0
end

function var_0_0.itemNums(arg_6_0, arg_6_1, arg_6_2)
	return arg_6_0.itemNums_[arg_6_0.campaignId_[arg_6_1][arg_6_2]] or 0
end

function var_0_0.fightId(arg_7_0, arg_7_1, arg_7_2)
	return arg_7_0.fightId_[arg_7_0.campaignId_[arg_7_1][arg_7_2]] or 0
end

return var_0_0
