local var_0_0 = class("BaseSelectTeamNewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 16
local var_0_4 = 5
local var_0_5 = 4
local var_0_6 = 6
local var_0_7 = 50
local var_0_8 = 108
local var_0_9 = import("framework.scheduler")
local var_0_10 = xyd.tables.translation
local var_0_11 = xyd.tables.battle
local var_0_12 = xyd.tables.hero
local var_0_13 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_14 = {
	RENT_HERO = 1,
	RENT_PET = 2
}
local var_0_15 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_16 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.CAMPAIGN
	arg_1_0.campaignType = arg_1_2.campaignType or xyd.CampaignType.NORMAL
	arg_1_0.campaignID = arg_1_2.campaignID or 0
	arg_1_0.totalPet_ = {}
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0.totalHero_) do
		iter_1_1[var_0_16.NO] = {}
		iter_1_1[var_0_16.YES] = {}
	end

	arg_1_0.totalIDs_ = {}
	arg_1_0.team_ = {}
	arg_1_0.petTeam_ = {}
	arg_1_0.select_ = {}
	arg_1_0.tmpTotalPets = {}
	arg_1_0.petSelect_ = arg_1_2.petSelect or {}
	arg_1_0.preSelect_ = arg_1_2.selected or {}
	arg_1_0.enemyHeroes_ = arg_1_2.enemyHeroes
	arg_1_0.isMercenary = arg_1_2.isMercenary or false
	arg_1_0.allTeamHeros = arg_1_2.allTeamHeros or {}
	arg_1_0.allTeamPets = {}
	arg_1_0.battleBegan = false
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.isSelectMerHero = false
	arg_1_0.selectMerHero = nil
	arg_1_0.isSelectMerPet = false
	arg_1_0.selectMerPet = nil
	arg_1_0.ischangeListRect = false
	arg_1_0.tmpTotalHero_ = {}
	arg_1_0.preHeros_ = arg_1_2.preHeros or {}
	arg_1_0.prePet_ = arg_1_2.prePet or {}
	arg_1_0.star_ = arg_1_2.star
	arg_1_0.enemyPets_ = arg_1_2.enemyPets
	arg_1_0.isLoadAllTeamPets = false
	arg_1_0.showEnemy = arg_1_2.showEnemy
	arg_1_0.hide_counts = arg_1_2.hide_counts
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.selectedHeroClass_ = {}
	arg_1_0.battleID = arg_1_2.battleID

	if arg_1_0.campaignID > 0 and not arg_1_0.battleID then
		arg_1_0.battleID = xyd.tables.campaign:fightID(arg_1_0.campaignID)
	end

	arg_1_0.regionAwards = arg_1_2.awards or {}
	arg_1_0.presetTeams = {}
	arg_1_0.assistID = arg_1_2.assistID
	arg_1_0.assistHeroID = arg_1_2.assistHeroID
	arg_1_0.selectSpType = arg_1_2.selectSpType or 0
	arg_1_0.isFirstInitPreHero = false
	arg_1_0.collocationType_ = var_0_16.NO
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	if not next(arg_2_0.preSelect_) and arg_2_0:checkCanLoadPreFormation() then
		arg_2_0:loadPreFormation()
	end

	arg_2_0:initHeros(arg_2_0:getHeros(), xyd.LeftMenuType.SELF_HERO)
	arg_2_0:initHeros(arg_2_0.allTeamHeros, xyd.LeftMenuType.RENT_HERO)
	arg_2_0:initPets(arg_2_0:getPets() or {}, xyd.PetType.SELF_PET)
	arg_2_0:initPresetTeams()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:spTypeDeal()
	arg_3_0:refreshSelectedHeroClass()
	arg_3_0:getBattleBtn()
	arg_3_0:playGuide()
	arg_3_0:updateScore()
	arg_3_0:afterOpen()
end

function var_0_0.spTypeDeal(arg_4_0)
	if arg_4_0.selectSpType == xyd.SelectSpType.SINGLE then
		for iter_4_0 = 2, 5 do
			arg_4_0:nodeByName("select_lock_self" .. iter_4_0):setVisible(true)
			arg_4_0:nodeByName("select_lock_enemy" .. iter_4_0):setVisible(true)
		end
	elseif arg_4_0.selectSpType == xyd.SelectSpType.TRIPLE then
		for iter_4_1 = 4, 5 do
			arg_4_0:nodeByName("select_lock_self" .. iter_4_1):setVisible(true)
			arg_4_0:nodeByName("select_lock_enemy" .. iter_4_1):setVisible(true)
		end
	end
end

function var_0_0.afterOpen(arg_5_0)
	if arg_5_0.isAssistBattle then
		local var_5_0 = cc.p(0, 0)

		if arg_5_0.assistHeroNode and not tolua.isnull(arg_5_0.assistHeroNode) then
			var_5_0 = arg_5_0.assistHeroNode:getParent():convertToWorldSpace(cc.p(arg_5_0.assistHeroNode:getPosition()))
		end

		local var_5_1 = {
			table_id = arg_5_0.assistHeroID,
			pos = var_5_0,
			callback = function()
				if arg_5_0.assistHeroNode and not tolua.isnull(arg_5_0.assistHeroNode) then
					local var_6_0 = cc.p(arg_5_0.assistHeroNode:getPosition())

					arg_5_0.assistHeroNode:setVisible(true)
					arg_5_0:moveFadeInAction(var_6_0.x, var_6_0.y, arg_5_0.assistHeroNode)
				end
			end
		}

		xyd.WindowManager.get():openWindow("assist_hero_show", var_5_1)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_5_0, arg_5_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_5_0, arg_5_0.updateListBySearchTxt))
end

function var_0_0.updateList(arg_7_0, ...)
	if arg_7_0.leftMenuType_ ~= xyd.LeftMenuType.SELF_HERO then
		return
	end

	arg_7_0.selectedHeroClass_[arg_7_0.leftMenuType_] = xyd.DistanceType.FILTER
	arg_7_0.isHeroPreset = false

	arg_7_0:updateFilterHeros()
	arg_7_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_8_0, arg_8_1)
	if arg_8_0.leftMenuType_ ~= var_0_13.SELF_HERO then
		return
	end

	arg_8_0.searchTxt = arg_8_1.heroName
	arg_8_0.selectedHeroClass_[arg_8_0.leftMenuType_] = xyd.DistanceType.SEARCH

	arg_8_0:updateSearchHeros()
	arg_8_0:refreshSelectedHeroClass()
end

function var_0_0.initEnemys(arg_9_0)
	local var_9_0 = 1
	local var_9_1 = 0

	for iter_9_0, iter_9_1 in pairs(arg_9_0.enemyHeroes_) do
		var_9_1 = var_9_1 + 1
	end

	table.sort(arg_9_0.enemyHeroes_, function(arg_10_0, arg_10_1)
		return arg_10_0:getDistance() < arg_10_1:getDistance()
	end)

	for iter_9_2, iter_9_3 in pairs(arg_9_0.enemyHeroes_) do
		if arg_9_0.hide_counts and var_9_1 - var_9_0 + 1 < arg_9_0.hide_counts then
			local var_9_2 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

			xyd.displaySpriteOnContainer(var_9_2, arg_9_0:nodeByName("enemy_hero_" .. var_9_0), true)
		else
			xyd.setAvatarBorderNewUI(iter_9_3, arg_9_0:nodeByName("enemy_hero_" .. var_9_0))
		end

		var_9_0 = var_9_0 + 1
	end

	if arg_9_0.enemyPets_ then
		if arg_9_0.hide_counts and arg_9_0.hide_counts >= 1 then
			local var_9_3 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/pet_hide.png")

			xyd.displaySpriteOnContainer(var_9_3, arg_9_0:nodeByName("enemy_pet"), true)
		else
			xyd.setPetAvatarNewUI(arg_9_0:nodeByName("enemy_pet"), arg_9_0.enemyPets_, 100, true)
		end
	end
end

function var_0_0.layout(arg_11_0)
	arg_11_0:specialLayout()
	arg_11_0:initRightMenu()
	arg_11_0:initLeftMenu()
	arg_11_0:initTopRentMenu()
	arg_11_0:selectHeros()
	arg_11_0:selectPets()
	arg_11_0:initListview()
	arg_11_0:updateListPosByLeftMenu()
	arg_11_0:checkHeroIcon()
	arg_11_0:nodeByName("title"):setString(var_0_10:translation("SELECT_TEAM_TEXT_2"))
end

function var_0_0.checkHeroIcon(arg_12_0)
	arg_12_0:nodeByName("icon_hero"):setVisible(false)
	arg_12_0:nodeByName("no_hero_text"):setVisible(false)

	if arg_12_0.isHeroPreset then
		if #arg_12_0.presetTeams == 0 then
			arg_12_0:nodeByName("icon_hero"):setVisible(true)
			arg_12_0:nodeByName("no_hero_text"):setVisible(true)
			arg_12_0:nodeByName("icon_hero"):y(arg_12_0.heroList_:getViewRect().height / 2 + 10)
			arg_12_0:nodeByName("no_hero_text"):y(arg_12_0:nodeByName("icon_hero"):getPositionY() - arg_12_0:nodeByName("icon_hero"):getContentSize().height / 2)
			arg_12_0:nodeByName("no_hero_text"):setString(var_0_10:translation("SELECT_TEAM_TEXT_3"))
		end
	elseif arg_12_0.leftMenuType_ == var_0_13.SELF_PET or arg_12_0.leftMenuType_ == var_0_13.RENT_HERO and arg_12_0.rentMenuType == var_0_14.RENT_PET then
		if #arg_12_0.totalPet_ == 0 then
			arg_12_0:nodeByName("icon_hero"):setVisible(true)
			arg_12_0:nodeByName("no_hero_text"):setVisible(true)
			arg_12_0:nodeByName("icon_hero"):y(arg_12_0.heroList_:getViewRect().height / 2 + 10)
			arg_12_0:nodeByName("no_hero_text"):y(arg_12_0:nodeByName("icon_hero"):getPositionY() - arg_12_0:nodeByName("icon_hero"):getContentSize().height / 2)

			if arg_12_0.leftMenuType_ == var_0_13.SELF_PET then
				arg_12_0:nodeByName("no_hero_text"):setString(var_0_10:translation("SELECT_TEAM_TEXT_4"))
			elseif arg_12_0.leftMenuType_ == var_0_13.RENT_HERO then
				arg_12_0:nodeByName("no_hero_text"):setString(var_0_10:translation("SELECT_TEAM_TEXT_5"))
			elseif arg_12_0.rentMenuType == var_0_14.RENT_PET then
				arg_12_0:nodeByName("no_hero_text"):setString(var_0_10:translation("SELECT_TEAM_TEXT_6"))
			end
		end
	elseif #arg_12_0.totalHero_[arg_12_0.selectedHeroClass_[arg_12_0.leftMenuType_]][arg_12_0.collocationType_] == 0 then
		arg_12_0:nodeByName("icon_hero"):setVisible(true)
		arg_12_0:nodeByName("no_hero_text"):setVisible(true)
		arg_12_0:nodeByName("icon_hero"):y(arg_12_0.heroList_:getViewRect().height / 2 + 10)
		arg_12_0:nodeByName("no_hero_text"):y(arg_12_0:nodeByName("icon_hero"):getPositionY() - arg_12_0:nodeByName("icon_hero"):getContentSize().height / 2)
		arg_12_0:nodeByName("no_hero_text"):setString(var_0_10:translation("SELECT_TEAM_TEXT_7"))
	end

	if arg_12_0.heroList_:getViewRect().height < arg_12_0:nodeByName("icon_hero"):getContentSize().height then
		arg_12_0:nodeByName("icon_hero"):setVisible(false)
		arg_12_0:nodeByName("no_hero_text"):setVisible(false)
	end
end

function var_0_0.specialLayout(arg_13_0)
	arg_13_0:nodeByName("recommend_layer"):setVisible(false)

	if arg_13_0.showEnemy then
		arg_13_0:nodeByName("battle_team_bg"):setVisible(true)
		arg_13_0:nodeByName("list_layer"):height(300)
		arg_13_0:initEnemys()
	else
		arg_13_0:nodeByName("battle_team_bg"):setVisible(false)
	end
end

