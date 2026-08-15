local var_0_0 = class("LibraryActTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.amour_ = {}

	import("app.common.tables.TableParser").parse("library_act.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.dialog_[var_2_0] = tonumber(arg_2_0.dialog)
		arg_1_0.amour_[var_2_0] = tonumber(arg_2_0.amour)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_0.dialog(arg_4_0, arg_4_1)
	return arg_4_0.dialog_[arg_4_1] or 0
end

function var_0_0.amour(arg_5_0, arg_5_1)
	return arg_5_0.amour_[arg_5_1] or 0
end

return var_0_0
