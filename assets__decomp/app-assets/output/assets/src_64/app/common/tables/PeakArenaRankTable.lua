local var_0_0 = class("PeakArenaRankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.type_ = {}
	arg_1_0.score_ = {}
	arg_1_0.teamNum_ = {}
	arg_1_0.teamHide_ = {}
	arg_1_0.coolTime_ = {}
	arg_1_0.challengeNum_ = {}
	arg_1_0.matchNum_ = {}

	import("app.common.tables.TableParser").parse("legend_arena_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.rank_name
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.rank_type)
		arg_1_0.score_[var_2_0] = tonumber(arg_2_0.rank_bound)
		arg_1_0.teamNum_[var_2_0] = tonumber(arg_2_0.team_num)
		arg_1_0.teamHide_[var_2_0] = tonumber(arg_2_0.team_hide)
		arg_1_0.coolTime_[var_2_0] = tonumber(arg_2_0.cool_time)
		arg_1_0.challengeNum_[var_2_0] = tonumber(arg_2_0.challenge_num)
		arg_1_0.matchNum_[var_2_0] = tonumber(arg_2_0.match_num)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or 0
end

function var_0_0.score(arg_5_0, arg_5_1)
	return arg_5_0.score_[arg_5_1] or 0
end

function var_0_0.teamNum(arg_6_0, arg_6_1)
	return arg_6_0.teamNum_[arg_6_1] or 0
end

function var_0_0.teamHide(arg_7_0, arg_7_1)
	return arg_7_0.teamHide_[arg_7_1] or 0
end

function var_0_0.coolTime(arg_8_0, arg_8_1)
	return arg_8_0.coolTime_[arg_8_1] or 0
end

function var_0_0.challengeNum(arg_9_0, arg_9_1)
	return arg_9_0.challengeNum_[arg_9_1] or 0
end

function var_0_0.matchNum(arg_10_0, arg_10_1)
	return arg_10_0.matchNum_[arg_10_1] or 0
end

return var_0_0
