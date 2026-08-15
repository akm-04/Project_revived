local var_0_0 = class("Playoffs", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.battle_status = {}
	arg_1_0.players_info = {}
	arg_1_0.player_info = {}
	arg_1_0.playoff_info = {}
	arg_1_0.support_info = {}
	arg_1_0.group_info = {}
	arg_1_0.match_list = {}
	arg_1_0.currentBattleRound_ = 0
	arg_1_0.totalRound = 0
	arg_1_0.battleReport_ = {}
	arg_1_0.reportInvalid_ = {}
	arg_1_0.hasNext = false
	arg_1_0.isSelfChallenger = false
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.populate(arg_3_0, arg_3_1)
	return
end

function var_0_0.getBasePlayers(arg_4_0, arg_4_1)
	local var_4_0 = {}

	xyd.Backend.get():request(xyd.mid.PLAYOFFS_GET_PLAYOFF_INFO, var_4_0, function(arg_5_0, arg_5_1)
		if arg_5_0 == xyd.error.OK then
			arg_4_0.battle_status = arg_5_1.battle_status
			arg_4_0.players_info = arg_5_1.players_info
			arg_4_0.player_info = arg_5_1.player_info
			arg_4_0.playoff_info = arg_5_1.playoff_info
			arg_4_0.support_info = arg_5_1.support_info

			if arg_4_0.playoff_info.stage >= 2 then
				arg_4_0:initGroupInfo()
			end

			if arg_4_1 then
				arg_4_1(arg_5_0, arg_5_1)
			end
		end
	end)
end

function var_0_0.getRecordList(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = {
		player_id = tonumber(arg_6_1),
		stage = arg_6_2
	}

	xyd.Backend.get():request(xyd.mid.PLAYOFFS_RECORD, var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK and arg_6_3 then
			arg_6_3(arg_7_0, arg_7_1)
		end
	end)
end

function var_0_0.getGroupDetail(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = {
		index = arg_8_1
	}

	xyd.Backend.get():request(xyd.mid.PLAYOFFS_GET_GROUP_DETAILS, var_8_0, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			for iter_9_0, iter_9_1 in pairs(arg_9_1) do
				arg_8_0.players_info[iter_9_0].fans = iter_9_1.fans
				arg_8_0.players_info[iter_9_0].sign_up_times = iter_9_1.sign_up_times
				arg_8_0.players_info[iter_9_0].win_times = iter_9_1.win_times
			end

			if arg_8_2 then
				arg_8_2(arg_9_0, arg_9_1)
			end
		end
	end)
end

function var_0_0.setBattleParams(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1
	local var_10_1 = var_10_0.battle_report
	local var_10_2 = {
		enemyHeros = {},
		selfHeros = {},
		battleReport = var_10_0.report[1].content
	}
	local var_10_3 = xyd.split(var_10_0.record_info["team_" .. arg_10_2], "|")
	local var_10_4 = xyd.splitToNumber(var_10_0.record_info["pet_id_" .. arg_10_2], "|")
	local var_10_5 = {}
	local var_10_6 = {}
	local var_10_7
	local var_10_8

	for iter_10_0 = 1, #xyd.splitToNumber(var_10_3[1], ":") do
		local var_10_9 = var_0_2.new()
		local var_10_10 = var_10_0.A_partners_info[tostring(xyd.splitToNumber(var_10_3[1], ":")[iter_10_0])]

		var_10_9:initUnCollected(var_10_10.table_id, nil, {
			star = var_10_10.star,
			color = var_10_10.color
		})
		var_10_9:setSkinInfo(tonumber(var_10_10.current_skin_id), var_10_10.skin_ids)
		table.insert(var_10_5, var_10_9)
	end

	if tonumber(var_10_4[1]) ~= 0 then
		local var_10_11 = var_0_3.new()
		local var_10_12 = var_10_0.A_pet_info[tostring(var_10_4[1])]

		var_10_11:initUnCollected(var_10_12.table_id, nil, {
			color = var_10_12.color,
			star = var_10_12.star
		})
		xyd.formatRegionArenaPetsAwake({
			var_10_11
		})

		var_10_7 = var_10_11
	end

	for iter_10_1 = 1, #xyd.splitToNumber(var_10_3[2], ":") do
		local var_10_13 = var_0_2.new()
		local var_10_14 = var_10_0.B_partners_info[tostring(xyd.splitToNumber(var_10_3[2], ":")[iter_10_1])]

		var_10_13:initUnCollected(var_10_14.table_id, nil, {
			star = var_10_14.star,
			color = var_10_14.color
		})
		var_10_13:setSkinInfo(tonumber(var_10_14.current_skin_id), var_10_14.skin_ids)
		table.insert(var_10_6, var_10_13)
	end

	if tonumber(var_10_4[2]) ~= 0 then
		local var_10_15 = var_0_3.new()
		local var_10_16 = var_10_0.B_pet_info[tostring(var_10_4[2])]

		var_10_15:initUnCollected(var_10_16.table_id, nil, {
			color = var_10_16.color,
			star = var_10_16.star
		})
		xyd.formatRegionArenaPetsAwake({
			var_10_15
		})

		var_10_8 = var_10_15
	end

	if arg_10_0.selfPlayer.playerID == var_10_0.record_info.A_player_id then
		var_10_2.enemyID = var_10_0.record_info.B_player_id
		var_10_2.enemyName = var_10_0.B_player_info.player_name
		var_10_2.enemyServerName = var_10_0.B_player_info.region_name
		var_10_2.enemyGuildName = var_10_0.B_player_info.guild_name or ""
		var_10_2.enemyRegion = var_10_0.B_player_info.region
		var_10_2.selfPlayerID = var_10_0.record_info.A_player_id
		var_10_2.selfPlayerName = arg_10_0.selfPlayer.playerName
		var_10_2.selfGuildName = var_10_0.A_player_info.guild_name
		var_10_2.selfRegion = var_10_0.A_player_info.region
		var_10_2.selfRegionName = var_10_0.A_player_info.region_name
		var_10_2.selfHeros = var_10_5
		var_10_2.enemyHeros = var_10_6
		var_10_2.selfPet = var_10_7
		var_10_2.enemyPet = var_10_8
	else
		var_10_2.enemyID = var_10_0.record_info.A_player_id
		var_10_2.enemyName = var_10_0.A_player_info.player_name
		var_10_2.enemyServerName = var_10_0.A_player_info.region_name
		var_10_2.enemyGuildName = var_10_0.A_player_info.guild_name or ""
		var_10_2.enemyRegion = var_10_0.A_player_info.region
		var_10_2.selfPlayerID = var_10_0.record_info.B_player_id
		var_10_2.selfPlayerName = arg_10_0.selfPlayer.playerName
		var_10_2.selfGuildName = var_10_0.B_player_info.guild_name
		var_10_2.selfRegion = var_10_0.B_player_info.region
		var_10_2.selfRegionName = var_10_0.B_player_info.region_name
		var_10_2.selfHeros = var_10_6
		var_10_2.enemyHeros = var_10_5
		var_10_2.selfPet = var_10_8
		var_10_2.enemyPet = var_10_7
	end

	xyd.formatRegionArenaHerosAwake(var_10_2.selfHeros)
	xyd.formatRegionArenaHerosAwake(var_10_2.enemyHeros)

	var_10_2.delay = 1
	var_10_2.isBackendBattle = 1
	var_10_2.oldStar = 45

	return var_10_2
end

function var_0_0.initGroupInfo(arg_11_0)
	for iter_11_0 = 1, 8 do
		local var_11_0 = {}

		for iter_11_1 = 1, 4 do
			table.insert(var_11_0, arg_11_0.battle_status["2"][4 * (iter_11_0 - 1) + iter_11_1])
		end

		table.insert(arg_11_0.group_info, var_11_0)
	end
end

function var_0_0.setDeclaration(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_12_1 = arg_12_1.dec

	xyd.Backend.get():request(xyd.mid.PLAYOFFS_SET_DECLARATION, arg_12_1, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK and arg_12_2 then
			arg_12_0.players_info[tostring(var_12_0.playerID)].dec = var_12_1

			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.support(arg_14_0, arg_14_1, arg_14_2)
	xyd.Backend.get():request(xyd.mid.PLAYOFFS_SUPPORT, arg_14_1, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK and arg_14_2 then
			if tonumber(arg_14_0.support_info.support_player) ~= 0 then
				arg_14_0.players_info[tostring(arg_14_0.support_info.support_player)].fans = arg_14_0.players_info[tostring(arg_14_0.support_info.support_player)].fans - 1
			end

			arg_14_0.support_info = arg_15_1
			arg_14_0.players_info[tostring(arg_15_1.support_player)].fans = arg_14_0.players_info[tostring(arg_15_1.support_player)].fans + 1

			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.hasJoin(arg_16_0)
	local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).playerID

	for iter_16_0 = 1, #arg_16_0.battle_status["2"] do
		if var_16_0 == arg_16_0.battle_status["2"][iter_16_0] then
			return true
		end
	end
end

function var_0_0.getMatchList(arg_17_0, arg_17_1)
	local var_17_0 = {}

	xyd.Backend.get():request(xyd.mid.PLAYOFFS_GET_MATCH_LIST, var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			arg_17_0.match_list = arg_18_1

			if arg_17_1 then
				arg_17_1(arg_18_0, arg_18_1)
			end
		end
	end)
end

function var_0_0.matchList(arg_19_0, arg_19_1)
	if arg_19_1 == 0 or not arg_19_1 then
		return arg_19_0.match_list
	else
		local var_19_0 = {
			fight_list = {},
			playoff_info = {}
		}

		for iter_19_0 = 1, #arg_19_0.match_list.fight_list do
			if arg_19_0.match_list.fight_list[iter_19_0].A_player_id == arg_19_1 or arg_19_0.match_list.fight_list[iter_19_0].B_player_id == arg_19_1 then
				table.insert(var_19_0.fight_list, arg_19_0.match_list.fight_list[iter_19_0])
			end
		end

		var_19_0.playoff_info = arg_19_0.match_list.playoff_info

		return var_19_0
	end
end

function var_0_0.getBattleScoresInfo(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = {
		player_id = arg_20_1
	}

	xyd.Backend.get():request(xyd.mid.GET_REARENA_PARTNERS, var_20_0, function(arg_21_0, arg_21_1)
		if arg_21_0 == xyd.error.OK and arg_20_2 then
			arg_20_2(arg_21_0, arg_21_1)
		end
	end)
end

function var_0_0.startBattle(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	arg_22_0.currentBattleRound_ = 1
	arg_22_0.stage = arg_22_1
	arg_22_0.record_id = arg_22_2
	arg_22_0.isSelfChallenger = false

	arg_22_0:getBattleReportFromBack(arg_22_3)
end

function var_0_0.getBattleReportFromBack(arg_23_0, arg_23_1, arg_23_2, arg_23_3, arg_23_4)
	local var_23_0 = {}

	if not arg_23_2 then
		var_23_0 = {
			stage = arg_23_0.stage,
			record_id = arg_23_0.record_id,
			index = arg_23_0.currentBattleRound_
		}
	else
		var_23_0 = {
			stage = arg_23_2,
			record_id = arg_23_3,
			index = arg_23_4
		}
	end

	xyd.Backend.get():request(xyd.mid.PLAYOFFS_BATTLE, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK and arg_23_1 then
			if not arg_23_2 then
				arg_23_0.totalRound = tonumber(arg_24_1.record_info.battle_count)
			end

			if arg_23_0.selfPlayer.playerID == arg_24_1.record_info.A_player_id then
				arg_23_0.isSelfChallenger = true
			else
				arg_23_0.isSelfChallenger = false
			end

			arg_23_1(arg_24_1)
		end
	end)
end

function var_0_0.setCurrentBattleRound(arg_25_0, arg_25_1)
	arg_25_0.currentBattleRound_ = arg_25_1
end

function var_0_0.getCurrentBattleRound(arg_26_0)
	return arg_26_0.currentBattleRound_
end

function var_0_0.setBattleResult(arg_27_0, arg_27_1)
	if arg_27_1 >= arg_27_0.totalRound then
		arg_27_0.hasNext = false

		return false
	else
		arg_27_0.hasNext = true

		return true
	end
end

function var_0_0.clear(arg_28_0)
	arg_28_0.currentBattleRound_ = 0
	arg_28_0.hasNext = false
	arg_28_0.totalRound = 0
end

function var_0_0.getBattleResult(arg_29_0)
	return arg_29_0.hasNext
end

function var_0_0.setBattleReport(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	arg_30_0.battleReport_[arg_30_1] = arg_30_2
	arg_30_0.reportInvalid_[arg_30_1] = arg_30_3 or 0
end

function var_0_0.getBattleReport(arg_31_0, arg_31_1)
	if arg_31_1 then
		return arg_31_0.battleReport_[arg_31_1]
	else
		return arg_31_0.battleReport_
	end
end

return var_0_0
