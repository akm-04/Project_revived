local var_0_0 = class("SubjectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.subject_ = {}
	arg_1_0.ans1_ = {}
	arg_1_0.ans2_ = {}
	arg_1_0.ans3_ = {}
	arg_1_0.ans4_ = {}
	arg_1_0.correct_ = {}
	arg_1_0.correctReward_ = {}
	arg_1_0.wrongReward_ = {}

	import("app.common.tables.TableParser").parse("subject.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.subject_[var_2_0] = arg_2_0.subject
		arg_1_0.ans1_[var_2_0] = arg_2_0.ans_1
		arg_1_0.ans2_[var_2_0] = arg_2_0.ans_2
		arg_1_0.ans3_[var_2_0] = arg_2_0.ans_3
		arg_1_0.ans4_[var_2_0] = arg_2_0.ans_4
		arg_1_0.correct_[var_2_0] = tonumber(arg_2_0.correct_ans)
		arg_1_0.correctReward_[var_2_0] = tonumber(arg_2_0.correct_reward)
		arg_1_0.wrongReward_[var_2_0] = tonumber(arg_2_0.wrong_reward)
	end)
end

function var_0_0.subject(arg_3_0, arg_3_1)
	return arg_3_0.subject_[arg_3_1] or ""
end

function var_0_0.ans1(arg_4_0, arg_4_1)
	return arg_4_0.ans1_[arg_4_1] or ""
end

function var_0_0.ans2(arg_5_0, arg_5_1)
	return arg_5_0.ans2_[arg_5_1] or ""
end

function var_0_0.ans3(arg_6_0, arg_6_1)
	return arg_6_0.ans3_[arg_6_1] or ""
end

function var_0_0.ans4(arg_7_0, arg_7_1)
	return arg_7_0.ans4_[arg_7_1] or ""
end

function var_0_0.correct(arg_8_0, arg_8_1)
	return arg_8_0.correct_[arg_8_1] or 0
end

function var_0_0.correctReward(arg_9_0, arg_9_1)
	return arg_9_0.correctReward_[arg_9_1] or 0
end

function var_0_0.wrongReward(arg_10_0, arg_10_1)
	return arg_10_0.wrongReward_[arg_10_1] or 0
end

return var_0_0
