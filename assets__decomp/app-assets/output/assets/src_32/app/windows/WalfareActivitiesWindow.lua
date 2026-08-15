local var_0_0 = class("WalfareActivitiesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activities
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.gift
local var_0_5 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	if arg_1_2 then
		arg_1_0.details = arg_1_2.details
		arg_1_0.callback = arg_1_2.callback
	end

	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = arg_1_0.activitiesModel:getActivitiesList()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.leftIdx = 1
	arg_2_0.firstEnter = true
	arg_2_0.isLeftLayout = false
	arg_2_0.openedActivities = {}
	arg_2_0.leftItems = {}
	arg_2_0.leftContainer = arg_2_0:nodeByName("left_container")
	arg_2_0.rightListContainer = arg_2_0:nodeByName("right_container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:rightLayout()
end

function var_0_0.leftLayout(arg_4_0, arg_4_1)
	arg_4_0.leftIdx = arg_4_1

	local var_4_0 = arg_4_0.leftContainer
	local var_4_1 = var_4_0:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_1.width + 15, var_4_1.height + 14.5),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_4_0):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
	arg_4_0.list:setBounceable(false)
end

function var_0_0.rightLayout(arg_5_0)
	local var_5_0 = 0

	arg_5_0.showActivities = {}

	for iter_5_0 = 1, #arg_5_0.activities do
		local var_5_1 = arg_5_0.activities[iter_5_0]
		local var_5_2 = arg_5_0:createAcitivityShow(var_5_1.table_id, iter_5_0)

		if var_5_2 then
			if arg_5_0:checkIsOpen(var_5_1) and not arg_5_0:activityVanishCheck(var_5_1) then
				var_5_0 = var_5_0 + 1
				arg_5_0.showActivities[var_5_0] = clone(arg_5_0.activities[iter_5_0])
				arg_5_0.openedActivities[var_5_1.table_id] = var_5_2

				arg_5_0:initRightCell(var_5_1, content, var_5_0)
			else
				var_5_2:release()
			end
		end
	end

	return var_5_0
end

