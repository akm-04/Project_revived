local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityHotSpring2
local var_0_3 = xyd.tables.gift
local var_0_4 = {
	195,
	345,
	45,
	495
}
local var_0_5 = 0.8
local var_0_6 = {
	yanliang = 1,
	wenchou = 3,
	cp = 2
}
local var_0_7 = {
	{
		fade = 255,
		scale = 1.1,
		x = 50,
		y = -50
	},
	{
		fade = 255,
		scale = 1,
		x = -220,
		y = 0
	},
	{
		fade = 0,
		scale = 0.85,
		x = -50,
		y = 0
	}
}
local var_0_8 = {
	{
		fade = 0,
		scale = 0.85,
		x = 150,
		y = 0
	},
	{
		fade = 255,
		scale = 1,
		x = 350,
		y = 0
	},
	{
		fade = 255,
		scale = 1.1,
		x = 150,
		y = 0
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.alreadyInit = false

	dump(arg_1_0.activity)
end

function var_0_0.initDetails(arg_2_0)
	if arg_2_0.alreadyInit then
		return
	end

	for iter_2_0, iter_2_1 in pairs(var_0_6) do
		if not arg_2_0.details.award_str[iter_2_1] then
			arg_2_0.details.award_str[iter_2_1] = 0
		end
	end

	arg_2_0.alreadyInit = true
	arg_2_0.canGetState = clone(arg_2_0.details.award_str)

	for iter_2_2, iter_2_3 in pairs(arg_2_0.canGetState) do
		arg_2_0.canGetState[iter_2_2] = 1
	end

	for iter_2_4, iter_2_5 in pairs(arg_2_0.details.award_str) do
		if iter_2_5 == 1 then
			arg_2_0.details.charge = arg_2_0.details.charge - var_0_2:charge(iter_2_4)
			arg_2_0.canGetState[iter_2_4] = 0

			for iter_2_6, iter_2_7 in pairs(var_0_2:exclude(iter_2_4)) do
				arg_2_0.canGetState[iter_2_7] = 0
			end
		end
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
	arg_3_0.btnState = var_0_6.cp

	arg_3_0:initDetails()
	arg_3_0:setButtonClick()
	arg_3_0:changeButtonState()
	arg_3_0:layout()
	arg_3_0.nodeDetail:getChildByName("btn_cp"):getChildByName("txt_cp"):setString(var_0_1:translation("ACTIVITY_1231_MID"))
	arg_3_0.nodeDetail:getChildByName("btn_yanliang"):getChildByName("txt_yanliang"):setString(var_0_1:translation("ACTIVITY_1231_LEFT"))
	arg_3_0.nodeDetail:getChildByName("btn_wenchou"):getChildByName("txt_wenchou"):setString(var_0_1:translation("ACTIVITY_1231_RIGHT"))
	arg_3_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_charge"):setString(var_0_1:translation("VIP_RECHARGE"))
	arg_3_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_get"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT1"))
	arg_3_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_already_get"):setString(var_0_1:translation("ACTIVITY_COMMON_TEXT2"))
	arg_3_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_cannot_get"):setString(var_0_1:translation("MAP_BUY"))
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0.nodeDetail:getChildByName("btn_rule"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_rule"):setScale(0.9)
		end

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_rule"):setScale(1)

			local var_5_0 = {
				title_name = "ACTIVITY_1231_RULE_1",
				rule = "ACTIVITY_1231_RULE_2"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
		end
	end)
	arg_4_0.nodeDetail:getChildByName("btn_cp"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_cp"):setScale(0.9)
		end

		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_cp"):setScale(1)

			arg_4_0.btnState = var_0_6.cp

			arg_4_0:changeButtonState()
			arg_4_0:showEffect()
		end
	end)
	arg_4_0.nodeDetail:getChildByName("btn_yanliang"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_yanliang"):setScale(0.9)
		end

		if arg_7_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_yanliang"):setScale(1)

			arg_4_0.btnState = var_0_6.yanliang

			arg_4_0:changeButtonState()
			arg_4_0:showEffect()
		end
	end)
	arg_4_0.nodeDetail:getChildByName("btn_wenchou"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			arg_4_0.nodeDetail:getChildByName("btn_wenchou"):setScale(0.9)
		end

		if arg_8_1 == ccui.TouchEventType.ended then
			arg_4_0.nodeDetail:getChildByName("btn_wenchou"):setScale(1)

			arg_4_0.btnState = var_0_6.wenchou

			arg_4_0:changeButtonState()
			arg_4_0:showEffect()
		end
	end)
	arg_4_0.nodeDetail:getChildByName("btn_get"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_4_0.activity.is_open == 1 then
				if arg_4_0.details.award_str[arg_4_0.btnState] == 0 and arg_4_0.canGetState[arg_4_0.btnState] == 1 and arg_4_0.details.charge < var_0_2:charge(arg_4_0.btnState) then
					local var_9_0 = {}

					var_9_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
				elseif arg_4_0.details.award_str[arg_4_0.btnState] == 0 and arg_4_0.canGetState[arg_4_0.btnState] == 1 and arg_4_0.details.charge >= var_0_2:charge(arg_4_0.btnState) then
					if arg_4_0.btnState == var_0_6.yanliang and arg_4_0.details.award_str[var_0_6.wenchou] == 0 or arg_4_0.btnState == var_0_6.wenchou and arg_4_0.details.award_str[var_0_6.yanliang] == 0 then
						local var_9_1

						if arg_4_0.btnState == var_0_6.yanliang then
							var_9_1 = string.format(var_0_1:translation("HOT_SPRING_CONFIRM"), var_0_2:name(var_0_6.yanliang), var_0_2:name(var_0_6.wenchou))
						else
							var_9_1 = string.format(var_0_1:translation("HOT_SPRING_CONFIRM"), var_0_2:name(var_0_6.wenchou), var_0_2:name(var_0_6.yanliang))
						end

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_1, function()
							local var_10_0 = {
								activity_id = arg_4_0.activity.table_id,
								award_id = arg_4_0.btnState
							}

							xyd.Backend.get():request(xyd.mid.ACTIVITY_1231_AWARD, var_10_0, function(arg_11_0, arg_11_1)
								if arg_11_0 == xyd.error.OK then
									arg_4_0.selfPlayer:handleRewards(arg_11_1.awards)

									local var_11_0 = {
										activity_id = arg_4_0.activity.table_id
									}

									xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_11_0, function(arg_12_0, arg_12_1)
										if arg_12_0 == xyd.error.OK then
											arg_4_0.details = arg_12_1.details
											arg_4_0.alreadyInit = false

											arg_4_0:initDetails()
											arg_4_0:changeButtonState()
										end
									end)
								end
							end)
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					else
						local var_9_2 = {
							activity_id = arg_4_0.activity.table_id,
							award_id = arg_4_0.btnState
						}

						xyd.Backend.get():request(xyd.mid.ACTIVITY_1231_AWARD, var_9_2, function(arg_13_0, arg_13_1)
							if arg_13_0 == xyd.error.OK then
								arg_4_0.selfPlayer:handleRewards(arg_13_1.awards)

								local var_13_0 = {
									activity_id = arg_4_0.activity.table_id
								}

								xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_13_0, function(arg_14_0, arg_14_1)
									if arg_14_0 == xyd.error.OK then
										arg_4_0.details = arg_14_1.details
										arg_4_0.alreadyInit = false

										arg_4_0:initDetails()
										arg_4_0:changeButtonState()
									end
								end)
							end
						end)
					end
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_4_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_4_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)
end

