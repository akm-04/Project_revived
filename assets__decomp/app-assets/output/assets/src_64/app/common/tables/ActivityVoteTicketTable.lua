local var_0_0 = class("ActivityVoteTicketTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.weight_ = {}
	arg_1_0.hide_ = {}

	import("app.common.tables.TableParser").parse("activity_vote_ticket", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.weight_[var_2_0] = tonumber(arg_2_0.weight)
		arg_1_0.hide_[var_2_0] = tonumber(arg_2_0.hide)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1] or 0
end

function var_0_0.weight(arg_5_0, arg_5_1)
	return arg_5_0.weight_[arg_5_1] or 0
end

function var_0_0.hide(arg_6_0, arg_6_1)
	return arg_6_0.hide_[arg_6_1] or 0
end

return var_0_0
