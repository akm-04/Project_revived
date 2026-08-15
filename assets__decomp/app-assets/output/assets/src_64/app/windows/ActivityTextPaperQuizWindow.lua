local var_0_0 = class("ActivityTextPaperQuizWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityTextPaperQuiz
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.misc.activityTestPaperNum
local var_0_5 = {
	"A ",
	"B ",
	"C ",
	"D "
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_2.details
	arg_1_0.baseInfo = arg_1_0.details.base_info
	arg_1_0.anserPos = xyd.shuffle({
		1,
		2,
		3,
		4
	})
	arg_1_0.anserResult = {}
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("name_txt"):setString(arg_3_0.selfPlayer.playerName)
	arg_3_0:nodeByName("get_award_text"):setString(var_0_1:translation("ALERT_AWARD_NAME"))
	arg_3_0:nodeByName("question_desc"):enableOutline(cc.c4b(42, 147, 162, 255), 2)

	local var_3_0 = {
		avatar_id = arg_3_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_3_0.selfPlayer.avatarFrame
	}

	xyd.setPlayerAvatar(arg_3_0:nodeByName("avtar_container"), var_3_0)

	local var_3_1 = xyd.split(var_0_1:translation("ACTIVITY_TEXT_PAPER_FINISH_NUM"), "#")

	for iter_3_0 = 1, 4 do
		arg_3_0:nodeByName("award_text" .. tostring(iter_3_0)):setString(var_3_1[iter_3_0])
		arg_3_0:nodeByName("award_text" .. tostring(iter_3_0)):enableOutline(cc.c4b(42, 147, 162, 255), 2)
	end

	local var_3_2 = xyd.split(var_0_1:translation("ACTIVITY_TEXT_PAPER_QUESTION"), "#")

	for iter_3_1 = 1, 2 do
		arg_3_0:nodeByName("question_text" .. tostring(iter_3_1)):setString(var_3_2[iter_3_1])
		arg_3_0:nodeByName("question_text" .. tostring(iter_3_1)):enableOutline(cc.c4b(42, 147, 162, 255), 2)
	end

	for iter_3_2 = 1, #arg_3_0.anserPos do
		arg_3_0:nodeByName("anser_btn" .. tostring(iter_3_2)):getChildByName("anser_txt"):enableOutline(cc.c4b(42, 147, 162, 255), 2)
	end

	arg_3_0:setButtonClick()
	arg_3_0:update(false)
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("next_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:update(false)
		end
	end)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.callback then
				arg_4_0.callback()
			end

			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:nodeByName("close_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.callback then
				arg_4_0.callback()
			end

			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
end

function var_0_0.update(arg_8_0, arg_8_1)
	if arg_8_1 or arg_8_0.baseInfo.quiz_count > 0 and arg_8_0.baseInfo.quiz_count <= var_0_4 then
		arg_8_0:nodeByName("question_container"):setVisible(true)
		arg_8_0:nodeByName("award_container"):setVisible(false)
		arg_8_0:nodeByName("next_btn"):setVisible(false)

		local var_8_0 = arg_8_0.baseInfo.quiz_count

		if arg_8_1 then
			var_8_0 = var_8_0 - 1
		end

		local var_8_1 = arg_8_0.baseInfo.quiz_ids[var_8_0]

		arg_8_0:nodeByName("question_desc"):setString(xyd.tables.activityTextPaperQuiz:question(var_8_1))
		arg_8_0:nodeByName("question_txt"):setString(tostring(var_8_0) .. "/" .. tostring(var_0_4))

		if not arg_8_1 then
			arg_8_0.anserPos = xyd.shuffle(arg_8_0.anserPos)
		end

		local var_8_2 = xyd.tables.activityTextPaperQuiz:answer(var_8_1)

		for iter_8_0 = 1, #arg_8_0.anserPos do
			local var_8_3 = arg_8_0:nodeByName("anser_btn" .. tostring(iter_8_0))

			var_8_3:setTouchEnabled(true)
			var_8_3:getChildByName("false"):setVisible(false)
			var_8_3:getChildByName("true"):setVisible(false)
			var_8_3:getChildByName("anser_txt"):setString(var_0_5[iter_8_0] .. var_0_2:getAnswer(var_8_1, arg_8_0.anserPos[iter_8_0]))

			if not arg_8_1 then
				var_8_3:addTouchEventListener(function(arg_9_0, arg_9_1)
					if arg_9_1 == ccui.TouchEventType.ended then
						xyd.playButtonSound()

						local var_9_0 = {
							answer_id = arg_8_0.anserPos[iter_8_0]
						}

						xyd.Backend.get():request(xyd.mid.TEXT_PAPER_QUIZ_ANSWER, var_9_0, function(arg_10_0, arg_10_1)
							if arg_10_0 == xyd.error.OK then
								if arg_10_1 and arg_10_1.base_info then
									arg_8_0.details.base_info = arg_10_1.base_info
									arg_8_0.baseInfo = arg_10_1.base_info
								end

								if arg_10_1.awards then
									arg_8_0.awards = arg_10_1.awards
								end

								arg_8_0:update(true)
							end
						end)
					end
				end)
			else
				var_8_3:setTouchEnabled(false)

				local var_8_4 = arg_8_0.baseInfo.quiz_ans[var_8_0]

				if var_8_2 == var_8_4 and var_8_4 == arg_8_0.anserPos[iter_8_0] then
					var_8_3:getChildByName("true"):setVisible(true)
					var_0_3.performWithDelayGlobal(function()
						if arg_8_0 and not tolua.isnull(arg_8_0) then
							arg_8_0:update(false)
						end
					end, 0.2)
				elseif var_8_2 ~= var_8_4 then
					if arg_8_0.anserPos[iter_8_0] == var_8_4 then
						var_8_3:getChildByName("false"):setVisible(true)
					elseif arg_8_0.anserPos[iter_8_0] == var_8_2 then
						var_8_3:getChildByName("true"):setVisible(true)
					end

					arg_8_0:nodeByName("next_btn"):setVisible(true)
				end
			end
		end
	else
		arg_8_0:nodeByName("question_container"):setVisible(false)
		arg_8_0:nodeByName("award_container"):setVisible(true)
		arg_8_0:nodeByName("award_txt1"):setString(var_0_4)
		arg_8_0:nodeByName("award_txt2"):setString(arg_8_0:getTrueAnswerCount())

		if arg_8_0.awards and arg_8_0.awards[1] and arg_8_0.awards[1].mana and arg_8_0.awards[1].mana > 0 then
			xyd.setItemBorder(arg_8_0:nodeByName("award_icon"), -2)
			arg_8_0:nodeByName("award_txt"):setString(var_0_1:translation("COIN") .. "X" .. arg_8_0.awards[1].mana)
		else
			arg_8_0:nodeByName("get_award_text"):setString(var_0_1:translation("ACTIVITY_TEXT_PAPER_NO_AWARDS"))
		end

		arg_8_0.details.base_info.quiz_count = 0
	end
end

function var_0_0.getTrueAnswerCount(arg_12_0)
	local var_12_0 = 0

	if not arg_12_0.baseInfo.quiz_ids or not arg_12_0.baseInfo.quiz_ans then
		return var_12_0
	end

	for iter_12_0 = 1, #arg_12_0.baseInfo.quiz_ids do
		local var_12_1 = arg_12_0.baseInfo.quiz_ids[iter_12_0]

		if arg_12_0.baseInfo.quiz_ans[iter_12_0] == xyd.tables.activityTextPaperQuiz:answer(var_12_1) then
			var_12_0 = var_12_0 + 1
		end
	end

	return var_12_0
end

return var_0_0
