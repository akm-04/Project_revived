local var_0_0 = class("ActivitySqRaffleCGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.raffleTime_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.vip_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.vip_ = {}
	arg_1_0.ids_ = {}

	import("app.common.tables.TableParser").parse("activity_square_turntable2_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.icon(arg_5_0, arg_5_1)
	return arg_5_0.icon_[arg_5_1] or ""
end

function var_0_0.vip(arg_6_0, arg_6_1)
	return arg_6_0.vip_[arg_6_1] or 0
end

function var_0_0.cost(arg_7_0, arg_7_1)
	return arg_7_0.cost_[arg_7_1] or 0
end

function var_0_0.vip(arg_8_0, arg_8_1)
	return arg_8_0.vip_[arg_8_1] or 0
end

return var_0_0
