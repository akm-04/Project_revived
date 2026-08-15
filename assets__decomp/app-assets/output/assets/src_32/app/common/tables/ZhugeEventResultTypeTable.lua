local var_0_0 = class("ZhugeEventResultTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.resultType_ = {}
	arg_1_0.toastText_ = {}

	import("app.common.tables.TableParser").parse("zhuge_event_result_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.resultType_[var_2_0] = arg_2_0.result_type
		arg_1_0.toastText_[var_2_0] = arg_2_0.toast_text
	end)
end

function var_0_0.resultType(arg_3_0, arg_3_1)
	return arg_3_0.resultType_[arg_3_1] or ""
end

function var_0_0.toastText(arg_4_0, arg_4_1)
	return arg_4_0.toastText_[arg_4_1] or ""
end

return var_0_0
