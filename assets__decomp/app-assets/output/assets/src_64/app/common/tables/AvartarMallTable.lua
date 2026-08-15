local var_0_0 = class("AvartarMallTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.skins_ = {}
	arg_1_0.name_ = {}
	arg_1_0.item_ = {}
	arg_1_0.saletype_ = {}
	arg_1_0.price_ = {}
	arg_1_0.chargeid_ = {}
	arg_1_0.giftId_ = {}
	arg_1_0.iosProductId_ = {}
	arg_1_0.discount_ = {}
	arg_1_0.discountChargeid_ = {}
	arg_1_0.discountIosProductId_ = {}
	arg_1_0.skillornot_ = {}
	arg_1_0.discountActivity_ = {}

	import("app.common.tables.TableParser").parse("avartar_mall.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = {}

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.saletype_[var_2_0] = tonumber(arg_2_0.saletype)
		arg_1_0.price_[var_2_0] = xyd.splitToNumber(arg_2_0.price, "|")
		arg_1_0.chargeid_[var_2_0] = tonumber(arg_2_0.chargeid)
		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.iosProductId_[var_2_0] = arg_2_0.ios_product_id
		arg_1_0.discount_[var_2_0] = xyd.splitToNumber(arg_2_0.discount, "|")
		arg_1_0.discountChargeid_[var_2_0] = tonumber(arg_2_0.discount_chargeid)
		arg_1_0.discountIosProductId_[var_2_0] = arg_2_0.discount_ios_product_id
		arg_1_0.discountActivity_[var_2_0] = tonumber(arg_2_0.discount_activity)
		var_2_1.id = var_2_0
		var_2_1.name = arg_1_0.name_[var_2_0]
		var_2_1.item = arg_1_0.item_[var_2_0]
		var_2_1.saletype = arg_1_0.saletype_[var_2_0]
		var_2_1.price = {}
		var_2_1.discount = {}

		if arg_1_0.saletype_[var_2_0] == 4 then
			var_2_1.price[2] = arg_1_0.price_[var_2_0][1]
			var_2_1.price[3] = arg_1_0.price_[var_2_0][2]
			var_2_1.discount[2] = arg_1_0.discount_[var_2_0][1]
			var_2_1.discount[3] = arg_1_0.discount_[var_2_0][2]
		elseif arg_1_0.saletype_[var_2_0] == 5 then
			var_2_1.price[9] = arg_1_0.price_[var_2_0][1]
			var_2_1.price[3] = arg_1_0.price_[var_2_0][2]
			var_2_1.discount[9] = arg_1_0.discount_[var_2_0][1]
			var_2_1.discount[3] = arg_1_0.discount_[var_2_0][2]
		elseif arg_1_0.saletype_[var_2_0] == 6 then
			var_2_1.price[10] = arg_1_0.price_[var_2_0][1]
			var_2_1.price[3] = arg_1_0.price_[var_2_0][2]
			var_2_1.discount[10] = arg_1_0.discount_[var_2_0][1]
			var_2_1.discount[3] = arg_1_0.discount_[var_2_0][2]
		elseif arg_1_0.saletype_[var_2_0] == 7 then
			var_2_1.price[9] = arg_1_0.price_[var_2_0][1]
			var_2_1.price[2] = arg_1_0.price_[var_2_0][2]
			var_2_1.discount[9] = arg_1_0.discount_[var_2_0][1]
			var_2_1.discount[2] = arg_1_0.discount_[var_2_0][2]
		elseif arg_1_0.saletype_[var_2_0] == 8 then
			var_2_1.price[10] = arg_1_0.price_[var_2_0][1]
			var_2_1.price[2] = arg_1_0.price_[var_2_0][2]
			var_2_1.discount[10] = arg_1_0.discount_[var_2_0][1]
			var_2_1.discount[2] = arg_1_0.discount_[var_2_0][2]
		else
			var_2_1.price[arg_1_0.saletype_[var_2_0]] = arg_1_0.price_[var_2_0][1]
			var_2_1.discount[arg_1_0.saletype_[var_2_0]] = arg_1_0.discount_[var_2_0][1]
		end

		var_2_1.chargeid = arg_1_0.chargeid_[var_2_0]
		var_2_1.giftId = arg_1_0.giftId_[var_2_0]
		var_2_1.discountActivity = arg_1_0.discountActivity_[var_2_0]

		table.insert(arg_1_0.skins_, var_2_1)
	end)
end

function var_0_0.getAllSkins(arg_3_0)
	return arg_3_0.skins_ or {}
end

function var_0_0.getItems(arg_4_0)
	return arg_4_0.item_ or {}
end

function var_0_0.name(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1] or ""
end

function var_0_0.item(arg_6_0, arg_6_1)
	return arg_6_0.item_[arg_6_1] or 0
end

function var_0_0.saletype(arg_7_0, arg_7_1)
	return arg_7_0.saletype_[arg_7_1] or 0
end

function var_0_0.price(arg_8_0, arg_8_1)
	return arg_8_0.price_[arg_8_1] or {}
end

function var_0_0.chargeid(arg_9_0, arg_9_1)
	return arg_9_0.chargeid_[arg_9_1] or 0
end

function var_0_0.giftId(arg_10_0, arg_10_1)
	return arg_10_0.giftId_[arg_10_1] or 0
end

function var_0_0.iosProductId(arg_11_0, arg_11_1)
	return arg_11_0.iosProductId_[arg_11_1] or ""
end

function var_0_0.discount(arg_12_0, arg_12_1)
	return arg_12_0.discount_[arg_12_1] or {}
end

function var_0_0.discountChargeid(arg_13_0, arg_13_1)
	return arg_13_0.discountChargeid_[arg_13_1] or 0
end

function var_0_0.discountIosProductId(arg_14_0, arg_14_1)
	return arg_14_0.discountIosProductId_[arg_14_1] or ""
end

function var_0_0.discountActivity(arg_15_0, arg_15_1)
	return arg_15_0.discountActivity_[arg_15_1] or 0
end

return var_0_0
