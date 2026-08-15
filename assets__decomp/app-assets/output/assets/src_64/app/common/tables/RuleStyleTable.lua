local var_0_0 = class("RuleStyleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.titleColor_ = {}
	arg_1_0.textColor_ = {}
	arg_1_0.res_ = {}
	arg_1_0.capInsets_ = {}

	import("app.common.tables.TableParser").parse("rule_style.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.titleColor_[var_2_0] = arg_2_0.title_color
		arg_1_0.textColor_[var_2_0] = arg_2_0.text_color
		arg_1_0.res_[var_2_0] = arg_2_0.res
		arg_1_0.capInsets_[var_2_0] = xyd.splitToNumber(arg_2_0.capInsets, "|")
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.titleColor(arg_4_0, arg_4_1)
	return arg_4_0.titleColor_[arg_4_1] or ""
end

function var_0_0.textColor(arg_5_0, arg_5_1)
	return arg_5_0.textColor_[arg_5_1] or ""
end

function var_0_0.res(arg_6_0, arg_6_1)
	return arg_6_0.res_[arg_6_1] or ""
end

function var_0_0.capInsets(arg_7_0, arg_7_1)
	return arg_7_0.capInsets_[arg_7_1] or {}
end

return var_0_0
