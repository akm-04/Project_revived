local var_0_0 = class("SelectPeakTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc
local var_0_4 = xyd.tables.hero
local var_0_5 = 30
local var_0_6 = 16
local var_0_7 = 7
local var_0_8 = 6
local var_0_9 = 108
local var_0_10 = 146
local var_0_11 = {
	PET = 2,
	HERO = 1
}
local var_0_12 = tonumber(var_0_3:getValue("legend_preparation_time"))
local var_0_13 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.PEAK_ARENA
	arg_1_0.campaignType = arg_1_2.campaignType or xyd.CampaignType.SUPER_ARENA
	arg_1_0.enemyTeams = arg_1_2.enemyTeams
	arg_1_0.enemyMatched = arg_1_2.matchedEnemy

	if arg_1_0.enemyMatched then
		arg_1_0.enemyInfo = arg_1_0.enemyMatched.player_info
	end

	arg_1_0.presetTeamCells = {}
	arg_1_0.presetTeamPetCells = {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)
	arg_1_0.selectItems = {}
	arg_1_0.selectTeams = {}
	arg_1_0.scores = {}

	if arg_1_0.enemyTeams then
		arg_1_0.teamNum = #arg_1_0.enemyTeams
	else
		arg_1_0.teamNum = arg_1_0.peakArena.teamNum
	end

	for iter_1_0 = 1, arg_1_0.teamNum do
		table.insert(arg_1_0.selectItems, {
			heros = {}
		})
		table.insert(arg_1_0.selectTeams, {
			heros = {}
		})
		table.insert(arg_1_0.scores, 0)
	end

	arg_1_0.containerState = var_0_11.HERO
	arg_1_0.nowTeamNumber_ = 1
	arg_1_0.switchMode = 0
	arg_1_0.collocationType_ = var_0_13.NO
	arg_1_0.preSelectTeams_ = arg_1_2.selectedTeams

	if not arg_1_0.preSelectTeams_ then
		arg_1_0:loadPreFormation()
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initHeros(arg_2_0.selfPlayer.heros_)
	arg_2_0:initPets(arg_2_0.selfPlayer.collectedPets or {})
	arg_2_0:initPresetTeams()
	arg_2_0:layout()
	arg_2_0:initPreHeros()
	arg_2_0:updateBtnState()
end

function var_0_0.initHeros(arg_3_0, arg_3_1)
	arg_3_0.totalHero_ = {}
	arg_3_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_3_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_3_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_3_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_3_0.totalHero_[xyd.DistanceType.FILTER] = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.totalHero_) do
		iter_3_1[var_0_13.NO] = {}
		iter_3_1[var_0_13.YES] = {}
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_1) do
		if arg_3_0:isSpecifyHero(iter_3_3) then
			if iter_3_3:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_3_0.totalHero_[xyd.DistanceType.QIANPAI][var_0_13.NO], iter_3_3)

				if iter_3_3:isCollocation() then
					table.insert(arg_3_0.totalHero_[xyd.DistanceType.QIANPAI][var_0_13.YES], iter_3_3)
				end
			elseif iter_3_3:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_3_0.totalHero_[xyd.DistanceType.ZHONGPAI][var_0_13.NO], iter_3_3)

				if iter_3_3:isCollocation() then
					table.insert(arg_3_0.totalHero_[xyd.DistanceType.ZHONGPAI][var_0_13.YES], iter_3_3)
				end
			elseif iter_3_3:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_3_0.totalHero_[xyd.DistanceType.HOUPAI][var_0_13.NO], iter_3_3)

				if iter_3_3:isCollocation() then
					table.insert(arg_3_0.totalHero_[xyd.DistanceType.HOUPAI][var_0_13.YES], iter_3_3)
				end
			end

			table.insert(arg_3_0.totalHero_[xyd.DistanceType.ALL][var_0_13.NO], iter_3_3)

			if iter_3_3:isCollocation() then
				table.insert(arg_3_0.totalHero_[xyd.DistanceType.ALL][var_0_13.YES], iter_3_3)
			end
		end
	end

	for iter_3_4 = 1, #arg_3_0.totalHero_ do
		arg_3_0:sortTables(arg_3_0.totalHero_[iter_3_4])
	end

	arg_3_0.selectedHeroClass_ = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_4_0, arg_4_1)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		if iter_4_1.is_show_ == 1 then
			table.insert(var_4_0, iter_4_1)
		end
	end

	arg_4_0:sortPetTables(var_4_0)

	arg_4_0.totalPet_ = var_4_0
end

function var_0_0.sortTables(arg_5_0, arg_5_1)
	table.sort(arg_5_1[var_0_13.NO], function(arg_6_0, arg_6_1)
		return xyd.heroNormalSort(arg_6_0, arg_6_1) or false
	end)
	table.sort(arg_5_1[var_0_13.YES], function(arg_7_0, arg_7_1)
		return xyd.heroNormalSort(arg_7_0, arg_7_1) or false
	end)
end

function var_0_0.sortPetTables(arg_8_0, arg_8_1)
	table.sort(arg_8_1, function(arg_9_0, arg_9_1)
		return xyd.heroNormalSort(arg_9_0, arg_9_1) or false
	end)
end

function var_0_0.isSpecifyHero(arg_10_0, arg_10_1)
	return true
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	arg_11_0:refreshSelectedHeroClass()
	arg_11_0:refreshSelectTeamClass()
	arg_11_0:getBattleBtn()
	arg_11_0:setNextBtn()
	arg_11_0:refreshBtnState()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_11_0, arg_11_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_11_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_11_0, arg_11_0.updateListBySearchTxt))
end

function var_0_0.updateList(arg_12_0, ...)
	arg_12_0.selectedHeroClass_ = xyd.DistanceType.FILTER
	arg_12_0.isHeroPreset = false

	arg_12_0:updateFilterHeros()
	arg_12_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_13_0, arg_13_1)
	arg_13_0.searchTxt = arg_13_1.heroName
	arg_13_0.selectedHeroClass_ = xyd.DistanceType.SEARCH

	arg_13_0:updateSearchHeros()
	arg_13_0:refreshSelectedHeroClass()
end

function var_0_0.updateFilterHeros(arg_14_0)
	arg_14_0.totalHero_[xyd.DistanceType.FILTER] = {}
	arg_14_0.totalHero_[xyd.DistanceType.FILTER][var_0_13.NO] = {}
	arg_14_0.totalHero_[xyd.DistanceType.FILTER][var_0_13.YES] = {}

	local var_14_0 = {
		0,
		0,
		0
	}
	local var_14_1 = {
		0,
		0,
		0
	}
	local var_14_2 = {
		0,
		0,
		0,
		0
	}

	if arg_14_0.selfPlayer.sortType and arg_14_0.selfPlayer.sortType > 0 then
		local var_14_3 = {}
		local var_14_4 = arg_14_0.selfPlayer.sortType
		local var_14_5 = 1

		while var_14_4 > 0 do
			var_14_3[var_14_5] = var_14_4 % 2
			var_14_5 = var_14_5 + 1
			var_14_4 = math.floor(var_14_4 / 2)
		end

		local var_14_6 = 1

		for iter_14_0 = 10, 1, -1 do
			if iter_14_0 <= 4 then
				if iter_14_0 == 4 then
					var_14_6 = 1
				end

				var_14_2[var_14_6] = var_14_3[iter_14_0]
			elseif iter_14_0 <= 7 then
				if iter_14_0 == 7 then
					var_14_6 = 1
				end

				var_14_1[var_14_6] = var_14_3[iter_14_0]
			elseif iter_14_0 <= 10 and var_14_3[iter_14_0] then
				var_14_0[var_14_6] = var_14_3[iter_14_0]
			end

			var_14_6 = var_14_6 + 1
		end
	else
		var_14_0 = {
			1,
			1,
			1
		}
		var_14_1 = {
			1,
			1,
			1
		}
		var_14_2 = {
			1,
			1,
			1,
			1
		}
	end

	for iter_14_1, iter_14_2 in pairs(arg_14_0.totalHero_[xyd.DistanceType.ALL][var_0_13.NO]) do
		if var_14_0[iter_14_2:getDistanceType() - 1] == 1 and var_14_1[iter_14_2:getHeroType()] == 1 and var_14_2[iter_14_2:getFromType()] == 1 and arg_14_0:isSpecifyHero(iter_14_2) then
			table.insert(arg_14_0.totalHero_[xyd.DistanceType.FILTER][var_0_13.NO], iter_14_2)
		end
	end

	for iter_14_3, iter_14_4 in pairs(arg_14_0.totalHero_[xyd.DistanceType.ALL][var_0_13.YES]) do
		if var_14_0[iter_14_4:getDistanceType() - 1] == 1 and var_14_1[iter_14_4:getHeroType()] == 1 and var_14_2[iter_14_4:getFromType()] == 1 and arg_14_0:isSpecifyHero(iter_14_4) then
			table.insert(arg_14_0.totalHero_[xyd.DistanceType.FILTER][var_0_13.YES], iter_14_4)
		end
	end
end

function var_0_0.updateSearchHeros(arg_15_0)
	arg_15_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_15_0.totalHero_[xyd.DistanceType.SEARCH][var_0_13.NO] = {}
	arg_15_0.totalHero_[xyd.DistanceType.SEARCH][var_0_13.YES] = {}

	if arg_15_0.searchTxt ~= "" then
		for iter_15_0, iter_15_1 in pairs(arg_15_0.totalHero_[xyd.DistanceType.ALL][var_0_13.NO]) do
			if xyd.searchHeroByName(arg_15_0.searchTxt, iter_15_1) then
				table.insert(arg_15_0.totalHero_[xyd.DistanceType.SEARCH][var_0_13.NO], iter_15_1)
			end
		end

		for iter_15_2, iter_15_3 in pairs(arg_15_0.totalHero_[xyd.DistanceType.ALL][var_0_13.YES]) do
			if xyd.searchHeroByName(arg_15_0.searchTxt, iter_15_3) then
				table.insert(arg_15_0.totalHero_[xyd.DistanceType.SEARCH][var_0_13.YES], iter_15_3)
			end
		end
	end
end

