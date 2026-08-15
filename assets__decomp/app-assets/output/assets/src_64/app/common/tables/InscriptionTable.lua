local var_0_0 = class("InscriptionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemID_ = {}
	arg_1_0.name_ = {}
	arg_1_0.level_ = {}
	arg_1_0.itemType_ = {}
	arg_1_0.addType_ = {}
	arg_1_0.rand_ = {}
	arg_1_0.compoundMaterial_ = {}
	arg_1_0.compoundNum_ = {}
	arg_1_0.compoundItem_ = {}
	arg_1_0.compoundItemNum_ = {}
	arg_1_0.resolveMaterial_ = {}
	arg_1_0.resolveNum_ = {}
	arg_1_0.changeGold_ = {}
	arg_1_0.changeCrystal_ = {}
	arg_1_0.fightingCapacity_ = {}
	arg_1_0.typeToItemIDs_ = {}
	arg_1_0.levelToItemIDs_ = {}
	arg_1_0.itemPos_ = {}
	arg_1_0.suitItems_ = {}
	arg_1_0.inscriptType_ = {}

	import("app.common.tables.TableParser").parse("inscription.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemID_[var_2_0] = xyd.splitToNumber(arg_2_0.item_id, "|")
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.itemType_[var_2_0] = tonumber(arg_2_0.item_type)
		arg_1_0.addType_[var_2_0] = tonumber(arg_2_0.add_type)
		arg_1_0.rand_[var_2_0] = xyd.splitToNumber(arg_2_0.rand, "|")
		arg_1_0.compoundMaterial_[var_2_0] = tonumber(arg_2_0.compound_material)
		arg_1_0.compoundItem_[var_2_0] = tonumber(arg_2_0.compound_item)
		arg_1_0.compoundItemNum_[var_2_0] = tonumber(arg_2_0.compound_item_num)
		arg_1_0.compoundNum_[var_2_0] = tonumber(arg_2_0.compound_num)
		arg_1_0.resolveMaterial_[var_2_0] = tonumber(arg_2_0.resolve_material)
		arg_1_0.resolveNum_[var_2_0] = tonumber(arg_2_0.resolve_num)
		arg_1_0.changeGold_[var_2_0] = tonumber(arg_2_0.change_gold)
		arg_1_0.changeCrystal_[var_2_0] = tonumber(arg_2_0.change_crystal)
		arg_1_0.fightingCapacity_[var_2_0] = tonumber(arg_2_0.fighting_capacity)
		arg_1_0.itemPos_[var_2_0] = tonumber(arg_2_0.item_pos)

		if not arg_1_0.typeToItemIDs_[arg_1_0.itemType_[var_2_0]] then
			arg_1_0.typeToItemIDs_[arg_1_0.itemType_[var_2_0]] = {}
		end

		table.insert(arg_1_0.typeToItemIDs_[arg_1_0.itemType_[var_2_0]], var_2_0)

		if not arg_1_0.levelToItemIDs_[arg_1_0.level_[var_2_0]] then
			arg_1_0.levelToItemIDs_[arg_1_0.level_[var_2_0]] = {}
		end

		table.insert(arg_1_0.levelToItemIDs_[arg_1_0.level_[var_2_0]], var_2_0)
	end)
	import("app.common.tables.TableParser").parse("inscription_pos.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)

		arg_1_0.suitItems_[var_3_0] = xyd.splitToNumber(arg_3_0.suit_items, "|")
		arg_1_0.inscriptType_[var_3_0] = tonumber(arg_3_0.inscript_type)
	end)
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1] or 0
end

function var_0_0.name(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1] or ""
end

function var_0_0.level(arg_6_0, arg_6_1)
	return arg_6_0.level_[arg_6_1] or 0
end

function var_0_0.itemType(arg_7_0, arg_7_1)
	return arg_7_0.itemType_[arg_7_1]
end

function var_0_0.addType(arg_8_0, arg_8_1)
	return arg_8_0.addType_[arg_8_1]
end

function var_0_0.rand(arg_9_0, arg_9_1)
	return arg_9_0.rand_[arg_9_1]
end

function var_0_0.compoundMaterial(arg_10_0, arg_10_1)
	return arg_10_0.compoundMaterial_[arg_10_1]
end

function var_0_0.compoundNum(arg_11_0, arg_11_1)
	return arg_11_0.compoundNum_[arg_11_1]
end

function var_0_0.compoundItem(arg_12_0, arg_12_1)
	return arg_12_0.compoundItem_[arg_12_1]
end

function var_0_0.compoundItemNum(arg_13_0, arg_13_1)
	return arg_13_0.compoundItemNum_[arg_13_1]
end

function var_0_0.resolveMaterial(arg_14_0, arg_14_1)
	return arg_14_0.resolveMaterial_[arg_14_1]
end

function var_0_0.resolveNum(arg_15_0, arg_15_1)
	return arg_15_0.resolveNum_[arg_15_1]
end

function var_0_0.changeGold(arg_16_0, arg_16_1)
	return arg_16_0.changeGold_[arg_16_1]
end

function var_0_0.changeCrystal(arg_17_0, arg_17_1)
	return arg_17_0.changeCrystal_[arg_17_1]
end

function var_0_0.fightingCapacity(arg_18_0, arg_18_1)
	return arg_18_0.fightingCapacity_[arg_18_1]
end

function var_0_0.getItemIDsBaseOnType(arg_19_0, arg_19_1)
	return arg_19_0.typeToItemIDs_[arg_19_1] or {}
end

function var_0_0.getItemIDsBaseOnLevel(arg_20_0, arg_20_1)
	return arg_20_0.levelToItemIDs_[arg_20_1] or {}
end

function var_0_0.getItemIDsBaseOnTypeAndLevel(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_0.typeToItemIDs_[arg_21_1]
	local var_21_1 = {}

	for iter_21_0 = 1, #var_21_0 do
		if arg_21_0:level(var_21_0[iter_21_0]) == arg_21_2 then
			table.insert(var_21_1, var_21_0[iter_21_0])
		end
	end

	return var_21_1
end

function var_0_0.getItemPos(arg_22_0, arg_22_1, arg_22_2)
	if arg_22_1 and arg_22_0.itemPos_[arg_22_1] ~= 0 then
		return arg_22_0.itemPos_[arg_22_1]
	elseif not arg_22_2 then
		return 0
	else
		for iter_22_0, iter_22_1 in pairs(arg_22_0.suitItems_) do
			for iter_22_2, iter_22_3 in ipairs(iter_22_1) do
				if iter_22_3 == arg_22_2 then
					return arg_22_0.inscriptType_[iter_22_0]
				end
			end
		end
	end
end

function var_0_0.getItemsByPosAndLevel(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = {}

	for iter_23_0, iter_23_1 in pairs(arg_23_0.itemPos_) do
		if iter_23_1 ~= 0 and iter_23_1 == arg_23_1 and arg_23_0:level(iter_23_0) == arg_23_2 then
			for iter_23_2, iter_23_3 in pairs(arg_23_0:itemID(iter_23_0)) do
				table.insert(var_23_0, iter_23_3)
			end
		end

		if iter_23_1 == 0 and arg_23_2 >= 7 then
			for iter_23_4, iter_23_5 in pairs(arg_23_0:itemID(iter_23_0)) do
				if arg_23_0:getItemPos(iter_23_0, iter_23_5) == arg_23_1 then
					table.insert(var_23_0, iter_23_5)
				end
			end
		end
	end

	return var_23_0
end

return var_0_0
