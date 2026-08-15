local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.activitySqRaffleGift
local var_0_5 = 161
local var_0_6 = 114
local var_0_7 = {
	x = 161,
	y = 114
}
local var_0_8 = {
	Vip = 24,
	Normal = 23
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
	arg_3_0.centre = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1090/centre_item.csb")

	arg_3_0.centre:addTo(arg_3_0.startPos)

	local var_3_0 = arg_3_0.centre:getChildByName("container")

	var_3_0:getChildByName("lucky_value_desc"):setString(var_0_2:translation("LUCKY_VALUE_DESC"))
	var_3_0:getChildByName("raffle270_btn"):getChildByName("txt_270"):setString(var_0_2:translation("ACTIVITY_1090_TEXT2"))
	var_3_0:getChildByName("txt_times"):setString(var_0_2:translation("ACTIVITY_1090_TEXT3"))
	var_3_0:getChildByName("txt_luck"):setString(var_0_2:translation("ACTIVITY_SQ_TURNTABLE_LUCKY"))
	var_3_0:setPosition(cc.p(var_0_7.x, var_0_7.y))

	arg_3_0.currentLuckTxt = var_3_0:getChildByName("luck")
	arg_3_0.raffleOnceBtn = var_3_0:getChildByName("raffle60_btn")

	arg_3_0.raffleOnceBtn:getChildByName("txt_60"):setString(var_0_2:translation("ACTIVITY_1090_TEXT1"))
	arg_3_0.raffleOnceBtn:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:raffle(2)
		end
	end)
	var_3_0:getChildByName("raffle270_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0:raffle(3)
		end
	end)
	var_3_0:getChildByName("rule_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "SQUARE_TURNTABLE_RULE_TITLE",
				rule = "SQUARE_TURNTABLE_RULE_TEXT"
			})
		end
	end)
	arg_3_0.container:getChildByName("exchange_btn"):getChildByName("txt"):setString(var_0_2:translation("ACTIVITY_1090_EXCHANGE_TXT"))
	arg_3_0.container:getChildByName("exchange_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0:activityIsEnd() then
				return
			end

			xyd.WindowManager.get():openWindow("activity_moon_raffle_shop", {
				activity = arg_3_0.activity,
				callback = function()
					arg_3_0:updateGifts()
				end
			})
		end
	end)
	arg_3_0:updateRaffleBaseOnType()
	arg_3_0:updateGifts()
	arg_3_0:addBlockLayer()
	arg_3_0.blockLayer_:setVisible(false)
end

function var_0_0.updateRaffleBaseOnType(arg_9_0)
	arg_9_0.items = {}
	arg_9_0.luckyLabel = arg_9_0.centre:getChildByName("container"):getChildByName("times")

	local var_9_0 = arg_9_0.startPos:getChildren()

	if var_9_0 then
		for iter_9_0, iter_9_1 in ipairs(var_9_0) do
			if iter_9_1 ~= arg_9_0.centre then
				arg_9_0.startPos:removeChild(iter_9_1)
			end
		end
	end

	local var_9_1 = xyd.tables.activitySqRaffle

	if arg_9_0.raffleType == var_0_8.Vip then
		var_9_1 = xyd.tables.activitySqVipRaffle
	end

	arg_9_0:updateLuckyLabel()

	for iter_9_2 = 1, var_9_1:getCounts() do
		local var_9_2 = var_9_1:itemID(iter_9_2)
		local var_9_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1090/raffle_item.csb")
		local var_9_4 = var_9_3:getChildByName("container")
		local var_9_5 = var_9_4:getChildByName("name_txt")

		xyd.setItemAndAddTips(var_9_4:getChildByName("icon_container"), var_9_2)
		var_9_5:setString(xyd.tables.item:name(var_9_2))
		var_9_4:getChildByName("item_num_txt"):setString(var_9_1:itemNum(iter_9_2))

		if var_9_1:isValua(iter_9_2) == 0 then
			var_9_4:getChildByName("rare_item_bg"):setVisible(false)
			var_9_4:getChildByName("rare"):setVisible(false)
		end

		var_9_3:addTo(arg_9_0.startPos)
		var_9_3:setPosition(cc.p(var_0_5 * var_9_1:x(iter_9_2), var_0_6 * var_9_1:y(iter_9_2)))

		arg_9_0.items[iter_9_2] = var_9_3
	end
end

function var_0_0.updateGifts(arg_10_0)
	arg_10_0.container:getChildByName("count_time_txt"):setString(arg_10_0.activity.details.lucky_star)
end

