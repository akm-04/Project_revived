local var_0_0 = class("EventCentreTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.maxLev_ = {}

	import("app.common.tables.TableParser").parse("event_centre.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.maxLev_[var_2_0] = tonumber(arg_2_0.max_level)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.icon(arg_4_0, arg_4_1)
	return arg_4_0.icon_[arg_4_1]
end

function var_0_0.maxLev(arg_5_0, arg_5_1)
	return arg_5_0.maxLev_[arg_5_1]
end

return var_0_0
