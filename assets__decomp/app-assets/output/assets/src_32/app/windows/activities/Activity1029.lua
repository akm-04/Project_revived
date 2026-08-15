local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	local function var_2_0(arg_3_0)
		arg_3_0:getChildByName("hour_text"):hide()
		arg_3_0:getChildByName("btn"):hide()
		arg_3_0:getChildByName("lingqu"):hide()
		arg_3_0:getChildByName("hasget_pic"):hide()
		arg_3_0:getChildByName("notget_pic"):show()
		arg_3_0:getChildByName("yilingqu"):show()
	end

	arg_2_0.onlineActivity = arg_2_0.activity
	arg_2_0.onlineDetails = arg_2_0.onlineActivity.details

	local var_2_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1029/1029.csb")

	var_2_1:addTo(arg_2_0.parent)
	var_2_1:setAnchorPoint(cc.p(0, 0))
	var_2_1:setPosition(0, 0)

	local var_2_2 = var_2_1:getChildByName("container")

	var_2_2:getChildByName("title_list"):getChildByName("online_content"):setString(var_0_1:translation("ONLINE_REWARD_EXPLAIN"))

	local var_2_3 = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, 670, 370),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_2_2:getChildByName("award_list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.onlineType = xyd.tables.activityOnlineReward:all()
	arg_2_0.container = {}

	if not arg_2_0.myOnlineCount then
		arg_2_0.myOnlineCount = arg_2_0.onlineDetails.gift_times
		arg_2_0.myAwardtime = arg_2_0.onlineDetails.award_time
	end

	for iter_2_0 = 1, #arg_2_0.onlineType do
		local var_2_4 = xyd.tables.activityOnlineReward:getGift(iter_2_0)
		local var_2_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1029/1029_item.csb")
		local var_2_6 = var_2_5:getChildByName("container")

		table.insert(arg_2_0.container, var_2_6)

		local var_2_7 = xyd.tables.activityOnlineReward:name(iter_2_0)
		local var_2_8 = var_2_6:getChildByName("item_title_container")
		local var_2_9 = {
			color = cc.c3b(255, 238, 243)
		}

		var_2_9.size = 24

		local var_2_10 = xyd.AssetLoader.get():loadLabel(var_2_9)

		var_2_10:setString(var_2_7)
		var_2_10:setMaxLineWidth(280)
		var_2_10:addTo(var_2_8)
		var_2_10:setAnchorPoint(cc.p(0, 0))
		var_2_10:setPosition(0, 0)
		arg_2_0:rewardFormat(var_2_6:getChildByName("reward_container"), tonumber(var_2_4), arg_2_0.activity)
		var_2_6:getChildByName("not_begin"):hide()
		var_2_6:getChildByName("yilingqu"):hide()
		var_2_6:getChildByName("get_gray"):hide()
		var_2_6:getChildByName("expired"):hide()
		var_2_6:getChildByName("item_bg"):hide()

		local var_2_11 = arg_2_0.myOnlineCount
		local var_2_12 = arg_2_0.myAwardtime
		local var_2_13 = xyd.ServerTime.get():getServerTime()

		if arg_2_0.activity.is_open == 0 then
			var_2_6:getChildByName("not_begin"):show()
			var_2_6:getChildByName("lingqu"):hide()
			var_2_6:getChildByName("btn"):setTouchEnabled(false)
			var_2_6:getChildByName("btn"):setBright(false)
		else
			local var_2_14 = tonumber(xyd.tables.activityOnlineReward:getOnlineTime(var_2_11 + 1)) - (var_2_13 - var_2_12)

			if iter_2_0 < var_2_11 + 1 then
				var_2_0(var_2_6)
			elseif iter_2_0 == var_2_11 + 1 then
				if var_2_14 > 0 then
					var_2_6:getChildByName("hour_text"):show()
					var_2_6:getChildByName("btn"):hide()
					var_2_6:getChildByName("lingqu"):hide()
					var_2_6:getChildByName("notget_pic"):hide()
					var_2_6:getChildByName("hasget_pic"):show()

					arg_2_0.TimeLabel_ = var_2_6:getChildByName("hour_text"):show()

					arg_2_0.TimeLabel_:setVisible(true)
					arg_2_0.TimeLabel_:setContentSize(200, 70)

					if arg_2_0.countDown_ then
						arg_2_0.countDown_:stop()
					end

					arg_2_0:OnlineCountDown(var_2_14)
				else
					var_2_6:getChildByName("not_begin"):hide()
					var_2_6:getChildByName("hour_text"):hide()
					var_2_6:getChildByName("btn"):setTouchEnabled(true)
					var_2_6:getChildByName("btn"):setBright(true)
					var_2_6:getChildByName("btn"):show()
					var_2_6:getChildByName("lingqu"):show()
					var_2_6:getChildByName("hasget_pic"):hide()
					var_2_6:getChildByName("notget_pic"):show()
				end
			else
				var_2_6:getChildByName("hour_text"):hide()
				var_2_6:getChildByName("btn"):hide()
				var_2_6:getChildByName("hasget_pic"):show()
				var_2_6:getChildByName("lingqu"):hide()
				var_2_6:getChildByName("notget_pic"):hide()
			end
		end

		local var_2_15 = display.newNode()
		local var_2_16 = var_2_6:getWidth()
		local var_2_17 = var_2_6:getHeight()

		var_2_15:setContentSize(var_2_16, var_2_17)
		var_2_5:addTo(var_2_15)
		var_2_15:setAnchorPoint(cc.p(0, 1))

		local var_2_18 = var_2_3:newItem()

		var_2_18:addContent(var_2_15)
		var_2_18:setItemSize(var_2_16, var_2_17 + 20)
		var_2_3:addItem(var_2_18)
	end

	var_2_3:reload()
	arg_2_0:isGetOnlineActivity()
end

function var_0_0.isGetOnlineActivity(arg_4_0)
	for iter_4_0 = 1, #arg_4_0.onlineType do
		local var_4_0 = xyd.tables.activityOnlineReward:getGift(iter_4_0)

		arg_4_0.container[iter_4_0]:getChildByName("btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_4_0.activitiesModel:getActivityReward(arg_4_0.onlineActivity.table_id, var_4_0, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_4_0.player:handleRewards(arg_6_1.awards)

						arg_4_0.activitiesModel.activities[arg_4_0.idx].details.gift_times = arg_6_1.gift_times
						arg_4_0.activitiesModel.activities[arg_4_0.idx].details.award_time = arg_6_1.award_time

						arg_4_0:refreshRedPoint()

						local var_6_0 = arg_6_1.gift_times + 1

						if var_6_0 <= #arg_4_0.onlineType then
							local var_6_1 = tonumber(xyd.tables.activityOnlineReward:getOnlineTime(var_6_0))

							arg_4_0.TimeLabel_ = arg_4_0.container[iter_4_0 + 1]:getChildByName("hour_text")

							arg_4_0.TimeLabel_:setVisible(true)
							arg_4_0:OnlineCountDown(var_6_1)
							arg_4_0.container[iter_4_0 + 1]:getChildByName("hour_text"):show()
						end

						arg_4_0.myOnlineCount = arg_4_0.myOnlineCount + 1
						arg_4_0.myAwardtime = arg_6_1.award_time
						arg_4_0.myServerTime = arg_6_1.server_time

						arg_4_0.container[iter_4_0]:getChildByName("lingqu"):hide()
						arg_4_0.container[iter_4_0]:getChildByName("yilingqu"):show()
						arg_4_0.container[iter_4_0]:getChildByName("hasget_pic"):hide()
						arg_4_0.container[iter_4_0]:getChildByName("btn"):hide()
						arg_4_0.container[iter_4_0]:getChildByName("notget_pic"):show()

						if arg_4_0.Effect then
							arg_4_0.Effect:setVisible(false)
						end
					end
				end)
			end
		end)
	end
