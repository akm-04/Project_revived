local var_0_0 = class("LibraryDialogConfigNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.openCondition_ = {}

	import("app.common.tables.TableParser").parse("library_dialog_config.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.openCondition_[var_2_0] = tonumber(arg_2_0.open_condition)
	end)
end

function var_0_0.getType(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1]
end

function var_0_0.getDesc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1]
end

function var_0_0.getOpenCondition(arg_5_0, arg_5_1)
	return arg_5_0.openCondition_[arg_5_1]
end

function var_0_0.getTotalNum(arg_6_0)
	return #arg_6_0.type_
end

return var_0_0