function var_0_0.setNextBtn(arg_16_0)
	arg_16_0:nodeByName("next_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if #arg_16_0.selectTeams[arg_16_0.nowTeamNumber_].heros < 1 then
				local var_17_0 = string.format(var_0_2:translation("PEAK_SELECT_TEAM_TIP_2"), arg_16_0.nowTeamNumber_)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_17_0, nil, nil, nil, arg_16_0.colorMode)
			else
				arg_16_0.nowTeamNumber_ = arg_16_0.nowTeamNumber_ + 1

				arg_16_0:refreshSelectTeamClass()
				arg_16_0:showTeamsByTeamNumber(arg_16_0.nowTeamNumber_)
				arg_16_0:refreshBtnState()

				if arg_16_0.type == xyd.SelectTeamType.PEAK_ARENA then
					arg_16_0:refreshEnemyPanel()
				end

				arg_16_0:updateScore(arg_16_0.nowTeamNumber_)
			end
		end
	end)
end

function var_0_0.refreshEnemyPanel(arg_18_0)
	for iter_18_0 = 1, 5 do
		arg_18_0:nodeByName("enemy_hero_" .. iter_18_0):removeAllChildren()
	end

	arg_18_0:nodeByName("pet_back_enemy"):removeAllChildren()

	if arg_18_0.teamNum > 3 and arg_18_0.nowTeamNumber_ > arg_18_0.teamNum / 2 + 1 then
		for iter_18_1 = 1, 5 do
			arg_18_0:nodeByName("question_mark_" .. iter_18_1):setVisible(true)
		end

		arg_18_0:nodeByName("question_mark_pet"):setVisible(true)
	else
		local var_18_0 = arg_18_0.enemyTeams[arg_18_0.nowTeamNumber_].heros

		for iter_18_2 = 1, 5 do
			arg_18_0:nodeByName("question_mark_" .. iter_18_2):setVisible(false)

			if iter_18_2 <= #var_18_0 then
				xyd.setAvatarBorderNewUI(var_18_0[iter_18_2], arg_18_0:nodeByName("enemy_hero_" .. iter_18_2))
			end
		end

		arg_18_0:nodeByName("question_mark_pet"):setVisible(false)

		local var_18_1 = arg_18_0.enemyTeams[arg_18_0.nowTeamNumber_].pet

		if var_18_1 then
			xyd.setPetAvatar(arg_18_0:nodeByName("pet_back_enemy"), var_18_1, nil, true)
		end
	end
end

function var_0_0.refreshBtnState(arg_19_0)
	if arg_19_0.nowTeamNumber_ < arg_19_0.teamNum then
		arg_19_0:nodeByName("next_btn"):setVisible(true)
		arg_19_0:nodeByName("button_ok"):setVisible(false)
		arg_19_0:nodeByName("button_battle"):setVisible(false)
	elseif arg_19_0.nowTeamNumber_ == arg_19_0.teamNum and arg_19_0.type == xyd.SelectTeamType.PEAK_ARENA then
		arg_19_0:nodeByName("next_btn"):setVisible(false)
		arg_19_0:nodeByName("button_ok"):setVisible(false)
		arg_19_0:nodeByName("button_battle"):setVisible(true)
	elseif arg_19_0.nowTeamNumber_ == arg_19_0.teamNum and arg_19_0.type == xyd.SelectTeamType.PEAK_ARENA_DEFENSE then
		arg_19_0:nodeByName("next_btn"):setVisible(false)
		arg_19_0:nodeByName("button_ok"):setVisible(true)
		arg_19_0:nodeByName("button_battle"):setVisible(false)
	end
end

function var_0_0.layout(arg_20_0)
	arg_20_0:nodeByName("txt_pet"):setString(var_0_2:translation("PERSON_SELECT_PET"))
	arg_20_0:nodeByName("txt_hero"):setString(var_0_2:translation("PERSON_SELECT_HERO"))
	arg_20_0:nodeByName("txt_all"):setString(var_0_2:translation("ALL_BUTTON"))
	arg_20_0:nodeByName("txt_qianpai"):setString(var_0_2:translation("QIANPAI_BUTTON"))
	arg_20_0:nodeByName("txt_zhongpai"):setString(var_0_2:translation("ZHONGPAI_BUTTON"))
	arg_20_0:nodeByName("txt_houpai"):setString(var_0_2:translation("HOUPAI_BUTTON"))
	arg_20_0:nodeByName("txt_preset"):setString(var_0_2:translation("HERO_LIST_BTN_PRESET"))
	arg_20_0:nodeByName("text_zhandouli"):setString(var_0_2:translation("TOP_SELECTPEAKTEAMWINDOW_TEXT1"))
	arg_20_0:nodeByName("txt_change"):setString(var_0_2:translation("TOP_PEAKARENAWINDOW_TEXT1"))
	arg_20_0:nodeByName("txt_cancel_change"):setString(var_0_2:translation("TOP_SELECTPEAKTEAMWINDOW_TEXT10"))
	arg_20_0:nodeByName("txt_next"):setString(var_0_2:translation("TOP_SELECTPEAKTEAMWINDOW_TEXT2"))
	arg_20_0:nodeByName("txt_next"):enableOutline(cc.c4b(65, 74, 84, 255), 2)
	arg_20_0:nodeByName("zhandouli"):setString(0)

	if arg_20_0.type == xyd.SelectTeamType.PEAK_ARENA then
		arg_20_0.heroListLayer = arg_20_0:nodeByName("list_layer_battle")

		local var_20_0 = arg_20_0.heroListLayer:getContentSize()

		arg_20_0:refreshEnemyPanel()

		arg_20_0.heroList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_20_0.width, var_20_0.height),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_20_0.heroListLayer)

		arg_20_0:nodeByName("battle_team_bg"):setVisible(true)

		local var_20_1 = arg_20_0:nodeByName("button_container"):getPositionY()

		arg_20_0:nodeByName("button_container"):setPositionY(var_20_1 - 130)

		local var_20_2 = arg_20_0:nodeByName("button_pet"):getPositionY()

		arg_20_0:nodeByName("button_pet"):setPositionY(var_20_2 - 10)
		arg_20_0:nodeByName("button_hero"):setPositionY(var_20_2 - 10)

		local var_20_3 = arg_20_0:nodeByName("list_team_btn"):getContentSize()

		arg_20_0:nodeByName("list_team_btn"):setContentSize(var_20_3.width, var_20_3.height - 100)
		arg_20_0:initSwitch()
		arg_20_0:startTimer()
	elseif arg_20_0.type == xyd.SelectTeamType.PEAK_ARENA_DEFENSE then
		arg_20_0.heroListLayer = arg_20_0:nodeByName("list_layer")

		local var_20_4 = arg_20_0.heroListLayer:getContentSize()

		arg_20_0.heroList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_20_4.width, var_20_4.height),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_20_0.heroListLayer)

		arg_20_0:nodeByName("battle_team_bg"):setVisible(false)
	end

	arg_20_0:initMenu()
	arg_20_0:initTeamMenu()

	arg_20_0.heroCells_ = {}

	arg_20_0.heroList_:setDelegate(handler(arg_20_0, arg_20_0.delegate))
	arg_20_0:showTeamsByTeamNumber(arg_20_0.nowTeamNumber_)

	for iter_20_0 = 1, arg_20_0.teamNum do
		arg_20_0:refreshTeamHeroNum(iter_20_0)
	end
end

function var_0_0.initSwitch(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("list_switch")
	local var_21_1 = var_21_0:getContentSize()

	arg_21_0.switchList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_21_1.width, var_21_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_21_0)

	arg_21_0.switchList:setVisible(false)
	arg_21_0:nodeByName("switch_team_button"):setVisible(true)
	arg_21_0:nodeByName("switch_team_button"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			arg_21_0:changeSwitchMode(1 - arg_21_0.switchMode)
		end
	end)
end

function var_0_0.changeSwitchMode(arg_23_0, arg_23_1)
	arg_23_0.switchMode = arg_23_1

	if arg_23_1 == 1 then
		arg_23_0:updateSwitchContainer()
		arg_23_0:nodeByName("txt_change"):setVisible(false)
		arg_23_0:nodeByName("txt_cancel_change"):setVisible(true)
		arg_23_0.heroListLayer:setVisible(false)
		arg_23_0.switchList:setVisible(true)
	else
		arg_23_0:nodeByName("txt_change"):setVisible(true)
		arg_23_0:nodeByName("txt_cancel_change"):setVisible(false)
		arg_23_0.switchList:setVisible(false)
		arg_23_0.heroListLayer:setVisible(true)
	end
end

function var_0_0.updateSwitchContainer(arg_24_0)
	arg_24_0.switchList:removeAllItems()

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.selectTeams) do
		local var_24_0 = arg_24_0:createSwitchTeamItem(iter_24_0, iter_24_1)

		arg_24_0.switchList:addItem(var_24_0)
	end

	arg_24_0.switchList:reload()
end

