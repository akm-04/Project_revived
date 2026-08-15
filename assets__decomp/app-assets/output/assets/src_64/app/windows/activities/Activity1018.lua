local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0:pointActivitiesLayout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.pointActivitiesLayout(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/normal_activity.csb")

	var_3_0:addTo(arg_3_0.parent)

	local var_3_1, var_3_2 = var_3_0:getChildByName("container"):getChildByName("title_pos"):getPosition()
	local var_3_3 = var_3_0:getChildByName("container"):getChildByName("list")
	local var_3_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 665, 500),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_3):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
	local var_3_5 = xyd.tables.activities:title(arg_3_1.table_id)
	local var_3_6 = xyd.AssetLoader.get():loadSprite(var_3_5)

	var_3_6:addTo(var_3_0:getChildByName("container"))
	var_3_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_6:setPosition(var_3_1, var_3_2)

	local var_3_7 = var_3_4:newItem()
	local var_3_8 = display.newNode()
	local var_3_9 = {
		color = cc.c3b(255, 236, 80)
	}

	var_3_9.size = 24

	local var_3_10 = xyd.AssetLoader.get():loadLabel(var_3_9)

	var_3_10:setMaxLineWidth(580)
	var_3_10:setString(xyd.tables.activities:desc(arg_3_1.table_id))
	var_3_10:addTo(var_3_8)
	var_3_10:setAnchorPoint(cc.p(0, 0))
	var_3_10:setPosition(33, 0)
	var_3_8:setContentSize(665, var_3_10:getContentSize().height)
	var_3_7:addContent(var_3_8)
	var_3_7:setItemSize(665, var_3_10:getContentSize().height)
	var_3_4:addItem(var_3_7)

	local var_3_11 = var_3_4:newItem()
	local var_3_12 = display.newNode()
	local var_3_13 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/normal_item_detail.csb")

	var_3_13:addTo(var_3_12)
	var_3_13:setAnchorPoint(cc.p(0, 0))
	var_3_13:setPosition(0, 0)

	local var_3_14 = var_3_13:getChildByName("container"):getChildByName("time_txt")

	var_3_13:getChildByName("container"):getChildByName("activity_time_txt"):setString(var_0_1:translation("ACTIVITY_TIME"))

	local var_3_15 = xyd.ServerTime.get():getServerTime()

	if arg_3_1.details.day_count > 7 then
		var_3_14:setString(var_0_1:translation("EARN_POINT_FINISHED"))
	else
		var_3_14:setString(string.format(var_0_1:translation("EARN_POINT_LEFTTIME"), 8 - arg_3_1.details.day_count))
	end

	var_3_12:setContentSize(665, 55)
	var_3_11:addContent(var_3_12)
	var_3_11:setItemSize(665, 55)
	var_3_4:addItem(var_3_11)

	local var_3_16 = var_3_4:newItem()
	local var_3_17 = display.newNode()
	local var_3_18 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/point_detail.csb")

	var_3_18:addTo(var_3_17)
	var_3_18:setAnchorPoint(cc.p(0, 0))
	var_3_18:setPosition(0, 0)

	local var_3_19 = var_3_18:getChildByName("container"):getChildByName("today_point_num")
	local var_3_20 = var_3_18:getChildByName("container"):getChildByName("left_point_num")

	var_3_18:getChildByName("container"):getChildByName("today_point_txt"):setString(var_0_1:translation("ACTIVITY_EARN_POINT"))
	var_3_18:getChildByName("container"):getChildByName("left_point_txt"):setString(var_0_1:translation("ACTIVITY_LEFT_POINT"))
	var_3_19:setString(arg_3_1.details.daily_integral)
	var_3_20:setString(arg_3_1.details.integral)

	if var_3_15 >= arg_3_1.details.end_time then
		var_3_18:getChildByName("container"):getChildByName("gain_point_btn"):setVisible(false)
	else
		var_3_18:getChildByName("container"):getChildByName("gain_point_btn"):setVisible(true)
	end

	var_3_18:getChildByName("container"):getChildByName("gain_point_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = {
				count = arg_3_2,
				activity = arg_3_1
			}

			xyd.WindowManager.get():openWindow("get_point_window", var_4_0)
		end
	end)
	var_3_17:setContentSize(665, 55)
	var_3_16:addContent(var_3_17)
	var_3_16:setItemSize(665, 55)
	var_3_4:addItem(var_3_16)

	local var_3_21 = var_3_4:newItem()
	local var_3_22 = display.newNode()

	var_3_22:setContentSize(665, 20)
	var_3_21:addContent(var_3_22)
	var_3_21:setItemSize(665, 20)
	var_3_4:addItem(var_3_21)
	var_3_4:reload()

	local var_3_23 = {
		activity = arg_3_1,
		list = var_3_4,
		count = arg_3_2,
		leftPoint = var_3_20
	}

	arg_3_0:createPointAwardList(var_3_23)
