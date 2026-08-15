local var_0_0 = class("EventAdminTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.resourcesId_ = {}
	arg_1_0.resourcesNum_ = {}
	arg_1_0.time_ = {}
	arg_1_0.functionRequest_ = {}
	arg_1_0.functionRequestLevel_ = {}
	arg_1_0.unlock_ = {}

	import("app.common.tables.TableParser").parse("event_centre_administrator.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = xyd.split(arg_2_0.desc, "|")
		arg_1_0.resourcesId_[var_2_0] = xyd.splitToNumber(arg_2_0.resources_id, "|")
		arg_1_0.resourcesNum_[var_2_0] = xyd.splitToNumber(arg_2_0.resources_num, "|")
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.functionRequest_[var_2_0] = tonumber(arg_2_0.type_request)
		arg_1_0.functionRequestLevel_[var_2_0] = tonumber(arg_2_0.function_request_level)
		arg_1_0.unlock_[var_2_0] = xyd.splitToNumber(arg_2_0.unlock, "|")
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.resourcesId(arg_6_0, arg_6_1)
	return arg_6_0.resourcesId_[arg_6_1] or {}
end

function var_0_0.resourcesNum(arg_7_0, arg_7_1)
	return arg_7_0.resourcesNum_[arg_7_1] or {}
end

function var_0_0.time(arg_8_0, arg_8_1)
	return arg_8_0.time_[arg_8_1] or 0
end

function var_0_0.typeRequest(arg_9_0, arg_9_1)
	return arg_9_0.functionRequest_[arg_9_1] or 0
end

function var_0_0.functionRequestLevel(arg_10_0, arg_10_1)
	return arg_10_0.functionRequestLevel_[arg_10_1] or 0
end

function var_0_0.unlock(arg_11_0, arg_11_1)
	return arg_11_0.unlock_[arg_11_1] or {}
end

return var_0_0
