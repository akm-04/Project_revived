local var_0_0 = class("ActivityMizhuTreasureTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.type_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.recharge_ = {}

	import("app.common.tables.TableParser").parse("activity_mizhu_treasure.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or ""
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.recharge(arg_5_0, arg_5_1)
	return arg_5_0.recharge_[arg_5_1] or 0
end

function var_0_0.getGiftsByType(arg_6_0, arg_6_1)
	local var_6_0 = {}

	for iter_6_0 = 1, #arg_6_0.ids_ do
		local var_6_1 = arg_6_0.ids_[iter_6_0]

		if arg_6_0:type(var_6_1) == arg_6_1 then
			table.insert(var_6_0, var_6_1)
		end
	end

	return var_6_0 or {}
end

return var_0_0