function var_0_0.initRightMenu(arg_14_0)
	arg_14_0.rightMenuButtons_ = {}

	table.insert(arg_14_0.rightMenuButtons_, arg_14_0:nodeByName("button_all"))
	table.insert(arg_14_0.rightMenuButtons_, arg_14_0:nodeByName("button_qianpai"))
	table.insert(arg_14_0.rightMenuButtons_, arg_14_0:nodeByName("button_zhongpai"))
	table.insert(arg_14_0.rightMenuButtons_, arg_14_0:nodeByName("button_houpai"))
	table.insert(arg_14_0.rightMenuButtons_, arg_14_0:nodeByName("button_filter"))
	table.insert(arg_14_0.rightMenuButtons_, arg_14_0:nodeByName("button_search"))

	arg_14_0.rightMenuText_ = {}

	table.insert(arg_14_0.rightMenuText_, arg_14_0:nodeByName("all"))
	table.insert(arg_14_0.rightMenuText_, arg_14_0:nodeByName("qianpai"))
	table.insert(arg_14_0.rightMenuText_, arg_14_0:nodeByName("zhongpai"))
	table.insert(arg_14_0.rightMenuText_, arg_14_0:nodeByName("houpai"))

	for iter_14_0 = 1, #arg_14_0.rightMenuButtons_ do
		arg_14_0.rightMenuButtons_[iter_14_0]:setZoomScale(0.3)
		arg_14_0.rightMenuButtons_[iter_14_0]:addTouchEventListener(function(arg_15_0, arg_15_1)
			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_14_0.selectedHeroClass_[arg_14_0.leftMenuType_] == iter_14_0 and not arg_14_0.isHeroPreset then
					for iter_15_0 = 1, #arg_14_0.rightMenuButtons_ do
						if iter_15_0 == arg_14_0.selectedHeroClass_[arg_14_0.leftMenuType_] then
							arg_14_0.rightMenuButtons_[iter_15_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_14_0.rightMenuButtons_[iter_15_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_14_0.isHeroPreset = false
				arg_14_0.selectedHeroClass_[arg_14_0.leftMenuType_] = iter_14_0

				arg_14_0:refreshSelectedHeroClass()
			end
		end)
	end

	if arg_14_0:checkCanPresetTeam() then
		arg_14_0:nodeByName("button_preset"):setZoomScale(0.3)
		arg_14_0:nodeByName("button_preset"):addTouchEventListener(function(arg_16_0, arg_16_1)
			if arg_16_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if not arg_14_0.isHeroPreset then
					arg_14_0.isHeroPreset = true
					arg_14_0.leftMenuType_ = xyd.LeftMenuType.SELF_HERO

					arg_14_0:updateListPosByLeftMenu()
					arg_14_0:selectHeros()
					arg_14_0:selectPets()

					if arg_14_0.leftMenuButtons_ then
						for iter_16_0, iter_16_1 in ipairs(arg_14_0.leftMenuButtons_) do
							iter_16_1:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					for iter_16_2 = 1, #arg_14_0.rightMenuButtons_ do
						arg_14_0.rightMenuButtons_[iter_16_2]:setBrightStyle(ccui.BrightStyle.normal)
					end

					arg_14_0.heroList_:reload()
					arg_14_0:checkHeroIcon()
				end

				arg_14_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
			end
		end)
	else
		arg_14_0:nodeByName("button_preset"):setVisible(false)
	end

	arg_14_0:nodeByName("text_filter"):setString(var_0_10:translation("FILTER_TEXT"))
	arg_14_0:nodeByName("button_filter"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			if arg_14_0.leftMenuType_ ~= var_0_13.SELF_HERO then
				return
			end

			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_14_0:nodeByName("button_search"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			if arg_14_0.leftMenuType_ ~= var_0_13.SELF_HERO then
				return
			end

			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_14_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			if arg_14_0.leftMenuType_ ~= var_0_13.SELF_HERO then
				return
			end

			arg_14_0.collocationType_ = 3 - arg_14_0.collocationType_

			arg_14_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.initLeftMenu(arg_20_0)
	arg_20_0:nodeByName("button_zhandui"):hide()

	arg_20_0:nodeByName("button_zhandui").menu_type = xyd.LeftMenuType.SELF_HERO

	arg_20_0:nodeByName("button_yongbing"):hide()

	arg_20_0:nodeByName("button_yongbing").menu_type = xyd.LeftMenuType.RENT_HERO

	arg_20_0:nodeByName("button_pet"):hide()

	arg_20_0:nodeByName("button_pet").menu_type = xyd.LeftMenuType.SELF_PET
	arg_20_0.leftMenuType_ = xyd.LeftMenuType.SELF_HERO
	arg_20_0.leftMenuButtons_, arg_20_0.leftMenuText_ = {}, {}

	table.insert(arg_20_0.leftMenuButtons_, arg_20_0:nodeByName("button_zhandui"))
	arg_20_0:nodeByName("button_zhandui"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_20_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)

	if arg_20_0:canRentHero() then
		table.insert(arg_20_0.leftMenuButtons_, arg_20_0:nodeByName("button_yongbing"))
	end

	if arg_20_0:isPet() then
		arg_20_0:nodeByName("rate_bg"):setVisible(false)
		table.insert(arg_20_0.leftMenuButtons_, arg_20_0:nodeByName("button_pet"))
	else
		arg_20_0:nodeByName("avatar_pet1"):hide()
		arg_20_0:nodeByName("bg_pet"):hide()

		if arg_20_0.type == xyd.SelectTeamType.ADVANCED then
			arg_20_0:nodeByName("rate_bg"):setVisible(true)
		else
			arg_20_0:nodeByName("rate_bg"):setVisible(false)
		end

		for iter_20_0 = 1, 5 do
			arg_20_0:nodeByName("avatar" .. iter_20_0):x(arg_20_0:nodeByName("avatar" .. iter_20_0):getX() - 127)
			arg_20_0:nodeByName("select_lock_self" .. iter_20_0):x(arg_20_0:nodeByName("select_lock_self" .. iter_20_0):getX() - 127)
			arg_20_0:nodeByName("bg_hero" .. iter_20_0):x(arg_20_0:nodeByName("bg_hero" .. iter_20_0):getX() - 127)
		end
	end

	if not arg_20_0.noPreset and arg_20_0:checkCanPresetTeam() then
		arg_20_0:nodeByName("button_preset"):y(arg_20_0.leftMenuButtons_[1]:getY() - 74 * #arg_20_0.leftMenuButtons_)
	else
		arg_20_0:nodeByName("button_preset"):setVisible(false)
	end

	if #arg_20_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_20_1 = 1, #arg_20_0.leftMenuButtons_ do
		arg_20_0.leftMenuButtons_[iter_20_1]:show()
		arg_20_0.leftMenuButtons_[iter_20_1]:setZoomScale(0.3)

		local var_20_0 = arg_20_0.leftMenuButtons_[1]:getY() - 74 * (iter_20_1 - 1)

		arg_20_0.leftMenuButtons_[iter_20_1]:y(var_20_0)
		arg_20_0.leftMenuButtons_[iter_20_1]:addTouchEventListener(function(arg_21_0, arg_21_1)
			if arg_21_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_21_0, iter_21_1 in ipairs(arg_20_0.leftMenuButtons_) do
					iter_21_1:setBrightStyle(arg_21_0 == iter_21_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_20_0.leftMenuType_ = arg_21_0.menu_type
				arg_20_0.isHeroPreset = false
				arg_20_0.rentMenuType = xyd.RentMenuType.RENT_HERO

				arg_20_0:updateListPosByLeftMenu()
				arg_20_0:selectHeros()
				arg_20_0:selectPets()
				arg_20_0:refreshSelectedHeroClass()
			end
		end)
	end
end

function var_0_0.initTopRentMenu(arg_22_0)
	arg_22_0:nodeByName("top_rent_container"):setVisible(false)
	arg_22_0:nodeByName("rent_bg"):setVisible(false)

	arg_22_0.rentMenuType = xyd.RentMenuType.RENT_HERO

	if not arg_22_0:canRentHero() then
		return
	end

	arg_22_0:nodeByName("btn_rent_hero"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_22_0.rentMenuType = xyd.RentMenuType.RENT_HERO

			arg_22_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_22_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_22_0:selectPets()
			arg_22_0:updateListPosByLeftMenu()
			arg_22_0.heroList_:reload()
			arg_22_0:checkHeroIcon()
		end
	end)
	arg_22_0:nodeByName("btn_rent_pet"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended and not arg_22_0.isClickRentPet then
			arg_22_0.isClickRentPet = true

			xyd.playButtonSound()

			arg_22_0.rentMenuType = xyd.RentMenuType.RENT_PET

			arg_22_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.normal)
			arg_22_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_22_0:initRentPets(function()
				arg_22_0:selectPets()
				arg_22_0:updateListPosByLeftMenu()
				arg_22_0.heroList_:reload()
				arg_22_0:checkHeroIcon()

				arg_22_0.isClickRentPet = false
			end)
		end
	end)
end

function var_0_0.initRentPets(arg_26_0, arg_26_1)
	if not arg_26_0.isLoadAllTeamPets then
		local var_26_0 = {}

		arg_26_0.guild:loadAllTeamPets(var_26_0, function(arg_27_0)
			arg_26_0.allTeamPets = {}

			if arg_27_0 == xyd.error.OK then
				for iter_27_0, iter_27_1 in ipairs(arg_26_0.guild:getAllTeamPets()) do
					local var_27_0 = var_0_2.new()

					var_27_0:populate(iter_27_1)

					var_27_0.player_name = iter_27_1.player_name
					var_27_0.rent_need_mana = iter_27_1.rent_need_mana
					var_27_0.can_rent = iter_27_1.can_rent
					var_27_0.player_id = iter_27_1.player_id

					table.insert(arg_26_0.allTeamPets, var_27_0)
				end

				arg_26_0.isLoadAllTeamPets = true
			end

			arg_26_0:initPets(arg_26_0.allTeamPets, xyd.PetType.RENT_PET)

			if arg_26_1 then
				arg_26_1()
			end
		end)
	elseif arg_26_1 then
		arg_26_1()
	end
end

function var_0_0.updateListPosByLeftMenu(arg_28_0)
	if arg_28_0.leftMenuType_ == var_0_13.RENT_HERO and arg_28_0:isPet() then
		arg_28_0:nodeByName("top_rent_container"):setVisible(true)
		arg_28_0:nodeByName("rent_bg"):setVisible(true)
	else
		arg_28_0:nodeByName("top_rent_container"):setVisible(false)
		arg_28_0:nodeByName("rent_bg"):setVisible(false)
	end

	arg_28_0:nodeByName("button_filter"):setVisible(true)
	arg_28_0:nodeByName("button_collocation"):setVisible(false)

	if arg_28_0.showEnemy or arg_28_0.type == xyd.SelectTeamType.ADVANCED then
		if arg_28_0.leftMenuType_ == var_0_13.RENT_HERO then
			if arg_28_0.rentMenuType == var_0_14.RENT_PET then
				for iter_28_0, iter_28_1 in ipairs(arg_28_0.rightMenuButtons_) do
					iter_28_1:setVisible(false)
				end

				for iter_28_2, iter_28_3 in ipairs(arg_28_0.rightMenuText_) do
					iter_28_3:setVisible(false)
				end

				arg_28_0:nodeByName("line"):setVisible(false)
				arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 290))
				arg_28_0:nodeByName("list_layer"):height(290)
			elseif arg_28_0.rentMenuType == var_0_14.RENT_HERO then
				for iter_28_4, iter_28_5 in ipairs(arg_28_0.rightMenuButtons_) do
					iter_28_5:setVisible(true)
				end

				for iter_28_6, iter_28_7 in ipairs(arg_28_0.rightMenuText_) do
					iter_28_7:setVisible(true)
				end

				arg_28_0:nodeByName("button_filter"):setVisible(false)
				arg_28_0:nodeByName("line"):setVisible(true)

				for iter_28_8, iter_28_9 in ipairs(arg_28_0.rightMenuButtons_) do
					iter_28_9:y(457)
				end

				for iter_28_10, iter_28_11 in ipairs(arg_28_0.rightMenuText_) do
					iter_28_11:y(457)
				end

				arg_28_0:nodeByName("line"):y(424)
				arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 220))
				arg_28_0:nodeByName("list_layer"):height(220)
			end
		elseif arg_28_0.leftMenuType_ == var_0_13.SELF_HERO then
			for iter_28_12, iter_28_13 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_13:setVisible(true)
			end

			for iter_28_14, iter_28_15 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_15:setVisible(true)
			end

			arg_28_0:nodeByName("line"):setVisible(true)

			for iter_28_16, iter_28_17 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_17:y(457)
			end

			for iter_28_18, iter_28_19 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_19:y(457)
			end

			arg_28_0:nodeByName("line"):y(424)
			arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 220))
			arg_28_0:nodeByName("list_layer"):height(220)

			if not arg_28_0.isHeroPreset then
				arg_28_0:nodeByName("button_collocation"):y(457)
				arg_28_0:nodeByName("button_collocation"):setVisible(true)
			end
		elseif arg_28_0.leftMenuType_ == var_0_13.SELF_PET then
			for iter_28_20, iter_28_21 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_21:setVisible(false)
			end

			for iter_28_22, iter_28_23 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_23:setVisible(false)
			end

			arg_28_0:nodeByName("line"):setVisible(false)
			arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 290))
			arg_28_0:nodeByName("list_layer"):height(290)
		end

		if arg_28_0.isHeroPreset then
			for iter_28_24, iter_28_25 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_25:y(457)
			end

			for iter_28_26, iter_28_27 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_27:y(457)
			end

			arg_28_0:nodeByName("line"):y(424)
			arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 220))
			arg_28_0:nodeByName("list_layer"):height(220)
		end
	else
		if arg_28_0.leftMenuType_ == var_0_13.RENT_HERO and arg_28_0:isPet() then
			if arg_28_0.rentMenuType == var_0_14.RENT_PET then
				for iter_28_28, iter_28_29 in ipairs(arg_28_0.rightMenuButtons_) do
					iter_28_29:setVisible(false)
				end

				for iter_28_30, iter_28_31 in ipairs(arg_28_0.rightMenuText_) do
					iter_28_31:setVisible(false)
				end

				arg_28_0:nodeByName("line"):setVisible(false)
				arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 385))
				arg_28_0:nodeByName("list_layer"):height(385)
			elseif arg_28_0.rentMenuType == var_0_14.RENT_HERO then
				for iter_28_32, iter_28_33 in ipairs(arg_28_0.rightMenuButtons_) do
					iter_28_33:setVisible(true)
				end

				for iter_28_34, iter_28_35 in ipairs(arg_28_0.rightMenuText_) do
					iter_28_35:setVisible(true)
				end

				arg_28_0:nodeByName("button_filter"):setVisible(false)
				arg_28_0:nodeByName("line"):setVisible(true)

				for iter_28_36, iter_28_37 in ipairs(arg_28_0.rightMenuButtons_) do
					iter_28_37:y(557)
				end

				for iter_28_38, iter_28_39 in ipairs(arg_28_0.rightMenuText_) do
					iter_28_39:y(557)
				end

				arg_28_0:nodeByName("line"):y(524)
				arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 322))
				arg_28_0:nodeByName("list_layer"):height(322)
			end
		elseif arg_28_0.leftMenuType_ == var_0_13.SELF_HERO then
			for iter_28_40, iter_28_41 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_41:setVisible(true)
			end

			for iter_28_42, iter_28_43 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_43:setVisible(true)
			end

			arg_28_0:nodeByName("line"):setVisible(true)

			for iter_28_44, iter_28_45 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_45:y(607)
			end

			for iter_28_46, iter_28_47 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_47:y(607)
			end

			arg_28_0:nodeByName("line"):y(574)
			arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 370))
			arg_28_0:nodeByName("list_layer"):height(370)

			if not arg_28_0.isHeroPreset then
				arg_28_0:nodeByName("button_collocation"):setVisible(true)
			end
		elseif arg_28_0.leftMenuType_ == var_0_13.SELF_PET then
			for iter_28_48, iter_28_49 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_49:setVisible(false)
			end

			for iter_28_50, iter_28_51 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_51:setVisible(false)
			end

			arg_28_0:nodeByName("line"):setVisible(false)
			arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 430))
			arg_28_0:nodeByName("list_layer"):height(430)
		end

		if arg_28_0.isHeroPreset then
			for iter_28_52, iter_28_53 in ipairs(arg_28_0.rightMenuButtons_) do
				iter_28_53:y(607)
			end

			for iter_28_54, iter_28_55 in ipairs(arg_28_0.rightMenuText_) do
				iter_28_55:y(607)
			end

			arg_28_0:nodeByName("line"):y(574)
			arg_28_0.heroList_:setViewRect(cc.rect(0, 0, 900, 370))
			arg_28_0:nodeByName("list_layer"):height(370)
		end
	end

	arg_28_0:nodeByName("lev_limit_txt"):setPositionY(arg_28_0.heroList_:getViewRect().height)
	arg_28_0:initTextOfList()
