local var_0_0 = class("TutorRankRuleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTutorRankRule

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_rule"):setString(var_0_1:translation("ACTIVITY_TUTOR_TEXT2"))
	arg_3_0:nodeByName("txt_number"):setString(var_0_1:translation("ACTIVITY_TUTOR_TEXT3"))
	arg_3_0:nodeByName("txt_score"):setString(var_0_1:translation("ACTIVITY_TUTOR_TEXT4"))

	local var_3_0 = arg_3_0:nodeByName("node_rule_txt")
	local var_3_1 = xyd.createLabel(20, cc.c3b(52, 54, 55))

	var_3_1:setString(var_0_1:translation("ACTIVITY_TUTOR_RANK_RULE_TEXT"))
	var_3_1:setAnchorPoint(0, 1)
	var_3_1:setPosition(0, 0)
	var_3_1:setLineHeight(20)
	var_3_1:addTo(var_3_0)
	arg_3_0:setScores()
end

function var_0_0.setScores(arg_4_0)
	local var_4_0 = var_0_2:getScores()

	if not var_4_0 then
		return
	end

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		arg_4_0:nodeByName("num_" .. iter_4_0):setString(iter_4_0)
		arg_4_0:nodeByName("score_" .. iter_4_0):setString(iter_4_1)
	end
end

return var_0_0
