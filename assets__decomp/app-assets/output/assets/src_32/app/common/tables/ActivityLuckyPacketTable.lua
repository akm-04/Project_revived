local var_0_0 = class("ActivityLuckyPacketTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.amount_ = {}
	arg_1_0.pacAmount_ = {}
	arg_1_0.pacMoney_ = {}
	arg_1_0.pacMin_ = {}

	import("app.common.tables.TableParser").parse("activity_luckypacket.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.amount_[var_2_0] = tonumber(arg_2_0.amount)
		arg_1_0.pacAmount_[var_2_0] = tonumber(arg_2_0.pac_amount)
		arg_1_0.pacMoney_[var_2_0] = tonumber(arg_2_0.pac_money)
		arg_1_0.pacMin_[var_2_0] = tonumber(arg_2_0.pac_min)
	end)
end

function var_0_0.amount(arg_3_0, arg_3_1)
	return arg_3_0.amount_[arg_3_1] or 0
end

function var_0_0.pacAmount(arg_4_0, arg_4_1)
	return arg_4_0.pacAmount_[arg_4_1] or 0
end

function var_0_0.pacMoney(arg_5_0, arg_5_1)
	return arg_5_0.pacMoney_[arg_5_1] or 0
end

function var_0_0.pacMin(arg_6_0, arg_6_1)
	return arg_6_0.pacMin_[arg_6_1] or 0
end

function var_0_0.getItemMaxNum(arg_7_0)
	if arg_7_0.amount_ and next(arg_7_0.amount_) then
		return #arg_7_0.amount_
	else
		return 0
	end
end

return var_0_0
