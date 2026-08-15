local var_0_0 = class("NewOpenServiceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.newOpenService
local var_0_4 = xyd.tables.newOpenServiceGift
local var_0_5 = xyd.tables.gift
local var_0_6 = 1
local var_0_7 = 2
local var_0_8 = 3
local var_0_9 = 12
local var_0_10 = 13
local var_0_11 = 120

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.missionList = arg_1_2.details.mission_list
	arg_1_0.baseInfo = arg_1_2.details.base_info
	arg_1_0.day = arg_1_2.details.day_count

	if arg_1_0.day > 7 then
		arg_1_0.day = 7
	end

	arg_1_0.leftTime = 604800 - (arg_1_2.details.now_time - arg_1_2.details.start_time)

	if xyd.ServerTime.get():getSecondsOfDay() > 18000 then
		arg_1_0.rewardTime = (8 - arg_1_2.details.day_count) * 86400 - xyd.ServerTime.get():getSecondsOfDay() + 18000 + 86400
	else
		arg_1_0.rewardTime = (8 - arg_1_2.details.day_count) * 86400 - xyd.ServerTime.get():getSecondsOfDay() + 18000
	end

	arg_1_0:listPrepare()

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
	arg_1_0.idx = 5
end

function var_0_0.sortMissions(arg_2_0)
	table.sort(arg_2_0.missionList, function(arg_3_0, arg_3_1)
		return math.floor(arg_3_0.mission_id / 1000) < math.floor(arg_3_1.mission_id / 1000) or math.floor(arg_3_0.mission_id / 1000) == math.floor(arg_3_1.mission_id / 1000) and (arg_3_0.state < arg_3_1.state or arg_3_0.state == arg_3_1.state and arg_3_0.mission_id < arg_3_1.mission_id)
	end)
end

function var_0_0.listPrepare(arg_4_0)
	for iter_4_0, iter_4_1 in pairs(arg_4_0.missionList) do
		local var_4_0 = var_0_3:_type(iter_4_1.mission_id)

		if var_4_0 == var_0_9 or var_4_0 == var_0_10 then
			iter_4_1.req = 1

			if iter_4_1.count >= var_0_3:req(iter_4_1.mission_id) then
				iter_4_1.count = 1
				iter_4_1.state = var_0_6
			else
				iter_4_1.count = 0
				iter_4_1.state = var_0_7
			end
		else
			iter_4_1.req = var_0_3:req(iter_4_1.mission_id)

			if iter_4_1.count >= iter_4_1.req then
				iter_4_1.state = var_0_6
			else
				iter_4_1.state = var_0_7
			end
		end

		if iter_4_1.is_award ~= 0 then
			iter_4_1.state = var_0_8
		end
	end

	arg_4_0:sortMissions()
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	arg_5_0:nodeByName("txt1"):setString(var_0_1:translation("ACTIVITY_OVER_TIME"))
	arg_5_0:nodeByName("txt2"):setString(var_0_1:translation("REWARD_OVER_TIME"))

	arg_5_0.label_index = arg_5_0.day

	arg_5_0:nodeByName("bar"):setPercent(arg_5_0.baseInfo.finish_count / var_0_4:req(5) * 100)

	arg_5_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("scroll"):getWidth(), arg_5_0:nodeByName("scroll"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("scroll")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.listView_:setBounceable(true)
	arg_5_0.listView_:setDelegate(handler(arg_5_0, arg_5_0.delegate))

	for iter_5_0 = 1, 8 do
		arg_5_0:nodeByName("btn" .. iter_5_0):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.began then
				return true
			elseif arg_6_1 == ccui.TouchEventType.ended then
				arg_5_0:updateLeft(iter_5_0)

				return true
			end
		end)
	end

	for iter_5_1 = 1, 5 do
		local var_5_0 = arg_5_0:nodeByName("gift" .. iter_5_1)
		local var_5_1 = var_0_4:req(iter_5_1)

		var_5_0:getChildByName("bg_award"):getChildByName("num"):setString(var_5_1)

		local var_5_2 = var_5_0:getChildByName("icon1")
		local var_5_3 = var_5_0:getChildByName("icon2")
		local var_5_4 = var_5_0:getChildByName("light")

		if var_5_1 > arg_5_0.baseInfo.finish_count then
			var_5_2:setTouchEnabled(true)
			var_5_2:setVisible(true)
			var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
				if arg_7_0.name == "began" then
					local var_7_0 = var_0_5:items(var_0_4:gift(iter_5_1))
					local var_7_1 = var_0_5:itemNum(var_0_4:gift(iter_5_1))
					local var_7_2 = {}

					for iter_7_0 = 1, #var_7_0 do
						table.insert(var_7_2, {
							table_id = var_7_0[iter_7_0],
							item_num = var_7_1[iter_7_0]
						})
					end

					xyd.WindowManager.get():openWindow("gift_award", {
						awards = var_7_2
					})

					local var_7_3 = xyd.WindowManager.get():getWindow("gift_award")

					if var_7_3 then
						var_7_3:setPosition(var_5_0:getPositionX() - 180, var_5_0:getPositionY() + 20)
					end

					return true
				elseif (arg_7_0.name == "ended" or arg_7_0.name == "canceled") and xyd.WindowManager.get():getWindow("gift_award") then
					xyd.WindowManager.get():closeWindow("gift_award")
				end
			end)
		elseif arg_5_0.baseInfo.gift_awards[iter_5_1] == 0 then
			var_5_4:setVisible(true)
			var_5_4:runAction(cc.RepeatForever:create(cc.RotateBy:create(5, 360)))
			var_5_2:setTouchEnabled(true)
			var_5_2:setVisible(true)
			var_5_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
				if arg_8_0.name == "began" then
					var_5_2:setScale(0.9)

					return true
				elseif arg_8_0.name == "canceled" then
					var_5_2:setScale(1)
				elseif arg_8_0.name == "ended" then
					var_5_2:setScale(1)
					xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward2(xyd.Activities.NewOpenService, 2, iter_5_1, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							arg_5_0.selfPlayer:handleRewards(arg_9_1.awards)
							var_5_2:setVisible(false)
							var_5_4:setVisible(false)
							var_5_3:setVisible(true)

							arg_5_0.baseInfo.gift_awards[iter_5_1] = 1
						end
					end)
				end
			end)
		else
			var_5_3:setVisible(true)
		end

		var_5_0:setVisible(false)
	end

	arg_5_0:nodeByName("bar"):setVisible(false)
	arg_5_0:nodeByName("bg_bar"):setVisible(false)
	arg_5_0:updateLeft(arg_5_0.label_index)
	arg_5_0:updateRedPoints()

	if arg_5_0.leftTime and arg_5_0.leftTime > 0 then
		arg_5_0:nodeByName("time1"):setString(xyd.secondsToString1(arg_5_0.leftTime))
	else
		arg_5_0:nodeByName("time1"):setString(var_0_1:translation("ALREADY_OVER"))
	end

	if arg_5_0.rewardTime and arg_5_0.rewardTime > 0 then
		arg_5_0:nodeByName("time2"):setString(xyd.secondsToString1(arg_5_0.rewardTime))
	else
		arg_5_0:nodeByName("time2"):setString(var_0_1:translation("ALREADY_OVER"))
	end

	arg_5_0.handle_ = var_0_2.scheduleGlobal(function()
		arg_5_0.leftTime = arg_5_0.leftTime - 10
		arg_5_0.rewardTime = arg_5_0.rewardTime - 10

		if arg_5_0.leftTime and arg_5_0.leftTime > 0 then
			arg_5_0:nodeByName("time1"):setString(xyd.secondsToString1(arg_5_0.leftTime))
		else
			arg_5_0:nodeByName("time1"):setString(var_0_1:translation("ALREADY_OVER"))
		end

		if arg_5_0.rewardTime and arg_5_0.rewardTime > 0 then
			arg_5_0:nodeByName("time2"):setString(xyd.secondsToString1(arg_5_0.rewardTime))
		else
			arg_5_0:nodeByName("time2"):setString(var_0_1:translation("ALREADY_OVER"))
		end
	end, 10)
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	if cc.ui.UIListView.COUNT_TAG == arg_11_2 and arg_11_0.label_index <= 7 then
		return 5
	elseif cc.ui.UIListView.COUNT_TAG == arg_11_2 and arg_11_0.label_index > 7 then
		return 1
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		if arg_11_0.label_index > 7 then
			local var_11_0
			local var_11_1 = arg_11_0.listView_:dequeueItem()

			if not var_11_1 then
				var_11_1 = arg_11_0.listView_:newItem()
			else
				var_11_1:removeAllChildren(true)
			end

			local var_11_2 = arg_11_0:createListContent(arg_11_3)

			var_11_1:setItemSize(690, 130)
			var_11_1:addContent(var_11_2)

			return var_11_1
		else
			local var_11_3 = arg_11_0.listView_:dequeueItem()

			if not var_11_3 then
				var_11_3 = arg_11_0.listView_:newItem()
			else
				var_11_3:removeAllChildren(true)
			end

			local var_11_4 = arg_11_0.missionList[arg_11_0.label_index * 5 + arg_11_3 - 5]
			local var_11_5 = display.newNode()
			local var_11_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/open_service_window/item.csb")
			local var_11_7 = var_11_6:getChildByName("container")

			var_11_7:getChildByName("desc"):setString(var_0_3:desc(var_11_4.mission_id))

			if var_11_4.state == var_0_8 then
				var_11_7:getChildByName("bar_words"):setVisible(false)
				var_11_7:getChildByName("bar_text"):setVisible(false)
				var_11_7:getChildByName("btn"):setVisible(false)
				var_11_7:getChildByName("got"):setVisible(true)
			else
				var_11_7:getChildByName("bar_words"):setString(var_0_1:translation("RATE_OF_ADVANCE"))
				var_11_7:getChildByName("bar_text"):setString(var_11_4.count .. "/" .. var_11_4.req)

				local var_11_8 = var_11_7:getChildByName("btn")

				var_11_8:setTouchSwallowEnabled(false)

				if var_11_4.state == var_0_6 then
					var_11_8:getChildByName("get"):setVisible(true)
					var_11_8:addTouchEventListener(function(arg_12_0, arg_12_1)
						if arg_12_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
							xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward2(xyd.Activities.NewOpenService, 1, var_11_4.mission_id, function(arg_13_0, arg_13_1)
								if arg_13_0 == xyd.error.OK then
									arg_11_0.selfPlayer:handleRewards(arg_13_1.awards)

									var_11_4.state = var_0_8
									var_11_4.is_award = 1

									arg_11_0:sortMissions()

									if arg_11_0.missionList[arg_11_0.label_index * 5 - 4].state ~= var_0_6 then
										arg_11_0:nodeByName("btn" .. arg_11_0.label_index):getChildByName("red_point"):setVisible(false)
									end

									arg_11_0.baseInfo.finish_count = arg_11_0.baseInfo.finish_count + 1

									arg_11_0:nodeByName("bar"):setPercent(arg_11_0.baseInfo.finish_count / var_0_4:req(5) * 100)

									if math.floor(arg_11_0.baseInfo.finish_count / 7) == math.floor((arg_11_0.baseInfo.finish_count - 1) / 7 + 1) then
										arg_11_0:updateGift(arg_11_0.baseInfo.finish_count / 7)
									end

									arg_11_0:updateRedPoints()
									arg_11_0.listView_:reload()
								end
							end)
						end
					end)
				elseif var_11_4.mission_id == 1002 or var_11_4.mission_id == 2002 or var_11_4.mission_id == 3002 or var_11_4.mission_id == 4002 or var_11_4.mission_id == 5002 or var_11_4.mission_id == 6002 or var_11_4.mission_id == 7002 then
					var_11_8:getChildByName("go"):setVisible(true)
					var_11_8:getChildByName("go_gray"):setVisible(false)
					var_11_8:addTouchEventListener(function(arg_14_0, arg_14_1)
						if arg_14_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
							if var_11_4.mission_id == 6002 then
								arg_11_0.selfPlayer:loadSummonInfo(nil, function()
									xyd.WindowManager.get():openWindow("summon")
									xyd.WindowManager.get():closeWindow(arg_11_0)
								end, true)
							elseif var_11_4.mission_id == 2002 or var_11_4.mission_id == 4002 then
								xyd.WindowManager.get():openWindow("hero_list")
								xyd.WindowManager.get():closeWindow(arg_11_0)
							elseif var_11_4.mission_id == 7002 then
								local var_14_0 = xyd.FunctionID.ID_PET

								if arg_11_0.selfPlayer:isFuncOpen(var_14_0) == true then
									xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_16_0)
										if arg_16_0 == xyd.error.OK then
											xyd.WindowManager.get():openWindow("pet_campaign")
											xyd.WindowManager.get():closeWindow(arg_11_0)
										end
									end)
								else
									local var_14_1 = xyd.tables.functionOpen:level(var_14_0)
									local var_14_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_14_1)

									xyd.WindowManager.get():openWindow("toast", {
										message = var_14_2
									})
								end
							else
								arg_11_0:buytili()
							end
						end
					end)
				elseif var_11_4.mission_id == 1003 or var_11_4.mission_id == 2003 or var_11_4.mission_id == 3003 or var_11_4.mission_id == 4003 or var_11_4.mission_id == 5003 or var_11_4.mission_id == 6003 or var_11_4.mission_id == 7003 then
					var_11_8:getChildByName("go"):setVisible(true)
					var_11_8:getChildByName("go_gray"):setVisible(false)
					var_11_8:addTouchEventListener(function(arg_17_0, arg_17_1)
						if arg_17_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
							if var_11_4.mission_id == 5003 then
								xyd.WindowManager.get():openWindow("hero_list")
								xyd.WindowManager.get():closeWindow(arg_11_0)
							else
								arg_11_0.selfPlayer:loadSummonInfo(nil, function()
									xyd.WindowManager.get():openWindow("summon")
									xyd.WindowManager.get():closeWindow(arg_11_0)
								end, true)
							end
						end
					end)
				elseif var_11_4.mission_id == 1004 or var_11_4.mission_id == 2004 or var_11_4.mission_id == 3004 or var_11_4.mission_id == 4004 or var_11_4.mission_id == 5004 or var_11_4.mission_id == 6004 or var_11_4.mission_id == 7004 then
					if var_11_4.mission_id == 1004 or var_11_4.mission_id == 4004 or var_11_4.mission_id == 7004 then
						var_11_8:getChildByName("go"):setVisible(false)
						var_11_8:getChildByName("go_gray"):setVisible(false)
						var_11_8:getChildByName("get_gray"):setVisible(true)
						var_11_8:setBright(false)
					else
						var_11_8:getChildByName("go"):setVisible(true)
						var_11_8:getChildByName("go_gray"):setVisible(false)
						var_11_8:addTouchEventListener(function(arg_19_0, arg_19_1)
							if arg_19_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
								if var_11_4.mission_id == 2004 or var_11_4.mission_id == 6004 then
									xyd.WindowManager.get():openWindow("map_window")
									xyd.WindowManager.get():closeWindow(arg_11_0)
								elseif var_11_4.mission_id == 3004 then
									xyd.WindowManager.get():openWindow("hero_list")
									xyd.WindowManager.get():closeWindow(arg_11_0)
								elseif var_11_4.mission_id == 5004 then
									local var_19_0 = xyd.FunctionID.ID_PET

									if arg_11_0.selfPlayer:isFuncOpen(var_19_0) == true then
										xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN):getCampaignInfo(function(arg_20_0)
											if arg_20_0 == xyd.error.OK then
												xyd.WindowManager.get():openWindow("pet_campaign")
												xyd.WindowManager.get():closeWindow(arg_11_0)
											end
										end)
									else
										local var_19_1 = xyd.tables.functionOpen:level(var_19_0)
										local var_19_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_19_1)

										xyd.WindowManager.get():openWindow("toast", {
											message = var_19_2
										})
									end
								end
							end
						end)
					end
				elseif var_11_4.mission_id == 1005 or var_11_4.mission_id == 2005 or var_11_4.mission_id == 3005 or var_11_4.mission_id == 4005 or var_11_4.mission_id == 5005 or var_11_4.mission_id == 6005 or var_11_4.mission_id == 7005 then
					if var_11_4.mission_id == 4005 then
						var_11_8:getChildByName("go"):setVisible(false)
						var_11_8:getChildByName("go_gray"):setVisible(false)
						var_11_8:getChildByName("get_gray"):setVisible(true)
						var_11_8:setBright(false)
					else
						var_11_8:getChildByName("go"):setVisible(true)
						var_11_8:getChildByName("go_gray"):setVisible(false)
						var_11_8:addTouchEventListener(function(arg_21_0, arg_21_1)
							if arg_21_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
								if var_11_4.mission_id == 1005 then
									local var_21_0 = xyd.FunctionID.ID_ARENA

									if arg_11_0.selfPlayer:isFuncOpen(var_21_0) == true then
										xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_22_0, arg_22_1)
											if arg_22_0 == xyd.error.OK then
												xyd.WindowManager.get():openWindow("arena")
												xyd.WindowManager.get():closeWindow(arg_11_0)
											end
										end)
									else
										local var_21_1 = xyd.tables.functionOpen:level(var_21_0)
										local var_21_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_21_1)

										xyd.WindowManager.get():openWindow("toast", {
											message = var_21_2
										})
									end
								elseif var_11_4.mission_id == 2005 then
									local var_21_3 = xyd.FunctionID.ID_MARCH

									if arg_11_0.selfPlayer:isFuncOpen(var_21_3) == true then
										local var_21_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

										if var_21_4.mapInfo == nil then
											var_21_4:loadMarchInfo({}, function(arg_23_0)
												if arg_23_0 == xyd.error.OK then
													xyd.WindowManager.get():openWindow("march")
													xyd.WindowManager.get():closeWindow(arg_11_0)
												end
											end)
										else
											xyd.WindowManager.get():openWindow("march")
											xyd.WindowManager.get():closeWindow(arg_11_0)
										end
									else
										local var_21_5 = xyd.tables.functionOpen:level(var_21_3)
										local var_21_6 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_21_5)

										xyd.WindowManager.get():openWindow("toast", {
											message = var_21_6
										})
									end
								elseif var_11_4.mission_id == 3005 then
									local var_21_7 = xyd.FunctionID.ID_FUMO

									if arg_11_0.selfPlayer:isFuncOpen(var_21_7) == true then
										xyd.WindowManager.get():openWindow("fumo")
										xyd.WindowManager.get():closeWindow(arg_11_0)
									else
										local var_21_8 = xyd.tables.functionOpen:level(var_21_7)
										local var_21_9 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_21_8)

										xyd.WindowManager.get():openWindow("toast", {
											message = var_21_9
										})
									end
								else
									xyd.WindowManager.get():openWindow("hero_list")
									xyd.WindowManager.get():closeWindow(arg_11_0)
								end
							end
						end)
					end
				else
					var_11_8:getChildByName("get_gray"):setVisible(true)
					var_11_8:getChildByName("go_gray"):setVisible(false)
					var_11_8:setBright(false)
				end
			end

			local var_11_9 = var_11_7:getChildByName("btn")

			if arg_11_0.label_index > arg_11_0.day then
				if var_11_4.state == var_0_6 then
					var_11_9:getChildByName("go"):setVisible(false)
					var_11_9:getChildByName("get"):setVisible(false)
					var_11_9:getChildByName("get_gray"):setVisible(true)
					var_11_9:setBright(false)
					var_11_9:addTouchEventListener(function(arg_24_0, arg_24_1)
						if arg_24_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("OPENSERVER_NEW_NOT_OPEN")
							})
						end
					end)
				else
					var_11_9:getChildByName("go"):setVisible(false)

					if var_11_4.mission_id ~= 1001 and var_11_4.mission_id ~= 2001 and var_11_4.mission_id ~= 3001 and var_11_4.mission_id ~= 4001 and var_11_4.mission_id ~= 5001 and var_11_4.mission_id ~= 6001 and var_11_4.mission_id ~= 7001 and var_11_4.mission_id ~= 4005 and var_11_4.mission_id ~= 1004 and var_11_4.mission_id ~= 4004 and var_11_4.mission_id ~= 7004 then
						var_11_9:getChildByName("go_gray"):setVisible(true)
					end

					var_11_9:setBright(false)
					var_11_9:addTouchEventListener(function(arg_25_0, arg_25_1)
						if arg_25_1 == ccui.TouchEventType.ended and not arg_11_0.scrollViewMoved_ then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("OPENSERVER_NEW_NOT_OPEN")
							})
						end
					end)
				end
			end

			local var_11_10 = clone(var_0_5:items(var_0_3:gift(var_11_4.mission_id)))
			local var_11_11 = clone(var_0_5:itemNum(var_0_3:gift(var_11_4.mission_id)))
			local var_11_12 = var_0_5:crystal(var_0_3:gift(var_11_4.mission_id))
			local var_11_13 = var_0_5:mana(var_0_3:gift(var_11_4.mission_id))

			if var_11_10[1] == 0 then
				var_11_10 = {}
				var_11_11 = {}
			end

			if var_11_12 > 0 then
				table.insert(var_11_10, -1)
				table.insert(var_11_11, var_11_12)
			end

			if var_11_13 > 0 then
				table.insert(var_11_10, -2)
				table.insert(var_11_11, var_11_13)
			end

			for iter_11_0 = 1, #var_11_10 do
				local var_11_14 = display.newNode()

				var_11_14:setContentSize(70, 70)
				xyd.setItemAndAddTips(var_11_14, var_11_10[iter_11_0], var_11_11[iter_11_0])
				var_11_14:setAnchorPoint(cc.p(0.5, 0.5))
				var_11_14:addTo(var_11_7:getChildByName("item_pos"))
				var_11_14:setPosition(85 * iter_11_0 - 85, 0)
			end

			local var_11_15 = display.newNode()

			var_11_15:addChild(var_11_6)
			var_11_15:setContentSize(690, 130)
			var_11_3:setItemSize(690, 130)
			var_11_3:addContent(var_11_15)

			return var_11_3
		end
	end
