local var_0_0 = class("GardenSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityGardenFlower
local var_0_3 = import("framework.scheduler")
local var_0_4 = "skeletons/ui_effect/garden/activity_garden1"
local var_0_5 = "skeletons/ui_effect/garden/activity_garden2"
local var_0_6 = "skeletons/ui_effect/garden/activity_garden3"
local var_0_7 = "skeletons/ui_effect/garden/activity_garden4"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.selectLandId = arg_1_2.selectLandId
	arg_1_0.position = arg_1_2.position
	arg_1_0.landItem = arg_1_2.landItem
	arg_1_0.details = arg_1_0.garden.details
	arg_1_0.playerInfo = arg_1_0.details.np_info
	arg_1_0.isSelfGarden = arg_1_0.garden:isSelfGarden()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:nodeByName("container"):setPosition(arg_2_0.position)
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initSelectContainer()
	arg_3_0:udpateSelectInfo()
	arg_3_0:nodeByName("fertilize_tip_txt"):enableOutline(xyd.color.FONT_OUTLINE_A, 2)
	arg_3_0:nodeByName("fertilize_tip_txt"):setString(var_0_1:translation("GARDEN_FEED_TIP"))
end

function var_0_0.udpateSelectInfo(arg_4_0, ...)
	if arg_4_0.details.field_info[arg_4_0.selectLandId].thirsty_time < xyd.ServerTime.get():getServerTime() then
		arg_4_0:nodeByName("water_gray"):setVisible(false)
	else
		arg_4_0:nodeByName("water_gray"):setVisible(true)
	end

	if not arg_4_0.isSelfGarden then
		arg_4_0:nodeByName("feed_bg"):setVisible(false)
		arg_4_0:nodeByName("delete_bg"):setVisible(false)
	else
		arg_4_0:nodeByName("feed_bg"):setVisible(true)
		arg_4_0:nodeByName("delete_bg"):setVisible(true)
	end

	arg_4_0:updateFertilizeNum()
end

function var_0_0.updateFertilizeNum(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1 or 0
	local var_5_1 = arg_5_0.backpack:getItemNumByID(xyd.tables.misc.activityGardenFertilizeItem)

	if var_5_1 < var_5_0 then
		var_5_0 = var_5_1
	end

	arg_5_0:nodeByName("fertilize_num_txt"):setString("X" .. var_5_1 - var_5_0)

	if var_5_1 <= var_5_0 then
		arg_5_0:nodeByName("fertilize_num_txt"):setVisible(true)
		arg_5_0:nodeByName("fertilize_gray"):setVisible(true)
		arg_5_0:nodeByName("fertilize"):setVisible(false)
	else
		arg_5_0:nodeByName("fertilize_num_txt"):setVisible(true)
		arg_5_0:nodeByName("fertilize_gray"):setVisible(false)
		arg_5_0:nodeByName("fertilize"):setVisible(true)
	end
end

function var_0_0.initSelectContainer(arg_6_0)
	local var_6_0 = arg_6_0.details.field_info[arg_6_0.selectLandId]

	if not arg_6_0.selectEffect then
		local var_6_1 = xyd.createEffect(var_0_5)

		var_6_1:addTo(arg_6_0)
		var_6_1:play(nil, true)

		arg_6_0.selectEffect = var_6_1

		arg_6_0.selectEffect:setVisible(false)
	end

	if not arg_6_0.waterEffect then
		local var_6_2 = xyd.createEffect(var_0_6)

		var_6_2:addTo(arg_6_0)

		arg_6_0.waterEffect = var_6_2

		arg_6_0.waterEffect:setVisible(false)
	end

	if not arg_6_0.feedEffect then
		local var_6_3 = xyd.createEffect(var_0_4)

		var_6_3:addTo(arg_6_0)

		arg_6_0.feedEffect = var_6_3

		arg_6_0.feedEffect:setVisible(false)
	end

	xyd.GrayNode(arg_6_0:nodeByName("water_gray"))
	arg_6_0:nodeByName("water_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if var_6_0.thirsty_time > xyd.ServerTime.get():getServerTime() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GARDEN_PLANT_TIP6")
				})

				return
			end

			var_6_0.is_locked = true

			local var_7_0 = arg_6_0.selectLandId
			local var_7_1 = {
				field_id = var_7_0,
				player_id = arg_6_0.playerInfo.player_id
			}

			arg_6_0.garden:gardenWater(var_7_1, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = arg_6_0.position
					local var_8_1 = xyd.addPosition(var_8_0, cc.p(22, 176))

					arg_6_0.waterEffect:setVisible(true)
					arg_6_0.waterEffect:setPosition(var_8_1)
					arg_6_0:nodeByName("container"):setVisible(false)
					arg_6_0.waterEffect:play(function()
						if arg_6_0 and not tolua.isnull(arg_6_0) then
							arg_6_0.waterEffect:setVisible(false)

							var_6_0.is_locked = false

							var_0_3.performWithDelayGlobal(function()
								xyd.WindowManager.get():closeWindow("garden_select")
							end, 0.1)
						end
					end, false)
				end
			end)
		end
	end)

	local function var_6_4(arg_11_0)
		if arg_11_0 <= 0 then
			var_6_0.is_locked = false

			local var_11_0 = var_0_1:translation("GARDEN_PLANT_TIP17")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_0, function()
				xyd.WindowManager.get():openWindow("garden_flower_shop")
				xyd.WindowManager.get():closeWindow(arg_6_0)
			end, nil, nil, arg_6_0.colorMode)

			return
		end

		local var_11_1 = arg_6_0.selectLandId
		local var_11_2 = {
			field_id = var_11_1,
			player_id = arg_6_0.selfPlayer.playerID,
			nums = arg_11_0
		}

		var_6_0.is_locked = true

		arg_6_0.garden:gardenFertilize(var_11_2, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				local var_13_0 = {
					itemID = xyd.tables.misc.activityGardenFertilizeItem,
					itemNum = arg_13_1.cost_num or var_11_2.nums
				}

				arg_6_0.backpack:removeItem(var_13_0)

				local var_13_1 = arg_6_0.position
				local var_13_2 = xyd.addPosition(var_13_1, cc.p(202, 176))

				arg_6_0.feedEffect:setVisible(true)
				arg_6_0.feedEffect:setPosition(var_13_2)
				arg_6_0:nodeByName("container"):setVisible(false)
				arg_6_0.feedEffect:play(function(...)
					if arg_6_0 and not tolua.isnull(arg_6_0) then
						arg_6_0.feedEffect:setVisible(false)

						var_6_0.is_locked = false

						var_0_3.performWithDelayGlobal(function()
							xyd.WindowManager.get():closeWindow("garden_select")
						end, 0.1)
					end
				end, false)
			end
		end)
	end

	local var_6_5 = 1

	xyd.GrayNode(arg_6_0:nodeByName("fertilize_gray"))
	arg_6_0:nodeByName("feed_btn"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			local var_16_0 = 0

			var_6_5 = 1

			local function var_16_1()
				var_6_0.is_locked = true

				if not arg_6_0 or not arg_6_0.nodeByName then
					if longTouchHandler then
						var_0_3.unscheduleGlobal(longTouchHandler)

						longTouchHandler = nil
					end

					return
				end

				var_16_0 = var_16_0 + 0.2

				local var_17_0 = arg_6_0.selectLandId

				if var_16_0 >= 0.4 then
					local var_17_1 = arg_6_0.backpack:getItemNumByID(xyd.tables.misc.activityGardenFertilizeItem)

					if var_6_0.end_time - 600 * xyd.tables.misc.activityGardenFertilizeTime * var_6_5 <= xyd.ServerTime.get():getServerTime() or var_17_1 <= var_6_5 then
						var_6_5 = var_6_5 - 1

						if longTouchHandler then
							var_0_3.unscheduleGlobal(longTouchHandler)

							longTouchHandler = nil
						end
					end

					if var_17_1 > var_6_5 then
						var_6_5 = var_6_5 + 1

						local var_17_2 = var_6_0.end_time - 600 * xyd.tables.misc.activityGardenFertilizeTime * var_6_5

						arg_6_0:playDecreaseTime(arg_6_0:nodeByName("feed_bg"), xyd.tables.misc.activityGardenFertilizeTime)
						arg_6_0:updateLandTime(arg_6_0.landItem, var_17_2, var_6_0)
						arg_6_0:updateFertilizeNum(var_6_5)
					end
				end
			end

			longTouchHandler = var_0_3.scheduleGlobal(var_16_1, 0.2)
		elseif arg_16_1 == ccui.TouchEventType.ended or arg_16_1 == ccui.TouchEventType.canceled then
			if longTouchHandler then
				var_0_3.unscheduleGlobal(longTouchHandler)

				longTouchHandler = nil
			end

			if arg_6_0.backpack:getItemNumByID(xyd.tables.misc.activityGardenFertilizeItem) <= var_6_5 then
				var_6_5 = arg_6_0.backpack:getItemNumByID(xyd.tables.misc.activityGardenFertilizeItem)
			end

			var_6_4(var_6_5)
		end
	end)
	arg_6_0:nodeByName("delete_btn"):setGlobalZOrder(1000)
	arg_6_0:nodeByName("delete_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_18_0 = arg_6_0.selectLandId
			local var_18_1 = arg_6_0.details.field_info[var_18_0]
			local var_18_2 = string.format(var_0_1:translation("GARDEN_PLANT_TIP7"), var_18_0, var_0_2:name(var_18_1.sei))

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_18_2, function()
				local var_19_0 = {
					field_id = var_18_0
				}

				arg_6_0.garden:gardenDug(var_19_0, function(arg_20_0, arg_20_1)
					if arg_20_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_6_0)
					end
				end)
			end, nil, nil, arg_6_0.colorMode)
		end
	end)
