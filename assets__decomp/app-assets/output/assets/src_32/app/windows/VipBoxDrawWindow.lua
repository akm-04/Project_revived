local var_0_0 = class("VipBoxDrawWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.vipBoxDraw
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.misc
local var_0_5 = {
	9,
	5
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rareIds = var_0_1:rareIds()
	arg_1_0.normalIds = var_0_1:normalIds()
	arg_1_0.totalIds1 = var_0_1:totalIds1()
	arg_1_0.totalIds2 = var_0_1:totalIds2()
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.activity = arg_1_0.activitiesModel:getActivityInfo(xyd.Activities.VipBoxDraw)
	arg_1_0.vipBoxDrawCost = {
		var_0_4.vipBoxDrawCost1,
		var_0_4.vipBoxDrawCost2
	}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("box1_cost_num"):setString(arg_2_0.vipBoxDrawCost[1])
	arg_2_0:nodeByName("box2_cost_num"):setString(arg_2_0.vipBoxDrawCost[2])

	for iter_2_0 = 1, 2 do
		local var_2_0 = arg_2_0:nodeByName("bg_box_gray" .. iter_2_0)

		if arg_2_0.player.vip < var_0_5[iter_2_0] then
			var_2_0:setTouchEnabled(true)
			var_2_0:setTouchSwallowEnabled(true)
			var_2_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
				if arg_3_0.name == "began" then
					return true
				elseif arg_3_0.name == "ended" then
					xyd.WindowManager.get():openWindow("toast", {
						message = string.format(var_0_2:translation("ACTIVITY_VIP_BOX_DRAW_LEV_TIP"), var_0_5[iter_2_0])
					})
				end
			end)
		else
			var_2_0:setVisible(false)
		end
	end

	arg_2_0:initBtn()
end

function var_0_0.initBtn(arg_4_0)
	arg_4_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_gacha_rule", {
				rule = "ACTIVITY_VIP_BOX_DRAW_TEXT",
				title = "ACTIVITY_VIP_BOX_DRAW_TITLE"
			})
		end
	end)
	arg_4_0:nodeByName("list_btn1"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("vip_box_draw_list", {
				index = "1",
				rareIds = arg_4_0.rareIds,
				normalIds = arg_4_0.normalIds
			})
		end
	end)
	arg_4_0:nodeByName("list_btn2"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("vip_box_draw_list", {
				index = "2",
				normalIds = arg_4_0.totalIds1
			})
		end
	end)
	arg_4_0:initDrawBtn(1)
	arg_4_0:initDrawBtn(2)
end

function var_0_0.initDrawBtn(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:nodeByName("box" .. arg_8_1)

	var_8_0:setTouchEnabled(true)
	var_8_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_8_0:setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			var_8_0:setScale(1)
			xyd.playButtonSound()

			if arg_8_0.player.crystal < arg_8_0.vipBoxDrawCost[arg_8_1] then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
					xyd.WindowManager.get():openWindow("vip_recharge", {
						windowState = true
					})
				end, nil, nil, arg_8_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_2:translation("ACTIVITY_VIP_BOX_DRAW_ALERT"), arg_8_0.vipBoxDrawCost[arg_8_1], var_0_2:translation("ACTIVITY_VIP_BOX_DRAW_BOX" .. arg_8_1)), function()
					arg_8_0:draw(3 - arg_8_1)
				end, nil, nil, arg_8_0.colorMode)
			end
		end
	end)
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	arg_12_0:nodeByName("close"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			local var_13_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_13_0, false)
			xyd.WindowManager.get():closeWindow(arg_12_0)
		end
	end)
	arg_12_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.draw(arg_14_0, arg_14_1)
	arg_14_0.activitiesModel:getActivityReward(xyd.Activities.VipBoxDraw, arg_14_1, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			local var_15_0

			if arg_14_1 == 1 then
				var_15_0 = arg_14_0.totalIds1
			elseif arg_14_1 == 2 then
				var_15_0 = arg_14_0.totalIds2
			end

			local var_15_1 = arg_15_1.awards[1].table_id

			if var_0_3:heroID(var_15_1) > 0 then
				var_15_1 = var_0_3:heroID(var_15_1)
			end

			xyd.WindowManager.get():openWindow("vip_box_draw_open", {
				heroId = var_15_1,
				awards = arg_15_1.awards,
				heroIds = var_15_0,
				multiple = arg_15_1.multiple
			})
		end
	end)
end

return var_0_0