function var_0_0.createSwitchTeamItem(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_0.switchList:newItem()
	local var_25_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/switch_team_item.csb")
	local var_25_2 = var_25_1:getChildByName("container")
	local var_25_3 = var_25_2:getContentSize()

	arg_25_0.selectTeams[arg_25_1].teamItem = var_25_1

	for iter_25_0, iter_25_1 in ipairs(arg_25_2.heros) do
		xyd.setAvatarBorderNewUI(iter_25_1, var_25_2:getChildByName("hero" .. iter_25_0))
	end

	if arg_25_2.pet then
		xyd.setPetAvatarNewUI(var_25_2:getChildByName("pet"), arg_25_2.pet, nil, true)
	end

	var_25_2:getChildByName("team_id_txt"):loadTexture("windows/peak_arena/pic/pic_team" .. arg_25_1 .. ".png")

	local var_25_4 = var_25_2:getChildByName("change")

	xyd.nodeEventSample(var_25_4, nil, function(arg_26_0)
		var_25_4:setVisible(false)

		arg_25_0.nowTeamNumber_ = arg_25_1

		arg_25_0:openOtherTeamsArrow(arg_25_1)
	end)

	local var_25_5 = var_25_2:getChildByName("switch_arrow")

	xyd.nodeEventSample(var_25_5, nil, function(arg_27_0)
		if not arg_25_0.isPresetAnimation then
			xyd.playTabButtonSound()

			if arg_25_1 == arg_25_0.nowTeamNumber_ then
				return
			end

			arg_25_0:changeTeams(arg_25_0.nowTeamNumber_, arg_25_1)
			arg_25_0:changeSwitchMode(0)
			arg_25_0:refreshSelectedHeroClass()
		end
	end)
	var_25_0:addContent(var_25_1)
	var_25_0:setItemSize(var_25_3.width, var_25_3.height + 10)

	return var_25_0
end

function var_0_0.openOtherTeamsArrow(arg_28_0, arg_28_1)
	for iter_28_0 = 1, #arg_28_0.selectTeams do
		if iter_28_0 ~= arg_28_1 then
			local var_28_0 = arg_28_0.selectTeams[iter_28_0].teamItem:getChildByName("container")

			var_28_0:getChildByName("change"):setVisible(false)
			var_28_0:getChildByName("switch_arrow"):setVisible(true)
		end
	end
end

function var_0_0.initTeamMenu(arg_29_0)
	local var_29_0 = arg_29_0:nodeByName("list_team_btn")
	local var_29_1 = var_29_0:getContentSize()

	arg_29_0.teamBtnList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_29_1.width, var_29_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(var_29_0)
	arg_29_0.teamButtons = {}

	for iter_29_0 = 1, arg_29_0.teamNum do
		local var_29_2 = arg_29_0:createTeamBtnItem(iter_29_0)

		arg_29_0.teamBtnList:addItem(var_29_2)
	end

	arg_29_0.teamBtnList:reload()
end

function var_0_0.createTeamBtnItem(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0.teamBtnList:newItem()
	local var_30_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/team_btn_item.csb")
	local var_30_2 = var_30_1:getChildByName("container")
	local var_30_3 = var_30_2:getContentSize()
	local var_30_4 = var_30_2:getChildByName("btn")

	table.insert(arg_30_0.teamButtons, var_30_4)
	var_30_4:getChildByName("txt_team"):setString(var_0_2:translation("TOP_SELECTPEAKTEAMWINDOW_TEXT" .. arg_30_1 + 2))
	var_30_4:addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.ended and not arg_30_0.isPresetAnimation then
			xyd.playTabButtonSound()

			if arg_30_0.isAnimating then
				return
			end

			arg_30_0.nowTeamNumber_ = arg_30_1

			arg_30_0:refreshSelectTeamClass()
			arg_30_0:showTeamsByTeamNumber(arg_30_0.nowTeamNumber_)
			arg_30_0:refreshBtnState()

			if arg_30_0.type == xyd.SelectTeamType.PEAK_ARENA then
				arg_30_0:refreshEnemyPanel()
			end

			arg_30_0:updateScore(arg_30_0.nowTeamNumber_)
		end
	end)
	var_30_1:setContentSize(var_30_3.width, var_30_3.height)
	var_30_0:addContent(var_30_1)
	var_30_0:setItemSize(var_30_3.width, var_30_3.height + 14)

	return var_30_0
end

function var_0_0.changeTeams(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_0.selectItems[arg_32_1]

	arg_32_0.selectItems[arg_32_1] = arg_32_0.selectItems[arg_32_2]
	arg_32_0.selectItems[arg_32_2] = var_32_0

	local var_32_1 = arg_32_0.selectTeams[arg_32_1]

	arg_32_0.selectTeams[arg_32_1] = arg_32_0.selectTeams[arg_32_2]
	arg_32_0.selectTeams[arg_32_2] = var_32_1

	arg_32_0:refreshTeamHeroNum(arg_32_1)
	arg_32_0:refreshTeamHeroNum(arg_32_2)

	for iter_32_0, iter_32_1 in ipairs(arg_32_0.selectItems[arg_32_1].heros) do
		iter_32_1.teamCount_ = arg_32_1
	end

	for iter_32_2, iter_32_3 in ipairs(arg_32_0.selectItems[arg_32_2].heros) do
		iter_32_3.teamCount_ = arg_32_2
	end
end

function var_0_0.widgetSet(arg_33_0, arg_33_1)
	for iter_33_0, iter_33_1 in ipairs(arg_33_1:getChildren()) do
		if iter_33_1 ~= nil then
			iter_33_1:setCascadeOpacityEnabled(true)
			arg_33_0:widgetSet(iter_33_1)
		end
	end
end

function var_0_0.loadPreFormation(arg_34_0)
	local var_34_0 = xyd.db.formation:getFormationTable(arg_34_0.campaignType) or {}

	if type(var_34_0) ~= "table" then
		return
	end

	arg_34_0.preSelectTeams_ = arg_34_0.peakArena:getSelfHeros(var_34_0, arg_34_0.teamNum)
end

function var_0_0.initMenu(arg_35_0)
	arg_35_0.heroClassButtons_ = {}

	table.insert(arg_35_0.heroClassButtons_, arg_35_0:nodeByName("button_all"))
	table.insert(arg_35_0.heroClassButtons_, arg_35_0:nodeByName("button_qianpai"))
	table.insert(arg_35_0.heroClassButtons_, arg_35_0:nodeByName("button_zhongpai"))
	table.insert(arg_35_0.heroClassButtons_, arg_35_0:nodeByName("button_houpai"))
	table.insert(arg_35_0.heroClassButtons_, arg_35_0:nodeByName("button_filter"))
	table.insert(arg_35_0.heroClassButtons_, arg_35_0:nodeByName("button_search"))

	for iter_35_0 = 1, #arg_35_0.heroClassButtons_ do
		arg_35_0.heroClassButtons_[iter_35_0]:addTouchEventListener(function(arg_36_0, arg_36_1)
			if arg_36_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				collectgarbage("collect")

				arg_35_0.selectedHeroClass_ = iter_35_0
				arg_35_0.isHeroPreset = false

				arg_35_0:refreshSelectedHeroClass()
			end
		end)
	end

	arg_35_0:nodeByName("button_hero"):addTouchEventListener(function(arg_37_0, arg_37_1)
		if arg_37_1 == ccui.TouchEventType.ended then
			arg_35_0:updateBtnState()

			if arg_35_0.containerState == var_0_11.PET then
				xyd.playTabButtonSound()

				arg_35_0.isHeroPreset = false
				arg_35_0.containerState = var_0_11.HERO

				arg_35_0:updateBtnState()
				arg_35_0:refreshSelectedHeroClass()
			end
		end
	end)
	arg_35_0:nodeByName("button_pet"):addTouchEventListener(function(arg_38_0, arg_38_1)
		if arg_38_1 == ccui.TouchEventType.ended then
			arg_35_0:updateBtnState()

			if arg_35_0.containerState == var_0_11.HERO then
				xyd.playTabButtonSound()

				arg_35_0.isHeroPreset = false
				arg_35_0.containerState = var_0_11.PET

				arg_35_0:updateBtnState()
				arg_35_0:refreshSelectedHeroClass()
			end
		end
	end)
	arg_35_0:nodeByName("button_preset"):addTouchEventListener(function(arg_39_0, arg_39_1)
		if arg_39_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()

			if not arg_35_0.isHeroPreset then
				arg_35_0.isHeroPreset = true

				for iter_39_0 = 1, #arg_35_0.heroClassButtons_ do
					arg_35_0.heroClassButtons_[iter_39_0]:setBrightStyle(ccui.BrightStyle.normal)
				end

				arg_35_0.heroList_:reload()
			end

			arg_35_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
		end
	end)
	arg_35_0:nodeByName("text_filter"):setString(var_0_2:translation("FILTER_TEXT"))
	arg_35_0:nodeByName("button_filter"):addTouchEventListener(function(arg_40_0, arg_40_1)
		xyd.buttonScaleAnim(arg_40_0, arg_40_1)

		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_filter_wnd", {
				awaken_not_show = true
			})
		end
	end)
	arg_35_0:nodeByName("button_search"):addTouchEventListener(function(arg_41_0, arg_41_1)
		xyd.buttonScaleAnim(arg_41_0, arg_41_1)

		if arg_41_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_35_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_42_0, arg_42_1)
		xyd.buttonScaleAnim(arg_42_0, arg_42_1)

		if arg_42_1 == ccui.TouchEventType.ended then
			arg_35_0.collocationType_ = 3 - arg_35_0.collocationType_

			arg_35_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.initHeroCell(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_0.totalHero_[arg_43_0.selectedHeroClass_][arg_43_0.collocationType_][arg_43_2]
	local var_43_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/hero_avatar.csb")
	local var_43_2 = var_43_1:getChildByName("background"):getContentSize()

	var_43_1:setContentSize(var_43_2)
	arg_43_1:setContentSize(var_43_2)
	xyd.setAvatarBorderNewUI(var_43_0, var_43_1:getChildByName("avatar"))

	local var_43_3 = var_43_1:getChildByName("chosen")

	var_43_3:setLocalZOrder(100)
	var_43_3:setVisible(false)

	local var_43_4 = var_43_1:getChildByName("avatar_mask")

	var_43_4:setLocalZOrder(2)
	var_43_4:setVisible(false)
	var_43_1:getChildByName("lv_txt"):setString(var_43_0:getLevel())
	var_43_1:getChildByName("name_text"):setString(var_43_0:getName())
	var_43_1:setName("layout")
	var_43_1:setPosition(cc.p(0, 0))

	arg_43_1.data = var_43_0

	arg_43_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_43_1:addChild(var_43_1)

	for iter_43_0, iter_43_1 in ipairs(arg_43_0.selectTeams) do
		for iter_43_2, iter_43_3 in ipairs(iter_43_1.heros) do
			if iter_43_3:getTableID() == var_43_0:getTableID() then
				arg_43_1.teamNo_ = iter_43_2
				arg_43_1.teamCount_ = iter_43_0

				var_43_3:setVisible(true)
				var_43_4:setVisible(true)

				arg_43_0.selectItems[iter_43_0].heros[iter_43_2].iniCell_ = arg_43_1
				arg_43_0.selectItems[iter_43_0].heros[iter_43_2].iniCellVisible_ = false

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
				arg_43_0:clickAvatar(arg_43_1, false, arg_43_0.nowTeamNumber_)
			end

			return true
		end)
	end
end

