local var_0_0 = class("RegionArenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = import("framework.scheduler")
local var_0_6 = "skeletons/ui_effect/effect_kfjjc/effect_kfjjc2"
local var_0_7 = 6
local var_0_8 = 3
local var_0_9 = 72000

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
	arg_1_0.defenceFormation = arg_1_0.regionArena:getDefenceFormation() or {}
	arg_1_0.pet_id = arg_1_0.regionArena:getPetID() or 0
	arg_1_0.defenseHeroes = {}
	arg_1_0.mode = xyd.RegionArenaMode.ARENA

	if arg_1_2 and arg_1_2.mode then
		arg_1_0.mode = arg_1_2.mode
	end

	arg_1_0.pet = nil

	if arg_1_2 and arg_1_2.is_playoff then
		arg_1_0.is_playoff = arg_1_2.is_playoff
		arg_1_0.is_playoff_ = true
	end

	if arg_1_2 and arg_1_2.is_playoff_ then
		arg_1_0.is_playoff_ = arg_1_2.is_playoff_
	end

	arg_1_0.missions = arg_1_0.regionArena.missions
	arg_1_0.missionTime = arg_1_0.regionArena.missionTime
	arg_1_0.exchangeTimes = arg_1_0.regionArena.exchangeTimes
	arg_1_0.awards = arg_1_0.regionArena.awards
	arg_1_0.missionFirstInit = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:translation()
	arg_2_0:addTopSidebar({
		isEcoBar = 0
	})
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.translation(arg_4_0)
	local var_4_0 = var_0_1:translation("REGION_ARENA_TIP3")
	local var_4_1 = var_0_1:translation("REGION_ARENA_TIP4")

	arg_4_0:nodeByName("defend_txt"):setString(var_4_0)
	arg_4_0:nodeByName("force_txt"):setString(var_4_1)
	arg_4_0:nodeByName("text_adjust"):setString(var_0_1:translation("REGION_ARENA_TEXT_1"))
	arg_4_0:nodeByName("text_pk"):setString(var_0_1:translation("REGION_ARENA_TEXT_2"))
	arg_4_0:nodeByName("text_mission"):setString(var_0_1:translation("REGION_ARENA_TEXT_3"))
	arg_4_0:nodeByName("text_game"):setString(var_0_1:translation("REGION_ARENA_TEXT_4"))
	arg_4_0:nodeByName("text_rule"):setString(var_0_1:translation("REGION_ARENA_TEXT_5"))
	arg_4_0:nodeByName("text_score"):setString(var_0_1:translation("REGION_ARENA_TEXT_6"))
	arg_4_0:nodeByName("text_rank"):setString(var_0_1:translation("REGION_ARENA_TEXT_7"))
	arg_4_0:nodeByName("text_reward"):setString(var_0_1:translation("REGION_ARENA_TEXT_8"))
	arg_4_0:nodeByName("text_match"):setString(var_0_1:translation("REGION_ARENA_TEXT_9"))
end

function var_0_0.layout(arg_5_0)
	local function var_5_0(arg_6_0)
		local var_6_0 = {}

		var_6_0.btn_pk = "container"
		var_6_0.btn_mission = "container_mission"
		var_6_0.btn_game = "container_game"

		if arg_5_0.is_playoff and arg_6_0 ~= "btn_game" then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("REGION_ARENA_NOT_OPEN")
			})

			return
		end

		for iter_6_0, iter_6_1 in pairs(var_6_0) do
			if iter_6_0 == arg_6_0 then
				arg_5_0:nodeByName(iter_6_0):setBrightStyle(ccui.BrightStyle.highlight)
				arg_5_0:nodeByName(iter_6_0):setTouchEnabled(false)
				arg_5_0:nodeByName(iter_6_1):setVisible(true)
			else
				arg_5_0:nodeByName(iter_6_0):setBrightStyle(ccui.BrightStyle.normal)
				arg_5_0:nodeByName(iter_6_0):setTouchEnabled(true)
				arg_5_0:nodeByName(iter_6_1):setVisible(false)
			end
		end

		if xyd.WindowManager.get():getWindow("playoffs_schedule_main") then
			xyd.WindowManager.get():closeWindow("playoffs_schedule_main")
		end

		if arg_6_0 == "btn_mission" then
			arg_5_0:nodeByName("panel_coin"):setVisible(true)

			local var_6_1 = arg_5_0:nodeByName("container_mission"):getChildByName("mission_layout"):getChildByName("container")

			arg_5_0.missionContainer:setVisible(true)
			arg_5_0.shopContainer:setVisible(false)
			var_6_1:getChildByName("btn_exchange"):setVisible(true)
			var_6_1:getChildByName("btn_return"):setVisible(false)
			var_6_1:getChildByName("title_bg"):getChildByName("title"):setString(var_0_1:translation("REGION_ARENA_MISSION_TITLE1"))
		else
			arg_5_0:nodeByName("panel_coin"):setVisible(false)
		end
	end

	if not arg_5_0.is_playoff_ then
		arg_5_0:initPKLayout()
	else
		var_5_0("btn_game")
		xyd.WindowManager.get():openWindow("playoffs_schedule_main")
	end

	arg_5_0:nodeByName("btn_pk"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			var_5_0("btn_pk")
		end
	end)
	arg_5_0:nodeByName("btn_mission"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.regionArena:getRegionArenaInfo(function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_5_0.missions = arg_9_1.missions

					if arg_5_0.missionFirstInit then
						arg_5_0:initMissionLayout()
						arg_5_0:updateKingCoin()

						arg_5_0.missionFirstInit = false
					end

					var_5_0("btn_mission")
					arg_5_0:updateMissionItem()
				end
			end)
		end
	end)
	arg_5_0:nodeByName("btn_game"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_5_0.PlayoffsModel:getBasePlayers(function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK and arg_11_1.playoff_info.is_open == 1 then
					var_5_0("btn_game")
					xyd.WindowManager.get():openWindow("playoffs_schedule_main")
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GAME_NOT_OPEN")
					})
				end
			end)
		end
	end)
	arg_5_0:nodeByName("panel_coin"):setVisible(false)
	arg_5_0:nodeByName("container_mission"):setVisible(false)
	arg_5_0:nodeByName("container_game"):setVisible(false)
	arg_5_0:nodeByName("panel_coin"):setVisible(false)

	if not arg_5_0.is_playoff_ then
		arg_5_0:nodeByName("btn_pk"):setTouchEnabled(false)
		arg_5_0:nodeByName("btn_pk"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_5_0:nodeByName("btn_game"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_0.initPKLayout(arg_12_0)
	arg_12_0:showDefenceFormation()
	arg_12_0:showWndByMode()
	arg_12_0:showForce()
	arg_12_0:updateLevelPanel()
	arg_12_0:nodeByName("panel_coin"):setVisible(true)
	arg_12_0:nodeByName("adjust_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_13_0 = {}
			local var_13_1 = arg_12_0.defenseHeroes

			if arg_12_0.defenseHeroes and next(arg_12_0.defenseHeroes) then
				for iter_13_0, iter_13_1 in pairs(arg_12_0.defenseHeroes) do
					table.insert(var_13_0, iter_13_1:getTableID())
				end
			end

			local var_13_2 = arg_12_0.selfPlayer:getPetByID(arg_12_0.pet_id)
			local var_13_3 = {
				var_13_2
			}
			local var_13_4 = arg_12_0.regionArena.awards

			params = {
				type = xyd.SelectTeamType.REGION_ARENA_DEFENSE,
				selected = var_13_0,
				preHeros = var_13_1,
				prePet = var_13_3,
				awards = var_13_4
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, params)
		end
	end)
	arg_12_0:nodeByName("match_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("finding_enemy")
			arg_12_0.regionArena:matchEnemy(arg_12_0.mode, function(arg_15_0, arg_15_1)
				var_0_5.performWithDelayGlobal(function()
					if xyd.WindowManager.get():getWindow("finding_enemy") then
						xyd.WindowManager.get():closeWindow("finding_enemy")
					end

					if arg_15_0 == xyd.error.OK then
						arg_12_0.enemyHeros = {}

						for iter_16_0, iter_16_1 in ipairs(arg_15_1.heros) do
							local var_16_0 = var_0_2.new()

							var_16_0:populate(iter_16_1)
							table.insert(arg_12_0.enemyHeros, var_16_0)
						end

						local var_16_1 = {}

						var_16_1.delay = 0.8
						var_16_1.pet_id = arg_15_1.pet_id
						var_16_1.pet_info = arg_15_1.pet_info
						var_16_1.avatar = arg_15_1.avatar_id
						var_16_1.avatarFrame = arg_15_1.avatar_frame
						var_16_1.winTimes = arg_15_1.win_times
						var_16_1.totalFight = arg_15_1.total_fight
						var_16_1.playerName = arg_15_1.player_name
						var_16_1.serverName = arg_15_1.region_name
						var_16_1.guildName = arg_15_1.guild_name
						var_16_1.playerID = arg_15_1.player_id
						var_16_1.heros = arg_12_0.enemyHeros
						var_16_1.mode = arg_12_0.mode
						var_16_1.selfRegionName = arg_15_1.self_region_name
						var_16_1.enemyRegion = arg_15_1.region

						xyd.WindowManager.get():openWindow("found_enemy", var_16_1)
					end
				end, 1)
			end)
		end
	end)
	arg_12_0:nodeByName("btn_change"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_12_0:showWndByMode(xyd.RegionArenaMode.ARENA + xyd.RegionArenaMode.PRACTISE - arg_12_0.mode)
		end
	end)
	arg_12_0:nodeByName("score_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_12_0.regionArena:getBattleScoresInfo(function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					local var_19_0 = {
						herosInfo = arg_19_1.partner_info,
						totalFight = arg_19_1.arena_info.total_fight,
						winFight = arg_19_1.arena_info.win_times,
						kingPoint = arg_19_1.arena_info.point
					}

					arg_12_0.regionArena:getFightReports(function(arg_20_0, arg_20_1)
						if arg_20_0 == xyd.error.OK then
							var_19_0.reports = arg_20_1.records

							xyd.WindowManager.get():openWindow("battle_scores", var_19_0)
						end
					end)
				end
			end)
		end
	end)
	arg_12_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_21_0, arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_21_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

			var_21_0:loadRankList({
				xyd.SubRankType.REGION_ARENA_RANK
			}, true, function(arg_22_0, arg_22_1)
				if arg_22_0 == xyd.error.OK then
					local var_22_0 = {
						rank_type = xyd.RankType.PK,
						sub_type = xyd.SubRankType.REGION_ARENA_RANK,
						rankData = var_21_0:getRankList()
					}

					xyd.WindowManager.get():openWindow("new_rank_list", var_22_0)
				end
			end)
		end
	end)
	arg_12_0:nodeByName("reward_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		xyd.buttonScaleAnim(arg_23_0, arg_23_1)

		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.REGION,
					top_status = xyd.MainSceneTop.CLOSE
				})
			end)
		end
	end)
	arg_12_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		xyd.buttonScaleAnim(arg_25_0, arg_25_1)

		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_25_0 = arg_12_0.regionArena:getStar()
			local var_25_1 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(var_25_0)
			local var_25_2 = {
				rank = var_25_1
			}

			xyd.WindowManager.get():openWindow("region_arena_rule", var_25_2)
		end
	end)
	arg_12_0:nodeByName("chest"):setTouchEnabled(true)
	arg_12_0:nodeByName("chest"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			return true
		elseif arg_26_0.name == "ended" then
			local var_26_0 = {
				count = arg_12_0.regionArena:getSeasonCount()
			}

			xyd.WindowManager.get():openWindow("season_award", var_26_0)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_12_0):addEventListener(xyd.event.REGION_ARENA_DEFENSE_UPDATE, function(arg_27_0)
		if arg_27_0.params.defenseHeroes then
			arg_12_0.defenseHeroes = arg_27_0.params.defenseHeroes
			arg_12_0.defenceFormation = {}
			arg_12_0.pet_id = arg_27_0.params.pet_id

			for iter_27_0, iter_27_1 in ipairs(arg_12_0.defenseHeroes) do
				table.insert(arg_12_0.defenceFormation, iter_27_1:getTableID())
			end

			local var_27_0 = {
				heros = arg_12_0.defenceFormation,
				pet_id = arg_12_0.pet_id
			}

			arg_12_0.regionArena:saveArenaDefendceFormation(var_27_0, function(arg_28_0)
				if arg_28_0 == xyd.error.OK then
					arg_12_0:showDefenceFormation()
					arg_12_0:showForce()
				end
			end)
		end
	end)
