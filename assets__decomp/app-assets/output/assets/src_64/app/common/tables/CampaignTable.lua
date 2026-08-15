local var_0_0 = class("CampaignTable")

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
	arg_1_0.monsterDisplays_ = {}
	arg_1_0.monsterStars_ = {}
	arg_1_0.monsterQualitys_ = {}
	arg_1_0.monsterLevels_ = {}
	arg_1_0.selfTeams_ = {}
	arg_1_0.itemDisplays_ = {}
	arg_1_0.relateCampaigns_ = {}
	arg_1_0.teamRelateCampaigns_ = {}
	arg_1_0.icons_ = {}
	arg_1_0.fightID_ = {}
	arg_1_0.gainMana_ = {}
	arg_1_0.openLevByChapter_ = {}
	arg_1_0.minLevInCampaignType_ = {}
	arg_1_0.awakeMissionID_ = {}
	arg_1_0.awakeDropbox_ = {}
	arg_1_0.firstFightID_ = {}
	arg_1_0.awakeTwiceMissionID_ = {}
	arg_1_0.awakeTwiceDropbox_ = {}
	arg_1_0.assistPartner_ = {}
	arg_1_0.storyDropPartner_ = {}
	arg_1_0.lastCampaignID_ = {}
	arg_1_0.nextCampaignID_ = {}
	arg_1_0.rewardIcon_ = {}
	arg_1_0.isBoss_ = {}
	arg_1_0.smallBg_ = {}
	arg_1_0.element_ = {}
	arg_1_0.starGift_ = {}
	arg_1_0.firstDisplay_ = {}
	arg_1_0.firstNumber_ = {}
	arg_1_0.petFloor_ = {}
	arg_1_0.fatigue_ = {}
	arg_1_0.floorType_ = {}

	import("app.common.tables.TableParser").parse("campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.campaignTypes_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.campaignNames_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.campaignDescs_[var_2_0] = arg_2_0.campaign_des
		arg_1_0.chapters_[var_2_0] = tonumber(arg_2_0.chapter)
		arg_1_0.energyCosts_[var_2_0] = tonumber(arg_2_0.energy_cost)
		arg_1_0.openLvs_[var_2_0] = tonumber(arg_2_0.open_lv)
		arg_1_0.trialLvs_[var_2_0] = tonumber(arg_2_0.trial_lv)
		arg_1_0.monsterDisplays_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display, "|")
		arg_1_0.monsterStars_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star, "|")
		arg_1_0.monsterQualitys_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality, "|")
		arg_1_0.element_[var_2_0] = xyd.splitToNumber(arg_2_0.element, "|")
		arg_1_0.monsterLevels_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level, "|")
		arg_1_0.itemDisplays_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.gainMana_[var_2_0] = tonumber(arg_2_0.mana_gain)
		arg_1_0.relateCampaigns_[var_2_0] = tonumber(arg_2_0.relate_campaign_id)
		arg_1_0.teamRelateCampaigns_[var_2_0] = tonumber(arg_2_0.team_relate_id)
		arg_1_0.awakeDropbox_[var_2_0] = xyd.splitToNumber(arg_2_0.awaken_dropbox, "|")
		arg_1_0.awakeMissionID_[var_2_0] = xyd.splitToNumber(arg_2_0.awaken_mission_id, "|")
		arg_1_0.awakeTwiceMissionID_[var_2_0] = xyd.splitToNumber(arg_2_0.bloodline_mission_id, "|")
		arg_1_0.awakeTwiceDropbox_[var_2_0] = xyd.splitToNumber(arg_2_0.bloodline_dropbox, "|")
		arg_1_0.assistPartner_[var_2_0] = xyd.splitToNumber(arg_2_0.assist_partner, "|")
		arg_1_0.storyDropPartner_[var_2_0] = xyd.splitToNumber(arg_2_0.story_drop_partner, "|")
		arg_1_0.lastCampaignID_[var_2_0] = tonumber(arg_2_0.last_campaign_id)
		arg_1_0.nextCampaignID_[var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.rewardIcon_[var_2_0] = arg_2_0.reward_icon
		arg_1_0.isBoss_[var_2_0] = tonumber(arg_2_0.is_boss)
		arg_1_0.smallBg_[var_2_0] = arg_2_0.small_bg
		arg_1_0.selfTeams_[var_2_0] = xyd.splitToNumber(arg_2_0.self_team, "|")
		arg_1_0.xs_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.ys_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.icons_[var_2_0] = arg_2_0.icon
		arg_1_0.fightID_[var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.firstFightID_[var_2_0] = tonumber(arg_2_0.first_fight_id)

		if not arg_1_0.openLevByChapter_[arg_1_0.chapters_[var_2_0]] then
			arg_1_0.openLevByChapter_[arg_1_0.chapters_[var_2_0]] = arg_1_0.openLvs_[var_2_0]
		end

		if not arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] then
			arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] = arg_1_0.openLvs_[var_2_0]
		elseif arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] > arg_1_0.openLvs_[var_2_0] then
			arg_1_0.minLevInCampaignType_[arg_1_0.campaignTypes_[var_2_0]] = arg_1_0.openLvs_[var_2_0]
		end

		arg_1_0.starGift_[var_2_0] = tonumber(arg_2_0.star_gift)
		arg_1_0.firstDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.first_display, "|")
		arg_1_0.firstNumber_[var_2_0] = xyd.splitToNumber(arg_2_0.first_number, "|")
	end)
	import("app.common.tables.TableParser").parse("pet_campaign.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.campaign_id)

		arg_1_0.campaignTypes_[var_3_0] = xyd.CampaignType.PET
		arg_1_0.openLvs_[var_3_0] = tonumber(arg_3_0.open_lv)
		arg_1_0.trialLvs_[var_3_0] = tonumber(arg_3_0.trial_lv)
		arg_1_0.itemDisplays_[var_3_0] = xyd.splitToNumber(arg_3_0.item, "|")
		arg_1_0.gainMana_[var_3_0] = tonumber(arg_3_0.mana_gain)
		arg_1_0.fightID_[var_3_0] = tonumber(arg_3_0.fight_id)
		arg_1_0.petFloor_[var_3_0] = tonumber(arg_3_0.campaign_type)
		arg_1_0.fatigue_[var_3_0] = tonumber(arg_3_0.fatigue)
		arg_1_0.floorType_[var_3_0] = tonumber(arg_3_0.floor_type)
		arg_1_0.icons_[var_3_0] = "images/icon/hero_get_way/7.png"
	end)
