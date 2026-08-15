local var_0_0 = class("ThirdAnniversaryWordRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.wordTypes_ = {}

	import("app.common.tables.TableParser").parse("activity_collect_word_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.wordTypes_[var_2_0] = xyd.splitToNumber(arg_2_0.word_types, "|")

		table.insert(arg_1_0.id_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.id_
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.wordTypes(arg_5_0, arg_5_1)
	return arg_5_0.wordTypes_[arg_5_1] or {}
end

return var_0_0