end

function var_0_0.buytili(arg_26_0, ...)
	local var_26_0
	local var_26_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_26_0.buyEnergyTimes = var_26_1.buyEnergyTimes
	arg_26_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_26_0.buyEnergyTimes + 1)
	arg_26_0.maxBuyTimes = xyd.tables.vip:numEnergy(var_26_1.vip)

	local var_26_2 = xyd.tables.misc.energyMaxLimit

	str = string.format(var_0_1:translation("ADD_ENERGY"), arg_26_0.buyEnergyCost, var_0_11, arg_26_0.buyEnergyTimes)

	if arg_26_0:isHasTiLiItem() then
		local var_26_3 = {
			text = str,
			callback = function()
				if arg_26_0.buyEnergyTimes >= arg_26_0.maxBuyTimes then
					str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_26_0.buyEnergyTimes)
					var_26_0 = xyd.AlertType.CONFIRM

					local var_27_0 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_27_0, function()
						local var_28_0 = {}

						var_28_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_28_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_26_0.colorMode)
				elseif arg_26_0.selfPlayer.energy >= var_26_2 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("TILI_LIMIT_INFO")
					})
					xyd.WindowManager.get():closeWindow("buy_tili")
				else
					local var_27_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

					if arg_26_0.buyEnergyCost > var_27_1.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_29_0 = {}

							var_29_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_29_0)
						end, nil, nil, arg_26_0.colorMode)
					else
						arg_26_0.addEnergyModel:addEnergy(function(arg_30_0)
							if arg_30_0 == xyd.error.OK then
								return true
							end
						end)
						xyd.WindowManager.get():closeWindow("buy_tili")
						xyd.WindowManager.get():closeWindow("open_service")
					end
				end
			end
		}

		xyd.WindowManager.get():openWindow("buy_tili", var_26_3)
	else
		local var_26_4 = xyd.luaStringSplit(str, "\n")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_4, function()
			local var_31_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

			if arg_26_0.buyEnergyTimes >= arg_26_0.maxBuyTimes then
				str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_26_0.buyEnergyTimes)
				var_26_0 = xyd.AlertType.CONFIRM

				local var_31_1 = xyd.luaStringSplit(str, "\n")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_31_1, function()
					local var_32_0 = {}

					var_32_0.windowState = false

					xyd.WindowManager.get():openWindow("vip_recharge", var_32_0)
					xyd.WindowManager.get():closeWindow("add_energy")
				end, nil, nil, arg_26_0.colorMode)
			elseif arg_26_0.buyEnergyCost > var_31_0.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_33_0 = {}

					var_33_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_33_0)
				end, nil, nil, arg_26_0.colorMode)
			else
				arg_26_0.addEnergyModel:addEnergy(function(arg_34_0)
					if arg_34_0 == xyd.error.OK then
						return true
					end
				end)
				xyd.WindowManager.get():closeWindow("open_service")
			end
		end, nil, 0, arg_26_0.colorMode)
	end
