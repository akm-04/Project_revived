local var_0_0 = class("ActivityLevelUpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.level_ = {}
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("activity_levelup.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.desc_[var_2_0] = arg_2_0.des
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or {}
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.gifts(arg_5_0)
	return arg_5_0.gift_ or {}
end

function var_0_0.level(arg_6_0, arg_6_1)
	return arg_6_0.level_[arg_6_1] or 0
end

function var_0_0.desc(arg_7_0, arg_7_1)
	return arg_7_0.desc_[arg_7_1] or ""
end

return var_0_0
