local var_0_0 = class("SummerQuizWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySummerQuiz
local var_0_3 = import("framework.scheduler")
local var_0_4 = "skeletons/ui_effect/summer/signal"
local var_0_5 = {
	Warning = 2,
	Normal = 1
}
local var_0_6 = {
	NotStart = 1,
	InFightBoss = 3,
	Ended = 5,
	Complete = 4,
	InQuizNormal = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.summer = xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.bigPassInfo = arg_1_0.summer.details.big_pass_info
	arg_1_0.anserPos = arg_1_0:shuffle({
		1,
		2,
		3,
		4
	})
	arg_1_0.anserResult = {}
end

function var_0_0.shuffle(arg_2_0, arg_2_1)
	local var_2_0 = clone(arg_2_1)
	local var_2_1 = {}

	while var_2_0 and next(var_2_0) do
		local var_2_2 = math.random(#var_2_0)

		table.insert(var_2_1, var_2_0[var_2_2])
		table.remove(var_2_0, var_2_2)
	end

	return var_2_1
end

function var_0_0.addSignalEffect(arg_3_0)
	arg_3_0.signalEffects = {}

	local var_3_0 = 45
	local var_3_1 = var_3_0 / 2
	local var_3_2 = cc.p(150, 57)
	local var_3_3 = 715
	local var_3_4 = 405
	local var_3_5 = 9
	local var_3_6 = 16
	local var_3_7 = 0
	local var_3_8 = cc.p(var_3_2.x, var_3_2.y + var_3_0 / 2)

	for iter_3_0 = 1, var_3_5 do
		var_3_7 = var_3_7 + 1
		arg_3_0.signalEffects[var_3_7] = arg_3_0:createAndAddSignal(var_3_8)
		var_3_8 = cc.p(var_3_8.x, var_3_8.y + var_3_0)
	end

	local var_3_9 = cc.p(var_3_2.x + var_3_0 / 2, var_3_2.y + var_3_4)

	for iter_3_1 = 1, var_3_6 do
		var_3_7 = var_3_7 + 1
		arg_3_0.signalEffects[var_3_7] = arg_3_0:createAndAddSignal(var_3_9)
		var_3_9 = cc.p(var_3_9.x + var_3_0, var_3_9.y)
	end

	local var_3_10 = cc.p(var_3_2.x + var_3_3, var_3_2.y + var_3_4 - var_3_0 / 2)

	for iter_3_2 = 1, var_3_5 do
		var_3_7 = var_3_7 + 1
		arg_3_0.signalEffects[var_3_7] = arg_3_0:createAndAddSignal(var_3_10)
		var_3_10 = cc.p(var_3_10.x, var_3_10.y - var_3_0)
	end

	local var_3_11 = cc.p(var_3_2.x + var_3_3 - var_3_0 / 2, var_3_2.y)

	for iter_3_3 = 1, var_3_6 do
		var_3_7 = var_3_7 + 1
		arg_3_0.signalEffects[var_3_7] = arg_3_0:createAndAddSignal(var_3_11)
		var_3_11 = cc.p(var_3_11.x - var_3_0, var_3_11.y)
	end

	arg_3_0:swapSingalState(var_0_5.Normal)
end

function var_0_0.createAndAddSignal(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0.summer:createEffect(var_0_4)

	var_4_0:addTo(arg_4_0:nodeByName("bg"))
	var_4_0:setPosition(arg_4_1)
	var_4_0:setLocalZOrder(0)

	return var_4_0
end

function var_0_0.swapSingalState(arg_5_0, arg_5_1)
	if not arg_5_0.signalEffects then
		return
	end

	for iter_5_0 = 1, #arg_5_0.signalEffects do
		if arg_5_1 == var_0_5.Normal then
			arg_5_0.signalEffects[iter_5_0]:play(nil, true, nil, iter_5_0 % 2 + 1)
		else
			arg_5_0.signalEffects[iter_5_0]:play(nil, false, nil, 3)
		end
	end
end

function var_0_0.playWarningEffect(arg_6_0)
	arg_6_0:swapSingalState(var_0_5.Warning)
	var_0_3.performWithDelayGlobal(function()
		if arg_6_0 and not tolua.isnull(arg_6_0) then
			arg_6_0:swapSingalState(var_0_5.Normal)
		end
	end, 1)
end

function var_0_0.willOpen(arg_8_0, arg_8_1)
	var_0_0.super.willOpen(arg_8_0, arg_8_1)
	arg_8_0:layout()
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super.didOpen(arg_9_0, arg_9_1)

	if arg_9_0.summer.fightResponse and arg_9_0.summer.fightResponse.rank and arg_9_0.summer.fightResponse.rank > 0 then
		xyd.WindowManager.get():openWindow("summer_quiz_result")
	end
end

function var_0_0.willClose(arg_10_0, arg_10_1)
	var_0_0.super.willClose(arg_10_0, arg_10_1)

	if arg_10_0.handle then
		var_0_3.unscheduleGlobal(arg_10_0.handle)

		arg_10_0.handle = nil
	end

	if arg_10_0.handle2 then
		var_0_3.unscheduleGlobal(arg_10_0.handle2)

		arg_10_0.handle2 = nil
	end
end

function var_0_0.layout(arg_11_0)
	arg_11_0:nodeByName("down_time_txt"):setString(var_0_1:translation(""))
	arg_11_0:nodeByName("nqustion_txt1"):setString(var_0_1:translation("NQUESTION_TEXT"))
	arg_11_0:nodeByName("question_txt1"):setString(var_0_1:translation(""))
	arg_11_0:nodeByName("question_txt2"):setString(var_0_1:translation(""))
	arg_11_0:nodeByName("nqustion_txt2"):setString(var_0_1:translation("NQUESTION_TEXT"))
	arg_11_0:nodeByName("down_time_text"):setString(var_0_1:translation("QUIZ_OPEN_DOWN_TIME"))
	arg_11_0:nodeByName("tip_txt"):setString(var_0_1:translation("QUIZ_NOT_OPEN_TEXT"))
	arg_11_0:nodeByName("battle_tip_txt4"):setVisible(false)
	arg_11_0:nodeByName("down_time_bg"):setLocalZOrder(1)

	arg_11_0.costTimeLabel = xyd.AssetLoader.get():loadLabel(nil, "summer_cost_time")

	arg_11_0.costTimeLabel:setAnchorPoint(cc.p(0, 0.5))
	arg_11_0.costTimeLabel:addTo(arg_11_0:nodeByName("time_pos"))
	arg_11_0:addCentreModel()
	arg_11_0:setButtonClick()
	arg_11_0:nextQuestion()
	arg_11_0:createScheduler()
	arg_11_0:addSignalEffect()
end

function var_0_0.addCentreModel(arg_12_0)
	local var_12_0 = 40001036

	arg_12_0.heroModel = xyd.HeroAnimation.new(nil, var_12_0, 0.8, {})

	arg_12_0.heroModel:addTo(arg_12_0:nodeByName("container"))
	arg_12_0.heroModel:setPosition(cc.p(1000, 30))
	arg_12_0.heroModel:idle()
	arg_12_0.heroModel:setFlipX(true)
end

function var_0_0.getQuizState(arg_13_0)
	local var_13_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_13_0 > 18000 and var_13_0 <= xyd.tables.misc.summerQuizStartTime then
		return var_0_6.NotStart
	elseif arg_13_0.bigPassInfo.finish_time ~= 0 then
		return var_0_6.Complete
	elseif var_13_0 <= 18000 or var_13_0 > xyd.tables.misc.summerQuizEndTime then
		return var_0_6.Ended
	elseif not xyd.isInTable(xyd.tables.misc.summerQuizBossPos, arg_13_0.bigPassInfo.now_pos) then
		return var_0_6.InQuizNormal
	else
		return var_0_6.InFightBoss
	end
end

function var_0_0.swapState(arg_14_0, arg_14_1)
	arg_14_0:nodeByName("question_container"):setVisible(false)
	arg_14_0:nodeByName("battle_container"):setVisible(false)
	arg_14_0:nodeByName("tip_container"):setVisible(false)
	arg_14_0:nodeByName("time_pos"):setVisible(false)

	if arg_14_1 == var_0_6.InQuizNormal or arg_14_1 == var_0_6.InFightBoss then
		arg_14_0.heroModel:setVisible(true)
		arg_14_0:nodeByName("time_pos"):setVisible(true)
		arg_14_0:nodeByName("bg"):setVisible(true)
		arg_14_0:nodeByName("not_open_bg"):setVisible(false)

		if arg_14_1 == var_0_6.InQuizNormal then
			arg_14_0:nodeByName("question_container"):setVisible(true)
		else
			arg_14_0:nodeByName("battle_container"):setVisible(true)
		end
	else
		arg_14_0.heroModel:setVisible(false)
		arg_14_0:nodeByName("time_pos"):setVisible(false)
		arg_14_0:nodeByName("bg"):setVisible(false)
		arg_14_0:nodeByName("not_open_bg"):setVisible(true)
		arg_14_0:nodeByName("tip_container"):setVisible(true)
		arg_14_0:nodeByName("down_time_txt"):setVisible(false)
		arg_14_0:nodeByName("down_time_text"):setVisible(false)

		if arg_14_1 == var_0_6.NotStart then
			arg_14_0:nodeByName("tip_txt"):setString(var_0_1:translation("QUIZ_NOT_OPEN_TEXT"))
			arg_14_0:nodeByName("down_time_txt"):setVisible(true)
			arg_14_0:nodeByName("down_time_text"):setVisible(true)
		elseif arg_14_1 == var_0_6.Complete then
			arg_14_0:nodeByName("tip_txt"):setString(var_0_1:translation("QUIZ_ANSERD_TEXT"))
		elseif arg_14_1 == var_0_6.Ended then
			arg_14_0:nodeByName("tip_txt"):setString(var_0_1:translation("QUIZ_ENDED_TEXT"))
		end
	end
end

function var_0_0.nextQuestion(arg_15_0)
	arg_15_0.bigPassInfo = arg_15_0.summer.details.big_pass_info

	local var_15_0 = arg_15_0:getQuizState()

	arg_15_0:swapState(var_15_0)

	local var_15_1 = arg_15_0.bigPassInfo.now_pos
	local var_15_2 = arg_15_0.bigPassInfo.today_questions[var_15_1]

	if var_15_0 == var_0_6.InFightBoss then
		local var_15_3 = xyd.tables.battle:fight1(var_15_2)[1]

		arg_15_0:nodeByName("nqustion_txt2"):setString(string.format(var_0_1:translation("NQUESTION_TEXT"), var_15_1))
		arg_15_0:nodeByName("question_txt2"):setString(string.format(var_0_1:translation("QUIZ_FIGHT_BOSS_TEXT"), xyd.tables.hero:name(var_15_3)))
		arg_15_0:nodeByName("battle_tip_txt1"):setString(var_0_1:translation("ONLY_TEXT"))

		local var_15_4 = xyd.tables.hero:distanceType(var_15_3)
		local var_15_5 = var_0_1:translation("QIANPAI_BUTTON")

		if var_15_4 == xyd.DistanceType.ZHONGPAI then
			var_15_5 = var_0_1:translation("ZHONGPAI_BUTTON")
		elseif var_15_4 == xyd.DistanceType.HOUPAI then
			var_15_5 = var_0_1:translation("HOUPAI_BUTTON")
		end

		arg_15_0:nodeByName("battle_tip_txt2"):setString(var_15_5)
		arg_15_0:nodeByName("battle_tip_txt3"):setString(var_0_1:translation("QUIZ_FIGHT_BOSS_TIP1"))
		arg_15_0:nodeByName("battle_text"):setString(var_0_1:translation("BATTlE_TEXT"))
		arg_15_0:nodeByName("battle_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
			xyd.buttonScaleAnim(arg_16_0, arg_16_1)

			if arg_16_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_15_0:startBattle(var_15_2)
			end
		end)
	elseif var_15_0 == var_0_6.InQuizNormal then
		arg_15_0:nodeByName("nqustion_txt1"):setString(string.format(var_0_1:translation("NQUESTION_TEXT"), var_15_1))
		arg_15_0:nodeByName("question_txt1"):setString(var_0_2:question(var_15_2))

		arg_15_0.anserPos = arg_15_0:shuffle(arg_15_0.anserPos)

		for iter_15_0 = 1, #arg_15_0.anserPos do
			local var_15_6 = arg_15_0:nodeByName("anser_btn" .. tostring(iter_15_0))

			var_15_6:setTouchEnabled(true)
			var_15_6:getChildByName("false"):setVisible(false)
			var_15_6:getChildByName("true"):setVisible(false)
			var_15_6:getChildByName("anser_txt"):setString(var_0_2:getAnswer(var_15_2, arg_15_0.anserPos[iter_15_0]))
			var_15_6:addTouchEventListener(function(arg_17_0, arg_17_1)
				xyd.buttonScaleAnim(arg_17_0, arg_17_1)

				if arg_17_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_17_0 = {
						ques_pos = var_15_1,
						answer = arg_15_0.anserPos[iter_15_0]
					}

					arg_15_0.summer:anserQuiz(var_17_0, function(arg_18_0, arg_18_1)
						if arg_18_0 == xyd.error.OK then
							if arg_18_1.awards then
								xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_18_1.awards)
							end

							if arg_18_1.is_success == 0 then
								arg_15_0:swapSingalState(var_0_5.Warning)
								var_15_6:getChildByName("false"):setVisible(true)
								var_15_6:setTouchEnabled(false)

								local function var_18_0()
									arg_15_0:swapSingalState(var_0_5.Normal)
								end

								local var_18_1 = {
									callback = var_18_0
								}

								xyd.WindowManager.get():openWindow("summer_quiz_reborn", var_18_1)
							else
								var_15_6:getChildByName("true"):setVisible(true)
								var_0_3.performWithDelayGlobal(function()
									if arg_15_0 and not tolua.isnull(arg_15_0) then
										arg_15_0:nextQuestion()
									end
								end, 0.2)
							end
						end
					end)
				end
			end)
		end
	end
end

function var_0_0.setButtonClick(arg_21_0)
	arg_21_0:nodeByName("rule_text"):setString(var_0_1:translation("RULE_STATEMENT"))
	arg_21_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_22_0 = {
				title_name = "SUMMER_QUIZ_RULE_TITLE",
				rule = "SUMMER_QUIZ_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_22_0)
		end
	end)
	arg_21_0:nodeByName("view_rank_text"):setString(var_0_1:translation("VIEW_RANK"))
	arg_21_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		xyd.buttonScaleAnim(arg_23_0, arg_23_1)

		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_23_0 = {}

			arg_21_0.summer:getQuizRankList(var_23_0, function(arg_24_0, arg_24_1)
				if arg_24_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("summer_quiz_rank")
				end
			end)
		end
	end)
	arg_21_0:nodeByName("battle_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		xyd.buttonScaleAnim(arg_25_0, arg_25_1)

		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
		end
	end)
end

function var_0_0.createScheduler(arg_26_0)
	if arg_26_0.handle then
		var_0_3.unscheduleGlobal(arg_26_0.handle)

		arg_26_0.handle = nil
	end

	arg_26_0.startTime = xyd.ServerTime.get():getSecondsOfDay()
	arg_26_0.count = 0
	arg_26_0.handle = var_0_3.scheduleGlobal(function()
		arg_26_0.count = arg_26_0.count + 3.3333333333333335

		arg_26_0:updateTimeShow()
	end, 0.01)
	arg_26_0.currentTime = arg_26_0.startTime
	arg_26_0.handle2 = var_0_3.scheduleGlobal(function()
		arg_26_0.currentTime = arg_26_0.currentTime + 1

		if arg_26_0.currentTime == xyd.tables.misc.summerQuizStartTime + 1 or arg_26_0.currentTime == xyd.tables.misc.summerQuizEndTime + 1 or arg_26_0.currentTime == 18001 then
			arg_26_0:nextQuestion()
		end
	end, 1)
end

function var_0_0.updateTimeShow(arg_29_0)
	local var_29_0 = arg_29_0.startTime + math.floor(arg_29_0.count / 100)
	local var_29_1 = math.floor(arg_29_0.count % 100)

	if var_29_1 < 10 then
		var_29_1 = "0" .. tostring(var_29_1)
	else
		var_29_1 = tostring(var_29_1)
	end

	local var_29_2 = var_29_0 - xyd.tables.misc.summerQuizStartTime
	local var_29_3 = xyd.tables.misc.summerQuizStartTime - var_29_0

	if var_29_2 < 0 then
		var_29_2 = var_29_2 + 86400
	end

	if var_29_3 < 0 then
		var_29_3 = var_29_3 + 86400
	end

	arg_29_0.costTimeLabel:setString(os.date("%M:%S", var_29_2) .. ":" .. tostring(var_29_1))
	arg_29_0.costTimeLabel:setScale(0.9)
	arg_29_0:nodeByName("down_time_txt"):setString(xyd.secondsToString1(var_29_3, 3))
end

function var_0_0.startBattle(arg_30_0, arg_30_1)
	local var_30_0 = xyd.tables.battle:campaignType(arg_30_1)
	local var_30_1 = {
		type = xyd.SelectTeamType.SUMMER_FIGHT_BOSS,
		battleID = arg_30_1,
		campaignType = var_30_0
	}

	xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_30_1)
end

return var_0_0
