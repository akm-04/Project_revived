local var_0_0 = class("OpenServiceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.undoDetails = arg_1_2[1].details.undo_details
	arg_1_0.undoIDs_ = arg_1_2[1].details.undo_ids
	arg_1_0.doneIDs_ = arg_1_2[1].details.done_ids
	arg_1_0.gotIDs_ = arg_1_2[1].details.got_ids
	arg_1_0.day_count = arg_1_2[1].details.day_count
	arg_1_0.nowTime = arg_1_2[1].details.server_time
	arg_1_0.leftTime = 86400 - (os.date("%H", arg_1_0.nowTime) * 3600 + os.date("%M", arg_1_0.nowTime) * 60 + os.date("%S", arg_1_0.nowTime)) + (7 - arg_1_0.day_count) * 86400

	arg_1_0:detailsList()

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rewardTime = arg_1_0.leftTime + 86400
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.detailsList(arg_2_0)
	for iter_2_0 = 1, 7 do
		arg_2_0:nodeByName("red_point_" .. iter_2_0):setVisible(false)

		if iter_2_0 <= 3 then
			arg_2_0:nodeByName("red_point_2" .. iter_2_0):setVisible(false)
		end
	end

	arg_2_0.details = {}
	arg_2_0.undoIDs = {}
	arg_2_0.doneIDs = {}
	arg_2_0.gotIDs = {}

	for iter_2_1, iter_2_2 in pairs(arg_2_0.undoDetails) do
		arg_2_0.details[iter_2_2.id] = math.floor(iter_2_2.count)
	end

	for iter_2_3, iter_2_4 in pairs(arg_2_0.undoIDs_) do
		arg_2_0.undoIDs[iter_2_4] = 1
	end

	local var_2_0 = false

	for iter_2_5, iter_2_6 in pairs(arg_2_0.doneIDs_) do
		arg_2_0.doneIDs[iter_2_6] = 1

		if math.floor(iter_2_6 / 1000) <= arg_2_0.day_count then
			arg_2_0:nodeByName("red_point_" .. math.floor(iter_2_6 / 1000)):setVisible(true)

			var_2_0 = true
		end
	end

	if var_2_0 == false then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.OPEN_SERVICE_ACTIVITY_NOTICE_CLOSE
		})
	end

	for iter_2_7, iter_2_8 in pairs(arg_2_0.gotIDs_) do
		arg_2_0.gotIDs[iter_2_8] = 1
	end
end

function var_0_0.updateAll(arg_3_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity({
		activity_id = xyd.Activities.OpenService
	}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.undoDetails = arg_4_1.details.undo_details
			arg_3_0.undoIDs_ = arg_4_1.details.undo_ids
			arg_3_0.doneIDs_ = arg_4_1.details.done_ids
			arg_3_0.gotIDs_ = arg_4_1.details.got_ids
			arg_3_0.day_count = arg_4_1.details.day_count
			arg_3_0.nowTime = arg_4_1.details.server_time
			arg_3_0.leftTime = 86400 - (os.date("%H", arg_3_0.nowTime) * 3600 + os.date("%M", arg_3_0.nowTime) * 60 + os.date("%S", arg_3_0.nowTime)) + (7 - arg_3_0.day_count) * 86400

			arg_3_0:detailsList()
			arg_3_0:updateLeft(arg_3_0.day_index)
			arg_3_0:updateLabel(arg_3_0.label_index)

			if arg_3_0.scrolly then
				arg_3_0.listView_:scrollTo(0, arg_3_0.scrolly)
			end
		end
	end)
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	var_0_0.super:willOpen(arg_5_1)
	arg_5_0:layout()
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("activity_time"):setString(var_0_1:translation("ACTIVITY_OVER_TIME"))
	arg_6_0:nodeByName("reward_time"):setString(var_0_1:translation("REWARD_OVER_TIME"))

	arg_6_0.label_index = 1
	arg_6_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_6_0:nodeByName("list_container"):getWidth(), arg_6_0:nodeByName("list_container"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0:nodeByName("list_container")):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.listView_:setBounceable(true)
	arg_6_0.listView_:setDelegate(handler(arg_6_0, arg_6_0.delegate))

	for iter_6_0 = 1, 7 do
		arg_6_0:nodeByName("day_btn_" .. iter_6_0):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.began then
				return true
			elseif arg_7_1 == ccui.TouchEventType.ended then
				arg_6_0:updateLeft(iter_6_0)

				return true
			end
		end)
	end

	for iter_6_1 = 1, 3 do
		arg_6_0:nodeByName("label_btn_" .. iter_6_1):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.began then
				return true
			elseif arg_8_1 == ccui.TouchEventType.ended then
				arg_6_0:updateLabel(iter_6_1)

				return true
			end
		end)
	end

	arg_6_0:updateLeft(1)
	arg_6_0:updateTime()

	arg_6_0.handle_ = var_0_2.scheduleGlobal(function()
		arg_6_0:updateTime()
	end, 10)
