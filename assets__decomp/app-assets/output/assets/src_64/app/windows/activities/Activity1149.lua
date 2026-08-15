local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySkinConsumeSet
local var_0_3 = 1
local var_0_4 = {
	yanliang = 1,
	wenchou = 3,
	cp = 2
}
local var_0_5 = {
	{
		scale = 1.15,
		x = 12,
		y = 222
	},
	{
		scale = 1,
		x = -195,
		y = 0
	},
	{
		scale = 1,
		x = -195,
		y = 0
	}
}
local var_0_6 = {
	{
		fade = 255,
		scale = 1.1,
		x = -50,
		y = 0
	},
	{
		fade = 255,
		scale = 1,
		x = -280,
		y = 0
	},
	{
		fade = 0,
		scale = 0.85,
		x = -150,
		y = 0
	}
}
local var_0_7 = {
	{
		fade = 0,
		scale = 0.85,
		x = 50,
		y = 0
	},
	{
		fade = 255,
		scale = 1,
		x = 223,
		y = 0
	},
	{
		fade = 255,
		scale = 1.1,
		x = 20,
		y = 0
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.alreadyInit = false
end

function var_0_0.initDetails(arg_2_0)
	if arg_2_0.alreadyInit then
		return
	end

	arg_2_0.alreadyInit = true

	if arg_2_0.details.award_str[var_0_4.cp] == 1 then
		arg_2_0.details.award_str[var_0_4.yanliang] = 1
		arg_2_0.details.award_str[var_0_4.wenchou] = 1
	end

	if arg_2_0.details.award_str[var_0_4.yanliang] == 1 or arg_2_0.details.award_str[var_0_4.wenchou] == 1 then
		arg_2_0.details.award_str[var_0_4.cp] = 1
	end
end

function var_0_0.show(arg_3_0, arg_3_1)
	var_0_0.super.show(arg_3_0, arg_3_1)

	if not arg_3_0.res or arg_3_0.res == 0 then
		print("No res available.")

		return
	end

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_3_0.res)

	var_3_0:addTo(arg_3_0.parent)

	arg_3_0.nodeDetail = var_3_0:getChildByName("container")
	arg_3_0.awardContainer = arg_3_0.nodeDetail:getChildByName("single_award")
	arg_3_0.btnState = var_0_4.cp

	arg_3_0:initDetails()
	arg_3_0:setButtonClick()
	arg_3_0:changeButtonState()
	arg_3_0:layout()
	arg_3_0.awardContainer:getChildByName("award_num_txt1"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 2)
	arg_3_0.awardContainer:getChildByName("award_num_txt2"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 2)
	arg_3_0.nodeDetail:getChildByName("txt_crystal_num"):enableShadow(xyd.color.FONT_SHADOW_A, cc.size(1, -1), 2)
	arg_3_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_get"):setString(var_0_1:translation("MAP_BUY"))
	arg_3_0.nodeDetail:getChildByName("btn_cp"):getChildByName("txt_cp"):setString(var_0_1:translation("ACTIVITY_1149_MID"))
	arg_3_0.nodeDetail:getChildByName("btn_yanliang"):getChildByName("txt_yanliang"):setString(var_0_1:translation("ACTIVITY_1149_LEFT"))
	arg_3_0.nodeDetail:getChildByName("btn_wenchou"):getChildByName("txt_wenchou"):setString(var_0_1:translation("ACTIVITY_1149_RIGHT"))
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0.nodeDetail:getChildByName("btn_cp"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_cp"):setScale(0.9)
		end

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_cp"):setScale(1)

			arg_4_0.btnState = var_0_4.cp

			arg_4_0:changeButtonState()
			arg_4_0:showEffect()
		end
	end)
	arg_4_0.nodeDetail:getChildByName("btn_yanliang"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_yanliang"):setScale(0.9)
		end

		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_yanliang"):setScale(1)

			arg_4_0.btnState = var_0_4.yanliang

			arg_4_0:changeButtonState()
			arg_4_0:showEffect()
		end
	end)
	arg_4_0.nodeDetail:getChildByName("btn_wenchou"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_wenchou"):setScale(0.9)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_wenchou"):setScale(1)

			arg_4_0.btnState = var_0_4.wenchou

			arg_4_0:changeButtonState()
			arg_4_0:showEffect()
		end
	end)

	local var_4_0 = arg_4_0.nodeDetail:getChildByName("btn_rule")

	var_4_0:addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(var_4_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("skin_consume_rule")
		end
	end)

	local var_4_1 = arg_4_0.nodeDetail:getChildByName("btn_get")

	var_4_1:addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(var_4_1, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_4_0.activity.is_open == 1 and arg_4_0.details.award_str[arg_4_0.btnState] == 0 then
				local var_9_0 = var_0_2:vipLimit(arg_4_0.btnState)
				local var_9_1 = var_0_2:consume(arg_4_0.btnState)

				if var_9_0 > arg_4_0.selfPlayer.vip then
					local var_9_2 = string.format(var_0_1:translation("ACTIVITY_SKIN_CONSUME_TIPS3"), var_0_2:vipLimit(arg_4_0.btnState))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_9_2
					})
				elseif var_9_1 > arg_4_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_10_0 = {}

						var_10_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				else
					local var_9_3 = string.format(var_0_1:translation("ACTIVITY_SKIN_CONSUME_TIPS2"), var_9_1, var_0_2:name(arg_4_0.btnState))

					if arg_4_0.btnState == var_0_4.yanliang and arg_4_0.details.award_str[var_0_4.wenchou] == 0 or arg_4_0.btnState == var_0_4.wenchou and arg_4_0.details.award_str[var_0_4.yanliang] == 0 then
						var_9_3 = var_9_3 .. var_0_1:translation("ACTIVITY_SKIN_CONSUME_TIPS4")
					end

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_3, function()
						local var_11_0 = {
							activity_id = xyd.Activities.SkinConsume,
							award_id = arg_4_0.btnState
						}

						xyd.Backend.get():request(xyd.mid.ACTIVITY_1149_AWARD, var_11_0, function(arg_12_0, arg_12_1)
							if arg_12_0 == xyd.error.OK then
								arg_4_0.selfPlayer:handleRewards(arg_12_1.awards)

								local var_12_0 = {
									activity_id = xyd.Activities.SkinConsume
								}

								xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_12_0, function(arg_13_0, arg_13_1)
									if arg_13_0 == xyd.error.OK then
										arg_4_0.details = arg_13_1.details
										arg_4_0.alreadyInit = false

										arg_4_0:initDetails()
										arg_4_0:changeButtonState()
									end
								end)
							end
						end)
					end, nil, nil, xyd.ColorMode.ACTIVITY)
				end
			else
				local var_9_4

				if xyd.ServerTime.get():getServerTime() < arg_4_0.activity.start_time then
					var_9_4 = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_4_0.activity.end_time then
					var_9_4 = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_4
				})
			end
		end
	end)