end

function var_0_0.playDecreaseTime(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = xyd.createLabel(24, cc.c3b(253, 255, 0))

	var_21_0:setString("-" .. string.format(var_0_1:translation("GARDEN_TIME_DECREASE_TIP"), arg_21_2 * 10))
	var_21_0:addTo(arg_21_1)
	var_21_0:setPosition(cc.p(10, 70))
	var_21_0:enableShadow()

	local var_21_1 = 0
	local var_21_2 = xyd.tables.battleConfig.floatAnimationDuration
	local var_21_3 = xyd.tables.battleConfig.floatAnimationDeltaY
	local var_21_4 = xyd.tables.battleConfig.floatFadeOutDelay
	local var_21_5 = cc.Spawn:create({
		cc.MoveBy:create(var_21_2, cc.p(0, 100)),
		cc.Sequence:create({
			cc.DelayTime:create(var_21_4),
			cc.FadeOut:create(var_21_2 - var_21_4)
		})
	})

	var_21_0:runActionOnce(var_21_5, true, nil, var_21_1)
end

function var_0_0.updateLandTime(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	local var_22_0 = arg_22_1:getChildByName("container"):getChildByName("state_container")

	if arg_22_3 and arg_22_3.status == 1 then
		var_22_0:setVisible(true)

		local var_22_1 = arg_22_2 - xyd.ServerTime.get():getServerTime()

		if var_22_1 < 0 then
			var_22_1 = 0
		end

		var_22_0:getChildByName("state_text"):setString(xyd.secondsToString(var_22_1))
	end
end

function var_0_0.didClose(arg_23_0, arg_23_1)
	var_0_0.super:didClose(arg_23_1)

	arg_23_0.details.field_info[arg_23_0.selectLandId].is_locked = false

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_GARDEN_INFO
	})
end

return var_0_0
