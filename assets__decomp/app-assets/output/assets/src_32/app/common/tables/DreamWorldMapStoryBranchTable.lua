local var_0_0 = class("DreamWorldMapStoryBranchTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.replaceDialogue_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_story_branch.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.main_id)

		if not arg_1_0.replaceDialogue_[var_2_0] then
			arg_1_0.replaceDialogue_[var_2_0] = {}
		end

		local var_2_1 = {
			replaceID = tonumber(arg_2_0.dialogue_id),
			characterID = xyd.splitToNumber(arg_2_0.favor_character, "|"),
			favorMin = xyd.splitToNumber(arg_2_0.favor_min, "|")
		}

		table.insert(arg_1_0.replaceDialogue_[var_2_0], var_2_1)
	end)
end

function var_0_0.getReplaceDialogueID(arg_3_0, arg_3_1)
	return arg_3_0.replaceDialogue_[arg_3_1] or {}
end

return var_0_0
