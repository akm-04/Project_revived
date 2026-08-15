local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = class("ConquerSchoolCampaignTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.lev_ = {}
	arg_1_0.region_ = {}
	arg_1_0.regions_ = {}
	arg_1_0.nextID_ = {}
	arg_1_0.name_ = {}
	arg_1_0.rewardItem_ = {}
	arg_1_0.rewardItemNum_ = {}
	arg_1_0.teams_ = {}
	arg_1_0.fightIDs_ = {}
	arg_1_0.buffID_ = {}
	arg_1_0.campaignMap_ = {}
	arg_1_0.isOpen_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("conquer_school_campaign.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("conquer_school_campaign", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.ids_[var_2_0] = var_2_0
	arg_2_0.lev_[var_2_0] = tonumber(arg_2_1.lev)
	arg_2_0.region_[var_2_0] = tonumber(arg_2_1.region)
	arg_2_0.nextID_[var_2_0] = tonumber(arg_2_1.next_id)
	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.rewardItem_[var_2_0] = tonumber(arg_2_1.reward_item)
	arg_2_0.rewardItemNum_[var_2_0] = tonumber(arg_2_1.reward_item_num)
	arg_2_0.isOpen_[var_2_0] = tonumber(arg_2_1.is_open)
	arg_2_0.teams_[var_2_0] = {}
	arg_2_0.teams_[var_2_0][var_0_1.ConquerSchoolBattle.FIRST_TEAM] = var_0_1.splitToNumber(arg_2_1.team1, "|")
	arg_2_0.teams_[var_2_0][var_0_1.ConquerSchoolBattle.SECOND_TEAM] = var_0_1.splitToNumber(arg_2_1.team2, "|")
	arg_2_0.teams_[var_2_0][var_0_1.ConquerSchoolBattle.THIRD_TEAM] = var_0_1.splitToNumber(arg_2_1.team3, "|")
	arg_2_0.teams_[var_2_0][var_0_1.ConquerSchoolBattle.FOUR_TEAM] = var_0_1.splitToNumber(arg_2_1.team4, "|")
	arg_2_0.teams_[var_2_0][var_0_1.ConquerSchoolBattle.FIVE_TEAM] = var_0_1.splitToNumber(arg_2_1.team5, "|")
	arg_2_0.fightIDs_[var_2_0] = {}
	arg_2_0.fightIDs_[var_2_0][var_0_1.ConquerSchoolBattle.FIRST_TEAM] = tonumber(arg_2_1.fight_id1)
	arg_2_0.fightIDs_[var_2_0][var_0_1.ConquerSchoolBattle.SECOND_TEAM] = tonumber(arg_2_1.fight_id2)
	arg_2_0.fightIDs_[var_2_0][var_0_1.ConquerSchoolBattle.THIRD_TEAM] = tonumber(arg_2_1.fight_id3)
	arg_2_0.fightIDs_[var_2_0][var_0_1.ConquerSchoolBattle.FOUR_TEAM] = tonumber(arg_2_1.fight_id4)
	arg_2_0.fightIDs_[var_2_0][var_0_1.ConquerSchoolBattle.FIVE_TEAM] = tonumber(arg_2_1.fight_id5)
	arg_2_0.buffID_[var_2_0] = tonumber(arg_2_1.buff_id)
	arg_2_0.campaignMap_[var_2_0] = arg_2_1.campaign_map
	arg_2_0.regions_[tonumber(arg_2_1.region)] = {}

	table.insert(arg_2_0.regions_[tonumber(arg_2_1.region)], tonumber(arg_2_1.lev))
end

function var_0_2.maxLev(arg_3_0)
	local var_3_0 = 0

	for iter_3_0, iter_3_1 in pairs(arg_3_0.ids_) do
		var_3_0 = var_3_0 + 1
	end

	return var_3_0
end

function var_0_2.lev(arg_4_0, arg_4_1)
	return arg_4_0.lev_[arg_4_1] or 0
end

function var_0_2.region(arg_5_0, arg_5_1)
	return arg_5_0.region_[arg_5_1] or 0
end

function var_0_2.nextID(arg_6_0, arg_6_1)
	return arg_6_0.nextID_[arg_6_1] or 0
end

function var_0_2.getRegionByLev(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = 0

	if arg_7_2 and arg_7_2 > 1 then
		for iter_7_0, iter_7_1 in pairs(arg_7_0.ids_) do
			if var_7_0 < arg_7_0:region(iter_7_1) then
				var_7_0 = arg_7_0:region(iter_7_1)
			end
		end
	else
		for iter_7_2, iter_7_3 in pairs(arg_7_0.ids_) do
			if arg_7_0:lev(iter_7_3) == arg_7_1 then
				return arg_7_0:region(iter_7_3)
			end
		end
	end

	return var_7_0
end

function var_0_2.checkAttrOpen(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if not arg_8_1 or arg_8_1 <= 0 or not arg_8_2 or arg_8_2 <= 0 then
		return false
	end

	if arg_8_3 and arg_8_3 > 1 then
		return true
	end

	local var_8_0 = arg_8_0:getRegionByLev(arg_8_2, arg_8_3)

	if var_8_0 < arg_8_1 then
		return false
	elseif arg_8_1 < var_8_0 then
		return true
	elseif arg_8_0.regions_[arg_8_1][#arg_8_0.regions_[arg_8_1]] == arg_8_2 then
		return true
	end

	return false
end

function var_0_2.name(arg_9_0, arg_9_1)
	return arg_9_0.name_[arg_9_1] or ""
end

function var_0_2.isOpen(arg_10_0, arg_10_1)
	return arg_10_0.isOpen_[arg_10_1] or 0
end

function var_0_2.rewardItem(arg_11_0, arg_11_1)
	return arg_11_0.rewardItem_[arg_11_1] or 0
end

function var_0_2.rewardItemNum(arg_12_0, arg_12_1)
	return arg_12_0.rewardItemNum_[arg_12_1] or 0
end

function var_0_2.teams(arg_13_0, arg_13_1)
	return arg_13_0.teams_[arg_13_1] or {}
end

function var_0_2.fightIDs(arg_14_0, arg_14_1)
	return arg_14_0.fightIDs_[arg_14_1] or {}
end

function var_0_2.buffID(arg_15_0, arg_15_1)
	return arg_15_0.buffID_[arg_15_1] or 0
end

function var_0_2.campaignMap(arg_16_0, arg_16_1)
	return arg_16_0.campaignMap_[arg_16_1] or ""
end

return var_0_2
