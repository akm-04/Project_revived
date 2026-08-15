local var_0_0 = class("ActivityTutorPartnerRuleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.strength_ = {}
	arg_1_0.category_ = {}
	arg_1_0.extractNums_ = {}

	import("app.common.tables.TableParser").parse("activity_tutor_partner_rule.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.strength_[var_2_0] = tonumber(arg_2_0.strength)
		arg_1_0.category_[var_2_0] = tonumber(arg_2_0.category)
		arg_1_0.extractNums_[var_2_0] = tonumber(arg_2_0.extract_nums)
	end)
end

function var_0_0.strength(arg_3_0, arg_3_1)
	return arg_3_0.strength_[arg_3_1] or 0
end

function var_0_0.category(arg_4_0, arg_4_1)
	return arg_4_0.category_[arg_4_1] or 0
end

function var_0_0.extractNums(arg_5_0, arg_5_1)
	return arg_5_0.extractNums_[arg_5_1] or 0
end

return var_0_0
