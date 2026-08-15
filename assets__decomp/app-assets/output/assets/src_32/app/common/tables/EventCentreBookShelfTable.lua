local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = class("EventCentreBookShelfTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.resourcesId_ = {}
	arg_1_0.resourcesNum_ = {}
	arg_1_0.time_ = {}
	arg_1_0.typeRequest_ = {}
	arg_1_0.functionRequestLevel_ = {}
	arg_1_0.attribute_ = {}
	arg_1_0.upperLimit_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("event_centre_bookshelf.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("event_centre_bookshelf", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.id_[var_2_0] = tonumber(arg_2_1.id)
	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.type_[var_2_0] = tonumber(arg_2_1.type)
	arg_2_0.desc_[var_2_0] = var_0_1.split(arg_2_1.desc, "|")
	arg_2_0.resourcesId_[var_2_0] = var_0_1.splitToNumber(arg_2_1.resources_id, "|")
	arg_2_0.resourcesNum_[var_2_0] = var_0_1.splitToNumber(arg_2_1.resources_num, "|")
	arg_2_0.time_[var_2_0] = tonumber(arg_2_1.time)
	arg_2_0.typeRequest_[var_2_0] = tonumber(arg_2_1.type_request)
	arg_2_0.functionRequestLevel_[var_2_0] = tonumber(arg_2_1.function_request_level)
	arg_2_0.attribute_[var_2_0] = var_0_1.split(arg_2_1.attribute, "|")
	arg_2_0.upperLimit_[var_2_0] = tonumber(arg_2_1.upper_limit)
end

function var_0_2.ids(arg_3_0)
	return arg_3_0.id_ or 0
end

function var_0_2.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_2.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or ""
end

function var_0_2.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1] or ""
end

function var_0_2.resourcesId(arg_7_0, arg_7_1)
	return arg_7_0.resourcesId_[arg_7_1] or ""
end

function var_0_2.resourcesNum(arg_8_0, arg_8_1)
	return arg_8_0.resourcesNum_[arg_8_1] or ""
end

function var_0_2.time(arg_9_0, arg_9_1)
	return arg_9_0.time_[arg_9_1] or ""
end

function var_0_2.typeRequest(arg_10_0, arg_10_1)
	return arg_10_0.typeRequest_[arg_10_1] or ""
end

function var_0_2.functionRequestLevel(arg_11_0, arg_11_1)
	return arg_11_0.functionRequestLevel_[arg_11_1] or ""
end

function var_0_2.attribute(arg_12_0, arg_12_1)
	return arg_12_0.attribute_[arg_12_1] or ""
end

function var_0_2.parameter(arg_13_0, arg_13_1)
	return arg_13_0.parameter_[arg_13_1] or ""
end

function var_0_2.upperLimit(arg_14_0, arg_14_1)
	return arg_14_0.upperLimit_[arg_14_1] or ""
end

return var_0_2
