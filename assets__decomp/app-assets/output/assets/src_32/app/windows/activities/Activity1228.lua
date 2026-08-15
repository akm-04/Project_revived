local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.giftbag
local var_0_5 = xyd.tables.activityMonthGift
local var_0_6

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	local var_1_0 = var_0_3:getValue("activity_month_gift_item_id")

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.isBuy = arg_1_0.selfPlayer:getBackpack():getItemNumByID(var_1_0)

	dump(arg_1_0.activity)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = var_0_3:getValue("activity_month_gift_id")
	local var_3_1 = var_0_4:originalCharge(var_3_0)
	local var_3_2 = var_0_4:charge(var_3_0)
	local var_3_3 = var_0_2:translation("ACTIVITY_1228_1")

	arg_3_0.container:getChildByName("txt_origin_price"):setString(var_3_3 .. var_3_1)
	arg_3_0.container:getChildByName("txt_now_price"):setString(var_0_2:translation("ACTIVITY_1228_2"))
	arg_3_0.container:getChildByName("txt_now_num"):setString(var_3_2)
	arg_3_0.container:getChildByName("txt_item"):setString(var_0_2:translation("ACTIVITY_1228_3"))

	arg_3_0.rewardCount, arg_3_0.downtime = arg_3_0:checkInitItem()

	arg_3_0:updateGift(arg_3_0.rewardCount)
	arg_3_0:updateDownTime(arg_3_0.downtime)
	arg_3_0:updateBtn()
	arg_3_0.container:getChildByName("btn_buy"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.isBuy == 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ACTIVITY_1228_4"), function()
					local var_5_0 = {}

					var_5_0.windowState = true
					var_5_0.chargeState = xyd.ChargeState.giftbag

					xyd.WindowManager.get():openWindow("vip_recharge", var_5_0)

					local var_5_1 = xyd.WindowManager.get():getWindow("activities")

					if var_5_1 then
						var_5_1:close()
					end
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			else
				local var_4_0 = var_0_2:translation("ACTIVITY_1228_5")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_0, function()
					local var_6_0 = {}

					xyd.Backend.get():request(xyd.mid.ACTIVITY_MONTH_FUND_AWARD, var_6_0, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							if arg_7_1 and arg_7_1.awards then
								arg_3_0.selfPlayer:handleRewards(arg_7_1.awards)
								arg_3_0.container:getChildByName("btn_buy"):setTouchEnabled(false)
								arg_3_0.container:getChildByName("btn_buy"):setBright(false)
								arg_3_0.activitiesModel:clearRedMarkState(arg_3_0.activity.table_id, 2)
							end
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_2:translation("WAR_CAMP_SHOP_TIPS1")
							})
						end
					end)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end
	end)
end

function var_0_0.checkInitItem(arg_8_0)
	local var_8_0 = xyd.ServerTime.get():getServerTime()
	local var_8_1 = 0
	local var_8_2 = 0

	if var_8_0 >= arg_8_0.activity.start_time and var_8_0 <= arg_8_0.activity.end_time then
		var_8_1 = math.floor((var_8_0 - arg_8_0.activity.start_time) / 604800)
		var_8_2 = 604800 - (var_8_0 - arg_8_0.activity.start_time - var_8_1 * 86400 * 7)
	end

	return var_8_1, var_8_2
end

function var_0_0.updateGift(arg_9_0, arg_9_1)
	local var_9_0 = var_0_5:gift(arg_9_1 + 1)

	arg_9_0.container:getChildByName("list"):removeAllChildren()

	if var_9_0 then
		arg_9_0:rewardFormat(arg_9_0.container:getChildByName("list"), var_9_0)
	end
end

function var_0_0.updateBtn(arg_10_0)
	local var_10_0 = arg_10_0.container:getChildByName("btn_buy")
	local var_10_1 = var_10_0:getChildByName("txt_buy")

	if arg_10_0.isBuy == 0 then
		var_10_1:setString(var_0_2:translation("ACTIVITY_1228_6"))
	else
		var_10_1:setString(var_0_2:translation("ACTIVITY_1228_7"))

		if arg_10_0.activity.details.is_award[arg_10_0.rewardCount + 1] == 0 then
			var_10_0:setTouchEnabled(true)
			var_10_0:setBright(true)
		else
			var_10_0:setTouchEnabled(false)
			var_10_0:setBright(false)
			var_10_1:setString(var_0_2:translation("REWARD_HAS_GOT"))
		end
	end
end

function var_0_0.updateDownTime(arg_11_0, arg_11_1)
	local function var_11_0(arg_12_0)
		local var_12_0

		if arg_12_0 < 86400 then
			var_12_0 = xyd.secondsToString(arg_12_0)
		else
			var_12_0 = xyd.secondsToString1(arg_12_0)
		end

		return var_12_0
	end

	if var_0_6 then
		var_0_1.unscheduleGlobal(var_0_6)

		var_0_6 = nil
	end

	if arg_11_1 and arg_11_1 > 0 then
		arg_11_0.container:getChildByName("txt_downtime"):setString(var_11_0(arg_11_1))

		var_0_6 = var_0_1.scheduleGlobal(function()
			arg_11_1 = arg_11_1 - 1

			if arg_11_0.container and not tolua.isnull(arg_11_0.container) then
				arg_11_0.container:getChildByName("txt_downtime"):setString(var_11_0(arg_11_1))
			end

			if arg_11_1 <= 0 then
				if var_0_6 then
					var_0_1.unscheduleGlobal(var_0_6)

					var_0_6 = nil
				end

				arg_11_0.rewardCount, arg_11_0.downtime = arg_11_0:checkInitItem()

				arg_11_0:updateGift(arg_11_0.rewardCount)
				arg_11_0:updateDownTime(arg_11_0.downtime)
				arg_11_0:updateBtn()
				arg_11_0.container:getChildByName("txt_downtime"):setString("")
			end
		end, 1)
	else
		if var_0_6 then
			var_0_1.unscheduleGlobal(var_0_6)

			var_0_6 = nil
		end

		arg_11_0.container:getChildByName("txt_downtime"):setString("")
	end
end

function var_0_0.release(arg_14_0)
	if var_0_6 then
		var_0_1.unscheduleGlobal(var_0_6)

		var_0_6 = nil
	end
end

return var_0_0
