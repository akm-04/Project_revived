local var_0_0 = class("ZhugeEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.note_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.type_ = {}
	arg_1_0.branch_ = {}
	arg_1_0.branchRate_ = {}
	arg_1_0.firstGift_ = {}
	arg_1_0.damage_ = {}
	arg_1_0.model_ = {}

	import("app.common.tables.TableParser").parse("zhuge_event.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.note_[var_2_0] = arg_2_0.note
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.branch_[var_2_0] = xyd.splitToNumber(arg_2_0.branch, "|")
		arg_1_0.branchRate_[var_2_0] = xyd.splitToNumber(arg_2_0.branch_rate, "|")
		arg_1_0.firstGift_[var_2_0] = tonumber(arg_2_0.first_gift)
		arg_1_0.damage_[var_2_0] = tonumber(arg_2_0.damage)
		arg_1_0.model_[var_2_0] = xyd.splitToNumber(arg_2_0.model, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.note(arg_4_0, arg_4_1)
	return arg_4_0.note_[arg_4_1] or ""
end

function var_0_0.rate(arg_5_0, arg_5_1)
	return arg_5_0.rate_[arg_5_1] or 0
end

function var_0_0.type(arg_6_0, arg_6_1)
	return arg_6_0.type_[arg_6_1] or 0
end

function var_0_0.branch(arg_7_0, arg_7_1)
	return arg_7_0.branch_[arg_7_1] or {}
end

function var_0_0.branchRate(arg_8_0, arg_8_1)
	return arg_8_0.branchRate_[arg_8_1] or {}
end

function var_0_0.firstGift(arg_9_0, arg_9_1)
	return arg_9_0.firstGift_[arg_9_1] or 0
end

function var_0_0.damage(arg_10_0, arg_10_1)
	return arg_10_0.damage_[arg_10_1] or 0
end

function var_0_0.model(arg_11_0, arg_11_1)
	return arg_11_0.model_[arg_11_1] or {}
end

return var_0_0
