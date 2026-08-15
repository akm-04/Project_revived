local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc:getValue("activity_attr_id")
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.activityAttrRangeReward

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isShowWord = false
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	local var_2_1 = var_2_0:getChildByName("container")

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_1:getChildByName("txt_1"):setString(var_0_1:translation("SCHOLARSHIP_TIPS"))
	arg_3_1:getChildByName("txt_2"):setString(var_0_1:translation("SCHOLARSHIP_COUNT_TIPS"))
	arg_3_1:getChildByName("txt_2"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_3_0 = var_0_1:translation("ACTIVITY_ATTR_DESC")
	local var_3_1 = arg_3_0:createLabel(20, cc.c3b(137, 68, 45), var_3_0, arg_3_1)

	var_3_1:setPosition(arg_3_1:getChildByName("pos_txt_rule"):getPosition())
	var_3_1:setAnchorPoint(0, 1)
	var_3_1:setWidth(500)
	var_3_1:setLineHeight(28)

	local var_3_2 = arg_3_1:getChildByName("list"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2.width, var_3_2.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_1:getChildByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.rewardsDelegate))
	arg_3_0.list:reload()

	arg_3_0.timeTxt = arg_3_1:getChildByName("txt_time")

	arg_3_0.timeTxt:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_3_0:createScheduler()
	xyd.nodeEventSample(arg_3_1:getChildByName("button"), nil, function(arg_4_0)
		local var_4_0 = {
			key = "force",
			max_num = 50,
			title = var_0_1:translation("ACTIVITY_ATTR_TIP1"),
			desc = var_0_1:translation("ACTIVITY_ATTR_TIP"),
			my_rank = arg_3_0.activity.details.my_rank,
			rank_list = arg_3_0.activity.details.rank_list,
			title_color = cc.c3b(104, 67, 37),
			colorMode = xyd.ColorMode.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("common_rank", var_4_0)
	end)

	arg_3_0.word = arg_3_1:getChildByName("bg_talk")

	local var_3_3 = arg_3_1:getChildByName("touch")
	local var_3_4 = display.newNode()

	var_3_4:setContentSize(var_3_3:getContentSize())
	var_3_4:setAnchorPoint(0, 0)
	var_3_4:addTo(var_3_3)
	var_3_4:setPosition(0, 0)
	var_3_4:setTouchEnabled(true)
	var_3_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" and not arg_3_0.isShowWord then
			arg_3_0.isShowWord = true

			arg_3_0.word:setVisible(true)

			if arg_3_0.handle2 then
				var_0_3.unscheduleGlobal(arg_3_0.handle2)

				arg_3_0.handle2 = nil
			end

			arg_3_0.handle2 = var_0_3.performWithDelayGlobal(function()
				arg_3_0.word:setVisible(false)

				arg_3_0.isShowWord = false
			end, 5)
		end
	end)
end

function var_0_0.rewardsDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = var_0_4:getRange()

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #var_7_0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1 = arg_7_0.list:dequeueItem()

		if var_7_1 then
			var_7_1:removeAllChildren(true)
		else
			var_7_1 = arg_7_0.list:newItem()
		end

		local var_7_2 = arg_7_0:createRewardContent(arg_7_3)

		var_7_1:addContent(var_7_2)

		local var_7_3 = var_7_2:getContentSize()

		var_7_1:setContentSize(var_7_3)
		var_7_1:setItemSize(var_7_3.width, var_7_3.height + 5)

		return var_7_1
	end
end

