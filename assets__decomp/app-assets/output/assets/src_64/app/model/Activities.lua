local var_0_0 = class("Activities", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = 980
local var_0_3 = xyd.tables.announce
local var_0_4 = {
	GET_AWARD_STATE = 1,
	TODAY_OPEN_STATE = 4,
	NEW_ACTIVITY_STATE = 2
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.activities = {}
	arg_1_0.redMarkMap = {}
	arg_1_0.noticeIDs = {}
	arg_1_0.isRedMark = false
	arg_1_0.isActivitiesRedMark = false
	arg_1_0.isBoardRedMark = false
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isSkillHalfOpen = false
	arg_1_0.vipFlag = false
	arg_1_0.lastvip = arg_1_0.player.vip
	arg_1_0.isLevelChargePointShow = false
	arg_1_0.noticeIDs = {}
	arg_1_0.boardInfo = {}
	arg_1_0.isBoardInfoValid = false
end

function var_0_0.getActivityRedMark(arg_2_0)
	return arg_2_0.isActivitiesRedMark
end

function var_0_0.getBoardRedMark(arg_3_0)
	return arg_3_0.isBoardRedMark
end

function var_0_0.loadBoardInfoList(arg_4_0)
	xyd.Backend.get():request(xyd.mid.GET_BOARD_INFO, nil, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.boardInfo = arg_5_1.contents or {}

			table.sort(arg_4_0.boardInfo, function(arg_6_0, arg_6_1)
				return arg_6_0.notice_id > arg_6_1.notice_id
			end)

			arg_4_0.isBoardInfoValid = true

			arg_4_0:refreshRedMark()
		end
	end)

	return arg_4_0.boardInfo
end

function var_0_0.getBoardInfoList(arg_7_0)
	return arg_7_0.boardInfo
end

function var_0_0.onRegister(arg_8_0)
	var_0_0.super.onRegister(arg_8_0)
	arg_8_0:registerEvent(xyd.event.LOAD_ACTIVITIES, handler(arg_8_0, arg_8_0.onLoadActivities_))
	arg_8_0:registerEvent(xyd.event.LOAD_SINGLE_ACTIVITY, handler(arg_8_0, arg_8_0.onLoadSingleActivity_))
	arg_8_0:registerEvent(xyd.event.UPDATE_ACTIVITIES_ONTIME, handler(arg_8_0, arg_8_0.onUpdateActivitiesOnTime_))
	arg_8_0:registerEvent(xyd.event.UPDATE_POINT_WAY, handler(arg_8_0, arg_8_0.onUpdatePoint_))
	arg_8_0:registerEvent(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_8_0, arg_8_0.onUpdateActivitiesOnTime_))
	arg_8_0:registerEvent(xyd.event.VIP_LEVEL_CHANGE, handler(arg_8_0, arg_8_0.vipchange))
	arg_8_0:registerEvent(xyd.event.ACTIVITY_BROADCAST, handler(arg_8_0, arg_8_0.activityBroadcast_))
	arg_8_0:registerEvent(xyd.event.ACTIVITY_LVBU_BROADCAST, handler(arg_8_0, arg_8_0.lvbuBroadcast_))
end

function var_0_0.vipchange(arg_9_0, arg_9_1)
	if arg_9_1.params and arg_9_1.params.vip and arg_9_1.params.vip < 5 then
		arg_9_0.vipFlag = true

		arg_9_0:refreshRedMark()
	end
end

function var_0_0.loadActivities(arg_10_0, arg_10_1)
	xyd.Backend.get():request(xyd.mid.ACTIVITIES, {}, function(arg_11_0, arg_11_1)
		if arg_10_1 then
			arg_10_1(arg_11_0)
		end
	end)
end

function var_0_0.onUpdateActivitiesOnTime_(arg_12_0, arg_12_1)
	if not arg_12_0.player or not arg_12_0.player.hasLogin_ then
		return
	end

	arg_12_0:loadActivities()
end

function var_0_0.buyFund(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.BUY_FUND, {}, function(arg_14_0, arg_14_1)
		if arg_13_1 then
			arg_13_1(arg_14_0)
		end
	end)
end

function var_0_0.openSubject(arg_15_0, arg_15_1)
	xyd.Backend.get():request(xyd.mid.ACTIVITY_OPEN_SUBJECT, {}, function(arg_16_0, arg_16_1)
		if arg_15_1 then
			arg_15_1(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.answerQuestion(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.ACTIVITY_ANSWER_QUESTION, var_17_0, function(arg_18_0, arg_18_1)
		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.selectExternalAward(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.ACTIVITY_SELECT_AWARD, var_19_0, function(arg_20_0, arg_20_1)
		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.getActivityReward(arg_21_0, arg_21_1, arg_21_2, arg_21_3)
	local var_21_0 = {
		activity_id = arg_21_1,
		award_id = arg_21_2
	}

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_21_0, function(arg_22_0, arg_22_1)
		if arg_21_3 then
			arg_21_3(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.getActivityReward2(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4)
	local var_23_0 = {
		activity_id = arg_23_1,
		award_id = arg_23_2,
		sub_award_id = arg_23_3
	}

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_23_0, function(arg_24_0, arg_24_1)
		if arg_23_4 then
			arg_23_4(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.loadSingleActivity(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, var_25_0, function(arg_26_0, arg_26_1)
		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.activityListSort(arg_27_0)
	if not arg_27_0.activities then
		return
	end

	local var_27_0 = xyd.ServerTime.get():getServerTime()

	function comps(arg_28_0, arg_28_1)
		if tonumber(arg_28_0.table_id) == xyd.Activities.GROW_UP or tonumber(arg_28_1.table_id) == xyd.Activities.GROW_UP then
			return tonumber(arg_28_0.table_id) == xyd.Activities.GROW_UP
		elseif tonumber(arg_28_0.table_id) == xyd.Activities.New_Date or tonumber(arg_28_1.table_id) == xyd.Activities.New_Date then
			return tonumber(arg_28_0.table_id) == xyd.Activities.New_Date
		elseif (arg_28_0.days < 0 or arg_28_0.end_time > var_27_0) and arg_28_1.days >= 0 and arg_28_1.end_time <= var_27_0 then
			return true
		elseif arg_28_0.days >= 0 and arg_28_0.end_time <= var_27_0 and (arg_28_1.days < 0 or arg_28_1.end_time > var_27_0) then
			return false
		elseif xyd.tables.activities:seque(arg_28_0.table_id) ~= xyd.tables.activities:seque(arg_28_1.table_id) then
			return xyd.tables.activities:seque(arg_28_0.table_id) < xyd.tables.activities:seque(arg_28_1.table_id)
		else
			return arg_28_0.table_id > arg_28_1.table_id
		end
	end

	table.sort(arg_27_0.activities, comps)
end

function var_0_0.onLoadActivities_(arg_29_0, arg_29_1)
	arg_29_0.oldActivities = arg_29_0.activities
	arg_29_0.activities = arg_29_1.params.list

	arg_29_0:activityListSort()
	arg_29_0:refreshRedMark(arg_29_0.activities)
	arg_29_0:onlineActivityCount()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_TOP_ACTIVITIES
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_CHARGE_ACTIVITY_MAIN,
		params = {
			isShow = arg_29_0:isFirstChargeShow(),
			hasPoint = arg_29_0:hasFirstChargePoint()
		}
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_SUMMER_SHOW,
		params = {
			isShow = arg_29_0:isActivityOpen(xyd.Activities.Summer)
		}
	})
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_GARDEN_SHOW,
		params = {
			isShow = arg_29_0:isActivityOpen(xyd.Activities.Garden)
		}
	})
	arg_29_0:checkHalfPriceOpen()
	arg_29_0:checkMagicShopActivityOpen()
	arg_29_0:checkVipWeekRedMardInDB()
	arg_29_0:isBeachShow()

	arg_29_0.noticeIDs = xyd.db.boardRedMark:getAllNoticeIDs(arg_29_0.player.playerID)
	arg_29_0.boardInfo = arg_29_0:loadBoardInfoList()

	if arg_29_0:isActivitiesListChange(arg_29_0.oldActivities, arg_29_0.activities) then
		local var_29_0 = xyd.WindowManager.get():getWindow("activities")

		if var_29_0 then
			print("Shall we change the list?")

			var_29_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivitiesList()

			var_29_0:rightLayout()
			var_29_0.rightList:reload()

			var_29_0.count = arg_29_0:getShowActivityCount()

			if var_29_0.count then
				var_29_0:leftLayout(var_29_0.count)
			end
		end
	end
end

function var_0_0.isPlayRecallTalk(arg_30_0)
	for iter_30_0, iter_30_1 in pairs(arg_30_0.activities) do
		if iter_30_1.table_id == xyd.Activities.Recall and iter_30_1.details and iter_30_1.details.base_info then
			local var_30_0 = iter_30_1.details.base_info.recall_time
			local var_30_1 = {
				playerID = arg_30_0.player.playerID,
				name = xyd.state.LAST_RECALL_TIME,
				state = tostring(var_30_0)
			}
			local var_30_2 = tonumber(xyd.db.stateVariable:getState(var_30_1.playerID, var_30_1.name))
			local var_30_3 = xyd.ServerTime.get():getServerTime()

			if var_30_0 > 0 and math.abs(var_30_0 - var_30_2) > 7776000 and math.abs(var_30_3 - var_30_0) < 3600 then
				xyd.db.stateVariable:setState(var_30_1)

				return true
			end
		end
	end

	return false
end

function var_0_0.isActivitiesListChange(arg_31_0, arg_31_1, arg_31_2)
	if #arg_31_1 ~= #arg_31_2 then
		return true
	end

	return false
end

function var_0_0.getShowActivityCount(arg_32_0)
	if not arg_32_0.currentClickActivity then
		return 1
	end

	for iter_32_0, iter_32_1 in pairs(arg_32_0.activities) do
		if iter_32_1.table_id == arg_32_0.currentClickActivity then
			return iter_32_0
		end
	end

	return 1
end

function var_0_0.onLoadSingleActivity_(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_1.params

	if var_33_0 then
		local var_33_1 = #arg_33_0.activities

		for iter_33_0, iter_33_1 in pairs(arg_33_0.activities) do
			if iter_33_1.table_id == var_33_0.table_id then
				table.remove(arg_33_0.activities, iter_33_0)

				var_33_1 = iter_33_0

				break
			end
		end

		table.insert(arg_33_0.activities, var_33_1, var_33_0)
		arg_33_0:checkHalfPriceOpen()
	end
end

function var_0_0.onlineActivityCount(arg_34_0)
	if arg_34_0.activities then
		for iter_34_0, iter_34_1 in ipairs(arg_34_0.activities) do
			if iter_34_1.table_id == xyd.Activities.OnlineReward and iter_34_1.is_open == 1 then
				local var_34_0 = iter_34_1.details
				local var_34_1 = var_34_0.gift_times
				local var_34_2 = var_34_0.server_time - var_34_0.award_time
				local var_34_3 = xyd.tables.activityOnlineReward

				if var_34_1 < #var_34_3:all() then
					if var_34_2 < var_34_3:getOnlineTime(var_34_1 + 1) then
						arg_34_0.onlineInversalTime = (var_34_3:getOnlineTime(var_34_1 + 1) - var_34_2) * 30

						if not arg_34_0.onlineHandle then
							arg_34_0.onlineHandle = var_0_1.scheduleUpdateGlobal(handler(arg_34_0, arg_34_0.OnlineActivityLoop))
						end
					else
						if arg_34_0.onlineHandle then
							var_0_1.unscheduleGlobal(arg_34_0.onlineHandle)

							arg_34_0.onlineHandle = nil
						end

						print("online activity red mark line 173")

						arg_34_0.isRedMark = true

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
							params = {
								index = 3,
								show = true
							}
						})

						arg_34_0.redMarkMap[xyd.Activities.OnlineReward].state = arg_34_0.redMarkMap[xyd.Activities.OnlineReward].state + var_0_4.GET_AWARD_STATE
					end
				end
			end
		end
	end
end

function var_0_0.OnlineActivityLoop(arg_35_0)
	if arg_35_0.onlineInversalTime then
		arg_35_0.onlineInversalTime = arg_35_0.onlineInversalTime - 1

		if arg_35_0.onlineInversalTime <= 0 then
			print("online activity red mark line 194")

			arg_35_0.isRedMark = true

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
				params = {
					index = 3,
					show = true
				}
			})

			arg_35_0.redMarkMap[xyd.Activities.OnlineReward].state = arg_35_0.redMarkMap[xyd.Activities.OnlineReward].state + var_0_4.GET_AWARD_STATE
			arg_35_0.onlineInversalTime = nil

			var_0_1.unscheduleGlobal(arg_35_0.onlineHandle)

			arg_35_0.onlineHandle = nil
		end
	end
end

function var_0_0.onUpdatePoint_(arg_36_0, arg_36_1)
	local var_36_0 = xyd.WindowManager.get():getWindow("get_point_window")

	if var_36_0 then
		var_36_0:updateWindow()
	end

	local var_36_1 = xyd.WindowManager.get():getWindow("activities")

	if var_36_1 then
		arg_36_0:loadActivities(function(arg_37_0)
			if arg_37_0 == xyd.error.OK then
				var_36_1.activities = arg_36_0:getActivitiesList()

				if arg_36_0.count then
					var_36_1:leftLayout(arg_36_0.count)
				end
			end
		end)
	end
end

function var_0_0.checkHalfPriceOpen(arg_38_0)
	for iter_38_0, iter_38_1 in pairs(arg_38_0.activities) do
		if iter_38_1.table_id == xyd.Activities.HalfPriceSkill then
			local var_38_0 = iter_38_1.start_time
			local var_38_1 = iter_38_1.end_time
			local var_38_2 = xyd.ServerTime.get():getServerTime()

			if var_38_0 <= var_38_2 and var_38_2 < var_38_1 then
				arg_38_0.isSkillHalfOpen = true

				return
			end
		end
	end

	arg_38_0.isSkillHalfOpen = false
end

function var_0_0.checkMagicShopActivityOpen(arg_39_0)
	for iter_39_0, iter_39_1 in pairs(arg_39_0.activities) do
		if iter_39_1.table_id == xyd.Activities.MagicShop then
			local var_39_0 = iter_39_1.start_time
			local var_39_1 = iter_39_1.end_time
			local var_39_2 = xyd.ServerTime.get():getServerTime()

			if var_39_0 <= var_39_2 and var_39_2 < var_39_1 then
				arg_39_0.isMagicShopActivityOpen_ = true

				return
			end
		end
	end

	arg_39_0.isMagicShopActivityOpen_ = false
end

function var_0_0.isMagicShopActivityOpen(arg_40_0)
	return arg_40_0.isMagicShopActivityOpen_
end

function var_0_0.refreshRedMark(arg_41_0)
	local var_41_0 = 0

	arg_41_0.redMarkMap = {}

	local var_41_1 = xyd.db.activitiesIds:getAllActivitiesIds(arg_41_0.player.playerID)
	local var_41_2 = {}

	for iter_41_0, iter_41_1 in ipairs(arg_41_0.activities) do
		if iter_41_1.table_id and arg_41_0:isActivityShow(iter_41_1.table_id, iter_41_0) then
			local var_41_3 = {
				table_id = iter_41_1.table_id,
				is_open = iter_41_1.is_open
			}

			table.insert(var_41_2, var_41_3)
		end
	end

	for iter_41_2 = 1, #var_41_1 do
		for iter_41_3, iter_41_4 in ipairs(var_41_2) do
			if tonumber(var_41_1[iter_41_2]) == iter_41_4.table_id then
				table.remove(var_41_2, iter_41_3)

				break
			end
		end
	end

	for iter_41_5, iter_41_6 in ipairs(var_41_2) do
		if not arg_41_0.redMarkMap[iter_41_6.table_id] then
			local var_41_4 = {}

			var_41_4.state = 0
			var_41_4.flag = xyd.db.activitiesIds:getFlagById(arg_41_0.player.playerID, tostring(iter_41_6.table_id)) or 0
			arg_41_0.redMarkMap[iter_41_6.table_id] = var_41_4
		end

		if iter_41_6.is_open == 1 then
			arg_41_0.redMarkMap[iter_41_6.table_id].state = var_0_4.NEW_ACTIVITY_STATE
		else
			arg_41_0.redMarkMap[iter_41_6.table_id].state = 0
		end
	end

	for iter_41_7, iter_41_8 in ipairs(arg_41_0.activities) do
		if not arg_41_0.redMarkMap[iter_41_8.table_id] then
			local var_41_5 = {}

			var_41_5.state = 0
			var_41_5.flag = xyd.db.activitiesIds:getFlagById(arg_41_0.player.playerID, tostring(iter_41_8.table_id)) or 0
			arg_41_0.redMarkMap[iter_41_8.table_id] = var_41_5
		end

		if iter_41_8.is_open == 1 and arg_41_0:isActivityShow(iter_41_8.table_id, iter_41_7) then
			if os.date("%x", iter_41_8.start_time) == os.date("%x", xyd.ServerTime.get():getServerTime()) and arg_41_0.redMarkMap[iter_41_8.table_id].flag == 0 then
				arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.TODAY_OPEN_STATE
			end

			if iter_41_8.is_open ~= 1 or not iter_41_8.details or iter_41_8.table_id == xyd.Activities.PointExchange or iter_41_8.table_id == xyd.Activities.Multiskin then
				-- block empty
			elseif iter_41_8.table_id == xyd.Activities.GrowthFund and iter_41_8.details.is_buy == 1 then
				local var_41_6 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				for iter_41_9 = 1, #xyd.tables.activityFund.name_ do
					if var_41_6[iter_41_9] == "0" and xyd.tables.activityFund:level(iter_41_9) <= arg_41_0.player.lev then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.Charge then
				local var_41_7 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				for iter_41_10 = 1, #xyd.tables.activityCharge.name_ do
					if var_41_7[iter_41_10] == "0" and xyd.tables.activityCharge:recharge(iter_41_10) <= iter_41_8.details.charge_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.Consume then
				local var_41_8 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				for iter_41_11 = 1, #xyd.tables.activityConsume.name_ do
					if var_41_8[iter_41_11] == "0" and xyd.tables.activityConsume:consume(iter_41_11) <= iter_41_8.details.consume_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.ServerCharge then
				local var_41_9 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				if iter_41_8.details.is_charged == 1 then
					for iter_41_12 = 1, #xyd.tables.activityServerCharge.name_ do
						if var_41_9[iter_41_12] == "0" and xyd.tables.activityServerCharge:num(iter_41_12) <= iter_41_8.details.player_num and xyd.tables.activityServerCharge:vip(iter_41_12) <= arg_41_0.player.vip then
							arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

							break
						end
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.SevendayGoal then
				if xyd.ServerTime.get():getServerTime() > iter_41_8.details.end_time and iter_41_8.details.can_award == 1 and iter_41_8.details.is_awarded == 0 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.StoneFeedback then
				local var_41_10 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				for iter_41_13 = 1, #var_41_10 do
					local var_41_11 = xyd.tables.activityStone:dayMin(iter_41_13)
					local var_41_12 = xyd.tables.activityStone:dayMax(iter_41_13)
					local var_41_13 = xyd.tables.activityStone:recharge(iter_41_13)
					local var_41_14 = xyd.tables.activityStone:level(iter_41_13)

					if var_41_10[iter_41_13] == "0" and var_41_11 <= iter_41_8.details.day_count and var_41_12 >= iter_41_8.details.day_count and var_41_13 <= arg_41_0.player.charge and var_41_14 <= arg_41_0.player.lev then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.SpringDial then
				if iter_41_8.details.times > 0 then
					arg_41_0.isRedMark = true

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
						params = {
							index = 3,
							show = true
						}
					})

					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.VipWeekGift then
				if arg_41_0.vipFlag == true then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

					xyd.db.vipWeekRedMark:addVipWeekRedMarkRecord(1, arg_41_0.player.playerID, arg_41_0.player.region)
				end
			elseif iter_41_8.table_id == xyd.Activities.SakuraCharge then
				local var_41_15 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				for iter_41_14 = 1, #xyd.tables.activitySakuraCharge.name_ do
					if var_41_15[iter_41_14] == "0" and xyd.tables.activitySakuraCharge:recharge(iter_41_14) <= iter_41_8.details.charge_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.PetBagBigSell then
				for iter_41_15 = 1, #iter_41_8.details.can_award do
					if iter_41_8.details.can_award[iter_41_15] == 1 and iter_41_8.details.is_awards[iter_41_15] == 0 then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.PetAndGirls then
				local var_41_16 = xyd.luaStringSplit(iter_41_8.details.can_award, "|")
				local var_41_17 = xyd.luaStringSplit(iter_41_8.details.is_awarded, "|")

				for iter_41_16 = 1, #var_41_16 do
					if tonumber(var_41_16[iter_41_16]) == 1 and tonumber(var_41_17[iter_41_16]) == 0 then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.SINGLE_DOG then
				local var_41_18 = xyd.ServerTime.get():getServerTime()

				if var_41_18 < iter_41_8.end_time and iter_41_8.details.is_reward == 0 and var_41_18 >= xyd.tables.misc.singleDogGiftTime then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.GROW_UP then
				local var_41_19 = xyd.tables.activityNewLevUp:getIDs()

				for iter_41_17 = 1, #var_41_19 do
					local var_41_20 = var_41_19[iter_41_17]
					local var_41_21 = xyd.splitToNumber(iter_41_8.details.is_awards, "|")

					if not var_41_21 then
						break
					end

					local var_41_22 = xyd.tables.activityNewLevUp:level(var_41_20)

					if var_41_21[var_41_20] == 0 and var_41_22 <= arg_41_0.player.lev then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.NEW_DAY_CHARGE then
				local var_41_23 = xyd.tables.activityNewDayCharge:getIDs()

				for iter_41_18 = 1, #var_41_23 do
					local var_41_24 = var_41_23[iter_41_18]
					local var_41_25 = xyd.splitToNumber(iter_41_8.details.is_awards, "|")

					if not var_41_25 then
						break
					end

					local var_41_26 = xyd.tables.activityNewDayCharge:charge(var_41_24)

					if var_41_25[var_41_24] == 0 and var_41_26 <= iter_41_8.details.charge_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.ACCUMULATE_CHARGE then
				local var_41_27 = xyd.tables.activityNewCharge:gifts()

				for iter_41_19 = 1, #var_41_27 do
					local var_41_28 = iter_41_19
					local var_41_29 = xyd.splitToNumber(iter_41_8.details.is_awards, "|")

					if not var_41_29 then
						break
					end

					local var_41_30 = xyd.tables.activityNewCharge:recharge(var_41_28)

					if var_41_29[var_41_28] == 0 and var_41_30 <= iter_41_8.details.charge_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.NEW_CONSUME then
				local var_41_31 = xyd.tables.activityNewConsume:gifts()

				for iter_41_20 = 1, #var_41_31 do
					local var_41_32 = iter_41_20
					local var_41_33 = xyd.splitToNumber(iter_41_8.details.is_awards, "|")

					if not var_41_33 then
						break
					end

					local var_41_34 = xyd.tables.activityNewConsume:consume(var_41_32)

					if var_41_33[var_41_32] == 0 and var_41_34 <= iter_41_8.details.consume_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.SmallMonthCard then
				local var_41_35 = iter_41_8.details

				if var_41_35.step == 2 and var_41_35.is_awarded == 0 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.LevelChargeGift then
				local var_41_36 = iter_41_8.details

				for iter_41_21, iter_41_22 in pairs(arg_41_0.oldActivities) do
					if iter_41_22.table_id == xyd.Activities.LevelChargeGift then
						local var_41_37 = iter_41_22.details

						for iter_41_23, iter_41_24 in pairs(var_41_36.award_infos) do
							if iter_41_24.open_time > 0 and var_41_37.award_infos[iter_41_23].open_time == 0 then
								arg_41_0.isLevelChargePointShow = true
							end
						end
					end
				end

				if arg_41_0.isLevelChargePointShow and arg_41_0.redMarkMap[iter_41_8.table_id].state == 0 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.NEW_ACTIVITY_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.GirlTraining then
				for iter_41_25 = 1, #iter_41_8.details.base_info.is_awards do
					if iter_41_8.details.base_info.is_awards[iter_41_25] == 0 and iter_41_8.details.mission_list[iter_41_25].is_complete == 1 and (arg_41_0.player:getHeroByTableID(xyd.tables.misc.activityGirlTrainingPartner) or arg_41_0.player:getHeroByTableID(xyd.tables.hero:afterAwaken(xyd.tables.misc.activityGirlTrainingPartner))) then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.NEW_DATE then
				if iter_41_8.details.is_login == 0 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.SkinWarmUp2 then
				for iter_41_26, iter_41_27 in pairs(iter_41_8.details.mission_list) do
					if iter_41_27.is_complete == 1 and iter_41_8.details.base_info.is_awards[iter_41_26] == 0 and xyd.tables.activitySkinWarmup2:type(iter_41_26) == 1 then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.PARTY and iter_41_8.details.mission_list then
				local var_41_38 = false

				for iter_41_28 = 1, #iter_41_8.details.mission_list do
					local var_41_39 = iter_41_8.details.mission_list[iter_41_28]

					if var_41_39.is_complete == 1 and var_41_39.is_award == 0 then
						var_41_38 = true

						break
					end
				end

				local var_41_40 = iter_41_8.details.base_info.stars
				local var_41_41 = iter_41_8.details.base_info.is_extra_awards
				local var_41_42 = xyd.tables.misc.activityPartyExtraNum

				for iter_41_29 = 1, #var_41_42 do
					if var_41_40 >= var_41_42[iter_41_29] and var_41_41[iter_41_29] == 0 then
						var_41_38 = true

						break
					end
				end

				if var_41_38 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.HeroSelling then
				local var_41_43 = xyd.tables.activityHeroSelling:recharge(iter_41_8.details.day_count)

				if iter_41_8.details.award_count < xyd.tables.misc.herosellBuyLimit and (var_41_43[iter_41_8.details.award_count + 1] or 0) <= iter_41_8.details.charge_count then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.MizhuTreasure then
				local var_41_44 = false

				for iter_41_30, iter_41_31 in pairs(iter_41_8.details.self_awarded) do
					if iter_41_31 == 0 and iter_41_8.details.charge_count >= xyd.tables.activityMizhuTreasure:recharge(tonumber(iter_41_30)) then
						var_41_44 = true

						break
					end
				end

				for iter_41_32, iter_41_33 in pairs(iter_41_8.details.whole_awarded) do
					if iter_41_33 == 0 and iter_41_8.details.whole_charge_count >= xyd.tables.activityMizhuTreasure:recharge(tonumber(iter_41_32)) then
						var_41_44 = true

						break
					end
				end

				if iter_41_8.details.charge_count == 0 then
					var_41_44 = false
				end

				if var_41_44 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.Goddess then
				local var_41_45 = false

				for iter_41_34, iter_41_35 in pairs(iter_41_8.details.daily_awarded) do
					if iter_41_35 == 0 and iter_41_8.details.daily_charge_count >= xyd.tables.activityGoddessStrategy:recharge(tonumber(iter_41_34)) then
						var_41_45 = true

						break
					end
				end

				for iter_41_36, iter_41_37 in pairs(iter_41_8.details.whole_awarded) do
					if iter_41_37 == 0 and iter_41_8.details.total_point >= xyd.tables.activityGoddessStrategy:recharge(tonumber(iter_41_36)) then
						var_41_45 = true

						break
					end
				end

				if var_41_45 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.Cultivate then
				local var_41_46 = false
				local var_41_47 = iter_41_8.details

				if var_41_47.hero and var_41_47.hero > 0 and var_41_47.day >= 1 and var_41_47.day <= 7 then
					for iter_41_38 = 1, var_41_47.day do
						local var_41_48 = xyd.tables.activityCultivate:getIdByDay(iter_41_38)
						local var_41_49 = xyd.tables.activityCultivate:type(var_41_48[1])

						if var_41_49 == 1 and (var_41_47.awards[var_41_48[1]] == 0 or var_41_47.awards[var_41_48[2]] and var_41_47.awards[var_41_48[2]] == 0) then
							var_41_46 = true

							break
						elseif var_41_49 == 2 then
							local var_41_50 = arg_41_0.details.consume6

							if iter_41_38 == 7 then
								var_41_50 = arg_41_0.details.consume7
							end

							if var_41_50 >= xyd.tables.activityCultivate:condition(var_41_48[1]) and var_41_47.awards[var_41_48[1]] == 0 or var_41_50 >= xyd.tables.activityCultivate:condition(var_41_48[2]) and var_41_47.awards[var_41_48[2]] == 0 then
								var_41_46 = true

								break
							end
						end
					end
				end

				if var_41_46 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.OnlineReward and iter_41_8.is_open == 1 then
				local var_41_51 = iter_41_8.details
				local var_41_52 = var_41_51.gift_times
				local var_41_53 = var_41_51.server_time - var_41_51.award_time
				local var_41_54 = xyd.tables.activityOnlineReward

				if var_41_52 < #var_41_54:all() then
					if var_41_53 < var_41_54:getOnlineTime(var_41_52 + 1) then
						arg_41_0.onlineInversalTime = (var_41_54:getOnlineTime(var_41_52 + 1) - var_41_53) * 30

						if not arg_41_0.onlineHandle then
							arg_41_0.onlineHandle = var_0_1.scheduleUpdateGlobal(handler(arg_41_0, arg_41_0.OnlineActivityLoop))
						end
					else
						if arg_41_0.onlineHandle then
							var_0_1.unscheduleGlobal(arg_41_0.onlineHandle)

							arg_41_0.onlineHandle = nil
						end

						print("online activity red mark line 173")

						arg_41_0.isRedMark = true

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
							params = {
								index = 3,
								show = true
							}
						})

						arg_41_0.redMarkMap[xyd.Activities.OnlineReward].state = arg_41_0.redMarkMap[xyd.Activities.OnlineReward].state + var_0_4.GET_AWARD_STATE
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.DongYun and iter_41_8.details then
				local var_41_55 = false

				for iter_41_39 = 1, #iter_41_8.details.is_awarded do
					local var_41_56 = iter_41_8.details.is_buy
					local var_41_57 = iter_41_8.details.day_count
					local var_41_58 = iter_41_8.details.is_awarded[iter_41_39]

					if var_41_56 == 1 and var_41_58 == 0 and iter_41_39 <= var_41_57 then
						var_41_55 = true

						break
					end
				end

				if var_41_55 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.CollegeConsume then
				if iter_41_8.details.base_info.free_times > 0 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.TwentyFourMission then
				local var_41_59 = iter_41_8.details.base_info.cur_mission
				local var_41_60 = iter_41_8.details.mission_list

				if var_41_59 and var_41_60 and next(var_41_60) and var_41_60[var_41_59].is_award == 0 and var_41_60[var_41_59].count >= xyd.tables.activityTwentyFourMission:num(var_41_59) then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.GirlTraining2 then
				local var_41_61 = tonumber(xyd.tables.misc:getValue("activity_girl_training2_partner"))

				for iter_41_40 = 1, #iter_41_8.details.base_info.is_awards do
					if iter_41_8.details.base_info.is_awards[iter_41_40] == 0 and iter_41_8.details.mission_list[iter_41_40].is_complete == 1 and (arg_41_0.player:getHeroByTableID(var_41_61) or arg_41_0.player:getHeroByTableID(xyd.tables.hero:afterAwaken(var_41_61))) then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.LukangCard then
				local var_41_62 = iter_41_8.details.progress
				local var_41_63 = xyd.tables.lukangExtraReward
				local var_41_64 = false

				for iter_41_41 = 1, 4 do
					if var_41_62 >= var_41_63:progress(iter_41_41) and iter_41_8.details.extra_awarded[iter_41_41] == 0 then
						var_41_64 = true

						break
					end
				end

				if var_41_62 == 0 or var_41_64 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.ConsumeNew then
				local var_41_65 = xyd.luaStringSplit(iter_41_8.details.is_awards, "|")

				for iter_41_42 = 1, #xyd.tables.activityConsume.name_ do
					if var_41_65[iter_41_42] == "0" and xyd.tables.activityConsume:consume(iter_41_42) <= iter_41_8.details.consume_count then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.MonthFundAward then
				local var_41_66 = xyd.ServerTime.get():getServerTime()
				local var_41_67 = math.floor((var_41_66 - iter_41_8.start_time) / 604800)

				if iter_41_8.details.is_buy == 1 and iter_41_8.details.is_award[var_41_67 + 1] == 0 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.SkinCharge and iter_41_8.is_open == 1 then
				if iter_41_8.details.is_awarded == 0 and iter_41_8.details.charge >= xyd.tables.activitySkinCharge:price(1) then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif iter_41_8.table_id == xyd.Activities.MizhuTreasureNew and iter_41_8.is_open == 1 then
				local var_41_68 = xyd.tables.mizhuTreasureNew

				for iter_41_43 = 1, #var_41_68:getIds() do
					if iter_41_8.details.is_award[iter_41_43] == 0 and iter_41_8.details.charge_count >= var_41_68:recharge(iter_41_43) then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.AliceBox and iter_41_8.is_open == 1 then
				local var_41_69 = xyd.tables.activityAliceBox

				for iter_41_44 = 1, 3 do
					if iter_41_8.details.base_info.is_awarded[iter_41_44] < var_41_69:limitTimes(iter_41_44) and iter_41_8.details.base_info.charge_count >= var_41_69:cost(iter_41_44) then
						arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE

						break
					end
				end
			elseif iter_41_8.table_id == xyd.Activities.ChenshouTravel and iter_41_8.is_open == 1 then
				local var_41_70 = xyd.tables.activityChenshouTravelBonus
				local var_41_71 = 0
				local var_41_72 = 0

				for iter_41_45 = 1, #iter_41_8.details.self_awarded do
					var_41_71 = var_41_71 + iter_41_8.details.self_awarded[iter_41_45]
					var_41_72 = var_41_72 + iter_41_8.details.self_achieved[iter_41_45]
				end

				local var_41_73 = 0

				for iter_41_46 = 1, #iter_41_8.details.whole_awarded do
					if iter_41_8.details.whole_awarded[iter_41_46] == 0 then
						var_41_73 = iter_41_46

						break
					end
				end

				if var_41_70:reqNum(var_41_73) <= iter_41_8.details.whole_charge_count or iter_41_8.details.is_buy == 1 and var_41_71 < var_41_72 then
					arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
				end
			elseif tonumber(iter_41_8.details.can_award) == 1 and tonumber(iter_41_8.details.is_awarded) == 0 then
				arg_41_0.redMarkMap[iter_41_8.table_id].state = arg_41_0.redMarkMap[iter_41_8.table_id].state + var_0_4.GET_AWARD_STATE
			end
		else
			arg_41_0.redMarkMap[iter_41_8.table_id].state = 0
		end

		if arg_41_0:activityVanishCheck(iter_41_8, iter_41_7) then
			arg_41_0.redMarkMap[iter_41_8.table_id].state = 0
		end

		if arg_41_0.redMarkMap[iter_41_8.table_id] and arg_41_0.redMarkMap[iter_41_8.table_id].state == 0 then
			var_41_0 = var_41_0 + 1
		elseif arg_41_0.player.lev and arg_41_0.player.lev < xyd.tables.activities:levelReq(iter_41_8.table_id) then
			var_41_0 = var_41_0 + 1
		end
	end

	if var_41_0 < #arg_41_0.activities then
		arg_41_0.isActivitiesRedMark = true
	else
		arg_41_0.isActivitiesRedMark = false
	end

	if arg_41_0.isBoardInfoValid and arg_41_0.noticeIDs then
		arg_41_0.isBoardInfoValid = false

		for iter_41_47, iter_41_48 in pairs(arg_41_0.boardInfo) do
			if arg_41_0.noticeIDs[iter_41_48.table_id] ~= nil then
				arg_41_0.noticeIDs[iter_41_48.table_id] = 1
			end
		end

		xyd.db.boardRedMark:updateMarkedNoticeIDs(arg_41_0.player.playerID, arg_41_0.noticeIDs)
	end

	arg_41_0.noticeIDs = xyd.db.boardRedMark:getAllNoticeIDs(arg_41_0.player.playerID)

	if xyd.count(arg_41_0.noticeIDs) < #arg_41_0.boardInfo then
		arg_41_0.isBoardRedMark = true
	else
		arg_41_0.isBoardRedMark = false
	end

	arg_41_0.isRedMark = arg_41_0.isActivitiesRedMark or arg_41_0.isBoardRedMark

	arg_41_0.player:setActivity(arg_41_0.isRedMark)
