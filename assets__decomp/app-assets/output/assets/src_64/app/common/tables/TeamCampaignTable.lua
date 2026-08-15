local var_0_0 = class("TeamCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.xs_ = {}
	arg_1_0.ys_ = {}
	arg_1_0.campaignTypes_ = {}
	arg_1_0.campaignNames_ = {}
	arg_1_0.campaignDescs_ = {}
	arg_1_0.chapters_ = {}
	arg_1_0.openLvs_ = {}
	arg_1_0.trialLvs_ = {}
	arg_1_0.energyCosts_ = {}
	arg_1_0.itemDisplays_ = {}
	arg_1_0.relateCampaigns_ = {}
	arg_1_0.icons_ = {}
	arg_1_0.fightID_ = {}
	arg_1_0.gainMana_ = {}
	arg_1_0.openLevByChapter_ = {}
	arg_1_0.minLevInCampaignType_ = {}
	arg_1_0.defeatCost_ = {}
	arg_1_0.throughCost_ = {}
	arg_1_0.monsterDisplay1_ = {}
	arg_1_0.monsterStar1_ = {}
	arg_1_0.monsterQualitys1_ = {}
	arg_1_0.monsterLevels1_ = {}
	arg_1_0.monsterDisplay2_ = {}
	arg_1_0.monsterStar2_ = {}
	arg_1_0.monsterQualitys2_ = {}
	arg_1_0.monsterLevels2_ = {}
	arg_1_0.monsterDisplay3_ = {}
	arg_1_0.monsterStar3_ = {}
	arg_1_0.monsterQualitys3_ = {}
	arg_1_0.monsterLevels3_ = {}
	arg_1_0.dropbox_ = {}
	arg_1_0.teamDropbox_ = {}
	arg_1_0.additionalDropbox_ = {}
	arg_1_0.lastCampaignID_ = {}
	arg_1_0.relateCampaignID_ = {}
	arg_1_0.nextCampaignID_ = {}
	arg_1_0.smallBg_ = {}

	import("app.common.tables.TableParser").parse("team_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.campaignTypes_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.campaignNames_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.campaignDescs_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.chapters_[var_2_0] = tonumber(arg_2_0.chapter)
		arg_1_0.energyCosts_[var_2_0] = tonumber(arg_2_0.energy_cost)
		arg_1_0.openLvs_[var_2_0] = tonumber(arg_2_0.open_lv)
		arg_1_0.trialLvs_[var_2_0] = tonumber(arg_2_0.trial_lv)
		arg_1_0.itemDisplays_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.gainMana_[var_2_0] = tonumber(arg_2_0.mana_gain)
		arg_1_0.relateCampaigns_[var_2_0] = tonumber(arg_2_0.relate_campaign_id)
		arg_1_0.defeatCost_[var_2_0] = tonumber(arg_2_0.defeat_cost)
		arg_1_0.throughCost_[var_2_0] = tonumber(arg_2_0.through_cost)
		arg_1_0.monsterDisplay1_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display_1, "|")
		arg_1_0.monsterStar1_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star_1, "|")
		arg_1_0.monsterQualitys1_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality_1, "|")
		arg_1_0.monsterLevels1_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level_1, "|")
		arg_1_0.monsterDisplay2_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display_2, "|")
		arg_1_0.monsterStar2_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star_2, "|")
		arg_1_0.monsterQualitys2_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality_2, "|")
		arg_1_0.monsterLevels2_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level_2, "|")
		arg_1_0.monsterDisplay3_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display_3, "|")
		arg_1_0.monsterStar3_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star_3, "|")
		arg_1_0.monsterQualitys3_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality_3, "|")
		arg_1_0.monsterLevels3_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level_3, "|")
		arg_1_0.dropbox_[var_2_0] = xyd.splitToNumber(arg_2_0.dropbox, "|")
		arg_1_0.teamDropbox_[var_2_0] = xyd.splitToNumber(arg_2_0.team_dropbox, "|")
		arg_1_0.additionalDropbox_[var_2_0] = xyd.splitToNumber(arg_2_0.additional_dropbox, "|")
		arg_1_0.lastCampaignID_[var_2_0] = tonumber(arg_2_0.last_campaign_id)
		arg_1_0.relateCampaignID_[var_2_0] = tonumber(arg_2_0.relate_campaign_id)
		arg_1_0.nextCampaignID_[var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.smallBg_[var_2_0] = arg_2_0.small_bg
		arg_1_0.xs_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.ys_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.icons_[var_2_0] = arg_2_0.icon
		arg_1_0.fightID_[var_2_0] = tonumber(arg_2_0.fight_id)

		if not arg_1_0.openLevByChapter_[arg_1_0.chapters_[var_2_0]] then
			arg_1_0.openLevByChapter_[arg_1_0.chapters_[var_2_0]] = arg_1_0.openLvs_[var_2_0]
		end

		if not arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] then
			arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] = arg_1_0.openLvs_[var_2_0]
		elseif arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] > arg_1_0.openLvs_[var_2_0] then
			arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] = arg_1_0.openLvs_[var_2_0]
		end
	end)
