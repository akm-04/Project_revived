local var_0_0 = class("PeakArena", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.point = 0
	arg_1_0.teams = {}
	arg_1_0.pets = {}
	arg_1_0.pets[1] = {}
	arg_1_0.pets[2] = {}
	arg_1_0.pets[3] = {}
	arg_1_0.leftTimes = 0
	arg_1_0.matches = {}
	arg_1_0.coolTime = 0
	arg_1_0.buyTimes = 0
	arg_1_0.revengeList = {}
	arg_1_0.myRank = 0
	arg_1_0.records = {}
	arg_1_0.reports = {}
	arg_1_0.attackTeams_ = {}
	arg_1_0.enemyMatched_ = {}
	arg_1_0.currentBattleRound_ = 0
	arg_1_0.battleResult_ = {}
	arg_1_0.reportInvalid_ = {}
	arg_1_0.battleReport_ = {}
	arg_1_0.totalResult_ = nil
	arg_1_0.isNeedNextBattle_ = nil
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_OLD_PEAK_ARENA, handler(arg_2_0, arg_2_0.onLoadPeakArena_))
end

function var_0_0.loadPeakArena(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.OLD_PEAK_LOAD_INFO, {}, function(arg_4_0, arg_4_1)
		if arg_3_1 then
			arg_3_1(arg_4_0)
		end
	end)
end

function var_0_0.changeTeam(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.OLD_PEAK_CHANGE_TEAMS, var_5_0, function(arg_6_0, arg_6_1)
		if arg_5_2 then
			arg_5_2(arg_6_0)
		end
	end)
end

