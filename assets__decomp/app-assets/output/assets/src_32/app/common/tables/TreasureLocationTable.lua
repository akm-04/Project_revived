local var_0_0 = class("TreasureLocationTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.treasure_type_ = {}
	arg_1_0.ids_ = {}
	arg_1_0.model_ = {}
	arg_1_0.offset_ = {}
	arg_1_0.scale_ = {}
	arg_1_0.max_member_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.base_ice_ = {}
	arg_1_0.base_time_ = {}
	arg_1_0.tableID_ = {}

	import("app.common.tables.TableParser").parse("treasure_location.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.treasure_type_[var_2_0] = xyd.splitToNumber(arg_2_0.treasure_type, "|")
		arg_1_0.max_member_[var_2_0] = tonumber(arg_2_0.max_member)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.base_ice_[var_2_0] = tonumber(arg_2_0.base_ice)
		arg_1_0.base_time_[var_2_0] = tonumber(arg_2_0.base_time)
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.tableID_[var_2_0] = tonumber(arg_2_0.table_id)
		arg_1_0.scale_[var_2_0] = tonumber(arg_2_0.scale)
		arg_1_0.offset_[var_2_0] = tonumber(arg_2_0.offset)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.treasureType(arg_4_0, arg_4_1)
	return arg_4_0.treasure_type_[arg_4_1] or {}
end

function var_0_0.getAll(arg_5_0)
	return arg_5_0.ids_ or {}
end

function var_0_0.maxMember(arg_6_0, arg_6_1)
	return arg_6_0.max_member_[arg_6_1] or 0
end

function var_0_0.icon(arg_7_0, arg_7_1)
	return arg_7_0.icon_[arg_7_1] or ""
end

function var_0_0.baseIce(arg_8_0, arg_8_1)
	return arg_8_0.base_ice_[arg_8_1] or 0
end

function var_0_0.baseTime(arg_9_0, arg_9_1)
	return arg_9_0.base_time_[arg_9_1] or 0
end

function var_0_0.model(arg_10_0, arg_10_1)
	return arg_10_0.model_[arg_10_1] or 0
end

function var_0_0.tableID(arg_11_0, arg_11_1)
	return arg_11_0.tableID_[arg_11_1] or 0
end

function var_0_0.scale(arg_12_0, arg_12_1)
	return arg_12_0.scale_[arg_12_1] or 1
end

function var_0_0.offset(arg_13_0, arg_13_1)
	return arg_13_0.offset_[arg_13_1] or 0
end

return var_0_0