end

function var_0_0.scrollListener(arg_35_0, arg_35_1)
	if arg_35_1.name == "began" then
		arg_35_0.scrollViewMoved_ = false
		arg_35_0.prevY_ = arg_35_1.y
	elseif arg_35_1.name == "moved" and 20 <= math.abs(arg_35_1.y - arg_35_0.prevY_) then
		arg_35_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateLeft(arg_36_0, arg_36_1)
	arg_36_0.label_index = arg_36_1

	arg_36_0.listView_:reload()

	for iter_36_0 = 1, 8 do
		arg_36_0:nodeByName("btn" .. iter_36_0):setBrightStyle(ccui.BrightStyle.normal)
	end

	arg_36_0:nodeByName("btn" .. arg_36_1):setBrightStyle(ccui.BrightStyle.highlight)

	local var_36_0 = arg_36_0.baseInfo.finish_count
	local var_36_1 = arg_36_0.idx

	if var_36_0 >= var_0_4:req(var_36_1) and arg_36_0.baseInfo.gift_awards[var_36_1] == 1 then
		arg_36_0:nodeByName("btn8"):setBright(false)
	end
end

function var_0_0.updateRedPoints(arg_37_0)
	for iter_37_0 = 1, arg_37_0.day do
		if arg_37_0.missionList[iter_37_0 * 5 - 4].state == var_0_6 then
			arg_37_0:nodeByName("btn" .. iter_37_0):getChildByName("red_point"):setVisible(true)
		end
	end

	local var_37_0 = arg_37_0.baseInfo.finish_count
	local var_37_1 = arg_37_0.idx

	if var_37_0 >= var_0_4:req(var_37_1) and arg_37_0.baseInfo.gift_awards[var_37_1] == 0 then
		arg_37_0:nodeByName("btn8"):getChildByName("red_point"):setVisible(true)
	end
