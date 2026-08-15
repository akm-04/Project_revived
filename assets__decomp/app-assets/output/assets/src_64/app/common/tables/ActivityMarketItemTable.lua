local var_0_0 = class("ActivityMarketItemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.item_id_ = {}
	arg_1_0.name_ = {}
	arg_1_0.num_ = {}
	arg_1_0.price_ = {}
	arg_1_0.allserver_limit_num_ = {}
	arg_1_0.personal_limit_num_ = {}

	import("app.common.tables.TableParser").parse("activity_market_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.item_id_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.allserver_limit_num_[var_2_0] = tonumber(arg_2_0.allserver_limit_num)
		arg_1_0.personal_limit_num_[var_2_0] = tonumber(arg_2_0.personal_limit_num)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.itemId(arg_4_0, arg_4_1)
	return arg_4_0.item_id_[arg_4_1] or ""
end

function var_0_0.name(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1] or ""
end

function var_0_0.num(arg_6_0, arg_6_1)
	return arg_6_0.num_[arg_6_1] or ""
end

function var_0_0.price(arg_7_0, arg_7_1)
	return arg_7_0.price_[arg_7_1] or ""
end

function var_0_0.allserverLimitNum(arg_8_0, arg_8_1)
	return arg_8_0.allserver_limit_num_[arg_8_1] or ""
end

function var_0_0.personalLimitNum(arg_9_0, arg_9_1)
	return arg_9_0.personal_limit_num_[arg_9_1] or ""
end

return var_0_0