end

function var_0_0.initPetCell(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_0.totalPet_[arg_29_2]

	if arg_29_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		local var_29_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/rent_pet_item.csb")

		arg_29_1:addChild(var_29_1)

		arg_29_1.type = xyd.PetType.RENT_PET

		var_29_1:setName("rent_cell")

		local var_29_2 = var_29_1:getChildByName("container")
		local var_29_3 = SplitLine.new({
			size = 139
		})

		var_29_3:addTo(var_29_2)
		var_29_3:setAnchorPoint(0, 0.5)
		var_29_3:setPosition(var_29_2:getChildByName("pos_splitline"):getPosition())
		arg_29_1:align(display.CENTER):size(var_29_2:getContentSize().width, var_29_2:getContentSize().height)

		local var_29_4 = var_29_2:getChildByName("avatar")

		var_29_2:getChildByName("player_name"):setString(var_29_0.player_name)
		var_29_2:getChildByName("rent_cost"):setString(var_29_0.rent_need_mana)
		var_29_4:getChildByName("yongbing_tubiao"):setPosition(cc.p(90, 100))
		xyd.setPetAvatarNewUI(var_29_4, var_29_0, 100)
		var_29_4:setPositionY(var_29_4:getPositionY() + 15)

		if not var_29_0.can_rent then
			var_29_2:getChildByName("can_not_rent"):setString(var_0_10:translation("CAN_NOT_BORROW"))
			var_29_4:getChildByName("layout"):getChildByName("chosen"):setVisible(false)
			var_29_4:getChildByName("layout"):getChildByName("avatar_mask"):setVisible(true)
		else
			var_29_2:getChildByName("can_not_rent"):setVisible(false)
		end
	else
		arg_29_1:align(display.CENTER):size(146, 146)
		xyd.setPetAvatarNewUI(arg_29_1, var_29_0, 100)

		arg_29_1.type = xyd.PetType.SELF_PET

		arg_29_0:initPetCellStatus(arg_29_1, var_29_0)
	end

	arg_29_1.data = var_29_0

	local var_29_5 = display.newNode()

	var_29_5:setContentSize(arg_29_1:getContentSize())
	var_29_5:addTo(arg_29_1)
	var_29_5:setTouchEnabled(true)
	var_29_5:setTouchSwallowEnabled(false)
	var_29_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		arg_29_0:buttonHandler(nil, arg_29_1, arg_30_0)

		if arg_30_0.name == "began" then
			arg_29_0.startClick_ = true
			arg_29_0.prevX_ = arg_30_0.x
			arg_29_0.prevY_ = arg_30_0.y
		elseif arg_30_0.name == "moved" then
			if math.abs(arg_30_0.y - arg_29_0.prevY_) > 5 or math.abs(arg_30_0.x - arg_29_0.prevX_) > 5 then
				arg_29_0.startClick_ = false
			end
		elseif arg_30_0.name == "ended" and arg_29_0.startClick_ and not arg_29_0.battleBegan then
			arg_29_0:beforeClickPetAvatar(arg_29_1, var_29_0)
		end

		return true
	end)
	arg_29_0:updatePetCellMask(arg_29_1, var_29_0)
end

function var_0_0.updatePetCellMask(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0

	if arg_31_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		var_31_0 = arg_31_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_31_0 = arg_31_1:getChildByName("layout")
	end

	local var_31_1 = var_31_0:getChildByName("avatar_mask")
	local var_31_2 = var_31_0:getChildByName("chosen")

	for iter_31_0, iter_31_1 in ipairs(arg_31_0.petTeam_) do
		if iter_31_1.data and iter_31_1.data:getTableID() == arg_31_2:getTableID() and iter_31_1.data.player_name == arg_31_2.player_name then
			arg_31_0.petTeam_[iter_31_0].iniCell_ = arg_31_1
			arg_31_1.teamNo_ = iter_31_0

			var_31_1:setVisible(true)
			var_31_2:setVisible(true)

			break
		end
	end
end

function var_0_0.initPetCellStatus(arg_32_0, arg_32_1, arg_32_2)
	return
end

function var_0_0.initPresetCell(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_0.presetTeams[arg_33_2].team
	local var_33_1 = arg_33_0.presetTeams[arg_33_2].teamName
	local var_33_2 = arg_33_0.presetTeams[arg_33_2].pet
	local var_33_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team_new/preset_item_2.csb")
	local var_33_4 = var_33_3:getChildByName("container")
	local var_33_5 = var_33_4:getContentSize()

	arg_33_1:setContentSize(var_33_5)
	var_33_3:addTo(arg_33_1)
	var_33_4:getChildByName("text_name"):setString(var_33_1)

	local var_33_6 = var_33_4:getChildByName("hero_list")
	local var_33_7 = 0
	local var_33_8 = 0

	for iter_33_0 = 1, #var_33_0 do
		local var_33_9 = var_33_0[iter_33_0]
		local var_33_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

		xyd.setAvatarBorderNewUI(var_33_9, var_33_10:getChildByName("avatar"))
		var_33_10:addTo(var_33_6)
		var_33_10:setPositionX(var_33_7)

		var_33_7 = var_33_7 + var_0_8 + 12

		local var_33_11 = var_33_10:getChildByName("chosen")

		var_33_11:setLocalZOrder(100)
		var_33_11:setVisible(false)

		local var_33_12 = var_33_10:getChildByName("avatar_mask")

		var_33_12:setLocalZOrder(2)
		var_33_12:setVisible(false)

		for iter_33_1 = 1, 3 do
			var_33_10:getChildByName("team" .. iter_33_1):setVisible(false)
		end

		local var_33_13 = var_33_10:getChildByName("lv_txt")

		var_33_13:setString(var_33_0[iter_33_0]:getLevel())
		var_33_10:getChildByName("name_text"):setString(var_33_0[iter_33_0]:getName())
		var_33_13:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_33_14 = var_33_10:getChildByName("hp_bar")
		local var_33_15 = var_33_10:getChildByName("mp_bar")

		var_33_10:getChildByName("yongbing_tubiao"):setVisible(false)
		var_33_14:hide()
		var_33_15:hide()
		var_33_10:getChildByName("hp_di"):hide()
		var_33_10:getChildByName("mp_di"):hide()

		local var_33_16 = var_33_10:getChildByName("dead_text")

		var_33_16:setVisible(false)

		local var_33_17 = false

		if arg_33_0:checkHeroIsDead(var_33_9) then
			var_33_12:setVisible(true)
			var_33_16:setLocalZOrder(3)
			var_33_16:setVisible(true)
			var_33_16:setString(var_0_10:translation("ALREADY_DEAD"))
			var_33_16:enableOutline(cc.c4b(0, 0, 0), 2)

			var_33_17 = true
		end

		var_33_9.isDead = var_33_17

		if arg_33_0:isBanned(var_33_9) then
			local var_33_18 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_33_18:setAnchorPoint(cc.p(0.5, 1))
			var_33_18:setPosition(var_0_8 / 2, var_0_8)
			var_33_10:getChildByName("avatar"):addChild(var_33_18)
			var_33_12:setVisible(true)
		end

		arg_33_0:updateHeroCell(var_33_10, var_33_9, false, true)

		var_33_8 = var_33_8 + var_33_0[iter_33_0]:getZhandouli()
	end

	if var_33_2 then
		xyd.setPetAvatarNewUI(var_33_4:getChildByName("pet"), var_33_2, 100)

		var_33_8 = var_33_8 + var_33_2:getZhandouli()
	end

	var_33_4:getChildByName("zhandouli"):setString(var_33_8)
	var_33_4:getChildByName("text_zhandouli"):setString(var_0_10:translation("TOTAL_FORCE") .. var_0_10:translation("COLON"))
	var_33_4:getChildByName("btn_use"):addTouchEventListener(function(arg_34_0, arg_34_1)
		xyd.buttonScaleAnim(var_33_4:getChildByName("btn_use"), arg_34_1)

		if arg_34_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_33_0:checkPresetTeamCanUse(arg_33_2) then
				local var_34_0 = arg_33_0.selfPlayer:getSaveTeamStr()
				local var_34_1 = arg_33_0.selfPlayer:getSaveTeamIDs(var_34_0)

				arg_33_0.preSelect_ = var_34_1[arg_33_2]
				arg_33_0.preHeros_ = var_33_0
				arg_33_0.prePet_ = {
					var_33_2
				}

				arg_33_0:showPresetTeam(arg_33_2)
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_35_0)
	local var_35_0 = arg_35_0.team_
	local var_35_1 = arg_35_0.petTeam_

	arg_35_0.team_ = {}
	arg_35_0.petTeam_ = {}
	arg_35_0.select_ = {}
	arg_35_0.petSelect_ = {}

	arg_35_0:updateScore()
	arg_35_0:initPreHeros(true)
	arg_35_0:initPrePets(true)

	local var_35_2 = arg_35_0.team_
	local var_35_3 = arg_35_0.petTeam_
	local var_35_4 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_36_0 = 1, #var_35_0 do
				local var_36_0 = var_35_0[iter_36_0]
				local var_36_1, var_36_2 = arg_35_0:nodeByName("avatar" .. iter_36_0):getPosition()

				arg_35_0:moveFadeOutAction(var_36_1, var_36_2 - 13, var_36_0)

				if var_36_0.type == xyd.LeftMenuType.RENT_HERO then
					arg_35_0.isSelectMerHero = false
					arg_35_0.selectMerHero = nil
				end
			end

			for iter_36_1 = 1, #var_35_1 do
				local var_36_3 = var_35_1[iter_36_1]
				local var_36_4, var_36_5 = arg_35_0:nodeByName("avatar_pet" .. iter_36_1):getPosition()

				arg_35_0:moveFadeOutAction(var_36_4, var_36_5, var_36_3)
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_35_5 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_37_0 = 1, #var_35_2 do
				local var_37_0 = var_35_2[iter_37_0]

				var_37_0:show()

				local var_37_1, var_37_2 = arg_35_0:nodeByName("avatar" .. iter_37_0):getPosition()

				arg_35_0:moveFadeInAction(var_37_1, var_37_2 - 13, var_37_0)
			end

			for iter_37_1 = 1, #var_35_3 do
				local var_37_3 = var_35_3[iter_37_1]

				var_37_3:show()

				local var_37_4, var_37_5 = arg_35_0:nodeByName("avatar_pet" .. iter_37_1):getPosition()

				arg_35_0:moveFadeInAction(var_37_4, var_37_5, var_37_3)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_35_0:runAction(transition.sequence({
		var_35_4,
		var_35_5
	}))
end

function var_0_0.checkPresetTeamCanUse(arg_38_0, arg_38_1)
	local var_38_0 = arg_38_0.presetTeams[arg_38_1].team

	for iter_38_0, iter_38_1 in ipairs(var_38_0) do
		if not arg_38_0:canHeroJoinBattle(iter_38_1) or arg_38_0:isBanned(iter_38_1) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_10:translation("PRESET_MEMBER_NOT_USE")
			})

			return false
		end
	end

	return true
end

function var_0_0.checkHeroIsDead(arg_39_0, arg_39_1)
	local var_39_0 = false
	local var_39_1 = false

	if arg_39_1.type == xyd.LeftMenuType.RENT_HERO then
		var_39_1 = true
	end

	local var_39_2 = arg_39_0:getListStatus(var_39_1, arg_39_1)

	if var_39_2 and next(var_39_2) ~= nil then
		local var_39_3 = var_39_2

		if not var_39_3 or not var_39_3.health or var_39_3.health == 0 then
			-- block empty
		elseif var_39_3.health == 1 and var_39_3.hp >= 1 then
			-- block empty
		else
			var_39_0 = true
		end
	end

	return var_39_0
end

function var_0_0.beforeClickPetAvatar(arg_40_0, arg_40_1, arg_40_2)
	local var_40_0 = arg_40_2.rent_need_mana

	if var_40_0 and var_40_0 > arg_40_0.selfPlayer.mana and arg_40_2.can_rent then
		local var_40_1 = var_0_10:translation("MERCENARY_ERROR_TIP4")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_40_1
		})

		return
	end

	if arg_40_1.isAnimated_ or not arg_40_1.teamNo_ and #arg_40_0.petTeam_ > xyd.MAX_PET_NUMBER then
		return
	elseif arg_40_1.type == xyd.PetType.RENT_PET and arg_40_0.isSelectMerHero then
		local var_40_2 = var_0_10:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_40_2
		})

		return
	elseif not arg_40_1.teamNo_ and #arg_40_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_40_3 = arg_40_0.petTeam_[1]

		arg_40_0:clickPetBottomAvatarWithoutAnimation(var_40_3, function()
			arg_40_0:clickPetAvatar(arg_40_1, no_animation)
		end)

		return
	end

	arg_40_0:clickPetAvatar(arg_40_1)
end

function var_0_0.checkClickNewPetAvatar(arg_42_0, arg_42_1, arg_42_2)
	if arg_42_0.rentMenuType == xyd.RentMenuType.RENT_PET and arg_42_2.can_rent == false then
		arg_42_1.isAnimated_ = false

		return false
	end

	return true
end