end

function var_0_0.createPointAwardList(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.list
	local var_5_1 = arg_5_1.activity
	local var_5_2 = arg_5_1.leftPoint
	local var_5_3 = var_5_1.details.award_ids
	local var_5_4 = var_5_1.details.exchange_nums
	local var_5_5 = arg_5_1.count

	for iter_5_0 = 1, #var_5_3 do
		local var_5_6 = var_5_0:newItem()
		local var_5_7 = display.newNode()
		local var_5_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/point_item.csb")
		local var_5_9 = var_5_8:getChildByName("container")
		local var_5_10 = var_5_9:getChildByName("item_title_container")
		local var_5_11 = var_5_9:getChildByName("reward_container")
		local var_5_12 = {
			color = cc.c3b(255, 255, 255)
		}

		var_5_12.size = 20

		local var_5_13 = xyd.AssetLoader.get():loadLabel(var_5_12)

		var_5_13:setMaxLineWidth(280)
		var_5_13:addTo(var_5_10)
		var_5_13:setAnchorPoint(cc.p(0, 0))
		var_5_13:setPosition(10, 3)
		var_5_13:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		local var_5_14 = var_5_9:getChildByName("btn")
		local var_5_15 = var_5_9:getChildByName("has_exchanged")
		local var_5_16 = var_5_9:getChildByName("exchange_txt")
		local var_5_17 = var_5_9:getChildByName("exchange_gray")
		local var_5_18 = var_5_9:getChildByName("not_begin")
		local var_5_19 = var_5_9:getChildByName("buy_one_txt")
		local var_5_20 = var_5_9:getChildByName("buy_one_gray")
		local var_5_21 = var_5_9:getChildByName("need_point_txt")
		local var_5_22 = var_5_9:getChildByName("open_time_txt")
		local var_5_23 = xyd.tables.activityPoint:beginDay(var_5_3[iter_5_0])

		var_5_21:setString(string.format(var_0_1:translation("NEED_POINT"), xyd.tables.activityPoint:point(var_5_3[iter_5_0])))
		var_5_22:setString(string.format(var_0_1:translation("OPEN_EXCHANGE_ON_DAY"), var_5_23 - var_5_1.details.day_count))

		local var_5_24 = xyd.tables.activityPoint:exchangeLimit(var_5_3[iter_5_0])

		if var_5_23 <= var_5_1.details.day_count then
			var_5_21:setPosition(var_5_9:getChildByName("need_point_pos2"):getPosition())
			var_5_22:setVisible(false)
			arg_5_0:updatePointBtn(var_5_9, iter_5_0, var_5_4, var_5_3)
		else
			var_5_21:setPosition(var_5_9:getChildByName("need_point_pos1"):getPosition())
			var_5_22:setVisible(true)
			var_5_15:setVisible(false)
			var_5_16:setVisible(false)
			var_5_17:setVisible(false)
			var_5_18:setVisible(true)
			var_5_19:setVisible(false)
			var_5_20:setVisible(false)
			var_5_14:setVisible(true)
			var_5_14:setTouchEnabled(false)
			var_5_14:setBright(false)
		end

		local var_5_25 = xyd.tables.activityPoint:name(var_5_3[iter_5_0])

		var_5_13:setString(var_5_25)
		arg_5_0:rewardFormat(var_5_11, xyd.tables.activityPoint:gift(var_5_3[iter_5_0]))
		var_5_14:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				if var_5_1.details.integral < xyd.tables.activityPoint:point(var_5_3[iter_5_0]) then
					local var_6_0 = var_0_1:translation("POINT_NOT_ENOUGH")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_6_0
					})

					return
				end

				local var_6_1 = var_5_3[iter_5_0]

				arg_5_0.activitiesModel:getActivityReward(var_5_1.table_id, var_6_1, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						arg_5_0.player:handleRewards(arg_7_1.awards)
						arg_5_0.activitiesModel:clearRedMarkState(var_5_1.table_id, 2)

						var_5_1.details.exchange_nums[iter_5_0] = var_5_1.details.exchange_nums[iter_5_0] + 1
						var_5_1.details.integral = var_5_1.details.integral - xyd.tables.activityPoint:point(var_5_3[iter_5_0])

						var_5_2:setString(var_5_1.details.integral)

						arg_5_0.activities[var_5_5] = var_5_1

						local var_7_0 = var_5_1.details.exchange_nums
						local var_7_1 = var_5_1.details.award_ids

						arg_5_0:updatePointBtn(var_5_9, iter_5_0, var_7_0, var_7_1)
					end
				end)
			end
		end)
		var_5_8:addTo(var_5_7)
		var_5_8:setTouchEnabled(true)
		var_5_8:setAnchorPoint(cc.p(0, 0))
		var_5_8:setPosition(0, 0)
		var_5_8:setTouchSwallowEnabled(false)
		var_5_7:setContentSize(665, 148)
		var_5_6:addContent(var_5_7)
		var_5_6:setItemSize(665, 148)
		var_5_0:addItem(var_5_6)
	end

	var_5_0:reload()
