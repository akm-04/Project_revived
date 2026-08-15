local var_0_0 = class("RagnarokRankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.carryRange_ = {}
	arg_1_0.carryGift_ = {}
	arg_1_0.scoreRange_ = {}
	arg_1_0.scoreGift_ = {}

	import("app.common.tables.TableParser").parse("activity_ragnarok_rank_carry.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.carryRange_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.carryGift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
	import("app.common.tables.TableParser").parse("activity_ragnarok_rank_score.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id)

		arg_1_0.scoreRange_[var_3_0] = tonumber(arg_3_0.range)
		arg_1_0.scoreGift_[var_3_0] = tonumber(arg_3_0.gift)
	end)
end

function var_0_0.carryRange(arg_4_0)
	return arg_4_0.carryRange_ or {}
end

function var_0_0.carryGift(arg_5_0)
	return arg_5_0.carryGift_ or {}
end

function var_0_0.scoreRange(arg_6_0)
	return arg_6_0.scoreRange_ or {}
end

function var_0_0.scoreGift(arg_7_0)
	return arg_7_0.scoreGift_ or {}
end

return var_0_0
