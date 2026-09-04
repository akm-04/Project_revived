local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("SpiritTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.star_ = {}
	arg_1_0.pos_ = {}
	arg_1_0.main_ = {}
	arg_1_0.mainIsP_ = {}
	arg_1_0.mainValue_ = {}
	arg_1_0.mainStrth_ = {}
	arg_1_0.subNum_ = {}
	arg_1_0.subNumRate_ = {}
	arg_1_0.sub_ = {}
	arg_1_0.subIsP_ = {}
	arg_1_0.subStrth_ = {}
	arg_1_0.aubValue_ = {}
	arg_1_0.exp_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("spirit.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("spirit", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.star_[var_2_0] = tonumber(arg_2_1.star)
	arg_2_0.pos_[var_2_0] = tonumber(arg_2_1.pos)
	arg_2_0.main_[var_2_0] = var_0_1.splitToNumber(arg_2_1.main, "|")
	arg_2_0.mainIsP_[var_2_0] = var_0_1.splitToNumber(arg_2_1.main_is_p, "|")
	arg_2_0.mainValue_[var_2_0] = var_0_1.splitToNumber(arg_2_1.main_value, "|")
	arg_2_0.mainStrth_[var_2_0] = var_0_1.splitToNumber(arg_2_1.main_strth, "|")
	arg_2_0.subNum_[var_2_0] = tonumber(arg_2_1.sub_num)
	arg_2_0.subNumRate_[var_2_0] = var_0_1.splitToNumber(arg_2_1.sub_num_rate, "|")
	arg_2_0.sub_[var_2_0] = var_0_1.splitToNumber(arg_2_1.sub, "|")
	arg_2_0.subIsP_[var_2_0] = var_0_1.splitToNumber(arg_2_1.sub_is_p, "|")
	arg_2_0.subStrth_[var_2_0] = var_0_1.splitToNumber(arg_2_1.sub_strth, "|")
	arg_2_0.aubValue_[var_2_0] = var_0_1.splitToNumber(arg_2_1.aub_value, "|")
	arg_2_0.exp_[var_2_0] = tonumber(arg_2_1.exp)
end

function var_0_2.star(arg_3_0, arg_3_1)
	return arg_3_0.star_[arg_3_1] or 0
end

function var_0_2.pos(arg_4_0, arg_4_1)
	return arg_4_0.pos_[arg_4_1] or 0
end

function var_0_2.main(arg_5_0, arg_5_1, arg_5_2)
	return arg_5_0.main_[arg_5_1][arg_5_2] or 0
end

function var_0_2.mainIsP(arg_6_0, arg_6_1, arg_6_2)
	return arg_6_0.mainIsP_[arg_6_1][arg_6_2] or 0
end

function var_0_2.mainValue(arg_7_0, arg_7_1, arg_7_2)
	return arg_7_0.mainValue_[arg_7_1][arg_7_2] or 0
end

function var_0_2.mainStrth(arg_8_0, arg_8_1, arg_8_2)
	return arg_8_0.mainStrth_[arg_8_1][arg_8_2] or 0
end

function var_0_2.mainTotalValue(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	return arg_9_0.mainValue_[arg_9_1][arg_9_2] + arg_9_3 * arg_9_0.mainStrth_[arg_9_1][arg_9_2]
end

function var_0_2.subNum(arg_10_0, arg_10_1)
	return arg_10_0.subNum_[arg_10_1] or 0
end

function var_0_2.subNumRate(arg_11_0, arg_11_1)
	return arg_11_0.subNumRate_[arg_11_1] or {}
end

function var_0_2.sub(arg_12_0, arg_12_1, arg_12_2)
	return arg_12_0.sub_[arg_12_1][arg_12_2] or 0
end

function var_0_2.subIsP(arg_13_0, arg_13_1, arg_13_2)
	return arg_13_0.subIsP_[arg_13_1][arg_13_2] or 0
end

function var_0_2.subStrth(arg_14_0, arg_14_1)
	return arg_14_0.subStrth_[arg_14_1] or {}
end

function var_0_2.aubValue(arg_15_0, arg_15_1)
	return arg_15_0.aubValue_[arg_15_1] or {}
end

function var_0_2.exp(arg_16_0, arg_16_1)
	return arg_16_0.exp_[arg_16_1] or 0
end

return var_0_2