end

function var_0_0.refreshWalfareRedMark(arg_42_0)
	arg_42_0.walfareRedMark = false
	arg_42_0.walfareRedMarkMap = arg_42_0.walfareRedMarkMap or {}

	for iter_42_0 = 1, #arg_42_0.activities do
		local var_42_0 = arg_42_0.activities[iter_42_0]

		arg_42_0:getWalfareActivityRedMark(var_42_0)
	end

	for iter_42_1, iter_42_2 in pairs(arg_42_0.walfareRedMarkMap) do
		if iter_42_2 then
			arg_42_0.walfareRedMark = true

			break
		end
	end

	if xyd.WindowManager.get():isWindowOpen("main_scene_top") then
		xyd.WindowManager.get():getWindow("main_scene_top"):refreshWalfareRedMark()
	end

	if xyd.WindowManager.get():isWindowOpen("walfare_activities") then
		xyd.WindowManager.get():getWindow("walfare_activities"):updateRedMark()
	end
end

function var_0_0.getWalfareActivityRedMark(arg_43_0, arg_43_1)
	if xyd.tables.activities:walfareShow(arg_43_1.table_id) ~= 1 then
		return
	end

	if arg_43_1.table_id == xyd.Activities.NewSevenDayLogin then
		local var_43_0 = arg_43_1.details.is_award
		local var_43_1 = arg_43_1.details.login_day

		for iter_43_0 = 1, #var_43_0 do
			if iter_43_0 <= var_43_1 and var_43_0[iter_43_0] == 0 then
				arg_43_0.walfareRedMarkMap[arg_43_1.table_id] = true

				return
			end
		end

		arg_43_0.walfareRedMarkMap[arg_43_1.table_id] = false

		return
	elseif arg_43_1.table_id == xyd.Activities.MysteryGift then
		local var_43_2 = xyd.ServerTime.get():getServerTime()
		local var_43_3 = arg_43_1.details.create_time + xyd.tables.misc:getValue("tomorrow_countdown")

		if arg_43_1.details.create_time < arg_43_1.start_time or arg_43_1.details.is_award == 1 then
			arg_43_0.walfareRedMarkMap[arg_43_1.table_id] = false

			return
		elseif var_43_3 <= var_43_2 then
			arg_43_0.walfareRedMarkMap[arg_43_1.table_id] = true
		elseif arg_43_0.walfareRedMarkMap[arg_43_1.table_id] == nil then
			arg_43_0.walfareRedMarkMap[arg_43_1.table_id] = true
		end

		return
	else
		arg_43_0.walfareRedMarkMap[arg_43_1.table_id] = false

		return
	end