end

function var_0_0.initMissionLayout(arg_29_0)
	local var_29_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/mission.csb")

	var_29_0:addTo(arg_29_0:nodeByName("container_mission"))
	var_29_0:setPosition(cc.p(0, 0))
	var_29_0:setAnchorPoint(cc.p(0, 0))
	var_29_0:setName("mission_layout")

	local var_29_1 = var_29_0:getChildByName("container")

	var_29_1:getChildByName("title_bg"):getChildByName("title"):setString(var_0_1:translation("REGION_ARENA_MISSION_TITLE1"))
	var_29_1:getChildByName("text_mid1"):setString(var_0_1:translation("REGION_ARENA_MISSION_MID1"))
	var_29_1:getChildByName("text_mid2"):setString(var_0_1:translation("REGION_ARENA_MISSION_MID2"))
	var_29_1:getChildByName("text_mid3"):setString(var_0_1:translation("REGION_ARENA_MISSION_MID3"))

	arg_29_0.missionContainer = var_29_1:getChildByName("detail_container"):getChildByName("mission_container")
	arg_29_0.shopContainer = var_29_1:getChildByName("detail_container"):getChildByName("shop_container")

	arg_29_0:updateShopContainer()
	arg_29_0.shopContainer:setVisible(false)
	var_29_1:getChildByName("btn_rule"):getChildByName("text_rule"):setString(var_0_1:translation("REGION_ARENA_TEXT_5"))
	var_29_1:getChildByName("btn_rule"):addTouchEventListener(function(arg_30_0, arg_30_1)
		xyd.buttonScaleAnim(arg_30_0, arg_30_1)

		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("region_mission_rule")
		end
	end)
	var_29_1:getChildByName("btn_exchange"):getChildByName("text_exchange"):setString(var_0_1:translation("REGION_ARENA_TEXT_10"))
	var_29_1:getChildByName("btn_exchange"):addTouchEventListener(function(arg_31_0, arg_31_1)
		xyd.buttonScaleAnim(arg_31_0, arg_31_1)

		if arg_31_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_29_0.missionContainer:setVisible(false)
			arg_29_0.shopContainer:setVisible(true)
			var_29_1:getChildByName("btn_exchange"):setVisible(false)
			var_29_1:getChildByName("btn_return"):setVisible(true)
			var_29_1:getChildByName("title_bg"):getChildByName("title"):setString(var_0_1:translation("REGION_ARENA_MISSION_TITLE2"))
		end
	end)
	var_29_1:getChildByName("btn_buy_record"):getChildByName("text_buy_record"):setString(var_0_1:translation("REGION_ARENA_TEXT_11"))
	var_29_1:getChildByName("btn_buy_record"):addTouchEventListener(function(arg_32_0, arg_32_1)
		xyd.buttonScaleAnim(arg_32_0, arg_32_1)

		if arg_32_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("region_arena_buy_record")
		end
	end)
	var_29_1:getChildByName("btn_return"):getChildByName("text_return"):setString(var_0_1:translation("REGION_ARENA_TEXT_12"))
	var_29_1:getChildByName("btn_return"):addTouchEventListener(function(arg_33_0, arg_33_1)
		xyd.buttonScaleAnim(arg_33_0, arg_33_1)

		if arg_33_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_29_0.missionContainer:setVisible(true)
			arg_29_0.shopContainer:setVisible(false)
			var_29_1:getChildByName("btn_exchange"):setVisible(true)
			var_29_1:getChildByName("btn_return"):setVisible(false)
			var_29_1:getChildByName("title_bg"):getChildByName("title"):setString(var_0_1:translation("REGION_ARENA_MISSION_TITLE1"))
		end
	end)
