local var_0_0 = class("ObjectClassTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.book_ = {}
	arg_1_0.application_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("object_class.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.book_[var_2_0] = xyd.splitToNumber(arg_2_0.book, "|")
		arg_1_0.application_[var_2_0] = tonumber(arg_2_0.application)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.book(arg_5_0, arg_5_1)
	return arg_5_0.book_[arg_5_1] or {}
end

function var_0_0.application(arg_6_0, arg_6_1)
	return arg_6_0.application_[arg_6_1] or 0
end

function var_0_0.icon(arg_7_0, arg_7_1)
	return arg_7_0.icon_[arg_7_1] or ""
end

return var_0_0
