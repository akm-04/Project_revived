local var_0_0 = class("ActivityFireworkTypeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.num_ = {}
	arg_1_0.startStage_ = {}
	arg_1_0.middleStage_ = {}
	arg_1_0.endStage_ = {}
	arg_1_0.sendTicket_ = {}
	arg_1_0.shotTicket_ = {}
	arg_1_0.fever_ = {}

	import("app.common.tables.TableParser").parse("activity_firework_type.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.startStage_[var_2_0] = tonumber(arg_2_0.start_stage)
		arg_1_0.middleStage_[var_2_0] = tonumber(arg_2_0.middle_stage)
		arg_1_0.endStage_[var_2_0] = tonumber(arg_2_0.end_stage)
		arg_1_0.sendTicket_[var_2_0] = tonumber(arg_2_0.send_ticket)
		arg_1_0.shotTicket_[var_2_0] = tonumber(arg_2_0.shot_ticket)
		arg_1_0.fever_[var_2_0] = tonumber(arg_2_0.fever)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.itemID(arg_6_0, arg_6_1)
	return arg_6_0.itemID_[arg_6_1] or 0
end

function var_0_0.recharge(arg_7_0, arg_7_1)
	return arg_7_0.recharge_[arg_7_1] or 0
end

function var_0_0.num(arg_8_0, arg_8_1)
	return arg_8_0.num_[arg_8_1] or 0
end

function var_0_0.startStage(arg_9_0)
	return arg_9_0.startStage_ or {}
end

function var_0_0.middleStage(arg_10_0, arg_10_1)
	return arg_10_0.middleStage_[arg_10_1] or 0
end

function var_0_0.endStage(arg_11_0, arg_11_1)
	return arg_11_0.endStage_[arg_11_1] or 0
end

function var_0_0.sendTicket(arg_12_0, arg_12_1)
	return arg_12_0.sendTicket_[arg_12_1] or 0
end

function var_0_0.shotTicket(arg_13_0, arg_13_1)
	return arg_13_0.shotTicket_[arg_13_1] or 0
end

function var_0_0.fever(arg_14_0, arg_14_1)
	return arg_14_0.fever_[arg_14_1] or 0
end

return var_0_0
