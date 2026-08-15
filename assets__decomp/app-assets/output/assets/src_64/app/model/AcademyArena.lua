local var_0_0 = class("AcademyArena", import(".BaseModel"))
local var_0_1 = xyd.tables.academyArenaMap
local var_0_2 = xyd.tables.academyArenaResource
local var_0_3 = {
	cc.c3b(255, 100, 235),
	cc.c3b(255, 255, 0),
	cc.c3b(0, 255, 0),
	cc.c3b(0, 255, 255),
	cc.c3b(255, 150, 0)
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.selfArea = {}
end

function var_0_0.getInfo(arg_2_0, arg_2_1)
	xyd.Backend.get():request(xyd.mid.ACADEMY_GET_INFO, nil, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0.stage = arg_3_1.god_war_info.stage
			arg_2_0.hasSignup = arg_3_1.player_info.is_signed
			arg_2_0.battleMapInfo = arg_3_1.battle_map_info

			if arg_2_0.battleMapInfo then
				arg_2_0.playerInfo = arg_2_0.battleMapInfo.player_info
				arg_2_0.baseMapId = arg_2_0.playerInfo.base_map_id
				arg_2_0.phase = arg_2_0.battleMapInfo.base_info.phase
				arg_2_0.round = arg_2_0.battleMapInfo.base_info.round
				arg_2_0.areaInfo = arg_2_0.battleMapInfo.map_info

				arg_2_0:dfs(arg_2_0.baseMapId)
				arg_2_0:initOccupy()
				arg_2_0:initScore()

				arg_2_0.commandList = arg_2_0.battleMapInfo.cmd_list
				arg_2_0.visitedList = arg_2_0.battleMapInfo.visited_place
				arg_2_0.enermyInfo = arg_2_0.battleMapInfo.player_infos

				table.insert(arg_2_0.visitedList, arg_2_0.baseMapId)
				arg_2_0:getRecruitList(arg_2_1)
			elseif arg_2_1 then
				arg_2_1()
			end
		end
	end)
end

function var_0_0.isOwned(arg_4_0, arg_4_1)
	return arg_4_0.areaInfo[tostring(arg_4_1)].owner == arg_4_0.selfPlayer.playerID
end

function var_0_0.getColor(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.areaInfo[tostring(arg_5_1)].owner
	local var_5_1 = arg_5_0.enermyInfo[tostring(var_5_0)]

	if not var_5_1 then
		return
	end

	return arg_5_0:getColor2(var_5_1.base_map_id)
end

function var_0_0.getColor2(arg_6_0, arg_6_1)
	return var_0_3[var_0_1:type(arg_6_1) - 11]
end

function var_0_0.dfs(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.areaInfo[tostring(arg_7_1)]

	if var_7_0.owner ~= arg_7_0.selfPlayer.playerID or var_7_0.hasV then
		return
	end

	var_7_0.hasV = true

	local var_7_1 = var_0_1:adj(arg_7_1)

	for iter_7_0, iter_7_1 in ipairs(var_7_1) do
		arg_7_0:dfs(iter_7_1)
	end
end

function var_0_0.initScore(arg_8_0)
	arg_8_0.score = {}
	arg_8_0.buffCount = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.areaInfo) do
		local var_8_0 = iter_8_1.owner

		if arg_8_0.score[var_8_0] then
			arg_8_0.score[var_8_0] = arg_8_0.score[var_8_0] + 1
		else
			arg_8_0.score[var_8_0] = 1
		end

		if var_8_0 == arg_8_0.selfPlayer.playerID and var_0_1:buff(tonumber(iter_8_0)) > 0 then
			arg_8_0.buffCount = arg_8_0.buffCount + 1
		end
	end
end

function var_0_0.initOccupy(arg_9_0)
	arg_9_0.occupy = {}

	for iter_9_0 = 1, 11 do
		arg_9_0.occupy[iter_9_0] = true
	end

	for iter_9_1 = 12, 16 do
		arg_9_0.occupy[iter_9_1] = false
	end

	for iter_9_2, iter_9_3 in pairs(arg_9_0.areaInfo) do
		if iter_9_3.owner ~= arg_9_0.selfPlayer.playerID then
			arg_9_0.occupy[var_0_1:type(tonumber(iter_9_2))] = false
		end
	end
end

function var_0_0.getResourceInc(arg_10_0, arg_10_1)
	local var_10_0 = 0
	local var_10_1 = 0

	for iter_10_0, iter_10_1 in pairs(arg_10_0.areaInfo) do
		if iter_10_1.owner == arg_10_0.selfPlayer.playerID and iter_10_1.start_production > 0 then
			local var_10_2 = arg_10_0.occupy[var_0_1:type(tonumber(iter_10_0))] and 2 or 1

			var_10_0 = var_10_0 + var_0_2:actionPoint(iter_10_1.land_id) * var_10_2
			var_10_1 = var_10_1 + var_0_2:summonPoint(iter_10_1.land_id) * var_10_2
		end
	end

	return var_10_0, var_10_1
end

function var_0_0.signup(arg_11_0, arg_11_1)
	xyd.Backend.get():request(xyd.mid.ACADEMY_SIGN_UP, nil, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.hasSignup = 1

			if arg_11_1 then
				arg_11_1()
			end
		end
	end)
end

function var_0_0.getRecruitList(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.ACADEMY_RECRUIT_LIST, nil, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_0.recruitHeros = arg_14_1.recruit_partners

			if arg_13_1 then
				arg_13_1()
			end
		end
	end)
end

function var_0_0.recruit(arg_15_0, arg_15_1, arg_15_2)
	xyd.Backend.get():request(xyd.mid.ACADEMY_RECRUIT, {
		table_id = arg_15_1
	}, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0.playerInfo = arg_16_1.player_info
			arg_15_0.recruitHeros[tostring(arg_15_1)] = {
				total_hp = 0,
				hp = 0,
				health = 0
			}

			if arg_15_2 then
				arg_15_2()
			end
		end
	end)
end

function var_0_0.loadTeam(arg_17_0, arg_17_1, arg_17_2)
	xyd.Backend.get():request(xyd.mid.ACADEMY_TEAM_LIST, {
		map_id = arg_17_1
	}, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK and arg_17_2 then
			arg_17_2(arg_18_1.teams_info)
		end
	end)
end

function var_0_0.getAllTeam(arg_19_0, arg_19_1)
	xyd.Backend.get():request(xyd.mid.ACADEMY_TEAM_LIST, {}, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0.teamInfo = arg_20_1.teams_info

			arg_19_0:initHeroInTeam(arg_19_0.teamInfo)

			if arg_19_1 then
				arg_19_1()
			end
		end
	end)
end

function var_0_0.removeHero(arg_21_0, arg_21_1, arg_21_2)
	for iter_21_0, iter_21_1 in ipairs(arg_21_0.teamInfo) do
		if iter_21_1.team_id == arg_21_2 then
			for iter_21_2, iter_21_3 in ipairs(iter_21_1.table_ids) do
				if iter_21_3 == arg_21_1 then
					table.remove(iter_21_1.table_ids, iter_21_2)

					break
				end
			end

			arg_21_0:calcuCe(iter_21_1)

			break
		end
	end
end

function var_0_0.calcuCe(arg_22_0, arg_22_1)
	local var_22_0 = 0

	for iter_22_0, iter_22_1 in ipairs(arg_22_1.table_ids) do
		var_22_0 = var_22_0 + arg_22_0:newAcademyHero(iter_22_1):getZhandouli()
	end

	arg_22_1.total_force = var_22_0
end

function var_0_0.newAcademyHero(arg_23_0, arg_23_1)
	local var_23_0 = import("app.model.Hero").new()

	var_23_0:initUnCollected(arg_23_1)

	local var_23_1 = arg_23_0.selfPlayer:getHeroIgnoreAwaken(arg_23_1)

	if var_23_1 then
		var_23_0.star_ = var_23_1.star_
		var_23_0.awakeTwiceStage_ = var_23_1.awakeTwiceStage_
	end

	xyd.formatAcademyArenaHero(var_23_0)

	return var_23_0
end

function var_0_0.adjustTeam(arg_24_0, arg_24_1, arg_24_2, arg_24_3, arg_24_4)
	for iter_24_0, iter_24_1 in ipairs(arg_24_2) do
		local var_24_0 = arg_24_0.recruitHeros[tostring(iter_24_1)]

		if var_24_0.teamId and var_24_0.teamId ~= arg_24_1 then
			arg_24_0:removeHero(iter_24_1, var_24_0.teamId)
		end
	end

	if arg_24_1 ~= -1 then
		for iter_24_2, iter_24_3 in ipairs(arg_24_0.teamInfo) do
			if iter_24_3.team_id == arg_24_1 then
				iter_24_3.table_ids = arg_24_2
				iter_24_3.total_force = arg_24_3

				break
			end
		end
	else
		local var_24_1 = {
			is_new = 1,
			team_id = 0,
			total_force = arg_24_3,
			table_ids = arg_24_2
		}

		table.insert(arg_24_0.teamInfo, var_24_1)
	end

	local var_24_2 = {}

	for iter_24_4, iter_24_5 in pairs(arg_24_0.teamInfo) do
		if not iter_24_5.map_id or iter_24_5.map_id == arg_24_0.baseMapId then
			table.insert(var_24_2, iter_24_5)
		end
	end

	local var_24_3 = {
		teams = var_24_2,
		map_id = arg_24_0.baseMapId
	}

	xyd.Backend.get():request(xyd.mid.ACADEMY_SAVE_TEAM, var_24_3, function(arg_25_0, arg_25_1)
		if arg_25_0 == xyd.error.OK then
			arg_24_0.teamInfo = arg_25_1.teams_info

			arg_24_0:initHeroInTeam(arg_24_0.teamInfo)

			if arg_24_4 then
				arg_24_4()
			end
		end
	end)
end

function var_0_0.initHeroInTeam(arg_26_0, arg_26_1)
	for iter_26_0, iter_26_1 in pairs(arg_26_0.recruitHeros) do
		iter_26_1.act = nil
		iter_26_1.teamId = nil
	end

	for iter_26_2, iter_26_3 in ipairs(arg_26_1) do
		for iter_26_4, iter_26_5 in ipairs(iter_26_3.table_ids) do
			if iter_26_3.map_id ~= arg_26_0.baseMapId or arg_26_0:getCommandInfo(iter_26_3.team_id) then
				arg_26_0.recruitHeros[tostring(iter_26_5)].act = true
			else
				arg_26_0.recruitHeros[tostring(iter_26_5)].teamId = iter_26_3.team_id
			end
		end
	end
end

function var_0_0.getCommandInfo(arg_27_0, arg_27_1)
	for iter_27_0, iter_27_1 in ipairs(arg_27_0.commandList) do
		for iter_27_2, iter_27_3 in ipairs(iter_27_1.teams) do
			if arg_27_1 == iter_27_3 then
				return iter_27_1.to_id
			end
		end
	end
end

function var_0_0.move(arg_28_0, arg_28_1, arg_28_2, arg_28_3, arg_28_4)
	local var_28_0 = {
		from_id = arg_28_1,
		to_id = arg_28_2,
		teams = arg_28_3
	}

	for iter_28_0, iter_28_1 in ipairs(arg_28_0.commandList) do
		if iter_28_1.from_id == arg_28_1 and iter_28_1.to_id == arg_28_2 then
			for iter_28_2, iter_28_3 in ipairs(iter_28_1.teams) do
				table.insert(var_28_0.teams, iter_28_3)
			end
		end
	end

	xyd.Backend.get():request(xyd.mid.ACADEMY_MOVE_COMMAND, {
		cmds = {
			var_28_0
		}
	}, function(arg_29_0, arg_29_1)
		if arg_29_0 == xyd.error.OK then
			arg_28_0.commandList = arg_29_1.cmd_list
			arg_28_0.playerInfo = arg_29_1.player_info

			if arg_28_4 then
				arg_28_4()
			end
		end
	end)
end

function var_0_0.cancelTeam(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = {}

	for iter_30_0, iter_30_1 in ipairs(arg_30_0.commandList) do
		local var_30_1 = false

		for iter_30_2 = #arg_30_1, 1, -1 do
			for iter_30_3, iter_30_4 in ipairs(iter_30_1.teams) do
				if arg_30_1[iter_30_2] == iter_30_4 then
					table.remove(iter_30_1.teams, iter_30_3)
					table.remove(arg_30_1, iter_30_2)

					var_30_1 = true

					break
				end
			end
		end

		if var_30_1 then
			table.insert(var_30_0, {
				from_id = iter_30_1.from_id,
				to_id = iter_30_1.to_id,
				teams = iter_30_1.teams
			})
		end
	end

	xyd.Backend.get():request(xyd.mid.ACADEMY_MOVE_COMMAND, {
		cmds = var_30_0
	}, function(arg_31_0, arg_31_1)
		if arg_31_0 == xyd.error.OK then
			arg_30_0.commandList = arg_31_1.cmd_list
			arg_30_0.playerInfo = arg_31_1.player_info

			if arg_30_2 then
				arg_30_2()
			end
		end
	end)
end

function var_0_0.getRecordList(arg_32_0, arg_32_1)
	xyd.Backend.get():request(xyd.mid.ACADEMY_RECORD_LIST, nil, function(arg_33_0, arg_33_1)
		if arg_33_0 == xyd.error.OK then
			arg_32_0.recordPlayer = arg_33_1.player_infos
			arg_32_0.recordList = arg_33_1.record_list

			if arg_32_1 then
				arg_32_1()
			end
		end
	end)
end

function var_0_0.getRecordPlayer(arg_34_0, arg_34_1)
	return arg_34_0.recordPlayer[tostring(arg_34_1)]
end

function var_0_0.getRecordDetail(arg_35_0, arg_35_1, arg_35_2)
	xyd.Backend.get():request(xyd.mid.ACADEMY_RECORD_DETAIL, {
		record_id = arg_35_1
	}, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK and arg_35_2 then
			arg_35_2(arg_36_1)
		end
	end)
end

function var_0_0.getRecord(arg_37_0, arg_37_1, arg_37_2, arg_37_3)
	xyd.Backend.get():request(xyd.mid.ACADEMY_RECORD, {
		record_id = arg_37_1,
		sub_record_id = arg_37_2
	}, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK and arg_37_3 then
			arg_37_3(arg_38_1)
		end
	end)
end

return var_0_0