function var_0_0.refreshEnemies(arg_7_0, arg_7_1)
	xyd.Backend.get():request(xyd.mid.OLD_PEAK_MATCH_ENEMIES, {}, function(arg_8_0, arg_8_1)
		arg_7_0.matches = arg_8_1

		if arg_7_1 then
			arg_7_1(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getPeakInfo(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_2 or {}

	xyd.Backend.get():request(xyd.mid.OLD_PEAK_GET_RANK_INFO, var_9_0, function(arg_10_0, arg_10_1)
		if arg_9_1 then
			arg_9_1(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.buyChallengeTimes(arg_11_0, arg_11_1)
	xyd.Backend.get():request(xyd.mid.OLD_PEAK_BUY_TIMES, {}, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.leftTimes = 5
			arg_11_0.coolTime = 0

			if arg_11_0.handle_ then
				var_0_1.unscheduleGlobal(arg_11_0.handle_)
			end
		end

		if arg_11_1 then
			arg_11_1(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.resetCoolTime(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.OLD_PEAK_RESET_TIMES, {}, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_0.coolTime = 0

			if arg_13_0.handle_ then
				var_0_1.unscheduleGlobal(arg_13_0.handle_)
			end
		end

		if arg_13_1 then
			arg_13_1(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.getPeakRecords(arg_15_0, arg_15_1)
	xyd.Backend.get():request(xyd.mid.OLD_PEAK_GET_RECORDS, {}, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0.records = arg_16_1
		end

		if arg_15_1 then
			arg_15_1(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.getPeakReports(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_1 or {}

	xyd.Backend.get():request(xyd.mid.OLD_PEAK_GET_REPORT, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0.reports = arg_18_1
		end

		if arg_17_2 then
			arg_17_2(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.getCoolTimeStr(arg_19_0)
	local var_19_0 = ""
	local var_19_1 = ""
	local var_19_2 = ""
	local var_19_3 = arg_19_0.coolTime
	local var_19_4 = math.floor(var_19_3 / 60)
	local var_19_5 = var_19_3 % 60

	if var_19_4 >= 10 then
		var_19_1 = tostring(var_19_4)
	else
		var_19_1 = "0" .. tostring(var_19_4)
	end

	if var_19_5 >= 10 then
		var_19_2 = tostring(var_19_5)
	else
		var_19_2 = "0" .. tostring(var_19_5)
	end

	return var_19_1 .. ":" .. var_19_2
end

function var_0_0.setTeams(arg_20_0, arg_20_1)
	arg_20_0.teams = arg_20_1
end

function var_0_0.setPets(arg_21_0, arg_21_1)
	arg_21_0.pets = arg_21_1
end

function var_0_0.onLoadPeakArena_(arg_22_0, arg_22_1)
	local var_22_0 = arg_22_1.params

	if var_22_0.self_info then
		arg_22_0.point = var_22_0.self_info.score
		arg_22_0.teams[1] = var_22_0.self_info.team1
		arg_22_0.teams[2] = var_22_0.self_info.team2
		arg_22_0.teams[3] = var_22_0.self_info.team3
		arg_22_0.pets[1][1] = var_22_0.self_info.pet1
		arg_22_0.pets[2][1] = var_22_0.self_info.pet2
		arg_22_0.pets[3][1] = var_22_0.self_info.pet3
		arg_22_0.leftTimes = var_22_0.self_info.challenge_times
		arg_22_0.coolTime = var_22_0.self_info.left_time
		arg_22_0.buyTimes = var_22_0.self_info.buy_times
		arg_22_0.revengeList = var_22_0.enemies
		arg_22_0.myRank = var_22_0.rank

		if arg_22_0.handle_ then
			var_0_1.unscheduleGlobal(arg_22_0.handle_)
		end

		if arg_22_0.coolTime and arg_22_0.coolTime > 0 then
			arg_22_0.handle_ = var_0_1.scheduleGlobal(function()
				arg_22_0.coolTime = arg_22_0.coolTime - 1

				if arg_22_0.coolTime <= 0 then
					arg_22_0.coolTime = 0

					var_0_1.unscheduleGlobal(arg_22_0.handle_)

					local var_23_0 = xyd.WindowManager.get():getWindow("peak_arena_old")

					if var_23_0 then
						var_23_0:updateChallengeBtnTxt()
					end
				end
			end, 1)
		end
	end

	if var_22_0.matches then
		arg_22_0.matches = var_22_0.matches
	end

	dump(var_22_0)

	arg_22_0.teams = arg_22_0:formatTeamHeros(arg_22_0.teams, arg_22_0.player.playerID)
	arg_22_0.pets = arg_22_0:formatTeamHeros(arg_22_0.pets, arg_22_0.player.playerID, true)
end

function var_0_0.formatTeamHeros(arg_24_0, arg_24_1, arg_24_2, arg_24_3, arg_24_4)
	local var_24_0 = {}
	local var_24_1 = arg_24_1 or {}

	for iter_24_0 = 1, 3 do
		local var_24_2

		if arg_24_3 then
			var_24_2 = {}

			if var_24_1[iter_24_0] then
				for iter_24_1, iter_24_2 in pairs(var_24_1[iter_24_0]) do
					local var_24_3 = import("app.model.Pet").new()

					var_24_3:populate(iter_24_2)

					var_24_2[iter_24_1] = var_24_3
				end
			end
		else
			var_24_2 = {}

			for iter_24_3, iter_24_4 in pairs(var_24_1[iter_24_0]) do
				local var_24_4 = import("app.model.Hero").new()

				var_24_4:populate(iter_24_4)

				if arg_24_4 and arg_24_4 > 0 then
					var_24_4:setConquerSchoolLev(arg_24_4)
				end

				var_24_2[iter_24_3] = var_24_4
			end
		end

		var_24_0[iter_24_0] = var_24_2
	end

	return var_24_0
end

function var_0_0.refreshDefenseTeam(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_0:generatePartnerIds(arg_25_1)
	local var_25_1 = arg_25_0:generatePartnerIds(arg_25_2, true)

	arg_25_0:changeTeam({
		team1 = var_25_0[1],
		team2 = var_25_0[2],
		team3 = var_25_0[3],
		pet1 = var_25_1[1],
		pet2 = var_25_1[2],
		pet3 = var_25_1[3]
	}, function(arg_26_0)
		if arg_26_0 == xyd.error.OK then
			arg_25_0.teams = arg_25_1
			arg_25_0.pets = arg_25_2

			local var_26_0 = xyd.WindowManager.get():getWindow("peak_arena_old")

			if var_26_0 then
				var_26_0:showDefenceTeams()
			end
		end
	end)
end

function var_0_0.generatePartnerIds(arg_27_0, arg_27_1, arg_27_2)
	if not arg_27_2 and (not arg_27_1 or next(arg_27_1) == nil) then
		return nil
	end

	local var_27_0 = {}

	for iter_27_0 = 1, 3 do
		local var_27_1 = ""

		if arg_27_2 then
			for iter_27_1 = 1, #arg_27_1[iter_27_0] do
				local var_27_2 = arg_27_1[iter_27_0][iter_27_1]

				if iter_27_1 ~= #arg_27_1[iter_27_0] then
					var_27_1 = var_27_1 .. var_27_2:getPetID() .. "|"
				else
					var_27_1 = var_27_1 .. var_27_2:getPetID()
				end
			end
		else
			for iter_27_2 = 1, #arg_27_1[iter_27_0] do
				local var_27_3 = arg_27_1[iter_27_0][iter_27_2]

				if iter_27_2 ~= #arg_27_1[iter_27_0] then
					var_27_1 = var_27_1 .. var_27_3:getHeroID() .. "|"
				else
					var_27_1 = var_27_1 .. var_27_3:getHeroID()
				end
			end
		end

		var_27_0[iter_27_0] = var_27_1
	end

	return var_27_0
end

function var_0_0.getPoint(arg_28_0)
	return arg_28_0.point
end

function var_0_0.getMatches(arg_29_0)
	return arg_29_0.matches
end

function var_0_0.getMyRank(arg_30_0)
	return arg_30_0.myRank
end

function var_0_0.getTeam(arg_31_0, arg_31_1)
	return arg_31_0.teams[arg_31_1]
end

function var_0_0.getTeams(arg_32_0)
	return arg_32_0.teams
end

function var_0_0.getPets(arg_33_0)
	return arg_33_0.pets
end

function var_0_0.getLeftTimes(arg_34_0)
	return arg_34_0.leftTimes
end

function var_0_0.getRecords(arg_35_0)
	return arg_35_0.records
end

function var_0_0.getReports(arg_36_0)
	return arg_36_0.reports
end

function var_0_0.getBuyTimes(arg_37_0)
	return arg_37_0.buyTimes
end

function var_0_0.setAttackTeams(arg_38_0, arg_38_1)
	arg_38_0.attackTeams = arg_38_1
end

function var_0_0.setEnemyMatched(arg_39_0, arg_39_1)
	arg_39_0.enemyMatched = arg_39_1
end

function var_0_0.setCurrentBattleRound(arg_40_0, arg_40_1)
	arg_40_0.currentBattleRound_ = arg_40_1
end

function var_0_0.getCurrentBattleRound(arg_41_0)
	return arg_41_0.currentBattleRound_
end

function var_0_0.setBattleResult(arg_42_0, arg_42_1, arg_42_2)
	arg_42_0.battleResult_[arg_42_1] = arg_42_2

	arg_42_0:checkBattleResult()

	return arg_42_0.isNeedNextBattle_
end

function var_0_0.getBattleResult(arg_43_0, arg_43_1)
	if arg_43_1 then
		return arg_43_0.battleResult_[arg_43_1]
	else
		return arg_43_0.battleResult_
	end
end

function var_0_0.getRevengeList(arg_44_0)
	return arg_44_0.revengeList
end

function var_0_0.setBattleReport(arg_45_0, arg_45_1, arg_45_2, arg_45_3)
	arg_45_0.battleReport_[arg_45_1] = arg_45_2
	arg_45_0.reportInvalid_[arg_45_1] = arg_45_3 or 0
end

function var_0_0.getBattleReport(arg_46_0, arg_46_1)
	if arg_46_1 then
		return arg_46_0.battleReport_[arg_46_1]
	else
		return arg_46_0.battleReport_
	end
end

function var_0_0.getReportInvalid(arg_47_0)
	return arg_47_0.reportInvalid_
end

function var_0_0.checkBattleResult(arg_48_0)
	local var_48_0 = 0
	local var_48_1 = 0

	for iter_48_0, iter_48_1 in ipairs(arg_48_0.battleResult_) do
		if iter_48_1 >= 1 then
			var_48_0 = var_48_0 + 1
		else
			var_48_1 = var_48_1 + 1
		end
	end

	if var_48_0 >= 2 then
		arg_48_0.totalResult_ = true
		arg_48_0.isNeedNextBattle_ = false
	elseif var_48_1 >= 2 then
		arg_48_0.totalResult_ = false
		arg_48_0.isNeedNextBattle_ = false
	else
		arg_48_0.totalResult_ = nil
		arg_48_0.isNeedNextBattle_ = true
	end
end

function var_0_0.isHasNextRound(arg_49_0)
	return arg_49_0.isNeedNextBattle_
end

function var_0_0.getTotalResult(arg_50_0)
	return arg_50_0.totalResult_
end

function var_0_0.getWinScore(arg_51_0)
	local var_51_0 = 0

	for iter_51_0, iter_51_1 in ipairs(arg_51_0.battleResult_) do
		if iter_51_1 > 0 then
			var_51_0 = var_51_0 + 1
		end
	end

	return var_51_0
end

function var_0_0.getLoseScore(arg_52_0)
	local var_52_0 = 0

	for iter_52_0, iter_52_1 in ipairs(arg_52_0.battleResult_) do
		if iter_52_1 == 0 then
			var_52_0 = var_52_0 + 1
		end
	end

	return var_52_0
end

function var_0_0.clearTotalResult(arg_53_0)
	arg_53_0.totalResult_ = nil
end

function var_0_0.clear(arg_54_0)
	arg_54_0.currentBattleRound_ = 0
	arg_54_0.battleResult_ = {}
	arg_54_0.battleReport_ = {}
	arg_54_0.reportInvalid_ = {}
end

return var_0_0
