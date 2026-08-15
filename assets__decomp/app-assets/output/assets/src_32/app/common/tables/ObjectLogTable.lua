local var_0_0 = class("ObjectLogTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.state_ = {}
	arg_1_0.text_ = {}

	import("app.common.tables.TableParser").parse("object_log.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.state_[var_2_0] = arg_2_0.state
		arg_1_0.text_[var_2_0] = arg_2_0.text
	end)
end

function var_0_0.state(arg_3_0, arg_3_1)
	return arg_3_0.state_[arg_3_1] or ""
end

function var_0_0.text(arg_4_0, arg_4_1)
	return arg_4_0.text_[arg_4_1] or ""
end

return var_0_0
