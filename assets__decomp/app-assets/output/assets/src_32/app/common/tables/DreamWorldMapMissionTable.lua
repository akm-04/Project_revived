local var_0_0 = class("DreamWorldStoryTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.taskNum_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.title_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_story.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.taskNum_[var_2_0] = arg_2_0.task_num
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

return var_0_0
