local var_0_0 = class("Garden", import(".BaseModel"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.Garden
	}

	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			if arg_4_1 then
				arg_3_0.activity = arg_4_1
				arg_3_0.details = arg_3_0.activity.details
				arg_3_0.selfDetails = arg_3_0.details
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.getGardenInfo(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_GARDEN_INFO, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.details = arg_6_1

			xyd.WindowManager.get():closeWindow("garden")
			xyd.WindowManager.get():openWindow("garden")
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.gardenBuyField(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_BUY_FIELD, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0:handleResponse(arg_8_1)
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.gardenBuySeed(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_BUY_SEED, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0:handleResponse(arg_10_1)
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.gardenSeeding(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_SEEDING, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:handleResponse(arg_12_1)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.gardenFertilize(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_FERTILIZE, var_13_0, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_0:handleResponse(arg_14_1)
		end

		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.gardenWater(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_WATER, var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:handleResponse(arg_16_1)
		end

		if arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.gardenGain(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_GAIN, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0:handleResponse(arg_18_1)
		end

		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.gardenBuySteal(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_BUY_STEAL, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0:handleResponse(arg_20_1)
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.gardenLog(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_LOG, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			-- block empty
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.gardenRank(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_RANK, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			-- block empty
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.gardenDug(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_DUG, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0:handleResponse(arg_26_1)
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.gardenExchange(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.GARDEN_EXCHANGE, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0:handleResponse(arg_28_1)
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.isGardenRedPointShow(arg_29_0)
	local var_29_0 = xyd.ServerTime.get():getServerTime()

	if arg_29_0.selfDetails and arg_29_0.selfDetails.field_info then
		local var_29_1 = arg_29_0.selfDetails.field_info

		for iter_29_0, iter_29_1 in pairs(var_29_1) do
			if iter_29_1.status == 1 and var_29_0 >= iter_29_1.end_time then
				return true
			end
		end
	end

	return false
end

function var_0_0.getCanPlantFlower(arg_30_0)
	local var_30_0 = {}
	local var_30_1 = xyd.tables.activityGardenFlower
	local var_30_2 = var_30_1:ids()

	for iter_30_0 = 1, #var_30_2 do
		local var_30_3 = var_30_1:seedId(var_30_2[iter_30_0])

		if arg_30_0.backpack:getItemNumByID(var_30_3) > 0 then
			table.insert(var_30_0, var_30_2[iter_30_0])
		end
	end

	return var_30_0
end

function var_0_0.handleResponse(arg_31_0, arg_31_1)
	if arg_31_1.field_info then
		local var_31_0 = arg_31_1.field_info

		arg_31_0.details.field_info[var_31_0.field_id] = arg_31_1.field_info
	end

	if arg_31_1.field_id then
		arg_31_0.details.field_info[arg_31_1.field_id] = arg_31_1
	end

	if arg_31_1.field_num then
		arg_31_0.details.field_num = arg_31_1.field_num
	end

	if arg_31_1.nectar then
		arg_31_0.selfDetails.nectar = arg_31_1.nectar
	end

	if arg_31_1.base_info then
		local var_31_1 = arg_31_1.base_info

		if var_31_1.steal_times then
			arg_31_0.selfDetails.steal_times = var_31_1.steal_times
		end

		if var_31_1.nectar then
			arg_31_0.selfDetails.nectar = var_31_1.nectar
		end
	end

	if arg_31_1.gold_seed then
		arg_31_0.selfDetails.gold_seed = arg_31_1.gold_seed
	end

	if arg_31_1.steal_times then
		arg_31_0.selfDetails.steal_times = arg_31_1.steal_times
	end

	if arg_31_1.server_time then
		xyd.ServerTime.get():resetServerTime(arg_31_1.server_time)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_GARDEN_INFO
	})
end

function var_0_0.getLandInfo(arg_32_0, arg_32_1)
	return arg_32_0.details.field_info[arg_32_1]
end

function var_0_0.getFlowerInfos(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = xyd.tables.activityGardenFlower
	local var_33_1 = {
		id = arg_33_1,
		growTime = var_33_0:growTime(arg_33_1),
		maxGain = var_33_0:maxGain(arg_33_1),
		witherParam = var_33_0:witherParam(arg_33_1),
		witherLimit = var_33_0:witherLimit(arg_33_1),
		pickParam = var_33_0:pickParam(arg_33_1),
		pickLimit = var_33_0:pickLimit(arg_33_1)
	}

	var_33_1.minGain = var_33_1.maxGain - var_33_1.witherParam * var_33_1.witherLimit - var_33_1.pickParam * var_33_1.pickLimit
	var_33_1.price = var_33_0:price(arg_33_1)
	var_33_1.iconPath = var_33_0:icon(arg_33_1)
	var_33_1.txts = {
		xyd.secondsToString1(var_33_1.growTime * 600),
		string.format(var_0_1:translation("GARDEN_TIP_FORMAT_TEXT2"), var_33_1.minGain, var_33_1.maxGain),
		string.format(var_0_1:translation("GARDEN_TIP_FORMAT_TEXT3"), var_33_1.price)
	}

	if arg_33_2 then
		local var_33_2 = arg_33_2.thirsty_value
		local var_33_3 = math.floor((math.min(xyd.ServerTime.get():getServerTime(), arg_33_2.end_time) - arg_33_2.thirsty_time) / 600)

		if var_33_3 < 0 then
			var_33_3 = 0
		end

		local var_33_4 = var_33_2 + var_33_3
		local var_33_5 = math.min(var_33_1.witherLimit, var_33_4)

		if var_33_5 > 0 then
			table.insert(var_33_1.txts, xyd.secondsToString1(var_33_5 * 600))
		else
			table.insert(var_33_1.txts, "0" .. xyd.tables.translation:translation("UNIT_MINUTE"))
		end

		table.insert(var_33_1.txts, arg_33_2.fertilize_times or 0)
		table.insert(var_33_1.txts, arg_33_2.steal_times)

		if arg_33_2.end_time <= xyd.ServerTime.get():getServerTime() then
			var_33_1.state_text = string.format(var_0_1:translation("GARDEN_FLOWER_STATE_TEXT2"), var_33_0:name(arg_33_1))
		else
			var_33_1.state_text = string.format(var_0_1:translation("GARDEN_FLOWER_STATE_TEXT1"), var_33_0:name(arg_33_1))
		end
	end

	return var_33_1
end

function var_0_0.isSelfGarden(arg_34_0)
	return arg_34_0.details.np_info.player_id == arg_34_0.selfPlayer.playerID
end

return var_0_0
