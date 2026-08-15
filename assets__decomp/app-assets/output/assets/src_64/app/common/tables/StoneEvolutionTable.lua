local var_0_0 = class("StoneEvolutionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.level_ = {}
	arg_1_0.star_ = {}
	arg_1_0.attrs_ = {}
	arg_1_0.attrsNum_ = {}
	arg_1_0.limitNum_ = {}

	import("app.common.tables.TableParser").parse("stone_evolution.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.star_[var_2_0] = tonumber(arg_2_0.star)
		arg_1_0.attrs_[var_2_0] = xyd.splitToNumber(arg_2_0.attrs, "|")
		arg_1_0.attrsNum_[var_2_0] = xyd.splitToNumber(arg_2_0.attrs_num, "|")
		arg_1_0.limitNum_[var_2_0] = tonumber(arg_2_0.limit_num)
	end)
end

function var_0_0.level(arg_3_0, arg_3_1)
	return arg_3_0.level_[arg_3_1] or 0
end

function var_0_0.star(arg_4_0, arg_4_1)
	return arg_4_0.star_[arg_4_1] or 0
end

function var_0_0.attrs(arg_5_0, arg_5_1)
	return arg_5_0.attrs_[arg_5_1] or {}
end

function var_0_0.attrsNum(arg_6_0, arg_6_1)
	return arg_6_0.attrsNum_[arg_6_1] or {}
end

function var_0_0.limitNum(arg_7_0, arg_7_1)
	return arg_7_0.limitNum_[arg_7_1] or 0
end

function var_0_0.getMaxStage(arg_8_0)
	return #arg_8_0.level_
end

function var_0_0.absoluteLimit(arg_9_0, arg_9_1)
	local var_9_0 = 0

	for iter_9_0 = 1, arg_9_1 do
		var_9_0 = var_9_0 + arg_9_0:limitNum(iter_9_0)
	end

	return var_9_0
end

function var_0_0.getAttrLimit(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = 0

	for iter_10_0 = 1, arg_10_1 do
		var_10_0 = var_10_0 + arg_10_0:limitNum(iter_10_0) * arg_10_0:attrsNum(iter_10_0)[arg_10_2]
	end

	return var_10_0
end

function var_0_0.getCumAttr(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = 0
	local var_11_1 = 0

	for iter_11_0 = 1, arg_11_1 do
		var_11_1 = var_11_1 + arg_11_0:limitNum(iter_11_0) * arg_11_0:attrsNum(iter_11_0)[arg_11_3]

		if iter_11_0 < arg_11_1 then
			var_11_0 = var_11_0 + arg_11_0:limitNum(iter_11_0) * arg_11_0:attrsNum(iter_11_0)[arg_11_3]
		else
			var_11_0 = var_11_0 + arg_11_2 * arg_11_0:attrsNum(iter_11_0)[arg_11_3]
		end
	end

	return var_11_0, var_11_1
end

function var_0_0.getCumAttrByType(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = arg_12_0:attrs(arg_12_1)

	for iter_12_0, iter_12_1 in pairs(var_12_0) do
		if iter_12_1 == arg_12_3 then
			return arg_12_0:getCumAttr(arg_12_1, arg_12_2, iter_12_0)
		end
	end

	return 0
end

function var_0_0.getCumLimit(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = 0
	local var_13_1 = 0

	for iter_13_0 = 1, arg_13_1 do
		var_13_1 = var_13_1 + arg_13_0:limitNum(iter_13_0)

		if iter_13_0 < arg_13_1 then
			var_13_0 = var_13_0 + arg_13_0:limitNum(iter_13_0)
		else
			var_13_0 = var_13_0 + arg_13_2
		end
	end

	return var_13_0, var_13_1
end

return var_0_0
