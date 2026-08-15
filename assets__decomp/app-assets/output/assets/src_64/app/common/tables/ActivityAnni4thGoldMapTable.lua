local var_0_0 = class("ActivityAnni4thGoldMapTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ID_ = {}
	arg_1_0.level_ = {}

	for iter_1_0 = 1, 25 do
		arg_1_0.level_[iter_1_0] = {}
	end

	import("app.common.tables.TableParser").parse("activity_anni_4th_gold_map.lua", function(arg_2_0)
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
		arg_1_0.level_[11][var_2_0] = xyd.splitToNumber(arg_2_0.level_11, "|")
		arg_1_0.level_[12][var_2_0] = xyd.splitToNumber(arg_2_0.level_12, "|")
		arg_1_0.level_[13][var_2_0] = xyd.splitToNumber(arg_2_0.level_13, "|")
		arg_1_0.level_[14][var_2_0] = xyd.splitToNumber(arg_2_0.level_14, "|")
		arg_1_0.level_[15][var_2_0] = xyd.splitToNumber(arg_2_0.level_15, "|")
		arg_1_0.level_[16][var_2_0] = xyd.splitToNumber(arg_2_0.level_16, "|")
		arg_1_0.level_[17][var_2_0] = xyd.splitToNumber(arg_2_0.level_17, "|")
		arg_1_0.level_[18][var_2_0] = xyd.splitToNumber(arg_2_0.level_18, "|")
		arg_1_0.level_[19][var_2_0] = xyd.splitToNumber(arg_2_0.level_19, "|")
		arg_1_0.level_[20][var_2_0] = xyd.splitToNumber(arg_2_0.level_20, "|")
		arg_1_0.level_[21][var_2_0] = xyd.splitToNumber(arg_2_0.level_21, "|")
		arg_1_0.level_[22][var_2_0] = xyd.splitToNumber(arg_2_0.level_22, "|")
		arg_1_0.level_[23][var_2_0] = xyd.splitToNumber(arg_2_0.level_23, "|")
		arg_1_0.level_[24][var_2_0] = xyd.splitToNumber(arg_2_0.level_24, "|")
		arg_1_0.level_[25][var_2_0] = xyd.splitToNumber(arg_2_0.level_25, "|")
	end)
end

function var_0_0.ID(arg_3_0, arg_3_1)
	return arg_3_0.ID_[arg_3_1] or 0
end

function var_0_0.level(arg_4_0)
	return arg_4_0.level_ or {}
end

return var_0_0
