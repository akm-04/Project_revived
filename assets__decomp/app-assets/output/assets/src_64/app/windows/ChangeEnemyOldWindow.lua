local var_0_0 = class("ChangeEnemyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 3
local var_0_2 = 66
local var_0_3 = -66
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Pet")
local var_0_6 = import("framework.scheduler")
local var_0_7 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA_OLD)

	if arg_1_2 and arg_1_2.matches then
		arg_1_0.matches = arg_1_2.matches
	else
		arg_1_0.matches = arg_1_0.peakArena:getMatches()
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:updateEnemiesInfos()

	for iter_4_0 = 1, 3 do
		arg_4_0:nodeByName("challenge_btn_" .. iter_4_0):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				local var_5_0 = arg_4_0.matches[iter_4_0]
				local var_5_1 = {}

				table.insert(var_5_1, var_5_0.team1)
				table.insert(var_5_1, var_5_0.team2)
				table.insert(var_5_1, var_5_0.team3)

				local var_5_2 = {
					{},
					{},
					{}
				}

				table.insert(var_5_2[1], var_5_0.pet1)
				table.insert(var_5_2[2], var_5_0.pet2)
				table.insert(var_5_2[3], var_5_0.pet3)

				local var_5_3 = {
					type = xyd.SelectTeamType.PEAK_ARENA,
					campaignType = xyd.CampaignType.SUPER_ARENA,
					enemyTeams = arg_4_0.peakArena:formatTeamHeros(var_5_1, var_5_0.player_id, false, var_5_0.conquer_lev),
					enemyPets = arg_4_0.peakArena:formatTeamHeros(var_5_2, var_5_0.player_id, true),
					withRobot = var_5_0.is_robot,
					matchedEnemy = var_5_0,
					enemyID = var_5_0.player_id,
					enemyName = var_5_0.player_name,
					enemyLev = var_5_0.level,
					enemyConquerLev = var_5_0.conquer_lev,
					enemyConquerLoopID = var_5_0.conquer_loop_id,
					enemyAvatar = var_5_0.avatar_id,
					enemyAvatarFrame = var_5_0.avatar_frame_id
				}

				xyd.WindowManager.get():openWindow("select_team_peak_old", var_5_3)
			end
		end)
	end

	arg_4_0:nodeByName("change_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.peakArena:refreshEnemies(function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK and arg_4_0 and not tolua.isnull(arg_4_0) then
					arg_4_0.matches = arg_7_1

					arg_4_0:updateEnemiesInfos()
				end
			end)
		end
	end)
end