end

function var_0_0.OnlineCountDown(arg_7_0, arg_7_1)
	arg_7_0.countDown_ = import("app.common.CountDown").new(arg_7_1)

	arg_7_0:updateCountDownLabel(arg_7_1)
	arg_7_0.countDown_:start(handler(arg_7_0, arg_7_0.updateCountDownLabel))
end

function var_0_0.updateCountDownLabel(arg_8_0, arg_8_1)
	local var_8_0 = math.floor(arg_8_1 / 3600)
	local var_8_1 = math.floor(arg_8_1 % 3600 / 60)
	local var_8_2 = arg_8_1 % 60
	local var_8_3 = tostring(var_8_0) .. ":"

	if var_8_1 < 10 then
		var_8_3 = var_8_3 .. "0"
	end

	local var_8_4 = var_8_3 .. tostring(var_8_1) .. ":"

	if var_8_2 < 10 then
		var_8_4 = var_8_4 .. "0"
	end

	local var_8_5 = var_8_4 .. tostring(var_8_2)

	if arg_8_0.TimeLabel_ ~= nil and not tolua.isnull(arg_8_0.TimeLabel_) then
		arg_8_0.TimeLabel_:setString(var_0_1:translation("COUNT_DOWN") .. "\n" .. var_8_5)
		arg_8_0.TimeLabel_:setFontSize(24)

		if arg_8_1 <= 0 then
			arg_8_0:checkTime_(arg_8_0.container[arg_8_0.myOnlineCount + 1])
		end
	end
end

function var_0_0.checkTime_(arg_9_0, arg_9_1)
	arg_9_1:getChildByName("hour_text"):hide()
	arg_9_1:getChildByName("btn"):show()
	arg_9_1:getChildByName("lingqu"):show()
	arg_9_1:getChildByName("hasget_pic"):show()
	arg_9_1:getChildByName("notget_pic"):hide()
end

