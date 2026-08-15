local var_0_0 = class("AllNightBossMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.damage_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.title_ = {}
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("activity_polar_night_damage.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.damage_[var_2_0] = tonumber(arg_2_0.damage)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.title_[var_2_0] = arg_2_0.task_title
		arg_1_0.desc_[var_2_0] = arg_2_0.task_dsc
	end)
end

function var_0_0.damage(arg_3_0, arg_3_1)
	return arg_3_0.damage_[arg_3_1]
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1]
end

function var_0_0.title(arg_5_0, arg_5_1)
	return arg_5_0.title_[arg_5_1]
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1]
end

return var_0_0
