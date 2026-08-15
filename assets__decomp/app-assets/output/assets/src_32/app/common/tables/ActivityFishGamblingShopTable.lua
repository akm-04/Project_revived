local var_0_0 = class("ActivityFishGamblingShopTable")

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
	arg_1_0.slot7Drop_ = {}
	arg_1_0.slot7Rate_ = {}
	arg_1_0.slot8Drop_ = {}
	arg_1_0.slot8Rate_ = {}
	arg_1_0.slot9Drop_ = {}
	arg_1_0.slot9Rate_ = {}
	arg_1_0.slot10Drop_ = {}
	arg_1_0.slot10Rate_ = {}
	arg_1_0.slot11Drop_ = {}
	arg_1_0.slot11Rate_ = {}
	arg_1_0.slot12Drop_ = {}
	arg_1_0.slot12Rate_ = {}
	arg_1_0.slot13Drop_ = {}
	arg_1_0.slot13Rate_ = {}
	arg_1_0.slot14Drop_ = {}
	arg_1_0.slot14Rate_ = {}
	arg_1_0.slot15Drop_ = {}
	arg_1_0.slot15Rate_ = {}

	import("app.common.tables.TableParser").parse("activity_fish_gambling_shop.lua", function(arg_2_0)
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
		arg_1_0.slot7Drop_[var_2_0] = tonumber(arg_2_0.slot7_drop)
		arg_1_0.slot7Rate_[var_2_0] = tonumber(arg_2_0.slot7_rate)
		arg_1_0.slot8Drop_[var_2_0] = tonumber(arg_2_0.slot8_drop)
		arg_1_0.slot8Rate_[var_2_0] = tonumber(arg_2_0.slot8_rate)
		arg_1_0.slot9Drop_[var_2_0] = tonumber(arg_2_0.slot9_drop)
		arg_1_0.slot9Rate_[var_2_0] = tonumber(arg_2_0.slot9_rate)
		arg_1_0.slot10Drop_[var_2_0] = tonumber(arg_2_0.slot10_drop)
		arg_1_0.slot10Rate_[var_2_0] = tonumber(arg_2_0.slot10_rate)
		arg_1_0.slot11Drop_[var_2_0] = tonumber(arg_2_0.slot11_drop)
		arg_1_0.slot11Rate_[var_2_0] = tonumber(arg_2_0.slot11_rate)
		arg_1_0.slot12Drop_[var_2_0] = tonumber(arg_2_0.slot12_drop)
		arg_1_0.slot12Rate_[var_2_0] = tonumber(arg_2_0.slot12_rate)
		arg_1_0.slot13Drop_[var_2_0] = tonumber(arg_2_0.slot13_drop)
		arg_1_0.slot13Rate_[var_2_0] = tonumber(arg_2_0.slot13_rate)
		arg_1_0.slot14Drop_[var_2_0] = tonumber(arg_2_0.slot14_drop)
		arg_1_0.slot14Rate_[var_2_0] = tonumber(arg_2_0.slot14_rate)
		arg_1_0.slot15Drop_[var_2_0] = tonumber(arg_2_0.slot15_drop)
		arg_1_0.slot15Rate_[var_2_0] = tonumber(arg_2_0.slot15_rate)
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

function var_0_0.slot7Drop(arg_15_0, arg_15_1)
	return arg_15_0.slot7Drop_[arg_15_1] or 0
end

function var_0_0.slot7Rate(arg_16_0, arg_16_1)
	return arg_16_0.slot7Rate_[arg_16_1] or 0
end

function var_0_0.slot8Drop(arg_17_0, arg_17_1)
	return arg_17_0.slot8Drop_[arg_17_1] or 0
end

function var_0_0.slot8Rate(arg_18_0, arg_18_1)
	return arg_18_0.slot8Rate_[arg_18_1] or 0
end

function var_0_0.slot9Drop(arg_19_0, arg_19_1)
	return arg_19_0.slot9Drop_[arg_19_1] or 0
end

function var_0_0.slot9Rate(arg_20_0, arg_20_1)
	return arg_20_0.slot9Rate_[arg_20_1] or 0
end

function var_0_0.slot10Drop(arg_21_0, arg_21_1)
	return arg_21_0.slot10Drop_[arg_21_1] or 0
end

function var_0_0.slot10Rate(arg_22_0, arg_22_1)
	return arg_22_0.slot10Rate_[arg_22_1] or 0
end

function var_0_0.slot11Drop(arg_23_0, arg_23_1)
	return arg_23_0.slot11Drop_[arg_23_1] or 0
end

function var_0_0.slot11Rate(arg_24_0, arg_24_1)
	return arg_24_0.slot11Rate_[arg_24_1] or 0
end

function var_0_0.slot12Drop(arg_25_0, arg_25_1)
	return arg_25_0.slot12Drop_[arg_25_1] or 0
end

function var_0_0.slot12Rate(arg_26_0, arg_26_1)
	return arg_26_0.slot12Rate_[arg_26_1] or 0
end

function var_0_0.slot13Drop(arg_27_0, arg_27_1)
	return arg_27_0.slot13Drop_[arg_27_1] or 0
end

function var_0_0.slot13Rate(arg_28_0, arg_28_1)
	return arg_28_0.slot13Rate_[arg_28_1] or 0
end

function var_0_0.slot14Drop(arg_29_0, arg_29_1)
	return arg_29_0.slot14Drop_[arg_29_1] or 0
end

function var_0_0.slot14Rate(arg_30_0, arg_30_1)
	return arg_30_0.slot14Rate_[arg_30_1] or 0
end

function var_0_0.slot15Drop(arg_31_0, arg_31_1)
	return arg_31_0.slot15Drop_[arg_31_1] or 0
end

function var_0_0.slot15Rate(arg_32_0, arg_32_1)
	return arg_32_0.slot15Rate_[arg_32_1] or 0
end

return var_0_0
