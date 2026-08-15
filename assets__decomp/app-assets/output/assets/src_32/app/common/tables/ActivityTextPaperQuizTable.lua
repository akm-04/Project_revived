local var_0_0 = class("ActivityTextPaperQuizTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.question_ = {}
	arg_1_0.ans1_ = {}
	arg_1_0.ans2_ = {}
	arg_1_0.ans3_ = {}
	arg_1_0.ans4_ = {}
	arg_1_0.answer_ = {}

	import("app.common.tables.TableParser").parse("activity_text_paper_quiz.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.question_[var_2_0] = arg_2_0.question
		arg_1_0.ans1_[var_2_0] = arg_2_0.ans_1
		arg_1_0.ans2_[var_2_0] = arg_2_0.ans_2
		arg_1_0.ans3_[var_2_0] = arg_2_0.ans_3
		arg_1_0.ans4_[var_2_0] = arg_2_0.ans_4
		arg_1_0.answer_[var_2_0] = tonumber(arg_2_0.answer)
	end)
end

function var_0_0.question(arg_3_0, arg_3_1)
	return arg_3_0.question_[arg_3_1] or ""
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

function var_0_0.answer(arg_8_0, arg_8_1)
	return arg_8_0.answer_[arg_8_1] or 0
end

function var_0_0.getAnswer(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_2 == 1 then
		return arg_9_0.ans1_[arg_9_1] or ""
	elseif arg_9_2 == 2 then
		return arg_9_0.ans2_[arg_9_1] or ""
	elseif arg_9_2 == 3 then
		return arg_9_0.ans3_[arg_9_1] or ""
	else
		return arg_9_0.ans4_[arg_9_1] or ""
	end
end

return var_0_0