end

function var_0_0.clearRedMarkState(arg_44_0, arg_44_1, arg_44_2)
	arg_44_0.currentClickActivity = arg_44_1

	if arg_44_0.redMarkMap[arg_44_1].state == 0 then
		return
	end

	if arg_44_2 == 1 and arg_44_0.redMarkMap[arg_44_1].state > 1 then
		if arg_44_0.redMarkMap[arg_44_1].state >= 2 and arg_44_0.redMarkMap[arg_44_1].state <= 3 or arg_44_0.redMarkMap[arg_44_1].state >= 6 and arg_44_0.redMarkMap[arg_44_1].state <= 7 then
			xyd.db.activitiesIds:setActivitiesIds(arg_44_0.player.playerID, tostring(arg_44_1))

			arg_44_0.redMarkMap[arg_44_1].state = arg_44_0.redMarkMap[arg_44_1].state - var_0_4.NEW_ACTIVITY_STATE
			arg_44_0.isLevelChargePointShow = false
		end

		if arg_44_0.redMarkMap[arg_44_1].state >= 4 and arg_44_0.redMarkMap[arg_44_1].state <= 7 then
			arg_44_0.redMarkMap[arg_44_1].flag = 1

			xyd.db.activitiesIds:setFlagById(1, arg_44_0.player.playerID, tostring(arg_44_1))

			arg_44_0.redMarkMap[arg_44_1].state = arg_44_0.redMarkMap[arg_44_1].state - var_0_4.TODAY_OPEN_STATE
		end

		arg_44_0:loadSingleActivity({
			activity_id = arg_44_1
		})
	end

	if arg_44_2 == 2 and arg_44_0.redMarkMap[arg_44_1].state % 2 == 1 and arg_44_0.redMarkMap[arg_44_1].state < 8 then
		arg_44_0.redMarkMap[arg_44_1].state = arg_44_0.redMarkMap[arg_44_1].state - var_0_4.GET_AWARD_STATE

		arg_44_0:loadSingleActivity({
			activity_id = arg_44_1
		})
	end

	if arg_44_1 == xyd.Activities.VipWeekGift and arg_44_2 == 1 and (arg_44_0.redMarkMap[arg_44_1].state == 1 or arg_44_0.redMarkMap[arg_44_1].state == 3 or arg_44_0.redMarkMap[arg_44_1].state == 5 or arg_44_0.redMarkMap[arg_44_1].state == 7) then
		arg_44_0.redMarkMap[arg_44_1].state = arg_44_0.redMarkMap[arg_44_1].state - var_0_4.GET_AWARD_STATE
		arg_44_0.vipFlag = false

		xyd.db.vipWeekRedMark:setFlagByPlayer(0, arg_44_0.player.playerID, arg_44_0.player.region)
		arg_44_0:loadSingleActivity({
			activity_id = arg_44_1
		})
	end

	local var_44_0 = xyd.WindowManager.get():getWindow("activities")

	if var_44_0 ~= nil then
		var_44_0:refreshRedMark()
	end
