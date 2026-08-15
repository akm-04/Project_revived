local var_0_0 = class("CvLinkWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityCvLink
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.cvLink = xyd.ModelManager.get():loadModel(xyd.ModelType.CVLINK)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_1_0:initData()

	arg_1_0.musicSwitch = xyd.db.settings:getBackgroudMusicOn()
	arg_1_0.dialogSwitch = xyd.db.settings:getAutoDialog()
end

function var_0_0.initData(arg_2_0)
	arg_2_0.details = arg_2_0.cvLink.details
	arg_2_0.heroIds = arg_2_0.details.base_info.daily_ids
	arg_2_0.heroToCv = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	arg_2_0.cvLinkNames = {}

	for iter_2_0 = 1, #arg_2_0.heroIds do
		table.insert(arg_2_0.cvLinkNames, var_0_2:cv(arg_2_0.heroIds[iter_2_0]))
	end

	arg_2_0.cvLinkNames = xyd.shuffle(arg_2_0.cvLinkNames)
	arg_2_0.currentSpeakIdx = 0
	arg_2_0.isShowRightAnswer = false

	if arg_2_0.details.base_info.is_daily_answer == 1 then
		local var_2_0 = json.decode(arg_2_0.details.base_info.record)

		arg_2_0.heroIds = var_2_0.ids
		arg_2_0.answers = var_2_0.names

		arg_2_0:formatHeroToCv()
	end
end

function var_0_0.countRightAnswer(arg_3_0)
	local var_3_0 = 0

	for iter_3_0 = 1, #arg_3_0.heroIds do
		if var_0_2:cv(arg_3_0.heroIds[iter_3_0]) == arg_3_0.answers[iter_3_0] then
			var_3_0 = var_3_0 + 1
		end
	end

	return var_3_0
end

function var_0_0.formatHeroToCv(arg_4_0)
	for iter_4_0 = 1, #arg_4_0.answers do
		for iter_4_1 = 1, #arg_4_0.cvLinkNames do
			if arg_4_0.cvLinkNames[iter_4_1] == arg_4_0.answers[iter_4_0] and not xyd.isInTable(arg_4_0.heroToCv, iter_4_1) then
				arg_4_0.heroToCv[iter_4_0] = iter_4_1
			end
		end
	end
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	var_0_0.super.willOpen(arg_5_0, arg_5_1)
	arg_5_0:layout()
end

function var_0_0.willClose(arg_6_0, arg_6_1)
	var_0_0.super.willClose(arg_6_0, arg_6_1)

	if arg_6_0.audioHandle then
		audio.stopSound(arg_6_0.audioHandle)

		arg_6_0.audioHandle = nil
	end

	if arg_6_0.handle then
		var_0_4.unscheduleGlobal(arg_6_0.handle)

		arg_6_0.handle = nil
	end

	arg_6_0:isStopBgSound(false)
end

function var_0_0.layout(arg_7_0)
	arg_7_0:nodeByName("tip_text1"):setString(var_0_1:translation("ACTIVITY_CV_LINK_TIP3"))
	arg_7_0:nodeByName("tip_text2"):setString(var_0_1:translation("ACTIVITY_CV_LINK_TIP4"))
	arg_7_0:nodeByName("result_txt"):enableOutline(cc.c4b(255, 132, 0, 255), 2)
	arg_7_0:nodeByName("award_txt"):enableOutline(cc.c4b(255, 132, 0, 255), 2)
	arg_7_0:nodeByName("result_text"):enableOutline(cc.c4b(144, 108, 255, 255), 2)
	arg_7_0:nodeByName("award_text"):enableOutline(cc.c4b(144, 108, 255, 255), 2)
	arg_7_0:setButtonClick()
end

function var_0_0.isLinkAll(arg_8_0)
	for iter_8_0 = 1, arg_8_0.linkmens do
		if arg_8_0.linkmens[iter_8_0] == 0 then
			return false
		end
	end

	return true
end

function var_0_0.setButtonClick(arg_9_0)
	arg_9_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("cv_link_rule")
		end
	end)
	arg_9_0:nodeByName("answer_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_9_0:nodeByName("answer_btn"):getChildByName("button_cover"):isVisible() then
				return
			end

			xyd.playButtonSound()

			local var_11_0 = var_0_1:translation("ACTIVITY_CV_LINK_TIP2")

			xyd.CvLinkConfirmWindow.open(xyd.AlertType.YES_NO, {
				var_11_0
			}, function(arg_12_0)
				if arg_12_0 then
					local var_12_0 = {
						ids = arg_9_0.heroIds,
						names = {}
					}

					for iter_12_0 = 1, 6 do
						table.insert(var_12_0.names, arg_9_0.cvLinkNames[arg_9_0.heroToCv[iter_12_0]])
					end

					arg_9_0.names = var_12_0.names

					arg_9_0.cvLink:answer(var_12_0, function(arg_13_0, arg_13_1)
						if arg_13_0 == xyd.error.OK then
							if arg_13_1.awards then
								arg_9_0.selfPlayer:handleRewards(arg_13_1.awards)
							end

							arg_9_0:initData()
							arg_9_0:update()
						end
					end)
				end
			end)
		end
	end)
	arg_9_0:nodeByName("peek_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			cc.Application:getInstance():openURL(arg_9_0.details.url)
		end
	end)
	arg_9_0:nodeByName("show_result_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_9_0.isShowRightAnswer = not arg_9_0.isShowRightAnswer

			arg_9_0:update()
		end
	end)
	arg_9_0:itemLayout()
