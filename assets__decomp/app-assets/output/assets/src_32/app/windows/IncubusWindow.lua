local var_0_0 = class("IncubusWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.incubusTable
local var_0_3 = xyd.tables.hero

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.ids = var_0_2:id_list()
	arg_1_0.moreIds = {}

	for iter_1_0 = 4, #arg_1_0.ids do
		table.insert(arg_1_0.moreIds, arg_1_0.ids[iter_1_0])
	end

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.incubus = xyd.ModelManager.get():loadModel(xyd.ModelType.INCUBUS)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layOut()
end

function var_0_0.layOut(arg_3_0)
	arg_3_0:nodeByName("close_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			audio.playSound(xyd.tables.sound:getSound("ui_close_window"), false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("top_txt"):setString(var_0_1:translation("INCUBUS_TITLE"))
	arg_3_0:nodeByName("time_txt"):setString("")
	arg_3_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_gacha_rule", {
				rule = "INCUBUS_RULE",
				title = "INCUBUS_RULE_TITLE"
			})
		end
	end)
	arg_3_0:nodeByName("add_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if xyd.tables.vip:incubusReset(arg_3_0.player.vip) <= arg_3_0.incubus.buyPre then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_1:translation("INCUBUS_RESET_TIMES2"), arg_3_0.incubus.buyPre),
					var_0_1:translation("INCUBUS_RESET_VIP")
				}, function()
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
						windowState = false
					})
				end, {
					rightName = var_0_1:translation("CHECK_PRIVILEGE")
				}, nil, nil, arg_3_0.colorMode)

				return
			end

			local var_6_0 = xyd.tables.refreshCost:incubusBuyCost(arg_3_0.incubus.buyPre + 1)

			if var_6_0 > arg_3_0.player.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_8_0 = {}

					var_8_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_8_0)
				end, nil, nil, arg_3_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_1:translation("INCUBUS_RESET"), var_6_0),
					var_0_1:translation("SWEEP_ITEM_CONTINUE") .. string.format(var_0_1:translation("MAP_RESET_TIMES"), arg_3_0.incubus.buyPre)
				}, function()
					arg_3_0.incubus:buyTimes(function()
						arg_3_0:updateTimes()
					end)
				end, nil, nil, arg_3_0.colorMode)
			end
		end
	end)
	arg_3_0.incubus:loadIncubusInfos(function()
		arg_3_0:updateTimes()
	end)
	arg_3_0:update()

	local var_3_0 = arg_3_0:nodeByName("more_btn")

	if #arg_3_0.moreIds > 0 then
		var_3_0:addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():openWindow("incubus_more", {
					ids = arg_3_0.moreIds
				})
			end
		end)
	else
		var_3_0:setVisible(false)
	end
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	var_0_0.super:didOpen(arg_13_1)
end

function var_0_0.update(arg_14_0)
	for iter_14_0 = 1, 3 do
		local var_14_0 = arg_14_0.ids[iter_14_0]

		if not var_14_0 then
			arg_14_0:nodeByName("monster" .. iter_14_0):setVisible(false)
		else
			arg_14_0:nodeByName("monster" .. iter_14_0):setVisible(true)

			local var_14_1 = xyd.HeroAnimation.new(nil, var_0_3:modelID(var_0_2:hero(var_14_0)), 1, {})

			var_14_1:addTo(arg_14_0:nodeByName("monster" .. iter_14_0))
			var_14_1:setScale(0.7)
			var_14_1:idle(true)
			arg_14_0:nodeByName("name_txt" .. iter_14_0):loadTexture("windows/incubus/text/" .. var_0_2:name(var_14_0))

			local var_14_2 = arg_14_0:nodeByName("monster_click" .. iter_14_0)

			var_14_2:setTouchEnabled(true)
			var_14_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
				if arg_15_0.name == "began" then
					return true
				elseif arg_15_0.name == "ended" then
					if arg_14_0.incubus.times < 1 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TRIAL_NO_TIMES_LEFT")
						})

						return
					end

					xyd.WindowManager.get():openWindow("incubus_detail", {
						id = var_14_0
					})
				end
			end)
		end
	end
end

function var_0_0.updateTimes(arg_16_0)
	arg_16_0:nodeByName("time_txt"):setString(string.format(var_0_1:translation("INCUBUS_LEFT_TIMES"), arg_16_0.incubus.times, 3))

	if arg_16_0.incubus.times > 0 then
		arg_16_0:nodeByName("add_btn"):setVisible(false)
	else
		arg_16_0:nodeByName("add_btn"):setVisible(true)
	end
end

return var_0_0