function var_0_0.clickPetAvatar(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0

	if arg_43_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		var_43_0 = arg_43_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_43_0 = arg_43_1:getChildByName("layout")
	end

	local var_43_1 = var_43_0:getChildByName("avatar_mask")
	local var_43_2 = var_43_0:getChildByName("chosen")
	local var_43_3 = arg_43_1:convertToWorldSpace(cc.p(0, 0))
	local var_43_4 = var_43_3.x
	local var_43_5 = var_43_3.y

	arg_43_1.isAnimated_ = true

	if arg_43_1.teamNo_ then
		local var_43_6 = arg_43_0.petTeam_[arg_43_1.teamNo_]

		arg_43_0:moveFadeOutAction(var_43_4, var_43_5, var_43_6, function()
			arg_43_1.isAnimated_ = false
		end)
		var_43_1:setVisible(false)
		var_43_2:setVisible(false)

		for iter_43_0 = #arg_43_0.petTeam_, arg_43_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_43_0.petTeam_[iter_43_0])

			local var_43_7, var_43_8 = arg_43_0:nodeByName("avatar_pet" .. iter_43_0 - 1):getPosition()

			transition.moveTo(arg_43_0.petTeam_[iter_43_0], {
				time = 0.3,
				x = var_43_7,
				y = var_43_8 - 13
			})

			arg_43_0.petTeam_[iter_43_0].iniCell_.teamNo_ = iter_43_0 - 1
		end

		if arg_43_1.type == xyd.PetType.RENT_PET then
			arg_43_0.isSelectMerPet = false
			arg_43_0.selectMerPet = nil
		end

		table.remove(arg_43_0.petTeam_, arg_43_1.teamNo_)
		table.remove(arg_43_0.petSelect_, arg_43_1.teamNo_)

		arg_43_1.teamNo_ = nil
	elseif not arg_43_1.teamNo_ and #arg_43_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_43_9 = arg_43_1.data

		if not arg_43_2 and var_0_12:chosenSound(var_43_9:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_43_9:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_12:chosenSound(var_43_9:getTableID()), false)
		end

		if not arg_43_0:checkClickNewPetAvatar(arg_43_1, var_43_9) then
			return false
		end

		local var_43_10 = arg_43_0:initPetBottomCell(var_43_9)

		var_43_10.iniCell_ = arg_43_1

		var_43_10:pos(var_43_4, var_43_5)
		var_43_10:addTo(arg_43_0)
		var_43_10:setTouchEnabled(true)
		var_43_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_46_0)
			if arg_46_0.name == "ended" and not arg_43_0.battleBegan then
				arg_43_0:clickPetBottomAvatar(var_43_10)
			end

			return true
		end)

		if arg_43_1.type == xyd.PetType.RENT_PET then
			arg_43_0.isSelectMerPet = true
			arg_43_0.selectMerPet = var_43_9
		end

		arg_43_1.teamNo_ = arg_43_0:getPetTeamNo(var_43_10)

		for iter_43_1 = arg_43_1.teamNo_, #arg_43_0.petTeam_ do
			local var_43_11, var_43_12 = arg_43_0:nodeByName("avatar_pet" .. iter_43_1):getPosition()

			if arg_43_2 then
				arg_43_0.petTeam_[iter_43_1]:pos(var_43_11, var_43_12)

				arg_43_1.isAnimated_ = false
			elseif iter_43_1 ~= arg_43_1.teamNo_ then
				local var_43_13 = arg_43_0.petTeam_[iter_43_1]

				transition.stopTarget(var_43_13)
				transition.moveTo(var_43_13, {
					time = 0.3,
					x = var_43_11,
					y = var_43_12,
					onComplete = function()
						var_43_13.iniCell_.isAnimated_ = false
						var_43_13.isAnimated_ = false
					end
				})
			else
				local var_43_14 = arg_43_0.petTeam_[iter_43_1]

				transition.stopTarget(var_43_14)

				var_43_10.isAnimated_ = true

				transition.moveTo(var_43_14, {
					time = 0.3,
					x = var_43_11,
					y = var_43_12,
					onComplete = function()
						arg_43_1.isAnimated_ = false
						var_43_10.isAnimated_ = false
					end
				})
			end

			arg_43_0.petTeam_[iter_43_1].iniCell_.teamNo_ = iter_43_1
		end

		var_43_1:setVisible(true)
		var_43_2:setVisible(true)
	end

	arg_43_0:updateScore()
end

function var_0_0.initHeroCell(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0 = arg_49_0.totalHero_[arg_49_0.selectedHeroClass_[arg_49_0.leftMenuType_]][arg_49_0.collocationType_][arg_49_2]

	var_49_0.healthStatus = nil

	local var_49_1
	local var_49_2 = false

	if arg_49_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO then
		var_49_2 = true

		local var_49_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/rent_hero_item.csb")

		var_49_1 = var_49_3:getChildByName("container")

		var_49_1:getChildByName("player_name"):setString(var_49_0.player_name)

		arg_49_1.player_name = var_49_0.player_name
		arg_49_1.can_rent = var_49_0.can_rent
		arg_49_1.type = xyd.LeftMenuType.RENT_HERO

		var_49_1:getChildByName("rent_cost"):setString(var_49_0.rent_need_mana)
		var_49_1:getChildByName("yongbing_tubiao"):setVisible(true)
		var_49_1:getChildByName("is_can_rent"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_49_1:getChildByName("is_can_rent"):setString(var_0_10:translation("CAN_NOT_BORROW"))
		arg_49_1:setContentSize(var_49_3:getChildByName("container"):getContentSize())

		local var_49_4 = SplitLine.new({
			size = 139
		})

		var_49_4:addTo(var_49_1)
		var_49_4:setAnchorPoint(0, 0.5)
		var_49_4:setPosition(var_49_1:getChildByName("pos_splitline"):getPosition())
		xyd.setAvatarBorderNewUI(var_49_0, var_49_1:getChildByName("avatar"))

		local var_49_5 = var_49_1:getChildByName("chosen")

		var_49_5:setLocalZOrder(100)
		var_49_5:setVisible(false)

		local var_49_6 = var_49_1:getChildByName("avatar_mask")

		var_49_6:setLocalZOrder(2)
		var_49_6:setVisible(false)

		if var_49_0.can_rent then
			var_49_1:getChildByName("is_can_rent"):setVisible(false)
			var_49_6:setVisible(false)
		else
			var_49_1:getChildByName("is_can_rent"):setVisible(true)
			var_49_1:getChildByName("is_can_rent"):setColor(cc.c3b(255, 165, 159))
			var_49_1:getChildByName("is_can_rent"):enableOutline(cc.c4b(0, 0, 0, 105), 1)
			var_49_1:getChildByName("is_can_rent"):setLocalZOrder(100)
			var_49_6:setVisible(true)
		end

		arg_49_1:addChild(var_49_3)
		var_49_3:setName("yongbingCell")
	else
		var_49_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_list.csb")

		local var_49_7 = var_49_1:getChildByName("background"):getContentSize()

		var_49_1:setContentSize(var_49_7)
		arg_49_1:setContentSize(var_49_7)
		xyd.setAvatarBorderNewUI(var_49_0, var_49_1:getChildByName("avatar"))

		local var_49_8 = var_49_1:getChildByName("chosen")

		var_49_8:setLocalZOrder(100)
		var_49_8:setVisible(false)

		local var_49_9 = var_49_1:getChildByName("avatar_mask")

		var_49_9:setLocalZOrder(2)
		var_49_9:setVisible(false)

		arg_49_1.type = xyd.LeftMenuType.SELF_HERO

		var_49_1:setName("layout")
		arg_49_1:addChild(var_49_1)
	end

	arg_49_0:initHeroStatus(arg_49_1, var_49_1, var_49_0, var_49_2)
	arg_49_0:updateHeroCell(var_49_1, var_49_0, var_49_2)
	arg_49_0:updateHeroMask(arg_49_1, var_49_1, var_49_0, var_49_2)

	if arg_49_0:isBanned(var_49_0) then
		local var_49_10 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

		var_49_10:setAnchorPoint(cc.p(0.5, 1))
		var_49_10:setPosition(70, 120)
		var_49_1:addChild(var_49_10)
		var_49_1:getChildByName("avatar_mask"):setVisible(true)

		return
	end

	arg_49_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_50_0)
		arg_49_0:buttonHandler(nil, arg_49_1, arg_50_0)

		if arg_50_0.name == "began" then
			arg_49_0.startClick_ = true
			arg_49_0.prevX_ = arg_50_0.x
			arg_49_0.prevY_ = arg_50_0.y
		elseif arg_50_0.name == "moved" then
			if math.abs(arg_50_0.y - arg_49_0.prevY_) > 5 or math.abs(arg_50_0.x - arg_49_0.prevX_) > 5 then
				arg_49_0.startClick_ = false
			end
		elseif arg_50_0.name == "ended" and arg_49_0.startClick_ then
			arg_49_0:beforeClickAvatar(arg_49_1)
		end

		return true
	end)
end

function var_0_0.updateHeroCell(arg_51_0, arg_51_1, arg_51_2, arg_51_3, arg_51_4)
	if arg_51_0:checkHeroIsNotUse(arg_51_2) then
		arg_51_1:getChildByName("avatar_mask"):setVisible(true)

		local var_51_0 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

		var_51_0:setPosition(85, 120)
		arg_51_1:addChild(var_51_0, 11)
	end
end

function var_0_0.updateHeroMask(arg_52_0, arg_52_1, arg_52_2, arg_52_3, arg_52_4)
	local var_52_0 = arg_52_2:getChildByName("chosen")
	local var_52_1 = arg_52_2:getChildByName("avatar_mask")

	for iter_52_0, iter_52_1 in ipairs(arg_52_0.select_) do
		if iter_52_1:getTableID() == arg_52_3:getTableID() and iter_52_1.player_name == arg_52_3.player_name then
			arg_52_1.teamNo_ = iter_52_0

			var_52_0:setVisible(true)
			var_52_1:setVisible(true)

			arg_52_0.team_[iter_52_0].iniCell_ = arg_52_1
			arg_52_0.team_[iter_52_0].iniCellVisible_ = false

			break
		end
	end
end

function var_0_0.getListStatus(arg_53_0, arg_53_1, arg_53_2)
	local var_53_0

	if arg_53_0.heroStatus_ then
		if arg_53_1 then
			var_53_0 = arg_53_0.heroStatus_.rent_list
		else
			var_53_0 = arg_53_0.heroStatus_.self_list
		end
	end

	if var_53_0 and next(var_53_0) then
		return var_53_0[tostring(arg_53_2:getHeroID())]
	end

	return nil
end

function var_0_0.initHeroStatus(arg_54_0, arg_54_1, arg_54_2, arg_54_3, arg_54_4)
	local var_54_0 = arg_54_2:getChildByName("lv_txt")

	var_54_0:setString(arg_54_3:getLevel())
	;(arg_54_2:getChildByName("name_txt") or arg_54_2:getChildByName("name_text")):setString(arg_54_3:getName())
	var_54_0:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_54_1 = arg_54_2:getChildByName("hp_bar")
	local var_54_2 = arg_54_2:getChildByName("mp_bar")
	local var_54_3 = arg_54_2:getChildByName("avatar_mask")
	local var_54_4 = false
	local var_54_5 = arg_54_0:getListStatus(arg_54_4, arg_54_3)

	if (var_54_5 and var_54_5.health or (not var_54_5 or not var_54_5.health) and arg_54_0:showHpBarIgnoreHealth()) and (not var_54_1 or tolua.isnull(var_54_1)) then
		local var_54_6 = xyd.AssetLoader.get():loadSprite("windows/common_new/energy-di.png")
		local var_54_7 = xyd.AssetLoader.get():loadSprite("windows/common_new/energy-di.png")

		var_54_6:addTo(arg_54_2)
		var_54_7:addTo(arg_54_2)
		var_54_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_54_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_54_6:setPosition(53, 117)
		var_54_7:setPosition(53, 103)
		var_54_6:setLocalZOrder(1)
		var_54_7:setLocalZOrder(1)
		var_54_6:setName("hp_di")
		var_54_7:setName("mp_di")

		local var_54_8 = cc.ProgressTimer:create(cc.Sprite:create("windows/common_new/lv.png"))

		var_54_8:addTo(arg_54_2)
		var_54_8:setType(1)
		var_54_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_54_8:setPosition(var_54_6:getPosition())
		var_54_8:setLocalZOrder(1)
		var_54_8:setMidpoint(cc.p(0, 0))
		var_54_8:setBarChangeRate(cc.p(1, 0))
		var_54_8:setName("hp_bar")

		local var_54_9 = cc.ProgressTimer:create(cc.Sprite:create("windows/common_new/energy.png"))

		var_54_9:addTo(arg_54_2)
		var_54_9:setType(1)
		var_54_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_54_9:setPosition(var_54_6:getPosition())
		var_54_9:setLocalZOrder(1)
		var_54_9:setMidpoint(cc.p(0, 0))
		var_54_9:setBarChangeRate(cc.p(1, 0))
		var_54_9:setName("mp_bar")

		local var_54_10 = display.newTTFLabel({
			font = "fonts/main_font.ttf",
			size = 26,
			text = var_0_10:translation("ALREADY_DEAD"),
			color = cc.c4b(206, 109, 109, 255),
			align = cc.TEXT_ALIGNMENT_LEFT
		})

		var_54_10:setAnchorPoint(cc.p(0, 0))
		var_54_10:addTo(arg_54_2)
		var_54_10:setPosition(17, 82)
		var_54_10:setLocalZOrder(3)
		var_54_10:setVisible(false)
	end

	if var_54_5 and var_54_5.health then
		local var_54_11 = var_54_5

		arg_54_3.healthStatus = var_54_11

		if var_54_11 and var_54_11.health then
			local var_54_12 = 0
			local var_54_13 = 0

			if var_54_11.health == 0 then
				var_54_12 = 100
				var_54_13 = 0
			elseif var_54_11.health == 1 and var_54_11.hp >= 1 then
				var_54_12 = var_54_11.hp / arg_54_3:getTotalAttr(xyd.AttributeType.HP) * 100
				var_54_13 = var_54_11.mp / 10
			else
				var_54_12 = 0
				var_54_13 = 0

				var_54_3:setVisible(true)
				deadText:setVisible(true)

				var_54_4 = true
			end

			var_54_1:setPercent(var_54_12)
			var_54_1:setVisible(true)
			var_54_2:setPercent(var_54_13)
			var_54_2:setVisible(true)
		end
	elseif (not var_54_5 or not var_54_5.health) and arg_54_0:showHpBarIgnoreHealth() then
		arg_54_3.healthStatus = {}
		arg_54_3.healthStatus.health = 0
		arg_54_3.healthStatus.hp = 0
		arg_54_3.healthStatus.mp = 0

		local var_54_14 = 100
		local var_54_15 = 0

		var_54_1:setPercent(var_54_14)
		var_54_1:setVisible(true)
		var_54_2:setPercent(var_54_15)
		var_54_2:setVisible(true)
	end

	arg_54_3.isDead = var_54_4

	arg_54_2:setPosition(cc.p(0, 0))

	arg_54_1.data = arg_54_3

	arg_54_2:setPosition(cc.p(0, 0))
	arg_54_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_54_1:setTouchSwallowEnabled(false)
	arg_54_1:setTouchEnabled(true)
end

function var_0_0.showHpBarIgnoreHealth(arg_55_0)
	if arg_55_0.campaignType == xyd.CampaignType.MARCH then
		return true
	end

	return false
end

function var_0_0.updateHeroBottomCell(arg_56_0, arg_56_1, arg_56_2)
	if arg_56_2.isAssist and arg_56_0.campaignType == xyd.CampaignType.NORMAL then
		local var_56_0 = xyd.AssetLoader.get():loadSprite("windows/battle/text_assist.png")

		var_56_0:addTo(arg_56_1)
		var_56_0:setAnchorPoint(cc.p(1, 1))
		var_56_0:setPosition(cc.p(cellSize.width, cellSize.height))
		var_56_0:setLocalZOrder(99)

		arg_56_0.assistHeroNode = arg_56_1

		arg_56_1:setVisible(false)
	end
