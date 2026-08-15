local var_0_0 = class("ArenaRecordPlayerInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "arena_record_player_info"
local var_0_2 = import("app.model.Pet")
local var_0_3 = 100000
local var_0_4 = xyd.tables.translation

function var_0_0.close(arg_1_0)
	xyd.WindowManager.get():closeWindow(var_0_1, arg_1_0)
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)

	arg_2_0.arena_ = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.team = arg_2_2.team
	arg_2_0.arenaType_ = arg_2_2.arena_type
	arg_2_0.can_avenge = arg_2_2.team.can_avenge
	arg_2_0.table_id = arg_2_2.team.table_id
	arg_2_0.isRobot = arg_2_2.team.is_robot
	arg_2_0.avenge_type = arg_2_2.team.avenge_type
	arg_2_0.is_attack = arg_2_2.team.is_attack
	arg_2_0.has_win = arg_2_2.team.has_win
	arg_2_0.conquerLev = arg_2_2.team.conquer_lev
	arg_2_0.conquerLoopID = arg_2_2.team.conquer_loop_id
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:container()
	local var_5_1 = var_5_0:getContentSize()
	local var_5_2 = cc.p(var_5_0:getPosition())

	local function var_5_3(arg_6_0, arg_6_1)
		xyd.WindowManager.get():closeWindow(var_0_1, callback)

		return true
	end

	local var_5_4 = cc.EventListenerTouchOneByOne:create()

	var_5_4:setSwallowTouches(true)
	var_5_4:registerScriptHandler(var_5_3, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_5_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_5_4, arg_5_0)

	arg_5_0.playerName = arg_5_0:nodeByName("text_player_name")
	arg_5_0.avatarPanel = arg_5_0:nodeByName("avatar")
	arg_5_0.textLevel = arg_5_0:nodeByName("text_level")
	arg_5_0.heroesContainer = arg_5_0:nodeByName("heroes_container")
	arg_5_0.titleRank = arg_5_0:nodeByName("lbl_rank")

	arg_5_0.titleRank:setString(xyd.tables.translation:translation("RANKING") .. xyd.tables.translation:translation("COLON"))
	arg_5_0:nodeByName("guild_words"):setString(xyd.tables.translation:translation("BELONG_TO_GUILD"))

	local function var_5_5(arg_7_0, arg_7_1, arg_7_2)
		local var_7_0 = {}
		local var_7_1

		if arg_7_0 and next(arg_7_0) then
			for iter_7_0, iter_7_1 in pairs(arg_7_0) do
				local var_7_2 = iter_7_1

				if arg_7_2 == true then
					var_7_2.table_id = iter_7_1.partner_id
					var_7_2.partner_id = iter_7_0
				end

				if type(var_7_2.equips) == "string" then
					var_7_2.equips = xyd.splitToNumber(var_7_2.equips, "|")
				end

				if bookshelfLev and bookshelfLev > 0 then
					var_7_2.book_shelf_lev = bookshelfLev
				else
					var_7_2.book_shelf_lev = 0
				end

				local var_7_3 = import("app.model.Hero").new()

				var_7_3:populate(var_7_2)
				table.insert(var_7_0, var_7_3)
			end
		end

		if arg_7_1 then
			local var_7_4 = arg_7_1

			if type(var_7_4.equips) == "string" then
				var_7_4.equips = xyd.splitToNumber(var_7_4.equips, "|")
			end

			local var_7_5 = import("app.model.Pet").new()

			var_7_5:populate(var_7_4)

			var_7_1 = var_7_5
		end

		return var_7_0, var_7_1
	end

	if arg_5_0.is_attack ~= 1 and arg_5_0.has_win ~= 1 and (arg_5_0.can_avenge and arg_5_0.can_avenge ~= 0 or arg_5_0.avenge_type == 3 or arg_5_0.avenge_type == 4) then
		arg_5_0:nodeByName("revenge_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				if arg_5_0.avenge_type == 3 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ARENA_RECORD_RANK_TOO_LOW")
					})

					return
				end

				if arg_5_0.avenge_type == 4 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_4:translation("ARENA_RECORD_RANK_TOO_HIGH")
					})

					return
				end

				xyd.playButtonSound()

				local var_8_0 = {
					other_player_id = arg_5_0.table_id + arg_5_0.selfPlayer.region * var_0_3
				}

				xyd.Backend.get():request(xyd.mid.query_arena_formation, var_8_0, function(arg_9_0, arg_9_1)
					local var_9_0
					local var_9_1 = arg_9_1.table_id <= 25000 and true or false
					local var_9_2, var_9_3 = var_5_5(arg_9_1.heros, arg_9_1.pet, var_9_1)

					if arg_5_0.arena_.leftTime and arg_5_0.arena_.leftTime <= 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = string.format(var_0_4:translation("TRIAL_LEFT_TIMES"), 0)
						})
					elseif xyd.WindowManager.get():getWindow("arena") and xyd.WindowManager.get():getWindow("arena").countDownOn then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_4:translation("TIME_TOO_EARLY")
						})
					else
						local var_9_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
						local var_9_5 = {
							my_id = var_9_4.playerID,
							enemy_id = arg_5_0.table_id
						}

						var_8_0 = {
							is_avenge = 1,
							showEnemy = true,
							type = xyd.SelectTeamType.ARENA,
							campaignType = xyd.CampaignType.ARENA,
							fighterInfo = var_9_5,
							enemyHeroes = var_9_2,
							withRobot = arg_5_0.isRobot,
							oldBestRank = arg_5_0.arena_:getBestRank(),
							enemyPets = var_9_3
						}

						xyd.Backend.get():request(xyd.mid.ARENA_PRE_FIGHT, {}, function(arg_10_0, arg_10_1)
							if arg_10_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("arena_select_team", var_8_0)
							end
						end)
					end
				end)
			end
		end)
	else
		arg_5_0:nodeByName("revenge_btn"):setVisible(false)
		arg_5_0:nodeByName("chat_btn"):setPositionX(arg_5_0:nodeByName("chat_btn"):getPositionX() + 100)
	end

	arg_5_0:nodeByName("chat_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_11_0 = arg_5_0.table_id + arg_5_0.selfPlayer.region * var_0_3
			local var_11_1 = xyd.WindowManager.get():openWindow("chat")

			if var_11_1 then
				var_11_1:updatePersonLabel(arg_5_0.team.name)

				var_11_1.toPlayerID = var_11_0
			end

			xyd.WindowManager.get():closeWindow(var_0_1, callback)
		end
	end)
	arg_5_0:updateTeamInfo()
