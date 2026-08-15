local var_0_0 = class("PeakArena", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.peakArenaRank

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.point = 0
	arg_1_0.teams = {}
	arg_1_0.leftTimes = 0
	arg_1_0.matches = {}
	arg_1_0.coolTime = xyd.ServerTime.get():getServerTime()
	arg_1_0.buyTimes = 0
	arg_1_0.revengeList = {}
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
	arg_2_0:registerEvent(xyd.event.LOAD_PEAK_ARENA, handler(arg_2_0, arg_2_0.onLoadPeakArena_))
end

function var_0_0.loadPeakArena(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.LOAD_PEAK_ARENA, {}, function(arg_4_0, arg_4_1)
		if arg_3_1 then
			arg_3_1(arg_4_0)
		end
	end)
end

function var_0_0.initBaseInfo(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.level = arg_5_1.rank_level
	arg_5_0.rank = arg_5_1.rank
	arg_5_0.myRank = arg_5_1.region_rank
	arg_5_0.point = arg_5_1.rank_point
	arg_5_0.teamNum = var_0_2:teamNum(arg_5_0.level)
	arg_5_0.buyTimes = arg_5_2.buy_times
	arg_5_0.leftTimes = arg_5_2.left_times

	arg_5_0:setCoolTime(arg_5_2.last_fight_time, arg_5_2.last_promote_fight_time)

	arg_5_0.mode = arg_5_2.mode
	arg_5_0.promoteTimes = arg_5_2.promote_challenge_times
	arg_5_0.promoteWin = arg_5_2.promote_wins
	arg_5_0.promoEndTime = arg_5_2.promote_end_time
end

function var_0_0.onLoadPeakArena_(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_1.params

	arg_6_0:initBaseInfo(var_6_0.rank_info, var_6_0.base_info)

	arg_6_0.teams = arg_6_0:getSelfHeros(var_6_0.defense)
end

function var_0_0.getSelfHeros(arg_7_0, arg_7_1, arg_7_2)
	arg_7_2 = arg_7_2 or #arg_7_1

	local var_7_0 = {}

	for iter_7_0 = 1, arg_7_2 do
		local var_7_1 = arg_7_1[iter_7_0]

		if not var_7_1 then
			return
		end

		local var_7_2 = xyd.split(var_7_1, "@")

		if var_7_2 and next(var_7_2) then
			local var_7_3 = {}

			for iter_7_1, iter_7_2 in ipairs(xyd.splitToNumber(var_7_2[1], "|")) do
				local var_7_4 = arg_7_0.player:getHeroByID(iter_7_2)

				if var_7_4 then
					table.insert(var_7_3, var_7_4)
				end
			end

			local var_7_5 = arg_7_0.player:getPetByID(tonumber(var_7_2[2]))

			table.insert(var_7_0, {
				heros = var_7_3,
				pet = var_7_5
			})
		end
	end

	return var_7_0
end

function var_0_0.setCoolTime(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 then
		arg_8_0.coolTime = math.max(arg_8_1 + var_0_2:coolTime(arg_8_0.level), xyd.ServerTime.get():getServerTime())
	else
		arg_8_0.coolTime = xyd.ServerTime.get():getServerTime()
	end

	if arg_8_2 then
		arg_8_0.promoteCoolTime = math.max(arg_8_2 + xyd.tables.misc.peakPromoCoolTime, xyd.ServerTime.get():getServerTime())
	else
		arg_8_0.promoteCoolTime = xyd.ServerTime.get():getServerTime()
	end
end

function var_0_0.changeTeam(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0, var_9_1 = arg_9_0:generatePartnerIds(arg_9_1)

	if var_9_1 then
		return
	end

	xyd.Backend.get():request(xyd.mid.PEAK_CHANGE_TEAMS, {
		formations = var_9_0
	}, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.teams = arg_9_1

			if arg_9_2 then
				arg_9_2()
			end
		end
	end)
end

function var_0_0.refreshEnemies(arg_11_0, arg_11_1)
	xyd.Backend.get():request(xyd.mid.MATCH_ENEMIES, {}, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.matches = arg_12_1.match_infos

			if arg_11_1 then
				arg_11_1()
			end
		end
	end)
end

function var_0_0.getPeakInfo(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_2 or {}

	xyd.Backend.get():request(xyd.mid.GET_PEAK_INFO, var_13_0, function(arg_14_0, arg_14_1)
		if arg_13_1 then
			arg_13_1(arg_14_0, arg_14_1)
		end
	end)
end

function var_0_0.buyChallengeTimes(arg_15_0, arg_15_1)
	xyd.Backend.get():request(xyd.mid.BUY_PEAK_TIMES, {}, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0.leftTimes = 10
			arg_15_0.coolTime = xyd.ServerTime.get():getServerTime()
		end

		if arg_15_1 then
			arg_15_1(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.resetCoolTime(arg_17_0, arg_17_1)
	xyd.Backend.get():request(xyd.mid.RESET_PEAK_TIME, {}, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0.coolTime = xyd.ServerTime.get():getServerTime()
		end

		if arg_17_1 then
			arg_17_1(arg_18_0, arg_18_1)
		end
	end)
end

function var_0_0.getPeakRecordsList(arg_19_0, arg_19_1)
	xyd.Backend.get():request(xyd.mid.PEAK_RECORDS_LIST, {}, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK and arg_19_1 then
			arg_19_1(arg_20_1)
		end
	end)
end

function var_0_0.getPeakRecordsDetail(arg_21_0, arg_21_1, arg_21_2)
	xyd.Backend.get():request(xyd.mid.PEAK_RECORDS_DETAIL, arg_21_1, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK and arg_21_2 then
			arg_21_2(arg_22_1)
		end
	end)
end

function var_0_0.formatTeams(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = {}
	local var_23_1 = arg_23_1 or {}

	for iter_23_0, iter_23_1 in ipairs(var_23_1) do
		local var_23_2 = {
			heros = {}
		}

		for iter_23_2, iter_23_3 in ipairs(iter_23_1.formation_info) do
			if iter_23_3.table_id then
				local var_23_3 = import("app.model.Hero").new()

				var_23_3:populate(iter_23_3)

				if arg_23_2 and arg_23_2 > 0 then
					var_23_3:setConquerSchoolLev(arg_23_2)
				end

				table.insert(var_23_2.heros, var_23_3)
			end
		end

		if iter_23_1.pet_info and iter_23_1.pet_info.table_id then
			var_23_2.pet = import("app.model.Pet").new()

			var_23_2.pet:populate(iter_23_1.pet_info)
		end

		table.insert(var_23_0, var_23_2)
	end

	return var_23_0
end

function var_0_0.generatePartnerIds(arg_24_0, arg_24_1)
	if not arg_24_1 or not next(arg_24_1) then
		return nil
	end

	local var_24_0 = {}
	local var_24_1 = false

	for iter_24_0, iter_24_1 in ipairs(arg_24_1) do
		local var_24_2 = ""

		for iter_24_2, iter_24_3 in ipairs(iter_24_1.heros) do
			if iter_24_2 == 1 then
				var_24_2 = "" .. iter_24_3:getHeroID()
			else
				var_24_2 = var_24_2 .. "|" .. iter_24_3:getHeroID()
			end
		end

		if iter_24_1.pet then
			var_24_2 = var_24_2 .. "@" .. iter_24_1.pet:getPetID()
		end

		if var_24_2 == "" then
			var_24_1 = true
		end

		table.insert(var_24_0, var_24_2)
	end

	return var_24_0, var_24_1
end

function var_0_0.getMatches(arg_25_0)
	return arg_25_0.matches
end

function var_0_0.getTeam(arg_26_0, arg_26_1)
	return arg_26_0.teams[arg_26_1]
end

function var_0_0.getLeftTimes(arg_27_0)
	return arg_27_0.leftTimes
end

function var_0_0.getReports(arg_28_0)
	return arg_28_0.reports
end

function var_0_0.getBuyTimes(arg_29_0)
	return arg_29_0.buyTimes
end

function var_0_0.setAttackTeams(arg_30_0, arg_30_1)
	arg_30_0.attackTeams = arg_30_1
end

function var_0_0.setEnemyMatched(arg_31_0, arg_31_1)
	arg_31_0.enemyMatched = arg_31_1
end

function var_0_0.setCurrentBattleRound(arg_32_0, arg_32_1)
	arg_32_0.currentBattleRound_ = arg_32_1
end

function var_0_0.getCurrentBattleRound(arg_33_0)
	return arg_33_0.currentBattleRound_
end

function var_0_0.setBattleResult(arg_34_0, arg_34_1, arg_34_2)
	arg_34_0.battleResult_[arg_34_1] = arg_34_2

	arg_34_0:checkBattleResult()

	return arg_34_0.isNeedNextBattle_
end

function var_0_0.getBattleResult(arg_35_0, arg_35_1)
	if arg_35_1 then
		return arg_35_0.battleResult_[arg_35_1]
	else
		return arg_35_0.battleResult_
	end
end

function var_0_0.getRevengeList(arg_36_0)
	return arg_36_0.revengeList
end

function var_0_0.setBattleReport(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	arg_37_0.battleReport_[arg_37_1] = arg_37_2
	arg_37_0.reportInvalid_[arg_37_1] = arg_37_3 or 0
end

function var_0_0.getBattleReport(arg_38_0, arg_38_1)
	if arg_38_1 then
		return arg_38_0.battleReport_[arg_38_1]
	else
		return arg_38_0.battleReport_
	end
end

function var_0_0.getReportInvalid(arg_39_0)
	return arg_39_0.reportInvalid_
end

function var_0_0.checkBattleResult(arg_40_0)
	local var_40_0 = 0
	local var_40_1 = 0

	for iter_40_0, iter_40_1 in ipairs(arg_40_0.battleResult_) do
		if iter_40_1 >= 1 then
			var_40_0 = var_40_0 + 1
		else
			var_40_1 = var_40_1 + 1
		end
	end

	if var_40_0 >= 2 then
		arg_40_0.totalResult_ = true
		arg_40_0.isNeedNextBattle_ = false
	elseif var_40_1 >= 2 then
		arg_40_0.totalResult_ = false
		arg_40_0.isNeedNextBattle_ = false
	else
		arg_40_0.totalResult_ = nil
		arg_40_0.isNeedNextBattle_ = true
	end
end

function var_0_0.isHasNextRound(arg_41_0)
	return arg_41_0.isNeedNextBattle_
end

function var_0_0.getTotalResult(arg_42_0)
	return arg_42_0.totalResult_
end

function var_0_0.getWinScore(arg_43_0)
	local var_43_0 = 0

	for iter_43_0, iter_43_1 in ipairs(arg_43_0.battleResult_) do
		if iter_43_1 > 0 then
			var_43_0 = var_43_0 + 1
		end
	end

	return var_43_0
end

function var_0_0.getLoseScore(arg_44_0)
	local var_44_0 = 0

	for iter_44_0, iter_44_1 in ipairs(arg_44_0.battleResult_) do
		if iter_44_1 == 0 then
			var_44_0 = var_44_0 + 1
		end
	end

	return var_44_0
end

function var_0_0.clearTotalResult(arg_45_0)
	arg_45_0.totalResult_ = nil
end

function var_0_0.clear(arg_46_0)
	arg_46_0.currentBattleRound_ = 0
	arg_46_0.battleResult_ = {}
	arg_46_0.battleReport_ = {}
	arg_46_0.reportInvalid_ = {}
end

function var_0_0.getEnemyTeam(arg_47_0, arg_47_1, arg_47_2)
	xyd.Backend.get():request(xyd.mid.GET_ENEMY_TEAM, {
		enemy_id = arg_47_1
	}, function(arg_48_0, arg_48_1)
		if arg_48_0 == xyd.error.OK and arg_47_2 then
			arg_47_2(arg_48_1.defense)
		end
	end)
end

function var_0_0.startFight(arg_49_0, arg_49_1, arg_49_2)
	xyd.Backend.get():request(xyd.mid.PEAK_START_FIGHT, arg_49_1, function(arg_50_0, arg_50_1)
		if arg_50_0 == xyd.error.OK then
			arg_49_0:initBaseInfo(arg_50_1.rank_info, arg_50_1.base_info)

			arg_49_0.matches = nil
		end

		if arg_49_2 then
			arg_49_2(arg_50_0, arg_50_1)
		end
	end)
end

function var_0_0.requestReport(arg_51_0, arg_51_1, arg_51_2)
	xyd.Backend.get():request(xyd.mid.PEAK_RECORDS, arg_51_1, function(arg_52_0, arg_52_1)
		if arg_52_0 == xyd.error.OK and arg_51_2 then
			arg_51_2(arg_52_1)
		end
	end)
end

return var_0_0
