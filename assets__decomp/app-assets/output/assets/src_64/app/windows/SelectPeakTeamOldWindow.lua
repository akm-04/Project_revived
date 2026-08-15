local var_0_0 = class("SelectPeakTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 30
local var_0_4 = 30
local var_0_5 = 5
local var_0_6 = 4
local var_0_7 = 90
local var_0_8 = xyd.tables.translation
local var_0_9 = xyd.tables.hero
local var_0_10 = 3
local var_0_11 = 1
local var_0_12 = 2

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.PEAK_ARENA
	arg_1_0.campaignType = arg_1_2.campaignType or 0
	arg_1_0.campaignID = arg_1_2.campaignID or 0
	arg_1_0.totalPet_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_1_0.totalIDs_ = {}
	arg_1_0.enemyTeams_ = arg_1_2.enemyTeams
	arg_1_0.enemyPets_ = arg_1_2.enemyPets
	arg_1_0.withRobot_ = arg_1_2.withRobot
	arg_1_0.enemyMatched_ = arg_1_2.matchedEnemy
	arg_1_0.enemyID_ = arg_1_2.enemyID
	arg_1_0.enemyName = arg_1_2.enemyName
	arg_1_0.enemyLev = arg_1_2.enemyLev
	arg_1_0.enemyConquerLev = arg_1_2.enemyConquerLev
	arg_1_0.enemyConquerLoopID = arg_1_2.enemyConquerLoopID
	arg_1_0.enemyAvatar = arg_1_2.enemyAvatar
	arg_1_0.enemyAvatarFrame = arg_1_2.enemyAvatarFrame
	arg_1_0.oldBestRank = arg_1_2.oldBestRank
	arg_1_0.fighterInfo = arg_1_2.fighterInfo
	arg_1_0.battleBegan = false
	arg_1_0.isPresetAnimation = false
	arg_1_0.containerState = var_0_11
	arg_1_0.petTeam_ = {}
	arg_1_0.petTeam_[1] = {}
	arg_1_0.petTeam_[2] = {}
	arg_1_0.petTeam_[3] = {}
	arg_1_0.peakTeams_ = {}
	arg_1_0.peakTeams_[1] = {}
	arg_1_0.peakTeams_[2] = {}
	arg_1_0.peakTeams_[3] = {}
	arg_1_0.peakSelectTeams_ = {}
	arg_1_0.peakSelectTeams_[1] = {}
	arg_1_0.peakSelectTeams_[2] = {}
	arg_1_0.peakSelectTeams_[3] = {}
	arg_1_0.petSelect_ = arg_1_2.petSelect

	if not arg_1_0.petSelect_ then
		arg_1_0.petSelect_ = {}
		arg_1_0.petSelect_[1] = {}
		arg_1_0.petSelect_[2] = {}
		arg_1_0.petSelect_[3] = {}
	end

	arg_1_0.nowTeamNumber_ = 1
	arg_1_0.preSelectTeams_ = arg_1_2.selectedTeams or {}
	arg_1_0.prePet_ = arg_1_2.prePet or {}
	arg_1_0.scores_ = {}
	arg_1_0.scores_[1] = 0
	arg_1_0.scores_[2] = 0
	arg_1_0.scores_[3] = 0
	arg_1_0.switchMode = 0
	arg_1_0.unPreSelect_ = {}
	arg_1_0.unPreSelectPet_ = {}
	arg_1_0.presetTeamCells = {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA_OLD)

	if not arg_1_0.prePet_ or not next(arg_1_0.prePet_) then
		arg_1_0.prePet_[1] = {}
		arg_1_0.prePet_[2] = {}
		arg_1_0.prePet_[3] = {}
	end

	if not arg_1_0.preSelectTeams_ or not next(arg_1_0.preSelectTeams_) then
		arg_1_0.preSelectTeams_[1] = {}
		arg_1_0.preSelectTeams_[2] = {}
		arg_1_0.preSelectTeams_[3] = {}

		arg_1_0:loadPreFormation()
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in pairs(arg_2_0.selfPlayer.heros_) do
		if arg_2_0:isSpecifyHero(iter_2_1) and iter_2_1:getLevel() >= xyd.tables.battle:levLimit(arg_2_0.campaignID) then
			if iter_2_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_2_0.totalHero_[xyd.DistanceType.QIANPAI], iter_2_1)
			elseif iter_2_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_2_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_2_1)
			elseif iter_2_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_2_0.totalHero_[xyd.DistanceType.HOUPAI], iter_2_1)
			end

			table.insert(arg_2_0.totalHero_[xyd.DistanceType.ALL], iter_2_1)
		end
	end

	arg_2_0:sortTables()

	arg_2_0.selectedHeroClass_ = xyd.DistanceType.ALL

	arg_2_0:initPets(arg_2_0:getPets() or {})
	arg_2_0:nodeByName("cancel_change"):setVisible(false)
	arg_2_0:initPresetTeams()
	arg_2_0:layout()
end

function var_0_0.initPets(arg_3_0, arg_3_1)
	local var_3_0 = {}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		if iter_3_1.is_show_ == 1 then
			table.insert(var_3_0, iter_3_1)
		end
	end

	table.sort(var_3_0, function(arg_4_0, arg_4_1)
		return xyd.petNormalSort(arg_4_0, arg_4_1) or false
	end)

	arg_3_0.totalPet_ = var_3_0
end

function var_0_0.layoutTeams(arg_5_0)
	for iter_5_0 = 1, #arg_5_0.peakSelectTeams_ do
		for iter_5_1 = 1, 5 do
			arg_5_0:nodeByName("team_container_" .. iter_5_0):getChildByName("hero_" .. iter_5_1):removeAllChildren()
		end

		for iter_5_2 = 1, #arg_5_0.peakSelectTeams_[iter_5_0] do
			if arg_5_0.peakSelectTeams_[iter_5_0][iter_5_2] then
				xyd.setAvatarBorder(arg_5_0.peakSelectTeams_[iter_5_0][iter_5_2], arg_5_0:nodeByName("team_container_" .. iter_5_0):getChildByName("hero_" .. iter_5_2))
			end
		end

		arg_5_0:nodeByName("team_container_" .. iter_5_0):getChildByName("pet"):removeAllChildren()

		if arg_5_0.petSelect_[iter_5_0][1] then
			xyd.setPetAvatar(arg_5_0:nodeByName("team_container_" .. iter_5_0):getChildByName("pet"), arg_5_0.petSelect_[iter_5_0][1], nil, true, nil, true)
		end
	end
end

function var_0_0.isSpecifyHero(arg_6_0, arg_6_1)
	if arg_6_0.campaignType == xyd.CampaignType.WU and arg_6_1:getFromType() == xyd.HeroFromType.WU then
		return false
	end

	if arg_6_0.campaignType == xyd.CampaignType.SHU and arg_6_1:getFromType() == xyd.HeroFromType.SHU then
		return false
	end

	if arg_6_0.campaignType == xyd.CampaignType.WEI and arg_6_1:getFromType() ~= xyd.HeroFromType.WU and arg_6_1:getFromType() ~= xyd.HeroFromType.SHU then
		return false
	end

	return true
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0.super.didOpen(arg_7_0, arg_7_1)
	arg_7_0:refreshSelectedHeroClass()
	arg_7_0:refreshSelectTeamClass()
	arg_7_0:getBattleBtn()
	arg_7_0:setNextBtn()
	arg_7_0:refreshBtnState()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_7_0, arg_7_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_7_0, arg_7_0.updateListBySearchTxt))
end

function var_0_0.updateList(arg_8_0)
	arg_8_0.selectedHeroClass_ = xyd.DistanceType.FILTER
	arg_8_0.isHeroPreset = false

	arg_8_0:updateFilterHeros()
	arg_8_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_9_0, arg_9_1)
	arg_9_0.searchTxt = arg_9_1.heroName
	arg_9_0.selectedHeroClass_ = xyd.DistanceType.SEARCH

	arg_9_0:updateSearchHeros()
	arg_9_0:refreshSelectedHeroClass()
end

function var_0_0.updateFilterHeros(arg_10_0)
	arg_10_0.totalHero_[xyd.DistanceType.FILTER] = {}

	local var_10_0 = {
		0,
		0,
		0
	}
	local var_10_1 = {
		0,
		0,
		0
	}
	local var_10_2 = {
		0,
		0,
		0,
		0
	}

	if arg_10_0.selfPlayer.sortType and arg_10_0.selfPlayer.sortType > 0 then
		local var_10_3 = {}
		local var_10_4 = arg_10_0.selfPlayer.sortType
		local var_10_5 = 1

		while var_10_4 > 0 do
			var_10_3[var_10_5] = var_10_4 % 2
			var_10_5 = var_10_5 + 1
			var_10_4 = math.floor(var_10_4 / 2)
		end

		local var_10_6 = 1

		for iter_10_0 = 10, 1, -1 do
			if iter_10_0 <= 4 then
				if iter_10_0 == 4 then
					var_10_6 = 1
				end

				var_10_2[var_10_6] = var_10_3[iter_10_0]
			elseif iter_10_0 <= 7 then
				if iter_10_0 == 7 then
					var_10_6 = 1
				end

				var_10_1[var_10_6] = var_10_3[iter_10_0]
			elseif iter_10_0 <= 10 and var_10_3[iter_10_0] then
				var_10_0[var_10_6] = var_10_3[iter_10_0]
			end

			var_10_6 = var_10_6 + 1
		end
	else
		var_10_0 = {
			1,
			1,
			1
		}
		var_10_1 = {
			1,
			1,
			1
		}
		var_10_2 = {
			1,
			1,
			1,
			1
		}
	end

	for iter_10_1, iter_10_2 in pairs(arg_10_0.totalHero_[xyd.DistanceType.ALL]) do
		if var_10_0[iter_10_2:getDistanceType() - 1] == 1 and var_10_1[iter_10_2:getHeroType()] == 1 and var_10_2[iter_10_2:getFromType()] == 1 and arg_10_0:isSpecifyHero(iter_10_2) and iter_10_2:getLevel() >= xyd.tables.battle:levLimit(arg_10_0.campaignID) then
			table.insert(arg_10_0.totalHero_[xyd.DistanceType.FILTER], iter_10_2)
		end
	end
end

function var_0_0.updateSearchHeros(arg_11_0)
	arg_11_0.totalHero_[xyd.DistanceType.SEARCH] = {}

	if arg_11_0.searchTxt ~= "" then
		for iter_11_0, iter_11_1 in pairs(arg_11_0.totalHero_[xyd.DistanceType.ALL]) do
			if xyd.searchHeroByName(arg_11_0.searchTxt, iter_11_1) then
				table.insert(arg_11_0.totalHero_[xyd.DistanceType.SEARCH], iter_11_1)
			end
		end
	end
end

function var_0_0.setNextBtn(arg_12_0)
	arg_12_0:nodeByName("next_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if #arg_12_0.peakSelectTeams_[arg_12_0.nowTeamNumber_] < 1 then
				local var_13_0 = string.format(var_0_8:translation("PEAK_SELECT_TEAM_TIP_2"), arg_12_0.nowTeamNumber_)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_13_0, nil, nil, nil, arg_12_0.colorMode)
			else
				arg_12_0.nowTeamNumber_ = arg_12_0.nowTeamNumber_ + 1

				arg_12_0:refreshSelectTeamClass()
				arg_12_0:showTeamsByTeamNumber(arg_12_0.nowTeamNumber_)
				arg_12_0:refreshBtnState()

				if arg_12_0.type == xyd.SelectTeamType.PEAK_ARENA then
					arg_12_0:refreshEnemyPanel()
				end

				arg_12_0:updateScore(arg_12_0.nowTeamNumber_)
			end
		end
	end)