end

function var_0_0.activityVanishCheck(arg_45_0, arg_45_1, arg_45_2)
	if not arg_45_0:isActivityShow(arg_45_1.table_id, arg_45_2) then
		return true
	end

	if arg_45_1.days == -1 then
		if arg_45_1.details and arg_45_1.details.is_awarded and arg_45_1.details.is_awarded == 1 then
			return true
		end

		if arg_45_1.details and arg_45_1.details.is_awards then
			local var_45_0 = 0

			for iter_45_0, iter_45_1 in ipairs(xyd.luaStringSplit(arg_45_1.details.is_awards, "|")) do
				if iter_45_1 == "0" then
					var_45_0 = 1

					break
				end
			end

			if var_45_0 == 0 then
				return true
			end
		end
	else
		local var_45_1 = arg_45_1.end_time

		if xyd.ServerTime.get():getServerTime() - var_45_1 >= 0 then
			return true
		end
	end

	return false
end

function var_0_0.getRedMarkMap(arg_46_0, arg_46_1)
	return arg_46_0.redMarkMap[arg_46_1]
end

function var_0_0.getActivitiesList(arg_47_0)
	return arg_47_0.activities
end

function var_0_0.setActivityCount(arg_48_0, arg_48_1)
	arg_48_0.count = arg_48_1
