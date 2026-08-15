local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.charge
local var_0_4 = 80001001

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(0, 0)
		arg_2_0.container:getChildByName("buy_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.began then
				arg_2_0.container:getChildByName("buy_btn"):setScale(0.9)
			elseif arg_3_1 == ccui.TouchEventType.moved then
				arg_2_0.container:getChildByName("buy_btn"):setScale(1)
			elseif arg_3_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_2_0.container:getChildByName("buy_btn"):setScale(1)
				xyd.tracking(xyd.AFInAppEventType.MONTHLY_PACK)
				arg_2_0:purchase(var_0_4)
			end
		end)
		arg_2_0.container:getChildByName("bg1"):getChildByName("old_price_copy"):setString(var_0_2:translation("ACTIVITY_1173_TEXT1"))
		arg_2_0.container:getChildByName("bg2"):getChildByName("old_price"):setString(var_0_2:translation("ACTIVITY_1173_TEXT1"))
		arg_2_0.container:getChildByName("buy_btn"):getChildByName("txt_buy"):setString(var_0_2:translation("ACTIVITY_1173_TEXT3"))
		arg_2_0:createTimeCount()
	end

	arg_2_0.giftTimeLeft = arg_2_0.details.created_time - xyd.ServerTime.get():getServerTime() + 259200
	arg_2_0.giftID = xyd.tables.misc:getValue("activity_monthcard_gift_id")

	if arg_2_0.giftTimeLeft > 0 then
		arg_2_0.container:getChildByName("bg1"):setVisible(false)

		arg_2_0.bg2 = arg_2_0.container:getChildByName("bg2")

		arg_2_0.bg2:getChildByName("gift"):setVisible(not arg_2_0.details.is_awarded or arg_2_0.details.is_awarded == 0)
		arg_2_0.bg2:getChildByName("gift_open"):setVisible(arg_2_0.details.is_awarded and arg_2_0.details.is_awarded == 1)

		arg_2_0.giftTimeTxt = arg_2_0.bg2:getChildByName("time_gift")

		arg_2_0.giftTimeTxt:setVisible(not arg_2_0.details.is_awarded or arg_2_0.details.is_awarded == 0)
		arg_2_0.giftTimeTxt:setString(string.format(var_0_2:translation("ACTIVITY_1173_TEXT2"), xyd.secondsToString1(arg_2_0.giftTimeLeft)))
		arg_2_0:createGiftTimer()
		arg_2_0.bg2:getChildByName("gift"):setTouchEnabled(true)
		arg_2_0.bg2:getChildByName("gift"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				if arg_2_0.selfPlayer.leftCardDay > 0 then
					arg_2_0.bg2:getChildByName("gift"):setScale(0.9)
				else
					local var_4_0 = xyd.tables.gift:items(arg_2_0.giftID)
					local var_4_1 = xyd.tables.gift:itemNum(arg_2_0.giftID)
					local var_4_2 = xyd.getFormatItemsByIdNums(var_4_0, var_4_1)

					xyd.WindowManager.get():openWindow("common_award", {
						awards = var_4_2
					})

					local var_4_3 = arg_2_0.bg2:getChildByName("gift"):convertToWorldSpace(cc.p(0, 0))

					xyd.WindowManager.get():getWindow("common_award"):setPosition(math.min(var_4_3.x - 220, 880), var_4_3.y + 130)
				end

				return true
			elseif arg_4_0.name == "ended" then
				arg_2_0.bg2:getChildByName("gift"):setScale(1)

				if arg_2_0.selfPlayer.leftCardDay <= 0 then
					if xyd.WindowManager:get():getWindow("common_award") then
						xyd.WindowManager:get():closeWindow("common_award")
					end

					return
				end

				arg_2_0.activitiesModel:getActivityReward(xyd.Activities.MonthCard, nil, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_2_0.selfPlayer:handleRewards(arg_5_1.awards)

						arg_2_0.details.is_awarded = 1

						arg_2_0.bg2:getChildByName("gift"):setVisible(false)
						arg_2_0.bg2:getChildByName("gift_open"):setVisible(true)
					end
				end)
			elseif arg_4_0.name == "cancled" then
				arg_2_0.bg2:getChildByName("gift"):setScale(1)

				if xyd.WindowManager:get():getWindow("common_award") then
					xyd.WindowManager:get():closeWindow("common_award")
				end
			end
		end)
	else
		arg_2_0.container:getChildByName("bg2"):setVisible(false)
	end