end

function var_0_0.initGameLayout(arg_34_0)
	return
end

function var_0_0.updateLevelPanel(arg_35_0)
	local var_35_0 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_35_0.regionArena:getStar())

	if var_35_0 == xyd.tables.regionArenaLevel.level[#xyd.tables.regionArenaLevel.level] then
		arg_35_0:nodeByName("star_level"):setString(var_0_1:translation("REGION_ARENA_RULE6"))
	else
		arg_35_0:nodeByName("star_level"):setString("Lv." .. var_35_0)
	end

	arg_35_0:nodeByName("star_level"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_35_1 = arg_35_0.regionArena:getStar() - xyd.tables.regionArenaLevel:getStar(var_35_0 - 1)
	local var_35_2 = xyd.tables.regionArenaLevel:getLevelStarType()
	local var_35_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/level_frame.csb")

	var_35_3:addTo(arg_35_0:nodeByName("level_container"))

	local var_35_4 = var_35_3:getChildByName("container")
	local var_35_5 = var_35_4:getChildByName("icon_container")

	arg_35_0:setCutLevelIcon(var_35_0, var_35_5)

	for iter_35_0, iter_35_1 in pairs(var_35_2) do
		if xyd.tables.regionArenaLevel:getlevelStar(var_35_0) == iter_35_1 then
			var_35_4:getChildByName("lev_index" .. iter_35_1):setVisible(true)

			local var_35_6 = var_35_4:getChildByName("lev_index" .. iter_35_1)

			for iter_35_2 = 1, iter_35_1 do
				if iter_35_2 <= var_35_1 then
					var_35_6:getChildByName("stone_" .. iter_35_2):setVisible(true)
				else
					var_35_6:getChildByName("stone_" .. iter_35_2):setVisible(false)
				end
			end
		else
			var_35_4:getChildByName("lev_index" .. iter_35_1):setVisible(false)
		end
	end

	var_35_3:setTouchEnabled(true)
	var_35_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_36_0)
		if arg_36_0.name == "began" then
			if not xyd.WindowManager.get():getWindow("region_level_tip") then
				local var_36_0 = {
					kingLevel = var_35_0,
					rankPercent = arg_35_0.regionArena:getRankPercent()
				}
				local var_36_1 = xyd.WindowManager.get():openWindow("region_level_tip", var_36_0)
				local var_36_2 = arg_35_0:nodeByName("level_container"):getWidth()
				local var_36_3 = arg_35_0:nodeByName("level_container"):getHeight()
				local var_36_4, var_36_5 = arg_35_0:nodeByName("level_container"):getPosition()

				var_36_1:setPosition(var_36_4 - 140 - var_36_2, var_36_5 - 50)
			end

			return true
		elseif arg_36_0.name == "ended" and xyd.WindowManager.get():getWindow("region_level_tip") then
			xyd.WindowManager.get():closeWindow("region_level_tip")
		end
	end)
