local var_0_0 = class("SnowBattleResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.isWin = arg_1_2.isWin
	arg_1_0.info = arg_1_0.snowActivity:getBattleResultInfo()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:addResultEffect()
	arg_3_0:nodeByName("text_score"):enableOutline(cc.c4b(18, 98, 15, 255), 2)
	arg_3_0:nodeByName("old_score_num"):enableOutline(cc.c4b(18, 98, 15, 255), 2)
	arg_3_0:nodeByName("new_score_num"):enableOutline(cc.c4b(18, 98, 15, 255), 2)
	arg_3_0:nodeByName("text_rank"):enableOutline(cc.c4b(222, 69, 123, 255), 2)
	arg_3_0:nodeByName("old_rank_num"):enableOutline(cc.c4b(222, 69, 123, 255), 2)
	arg_3_0:nodeByName("new_rank_num"):enableOutline(cc.c4b(222, 69, 123, 255), 2)
	arg_3_0:nodeByName("text_score"):setString(var_0_2:translation("SNOW_ACTIVITY_SCORE"))
	arg_3_0:nodeByName("text_rank"):setString(var_0_2:translation("RANKING"))

	if arg_3_0.info then
		local var_3_0 = arg_3_0.info.point
		local var_3_1 = arg_3_0.info.rank
		local var_3_2 = arg_3_0.snowActivity:getArenaInfo()
		local var_3_3 = var_3_2.point
		local var_3_4 = var_3_2.rank

		arg_3_0:nodeByName("old_score_num"):setString(var_3_3)
		arg_3_0:nodeByName("new_score_num"):setString(var_3_0)
		arg_3_0:nodeByName("old_rank_num"):setString(var_3_4)
		arg_3_0:nodeByName("new_rank_num"):setString(var_3_1)

		if var_3_3 < var_3_0 then
			arg_3_0:nodeByName("img_score_down"):setVisible(false)
		elseif var_3_0 < var_3_3 then
			arg_3_0:nodeByName("img_score_up"):setVisible(false)
		else
			arg_3_0:nodeByName("img_score_down"):setVisible(false)
			arg_3_0:nodeByName("img_score_up"):setVisible(false)
		end

		if var_3_1 < var_3_4 then
			arg_3_0:nodeByName("img_rank_down"):setVisible(false)
		elseif var_3_4 < var_3_1 then
			arg_3_0:nodeByName("img_rank_up"):setVisible(false)
		else
			arg_3_0:nodeByName("img_rank_down"):setVisible(false)
			arg_3_0:nodeByName("img_rank_up"):setVisible(false)
		end

		arg_3_0.snowActivity:updateArenaInfo(arg_3_0.info)
	end

	arg_3_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 200))

	local var_3_5 = arg_3_0:nodeByName("container"):convertToWorldSpace(cc.p(0, 0))

	arg_3_0.blockLayer_:pos(-var_3_5.x, -var_3_5.y):addTo(arg_3_0:nodeByName("container"), -1)
	arg_3_0.blockLayer_:setTouchEnabled(true)
	arg_3_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
end

function var_0_0.playEffect(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6)
	local var_5_0
	local var_5_1 = arg_5_5 or false
	local var_5_2 = arg_5_2 .. ".json"
	local var_5_3 = arg_5_2 .. ".atlas"
	local var_5_4 = var_0_1.new(var_5_2, var_5_3, 1)

	arg_5_1:addChild(var_5_4, arg_5_6)
	var_5_4:pos(arg_5_3.x, arg_5_3.y)

	if arg_5_4 == true then
		var_5_4:setToSetupPose()
		var_5_4:setVisible(true)

		if var_5_1 then
			var_5_4:play(function()
				return
			end, true)
		else
			var_5_4:play(function()
				var_5_4:setVisible(true)
			end)
		end
	else
		var_5_4:setVisible(false)
	end
end

function var_0_0.addResultEffect(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("effect")
	local var_8_1 = var_8_0:getContentSize()
	local var_8_2 = cc.p(var_8_1.width / 2, var_8_1.height / 2 + 80)

	if arg_8_0.isWin == 1 then
		arg_8_0:playEffect(var_8_0, "skeletons/ui_effect/douniu_effect/douniu_effect_win", var_8_2, true, false, 20)
	else
		arg_8_0:playEffect(var_8_0, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat", var_8_2, true, false, 20)
	end
end

return var_0_0