end

function var_0_0.updateTime(arg_10_0)
	local var_10_0 = arg_10_0.leftTime

	arg_10_0.leftTime = arg_10_0.leftTime - 10
	arg_10_0.rewardTime = arg_10_0.rewardTime - 10

	if math.floor(var_10_0 / 86400) - math.floor(arg_10_0.leftTime / 86400) == 1 then
		arg_10_0:updateAll()
	end

	if arg_10_0.leftTime and arg_10_0.leftTime > 0 then
		local var_10_1 = math.floor(arg_10_0.leftTime % 3600 / 60)
		local var_10_2 = math.floor(arg_10_0.leftTime / 3600 % 24)
		local var_10_3 = math.floor(arg_10_0.leftTime / 86400)

		arg_10_0:nodeByName("activity_time_text"):setString(string.format(var_0_1:translation("ACTIVITY_LEFT_TIME"), var_10_3, var_10_2, var_10_1))
	else
		arg_10_0:nodeByName("activity_time_text"):setString(var_0_1:translation("ALREADY_OVER"))
	end

	if arg_10_0.rewardTime and arg_10_0.rewardTime > 0 then
		local var_10_4 = math.floor(arg_10_0.rewardTime % 3600 / 60)
		local var_10_5 = math.floor(arg_10_0.rewardTime / 3600 % 24)
		local var_10_6 = math.floor(arg_10_0.rewardTime / 86400)

		arg_10_0:nodeByName("reward_time_text"):setString(string.format(var_0_1:translation("ACTIVITY_LEFT_TIME"), var_10_6, var_10_5, var_10_4))
	else
		arg_10_0:nodeByName("reward_time_text"):setString(var_0_1:translation("ALREADY_OVER"))
	end
end

