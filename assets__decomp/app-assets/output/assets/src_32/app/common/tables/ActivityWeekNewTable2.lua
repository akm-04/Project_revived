local var_0_0 = class("ActivityWeekNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.scrollNum_ = {}

	import("app.common.tables.TableParser").parse("activity_week_new2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.scrollNum_[var_2_0] = tonumber(arg_2_0.scroll_num)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.scrollNum(arg_6_0, arg_6_1)
	return arg_6_0.scrollNum_[arg_6_1] or 0
end

return var_0_0
