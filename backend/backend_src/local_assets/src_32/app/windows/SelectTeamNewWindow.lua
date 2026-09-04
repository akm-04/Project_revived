local var_0_0 = class("SelectTeamNewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = import("app.model.Pet")
local var_0_4 = 30
local var_0_5 = 16
local var_0_6 = 5
local var_0_7 = 4
local var_0_8 = 6
local var_0_9 = 65
local var_0_10 = 20
local var_0_11 = 108
local var_0_12 = import("app.model.Item")
local var_0_13 = import("framework.scheduler")
local var_0_14 = xyd.tables.translation
local var_0_15 = xyd.tables.battle
local var_0_16 = xyd.tables.hero
local var_0_17 = xyd.tables.marchAdvanced
local var_0_18 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_19 = {
	RENT_HERO = 1,
	RENT_PET = 2
}
local var_0_20 = {
	RENT_PET = 2,
	SELF_PET = 1
}
local var_0_21 = {
	YES = 2,
	NO = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.CAMPAIGN
	arg_1_0.ispreperation = arg_1_2.isPreperation or false
	arg_1_0.campaignType = arg_1_2.campaignType or xyd.CampaignType.NORMAL
	arg_1_0.campaignID = arg_1_2.campaignID or 0
	arg_1_0.totalPet_ = {}
	arg_1_0.marchStage_ = arg_1_2.marchStage or 0
	arg_1_0.totalHero_ = {}
	arg_1_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_1_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_1_0.totalHero_[xyd.DistanceType.FILTER] = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0.totalHero_) do
		iter_1_1[var_0_21.NO] = {}
		iter_1_1[var_0_21.YES] = {}
	end

	arg_1_0.totalIDs_ = {}
	arg_1_0.team_ = {}
	arg_1_0.petTeam_ = {}
	arg_1_0.select_ = {}
	arg_1_0.tmpTotalPets = {}
	arg_1_0.sealHeroID = arg_1_2.sealHeroID or 0
	arg_1_0.petSelect_ = arg_1_2.petSelect or {}
	arg_1_0.preSelect_ = arg_1_2.selected or {}
	arg_1_0.enemyHeroes_ = arg_1_2.enemyHeroes
	arg_1_0.enemyID_ = arg_1_2.enemyID
	arg_1_0.oldBestRank = arg_1_2.oldBestRank
	arg_1_0.fighterInfo = arg_1_2.fighterInfo
	arg_1_0.busyHeros_ = arg_1_2.busyHeros or {}
	arg_1_0.busyPets_ = arg_1_2.busyPets or {}
	arg_1_0.treasureType = arg_1_2.treasureType or 0
	arg_1_0.treasureTeamID = arg_1_2.treasureTeamID or 0
	arg_1_0.isMercenary = arg_1_2.isMercenary or false
	arg_1_0.allTeamHeros = arg_1_2.allTeamHeros or {}
	arg_1_0.allTeamPets = {}
	arg_1_0.busyHeroList = arg_1_2.busyHeroList or {}
	arg_1_0.battleBegan = false
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.marchModel = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
	arg_1_0.memoriesOfSchool = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)
	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.is_avenge = arg_1_2.is_avenge
	arg_1_0.petFloor = arg_1_2.petFloor
	arg_1_0.petFloorType = arg_1_2.petFloorType
	arg_1_0.isBoss = arg_1_2.isBoss
	arg_1_0.chapter = arg_1_2.chapter
	arg_1_0.chapterType = arg_1_2.chapterType
	arg_1_0.collocationType_ = var_0_21.NO
	arg_1_0.isSelectMerHero = false
	arg_1_0.selectMerHero = nil
	arg_1_0.isSelectMerPet = false
	arg_1_0.selectMerPet = nil
	arg_1_0.ischangeListRect = false
	arg_1_0.tmpTotalHero_ = {}
	arg_1_0.preHeros_ = arg_1_2.preHeros
	arg_1_0.prePet_ = arg_1_2.prePet or {}
	arg_1_0.star_ = arg_1_2.star
	arg_1_0.enemyPets_ = arg_1_2.enemyPets
	arg_1_0.rateValue = var_0_17:rateValue(arg_1_0.selfPlayer.lev)
	arg_1_0.recommendHeros = arg_1_2.recommendHeros or {}
	arg_1_0.bannedHeros = arg_1_2.bannedHeros or {}
	arg_1_0.isLoadAllTeamPets = false
	arg_1_0.showEnemy = arg_1_2.showEnemy
	arg_1_0.hide_counts = arg_1_2.hide_counts
	arg_1_0.guildPrepareTime = arg_1_2.prepareTime
	arg_1_0.guildChapterID = arg_1_2.guildChapterID
	arg_1_0.guildMonsterStatus = arg_1_2.monsterStatus
	arg_1_0.isRegionPractise = arg_1_2.is_challenge
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.isAwakeCampaign = false
	arg_1_0.hasPurpleHero = arg_1_2.hasPurpleHero
	arg_1_0.hasGuildPurpleHero = arg_1_2.hasGuildPurpleHero
	arg_1_0.selectTeamId = arg_1_2.selectTeamId
	arg_1_0.monsterPos = arg_1_2.monster_pos

	if arg_1_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER or arg_1_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER then
		arg_1_0.heroStatus_ = arg_1_0.memoriesOfSchool:getHeroStatus()
		arg_1_0.bannedHeros = arg_1_0.memoriesOfSchool:getBanList()
	elseif arg_1_0.type == xyd.SelectTeamType.MARCH then
		arg_1_0.heroStatus_ = arg_1_0.marchModel:getHeroStatus()
	elseif arg_1_0.type == xyd.SelectTeamType.TREASURE then
		arg_1_0.heroStatus_ = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE):getHeroStatus()
	elseif arg_1_0.type == xyd.SelectTeamType.TWO_YEARS then
		arg_1_0.heroStatus_ = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS):getHeroStatus()
	end

	arg_1_0.selectedHeroClass_ = {}
	arg_1_0.battleID = arg_1_2.battleID
	arg_1_0.missionID = arg_1_2.missionID

	if arg_1_0.campaignID > 0 and not arg_1_0.battleID then
		arg_1_0.battleID = xyd.tables.campaign:fightID(arg_1_0.campaignID)
	end

	arg_1_0.reinforcePartnerRatios = {}

	if arg_1_0.battleID then
		arg_1_0.campaignLimit = var_0_15:campaignLimit(arg_1_0.battleID)

		for iter_1_2, iter_1_3 in ipairs(var_0_15:reinforcePartnerIds(arg_1_0.battleID)) do
			arg_1_0.reinforcePartnerRatios[iter_1_3] = var_0_15:reinforcePartnerRatios(arg_1_0.battleID)[iter_1_2]
		end
	end

	arg_1_0.regionAwards = arg_1_2.awards or {}
	arg_1_0.presetHeroIndex = arg_1_2.presetHeroIndex
	arg_1_0.presetHeroType = arg_1_2.presetHeroType
	arg_1_0.presetTeams = {}
	arg_1_0.conquerSchoolTeamID = arg_1_2.conquerSchoolTeamID
	arg_1_0.conquerUsedTeam = arg_1_2.conquerUsedTeam
	arg_1_0.assistID = arg_1_2.assistID
	arg_1_0.assistHeroID = arg_1_2.assistHeroID
	arg_1_0.selectSpType = arg_1_2.selectSpType or 0
	arg_1_0.banPet = arg_1_2.banPet
	arg_1_0.noPreset = arg_1_2.noPreset
	arg_1_0.stories = arg_1_2.stories
	arg_1_0.tutor = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR)

	if arg_1_0.guild.tutorRentHeroes and arg_1_0.isMercenary then
		local var_1_0 = arg_1_0.tutor:getRentHeros(arg_1_0.guild.tutorRentHeroes, arg_1_0.selfPlayer.lev)

		arg_1_0.allTeamHeros = xyd.mergeTable(var_1_0 or {}, arg_1_0.allTeamHeros or {})
	end
end

function var_0_0.handleRentParams(arg_2_0, arg_2_1)
	if arg_2_0.selectMerHero then
		if arg_2_0.selectMerHero.tutorInfo then
			arg_2_1.tutor_rent_hero = arg_2_0.selectMerHero.tutorInfo
		elseif arg_2_0.fourthAnni then
			arg_2_1.rent_hero_player = arg_2_0.selectMerHero.player_id
			arg_2_1.rent_hero_id = arg_2_0.selectMerHero:getHeroID()
		else
			arg_2_1.rent_player_id = arg_2_0.selectMerHero.player_id
			arg_2_1.rent_formation = tostring(arg_2_0.selectMerHero:getHeroID())
		end
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	if not next(arg_3_0.preSelect_) then
		arg_3_0:loadPreFormation()
	end

	arg_3_0:initHeros(arg_3_0:getHeros(), var_0_18.SELF_HERO)
	arg_3_0:initHeros(arg_3_0.allTeamHeros, var_0_18.RENT_HERO)
	arg_3_0:initPets(arg_3_0:getPets() or {}, var_0_20.SELF_PET)
	arg_3_0:initPresetTeams()
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:refreshSelectedHeroClass()
	arg_4_0:getBattlepetBtn()
	arg_4_0:playGuide()
	arg_4_0:updateScore()

	if arg_4_0.isAssistBattle then
		local var_4_0 = cc.p(0, 0)

		if arg_4_0.assistHeroNode and not tolua.isnull(arg_4_0.assistHeroNode) then
			var_4_0 = arg_4_0.assistHeroNode:getParent():convertToWorldSpace(cc.p(arg_4_0.assistHeroNode:getPosition()))
		end

		local var_4_1 = {
			table_id = arg_4_0.assistHeroID,
			pos = var_4_0,
			callback = function()
				if arg_4_0.assistHeroNode and not tolua.isnull(arg_4_0.assistHeroNode) then
					local var_5_0 = cc.p(arg_4_0.assistHeroNode:getPosition())

					arg_4_0.assistHeroNode:setVisible(true)
					arg_4_0:moveFadeInAction(var_5_0.x, var_5_0.y, arg_4_0.assistHeroNode)
				end
			end
		}

		xyd.WindowManager.get():openWindow("assist_hero_show", var_4_1)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_4_0, arg_4_0.updateList))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.HERO_SEARCH, handler(arg_4_0, arg_4_0.updateListBySearchTxt))
	arg_4_0:checkShowBlockLayer()
end

function var_0_0.updateList(arg_6_0, ...)
	if arg_6_0.leftMenuType_ ~= var_0_18.SELF_HERO then
		return
	end

	arg_6_0.selectedHeroClass_[arg_6_0.leftMenuType_] = xyd.DistanceType.FILTER
	arg_6_0.isHeroPreset = false

	arg_6_0:updateFilterHeros()
	arg_6_0:refreshSelectedHeroClass()
end

function var_0_0.updateListBySearchTxt(arg_7_0, arg_7_1)
	if arg_7_0.leftMenuType_ ~= var_0_18.SELF_HERO then
		return
	end

	arg_7_0.searchTxt = arg_7_1.heroName
	arg_7_0.selectedHeroClass_[arg_7_0.leftMenuType_] = xyd.DistanceType.SEARCH

	arg_7_0:updateSearchHeros()
	arg_7_0:refreshSelectedHeroClass()
end

function var_0_0.initEnemys(arg_8_0)
	local var_8_0 = 1

	if arg_8_0.type and arg_8_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_8_0.type == xyd.SelectTeamType.REGION_ARENA then
		xyd.formatRegionArenaHeros(arg_8_0.enemyHeroes_)
		xyd.formatRegionArenaPets({
			arg_8_0.enemyPets_
		})
	end

	local var_8_1 = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.enemyHeroes_) do
		var_8_1 = var_8_1 + 1
	end

	table.sort(arg_8_0.enemyHeroes_, function(arg_9_0, arg_9_1)
		return arg_9_0:getDistance() < arg_9_1:getDistance()
	end)

	for iter_8_2, iter_8_3 in pairs(arg_8_0.enemyHeroes_) do
		if arg_8_0.hide_counts and var_8_1 - var_8_0 + 1 < arg_8_0.hide_counts then
			local var_8_2 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

			xyd.displaySpriteOnContainer(var_8_2, arg_8_0:nodeByName("enemy_hero_" .. var_8_0), true)
		elseif iter_8_3.status_ then
			local var_8_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar3.csb")
			local var_8_4 = var_8_3:getChildByName("background"):getContentSize()

			var_8_3:setContentSize(var_8_4)
			var_8_3:setScale(86 / var_8_4.width)
			xyd.setAvatarBorderNewUI(iter_8_3, var_8_3:getChildByName("avatar"))

			local var_8_5 = var_8_3:getChildByName("avatar_mask")

			var_8_5:setVisible(false)
			var_8_3:getChildByName("lv_di"):setVisible(false)
			var_8_3:getChildByName("lv_txt"):setVisible(false)

			local var_8_6 = var_8_3:getChildByName("hp_bar")
			local var_8_7 = var_8_3:getChildByName("dead_text")

			var_8_7:setString(var_0_14:translation("ALREADY_DEAD"))

			if var_8_7 then
				var_8_7:setVisible(false)
			end

			local var_8_8 = false
			local var_8_9 = iter_8_3.status_

			if var_8_9 and var_8_9.health then
				local var_8_10 = 0

				if var_8_9.health == 0 then
					var_8_10 = 100
				elseif var_8_9.health == 1 and var_8_9.hp >= 1 then
					var_8_10 = var_8_9.hp / (var_8_9.total_hp or iter_8_3:getTotalAttr(xyd.AttributeType.HP)) * 100
				else
					var_8_10 = 0

					var_8_5:setVisible(true)
					var_8_7:setLocalZOrder(3)
					var_8_7:setVisible(true)
					var_8_7:enableOutline(cc.c4b(0, 0, 0), 2)
					var_8_7:getVirtualRenderer():setAdditionalKerning(-2)

					local var_8_11 = true
				end

				var_8_6:setPercent(var_8_10)
				var_8_6:setVisible(true)
			end

			var_8_3:setName("layout")
			var_8_3:setPosition(cc.p(0, 0))
			arg_8_0:nodeByName("enemy_hero_" .. var_8_0):addChild(var_8_3)
		else
			xyd.setAvatarBorderNewUI(iter_8_3, arg_8_0:nodeByName("enemy_hero_" .. var_8_0))

			if iter_8_3.isLeader then
				local var_8_12 = xyd.AssetLoader.get():loadSprite("windows/arena/mode/lead_icon.png")

				var_8_12:addTo(arg_8_0:nodeByName("enemy_hero_" .. var_8_0))
				var_8_12:setPosition(20, 70)
			end
		end

		var_8_0 = var_8_0 + 1
	end

	if arg_8_0.enemyPets_ then
		if arg_8_0.hide_counts and arg_8_0.hide_counts >= 1 then
			local var_8_13 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/pet_hide.png")

			xyd.displaySpriteOnContainer(var_8_13, arg_8_0:nodeByName("enemy_pet"), true)
		else
			xyd.setPetAvatarNewUI(arg_8_0:nodeByName("enemy_pet"), arg_8_0.enemyPets_, 100)
		end
	end
end

function var_0_0.layout(arg_10_0)
	arg_10_0:nodeByName("lev_limit_txt"):setVisible(false)

	if arg_10_0.type == xyd.SelectTeamType.ADVANCED then
		arg_10_0:initRecommend()
	else
		arg_10_0:nodeByName("recommend_layer"):setVisible(false)
	end

	if arg_10_0.showEnemy then
		arg_10_0:nodeByName("battle_team_bg"):setVisible(true)
		arg_10_0:initEnemys()
	else
		arg_10_0:nodeByName("battle_team_bg"):setVisible(false)
	end

	arg_10_0:initRightMenu()
	arg_10_0:initLeftMenu()
	arg_10_0:initTopRentMenu()
	arg_10_0:selectHeros()
	arg_10_0:selectPets()
	arg_10_0:initListview()
	arg_10_0:awakeMissionInit()
	arg_10_0:checkGuildPrepareTime()
	arg_10_0:updateListPosByLeftMenu()
	arg_10_0:checkHeroIcon()
	arg_10_0:setCloseBtn()
	arg_10_0:nodeByName("title"):setString(var_0_14:translation("SELECT_TEAM_TEXT_2"))
end

function var_0_0.checkHeroIcon(arg_11_0)
	arg_11_0:nodeByName("icon_hero"):setVisible(false)
	arg_11_0:nodeByName("no_hero_text"):setVisible(false)

	if arg_11_0.isHeroPreset then
		if #arg_11_0.presetTeams == 0 then
			arg_11_0:nodeByName("icon_hero"):setVisible(true)
			arg_11_0:nodeByName("no_hero_text"):setVisible(true)
			arg_11_0:nodeByName("icon_hero"):y(arg_11_0.heroList_:getViewRect().height / 2 + 10)
			arg_11_0:nodeByName("no_hero_text"):y(arg_11_0:nodeByName("icon_hero"):getPositionY() - arg_11_0:nodeByName("icon_hero"):getContentSize().height / 2)
			arg_11_0:nodeByName("no_hero_text"):setString(var_0_14:translation("SELECT_TEAM_TEXT_3"))
		end
	elseif arg_11_0.leftMenuType_ == var_0_18.SELF_PET or arg_11_0.leftMenuType_ == var_0_18.RENT_HERO and arg_11_0.rentMenuType == var_0_19.RENT_PET then
		if #arg_11_0.totalPet_ == 0 then
			arg_11_0:nodeByName("icon_hero"):setVisible(true)
			arg_11_0:nodeByName("no_hero_text"):setVisible(true)
			arg_11_0:nodeByName("icon_hero"):y(arg_11_0.heroList_:getViewRect().height / 2 + 10)
			arg_11_0:nodeByName("no_hero_text"):y(arg_11_0:nodeByName("icon_hero"):getPositionY() - arg_11_0:nodeByName("icon_hero"):getContentSize().height / 2)

			if arg_11_0.leftMenuType_ == var_0_18.SELF_PET then
				arg_11_0:nodeByName("no_hero_text"):setString(var_0_14:translation("SELECT_TEAM_TEXT_4"))
			elseif arg_11_0.leftMenuType_ == var_0_18.RENT_HERO then
				arg_11_0:nodeByName("no_hero_text"):setString(var_0_14:translation("SELECT_TEAM_TEXT_5"))
			elseif arg_11_0.rentMenuType == var_0_19.RENT_PET then
				arg_11_0:nodeByName("no_hero_text"):setString(var_0_14:translation("SELECT_TEAM_TEXT_6"))
			end
		end
	elseif #arg_11_0.totalHero_[arg_11_0.selectedHeroClass_[arg_11_0.leftMenuType_]][arg_11_0.collocationType_] == 0 then
		arg_11_0:nodeByName("icon_hero"):setVisible(true)
		arg_11_0:nodeByName("no_hero_text"):setVisible(true)
		arg_11_0:nodeByName("icon_hero"):y(arg_11_0.heroList_:getViewRect().height / 2 + 10)
		arg_11_0:nodeByName("no_hero_text"):y(arg_11_0:nodeByName("icon_hero"):getPositionY() - arg_11_0:nodeByName("icon_hero"):getContentSize().height / 2)
		arg_11_0:nodeByName("no_hero_text"):setString(var_0_14:translation("SELECT_TEAM_TEXT_7"))
	end

	if arg_11_0.heroList_:getViewRect().height < arg_11_0:nodeByName("icon_hero"):getContentSize().height then
		arg_11_0:nodeByName("icon_hero"):setVisible(false)
		arg_11_0:nodeByName("no_hero_text"):setVisible(false)
	end
end

function var_0_0.initRightMenu(arg_12_0)
	arg_12_0.rightMenuButtons_ = {}

	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_all"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_qianpai"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_zhongpai"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_houpai"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_filter"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_search"))

	arg_12_0.rightMenuText_ = {}

	table.insert(arg_12_0.rightMenuText_, arg_12_0:nodeByName("all"))
	table.insert(arg_12_0.rightMenuText_, arg_12_0:nodeByName("qianpai"))
	table.insert(arg_12_0.rightMenuText_, arg_12_0:nodeByName("zhongpai"))
	table.insert(arg_12_0.rightMenuText_, arg_12_0:nodeByName("houpai"))

	for iter_12_0 = 1, #arg_12_0.rightMenuButtons_ do
		arg_12_0.rightMenuButtons_[iter_12_0]:setZoomScale(0.3)
		arg_12_0.rightMenuButtons_[iter_12_0]:addTouchEventListener(function(arg_13_0, arg_13_1)
			if arg_13_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_12_0.selectedHeroClass_[arg_12_0.leftMenuType_] == iter_12_0 and not arg_12_0.isHeroPreset then
					for iter_13_0 = 1, #arg_12_0.rightMenuButtons_ do
						if iter_13_0 == arg_12_0.selectedHeroClass_[arg_12_0.leftMenuType_] then
							arg_12_0.rightMenuButtons_[iter_13_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_12_0.rightMenuButtons_[iter_13_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_12_0.isHeroPreset = false
				arg_12_0.selectedHeroClass_[arg_12_0.leftMenuType_] = iter_12_0

				arg_12_0:refreshSelectedHeroClass()
			end
		end)
	end

	if not arg_12_0.noPreset and arg_12_0:checkCanPresetTeam() then
		arg_12_0:nodeByName("button_preset"):setZoomScale(0.3)
		arg_12_0:nodeByName("button_preset"):addTouchEventListener(function(arg_14_0, arg_14_1)
			if arg_14_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if not arg_12_0.isHeroPreset then
					arg_12_0.isHeroPreset = true
					arg_12_0.leftMenuType_ = var_0_18.SELF_HERO

					arg_12_0:updateListPosByLeftMenu()
					arg_12_0:selectHeros()
					arg_12_0:selectPets()
					arg_12_0:updateTextOfList()

					if arg_12_0.leftMenuButtons_ then
						for iter_14_0, iter_14_1 in ipairs(arg_12_0.leftMenuButtons_) do
							iter_14_1:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					for iter_14_2 = 1, #arg_12_0.rightMenuButtons_ do
						arg_12_0.rightMenuButtons_[iter_14_2]:setBrightStyle(ccui.BrightStyle.normal)
					end

					arg_12_0.heroList_:reload()
					arg_12_0:checkHeroIcon()
				end

				arg_12_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
			end
		end)
	else
		arg_12_0:nodeByName("button_preset"):setVisible(false)
	end

	arg_12_0:nodeByName("text_filter"):setString(var_0_14:translation("FILTER_TEXT"))
	arg_12_0:nodeByName("button_filter"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_12_0.leftMenuType_ ~= var_0_18.SELF_HERO then
				return
			end

			xyd.WindowManager.get():openWindow("hero_filter_wnd")
		end
	end)
	arg_12_0:nodeByName("button_search"):addTouchEventListener(function(arg_16_0, arg_16_1)
		xyd.buttonScaleAnim(arg_16_0, arg_16_1)

		if arg_16_1 == ccui.TouchEventType.ended then
			if arg_12_0.leftMenuType_ ~= var_0_18.SELF_HERO then
				return
			end

			xyd.WindowManager.get():openWindow("hero_search_wnd")
		end
	end)
	arg_12_0:nodeByName("button_collocation"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			if arg_12_0.leftMenuType_ ~= var_0_18.SELF_HERO then
				return
			end

			arg_12_0.collocationType_ = 3 - arg_12_0.collocationType_

			arg_12_0:refreshSelectedHeroClass()
		end
	end)
end

function var_0_0.initLeftMenu(arg_18_0)
	arg_18_0:nodeByName("button_zhandui"):hide()

	arg_18_0:nodeByName("button_zhandui").menu_type = var_0_18.SELF_HERO

	arg_18_0:nodeByName("button_yongbing"):hide()

	arg_18_0:nodeByName("button_yongbing").menu_type = var_0_18.RENT_HERO

	arg_18_0:nodeByName("button_pet"):hide()

	arg_18_0:nodeByName("button_pet").menu_type = var_0_18.SELF_PET
	arg_18_0.leftMenuType_ = var_0_18.SELF_HERO
	arg_18_0.leftMenuButtons_, arg_18_0.leftMenuText_ = {}, {}

	table.insert(arg_18_0.leftMenuButtons_, arg_18_0:nodeByName("button_zhandui"))
	arg_18_0:nodeByName("button_zhandui"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_18_0:nodeByName("button_zhandui"):width(151)
	arg_18_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)

	if arg_18_0:canRentHero() then
		table.insert(arg_18_0.leftMenuButtons_, arg_18_0:nodeByName("button_yongbing"))
	end

	if arg_18_0:isPet() then
		arg_18_0:nodeByName("rate_bg"):setVisible(false)
		table.insert(arg_18_0.leftMenuButtons_, arg_18_0:nodeByName("button_pet"))
	else
		arg_18_0:nodeByName("avatar_pet1"):hide()
		arg_18_0:nodeByName("bg_pet"):hide()

		if arg_18_0.type == xyd.SelectTeamType.ADVANCED then
			arg_18_0:nodeByName("rate_bg"):setVisible(true)
		else
			arg_18_0:nodeByName("rate_bg"):setVisible(false)
			arg_18_0:nodeByName("text_bg"):setLocalZOrder(10)
		end

		for iter_18_0 = 1, 5 do
			arg_18_0:nodeByName("avatar" .. iter_18_0):x(arg_18_0:nodeByName("avatar" .. iter_18_0):getX() - 127)
			arg_18_0:nodeByName("select_lock_self" .. iter_18_0):x(arg_18_0:nodeByName("select_lock_self" .. iter_18_0):getX() - 127)
			arg_18_0:nodeByName("bg_hero" .. iter_18_0):x(arg_18_0:nodeByName("bg_hero" .. iter_18_0):getX() - 127)
		end
	end

	if not arg_18_0.noPreset and arg_18_0:checkCanPresetTeam() then
		arg_18_0:nodeByName("button_preset"):y(arg_18_0.leftMenuButtons_[1]:getY() - 74 * #arg_18_0.leftMenuButtons_)
	else
		arg_18_0:nodeByName("button_preset"):setVisible(false)
	end

	if #arg_18_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_18_1 = 1, #arg_18_0.leftMenuButtons_ do
		arg_18_0.leftMenuButtons_[iter_18_1]:show()
		arg_18_0.leftMenuButtons_[iter_18_1]:setZoomScale(0.3)

		local var_18_0 = arg_18_0.leftMenuButtons_[1]:getY() - 74 * (iter_18_1 - 1)

		arg_18_0.leftMenuButtons_[iter_18_1]:y(var_18_0)
		arg_18_0.leftMenuButtons_[iter_18_1]:addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_19_0, iter_19_1 in ipairs(arg_18_0.leftMenuButtons_) do
					iter_19_1:setBrightStyle(arg_19_0 == iter_19_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_18_0.leftMenuType_ = arg_19_0.menu_type
				arg_18_0.isHeroPreset = false
				arg_18_0.rentMenuType = var_0_19.RENT_HERO

				arg_18_0:updateListPosByLeftMenu()
				arg_18_0:selectHeros()
				arg_18_0:selectPets()
				arg_18_0:refreshSelectedHeroClass()
				arg_18_0:updateTextOfList()
			end
		end)
	end
end

function var_0_0.initTopRentMenu(arg_20_0)
	arg_20_0:nodeByName("btn_rent_hero"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_20_0.rentMenuType = var_0_19.RENT_HERO

			arg_20_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_20_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_20_0:selectPets()
			arg_20_0:updateListPosByLeftMenu()
			arg_20_0.heroList_:reload()
			arg_20_0:checkHeroIcon()
		end
	end)
	arg_20_0:nodeByName("btn_rent_pet"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended and not arg_20_0.isClickRentPet then
			arg_20_0.isClickRentPet = true

			xyd.playButtonSound()

			arg_20_0.rentMenuType = var_0_19.RENT_PET

			arg_20_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.normal)
			arg_20_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_20_0:initRentPets(function()
				arg_20_0:selectPets()
				arg_20_0:updateListPosByLeftMenu()
				arg_20_0.heroList_:reload()
				arg_20_0:checkHeroIcon()

				arg_20_0.isClickRentPet = false
			end)
		end
	end)
	arg_20_0:nodeByName("top_rent_container"):setVisible(false)
	arg_20_0:nodeByName("rent_bg"):setVisible(false)

	arg_20_0.rentMenuType = var_0_19.RENT_HERO
end

function var_0_0.initRentPets(arg_24_0, arg_24_1)
	if not arg_24_0.isLoadAllTeamPets then
		local var_24_0 = {}

		arg_24_0.guild:loadAllTeamPets(var_24_0, function(arg_25_0)
			arg_24_0.allTeamPets = {}

			if arg_25_0 == xyd.error.OK then
				for iter_25_0, iter_25_1 in ipairs(arg_24_0.guild:getAllTeamPets()) do
					local var_25_0 = var_0_3.new()

					var_25_0:populate(iter_25_1)

					var_25_0.player_name = iter_25_1.player_name
					var_25_0.rent_need_mana = iter_25_1.rent_need_mana
					var_25_0.can_rent = iter_25_1.can_rent
					var_25_0.player_id = iter_25_1.player_id

					table.insert(arg_24_0.allTeamPets, var_25_0)
				end

				arg_24_0.isLoadAllTeamPets = true
			end

			arg_24_0:initPets(arg_24_0.allTeamPets, var_0_20.RENT_PET)

			if arg_24_1 then
				arg_24_1()
			end
		end)
	elseif arg_24_1 then
		arg_24_1()
	end
end

function var_0_0.updateListPosByLeftMenu(arg_26_0)
	if arg_26_0.leftMenuType_ == var_0_18.RENT_HERO and arg_26_0:isPet() then
		arg_26_0:nodeByName("top_rent_container"):setVisible(true)
		arg_26_0:nodeByName("rent_bg"):setVisible(true)
	else
		arg_26_0:nodeByName("top_rent_container"):setVisible(false)
		arg_26_0:nodeByName("rent_bg"):setVisible(false)
	end

	arg_26_0:nodeByName("button_filter"):setVisible(true)
	arg_26_0:nodeByName("button_collocation"):setVisible(false)

	if arg_26_0.showEnemy or arg_26_0.type == xyd.SelectTeamType.ADVANCED then
		if arg_26_0.leftMenuType_ == var_0_18.RENT_HERO then
			if arg_26_0.rentMenuType == var_0_19.RENT_PET then
				for iter_26_0, iter_26_1 in ipairs(arg_26_0.rightMenuButtons_) do
					iter_26_1:setVisible(false)
				end

				for iter_26_2, iter_26_3 in ipairs(arg_26_0.rightMenuText_) do
					iter_26_3:setVisible(false)
				end

				arg_26_0:nodeByName("line"):setVisible(false)
				arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 290))
				arg_26_0:nodeByName("list_layer"):height(290)
			elseif arg_26_0.rentMenuType == var_0_19.RENT_HERO then
				for iter_26_4, iter_26_5 in ipairs(arg_26_0.rightMenuButtons_) do
					iter_26_5:setVisible(true)
				end

				for iter_26_6, iter_26_7 in ipairs(arg_26_0.rightMenuText_) do
					iter_26_7:setVisible(true)
				end

				arg_26_0:nodeByName("button_filter"):setVisible(false)
				arg_26_0:nodeByName("button_search"):setVisible(false)
				arg_26_0:nodeByName("line"):setVisible(true)

				for iter_26_8, iter_26_9 in ipairs(arg_26_0.rightMenuButtons_) do
					iter_26_9:y(457)
				end

				for iter_26_10, iter_26_11 in ipairs(arg_26_0.rightMenuText_) do
					iter_26_11:y(459)
				end

				arg_26_0:nodeByName("line"):y(424)
				arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 220))
				arg_26_0:nodeByName("list_layer"):height(220)
			end
		elseif arg_26_0.leftMenuType_ == var_0_18.SELF_HERO then
			for iter_26_12, iter_26_13 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_13:setVisible(true)
			end

			for iter_26_14, iter_26_15 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_15:setVisible(true)
			end

			if not arg_26_0.isHeroPreset then
				arg_26_0:nodeByName("button_collocation"):setVisible(true)
			end

			arg_26_0:nodeByName("line"):setVisible(true)

			for iter_26_16, iter_26_17 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_17:y(457)
			end

			for iter_26_18, iter_26_19 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_19:y(459)
			end

			arg_26_0:nodeByName("line"):y(424)
			arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 220))
			arg_26_0:nodeByName("list_layer"):height(220)
		elseif arg_26_0.leftMenuType_ == var_0_18.SELF_PET then
			for iter_26_20, iter_26_21 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_21:setVisible(false)
			end

			for iter_26_22, iter_26_23 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_23:setVisible(false)
			end

			arg_26_0:nodeByName("line"):setVisible(false)
			arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 290))
			arg_26_0:nodeByName("list_layer"):height(290)
		end

		if arg_26_0.isHeroPreset then
			for iter_26_24, iter_26_25 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_25:y(457)
			end

			for iter_26_26, iter_26_27 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_27:y(459)
			end

			arg_26_0:nodeByName("line"):y(424)
			arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 220))
			arg_26_0:nodeByName("list_layer"):height(220)
		end
	else
		if arg_26_0.leftMenuType_ == var_0_18.RENT_HERO and arg_26_0:isPet() then
			if arg_26_0.rentMenuType == var_0_19.RENT_PET then
				for iter_26_28, iter_26_29 in ipairs(arg_26_0.rightMenuButtons_) do
					iter_26_29:setVisible(false)
				end

				for iter_26_30, iter_26_31 in ipairs(arg_26_0.rightMenuText_) do
					iter_26_31:setVisible(false)
				end

				arg_26_0:nodeByName("line"):setVisible(false)
				arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 385))
				arg_26_0:nodeByName("list_layer"):height(385)
			elseif arg_26_0.rentMenuType == var_0_19.RENT_HERO then
				for iter_26_32, iter_26_33 in ipairs(arg_26_0.rightMenuButtons_) do
					iter_26_33:setVisible(true)
				end

				for iter_26_34, iter_26_35 in ipairs(arg_26_0.rightMenuText_) do
					iter_26_35:setVisible(true)
				end

				arg_26_0:nodeByName("button_filter"):setVisible(false)
				arg_26_0:nodeByName("button_search"):setVisible(false)
				arg_26_0:nodeByName("line"):setVisible(true)

				for iter_26_36, iter_26_37 in ipairs(arg_26_0.rightMenuButtons_) do
					iter_26_37:y(557)
				end

				for iter_26_38, iter_26_39 in ipairs(arg_26_0.rightMenuText_) do
					iter_26_39:y(559)
				end

				arg_26_0:nodeByName("line"):y(524)
				arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 322))
				arg_26_0:nodeByName("list_layer"):height(322)
			end
		elseif arg_26_0.leftMenuType_ == var_0_18.SELF_HERO then
			for iter_26_40, iter_26_41 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_41:setVisible(true)
			end

			for iter_26_42, iter_26_43 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_43:setVisible(true)
			end

			arg_26_0:nodeByName("line"):setVisible(true)

			if not arg_26_0.isHeroPreset then
				arg_26_0:nodeByName("button_collocation"):setVisible(true)
			end

			for iter_26_44, iter_26_45 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_45:y(607)
			end

			for iter_26_46, iter_26_47 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_47:y(609)
			end

			arg_26_0:nodeByName("line"):y(574)
			arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 370))
			arg_26_0:nodeByName("list_layer"):height(370)
		elseif arg_26_0.leftMenuType_ == var_0_18.SELF_PET then
			for iter_26_48, iter_26_49 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_49:setVisible(false)
			end

			for iter_26_50, iter_26_51 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_51:setVisible(false)
			end

			arg_26_0:nodeByName("line"):setVisible(false)
			arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 430))
			arg_26_0:nodeByName("list_layer"):height(430)
		end

		if arg_26_0.isHeroPreset then
			for iter_26_52, iter_26_53 in ipairs(arg_26_0.rightMenuButtons_) do
				iter_26_53:y(607)
			end

			for iter_26_54, iter_26_55 in ipairs(arg_26_0.rightMenuText_) do
				iter_26_55:y(609)
			end

			arg_26_0:nodeByName("line"):y(574)
			arg_26_0.heroList_:setViewRect(cc.rect(0, 0, 900, 370))
			arg_26_0:nodeByName("list_layer"):height(370)
		end
	end

	arg_26_0:nodeByName("lev_limit_txt"):setPositionY(arg_26_0.heroList_:getViewRect().height)
	arg_26_0:initTextOfList()
end

function var_0_0.initPetCell(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_0.totalPet_[arg_27_2]
	local var_27_1 = false

	if arg_27_0.rentMenuType == var_0_19.RENT_PET then
		local var_27_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/rent_pet_item.csb")

		var_27_2:setTouchSwallowEnabled(false)
		arg_27_1:addChild(var_27_2)

		arg_27_1.type = var_0_20.RENT_PET

		var_27_2:setName("rent_cell")

		local var_27_3 = var_27_2:getChildByName("container")
		local var_27_4 = var_0_2.new({
			size = 139
		})

		var_27_4:addTo(var_27_3)
		var_27_4:setAnchorPoint(0, 0.5)
		var_27_4:setPosition(var_27_3:getChildByName("pos_splitline"):getPosition())
		arg_27_1:align(display.CENTER):size(var_27_3:getContentSize().width, var_27_3:getContentSize().height)

		local var_27_5 = var_27_3:getChildByName("avatar")

		var_27_3:getChildByName("player_name"):setString(var_27_0.player_name)
		var_27_3:getChildByName("rent_cost"):setString(var_27_0.rent_need_mana)
		var_27_5:getChildByName("yongbing_tubiao"):setPosition(cc.p(90, 100))
		xyd.setPetAvatarNewUI(var_27_5, var_27_0, 100)
		var_27_5:setPositionY(var_27_5:getPositionY() + 15)

		if not var_27_0.can_rent then
			var_27_3:getChildByName("can_not_rent"):setString(var_0_14:translation("CAN_NOT_BORROW"))
			var_27_5:getChildByName("layout"):getChildByName("chosen"):setVisible(false)
			var_27_5:getChildByName("layout"):getChildByName("avatar_mask"):setVisible(true)
		else
			var_27_3:getChildByName("can_not_rent"):setVisible(false)
		end
	else
		arg_27_1:align(display.CENTER):size(146, 146)
		xyd.setPetAvatarNewUI(arg_27_1, var_27_0, 100)

		arg_27_1.type = var_0_20.SELF_PET

		arg_27_0:initPetCellStatus(arg_27_1, var_27_0)
	end

	arg_27_1.data = var_27_0

	arg_27_1:setTouchSwallowEnabled(false)

	if arg_27_0.type == xyd.SelectTeamType.DREAM_WORLD then
		local var_27_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD).coolTimeInfo.cooltime_pets[tostring(var_27_0:getTableID())]
		local var_27_7 = xyd.ServerTime.get():getServerTime()

		if var_27_6 and var_27_7 < var_27_6 then
			local var_27_8 = arg_27_1:getChildByName("layout")
			local var_27_9 = display.newNode()
			local var_27_10
			local var_27_11 = {
				size = 20,
				color = cc.c4b(255, 127, 127, 255),
				align = cc.ui.TEXT_ALIGN_CENTER,
				text = var_0_14:translation("BANED")
			}
			local var_27_12 = xyd.AssetLoader:get():loadLabel(var_27_11)

			var_27_12:setAnchorPoint(cc.p(0.5, 0.5))
			var_27_12:enableOutline(cc.c4b(49, 21, 21, 255), 2)
			var_27_12:setPosition(arg_27_1:getWidth() / 2 + 2, 95)
			var_27_12:addTo(var_27_9)
			var_27_12:setString(var_0_14:translation("BANED"))
			var_27_8:getChildByName("avatar_mask"):setVisible(true)

			local var_27_13 = xyd.AssetLoader.get():loadSprite("windows/dream_world/explore/time_mask_pet.png")

			var_27_13:addTo(var_27_9)
			var_27_13:setPosition(arg_27_1:getWidth() / 2, 67)

			local var_27_14 = {
				size = 22,
				color = cc.c4b(255, 255, 255, 255)
			}
			local var_27_15 = xyd.AssetLoader:get():loadLabel(var_27_14)

			var_27_15:setName("time")
			var_27_15:setAnchorPoint(cc.p(0.5, 0.5))
			var_27_15:setString(xyd.secondsToString(var_27_6 - var_27_7))
			var_27_15:addTo(var_27_9)
			var_27_15:setPosition(arg_27_1:getWidth() / 2, 67)

			var_27_9.coolTime = var_27_6
			var_27_9.tableID = var_27_0:getTableID()

			var_27_9:addTo(var_27_8, 99)

			var_27_9.layout = var_27_8

			arg_27_0:addDreamWorldCoolTimeNode(var_27_9)
		end
	end

	local var_27_16 = display.newNode()

	var_27_16:setContentSize(arg_27_1:getContentSize())
	var_27_16:addTo(arg_27_1)
	var_27_16:setTouchEnabled(true)
	var_27_16:setTouchSwallowEnabled(false)
	var_27_16:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
		if not var_27_1 then
			arg_27_0:buttonHandler(nil, arg_27_1, arg_28_0)

			if arg_28_0.name == "began" then
				arg_27_0.startClick_ = true
				arg_27_0.prevX_ = arg_28_0.x
				arg_27_0.prevY_ = arg_28_0.y
			elseif arg_28_0.name == "moved" then
				if math.abs(arg_28_0.y - arg_27_0.prevY_) > 5 or math.abs(arg_28_0.x - arg_27_0.prevX_) > 5 then
					arg_27_0.startClick_ = false
				end
			elseif arg_28_0.name == "ended" and arg_27_0.startClick_ then
				local var_28_0 = var_27_0.rent_need_mana

				if arg_27_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_27_0:checkPetIsConquerUsed(var_27_0) then
					return
				elseif arg_27_0.isAwakeCampaign and arg_27_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
					local function var_28_1()
						arg_27_0:clickPetAvatar(arg_27_1)
					end

					local var_28_2 = {
						txt = var_0_14:translation("AWAKE_SELECT_TEAM_TIP6"),
						type = xyd.CommonAlertType.TWO_BTN,
						rcallback = var_28_1,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_28_2)
				elseif arg_27_0.rentMenuType == var_0_19.RENT_PET and not var_27_0.can_rent then
					return
				elseif var_28_0 and var_28_0 > arg_27_0.selfPlayer.mana and var_27_0.can_rent then
					local var_28_3 = var_0_14:translation("MERCENARY_ERROR_TIP4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_28_3
					})

					return
				elseif arg_27_0.type == xyd.SelectTeamType.DREAM_WORLD then
					local var_28_4 = var_27_0:getTableID()

					if arg_27_0:checkDreamWorldCoolTime(var_28_4) then
						local var_28_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)

						if var_28_5.mapType == xyd.DreamWorldType.CHALLENGE then
							local function var_28_6()
								local var_30_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

								if xyd.tables.misc:getValue("dreamworld_hard_battle_partner_crystal") > var_30_0.crystal then
									local function var_30_1()
										local var_31_0 = {}

										var_31_0.windowState = true

										xyd.WindowManager.get():openWindow("vip_recharge", var_31_0)
									end

									local var_30_2 = {
										rcallBefore = 0,
										txt = var_0_14:translation("ZUANSHI_ABSENCE"),
										rcallback = var_30_1,
										align = xyd.ui_align.CENTER
									}

									xyd.WindowManager.get():openWindow("common_alert", var_30_2)
								else
									local var_30_3 = {
										pets = {
											var_28_4
										}
									}

									var_28_5:resetCoolTime(var_30_3, function(arg_32_0, arg_32_1)
										if arg_32_0 == xyd.error.OK then
											arg_27_0:clearDreamWorldCoolTimeNode(var_28_4)
										end
									end)
								end
							end

							local var_28_7 = {
								rcallBefore = 0,
								txt = var_0_14:translation("DREAM_WORLD_TEXT_13"),
								rcallback = var_28_6,
								align = xyd.ui_align.CENTER
							}

							xyd.WindowManager.get():openWindow("common_alert", var_28_7)
						end
					else
						arg_27_0:clickPetAvatar(arg_27_1)
					end
				else
					arg_27_0:clickPetAvatar(arg_27_1)
				end
			end
		end

		return true
	end)

	for iter_27_0, iter_27_1 in ipairs(arg_27_0.petTeam_) do
		if var_27_0 == iter_27_1.data or arg_27_0.type == xyd.SelectTeamType.TWO_YEARS and var_27_0:getPetID() == iter_27_1.data:getPetID() then
			arg_27_0.petTeam_[iter_27_0].iniCell_ = arg_27_1
			arg_27_1.teamNo_ = iter_27_0

			local var_27_17

			if arg_27_0.rentMenuType == var_0_19.RENT_PET then
				var_27_17 = arg_27_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
			else
				var_27_17 = arg_27_1:getChildByName("layout")
			end

			local var_27_18 = var_27_17:getChildByName("avatar_mask")
			local var_27_19 = var_27_17:getChildByName("chosen")

			var_27_18:setVisible(true)
			var_27_19:setVisible(true)

			break
		end
	end

	for iter_27_2, iter_27_3 in pairs(arg_27_0.busyPets_) do
		if iter_27_3 == var_27_0:getPetID() then
			local var_27_20

			if arg_27_0.rentMenuType == var_0_19.RENT_PET then
				var_27_20 = arg_27_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
			else
				var_27_20 = arg_27_1:getChildByName("layout")
			end

			local var_27_21 = var_27_20:getChildByName("avatar_mask")

			var_27_20:getChildByName("chosen"):setVisible(true)
			var_27_21:setVisible(true)

			var_27_1 = true

			break
		end
	end
end

function var_0_0.initPetCellStatus(arg_33_0, arg_33_1, arg_33_2, arg_33_3, arg_33_4)
	arg_33_3 = arg_33_3 or 0
	arg_33_4 = arg_33_4 or 0

	if arg_33_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_33_0:checkPetIsConquerUsed(arg_33_2) then
		local var_33_0 = arg_33_1:getChildByName("layout")

		var_33_0:getChildByName("avatar_mask"):setVisible(true)

		local var_33_1 = var_33_0:getChildByName("background"):getContentSize()
		local var_33_2 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

		var_33_2:setAnchorPoint(cc.p(0, 1))
		var_33_2:setPosition(var_33_1.width / 2 + arg_33_3, var_33_1.height - 20 + arg_33_4)
		arg_33_1:addChild(var_33_2, 11)
	end
end

function var_0_0.initPresetCell(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = arg_34_0.presetTeams[arg_34_2].team
	local var_34_1 = arg_34_0.presetTeams[arg_34_2].teamName
	local var_34_2 = arg_34_0.presetTeams[arg_34_2].pet
	local var_34_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team_new/preset_item_2.csb")
	local var_34_4 = var_34_3:getChildByName("container")
	local var_34_5 = var_34_4:getContentSize()

	arg_34_1:setContentSize(var_34_5)
	var_34_3:addTo(arg_34_1)
	var_34_4:getChildByName("text_name"):setString(var_34_1)

	local var_34_6 = var_34_4:getChildByName("hero_list")
	local var_34_7 = 0
	local var_34_8 = 0

	for iter_34_0 = 1, #var_34_0 do
		local var_34_9 = var_34_0[iter_34_0]
		local var_34_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

		xyd.setAvatarBorderNewUI(var_34_9, var_34_10:getChildByName("avatar"))
		var_34_10:addTo(var_34_6)
		var_34_10:setPositionX(var_34_7)

		var_34_7 = var_34_7 + var_0_11 + 12

		local var_34_11 = var_34_10:getChildByName("chosen")

		var_34_11:setLocalZOrder(100)
		var_34_11:setVisible(false)

		local var_34_12 = var_34_10:getChildByName("avatar_mask")

		var_34_12:setLocalZOrder(2)
		var_34_12:setVisible(false)

		for iter_34_1 = 1, 3 do
			var_34_10:getChildByName("team" .. iter_34_1):setVisible(false)
		end

		local var_34_13 = var_34_10:getChildByName("lv_txt")

		var_34_13:setString(var_34_0[iter_34_0]:getLevel())
		var_34_10:getChildByName("name_text"):setString(var_34_0[iter_34_0]:getName())
		var_34_13:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_34_14 = var_34_10:getChildByName("hp_bar")
		local var_34_15 = var_34_10:getChildByName("mp_bar")

		var_34_10:getChildByName("yongbing_tubiao"):setVisible(false)
		var_34_14:hide()
		var_34_15:hide()
		var_34_10:getChildByName("hp_di"):hide()
		var_34_10:getChildByName("mp_di"):hide()

		if arg_34_0.type == xyd.SelectTeamType.ADVANCED and arg_34_0:isRecommend(var_34_9) then
			local var_34_16 = xyd.AssetLoader.get():loadSprite("windows/battle/select_team_new/icon_recommand.png")

			var_34_16:setAnchorPoint(cc.p(0.5, 1))
			var_34_16:setPosition(var_0_11 / 2, var_0_11)
			var_34_10:getChildByName("avatar"):addChild(var_34_16)
		elseif arg_34_0:checkHeroIsNotUse(var_34_9) then
			var_34_12:setVisible(true)

			local var_34_17 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

			var_34_17:setAnchorPoint(cc.p(0.5, 1))
			var_34_17:setPosition(var_0_11 / 2, var_0_11)
			var_34_10:getChildByName("avatar"):addChild(var_34_17, 11)
		end

		local var_34_18 = var_34_10:getChildByName("dead_text")

		var_34_18:setVisible(false)

		local var_34_19 = false

		if arg_34_0:checkHeroIsDead(var_34_9) then
			var_34_12:setVisible(true)
			var_34_18:setLocalZOrder(3)
			var_34_18:setVisible(true)
			var_34_18:setString(var_0_14:translation("ALREADY_DEAD"))
			var_34_18:enableOutline(cc.c4b(0, 0, 0), 2)

			var_34_19 = true
		end

		if arg_34_0.type == xyd.SelectTeamType.RAGNAROK and xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):checkHeroIsDead(var_34_9:getHeroID()) then
			var_34_12:setVisible(true)
			var_34_18:setLocalZOrder(3)
			var_34_18:setVisible(true)
			var_34_18:setString(var_0_14:translation("ALREADY_DEAD"))
			var_34_18:enableOutline(cc.c4b(0, 0, 0), 2)

			var_34_19 = true
		end

		var_34_9.isDead = var_34_19

		for iter_34_2, iter_34_3 in pairs(arg_34_0.busyHeros_) do
			if iter_34_3 == var_34_9:getHeroID() then
				var_34_12:setVisible(true)

				break
			end
		end

		if (arg_34_0.type == xyd.SelectTeamType.INCUBUS or arg_34_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_34_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER or arg_34_0.selectSpType == xyd.SelectSpType.BAN) and arg_34_0:isBanned(var_34_9) then
			local var_34_20 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_34_20:setAnchorPoint(cc.p(0.5, 1))
			var_34_20:setPosition(var_0_11 / 2, var_0_11)
			var_34_10:getChildByName("avatar"):addChild(var_34_20)
			var_34_12:setVisible(true)
		end

		if arg_34_0.type == xyd.SelectTeamType.DREAM_WORLD then
			local var_34_21 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD).coolTimeInfo.cooltime_heroes[tostring(var_34_9:getFirstTableID())]
			local var_34_22 = xyd.ServerTime.get():getServerTime()

			if var_34_21 and var_34_22 < var_34_21 then
				local var_34_23 = display.newNode()
				local var_34_24
				local var_34_25 = {
					size = 20,
					color = cc.c4b(255, 127, 127, 255),
					align = cc.ui.TEXT_ALIGN_CENTER,
					text = var_0_14:translation("BANED")
				}
				local var_34_26 = xyd.AssetLoader:get():loadLabel(var_34_25)

				var_34_26:setAnchorPoint(cc.p(0.5, 0.5))
				var_34_26:enableOutline(cc.c4b(49, 21, 21, 255), 2)
				var_34_26:setPosition(55, var_0_11 / 2 + 27)
				var_34_26:addTo(var_34_23)
				var_34_12:setVisible(true)

				local var_34_27 = xyd.AssetLoader.get():loadSprite("windows/dream_world/explore/time_mask_hero.png")

				var_34_27:addTo(var_34_23)
				var_34_27:setPosition(54, var_0_11 / 2)

				local var_34_28 = {
					size = 22,
					color = cc.c4b(255, 255, 255, 255)
				}
				local var_34_29 = xyd.AssetLoader:get():loadLabel(var_34_28)

				var_34_29:setName("time")
				var_34_29:setAnchorPoint(cc.p(0.5, 0.5))
				var_34_29:setString(xyd.secondsToString(var_34_21 - var_34_22))
				var_34_29:addTo(var_34_23)
				var_34_29:setPosition(57, var_0_11 / 2)

				var_34_23.coolTime = var_34_21

				var_34_23:addTo(var_34_10:getChildByName("avatar"), 99)

				var_34_23.layout = var_34_10:getChildByName("avatar")

				arg_34_0:addDreamWorldCoolTimeNode(var_34_23)
			end
		end

		var_34_8 = var_34_8 + var_34_0[iter_34_0]:getZhandouli()
	end

	if var_34_2 then
		xyd.setPetAvatarNewUI(var_34_4:getChildByName("pet"), var_34_2, 100)
		arg_34_0:initPetCellStatus(var_34_4:getChildByName("pet"), var_34_2, -20, -20)

		var_34_8 = var_34_8 + var_34_2:getZhandouli()
	end

	var_34_4:getChildByName("zhandouli"):setString(var_34_8)
	var_34_4:getChildByName("text_zhandouli"):setString(var_0_14:translation("TOTAL_FORCE") .. var_0_14:translation("COLON"))
	var_34_4:getChildByName("btn_use"):getChildByName("use"):setString(var_0_14:translation("SELECT_TEAM_TEXT_1"))
	var_34_4:getChildByName("btn_use"):addTouchEventListener(function(arg_35_0, arg_35_1)
		xyd.buttonScaleAnim(var_34_4:getChildByName("btn_use"), arg_35_1)

		if arg_35_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_34_0:checkPresetTeamCanUse(arg_34_2) then
				local var_35_0 = arg_34_0.selfPlayer:getSaveTeamStr()
				local var_35_1 = arg_34_0.selfPlayer:getSaveTeamIDs(var_35_0)

				arg_34_0.preSelect_ = var_35_1[arg_34_2]
				arg_34_0.preHeros_ = var_34_0
				arg_34_0.prePet_ = {
					var_34_2
				}

				arg_34_0:showPresetTeam(arg_34_2)
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_36_0)
	local var_36_0 = arg_36_0.team_
	local var_36_1 = arg_36_0.petTeam_

	arg_36_0.team_ = {}
	arg_36_0.petTeam_ = {}
	arg_36_0.select_ = {}
	arg_36_0.petSelect_ = {}

	arg_36_0:updateScore()
	arg_36_0:initPreHeros(true)
	arg_36_0:initPrePets(true)

	local var_36_2 = arg_36_0.team_
	local var_36_3 = arg_36_0.petTeam_
	local var_36_4 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_37_0 = 1, #var_36_0 do
				local var_37_0 = var_36_0[iter_37_0]
				local var_37_1, var_37_2 = arg_36_0:nodeByName("avatar" .. iter_37_0):getPosition()

				arg_36_0:moveFadeOutAction(var_37_1, var_37_2 - 13, var_37_0)

				if var_37_0.type == var_0_18.RENT_HERO then
					arg_36_0.isSelectMerHero = false
					arg_36_0.selectMerHero = nil
				end
			end

			for iter_37_1 = 1, #var_36_1 do
				local var_37_3 = var_36_1[iter_37_1]
				local var_37_4, var_37_5 = arg_36_0:nodeByName("avatar_pet" .. iter_37_1):getPosition()

				arg_36_0:moveFadeOutAction(var_37_4, var_37_5, var_37_3)
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_36_5 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_38_0 = 1, #var_36_2 do
				local var_38_0 = var_36_2[iter_38_0]

				var_38_0:show()

				local var_38_1, var_38_2 = arg_36_0:nodeByName("avatar" .. iter_38_0):getPosition()

				arg_36_0:moveFadeInAction(var_38_1, var_38_2 - 13, var_38_0)
			end

			for iter_38_1 = 1, #var_36_3 do
				local var_38_3 = var_36_3[iter_38_1]

				var_38_3:show()

				local var_38_4, var_38_5 = arg_36_0:nodeByName("avatar_pet" .. iter_38_1):getPosition()

				arg_36_0:moveFadeInAction(var_38_4, var_38_5, var_38_3)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_36_0:runAction(transition.sequence({
		var_36_4,
		var_36_5
	}))
end

function var_0_0.checkPresetTeamCanUse(arg_39_0, arg_39_1)
	local var_39_0 = arg_39_0.presetTeams[arg_39_1].team
	local var_39_1 = arg_39_0.presetTeams[arg_39_1].pet

	if arg_39_0.isAwakeCampaign then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_14:translation("PRESET_TEAM_NOT_USE")
		})

		return false
	elseif arg_39_0.type == xyd.SelectTeamType.CHALLENGE then
		local var_39_2 = var_0_15:modeType(arg_39_0.battleID)

		if var_39_2 == xyd.ChallengeType.OneHeroKillAll then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_14:translation("CHALLENGE_ONLY_ONE_HERO")
			})

			return false
		elseif var_39_2 == xyd.ChallengeType.Protect or var_39_2 == xyd.ChallengeType.KillSteal then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_14:translation("PRESET_TEAM_NOT_USE")
			})

			return false
		end
	end

	for iter_39_0 = 1, #var_39_0 do
		local var_39_3 = var_39_0[iter_39_0]

		if not arg_39_0:canHeroJoinBattle(var_39_3) or arg_39_0:checkHeroIsDead(var_39_3) or arg_39_0:checkBusyHero2(var_39_3) or arg_39_0.selectSpType == xyd.SelectSpType.BAN and arg_39_0:isBanned(var_39_3) or arg_39_0.type == xyd.SelectTeamType.INCUBUS and arg_39_0:isBanned(var_39_3) or arg_39_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER and arg_39_0:isBanned(var_39_3) or arg_39_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER and arg_39_0:isBanned(var_39_3) or arg_39_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_39_0:checkHeroIsConquerUsed(var_39_3) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_14:translation("PRESET_MEMBER_NOT_USE")
			})

			return false
		elseif arg_39_0.type == xyd.SelectTeamType.DREAM_WORLD then
			local var_39_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD).coolTimeInfo.cooltime_heroes[tostring(var_39_3:getFirstTableID())]
			local var_39_5 = xyd.ServerTime.get():getServerTime()

			if var_39_4 and var_39_5 < var_39_4 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_14:translation("PRESET_MEMBER_NOT_USE")
				})

				return false
			end
		elseif arg_39_0.type == xyd.SelectTeamType.RAGNAROK and var_39_3.isDead then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_14:translation("PRESET_MEMBER_NOT_USE")
			})

			return false
		end
	end

	if var_39_1 then
		if arg_39_0.type == xyd.SelectTeamType.DREAM_WORLD then
			local var_39_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD).coolTimeInfo.cooltime_pets[tostring(var_39_1:getTableID())]
			local var_39_7 = xyd.ServerTime.get():getServerTime()

			if var_39_6 and var_39_7 < var_39_6 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_14:translation("PRESET_PET_NOT_USE")
				})

				return false
			end
		elseif arg_39_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_39_0:checkPetIsConquerUsed(var_39_1) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_14:translation("PRESET_PET_NOT_USE")
			})

			return false
		end
	end

	return true
end

function var_0_0.checkHeroIsDead(arg_40_0, arg_40_1)
	local var_40_0
	local var_40_1 = false

	if arg_40_0.heroStatus_ then
		var_40_0 = arg_40_0.heroStatus_.self_list

		if arg_40_0.campaignType == xyd.CampaignType.TREASURE then
			var_40_0 = arg_40_0.heroStatus_
		end
	end

	if var_40_0 and next(var_40_0) ~= nil then
		local var_40_2 = var_40_0[tostring(arg_40_1:getHeroID())]

		if not var_40_2 or not var_40_2.health or var_40_2.health == 0 then
			-- block empty
		elseif var_40_2.health == 1 and var_40_2.hp >= 1 then
			-- block empty
		else
			var_40_1 = true
		end
	end

	return var_40_1
end

function var_0_0.clickPetAvatar(arg_41_0, arg_41_1, arg_41_2)
	if arg_41_1.isAnimated_ or not arg_41_1.teamNo_ and #arg_41_0.petTeam_ > xyd.MAX_PET_NUMBER then
		return
	elseif arg_41_1.type == var_0_20.RENT_PET and arg_41_0.isSelectMerHero then
		local var_41_0 = var_0_14:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_41_0
		})

		return
	elseif not arg_41_1.teamNo_ and #arg_41_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_41_1 = arg_41_0.petTeam_[1]

		arg_41_0:clickPetBottomAvatarWithoutAnimation(var_41_1, function()
			arg_41_0:clickPetAvatar(arg_41_1, arg_41_2)
		end)

		return
	end

	local var_41_2

	if arg_41_0.rentMenuType == var_0_19.RENT_PET then
		var_41_2 = arg_41_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_41_2 = arg_41_1:getChildByName("layout")
	end

	local var_41_3 = var_41_2:getChildByName("avatar_mask")
	local var_41_4 = var_41_2:getChildByName("chosen")
	local var_41_5 = arg_41_1:convertToWorldSpace(cc.p(0, 0))
	local var_41_6 = var_41_5.x
	local var_41_7 = var_41_5.y

	arg_41_1.isAnimated_ = true

	if arg_41_1.teamNo_ then
		local var_41_8 = arg_41_0.petTeam_[arg_41_1.teamNo_]

		arg_41_0:moveFadeOutAction(var_41_6, var_41_7, var_41_8, function()
			arg_41_1.isAnimated_ = false
		end)
		var_41_3:setVisible(false)
		var_41_4:setVisible(false)

		for iter_41_0 = #arg_41_0.petTeam_, arg_41_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_41_0.petTeam_[iter_41_0])

			local var_41_9, var_41_10 = arg_41_0:nodeByName("avatar_pet" .. iter_41_0 - 1):getPosition()

			transition.moveTo(arg_41_0.petTeam_[iter_41_0], {
				time = 0.3,
				x = var_41_9,
				y = var_41_10
			})

			arg_41_0.petTeam_[iter_41_0].iniCell_.teamNo_ = iter_41_0 - 1
		end

		if arg_41_1.type == var_0_20.RENT_PET then
			arg_41_0.isSelectMerPet = false
			arg_41_0.selectMerPet = nil
		end

		table.remove(arg_41_0.petTeam_, arg_41_1.teamNo_)
		table.remove(arg_41_0.petSelect_, arg_41_1.teamNo_)

		arg_41_1.teamNo_ = nil
	elseif not arg_41_1.teamNo_ and #arg_41_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_41_11 = arg_41_1.data

		if not arg_41_2 and var_0_16:chosenSound(var_41_11:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_41_11:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_16:chosenSound(var_41_11:getTableID()), false)
		end

		if arg_41_0.rentMenuType == var_0_19.RENT_PET and var_41_11.can_rent == false then
			arg_41_1.isAnimated_ = false

			return
		end

		local var_41_12 = arg_41_0:initPetBottomCell(var_41_11)

		var_41_12.iniCell_ = arg_41_1

		var_41_12:pos(var_41_6, var_41_7)
		var_41_12:addTo(arg_41_0)
		var_41_12:setTouchEnabled(true)
		var_41_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_45_0)
			if arg_45_0.name == "ended" then
				arg_41_0:clickPetBottomAvatar(var_41_12)
			end

			return true
		end)

		if arg_41_1.type == var_0_20.RENT_PET then
			arg_41_0.isSelectMerPet = true
			arg_41_0.selectMerPet = var_41_11
		end

		arg_41_1.teamNo_ = arg_41_0:getPetTeamNo(var_41_12)

		for iter_41_1 = arg_41_1.teamNo_, #arg_41_0.petTeam_ do
			local var_41_13, var_41_14 = arg_41_0:nodeByName("avatar_pet" .. iter_41_1):getPosition()

			if arg_41_2 then
				arg_41_0.petTeam_[iter_41_1]:pos(var_41_13, var_41_14)

				arg_41_1.isAnimated_ = false
			elseif iter_41_1 ~= arg_41_1.teamNo_ then
				local var_41_15 = arg_41_0.petTeam_[iter_41_1]

				transition.stopTarget(var_41_15)
				transition.moveTo(var_41_15, {
					time = 0.3,
					x = var_41_13,
					y = var_41_14,
					onComplete = function()
						var_41_15.iniCell_.isAnimated_ = false
						var_41_15.isAnimated_ = false
					end
				})
			else
				local var_41_16 = arg_41_0.petTeam_[iter_41_1]

				transition.stopTarget(var_41_16)

				var_41_12.isAnimated_ = true

				transition.moveTo(var_41_16, {
					time = 0.3,
					x = var_41_13,
					y = var_41_14,
					onComplete = function()
						arg_41_1.isAnimated_ = false
						var_41_12.isAnimated_ = false
					end
				})
			end

			arg_41_0.petTeam_[iter_41_1].iniCell_.teamNo_ = iter_41_1
		end

		var_41_3:setVisible(true)
		var_41_4:setVisible(true)
	end

	arg_41_0:updateScore()
end

function var_0_0.initHeroCell(arg_48_0, arg_48_1, arg_48_2)
	local var_48_0 = arg_48_0.totalHero_[arg_48_0.selectedHeroClass_[arg_48_0.leftMenuType_]][arg_48_0.collocationType_][arg_48_2]

	var_48_0.healthStatus = nil

	if arg_48_0.leftMenuType_ == var_0_18.RENT_HERO then
		local var_48_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/rent_hero_item.csb")

		var_48_1:setTouchSwallowEnabled(false)

		local var_48_2 = var_48_1:getChildByName("container")
		local var_48_3 = var_48_2:getChildByName("player_name")

		var_48_3:setString(var_48_0.player_name)

		arg_48_1.player_name = var_48_0.player_name
		arg_48_1.can_rent = var_48_0.can_rent
		arg_48_1.type = var_0_18.RENT_HERO

		local var_48_4 = var_48_2:getChildByName("rent_cost")

		var_48_4:setString(var_48_0.rent_need_mana or 0)

		if var_48_0.tutorInfo then
			var_48_0.rent_need_mana = var_48_0.tutorInfo.cost

			var_48_3:setString(var_0_14:translation("TUTOR_TEXT"))
			var_48_4:setString(var_48_0.tutorInfo.cost)
			var_48_3:setColor(cc.c3b(255, 240, 124))
		end

		var_48_2:getChildByName("yongbing_tubiao"):setVisible(true)
		var_48_2:getChildByName("is_can_rent"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_48_2:getChildByName("is_can_rent"):setString(var_0_14:translation("CAN_NOT_BORROW"))
		arg_48_1:setContentSize(var_48_1:getChildByName("container"):getContentSize())

		local var_48_5 = var_0_2.new({
			size = 139
		})

		var_48_5:addTo(var_48_2)
		var_48_5:setAnchorPoint(0, 0.5)
		var_48_5:setPosition(var_48_2:getChildByName("pos_splitline"):getPosition())
		xyd.setAvatarBorderNewUI(var_48_0, var_48_2:getChildByName("avatar"))

		local var_48_6 = var_48_2:getChildByName("chosen")

		var_48_6:setLocalZOrder(100)
		var_48_6:setVisible(false)

		local var_48_7 = var_48_2:getChildByName("avatar_mask")

		var_48_7:setLocalZOrder(2)
		var_48_7:setVisible(false)

		if var_48_0.can_rent then
			var_48_2:getChildByName("is_can_rent"):setVisible(false)
			var_48_7:setVisible(false)
		else
			var_48_2:getChildByName("is_can_rent"):setVisible(true)
			var_48_2:getChildByName("is_can_rent"):setColor(cc.c3b(255, 165, 159))
			var_48_2:getChildByName("is_can_rent"):enableOutline(cc.c4b(0, 0, 0, 105), 1)
			var_48_2:getChildByName("is_can_rent"):setLocalZOrder(100)
			var_48_7:setVisible(true)
		end

		if arg_48_0.type == xyd.SelectTeamType.ADVANCED and arg_48_0:isRecommend(var_48_0) then
			local var_48_8 = xyd.AssetLoader.get():loadSprite("windows/battle/select_team_new/icon_recommand.png")

			var_48_8:setAnchorPoint(cc.p(0.5, 1))
			var_48_8:setPosition(110, 186)
			var_48_2:addChild(var_48_8)
		end

		if arg_48_0.reinforcePartnerRatios[var_48_0:getTableID()] then
			local var_48_9 = xyd.AssetLoader.get():loadSprite("windows/common/attr_reinforcement.png")

			var_48_9:setAnchorPoint(cc.p(0, 0))

			local var_48_10 = arg_48_1:getContentSize()

			var_48_9:setPosition(var_48_10.width / 6, var_48_10.height - 40)
			var_48_2:addChild(var_48_9)

			local var_48_11 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 18,
				text = string.format("%3.f%%", arg_48_0.reinforcePartnerRatios[var_48_0:getTableID()] * 100),
				color = cc.c4b(0, 192, 255, 255),
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_48_11:setAnchorPoint(cc.p(0, 0))
			var_48_11:addTo(var_48_9)
			var_48_11:setPosition(24, 3)
		end

		local var_48_12 = var_48_2:getChildByName("lv_txt")

		var_48_12:setString(var_48_0:getLevel())
		var_48_2:getChildByName("name_txt"):setString(var_48_0:getName())
		var_48_12:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_48_13 = var_48_2:getChildByName("hp_bar")
		local var_48_14 = var_48_2:getChildByName("mp_bar")
		local var_48_15 = var_48_2:getChildByName("dead_txt")

		var_48_15:setString(var_0_14:translation("ALREADY_DEAD"))

		if var_48_15 then
			var_48_15:setVisible(false)
		end

		local var_48_16 = false
		local var_48_17

		if arg_48_0.heroStatus_ then
			var_48_17 = arg_48_0.heroStatus_.rent_list
		end

		if var_48_17 and var_48_17.health then
			local var_48_18 = var_48_17

			var_48_0.healthStatus = var_48_18

			if var_48_18 and var_48_18.health then
				local var_48_19 = 0
				local var_48_20 = 0

				if var_48_18.health == 0 then
					var_48_19 = 100
					var_48_20 = 0
				elseif var_48_18.health == 1 and var_48_18.hp >= 1 then
					var_48_19 = var_48_18.hp / (var_48_18.total_hp or var_48_0:getTotalAttr(xyd.AttributeType.HP)) * 100
					var_48_20 = var_48_18.mp / 10
				else
					var_48_19 = 0
					var_48_20 = 0

					var_48_7:setVisible(true)
					var_48_15:setLocalZOrder(3)
					var_48_15:setVisible(true)
					var_48_15:enableOutline(cc.c4b(0, 0, 0), 2)
					var_48_15:getVirtualRenderer():setAdditionalKerning(-2)

					var_48_16 = true
				end

				var_48_13:setPercent(var_48_19)
				var_48_13:setVisible(true)
				var_48_14:setPercent(var_48_20)
				var_48_14:setVisible(true)
			end
		elseif (not var_48_17 or not var_48_17.health) and arg_48_0.campaignType == xyd.CampaignType.MARCH then
			var_48_0.healthStatus = {}
			var_48_0.healthStatus.health = 0
			var_48_0.healthStatus.hp = 0
			var_48_0.healthStatus.mp = 0

			local var_48_21 = 100
			local var_48_22 = 0

			var_48_13:setPercent(var_48_21)
			var_48_13:setVisible(true)
			var_48_14:setPercent(var_48_22)
			var_48_14:setVisible(true)
		else
			var_48_13:hide()
			var_48_14:hide()
			var_48_2:getChildByName("hp_di"):hide()
			var_48_2:getChildByName("mp_di"):hide()
		end

		var_48_0.isDead = var_48_16

		var_48_2:setPosition(cc.p(0, 0))

		arg_48_1.data = var_48_0

		for iter_48_0, iter_48_1 in ipairs(arg_48_0.select_) do
			if iter_48_1:getFirstTableID() == var_48_0:getFirstTableID() then
				arg_48_1.teamNo_ = iter_48_0

				var_48_6:setVisible(true)
				var_48_7:setVisible(true)

				arg_48_0.team_[iter_48_0].iniCell_ = arg_48_1
				arg_48_0.team_[iter_48_0].iniCellVisible_ = false

				break
			end
		end

		arg_48_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_48_1:addChild(var_48_1)
		var_48_1:setName("yongbingCell")
		arg_48_1:setTouchSwallowEnabled(false)
		arg_48_1:setTouchEnabled(true)

		local var_48_23 = false

		for iter_48_2, iter_48_3 in pairs(arg_48_0.busyHeros_) do
			if iter_48_3 == var_48_0:getHeroID() then
				var_48_6:setVisible(true)
				var_48_7:setVisible(true)

				var_48_23 = true

				break
			end
		end

		if not var_48_23 then
			local var_48_24 = var_48_1:getChildByName("container"):getChildByName("yongbing_di")

			var_48_24:setTouchEnabled(true)
			var_48_24:setTouchSwallowEnabled(false)
			var_48_24:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_49_0)
				arg_48_0:buttonHandler(nil, arg_48_1, arg_49_0)

				if arg_49_0.name == "began" then
					arg_48_0.startClick_ = true
					arg_48_0.prevX_ = arg_49_0.x
					arg_48_0.prevY_ = arg_49_0.y
				elseif arg_49_0.name == "moved" then
					if math.abs(arg_49_0.y - arg_48_0.prevY_) > 5 or math.abs(arg_49_0.x - arg_48_0.prevX_) > 5 then
						arg_48_0.startClick_ = false
					end
				elseif arg_49_0.name == "ended" and arg_48_0.startClick_ then
					if var_48_16 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_14:translation("HERO_DIE_ERROR")
						})
					else
						local var_49_0 = xyd.StoryData.get():getGuideID()

						if var_49_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
							arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO1)
						elseif var_49_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
							arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO2)
						elseif var_49_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
							arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO3)
						end

						if arg_48_0.isAwakeCampaign and arg_48_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
							local function var_49_1()
								arg_48_0:clickAvatar(arg_48_1)
							end

							local var_49_2 = {
								txt = var_0_14:translation("AWAKE_SELECT_TEAM_TIP6"),
								type = xyd.CommonAlertType.TWO_BTN,
								align = xyd.ui_align.CENTER,
								rcallback = var_49_1
							}

							xyd.WindowManager.get():openWindow("common_alert", var_49_2)
						elseif arg_48_0.type == xyd.SelectTeamType.CHALLENGE and var_0_15:modeType(arg_48_0.battleID) == xyd.ChallengeType.OneHeroKillAll and #arg_48_0.team_ > 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_14:translation("CHALLENGE_ONLY_ONE_HERO")
							})
						else
							arg_48_0:clickAvatar(arg_48_1)
						end
					end
				end

				return true
			end)
		end
	else
		local var_48_25 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_list.csb")
		local var_48_26 = var_48_25:getChildByName("background"):getContentSize()

		var_48_25:setContentSize(var_48_26)
		arg_48_1:setContentSize(var_48_26)
		xyd.setAvatarBorderNewUI(var_48_0, var_48_25:getChildByName("avatar"))

		local var_48_27 = var_48_25:getChildByName("chosen")

		var_48_27:setLocalZOrder(100)
		var_48_27:setVisible(false)

		local var_48_28 = var_48_25:getChildByName("avatar_mask")

		var_48_28:setLocalZOrder(2)
		var_48_28:setVisible(false)

		arg_48_1.type = var_0_18.SELF_HERO

		if arg_48_0.type == xyd.SelectTeamType.ADVANCED and arg_48_0:isRecommend(var_48_0) then
			local var_48_29 = xyd.AssetLoader.get():loadSprite("windows/battle/select_team_new/icon_recommand.png")

			var_48_29:setAnchorPoint(cc.p(0, 0.5))
			var_48_29:setPosition(4, 80)
			var_48_25:addChild(var_48_29)
		elseif arg_48_0.type == xyd.SelectTeamType.CAMPAIGN and arg_48_0:isRecommend(var_48_0) and arg_48_0.ispreperation then
			local var_48_30 = xyd.AssetLoader.get():loadSprite("windows/battle/select_team_new/icon_recommand.png")

			var_48_30:setAnchorPoint(cc.p(0, 0.5))
			var_48_30:setPosition(4, 80)
			var_48_25:addChild(var_48_30)
		elseif arg_48_0:checkHeroIsNotUse(var_48_0) then
			var_48_28:setVisible(true)

			local var_48_31 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

			var_48_31:setPosition(85, 120)
			var_48_25:addChild(var_48_31, 11)
		end

		local var_48_32 = var_48_25:getChildByName("lv_txt")

		var_48_32:setString(var_48_0:getLevel())
		var_48_25:getChildByName("name_text"):setString(var_48_0:getName())
		var_48_32:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_48_33 = false
		local var_48_34

		if arg_48_0.heroStatus_ then
			var_48_34 = arg_48_0.heroStatus_.self_list

			if arg_48_0.campaignType == xyd.CampaignType.TREASURE then
				var_48_34 = arg_48_0.heroStatus_
			end
		end

		if var_48_34 and next(var_48_34) ~= nil then
			local var_48_35 = var_48_34[tostring(var_48_0:getHeroID())]

			var_48_0.healthStatus = var_48_35

			if var_48_35 and var_48_35.health then
				local var_48_36 = xyd.AssetLoader.get():loadSprite("windows/common_new/energy-di.png")
				local var_48_37 = xyd.AssetLoader.get():loadSprite("windows/common_new/energy-di.png")

				var_48_36:addTo(var_48_25)
				var_48_37:addTo(var_48_25)
				var_48_36:setAnchorPoint(cc.p(0.5, 0.5))
				var_48_37:setAnchorPoint(cc.p(0.5, 0.5))
				var_48_36:setPosition(53, 117)
				var_48_37:setPosition(53, 103)
				var_48_36:setLocalZOrder(1)
				var_48_37:setLocalZOrder(1)

				local var_48_38 = cc.ProgressTimer:create(cc.Sprite:create("windows/common_new/lv.png"))

				var_48_38:addTo(var_48_25)
				var_48_38:setType(1)
				var_48_38:setAnchorPoint(cc.p(0.5, 0.5))
				var_48_38:setPosition(var_48_36:getPosition())
				var_48_38:setLocalZOrder(1)
				var_48_38:setMidpoint(cc.p(0, 0))
				var_48_38:setBarChangeRate(cc.p(1, 0))
				var_48_38:setName("hp_bar")

				local var_48_39 = cc.ProgressTimer:create(cc.Sprite:create("windows/common_new/energy.png"))

				var_48_39:addTo(var_48_25)
				var_48_39:setType(1)
				var_48_39:setAnchorPoint(cc.p(0.5, 0.5))
				var_48_39:setPosition(var_48_37:getPosition())
				var_48_39:setLocalZOrder(1)
				var_48_39:setMidpoint(cc.p(0, 0))
				var_48_39:setBarChangeRate(cc.p(1, 0))
				var_48_39:setName("mp_bar")

				local var_48_40 = 0
				local var_48_41 = 0

				if var_48_35.health == 0 then
					var_48_40 = 100
					var_48_41 = 0
				elseif var_48_35.health == 1 and var_48_35.hp >= 1 then
					var_48_40 = var_48_35.hp / (var_48_35.total_hp or var_48_0:getTotalAttr(xyd.AttributeType.HP)) * 100
					var_48_41 = var_48_35.mp / 10
				else
					var_48_40 = 0
					var_48_41 = 0

					var_48_28:setVisible(true)

					local var_48_42 = display.newTTFLabel({
						font = "fonts/main_font.ttf",
						size = 22,
						text = var_0_14:translation("ALREADY_DEAD"),
						color = cc.c4b(206, 109, 109, 255),
						align = cc.TEXT_ALIGNMENT_LEFT
					})

					var_48_42:setAnchorPoint(cc.p(0, 0))
					var_48_42:addTo(var_48_25)
					var_48_42:setPosition(17, 82)
					var_48_42:setLocalZOrder(3)

					var_48_33 = true
				end

				var_48_38:setPercentage(var_48_40)
				var_48_38:setVisible(true)
				var_48_39:setPercentage(var_48_41)
				var_48_39:setVisible(true)
			end
		end

		if arg_48_0.type == xyd.SelectTeamType.RAGNAROK and xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):checkHeroIsDead(var_48_0:getHeroID()) then
			var_48_28:setVisible(true)

			local var_48_43 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 26,
				text = var_0_14:translation("ALREADY_DEAD"),
				color = cc.c4b(206, 109, 109, 255),
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_48_43:setAnchorPoint(cc.p(0, 0))
			var_48_43:addTo(var_48_25)
			var_48_43:setPosition(17, 82)
			var_48_43:setLocalZOrder(3)

			var_48_33 = true
		end

		var_48_25:setName("layout")
		var_48_25:setPosition(cc.p(0, 0))

		if arg_48_0.reinforcePartnerRatios[var_48_0:getTableID()] then
			local var_48_44 = xyd.AssetLoader.get():loadSprite("windows/common/attr_reinforcement.png")

			var_48_44:setAnchorPoint(cc.p(0, 0))

			local var_48_45 = arg_48_1:getContentSize()

			var_48_44:setPosition(var_48_45.width / 6, var_48_45.height - 40)
			var_48_25:addChild(var_48_44)

			local var_48_46 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 18,
				text = string.format("%3.f%%", arg_48_0.reinforcePartnerRatios[var_48_0:getTableID()] * 100),
				color = cc.c4b(0, 192, 255, 255),
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_48_46:setAnchorPoint(cc.p(0, 0))
			var_48_46:addTo(var_48_44)
			var_48_46:setPosition(24, 3)
		end

		arg_48_1.data = var_48_0

		for iter_48_4, iter_48_5 in ipairs(arg_48_0.select_) do
			if iter_48_5:getTableID() == var_48_0:getTableID() and iter_48_5.player_name == var_48_0.player_name then
				arg_48_1.teamNo_ = iter_48_4

				var_48_27:setVisible(true)
				var_48_28:setVisible(true)

				arg_48_0.team_[iter_48_4].iniCell_ = arg_48_1
				arg_48_0.team_[iter_48_4].iniCellVisible_ = false

				break
			end
		end

		var_48_0.isDead = var_48_33

		arg_48_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_48_1:addChild(var_48_25)
		arg_48_1:setTouchSwallowEnabled(false)
		arg_48_1:setTouchEnabled(true)

		local var_48_47 = false

		for iter_48_6, iter_48_7 in pairs(arg_48_0.busyHeros_) do
			if iter_48_7 == var_48_0:getHeroID() then
				var_48_27:setVisible(true)
				var_48_28:setVisible(true)

				var_48_47 = true

				break
			end
		end

		if arg_48_0.type == xyd.SelectTeamType.DREAM_WORLD then
			local var_48_48 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD).coolTimeInfo.cooltime_heroes[tostring(var_48_0:getFirstTableID())]
			local var_48_49 = xyd.ServerTime.get():getServerTime()

			if var_48_48 and var_48_49 < var_48_48 then
				local var_48_50 = display.newNode()
				local var_48_51
				local var_48_52 = {
					size = 20,
					color = cc.c4b(255, 127, 127, 255),
					align = cc.ui.TEXT_ALIGN_CENTER,
					text = var_0_14:translation("BANED")
				}
				local var_48_53 = xyd.AssetLoader:get():loadLabel(var_48_52)

				var_48_53:setAnchorPoint(cc.p(0.5, 0.5))
				var_48_53:enableOutline(cc.c4b(49, 21, 21, 255), 2)
				var_48_53:setPosition(55, 105)
				var_48_53:addTo(var_48_50)
				var_48_28:setVisible(true)

				local var_48_54 = xyd.AssetLoader.get():loadSprite("windows/dream_world/explore/time_mask_hero.png")

				var_48_54:addTo(var_48_50)
				var_48_54:setPosition(54, 80)

				local var_48_55 = {
					size = 22,
					color = cc.c4b(255, 255, 255, 255)
				}
				local var_48_56 = xyd.AssetLoader:get():loadLabel(var_48_55)

				var_48_56:setName("time")
				var_48_56:setAnchorPoint(cc.p(0.5, 0.5))
				var_48_56:setString(xyd.secondsToString(var_48_48 - var_48_49))
				var_48_56:addTo(var_48_50)
				var_48_56:setPosition(57, 80)

				var_48_50.coolTime = var_48_48
				var_48_50.tableID = var_48_0:getFirstTableID()

				var_48_50:addTo(var_48_25, 99)

				var_48_50.layout = var_48_25

				arg_48_0:addDreamWorldCoolTimeNode(var_48_50)
			end
		end

		if (arg_48_0.type == xyd.SelectTeamType.INCUBUS or arg_48_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER or arg_48_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_48_0.selectSpType == xyd.SelectSpType.BAN) and arg_48_0:isBanned(var_48_0) then
			local var_48_57 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_48_57:setAnchorPoint(cc.p(0.5, 1))
			var_48_57:setPosition(80, 135)
			var_48_25:addChild(var_48_57)
			var_48_28:setVisible(true)
		elseif not var_48_47 then
			arg_48_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_51_0)
				arg_48_0:buttonHandler(nil, arg_48_1, arg_51_0)

				if arg_51_0.name == "began" then
					arg_48_0.startClick_ = true
					arg_48_0.prevX_ = arg_51_0.x
					arg_48_0.prevY_ = arg_51_0.y
				elseif arg_51_0.name == "moved" then
					if math.abs(arg_51_0.y - arg_48_0.prevY_) > 5 or math.abs(arg_51_0.x - arg_48_0.prevX_) > 5 then
						arg_48_0.startClick_ = false
					end
				elseif arg_51_0.name == "ended" and arg_48_0.startClick_ then
					if var_48_33 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_14:translation("HERO_DIE_ERROR")
						})
					else
						local var_51_0 = xyd.StoryData.get():getGuideID()

						if var_51_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
							arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO1)
						elseif var_51_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
							arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO2)
						elseif var_51_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
							arg_48_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO3)
						end

						if arg_48_0.isAwakeCampaign and arg_48_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL and var_48_0:getTableID() ~= arg_48_0.awakeHero:getTableID() then
							local function var_51_1()
								arg_48_0:clickAvatar(arg_48_1)
							end

							local var_51_2 = {
								txt = var_0_14:translation("AWAKE_SELECT_TEAM_TIP6"),
								type = xyd.CommonAlertType.TWO_BTN,
								rcallback = var_51_1,
								align = xyd.ui_align.CENTER
							}

							xyd.WindowManager.get():openWindow("common_alert", var_51_2)
						elseif arg_48_0.type == xyd.SelectTeamType.CHALLENGE and var_0_15:modeType(arg_48_0.battleID) == xyd.ChallengeType.OneHeroKillAll and #arg_48_0.team_ > 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_14:translation("CHALLENGE_ONLY_ONE_HERO")
							})
						elseif arg_48_0.type == xyd.SelectTeamType.DREAM_WORLD then
							local var_51_3 = var_48_0:getFirstTableID()

							if arg_48_0:checkDreamWorldCoolTime(var_51_3) then
								local var_51_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)

								if var_51_4.mapType == xyd.DreamWorldType.CHALLENGE then
									local function var_51_5()
										local var_53_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

										if xyd.tables.misc:getValue("dreamworld_hard_battle_partner_crystal") > var_53_0.crystal then
											local function var_53_1()
												local var_54_0 = {}

												var_54_0.windowState = true

												xyd.WindowManager.get():openWindow("vip_recharge", var_54_0)
											end

											local var_53_2 = {
												rcallBefore = 0,
												txt = var_0_14:translation("ZUANSHI_ABSENCE"),
												rcallback = var_53_1,
												align = xyd.ui_align.CENTER
											}

											xyd.WindowManager.get():openWindow("common_alert", var_53_2)
										else
											local var_53_3 = {
												heroes = {
													var_51_3
												}
											}

											var_51_4:resetCoolTime(var_53_3, function(arg_55_0, arg_55_1)
												if arg_55_0 == xyd.error.OK then
													arg_48_0:clearDreamWorldCoolTimeNode(var_51_3)
												end
											end)
										end
									end

									local var_51_6 = {
										rcallBefore = 0,
										txt = var_0_14:translation("DREAM_WORLD_TEXT_11"),
										rcallback = var_51_5,
										align = xyd.ui_align.CENTER
									}

									xyd.WindowManager.get():openWindow("common_alert", var_51_6)
								end
							else
								arg_48_0:clickAvatar(arg_48_1)
							end
						elseif arg_48_0:checkHeroIsNotUse(var_48_0) then
							return
						else
							arg_48_0:clickAvatar(arg_48_1)
						end
					end
				end

				return true
			end)
		end
	end
end

function var_0_0.initBottomCell(arg_56_0, arg_56_1)
	local var_56_0 = display.newNode()
	local var_56_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")
	local var_56_2 = var_56_1:getChildByName("background"):getContentSize()

	var_56_1:setContentSize(var_56_2)
	var_56_0:setContentSize(var_56_2)
	xyd.setAvatarBorderNewUI(arg_56_1, var_56_1:getChildByName("avatar"))

	local var_56_3 = var_56_1:getChildByName("chosen")

	var_56_3:setLocalZOrder(100)
	var_56_3:setVisible(false)

	local var_56_4 = var_56_1:getChildByName("avatar_mask")

	var_56_4:setLocalZOrder(2)
	var_56_4:setVisible(false)

	local var_56_5 = var_56_1:getChildByName("yongbing_tubiao")

	if arg_56_0.leftMenuType_ == var_0_18.RENT_HERO or arg_56_1.type == var_0_18.RENT_HERO then
		var_56_5:setVisible(true)

		var_56_0.type = var_0_18.RENT_HERO
	else
		var_56_5:setVisible(false)

		var_56_0.type = var_0_18.SELF_HERO
	end

	if arg_56_1.isAssist and arg_56_0.campaignType == xyd.CampaignType.NORMAL then
		local var_56_6 = xyd.AssetLoader.get():loadSprite("windows/battle/text_assist.png")

		var_56_6:addTo(var_56_0)
		var_56_6:setAnchorPoint(cc.p(1, 1))
		var_56_6:setPosition(cc.p(var_56_2.width, var_56_2.height))
		var_56_6:setLocalZOrder(99)

		arg_56_0.assistHeroNode = var_56_0

		var_56_0:setVisible(false)
	end

	for iter_56_0 = 1, 3 do
		var_56_1:getChildByName("team" .. iter_56_0):setVisible(false)
	end

	local var_56_7 = var_56_1:getChildByName("lv_txt")

	var_56_7:setString(arg_56_1:getLevel())
	var_56_1:getChildByName("name_text"):setString(arg_56_1:getName())
	var_56_7:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_56_8 = var_56_1:getChildByName("hp_bar")
	local var_56_9 = var_56_1:getChildByName("mp_bar")
	local var_56_10 = var_56_1:getChildByName("dead_text")

	if var_56_10 then
		var_56_10:setVisible(false)
	end

	local var_56_11 = false

	if arg_56_0.heroStatus_ then
		if var_56_0.type == var_0_18.RENT_HERO then
			local var_56_12 = arg_56_0.heroStatus_.rent_list

			if var_56_12 and var_56_12.health then
				local var_56_13 = var_56_12

				arg_56_1.healthStatus = var_56_13

				if var_56_13 and var_56_13.health then
					local var_56_14 = 0
					local var_56_15 = 0

					if var_56_13.health == 0 then
						var_56_14 = 100
						var_56_15 = 0
					elseif var_56_13.health == 1 then
						var_56_14 = var_56_13.hp / (var_56_13.total_hp or arg_56_1:getTotalAttr(xyd.AttributeType.HP)) * 100
						var_56_15 = var_56_13.mp / 10
					else
						var_56_14 = 0
						var_56_15 = 0

						var_56_4:setVisible(true)
						var_56_10:setLocalZOrder(3)
						var_56_10:setVisible(true)
						var_56_10:enableOutline(cc.c4b(0, 0, 0), 2)
						var_56_10:getVirtualRenderer():setAdditionalKerning(-2)

						local var_56_16 = true
					end

					var_56_8:setPercent(var_56_14)
					var_56_8:setVisible(true)
					var_56_9:setPercent(var_56_15)
					var_56_9:setVisible(true)
				end
			elseif (not var_56_12 or not var_56_12.health) and arg_56_0.campaignType == xyd.CampaignType.MARCH then
				arg_56_1.healthStatus = {}
				arg_56_1.healthStatus.health = 0
				arg_56_1.healthStatus.mp = 0
				arg_56_1.healthStatus.hp = 0

				local var_56_17 = 100
				local var_56_18 = 0

				var_56_8:setPercent(var_56_17)
				var_56_8:setVisible(true)
				var_56_9:setPercent(var_56_18)
				var_56_9:setVisible(true)
			else
				var_56_8:hide()
				var_56_9:hide()
				var_56_1:getChildByName("hp_di"):hide()
				var_56_1:getChildByName("mp_di"):hide()
			end
		else
			local var_56_19 = arg_56_0.heroStatus_.self_list

			if arg_56_0.campaignType == xyd.CampaignType.TREASURE then
				var_56_19 = arg_56_0.heroStatus_
			end

			if var_56_19 and next(var_56_19) then
				local var_56_20 = var_56_19[tostring(arg_56_1:getHeroID())]

				arg_56_1.healthStatus = var_56_20

				if var_56_20 and var_56_20.health then
					local var_56_21 = 0
					local var_56_22 = 0

					if var_56_20.health == 0 then
						var_56_21 = 100
						var_56_22 = 0
					elseif var_56_20.health == 1 then
						var_56_21 = var_56_20.hp / (var_56_20.total_hp or arg_56_1:getTotalAttr(xyd.AttributeType.HP)) * 100
						var_56_22 = var_56_20.mp / 10
					else
						var_56_21 = 0
						var_56_22 = 0

						var_56_4:setVisible(true)
						var_56_10:setLocalZOrder(3)
						var_56_10:setVisible(true)
						var_56_10:enableOutline(cc.c4b(0, 0, 0), 2)
						var_56_10:getVirtualRenderer():setAdditionalKerning(-2)

						local var_56_23 = true
					end

					var_56_8:setPercent(var_56_21)
					var_56_8:setVisible(true)
					var_56_9:setPercent(var_56_22)
					var_56_9:setVisible(true)
				end
			else
				var_56_8:hide()
				var_56_9:hide()
				var_56_1:getChildByName("hp_di"):hide()
				var_56_1:getChildByName("mp_di"):hide()
			end
		end
	else
		var_56_8:hide()
		var_56_9:hide()
		var_56_1:getChildByName("hp_di"):hide()
		var_56_1:getChildByName("mp_di"):hide()
	end

	var_56_1:setName("layout")

	var_56_0.data = arg_56_1

	var_56_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_56_0:addChild(var_56_1)

	return var_56_0
end

function var_0_0.initPetBottomCell(arg_57_0, arg_57_1)
	local var_57_0 = display.newNode()

	var_57_0:size(146, 146)
	var_57_0:align(display.CENTER)

	var_57_0.data = arg_57_1
	var_57_0.type = var_0_20.SELF_PET

	xyd.setPetAvatarNewUI(var_57_0, arg_57_1, 100)

	if arg_57_0.rentMenuType == var_0_19.RENT_PET then
		local var_57_1 = xyd.AssetLoader.get():loadSprite("windows/cloud_city/yongbing_tubiao.png")

		var_57_1:addTo(var_57_0)
		var_57_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_57_1:setPosition(cc.p(110, 120))

		var_57_0.type = var_0_20.RENT_PET
	end

	return var_57_0
end

function var_0_0.delegate(arg_58_0, ...)
	if arg_58_0.isHeroPreset then
		return arg_58_0:presetDelegate(...)
	elseif arg_58_0.leftMenuType_ == var_0_18.SELF_PET or arg_58_0.leftMenuType_ == var_0_18.RENT_HERO and arg_58_0.rentMenuType == var_0_19.RENT_PET then
		return arg_58_0:petDelegate(...)
	end

	return arg_58_0:heroDelegate(...)
end

function var_0_0.petDelegate(arg_59_0, arg_59_1, arg_59_2, arg_59_3)
	if arg_59_0.leftMenuType_ == var_0_18.SELF_PET then
		var_0_7 = 6
	else
		var_0_7 = 5
	end

	local var_59_0 = math.ceil(#arg_59_0.totalPet_ / var_0_7)

	if cc.ui.UIListView.COUNT_TAG == arg_59_2 then
		return var_59_0
	elseif cc.ui.UIListView.CELL_TAG == arg_59_2 then
		local var_59_1
		local var_59_2
		local var_59_3
		local var_59_4 = arg_59_0.heroList_:dequeueItem()

		if not var_59_4 then
			var_59_4 = arg_59_0.heroList_:newItem()
		else
			var_59_4:removeAllChildren()
		end

		local var_59_5 = display.newNode()

		var_59_5:setTouchSwallowEnabled(false)

		for iter_59_0 = 1, var_0_7 do
			local var_59_6 = (arg_59_3 - 1) * var_0_7 + iter_59_0

			if var_59_6 > #arg_59_0.totalPet_ then
				break
			end

			var_59_3 = display.newNode()

			arg_59_0:initPetCell(var_59_3, var_59_6)

			local var_59_7 = var_59_3:getContentSize().width
			local var_59_8 = var_59_3:getContentSize().height
			local var_59_9 = (arg_59_0.heroList_.viewRect_.width - var_59_7 * var_0_7) / (var_0_7 + 1)

			var_59_3:align(display.CENTER, var_59_9 * iter_59_0 + (iter_59_0 - 1) * var_59_7 + var_59_7 / 2, var_59_8 / 2)
			var_59_5:addChild(var_59_3)
		end

		var_59_5:setContentSize(cc.size(arg_59_0.heroList_.viewRect_.width, var_59_3:getContentSize().height))
		var_59_4:setItemSize(arg_59_0.heroList_.viewRect_.width, var_59_3:getContentSize().height)
		var_59_4:addContent(var_59_5)

		return var_59_4
	end
end

function var_0_0.presetDelegate(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	local var_60_0 = #arg_60_0.presetTeams

	if cc.ui.UIListView.COUNT_TAG == arg_60_2 then
		return var_60_0
	elseif cc.ui.UIListView.CELL_TAG == arg_60_2 then
		local var_60_1
		local var_60_2
		local var_60_3
		local var_60_4 = arg_60_0.heroList_:dequeueItem()

		if not var_60_4 then
			var_60_4 = arg_60_0.heroList_:newItem()
		else
			var_60_4:removeAllChildren()
		end

		local var_60_5 = display.newNode()

		var_60_5:setTouchSwallowEnabled(false)

		local var_60_6 = display.newNode()

		arg_60_0:initPresetCell(var_60_6, arg_60_3)
		var_60_5:addChild(var_60_6)
		var_60_5:setContentSize(cc.size(arg_60_0.heroList_.viewRect_.width, var_60_6:getContentSize().height))
		var_60_4:setItemSize(arg_60_0.heroList_.viewRect_.width, var_60_6:getContentSize().height)
		var_60_4:addContent(var_60_5)

		return var_60_4
	end
end

function var_0_0.heroDelegate(arg_61_0, arg_61_1, arg_61_2, arg_61_3)
	if arg_61_0.leftMenuType_ == var_0_18.SELF_HERO then
		var_0_6 = 7
	else
		var_0_6 = 5
	end

	local var_61_0 = math.ceil(#arg_61_0.totalHero_[arg_61_0.selectedHeroClass_[arg_61_0.leftMenuType_]][arg_61_0.collocationType_] / var_0_6)

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

		for iter_61_0 = 1, var_0_6 do
			local var_61_6 = (arg_61_3 - 1) * var_0_6 + iter_61_0

			if var_61_6 > #arg_61_0.totalHero_[arg_61_0.selectedHeroClass_[arg_61_0.leftMenuType_]][arg_61_0.collocationType_] then
				break
			end

			var_61_3 = display.newNode()

			arg_61_0:initHeroCell(var_61_3, var_61_6)

			local var_61_7 = var_61_3:getContentSize().width
			local var_61_8 = var_61_3:getContentSize().height
			local var_61_9 = (arg_61_0.heroList_.viewRect_.width - var_61_7 * var_0_6) / (var_0_6 + 1)

			var_61_3:pos(var_61_9 * iter_61_0 + (iter_61_0 - 1) * var_61_7 + var_61_7 / 2, var_0_5 + var_61_8 / 2 - 6)
			var_61_5:addChild(var_61_3)

			arg_61_0.heroCells_[var_61_6] = var_61_3
		end

		var_61_5:setContentSize(cc.size(arg_61_0.heroList_.viewRect_.width, var_61_3:getContentSize().height + var_0_5))
		var_61_4:setItemSize(arg_61_0.heroList_.viewRect_.width, var_61_3:getContentSize().height + var_0_5)
		var_61_4:addContent(var_61_5)

		return var_61_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_62_0)
	for iter_62_0 = 1, #arg_62_0.rightMenuButtons_ do
		if iter_62_0 == arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] then
			arg_62_0.rightMenuButtons_[iter_62_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_62_0.rightMenuButtons_[iter_62_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_62_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.normal)
	arg_62_0.heroList_:removeAllItems()

	if arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_62_1, iter_62_2 in ipairs(arg_62_0.select_) do
			if iter_62_2:getDistanceType() ~= arg_62_0.selectedHeroClass_[arg_62_0.leftMenuType_] then
				arg_62_0.team_[iter_62_1].iniCellVisible_ = true
			end
		end
	end

	arg_62_0:initPreHeros()
	arg_62_0:initPrePets()
	arg_62_0.heroList_:reload()
	arg_62_0:checkHeroIcon()
end

function var_0_0.buttonHandler(arg_63_0, arg_63_1, arg_63_2, arg_63_3)
	if not arg_63_2 or not arg_63_2:getParent() then
		return
	end

	if arg_63_3.name == "ended" then
		transition.stopTarget(arg_63_2)
		arg_63_2:setScale(1)

		if arg_63_1 then
			arg_63_1(arg_63_2, eventType)
		end
	elseif arg_63_3.name == "began" then
		local var_63_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_63_2:runAction(var_63_0)

		return true
	elseif arg_63_3.name == "cancled" then
		transition.stopTarget(arg_63_2)
		arg_63_2:setScale(1)
	end
end

function var_0_0.initPrePets(arg_64_0, arg_64_1)
	if not arg_64_0:isPet() or arg_64_0.isAwakeCampaign then
		return
	end

	for iter_64_0, iter_64_1 in ipairs(arg_64_0.prePet_) do
		local var_64_0, var_64_1 = arg_64_0:nodeByName("avatar_pet" .. iter_64_0):getPosition()
		local var_64_2 = arg_64_0:initPetBottomCell(iter_64_1)

		var_64_2:pos(var_64_0, var_64_1)
		var_64_2:addTo(arg_64_0)
		var_64_2:setTouchEnabled(true)
		var_64_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_65_0)
			if arg_65_0.name == "ended" then
				arg_64_0:clickPetBottomAvatar(var_64_2)
			end

			return true
		end)
		arg_64_0:getPetTeamNo(var_64_2)

		if arg_64_1 then
			var_64_2:hide()
		end
	end

	arg_64_0:updateScore()

	arg_64_0.prePet_ = {}
end

function var_0_0.initPreHeros(arg_66_0, arg_66_1)
	if arg_66_0.preSelect_ and arg_66_0.preHeros_ then
		for iter_66_0, iter_66_1 in pairs(arg_66_0.preHeros_) do
			if iter_66_1.type == var_0_18.RENT_HERO then
				if not iter_66_1.can_rent or iter_66_1.isDead or arg_66_0.isSelectMerHero or not arg_66_0:checkHeroValid(iter_66_1) then
					return
				end

				local var_66_0 = iter_66_1.rent_need_mana

				if var_66_0 and var_66_0 > arg_66_0.selfPlayer.mana and not iter_66_1.have_rent then
					return
				end

				local var_66_1 = false

				if arg_66_0.heroStatus_ then
					local var_66_2 = arg_66_0.heroStatus_.rent_list

					iter_66_1.healthStatus = var_66_2

					if var_66_2 and var_66_2.health then
						local var_66_3 = 0
						local var_66_4 = 0

						if var_66_2.health == 0 then
							local var_66_5 = 100
							local var_66_6 = 0
						elseif var_66_2.health == 1 and var_66_2.hp >= 1 then
							local var_66_7 = var_66_2.hp / (var_66_2.total_hp or iter_66_1:getTotalAttr(xyd.AttributeType.HP)) * 100
							local var_66_8 = var_66_2.mp / 10
						else
							local var_66_9 = 0
							local var_66_10 = 0

							var_66_1 = true
						end
					end
				end

				if not var_66_1 then
					local var_66_11 = arg_66_0:initBottomCell(iter_66_1)

					var_66_11.iniCellVisible_ = true
					var_66_11.iniCell_ = display.newNode()

					var_66_11:addTo(arg_66_0)
					var_66_11:setTouchEnabled(true)
					var_66_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_67_0)
						if arg_67_0.name == "ended" then
							if (iter_66_1.isChallengeKillSteal_ or iter_66_1.isChallengeProtected_) and arg_66_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_15:modeType(arg_66_0.battleID) == xyd.ChallengeType.KillSteal or var_0_15:modeType(arg_66_0.battleID) == xyd.ChallengeType.Protect) then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_14:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
								})
							else
								arg_66_0:clickBottomAvatar(var_66_11)
							end
						end

						return true
					end)

					if iter_66_1.type == var_0_18.RENT_HERO then
						arg_66_0.isSelectMerHero = true
						arg_66_0.selectMerHero = var_66_11.data
					end

					for iter_66_2 = arg_66_0:getTeamNo(var_66_11), #arg_66_0.team_ do
						local var_66_12, var_66_13 = arg_66_0:nodeByName("avatar" .. iter_66_2):getPosition()

						arg_66_0.team_[iter_66_2]:pos(var_66_12, var_66_13 - 13)

						if arg_66_0.team_[iter_66_2].iniCell_ then
							arg_66_0.team_[iter_66_2].iniCell_.teamNo_ = iter_66_2
						end
					end
				end
			elseif arg_66_0.selectSpType ~= 0 and not arg_66_0:canHeroJoinBattle(iter_66_1) then
				-- block empty
			else
				if (arg_66_0.campaignType == xyd.CampaignType.MARCH or arg_66_0.campaignType == xyd.CampaignType.TREASURE) and iter_66_1.isDead or not arg_66_0:checkHeroValid(iter_66_1) then
					return
				end

				local var_66_14 = false

				if arg_66_0.heroStatus_ then
					local var_66_15 = arg_66_0.heroStatus_.self_list

					if arg_66_0.campaignType == xyd.CampaignType.TREASURE then
						var_66_15 = arg_66_0.heroStatus_
					end

					local var_66_16 = var_66_15[tostring(iter_66_1:getHeroID())]

					iter_66_1.healthStatus = var_66_16

					if var_66_16 and var_66_16.health then
						local var_66_17 = 0
						local var_66_18 = 0

						if var_66_16.health == 0 then
							local var_66_19 = 100
							local var_66_20 = 0
						elseif var_66_16.health == 1 and var_66_16.hp >= 1 then
							local var_66_21 = var_66_16.hp / (var_66_16.total_hp or iter_66_1:getTotalAttr(xyd.AttributeType.HP)) * 100
							local var_66_22 = var_66_16.mp / 10
						else
							local var_66_23 = 0
							local var_66_24 = 0

							var_66_14 = true
						end
					end
				end

				local var_66_25

				if arg_66_0.campaignType == xyd.CampaignType.MEMORIES_OF_SCHOOL then
					var_66_25 = arg_66_0:isBanned(iter_66_1)
				end

				if not var_66_14 and not var_66_25 then
					local var_66_26 = arg_66_0:initBottomCell(iter_66_1)

					if arg_66_1 then
						var_66_26:hide()
					end

					var_66_26.iniCellVisible_ = true
					var_66_26.iniCell_ = display.newNode()

					var_66_26:addTo(arg_66_0)
					var_66_26:setTouchEnabled(true)
					var_66_26:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_68_0)
						if arg_68_0.name == "ended" then
							local function var_68_0()
								arg_66_0:clickBottomAvatar(var_66_26)
							end

							if arg_66_0.isAwakeCampaign and iter_66_1:getTableID() == arg_66_0.awakeHero:getTableID() then
								local var_68_1 = {
									txt = string.format(var_0_14:translation("AWAKE_SELECT_TEAM_TIP5"), iter_66_1:getName()),
									type = xyd.CommonAlertType.TWO_BTN,
									align = xyd.ui_align.CENTER,
									rcallback = var_68_0
								}

								xyd.WindowManager.get():openWindow("common_alert", var_68_1)
							elseif (iter_66_1.isChallengeKillSteal_ or iter_66_1.isChallengeProtected_) and arg_66_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_15:modeType(arg_66_0.battleID) == xyd.ChallengeType.KillSteal or var_0_15:modeType(arg_66_0.battleID) == xyd.ChallengeType.Protect) then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_14:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
								})
							elseif iter_66_1.isAssist and arg_66_0.campaignType == xyd.CampaignType.NORMAL then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_14:translation("CAMPAIGN_ASSIST_HERO")
								})
							elseif iter_66_1.isAssist and arg_66_0.selectSpType == xyd.SelectSpType.ASSIST then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_14:translation("CAMPAIGN_ASSIST_HERO")
								})
							else
								arg_66_0:clickBottomAvatar(var_66_26)
							end
						end

						return true
					end)

					for iter_66_3 = arg_66_0:getTeamNo(var_66_26), #arg_66_0.team_ do
						local var_66_27, var_66_28 = arg_66_0:nodeByName("avatar" .. iter_66_3):getPosition()

						arg_66_0.team_[iter_66_3]:pos(var_66_27, var_66_28 - 13)

						if arg_66_0.team_[iter_66_3].iniCell_ then
							arg_66_0.team_[iter_66_3].iniCell_.teamNo_ = iter_66_3
						end
					end
				end
			end
		end

		arg_66_0:updateScore()
	end

	arg_66_0.preSelect_ = {}
	arg_66_0.preHeros_ = {}
end

function var_0_0.clickAvatar(arg_70_0, arg_70_1, arg_70_2)
	if arg_70_1.isAnimated_ or not arg_70_1.teamNo_ and #arg_70_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if arg_70_0.selectSpType == xyd.SelectSpType.SINGLE and #arg_70_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_14:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return
	end

	if arg_70_0.selectSpType == xyd.SelectSpType.TRIPLE and #arg_70_0.team_ >= 3 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_14:translation("ARENA_MODE_MAX_HERO"), 3)
		})

		return
	end

	if not arg_70_2 then
		arg_70_0.unPreSelect_ = true
	end

	local var_70_0

	if arg_70_0.leftMenuType_ == var_0_18.SELF_HERO then
		var_70_0 = arg_70_1:getChildByName("layout")
	else
		var_70_0 = arg_70_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_70_1 = var_70_0:getChildByName("avatar_mask")
	local var_70_2 = var_70_0:getChildByName("chosen")
	local var_70_3 = arg_70_1:convertToWorldSpace(cc.p(0, 0))
	local var_70_4 = var_70_3.x + arg_70_1:getContentSize().width / 2
	local var_70_5 = var_70_3.y + arg_70_1:getContentSize().height / 2

	arg_70_1.isAnimated_ = true

	if arg_70_1.teamNo_ then
		local var_70_6 = arg_70_0.team_[arg_70_1.teamNo_]

		arg_70_0:moveFadeOutAction(var_70_4, var_70_5, var_70_6, function()
			arg_70_1.isAnimated_ = false
		end)
		var_70_1:setVisible(false)
		var_70_2:setVisible(false)

		for iter_70_0 = #arg_70_0.team_, arg_70_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_70_0.team_[iter_70_0])

			local var_70_7, var_70_8 = arg_70_0:nodeByName("avatar" .. iter_70_0 - 1):getPosition()

			transition.moveTo(arg_70_0.team_[iter_70_0], {
				time = 0.3,
				x = var_70_7,
				y = var_70_8 - 13
			})

			arg_70_0.team_[iter_70_0].iniCell_.teamNo_ = iter_70_0 - 1
		end

		if var_70_6.type == var_0_18.RENT_HERO then
			arg_70_0.isSelectMerHero = false
			arg_70_0.selectMerHero = nil
		end

		table.remove(arg_70_0.team_, arg_70_1.teamNo_)
		table.remove(arg_70_0.select_, arg_70_1.teamNo_)

		arg_70_1.teamNo_ = nil
	elseif not arg_70_1.teamNo_ and #arg_70_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if not arg_70_2 then
			local var_70_9 = arg_70_1.data

			if var_0_16:chosenSound(var_70_9:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_70_9:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_16:chosenSound(var_70_9:getTableID()), false)
			end
		end

		if not arg_70_1.data.can_rent and arg_70_0.leftMenuType_ == var_0_18.RENT_HERO then
			arg_70_1.isAnimated_ = false

			return
		end

		if arg_70_1.data.isDead then
			arg_70_1.isAnimated_ = false

			return
		end

		if (arg_70_0.isSelectMerHero or arg_70_0.isSelectMerPet) and arg_70_0.leftMenuType_ == var_0_18.RENT_HERO then
			arg_70_1.isAnimated_ = false

			local var_70_10 = var_0_14:translation("MERCENARY_ERROR_TIP1")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_70_10
			})

			return
		end

		if not arg_70_0:checkHeroValid(arg_70_1.data) then
			arg_70_1.isAnimated_ = false

			local var_70_11 = var_0_14:translation("MERCENARY_ERROR_TIP2")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_70_11
			})

			return
		end

		local var_70_12 = arg_70_1.data.rent_need_mana

		if var_70_12 and var_70_12 > arg_70_0.selfPlayer.mana and not arg_70_1.data.have_rent then
			arg_70_1.isAnimated_ = false

			local var_70_13 = var_0_14:translation("MERCENARY_ERROR_TIP3")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_70_13
			})

			return
		end

		local var_70_14 = arg_70_0:initBottomCell(arg_70_1.data)

		var_70_14.iniCell_ = arg_70_1

		var_70_14:pos(var_70_4, var_70_5)
		var_70_14:addTo(arg_70_0)
		var_70_14:setTouchEnabled(true)

		local var_70_15 = arg_70_1.data

		var_70_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_73_0)
			if arg_73_0.name == "ended" then
				local function var_73_0()
					arg_70_0:clickBottomAvatar(var_70_14)
				end

				if arg_70_0.isAwakeCampaign and var_70_15:getTableID() == arg_70_0.awakeHero:getTableID() and arg_70_1.type == var_0_18.SELF_HERO then
					local var_73_1 = {
						txt = string.format(var_0_14:translation("AWAKE_SELECT_TEAM_TIP5"), var_70_15:getName()),
						type = xyd.CommonAlertType.TWO_BTN,
						align = xyd.ui_align.CENTER,
						rcallback = var_73_0
					}

					xyd.WindowManager.get():openWindow("common_alert", var_73_1)
				elseif (var_70_15.isChallengeKillSteal_ or var_70_15.isChallengeProtected_) and arg_70_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_15:modeType(arg_70_0.battleID) == xyd.ChallengeType.KillSteal or var_0_15:modeType(arg_70_0.battleID) == xyd.ChallengeType.Protect) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
					})
				elseif var_70_15.isAssist and arg_70_0.campaignType == xyd.CampaignType.NORMAL then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("CAMPAIGN_ASSIST_HERO")
					})
				elseif var_70_15.isAssist and arg_70_0.selectSpType == xyd.SelectSpType.ASSIST then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("CAMPAIGN_ASSIST_HERO")
					})
				else
					arg_70_0:clickBottomAvatar(var_70_14)
				end
			end

			return true
		end)

		if arg_70_1.type == var_0_18.RENT_HERO then
			arg_70_0.isSelectMerHero = true
			arg_70_0.selectMerHero = var_70_14.data
		end

		arg_70_1.teamNo_ = arg_70_0:getTeamNo(var_70_14)

		for iter_70_1 = arg_70_1.teamNo_, #arg_70_0.team_ do
			local var_70_16, var_70_17 = arg_70_0:nodeByName("avatar" .. iter_70_1):getPosition()

			if arg_70_2 then
				arg_70_0.team_[iter_70_1]:pos(var_70_16, var_70_17 - 13)

				arg_70_1.isAnimated_ = false
			elseif iter_70_1 ~= arg_70_1.teamNo_ then
				local var_70_18 = arg_70_0.team_[iter_70_1]

				transition.stopTarget(var_70_18)
				transition.moveTo(var_70_18, {
					time = 0.3,
					x = var_70_16,
					y = var_70_17 - 13,
					onComplete = function()
						var_70_18.iniCell_.isAnimated_ = false
						var_70_18.isAnimated_ = false
					end
				})
			else
				local var_70_19 = arg_70_0.team_[iter_70_1]

				transition.stopTarget(var_70_19)

				var_70_14.isAnimated_ = true

				transition.moveTo(var_70_19, {
					time = 0.3,
					x = var_70_16,
					y = var_70_17 - 13,
					onComplete = function()
						arg_70_1.isAnimated_ = false
						var_70_14.isAnimated_ = false
					end
				})
			end

			arg_70_0.team_[iter_70_1].iniCell_.teamNo_ = iter_70_1
		end

		var_70_1:setVisible(true)
		var_70_2:setVisible(true)
	end

	if not arg_70_2 then
		arg_70_0:playGuide()
	end

	arg_70_0:updateScore()
end

function var_0_0.checkHeroValid(arg_77_0, arg_77_1)
	for iter_77_0, iter_77_1 in pairs(arg_77_0.select_) do
		if arg_77_1:getTableID() == iter_77_1:getTableID() or xyd.tables.hero:beforeAwaken(arg_77_1:getTableID()) == iter_77_1:getTableID() or xyd.tables.hero:afterAwaken(arg_77_1:getTableID()) == iter_77_1:getTableID() or iter_77_1.isAssist and arg_77_1:getTableID() == arg_77_0.assistHeroID then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_78_0)
	if arg_78_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_78_0.type == xyd.SelectTeamType.REGION_ARENA then
		arg_78_0:nodeByName("text_bg"):hide()

		return
	end

	local var_78_0 = 0
	local var_78_1 = 0

	for iter_78_0, iter_78_1 in ipairs(arg_78_0.team_) do
		local var_78_2 = iter_78_1.data

		var_78_0 = var_78_0 + var_78_2:getZhandouli()

		if arg_78_0.type == xyd.SelectTeamType.ADVANCED then
			if arg_78_0:isRecommend(var_78_2) then
				var_78_1 = var_78_1 + var_78_2:getZhandouli() * 2
			else
				var_78_1 = var_78_1 + var_78_2:getZhandouli()
			end
		end
	end

	for iter_78_2, iter_78_3 in ipairs(arg_78_0.petTeam_) do
		var_78_0 = var_78_0 + iter_78_3.data:getZhandouli()
	end

	arg_78_0:nodeByName("zhandouli"):setString(var_78_0)

	if arg_78_0.type == xyd.SelectTeamType.ADVANCED then
		arg_78_0:nodeByName("bg_txt"):setString(var_0_14:translation("ADVANCED_SWEEP"))

		local var_78_3 = ""
		local var_78_4 = var_78_1 < arg_78_0.rateValue[1] and "d" or var_78_1 < arg_78_0.rateValue[2] and "c" or var_78_1 < arg_78_0.rateValue[3] and "b" or var_78_1 < arg_78_0.rateValue[4] and "a" or "s"

		arg_78_0:nodeByName("rate_pic"):loadTexture("windows/battle/select_team_new/icon_" .. var_78_4 .. ".png")

		arg_78_0.rateScore = var_78_1

		local var_78_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
		local var_78_6 = var_0_17:rateValue(var_78_5.lev)
		local var_78_7 = var_0_17:sweepNum(var_78_5.lev)

		if arg_78_0.rateScore == 0 then
			local var_78_8 = xyd.split(var_78_7[1], ",")

			arg_78_0:nodeByName("bg_sweep_number"):setString(var_0_14:translation(""))
		elseif arg_78_0.rateScore < tonumber(var_78_6[1]) then
			local var_78_9 = xyd.split(var_78_7[1], ",")

			arg_78_0:nodeByName("bg_sweep_number"):setString(string.format(var_0_14:translation("SWEEP_NUMBER"), var_78_9[1], var_78_9[#var_78_9]))
		elseif arg_78_0.rateScore < tonumber(var_78_6[2]) then
			local var_78_10 = xyd.split(var_78_7[2], ",")

			arg_78_0:nodeByName("bg_sweep_number"):setString(string.format(var_0_14:translation("SWEEP_NUMBER"), var_78_10[1], var_78_10[#var_78_10]))
		elseif arg_78_0.rateScore < tonumber(var_78_6[3]) then
			local var_78_11 = xyd.split(var_78_7[3], ",")

			arg_78_0:nodeByName("bg_sweep_number"):setString(string.format(var_0_14:translation("SWEEP_NUMBER"), var_78_11[1], var_78_11[#var_78_11]))
		elseif arg_78_0.rateScore < tonumber(var_78_6[4]) then
			local var_78_12 = xyd.split(var_78_7[4], ",")

			arg_78_0:nodeByName("bg_sweep_number"):setString(string.format(var_0_14:translation("SWEEP_NUMBER"), var_78_12[1], var_78_12[#var_78_12]))
		else
			local var_78_13 = xyd.split(var_78_7[5], ",")

			arg_78_0:nodeByName("bg_sweep_number"):setString(string.format(var_0_14:translation("SWEEP_NUMBER"), var_78_13[1], var_78_13[#var_78_13]))
		end
	end
end

function var_0_0.clickBottomAvatar(arg_79_0, arg_79_1)
	if arg_79_1.isAnimated_ then
		return
	end

	local var_79_0, var_79_1 = arg_79_0:nodeByName("list_layer"):getPosition()
	local var_79_2 = arg_79_1.iniCell_
	local var_79_3

	for iter_79_0, iter_79_1 in ipairs(arg_79_0.select_) do
		if iter_79_1:getTableID() == arg_79_1.data:getTableID() and iter_79_1.player_name == arg_79_1.data.player_name then
			var_79_3 = iter_79_0

			break
		end
	end

	if not var_79_3 then
		return
	end

	if not arg_79_1.iniCellVisible_ and arg_79_1.type == arg_79_0.leftMenuType_ and not tolua.isnull(var_79_2) then
		local var_79_4 = var_79_2:convertToWorldSpace(cc.p(0, 0))

		var_79_0, var_79_1 = var_79_4.x + var_79_2:getContentSize().width / 2, var_79_4.y + var_79_2:getContentSize().height / 2

		local var_79_5

		if arg_79_1.type == var_0_18.RENT_HERO then
			var_79_5 = var_79_2:getChildByName("yongbingCell"):getChildByName("container")
		else
			var_79_5 = var_79_2:getChildByName("layout")
		end

		local var_79_6 = var_79_5:getChildByName("avatar_mask")
		local var_79_7 = var_79_5:getChildByName("chosen")

		var_79_6:setVisible(false)
		var_79_7:setVisible(false)
	end

	arg_79_0:moveFadeOutAction(var_79_0, var_79_1, arg_79_1)

	for iter_79_2 = #arg_79_0.team_, var_79_3 + 1, -1 do
		local var_79_8 = arg_79_0.team_[iter_79_2]
		local var_79_9, var_79_10 = arg_79_0:nodeByName("avatar" .. iter_79_2 - 1):getPosition()

		transition.stopTarget(var_79_8)
		transition.moveTo(arg_79_0.team_[iter_79_2], {
			time = 0.3,
			x = var_79_9,
			y = var_79_10 - 13
		})

		arg_79_0.team_[iter_79_2].iniCell_.teamNo_ = iter_79_2 - 1
	end

	if arg_79_1.type == var_0_18.RENT_HERO then
		arg_79_0.isSelectMerHero = false
		arg_79_0.selectMerHero = nil
	end

	table.remove(arg_79_0.team_, var_79_3)
	table.remove(arg_79_0.select_, var_79_3)

	var_79_2.teamNo_ = nil

	arg_79_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_80_0, arg_80_1, arg_80_2)
	if arg_80_1.isAnimated_ then
		return
	end

	local var_80_0, var_80_1 = arg_80_0:nodeByName("list_layer"):getPosition()
	local var_80_2 = arg_80_1.iniCell_
	local var_80_3

	for iter_80_0, iter_80_1 in ipairs(arg_80_0.petSelect_) do
		if iter_80_1:getTableID() == arg_80_1.data:getTableID() and iter_80_1.player_name == arg_80_1.data.player_name then
			var_80_3 = iter_80_0

			break
		end
	end

	if not var_80_3 then
		return
	end

	if var_80_2 and not tolua.isnull(var_80_2) then
		local var_80_4 = var_80_2:convertToWorldSpace(cc.p(0, 0))

		var_80_0, var_80_1 = var_80_4.x, var_80_4.y

		local var_80_5

		if arg_80_0.rentMenuType == var_0_19.RENT_PET then
			var_80_5 = var_80_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_80_5 = var_80_2:getChildByName("layout")
		end

		local var_80_6 = var_80_5:getChildByName("avatar_mask")
		local var_80_7 = var_80_5:getChildByName("chosen")

		var_80_6:setVisible(false)
		var_80_7:setVisible(false)
	end

	arg_80_0:moveFadeOutAction(var_80_0, var_80_1, arg_80_1, arg_80_2)

	for iter_80_2 = #arg_80_0.petTeam_, var_80_3 + 1, -1 do
		local var_80_8 = arg_80_0.petTeam_[iter_80_2]
		local var_80_9, var_80_10 = arg_80_0:nodeByName("avatar_pet" .. iter_80_2 - 1):getPosition()

		transition.stopTarget(var_80_8)
		transition.moveTo(arg_80_0.petTeam_[iter_80_2], {
			time = 0.3,
			x = var_80_9,
			y = var_80_10
		})

		arg_80_0.petTeam_[iter_80_2].iniCell_.teamNo_ = iter_80_2 - 1
	end

	if arg_80_1.type == var_0_20.RENT_PET then
		arg_80_0.isSelectMerPet = false
		arg_80_0.selectMerPet = nil
	end

	table.remove(arg_80_0.petTeam_, var_80_3)
	table.remove(arg_80_0.petSelect_, var_80_3)

	if var_80_2 then
		var_80_2.teamNo_ = nil
	end

	arg_80_0:updateScore()
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_81_0, arg_81_1, arg_81_2)
	if arg_81_1.isAnimated_ then
		return
	end

	local var_81_0, var_81_1 = arg_81_0:nodeByName("list_layer"):getPosition()
	local var_81_2 = arg_81_1.iniCell_
	local var_81_3

	for iter_81_0, iter_81_1 in ipairs(arg_81_0.petTeam_) do
		if iter_81_1 == arg_81_1 then
			var_81_3 = iter_81_0

			break
		end
	end

	if not var_81_3 then
		return
	end

	if var_81_2 and not tolua.isnull(var_81_2) then
		local var_81_4 = var_81_2:convertToWorldSpace(cc.p(0, 0))
		local var_81_5

		if arg_81_0.rentMenuType == var_0_19.RENT_PET then
			var_81_5 = var_81_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_81_5 = var_81_2:getChildByName("layout")
		end

		local var_81_6 = var_81_5:getChildByName("avatar_mask")
		local var_81_7 = var_81_5:getChildByName("chosen")

		var_81_6:setVisible(false)
		var_81_7:setVisible(false)
	end

	for iter_81_2 = #arg_81_0.petTeam_, var_81_3 + 1, -1 do
		local var_81_8 = arg_81_0.petTeam_[iter_81_2]
		local var_81_9, var_81_10 = arg_81_0:nodeByName("avatar_pet" .. iter_81_2 - 1):getPosition()

		transition.stopTarget(var_81_8)
		transition.moveTo(arg_81_0.petTeam_[iter_81_2], {
			time = 0.3,
			x = var_81_9,
			y = var_81_10
		})

		arg_81_0.petTeam_[iter_81_2].iniCell_.teamNo_ = iter_81_2 - 1
	end

	if arg_81_1.type == var_0_20.RENT_PET then
		arg_81_0.isSelectMerPet = false
		arg_81_0.selectMerPet = nil
	end

	table.remove(arg_81_0.petTeam_, var_81_3)
	table.remove(arg_81_0.petSelect_, var_81_3)

	if var_81_2 then
		var_81_2.teamNo_ = nil
	end

	if arg_81_1 and not tolua.isnull(arg_81_1) then
		arg_81_1:removeSelf()
	end

	if arg_81_2 then
		arg_81_2()
	end
end

function var_0_0.getTeamNo(arg_82_0, arg_82_1)
	for iter_82_0, iter_82_1 in ipairs(arg_82_0.team_) do
		if arg_82_1.data:getDistance() < iter_82_1.data:getDistance() then
			table.insert(arg_82_0.team_, iter_82_0, arg_82_1)
			table.insert(arg_82_0.select_, iter_82_0, arg_82_1.data)

			return iter_82_0
		end
	end

	table.insert(arg_82_0.team_, arg_82_1)
	table.insert(arg_82_0.select_, arg_82_1.data)

	return #arg_82_0.team_
end

function var_0_0.getPetTeamNo(arg_83_0, arg_83_1)
	table.insert(arg_83_0.petTeam_, arg_83_1)
	table.insert(arg_83_0.petSelect_, arg_83_1.data)

	return #arg_83_0.petTeam_
end

function var_0_0.widgetSet(arg_84_0, arg_84_1)
	for iter_84_0, iter_84_1 in ipairs(arg_84_1:getChildren()) do
		if iter_84_1 ~= nil then
			iter_84_1:setCascadeOpacityEnabled(true)
			arg_84_0:widgetSet(iter_84_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_85_0, arg_85_1, arg_85_2, arg_85_3, arg_85_4)
	arg_85_0:widgetSet(arg_85_3)
	arg_85_3:setCascadeOpacityEnabled(true)

	local var_85_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_85_1, arg_85_2)))

	arg_85_3:runActionOnce(var_85_0, true, arg_85_4)
end

function var_0_0.moveFadeInAction(arg_86_0, arg_86_1, arg_86_2, arg_86_3, arg_86_4)
	arg_86_0:widgetSet(arg_86_3)
	arg_86_3:setCascadeOpacityEnabled(true)
	arg_86_3:setOpacity(0)

	local var_86_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_86_1, arg_86_2)))

	arg_86_3:runActionOnce(var_86_0, false, arg_86_4)
end

function var_0_0.getBattlepetBtn(arg_87_0)
	if not arg_87_0.battlepetBtn_ then
		if arg_87_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE then
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_ok")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_88_0, arg_88_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_88_1)

				if #arg_87_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("BATTLE_NO_HERO")
					})

					return
				end

				if #arg_87_0.select_ > 0 and #arg_87_0.select_ < 5 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("REGION_ARENA_TIP48")
					})

					return
				end

				if arg_88_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_88_0 = 0

					if #arg_87_0.petTeam_ ~= 0 and not arg_87_0.isSelectMerPet then
						var_88_0 = arg_87_0.petTeam_[1].data:getPetID()
					end

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.REGION_ARENA_DEFENSE_UPDATE,
						params = {
							defenseHeroes = arg_87_0.select_,
							pet_id = var_88_0
						}
					})
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_87_0.type == xyd.SelectTeamType.TREASURE_DEFENSE then
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_ok")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_89_0, arg_89_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_89_1)

				local var_89_0 = {}

				for iter_89_0, iter_89_1 in pairs(arg_87_0.select_) do
					table.insert(var_89_0, iter_89_1:getHeroID())
				end

				if #arg_87_0.select_ < 1 or #var_89_0 < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_89_1 == ccui.TouchEventType.ended then
					xyd.Backend.get():request(xyd.mid.TREASURE_SET_PARTNER, {
						type = arg_87_0.treasureType,
						partners = var_89_0,
						team_id = arg_87_0.treasureTeamID
					}, function(arg_90_0, arg_90_1)
						return
					end)
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_87_0.type == xyd.SelectTeamType.INCUBUS then
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_ok")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_91_0, arg_91_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_91_1)

				if arg_91_1 == ccui.TouchEventType.ended then
					if #arg_87_0.select_ < 5 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_14:translation("INCUBUS_FIRST")
						})

						return
					end

					xyd.WindowManager.get():openWindow("incubus_select_team", {
						id = arg_87_0.campaignID,
						firstHeros = arg_87_0.select_
					})
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_87_0.type == xyd.SelectTeamType.ADJUST_TROOP then
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_ok")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_92_0, arg_92_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_92_1)

				if #arg_87_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_92_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_92_0 = {
						defenseHeroes = arg_87_0.select_,
						selectTeamId = arg_87_0.selectTeamId
					}

					if #arg_87_0.petTeam_ ~= 0 then
						var_92_0.pet_id = arg_87_0.petTeam_[1].data:getPetID()
					else
						var_92_0.pet_id = 0
					end

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.UPDATE_GUILD_TROOP,
						params = var_92_0
					})
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_87_0.type == xyd.SelectTeamType.HERO_PRESET then
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_ok")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_93_0, arg_93_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_93_1)

				if #arg_87_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("BATTLE_NO_HERO")
					})

					return
				elseif #arg_87_0.select_ < 5 then
					xyd.WindowManager.get():openWindow("toast", {
						message = string.format(var_0_14:translation("PRESET_TEAM_MEM_NOT_ENOUGH"), xyd.MAX_TEAM_MEMBER_NUM)
					})

					return
				end

				if arg_93_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_93_0 = arg_87_0:getFormationStr(arg_87_0.select_)
					local var_93_1

					if #arg_87_0.petTeam_ ~= 0 and not arg_87_0.isSelectMerPet then
						var_93_1 = arg_87_0.petTeam_[1].data:getPetID()
					else
						var_93_1 = 0
					end

					local var_93_2 = {
						formation = var_93_0,
						pet_id = var_93_1,
						presetHeroType = arg_87_0.presetHeroType,
						presetHeroIndex = arg_87_0.presetHeroIndex,
						callback = function()
							if xyd.WindowManager.get():getWindow(xyd.WindowName.SelectTeamWnd) then
								xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
							end
						end
					}

					xyd.WindowManager.get():openWindow("save_team", var_93_2)
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_87_0.type == xyd.SelectTeamType.TWO_YEARS then
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_ok")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_95_0, arg_95_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_95_1)

				if #arg_87_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_95_1 == ccui.TouchEventType.ended and not arg_87_0.battleBegan then
					xyd.playButtonSound()

					if xyd.WindowManager.get():isWindowOpen("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					if arg_87_0.selectMerHero and arg_87_0.selectMerHero.tutorInfo then
						arg_87_0.battleBegan = true

						arg_87_0:startBattle()
					elseif arg_87_0.selectMerHero and not arg_87_0.selectMerHero.have_rent then
						local var_95_0 = {
							hero = arg_87_0.selectMerHero,
							type = xyd.ConfirmRent.HERO
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_95_0)
					elseif arg_87_0.isSelectMerPet and arg_87_0.selectMerPet.can_rent then
						local var_95_1 = {
							hero = arg_87_0.selectMerPet,
							type = xyd.ConfirmRent.PET
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_95_1)
					else
						arg_87_0.battleBegan = true

						arg_87_0:startBattle()
					end
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_battle"):setVisible(false)
		else
			arg_87_0.battlepetBtn_ = arg_87_0:nodeByName("button_battle")

			arg_87_0.battlepetBtn_:addTouchEventListener(function(arg_96_0, arg_96_1)
				xyd.buttonScaleAnim(arg_87_0.battlepetBtn_, arg_96_1)

				if not arg_87_0:checkCanStartBattle() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_14:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_96_1 == ccui.TouchEventType.ended and not arg_87_0.battleBegan then
					xyd.playButtonSound()

					if xyd.WindowManager.get():isWindowOpen("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					if arg_87_0.selectMerHero and arg_87_0.selectMerHero.tutorInfo then
						local var_96_0 = {
							hero = arg_87_0.selectMerHero,
							type = xyd.ConfirmRent.TUTOR
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_96_0)
					elseif arg_87_0.selectMerHero and not arg_87_0.selectMerHero.have_rent then
						local var_96_1 = {
							hero = arg_87_0.selectMerHero,
							type = xyd.ConfirmRent.HERO
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_96_1)
					elseif arg_87_0.isSelectMerPet and arg_87_0.selectMerPet.can_rent then
						local var_96_2 = {
							hero = arg_87_0.selectMerPet,
							type = xyd.ConfirmRent.PET
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_96_2)
					else
						arg_87_0.battleBegan = true

						arg_87_0:startBattle()
					end
				end
			end)
			arg_87_0.battlepetBtn_:setVisible(true)
			arg_87_0:nodeByName("button_ok"):setVisible(false)
		end
	end

	return arg_87_0.battlepetBtn_
end

function var_0_0.checkCanStartBattle(arg_97_0)
	if #arg_97_0.select_ < 1 then
		return false
	elseif #arg_97_0.select_ == 1 and arg_97_0.type == xyd.SelectTeamType.TUTOR then
		return true
	elseif #arg_97_0.select_ == 1 and (arg_97_0.select_[1]:getHeroID() < 0 or arg_97_0.isSelectMerHero) then
		return false
	end

	return true
end

function var_0_0.recordFormation(arg_98_0)
	if arg_98_0.isAwakeCampaign then
		for iter_98_0, iter_98_1 in pairs(arg_98_0.team_) do
			if iter_98_1.type == var_0_18.SELF_HERO and iter_98_1.data:getTableID() == arg_98_0.awakeHero:getTableID() then
				arg_98_0.isAwakeCampaign = true

				return
			else
				arg_98_0.isAwakeCampaign = false
			end
		end
	end

	local var_98_0 = arg_98_0.campaignType
	local var_98_1 = {}

	if var_98_0 == xyd.CampaignType.MARCH then
		for iter_98_2, iter_98_3 in pairs(arg_98_0.team_) do
			if iter_98_3.type == var_0_18.RENT_HERO then
				table.insert(var_98_1, -iter_98_3.data:getHeroID())
			else
				table.insert(var_98_1, iter_98_3.data:getHeroID())
			end
		end
	else
		for iter_98_4, iter_98_5 in ipairs(arg_98_0.team_) do
			if iter_98_5.type ~= var_0_18.RENT_HERO then
				table.insert(var_98_1, iter_98_5.data:getHeroID())
			end
		end
	end

	local var_98_2 = ""

	for iter_98_6, iter_98_7 in ipairs(var_98_1) do
		var_98_2 = var_98_2 .. string.format("%d|", iter_98_7)
	end

	if arg_98_0:isPet() and next(arg_98_0.petTeam_) then
		local var_98_3 = ""

		for iter_98_8, iter_98_9 in ipairs(arg_98_0.petTeam_) do
			if iter_98_9.type ~= var_0_20.RENT_PET then
				var_98_3 = var_98_3 .. string.format("%d|", iter_98_9.data:getPetID())
			end
		end

		var_98_2 = var_98_2 .. "," .. var_98_3
	end

	xyd.db.formation:setFormationData(var_98_0, var_98_2)
end

function var_0_0.startBattle(arg_99_0)
	if next(arg_99_0.team_) == nil then
		return
	end

	if arg_99_0.ispreperation then
		arg_99_0.type = xyd.SelectTeamType.CAMPAIGN
	end

	if arg_99_0.type == xyd.SelectTeamType.ADVANCED then
		arg_99_0:startMarchAdvance()
	elseif arg_99_0.type == xyd.SelectTeamType.REGION_ARENA then
		if next(arg_99_0.enemyHeroes_) == nil then
			return
		end

		arg_99_0:recordFormation()
		arg_99_0:startRegionArenaBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.MARCH then
		if next(arg_99_0.enemyHeroes_) == nil then
			return
		end

		arg_99_0:recordFormation()
		arg_99_0:startMarchBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.TREASURE then
		if next(arg_99_0.enemyHeroes_) == nil then
			return
		end

		arg_99_0:recordFormation()
		arg_99_0:startTreasureBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.GUILD then
		arg_99_0:recordFormation()
		arg_99_0:startGuildCampaignBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.WORLD_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startWorldBossBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.NIAN_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startNianBossBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.SAKURA_CAMPAIGN then
		arg_99_0:recordFormation()
		arg_99_0:startSakuraBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.PET then
		arg_99_0:recordFormation()
		arg_99_0:startPetBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.PET_PRACTICE then
		arg_99_0:startPetBattle(true)
	elseif arg_99_0.type == xyd.SelectTeamType.CHALLENGE then
		arg_99_0:recordFormation()
		arg_99_0:startChallengeBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.THIEF_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startThiefBossBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.ILLUSION then
		arg_99_0:recordFormation()
		arg_99_0:startIllusionBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.SINGLE_DAY then
		arg_99_0:startSingleDayBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.CONQUER_SCHOOL then
		arg_99_0:recordFormation()
		arg_99_0:startConquerSchoolBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.SAKURA2_COMPETITOR then
		arg_99_0:startSakura2CompetitorBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.SAKURA2_WAR then
		arg_99_0:startSakura2WarBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.STUDENT_OVER then
		arg_99_0:recordFormation()
		arg_99_0:startStudentBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		arg_99_0:recordFormation()
		arg_99_0:startZhugeNoteBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.ZHUGE_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startZhugeBossBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER then
		arg_99_0:recordFormation()
		arg_99_0:startMemoriesOfSchoolBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER then
		arg_99_0:recordFormation()
		arg_99_0:startMemoriesOfSchoolPVPBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.SUMMER_FIGHT_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startSummerFightBossBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.TWO_YEARS then
		arg_99_0:recordFormation()
		arg_99_0:startTwoYearsFight()
	elseif arg_99_0.type == xyd.SelectTeamType.ADVENTURE_BATTLE then
		arg_99_0:recordFormation()
		arg_99_0:startAdventureBattleFight()
	elseif arg_99_0.type == xyd.SelectTeamType.ADVENTURE_ILLUSION_SINGLE then
		arg_99_0:recordFormation()
		arg_99_0:startAdventureIllusionSingleFight()
	elseif arg_99_0.type == xyd.SelectTeamType.ADVENTURE_DEFENSE then
		arg_99_0:recordFormation()
		arg_99_0:startAdventureDefenseFight()
	elseif arg_99_0.type == xyd.SelectTeamType.CHAPTER_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startChapterBossFight()
	elseif arg_99_0.type == xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startThirdAnniversaryBossBattle()
	elseif arg_99_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		arg_99_0:recordFormation()
		arg_99_0:startSuperRichChallenge()
	elseif arg_99_0.type == xyd.SelectTeamType.CHOCOLATE then
		arg_99_0:recordFormation()
		arg_99_0:startChocolateFight()
	elseif arg_99_0.type == xyd.SelectTeamType.TUTOR then
		arg_99_0:startTutorFight()
	elseif arg_99_0.type == xyd.SelectTeamType.DREAM_WORLD then
		arg_99_0:recordFormation()
		arg_99_0:startDreamWorldFight()
	elseif arg_99_0.type == xyd.SelectTeamType.FOURTH_ANNI_MAP then
		arg_99_0:recordFormation()
		arg_99_0:startFourthAnniMapFight()
	elseif arg_99_0.type == xyd.SelectTeamType.ALL_NIGHT_MAP then
		arg_99_0:recordFormation()
		arg_99_0:startAllNightMapFight()
	elseif arg_99_0.type == xyd.SelectTeamType.ALL_NIGHT_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startAllNightBossFight()
	elseif arg_99_0.type == xyd.SelectTeamType.RAGNAROK_MAP then
		arg_99_0:recordFormation()
		arg_99_0:startRagnarokMapFight()
	elseif arg_99_0.type == xyd.SelectTeamType.RAGNAROK then
		arg_99_0:recordFormation()
		arg_99_0:startRagnarokFight()
	elseif arg_99_0.type == xyd.SelectTeamType.FIFTH_ANNIVERSARY_BOSS then
		arg_99_0:recordFormation()
		arg_99_0:startFifthAnniBossFight()
	elseif arg_99_0.type == xyd.SelectTeamType.HUNQI then
		arg_99_0:recordFormation()
		arg_99_0:startHunqiFight()
	else
		arg_99_0:recordFormation()
		arg_99_0:startCampaignBattle()
	end
end

function var_0_0.startHunqiFight(arg_100_0)
	local var_100_0 = {
		campaignType = arg_100_0.campaignType,
		campaignID = arg_100_0.campaignID,
		battleID = arg_100_0.battleID,
		herosA = {}
	}
	local var_100_1 = false

	for iter_100_0, iter_100_1 in ipairs(arg_100_0.team_) do
		iter_100_1.data.type = iter_100_1.type

		if iter_100_1.type == var_0_18.RENT_HERO then
			var_100_1 = true
		end

		table.insert(var_100_0.herosA, iter_100_1.data)
	end

	var_100_0.rentFlag = var_100_1

	local var_100_2 = xyd.tables.battle:monsters(var_100_0.battleID)

	var_100_0.herosB = {}

	for iter_100_2 = 1, #var_100_2 do
		local var_100_3 = {}

		for iter_100_3, iter_100_4 in ipairs(var_100_2[iter_100_2]) do
			local var_100_4 = var_0_1.new()

			var_100_4:populateWithTableID(iter_100_4)
			table.insert(var_100_3, var_100_4)
		end

		if next(var_100_3) then
			table.insert(var_100_0.herosB, var_100_3)
		end
	end

	local var_100_5 = {}

	for iter_100_5, iter_100_6 in pairs(var_100_0.herosA) do
		if iter_100_6.type ~= var_0_18.RENT_HERO and iter_100_6:getHeroID() > 0 then
			table.insert(var_100_5, iter_100_6)
		end
	end

	local var_100_6 = arg_100_0:getFormationStr(var_100_5)

	var_100_0.formation = var_100_6

	local var_100_7 = {
		campaign_id = var_100_0.campaignID,
		campaign_type = var_100_0.campaignType,
		formation = var_100_6
	}
	local var_100_8

	if #arg_100_0.petTeam_ ~= 0 and not arg_100_0.isSelectMerPet then
		var_100_8 = arg_100_0.petTeam_[1].data:getPetID()
	end

	var_100_7.pet_id = var_100_8

	if arg_100_0.isSelectMerPet then
		var_100_0.rent_pet_id = arg_100_0.selectMerPet:getPetID()
	end

	if arg_100_0.selectMerPet then
		var_100_7.rent_pet_player_id = arg_100_0.selectMerPet.player_id
		var_100_7.rent_pet_id = tostring(arg_100_0.selectMerPet:getPetID())
	end

	arg_100_0:handleRentParams(var_100_7)

	var_100_0.fightParams = var_100_7

	xyd.Backend.get():request(xyd.mid.HUNQI_START_FIGHT, var_100_7, function(arg_101_0, arg_101_1)
		if arg_101_0 == xyd.error.OK then
			if arg_100_0.selectMerHero then
				arg_100_0.guild:setUseRent(arg_100_0.selectMerHero)
			end

			if arg_100_0.selectMerPet then
				arg_100_0.guild:setUseRentPet(arg_100_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "hunqi_campaign"
				}
			})

			var_100_0.petsA = {}

			for iter_101_0, iter_101_1 in ipairs(arg_100_0.petSelect_) do
				table.insert(var_100_0.petsA, iter_101_1)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_100_0)
		else
			arg_100_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startFifthAnniBossFight(arg_102_0)
	local var_102_0 = {
		campaignType = arg_102_0.campaignType,
		battleID = arg_102_0.battleID,
		herosA = {}
	}
	local var_102_1 = {}
	local var_102_2 = false

	for iter_102_0, iter_102_1 in ipairs(arg_102_0.team_) do
		iter_102_1.data.type = iter_102_1.type

		if iter_102_1.type == var_0_18.RENT_HERO then
			var_102_2 = true
		else
			table.insert(var_102_1, iter_102_1.data)
		end

		table.insert(var_102_0.herosA, iter_102_1.data)
	end

	var_102_0.rentFlag = var_102_2

	local var_102_3 = xyd.tables.battle:monsters(var_102_0.battleID)

	var_102_0.herosB = {}

	local var_102_4 = {}

	for iter_102_2, iter_102_3 in ipairs(var_102_3[1]) do
		local var_102_5 = var_0_1.new()

		var_102_5:populateWithTableID(iter_102_3)
		table.insert(var_102_4, var_102_5)
	end

	table.insert(var_102_0.herosB, var_102_4)

	local var_102_6 = {
		formation = arg_102_0:getFormationStr(var_102_1)
	}
	local var_102_7

	if #arg_102_0.petTeam_ ~= 0 and not arg_102_0.isSelectMerPet then
		var_102_7 = arg_102_0.petTeam_[1].data:getPetID()
	end

	var_102_6.pet_id = var_102_7

	if arg_102_0.isSelectMerPet then
		var_102_0.rent_pet_id = arg_102_0.selectMerPet:getPetID()
	end

	if arg_102_0.selectMerPet then
		var_102_6.rent_pet_player_id = arg_102_0.selectMerPet.player_id
		var_102_6.rent_pet_id = tostring(arg_102_0.selectMerPet:getPetID())
	end

	arg_102_0:handleRentParams(var_102_6)

	var_102_0.fightParams = var_102_6

	xyd.Backend.get():request(xyd.mid.FIFTH_ANNI_BOSS_START_FIGHT, var_102_6, function(arg_103_0, arg_103_1)
		if arg_103_0 == xyd.error.OK then
			local var_103_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)

			var_103_0.isFighting = arg_103_1.is_fighting

			if var_103_0.bossInfo.stage ~= arg_103_1.stage then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_14:translation("ACTIVITY_1232_BOSS_21")
				})

				arg_102_0.battleBegan = false

				local var_103_1 = xyd.WindowManager.get():getWindow("fifth_anni_boss")

				if var_103_1 then
					var_103_1:close()
				end

				return
			end

			if arg_102_0.selectMerHero then
				arg_102_0.guild:setUseRent(arg_102_0.selectMerHero)
			end

			if arg_102_0.selectMerPet then
				arg_102_0.guild:setUseRentPet(arg_102_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "fifth_anni_boss"
				}
			})

			var_102_0.petsA = {}

			for iter_103_0, iter_103_1 in ipairs(arg_102_0.petSelect_) do
				table.insert(var_102_0.petsA, iter_103_1)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_102_0)
		else
			arg_102_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startRagnarokFight(arg_104_0)
	local var_104_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	local var_104_1 = {
		campaignType = arg_104_0.campaignType,
		battleID = arg_104_0.battleID,
		herosA = {}
	}
	local var_104_2 = {}
	local var_104_3 = false

	for iter_104_0, iter_104_1 in ipairs(arg_104_0.team_) do
		iter_104_1.data.type = iter_104_1.type

		if iter_104_1.type == var_0_18.RENT_HERO then
			var_104_3 = true
		else
			table.insert(var_104_2, iter_104_1.data)
		end

		table.insert(var_104_1.herosA, iter_104_1.data)
	end

	var_104_1.rentFlag = var_104_3

	local var_104_4 = xyd.tables.battle:monsters(var_104_1.battleID)

	var_104_1.herosB = {}

	local var_104_5 = {}

	for iter_104_2, iter_104_3 in ipairs(var_104_4[1]) do
		local var_104_6 = var_0_1.new()

		var_104_6:populateWithTableID(iter_104_3)

		local var_104_7 = {
			hp = var_104_0:getEnemyHp()
		}

		var_104_7.health = 1
		var_104_7.mp = 0
		var_104_6.healthStatus = var_104_7

		table.insert(var_104_5, var_104_6)
	end

	table.insert(var_104_1.herosB, var_104_5)

	local var_104_8 = {
		formation = arg_104_0:getFormationStr(var_104_2),
		pos = var_104_0:getPos()
	}

	var_104_1.fightParams = var_104_8

	if var_104_0:getType() == xyd.RagnarokType.SINGLE then
		xyd.Backend.get():request(xyd.mid.RAGNAROK_START_SINGLE_FIGHT, var_104_8, function(arg_105_0, arg_105_1)
			if arg_105_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "ragnarok_battle"
					}
				})

				var_104_1.petsA = {}

				for iter_105_0, iter_105_1 in ipairs(arg_104_0.petSelect_) do
					table.insert(var_104_1.petsA, iter_105_1)
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_104_1)
			else
				arg_104_0.battleBegan = false
			end
		end, nil, false, true)
	elseif var_104_0:getType() == xyd.RagnarokType.TEAM then
		xyd.Backend.get():request(xyd.mid.RAGNAROK_START_TEAM_FIGHT, var_104_8, function(arg_106_0, arg_106_1)
			if arg_106_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "ragnarok_battle"
					}
				})

				var_104_1.petsA = {}

				for iter_106_0, iter_106_1 in ipairs(arg_104_0.petSelect_) do
					table.insert(var_104_1.petsA, iter_106_1)
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_104_1)
			else
				arg_104_0.battleBegan = false
			end
		end, nil, false, true)
	end
end

function var_0_0.startAllNightBossFight(arg_107_0)
	local var_107_0 = {
		campaignType = arg_107_0.campaignType,
		battleID = arg_107_0.battleID,
		herosA = {}
	}
	local var_107_1 = {}
	local var_107_2 = false

	for iter_107_0, iter_107_1 in ipairs(arg_107_0.team_) do
		iter_107_1.data.type = iter_107_1.type

		if iter_107_1.type == var_0_18.RENT_HERO then
			var_107_2 = true
		else
			table.insert(var_107_1, iter_107_1.data)
		end

		table.insert(var_107_0.herosA, iter_107_1.data)
	end

	var_107_0.rentFlag = var_107_2

	local var_107_3 = xyd.tables.battle:monsters(var_107_0.battleID)

	var_107_0.herosB = {}

	local var_107_4 = {}

	for iter_107_2, iter_107_3 in ipairs(var_107_3[1]) do
		local var_107_5 = var_0_1.new()

		var_107_5:populateWithTableID(iter_107_3)
		table.insert(var_107_4, var_107_5)
	end

	table.insert(var_107_0.herosB, var_107_4)

	local var_107_6 = {
		formation = arg_107_0:getFormationStr(var_107_1)
	}
	local var_107_7

	if #arg_107_0.petTeam_ ~= 0 and not arg_107_0.isSelectMerPet then
		var_107_7 = arg_107_0.petTeam_[1].data:getPetID()
	end

	var_107_6.pet_id = var_107_7

	if arg_107_0.isSelectMerPet then
		var_107_0.rent_pet_id = arg_107_0.selectMerPet:getPetID()
	end

	if arg_107_0.selectMerPet then
		var_107_6.rent_pet_player_id = arg_107_0.selectMerPet.player_id
		var_107_6.rent_pet_id = tostring(arg_107_0.selectMerPet:getPetID())
	end

	arg_107_0:handleRentParams(var_107_6)

	var_107_0.fightParams = var_107_6

	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_BOSS_START_FIGHT, var_107_6, function(arg_108_0, arg_108_1)
		if arg_108_0 == xyd.error.OK then
			local var_108_0 = xyd.tables.misc:getValue("activity_polar_night_boss_ticket")

			arg_107_0.selfPlayer:getBackpack():removeItem({
				itemNum = 1,
				itemID = var_108_0
			})

			if arg_107_0.selectMerHero then
				arg_107_0.guild:setUseRent(arg_107_0.selectMerHero)
			end

			if arg_107_0.selectMerPet then
				arg_107_0.guild:setUseRentPet(arg_107_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "all_night_boss"
				}
			})

			var_107_0.petsA = {}

			for iter_108_0, iter_108_1 in ipairs(arg_107_0.petSelect_) do
				table.insert(var_107_0.petsA, iter_108_1)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_107_0)
		else
			arg_107_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startDreamWorldFight(arg_109_0)
	local var_109_0 = {
		herosA = {}
	}
	local var_109_1 = {}

	for iter_109_0, iter_109_1 in ipairs(arg_109_0.team_) do
		iter_109_1.data.type = iter_109_1.type

		if iter_109_1.type == var_0_18.RENT_HERO then
			-- block empty
		else
			table.insert(var_109_1, iter_109_1.data)
		end

		table.insert(var_109_0.herosA, iter_109_1.data)
	end

	var_109_0.campaignType = arg_109_0.campaignType
	var_109_0.campaignID = arg_109_0.campaignID
	var_109_0.itemComposeID = arg_109_0.itemComposeID
	var_109_0.battleID = arg_109_0:getBattleID()

	local var_109_2 = arg_109_0:getFormationStr(var_109_1)
	local var_109_3 = {
		campaign_id = var_109_0.campaignID,
		campaign_type = var_109_0.campaignType,
		formation = var_109_2
	}
	local var_109_4

	if #arg_109_0.petTeam_ ~= 0 and not arg_109_0.isSelectMerPet then
		var_109_4 = arg_109_0.petTeam_[1].data:getPetID()
	end

	var_109_3.pet_id = var_109_4

	local var_109_5 = var_0_15:monsters(var_109_0.battleID)

	var_109_0.herosB = {}

	for iter_109_2 = 1, #var_109_5 do
		local var_109_6 = {}

		for iter_109_3, iter_109_4 in ipairs(var_109_5[iter_109_2]) do
			local var_109_7 = var_0_1.new()

			var_109_7:populateWithTableID(iter_109_4)
			table.insert(var_109_6, var_109_7)
		end

		if next(var_109_6) then
			table.insert(var_109_0.herosB, var_109_6)
		end
	end

	for iter_109_5, iter_109_6 in pairs(var_109_0.herosA) do
		if iter_109_6.type ~= var_0_18.RENT_HERO and iter_109_6:getHeroID() > 0 then
			table.insert(var_109_1, iter_109_6)
		end
	end

	var_109_0.fightParams = var_109_3
	var_109_0.petsA = {}

	for iter_109_7, iter_109_8 in ipairs(arg_109_0.petSelect_) do
		table.insert(var_109_0.petsA, iter_109_8)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "dream_world_main"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_109_0)
end

function var_0_0.startTutorFight(arg_110_0)
	local var_110_0 = false
	local var_110_1 = {
		herosA = {},
		herosB = {}
	}
	local var_110_2 = {}

	for iter_110_0, iter_110_1 in ipairs(arg_110_0.team_) do
		iter_110_1.data.type = iter_110_1.type

		if iter_110_1.type == var_0_18.RENT_HERO then
			var_110_0 = true
		else
			table.insert(var_110_2, iter_110_1.data)
		end

		table.insert(var_110_1.herosA, iter_110_1.data)
	end

	var_110_1.rentFlag = var_110_0
	var_110_1.campaignType = arg_110_0.campaignType
	var_110_1.campaignID = arg_110_0.campaignID
	var_110_1.battleID = arg_110_0.battleID

	local var_110_3 = arg_110_0:getFormationStr(var_110_2)
	local var_110_4 = {
		campaign_id = var_110_1.campaignID,
		formation = var_110_3
	}

	arg_110_0:handleRentParams(var_110_4)

	var_110_1.fightParams = var_110_4

	local var_110_5 = xyd.tables.battle:monsters(var_110_1.battleID)

	var_110_1.herosB = {}

	for iter_110_2 = 1, 3 do
		local var_110_6 = {}

		for iter_110_3, iter_110_4 in ipairs(var_110_5[iter_110_2]) do
			local var_110_7 = var_0_1.new()

			var_110_7:populateWithTableID(iter_110_4)
			table.insert(var_110_6, var_110_7)
		end

		table.insert(var_110_1.herosB, var_110_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "tutor_exam_detail"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_110_1)
end

function var_0_0.startChocolateFight(arg_111_0)
	local var_111_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	local var_111_1 = {}
	local var_111_2 = false
	local var_111_3 = {
		herosA = {},
		herosB = {}
	}
	local var_111_4 = {}

	for iter_111_0, iter_111_1 in ipairs(arg_111_0.team_) do
		local var_111_5 = iter_111_1.data

		table.insert(var_111_4, var_111_5)
		table.insert(var_111_3.herosA, var_111_5)

		local var_111_6 = arg_111_0.reinforcePartnerRatios[var_111_5:getTableID()]

		if var_111_6 and not var_111_5.reinforceRatio then
			var_111_5.reinforceRatio = var_111_6

			if not var_111_5.isDouble then
				local var_111_7 = var_111_5.getTotalAttr

				function var_111_5.getTotalAttr(arg_112_0, arg_112_1)
					local var_112_0 = var_111_7(arg_112_0, arg_112_1)

					if var_111_5.reinforceRatio and (arg_112_1 == xyd.AttributeType.HP or arg_112_1 == xyd.AttributeType.AD or arg_112_1 == xyd.AttributeType.AP) then
						return var_112_0 + var_112_0 * var_111_5.reinforceRatio
					else
						return var_112_0
					end
				end
			end
		end
	end

	var_111_3.petsA = {}

	for iter_111_2, iter_111_3 in ipairs(arg_111_0.petSelect_) do
		table.insert(var_111_3.petsA, iter_111_3)
	end

	var_111_3.campaignType = xyd.CampaignType.CHOCOLATE
	var_111_3.campaignID = arg_111_0.campaignID
	var_111_3.battleID = arg_111_0.battleID
	var_111_3.stories = arg_111_0.stories
	var_111_3.rentFlag = var_111_2
	var_111_3.formation = arg_111_0:getFormationStr(var_111_3.herosA)

	local var_111_8 = xyd.tables.battle:monsters(var_111_3.battleID)

	var_111_3.herosB = {}

	for iter_111_4, iter_111_5 in ipairs(var_111_8) do
		local var_111_9 = {}

		for iter_111_6, iter_111_7 in ipairs(var_111_8[iter_111_4]) do
			local var_111_10 = var_0_1.new()

			var_111_10:populateWithTableID(iter_111_7)
			table.insert(var_111_9, var_111_10)
		end

		table.insert(var_111_3.herosB, var_111_9)
	end

	local var_111_11 = {
		campaign_id = arg_111_0.campaignID,
		formation = arg_111_0:getFormationStr(var_111_4)
	}
	local var_111_12

	if #arg_111_0.petTeam_ ~= 0 and not arg_111_0.isSelectMerPet then
		var_111_12 = arg_111_0.petTeam_[1].data:getPetID()
	end

	var_111_11.pet_id = var_111_12

	if arg_111_0.isSelectMerPet then
		var_111_3.rent_pet_id = arg_111_0.selectMerPet:getPetID()
	end

	if arg_111_0.selectMerPet then
		var_111_11.rent_pet_player = arg_111_0.selectMerPet.player_id
		var_111_11.rent_pet = tostring(arg_111_0.selectMerPet:getPetID())
	end

	arg_111_0:handleRentParams(var_111_11)

	var_111_3.fightParams = var_111_11

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_START_FIGHT, var_111_11, function(arg_113_0, arg_113_1)
		if arg_113_0 == xyd.error.OK then
			if arg_111_0.selectMerHero then
				arg_111_0.guild:setUseRent(arg_111_0.selectMerHero)
			end

			if arg_111_0.selectMerPet then
				arg_111_0.guild:setUseRentPet(arg_111_0.selectMerPet)
			end

			var_111_3.petsA = {}

			for iter_113_0, iter_113_1 in ipairs(arg_111_0.petSelect_) do
				table.insert(var_111_3.petsA, iter_113_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "chocolate_map"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_111_3)
		else
			arg_111_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startFourthAnniMapFight(arg_114_0)
	local var_114_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.FOURTH_ANNIVERSARY)

	arg_114_0.fourthAnni = true

	local var_114_1 = false
	local var_114_2 = {
		herosA = {},
		herosB = {}
	}
	local var_114_3 = {}

	for iter_114_0, iter_114_1 in ipairs(arg_114_0.team_) do
		local var_114_4 = iter_114_1.data

		table.insert(var_114_3, var_114_4)
		table.insert(var_114_2.herosA, var_114_4)

		local var_114_5 = arg_114_0.reinforcePartnerRatios[var_114_4:getTableID()]

		if var_114_5 and not var_114_4.reinforceRatio then
			var_114_4.reinforceRatio = var_114_5

			if not var_114_4.isDouble then
				local var_114_6 = var_114_4.getTotalAttr

				function var_114_4.getTotalAttr(arg_115_0, arg_115_1)
					local var_115_0 = var_114_6(arg_115_0, arg_115_1)

					if var_114_4.reinforceRatio and (arg_115_1 == xyd.AttributeType.HP or arg_115_1 == xyd.AttributeType.AD or arg_115_1 == xyd.AttributeType.AP) then
						return var_115_0 + var_115_0 * var_114_4.reinforceRatio
					else
						return var_115_0
					end
				end
			end
		end
	end

	var_114_2.petsA = {}

	for iter_114_2, iter_114_3 in ipairs(arg_114_0.petSelect_) do
		table.insert(var_114_2.petsA, iter_114_3)
	end

	var_114_2.campaignType = xyd.CampaignType.FOURTH_ANNI_MAP
	var_114_2.campaignID = arg_114_0.campaignID
	var_114_2.battleID = arg_114_0.battleID
	var_114_2.stories = arg_114_0.stories
	var_114_2.rentFlag = var_114_1
	var_114_2.formation = arg_114_0:getFormationStr(var_114_2.herosA)

	local var_114_7 = xyd.tables.battle:monsters(var_114_2.battleID)

	var_114_2.herosB = {}

	for iter_114_4, iter_114_5 in ipairs(var_114_7) do
		local var_114_8 = {}

		for iter_114_6, iter_114_7 in ipairs(var_114_7[iter_114_4]) do
			local var_114_9 = var_0_1.new()

			var_114_9:populateWithTableID(iter_114_7)
			table.insert(var_114_8, var_114_9)
		end

		table.insert(var_114_2.herosB, var_114_8)
	end

	if arg_114_0.isSelectMerPet then
		var_114_2.rent_pet_player = arg_114_0.selectMerPet.player_id
		var_114_2.rent_pet_id = arg_114_0.selectMerPet:getPetID()
	end

	arg_114_0:handleRentParams(var_114_2)

	if arg_114_0.selectMerHero then
		arg_114_0.guild:setUseRent(arg_114_0.selectMerHero)
	end

	if arg_114_0.selectMerPet then
		arg_114_0.guild:setUseRentPet(arg_114_0.selectMerPet)
	end

	var_114_2.petsA = {}

	for iter_114_8, iter_114_9 in ipairs(arg_114_0.petSelect_) do
		table.insert(var_114_2.petsA, iter_114_9)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "fourth_annni_map"
		}
	})

	arg_114_0.fourthAnni = false

	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_114_2)
end

function var_0_0.startRagnarokMapFight(arg_116_0)
	local var_116_0 = false
	local var_116_1 = {
		herosA = {},
		herosB = {}
	}
	local var_116_2 = {}

	for iter_116_0, iter_116_1 in ipairs(arg_116_0.team_) do
		local var_116_3 = iter_116_1.data

		table.insert(var_116_2, var_116_3)
		table.insert(var_116_1.herosA, var_116_3)

		local var_116_4 = arg_116_0.reinforcePartnerRatios[var_116_3:getTableID()]

		if var_116_4 and not var_116_3.reinforceRatio then
			var_116_3.reinforceRatio = var_116_4

			if not var_116_3.isDouble then
				local var_116_5 = var_116_3.getTotalAttr

				function var_116_3.getTotalAttr(arg_117_0, arg_117_1)
					local var_117_0 = var_116_5(arg_117_0, arg_117_1)

					if var_116_3.reinforceRatio and (arg_117_1 == xyd.AttributeType.HP or arg_117_1 == xyd.AttributeType.AD or arg_117_1 == xyd.AttributeType.AP) then
						return var_117_0 + var_117_0 * var_116_3.reinforceRatio
					else
						return var_117_0
					end
				end
			end
		end
	end

	var_116_1.petsA = {}

	for iter_116_2, iter_116_3 in ipairs(arg_116_0.petSelect_) do
		table.insert(var_116_1.petsA, iter_116_3)
	end

	var_116_1.campaignType = xyd.CampaignType.RAGNAROK_MAP
	var_116_1.campaignID = arg_116_0.campaignID
	var_116_1.battleID = arg_116_0.battleID
	var_116_1.stories = arg_116_0.stories
	var_116_1.rentFlag = var_116_0
	var_116_1.formation = arg_116_0:getFormationStr(var_116_1.herosA)

	local var_116_6 = xyd.tables.battle:monsters(var_116_1.battleID)

	var_116_1.herosB = {}

	for iter_116_4, iter_116_5 in ipairs(var_116_6) do
		local var_116_7 = {}

		for iter_116_6, iter_116_7 in ipairs(var_116_6[iter_116_4]) do
			local var_116_8 = var_0_1.new()

			var_116_8:populateWithTableID(iter_116_7)
			table.insert(var_116_7, var_116_8)
		end

		table.insert(var_116_1.herosB, var_116_7)
	end

	local var_116_9 = {
		campaign_id = arg_116_0.campaignID,
		formation = arg_116_0:getFormationStr(var_116_2)
	}
	local var_116_10

	if #arg_116_0.petTeam_ ~= 0 and not arg_116_0.isSelectMerPet then
		var_116_10 = arg_116_0.petTeam_[1].data:getPetID()
	end

	var_116_9.pet_id = var_116_10

	if arg_116_0.isSelectMerPet then
		var_116_1.rent_pet_id = arg_116_0.selectMerPet:getPetID()
	end

	if arg_116_0.selectMerPet then
		var_116_9.rent_pet_player = arg_116_0.selectMerPet.player_id
		var_116_9.rent_pet = tostring(arg_116_0.selectMerPet:getPetID())
	end

	arg_116_0:handleRentParams(var_116_9)

	var_116_1.fightParams = var_116_9
	var_116_1.star = arg_116_0.star_

	xyd.Backend.get():request(xyd.mid.RAGNAROK_START_FIGHT, var_116_9, function(arg_118_0, arg_118_1)
		if arg_118_0 == xyd.error.OK then
			if arg_116_0.selectMerHero then
				arg_116_0.guild:setUseRent(arg_116_0.selectMerHero)
			end

			if arg_116_0.selectMerPet then
				arg_116_0.guild:setUseRentPet(arg_116_0.selectMerPet)
			end

			var_116_1.petsA = {}

			for iter_118_0, iter_118_1 in ipairs(arg_116_0.petSelect_) do
				table.insert(var_116_1.petsA, iter_118_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "activity_ragnarok_map"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_116_1)
		else
			arg_116_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startAllNightMapFight(arg_119_0)
	local var_119_0 = false
	local var_119_1 = {
		herosA = {},
		herosB = {}
	}
	local var_119_2 = {}

	for iter_119_0, iter_119_1 in ipairs(arg_119_0.team_) do
		local var_119_3 = iter_119_1.data

		table.insert(var_119_2, var_119_3)
		table.insert(var_119_1.herosA, var_119_3)

		local var_119_4 = arg_119_0.reinforcePartnerRatios[var_119_3:getTableID()]

		if var_119_4 and not var_119_3.reinforceRatio then
			var_119_3.reinforceRatio = var_119_4

			if not var_119_3.isDouble then
				local var_119_5 = var_119_3.getTotalAttr

				function var_119_3.getTotalAttr(arg_120_0, arg_120_1)
					local var_120_0 = var_119_5(arg_120_0, arg_120_1)

					if var_119_3.reinforceRatio and (arg_120_1 == xyd.AttributeType.HP or arg_120_1 == xyd.AttributeType.AD or arg_120_1 == xyd.AttributeType.AP) then
						return var_120_0 + var_120_0 * var_119_3.reinforceRatio
					else
						return var_120_0
					end
				end
			end
		end
	end

	var_119_1.petsA = {}

	for iter_119_2, iter_119_3 in ipairs(arg_119_0.petSelect_) do
		table.insert(var_119_1.petsA, iter_119_3)
	end

	var_119_1.campaignType = xyd.CampaignType.ALL_NIGHT_MAP
	var_119_1.campaignID = arg_119_0.campaignID
	var_119_1.battleID = arg_119_0.battleID
	var_119_1.stories = arg_119_0.stories
	var_119_1.rentFlag = var_119_0
	var_119_1.formation = arg_119_0:getFormationStr(var_119_1.herosA)

	local var_119_6 = xyd.tables.battle:monsters(var_119_1.battleID)

	var_119_1.herosB = {}

	for iter_119_4, iter_119_5 in ipairs(var_119_6) do
		local var_119_7 = {}

		for iter_119_6, iter_119_7 in ipairs(var_119_6[iter_119_4]) do
			local var_119_8 = var_0_1.new()

			var_119_8:populateWithTableID(iter_119_7)
			table.insert(var_119_7, var_119_8)
		end

		table.insert(var_119_1.herosB, var_119_7)
	end

	local var_119_9 = {
		campaign_id = arg_119_0.campaignID,
		formation = arg_119_0:getFormationStr(var_119_2)
	}
	local var_119_10

	if #arg_119_0.petTeam_ ~= 0 and not arg_119_0.isSelectMerPet then
		var_119_10 = arg_119_0.petTeam_[1].data:getPetID()
	end

	var_119_9.pet_id = var_119_10

	if arg_119_0.isSelectMerPet then
		var_119_1.rent_pet_id = arg_119_0.selectMerPet:getPetID()
	end

	if arg_119_0.selectMerPet then
		var_119_9.rent_pet_player = arg_119_0.selectMerPet.player_id
		var_119_9.rent_pet = tostring(arg_119_0.selectMerPet:getPetID())
	end

	arg_119_0:handleRentParams(var_119_9)

	var_119_1.fightParams = var_119_9
	var_119_1.star = arg_119_0.star_

	xyd.Backend.get():request(xyd.mid.POLAR_NIGHT_START_FIGHT, var_119_9, function(arg_121_0, arg_121_1)
		if arg_121_0 == xyd.error.OK then
			if arg_119_0.selectMerHero then
				arg_119_0.guild:setUseRent(arg_119_0.selectMerHero)
			end

			if arg_119_0.selectMerPet then
				arg_119_0.guild:setUseRentPet(arg_119_0.selectMerPet)
			end

			var_119_1.petsA = {}

			for iter_121_0, iter_121_1 in ipairs(arg_119_0.petSelect_) do
				table.insert(var_119_1.petsA, iter_121_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "all_night_map"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_119_1)
		else
			arg_119_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startSuperRichChallenge(arg_122_0)
	local var_122_0 = false
	local var_122_1 = {
		herosA = {},
		herosB = {}
	}
	local var_122_2 = {}

	for iter_122_0, iter_122_1 in ipairs(arg_122_0.team_) do
		iter_122_1.data.type = iter_122_1.type

		table.insert(var_122_2, iter_122_1.data)
		table.insert(var_122_1.herosA, iter_122_1.data)
	end

	var_122_1.petsA = {}

	for iter_122_2, iter_122_3 in ipairs(arg_122_0.petSelect_) do
		table.insert(var_122_1.petsA, iter_122_3)
	end

	var_122_1.campaignType = xyd.CampaignType.SUPER_RICH_CHALLENGE
	var_122_1.campaignID = arg_122_0.campaignID
	var_122_1.battleID = arg_122_0.battleID

	local var_122_3 = arg_122_0:getFormationStr(var_122_2)

	var_122_1.fightParams = {
		campaign_id = var_122_1.campaignID,
		formation = var_122_3
	}

	local var_122_4 = xyd.tables.battle:monsters(arg_122_0.battleID)

	var_122_1.herosB = {}

	local var_122_5 = {}

	for iter_122_4, iter_122_5 in ipairs(var_122_4[1]) do
		local var_122_6 = var_0_1.new()

		var_122_6:populateWithTableID(iter_122_5)
		table.insert(var_122_5, var_122_6)
	end

	table.insert(var_122_1.herosB, var_122_5)

	function var_122_1.callback(arg_123_0)
		if arg_123_0 then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "super_rich_challenge"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_122_1)
		else
			arg_122_0.battleBegan = false
		end
	end

	xyd.WindowManager.get():openWindow("super_rich_challenge_formation", var_122_1)
end

function var_0_0.startAdventureDefenseFight(arg_124_0)
	local var_124_0 = {
		campaignType = arg_124_0.campaignType,
		campaignID = arg_124_0.campaignID,
		battleID = arg_124_0.battleID,
		monster_pos = arg_124_0.monsterPos,
		herosA = {}
	}
	local var_124_1 = {}
	local var_124_2 = false

	for iter_124_0, iter_124_1 in ipairs(arg_124_0.team_) do
		iter_124_1.data.type = iter_124_1.type

		if iter_124_1.type == var_0_18.RENT_HERO then
			var_124_2 = true
		else
			table.insert(var_124_1, iter_124_1.data)
		end

		table.insert(var_124_0.herosA, iter_124_1.data)
	end

	var_124_0.rentFlag = var_124_2
	var_124_0.formation = arg_124_0:getFormationStr(var_124_0.herosA)

	local var_124_3 = xyd.tables.battle:monsters(var_124_0.battleID)

	var_124_0.herosB = {}

	local var_124_4 = {}

	for iter_124_2, iter_124_3 in ipairs(var_124_3[1]) do
		local var_124_5 = var_0_1.new()

		var_124_5:populateWithTableID(iter_124_3)
		table.insert(var_124_4, var_124_5)
	end

	table.insert(var_124_0.herosB, var_124_4)

	local var_124_6 = {
		formation = arg_124_0:getFormationStr(var_124_1)
	}
	local var_124_7

	if #arg_124_0.petTeam_ ~= 0 and not arg_124_0.isSelectMerPet then
		var_124_7 = arg_124_0.petTeam_[1].data:getPetID()
	end

	var_124_6.pet_id = var_124_7

	if arg_124_0.isSelectMerPet then
		var_124_0.rent_pet_id = arg_124_0.selectMerPet:getPetID()
	end

	if arg_124_0.selectMerPet then
		var_124_6.rent_pet_player_id = arg_124_0.selectMerPet.player_id
		var_124_6.rent_pet_id = tostring(arg_124_0.selectMerPet:getPetID())
	end

	arg_124_0:handleRentParams(var_124_6)

	var_124_0.fightParams = var_124_6
	var_124_6.monster_pos = arg_124_0.monsterPos
	var_124_6.table_id = xyd.AdventureEventType.DEFENSE

	xyd.Backend.get():request(xyd.mid.ADVENTURE_DEFENSE_START_ROOM_FIGHT, var_124_6, function(arg_125_0, arg_125_1)
		if arg_125_0 == xyd.error.OK then
			if arg_124_0.selectMerHero then
				arg_124_0.guild:setUseRent(arg_124_0.selectMerHero)
			end

			if arg_124_0.selectMerPet then
				arg_124_0.guild:setUseRentPet(arg_124_0.selectMerPet)
			end

			var_124_0.petsA = {}

			for iter_125_0, iter_125_1 in ipairs(arg_124_0.petSelect_) do
				table.insert(var_124_0.petsA, iter_125_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "adventure_defense"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_124_0)
		else
			arg_124_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startAdventureBattleFight(arg_126_0)
	local var_126_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	local var_126_1 = {}
	local var_126_2 = {}

	for iter_126_0, iter_126_1 in ipairs(arg_126_0.team_) do
		table.insert(var_126_2, iter_126_1.data)
	end

	var_126_1.formation = arg_126_0:getFormationStr(var_126_2)

	if #arg_126_0.petTeam_ ~= 0 then
		var_126_1.pet_id = arg_126_0.petTeam_[1].data:getPetID()
	end

	var_126_0:startAdventureBattleFight(var_126_1, function(arg_127_0, arg_127_1)
		if arg_127_0 == xyd.error.OK then
			local var_127_0 = {}

			ngx.ctx.battle.reportData = json.decode(arg_127_1.battle_report)
			var_127_0.herosA = {}
			var_127_0.herosB = {}
			var_127_0.summonMonsters = {}
			var_127_0.battleType = xyd.BattleType.ReplayReport
			var_127_0.battleID = xyd.MapBattleID.ARENA
			var_127_0.campaignType = arg_126_0.campaignType

			local var_127_1 = {}
			local var_127_2 = {}

			for iter_127_0, iter_127_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_127_3 = string.sub(iter_127_0, 1, 1)
				local var_127_4 = tonumber(string.sub(iter_127_0, 3, 3))

				if var_127_3 == "A" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.None then
					local var_127_5 = var_0_1.new()

					var_127_5:populate(iter_127_1.hero)
					var_127_5:setReportData(iter_127_1)

					var_127_0.herosA[var_127_4] = var_127_5
				elseif var_127_3 == "A" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_127_6 = var_0_3.new()

					var_127_6:populate(iter_127_1.hero)
					var_127_6:setReportData(iter_127_1)

					var_127_0.petsA = {
						var_127_6
					}
				elseif var_127_3 == "B" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.None then
					local var_127_7 = var_0_1.new()

					var_127_7:populate(iter_127_1.hero)
					var_127_7:setReportData(iter_127_1)

					var_127_1[var_127_4] = var_127_7
				elseif var_127_3 == "B" and tonumber(iter_127_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_127_8 = var_0_3.new()

					var_127_8:populate(iter_127_1.hero)
					var_127_8:setReportData(iter_127_1)

					var_127_0.petsB = {
						var_127_8
					}
				elseif tonumber(iter_127_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_127_9 = var_0_1.new()

					var_127_9:populate(iter_127_1.hero)
					var_127_9:setReportData(iter_127_1)

					var_127_2[iter_127_0] = var_127_9
				end
			end

			var_127_0.reportStar = ngx.ctx.battle.reportData.star
			var_127_0.herosB = {
				var_127_1
			}
			var_127_0.summonMonsters = var_127_2

			local var_127_10 = arg_127_1.is_win

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "adventure_event"
				}
			})
			xyd.WindowManager.get():retainHistory()

			var_127_0.awards = arg_127_1.awards

			xyd.pushBattleScene(var_127_0)
		end
	end)
end

function var_0_0.startTwoYearsFight(arg_128_0)
	local var_128_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	local var_128_1 = {
		campaign_id = arg_128_0.campaignID
	}
	local var_128_2 = {}

	for iter_128_0, iter_128_1 in ipairs(arg_128_0.team_) do
		iter_128_1.data.type = iter_128_1.type

		table.insert(var_128_2, iter_128_1.data:getTableID())
	end

	var_128_1.formation = var_128_2

	local var_128_3

	if #arg_128_0.petTeam_ ~= 0 and not arg_128_0.isSelectMerPet then
		var_128_3 = arg_128_0.petTeam_[1].data:getPetID()
	end

	var_128_1.pet_id = var_128_3

	var_128_0:anniStartFight(var_128_1, function(arg_129_0, arg_129_1)
		if arg_129_0 == xyd.error.OK then
			local var_129_0 = {}
			local var_129_1 = var_128_0:getTempEnemiesInfo()
			local var_129_2 = var_128_0:getSelfHeroesInfo()

			ngx.ctx.battle.reportData = json.decode(arg_129_1.battle_report)
			var_129_0.herosA = {}
			var_129_0.herosB = {}
			var_129_0.summonMonsters = {}
			var_129_0.battleType = xyd.BattleType.ReplayReport
			var_129_0.battleID = xyd.MapBattleID.ARENA
			var_129_0.campaignType = arg_128_0.campaignType

			local var_129_3 = {}
			local var_129_4 = {}

			for iter_129_0, iter_129_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_129_5 = string.sub(iter_129_0, 1, 1)
				local var_129_6 = tonumber(string.sub(iter_129_0, 3, 3))

				if var_129_5 == "A" and tonumber(iter_129_1.summon_type) == xyd.summonMonsterType.None then
					local var_129_7 = var_0_1.new()

					var_129_7:populate(iter_129_1.hero)

					local var_129_8

					if var_129_2[tostring(var_129_7:getHeroID())] then
						var_129_8 = {}
						var_129_8.health = 1
						var_129_8.hp = var_129_2[tostring(var_129_7:getHeroID())].hp
						var_129_8.mp = var_129_2[tostring(var_129_7:getHeroID())].mp
						var_129_8.is_reborn = var_129_2[tostring(var_129_7:getHeroID())].is_reborn
					end

					var_129_7.healthStatus = var_129_8

					var_129_7:setReportData(iter_129_1)

					var_129_0.herosA[var_129_6] = var_129_7
				elseif var_129_5 == "A" and tonumber(iter_129_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_129_9 = var_0_3.new()

					var_129_9:populate(iter_129_1.hero)
					var_129_9:setReportData(iter_129_1)

					var_129_0.petsA = {
						var_129_9
					}
				elseif var_129_5 == "B" and tonumber(iter_129_1.summon_type) == xyd.summonMonsterType.None then
					local var_129_10 = var_0_1.new()

					var_129_10:populate(iter_129_1.hero)

					local var_129_11

					if var_129_1[tostring(var_129_10:getTableID())] then
						var_129_11 = {}
						var_129_11.health = 1
						var_129_11.hp = var_129_1[tostring(var_129_10:getTableID())].hp
						var_129_11.mp = var_129_1[tostring(var_129_10:getTableID())].mp
						var_129_11.is_reborn = var_129_1[tostring(var_129_10:getTableID())].is_reborn
					end

					var_129_10.healthStatus = var_129_11

					var_129_10:setReportData(iter_129_1)

					var_129_3[var_129_6] = var_129_10
				elseif var_129_5 == "B" and tonumber(iter_129_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_129_12 = var_0_3.new()

					var_129_12:populate(iter_129_1.hero)
					var_129_12:setReportData(iter_129_1)

					var_129_0.petsB = {
						var_129_12
					}
				elseif tonumber(iter_129_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_129_13 = var_0_1.new()

					var_129_13:populate(iter_129_1.hero)
					var_129_13:setReportData(iter_129_1)

					var_129_4[iter_129_0] = var_129_13
				end
			end

			var_129_0.reportStar = ngx.ctx.battle.reportData.star
			var_129_0.herosB = {
				var_129_3
			}
			var_129_0.summonMonsters = var_129_4

			local var_129_14 = arg_129_1.is_win
			local var_129_15 = {}

			if arg_129_1.awards then
				var_129_0.twoYearsAwards = arg_129_1.awards
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "two_years_main"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_129_0)
		end
	end)
end

function var_0_0.startMemoriesOfSchoolBattle(arg_130_0)
	arg_130_0.memoriesOfSchool:startFight({
		grid_pos = arg_130_0.memoriesOfSchool:getBattleGrid()
	}, function(arg_131_0, arg_131_1)
		if arg_131_0 == xyd.error.OK then
			local var_131_0 = false
			local var_131_1 = {
				herosA = {},
				herosB = {}
			}
			local var_131_2 = {}

			for iter_131_0, iter_131_1 in ipairs(arg_130_0.team_) do
				iter_131_1.data.type = iter_131_1.type

				if iter_131_1.type == var_0_18.RENT_HERO then
					var_131_0 = true
				else
					table.insert(var_131_2, iter_131_1.data)
				end

				table.insert(var_131_1.herosA, iter_131_1.data)
			end

			var_131_1.rentFlag = var_131_0
			var_131_1.campaignType = arg_130_0.campaignType
			var_131_1.campaignID = arg_130_0.campaignID
			var_131_1.battleID = arg_130_0.battleID

			local var_131_3 = arg_130_0:getFormationStr(var_131_2)
			local var_131_4 = {
				campaign_id = var_131_1.campaignID,
				formation = var_131_3
			}

			arg_130_0:handleRentParams(var_131_4)

			var_131_1.fightParams = var_131_4
			var_131_1.formation = var_131_3

			local var_131_5

			if #arg_130_0.petTeam_ ~= 0 and not arg_130_0.isSelectMerPet then
				var_131_5 = arg_130_0.petTeam_[1].data:getPetID()
			end

			var_131_4.pet_id = var_131_5
			var_131_1.pet_id = var_131_5
			var_131_1.petsA = {}

			for iter_131_2, iter_131_3 in ipairs(arg_130_0.petSelect_) do
				table.insert(var_131_1.petsA, iter_131_3)
			end

			local var_131_6 = xyd.tables.battle:monsters(var_131_1.battleID)
			local var_131_7, var_131_8 = arg_130_0.memoriesOfSchool:getTempEnemiesInfo()

			var_131_1.currentGroup = tonumber(var_131_8)
			var_131_1.herosB = {}

			for iter_131_4 = 1, #var_131_6 do
				local var_131_9 = {}

				for iter_131_5, iter_131_6 in ipairs(var_131_6[iter_131_4]) do
					local var_131_10 = var_0_1.new()

					var_131_10:populateWithTableID(iter_131_6)

					if var_131_7[tostring(iter_131_6)] then
						local var_131_11 = {}

						var_131_11.health = 1
						var_131_11.hp = var_131_7[tostring(iter_131_6)].hp
						var_131_11.is_reborn = var_131_7[tostring(iter_131_6)].is_reborn
						var_131_11.mp = var_131_7[tostring(iter_131_6)].mp
						var_131_10.healthStatus = var_131_11
					end

					table.insert(var_131_9, var_131_10)
				end

				if #var_131_9 ~= 0 then
					table.insert(var_131_1.herosB, var_131_9)
				end
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "memories_of_school"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_131_1)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("MEMROIES_OF_SCHOOL_ENERGY_NOT_ENOUGH")
			})
		end
	end)
end

function var_0_0.startMemoriesOfSchoolPVPBattle(arg_132_0)
	local var_132_0 = false
	local var_132_1 = {
		herosA = {},
		herosB = {}
	}
	local var_132_2 = {}

	for iter_132_0, iter_132_1 in ipairs(arg_132_0.team_) do
		iter_132_1.data.type = iter_132_1.type

		if iter_132_1.type == var_0_18.RENT_HERO then
			var_132_0 = true
		else
			table.insert(var_132_2, iter_132_1.data)
		end

		table.insert(var_132_1.herosA, iter_132_1.data)
	end

	var_132_1.rentFlag = var_132_0
	var_132_1.campaignType = arg_132_0.campaignType
	var_132_1.campaignID = arg_132_0.campaignID
	var_132_1.battleID = arg_132_0.battleID

	local var_132_3 = arg_132_0:getFormationStr(var_132_2)
	local var_132_4 = {
		campaign_id = var_132_1.campaignID,
		formation = var_132_3
	}

	arg_132_0:handleRentParams(var_132_4)

	var_132_1.fightParams = var_132_4
	var_132_1.formation = var_132_3
	var_132_1.herosB = {}

	local var_132_5

	if #arg_132_0.petTeam_ ~= 0 and not arg_132_0.isSelectMerPet then
		var_132_5 = arg_132_0.petTeam_[1].data:getPetID()
	end

	arg_132_0.memoriesOfSchool:fightPlayer({
		grid_pos = arg_132_0.memoriesOfSchool:getBattleGrid(),
		formation = var_132_3,
		pet_id = var_132_5
	}, function(arg_133_0, arg_133_1)
		if arg_133_0 == xyd.error.OK then
			local var_133_0 = {}
			local var_133_1, var_133_2 = arg_132_0.memoriesOfSchool:getTempEnemiesInfo()

			ngx.ctx.battle.reportData = json.decode(arg_133_1.battle_info.battle_report)
			var_133_0.herosA = {}
			var_133_0.herosB = {}
			var_133_0.summonMonsters = {}
			var_133_0.battleType = xyd.BattleType.ReplayReport
			var_133_0.battleID = xyd.MapBattleID.ARENA
			var_133_0.campaignType = arg_132_0.campaignType

			local var_133_3 = {}
			local var_133_4 = {}

			for iter_133_0, iter_133_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_133_5 = string.sub(iter_133_0, 1, 1)
				local var_133_6 = tonumber(string.sub(iter_133_0, 3, 3))

				if var_133_5 == "A" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.None then
					local var_133_7 = var_0_1.new()

					var_133_7:populate(iter_133_1.hero)
					var_133_7:setReportData(iter_133_1)

					var_133_0.herosA[var_133_6] = var_133_7
				elseif var_133_5 == "A" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_133_8 = var_0_3.new()

					var_133_8:populate(iter_133_1.hero)
					var_133_8:setReportData(iter_133_1)

					var_133_0.petsA = {
						var_133_8
					}
				elseif var_133_5 == "B" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.None then
					local var_133_9 = var_0_1.new()

					var_133_9:populate(iter_133_1.hero)

					local var_133_10

					if var_133_1[tostring(var_133_9:getHeroID())] then
						var_133_10 = {}
						var_133_10.health = 1
						var_133_10.hp = var_133_1[tostring(var_133_9:getHeroID())].hp
						var_133_10.mp = var_133_1[tostring(var_133_9:getHeroID())].mp
						var_133_10.is_reborn = var_133_1[tostring(var_133_9:getHeroID())].is_reborn
					end

					var_133_9.healthStatus = var_133_10

					var_133_9:setReportData(iter_133_1)

					var_133_3[var_133_6] = var_133_9
				elseif var_133_5 == "B" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_133_11 = var_0_3.new()

					var_133_11:populate(iter_133_1.hero)
					var_133_11:setReportData(iter_133_1)

					var_133_0.petsB = {
						var_133_11
					}
				elseif tonumber(iter_133_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_133_12 = var_0_1.new()

					var_133_12:populate(iter_133_1.hero)
					var_133_12:setReportData(iter_133_1)

					var_133_4[iter_133_0] = var_133_12
				end
			end

			var_133_0.reportStar = ngx.ctx.battle.reportData.star
			var_133_0.herosB = {
				var_133_3
			}
			var_133_0.summonMonsters = var_133_4

			local var_133_13 = 0

			if arg_133_1.battle_info.star > 0 then
				var_133_13 = 1
			end

			local var_133_14 = var_133_13
			local var_133_15 = {}

			if arg_133_1.battle_info.library_mission_formations.partner_favor then
				for iter_133_2, iter_133_3 in pairs(arg_133_1.battle_info.library_mission_formations.partner_favor) do
					if iter_133_3 > arg_132_0.selfPlayer:getHero(tonumber(iter_133_2)):getFavorDegree() then
						var_133_15[tonumber(iter_133_2)] = true

						arg_132_0.selfPlayer:getHero(tonumber(iter_133_2)):setFavorDegree(iter_133_3)
					end
				end

				var_133_0.favorDegreeUp = var_133_15
			end

			if arg_133_1.awards then
				var_133_0.memories_awards = arg_133_1.awards
			end

			var_133_0.pvp = 1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "memories_of_school"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_133_0)
		end
	end)
end

function var_0_0.startNianBossBattle(arg_134_0)
	local var_134_0 = false
	local var_134_1 = {
		herosA = {},
		herosB = {}
	}
	local var_134_2 = {}

	for iter_134_0, iter_134_1 in ipairs(arg_134_0.team_) do
		iter_134_1.data.type = iter_134_1.type

		if iter_134_1.type == var_0_18.RENT_HERO then
			var_134_0 = true
		else
			table.insert(var_134_2, iter_134_1.data)
		end

		table.insert(var_134_1.herosA, iter_134_1.data)
	end

	var_134_1.rentFlag = var_134_0
	var_134_1.campaignType = arg_134_0.campaignType
	var_134_1.campaignID = arg_134_0.campaignID
	var_134_1.battleID = xyd.tables.nianBoss.fight_id[arg_134_0.campaignID]

	local var_134_3 = arg_134_0:getFormationStr(var_134_2)
	local var_134_4 = {
		campaign_id = var_134_1.campaignID,
		formation = var_134_3
	}

	arg_134_0:handleRentParams(var_134_4)

	var_134_1.fightParams = var_134_4

	local var_134_5 = xyd.tables.battle:monsters(var_134_1.battleID)

	var_134_1.herosB = {}

	for iter_134_2 = 1, #var_134_5 do
		local var_134_6 = {}

		for iter_134_3, iter_134_4 in ipairs(var_134_5[iter_134_2]) do
			local var_134_7 = var_0_1.new()

			var_134_7:populateWithTableID(iter_134_4)
			table.insert(var_134_6, var_134_7)
		end

		table.insert(var_134_1.herosB, var_134_6)
	end

	xyd.Backend.get():request(xyd.mid.NIAN_BOSS_START_FIGHT, var_134_4, function(arg_135_0, arg_135_1)
		if arg_135_0 == xyd.error.OK then
			if arg_134_0.selectMerHero then
				arg_134_0.guild:setUseRent(arg_134_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "nian_boss_battle_pre"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_134_1)
		else
			arg_134_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startThiefBossBattle(arg_136_0)
	local var_136_0 = false
	local var_136_1 = {
		herosA = {},
		herosB = {}
	}
	local var_136_2 = {}

	for iter_136_0, iter_136_1 in ipairs(arg_136_0.team_) do
		iter_136_1.data.type = iter_136_1.type

		if iter_136_1.type == var_0_18.RENT_HERO then
			var_136_0 = true
		else
			table.insert(var_136_2, iter_136_1.data)
		end

		table.insert(var_136_1.herosA, iter_136_1.data)
	end

	var_136_1.rentFlag = var_136_0
	var_136_1.campaignType = arg_136_0.campaignType
	var_136_1.campaignID = arg_136_0.campaignID
	var_136_1.battleID = xyd.tables.nianBoss.fight_id[arg_136_0.campaignID]

	local var_136_3 = arg_136_0:getFormationStr(var_136_2)
	local var_136_4 = {
		campaign_id = var_136_1.campaignID,
		formation = var_136_3
	}

	arg_136_0:handleRentParams(var_136_4)

	var_136_1.fightParams = var_136_4

	local var_136_5 = xyd.tables.battle:monsters(var_136_1.battleID)

	var_136_1.herosB = {}

	for iter_136_2 = 1, #var_136_5 do
		local var_136_6 = {}

		for iter_136_3, iter_136_4 in ipairs(var_136_5[iter_136_2]) do
			local var_136_7 = var_0_1.new()

			var_136_7:populateWithTableID(iter_136_4)
			table.insert(var_136_6, var_136_7)
		end

		table.insert(var_136_1.herosB, var_136_6)
	end

	xyd.Backend.get():request(xyd.mid.NIAN_BOSS_START_FIGHT, var_136_4, function(arg_137_0, arg_137_1)
		if arg_137_0 == xyd.error.OK then
			if arg_136_0.selectMerHero then
				arg_136_0.guild:setUseRent(arg_136_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "thief_boss_battle_pre"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_136_1)
		else
			arg_136_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startSingleDayBattle(arg_138_0)
	local var_138_0 = false
	local var_138_1 = {
		missionID = arg_138_0.missionID,
		herosA = {},
		herosB = {}
	}
	local var_138_2 = {}

	for iter_138_0, iter_138_1 in ipairs(arg_138_0.team_) do
		iter_138_1.data.type = iter_138_1.type

		if iter_138_1.type == var_0_18.RENT_HERO then
			var_138_0 = true
		else
			table.insert(var_138_2, iter_138_1.data)
		end

		table.insert(var_138_1.herosA, iter_138_1.data)
	end

	var_138_1.rentFlag = var_138_0
	var_138_1.campaignType = arg_138_0.campaignType
	var_138_1.campaignID = arg_138_0.campaignID
	var_138_1.battleID = arg_138_0.battleID

	local var_138_3 = arg_138_0:getFormationStr(var_138_2)
	local var_138_4 = {
		campaign_id = var_138_1.campaignID,
		formation = var_138_3
	}

	arg_138_0:handleRentParams(var_138_4)

	var_138_1.fightParams = var_138_4

	local var_138_5 = xyd.tables.battle:monsters(var_138_1.battleID)

	var_138_1.herosB = {}

	for iter_138_2 = 1, 1 do
		local var_138_6 = {}

		for iter_138_3, iter_138_4 in ipairs(var_138_5[iter_138_2]) do
			local var_138_7 = var_0_1.new()

			var_138_7:populateWithTableID(iter_138_4)
			table.insert(var_138_6, var_138_7)
		end

		table.insert(var_138_1.herosB, var_138_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "single_day"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_138_1)
end

function var_0_0.startAdventureIllusionSingleFight(arg_139_0)
	local var_139_0 = {
		campaignType = arg_139_0.campaignType,
		campaignID = arg_139_0.campaignID,
		battleID = xyd.tables.illusionCampaign:fightId(arg_139_0.campaignID),
		herosA = {}
	}
	local var_139_1 = {}
	local var_139_2 = false

	for iter_139_0, iter_139_1 in ipairs(arg_139_0.team_) do
		iter_139_1.data.type = iter_139_1.type

		if iter_139_1.type == var_0_18.RENT_HERO then
			var_139_2 = true
		else
			table.insert(var_139_1, iter_139_1.data)
		end

		table.insert(var_139_0.herosA, iter_139_1.data)
	end

	var_139_0.rentFlag = var_139_2

	local var_139_3 = xyd.tables.battle:monsters(var_139_0.battleID)

	var_139_0.herosB = {}

	local var_139_4 = {}

	for iter_139_2, iter_139_3 in ipairs(var_139_3[1]) do
		local var_139_5 = var_0_1.new()

		var_139_5:populateWithTableID(iter_139_3)
		table.insert(var_139_4, var_139_5)
	end

	table.insert(var_139_0.herosB, var_139_4)

	local var_139_6 = {
		formation = arg_139_0:getFormationStr(var_139_1)
	}
	local var_139_7

	if #arg_139_0.petTeam_ ~= 0 and not arg_139_0.isSelectMerPet then
		var_139_7 = arg_139_0.petTeam_[1].data:getPetID()
	end

	var_139_6.pet_id = var_139_7

	if arg_139_0.isSelectMerPet then
		var_139_0.rent_pet_id = arg_139_0.selectMerPet:getPetID()
	end

	if arg_139_0.selectMerPet then
		var_139_6.rent_pet_player_id = arg_139_0.selectMerPet.player_id
		var_139_6.rent_pet_id = tostring(arg_139_0.selectMerPet:getPetID())
	end

	arg_139_0:handleRentParams(var_139_6)

	var_139_0.fightParams = var_139_6

	xyd.Backend.get():request(xyd.mid.START_PARADISE_FIGHT, var_139_6, function(arg_140_0, arg_140_1)
		if arg_140_0 == xyd.error.OK then
			if arg_139_0.selectMerHero then
				arg_139_0.guild:setUseRent(arg_139_0.selectMerHero)
			end

			if arg_139_0.selectMerPet then
				arg_139_0.guild:setUseRentPet(arg_139_0.selectMerPet)
			end

			var_139_0.petsA = {}

			for iter_140_0, iter_140_1 in ipairs(arg_139_0.petSelect_) do
				table.insert(var_139_0.petsA, iter_140_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "adventure_event"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_139_0)
		else
			arg_139_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startIllusionBattle(arg_141_0)
	local var_141_0 = {
		campaignType = arg_141_0.campaignType,
		campaignID = arg_141_0.campaignID,
		battleID = xyd.tables.illusionCampaign:fightId(arg_141_0.campaignID),
		herosA = {}
	}
	local var_141_1 = {}
	local var_141_2 = false

	for iter_141_0, iter_141_1 in ipairs(arg_141_0.team_) do
		iter_141_1.data.type = iter_141_1.type

		if iter_141_1.type == var_0_18.RENT_HERO then
			var_141_2 = true
		else
			table.insert(var_141_1, iter_141_1.data)
		end

		table.insert(var_141_0.herosA, iter_141_1.data)
	end

	var_141_0.rentFlag = var_141_2

	local var_141_3 = xyd.tables.battle:monsters(var_141_0.battleID)

	var_141_0.herosB = {}

	local var_141_4 = {}

	for iter_141_2, iter_141_3 in ipairs(var_141_3[1]) do
		local var_141_5 = var_0_1.new()

		var_141_5:populateWithTableID(iter_141_3)
		table.insert(var_141_4, var_141_5)
	end

	table.insert(var_141_0.herosB, var_141_4)

	local var_141_6 = {
		formation = arg_141_0:getFormationStr(var_141_1)
	}
	local var_141_7

	if #arg_141_0.petTeam_ ~= 0 and not arg_141_0.isSelectMerPet then
		var_141_7 = arg_141_0.petTeam_[1].data:getPetID()
	end

	var_141_6.pet_id = var_141_7

	if arg_141_0.isSelectMerPet then
		var_141_0.rent_pet_id = arg_141_0.selectMerPet:getPetID()
	end

	if arg_141_0.selectMerPet then
		var_141_6.rent_pet_player_id = arg_141_0.selectMerPet.player_id
		var_141_6.rent_pet_id = tostring(arg_141_0.selectMerPet:getPetID())
	end

	arg_141_0:handleRentParams(var_141_6)

	var_141_0.fightParams = var_141_6

	xyd.Backend.get():request(xyd.mid.ILLUSION_START_FIGHT, var_141_6, function(arg_142_0, arg_142_1)
		if arg_142_0 == xyd.error.OK then
			if arg_141_0.selectMerHero then
				arg_141_0.guild:setUseRent(arg_141_0.selectMerHero)
			end

			if arg_141_0.selectMerPet then
				arg_141_0.guild:setUseRentPet(arg_141_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "illusion_detail"
				}
			})

			var_141_0.petsA = {}

			for iter_142_0, iter_142_1 in ipairs(arg_141_0.petSelect_) do
				table.insert(var_141_0.petsA, iter_142_1)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_141_0)
		else
			arg_141_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startStudentBattle(arg_143_0)
	local var_143_0 = false
	local var_143_1 = {
		herosA = {},
		herosB = {}
	}
	local var_143_2 = {}

	for iter_143_0, iter_143_1 in ipairs(arg_143_0.team_) do
		iter_143_1.data.type = iter_143_1.type

		if iter_143_1.type == var_0_18.RENT_HERO then
			var_143_0 = true
		else
			table.insert(var_143_2, iter_143_1.data)
		end

		table.insert(var_143_1.herosA, iter_143_1.data)
	end

	var_143_1.rentFlag = var_143_0
	var_143_1.campaignType = arg_143_0.campaignType
	var_143_1.campaignID = arg_143_0.campaignID
	var_143_1.battleID = xyd.tables.campaign:fightID(arg_143_0.campaignID)

	local var_143_3 = arg_143_0:getFormationStr(var_143_2)

	var_143_1.fightParams = {
		campaign_id = var_143_1.campaignID,
		formation = var_143_3
	}
	var_143_1.formation = var_143_3

	local var_143_4 = xyd.tables.battle:monsters(var_143_1.battleID)

	var_143_1.herosB = {}

	for iter_143_2 = 1, #var_143_4 do
		local var_143_5 = {}

		for iter_143_3, iter_143_4 in ipairs(var_143_4[iter_143_2]) do
			local var_143_6 = var_0_1.new()

			var_143_6:populateWithTableID(iter_143_4)
			table.insert(var_143_5, var_143_6)
		end

		table.insert(var_143_1.herosB, var_143_5)
	end

	var_143_1.petsA = {}

	for iter_143_5, iter_143_6 in ipairs(arg_143_0.petSelect_) do
		table.insert(var_143_1.petsA, iter_143_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "teacher"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_143_1)
end

function var_0_0.startZhugeNoteBattle(arg_144_0)
	local var_144_0 = false
	local var_144_1 = {
		herosA = {},
		herosB = {}
	}
	local var_144_2 = {}

	for iter_144_0, iter_144_1 in ipairs(arg_144_0.team_) do
		iter_144_1.data.type = iter_144_1.type

		if iter_144_1.type == var_0_18.RENT_HERO then
			var_144_0 = true
		else
			table.insert(var_144_2, iter_144_1.data)
		end

		table.insert(var_144_1.herosA, iter_144_1.data)
	end

	var_144_1.rentFlag = var_144_0
	var_144_1.campaignType = arg_144_0.campaignType
	var_144_1.campaignID = arg_144_0.campaignID
	var_144_1.battleID = arg_144_0.battleID

	local var_144_3 = arg_144_0:getFormationStr(var_144_2)

	var_144_1.fightParams = {
		campaign_id = var_144_1.campaignID,
		formation = var_144_3
	}
	var_144_1.formation = var_144_3

	local var_144_4 = xyd.tables.battle:monsters(var_144_1.battleID)

	var_144_1.herosB = {}

	for iter_144_2 = 1, #var_144_4 do
		local var_144_5 = {}

		for iter_144_3, iter_144_4 in ipairs(var_144_4[iter_144_2]) do
			local var_144_6 = var_0_1.new()

			var_144_6:populateWithTableID(iter_144_4)
			table.insert(var_144_5, var_144_6)
		end

		if var_144_5 and next(var_144_5) then
			table.insert(var_144_1.herosB, var_144_5)
		end
	end

	var_144_1.petsA = {}

	for iter_144_5, iter_144_6 in ipairs(arg_144_0.petSelect_) do
		table.insert(var_144_1.petsA, iter_144_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_small_house"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_144_1)
end

function var_0_0.startZhugeBossBattle(arg_145_0)
	local var_145_0 = false
	local var_145_1 = {
		herosA = {},
		herosB = {}
	}
	local var_145_2 = {}

	for iter_145_0, iter_145_1 in ipairs(arg_145_0.team_) do
		iter_145_1.data.type = iter_145_1.type

		if iter_145_1.type == var_0_18.RENT_HERO then
			var_145_0 = true
		else
			table.insert(var_145_2, iter_145_1.data)
		end

		table.insert(var_145_1.herosA, iter_145_1.data)
	end

	var_145_1.rentFlag = var_145_0
	var_145_1.campaignType = arg_145_0.campaignType
	var_145_1.campaignID = arg_145_0.campaignID
	var_145_1.battleID = arg_145_0.battleID

	local var_145_3 = arg_145_0:getFormationStr(var_145_2)

	var_145_1.fightParams = {
		campaign_id = var_145_1.campaignID,
		formation = var_145_3
	}
	var_145_1.formation = var_145_3

	local var_145_4 = xyd.tables.battle:monsters(var_145_1.battleID)

	var_145_1.herosB = {}

	for iter_145_2 = 1, 1 do
		local var_145_5 = {}

		for iter_145_3, iter_145_4 in ipairs(var_145_4[iter_145_2]) do
			local var_145_6 = var_0_1.new()

			var_145_6:populateWithTableID(iter_145_4)
			table.insert(var_145_5, var_145_6)
		end

		table.insert(var_145_1.herosB, var_145_5)
	end

	var_145_1.petsA = {}

	for iter_145_5, iter_145_6 in ipairs(arg_145_0.petSelect_) do
		table.insert(var_145_1.petsA, iter_145_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_small_house"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_145_1)
end

function var_0_0.startSakuraBattle(arg_146_0)
	local var_146_0 = false
	local var_146_1 = {
		herosA = {},
		herosB = {}
	}
	local var_146_2 = {}

	for iter_146_0, iter_146_1 in ipairs(arg_146_0.team_) do
		iter_146_1.data.type = iter_146_1.type

		if iter_146_1.type == var_0_18.RENT_HERO then
			var_146_0 = true
		else
			table.insert(var_146_2, iter_146_1.data)
		end

		table.insert(var_146_1.herosA, iter_146_1.data)
	end

	var_146_1.rentFlag = var_146_0
	var_146_1.campaignType = arg_146_0.campaignType
	var_146_1.campaignID = arg_146_0.campaignID
	var_146_1.battleID = xyd.tables.campaign:fightID(arg_146_0.campaignID)

	local var_146_3 = arg_146_0:getFormationStr(var_146_2)
	local var_146_4 = {
		formation = var_146_3
	}

	arg_146_0:handleRentParams(var_146_4)

	var_146_1.fightParams = var_146_4

	local var_146_5 = xyd.tables.battle:monsters(var_146_1.battleID)

	var_146_1.herosB = {}

	for iter_146_2 = 1, #var_146_5 do
		local var_146_6 = {}

		for iter_146_3, iter_146_4 in ipairs(var_146_5[iter_146_2]) do
			local var_146_7 = var_0_1.new()

			var_146_7:populateWithTableID(iter_146_4)
			table.insert(var_146_6, var_146_7)
		end

		table.insert(var_146_1.herosB, var_146_6)
	end

	var_146_1.star = arg_146_0.star_

	xyd.Backend.get():request(xyd.mid.SAKURA_START_FIGHT, var_146_4, function(arg_147_0, arg_147_1)
		if arg_147_0 == xyd.error.OK then
			if arg_147_1.items then
				local var_147_0 = {}

				for iter_147_0, iter_147_1 in ipairs(arg_147_1.items) do
					for iter_147_2 = 1, iter_147_1.item_num do
						local var_147_1 = var_0_12.new()

						var_147_1:populate({
							table_id = iter_147_1.item_id
						})
						var_147_1:initDrop(arg_146_0.campaignID)
						table.insert(var_147_0, var_147_1)
					end
				end

				var_146_1.drops = var_147_0
			end

			local var_147_2 = clone(var_146_5)
			local var_147_3 = xyd.tables.campaign:gainMana(arg_146_0.campaignID)

			if var_147_3 > 0 then
				local var_147_4 = 0

				for iter_147_3, iter_147_4 in ipairs(var_146_5) do
					for iter_147_5, iter_147_6 in ipairs(iter_147_4) do
						var_147_4 = var_147_4 + 1
					end
				end

				local var_147_5 = xyd.tables.battleConfig.monsterDropMana
				local var_147_6 = (var_147_5 + var_147_5 + var_147_4 - 1) / 2 * var_147_4
				local var_147_7 = 0
				local var_147_8 = var_147_3

				for iter_147_7, iter_147_8 in ipairs(var_146_5) do
					for iter_147_9, iter_147_10 in ipairs(iter_147_8) do
						var_147_7 = var_147_7 + 1

						if var_147_7 ~= var_147_4 then
							var_147_2[iter_147_7][iter_147_9] = math.ceil(var_147_3 / var_147_6 * (var_147_5 + var_147_7 - 1))
							var_147_8 = var_147_8 - var_147_2[iter_147_7][iter_147_9]
						else
							var_147_2[iter_147_7][iter_147_9] = var_147_8
						end
					end
				end

				var_146_1.dropMana = var_147_2
			end

			if arg_146_0.selectMerHero then
				arg_146_0.guild:setUseRent(arg_146_0.selectMerHero)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_146_1)
		else
			arg_146_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startPetBattle(arg_148_0, arg_148_1)
	local var_148_0 = false
	local var_148_1 = {
		herosA = {},
		herosB = {}
	}

	if arg_148_1 then
		var_148_1.noResult = true
	end

	local var_148_2 = {}

	for iter_148_0, iter_148_1 in ipairs(arg_148_0.team_) do
		iter_148_1.data.type = iter_148_1.type

		if iter_148_1.type == var_0_18.RENT_HERO then
			var_148_0 = true
		else
			table.insert(var_148_2, iter_148_1.data)
		end

		table.insert(var_148_1.herosA, iter_148_1.data)
	end

	var_148_1.rentFlag = var_148_0
	var_148_1.campaignType = arg_148_0.campaignType
	var_148_1.campaignID = arg_148_0.campaignID
	var_148_1.battleID = xyd.tables.campaign:fightID(arg_148_0.campaignID)

	local var_148_3 = arg_148_0:getFormationStr(var_148_2)
	local var_148_4 = {
		campaign_id = var_148_1.campaignID,
		formation = var_148_3
	}

	arg_148_0:handleRentParams(var_148_4)

	var_148_1.fightParams = var_148_4

	local var_148_5 = xyd.tables.battle:monsters(var_148_1.battleID)

	var_148_1.herosB = {}

	for iter_148_2 = 1, #var_148_5 do
		if #var_148_5[iter_148_2] > 0 then
			local var_148_6 = {}

			for iter_148_3, iter_148_4 in ipairs(var_148_5[iter_148_2]) do
				local var_148_7 = var_0_1.new()

				var_148_7:populateWithTableID(iter_148_4)
				table.insert(var_148_6, var_148_7)
			end

			table.insert(var_148_1.herosB, var_148_6)
		end
	end

	var_148_1.petsA = {}

	local var_148_8

	for iter_148_5, iter_148_6 in ipairs(arg_148_0.petSelect_) do
		table.insert(var_148_1.petsA, iter_148_6)
	end

	local var_148_9

	if #arg_148_0.petTeam_ ~= 0 and not arg_148_0.isSelectMerPet then
		var_148_9 = arg_148_0.petTeam_[1].data:getPetID()
	end

	var_148_4.pet_id = var_148_9

	if arg_148_0.isSelectMerPet then
		var_148_1.rent_pet_id = arg_148_0.selectMerPet:getPetID()
	end

	if arg_148_0.selectMerPet then
		var_148_4.rent_pet_player_id = arg_148_0.selectMerPet.player_id
		var_148_4.rent_pet_id = tostring(arg_148_0.selectMerPet:getPetID())
	end

	var_148_1.petFloor = arg_148_0.petFloor
	var_148_1.petFloorType = arg_148_0.petFloorType

	local var_148_10 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

	if arg_148_1 then
		xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_PRACTICE, var_148_4, function(arg_149_0, arg_149_1)
			if arg_149_0 == xyd.error.OK then
				if arg_148_0.selectMerHero then
					arg_148_0.guild:setUseRent(arg_148_0.selectMerHero)
				end

				if arg_148_0.selectMerPet then
					arg_148_0.guild:setUseRentPet(arg_148_0.selectMerPet)
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "pet_campaign"
					}
				})

				if arg_148_0.type == xyd.SelectTeamType.PET_PRACTICE and arg_148_0.petFloor then
					var_148_10.testFormation[arg_148_0.petFloor] = {}
					var_148_10.testFormation[arg_148_0.petFloor].heros = {}

					for iter_149_0, iter_149_1 in pairs(var_148_1.herosA) do
						table.insert(var_148_10.testFormation[arg_148_0.petFloor].heros, iter_149_1:getHeroID())
					end

					if var_148_9 then
						var_148_10.testFormation[arg_148_0.petFloor].pet = var_148_9
					end
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_148_1)
			else
				arg_148_0.battleBegan = false
			end
		end, nil, false, true)
	else
		xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_FIGHT, var_148_4, function(arg_150_0, arg_150_1)
			if arg_150_0 == xyd.error.OK then
				if var_148_10.state == xyd.PetCampaignFloorType.SUPER then
					arg_148_0.selfPlayer:getBackpack():removeItem({
						itemNum = 1,
						itemID = xyd.tables.misc.skyCitySuperPaper
					})
				end

				if arg_148_0.selectMerHero then
					arg_148_0.guild:setUseRent(arg_148_0.selectMerHero)
				end

				if arg_148_0.selectMerPet then
					arg_148_0.guild:setUseRentPet(arg_148_0.selectMerPet)
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "pet_campaign"
					}
				})

				if arg_150_1 and arg_150_1.award and arg_150_1.award.item_id and arg_150_1.award.item_num then
					arg_148_0.selfPlayer:getBackpack():addItemsByID(arg_150_1.award.item_id, arg_150_1.award.item_num)
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_148_1)
			else
				arg_148_0.battleBegan = false
			end
		end, nil, false, true)
	end
end

function var_0_0.startWorldBossBattle(arg_151_0)
	local var_151_0 = false
	local var_151_1 = {
		herosA = {},
		herosB = {}
	}
	local var_151_2 = {}

	for iter_151_0, iter_151_1 in ipairs(arg_151_0.team_) do
		iter_151_1.data.type = iter_151_1.type

		if iter_151_1.type == var_0_18.RENT_HERO then
			var_151_0 = true
		else
			table.insert(var_151_2, iter_151_1.data)
		end

		table.insert(var_151_1.herosA, iter_151_1.data)
	end

	var_151_1.rentFlag = var_151_0
	var_151_1.campaignType = arg_151_0.campaignType
	var_151_1.campaignID = arg_151_0.campaignID
	var_151_1.battleID = xyd.tables.worldBoss.fight_id[arg_151_0.campaignID]

	local var_151_3 = arg_151_0:getFormationStr(var_151_2)
	local var_151_4 = {
		campaign_id = var_151_1.campaignID,
		formation = var_151_3
	}

	arg_151_0:handleRentParams(var_151_4)

	var_151_1.fightParams = var_151_4

	local var_151_5 = xyd.tables.battle:monsters(var_151_1.battleID)

	var_151_1.herosB = {}

	for iter_151_2 = 1, #var_151_5 do
		local var_151_6 = {}

		for iter_151_3, iter_151_4 in ipairs(var_151_5[iter_151_2]) do
			local var_151_7 = var_0_1.new()

			var_151_7:populateWithTableID(iter_151_4)
			table.insert(var_151_6, var_151_7)
		end

		table.insert(var_151_1.herosB, var_151_6)
	end

	xyd.Backend.get():request(xyd.mid.WORLD_BOSS_START_FIGHT, var_151_4, function(arg_152_0, arg_152_1)
		if arg_152_0 == xyd.error.OK then
			if arg_151_0.selectMerHero then
				arg_151_0.guild:setUseRent(arg_151_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "world_boss_battle_pre"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_151_1)
		else
			arg_151_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startGuildCampaignBattle(arg_153_0)
	local var_153_0 = false
	local var_153_1 = {
		herosA = {},
		herosB = {}
	}
	local var_153_2 = {}

	for iter_153_0, iter_153_1 in ipairs(arg_153_0.team_) do
		iter_153_1.data.type = iter_153_1.type

		if iter_153_1.type == var_0_18.RENT_HERO then
			var_153_0 = true
		else
			table.insert(var_153_2, iter_153_1.data)
		end

		table.insert(var_153_1.herosA, iter_153_1.data)
	end

	var_153_1.rentFlag = var_153_0
	var_153_1.campaignType = arg_153_0.campaignType
	var_153_1.campaignID = arg_153_0.campaignID
	var_153_1.battleID = xyd.tables.teamCampaign:fightID(arg_153_0.campaignID)

	local var_153_3 = arg_153_0:getFormationStr(var_153_2)
	local var_153_4 = {
		copy_id = var_153_1.campaignID,
		campaign_type = var_153_1.campaignType,
		formation = var_153_3,
		chapter_id = arg_153_0.guildChapterID
	}
	local var_153_5

	if #arg_153_0.petTeam_ ~= 0 and not arg_153_0.isSelectMerPet then
		var_153_5 = arg_153_0.petTeam_[1].data:getPetID()
	end

	var_153_4.pet_id = var_153_5

	if arg_153_0.isSelectMerPet then
		var_153_1.rent_pet_id = arg_153_0.selectMerPet:getPetID()
	end

	if arg_153_0.selectMerPet then
		var_153_4.rent_pet_player_id = arg_153_0.selectMerPet.player_id
		var_153_4.rent_pet_id = tostring(arg_153_0.selectMerPet:getPetID())
	end

	arg_153_0:handleRentParams(var_153_4)
	xyd.Backend.get():request(xyd.mid.GUILD_START_FIGHT, var_153_4, function(arg_154_0, arg_154_1)
		if arg_154_0 == xyd.error.OK then
			local function var_154_0(arg_155_0)
				local var_155_0 = var_0_1.new()

				var_155_0:populate(arg_155_0)

				var_155_0.healthStatus = {
					health = arg_155_0.health,
					hp = arg_155_0.hp,
					is_reborn = arg_155_0.is_reborn
				}
				var_155_0.guildDrop = {}

				return var_155_0
			end

			if arg_153_0.selectMerHero then
				arg_153_0.guild:setUseRent(arg_153_0.selectMerHero)
			end

			if arg_153_0.selectMerPet then
				arg_153_0.guild:setUseRentPet(arg_153_0.selectMerPet)
			end

			local var_154_1 = {
				{},
				{},
				{}
			}

			for iter_154_0, iter_154_1 in pairs(arg_154_1.enemy_status) do
				local var_154_2 = var_154_1[iter_154_0]

				for iter_154_2, iter_154_3 in ipairs(iter_154_1) do
					table.insert(var_154_2, var_154_0(iter_154_3))
				end
			end

			if arg_154_1.guild_drop and next(arg_154_1.guild_drop) then
				for iter_154_4, iter_154_5 in ipairs(arg_154_1.guild_drop) do
					local var_154_3

					for iter_154_6, iter_154_7 in ipairs(var_154_1[iter_154_5.index]) do
						if iter_154_7:getHeroID() == iter_154_5.hero_id then
							var_154_3 = iter_154_7

							break
						end
					end

					if var_154_3 ~= nil then
						for iter_154_8 = 1, iter_154_5.item_num do
							local var_154_4 = var_0_12.new()

							var_154_4:populate({
								table_id = iter_154_5.item_id
							})
							table.insert(var_154_3.guildDrop, var_154_4)
						end
					else
						print("guild drop info is invalid :")
						print(unpack(iter_154_5))
					end
				end
			end

			if arg_154_1.normal_drop and next(arg_154_1.normal_drop) then
				var_153_1.guildNormalDrop = {}

				if not arg_154_1.current_index then
					local var_154_5 = 1
				end

				for iter_154_9, iter_154_10 in ipairs(arg_154_1.normal_drop) do
					for iter_154_11 = 1, iter_154_10.item_num do
						local var_154_6 = var_0_12.new()

						var_154_6:populate({
							table_id = iter_154_10.item_id
						})
						table.insert(var_153_1.guildNormalDrop, var_154_6)
					end
				end
			end

			if arg_154_1.monster_drop and next(arg_154_1.monster_drop) then
				local var_154_7 = {}

				for iter_154_12 = 1, 10 do
					table.insert(var_154_7, {})
				end

				for iter_154_13, iter_154_14 in ipairs(arg_154_1.monster_drop) do
					for iter_154_15 = 1, iter_154_14.item_num do
						local var_154_8 = var_0_12.new()

						var_154_8:populate({
							table_id = iter_154_14.item_id
						})

						if iter_154_14.index <= #var_154_7 then
							table.insert(var_154_7[iter_154_14.index], var_154_8)
						end
					end
				end

				local var_154_9 = var_154_1[#var_154_1][1]

				if var_154_9 then
					var_154_9.monsterDrop = var_154_7
				end
			end

			var_153_1.herosB = var_154_1
			var_153_1.fightParams = var_153_4
			var_153_1.currentGroup = arg_154_1.current_index or 1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_153_0.campaignType,
						chapter = arg_153_0.guildChapterID
					}
				}
			})

			var_153_1.petsA = {}

			for iter_154_16, iter_154_17 in ipairs(arg_153_0.petSelect_) do
				table.insert(var_153_1.petsA, iter_154_17)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_153_1)
		else
			arg_153_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startChallengeBattle(arg_156_0)
	local var_156_0 = false
	local var_156_1 = {
		herosA = {},
		herosB = {}
	}
	local var_156_2 = {}

	for iter_156_0, iter_156_1 in ipairs(arg_156_0.team_) do
		iter_156_1.data.type = iter_156_1.type

		if iter_156_1.type == var_0_18.RENT_HERO then
			var_156_0 = true
		elseif iter_156_1.data:getHeroID() > 0 then
			table.insert(var_156_2, iter_156_1.data)
		end

		table.insert(var_156_1.herosA, iter_156_1.data)
	end

	var_156_1.rentFlag = var_156_0
	var_156_1.campaignType = arg_156_0.campaignType
	var_156_1.campaignID = arg_156_0.campaignID
	var_156_1.battleID = arg_156_0.battleID
	var_156_1.challengeType = var_0_15:modeType(arg_156_0.battleID)

	local var_156_3 = arg_156_0:getFormationStr(var_156_2)
	local var_156_4 = {
		campaign_id = var_156_1.campaignID,
		campaign_type = var_156_1.campaignType,
		formation = var_156_3
	}

	var_156_1.campaignType = xyd.CampaignType.CHALLENGE

	arg_156_0:handleRentParams(var_156_4)

	var_156_1.formation = var_156_3

	local var_156_5 = xyd.tables.battle:monsters(var_156_1.battleID)

	var_156_1.herosB = {}

	for iter_156_2 = 1, #var_156_5 do
		local var_156_6 = {}

		for iter_156_3, iter_156_4 in ipairs(var_156_5[iter_156_2]) do
			local var_156_7 = var_0_1.new()

			var_156_7:populateWithTableID(iter_156_4)
			table.insert(var_156_6, var_156_7)
		end

		table.insert(var_156_1.herosB, var_156_6)
	end

	xyd.Backend.get():request(xyd.mid.FIGHT, var_156_4, function(arg_157_0, arg_157_1)
		if arg_157_0 == xyd.error.OK then
			if arg_157_1.items then
				local var_157_0 = {}

				for iter_157_0, iter_157_1 in ipairs(arg_157_1.items) do
					for iter_157_2 = 1, iter_157_1.item_num do
						local var_157_1 = var_0_12.new()

						var_157_1:populate({
							table_id = iter_157_1.item_id
						})
						var_157_1:initDrop(arg_156_0.campaignID)
						table.insert(var_157_0, var_157_1)
					end
				end

				var_156_1.drops = var_157_0
			end

			local var_157_2 = clone(var_156_5)
			local var_157_3 = xyd.tables.campaign:gainMana(arg_156_0.campaignID)

			if var_157_3 > 0 then
				local var_157_4 = 0

				for iter_157_3, iter_157_4 in ipairs(var_156_5) do
					for iter_157_5, iter_157_6 in ipairs(iter_157_4) do
						var_157_4 = var_157_4 + 1
					end
				end

				local var_157_5 = xyd.tables.battleConfig.monsterDropMana
				local var_157_6 = (var_157_5 + var_157_5 + var_157_4 - 1) / 2 * var_157_4
				local var_157_7 = 0
				local var_157_8 = var_157_3

				for iter_157_7, iter_157_8 in ipairs(var_156_5) do
					for iter_157_9, iter_157_10 in ipairs(iter_157_8) do
						var_157_7 = var_157_7 + 1

						if var_157_7 ~= var_157_4 then
							var_157_2[iter_157_7][iter_157_9] = math.ceil(var_157_3 / var_157_6 * (var_157_5 + var_157_7 - 1))
							var_157_8 = var_157_8 - var_157_2[iter_157_7][iter_157_9]
						else
							var_157_2[iter_157_7][iter_157_9] = var_157_8
						end
					end
				end

				var_156_1.dropMana = var_157_2
			end

			if arg_156_0.selectMerHero then
				arg_156_0.guild:setUseRent(arg_156_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_156_0.campaignType,
						chapter = xyd.tables.campaign:chapter(var_156_1.campaignID)
					}
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_156_1)
		else
			arg_156_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.getBattleID(arg_158_0)
	local var_158_0
	local var_158_1
	local var_158_2
	local var_158_3 = false

	if arg_158_0.campaignType == xyd.CampaignType.NORMAL and arg_158_0.campaignID ~= 0 then
		local var_158_4 = xyd.tables.campaign:firstFightID(arg_158_0.campaignID)
		local var_158_5 = arg_158_0.selfPlayer.worldMaps_[arg_158_0.campaignID].star or 0

		if var_158_4 ~= 0 and var_158_5 <= 0 then
			var_158_0 = var_158_4
			var_158_3 = true
		else
			var_158_0 = arg_158_0.battleID or xyd.tables.campaign:fightID(arg_158_0.campaignID)
		end
	else
		var_158_0 = arg_158_0.battleID or xyd.tables.campaign:fightID(arg_158_0.campaignID)
	end

	return var_158_0, var_158_3
end

function var_0_0.startCampaignBattle(arg_159_0)
	local var_159_0 = false
	local var_159_1 = false
	local var_159_2 = {}
	local var_159_3 = xyd.StoryData.get():getGuideID()

	if var_159_3 == xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT then
		arg_159_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_START)

		var_159_2.isGuide = true
	elseif var_159_3 == xyd.GuideStoryType.GUIDE_FIGHT_5_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_FOUR)
		arg_159_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_5_3)
	elseif var_159_3 == xyd.GuideStoryType.GUIDE_FIGHT_3_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_END)
		arg_159_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_4)
	end

	var_159_2.herosA = {}

	for iter_159_0, iter_159_1 in ipairs(arg_159_0.team_) do
		iter_159_1.data.type = iter_159_1.type

		if iter_159_1.type == var_0_18.RENT_HERO then
			var_159_0 = true
		end

		table.insert(var_159_2.herosA, iter_159_1.data)
	end

	var_159_2.rentFlag = var_159_0
	var_159_2.campaignType = arg_159_0.campaignType
	var_159_2.campaignID = arg_159_0.campaignID
	var_159_2.itemComposeID = arg_159_0.itemComposeID

	local var_159_4

	var_159_2.battleID, var_159_4 = arg_159_0:getBattleID()

	local var_159_5 = {}

	if xyd.StoryData.get():getStoryID() <= var_159_2.battleID or arg_159_0.campaignID and (((arg_159_0.selfPlayer.worldMaps_ or {})[arg_159_0.campaignID] or {}).star or 0) <= 0 then
		local var_159_6 = var_0_15:storyHeroes(var_159_2.battleID)

		for iter_159_2, iter_159_3 in ipairs(var_159_6) do
			local var_159_7 = 0

			for iter_159_4, iter_159_5 in ipairs(var_159_2.herosA) do
				if iter_159_5:getTableID() == iter_159_3 then
					var_159_7 = iter_159_2

					break
				end
			end

			if var_159_7 > 0 then
				local var_159_8 = var_0_15:specialBefore(var_159_2.battleID)[var_159_7] or 0
				local var_159_9 = var_0_15:specialLose(var_159_2.battleID)[var_159_7] or 0
				local var_159_10 = var_0_15:specialVictory(var_159_2.battleID)[var_159_7] or 0

				var_159_5 = {
					var_159_8,
					var_159_9,
					var_159_10
				}

				break
			end
		end

		if next(var_159_5) == nil then
			local var_159_11 = var_0_15:storyBefore(var_159_2.battleID)
			local var_159_12 = var_0_15:storyLose(var_159_2.battleID)
			local var_159_13 = var_0_15:storyVictory(var_159_2.battleID)

			var_159_5 = {
				var_159_11,
				var_159_12,
				var_159_13
			}
		end

		if xyd.StoryData.get():getStoryID() == var_159_2.battleID then
			if xyd.StoryData.get():getStoryState() >= 1 then
				var_159_5[1] = 0
			end

			if xyd.StoryData.get():getStoryState() >= 2 then
				var_159_5[2] = 0
			end

			if xyd.StoryData.get():getStoryState() >= 3 then
				var_159_5[3] = 0
			end
		end

		if var_159_4 then
			var_159_5[1] = 0
		end

		var_159_2.stories = var_159_5
	end

	if arg_159_0.selfPlayer.worldMaps_[arg_159_0.campaignID] then
		var_159_2.star = arg_159_0.selfPlayer.worldMaps_[arg_159_0.campaignID].star or 0

		if var_159_2.star <= 0 then
			local var_159_14 = var_0_15:preBattleShow(var_159_2.battleID)

			var_159_2.preBattleShow = clone(var_159_14)
		end

		local var_159_15 = arg_159_0.selfPlayer.worldMaps_[arg_159_0.campaignID].is_partner_drop
		local var_159_16 = xyd.tables.campaign:storyDropPartner(arg_159_0.campaignID)

		if (not var_159_15 or var_159_15 ~= 1) and var_159_16 and next(var_159_16) and var_159_16[1] ~= 0 then
			var_159_2.isPartnerdrop = true
		end
	end

	local var_159_17 = var_0_15:monsters(var_159_2.battleID)

	var_159_2.herosB = {}

	for iter_159_6 = 1, #var_159_17 do
		local var_159_18 = {}

		for iter_159_7, iter_159_8 in ipairs(var_159_17[iter_159_6]) do
			local var_159_19 = var_0_1.new()

			var_159_19:populateWithTableID(iter_159_8)
			table.insert(var_159_18, var_159_19)
		end

		if next(var_159_18) then
			table.insert(var_159_2.herosB, var_159_18)
		end
	end

	local var_159_20 = {}

	for iter_159_9, iter_159_10 in pairs(var_159_2.herosA) do
		if iter_159_10.type ~= var_0_18.RENT_HERO and iter_159_10:getHeroID() > 0 then
			table.insert(var_159_20, iter_159_10)
		end
	end

	if var_159_4 then
		var_159_2.isAssist = true
		var_159_2.assistID = arg_159_0.assistID
	end

	if var_159_2.star and var_159_2.star >= 0 and var_0_15:escapeEnemy(var_159_2.battleID) > 0 then
		var_159_2.isEscapeStory = true
	end

	if xyd.StoryData:get():getGuideID() == xyd.GuideStoryType.GUIDE_FIGHT_2_FOUR then
		var_159_2.guideMonsterID = xyd.tables.misc.guideBreakEnemy
	end

	if arg_159_0.isAwakeCampaign then
		var_159_2.isAwakeCampaign = true
		var_159_2.awakeHero = arg_159_0.awakeHero
		var_159_2.awakeStage = arg_159_0.awakeStage
		var_159_2.awakeMissionGoalType = arg_159_0.awakeMissionGoalType
		var_159_2.awakeMissionID = arg_159_0.awakeMission.table_id
	else
		var_159_2.isAwakeCampaign = false
	end

	local var_159_21 = arg_159_0:getFormationStr(var_159_20)

	var_159_2.formation = var_159_21

	local var_159_22 = {
		campaign_id = var_159_2.campaignID,
		campaign_type = var_159_2.campaignType,
		formation = var_159_21
	}
	local var_159_23

	if #arg_159_0.petTeam_ ~= 0 and not arg_159_0.isSelectMerPet then
		var_159_23 = arg_159_0.petTeam_[1].data:getPetID()
	end

	var_159_22.pet_id = var_159_23

	if arg_159_0.isSelectMerPet then
		var_159_2.rent_pet_id = arg_159_0.selectMerPet:getPetID()
	end

	if arg_159_0.selectMerPet then
		var_159_22.rent_pet_player_id = arg_159_0.selectMerPet.player_id
		var_159_22.rent_pet_id = tostring(arg_159_0.selectMerPet:getPetID())
	end

	arg_159_0:handleRentParams(var_159_22)
	xyd.Backend.get():request(xyd.mid.FIGHT, var_159_22, function(arg_160_0, arg_160_1)
		if arg_160_0 == xyd.error.OK then
			if arg_160_1.items then
				local var_160_0 = {}

				for iter_160_0, iter_160_1 in ipairs(arg_160_1.items) do
					for iter_160_2 = 1, iter_160_1.item_num do
						local var_160_1 = var_0_12.new()

						var_160_1:populate({
							table_id = iter_160_1.item_id
						})
						var_160_1:initDrop(arg_159_0.campaignID)
						table.insert(var_160_0, var_160_1)
					end
				end

				var_159_2.drops = var_160_0
			end

			local var_160_2 = clone(var_159_17)
			local var_160_3 = xyd.tables.campaign:gainMana(arg_159_0.campaignID)

			if var_160_3 > 0 then
				local var_160_4 = 0

				for iter_160_3, iter_160_4 in ipairs(var_159_17) do
					for iter_160_5, iter_160_6 in ipairs(iter_160_4) do
						var_160_4 = var_160_4 + 1
					end
				end

				local var_160_5 = xyd.tables.battleConfig.monsterDropMana
				local var_160_6 = (var_160_5 + var_160_5 + var_160_4 - 1) / 2 * var_160_4
				local var_160_7 = 0
				local var_160_8 = var_160_3

				for iter_160_7, iter_160_8 in ipairs(var_159_17) do
					for iter_160_9, iter_160_10 in ipairs(iter_160_8) do
						var_160_7 = var_160_7 + 1

						if var_160_7 ~= var_160_4 then
							var_160_2[iter_160_7][iter_160_9] = math.ceil(var_160_3 / var_160_6 * (var_160_5 + var_160_7 - 1))
							var_160_8 = var_160_8 - var_160_2[iter_160_7][iter_160_9]
						else
							var_160_2[iter_160_7][iter_160_9] = var_160_8
						end
					end
				end

				var_159_2.dropMana = var_160_2
			end

			if arg_159_0.selectMerHero then
				arg_159_0.guild:setUseRent(arg_159_0.selectMerHero)
			end

			if arg_159_0.selectMerPet then
				arg_159_0.guild:setUseRentPet(arg_159_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_159_0.campaignType,
						chapter = xyd.tables.campaign:chapter(var_159_2.campaignID)
					}
				}
			})

			var_159_2.petsA = {}

			for iter_160_11, iter_160_12 in ipairs(arg_159_0.petSelect_) do
				table.insert(var_159_2.petsA, iter_160_12)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_159_2)
		else
			arg_159_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startSummerFightBossBattle(arg_161_0)
	local var_161_0 = {
		herosA = {}
	}

	for iter_161_0, iter_161_1 in ipairs(arg_161_0.team_) do
		table.insert(var_161_0.herosA, iter_161_1.data)
	end

	local var_161_1 = arg_161_0:getFormationStr(var_161_0.herosA)

	var_161_0.formation = var_161_1

	local var_161_2

	if #arg_161_0.petTeam_ ~= 0 then
		var_161_2 = arg_161_0.petTeam_[1].data:getPetID()
	end

	local var_161_3 = {
		formation = var_161_1,
		pet_id = var_161_2
	}

	xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER):fightQuizBoss(var_161_3, function(arg_162_0, arg_162_1)
		if arg_162_0 == xyd.error.OK then
			arg_162_1 = arg_162_1.battle_info

			local function var_162_0()
				ngx.ctx.battle.reportData = json.decode(arg_162_1.battle_report)
				var_161_0.battle_report = arg_162_1.battle_report
				var_161_0.herosA = {}
				var_161_0.herosB = {}
				var_161_0.summonMonsters = {}
				var_161_0.campaignType = arg_161_0.campaignType
				var_161_0.campaignID = arg_161_0.campaignID
				var_161_0.battleID = arg_161_0.battleID
				var_161_0.battleType = xyd.BattleType.ReplayReport

				local var_163_0 = {}
				local var_163_1 = {}

				for iter_163_0, iter_163_1 in pairs(ngx.ctx.battle.reportData.fighter) do
					local var_163_2 = string.sub(iter_163_0, 1, 1)
					local var_163_3 = tonumber(string.sub(iter_163_0, 3, 3))

					if var_163_2 == "A" and tonumber(iter_163_1.summon_type) == xyd.summonMonsterType.None then
						local var_163_4 = var_0_1.new()

						var_163_4:populate(iter_163_1.hero)
						var_163_4:setReportData(iter_163_1)

						var_161_0.herosA[var_163_3] = var_163_4
					elseif var_163_2 == "A" and tonumber(iter_163_1.summon_type) == xyd.summonMonsterType.Pet then
						local var_163_5 = var_0_3.new()

						var_163_5:populate(iter_163_1.hero)
						var_163_5:setReportData(iter_163_1)

						var_161_0.petsA = {
							var_163_5
						}
					elseif var_163_2 == "B" and tonumber(iter_163_1.summon_type) == xyd.summonMonsterType.None then
						local var_163_6 = var_0_1.new()

						var_163_6:populate(iter_163_1.hero)
						var_163_6:setReportData(iter_163_1)

						var_163_0[var_163_3] = var_163_6
					elseif var_163_2 == "B" and tonumber(iter_163_1.summon_type) == xyd.summonMonsterType.Pet then
						local var_163_7 = var_0_3.new()

						var_163_7:populate(iter_163_1.hero)
						var_163_7:setReportData(iter_163_1)

						var_161_0.petsB = {
							var_163_7
						}
					elseif tonumber(iter_163_1.summon_type) ~= xyd.summonMonsterType.None then
						local var_163_8 = var_0_1.new()

						var_163_8:populate(iter_163_1.hero)
						var_163_8:setReportData(iter_163_1)

						var_163_1[iter_163_0] = var_163_8
					end
				end

				var_161_0.reportStar = ngx.ctx.battle.reportData.star
				var_161_0.herosB = {
					var_163_0
				}
				var_161_0.summonMonsters = var_163_1

				local var_163_9 = 0

				if arg_162_1.star > 0 then
					var_163_9 = 1
				end

				local var_163_10 = var_163_9
				local var_163_11 = {}

				if arg_162_1.library_mission_formations.partner_favor then
					for iter_163_2, iter_163_3 in pairs(arg_162_1.library_mission_formations.partner_favor) do
						if iter_163_3 > arg_161_0.selfPlayer:getHero(tonumber(iter_163_2)):getFavorDegree() then
							var_163_11[tonumber(iter_163_2)] = true

							arg_161_0.selfPlayer:getHero(tonumber(iter_163_2)):setFavorDegree(iter_163_3)
						end
					end

					var_161_0.favorDegreeUp = var_163_11
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "summer_quiz"
					}
				})
				xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL):formatLvbuCampusHeros(var_161_0.herosA)
				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_161_0)
			end

			if arg_162_1.battle_report == {} or #arg_162_1.battle_report == 0 then
				var_0_13.performWithDelayGlobal(function()
					requestReport(var_161_3)
				end, 3)
			else
				var_162_0()
			end
		elseif arg_162_1.error_code == 31005 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_14:translation("CHANGE_SEAL_HERO_TIPS")
			})

			arg_161_0.battleBegan = false
		else
			arg_161_0.battleBegan = false
		end
	end)
end

function var_0_0.startRegionArenaBattle(arg_165_0)
	local var_165_0 = {
		herosA = {}
	}

	for iter_165_0, iter_165_1 in ipairs(arg_165_0.team_) do
		table.insert(var_165_0.herosA, iter_165_1.data)
	end

	var_165_0.campaignType = arg_165_0.campaignType
	var_165_0.campaignID = arg_165_0.campaignID
	var_165_0.herosB = {
		arg_165_0.enemyHeroes_
	}
	var_165_0.fighterInfo = arg_165_0.fighterInfo
	var_165_0.battleID = xyd.MapBattleID.ARENA

	local var_165_1 = arg_165_0:getFormationStr(var_165_0.herosA)

	var_165_0.formation = var_165_1
	var_165_0.battleType = xyd.BattleType.CreateReport

	local var_165_2

	if #arg_165_0.petTeam_ ~= 0 then
		var_165_2 = arg_165_0.petTeam_[1].data:getPetID()
	end

	local var_165_3 = {
		pet_id = var_165_2,
		campaign_id = var_165_0.campaignID,
		campaign_type = var_165_0.campaignType,
		formation = var_165_1
	}

	if arg_165_0.isRegionPractise then
		var_165_3.is_practice = 1
	else
		var_165_3.is_practice = 0
	end

	xyd.Backend.get():request(xyd.mid.REGION_START_FIGHT, var_165_3, function(arg_166_0, arg_166_1)
		if arg_166_0 == xyd.error.OK then
			if arg_166_1.formation and next(arg_166_1.formation) then
				local var_166_0 = {}

				for iter_166_0, iter_166_1 in ipairs(arg_166_1.formation) do
					local var_166_1 = var_0_1.new()

					var_166_1:populate(iter_166_1)
					table.insert(var_166_0, var_166_1)
				end

				xyd.formatRegionArenaHeros(var_166_0)

				var_165_0.herosA = var_166_0
			end

			var_165_0.petsA = {}

			for iter_166_2, iter_166_3 in ipairs(arg_165_0.petSelect_) do
				table.insert(var_165_0.petsA, iter_166_3)
			end

			xyd.formatRegionArenaPets(var_165_0.petsA)

			var_165_0.petsB = {}

			table.insert(var_165_0.petsB, arg_165_0.enemyPets_)

			if arg_165_0.isRegionPractise then
				var_165_0.is_practice = true
			else
				var_165_0.is_practice = false
			end

			var_165_0.enemy_id = arg_165_0.fighterInfo.enemy_id
			arg_165_0.regionArena.isPractise = arg_165_0.isRegionPractise

			xyd.WindowManager.get():hideAllWindows()
			xyd.LoadingProxy.get():openBattleLoading(var_165_0)
		else
			arg_165_0.battleBegan = false
		end
	end)
end

function var_0_0.startMarchBattle(arg_167_0)
	local var_167_0 = {
		herosA = {}
	}

	for iter_167_0, iter_167_1 in ipairs(arg_167_0.team_) do
		iter_167_1.data.type = iter_167_1.type

		table.insert(var_167_0.herosA, iter_167_1.data)
	end

	local var_167_1 = {}

	for iter_167_2, iter_167_3 in ipairs(arg_167_0.enemyHeroes_) do
		if iter_167_3.healthStatus.health ~= 2 then
			table.insert(var_167_1, iter_167_3)
		end
	end

	var_167_0.campaignType = arg_167_0.campaignType
	var_167_0.campaignID = arg_167_0.campaignID
	var_167_0.herosB = {
		var_167_1
	}
	var_167_0.enemyID = arg_167_0.enemyID_
	var_167_0.battleID = xyd.MapBattleID.MARCH[arg_167_0.marchStage_]

	local var_167_2 = clone(var_167_0.herosA)

	for iter_167_4, iter_167_5 in pairs(var_167_2) do
		if iter_167_5.type == var_0_18.RENT_HERO then
			table.remove(var_167_2, iter_167_4)
		end
	end

	local var_167_3 = arg_167_0:getFormationStr(var_167_2)

	var_167_0.formation = var_167_3

	local var_167_4 = {
		campaign_type = var_167_0.campaignType,
		formation = var_167_3
	}

	arg_167_0:handleRentParams(var_167_4)
	xyd.Backend.get():request(xyd.mid.MARCH_START_FIGHT, var_167_4, function(arg_168_0, arg_168_1)
		if arg_168_0 == xyd.error.OK then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "march"
				}
			})

			if arg_167_0.selectMerHero then
				arg_167_0.guild:setUseRent(arg_167_0.selectMerHero)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_167_0)
		else
			arg_167_0.battleBegan = false
		end
	end)
end

function var_0_0.startMarchAdvance(arg_169_0)
	local var_169_0 = {}
	local var_169_1 = {}

	for iter_169_0, iter_169_1 in ipairs(arg_169_0.team_) do
		if iter_169_1.type ~= var_0_18.RENT_HERO then
			iter_169_1.data.type = iter_169_1.type

			table.insert(var_169_1, iter_169_1.data)
		end
	end

	var_169_0.campaign_type = xyd.CampaignType.MARCH
	var_169_0.formation = arg_169_0:getFormationStr(var_169_1)
	var_169_0.force = arg_169_0.rateScore

	arg_169_0:handleRentParams(var_169_0)
	xyd.Backend.get():request(xyd.mid.MARCH_ADVANCE_SWEEP, var_169_0, function(arg_170_0, arg_170_1)
		if arg_170_0 == xyd.error.OK then
			if arg_170_1.partner_favor then
				for iter_170_0, iter_170_1 in pairs(arg_170_1.partner_favor) do
					if iter_170_1 > arg_169_0.selfPlayer:getHero(tonumber(iter_170_0)):getFavorDegree() then
						arg_169_0.selfPlayer:getHero(tonumber(iter_170_0)):setFavorDegree(iter_170_1)
					end
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_FAVOR_INFO
				})
			end

			local var_170_0 = {
				award = arg_170_1.award,
				economy = arg_170_1.economy,
				power_drink = arg_170_1.power_drink
			}

			xyd.WindowManager.get():openWindow("march_sweep_window", var_170_0)
			xyd.WindowManager.get():closeWindow(arg_169_0)
			xyd.WindowManager.get():getWindow("march"):addMap()
		end
	end)
end

function var_0_0.startTreasureBattle(arg_171_0)
	local var_171_0 = false
	local var_171_1 = {
		herosA = {}
	}

	for iter_171_0, iter_171_1 in ipairs(arg_171_0.team_) do
		iter_171_1.data.type = iter_171_1.type

		if iter_171_1.type == var_0_18.RENT_HERO then
			var_171_0 = true
		end

		table.insert(var_171_1.herosA, iter_171_1.data)
	end

	var_171_1.rentFlag = var_171_0

	local var_171_2 = {}

	for iter_171_2, iter_171_3 in ipairs(arg_171_0.enemyHeroes_) do
		if iter_171_3.healthStatus.health ~= 2 and (iter_171_3.healthStatus.hp == nil or iter_171_3.healthStatus.hp > 0) then
			table.insert(var_171_2, iter_171_3)
		end
	end

	var_171_1.campaignType = arg_171_0.campaignType
	var_171_1.campaignID = arg_171_0.campaignID
	var_171_1.treasureAwardType = arg_171_0.treasureType
	var_171_1.herosB = {
		var_171_2
	}
	var_171_1.enemyID = arg_171_0.enemyID_
	var_171_1.battleID = xyd.MapBattleID.TREASURE[arg_171_0.treasureType]

	local var_171_3 = clone(var_171_1.herosA)

	for iter_171_4, iter_171_5 in pairs(var_171_3) do
		if iter_171_5.type == var_0_18.RENT_HERO then
			table.remove(var_171_3, iter_171_4)
		end
	end

	local var_171_4 = arg_171_0:getFormationStr(var_171_3)

	if arg_171_0.selectMerHero then
		local var_171_5 = {
			campaign_type = var_171_1.campaignType,
			formation = var_171_4
		}

		arg_171_0:handleRentParams(var_171_5)
		xyd.Backend.get():request(xyd.mid.TREASURE_START_FIGHT, var_171_5, function(arg_172_0, arg_172_1)
			if arg_172_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "treasure_window",
						status = {
							isSelf = false
						}
					}
				})

				if arg_171_0.selectMerHero then
					arg_171_0.guild:setUseRent(arg_171_0.selectMerHero)
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_171_1)
			else
				arg_171_0.battleBegan = false
			end
		end)
	else
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "treasure_window",
				status = {
					isSelf = false
				}
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_171_1)
	end
end

function var_0_0.startConquerSchoolBattle(arg_173_0)
	local var_173_0 = false
	local var_173_1 = {
		herosA = {}
	}

	for iter_173_0, iter_173_1 in ipairs(arg_173_0.team_) do
		iter_173_1.data.type = iter_173_1.type

		if iter_173_1.type == var_0_18.RENT_HERO then
			var_173_0 = true
		end

		table.insert(var_173_1.herosA, iter_173_1.data)
	end

	var_173_1.rentFlag = var_173_0
	var_173_1.campaignType = arg_173_0.campaignType
	var_173_1.campaignID = arg_173_0.campaignID
	var_173_1.conquerSchoolTeamID = arg_173_0.conquerSchoolTeamID
	var_173_1.battleID = xyd.tables.conquerSchoolCampaign:fightIDs(arg_173_0.campaignID)[arg_173_0.conquerSchoolTeamID]

	local var_173_2 = xyd.tables.conquerSchoolCampaign:teams(arg_173_0.campaignID)[arg_173_0.conquerSchoolTeamID]

	var_173_1.herosB = {}

	local var_173_3 = {}

	for iter_173_2, iter_173_3 in ipairs(var_173_2) do
		local var_173_4 = var_0_1.new()
		local var_173_5 = arg_173_0.selfPlayer.conquerLoopID
		local var_173_6 = xyd.tables.ConquerSchoolLoop:ratio(var_173_5)

		var_173_4:populateWithTableID(iter_173_3)

		local var_173_7 = var_173_4.getTotalAttr

		function var_173_4.getTotalAttr(arg_174_0, arg_174_1)
			local var_174_0 = var_173_7(arg_174_0, arg_174_1)

			if arg_174_1 == xyd.AttributeType.HP or arg_174_1 == xyd.AttributeType.AD or arg_174_1 == xyd.AttributeType.AP or arg_174_1 == xyd.AttributeType.HUJIA or arg_174_1 == xyd.AttributeType.MOKANG or arg_174_1 == xyd.AttributeType.AD_BAOJI or arg_174_1 == xyd.AttributeType.AP_BAOJI or arg_174_1 == xyd.AttributeType.SHANBI or arg_174_1 == xyd.AttributeType.D_HUJIA or arg_174_1 == xyd.AttributeType.D_MOKANG or arg_174_1 == xyd.AttributeType.MINGZHONG then
				return var_174_0 * var_173_6
			else
				return var_174_0
			end
		end

		table.insert(var_173_3, var_173_4)
	end

	if next(var_173_3) then
		table.insert(var_173_1.herosB, var_173_3)
	end

	local var_173_8 = var_0_1.new()

	var_173_8:populateWithTableID(90000101)

	var_173_1.sceneFighter = var_173_8

	local var_173_9 = {}

	for iter_173_4, iter_173_5 in pairs(var_173_1.herosA) do
		if iter_173_5.type ~= var_0_18.RENT_HERO and iter_173_5:getHeroID() > 0 then
			table.insert(var_173_9, iter_173_5)
		end
	end

	local var_173_10 = arg_173_0:getFormationStr(var_173_9)

	var_173_1.formation = var_173_10

	local var_173_11 = {
		formation = var_173_10
	}
	local var_173_12

	if #arg_173_0.petTeam_ ~= 0 and not arg_173_0.isSelectMerPet then
		var_173_12 = arg_173_0.petTeam_[1].data:getPetID()
	end

	var_173_11.pet_id = var_173_12
	var_173_1.fightParams = var_173_11

	xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL):startFight(var_173_11, function(arg_175_0, arg_175_1)
		if arg_175_0 == xyd.error.OK then
			var_173_1.petsA = {}

			for iter_175_0, iter_175_1 in ipairs(arg_173_0.petSelect_) do
				table.insert(var_173_1.petsA, iter_175_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "conquer_school"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_173_1)
		else
			arg_173_0.battleBegan = false
		end
	end)
end

function var_0_0.getFormationStr(arg_176_0, arg_176_1)
	local var_176_0 = ""

	for iter_176_0, iter_176_1 in ipairs(arg_176_1) do
		var_176_0 = var_176_0 .. string.format("%d", iter_176_1:getHeroID())

		if iter_176_0 < #arg_176_1 then
			var_176_0 = var_176_0 .. "|"
		end
	end

	return var_176_0
end

function var_0_0.getOriginFormationStr(arg_177_0, arg_177_1)
	local var_177_0 = ""

	for iter_177_0, iter_177_1 in ipairs(arg_177_1) do
		var_177_0 = var_177_0 .. string.format("%d", iter_177_1:getFirstTableID())

		if iter_177_0 < #arg_177_1 then
			var_177_0 = var_177_0 .. "|"
		end
	end

	return var_177_0
end

function var_0_0.getHeroStarStr(arg_178_0, arg_178_1)
	local var_178_0 = ""

	for iter_178_0, iter_178_1 in ipairs(arg_178_1) do
		var_178_0 = var_178_0 .. string.format("%d", iter_178_1:getStar())

		if iter_178_0 < #arg_178_1 then
			var_178_0 = var_178_0 .. "|"
		end
	end

	return var_178_0
end

function var_0_0.size(arg_179_0, arg_179_1, arg_179_2)
	return {
		width = arg_179_1,
		height = arg_179_2
	}
end

function var_0_0.setIDBeforeGuideWnd(arg_180_0)
	local var_180_0 = xyd.StoryData.get():getGuideID()

	if var_180_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL)
	elseif var_180_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_TWO)
	elseif var_180_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_TWO)
	elseif var_180_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_181_0)
	local var_181_0 = xyd.StoryData.get():getGuideID()

	if var_181_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO)
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE)
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR)
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT)
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_MISSION_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START)
		xyd.StoryData.get():persist()
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE then
		arg_181_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_2_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_FOUR)
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO then
		arg_181_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_THREE)
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		arg_181_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_4)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_END)
		xyd.StoryData.get():persist()
	elseif var_181_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		arg_181_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR)
	end
end

function var_0_0.checkGuideIntoBattle(arg_182_0)
	local var_182_0 = xyd.StoryData.get():getGuideID()

	if var_182_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR or var_182_0 == xyd.GuideStoryType.GUIDE_MISSION_END or var_182_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE or var_182_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO or var_182_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		return true
	end

	return false
end

function var_0_0.getGuideHeroCell(arg_183_0, arg_183_1)
	local var_183_0 = xyd.StoryData.get():getGuideID()
	local var_183_1 = arg_183_1 or 10001001

	if var_183_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		var_183_1 = 10001004
	end

	for iter_183_0 = 1, #arg_183_0.heroCells_ do
		if arg_183_0.heroCells_[iter_183_0] and arg_183_0.heroCells_[iter_183_0].data and arg_183_0.heroCells_[iter_183_0].data:getTableID() == var_183_1 then
			return arg_183_0.heroCells_[iter_183_0]
		end
	end

	return arg_183_0.heroCells_[1]
end

function var_0_0.playGuide(arg_184_0)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_184_0 = xyd.StoryData.get():getGuideID()

	if tonumber(#arg_184_0.team_) >= 3 and var_184_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR)

		var_184_0 = xyd.StoryData.get():getGuideID()
	end

	if var_184_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
		local var_184_1 = arg_184_0.heroCells_[1]

		if var_184_1 == nil then
			return
		end

		local var_184_2 = {
			550,
			350
		}

		xyd.showGuideWnd(var_184_1, nil, nil, 1, var_184_2, true)
		arg_184_0:setIDAfterGuideWnd()
	elseif var_184_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
		local var_184_3 = arg_184_0.heroCells_[2]

		if var_184_3 == nil then
			return
		end

		local var_184_4 = {
			550,
			350
		}

		xyd.showGuideWnd(var_184_3, nil, nil, 1, var_184_4, true)
		arg_184_0:setIDAfterGuideWnd()
	elseif var_184_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
		local var_184_5 = arg_184_0.heroCells_[3]

		if var_184_5 == nil then
			return
		end

		local var_184_6 = {
			550,
			350
		}

		xyd.showGuideWnd(var_184_5, nil, nil, 1, var_184_6, true)
		arg_184_0:setIDAfterGuideWnd()
	elseif arg_184_0:checkGuideIntoBattle() then
		local var_184_7 = arg_184_0:nodeByName("button_battle")
		local var_184_8 = {
			850,
			250
		}

		xyd.showGuideWnd(var_184_7, nil, nil, 0, var_184_8, true)
		arg_184_0:setIDAfterGuideWnd()

		if #arg_184_0.select_ < 1 then
			arg_184_0.preSelect_ = {}
			arg_184_0.preHeros_ = {}

			table.insert(arg_184_0.preSelect_, 1)
			table.insert(arg_184_0.preSelect_, 2)
			table.insert(arg_184_0.preSelect_, 3)
			table.insert(arg_184_0.preHeros_, arg_184_0.selfPlayer:getHeroByID(1))
			table.insert(arg_184_0.preHeros_, arg_184_0.selfPlayer:getHeroByID(2))
			table.insert(arg_184_0.preHeros_, arg_184_0.selfPlayer:getHeroByID(3))
			arg_184_0:refreshSelectedHeroClass()
		end
	elseif var_184_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		local var_184_9 = arg_184_0:getGuideHeroCell()

		if var_184_9 == nil then
			return
		end

		local var_184_10 = {
			550,
			350
		}

		xyd.showGuideWnd(var_184_9, nil, nil, 1, var_184_10, true)
		arg_184_0:setIDAfterGuideWnd()
	end
end

function var_0_0.checkGuildPrepareTime(arg_185_0)
	if arg_185_0.campaignType == xyd.CampaignType.GUILD and arg_185_0.guildPrepareTime and arg_185_0.guildPrepareTime > 0 then
		arg_185_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_185_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_14:translation("GUILD_PREPARE_FIGHT"), arg_185_0.guildPrepareTime))

		arg_185_0.handle_ = var_0_13.scheduleGlobal(function()
			arg_185_0.guildPrepareTime = arg_185_0.guildPrepareTime - 1

			if arg_185_0.guildPrepareTime <= 0 then
				if arg_185_0.handle_ then
					var_0_13.unscheduleGlobal(arg_185_0.handle_)
				end

				xyd.WindowManager.get():closeWindow(arg_185_0.name)
			else
				arg_185_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_14:translation("GUILD_PREPARE_FIGHT"), arg_185_0.guildPrepareTime))
			end
		end, 1)
	end
end

function var_0_0.checkBusyHeros(arg_187_0, arg_187_1)
	for iter_187_0 = 1, #arg_187_0.busyHeroList do
		if arg_187_0.busyHeroList[iter_187_0] == arg_187_1:getHeroID() then
			for iter_187_1, iter_187_2 in pairs(arg_187_0.preSelect_) do
				if iter_187_2 == arg_187_0.busyHeroList[iter_187_0] then
					return true
				end
			end

			return false
		end
	end

	return true
end

function var_0_0.checkBusyHero2(arg_188_0, arg_188_1)
	local var_188_0 = false

	for iter_188_0, iter_188_1 in pairs(arg_188_0.busyHeros_) do
		if iter_188_1 == arg_188_1:getHeroID() then
			var_188_0 = true

			break
		end
	end

	return var_188_0
end

function var_0_0.canPetJoinBattle(arg_189_0, arg_189_1)
	if arg_189_0.type == xyd.SelectTeamType.ADJUST_TROOP and arg_189_1.level_ < arg_189_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
		return false
	end

	return true
end

function var_0_0.canHeroJoinBattle(arg_190_0, arg_190_1)
	if arg_190_0.campaignLimit and next(arg_190_0.campaignLimit) then
		local var_190_0 = arg_190_1:getFromType()

		if xyd.isInTable(arg_190_0.campaignLimit, var_190_0) then
			return false
		end
	end

	if arg_190_0.selectSpType == xyd.SelectSpType.WEI then
		if arg_190_1:getFromType() ~= xyd.HeroFromType.WEI then
			return false
		end
	elseif arg_190_0.selectSpType == xyd.SelectSpType.SHU then
		if arg_190_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_190_0.selectSpType == xyd.SelectSpType.WU then
		if arg_190_1:getFromType() ~= xyd.HeroFromType.WU then
			return false
		end
	elseif arg_190_0.selectSpType == xyd.SelectSpType.QUN and arg_190_1:getFromType() ~= xyd.HeroFromType.QUN then
		return false
	end

	if arg_190_0.campaignType == xyd.CampaignType.WU then
		if arg_190_1:getFromType() == xyd.HeroFromType.WU then
			return false
		end
	elseif arg_190_0.campaignType == xyd.CampaignType.SHU then
		if arg_190_1:getFromType() == xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_190_0.campaignType == xyd.CampaignType.WEI then
		if arg_190_1:getFromType() ~= xyd.HeroFromType.WU and arg_190_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_190_0.type == xyd.SelectTeamType.TREASURE_DEFENSE then
		if not arg_190_0:checkBusyHeros(arg_190_1) then
			return false
		end
	elseif arg_190_0.type == xyd.SelectTeamType.WORLD_BOSS then
		if arg_190_1.color_ < xyd.EquipQuality.PURPLE then
			return false
		end
	elseif arg_190_0.type == xyd.SelectTeamType.ADJUST_TROOP then
		if arg_190_1.level_ < arg_190_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
			return false
		end
	elseif arg_190_0.type == xyd.SelectTeamType.CHALLENGE then
		if var_0_15:modeType(arg_190_0.battleID) == xyd.ChallengeType.KillSteal then
			local var_190_1 = var_0_15:killingHero(arg_190_0.battleID)
			local var_190_2 = xyd.tables.hero:monster2PartnerID(var_190_1)

			if arg_190_1:getTableID() == var_190_2 or xyd.tables.hero:beforeAwaken(arg_190_1:getTableID()) == var_190_2 or xyd.tables.hero:afterAwaken(arg_190_1:getTableID()) == var_190_2 then
				return false
			end
		elseif var_0_15:modeType(arg_190_0.battleID) == xyd.ChallengeType.Protect then
			local var_190_3 = var_0_15:protectedHero(arg_190_0.battleID)
			local var_190_4 = xyd.tables.hero:monster2PartnerID(var_190_3)

			if arg_190_1:getTableID() == var_190_4 or xyd.tables.hero:beforeAwaken(arg_190_1:getTableID()) == var_190_4 or xyd.tables.hero:afterAwaken(arg_190_1:getTableID()) == var_190_4 then
				return false
			end
		end
	end

	if arg_190_0.type == xyd.SelectTeamType.ADVANCED then
		if arg_190_1:getLevel() >= var_0_9 then
			return true
		end
	elseif arg_190_1:getLevel() >= xyd.tables.battle:levLimit(arg_190_0.campaignID) then
		return true
	end

	return false
end

function var_0_0.initHeros(arg_191_0, arg_191_1, arg_191_2)
	arg_191_0.tmpTotalHero_[arg_191_2] = {}
	arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ALL] = {}
	arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.QIANPAI] = {}
	arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.HOUPAI] = {}
	arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.FILTER] = {}

	for iter_191_0, iter_191_1 in pairs(arg_191_0.tmpTotalHero_[arg_191_2]) do
		iter_191_1[var_0_21.NO] = {}
		iter_191_1[var_0_21.YES] = {}
	end

	if arg_191_2 == var_0_18.SELF_HERO then
		for iter_191_2, iter_191_3 in pairs(arg_191_1) do
			if arg_191_0:canHeroJoinBattle(iter_191_3) then
				if iter_191_3:getDistanceType() == xyd.DistanceType.QIANPAI then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.QIANPAI][var_0_21.NO], iter_191_3)

					if iter_191_3:isCollocation() then
						table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.QIANPAI][var_0_21.YES], iter_191_3)
					end
				elseif iter_191_3:getDistanceType() == xyd.DistanceType.ZHONGPAI then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ZHONGPAI][var_0_21.NO], iter_191_3)

					if iter_191_3:isCollocation() then
						table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ZHONGPAI][var_0_21.YES], iter_191_3)
					end
				elseif iter_191_3:getDistanceType() == xyd.DistanceType.HOUPAI then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.HOUPAI][var_0_21.NO], iter_191_3)

					if iter_191_3:isCollocation() then
						table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.HOUPAI][var_0_21.YES], iter_191_3)
					end
				end

				table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ALL][var_0_21.NO], iter_191_3)

				if iter_191_3:isCollocation() then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ALL][var_0_21.YES], iter_191_3)
				end
			end
		end
	elseif arg_191_2 == var_0_18.RENT_HERO then
		for iter_191_4, iter_191_5 in pairs(arg_191_1) do
			if arg_191_0:canHeroJoinBattle(iter_191_5) then
				if iter_191_5:getDistanceType() == xyd.DistanceType.QIANPAI then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.QIANPAI][var_0_21.NO], iter_191_5)
				elseif iter_191_5:getDistanceType() == xyd.DistanceType.ZHONGPAI then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ZHONGPAI][var_0_21.NO], iter_191_5)
				elseif iter_191_5:getDistanceType() == xyd.DistanceType.HOUPAI then
					table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.HOUPAI][var_0_21.NO], iter_191_5)
				end

				table.insert(arg_191_0.tmpTotalHero_[arg_191_2][xyd.DistanceType.ALL][var_0_21.NO], iter_191_5)
			end
		end

		for iter_191_6, iter_191_7 in pairs(arg_191_0.tmpTotalHero_[arg_191_2]) do
			iter_191_7[var_0_21.YES] = iter_191_7[var_0_21.NO]
		end
	end

	arg_191_0:sortTables(arg_191_0.tmpTotalHero_[arg_191_2])

	arg_191_0.selectedHeroClass_[arg_191_2] = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_192_0, arg_192_1, arg_192_2)
	local var_192_0 = {}

	for iter_192_0, iter_192_1 in ipairs(arg_192_1) do
		if iter_192_1.is_show_ == 1 and arg_192_0:canPetJoinBattle(iter_192_1) then
			table.insert(var_192_0, iter_192_1)
		end
	end

	table.sort(var_192_0, function(arg_193_0, arg_193_1)
		return xyd.petNormalSort(arg_193_0, arg_193_1) or false
	end)

	arg_192_0.tmpTotalPets[arg_192_2] = var_192_0
end

function var_0_0.updateFilterHeros(arg_194_0)
	arg_194_0.totalHero_[xyd.DistanceType.FILTER][var_0_21.NO] = {}
	arg_194_0.totalHero_[xyd.DistanceType.FILTER][var_0_21.YES] = {}

	local var_194_0 = {
		0,
		0,
		0
	}
	local var_194_1 = {
		0,
		0,
		0
	}
	local var_194_2 = {
		0,
		0,
		0,
		0
	}
	local var_194_3 = {
		0,
		0,
		0
	}

	if arg_194_0.selfPlayer.sortType and arg_194_0.selfPlayer.sortType > 0 then
		local var_194_4 = {}
		local var_194_5 = arg_194_0.selfPlayer.sortType
		local var_194_6 = 1

		while var_194_5 > 0 do
			var_194_4[var_194_6] = var_194_5 % 2
			var_194_6 = var_194_6 + 1
			var_194_5 = math.floor(var_194_5 / 2)
		end

		local var_194_7 = 1

		for iter_194_0 = 13, 1, -1 do
			if iter_194_0 <= 4 then
				if iter_194_0 == 4 then
					var_194_7 = 1
				end

				var_194_2[var_194_7] = var_194_4[iter_194_0]
			elseif iter_194_0 <= 7 then
				if iter_194_0 == 7 then
					var_194_7 = 1
				end

				var_194_1[var_194_7] = var_194_4[iter_194_0]
			elseif iter_194_0 <= 10 then
				if iter_194_0 == 10 then
					var_194_7 = 1
				end

				if var_194_4[iter_194_0] then
					var_194_0[var_194_7] = var_194_4[iter_194_0]
				end
			elseif iter_194_0 <= 13 then
				if iter_194_0 == 13 then
					var_194_7 = 1
				end

				if var_194_4[iter_194_0] then
					var_194_3[var_194_7] = var_194_4[iter_194_0]
				end
			end

			var_194_7 = var_194_7 + 1
		end
	else
		var_194_0 = {
			1,
			1,
			1
		}
		var_194_1 = {
			1,
			1,
			1
		}
		var_194_2 = {
			1,
			1,
			1,
			1
		}
		var_194_3 = {
			1,
			1,
			1
		}
	end

	for iter_194_1, iter_194_2 in pairs(arg_194_0.totalHero_[xyd.DistanceType.ALL][var_0_21.NO]) do
		if var_194_0[iter_194_2:getDistanceType() - 1] == 1 and var_194_1[iter_194_2:getHeroType()] == 1 and var_194_2[iter_194_2:getFromType()] == 1 and arg_194_0:canHeroJoinBattle(iter_194_2) and var_194_3[iter_194_2:getAwakenType()] == 1 then
			table.insert(arg_194_0.totalHero_[xyd.DistanceType.FILTER][var_0_21.NO], iter_194_2)
		end
	end

	for iter_194_3, iter_194_4 in pairs(arg_194_0.totalHero_[xyd.DistanceType.ALL][var_0_21.YES]) do
		if var_194_0[iter_194_4:getDistanceType() - 1] == 1 and var_194_1[iter_194_4:getHeroType()] == 1 and var_194_2[iter_194_4:getFromType()] == 1 and arg_194_0:canHeroJoinBattle(iter_194_4) and var_194_3[iter_194_4:getAwakenType()] == 1 then
			table.insert(arg_194_0.totalHero_[xyd.DistanceType.FILTER][var_0_21.YES], iter_194_4)
		end
	end
end

function var_0_0.updateSearchHeros(arg_195_0)
	arg_195_0.totalHero_[xyd.DistanceType.SEARCH] = {}
	arg_195_0.totalHero_[xyd.DistanceType.SEARCH][var_0_21.YES] = {}
	arg_195_0.totalHero_[xyd.DistanceType.SEARCH][var_0_21.NO] = {}

	if arg_195_0.searchTxt ~= "" then
		for iter_195_0, iter_195_1 in pairs(arg_195_0.totalHero_[xyd.DistanceType.ALL][var_0_21.NO]) do
			if xyd.searchHeroByName(arg_195_0.searchTxt, iter_195_1) then
				table.insert(arg_195_0.totalHero_[xyd.DistanceType.SEARCH][var_0_21.NO], iter_195_1)
			end
		end

		for iter_195_2, iter_195_3 in pairs(arg_195_0.totalHero_[xyd.DistanceType.ALL][var_0_21.YES]) do
			if xyd.searchHeroByName(arg_195_0.searchTxt, iter_195_3) then
				table.insert(arg_195_0.totalHero_[xyd.DistanceType.SEARCH][var_0_21.YES], iter_195_3)
			end
		end
	end
end

function var_0_0.initPresetTeams(arg_196_0)
	arg_196_0.presetTeams = {}

	if not arg_196_0:checkCanPresetTeam() then
		return
	end

	local var_196_0 = arg_196_0.selfPlayer:getSaveTeams()

	if arg_196_0.type and arg_196_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_196_0.type == xyd.SelectTeamType.REGION_ARENA or arg_196_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		local var_196_1 = arg_196_0.regionAwards

		for iter_196_0 = 1, #var_196_0 do
			local var_196_2 = var_196_0[iter_196_0].team

			arg_196_0:initRegionHeros(var_196_2, var_196_1, true)
			xyd.formatRegionArenaHeros(var_196_2)
		end
	elseif arg_196_0.type and arg_196_0.type == xyd.SelectTeamType.DREAM_WORLD then
		local var_196_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)

		if var_196_3.mapType == xyd.DreamWorldType.STORY then
			for iter_196_1 = 1, #var_196_0 do
				local var_196_4 = var_196_0[iter_196_1].team
				local var_196_5 = {}

				for iter_196_2, iter_196_3 in pairs(var_196_4) do
					local var_196_6 = iter_196_3:getTableID()
					local var_196_7 = xyd.getOriginHeroId(var_196_6)

					if var_0_16:isCanAwaken(var_196_7) == 0 then
						var_196_6 = var_196_7
					else
						var_196_6 = var_0_16:afterAwaken(var_196_7)
					end

					local var_196_8 = var_0_1.new()

					var_196_8:initUnCollected(var_196_6, 1)

					arg_196_0.totalIDs_[var_196_7] = var_196_8

					table.insert(var_196_5, var_196_8)
				end

				var_196_3:formatNewHeros(var_196_5)

				var_196_0[iter_196_1].team = var_196_5

				if var_196_0[iter_196_1].pet then
					local var_196_9 = var_196_0[iter_196_1].pet:getTableID()
					local var_196_10 = var_0_16:beforeAwaken(var_196_9)

					if var_196_10 == 0 then
						var_196_10 = var_196_9
					end

					if var_0_16:isCanAwaken(var_196_10) == 0 then
						var_196_9 = var_196_10
					else
						var_196_9 = var_0_16:afterAwaken(var_196_10)
					end

					local var_196_11 = var_0_3.new()
					local var_196_12 = {
						is_show = 1,
						star = xyd.MAX_STAR_LEVEL
					}

					var_196_11:initUnCollected(var_196_9, nil, var_196_12)
					var_196_3:formatNewPets({
						var_196_11
					})

					var_196_0[iter_196_1].pet = var_196_11
				end
			end
		end
	elseif arg_196_0.type and arg_196_0.type == xyd.SelectTeamType.RAGNAROK then
		var_196_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):getPresetTeams()
	end

	arg_196_0.presetTeams = var_196_0
end

function var_0_0.selectHeros(arg_197_0)
	arg_197_0.totalHero_ = arg_197_0.tmpTotalHero_[arg_197_0.leftMenuType_]
end

function var_0_0.selectPets(arg_198_0)
	if arg_198_0.rentMenuType == var_0_19.RENT_PET then
		arg_198_0.totalPet_ = arg_198_0.tmpTotalPets[var_0_20.RENT_PET]
	else
		arg_198_0.totalPet_ = arg_198_0.tmpTotalPets[var_0_20.SELF_PET]
	end
end

function var_0_0.initListview(arg_199_0)
	local var_199_0 = arg_199_0:nodeByName("list_layer")
	local var_199_1 = var_199_0:getContentSize().width
	local var_199_2 = var_199_0:getContentSize().height

	arg_199_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_199_1, var_199_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_199_0)
	arg_199_0.heroCells_ = {}

	arg_199_0.heroList_:setDelegate(handler(arg_199_0, arg_199_0.delegate))
end

function var_0_0.initTextOfList(arg_200_0)
	arg_200_0.txt_height = arg_200_0:nodeByName("lev_limit_txt"):getY()

	if arg_200_0.type == xyd.SelectTeamType.ADVANCED then
		arg_200_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_200_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_14:translation("SELECT_HERO_LEV_LIMIT"), var_0_9, var_0_14:translation("MARCH_ADVANCED")))
	elseif arg_200_0.type == xyd.SelectTeamType.INCUBUS then
		arg_200_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_200_0:nodeByName("lev_limit_txt"):setString(var_0_14:translation("INCUBUS_CHOOSE_FIRST"))
	elseif arg_200_0.type == xyd.SelectTeamType.ADVENTURE_DEFENSE then
		arg_200_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_200_0:updateDefenseTimeCount(arg_200_0:nodeByName("lev_limit_txt"))
	elseif xyd.tables.battle:levLimit(arg_200_0.campaignID) > 0 then
		arg_200_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_200_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_14:translation("SELECT_HERO_LEV_LIMIT"), xyd.tables.battle:levLimit(arg_200_0.campaignID), xyd.tables.battle:name(arg_200_0.campaignID)))
	end

	if arg_200_0.campaignType == xyd.CampaignType.ELEMENT and arg_200_0.hasPurpleHero ~= nil and arg_200_0.hasPurpleHero == false then
		arg_200_0:nodeByName("lev_limit_txt"):y(arg_200_0.txt_height - 20)
		arg_200_0:nodeByName("lev_limit_txt"):show()
		arg_200_0:nodeByName("lev_limit_txt"):setString(var_0_14:translation("HAS_NOT_PURPLE_HERO"))
	end

	local var_200_0 = arg_200_0.heroList_:getViewRect()

	if arg_200_0:nodeByName("lev_limit_txt"):isVisible() then
		local var_200_1 = cc.rect(0, 0, var_200_0.width, var_200_0.height - var_0_10)

		arg_200_0.heroList_:setViewRect(var_200_1)
	end
end

function var_0_0.updateTextOfList(arg_201_0)
	if arg_201_0.campaignType ~= xyd.CampaignType.ELEMENT then
		return
	end

	if arg_201_0.leftMenuType_ == var_0_18.SELF_HERO and arg_201_0.hasPurpleHero == false or arg_201_0.leftMenuType_ == var_0_18.RENT_HERO and arg_201_0.hasGuildPurpleHero == false then
		arg_201_0:nodeByName("lev_limit_txt"):y(arg_201_0.txt_height - 20)
		arg_201_0:nodeByName("lev_limit_txt"):show()
		arg_201_0:nodeByName("lev_limit_txt"):setString(var_0_14:translation("HAS_NOT_PURPLE_HERO"))
	else
		arg_201_0:nodeByName("lev_limit_txt"):setVisible(false)
	end
end

function var_0_0.awakeMissionInit(arg_202_0)
	local var_202_0 = arg_202_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_202_0 then
		local var_202_1 = xyd.tables.mission:sufMissionID(var_202_0)

		if var_202_1 and var_202_1 == 0 and xyd.getMissionGoIDs(var_202_0) == arg_202_0.campaignID then
			arg_202_0.isAwakeCampaign = true
			arg_202_0.awakeMission = arg_202_0.task:getTaskByID(var_202_0, xyd.TaskType.AWAKE)
			arg_202_0.awakeStage = xyd.tables.mission:stage(var_202_0)
			arg_202_0.awakeMissionGoalType = xyd.tables.mission:copyChallenges(var_202_0)
			arg_202_0.awakeHero = arg_202_0.selfPlayer:getHeroByTableID(xyd.tables.mission:beforeAwakenID(var_202_0))
		end

		if arg_202_0.awakeHero then
			arg_202_0.awakeHero.type = var_0_18.SELF_HERO
		end
	end

	if arg_202_0.isAwakeCampaign then
		local var_202_2 = ""
		local var_202_3 = arg_202_0.awakeMission.tableID

		if arg_202_0.awakeStage == 2 then
			var_202_2 = string.format(var_0_14:translation("AWAKE_SELECT_TEAM_TIP1"), arg_202_0.awakeHero:getName())
		elseif arg_202_0.awakeStage == 3 then
			if arg_202_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.SELF_KILL then
				var_202_2 = string.format(var_0_14:translation("AWAKE_SELECT_TEAM_TIP" .. arg_202_0.awakeMissionGoalType), arg_202_0.awakeHero:getName())
			elseif arg_202_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				var_202_2 = string.format(var_0_14:translation("AWAKE_SELECT_TEAM_TIP" .. arg_202_0.awakeMissionGoalType), xyd.tables.mission:challengeNums(var_202_3))
			elseif arg_202_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
				var_202_2 = string.format(var_0_14:translation("AWAKE_SELECT_TEAM_TIP" .. arg_202_0.awakeMissionGoalType), arg_202_0.awakeHero:getName())
			elseif arg_202_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALL_ALIVE then
				var_202_2 = var_0_14:translation("AWAKE_SELECT_TEAM_TIP" .. arg_202_0.awakeMissionGoalType)
			end
		end

		arg_202_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_202_0:nodeByName("lev_limit_txt"):setString(var_202_2)

		arg_202_0.preSelect_ = {}
		arg_202_0.preHeros_ = {}

		table.insert(arg_202_0.preSelect_, arg_202_0.awakeHero:getHeroID())
		table.insert(arg_202_0.preHeros_, arg_202_0.awakeHero)
	end
end

function var_0_0.sortTables(arg_203_0, arg_203_1)
	for iter_203_0 = 1, #arg_203_1 do
		table.sort(arg_203_1[iter_203_0][var_0_21.NO], function(arg_204_0, arg_204_1)
			if arg_204_0.tutorInfo and not arg_204_1.tutorInfo then
				return true
			elseif arg_204_1.tutorInfo and not arg_204_0.tutorInfo then
				return false
			end

			if arg_203_0.reinforcePartnerRatios[arg_204_0:getTableID()] and not arg_203_0.reinforcePartnerRatios[arg_204_1:getTableID()] then
				return true
			elseif arg_203_0.reinforcePartnerRatios[arg_204_1:getTableID()] and not arg_203_0.reinforcePartnerRatios[arg_204_0:getTableID()] then
				return false
			end

			if arg_203_0.type == xyd.SelectTeamType.INCUBUS or arg_203_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_203_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER then
				local var_204_0 = arg_203_0:isBanned(arg_204_0)
				local var_204_1 = arg_203_0:isBanned(arg_204_1)

				if (var_204_0 or var_204_1) and (not var_204_0 or not var_204_1) then
					return var_204_1
				end
			elseif arg_203_0.type == xyd.SelectTeamType.ADVANCED then
				local var_204_2 = arg_203_0:isRecommend(arg_204_0)
				local var_204_3 = arg_203_0:isRecommend(arg_204_1)

				if (var_204_2 or var_204_3) and (not var_204_2 or not var_204_3) then
					return var_204_2
				end
			elseif arg_203_0.type == xyd.SelectTeamType.CAMPAIGN and arg_203_0.ispreperation then
				local var_204_4 = arg_203_0:isRecommend(arg_204_0)
				local var_204_5 = arg_203_0:isRecommend(arg_204_1)

				if (var_204_4 or var_204_5) and (not var_204_4 or not var_204_5) then
					return var_204_4
				end
			end

			if (arg_204_0.can_rent or arg_204_1.can_rent) and (not arg_204_0.can_rent or not arg_204_1.can_rent) then
				return arg_204_0.can_rent and not arg_204_1.can_rent
			end

			return xyd.heroNormalSort(arg_204_0, arg_204_1) or false
		end)
		table.sort(arg_203_1[iter_203_0][var_0_21.YES], function(arg_205_0, arg_205_1)
			if arg_205_0.tutorInfo and not arg_205_1.tutorInfo then
				return true
			elseif arg_205_1.tutorInfo and not arg_205_0.tutorInfo then
				return false
			end

			if arg_203_0.reinforcePartnerRatios[arg_205_0:getTableID()] and not arg_203_0.reinforcePartnerRatios[arg_205_1:getTableID()] then
				return true
			elseif arg_203_0.reinforcePartnerRatios[arg_205_1:getTableID()] and not arg_203_0.reinforcePartnerRatios[arg_205_0:getTableID()] then
				return false
			end

			if arg_203_0.type == xyd.SelectTeamType.INCUBUS or arg_203_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_203_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER then
				local var_205_0 = arg_203_0:isBanned(arg_205_0)
				local var_205_1 = arg_203_0:isBanned(arg_205_1)

				if (var_205_0 or var_205_1) and (not var_205_0 or not var_205_1) then
					return var_205_1
				end
			elseif arg_203_0.type == xyd.SelectTeamType.ADVANCED then
				local var_205_2 = arg_203_0:isRecommend(arg_205_0)
				local var_205_3 = arg_203_0:isRecommend(arg_205_1)

				if (var_205_2 or var_205_3) and (not var_205_2 or not var_205_3) then
					return var_205_2
				end
			elseif arg_203_0.type == xyd.SelectTeamType.CAMPAIGN and arg_203_0.ispreperation then
				local var_205_4 = arg_203_0:isRecommend(arg_205_0)
				local var_205_5 = arg_203_0:isRecommend(arg_205_1)

				if (var_205_4 or var_205_5) and (not var_205_4 or not var_205_5) then
					return var_205_4
				end
			end

			if (arg_205_0.can_rent or arg_205_1.can_rent) and (not arg_205_0.can_rent or not arg_205_1.can_rent) then
				return arg_205_0.can_rent and not arg_205_1.can_rent
			end

			return xyd.heroNormalSort(arg_205_0, arg_205_1) or false
		end)
	end
end

function var_0_0.checkIsAssistBattle(arg_206_0)
	if arg_206_0.campaignType == xyd.CampaignType.NORMAL then
		local var_206_0, var_206_1 = arg_206_0:getBattleID()

		if var_206_1 then
			arg_206_0.preHeros_ = {}
			arg_206_0.preSelect_ = {}

			local var_206_2 = {}
			local var_206_3 = var_0_15:assistPartner(var_206_0)

			if not var_206_3 or not next(var_206_3) or #var_206_3 ~= 2 then
				return false
			end

			local var_206_4 = {}
			local var_206_5 = var_0_1.new()

			var_206_5:populateWithTableID(var_206_3[arg_206_0.assistID])
			table.insert(var_206_2, var_206_5)

			var_206_5.type = var_0_18.SELF_HERO
			var_206_5.isAssist = true
			arg_206_0.assistHeroID = var_206_5:getModelID()

			if #var_206_2 < xyd.MAX_TEAM_MEMBER_NUM then
				local var_206_6 = xyd.MAX_TEAM_MEMBER_NUM - #var_206_2

				for iter_206_0 = 1, var_206_6 do
					local var_206_7 = arg_206_0.selfPlayer:getHeroByID(iter_206_0)

					if var_206_7 then
						table.insert(var_206_2, var_206_7)
					end
				end

				table.sort(var_206_2, function(arg_207_0, arg_207_1)
					return arg_207_0:getDistance() < arg_207_1:getDistance()
				end)

				for iter_206_1, iter_206_2 in ipairs(var_206_2) do
					table.insert(arg_206_0.preSelect_, iter_206_2:getHeroID())
					table.insert(arg_206_0.preHeros_, iter_206_2)
				end

				return true
			end
		end

		return false
	end

	return false
end

function var_0_0.loadPreFormation(arg_208_0)
	if arg_208_0.type == xyd.SelectTeamType.TREASURE_DEFENSE or arg_208_0.type == xyd.SelectTeamType.ADVANCED or arg_208_0.type == xyd.SelectTeamType.ADJUST_TROOP or arg_208_0.type == xyd.SelectTeamType.PET_PRACTICE or arg_208_0.type == xyd.SelectTeamType.SUMMER_FIGHT_BOSS or arg_208_0.type == xyd.SelectTeamType.TUTOR or arg_208_0.type == xyd.SelectTeamType.RAGNAROK then
		return
	end

	if arg_208_0.type == xyd.SelectTeamType.CHALLENGE then
		arg_208_0.preHeros_ = {}
		arg_208_0.preSelect_ = {}

		if var_0_15:modeType(arg_208_0.battleID) == xyd.ChallengeType.KillSteal then
			local var_208_0 = var_0_1.new()

			var_208_0:populateWithTableID(var_0_15:killingHero(arg_208_0.battleID))
			table.insert(arg_208_0.preSelect_, -1)
			table.insert(arg_208_0.preHeros_, var_208_0)

			var_208_0.type = var_0_18.SELF_HERO
			var_208_0.isChallengeKillSteal_ = true

			return
		elseif var_0_15:modeType(arg_208_0.battleID) == xyd.ChallengeType.Protect then
			local var_208_1 = var_0_1.new()

			var_208_1:populateWithTableID(var_0_15:protectedHero(arg_208_0.battleID))
			table.insert(arg_208_0.preSelect_, -1)
			table.insert(arg_208_0.preHeros_, var_208_1)

			var_208_1.type = var_0_18.SELF_HERO
			var_208_1.isChallengeProtected_ = true

			return
		elseif var_0_15:modeType(arg_208_0.battleID) == xyd.ChallengeType.OneHeroKillAll then
			return
		end
	end

	if arg_208_0.selectSpType == xyd.SelectSpType.ASSIST and arg_208_0.assistID then
		local var_208_2 = var_0_1.new()

		var_208_2:populateWithTableID(arg_208_0.assistID)

		var_208_2.isAssist = true
		arg_208_0.preSelect_ = {
			-1
		}
		arg_208_0.preHeros_ = {
			var_208_2
		}

		return
	end

	if arg_208_0.type == xyd.SelectTeamType.HERO_PRESET then
		if arg_208_0.preHeros_ then
			for iter_208_0, iter_208_1 in pairs(arg_208_0.preHeros_) do
				iter_208_1.type = var_0_18.SELF_HERO
			end
		end

		return
	end

	if arg_208_0:checkIsAssistBattle() then
		arg_208_0.isAssistBattle = true

		return
	end

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		arg_208_0.preSelect_ = {
			1,
			2,
			3
		}
		arg_208_0.preHeros_ = {}

		table.insert(arg_208_0.preHeros_, arg_208_0.selfPlayer:getHeroByID(1))
		table.insert(arg_208_0.preHeros_, arg_208_0.selfPlayer:getHeroByID(2))
		table.insert(arg_208_0.preHeros_, arg_208_0.selfPlayer:getHeroByID(3))

		return
	end

	local var_208_3 = {}
	local var_208_4 = {}
	local var_208_5 = xyd.db.formation:getFormationData(arg_208_0.campaignType) or {}
	local var_208_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	local var_208_7 = var_208_5[1] or {}

	for iter_208_2, iter_208_3 in ipairs(var_208_7) do
		if arg_208_0.type == xyd.SelectTeamType.TWO_YEARS then
			local var_208_8 = var_208_6:getFightHeroes()

			for iter_208_4, iter_208_5 in pairs(var_208_8) do
				if iter_208_5:getHeroID() == iter_208_3 then
					iter_208_5.type = var_0_18.SELF_HERO

					table.insert(var_208_3, iter_208_3)
					table.insert(var_208_4, iter_208_5)
				end
			end
		elseif iter_208_3 < 0 and arg_208_0.type == xyd.SelectTeamType.MARCH then
			iter_208_3 = -iter_208_3

			for iter_208_6, iter_208_7 in pairs(arg_208_0.allTeamHeros) do
				if iter_208_7:getHeroID() == iter_208_3 and #var_208_3 < xyd.MAX_TEAM_MEMBER_NUM and not xyd.isInTable(arg_208_0.campaignLimit, iter_208_7:getFromType()) then
					iter_208_7.type = var_0_18.RENT_HERO

					table.insert(var_208_3, -iter_208_3)
					table.insert(var_208_4, iter_208_7)

					break
				end
			end
		else
			local var_208_9 = arg_208_0.selfPlayer:getHeroByID(iter_208_3)

			if var_208_9 and arg_208_0.campaignType == xyd.CampaignType.CONQUER_SCHOOL and arg_208_0:checkHeroIsConquerUsed(var_208_9) then
				return
			end

			if var_208_9 and #var_208_3 < xyd.MAX_TEAM_MEMBER_NUM and not xyd.isInTable(arg_208_0.campaignLimit, var_208_9:getFromType()) then
				var_208_9.type = var_0_18.SELF_HERO

				table.insert(var_208_3, iter_208_3)
				table.insert(var_208_4, var_208_9)
			end
		end
	end

	arg_208_0.preSelect_ = var_208_3
	arg_208_0.preHeros_ = var_208_4

	local var_208_10 = var_208_5[2] or {}

	for iter_208_8, iter_208_9 in ipairs(var_208_10) do
		local var_208_11 = arg_208_0.selfPlayer:getPetByID(iter_208_9)

		if var_208_11 and var_208_11 and #arg_208_0.prePet_ < xyd.MAX_PET_NUMBER then
			table.insert(arg_208_0.prePet_, var_208_11)
		end
	end
end

function var_0_0.willClose(arg_209_0)
	if arg_209_0.handle_ then
		var_0_13.unscheduleGlobal(arg_209_0.handle_)
	end

	if arg_209_0.handleDefense_ then
		var_0_13.unscheduleGlobal(arg_209_0.handleDefense_)
	end

	if arg_209_0.dreamWorldHandle then
		var_0_13.unscheduleGlobal(arg_209_0.dreamWorldHandle)
	end

	local var_209_0 = xyd.WindowManager.get():getWindow("guild_map_detail_window")

	if var_209_0 and arg_209_0.campaignType == xyd.CampaignType.GUILD then
		var_209_0.prepareTime = arg_209_0.guild:getPrepareTime(arg_209_0.campaignID)
		var_209_0.fightPlayerID = nil
		var_209_0.fightPlayerName = nil
		var_209_0.fightPlayerLev = nil
		var_209_0.fightPlayerAvatar = nil

		var_209_0:initPrepareWindow()
	end

	local var_209_1 = xyd.WindowManager.get():getWindow("pet_campaign")

	if var_209_1 and xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_ONE then
		var_209_1:playGuide(1)
	end

	local var_209_2 = xyd.StoryData.get():getGuideID()

	if var_209_2 >= xyd.GuideStoryType.GUIDE_FIGHT_5_TWO and var_209_2 < xyd.GuideStoryType.GUIDE_FIGHT_5_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_TWO, true)

		local var_209_3 = xyd.WindowManager.get():getWindow("map_detail_window")

		if var_209_3 and not tolua.isnull(var_209_3) then
			var_209_3:playGuide()
		end
	end
end

function var_0_0.canRentHero(arg_210_0)
	if arg_210_0.isMercenary and (arg_210_0.type ~= xyd.SelectTeamType.CHALLENGE or var_0_15:modeType(arg_210_0.battleID) ~= xyd.ChallengeType.OneHeroKillAll) then
		return true
	end

	return false
end

function var_0_0.isPet(arg_211_0)
	if not arg_211_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	if arg_211_0.banPet then
		return false
	end

	if arg_211_0.type == xyd.SelectTeamType.TREASURE_DEFENSE or arg_211_0.type == xyd.SelectTeamType.ADVANCED then
		return false
	end

	if arg_211_0.campaignType == xyd.CampaignType.NORMAL or arg_211_0.campaignType == xyd.CampaignType.SUPER or arg_211_0.campaignType == xyd.CampaignType.GUILD or arg_211_0.campaignType == xyd.CampaignType.NIAN_BOSS or arg_211_0.campaignType == xyd.CampaignType.WU or arg_211_0.campaignType == xyd.CampaignType.SHU or arg_211_0.campaignType == xyd.CampaignType.WEI or arg_211_0.campaignType == xyd.CampaignType.MOMIAN or arg_211_0.campaignType == xyd.CampaignType.WUMIAN or arg_211_0.campaignType == xyd.CampaignType.PROPHESY_JIUWEI or arg_211_0.campaignType == xyd.CampaignType.PROPHESY_NIAN or arg_211_0.campaignType == xyd.CampaignType.PROPHESY_QIUBITE or arg_211_0.campaignType == xyd.CampaignType.PROPHESY_YUAN or arg_211_0.campaignType == xyd.CampaignType.PROPHESY_SINGLE_DOG or arg_211_0.campaignType == xyd.CampaignType.PROPHESY_SONGZHONGJI or arg_211_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN or arg_211_0.campaignType == xyd.CampaignType.PET or arg_211_0.campaignType == xyd.CampaignType.REGION_ARENA or arg_211_0.campaignType == xyd.CampaignType.ILLUSION or arg_211_0.campaignType == xyd.CampaignType.CONQUER_SCHOOL or arg_211_0.campaignType == xyd.CampaignType.SAKURA2_COMPETITOR or arg_211_0.campaignType == xyd.CampaignType.SAKURA2_WAR or arg_211_0.campaignType == xyd.CampaignType.STUDENT_OVER or arg_211_0.campaignType == xyd.CampaignType.ZHUGE_NOTE or arg_211_0.campaignType == xyd.CampaignType.ZHUGE_BOSS or arg_211_0.campaignType == xyd.CampaignType.MEMORIES_OF_SCHOOL or arg_211_0.campaignType == xyd.CampaignType.SUMMER_FIGHT_BOSS or arg_211_0.campaignType == xyd.CampaignType.TWO_YEARS or arg_211_0.campaignType == xyd.CampaignType.ARENA or arg_211_0.campaignType == xyd.CampaignType.ADVENTURE_ILLUSION_SINGLE or arg_211_0.campaignType == xyd.CampaignType.ADVENTURE_DEFENSE or arg_211_0.campaignType == xyd.CampaignType.CHAPTER_BOSS or arg_211_0.campaignType == xyd.CampaignType.THIRD_ANNIVERSARY_BOSS or arg_211_0.campaignType == xyd.CampaignType.SUPER_RICH_CHALLENGE or arg_211_0.campaignType == xyd.CampaignType.CHOCOLATE or arg_211_0.campaignType == xyd.CampaignType.DREAM_WORLD or arg_211_0.campaignType == xyd.CampaignType.FOURTH_ANNI_MAP or arg_211_0.campaignType == xyd.CampaignType.ALL_NIGHT_MAP or arg_211_0.campaignType == xyd.CampaignType.RAGNAROK_MAP or arg_211_0.campaignType == xyd.CampaignType.RAGNAROK or arg_211_0.campaignType == xyd.CampaignType.FIFTH_ANNIVERSARY_BOSS or arg_211_0.campaignType == xyd.CampaignType.HUNQI then
		return true
	end

	return false
end

function var_0_0.formatRegionArenaHeros(arg_212_0, arg_212_1)
	for iter_212_0, iter_212_1 in pairs(arg_212_1) do
		if iter_212_1:isHaveAwakenItem() and not iter_212_1:isAwaken() then
			local var_212_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_212_1 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_212_2 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_212_0:renewHeroInfo(iter_212_1, var_212_0, var_212_1, var_212_2)
		elseif iter_212_1:isAwaken() then
			local var_212_3 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_212_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_212_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_212_0:renewHeroInfo(iter_212_1, var_212_3, var_212_4, var_212_5)
		else
			local var_212_6 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_212_7 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_212_8 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_212_0:renewHeroInfo(iter_212_1, var_212_6, var_212_7, var_212_8)
		end

		iter_212_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_212_1:updatePracticeAwardAttr()
	end
end

function var_0_0.formatRegionArenaPets(arg_213_0, arg_213_1)
	for iter_213_0, iter_213_1 in pairs(arg_213_1) do
		if iter_213_1:isHaveAwakenItem() and not iter_213_1:isAwaken() then
			local var_213_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_213_1 = {
				1,
				1,
				1
			}

			arg_213_0:renewPetInfo(iter_213_1, var_213_0, var_213_1)
		elseif iter_213_1:isAwaken() then
			local var_213_2 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_213_3 = {
				1,
				1,
				1
			}

			arg_213_0:renewPetInfo(iter_213_1, var_213_2, var_213_3)
		else
			local var_213_4 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_213_5 = {
				0,
				1,
				1
			}

			arg_213_0:renewPetInfo(iter_213_1, var_213_4, var_213_5)
		end

		iter_213_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_213_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_214_0, arg_214_1, arg_214_2, arg_214_3, arg_214_4)
	local var_214_0 = xyd.tables.misc.regionHeroColor

	arg_214_1.level_, arg_214_1.color_ = xyd.tables.misc.regionHeroLevel, var_214_0
	arg_214_1.skillLev_ = {}
	arg_214_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_214_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_214_1.color_ >= xyd.EquipQuality.GREEN then
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_214_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_214_1.color_ >= xyd.EquipQuality.BLUE then
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_214_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_214_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_214_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_214_1:isAwaken() then
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_214_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_214_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_214_1.equips_ = {}

	for iter_214_0 = 1, var_0_8 do
		table.insert(arg_214_1.equips_, tonumber(arg_214_4[iter_214_0]))
	end

	arg_214_1.fumo_ = {}

	for iter_214_1 = 1, var_0_8 do
		table.insert(arg_214_1.fumo_, tonumber(arg_214_3[iter_214_1]))
	end

	arg_214_1.fumoLev_ = {}

	for iter_214_2 = 1, var_0_8 do
		local var_214_1 = arg_214_1:getEquipByIndex(iter_214_2)

		table.insert(arg_214_1.fumoLev_, tonumber(var_214_1:getMaxFumoStar()))
	end
end

function var_0_0.renewPetInfo(arg_215_0, arg_215_1, arg_215_2, arg_215_3)
	local var_215_0 = 14

	arg_215_1.level_, arg_215_1.color_ = 90, var_215_0
	arg_215_1.skillLev_ = {}
	arg_215_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_215_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_215_1.color_ >= xyd.EquipQuality.GREEN then
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_215_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_215_1.color_ >= xyd.EquipQuality.BLUE then
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_215_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_215_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_215_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_215_1:isAwaken() then
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_215_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_215_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_215_1.equips_ = {}

	for iter_215_0 = 1, var_0_8 do
		table.insert(arg_215_1.equips_, tonumber(arg_215_3[iter_215_0]))
	end
end

function var_0_0.getHeros(arg_216_0)
	local var_216_0

	if arg_216_0.type and arg_216_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_216_0.type == xyd.SelectTeamType.REGION_ARENA or arg_216_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		var_216_0 = {}

		for iter_216_0, iter_216_1 in ipairs(arg_216_0.selfPlayer.heros_) do
			local var_216_1 = var_0_1.new()

			var_216_1:populate(iter_216_1:toParams())
			table.insert(var_216_0, var_216_1)
		end

		local var_216_2 = {}

		for iter_216_2, iter_216_3 in ipairs(arg_216_0.preHeros_) do
			local var_216_3 = var_0_1.new()

			var_216_3:populate(iter_216_3:toParams())
			table.insert(var_216_2, var_216_3)
		end

		local var_216_4 = arg_216_0.regionAwards

		arg_216_0:initRegionHeros(var_216_0, var_216_4)
		xyd.formatRegionArenaHeros(var_216_0)
		xyd.formatRegionArenaHeros(var_216_2)

		arg_216_0.preHeros_ = var_216_2
	elseif arg_216_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_216_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		local var_216_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)

		var_216_0 = {}

		for iter_216_4, iter_216_5 in ipairs(arg_216_0.selfPlayer.heros_) do
			local var_216_6 = var_0_1.new()

			var_216_6:populate(iter_216_5:toParams())
			table.insert(var_216_0, var_216_6)
		end

		var_216_5:formatNewHeros(var_216_0)

		local var_216_7 = {}

		for iter_216_6, iter_216_7 in ipairs(arg_216_0.preHeros_) do
			local var_216_8 = var_0_1.new()

			var_216_8:populate(iter_216_7:toParams())
			table.insert(var_216_7, var_216_8)
		end

		var_216_5:formatNewHeros(var_216_7)

		arg_216_0.preHeros_ = var_216_7
	elseif arg_216_0.type == xyd.SelectTeamType.SUMMER_FIGHT_BOSS then
		local var_216_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)

		var_216_0 = clone(arg_216_0.selfPlayer.heros_)

		var_216_9:formatLvbuCampusHeros(var_216_0)
	elseif arg_216_0.type == xyd.SelectTeamType.TWO_YEARS then
		var_216_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS):getFightHeroes()
	elseif arg_216_0.type == xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS then
		var_216_0 = {}

		for iter_216_8, iter_216_9 in ipairs(arg_216_0.selfPlayer.heros_) do
			local var_216_10 = var_0_1.new()

			var_216_10:populate(iter_216_9:toParams())
			table.insert(var_216_0, var_216_10)
		end

		arg_216_0.thirdAnniversary:formatNewHeros(var_216_0)

		local var_216_11 = {}

		for iter_216_10, iter_216_11 in ipairs(arg_216_0.preHeros_) do
			local var_216_12 = var_0_1.new()

			var_216_12:populate(iter_216_11:toParams())
			table.insert(var_216_11, var_216_12)
		end

		arg_216_0.thirdAnniversary:formatNewHeros(var_216_11)

		arg_216_0.preHeros_ = var_216_11
	elseif arg_216_0.type == xyd.SelectTeamType.TUTOR then
		var_216_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TUTOR):getHeros(tostring(arg_216_0.campaignID))
	elseif arg_216_0.type == xyd.SelectTeamType.DREAM_WORLD then
		local var_216_13 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)

		if var_216_13.mapType == xyd.DreamWorldType.STORY then
			var_216_0 = {}

			for iter_216_12, iter_216_13 in ipairs(xyd.tables.hero:getAllHeroes()) do
				local var_216_14 = xyd.getOriginHeroId(iter_216_13)

				if var_0_16:isCanAwaken(var_216_14) == 0 then
					iter_216_13 = var_216_14
				else
					iter_216_13 = var_0_16:afterAwaken(var_216_14)
				end

				if arg_216_0.totalIDs_[var_216_14] == nil and xyd.tables.hero:isLibraryShow(var_216_14) then
					local var_216_15 = var_0_1.new()

					var_216_15:initUnCollected(iter_216_13, 1)

					arg_216_0.totalIDs_[var_216_14] = var_216_15

					table.insert(var_216_0, var_216_15)
				end
			end

			var_216_13:formatNewHeros(var_216_0)

			arg_216_0.preHeros_ = {}
		else
			var_216_0 = arg_216_0.selfPlayer.heros_
			arg_216_0.preHeros_ = {}
		end
	elseif arg_216_0.type == xyd.SelectTeamType.RAGNAROK then
		var_216_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):getHeros()
	else
		var_216_0 = arg_216_0.selfPlayer.heros_
	end

	return var_216_0
end

function var_0_0.getPets(arg_217_0)
	local var_217_0

	if arg_217_0.type and arg_217_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_217_0.type == xyd.SelectTeamType.REGION_ARENA or arg_217_0.type == xyd.SelectTeamType.TWO_YEARS or arg_217_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		var_217_0 = {}

		for iter_217_0, iter_217_1 in ipairs(arg_217_0.selfPlayer.collectedPets) do
			local var_217_1 = var_0_3.new()

			var_217_1:populate(iter_217_1:toParams())

			if arg_217_0.type == xyd.SelectTeamType.TWO_YEARS then
				var_217_1.star_ = xyd.MAX_STAR_LEVEL
			end

			table.insert(var_217_0, var_217_1)
		end

		local var_217_2 = {}

		for iter_217_2, iter_217_3 in ipairs(arg_217_0.prePet_) do
			local var_217_3 = var_0_3.new()

			var_217_3:populate(iter_217_3:toParams())

			if arg_217_0.type == xyd.SelectTeamType.TWO_YEARS then
				var_217_3.star_ = xyd.MAX_STAR_LEVEL
			end

			table.insert(var_217_2, var_217_3)
		end

		xyd.formatRegionArenaPets(var_217_0)
		xyd.formatRegionArenaPets(var_217_2)

		arg_217_0.prePet_ = var_217_2
	elseif arg_217_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_217_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		local var_217_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)

		var_217_0 = {}

		for iter_217_4, iter_217_5 in ipairs(arg_217_0.selfPlayer.collectedPets) do
			local var_217_5 = var_0_3.new()

			var_217_5:populate(iter_217_5:toParams())
			table.insert(var_217_0, var_217_5)
		end

		local var_217_6 = {}

		for iter_217_6, iter_217_7 in ipairs(arg_217_0.prePet_) do
			local var_217_7 = var_0_3.new()

			var_217_7:populate(iter_217_7:toParams())
			table.insert(var_217_6, var_217_7)
		end

		var_217_4:formatNewPets(var_217_0)
		var_217_4:formatNewPets(var_217_6)

		arg_217_0.prePet_ = var_217_6
	elseif arg_217_0.type == xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS then
		var_217_0 = {}

		for iter_217_8, iter_217_9 in ipairs(arg_217_0.selfPlayer.collectedPets) do
			local var_217_8 = var_0_3.new()

			var_217_8:populate(iter_217_9:toParams())
			table.insert(var_217_0, var_217_8)
		end

		local var_217_9 = {}

		for iter_217_10, iter_217_11 in ipairs(arg_217_0.prePet_) do
			local var_217_10 = var_0_3.new()

			var_217_10:populate(iter_217_11:toParams())
			table.insert(var_217_9, var_217_10)
		end

		arg_217_0.thirdAnniversary:formatNewPets(var_217_0)
		arg_217_0.thirdAnniversary:formatNewPets(var_217_9)

		arg_217_0.prePet_ = var_217_9
	elseif arg_217_0.type == xyd.SelectTeamType.DREAM_WORLD then
		local var_217_11 = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)

		if var_217_11.mapType == xyd.DreamWorldType.STORY then
			var_217_0 = {}

			for iter_217_12, iter_217_13 in pairs(var_0_16:getPetsIgnoreShow()) do
				local var_217_12 = var_0_16:beforeAwaken(iter_217_13)

				if var_217_12 == 0 then
					var_217_12 = iter_217_13
				end

				if var_0_16:isCanAwaken(var_217_12) == 0 then
					iter_217_13 = var_217_12
				else
					iter_217_13 = var_0_16:afterAwaken(var_217_12)
				end

				if arg_217_0.totalIDs_[var_217_12] == nil and xyd.tables.hero:isLibraryShow(var_217_12) then
					local var_217_13 = var_0_3.new()
					local var_217_14 = {
						is_show = 1,
						star = xyd.MAX_STAR_LEVEL
					}

					var_217_13:initUnCollected(iter_217_13, nil, var_217_14)

					arg_217_0.totalIDs_[var_217_12] = var_217_13

					table.insert(var_217_0, var_217_13)
				end
			end

			var_217_11:formatNewPets(var_217_0)

			arg_217_0.prePet_ = {}
		else
			var_217_0 = arg_217_0.selfPlayer.collectedPets
			arg_217_0.prePet_ = {}
		end
	elseif arg_217_0.type == xyd.SelectTeamType.RAGNAROK then
		var_217_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK):getPets()
	else
		var_217_0 = arg_217_0.selfPlayer.collectedPets
	end

	return var_217_0
end

function var_0_0.initRegionPets(arg_218_0, arg_218_1)
	return
end

function var_0_0.initRegionHeros(arg_219_0, arg_219_1, arg_219_2, arg_219_3)
	for iter_219_0, iter_219_1 in pairs(arg_219_2) do
		local var_219_0 = arg_219_0:checkHeroExit(arg_219_1, iter_219_1.table_id)

		if not var_219_0 and arg_219_3 then
			-- block empty
		else
			if iter_219_1.is_summon == 1 and not var_219_0 then
				var_219_0 = var_0_1.new()

				var_219_0:initUnCollected(iter_219_1.table_id)
				table.insert(arg_219_1, var_219_0)
			end

			if iter_219_1.add_star > 0 then
				local var_219_1 = var_219_0:getStar()

				if not xyd.isSuperHero(var_219_0) then
					if var_219_1 + iter_219_1.add_star > xyd.MAX_STAR_LEVEL then
						var_219_0:setStar(xyd.MAX_STAR_LEVEL)
					else
						var_219_0:setStar(var_219_1 + iter_219_1.add_star)
					end
				elseif var_219_1 + iter_219_1.add_star > xyd.SUPER_HERO_TOTAL_STARS then
					var_219_0:setStar(xyd.SUPER_HERO_TOTAL_STARS)
				else
					var_219_0:setStar(var_219_1 + iter_219_1.add_star)
				end
			end

			if iter_219_1.is_awake == 1 and not var_219_0:isAwaken() then
				var_219_0:setTableID(xyd.tables.hero:afterAwaken(iter_219_1.table_id))
			end

			if var_219_0 and var_219_0:awakeTwiceStage() == 0 and var_219_0.setAwakeTwiceStage then
				if iter_219_1.twice_awake_stage then
					var_219_0:setAwakeTwiceStage(iter_219_1.twice_awake_stage)
				else
					var_219_0:setAwakeTwiceStage(0)
				end
			end
		end
	end
end

function var_0_0.checkHeroExit(arg_220_0, arg_220_1, arg_220_2)
	local var_220_0 = false

	for iter_220_0, iter_220_1 in pairs(arg_220_1) do
		local var_220_1 = iter_220_1:getTableID()

		if var_220_1 == arg_220_2 then
			var_220_0 = iter_220_1

			break
		end

		if iter_220_1:isAwaken() then
			var_220_1 = iter_220_1:beforeAwakenID()
		end

		if var_220_1 == arg_220_2 then
			var_220_0 = iter_220_1

			break
		end
	end

	return var_220_0
end

function var_0_0.isRecommend(arg_221_0, arg_221_1)
	local var_221_0 = arg_221_1:getTableID()

	if var_0_16:beforeAwaken(var_221_0) > 0 then
		var_221_0 = var_0_16:beforeAwaken(var_221_0)
	end

	for iter_221_0 = 1, #arg_221_0.recommendHeros do
		if var_221_0 == arg_221_0.recommendHeros[iter_221_0] then
			return true
		end
	end

	return false
end

function var_0_0.initRecommend(arg_222_0)
	arg_222_0:nodeByName("recommend_layer"):setVisible(true)
	arg_222_0:nodeByName("recommend_txt"):setString(var_0_14:translation("RECOMMENDED_HERO"))

	for iter_222_0 = 1, #arg_222_0.recommendHeros do
		xyd.setAvatarBorderNewUI(arg_222_0.recommendHeros[iter_222_0], arg_222_0:nodeByName("recommend_hero" .. iter_222_0), true, var_0_16:initialStar(arg_222_0.recommendHeros[iter_222_0]))

		local var_222_0 = {}
		local var_222_1 = cc.Node:create()

		var_222_1:setAnchorPoint(cc.p(0, 0))
		var_222_1:setContentSize(100, 100)
		arg_222_0:nodeByName("recommend_hero" .. iter_222_0):addChild(var_222_1)

		var_222_0.id = arg_222_0.recommendHeros[iter_222_0]
		var_222_0.desc = xyd.tables.hero:getDes(arg_222_0.recommendHeros[iter_222_0])
		var_222_0.name = xyd.tables.hero:name(arg_222_0.recommendHeros[iter_222_0])
		var_222_0.isHero = true

		var_222_1:setTouchEnabled(true)
		var_222_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_223_0)
			if arg_223_0.name == "began" then
				local var_223_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_223_1 = arg_222_0:convertToWorldSpace(cc.p(0, 0))

				if not var_223_0 then
					local var_223_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_222_0)

					xyd.adaptToWorldPosition(var_222_1, var_223_2)
				end

				return true
			elseif arg_223_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_223_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

function var_0_0.isBanned(arg_224_0, arg_224_1)
	local var_224_0 = arg_224_1:getTableID()

	if var_0_16:beforeAwaken(var_224_0) > 0 then
		var_224_0 = var_0_16:beforeAwaken(var_224_0)
	end

	for iter_224_0 = 1, #arg_224_0.bannedHeros do
		if var_224_0 == arg_224_0.bannedHeros[iter_224_0] then
			return true
		end
	end

	return false
end

function var_0_0.checkHeroIsNotUse(arg_225_0, arg_225_1)
	if arg_225_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_225_0:checkHeroIsConquerUsed(arg_225_1) then
		return true
	elseif arg_225_0.type == xyd.SelectTeamType.TUTOR and arg_225_1.useTime > 0 then
		return true
	end

	return false
end

function var_0_0.checkHeroIsConquerUsed(arg_226_0, arg_226_1)
	if arg_226_0.conquerUsedTeam and arg_226_0.conquerUsedTeam.heroIDs then
		local var_226_0 = arg_226_0.conquerUsedTeam.heroIDs

		for iter_226_0, iter_226_1 in pairs(var_226_0) do
			if iter_226_1 == arg_226_1:getHeroID() then
				return true
			end
		end
	end

	return false
end

function var_0_0.checkPetIsConquerUsed(arg_227_0, arg_227_1)
	if arg_227_0.conquerUsedTeam and arg_227_0.conquerUsedTeam.petIDs then
		local var_227_0 = arg_227_0.conquerUsedTeam.petIDs

		for iter_227_0, iter_227_1 in pairs(var_227_0) do
			if iter_227_1 == arg_227_1:getPetID() then
				return true
			end
		end
	end

	return false
end

function var_0_0.checkHeroIsSeal(arg_228_0, arg_228_1)
	if arg_228_0.sealHeroID and arg_228_0.sealHeroID > 0 and arg_228_1:getFirstTableID() == arg_228_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.checkCanPresetTeam(arg_229_0)
	if arg_229_0.type == xyd.SelectTeamType.HERO_PRESET or arg_229_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_229_0.type == xyd.SelectTeamType.ZHUGE_NOTE or arg_229_0.type == xyd.SelectTeamType.TUTOR then
		return false
	end

	return true
end

function var_0_0.startSakura2CompetitorBattle(arg_230_0)
	local var_230_0 = {
		herosA = {}
	}

	for iter_230_0, iter_230_1 in ipairs(arg_230_0.team_) do
		table.insert(var_230_0.herosA, iter_230_1.data)
	end

	var_230_0.petsA = {}

	for iter_230_2, iter_230_3 in ipairs(arg_230_0.petSelect_) do
		table.insert(var_230_0.petsA, iter_230_3)
	end

	var_230_0.campaignType = xyd.CampaignType.SAKURA2_COMPETITOR
	var_230_0.campaignID = 0
	var_230_0.herosB = {
		arg_230_0.enemyHeroes_
	}
	var_230_0.petsB = {}

	table.insert(var_230_0.petsB, arg_230_0.enemyPets_)

	var_230_0.battleID = xyd.MapBattleID.ARENA
	var_230_0.formation = arg_230_0:getFormationStr(var_230_0.herosA)

	xyd.pushBattleScene(var_230_0)
end

function var_0_0.startSakura2WarBattle(arg_231_0)
	local var_231_0 = {
		rentFlag = rentFlag,
		campaignType = arg_231_0.campaignType,
		campaignID = arg_231_0.campaignID,
		itemComposeID = arg_231_0.itemComposeID,
		battleID = xyd.tables.activitySakura2Campaign:fightId(arg_231_0.campaignID),
		herosA = {}
	}

	for iter_231_0, iter_231_1 in ipairs(arg_231_0.team_) do
		iter_231_1.data.type = iter_231_1.type

		if iter_231_1.type == var_0_18.RENT_HERO then
			rentFlag = true
		end

		table.insert(var_231_0.herosA, iter_231_1.data)
	end

	var_231_0.petsA = {}

	for iter_231_2, iter_231_3 in ipairs(arg_231_0.petSelect_) do
		table.insert(var_231_0.petsA, iter_231_3)
	end

	local var_231_1 = var_0_15:monsters(var_231_0.battleID)

	var_231_0.herosB = {}
	var_231_0.petsB = {}

	for iter_231_4 = 1, #var_231_1 do
		local var_231_2 = {}

		for iter_231_5, iter_231_6 in ipairs(var_231_1[iter_231_4]) do
			if xyd.tables.hero:summonType(iter_231_6) ~= 4 then
				local var_231_3 = arg_231_0.sakura:populateMonsterWithTableID(iter_231_6)

				table.insert(var_231_2, var_231_3)
			else
				local var_231_4 = arg_231_0.sakura:populatePetWithTableID(iter_231_6)

				table.insert(var_231_0.petsB, var_231_4)
			end
		end

		if next(var_231_2) then
			table.insert(var_231_0.herosB, var_231_2)
		end
	end

	var_231_0.formation = arg_231_0:getFormationStr(var_231_0.herosA)

	arg_231_0.sakura:setPreHerosFormation(var_231_0.formation)

	if var_231_0.petsA and next(var_231_0.petsA) then
		arg_231_0.sakura:setPrePetFormation(var_231_0.petsA[1]:getPetID())
	end

	local var_231_5 = xyd.tables.activitySakura2Campaign:preWarStory(arg_231_0.campaignID)

	if var_231_5 and var_231_5 ~= "" then
		local function var_231_6()
			xyd.pushBattleScene(var_231_0)
		end

		xyd.WindowManager.get():openWindow("school_story_talk", {
			callback = var_231_6,
			talk_id = var_231_5
		})
	else
		xyd.pushBattleScene(var_231_0)
	end
end

function var_0_0.startChapterBossFight(arg_233_0)
	local var_233_0 = {
		rentFlag = rentFlag,
		chapter_id = arg_233_0.chapter,
		campaignType = arg_233_0.campaignType,
		battleID = arg_233_0.battleID,
		herosA = {}
	}
	local var_233_1 = {}
	local var_233_2 = false

	for iter_233_0, iter_233_1 in ipairs(arg_233_0.team_) do
		iter_233_1.data.type = iter_233_1.type

		if iter_233_1.type == var_0_18.RENT_HERO then
			var_233_2 = true
		else
			table.insert(var_233_1, iter_233_1.data)
		end

		table.insert(var_233_0.herosA, iter_233_1.data)
	end

	var_233_0.petsA = {}

	for iter_233_2, iter_233_3 in ipairs(arg_233_0.petSelect_) do
		table.insert(var_233_0.petsA, iter_233_3)
	end

	var_233_0.rentFlag = var_233_2
	var_233_0.formation = arg_233_0:getFormationStr(var_233_0.herosA)

	local var_233_3 = xyd.tables.battle:monsters(var_233_0.battleID)

	var_233_0.herosB = {}

	local var_233_4 = arg_233_0.selfPlayer.chapterEvents[arg_233_0.chapter] or {}
	local var_233_5 = {}

	for iter_233_4, iter_233_5 in ipairs(var_233_3[1]) do
		local var_233_6 = var_0_1.new()

		var_233_6:populateWithTableID(iter_233_5)

		local var_233_7 = {
			total_hp = var_233_4.record,
			hp = var_233_4.val
		}

		var_233_7.health = 1
		var_233_7.mp = 0
		var_233_6.healthStatus = var_233_7

		table.insert(var_233_5, var_233_6)
	end

	table.insert(var_233_0.herosB, var_233_5)

	local var_233_8 = {
		formation = arg_233_0:getFormationStr(var_233_1)
	}
	local var_233_9

	if #arg_233_0.petTeam_ ~= 0 and not arg_233_0.isSelectMerPet then
		var_233_9 = arg_233_0.petTeam_[1].data:getPetID()
	end

	var_233_8.pet_id = var_233_9

	if arg_233_0.isSelectMerPet then
		var_233_0.rent_pet_id = arg_233_0.selectMerPet:getPetID()
	end

	if arg_233_0.selectMerPet then
		var_233_8.rent_pet_player_id = arg_233_0.selectMerPet.player_id
		var_233_8.rent_pet_id = tostring(arg_233_0.selectMerPet:getPetID())
	end

	arg_233_0:handleRentParams(var_233_8)

	var_233_8.chapter_id = arg_233_0.chapter
	var_233_0.fightParams = var_233_8

	xyd.Backend.get():request(xyd.mid.START_CHAPTER_BOSS_FIGHT, var_233_8, function(arg_234_0, arg_234_1)
		if arg_234_0 == xyd.error.OK then
			if arg_233_0.selectMerHero then
				arg_233_0.guild:setUseRent(arg_233_0.selectMerHero)
			end

			if arg_233_0.selectMerPet then
				arg_233_0.guild:setUseRentPet(arg_233_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_233_0.chapterType,
						chapter = var_233_0.chapter_id
					}
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_233_0)
		end
	end)
end

function var_0_0.startThirdAnniversaryBossBattle(arg_235_0)
	local var_235_0 = false
	local var_235_1 = {
		herosA = {},
		herosB = {}
	}
	local var_235_2 = {}

	for iter_235_0, iter_235_1 in ipairs(arg_235_0.team_) do
		iter_235_1.data.type = iter_235_1.type

		if iter_235_1.type == var_0_18.RENT_HERO then
			var_235_0 = true
		else
			table.insert(var_235_2, iter_235_1.data)
		end

		table.insert(var_235_1.herosA, iter_235_1.data)
	end

	var_235_1.rentFlag = var_235_0
	var_235_1.campaignType = arg_235_0.campaignType
	var_235_1.battleID = xyd.tables.thirdAnniversaryBoss:battleID(arg_235_0.thirdAnniversary.day_count)
	var_235_1.petsA = {}

	for iter_235_2, iter_235_3 in ipairs(arg_235_0.petSelect_) do
		table.insert(var_235_1.petsA, iter_235_3)
	end

	local var_235_3 = arg_235_0:getFormationStr(var_235_2)
	local var_235_4 = {
		formation = var_235_3
	}
	local var_235_5

	if #arg_235_0.petTeam_ ~= 0 and not arg_235_0.isSelectMerPet then
		var_235_5 = arg_235_0.petTeam_[1].data:getPetID()
	end

	var_235_4.pet_id = var_235_5

	if arg_235_0.isSelectMerPet then
		var_235_1.rent_pet_id = arg_235_0.selectMerPet:getPetID()
	end

	if arg_235_0.selectMerPet then
		var_235_4.rent_pet_player_id = arg_235_0.selectMerPet.player_id
		var_235_4.rent_pet_id = tostring(arg_235_0.selectMerPet:getPetID())
	end

	arg_235_0:handleRentParams(var_235_4)

	var_235_1.fightParams = var_235_4
	var_235_1.formation = var_235_3

	local var_235_6 = {}

	table.insert(var_235_6, arg_235_0.thirdAnniversary:getBossID())

	var_235_1.herosB = {}

	if not arg_235_0.thirdAnniversary then
		local var_235_7 = {}
	end

	local var_235_8 = {}

	for iter_235_4, iter_235_5 in ipairs(var_235_6) do
		local var_235_9 = var_0_1.new()

		var_235_9:populateWithTableID(iter_235_5)
		table.insert(var_235_8, var_235_9)
	end

	table.insert(var_235_1.herosB, var_235_8)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNIVERSARY_BOSS_START_FIGHT, var_235_4, function(arg_236_0, arg_236_1)
		if arg_236_0 == xyd.error.OK then
			if arg_235_0.selectMerHero then
				arg_235_0.guild:setUseRent(arg_235_0.selectMerHero)
			end

			arg_235_0.selfPlayer:getBackpack():removeItem({
				itemNum = 1,
				itemID = xyd.tables.misc.thirdAnniversaryBossTicket
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "third_anniversary_boss"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_235_1)
		else
			arg_235_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.setCloseBtn(arg_237_0)
	if arg_237_0.type == xyd.SelectTeamType.ADVENTURE_DEFENSE then
		arg_237_0:nodeByName("close"):addTouchEventListener(function(arg_238_0, arg_238_1)
			if arg_238_1 == ccui.TouchEventType.ended then
				local var_238_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
				local var_238_1 = {
					table_id = xyd.AdventureEventType.DEFENSE,
					monster_pos = arg_237_0.monsterPos
				}

				var_238_0:quitRoomFight(var_238_1, function(arg_239_0, arg_239_1)
					if arg_239_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_237_0)
					end
				end)
			end
		end)
	end
end

function var_0_0.updateDefenseTimeCount(arg_240_0, arg_240_1)
	local var_240_0 = arg_240_1

	if arg_240_0.handleDefense_ then
		return
	end

	local var_240_1 = xyd.tables.misc.adventureDefenseSelectTeamTimeLimit

	if var_240_1 <= 0 then
		var_240_0:setString(string.format(var_0_14:translation("GUILD_PREPARE_FIGHT"), 0))

		return
	end

	var_240_0:setString(string.format(var_0_14:translation("GUILD_PREPARE_FIGHT"), var_240_1))

	arg_240_0.handleDefense_ = var_0_13.scheduleGlobal(function()
		if var_240_0 and not tolua.isnull(var_240_0) then
			var_240_1 = var_240_1 - 1

			var_240_0:setString(string.format(var_0_14:translation("GUILD_PREPARE_FIGHT"), var_240_1))

			if var_240_1 == 0 then
				if arg_240_0.handleDefense_ then
					var_0_13.unscheduleGlobal(arg_240_0.handleDefense_)

					arg_240_0.handleDefense_ = nil
				end

				local var_241_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
				local var_241_1 = {
					table_id = xyd.AdventureEventType.DEFENSE,
					monster_pos = arg_240_0.monsterPos
				}

				var_241_0:quitRoomFight(var_241_1, function(arg_242_0, arg_242_1)
					if arg_242_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_240_0)
					end
				end)
			end
		elseif arg_240_0.handleDefense_ then
			var_0_13.unscheduleGlobal(arg_240_0.handleDefense_)

			arg_240_0.handleDefense_ = nil
		end
	end, 1)
end

function var_0_0.checkShowBlockLayer(arg_243_0)
	if arg_243_0.type == xyd.SelectTeamType.ILLUSION then
		arg_243_0:addBlockLayerWithNoTouchEvent()
	end
end

function var_0_0.addDreamWorldCoolTimeNode(arg_244_0, arg_244_1)
	if not arg_244_0.dreamWorldNode then
		arg_244_0.dreamWorldNode = {}
	end

	table.insert(arg_244_0.dreamWorldNode, arg_244_1)

	if not arg_244_0.dreamWorldHandle then
		arg_244_0.dreamWorldHandle = var_0_13.scheduleGlobal(function()
			local var_245_0 = xyd.ServerTime.get():getServerTime()

			for iter_245_0, iter_245_1 in ipairs(arg_244_0.dreamWorldNode) do
				if iter_245_1 and not tolua.isnull(iter_245_1) then
					if var_245_0 < iter_245_1.coolTime then
						iter_245_1:getChildByName("time"):setString(xyd.secondsToString(iter_245_1.coolTime - var_245_0))
					else
						iter_245_1.layout:getChildByName("avatar_mask"):setVisible(false)
						iter_245_1:removeSelf()
					end
				end
			end
		end, 1)
	end
end

function var_0_0.checkDreamWorldCoolTime(arg_246_0, arg_246_1)
	if arg_246_0.dreamWorldNode then
		for iter_246_0, iter_246_1 in ipairs(arg_246_0.dreamWorldNode) do
			if iter_246_1 and not tolua.isnull(iter_246_1) and iter_246_1.tableID == arg_246_1 then
				return true
			end
		end
	end

	return false
end

function var_0_0.clearDreamWorldCoolTimeNode(arg_247_0, arg_247_1)
	for iter_247_0, iter_247_1 in ipairs(arg_247_0.dreamWorldNode) do
		if iter_247_1 and not tolua.isnull(iter_247_1) and iter_247_1.tableID == arg_247_1 then
			iter_247_1.layout:getChildByName("avatar_mask"):setVisible(false)
			iter_247_1:removeSelf()
		end
	end
end

return var_0_0
