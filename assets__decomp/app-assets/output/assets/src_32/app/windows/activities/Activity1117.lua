local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.is_open = arg_1_0.activity.is_open or 0
	arg_1_0.startTime = arg_1_0.activity.start_time
	arg_1_0.endTime = arg_1_0.activity.end_time
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	arg_2_0.serverTime = xyd.ServerTime.get():getServerTime()

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.detail = var_2_0

	local var_2_1 = var_2_0:getChildByName("container"):getChildByName("bg_desc"):getChildByName("desc")

	var_2_1:setString(var_0_1:translation("ANNI2_TIPS_TXT18"))
	var_2_1:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_2_0:registerButtons()
	arg_2_0:initItems()
end

function var_0_0.checkActivityNotOpen(arg_3_0)
	if arg_3_0.is_open == 0 then
		local var_3_0 = ""

		if arg_3_0.startTime > arg_3_0.serverTime then
			var_3_0 = var_0_1:translation("ACTIVITY_NO_OPEN")
		elseif arg_3_0.endTime < arg_3_0.serverTime then
			var_3_0 = var_0_1:translation("ACTIVITY_FINISHED")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_3_0
		})

		return true
	end
end

function var_0_0.registerButtons(arg_4_0)
	local var_4_0 = arg_4_0.detail:getChildByName("container")
	local var_4_1 = var_4_0:getChildByName("give_btn")

	var_4_1:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			var_4_1:setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.canceled then
			var_4_1:setScale(1)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			var_4_1:setScale(1)

			if arg_4_0:checkActivityNotOpen() then
				return
			end

			xyd.WindowManager.get():openWindow("two_years_give_alert")
		end
	end)
	var_4_1:getChildByName("txt"):setString(var_0_1:translation("ACTIVITY_PRESENT_POINT"))

	local var_4_2 = var_4_0:getChildByName("compose_btn")

	var_4_2:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_2:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.canceled then
			var_4_2:setScale(1)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_4_2:setScale(1)

			if arg_4_0:checkActivityNotOpen() then
				return
			end

			local var_6_0, var_6_1 = arg_4_0:checkCompose()

			if #var_6_0 == 0 then
				-- block empty
			else
				local var_6_2 = ""

				for iter_6_0, iter_6_1 in ipairs(var_6_0) do
					var_6_2 = var_6_2 .. xyd.tables.item:name(iter_6_1)

					if iter_6_0 < #var_6_0 then
						var_6_2 = var_6_2 .. "，"
					end
				end

				local var_6_3 = string.format(var_0_1:translation("ANNI2_TIPS_TXT30"), var_6_1, var_6_2)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_3, function()
					if arg_4_0.selfPlayer.mana < var_6_1 then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("JINBI_ABSENCE"), function()
							local var_8_0 = xyd.FunctionID.ID_GOLD_HAND

							if arg_4_0.selfPlayer:isFuncOpen(var_8_0) == true then
								xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
							else
								local var_8_1 = xyd.tables.functionOpen:level(var_8_0)
								local var_8_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_8_1)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_8_2
								})
							end
						end, nil, nil, xyd.ColorMode.ACTIVITY)
					else
						local var_7_0 = 0
						local var_7_1 = {}

						for iter_7_0, iter_7_1 in pairs(var_6_0) do
							arg_4_0.selfPlayer:makeItem({
								item_id = iter_7_1,
								item_num = var_0_2
							}, function()
								arg_4_0:initItems()

								var_7_0 = var_7_0 + 1

								local var_9_0 = {
									item_num = 1,
									table_id = iter_7_1
								}

								table.insert(var_7_1, var_9_0)

								if var_7_0 == #var_6_0 then
									xyd.WindowManager.get():openWindow("alert_award", {
										awards = var_7_1
									})
								end
							end)
						end
					end
				end, nil, 0, xyd.ColorMode.ACTIVITY)
			end
		end
	end)
	var_4_2:getChildByName("txt"):setString(var_0_1:translation("AUTO_COMPOSE"))
end

function var_0_0.checkCompose(arg_10_0)
	local var_10_0 = xyd.tables.misc.twoYearspresentItem
	local var_10_1 = {}
	local var_10_2 = 0

	for iter_10_0, iter_10_1 in pairs(var_10_0) do
		local var_10_3 = xyd.tables.item:composeItem(iter_10_1)
		local var_10_4 = xyd.tables.item:composeMana(iter_10_1)

		if arg_10_0.selfPlayer:getBackpack():getItemNumByID(iter_10_1) >= xyd.tables.item:itemNum(iter_10_1) and xyd.tables.item:itemNum(iter_10_1) ~= 0 then
			table.insert(var_10_1, var_10_3)

			var_10_2 = var_10_2 + var_10_4
		end
	end

	return var_10_1, var_10_2
end

function var_0_0.initItems(arg_11_0)
	local var_11_0 = arg_11_0.detail:getChildByName("container"):getChildByName("bg_list")
	local var_11_1 = xyd.tables.misc.twoYearspresentItem

	for iter_11_0, iter_11_1 in pairs(var_11_1) do
		local var_11_2 = var_11_0:getChildByName("item" .. iter_11_0)
		local var_11_3 = var_11_0:getChildByName("item_desc" .. iter_11_0)

		var_11_2:setAnchorPoint(0.5, 0.5)
		var_11_2:setContentSize(70, 70)
		var_11_2:removeAllChildren()
		xyd.setItemBorder(var_11_2, iter_11_1)

		local var_11_4 = arg_11_0.selfPlayer:getBackpack():getItemNumByID(iter_11_1)

		var_11_3:setString(xyd.tables.item:name(iter_11_1) .. " x " .. var_11_4)
	end
end

function var_0_0.release(arg_12_0)
	if arg_12_0.handle then
		scheduler.unscheduleGlobal(arg_12_0.handle)

		arg_12_0.handle = nil
	end
end

return var_0_0