end

function var_0_0.campaignType(arg_3_0, arg_3_1)
	return arg_3_0.campaignTypes_[arg_3_1] or 0
end

function var_0_0.campaignName(arg_4_0, arg_4_1)
	return arg_4_0.campaignNames_[arg_4_1] or ""
end

function var_0_0.campaignDesc(arg_5_0, arg_5_1)
	return arg_5_0.campaignDescs_[arg_5_1] or ""
end

function var_0_0.chapter(arg_6_0, arg_6_1)
	return arg_6_0.chapters_[arg_6_1] or 0
end

function var_0_0.energyCost(arg_7_0, arg_7_1)
	return arg_7_0.energyCosts_[arg_7_1] or 0
end

function var_0_0.itemDisplay(arg_8_0, arg_8_1)
	return {}
end

function var_0_0.x(arg_9_0, arg_9_1)
	return arg_9_0.xs_[arg_9_1] or 0
end

function var_0_0.y(arg_10_0, arg_10_1)
	return arg_10_0.ys_[arg_10_1] or 0
end

function var_0_0.icon(arg_11_0, arg_11_1)
	return arg_11_0.icons_[arg_11_1]
end

function var_0_0.openLv(arg_12_0, arg_12_1)
	return arg_12_0.openLvs_[arg_12_1] or 0
end

function var_0_0.trialLv(arg_13_0, arg_13_1)
	return arg_13_0.trialLvs_[arg_13_1] or 0
end

function var_0_0.fightID(arg_14_0, arg_14_1)
	return arg_14_0.fightID_[arg_14_1] or 0
end

function var_0_0.gainMana(arg_15_0, arg_15_1)
	return arg_15_0.gainMana_[arg_15_1] or 0
end

function var_0_0.relateCampaign(arg_16_0, arg_16_1)
	return arg_16_0.relateCampaigns_[arg_16_1] or 0
end

function var_0_0.openLevByChapter(arg_17_0, arg_17_1)
	return arg_17_0.openLevByChapter_[arg_17_1] or 0
end

function var_0_0.minLevInCampaignType(arg_18_0, arg_18_1)
	return arg_18_0.minLevInCampaignType_[arg_18_1] or 0
end

function var_0_0.lastCampaignID(arg_19_0, arg_19_1)
	return arg_19_0.lastCampaignID_[arg_19_1] or 0
end

function var_0_0.nextCampaignID(arg_20_0, arg_20_1)
	return arg_20_0.nextCampaignID_[arg_20_1] or 0
end

function var_0_0.monsterDisplay1(arg_21_0, arg_21_1)
	return arg_21_0.monsterDisplay1_[arg_21_1] or {}
end

function var_0_0.monsterStar1(arg_22_0, arg_22_1)
	return arg_22_0.monsterStar1_[arg_22_1] or {}
end

function var_0_0.monsterQualitys1(arg_23_0, arg_23_1)
	return arg_23_0.monsterQualitys1_[arg_23_1] or {}
end

function var_0_0.monsterLevels1(arg_24_0, arg_24_1)
	return arg_24_0.monsterLevels1_[arg_24_1] or {}
end

function var_0_0.monsterDisplay2(arg_25_0, arg_25_1)
	return arg_25_0.monsterDisplay2_[arg_25_1] or {}
end

function var_0_0.monsterStar2(arg_26_0, arg_26_1)
	return arg_26_0.monsterStar2_[arg_26_1] or {}
end

function var_0_0.monsterQualitys2(arg_27_0, arg_27_1)
	return arg_27_0.monsterQualitys2_[arg_27_1] or {}
end

function var_0_0.monsterLevels2(arg_28_0, arg_28_1)
	return arg_28_0.monsterLevels2_[arg_28_1] or {}
end

function var_0_0.monsterDisplay3(arg_29_0, arg_29_1)
	return arg_29_0.monsterDisplay3_[arg_29_1] or {}
end

function var_0_0.monsterStar3(arg_30_0, arg_30_1)
	return arg_30_0.monsterStar3_[arg_30_1] or {}
end

function var_0_0.monsterQualitys3(arg_31_0, arg_31_1)
	return arg_31_0.monsterQualitys3_[arg_31_1] or {}
end

function var_0_0.monsterLevels3(arg_32_0, arg_32_1)
	return arg_32_0.monsterLevels3_[arg_32_1] or {}
end

function var_0_0.smallBg(arg_33_0, arg_33_1)
	return arg_33_0.smallBg_[arg_33_1] or ""
end

return var_0_0
