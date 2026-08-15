local var_0_0 = class("NewVipBoxDrawWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.activityChestNew
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = {
	9,
	5,
	0
}
local var_0_6 = var_0_4:getValue("activity_zhanghe_chest_item")
local var_0_7 = {
	var_0_4:getValue("activity_zhanghe_special_chest2"),
	var_0_4:getValue("activity_zhanghe_normal_chest2"),
	var_0_4:getValue("activity_zhanghe_lowest_chest2")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.activity = arg_1_0.activitiesModel:getActivityInfo(xyd.Activities.NewVipBoxDraw)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("time_words"):setString(var_0_3:translation("ACTIVITY_END_TIME"))
	arg_2_0:nodeByName("txt_rule"):setString(var_0_3:translation("ACTIVITY_1206_TEXT_1"))
	arg_2_0:nodeByName("words1"):setString(var_0_3:translation("ACTIVITY_1206_TEXT_5"))
	arg_2_0:nodeByName("words2"):setString(var_0_3:translation("ACTIVITY_1206_TEXT_6"))
	arg_2_0:nodeByName("words3"):setString(var_0_3:translation("ACTIVITY_1206_TEXT_7"))

	for iter_2_0 = 1, 3 do
		arg_2_0:nodeByName("words" .. iter_2_0):enableOutline(cc.c4b(86, 82, 106, 255), 2)
		arg_2_0:nodeByName("box" .. iter_2_0 .. "_cost_num"):setString("x" .. var_0_7[iter_2_0])

		local var_2_0 = arg_2_0:nodeByName("bg_box_gray" .. iter_2_0)

		if arg_2_0.selfPlayer.vip < var_0_5[iter_2_0] then
			var_2_0:setTouchEnabled(true)
			var_2_0:setTouchSwallowEnabled(true)
			var_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
				if arg_3_0.name == "began" then
					return true
				elseif arg_3_0.name == "ended" then
					xyd.WindowManager.get():openWindow("toast", {
						message = string.format(var_0_3:translation("ACTIVITY_VIP_BOX_DRAW2_LEV_TIP"), var_0_5[iter_2_0])
					})
				end
			end)
		else
			var_2_0:setVisible(false)
		end
	end

	arg_2_0:initBtn()
	arg_2_0:updateTicketNum()
end

function var_0_0.initBtn(arg_4_0)
	arg_4_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "ACTIVITY_VIP_BOX_DRAW2_TITLE",
				rule = "ACTIVITY_VIP_BOX_DRAW2_TEXT"
			})
		end
	end)
	arg_4_0:nodeByName("list_btn1"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_vip_box_draw_list", {
				index = 1,
				rareIds = var_0_2:getTotalIds(1, 2),
				normalIds = var_0_2:getTotalIds(1, 1)
			})
		end
	end)
	arg_4_0:nodeByName("list_btn2"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_vip_box_draw_list", {
				index = 2,
				rareIds = var_0_2:getTotalIds(2, 2),
				normalIds = var_0_2:getTotalIds(2, 1)
			})
		end
	end)
	arg_4_0:nodeByName("list_btn3"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_vip_box_draw_list", {
				index = 3,
				normalIds = var_0_2:getTotalIds(3, 1)
			})
		end
	end)
	arg_4_0:initDrawBtn(1)
	arg_4_0:initDrawBtn(2)
	arg_4_0:initDrawBtn(3)
end

function var_0_0.initDrawBtn(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_0:nodeByName("box_" .. arg_9_1)
	local var_9_1 = arg_9_0:nodeByName("bg_box" .. arg_9_1)

	var_9_0:setTouchEnabled(true)
	var_9_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			var_9_1:setScale(0.9)

			return true
		elseif arg_10_0.name == "ended" then
			var_9_1:setScale(1)
			xyd.playButtonSound()

			if arg_9_0.backpack:getItemNumByID(var_0_6) < var_0_7[arg_9_1] then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_3:translation("ACTIVITY_VIP_BOX_DRAW2_ABSENCE"))
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("ACTIVITY_VIP_BOX_DRAW2_ALERT"), var_0_7[arg_9_1], ""), function()
					arg_9_0:draw(arg_9_1)
				end, nil, nil, arg_9_0.colorMode)
			end
		end
	end)
end

function var_0_0.updateTicketNum(arg_12_0)
	local var_12_0 = arg_12_0.backpack:getItemNumByID(var_0_6)

	arg_12_0:nodeByName("ticket_num"):setString(var_12_0)
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	arg_13_0:nodeByName("close"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_14_0, false)
			xyd.WindowManager.get():closeWindow(arg_13_0)
		end
	end)
	arg_13_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
	arg_13_0:updateDownTimeScheduler()
end

function var_0_0.updateDownTimeScheduler(arg_15_0)
	if arg_15_0.handler then
		var_0_1.unscheduleGlobal(arg_15_0.handler)

		arg_15_0.handler = nil
	end

	arg_15_0.currentTime = xyd.ServerTime.get():getServerTime()
	arg_15_0.downTime = arg_15_0.activity.end_time - arg_15_0.currentTime

	if arg_15_0.downTime < 0 then
		arg_15_0.downTime = 0
	end

	arg_15_0:updateDownTime()

	arg_15_0.handler = var_0_1.scheduleGlobal(function()
		arg_15_0.currentTime = arg_15_0.currentTime + 1
		arg_15_0.downTime = arg_15_0.downTime - 1

		arg_15_0:updateDownTime()
	end, 1)
end

function var_0_0.updateDownTime(arg_17_0)
	if arg_17_0.downTime < 0 then
		arg_17_0.downTime = 0
	end

	local var_17_0 = string.format(var_0_3:translation("ACTIVITY_LEFT_TIME"), math.floor(arg_17_0.downTime / 86400), math.floor(arg_17_0.downTime % 86400 / 3600), math.floor(arg_17_0.downTime % 86400 % 3600 / 60))
	local var_17_1 = arg_17_0:nodeByName("time_text")

	if not tolua.isnull(var_17_1) then
		var_17_1:setString(var_17_0)
	end
end

function var_0_0.willClose(arg_18_0)
	var_0_0.super.willClose()

	if arg_18_0.handler then
		var_0_1.unscheduleGlobal(arg_18_0.handler)

		arg_18_0.handler = nil
	end
end

function var_0_0.draw(arg_19_0, arg_19_1)
	local var_19_0 = {
		activity_id = xyd.Activities.NewVipBoxDraw,
		award_id = arg_19_1
	}

	xyd.Backend.get():request(xyd.mid.ACTIVITY_1206_AWARD, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local var_20_0 = {
				itemID = var_0_6,
				itemNum = var_0_7[arg_19_1]
			}

			arg_19_0.backpack:removeItem(var_20_0)
			arg_19_0:updateTicketNum()

			if arg_19_1 == 3 then
				arg_19_0.selfPlayer:handleRewards({
					arg_20_1.awards[1]
				})
			else
				xyd.WindowManager.get():openWindow("new_vip_box_draw_effect", {
					awards = arg_20_1.awards,
					multiple = arg_20_1.multiple
				})
			end
		end
	end)
end

return var_0_0