function var_0_0.initRightCell(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if not arg_6_0.isLeftLayout and (not arg_6_0.defaultTableId or arg_6_0.defaultTableId == -1 or arg_6_0.activities[arg_6_3].table_id == arg_6_0.defaultTableId) then
		arg_6_0:leftLayout(arg_6_3)

		arg_6_0.isLeftLayout = true
	end
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
		arg_7_0.prevY_ = arg_7_1.y
	elseif arg_7_1.name == "moved" then
		local var_7_0 = 3

		if var_7_0 <= math.abs(arg_7_1.y - arg_7_0.prevY_) or var_7_0 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
			arg_7_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.showActivities
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 197
		local var_8_2 = 75

		if arg_8_3 == 1 then
			var_8_2 = var_8_2 + 14.5
		end

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setAnchorPoint(cc.p(0, 0))
		arg_8_0:createExchangeItem(var_8_3, arg_8_3)
		var_8_3:setAnchorPoint(cc.p(0, 0))
		var_8_3:setContentSize(var_8_1, var_8_2)
		var_8_0:addContent(var_8_3)

		return var_8_0
	end
end

function var_0_0.createExchangeItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/walfare_activities/left_item.csb")
	local var_9_1 = var_9_0:getChildByName("container")
	local var_9_2 = arg_9_0.showActivities[arg_9_2]

	var_9_1:getChildByName("txt1"):setString(var_0_2:desc(var_9_2.table_id))
	var_9_1:getChildByName("txt2"):setString(var_0_2:desc(var_9_2.table_id))

	if arg_9_0.openedActivities[var_9_2.table_id] and arg_9_0.leftIdx == arg_9_2 then
		arg_9_0.lastActivityCell = var_9_0

		var_9_1:getChildByName("select_btn"):setVisible(true)
		var_9_1:getChildByName("split"):setVisible(false)
		var_9_1:getChildByName("split2"):setVisible(false)
		var_9_1:getChildByName("txt1"):setVisible(true)
		var_9_1:getChildByName("txt2"):setVisible(false)
		print("====================================", var_9_2.table_id)

		if arg_9_0.openedActivities[var_9_2.table_id] then
			xyd.AssetDownload.get():preloadActivitiesByTableID(tostring(var_9_2.table_id), function()
				arg_9_0.openedActivities[var_9_2.table_id]:show()
			end)
		end
	else
		var_9_1:getChildByName("select_btn"):setVisible(false)
		var_9_1:getChildByName("split"):setVisible(true)

		if arg_9_2 == 1 then
			var_9_1:getChildByName("split2"):setVisible(true)
		else
			var_9_1:getChildByName("split2"):setVisible(false)
		end

		var_9_1:getChildByName("txt1"):setVisible(false)
		var_9_1:getChildByName("txt2"):setVisible(true)
	end

	var_9_0:setTouchEnabled(true)
	var_9_0:setTouchSwallowEnabled(false)
	var_9_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" then
			if arg_9_0.leftIdx == arg_9_2 then
				return
			else
				arg_9_0.lastIdx = arg_9_0.leftIdx
				arg_9_0.leftIdx = arg_9_2
			end

			if not arg_9_0.scrollViewMoved_ then
				if arg_9_0.lastActivityCell and not tolua.isnull(arg_9_0.lastActivityCell) then
					local var_11_0 = arg_9_0.lastActivityCell:getChildByName("container")

					var_11_0:getChildByName("select_btn"):setVisible(false)
					var_11_0:getChildByName("split"):setVisible(true)

					if arg_9_0.lastIdx == 1 then
						var_11_0:getChildByName("split2"):setVisible(true)
					else
						var_11_0:getChildByName("split2"):setVisible(false)
					end

					var_11_0:getChildByName("txt1"):setVisible(false)
					var_11_0:getChildByName("txt2"):setVisible(true)
				end

				arg_9_0.lastActivityCell = var_9_0

				local var_11_1 = arg_9_0.lastActivityCell:getChildByName("container")

				var_11_1:getChildByName("select_btn"):setVisible(true)
				var_11_1:getChildByName("split"):setVisible(false)
				var_11_1:getChildByName("split2"):setVisible(false)
				var_11_1:getChildByName("txt1"):setVisible(true)
				var_11_1:getChildByName("txt2"):setVisible(false)
				arg_9_0.rightListContainer:removeAllChildren()
				print("====================================", var_9_2.table_id)

				if arg_9_0.openedActivities[var_9_2.table_id] then
					xyd.AssetDownload.get():preloadActivitiesByTableID(tostring(var_9_2.table_id), function()
						arg_9_0.openedActivities[var_9_2.table_id]:show()
					end)
				end

				for iter_11_0, iter_11_1 in pairs(arg_9_0.openedActivities) do
					if iter_11_0 ~= var_9_2.table_id and iter_11_1 then
						iter_11_1:release()
					end
				end
			end
		end
	end)
	var_9_0:addTo(arg_9_1)
	var_9_0:setAnchorPoint(cc.p(0, 0))

	arg_9_0.leftItems[var_9_2.table_id] = var_9_0

	arg_9_0:updateLeftRedMark(var_9_2.table_id)
	arg_9_1:setContentSize(var_9_1:getContentSize())
	var_9_0:setName("source")

	return arg_9_1
end

function var_0_0.updateLeftRedMark(arg_13_0, arg_13_1)
	if not arg_13_0.leftItems[arg_13_1] then
		return
	end

	if arg_13_0.activitiesModel.walfareRedMarkMap[arg_13_1] == true then
		arg_13_0.leftItems[arg_13_1]:getChildByName("container"):getChildByName("red_point"):setVisible(true)
	else
		arg_13_0.leftItems[arg_13_1]:getChildByName("container"):getChildByName("red_point"):setVisible(false)
	end
end

function var_0_0.updateRedMark(arg_14_0)
	for iter_14_0, iter_14_1 in pairs(arg_14_0.leftItems) do
		arg_14_0:updateLeftRedMark(iter_14_0)
	end
end

function var_0_0.didOpen(arg_15_0, arg_15_1)
	arg_15_0:addBlockLayer()
end

