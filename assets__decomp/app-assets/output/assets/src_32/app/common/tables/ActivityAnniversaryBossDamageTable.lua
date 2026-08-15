local var_0_0 = class("ActivityAnniversaryBossDamageTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.damage_ = {}
	arg_1_0.item_ = {}
	arg_1_0.num_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_boss_damage.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.damage_[var_2_0] = tonumber(arg_2_0.damage)
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
	end)
end

function var_0_0.damage(arg_3_0, arg_3_1)
	return arg_3_0.damage_[arg_3_1] or 0
end

function var_0_0.item(arg_4_0, arg_4_1)
	return arg_4_0.item_[arg_4_1] or 0
end

function var_0_0.num(arg_5_0, arg_5_1)
	return arg_5_0.num_[arg_5_1] or 0
end

function var_0_0.ids(arg_6_0, ...)
	return table.keys(arg_6_0.damage_)
end

return var_0_0
