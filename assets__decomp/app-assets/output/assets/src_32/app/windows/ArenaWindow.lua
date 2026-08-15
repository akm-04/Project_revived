local var_0_0 = class("ArenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.arenaMode
local var_0_6 = 100000
local var_0_7 = 5
local var_0_8 = 5
local var_0_9 = 15
local var_0_10 = 3
local var_0_11 = 25
local var_0_12 = 20

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	xyd.LoadingProxy.get():addLoading()
	arg_2_0:addTopSidebar({
		show_rule = true
	})

	arg_2_0.heroList_ = arg_2_0:nodeByName("team_container")
	arg_2_0.heroListWidth = arg_2_0.heroList_:getContentSize().width
	arg_2_0.heroListHeight = arg_2_0.heroList_:getContentSize().height
	arg_2_0.arena_ = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.numArena = xyd.tables.vip:numArena(arg_2_0.player_.vip)
	arg_2_0.arenaReset = xyd.tables.vip:arenaReset(arg_2_0.player_.vip)

	if arg_2_0.player_.privilegeLeftCardEnd > 0 then
		arg_2_0.arenaReset = true
	end

	arg_2_0.refreshContainer = arg_2_0:nodeByName("refresh_container")
	arg_2_0.mRefreshContainer = arg_2_0:nodeByName("mode_refresh_container")
	arg_2_0.modeType = 0
	arg_2_0.isShowArenaMode = false
	arg_2_0.redMarkReport = arg_2_0:nodeByName("red_point_arena")

	if arg_2_0.player_.arenaRedMarkEnable then
		arg_2_0.redMarkReport:setVisible(true)
	else
		arg_2_0.redMarkReport:setVisible(false)
	end

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	xyd.LoadingProxy.get():removeLoading()
	arg_3_0:showArenaInfo()
	arg_3_0:showModeScheduler()
	arg_3_0.arena_:loadModeInfo(function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK and arg_3_0 and not tolua.isnull(arg_3_0) then
			arg_3_0.isShowArenaMode = true

			arg_3_0:initArenaMode()
		end
	end)
	arg_3_0:setTouchSwallowEnabled(true)
	arg_3_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_5_0)
		if arg_5_0.params == xyd.CheckMiddleRed.ARENA then
			arg_3_0:checkArenaRedMark(1)
			arg_3_0.arena_:loadArenaInfo(function(arg_6_0)
				if arg_6_0 == xyd.error.OK then
					local var_6_0 = xyd.WindowManager.get():getWindow("arena")
					local var_6_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

					if var_6_0 then
						var_6_0:updateRank()
					end
				end
			end)
		elseif arg_5_0.params == xyd.CheckMiddleRed.ARENA_CANCEL then
			arg_3_0:checkArenaRedMark(0)
		end
	end)
	arg_3_0:playGuide()
end

function var_0_0.willClose(arg_7_0)
	arg_7_0:stopMatchTimer()
	arg_7_0:stopMMatchTimer()
	arg_7_0:stopAdjustCDTimer()
end

function var_0_0.checkArenaRedMark(arg_8_0, arg_8_1)
	if arg_8_1 == 1 then
		arg_8_0.redMarkReport:setVisible(true)
	else
		arg_8_0.redMarkReport:setVisible(false)
	end
end

function var_0_0.showArenaInfo(arg_9_0)
	arg_9_0:updateRank()
	arg_9_0:addMatchTimer(arg_9_0.refreshContainer)
	arg_9_0:loadHeroListView()
	arg_9_0:updateEnemyListView()

	local var_9_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_9_0.playerName or #var_9_0.playerName == 0 then
		xyd.WindowManager.get():openWindow("edit_player_name")
	end
end

function var_0_0.initPetCell(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	arg_10_1:getChildByName("icon"):removeAllChildren()
	xyd.setPetAvatarNewUI(arg_10_1:getChildByName("icon"), arg_10_2, nil, true)

	local var_10_0 = display.newNode()

	var_10_0:size(arg_10_1:getChildByName("icon"):getWidth(), arg_10_1:getChildByName("icon"):getHeight())
	var_10_0:addTo(arg_10_1:getChildByName("icon"))
	var_10_0:setLocalZOrder(5)
	var_10_0:setTouchEnabled(true)

	if not arg_10_3 then
		arg_10_1:getChildByName("no_pet"):setVisible(true)
		arg_10_1:getChildByName("no_pet"):getChildByName("add"):setVisible(false)
		arg_10_1:getChildByName("no_pet"):getChildByName("lock"):setVisible(true)
		arg_10_1:getChildByName("name_bg"):setVisible(false)
		arg_10_1:getChildByName("name"):setVisible(false)
		arg_10_1:getChildByName("name_gray"):setVisible(true)
		xyd.nodeEventSample(var_10_0, {
			scale = 1
		}, function(arg_11_0)
			if var_0_5:isPet(arg_10_0.modeType) == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ARENA_ADJUST_NOT_OPEN1")
				})
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ARENA_ADJUST_NOT_OPEN2")
				})
			end
		end)

		return
	end

	local var_10_1

	if not arg_10_2 then
		arg_10_1:getChildByName("no_pet"):setVisible(true)
		arg_10_1:getChildByName("no_pet"):getChildByName("add"):setVisible(true)
		arg_10_1:getChildByName("no_pet"):getChildByName("lock"):setVisible(false)
		arg_10_1:getChildByName("name_bg"):setVisible(false)
		arg_10_1:getChildByName("name"):setVisible(false)
		arg_10_1:getChildByName("name_gray"):setVisible(true)

		var_10_1 = arg_10_1:getChildByName("no_pet"):getChildByName("add")
	else
		arg_10_1:getChildByName("no_pet"):setVisible(false)
		arg_10_1:getChildByName("name_bg"):setVisible(true)
		arg_10_1:getChildByName("name"):setVisible(true)
		arg_10_1:getChildByName("name"):setString(arg_10_2:getName())
		arg_10_1:getChildByName("name_gray"):setVisible(false)

		var_10_1 = arg_10_1:getChildByName("icon")
	end

	var_10_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			var_10_1:setScale(0.9)
		elseif arg_12_0.name == "ended" then
			xyd.playButtonSound()
			var_10_1:setScale(1)

			local var_12_0 = var_10_0:getContentSize()
			local var_12_1 = var_10_0:convertToNodeSpace(cc.p(arg_12_0.x, arg_12_0.y))

			if var_12_1.x < 0 or var_12_1.x > var_12_0.width or var_12_1.y < 0 or var_12_1.y > var_12_0.height then
				return
			end

			if arg_10_0.modeType == 0 then
				if arg_10_0.adjustCountDownOn and not FRONT_ARENA_BATTLE then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("ARENA_ADJUST_TIP")
					})

					return
				end

				arg_10_0:setDefenseHeroes()
			else
				if arg_10_0.mAdjustCountDownOn then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("ARENA_ADJUST_TIP")
					})

					return
				end

				arg_10_0:setMDefenseHeroes()
			end
		end

		return true
	end)
end