end

function var_0_0.refreshEnemyPanel(arg_14_0)
	for iter_14_0 = 1, 5 do
		local var_14_0 = arg_14_0:nodeByName("enemy_hero_" .. iter_14_0)

		var_14_0:removeAllChildren()
		arg_14_0:nodeByName("pet_back_enemy"):removeAllChildren()

		for iter_14_1 = 1, 3 do
			if arg_14_0.nowTeamNumber_ == iter_14_1 then
				if arg_14_0.enemyMatched_.rank <= xyd.tables.misc.peakArenaRankLimit[iter_14_1] then
					arg_14_0:nodeByName("question_mark_" .. iter_14_0):setVisible(true)
					arg_14_0:nodeByName("question_mark_pet"):setVisible(true)

					break
				end

				local var_14_1 = arg_14_0.enemyTeams_[arg_14_0.nowTeamNumber_]

				if iter_14_0 <= #var_14_1 then
					xyd.setAvatarBorder(var_14_1[iter_14_0], var_14_0)
				end

				local var_14_2 = arg_14_0.enemyPets_[arg_14_0.nowTeamNumber_]

				if #var_14_2 > 0 then
					xyd.setPetAvatar(arg_14_0:nodeByName("pet_back_enemy"), var_14_2[1], nil, true)
				end

				arg_14_0:nodeByName("question_mark_" .. iter_14_0):setVisible(false)
				arg_14_0:nodeByName("question_mark_pet"):setVisible(false)

				break
			end
		end
	end
end

function var_0_0.updateTeamBtnNumber(arg_15_0, arg_15_1, arg_15_2)
	return
end

function var_0_0.refreshBtnState(arg_16_0)
	if arg_16_0.nowTeamNumber_ < 3 then
		arg_16_0:nodeByName("next_btn"):setVisible(true)
		arg_16_0:nodeByName("button_ok"):setVisible(false)
		arg_16_0:nodeByName("button_battle"):setVisible(false)
	elseif arg_16_0.nowTeamNumber_ == 3 and arg_16_0.type == xyd.SelectTeamType.PEAK_ARENA then
		arg_16_0:nodeByName("next_btn"):setVisible(false)
		arg_16_0:nodeByName("button_ok"):setVisible(false)
		arg_16_0:nodeByName("button_battle"):setVisible(true)
	elseif arg_16_0.nowTeamNumber_ == 3 and arg_16_0.type == xyd.SelectTeamType.PEAK_ARENA_DEFENSE then
		arg_16_0:nodeByName("next_btn"):setVisible(false)
		arg_16_0:nodeByName("button_ok"):setVisible(true)
		arg_16_0:nodeByName("button_battle"):setVisible(false)
		arg_16_0:nodeByName("switch_team_button"):setVisible(false)
	end
end

function var_0_0.sortTables(arg_17_0)
	for iter_17_0 = 1, #arg_17_0.totalHero_ do
		table.sort(arg_17_0.totalHero_[iter_17_0], function(arg_18_0, arg_18_1)
			return xyd.heroNormalSort(arg_18_0, arg_18_1) or false
		end)
	end
end

function var_0_0.exitScene(arg_19_0)
	arg_19_0:dispatchEvent({
		name = xyd.event.EXIT_BATTLE_PREPARE
	})
end

function var_0_0.layout(arg_20_0)
	arg_20_0:initMenu()
	arg_20_0:initTeamMenu()
	arg_20_0:updateScore(arg_20_0.nowTeamNumber_)

	local var_20_0 = arg_20_0:nodeByName("list_layer")
	local var_20_1 = arg_20_0:nodeByName("list_layer_battle")
	local var_20_2 = var_20_0:getContentSize().width
	local var_20_3 = var_20_0:getContentSize().height
	local var_20_4 = var_20_1:getContentSize().width
	local var_20_5 = var_20_1:getContentSize().height

	if arg_20_0.type == xyd.SelectTeamType.PEAK_ARENA then
		arg_20_0:refreshEnemyPanel()

		arg_20_0.heroList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_20_4, var_20_5),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_20_1)

		var_20_0:setVisible(false)
		arg_20_0:nodeByName("battle_team_bg"):setVisible(true)
		arg_20_0:nodeByName("main_bg"):setVisible(false)
	elseif arg_20_0.type == xyd.SelectTeamType.PEAK_ARENA_DEFENSE then
		arg_20_0.heroList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_20_2, var_20_3),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(var_20_0)

		var_20_1:setVisible(false)
		arg_20_0:nodeByName("battle_team_bg"):setVisible(false)
		arg_20_0:nodeByName("main_bg"):setVisible(true)
		arg_20_0:nodeByName("switch_team_button"):setVisible(false)
	end

	arg_20_0.heroCells_ = {}

	arg_20_0.heroList_:setDelegate(handler(arg_20_0, arg_20_0.delegate))
	arg_20_0:showTeamsByTeamNumber(arg_20_0.nowTeamNumber_)

	for iter_20_0 = 1, var_0_10 do
		arg_20_0:refreshTeamHeroNum(iter_20_0, #arg_20_0.peakTeams_[iter_20_0])
	end

	arg_20_0:nodeByName("list_layer_team"):runActionOnce(cc.FadeOut:create(0.1))
end

function var_0_0.initTeamMenu(arg_21_0)
	arg_21_0.teamButtons_ = {}

	table.insert(arg_21_0.teamButtons_, arg_21_0:nodeByName("button_team1"))
	table.insert(arg_21_0.teamButtons_, arg_21_0:nodeByName("button_team2"))
	table.insert(arg_21_0.teamButtons_, arg_21_0:nodeByName("button_team3"))

	for iter_21_0 = 1, #arg_21_0.teamButtons_ do
		arg_21_0.teamButtons_[iter_21_0]:addTouchEventListener(function(arg_22_0, arg_22_1)
			if arg_22_1 == ccui.TouchEventType.ended and not arg_21_0.isPresetAnimation then
				collectgarbage("collect")
				xyd.playTabButtonSound()

				if arg_21_0.isAnimating then
					return
				end

				if arg_21_0.switchMode == 0 then
					arg_21_0.isHeroPreset = false
					arg_21_0.nowTeamNumber_ = iter_21_0

					arg_21_0:refreshSelectTeamClass()
					arg_21_0:showTeamsByTeamNumber(arg_21_0.nowTeamNumber_)
					arg_21_0:refreshBtnState()

					if arg_21_0.type == xyd.SelectTeamType.PEAK_ARENA then
						arg_21_0:refreshEnemyPanel()
					end

					arg_21_0:refreshSelectedHeroClass()
					arg_21_0:updateScore(arg_21_0.nowTeamNumber_)
				elseif arg_21_0.switchMode == 1 then
					arg_21_0:refreshBtnState()

					if iter_21_0 == arg_21_0.nowTeamNumber_ then
						arg_21_0:refreshSelectTeamClass()

						return
					end

					arg_21_0:changeTeams(arg_21_0.nowTeamNumber_, iter_21_0)

					arg_21_0.nowTeamNumber_ = iter_21_0

					arg_21_0:refreshBtnState()
					arg_21_0:refreshSelectTeamClass()
					arg_21_0:refreshSelectedHeroClass()
				end
			end
		end)
	end
end

function var_0_0.changeTeams(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_0.peakSelectTeams_[arg_23_1]

	arg_23_0.peakSelectTeams_[arg_23_1] = arg_23_0.peakSelectTeams_[arg_23_2]
	arg_23_0.peakSelectTeams_[arg_23_2] = var_23_0

	local var_23_1 = arg_23_0.petSelect_[arg_23_1]

	arg_23_0.petSelect_[arg_23_1] = arg_23_0.petSelect_[arg_23_2]
	arg_23_0.petSelect_[arg_23_2] = var_23_1

	local var_23_2 = arg_23_0.peakTeams_[arg_23_1]

	arg_23_0.peakTeams_[arg_23_1] = arg_23_0.peakTeams_[arg_23_2]
	arg_23_0.peakTeams_[arg_23_2] = var_23_2

	for iter_23_0, iter_23_1 in ipairs(arg_23_0.peakTeams_[arg_23_1]) do
		iter_23_1.teamCount_ = arg_23_1

		iter_23_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
			if arg_24_0.name == "ended" then
				arg_23_0:clickBottomAvatar(iter_23_1, arg_23_1)
			end

			return true
		end)
	end

	for iter_23_2, iter_23_3 in ipairs(arg_23_0.peakTeams_[arg_23_2]) do
		iter_23_3.teamCount_ = arg_23_2

		iter_23_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_25_0)
			if arg_25_0.name == "ended" then
				arg_23_0:clickBottomAvatar(iter_23_3, arg_23_2)
			end

			return true
		end)
	end

	local var_23_3 = arg_23_0.petTeam_[arg_23_1]

	arg_23_0.petTeam_[arg_23_1] = arg_23_0.petTeam_[arg_23_2]
	arg_23_0.petTeam_[arg_23_2] = var_23_3

	arg_23_0:widgetSet(arg_23_0:nodeByName("team_container_" .. arg_23_1))
	arg_23_0:widgetSet(arg_23_0:nodeByName("team_container_" .. arg_23_2))

	arg_23_0.isAnimating = true

	arg_23_0:nodeByName("team_container_" .. arg_23_1):runActionOnce(cc.FadeOut:create(0.4), false, function()
		for iter_26_0 = 1, 3 do
			for iter_26_1 = 1, 5 do
				arg_23_0:nodeByName("team_container_" .. iter_26_0):getChildByName("hero_" .. iter_26_1):removeAllChildren()
			end

			arg_23_0:nodeByName("team_container_" .. iter_26_0):getChildByName("pet"):removeAllChildren()
		end

		arg_23_0:layoutTeams()
	end)
	arg_23_0:nodeByName("team_container_" .. arg_23_2):runActionOnce(cc.FadeOut:create(0.4), false, function()
		arg_23_0:nodeByName("team_container_" .. arg_23_1):runActionOnce(cc.FadeIn:create(0.4))
		arg_23_0:nodeByName("team_container_" .. arg_23_2):runActionOnce(cc.FadeIn:create(0.4), false, function()
			arg_23_0:showTeamsByTeamNumber(arg_23_0.nowTeamNumber_)
			arg_23_0:refreshEnemyPanel()
			arg_23_0:moveButtons(0)
			arg_23_0:nodeByName("team_arrow"):setVisible(true)
			arg_23_0:nodeByName("team_arrow_Copy"):setVisible(true)
		end)
	end)
end

function var_0_0.widgetSet(arg_29_0, arg_29_1)
	for iter_29_0, iter_29_1 in ipairs(arg_29_1:getChildren()) do
		if iter_29_1 ~= nil then
			iter_29_1:setCascadeOpacityEnabled(true)
			arg_29_0:widgetSet(iter_29_1)
		end
	end
end

