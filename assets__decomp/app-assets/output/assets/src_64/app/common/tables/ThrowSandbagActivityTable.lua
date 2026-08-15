local var_0_0 = class("ThrowSandbagActivityTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.type_ = {}
	arg_1_0.prob_ = {}
	arg_1_0.effectNum_ = {}
	arg_1_0.pic_ = {}
	arg_1_0.subTitle_ = {}

	import("app.common.tables.TableParser").parse("dodge_activity.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.act_id)

		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.activity_type)
		arg_1_0.prob_[var_2_0] = tonumber(arg_2_0.prop_up)
		arg_1_0.effectNum_[var_2_0] = tonumber(arg_2_0.effect_num)
		arg_1_0.pic_[var_2_0] = arg_2_0.pic
		arg_1_0.subTitle_[var_2_0] = arg_2_0.sub_title
	end)
end

function var_0_0.type(arg_3_0, arg_3_1)
	return arg_3_0.type_[arg_3_1]
end

function var_0_0.prob(arg_4_0, arg_4_1)
	return arg_4_0.prob_[arg_4_1]
end

function var_0_0.effectNum(arg_5_0, arg_5_1)
	return arg_5_0.effectNum_[arg_5_1]
end

function var_0_0.pic(arg_6_0, arg_6_1)
	return arg_6_0.pic_[arg_6_1]
end

function var_0_0.subTitle(arg_7_0, arg_7_1)
	return arg_7_0.subTitle_[arg_7_1]
end

return var_0_0