end

function var_0_0.getActivityCount(arg_49_0)
	return arg_49_0.count
end

function var_0_0.getActivityInfo(arg_50_0, arg_50_1)
	if not arg_50_0.activities or not next(arg_50_0.activities) then
		return nil
	end

	for iter_50_0, iter_50_1 in ipairs(arg_50_0.activities) do
		if iter_50_1.table_id == arg_50_1 then
			return iter_50_1
		end
	end

	return nil
end

function var_0_0.isBeachShow(arg_51_0)
	if not arg_51_0.activities or not next(arg_51_0.activities) then
		return false
	end

	for iter_51_0, iter_51_1 in ipairs(arg_51_0.activities) do
		if iter_51_1.table_id == xyd.Activities.BEACH and iter_51_1.is_open == 1 then
			xyd.ModelManager.get():loadModel(xyd.ModelType.BEACH_ACTIVITY):setParams(iter_51_1.details)

			return true
		end
	end

	return false
end

function var_0_0.isFirstChargeShow(arg_52_0)
	if not arg_52_0.activities or not next(arg_52_0.activities) then
		return false
	end

	for iter_52_0, iter_52_1 in ipairs(arg_52_0.activities) do
		if iter_52_1.table_id == xyd.Activities.FirstRechargeNew and iter_52_1.is_open == 1 and iter_52_1.details and iter_52_1.details.is_awarded == 0 then
			return xyd.Activities.FirstRechargeNew
		end

		if iter_52_1.table_id == xyd.Activities.FirstStoreAward and iter_52_1.is_open == 1 and iter_52_1.details and iter_52_1.details.is_awarded == 0 then
			return xyd.Activities.FirstStoreAward
		end

		if iter_52_1.table_id == xyd.Activities.FirstRecharge and iter_52_1.is_open == 1 and iter_52_1.details and iter_52_1.details.is_awarded == 0 then
			return xyd.Activities.FirstRecharge
		end
	end

	return false
