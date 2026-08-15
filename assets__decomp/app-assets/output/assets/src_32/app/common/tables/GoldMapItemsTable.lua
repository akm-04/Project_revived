local var_0_0 = class("GoldMapItemsTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ID_ = {}
	arg_1_0.level_ = {}

	for iter_1_0 = 1, 10 do
		arg_1_0.level_[iter_1_0] = {}
	end

	import("app.common.tables.TableParser").parse("gold_map_items.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.level_[1][var_2_0] = xyd.splitToNumber(arg_2_0.level_1, "|")
		arg_1_0.level_[2][var_2_0] = xyd.splitToNumber(arg_2_0.level_2, "|")
		arg_1_0.level_[3][var_2_0] = xyd.splitToNumber(arg_2_0.level_3, "|")
		arg_1_0.level_[4][var_2_0] = xyd.splitToNumber(arg_2_0.level_4, "|")
		arg_1_0.level_[5][var_2_0] = xyd.splitToNumber(arg_2_0.level_5, "|")
		arg_1_0.level_[6][var_2_0] = xyd.splitToNumber(arg_2_0.level_6, "|")
		arg_1_0.level_[7][var_2_0] = xyd.splitToNumber(arg_2_0.level_7, "|")
		arg_1_0.level_[8][var_2_0] = xyd.splitToNumber(arg_2_0.level_8, "|")
		arg_1_0.level_[9][var_2_0] = xyd.splitToNumber(arg_2_0.level_9, "|")
		arg_1_0.level_[10][var_2_0] = xyd.splitToNumber(arg_2_0.level_10, "|")
	end)
end

function var_0_0.ID(arg_3_0, arg_3_1)
	return arg_3_0.ID_[arg_3_1] or 0
end

function var_0_0.level(arg_4_0)
	return arg_4_0.level_ or {}
end

function var_0_0.level1(arg_5_0, arg_5_1)
	return arg_5_0.level_[1][arg_5_1] or {}
end

function var_0_0.level2(arg_6_0, arg_6_1)
	return arg_6_0.level_[2][arg_6_1] or {}
end

function var_0_0.level3(arg_7_0, arg_7_1)
	return arg_7_0.level_[3][arg_7_1] or {}
end

function var_0_0.level4(arg_8_0, arg_8_1)
	return arg_8_0.level_[4][arg_8_1] or {}
end

function var_0_0.level5(arg_9_0, arg_9_1)
	return arg_9_0.level_[5][arg_9_1] or {}
end

function var_0_0.level6(arg_10_0, arg_10_1)
	return arg_10_0.level_[6][arg_10_1] or {}
end

function var_0_0.level7(arg_11_0, arg_11_1)
	return arg_11_0.level_[7][arg_11_1] or {}
end

function var_0_0.level8(arg_12_0, arg_12_1)
	return arg_12_0.level_[8][arg_12_1] or {}
end

function var_0_0.level9(arg_13_0, arg_13_1)
	return arg_13_0.level_[9][arg_13_1] or {}
end

function var_0_0.level10(arg_14_0, arg_14_1)
	return arg_14_0.level_[10][arg_14_1] or {}
end

return var_0_0
