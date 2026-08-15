local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = class("ConquerSchoolTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.regionName_ = {}
	arg_1_0.attrType_ = {}
	arg_1_0.attrNum_ = {}
	arg_1_0.translation_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("conquer_school.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("conquer_school", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.region_id)

	arg_2_0.regionName_[var_2_0] = arg_2_1.region_name
	arg_2_0.attrType_[var_2_0] = var_0_1.splitToNumber(arg_2_1.attr_type, "|")
	arg_2_0.attrNum_[var_2_0] = var_0_1.splitToNumber(arg_2_1.attr_num, "|")
	arg_2_0.translation_[var_2_0] = var_0_1.split(arg_2_1.translation, "|")
end

function var_0_2.regionName(arg_3_0, arg_3_1)
	return arg_3_0.regionName_[arg_3_1] or ""
end

function var_0_2.attrType(arg_4_0, arg_4_1)
	return arg_4_0.attrType_[arg_4_1] or {}
end

function var_0_2.attrNum(arg_5_0, arg_5_1)
	return arg_5_0.attrNum_[arg_5_1] or {}
end

function var_0_2.attrValues(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_1 or not arg_6_2 then
		return 0
	end

	local var_6_0 = arg_6_0:attrType(arg_6_1)
	local var_6_1 = arg_6_0:attrNum(arg_6_1)

	for iter_6_0 = 1, #var_6_0 do
		if var_6_0[iter_6_0] == arg_6_2 then
			return var_6_1[iter_6_0]
		end
	end

	return 0
end

function var_0_2.translation(arg_7_0, arg_7_1)
	return arg_7_0.translation_[arg_7_1] or {}
end

return var_0_2
