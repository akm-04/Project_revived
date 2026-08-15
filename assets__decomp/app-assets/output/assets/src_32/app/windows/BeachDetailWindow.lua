local var_0_0 = class("BeachDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.beachBoss
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.giftbag

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.UnlockNum = 0
	arg_1_0.canGetAwards = true
	arg_1_0.pointLev = {}
	arg_1_0.lev = 0
	arg_1_0.beachMaxLevel = xyd.tables.misc.beachMaxLevel
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.beach = xyd.ModelManager.get():loadModel(xyd.ModelType.BEACH_ACTIVITY)
	arg_2_0.selfplayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.point = arg_2_0.beach:getPoints()
	arg_2_0.awardStepNormal = arg_2_0.beach:getAwardStepNormal()
	arg_2_0.awardStepSpecial = arg_2_0.beach:getAwardStepSpecial()

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super:didOpen()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("btn_buy"):getChildByName("txt_buy"):setString(var_0_2:translation("BEACH_DETAIL_TXT_1"))
	arg_4_0:nodeByName("btn_award"):getChildByName("txt_award"):setString(var_0_2:translation("BEACH_DETAIL_TXT_2"))
	arg_4_0:nodeByName("btn_lock"):getChildByName("txt_lock"):setString(var_0_2:translation("BEACH_DETAIL_TXT_3"))
	arg_4_0:nodeByName("title"):setString(var_0_2:translation("BEACH_DETAIL_TXT_6"))
	arg_4_0:nodeByName("level_txt"):setString(var_0_2:translation("BEACH_DETAIL_TXT_4"))
	arg_4_0:nodeByName("point_word_txt"):setString(var_0_2:translation("BEACH_DETAIL_TXT_5"))

	local var_4_0 = arg_4_0:nodeByName("list"):getContentSize()

	for iter_4_0 = 1, arg_4_0.beachMaxLevel do
		arg_4_0.pointLev[iter_4_0] = xyd.tables.beachGift:pointLev(iter_4_0)
	end

	arg_4_0:update()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.Delegate))
	arg_4_0.scrollList:setBounceable(true)
	arg_4_0.scrollList:reload()
	arg_4_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_buy"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.lev < arg_4_0.beachMaxLevel then
				local var_5_0 = {
					title = var_0_2:translation("TIP"),
					align = xyd.ui_align.CENTER
				}
				local var_5_1 = arg_4_0:getNeedCrystal()

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_2:translation("BEACH_DETAIL_UNLOCK"), var_5_1, arg_4_0.lev + 1)
				}, function()
					if arg_4_0.selfplayer.crystal < var_5_1 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
							var_0_2:translation("ZUANSHI_ABSENCE")
						}, function()
							local var_7_0 = {}

							var_7_0.windowState = true
							var_7_0.chargeState = xyd.ChargeState.diamond

							xyd.WindowManager.get():closeWindow(arg_4_0.name)
							xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
						end, var_5_0, nil, xyd.ColorMode.ACTIVITY)
					else
						local var_6_0 = {
							num = var_5_1 / 10
						}

						arg_4_0.beach:buyPoint(var_6_0, function(arg_8_0, arg_8_1)
							if arg_8_0 == xyd.error.OK then
								arg_4_0.point = arg_8_1.points

								arg_4_0:update()
								arg_4_0.scrollList:reload()

								local var_8_0 = {
									points = arg_4_0.point
								}

								arg_4_0.beach:setParams(var_8_0)
							end
						end)
					end
				end, var_5_0, 0, xyd.ColorMode.ACTIVITY)
			else
				local var_5_2 = var_0_2:translation("BEACH_DETAIL_TXT_8")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_5_2
				})
			end
		end
	end)
	arg_4_0:nodeByName("btn_award"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_award"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_4_0:judgeGetAwards()

			if not arg_4_0.canGetAwards then
				local var_9_0 = var_0_2:translation("BEACH_DETAIL_TXT_7")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_0
				})
			else
				arg_4_0.beach:getPointAward(function(arg_10_0, arg_10_1)
					if arg_10_0 == xyd.error.OK then
						arg_4_0.selfplayer:handleRewards(arg_10_1.awards)

						arg_4_0.awardStepNormal = arg_10_1.award_step_n
						arg_4_0.awardStepSpecial = arg_10_1.award_step_s

						local var_10_0 = {
							award_step_n = arg_4_0.awardStepNormal,
							award_step_s = arg_4_0.awardStepSpecial
						}

						arg_4_0.beach:setParams(var_10_0)
						arg_4_0:update()
						arg_4_0.scrollList:reload()
					end
				end)
			end
		end
	end)
	arg_4_0:nodeByName("btn_lock"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_4_0:nodeByName("btn_lock"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_11_0 = {
				chargeState = xyd.ChargeState.giftbag
			}

			xyd.WindowManager.get():closeWindow(arg_4_0.name)
			xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
		end
	end)
end

function var_0_0.rewardItemLayout(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if arg_12_2 < arg_12_0.beachMaxLevel then
		arg_12_2 = arg_12_2 + 1
	end

	local var_12_0 = xyd.tables.beachGift
	local var_12_1 = var_12_0:normalGift(arg_12_2)
	local var_12_2 = var_12_0:numNormal(arg_12_2)
	local var_12_3 = var_12_0:specialGift(arg_12_2)
	local var_12_4 = var_12_0:numSpecial(arg_12_2)

	arg_12_1:getChildByName("num"):setString(arg_12_2)
	xyd.setItemAndAddTips(arg_12_1:getChildByName("item_container_1"), var_12_1, var_12_2)
	xyd.setItemAndAddTips(arg_12_1:getChildByName("item_container_2"), var_12_3, var_12_4)

	if arg_12_3 then
		arg_12_1:getChildByName("shadow_1"):setVisible(false)
		arg_12_1:getChildByName("shadow_2"):setVisible(false)
	end

	if arg_12_3 then
		if arg_12_2 <= arg_12_0.awardStepNormal then
			arg_12_1:getChildByName("is_signed_1"):setVisible(true)
		else
			arg_12_0.canGetAwards = true
		end

		if arg_12_2 <= arg_12_0.awardStepSpecial then
			arg_12_1:getChildByName("is_signed_2"):setVisible(true)
		else
			arg_12_0.canGetAwards = true
		end
	else
		arg_12_1:getChildByName("is_signed_1"):setVisible(false)
		arg_12_1:getChildByName("is_signed_2"):setVisible(false)
	end

	if arg_12_0.UnlockNum < 1 then
		arg_12_1:getChildByName("shadow_2"):setVisible(true)
	end
end

function var_0_0.getNeedCrystal(arg_13_0)
	local var_13_0 = 0
	local var_13_1 = xyd.tables.misc.beachExchangeRate

	if arg_13_0.lev < arg_13_0.beachMaxLevel then
		var_13_0 = (arg_13_0.pointLev[arg_13_0.lev + 1] - arg_13_0.point) * var_13_1
	else
		var_13_0 = 0
	end

	return var_13_0
end

function var_0_0.update(arg_14_0)
	arg_14_0.lev = 0

	for iter_14_0 = 1, arg_14_0.beachMaxLevel do
		if arg_14_0.point >= arg_14_0.pointLev[iter_14_0] then
			arg_14_0.lev = iter_14_0
		end
	end

	arg_14_0:nodeByName("lev_txt"):setString(arg_14_0.lev)

	local var_14_0 = 0
	local var_14_1 = 0

	if arg_14_0.lev == 0 then
		var_14_0 = arg_14_0.point
		var_14_1 = xyd.tables.beachGift:scorePoint(arg_14_0.lev + 1)
	elseif arg_14_0.lev < arg_14_0.beachMaxLevel then
		var_14_0 = arg_14_0.point - arg_14_0.pointLev[arg_14_0.lev]
		var_14_1 = xyd.tables.beachGift:scorePoint(arg_14_0.lev + 1)
	else
		var_14_0 = arg_14_0.point - arg_14_0.pointLev[arg_14_0.lev - 1]
		var_14_1 = xyd.tables.beachGift:scorePoint(arg_14_0.lev)
	end

	arg_14_0:nodeByName("point_txt"):setString(var_14_0 .. "/" .. var_14_1)

	arg_14_0.UnlockNum = arg_14_0.selfplayer:getBackpack():getItemNumByID(xyd.tables.misc.beachUnlockItem)

	if not arg_14_0.progressBar then
		arg_14_0.progressBar = cc.ProgressTimer:create(cc.Sprite:create("windows/beach_activity/detail_wnd/yellow_progress.png"))

		arg_14_0.progressBar:addTo(arg_14_0:nodeByName("container"))
		arg_14_0.progressBar:setAnchorPoint(cc.p(0.5, 0.5))
		arg_14_0.progressBar:setPosition(arg_14_0:nodeByName("progress_pos"):getPosition())
		arg_14_0.progressBar:setLocalZOrder(10)
		arg_14_0:nodeByName("zhangyu"):setLocalZOrder(11)
		arg_14_0:nodeByName("lev_txt"):setLocalZOrder(12)
		arg_14_0.progressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		arg_14_0.progressBar:setMidpoint(cc.p(0, 0))
		arg_14_0.progressBar:setBarChangeRate(cc.p(1, 0))

		local var_14_2 = cc.ProgressTo:create(0, 100)

		arg_14_0.progressBar:runAction(cc.Repeat:create(var_14_2, 1))
	end

	local var_14_3 = var_14_0 / var_14_1 * 100

	if var_14_3 < 100 and var_14_3 > 99 then
		maybePercent = math.floor(var_14_3)
	elseif var_14_3 > 0 and var_14_3 < 1 then
		maybePercent = math.ceil(var_14_3)
	else
		maybePercent = var_14_3
	end

	local var_14_4 = cc.ProgressTo:create(0, maybePercent)

	arg_14_0.progressBar:runAction(cc.Repeat:create(var_14_4, 1))
end

function var_0_0.Delegate(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if cc.ui.UIListView.COUNT_TAG == arg_15_2 then
		return arg_15_0.beachMaxLevel
	elseif cc.ui.UIListView.CELL_TAG == arg_15_2 then
		local var_15_0 = arg_15_0.scrollList:dequeueItem()

		if not var_15_0 then
			var_15_0 = arg_15_0.scrollList:newItem()
		else
			var_15_0:removeAllChildren(true)
		end

		local var_15_1 = arg_15_0:initCell(arg_15_3)
		local var_15_2 = var_15_1:getWidth()
		local var_15_3 = var_15_1:getHeight()

		var_15_0:setItemSize(var_15_2, var_15_3)
		var_15_0:addContent(var_15_1)

		return var_15_0
	end
end

function var_0_0.initCell(arg_16_0, arg_16_1)
	arg_16_1 = arg_16_1 - 1

	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/beach_activity/detail_wnd/beach_award.csb")
	local var_16_1 = display.newNode()
	local var_16_2 = var_16_0:getChildByName("container")

	var_16_0:addTo(var_16_1)
	var_16_0:setTouchEnabled(true)
	var_16_0:setAnchorPoint(cc.p(0, 0))
	var_16_0:setPosition(0, 0)
	var_16_0:setTouchSwallowEnabled(false)

	if arg_16_0.lev == 0 then
		arg_16_0:rewardItemLayout(var_16_2, arg_16_1, false)
	elseif arg_16_1 < arg_16_0.lev then
		arg_16_0:rewardItemLayout(var_16_2, arg_16_1, true)
	else
		arg_16_0:rewardItemLayout(var_16_2, arg_16_1, false)
	end

	local var_16_3 = var_16_2:getContentSize()

	var_16_1:setContentSize(var_16_3.width, var_16_3.height)

	return var_16_1
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevX_ = arg_17_1.x
	elseif arg_17_1.name == "moved" and 20 <= math.abs(arg_17_1.x - arg_17_0.prevX_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

function var_0_0.judgeGetAwards(arg_18_0)
	local var_18_0

	if arg_18_0.lev == 0 then
		arg_18_0.canGetAwards = false
	elseif arg_18_0.lev > arg_18_0.awardStepNormal then
		arg_18_0.canGetAwards = true

		dump(arg_18_0.canGetAwards)
	elseif arg_18_0.UnlockNum > 0 and arg_18_0.lev > arg_18_0.awardStepSpecial then
		arg_18_0.canGetAwards = true
	end

	if arg_18_0.UnlockNum == 0 then
		if arg_18_0.lev == arg_18_0.awardStepNormal then
			arg_18_0.canGetAwards = false
		end
	elseif arg_18_0.lev == arg_18_0.awardStepSpecial then
		arg_18_0.canGetAwards = false
	end
end

return var_0_0
