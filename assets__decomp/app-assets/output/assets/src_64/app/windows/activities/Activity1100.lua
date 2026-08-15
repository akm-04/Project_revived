local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.activitySqRaffleCGift
local var_0_5 = 161
local var_0_6 = 114
local var_0_7 = {
	x = 161,
	y = 114
}
local var_0_8 = {
	Normal = 25
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.isAwards = xyd.splitToNumber(arg_1_0.activity.details.is_awards, "|")
	arg_1_0.items = {}
	arg_1_0.raffleType = var_0_8.Normal
	arg_1_0.selectedEffectS = {}
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("bg")
	arg_2_0.startPos = arg_2_0.container:getChildByName("start_pos")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.centre = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1100/centre_item.csb")

	arg_3_0.centre:addTo(arg_3_0.startPos)

	local var_3_0 = arg_3_0.centre:getChildByName("container")

	var_3_0:getChildByName("lucky_value_desc"):setString(var_0_2:translation("LUCKY_VALUE_DESC"))
	var_3_0:getChildByName("raffle270_btn"):getChildByName("txt_270"):setString(var_0_2:translation("ACTIVITY_1100_TEXT3"))
	var_3_0:getChildByName("txt_times"):setString(var_0_2:translation("ACTIVITY_1100_TEXT4"))
	var_3_0:getChildByName("txt_luck"):setString(var_0_2:translation("ACTIVITY_1100_TEXT5"))
	var_3_0:setPosition(cc.p(var_0_7.x, var_0_7.y))

	arg_3_0.raffleOnceBtn = var_3_0:getChildByName("raffle60_btn")

	arg_3_0.raffleOnceBtn:getChildByName("txt_free"):setString(var_0_2:translation("ACTIVITY_1100_TEXT8"))
	arg_3_0.raffleOnceBtn:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.activity.details.free_summon_times > 0 then
				arg_3_0:raffle(1)
			elseif arg_3_0.player:getBackpack():getItemNumByID(xyd.tables.misc.activitySquareTurntable2Ticket) > 0 then
				arg_3_0:raffle(4)
			else
				arg_3_0:raffle(2)
			end
		end
	end)

	local var_3_1 = xyd.tables.item:icon(xyd.tables.misc.activitySquareTurntable2Ticket)
	local var_3_2 = xyd.SpriteLoader.new(var_3_1, nil, nil, xyd.DefaultImageType.ITEM_ICON)

	var_3_2:setPosition(arg_3_0.raffleOnceBtn:getChildByName("crystal"):getPosition())
	var_3_2:setScale(0.5)
	var_3_2:setName("ticket")
	arg_3_0.raffleOnceBtn:addChild(var_3_2)
	var_3_0:getChildByName("raffle270_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0:raffle(3)
		end
	end)

	local var_3_3 = var_3_0:getChildByName("rule_btn")

	var_3_3:addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(var_3_3, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "SQUARE_TURNTABLE2_RULE_TITLE",
				rule = "SQUARE_TURNTABLE2_RULE_TEXT"
			})
		end
	end)

	local var_3_4 = arg_3_0.container:getChildByName("exchange_btn")

	var_3_4:addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(var_3_4, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0:activityIsEnd() then
				return
			end

			xyd.WindowManager.get():openWindow("activity_sun_raffle_shop", {
				activity = arg_3_0.activity,
				callback = function()
					arg_3_0:updateGifts()
				end
			})
		end
	end)
	var_3_4:getChildByName("txt"):setString(var_0_2:translation("ACTIVITY_1090_EXCHANGE_TXT"))
	arg_3_0:updateRaffleBaseOnType()
	arg_3_0:updateGifts()
	arg_3_0:addBlockLayer()
	arg_3_0.blockLayer_:setVisible(false)
end

function var_0_0.updateRaffleBaseOnType(arg_9_0)
	arg_9_0.items = {}
	arg_9_0.luckyLabel = arg_9_0.centre:getChildByName("container"):getChildByName("luck")

	local var_9_0 = arg_9_0.startPos:getChildren()

	if var_9_0 then
		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			if iter_9_1 ~= arg_9_0.centre then
				arg_9_0.startPos:removeChild(iter_9_1)
			end
		end
	end

	local var_9_1 = xyd.tables.activitySqRaffleC

	if arg_9_0.raffleType == var_0_8.Vip then
		var_9_1 = xyd.tables.activitySqVipRaffle
	end

	arg_9_0:updateLuckyLabel()

	for iter_9_2 = 1, var_9_1:getCounts() do
		local var_9_2 = var_9_1:itemID(iter_9_2)
		local var_9_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1100/raffle_item.csb")
		local var_9_4 = var_9_3:getChildByName("container")

		xyd.setItemAndAddTips(var_9_4:getChildByName("icon_container"), var_9_2)
		var_9_4:getChildByName("label_num"):setString(var_9_1:itemNum(iter_9_2))
		var_9_4:getChildByName("label_name"):setString(xyd.tables.item:name(var_9_2))

		if var_9_1:isValua(iter_9_2) == 0 then
			var_9_4:getChildByName("rare_item_bg"):setVisible(false)
			var_9_4:getChildByName("rare"):setVisible(false)
		end

		var_9_3:addTo(arg_9_0.startPos)
		var_9_3:setPosition(cc.p(var_0_5 * var_9_1:x(iter_9_2), var_0_6 * var_9_1:y(iter_9_2)))

		arg_9_0.items[iter_9_2] = var_9_3
	end

	arg_9_0:updateFreeBtnState()