end

function var_0_0.isRecallShow(arg_53_0)
	if not arg_53_0.activities or not next(arg_53_0.activities) then
		return false
	end

	for iter_53_0, iter_53_1 in ipairs(arg_53_0.activities) do
		if iter_53_1.table_id == xyd.Activities.Recall and iter_53_1.is_open == 1 and iter_53_1.details then
			if iter_53_1.details.base_info.recall_time <= 0 and arg_53_0.player.lev < xyd.tables.misc.activityRecallShowLevel then
				return false
			else
				return true
			end
		end
	end

	return false
end

function var_0_0.hasFirstChargePoint(arg_54_0)
	if not arg_54_0.activities or not next(arg_54_0.activities) then
		return false
	end

	for iter_54_0, iter_54_1 in ipairs(arg_54_0.activities) do
		if iter_54_1.table_id == xyd.Activities.FirstRechargeNew and iter_54_1.is_open == 1 and iter_54_1.details and iter_54_1.details.is_awarded == 0 and iter_54_1.details.can_award == 1 then
			return true
		end

		if iter_54_1.table_id == xyd.Activities.FirstStoreAward and iter_54_1.is_open == 1 and iter_54_1.details and iter_54_1.details.is_awarded == 0 and iter_54_1.details.charge >= var_0_2 then
			return true
		end

		if iter_54_1.table_id == xyd.Activities.FirstRecharge and iter_54_1.is_open == 1 and iter_54_1.details and iter_54_1.details.is_awarded == 0 and iter_54_1.details.can_award == 1 then
			return true
		end
	end

	return false
