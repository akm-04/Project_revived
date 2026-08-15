local var_0_0 = class("ActivityTutorCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.campaignName_ = {}
	arg_1_0.itemDisplay_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.monsterDisplay_ = {}
	arg_1_0.monsterStar_ = {}
	arg_1_0.monsterQuality_ = {}
	arg_1_0.monsterLevel_ = {}
	arg_1_0.fightId_ = {}
	arg_1_0.hardFightId_ = {}
	arg_1_0.challengeTimes_ = {}
	arg_1_0.canRentFunc_ = {}
	arg_1_0.rentFuncDesc_ = {}
	arg_1_0.campaignDisplay_ = {}
	arg_1_0.campaignBackground_ = {}
	arg_1_0.campaignText_ = {}

	import("app.common.tables.TableParser").parse("activity_tutor_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		arg_1_0.campaignName_[var_2_0] = arg_2_0.campaign_name
		arg_1_0.itemDisplay_[var_2_0] = tonumber(arg_2_0.item_display)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.monsterDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display, "|")
		arg_1_0.monsterStar_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star, "|")
		arg_1_0.monsterQuality_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality, "|")
		arg_1_0.monsterLevel_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level, "|")
		arg_1_0.fightId_[var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.hardFightId_[var_2_0] = tonumber(arg_2_0.hard_fight_id)
		arg_1_0.challengeTimes_[var_2_0] = tonumber(arg_2_0.challenge_times)
		arg_1_0.canRentFunc_[var_2_0] = tonumber(arg_2_0.can_rent_func)
		arg_1_0.rentFuncDesc_[var_2_0] = arg_2_0.rent_func_desc
		arg_1_0.campaignDisplay_[var_2_0] = tonumber(arg_2_0.campaign_display)
		arg_1_0.campaignBackground_[var_2_0] = arg_2_0.campaign_background
		arg_1_0.campaignText_[var_2_0] = arg_2_0.campaign_text
	end)
end

function var_0_0.campaignText(arg_3_0, arg_3_1)
	return arg_3_0.campaignText_[arg_3_1] or ""
end

function var_0_0.campaignName(arg_4_0, arg_4_1)
	return arg_4_0.campaignName_[arg_4_1] or ""
end

function var_0_0.itemDisplay(arg_5_0, arg_5_1)
	return arg_5_0.itemDisplay_[arg_5_1] or 0
end

function var_0_0.giftId(arg_6_0, arg_6_1)
	return arg_6_0.giftId_[arg_6_1] or 0
end

function var_0_0.monsterDisplay(arg_7_0, arg_7_1)
	return arg_7_0.monsterDisplay_[arg_7_1] or {}
end

function var_0_0.monsterStar(arg_8_0, arg_8_1)
	return arg_8_0.monsterStar_[arg_8_1] or {}
end

function var_0_0.monsterQuality(arg_9_0, arg_9_1)
	return arg_9_0.monsterQuality_[arg_9_1] or {}
end

function var_0_0.monsterLevel(arg_10_0, arg_10_1)
	return arg_10_0.monsterLevel_[arg_10_1] or {}
end

function var_0_0.fightId(arg_11_0, arg_11_1, arg_11_2)
	if xyd.TutorMode.NORMAL == arg_11_2 then
		return arg_11_0.fightId_[arg_11_1] or 0
	elseif xyd.TutorMode.HARD == arg_11_2 then
		return arg_11_0.hardFightId_[arg_11_1] or 0
	end
end

function var_0_0.challengeTimes(arg_12_0, arg_12_1)
	return arg_12_0.challengeTimes_[arg_12_1] or 0
end

function var_0_0.canRentFunc(arg_13_0, arg_13_1)
	return arg_13_0.canRentFunc_[arg_13_1] or 0
end

function var_0_0.rentFuncDesc(arg_14_0, arg_14_1)
	return arg_14_0.rentFuncDesc_[arg_14_1] or ""
end

function var_0_0.campaignDisplay(arg_15_0, arg_15_1)
	return arg_15_0.campaignDisplay_[arg_15_1] or 0
end

function var_0_0.campaignBackground(arg_16_0, arg_16_1)
	return arg_16_0.campaignBackground_[arg_16_1] or ""
end

return var_0_0