function var_0_0.moveButtons(arg_30_0)
	arg_30_0:switchTeamMode()

	if arg_30_0.switchMode == 1 then
		arg_30_0:nodeByName("list_layer_battle"):setVisible(false)
		arg_30_0:nodeByName("list_layer_team"):setVisible(true)
		arg_30_0:widgetSet(arg_30_0:nodeByName("list_layer_team"))
		arg_30_0:nodeByName("list_layer_team"):runActionOnce(cc.FadeIn:create(0.5), false)

		for iter_30_0, iter_30_1 in ipairs(arg_30_0.teamButtons_) do
			arg_30_0.isAnimating = true

			iter_30_1:runActionOnce(cc.MoveTo:create(0.5, cc.p(iter_30_1:getPositionX() + 130, iter_30_1:getPositionY())), false, function()
				arg_30_0.isAnimating = false
			end)
		end
	elseif arg_30_0.switchMode == 0 then
		for iter_30_2, iter_30_3 in ipairs(arg_30_0.teamButtons_) do
			arg_30_0.isAnimating = true

			iter_30_3:runActionOnce(cc.MoveTo:create(0.5, cc.p(iter_30_3:getPositionX() - 130, iter_30_3:getPositionY())), false, function()
				arg_30_0.isAnimating = false
			end)
		end

		arg_30_0:widgetSet(arg_30_0:nodeByName("list_layer_team"))
		arg_30_0:nodeByName("list_layer_team"):runActionOnce(cc.FadeOut:create(0.5), false, function()
			arg_30_0:nodeByName("list_layer_battle"):setVisible(true)
			arg_30_0:nodeByName("list_layer_team"):setVisible(false)
		end)
	end
end

function var_0_0.willClose(arg_34_0)
	return
end

function var_0_0.loadPreFormation(arg_35_0)
	local var_35_0 = xyd.db.formation:getFormationData(arg_35_0.campaignType) or {}

	if type(var_35_0) == "table" then
		for iter_35_0 = 1, #var_35_0 do
			local var_35_1 = {}
			local var_35_2 = {}

			for iter_35_1, iter_35_2 in ipairs(var_35_0[iter_35_0]) do
				if iter_35_0 > 3 then
					local var_35_3 = arg_35_0.selfPlayer:getPetByID(iter_35_2)

					if var_35_3 then
						table.insert(var_35_2, var_35_3)
					end
				else
					local var_35_4 = arg_35_0.selfPlayer:getHeroByID(iter_35_2)

					if var_35_4 then
						table.insert(var_35_1, var_35_4)
					end
				end
			end

			if iter_35_0 > 3 then
				arg_35_0.prePet_[iter_35_0 - 3] = var_35_2
			else
				arg_35_0.preSelectTeams_[iter_35_0] = var_35_1
			end
		end
	else
		return
	end
end

function var_0_0.initMenu(arg_36_0)
	arg_36_0.heroClassButtons_ = {}

	table.insert(arg_36_0.heroClassButtons_, arg_36_0:nodeByName("button_all"))
	table.insert(arg_36_0.heroClassButtons_, arg_36_0:nodeByName("button_qianpai"))
	table.insert(arg_36_0.heroClassButtons_, arg_36_0:nodeByName("button_zhongpai"))
	table.insert(arg_36_0.heroClassButtons_, arg_36_0:nodeByName("button_houpai"))
	table.insert(arg_36_0.heroClassButtons_, arg_36_0:nodeByName("button_filter"))

	for iter_36_0 = 1, #arg_36_0.heroClassButtons_ do
		arg_36_0.heroClassButtons_[iter_36_0]:addTouchEventListener(function(arg_37_0, arg_37_1)
			if arg_37_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				collectgarbage("collect")

				arg_36_0.selectedHeroClass_ = iter_36_0
				arg_36_0.isHeroPreset = false

				arg_36_0:refreshSelectedHeroClass(true)
			end
		end)
	end

	arg_36_0:nodeByName("button_preset"):addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()

			if not arg_36_0.isHeroPreset then
				arg_36_0.isHeroPreset = true

				for iter_38_0 = 1, #arg_36_0.heroClassButtons_ do
					arg_36_0.heroClassButtons_[iter_38_0]:setBrightStyle(ccui.BrightStyle.normal)
				end

				arg_36_0.heroList_:reload()
			end

			arg_36_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
		end
	end)
	arg_36_0:nodeByName("text_filter"):setString(var_0_8:translation("FILTER_TEXT"))
	arg_36_0:nodeByName("button_filter"):addTouchEventListener(function(arg_39_0, arg_39_1)
		xyd.buttonScaleAnim(arg_39_0, arg_39_1)

		if arg_39_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_filter_wnd", {
				awaken_not_show = true
			})
		end
	end)
	arg_36_0:nodeByName("button_search"):addTouchEventListener(function(arg_40_0, arg_40_1)
		xyd.buttonScaleAnim(arg_40_0, arg_40_1)

		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_36_0:nodeByName("switch_team_button"):addTouchEventListener(function(arg_41_0, arg_41_1)
		if arg_41_1 == ccui.TouchEventType.ended then
			if arg_36_0.isAnimating then
				return
			end

			arg_36_0:moveButtons(1)
		end
	end)
end

function var_0_0.switchTeamMode(arg_42_0)
	arg_42_0.switchMode = 1 - arg_42_0.switchMode

	if arg_42_0.switchMode == 1 then
		arg_42_0:nodeByName("cancel_change"):setVisible(true)
		arg_42_0:nodeByName("change_txt"):setVisible(false)
		arg_42_0:nodeByName("team_arrow"):setVisible(false)
		arg_42_0:nodeByName("team_arrow_Copy"):setVisible(false)
		arg_42_0:layoutTeams()
	elseif arg_42_0.switchMode == 0 then
		arg_42_0:nodeByName("cancel_change"):setVisible(false)
		arg_42_0:nodeByName("change_txt"):setVisible(true)
		arg_42_0:layoutTeams()
	end
end

function var_0_0.initHeroCell(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_0.totalHero_[arg_43_0.selectedHeroClass_][arg_43_2]
	local var_43_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
	local var_43_2 = var_43_1:getChildByName("background"):getContentSize()

	var_43_1:setContentSize(var_43_2)
	arg_43_1:setContentSize(var_43_2)
	xyd.setAvatarBorder(var_43_0, var_43_1:getChildByName("avatar"))

	local var_43_3 = var_43_1:getChildByName("chosen")

	var_43_3:setLocalZOrder(100)
	var_43_3:setVisible(false)

	local var_43_4 = var_43_1:getChildByName("avatar_mask")

	var_43_4:setLocalZOrder(2)
	var_43_4:setVisible(false)
	var_43_1:getChildByName("lv_txt"):setString(var_43_0:getLevel())

	local var_43_5 = var_43_1:getChildByName("name_text")

	var_43_5:setString(var_43_0:getName())
	var_43_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[var_43_0:getColor()] ~= "" then
		local var_43_6 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_43_5:getX() + var_43_5:getWidth() / 2 - 10,
			y = var_43_5:getY(),
			color = xyd.color.HERO_QUALITY[var_43_0:getColor()],
			text = xyd.Color2Level[var_43_0:getColor()]
		}
		local var_43_7 = xyd.AssetLoader.get():loadLabel(var_43_6)

		var_43_7:addTo(var_43_1)
		var_43_7:align(display.CENTER_LEFT)
		var_43_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_43_5:x(var_43_5:getX() - 15)
	end

	local var_43_8 = var_43_1:getChildByName("hp_bar")
	local var_43_9 = var_43_1:getChildByName("mp_bar")
	local var_43_10 = var_43_1:getChildByName("dead_text")

	var_43_10:setString(var_0_8:translation("ALREADY_DEAD"))

	if var_43_10 then
		var_43_10:setVisible(false)
	end

	local var_43_11 = false

	if arg_43_0.heroStatus_ ~= nil and next(arg_43_0.heroStatus_) then
		local var_43_12 = arg_43_0.heroStatus_[tostring(var_43_0:getHeroID())]

		if var_43_12 and var_43_12.health then
			local var_43_13
			local var_43_14

			if var_43_12.health == 0 then
				var_43_13 = 100
				var_43_14 = 0
			elseif var_43_12.health == 1 and var_43_12.hp >= 1 then
				var_43_13 = var_43_12.hp / var_43_0:getMaxHP() * 100
				var_43_14 = var_43_12.mp / 10
			else
				var_43_13 = 0
				var_43_14 = 0

				var_43_4:setVisible(true)
				var_43_10:setLocalZOrder(3)
				var_43_10:setVisible(true)
				var_43_10:enableOutline(cc.c4b(0, 0, 0), 2)
				var_43_10:getVirtualRenderer():setAdditionalKerning(2)

				var_43_11 = true
			end

			var_43_8:setPercent(var_43_13)
			var_43_8:setVisible(true)
			var_43_9:setPercent(var_43_14)
			var_43_9:setVisible(true)
		end
	else
		var_43_8:hide()
		var_43_9:hide()
		var_43_1:getChildByName("hp_di"):hide()
		var_43_1:getChildByName("mp_di"):hide()
	end

	var_43_1:setName("layout")
	var_43_1:setPosition(cc.p(0, 0))

	arg_43_1.data = var_43_0

	arg_43_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_43_1:addChild(var_43_1)

	for iter_43_0 = 1, var_0_10 do
		for iter_43_1, iter_43_2 in ipairs(arg_43_0.peakSelectTeams_[iter_43_0]) do
			if iter_43_2:getTableID() == var_43_0:getTableID() then
				arg_43_1.teamNo_ = iter_43_1
				arg_43_1.teamCount_ = iter_43_0

				var_43_3:setVisible(true)
				var_43_4:setVisible(true)

				if not arg_43_0.peakTeams_[iter_43_0][iter_43_1] then
					arg_43_0.peakTeams_[iter_43_0][iter_43_1] = {}
				end

				arg_43_0.peakTeams_[iter_43_0][iter_43_1].iniCell_ = arg_43_1
				arg_43_0.peakTeams_[iter_43_0][iter_43_1].iniCellVisible_ = false

				arg_43_0:showHeroCellTeam(arg_43_1.teamCount_, arg_43_1:getChildByName("layout"))

				break
			end
		end

		if arg_43_1.teamNo_ and arg_43_1.teamCount_ then
			break
		end
	end

	arg_43_1:setTouchSwallowEnabled(false)
	arg_43_1:setTouchEnabled(true)
	arg_43_0:showHeroCellTeam(arg_43_1.teamCount_, arg_43_1:getChildByName("layout"))

	if not isBusy then
		arg_43_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
			arg_43_0:buttonHandler(nil, arg_43_1, arg_44_0)

			if arg_44_0.name == "began" then
				arg_43_0.startClick_ = true
				arg_43_0.prevX_ = arg_44_0.x
				arg_43_0.prevY_ = arg_44_0.y
			elseif arg_44_0.name == "moved" then
				if math.abs(arg_44_0.y - arg_43_0.prevY_) > 5 or math.abs(arg_44_0.x - arg_43_0.prevX_) > 5 then
					arg_43_0.startClick_ = false
				end
			elseif arg_44_0.name == "ended" and arg_43_0.startClick_ then
				if var_43_11 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_8:translation("HERO_DIE_ERROR")
					})
				else
					arg_43_0:clickAvatar(arg_43_1, false, arg_43_0.nowTeamNumber_)
				end
			end

			return true
		end)
	end
end

