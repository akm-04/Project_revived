local var_0_0 = class("Summer", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	local var_3_0 = {
		activity_id = xyd.Activities.Summer
	}

	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			if arg_4_1 then
				arg_3_0.activity = arg_4_1
				arg_3_0.details = arg_3_0.activity.details
			end

			if arg_3_1 then
				arg_3_1(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.catchFish(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.CATCH_FISH, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			local var_6_0 = {
				itemID = var_5_0.net_item_id
			}

			var_6_0.itemNum = 1

			arg_5_0.selfPlayer:getBackpack():removeItem(var_6_0)
			arg_5_0:handleResponse(arg_6_1)

			if arg_6_1.task_list then
				arg_5_0.details.goldfish_info.task_list = arg_6_1.task_list
			end
		end

		if arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.buyNet(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_NET, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.selfPlayer:getBackpack():addItemsByID(var_0_2.summerGoldFishNetItem, var_0_2.summerGoldFishBuyNum)
		end

		if arg_7_2 then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.buyGoldfishItem(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_GOLDFISH_ITEM, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0:handleResponse(arg_10_1)
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.getGoldfishRankList(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_GOLDFISH_RANK_LIST, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.fishingRankInfo = arg_12_1 or {}

			table.sort(arg_11_0.fishingRankInfo.rank_list, function(arg_13_0, arg_13_1)
				return arg_13_0.total_point > arg_13_1.total_point
			end)
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.fightQuizBoss(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.FIGHT_QUIZ_BOSS, var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			arg_14_0.fightResponse = arg_15_1

			arg_14_0:handleResponse(arg_15_1)
		end

		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.getQuizRankList(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_QUIZ_RANK_LIST, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			arg_16_0.quizRankInfo = arg_17_1 or {}
		end

		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.anserQuiz(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_1 or {}

	xyd.Backend.get():request(xyd.mid.ANSER_QUIZ, var_18_0, function(arg_19_0, arg_19_1)
		if arg_19_0 == xyd.error.OK then
			arg_18_0:handleResponse(arg_19_1)
		end

		if arg_18_2 then
			arg_18_2(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.quizRevive(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_1 or {}

	xyd.Backend.get():request(xyd.mid.QUIZ_REVIVE, var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0:handleResponse(arg_21_1)
		end

		if arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.handleResponse(arg_22_0, arg_22_1)
	if arg_22_1.goldfish_info then
		local var_22_0 = arg_22_0.details.goldfish_info.task_list

		arg_22_0.details.goldfish_info = arg_22_1.goldfish_info

		if not arg_22_0.details.goldfish_info.task_list then
			arg_22_0.details.goldfish_info.task_list = var_22_0
		end

		local var_22_1 = xyd.WindowManager.get():openWindow("summer_fishing")

		if var_22_1 and not tolua.isnull(var_22_1) then
			var_22_1:updatePoints()
		end
	end

	if arg_22_1.big_pass_info then
		arg_22_0.details.big_pass_info = arg_22_1.big_pass_info
	end
end

function var_0_0.updateFishNet(arg_23_0, arg_23_1)
	if arg_23_1.awards then
		arg_23_0.selfPlayer:handleRewards(arg_23_1.awards)

		local var_23_0 = xyd.WindowManager.get():getWindow("summer_fish")

		if var_23_0 and not tolua.isnull(var_23_0) then
			var_23_0:updateNetShow()
		end
	end
end

function var_0_0.createEffect(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_1 .. ".json"
	local var_24_1 = arg_24_1 .. ".atlas"
	local var_24_2 = var_0_3.new(var_24_0, var_24_1, 1)

	var_24_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_24_2
end

function var_0_0.isSummerRedPointShow(arg_25_0)
	if not arg_25_0.details then
		return false
	end

	local var_25_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_25_0 > xyd.tables.misc.summerQuizStartTime and var_25_0 < xyd.tables.misc.summerQuizEndTime and arg_25_0.details.big_pass_info.now_pos == 1 then
		return true
	end

	return false
end

function var_0_0.getReward(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = {
		task_id = arg_26_1
	}

	xyd.Backend.get():request(xyd.mid.SUMMER_TASK, var_26_0, function(arg_27_0, arg_27_1)
		if arg_27_0 == xyd.error.OK then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_27_1.awards)

			if arg_27_1.task_list then
				arg_26_0.details.goldfish_info.task_list = arg_27_1.task_list
			end

			if arg_26_2 then
				arg_26_2(arg_27_0, arg_27_1)
			end
		end
	end)
end

return var_0_0
