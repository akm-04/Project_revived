local var_0_0 = class("FlappyBird", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.score = 0
	arg_1_0.dailyMission = {}
	arg_1_0.passMission = {}
end

function var_0_0.getInfo(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0 = arg_2_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_GET_INFO, var_2_0, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.baseInfo = arg_3_1.base_info
			arg_2_0.missionList = arg_3_1.mission_list
			arg_2_0.rankInfo = arg_3_1.rank_info
		end

		if arg_2_2 then
			arg_2_2(arg_3_0, arg_3_1)
		end
	end)
end

function var_0_0.getRankList(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_GET_RANK_LIST, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			-- block empty
		end

		if arg_4_2 then
			arg_4_2(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.startGame(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_START_GAME, var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			-- block empty
		end

		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.endGame(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_END_GAME, var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			arg_8_0.baseInfo.points = arg_9_1.points
			arg_8_0.missionList = arg_9_1.mission_list
			arg_8_0.rankInfo = arg_9_1.rank_info
		end

		if arg_8_2 then
			arg_8_2(arg_9_0, arg_9_1)
		end
	end)
end

function var_0_0.getPointAward(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_POINT_AWARD, var_10_0, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			-- block empty
		end

		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.buyPoint(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = arg_12_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_POINT_BUY, var_12_0, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			-- block empty
		end

		if arg_12_2 then
			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.unlockHero(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_UNLOCK_HERO, var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			arg_14_0.baseInfo.status = arg_15_1.status
		end

		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.getAward(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	xyd.Backend.get():request(xyd.mid.FLAPPY_BIRD_GET_AWARD, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK then
			arg_16_0.baseInfo.points = arg_17_1.points
		end

		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.setParams(arg_18_0, arg_18_1)
	if arg_18_1 then
		if arg_18_1.award_step_n then
			arg_18_0.baseInfo.award_step_n = arg_18_1.award_step_n
		end

		if arg_18_1.award_step_s then
			arg_18_0.baseInfo.award_step_s = arg_18_1.award_step_s
		end

		if arg_18_1.status then
			arg_18_0.baseInfo.status = arg_18_1.status
		end

		if arg_18_1.points then
			arg_18_0.baseInfo.points = arg_18_1.points
		end
	end
end

return var_0_0