end

function var_0_0.itemLayout(arg_16_0)
	local var_16_0 = 174

	arg_16_0.heroItems = {}
	arg_16_0.nameItems = {}

	arg_16_0:nodeByName("pos"):removeAllChildren(true)

	for iter_16_0 = 1, 6 do
		local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/cv_link/hero_item.csb")
		local var_16_2 = var_16_1:getChildByName("container")

		var_16_1:addTo(arg_16_0:nodeByName("pos"))
		var_16_1:setPosition(cc.p((iter_16_0 - 1) * var_16_0, 94))

		local var_16_3 = arg_16_0.heroIds[iter_16_0]
		local var_16_4 = var_0_3.new()

		var_16_4:populateWithTableID(var_16_3)
		xyd.setAvatarBorder(var_16_4, var_16_2:getChildByName("avatar_container"))
		var_16_2:getChildByName("hero_name_txt"):setString(var_16_4:getName())
		var_16_2:getChildByName("box_select"):setVisible(false)
		table.insert(arg_16_0.heroItems, var_16_1)

		local var_16_5 = var_16_2:getChildByName("start")
		local var_16_6 = var_16_2:getChildByName("pause")
		local var_16_7 = var_16_2:getChildByName("name_bg"):getChildByName("name_bg1")

		var_16_1.isStart = false

		var_16_6:setVisible(false)
		var_16_5:setTouchEnabled(true)
		var_16_5:setTouchSwallowEnabled(true)
		var_16_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				return true
			elseif arg_17_0.name == "ended" then
				arg_16_0.currentSpeakIdx = iter_16_0

				arg_16_0:updateSoundShow()

				if arg_16_0.audioHandle then
					audio.stopSound(arg_16_0.audioHandle)

					arg_16_0.audioHandle = nil
				end

				if arg_16_0.handle then
					var_0_4.unscheduleGlobal(arg_16_0.handle)

					arg_16_0.handle = nil
				end

				local var_17_0 = var_0_2:sound(var_16_3)
				local var_17_1 = var_0_2:time(var_16_3)

				arg_16_0.audioHandle = audio.playSound(var_17_0, false)

				arg_16_0:isStopBgSound(true)

				local var_17_2 = 0

				arg_16_0.handle = var_0_4.scheduleGlobal(function()
					if arg_16_0 and var_16_5 and not tolua.isnull(var_16_5) then
						var_17_2 = var_17_2 + 1

						if var_17_2 >= var_17_1 then
							arg_16_0.currentSpeakIdx = 0

							if arg_16_0.handle then
								var_0_4.unscheduleGlobal(arg_16_0.handle)

								arg_16_0.handle = nil

								arg_16_0:isStopBgSound(false)
								arg_16_0:updateSoundShow()
							end
						end
					elseif arg_16_0.handle then
						var_0_4.unscheduleGlobal(arg_16_0.handle)

						arg_16_0.handle = nil
					end
				end, 1)
			end
		end)
		var_16_6:setTouchEnabled(true)
		var_16_6:setTouchSwallowEnabled(true)
		var_16_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "began" then
				return true
			elseif arg_19_0.name == "ended" then
				arg_16_0.currentSpeakIdx = 0

				if arg_16_0.audioHandle then
					audio.stopSound(arg_16_0.audioHandle)

					arg_16_0.audioHandle = nil
				end

				if arg_16_0.handle then
					var_0_4.unscheduleGlobal(arg_16_0.handle)

					arg_16_0.handle = nil
				end

				arg_16_0:isStopBgSound(false)
				arg_16_0:updateSoundShow()
			end
		end)
	end

	for iter_16_1 = 1, 6 do
		local var_16_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/cv_link/name_item.csb")
		local var_16_9 = var_16_8:getChildByName("container")

		var_16_8:addTo(arg_16_0:nodeByName("pos"))
		var_16_8:setPosition(cc.p((iter_16_1 - 1) * var_16_0 + 85, 43))
		var_16_9:getChildByName("name_txt"):setString(arg_16_0.cvLinkNames[iter_16_1])
		var_16_9:getChildByName("name_txt"):enableOutline(cc.c4b(185, 37, 173, 255), 2)
		table.insert(arg_16_0.nameItems, var_16_8)
		var_16_8:setTouchEnabled(true)
		var_16_8:setTouchSwallowEnabled(false)

		var_16_8.orgItemPos = cc.p(var_16_8:getPosition())

		var_16_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "began" then
				for iter_20_0 = 1, #arg_16_0.heroToCv do
					if arg_16_0.heroToCv[iter_20_0] == iter_16_1 then
						arg_16_0.heroToCv[iter_20_0] = 0
					end
				end

				arg_16_0:updateBtn()

				arg_16_0.itemPos = cc.p(var_16_8:getPosition())
				arg_16_0.orgPos = cc.p(arg_20_0.x, arg_20_0.y)

				var_16_8:setLocalZOrder(100)

				return true
			elseif arg_20_0.name == "moved" then
				local var_20_0 = xyd.subPosition(arg_20_0, arg_16_0.orgPos)
				local var_20_1 = xyd.addPosition(arg_16_0.itemPos, var_20_0)

				var_16_8:setPosition(var_20_1)
			elseif arg_20_0.name == "ended" then
				local var_20_2, var_20_3 = arg_16_0:getCurrentIdx(var_16_8)

				if var_20_2 and arg_16_0.heroToCv[var_20_2] == 0 then
					arg_16_0.heroToCv[var_20_2] = iter_16_1

					arg_16_0:updateBtn()
					var_16_8:setPosition(var_20_3)
				else
					var_16_8:setPosition(var_16_8.orgItemPos)
				end
			end
		end)
	end

	arg_16_0:update()
