local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("SpiritSuitTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.attr2_ = {}
	arg_1_0.attr2Value_ = {}
	arg_1_0.isP_ = {}
	arg_1_0.attr4Desc_ = {}
	arg_1_0.campainDesc_ = {}
	arg_1_0.totalNum = 0

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("spirit_suit.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("spirit_suit", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.attr2_[var_2_0] = tonumber(arg_2_1.attr_2)
	arg_2_0.attr2Value_[var_2_0] = tonumber(arg_2_1.attr_2_value)
	arg_2_0.isP_[var_2_0] = tonumber(arg_2_1.is_p)
	arg_2_0.attr4Desc_[var_2_0] = arg_2_1.attr_4_desc
	arg_2_0.campainDesc_[var_2_0] = var_0_1.split(arg_2_1.campain_desc, "|")
	arg_2_0.totalNum = arg_2_0.totalNum + 1
end

function var_0_2.getTotalNum(arg_3_0)
	return arg_3_0.totalNum
end

function var_0_2.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_2.attr2(arg_5_0, arg_5_1)
	return arg_5_0.attr2_[arg_5_1] or 0
end

function var_0_2.attr2Value(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.isP_[arg_6_1] == 1

	return arg_6_0.attr2Value_[arg_6_1] or 0, var_6_0
end

function var_0_2.attr4Desc(arg_7_0, arg_7_1)
	return arg_7_0.attr4Desc_[arg_7_1] or ""
end

function var_0_2.campainDesc(arg_8_0, arg_8_1)
	return arg_8_0.campainDesc_[arg_8_1] or {}
end

return var_0_2
