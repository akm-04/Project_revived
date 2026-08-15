local var_0_0 = class("SuperEquipEnhanceTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.attrIncrRatio_ = {}
	arg_1_0.needStar_ = {}
	arg_1_0.needNum_ = {}

	import("app.common.tables.TableParser").parse("super_equip_enhance.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.attrIncrRatio_[var_2_0] = tonumber(arg_2_0.attr_incr_ratio)
		arg_1_0.needStar_[var_2_0] = tonumber(arg_2_0.need_star)
		arg_1_0.needNum_[var_2_0] = tonumber(arg_2_0.need_num)
	end)
end

function var_0_0.attrIncrRatio(arg_3_0, arg_3_1)
	return arg_3_0.attrIncrRatio_[arg_3_1] or 0
end

function var_0_0.needStar(arg_4_0, arg_4_1)
	return arg_4_0.needStar_[arg_4_1] or 0
end

function var_0_0.needNum(arg_5_0, arg_5_1)
	return arg_5_0.needNum_[arg_5_1] or 0
end

function var_0_0.getRate(arg_6_0, arg_6_1)
	if arg_6_1 < 1 then
		return 1
	end

	local var_6_0 = 2

	for iter_6_0 = 1, arg_6_1 do
		var_6_0 = var_6_0 + arg_6_0:attrIncrRatio(math.ceil(iter_6_0 / 10))
	end

	return var_6_0
end

return var_0_0