end

function var_0_0.updateFreeBtnState(arg_10_0)
	arg_10_0.centre:getChildByName("container"):getChildByName("times"):setString(arg_10_0.activity.details.free_summon_times)

	if arg_10_0.activity.details.free_summon_times > 0 then
		arg_10_0.raffleOnceBtn:getChildByName("ticket"):setVisible(false)
		arg_10_0.raffleOnceBtn:getChildByName("crystal"):setVisible(false)
		arg_10_0.raffleOnceBtn:getChildByName("txt_free"):setVisible(true)
		arg_10_0.raffleOnceBtn:getChildByName("txt_60"):setVisible(false)
	elseif arg_10_0.player:getBackpack():getItemNumByID(xyd.tables.misc.activitySquareTurntable2Ticket) > 0 then
		arg_10_0.raffleOnceBtn:getChildByName("ticket"):setVisible(true)
		arg_10_0.raffleOnceBtn:getChildByName("crystal"):setVisible(false)
		arg_10_0.raffleOnceBtn:getChildByName("txt_free"):setVisible(false)
		arg_10_0.raffleOnceBtn:getChildByName("txt_60"):setVisible(true)
		arg_10_0.raffleOnceBtn:getChildByName("txt_60"):setString(var_0_2:translation("ACTIVITY_1100_TEXT1"))
	else
		arg_10_0.raffleOnceBtn:getChildByName("ticket"):setVisible(false)
		arg_10_0.raffleOnceBtn:getChildByName("crystal"):setVisible(true)
		arg_10_0.raffleOnceBtn:getChildByName("txt_free"):setVisible(false)
		arg_10_0.raffleOnceBtn:getChildByName("txt_60"):setVisible(true)
		arg_10_0.raffleOnceBtn:getChildByName("txt_60"):setString(var_0_2:translation("ACTIVITY_1100_TEXT2"))
	end
end

function var_0_0.updateGifts(arg_11_0)
	arg_11_0.container:getChildByName("count_time_txt"):setString(arg_11_0.activity.details.lucky_star)
end

function var_0_0.raffle(arg_12_0, arg_12_1)
	if arg_12_0:activityIsEnd() then
		return
	end

	if arg_12_0.raffleType == var_0_8.Vip and arg_12_0.player.vip < xyd.tables.misc.lvbuVipLimit then
		local var_12_0 = string.format(var_0_2:translation("UNDER_RAFFLE_VIP_LIMIT"), xyd.tables.misc.lvbuVipLimit)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_0
		})

		return
	end

	local var_12_1 = xyd.tables.summon:crystals(arg_12_0.raffleType)[arg_12_1]

	if var_12_1 > arg_12_0.player.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
			local var_13_0 = {}

			var_13_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)
	else
		local var_12_2 = string.format(xyd.tables.translation:translation("LVBU_SURE_COST_TO_RAFFLE"), var_12_1)

		if arg_12_1 ~= 4 and arg_12_1 ~= 1 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_2, function()
				local var_14_0 = {
					summon_type = arg_12_0.raffleType,
					summon_index = arg_12_1
				}

				xyd.Backend.get():request(xyd.mid.SQUARE_TURNTABLEC_RAFFLE, var_14_0, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						arg_12_0.activity.details.normal = arg_15_1.normal
						arg_12_0.activity.details.super = arg_15_1.super
						arg_12_0.activity.details.score = arg_15_1.score
						arg_12_0.activity.details.lucky_star = arg_15_1.lucky_star
						arg_12_0.activity.details.free_summon_times = arg_15_1.free_summon_times

						if arg_12_1 == 4 then
							arg_12_0.player:getBackpack():addItemsByID(xyd.tables.misc.activitySquareTurntable2Ticket, -1)

							if arg_12_0.player:getBackpack():getItemNumByID(xyd.tables.misc.activitySquareTurntable2Ticket) <= 0 then
								local var_15_0 = {}

								var_15_0.itemNum = 0
								var_15_0.itemID = xyd.tables.misc.activitySquareTurntable2Ticket

								arg_12_0.player:getBackpack():removeItem(var_15_0)
							end
						end

						arg_12_0.isOnSimulation = true

						arg_12_0:simulationRaffle(arg_15_1.awards)

						if arg_12_1 == 1 or arg_12_1 == 4 then
							arg_12_0:updateFreeBtnState()
						end
					end
				end)
			end, nil, nil, xyd.ColorMode.ACTIVITY)
		else
			local var_12_3 = {
				summon_type = arg_12_0.raffleType,
				summon_index = arg_12_1
			}

			xyd.Backend.get():request(xyd.mid.SQUARE_TURNTABLEC_RAFFLE, var_12_3, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					arg_12_0.activity.details.normal = arg_16_1.normal
					arg_12_0.activity.details.super = arg_16_1.super
					arg_12_0.activity.details.score = arg_16_1.score
					arg_12_0.activity.details.lucky_star = arg_16_1.lucky_star
					arg_12_0.activity.details.free_summon_times = arg_16_1.free_summon_times

					if arg_12_1 == 4 then
						arg_12_0.player:getBackpack():addItemsByID(xyd.tables.misc.activitySquareTurntable2Ticket, -1)

						if arg_12_0.player:getBackpack():getItemNumByID(xyd.tables.misc.activitySquareTurntable2Ticket) <= 0 then
							local var_16_0 = {}

							var_16_0.itemNum = 0
							var_16_0.itemID = xyd.tables.misc.activitySquareTurntable2Ticket

							arg_12_0.player:getBackpack():removeItem(var_16_0)
						end
					end

					arg_12_0.isOnSimulation = true

					arg_12_0:simulationRaffle(arg_16_1.awards)

					if arg_12_1 == 1 or arg_12_1 == 4 then
						arg_12_0:updateFreeBtnState()
					end
				end
			end)
		end
	end
