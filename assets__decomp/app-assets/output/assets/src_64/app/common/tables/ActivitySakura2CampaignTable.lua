local var_0_0 = class("ActivitySakura2CampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.campaignName_ = {}
	arg_1_0.campaignDes_ = {}
	arg_1_0.avatar_ = {}
	arg_1_0.monsterDisplay_ = {}
	arg_1_0.fightId_ = {}
	arg_1_0.itemDisplay_ = {}
	arg_1_0.dropbox_ = {}
	arg_1_0.lastCampaignId_ = {}
	arg_1_0.nextCampaignId_ = {}
	arg_1_0.preWarStory_ = {}
	arg_1_0.victoryStory_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura2_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, 1, var_2_0)

		arg_1_0.campaignName_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.campaignDes_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.avatar_[var_2_0] = tonumber(arg_2_0.avatar)
		arg_1_0.monsterDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display, "|")
		arg_1_0.fightId_[var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.itemDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.dropbox_[var_2_0] = tonumber(arg_2_0.dropbox)
		arg_1_0.lastCampaignId_[var_2_0] = tonumber(arg_2_0.last_campaign_id)
		arg_1_0.nextCampaignId_[var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.preWarStory_[var_2_0] = arg_2_0.prewar_story
		arg_1_0.victoryStory_[var_2_0] = arg_2_0.victory_story
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

function var_0_0.avatar(arg_6_0, arg_6_1)
	return arg_6_0.avatar_[arg_6_1] or 0
end

function var_0_0.monsterDisplay(arg_7_0, arg_7_1)
	return arg_7_0.monsterDisplay_[arg_7_1] or {}
end

function var_0_0.fightId(arg_8_0, arg_8_1)
	return arg_8_0.fightId_[arg_8_1] or 0
end

function var_0_0.itemDisplay(arg_9_0, arg_9_1)
	return arg_9_0.itemDisplay_[arg_9_1] or {}
end

function var_0_0.dropbox(arg_10_0, arg_10_1)
	return arg_10_0.dropbox_[arg_10_1] or 0
end

function var_0_0.lastCampaignId(arg_11_0, arg_11_1)
	return arg_11_0.lastCampaignId_[arg_11_1] or 0
end

function var_0_0.nextCampaignId(arg_12_0, arg_12_1)
	return arg_12_0.nextCampaignId_[arg_12_1] or 0
end

function var_0_0.preWarStory(arg_13_0, arg_13_1)
	return arg_13_0.preWarStory_[arg_13_1] or ""
end

function var_0_0.victoryStory(arg_14_0, arg_14_1)
	return arg_14_0.victoryStory_[arg_14_1] or ""
end

return var_0_0