function var_0_0.initPetCell(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_0.totalPet_[arg_45_2]

	arg_45_1:align(display.CENTER):size(var_0_10, var_0_10)
	xyd.setPetAvatarNewUI(arg_45_1, var_45_0, 100)

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
			arg_45_0:clickPetAvatar(arg_45_1, false, arg_45_0.nowTeamNumber_)
		end

		return true
	end)

	for iter_45_0 = 1, arg_45_0.teamNum do
		local var_45_1 = arg_45_0.selectTeams[iter_45_0].pet

		if var_45_1 and var_45_1:getPetID() == var_45_0:getPetID() then
			arg_45_0.selectItems[iter_45_0].pet.iniCell_ = arg_45_1
			arg_45_1.teamNo_ = 1
			arg_45_1.teamCount_ = iter_45_0

			local var_45_2 = arg_45_1:getChildByName("layout")

			var_45_2:getChildByName("avatar_mask"):setVisible(true)
			var_45_2:getChildByName("chosen"):setVisible(true)

			break
		end
	end

	arg_45_0:showPetCellTeam(arg_45_1.teamCount_, arg_45_1:getChildByName("layout"))
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_47_0, arg_47_1, arg_47_2)
	if arg_47_1.isAnimated_ then
		return
	end

	local var_47_0, var_47_1 = arg_47_0:nodeByName("list_layer"):getPosition()
	local var_47_2 = arg_47_1.iniCell_

	if arg_47_0.selectItems[arg_47_0.nowTeamNumber_].pet ~= arg_47_1 then
		return
	end

	local var_47_3 = 1

	if var_47_2 and not tolua.isnull(var_47_2) then
		local var_47_4 = var_47_2:convertToWorldSpace(cc.p(0, 0))
		local var_47_5 = var_47_2:getChildByName("layout")
		local var_47_6 = var_47_5:getChildByName("avatar_mask")
		local var_47_7 = var_47_5:getChildByName("chosen")

		var_47_6:setVisible(false)
		var_47_7:setVisible(false)
		arg_47_0:showPetCellTeam(0, var_47_2:getChildByName("layout"))
	end

	arg_47_0.selectItems[arg_47_0.nowTeamNumber_].pet = nil
	arg_47_0.selectTeams[arg_47_0.nowTeamNumber_].pet = nil

	if arg_47_0.isHeroPreset then
		arg_47_0:changePresetTeamStatus()
	end

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

	var_48_0:size(114, 114)
	var_48_0:align(display.CENTER)

	var_48_0.data = arg_48_1

	xyd.setPetAvatarNewUI(var_48_0, arg_48_1, 100)

	return var_48_0
end

function var_0_0.clickPetBottomAvatar(arg_49_0, arg_49_1, arg_49_2)
	if arg_49_1.isAnimated_ then
		return
	end

	local var_49_0, var_49_1 = arg_49_0:nodeByName("list_layer"):getPosition()
	local var_49_2 = arg_49_1.iniCell_
	local var_49_3
	local var_49_4 = arg_49_0.selectTeams[arg_49_0.nowTeamNumber_].pet

	if var_49_4 and var_49_4:getTableID() == arg_49_1.data:getTableID() then
		var_49_3 = 1
	end

	if not var_49_3 then
		return
	end

	if var_49_2 and not tolua.isnull(var_49_2) then
		local var_49_5 = var_49_2:convertToWorldSpace(cc.p(0, 0))

		var_49_0, var_49_1 = var_49_5.x, var_49_5.y

		local var_49_6 = var_49_2:getChildByName("layout")
		local var_49_7 = var_49_6:getChildByName("avatar_mask")
		local var_49_8 = var_49_6:getChildByName("chosen")

		var_49_7:setVisible(false)
		var_49_8:setVisible(false)

		var_49_2.teamNo_ = nil

		arg_49_0:showHeroCellTeam(0, var_49_6)
	end

	arg_49_0:moveFadeOutAction(var_49_0, var_49_1, arg_49_1, arg_49_2)

	arg_49_0.selectItems[arg_49_0.nowTeamNumber_].pet = nil
	arg_49_0.selectTeams[arg_49_0.nowTeamNumber_].pet = nil

	arg_49_0:updateScore(arg_49_0.nowTeamNumber_)

	if arg_49_0.isHeroPreset then
		arg_49_0:changePresetTeamStatus()
	end
end

function var_0_0.clickPetAvatar(arg_50_0, arg_50_1, arg_50_2, arg_50_3, arg_50_4)
	local var_50_0 = arg_50_3 or arg_50_0.nowTeamNumber_

	if arg_50_1.isAnimated_ then
		return
	elseif not arg_50_1.teamNo_ and arg_50_0.selectTeams[var_50_0].pet then
		local var_50_1 = arg_50_0.selectItems[var_50_0].pet

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
		if arg_50_1.teamCount_ ~= arg_50_3 then
			local var_50_8 = string.format(var_0_2:translation("PEAK_SELECT_TEAM_TIP"), xyd.tables.hero:name(arg_50_1.data:getTableID()))

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_50_8, function()
				local var_52_0 = 1

				for iter_52_0 = 1, arg_50_0.teamNum do
					local var_52_1 = arg_50_0.selectItems[iter_52_0].pet

					if var_52_1 and arg_50_1.data and var_52_1.data:getTableID() == arg_50_1.data:getTableID() then
						var_52_0 = iter_52_0

						break
					end
				end

				local var_52_2 = arg_50_0.selectItems[var_52_0].pet

				if arg_50_1.invisible then
					var_52_2:hide()

					arg_50_1.invisible = false
				end

				var_50_3:setVisible(false)
				var_50_4:setVisible(false)

				arg_50_0.selectItems[var_52_0].pet = nil
				arg_50_0.selectTeams[var_52_0].pet = nil
				arg_50_1.teamNo_ = nil
				arg_50_1.teamCount_ = nil

				arg_50_0:showPetCellTeam(0, arg_50_1:getChildByName("layout"))

				arg_50_1.isAnimated_ = false

				arg_50_0:clickPetAvatar(arg_50_1, arg_50_2, var_50_0)
			end, {
				lcallback = function()
					arg_50_1.isAnimated_ = false
				end
			}, nil, arg_50_0.colorMode)
		else
			local var_50_9 = 1

			for iter_50_0 = 1, arg_50_0.teamNum do
				local var_50_10 = arg_50_0.selectItems[iter_50_0].pet

				if var_50_10 and arg_50_1.data and var_50_10.data:getTableID() == arg_50_1.data:getTableID() then
					var_50_9 = iter_50_0

					break
				end
			end

			local var_50_11 = arg_50_0.selectItems[var_50_9].pet

			if arg_50_1.invisible then
				var_50_11:hide()

				arg_50_1.invisible = false
			end

			arg_50_0:moveFadeOutAction(var_50_6, var_50_7, var_50_11, function()
				arg_50_1.isAnimated_ = false
			end)
			var_50_3:setVisible(false)
			var_50_4:setVisible(false)

			arg_50_0.selectItems[var_50_9].pet = nil
			arg_50_0.selectTeams[var_50_9].pet = nil
			arg_50_1.teamNo_ = nil
			arg_50_1.teamCount_ = nil

			arg_50_0:showPetCellTeam(0, arg_50_1:getChildByName("layout"))
		end
	elseif not arg_50_1.teamNo_ and not arg_50_0.selectItems[var_50_0].pet then
		local var_50_12 = arg_50_1.data

		if not arg_50_2 and var_0_4:chosenSound(var_50_12:getTableID()) ~= "" then
			audio.playSound(var_0_4:chosenSound(var_50_12:getTableID()), false)
		end

		local var_50_13 = arg_50_0:initPetBottomCell(var_50_12)

		if arg_50_1.invisible then
			var_50_13:hide()

			arg_50_1.invisible = false
		end

		var_50_13.iniCell_ = arg_50_1
		var_50_13.teamCount_ = arg_50_3

		var_50_13:pos(var_50_6, var_50_7)
		var_50_13:addTo(arg_50_0:nodeByName("avatar_container"))
		var_50_13:setTouchEnabled(true)
		var_50_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_55_0)
			if arg_55_0.name == "ended" then
				arg_50_0:clickPetBottomAvatar(var_50_13)
			end

			return true
		end)

		arg_50_1.teamNo_ = arg_50_0:getPetTeamNo(var_50_13, var_50_0)
		arg_50_1.teamCount_ = var_50_0

		arg_50_0:showPetCellTeam(arg_50_1.teamCount_, arg_50_1:getChildByName("layout"))

		local var_50_14, var_50_15 = arg_50_0:nodeByName("avatar_pet"):getPosition()

		if arg_50_2 then
			arg_50_0.selectItems[var_50_0].pet:pos(var_50_14, var_50_15)

			arg_50_1.isAnimated_ = false
		else
			local var_50_16 = arg_50_0.selectItems[var_50_0].pet

			transition.stopTarget(var_50_16)

			var_50_13.isAnimated_ = true

			transition.moveTo(var_50_16, {
				time = 0.3,
				x = var_50_14,
				y = var_50_15,
				onComplete = function()
					arg_50_1.isAnimated_ = false
					var_50_13.isAnimated_ = false
				end
			})
		end

		arg_50_0.selectItems[var_50_0].pet.iniCell_.teamNo_ = 1

		var_50_3:setVisible(true)
		var_50_4:setVisible(true)
	end

	if not arg_50_4 then
		arg_50_0:updateScore(var_50_0)
	end
end

function var_0_0.showHeroCellTeam(arg_57_0, arg_57_1, arg_57_2)
	if not arg_57_2 then
		return
	end

	local var_57_0 = arg_57_2:getChildByName("team_pic")

	if arg_57_1 and arg_57_1 > 0 then
		var_57_0:setVisible(true)
		var_57_0:loadTexture("windows/peak_arena/select_team_peak/team" .. arg_57_1 .. "_txt.png")
	else
		var_57_0:setVisible(false)
	end
end

function var_0_0.showPetCellTeam(arg_58_0, arg_58_1, arg_58_2)
	if not arg_58_2 then
		return
	end

	local var_58_0 = arg_58_2:getChildByName("team_pic")

	if arg_58_1 and arg_58_1 > 0 then
		if var_58_0 then
			var_58_0:setVisible(true)
			var_58_0:setTexture("windows/peak_arena/select_team_peak/team" .. arg_58_1 .. "_txt.png")
		else
			var_58_0 = xyd.AssetLoader.get():loadSprite("windows/peak_arena/select_team_peak/team" .. arg_58_1 .. "_txt.png")

			var_58_0:addTo(arg_58_2)
			var_58_0:setPosition(100, 100)
			var_58_0:setName("team_pic")
		end
	elseif var_58_0 then
		var_58_0:setVisible(false)
	end
end

