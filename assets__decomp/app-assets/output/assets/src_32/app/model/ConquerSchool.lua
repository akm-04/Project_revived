local var_0_0 = class("ConquerSchool", import(".BaseModel"))
local var_0_1 = xyd.tables.conquerSchoolCampaign

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.info = {}
	arg_1_0.lastID = 0
	arg_1_0.lastTeamID = 0
	arg_1_0.lastLeftTimes = 0
	arg_1_0.loopID = 1
	arg_1_0.currentID = 0
	arg_1_0.passedID = 0
	arg_1_0.leftTimes = 0
	arg_1_0.isBuffOn = 0
	arg_1_0.reportAwardTimes = 0
	arg_1_0.isPromote = false
	arg_1_0.teamStatus = {}
	arg_1_0.usedHeros = {}
	arg_1_0.usedPets = {}
	arg_1_0.reportList = {}
	arg_1_0.reportDatas = {}
	arg_1_0.awards = {}
	arg_1_0.isLoadInfo = false
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.updateInfo(arg_3_0, arg_3_1)
	arg_3_0.info = arg_3_1
	arg_3_0.loopID = arg_3_1.conquer_loop_id
	arg_3_0.currentID = arg_3_1.current_id
	arg_3_0.passedID = arg_3_1.passed_id
	arg_3_0.leftTimes = arg_3_1.left_times
	arg_3_0.isBuffOn = arg_3_1.is_buff_on
	arg_3_0.reportAwardTimes = arg_3_1.report_award_times
	arg_3_0.teamStatus = arg_3_1.team_status
	arg_3_0.usedHeroes = arg_3_1.used_heroes
	arg_3_0.usedPets = arg_3_1.used_pets
	arg_3_0.buyConquerTimes = arg_3_1.buy_conquer_times
	arg_3_0.isLoadInfo = true
end

function var_0_0.clear(arg_4_0)
	arg_4_0.lastTeamID = 0
	arg_4_0.lastID = 0
	arg_4_0.lastLeftTimes = 0
	arg_4_0.awards = {}
	arg_4_0.isPromote = false
end

function var_0_0.getConquerSchoolInfo(arg_5_0)
	return arg_5_0.info
end

function var_0_0.getBuyConquerTimes(arg_6_0)
	return arg_6_0.buyConquerTimes
end

function var_0_0.checkEnd(arg_7_0)
	if arg_7_0.currentID == arg_7_0.passedID then
		return true
	elseif var_0_1:isOpen(arg_7_0.currentID) == 0 then
		return true
	elseif arg_7_0.loopID > xyd.tables.misc.conquerSchoolMaxLoop then
		return true
	end

	return false
end

function var_0_0.getTeamStatus(arg_8_0)
	return arg_8_0.teamStatus
end

function var_0_0.getLoopID(arg_9_0)
	return arg_9_0.loopID or 1
end

function var_0_0.getCurrentID(arg_10_0)
	if arg_10_0.lastID ~= 0 then
		return arg_10_0.lastID
	end

	return arg_10_0.currentID
end

function var_0_0.getIsBuffOn(arg_11_0)
	return arg_11_0.isBuffOn
end

function var_0_0.getPromote(arg_12_0)
	return arg_12_0.isPromote or false
end

function var_0_0.getLastID(arg_13_0)
	return arg_13_0.lastID
end

function var_0_0.getLastTeamID(arg_14_0)
	return arg_14_0.lastTeamID
end

function var_0_0.setLastTeamID(arg_15_0, arg_15_1)
	arg_15_0.lastTeamID = arg_15_1
end

function var_0_0.getLastLeftTimes(arg_16_0)
	return arg_16_0.lastLeftTimes
end

function var_0_0.getLeftTimes(arg_17_0)
	return arg_17_0.leftTimes
end

function var_0_0.getAwards(arg_18_0)
	return arg_18_0.awards
end

function var_0_0.checkTeamCanFight(arg_19_0, arg_19_1)
	if arg_19_0.teamStatus[arg_19_1] == 1 then
		return false
	else
		return true
	end
end

function var_0_0.getUsedHeros(arg_20_0)
	return arg_20_0.usedHeroes
end

function var_0_0.getUsedPets(arg_21_0)
	return arg_21_0.usedPets
end

