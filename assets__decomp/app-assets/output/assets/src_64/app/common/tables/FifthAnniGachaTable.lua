local var_0_0 = class("FifthAnniGachaTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.giftId_ = {}
	arg_1_0.poolId_ = {}
	arg_1_0.poolItems = {}

	import("app.common.tables.TableParser").parse("fifth_anni_gacha.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.poolId_[var_2_0] = tonumber(arg_2_0.pool_id)
		arg_1_0.poolItems[arg_1_0.poolId_[var_2_0]] = arg_1_0.poolItems[arg_1_0.poolId_[var_2_0]] or {}

		table.insert(arg_1_0.poolItems[arg_1_0.poolId_[var_2_0]], var_2_0)
	end)
end

function var_0_0.giftId(arg_3_0, arg_3_1)
	return arg_3_0.giftId_[arg_3_1] or 0
end

function var_0_0.poolId(arg_4_0, arg_4_1)
	return arg_4_0.poolId_[arg_4_1] or 0
end

function var_0_0.getPoolItems(arg_5_0, arg_5_1)
	return arg_5_0.poolItems[arg_5_1] or {}
end

return var_0_0