end

function var_0_0.getFloorType(arg_4_0, arg_4_1)
	return arg_4_0.floorType_[arg_4_1] or 1
end

function var_0_0.getFloor(arg_5_0, arg_5_1)
	return arg_5_0.petFloor_[arg_5_1] or 1
end

function var_0_0.firstDisplay(arg_6_0, arg_6_1)
	return arg_6_0.firstDisplay_[arg_6_1] or 0
end

function var_0_0.firstNumber(arg_7_0, arg_7_1)
	return arg_7_0.firstNumber_[arg_7_1] or 0
end

function var_0_0.campaignType(arg_8_0, arg_8_1)
	return arg_8_0.campaignTypes_[arg_8_1] or 0
end

function var_0_0.campaignName(arg_9_0, arg_9_1)
	return arg_9_0.campaignNames_[arg_9_1] or ""
end

function var_0_0.campaignDesc(arg_10_0, arg_10_1)
	return arg_10_0.campaignDescs_[arg_10_1] or ""
end

function var_0_0.chapter(arg_11_0, arg_11_1)
	return arg_11_0.chapters_[arg_11_1] or 0
end

function var_0_0.energyCost(arg_12_0, arg_12_1)
	return arg_12_0.energyCosts_[arg_12_1] or 0
end

function var_0_0.monsterDisplay(arg_13_0, arg_13_1)
	return arg_13_0.monsterDisplays_[arg_13_1] or {}
end

function var_0_0.monsterStar(arg_14_0, arg_14_1)
	return arg_14_0.monsterStars_[arg_14_1] or {}
end

function var_0_0.monsterQuality(arg_15_0, arg_15_1)
	return arg_15_0.monsterQualitys_[arg_15_1] or {}
end

function var_0_0.element(arg_16_0, arg_16_1)
	return arg_16_0.element_[arg_16_1] or {}
end

