local var_0_0 = class("GiftPush", import(".BaseModel"))
local var_0_1 = xyd.tables.giftPush
local var_0_2 = require("framework.scheduler")
local var_0_3 = {
	{
		90002062,
		90002063,
		90002085,
		90002086,
		90002087,
		90002088,
		90002089,
		90002090,
		90002091,
		90002092,
		90002093,
		90002094,
		90002095,
		90002096,
		90002097,
		90002098,
		90002099,
		90002100,
		90002101,
		90002102,
		90002103,
		90002104,
		90002105,
		90002106,
		90002107,
		90002108
	},
	{
		90002072,
		90002073
	},
	{
		90002070,
		90002083
	},
	{
		90002079
	}
}
local var_0_4 = {
	17,
	24,
	27,
	28,
	35,
	36,
	37,
	39,
	40,
	41
}
local var_0_5 = {
	16
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.giftInfos = {}
	arg_1_0.sceneConditions = {}
	arg_1_0.backendCountConditions = {}
	arg_1_0.specialTags = {}
	arg_1_0.specialCount = {}
	arg_1_0.popTag = false
	arg_1_0.specialInfo = {}

	local var_1_0 = arg_1_0.activities:getActivityInfo(xyd.Activities.GiftPushNew)

	if var_1_0 then
		arg_1_0:dealCountInfos(var_1_0.details)
		arg_1_0:dealGiftInfos(var_1_0.details)
	end
end

function var_0_0.getInfo(arg_2_0)
	xyd.Backend.get():request(xyd.mid.GIFT_PUSH_INFO, {}, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:dealCountInfos(arg_3_1)
		end
	end)
end

function var_0_0.dealCountInfos(arg_4_0, arg_4_1)
	if not arg_4_1 or not arg_4_1.condition_info then
		return
	end

	local var_4_0 = arg_4_1.condition_info

	for iter_4_0 = 1, #var_0_5 do
		local var_4_1 = var_0_5[iter_4_0]
		local var_4_2 = "condition_" .. var_4_1

		if var_4_0[var_4_2] then
			arg_4_0.backendCountConditions[var_4_1] = var_4_0[var_4_2]
		else
			arg_4_0.backendCountConditions[var_4_1] = 0
		end
	end
end

function var_0_0.dealGiftInfos(arg_5_0, arg_5_1)
	if not arg_5_1 or not arg_5_1.gift_infos then
		return
	end

	if not arg_5_0.giftInfos then
		arg_5_0.giftInfos = {}
	end

	local var_5_0 = arg_5_1.gift_infos
	local var_5_1 = {}

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		table.insert(var_5_1, {
			gift_id = iter_5_1.gift_id,
			push_time = iter_5_1.push_time
		})
	end

	table.sort(var_5_1, function(arg_6_0, arg_6_1)
		return arg_6_0.push_time < arg_6_1.push_time
	end)

	for iter_5_2, iter_5_3 in pairs(var_5_1) do
		table.insert(arg_5_0.giftInfos, {
			gift_id = iter_5_3.gift_id,
			push_time = iter_5_3.push_time
		})
	end
end

function var_0_0.onRegister(arg_7_0)
	var_0_0.super.onRegister(arg_7_0)
	arg_7_0:registerEvent(xyd.event.RECHARGE, handler(arg_7_0, arg_7_0.onRecharge_))
end

function var_0_0.getGiftInfo(arg_8_0)
	return arg_8_0.giftInfos or {}
end

function var_0_0.giftExist(arg_9_0)
	return #arg_9_0:getGiftInfo() > 0
end

function var_0_0.setGift(arg_10_0, arg_10_1)
	arg_10_0.popTag = true

	if not arg_10_0.giftInfos then
		arg_10_0.giftInfos = {}
	end

	table.insert(arg_10_0.giftInfos, arg_10_1)

	local var_10_0 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_10_0 then
		var_10_0:updateTopBtn()
	end
end

function var_0_0.removeGift(arg_11_0, arg_11_1)
	for iter_11_0, iter_11_1 in ipairs(arg_11_0.giftInfos) do
		if iter_11_1.gift_id == arg_11_1 then
			table.remove(arg_11_0.giftInfos, iter_11_0)

			break
		end
	end

	local var_11_0 = xyd.WindowManager.get():getWindow("main_scene_top")

	if var_11_0 then
		var_11_0:updateTopBtn()
	end
end

function var_0_0.judgeCondition(arg_12_0, arg_12_1)
	local var_12_0 = xyd.splitToNumber(arg_12_1, ":")

	if var_12_0[1] == 1 then
		return arg_12_0.selfPlayer.lev >= var_12_0[2]
	elseif var_12_0[1] == 6 then
		local var_12_1 = var_12_0[2]
		local var_12_2 = 0

		for iter_12_0, iter_12_1 in pairs(arg_12_0.selfPlayer.heros_) do
			if iter_12_1:getItemHeroHasNotEquip(var_12_1) then
				var_12_2 = var_12_2 + 1
			end
		end

		return var_12_2 > 4
	elseif var_12_0[1] == 4 then
		return var_12_0[2] <= arg_12_0.selfPlayer.buyEnergyTimes
	elseif var_12_0[1] == 7 then
		local var_12_3 = 0

		for iter_12_2 = 2, #var_12_0 do
			local var_12_4 = var_12_0[iter_12_2]
			local var_12_5 = 0

			for iter_12_3, iter_12_4 in pairs(arg_12_0.selfPlayer.heros_) do
				if iter_12_4:getItemHeroHasNotEquip(var_12_4) then
					var_12_5 = var_12_5 + 1
				end
			end

			if var_12_5 > 4 and var_12_5 < 10 then
				var_12_3 = var_12_3 + 1
			end
		end

		return var_12_3 > 2
	elseif var_12_0[1] == 14 then
		local var_12_6 = 0

		for iter_12_5 = 2, #var_12_0 do
			local var_12_7 = var_12_0[iter_12_5]
			local var_12_8 = 0

			for iter_12_6, iter_12_7 in pairs(arg_12_0.selfPlayer.collectedPets) do
				if iter_12_7:getItemHeroHasNotEquip(var_12_7) then
					var_12_8 = var_12_8 + 1
				end
			end

			if var_12_8 > 2 then
				var_12_6 = var_12_6 + 1
			end
		end

		return var_12_6 > 2
	elseif var_12_0[1] == 15 then
		if arg_12_0.moneyCount then
			arg_12_0.moneyCount = arg_12_0.moneyCount + 1
		else
			arg_12_0.moneyCount = 1
		end

		return arg_12_0.moneyCount >= var_12_0[2]
	elseif var_12_0[1] == 25 then
		local var_12_9 = arg_12_0.selfPlayer:getBackpack()
		local var_12_10 = xyd.tables.misc.practiceTicketId

		if var_12_9:getItemByID(var_12_10) then
			return false
		end

		return true
	elseif var_12_0[1] == 26 then
		local var_12_11 = arg_12_0.selfPlayer:getBackpack():getItems()

		for iter_12_8, iter_12_9 in pairs(var_12_11) do
			if xyd.tables.item:subType(iter_12_9.itemID) == xyd.ConsumeItemType.SKILL_POINT then
				return false
			end
		end

		return arg_12_0.selfPlayer:getSkillPoint() <= var_12_0[2]
	elseif var_12_0[1] == 34 then
		local var_12_12 = arg_12_0.selfPlayer:getBackpack()
		local var_12_13 = xyd.tables.misc.stoneTicketLow

		if var_12_12:getItemByID(var_12_13) then
			return false
		end

		local var_12_14 = xyd.tables.misc.stoneTicketHigh

		if var_12_12:getItemByID(var_12_14) then
			return false
		end

		return true
	elseif var_12_0[1] == 38 then
		local var_12_15 = xyd.tables.misc.objectBoxBooks
		local var_12_16 = arg_12_0.selfPlayer:getBackpack()

		for iter_12_10, iter_12_11 in pairs(var_12_15) do
			if var_12_16:getItemByID(iter_12_11) then
				return false
			end
		end

		return true
	end

	return false
end

function var_0_0.pushToBackend(arg_13_0, arg_13_1)
	if arg_13_0.activities:isActivityOpen(xyd.Activities.GiftPushNew) then
		xyd.Backend.get():request(xyd.mid.GIFT_PUSH_NEW, {
			gift_id = arg_13_1
		})
	end
end

function var_0_0.judgePush(arg_14_0, arg_14_1)
	return
end

function var_0_0.onRecharge_(arg_15_0, arg_15_1)
	if not arg_15_0:giftExist() then
		return
	end

	local var_15_0 = arg_15_1.params.params.charge_id

	arg_15_0:removeGift(var_15_0)
end

function var_0_0.count(arg_16_0, arg_16_1)
	xyd.Backend.get():request(xyd.mid.GIFT_PUSH_NEW_CLICK, {
		gift_id = arg_16_1
	})
end

function var_0_0.setSceneCondition(arg_17_0, arg_17_1, arg_17_2)
	arg_17_2 = arg_17_2 or 1

	if not arg_17_0.sceneConditions[arg_17_1] then
		arg_17_0.sceneConditions[arg_17_1] = 0
	end

	arg_17_0.sceneConditions[arg_17_1] = arg_17_0.sceneConditions[arg_17_1] + arg_17_2

	arg_17_0:checkGiftByConditionIndex(arg_17_1)
end

function var_0_0.getSceneCondition(arg_18_0, arg_18_1)
	return arg_18_0.sceneConditions[arg_18_1] or 0
end

function var_0_0.cleanSceneCondition(arg_19_0, arg_19_1)
	arg_19_0.sceneConditions[arg_19_1] = 0
end

function var_0_0.setBackendCountCondition(arg_20_0, arg_20_1, arg_20_2)
	arg_20_2 = arg_20_2 or 1

	local var_20_0 = {
		condition = arg_20_1,
		count = arg_20_2
	}

	xyd.Backend.get():request(xyd.mid.GIFT_PUSH_CONDITION_COUNT, var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			if not arg_20_0.backendCountConditions[arg_20_1] then
				arg_20_0.backendCountConditions[arg_20_1] = 0
			end

			arg_20_0.backendCountConditions[arg_20_1] = arg_20_0.backendCountConditions[arg_20_1] + arg_20_2

			arg_20_0:checkGiftByConditionIndex(arg_20_1)
		end
	end)
end

function var_0_0.getBackendCountCondition(arg_22_0, arg_22_1)
	return arg_22_0.backendCountConditions[arg_22_1] or 0
end

function var_0_0.checkGiftByConditionIndex(arg_23_0, arg_23_1)
	local var_23_0 = var_0_1:conditionMap()

	if var_23_0[arg_23_1] then
		local var_23_1 = var_23_0[arg_23_1]

		for iter_23_0, iter_23_1 in ipairs(var_23_1) do
			arg_23_0:checkGift(iter_23_1)
		end
	end
end

function var_0_0.checkGift(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_1

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.giftInfos) do
		if iter_24_1.gift_id == arg_24_1 then
			return
		end
	end

	if var_0_1:isOpen(var_24_0) == 1 and arg_24_0.selfPlayer.charge >= var_0_1:chargeSum(var_24_0) and arg_24_0.selfPlayer.charge <= var_0_1:chargeSumLimit(var_24_0) then
		local var_24_1 = true
		local var_24_2 = var_0_1:condition(var_24_0)

		for iter_24_2, iter_24_3 in ipairs(var_24_2) do
			local var_24_3 = xyd.splitToNumber(iter_24_3, ":")
			local var_24_4 = var_24_3[1]
			local var_24_5 = var_24_3[2]

			if xyd.tableHaveElement(var_0_4, var_24_4) then
				if var_24_5 > arg_24_0:getSceneCondition(var_24_4) then
					var_24_1 = false

					break
				end
			elseif xyd.tableHaveElement(var_0_5, var_24_4) then
				if var_24_5 > arg_24_0:getBackendCountCondition(var_24_4) then
					var_24_1 = false

					break
				end
			elseif not arg_24_0:judgeCondition(iter_24_3) then
				var_24_1 = false

				break
			end
		end

		if var_24_1 then
			arg_24_0:pushToBackend(var_24_0)
		end
	end
end

local var_0_6 = {
	[41] = 3
}
local var_0_7 = 180

function var_0_0.setSpecialTag(arg_25_0, arg_25_1, arg_25_2)
	if var_0_6[arg_25_1] then
		if not arg_25_0.specialTags[arg_25_1] then
			arg_25_0.specialTags[arg_25_1] = {}
		end

		arg_25_0.specialTags[arg_25_1][arg_25_2] = true

		local var_25_0 = true

		for iter_25_0 = 1, var_0_6[arg_25_1] do
			if not arg_25_0.specialTags[arg_25_1][iter_25_0] then
				var_25_0 = false

				break
			end
		end

		for iter_25_1 = #arg_25_0.specialCount, 1, -1 do
			if arg_25_0.specialCount[iter_25_1].index == arg_25_1 then
				table.remove(arg_25_0.specialCount, iter_25_1)
			end
		end

		if var_25_0 then
			arg_25_0:setSceneCondition(arg_25_1)
		else
			arg_25_0:updateSpecialCount(arg_25_1)
		end
	end
end

function var_0_0.updateSpecialCount(arg_26_0, arg_26_1)
	local var_26_0 = {
		index = arg_26_1,
		time = var_0_7
	}

	table.insert(arg_26_0.specialCount, var_26_0)

	if not arg_26_0.countHandle then
		arg_26_0.countHandle = var_0_2.scheduleGlobal(function()
			for iter_27_0 = #arg_26_0.specialCount, 1, -1 do
				local var_27_0 = arg_26_0.specialCount[iter_27_0]

				var_27_0.time = var_27_0.time - 1

				if var_27_0.time <= 0 then
					arg_26_0:cleanSpecialTag(var_27_0.index)
					table.remove(arg_26_0.specialCount, iter_27_0)
				end
			end

			if #arg_26_0.specialCount == 0 then
				var_0_2.unscheduleGlobal(arg_26_0.countHandle)

				arg_26_0.countHandle = nil
			end
		end, 1)
	end
end

function var_0_0.getSpecialTag(arg_28_0, arg_28_1)
	return arg_28_0.specialTags[arg_28_1] or {}
end

function var_0_0.cleanSpecialTag(arg_29_0, arg_29_1)
	arg_29_0.specialTags[arg_29_1] = {}
end

function var_0_0.popGift(arg_30_0)
	if arg_30_0.popTag then
		var_0_2.performWithDelayGlobal(function()
			if xyd.WindowManager.get():isInMainWindow() then
				arg_30_0.popTag = nil

				arg_30_0.selfPlayer:queryChargeData(function()
					xyd.WindowManager.get():openWindow("gift_push", {
						showIndex = #arg_30_0:getGiftInfo()
					})
				end)
			end
		end, 0.7)
	end
end

return var_0_0
