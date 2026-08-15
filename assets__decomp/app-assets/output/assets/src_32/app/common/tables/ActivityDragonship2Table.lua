local var_0_0 = class("ActivityDragonship2Table")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.des_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_dragonship2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.des_[var_2_0] = arg_2_0.des
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.crystal(arg_4_0, arg_4_1)
	return arg_4_0.crystal_[arg_4_1] or 0
end

function var_0_0.des(arg_5_0, arg_5_1)
	return arg_5_0.des_[arg_5_1] or ""
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

function var_0_0.getBoatNums(arg_7_0)
	return #arg_7_0.name_ or 0
end

return var_0_0
