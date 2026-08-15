local var_0_0 = class("Chocolate", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	Unlimit = 2,
	Normal = 1
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.startTime = 0
	arg_1_0.endTime = 0
	arg_1_0.stage = 1
	arg_1_0.mapNeedReload = true
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.effectsPool = {}
	arg_1_0.fruitsPool = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.chocolateInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.fruit = arg_4_1.fruit
			arg_3_0.chocolateSlot = arg_4_1.chocolate_slot
			arg_3_0.pool = arg_4_1.pool
			arg_3_0.startTime = arg_4_1.start_time
			arg_3_0.endTime = arg_4_1.end_time
			arg_3_0.stage = arg_4_1.stage
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.getChocolateSlot(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_SLOT, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			-- block empty
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.chocolateSlotList(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_SLOT_LIST, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			-- block empty
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.chocolateSlotGetExtra(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_SLOT_GET_EXTRA, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			-- block empty
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.chocolateFruitMul(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_FRUIT_MUL, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:handleRespone(arg_12_1)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.chocolateFruitStart(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_FRUIT_START, var_13_0, function(arg_14_0, arg_14_1)
		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end

		if arg_14_0 == xyd.error.OK then
			arg_13_0:handleRespone(arg_14_1)
		end
	end)
end

function var_0_0.startFruit(arg_15_0)
	local var_15_0 = xyd.tables.misc.activityChocolateFruitDiamondCost
	local var_15_1 = arg_15_0.backpack:getItemNumByID(xyd.tables.misc.activityChocolateFruitItem)

	if var_15_1 <= 0 and var_15_0 > arg_15_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_16_0 = {}

			var_16_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)

		return
	end

	local var_15_2 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_COST_TIP"), var_15_0)

	if var_15_1 > 0 then
		var_15_2 = var_0_1:translation("ACTIVITY_CHOCOLATE_FRUIT_TEXT2")
	end

	local function var_15_3()
		local var_17_0 = {
			bt_type = var_0_2.Normal
		}

		arg_15_0:chocolateFruitStart(var_17_0, function(arg_18_0, arg_18_1)
			if arg_18_0 == xyd.error.OK then
				if var_15_1 > 0 then
					local var_18_0 = {
						itemID = xyd.tables.misc.activityChocolateFruitItem
					}

					var_18_0.itemNum = 1

					arg_15_0.backpack:removeItem(var_18_0)
				end

				xyd.WindowManager.get():closeWindow("chocolate_fruits_catch")
				xyd.WindowManager.get():openWindow("chocolate_fruits_catch", var_17_0)
				xyd.WindowManager.get():closeWindow("chocolate_fruits_result")
			end
		end)
	end

	local var_15_4 = {
		rcallBefore = 0,
		title = var_0_1:translation("TIP"),
		txt = var_15_2,
		rcallback = var_15_3,
		colorMode = xyd.ColorMode.ACTIVITY,
		align = xyd.ui_align.CENTER,
		valign = xyd.ui_valign.CENTER
	}

	xyd.WindowManager.get():openWindow("alert_green", var_15_4)
end

function var_0_0.startUnlimitFruit(arg_19_0)
	if math.floor(arg_19_0.fruit.challenge_times / xyd.tables.misc.activityChocolateLimitLessTimes) < 1 then
		local var_19_0 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_NOTIME_TIP"), xyd.tables.misc.activityChocolateLimitLessTimes)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_19_0
		})

		return
	end

	local var_19_1 = {
		bt_type = var_0_2.Unlimit
	}

	arg_19_0:chocolateFruitStart(var_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			local var_20_0 = {
				bt_type = var_0_2.Unlimit
			}

			xyd.WindowManager.get():closeWindow("chocolate_fruits_catch")
			xyd.WindowManager.get():openWindow("chocolate_fruits_catch", var_20_0)
			xyd.WindowManager.get():closeWindow("chocolate_fruits_result")
		end
	end)
end

function var_0_0.chocolateFruitEnd(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_FRUIT_END, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0:handleRespone(arg_22_1, true)
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.chocolateFruitExchange(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_FRUIT_EXCHANGE, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0:handleRespone(arg_24_1)
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.chocolateFruitRank(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_FRUIT_RANK, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			-- block empty
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.handleRespone(arg_27_0, arg_27_1, arg_27_2)
	if arg_27_1.challenge_times then
		arg_27_0.fruit.challenge_times = arg_27_1.challenge_times

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REfRESH_CHOCOLATE_FRUIT_TIMES
		})
	end

	if arg_27_1.inf_score then
		arg_27_0.fruit.inf_score = arg_27_1.inf_score
	end

	if arg_27_1.point then
		arg_27_0.fruit.point = arg_27_1.point
	end

	if arg_27_1.awards and not arg_27_2 then
		arg_27_0.selfPlayer:handleRewards(arg_27_1.awards)
	elseif arg_27_1.awards and arg_27_2 then
		arg_27_0.selfPlayer:handleRewardsWithoutShow(arg_27_1.awards)
	end
end

function var_0_0.chocolateDrawPool(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_DRAW_POOL, var_28_0, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			-- block empty
		end

		if arg_28_2 then
			arg_28_2(arg_29_0, arg_29_1)
		end
	end)
end

function var_0_0.chocolateGoNext(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = arg_30_1 or {}

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_GO_NEXT, var_30_0, function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			-- block empty
		end

		if arg_30_2 then
			arg_30_2(arg_31_0, arg_31_1)
		end
	end)
end

function var_0_0.getStartTime(arg_32_0)
	return arg_32_0.startTime
end

function var_0_0.getEndTime(arg_33_0)
	return arg_33_0.endTime
end

function var_0_0.getPool(arg_34_0)
	return arg_34_0.pool
end

function var_0_0.getStage(arg_35_0)
	return arg_35_0.stage
end

function var_0_0.firstEnterMap(arg_36_0, arg_36_1)
	xyd.Backend.get():request(xyd.mid.CHOCOLATE_ENTER_MAP, nil, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			arg_36_1()
		end
	end)
end

function var_0_0.enterMap(arg_38_0, arg_38_1)
	xyd.Backend.get():request(xyd.mid.CHOCOLATE_MAP_INFO, nil, function(arg_39_0, arg_39_1)
		if arg_39_0 == xyd.error.OK then
			if arg_38_0.mapNeedReload then
				arg_38_0.mapInfo = arg_39_1
			else
				arg_38_0.mapInfo.act_item_change_ = arg_39_1.act_item_change_
			end

			if arg_38_0.stage ~= 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACTIVITY_MAP_CLOSED")
				})

				return
			end

			if arg_38_0.mapInfo.base_info.first_enter == 1 then
				local var_39_0 = {}

				var_39_0.talk_id = "story11771000"

				function var_39_0.callback()
					xyd.WindowManager.get():openWindow("chocolate_map")
				end

				xyd.WindowManager.get():openWindow("school_story_talk", var_39_0)
			else
				xyd.WindowManager.get():openWindow("chocolate_map")
			end
		end
	end)
end

function var_0_0.unlockCampaign(arg_41_0, arg_41_1, arg_41_2)
	xyd.Backend.get():request(xyd.mid.CHOCOLATE_UNLOCK_CAMPAIGN, {
		campaign_id = arg_41_1
	}, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK and arg_41_2 then
			arg_41_2(arg_42_1)
		end
	end)
end

return var_0_0
