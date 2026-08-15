local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.activityMizhuTreasure
local var_0_4 = {
	SELF_AWARD = 1,
	ALL_AWARD = 2
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
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container")
	local var_2_2 = var_2_1:getChildByName("reward_container")

	var_2_2:setTouchSwallowEnabled(false)

	local var_2_3 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 664, 370),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0:layout(var_2_1, var_2_3)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_0.activity.details.charge_count
	local var_3_1 = arg_3_0.activity.details.whole_charge_count

	arg_3_1:getChildByName("person_charge_num"):setString(var_3_0)
	arg_3_1:getChildByName("all_charge_num"):setString(var_3_1)
	arg_3_1:getChildByName("word_text1"):setString(var_0_1:translation("ACTIVITY_1102_TEXT1"))
	arg_3_1:getChildByName("word_text2"):setString(var_0_1:translation("ACTIVITY_1102_TEXT2"))
	arg_3_0:initTimeCount(arg_3_1)
	arg_3_1:getChildByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_1:getChildByName("btn_rule"):setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.moved then
			arg_3_1:getChildByName("btn_rule"):setScale(1)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_3_1:getChildByName("btn_rule"):setScale(1)

			local var_4_0 = {
				title_name = "MIZHU_TREASURE_TITLE",
				rule = "MIZHU_TREASURE_RULE"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
		end
	end)

	arg_3_0.tabType = var_0_4.ALL_AWARD

	local var_3_2 = arg_3_1:getChildByName("btn_all")
	local var_3_3 = arg_3_1:getChildByName("btn_self")

	arg_3_0:updateTabState(arg_3_0.tabType, var_3_2, var_3_3)
	var_3_2:getChildByName("word_4_text"):setString(var_0_1:translation("ACTIVITY_1102_TEXT3"))
	var_3_3:getChildByName("word_3_text"):setString(var_0_1:translation("ACTIVITY_1102_TEXT4"))
	var_3_2:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and arg_3_0.tabType ~= var_0_4.ALL_AWARD then
			arg_3_0.tabType = var_0_4.ALL_AWARD

			arg_3_0:updateTabState(arg_3_0.tabType, var_3_2, var_3_3)
			arg_3_0:initAward(arg_3_2, var_0_3:getGiftsByType(arg_3_0.tabType), arg_3_0.tabType)
		end
	end)
	var_3_3:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_3_0.tabType ~= var_0_4.SELF_AWARD then
			arg_3_0.tabType = var_0_4.SELF_AWARD

			arg_3_0:updateTabState(arg_3_0.tabType, var_3_2, var_3_3)
			arg_3_0:initAward(arg_3_2, var_0_3:getGiftsByType(arg_3_0.tabType), arg_3_0.tabType)
		end
	end)
	arg_3_0:initAward(arg_3_2, var_0_3:getGiftsByType(arg_3_0.tabType), arg_3_0.tabType)
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
	if arg_8_1 == var_0_4.ALL_AWARD then
		arg_8_2:setBright(true)
		arg_8_2:setTouchEnabled(false)
		arg_8_3:setTouchEnabled(true)
		arg_8_3:setBright(false)
	else
		arg_8_3:setBright(true)
		arg_8_2:setBright(false)
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
			local var_9_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1102/activity_item.csb")
			local var_9_8 = var_9_7:getChildByName("container")

			arg_9_0:rewardItemLayout(var_9_1, var_9_8, var_9_4, var_9_2[iter_9_0], var_9_3, arg_9_1.type)
			var_9_7:addTo(var_9_6)
			var_9_7:setTouchEnabled(true)
			var_9_7:setAnchorPoint(cc.p(0, 0))
			var_9_7:setPosition(0, 3)
			var_9_7:setTouchSwallowEnabled(false)
			var_9_6:setContentSize(667, 170)
			var_9_5:addContent(var_9_6)
			var_9_5:setItemSize(667, 170)
			var_9_0:addItem(var_9_5)
		end
	end

	var_9_0:reload()
end

