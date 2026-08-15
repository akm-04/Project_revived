local var_0_0 = class("WidgetTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.classNames_ = {}
	arg_1_0.resources_ = {}
	arg_1_0.canTouch_ = {}

	import("app.common.tables.TableParser").parse("widget.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.name

		arg_1_0.classNames_[var_2_0] = arg_2_0.class
		arg_1_0.resources_[var_2_0] = arg_2_0.res
		arg_1_0.canTouch_[var_2_0] = tonumber(arg_2_0.can_touch)
	end)
end

function var_0_0.hasWidget(arg_3_0, arg_3_1)
	return arg_3_0.classNames_[arg_3_1] ~= nil
end

function var_0_0.className(arg_4_0, arg_4_1)
	return arg_4_0.classNames_[arg_4_1]
end

function var_0_0.resource(arg_5_0, arg_5_1)
	return arg_5_0.resources_[arg_5_1]
end

function var_0_0.canTouch(arg_6_0, arg_6_1)
	return (arg_6_0.canTouch_[arg_6_1] or 0) == 0
end

return var_0_0
