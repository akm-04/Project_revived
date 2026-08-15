local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.mizhuTreasureNew
local var_0_4 = 0.1
local var_0_5 = 10

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.itemContainers_ = {}
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

	arg_2_0.container = var_2_1

	arg_2_0:layout(var_2_1)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_1:getChildByName("txt_charge"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_CHARGE_2"))
	arg_3_1:getChildByName("txt_time"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_COUNT_TIME"))
	arg_3_1:getChildByName("charge_num"):setString(arg_3_0.activity.details.charge_count)

	local var_3_0 = arg_3_1:getChildByName("list"):getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_1:getChildByName("list")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0:updateList()
	xyd.nodeEventSample(arg_3_1:getChildByName("btn_rule"), nil, function()
		local var_4_0 = {
			title_name = "MIZHU_TREASURE_NEW_TITLE",
			rule = "MIZHU_TREASURE_NEW_RULE"
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
	end)

	arg_3_0.timeTxt = arg_3_1:getChildByName("time")

	arg_3_0:createTimer()
end

function var_0_0.updateList(arg_5_0)
	arg_5_0.list:removeAllItems()

	arg_5_0.itemContainers_ = {}

	for iter_5_0 = 1, #var_0_3:getIds() do
		local var_5_0 = arg_5_0.list:dequeueItem()

		if var_5_0 then
			var_5_0:removeAllChildren(true)
		else
			var_5_0 = arg_5_0.list:newItem()
		end

		local var_5_1 = arg_5_0:createRewardContent(iter_5_0)

		var_5_0:addContent(var_5_1)

		local var_5_2 = var_5_1:getContentSize()

		var_5_0:setContentSize(var_5_2)
		var_5_0:setItemSize(var_5_2.width, var_5_2.height + 5)
		arg_5_0.list:addItem(var_5_0)
	end

	arg_5_0.list:reload()
end

function var_0_0.createRewardContent(arg_6_0, arg_6_1)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1205/item.csb")
	local var_6_1 = var_6_0:getChildByName("container")

	var_6_0:setContentSize(var_6_1:getContentSize())
	table.insert(arg_6_0.itemContainers_, var_6_1)

	local var_6_2 = "windows/activities/1205/chest/chest_close_" .. arg_6_1 .. ".png"

	for iter_6_0 = 1, 3 do
		var_6_1:getChildByName("chest_" .. iter_6_0):setTexture(var_6_2)
	end

	local var_6_3 = var_0_3:recharge(arg_6_1)
	local var_6_4 = string.format(var_0_2:translation("MIZHU_TREASURE_NEW_CHARGE_1"), var_6_3)

	var_6_1:getChildByName("txt_title"):setString(var_6_4)
	var_6_1:getChildByName("txt_1"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_TEXT_3"))
	var_6_1:getChildByName("txt_2"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_TEXT_2"))
	var_6_1:getChildByName("txt_chest_1"):enableOutline(cc.c4b(69, 147, 208, 255), 2)
	var_6_1:getChildByName("txt_chest_2"):enableOutline(cc.c4b(86, 170, 104, 255), 2)
	var_6_1:getChildByName("txt_chest_3"):enableOutline(cc.c4b(206, 75, 118, 255), 2)

	local var_6_5 = arg_6_0.activity.details.is_award[arg_6_1]

	if var_6_5 ~= 0 then
		var_6_1:getChildByName("icon_recieved"):setVisible(true)

		local var_6_6 = "windows/activities/1205/chest/chest_open_" .. arg_6_1 .. ".png"

		var_6_1:getChildByName("chest_" .. var_6_5):setTexture(var_6_6)
	elseif arg_6_0:checkCanOpen(arg_6_1) then
		if arg_6_0.activity.is_open == 0 then
			var_6_1:getChildByName("txt_2"):setVisible(true)
			var_6_1:getChildByName("txt_2"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_TEXT_8"))
		else
			var_6_1:getChildByName("txt_2"):setVisible(true)

			for iter_6_1 = 1, 3 do
				local var_6_7 = cc.RepeatForever:create(cc.Sequence:create(cc.RotateBy:create(var_0_4, -var_0_5), cc.RotateBy:create(var_0_4, -var_0_5):reverse(), cc.RotateBy:create(var_0_4, var_0_5), cc.RotateBy:create(var_0_4, var_0_5):reverse(), cc.RotateBy:create(var_0_4, -var_0_5), cc.RotateBy:create(var_0_4, -var_0_5):reverse(), cc.RotateBy:create(var_0_4, var_0_5), cc.RotateBy:create(var_0_4, var_0_5):reverse(), cc.DelayTime:create(1)))

				var_6_1:getChildByName("chest_" .. iter_6_1):runAction(var_6_7)
			end
		end
	else
		var_6_1:getChildByName("txt_1"):setVisible(true)
	end

	for iter_6_2 = 1, 3 do
		var_6_1:getChildByName("txt_chest_" .. iter_6_2):setString(var_0_3:name(iter_6_2, arg_6_1))
		var_6_1:getChildByName("chest_" .. iter_6_2):setTouchSwallowEnabled(false)
		xyd.nodeEventSample(var_6_1:getChildByName("chest_" .. iter_6_2), nil, function()
			if arg_6_0.scrollViewMoved_ then
				return
			end

			local var_7_0 = {
				award_id = arg_6_1,
				pos = iter_6_2,
				award_flag = arg_6_0.activity.details.is_award[arg_6_1],
				can_open = arg_6_0:checkCanOpen(arg_6_1),
				activity_id = arg_6_0.activity.table_id,
				is_open = arg_6_0.activity.is_open,
				callback = handler(arg_6_0, arg_6_0.refreshList)
			}

			xyd.WindowManager.get():openWindow("mizhu_chest_detail_new", var_7_0)
		end)
	end

	return var_6_0
end

function var_0_0.updateItemContainer(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0.itemContainers_[arg_8_1]

	for iter_8_0 = 1, 3 do
		var_8_0:getChildByName("chest_" .. iter_8_0):stopAllActions()
		var_8_0:getChildByName("chest_" .. iter_8_0):setRotation(0)
	end

	local var_8_1 = "windows/activities/1205/chest/chest_open_" .. arg_8_1 .. ".png"
	local var_8_2 = arg_8_0.activity.details.is_award[arg_8_1]

	var_8_0:getChildByName("chest_" .. var_8_2):setTexture(var_8_1)
	var_8_0:getChildByName("icon_recieved"):setVisible(true)
	var_8_0:getChildByName("txt_2"):setVisible(false)
end

function var_0_0.refreshList(arg_9_0, arg_9_1, arg_9_2)
	arg_9_0.activity.details.is_award[arg_9_1] = arg_9_2

	arg_9_0:updateItemContainer(arg_9_1)
	arg_9_0.activitiesModel:refreshRedMark()

	local var_9_0 = xyd.WindowManager.get():getWindow("activities")

	if var_9_0 then
		var_9_0:updateActivityRedMark(arg_9_0.activity)
	end
end

function var_0_0.checkCanOpen(arg_10_0, arg_10_1)
	return arg_10_0.activity.details.charge_count >= var_0_3:recharge(arg_10_1)
end

function var_0_0.createTimer(arg_11_0)
	local var_11_0 = xyd.ServerTime.get():getServerTime()

	if var_11_0 >= arg_11_0.activity.end_time then
		arg_11_0.container:getChildByName("txt_time"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_TEXT_8"))
		arg_11_0.timeTxt:setVisible(false)

		return
	elseif var_11_0 < arg_11_0.activity.start_time then
		arg_11_0.container:getChildByName("txt_time"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_TEXT_7"))
		arg_11_0.timeTxt:setVisible(false)

		return
	else
		arg_11_0.timeTxt:setString(arg_11_0:createTimeTxt(var_11_0, arg_11_0.activity.end_time))
	end

	if arg_11_0.handle then
		var_0_1.unscheduleGlobal(arg_11_0.handle)

		arg_11_0.handle = nil
	end

	arg_11_0.handle = var_0_1.scheduleGlobal(function()
		local var_12_0 = xyd.ServerTime.get():getServerTime()

		arg_11_0.timeTxt:setString(arg_11_0:createTimeTxt(var_12_0, arg_11_0.activity.end_time))

		if var_12_0 > arg_11_0.activity.end_time and arg_11_0.handle then
			var_0_1.unscheduleGlobal(arg_11_0.handle)
			arg_11_0.container:getChildByName("txt_time"):setString(var_0_2:translation("MIZHU_TREASURE_NEW_TEXT_8"))
			arg_11_0.timeTxt:setVisible(false)

			arg_11_0.handle = nil
		end
	end, 1)
end

function var_0_0.createTimeTxt(arg_13_0, arg_13_1, arg_13_2)
	return xyd.secondsToString1(arg_13_2 - arg_13_1)
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevY_ = arg_14_1.y
	elseif arg_14_1.name == "moved" and 20 <= math.abs(arg_14_1.y - arg_14_0.prevY_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_15_0)
	if arg_15_0.handle then
		var_0_1.unscheduleGlobal(arg_15_0.handle)

		arg_15_0.handle = nil
	end
end

return var_0_0
