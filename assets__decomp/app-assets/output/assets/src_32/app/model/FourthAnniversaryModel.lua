local var_0_0 = class("FourthAnniversaryModel", import(".BaseModel"))
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
	arg_1_0.notFristIn = false
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.fourthAnniInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_GET_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.gold = arg_4_1.mine_info
			arg_3_0.startTime = arg_4_1.start_time
			arg_3_0.endTime = arg_4_1.end_time
			arg_3_0.stage = arg_4_1.stage
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.fourthAnniGoldMul(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNIVERSARY_GOLD_MUL, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0:handleRespone(arg_6_1)
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.fourthAnniGoldStart(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNIVERSARY_GOLD_START, var_7_0, function(arg_8_0, arg_8_1)
		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end

		if arg_8_0 == xyd.error.OK then
			arg_7_0:handleRespone(arg_8_1)
		end
	end)
end

function var_0_0.startGold(arg_9_0)
	local var_9_0 = xyd.tables.misc.activityAnni4thGoldDiamondCost
	local var_9_1 = arg_9_0.backpack:getItemNumByID(xyd.tables.misc.activityAnni4thGoldResetItem)

	if var_9_1 <= 0 and var_9_0 > arg_9_0.selfPlayer.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
			local var_10_0 = {}

			var_10_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
		end, nil, nil, xyd.ColorMode.ACTIVITY)

		return
	end

	local var_9_2 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_NORMAL_COST_TIP"), var_9_0)

	if var_9_1 > 0 then
		var_9_2 = var_0_1:translation("FOURTH_ANNI_GOLD_TIP6")
	end

	local function var_9_3()
		local var_11_0 = {
			bt_type = var_0_2.Normal
		}

		arg_9_0:fourthAnniGoldStart(var_11_0, function(arg_12_0, arg_12_1)
			if arg_12_0 == xyd.error.OK then
				if var_9_1 > 0 then
					local var_12_0 = {
						itemID = xyd.tables.misc.activityAnni4thGoldResetItem
					}

					var_12_0.itemNum = 1

					arg_9_0.backpack:removeItem(var_12_0)
				end

				xyd.WindowManager.get():closeWindow("gold_catch")
				xyd.WindowManager.get():openWindow("gold_catch", var_11_0)
				xyd.WindowManager.get():closeWindow("gold_result")
			end
		end)
	end

	local var_9_4 = {
		rcallBefore = 0,
		title = var_0_1:translation("TIP"),
		txt = var_9_2,
		rcallback = var_9_3,
		colorMode = xyd.ColorMode.ACTIVITY,
		align = xyd.ui_align.CENTER,
		valign = xyd.ui_valign.CENTER
	}

	xyd.WindowManager.get():openWindow("alert_green", var_9_4)
end

function var_0_0.startUnlimitGold(arg_13_0)
	if math.floor(arg_13_0.gold.challenge_times / xyd.tables.misc.activityChocolateLimitLessTimes) < 1 then
		local var_13_0 = string.format(var_0_1:translation("ACTIVITY_THIRD_DIGLETT_UNLIMIT_NOTIME_TIP"), xyd.tables.misc.activityChocolateLimitLessTimes)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_13_0
		})

		return
	end

	local var_13_1 = {
		bt_type = var_0_2.Unlimit
	}

	arg_13_0:fourthAnniGoldStart(var_13_1, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			local var_14_0 = {
				bt_type = var_0_2.Unlimit
			}

			xyd.WindowManager.get():closeWindow("gold_catch")
			xyd.WindowManager.get():openWindow("gold_catch", var_14_0)
			xyd.WindowManager.get():closeWindow("gold_result")
		end
	end)
end

