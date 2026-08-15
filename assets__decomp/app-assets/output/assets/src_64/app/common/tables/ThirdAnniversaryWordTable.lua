local var_0_0 = class("ThirdAnniversaryWrodTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.word_ = {}
	arg_1_0.itemId_ = {}
	arg_1_0.getWay_ = {}
	arg_1_0.rate_ = {}

	import("app.common.tables.TableParser").parse("activity_collect_word.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.word_[var_2_0] = arg_2_0.word
		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.getWay_[var_2_0] = arg_2_0.get_way
		arg_1_0.rate_[var_2_0] = arg_2_0.rate
	end)
end

function var_0_0.word(arg_3_0, arg_3_1)
	return arg_3_0.word_[arg_3_1] or ""
end

function var_0_0.itemId(arg_4_0, arg_4_1)
	return arg_4_0.itemId_[arg_4_1] or 0
end

function var_0_0.getWay(arg_5_0, arg_5_1)
	return arg_5_0.getWay_[arg_5_1] or ""
end

function var_0_0.rate(arg_6_0, arg_6_1)
	return arg_6_0.rate_[arg_6_1] or 0
end

return var_0_0