end

function var_0_0.initBottomCell(arg_57_0, arg_57_1)
	local var_57_0 = display.newNode()
	local var_57_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")
	local var_57_2 = var_57_1:getChildByName("background"):getContentSize()

	var_57_1:setContentSize(var_57_2)
	var_57_0:setContentSize(var_57_2)
	xyd.setAvatarBorderNewUI(arg_57_1, var_57_1:getChildByName("avatar"))

	local var_57_3 = var_57_1:getChildByName("chosen")

	var_57_3:setLocalZOrder(100)
	var_57_3:setVisible(false)

	local var_57_4 = var_57_1:getChildByName("avatar_mask")

	var_57_4:setLocalZOrder(2)
	var_57_4:setVisible(false)

	local var_57_5 = var_57_1:getChildByName("yongbing_tubiao")
	local var_57_6 = false

	if arg_57_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO or arg_57_1.type == xyd.LeftMenuType.RENT_HERO then
		var_57_5:setVisible(true)

		var_57_0.type = xyd.LeftMenuType.RENT_HERO
		var_57_6 = true
	else
		var_57_5:setVisible(false)

		var_57_0.type = xyd.LeftMenuType.SELF_HERO
	end

	for iter_57_0 = 1, 3 do
		var_57_1:getChildByName("team" .. iter_57_0):setVisible(false)
	end

	arg_57_0:initHeroStatusBottom(var_57_0, var_57_1, arg_57_1, var_57_6)
	arg_57_0:updateHeroBottomCell(var_57_0, arg_57_1)
	var_57_1:setName("layout")
	var_57_0:addChild(var_57_1)

	return var_57_0
end

function var_0_0.initHeroStatusBottom(arg_58_0, arg_58_1, arg_58_2, arg_58_3, arg_58_4)
	local var_58_0 = arg_58_2:getChildByName("lv_txt")

	var_58_0:setString(arg_58_3:getLevel())
	;(arg_58_2:getChildByName("name_txt") or arg_58_2:getChildByName("name_text")):setString(arg_58_3:getName())
	var_58_0:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_58_1 = arg_58_2:getChildByName("hp_bar")
	local var_58_2 = arg_58_2:getChildByName("mp_bar")
	local var_58_3 = arg_58_2:getChildByName("dead_txt") or arg_58_2:getChildByName("dead_text")

	var_58_3:setString(var_0_10:translation("ALREADY_DEAD"))

	if var_58_3 then
		var_58_3:setVisible(false)
	end

	local var_58_4 = arg_58_2:getChildByName("avatar_mask")
	local var_58_5 = false
	local var_58_6 = arg_58_0:getListStatus(arg_58_4, arg_58_3)

	if var_58_6 and var_58_6.health then
		local var_58_7 = var_58_6

		arg_58_3.healthStatus = var_58_7

		if var_58_7 and var_58_7.health then
			local var_58_8 = 0
			local var_58_9 = 0

			if var_58_7.health == 0 then
				var_58_8 = 100
				var_58_9 = 0
			elseif var_58_7.health == 1 and var_58_7.hp >= 1 then
				var_58_8 = var_58_7.hp / arg_58_3:getTotalAttr(xyd.AttributeType.HP) * 100
				var_58_9 = var_58_7.mp / 10
			else
				var_58_8 = 0
				var_58_9 = 0

				var_58_4:setVisible(true)
				var_58_3:setLocalZOrder(3)
				var_58_3:setVisible(true)
				var_58_3:enableOutline(cc.c4b(0, 0, 0), 2)
				var_58_3:getVirtualRenderer():setAdditionalKerning(2)

				var_58_5 = true
			end

			var_58_1:setPercent(var_58_8)
			var_58_1:setVisible(true)
			var_58_2:setPercent(var_58_9)
			var_58_2:setVisible(true)
		end
	elseif (not var_58_6 or not var_58_6.health) and arg_58_0:showHpBarIgnoreHealth() then
		arg_58_3.healthStatus = {}
		arg_58_3.healthStatus.health = 0
		arg_58_3.healthStatus.hp = 0
		arg_58_3.healthStatus.mp = 0

		local var_58_10 = 100
		local var_58_11 = 0

		var_58_1:setPercent(var_58_10)
		var_58_1:setVisible(true)
		var_58_2:setPercent(var_58_11)
		var_58_2:setVisible(true)
	else
		var_58_1:hide()
		var_58_2:hide()
		arg_58_2:getChildByName("hp_di"):hide()
		arg_58_2:getChildByName("mp_di"):hide()
	end

	arg_58_3.isDead = var_58_5

	arg_58_2:setPosition(cc.p(0, 0))

	arg_58_1.data = arg_58_3

	arg_58_2:setPosition(cc.p(0, 0))
	arg_58_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_58_1:setTouchSwallowEnabled(false)
	arg_58_1:setTouchEnabled(true)
end

function var_0_0.initPetBottomCell(arg_59_0, arg_59_1)
	local var_59_0 = display.newNode()

	var_59_0:size(146, 146)
	var_59_0:align(display.CENTER)

	var_59_0.data = arg_59_1
	var_59_0.type = xyd.PetType.SELF_PET

	xyd.setPetAvatarNewUI(var_59_0, arg_59_1, 100)

	if arg_59_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		local var_59_1 = xyd.AssetLoader.get():loadSprite("windows/cloud_city/yongbing_tubiao.png")

		var_59_1:addTo(var_59_0)
		var_59_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_59_1:setPosition(cc.p(110, 120))

		var_59_0.type = xyd.PetType.RENT_PET
	end

	return var_59_0
end

function var_0_0.delegate(arg_60_0, ...)
	if arg_60_0.isHeroPreset then
		return arg_60_0:presetDelegate(...)
	elseif arg_60_0.leftMenuType_ == xyd.LeftMenuType.SELF_PET or arg_60_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO and arg_60_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		return arg_60_0:petDelegate(...)
	end

	return arg_60_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_61_0, arg_61_1, arg_61_2, arg_61_3)
	if arg_61_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
		var_0_4 = 7
	else
		var_0_4 = 5
	end

	local var_61_0 = math.ceil(#arg_61_0.totalHero_[arg_61_0.selectedHeroClass_[arg_61_0.leftMenuType_]][arg_61_0.collocationType_] / var_0_4)

	if cc.ui.UIListView.COUNT_TAG == arg_61_2 then
		return var_61_0
	elseif cc.ui.UIListView.CELL_TAG == arg_61_2 then
		local var_61_1
		local var_61_2
		local var_61_3
		local var_61_4 = arg_61_0.heroList_:dequeueItem()

		if not var_61_4 then
			var_61_4 = arg_61_0.heroList_:newItem()
		else
			var_61_4:removeAllChildren()
		end

		local var_61_5 = display.newNode()

		var_61_5:setTouchSwallowEnabled(false)

		for iter_61_0 = 1, var_0_4 do
			local var_61_6 = (arg_61_3 - 1) * var_0_4 + iter_61_0

			if var_61_6 > #arg_61_0.totalHero_[arg_61_0.selectedHeroClass_[arg_61_0.leftMenuType_]][arg_61_0.collocationType_] then
				break
			end

			var_61_3 = display.newNode()

			arg_61_0:initHeroCell(var_61_3, var_61_6)

			local var_61_7 = var_61_3:getContentSize().width
			local var_61_8 = var_61_3:getContentSize().height
			local var_61_9 = (arg_61_0.heroList_.viewRect_.width - var_61_7 * var_0_4) / (var_0_4 + 1)

			var_61_3:pos(var_61_9 * iter_61_0 + (iter_61_0 - 1) * var_61_7 + var_61_7 / 2, var_0_3 + var_61_8 / 2 - 6)
			var_61_5:addChild(var_61_3)

			arg_61_0.heroCells_[var_61_6] = var_61_3
		end

		var_61_5:setContentSize(cc.size(arg_61_0.heroList_.viewRect_.width, var_61_3:getContentSize().height + var_0_3))
		var_61_4:setItemSize(arg_61_0.heroList_.viewRect_.width, var_61_3:getContentSize().height + var_0_3)
		var_61_4:addContent(var_61_5)

		return var_61_4
	end
end

function var_0_0.petDelegate(arg_62_0, arg_62_1, arg_62_2, arg_62_3)
	if arg_62_0.leftMenuType_ == xyd.LeftMenuType.SELF_PET then
		var_0_5 = 6
	else
		var_0_5 = 5
	end

	local var_62_0 = math.ceil(#arg_62_0.totalPet_ / var_0_5)

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

		for iter_62_0 = 1, var_0_5 do
			local var_62_6 = (arg_62_3 - 1) * var_0_5 + iter_62_0

			if var_62_6 > #arg_62_0.totalPet_ then
				break
			end

			var_62_3 = display.newNode()

			arg_62_0:initPetCell(var_62_3, var_62_6)

			local var_62_7 = var_62_3:getContentSize().width
			local var_62_8 = var_62_3:getContentSize().height
			local var_62_9 = (arg_62_0.heroList_.viewRect_.width - var_62_7 * var_0_5) / (var_0_5 + 1)

			var_62_3:align(display.CENTER, var_62_9 * iter_62_0 + (iter_62_0 - 1) * var_62_7 + var_62_7 / 2, var_62_8 / 2)
			var_62_5:addChild(var_62_3)
		end

		var_62_5:setContentSize(cc.size(arg_62_0.heroList_.viewRect_.width, var_62_3:getContentSize().height))
		var_62_4:setItemSize(arg_62_0.heroList_.viewRect_.width, var_62_3:getContentSize().height)
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

function var_0_0.refreshSelectedHeroClass(arg_64_0)
	for iter_64_0 = 1, #arg_64_0.rightMenuButtons_ do
		if iter_64_0 == arg_64_0.selectedHeroClass_[arg_64_0.leftMenuType_] then
			arg_64_0.rightMenuButtons_[iter_64_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_64_0.rightMenuButtons_[iter_64_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_64_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.normal)
	arg_64_0.heroList_:removeAllItems()

	if arg_64_0.selectedHeroClass_[arg_64_0.leftMenuType_] == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_64_0.selectedHeroClass_[arg_64_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_64_1, iter_64_2 in ipairs(arg_64_0.select_) do
			if iter_64_2:getDistanceType() ~= arg_64_0.selectedHeroClass_[arg_64_0.leftMenuType_] then
				arg_64_0.team_[iter_64_1].iniCellVisible_ = true
			end
		end
	end

	if not arg_64_0.isFirstInitPreHero then
		arg_64_0.isFirstInitPreHero = true

		arg_64_0:initPreHeros()
		arg_64_0:initPrePets()
	end

	arg_64_0.heroList_:reload()
	arg_64_0:checkHeroIcon()
end

function var_0_0.buttonHandler(arg_65_0, arg_65_1, arg_65_2, arg_65_3)
	if not arg_65_2 or not arg_65_2:getParent() then
		return
	end

	if arg_65_3.name == "ended" then
		transition.stopTarget(arg_65_2)
		arg_65_2:setScale(1)

		if arg_65_1 then
			arg_65_1(arg_65_2, eventType)
		end
	elseif arg_65_3.name == "began" then
		local var_65_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_65_2:runAction(var_65_0)

		return true
	elseif arg_65_3.name == "cancled" then
		transition.stopTarget(arg_65_2)
		arg_65_2:setScale(1)
	end
end

function var_0_0.initPrePets(arg_66_0, arg_66_1)
	if not arg_66_0:isPet() then
		return
	end

	for iter_66_0, iter_66_1 in ipairs(arg_66_0.prePet_) do
		local var_66_0, var_66_1 = arg_66_0:nodeByName("avatar_pet" .. iter_66_0):getPosition()
		local var_66_2 = arg_66_0:initPetBottomCell(iter_66_1)

		var_66_2:pos(var_66_0, var_66_1)
		var_66_2:addTo(arg_66_0)
		var_66_2:setTouchEnabled(true)
		var_66_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_67_0)
			if arg_67_0.name == "ended" and not arg_66_0.battleBegan then
				arg_66_0:clickPetBottomAvatar(var_66_2)
			end

			return true
		end)
		arg_66_0:getPetTeamNo(var_66_2)

		if arg_66_1 then
			var_66_2:hide()
		end
	end

	arg_66_0:updateScore()

	arg_66_0.prePet_ = {}
end

function var_0_0.checkPreHeroCanLoad(arg_68_0, arg_68_1)
	if arg_68_1.type == xyd.LeftMenuType.RENT_HERO then
		if not arg_68_1.can_rent or arg_68_1.isDead or arg_68_0.isSelectMerHero or not arg_68_0:checkHeroValid(arg_68_1) then
			return false
		end

		local var_68_0 = arg_68_1.rent_need_mana

		if var_68_0 and var_68_0 > arg_68_0.selfPlayer.mana and not arg_68_1.have_rent then
			return false
		end
	elseif arg_68_0.selectSpType ~= 0 and not arg_68_0:canHeroJoinBattle(arg_68_1) then
		return false
	end

	if arg_68_0:checkHeroIsDead(arg_68_1) then
		return false
	end

	return true
end

function var_0_0.initPreHeros(arg_69_0, arg_69_1)
	if arg_69_0.preSelect_ and arg_69_0.preHeros_ then
		for iter_69_0, iter_69_1 in pairs(arg_69_0.preHeros_) do
			if not arg_69_0:checkPreHeroCanLoad(iter_69_1) then
				arg_69_0.preSelect_ = {}
				arg_69_0.preHeros_ = {}

				return
			end

			local var_69_0 = arg_69_0:initBottomCell(iter_69_1)

			if arg_69_1 then
				var_69_0:hide()
			end

			var_69_0.iniCellVisible_ = true
			var_69_0.iniCell_ = display.newNode()

			var_69_0:addTo(arg_69_0)
			var_69_0:setTouchEnabled(true)
			var_69_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_70_0)
				if arg_70_0.name == "ended" then
					arg_69_0:checkClickBottomAvatar(var_69_0, iter_69_1)
				end

				return true
			end)

			if iter_69_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_69_0.isSelectMerHero = true
				arg_69_0.selectMerHero = var_69_0.data
			end

			for iter_69_2 = arg_69_0:getTeamNo(var_69_0), #arg_69_0.team_ do
				local var_69_1, var_69_2 = arg_69_0:nodeByName("avatar" .. iter_69_2):getPosition()

				arg_69_0.team_[iter_69_2]:pos(var_69_1, var_69_2 - 13)

				if arg_69_0.team_[iter_69_2].iniCell_ then
					arg_69_0.team_[iter_69_2].iniCell_.teamNo_ = iter_69_2
				end
			end
		end

		arg_69_0:updateScore()
	end

	arg_69_0.preSelect_ = {}
	arg_69_0.preHeros_ = {}