end

function var_0_0.updateTeamInfo(arg_12_0)
	xyd.setPlayerAvatar(arg_12_0.avatarPanel, {
		avatar_id = arg_12_0.team.avatar_id,
		avatar_frame_id = arg_12_0.team.avatar_frame_id
	})
	arg_12_0.playerName:setString(arg_12_0.team.name)

	if arg_12_0.conquerLev and arg_12_0.conquerLev > 0 then
		xyd.setConquerLev(arg_12_0.conquerLev, arg_12_0.textLevel, arg_12_0:nodeByName("dengjiquan"), nil, nil, nil, nil, arg_12_0.conquerLoopID)
	else
		arg_12_0.textLevel:setString(arg_12_0.team.level)
	end

	if arg_12_0.team.guild ~= nil and arg_12_0.team.guild ~= "" then
		arg_12_0:nodeByName("guild_words"):setVisible(true)
		arg_12_0:nodeByName("guild_text"):setVisible(true)
		arg_12_0:nodeByName("guild_text"):setString(arg_12_0.team.guild)
	else
		arg_12_0:nodeByName("guild_words"):setVisible(false)
		arg_12_0:nodeByName("guild_text"):setVisible(false)
	end

	if arg_12_0.arenaType_ then
		arg_12_0.titleRank:hide()
		arg_12_0:addTeamHero()
		arg_12_0:container():height(arg_12_0:container():getHeight() + 130)
		arg_12_0:container():y(arg_12_0:container():getY() + 60)
		arg_12_0:nodeByName("rank_container"):y(arg_12_0:nodeByName("rank_container"):getY() + 170)
		arg_12_0:nodeByName("title_bar"):y(arg_12_0:nodeByName("title_bar"):getY() + 130)
		arg_12_0.heroesContainer:y(arg_12_0.heroesContainer:getY() + 170)
		arg_12_0.heroesContainer2:y(arg_12_0.heroesContainer2:getY() + 170)
		arg_12_0.heroesContainer3:y(arg_12_0.heroesContainer3:getY() + 170)
	else
		arg_12_0:updateRank()
		arg_12_0:addHeroCells()
		arg_12_0:updateSealHero()
	end
end

function var_0_0.updateRank(arg_13_0)
	if type(arg_13_0.team.rank) ~= "number" then
		return
	end

	local var_13_0, var_13_1 = arg_13_0:nodeByName("rank_pos"):getPosition()

	arg_13_0.rankLabel = xyd.AssetLoader.get():loadLabel(nil, "bonus")

	arg_13_0.rankLabel:setString(tostring(arg_13_0.team.rank))
	arg_13_0.rankLabel:addTo(arg_13_0:nodeByName("container"):getChildByName("rank_container"))
	arg_13_0.rankLabel:setPosition(var_13_0, var_13_1)
	arg_13_0.rankLabel:setAnchorPoint(cc.p(0, 0.5))
end

