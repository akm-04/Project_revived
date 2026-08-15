local var_0_0 = class("RegionArenaTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "arena_team_info"
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.misc

function var_0_0.close(arg_1_0)
	xyd.WindowManager.get():closeWindow(var_0_1, arg_1_0)

	self.heroList = {}
end

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	var_0_0.super.ctor(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0:formatParams(arg_2_2.team)

	arg_2_0.arenaType_ = arg_2_2.arena_type

	if arg_2_2.is_challenge then
		arg_2_0.is_challenge = arg_2_2.is_challenge
		arg_2_0.enemyID = arg_2_2.enemy_id
	end

	arg_2_0.concealNum = 0
end

function var_0_0.formatParams(arg_3_0, arg_3_1)
	arg_3_0.team = {
		name = arg_3_1.name,
		level = arg_3_1.level,
		fans = arg_3_1.be_support_num,
		avatar_id = arg_3_1.avatar_id,
		avatar_frame_id = arg_3_1.avatar_frame_id,
		point = arg_3_1.point,
		server = "(" .. arg_3_1.region .. ")" .. arg_3_1.region_name,
		wins = arg_3_1.win_times,
		guild = arg_3_1.guild_name,
		heroes = arg_3_1.heros,
		rank = tonumber(arg_3_1.region_rank),
		rank_type = tonumber(arg_3_1.rank_type),
		daily_rank = tonumber(arg_3_1.rank)
	}

	if arg_3_1.pet_info then
		arg_3_0.team.pet = arg_3_1.pet_info
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	var_0_0.super.willOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
end

function var_0_0.initHeros(arg_6_0)
	arg_6_0.heroList = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.team.heroes) do
		local var_6_0 = var_0_3.new()

		var_6_0:populate(iter_6_1)
		xyd.formatRegionArenaHeros({
			var_6_0
		})
		table.insert(arg_6_0.heroList, var_6_0)
	end

	table.sort(arg_6_0.heroList, function(arg_7_0, arg_7_1)
		return arg_7_0:getDistance() > arg_7_1:getDistance()
	end)
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = arg_8_0:container()
	local var_8_1 = var_8_0:getContentSize()
	local var_8_2 = cc.p(var_8_0:getPosition())

	local function var_8_3(arg_9_0, arg_9_1)
		xyd.WindowManager.get():closeWindow(var_0_1, callback)

		return true
	end

	local var_8_4 = cc.EventListenerTouchOneByOne:create()

	var_8_4:setSwallowTouches(true)
	var_8_4:registerScriptHandler(var_8_3, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_8_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_8_4, arg_8_0)
	arg_8_0:nodeByName("lev_txt"):setString(var_0_4:translation("REGION_ARENA_TIP39"))
	arg_8_0:nodeByName("rank_label"):setString(var_0_4:translation("RANK_LABEL"))
	arg_8_0:nodeByName("point_label"):setString(var_0_4:translation("REGION_POINTS_LABEL"))
	arg_8_0:nodeByName("guild_label"):setString(var_0_4:translation("GAME_FROM_LABEL"))
	arg_8_0:nodeByName("server_label"):setString(var_0_4:translation("REGION_ARENA_TIP10"))

	arg_8_0.playerName = arg_8_0:nodeByName("name")
	arg_8_0.avatarPanel = arg_8_0:nodeByName("avatar")
	arg_8_0.textLevel = arg_8_0:nodeByName("lev_txt")
	arg_8_0.pointNum = arg_8_0:nodeByName("point_num")
	arg_8_0.guildTxt = arg_8_0:nodeByName("guild_txt")
	arg_8_0.serverTxt = arg_8_0:nodeByName("server_txt")
	arg_8_0.heroesContainer = arg_8_0:nodeByName("heroes_container")

	if arg_8_0.is_challenge then
		arg_8_0:nodeByName("challenge_btn"):setVisible(true)
		arg_8_0:nodeByName("challenge_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_10_1 = {
					my_id = var_10_0.playerID,
					enemy_id = arg_8_0.team.player_id
				}

				params = {
					withRobot = false,
					is_challenge = true,
					showEnemy = true,
					type = xyd.SelectTeamType.REGION_ARENA,
					campaignType = xyd.CampaignType.REGION_ARENA,
					fighterInfo = var_10_1,
					enemyHeroes = arg_8_0.heroList,
					hide_counts = arg_8_0.concealNum,
					enemyPets = arg_8_0.enemyPet
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, params)
				xyd.WindowManager.get():closeWindow(arg_8_0)
			end
		end)
	end

	arg_8_0:updateTeamInfo()
end

