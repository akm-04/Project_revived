local var_0_0 = class("DreamWorldMapCellTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.resID_ = {}
	arg_1_0.resScale_ = {}
	arg_1_0.resPosX_ = {}
	arg_1_0.resPosY_ = {}
	arg_1_0.model_ = {}
	arg_1_0.modelScale_ = {}
	arg_1_0.modelDialogue_ = {}
	arg_1_0.events_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_map_cell.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.resID_[var_2_0] = xyd.splitToNumber(arg_2_0.resource_id, "|")
		arg_1_0.resScale_[var_2_0] = xyd.splitToNumber(arg_2_0.resource_scale, "|")
		arg_1_0.resPosX_[var_2_0] = xyd.splitToNumber(arg_2_0.resource_pos_x, "|")
		arg_1_0.resPosY_[var_2_0] = xyd.splitToNumber(arg_2_0.resource_pos_y, "|")
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.modelScale_[var_2_0] = tonumber(arg_2_0.scale)
		arg_1_0.modelDialogue_[var_2_0] = arg_2_0.model_dialogue
		arg_1_0.events_[var_2_0] = xyd.splitToNumber(arg_2_0.events, "|")
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1] or 0
end

function var_0_0.resID(arg_4_0, arg_4_1)
	return arg_4_0.resID_[arg_4_1] or {}
end

function var_0_0.resScale(arg_5_0, arg_5_1)
	return arg_5_0.resScale_[arg_5_1] or {}
end

function var_0_0.resPosX(arg_6_0, arg_6_1)
	return arg_6_0.resPosX_[arg_6_1] or {}
end

function var_0_0.resPosY(arg_7_0, arg_7_1)
	return arg_7_0.resPosY_[arg_7_1] or {}
end

function var_0_0.model(arg_8_0, arg_8_1)
	return arg_8_0.model_[arg_8_1] or 0
end

function var_0_0.modelScale(arg_9_0, arg_9_1)
	return arg_9_0.modelScale_[arg_9_1] or 0
end

function var_0_0.modelDialogue(arg_10_0, arg_10_1)
	return arg_10_0.modelDialogue_[arg_10_1] or ""
end

function var_0_0.events(arg_11_0, arg_11_1)
	return arg_11_0.events_[arg_11_1] or 0
end

return var_0_0