function var_0_0.initHeroCell(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0

	if arg_13_0.modeType > 0 then
		var_13_0 = arg_13_0.mDefenseHeroes[arg_13_2 or 0]
	else
		var_13_0 = arg_13_0.defenseHeroes[arg_13_2 or 0]
	end

	arg_13_1:getChildByName("icon"):removeAllChildren()

	if var_13_0 then
		xyd.setAvatarBorderNewUI(var_13_0, arg_13_1:getChildByName("icon"))
	end

	local var_13_1 = display.newNode()

	var_13_1:size(arg_13_1:getChildByName("icon"):getWidth(), arg_13_1:getChildByName("icon"):getHeight())
	var_13_1:addTo(arg_13_1:getChildByName("icon"))
	var_13_1:setLocalZOrder(5)
	var_13_1:setTouchEnabled(true)

	if arg_13_3 and arg_13_3.is_lock then
		arg_13_1:getChildByName("no_partner"):setVisible(true)
		arg_13_1:getChildByName("no_partner"):getChildByName("add"):setVisible(false)
		arg_13_1:getChildByName("no_partner"):getChildByName("lock"):setVisible(true)
		arg_13_1:getChildByName("name_bg"):setVisible(false)
		arg_13_1:getChildByName("name"):setVisible(false)
		arg_13_1:getChildByName("name_gray"):setVisible(true)
		xyd.nodeEventSample(var_13_1, {
			scale = 1
		}, function(arg_14_0)
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_3:translation("ARENA_ADJUST_NOT_OPEN1")
			})
		end)

		return
	end

	local var_13_2

	if not var_13_0 then
		arg_13_1:getChildByName("no_partner"):setVisible(true)
		arg_13_1:getChildByName("no_partner"):getChildByName("add"):setVisible(true)
		arg_13_1:getChildByName("no_partner"):getChildByName("lock"):setVisible(false)
		arg_13_1:getChildByName("name_bg"):setVisible(false)
		arg_13_1:getChildByName("name"):setVisible(false)
		arg_13_1:getChildByName("name_gray"):setVisible(true)

		var_13_2 = arg_13_1:getChildByName("no_partner"):getChildByName("add")
	else
		arg_13_1:getChildByName("no_partner"):setVisible(false)
		arg_13_1:getChildByName("name_bg"):setVisible(true)
		arg_13_1:getChildByName("name"):setVisible(true)
		arg_13_1:getChildByName("name"):setString(var_13_0:getName())
		arg_13_1:getChildByName("name_gray"):setVisible(false)

		var_13_2 = arg_13_1:getChildByName("icon")
	end

	var_13_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			var_13_2:setScale(0.9)
		elseif arg_15_0.name == "ended" then
			xyd.playButtonSound()
			var_13_2:setScale(1)

			local var_15_0 = var_13_1:getContentSize()
			local var_15_1 = var_13_1:convertToNodeSpace(cc.p(arg_15_0.x, arg_15_0.y))

			if var_15_1.x < 0 or var_15_1.x > var_15_0.width or var_15_1.y < 0 or var_15_1.y > var_15_0.height then
				return
			end

			if arg_13_0.modeType == 0 then
				if arg_13_0.adjustCountDownOn and not FRONT_ARENA_BATTLE then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("ARENA_ADJUST_TIP")
					})

					return
				end

				arg_13_0:setDefenseHeroes()
			else
				if arg_13_0.mAdjustCountDownOn then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_3:translation("ARENA_ADJUST_TIP")
					})

					return
				end

				arg_13_0:setMDefenseHeroes()
			end
		end

		return true
	end)

	if arg_13_0.modeType == xyd.ArenaModeType.LEAD and var_13_0 and var_13_0:getHeroID() == arg_13_0.arena_.mLeadId then
		local var_13_3 = xyd.AssetLoader.get():loadSprite("windows/arena/mode/lead_icon.png")

		var_13_3:addTo(arg_13_1:getChildByName("icon"))
		var_13_3:setPosition(-13, 82)
		var_13_3:setLocalZOrder(4)
	end
end

