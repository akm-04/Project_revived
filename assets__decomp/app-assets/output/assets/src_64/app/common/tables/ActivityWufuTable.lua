local var_0_0 = class("NewYearBlessingMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.num_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.model_ = {}
	arg_1_0.word_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("activity_newyear_blessing.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.word_[var_2_0] = arg_2_0.word
		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1]
end

function var_0_0.num(arg_4_0, arg_4_1)
	return arg_4_0.num_[arg_4_1]
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1]
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1]
end

function var_0_0.model(arg_7_0, arg_7_1)
	return arg_7_0.model_[arg_7_1]
end

function var_0_0.word(arg_8_0, arg_8_1)
	return arg_8_0.word_[arg_8_1]
end

function var_0_0.name(arg_9_0, arg_9_1)
	return arg_9_0.name_[arg_9_1]
end

return var_0_0