end

function var_0_0.updateGift(arg_38_0, arg_38_1)
	local var_38_0 = arg_38_0:nodeByName("gift" .. arg_38_1)
	local var_38_1 = var_38_0:getChildByName("icon1")
	local var_38_2 = var_38_0:getChildByName("icon2")
	local var_38_3 = var_38_0:getChildByName("light")

	var_38_0:removeAllNodeEventListeners()
	var_38_3:setVisible(true)
	var_38_3:runAction(cc.RepeatForever:create(cc.RotateBy:create(5, 360)))
	var_38_1:setTouchEnabled(true)
	var_38_1:setVisible(true)
	var_38_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
		if arg_39_0.name == "began" then
			var_38_1:setScale(0.9)

			return true
		elseif arg_39_0.name == "canceled" then
			var_38_1:setScale(1)
		elseif arg_39_0.name == "ended" then
			var_38_1:setScale(1)
			xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward2(xyd.Activities.NewOpenService, 2, arg_38_1, function(arg_40_0, arg_40_1)
				if arg_40_0 == xyd.error.OK then
					arg_38_0.selfPlayer:handleRewards(arg_40_1.awards)
					var_38_1:setVisible(false)
					var_38_3:setVisible(false)
					var_38_2:setVisible(true)

					arg_38_0.baseInfo.gift_awards[arg_38_1] = 1
				end
			end)
		end
	end)