end

function var_0_0.purchase(arg_6_0, arg_6_1)
	local var_6_0 = true
	local var_6_1 = {}

	if device.platform == "android" then
		xyd.androidPurchase({
			arg_6_1
		}, var_6_1, arg_6_1, false, var_0_3:charge(arg_6_1), var_0_3:chargeName(arg_6_1))
	elseif device.platform == "ios" then
		local var_6_2 = var_0_3:iosProductID(arg_6_1)

		xyd.sdkPurchase(var_6_2, var_6_0, arg_6_1, {}, var_6_1, {
			arg_6_1
		})
	end
end

function var_0_0.createTimeCount(arg_7_0)
	if arg_7_0.handle then
		var_0_1.unscheduleGlobal(arg_7_0.handle)

		arg_7_0.handle = nil
	end

	arg_7_0:update()

	arg_7_0.handle = var_0_1.scheduleGlobal(function()
		if arg_7_0 and arg_7_0.container and not tolua.isnull(arg_7_0.container) then
			arg_7_0:update()
		elseif arg_7_0.handle then
			var_0_1.unscheduleGlobal(arg_7_0.handle)

			arg_7_0.handle = nil
		end
	end, 1)
end

function var_0_0.createGiftTimer(arg_9_0)
	if arg_9_0.giftHandle then
		var_0_1.unscheduleGlobal(arg_9_0.giftHandle)

		arg_9_0.giftHandle = nil
	end

	arg_9_0.giftHandle = var_0_1.scheduleGlobal(function()
		if arg_9_0 and arg_9_0.container and not tolua.isnull(arg_9_0.container) then
			arg_9_0.giftTimeLeft = arg_9_0.giftTimeLeft - 1

			if arg_9_0.giftTimeLeft <= 0 then
				arg_9_0.container:getChildByName("bg2"):setVisible(false)
				arg_9_0.container:getChildByName("bg1"):setVisible(true)
				var_0_1.unscheduleGlobal(arg_9_0.giftHandle)

				arg_9_0.giftHandle = nil
			else
				arg_9_0.giftTimeTxt:setString(string.format(var_0_2:translation("ACTIVITY_1173_TEXT2"), xyd.secondsToString1(arg_9_0.giftTimeLeft)))
			end
		elseif arg_9_0.giftHandle then
			var_0_1.unscheduleGlobal(arg_9_0.giftHandle)

			arg_9_0.giftHandle = nil
		end
	end, 1)
end

function var_0_0.update(arg_11_0)
	local var_11_0 = arg_11_0.selfPlayer.leftCardDay

	arg_11_0.container:getChildByName("time_text"):setString(string.format(var_0_2:translation("AVATAR_LEFT_TIME_DAY"), var_11_0))
	arg_11_0.container:getChildByName("time_text"):setVisible(true)
	arg_11_0.container:getChildByName("buy_btn"):setBright(true)
	arg_11_0.container:getChildByName("buy_btn"):setTouchEnabled(true)

	if arg_11_0.selfPlayer.leftCardDay <= 0 then
		arg_11_0.container:getChildByName("buy_btn"):getChildByName("txt_buy"):setString(var_0_2:translation("ACTIVITY_1173_TEXT3"))
		arg_11_0.container:getChildByName("time_text"):setVisible(false)
	elseif arg_11_0.selfPlayer.leftCardDay > 30 then
		arg_11_0.container:getChildByName("buy_btn"):getChildByName("txt_buy"):setString(var_0_2:translation("ACTIVITY_COMMON_TEXT5"))
		arg_11_0.container:getChildByName("buy_btn"):setBright(false)
		arg_11_0.container:getChildByName("buy_btn"):setTouchEnabled(false)
	end
end

function var_0_0.release(arg_12_0)
	if arg_12_0.handle then
		var_0_1.unscheduleGlobal(arg_12_0.handle)
	end

	if arg_12_0.giftHandle then
		var_0_1.unscheduleGlobal(arg_12_0.giftHandle)
	end

	var_0_0.super:release()
end

return var_0_0
