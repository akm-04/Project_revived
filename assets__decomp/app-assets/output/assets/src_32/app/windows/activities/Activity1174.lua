local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.chargeList

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	arg_2_0.details = arg_2_0.activity.details

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setPosition(8, 5)

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.charge_id = 80008801
	arg_2_0.buyEndTime = xyd.tables.misc.activityDongYunSouvenirDay * 60 * 60 * 24 + arg_2_0.activity.start_time

	arg_2_0:layout(arg_2_0.activity, arg_2_0.idx)
end

function var_0_0.layout(arg_3_0, arg_3_1, arg_3_2)
	if not arg_3_0.res or arg_3_0.res == 0 then
		print("No res available.")

		return
	end

	local var_3_0 = arg_3_0.container:getChildByName("list")
	local var_3_1 = tonumber(arg_3_0.charge_id)
	local var_3_2 = arg_3_0.container:getChildByName("btn")
	local var_3_3 = xyd.ServerTime.get():getServerTime()
	local var_3_4 = arg_3_0.buyEndTime - xyd.ServerTime.get():getServerTime()
	local var_3_5 = arg_3_0.activity.end_time - xyd.ServerTime.get():getServerTime()
	local var_3_6 = arg_3_0.activity.end_time - arg_3_0.activity.start_time
	local var_3_7 = arg_3_0.details.is_buy

	if var_3_7 == 1 or var_3_4 < 0 then
		var_3_2:setBright(false)
	else
		var_3_2:setBright(true)
		var_3_2:setTouchEnabled(true)
	end

	var_3_2:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_2, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			if var_3_4 < 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_DONGYUN_SOUVENIR_DAY_END")
				})

				return
			elseif var_3_7 == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_DONGYUN_SOUVENIR_HAVE_BOUGHT")
				})

				return
			elseif var_3_5 > var_3_6 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("KITE_NOT_OPEN")
				})

				return
			end

			arg_3_0:purchaseGiftBag(var_3_1)
			xyd.WindowManager.get():closeWindow("activities")
		end
	end)

	local var_3_8 = arg_3_0.container:getChildByName("before_txt")
	local var_3_9 = xyd.tables.translation:translation("ACTIVITY_DONGYUN_BEFORE")
	local var_3_10 = xyd.tables.translation:translation("ACTIVITY_DONGYUN_NOW")
	local var_3_11 = var_0_3:originalCharge(arg_3_0.charge_id)

	var_3_8:setString(var_3_9 .. tostring(var_3_11) .. "USD")

	local var_3_12 = var_3_2:getChildByName("now_price")
	local var_3_13 = var_0_3:charge(arg_3_0.charge_id)

	var_3_12:setString(var_3_13 .. "USD")

	local var_3_14 = arg_3_0.container:getChildByName("now_txt")
	local var_3_15 = arg_3_0.container:getChildByName("buy_txt")
	local var_3_16 = arg_3_0.container:getChildByName("lingqu_txt")

	var_3_14:setString(var_3_10)

	local var_3_17 = arg_3_0.container:getChildByName("container_3")
	local var_3_18 = {
		color = cc.c3b(255, 255, 255)
	}

	var_3_18.size = 21

	local var_3_19 = xyd.AssetLoader.get():loadLabel(var_3_18)

	var_3_19:setMaxLineWidth(460)
	var_3_19:addTo(var_3_17)
	var_3_19:setAnchorPoint(cc.p(0, 1))
	var_3_19:setPosition(0, 80)

	local var_3_20 = xyd.tables.activities:desc(arg_3_0.activity.table_id)

	var_3_19:setString(var_3_20)
	arg_3_0:createTimeCount()

	arg_3_0.awardList = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 670, 385),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	})

	arg_3_0.awardList:addTo(var_3_0)
	arg_3_0.awardList:onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	local var_3_21 = {
		activity = arg_3_1,
		list = arg_3_0.awardList,
		count = arg_3_2
	}

	arg_3_0:addActivityAwardList(var_3_21)
end

function var_0_0.addActivityAwardList(arg_5_0, arg_5_1)
	arg_5_0.loginTable = xyd.tables.activityDongyunSouvenirLogin
	arg_5_1.listNum = #arg_5_0.loginTable:gifts()
	arg_5_1.obtainStates = arg_5_1.activity.details.is_awarded

	if not arg_5_1.listNum then
		return
	else
		arg_5_0:createAwardList(arg_5_1)
	end
end

