local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:layout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1054/normal_activity.csb")
	local var_3_1 = var_3_0:getChildByName("container")

	arg_3_0.container = var_3_1

	local var_3_2 = var_3_0:getChildByName("container"):getChildByName("list")

	arg_3_0.parent:removeAllChildren()
	var_3_0:addTo(arg_3_0.parent)
	var_3_0:setPosition(cc.p(0, 0))

	local var_3_3 = {
		size = 18,
		color = cc.c3b(86, 96, 120)
	}
	local var_3_4 = xyd.AssetLoader.get():loadLabel(var_3_3)

	var_3_4:setMaxLineWidth(500)
	var_3_4:setAnchorPoint(cc.p(0, 1))
	var_3_4:addTo(var_3_1)
	var_3_4:setPosition(var_3_1:getChildByName("activity_desc_pos"):getPositionX(), var_3_1:getChildByName("activity_desc_pos"):getPositionY())
	var_3_4:setString(xyd.tables.activities:desc(arg_3_1.table_id))

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 667, 370),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	})

	arg_3_0.awardList:addTo(var_3_2)
	arg_3_0.awardList:onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	local var_3_5 = {
		activity = arg_3_1,
		list = arg_3_0.awardList,
		count = arg_3_2
	}

	arg_3_0:addActivityAwardList(var_3_5)
end