function var_0_0.showTeamsByTeamNumber(arg_59_0, arg_59_1)
	for iter_59_0 = 1, arg_59_0.teamNum do
		local var_59_0 = arg_59_1 == iter_59_0

		for iter_59_1, iter_59_2 in ipairs(arg_59_0.selectItems[iter_59_0].heros) do
			iter_59_2:setVisible(var_59_0)
		end

		if arg_59_0.selectItems[iter_59_0].pet then
			arg_59_0.selectItems[iter_59_0].pet:setVisible(var_59_0)
		end
	end
end

function var_0_0.initBottomCell(arg_60_0, arg_60_1)
	local var_60_0 = display.newNode()
	local var_60_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/hero_avatar.csb")
	local var_60_2 = var_60_1:getChildByName("background"):getContentSize()

	var_60_1:setContentSize(var_60_2)
	var_60_0:setContentSize(var_60_2)
	xyd.setAvatarBorderNewUI(arg_60_1, var_60_1:getChildByName("avatar"))

	local var_60_3 = var_60_1:getChildByName("chosen")

	var_60_3:setLocalZOrder(100)
	var_60_3:setVisible(false)

	local var_60_4 = var_60_1:getChildByName("avatar_mask")

	var_60_4:setLocalZOrder(2)
	var_60_4:setVisible(false)
	var_60_1:getChildByName("lv_txt"):setString(arg_60_1:getLevel())
	var_60_1:getChildByName("name_text"):setString(arg_60_1:getName())
	var_60_1:setName("layout")

	var_60_0.data = arg_60_1

	var_60_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_60_0:addChild(var_60_1)

	return var_60_0
end

function var_0_0.delegate(arg_61_0, ...)
	if arg_61_0.isHeroPreset then
		return arg_61_0:presetDelegate(...)
	end

	if arg_61_0.containerState == var_0_11.PET then
		return arg_61_0:petDelegate(...)
	end

	return arg_61_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_62_0, arg_62_1, arg_62_2, arg_62_3)
	local var_62_0 = math.ceil(#arg_62_0.totalHero_[arg_62_0.selectedHeroClass_][arg_62_0.collocationType_] / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_62_2 then
		return var_62_0
	elseif cc.ui.UIListView.CELL_TAG == arg_62_2 then
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

		for iter_62_0 = 1, var_0_7 do
			local var_62_6 = (arg_62_3 - 1) * var_0_7 + iter_62_0

			if var_62_6 > #arg_62_0.totalHero_[arg_62_0.selectedHeroClass_][arg_62_0.collocationType_] then
				break
			end

			var_62_3 = display.newNode()

			arg_62_0:initHeroCell(var_62_3, var_62_6)

			local var_62_7 = var_62_3:getContentSize().width
			local var_62_8 = var_62_3:getContentSize().height
			local var_62_9 = (arg_62_0.heroList_.viewRect_.width - var_62_7 * var_0_7) / (var_0_7 + 1)

			var_62_3:pos(var_62_9 * iter_62_0 + (iter_62_0 - 1) * var_62_7 + var_62_7 / 2, var_0_6 + var_62_8 / 2)
			var_62_5:addChild(var_62_3)

			arg_62_0.heroCells_[var_62_6] = var_62_3
		end

		var_62_5:setContentSize(cc.size(arg_62_0.heroList_.viewRect_.width, var_62_3:getContentSize().height + var_0_6))
		var_62_4:setItemSize(arg_62_0.heroList_.viewRect_.width, var_62_3:getContentSize().height + var_0_6)
		var_62_4:addContent(var_62_5)

		return var_62_4
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

		arg_63_0:initPresetCell(var_63_5, arg_63_3)
		var_63_4:setItemSize(arg_63_0.heroList_.viewRect_.width, var_63_5:getContentSize().height)
		var_63_4:addContent(var_63_5)

		return var_63_4
	end
end

function var_0_0.petDelegate(arg_64_0, arg_64_1, arg_64_2, arg_64_3)
	local var_64_0 = math.ceil(#arg_64_0.totalPet_ / var_0_8)

	if cc.ui.UIListView.COUNT_TAG == arg_64_2 then
		return var_64_0
	elseif cc.ui.UIListView.CELL_TAG == arg_64_2 then
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

		for iter_64_0 = 1, var_0_8 do
			local var_64_6 = (arg_64_3 - 1) * var_0_8 + iter_64_0

			if var_64_6 > #arg_64_0.totalPet_ then
				break
			end

			var_64_3 = display.newNode()

			arg_64_0:initPetCell(var_64_3, var_64_6)

			local var_64_7 = var_64_3:getContentSize().width
			local var_64_8 = var_64_3:getContentSize().height
			local var_64_9 = (arg_64_0.heroList_.viewRect_.width - var_64_7 * var_0_8) / (var_0_8 + 1)

			var_64_3:align(display.CENTER, var_64_9 * iter_64_0 + (iter_64_0 - 1) * var_64_7 + var_64_7 / 2, var_0_6 + var_64_8 / 2)
			var_64_5:addChild(var_64_3)
		end

		var_64_5:setContentSize(cc.size(arg_64_0.heroList_.viewRect_.width, var_64_3:getContentSize().height))
		var_64_4:setItemSize(arg_64_0.heroList_.viewRect_.width, var_64_3:getContentSize().height + var_0_6)
		var_64_4:addContent(var_64_5)

		return var_64_4
	end
end

function var_0_0.initPresetCell(arg_65_0, arg_65_1, arg_65_2)
	local var_65_0 = arg_65_0.presetTeams[arg_65_2].team
	local var_65_1 = arg_65_0.presetTeams[arg_65_2].teamName
	local var_65_2 = arg_65_0.presetTeams[arg_65_2].pet
	local var_65_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/preset_team_item.csb")
	local var_65_4 = var_65_3:getChildByName("container")
	local var_65_5 = var_65_4:getContentSize()

	arg_65_1:setContentSize(var_65_5.width, var_65_5.height + 10)
	var_65_3:addTo(arg_65_1)
	var_65_4:getChildByName("text_name"):setString(var_65_1)

	local var_65_6 = var_65_4:getChildByName("hero_list")
	local var_65_7 = 0
	local var_65_8 = 0

	for iter_65_0 = 1, #var_65_0 do
		local var_65_9 = var_65_0[iter_65_0]

		var_65_9.isUsed = nil

		local var_65_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/hero_avatar.csb")

		xyd.setAvatarBorderNewUI(var_65_9, var_65_10:getChildByName("avatar"))

		var_65_10.data = var_65_9

		var_65_10:addTo(var_65_6)
		var_65_10:setPositionX(var_65_7)

		var_65_7 = var_65_7 + var_0_9 + 12

		local var_65_11 = var_65_10:getChildByName("chosen")

		var_65_11:setLocalZOrder(100)
		var_65_11:setVisible(false)

		local var_65_12 = var_65_10:getChildByName("avatar_mask")

		var_65_12:setLocalZOrder(2)
		var_65_12:setVisible(false)

		for iter_65_1, iter_65_2 in ipairs(arg_65_0.selectTeams) do
			for iter_65_3, iter_65_4 in ipairs(iter_65_2.heros) do
				if iter_65_4:getTableID() == var_65_9:getTableID() then
					var_65_12:setVisible(true)
					arg_65_0:showHeroCellTeam(iter_65_1, var_65_10)

					var_65_9.isUsed = iter_65_1

					break
				end
			end
		end

		if not arg_65_0.presetTeamCells[arg_65_2] then
			arg_65_0.presetTeamCells[arg_65_2] = {}
		end

		arg_65_0.presetTeamCells[arg_65_2][iter_65_0] = var_65_10

		local var_65_13 = var_65_10:getChildByName("lv_txt")

		var_65_13:setString(var_65_0[iter_65_0]:getLevel())
		var_65_10:getChildByName("name_text"):setString(var_65_0[iter_65_0]:getName())
		var_65_13:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		var_65_8 = var_65_8 + var_65_0[iter_65_0]:getZhandouli()
	end

	if var_65_2 then
		var_65_2.isUsed = nil

		local var_65_14 = var_65_4:getChildByName("pet")

		xyd.setPetAvatarNewUI(var_65_14, var_65_2, 100)

		local var_65_15 = var_65_14:getChildByName("layout")

		var_65_15.data = var_65_2
		var_65_8 = var_65_8 + var_65_2:getZhandouli()

		for iter_65_5 = 1, arg_65_0.teamNum do
			local var_65_16 = arg_65_0.selectTeams[iter_65_5].pet

			if var_65_16 and var_65_16:getPetID() == var_65_2:getPetID() then
				var_65_15:getChildByName("avatar_mask"):setVisible(true)
				var_65_15:getChildByName("chosen"):setVisible(true)
				arg_65_0:showPetCellTeam(iter_65_5, var_65_15)

				var_65_2.isUsed = iter_65_5

				break
			end
		end

		arg_65_0.presetTeamPetCells[arg_65_2] = var_65_14:getChildByName("layout")
	end

	var_65_4:getChildByName("zhandouli"):setString(var_65_8)
	var_65_4:getChildByName("text_zhandouli"):setString(var_0_2:translation("TOTAL_FORCE") .. var_0_2:translation("COLON"))
	var_65_4:getChildByName("btn_use"):getChildByName("txt_use"):setString(var_0_2:translation("SELECT_TEAM_TEXT_1"))
	var_65_4:getChildByName("btn_use"):addTouchEventListener(function(arg_66_0, arg_66_1)
		xyd.buttonScaleAnim(arg_66_0, arg_66_1)

		if arg_66_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_65_0:checkPresetTeamCanUse(arg_65_2) then
				arg_65_0:showPresetTeam(var_65_0, var_65_2)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("PRESET_MEMBER_IN_USE")
				})
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_67_0, arg_67_1, arg_67_2)
	local var_67_0 = arg_67_0.selectItems[arg_67_0.nowTeamNumber_].heros
	local var_67_1 = arg_67_0.selectItems[arg_67_0.nowTeamNumber_].pet

	arg_67_0.selectTeams[arg_67_0.nowTeamNumber_].heros = {}
	arg_67_0.selectItems[arg_67_0.nowTeamNumber_].heros = {}
	arg_67_0.selectTeams[arg_67_0.nowTeamNumber_].pet = nil
	arg_67_0.selectItems[arg_67_0.nowTeamNumber_].pet = nil

	arg_67_0:initPreTeam(arg_67_0.nowTeamNumber_, {
		heros = arg_67_1,
		pet = arg_67_2
	}, true)
	arg_67_0:updateScore(arg_67_0.nowTeamNumber_)
	arg_67_0:changePresetTeamStatus()

	local var_67_2 = arg_67_0.selectItems[arg_67_0.nowTeamNumber_].heros
	local var_67_3 = arg_67_0.selectItems[arg_67_0.nowTeamNumber_].pet

	arg_67_0.isPresetAnimation = true

	local var_67_4 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_68_0, iter_68_1 in ipairs(var_67_0) do
				local var_68_0, var_68_1 = arg_67_0:nodeByName("avatar" .. iter_68_0):getPosition()

				arg_67_0:moveFadeOutAction(var_68_0, var_68_1, iter_68_1)
			end

			if var_67_1 then
				local var_68_2, var_68_3 = arg_67_0:nodeByName("avatar_pet"):getPosition()

				arg_67_0:moveFadeOutAction(var_68_2, var_68_3, var_67_1)
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_67_5 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_69_0, iter_69_1 in ipairs(var_67_2) do
				iter_69_1:show()

				local var_69_0, var_69_1 = arg_67_0:nodeByName("avatar" .. iter_69_0):getPosition()

				arg_67_0:moveFadeInAction(var_69_0, var_69_1, iter_69_1, function()
					arg_67_0.isPresetAnimation = false
				end)
			end

			if var_67_3 then
				var_67_3:show()

				local var_69_2, var_69_3 = arg_67_0:nodeByName("avatar_pet"):getPosition()

				arg_67_0:moveFadeInAction(var_69_2, var_69_3, var_67_3)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_67_0:runAction(transition.sequence({
		var_67_4,
		var_67_5
	}))
