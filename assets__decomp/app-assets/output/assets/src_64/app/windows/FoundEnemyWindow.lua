local var_0_0 = class("FoundEnemyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.delay = arg_1_2.delay or 1
	arg_1_0.avatar = arg_1_2.avatar
	arg_1_0.avatarFrame = arg_1_2.avatarFrame
	arg_1_0.winTimes = arg_1_2.winTimes
	arg_1_0.totalFight = arg_1_2.totalFight
	arg_1_0.playerName = arg_1_2.playerName
	arg_1_0.serverName = arg_1_2.serverName
	arg_1_0.guildName = arg_1_2.guildName
	arg_1_0.playerID = arg_1_2.playerID
	arg_1_0.heros = arg_1_2.heros
	arg_1_0.enemyPet = arg_1_2.pet_info
	arg_1_0.mode = arg_1_2.mode
	arg_1_0.pet_id = arg_1_2.pet_id
	arg_1_0.selfRegionName = arg_1_2.selfRegionName
	arg_1_0.enemyRegion = arg_1_2.enemyRegion
	arg_1_0.isBackendBattle = 1
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:translation()
	arg_3_0:nodeByName("enemy_name"):setString(arg_3_0.playerName)
	arg_3_0:nodeByName("win_num"):setString(arg_3_0.winTimes)

	if arg_3_0.totalFight > 0 then
		arg_3_0:nodeByName("win_ratio"):setString(tostring(math.floor(arg_3_0.winTimes / arg_3_0.totalFight * 100)) .. "%")
	else
		arg_3_0:nodeByName("win_ratio"):setString("N/A")
	end

	arg_3_0:nodeByName("guild_name"):setString(arg_3_0.guildName)
	arg_3_0:nodeByName("server_name"):setString(arg_3_0.serverName)
	xyd.setPlayerAvatar(arg_3_0:nodeByName("avatar"), {
		avatar_id = arg_3_0.avatar,
		avatar_frame_id = arg_3_0.avatarFrame
	})
	arg_3_0.regionArena:startFight(function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.isBackendBattle = arg_4_1.is_back_battle
		end

		var_0_2.performWithDelayGlobal(function()
			local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
			local var_5_1 = {
				my_id = var_5_0.playerID,
				enemy_id = arg_3_0.playerID
			}

			params = {
				withRobot = false,
				type = xyd.SelectTeamType.REGION_ARENA,
				pet_info = arg_3_0.enemyPet,
				campaignType = xyd.CampaignType.REGION_ARENA,
				fighterInfo = var_5_1,
				enemyHeroes = arg_3_0.heros,
				firstSelect = arg_3_0:getRandomFirstSelect(),
				mode = arg_3_0.mode,
				enemyID = arg_3_0.playerID,
				pet_id = arg_3_0.pet_id,
				isBackendBattle = arg_3_0.isBackendBattle,
				enemyGuildName = arg_3_0.guildName,
				enemyName = arg_3_0.playerName,
				enemyServerName = arg_3_0.serverName,
				enemyAvatarID = arg_3_0.avatar,
				enemyAvaterFrameID = arg_3_0.avatarFrame,
				selfRegionName = arg_3_0.selfRegionName,
				enemyRegion = arg_3_0.enemyRegion
			}

			xyd.WindowManager.get():openWindow("select_team_rearena", params)
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end, arg_3_0.delay)
	end)
end

function var_0_0.translation(arg_6_0)
	local var_6_0 = var_0_1:translation("REGION_ARENA_TIP6")
	local var_6_1 = var_0_1:translation("REGION_ARENA_TIP7")
	local var_6_2 = var_0_1:translation("REGION_ARENA_TIP8")
	local var_6_3 = var_0_1:translation("REGION_ARENA_TIP9")
	local var_6_4 = var_0_1:translation("REGION_ARENA_TIP10")

	arg_6_0:nodeByName("title"):setString(var_6_0)
	arg_6_0:nodeByName("win_num_txt"):setString(var_6_1)
	arg_6_0:nodeByName("win_ratio_txt"):setString(var_6_2)
	arg_6_0:nodeByName("from_txt"):setString(var_6_3)
	arg_6_0:nodeByName("server_txt"):setString(var_6_4)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
end

function var_0_0.getRandomFirstSelect(arg_8_0)
	if math.random() < 0.5 then
		return 0
	else
		return 1
	end
end

return var_0_0