function var_0_0.getMaxTeamNum(arg_22_0)
	local var_22_0 = var_0_1:teams(arg_22_0:getCurrentID())
	local var_22_1 = 0

	for iter_22_0 = 1, #var_22_0 do
		if #var_22_0[iter_22_0] > 1 or #var_22_0[iter_22_0] == 1 and var_22_0[iter_22_0][1] ~= 0 then
			var_22_1 = var_22_1 + 1
		end
	end

	return var_22_1
end

function var_0_0.loadConquerSchoolInfo(arg_23_0, arg_23_1, arg_23_2)
	if not arg_23_2 and arg_23_0.isLoadInfo then
		if arg_23_1 then
			arg_23_1(true)
		end

		return
	end

	local var_23_0 = {}

	xyd.Backend.get():request(xyd.mid.GET_CONQUER_SCHOOL_INFO, var_23_0, function(arg_24_0, arg_24_1, arg_24_2)
		if arg_24_0 == xyd.error.OK then
			arg_23_0:updateInfo(arg_24_1.info)

			if arg_23_1 then
				arg_23_1(true)
			end
		end
	end)
end

function var_0_0.startFight(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.START_CONQUER_SCHOOL_FIGHT, var_25_0, function(arg_26_0, arg_26_1, arg_26_2)
		if arg_26_0 == xyd.error.OK then
			arg_25_0.leftTimes = arg_25_0.leftTimes - 1
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.buyConquer(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0

	var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.BUY_CONQUER_TIMES, nil, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			arg_27_0.leftTimes = arg_27_0.leftTimes + 1
			arg_27_0.buyConquerTimes = arg_27_0.buyConquerTimes + 1
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.fightResult(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	xyd.Backend.get():request(xyd.mid.CONQUER_SCHOOL_FIGHT_RESULT, var_29_0, function(arg_30_0, arg_30_1, arg_30_2)
		if arg_30_0 == xyd.error.OK then
			if arg_30_1.is_promote then
				arg_29_0.isPromote = arg_30_1.is_promote
			end

			if arg_30_1.conquer_lev then
				local var_30_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				var_30_0:updateConquerLev(arg_30_1.conquer_lev)
				xyd.Backend.get():enterChatRoom(var_30_0.region)
				xyd.Backend.get():enterServiceChatRoom(99999)

				if var_30_0.guildID and var_30_0.guildID ~= 0 then
					xyd.Backend.get():enterLeagueRoom(var_30_0.guildID)
				end
			end

			if arg_30_1.conquer_loop_id then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):updateConquerLoopID(arg_30_1.conquer_loop_id)
			end

			if arg_30_1.conquer_region then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).conquerRegion = arg_30_1.conquer_region
			end

			if arg_30_1.is_buff_on then
				arg_29_0.isBuffOn = arg_30_1.is_buff_on
			end

			if arg_29_0.isPromote and arg_30_1.awards then
				arg_29_0.awards = arg_30_1.awards
				arg_29_0.lastID = arg_29_0.currentID
				arg_29_0.lastLeftTimes = arg_29_0.leftTimes
			end

			if arg_30_1.info then
				arg_29_0:updateInfo(arg_30_1.info)
			end
		end

		arg_29_0:setLastTeamID(var_29_0.team_id)

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end)
end

function var_0_0.getReportList(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CONQUER_SCHOOL_REPORT_LIST, var_31_0, function(arg_32_0, arg_32_1, arg_32_2)
		if arg_32_0 == xyd.error.OK then
			arg_31_0.reportList = arg_32_1.reports
		end

		if var_31_0.team_id then
			arg_31_0:setLastTeamID(var_31_0.team_id)
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end)
end

function var_0_0.getReport(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_CONQUER_SCHOOL_REPORT, var_33_0, function(arg_34_0, arg_34_1, arg_34_2)
		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.reset(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = arg_35_1 or {}

	xyd.Backend.get():request(xyd.mid.RESET_CONQUER_SCHOOL, var_35_0, function(arg_36_0, arg_36_1, arg_36_2)
		if arg_36_0 == xyd.error.OK then
			arg_35_0:updateInfo(arg_36_1.info)
			arg_35_0:clear()
		end

		if arg_35_2 then
			arg_35_2(arg_36_0, arg_36_1)
		end
	end)
end

return var_0_0
