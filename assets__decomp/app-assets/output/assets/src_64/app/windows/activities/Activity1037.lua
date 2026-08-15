local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:SpringDialLayout(arg_2_0.activity)
end

function var_0_0.SpringDialLayout(arg_3_0, arg_3_1)
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

	if arg_3_1.details and arg_3_1.details.times and not arg_3_0.springDialTimes then
		arg_3_0.springDialTimes = arg_3_1.details.times
	end

	if arg_3_1.details and arg_3_1.details.lucky_star then
		arg_3_0.lucky_star = arg_3_1.details.lucky_star
	end

	arg_3_0.parent:removeAllChildren()

	local var_3_3 = "spring_dial_activity"
	local var_3_4 = {
		startTime = var_3_1,
		endTime = var_3_2,
		leftTimes = arg_3_0.springDialTimes,
		table_id = arg_3_1.table_id,
		is_open = arg_3_1.is_open
	}

	if arg_3_0.lucky_star then
		var_3_4.lucky_star = arg_3_0.lucky_star
	end

	local var_3_5 = import("app.windows." .. xyd.tables.window:className(var_3_3)).new(var_3_3, var_3_4)

	var_3_5:addTo(arg_3_0.parent)
	var_3_5:loadRes()
	var_3_5:align(display.LEFT_BOTTOM, -20, -13)
	var_3_5:layout()

	arg_3_0.springDialLayout_ = var_3_5
end

return var_0_0
