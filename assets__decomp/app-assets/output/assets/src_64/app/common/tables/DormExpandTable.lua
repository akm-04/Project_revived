local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("DormExpandTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.area_ = {}
	arg_1_0.comfort_ = {}
	arg_1_0.attr_ = {}
	arg_1_0.costItems_ = {}
	arg_1_0.costNums_ = {}
	arg_1_0.bg_ = {}
	arg_1_0.houseExpand_ = {}
	arg_1_0.brand_ = {}
	arg_1_0.costTimes_ = {}

	import("app.common.tables.TableParser").parse("dorm_expand.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.area_[var_2_0] = tonumber(arg_2_0.area)
		arg_1_0.comfort_[var_2_0] = tonumber(arg_2_0.comfort)
		arg_1_0.attr_[var_2_0] = var_0_1.split(arg_2_0.attr, "|")
		arg_1_0.costItems_[var_2_0] = var_0_1.splitToNumber(arg_2_0.cost_items, "|")
		arg_1_0.costNums_[var_2_0] = var_0_1.splitToNumber(arg_2_0.cost_nums, "|")
		arg_1_0.bg_[var_2_0] = arg_2_0.bg
		arg_1_0.houseExpand_[var_2_0] = arg_2_0.house_expand
		arg_1_0.brand_[var_2_0] = arg_2_0.brand
		arg_1_0.costTimes_[var_2_0] = tonumber(arg_2_0.cost_times)
	end)
end

function var_0_2.area(arg_3_0, arg_3_1)
	return arg_3_0.area_[arg_3_1] or 0
end

function var_0_2.comfort(arg_4_0, arg_4_1)
	return arg_4_0.comfort_[arg_4_1] or 0
end

function var_0_2.attr(arg_5_0, arg_5_1)
	return arg_5_0.attr_[arg_5_1] or {}
end

function var_0_2.costItems(arg_6_0, arg_6_1)
	return arg_6_0.costItems_[arg_6_1] or {}
end

function var_0_2.costNums(arg_7_0, arg_7_1)
	return arg_7_0.costNums_[arg_7_1] or {}
end

function var_0_2.bg(arg_8_0, arg_8_1)
	return arg_8_0.bg_[arg_8_1] or ""
end

function var_0_2.houseExpand(arg_9_0, arg_9_1)
	return arg_9_0.houseExpand_[arg_9_1] or ""
end

function var_0_2.brand(arg_10_0, arg_10_1)
	return arg_10_0.brand_[arg_10_1] or ""
end

function var_0_2.costTimes(arg_11_0, arg_11_1)
	return arg_11_0.costTimes_[arg_11_1] or 0
end

function var_0_2.getAttrsGrowByLev(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	for iter_12_0 = arg_12_3, 1, -1 do
		if arg_12_2 >= arg_12_0:comfort(iter_12_0) then
			local var_12_0 = arg_12_0:attr(iter_12_0)

			return var_0_1.splitToNumber(var_12_0[arg_12_1], ",")
		end
	end

	return nil
end

function var_0_2.getAttrsByType(arg_13_0, arg_13_1)
	local var_13_0 = {}

	for iter_13_0 = 1, 3 do
		local var_13_1 = arg_13_0:attr(iter_13_0)

		table.insert(var_13_0, var_13_1[arg_13_1])
	end

	return var_13_0
end

function var_0_2.getComforts(arg_14_0)
	local var_14_0 = {}

	for iter_14_0 = 1, 3 do
		table.insert(var_14_0, arg_14_0:comfort(iter_14_0))
	end

	return var_14_0
end

return var_0_2
