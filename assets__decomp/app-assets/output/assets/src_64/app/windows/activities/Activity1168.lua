local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.activityMonthLimit
local var_0_4 = import("framework.scheduler")
local var_0_5 = {
	1,
	3,
	4,
	5
}
local var_0_6 = xyd.tables.misc.activityConsumePoolPrice
local var_0_7 = xyd.tables.misc.activityConsumePoolPrice10

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.ticketNum = arg_1_0.backpack:getItemNumByID(var_0_2:getValue("activity_consume_pool_ticket"))
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
		arg_2_0.container:getChildByName("exchange_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			xyd.buttonScaleAnim(arg_3_0, arg_3_1)

			if arg_3_1 == ccui.TouchEventType.ended then
				local function var_3_0(...)
					arg_2_0:updateShow()
				end

				local var_3_1 = {
					details = arg_2_0.details,
					callback = var_3_0
				}

				xyd.WindowManager.get():openWindow("activity_consume_exchange", var_3_1)
			end
		end)
		arg_2_0.container:getChildByName("view_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
			xyd.buttonScaleAnim(arg_5_0, arg_5_1)

			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():openWindow("activity_consume_collection")
			end
		end)
		arg_2_0.container:getChildByName("buy_btn1"):addTouchEventListener(function(arg_6_0, arg_6_1)
			xyd.buttonScaleAnim(arg_6_0, arg_6_1)

			if arg_6_1 == ccui.TouchEventType.ended then
				if arg_2_0.ticketNum <= 0 and arg_2_0.details.base_info.free_times <= 0 and arg_2_0.selfPlayer.crystal < var_0_6 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_7_0 = {}

						var_7_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)

					return
				end

				if arg_2_0.details.base_info.free_times > 0 then
					arg_2_0:getAward(1)
				elseif arg_2_0.ticketNum > 0 then
					arg_2_0:getAward(3)
				else
					local var_6_0 = string.format(xyd.tables.translation:translation("ACTIVITY_CONSUME_COST_TIP1"), var_0_6)

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
						arg_2_0:getAward(1)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			end
		end)
		arg_2_0.container:getChildByName("buy_btn2"):addTouchEventListener(function(arg_9_0, arg_9_1)
			xyd.buttonScaleAnim(arg_9_0, arg_9_1)

			if arg_9_1 == ccui.TouchEventType.ended then
				if arg_2_0.selfPlayer.crystal < var_0_7 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_10_0 = {}

						var_10_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)

					return
				end

				local var_9_0 = string.format(xyd.tables.translation:translation("ACTIVITY_CONSUME_COST_TIP2"), var_0_7)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_0, function()
					arg_2_0:getAward(2)
				end, nil, nil, xyd.ColorMode.ACTIVITY)
			end
		end)
		arg_2_0.container:getChildByName("touch_arena"):setTouchEnabled(true)
		arg_2_0.container:getChildByName("touch_arena"):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				arg_2_0:updateLabel(var_0_5[math.random(2, 4)])
			end
		end)

		local var_2_1 = xyd.createLabel(20, cc.c3b(243, 216, 172))

		var_2_1:setAnchorPoint(0, 1)
		var_2_1:setLineHeight(33)
		var_2_1:setString(var_0_1:translation("ACTIVITY_CONSUME_POOL_RULE"))
		arg_2_0.container:getChildByName("pos_rule"):addChild(var_2_1)
		arg_2_0:updateShow()

		arg_2_0.dialogTxt = arg_2_0.container:getChildByName("dialog_bg"):getChildByName("dialog_txt")

		arg_2_0:createTimeCount()
		arg_2_0:updateLabel(1)
		arg_2_0.container:getChildByName("view_btn"):getChildByName("txt_view"):setString(var_0_1:translation("ACTIVITY_1168_BUTTON1"))
		arg_2_0.container:getChildByName("exchange_btn"):getChildByName("txt_exchange"):setString(var_0_1:translation("EXCHANGE_AWARD"))
		arg_2_0.container:getChildByName("cost_txt1"):setString("x" .. var_0_6)
		arg_2_0.container:getChildByName("cost_txt2"):setString("x" .. var_0_7)
		arg_2_0.container:getChildByName("free_text"):setString(xyd.tables.translation:translation("SUMMON_PRICE_FREE"))
	end
