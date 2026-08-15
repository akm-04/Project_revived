local var_0_0 = class("ZhugeMazeEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.choice_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.enemyAlert_ = {}

	import("app.common.tables.TableParser").parse("zhuge_maze_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.choice_[var_2_0] = xyd.split(arg_2_0.choice, "|")
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.dialog_[var_2_0] = xyd.splitToNumber(arg_2_0.dialog, "|")
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.enemyAlert_[var_2_0] = tonumber(arg_2_0.enemy_alert)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.choice(arg_5_0, arg_5_1)
	return arg_5_0.choice_[arg_5_1] or {}
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

function var_0_0.dialog(arg_7_0, arg_7_1)
	return arg_7_0.dialog_[arg_7_1] or {}
end

function var_0_0.icon(arg_8_0, arg_8_1)
	return arg_8_0.icon_[arg_8_1] or ""
end

function var_0_0.enemyAlert(arg_9_0, arg_9_1)
	return arg_9_0.enemyAlert_[arg_9_1] or 0
end

return var_0_0
