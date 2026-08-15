local var_0_0 = class("ChatBubbleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.isShow_ = {}
	arg_1_0.capInsets_ = {}
	arg_1_0.minLength_ = {}

	import("app.common.tables.TableParser").parse("chat_bubble.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.isShow_[var_2_0] = tonumber(arg_2_0.is_show)
		arg_1_0.capInsets_[var_2_0] = xyd.splitToNumber(arg_2_0.cap_insets, "|")
		arg_1_0.minLength_[var_2_0] = tonumber(arg_2_0.min_length)
	end)
end

function var_0_0.all(arg_3_0)
	return arg_3_0.name_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.isShow(arg_6_0, arg_6_1)
	return arg_6_0.isShow_[arg_6_1] or 0
end

function var_0_0.capInsets(arg_7_0, arg_7_1)
	return arg_7_0.capInsets_[arg_7_1]
end

function var_0_0.minLength(arg_8_0, arg_8_1)
	return arg_8_0.minLength_[arg_8_1]
end

return var_0_0
