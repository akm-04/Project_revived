local var_0_0 = class("ActivityAllNightCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.campaignName_ = {}
	arg_1_0.campaignDes_ = {}
	arg_1_0.campaignType_ = {}
	arg_1_0.itemDisplay_ = {}
	arg_1_0.dropbox_ = {}
	arg_1_0.monsterDisplay_ = {}
	arg_1_0.monsterStar_ = {}
	arg_1_0.monsterQuality_ = {}
	arg_1_0.monsterLevel_ = {}
	arg_1_0.element_ = {}
	arg_1_0.fightId_ = {}
	arg_1_0.lastCampaignId_ = {}
	arg_1_0.nextCampaignId_ = {}
	arg_1_0.itemCampaignId_ = {}
	arg_1_0.costType_ = {}
	arg_1_0.winCost_ = {}
	arg_1_0.loseCost_ = {}
	arg_1_0.posX_ = {}
	arg_1_0.posY_ = {}
	arg_1_0.smallBg_ = {}
	arg_1_0.avatar_ = {}
	arg_1_0.preWarStory_ = {}
	arg_1_0.victoryStory_ = {}
	arg_1_0.startPoints_ = {}
	arg_1_0.firstDisplay_ = {}
	arg_1_0.firstDisplayNum_ = {}

	import("app.common.tables.TableParser").parse("activity_polar_night_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.campaignName_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.campaignDes_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.campaignType_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.itemDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.dropbox_[var_2_0] = tonumber(arg_2_0.dropbox)
		arg_1_0.monsterDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display, "|")
		arg_1_0.monsterStar_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star, "|")
		arg_1_0.monsterQuality_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality, "|")
		arg_1_0.monsterLevel_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level, "|")
		arg_1_0.element_[var_2_0] = xyd.splitToNumber(arg_2_0.element, "|")
		arg_1_0.fightId_[var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.lastCampaignId_[var_2_0] = tonumber(arg_2_0.last_campaign_id)

		if arg_1_0.lastCampaignId_[var_2_0] == 0 then
			table.insert(arg_1_0.startPoints_, var_2_0)
		end

		arg_1_0.nextCampaignId_[var_2_0] = xyd.splitToNumber(arg_2_0.next_campaign_id, "|")
		arg_1_0.itemCampaignId_[var_2_0] = tonumber(arg_2_0.item_campaign_id)
		arg_1_0.costType_[var_2_0] = tonumber(arg_2_0.cost_type)
		arg_1_0.winCost_[var_2_0] = tonumber(arg_2_0.win_cost_num)
		arg_1_0.loseCost_[var_2_0] = tonumber(arg_2_0.lose_cost_num)
		arg_1_0.posX_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.posY_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.smallBg_[var_2_0] = arg_2_0.small_bg
		arg_1_0.avatar_[var_2_0] = arg_2_0.avatar
		arg_1_0.preWarStory_[var_2_0] = tonumber(arg_2_0.prewar_story)
		arg_1_0.victoryStory_[var_2_0] = tonumber(arg_2_0.victory_story)
		arg_1_0.firstDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.first_item, "|")
		arg_1_0.firstDisplayNum_[var_2_0] = xyd.splitToNumber(arg_2_0.first_num, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.campaignName(arg_4_0, arg_4_1)
	return arg_4_0.campaignName_[arg_4_1] or ""
end

function var_0_0.campaignDes(arg_5_0, arg_5_1)
	return arg_5_0.campaignDes_[arg_5_1] or ""
end

function var_0_0.campaignType(arg_6_0, arg_6_1)
	return arg_6_0.campaignType_[arg_6_1] or 2
end

function var_0_0.itemDisplay(arg_7_0, arg_7_1)
	return arg_7_0.itemDisplay_[arg_7_1] or {}
end

function var_0_0.dropbox(arg_8_0, arg_8_1)
	return arg_8_0.dropbox_[arg_8_1] or 0
end

function var_0_0.monsterDisplay(arg_9_0, arg_9_1)
	return arg_9_0.monsterDisplay_[arg_9_1] or {}
end

function var_0_0.monsterStar(arg_10_0, arg_10_1)
	return arg_10_0.monsterStar_[arg_10_1] or {}
end

function var_0_0.monsterQuality(arg_11_0, arg_11_1)
	return arg_11_0.monsterQuality_[arg_11_1] or {}
end

function var_0_0.monsterLevel(arg_12_0, arg_12_1)
	return arg_12_0.monsterLevel_[arg_12_1] or {}
end

function var_0_0.element(arg_13_0, arg_13_1)
	return arg_13_0.element_[arg_13_1] or {}
end

function var_0_0.fightId(arg_14_0, arg_14_1)
	return arg_14_0.fightId_[arg_14_1] or 0
end

function var_0_0.dropbox(arg_15_0, arg_15_1)
	return arg_15_0.dropbox_[arg_15_1] or 0
end

function var_0_0.lastCampaignId(arg_16_0, arg_16_1)
	return arg_16_0.lastCampaignId_[arg_16_1] or 0
end

function var_0_0.nextCampaignId(arg_17_0, arg_17_1)
	return arg_17_0.nextCampaignId_[arg_17_1] or {}
end

function var_0_0.itemCampaignId(arg_18_0, arg_18_1)
	return arg_18_0.itemCampaignId_[arg_18_1] or 0
end

function var_0_0.costType(arg_19_0, arg_19_1)
	return arg_19_0.costType_[arg_19_1] or 3
end

function var_0_0.winCost(arg_20_0, arg_20_1)
	return arg_20_0.winCost_[arg_20_1] or 0
end

function var_0_0.loseCost(arg_21_0, arg_21_1)
	return arg_21_0.loseCost_[arg_21_1] or 0
end

function var_0_0.posX(arg_22_0, arg_22_1)
	return arg_22_0.posX_[arg_22_1] or 0
end

function var_0_0.posY(arg_23_0, arg_23_1)
	return arg_23_0.posY_[arg_23_1] or 0
end

function var_0_0.smallBg(arg_24_0, arg_24_1)
	return arg_24_0.smallBg_[arg_24_1] or ""
end

function var_0_0.avatar(arg_25_0, arg_25_1)
	return arg_25_0.avatar_[arg_25_1] or ""
end

function var_0_0.firstDisplay(arg_26_0, arg_26_1)
	return arg_26_0.firstDisplay_[arg_26_1] or {}
end

function var_0_0.preWarStory(arg_27_0, arg_27_1)
	return arg_27_0.preWarStory_[arg_27_1] or 0
end

function var_0_0.victoryStory(arg_28_0, arg_28_1)
	return arg_28_0.victoryStory_[arg_28_1] or 0
end

function var_0_0.startPoints(arg_29_0)
	return arg_29_0.startPoints_ or {}
end

return var_0_0
