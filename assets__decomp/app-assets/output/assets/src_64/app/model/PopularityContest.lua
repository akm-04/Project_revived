local var_0_0 = class("PopularityContest", import(".BaseModel"))
local var_0_1 = xyd.tables.activityVotePartner
local var_0_2 = xyd.tables.activityVoteTicket
local var_0_3 = xyd.tables.activityVoteTimeline
local var_0_4 = 6

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.clear(arg_3_0)
	arg_3_0.baseInfo = {}
	arg_3_0.pollInfo = {}
	arg_3_0.pollRecord = {}
	arg_3_0.startPos_ = 1
	arg_3_0.showOrder = xyd.PopularityShowOrder.DOWN
	arg_3_0.stage_ = 0
	arg_3_0.searchInfo = {}
end

function var_0_0.loadInfo(arg_4_0, arg_4_1)
	arg_4_0:clear()

	local var_4_0 = {
		activity_id = xyd.Activities.PopularityContest
	}

	arg_4_0.activities:loadSingleActivity(var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			if arg_5_1 and arg_5_1.details then
				arg_4_0:updateInfo(arg_5_1.details)
			end

			arg_4_0:updateTime(arg_5_1)
		end

		if arg_4_1 then
			arg_4_1(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.updateTime(arg_6_0, arg_6_1)
	arg_6_0.startTime = arg_6_1.start_time
	arg_6_0.endTime = arg_6_1.end_time
end

function var_0_0.updateInfo(arg_7_0, arg_7_1)
	if arg_7_1.base_info then
		arg_7_0:updateBaseInfo(arg_7_1.base_info)
	end

	if arg_7_1.poll_info then
		arg_7_0:updatePollInfo(arg_7_1.poll_info)
	end

	if arg_7_1.poll_record then
		arg_7_0:updatePollRecord(arg_7_1.poll_record)
	end
end

function var_0_0.updateBaseInfo(arg_8_0, arg_8_1)
	arg_8_0.baseInfo = arg_8_1 or {}

	if arg_8_1.day_count and arg_8_1.day_count > 0 then
		arg_8_0.stage_ = var_0_3:getStage(arg_8_1.day_count)
	end
end

function var_0_0.updatePollInfo(arg_9_0, arg_9_1)
	arg_9_0.pollInfo = arg_9_1 or {}
end

function var_0_0.updatePollRecord(arg_10_0, arg_10_1)
	arg_10_0.pollRecord = arg_10_1 or {}
end

function var_0_0.updateSearchInfo(arg_11_0, arg_11_1)
	arg_11_0.searchInfo = arg_11_1 or {}
end

function var_0_0.getSearchInfo(arg_12_0)
	return arg_12_0.searchInfo or {}
end

function var_0_0.getStageEndtime(arg_13_0)
	local var_13_0 = arg_13_0:getBaseInfo()
	local var_13_1 = var_13_0.day_end_time
	local var_13_2 = var_13_0.day_count
	local var_13_3 = var_0_3:time(arg_13_0:getStage())

	if #var_13_3 ~= 2 then
		return 0
	end

	return (var_13_3[2] - var_13_2) * 86400 + var_13_1
end

function var_0_0.getBaseInfo(arg_14_0)
	return arg_14_0.baseInfo or {}
end

function var_0_0.getPredictHero(arg_15_0)
	return arg_15_0:getBaseInfo().predict_hero or 0
end

function var_0_0.getPollInfo(arg_16_0)
	return arg_16_0.pollInfo or {}
end

function var_0_0.getPollRecord(arg_17_0)
	return arg_17_0.pollRecord or {}
end

function var_0_0.getStartPos(arg_18_0)
	return arg_18_0.startPos_ or 1
end

function var_0_0.getStage(arg_19_0)
	return arg_19_0.stage_
end

function var_0_0.getCurrentIndex(arg_20_0)
	return arg_20_0:getStartPos() + #arg_20_0:getPollInfo()
end

function var_0_0.getTotal(arg_21_0)
	return #(var_0_1:ids() or {})
end

function var_0_0.setOrder(arg_22_0, arg_22_1)
	if arg_22_1 then
		arg_22_0.showOrder = arg_22_1
	else
		arg_22_0.showOrder = arg_22_0.showOrder == xyd.PopularityShowOrder.DOWN and xyd.PopularityShowOrder.UP or xyd.PopularityShowOrder.DOWN
	end
end

function var_0_0.getOrder(arg_23_0)
	return arg_23_0.showOrder or xyd.PopularityShowOrder.DOWN
end

function var_0_0.getShowModel(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = var_0_1:models(arg_24_2.table_id)
	local var_24_1 = var_0_1:modelName(arg_24_2.table_id)
	local var_24_2 = 0
	local var_24_3 = 0
	local var_24_4 = 0

	if arg_24_1 == 1 then
		var_24_4 = var_0_2:weight(xyd.PopularityHeroPollType.SUPER) / var_0_2:weight(xyd.PopularityHeroPollType.NORMAL)
	end

	local var_24_5 = 0
	local var_24_6 = var_24_0[1]
	local var_24_7 = 1

	for iter_24_0 = 1, #var_24_0 do
		local var_24_8 = var_24_0[iter_24_0]
		local var_24_9 = arg_24_2[tostring(var_24_8)]

		if var_24_9 and var_24_5 < var_24_9[xyd.PopularityHeroPollType.NORMAL] + var_24_9[xyd.PopularityHeroPollType.SUPER] * var_24_4 then
			var_24_7 = iter_24_0
			var_24_6 = var_24_8
			var_24_5 = var_24_9[xyd.PopularityHeroPollType.NORMAL] + var_24_9[xyd.PopularityHeroPollType.SUPER] * var_24_4
		end
	end

	return var_24_6, var_24_5, var_24_7
end

function var_0_0.poll(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.POPULARITY_POLL, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			arg_25_0:updateInfo(arg_26_1)

			if arg_26_1.base_info then
				arg_25_0:updateBaseInfo(arg_26_1.base_info)
			end

			if arg_26_1.poll_detail then
				arg_25_0:updateSearchInfo(arg_26_1.poll_detail)
			end

			local var_26_0 = {
				itemID = var_0_2:itemID(var_25_0.poll_type),
				itemNum = var_25_0.poll_num
			}

			arg_25_0.backpack:removeItem(var_26_0)

			if arg_26_1.awards then
				local var_26_1 = {
					awards = arg_26_1.awards,
					table_id = var_25_0.table_id
				}

				xyd.WindowManager.get():openWindow("popularity_show_reward", var_26_1)
			end
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end, nil, nil, false)
end

function var_0_0.predict(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = {
		table_id = arg_27_1
	}

	xyd.Backend.get():request(xyd.mid.POPULARITY_PREDICT, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0:updateBaseInfo(arg_28_1.base_info)
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end, nil, nil, false)
end

function var_0_0.getPollPlayerRankList(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = {
		table_id = arg_29_1
	}

	xyd.Backend.get():request(xyd.mid.POPULARITY_POLL_RANK_LIST, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			-- block empty
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end, nil, nil, false)
end

function var_0_0.getPollList(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = 1
	local var_31_1 = xyd.tables.misc.voteListQueryNum

	if arg_31_1 == xyd.PopularityLoadDataType.FRONT then
		var_31_0 = arg_31_0:getStartPos() - var_31_1 + 5
	elseif arg_31_1 == xyd.PopularityLoadDataType.BACK then
		var_31_0 = arg_31_0:getCurrentIndex() - 5
	elseif arg_31_1 == xyd.PopularityLoadDataType.NONE then
		var_31_0 = 1
	end

	if var_31_0 >= arg_31_0:getTotal() then
		return
	elseif var_31_0 < 0 then
		var_31_0 = 1
	end

	local var_31_2 = {
		start_pos = var_31_0,
		query_num = var_31_1,
		order = arg_31_0:getOrder()
	} or {}

	xyd.Backend.get():request(xyd.mid.POPULARITY_POLL_LIST, var_31_2, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			arg_31_0:updatePollInfo(arg_32_1.poll_list)

			arg_31_0.startPos_ = var_31_0
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end, nil, nil, false)
end

function var_0_0.getSingleRankById(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = {
		table_id = arg_33_1
	}

	xyd.Backend.get():request(xyd.mid.POPULARITY_GET_SINGLE_RANK, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			arg_33_0:updateSearchInfo(arg_34_1.hero_poll_info)
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end, nil, nil, false)
end

return var_0_0