function var_0_0.rewardItemLayout(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4, arg_10_5, arg_10_6)
	local var_10_0 = arg_10_2:getChildByName("btn")
	local var_10_1 = arg_10_2:getChildByName("yilingqu")
	local var_10_2 = arg_10_2:getChildByName("lingqu")
	local var_10_3 = arg_10_2:getChildByName("get_gray")
	local var_10_4 = arg_10_2:getChildByName("expired")
	local var_10_5 = arg_10_2:getChildByName("not_begin")
	local var_10_6 = {
		btn = var_10_0,
		alreadyObtain = var_10_1,
		obtain_bright = var_10_2,
		obtain_gray = var_10_3,
		expired = var_10_4,
		notBegin = var_10_5
	}

	arg_10_0:formatStateText(var_10_6)

	local var_10_7 = arg_10_2:getChildByName("reward_container")
	local var_10_8 = arg_10_2:getChildByName("item_title_container")
	local var_10_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_10_9.size = 20

	local var_10_10 = xyd.AssetLoader.get():loadLabel(var_10_9)

	var_10_10:setMaxLineWidth(280)
	var_10_10:addTo(var_10_8)
	var_10_10:setAnchorPoint(cc.p(0, 0))
	var_10_10:setPosition(0, 0)

	local var_10_11 = var_0_3:recharge(arg_10_4)
	local var_10_12 = ""

	if arg_10_6 == var_0_4.ALL_AWARD then
		var_10_12 = string.format(var_0_1:translation("MIZHU_TREASURE_CHARGE_1"), var_10_11)
	else
		var_10_12 = string.format(var_0_1:translation("MIZHU_TREASURE_CHARGE_2"), var_10_11)
	end

	var_10_10:setString(var_10_12)
	arg_10_0:rewardFormat(var_10_7, var_0_3:gift(arg_10_4))

	local var_10_13 = xyd.ServerTime.get():getServerTime()
	local var_10_14
	local var_10_15

	if arg_10_6 == var_0_4.ALL_AWARD then
		var_10_14 = arg_10_1.details.whole_awarded
		var_10_15 = arg_10_1.details.whole_charge_count
	else
		var_10_14 = arg_10_1.details.self_awarded
		var_10_15 = arg_10_1.details.charge_count
	end

	if arg_10_1.details.charge_count == 0 then
		arg_10_0:setBtnGetState(-1, var_10_6)

		return
	end

	if var_10_15 < var_10_11 then
		arg_10_0:setBtnGetState(-1, var_10_6)
	elseif tonumber(var_10_14[tostring(arg_10_4)]) == 1 then
		arg_10_0:setBtnGetState(0, var_10_6)
	else
		arg_10_0:setBtnGetState(1, var_10_6)
	end

	if not arg_10_0:checkTime(arg_10_1) then
		arg_10_0:setBtnGetState(-1, var_10_6)
	end

	var_10_0:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			var_10_0:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.moved then
			var_10_0:setScale(1)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			var_10_0:setScale(1)

			if arg_10_0.scrollViewMoved_ == true then
				return
			end

			local var_11_0 = arg_10_4

			arg_10_0.activitiesModel:getActivityReward(arg_10_1.table_id, var_11_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					arg_10_0.player:handleRewards(arg_12_1.awards)
					arg_10_0:setBtnGetState(0, var_10_6)

					if arg_10_6 == var_0_4.ALL_AWARD then
						local var_12_0 = arg_10_0.activities[arg_10_3].details.whole_awarded

						if var_12_0 and next(var_12_0) then
							var_12_0[tostring(arg_10_4)] = 1
						end

						arg_10_0.activities[arg_10_3].details.whole_awarded = var_12_0
					else
						local var_12_1 = arg_10_0.activities[arg_10_3].details.self_awarded

						if var_12_1 and next(var_12_1) then
							var_12_1[tostring(arg_10_4)] = 1
						end

						arg_10_0.activities[arg_10_3].details.self_awarded = var_12_1
					end

					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):refreshRedMark()

					local var_12_2 = xyd.WindowManager.get():getWindow("activities")

					if var_12_2 and not tolua.isnull(var_12_2) then
						var_12_2:rightLayout()
					end
				end
			end)
		end
	end)
end

function var_0_0.checkTime(arg_13_0, arg_13_1)
	local var_13_0 = xyd.ServerTime.get():getServerTime()
	local var_13_1 = arg_13_1.start_time
	local var_13_2 = arg_13_1.end_time

	if arg_13_1.days < 0 or arg_13_1.days > 0 and var_13_1 <= var_13_0 and var_13_0 <= var_13_2 + 86400 then
		return true
	end

	return false
end

function var_0_0.checkInitItem(arg_14_0, arg_14_1, arg_14_2)
	return true
end

function var_0_0.initTimeCount(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.activity.start_time
	local var_15_1 = arg_15_0.activity.end_time
	local var_15_2 = xyd.ServerTime.get():getServerTime()

	if var_15_2 - var_15_0 < 0 then
		arg_15_1:getChildByName("text_time"):setVisible(false)

		return false
	elseif var_15_1 - var_15_2 < 0 then
		arg_15_1:getChildByName("text_time"):setVisible(false)

		return false
	end

	local var_15_3 = var_15_1 - var_15_2

	arg_15_0:updateTimeCount(arg_15_1, var_15_3)
end

function var_0_0.updateTimeCount(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1:getChildByName("text_time")
	local var_16_1 = var_0_1:translation("MIZHU_TREASURE_COUNT_TIME")

	if arg_16_2 <= 0 then
		var_16_0:setString(var_16_1 .. xyd.secondsToString(arg_16_2))

		return
	end

	local function var_16_2(arg_17_0)
		if arg_17_0 > 86400 then
			return xyd.secondsToString1(arg_17_0)
		else
			return xyd.secondsToString(arg_17_0)
		end
	end

	if arg_16_0.timeHandler then
		var_0_2.unscheduleGlobal(arg_16_0.timeHandler)

		arg_16_0.timeHandler = nil
	end

	if arg_16_2 > 0 then
		var_16_0:setString(var_16_1 .. var_16_2(arg_16_2))

		arg_16_0.timeHandler = var_0_2.scheduleGlobal(function()
			arg_16_2 = arg_16_2 - 1

			if var_16_0 and not tolua.isnull(var_16_0) then
				var_16_0:setString(var_16_1 .. var_16_2(arg_16_2))
			end

			if arg_16_2 <= 0 and arg_16_0.timeHandler then
				var_0_2.unscheduleGlobal(arg_16_0.timeHandler)

				arg_16_0.timeHandler = nil
			end
		end, 1)
	end
end

function var_0_0.release(arg_19_0)
	if arg_19_0.timeHandler then
		var_0_2.unscheduleGlobal(arg_19_0.timeHandler)

		arg_19_0.timeHandler = nil
	end
end

return var_0_0