function var_0_0.createAwardList(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.list
	local var_6_1 = arg_6_1.activity
	local var_6_2 = arg_6_1.listNum
	local var_6_3 = arg_6_1.count

	if arg_6_1.type then
		var_6_0:removeAllItems()
	end

	for iter_6_0 = 1, var_6_2 + 1 do
		if arg_6_0:checkInitItem(iter_6_0, arg_6_1) then
			local var_6_4 = var_6_0:newItem()
			local var_6_5 = display.newNode()
			local var_6_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1174/activity_item.csb")
			local var_6_7 = var_6_6:getChildByName("container")

			if iter_6_0 == 1 then
				var_6_7:getChildByName("btn"):setVisible(false)
				var_6_7:getChildByName("yilingqu"):setVisible(arg_6_0.activity.details.is_buy == 1)

				local var_6_8 = var_6_7:getChildByName("item_title_container")
				local var_6_9 = {
					color = cc.c3b(255, 255, 255)
				}

				var_6_9.size = 24

				local var_6_10 = xyd.AssetLoader.get():loadLabel(var_6_9)

				var_6_10:setMaxLineWidth(350)
				var_6_10:addTo(var_6_8)
				var_6_10:setAnchorPoint(cc.p(0, 0))
				var_6_10:setPosition(0, 0)

				local var_6_11 = var_0_1:translation("ACTIVITY_DONGYUN_TITLE1")

				var_6_10:setString(var_6_11)
				arg_6_0:rewardFormat(var_6_7:getChildByName("reward_container"), var_0_3:gift(arg_6_0.charge_id))
			else
				arg_6_0:rewardItemLayout(var_6_1, var_6_7, var_6_3, iter_6_0 - 1)
			end

			var_6_6:addTo(var_6_5)
			var_6_6:setTouchEnabled(true)
			var_6_6:setAnchorPoint(cc.p(0, 0))
			var_6_6:setPosition(0, 4)
			var_6_6:setTouchSwallowEnabled(false)
			var_6_5:setContentSize(667, 170)
			var_6_4:addContent(var_6_5)
			var_6_4:setItemSize(667, 170)
			var_6_0:addItem(var_6_4)
		end
	end

	var_6_0:reload()

	if arg_6_0.scrollNodePosX and arg_6_0.scrollNodePosY then
		var_6_0.scrollNode:setPosition(arg_6_0.scrollNodePosX, arg_6_0.scrollNodePosY)
	end
end

function var_0_0.rewardItemLayout(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4)
	local var_7_0 = arg_7_2:getChildByName("btn")
	local var_7_1 = var_7_0:getChildByName("txt")
	local var_7_2 = arg_7_2:getChildByName("yilingqu")
	local var_7_3 = arg_7_2:getChildByName("lingqu")
	local var_7_4 = arg_7_2:getChildByName("get_gray")
	local var_7_5 = arg_7_2:getChildByName("expired")
	local var_7_6 = arg_7_2:getChildByName("not_begin")
	local var_7_7 = {
		btn = var_7_0,
		alreadyObtain = var_7_2,
		obtain_bright = var_7_3,
		obtain_gray = var_7_4,
		expired = var_7_5,
		notBegin = var_7_6
	}
	local var_7_8 = arg_7_2:getChildByName("reward_container")
	local var_7_9 = arg_7_2:getChildByName("item_title_container")
	local var_7_10 = {
		color = cc.c3b(255, 255, 255)
	}

	var_7_10.size = 24

	local var_7_11 = xyd.AssetLoader.get():loadLabel(var_7_10)

	var_7_11:setMaxLineWidth(350)
	var_7_11:addTo(var_7_9)
	var_7_11:setAnchorPoint(cc.p(0, 0))
	var_7_11:setPosition(0, 0)

	local var_7_12 = arg_7_0.loginTable:name(arg_7_4)

	var_7_11:setString(var_7_12)

	local var_7_13 = xyd.ServerTime.get():getServerTime()

	if arg_7_1.details.is_buy == 0 then
		var_7_0:setVisible(false)
		var_7_2:setVisible(false)
	elseif arg_7_4 > arg_7_0.details.day_count then
		var_7_0:setVisible(false)
		var_7_2:setVisible(false)
	elseif arg_7_0.details.is_awarded[arg_7_4] == 1 then
		var_7_0:setVisible(false)
		var_7_2:setVisible(true)
	elseif arg_7_0.details.is_awarded[arg_7_4] == 0 then
		var_7_0:setVisible(true)
		var_7_2:setVisible(false)
		var_7_1:setString(var_0_1:translation("OBTAIN"))
	end

	arg_7_0:rewardFormat(var_7_8, arg_7_0.loginTable:gift(arg_7_4))

	if not arg_7_0:checkTime(arg_7_1) then
		var_7_0:setVisible(false)
		var_7_2:setVisible(false)
	end

	if var_7_13 < arg_7_1.start_time then
		var_7_0:setVisible(true)
		var_7_2:setVisible(false)
		var_7_1:setString(var_0_1:translation("ACTIVITY_COMMON_TEXT3"))
	end

	var_7_0:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = arg_7_4

			if arg_7_1.details.is_buy == 1 and arg_7_1.details.is_awarded[arg_7_4] == 0 then
				arg_7_0.scrollNodePosX = arg_7_0.awardList.scrollNode:getPositionX()
				arg_7_0.scrollNodePosY = arg_7_0.awardList.scrollNode:getPositionY()

				arg_7_0.activitiesModel:getActivityReward(arg_7_1.table_id, var_8_0, function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						arg_7_0.player:handleRewards(arg_9_1.awards)
						var_7_0:setVisible(false)
						var_7_2:setVisible(true)

						arg_7_0.details.is_awarded[arg_7_4] = 1

						xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):refreshRedMark()

						local var_9_0 = xyd.WindowManager.get():getWindow("activities")

						if var_9_0 and not tolua.isnull(var_9_0) then
							var_9_0:rightLayout()
						end
					end
				end)
			else
				local var_8_1 = var_0_1:translation("ACTIVITY_HAVE_GET_REWARD")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_8_1
				})
			end
		end
	end)
