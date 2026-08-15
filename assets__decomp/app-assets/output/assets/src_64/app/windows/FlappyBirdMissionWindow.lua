local var_0_0 = class("FlappyBirdMissionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.flappyBirdMission
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.flappyBirdGift
local var_0_6 = xyd.tables.misc
local var_0_7 = {
	DAILY = 1,
	PASS = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.UnlockNum = 0
	arg_1_0.canGetAwards = true
	arg_1_0.pointLev = {}
	arg_1_0.lev = 0
	arg_1_0.flappyBirdPassMaxLevel = var_0_6:getValue("activity_flappy_max_level")
	arg_1_0.showType = 0
	arg_1_0.flappyBird = xyd.ModelManager.get():loadModel(xyd.ModelType.FLAPPY_BIRD)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.point = arg_1_0.flappyBird.baseInfo.points
	arg_1_0.awardStepNormal = arg_1_0.flappyBird.baseInfo.award_step_n
	arg_1_0.awardStepSpecial = arg_1_0.flappyBird.baseInfo.award_step_s
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()
	arg_3_0:initDaily()
	arg_3_0:initPass()
	arg_3_0:updateShow(var_0_7.DAILY)
end

function var_0_0.initDaily(arg_4_0)
	arg_4_0.dailyList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("daily_list"):getWidth(), arg_4_0:nodeByName("daily_list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0:nodeByName("daily_list")):onScroll(handler(arg_4_0, arg_4_0.listener))

	arg_4_0.dailyList:setDelegate(handler(arg_4_0, arg_4_0.dailyDelegate))
	arg_4_0.dailyList:setBounceable(true)
	arg_4_0.dailyList:reload()
end

function var_0_0.initPass(arg_5_0)
	for iter_5_0 = 1, arg_5_0.flappyBirdPassMaxLevel do
		arg_5_0.pointLev[iter_5_0] = var_0_5:pointLev(iter_5_0)
	end

	arg_5_0:updatePass()

	arg_5_0.passList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("pass_list"):getWidth(), arg_5_0:nodeByName("pass_list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_5_0:nodeByName("pass_list")):onScroll(handler(arg_5_0, arg_5_0.listener))

	arg_5_0.passList:setDelegate(handler(arg_5_0, arg_5_0.passDelegate))
	arg_5_0.passList:setBounceable(true)
	arg_5_0.passList:reload()
end

function var_0_0.updatePass(arg_6_0)
	arg_6_0.lev = 0

	for iter_6_0 = 1, arg_6_0.flappyBirdPassMaxLevel do
		if arg_6_0.point >= arg_6_0.pointLev[iter_6_0] then
			arg_6_0.lev = iter_6_0
		end
	end

	arg_6_0:nodeByName("lev_txt"):setString(arg_6_0.lev)

	local var_6_0
	local var_6_1

	if arg_6_0.lev == 0 then
		var_6_0 = arg_6_0.point
		var_6_1 = var_0_5:scorePoint(arg_6_0.lev + 1)
	elseif arg_6_0.lev < arg_6_0.flappyBirdPassMaxLevel then
		var_6_0 = arg_6_0.point - arg_6_0.pointLev[arg_6_0.lev]
		var_6_1 = var_0_5:scorePoint(arg_6_0.lev + 1)
	else
		var_6_0 = arg_6_0.point - arg_6_0.pointLev[arg_6_0.lev - 1]
		var_6_1 = var_0_5:scorePoint(arg_6_0.lev)
	end

	arg_6_0:nodeByName("point_txt"):setString(var_6_0 .. "/" .. var_6_1)

	arg_6_0.UnlockNum = arg_6_0.selfPlayer:getBackpack():getItemNumByID(var_0_6:getValue("activity_flappy_unlock_item"))

	if not arg_6_0.progressBar then
		arg_6_0.progressBar = cc.ProgressTimer:create(cc.Sprite:create("windows/flappy_bird/yellow_progress.png"))

		arg_6_0.progressBar:setAnchorPoint(cc.p(0.5, 0.5))
		arg_6_0.progressBar:addTo(arg_6_0:nodeByName("progress_pos"))
		arg_6_0.progressBar:setLocalZOrder(10)
		arg_6_0.progressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		arg_6_0.progressBar:setMidpoint(cc.p(0, 0))
		arg_6_0.progressBar:setBarChangeRate(cc.p(1, 0))
		arg_6_0.progressBar:setScale(0.86)

		local var_6_2 = cc.ProgressTo:create(0, 100)

		arg_6_0.progressBar:runAction(cc.Repeat:create(var_6_2, 1))
	end

	local var_6_3
	local var_6_4 = var_6_0 / var_6_1 * 100

	if var_6_4 < 100 and var_6_4 > 99 then
		var_6_3 = math.floor(var_6_4)
	elseif var_6_4 > 0 and var_6_4 < 1 then
		var_6_3 = math.ceil(var_6_4)
	else
		var_6_3 = var_6_4
	end

	local var_6_5 = cc.ProgressTo:create(0, var_6_3)

	arg_6_0.progressBar:runAction(cc.Repeat:create(var_6_5, 1))
end

function var_0_0.setTexts(arg_7_0)
	arg_7_0:nodeByName("text_title"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_9"))
	arg_7_0:nodeByName("text_daily"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_10"))
	arg_7_0:nodeByName("text_mission"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_11"))
	arg_7_0:nodeByName("text_one_key_get"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_13"))
	arg_7_0:nodeByName("text_jinjie_unlock"):setString(var_0_4:translation("FLAPPY_BIRD_TEXT_14"))
	arg_7_0:nodeByName("text_buy_level"):setString(var_0_4:translation("BEACH_DETAIL_TXT_1"))
	arg_7_0:nodeByName("level_txt"):setString(var_0_4:translation("BEACH_DETAIL_TXT_4"))
	arg_7_0:nodeByName("point_word_txt"):setString(var_0_4:translation("BEACH_DETAIL_TXT_5"))
end

function var_0_0.setBtns(arg_8_0)
	arg_8_0:nodeByName("btn_daily"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0:updateShow(var_0_7.DAILY)
		end
	end)
	arg_8_0:nodeByName("btn_mission"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0:updateShow(var_0_7.PASS)
		end
	end)
	arg_8_0:nodeByName("btn_one_key_get"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0.flappyBird:getPointAward({}, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					arg_8_0.selfPlayer:handleRewards(arg_12_1.awards)

					arg_8_0.awardStepNormal = arg_12_1.award_step_n
					arg_8_0.awardStepSpecial = arg_12_1.award_step_s

					local var_12_0 = {
						award_step_n = arg_8_0.awardStepNormal,
						award_step_s = arg_8_0.awardStepSpecial
					}

					arg_8_0.flappyBird:setParams(var_12_0)
					arg_8_0:updatePass()
					arg_8_0.passList:reload()
				end
			end)
		end
	end)
	arg_8_0:nodeByName("btn_jinjie_unlock"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {
				chargeState = xyd.ChargeState.giftbag
			}

			xyd.WindowManager.get():closeWindow(arg_8_0.name)
			xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
		end
	end)
	arg_8_0:nodeByName("btn_buy_level"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.lev < arg_8_0.flappyBirdPassMaxLevel then
				local var_14_0 = {
					title = var_0_4:translation("TIP"),
					align = xyd.ui_align.CENTER
				}
				local var_14_1 = arg_8_0:getNeedCrystal()

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_4:translation("BEACH_DETAIL_UNLOCK"), var_14_1, arg_8_0.lev + 1)
				}, function()
					if arg_8_0.selfPlayer.crystal < var_14_1 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
							var_0_4:translation("ZUANSHI_ABSENCE")
						}, function()
							local var_16_0 = {}

							var_16_0.windowState = true
							var_16_0.chargeState = xyd.ChargeState.diamond

							xyd.WindowManager.get():closeWindow(arg_8_0.name)
							xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
						end, var_14_0, nil, xyd.ColorMode.ACTIVITY)
					else
						local var_15_0 = {
							num = var_14_1 / var_0_6:getValue("activity_flappy_exchange_rate")
						}

						arg_8_0.flappyBird:buyPoint(var_15_0, function(arg_17_0, arg_17_1)
							if arg_17_0 == xyd.error.OK then
								arg_8_0.point = arg_17_1.points

								arg_8_0:updatePass()
								arg_8_0.passList:reload()

								local var_17_0 = {
									points = arg_8_0.point
								}

								arg_8_0.flappyBird:setParams(var_17_0)
							end
						end)
					end
				end, var_14_0, 0, xyd.ColorMode.ACTIVITY)
			else
				local var_14_2 = var_0_4:translation("BEACH_DETAIL_TXT_8")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_2
				})
			end
		end
	end)
end

function var_0_0.getNeedCrystal(arg_18_0)
	local var_18_0 = 0
	local var_18_1 = var_0_6:getValue("activity_flappy_exchange_rate")

	if arg_18_0.lev < arg_18_0.flappyBirdPassMaxLevel then
		var_18_0 = (arg_18_0.pointLev[arg_18_0.lev + 1] - arg_18_0.point) * var_18_1
	else
		var_18_0 = 0
	end

	return var_18_0
end

function var_0_0.updateShow(arg_19_0, arg_19_1)
	arg_19_0.showType = arg_19_1

	if arg_19_0.showType == var_0_7.DAILY then
		arg_19_0:nodeByName("daily_container"):setVisible(true)
		arg_19_0:nodeByName("pass_container"):setVisible(false)
		arg_19_0:nodeByName("btn_daily"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_19_0:nodeByName("btn_mission"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_19_0.showType == var_0_7.PASS then
		arg_19_0:nodeByName("daily_container"):setVisible(false)
		arg_19_0:nodeByName("pass_container"):setVisible(true)
		arg_19_0:nodeByName("btn_daily"):setBrightStyle(ccui.BrightStyle.normal)
		arg_19_0:nodeByName("btn_mission"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.passDelegate(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	if cc.ui.UIListView.COUNT_TAG == arg_20_2 then
		return arg_20_0.flappyBirdPassMaxLevel
	elseif cc.ui.UIListView.CELL_TAG == arg_20_2 then
		local var_20_0 = arg_20_0.passList:dequeueItem()

		if not var_20_0 then
			var_20_0 = arg_20_0.passList:newItem()
		else
			var_20_0:removeAllChildren(true)
		end

		local var_20_1 = arg_20_0:initPassCell(arg_20_3)
		local var_20_2 = var_20_1:getWidth()
		local var_20_3 = var_20_1:getHeight()

		var_20_0:setItemSize(var_20_2, var_20_3)
		var_20_0:addContent(var_20_1)

		return var_20_0
	end
end

function var_0_0.dailyDelegate(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	if cc.ui.UIListView.COUNT_TAG == arg_21_2 then
		return #arg_21_0.flappyBird.missionList
	elseif cc.ui.UIListView.CELL_TAG == arg_21_2 then
		local var_21_0 = arg_21_0.dailyList:dequeueItem()

		if not var_21_0 then
			var_21_0 = arg_21_0.dailyList:newItem()
		else
			var_21_0:removeAllChildren(true)
		end

		local var_21_1 = arg_21_0:initDailyCell(arg_21_3)
		local var_21_2 = var_21_1:getWidth()
		local var_21_3 = var_21_1:getHeight()

		var_21_0:setItemSize(var_21_2, var_21_3)
		var_21_0:addContent(var_21_1)

		return var_21_0
	end
end

function var_0_0.initPassCell(arg_22_0, arg_22_1)
	arg_22_1 = arg_22_1 - 1

	local var_22_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/flappy_bird/mission/pass_item.csb")
	local var_22_1 = display.newNode()
	local var_22_2 = var_22_0:getChildByName("container")

	var_22_0:addTo(var_22_1)
	var_22_0:setTouchEnabled(true)
	var_22_0:setAnchorPoint(cc.p(0, 0))
	var_22_0:setPosition(0, 0)
	var_22_0:setTouchSwallowEnabled(false)

	if arg_22_0.lev == 0 then
		arg_22_0:rewardItemLayout(var_22_2, arg_22_1, false)
	elseif arg_22_1 < arg_22_0.lev then
		arg_22_0:rewardItemLayout(var_22_2, arg_22_1, true)
	else
		arg_22_0:rewardItemLayout(var_22_2, arg_22_1, false)
	end

	local var_22_3 = var_22_2:getContentSize()

	var_22_1:setContentSize(var_22_3.width, var_22_3.height)

	return var_22_1
end

function var_0_0.initDailyCell(arg_23_0, arg_23_1)
	local var_23_0 = display.newNode()

	if arg_23_0.flappyBird.missionList[arg_23_1].is_award == 0 then
		local var_23_1 = arg_23_0.flappyBird.missionList[arg_23_1].mission_id
		local var_23_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/flappy_bird/mission/mission_item.csb")
		local var_23_3 = var_23_2:getChildByName("container")

		var_23_2:addTo(var_23_0)
		var_23_2:setTouchEnabled(true)
		var_23_2:setAnchorPoint(cc.p(0, 0))
		var_23_2:setPosition(0, 0)
		var_23_2:setTouchSwallowEnabled(false)

		local var_23_4 = var_23_3:getChildByName("line")

		var_0_2.new({
			size = var_23_4:getWidth(),
			type = xyd.SplitlineType.SOLID
		}):addTo(var_23_4)
		var_23_3:getChildByName("name"):setString(var_0_3:name(var_23_1))
		var_23_3:getChildByName("desc"):setString(var_0_3:desc(var_23_1))
		var_23_3:getChildByName("score_num"):setString(var_0_3:point(var_23_1))
		var_23_3:getChildByName("progress"):setString(arg_23_0.flappyBird.missionList[arg_23_1].count .. "/" .. var_0_3:taskNum(var_23_1))
		xyd.setSpriteBorder(var_23_3:getChildByName("icon"), var_0_3:icon(var_23_1), 1)

		local var_23_5 = arg_23_0.flappyBird.missionList[arg_23_1].count >= var_0_3:taskNum(var_23_1)

		var_23_3:getChildByName("can_award"):setVisible(var_23_5)

		if var_23_5 then
			var_23_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
				if arg_24_0.name == "ended" then
					xyd.playButtonSound()

					local var_24_0 = {
						id = arg_23_0.flappyBird.missionList[arg_23_1].mission_id
					}

					arg_23_0.flappyBird:getAward(var_24_0, function(arg_25_0, arg_25_1)
						if arg_25_0 == xyd.error.OK then
							arg_23_0.flappyBird.missionList[arg_23_1].is_award = 1

							arg_23_0.dailyList:reload()

							arg_23_0.point = arg_23_0.point + arg_25_1.points

							arg_23_0:updatePass()

							local var_25_0 = {
								points = arg_23_0.point
							}

							arg_23_0.flappyBird:setParams(var_25_0)
						end
					end)
				end

				return true
			end)
		end

		local var_23_6 = var_23_3:getContentSize()

		var_23_0:setContentSize(var_23_6.width, var_23_6.height + 15)
	end

	return var_23_0
end

function var_0_0.listener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.scrollViewMoved_ = false
		arg_26_0.prevX_ = arg_26_1.x
	elseif arg_26_1.name == "moved" and 20 <= math.abs(arg_26_1.x - arg_26_0.prevX_) then
		arg_26_0.scrollViewMoved_ = true
	end
end

function var_0_0.rewardItemLayout(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if arg_27_2 < arg_27_0.flappyBirdPassMaxLevel then
		arg_27_2 = arg_27_2 + 1
	end

	local var_27_0 = var_0_5:normalGift(arg_27_2)
	local var_27_1 = var_0_5:numNormal(arg_27_2)
	local var_27_2 = var_0_5:specialGift(arg_27_2)
	local var_27_3 = var_0_5:numSpecial(arg_27_2)

	arg_27_1:getChildByName("num"):setString(arg_27_2)
	xyd.setItemAndAddTips(arg_27_1:getChildByName("item_container_1"), var_27_0, var_27_1)
	xyd.setItemAndAddTips(arg_27_1:getChildByName("item_container_2"), var_27_2, var_27_3)

	if arg_27_3 then
		arg_27_1:getChildByName("shadow_1"):setVisible(false)
		arg_27_1:getChildByName("shadow_2"):setVisible(false)
	end

	print("==================", arg_27_0.awardStepNormal, arg_27_0.awardStepSpecial, arg_27_2)

	if arg_27_3 then
		if arg_27_2 <= arg_27_0.awardStepNormal then
			arg_27_1:getChildByName("is_signed_1"):setVisible(true)
		else
			arg_27_0.canGetAwards = true
		end

		if arg_27_2 <= arg_27_0.awardStepSpecial then
			arg_27_1:getChildByName("is_signed_2"):setVisible(true)
		else
			arg_27_0.canGetAwards = true
		end
	else
		arg_27_1:getChildByName("is_signed_1"):setVisible(false)
		arg_27_1:getChildByName("is_signed_2"):setVisible(false)
	end

	if arg_27_0.UnlockNum < 1 then
		arg_27_1:getChildByName("shadow_2"):setVisible(true)
	end
end

function var_0_0.judgeGetAwards(arg_28_0)
	local var_28_0

	if arg_28_0.lev == 0 then
		arg_28_0.canGetAwards = false
	elseif arg_28_0.lev > arg_28_0.awardStepNormal then
		arg_28_0.canGetAwards = true
	elseif arg_28_0.UnlockNum > 0 and arg_28_0.lev > arg_28_0.awardStepSpecial then
		arg_28_0.canGetAwards = true
	end

	if arg_28_0.UnlockNum == 0 then
		if arg_28_0.lev == arg_28_0.awardStepNormal then
			arg_28_0.canGetAwards = false
		end
	elseif arg_28_0.lev == arg_28_0.awardStepSpecial then
		arg_28_0.canGetAwards = false
	end
end

function var_0_0.didOpen(arg_29_0)
	arg_29_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