end

function var_0_0.beforeClickAvatar(arg_71_0, arg_71_1)
	arg_71_0:clickAvatar(arg_71_1)
end

function var_0_0.checkClickAvatar(arg_72_0, arg_72_1)
	if arg_72_1.isAnimated_ or not arg_72_1.teamNo_ and #arg_72_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return false
	end

	if arg_72_0.selectSpType == xyd.SelectSpType.SINGLE and #arg_72_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_10:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return false
	end

	if arg_72_0.selectSpType == xyd.SelectSpType.TRIPLE and #arg_72_0.team_ >= 3 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_10:translation("ARENA_MODE_MAX_HERO"), 3)
		})

		return false
	end

	if arg_72_0.battleBegan then
		return false
	end

	return true
end

function var_0_0.checkClickNewAvatar(arg_73_0, arg_73_1)
	if not arg_73_1.data.can_rent and arg_73_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO then
		arg_73_1.isAnimated_ = false

		return false
	end

	if arg_73_1.data.isDead then
		arg_73_1.isAnimated_ = false

		return false
	end

	if (arg_73_0.isSelectMerHero or arg_73_0.isSelectMerPet) and arg_73_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO then
		arg_73_1.isAnimated_ = false

		local var_73_0 = var_0_10:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_73_0
		})

		return false
	end

	if not arg_73_0:checkHeroValid(arg_73_1.data) then
		arg_73_1.isAnimated_ = false

		local var_73_1 = var_0_10:translation("MERCENARY_ERROR_TIP2")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_73_1
		})

		return false
	end

	local var_73_2 = arg_73_1.data.rent_need_mana

	if var_73_2 and var_73_2 > arg_73_0.selfPlayer.mana and not arg_73_1.data.have_rent then
		arg_73_1.isAnimated_ = false

		local var_73_3 = var_0_10:translation("MERCENARY_ERROR_TIP3")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_73_3
		})

		return false
	end

	return true
end

function var_0_0.clickAvatar(arg_74_0, arg_74_1, arg_74_2)
	if not arg_74_0:checkClickAvatar(arg_74_1) then
		return
	end

	local var_74_0

	if arg_74_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
		var_74_0 = arg_74_1:getChildByName("layout")
	else
		var_74_0 = arg_74_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_74_1 = var_74_0:getChildByName("avatar_mask")
	local var_74_2 = var_74_0:getChildByName("chosen")
	local var_74_3 = arg_74_1:convertToWorldSpace(cc.p(0, 0))
	local var_74_4 = var_74_3.x + arg_74_1:getContentSize().width / 2
	local var_74_5 = var_74_3.y + arg_74_1:getContentSize().height / 2

	arg_74_1.isAnimated_ = true

	if arg_74_1.teamNo_ then
		local var_74_6 = arg_74_0.team_[arg_74_1.teamNo_]

		arg_74_0:moveFadeOutAction(var_74_4, var_74_5, var_74_6, function()
			arg_74_1.isAnimated_ = false
		end)
		var_74_1:setVisible(false)
		var_74_2:setVisible(false)

		for iter_74_0 = #arg_74_0.team_, arg_74_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_74_0.team_[iter_74_0])

			local var_74_7, var_74_8 = arg_74_0:nodeByName("avatar" .. iter_74_0 - 1):getPosition()

			transition.moveTo(arg_74_0.team_[iter_74_0], {
				time = 0.3,
				x = var_74_7,
				y = var_74_8 - 13
			})

			arg_74_0.team_[iter_74_0].iniCell_.teamNo_ = iter_74_0 - 1
		end

		if arg_74_1.type == xyd.LeftMenuType.RENT_HERO then
			arg_74_0.isSelectMerHero = false
			arg_74_0.selectMerHero = nil
		end

		table.remove(arg_74_0.team_, arg_74_1.teamNo_)
		table.remove(arg_74_0.select_, arg_74_1.teamNo_)

		arg_74_1.teamNo_ = nil
	elseif not arg_74_1.teamNo_ and #arg_74_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if arg_74_0.selectSpType == xyd.SelectSpType.CAMP and arg_74_0.team_[1] and arg_74_1.data.getFromType and arg_74_1.data:getFromType() ~= arg_74_0.team_[1].data:getFromType() then
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("ARENA_SAME_CAMP_WARNING")
			})

			return
		end

		if not arg_74_2 then
			local var_74_9 = arg_74_1.data

			if var_0_12:chosenSound(var_74_9:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_74_9:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_12:chosenSound(var_74_9:getTableID()), false)
			end
		end

		if not arg_74_0:checkClickNewAvatar(arg_74_1) then
			return
		end

		local var_74_10 = arg_74_0:initBottomCell(arg_74_1.data)

		var_74_10.iniCell_ = arg_74_1

		var_74_10:pos(var_74_4, var_74_5)
		var_74_10:addTo(arg_74_0)
		var_74_10:setTouchEnabled(true)

		local var_74_11 = arg_74_1.data

		var_74_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_77_0)
			if arg_77_0.name == "ended" then
				if var_74_11.isAssist and arg_74_0.selectSpType == xyd.SelectSpType.ASSIST then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_10:translation("CAMPAIGN_ASSIST_HERO")
					})
				elseif not arg_74_0.battleBegan then
					arg_74_0:clickBottomAvatar(var_74_10)
				end
			end

			return true
		end)

		if arg_74_1.type == xyd.LeftMenuType.RENT_HERO then
			arg_74_0.isSelectMerHero = true
			arg_74_0.selectMerHero = var_74_10.data
		end

		arg_74_1.teamNo_ = arg_74_0:getTeamNo(var_74_10)

		for iter_74_1 = arg_74_1.teamNo_, #arg_74_0.team_ do
			local var_74_12, var_74_13 = arg_74_0:nodeByName("avatar" .. iter_74_1):getPosition()

			if arg_74_2 then
				arg_74_0.team_[iter_74_1]:pos(var_74_12, var_74_13 - 13)

				arg_74_1.isAnimated_ = false
			elseif iter_74_1 ~= arg_74_1.teamNo_ then
				local var_74_14 = arg_74_0.team_[iter_74_1]

				transition.stopTarget(var_74_14)
				transition.moveTo(var_74_14, {
					time = 0.3,
					x = var_74_12,
					y = var_74_13 - 13,
					onComplete = function()
						var_74_14.iniCell_.isAnimated_ = false
						var_74_14.isAnimated_ = false
					end
				})
			else
				local var_74_15 = arg_74_0.team_[iter_74_1]

				transition.stopTarget(var_74_15)

				var_74_10.isAnimated_ = true

				transition.moveTo(var_74_15, {
					time = 0.3,
					x = var_74_12,
					y = var_74_13 - 13,
					onComplete = function()
						arg_74_1.isAnimated_ = false
						var_74_10.isAnimated_ = false
					end
				})
			end

			arg_74_0.team_[iter_74_1].iniCell_.teamNo_ = iter_74_1
		end

		var_74_1:setVisible(true)
		var_74_2:setVisible(true)
	end

	if not arg_74_2 then
		arg_74_0:playGuide()
	end

	arg_74_0:updateScore()
end

function var_0_0.checkClickBottomAvatar(arg_80_0, arg_80_1, arg_80_2)
	if arg_80_0.battleBegan then
		return false
	end

	arg_80_0:clickBottomAvatar(arg_80_1)
end

function var_0_0.checkHeroValid(arg_81_0, arg_81_1)
	for iter_81_0, iter_81_1 in pairs(arg_81_0.select_) do
		if arg_81_1:getTableID() == iter_81_1:getTableID() or xyd.tables.hero:beforeAwaken(arg_81_1:getTableID()) == iter_81_1:getTableID() or xyd.tables.hero:afterAwaken(arg_81_1:getTableID()) == iter_81_1:getTableID() or iter_81_1.isAssist and arg_81_1:getTableID() == arg_81_0.assistHeroID then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_82_0)
	local var_82_0 = 0

	for iter_82_0, iter_82_1 in ipairs(arg_82_0.team_) do
		var_82_0 = var_82_0 + iter_82_1.data:getZhandouli()
	end

	for iter_82_2, iter_82_3 in ipairs(arg_82_0.petTeam_) do
		var_82_0 = var_82_0 + iter_82_3.data:getZhandouli()
	end

	arg_82_0:nodeByName("zhandouli"):setString(var_82_0)
end

function var_0_0.clickBottomAvatar(arg_83_0, arg_83_1)
	if arg_83_1.isAnimated_ then
		return
	end

	local var_83_0, var_83_1 = arg_83_0:nodeByName("list_layer"):getPosition()
	local var_83_2 = arg_83_1.iniCell_
	local var_83_3

	for iter_83_0, iter_83_1 in ipairs(arg_83_0.select_) do
		if iter_83_1:getTableID() == arg_83_1.data:getTableID() and iter_83_1.player_name == arg_83_1.data.player_name then
			var_83_3 = iter_83_0

			break
		end
	end

	if not var_83_3 then
		return
	end

	if not arg_83_1.iniCellVisible_ and arg_83_1.type == arg_83_0.leftMenuType_ and not tolua.isnull(var_83_2) then
		local var_83_4 = var_83_2:convertToWorldSpace(cc.p(0, 0))

		var_83_0, var_83_1 = var_83_4.x + var_83_2:getContentSize().width / 2, var_83_4.y + var_83_2:getContentSize().height / 2

		local var_83_5

		if arg_83_1.type == xyd.LeftMenuType.RENT_HERO then
			var_83_5 = var_83_2:getChildByName("yongbingCell"):getChildByName("container")
		else
			var_83_5 = var_83_2:getChildByName("layout")
		end

		local var_83_6 = var_83_5:getChildByName("avatar_mask")
		local var_83_7 = var_83_5:getChildByName("chosen")

		var_83_6:setVisible(false)
		var_83_7:setVisible(false)
	end

	arg_83_0:moveFadeOutAction(var_83_0, var_83_1, arg_83_1)

	for iter_83_2 = #arg_83_0.team_, var_83_3 + 1, -1 do
		local var_83_8 = arg_83_0.team_[iter_83_2]
		local var_83_9, var_83_10 = arg_83_0:nodeByName("avatar" .. iter_83_2 - 1):getPosition()

		transition.stopTarget(var_83_8)
		transition.moveTo(arg_83_0.team_[iter_83_2], {
			time = 0.3,
			x = var_83_9,
			y = var_83_10 - 13
		})

		arg_83_0.team_[iter_83_2].iniCell_.teamNo_ = iter_83_2 - 1
	end

	if arg_83_1.type == xyd.LeftMenuType.RENT_HERO then
		arg_83_0.isSelectMerHero = false
		arg_83_0.selectMerHero = nil
	end

	table.remove(arg_83_0.team_, var_83_3)
	table.remove(arg_83_0.select_, var_83_3)

	var_83_2.teamNo_ = nil

	arg_83_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_84_0, arg_84_1, arg_84_2)
	if arg_84_1.isAnimated_ then
		return
	end

	local var_84_0, var_84_1 = arg_84_0:nodeByName("list_layer"):getPosition()
	local var_84_2 = arg_84_1.iniCell_
	local var_84_3

	for iter_84_0, iter_84_1 in ipairs(arg_84_0.petSelect_) do
		if iter_84_1:getTableID() == arg_84_1.data:getTableID() and iter_84_1.player_name == arg_84_1.data.player_name then
			var_84_3 = iter_84_0

			break
		end
	end

	if not var_84_3 then
		return
	end

	if var_84_2 and not tolua.isnull(var_84_2) then
		local var_84_4 = var_84_2:convertToWorldSpace(cc.p(0, 0))

		var_84_0, var_84_1 = var_84_4.x, var_84_4.y

		local var_84_5

		if arg_84_0.rentMenuType == xyd.RentMenuType.RENT_PET then
			var_84_5 = var_84_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_84_5 = var_84_2:getChildByName("layout")
		end

		local var_84_6 = var_84_5:getChildByName("avatar_mask")
		local var_84_7 = var_84_5:getChildByName("chosen")

		var_84_6:setVisible(false)
		var_84_7:setVisible(false)
	end

	arg_84_0:moveFadeOutAction(var_84_0, var_84_1, arg_84_1, arg_84_2)

	if arg_84_1.type == xyd.PetType.RENT_PET then
		arg_84_0.isSelectMerPet = false
		arg_84_0.selectMerPet = nil
	end

	table.remove(arg_84_0.petTeam_, var_84_3)
	table.remove(arg_84_0.petSelect_, var_84_3)

	if var_84_2 then
		var_84_2.teamNo_ = nil
	end

	arg_84_0:updateScore()
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_85_0, arg_85_1, arg_85_2)
	if arg_85_1.isAnimated_ then
		return
	end

	local var_85_0, var_85_1 = arg_85_0:nodeByName("list_layer"):getPosition()
	local var_85_2 = arg_85_1.iniCell_
	local var_85_3

	for iter_85_0, iter_85_1 in ipairs(arg_85_0.petTeam_) do
		if iter_85_1 == arg_85_1 then
			var_85_3 = iter_85_0

			break
		end
	end

	if not var_85_3 then
		return
	end

	if var_85_2 and not tolua.isnull(var_85_2) then
		local var_85_4 = var_85_2:convertToWorldSpace(cc.p(0, 0))
		local var_85_5

		if arg_85_0.rentMenuType == xyd.RentMenuType.RENT_PET then
			var_85_5 = var_85_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_85_5 = var_85_2:getChildByName("layout")
		end

		local var_85_6 = var_85_5:getChildByName("avatar_mask")
		local var_85_7 = var_85_5:getChildByName("chosen")

		var_85_6:setVisible(false)
		var_85_7:setVisible(false)
	end

	for iter_85_2 = #arg_85_0.petTeam_, var_85_3 + 1, -1 do
		local var_85_8 = arg_85_0.petTeam_[iter_85_2]
		local var_85_9, var_85_10 = arg_85_0:nodeByName("avatar_pet" .. iter_85_2 - 1):getPosition()

		transition.stopTarget(var_85_8)
		transition.moveTo(arg_85_0.petTeam_[iter_85_2], {
			time = 0.3,
			x = var_85_9,
			y = var_85_10
		})

		arg_85_0.petTeam_[iter_85_2].iniCell_.teamNo_ = iter_85_2 - 1
	end

	if arg_85_1.type == xyd.PetType.RENT_PET then
		arg_85_0.isSelectMerPet = false
		arg_85_0.selectMerPet = nil
	end

	table.remove(arg_85_0.petTeam_, var_85_3)
	table.remove(arg_85_0.petSelect_, var_85_3)

	if var_85_2 then
		var_85_2.teamNo_ = nil
	end

	if arg_85_1 and not tolua.isnull(arg_85_1) then
		arg_85_1:removeSelf()
	end

	if arg_85_2 then
		arg_85_2()
	end
