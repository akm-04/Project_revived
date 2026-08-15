local var_0_0 = class("ThrowSandbagTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.partnerID_ = {}
	arg_1_0.name_ = {}
	arg_1_0.model_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.num_ = {}
	arg_1_0.collider_ = {}
	arg_1_0.group_ = {}
	arg_1_0.wij_ = {}
	arg_1_0.probability_ = {}
	arg_1_0.speed_ = {}

	import("app.common.tables.TableParser").parse("dodge_ball.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.partnerID_[var_2_0] = tonumber(arg_2_0.partner_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.collider_[var_2_0] = tonumber(arg_2_0.collider)
		arg_1_0.group_[var_2_0] = tonumber(arg_2_0.group)
		arg_1_0.wij_[var_2_0] = tonumber(arg_2_0.wij)
		arg_1_0.probability_[var_2_0] = tonumber(arg_2_0.probability)
		arg_1_0.speed_[var_2_0] = tonumber(arg_2_0.speed)
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1]
end

function var_0_0.partnerID(arg_4_0, arg_4_1)
	return arg_4_0.partnerID_[arg_4_1]
end

function var_0_0.name(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1]
end

function var_0_0.model(arg_6_0, arg_6_1)
	return arg_6_0.model_[arg_6_1]
end

function var_0_0.itemID(arg_7_0, arg_7_1)
	return arg_7_0.itemID_[arg_7_1]
end

function var_0_0.num(arg_8_0, arg_8_1)
	return arg_8_0.num_[arg_8_1]
end

function var_0_0.collider(arg_9_0, arg_9_1)
	return arg_9_0.collider_[arg_9_1]
end

function var_0_0.group(arg_10_0, arg_10_1)
	return arg_10_0.group_[arg_10_1]
end

function var_0_0.wij(arg_11_0, arg_11_1)
	return arg_11_0.wij_[arg_11_1]
end

function var_0_0.probability(arg_12_0, arg_12_1)
	return arg_12_0.probability_[arg_12_1]
end

function var_0_0.speed(arg_13_0, arg_13_1)
	return arg_13_0.speed_[arg_13_1]
end

return var_0_0
