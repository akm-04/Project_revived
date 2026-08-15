local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("ElementStrthTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.strthMtrs_ = {}
	arg_1_0.strthMtrsNums_ = {}
	arg_1_0.decMtrs_ = {}
	arg_1_0.decMtrsNums_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("element_strth.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("element_strth", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.strth_ranks)

	if not arg_2_0.strthMtrs_[var_2_0] then
		arg_2_0.strthMtrs_[var_2_0] = {}
		arg_2_0.strthMtrsNums_[var_2_0] = {}
		arg_2_0.decMtrs_[var_2_0] = {}
		arg_2_0.decMtrsNums_[var_2_0] = {}
	end

	for iter_2_0 = 1, 3 do
		arg_2_0.strthMtrs_[var_2_0][iter_2_0] = var_0_1.splitToNumber(arg_2_1["strth_mtrs" .. iter_2_0], "|") or {}
		arg_2_0.strthMtrsNums_[var_2_0][iter_2_0] = var_0_1.splitToNumber(arg_2_1["strth_nums" .. iter_2_0], "|") or {}
		arg_2_0.decMtrs_[var_2_0][iter_2_0] = var_0_1.splitToNumber(arg_2_1["dec_mtrs" .. iter_2_0], "|") or {}
		arg_2_0.decMtrsNums_[var_2_0][iter_2_0] = var_0_1.splitToNumber(arg_2_1["dec_nums" .. iter_2_0], "|") or {}
	end
end

function var_0_2.strthMtrs(arg_3_0, arg_3_1, arg_3_2)
	return arg_3_0.strthMtrs_[arg_3_1][arg_3_2]
end

function var_0_2.strthMtrsNums(arg_4_0, arg_4_1, arg_4_2)
	return arg_4_0.strthMtrsNums_[arg_4_1][arg_4_2]
end

function var_0_2.decMtrs(arg_5_0, arg_5_1, arg_5_2)
	return arg_5_0.decMtrs_[arg_5_1][arg_5_2]
end

function var_0_2.decMtrsNums(arg_6_0, arg_6_1, arg_6_2)
	return arg_6_0.decMtrsNums_[arg_6_1][arg_6_2]
end

return var_0_2