end

function var_0_0.updatePointBtn(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = xyd.tables.activityPoint:exchangeLimit(arg_8_4[arg_8_2])
	local var_8_1 = arg_8_1:getChildByName("btn")
	local var_8_2 = arg_8_1:getChildByName("has_exchanged")
	local var_8_3 = arg_8_1:getChildByName("exchange_txt")
	local var_8_4 = arg_8_1:getChildByName("exchange_gray")
	local var_8_5 = arg_8_1:getChildByName("not_begin")
	local var_8_6 = arg_8_1:getChildByName("buy_one_txt")
	local var_8_7 = arg_8_1:getChildByName("buy_one_gray")

	if var_8_0 > 1 and var_8_0 <= arg_8_3[arg_8_2] then
		var_8_2:setVisible(true)
		var_8_3:setVisible(false)
		var_8_4:setVisible(false)
		var_8_5:setVisible(false)
		var_8_6:setVisible(false)
		var_8_7:setVisible(false)
		var_8_1:setVisible(false)
		var_8_1:setTouchEnabled(false)
		var_8_1:setBright(false)
	elseif var_8_0 == 1 then
		if tonumber(arg_8_3[arg_8_2]) == var_8_0 then
			var_8_2:setVisible(true)
			var_8_3:setVisible(false)
			var_8_4:setVisible(false)
			var_8_5:setVisible(false)
			var_8_6:setVisible(false)
			var_8_7:setVisible(false)
			var_8_1:setVisible(false)
			var_8_1:setTouchEnabled(false)
			var_8_1:setBright(false)
		else
			var_8_2:setVisible(false)
			var_8_3:setVisible(false)
			var_8_4:setVisible(false)
			var_8_5:setVisible(false)
			var_8_6:setVisible(true)
			var_8_7:setVisible(false)
			var_8_1:setVisible(true)
			var_8_1:setTouchEnabled(true)
			var_8_1:setBright(true)
		end
	else
		var_8_2:setVisible(false)
		var_8_3:setVisible(true)
		var_8_4:setVisible(false)
		var_8_5:setVisible(false)
		var_8_6:setVisible(false)
		var_8_7:setVisible(false)
		var_8_1:setVisible(true)
		var_8_1:setTouchEnabled(true)
		var_8_1:setBright(true)
	end
end

return var_0_0
