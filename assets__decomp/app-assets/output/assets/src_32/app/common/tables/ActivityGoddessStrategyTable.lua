local var_0_0 = class("ActivityGoddessStrategyTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.type_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.point_ = {}

	import("app.common.tables.TableParser").parse("activity_goddess_strategy.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.gift_[var_2_0] = xyd.splitToNumber(arg_2_0.gift, "|")
		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.get_point)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or ""
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or {}
end

function var_0_0.recharge(arg_5_0, arg_5_1)
	return arg_5_0.recharge_[arg_5_1] or 0
end

function var_0_0.point(arg_6_0, arg_6_1)
	return arg_6_0.point_[arg_6_1] or 0
end

function var_0_0.getGiftsByType(arg_7_0, arg_7_1)
	local var_7_0 = {}

	for iter_7_0 = 1, #arg_7_0.ids_ do
		local var_7_1 = arg_7_0.ids_[iter_7_0]

		if arg_7_0:type(var_7_1) == arg_7_1 then
			table.insert(var_7_0, var_7_1)
		end
	end

	return var_7_0 or {}
end

return var_0_0
