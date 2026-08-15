local var_0_0 = class("ActivityCultivateTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.day_ = {}
	arg_1_0.type_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.chargeId_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.stoneNums_ = {}
	arg_1_0.dayToid_ = {}
	arg_1_0.icon1_ = {}
	arg_1_0.icon2_ = {}
	arg_1_0.text1_ = {}
	arg_1_0.text2_ = {}

	import("app.common.tables.TableParser").parse("activity_cultivate.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.day_[var_2_0] = tonumber(arg_2_0.day)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)
		arg_1_0.chargeId_[var_2_0] = tonumber(arg_2_0.charge_id)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.stoneNums_[var_2_0] = tonumber(arg_2_0.stone_nums)
		arg_1_0.icon1_[var_2_0] = arg_2_0.icon1
		arg_1_0.icon2_[var_2_0] = arg_2_0.icon2
		arg_1_0.text1_[var_2_0] = arg_2_0.text1
		arg_1_0.text2_[var_2_0] = arg_2_0.text2

		if not arg_1_0.dayToid_[arg_1_0.day_[var_2_0]] then
			arg_1_0.dayToid_[arg_1_0.day_[var_2_0]] = {}
		end

		table.insert(arg_1_0.dayToid_[arg_1_0.day_[var_2_0]], var_2_0)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.day(arg_4_0, arg_4_1)
	return arg_4_0.day_[arg_4_1] or 0
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.condition(arg_6_0, arg_6_1)
	return arg_6_0.condition_[arg_6_1] or 0
end

function var_0_0.chargeId(arg_7_0, arg_7_1)
	return arg_7_0.chargeId_[arg_7_1] or 0
end

function var_0_0.gift(arg_8_0, arg_8_1)
	return arg_8_0.gift_[arg_8_1] or 0
end

function var_0_0.stoneNums(arg_9_0, arg_9_1)
	return arg_9_0.stoneNums_[arg_9_1] or 0
end

function var_0_0.getIdByDay(arg_10_0, arg_10_1)
	return arg_10_0.dayToid_[arg_10_1]
end

function var_0_0.icon1(arg_11_0, arg_11_1)
	return arg_11_0.icon1_[arg_11_1] or ""
end

function var_0_0.icon2(arg_12_0, arg_12_1)
	return arg_12_0.icon2_[arg_12_1] or ""
end

function var_0_0.text1(arg_13_0, arg_13_1)
	return arg_13_0.text1_[arg_13_1] or ""
end

function var_0_0.text2(arg_14_0, arg_14_1)
	return arg_14_0.text2_[arg_14_1] or ""
end

return var_0_0
