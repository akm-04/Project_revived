local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:normalActivitiesLayout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.normalActivitiesLayout(arg_3_0, arg_3_1, arg_3_2)
	if not arg_3_0.res or arg_3_0.res == "0" then
		print("No res available.")

		return
	end

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_3_0.res)
	local var_3_1 = var_3_0:getChildByName("bg"):getChildByName("list")
	local var_3_2 = var_3_0:getChildByName("bg")
	local var_3_3 = var_3_1:getContentSize()
	local var_3_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_3.width, var_3_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_1):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	var_3_0:addTo(arg_3_0.parent)
	var_3_2:getChildByName("txt_num"):setString(arg_3_1.details.consume_count)
	var_3_2:getChildByName("txt_word"):setString(var_0_1:translation("ACTIVITY_1074_TEXT1"))

	local var_3_5 = {
		activity = arg_3_1,
		list = var_3_4,
		count = arg_3_2
	}

	arg_3_0:addActivityAwardList(var_3_5)
end

function var_0_0.addActivityAwardList(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.activities:tableName(arg_4_1.activity.table_id)

	if var_4_0 and var_4_0 ~= "" then
		arg_4_1.listNum = #import("app.common.tables." .. var_4_0).new():gifts()
		arg_4_1.obtainStates = xyd.luaStringSplit(arg_4_1.activity.details.is_awards, "|")

		if not arg_4_1.listNum then
			return
		else
			arg_4_0:createAwardList(arg_4_1)
		end
	end
end

function var_0_0.createAwardList(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.list
	local var_5_1 = arg_5_1.activity
	local var_5_2 = arg_5_1.listNum
	local var_5_3 = arg_5_1.count

	if arg_5_1.type then
		var_5_0:removeAllItems()
	end

	for iter_5_0 = 1, var_5_2 do
		if arg_5_0:checkInitItem(iter_5_0, arg_5_1) then
			local var_5_4 = var_5_0:newItem()
			local var_5_5 = display.newNode()
			local var_5_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1074/activity1074_item.csb")
			local var_5_7 = var_5_6:getChildByName("bg")

			arg_5_0:rewardItemLayout(var_5_1, var_5_7, var_5_3, iter_5_0)
			var_5_6:addTo(var_5_5)
			var_5_6:setTouchEnabled(true)
			var_5_6:setAnchorPoint(cc.p(0, 0))
			var_5_6:setPosition(0, 0)
			var_5_6:setTouchSwallowEnabled(false)
			var_5_5:setContentSize(667, 166)
			var_5_4:addContent(var_5_5)
			var_5_4:setItemSize(667, 176)
			var_5_0:addItem(var_5_4)
		end
	end

	var_5_0:reload()
end

function var_0_0.rewardItemLayout(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = arg_6_2:getChildByName("btn")
	local var_6_1 = arg_6_2:getChildByName("yilingqu")
	local var_6_2 = var_6_0:getChildByName("lingqu")
	local var_6_3 = var_6_0:getChildByName("get_gray")
	local var_6_4 = arg_6_2:getChildByName("expired")
	local var_6_5 = var_6_0:getChildByName("not_begin")
	local var_6_6 = {
		btn = var_6_0,
		alreadyObtain = var_6_1,
		obtain_bright = var_6_2,
		obtain_gray = var_6_3,
		expired = var_6_4,
		notBegin = var_6_5
	}
	local var_6_7 = arg_6_2:getChildByName("reward_container")
	local var_6_8 = import("app.common.tables.ActivityNewConsumeTable").new()
	local var_6_9 = var_6_8:name(arg_6_4)

	arg_6_2:getChildByName("txt_title"):setString(var_6_9)

	local var_6_10 = xyd.ServerTime.get():getServerTime()
	local var_6_11 = xyd.luaStringSplit(arg_6_1.details.is_awards, "|")

	if var_6_8:consume(arg_6_4) > arg_6_1.details.consume_count then
		arg_6_0:setBtnGetState(-1, var_6_6)
	elseif var_6_11[arg_6_4] == "1" then
		arg_6_0:setBtnGetState(0, var_6_6)
	else
		arg_6_0:setBtnGetState(1, var_6_6)
	end

	arg_6_0:rewardFormat(var_6_7, var_6_8:gift(arg_6_4))

	if not arg_6_0:checkTime(arg_6_1) then
		arg_6_0:setBtnGetState(-1, var_6_6)
	end

	if var_6_10 < arg_6_1.start_time then
		arg_6_0:setBtnGetState(-2, var_6_6)
	end

	var_6_0:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			arg_6_0.activitiesModel:getActivityReward(arg_6_1.table_id, arg_6_4, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_6_0.player:handleRewards(arg_8_1.awards)
					arg_6_0:setBtnGetState(0, var_6_6)

					if arg_6_0.activities[arg_6_3].details.is_awarded then
						arg_6_0.activities[arg_6_3].details.is_awarded = 1
					end

					if arg_6_0.activities[arg_6_3].details.is_awards then
						local var_8_0 = xyd.luaStringSplit(arg_6_0.activities[arg_6_3].details.is_awards, "|")

						var_8_0[arg_6_4] = "1"

						local var_8_1 = xyd.luaStringMerge(var_8_0, "|")

						arg_6_0.activities[arg_6_3].details.is_awards = var_8_1
					end

					arg_6_0:refreshRedPoint()
				end
			end)
		end
	end)
end

function var_0_0.checkInitItem(arg_9_0, arg_9_1, arg_9_2)
	return true
end

return var_0_0
