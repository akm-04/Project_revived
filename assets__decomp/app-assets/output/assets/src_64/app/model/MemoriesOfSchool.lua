local var_0_0 = class("MemoriesOfSchool", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.mazeFog = {}
	arg_1_0.mapInfo = {}
	arg_1_0.banList = {}
	arg_1_0.baseInfo = {}
	arg_1_0.dropsInfo = {}
	arg_1_0.enemyInfos = {}
	arg_1_0.heroStatus = {
		self_list = {},
		rent_list = {}
	}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.getInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_GET_INFO, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.baseInfo = arg_4_1.base_info

			if arg_4_1.maze_info then
				if arg_4_1.maze_info.map_open then
					arg_3_0.mazeFog = {}

					for iter_4_0, iter_4_1 in pairs(arg_4_1.maze_info.map_open) do
						arg_3_0.mazeFog[tonumber(iter_4_0)] = iter_4_1
					end
				end

				arg_3_0.mapInfo = arg_4_1.maze_info.maze_map
				arg_3_0.enemyInfos = arg_4_1.maze_info.enemy_grids_info
				arg_3_0.baseInfo = arg_4_1.base_info
				arg_3_0.dropsInfo = arg_4_1.drops_info or {}
				arg_3_0.maxFloorInfo = arg_4_1.max_floor_info or {}

				arg_3_0:initHeroStatus(arg_4_1.heroes_status)
			end

			if arg_3_2 then
				arg_3_2(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.getBanList(arg_5_0)
	if arg_5_0.baseInfo and arg_5_0.baseInfo.hero_id ~= 0 then
		arg_5_0.banList = xyd.tables.mazePartnerCampaign:banList(arg_5_0.baseInfo.hero_id)
	end

	return arg_5_0.banList
end

function var_0_0.startGame(arg_6_0, arg_6_1, arg_6_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_START_GAME, arg_6_1, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK then
			arg_6_0.baseInfo = arg_7_1.base_info

			if arg_7_1.maze_info then
				if arg_7_1.maze_info.map_open then
					arg_6_0.mazeFog = {}

					for iter_7_0, iter_7_1 in pairs(arg_7_1.maze_info.map_open) do
						arg_6_0.mazeFog[tonumber(iter_7_0)] = iter_7_1
					end
				end

				arg_6_0.mapInfo = arg_7_1.maze_info.maze_map
				arg_6_0.enemyInfos = arg_7_1.maze_info.enemy_grids_info
				arg_6_0.baseInfo = arg_7_1.base_info
				arg_6_0.dropsInfo = arg_7_1.drops_info or {}

				arg_6_0:initHeroStatus(arg_7_1.heroes_status)
			end

			if arg_6_2 then
				arg_6_2(arg_7_0, arg_7_1)
			end
		end
	end)
end

function var_0_0.rebornHero(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_REBORN_HERO, arg_8_1, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			if arg_8_0.heroStatus.self_list[tostring(arg_8_1.partner_id)] then
				arg_8_0.heroStatus.self_list[tostring(arg_8_1.partner_id)] = {}
				arg_8_0.heroStatus.self_list[tostring(arg_8_1.partner_id)].health = 0
				arg_8_0.heroStatus.self_list[tostring(arg_8_1.partner_id)].is_reborn = 0
				arg_8_0.heroStatus.self_list[tostring(arg_8_1.partner_id)].player_id = arg_8_0.selfPlayer.playerID
			end

			if arg_8_2 then
				arg_8_2(arg_9_0, arg_9_1)
			end
		end
	end)
end

function var_0_0.getMonsterInfos(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_GET_MONSTER_INFO, arg_10_1, function(arg_11_0, arg_11_1)
		if arg_11_0 == xyd.error.OK then
			-- block empty
		end
	end)
end

function var_0_0.initHeroStatus(arg_12_0, arg_12_1)
	if not arg_12_1 then
		return
	end

	arg_12_0.heroStatus = {}
	arg_12_0.heroStatus.self_list = {}
	arg_12_0.heroStatus.rent_list = {}

	for iter_12_0, iter_12_1 in pairs(arg_12_0.selfPlayer.heros_) do
		if iter_12_1 and iter_12_1:getHeroID() and tostring(iter_12_1:getHeroID()) then
			local var_12_0 = tostring(iter_12_1:getHeroID())
			local var_12_1 = {
				player_id = arg_12_0.selfPlayer.playerID
			}

			if arg_12_1 and arg_12_1[var_12_0] and var_12_1 then
				var_12_1.health = 1
				var_12_1.is_reborn = arg_12_1[var_12_0].is_reborn or 0
				var_12_1.hp = arg_12_1[var_12_0].hp or 0
				var_12_1.mp = arg_12_1[var_12_0].mp or 0
			else
				var_12_1.health = 0
				var_12_1.is_reborn = 0
			end

			arg_12_0.heroStatus.self_list[var_12_0] = var_12_1
		end
	end
end

function var_0_0.updateHeroStatus(arg_13_0, arg_13_1)
	if not arg_13_0.heroStatus or not arg_13_0.heroStatus.self_list then
		arg_13_0:initHeroStatus(arg_13_1)
	end

	for iter_13_0, iter_13_1 in pairs(arg_13_1) do
		arg_13_0.heroStatus.self_list[tostring(iter_13_1.hero_id or iter_13_0)] = {}
		arg_13_0.heroStatus.self_list[tostring(iter_13_1.hero_id or iter_13_0)].health = 1
		arg_13_0.heroStatus.self_list[tostring(iter_13_1.hero_id or iter_13_0)].is_reborn = iter_13_1.is_reborn
		arg_13_0.heroStatus.self_list[tostring(iter_13_1.hero_id or iter_13_0)].hp = iter_13_1.hp
		arg_13_0.heroStatus.self_list[tostring(iter_13_1.hero_id or iter_13_0)].mp = iter_13_1.mp
		arg_13_0.heroStatus.self_list[tostring(iter_13_1.hero_id or iter_13_0)].player_id = arg_13_0.selfPlayer.playerID
	end
end

function var_0_0.getHeroStatus(arg_14_0)
	return arg_14_0.heroStatus
end

function var_0_0.saveMap(arg_15_0, arg_15_1, arg_15_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_SAVE_MAP, arg_15_1, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK and arg_15_2 then
			arg_15_2(arg_16_0, arg_16_1)
		end
	end)
end

function var_0_0.openBox(arg_17_0, arg_17_1, arg_17_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_OPEN_BOX, arg_17_1, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0.baseInfo = arg_18_1.base_info
			arg_17_0.dropsInfo = arg_18_1.drops_info

			if arg_17_0.mapInfo[arg_17_1.grid_pos] == xyd.MazeType.SMALL_BOX then
				arg_17_0.mapInfo[arg_17_1.grid_pos] = xyd.MazeType.SMALL_BOX_OPEN
			elseif arg_17_0.mapInfo[arg_17_1.grid_pos] == xyd.MazeType.BIG_BOX then
				arg_17_0.mapInfo[arg_17_1.grid_pos] = xyd.MazeType.BIG_BOX_OPEN
			end

			if arg_17_2 then
				arg_17_2(arg_18_0, arg_18_1)
			end
		end
	end)
end

function var_0_0.enterNextFloor(arg_19_0, arg_19_1, arg_19_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_ENTER_NEXT_FLOOR, arg_19_1, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0.baseInfo = arg_20_1.base_info

			if arg_20_1.maze_info then
				if arg_20_1.maze_info.map_open then
					arg_19_0.mazeFog = {}

					for iter_20_0, iter_20_1 in pairs(arg_20_1.maze_info.map_open) do
						arg_19_0.mazeFog[tonumber(iter_20_0)] = iter_20_1
					end
				end

				arg_19_0.mapInfo = arg_20_1.maze_info.maze_map
				arg_19_0.enemyInfos = arg_20_1.maze_info.enemy_grids_info
				arg_19_0.baseInfo = arg_20_1.base_info
			end

			if arg_19_2 then
				arg_19_2(arg_20_0, arg_20_1)
			end
		end
	end)
end

function var_0_0.getEnemyInfo(arg_21_0, arg_21_1, arg_21_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_GET_ENEMY_INFO, arg_21_1, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0:setTempEnemiesInfo(arg_22_1.enemy_info.enemy_status, arg_22_1.enemy_info.round)

			if arg_21_2 then
				arg_21_2(arg_22_0, arg_22_1)
			end
		end
	end)
end

function var_0_0.setTempEnemiesInfo(arg_23_0, arg_23_1, arg_23_2)
	arg_23_0.tempEnemiesInfo = arg_23_1 or {}
	arg_23_0.currentRound = arg_23_2 or 1
end

function var_0_0.getTempEnemiesInfo(arg_24_0)
	return arg_24_0.tempEnemiesInfo or {}, arg_24_0.currentRound or 1
end

function var_0_0.fightMonster(arg_25_0, arg_25_1, arg_25_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_FIGHT_MONSTER, arg_25_1, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			if arg_25_2 then
				arg_25_0:updateHeroStatus(arg_25_1.heroes_status)

				arg_25_0.baseInfo = arg_26_1.base_info
				arg_25_0.dropsInfo = arg_26_1.drops_info

				if arg_25_1.is_win == 1 then
					if arg_25_0.mapInfo[arg_25_1.grid_pos] == 2 then
						arg_25_0.maxFloorInfo[tostring(arg_25_0.baseInfo.hero_id)] = arg_25_0.baseInfo.now_floor
					end

					arg_25_0.mapInfo[arg_25_1.grid_pos] = 0
					arg_25_0.mazeFog[arg_25_1.grid_pos] = 1
				end

				arg_25_2(arg_26_0, arg_26_1)
			end
		else
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.getLocalParams(arg_27_0)
	return {
		base_info = arg_27_0.baseInfo,
		drops_info = arg_27_0.dropsInfo,
		maze_info = {
			enemy_grids_info = arg_27_0.enemyInfos,
			map_open = arg_27_0.mazeFog,
			maze_map = arg_27_0.mapInfo
		}
	}
end

function var_0_0.getPlayerInfo(arg_28_0, arg_28_1, arg_28_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_GET_ENEMY_INFO, arg_28_1, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			if arg_28_2 then
				arg_28_2(arg_29_0, arg_29_1)
			end
		else
			arg_28_2(arg_29_0, arg_29_1)
		end
	end)
end

function var_0_0.fightPlayer(arg_30_0, arg_30_1, arg_30_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_FIGHT_PLAYER, arg_30_1, function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			arg_30_0:updateHeroStatus(arg_31_1.battle_info.health_status.team_A)

			arg_30_0.baseInfo = arg_31_1.base_info
			arg_30_0.dropsInfo = arg_31_1.drops_info

			if arg_31_1.battle_info.star > 0 then
				arg_30_0.mapInfo[arg_30_1.grid_pos] = 0
				arg_30_0.mazeFog[arg_30_1.grid_pos] = 1
			end

			if arg_30_2 then
				arg_30_2(arg_31_0, arg_31_1)
			end
		end
	end)
end

function var_0_0.startFight(arg_32_0, arg_32_1, arg_32_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_START_FIGHT, arg_32_1, function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK and arg_32_2 then
			arg_32_2(arg_33_0, arg_33_1)
		end
	end)
end

function var_0_0.getBattleGrid(arg_34_0)
	return arg_34_0.battleGrid or 0
end

function var_0_0.setBattleGrid(arg_35_0, arg_35_1)
	arg_35_0.battleGrid = arg_35_1
end

function var_0_0.abandonGame(arg_36_0, arg_36_1, arg_36_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_ABANDON_GAME, arg_36_1, function(arg_37_0, arg_37_1)
		if arg_37_0 == xyd.error.OK then
			arg_36_0.baseInfo = arg_37_1.base_info
			arg_36_0.dropsInfo = arg_37_1.drops_info
			arg_36_0.mazeFog = {}
			arg_36_0.mapInfo = {}
			arg_36_0.enemyInfos = {}
			arg_36_0.heroStatus = {
				self_list = {},
				rent_list = {}
			}

			if arg_36_2 then
				arg_36_2(arg_37_0, arg_37_1)
			end
		end
	end)
end

function var_0_0.getFinalAward(arg_38_0, arg_38_1, arg_38_2)
	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_GET_FINAL_AWARD, arg_38_1, function(arg_39_0, arg_39_1)
		if arg_39_0 == xyd.error.OK then
			local var_39_0 = tostring(arg_38_0.baseInfo.hero_id)

			arg_38_0.baseInfo = arg_39_1.base_info
			arg_38_0.dropsInfo = arg_39_1.drops_info
			arg_38_0.mazeFog = {}
			arg_38_0.mapInfo = {}
			arg_38_0.enemyInfos = {}
			arg_38_0.heroStatus = {
				self_list = {},
				rent_list = {}
			}
			arg_38_0.maxFloorInfo[var_39_0] = var_0_2

			if arg_38_2 then
				arg_38_2(arg_39_0, arg_39_1)
			end
		end
	end)
end

function var_0_0.updateMapInfo(arg_40_0, arg_40_1)
	local function var_40_0(arg_41_0, arg_41_1)
		local var_41_0 = {}

		for iter_41_0 = 1, #arg_41_0 do
			if arg_41_0[iter_41_0] ~= arg_41_1[iter_41_0] then
				table.insert(var_41_0, iter_41_0)
			end
		end

		return var_41_0
	end

	local var_40_1 = arg_40_1.pos
	local var_40_2 = var_40_0(arg_40_1.map, arg_40_0.mazeFog)

	xyd.Backend.get():request(xyd.mid.MEMORIES_OF_SCHOOL_SAVE_MAP, {
		open_grids = var_40_2,
		now_pos = var_40_1
	}, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			for iter_42_0 = 1, #var_40_2 do
				arg_40_0.mazeFog[var_40_2[iter_42_0]] = 1
			end

			if callback then
				callback(arg_42_0, arg_42_1)
			end
		end
	end)
end

function var_0_0.getMapInfos(arg_43_0)
	return arg_43_0.mapInfo, arg_43_0.mazeFog
end

return var_0_0
