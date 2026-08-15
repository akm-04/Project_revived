local var_0_0 = class("ActivityMizhuTreasureNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.gifts_ = {}
	arg_1_0.names_ = {}

	for iter_1_0 = 1, 3 do
		arg_1_0.gifts_[iter_1_0] = {}
		arg_1_0.names_[iter_1_0] = {}
	end

	import("app.common.tables.TableParser").parse("activity_mizhu_treasure_new.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.gifts_[1][var_2_0] = tonumber(arg_2_0.gift1)
		arg_1_0.gifts_[2][var_2_0] = tonumber(arg_2_0.gift2)
		arg_1_0.gifts_[3][var_2_0] = tonumber(arg_2_0.gift3)
		arg_1_0.names_[1][var_2_0] = arg_2_0.name1
		arg_1_0.names_[2][var_2_0] = arg_2_0.name2
		arg_1_0.names_[3][var_2_0] = arg_2_0.name3
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.recharge(arg_4_0, arg_4_1)
	return arg_4_0.recharge_[arg_4_1] or 0
end

function var_0_0.gift(arg_5_0, arg_5_1, arg_5_2)
	return arg_5_0.gifts_[arg_5_1][arg_5_2] or 0
end

function var_0_0.name(arg_6_0, arg_6_1, arg_6_2)
	return arg_6_0.names_[arg_6_1][arg_6_2] or ""
end

return var_0_0