function var_0_0.initEnemyCell(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0.enemies[arg_16_2]
	local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/enemy_item.csb")
	local var_16_2 = var_16_1:getChildByName("container")
	local var_16_3 = var_16_2:getContentSize()

	var_16_1:setContentSize(var_16_3)
	arg_16_1:setContentSize(var_16_3)

	if not var_16_0 then
		var_16_1:addTo(arg_16_1)
		var_16_1:getChildByName("container"):setVisible(false)

		return
	else
		var_16_1:getChildByName("no_enemy"):setVisible(false)
	end

	var_16_2:getChildByName("name"):setString(var_16_0.player_name)
	var_16_2:getChildByName("rank"):setString(var_16_0.rank)
	var_16_2:getChildByName("rank_label"):setString(var_0_3:translation("RANKING") .. var_0_3:translation("COLON"))
	var_16_2:getChildByName("force_label"):setString(var_0_3:translation("FORCE_TXT"))

	local var_16_4 = 0
	local var_16_5 = {}
	local var_16_6
	local var_16_7
	local var_16_8 = var_16_0.book_shelf_lev
	local var_16_9 = var_16_0.table_id and var_16_0.table_id <= 25000 and true or false

	if var_16_0.heros and next(var_16_0.heros) then
		for iter_16_0, iter_16_1 in pairs(var_16_0.heros) do
			local var_16_10 = iter_16_1

			if var_16_9 == true then
				var_16_10.table_id = iter_16_1.partner_id
			end

			if type(var_16_10.equips) == "string" then
				var_16_10.equips = xyd.splitToNumber(var_16_10.equips, "|")
			end

			if var_16_8 and var_16_8 > 0 then
				var_16_10.book_shelf_lev = var_16_8
			else
				var_16_10.book_shelf_lev = 0
			end

			local var_16_11 = var_0_1.new()

			var_16_11:populate(var_16_10)

			if var_16_0.conquer_lev and var_16_0.conquer_lev > 0 then
				var_16_11:setConquerSchoolLev(var_16_0.conquer_lev)
			end

			table.insert(var_16_5, var_16_11)

			if var_16_9 then
				var_16_4 = var_16_4 + var_16_11:getZhandouli()
			else
				var_16_4 = var_16_4 + var_16_11.force_
			end
		end
	end

	local function var_16_12(arg_17_0)
		var_16_4 = 0
		var_16_5 = {}
		var_16_0.heros = arg_17_0.heros

		if var_16_0.heros and next(var_16_0.heros) then
			for iter_17_0, iter_17_1 in pairs(var_16_0.heros) do
				local var_17_0 = iter_17_1

				if var_16_9 == true then
					var_17_0.table_id = iter_17_1.partner_id
					var_17_0.partner_id = iter_17_0
				end

				if type(var_17_0.equips) == "string" then
					var_17_0.equips = xyd.splitToNumber(var_17_0.equips, "|")
				end

				if var_16_8 and var_16_8 > 0 then
					var_17_0.book_shelf_lev = var_16_8
				else
					var_17_0.book_shelf_lev = 0
				end

				local var_17_1 = var_0_1.new()

				var_17_1:populate(var_17_0)

				if iter_17_1.is_leader and iter_17_1.is_leader > 0 then
					var_17_1.isLeader = true
				end

				if arg_17_0.conquer_lev and arg_17_0.conquer_lev > 0 then
					var_17_1:setConquerSchoolLev(arg_17_0.conquer_lev)
				end

				table.insert(var_16_5, var_17_1)

				if var_16_9 then
					var_16_4 = var_16_4 + var_17_1:getZhandouli()
				else
					var_16_4 = var_16_4 + var_17_1.force_
				end
			end
		end

		if arg_17_0.pet then
			local var_17_2 = arg_17_0.pet

			if type(var_17_2.equips) == "string" then
				var_17_2.equips = xyd.splitToNumber(var_17_2.equips, "|")
			end

			local var_17_3 = import("app.model.Pet").new()

			var_17_3:populate(var_17_2)

			var_16_6 = var_17_3
			var_16_0.pet = arg_17_0.pet
			var_16_4 = var_16_4 + var_17_3:getZhandouli()
		else
			var_16_0.pet = nil
			var_16_6 = nil
		end
	end

	if var_16_0.pet then
		local var_16_13 = var_16_0.pet

		if type(var_16_13.equips) == "string" then
			var_16_13.equips = xyd.splitToNumber(var_16_13.equips, "|")
		end

		local var_16_14 = import("app.model.Pet").new()

		var_16_14:populate(var_16_13)

		var_16_6 = var_16_14
		var_16_4 = var_16_4 + var_16_14:getZhandouli()
	else
		var_16_6 = nil
	end

	local var_16_15 = var_16_2:getChildByName("avatar_panel")

	local function var_16_16(arg_18_0)
		if arg_18_0.name == "began" then
			-- block empty
		elseif arg_18_0.name == "ended" then
			local var_18_0 = {
				other_player_id = (var_16_0.table_id or 0) + arg_16_0.player_.region * var_0_6
			}
			local var_18_1 = arg_16_0.modeType > 0 and xyd.mid.ARENA_MODE_QUERY_FORMATION or xyd.mid.query_arena_formation

			xyd.Backend.get():request(var_18_1, var_18_0, function(arg_19_0, arg_19_1)
				var_16_12(arg_19_1)

				local var_19_0 = {
					name = var_16_0.player_name,
					level = var_16_0.lev,
					avatar_id = var_16_0.avatar_id,
					avatar_frame_id = var_16_0.avatar_frame_id,
					win = var_16_0.win,
					rank = var_16_0.rank,
					force = var_16_0.force,
					heroes = var_16_5,
					force = var_16_4,
					guild = var_16_0.guild_name,
					pet = var_16_0.pet,
					isSealHeroOpen = arg_16_0.arena_.isSealHeroOpen,
					sealHeroID = var_16_0.ban_hero_id,
					conquer_lev = var_16_0.conquer_lev,
					conquer_loop_id = var_16_0.conquer_loop_id,
					player_id = (var_16_0.table_id or 0) + arg_16_0.player_.region * var_0_6
				}

				xyd.WindowManager.get():openWindow("arena_team_info", {
					is_red = true,
					team = var_19_0
				})
			end)
		end

		return true
	end

	xyd.setPlayerAvatar(var_16_15, {
		showLevel = true,
		is_new = true,
		avatar_id = var_16_0.avatar_id,
		avatar_frame_id = var_16_0.avatar_frame_id,
		level = var_16_0.lev,
		conquerLev = var_16_0.conquer_lev,
		conquerLoopID = var_16_0.conquer_loop_id,
		callback = var_16_16
	})
	var_16_2:getChildByName("force"):setString(var_16_4)
	var_16_1:setName("layout")
	var_16_1:setPosition(cc.p(0, 0))

	arg_16_1.data = hero

	arg_16_1:addChild(var_16_1)

	local var_16_17 = var_16_2:getChildByName("challenge_button")

	xyd.nodeEventSample(var_16_17, nil, function(arg_20_0)
		if arg_16_0.guideFightHand and not tolua.isnull(arg_16_0.guideFightHand) then
			arg_16_0.guideFightHand:removeSelf()
		end

		xyd.playButtonSound()

		if not arg_16_0:challengeTimeDeal() then
			return
		end

		local var_20_0 = {
			other_player_id = (var_16_0.table_id or 0) + arg_16_0.player_.region * var_0_6
		}
		local var_20_1
		local var_20_2
		local var_20_3

		if arg_16_0.modeType > 0 then
			var_20_1 = xyd.mid.ARENA_MODE_QUERY_FORMATION
			var_20_2 = arg_16_0.arena_.mLeftTime
			var_20_3 = arg_16_0.mCountDownOn
		else
			var_20_1 = xyd.mid.query_arena_formation
			var_20_2 = arg_16_0.arena_.leftTime
			var_20_3 = arg_16_0.countDownOn
		end

		xyd.Backend.get():request(var_20_1, var_20_0, function(arg_21_0, arg_21_1)
			var_16_12(arg_21_1)

			if var_20_2 and var_20_2 <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_3:translation("TRIAL_LEFT_TIMES"), 0)
				})
			elseif var_20_3 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("TIME_TOO_EARLY")
				})
			else
				local var_21_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_21_1 = {
					my_id = var_21_0.playerID,
					enemy_id = var_16_0.table_id or 0,
					enemy_title_info = var_16_0.title_info or {}
				}

				if arg_16_0.modeType > 0 then
					var_21_1.enemy_id = var_21_1.enemy_id + arg_16_0.player_.region * var_0_6
					var_20_0 = {
						is_avenge = 0,
						showEnemy = true,
						type = xyd.SelectTeamType.ARENA_MODE,
						campaignType = xyd.CampaignType.ARENA_MODE,
						fighterInfo = var_21_1,
						enemyHeroes = var_16_5,
						withRobot = var_16_9,
						oldBestRank = arg_16_0.arena_:getBestRank(),
						enemyPets = var_16_6,
						banPet = xyd.tables.arenaMode:isPet(arg_16_0.modeType) == 0
					}

					if arg_16_0.modeType == xyd.ArenaModeType.SINGLE then
						var_20_0.selectSpType = xyd.SelectSpType.SINGLE
						var_20_0.noPreset = true
					elseif arg_16_0.modeType == xyd.ArenaModeType.TRIPLE then
						var_20_0.selectSpType = xyd.SelectSpType.TRIPLE
						var_20_0.noPreset = true
					elseif arg_16_0.modeType == xyd.ArenaModeType.LEAD then
						var_20_0.selectSpType = xyd.SelectSpType.LEAD
					elseif arg_16_0.modeType == xyd.ArenaModeType.BAN then
						var_20_0.selectSpType = xyd.SelectSpType.BAN
						var_20_0.bannedHeros = xyd.tables.arenaMode:banList(arg_16_0.arena_.modeType)
					elseif arg_16_0.modeType == xyd.ArenaModeType.PHANTOM then
						var_20_0.selectSpType = xyd.SelectSpType.PHANTOM
						var_20_0.noPreset = true
						var_20_0.bannedHeros = xyd.tables.arenaMode:banList(arg_16_0.arena_.modeType)

						local var_21_2

						for iter_21_0, iter_21_1 in pairs(var_20_0.enemyHeroes) do
							var_21_2 = iter_21_1
						end

						local var_21_3 = {}

						for iter_21_2 = 1, 5 do
							table.insert(var_21_3, var_21_2)
						end

						var_20_0.enemyHeroes = var_21_3
					elseif arg_16_0.modeType == xyd.ArenaModeType.CAMP then
						if arg_16_0.arena_.subMode > 0 then
							var_20_0.selectSpType = arg_16_0.arena_.subMode
						else
							var_20_0.selectSpType = xyd.SelectSpType.CAMP
						end

						var_20_0.noPreset = true
						var_20_0.bannedHeros = xyd.tables.arenaMode:banList(arg_16_0.arena_.modeType)
					end
				else
					var_20_0 = {
						is_avenge = 0,
						showEnemy = true,
						type = xyd.SelectTeamType.ARENA,
						campaignType = xyd.CampaignType.ARENA,
						fighterInfo = var_21_1,
						enemyHeroes = var_16_5,
						withRobot = var_16_9,
						oldBestRank = arg_16_0.arena_:getBestRank(),
						enemyPets = var_16_6
					}

					if arg_16_0.arena_.isSealHeroOpen then
						var_20_0.sealHeroID = var_16_0.ban_hero_id
					end
				end

				local var_21_4 = arg_16_0.modeType > 0 and xyd.mid.ARENA_MODE_FIGHT_PRE or xyd.mid.ARENA_PRE_FIGHT

				xyd.Backend.get():request(var_21_4, {
					enemy_id = var_16_0.table_id
				}, function(arg_22_0, arg_22_1)
					if arg_22_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("arena_select_team", var_20_0)
					end
				end)
			end
		end)
	end)

	if arg_16_2 == var_0_10 then
		arg_16_0.guideFightBtn = var_16_17
	end