end

function var_0_0.getAward(arg_13_0, arg_13_1)
	arg_13_0.activitiesModel:getActivityReward(xyd.Activities.CollegeConsume, arg_13_1, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			if arg_13_1 == 3 then
				arg_13_0.backpack:removeItem({
					itemNum = 1,
					itemID = var_0_2:getValue("activity_consume_pool_ticket")
				})

				arg_13_0.ticketNum = arg_13_0.ticketNum - 1
			end

			arg_13_0.selfPlayer:handleRewards(arg_14_1.awards, function()
				arg_13_0:updateLabel(arg_13_1)
			end)

			if arg_14_1.base_info then
				arg_13_0.details.base_info = arg_14_1.base_info

				arg_13_0:updateShow()
			end
		end
	end)
end

function var_0_0.updateShow(arg_16_0)
	arg_16_0.container:getChildByName("pic_ticket"):setVisible(false)
	arg_16_0.container:getChildByName("score_txt"):setString(var_0_1:translation("PEAK_ARENA_MY_POINT") .. arg_16_0.details.base_info.point)

	if arg_16_0.details.base_info.free_times > 0 then
		arg_16_0.container:getChildByName("cost_txt1"):setVisible(false)
		arg_16_0.container:getChildByName("crystal1"):setVisible(false)
		arg_16_0.container:getChildByName("free_text"):setVisible(true)
		arg_16_0.container:getChildByName("pic_ticket"):setVisible(false)
	elseif arg_16_0.ticketNum > 0 then
		arg_16_0.container:getChildByName("free_text"):setVisible(false)
		arg_16_0.container:getChildByName("crystal1"):setVisible(false)
		arg_16_0.container:getChildByName("pic_ticket"):setVisible(true)
		arg_16_0.container:getChildByName("cost_txt1"):setVisible(false)
	else
		arg_16_0.container:getChildByName("cost_txt1"):setVisible(true)
		arg_16_0.container:getChildByName("crystal1"):setVisible(true)
		arg_16_0.container:getChildByName("free_text"):setVisible(false)
		arg_16_0.container:getChildByName("pic_ticket"):setVisible(false)
	end
end

function var_0_0.createTimeCount(arg_17_0)
	if arg_17_0.handle then
		var_0_4.unscheduleGlobal(arg_17_0.handle)

		arg_17_0.handle = nil
	end

	arg_17_0.count = 0
	arg_17_0.handle = var_0_4.scheduleGlobal(function()
		arg_17_0.count = arg_17_0.count + 1

		if arg_17_0 and arg_17_0.dialogTxt and not tolua.isnull(arg_17_0.dialogTxt) and arg_17_0.container and not tolua.isnull(arg_17_0.container) then
			if arg_17_0.count >= 5 then
				arg_17_0:updateLabel(var_0_5[math.random(1, 4)])
			end
		elseif arg_17_0.handle then
			var_0_4.unscheduleGlobal(arg_17_0.handle)

			arg_17_0.handle = nil
		end
	end, 1)
end

function var_0_0.updateLabel(arg_19_0, arg_19_1)
	if arg_19_0.dialogTxt and not tolua.isnull(arg_19_0.dialogTxt) then
		arg_19_0.dialogTxt:setString(var_0_1:translation("ACTIVITY_CONSUME_TIPS" .. arg_19_1))

		arg_19_0.count = 0
	end
end

function var_0_0.release(arg_20_0)
	if arg_20_0.handle then
		var_0_4.unscheduleGlobal(arg_20_0.handle)
	end

	var_0_0.super:release()
end

return var_0_0
