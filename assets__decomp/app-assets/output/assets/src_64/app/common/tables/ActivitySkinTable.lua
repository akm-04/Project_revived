local var_0_0 = class("ActivitySkinTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.giftId_ = {}
	arg_1_0.price_ = {}
	arg_1_0.discountPrice_ = {}
	arg_1_0.skinItem_ = {}

	import("app.common.tables.TableParser").parse("activity_skin.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.discountPrice_[var_2_0] = tonumber(arg_2_0.discount_price)
		arg_1_0.skinItem_[var_2_0] = tonumber(arg_2_0.skin_item)
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.giftId_[arg_3_1] or 0
end

function var_0_0.price(arg_4_0, arg_4_1)
	return arg_4_0.price_[arg_4_1] or 0
end

function var_0_0.discountPrice(arg_5_0, arg_5_1)
	return arg_5_0.discountPrice_[arg_5_1] or 0
end

function var_0_0.skinItem(arg_6_0, arg_6_1)
	return arg_6_0.skinItem_[arg_6_1] or 0
end

return var_0_0