end

function var_0_0.addMatchTimer(arg_23_0)
	arg_23_0.refreshContainer:getChildByName("text_remain_num"):setString(string.format("%d/5", arg_23_0.arena_.leftTime or 0))

	if arg_23_0.arena_.leftTime > 0 and arg_23_0.arena_.leftTime < 5 then
		arg_23_0.countDownTime = arg_23_0.arena_.lastMatchTime + 300 - xyd.ServerTime.get():getServerTime()

		if arg_23_0.countDownTime > 0 and arg_23_0.matchCountDown_ == nil then
			arg_23_0.countDownOn = true

			arg_23_0:updateCountDownLabel(arg_23_0.countDownTime)

			arg_23_0.matchCountDown_ = import("app.common.CountDown").new(arg_23_0.countDownTime)

			arg_23_0.matchCountDown_:start(handler(arg_23_0, arg_23_0.updateCountDownLabel))
		end
	else
		arg_23_0:stopMatchTimer()
	end

	arg_23_0:setRefreshStatus()
end

function var_0_0.addMMatchTimer(arg_24_0)
	arg_24_0.mRefreshContainer:getChildByName("text_remain_num"):setString(string.format("%d/5", arg_24_0.arena_.mLeftTime or 0))

	if arg_24_0.arena_.mLeftTime > 0 and arg_24_0.arena_.mLeftTime < 5 then
		arg_24_0.mCountDownTime = arg_24_0.arena_.mLastMatchTime + 300 - xyd.ServerTime.get():getServerTime()

		if arg_24_0.mCountDownTime > 0 and arg_24_0.mMatchCountDown_ == nil then
			arg_24_0.mCountDownOn = true

			arg_24_0:updateMCountDownLabel(arg_24_0.mCountDownTime)

			arg_24_0.mMatchCountDown_ = import("app.common.CountDown").new(arg_24_0.mCountDownTime)

			arg_24_0.mMatchCountDown_:start(handler(arg_24_0, arg_24_0.updateMCountDownLabel))
		end
	else
		arg_24_0:stopMMatchTimer()
	end

	arg_24_0:setMRefreshStatus()
end

function var_0_0.addAdjustCDTimer(arg_25_0)
	arg_25_0.adjustCountDownTime = xyd.ServerTime.get():getServerTime() - arg_25_0.arena_.setFormationTime

	if arg_25_0.adjustCountDownTime < var_0_4.arenaAdjustmentTime then
		arg_25_0.adjustCountDownTime = 10 - (xyd.ServerTime.get():getServerTime() - arg_25_0.arena_.setFormationTime)
		arg_25_0.adjustCountDownOn = true

		arg_25_0:updateAdjustLabel(arg_25_0.adjustCountDownTime)

		if arg_25_0.adjustCountDown_ then
			arg_25_0.adjustCountDown_:stop()
			arg_25_0.adjustCountDown_:setSeconds(arg_25_0.adjustCountDownTime)
		else
			arg_25_0.adjustCountDown_ = import("app.common.CountDown").new(arg_25_0.adjustCountDownTime)
		end

		arg_25_0.adjustCountDown_:start(handler(arg_25_0, arg_25_0.updateAdjustLabel))
	else
		arg_25_0:stopAdjustCDTimer()
	end
end

function var_0_0.stopMatchTimer(arg_26_0)
	if arg_26_0.matchCountDown_ then
		arg_26_0.matchCountDown_:stop()

		arg_26_0.countDownOn = false
	end

	arg_26_0:setRefreshStatus()
end

function var_0_0.stopMMatchTimer(arg_27_0)
	if not arg_27_0.arena_.modeType then
		return
	end

	if arg_27_0.mMatchCountDown_ then
		arg_27_0.mMatchCountDown_:stop()

		arg_27_0.mCountDownOn = false
	end

	arg_27_0:setMRefreshStatus()
end

function var_0_0.stopAdjustCDTimer(arg_28_0)
	if arg_28_0.adjustCountDown_ then
		arg_28_0.adjustCountDown_:stop()

		arg_28_0.adjustCountDownOn = false
	end
end