end

function var_0_0.updateBtnState(arg_71_0)
	if arg_71_0.containerState == var_0_11.PET then
		arg_71_0:nodeByName("button_pet"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_71_0:nodeByName("button_hero"):setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_71_0:nodeByName("button_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_71_0:nodeByName("button_pet"):setBrightStyle(ccui.BrightStyle.normal)
	end
end

function var_0_0.initPresetTeams(arg_72_0)
	arg_72_0.presetTeams = clone(arg_72_0.selfPlayer:getSaveTeams())
end

function var_0_0.checkHeroSelected(arg_73_0, arg_73_1)
	for iter_73_0, iter_73_1 in ipairs(arg_73_0.selectTeams) do
		for iter_73_2, iter_73_3 in ipairs(iter_73_1.heros) do
			if iter_73_3:getTableID() == arg_73_1:getTableID() then
				return true, iter_73_0
			end
		end
	end

	return false, nil
end

function var_0_0.checkPetSelected(arg_74_0, arg_74_1)
	for iter_74_0, iter_74_1 in ipairs(arg_74_0.selectTeams) do
		if iter_74_1.pet and iter_74_1.pet:getTableID() == arg_74_1:getTableID() then
			return true, iter_74_0
		end
	end

	return false, nil
end

function var_0_0.changePresetTeamStatus(arg_75_0)
	if arg_75_0.presetTeamCells and next(arg_75_0.presetTeamCells) then
		for iter_75_0, iter_75_1 in pairs(arg_75_0.presetTeamCells) do
			for iter_75_2, iter_75_3 in pairs(iter_75_1) do
				if iter_75_3 and iter_75_3.data then
					local var_75_0 = iter_75_3.data
					local var_75_1, var_75_2 = arg_75_0:checkHeroSelected(var_75_0)

					var_75_0.isUsed = var_75_2

					iter_75_3:getChildByName("avatar_mask"):setVisible(var_75_1)
					arg_75_0:showHeroCellTeam(var_75_2, iter_75_3)
				end
			end
		end
	end

	if arg_75_0.presetTeamPetCells and next(arg_75_0.presetTeamPetCells) then
		for iter_75_4, iter_75_5 in pairs(arg_75_0.presetTeamPetCells) do
			if iter_75_5 and iter_75_5.data then
				local var_75_3 = iter_75_5.data
				local var_75_4, var_75_5 = arg_75_0:checkPetSelected(var_75_3)

				var_75_3.isUsed = var_75_5

				iter_75_5:getChildByName("avatar_mask"):setVisible(var_75_4)
				iter_75_5:getChildByName("chosen"):setVisible(var_75_4)
				arg_75_0:showPetCellTeam(var_75_5, iter_75_5)
			end
		end
	end
end

function var_0_0.checkPresetTeamCanUse(arg_76_0, arg_76_1)
	local var_76_0 = arg_76_0.presetTeams[arg_76_1].team

	for iter_76_0 = 1, #var_76_0 do
		local var_76_1 = var_76_0[iter_76_0]

		if var_76_1.isUsed and var_76_1.isUsed ~= arg_76_0.nowTeamNumber_ or not arg_76_0:isSpecifyHero(var_76_1) then
			return false
		end
	end

	local var_76_2 = arg_76_0.presetTeams[arg_76_1].pet

	if var_76_2 and var_76_2.isUsed and var_76_2.isUsed ~= arg_76_0.nowTeamNumber_ then
		return false
	end

	return true
end

function var_0_0.refreshSelectedHeroClass(arg_77_0)
	for iter_77_0 = 1, #arg_77_0.heroClassButtons_ do
		if iter_77_0 == arg_77_0.selectedHeroClass_ then
			arg_77_0.heroClassButtons_[iter_77_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_77_0.heroClassButtons_[iter_77_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_77_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.normal)

	if arg_77_0.selectedHeroClass_ == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_77_0.selectedHeroClass_ ~= xyd.DistanceType.ALL then
		for iter_77_1, iter_77_2 in ipairs(arg_77_0.selectTeams[arg_77_0.nowTeamNumber_]) do
			if iter_77_2:getDistanceType() ~= arg_77_0.selectedHeroClass_ then
				arg_77_0.selectItems[arg_77_0.nowTeamNumber_].heros[iter_77_1].iniCellVisible_ = true
			end
		end
	end

	arg_77_0.heroList_:reload()
	arg_77_0:showTeamsByTeamNumber(arg_77_0.nowTeamNumber_)
end

function var_0_0.refreshSelectTeamClass(arg_78_0)
	for iter_78_0 = 1, #arg_78_0.teamButtons do
		if iter_78_0 == arg_78_0.nowTeamNumber_ then
			arg_78_0.teamButtons[iter_78_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_78_0.teamButtons[iter_78_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.buttonHandler(arg_79_0, arg_79_1, arg_79_2, arg_79_3)
	if not arg_79_2 or not arg_79_2:getParent() then
		return
	end

	if arg_79_3.name == "ended" then
		transition.stopTarget(arg_79_2)
		arg_79_2:setScale(1)

		if arg_79_1 then
			arg_79_1(arg_79_2, eventType)
		end
	elseif arg_79_3.name == "began" then
		local var_79_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_79_2:runAction(var_79_0)

		return true
	elseif arg_79_3.name == "cancled" then
		transition.stopTarget(arg_79_2)
		arg_79_2:setScale(1)
	end
end

function var_0_0.initPreHeros(arg_80_0)
	if not arg_80_0.preSelectTeams_ then
		return
	end

	for iter_80_0, iter_80_1 in ipairs(arg_80_0.preSelectTeams_) do
		arg_80_0:firstInitPreTeam(iter_80_0, iter_80_1)
	end

	arg_80_0.preSelectTeams_ = {}
end

function var_0_0.initPreTeam(arg_81_0, arg_81_1, arg_81_2, arg_81_3)
	for iter_81_0, iter_81_1 in pairs(arg_81_2.heros) do
		local var_81_0 = display.newNode()
		local var_81_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/hero_avatar.csb")
		local var_81_2 = var_81_1:getChildByName("background"):getContentSize()

		var_81_1:setContentSize(var_81_2)
		var_81_0:setContentSize(var_81_2)
		xyd.setAvatarBorderNewUI(iter_81_1, var_81_1:getChildByName("avatar"))
		var_81_1:setName("layout")

		var_81_0.data = iter_81_1
		var_81_0.invisible = arg_81_3

		var_81_0:addChild(var_81_1)
		var_81_0:setTouchSwallowEnabled(false)
		var_81_0:setTouchEnabled(true)
		arg_81_0:showHeroCellTeam(var_81_0.teamCount_, var_81_0:getChildByName("layout"))
		arg_81_0:clickAvatar(var_81_0, true, arg_81_1, true)
	end

	if arg_81_2.pet then
		local var_81_3 = display.newNode()

		var_81_3:setContentSize(var_0_10, var_0_10)
		xyd.setPetAvatarNewUI(var_81_3, arg_81_2.pet)

		var_81_3.data = arg_81_2.pet
		var_81_3.invisible = arg_81_3

		var_81_3:setTouchSwallowEnabled(false)
		var_81_3:setTouchEnabled(true)
		arg_81_0:clickPetAvatar(var_81_3, true, arg_81_1, true)
	end

	arg_81_0:updateScore(arg_81_1)
end

function var_0_0.firstInitPreTeam(arg_82_0, arg_82_1, arg_82_2)
	for iter_82_0, iter_82_1 in pairs(arg_82_2.heros) do
		local var_82_0 = display.newNode()
		local var_82_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/select_team_peak/hero_avatar.csb")
		local var_82_2 = var_82_1:getChildByName("background"):getContentSize()

		var_82_1:setContentSize(var_82_2)
		var_82_0:setContentSize(var_82_2)
		xyd.setAvatarBorderNewUI(iter_82_1, var_82_1:getChildByName("avatar"))
		var_82_1:setName("layout")

		var_82_0.data = iter_82_1

		var_82_0:addChild(var_82_1)
		var_82_0:setTouchSwallowEnabled(false)
		var_82_0:setTouchEnabled(true)
		arg_82_0:showHeroCellTeam(var_82_0.teamCount_, var_82_0:getChildByName("layout"))
		arg_82_0:initBottomAvatar(var_82_0, iter_82_0, arg_82_1)
	end

	if arg_82_2.pet then
		local var_82_3 = display.newNode()

		var_82_3:setContentSize(var_0_10, var_0_10)
		xyd.setPetAvatarNewUI(var_82_3, arg_82_2.pet)

		var_82_3.data = arg_82_2.pet

		var_82_3:setTouchSwallowEnabled(false)
		var_82_3:setTouchEnabled(true)
		arg_82_0:clickPetAvatar(var_82_3, true, arg_82_1, true)
	end

	arg_82_0:updateScore(arg_82_1)
end

function var_0_0.clickAvatar(arg_83_0, arg_83_1, arg_83_2, arg_83_3, arg_83_4)
	if arg_83_1.isAnimated_ or not arg_83_1.teamNo_ and #arg_83_0.selectTeams[arg_83_3].heros >= xyd.MAX_TEAM_MEMBER_NUM then
		return
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
			if #arg_83_0.selectTeams[arg_83_3].heros >= 5 then
				arg_83_1.isAnimated_ = false

				return
			end

			local var_83_6 = string.format(var_0_2:translation("PEAK_SELECT_TEAM_TIP"), xyd.tables.hero:name(arg_83_1.data:getTableID()))

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_83_6, function()
				local var_84_0 = arg_83_0.selectItems[arg_83_1.teamCount_].heros

				for iter_84_0 = #var_84_0, arg_83_1.teamNo_ + 1, -1 do
					local var_84_1 = var_84_0[iter_84_0]
					local var_84_2, var_84_3 = arg_83_0:nodeByName("avatar" .. iter_84_0 - 1):getPosition()

					transition.stopTarget(var_84_1)
					transition.moveTo(var_84_0[iter_84_0], {
						time = 0.3,
						x = var_84_2,
						y = var_84_3
					})

					var_84_0[iter_84_0].iniCell_.teamNo_ = iter_84_0 - 1
				end

				table.remove(var_84_0, arg_83_1.teamNo_)
				table.remove(arg_83_0.selectTeams[arg_83_1.teamCount_].heros, arg_83_1.teamNo_)
				arg_83_0:refreshTeamHeroNum(arg_83_1.teamCount_, #arg_83_0.selectTeams[arg_83_1.teamCount_].heros)
				arg_83_0:avatarToBottom(arg_83_1, var_83_4, var_83_5, var_83_1, var_83_2, arg_83_2, arg_83_3)
			end, {
				lcallback = function()
					arg_83_1.isAnimated_ = false
				end
			}, nil, arg_83_0.colorMode)
		else
			local var_83_7 = arg_83_0.selectItems[arg_83_3].heros[arg_83_1.teamNo_]

			arg_83_0:moveFadeOutAction(var_83_4, var_83_5, var_83_7, function()
				arg_83_1.isAnimated_ = false
			end)
			var_83_1:setVisible(false)
			var_83_2:setVisible(false)

			local var_83_8 = arg_83_0.selectItems[arg_83_3].heros

			for iter_83_0 = #var_83_8, arg_83_1.teamNo_ + 1, -1 do
				transition.stopTarget(var_83_8[iter_83_0])

				local var_83_9, var_83_10 = arg_83_0:nodeByName("avatar" .. iter_83_0 - 1):getPosition()

				transition.moveTo(var_83_8[iter_83_0], {
					time = 0.3,
					x = var_83_9,
					y = var_83_10
				})

				var_83_8[iter_83_0].iniCell_.teamNo_ = iter_83_0 - 1
			end

			arg_83_0:showHeroCellTeam(0, arg_83_1:getChildByName("layout"))
			table.remove(var_83_8, arg_83_1.teamNo_)
			table.remove(arg_83_0.selectTeams[arg_83_3].heros, arg_83_1.teamNo_)
			arg_83_0:refreshTeamHeroNum(arg_83_3)

			arg_83_1.teamNo_ = nil
			arg_83_1.teamCount_ = nil
		end
	elseif not arg_83_1.teamNo_ and #arg_83_0.selectTeams[arg_83_3].heros < xyd.MAX_TEAM_MEMBER_NUM then
		arg_83_0:avatarToBottom(arg_83_1, var_83_4, var_83_5, var_83_1, var_83_2, arg_83_2, arg_83_3)
	end

	if not arg_83_4 then
		arg_83_0:updateScore(arg_83_3)
	end
end

function var_0_0.refreshTeamHeroNum(arg_87_0, arg_87_1)
	local var_87_0 = #arg_87_0.selectTeams[arg_87_1].heros

	arg_87_0.teamButtons[arg_87_1]:getChildByName("txt_num"):setString("(" .. var_87_0 .. "/5)")
end

function var_0_0.avatarToBottom(arg_88_0, arg_88_1, arg_88_2, arg_88_3, arg_88_4, arg_88_5, arg_88_6, arg_88_7)
	if not arg_88_6 then
		local var_88_0 = arg_88_1.data

		if var_0_4:chosenSound(var_88_0:getTableID()) ~= "" then
			audio.playSound(var_0_4:chosenSound(var_88_0:getTableID()), false)
		end
	end

	local var_88_1 = arg_88_0:initBottomCell(arg_88_1.data)

	if arg_88_1.invisible then
		var_88_1:hide()

		arg_88_1.invisible = false
	end

	var_88_1.iniCell_ = arg_88_1
	var_88_1.teamCount_ = arg_88_7

	var_88_1:pos(arg_88_2, arg_88_3)
	var_88_1:addTo(arg_88_0:nodeByName("avatar_container"))
	var_88_1:setTouchEnabled(true)
	var_88_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_89_0)
		if arg_89_0.name == "ended" then
			arg_88_0:clickBottomAvatar(var_88_1)
		end

		return true
	end)

	arg_88_1.teamNo_ = arg_88_0:getTeamNo(var_88_1, arg_88_7)
	arg_88_1.teamCount_ = arg_88_7

	arg_88_0:showHeroCellTeam(arg_88_1.teamCount_, arg_88_1:getChildByName("layout"))

	local var_88_2 = arg_88_0.selectItems[arg_88_7].heros

	for iter_88_0 = arg_88_1.teamNo_, #var_88_2 do
		local var_88_3, var_88_4 = arg_88_0:nodeByName("avatar" .. iter_88_0):getPosition()

		if arg_88_6 then
			var_88_2[iter_88_0]:pos(var_88_3, var_88_4)

			arg_88_1.isAnimated_ = false
		elseif iter_88_0 ~= arg_88_1.teamNo_ then
			local var_88_5 = var_88_2[iter_88_0]

			transition.stopTarget(var_88_5)
			transition.moveTo(var_88_5, {
				time = 0.3,
				x = var_88_3,
				y = var_88_4,
				onComplete = function()
					var_88_5.iniCell_.isAnimated_ = false
					var_88_5.isAnimated_ = false
				end
			})
		else
			local var_88_6 = var_88_2[iter_88_0]

			transition.stopTarget(var_88_6)

			var_88_1.isAnimated_ = true

			transition.moveTo(var_88_6, {
				time = 0.3,
				x = var_88_3,
				y = var_88_4,
				onComplete = function()
					arg_88_1.isAnimated_ = false
					var_88_1.isAnimated_ = false
				end
			})
		end

		var_88_2[iter_88_0].iniCell_.teamNo_ = iter_88_0
	end

	arg_88_4:setVisible(true)
	arg_88_5:setVisible(true)
end

function var_0_0.initBottomAvatar(arg_92_0, arg_92_1, arg_92_2, arg_92_3)
	local var_92_0 = arg_92_0:initBottomCell(arg_92_1.data)

	if arg_92_1.invisible then
		var_92_0:hide()

		arg_92_1.invisible = false
	end

	var_92_0.iniCell_ = arg_92_1
	var_92_0.teamCount_ = arg_92_3

	var_92_0:setPosition(arg_92_0:nodeByName("avatar" .. arg_92_2):getPosition())
	var_92_0:addTo(arg_92_0:nodeByName("avatar_container"))
	var_92_0:setTouchEnabled(true)
	var_92_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_93_0)
		if arg_93_0.name == "ended" then
			arg_92_0:clickBottomAvatar(var_92_0)
		end

		return true
	end)

	arg_92_1.teamNo_ = arg_92_0:getTeamNo(var_92_0, arg_92_3)
	arg_92_1.teamCount_ = arg_92_3

	arg_92_0:showHeroCellTeam(arg_92_1.teamCount_, arg_92_1:getChildByName("layout"))

	arg_92_1.isAnimated_ = false

	local var_92_1 = arg_92_1:getChildByName("layout")
	local var_92_2 = var_92_1:getChildByName("avatar_mask")
	local var_92_3 = var_92_1:getChildByName("chosen")

	var_92_2:setVisible(true)
	var_92_3:setVisible(true)
end

function var_0_0.updateScore(arg_94_0, arg_94_1)
	arg_94_0.scores[arg_94_1] = 0

	for iter_94_0, iter_94_1 in ipairs(arg_94_0.selectItems[arg_94_1].heros) do
		arg_94_0.scores[arg_94_1] = arg_94_0.scores[arg_94_1] + iter_94_1.data:getZhandouli()
	end

	local var_94_0 = arg_94_0.selectItems[arg_94_1].pet

	if var_94_0 then
		arg_94_0.scores[arg_94_1] = arg_94_0.scores[arg_94_1] + var_94_0.data:getZhandouli()
	end

	arg_94_0:nodeByName("zhandouli"):setString(arg_94_0.scores[arg_94_0.nowTeamNumber_])
end

function var_0_0.clickBottomAvatar(arg_95_0, arg_95_1)
	if arg_95_1.isAnimated_ or arg_95_0.switchMode == 1 then
		return
	end

	local var_95_0 = arg_95_1.teamCount_
	local var_95_1, var_95_2 = arg_95_0:nodeByName("list_layer"):getPosition()
	local var_95_3 = arg_95_1.iniCell_
	local var_95_4

	for iter_95_0, iter_95_1 in ipairs(arg_95_0.selectTeams[var_95_0].heros) do
		if iter_95_1:getTableID() == arg_95_1.data:getTableID() then
			var_95_4 = iter_95_0

			break
		end
	end

	if not var_95_4 then
		return
	end

	if not arg_95_1.iniCellVisible_ and not tolua.isnull(var_95_3) then
		local var_95_5 = var_95_3:convertToWorldSpace(cc.p(0, 0))

		var_95_1, var_95_2 = var_95_5.x + var_95_3:getContentSize().width / 2, var_95_5.y + var_95_3:getContentSize().height / 2

		local var_95_6 = var_95_3:getChildByName("layout")
		local var_95_7 = var_95_6:getChildByName("avatar_mask")
		local var_95_8 = var_95_6:getChildByName("chosen")

		var_95_7:setVisible(false)
		var_95_8:setVisible(false)
		arg_95_0:showHeroCellTeam(0, var_95_6)
	end

	arg_95_0:moveFadeOutAction(var_95_1, var_95_2, arg_95_1)

	local var_95_9 = arg_95_0.selectItems[var_95_0].heros

	for iter_95_2 = #var_95_9, var_95_4 + 1, -1 do
		local var_95_10 = var_95_9[iter_95_2]
		local var_95_11, var_95_12 = arg_95_0:nodeByName("avatar" .. iter_95_2 - 1):getPosition()

		transition.stopTarget(var_95_10)
		transition.moveTo(var_95_9[iter_95_2], {
			time = 0.3,
			x = var_95_11,
			y = var_95_12
		})

		var_95_9[iter_95_2].iniCell_.teamNo_ = iter_95_2 - 1
	end

	table.remove(var_95_9, var_95_4)
	table.remove(arg_95_0.selectTeams[var_95_0].heros, var_95_4)
	arg_95_0:refreshTeamHeroNum(var_95_0)

	var_95_3.teamNo_ = nil
	var_95_3.teamCount_ = nil

	arg_95_0:updateScore(var_95_0)

	if arg_95_0.isHeroPreset then
		arg_95_0:changePresetTeamStatus()
	end
end

function var_0_0.getTeamNo(arg_96_0, arg_96_1, arg_96_2)
	local var_96_0 = arg_96_0.selectItems[arg_96_2].heros

	for iter_96_0, iter_96_1 in ipairs(var_96_0) do
		if arg_96_1.data:getDistance() < iter_96_1.data:getDistance() then
			table.insert(var_96_0, iter_96_0, arg_96_1)
			table.insert(arg_96_0.selectTeams[arg_96_2].heros, iter_96_0, arg_96_1.data)
			arg_96_0:refreshTeamHeroNum(arg_96_2)

			return iter_96_0
		end
	end

	table.insert(var_96_0, arg_96_1)
	table.insert(arg_96_0.selectTeams[arg_96_2].heros, arg_96_1.data)
	arg_96_0:refreshTeamHeroNum(arg_96_2)

	return #var_96_0
end

function var_0_0.getPetTeamNo(arg_97_0, arg_97_1, arg_97_2)
	arg_97_0.selectItems[arg_97_2].pet = arg_97_1
	arg_97_0.selectTeams[arg_97_2].pet = arg_97_1.data

	return 1
end

function var_0_0.moveFadeOutAction(arg_98_0, arg_98_1, arg_98_2, arg_98_3, arg_98_4)
	arg_98_0:widgetSet(arg_98_3)
	arg_98_3:setCascadeOpacityEnabled(true)

	local var_98_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_98_1, arg_98_2)))

	arg_98_3:runActionOnce(var_98_0, true, arg_98_4)
