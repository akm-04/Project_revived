local var_0_0 = class("ThirdAnniversaryMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.mesc_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.itemIds_ = {}
	arg_1_0.itemNums_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.mesc_[var_2_0] = arg_2_0.mesc
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)
		arg_1_0.itemIds_[var_2_0] = xyd.splitToNumber(arg_2_0.item_ids, "|")
		arg_1_0.itemNums_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.mesc(arg_5_0, arg_5_1)
	return arg_5_0.mesc_[arg_5_1] or ""
end

function var_0_0.condition(arg_6_0, arg_6_1)
	return arg_6_0.condition_[arg_6_1] or 0
end

function var_0_0.itemIds(arg_7_0, arg_7_1)
	return arg_7_0.itemIds_[arg_7_1] or {}
end

function var_0_0.itemNums(arg_8_0, arg_8_1)
	return arg_8_0.itemNums_[arg_8_1] or {}
end

return var_0_0