function var_0_0.initPetCell(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_0.totalPet_[arg_45_2]

	arg_45_1:align(display.CENTER):size(146, 146)
	xyd.setPetAvatar(arg_45_1, var_45_0, 100)

	arg_45_1.data = var_45_0

	arg_45_1:setTouchEnabled(true)
	arg_45_1:setTouchSwallowEnabled(false)
	arg_45_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_46_0)
		arg_45_0:buttonHandler(nil, arg_45_1, arg_46_0)

		if arg_46_0.name == "began" then
			arg_45_0.startClick_ = true
			arg_45_0.prevX_ = arg_46_0.x
			arg_45_0.prevY_ = arg_46_0.y
		elseif arg_46_0.name == "moved" then
			if math.abs(arg_46_0.y - arg_45_0.prevY_) > 5 or math.abs(arg_46_0.x - arg_45_0.prevX_) > 5 then
				arg_45_0.startClick_ = false
			end
		elseif arg_46_0.name == "ended" and arg_45_0.startClick_ then
			arg_45_0:clickPetAvatar(arg_45_1)
		end

		return true
	end)

	for iter_45_0 = 1, 3 do
		for iter_45_1, iter_45_2 in ipairs(arg_45_0.petTeam_[iter_45_0]) do
			if var_45_0:getPetID() == iter_45_2.data:getPetID() then
				arg_45_0.petTeam_[iter_45_0][iter_45_1].iniCell_ = arg_45_1
				arg_45_1.teamNo_ = iter_45_1

				local var_45_1 = arg_45_1:getChildByName("layout")
				local var_45_2 = var_45_1:getChildByName("avatar_mask")
				local var_45_3 = var_45_1:getChildByName("chosen")

				var_45_2:setVisible(true)
				var_45_3:setVisible(true)

				break
			end
		end
	end
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_47_0, arg_47_1, arg_47_2)
	if arg_47_1.isAnimated_ then
		return
	end

	local var_47_0, var_47_1 = arg_47_0:nodeByName("list_layer"):getPosition()
	local var_47_2 = arg_47_1.iniCell_
	local var_47_3

	for iter_47_0, iter_47_1 in ipairs(arg_47_0.petTeam_[arg_47_0.nowTeamNumber_]) do
		if iter_47_1 == arg_47_1 then
			var_47_3 = iter_47_0

			break
		end
	end

	if not var_47_3 then
		return
	end

	if var_47_2 and not tolua.isnull(var_47_2) then
		local var_47_4 = var_47_2:convertToWorldSpace(cc.p(0, 0))
		local var_47_5 = var_47_2:getChildByName("layout")
		local var_47_6 = var_47_5:getChildByName("avatar_mask")
		local var_47_7 = var_47_5:getChildByName("chosen")

		var_47_6:setVisible(false)
		var_47_7:setVisible(false)
	end

	for iter_47_2 = #arg_47_0.petTeam_[arg_47_0.nowTeamNumber_], var_47_3 + 1, -1 do
		local var_47_8 = arg_47_0.petTeam_[arg_47_0.nowTeamNumber_][iter_47_2]
		local var_47_9, var_47_10 = arg_47_0:nodeByName("avatar_pet" .. iter_47_2 - 1):getPosition()

		transition.stopTarget(var_47_8)
		transition.moveTo(arg_47_0.petTeam_[arg_47_0.nowTeamNumber_][iter_47_2], {
			time = 0.3,
			x = var_47_9,
			y = var_47_10
		})

		arg_47_0.petTeam_[arg_47_0.nowTeamNumber_][iter_47_2].iniCell_.teamNo_ = iter_47_2 - 1
	end

	table.remove(arg_47_0.petTeam_[arg_47_0.nowTeamNumber_], var_47_3)
	table.remove(arg_47_0.petSelect_[arg_47_0.nowTeamNumber_], var_47_3)

	if var_47_2 then
		var_47_2.teamNo_ = nil
	end

	if arg_47_1 and not tolua.isnull(arg_47_1) then
		arg_47_1:removeSelf()
	end

	if arg_47_2 then
		arg_47_2()
	end
end

function var_0_0.initPetBottomCell(arg_48_0, arg_48_1)
	local var_48_0 = display.newNode()

	var_48_0:size(146, 146)
	var_48_0:align(display.CENTER)

	var_48_0.data = arg_48_1

	xyd.setPetAvatar(var_48_0, arg_48_1, 100)

	return var_48_0
end

function var_0_0.clickPetBottomAvatar(arg_49_0, arg_49_1, arg_49_2)
	if arg_49_1.isAnimated_ then
		return
	end

	local var_49_0, var_49_1 = arg_49_0:nodeByName("list_layer"):getPosition()
	local var_49_2 = arg_49_1.iniCell_
	local var_49_3

	for iter_49_0, iter_49_1 in ipairs(arg_49_0.petSelect_[arg_49_0.nowTeamNumber_]) do
		if iter_49_1:getTableID() == arg_49_1.data:getTableID() and iter_49_1.player_name == arg_49_1.data.player_name then
			var_49_3 = iter_49_0

			break
		end
	end

	if not var_49_3 then
		return
	end

	if var_49_2 and not tolua.isnull(var_49_2) then
		local var_49_4 = var_49_2:convertToWorldSpace(cc.p(0, 0))

		var_49_0, var_49_1 = var_49_4.x, var_49_4.y

		local var_49_5 = var_49_2:getChildByName("layout")
		local var_49_6 = var_49_5:getChildByName("avatar_mask")
		local var_49_7 = var_49_5:getChildByName("chosen")

		var_49_6:setVisible(false)
		var_49_7:setVisible(false)
	end

	arg_49_0:moveFadeOutAction(var_49_0, var_49_1, arg_49_1, arg_49_2)

	for iter_49_2 = #arg_49_0.petTeam_[arg_49_0.nowTeamNumber_], var_49_3 + 1, -1 do
		local var_49_8 = arg_49_0.petTeam_[arg_49_0.nowTeamNumber_][iter_49_2]
		local var_49_9, var_49_10 = arg_49_0:nodeByName("avatar_pet" .. iter_49_2 - 1):getPosition()

		transition.stopTarget(var_49_8)
		transition.moveTo(arg_49_0.petTeam_[arg_49_0.nowTeamNumber_][iter_49_2], {
			time = 0.3,
			x = var_49_9,
			y = var_49_10
		})

		arg_49_0.petTeam_[arg_49_0.nowTeamNumber_][iter_49_2].iniCell_.teamNo_ = iter_49_2 - 1
	end

	table.remove(arg_49_0.petTeam_[arg_49_0.nowTeamNumber_], var_49_3)
	table.remove(arg_49_0.petSelect_[arg_49_0.nowTeamNumber_], var_49_3)

	if var_49_2 then
		var_49_2.teamNo_ = nil
	end

	arg_49_0:updateScore(arg_49_0.nowTeamNumber_)
end

function var_0_0.clickPetAvatar(arg_50_0, arg_50_1, arg_50_2, arg_50_3)
	local var_50_0 = arg_50_3 or arg_50_0.nowTeamNumber_

	if not arg_50_2 then
		arg_50_0.unPreSelectPet_[var_50_0] = true
	end

	if arg_50_1.isAnimated_ or not arg_50_1.teamNo_ and #arg_50_0.petTeam_[var_50_0] > xyd.MAX_PET_NUMBER then
		return
	elseif not arg_50_1.teamNo_ and #arg_50_0.petTeam_[var_50_0] == xyd.MAX_PET_NUMBER then
		local var_50_1 = arg_50_0.petTeam_[var_50_0][1]

		arg_50_0:clickPetBottomAvatarWithoutAnimation(var_50_1, function()
			arg_50_0:clickPetAvatar(arg_50_1, arg_50_2)
		end)

		return
	end

	local var_50_2 = arg_50_1:getChildByName("layout")
	local var_50_3 = var_50_2:getChildByName("avatar_mask")
	local var_50_4 = var_50_2:getChildByName("chosen")
	local var_50_5 = arg_50_1:convertToWorldSpace(cc.p(0, 0))
	local var_50_6 = var_50_5.x
	local var_50_7 = var_50_5.y

	arg_50_1.isAnimated_ = true

	if arg_50_1.teamNo_ then
		local var_50_8 = 1

		for iter_50_0 = 1, 3 do
			if arg_50_0.petTeam_[iter_50_0][1] and arg_50_1.data and arg_50_0.petTeam_[iter_50_0][1].data:getTableID() == arg_50_1.data:getTableID() then
				var_50_8 = iter_50_0

				break
			end
		end

		local var_50_9 = arg_50_0.petTeam_[var_50_8][arg_50_1.teamNo_]

		arg_50_0:moveFadeOutAction(var_50_6, var_50_7, var_50_9, function()
			arg_50_1.isAnimated_ = false
		end)
		var_50_3:setVisible(false)
		var_50_4:setVisible(false)

		for iter_50_1 = #arg_50_0.petTeam_[var_50_8], arg_50_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_50_0.petTeam_[var_50_0][iter_50_1])

			local var_50_10, var_50_11 = arg_50_0:nodeByName("avatar_pet" .. iter_50_1 - 1):getPosition()

			transition.moveTo(arg_50_0.petTeam_[var_50_0][iter_50_1], {
				time = 0.3,
				x = var_50_10,
				y = var_50_11
			})

			arg_50_0.petTeam_[var_50_0][iter_50_1].iniCell_.teamNo_ = iter_50_1 - 1
		end

		table.remove(arg_50_0.petTeam_[var_50_8], arg_50_1.teamNo_)
		table.remove(arg_50_0.petSelect_[var_50_8], arg_50_1.teamNo_)

		arg_50_1.teamNo_ = nil
	elseif not arg_50_1.teamNo_ and #arg_50_0.petTeam_[var_50_0] < xyd.MAX_PET_NUMBER then
		local var_50_12 = arg_50_1.data

		if not arg_50_2 and var_0_9:chosenSound(var_50_12:getTableID()) ~= "" then
			audio.playSound(var_0_9:chosenSound(var_50_12:getTableID()), false)
		end

		local var_50_13 = arg_50_0:initPetBottomCell(var_50_12)

		var_50_13.iniCell_ = arg_50_1

		var_50_13:pos(var_50_6, var_50_7)
		var_50_13:addTo(arg_50_0)
		var_50_13:setTouchEnabled(true)
		var_50_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_53_0)
			if arg_53_0.name == "ended" then
				arg_50_0:clickPetBottomAvatar(var_50_13)
			end

			return true
		end)

		arg_50_1.teamNo_ = arg_50_0:getPetTeamNo(var_50_13, var_50_0)

		for iter_50_2 = arg_50_1.teamNo_, #arg_50_0.petTeam_[var_50_0] do
			local var_50_14, var_50_15 = arg_50_0:nodeByName("avatar_pet" .. iter_50_2):getPosition()

			if arg_50_2 then
				arg_50_0.petTeam_[var_50_0][iter_50_2]:pos(var_50_14, var_50_15)

				arg_50_1.isAnimated_ = false
			elseif iter_50_2 ~= arg_50_1.teamNo_ then
				local var_50_16 = arg_50_0.petTeam_[var_50_0][iter_50_2]

				transition.stopTarget(var_50_16)
				transition.moveTo(var_50_16, {
					time = 0.3,
					x = var_50_14,
					y = var_50_15,
					onComplete = function()
						var_50_16.iniCell_.isAnimated_ = false
						var_50_16.isAnimated_ = false
					end
				})
			else
				local var_50_17 = arg_50_0.petTeam_[var_50_0][iter_50_2]

				transition.stopTarget(var_50_17)

				var_50_13.isAnimated_ = true

				transition.moveTo(var_50_17, {
					time = 0.3,
					x = var_50_14,
					y = var_50_15,
					onComplete = function()
						arg_50_1.isAnimated_ = false
						var_50_13.isAnimated_ = false
					end
				})
			end

			arg_50_0.petTeam_[var_50_0][iter_50_2].iniCell_.teamNo_ = iter_50_2
		end

		var_50_3:setVisible(true)
		var_50_4:setVisible(true)
	end

	arg_50_0:updateScore(var_50_0)