function var_0_0.rewardFormat(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_1:getContentSize().height
	local var_10_1 = var_10_0 / 4
	local var_10_2 = xyd.tables.gift:items(arg_10_2)

	if #var_10_2 == 1 and var_10_2[1] == 0 then
		var_10_2 = {}
	end

	local var_10_3 = xyd.tables.gift:itemNum(arg_10_2)
	local var_10_4 = #var_10_2

	for iter_10_0 = 1, #var_10_2 do
		local var_10_5 = display.newNode()

		var_10_5:setContentSize(var_10_0, var_10_0)

		if xyd.tables.item:type(var_10_2[iter_10_0]) == -1 then
			xyd.setAvatarBorder(var_10_2[iter_10_0], var_10_5, 1, xyd.tables.hero:initialStar(var_10_2[iter_10_0]))
		else
			xyd.setItemBorder(var_10_5, var_10_2[iter_10_0], false, false, var_10_3[iter_10_0])
		end

		var_10_5:addTo(arg_10_1)
		var_10_5:setAnchorPoint(cc.p(0, 0))
		var_10_5:setPosition((iter_10_0 - 1) * (var_10_0 + var_10_1), 0)

		local var_10_6 = {
			id = var_10_2[iter_10_0],
			lev = xyd.tables.item:level(var_10_2[iter_10_0])
		}

		if xyd.tables.item:type(var_10_2[iter_10_0]) == -1 then
			var_10_6.tipsType = 0
			var_10_6.desc1 = xyd.tables.hero:getDes(var_10_2[iter_10_0])
		elseif specialItem then
			var_10_6.tipsType = 1
			var_10_6.id = -3
		else
			var_10_6.tipsType = 1
			var_10_6.desc1 = xyd.tables.item:desc1(var_10_2[iter_10_0])
			var_10_6.desc2 = xyd.tables.item:desc2(var_10_2[iter_10_0])
		end

		var_10_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_10_2[iter_10_0])
		var_10_6.name = xyd.tables.item:name(var_10_2[iter_10_0])

		arg_10_0:addTips(var_10_5, var_10_6)
	end

	local var_10_7 = xyd.tables.gift:crystal(arg_10_2)

	if var_10_7 and var_10_7 > 0 then
		local var_10_8 = display.newNode()

		var_10_8:setContentSize(var_10_0, var_10_0)
		xyd.setItemBorder(var_10_8, -1, false, false, var_10_7)
		var_10_8:addTo(arg_10_1)
		var_10_8:setAnchorPoint(cc.p(0, 0))
		var_10_8:setPosition(var_10_4 * (var_10_0 + var_10_1), 0)

		local var_10_9 = {}

		var_10_9.id = -1
		var_10_9.tipsType = 1

		arg_10_0:addTips(var_10_8, var_10_9)

		var_10_4 = var_10_4 + 1
	end

	local var_10_10 = xyd.tables.gift:mana(arg_10_2)

	if var_10_10 and var_10_10 > 0 then
		local var_10_11 = display.newNode()

		var_10_11:setContentSize(var_10_0, var_10_0)
		xyd.setItemBorder(var_10_11, -2, false, false, var_10_10)
		var_10_11:addTo(arg_10_1)
		var_10_11:setAnchorPoint(cc.p(0, 0))
		var_10_11:setPosition(var_10_4 * (var_10_0 + var_10_1), 0)

		local var_10_12 = {}

		var_10_12.id = -2
		var_10_12.tipsType = 1

		arg_10_0:addTips(var_10_11, var_10_12)

		var_10_4 = var_10_4 + 1
	end

	local var_10_13 = xyd.tables.gift:drops(arg_10_2)
	local var_10_14 = false

	if var_10_13 and next(var_10_13) then
		var_10_14 = #var_10_13 ~= 1 or var_10_13[1] ~= 0
	end

	if var_10_14 and arg_10_3 and arg_10_3.table_id == xyd.Activities.OnlineReward then
		local var_10_15 = display.newNode()

		var_10_15:addTo(arg_10_1)
		var_10_15:setAnchorPoint(cc.p(0, 0))
		var_10_15:setPosition(var_10_4 * (var_10_0 + var_10_1), 0)
		var_10_15:setContentSize(var_10_0, var_10_0)

		local var_10_16 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_10_16 then
			local var_10_17 = var_10_15:getWidth()
			local var_10_18 = var_10_15:getHeight()
			local var_10_19 = var_10_17 / var_10_16:getWidth()

			var_10_16:setScale(var_10_19)
			var_10_16:addTo(var_10_15)
			var_10_16:setAnchorPoint(cc.p(0.5, 0.5))
			var_10_16:setPosition(var_10_17 / 2, var_10_18 / 2)

			local var_10_20 = xyd.getBorder(0, false)

			xyd.displaySpriteOnContainer(var_10_20, var_10_15, true)
		end

		local var_10_21 = {}

		var_10_21.id = -3
		var_10_21.tipsType = 1

		arg_10_0:addTips(var_10_15, var_10_21)

		local var_10_22 = var_10_4 + 1
	end

	return arg_10_1
end

function var_0_0.release(arg_11_0)
	if arg_11_0.countDown_ then
		arg_11_0.countDown_:stop()
	end
end

return var_0_0