function var_0_0.refreshTicket(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_2 and arg_29_0.mRefreshContainer or arg_29_0.refreshContainer

	if arg_29_1.refresh_type == 1 then
		print("reset text remain")
		var_29_0:getChildByName("text_remain_num"):setString(string.format("%d/5", arg_29_0.arena_.leftTime))
	elseif arg_29_2 then
		arg_29_0:stopMMatchTimer()
	else
		arg_29_0:stopMatchTimer()
	end

	if arg_29_2 then
		arg_29_0:setMRefreshStatus()
	else
		arg_29_0:setRefreshStatus()
	end
end

function var_0_0.setRefreshStatus(arg_30_0)
	local var_30_0 = arg_30_0.refreshContainer
	local var_30_1 = arg_30_0:nodeByName("change_txt")
	local var_30_2 = var_30_0:getChildByName("crystal_panel")
	local var_30_3 = var_30_2:getChildByName("text_cost")

	if arg_30_0.numArena > arg_30_0.arena_.buyNum and arg_30_0.arena_.leftTime and arg_30_0.arena_.leftTime <= 0 then
		arg_30_0.refreshStatus_ = 1

		var_30_1:setString(var_0_3:translation("ARENA_BUY_TIME"))
		var_30_2:setVisible(true)
		arg_30_0.countDownLabel_:setVisible(false)
		arg_30_0.challengeLabel_:setVisible(false)
		var_30_3:setString(xyd.tables.refreshCost:buyArenaCost(arg_30_0.arena_.buyNum + 1))
	elseif arg_30_0.arenaReset and arg_30_0.matchCountDown_ and arg_30_0.matchCountDown_.isRunning_ then
		arg_30_0.refreshStatus_ = 2

		var_30_1:setString(var_0_3:translation("ARENA_RESET_TXT"))
		var_30_2:setVisible(true)
		var_30_3:setString(var_0_4.arenaRefreshCost)
	else
		arg_30_0.refreshStatus_ = 3

		var_30_1:setString(var_0_3:translation("ARENA_CHANGE_ENEMY"))
		var_30_2:setVisible(false)
		arg_30_0.countDownLabel_:setVisible(false)
		arg_30_0.challengeLabel_:setVisible(false)
	end
end

function var_0_0.setMRefreshStatus(arg_31_0)
	local var_31_0 = arg_31_0.mRefreshContainer
	local var_31_1 = arg_31_0:nodeByName("mode_change_txt")
	local var_31_2 = var_31_0:getChildByName("crystal_panel")
	local var_31_3 = var_31_2:getChildByName("text_cost")

	if arg_31_0.numArena > arg_31_0.arena_.mBuyNum and arg_31_0.arena_.mLeftTime and arg_31_0.arena_.mLeftTime <= 0 then
		arg_31_0.mRefreshStatus_ = 1

		var_31_1:setString(var_0_3:translation("ARENA_BUY_TIME"))
		var_31_2:setVisible(true)
		var_31_3:setString(xyd.tables.refreshCost:buyArenaCost(arg_31_0.arena_.mBuyNum + 1))
	elseif arg_31_0.arenaReset and arg_31_0.mMatchCountDown_ and arg_31_0.mMatchCountDown_.isRunning_ then
		arg_31_0.mRefreshStatus_ = 2

		var_31_1:setString(var_0_3:translation("ARENA_RESET_TXT"))
		var_31_2:setVisible(true)
		var_31_3:setString(var_0_4.arenaRefreshCost)
	else
		arg_31_0.mRefreshStatus_ = 3

		var_31_1:setString(var_0_3:translation("ARENA_CHANGE_ENEMY"))
		var_31_2:setVisible(false)
		arg_31_0.mCountDownLabel_:setVisible(false)
		arg_31_0.mChallengeLabel_:setVisible(false)
	end
end

function var_0_0.updateCountDownLabel(arg_32_0, arg_32_1)
	local var_32_0 = math.floor(arg_32_1 % 3600 / 60)
	local var_32_1 = arg_32_1 % 60
	local var_32_2 = ""

	if var_32_0 < 10 then
		var_32_2 = "0"
	end

	local var_32_3 = var_32_2 .. tostring(var_32_0) .. ":"

	if var_32_1 < 10 then
		var_32_3 = var_32_3 .. "0"
	end

	local var_32_4 = var_32_3 .. tostring(var_32_1) .. xyd.tables.translation:translation("LATER")

	if arg_32_0.countDownLabel_ then
		if arg_32_1 > 0 then
			arg_32_0.countDownLabel_:setString(var_32_4)
			arg_32_0.countDownLabel_:setVisible(true)
			arg_32_0.challengeLabel_:setVisible(true)
		else
			arg_32_0.countDownLabel_:setVisible(false)
			arg_32_0.challengeLabel_:setVisible(false)
			arg_32_0:stopMatchTimer()
		end
	end
end

function var_0_0.updateMCountDownLabel(arg_33_0, arg_33_1)
	local var_33_0 = math.floor(arg_33_1 % 3600 / 60)
	local var_33_1 = arg_33_1 % 60
	local var_33_2 = ""

	if var_33_0 < 10 then
		var_33_2 = "0"
	end

	local var_33_3 = var_33_2 .. tostring(var_33_0) .. ":"

	if var_33_1 < 10 then
		var_33_3 = var_33_3 .. "0"
	end

	local var_33_4 = var_33_3 .. tostring(var_33_1) .. xyd.tables.translation:translation("LATER")

	if arg_33_0.mCountDownLabel_ then
		if arg_33_1 > 0 then
			arg_33_0.mCountDownLabel_:setString(var_33_4)
			arg_33_0.mCountDownLabel_:setVisible(true)
			arg_33_0.mChallengeLabel_:setVisible(true)
		else
			arg_33_0.mCountDownLabel_:setVisible(false)
			arg_33_0.mChallengeLabel_:setVisible(false)
			arg_33_0:stopMMatchTimer(container)
		end
	end
end

function var_0_0.layout(arg_34_0)
	arg_34_0.countDownLabel_ = arg_34_0.refreshContainer:getChildByName("count_down")
	arg_34_0.challengeLabel_ = arg_34_0.refreshContainer:getChildByName("lbl_challenge")
	arg_34_0.mCountDownLabel_ = arg_34_0.mRefreshContainer:getChildByName("count_down")
	arg_34_0.mChallengeLabel_ = arg_34_0.mRefreshContainer:getChildByName("lbl_challenge")

	arg_34_0:nodeByName("lbl_defense"):setString(xyd.tables.translation:translation("DEFENSE_FORMATION"))
	arg_34_0:nodeByName("lbl_total_force"):setString(xyd.tables.translation:translation("HERO_INFO_ZHANDOULI"))
	arg_34_0:nodeByName("lbl_rank"):setString(xyd.tables.translation:translation("MY_RANKING"))
	arg_34_0:nodeByName("lbl_remain"):setString(xyd.tables.translation:translation("TODAY_LEFT_TIME"))
	arg_34_0:nodeByName("lbl_enemy"):setString(xyd.tables.translation:translation("ARENA_ENEMY_INFO"))
	arg_34_0:nodeByName("lbl_info"):setString(xyd.tables.translation:translation("ARENA_MY_INFO"))
	arg_34_0:nodeByName("lbl_name"):setString(arg_34_0.player_.playerName)
	arg_34_0.challengeLabel_:setString(xyd.tables.translation:translation("CAN_CHALLENGE_AGAIN"))
	arg_34_0.mChallengeLabel_:setString(xyd.tables.translation:translation("CAN_CHALLENGE_AGAIN"))
	arg_34_0:nodeByName("record_text"):setString(xyd.tables.translation:translation("FIGHT_RECORD"))
	arg_34_0:nodeByName("rank_text"):setString(xyd.tables.translation:translation("RANKING_LIST"))
	arg_34_0:nodeByName("award_text"):setString(xyd.tables.translation:translation("EXCHANGE_AWARD"))

	arg_34_0.buttons = {}
	arg_34_0.rank_btn = arg_34_0:nodeByName("rank_button")
	arg_34_0.rule_btn = arg_34_0:nodeByName("top_sidebar"):nodeByName("rule")
	arg_34_0.award_btn = arg_34_0:nodeByName("award_button")
	arg_34_0.scheduleBtn = arg_34_0:nodeByName("schedule_btn")
	arg_34_0.changeModeBtn = arg_34_0:nodeByName("change_mode_btn")
	arg_34_0.adjustLabel = arg_34_0:nodeByName("lbl_adjust")

	arg_34_0:nodeByName("refresh_container"):setVisible(arg_34_0.modeType == 0)
	arg_34_0:nodeByName("mode_refresh_container"):setVisible(arg_34_0.modeType > 0)
	table.insert(arg_34_0.buttons, arg_34_0.adjust_btn)
	table.insert(arg_34_0.buttons, arg_34_0.seal_btn)
	table.insert(arg_34_0.buttons, arg_34_0.rank_btn)
	table.insert(arg_34_0.buttons, arg_34_0.rule_btn)
	table.insert(arg_34_0.buttons, arg_34_0.award_btn)

	for iter_34_0, iter_34_1 in pairs(arg_34_0.buttons) do
		iter_34_1:setTouchEnabled(true)
	end

	arg_34_0:setTouchSwallowEnabled(true)
	xyd.nodeEventSample(arg_34_0.refreshContainer:getChildByName("change_button"), nil, function(arg_35_0)
		xyd.playButtonSound()

		if arg_34_0.refreshStatus_ == 1 then
			local var_35_0 = xyd.tables.refreshCost:buyArenaCost(arg_34_0.arena_.buyNum + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_3:translation("ARENA_BUY_TIMES1"), arg_34_0.arena_.buyNum + 1),
				string.format(var_0_3:translation("ARENA_BUY_TIMES2"), var_35_0)
			}, function()
				if var_35_0 > arg_34_0.player_.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_37_0 = {}

						var_37_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_37_0)
					end, nil, nil, arg_34_0.colorMode)
				else
					arg_34_0.arena_:buyTicket()
				end
			end, nil, 0, arg_34_0.colorMode)
		elseif arg_34_0.refreshStatus_ == 2 then
			local var_35_1 = var_0_4.arenaRefreshCost

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("ARENA_RESET_ALERT"), var_35_1), function()
				if var_35_1 > arg_34_0.player_.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_39_0 = {}

						var_39_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_39_0)
					end, nil, nil, arg_34_0.colorMode)
				else
					arg_34_0.arena_:resetTimer()
				end
			end, nil, 0, arg_34_0.colorMode)
		else
			if arg_34_0.arena_:getRank() == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ARENA_FIRST_TIPS2")
				})
			end

			arg_34_0.arena_:refreshEnemies()
		end
	end)
	xyd.nodeEventSample(arg_34_0.rule_btn, nil, function(arg_40_0)
		xyd.playButtonSound()

		if arg_34_0.modeType > 0 then
			xyd.WindowManager.get():openWindow("arena_mode_rule", {
				rank = arg_34_0.arena_.mRank,
				modeType = arg_34_0.modeType
			})
		else
			local var_40_0 = {
				bestRank = arg_34_0.arena_:getBestRank(),
				rank = arg_34_0.arena_:getRank()
			}

			xyd.WindowManager.get():openWindow("arena_rule", var_40_0)
		end
	end)
	xyd.nodeEventSample(arg_34_0.rank_btn, nil, function(arg_41_0)
		xyd.playButtonSound()

		local var_41_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

		var_41_0:resetSpecialSubList(xyd.RankType.PK, xyd.SubRankType.ARENA_MODE_RANK_INFO, arg_34_0.isShowArenaMode, 2)
		var_41_0:loadRankList({
			xyd.SubRankType.ARENA_RANK
		}, true, function(arg_42_0, arg_42_1)
			if arg_42_0 == xyd.error.OK then
				local var_42_0 = {
					rank_type = xyd.RankType.PK,
					sub_type = xyd.SubRankType.ARENA_RANK,
					rankData = var_41_0:getRankList()
				}

				xyd.WindowManager.get():openWindow("new_rank_list", var_42_0)
			end
		end)
	end)
	xyd.nodeEventSample(arg_34_0:nodeByName("record_button"), nil, function(arg_43_0)
		xyd.playButtonSound()
		xyd.Backend.get():request(xyd.mid.LOAD_ARENA_FIGHT_RECORDS, {}, function(arg_44_0, arg_44_1)
			local var_44_0 = {
				records = arg_44_1.records
			}

			xyd.WindowManager.get():openWindow("new_arena_record", var_44_0)
		end)
	end)
	xyd.nodeEventSample(arg_34_0.award_btn, nil, function(arg_45_0)
		xyd.playButtonSound()
		xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
			xyd.WindowManager.get():openWindow("shop", {
				shop_type = xyd.ShopType.ARENA
			})
		end)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_34_0):addEventListener(xyd.event.ARENA_DEFENSE_UPDATE, function(arg_47_0)
		if arg_47_0.params.defenseHeroes then
			arg_34_0.arena_:saveArenaDefenderData(arg_47_0.params)

			arg_34_0.arena_.setFormationTime = xyd.ServerTime.get():getServerTime()

			arg_34_0:loadHeroListView()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_34_0):addEventListener(xyd.event.ARENA_ENEMY_UPDATE, function(arg_48_0)
		arg_34_0:updateEnemyListView()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_34_0):addEventListener(xyd.event.ARENA_TICKET_UPDATE, function(arg_49_0)
		arg_34_0:refreshTicket(arg_49_0.params)
	end)

	local var_34_0 = {
		showLevel = true,
		is_new = true,
		avatar_id = arg_34_0.player_:getMyCurrentAvatarID(),
		avatar_frame_id = arg_34_0.player_.avatarFrame,
		level = arg_34_0.player_.lev,
		conquerLev = arg_34_0.player_.conquerLev,
		conquerLoopID = arg_34_0.player_.conquerLoopID
	}

	arg_34_0:nodeByName("info_container"):getChildByName("avatar_panel"):removeAllChildren()
	xyd.setPlayerAvatar(arg_34_0:nodeByName("info_container"):getChildByName("avatar_panel"), var_34_0)

	if not arg_34_0.npc then
		local var_34_1 = var_0_4:getValue("arena_hero_id")
		local var_34_2 = var_0_4:getValue("arena_first_hero_model")
		local var_34_3 = var_0_4:getValue("arena_hero_scaling")

		arg_34_0:nodeByName("content"):setString(var_0_3:translation("ARENA_FIRST_TIPS1"))

		arg_34_0.npc = xyd.HeroAnimation.new(var_34_1, var_34_2, var_34_3, {})

		if arg_34_0.npc then
			arg_34_0.npc:idle()
		end

		arg_34_0.npc:addTo(arg_34_0:nodeByName("enemy_container"))
		arg_34_0.npc:pos(408, 4)
		arg_34_0.npc:setTouchEnabled(true)
		arg_34_0.npc:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_50_0)
			if arg_34_0.npcAction then
				return
			end

			if arg_50_0.name == "ended" then
				arg_34_0.npcAction = true

				arg_34_0.npc:win(false, function()
					arg_34_0.npcAction = false

					arg_34_0.npc:idle()
				end)
			end

			return true
		end)
	end