end

function var_0_0.getPetTeamNo(arg_56_0, arg_56_1, arg_56_2)
	table.insert(arg_56_0.petTeam_[arg_56_2], arg_56_1)
	table.insert(arg_56_0.petSelect_[arg_56_2], arg_56_1.data)

	return #arg_56_0.petTeam_[arg_56_2]
end

function var_0_0.showHeroCellTeam(arg_57_0, arg_57_1, arg_57_2)
	arg_57_1 = arg_57_1 or 0

	if not arg_57_2 then
		return
	end

	for iter_57_0 = 1, var_0_10 do
		if arg_57_1 == iter_57_0 then
			arg_57_2:getChildByName("team" .. iter_57_0):setVisible(true)
		else
			arg_57_2:getChildByName("team" .. iter_57_0):setVisible(false)
		end
	end
end

function var_0_0.showTeamsByTeamNumber(arg_58_0, arg_58_1)
	for iter_58_0 = 1, var_0_10 do
		if arg_58_1 == iter_58_0 then
			for iter_58_1, iter_58_2 in pairs(arg_58_0.peakTeams_[iter_58_0]) do
				iter_58_2:setVisible(true)
			end

			for iter_58_3, iter_58_4 in pairs(arg_58_0.petTeam_[iter_58_0]) do
				iter_58_4:setVisible(true)
			end
		else
			for iter_58_5, iter_58_6 in pairs(arg_58_0.peakTeams_[iter_58_0]) do
				iter_58_6:setVisible(false)
			end

			for iter_58_7, iter_58_8 in pairs(arg_58_0.petTeam_[iter_58_0]) do
				iter_58_8:setVisible(false)
			end
		end
	end
end

function var_0_0.initBottomCell(arg_59_0, arg_59_1)
	local var_59_0 = display.newNode()
	local var_59_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
	local var_59_2 = var_59_1:getChildByName("background"):getContentSize()

	var_59_1:setContentSize(var_59_2)
	var_59_0:setContentSize(var_59_2)
	xyd.setAvatarBorder(arg_59_1, var_59_1:getChildByName("avatar"))

	local var_59_3 = var_59_1:getChildByName("chosen")

	var_59_3:setLocalZOrder(100)
	var_59_3:setVisible(false)

	local var_59_4 = var_59_1:getChildByName("avatar_mask")

	var_59_4:setLocalZOrder(2)
	var_59_4:setVisible(false)

	for iter_59_0 = 1, 3 do
		var_59_1:getChildByName("team" .. iter_59_0):setVisible(false)
	end

	var_59_1:getChildByName("lv_txt"):setString(arg_59_1:getLevel())

	local var_59_5 = var_59_1:getChildByName("name_text")

	var_59_5:setString(arg_59_1:getName())
	var_59_5:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_59_1:getColor()] ~= "" then
		local var_59_6 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_59_5:getX() + var_59_5:getWidth() / 2 - 10,
			y = var_59_5:getY(),
			color = xyd.color.HERO_QUALITY[arg_59_1:getColor()],
			text = xyd.Color2Level[arg_59_1:getColor()]
		}
		local var_59_7 = xyd.AssetLoader.get():loadLabel(var_59_6)

		var_59_7:addTo(var_59_1)
		var_59_7:align(display.CENTER_LEFT)
		var_59_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_59_5:x(var_59_5:getX() - 15)
	end

	local var_59_8 = var_59_1:getChildByName("hp_bar")
	local var_59_9 = var_59_1:getChildByName("mp_bar")
	local var_59_10 = var_59_1:getChildByName("dead_text")

	var_59_10:setString(var_0_8:translation("ALREADY_DEAD"))

	if var_59_10 then
		var_59_10:setVisible(false)
	end

	local var_59_11 = false

	if arg_59_0.heroStatus_ ~= nil and next(arg_59_0.heroStatus_) then
		local var_59_12 = arg_59_0.heroStatus_[tostring(arg_59_1:getHeroID())]

		if var_59_12 and var_59_12.health then
			local var_59_13 = 0
			local var_59_14 = 0

			if var_59_12.health == 0 then
				var_59_13 = 100
				var_59_14 = 0
			elseif var_59_12.health == 1 then
				var_59_13 = var_59_12.hp / arg_59_1:getMaxHP() * 100
				var_59_14 = var_59_12.mp / 10
			else
				var_59_13 = 0
				var_59_14 = 0

				var_59_4:setVisible(true)
				var_59_10:setLocalZOrder(3)
				var_59_10:setVisible(true)
				var_59_10:enableOutline(cc.c4b(0, 0, 0), 2)
				var_59_10:getVirtualRenderer():setAdditionalKerning(2)

				local var_59_15 = true
			end

			var_59_8:setPercent(var_59_13)
			var_59_8:setVisible(true)
			var_59_9:setPercent(var_59_14)
			var_59_9:setVisible(true)
		end
	else
		var_59_8:hide()
		var_59_9:hide()
		var_59_1:getChildByName("hp_di"):hide()
		var_59_1:getChildByName("mp_di"):hide()
	end

	var_59_1:setName("layout")

	var_59_0.data = arg_59_1

	var_59_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_59_0:addChild(var_59_1)

	return var_59_0
end

function var_0_0.getPets(arg_60_0)
	local var_60_0

	return arg_60_0.selfPlayer.collectedPets
end

function var_0_0.delegate(arg_61_0, ...)
	if arg_61_0.isHeroPreset then
		return arg_61_0:presetDelegate(...)
	end

	if arg_61_0.containerState == var_0_12 then
		return arg_61_0:petDelegate(...)
	end

	return arg_61_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_62_0, arg_62_1, arg_62_2, arg_62_3)
	local var_62_0 = math.ceil(#arg_62_0.totalHero_[arg_62_0.selectedHeroClass_] / var_0_5) + 1

	if cc.ui.UIListView.COUNT_TAG == arg_62_2 then
		return var_62_0
	elseif cc.ui.UIListView.CELL_TAG == arg_62_2 then
		if arg_62_3 == 1 then
			return arg_62_0:addExchangeItem()
		else
			local var_62_1
			local var_62_2
			local var_62_3
			local var_62_4 = arg_62_0.heroList_:dequeueItem()

			if not var_62_4 then
				var_62_4 = arg_62_0.heroList_:newItem()
			else
				var_62_4:removeAllChildren()
			end

			local var_62_5 = display.newNode()

			var_62_5:setTouchSwallowEnabled(false)

			for iter_62_0 = 1, var_0_5 do
				local var_62_6 = (arg_62_3 - 2) * var_0_5 + iter_62_0

				if var_62_6 > #arg_62_0.totalHero_[arg_62_0.selectedHeroClass_] then
					break
				end

				var_62_3 = display.newNode()

				arg_62_0:initHeroCell(var_62_3, var_62_6)

				local var_62_7 = var_62_3:getContentSize().width
				local var_62_8 = var_62_3:getContentSize().height
				local var_62_9 = (arg_62_0.heroList_.viewRect_.width - var_62_7 * var_0_5) / (var_0_5 + 1)

				var_62_3:pos(var_62_9 * iter_62_0 + (iter_62_0 - 1) * var_62_7 + var_62_7 / 2, var_0_4 + var_62_8 / 2)
				var_62_5:addChild(var_62_3)

				arg_62_0.heroCells_[var_62_6] = var_62_3
			end

			var_62_5:setContentSize(cc.size(arg_62_0.heroList_.viewRect_.width, var_62_3:getContentSize().height + var_0_4))
			var_62_4:setItemSize(arg_62_0.heroList_.viewRect_.width, var_62_3:getContentSize().height + var_0_4)
			var_62_4:addContent(var_62_5)

			return var_62_4
		end
	end
end

function var_0_0.presetDelegate(arg_63_0, arg_63_1, arg_63_2, arg_63_3)
	local var_63_0 = #arg_63_0.presetTeams

	if cc.ui.UIListView.COUNT_TAG == arg_63_2 then
		return var_63_0
	elseif cc.ui.UIListView.CELL_TAG == arg_63_2 then
		local var_63_1
		local var_63_2
		local var_63_3
		local var_63_4 = arg_63_0.heroList_:dequeueItem()

		if not var_63_4 then
			var_63_4 = arg_63_0.heroList_:newItem()
		else
			var_63_4:removeAllChildren()
		end

		local var_63_5 = display.newNode()

		var_63_5:setTouchSwallowEnabled(false)

		local var_63_6 = display.newNode()

		arg_63_0:initPresetCell(var_63_6, arg_63_3)
		var_63_5:addChild(var_63_6)
		var_63_5:setContentSize(cc.size(arg_63_0.heroList_.viewRect_.width, var_63_6:getContentSize().height))
		var_63_4:setItemSize(arg_63_0.heroList_.viewRect_.width, var_63_6:getContentSize().height)
		var_63_4:addContent(var_63_5)

		return var_63_4
	end
end

function var_0_0.petDelegate(arg_64_0, arg_64_1, arg_64_2, arg_64_3)
	if arg_64_0.containerState == var_0_12 then
		var_0_6 = 5
	else
		var_0_6 = 4
	end

	local var_64_0 = math.ceil(#arg_64_0.totalPet_ / var_0_6) + 1

	if cc.ui.UIListView.COUNT_TAG == arg_64_2 then
		return var_64_0
	elseif cc.ui.UIListView.CELL_TAG == arg_64_2 then
		if arg_64_3 == 1 then
			return arg_64_0:addExchangeItem()
		else
			local var_64_1
			local var_64_2
			local var_64_3
			local var_64_4 = arg_64_0.heroList_:dequeueItem()

			if not var_64_4 then
				var_64_4 = arg_64_0.heroList_:newItem()
			else
				var_64_4:removeAllChildren()
			end

			local var_64_5 = display.newNode()

			var_64_5:setTouchSwallowEnabled(false)

			for iter_64_0 = 1, var_0_6 do
				local var_64_6 = (arg_64_3 - 2) * var_0_6 + iter_64_0

				if var_64_6 > #arg_64_0.totalPet_ then
					break
				end

				var_64_3 = display.newNode()

				arg_64_0:initPetCell(var_64_3, var_64_6)

				local var_64_7 = var_64_3:getContentSize().width
				local var_64_8 = var_64_3:getContentSize().height
				local var_64_9 = (arg_64_0.heroList_.viewRect_.width - var_64_7 * var_0_6) / (var_0_6 + 1)

				var_64_3:align(display.CENTER, var_64_9 * iter_64_0 + (iter_64_0 - 1) * var_64_7 + var_64_7 / 2, var_64_8 / 2)
				var_64_5:addChild(var_64_3)
			end

			var_64_5:setContentSize(cc.size(arg_64_0.heroList_.viewRect_.width, var_64_3:getContentSize().height))
			var_64_4:setItemSize(arg_64_0.heroList_.viewRect_.width, var_64_3:getContentSize().height)
			var_64_4:addContent(var_64_5)

			return var_64_4
		end
	end
end

function var_0_0.initPresetCell(arg_65_0, arg_65_1, arg_65_2)
	local var_65_0 = arg_65_0.presetTeams[arg_65_2].team
	local var_65_1 = arg_65_0.presetTeams[arg_65_2].teamName
	local var_65_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list/hero_preset/preset_item_2.csb")
	local var_65_3 = var_65_2:getChildByName("container")
	local var_65_4 = var_65_3:getContentSize()

	arg_65_1:setContentSize(var_65_4.width, var_65_4.height + 10)
	var_65_2:addTo(arg_65_1)
	var_65_3:getChildByName("text_name"):setString(var_65_1)

	local var_65_5 = var_65_3:getChildByName("hero_list")
	local var_65_6 = 0

	for iter_65_0 = 1, #var_65_0 do
		local var_65_7 = var_65_0[iter_65_0]
		local var_65_8 = display.newNode()

		var_65_8:setContentSize(var_0_7, var_0_7)
		xyd.setAvatarBorder(var_65_7, var_65_8)
		var_65_8:addTo(var_65_5)
		var_65_8:setPositionX(var_65_6)
		var_65_8:setName("layout")

		var_65_8.data = var_65_7
		var_65_6 = var_65_6 + var_0_7 + 10

		local var_65_9 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")

		var_65_9:addTo(var_65_8)
		var_65_9:setPosition(cc.p(0, 0))
		var_65_9:setAnchorPoint(cc.p(0, 0))
		var_65_9:setName("avatar_mask")
		var_65_9:setScale(var_0_7 / var_65_9:getWidth())
		var_65_9:setVisible(false)
		var_65_9:setLocalZOrder(10)

		for iter_65_1 = 1, 3 do
			local var_65_10 = xyd.AssetLoader:get():loadSprite("windows/common/team" .. iter_65_1 .. ".png")

			var_65_10:addTo(var_65_8)
			var_65_10:setAnchorPoint(cc.p(0.5, 1))
			var_65_10:setPosition(cc.p(var_0_7 / 2, var_0_7 - 5))
			var_65_10:setName("team" .. iter_65_1)
			var_65_10:setScale(0.8)
			var_65_10:setVisible(false)
		end

		var_65_7.isUsed = false

		for iter_65_2 = 1, var_0_10 do
			for iter_65_3, iter_65_4 in ipairs(arg_65_0.peakSelectTeams_[iter_65_2]) do
				if iter_65_4:getTableID() == var_65_7:getTableID() then
					var_65_9:setVisible(true)
					arg_65_0:showHeroCellTeam(iter_65_2, var_65_8)

					var_65_7.isUsed = true

					break
				end
			end
		end

		if not arg_65_0.presetTeamCells[arg_65_2] then
			arg_65_0.presetTeamCells[arg_65_2] = {}
		end

		arg_65_0.presetTeamCells[arg_65_2][iter_65_0] = var_65_8
	end

	var_65_3:getChildByName("btn_use"):addTouchEventListener(function(arg_66_0, arg_66_1)
		if arg_66_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_65_0:checkPresetTeamCanUse(arg_65_2) then
				arg_65_0.preSelectTeams_[arg_65_0.nowTeamNumber_] = var_65_0
				arg_65_0.unPreSelect_[arg_65_0.nowTeamNumber_] = false

				arg_65_0:showPresetTeam()
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_8:translation("PRESET_MEMBER_IN_USE")
				})
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_67_0)
	local var_67_0 = arg_67_0.peakTeams_[arg_67_0.nowTeamNumber_]

	arg_67_0.peakSelectTeams_[arg_67_0.nowTeamNumber_] = {}
	arg_67_0.peakTeams_[arg_67_0.nowTeamNumber_] = {}

	arg_67_0:initPreHeros(true)
	arg_67_0:updateScore(arg_67_0.nowTeamNumber_)
	arg_67_0:changePresetTeamStatus()

	local var_67_1 = arg_67_0.peakTeams_[arg_67_0.nowTeamNumber_]

	arg_67_0.isPresetAnimation = true

	local var_67_2 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_68_0 = 1, #var_67_0 do
				local var_68_0 = var_67_0[iter_68_0]
				local var_68_1, var_68_2 = arg_67_0:nodeByName("avatar" .. iter_68_0):getPosition()

				arg_67_0:moveFadeOutAction(var_68_1, var_68_2, var_68_0)
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_67_3 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_69_0 = 1, #var_67_1 do
				local var_69_0 = var_67_1[iter_69_0]

				var_69_0:show()

				local var_69_1, var_69_2 = arg_67_0:nodeByName("avatar" .. iter_69_0):getPosition()

				arg_67_0:moveFadeInAction(var_69_1, var_69_2, var_69_0, function()
					arg_67_0.isPresetAnimation = false
				end)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_67_0:runAction(transition.sequence({
		var_67_2,
		var_67_3
	}))
