local var_0_0 = class("ActivityGacha2CollectionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemID_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.rarity_ = {}
	arg_1_0.rarityById_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_gacha2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.rarity_[var_2_0] = tonumber(arg_2_0.rarity)
		arg_1_0.rarityById_[arg_1_0.itemID_[var_2_0]] = arg_1_0.rarity_[var_2_0]
	end)
end

function var_0_0.itemID(arg_3_0, arg_3_1)
	return arg_3_0.itemID_[arg_3_1] or 0
end

function var_0_0.itemNum(arg_4_0, arg_4_1)
	return arg_4_0.itemNum_[arg_4_1] or 0
end

function var_0_0.rarity(arg_5_0, arg_5_1)
	return arg_5_0.rarity_[arg_5_1] or 0
end

function var_0_0.size(arg_6_0, arg_6_1)
	return #arg_6_0.itemID_ or 0
end

function var_0_0.rarityById(arg_7_0, arg_7_1)
	return arg_7_0.rarityById_[arg_7_1] or 0
end

return var_0_0
