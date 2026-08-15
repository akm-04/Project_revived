local var_0_0 = class("RegionArenaAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.level = {}
	arg_1_0.regionCoin = {}
	arg_1_0.regionMana = {}
	arg_1_0.regionItem = {}
	arg_1_0.regionItemNum = {}
	arg_1_0.ids = {}

	import("app.common.tables.TableParser").parse("region_arena_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids, var_2_0)

		arg_1_0.level[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.regionCoin[var_2_0] = tonumber(arg_2_0.region_arena_coin)
		arg_1_0.regionMana[var_2_0] = tonumber(arg_2_0.season_mana)
		arg_1_0.regionItem[var_2_0] = xyd.splitToNumber(arg_2_0.daily_item, "|")
		arg_1_0.regionItemNum[var_2_0] = xyd.splitToNumber(arg_2_0.daily_item_num, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids or {}
end

function var_0_0.getLevel(arg_4_0, arg_4_1)
	return arg_4_0.level[arg_4_1] or 0
end

function var_0_0.getRegionCoin(arg_5_0, arg_5_1)
	return arg_5_0.regionCoin[arg_5_1] or 0
end

function var_0_0.getRegionMana(arg_6_0, arg_6_1)
	return arg_6_0.regionMana[arg_6_1] or 0
end

function var_0_0.getRegionItem(arg_7_0, arg_7_1)
	return arg_7_0.regionItem[arg_7_1] or {}
end

function var_0_0.getRegionItemNum(arg_8_0, arg_8_1)
	return arg_8_0.regionItemNum[arg_8_1] or {}
end

return var_0_0
