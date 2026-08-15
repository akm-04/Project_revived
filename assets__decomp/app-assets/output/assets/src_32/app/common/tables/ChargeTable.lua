local var_0_0 = class("ChargeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.nameNew_ = {}
	arg_1_0.doubleName_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.extraDiamond_ = {}
	arg_1_0.firstExtraDiamond_ = {}
	arg_1_0.monthCard_ = {}
	arg_1_0.iconUrl_ = {}
	arg_1_0.iconNew_ = {}
	arg_1_0.recommend_ = {}
	arg_1_0.firstRecommend_ = {}
	arg_1_0.chargeIds_ = {}
	arg_1_0.iosProductID_ = {}
	arg_1_0.monthCardSort_ = {}
	arg_1_0.isPrivilege_ = {}
	arg_1_0.privilegeIds_ = {}
	arg_1_0.cardType_ = {}
	arg_1_0.showType_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.beforeId_ = {}

	import("app.common.tables.TableParser").parse("charge.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)
		local var_2_1 = tonumber(arg_2_0.show_type)
		local var_2_2 = tonumber(arg_2_0.is_privilege)

		if var_2_1 == 0 and var_2_2 == 0 and (device.platform ~= "ios" or var_2_0 ~= 80001030) then
			table.insert(arg_1_0.chargeIds_, var_2_0)
		end

		if var_2_2 == 1 then
			table.insert(arg_1_0.privilegeIds_, var_2_0)
		end

		local var_2_3 = tonumber(arg_2_0.discount_charge_id)

		if var_2_3 ~= 0 then
			arg_1_0.beforeId_[var_2_3] = var_2_0
		end

		arg_1_0.isPrivilege_[var_2_0] = tonumber(arg_2_0.is_privilege)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.nameNew_[var_2_0] = string.gsub(arg_2_0.name_new, "|", "\n")
		arg_1_0.doubleName_[var_2_0] = arg_2_0.first_charge_name
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.firstExtraDiamond_[var_2_0] = tonumber(arg_2_0.first_extra_diamond)
		arg_1_0.extraDiamond_[var_2_0] = tonumber(arg_2_0.extra_diamond)
		arg_1_0.monthCard_[var_2_0] = tonumber(arg_2_0.month_card)
		arg_1_0.monthCardSort_[var_2_0] = tonumber(arg_2_0.month_card_sort)
		arg_1_0.iconUrl_[var_2_0] = arg_2_0.icon
		arg_1_0.iconNew_[var_2_0] = arg_2_0.icon_new
		arg_1_0.recommend_[var_2_0] = tonumber(arg_2_0.recommend)
		arg_1_0.firstRecommend_[var_2_0] = tonumber(arg_2_0.first_recommend)
		arg_1_0.iosProductID_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.cardType_[var_2_0] = tonumber(arg_2_0.card_type)
		arg_1_0.showType_[var_2_0] = tonumber(arg_2_0.show_type)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
	end)
end

function var_0_0.getChargeIds(arg_3_0)
	return arg_3_0.chargeIds_ or {}
end

function var_0_0.getPrivilegeIds(arg_4_0)
	return arg_4_0.privilegeIds_ or {}
end

function var_0_0.showType(arg_5_0, arg_5_1)
	return arg_5_0.showType_[arg_5_1] or 1
end

function var_0_0.beforeId(arg_6_0, arg_6_1)
	return arg_6_0.beforeId_[arg_6_1] or 0
end

function var_0_0.isPrivilege(arg_7_0, arg_7_1)
	return arg_7_0.isPrivilege_[arg_7_1] or 0
end

function var_0_0.chargeId(arg_8_0, arg_8_1)
	return arg_8_0.chargeIds_[arg_8_1]
end

function var_0_0.chargeName(arg_9_0, arg_9_1)
	return arg_9_0.name_[arg_9_1] or 0
end

function var_0_0.chargeNameNew(arg_10_0, arg_10_1)
	return arg_10_0.nameNew_[arg_10_1] or 0
end

function var_0_0.chargeDoubleName(arg_11_0, arg_11_1)
	return arg_11_0.doubleName_[arg_11_1] or 0
end

function var_0_0.charge(arg_12_0, arg_12_1)
	return arg_12_0.charge_[arg_12_1] or 0
end

function var_0_0.diamond(arg_13_0, arg_13_1)
	return arg_13_0.diamond_[arg_13_1] or 0
end

function var_0_0.extraDiamond(arg_14_0, arg_14_1)
	return arg_14_0.extraDiamond_[arg_14_1] or 0
end

function var_0_0.firstExtraDiamond(arg_15_0, arg_15_1)
	return arg_15_0.firstExtraDiamond_[arg_15_1] or 0
end

function var_0_0.monthCard(arg_16_0, arg_16_1)
	return arg_16_0.monthCard_[arg_16_1] or 0
end

function var_0_0.monthCardSort(arg_17_0, arg_17_1)
	return arg_17_0.monthCardSort_[arg_17_1] or 0
end

function var_0_0.iconUrl(arg_18_0, arg_18_1)
	return arg_18_0.iconUrl_[arg_18_1] or 0
end

function var_0_0.iconNew(arg_19_0, arg_19_1)
	return arg_19_0.iconNew_[arg_19_1] or 0
end

function var_0_0.recommend(arg_20_0, arg_20_1)
	return arg_20_0.recommend_[arg_20_1] or 0
end

function var_0_0.firstRecommend(arg_21_0, arg_21_1)
	return arg_21_0.firstRecommend_[arg_21_1] or 0
end

function var_0_0.iosProductID(arg_22_0, arg_22_1)
	return arg_22_0.iosProductID_[arg_22_1] or 0
end

function var_0_0.cardType(arg_23_0, arg_23_1)
	return arg_23_0.cardType_[arg_23_1] or 0
end

function var_0_0.buyLimit(arg_24_0, arg_24_1)
	return arg_24_0.buyLimit_[arg_24_1] or 0
end

return var_0_0
