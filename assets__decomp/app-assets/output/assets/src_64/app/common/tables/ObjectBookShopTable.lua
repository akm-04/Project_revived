local var_0_0 = class("ObjectBookShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.slot1Drop_ = {}
	arg_1_0.slot1Rate_ = {}
	arg_1_0.slot2Drop_ = {}
	arg_1_0.slot2Rate_ = {}
	arg_1_0.slot3Drop_ = {}
	arg_1_0.slot3Rate_ = {}
	arg_1_0.slot4Drop_ = {}
	arg_1_0.slot4Rate_ = {}
	arg_1_0.slot5Drop_ = {}
	arg_1_0.slot5Rate_ = {}
	arg_1_0.slot6Drop_ = {}
	arg_1_0.slot6Rate_ = {}

	import("app.common.tables.TableParser").parse("object_book_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.slot1Drop_[var_2_0] = tonumber(arg_2_0.slot1_drop)
		arg_1_0.slot1Rate_[var_2_0] = tonumber(arg_2_0.slot1_rate)
		arg_1_0.slot2Drop_[var_2_0] = tonumber(arg_2_0.slot2_drop)
		arg_1_0.slot2Rate_[var_2_0] = tonumber(arg_2_0.slot2_rate)
		arg_1_0.slot3Drop_[var_2_0] = tonumber(arg_2_0.slot3_drop)
		arg_1_0.slot3Rate_[var_2_0] = tonumber(arg_2_0.slot3_rate)
		arg_1_0.slot4Drop_[var_2_0] = tonumber(arg_2_0.slot4_drop)
		arg_1_0.slot4Rate_[var_2_0] = tonumber(arg_2_0.slot4_rate)
		arg_1_0.slot5Drop_[var_2_0] = tonumber(arg_2_0.slot5_drop)
		arg_1_0.slot5Rate_[var_2_0] = tonumber(arg_2_0.slot5_rate)
		arg_1_0.slot6Drop_[var_2_0] = tonumber(arg_2_0.slot6_drop)
		arg_1_0.slot6Rate_[var_2_0] = tonumber(arg_2_0.slot6_rate)
	end)
end

function var_0_0.slot1Drop(arg_3_0, arg_3_1)
	return arg_3_0.slot1Drop_[arg_3_1] or 0
end

function var_0_0.slot1Rate(arg_4_0, arg_4_1)
	return arg_4_0.slot1Rate_[arg_4_1] or 0
end

function var_0_0.slot2Drop(arg_5_0, arg_5_1)
	return arg_5_0.slot2Drop_[arg_5_1] or 0
end

function var_0_0.slot2Rate(arg_6_0, arg_6_1)
	return arg_6_0.slot2Rate_[arg_6_1] or 0
end

function var_0_0.slot3Drop(arg_7_0, arg_7_1)
	return arg_7_0.slot3Drop_[arg_7_1] or 0
end

function var_0_0.slot3Rate(arg_8_0, arg_8_1)
	return arg_8_0.slot3Rate_[arg_8_1] or 0
end

function var_0_0.slot4Drop(arg_9_0, arg_9_1)
	return arg_9_0.slot4Drop_[arg_9_1] or 0
end

function var_0_0.slot4Rate(arg_10_0, arg_10_1)
	return arg_10_0.slot4Rate_[arg_10_1] or 0
end

function var_0_0.slot5Drop(arg_11_0, arg_11_1)
	return arg_11_0.slot5Drop_[arg_11_1] or 0
end

function var_0_0.slot5Rate(arg_12_0, arg_12_1)
	return arg_12_0.slot5Rate_[arg_12_1] or 0
end

function var_0_0.slot6Drop(arg_13_0, arg_13_1)
	return arg_13_0.slot6Drop_[arg_13_1] or 0
end

function var_0_0.slot6Rate(arg_14_0, arg_14_1)
	return arg_14_0.slot6Rate_[arg_14_1] or 0
end

return var_0_0
