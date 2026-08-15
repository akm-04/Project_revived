local var_0_0 = class("FifthAnniBossRankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.bubbleId_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_boss_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.bubbleId_[var_2_0] = tonumber(arg_2_0.bubble_id)
	end)
end

function var_0_0.all(arg_3_0)
	return #arg_3_0.range_
end

function var_0_0.range(arg_4_0, arg_4_1)
	local var_4_0 = {}

	if arg_4_1 == 1 then
		var_4_0[1] = arg_4_0.range_[1]
	else
		var_4_0[1] = arg_4_0.range_[arg_4_1 - 1] + 1
	end

	var_4_0[2] = arg_4_0.range_[arg_4_1]

	return var_4_0
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.titleId(arg_6_0, arg_6_1)
	return 0
end

function var_0_0.bubbleId(arg_7_0, arg_7_1)
	return arg_7_0.bubbleId_[arg_7_1] or 0
end

return var_0_0
