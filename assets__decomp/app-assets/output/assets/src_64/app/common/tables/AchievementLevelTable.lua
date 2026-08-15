local var_0_0 = class("AchievementLevelTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.pointCondition_ = {}
	arg_1_0.levelName_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.items_ = {}
	arg_1_0.itemNums_ = {}
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("achievement_level.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.pointCondition_[var_2_0] = tonumber(arg_2_0.point_condition)
		arg_1_0.levelName_[var_2_0] = arg_2_0.level_name
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.items_[var_2_0] = xyd.splitToNumber(arg_2_0.items, "|")
		arg_1_0.itemNums_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
	end)
end

function var_0_0.pointCondition(arg_3_0, arg_3_1)
	return arg_3_0.pointCondition_[arg_3_1] or 0
end

function var_0_0.levelName(arg_4_0, arg_4_1)
	return arg_4_0.levelName_[arg_4_1] or ""
end

function var_0_0.icon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.items(arg_6_0, arg_6_1)
	if #arg_6_0.items_[arg_6_1] <= 0 or arg_6_0.items_[arg_6_1][1] == 0 then
		return {}
	end

	return arg_6_0.items_[arg_6_1] or {}
end

function var_0_0.isMaxCanAwardLev(arg_7_0, arg_7_1)
	if arg_7_0.items_[arg_7_1][1] >= 0 and arg_7_0.items_[arg_7_1 + 1] and arg_7_0.items_[arg_7_1 + 1][1] == 0 or not arg_7_0.items_[arg_7_1 + 1] then
		return true
	end

	return false
end

function var_0_0.itemNums(arg_8_0, arg_8_1)
	return arg_8_0.itemNums_[arg_8_1] or {}
end

function var_0_0.desc(arg_9_0, arg_9_1)
	return arg_9_0.desc_[arg_9_1]
end

function var_0_0.maxLev(arg_10_0, arg_10_1)
	return #arg_10_0.pointCondition_
end

function var_0_0.getLevByPoint(arg_11_0, arg_11_1)
	local var_11_0 = 1

	for iter_11_0 = 1, #arg_11_0.pointCondition_ do
		if arg_11_1 >= arg_11_0.pointCondition_[iter_11_0] then
			var_11_0 = iter_11_0
		end
	end

	return var_11_0
end

return var_0_0
