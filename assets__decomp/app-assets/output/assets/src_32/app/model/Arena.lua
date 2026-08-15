local var_0_0 = class("Arena", import(".BaseModel"))
local var_0_1 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.arenaInfos_ = {}
	arg_1_0.showList = 0
	arg_1_0.leftTime = 5
	arg_1_0.rank = 0
	arg_1_0.win = 0
	arg_1_0.rankData = {}
	arg_1_0.isFirstTimeToSetOldBestRank = true
end

function var_0_0.getRank(arg_2_0)
	if arg_2_0.rank > 0 then
		return arg_2_0.rank
	else
		return 19527
	end
end

function var_0_0.getBestRank(arg_3_0)
	if arg_3_0.bestRank and arg_3_0.bestRank > 0 then
		return arg_3_0.bestRank
	elseif arg_3_0.rank > 0 then
		return arg_3_0.rank
	else
		return 19527
	end
end

function var_0_0.getSummitRank(arg_4_0)
	if arg_4_0.rank > 0 then
		return arg_4_0.rank
	else
		return 19527
	end
end

function var_0_0.getDefense(arg_5_0)
	return arg_5_0.defense
end

function var_0_0.getEnemies(arg_6_0)
	return arg_6_0.enemies
end

function var_0_0.onRegister(arg_7_0)
	var_0_0.super.onRegister(arg_7_0)
	arg_7_0:registerEvent(xyd.event.LOAD_ARENA, handler(arg_7_0, arg_7_0.onLoadArena_))
	arg_7_0:registerEvent(xyd.event.LOAD_ARENA_PLAYER_LIST, handler(arg_7_0, arg_7_0.onLoadArenaPlayerList_))
	arg_7_0:registerEvent(xyd.event.ARENA_BUY_TICKET, handler(arg_7_0, arg_7_0.onBuyTicket_))
	arg_7_0:registerEvent(xyd.event.ARENA_RESET_TIMER, handler(arg_7_0, arg_7_0.onResetTimer_))
end

function var_0_0.loadArenaInfo(arg_8_0, arg_8_1)
	if xyd.isFunctionOpen(xyd.FunctionID.ID_ARENA) then
		xyd.Backend.get():request(xyd.mid.LOAD_ARENA, {}, function(arg_9_0, arg_9_1)
			arg_8_1(arg_9_0, arg_9_1)
		end)
	else
		arg_8_1(xyd.error.ERROR)
	end
end

function var_0_0.refreshEnemies(arg_10_0)
	xyd.Backend.get():request(xyd.mid.LOAD_ARENA_PLAYER_LIST, {}, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			-- block empty
		else
			print("error in loading arena player list")
		end
	end)
end

function var_0_0.buyTicket(arg_12_0)
	xyd.Backend.get():request(xyd.mid.ARENA_BUY_TICKET, {}, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			-- block empty
		else
			print("error in buying ticket")
		end
	end)
end

function var_0_0.resetTimer(arg_14_0)
	xyd.Backend.get():request(xyd.mid.ARENA_RESET_TIMER, {}, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK then
			-- block empty
		else
			print("error in resetting timer")
		end
	end)
end