end

function var_0_0.showModeScheduler(arg_52_0)
	arg_52_0:nodeByName("label_mode_name"):setString(var_0_3:translation("ARENA_REPORT_DESC"))
	xyd.nodeEventSample(arg_52_0.scheduleBtn, nil, function(arg_53_0)
		arg_52_0.arena_:loadModeSchedule(function(arg_54_0)
			xyd.WindowManager.get():openWindow("arena_mode_schedule", {
				infos = arg_54_0
			})
		end)
	end)
end

function var_0_0.initArenaMode(arg_55_0)
	local var_55_0 = arg_55_0.arena_:getMDefenseFormation()

	arg_55_0.mDefenseHeroes = var_55_0.heros
	arg_55_0.mPetId = var_55_0.petId

	arg_55_0.changeModeBtn:setVisible(true)
	xyd.nodeEventSample(arg_55_0.changeModeBtn, nil, function(arg_56_0)
		if arg_55_0.modeType > 0 then
			arg_55_0.modeType = 0
			arg_55_0.arena_.windowIsMode = nil
		else
			arg_55_0.modeType = arg_55_0.arena_.modeType
			arg_55_0.arena_.windowIsMode = true
		end

		arg_55_0:updateMode()
	end)
	xyd.nodeEventSample(arg_55_0.mRefreshContainer:getChildByName("change_button"), nil, function(arg_57_0)
		xyd.playButtonSound()

		if arg_55_0.mRefreshStatus_ == 1 then
			local var_57_0 = xyd.tables.refreshCost:buyArenaCost(arg_55_0.arena_.mBuyNum + 1)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_3:translation("ARENA_BUY_TIMES1"), arg_55_0.arena_.mBuyNum + 1),
				string.format(var_0_3:translation("ARENA_BUY_TIMES2"), var_57_0)
			}, function()
				if var_57_0 > arg_55_0.player_.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_59_0 = {}

						var_59_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_59_0)
					end, nil, nil, arg_55_0.colorMode)
				else
					arg_55_0.arena_:buyModeTicket()
				end
			end, nil, 0, arg_55_0.colorMode)
		elseif arg_55_0.mRefreshStatus_ == 2 then
			local var_57_1 = var_0_4.arenaRefreshCost

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("ARENA_RESET_ALERT"), var_57_1), function()
				if var_57_1 > arg_55_0.player_.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_61_0 = {}

						var_61_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_61_0)
					end, nil, nil, arg_55_0.colorMode)
				else
					arg_55_0.arena_:resetModeTime()
				end
			end, nil, 0, arg_55_0.colorMode)
		else
			if arg_55_0.arena_.mRank == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("ARENA_FIRST_TIPS2")
				})
			end

			arg_55_0.arena_:refreshModeEnemies()
		end
	end)
	arg_55_0:addMMatchTimer()

	if arg_55_0.arena_.windowIsMode then
		arg_55_0.modeType = arg_55_0.arena_.modeType

		arg_55_0:updateMode()
	end