end

function var_0_0.layout(arg_14_0)
	arg_14_0.yanliang = xyd.AssetLoader.get():loadSprite("windows/activities/1149/bg_person_left.png")
	arg_14_0.wenchou = xyd.AssetLoader.get():loadSprite("windows/activities/1149/bg_person_right.png")

	arg_14_0.nodeDetail:addChild(arg_14_0.yanliang)
	arg_14_0.yanliang:setAnchorPoint(cc.p(0, 0))
	arg_14_0.yanliang:setPosition(-280, 0)
	arg_14_0.yanliang:setLocalZOrder(-10)
	arg_14_0.yanliang:scale(var_0_6[arg_14_0.btnState].scale)
	arg_14_0.nodeDetail:addChild(arg_14_0.wenchou)
	arg_14_0.wenchou:setAnchorPoint(cc.p(0, 0))
	arg_14_0.wenchou:setPosition(223, 0)
	arg_14_0.wenchou:setLocalZOrder(-11)
	arg_14_0.wenchou:scale(var_0_7[arg_14_0.btnState].scale)
end

function var_0_0.changeButtonState(arg_15_0)
	arg_15_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(true)
	arg_15_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(true)
	arg_15_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(true)
	arg_15_0.nodeDetail:getChildByName("btn_cp"):setBrightStyle(ccui.BrightStyle.normal)
	arg_15_0.nodeDetail:getChildByName("btn_yanliang"):setBrightStyle(ccui.BrightStyle.normal)
	arg_15_0.nodeDetail:getChildByName("btn_wenchou"):setBrightStyle(ccui.BrightStyle.normal)

	if arg_15_0.btnState == var_0_4.cp then
		arg_15_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(false)
		arg_15_0.nodeDetail:getChildByName("btn_cp"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_15_0.btnState == var_0_4.yanliang then
		arg_15_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(false)
		arg_15_0.nodeDetail:getChildByName("btn_yanliang"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_15_0.btnState == var_0_4.wenchou then
		arg_15_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(false)
		arg_15_0.nodeDetail:getChildByName("btn_wenchou"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	local var_15_0 = var_0_2:gift(arg_15_0.btnState)
	local var_15_1 = xyd.tables.gift:items(var_15_0)
	local var_15_2 = xyd.tables.gift:itemNum(var_15_0)
	local var_15_3 = 1

	for iter_15_0 = 1, 4 do
		arg_15_0.awardContainer:getChildByName("award_container" .. tostring(iter_15_0)):removeAllChildren()
		arg_15_0.awardContainer:getChildByName("award_num_txt" .. tostring(iter_15_0)):setVisible(false)
	end

	for iter_15_1 = #var_15_1, 1, -1 do
		local var_15_4 = var_15_1[iter_15_1]
		local var_15_5 = var_15_2[iter_15_1]

		if var_15_3 <= 4 then
			xyd.setItemAndAddTips(arg_15_0.awardContainer:getChildByName("award_container" .. tostring(var_15_3)), var_15_4)
			arg_15_0.awardContainer:getChildByName("award_num_txt" .. tostring(var_15_3)):setVisible(true)
			arg_15_0.awardContainer:getChildByName("award_num_txt" .. tostring(var_15_3)):setString("x " .. tostring(var_15_5))
			arg_15_0.awardContainer:getChildByName("award_num_txt" .. tostring(var_15_3)):enableOutline(cc.c4b(174, 32, 0, 255), 1)

			var_15_3 = var_15_3 + 1
		end
	end

	arg_15_0.nodeDetail:getChildByName("txt_crystal_num"):setString(tostring(var_0_2:consume(arg_15_0.btnState)))
	arg_15_0.nodeDetail:getChildByName("txt_crystal_num"):enableOutline(cc.c4b(255, 177, 15, 255), 2)

	local var_15_6 = arg_15_0.nodeDetail:getChildByName("btn_get")
	local var_15_7 = arg_15_0.nodeDetail:getChildByName("already_get")

	if arg_15_0.details.award_str[arg_15_0.btnState] == 1 then
		var_15_6:setVisible(false)
		var_15_7:setVisible(true)
	elseif var_0_2:vipLimit(arg_15_0.btnState) > arg_15_0.selfPlayer.vip then
		var_15_6:setVisible(true)
		var_15_7:setVisible(false)
	else
		var_15_6:setVisible(true)
		var_15_7:setVisible(false)
	end
end

function var_0_0.showEffect(arg_16_0)
	local var_16_0 = cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_16_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(false)
			arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(false)
			arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(false)
		end),
		cc.Spawn:create({
			cc.MoveTo:create(var_0_3, cc.p(var_0_6[arg_16_0.btnState].x, var_0_6[arg_16_0.btnState].y)),
			cc.ScaleTo:create(var_0_3, var_0_6[arg_16_0.btnState].scale),
			cc.FadeTo:create(var_0_3, var_0_6[arg_16_0.btnState].fade)
		}),
		cc.CallFunc:create(function()
			arg_16_0:changeButtonState()
		end)
	})

	arg_16_0.yanliang:runActionOnce(var_16_0)

	local var_16_1 = cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_16_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(false)
			arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(false)
			arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(false)
		end),
		cc.Spawn:create({
			cc.MoveTo:create(var_0_3, cc.p(var_0_7[arg_16_0.btnState].x, var_0_7[arg_16_0.btnState].y)),
			cc.ScaleTo:create(var_0_3, var_0_7[arg_16_0.btnState].scale),
			cc.FadeTo:create(var_0_3, var_0_7[arg_16_0.btnState].fade)
		}),
		cc.CallFunc:create(function()
			arg_16_0:changeButtonState()
		end)
	})

	arg_16_0.wenchou:runActionOnce(var_16_1)
end

return var_0_0
