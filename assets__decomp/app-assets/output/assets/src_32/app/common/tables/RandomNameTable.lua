local var_0_0 = class("RandomNameTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.nameType_ = {}
	arg_1_0.nameTxt_ = {}
	arg_1_0.nameClassified_ = {}

	import("app.common.tables.TableParser").parse("random_name.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.nameType_[var_2_0] = tonumber(arg_2_0.name_type)
		arg_1_0.nameTxt_[var_2_0] = arg_2_0.text

		if not arg_1_0.nameClassified_[arg_1_0.nameType_[var_2_0]] then
			arg_1_0.nameClassified_[arg_1_0.nameType_[var_2_0]] = {}
		end

		table.insert(arg_1_0.nameClassified_[arg_1_0.nameType_[var_2_0]], arg_1_0.nameTxt_[var_2_0])
	end)
end

function var_0_0.nameType(arg_3_0, arg_3_1)
	return arg_3_0.nameType_[arg_3_1] or 0
end

function var_0_0.nameTxt(arg_4_0, arg_4_1)
	return arg_4_0.nameTxt_[arg_4_1] or ""
end

function var_0_0.nameClassified(arg_5_0, arg_5_1)
	return arg_5_0.nameClassified_[arg_5_1] or nil
end

return var_0_0
