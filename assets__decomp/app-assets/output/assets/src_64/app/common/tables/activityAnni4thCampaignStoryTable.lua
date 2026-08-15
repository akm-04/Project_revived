local var_0_0 = class("activityAnni4thCampaignStoryTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.dialogueID_ = {}
	arg_1_0.typeID_ = {}
	arg_1_0.name_ = {}
	arg_1_0.buttonChoose_ = {}
	arg_1_0.dialog_ = {}
	arg_1_0.turnID_ = {}
	arg_1_0.position_ = {}
	arg_1_0.img_ = {}
	arg_1_0.expression_ = {}
	arg_1_0.storyIDs_ = {}

	import("app.common.tables.TableParser").parse("story1194.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.dialogueID_[var_2_0] = tonumber(arg_2_0.dialogue_id)
		arg_1_0.typeID_[var_2_0] = tonumber(arg_2_0.type_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.buttonChoose_[var_2_0] = arg_2_0.button_choose
		arg_1_0.dialog_[var_2_0] = arg_2_0.dialog
		arg_1_0.turnID_[var_2_0] = xyd.splitToNumber(arg_2_0.turn_id, "|")
		arg_1_0.position_[var_2_0] = tonumber(arg_2_0.position)
		arg_1_0.img_[var_2_0] = {}

		if arg_2_0.l_img ~= "" then
			table.insert(arg_1_0.img_[var_2_0], arg_2_0.l_img)
		end

		if arg_2_0.r_img ~= "" then
			table.insert(arg_1_0.img_[var_2_0], arg_2_0.r_img)
		end

		arg_1_0.expression_[var_2_0] = tonumber(arg_2_0.expression)

		if not arg_1_0.storyIDs_[arg_1_0.dialogueID_[var_2_0]] then
			arg_1_0.storyIDs_[arg_1_0.dialogueID_[var_2_0]] = {}
		end

		table.insert(arg_1_0.storyIDs_[arg_1_0.dialogueID_[var_2_0]], var_2_0)
	end)
end

function var_0_0.getStoryIDsByDialogueID(arg_3_0, arg_3_1)
	return arg_3_0.storyIDs_[arg_3_1]
end

function var_0_0.dialogueID(arg_4_0, arg_4_1)
	return arg_4_0.dialogueID_[arg_4_1]
end

function var_0_0.typeID(arg_5_0, arg_5_1)
	return arg_5_0.typeID_[arg_5_1]
end

function var_0_0.name(arg_6_0, arg_6_1)
	return arg_6_0.name_[arg_6_1]
end

function var_0_0.buttonChoose(arg_7_0, arg_7_1)
	return arg_7_0.buttonChoose_[arg_7_1]
end

function var_0_0.dialog(arg_8_0, arg_8_1)
	return arg_8_0.dialog_[arg_8_1]
end

function var_0_0.turnID(arg_9_0, arg_9_1)
	return arg_9_0.turnID_[arg_9_1] or {}
end

function var_0_0.position(arg_10_0, arg_10_1)
	return arg_10_0.position_[arg_10_1]
end

function var_0_0.img(arg_11_0, arg_11_1)
	return arg_11_0.img_[arg_11_1]
end

function var_0_0.expression(arg_12_0, arg_12_1)
	return arg_12_0.expression_[arg_12_1]
end

return var_0_0
