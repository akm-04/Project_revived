local var_0_0 = class("PracticeLockTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.lock_style_ = {}
	arg_1_0.mana_ = {}
	arg_1_0.crystal_ = {}
	arg_1_0.bless_num_ = {}
	arg_1_0.up_limit_ = {}

	import("app.common.tables.TableParser").parse("practice_lock.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.lock_style_[var_2_0] = arg_2_0.lock_style
		arg_1_0.mana_[var_2_0] = tonumber(arg_2_0.mana)
		arg_1_0.crystal_[var_2_0] = tonumber(arg_2_0.crystal)
		arg_1_0.bless_num_[var_2_0] = tonumber(arg_2_0.bless_num)
		arg_1_0.up_limit_[var_2_0] = tonumber(arg_2_0.up_limit)
	end)
end

function var_0_0.lockStyle(arg_3_0, arg_3_1)
	return arg_3_0.lock_style_[arg_3_1] or nil
end

function var_0_0.getMana(arg_4_0, arg_4_1)
	return arg_4_0.mana_[arg_4_1]
end

function var_0_0.getCryStal(arg_5_0, arg_5_1)
	return arg_5_0.crystal_[arg_5_1] or 0
end

function var_0_0.getBlessNum(arg_6_0, arg_6_1)
	return arg_6_0.bless_num_[arg_6_1] or 0
end

function var_0_0.getUpLimie(arg_7_0, arg_7_1)
	return arg_7_0.up_limit_[arg_7_1] or 0
end

return var_0_0