function var_0_0.createAwardList(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.list
	local var_4_1 = arg_4_1.activity
	local var_4_2 = arg_4_1.listNum
	local var_4_3 = arg_4_1.count

	var_4_0:removeAllItems()

	for iter_4_0 = 1, var_4_2 do
		if arg_4_0:checkInitItem(iter_4_0, arg_4_1) then
			local var_4_4 = var_4_0:newItem()
			local var_4_5 = display.newNode()
			local var_4_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1054/activity_item.csb")
			local var_4_7 = var_4_6:getChildByName("container")

			arg_4_0:rewardItemLayout(var_4_1, var_4_7, var_4_3, iter_4_0)
			var_4_6:addTo(var_4_5)
			var_4_6:setTouchEnabled(true)
			var_4_6:setAnchorPoint(cc.p(0, 0))
			var_4_6:setPosition(0, 5)
			var_4_6:setTouchSwallowEnabled(false)
			var_4_5:setContentSize(667, 171)
			var_4_4:addContent(var_4_5)
			var_4_4:setItemSize(667, 171)
			var_4_0:addItem(var_4_4)
		end
	end

	var_4_0:reload()

	if arg_4_0.scrollNodePosX and arg_4_0.scrollNodePosY then
		var_4_0.scrollNode:setPosition(arg_4_0.scrollNodePosX, arg_4_0.scrollNodePosY)
	end
end

function var_0_0.addActivityAwardList(arg_5_0, arg_5_1)
	local var_5_0 = xyd.tables.activities:tableName(arg_5_1.activity.table_id)

	if var_5_0 and var_5_0 ~= "" then
		arg_5_1.listNum = #import("app.common.tables." .. var_5_0).new():gifts()
		arg_5_1.obtainStates = xyd.luaStringSplit(arg_5_1.activity.details.is_awards, "|")

		if not arg_5_1.listNum then
			return
		else
			arg_5_0:createAwardList(arg_5_1)
		end
	end
end

function var_0_0.rewardItemLayout(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	local var_6_0 = arg_6_2:getChildByName("btn")
	local var_6_1 = arg_6_2:getChildByName("yilingqu")
	local var_6_2 = arg_6_2:getChildByName("lingqu")
	local var_6_3 = arg_6_2:getChildByName("get_gray")
	local var_6_4 = arg_6_2:getChildByName("expired")
	local var_6_5 = arg_6_2:getChildByName("not_begin")
	local var_6_6 = {
		btn = var_6_0,
		alreadyObtain = var_6_1,
		obtain_bright = var_6_2,
		obtain_gray = var_6_3,
		expired = var_6_4,
		notBegin = var_6_5
	}
	local var_6_7 = arg_6_2:getChildByName("reward_container")
	local var_6_8 = arg_6_2:getChildByName("item_title_container")

	arg_6_0:formatStateText(var_6_6)

	local var_6_9 = {
		color = cc.c3b(255, 255, 255)
	}

	var_6_9.size = 20

	local var_6_10 = xyd.AssetLoader.get():loadLabel(var_6_9)

	var_6_10:setMaxLineWidth(280)
	var_6_10:addTo(var_6_8)
	var_6_10:setAnchorPoint(cc.p(0, 0))
	var_6_10:setPosition(0, 0)

	local var_6_11 = xyd.tables.activityKiteLogin:name(arg_6_4)

	var_6_10:setString(var_6_11)

	local var_6_12 = xyd.ServerTime.get():getServerTime()

	if arg_6_4 <= arg_6_0.activities[arg_6_3].details.award_count then
		arg_6_0:setBtnGetState(0, var_6_6)
	elseif arg_6_4 > arg_6_0.activities[arg_6_3].details.award_count + 1 then
		arg_6_0:setBtnGetState(-1, var_6_6)
	elseif arg_6_4 == arg_6_0.activities[arg_6_3].details.award_count + 1 and arg_6_0.activities[arg_6_3].details.is_awarded == 1 then
		arg_6_0:setBtnGetState(-1, var_6_6)
	elseif arg_6_4 == arg_6_0.activities[arg_6_3].details.award_count + 1 and arg_6_0.activities[arg_6_3].details.is_awarded == 0 then
		arg_6_0:setBtnGetState(1, var_6_6)
	end

	local var_6_13 = xyd.tables.activityKiteLogin:name(arg_6_4)

	var_6_10:setString(var_6_13)
	arg_6_0:rewardFormat(var_6_7, xyd.tables.activityKiteLogin:gift(arg_6_4))

	if not arg_6_0:checkTime(arg_6_1) then
		arg_6_0:setBtnGetState(-1, var_6_6)
	end

	if var_6_12 < arg_6_1.start_time then
		arg_6_0:setBtnGetState(-2, var_6_6)
	end

	var_6_0:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_6_1.details.can_award == 1 and arg_6_1.details.is_awarded == 0 then
				arg_6_0.scrollNodePosX = arg_6_0.awardList.scrollNode:getPositionX()
				arg_6_0.scrollNodePosY = arg_6_0.awardList.scrollNode:getPositionY()

				arg_6_0.activitiesModel:getActivityReward(arg_6_1.table_id, nil, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_6_0.player:handleRewards(arg_8_1.awards)
						arg_6_0:setBtnGetState(0, var_6_6)

						if arg_6_0.activities[arg_6_3].details.is_awarded then
							arg_6_0.activities[arg_6_3].details.is_awarded = 1
						end

						arg_6_0.activitiesModel:clearRedMarkState(arg_6_1.table_id, 2)

						if arg_6_0.activities[arg_6_3].details.award_count then
							arg_6_0.activities[arg_6_3].details.award_count = arg_6_0.activities[arg_6_3].details.award_count + 1
						end

						if arg_6_0.activities[arg_6_3].details.is_awards then
							local var_8_0 = xyd.luaStringSplit(arg_6_0.activities[arg_6_3].details.is_awards, "|")

							var_8_0[arg_6_4] = "1"

							local var_8_1 = xyd.luaStringMerge(var_8_0, "|")

							arg_6_0.activities[arg_6_3].details.is_awards = var_8_1
						end

						arg_6_0:layout(arg_6_0.activities[arg_6_3], arg_6_0.idx)

						local var_8_2 = xyd.WindowManager.get():getWindow("activities")

						if var_8_2 then
							var_8_2:rightLayout()
						end
					end
				end)
			else
				local var_7_0 = var_0_1:translation("ACTIVITY_HAVE_GET_REWARD")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})
			end
		end
	end)
end

function var_0_0.checkInitItem(arg_9_0, arg_9_1, arg_9_2)
	return true
end

return var_0_0