end

function var_0_0.setCutLevelIcon(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/main_wnd/level_icon/" .. arg_37_1 .. ".png")
	local var_37_1 = xyd.AssetLoader:get():loadSprite("windows/across_arena/across_arena/main_wnd/level_frame/mask.png")

	var_37_0:setAnchorPoint(cc.p(0, 0))
	var_37_1:setAnchorPoint(cc.p(0, 0))

	local var_37_2 = var_37_0:getWidth()

	var_37_1:setScale(var_37_2 / var_37_1:getWidth())
	var_37_1:setPosition(0, 0)

	local var_37_3 = cc.ClippingNode:create()

	var_37_3:setStencil(var_37_1)
	var_37_3:setInverted(true)
	var_37_3:setAlphaThreshold(0)
	var_37_3:addChild(var_37_0)
	var_37_3:addTo(arg_37_2)
end

function var_0_0.showWndByMode(arg_38_0, arg_38_1)
	local var_38_0 = var_0_1:translation("REGION_ARENA_TIP1")
	local var_38_1 = var_0_1:translation("REGION_ARENA_TIP2")

	if arg_38_1 and arg_38_1 ~= arg_38_0.mode or arg_38_0.mode == xyd.RegionArenaMode.ARENA then
		local var_38_2, var_38_3 = arg_38_0:nodeByName("tag_parctise"):getPosition()
		local var_38_4, var_38_5 = arg_38_0:nodeByName("tag_arena"):getPosition()

		arg_38_0:nodeByName("tag_arena"):setPosition(var_38_2, var_38_3)
		arg_38_0:nodeByName("tag_parctise"):setPosition(var_38_4, var_38_5)
	end

	if arg_38_1 then
		arg_38_0.mode = arg_38_1
	end

	if arg_38_0.mode == xyd.RegionArenaMode.ARENA then
		arg_38_0:nodeByName("tag_parctise"):setLocalZOrder(-2)
		arg_38_0:nodeByName("tag_parctise"):getChildByName("tag_shadow"):setVisible(true)
		arg_38_0:nodeByName("tag_arena"):setLocalZOrder(-1)
		arg_38_0:nodeByName("tag_arena"):getChildByName("tag_shadow"):setVisible(false)
	else
		arg_38_0:nodeByName("tag_arena"):setLocalZOrder(-2)
		arg_38_0:nodeByName("tag_arena"):getChildByName("tag_shadow"):setVisible(true)
		arg_38_0:nodeByName("tag_parctise"):setLocalZOrder(-1)
		arg_38_0:nodeByName("tag_parctise"):getChildByName("tag_shadow"):setVisible(false)
	end

	if arg_38_0.mode == xyd.RegionArenaMode.ARENA then
		arg_38_0:nodeByName("reward_txt"):setString(var_38_0)
		arg_38_0:nodeByName("chest"):setVisible(true)
	else
		arg_38_0:nodeByName("reward_txt"):setString(var_38_1)
		arg_38_0:nodeByName("chest"):setVisible(false)
	end
end

function var_0_0.showForce(arg_39_0)
	local var_39_0 = 0
	local var_39_1 = clone(arg_39_0.defenseHeroes)

	arg_39_0:formatRegionArenaHeros(var_39_1)

	for iter_39_0, iter_39_1 in pairs(var_39_1) do
		var_39_0 = var_39_0 + iter_39_1:getZhandouli()
	end

	if arg_39_0.pet_id ~= 0 and arg_39_0.pet then
		var_39_0 = var_39_0 + arg_39_0.pet:getZhandouli()
	end

	arg_39_0:nodeByName("force_num"):setString(var_39_0)
end

function var_0_0.showDefenceFormation(arg_40_0)
	arg_40_0.defenseHeroes = {}

	for iter_40_0 = 1, 5 do
		arg_40_0:nodeByName("hero" .. iter_40_0):getChildByName("node"):removeAllChildren()
	end

	arg_40_0:nodeByName("pet"):getChildByName("node"):removeAllChildren()
	arg_40_0:initAwards()

	for iter_40_1, iter_40_2 in ipairs(arg_40_0.defenceFormation) do
		local var_40_0 = arg_40_0:initDefenceHero(iter_40_2)

		table.insert(arg_40_0.defenseHeroes, var_40_0)
	end

	if arg_40_0.pet_id ~= 0 then
		local var_40_1 = arg_40_0:initDefencePet()

		arg_40_0.pet = arg_40_0:formatRegionArenaPets(var_40_1)

		arg_40_0:nodeByName("pet"):getChildByName("name"):setString(var_40_1:getName())

		local var_40_2 = arg_40_0:initPetCell(arg_40_0.pet, arg_40_0:nodeByName("pet"):getContentSize())

		var_40_2:addTo(arg_40_0:nodeByName("pet"):getChildByName("node"))
		var_40_2:setName("card")
	else
		arg_40_0:nodeByName("pet"):getChildByName("name"):setString("")
		arg_40_0:nodeByName("pet"):getChildByName("node"):removeAllChildren()
	end

	local var_40_3 = clone(arg_40_0.defenseHeroes)

	arg_40_0:formatRegionArenaHeros(var_40_3)

	for iter_40_3, iter_40_4 in ipairs(var_40_3) do
		arg_40_0:nodeByName("hero" .. iter_40_3):getChildByName("name"):setString(iter_40_4:getName())

		local var_40_4 = arg_40_0:initHeroCell(iter_40_4, arg_40_0:nodeByName("hero" .. iter_40_3):getContentSize(), iter_40_3 % 3 + 1)

		var_40_4:addTo(arg_40_0:nodeByName("hero" .. iter_40_3):getChildByName("node"))
		var_40_4:setName("card")
	end
end

function var_0_0.formatRegionArenaPets(arg_41_0, arg_41_1)
	local var_41_0 = var_0_3.new()
	local var_41_1 = arg_41_1:toParams()

	if arg_41_1:isHaveAwakenItem() and not arg_41_1:isAwaken() then
		var_41_1.skills = {
			90,
			90,
			70,
			50,
			0
		}
		var_41_1.equips = {
			1,
			1,
			1
		}
	elseif arg_41_1:isAwaken() then
		var_41_1.skills = {
			90,
			90,
			70,
			50,
			30
		}
		var_41_1.equips = {
			1,
			1,
			1
		}
	else
		var_41_1.skills = {
			90,
			90,
			70,
			50,
			0
		}
		var_41_1.equips = {
			0,
			1,
			1
		}
	end

	var_41_1.color = 14
	var_41_1.lev = 90

	var_41_0:populate(var_41_1)

	return var_41_0
end

function var_0_0.initAwards(arg_42_0)
	local var_42_0 = arg_42_0.regionArena.awards

	arg_42_0.awards = {}

	for iter_42_0, iter_42_1 in pairs(var_42_0) do
		arg_42_0.awards[iter_42_1.table_id] = iter_42_1
	end
end

function var_0_0.initDefenceHero(arg_43_0, arg_43_1)
	local var_43_0 = true
	local var_43_1 = arg_43_0.selfPlayer:getHeroByTableID(arg_43_1)

	if not var_43_1 then
		tmpTableID = xyd.tables.hero:afterAwaken(arg_43_1)

		if tmpTableID ~= 0 then
			var_43_1 = arg_43_0.selfPlayer:getHeroByTableID(tmpTableID)

			if not var_43_1 then
				local var_43_2 = false
			end
		else
			tmpTableID = xyd.tables.hero:beforeAwaken(arg_43_1)
			var_43_1 = arg_43_0.selfPlayer:getHeroByTableID(tmpTableID)

			if not var_43_1 then
				local var_43_3 = false
			end
		end
	end

	return var_43_1
end

function var_0_0.initDefencePet(arg_44_0)
	local var_44_0

	if arg_44_0.pet_id and arg_44_0.pet_id ~= 0 then
		var_44_0 = clone(arg_44_0.selfPlayer:getPetByID(arg_44_0.pet_id))
	end

	return var_44_0
end

function var_0_0.initHeroCell(arg_45_0, arg_45_1, arg_45_2, arg_45_3)
	local var_45_0 = display.newNode()

	var_45_0:setContentSize(arg_45_2.width, arg_45_2.height)
	arg_45_0:setAvatarCard(arg_45_1, var_45_0, nil, nil, true, arg_45_3)
	var_45_0:y(3)

	return var_45_0
end

function var_0_0.setPetAvatarCard(arg_46_0, arg_46_1, arg_46_2, arg_46_3)
	local function var_46_0()
		local var_47_0 = "windows/across_arena/across_arena/main_wnd/icon_star.png"

		return xyd.AssetLoader.get():loadSprite(var_47_0)
	end

	local var_46_1 = arg_46_1:getAvatar(2)
	local var_46_2 = arg_46_1:getColor()
	local var_46_3 = arg_46_1:getStar()
	local var_46_4 = arg_46_2:getContentSize()
	local var_46_5 = var_46_4.width
	local var_46_6 = var_46_4.height
	local var_46_7 = arg_46_1:getHeroModel()
	local var_46_8 = display.newNode()
	local var_46_9
	local var_46_10 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/main_wnd/shadow1.png")

	var_46_10:setPosition(var_46_5 / 2, var_46_6 / 2)
	var_46_10:setAnchorPoint(cc.p(0.5, 0.5))
	var_46_10:setScale(var_46_6 / var_46_10:getHeight() * 0.98)

	local var_46_11 = cc.ClippingNode:create()

	var_46_11:setStencil(var_46_10)
	var_46_11:setInverted(false)
	var_46_11:setAlphaThreshold(0)
	arg_46_2:addChild(var_46_11)
	var_46_11:addChild(var_46_8)
	var_46_8:setPosition(var_46_5 / 2 - 8, 100)
	var_46_8:addChild(var_46_7)

	local var_46_12 = 0.65

	var_46_7:setScale(var_46_12)
	var_46_11:setLocalZOrder(-1)

	local var_46_13 = display.newNode()

	var_46_13:setContentSize(var_46_4)
	var_46_13:setAnchorPoint(cc.p(0.5, 0.5))
	var_46_13:setPosition(cc.p(0.5 * var_46_4.width, 0.5 * var_46_4.height))

	local var_46_14 = var_46_0()

	var_46_14:setScale(0.65)

	local var_46_15 = var_46_14:getContentSize().width * 0.65 - 3
	local var_46_16 = (var_46_4.width - var_46_3 * var_46_15) / 2

	var_46_13:setName("view")
	var_46_13:setAnchorPoint(cc.p(0, 0))
	var_46_13:setPosition(cc.p(0, 0))

	for iter_46_0 = 1, var_46_3 do
		local var_46_17 = var_46_0()

		var_46_17:setScale(0.65)
		var_46_13:addChild(var_46_17)
		var_46_17:x(var_46_16 - 15 + (iter_46_0 - 1) * var_46_15):y(50)
		var_46_17:setAnchorPoint(cc.p(0, 0))
	end

	arg_46_2:addChild(var_46_13)
end

function var_0_0.setAvatarCard(arg_48_0, arg_48_1, arg_48_2, arg_48_3, arg_48_4, arg_48_5, arg_48_6)
	local function var_48_0(arg_49_0, arg_49_1)
		local var_49_0
		local var_49_1 = xyd.isSuperHero(arg_49_0) and arg_49_1 > xyd.MAX_STAR_LEVEL and "windows/across_arena/across_arena/main_wnd/icon_star_pink.png" or "windows/across_arena/across_arena/main_wnd/icon_star.png"

		return xyd.AssetLoader.get():loadSprite(var_49_1)
	end

	local var_48_1 = xyd.tables.model:smallCard(arg_48_1:getModelID())
	local var_48_2 = arg_48_1:getColor()
	local var_48_3 = arg_48_1:getStar()
	local var_48_4 = xyd.getNormalCard(arg_48_1, 6)
	local var_48_5 = arg_48_2:getContentSize()
	local var_48_6 = arg_48_2:getContentSize().height
	local var_48_7 = arg_48_2:getContentSize().width

	var_48_4 = var_48_4 or xyd.AssetLoader.get():loadSprite("images/cards/10001001.png")

	local var_48_8
	local var_48_9 = xyd.AssetLoader.get():loadSprite("windows/across_arena/across_arena/main_wnd/shadow" .. arg_48_6 .. ".png")
	local var_48_10 = arg_48_1:getSkinDatas()

	for iter_48_0 = 1, #var_48_10 do
		if var_48_10[iter_48_0].modelID == arg_48_1:getModelID() then
			if var_48_10[iter_48_0].cardState == 2 then
				arg_48_0:setCardRare(arg_48_1, arg_48_1:getModelID(), arg_48_2, 2, 1, arg_48_6)
			end

			break
		end
	end

	var_48_9:setPosition(var_48_7 / 2, var_48_6 / 2)
	var_48_9:setAnchorPoint(cc.p(0.5, 0.5))
	var_48_9:setScale(var_48_6 / var_48_9:getHeight() * 0.98)

	local var_48_11 = cc.ClippingNode:create()

	var_48_11:setStencil(var_48_9)
	var_48_11:setInverted(false)
	var_48_11:setAlphaThreshold(0)
	arg_48_2:addChild(var_48_11)
	var_48_11:addChild(var_48_4)
	var_48_4:setPosition(var_48_7 / 2, var_48_6 / 2)
	var_48_4:setAnchorPoint(cc.p(0.5, 0.5))

	local var_48_12 = var_48_6 / var_48_4:getHeight()

	var_48_4:setScale(var_48_12)
	var_48_11:setLocalZOrder(-1)

	local var_48_13 = display.newNode()

	var_48_13:setContentSize(var_48_5)
	var_48_13:setAnchorPoint(cc.p(0.5, 0.5))
	var_48_13:setPosition(cc.p(0.5 * var_48_5.width, 0.5 * var_48_5.height))

	local var_48_14 = var_48_3

	if var_48_14 > xyd.MAX_STAR_LEVEL then
		var_48_14 = var_48_14 - xyd.MAX_STAR_LEVEL
	end

	local var_48_15 = var_48_0(arg_48_1, var_48_3)

	var_48_15:setScale(0.65)

	local var_48_16 = var_48_15:getContentSize().width * 0.65 - 3
	local var_48_17 = (var_48_5.width - var_48_14 * var_48_16) / 2

	var_48_13:setName("view")
	var_48_13:setAnchorPoint(cc.p(0, 0))
	var_48_13:setPosition(cc.p(0, 0))

	for iter_48_1 = 1, var_48_14 do
		local var_48_18 = var_48_0(arg_48_1, var_48_3)

		var_48_18:setScale(0.65)
		var_48_13:addChild(var_48_18)

		local var_48_19 = 0

		if arg_48_6 == 1 then
			var_48_19 = -12
		elseif arg_48_6 == 2 then
			-- block empty
		elseif arg_48_6 == 3 then
			var_48_19 = 6
		end

		var_48_18:x(var_48_17 + var_48_19 + (iter_48_1 - 1) * var_48_16):y(50)
		var_48_18:setAnchorPoint(cc.p(0, 0))
	end

	arg_48_2:addChild(var_48_13)
end

function var_0_0.setCardRare(arg_50_0, arg_50_1, arg_50_2, arg_50_3, arg_50_4, arg_50_5, arg_50_6)
	local var_50_0 = xyd.tables.skinSkill
	local var_50_1 = xyd.tables.hero:skinItem(arg_50_1:getTableID())

	if arg_50_4 == 2 then
		local var_50_2

		for iter_50_0 = 1, #var_50_1 do
			local var_50_3 = var_50_1[iter_50_0]
			local var_50_4 = var_50_0:getModelID(var_50_3)

			if var_50_4 and var_50_4 == arg_50_2 then
				var_50_2 = var_50_0:getRareLev(var_50_1[iter_50_0])

				break
			end
		end

		local var_50_5

		if var_50_2 and var_50_2 ~= 1 then
			if not arg_50_5 then
				var_50_5 = xyd.AssetLoader:get():loadSprite("images/icon/rare" .. var_50_2 .. "_2.png")
			else
				var_50_5 = xyd.AssetLoader:get():loadSprite("images/icon/rare" .. var_50_2 .. ".png")
			end

			var_50_5:setScale(0.8)
			var_50_5:addTo(arg_50_3)
			var_50_5:setPosition(arg_50_0:nodeByName("hero" .. arg_50_6 + 2):getChildByName("name"):getX(), 90)
		end
	end
end

function var_0_0.initPetCell(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = display.newNode()

	var_51_0:setContentSize(arg_51_2.width, arg_51_2.height)
	arg_51_0:setPetAvatarCard(arg_51_1, var_51_0)
	var_51_0:y(3)

	return var_51_0
end

function var_0_0.initOtherHero(arg_52_0, arg_52_1)
	for iter_52_0, iter_52_1 in pairs(arg_52_1) do
		if iter_52_1.add_star > 0 then
			table.insert(arg_52_0.isAddStarHeros, iter_52_1)
		end

		if iter_52_1.is_awake == 1 then
			table.insert(arg_52_0.isAwakeHeros, iter_52_1)
		end

		if iter_52_1.is_summon == 1 then
			local var_52_0 = var_0_2.new()

			var_52_0:initUnCollected(iter_52_1.table_id)
			table.insert(arg_52_0.isSummonHeros, iter_52_1)

			if not arg_52_0:checkHeroExit(arg_52_0.heros, iter_52_1.table_id) then
				table.insert(arg_52_0.heros, var_52_0)
			end
		end
	end
end

function var_0_0.formatRegionArenaHeros(arg_53_0, arg_53_1)
	for iter_53_0, iter_53_1 in pairs(arg_53_1) do
		if xyd.isSuperHero(iter_53_1) then
			local var_53_0 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_53_1 = {
				0,
				0,
				0,
				0,
				0,
				0
			}
			local var_53_2 = {
				31,
				31,
				31,
				31,
				31,
				31
			}

			arg_53_0:renewSuperHeroInfo(iter_53_1, var_53_0, var_53_1, var_53_2)
		elseif iter_53_1:isHaveAwakenItem() and not iter_53_1:isAwaken() then
			local var_53_3 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_53_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_53_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_53_0:renewHeroInfo(iter_53_1, var_53_3, var_53_4, var_53_5)
		elseif iter_53_1:isAwaken() then
			local var_53_6 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_53_7 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_53_8 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_53_0:renewHeroInfo(iter_53_1, var_53_6, var_53_7, var_53_8)
		else
			local var_53_9 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_53_10 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_53_11 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_53_0:renewHeroInfo(iter_53_1, var_53_9, var_53_10, var_53_11)
		end

		iter_53_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_53_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_54_0, arg_54_1, arg_54_2, arg_54_3, arg_54_4)
	local var_54_0 = xyd.tables.misc.regionHeroColor

	arg_54_1.level_, arg_54_1.color_ = xyd.tables.misc.regionHeroLevel, var_54_0
	arg_54_1.skillLev_ = {}
	arg_54_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_54_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_54_1.color_ >= xyd.EquipQuality.GREEN then
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_54_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_54_1.color_ >= xyd.EquipQuality.BLUE then
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_54_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_54_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_54_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_54_1:isAwaken() then
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_54_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_54_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_54_1.equips_ = {}

	for iter_54_0 = 1, var_0_7 do
		table.insert(arg_54_1.equips_, tonumber(arg_54_4[iter_54_0]))
	end

	arg_54_1.fumo_ = {}

	for iter_54_1 = 1, var_0_7 do
		table.insert(arg_54_1.fumo_, tonumber(arg_54_3[iter_54_1]))
	end

	arg_54_1.fumoLev_ = {}

	for iter_54_2 = 1, var_0_7 do
		local var_54_1 = arg_54_1:getEquipByIndex(iter_54_2)

		table.insert(arg_54_1.fumoLev_, tonumber(var_54_1:getMaxFumoStar()))
	end
end

function var_0_0.renewSuperHeroInfo(arg_55_0, arg_55_1, arg_55_2, arg_55_3, arg_55_4)
	local var_55_0 = 1

	if not arg_55_0.isfriend and arg_55_1:isCanAwaken() and not arg_55_1:isAwaken() then
		arg_55_1:setTableID(arg_55_1:afterAwakenID())
	end

	arg_55_1.color_ = var_55_0
	arg_55_1.skillLev_ = {}
	arg_55_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_55_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]
	arg_55_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_55_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	arg_55_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_55_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	arg_55_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_55_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	arg_55_1.equips_ = {}

	for iter_55_0 = 1, var_0_7 do
		table.insert(arg_55_1.equips_, tonumber(arg_55_4[iter_55_0]))
	end

	arg_55_1.fumo_ = {}

	for iter_55_1 = 1, var_0_7 do
		table.insert(arg_55_1.fumo_, tonumber(arg_55_3[iter_55_1]))
	end

	arg_55_1.fumoLev_ = {}

	for iter_55_2 = 1, var_0_7 do
		local var_55_1 = arg_55_1:getEquipByIndex(iter_55_2)

		table.insert(arg_55_1.fumoLev_, tonumber(var_55_1:getMaxFumoStar()))
	end