end

function var_0_0.addExchangeItem(arg_71_0)
	local var_71_0
	local var_71_1
	local var_71_2
	local var_71_3 = arg_71_0.heroList_:dequeueItem()

	if not var_71_3 then
		var_71_3 = arg_71_0.heroList_:newItem()
	else
		var_71_3:removeAllChildren()
	end

	local var_71_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/exchange_select_item.csb")
	local var_71_5 = var_71_4:getChildByName("container")

	local function var_71_6()
		if arg_71_0.containerState == var_0_12 then
			var_71_5:getChildByName("hero_btn"):setBrightStyle(ccui.BrightStyle.highlight)
			var_71_5:getChildByName("pet_btn"):setBrightStyle(ccui.BrightStyle.normal)
		else
			var_71_5:getChildByName("pet_btn"):setBrightStyle(ccui.BrightStyle.highlight)
			var_71_5:getChildByName("hero_btn"):setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	var_71_5:getChildByName("hero_btn"):addTouchEventListener(function(arg_73_0, arg_73_1)
		if arg_73_1 == ccui.TouchEventType.ended and arg_71_0.containerState == var_0_12 then
			xyd.playTabButtonSound()

			arg_71_0.containerState = var_0_11

			arg_71_0:refreshSelectedHeroClass(true)
		end
	end)
	var_71_5:getChildByName("pet_btn"):addTouchEventListener(function(arg_74_0, arg_74_1)
		if arg_74_1 == ccui.TouchEventType.ended and arg_71_0.containerState == var_0_11 then
			xyd.playTabButtonSound()

			arg_71_0.containerState = var_0_12

			arg_71_0:refreshSelectedHeroClass(true)
		end
	end)

	local var_71_7 = display.newNode()

	var_71_7:addChild(var_71_4)
	var_71_7:setContentSize(cc.size(var_71_5:getWidth(), var_71_5:getHeight()))
	var_71_3:setItemSize(var_71_5:getWidth(), var_71_5:getHeight())
	var_71_3:addContent(var_71_7)
	var_71_6()

	return var_71_3
end

function var_0_0.initPresetTeams(arg_75_0)
	arg_75_0.presetTeams = clone(arg_75_0.selfPlayer:getSaveTeams())
end

function var_0_0.checkHeroSelected(arg_76_0, arg_76_1)
	for iter_76_0 = 1, var_0_10 do
		for iter_76_1, iter_76_2 in ipairs(arg_76_0.peakSelectTeams_[iter_76_0]) do
			if iter_76_2:getTableID() == arg_76_1:getTableID() then
				return true, iter_76_0
			end
		end
	end

	return false, 0
end

function var_0_0.changePresetTeamStatus(arg_77_0)
	if arg_77_0.presetTeamCells and next(arg_77_0.presetTeamCells) then
		for iter_77_0, iter_77_1 in pairs(arg_77_0.presetTeamCells) do
			for iter_77_2, iter_77_3 in pairs(iter_77_1) do
				if iter_77_3 and iter_77_3.data then
					local var_77_0 = iter_77_3.data
					local var_77_1, var_77_2 = arg_77_0:checkHeroSelected(var_77_0)

					var_77_0.isUsed = var_77_1

					iter_77_3:getChildByName("avatar_mask"):setVisible(var_77_1)
					arg_77_0:showHeroCellTeam(var_77_2, iter_77_3)
				end
			end
		end
	end
end

function var_0_0.checkPresetTeamCanUse(arg_78_0, arg_78_1)
	local var_78_0 = arg_78_0.presetTeams[arg_78_1].team

	for iter_78_0 = 1, #var_78_0 do
		local var_78_1 = var_78_0[iter_78_0]

		if var_78_1.isUsed or not arg_78_0:isSpecifyHero(var_78_1) or var_78_1:getLevel() < xyd.tables.battle:levLimit(arg_78_0.campaignID) then
			return false
		end
	end

	return true
end

