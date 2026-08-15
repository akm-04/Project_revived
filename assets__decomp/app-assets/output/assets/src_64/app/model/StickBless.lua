local var_0_0 = class("StickBless", import(".BaseModel"))
local var_0_1 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.infos = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.StickBless
	}

	arg_3_0.activities:loadSingleActivity(var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_4_1 then
			arg_3_0:updateInfo(arg_4_1)
		end

		if arg_3_1 then
			arg_3_1(arg_4_0, arg_4_1)
		end
	end)
end

function var_0_0.updateInfo(arg_5_0, arg_5_1)
	arg_5_0.activity = arg_5_1
	arg_5_0.baseInfo = arg_5_1.details.base_info or {}
	arg_5_0.stickerList = arg_5_1.details.sticker_list or {}
	arg_5_0.buyTimes = arg_5_1.details.buy_times or {}
end

function var_0_0.getStickerList(arg_6_0)
	return arg_6_0.stickerList or {}
end

function var_0_0.updateStickerList(arg_7_0, arg_7_1)
	arg_7_0.stickerList = arg_7_1
end

function var_0_0.getBaseInfo(arg_8_0)
	return arg_8_0.baseInfo or {}
end

function var_0_0.updateBaseInfo(arg_9_0, arg_9_1)
	arg_9_0.baseInfo = arg_9_1
end

function var_0_0.getBuyTimes(arg_10_0, arg_10_1)
	return arg_10_0.buyTimes[arg_10_1] or 0
end

function var_0_0.stickBlessWord(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = {
		times = arg_11_1
	}

	xyd.Backend.get():request(xyd.mid.STICK_BLESS_WORD, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			local var_12_0 = {
				itemID = var_0_1.activityStickerItem,
				itemNum = arg_11_1 * var_0_1.activityStickerStickCost
			}

			arg_11_0.backpack:removeItem(var_12_0)

			if arg_12_1 and arg_12_1.base_info then
				arg_11_0:updateBaseInfo(arg_12_1.base_info)
			end
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end, nil, nil, false)
end

function var_0_0.stickBlessBan(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {
		idx = arg_13_1
	}

	xyd.Backend.get():request(xyd.mid.STICK_BLESS_BAN, var_13_0, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK and arg_14_1 and arg_14_1.base_info then
			arg_13_0:updateBaseInfo(arg_14_1.base_info)
		end

		if arg_13_2 then
			arg_13_2(arg_14_0, arg_14_1)
		end
	end, nil, nil, false)
end

function var_0_0.stickBlessRank(arg_15_0, arg_15_1)
	xyd.Backend.get():request(xyd.mid.STICK_BLESS_RANK, {}, function(arg_16_0, arg_16_1)
		if arg_15_1 then
			arg_15_1(arg_16_0, arg_16_1)
		end
	end, nil, nil, false)
end

function var_0_0.stickBlessReset(arg_17_0, arg_17_1)
	xyd.Backend.get():request(xyd.mid.STICK_BLESS_RESET, {}, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			if arg_18_1 and arg_18_1.base_info then
				arg_17_0:updateBaseInfo(arg_18_1.base_info)
			end

			if arg_18_1 and arg_18_1.sticker_list then
				arg_17_0:updateStickerList(arg_18_1.sticker_list)
			end
		end

		if arg_17_1 then
			arg_17_1(arg_18_0, arg_18_1)
		end
	end, nil, nil, false)
end

function var_0_0.stickBuy(arg_19_0, arg_19_1)
	xyd.Backend.get():request(xyd.mid.STICK_BLESS_BUY, {}, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK and arg_19_1 then
			arg_19_1(arg_20_1)
		end
	end)
end

function var_0_0.getActivityReward(arg_21_0, arg_21_1, arg_21_2)
	arg_21_0.activities:getActivityReward(xyd.Activities.StickBless, arg_21_1, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			if arg_22_1 and arg_22_1.base_info then
				arg_21_0:updateBaseInfo(arg_22_1.base_info)
			end

			if arg_22_1 and arg_22_1.awards then
				arg_21_0.selfPlayer:handleRewards(arg_22_1.awards)
			end

			if arg_22_1 and arg_22_1.buy_times then
				arg_21_0.buyTimes = arg_22_1.buy_times
			end
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

return var_0_0