function var_0_0.raffle(arg_11_0, arg_11_1)
	if arg_11_0:activityIsEnd() then
		return
	end

	if arg_11_0.raffleType == var_0_8.Vip and arg_11_0.player.vip < xyd.tables.misc.lvbuVipLimit then
		local var_11_0 = string.format(var_0_2:translation("UNDER_RAFFLE_VIP_LIMIT"), xyd.tables.misc.lvbuVipLimit)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_11_0
		})

		return
	end

	if xyd.tables.summon:crystals(arg_11_0.raffleType)[arg_11_1] > arg_11_0.player.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
			local var_12_0 = {}

			var_12_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)
	else
		local var_11_1 = 1

		if arg_11_1 == 3 then
			var_11_1 = 5
		end

		if var_11_1 > arg_11_0.activity.details.free_summon_times then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("ACTIVITY_SQ_TURNTABLE_TIMES")
			})

			return
		end

		local var_11_2 = {
			summon_type = arg_11_0.raffleType,
			summon_index = arg_11_1
		}

		xyd.Backend.get():request(xyd.mid.SQUARE_TURNTABLE_RAFFLE, var_11_2, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				arg_11_0.activity.details.normal = arg_13_1.normal
				arg_11_0.activity.details.super = arg_13_1.super
				arg_11_0.activity.details.summon_times = arg_13_1.summon_times
				arg_11_0.activity.details.free_summon_times = arg_13_1.free_summon_times
				arg_11_0.activity.details.lucky_star = arg_13_1.lucky_star
				arg_11_0.isOnSimulation = true

				arg_11_0:simulationRaffle(arg_13_1.awards)
			end
		end)
	end
end

function var_0_0.simulationRaffle(arg_14_0, arg_14_1)
	arg_14_0.blockLayer_:setVisible(true)

	local var_14_0 = clone(arg_14_1)
	local var_14_1 = xyd.tables.activitySqRaffle

	if arg_14_0.raffleType == var_0_8.Vip then
		var_14_1 = xyd.tables.activitySqVipRaffle
	end

	local var_14_2 = 0
	local var_14_3 = var_14_1:getCounts()

	if arg_14_0.handle then
		var_0_1.unscheduleGlobal(arg_14_0.handle)

		arg_14_0.handle = nil
	end

	local var_14_4 = 1
	local var_14_5 = arg_14_0:getRandomRotateCount()
	local var_14_6 = 0.05
	local var_14_7 = 0
	local var_14_8 = math.random(2, 4)

	arg_14_0.handle = var_0_1.scheduleGlobal(function()
		var_14_7 = var_14_7 + 1

		if var_14_2 > 0 and not arg_14_0.isOnSimulationt then
			var_14_2 = var_14_2 - 1

			if var_14_2 <= 0 and arg_14_0.effect then
				arg_14_0.effect:setVisible(true)
			end
		elseif not arg_14_0 or tolua.isnull(arg_14_0.container) or #var_14_0 < 1 or arg_14_0.forceStopSimulation then
			arg_14_0.isOnSimulation = false
			arg_14_0.forceStopSimulation = false

			if arg_14_0.handle then
				if arg_14_0.blockLayer_ and not tolua.isnull(arg_14_0.blockLayer_) then
					arg_14_0.blockLayer_:setVisible(false)
				end

				var_0_1.unscheduleGlobal(arg_14_0.handle)

				arg_14_0.handle = nil

				var_0_1.performWithDelayGlobal(function()
					if arg_14_0 and not tolua.isnull(arg_14_0.container) then
						arg_14_0:updateLuckyLabel()
						arg_14_0:updateGifts()
						arg_14_0:releaseAllEffects()
						arg_14_0.player:handleRewards(arg_14_1)
					end
				end, 0.5)
			end
		elseif var_14_5 > 0 then
			if var_14_5 < var_14_8 and var_14_7 % 2 == 0 or var_14_5 >= var_14_8 then
				var_14_5 = var_14_5 - 1
				var_14_4 = var_14_4 - 1
				var_14_4 = (var_14_4 - 1 + var_14_3) % var_14_3 + 1

				arg_14_0:addSelectEffectForItem(arg_14_0.items[var_14_4])
			end
		elseif var_14_7 % 2 == 0 then
			var_14_4 = var_14_4 - 1
			var_14_4 = (var_14_4 - 1 + var_14_3) % var_14_3 + 1

			arg_14_0:addSelectEffectForItem(arg_14_0.items[var_14_4])

			if var_14_1:itemID(var_14_4) == xyd.tables.item:heroID(var_14_0[1].table_id) or var_14_1:itemID(var_14_4) == var_14_0[1].table_id and var_14_1:itemNum(var_14_4) == (var_14_0[1].item_num or 1) then
				table.remove(var_14_0, 1)

				var_14_2 = 10

				arg_14_0:addSelectedEffectForItem(arg_14_0.items[var_14_4])

				if arg_14_0.selectedEffect then
					arg_14_0.selectedEffect:setVisible(true)
				end

				if arg_14_0.effect then
					arg_14_0.effect:setVisible(false)
				end
			end
		end
	end, var_14_6)
