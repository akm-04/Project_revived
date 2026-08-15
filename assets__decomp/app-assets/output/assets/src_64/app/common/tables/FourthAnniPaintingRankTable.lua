local var_0_0 = class("FourthAnniPaintingRankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_4th_painting_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.RewardCount(arg_3_0)
	return #arg_3_0.gift_
end

function var_0_0.range(arg_4_0, arg_4_1)
	if arg_4_1 == 1 then
		return {
			arg_4_0.range_[1],
			arg_4_0.range_[1]
		}
	else
		return {
			arg_4_0.range_[arg_4_1 - 1] + 1,
			arg_4_0.range_[arg_4_1]
		}
	end
end

function var_0_0.item(arg_5_0, arg_5_1)
	return xyd.tables.gift:items(arg_5_0.gift_[arg_5_1])
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return xyd.tables.gift:itemNum(arg_6_0.gift_[arg_6_1])
end

return var_0_0
