local var_0_0 = class("DreamWorldDiaryTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.dialogueID_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_story_diary.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.item_id)

		arg_1_0.dialogueID_[var_2_0] = tonumber(arg_2_0.dialogue_id)
	end)
end

function var_0_0.dialogueID(arg_3_0, arg_3_1)
	return arg_3_0.dialogueID_[arg_3_1] or 0
end

return var_0_0
