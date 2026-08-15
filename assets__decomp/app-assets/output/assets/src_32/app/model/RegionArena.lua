local var_0_0 = class("RegionArena", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)
end

function var_0_0.onRegister(arg_2_0)
	print("on registering RegionArena")
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.GET_REARENA_INFO, handler(arg_2_0, arg_2_0.onGetRegionArenaInfo_))
end

function var_0_0.onGetRegionArenaInfo_(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.params

	arg_3_0.dailyFightTimes = var_3_0.daily_fight
	arg_3_0.defenceFormation = var_3_0.defence_formation
	arg_3_0.arenaSection = var_3_0.index
	arg_3_0.winTimes = var_3_0.win_times
	arg_3_0.totalFightTimes = var_3_0.total_fight
	arg_3_0.comboWinTimes = var_3_0.keep_win_times
	arg_3_0.kingPoint = var_3_0.point
	arg_3_0.arenaStar = var_3_0.star
	arg_3_0.total = var_3_0.total
	arg_3_0.myRank = var_3_0.my_rank
	arg_3_0.seasonCount = var_3_0.count
	arg_3_0.dayCount = var_3_0.day_count
	arg_3_0.missions = var_3_0.missions
	arg_3_0.missionTime = var_3_0.mission_time
	arg_3_0.awards = var_3_0.awards
	arg_3_0.pet_id = var_3_0.pet_id
	arg_3_0.exchangeTimes = {}

	for iter_3_0 = 1, 3 do
		table.insert(arg_3_0.exchangeTimes, var_3_0["exchange_times_" .. iter_3_0])
	end
end

function var_0_0.getRegionArenaInfo(arg_4_0, arg_4_1)
	xyd.Backend.get():request(xyd.mid.GET_REARENA_INFO, {}, function(arg_5_0, arg_5_1)
		if arg_5_1.is_close then
			arg_4_0.isClose = arg_5_1.is_close
		end

		if arg_4_1 then
			arg_4_1(arg_5_0, arg_5_1)
		end
	end)
end

function var_0_0.giveUpRegionMission(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1 or {}

	xyd.Backend.get():request(xyd.mid.GIVE_UP_REGION_MISSION, var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			-- block empty
		end

		if arg_6_2 then
			arg_6_2(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.saveArenaDefendceFormation(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = arg_8_1 or {}

	xyd.Backend.get():request(xyd.mid.REARENA_MODIFY_DEFENCE, var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			arg_8_0.defenceFormation = arg_9_1.defence_formation
			arg_8_0.pet_id = arg_9_1.pet_id
		end

		if arg_8_2 then
			arg_8_2(arg_9_0, arg_9_1)
		end
	end)
end

function var_0_0.matchEnemy(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(xyd.mid.REARENA_MATCH_ENEMY, {
		is_practice = arg_10_1
	}, function(arg_11_0, arg_11_1)
		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end
	end)
end

function var_0_0.startFight(arg_12_0, arg_12_1)
	xyd.Backend.get():request(xyd.mid.REARENA_START_FIGHT, {}, function(arg_13_0, arg_13_1)
		if arg_12_1 then
			arg_12_1(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.fight(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = arg_14_1 or {}

	xyd.Backend.get():request(xyd.mid.REARENA_FIGHT, var_14_0, function(arg_15_0, arg_15_1)
		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.getRankInfo(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1 or {}

	var_16_0.index = arg_16_0.arenaSection

	xyd.Backend.get():request(xyd.mid.REARENA_LOAD_RANKS, var_16_0, function(arg_17_0, arg_17_1)
		if arg_16_2 then
			arg_16_2(arg_17_0, arg_17_1)
		end
	end)
end

function var_0_0.fightResult(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_1 or {}

	xyd.Backend.get():request(xyd.mid.REARENA_END_FIGHT, var_18_0, function(arg_19_0, arg_19_1)
		if arg_18_2 then
			arg_18_2(arg_19_0, arg_19_1)
		end
	end)
end

function var_0_0.getBattleScoresInfo(arg_20_0, arg_20_1)
	xyd.Backend.get():request(xyd.mid.GET_REARENA_PARTNERS, {}, function(arg_21_0, arg_21_1)
		if arg_20_1 then
			arg_20_1(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.getFightReports(arg_22_0, arg_22_1)
	xyd.Backend.get():request(xyd.mid.REARENA_FIGHT_RECORDS, {}, function(arg_23_0, arg_23_1)
		if arg_22_1 then
			arg_22_1(arg_23_0, arg_23_1)
		end
	end)
end

function var_0_0.getFightReport(arg_24_0, arg_24_1, arg_24_2)
	local var_24_0 = arg_24_1 or {}

	xyd.Backend.get():request(xyd.mid.REARENA_FIGHT_REPORT, var_24_0, function(arg_25_0, arg_25_1)
		if arg_24_2 then
			arg_24_2(arg_25_0, arg_25_1)
		end
	end)
end

function var_0_0.getMissionAwards(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = arg_26_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_MISSION_AWARD, var_26_0, function(arg_27_0, arg_27_1)
		if arg_26_2 then
			arg_26_2(arg_27_0, arg_27_1)
		end
	end)
end

function var_0_0.getExchangeAwards(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_EXCHANGE_AWARD, var_28_0, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			local var_29_0 = false

			for iter_29_0, iter_29_1 in pairs(arg_28_0.awards) do
				if iter_29_1.table_id == arg_29_1.award.table_id then
					arg_28_0.awards[iter_29_0] = arg_29_1.award
					var_29_0 = true

					break
				end
			end

			if not var_29_0 then
				table.insert(arg_28_0.awards, arg_29_1.award)
			end

			arg_28_0.exchangeTimes[var_28_0.exchange_type] = arg_28_0.exchangeTimes[var_28_0.exchange_type] + 1
		end

		if arg_28_2 then
			arg_28_2(arg_29_0, arg_29_1)
		end
	end)
end

function var_0_0.getDefenceFormation(arg_30_0)
	return arg_30_0.defenceFormation
end

function var_0_0.getPetID(arg_31_0)
	return arg_31_0.pet_id
end

function var_0_0.getArenaSection(arg_32_0)
	return arg_32_0.arenaSection
end

function var_0_0.getStar(arg_33_0)
	return arg_33_0.arenaStar
end

function var_0_0.setStar(arg_34_0, arg_34_1)
	arg_34_0.arenaStar = arg_34_1
end

function var_0_0.getRankPercent(arg_35_0)
	if arg_35_0.total <= 0 then
		return 100
	else
		return math.ceil(arg_35_0.myRank / arg_35_0.total * 100)
	end
end

function var_0_0.getSeasonCount(arg_36_0)
	return arg_36_0.seasonCount
end

function var_0_0.getRegionDayCount(arg_37_0)
	return arg_37_0.dayCount or 0
end

return var_0_0
