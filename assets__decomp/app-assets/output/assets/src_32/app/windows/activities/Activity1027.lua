local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:christmasLayout(arg_2_0.activity)
end

function var_0_0.christmasLayout(arg_3_0, arg_3_1)
	local var_3_0 = xyd.tables.activities:cutOffTime(arg_3_1.table_id)
	local var_3_1
	local var_3_2

	if arg_3_1.details and arg_3_1.details.start_time then
		var_3_1 = arg_3_1.details.start_time
	else
		var_3_1 = arg_3_1.start_time
	end

	if arg_3_1.details and arg_3_1.details.start_time then
		var_3_2 = arg_3_1.details.end_time
	else
		var_3_2 = arg_3_1.end_time
	end

	arg_3_0.parent:removeAllChildren()

	local var_3_3 = "christmas_activity"
	local var_3_4 = import("app.windows." .. xyd.tables.window:className(var_3_3)).new(var_3_3, {
		startTime = var_3_1,
		endTime = var_3_2
	})

	var_3_4:addTo(arg_3_0.parent)
	var_3_4:align(display.LEFT_BOTTOM, 0, -20)
	var_3_4:layout()
	var_3_4:random()

	arg_3_0.christmasLayout_ = var_3_4

	arg_3_0.parent:setTouchSwallowEnabled(false)
end

function var_0_0.getChristmasLayout(arg_4_0)
	if arg_4_0.christmasLayout_ and not tolua.isnull(arg_4_0.christmasLayout_) then
		return arg_4_0.christmasLayout_
	end

	return nil
end

return var_0_0