end

function var_0_0.getCurrentIdx(arg_21_0, arg_21_1)
	for iter_21_0 = 1, #arg_21_0.heroItems do
		local var_21_0 = arg_21_0.heroItems[iter_21_0]:getChildByName("container")
		local var_21_1 = var_21_0:getChildByName("name_bg")
		local var_21_2 = var_21_0:getContentSize()
		local var_21_3 = arg_21_1:getParent():convertToWorldSpace(cc.p(arg_21_1:getPosition()))
		local var_21_4 = var_21_0:convertToNodeSpace(var_21_3)
		local var_21_5 = xyd.addPosition(cc.p(arg_21_0.heroItems[iter_21_0]:getPosition()), cc.p(var_21_1:getPosition()))

		if var_21_4.x > 0 and var_21_4.y > 0 and var_21_4.x <= var_21_2.width and var_21_4.y <= var_21_2.height then
			return iter_21_0, var_21_5
		end
	end
end

function var_0_0.update(arg_22_0)
	for iter_22_0 = 1, #arg_22_0.heroItems do
		local var_22_0 = arg_22_0.heroItems[iter_22_0]:getChildByName("container"):getChildByName("name_bg")

		var_22_0:getChildByName("name_bg1"):setVisible(false)
		var_22_0:getChildByName("name_bg2"):setVisible(false)
		var_22_0:getChildByName("name_bg3"):setVisible(false)
		var_22_0:setVisible(false)

		if arg_22_0.heroToCv[iter_22_0] > 0 then
			var_22_0:setVisible(true)

			if arg_22_0.details.base_info.is_daily_answer == 1 and not arg_22_0.isShowRightAnswer then
				var_22_0:getChildByName("cv_name_txt"):setString(arg_22_0.cvLinkNames[arg_22_0.heroToCv[iter_22_0]])

				if var_0_2:cv(arg_22_0.heroIds[iter_22_0]) == arg_22_0.cvLinkNames[arg_22_0.heroToCv[iter_22_0]] then
					var_22_0:getChildByName("name_bg2"):setVisible(true)
					var_22_0:getChildByName("cv_name_txt"):enableOutline(cc.c4b(41, 116, 141, 255), 2)
				else
					var_22_0:getChildByName("name_bg3"):setVisible(true)
					var_22_0:getChildByName("cv_name_txt"):enableOutline(cc.c4b(226, 24, 96, 255), 2)
				end
			elseif arg_22_0.details.base_info.is_daily_answer == 1 and arg_22_0.isShowRightAnswer then
				var_22_0:getChildByName("cv_name_txt"):setString(var_0_2:cv(arg_22_0.heroIds[iter_22_0]))
				var_22_0:getChildByName("name_bg2"):setVisible(true)
				var_22_0:getChildByName("cv_name_txt"):enableOutline(cc.c4b(41, 116, 141, 255), 2)
			else
				var_22_0:getChildByName("cv_name_txt"):setString(arg_22_0.cvLinkNames[arg_22_0.heroToCv[iter_22_0]])
				var_22_0:getChildByName("name_bg1"):setVisible(true)
				var_22_0:getChildByName("cv_name_txt"):enableOutline(cc.c4b(185, 37, 173, 255), 2)
			end
		end
	end

	for iter_22_1 = 1, #arg_22_0.nameItems do
		local var_22_1 = arg_22_0.nameItems[iter_22_1]

		if xyd.isInTable(arg_22_0.heroToCv, iter_22_1) then
			var_22_1:setVisible(false)
		else
			var_22_1:setVisible(true)
		end
	end

	arg_22_0:updateBtn()
