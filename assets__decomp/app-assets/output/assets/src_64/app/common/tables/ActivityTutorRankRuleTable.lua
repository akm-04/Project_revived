local var_0_0 = class("ActivityTutorRankRuleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.scores_ = {}

	import("app.common.tables.TableParser").parse("activity_tutor_rank_rule.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.scores_[var_2_0] = tonumber(arg_2_0.scores)
	end)
end

function var_0_0.getScores(arg_3_0)
	return arg_3_0.scores_ or {}
end

return var_0_0
