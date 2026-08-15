local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = 3
local var_0_4 = xyd.tables.activityGoddessStrategy
local var_0_5 = {
	TOTAL = 2,
	SINGLE_DAY = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("reward_container")
	local var_2_3 = var_2_2:getContentSize()

	var_2_2:setTouchSwallowEnabled(false)

	local var_2_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_3.width, var_2_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0:layout(var_2_1, var_2_4)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	arg_3_1:getChildByName("txt_charge"):setString(var_0_1:translation("ACTIVITY_TODAY_HAS_SAVED"))
	arg_3_1:getChildByName("txt_point"):setString(var_0_1:translation("SUPER_RICH_RANK_TEXT1"))

	local var_3_0 = arg_3_0.activity.details.total_point
	local var_3_1 = arg_3_0.activity.details.daily_charge_count

	arg_3_1:getChildByName("single_day_num"):setString(var_3_1)
	arg_3_1:getChildByName("total_num"):setString(var_3_0)

	arg_3_0.pointContainer = arg_3_1:getChildByName("total_num")

	arg_3_1:getChildByName("text_desc"):setString(var_0_1:translation("GODDESS_STRATEGY_TIPS"))
	arg_3_0:initTimeCount(arg_3_1)

	local var_3_2 = arg_3_1:getChildByName("btn_rule")

	var_3_2:getChildByName("txt"):setString(var_0_1:translation("SPRINGLOGIN_RULE_TITLE"))
	var_3_2:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = {
				title_name = "GODDESS_STRATEGY_TITLE",
				rule = "GODDESS_STRATEGY_RULE"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
		end
	end)

	arg_3_0.tabType = var_0_5.SINGLE_DAY

	local var_3_3 = arg_3_1:getChildByName("btn_single_day")

	var_3_3:getChildByName("txt"):setString(var_0_1:translation("PER_DAY_AWARD"))

	local var_3_4 = arg_3_1:getChildByName("btn_total")

	var_3_4:getChildByName("txt"):setString(var_0_1:translation("POINT_AWARD"))
	arg_3_0:updateTabState(arg_3_0.tabType, var_3_3, var_3_4)
	var_3_3:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and arg_3_0.tabType ~= var_0_5.SINGLE_DAY then
			arg_3_0.tabType = var_0_5.SINGLE_DAY

			arg_3_0:updateTabState(arg_3_0.tabType, var_3_3, var_3_4)
			arg_3_0:initAward(arg_3_2, var_0_4:getGiftsByType(arg_3_0.tabType), arg_3_0.tabType)
		end
	end)
	var_3_4:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_3_0.tabType ~= var_0_5.TOTAL then
			arg_3_0.tabType = var_0_5.TOTAL

			arg_3_0:updateTabState(arg_3_0.tabType, var_3_3, var_3_4)
			arg_3_0:initAward(arg_3_2, var_0_4:getGiftsByType(arg_3_0.tabType), arg_3_0.tabType)
		end
	end)
	arg_3_0:initAward(arg_3_2, var_0_4:getGiftsByType(arg_3_0.tabType), arg_3_0.tabType)
end

