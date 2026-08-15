local var_0_0 = class("DreamWorldTaskTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.taskNum_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.title_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.taskNum_[var_2_0] = tonumber(arg_2_0.task_num)
		arg_1_0.item_[var_2_0] = {}

		table.insert(arg_1_0.item_[var_2_0], tonumber(arg_2_0.item))
		table.insert(arg_1_0.item_[var_2_0], tonumber(arg_2_0.hard_item))

		arg_1_0.itemNum_[var_2_0] = {}

		table.insert(arg_1_0.itemNum_[var_2_0], tonumber(arg_2_0.item_num))
		table.insert(arg_1_0.itemNum_[var_2_0], tonumber(arg_2_0.hard_item_num))

		arg_1_0.title_[var_2_0] = {}

		table.insert(arg_1_0.title_[var_2_0], tonumber(arg_2_0.title))
		table.insert(arg_1_0.title_[var_2_0], tonumber(arg_2_0.hard_title))
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.taskNum(arg_5_0, arg_5_1)
	return arg_5_0.taskNum_[arg_5_1] or 0
end

function var_0_0.item(arg_6_0, arg_6_1)
	return arg_6_0.item_[arg_6_1] or {}
end

function var_0_0.itemNum(arg_7_0, arg_7_1)
	return arg_7_0.itemNum_[arg_7_1] or {}
end

function var_0_0.title(arg_8_0, arg_8_1)
	return arg_8_0.title_[arg_8_1] or {}
end

return var_0_0
