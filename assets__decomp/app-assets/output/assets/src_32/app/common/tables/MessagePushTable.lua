local var_0_0 = class("MessagePushTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.titles_ = {}
	arg_1_0.tips_ = {}

	import("app.common.tables.TableParser").parse("message_push.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.titles_[var_2_0] = arg_2_0.title
		arg_1_0.tips_[var_2_0] = arg_2_0.tip
	end)
end

function var_0_0.title(arg_3_0, arg_3_1)
	return arg_3_0.titles_[arg_3_1] or ""
end

function var_0_0.tip(arg_4_0, arg_4_1)
	return arg_4_0.tips_[arg_4_1] or ""
end

return var_0_0