function var_0_0.monsterLevel(arg_17_0, arg_17_1)
	return arg_17_0.monsterLevels_[arg_17_1] or {}
end

function var_0_0.itemDisplay(arg_18_0, arg_18_1)
	return arg_18_0.itemDisplays_[arg_18_1] or {}
end

function var_0_0.monsterStar(arg_19_0, arg_19_1)
	return arg_19_0.monsterStars_[arg_19_1] or {}
end

function var_0_0.x(arg_20_0, arg_20_1)
	return arg_20_0.xs_[arg_20_1] or 0
end

function var_0_0.y(arg_21_0, arg_21_1)
	return arg_21_0.ys_[arg_21_1] or 0
end

function var_0_0.icon(arg_22_0, arg_22_1)
	return arg_22_0.icons_[arg_22_1]
end

function var_0_0.openLv(arg_23_0, arg_23_1)
	return arg_23_0.openLvs_[arg_23_1] or 0
end

function var_0_0.trialLv(arg_24_0, arg_24_1)
	return arg_24_0.trialLvs_[arg_24_1] or 0
end

function var_0_0.fightID(arg_25_0, arg_25_1)
	return arg_25_0.fightID_[arg_25_1] or 0
end

function var_0_0.gainMana(arg_26_0, arg_26_1)
	return arg_26_0.gainMana_[arg_26_1] or 0
end

function var_0_0.relateCampaign(arg_27_0, arg_27_1)
	return arg_27_0.relateCampaigns_[arg_27_1] or 0
end

function var_0_0.teamRelateCampaign(arg_28_0, arg_28_1)
	return arg_28_0.teamRelateCampaigns_[arg_28_1] or 0
end

function var_0_0.openLevByChapter(arg_29_0, arg_29_1)
	return arg_29_0.openLevByChapter_[arg_29_1] or 0
end

function var_0_0.minLevInCampaignType(arg_30_0, arg_30_1)
	return arg_30_0.minLevInCampaignType_[arg_30_1] or 0
end

function var_0_0.awakeDropboxIds(arg_31_0, arg_31_1)
	return arg_31_0.awakeDropbox_[arg_31_1] or {}
end

function var_0_0.awakeMissionIds(arg_32_0, arg_32_1)
	return arg_32_0.awakeMissionID_[arg_32_1] or {}
end

function var_0_0.awakeTwiceMissionIds(arg_33_0, arg_33_1)
	return arg_33_0.awakeTwiceMissionID_[arg_33_1] or {}
end

function var_0_0.awakeTwiceDropboxIds(arg_34_0, arg_34_1)
	return arg_34_0.awakeTwiceDropbox_[arg_34_1] or {}
end

function var_0_0.getFatigue(arg_35_0, arg_35_1)
	return arg_35_0.fatigue_[arg_35_1] or 0
end

function var_0_0.selfTeams(arg_36_0, arg_36_1)
	return arg_36_0.selfTeams_[arg_36_1] or {}
end

function var_0_0.firstFightID(arg_37_0, arg_37_1)
	return arg_37_0.firstFightID_[arg_37_1] or 0
end

function var_0_0.assistPartner(arg_38_0, arg_38_1)
	return arg_38_0.assistPartner_[arg_38_1] or {}
end

function var_0_0.storyDropPartner(arg_39_0, arg_39_1)
	return arg_39_0.storyDropPartner_[arg_39_1] or {}
end

function var_0_0.lastCampaignID(arg_40_0, arg_40_1)
	return arg_40_0.lastCampaignID_[arg_40_1] or 0
end

function var_0_0.nextCampaignID(arg_41_0, arg_41_1)
	return arg_41_0.nextCampaignID_[arg_41_1] or 0
end

function var_0_0.rewardIcon(arg_42_0, arg_42_1)
	return arg_42_0.rewardIcon_[arg_42_1] or ""
end

function var_0_0.isBoss(arg_43_0, arg_43_1)
	return arg_43_0.isBoss_[arg_43_1] or 0
end

function var_0_0.smallBg(arg_44_0, arg_44_1)
	return arg_44_0.smallBg_[arg_44_1] or ""
end

function var_0_0.starGift(arg_45_0, arg_45_1)
	return arg_45_0.starGift_[arg_45_1] or 0
end

return var_0_0
