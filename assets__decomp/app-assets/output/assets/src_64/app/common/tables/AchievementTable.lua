local var_0_0 = class("AchievementTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.points_ = {}
	arg_1_0.isDailyUpdate_ = {}
	arg_1_0.tip_ = {}
	arg_1_0.isHide_ = {}
	arg_1_0.stamp_ = {}

	import("app.common.tables.TableParser").parse("achievement.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.condition_[var_2_0] = xyd.splitToNumber(arg_2_0.condition, "|")
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.points_[var_2_0] = xyd.splitToNumber(arg_2_0.points, "|")
		arg_1_0.isDailyUpdate_[var_2_0] = tonumber(arg_2_0.is_daily_update)
		arg_1_0.tip_[var_2_0] = arg_2_0.tip
		arg_1_0.isHide_[var_2_0] = tonumber(arg_2_0.is_hide)
		arg_1_0.stamp_[var_2_0] = tonumber(arg_2_0.stamp)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.condition(arg_5_0, arg_5_1)
	return arg_5_0.condition_[arg_5_1] or 0
end

function var_0_0.icon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or ""
end

function var_0_0.points(arg_7_0, arg_7_1)
	return arg_7_0.points_[arg_7_1] or 0
end

function var_0_0.isDailyUpdate(arg_8_0, arg_8_1)
	return arg_8_0.isDailyUpdate_[arg_8_1] or 0
end

function var_0_0.tip(arg_9_0, arg_9_1)
	return arg_9_0.tip_[arg_9_1] or ""
end

function var_0_0.isHide(arg_10_0, arg_10_1)
	return arg_10_0.isHide_[arg_10_1] or 0
end

function var_0_0.stamp(arg_11_0, arg_11_1)
	return arg_11_0.stamp_[arg_11_1] or 0
end

return var_0_0