function var_0_0.addHeroCells(arg_14_0)
	arg_14_0.heroesContainer:removeAllChildren()

	if not arg_14_0.team or not arg_14_0.team.heroes or not next(arg_14_0.team.heroes) then
		return
	end

	local var_14_0 = 1

	if arg_14_0.team.pet then
		local var_14_1 = display.newNode()

		var_14_1:setContentSize(65, 65)

		local var_14_2 = var_0_2.new()

		var_14_2:populate(arg_14_0.team.pet)
		xyd.setPetAvatar(var_14_1, var_14_2, nil, true)
		var_14_1:setScale(0.65, 0.65)
		var_14_1:setPosition(10, 10)
		arg_14_0.heroesContainer:addChild(var_14_1)

		var_14_0 = var_14_0 + 1

		for iter_14_0, iter_14_1 in pairs(arg_14_0.team.heroes) do
			local var_14_3 = display.newNode()

			var_14_3:setContentSize(65, 65)
			var_14_3:setPosition(cc.p(70 * (var_14_0 - 1), 0))
			xyd.setAvatarBorder(iter_14_1, var_14_3)
			arg_14_0.heroesContainer:addChild(var_14_3)

			var_14_0 = var_14_0 + 1
		end
	else
		for iter_14_2, iter_14_3 in pairs(arg_14_0.team.heroes) do
			local var_14_4 = display.newNode()

			var_14_4:setContentSize(80, 80)
			var_14_4:setPosition(cc.p(85 * (var_14_0 - 1), 0))
			xyd.setAvatarBorder(iter_14_3, var_14_4)
			arg_14_0.heroesContainer:addChild(var_14_4)

			var_14_0 = var_14_0 + 1
		end
	end
end

function var_0_0.addTeamHero(arg_15_0)
	arg_15_0.heroesContainer:removeAllChildren()
	arg_15_0.heroesContainer2:removeAllChildren()
	arg_15_0.heroesContainer3:removeAllChildren()

	local var_15_0 = arg_15_0.team.force

	if arg_15_0.team and arg_15_0.team.team1 and next(arg_15_0.team.team1) then
		for iter_15_0, iter_15_1 in pairs(arg_15_0.team.team1) do
			local var_15_1 = display.newNode()

			var_15_1:setContentSize(80, 80)
			var_15_1:setPosition(cc.p(85 * (iter_15_0 - 1), 0))

			if var_15_0 >= 2000 then
				local var_15_2 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

				xyd.displaySpriteOnContainer(var_15_2, var_15_1, true)
			else
				xyd.setAvatarBorder(iter_15_1, var_15_1)
			end

			arg_15_0.heroesContainer:addChild(var_15_1)
		end
	end

	if arg_15_0.team and arg_15_0.team.team2 and next(arg_15_0.team.team2) then
		for iter_15_2, iter_15_3 in pairs(arg_15_0.team.team2) do
			local var_15_3 = display.newNode()

			var_15_3:setContentSize(80, 80)
			var_15_3:setPosition(cc.p(85 * (iter_15_2 - 1), 0))

			local var_15_4 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

			xyd.displaySpriteOnContainer(var_15_4, var_15_3, true)
			arg_15_0.heroesContainer2:addChild(var_15_3)
		end
	end

	if arg_15_0.team and arg_15_0.team.team3 and next(arg_15_0.team.team3) then
		for iter_15_4, iter_15_5 in pairs(arg_15_0.team.team3) do
			local var_15_5 = display.newNode()

			var_15_5:setContentSize(80, 80)
			var_15_5:setPosition(cc.p(85 * (iter_15_4 - 1), 0))

			local var_15_6 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

			xyd.displaySpriteOnContainer(var_15_6, var_15_5, true)
			arg_15_0.heroesContainer3:addChild(var_15_5)
		end
	end
end

function var_0_0.didClose(arg_16_0)
	var_0_0.super.didClose()
end

function var_0_0.container(arg_17_0)
	return arg_17_0:nodeByName("container")
end

function var_0_0.updateSealHero(arg_18_0)
	local var_18_0 = arg_18_0.team.isSealHeroOpen
	local var_18_1 = arg_18_0.team.sealHeroID

	if var_18_0 then
		local var_18_2

		if var_18_1 > 0 then
			var_18_2 = xyd.tables.hero:name(var_18_1)
		else
			var_18_2 = xyd.tables.translation:translation("NOT_SEAL_HERO")
		end

		arg_18_0:nodeByName("seal_hero_name"):setVisible(true)
		arg_18_0:nodeByName("seal_hero"):setVisible(true)
		arg_18_0:nodeByName("seal_hero_name"):setString(var_18_2)
		arg_18_0:nodeByName("seal_hero"):setString(xyd.tables.translation:translation("MAGIC_SEAL"))

		local var_18_3 = 0

		if arg_18_0.team.guild ~= nil and arg_18_0.team.guild ~= "" then
			arg_18_0:container():height(arg_18_0:container():getHeight() + 30)
			arg_18_0:container():y(arg_18_0:container():getY() + 30)
			arg_18_0:nodeByName("rank_container"):y(arg_18_0:nodeByName("rank_container"):getY() + 30)
			arg_18_0:nodeByName("title_bar"):y(arg_18_0:nodeByName("title_bar"):getY() + 30)
		else
			arg_18_0:nodeByName("seal_hero_name"):y(arg_18_0:nodeByName("seal_hero_name"):getY() + 36)
			arg_18_0:nodeByName("seal_hero"):y(arg_18_0:nodeByName("seal_hero"):getY() + 36)
		end
	else
		arg_18_0:nodeByName("seal_hero_name"):setVisible(false)
		arg_18_0:nodeByName("seal_hero"):setVisible(false)
	end
end

return var_0_0