function var_0_0.updateEnemiesInfos(arg_8_0)
	for iter_8_0, iter_8_1 in ipairs(arg_8_0.matches) do
		arg_8_0:nodeByName("head_frame_" .. iter_8_0):removeAllChildren()
		arg_8_0:nodeByName("point_txt_" .. iter_8_0):setString(var_0_7:translation("JIFEN_TIP") .. var_0_7:translation("COLON"))
		arg_8_0:nodeByName("win_times_txt_" .. iter_8_0):setString(var_0_7:translation("WIN_TIMES"))
		arg_8_0:nodeByName("level_" .. iter_8_0):setString(iter_8_1.level)
		arg_8_0:nodeByName("name_" .. iter_8_0):setString(iter_8_1.player_name)
		arg_8_0:nodeByName("point_" .. iter_8_0):setString(iter_8_1.score)
		arg_8_0:nodeByName("win_times_" .. iter_8_0):setString(iter_8_1.wins)

		local var_8_0 = arg_8_0:nodeByName("head_frame_" .. iter_8_0):getWidth() / 2
		local var_8_1 = arg_8_0:nodeByName("change_bundle_hero_" .. iter_8_0)
		local var_8_2 = arg_8_0:nodeByName("head_frame_" .. iter_8_0)
		local var_8_3 = var_8_1:getLocalZOrder() + 1 + 1

		var_8_2:setLocalZOrder(var_8_3)

		if iter_8_1.conquer_lev and iter_8_1.conquer_lev > 0 then
			xyd.setConquerLev(iter_8_1.conquer_lev, arg_8_0:nodeByName("level_" .. iter_8_0), arg_8_0:nodeByName("level_bg_" .. iter_8_0), nil, false, nil, "conquer_lev_bg" .. iter_8_0)
		else
			local var_8_4 = arg_8_0:nodeByName("level_bg_" .. iter_8_0):getParent():getChildByName("conquer_lev_bg" .. iter_8_0)

			if var_8_4 then
				var_8_4:removeSelf()
			end

			arg_8_0:nodeByName("level_bg_" .. iter_8_0):setVisible(true)
			arg_8_0:nodeByName("level_bg_" .. iter_8_0):setLocalZOrder(var_8_3 + 1)
			arg_8_0:nodeByName("level_" .. iter_8_0):setLocalZOrder(var_8_3 + 2)
		end

		local var_8_5 = display.newNode()

		var_8_5:setContentSize(110, 110)
		var_8_5:setPosition(var_8_0, var_8_0)
		var_8_5:addTo(arg_8_0:nodeByName("head_frame_" .. iter_8_0))
		var_8_5:setName("avatar" .. iter_8_0)
		var_8_5:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setAvatarClip(var_8_5, iter_8_1.avatar_id, 1)

		local var_8_6

		if iter_8_1.avatar_frame_id == nil or iter_8_1.avatar_frame_id == 0 then
			var_8_6 = xyd.AssetLoader.get():loadSprite("images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png")
		else
			var_8_6 = xyd.AssetLoader.get():loadSprite("images/avatar_frames/" .. xyd.tables.avatar.icon_[iter_8_1.avatar_frame_id] .. ".png")
		end

		var_8_6:addTo(arg_8_0:nodeByName("head_frame_" .. iter_8_0))
		var_8_6:setPosition(arg_8_0:nodeByName("head_frame_" .. iter_8_0):getWidth() / 2, arg_8_0:nodeByName("head_frame_" .. iter_8_0):getHeight() / 2)
		var_8_5:setTouchSwallowEnabled(false)
		var_8_5:setTouchEnabled(true)
		var_8_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			arg_8_0:showTeamInfo(arg_9_0, iter_8_1)

			return true
		end)
	end
end

function var_0_0.showTeamInfo(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_1.name == "began" then
		-- block empty
	elseif arg_10_1.name == "ended" then
		local var_10_0 = {}
		local var_10_1 = {}
		local var_10_2 = {}

		for iter_10_0, iter_10_1 in ipairs(arg_10_2.team1) do
			local var_10_3 = var_0_4.new()

			var_10_3:populate(iter_10_1)
			table.insert(var_10_0, var_10_3)
		end

		for iter_10_2, iter_10_3 in ipairs(arg_10_2.team2) do
			local var_10_4 = var_0_4.new()

			var_10_4:populate(iter_10_3)
			table.insert(var_10_1, var_10_4)
		end

		for iter_10_4, iter_10_5 in ipairs(arg_10_2.team3) do
			local var_10_5 = var_0_4.new()

			var_10_5:populate(iter_10_5)
			table.insert(var_10_2, var_10_5)
		end

		arg_10_0.pets1, arg_10_0.pets2, arg_10_0.pets3 = {}, {}, {}

		for iter_10_6 = 1, 3 do
			if arg_10_2["pet" .. iter_10_6] then
				local var_10_6 = var_0_5.new()

				var_10_6:populate(arg_10_2["pet" .. iter_10_6])
				table.insert(arg_10_0["pets" .. iter_10_6], var_10_6)
			end
		end

		local var_10_7 = {
			name = arg_10_2.player_name,
			level = arg_10_2.level,
			avatar_id = arg_10_2.avatar_id,
			avatar_frame_id = arg_10_2.avatar_frame_id,
			win = arg_10_2.wins,
			force = arg_10_2.score,
			team1 = var_10_0,
			team2 = var_10_1,
			team3 = var_10_2,
			pet1 = arg_10_0.pets1,
			pet2 = arg_10_0.pets2,
			pet3 = arg_10_0.pets3,
			guild = arg_10_2.guild_name,
			conquer_lev = arg_10_2.conquer_lev,
			conquer_loop_id = arg_10_2.conquer_loop_id,
			player_id = arg_10_2.player_id,
			rank = arg_10_2.rank
		}

		xyd.WindowManager.get():openWindow("arena_team_info", {
			team = var_10_7,
			arena_type = xyd.CampaignType.SUPER_ARENA
		})
	end
end

return var_0_0