end

function var_0_0.purchaseGiftBag(arg_10_0, arg_10_1)
	local var_10_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_10_1
		}, {}, arg_10_1, false, var_0_3:charge(arg_10_1), var_0_3:name(arg_10_1))
	elseif device.platform == "ios" then
		local var_10_1 = var_0_3:iosProductId(arg_10_1)

		xyd.sdkPurchase(var_10_1, var_10_0, arg_10_1, {}, {}, {
			arg_10_1
		})
	end
end

function var_0_0.checkInitItem(arg_11_0, arg_11_1, arg_11_2)
	return true
end

function var_0_0.getDownTime(arg_12_0)
	return arg_12_0.activity.start_time - xyd.ServerTime.get():getServerTime()
end

function var_0_0.createTimeCount(arg_13_0)
	if arg_13_0.handle then
		var_0_2.unscheduleGlobal(arg_13_0.handle)

		arg_13_0.handle = nil
	end

	local var_13_0 = arg_13_0.activity.end_time - xyd.ServerTime.get():getServerTime()
	local var_13_1 = arg_13_0.activity.end_time - arg_13_0.activity.start_time

	arg_13_0:updateDownTime(var_13_0, var_13_1)

	arg_13_0.handle = var_0_2.scheduleGlobal(function()
		var_13_0 = var_13_0 - 1

		if var_13_0 <= 0 then
			var_0_2.unscheduleGlobal(arg_13_0.handle)
		else
			arg_13_0:updateDownTime(var_13_0, var_13_1)
		end
	end, 1)
end

function var_0_0.updateDownTime(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_0.buyEndTime - xyd.ServerTime.get():getServerTime()
	local var_15_1 = arg_15_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if arg_15_0:getDownTime() > 0 then
		arg_15_0.container:getChildByName("buy_txt"):setVisible(false)
		arg_15_0.container:getChildByName("lingqu_txt"):setString(var_0_1:translation("SAKURA_NOT_OPEN"))
	elseif var_15_0 <= 0 then
		if not tolua.isnull(arg_15_0.container) then
			arg_15_0.container:getChildByName("buy_txt"):setString(var_0_1:translation("ACTIVITY_DONGYUN_SOUVENIR_DAY_END"))
			arg_15_0.container:getChildByName("lingqu_txt"):setString(var_0_1:translation("ACTIVITY_DONGYUN_SOUVENIR_TIME") .. xyd.secondsToString(var_15_1))
		else
			var_0_2.unscheduleGlobal(arg_15_0.handle)
		end
	elseif var_15_1 <= 0 then
		arg_15_0.container:getChildByName("buy_txt"):setString(var_0_1:translation("ACTIVITY_DONGYUN_SOUVENIR_DAY_END"))
		contaself.containeriner:getChildByName("lingqu_txt"):setString(var_0_1:translation("SAKURA_CLOSED"))
	elseif not tolua.isnull(arg_15_0.container) then
		arg_15_0.container:getChildByName("buy_txt"):setString(var_0_1:translation("ACTIVITY_DONGYUN_SOUVENIR_DAY") .. xyd.secondsToString(var_15_0))
		arg_15_0.container:getChildByName("lingqu_txt"):setString(var_0_1:translation("ACTIVITY_DONGYUN_SOUVENIR_TIME") .. xyd.secondsToString(var_15_1))
	else
		var_0_2.unscheduleGlobal(arg_15_0.handle)
	end
end

function var_0_0.release(arg_16_0)
	if arg_16_0.handle then
		var_0_2.unscheduleGlobal(arg_16_0.handle)
	end

	var_0_0.super:release()
end

return var_0_0
