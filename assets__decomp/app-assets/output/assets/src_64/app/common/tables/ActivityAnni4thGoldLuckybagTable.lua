local var_0_0 = class("ActivityAnni4thGoldLuckybagTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.item_ = {}
	arg_1_0.type_ = {}
	arg_1_0.num_ = {}
	arg_1_0.rate_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_4th_gold_luckybag.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.item_[var_2_0] = arg_2_0.item
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.tyoe)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
	end)
end

function var_0_0.item(arg_3_0, arg_3_1)
	return arg_3_0.item_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.num(arg_5_0, arg_5_1)
	return arg_5_0.num_[arg_5_1] or 0
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

function var_0_0.getAllRates(arg_7_0)
	return arg_7_0.rate_ or {}
end

return var_0_0