function var_0_0.delegate(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	data = arg_11_0.list_items

	if cc.ui.UIListView.COUNT_TAG == arg_11_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_11_2 then
		if arg_11_3 > #data then
			return nil
		end

		local var_11_0 = arg_11_0.listView_:dequeueItem()

		if not var_11_0 then
			var_11_0 = arg_11_0.listView_:newItem()
		else
			var_11_0:removeAllChildren(true)
		end

		local var_11_1 = data[arg_11_3]
		local var_11_2 = display.newNode()

		arg_11_0:initCell(var_11_2, var_11_1)

		local var_11_3 = display.newNode()

		var_11_3:addChild(var_11_2)
		var_11_2:setPosition(10, -5)
		var_11_3:setContentSize(665, 137)
		var_11_0:setItemSize(665, 137)
		var_11_0:addContent(var_11_3)

		return var_11_0
	end
end

function var_0_0.initCell(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/open_service_window/reward_item.csb")
	local var_12_1 = var_12_0:getChildByName("container")
	local var_12_2 = var_12_1:getContentSize()

	var_12_1:getChildByName("bar_words"):setString(var_0_1:translation("RATE_OF_ADVANCE"))
	var_12_1:getChildByName("purpose_text"):setString(arg_12_2.desc)

	local var_12_3 = ""

	if arg_12_2.id % 2200 > 0 and arg_12_2.id % 2200 < 100 then
		if arg_12_0.details[arg_12_2.id] then
			if arg_12_0.details[arg_12_2.id] > 3 then
				var_12_3 = var_12_3 .. 3
			else
				var_12_3 = var_12_3 .. arg_12_0.details[arg_12_2.id]
			end
		else
			var_12_3 = var_12_3 .. 3
		end

		var_12_3 = var_12_3 .. "/3"
	else
		if arg_12_2.id % 3200 > 0 and arg_12_2.id % 3200 < 100 then
			if arg_12_0.details[arg_12_2.id] then
				arg_12_0.myRank = arg_12_0.details[arg_12_2.id]

				if arg_12_0.details[arg_12_2.id] <= arg_12_2.condition then
					var_12_3 = var_12_3 .. arg_12_0.details[arg_12_2.id]
				else
					var_12_3 = var_12_3 .. "0"
				end
			elseif arg_12_0.myRank then
				var_12_3 = var_12_3 .. arg_12_0.myRank
			else
				var_12_3 = var_12_3 .. arg_12_2.condition
			end
		elseif arg_12_0.details[arg_12_2.id] then
			if arg_12_0.details[arg_12_2.id] > arg_12_2.condition then
				var_12_3 = var_12_3 .. arg_12_2.condition
			else
				var_12_3 = var_12_3 .. arg_12_0.details[arg_12_2.id]
			end
		elseif arg_12_2.condition < 10000 then
			var_12_3 = var_12_3 .. arg_12_2.condition
		else
			var_12_3 = var_12_3 .. "1"
		end

		var_12_3 = var_12_3 .. "/"

		if arg_12_2.condition < 10000 then
			var_12_3 = var_12_3 .. arg_12_2.condition
		else
			var_12_3 = var_12_3 .. "1"
		end
	end

	local var_12_4 = xyd.tables.gift:items(arg_12_2.reward)

	arg_12_0.itemTips = {}

	local var_12_5 = 0

	for iter_12_0 = 1, #var_12_4 do
		if var_12_4[iter_12_0] ~= 0 then
			local var_12_6 = cc.Node:create()

			var_12_6:setContentSize(66, 66)
			xyd.setItemBorder(var_12_6, var_12_4[iter_12_0], nil, nil, xyd.tables.gift:itemNum(arg_12_2.reward)[iter_12_0])
			var_12_1:getChildByName("reward_container"):addChild(var_12_6)
			var_12_6:setPosition(iter_12_0 * 80 - 80 + 5, 2)

			local var_12_7 = {
				id = var_12_4[iter_12_0],
				hasNum = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_4[iter_12_0])
			}
			local var_12_8, var_12_9 = var_12_6:getPosition()

			var_12_6:setTouchEnabled(true)
			var_12_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
				if arg_13_0.name == "began" then
					local var_13_0 = xyd.WindowManager.get():getWindow("new_item_tips")
					local var_13_1 = arg_12_0:convertToWorldSpace(cc.p(0, 0))

					if not var_13_0 then
						local var_13_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_12_7)

						xyd.adaptToWorldPosition(var_12_6, var_13_2)
					end

					return true
				elseif arg_13_0.name == "ended" then
					wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
				end
			end)

			var_12_5 = var_12_5 + 1
		end
	end

	if xyd.tables.gift:mana(arg_12_2.reward) ~= 0 then
		var_12_5 = var_12_5 + 1

		local var_12_10 = cc.Node:create()

		var_12_10:setContentSize(88, 88)
		xyd.setItemBorder(var_12_10, -2, nil, nil, xyd.tables.gift:mana(arg_12_2.reward))
		var_12_10:setScale(0.75)
		var_12_1:getChildByName("reward_container"):addChild(var_12_10)
		var_12_10:setPosition(var_12_5 * 80 - 80 + 5, 2)

		local var_12_11 = {}

		var_12_11.id = -2
		var_12_11.hasNum = arg_12_0.selfPlayer.mana

		local var_12_12, var_12_13 = var_12_10:getPosition()

		var_12_10:setTouchEnabled(true)
		var_12_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "began" then
				local var_14_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_14_1 = arg_12_0:convertToWorldSpace(cc.p(0, 0))

				if not var_14_0 then
					local var_14_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_12_11)

					xyd.adaptToWorldPosition(var_12_10, var_14_2)
				end

				return true
			elseif arg_14_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	if xyd.tables.gift:crystal(arg_12_2.reward) ~= 0 then
		var_12_5 = var_12_5 + 1

		local var_12_14 = cc.Node:create()

		var_12_14:setContentSize(88, 88)
		xyd.setItemBorder(var_12_14, -1, nil, nil, xyd.tables.gift:crystal(arg_12_2.reward))
		var_12_14:setScale(0.75)
		var_12_1:getChildByName("reward_container"):addChild(var_12_14)
		var_12_14:setPosition(var_12_5 * 80 - 80 + 5, 2)

		local var_12_15 = {}

		var_12_15.id = -1
		var_12_15.hasNum = arg_12_0.selfPlayer.crystal

		local var_12_16, var_12_17 = var_12_14:getPosition()

		var_12_14:setTouchEnabled(true)
		var_12_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "began" then
				local var_15_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_15_1 = arg_12_0:convertToWorldSpace(cc.p(0, 0))

				if not var_15_0 then
					local var_15_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_12_15)

					xyd.adaptToWorldPosition(var_12_14, var_15_2)
				end

				return true
			elseif arg_15_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	if xyd.tables.gift:arenaCoin(arg_12_2.reward) ~= 0 then
		var_12_5 = var_12_5 + 1

		local var_12_18 = cc.Node:create()

		var_12_18:setContentSize(88, 88)
		xyd.setItemBorder(var_12_18, -3, nil, nil, xyd.tables.gift:arenaCoin(arg_12_2.reward))
		var_12_18:setScale(0.75)
		var_12_1:getChildByName("reward_container"):addChild(var_12_18)
		var_12_18:setPosition(var_12_5 * 80 - 80 + 5, 2)

		local var_12_19 = {}

		var_12_19.id = -3
		var_12_19.hasNum = arg_12_0.selfPlayer.arena_coin

		local var_12_20, var_12_21 = var_12_18:getPosition()

		var_12_18:setTouchEnabled(true)
		var_12_18:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
			if arg_16_0.name == "began" then
				local var_16_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_16_1 = arg_12_0:convertToWorldSpace(cc.p(0, 0))

				if not var_16_0 then
					local var_16_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_12_19)

					xyd.adaptToWorldPosition(var_12_18, var_16_2)
				end

				return true
			elseif arg_16_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	if xyd.tables.gift:marchCoin(arg_12_2.reward) ~= 0 then
		local var_12_22 = var_12_5 + 1
		local var_12_23 = cc.Node:create()

		var_12_23:setContentSize(88, 88)
		xyd.setItemBorder(var_12_23, -4, nil, nil, xyd.tables.gift:marchCoin(arg_12_2.reward))
		var_12_23:setScale(0.75)
		var_12_1:getChildByName("reward_container"):addChild(var_12_23)
		var_12_23:setPosition(var_12_22 * 80 - 80 + 5, 2)

		local var_12_24 = {}

		var_12_24.id = -4
		var_12_24.hasNum = arg_12_0.selfPlayer.march_coin

		local var_12_25, var_12_26 = var_12_23:getPosition()

		var_12_23:setTouchEnabled(true)
		var_12_23:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				local var_17_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_17_1 = arg_12_0:convertToWorldSpace(cc.p(0, 0))

				if not var_17_0 then
					local var_17_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_12_24)

					xyd.adaptToWorldPosition(var_12_23, var_17_2)
				end

				return true
			elseif arg_17_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	var_12_1:getChildByName("bar_text"):setString(var_12_3)
	arg_12_1:setContentSize(var_12_2)
	var_12_0:setName("layout")
	var_12_0:setPosition(cc.p(0, 0))
	arg_12_1:addChild(var_12_0)
	arg_12_1:setTouchSwallowEnabled(false)
	arg_12_1:setTouchEnabled(true)

	if arg_12_2.itemState == var_0_3 then
		var_12_1:getChildByName("get_words"):setVisible(false)
		var_12_1:getChildByName("has_got"):setVisible(false)

		if arg_12_0.leftTime > 0 then
			var_12_1:getChildByName("go_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
				if arg_18_1 == ccui.TouchEventType.began then
					return true
				elseif arg_18_1 == ccui.TouchEventType.ended then
					if arg_12_0.day_index > arg_12_0.day_count then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ACTIVITY_NO_OPEN")
						})

						return true
					end

					if arg_12_0.startClick_ == true then
						if arg_12_0.label_index == 1 then
							xyd.WindowManager.get():openWindow("vip_recharge")
						elseif arg_12_0.label_index == 2 then
							if arg_12_0.day_index == 1 then
								xyd.WindowManager.get():openWindow("map_window", {
									chapter_type = 1
								})
								xyd.WindowManager.get():closeWindow(arg_12_0)
							elseif arg_12_0.day_index == 2 then
								if arg_12_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SKILL_UP) == true then
									xyd.WindowManager.get():openWindow("hero_list")
									xyd.WindowManager.get():closeWindow(arg_12_0)
								else
									local var_18_0 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_SKILL_UP)
									local var_18_1 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_0)

									xyd.WindowManager.get():openWindow("toast", {
										message = var_18_1
									})
								end
							elseif arg_12_0.day_index == 3 then
								if arg_12_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ARENA) == true then
									xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_19_0, arg_19_1)
										if arg_19_0 == xyd.error.OK then
											xyd.WindowManager.get():openWindow("arena")
											xyd.WindowManager.get():closeWindow(arg_12_0)
										end
									end)
								else
									local var_18_2 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ARENA)
									local var_18_3 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_2)

									xyd.WindowManager.get():openWindow("toast", {
										message = var_18_3
									})
								end
							elseif arg_12_0.day_index == 4 then
								if arg_12_0.selfPlayer.super_chapter_id <= 0 then
									xyd.WindowManager.get():openWindow("toast", {
										message = var_0_1:translation("SUPER_STORE_NOT_OPEN")
									})
								else
									xyd.WindowManager.get():openWindow("map_window", {
										chapter_type = 2
									})
									xyd.WindowManager.get():closeWindow(arg_12_0)
								end
							elseif arg_12_0.day_index == 5 then
								xyd.WindowManager.get():openWindow("hero_list")
								xyd.WindowManager.get():closeWindow(arg_12_0)
							elseif arg_12_0.day_index == 6 then
								xyd.WindowManager.get():openWindow("map_window", {
									chapter_type = 1
								})
								xyd.WindowManager.get():closeWindow(arg_12_0)
							elseif arg_12_0.day_index == 7 then
								xyd.WindowManager.get():openWindow("map_window", {
									chapter_type = 1
								})
								xyd.WindowManager.get():closeWindow(arg_12_0)
							end
						elseif arg_12_0.day_index == 1 then
							if arg_12_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SUMMON) == true then
								xyd.WindowManager.get():openWindow("summon")
								xyd.WindowManager.get():closeWindow(arg_12_0)
							else
								local var_18_4 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_SUMMON)
								local var_18_5 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_4)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_18_5
								})
							end
						elseif arg_12_0.day_index == 2 then
							xyd.WindowManager.get():openWindow("mission")
							xyd.WindowManager.get():closeWindow(arg_12_0)
						elseif arg_12_0.day_index == 3 then
							if arg_12_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_FUMO) == true then
								xyd.WindowManager.get():openWindow("fumo")
								xyd.WindowManager.get():closeWindow(arg_12_0)
							else
								local var_18_6 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_FUMO)
								local var_18_7 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_6)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_18_7
								})
							end
						elseif arg_12_0.day_index == 4 then
							xyd.WindowManager.get():openWindow("map_window", {
								chapter_type = 1
							})
							xyd.WindowManager.get():closeWindow(arg_12_0)
						elseif arg_12_0.day_index == 5 then
							if arg_12_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_MARCH) == true then
								local var_18_8 = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)

								if var_18_8.mapInfo == nil then
									var_18_8:loadMarchInfo({}, function(arg_20_0)
										if arg_20_0 == xyd.error.OK then
											xyd.WindowManager.get():openWindow("march")
											xyd.WindowManager.get():closeWindow(arg_12_0)
										end
									end)
								else
									xyd.WindowManager.get():openWindow("march")
									xyd.WindowManager.get():closeWindow(arg_12_0)
								end
							else
								local var_18_9 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_MARCH)
								local var_18_10 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_9)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_18_10
								})
							end
						elseif arg_12_0.day_index == 6 then
							xyd.WindowManager.get():openWindow("map_window", {
								chapter_type = 1
							})
							xyd.WindowManager.get():closeWindow(arg_12_0)
						elseif arg_12_0.day_index == 7 then
							if arg_12_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ARENA) == true then
								xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA):loadArenaInfo(function(arg_21_0, arg_21_1)
									if arg_21_0 == xyd.error.OK then
										xyd.WindowManager.get():openWindow("arena")
										xyd.WindowManager.get():closeWindow(arg_12_0)
									end
								end)
							else
								local var_18_11 = xyd.tables.functionOpen:level(xyd.FunctionID.ID_ARENA)
								local var_18_12 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_18_11)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_18_12
								})
							end
						end
					end

					return true
				end
			end)
		else
			local var_12_27 = display.newFilteredSprite("windows/button/small_button1.png", "GRAY", {
				0.2,
				0.3,
				0.5,
				0.1
			})

			var_12_27:setAnchorPoint(cc.p(0, 0))
			var_12_1:getChildByName("go_btn"):addChild(var_12_27)

			local var_12_28 = display.newFilteredSprite("windows/open_service_window/go.png", "GRAY", {
				0.2,
				0.3,
				0.5,
				0.1
			})

			var_12_28:setAnchorPoint(cc.p(0, 0))
			var_12_1:getChildByName("go"):addChild(var_12_28)
			var_12_1:getChildByName("go_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
				if arg_22_1 == ccui.TouchEventType.began then
					return true
				elseif arg_22_1 == ccui.TouchEventType.ended then
					if arg_12_0.day_index > arg_12_0.day_count then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ACTIVITY_NO_OPEN")
						})

						return true
					end

					if arg_12_0.startClick_ == true then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ACTIVITY_FINISHED")
						})
					end

					return true
				end
			end)
		end
	elseif arg_12_2.itemState == var_0_4 then
		var_12_1:getChildByName("go"):setVisible(false)
		var_12_1:getChildByName("has_got"):setVisible(false)

		if arg_12_0.rewardTime > 0 then
			var_12_1:getChildByName("go_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
				if arg_23_1 == ccui.TouchEventType.began then
					return true
				elseif arg_23_1 == ccui.TouchEventType.ended then
					if arg_12_0.day_index > arg_12_0.day_count then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ACTIVITY_NO_OPEN")
						})

						return true
					end

					if arg_12_0.startClick_ == true then
						xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivityReward(xyd.Activities.OpenService, arg_12_2.id, function(arg_24_0, arg_24_1)
							if arg_24_0 == xyd.error.OK then
								arg_12_0.selfPlayer:handleRewards(arg_24_1.awards)
								arg_12_0:updateAll()
							end
						end)
					end

					return true
				end
			end)
		else
			local var_12_29 = display.newFilteredSprite("windows/button/small_button1.png", "GRAY", {
				0.2,
				0.3,
				0.5,
				0.1
			})

			var_12_29:setAnchorPoint(cc.p(0, 0))
			var_12_1:getChildByName("go_btn"):addChild(var_12_29)

			local var_12_30 = display.newFilteredSprite("windows/open_service_window/get_words.png", "GRAY", {
				0.2,
				0.3,
				0.5,
				0.1
			})

			var_12_30:setAnchorPoint(cc.p(0, 0))
			var_12_1:getChildByName("get_words"):addChild(var_12_30)
			var_12_1:getChildByName("go_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
				if arg_25_1 == ccui.TouchEventType.began then
					return true
				elseif arg_25_1 == ccui.TouchEventType.ended then
					if arg_12_0.day_index > arg_12_0.day_count then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ACTIVITY_NO_OPEN")
						})

						return true
					end

					if arg_12_0.startClick_ == true then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ACTIVITY_FINISHED")
						})
					end

					return true
				end
			end)
		end
	else
		var_12_1:getChildByName("go"):setVisible(false)
		var_12_1:getChildByName("has_got"):setVisible(true)
		var_12_1:getChildByName("get_words"):setVisible(false)

		local var_12_31 = display.newFilteredSprite("windows/button/small_button1.png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		var_12_31:setAnchorPoint(cc.p(0, 0))
		var_12_1:getChildByName("go_btn"):addChild(var_12_31)
		var_12_1:getChildByName("go_btn"):addTouchEventListener(function(arg_26_0, arg_26_1)
			if arg_26_1 == ccui.TouchEventType.began then
				return true
			elseif arg_26_1 == ccui.TouchEventType.ended then
				if arg_12_0.day_index > arg_12_0.day_count then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_NO_OPEN")
					})

					return true
				end

				if arg_12_0.startClick_ == true then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("HAVE_GET_AWARD")
					})
				end

				return true
			end
		end)
	end

	if arg_12_0.day_index > arg_12_0.day_count then
		var_12_1:getChildByName("get_words"):setVisible(false)
		var_12_1:getChildByName("go"):setVisible(true)
		var_12_1:getChildByName("has_got"):setVisible(false)

		local var_12_32 = display.newFilteredSprite("windows/button/small_button1.png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		var_12_32:setAnchorPoint(cc.p(0, 0))
		var_12_1:getChildByName("go_btn"):addChild(var_12_32)

		local var_12_33 = display.newFilteredSprite("windows/open_service_window/go.png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		var_12_33:setAnchorPoint(cc.p(0, 0))
		var_12_1:getChildByName("go"):addChild(var_12_33)
	end
end

function var_0_0.scrollListener(arg_27_0, arg_27_1)
	if arg_27_1.name == "began" then
		arg_27_0.startClick_ = true
		arg_27_0.prevY_ = arg_27_1.y
	elseif arg_27_1.name == "moved" then
		local var_27_0 = 20

		arg_27_0.scrolly = arg_27_0.listView_:getScrollNode():getPositionY()

		if var_27_0 <= math.abs(arg_27_1.y - arg_27_0.prevY_) then
			arg_27_0.startClick_ = false
		end
	elseif arg_27_1.name == "scrollEnd" then
		arg_27_0.scrolly = arg_27_0.listView_:getScrollNode():getPositionY()
	end
end

function var_0_0.updateLabel(arg_28_0, arg_28_1)
	arg_28_0.label_index = arg_28_1

	arg_28_0.listView_:removeAllItems()

	for iter_28_0 = 1, 3 do
		arg_28_0:nodeByName("label_btn_" .. iter_28_0):setBrightStyle(ccui.BrightStyle.normal)
	end

	arg_28_0:nodeByName("label_btn_" .. arg_28_1):setBrightStyle(ccui.BrightStyle.highlight)

	arg_28_0.list_items = {}

	local var_28_0 = {}

	for iter_28_1 = 1, 99 do
		if xyd.tables.openService:condition(tonumber(arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1))) == nil then
			break
		end

		local var_28_1 = {
			id = tonumber(arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1)),
			reward = xyd.tables.openService:reward(tonumber(arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1))),
			desc = xyd.tables.openService:desc(tonumber(arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1))),
			condition = xyd.tables.openService:condition(tonumber(arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1))),
			itemState = var_0_3
		}

		if arg_28_0.undoIDs[arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1)] then
			var_28_1.undo = true
		end

		if arg_28_0.gotIDs[arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1)] then
			var_28_1.itemState = var_0_5
		elseif arg_28_0.doneIDs[arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1)] then
			var_28_1.itemState = var_0_4
		elseif arg_28_0.undoIDs[arg_28_0.day_index .. arg_28_0.label_index .. string.format("%02d", iter_28_1)] then
			var_28_1.itemState = var_0_3
		end

		if var_28_1.itemState == var_0_4 then
			table.insert(arg_28_0.list_items, var_28_1)
		else
			table.insert(var_28_0, var_28_1)
		end
	end

	for iter_28_2, iter_28_3 in ipairs(var_28_0) do
		table.insert(arg_28_0.list_items, iter_28_3)
	end

	arg_28_0.listView_:reload()
