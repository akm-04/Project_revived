local var_0_0 = class("RegionCasualArena", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentBattleRound_ = 0
	arg_1_0.totalRound = 0
	arg_1_0.needMatchTime = 0
	arg_1_0.battleReport_ = {}
	arg_1_0.reportInvalid_ = {}
	arg_1_0.hasNext = false
	arg_1_0.isSelfChallenger = false
	arg_1_0.isMatching = false
	arg_1_0.lastMatchTime = 0
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.onGetRegionCasualArenaInfo_(arg_3_0, arg_3_1)
	return
end

function var_0_0.setBattleParams(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = arg_4_1
	local var_4_1 = var_4_0.battle_report
	local var_4_2 = {
		enemyHeros = {},
		selfHeros = {},
		battleReport = var_4_0.report[1].content
	}
	local var_4_3 = xyd.split(var_4_0.record_info["team_" .. arg_4_2], "|")
	local var_4_4 = xyd.splitToNumber(var_4_0.record_info["pet_id_" .. arg_4_2], "|")
	local var_4_5 = {}
	local var_4_6 = {}
	local var_4_7
	local var_4_8

	for iter_4_0 = 1, #xyd.splitToNumber(var_4_3[1], ":") do
		local var_4_9 = var_0_2.new()
		local var_4_10 = var_4_0.A_partners_info[tostring(xyd.splitToNumber(var_4_3[1], ":")[iter_4_0])]

		var_4_9:initUnCollected(var_4_10.table_id, nil, {
			star = var_4_10.star,
			color = var_4_10.color
		})
		var_4_9:setSkinInfo(tonumber(var_4_10.current_skin_id), var_4_10.skin_ids)
		table.insert(var_4_5, var_4_9)
	end

	if tonumber(var_4_4[1]) ~= 0 then
		local var_4_11 = var_0_3.new()
		local var_4_12 = var_4_0.A_pet_info[tostring(var_4_4[1])]

		var_4_11:initUnCollected(var_4_12.table_id, nil, {
			color = var_4_12.color,
			star = var_4_12.star
		})
		xyd.formatRegionArenaPetsAwake({
			var_4_11
		})

		var_4_7 = var_4_11
	end

	for iter_4_1 = 1, #xyd.splitToNumber(var_4_3[2], ":") do
		local var_4_13 = var_0_2.new()
		local var_4_14 = var_4_0.B_partners_info[tostring(xyd.splitToNumber(var_4_3[2], ":")[iter_4_1])]

		var_4_13:initUnCollected(var_4_14.table_id, nil, {
			star = var_4_14.star,
			color = var_4_14.color
		})
		var_4_13:setSkinInfo(tonumber(var_4_14.current_skin_id), var_4_14.skin_ids)
		table.insert(var_4_6, var_4_13)
	end

	if tonumber(var_4_4[2]) ~= 0 then
		local var_4_15 = var_0_3.new()
		local var_4_16 = var_4_0.B_pet_info[tostring(var_4_4[2])]

		var_4_15:initUnCollected(var_4_16.table_id, nil, {
			color = var_4_16.color,
			star = var_4_16.star
		})
		xyd.formatRegionArenaPetsAwake({
			var_4_15
		})

		var_4_8 = var_4_15
	end

	if arg_4_0.selfPlayer.playerID == var_4_0.record_info.A_player_id then
		var_4_2.enemyID = var_4_0.record_info.B_player_id
		var_4_2.enemyName = var_4_0.B_player_info.player_name
		var_4_2.enemyServerName = var_4_0.B_player_info.region_name
		var_4_2.enemyGuildName = var_4_0.B_player_info.guild_name or ""
		var_4_2.enemyRegion = var_4_0.B_player_info.region
		var_4_2.selfPlayerID = var_4_0.record_info.A_player_id
		var_4_2.selfPlayerName = arg_4_0.selfPlayer.playerName
		var_4_2.selfGuildName = var_4_0.A_player_info.guild_name
		var_4_2.selfRegion = var_4_0.A_player_info.region
		var_4_2.selfRegionName = var_4_0.A_player_info.region_name
		var_4_2.selfHeros = var_4_5
		var_4_2.enemyHeros = var_4_6
		var_4_2.selfPet = var_4_7
		var_4_2.enemyPet = var_4_8
	else
		var_4_2.enemyID = var_4_0.record_info.A_player_id
		var_4_2.enemyName = var_4_0.A_player_info.player_name
		var_4_2.enemyServerName = var_4_0.A_player_info.region_name
		var_4_2.enemyGuildName = var_4_0.A_player_info.guild_name or ""
		var_4_2.enemyRegion = var_4_0.A_player_info.region
		var_4_2.selfPlayerID = var_4_0.record_info.B_player_id
		var_4_2.selfPlayerName = arg_4_0.selfPlayer.playerName
		var_4_2.selfGuildName = var_4_0.B_player_info.guild_name
		var_4_2.selfRegion = var_4_0.B_player_info.region
		var_4_2.selfRegionName = var_4_0.B_player_info.region_name
		var_4_2.selfHeros = var_4_6
		var_4_2.enemyHeros = var_4_5
		var_4_2.selfPet = var_4_8
		var_4_2.enemyPet = var_4_7
	end

	xyd.formatRegionArenaHerosAwake(var_4_2.selfHeros)
	xyd.formatRegionArenaHerosAwake(var_4_2.enemyHeros)

	var_4_2.delay = 1
	var_4_2.isBackendBattle = 1
	var_4_2.oldStar = 45
	var_4_2.is_casual = true

	return var_4_2
end

function var_0_0.getRegionCasualArenaInfo(arg_5_0, arg_5_1)
	xyd.Backend.get():request(xyd.mid.REGION_CASUAL_GET_INFO, {}, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.casualInfo = arg_6_1
			arg_5_0.lastMatchTime = arg_6_1.match_time

			if arg_5_1 then
				arg_5_1(arg_6_0, arg_6_1)
			end
		end
	end)
end

function var_0_0.getReports(arg_7_0, arg_7_1, arg_7_2)
	xyd.Backend.get():request(xyd.mid.REGION_CASUAL_GET_RECORD_REPORT, arg_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_2(arg_8_0, arg_8_1)
		end
	end)
end

function var_0_0.getRecordList(arg_9_0, arg_9_1)
	xyd.Backend.get():request(xyd.mid.REGION_CASUAL_GET_RECORD_LIST, {}, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK and arg_9_1 then
			arg_9_1(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.matchPlayer(arg_11_0, arg_11_1)
	xyd.Backend.get():request(xyd.mid.REGION_CASUAL_MATCH_ENEMY, {}, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.isMatching = true
			arg_11_0.needMatchTime = arg_12_1.need_match_time
			arg_11_0.lastMatchTime = xyd.ServerTime.get():getServerTime()

			if arg_11_1 then
				arg_11_1(arg_12_0, arg_12_1)
			end
		end
	end)
end

function var_0_0.cancelMatch(arg_13_0, arg_13_1)
	xyd.Backend.get():request(xyd.mid.REGION_CASUAL_CANCEL_MATCH, {}, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			arg_13_0.isMatching = false

			if arg_13_1 then
				arg_13_1(arg_14_0, arg_14_1)
			end
		end
	end)
end

function var_0_0.startBattle(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	arg_15_0.currentBattleRound_ = 1
	arg_15_0.stage = arg_15_1
	arg_15_0.record_id = arg_15_2
	arg_15_0.isSelfChallenger = false

	arg_15_0:getBattleReportFromBack(arg_15_3)

	arg_15_0.isMatching = false
end

function var_0_0.getBattleReportFromBack(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0 = {}

	if not arg_16_2 then
		var_16_0 = {
			stage = arg_16_0.stage,
			record_id = arg_16_0.record_id,
			index = arg_16_0.currentBattleRound_
		}
	else
		var_16_0 = {
			stage = arg_16_2,
			record_id = arg_16_0.record_id,
			index = arg_16_0.currentBattleRound_
		}
	end

	xyd.Backend.get():request(xyd.mid.REGION_CASUAL_GET_FIGHT_REPORT, var_16_0, function(arg_17_0, arg_17_1)
		if arg_17_0 == xyd.error.OK and arg_16_1 then
			if not arg_16_2 then
				arg_16_0.totalRound = tonumber(arg_17_1.record_info.battle_count)
			end

			if arg_16_0.selfPlayer.playerID == arg_17_1.record_info.A_player_id then
				arg_16_0.isSelfChallenger = true
			else
				arg_16_0.isSelfChallenger = false
			end

			arg_16_1(arg_17_1)
		end
	end)
end

function var_0_0.setCurrentBattleRound(arg_18_0, arg_18_1)
	arg_18_0.currentBattleRound_ = arg_18_1
end

function var_0_0.getCurrentBattleRound(arg_19_0)
	return arg_19_0.currentBattleRound_
end

function var_0_0.setBattleResult(arg_20_0, arg_20_1)
	if arg_20_1 >= arg_20_0.totalRound then
		arg_20_0.hasNext = false

		return false
	else
		arg_20_0.hasNext = true

		return true
	end
end

function var_0_0.clear(arg_21_0)
	arg_21_0.currentBattleRound_ = 0
	arg_21_0.hasNext = false
	arg_21_0.totalRound = 0
end

function var_0_0.getBattleResult(arg_22_0)
	return arg_22_0.hasNext
end

function var_0_0.setBattleReport(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	arg_23_0.battleReport_[arg_23_1] = arg_23_2
	arg_23_0.reportInvalid_[arg_23_1] = arg_23_3 or 0
end

function var_0_0.getBattleReport(arg_24_0, arg_24_1)
	if arg_24_1 then
		return arg_24_0.battleReport_[arg_24_1]
	else
		return arg_24_0.battleReport_
	end
end

return var_0_0
