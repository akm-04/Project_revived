local var_0_0 = class("Activity", import("app.windows.activities.ActivityNormal"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	arg_2_0:layout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.parent:removeAllChildren()

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1048/normal_activity.csb")

	var_3_0:addTo(arg_3_0.parent)

	local var_3_1 = var_3_0:getChildByName("bg_desc"):getChildByName("txt")

	var_3_1:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_3_1:setString(xyd.tables.activities:desc(arg_3_1.table_id))

	local var_3_2 = arg_3_1.details.day_count
	local var_3_3 = arg_3_1.details.award_count
	local var_3_4 = xyd.AssetLoader.get():loadLabel(nil, "activity_common")

	var_3_4:setString(var_3_3)
	var_3_4:setScale(1)
	var_3_4:setPosition(var_3_0:getChildByName("day_pos"):getPosition())
	var_3_4:addTo(var_3_0)

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 572, 310),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	})

	arg_3_0.awardList:addTo(var_3_0:getChildByName("container"):getChildByName("list"))
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

	if arg_4_1.type then
		var_4_0:removeAllItems()
	end

	for iter_4_0 = 1, var_4_2 do
		if arg_4_0:checkInitItem(iter_4_0, arg_4_1) then
			local var_4_4 = var_4_0:newItem()
			local var_4_5 = display.newNode()
			local var_4_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/common/award_item.csb")
			local var_4_7 = var_4_6:getChildByName("container")

			arg_4_0:rewardItemLayout(var_4_1, var_4_7, var_4_3, iter_4_0)
			var_4_6:addTo(var_4_5)
			var_4_6:setTouchEnabled(true)
			var_4_6:setAnchorPoint(cc.p(0, 0))
			var_4_6:setPosition(0, 0)
			var_4_6:setTouchSwallowEnabled(false)
			var_4_5:setContentSize(572, 160)
			var_4_4:addContent(var_4_5)
			var_4_4:setItemSize(572, 160)
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
	local var_6_0 = xyd.tables.activitySakuraLogin:name(arg_6_4)

	arg_6_2:getChildByName("desc"):setString(var_6_0)
	arg_6_2:getChildByName("desc"):enableOutline(cc.c4b(204, 24, 18, 255), 2)

	local var_6_1 = arg_6_2:getChildByName("btn")

	var_6_1:getChildByName("txt"):setString(var_0_1:translation("OBTAIN"))

	local var_6_2 = xyd.ServerTime.get():getServerTime()

	if arg_6_4 <= arg_6_1.details.award_count then
		var_6_1:setVisible(false)
		arg_6_2:getChildByName("already_get"):setVisible(true)
	elseif arg_6_4 > arg_6_1.details.award_count + 1 then
		var_6_1:setTouchEnabled(false)
		var_6_1:setBright(false)
	elseif arg_6_4 == arg_6_1.details.award_count + 1 then
		-- block empty
	end

	arg_6_0:rewardFormat(arg_6_2:getChildByName("award_container"), xyd.tables.activitySakuraLogin:gift(arg_6_4))

	if not arg_6_0:checkTime(arg_6_1) then
		var_6_1:setTouchEnabled(false)
		var_6_1:setBright(false)
	end

	if var_6_2 < arg_6_1.start_time then
		var_6_1:setTouchEnabled(false)
		var_6_1:setBright(false)
	end

	var_6_1:addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_6_1, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			if arg_6_1.details.can_award == 1 and arg_6_1.details.is_awarded == 0 then
				arg_6_0.scrollNodePosX = arg_6_0.awardList.scrollNode:getPositionX()
				arg_6_0.scrollNodePosY = arg_6_0.awardList.scrollNode:getPositionY()

				arg_6_0.activitiesModel:getActivityReward(arg_6_1.table_id, nil, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_6_0.player:handleRewards(arg_8_1.awards)
						var_6_1:setVisible(false)
						arg_6_2:getChildByName("already_get"):setVisible(true)
						arg_6_0.activitiesModel:clearRedMarkState(arg_6_1.table_id, 2)

						arg_6_0.activity.details.is_awarded = 1
						arg_6_0.activity.details.award_count = (arg_6_0.activity.details.award_count or 0) + 1

						if arg_6_0.activity.details.is_awards then
							local var_8_0 = xyd.luaStringSplit(arg_6_0.activity.details.is_awards, "|")

							var_8_0[arg_6_4] = "1"

							local var_8_1 = xyd.luaStringMerge(var_8_0, "|")

							arg_6_0.activity.details.is_awards = var_8_1
						end

						arg_6_0:layout(arg_6_0.activity, arg_6_0.idx)

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
