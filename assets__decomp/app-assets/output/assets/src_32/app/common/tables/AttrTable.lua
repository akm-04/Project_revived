local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = class("AttrTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.suffix_ = {}
	arg_1_0.attrScore_ = {}
	arg_1_0.percent_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("attr.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("attr", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.names_[var_2_0] = arg_2_1.name
	arg_2_0.suffix_[var_2_0] = arg_2_1.suffix
	arg_2_0.attrScore_[var_2_0] = tonumber(arg_2_1.power_param)
	arg_2_0.percent_[var_2_0] = tonumber(arg_2_1.percent)
end

function var_0_2.name(arg_3_0, arg_3_1)
	return arg_3_0.names_[arg_3_1]
end

function var_0_2.suffix(arg_4_0, arg_4_1)
	return arg_4_0.suffix_[arg_4_1] or ""
end

function var_0_2.attrScore(arg_5_0, arg_5_1)
	return arg_5_0.attrScore_[arg_5_1] or 0
end

function var_0_2.percent(arg_6_0, arg_6_1)
	return arg_6_0.percent_[arg_6_1] or 0
end

function var_0_2.isPercent(arg_7_0, arg_7_1)
	if arg_7_0:percent(arg_7_1) == 1 then
		return true
	else
		return false
	end
end

return var_0_2