end

function var_0_0.isNewSkinSellShow(arg_55_0)
	return arg_55_0:isActivityOpen(xyd.Activities.NewSkinSell)
end

function var_0_0.isScratchCardShow(arg_56_0)
	return arg_56_0:isActivityOpen(xyd.Activities.ScratchCard)
end

function var_0_0.isZhugeActivityShow(arg_57_0)
	if arg_57_0:isActivityOpen(xyd.Activities.ZhugeFestival) then
		if arg_57_0:getActivityInfo(xyd.Activities.ZhugeFestival).details.base_info.is_passed == 1 then
			return 2
		else
			return 1
		end
	end

	return 0
end

function var_0_0.isNewOpenServiceShow(arg_58_0)
	local var_58_0 = arg_58_0:getActivityInfo(xyd.Activities.NewOpenService).details.day_count

	if var_58_0 > 8 or var_58_0 < 1 then
		return false
	end

	return arg_58_0:isActivityOpen(xyd.Activities.NewOpenService)
end

function var_0_0.isOpenDoubleTreasureAward(arg_59_0)
	local var_59_0 = false
	local var_59_1 = xyd.ServerTime.get():getServerTime()

	if arg_59_0:isActivityOpen(xyd.Activities.DoubleTreasureAward) then
		for iter_59_0, iter_59_1 in ipairs(arg_59_0.activities) do
			if iter_59_1.table_id == xyd.Activities.DoubleTreasureAward then
				if var_59_1 >= iter_59_1.start_time and var_59_1 <= iter_59_1.end_time then
					var_59_0 = true
				end

				break
			end
		end
	end

	return var_59_0
end

function var_0_0.isActivityOpen(arg_60_0, arg_60_1)
	if not arg_60_0.activities or not next(arg_60_0.activities) then
		return false
	end

	if arg_60_0.player.lev and arg_60_0.player.lev < xyd.tables.activities:levelReq(arg_60_1) then
		return false
	end

	for iter_60_0, iter_60_1 in ipairs(arg_60_0.activities) do
		if iter_60_1.table_id == arg_60_1 and iter_60_1.is_open == 1 then
			return true
		end
	end

	return false
end

function var_0_0.isIllusionBetOpen(arg_61_0)
	if not arg_61_0.activities or not next(arg_61_0.activities) then
		return false
	end

	if arg_61_0.player.lev and arg_61_0.player.lev < xyd.tables.activities:levelReq(activity_id) then
		return false
	end

	for iter_61_0, iter_61_1 in ipairs(arg_61_0.activities) do
		if iter_61_1.table_id == xyd.Activities.IllusionBet and iter_61_1.is_open == 1 and xyd.ServerTime.get():getServerTime() >= iter_61_1.start_time and xyd.ServerTime.get():getServerTime() < iter_61_1.end_time then
			return true
		end
	end

	return false
end

function var_0_0.getActivityTimeInterVal(arg_62_0, arg_62_1)
	for iter_62_0, iter_62_1 in ipairs(arg_62_0.activities) do
		if iter_62_1.table_id == arg_62_1 then
			return iter_62_1.start_time, iter_62_1.end_time
		end
	end
end

function var_0_0.isHalfPriceOpen(arg_63_0)
	return arg_63_0.isSkillHalfOpen
end

function var_0_0.isHasNewRedpoint(arg_64_0, arg_64_1)
	if arg_64_0.redMarkMap[arg_64_1].state >= 2 and arg_64_0.redMarkMap[arg_64_1].state <= 3 or arg_64_0.redMarkMap[arg_64_1].state >= 6 and arg_64_0.redMarkMap[arg_64_1].state <= 7 then
		return true
	end

	return false
end

function var_0_0.isActivityShow(arg_65_0, arg_65_1, arg_65_2)
	local function var_65_0()
		if arg_65_0.player.lev and arg_65_0.player.lev < xyd.tables.activities:levelReq(activity_id) then
			return false
		end

		return xyd.tables.activities:isShow(arg_65_1) == 1
	end

	local var_65_1 = xyd.WindowManager.get():getWindow("activities")

	if var_65_1 then
		local var_65_2 = var_65_1.openedActivities[arg_65_1]

		if var_65_2 then
			return var_65_2:isShow()
		else
			return var_65_0()
		end
	else
		return var_65_0()
	end
end

function var_0_0.checkVipWeekRedMardInDB(arg_67_0)
	local var_67_0 = false

	for iter_67_0, iter_67_1 in ipairs(arg_67_0.activities) do
		if iter_67_1.table_id == xyd.Activities.VipWeekGift and iter_67_1.is_open == 1 then
			var_67_0 = true

			break
		end
	end

	if var_67_0 and xyd.db.vipWeekRedMark:getVipWeekRedMarkByPlayer(arg_67_0.player.playerID, arg_67_0.player.region) == 1 then
		arg_67_0.vipFlag = true

		arg_67_0:refreshRedMark()
	end
end