end

function var_0_0.moveFadeInAction(arg_99_0, arg_99_1, arg_99_2, arg_99_3, arg_99_4)
	arg_99_0:widgetSet(arg_99_3)
	arg_99_3:setCascadeOpacityEnabled(true)
	arg_99_3:setOpacity(0)

	local var_99_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_99_1, arg_99_2)))

	arg_99_3:runActionOnce(var_99_0, false, arg_99_4)
end

function var_0_0.getBattleBtn(arg_100_0)
	if not arg_100_0.battleBtn_ then
		if arg_100_0.type == xyd.SelectTeamType.PEAK_ARENA_DEFENSE then
			arg_100_0.battleBtn_ = arg_100_0:nodeByName("button_ok")

			arg_100_0.battleBtn_:addTouchEventListener(function(arg_101_0, arg_101_1)
				xyd.buttonScaleAnim(arg_101_0, arg_101_1)
				arg_100_0:checkTeamValid()

				if arg_101_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()
					arg_100_0.peakArena:changeTeam(arg_100_0.selectTeams, function()
						local var_102_0 = xyd.WindowManager.get():getWindow("peak_arena")

						if var_102_0 then
							var_102_0:updateDefendTeam()
						end

						xyd.WindowManager.get():closeWindow("select_team_peak")
					end)
				end
			end)
		else
			arg_100_0.battleBtn_ = arg_100_0:nodeByName("button_battle")

			arg_100_0.battleBtn_:addTouchEventListener(function(arg_103_0, arg_103_1)
				xyd.buttonScaleAnim(arg_103_0, arg_103_1)

				if arg_100_0:checkTeamValid() then
					return
				end

				if arg_103_1 == ccui.TouchEventType.ended and not arg_100_0.battleBegan then
					xyd.playButtonSound()

					arg_100_0.battleBegan = true

					arg_100_0:startBattle()
				end
			end)
		end
	end

	return arg_100_0.battleBtn_