end

function var_0_0.getTeamNo(arg_86_0, arg_86_1)
	for iter_86_0, iter_86_1 in ipairs(arg_86_0.team_) do
		if arg_86_1.data:getDistance() < iter_86_1.data:getDistance() then
			table.insert(arg_86_0.team_, iter_86_0, arg_86_1)
			table.insert(arg_86_0.select_, iter_86_0, arg_86_1.data)

			return iter_86_0
		end
	end

	table.insert(arg_86_0.team_, arg_86_1)
	table.insert(arg_86_0.select_, arg_86_1.data)

	return #arg_86_0.team_
end

function var_0_0.getPetTeamNo(arg_87_0, arg_87_1)
	table.insert(arg_87_0.petTeam_, arg_87_1)
	table.insert(arg_87_0.petSelect_, arg_87_1.data)

	return #arg_87_0.petTeam_
end

function var_0_0.widgetSet(arg_88_0, arg_88_1)
	for iter_88_0, iter_88_1 in ipairs(arg_88_1:getChildren()) do
		if iter_88_1 ~= nil then
			iter_88_1:setCascadeOpacityEnabled(true)
			arg_88_0:widgetSet(iter_88_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_89_0, arg_89_1, arg_89_2, arg_89_3, arg_89_4)
	arg_89_0:widgetSet(arg_89_3)
	arg_89_3:setCascadeOpacityEnabled(true)

	local var_89_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_89_1, arg_89_2)))

	arg_89_3:runActionOnce(var_89_0, true, arg_89_4)
end

function var_0_0.moveFadeInAction(arg_90_0, arg_90_1, arg_90_2, arg_90_3, arg_90_4)
	arg_90_0:widgetSet(arg_90_3)
	arg_90_3:setCascadeOpacityEnabled(true)
	arg_90_3:setOpacity(0)

	local var_90_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_90_1, arg_90_2)))

	arg_90_3:runActionOnce(var_90_0, false, arg_90_4)
end

function var_0_0.getBattleBtn(arg_91_0)
	if not arg_91_0.battleBtn_ then
		arg_91_0.battleBtn_ = arg_91_0:nodeByName("button_battle")

		arg_91_0.battleBtn_:addTouchEventListener(function(arg_92_0, arg_92_1)
			if not arg_91_0:checkCanStartBattle() then
				return
			end

			if arg_92_1 == ccui.TouchEventType.ended and not arg_91_0.battleBegan then
				xyd.playButtonSound()

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				arg_91_0:beforeStartBattle()
			end
		end)
		arg_91_0.battleBtn_:setVisible(true)
		arg_91_0:nodeByName("button_ok"):setVisible(false)
	end

	return arg_91_0.battleBtn_
end

function var_0_0.checkCanStartBattle(arg_93_0)
	local var_93_0 = true
	local var_93_1 = ""

	if #arg_93_0.select_ < 1 then
		var_93_0 = false
		var_93_1 = var_0_10:translation("BATTLE_NO_HERO")
	elseif #arg_93_0.select_ == 1 and (arg_93_0.select_[1]:getHeroID() < 0 or arg_93_0.isSelectMerHero) then
		var_93_1 = var_0_10:translation("BATTLE_NO_HERO")
		var_93_0 = false
	end

	if not var_93_0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_93_1
		})
	end

	return var_93_0
end

function var_0_0.beforeStartBattle(arg_94_0)
	if arg_94_0.selectMerHero and not arg_94_0.selectMerHero.have_rent then
		local var_94_0 = {
			hero = arg_94_0.selectMerHero,
			type = xyd.ConfirmRent.HERO
		}

		xyd.WindowManager.get():openWindow("confirm_rent", var_94_0)
	elseif arg_94_0.isSelectMerPet and arg_94_0.selectMerPet.can_rent then
		local var_94_1 = {
			hero = arg_94_0.selectMerPet,
			type = xyd.ConfirmRent.PET
		}

		xyd.WindowManager.get():openWindow("confirm_rent", var_94_1)
	else
		arg_94_0.battleBegan = true

		arg_94_0:startBattle()
	end
end

function var_0_0.startBattle(arg_95_0)
	return
end

function var_0_0.recordFormation(arg_96_0)
	local var_96_0 = {}

	for iter_96_0, iter_96_1 in ipairs(arg_96_0.team_) do
		if iter_96_1.type ~= xyd.LeftMenuType.RENT_HERO then
			table.insert(var_96_0, iter_96_1.data:getHeroID())
		end
	end

	local var_96_1 = ""

	for iter_96_2, iter_96_3 in ipairs(var_96_0) do
		var_96_1 = var_96_1 .. string.format("%d|", iter_96_3)
	end

	if arg_96_0:isPet() and next(arg_96_0.petTeam_) then
		local var_96_2 = ""

		for iter_96_4, iter_96_5 in ipairs(arg_96_0.petTeam_) do
			if iter_96_5.type ~= xyd.PetType.RENT_PET then
				var_96_2 = var_96_2 .. string.format("%d|", iter_96_5.data:getPetID())
			end
		end

		var_96_1 = var_96_1 .. "," .. var_96_2
	end

	xyd.db.formation:setFormationData(arg_96_0.campaignType, var_96_1)
end

function var_0_0.getBattleID(arg_97_0)
	local var_97_0
	local var_97_1
	local var_97_2
	local var_97_3 = false

	if arg_97_0.campaignType == xyd.CampaignType.NORMAL and arg_97_0.campaignID ~= 0 then
		local var_97_4 = xyd.tables.campaign:firstFightID(arg_97_0.campaignID)
		local var_97_5 = arg_97_0.selfPlayer.worldMaps_[arg_97_0.campaignID].star or 0

		if var_97_4 ~= 0 and var_97_5 <= 0 then
			var_97_0 = var_97_4
			var_97_3 = true
		else
			var_97_0 = arg_97_0.battleID or xyd.tables.campaign:fightID(arg_97_0.campaignID)
		end
	else
		var_97_0 = arg_97_0.battleID or xyd.tables.campaign:fightID(arg_97_0.campaignID)
	end

	return var_97_0, var_97_3
end

function var_0_0.getFormationStr(arg_98_0, arg_98_1)
	local var_98_0 = ""

	for iter_98_0, iter_98_1 in ipairs(arg_98_1) do
		var_98_0 = var_98_0 .. string.format("%d", iter_98_1:getHeroID())

		if iter_98_0 < #arg_98_1 then
			var_98_0 = var_98_0 .. "|"
		end
	end

	return var_98_0
end

function var_0_0.setIDBeforeGuideWnd(arg_99_0)
	local var_99_0 = xyd.StoryData.get():getGuideID()

	if var_99_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL)
	elseif var_99_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_TWO)
	elseif var_99_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_TWO)
	elseif var_99_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_100_0)
	local var_100_0 = xyd.StoryData.get():getGuideID()

	if var_100_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO)
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE)
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR)
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT)
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_MISSION_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START)
		xyd.StoryData.get():persist()
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE then
		arg_100_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_2_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_FOUR)
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO then
		arg_100_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_THREE)
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		arg_100_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_4)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_END)
		xyd.StoryData.get():persist()
	elseif var_100_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		arg_100_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR)
	end
end

function var_0_0.checkGuideIntoBattle(arg_101_0)
	local var_101_0 = xyd.StoryData.get():getGuideID()

	if var_101_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR or var_101_0 == xyd.GuideStoryType.GUIDE_MISSION_END or var_101_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE or var_101_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO or var_101_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		return true
	end

	return false
end

function var_0_0.getGuideHeroCell(arg_102_0, arg_102_1)
	local var_102_0 = xyd.StoryData.get():getGuideID()
	local var_102_1 = arg_102_1 or 10001001

	if var_102_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		var_102_1 = 10001004
	end

	for iter_102_0 = 1, #arg_102_0.heroCells_ do
		if arg_102_0.heroCells_[iter_102_0] and arg_102_0.heroCells_[iter_102_0].data and arg_102_0.heroCells_[iter_102_0].data:getTableID() == var_102_1 then
			return arg_102_0.heroCells_[iter_102_0]
		end
	end

	return arg_102_0.heroCells_[1]
end

function var_0_0.playGuide(arg_103_0)
	return
end

function var_0_0.canPetJoinBattle(arg_104_0, arg_104_1)
	return true
end

function var_0_0.canHeroJoinBattle(arg_105_0, arg_105_1)
	if arg_105_0.selectSpType == xyd.SelectSpType.WEI then
		if arg_105_1:getFromType() ~= xyd.HeroFromType.WEI then
			return false
		end
	elseif arg_105_0.selectSpType == xyd.SelectSpType.SHU then
		if arg_105_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_105_0.selectSpType == xyd.SelectSpType.WU and arg_105_1:getFromType() ~= xyd.HeroFromType.WU then
		return false
	end

	return true
end

function var_0_0.initHeros(arg_106_0, arg_106_1, arg_106_2)
	arg_106_0.tmpTotalHero_[arg_106_2] = {}
	arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ALL] = {}
	arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.QIANPAI] = {}
	arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.HOUPAI] = {}
	arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.FILTER] = {}

	for iter_106_0, iter_106_1 in pairs(arg_106_0.tmpTotalHero_[arg_106_2]) do
		iter_106_1[var_0_16.NO] = {}
		iter_106_1[var_0_16.YES] = {}
	end

	if arg_106_2 == var_0_13.SELF_HERO then
		for iter_106_2, iter_106_3 in pairs(arg_106_1) do
			if arg_106_0:canHeroJoinBattle(iter_106_3) then
				if iter_106_3:getDistanceType() == xyd.DistanceType.QIANPAI then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.QIANPAI][var_0_16.NO], iter_106_3)

					if iter_106_3:isCollocation() then
						table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.QIANPAI][var_0_16.YES], iter_106_3)
					end
				elseif iter_106_3:getDistanceType() == xyd.DistanceType.ZHONGPAI then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ZHONGPAI][var_0_16.NO], iter_106_3)

					if iter_106_3:isCollocation() then
						table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ZHONGPAI][var_0_16.YES], iter_106_3)
					end
				elseif iter_106_3:getDistanceType() == xyd.DistanceType.HOUPAI then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.HOUPAI][var_0_16.NO], iter_106_3)

					if iter_106_3:isCollocation() then
						table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.HOUPAI][var_0_16.YES], iter_106_3)
					end
				end

				table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ALL][var_0_16.NO], iter_106_3)

				if iter_106_3:isCollocation() then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ALL][var_0_16.YES], iter_106_3)
				end
			end
		end
	elseif arg_106_2 == var_0_13.RENT_HERO then
		for iter_106_4, iter_106_5 in pairs(arg_106_1) do
			if arg_106_0:canHeroJoinBattle(iter_106_5) then
				if iter_106_5:getDistanceType() == xyd.DistanceType.QIANPAI then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.QIANPAI][var_0_16.NO], iter_106_5)
				elseif iter_106_5:getDistanceType() == xyd.DistanceType.ZHONGPAI then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ZHONGPAI][var_0_16.NO], iter_106_5)
				elseif iter_106_5:getDistanceType() == xyd.DistanceType.HOUPAI then
					table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.HOUPAI][var_0_16.NO], iter_106_5)
				end

				table.insert(arg_106_0.tmpTotalHero_[arg_106_2][xyd.DistanceType.ALL][var_0_16.NO], iter_106_5)
			end
		end

		for iter_106_6, iter_106_7 in pairs(arg_106_0.tmpTotalHero_[arg_106_2]) do
			iter_106_7[var_0_16.YES] = iter_106_7[var_0_16.NO]
		end
	end

	arg_106_0:sortTables(arg_106_0.tmpTotalHero_[arg_106_2])

	arg_106_0.selectedHeroClass_[arg_106_2] = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_107_0, arg_107_1, arg_107_2)
	local var_107_0 = {}

	for iter_107_0, iter_107_1 in ipairs(arg_107_1) do
		if iter_107_1.is_show_ == 1 and arg_107_0:canPetJoinBattle(iter_107_1) then
			table.insert(var_107_0, iter_107_1)
		end
	end

	table.sort(var_107_0, function(arg_108_0, arg_108_1)
		return xyd.petNormalSort(arg_108_0, arg_108_1) or false
	end)

	arg_107_0.tmpTotalPets[arg_107_2] = var_107_0
end

function var_0_0.updateFilterHeros(arg_109_0)
	arg_109_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.NO] = {}
	arg_109_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.YES] = {}

	local var_109_0 = {
		0,
		0,
		0
	}
	local var_109_1 = {
		0,
		0,
		0
	}
	local var_109_2 = {
		0,
		0,
		0,
		0
	}
	local var_109_3 = {
		0,
		0,
		0
	}

	if arg_109_0.selfPlayer.sortType and arg_109_0.selfPlayer.sortType > 0 then
		local var_109_4 = {}
		local var_109_5 = arg_109_0.selfPlayer.sortType
		local var_109_6 = 1

		while var_109_5 > 0 do
			var_109_4[var_109_6] = var_109_5 % 2
			var_109_6 = var_109_6 + 1
			var_109_5 = math.floor(var_109_5 / 2)
		end

		local var_109_7 = 1

		for iter_109_0 = 13, 1, -1 do
			if iter_109_0 <= 4 then
				if iter_109_0 == 4 then
					var_109_7 = 1
				end

				var_109_2[var_109_7] = var_109_4[iter_109_0]
			elseif iter_109_0 <= 7 then
				if iter_109_0 == 7 then
					var_109_7 = 1
				end

				var_109_1[var_109_7] = var_109_4[iter_109_0]
			elseif iter_109_0 <= 10 then
				if iter_109_0 == 10 then
					var_109_7 = 1
				end

				if var_109_4[iter_109_0] then
					var_109_0[var_109_7] = var_109_4[iter_109_0]
				end
			elseif iter_109_0 <= 13 then
				if iter_109_0 == 13 then
					var_109_7 = 1
				end

				if var_109_4[iter_109_0] then
					var_109_3[var_109_7] = var_109_4[iter_109_0]
				end
			end

			var_109_7 = var_109_7 + 1
		end
	else
		var_109_0 = {
			1,
			1,
			1
		}
		var_109_1 = {
			1,
			1,
			1
		}
		var_109_2 = {
			1,
			1,
			1,
			1
		}
		var_109_3 = {
			1,
			1,
			1
		}
	end

	for iter_109_1, iter_109_2 in pairs(arg_109_0.totalHero_[xyd.DistanceType.ALL][var_0_16.NO]) do
		if var_109_0[iter_109_2:getDistanceType() - 1] == 1 and var_109_1[iter_109_2:getHeroType()] == 1 and var_109_2[iter_109_2:getFromType()] == 1 and arg_109_0:canHeroJoinBattle(iter_109_2) and var_109_3[iter_109_2:getAwakenType()] == 1 then
			table.insert(arg_109_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.NO], iter_109_2)
		end
	end

	for iter_109_3, iter_109_4 in pairs(arg_109_0.totalHero_[xyd.DistanceType.ALL][var_0_16.YES]) do
		if var_109_0[iter_109_4:getDistanceType() - 1] == 1 and var_109_1[iter_109_4:getHeroType()] == 1 and var_109_2[iter_109_4:getFromType()] == 1 and arg_109_0:canHeroJoinBattle(iter_109_4) and var_109_3[iter_109_4:getAwakenType()] == 1 then
			table.insert(arg_109_0.totalHero_[xyd.DistanceType.FILTER][var_0_16.YES], iter_109_4)
		end
	end