end

function var_0_0.updateMode(arg_62_0)
	arg_62_0:nodeByName("label_mode_name"):setString(arg_62_0.modeType > 0 and var_0_5:title(arg_62_0.arena_.modeType) or var_0_3:translation("ARENA_REPORT_DESC"))
	arg_62_0:updateHeroListView()
	arg_62_0:updateRank()
	arg_62_0:updateEnemyListView()

	if arg_62_0.modeType > 0 then
		arg_62_0.refreshContainer:setVisible(false)
		arg_62_0.mRefreshContainer:setVisible(true)
		arg_62_0.adjustLabel:setVisible(false)
	else
		arg_62_0.refreshContainer:setVisible(true)
		arg_62_0.mRefreshContainer:setVisible(false)

		if arg_62_0.countDownOn then
			arg_62_0.adjustLabel:setVisible(true)
		end
	end
end

function var_0_0.setDefenseHeroes(arg_63_0)
	local var_63_0 = {}
	local var_63_1 = {}

	if arg_63_0.defenseHeroes and next(arg_63_0.defenseHeroes) then
		for iter_63_0, iter_63_1 in pairs(arg_63_0.defenseHeroes) do
			table.insert(var_63_0, iter_63_1:getHeroID())
		end
	end

	for iter_63_2, iter_63_3 in pairs(var_63_0) do
		table.insert(var_63_1, arg_63_0.player_:getHeroByID(iter_63_3))
	end

	params = {
		type = xyd.SelectTeamType.ARENA_DEFENSE,
		selected = var_63_0,
		preHeros = var_63_1
	}

	if arg_63_0.petId then
		params.prePet = {}

		table.insert(params.prePet, arg_63_0.player_:getPetByID(arg_63_0.petId))

		params.petSelect = {}

		table.insert(params.petSelect, arg_63_0.player_:getPetByID(arg_63_0.petId))
	end

	if arg_63_0.arena_.isSealHeroOpen then
		params.sealHeroID = arg_63_0.arena_.sealHeroID
	end

	xyd.WindowManager.get():openWindow("arena_select_team", params)
end

function var_0_0.setMDefenseHeroes(arg_64_0)
	local var_64_0 = {}
	local var_64_1 = {}

	if arg_64_0.mDefenseHeroes and next(arg_64_0.mDefenseHeroes) then
		for iter_64_0, iter_64_1 in pairs(arg_64_0.mDefenseHeroes) do
			table.insert(var_64_0, iter_64_1:getHeroID())
		end
	end

	for iter_64_2, iter_64_3 in pairs(var_64_0) do
		table.insert(var_64_1, arg_64_0.player_:getHeroByID(iter_64_3))
	end

	params = {
		type = xyd.SelectTeamType.ARENA_MODE_DEFENSE,
		selected = var_64_0,
		preHeros = var_64_1,
		banPet = xyd.tables.arenaMode:isPet(arg_64_0.modeType) == 0
	}

	if arg_64_0.arena_.modeType == xyd.ArenaModeType.SINGLE then
		params.selectSpType = xyd.SelectSpType.SINGLE
		params.noPreset = true
	elseif arg_64_0.modeType == xyd.ArenaModeType.TRIPLE then
		params.selectSpType = xyd.SelectSpType.TRIPLE
		params.noPreset = true
	elseif arg_64_0.modeType == xyd.ArenaModeType.LEAD then
		params.selectSpType = xyd.SelectSpType.LEAD
	elseif arg_64_0.modeType == xyd.ArenaModeType.BAN then
		params.selectSpType = xyd.SelectSpType.BAN
		params.bannedHeros = xyd.tables.arenaMode:banList(arg_64_0.arena_.modeType)
	elseif arg_64_0.modeType == xyd.ArenaModeType.PHANTOM then
		params.selectSpType = xyd.SelectSpType.PHANTOM
		params.noPreset = true
		params.bannedHeros = xyd.tables.arenaMode:banList(arg_64_0.arena_.modeType)
	elseif arg_64_0.modeType == xyd.ArenaModeType.CAMP then
		if arg_64_0.arena_.subMode > 0 then
			params.selectSpType = arg_64_0.arena_.subMode
		else
			params.selectSpType = xyd.SelectSpType.CAMP
		end

		params.noPreset = true
		params.bannedHeros = xyd.tables.arenaMode:banList(arg_64_0.arena_.modeType)
	end

	if arg_64_0.mPetId then
		params.prePet = {}

		table.insert(params.prePet, arg_64_0.player_:getPetByID(arg_64_0.mPetId))

		params.petSelect = {}

		table.insert(params.petSelect, arg_64_0.player_:getPetByID(arg_64_0.mPetId))
	end

	if arg_64_0.arena_.isSealHeroOpen then
		params.sealHeroID = arg_64_0.arena_.sealHeroID
	end

	xyd.WindowManager.get():openWindow("arena_select_team", params)
end

function var_0_0.updateRank(arg_65_0, arg_65_1)
	arg_65_1 = arg_65_1 or arg_65_0.modeType > 0 and arg_65_0.arena_.mRank or arg_65_0.arena_:getRank()

	if arg_65_0.rankLabel then
		arg_65_0.rankLabel:removeAllChildren()
		arg_65_0.rankLabel:removeSelf()

		arg_65_0.rankLabel = nil
	end

	local var_65_0, var_65_1 = arg_65_0:nodeByName("rank_pos"):getPosition()

	arg_65_0.rankLabel = xyd.colorNumLabel(arg_65_1, "yellow1")

	arg_65_0.rankLabel:addTo(arg_65_0)
	arg_65_0.rankLabel:setPosition(var_65_0, var_65_1)
	arg_65_0.rankLabel:setAnchorPoint(cc.p(1, 0))
end