end

function var_0_0.checkTeamValid(arg_104_0)
	for iter_104_0 = 1, arg_104_0.teamNum do
		if #arg_104_0.selectTeams[iter_104_0].heros < 1 then
			local var_104_0 = string.format(var_0_2:translation("PEAK_SELECT_TEAM_TIP_2"), iter_104_0)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_104_0, nil, nil, nil, arg_104_0.colorMode)

			return true
		end
	end
end

function var_0_0.recordFormation(arg_105_0)
	arg_105_0.peakArena:setAttackTeams(arg_105_0.selectTeams)
	arg_105_0.peakArena:setEnemyMatched(arg_105_0.enemyMatched)

	local var_105_0 = arg_105_0.peakArena:generatePartnerIds(arg_105_0.selectTeams)
	local var_105_1

	for iter_105_0, iter_105_1 in ipairs(var_105_0) do
		if iter_105_0 == 1 then
			var_105_1 = "" .. iter_105_1
		else
			var_105_1 = var_105_1 .. "," .. iter_105_1
		end
	end

	xyd.db.formation:setFormationData(arg_105_0.campaignType, var_105_1)
end

function var_0_0.startBattle(arg_106_0)
	if arg_106_0.type == xyd.SelectTeamType.PEAK_ARENA then
		arg_106_0:recordFormation()
		arg_106_0:startPeakArenaBattle()
	end
end

function var_0_0.startPeakArenaBattle(arg_107_0)
	local var_107_0 = arg_107_0.peakArena.point
	local var_107_1 = {
		formations = arg_107_0.peakArena:generatePartnerIds(arg_107_0.selectTeams),
		enemy_id = arg_107_0.enemyInfo.player_id
	}

	arg_107_0.peakArena:startFight(var_107_1, function(arg_108_0, arg_108_1)
		if arg_108_0 == xyd.error.OK then
			if arg_108_1.error_code then
				if arg_108_1.error_code == 30002 then
					local var_108_0 = xyd.tables.message:getContent(30002)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_108_0
					})

					return
				elseif arg_108_1.error_code == 30003 then
					local var_108_1 = xyd.tables.message:getContent(30003)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_108_1
					})

					return
				end
			end

			if arg_108_1.partner_favor then
				xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY):refreshPartnersFavor(arg_108_1.partner_favor)
			end

			local var_108_2 = {
				player_id = arg_107_0.selfPlayer.playerID,
				player_name = arg_107_0.selfPlayer.playerName,
				lev = arg_107_0.selfPlayer.lev,
				conquer_lev = arg_107_0.selfPlayer.conquerLev,
				avatar_id = arg_107_0.selfPlayer.avatarId,
				avatar_frame_id = arg_107_0.selfPlayer.avatarFrame
			}
			local var_108_3 = {
				withWin = true,
				fromSelectPeak = true,
				reportKeys = arg_108_1.report_keys,
				isWin = arg_108_1.is_win,
				wins = arg_108_1.wins,
				attackInfo = var_108_2,
				defendInfo = arg_107_0.enemyInfo,
				attackTeam = arg_107_0.selectTeams,
				defendTeam = arg_107_0.enemyTeams,
				oldScore = var_107_0
			}

			if arg_108_1.items then
				var_108_3.awards = {}

				for iter_108_0, iter_108_1 in pairs(arg_108_1.items) do
					local var_108_4 = {
						table_id = iter_108_1.item_id,
						item_num = iter_108_1.item_num
					}

					table.insert(var_108_3.awards, var_108_4)
				end
			end

			xyd.WindowManager.get():openWindow("peak_arena_report", var_108_3)
			xyd.WindowManager.get():closeWindow("select_team_peak")
			xyd.WindowManager.get():closeWindow("change_enemy")

			local var_108_5 = xyd.WindowManager.get():getWindow("peak_arena")

			if var_108_5 then
				var_108_5:updateRank()
				var_108_5:updateChallengeBtnTxt()
				var_108_5:updateLeftTimes()
			end
		else
			arg_107_0.battleBegan = false
		end
	end)
end

function var_0_0.startTimer(arg_109_0)
	local var_109_0 = var_0_2:translation("ARENA_PREPARATION_COUNTDOWN")
	local var_109_1 = xyd.ServerTime.get():getServerTime()
	local var_109_2 = xyd.createLabel(18, cc.c3b(77, 87, 142))
	local var_109_3 = arg_109_0:nodeByName("list_layer_battle"):getContentSize()

	var_109_2:setString(string.format(var_109_0, var_0_12))
	var_109_2:setAnchorPoint(0.5, 0.5)
	var_109_2:addTo(arg_109_0:nodeByName("list_layer_battle"))
	var_109_2:setPosition(var_109_3.width / 2, var_109_3.height + 14)

	if arg_109_0.timerHandle then
		var_0_1.unscheduleGlobal(arg_109_0.timerHandle)

		arg_109_0.timerHandle = nil
	end

	arg_109_0.timerHandle = var_0_1.scheduleGlobal(function()
		local var_110_0 = xyd.ServerTime.get():getServerTime()
		local var_110_1 = var_109_1 + var_0_12 - var_110_0

		if var_110_1 >= 0 then
			var_109_2:setString(string.format(var_109_0, var_110_1))
		else
			if arg_109_0.timerHandle then
				var_0_1.unscheduleGlobal(arg_109_0.timerHandle)

				arg_109_0.timerHandle = nil
			end

			arg_109_0:close()
		end
	end, 1)
end

function var_0_0.willClose(arg_111_0)
	if arg_111_0.timerHandle then
		var_0_1.unscheduleGlobal(arg_111_0.timerHandle)

		arg_111_0.timerHandle = nil
	end
end

return var_0_0