end

function var_0_0.simulationRaffle(arg_17_0, arg_17_1)
	arg_17_0.blockLayer_:setVisible(true)

	local var_17_0 = clone(arg_17_1)
	local var_17_1 = xyd.tables.activitySqRaffleC

	if arg_17_0.raffleType == var_0_8.Vip then
		var_17_1 = xyd.tables.activitySqVipRaffle
	end

	local var_17_2 = 0
	local var_17_3 = var_17_1:getCounts()

	if arg_17_0.handle then
		var_0_1.unscheduleGlobal(arg_17_0.handle)

		arg_17_0.handle = nil
	end

	local var_17_4 = 1
	local var_17_5 = arg_17_0:getRandomRotateCount()
	local var_17_6 = 0.05
	local var_17_7 = 0
	local var_17_8 = math.random(2, 4)

	arg_17_0.handle = var_0_1.scheduleGlobal(function()
		var_17_7 = var_17_7 + 1

		if var_17_2 > 0 and not arg_17_0.isOnSimulationt then
			var_17_2 = var_17_2 - 1

			if var_17_2 <= 0 and arg_17_0.effect then
				arg_17_0.effect:setVisible(true)
			end
		elseif not arg_17_0 or tolua.isnull(arg_17_0.container) or #var_17_0 < 1 or arg_17_0.forceStopSimulation then
			arg_17_0.isOnSimulation = false
			arg_17_0.forceStopSimulation = false

			if arg_17_0.handle then
				if arg_17_0.blockLayer_ and not tolua.isnull(arg_17_0.blockLayer_) then
					arg_17_0.blockLayer_:setVisible(false)
				end

				var_0_1.unscheduleGlobal(arg_17_0.handle)

				arg_17_0.handle = nil

				var_0_1.performWithDelayGlobal(function()
					if arg_17_0 and not tolua.isnull(arg_17_0.container) then
						arg_17_0:updateLuckyLabel()
						arg_17_0:updateGifts()
						arg_17_0:releaseAllEffects()
						arg_17_0.player:handleRewards(arg_17_1)
					end
				end, 0.5)
			end
		elseif var_17_5 > 0 then
			if var_17_5 < var_17_8 and var_17_7 % 2 == 0 or var_17_5 >= var_17_8 then
				var_17_5 = var_17_5 - 1
				var_17_4 = var_17_4 - 1
				var_17_4 = (var_17_4 - 1 + var_17_3) % var_17_3 + 1

				arg_17_0:addSelectEffectForItem(arg_17_0.items[var_17_4])
			end
		elseif var_17_7 % 2 == 0 then
			var_17_4 = var_17_4 - 1
			var_17_4 = (var_17_4 - 1 + var_17_3) % var_17_3 + 1

			arg_17_0:addSelectEffectForItem(arg_17_0.items[var_17_4])

			if var_17_1:itemID(var_17_4) == xyd.tables.item:heroID(var_17_0[1].table_id) or var_17_1:itemID(var_17_4) == var_17_0[1].table_id and var_17_1:itemNum(var_17_4) == (var_17_0[1].item_num or 1) then
				table.remove(var_17_0, 1)

				var_17_2 = 10

				arg_17_0:addSelectedEffectForItem(arg_17_0.items[var_17_4])

				if arg_17_0.selectedEffect then
					arg_17_0.selectedEffect:setVisible(true)
				end

				if arg_17_0.effect then
					arg_17_0.effect:setVisible(false)
				end
			end
		end
	end, var_17_6)
