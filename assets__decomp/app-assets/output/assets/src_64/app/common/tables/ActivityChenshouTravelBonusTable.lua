local var_0_0 = class("ActivityChenshouTravelBonusTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.reqNum_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_chenshou_travel_bonus.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.reqNum_[var_2_0] = tonumber(arg_2_0.req_num)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.reqNum(arg_4_0, arg_4_1)
	return arg_4_0.reqNum_[arg_4_1] or 0
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

return var_0_0