function var_0_0.refreshSelectedHeroClass(arg_79_0, arg_79_1)
	if arg_79_1 then
		arg_79_0.preSelectTeams_ = {}
		arg_79_0.prePet_ = {}
	end

	for iter_79_0 = 1, #arg_79_0.heroClassButtons_ do
		if iter_79_0 == arg_79_0.selectedHeroClass_ then
			arg_79_0.heroClassButtons_[iter_79_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_79_0.heroClassButtons_[iter_79_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_79_0.heroList_:removeAllItems()
	arg_79_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.normal)

	if arg_79_0.selectedHeroClass_ == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_79_0.selectedHeroClass_ ~= xyd.DistanceType.ALL then
		for iter_79_1, iter_79_2 in ipairs(arg_79_0.peakSelectTeams_[arg_79_0.nowTeamNumber_]) do
			if iter_79_2:getDistanceType() ~= arg_79_0.selectedHeroClass_ then
				arg_79_0.peakTeams_[arg_79_0.nowTeamNumber_][iter_79_1].iniCellVisible_ = true
			end
		end
	end

	arg_79_0:initPreHeros()
	arg_79_0.heroList_:reload()
	arg_79_0:showTeamsByTeamNumber(arg_79_0.nowTeamNumber_)

	arg_79_0.preSelectTeams_[arg_79_0.nowTeamNumber_] = nil
	arg_79_0.prePet_[arg_79_0.nowTeamNumber_] = nil
end

function var_0_0.refreshSelectTeamClass(arg_80_0)
	for iter_80_0 = 1, #arg_80_0.teamButtons_ do
		if iter_80_0 == arg_80_0.nowTeamNumber_ then
			arg_80_0.teamButtons_[iter_80_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_80_0.teamButtons_[iter_80_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.buttonHandler(arg_81_0, arg_81_1, arg_81_2, arg_81_3)
	if not arg_81_2 or not arg_81_2:getParent() then
		return
	end

	if arg_81_3.name == "ended" then
		transition.stopTarget(arg_81_2)
		arg_81_2:setScale(1)

		if arg_81_1 then
			arg_81_1(arg_81_2, eventType)
		end
	elseif arg_81_3.name == "began" then
		local var_81_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_81_2:runAction(var_81_0)

		return true
	elseif arg_81_3.name == "cancled" then
		transition.stopTarget(arg_81_2)
		arg_81_2:setScale(1)
	end
end

function var_0_0.initPreHeros(arg_82_0, arg_82_1)
	if arg_82_0.preSelectTeams_ then
		for iter_82_0 = 1, var_0_10 do
			if arg_82_0.preSelectTeams_[iter_82_0] and next(arg_82_0.preSelectTeams_[iter_82_0]) and not arg_82_0.unPreSelect_[iter_82_0] then
				for iter_82_1, iter_82_2 in pairs(arg_82_0.preSelectTeams_[iter_82_0]) do
					local var_82_0 = display.newNode()
					local var_82_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
					local var_82_2 = var_82_1:getChildByName("background"):getContentSize()

					var_82_1:setContentSize(var_82_2)
					var_82_0:setContentSize(var_82_2)
					xyd.setAvatarBorder(iter_82_2, var_82_1:getChildByName("avatar"))
					var_82_1:setName("layout")

					var_82_0.data = iter_82_2
					var_82_0.invisible = arg_82_1

					var_82_0:addChild(var_82_1)
					var_82_0:setTouchSwallowEnabled(false)
					var_82_0:setTouchEnabled(true)
					arg_82_0:showHeroCellTeam(var_82_0.teamCount_, var_82_0:getChildByName("layout"))
					arg_82_0:clickAvatar(var_82_0, true, iter_82_0)
				end
			end
		end
	end

	if arg_82_0.prePet_ then
		for iter_82_3 = 1, var_0_10 do
			if arg_82_0.prePet_[iter_82_3] and next(arg_82_0.prePet_[iter_82_3]) and not arg_82_0.unPreSelectPet_[iter_82_3] then
				for iter_82_4, iter_82_5 in pairs(arg_82_0.prePet_[iter_82_3]) do
					local var_82_3 = display.newNode()
					local var_82_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
					local var_82_5 = var_82_4:getChildByName("background"):getContentSize()

					var_82_4:setContentSize(var_82_5)
					var_82_3:setContentSize(var_82_5)
					xyd.setPetAvatar(var_82_4:getChildByName("avatar"), iter_82_5)
					var_82_4:setName("layout")

					var_82_3.data = iter_82_5

					var_82_3:addChild(var_82_4)
					var_82_3:setTouchSwallowEnabled(false)
					var_82_3:setTouchEnabled(true)
					arg_82_0:showHeroCellTeam(var_82_3.teamCount_, var_82_3:getChildByName("layout"))
					arg_82_0:clickPetAvatar(var_82_3, true, iter_82_3)
				end
			end
		end
	end

	arg_82_0.prePet_ = {}
	arg_82_0.preSelectTeams_ = {}
end

function var_0_0.clickAvatar(arg_83_0, arg_83_1, arg_83_2, arg_83_3)
	if arg_83_1.isAnimated_ or not arg_83_1.teamNo_ and #arg_83_0.peakTeams_[arg_83_3] >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if not arg_83_2 then
		arg_83_0.unPreSelect_[arg_83_3] = true
	end

	local var_83_0 = arg_83_1:getChildByName("layout")
	local var_83_1 = var_83_0:getChildByName("avatar_mask")
	local var_83_2 = var_83_0:getChildByName("chosen")
	local var_83_3 = arg_83_1:convertToWorldSpace(cc.p(0, 0))
	local var_83_4 = var_83_3.x + arg_83_1:getContentSize().width / 2
	local var_83_5 = var_83_3.y + arg_83_1:getContentSize().height / 2

	arg_83_1.isAnimated_ = true

	if arg_83_1.teamNo_ and arg_83_1.teamCount_ then
		if arg_83_1.teamCount_ ~= arg_83_3 then
			if #arg_83_0.peakTeams_[arg_83_3] >= 5 then
				arg_83_1.isAnimated_ = false

				return
			end

			local var_83_6 = string.format(var_0_8:translation("PEAK_SELECT_TEAM_TIP"), xyd.tables.hero:name(arg_83_1.data:getTableID()))

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_83_6, function()
				for iter_84_0 = #arg_83_0.peakTeams_[arg_83_1.teamCount_], arg_83_1.teamNo_ + 1, -1 do
					local var_84_0 = arg_83_0.peakTeams_[arg_83_1.teamCount_][iter_84_0]
					local var_84_1, var_84_2 = arg_83_0:nodeByName("avatar" .. iter_84_0 - 1):getPosition()

					transition.stopTarget(var_84_0)
					transition.moveTo(arg_83_0.peakTeams_[arg_83_1.teamCount_][iter_84_0], {
						time = 0.3,
						x = var_84_1,
						y = var_84_2
					})

					arg_83_0.peakTeams_[arg_83_1.teamCount_][iter_84_0].iniCell_.teamNo_ = iter_84_0 - 1
				end

				table.remove(arg_83_0.peakTeams_[arg_83_1.teamCount_], arg_83_1.teamNo_)
				table.remove(arg_83_0.peakSelectTeams_[arg_83_1.teamCount_], arg_83_1.teamNo_)
				arg_83_0:refreshTeamHeroNum(arg_83_1.teamCount_, #arg_83_0.peakTeams_[arg_83_1.teamCount_])
				arg_83_0:avatarToBottom(arg_83_1, var_83_4, var_83_5, var_83_1, var_83_2, arg_83_2, arg_83_3)
			end, {
				lcallback = function()
					arg_83_1.isAnimated_ = false
				end
			}, nil, arg_83_0.colorMode)
		else
			local var_83_7 = arg_83_0.peakTeams_[arg_83_3][arg_83_1.teamNo_]

			arg_83_0:moveFadeOutAction(var_83_4, var_83_5, var_83_7, function()
				arg_83_1.isAnimated_ = false
			end)
			var_83_1:setVisible(false)
			var_83_2:setVisible(false)

			for iter_83_0 = #arg_83_0.peakTeams_[arg_83_3], arg_83_1.teamNo_ + 1, -1 do
				transition.stopTarget(arg_83_0.peakTeams_[arg_83_3][iter_83_0])

				local var_83_8, var_83_9 = arg_83_0:nodeByName("avatar" .. iter_83_0 - 1):getPosition()

				transition.moveTo(arg_83_0.peakTeams_[arg_83_3][iter_83_0], {
					time = 0.3,
					x = var_83_8,
					y = var_83_9
				})

				arg_83_0.peakTeams_[arg_83_3][iter_83_0].iniCell_.teamNo_ = iter_83_0 - 1
			end

			arg_83_0:showHeroCellTeam(0, arg_83_1:getChildByName("layout"))
			table.remove(arg_83_0.peakTeams_[arg_83_3], arg_83_1.teamNo_)
			table.remove(arg_83_0.peakSelectTeams_[arg_83_3], arg_83_1.teamNo_)
			arg_83_0:refreshTeamHeroNum(arg_83_3, #arg_83_0.peakTeams_[arg_83_3])

			arg_83_1.teamNo_ = nil
			arg_83_1.teamCount_ = nil
		end
	elseif not arg_83_1.teamNo_ and #arg_83_0.peakTeams_[arg_83_3] < xyd.MAX_TEAM_MEMBER_NUM then
		arg_83_0:avatarToBottom(arg_83_1, var_83_4, var_83_5, var_83_1, var_83_2, arg_83_2, arg_83_3)
	end

	arg_83_0:updateScore(arg_83_3)
end

function var_0_0.refreshTeamHeroNum(arg_87_0, arg_87_1, arg_87_2)
	for iter_87_0 = 0, 5 do
		if iter_87_0 == arg_87_2 then
			arg_87_0:nodeByName("team" .. arg_87_1 .. "_" .. iter_87_0):setVisible(true)
		else
			arg_87_0:nodeByName("team" .. arg_87_1 .. "_" .. iter_87_0):setVisible(false)
		end
	end
end

function var_0_0.avatarToBottom(arg_88_0, arg_88_1, arg_88_2, arg_88_3, arg_88_4, arg_88_5, arg_88_6, arg_88_7)
	if not arg_88_6 then
		local var_88_0 = arg_88_1.data

		if var_0_9:chosenSound(var_88_0:getTableID()) ~= "" then
			audio.playSound(var_0_9:chosenSound(var_88_0:getTableID()), false)
		end
	end

	local var_88_1 = arg_88_0:initBottomCell(arg_88_1.data)

	if arg_88_1.invisible then
		var_88_1:hide()

		arg_88_1.invisible = false
	end

	var_88_1.iniCell_ = arg_88_1

	var_88_1:pos(arg_88_2, arg_88_3)
	var_88_1:addTo(arg_88_0)
	var_88_1:setTouchEnabled(true)
	var_88_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_89_0)
		if arg_89_0.name == "ended" then
			arg_88_0:clickBottomAvatar(var_88_1, arg_88_7)
		end

		return true
	end)

	arg_88_1.teamNo_ = arg_88_0:getTeamNo(var_88_1, arg_88_7)
	arg_88_1.teamCount_ = arg_88_7

	arg_88_0:showHeroCellTeam(arg_88_1.teamCount_, arg_88_1:getChildByName("layout"))

	for iter_88_0 = arg_88_1.teamNo_, #arg_88_0.peakTeams_[arg_88_7] do
		local var_88_2, var_88_3 = arg_88_0:nodeByName("avatar" .. iter_88_0):getPosition()

		if arg_88_6 then
			arg_88_0.peakTeams_[arg_88_7][iter_88_0]:pos(var_88_2, var_88_3)

			arg_88_1.isAnimated_ = false
		elseif iter_88_0 ~= arg_88_1.teamNo_ then
			local var_88_4 = arg_88_0.peakTeams_[arg_88_7][iter_88_0]

			transition.stopTarget(var_88_4)
			transition.moveTo(var_88_4, {
				time = 0.3,
				x = var_88_2,
				y = var_88_3,
				onComplete = function()
					var_88_4.iniCell_.isAnimated_ = false
					var_88_4.isAnimated_ = false
				end
			})
		else
			local var_88_5 = arg_88_0.peakTeams_[arg_88_7][iter_88_0]

			transition.stopTarget(var_88_5)

			var_88_1.isAnimated_ = true

			transition.moveTo(var_88_5, {
				time = 0.3,
				x = var_88_2,
				y = var_88_3,
				onComplete = function()
					arg_88_1.isAnimated_ = false
					var_88_1.isAnimated_ = false
				end
			})
		end

		arg_88_0.peakTeams_[arg_88_7][iter_88_0].iniCell_.teamNo_ = iter_88_0
	end

	arg_88_4:setVisible(true)
	arg_88_5:setVisible(true)
end

function var_0_0.updateScore(arg_92_0, arg_92_1)
	arg_92_0.scores_[arg_92_1] = 0

	for iter_92_0, iter_92_1 in ipairs(arg_92_0.peakTeams_[arg_92_1]) do
		local var_92_0 = iter_92_1.data

		arg_92_0.scores_[arg_92_1] = arg_92_0.scores_[arg_92_1] + var_92_0:getZhandouli()
	end

	for iter_92_2, iter_92_3 in ipairs(arg_92_0.petTeam_[arg_92_1]) do
		local var_92_1 = iter_92_3.data

		arg_92_0.scores_[arg_92_1] = arg_92_0.scores_[arg_92_1] + var_92_1:getZhandouli()
	end

	arg_92_0:nodeByName("zhandouli"):setString(arg_92_0.scores_[arg_92_0.nowTeamNumber_])
end

function var_0_0.clickBottomAvatar(arg_93_0, arg_93_1, arg_93_2)
	if arg_93_1.isAnimated_ or arg_93_0.switchMode == 1 then
		return
	end

	local var_93_0, var_93_1 = arg_93_0:nodeByName("list_layer"):getPosition()
	local var_93_2 = arg_93_1.iniCell_
	local var_93_3

	for iter_93_0, iter_93_1 in ipairs(arg_93_0.peakSelectTeams_[arg_93_2]) do
		if iter_93_1:getTableID() == arg_93_1.data:getTableID() then
			var_93_3 = iter_93_0

			break
		end
	end

	if not var_93_3 then
		return
	end

	if not arg_93_1.iniCellVisible_ and not tolua.isnull(var_93_2) then
		local var_93_4 = var_93_2:convertToWorldSpace(cc.p(0, 0))

		var_93_0, var_93_1 = var_93_4.x + var_93_2:getContentSize().width / 2, var_93_4.y + var_93_2:getContentSize().height / 2

		local var_93_5 = var_93_2:getChildByName("layout")
		local var_93_6 = var_93_5:getChildByName("avatar_mask")
		local var_93_7 = var_93_5:getChildByName("chosen")

		var_93_6:setVisible(false)
		var_93_7:setVisible(false)
		arg_93_0:showHeroCellTeam(0, var_93_5)
	end

	arg_93_0:moveFadeOutAction(var_93_0, var_93_1, arg_93_1)

	for iter_93_2 = #arg_93_0.peakTeams_[arg_93_2], var_93_3 + 1, -1 do
		local var_93_8 = arg_93_0.peakTeams_[arg_93_2][iter_93_2]
		local var_93_9, var_93_10 = arg_93_0:nodeByName("avatar" .. iter_93_2 - 1):getPosition()

		transition.stopTarget(var_93_8)
		transition.moveTo(arg_93_0.peakTeams_[arg_93_2][iter_93_2], {
			time = 0.3,
			x = var_93_9,
			y = var_93_10
		})

		arg_93_0.peakTeams_[arg_93_2][iter_93_2].iniCell_.teamNo_ = iter_93_2 - 1
	end

	table.remove(arg_93_0.peakTeams_[arg_93_2], var_93_3)
	table.remove(arg_93_0.peakSelectTeams_[arg_93_2], var_93_3)
	arg_93_0:refreshTeamHeroNum(arg_93_2, #arg_93_0.peakTeams_[arg_93_2])

	var_93_2.teamNo_ = nil
	var_93_2.teamCount_ = nil

	arg_93_0:updateScore(arg_93_2)

	if arg_93_0.isHeroPreset then
		arg_93_0:changePresetTeamStatus()
	end
end

function var_0_0.getTeamNo(arg_94_0, arg_94_1, arg_94_2)
	for iter_94_0, iter_94_1 in ipairs(arg_94_0.peakTeams_[arg_94_2]) do
		if arg_94_1.data:getDistance() < iter_94_1.data:getDistance() then
			table.insert(arg_94_0.peakTeams_[arg_94_2], iter_94_0, arg_94_1)
			table.insert(arg_94_0.peakSelectTeams_[arg_94_2], iter_94_0, arg_94_1.data)
			arg_94_0:refreshTeamHeroNum(arg_94_2, #arg_94_0.peakTeams_[arg_94_2])

			return iter_94_0
		end
	end

	table.insert(arg_94_0.peakTeams_[arg_94_2], arg_94_1)
	table.insert(arg_94_0.peakSelectTeams_[arg_94_2], arg_94_1.data)
	arg_94_0:refreshTeamHeroNum(arg_94_2, #arg_94_0.peakTeams_[arg_94_2])

	return #arg_94_0.peakTeams_[arg_94_2]
end

function var_0_0.widgetSet(arg_95_0, arg_95_1)
	if arg_95_1 and arg_95_1:getChildren() then
		for iter_95_0, iter_95_1 in ipairs(arg_95_1:getChildren()) do
			if iter_95_1 ~= nil then
				iter_95_1:setCascadeOpacityEnabled(true)
				arg_95_0:widgetSet(iter_95_1)
			end
		end
	end
end

function var_0_0.moveFadeOutAction(arg_96_0, arg_96_1, arg_96_2, arg_96_3, arg_96_4)
	arg_96_0:widgetSet(arg_96_3)
	arg_96_3:setCascadeOpacityEnabled(true)

	local var_96_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_96_1, arg_96_2)))

	arg_96_3:runActionOnce(var_96_0, true, arg_96_4)
end

function var_0_0.moveFadeInAction(arg_97_0, arg_97_1, arg_97_2, arg_97_3, arg_97_4)
	arg_97_0:widgetSet(arg_97_3)
	arg_97_3:setCascadeOpacityEnabled(true)
	arg_97_3:setOpacity(0)

	local var_97_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_97_1, arg_97_2)))

	arg_97_3:runActionOnce(var_97_0, false, arg_97_4)