function var_0_0.activityBroadcast_(arg_68_0, arg_68_1)
	local var_68_0 = xyd.tables.translation
	local var_68_1 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_68_1 then
		local var_68_2 = {
			time = 7
		}
		local var_68_3 = arg_68_1.params.msg
		local var_68_4 = var_0_3:getIDByActivityID(var_68_3.activity_id)
		local var_68_5

		if not var_68_3.activity_id then
			var_68_5 = 1
		elseif type(var_68_4) ~= "table" then
			var_68_5 = var_0_3:haveCD(var_68_4)
		else
			var_68_5 = var_0_3:haveCD(var_68_4[1])
		end

		if var_68_3.activity_id == xyd.Activities.FIREWORK then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, xyd.tables.activityFireworkType:name(var_68_3.fire_type))
		elseif var_68_3.activity_id == xyd.Activities.GaCha then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, xyd.tables.item:name(var_68_3.id))
		elseif var_68_3.activity_id == xyd.Activities.SqTurntable then
			if xyd.tables.item:heroID(var_68_3.id) ~= 0 then
				var_68_3.id = xyd.tables.item:heroID(var_68_3.id)
			end

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, xyd.tables.hero:name(var_68_3.id))
		elseif var_68_3.activity_id == xyd.Activities.LvbuFestival then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, xyd.tables.item:name(var_68_3.id))
		elseif var_68_3.activity_id == xyd.Activities.Summer then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, var_68_3.region)
		elseif var_68_3.activity_id == xyd.Activities.PopularityContest then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, var_68_3.region, xyd.tables.hero:name(var_68_3.table_id))
		elseif var_68_3.activity_id == xyd.Activities.NewTerms then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.from_player_name, xyd.getPlayerRegion(var_68_3.from_player_id), var_68_3.to_player_name, xyd.getPlayerRegion(var_68_3.to_player_id), var_68_3.item_num, xyd.tables.item:name(var_68_3.item_id))
		elseif var_68_3.activity_id == xyd.Activities.Valentine then
			local var_68_6 = var_68_3.gift_index
			local var_68_7 = var_68_4[tonumber(var_68_6)]

			var_68_2.msg = string.format(var_0_3:content(var_68_7), var_68_3.from_region, var_68_3.from_name, var_68_3.to_region, var_68_3.to_name)
		elseif var_68_3.activity_id == xyd.Activities.WarCamp then
			local var_68_8 = ""

			if var_68_3.group_id == xyd.WarCampSelectType.LEFT then
				var_68_8 = var_68_0:translation("WAR_CAMP_LEFT_NAME")
			else
				var_68_8 = var_68_0:translation("WAR_CAMP_RIGHT_NAME")
			end

			local var_68_9 = xyd.tables.warCamp:name(var_68_3.map_id)

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_8, var_68_3.player_name, var_68_9)
		elseif var_68_3.activity_id == xyd.Activities.StickBless then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.region, var_68_3.player_name)
		elseif var_68_3.activity_id == xyd.Activities.SAKURA_WISHES then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.region, var_68_3.player_name, xyd.tables.item:name(var_68_3.item_id))
		elseif var_68_3.activity_id == xyd.Activities.BlackFriday then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.player_name, xyd.tables.item:name(var_68_3.id))
		elseif var_68_3.activity_id == xyd.Activities.Valentine2 then
			local var_68_10 = var_68_3.gift_index
			local var_68_11 = var_68_4

			var_68_2.msg = string.format(var_0_3:content(var_68_11), var_68_3.from_region, var_68_3.from_name, var_68_3.to_region, var_68_3.to_name)
		elseif var_68_3.activity_id == xyd.Activities.CollegeConsume then
			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.region_id, var_68_3.player_name, xyd.tables.item:name(var_68_3.special_item))
		elseif var_68_3.msg_type == xyd.SystemBroadcast.DORM_EXPAND then
			var_68_2.msg = string.format(xyd.tables.announce:content(var_68_3.msg_type), var_68_3.region_id, var_68_3.player_name)
		elseif var_68_3.activity_id == xyd.Activities.CHOCOLATE then
			local var_68_12 = xyd.tables.activityChocolateSlot:content(var_68_3.table_id)[1] + 16
			local var_68_13 = xyd.tables.translation:translation("ACTIVITY_CHOCOLATE_SLOT_TIP" .. var_68_12)
			local var_68_14 = xyd.tables.activityChocolateSlot:giftId(var_68_3.table_id)
			local var_68_15 = xyd.tables.gift:items(var_68_14)

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_3.region, var_68_3.player_name, var_68_13, xyd.tables.item:name(var_68_15[1]))
		elseif var_68_3.activity_id == xyd.Activities.LOVELETTER then
			local var_68_16 = tonumber(var_68_3.region)
			local var_68_17 = var_68_3.player_name
			local var_68_18 = xyd.tables.item:name(tonumber(var_68_3.item_id))

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_16, var_68_17, var_68_18)
		elseif var_68_3.activity_id == xyd.Activities.SPShop then
			local var_68_19 = tonumber(var_68_3.region)
			local var_68_20 = var_68_3.player_name
			local var_68_21 = xyd.tables.item:name(tonumber(var_68_3.table_id))

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_19, var_68_20, var_68_21)
		elseif var_68_3.activity_id == xyd.Activities.FourthAnniversary then
			local var_68_22 = tonumber(var_68_3.region)
			local var_68_23 = var_68_3.player_name
			local var_68_24 = var_68_3.table_id
			local var_68_25

			if var_68_24 == 1 and var_68_3.sub_id then
				var_68_25 = xyd.tables.misc:getValue("activity_ufocatcher_jackpot_reward")[var_68_3.sub_id]
			else
				var_68_25 = xyd.tables.fourthAnniUfocatcherTable:gift(var_68_24)
			end

			local var_68_26 = xyd.tables.gift:items(var_68_25)
			local var_68_27 = xyd.tables.gift:itemNum(var_68_25)
			local var_68_28 = ""

			for iter_68_0 = 1, #var_68_26 do
				if iter_68_0 < #var_68_26 then
					var_68_28 = var_68_28 .. xyd.tables.item:name(var_68_26[iter_68_0]) .. "*" .. var_68_27[iter_68_0] .. "、"
				else
					var_68_28 = var_68_28 .. xyd.tables.item:name(var_68_26[iter_68_0]) .. "*" .. var_68_27[iter_68_0]
				end
			end

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_22, var_68_23, var_68_28)
		elseif var_68_3.activity_id == xyd.Activities.LUCKY_BAG then
			local var_68_29 = tonumber(var_68_3.region)
			local var_68_30 = var_68_3.player_name
			local var_68_31 = xyd.tables.misc:getValue("activity_anniversary_luckbag_item_id")
			local var_68_32 = xyd.tables.item:name(tonumber(var_68_31))

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_29, var_68_30, var_68_32)
		elseif var_68_3.activity_id == xyd.Activities.SakuraSell then
			local var_68_33 = tonumber(var_68_3.region_id)
			local var_68_34 = var_68_3.player_name
			local var_68_35 = xyd.tables.activitySakuraSell
			local var_68_36 = var_68_35:allcount()
			local var_68_37 = 0

			for iter_68_1 = 1, #var_68_36 do
				if var_68_3.id == var_68_36[iter_68_1] then
					var_68_37 = iter_68_1
				end
			end

			local var_68_38 = var_68_35:name(tonumber(var_68_37))

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_33, var_68_34, var_68_38)
		elseif var_68_3.activity_id == xyd.Activities.Contract then
			local var_68_39 = tonumber(var_68_3.region)
			local var_68_40 = var_68_3.player_name
			local var_68_41 = xyd.tables.item:name(xyd.tables.activityContract:itemID(tonumber(var_68_3.table_id)))

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_39, var_68_40, var_68_41)
		elseif var_68_3.activity_id == xyd.Activities.FISH then
			local var_68_42 = tonumber(var_68_3.stage)
			local var_68_43 = xyd.tables.activityFishGamblingSchedule:name(var_68_42)

			var_68_2.msg = string.format(var_0_3:content(var_68_4), var_68_43)

			local var_68_44 = xyd.WindowManager.get():getWindow("fish_gambling_main")

			if var_68_44 then
				var_68_44:activityBroadcast_(arg_68_1)
			end
		end

		var_68_2.cd = var_68_5

		var_68_1:showBroadcast(var_68_2)
	end
end

function var_0_0.lvbuBroadcast_(arg_69_0, arg_69_1)
	local var_69_0 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_69_0 then
		local var_69_1 = {
			msg = string.format(xyd.tables.translation:translation("ANNIVERSARY_LVBU_ANNOUNCE"), arg_69_1.params.msg.player_name, xyd.tables.item:name(arg_69_1.params.msg.id))
		}

		var_69_1.time = 7

		var_69_0:showBroadcast(var_69_1)
	end
end

return var_0_0
