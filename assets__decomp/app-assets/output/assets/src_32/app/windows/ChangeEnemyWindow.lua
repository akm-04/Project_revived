local var_0_0 = class("ChangeEnemyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

	if arg_1_2 and arg_1_2.matches then
		arg_1_0.matches = arg_1_2.matches
	else
		arg_1_0.matches = arg_1_0.peakArena:getMatches()
	end

	arg_1_0.teamInfos = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT7"))
	arg_2_0:nodeByName("txt_change"):setString(var_0_3:translation("TOP_CHANGEENEMYWINDOW_TEXT1"))
	arg_2_0:nodeByName("change_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_3_0, arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			if arg_2_0.peakArena.mode == 2 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("LEGEND_PROMO_TIPS1")
				})

				return
			end

			arg_2_0.peakArena:refreshEnemies(function()
				if arg_2_0 and not tolua.isnull(arg_2_0) then
					arg_2_0.teamInfos = {}
					arg_2_0.matches = arg_2_0.peakArena:getMatches()

					for iter_4_0 = 1, 3 do
						arg_2_0:updateEnemiesInfos(iter_4_0)
					end
				end
			end)
		end
	end)

	if arg_2_0.matches and next(arg_2_0.matches) then
		for iter_2_0 = 1, 3 do
			arg_2_0:initEnemiesInfos(iter_2_0)
			arg_2_0:updateEnemiesInfos(iter_2_0)
		end
	else
		arg_2_0:addNpc()
		arg_2_0:nodeByName("enemy_container"):setVisible(false)
		arg_2_0:nodeByName("top_container"):setVisible(true)
	end
end

function var_0_0.addNpc(arg_5_0)
	local var_5_0 = var_0_4:getValue("arena_hero_id")
	local var_5_1 = var_0_4:getValue("arena_first_hero_model")
	local var_5_2 = var_0_4:getValue("arena_hero_scaling")

	arg_5_0:nodeByName("txt_talk"):setString(var_0_3:translation("ARENA_FIRST_TIPS1"))

	arg_5_0.npc = xyd.HeroAnimation.new(var_5_0, var_5_1, var_5_2, {})

	if arg_5_0.npc then
		arg_5_0.npc:idle()
	end

	arg_5_0.npc:addTo(arg_5_0:nodeByName("top_container"))
	arg_5_0.npc:pos(309, 133)
	arg_5_0.npc:setTouchEnabled(true)
	arg_5_0.npc:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_5_0.npcAction then
			return
		end

		if arg_6_0.name == "ended" then
			arg_5_0.npcAction = true

			arg_5_0.npc:win(false, function()
				arg_5_0.npcAction = false

				arg_5_0.npc:idle()
			end)
		end

		return true
	end)
end

function var_0_0.initEnemiesInfos(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:nodeByName("enemy_container" .. arg_8_1)

	var_8_0:getChildByName("win_times_txt"):setString(var_0_3:translation("LEGEND_WINDOW_SERVERS"))
	var_8_0:getChildByName("challenge_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0:getTeamInfo(arg_8_1, function()
				arg_8_0:challengeEnemy(arg_8_1)
			end)
		end
	end)
end

function var_0_0.updateEnemiesInfos(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_0:nodeByName("enemy_container" .. arg_11_1)
	local var_11_1 = arg_11_0.matches[arg_11_1]

	if not var_11_1 then
		arg_11_0:nodeByName("no_enemy" .. arg_11_1):setVisible(true)
		var_11_0:setVisible(false)

		return
	else
		arg_11_0:nodeByName("no_enemy" .. arg_11_1):setVisible(false)
		var_11_0:setVisible(true)
	end

	local var_11_2 = var_11_1.player_info
	local var_11_3 = var_11_1.rank_info

	var_11_0:getChildByName("head_frame"):removeAllChildren()
	var_11_0:getChildByName("name"):setString(var_11_2.player_name)
	var_11_0:getChildByName("point_txt"):setString(var_0_3:translation(var_11_3.rank_level < 3 and "LEGEND_WINDOW_RANK" or "LEGEND_WINDOW_POINTS"))
	var_11_0:getChildByName("point"):setString(var_11_3.rank_level < 3 and var_11_3.rank or var_11_3.rank_point)
	var_11_0:getChildByName("win_times"):setString("S" .. var_11_2.region)

	local var_11_4 = var_11_0:getChildByName("head_frame")

	local function var_11_5(arg_12_0)
		if arg_12_0.name == "began" then
			return true
		elseif arg_12_0.name == "ended" then
			arg_11_0:getTeamInfo(arg_11_1, function()
				arg_11_0:showTeamInfo(arg_11_1)
			end)
		end
	end

	local var_11_6 = {
		showLevel = true,
		is_new = true,
		avatar_id = var_11_2.avatar_id,
		avatar_frame_id = var_11_2.avatar_frame_id,
		level = var_11_2.lev,
		conquerLev = var_11_2.conquer_lev,
		conquerLoopID = var_11_2.conquer_loop_id,
		callback = var_11_5
	}

	xyd.setPlayerAvatar(var_11_4, var_11_6)
end

function var_0_0.showTeamInfo(arg_14_0, arg_14_1)
	local var_14_0 = arg_14_0.matches[arg_14_1]

	xyd.WindowManager.get():openWindow("peak_team_info", {
		rank = var_14_0.rank_info.rank,
		playerInfo = var_14_0.player_info,
		teams = arg_14_0.peakArena:formatTeams(arg_14_0.teamInfos[arg_14_1])
	})
end

function var_0_0.challengeEnemy(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.matches[arg_15_1]
	local var_15_1 = {
		type = xyd.SelectTeamType.PEAK_ARENA,
		campaignType = xyd.CampaignType.SUPER_ARENA,
		enemyTeams = arg_15_0.peakArena:formatTeams(arg_15_0.teamInfos[arg_15_1], var_15_0.conquer_lev),
		matchedEnemy = var_15_0
	}

	xyd.WindowManager.get():openWindow("select_team_peak", var_15_1)
end

function var_0_0.getTeamInfo(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_0.teamInfos[arg_16_1] then
		arg_16_2()
	else
		local var_16_0 = arg_16_0.matches[arg_16_1].player_info.player_id

		arg_16_0.peakArena:getEnemyTeam(var_16_0, function(arg_17_0)
			arg_16_0.teamInfos[arg_16_1] = arg_17_0

			arg_16_2()
		end)
	end
end

function var_0_0.didOpen(arg_18_0, arg_18_1)
	arg_18_0:addBlockLayer()
end

return var_0_0
