local var_0_0 = class("ActivityAnni4thGoldItemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.price_ = {}
	arg_1_0.speed_ = {}
	arg_1_0.multiple_ = {}
	arg_1_0.sequence_ = {}
	arg_1_0.height_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_4th_gold_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.speed_[var_2_0] = xyd.splitToNumber(arg_2_0.speed, "|")
		arg_1_0.multiple_[var_2_0] = tonumber(arg_2_0.multiple)
		arg_1_0.sequence_[var_2_0] = xyd.splitToNumber(arg_2_0.sequence, "|")
		arg_1_0.height_[var_2_0] = tonumber(arg_2_0.height)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.price(arg_5_0, arg_5_1)
	return arg_5_0.price_[arg_5_1] or 0
end

function var_0_0.speed(arg_6_0, arg_6_1)
	return arg_6_0.speed_[arg_6_1] or {}
end

function var_0_0.multiple(arg_7_0, arg_7_1)
	return arg_7_0.multiple_[arg_7_1] or 0
end

function var_0_0.sequence(arg_8_0, arg_8_1)
	return arg_8_0.sequence_[arg_8_1] or {}
end

function var_0_0.height(arg_9_0, arg_9_1)
	return arg_9_0.height_[arg_9_1] or 0
end

function var_0_0.getHeight(arg_10_0)
	return arg_10_0.height_ or {}
end

function var_0_0.getMultiple(arg_11_0)
	return arg_11_0.multiple_ or {}
end

function var_0_0.getSpeed(arg_12_0)
	return arg_12_0.speed_ or {}
end

return var_0_0