function var_0_0.onLoadArena_(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_1.params

	arg_16_0.rank = var_16_0.rank
	arg_16_0.bestRank = var_16_0.best_rank
	arg_16_0.defense = var_16_0.defense
	arg_16_0.leftTime = var_16_0.left_time
	arg_16_0.buyNum = var_16_0.buy_num
	arg_16_0.lastMatchTime = var_16_0.last_match_time
	arg_16_0.updateCount = var_16_0.update_count
	arg_16_0.enemies = var_16_0.enemies
	arg_16_0.petId = var_16_0.pet_id
	arg_16_0.serverTime = var_16_0.server_time or xyd.ServerTime.get():getServerTime()
	arg_16_0.sealHeroID = var_16_0.ban_hero_id
	arg_16_0.isSealHeroOpen = var_16_0.is_ban_open
	arg_16_0.setFormationTime = var_16_0.set_formation_time
	arg_16_0.fightTimes = var_16_0.fight_times or 0

	if arg_16_0.isFirstTimeToSetOldBestRank and arg_16_0.bestRank then
		arg_16_0.oldBestRank = arg_16_0.bestRank
		arg_16_0.isFirstTimeToSetOldBestRank = false
	end
end

function var_0_0.getDefenseFormation(arg_17_0)
	local var_17_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_17_1 = {}
	local var_17_2 = {}
	local var_17_3

	if arg_17_0.defense then
		var_17_3 = arg_17_0.defense
	else
		local var_17_4 = xyd.db.arenaDefender:getArenaDefenderData(1)

		if var_17_4 and next(var_17_4) then
			arg_17_0.defense = var_17_4
			var_17_3 = var_17_4
		end
	end

	if var_17_3 and next(var_17_3) then
		for iter_17_0, iter_17_1 in pairs(var_17_3) do
			local var_17_5 = var_17_0:getHero(tonumber(iter_17_1))

			if var_17_5 then
				table.insert(var_17_1, var_17_5)
			end
		end
	else
		local var_17_6 = var_17_0:getHeros()
		local var_17_7 = var_17_0:getFormation()

		if var_17_7 then
			local var_17_8 = xyd.splitToNumber(var_17_7, "|")

			for iter_17_2 = 1, #var_17_6 do
				local var_17_9 = var_17_6[iter_17_2]:getHeroID()
				local var_17_10 = var_17_6[iter_17_2]:getTableID()

				if var_17_8[var_17_9] then
					table.insert(var_17_1, var_17_6[iter_17_2])
				end
			end

			xyd.db.arenaDefender:setArenaDefenderData(1, var_17_8)
		end
	end

	var_17_2.heros = var_17_1

	if arg_17_0.petId and arg_17_0.petId ~= 0 then
		var_17_2.petId = arg_17_0.petId
	end

	return var_17_2
end

function var_0_0.getMDefenseFormation(arg_18_0)
	local var_18_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_18_1 = {}
	local var_18_2 = {}
	local var_18_3 = arg_18_0.mDefense or {}

	if var_18_3 and next(var_18_3) then
		for iter_18_0, iter_18_1 in pairs(var_18_3) do
			local var_18_4 = var_18_0:getHero(tonumber(iter_18_1))

			if var_18_4 then
				table.insert(var_18_1, var_18_4)
			end
		end
	end

	var_18_2.heros = var_18_1

	if arg_18_0.mPetId and arg_18_0.mPetId ~= 0 then
		var_18_2.petId = arg_18_0.mPetId
	end

	return var_18_2
end

function var_0_0.saveArenaDefenderData(arg_19_0, arg_19_1)
	local var_19_0 = {}

	for iter_19_0 = 1, #arg_19_1.defenseHeroes do
		if #var_19_0 >= 5 then
			break
		elseif arg_19_1.defenseHeroes[iter_19_0] then
			table.insert(var_19_0, arg_19_1.defenseHeroes[iter_19_0]:getHeroID())
		end
	end

	xyd.db.arenaDefender:setArenaDefenderData(1, var_19_0)

	local var_19_1 = {
		heroIDs = var_19_0
	}

	arg_19_0.defense = var_19_0

	if arg_19_1.pet_id then
		var_19_1.pet_id = arg_19_1.pet_id
		arg_19_0.petId = arg_19_1.pet_id
	end

	xyd.Backend.get():request(xyd.mid.SAVE_ARENA_DEFENSE, var_19_1)
end

function var_0_0.saveModeDefenderData(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = {}

	for iter_20_0 = 1, #arg_20_1.defenseHeroes do
		if #var_20_0 >= 5 then
			break
		elseif arg_20_1.defenseHeroes[iter_20_0] then
			table.insert(var_20_0, arg_20_1.defenseHeroes[iter_20_0]:getHeroID())
		end
	end

	local var_20_1 = {
		heroIDs = var_20_0,
		pet_id = arg_20_1.pet_id,
		leader_id = arg_20_1.leader_id
	}

	xyd.Backend.get():request(xyd.mid.ARENA_MODE_DEFENCE, var_20_1, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK then
			arg_20_0.mDefense = var_20_0
			arg_20_0.mPetId = arg_20_1.pet_id

			if var_20_1.leader_id then
				arg_20_0.mLeadId = var_20_1.leader_id
			end

			if arg_20_2 then
				arg_20_2(arg_21_1)
			end
		end
	end)
end

function var_0_0.loadRankInfo(arg_22_0, arg_22_1)
	xyd.Backend.get():request(xyd.mid.LOAD_ARENA_RANK, {}, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):getGuildRank(function(arg_24_0, arg_24_1)
				if arg_24_0 == xyd.error.OK then
					arg_22_0.rankData = {}

					local var_24_0 = {
						title = "WORLD_BOSS",
						type = xyd.RankType.WB,
						subList = {}
					}

					if arg_23_1.boss_rank and #arg_23_1.boss_rank > 0 then
						for iter_24_0 = 1, #arg_23_1.boss_rank do
							if arg_23_1.boss_rank[iter_24_0] and arg_23_1.boss_rank[iter_24_0].boss_id and arg_23_1.boss_rank[iter_24_0].boss_id > 10010 and arg_23_1.boss_rank[iter_24_0].boss_id <= 10015 then
								local var_24_1 = {
									info_text = "BOSS_RANK_INFO",
									sub_type = xyd.tables.worldBoss.ids_[arg_23_1.boss_rank[iter_24_0].boss_id],
									title = "BOSS_RANK_TITLE_" .. xyd.tables.worldBoss.ids_[arg_23_1.boss_rank[iter_24_0].boss_id],
									rankList = arg_23_1.boss_rank[iter_24_0].infos,
									boss_id = arg_23_1.boss_rank[iter_24_0].boss_id
								}

								if arg_23_1.boss_rank[iter_24_0].my_rank and arg_23_1.boss_rank[iter_24_0].my_rank ~= 0 then
									var_24_1.myRank = {}
									var_24_1.myRank.rank = arg_23_1.boss_rank[iter_24_0].my_rank
									var_24_1.myRank.score = math.floor(arg_23_1.boss_rank[iter_24_0].my_hurt)
								end

								table.insert(var_24_0.subList, var_24_1)
							end

							table.sort(var_24_0.subList, function(arg_25_0, arg_25_1)
								return arg_25_0.sub_type < arg_25_1.sub_type
							end)
						end
					end

					local var_24_2 = {
						title = "NIAN_BOSS",
						type = xyd.RankType.NB,
						subList = {}
					}

					if arg_23_1.newyear_boss_rank and arg_23_1.newyear_boss_rank.boss_id and arg_23_1.newyear_boss_rank.boss_id ~= 0 then
						local var_24_3 = {
							title = "NIAN_RANK_TITLE_1",
							sub_type = 1,
							info_text = "NIAN_RANK_INFO",
							rankList = arg_23_1.newyear_boss_rank.infos,
							boss_id = arg_23_1.newyear_boss_rank.boss_id
						}

						if arg_23_1.newyear_boss_rank.my_rank and arg_23_1.newyear_boss_rank.my_rank ~= 0 then
							var_24_3.myRank = {}
							var_24_3.myRank.rank = arg_23_1.newyear_boss_rank.my_rank
							var_24_3.myRank.score = math.floor(arg_23_1.newyear_boss_rank.my_hurt)
						end

						table.insert(var_24_2.subList, var_24_3)
					end

					if arg_23_1.leisure_arena_rank and arg_23_1.leisure_arena_rank.rank_list and arg_23_1.leisure_arena_rank.rank_list ~= 0 then
						local var_24_4 = {
							info_text = "REGION_CASUAL_RANK",
							sub_type = 5,
							title = "REGION_CASUAL_TXT12",
							rankList = arg_23_1.leisure_arena_rank.rank_list
						}

						if arg_23_1.leisure_arena_rank.my_rank and arg_23_1.leisure_arena_rank.my_rank ~= 0 and arg_23_1.leisure_arena_rank.my_point and arg_23_1.leisure_arena_rank.my_point ~= 0 then
							var_24_4.myRank = {}
							var_24_4.myRank.rank = arg_23_1.leisure_arena_rank.my_rank
							var_24_4.myRank.damage = arg_23_1.leisure_arena_rank.my_point
						end

						table.insert(arenaList.subList, var_24_4)
					end

					if arg_23_1.boss_rank and #arg_23_1.boss_rank > 0 then
						arg_22_0.rankData[xyd.RankType.WB] = var_24_0
					end

					if arg_23_1.newyear_boss_rank then
						arg_22_0.rankData[xyd.RankType.NB] = var_24_2
					end

					arg_22_1()
				end
			end)
		else
			print("save arena rank error!")
		end
	end)
end

function var_0_0.createIllusionTeamRank(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_26_1 = arg_26_1.player_infos

	if var_26_1 and next(var_26_1) then
		local var_26_2 = 0
		local var_26_3 = 1
		local var_26_4 = 1

		for iter_26_0 = 1, #var_26_1 do
			local var_26_5 = var_26_1[iter_26_0]

			if var_26_2 == 0 then
				var_26_2 = var_26_5.hurt
			elseif var_26_2 ~= 0 and var_26_5.hurt == var_26_2 then
				var_26_4 = var_26_4 + 1
			else
				var_26_3 = var_26_3 + var_26_4
				var_26_4 = 1
				var_26_2 = var_26_5.hurt
			end

			var_26_5.illusion_rank = var_26_3

			if var_26_5.player_id == var_26_0.playerID then
				arg_26_1.my_rank = var_26_3
			end
		end
	end

	local var_26_6 = table.insert
	local var_26_7 = arg_26_2.subList
	local var_26_8 = {
		sub_type = 4,
		info_text = "PARADISE_THE_MOST_ATTACK",
		title = "PARADISE_TEAM_RANK"
	}
	local var_26_9

	var_26_9 = arg_26_1.my_rank > 0 and {
		rank = arg_26_1.my_rank,
		damage = arg_26_1.my_hurt
	}
	var_26_8.myRank = var_26_9
	var_26_8.rankList = arg_26_1.player_infos

	var_26_6(var_26_7, var_26_8)
end

function var_0_0.getRankData(arg_27_0)
	return arg_27_0.rankData
end

function var_0_0.onLoadArenaPlayerList_(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_1.params

	if var_28_0 and next(var_28_0) then
		arg_28_0.enemies = var_28_0.enemies

		if xyd.WindowManager.get():isWindowVisible("arena") then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ARENA_ENEMY_UPDATE
			})
		end
	end
end

function var_0_0.onBuyTicket_(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_1.params

	if var_29_0 and next(var_29_0) then
		arg_29_0.leftTime = var_29_0.left_time
		arg_29_0.lastMatchTime = var_29_0.last_match_time
		arg_29_0.buyNum = var_29_0.buy_num

		if arg_29_0.leftTime == 5 and xyd.WindowManager.get():isWindowVisible("arena") then
			var_29_0.refresh_type = 1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ARENA_TICKET_UPDATE,
				params = var_29_0
			})
		end
	end