function var_0_0.createRewardContent(arg_8_0, arg_8_1)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1196/item.csb")
	local var_8_1 = var_8_0:getChildByName("container")
	local var_8_2 = display.newNode()

	var_8_2:setContentSize(var_8_1:getContentSize())
	var_8_0:addTo(var_8_2)

	local var_8_3 = 90
	local var_8_4 = var_0_4:crystal(arg_8_1)
	local var_8_5 = display.newNode()

	var_8_5:setContentSize(80, 80)
	xyd.setItemBorder(var_8_5, -1, nil, nil, var_8_4)
	var_8_5:addTo(var_8_1:getChildByName("list_item"))
	var_8_5:setAnchorPoint(0, 0)
	var_8_5:setPosition(0, 0)
	arg_8_0:addTips(var_8_5, {
		id = -1,
		tipsType = 1
	})

	local var_8_6 = var_0_4:itemIds(arg_8_1)
	local var_8_7 = var_0_4:itemNums(arg_8_1)
	local var_8_8 = 90
	local var_8_9 = 0

	for iter_8_0 = 1, #var_8_6 do
		local var_8_10 = display.newNode()

		var_8_10:setContentSize(80, 80)
		xyd.setItemBorder(var_8_10, var_8_6[iter_8_0], nil, nil, var_8_7[iter_8_0])
		var_8_10:addTo(var_8_1:getChildByName("list_item"))
		var_8_10:setAnchorPoint(0, 0)
		var_8_10:setPosition(var_8_8, var_8_9)

		var_8_8 = var_8_8 + var_8_3

		local var_8_11 = {
			id = var_8_6[iter_8_0],
			lev = xyd.tables.item:level(var_8_6[iter_8_0])
		}

		if xyd.tables.item:type(var_8_6[iter_8_0]) == -1 then
			var_8_11.tipsType = 0
			var_8_11.desc1 = xyd.tables.hero:getDes(var_8_6[iter_8_0])
		else
			var_8_11.tipsType = 1
			var_8_11.desc1 = xyd.tables.item:desc1(var_8_6[iter_8_0])
			var_8_11.desc2 = xyd.tables.item:desc2(var_8_6[iter_8_0])
		end

		var_8_11.hasNum = arg_8_0.selfPlayer:getBackpack():getItemNumByID(var_8_6[iter_8_0])
		var_8_11.name = xyd.tables.item:name(var_8_6[iter_8_0])

		arg_8_0:addTips(var_8_10, var_8_11)
	end

	local var_8_12

	if arg_8_1 == 1 or var_0_4:range(arg_8_1) == var_0_4:range(arg_8_1 - 1) + 1 then
		var_8_12 = tostring(var_0_4:range(arg_8_1))
	else
		var_8_12 = var_0_4:range(arg_8_1 - 1) + 1 .. "-" .. var_0_4:range(arg_8_1)
	end

	local var_8_13 = string.format(var_0_1:translation("SCHOLARSHIP_REWARD_TIPS"), var_8_12)

	var_8_1:getChildByName("txt_title"):setString(var_8_13)
	var_8_1:getChildByName("txt_title"):enableOutline(cc.c4b(180, 54, 33, 255), 2)

	return var_8_2
end

function var_0_0.createScheduler(arg_9_0)
	if arg_9_0.handle then
		var_0_3.unscheduleGlobal(arg_9_0.handle)

		arg_9_0.handle = nil
	end

	arg_9_0.timeTxt:setString(arg_9_0:createTimeTxt())

	arg_9_0.handle = var_0_3.scheduleGlobal(function()
		arg_9_0.timeTxt:setString(arg_9_0:createTimeTxt())

		if xyd.ServerTime.get():getServerTime() > arg_9_0.activity.end_time - 25200 and arg_9_0.handle then
			var_0_3.unscheduleGlobal(arg_9_0.handle)

			arg_9_0.handle = nil
		end
	end, 1)
end

function var_0_0.createTimeTxt(arg_11_0)
	local var_11_0 = xyd.ServerTime.get():getServerTime()
	local var_11_1 = arg_11_0.activity.end_time - 25200

	if var_11_1 <= var_11_0 then
		return var_0_1:translation("THIRD_ANNIVERSARY_BOSS_TEXT4")
	else
		return xyd.secondsToString1(var_11_1 - var_11_0)
	end
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 10 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_13_0)
	if arg_13_0.handle then
		var_0_3.unscheduleGlobal(arg_13_0.handle)

		arg_13_0.handle = nil
	end

	if arg_13_0.handle2 then
		var_0_3.unscheduleGlobal(arg_13_0.handle2)

		arg_13_0.handle2 = nil
	end

	arg_13_0.isShowWord = false
end

return var_0_0