end

function var_0_0.updateLeft(arg_29_0, arg_29_1)
	arg_29_0.day_index = arg_29_1

	arg_29_0:updateLabel(arg_29_0.label_index)

	for iter_29_0 = 1, 3 do
		arg_29_0:nodeByName("red_point_2" .. iter_29_0):setVisible(false)

		for iter_29_1 = 1, 99 do
			if xyd.tables.openService:condition(tonumber(arg_29_0.day_index .. iter_29_0 .. string.format("%02d", iter_29_1))) == nil then
				break
			end

			if arg_29_0.doneIDs[arg_29_0.day_index .. iter_29_0 .. string.format("%02d", iter_29_1)] and arg_29_0.day_index <= arg_29_0.day_count then
				arg_29_0:nodeByName("red_point_2" .. iter_29_0):setVisible(true)
			end
		end
	end

	for iter_29_2 = 1, 7 do
		arg_29_0:nodeByName("day_btn_" .. iter_29_2):setBrightStyle(ccui.BrightStyle.normal)
		arg_29_0:nodeByName("label_2_" .. iter_29_2):setVisible(false)
		arg_29_0:nodeByName("label_3_" .. iter_29_2):setVisible(false)
	end

	arg_29_0:nodeByName("label_2_" .. arg_29_1):setVisible(true)
	arg_29_0:nodeByName("label_3_" .. arg_29_1):setVisible(true)
	arg_29_0:nodeByName("day_btn_" .. arg_29_1):setBrightStyle(ccui.BrightStyle.highlight)
end

function var_0_0.didOpen(arg_30_0, arg_30_1)
	var_0_0.super:didOpen(arg_30_1)
	arg_30_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.willClose(arg_31_0, arg_31_1)
	var_0_0.super:willClose(arg_31_1)
	var_0_2.unscheduleGlobal(arg_31_0.handle_)
end

return var_0_0