end

function var_0_0.release(arg_20_0)
	if arg_20_0.handle then
		var_0_1.unscheduleGlobal(arg_20_0.handle)
	end
end

function var_0_0.addBlockLayer(arg_21_0)
	arg_21_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	local var_21_0 = arg_21_0.container:convertToWorldSpace(cc.p(0, 0))

	arg_21_0.blockLayer_:pos(-var_21_0.x, -var_21_0.y):addTo(arg_21_0.container, 20)
	arg_21_0.blockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_21_0.blockLayer_:setTouchEnabled(true)
	arg_21_0.blockLayer_:setTouchSwallowEnabled(true)
	arg_21_0.blockLayer_:setVisible(false)
	arg_21_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			return true
		elseif arg_22_0.name == "ended" then
			arg_21_0.blockLayer_:setVisible(false)

			arg_21_0.forceStopSimulation = true
		end
	end)
end

function var_0_0.getRandomRotateCount(arg_23_0)
	return xyd.tables.activitySqRaffleC:getCounts() * math.random(2, 3)
end

function var_0_0.addSelectEffectForItem(arg_24_0, arg_24_1)
	if not arg_24_1 or tolua.isnull(arg_24_1) then
		return
	end

	if not arg_24_0.effect or tolua.isnull(arg_24_0.effect) then
		local var_24_0 = "skeletons/ui_effect/raffle/effect_raffle1" .. ".json"
		local var_24_1 = "skeletons/ui_effect/raffle/effect_raffle1" .. ".atlas"

		arg_24_0.effect = var_0_3.new(var_24_0, var_24_1, 1)

		arg_24_0.effect:setScale(1.15)
		arg_24_0.effect:addTo(arg_24_0.startPos)
		arg_24_0.effect:setName("effect")
		arg_24_0.effect:play(nil, true)
	end

	arg_24_1:getPosition()
	arg_24_0.effect:setPosition(cc.p(arg_24_1:getPositionX() + 71, arg_24_1:getPositionY() + 58))
end

function var_0_0.addSelectedEffectForItem(arg_25_0, arg_25_1)
	if not arg_25_1 or tolua.isnull(arg_25_1) then
		return
	end

	local var_25_0 = "skeletons/ui_effect/raffle/effect_raffle2" .. ".json"
	local var_25_1 = "skeletons/ui_effect/raffle/effect_raffle2" .. ".atlas"
	local var_25_2 = var_0_3.new(var_25_0, var_25_1, 0.9)

	var_25_2:setScale(1.15)
	var_25_2:addTo(arg_25_0.startPos)
	var_25_2:setName("effect")
	var_25_2:play(nil, true)
	arg_25_1:getPosition()
	var_25_2:setPosition(cc.p(arg_25_1:getPositionX() + 71, arg_25_1:getPositionY() + 58))
	table.insert(arg_25_0.selectedEffectS, var_25_2)
end

function var_0_0.updateLuckyLabel(arg_26_0)
	if arg_26_0.raffleType == var_0_8.Vip then
		arg_26_0.luckyLabel:setString(arg_26_0.activity.details.super)
	else
		arg_26_0.luckyLabel:setString(math.floor(arg_26_0.activity.details.normal / 150))
	end
end

function var_0_0.releaseAllEffects(arg_27_0)
	if not arg_27_0 or tolua.isnull(arg_27_0.container) then
		return
	end

	for iter_27_0, iter_27_1 in ipairs(arg_27_0.selectedEffectS) do
		if not tolua.isnull(iter_27_1) then
			iter_27_1:removeSelf()
		end
	end

	if arg_27_0.effect and not tolua.isnull(arg_27_0.effect) then
		arg_27_0.effect:removeSelf()

		arg_27_0.effect = nil
	end

	arg_27_0.selectedEffectS = {}
end

function var_0_0.activityIsEnd(arg_28_0)
	local var_28_0 = xyd.ServerTime.get():getServerTime()

	if var_28_0 < arg_28_0.activity.start_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("ACTIVITY_NO_OPEN")
		})

		return true
	elseif var_28_0 > arg_28_0.activity.end_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("ACTIVITY_FINISHED")
		})

		return true
	end

	return false
end

return var_0_0
