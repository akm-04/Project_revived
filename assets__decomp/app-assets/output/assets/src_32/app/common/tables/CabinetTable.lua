local var_0_0 = class("CabinetTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.resources_id_ = {}
	arg_1_0.resources_num_ = {}
	arg_1_0.time_ = {}
	arg_1_0.type_request_ = {}
	arg_1_0.function_request_level_ = {}
	arg_1_0.item_level_ = {}
	arg_1_0.cut_time_ = {}

	import("app.common.tables.TableParser").parse("event_centre_cabinet.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = xyd.split(arg_2_0.desc, "|")
		arg_1_0.resources_id_[var_2_0] = xyd.splitToNumber(arg_2_0.resources_id, "|")
		arg_1_0.resources_num_[var_2_0] = xyd.splitToNumber(arg_2_0.resources_num, "|")
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.type_request_[var_2_0] = tonumber(arg_2_0.type_request)
		arg_1_0.function_request_level_[var_2_0] = tonumber(arg_2_0.function_request_level)
		arg_1_0.item_level_[var_2_0] = tonumber(arg_2_0.item_level)
		arg_1_0.cut_time_[var_2_0] = tonumber(arg_2_0.cut_time)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or {}
end

function var_0_0.resourcesId(arg_6_0, arg_6_1)
	return arg_6_0.resources_id_[arg_6_1] or {}
end

function var_0_0.resourcesNum(arg_7_0, arg_7_1)
	return arg_7_0.resources_num_[arg_7_1] or {}
end

function var_0_0.time(arg_8_0, arg_8_1)
	return arg_8_0.time_[arg_8_1] or 0
end

function var_0_0.typeRequest(arg_9_0, arg_9_1)
	return arg_9_0.type_request_[arg_9_1] or 0
end

function var_0_0.functionRequestLevel(arg_10_0, arg_10_1)
	return arg_10_0.function_request_level_[arg_10_1] or 0
end

function var_0_0.itemLevel(arg_11_0, arg_11_1)
	return arg_11_0.item_level_[arg_11_1] or 0
end

function var_0_0.cutTime(arg_12_0, arg_12_1)
	return arg_12_0.cut_time_[arg_12_1] or 0
end

return var_0_0