function var_0_0.layout(arg_15_0)
	arg_15_0.yanliang = xyd.AssetLoader.get():loadSprite("windows/activities/1231/michael.png")
	arg_15_0.wenchou = xyd.AssetLoader.get():loadSprite("windows/activities/1231/lucifer.png")

	arg_15_0.nodeDetail:addChild(arg_15_0.yanliang)
	arg_15_0.yanliang:setAnchorPoint(cc.p(0, 0))
	arg_15_0.yanliang:setPosition(-220, 0)
	arg_15_0.yanliang:setLocalZOrder(-11)
	arg_15_0.yanliang:scale(var_0_7[arg_15_0.btnState].scale)
	arg_15_0.nodeDetail:addChild(arg_15_0.wenchou)
	arg_15_0.wenchou:setAnchorPoint(cc.p(0, 0))
	arg_15_0.wenchou:setPosition(350, 0)
	arg_15_0.wenchou:setLocalZOrder(-10)
	arg_15_0.wenchou:scale(var_0_8[arg_15_0.btnState].scale)
end

function var_0_0.changeButtonState(arg_16_0)
	if arg_16_0.btnState == var_0_6.cp then
		arg_16_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(false)
		arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_cp"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setBrightStyle(ccui.BrightStyle.normal)
		arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_16_0.btnState == var_0_6.yanliang then
		arg_16_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(false)
		arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_cp"):setBrightStyle(ccui.BrightStyle.normal)
		arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setBrightStyle(ccui.BrightStyle.normal)
	elseif arg_16_0.btnState == var_0_6.wenchou then
		arg_16_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(false)
		arg_16_0.nodeDetail:getChildByName("btn_cp"):setBrightStyle(ccui.BrightStyle.normal)
		arg_16_0.nodeDetail:getChildByName("btn_yanliang"):setBrightStyle(ccui.BrightStyle.normal)
		arg_16_0.nodeDetail:getChildByName("btn_wenchou"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	arg_16_0.nodeDetail:getChildByName("text"):getChildByName("charge_num"):setString(tostring(var_0_2:charge(arg_16_0.btnState)))

	if arg_16_0.details.award_str[arg_16_0.btnState] == 1 then
		arg_16_0.nodeDetail:getChildByName("btn_get"):setTouchEnabled(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):setBright(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_already_get"):setVisible(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_cannot_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_charge"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("text"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("bar"):setVisible(true)
		arg_16_0:initBar(1)
		arg_16_0:initItems()
	elseif arg_16_0.canGetState[arg_16_0.btnState] == 1 and arg_16_0.details.charge >= var_0_2:charge(arg_16_0.btnState) then
		arg_16_0.nodeDetail:getChildByName("btn_get"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):setBright(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_get"):setVisible(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_already_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_cannot_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_charge"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("text"):setVisible(true)
		arg_16_0.nodeDetail:getChildByName("bar"):setVisible(true)
		arg_16_0:initBar()
		arg_16_0:initItems()
	elseif arg_16_0.canGetState[arg_16_0.btnState] == 1 and arg_16_0.details.charge < var_0_2:charge(arg_16_0.btnState) then
		arg_16_0.nodeDetail:getChildByName("btn_get"):setTouchEnabled(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):setBright(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_already_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_cannot_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_charge"):setVisible(true)
		arg_16_0.nodeDetail:getChildByName("text"):setVisible(true)
		arg_16_0.nodeDetail:getChildByName("bar"):setVisible(true)
		arg_16_0:initBar()
		arg_16_0:initItems()
	else
		arg_16_0.nodeDetail:getChildByName("btn_get"):setTouchEnabled(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):setBright(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_already_get"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_cannot_get"):setVisible(true)
		arg_16_0.nodeDetail:getChildByName("btn_get"):getChildByName("txt_charge"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("text"):setVisible(false)
		arg_16_0.nodeDetail:getChildByName("bar"):setVisible(false)
		arg_16_0:initItems()
	end
end

function var_0_0.initBar(arg_17_0, arg_17_1)
	if arg_17_1 then
		arg_17_0.nodeDetail:getChildByName("bar"):setVisible(false)
	else
		arg_17_0.nodeDetail:getChildByName("bar"):setVisible(true)
		arg_17_0.nodeDetail:getChildByName("bar"):getChildByName("bar_text"):setVisible(true)

		if arg_17_0.details.charge > var_0_2:charge(arg_17_0.btnState) then
			arg_17_0.nodeDetail:getChildByName("bar"):getChildByName("charge_bar"):setPercent(100)
		else
			arg_17_0.nodeDetail:getChildByName("bar"):getChildByName("charge_bar"):setPercent(arg_17_0.details.charge / var_0_2:charge(arg_17_0.btnState) * 100)
		end

		arg_17_0.nodeDetail:getChildByName("bar"):getChildByName("bar_text"):setString(arg_17_0.details.charge .. "/" .. var_0_2:charge(arg_17_0.btnState))
	end
end

function var_0_0.initItems(arg_18_0)
	local var_18_0 = arg_18_0.nodeDetail:getChildByName("item")
	local var_18_1 = var_0_2:getGift(arg_18_0.btnState)
	local var_18_2 = var_0_3:items(var_18_1)
	local var_18_3 = var_0_3:itemNum(var_18_1)

	var_18_0:removeAllChildren()

	for iter_18_0, iter_18_1 in ipairs(var_18_2) do
		local var_18_4 = display.newNode()

		var_18_4:setContentSize(86, 86)
		xyd.setItemAndAddTips(var_18_4, iter_18_1)
		var_18_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_18_4:setPosition(cc.p(var_0_4[iter_18_0], 75))
		var_18_4:addTo(var_18_0)

		local var_18_5 = {
			size = 24,
			color = cc.c3b(255, 255, 255)
		}
		local var_18_6 = xyd.AssetLoader.get():loadLabel(var_18_5)

		var_18_6:setString("x " .. var_18_3[iter_18_0])
		var_18_6:addTo(var_18_0)
		var_18_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_18_6:setPosition(var_0_4[iter_18_0], 10)
		var_18_6:enableOutline(cc.c4b(162, 103, 235, 255), 2)
	end
end

function var_0_0.showEffect(arg_19_0)
	local var_19_0 = cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_19_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(false)
			arg_19_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(false)
			arg_19_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(false)
		end),
		cc.Spawn:create({
			cc.MoveTo:create(var_0_5, cc.p(var_0_7[arg_19_0.btnState].x, var_0_7[arg_19_0.btnState].y)),
			cc.ScaleTo:create(var_0_5, var_0_7[arg_19_0.btnState].scale),
			cc.FadeTo:create(var_0_5, var_0_7[arg_19_0.btnState].fade)
		}),
		cc.CallFunc:create(function()
			arg_19_0:changeButtonState()
		end)
	})

	arg_19_0.yanliang:runActionOnce(var_19_0)

	local var_19_1 = cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_19_0.nodeDetail:getChildByName("btn_cp"):setTouchEnabled(false)
			arg_19_0.nodeDetail:getChildByName("btn_yanliang"):setTouchEnabled(false)
			arg_19_0.nodeDetail:getChildByName("btn_wenchou"):setTouchEnabled(false)
		end),
		cc.Spawn:create({
			cc.MoveTo:create(var_0_5, cc.p(var_0_8[arg_19_0.btnState].x, var_0_8[arg_19_0.btnState].y)),
			cc.ScaleTo:create(var_0_5, var_0_8[arg_19_0.btnState].scale),
			cc.FadeTo:create(var_0_5, var_0_8[arg_19_0.btnState].fade)
		}),
		cc.CallFunc:create(function()
			arg_19_0:changeButtonState()
		end)
	})

	arg_19_0.wenchou:runActionOnce(var_19_1)
end

return var_0_0
