local var_0_0 = class("AnswerWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 15
local var_0_4 = 1800

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.details = arg_1_2.details
	arg_1_0.idx = arg_1_2.idx
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.currentSubject = arg_1_0.details.question_index
	arg_1_0.questionID = arg_1_0.details.question_ids[arg_1_0.currentSubject]
	arg_1_0.touchNodes = {}
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.timeLabel = arg_2_0:nodeByName("left_time")

	arg_2_0:addBlockLayer()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:initWnd()
	arg_3_0:refresh()
	arg_3_0:addBtnEvent()
end

function var_0_0.addBtnEvent(arg_4_0)
	for iter_4_0 = 1, 4 do
		local var_4_0 = arg_4_0:nodeByName("answer_" .. iter_4_0)
		local var_4_1 = var_4_0:getChildByName("choosen_answer")
		local var_4_2 = var_4_0:getChildByName("answer_bg")
		local var_4_3 = var_4_0:getChildByName("true")
		local var_4_4 = var_4_0:getChildByName("false")

		arg_4_0.touchNodes[iter_4_0]:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				var_4_2:scale(0.9)

				if var_4_0:getChildByName("answer_label") then
					var_4_0:getChildByName("answer_label"):scale(0.9)
				end

				return true
			elseif arg_5_0.name == "ended" then
				var_4_2:scale(1)

				if var_4_0:getChildByName("answer_label") then
					var_4_0:getChildByName("answer_label"):scale(1)
				end

				var_4_2:setVisible(false)
				var_4_1:setVisible(true)

				local var_5_0 = xyd.tables.subject:correct(arg_4_0.questionID)

				for iter_5_0, iter_5_1 in pairs(arg_4_0.touchNodes) do
					iter_5_1:setTouchEnabled(false)
				end

				local var_5_1 = {
					ans_id = iter_4_0
				}

				arg_4_0.activitiesModel:answerQuestion(var_5_1, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_4_0.details = arg_6_1.subject_info
						arg_4_0.currentSubject = arg_4_0.details.question_index
						arg_4_0.questionID = arg_4_0.details.question_ids[arg_4_0.currentSubject]

						if iter_4_0 == var_5_0 then
							var_4_3:setVisible(true)
						else
							var_4_4:setVisible(true)
						end

						arg_4_0:handleRewards(arg_6_1.award)
						var_0_1.performWithDelayGlobal(function()
							if arg_4_0.details.subject_status[arg_4_0.idx] >= var_0_3 then
								if arg_6_1.external_award and next(arg_6_1.external_award) then
									local var_7_0 = {
										chooseAwards = arg_6_1.external_award
									}

									xyd.WindowManager.get():openWindow("extra_award_wnd", var_7_0)
									xyd.WindowManager.get():closeWindow(arg_4_0.name)
								else
									local var_7_1 = var_0_2:translation("LATERN_TIP_11")

									xyd.WindowManager.get():openWindow("toast", {
										message = var_7_1
									})
									var_0_1.performWithDelayGlobal(function()
										xyd.WindowManager.get():closeWindow(arg_4_0.name)
									end, 1.5)
								end
							elseif arg_4_0.refresh then
								arg_4_0:refresh()
							end
						end, 1)
					end
				end)
			end
		end)
	end
end

function var_0_0.initWnd(arg_9_0)
	for iter_9_0 = 1, 4 do
		local var_9_0 = display.newNode()

		var_9_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_0:addTo(arg_9_0:nodeByName("answer_" .. iter_9_0))
		var_9_0:setPosition(arg_9_0:nodeByName("answer_" .. iter_9_0):getChildByName("answer_bg"):getPosition())
		var_9_0:setContentSize(arg_9_0:nodeByName("answer_" .. iter_9_0):getChildByName("answer_bg"):getContentSize())
		var_9_0:setName("touch_node")
		var_9_0:setTouchEnabled(true)
		table.insert(arg_9_0.touchNodes, var_9_0)
	end

	arg_9_0.countDown_ = import("app.common.CountDown").new(var_0_4 - xyd.ServerTime.get():getServerTime() + arg_9_0.details.open_time[arg_9_0.idx])

	arg_9_0:updateTimeTxt(var_0_4 - xyd.ServerTime.get():getServerTime() + arg_9_0.details.open_time[arg_9_0.idx])
	arg_9_0.countDown_:start(handler(arg_9_0, arg_9_0.updateTimeTxt))
	arg_9_0:nodeByName("left_time_desc"):setString(var_0_2:translation("LATERN_TIP_4"))
	arg_9_0:nodeByName("right_answer_desc"):setString(var_0_2:translation("LATERN_TIP_5"))
	arg_9_0:nodeByName("desc1"):setString(var_0_2:translation("LATERN_TIP_6"))
	arg_9_0:nodeByName("desc2"):setString(var_0_2:translation("LATERN_TIP_7"))
	arg_9_0:nodeByName("desc3"):setString(var_0_2:translation("LATERN_TIP_6"))
end

