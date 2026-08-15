local var_0_0 = class("ActivityStickRankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.rank_ = {}
	arg_1_0.item_ids_ = {}
	arg_1_0.item_nums_ = {}

	import("app.common.tables.TableParser").parse("activity_sticker_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.rank_[var_2_0] = xyd.splitToNumber(arg_2_0.rank, "|")
		arg_1_0.item_ids_[var_2_0] = xyd.splitToNumber(arg_2_0.item_id, "|")
		arg_1_0.item_nums_[var_2_0] = xyd.splitToNumber(arg_2_0.item_num, "|")

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getAllIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.getRank(arg_4_0, arg_4_1)
	return arg_4_0.rank_[arg_4_1] or ""
end

function var_0_0.getItemIDs(arg_5_0, arg_5_1)
	return arg_5_0.item_ids_[arg_5_1] or ""
end

function var_0_0.getItemCount(arg_6_0, arg_6_1)
	return arg_6_0.item_nums_[arg_6_1] or ""
end

return var_0_0