function var_0_0.createAcitivityShow(arg_16_0, arg_16_1, arg_16_2)
	if var_0_2:walfareShow(arg_16_1) ~= 1 then
		return false
	end

	local var_16_0 = {
		idx = arg_16_2,
		tableID = arg_16_1,
		parent = arg_16_0.rightListContainer
	}

	return import("app.windows.activities.Activity" .. arg_16_1).new(var_16_0)
end

function var_0_0.checkIsOpen(arg_17_0, arg_17_1)
	if arg_17_1.is_open == 1 and arg_17_1.days == -1 then
		return true
	elseif arg_17_1.days > 0 then
		return true
	else
		return false
	end
end

function var_0_0.activityVanishCheck(arg_18_0, arg_18_1)
	if arg_18_0.player.lev < var_0_2:levelReq(arg_18_1.table_id) then
		return true
	end

	if arg_18_1.table_id == xyd.Activities.MysteryGift and arg_18_1.details.create_time < arg_18_1.start_time then
		return true
	end

	local var_18_0 = xyd.ServerTime.get():getServerTime()

	if arg_18_1.days == -1 then
		if arg_18_1.details and arg_18_1.details.is_awarded and arg_18_1.details.is_awarded == 1 then
			if arg_18_1.table_id == xyd.Activities.SevenLogin or arg_18_1.table_id == xyd.Activities.SmallMonthCard or arg_18_1.table_id == xyd.Activities.MonthCard then
				return false
			else
				return true
			end
		end

		if arg_18_1.details and arg_18_1.details.is_awards then
			local var_18_1 = 0

			for iter_18_0, iter_18_1 in ipairs(xyd.luaStringSplit(arg_18_1.details.is_awards, "|")) do
				if iter_18_1 == "0" then
					var_18_1 = 1

					break
				end
			end

			if var_18_1 == 0 then
				return true
			end
		end

		if arg_18_1.details and arg_18_1.details.start_time and arg_18_1.table_id ~= xyd.Activities.SevendayGoal then
			if arg_18_1.table_id == xyd.Activities.PointExchange then
				local var_18_2 = var_0_2:cutOffTime(arg_18_1.table_id)

				if var_18_0 >= arg_18_1.details.end_time + var_18_2 * 24 * 60 * 60 then
					return true
				end
			elseif var_18_0 >= arg_18_1.details.end_time then
				return true
			end
		end
	elseif var_18_0 - arg_18_1.end_time >= 86400 then
		if xyd.db.activitiesIds:isActivityExist(arg_18_0.player.playerID, arg_18_1.table_id) then
			xyd.db.activitiesIds:deleteActivitiesId(arg_18_0.player.playerID, arg_18_1.table_id)
		end

		return true
	end

	return false
end

function var_0_0.updateActivitiesShow(arg_19_0)
	arg_19_0.activitiesModel:loadActivities(function()
		arg_19_0.activities = arg_19_0.activitiesModel:getActivitiesList()

		if arg_19_0.activities and next(arg_19_0.activities) then
			for iter_20_0, iter_20_1 in pairs(arg_19_0.openedActivities) do
				if iter_20_1 then
					iter_20_1:release()

					iter_20_1 = nil
				end
			end

			arg_19_0.rightListContainer:removeAllChildren()

			if arg_19_0:rightLayout() == 0 then
				arg_19_0:close()

				local var_20_0 = xyd.WindowManager.get():getWindow("main_scene_top")

				if var_20_0 and not tolua.isnull(var_20_0) then
					var_20_0:updateWalfareOpen(true)
				end
			else
				arg_19_0.list:reload()
			end
		else
			arg_19_0:close()

			local var_20_1 = xyd.WindowManager.get():getWindow("main_scene_top")

			if var_20_1 and not tolua.isnull(var_20_1) then
				var_20_1:updateWalfareOpen(true)
			end
		end
	end)
end

function var_0_0.willClose(arg_21_0, arg_21_1)
	for iter_21_0, iter_21_1 in pairs(arg_21_0.openedActivities) do
		if iter_21_1 then
			iter_21_1:release()

			iter_21_1 = nil
		end
	end

	if arg_21_0.callback then
		arg_21_0.callback()
	end
end

return var_0_0
