local var_0_0 = class("ActivityZongZiTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gifts_ = {}
	arg_1_0.times_ = {}

	import("app.common.tables.TableParser").parse("activity_zongzi.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gifts_[var_2_0] = arg_2_0.gifts
		arg_1_0.times_[var_2_0] = arg_2_0.time
	end)
end

function var_0_0.gifts(arg_3_0, arg_3_1)
	return arg_3_0.gifts_[arg_3_1] or ""
end

function var_0_0.times(arg_4_0, arg_4_1)
	return arg_4_0.times_[arg_4_1] or ""
end

return var_0_0