function var_0_0.fourthAnniGoldEnd(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNIVERSARY_GOLD_END, var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:handleRespone(arg_16_1, true)
		end

		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.fourthAnniGoldExchange(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNIVERSARY_GOLD_EXCHANGE, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0:handleRespone(arg_18_1)
		end

		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.fourthAnniGoldRank(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.FOURTH_ANNIVERSARY_GOLD_RANK, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			-- block empty
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.handleRespone(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_1.challenge_times then
		arg_21_0.gold.challenge_times = arg_21_1.challenge_times

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.REFRESH_FOURTH_ANNI_GOLD_TIMES
		})
	end

	if arg_21_1.inf_score then
		arg_21_0.gold.inf_score = arg_21_1.inf_score
	end

	if arg_21_1.point then
		arg_21_0.gold.point = arg_21_1.point
	end

	if arg_21_1.awards and not arg_21_2 then
		arg_21_0.selfPlayer:handleRewards(arg_21_1.awards)
	elseif arg_21_1.awards and arg_21_2 then
		arg_21_0.selfPlayer:handleRewardsWithoutShow(arg_21_1.awards)
	end
end

function var_0_0.getStartTime(arg_22_0)
	return arg_22_0.startTime
end

function var_0_0.getEndTime(arg_23_0)
	return arg_23_0.endTime
end

function var_0_0.getStage(arg_24_0)
	return arg_24_0.stage
end

function var_0_0.enterMapShop(arg_25_0, arg_25_1)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_GET_INFO, nil, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			local var_26_0 = arg_26_1.act_campaign.shop_buy_info

			xyd.WindowManager.get():openWindow("fourth_annni_map_shop", var_26_0)
		end

		if arg_25_1 then
			arg_25_1(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.enterMap(arg_27_0, arg_27_1, arg_27_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_GET_INFO, nil, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0.campaignTable = xyd.tables.activityAnni4thCampaignTable

			local var_28_0 = arg_28_1.act_campaign
			local var_28_1 = tostring(arg_27_0.campaignTable:startPoints()[1])

			if arg_28_1.act_campaign.campaigns[1][var_28_1] % 10 == 0 and (not arg_27_0.mapMode or arg_27_0.mapMode ~= 2) then
				local var_28_2 = 10001

				xyd.WindowManager.get():openWindow("fourth_annni_map_story", {
					showBG = true,
					dialogueID = var_28_2,
					callback = function()
						xyd.WindowManager.get():openWindow("fourth_annni_map", var_28_0)
					end
				})
			else
				xyd.WindowManager.get():openWindow("fourth_annni_map", var_28_0)
			end

			if arg_27_2 then
				arg_27_2(arg_28_0, arg_28_1)
			end
		end
	end)
end

function var_0_0.mapRestart(arg_30_0, arg_30_1)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_MAP_RESTART, nil, function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			-- block empty
		end

		if arg_30_1 then
			arg_30_1(arg_31_0, arg_31_1)
		end
	end)
end

function var_0_0.mapChooseStory(arg_32_0, arg_32_1, arg_32_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_MAP_CHOOSE_STORY, arg_32_1, function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK then
			-- block empty
		end

		if arg_32_2 then
			arg_32_2(arg_33_0, arg_33_1)
		end
	end)
end

function var_0_0.mapShoppingBuy(arg_34_0, arg_34_1, arg_34_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_SHOP_BUY, arg_34_1, function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			-- block empty
		end

		if arg_34_2 then
			arg_34_2(arg_35_0, arg_35_1)
		end
	end)
end

function var_0_0.getMapAward(arg_36_0, arg_36_1, arg_36_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_MAP_GET_AWARD, arg_36_1, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			-- block empty
		end

		if arg_36_2 then
			arg_36_2(arg_37_0, arg_37_1)
		end
	end)
end

function var_0_0.ufocatcherGetInfo(arg_38_0, arg_38_1, arg_38_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_GET_INFO, arg_38_1, function(arg_39_0, arg_39_1)
		if arg_38_2 then
			arg_38_2(arg_39_0, arg_39_1)
		end
	end)
end

function var_0_0.ufocatcherRefresh(arg_40_0, arg_40_1, arg_40_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_REFRESH, arg_40_1, function(arg_41_0, arg_41_1)
		if arg_40_2 then
			arg_40_2(arg_41_0, arg_41_1)
		end
	end)
end

function var_0_0.ufocatcherCatchGetExtra(arg_42_0, arg_42_1, arg_42_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_CATCH_GET_EXTRA, arg_42_1, function(arg_43_0, arg_43_1)
		if arg_42_2 then
			arg_42_2(arg_43_0, arg_43_1)
		end
	end)
end

function var_0_0.ufocatcherStartCatch(arg_44_0, arg_44_1, arg_44_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_START_CATCH, arg_44_1, function(arg_45_0, arg_45_1)
		if arg_44_2 then
			arg_44_2(arg_45_0, arg_45_1)
		end
	end)
end

function var_0_0.ufocatcherAutoCatch(arg_46_0, arg_46_1, arg_46_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_AUTO_CATCH, arg_46_1, function(arg_47_0, arg_47_1)
		if arg_46_2 then
			arg_46_2(arg_47_0, arg_47_1)
		end
	end)
end

function var_0_0.ufocatcherCatch(arg_48_0, arg_48_1, arg_48_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_CATCH, arg_48_1, function(arg_49_0, arg_49_1)
		if arg_48_2 then
			arg_48_2(arg_49_0, arg_49_1)
		end
	end)
end

function var_0_0.ufocatcherEndCatch(arg_50_0, arg_50_1, arg_50_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_END_CATCH, arg_50_1, function(arg_51_0, arg_51_1)
		if arg_50_2 then
			arg_50_2(arg_51_0, arg_51_1)
		end
	end)
end

function var_0_0.ufocatcherCatchList(arg_52_0, arg_52_1, arg_52_2)
	xyd.Backend.get():request(xyd.mid.FOURTH_ANNI_UFOCATCHER_CATCH_LIST, arg_52_1, function(arg_53_0, arg_53_1)
		if arg_52_2 then
			arg_52_2(arg_53_0, arg_53_1)
		end
	end)
end

return var_0_0
