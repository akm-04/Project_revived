local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.chargeList
local var_0_4 = xyd.tables.activityChenshouTravel
local var_0_5 = 80008803
local var_0_6 = xyd.tables.activityChenshouTravelBonus
local var_0_7 = {
	hard = 2,
	normal = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.flag = var_0_7.normal
	arg_1_0.awardItem = arg_1_0.details.self_awarded
	arg_1_0.achieveItem = arg_1_0.details.self_achieved
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container")

	var_2_1:getChildByName("txt_tips"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_1"))

	if arg_2_0.details.is_buy == 0 then
		var_2_1:getChildByName("btn_buygift"):getChildByName("txt_buy"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_3") .. var_0_3:charge(var_0_5))
	else
		var_2_1:getChildByName("btn_buygift"):setTouchEnabled(false)
		var_2_1:getChildByName("btn_buygift"):setBright(false)
		var_2_1:getChildByName("btn_buygift"):getChildByName("txt_buy"):setColor(cc.c3b(52, 54, 55))
		var_2_1:getChildByName("btn_buygift"):getChildByName("txt_buy"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_4"))
	end

	var_2_1:getChildByName("num_time"):setString(arg_2_0.details.whole_charge_count)
	var_2_1:getChildByName("txt_fuli"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	var_2_1:getChildByName("txt_fuli"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_8"))
	var_2_1:getChildByName("txt_time"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_9"))
	var_2_1:getChildByName("txt_gift"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_2"))
	var_2_1:getChildByName("btn_person"):getChildByName("txt_person"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_11"))
	var_2_1:getChildByName("btn_server"):getChildByName("txt_server"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_12"))

	local var_2_2 = var_2_1:getChildByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_2.width, var_2_2.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_1:getChildByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0.list:reload()
	arg_2_0:initBtn(var_2_1)
end

function var_0_0.sortAwardItem(arg_3_0)
	local var_3_0 = {
		[var_0_7.normal] = {},
		[var_0_7.hard] = {}
	}
	local var_3_1 = #var_0_4:getIdByType(var_0_7.normal)

	for iter_3_0 = 1, #arg_3_0.awardItem do
		if iter_3_0 <= var_3_1 and arg_3_0.awardItem[iter_3_0] == 0 then
			table.insert(var_3_0[var_0_7.normal], iter_3_0)
		elseif var_3_1 < iter_3_0 and arg_3_0.awardItem[iter_3_0] == 0 then
			table.insert(var_3_0[var_0_7.hard], iter_3_0)
		end
	end

	for iter_3_1 = 1, #arg_3_0.awardItem do
		if iter_3_1 <= var_3_1 and arg_3_0.awardItem[iter_3_1] == 1 then
			table.insert(var_3_0[var_0_7.normal], iter_3_1)
		elseif var_3_1 < iter_3_1 and arg_3_0.awardItem[iter_3_1] == 1 then
			table.insert(var_3_0[var_0_7.hard], iter_3_1)
		end
	end

	return var_3_0
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = arg_4_0:sortAwardItem()

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #var_4_0[arg_4_0.flag]
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_1 = arg_4_0.list:dequeueItem()

		if var_4_1 then
			var_4_1:removeAllChildren()
		else
			var_4_1 = arg_4_0.list:newItem()
		end

		local var_4_2 = display.newNode()

		var_4_2:setContentSize(667, 170)
		var_4_2:setAnchorPoint(cc.p(0.5, 0.5))
		arg_4_0:createItemContent(var_4_0, arg_4_3):addTo(var_4_2)
		var_4_1:addContent(var_4_2)
		var_4_1:setItemSize(667, 170)

		return var_4_1
	end
end

function var_0_0.createItemContent(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1234/gift_item.csb")
	local var_5_1 = var_5_0:getChildByName("container")
	local var_5_2 = var_5_1:getContentSize()

	var_5_0:setContentSize(var_5_2)

	local var_5_3 = arg_5_1[arg_5_0.flag][arg_5_2]

	var_5_1:getChildByName("txt_title"):setString(var_0_4:name(var_5_3))
	arg_5_0:rewardFormat(var_5_1:getChildByName("list_gift"), var_0_4:gift(var_5_3))

	local var_5_4 = var_5_1:getChildByName("btn_get")

	if arg_5_0.achieveItem[var_5_3] == 0 then
		var_5_4:getChildByName("txt_get"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_6"))
		var_5_4:setTouchEnabled(false)
	elseif arg_5_0.awardItem[var_5_3] == 0 then
		var_5_4:getChildByName("txt_get"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_5"))
	else
		var_5_4:getChildByName("txt_get"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_7"))
		var_5_4:setTouchEnabled(false)
		var_5_4:setBright(false)
	end

	var_5_4:addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(var_5_4, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_5_0:checkIsOpen() then
				if arg_5_0.details.is_buy == 1 then
					arg_5_0.activitiesModel:getActivityReward2(arg_5_0.activity.table_id, var_5_3, 1, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_5_0.player:handleRewards(arg_7_1.awards)
							arg_5_0.activitiesModel:refreshRedMark()

							arg_5_0.awardItem[var_5_3] = 1

							var_5_4:getChildByName("txt_get"):setString(var_0_2:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_7"))
							var_5_4:setTouchEnabled(false)
							var_5_4:setBright(false)
						end
					end)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("ACTIVITY_CHENSHOU_TRAVEL_TEXT_13")
					})
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_FINISHED")
				})
			end
		end
	end)

	return var_5_0
end

function var_0_0.purchaseGiftBag(arg_8_0, arg_8_1)
	local var_8_0 = true

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_8_1
		}, {}, arg_8_1, false, var_0_3:charge(arg_8_1), var_0_3:name(arg_8_1))
	elseif device.platform == "ios" then
		local var_8_1 = var_0_3:iosProductId(arg_8_1)

		xyd.sdkPurchase(var_8_1, var_8_0, arg_8_1, {}, {}, {
			arg_8_1
		})
	end
end

function var_0_0.initBtn(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1:getChildByName("btn_person")
	local var_9_1 = arg_9_1:getChildByName("btn_server")

	if arg_9_0.flag == var_0_7.normal then
		var_9_1:setBright(true)
		var_9_0:setBright(false)
		var_9_0:setTouchEnabled(false)
		var_9_1:setTouchEnabled(true)
	else
		var_9_0:setBright(true)
		var_9_1:setBright(false)
		var_9_1:setTouchEnabled(false)
		var_9_0:setTouchEnabled(true)
	end

	var_9_0:addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(var_9_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_9_0.flag = var_0_7.normal

			var_9_1:setBright(true)
			var_9_0:setBright(false)
			var_9_0:setTouchEnabled(false)
			var_9_1:setTouchEnabled(true)
			arg_9_0.list:reload()
		end
	end)
	var_9_1:addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(var_9_1, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_9_0.flag = var_0_7.hard

			var_9_0:setBright(true)
			var_9_1:setBright(false)
			var_9_1:setTouchEnabled(false)
			var_9_0:setTouchEnabled(true)
			arg_9_0.list:reload()
		end
	end)

	local var_9_2 = arg_9_1:getChildByName("btn_rule")

	var_9_2:addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(var_9_2, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_12_0 = {}

			var_12_0.title_name = "ACTIVITY_CHENSHOU_TRAVEL_RULE_TITLE"
			var_12_0.rule = "ACTIVITY_CHENSHOU_TRAVEL_RULE"

			xyd.WindowManager.get():openWindow("new_text_rule", var_12_0)
		end
	end)

	local var_9_3 = arg_9_1:getChildByName("btn_buygift")

	var_9_3:addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(var_9_3, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			if arg_9_0:checkIsOpen() then
				xyd.playButtonSound()
				arg_9_0:purchaseGiftBag(var_0_5)
				xyd.WindowManager.get():closeWindow("activities")
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_FINISHED")
				})
			end
		end
	end)

	local var_9_4 = arg_9_1:getChildByName("btn_box")
	local var_9_5 = 0

	for iter_9_0 = 1, #arg_9_0.details.whole_awarded do
		if arg_9_0.details.whole_awarded[iter_9_0] == 0 then
			var_9_5 = iter_9_0

			break
		end
	end

	if var_0_6:reqNum(var_9_5) <= arg_9_0.details.whole_charge_count then
		var_9_4:getChildByName("bg_redpoint"):setVisible(true)
	else
		var_9_4:getChildByName("bg_redpoint"):setVisible(false)
	end

	var_9_4:addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(var_9_4, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_9_0:checkIsOpen() then
				xyd.playButtonSound()
				var_9_4:getChildByName("bg_redpoint"):setVisible(false)

				local var_14_0 = {
					activity_id = arg_9_0.activity.table_id
				}

				arg_9_0.activitiesModel:loadSingleActivity(var_14_0, function(arg_15_0, arg_15_1)
					xyd.WindowManager.get():openWindow("activity1234_all_award", arg_15_1)
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("ACTIVITY_FINISHED")
				})
			end
		end
	end)
end

function var_0_0.checkIsOpen(arg_16_0)
	if arg_16_0.activity.end_time - xyd.ServerTime.get():getServerTime() <= 0 or arg_16_0.activity.start_time - xyd.ServerTime.get():getServerTime() >= 0 then
		return false
	else
		return true
	end
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevY_ = arg_17_1.y
	elseif arg_17_1.name == "moved" and 20 <= math.abs(arg_17_1.y - arg_17_0.prevY_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_18_0)
	if arg_18_0.handle then
		var_0_1.unscheduleGlobal(arg_18_0.handle)

		arg_18_0.handle = nil
	end
end

return var_0_0