function var_0_0.updateAdjustLabel(arg_66_0, arg_66_1)
	if arg_66_1 > 0 and arg_66_0.modeType == 0 then
		arg_66_0.adjustLabel:setVisible(true)
		arg_66_0.adjustLabel:setString(var_0_3:translation("ARENA_ADJUST_LBL") .. arg_66_1 .. "s")
	else
		arg_66_0.adjustLabel:setVisible(false)

		arg_66_0.adjustCountDownOn = false
	end
end

function var_0_0.soundButtonClick(arg_67_0, arg_67_1, arg_67_2)
	var_0_0.super.soundButtonClick(arg_67_0, arg_67_1, arg_67_2)

	if arg_67_2 == ccui.TouchEventType.ended then
		local var_67_0 = arg_67_1:getName()
	end
end

function var_0_0.loadHeroListView(arg_68_0)
	local var_68_0 = arg_68_0.arena_:getDefenseFormation()

	arg_68_0.defenseHeroes = var_68_0.heros
	arg_68_0.petId = var_68_0.petId

	arg_68_0:addAdjustCDTimer()
	arg_68_0:updateHeroListView()
end

function var_0_0.loadMHeroListView(arg_69_0)
	local var_69_0 = arg_69_0.arena_:getMDefenseFormation()

	arg_69_0.mDefenseHeroes = var_69_0.heros
	arg_69_0.mPetId = var_69_0.petId

	arg_69_0:addAdjustCDTimer()
	arg_69_0:updateHeroListView()
end

function var_0_0.updateHeroListView(arg_70_0)
	local var_70_0 = arg_70_0.modeType > 0 and arg_70_0.mDefenseHeroes or arg_70_0.defenseHeroes
	local var_70_1 = 0

	for iter_70_0, iter_70_1 in pairs(var_70_0) do
		var_70_1 = var_70_1 + iter_70_1:getZhandouli()
	end

	local var_70_2 = var_0_5:heroNum(arg_70_0.modeType)
	local var_70_3

	if arg_70_0.modeType > 0 then
		if arg_70_0.mPetId and arg_70_0.mPetId ~= 0 then
			var_70_3 = arg_70_0.player_:getPetByID(arg_70_0.mPetId)
			var_70_1 = var_70_1 + var_70_3:getZhandouli()
		end
	elseif arg_70_0.petId and arg_70_0.petId ~= 0 then
		var_70_3 = arg_70_0.player_:getPetByID(arg_70_0.petId)
		var_70_1 = var_70_1 + var_70_3:getZhandouli()
	end

	if arg_70_0.modeType == xyd.ArenaModeType.PHANTOM then
		var_70_1 = var_70_1 * 5
	end

	arg_70_0:nodeByName("force_val"):setString(var_70_1)

	if arg_70_0.modeType == xyd.ArenaModeType.SINGLE then
		for iter_70_2 = 1, 5 do
			local var_70_4 = arg_70_0:nodeByName("hero" .. iter_70_2)

			if iter_70_2 == 3 then
				arg_70_0:initHeroCell(var_70_4, 1)
			else
				arg_70_0:initHeroCell(var_70_4, nil, {
					is_lock = true
				})
			end
		end
	elseif arg_70_0.modeType == xyd.ArenaModeType.TRIPLE then
		for iter_70_3 = 2, 4 do
			arg_70_0:initHeroCell(arg_70_0:nodeByName("hero" .. iter_70_3), iter_70_3 - 1)
		end

		arg_70_0:initHeroCell(arg_70_0:nodeByName("hero1"), nil, {
			is_lock = true
		})
		arg_70_0:initHeroCell(arg_70_0:nodeByName("hero5"), nil, {
			is_lock = true
		})
	elseif arg_70_0.modeType == xyd.ArenaModeType.PHANTOM then
		for iter_70_4 = 1, 5 do
			arg_70_0:initHeroCell(arg_70_0:nodeByName("hero" .. iter_70_4), 1)
		end
	else
		for iter_70_5 = 1, 5 do
			arg_70_0:initHeroCell(arg_70_0:nodeByName("hero" .. iter_70_5), iter_70_5)
		end
	end

	arg_70_0:initPetCell(arg_70_0:nodeByName("pet"), var_70_3, arg_70_0:isPet())
end

function var_0_0.isPet(arg_71_0)
	if arg_71_0.modeType > 0 then
		return var_0_5:isPet(arg_71_0.modeType) > 0
	end

	if arg_71_0.player_:isFuncOpen(xyd.FunctionID.ID_PET) == true then
		return true
	end
end

function var_0_0.updateEnemyListView(arg_72_0)
	if arg_72_0.arena_ == nil then
		return
	end

	arg_72_0.enemies = arg_72_0.modeType > 0 and arg_72_0.arena_.mEnemies or arg_72_0.arena_:getEnemies()

	arg_72_0:nodeByName("enemy_pos1"):removeAllChildren()
	arg_72_0:nodeByName("enemy_pos2"):removeAllChildren()
	arg_72_0:nodeByName("enemy_pos3"):removeAllChildren()

	if #arg_72_0.enemies == 0 then
		arg_72_0:nodeByName("talk_container"):setVisible(true)
		arg_72_0.npc:setVisible(true)
		arg_72_0:nodeByName("shadow"):setVisible(true)

		return
	else
		arg_72_0:nodeByName("talk_container"):setVisible(false)
		arg_72_0.npc:setVisible(false)
		arg_72_0:nodeByName("shadow"):setVisible(false)
	end

	for iter_72_0 = 1, var_0_10 do
		local var_72_0 = display.newNode()

		arg_72_0:initEnemyCell(var_72_0, iter_72_0)
		var_72_0:setAnchorPoint(cc.p(0, 0))
		var_72_0:addTo(arg_72_0:nodeByName("enemy_pos" .. iter_72_0))
	end
end

function var_0_0.scrollListener(arg_73_0, arg_73_1)
	return false
end

function var_0_0.playGuide(arg_74_0)
	local var_74_0 = xyd.StoryData.get():getGuideID()

	if var_74_0 == xyd.GuideStoryType.GUIDE_ARENA_START then
		local var_74_1 = arg_74_0.guideFightBtn

		if not var_74_1 then
			return
		end

		local var_74_2 = var_74_1:getPositionX()
		local var_74_3 = var_74_1:getPositionY()
		local var_74_4 = var_74_1:getContentSize().width
		local var_74_5 = var_74_1:getContentSize().height
		local var_74_6 = display.newNode()

		var_74_6:setPosition(var_74_2, var_74_3)

		local var_74_7 = import("app.windows.GuideHand").new()

		var_74_6:addChild(var_74_7)
		var_74_7:setPosition(0, 0)

		local var_74_8 = xyd.tables.guide:desc(var_74_0)

		var_74_7:setText(var_74_8, cc.p(-80, 40), 50, 30)
		var_74_6:addTo(arg_74_0.guideFightBtn:getParent())

		arg_74_0.guideFightHand = var_74_6

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_ARENA_END, true)
		xyd.StoryData.get():persist()
	end
end

function var_0_0.challengeTimeDeal(arg_75_0)
	local var_75_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_75_0 > var_0_4.arenaTime1 and var_75_0 < var_0_4.arenaTime2 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("ARENA_BATTLE_LIMIT")
		})

		return false
	end

	return true
end

return var_0_0
