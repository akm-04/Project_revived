local var_0_0 = class("ActivityVotePartnerTable")

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.model_ = {}
	arg_1_0.modelName_ = {}
	arg_1_0.isPreChampion_ = {}
	arg_1_0.canVote_ = {}

	import("app.common.tables.TableParser").parse("activity_vote_partner", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.model_[var_2_0] = xyd.splitToNumber(arg_2_0.model, "|")
		arg_1_0.modelName_[var_2_0] = xyd.split(arg_2_0.model_name, "|")
		arg_1_0.name_[var_2_0] = xyd.split(arg_2_0.name, "|")
		arg_1_0.isPreChampion_[var_2_0] = tonumber(arg_2_0.is_pre_champion)
		arg_1_0.canVote_[var_2_0] = tonumber(arg_2_0.can_vote)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.models(arg_4_0, arg_4_1)
	return arg_4_0.model_[arg_4_1] or {}
end

function var_0_0.modelName(arg_5_0, arg_5_1)
	return arg_5_0.modelName_[arg_5_1] or {}
end

function var_0_0.name(arg_6_0, arg_6_1)
	return arg_6_0.name_[arg_6_1] or {}
end

function var_0_0.isPreChampion(arg_7_0, arg_7_1)
	return arg_7_0.isPreChampion_[arg_7_1] == 1
end

function var_0_0.canVote(arg_8_0, arg_8_1)
	return arg_8_0.canVote_[arg_8_1] == 1
end

function var_0_0.getAllPreChampion(arg_9_0)
	local var_9_0 = {}

	for iter_9_0 = 1, #arg_9_0.ids_ do
		if arg_9_0:isPreChampion(arg_9_0.ids_[iter_9_0]) then
			table.insert(var_9_0, arg_9_0.ids_[iter_9_0])
		end
	end

	return var_9_0
end

function var_0_0.getTableIdByName(arg_10_0, arg_10_1)
	for iter_10_0 = 1, #arg_10_0.ids_ do
		local var_10_0 = arg_10_0.ids_[iter_10_0]
		local var_10_1 = arg_10_0:name(var_10_0)

		for iter_10_1 = 1, #var_10_1 do
			if var_10_1[iter_10_1] == arg_10_1 then
				return var_10_0
			end
		end
	end

	return 0
end

return var_0_0
