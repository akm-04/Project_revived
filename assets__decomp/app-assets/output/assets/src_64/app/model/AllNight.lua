local var_0_0 = class("AllNight", import(".BaseModel"))
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

function var_0_0.AllNightInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.fruit = arg_4_1.fruit
			arg_3_0.AllNightSlot = arg_4_1.AllNight_slot
			arg_3_0.pool = arg_4_1.pool_info.base_info.pool_id
			arg_3_0.startTime = arg_4_1.start_time
			arg_3_0.endTime = arg_4_1.end_time
			arg_3_0.stage = arg_4_1.stage
			arg_3_0.bossInfo = arg_4_1.boss_info
			arg_3_0.dayCount = math.ceil((xyd.ServerTime.get():getServerTime() - arg_3_0.startTime) / xyd.OneDaySec)
		end

		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.firstEnterMap(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_FIRST_ENTER, nil, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_1()
		end
	end)
end

function var_0_0.getMapAward(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_STAR_AWARDS, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK and arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.enterMap(arg_9_0, arg_9_1, arg_9_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_CAMPAIGH_INFO, nil, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			dump(arg_10_1)

			arg_9_0.mapInfo = arg_10_1

			if arg_9_0.mapInfo.base_info.first_enter == 1 then
				local var_10_0 = 10001

				xyd.WindowManager.get():openWindow("all_night_map_story", {
					showBG = true,
					dialogueID = var_10_0,
					callback = function()
						xyd.WindowManager.get():openWindow("all_night_map", {
							mapMode = arg_9_2
						})
					end
				})
			else
				xyd.WindowManager.get():openWindow("all_night_map", {
					mapMode = arg_9_2
				})
			end
		end
	end)
end

function var_0_0.enterLightGacha(arg_12_0)
	arg_12_0:AllNightInfo(nil, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			local var_13_0 = arg_13_1.pool_info

			xyd.WindowManager.get():openWindow("all_night_light_gacha", var_13_0)
		end
	end)
end

function var_0_0.enterDarkGacha(arg_14_0)
	arg_14_0:AllNightInfo(nil, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			local var_15_0 = {
				award_times = arg_15_1.gacha_info.award_times
			}

			xyd.WindowManager.get():openWindow("all_night_dark_gacha", var_15_0)
		end
	end)
end

function var_0_0.unlockCampaign(arg_16_0, arg_16_1, arg_16_2)
	xyd.Backend.get():request(xyd.mid.AllNight_UNLOCK_CAMPAIGN, {
		campaign_id = arg_16_1
	}, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK and arg_16_2 then
			arg_16_2(arg_17_1)
		end
	end)
end

function var_0_0.lightGachaDraw(arg_18_0, arg_18_1, arg_18_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_LIGHT_GACHA_DRAW, arg_18_1, function(arg_19_0, arg_19_1)
		if arg_18_2 then
			arg_18_2(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.lightGachaNextPool(arg_20_0, arg_20_1, arg_20_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_LIGHT_GACHA_NEXT_POOL, arg_20_1, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0.pool = arg_21_1.base_info.pool_id

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ALL_NIGHT_POOL_CHANGE
			})
		end

		if arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.darkGachaDraw(arg_22_0, arg_22_1, arg_22_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_DARK_GACHA_DRAW, arg_22_1, function(arg_23_0, arg_23_1)
		if arg_22_2 then
			arg_22_2(arg_23_0, arg_23_1)
		end
	end)
end

function var_0_0.darkGachaBuy(arg_24_0, arg_24_1, arg_24_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_DARK_GACHA_BUY, arg_24_1, function(arg_25_0, arg_25_1)
		if arg_24_2 then
			arg_24_2(arg_25_0, arg_25_1)
		end
	end)
end

function var_0_0.darkGachaGetExtra(arg_26_0, arg_26_1, arg_26_2)
	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_DARK_GACHA_GET_EXTRA, arg_26_1, function(arg_27_0, arg_27_1)
		if arg_26_2 then
			arg_26_2(arg_27_0, arg_27_1)
		end
	end)
end

return var_0_0