end

function var_0_0.updateSearchHeros(arg_110_0)
	arg_110_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_110_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.YES] = {}
	arg_110_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.NO] = {}

	if arg_110_0.searchTxt ~= "" then
		for iter_110_0, iter_110_1 in pairs(arg_110_0.totalHero_[xyd.DistanceType.ALL][var_0_16.NO]) do
			if xyd.searchHeroByName(arg_110_0.searchTxt, iter_110_1) then
				table.insert(arg_110_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.NO], iter_110_1)
			end
		end

		for iter_110_2, iter_110_3 in pairs(arg_110_0.totalHero_[xyd.DistanceType.ALL][var_0_16.YES]) do
			if xyd.searchHeroByName(arg_110_0.searchTxt, iter_110_3) then
				table.insert(arg_110_0.totalHero_[xyd.DistanceType.SEARCH][var_0_16.YES], iter_110_3)
			end
		end
	end
end

function var_0_0.updatePresetTeams(arg_111_0, arg_111_1)
	if arg_111_0.type and arg_111_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_111_0.type == xyd.SelectTeamType.REGION_ARENA then
		local var_111_0 = arg_111_0.regionAwards

		for iter_111_0 = 1, #arg_111_1 do
			local var_111_1 = arg_111_1[iter_111_0].team

			arg_111_0:initRegionHeros(var_111_1, var_111_0, true)
			xyd.formatRegionArenaHeros(var_111_1)
		end
	end

	return arg_111_1
end

function var_0_0.initPresetTeams(arg_112_0)
	arg_112_0.presetTeams = {}

	if not arg_112_0:checkCanPresetTeam() then
		return
	end

	local var_112_0 = arg_112_0.selfPlayer:getSaveTeams()

	arg_112_0.presetTeams = arg_112_0:updatePresetTeams(var_112_0)
end

function var_0_0.selectHeros(arg_113_0)
	arg_113_0.totalHero_ = arg_113_0.tmpTotalHero_[arg_113_0.leftMenuType_]
end

function var_0_0.selectPets(arg_114_0)
	if arg_114_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		arg_114_0.totalPet_ = arg_114_0.tmpTotalPets[xyd.PetType.RENT_PET]
	else
		arg_114_0.totalPet_ = arg_114_0.tmpTotalPets[xyd.PetType.SELF_PET]
	end
end

function var_0_0.initListview(arg_115_0)
	local var_115_0 = arg_115_0:nodeByName("list_layer")
	local var_115_1 = var_115_0:getContentSize().width
	local var_115_2 = var_115_0:getContentSize().height

	arg_115_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_115_1, var_115_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_115_0)
	arg_115_0.heroCells_ = {}

	arg_115_0.heroList_:setDelegate(handler(arg_115_0, arg_115_0.delegate))
end

function var_0_0.initTextOfList(arg_116_0)
	arg_116_0.txt_height = arg_116_0:nodeByName("lev_limit_txt"):getY()

	if xyd.tables.battle:levLimit(arg_116_0.campaignID) > 0 then
		arg_116_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_116_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_10:translation("SELECT_HERO_LEV_LIMIT"), xyd.tables.battle:levLimit(arg_116_0.campaignID), xyd.tables.battle:name(arg_116_0.campaignID)))
	else
		arg_116_0:nodeByName("lev_limit_txt"):setVisible(false)
	end

	local var_116_0 = arg_116_0.heroList_:getViewRect()

	if arg_116_0:nodeByName("lev_limit_txt"):isVisible() then
		local var_116_1 = cc.rect(0, 0, var_116_0.width, var_116_0.height - var_0_7)

		arg_116_0.heroList_:setViewRect(var_116_1)
	end
end

function var_0_0.awakeMissionInit(arg_117_0)
	local var_117_0 = arg_117_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_117_0 then
		local var_117_1 = xyd.tables.mission:stage(var_117_0)

		if var_117_1 == 3 and xyd.getMissionGoIDs(var_117_0) == arg_117_0.campaignID then
			arg_117_0.isAwakeCampaign = true
			arg_117_0.awakeMission = arg_117_0.task:getTaskByID(var_117_0, xyd.TaskType.AWAKE)
			arg_117_0.awakeStage = var_117_1
			arg_117_0.awakeMissionGoalType = xyd.tables.mission:copyChallenges(var_117_0)
			arg_117_0.awakeHero = arg_117_0.selfPlayer:getHeroByTableID(xyd.tables.mission:beforeAwakenID(var_117_0))
		end

		if arg_117_0.awakeHero then
			arg_117_0.awakeHero.type = xyd.LeftMenuType.SELF_HERO
		end
	end

	if arg_117_0.isAwakeCampaign then
		local var_117_2 = ""
		local var_117_3 = var_117_0

		if arg_117_0.awakeStage == 2 then
			var_117_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP1"), arg_117_0.awakeHero:getName())
		elseif arg_117_0.awakeStage == 3 then
			if arg_117_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.SELF_KILL then
				var_117_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_117_0.awakeMissionGoalType), arg_117_0.awakeHero:getName())
			elseif arg_117_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				var_117_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_117_0.awakeMissionGoalType), xyd.tables.mission:challengeNums(var_117_3))
			elseif arg_117_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
				var_117_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_117_0.awakeMissionGoalType), arg_117_0.awakeHero:getName())
			elseif arg_117_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALL_ALIVE then
				var_117_2 = var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_117_0.awakeMissionGoalType)
			end
		end

		arg_117_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_117_0:nodeByName("lev_limit_txt"):setString(var_117_2)

		arg_117_0.preSelect_ = {}
		arg_117_0.preHeros_ = {}

		table.insert(arg_117_0.preSelect_, arg_117_0.awakeHero:getHeroID())
		table.insert(arg_117_0.preHeros_, arg_117_0.awakeHero)
	end
end

function var_0_0.sortTables(arg_118_0, arg_118_1)
	for iter_118_0 = 1, #arg_118_1 do
		table.sort(arg_118_1[iter_118_0][var_0_16.NO], function(arg_119_0, arg_119_1)
			if (arg_119_0.can_rent or arg_119_1.can_rent) and (not arg_119_0.can_rent or not arg_119_1.can_rent) then
				return arg_119_0.can_rent and not arg_119_1.can_rent
			end

			return xyd.heroNormalSort(arg_119_0, arg_119_1) or false
		end)
		table.sort(arg_118_1[iter_118_0][var_0_16.YES], function(arg_120_0, arg_120_1)
			if (arg_120_0.can_rent or arg_120_1.can_rent) and (not arg_120_0.can_rent or not arg_120_1.can_rent) then
				return arg_120_0.can_rent and not arg_120_1.can_rent
			end

			return xyd.heroNormalSort(arg_120_0, arg_120_1) or false
		end)
	end
end

function var_0_0.checkIsAssistBattle(arg_121_0)
	if arg_121_0.campaignType == xyd.CampaignType.NORMAL then
		local var_121_0, var_121_1 = arg_121_0:getBattleID()

		if var_121_1 then
			arg_121_0.preHeros_ = {}
			arg_121_0.preSelect_ = {}

			local var_121_2 = {}
			local var_121_3 = var_0_11:assistPartner(var_121_0)

			if not var_121_3 or not next(var_121_3) or #var_121_3 ~= 2 then
				return false
			end

			local var_121_4 = var_0_1.new()

			var_121_4:populateWithTableID(var_121_3[arg_121_0.assistID])
			table.insert(var_121_2, var_121_4)

			var_121_4.type = xyd.LeftMenuType.SELF_HERO
			var_121_4.isAssist = true
			arg_121_0.assistHeroID = var_121_4:getModelID()

			if #var_121_2 < xyd.MAX_TEAM_MEMBER_NUM then
				local var_121_5 = xyd.MAX_TEAM_MEMBER_NUM - #var_121_2

				for iter_121_0 = 1, var_121_5 do
					local var_121_6 = arg_121_0.selfPlayer:getHeroByID(iter_121_0)

					if var_121_6 then
						table.insert(var_121_2, var_121_6)
					end
				end

				table.sort(var_121_2, function(arg_122_0, arg_122_1)
					return arg_122_0:getDistance() < arg_122_1:getDistance()
				end)

				for iter_121_1, iter_121_2 in ipairs(var_121_2) do
					table.insert(arg_121_0.preSelect_, iter_121_2:getHeroID())
					table.insert(arg_121_0.preHeros_, iter_121_2)
				end

				return true
			end
		end

		return false
	end

	return false
end

function var_0_0.checkCanLoadPreFormation(arg_123_0)
	return false
end

function var_0_0.loadPreFormation(arg_124_0)
	local var_124_0 = {}
	local var_124_1 = {}
	local var_124_2 = xyd.db.formation:getFormationData(arg_124_0.campaignType) or {}
	local var_124_3 = var_124_2[1] or {}

	for iter_124_0, iter_124_1 in ipairs(var_124_3) do
		if iter_124_1 < 0 then
			iter_124_1 = -iter_124_1

			for iter_124_2, iter_124_3 in pairs(arg_124_0.allTeamHeros) do
				if iter_124_3:getHeroID() == iter_124_1 and #var_124_0 < xyd.MAX_TEAM_MEMBER_NUM then
					iter_124_3.type = xyd.LeftMenuType.RENT_HERO

					table.insert(var_124_0, -iter_124_1)
					table.insert(var_124_1, iter_124_3)

					break
				end
			end
		else
			local var_124_4 = arg_124_0.selfPlayer:getHeroByID(iter_124_1)

			if var_124_4 and #var_124_0 < xyd.MAX_TEAM_MEMBER_NUM then
				var_124_4.type = xyd.LeftMenuType.SELF_HERO

				table.insert(var_124_0, iter_124_1)
				table.insert(var_124_1, var_124_4)
			end
		end
	end

	arg_124_0.preSelect_ = var_124_0
	arg_124_0.preHeros_ = var_124_1

	local var_124_5 = var_124_2[2] or {}

	for iter_124_4, iter_124_5 in ipairs(var_124_5) do
		local var_124_6 = arg_124_0.selfPlayer:getPetByID(iter_124_5)

		if var_124_6 and var_124_6 and #arg_124_0.prePet_ < xyd.MAX_PET_NUMBER then
			table.insert(arg_124_0.prePet_, var_124_6)
		end
	end
end

function var_0_0.canRentHero(arg_125_0)
	if arg_125_0.isMercenary then
		return true
	end

	return false
end

function var_0_0.isPet(arg_126_0)
	if not arg_126_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	return true
end

function var_0_0.getHeros(arg_127_0)
	return arg_127_0.selfPlayer.heros_
end

function var_0_0.getPets(arg_128_0)
	return arg_128_0.selfPlayer.collectedPets
end

function var_0_0.initRegionHeros(arg_129_0, arg_129_1, arg_129_2, arg_129_3)
	for iter_129_0, iter_129_1 in pairs(arg_129_2) do
		local var_129_0 = arg_129_0:checkHeroExit(arg_129_1, iter_129_1.table_id)

		if not var_129_0 and arg_129_3 then
			-- block empty
		else
			if iter_129_1.is_summon == 1 and not var_129_0 then
				var_129_0 = var_0_1.new()

				var_129_0:initUnCollected(iter_129_1.table_id)
				table.insert(arg_129_1, var_129_0)
			end

			if iter_129_1.add_star > 0 then
				local var_129_1 = var_129_0:getStar()

				if not xyd.isSuperHero(var_129_0) then
					if var_129_1 + iter_129_1.add_star > xyd.MAX_STAR_LEVEL then
						var_129_0:setStar(xyd.MAX_STAR_LEVEL)
					else
						var_129_0:setStar(var_129_1 + iter_129_1.add_star)
					end
				elseif var_129_1 + iter_129_1.add_star > xyd.SUPER_HERO_TOTAL_STARS then
					var_129_0:setStar(xyd.SUPER_HERO_TOTAL_STARS)
				else
					var_129_0:setStar(var_129_1 + iter_129_1.add_star)
				end
			end

			if iter_129_1.is_awake == 1 and not var_129_0:isAwaken() then
				var_129_0:setTableID(xyd.tables.hero:afterAwaken(iter_129_1.table_id))
			end
		end
	end
end

function var_0_0.checkHeroExit(arg_130_0, arg_130_1, arg_130_2)
	local var_130_0 = false

	for iter_130_0, iter_130_1 in pairs(arg_130_1) do
		local var_130_1 = iter_130_1:getTableID()

		if var_130_1 == arg_130_2 then
			var_130_0 = iter_130_1

			break
		end

		if iter_130_1:isAwaken() then
			var_130_1 = iter_130_1:beforeAwakenID()
		end

		if var_130_1 == arg_130_2 then
			var_130_0 = iter_130_1

			break
		end
	end

	return var_130_0
end

function var_0_0.checkHeroIsNotUse(arg_131_0, arg_131_1)
	return false
end

function var_0_0.checkCanPresetTeam(arg_132_0)
	if arg_132_0.type == xyd.SelectTeamType.HERO_PRESET or arg_132_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_132_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		return false
	end

	return true
end

function var_0_0.isBanned(arg_133_0, arg_133_1)
	return false
end

return var_0_0
