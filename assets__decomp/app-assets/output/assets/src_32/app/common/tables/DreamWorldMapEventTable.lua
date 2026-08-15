local var_0_0 = class("DreamWorldMapEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.cellID_ = {}
	arg_1_0.eventType_ = {}
	arg_1_0.battleID_ = {}
	arg_1_0.giftID_ = {}
	arg_1_0.dialogueID_ = {}

	import("app.common.tables.TableParser").parse("dreamworld_map_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.event_id)

		arg_1_0.cellID_[var_2_0] = tonumber(arg_2_0.cell_id)
		arg_1_0.eventType_[var_2_0] = tonumber(arg_2_0.event_type)
		arg_1_0.battleID_[var_2_0] = {}

		table.insert(arg_1_0.battleID_[var_2_0], tonumber(arg_2_0.battle_id))
		table.insert(arg_1_0.battleID_[var_2_0], tonumber(arg_2_0.hard_battle_id))

		arg_1_0.giftID_[var_2_0] = {}

		table.insert(arg_1_0.giftID_[var_2_0], tonumber(arg_2_0.gift_id))
		table.insert(arg_1_0.giftID_[var_2_0], tonumber(arg_2_0.hard_gift_id))

		arg_1_0.dialogueID_[var_2_0] = tonumber(arg_2_0.dialogue_id)
	end)
end

function var_0_0.cellID(arg_3_0, arg_3_1)
	return arg_3_0.cellID_[arg_3_1] or 0
end

function var_0_0.eventType(arg_4_0, arg_4_1)
	return arg_4_0.eventType_[arg_4_1] or 0
end

function var_0_0.battleID(arg_5_0, arg_5_1)
	return arg_5_0.battleID_[arg_5_1] or {}
end

function var_0_0.giftID(arg_6_0, arg_6_1)
	return arg_6_0.giftID_[arg_6_1] or {}
end

function var_0_0.dialogueID(arg_7_0, arg_7_1)
	return arg_7_0.dialogueID_[arg_7_1] or 0
end

return var_0_0
