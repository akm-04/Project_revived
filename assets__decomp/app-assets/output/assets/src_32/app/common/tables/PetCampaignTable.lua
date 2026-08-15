local var_0_0 = class("PetCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0:makeArr("campaign_id_")
	arg_1_0:makeArr("monster_display_")
	arg_1_0:makeArr("fight_id_")
	arg_1_0:makeArr("mana_gain_")
	arg_1_0:makeArr("last_campaign_")
	arg_1_0:makeArr("next_campaign_")
	arg_1_0:makeArr("campaign_map_")
	arg_1_0:makeArr("item_display_")
	arg_1_0:makeArr("item_num_")
	arg_1_0:makeArr("monsterStars_")
	arg_1_0:makeArr("monsterQualitys_")
	arg_1_0:makeArr("monsterLevels_")
	arg_1_0:makeArr("first_drop_")
	arg_1_0:makeArr("first_drop_num_")
	arg_1_0:makeArr("vip6_first_drop_num_")
	arg_1_0:makeArr("vip6_item_num_")

	arg_1_0.to_floor_item = {}

	local var_1_0 = {}

	import("app.common.tables.TableParser").parse("pet_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_type)
		local var_2_1 = tonumber(arg_2_0.floor_type)

		arg_1_0.campaign_id_[var_2_1][var_2_0] = tonumber(arg_2_0.campaign_id)
		arg_1_0.monster_display_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.monster_display, "|")
		arg_1_0.fight_id_[var_2_1][var_2_0] = tonumber(arg_2_0.fight_id)
		arg_1_0.mana_gain_[var_2_1][var_2_0] = tonumber(arg_2_0.mana_gain)
		arg_1_0.last_campaign_[var_2_1][var_2_0] = tonumber(arg_2_0.last_campaign_id)
		arg_1_0.next_campaign_[var_2_1][var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.campaign_map_[var_2_1][var_2_0] = arg_2_0.campaign_map
		arg_1_0.item_display_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.item, "|")
		arg_1_0.item_num_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.item_num, "|")
		arg_1_0.vip6_item_num_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.vip6_item_num, "|")
		arg_1_0.monsterStars_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.monster_star, "|")
		arg_1_0.monsterQualitys_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality, "|")
		arg_1_0.monsterLevels_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.monster_level, "|")
		arg_1_0.first_drop_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.first_drop, "|")
		arg_1_0.first_drop_num_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.first_drop_num, "|")
		arg_1_0.vip6_first_drop_num_[var_2_1][var_2_0] = xyd.splitToNumber(arg_2_0.vip6_first_drop_num, "|")

		if var_2_1 == xyd.PetCampaignFloorType.NORMAL then
			for iter_2_0, iter_2_1 in pairs(arg_1_0.item_display_[var_2_1][var_2_0]) do
				local var_2_2 = true

				for iter_2_2, iter_2_3 in ipairs(var_1_0) do
					if iter_2_3.table_id == iter_2_1 then
						var_2_2 = false
						iter_2_3.item_num = iter_2_3.item_num + arg_1_0.item_num_[var_2_1][var_2_0][iter_2_0]

						break
					end
				end

				if var_2_2 == true then
					local var_2_3 = {
						table_id = iter_2_1,
						item_num = arg_1_0.item_num_[var_2_1][var_2_0][iter_2_0]
					}

					table.insert(var_1_0, var_2_3)
				end
			end

			arg_1_0.to_floor_item[var_2_0] = clone(var_1_0)
		end
	end)
end

function var_0_0.makeArr(arg_3_0, arg_3_1)
	arg_3_0[arg_3_1] = {}
	arg_3_0[arg_3_1][xyd.PetCampaignFloorType.NORMAL] = {}
	arg_3_0[arg_3_1][xyd.PetCampaignFloorType.SUPER] = {}
end

function var_0_0.getFloorItems(arg_4_0, arg_4_1)
	if arg_4_0.to_floor_item[arg_4_1] ~= nil then
		table.sort(arg_4_0.to_floor_item[arg_4_1], function(arg_5_0, arg_5_1)
			return arg_5_0.item_num > arg_5_1.item_num
		end)

		return arg_4_0.to_floor_item[arg_4_1]
	else
		return {}
	end
end

function var_0_0.getFirstDrop(arg_6_0, arg_6_1, arg_6_2)
	return arg_6_0.first_drop_[arg_6_1][arg_6_2] or {}
end

function var_0_0.getFirstDropNum(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if not arg_7_3 then
		return arg_7_0.first_drop_num_[arg_7_1][arg_7_2] or {}
	else
		return arg_7_0.vip6_first_drop_num_[arg_7_1][arg_7_2] or {}
	end
end

function var_0_0.getCampaignId(arg_8_0, arg_8_1, arg_8_2)
	return arg_8_0.campaign_id_[arg_8_1][arg_8_2] or 0
end

function var_0_0.getItem(arg_9_0, arg_9_1, arg_9_2)
	return arg_9_0.item_display_[arg_9_1][arg_9_2] or {}
end

function var_0_0.getItemNum(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if not arg_10_3 then
		return arg_10_0.item_num_[arg_10_1][arg_10_2] or {}
	else
		return arg_10_0.vip6_item_num_[arg_10_1][arg_10_2] or {}
	end
end

function var_0_0.getMonster(arg_11_0, arg_11_1, arg_11_2)
	return arg_11_0.monster_display_[arg_11_1][arg_11_2] or {}
end

function var_0_0.monsterStar(arg_12_0, arg_12_1, arg_12_2)
	return arg_12_0.monsterStars_[arg_12_1][arg_12_2] or {}
end

function var_0_0.monsterQuality(arg_13_0, arg_13_1, arg_13_2)
	return arg_13_0.monsterQualitys_[arg_13_1][arg_13_2] or {}
end

function var_0_0.monsterLevel(arg_14_0, arg_14_1, arg_14_2)
	return arg_14_0.monsterLevels_[arg_14_1][arg_14_2] or {}
end

function var_0_0.getFightId(arg_15_0, arg_15_1, arg_15_2)
	return arg_15_0.fight_id_[arg_15_1][arg_15_2] or 0
end

function var_0_0.getManaGain(arg_16_0, arg_16_1, arg_16_2)
	return arg_16_0.mana_gain_[arg_16_1][arg_16_2] or 0
end

function var_0_0.getLastCampaign(arg_17_0, arg_17_1, arg_17_2)
	return arg_17_0.last_campaign_[arg_17_1][arg_17_2] or 0
end

function var_0_0.getNextCampaign(arg_18_0, arg_18_1, arg_18_2)
	return arg_18_0.next_campaign_[arg_18_1][arg_18_2] or 0
end

function var_0_0.getMap(arg_19_0, arg_19_1, arg_19_2)
	return arg_19_0.campaign_map_[arg_19_1][arg_19_2] or ""
end

function var_0_0.getSweepTime(arg_20_0, arg_20_1, arg_20_2)
	return (arg_20_2 - arg_20_1) * xyd.tables.misc.petSweepLayerTime
end

function var_0_0.getMaxLimitFloor(arg_21_0, arg_21_1)
	return #arg_21_0.campaign_id_[arg_21_1]
end

return var_0_0
