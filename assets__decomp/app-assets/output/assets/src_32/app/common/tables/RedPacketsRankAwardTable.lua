local var_0_0 = class("RedPacketsRankAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.count_ = 0
	arg_1_0.rank_ = {}
	arg_1_0.itemId_ = {}
	arg_1_0.itemNum_ = {}

	import("app.common.tables.TableParser").parse("activity_redpackets_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.count_ = arg_1_0.count_ + 1
		arg_1_0.rank_[var_2_0] = xyd.splitToNumber(arg_2_0.rank, "|")
		arg_1_0.itemId_[var_2_0] = xyd.splitToNumber(arg_2_0.item_id, "|")
		arg_1_0.itemNum_[var_2_0] = xyd.splitToNumber(arg_2_0.item_num, "|")
	end)
end

function var_0_0.count(arg_3_0)
	return arg_3_0.count_
end

function var_0_0.rank(arg_4_0, arg_4_1)
	return arg_4_0.rank_[arg_4_1] or {
		0,
		0
	}
end

function var_0_0.itemId(arg_5_0, arg_5_1)
	return arg_5_0.itemId_[arg_5_1] or {}
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or {}
end

return var_0_0
