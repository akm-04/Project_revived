local var_0_0 = class("HighestRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.oldRank = arg_1_2.oldRank
	arg_1_0.newRank = arg_1_2.newRank
	arg_1_0.reward = arg_1_2.reward
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("reward_txt"):setString(var_0_1:translation("QUIZ_AWARD_TEXT"))
	arg_3_0:nodeByName("reward_num"):setString(arg_3_0.reward)
	arg_3_0:nodeByName("highest_txt"):setString(var_0_1:translation("HISTORY_MAX_RANK"))
	arg_3_0:nodeByName("current_txt"):setString(var_0_1:translation("CURRENT_RANK"))

	local var_3_0 = xyd.colorNumLabel(arg_3_0.oldRank, "yellow1")

	var_3_0:addTo(arg_3_0:nodeByName("background"))
	var_3_0:setPosition(arg_3_0:nodeByName("highest_pos"):getPosition())
	var_3_0:setAnchorPoint(cc.p(0, 0.5))

	local var_3_1 = xyd.colorNumLabel(arg_3_0.newRank, "yellow1")

	var_3_1:addTo(arg_3_0:nodeByName("background"))
	var_3_1:setPosition(arg_3_0:nodeByName("current_pos"):getPosition())
	var_3_1:setAnchorPoint(cc.p(0, 0.5))

	local var_3_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank_up.csb")

	var_3_2:setContentSize(var_3_2:getChildByName("background"):getContentSize())

	local var_3_3 = var_3_2:getChildByName("background")

	var_3_3:getChildByName("lev_up_txt"):setString(tostring(arg_3_0.oldRank - arg_3_0.newRank))

	local var_3_4 = var_3_3:getChildByName("lev_up_txt"):getWidth()

	var_3_3:getChildByName("right"):runAction(cc.MoveBy:create(0, cc.p(var_3_4, 0)))
	var_3_2:addTo(arg_3_0:nodeByName("background"))

	local var_3_5, var_3_6 = var_3_1:getPosition()

	var_3_2:setPosition(var_3_5 + var_3_1:getContentSize().width + 10, var_3_6)
	var_3_2:setAnchorPoint(cc.p(0, 0.5))
	arg_3_0:nodeByName("sure_txt"):setString(var_0_1:translation("HERO_MAIN_TEXT_31"))
	xyd.nodeEventSample(arg_3_0:nodeByName("sure"), nil, function(arg_4_0)
		xyd.playButtonSound()
		xyd.WindowManager.get():closeWindow(arg_3_0)
	end)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