function var_0_0.initAward(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = {
		list = arg_7_1,
		listIDs = arg_7_2,
		activity = arg_7_0.activity,
		count = arg_7_0.idx,
		type = arg_7_3
	}

	arg_7_0:createAwardList(var_7_0)
end

function var_0_0.updateTabState(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if arg_8_1 == var_0_5.SINGLE_DAY then
		arg_8_2:setBrightStyle(ccui.BrightStyle.highlight)
		arg_8_2:setTouchEnabled(false)
		arg_8_3:setTouchEnabled(true)
		arg_8_3:setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_8_3:setBrightStyle(ccui.BrightStyle.highlight)
		arg_8_2:setBrightStyle(ccui.BrightStyle.normal)
		arg_8_3:setTouchEnabled(false)
		arg_8_2:setTouchEnabled(true)
	end
end

function var_0_0.createAwardList(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1.list
	local var_9_1 = arg_9_1.activity
	local var_9_2 = arg_9_1.listIDs
	local var_9_3 = #var_9_2
	local var_9_4 = arg_9_1.count

	var_9_0:removeAllItems()

	for iter_9_0 = 1, #var_9_2 do
		if arg_9_0:checkInitItem(iter_9_0, arg_9_1) then
			local var_9_5 = var_9_0:newItem()
			local var_9_6 = display.newNode()
			local var_9_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1103/award_item.csb")
			local var_9_8 = var_9_7:getChildByName("container")

			arg_9_0:rewardItemLayout(var_9_1, var_9_8, var_9_4, var_9_2[iter_9_0], var_9_3, arg_9_1.type, var_9_0)
			var_9_7:addTo(var_9_6)
			var_9_7:setTouchEnabled(true)
			var_9_7:setAnchorPoint(cc.p(0, 0))
			var_9_7:setPosition(0, 5)
			var_9_7:setTouchSwallowEnabled(false)
			var_9_6:setContentSize(667, 166)
			var_9_5:addContent(var_9_6)
			var_9_5:setItemSize(667, 176)
			var_9_0:addItem(var_9_5)
		end
	end

	var_9_0:reload()
end

function var_0_0.rewardItemLayout(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6, arg_10_7)
	local var_10_0 = var_0_4:recharge(arg_10_4)
	local var_10_1 = var_0_4:point(arg_10_4)
	local var_10_2 = ""

	if arg_10_6 == var_0_5.SINGLE_DAY then
		var_10_2 = string.format(var_0_1:translation("GODDESS_STRATEGY_CHARGE_1"), var_10_0)

		arg_10_2:getChildByName("desc2"):setString(string.format(var_0_1:translation("GODDNESS_CAN_GET_POINT"), var_10_1))
	else
		var_10_2 = string.format(var_0_1:translation("GODDESS_STRATEGY_CHARGE_2"), var_10_0)
	end

	arg_10_2:getChildByName("desc"):setString(var_10_2)

	local var_10_3
	local var_10_4

	for iter_10_0 = 1, #var_0_4:gift(arg_10_4) do
		local var_10_5 = ""
		local var_10_6 = arg_10_2:getChildByName("btn" .. var_10_5)
		local var_10_7 = var_10_6:getChildByName("txt")

		var_10_7:setString(var_0_1:translation("OBTAIN"))

		local var_10_8 = arg_10_2:getChildByName("already_get" .. var_10_5)
		local var_10_9 = arg_10_2:getChildByName("award_container" .. var_10_5)

		arg_10_0:rewardFormat(var_10_9, var_0_4:gift(arg_10_4)[iter_10_0])

		local var_10_10 = xyd.ServerTime.get():getServerTime()
		local var_10_11
		local var_10_12

		if arg_10_6 == var_0_5.SINGLE_DAY then
			var_10_11 = arg_10_1.details.daily_awarded
			var_10_12 = arg_10_1.details.daily_charge_count
		else
			var_10_11 = arg_10_1.details.whole_awarded
			var_10_12 = arg_10_1.details.total_point
		end

		if arg_10_6 == var_0_5.SINGLE_DAY then
			if var_10_12 < var_10_0 then
				var_10_6:setVisible(false)
				var_10_8:setVisible(false)
			elseif tonumber(var_10_11[tostring(arg_10_4)]) == 1 then
				var_10_6:setVisible(false)
				var_10_8:setVisible(true)
			else
				var_10_6:setVisible(true)
				var_10_8:setVisible(false)
			end
		elseif var_10_12 < var_10_0 then
			var_10_6:setVisible(false)
			var_10_8:setVisible(false)
		elseif tonumber(var_10_11[tostring(arg_10_4)]) == 1 then
			var_10_6:setVisible(false)
			var_10_8:setVisible(true)
		else
			var_10_6:setVisible(true)
			var_10_8:setVisible(false)
		end

		if not arg_10_0:checkTime(arg_10_1) then
			var_10_6:setVisible(false)
			var_10_8:setVisible(false)
		end

		if var_10_10 < arg_10_1.start_time then
			var_10_6:setVisible(true)
			var_10_8:setVisible(false)
			var_10_7:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT3"))
		end

		var_10_6:addTouchEventListener(function(arg_11_0, arg_11_1)
			xyd.buttonScaleAnim(var_10_6, arg_11_1)

			if arg_11_1 == ccui.TouchEventType.ended then
				local function var_11_0()
					local var_12_0 = arg_10_4
					local var_12_1 = 1

					arg_10_0.activitiesModel:getActivityReward2(arg_10_1.table_id, var_12_0, iter_10_0, function(arg_13_0, arg_13_1)
						if arg_13_0 == xyd.error.OK then
							arg_10_0.player:handleRewards(arg_13_1.awards)
							var_10_6:setVisible(false)
							var_10_8:setVisible(true)

							if var_10_3 then
								var_10_6:setVisible(false)
								var_10_8:setVisible(true)
							end

							if var_10_4 then
								var_10_6:setVisible(false)
								var_10_8:setVisible(true)
							end

							if arg_10_6 == var_0_5.TOTAL then
								local var_13_0 = arg_10_0.activities[arg_10_3].details.whole_awarded

								if var_13_0 and next(var_13_0) then
									var_13_0[tostring(arg_10_4)] = 1
								end
							else
								local var_13_1 = arg_10_0.activities[arg_10_3].details.daily_awarded

								if var_13_1 and next(var_13_1) then
									var_13_1[tostring(arg_10_4)] = 1
								end

								arg_10_0.activities[arg_10_3].details = arg_13_1.base_info

								local var_13_2 = xyd.WindowManager.get():getWindow("activities")

								if var_13_2 then
									var_13_2:leftLayout(arg_10_3)
								end
							end

							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):refreshRedMark()

							local var_13_3 = xyd.WindowManager.get():getWindow("activities")

							if var_13_3 and not tolua.isnull(var_13_3) then
								var_13_3:rightLayout()
							end
						end
					end)
				end

				if #var_0_4:gift(arg_10_4) > 1 then
					local var_11_1 = xyd.tables.translation:translation("GODDESS_SELECT_AWARD_TIP")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_1, function()
						var_11_0()
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					var_11_0()
				end
			end
		end)
	end
end

function var_0_0.checkInitItem(arg_15_0, arg_15_1, arg_15_2)
	return true
end

function var_0_0.initTimeCount(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.activity.start_time
	local var_16_1 = arg_16_0.activity.end_time
	local var_16_2 = xyd.ServerTime.get():getServerTime()

	if var_16_2 - var_16_0 < 0 then
		arg_16_1:getChildByName("text_time"):setVisible(false)

		return false
	elseif var_16_1 - var_16_2 < 0 then
		arg_16_1:getChildByName("text_time"):setVisible(false)

		return false
	end

	local var_16_3 = var_16_1 - var_16_2

	arg_16_0:updateTimeCount(arg_16_1, var_16_3)
end

function var_0_0.updateTimeCount(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1:getChildByName("text_time")
	local var_17_1 = var_0_1:translation("MIZHU_TREASURE_COUNT_TIME")

	if arg_17_2 <= 0 then
		var_17_0:setString(var_17_1 .. xyd.secondsToString(arg_17_2))

		return
	end

	local function var_17_2(arg_18_0)
		if arg_18_0 > 86400 then
			return xyd.secondsToString1(arg_18_0)
		else
			return xyd.secondsToString(arg_18_0)
		end
	end

	if arg_17_0.timeHandler then
		var_0_2.unscheduleGlobal(arg_17_0.timeHandler)

		arg_17_0.timeHandler = nil
	end

	if arg_17_2 > 0 then
		var_17_0:setString(var_17_1 .. var_17_2(arg_17_2))

		arg_17_0.timeHandler = var_0_2.scheduleGlobal(function()
			arg_17_2 = arg_17_2 - 1

			if var_17_0 and not tolua.isnull(var_17_0) then
				var_17_0:setString(var_17_1 .. var_17_2(arg_17_2))
			end

			if arg_17_2 <= 0 and arg_17_0.timeHandler then
				var_0_2.unscheduleGlobal(arg_17_0.timeHandler)

				arg_17_0.timeHandler = nil
			end
		end, 1)
	end
end

function var_0_0.release(arg_20_0)
	if arg_20_0.timeHandler then
		var_0_2.unscheduleGlobal(arg_20_0.timeHandler)

		arg_20_0.timeHandler = nil
	end
end

return var_0_0
