local var_0_0 = class("ActivityAliceBox2Table")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.limitTimes_ = {}

	import("app.common.tables.TableParser").parse("activity_alice_box2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.limitTimes_[var_2_0] = tonumber(arg_2_0.limit_times)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.cost(arg_5_0, arg_5_1)
	return arg_5_0.cost_[arg_5_1] or 0
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

function var_0_0.limitTimes(arg_7_0, arg_7_1)
	return arg_7_0.limitTimes_[arg_7_1] or 0
end

return var_0_0
