local var_0_0 = class("ActivityRichCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.campaignDes_ = {}
	arg_1_0.heroDisplay_ = {}
	arg_1_0.monsterDisplay_ = {}
	arg_1_0.monsterTeamDisplay_ = {}
	arg_1_0.monsterPetDisplay_ = {}
	arg_1_0.battleId_ = {}
	arg_1_0.lastCampaignId_ = {}
	arg_1_0.nextCampaignId_ = {}
	arg_1_0.itemIds_ = {}
	arg_1_0.itemNums_ = {}
	arg_1_0.campaignIds_ = {}

	import("app.common.tables.TableParser").parse("activity_rich_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.campaignIds_, var_2_0)

		arg_1_0.campaignDes_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.heroDisplay_[var_2_0] = tonumber(arg_2_0.hero_display)
		arg_1_0.monsterDisplay_[var_2_0] = tonumber(arg_2_0.monster_display)
		arg_1_0.monsterTeamDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_team_display, "|")
		arg_1_0.monsterPetDisplay_[var_2_0] = tonumber(arg_2_0.monster_pet_display)
		arg_1_0.battleId_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.lastCampaignId_[var_2_0] = tonumber(arg_2_0.last_campaign_id)
		arg_1_0.nextCampaignId_[var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.itemIds_[var_2_0] = arg_2_0.item_ids
		arg_1_0.itemNums_[var_2_0] = arg_2_0.item_nums
	end)
end

function var_0_0.campaignDes(arg_3_0, arg_3_1)
	return arg_3_0.campaignDes_[arg_3_1] or ""
end

function var_0_0.heroDisplay(arg_4_0, arg_4_1)
	return arg_4_0.heroDisplay_[arg_4_1] or 0
end

function var_0_0.monsterDisplay(arg_5_0, arg_5_1)
	return arg_5_0.monsterDisplay_[arg_5_1] or 0
end

function var_0_0.monsterTeamDisplay(arg_6_0, arg_6_1)
	return arg_6_0.monsterTeamDisplay_[arg_6_1] or {}
end

function var_0_0.monsterPetDisplay(arg_7_0, arg_7_1)
	return arg_7_0.monsterPetDisplay_[arg_7_1] or 0
end

function var_0_0.battleId(arg_8_0, arg_8_1)
	return arg_8_0.battleId_[arg_8_1] or 0
end

function var_0_0.lastCampaignId(arg_9_0, arg_9_1)
	return arg_9_0.lastCampaignId_[arg_9_1] or 0
end

function var_0_0.nextCampaignId(arg_10_0, arg_10_1)
	return arg_10_0.nextCampaignId_[arg_10_1] or 0
end

function var_0_0.itemIds(arg_11_0, arg_11_1)
	return arg_11_0.itemIds_[arg_11_1] or ""
end

function var_0_0.itemNums(arg_12_0, arg_12_1)
	return arg_12_0.itemNums_[arg_12_1] or ""
end

function var_0_0.campaignIds(arg_13_0)
	return arg_13_0.campaignIds_
end

function var_0_0.getIdxByCampaignId(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_0:campaignIds()

	for iter_14_0 = 1, #var_14_0 do
		if var_14_0[iter_14_0] == arg_14_1 then
			return iter_14_0
		end
	end

	return 1
end

return var_0_0