function var_0_0.refresh(arg_10_0)
	for iter_10_0 = 1, 4 do
		arg_10_0.touchNodes[iter_10_0]:setTouchEnabled(true)

		local var_10_0 = arg_10_0:nodeByName("answer_" .. iter_10_0)
		local var_10_1 = var_10_0:getChildByName("choosen_answer")
		local var_10_2 = var_10_0:getChildByName("answer_bg")
		local var_10_3 = var_10_0:getChildByName("true")
		local var_10_4 = var_10_0:getChildByName("false")

		var_10_1:setVisible(false)
		var_10_2:setVisible(true)
		var_10_3:setVisible(false)
		var_10_4:setVisible(false)
	end

	arg_10_0:nodeByName("right_num"):setString(arg_10_0.details.ans_status[arg_10_0.idx])
	arg_10_0:nodeByName("answer_num"):setString(var_0_3 - arg_10_0.details.subject_status[arg_10_0.idx] .. "/" .. var_0_3)

	local var_10_5 = xyd.tables.subject:subject(arg_10_0.questionID)
	local var_10_6 = {
		xyd.tables.subject:ans1(arg_10_0.questionID),
		xyd.tables.subject:ans2(arg_10_0.questionID),
		xyd.tables.subject:ans3(arg_10_0.questionID),
		(xyd.tables.subject:ans4(arg_10_0.questionID))
	}
	local var_10_7 = {
		size = 22,
		color = cc.c3b(117, 79, 54)
	}
	local var_10_8

	if arg_10_0:nodeByName("background"):getChildByName("question_label") then
		arg_10_0:nodeByName("background"):getChildByName("question_label"):setString(var_10_5)
	else
		local var_10_9 = xyd.AssetLoader.get():loadLabel(var_10_7)

		var_10_9:setMaxLineWidth(360)
		var_10_9:addTo(arg_10_0:nodeByName("background"))
		var_10_9:setPosition(arg_10_0:nodeByName("question_pos"):getPosition())
		var_10_9:setAnchorPoint(cc.p(0, 1))
		var_10_9:setString(var_10_5)
		var_10_9:setName("question_label")
	end

	for iter_10_1 = 1, 4 do
		local var_10_10 = arg_10_0:nodeByName("answer_" .. iter_10_1)
		local var_10_11 = var_10_10:getChildByName("answer_pos")
		local var_10_12 = var_10_10:getChildByName("choosen_answer")
		local var_10_13 = var_10_10:getChildByName("answer_bg")
		local var_10_14 = var_10_10:getChildByName("true")
		local var_10_15 = var_10_10:getChildByName("false")
		local var_10_16 = {
			size = 18,
			color = cc.c3b(54, 54, 54)
		}
		local var_10_17

		if var_10_10:getChildByName("answer_label") then
			var_10_10:getChildByName("answer_label"):setString(var_10_6[iter_10_1])
		else
			local var_10_18 = xyd.AssetLoader.get():loadLabel(var_10_16)

			var_10_18:setString(var_10_6[iter_10_1])
			var_10_18:addTo(var_10_10)
			var_10_18:setAnchorPoint(cc.p(0.5, 0.5))
			var_10_18:setPosition(var_10_11:getPosition())
			var_10_18:setLocalZOrder(100)
			var_10_18:setName("answer_label")
		end
	end
end

function var_0_0.handleRewards(arg_11_0, arg_11_1)
	local var_11_0 = ""

	for iter_11_0, iter_11_1 in pairs(arg_11_1) do
		if iter_11_1.item == "mana" then
			local var_11_1 = var_0_2:translation("COIN") .. "X" .. iter_11_1.num

			if var_11_0 ~= "" then
				var_11_0 = var_11_0 .. "," .. var_11_1
			else
				var_11_0 = var_11_0 .. var_11_1
			end
		else
			local var_11_2 = xyd.tables.item:name(tonumber(iter_11_1.item)) .. "X" .. iter_11_1.num

			if var_11_0 ~= "" then
				var_11_0 = var_11_0 .. "," .. var_11_2
			else
				var_11_0 = var_11_0 .. var_11_2
			end

			arg_11_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_11_1.item), tonumber(iter_11_1.num))
		end
	end

	local var_11_3 = {
		message = var_11_0
	}

	var_11_3.delay = 0.95
	var_11_3.textSize = 24

	xyd.WindowManager.get():openWindow("toast", var_11_3)
end

function var_0_0.updateTimeTxt(arg_12_0, arg_12_1)
	if arg_12_1 <= 0 then
		arg_12_0.countDown_:stop()
		arg_12_0.activitiesModel:openSubject(function(arg_13_0, arg_13_1)
			if arg_13_1 and arg_13_1.open_time and xyd.ServerTime.get():getServerTime() - arg_13_1.open_time[arg_12_0.idx] < var_0_4 then
				arg_12_0.countDown_ = import("app.common.CountDown").new(var_0_4 - xyd.ServerTime.get():getServerTime() + arg_13_1.open_time[arg_12_0.idx])

				arg_12_0:updateTimeTxt(var_0_4 - xyd.ServerTime.get():getServerTime() + arg_13_1.open_time[arg_12_0.idx])
				arg_12_0.countDown_:start(handler(arg_12_0, arg_12_0.updateTimeTxt))

				return
			end

			if arg_13_1 and arg_13_1.external_award and next(arg_13_1.external_award) then
				local var_13_0 = {
					chooseAwards = arg_13_1.external_award
				}

				xyd.WindowManager.get():openWindow("extra_award_wnd", var_13_0)
				xyd.WindowManager.get():closeWindow(arg_12_0.name)
			else
				xyd.WindowManager.get():closeWindow(arg_12_0.name)
			end
		end)

		return
	end

	local var_12_0 = math.floor(arg_12_1 / 60)

	if var_12_0 < 10 then
		var_12_0 = "0" .. var_12_0
	end

	local var_12_1 = arg_12_1 % 60

	if var_12_1 < 10 then
		var_12_1 = "0" .. var_12_1
	end

	local var_12_2 = var_12_0 .. var_0_2:translation("UNIT_MINUTE") .. var_12_1 .. var_0_2:translation("UNIT_SECOND")

	arg_12_0.timeLabel:setString(var_12_2)
end

function var_0_0.willClose(arg_14_0, arg_14_1)
	if arg_14_0.callback then
		arg_14_0.callback(arg_14_0.details)
	end

	if arg_14_0.countDown_ then
		arg_14_0.countDown_:stop()
	end
end

return var_0_0
