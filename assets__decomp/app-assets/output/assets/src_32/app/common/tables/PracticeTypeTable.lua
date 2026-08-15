local var_0_0 = class("PracticeTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.style_name_ = {}
	arg_1_0.currency_type_ = {}
	arg_1_0.currency_num_ = {}
	arg_1_0.open_viplv_ = {}
	arg_1_0.lower_limit_ = {}
	arg_1_0.up_limit_ = {}

	import("app.common.tables.TableParser").parse("practice_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.style_name_[var_2_0] = arg_2_0.style_name
		arg_1_0.currency_type_[var_2_0] = tonumber(arg_2_0.currency_type)
		arg_1_0.currency_num_[var_2_0] = tonumber(arg_2_0.currency_num)
		arg_1_0.open_viplv_[var_2_0] = tonumber(arg_2_0.vip)
		arg_1_0.lower_limit_[var_2_0] = tonumber(arg_2_0.lower_limit)
		arg_1_0.up_limit_[var_2_0] = tonumber(arg_2_0.up_limit)
	end)
end

function var_0_0.getStyleName(arg_3_0, arg_3_1)
	return arg_3_0.style_name_[arg_3_1] or nil
end

function var_0_0.getSytle(arg_4_0, arg_4_1)
	return arg_4_0.currency_type_[arg_4_1]
end

function var_0_0.getCurrencyType(arg_5_0, arg_5_1)
	return arg_5_0.currency_type_[arg_5_1]
end

function var_0_0.getNum(arg_6_0, arg_6_1)
	return arg_6_0.currency_num_[arg_6_1] or 0
end

function var_0_0.getLowerLimit(arg_7_0, arg_7_1)
	return arg_7_0.lower_limit_[arg_7_1] or 0
end

function var_0_0.getOpenVip(arg_8_0, arg_8_1)
	return arg_8_0.open_viplv_[arg_8_1] or 0
end

function var_0_0.getUpLimit(arg_9_0, arg_9_1)
	return arg_9_0.up_limit_[arg_9_1] or 0
end

function var_0_0.getTableLength(arg_10_0)
	return #arg_10_0.style_name_
end

return var_0_0