function var_0_0.updateTeamInfo(arg_11_0)
	xyd.setPlayerAvatar(arg_11_0.avatarPanel, {
		avatar_id = arg_11_0.team.avatar_id,
		avatar_frame_id = arg_11_0.team.avatar_frame_id
	})
	arg_11_0.playerName:setString(arg_11_0.team.name)
	arg_11_0.textLevel:setString(arg_11_0.team.level)
	arg_11_0.pointNum:setString(arg_11_0.team.point)
	arg_11_0.guildTxt:setString(arg_11_0.team.guild)
	arg_11_0.serverTxt:setString(arg_11_0.team.server)
	arg_11_0:updateRank()
	arg_11_0:addHeroCells()
end

function var_0_0.updateRank(arg_12_0)
	if type(arg_12_0.team.rank) ~= "number" then
		return
	end

	local var_12_0, var_12_1 = arg_12_0:nodeByName("rank_num"):getPosition()

	arg_12_0.rankLabel = xyd.AssetLoader.get():loadLabel(nil, "bonus")

	arg_12_0.rankLabel:setString(tostring(arg_12_0.team.rank))
	arg_12_0.rankLabel:addTo(arg_12_0:nodeByName("container"))
	arg_12_0.rankLabel:setPosition(var_12_0, var_12_1)
	arg_12_0.rankLabel:setAnchorPoint(cc.p(0, 0.5))
end

function var_0_0.ConcealNum(arg_13_0)
	for iter_13_0 = 1, #var_0_5.newArenaConcealRank do
		if arg_13_0.team.daily_rank < var_0_5.newArenaConcealRank[iter_13_0] then
			arg_13_0.concealNum = var_0_5.newArenaConcealNum[iter_13_0]
		end
	end
end

function var_0_0.addHeroCells(arg_14_0)
	arg_14_0.heroesContainer:removeAllChildren()

	if not arg_14_0.team or not arg_14_0.team.heroes or not next(arg_14_0.team.heroes) then
		return
	end

	arg_14_0:initHeros()

	if arg_14_0.team.rank_type ~= 0 then
		arg_14_0:ConcealNum()
	end

	local var_14_0 = 1

	if arg_14_0.team.pet then
		local var_14_1 = display.newNode()

		var_14_1:setContentSize(80, 80)

		local var_14_2 = var_0_2.new()

		arg_14_0.enemyPet = var_14_2

		var_14_2:populate(arg_14_0.team.pet)
		xyd.formatRegionArenaPets({
			var_14_2
		})
		var_14_1:setScale(0.8, 0.8)
		var_14_1:setPosition(10, 10)

		if var_14_0 <= arg_14_0.concealNum then
			var_14_1:setScale(1, 1)
			var_14_1:setPosition(0, 0)

			local var_14_3 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/pet_hide.png")

			xyd.displaySpriteOnContainer(var_14_3, var_14_1, true)
		else
			xyd.setPetAvatar(var_14_1, var_14_2, false, true)
		end

		arg_14_0.heroesContainer:addChild(var_14_1)

		var_14_0 = var_14_0 + 1

		for iter_14_0, iter_14_1 in ipairs(arg_14_0.heroList) do
			local var_14_4 = display.newNode()

			var_14_4:setContentSize(80, 80)
			var_14_4:setPosition(cc.p(85 * (var_14_0 - 1), 0))

			if var_14_0 <= arg_14_0.concealNum then
				local var_14_5 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/hero_hide.png")

				xyd.displaySpriteOnContainer(var_14_5, var_14_4, true)
			else
				xyd.setAvatarBorder(iter_14_1, var_14_4)
			end

			arg_14_0.heroesContainer:addChild(var_14_4)

			var_14_0 = var_14_0 + 1
		end
	else
		for iter_14_2, iter_14_3 in ipairs(arg_14_0.heroList) do
			local var_14_6 = display.newNode()

			var_14_6:setContentSize(80, 80)
			var_14_6:setPosition(cc.p(85 * (var_14_0 - 1), 0))

			if var_14_0 <= arg_14_0.concealNum - 1 then
				local var_14_7 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/hero_hide.png")

				xyd.displaySpriteOnContainer(var_14_7, var_14_6, true)
			else
				xyd.setAvatarBorder(iter_14_3, var_14_6)
			end

			arg_14_0.heroesContainer:addChild(var_14_6)

			var_14_0 = var_14_0 + 1
		end
	end
end

function var_0_0.didClose(arg_15_0)
	var_0_0.super.didClose()
end

function var_0_0.container(arg_16_0)
	return arg_16_0:nodeByName("container")
end

return var_0_0