end

function var_0_0.onResetTimer_(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_1.params

	if var_30_0 and next(var_30_0) then
		arg_30_0.lastMatchTime = var_30_0.last_match_time

		if arg_30_0.lastMatchTime == 0 and xyd.WindowManager.get():isWindowVisible("arena") then
			print("update arena ticket")

			var_30_0.refresh_type = 2

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.ARENA_TICKET_UPDATE,
				params = var_30_0
			})
		end
	end
end

function var_0_0.getRankReward(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_0:getRangeID(arg_31_1)
	local var_31_1 = arg_31_0:getRangeID(arg_31_2)
	local var_31_2 = 0
	local var_31_3 = xyd.tables.arenaReward

	if var_31_0 == var_31_1 then
		var_31_2 = (arg_31_1 - arg_31_2) * var_31_3:rankRewardCrystal(var_31_1)
	else
		for iter_31_0 = var_31_0, var_31_1, -1 do
			if iter_31_0 == var_31_0 then
				var_31_2 = var_31_2 + (arg_31_1 - var_31_3:range(iter_31_0 - 1)) * var_31_3:rankRewardCrystal(iter_31_0)
			elseif iter_31_0 == var_31_1 then
				var_31_2 = var_31_2 + (var_31_3:range(iter_31_0) - arg_31_2) * var_31_3:rankRewardCrystal(iter_31_0)
			else
				var_31_2 = var_31_2 + (var_31_3:range(iter_31_0) - var_31_3:range(iter_31_0 - 1)) * var_31_3:rankRewardCrystal(iter_31_0)
			end
		end
	end

	if var_31_2 == 0 then
		var_31_2 = 1
	end

	return math.ceil(var_31_2)
end

function var_0_0.getRangeID(arg_32_0, arg_32_1)
	local var_32_0 = xyd.tables.arenaReward:getRangeTable()

	local function var_32_1(arg_33_0, arg_33_1, arg_33_2)
		if arg_33_2 < arg_33_1 then
			arg_33_2, arg_33_1 = arg_33_1, arg_33_2
		end

		if arg_33_0 > var_32_0[arg_33_2] or arg_33_0 < var_32_0[arg_33_1] then
			return
		end

		if arg_33_0 > var_32_0[arg_33_1] and arg_33_0 <= var_32_0[arg_33_2] and arg_33_1 == arg_33_2 - 1 then
			return arg_33_2
		end

		if arg_33_1 == arg_33_2 and var_32_0[arg_33_1] == arg_33_0 then
			return arg_33_1
		end

		local var_33_0 = var_32_0[math.floor((arg_33_1 + arg_33_2) / 2)]

		if arg_33_0 <= var_33_0 then
			arg_33_2 = math.floor((arg_33_1 + arg_33_2) / 2)

			return var_32_1(arg_33_0, arg_33_1, arg_33_2)
		elseif var_33_0 < arg_33_0 then
			arg_33_1 = math.floor((arg_33_1 + arg_33_2) / 2)

			return var_32_1(arg_33_0, arg_33_1, arg_33_2)
		end
	end

	return (var_32_1(arg_32_1, 1, #var_32_0))
end

function var_0_0.sealHeroByTableID(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = {
		table_id = arg_34_1
	}

	xyd.Backend.get():request(xyd.mid.SEAL_HERO, var_34_0, function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			arg_34_0.sealHeroID = arg_34_1
		end

		if arg_34_2 then
			arg_34_2(arg_35_0, arg_35_1)
		end
	end)
end

function var_0_0.loadModeInfo(arg_36_0, arg_36_1)
	xyd.Backend.get():request(xyd.mid.ARENA_MODE_INFO, {}, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			arg_36_0.modeType = arg_37_1.mode
			arg_36_0.subMode = arg_37_1.submode
			arg_36_0.mRank = arg_37_1.rank
			arg_36_0.mDefense = xyd.split(arg_37_1["defense_" .. arg_36_0.modeType], "|")
			arg_36_0.mLeftTime = arg_37_1.left_time
			arg_36_0.mBuyNum = arg_37_1.buy_num
			arg_36_0.mLastMatchTime = arg_37_1.last_match_time
			arg_36_0.mPetId = arg_37_1.pet_id
			arg_36_0.mEnemies = arg_37_1.enemies
			arg_36_0.mLeadId = arg_37_1.leader
		end

		if arg_36_1 then
			arg_36_1(arg_37_0, arg_37_1)
		end
	end)
end

function var_0_0.loadModeSchedule(arg_38_0, arg_38_1)
	xyd.Backend.get():request(xyd.mid.ARENA_MODE_SCHEDULE, {}, function(arg_39_0, arg_39_1)
		if arg_39_0 == xyd.error.OK and arg_38_1 then
			arg_38_1(arg_39_1)
		end
	end)
end

function var_0_0.buyModeTicket(arg_40_0)
	xyd.Backend.get():request(xyd.mid.ARENA_MODE_BUY_TICKET, {}, function(arg_41_0, arg_41_1)
		if arg_41_0 == xyd.error.OK then
			arg_40_0.mLeftTime = arg_41_1.left_time
			arg_40_0.mLastMatchTime = arg_41_1.last_match_time
			arg_40_0.mBuyNum = arg_41_1.buy_num

			if arg_40_0.mLeftTime == 5 then
				local var_41_0 = xyd.WindowManager.get():getWindow("arena")

				if var_41_0 then
					var_41_0:refreshTicket({
						refresh_type = 1
					}, true)
				end
			end
		end
	end)
end

function var_0_0.resetModeTime(arg_42_0)
	xyd.Backend.get():request(xyd.mid.ARENA_MODE_RESET_TIME, {}, function(arg_43_0, arg_43_1)
		if arg_43_0 == xyd.error.OK then
			arg_42_0.mLastMatchTime = arg_43_1.last_match_time

			local var_43_0 = xyd.WindowManager.get():getWindow("arena")

			if var_43_0 then
				var_43_0:refreshTicket({
					refresh_type = 2
				}, true)
			end
		end
	end)
end

function var_0_0.refreshModeEnemies(arg_44_0)
	xyd.Backend.get():request(xyd.mid.ARENA_MODE_ENEMY_LIST, {}, function(arg_45_0, arg_45_1)
		if arg_45_0 == xyd.error.OK then
			arg_44_0.mEnemies = arg_45_1.enemies

			local var_45_0 = xyd.WindowManager.get():getWindow("arena")

			if var_45_0 then
				var_45_0:updateEnemyListView()
			end
		end
	end)
end

return var_0_0