end

function var_0_0.getBattleBtn(arg_98_0)
	if not arg_98_0.battleBtn_ then
		if arg_98_0.type == xyd.SelectTeamType.PEAK_ARENA_DEFENSE then
			arg_98_0.battleBtn_ = arg_98_0:nodeByName("button_ok")

			arg_98_0.battleBtn_:addTouchEventListener(function(arg_99_0, arg_99_1)
				arg_98_0:checkTeamValid()

				if arg_99_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()
					arg_98_0.peakArena:refreshDefenseTeam(arg_98_0.peakSelectTeams_, arg_98_0.petSelect_)
					xyd.WindowManager.get():closeWindow("select_team_peak_old")
				end
			end)
		else
			arg_98_0.battleBtn_ = arg_98_0:nodeByName("button_battle")

			arg_98_0.battleBtn_:addTouchEventListener(function(arg_100_0, arg_100_1)
				if arg_98_0:checkTeamValid() then
					return
				end

				if arg_100_1 == ccui.TouchEventType.ended and not arg_98_0.battleBegan then
					xyd.playButtonSound()

					arg_98_0.battleBegan = true

					arg_98_0:startBattle()
				end
			end)
		end
	end

	return arg_98_0.battleBtn_
end

function var_0_0.checkTeamValid(arg_101_0)
	if #arg_101_0.peakSelectTeams_[arg_101_0.nowTeamNumber_] < 1 then
		local var_101_0 = string.format(var_0_8:translation("PEAK_SELECT_TEAM_TIP_2"), arg_101_0.nowTeamNumber_)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_101_0, nil, nil, nil, arg_101_0.colorMode)

		return true
	end

	for iter_101_0 = 1, var_0_10 do
		if #arg_101_0.peakSelectTeams_[iter_101_0] < 1 then
			local var_101_1 = string.format(var_0_8:translation("PEAK_SELECT_TEAM_TIP_2"), iter_101_0)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_101_1, nil, nil, nil, arg_101_0.colorMode)

			return true
		end
	end
end

function var_0_0.recordFormation(arg_102_0)
	arg_102_0.peakArena:setAttackTeams(arg_102_0.peakSelectTeams_)
	arg_102_0.peakArena:setEnemyMatched(arg_102_0.enemyMatched_)

	local var_102_0 = arg_102_0.peakArena:generatePartnerIds(arg_102_0.peakSelectTeams_)
	local var_102_1 = arg_102_0.peakArena:generatePartnerIds(arg_102_0.petSelect_, true)
	local var_102_2 = ""

	for iter_102_0 = 1, #var_102_0 do
		if iter_102_0 == #var_102_0 then
			var_102_2 = var_102_2 .. var_102_0[iter_102_0]
		else
			var_102_2 = var_102_2 .. var_102_0[iter_102_0] .. ","
		end
	end

	local var_102_3 = ""

	for iter_102_1 = 1, #var_102_1 do
		if iter_102_1 == #var_102_1 then
			var_102_3 = var_102_3 .. var_102_1[iter_102_1]
		else
			var_102_3 = var_102_3 .. var_102_1[iter_102_1] .. ","
		end
	end

	if var_102_3 ~= "" then
		var_102_2 = var_102_2 .. "," .. var_102_3
	end

	local var_102_4 = arg_102_0.campaignType

	xyd.db.formation:setFormationData(var_102_4, var_102_2)
end

function var_0_0.startBattle(arg_103_0)
	if next(arg_103_0.peakTeams_) == nil then
		return
	end

	if arg_103_0.type == xyd.SelectTeamType.PEAK_ARENA then
		print(11111111)
		arg_103_0:recordFormation()
		print(22222222)
		arg_103_0:startPeakArenaBattle()
	end
end

function var_0_0.startPeakArenaBattle(arg_104_0)
	local var_104_0 = {}
	local var_104_1 = arg_104_0.peakArena:generatePartnerIds(arg_104_0.peakSelectTeams_)
	local var_104_2 = arg_104_0.peakArena:generatePartnerIds(arg_104_0.petSelect_, true)

	var_104_0.team1 = var_104_1[1]
	var_104_0.team2 = var_104_1[2]
	var_104_0.team3 = var_104_1[3]
	var_104_0.pet1 = var_104_2[1]
	var_104_0.pet2 = var_104_2[2]
	var_104_0.pet3 = var_104_2[3]
	var_104_0.enemy_id = arg_104_0.enemyID_

	xyd.Backend.get():request(xyd.mid.OLD_PEAK_PRE_START_FIGHT, {}, function(arg_105_0, arg_105_1)
		if arg_105_0 == xyd.error.OK then
			xyd.Backend.get():request(xyd.mid.OLD_PEAK_START_FIGHT, var_104_0, function(arg_106_0, arg_106_1)
				if arg_106_0 == xyd.error.OK then
					print(33333333)

					if arg_106_1.error_code then
						if arg_106_1.error_code == 30002 then
							local var_106_0 = xyd.tables.message:getContent(30002)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_106_0
							})

							return
						elseif arg_106_1.error_code == 30003 then
							local var_106_1 = xyd.tables.message:getContent(30003)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_106_1
							})

							return
						end
					end

					local var_106_2 = {
						reports = {}
					}

					for iter_106_0, iter_106_1 in pairs(arg_106_1.reports) do
						var_106_2.reports[iter_106_0] = {}
						var_106_2.reports[iter_106_0].content = iter_106_1

						if json.decode(iter_106_1).star > 0 then
							var_106_2.reports[iter_106_0].win = 1
						else
							var_106_2.reports[iter_106_0].win = 0
						end
					end

					if arg_106_1.partner_favor then
						xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY):refreshPartnersFavor(arg_106_1.partner_favor)
					end

					var_106_2.attackerName = arg_104_0.selfPlayer.playerName
					var_106_2.attackerLev = arg_104_0.selfPlayer.lev
					var_106_2.attackerConquerLev = arg_104_0.selfPlayer.conquerLev
					var_106_2.attackerConquerLoopID = arg_104_0.selfPlayer.conquerLoopID
					var_106_2.attackerAvatar = arg_104_0.selfPlayer.avatarId or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
					var_106_2.attackerAvatarFrame = arg_104_0.selfPlayer.avatarFrame
					var_106_2.defenderName = arg_104_0.enemyName
					var_106_2.defenderLev = arg_104_0.enemyLev
					var_106_2.defenderConquerLev = arg_104_0.enemyConquerLev
					var_106_2.defenderConquerLoopID = arg_104_0.enemyConquerLoopID
					var_106_2.defenderAvatar = arg_104_0.enemyAvatar or xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
					var_106_2.defenderAvatarFrame = arg_104_0.enemyAvatarFrame
					var_106_2.noJson = true
					var_106_2.win = arg_106_1.is_win
					var_106_2.withWin = true
					var_106_2.fromSelectPeak = true

					if arg_106_1.items then
						var_106_2.awards = {}

						for iter_106_2, iter_106_3 in pairs(arg_106_1.items) do
							local var_106_3 = {
								table_id = iter_106_3.item_id,
								item_num = iter_106_3.item_num
							}

							table.insert(var_106_2.awards, var_106_3)
						end
					end

					xyd.WindowManager.get():closeWindow("peak_arena_old")
					arg_104_0.peakArena:loadPeakArena(function(arg_107_0)
						if arg_107_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("peak_arena_report_old", var_106_2)
							xyd.WindowManager.get():openWindow("peak_arena_old")
							xyd.WindowManager.get():closeWindow("change_enemy_old")
							xyd.WindowManager.get():closeWindow("select_team_peak_old")
						end
					end)
				else
					arg_104_0.battleBegan = false
				end
			end)
		end
	end)
end

function var_0_0.size(arg_108_0, arg_108_1, arg_108_2)
	return {
		width = arg_108_1,
		height = arg_108_2
	}
end

return var_0_0