end

function var_0_0.willClose(arg_56_0)
	if xyd.WindowManager.get():getWindow("playoffs_schedule_main") then
		xyd.WindowManager.get():closeWindow("playoffs_schedule_main")
	end
end

function var_0_0.didClose(arg_57_0)
	if xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneTopWnd) then
		xyd.WindowManager.get():getWindow(xyd.WindowName.mainSceneTopWnd):setVisible(true)
	end
end

function var_0_0.UpdateMissionTime(arg_58_0, arg_58_1, arg_58_2)
	if arg_58_0.handler then
		var_0_5.unscheduleGlobal(arg_58_0.handler)

		arg_58_0.handler = nil
	end

	if arg_58_2 > 0 then
		arg_58_1:setString(xyd.secondsToString(arg_58_2))

		arg_58_0.handler = var_0_5.scheduleGlobal(function()
			arg_58_2 = arg_58_2 - 1

			if not tolua.isnull(arg_58_0) then
				arg_58_1:setString(xyd.secondsToString(arg_58_2))
			end

			if arg_58_2 <= 0 and arg_58_0.handler then
				var_0_5.unscheduleGlobal(arg_58_0.handler)

				arg_58_0.handler = nil

				arg_58_0.regionArena:getRegionArenaInfo(function(arg_60_0, arg_60_1)
					if arg_60_0 == xyd.error.OK then
						arg_58_0.missions = arg_60_1.missions
						arg_58_0.missionTime = arg_60_1.mission_time

						arg_58_0:updateMissionItem()
					end
				end)
			end
		end, 1)
	end