end

function var_0_0.release(arg_17_0)
	if arg_17_0.handle then
		var_0_1.unscheduleGlobal(arg_17_0.handle)
	end
end

function var_0_0.addBlockLayer(arg_18_0)
	arg_18_0.blockLayer_ = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	local var_18_0 = arg_18_0.container:convertToWorldSpace(cc.p(0, 0))

	arg_18_0.blockLayer_:pos(-var_18_0.x, -var_18_0.y):addTo(arg_18_0.container, 20)
	arg_18_0.blockLayer_:setTouchEnabled(true)
	arg_18_0.blockLayer_:setTouchSwallowEnabled(true)
	arg_18_0.blockLayer_:setVisible(false)
	arg_18_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			return true
		elseif arg_19_0.name == "ended" then
			arg_18_0.blockLayer_:setVisible(false)

			arg_18_0.forceStopSimulation = true
		end
	end)
end

function var_0_0.getRandomRotateCount(arg_20_0)
	return xyd.tables.activitySqRaffle:getCounts() * math.random(2, 3)
end

function var_0_0.addSelectEffectForItem(arg_21_0, arg_21_1)
	if not arg_21_1 or tolua.isnull(arg_21_1) then
		return
	end

	if not arg_21_0.effect or tolua.isnull(arg_21_0.effect) then
		local var_21_0 = "skeletons/ui_effect/raffle/effect_raffle1" .. ".json"
		local var_21_1 = "skeletons/ui_effect/raffle/effect_raffle1" .. ".atlas"

		arg_21_0.effect = var_0_3.new(var_21_0, var_21_1, 1)

		arg_21_0.effect:setScale(1.2)
		arg_21_0.effect:addTo(arg_21_0.startPos)
		arg_21_0.effect:setName("effect")
		arg_21_0.effect:play(nil, true)
	end

	arg_21_1:getPosition()
	arg_21_0.effect:setPosition(cc.p(arg_21_1:getPositionX() + 71, arg_21_1:getPositionY() + 58))
end

function var_0_0.addSelectedEffectForItem(arg_22_0, arg_22_1)
	if not arg_22_1 or tolua.isnull(arg_22_1) then
		return
	end

	local var_22_0 = "skeletons/ui_effect/raffle/effect_raffle2" .. ".json"
	local var_22_1 = "skeletons/ui_effect/raffle/effect_raffle2" .. ".atlas"
	local var_22_2 = var_0_3.new(var_22_0, var_22_1, 0.9)

	var_22_2:setScale(1.3)
	var_22_2:addTo(arg_22_0.startPos)
	var_22_2:setName("effect")
	var_22_2:play(nil, true)
	arg_22_1:getPosition()
	var_22_2:setPosition(cc.p(arg_22_1:getPositionX() + 71, arg_22_1:getPositionY() + 58))
	table.insert(arg_22_0.selectedEffectS, var_22_2)
end

function var_0_0.updateLuckyLabel(arg_23_0)
	arg_23_0.currentLuckTxt:setString(math.floor(arg_23_0.activity.details.normal / 180))

	if arg_23_0.raffleType == var_0_8.Vip then
		arg_23_0.luckyLabel:setString(arg_23_0.activity.details.super)
	else
		arg_23_0.luckyLabel:setString(arg_23_0.activity.details.free_summon_times)
	end
end

function var_0_0.releaseAllEffects(arg_24_0)
	if not arg_24_0 or tolua.isnull(arg_24_0.container) then
		return
	end

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.selectedEffectS) do
		if not tolua.isnull(iter_24_1) then
			iter_24_1:removeSelf()
		end
	end

	if arg_24_0.effect and not tolua.isnull(arg_24_0.effect) then
		arg_24_0.effect:removeSelf()

		arg_24_0.effect = nil
	end

	arg_24_0.selectedEffectS = {}
end

function var_0_0.activityIsEnd(arg_25_0)
	local var_25_0 = xyd.ServerTime.get():getServerTime()

	if var_25_0 < arg_25_0.activity.start_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("ACTIVITY_NO_OPEN")
		})

		return true
	elseif var_25_0 > arg_25_0.activity.end_time then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_2:translation("ACTIVITY_FINISHED")
		})

		return true
	end

	return false
end

return var_0_0
