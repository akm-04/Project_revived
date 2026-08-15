local var_0_0 = class("ActivityAnniJigsaw2Table")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.amount_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_jigsaw2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.amount_[var_2_0] = tonumber(arg_2_0.amount)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.amount(arg_5_0, arg_5_1)
	return arg_5_0.amount_[arg_5_1] or 0
end

return var_0_0