end

function var_0_0.updateBtn(arg_23_0)
	arg_23_0:nodeByName("result_txt"):setString("")
	arg_23_0:nodeByName("award_text"):setString("")
	arg_23_0:nodeByName("award_txt"):setString("")
	arg_23_0:nodeByName("text_container"):setVisible(false)

	if arg_23_0.details.base_info.is_daily_answer == 0 then
		arg_23_0:nodeByName("show_result_btn"):setVisible(false)
		arg_23_0:nodeByName("answer_btn"):setVisible(true)

		if xyd.isInTable(arg_23_0.heroToCv, 0) then
			arg_23_0:nodeByName("answer_btn"):getChildByName("button_cover"):setVisible(true)
		else
			arg_23_0:nodeByName("answer_btn"):getChildByName("button_cover"):setVisible(false)
		end
	else
		arg_23_0:nodeByName("text_container"):setVisible(true)
		arg_23_0:nodeByName("result_text"):setString(var_0_1:translation("ACTIVITY_CV_LINK_TIP5"))
		arg_23_0:nodeByName("result_txt"):setString(arg_23_0:countRightAnswer())

		if arg_23_0:countRightAnswer() >= 3 then
			arg_23_0:nodeByName("award_text"):setString(var_0_1:translation("ACTIVITY_CV_LINK_TIP6"))
			arg_23_0:nodeByName("award_txt"):setString(1)
			arg_23_0:nodeByName("text_container"):setPositionY(30)
		else
			arg_23_0:nodeByName("text_container"):setPositionY(6)
		end

		arg_23_0:nodeByName("show_result_btn"):setVisible(true)
		arg_23_0:nodeByName("answer_btn"):setVisible(false)

		if arg_23_0.isShowRightAnswer then
			arg_23_0:nodeByName("show_answer_text"):setVisible(false)
			arg_23_0:nodeByName("self_answer_text"):setVisible(true)
		else
			arg_23_0:nodeByName("show_answer_text"):setVisible(true)
			arg_23_0:nodeByName("self_answer_text"):setVisible(false)
		end
	end
end

function var_0_0.updateSoundShow(arg_24_0)
	for iter_24_0 = 1, #arg_24_0.heroItems do
		local var_24_0 = arg_24_0.heroItems[iter_24_0]:getChildByName("container")

		if iter_24_0 == arg_24_0.currentSpeakIdx then
			var_24_0:getChildByName("pause"):setVisible(true)
			var_24_0:getChildByName("start"):setVisible(false)
			var_24_0:getChildByName("box_select"):setVisible(true)
			var_24_0:getChildByName("box"):setVisible(false)
		else
			var_24_0:getChildByName("pause"):setVisible(false)
			var_24_0:getChildByName("start"):setVisible(true)
			var_24_0:getChildByName("box_select"):setVisible(false)
			var_24_0:getChildByName("box"):setVisible(true)
		end
	end
end

function var_0_0.isStopBgSound(arg_25_0, arg_25_1)
	if arg_25_1 then
		xyd.db.settings:setBakgroundMusic(false)
		xyd.db.settings:setAutoDialog(false)
	else
		xyd.db.settings:setBakgroundMusic(arg_25_0.musicSwitch == 1)
		xyd.db.settings:setAutoDialog(arg_25_0.dialogSwitch == 1)
	end
end

return var_0_0
