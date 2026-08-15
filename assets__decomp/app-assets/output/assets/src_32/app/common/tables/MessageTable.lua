local var_0_0 = class("MessageTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.contents_ = {}
	arg_1_0.types_ = {}

	import("app.common.tables.TableParser").parse("message.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.types_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.contents_[var_2_0] = arg_2_0.content
	end)
end

function var_0_0.getContent(arg_3_0, arg_3_1)
	return arg_3_0.contents_[arg_3_1] or ""
end

return var_0_0
