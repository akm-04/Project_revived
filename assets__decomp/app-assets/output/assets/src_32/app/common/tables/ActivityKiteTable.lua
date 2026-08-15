local var_0_0 = class("ActivityKiteTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.amount_ = {}
	arg_1_0.name_ = {}
	arg_1_0.pacAmount_ = {}
	arg_1_0.pacMoneyRight_ = {}
	arg_1_0.pacMoneyWrong_ = {}

	import("app.common.tables.TableParser").parse("activity_kite.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.amount_[var_2_0] = tonumber(arg_2_0.amount)
		arg_1_0.pacAmount_[var_2_0] = tonumber(arg_2_0.activity_amount)
		arg_1_0.pacMoneyRight_[var_2_0] = tonumber(arg_2_0.activity_right)
		arg_1_0.pacMoneyWrong_[var_2_0] = tonumber(arg_2_0.pac_wrong)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.amount(arg_4_0, arg_4_1)
	return arg_4_0.amount_[arg_4_1] or 0
end

function var_0_0.activityAmount(arg_5_0, arg_5_1)
	return arg_5_0.pacAmount_[arg_5_1] or 0
end

function var_0_0.pacMoneyRight(arg_6_0, arg_6_1)
	return arg_6_0.pacMoneyRight_[arg_6_1] or 0
end

function var_0_0.pacMoneyWrong(arg_7_0, arg_7_1)
	return arg_7_0.pacMoneyWrong_[arg_7_1] or 0
end

function var_0_0.getItemMaxNum(arg_8_0)
	if arg_8_0.amount_ and next(arg_8_0.amount_) then
		return #arg_8_0.amount_
	else
		return 0
	end
end

return var_0_0