end

function var_0_0.didOpen(arg_41_0, arg_41_1)
	arg_41_0:addBlockLayer()
end

function var_0_0.willClose(arg_42_0, arg_42_1)
	var_0_2.unscheduleGlobal(arg_42_0.handle_)

	local var_42_0 = false

	for iter_42_0 = 1, 5 do
		if arg_42_0.baseInfo.finish_count > var_0_4:req(iter_42_0) and arg_42_0.baseInfo.gift_awards[iter_42_0] == 0 then
			var_42_0 = true
		end
	end

	for iter_42_1 = 1, arg_42_0.day do
		if arg_42_0.missionList[iter_42_1 * 5 - 4].state == var_0_6 then
			var_42_0 = true
		end
	end

	local var_42_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneTopWnd)

	if var_42_1 and var_42_1.newOpenServiceMark and not tolua.isnull(var_42_1.newOpenServiceMark) then
		if not var_42_0 then
			var_42_1.newOpenServiceMark:setVisible(false)
		else
			var_42_1.newOpenServiceMark:setVisible(true)
		end
	end
end

function var_0_0.isHasTiLiItem(arg_43_0)
	local var_43_0 = arg_43_0.selfPlayer:getBackpack():getItems()

	for iter_43_0, iter_43_1 in pairs(var_43_0) do
		if xyd.tables.item:subType(iter_43_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

function var_0_0.createListContent(arg_44_0, arg_44_1)
	arg_44_1 = arg_44_0.idx

	local var_44_0 = arg_44_0.baseInfo.finish_count
	local var_44_1 = var_0_4:req(arg_44_1)
	local var_44_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/open_service_window/item.csb")
	local var_44_3 = var_44_2:getChildByName("container")
	local var_44_4 = var_0_5:items(var_0_4:gift(arg_44_1))
	local var_44_5 = var_0_5:itemNum(var_0_4:gift(arg_44_1))

	for iter_44_0 = 1, #var_44_4 do
		local var_44_6 = display.newNode()

		var_44_6:setContentSize(70, 70)
		xyd.setItemAndAddTips(var_44_6, var_44_4[iter_44_0], var_44_5[iter_44_0])
		var_44_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_44_6:addTo(var_44_3:getChildByName("item_pos"))
		var_44_6:setPosition(85 * iter_44_0 - 85, 0)
	end

	local var_44_7 = display.newNode()

	var_44_3:getChildByName("bar_text"):setString(tostring(var_44_0) .. "/" .. tostring(var_44_1))
	var_44_3:getChildByName("desc"):setString(string.format(var_0_1:translation("FINISH_ALL_MISSION")))

	local var_44_8 = var_44_3:getChildByName("btn")

	var_44_8:setTouchSwallowEnabled(false)

	if var_44_0 < var_44_1 then
		var_44_8:setBright(false)
		var_44_8:getChildByName("go"):setVisible(false)
		var_44_8:getChildByName("get"):setVisible(false)
		var_44_8:getChildByName("get_gray"):setVisible(true)
	elseif arg_44_0.baseInfo.gift_awards[arg_44_1] == 0 then
		var_44_8:getChildByName("go"):setVisible(false)
		var_44_8:getChildByName("get"):setVisible(true)
		var_44_8:getChildByName("get_gray"):setVisible(false)
	else
		var_44_8:setVisible(false)
		var_44_3:getChildByName("bar_words"):setVisible(false)
		var_44_3:getChildByName("bar_text"):setVisible(false)
		var_44_3:getChildByName("got"):setVisible(true)
	end

	var_44_8:addTouchEventListener(function(arg_45_0, arg_45_1)
		if arg_45_1 == ccui.TouchEventType.ended and not arg_44_0.scrollViewMoved_ then
			xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward2(xyd.Activities.NewOpenService, 2, arg_44_1, function(arg_46_0, arg_46_1)
				if arg_46_0 == xyd.error.OK then
					arg_44_0.selfPlayer:handleRewards(arg_46_1.awards)
					var_44_8:setVisible(false)
					var_44_3:getChildByName("bar_words"):setVisible(false)
					var_44_3:getChildByName("bar_text"):setVisible(false)
					var_44_3:getChildByName("got"):setVisible(true)
					arg_44_0:updateLeft()
					arg_44_0:updateRedPoints()

					arg_44_0.baseInfo.gift_awards[arg_44_1] = 1
				else
					local var_46_0 = string.format(var_0_1:translation("MISSION_NOT_FINISH"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_46_0
					})
				end
			end)
		end
	end)
	var_44_2:addTo(var_44_7)
	var_44_2:setAnchorPoint(cc.p(0, 0))
	var_44_7:setContentSize(var_44_3:getContentSize())
	var_44_2:setName("source")

	return var_44_7
end

return var_0_0
