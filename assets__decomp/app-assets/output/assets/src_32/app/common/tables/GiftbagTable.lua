local var_0_0 = class("GiftbagTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.nameNew_ = {}
	arg_1_0.type_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.originalCharge_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.startTime_ = {}
	arg_1_0.time_ = {}
	arg_1_0.requireCharge_ = {}
	arg_1_0.nextCharge_ = {}
	arg_1_0.totalValue_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.iconNew_ = {}
	arg_1_0.banner_ = {}
	arg_1_0.title_ = {}
	arg_1_0.iosProductID_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.recommend_ = {}
	arg_1_0.chargeIds_ = {}
	arg_1_0.seque_ = {}
	arg_1_0.page_ = {}
	arg_1_0.isNew = {}
	arg_1_0.lastShowTime2 = 0
	arg_1_0.lastShowTime3 = 0
	arg_1_0.discribe_ = {}

	import("app.common.tables.TableParser").parse("giftbag.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.charge_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.nameNew_[var_2_0] = string.gsub(arg_2_0.name_new, "|", "\n")
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.originalCharge_[var_2_0] = tonumber(arg_2_0.original_charge)
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.condition_[var_2_0] = arg_2_0.condition
		arg_1_0.startTime_[var_2_0] = tonumber(arg_2_0.start)
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.requireCharge_[var_2_0] = tonumber(arg_2_0.require_charge)
		arg_1_0.nextCharge_[var_2_0] = tonumber(arg_2_0.next_charge)
		arg_1_0.totalValue_[var_2_0] = tonumber(arg_2_0.total_value)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.iconNew_[var_2_0] = arg_2_0.icon_new
		arg_1_0.banner_[var_2_0] = arg_2_0.banner
		arg_1_0.title_[var_2_0] = arg_2_0.title
		arg_1_0.iosProductID_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.recommend_[var_2_0] = tonumber(arg_2_0.recommend)
		arg_1_0.seque_[var_2_0] = tonumber(arg_2_0.seque)
		arg_1_0.page_[var_2_0] = tonumber(arg_2_0.page)
		arg_1_0.discribe_[var_2_0] = arg_2_0.time_limited

		if tonumber(arg_2_0.is_open) == 0 then
			table.insert(arg_1_0.chargeIds_, var_2_0)
		end

		local var_2_1 = tonumber(arg_2_0.display_time)

		if var_2_1 and var_2_1 > 0 then
			if tonumber(arg_2_0.type) == 2 and var_2_1 > arg_1_0.lastShowTime2 then
				arg_1_0.lastShowTime2 = var_2_1
			elseif tonumber(arg_2_0.type) == 3 and var_2_1 > arg_1_0.lastShowTime3 then
				arg_1_0.lastShowTime3 = var_2_1
			end

			arg_1_0.isNew[var_2_0] = true
		end
	end)
end

function var_0_0.getChargeIds(arg_3_0)
	return arg_3_0.chargeIds_ or {}
end

function var_0_0.chargeId(arg_4_0, arg_4_1)
	return arg_4_0.chargeIds_[arg_4_1]
end

function var_0_0.chargeName(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1] or 0
end

function var_0_0.chargeNameNew(arg_6_0, arg_6_1)
	return arg_6_0.nameNew_[arg_6_1] or ""
end

function var_0_0.type(arg_7_0, arg_7_1)
	return arg_7_0.type_[arg_7_1] or 0
end

function var_0_0.page(arg_8_0, arg_8_1)
	return arg_8_0.page_[arg_8_1] or 0
end

function var_0_0.charge(arg_9_0, arg_9_1)
	return arg_9_0.charge_[arg_9_1] or 0
end

function var_0_0.originalCharge(arg_10_0, arg_10_1)
	return arg_10_0.originalCharge_[arg_10_1] or 0
end

function var_0_0.diamond(arg_11_0, arg_11_1)
	return arg_11_0.diamond_[arg_11_1] or 0
end

function var_0_0.condition(arg_12_0, arg_12_1)
	return arg_12_0.condition_[arg_12_1] or {}
end

function var_0_0.startTime(arg_13_0, arg_13_1)
	return arg_13_0.startTime_[arg_13_1] or 0
end

function var_0_0.time(arg_14_0, arg_14_1)
	return arg_14_0.time_[arg_14_1] or 0
end

function var_0_0.requireCharge(arg_15_0, arg_15_1)
	return arg_15_0.requireCharge_[arg_15_1] or 0
end

function var_0_0.nextCharge(arg_16_0, arg_16_1)
	return arg_16_0.nextCharge_[arg_16_1] or 0
end

function var_0_0.totalValue(arg_17_0, arg_17_1)
	return arg_17_0.totalValue_[arg_17_1] or 0
end

function var_0_0.icon(arg_18_0, arg_18_1)
	return arg_18_0.icon_[arg_18_1] or ""
end

function var_0_0.iconNew(arg_19_0, arg_19_1)
	return arg_19_0.iconNew_[arg_19_1] or ""
end

function var_0_0.banner(arg_20_0, arg_20_1)
	return arg_20_0.banner_[arg_20_1] or 0
end

function var_0_0.title(arg_21_0, arg_21_1)
	return arg_21_0.title_[arg_21_1]
end

function var_0_0.giftId(arg_22_0, arg_22_1)
	return arg_22_0.giftId_[arg_22_1] or 0
end

function var_0_0.recommend(arg_23_0, arg_23_1)
	return arg_23_0.recommend_[arg_23_1] or 0
end

function var_0_0.iosProductID(arg_24_0, arg_24_1)
	return arg_24_0.iosProductID_[arg_24_1] or 0
end

function var_0_0.seque(arg_25_0, arg_25_1)
	return arg_25_0.seque_[arg_25_1] or 1
end

function var_0_0.discribe(arg_26_0, arg_26_1)
	return arg_26_0.discribe_[arg_26_1] or ""
end

return var_0_0