end

function var_0_0.updateShopContainer(arg_61_0)
	local var_61_0 = arg_61_0.shopContainer
	local var_61_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/shop.csb")

	var_61_1:addTo(var_61_0)
	var_61_1:setPosition(cc.p(0, 0))
	var_61_1:setAnchorPoint(cc.p(0, 0))
	var_61_1:setName("shopContainer")
	arg_61_0:updateKingCoin()

	for iter_61_0 = 1, var_0_8 do
		local var_61_2 = var_61_1:getChildByName("container"):getChildByName("bg" .. iter_61_0)

		var_61_2:getChildByName("title" .. iter_61_0):setString(var_0_1:translation("REGION_SHOP_ITEM_" .. iter_61_0))
		var_61_2:setTouchEnabled(true)
		var_61_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_62_0)
			if arg_62_0.name == "began" then
				var_61_2:setScale(0.9)

				return true
			elseif arg_62_0.name == "ended" then
				var_61_2:setScale(1)

				local var_62_0 = {
					exchange_type = iter_61_0
				}

				xyd.WindowManager.get():openWindow("region_arena_hero_shop", var_62_0)
			end
		end)
	end
end

function var_0_0.updateMissionItem(arg_63_0)
	local var_63_0 = arg_63_0.missionContainer
	local var_63_1 = -32
	local var_63_2 = arg_63_0.missions

	var_63_0:removeAllChildren()

	for iter_63_0, iter_63_1 in pairs(var_63_2) do
		local var_63_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/mission_item.csb")

		var_63_3:addTo(var_63_0)
		var_63_3:setPosition(cc.p(var_63_1, 0))
		var_63_3:setAnchorPoint(cc.p(0, 0))

		local var_63_4 = var_63_3:getChildByName("container"):getChildByName("panel1")

		var_63_3:getChildByName("container"):removeChildByName("panel2")

		local var_63_5 = xyd.tables.regionMission:taskReq(iter_63_1.mission_id)
		local var_63_6 = xyd.tables.regionMission:taskNum(iter_63_1.mission_id)
		local var_63_7 = xyd.tables.regionMission:kingCoin(iter_63_1.mission_id)
		local var_63_8 = xyd.tables.regionMission:icon(iter_63_1.mission_id)
		local var_63_9 = iter_63_1.current_num

		if var_63_6 > 10000 then
			var_63_6 = var_63_6 / 10000
			var_63_9 = var_63_9 / 10000
		end

		var_63_4:getChildByName("text_top1"):setString(var_0_1:translation("REGION_MISSION_TITLE_" .. var_63_5))
		var_63_4:getChildByName("text_top2"):setString(string.format(var_0_1:translation("REGION_MISSION_VALUE_" .. var_63_5), var_63_9, var_63_6))

		local var_63_10 = xyd.AssetLoader.get():loadSprite(var_63_8)

		var_63_4:getChildByName("icon"):addChild(var_63_10)
		var_63_4:getChildByName("text_reward"):setString(var_63_7)

		var_63_1 = var_63_1 + 400

		var_63_4:setTouchEnabled(true)
		var_63_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_64_0)
			if arg_64_0.name == "began" then
				if var_63_4:getChildByName("give_up_btn"):isVisible() == true then
					local var_64_0 = var_63_4:getChildByName("give_up_btn"):convertToNodeSpace(arg_64_0)

					if var_64_0.x > 0 and var_64_0.y > 0 then
						return false
					end
				end

				var_63_4:setScale(0.9)

				return true
			elseif arg_64_0.name == "ended" then
				var_63_4:setScale(1)

				if iter_63_1.is_complete == xyd.MissionIsComplete.TRUE then
					local var_64_1 = {
						mission_id = iter_63_1.mission_id
					}

					arg_63_0.regionArena:getMissionAwards(var_64_1, function(arg_65_0, arg_65_1)
						if arg_65_0 == xyd.error.OK then
							local var_65_0 = {}

							arg_63_0:updateKingCoin()

							var_65_0.awards = arg_65_1.awards
							arg_63_0.missions = arg_65_1.missions
							arg_63_0.missionTime = arg_65_1.mission_time
							var_65_0.callback = arg_63_0:updateMissionItem()

							xyd.WindowManager.get():openWindow("alert_award", var_65_0)
						end
					end)
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("MISSION_NOT_COMPLETE")
					})
				end
			end
		end)

		if iter_63_1.is_complete == xyd.MissionIsComplete.TRUE then
			var_63_4:getChildByName("give_up_btn"):setVisible(false)
		end

		var_63_4:getChildByName("give_up_btn"):addTouchEventListener(function(arg_66_0, arg_66_1)
			if arg_66_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_66_0 = string.format(var_0_1:translation("REGION_AREAN_GIVE_UP_MISSION_TIP"), xyd.secondsToString1(var_0_9, 1))

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_66_0, function()
					local var_67_0 = {
						mission_id = iter_63_1.mission_id
					}

					arg_63_0.regionArena:giveUpRegionMission(var_67_0, function(arg_68_0, arg_68_1)
						if arg_68_0 == xyd.error.OK then
							arg_63_0.missions = arg_68_1.missions
							arg_63_0.missionTime = arg_68_1.mission_time

							arg_63_0:updateMissionItem()
						end
					end)
				end, nil, nil, arg_63_0.colorMode)
			end
		end)
	end

	if #var_63_2 < 3 then
		local var_63_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/mission_item.csb")

		var_63_11:addTo(var_63_0)
		var_63_11:setPosition(cc.p(var_63_1, 0))
		var_63_11:setAnchorPoint(cc.p(0, 0))

		local var_63_12 = var_63_11:getChildByName("container"):getChildByName("panel2")

		var_63_11:getChildByName("container"):getChildByName("panel1"):setVisible(false)
		var_63_12:getChildByName("text_mid"):setString(var_0_1:translation("MISSION_TIME"))

		local var_63_13 = xyd.ServerTime.get():getServerTime()

		arg_63_0:UpdateMissionTime(var_63_12:getChildByName("text_time"), arg_63_0.missionTime + var_0_9 - var_63_13)
	end
end

function var_0_0.updateKingCoin(arg_69_0)
	local var_69_0 = arg_69_0.selfPlayer.kingCoin

	arg_69_0:nodeByName("text_king_coin"):setString(var_69_0)

	local var_69_1 = arg_69_0.regionArena.exchangeTimes

	for iter_69_0 = 1, #var_69_1 do
		local var_69_2 = xyd.tables.regionExchange:getCost(iter_69_0)
		local var_69_3 = var_69_1[iter_69_0] + 1

		if var_69_3 > #var_69_2 then
			var_69_3 = #var_69_2
		end

		arg_69_0.shopContainer:getChildByName("shopContainer"):getChildByName("container"):getChildByName("bg" .. iter_69_0):getChildByName("king_coin" .. iter_69_0):setString(var_69_2[var_69_3])
	end
end

return var_0_0
