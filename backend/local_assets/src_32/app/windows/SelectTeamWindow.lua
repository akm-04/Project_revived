local var_0_0 = class("SelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 30
local var_0_4 = 30
local var_0_5 = 5
local var_0_6 = 4
local var_0_7 = 6
local var_0_8 = 65
local var_0_9 = 50
local var_0_10 = 90
local var_0_11 = import("app.model.Item")
local var_0_12 = import("framework.scheduler")
local var_0_13 = xyd.tables.translation
local var_0_14 = xyd.tables.battle
local var_0_15 = xyd.tables.hero
local var_0_16 = xyd.tables.marchAdvanced
local var_0_17 = {
	RENT_HERO = 2,
	SELF_HERO = 1,
	SELF_PET = 3
}
local var_0_18 = {
	RENT_HERO = 1,
	RENT_PET = 2
}
local var_0_19 = {
	RENT_PET = 2,
	SELF_PET = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.CAMPAIGN
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
	arg_1_0.rateValue = var_0_16:rateValue(arg_1_0.selfPlayer.lev)
	arg_1_0.recommendHeros = arg_1_2.recommendHeros
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
		arg_1_0.campaignLimit = var_0_14:campaignLimit(arg_1_0.battleID)

		for iter_1_0, iter_1_1 in ipairs(var_0_14:reinforcePartnerIds(arg_1_0.battleID)) do
			arg_1_0.reinforcePartnerRatios[iter_1_1] = var_0_14:reinforcePartnerRatios(arg_1_0.battleID)[iter_1_0]
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
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	if not next(arg_2_0.preSelect_) then
		arg_2_0:loadPreFormation()
	end

	arg_2_0:initHeros(arg_2_0:getHeros(), var_0_17.SELF_HERO)
	arg_2_0:initHeros(arg_2_0.allTeamHeros, var_0_17.RENT_HERO)
	arg_2_0:initPets(arg_2_0:getPets() or {}, var_0_19.SELF_PET)
	arg_2_0:initPresetTeams()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:refreshSelectedHeroClass()
	arg_3_0:getBattlepetBtn()
	arg_3_0:playGuide()
	arg_3_0:updateScore()

	if arg_3_0.isAssistBattle then
		local var_3_0 = cc.p(0, 0)

		if arg_3_0.assistHeroNode and not tolua.isnull(arg_3_0.assistHeroNode) then
			var_3_0 = arg_3_0.assistHeroNode:getParent():convertToWorldSpace(cc.p(arg_3_0.assistHeroNode:getPosition()))
		end

		local var_3_1 = {
			table_id = arg_3_0.assistHeroID,
			pos = var_3_0,
			callback = function()
				if arg_3_0.assistHeroNode and not tolua.isnull(arg_3_0.assistHeroNode) then
					local var_4_0 = cc.p(arg_3_0.assistHeroNode:getPosition())

					arg_3_0.assistHeroNode:setVisible(true)
					arg_3_0:moveFadeInAction(var_4_0.x, var_4_0.y, arg_3_0.assistHeroNode)
				end
			end
		}

		xyd.WindowManager.get():openWindow("assist_hero_show", var_3_1)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_3_0, arg_3_0.updateList))
end

function var_0_0.updateList(arg_5_0, ...)
	if arg_5_0.leftMenuType_ ~= var_0_17.SELF_HERO then
		return
	end

	arg_5_0.selectedHeroClass_[arg_5_0.leftMenuType_] = xyd.DistanceType.FILTER
	arg_5_0.isHeroPreset = false

	arg_5_0:updateFilterHeros()
	arg_5_0:refreshSelectedHeroClass()
end

function var_0_0.initEnemys(arg_6_0)
	local var_6_0 = 1

	if arg_6_0.type and arg_6_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_6_0.type == xyd.SelectTeamType.REGION_ARENA then
		xyd.formatRegionArenaHeros(arg_6_0.enemyHeroes_)
		xyd.formatRegionArenaPets({
			arg_6_0.enemyPets_
		})
	end

	local var_6_1 = 0

	for iter_6_0, iter_6_1 in pairs(arg_6_0.enemyHeroes_) do
		var_6_1 = var_6_1 + 1
	end

	table.sort(arg_6_0.enemyHeroes_, function(arg_7_0, arg_7_1)
		return arg_7_0:getDistance() < arg_7_1:getDistance()
	end)

	for iter_6_2, iter_6_3 in pairs(arg_6_0.enemyHeroes_) do
		if arg_6_0.hide_counts and var_6_1 - var_6_0 + 1 < arg_6_0.hide_counts then
			local var_6_2 = xyd.AssetLoader.get():loadSprite("images/battle/hide_avatar.png")

			xyd.displaySpriteOnContainer(var_6_2, arg_6_0:nodeByName("enemy_hero_" .. var_6_0), true)
		elseif iter_6_3.status_ then
			local var_6_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar3.csb")
			local var_6_4 = var_6_3:getChildByName("background"):getContentSize()

			var_6_3:setContentSize(var_6_4)
			var_6_3:setScale(86 / var_6_4.width)
			xyd.setAvatarBorder(iter_6_3, var_6_3:getChildByName("avatar"))

			local var_6_5 = var_6_3:getChildByName("avatar_mask")

			var_6_5:setVisible(false)
			var_6_3:getChildByName("lv_di"):setVisible(false)
			var_6_3:getChildByName("lv_txt"):setVisible(false)

			local var_6_6 = var_6_3:getChildByName("hp_bar")
			local var_6_7 = var_6_3:getChildByName("dead_text")

			var_6_7:setString(var_0_13:translation("ALREADY_DEAD"))

			if var_6_7 then
				var_6_7:setVisible(false)
			end

			local var_6_8 = false
			local var_6_9 = iter_6_3.status_

			if var_6_9 and var_6_9.health then
				local var_6_10 = 0

				if var_6_9.health == 0 then
					var_6_10 = 100
				elseif var_6_9.health == 1 and var_6_9.hp >= 1 then
					var_6_10 = var_6_9.hp / (var_6_9.total_hp or iter_6_3:getTotalAttr(xyd.AttributeType.HP)) * 100
				else
					var_6_10 = 0

					var_6_5:setVisible(true)
					var_6_7:setLocalZOrder(3)
					var_6_7:setVisible(true)
					var_6_7:enableOutline(cc.c4b(0, 0, 0), 2)
					var_6_7:getVirtualRenderer():setAdditionalKerning(2)

					local var_6_11 = true
				end

				var_6_6:setPercent(var_6_10)
				var_6_6:setVisible(true)
			end

			var_6_3:setName("layout")
			var_6_3:setPosition(cc.p(0, 0))
			arg_6_0:nodeByName("enemy_hero_" .. var_6_0):addChild(var_6_3)
		else
			xyd.setAvatarBorder(iter_6_3, arg_6_0:nodeByName("enemy_hero_" .. var_6_0))

			if iter_6_3.isLeader then
				local var_6_12 = xyd.AssetLoader.get():loadSprite("windows/arena/mode/lead_icon.png")

				var_6_12:addTo(arg_6_0:nodeByName("enemy_hero_" .. var_6_0))
				var_6_12:setPosition(20, 70)
			end
		end

		var_6_0 = var_6_0 + 1
	end

	if arg_6_0.enemyPets_ then
		if arg_6_0.hide_counts and arg_6_0.hide_counts >= 1 then
			local var_6_13 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/pet_hide.png")

			xyd.displaySpriteOnContainer(var_6_13, arg_6_0:nodeByName("pet_back_enemy"), true)
		else
			xyd.setPetAvatar(arg_6_0:nodeByName("pet_back_enemy"), arg_6_0.enemyPets_, 100)
		end
	end
end

function var_0_0.layout(arg_8_0)
	if arg_8_0.type == xyd.SelectTeamType.ADVANCED then
		arg_8_0:initRecommend()
	else
		arg_8_0:nodeByName("recommend_layer"):setVisible(false)
	end

	if arg_8_0.showEnemy then
		arg_8_0:nodeByName("battle_team_bg"):setVisible(true)
		arg_8_0:nodeByName("list_layer"):height(300)
		arg_8_0:initEnemys()
	else
		arg_8_0:nodeByName("battle_team_bg"):setVisible(false)
	end

	arg_8_0:initRightMenu()
	arg_8_0:initLeftMenu()
	arg_8_0:initTopRentMenu()
	arg_8_0:selectHeros()
	arg_8_0:selectPets()
	arg_8_0:initListview()
	arg_8_0:initTextOfList()
	arg_8_0:checkGuildPrepareTime()
	arg_8_0:awakeMissionInit()
	arg_8_0:setCloseBtn()
end

function var_0_0.initRightMenu(arg_9_0)
	arg_9_0.rightMenuButtons_ = {}

	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("button_all"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("button_qianpai"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("button_zhongpai"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("button_houpai"))
	table.insert(arg_9_0.rightMenuButtons_, arg_9_0:nodeByName("button_filter"))

	for iter_9_0 = 1, #arg_9_0.rightMenuButtons_ do
		arg_9_0.rightMenuButtons_[iter_9_0]:setZoomScale(0.3)
		arg_9_0.rightMenuButtons_[iter_9_0]:addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if arg_9_0.selectedHeroClass_[arg_9_0.leftMenuType_] == iter_9_0 and not arg_9_0.isHeroPreset then
					for iter_10_0 = 1, #arg_9_0.rightMenuButtons_ do
						if iter_10_0 == arg_9_0.selectedHeroClass_[arg_9_0.leftMenuType_] then
							arg_9_0.rightMenuButtons_[iter_10_0]:setBrightStyle(ccui.BrightStyle.highlight)
						else
							arg_9_0.rightMenuButtons_[iter_10_0]:setBrightStyle(ccui.BrightStyle.normal)
						end
					end

					return
				end

				arg_9_0.isHeroPreset = false
				arg_9_0.selectedHeroClass_[arg_9_0.leftMenuType_] = iter_9_0

				arg_9_0:refreshSelectedHeroClass()
			end
		end)
	end

	if not arg_9_0.noPreset and arg_9_0:checkCanPresetTeam() then
		arg_9_0:nodeByName("button_preset"):setZoomScale(0.3)
		arg_9_0:nodeByName("button_preset"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if not arg_9_0.isHeroPreset then
					arg_9_0.isHeroPreset = true
					arg_9_0.leftMenuType_ = var_0_17.SELF_HERO

					arg_9_0:updateTopRentMenu()
					arg_9_0:selectHeros()
					arg_9_0:selectPets()
					arg_9_0:updateTextOfList()

					if arg_9_0.leftMenuButtons_ then
						for iter_11_0, iter_11_1 in ipairs(arg_9_0.leftMenuButtons_) do
							iter_11_1:setBrightStyle(iter_11_1.menu_type == var_0_17.SELF_HERO and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
						end
					end

					for iter_11_2 = 1, #arg_9_0.rightMenuButtons_ do
						arg_9_0.rightMenuButtons_[iter_11_2]:setBrightStyle(ccui.BrightStyle.normal)
					end

					arg_9_0.heroList_:reload()
				end

				arg_9_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
			end
		end)
	else
		arg_9_0:nodeByName("button_preset"):setVisible(false)
		arg_9_0:nodeByName("preset"):setVisible(false)
	end

	arg_9_0:nodeByName("button_filter"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_9_0.leftMenuType_ ~= var_0_17.SELF_HERO then
			return
		end

		xyd.WindowManager.get():openWindow("hero_filter")
	end)
end

function var_0_0.initLeftMenu(arg_13_0)
	arg_13_0:nodeByName("zhandui"):hide()
	arg_13_0:nodeByName("button_zhandui"):hide()

	arg_13_0:nodeByName("button_zhandui").menu_type = var_0_17.SELF_HERO

	arg_13_0:nodeByName("yongbing"):hide()
	arg_13_0:nodeByName("button_yongbing"):hide()

	arg_13_0:nodeByName("button_yongbing").menu_type = var_0_17.RENT_HERO

	arg_13_0:nodeByName("pet"):hide()
	arg_13_0:nodeByName("button_pet"):hide()

	arg_13_0:nodeByName("button_pet").menu_type = var_0_17.SELF_PET
	arg_13_0.leftMenuType_ = var_0_17.SELF_HERO
	arg_13_0.leftMenuButtons_, arg_13_0.leftMenuText_ = {}, {}

	table.insert(arg_13_0.leftMenuButtons_, arg_13_0:nodeByName("button_zhandui"))
	table.insert(arg_13_0.leftMenuText_, arg_13_0:nodeByName("zhandui"))

	if arg_13_0:canRentHero() then
		table.insert(arg_13_0.leftMenuButtons_, arg_13_0:nodeByName("button_yongbing"))
		table.insert(arg_13_0.leftMenuText_, arg_13_0:nodeByName("yongbing"))
	end

	if arg_13_0:isPet() then
		arg_13_0:nodeByName("rate_bg"):setVisible(false)
		table.insert(arg_13_0.leftMenuButtons_, arg_13_0:nodeByName("button_pet"))
		table.insert(arg_13_0.leftMenuText_, arg_13_0:nodeByName("pet"))
	else
		arg_13_0:nodeByName("avatar_pet1"):hide()

		if arg_13_0.type == xyd.SelectTeamType.ADVANCED then
			arg_13_0:nodeByName("rate_bg"):setVisible(true)
		else
			arg_13_0:nodeByName("rate_bg"):setVisible(false)
			arg_13_0:nodeByName("text_bg"):setLocalZOrder(10)
			arg_13_0:nodeByName("text_bg"):y(arg_13_0:nodeByName("text_bg"):getY() - 120)
		end
	end

	if #arg_13_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_13_0 = 1, #arg_13_0.leftMenuButtons_ do
		arg_13_0.leftMenuButtons_[iter_13_0]:show()
		arg_13_0.leftMenuText_[iter_13_0]:show()
		arg_13_0.leftMenuButtons_[iter_13_0]:setZoomScale(0.3)

		local var_13_0 = arg_13_0.leftMenuButtons_[1]:getY() - 85 * (iter_13_0 - 1)

		arg_13_0.leftMenuButtons_[iter_13_0]:y(var_13_0)
		arg_13_0.leftMenuText_[iter_13_0]:y(var_13_0)
		arg_13_0.leftMenuButtons_[iter_13_0]:addTouchEventListener(function(arg_14_0, arg_14_1)
			if arg_14_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_14_0, iter_14_1 in ipairs(arg_13_0.leftMenuButtons_) do
					iter_14_1:setBrightStyle(arg_14_0 == iter_14_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_13_0.leftMenuType_ = arg_14_0.menu_type
				arg_13_0.isHeroPreset = false
				arg_13_0.rentMenuType = var_0_18.RENT_HERO

				arg_13_0:updateTopRentMenu()
				arg_13_0:selectHeros()
				arg_13_0:selectPets()
				arg_13_0:refreshSelectedHeroClass()
				arg_13_0:updateTextOfList()
			end
		end)
	end
end

function var_0_0.initTopRentMenu(arg_15_0)
	arg_15_0:nodeByName("btn_rent_hero"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_15_0.rentMenuType = var_0_18.RENT_HERO

			arg_15_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_15_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_15_0:selectPets()
			arg_15_0.heroList_:reload()
		end
	end)
	arg_15_0:nodeByName("btn_rent_pet"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and not arg_15_0.isClickRentPet then
			arg_15_0.isClickRentPet = true

			xyd.playButtonSound()

			arg_15_0.rentMenuType = var_0_18.RENT_PET

			arg_15_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.normal)
			arg_15_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_15_0:initRentPets(function()
				arg_15_0:selectPets()
				arg_15_0.heroList_:reload()

				arg_15_0.isClickRentPet = false
			end)
		end
	end)
	arg_15_0:nodeByName("top_rent_container"):setVisible(false)

	arg_15_0.rentMenuType = var_0_18.RENT_HERO
end

function var_0_0.initRentPets(arg_19_0, arg_19_1)
	if not arg_19_0.isLoadAllTeamPets then
		local var_19_0 = {}

		arg_19_0.guild:loadAllTeamPets(var_19_0, function(arg_20_0)
			arg_19_0.allTeamPets = {}

			if arg_20_0 == xyd.error.OK then
				for iter_20_0, iter_20_1 in ipairs(arg_19_0.guild:getAllTeamPets()) do
					local var_20_0 = var_0_2.new()

					var_20_0:populate(iter_20_1)

					var_20_0.player_name = iter_20_1.player_name
					var_20_0.rent_need_mana = iter_20_1.rent_need_mana
					var_20_0.can_rent = iter_20_1.can_rent
					var_20_0.player_id = iter_20_1.player_id

					table.insert(arg_19_0.allTeamPets, var_20_0)
				end

				arg_19_0.isLoadAllTeamPets = true
			end

			arg_19_0:initPets(arg_19_0.allTeamPets, var_0_19.RENT_PET)

			if arg_19_1 then
				arg_19_1()
			end
		end)
	elseif arg_19_1 then
		arg_19_1()
	end
end

function var_0_0.updateTopRentMenu(arg_21_0)
	if arg_21_0.leftMenuType_ == var_0_17.RENT_HERO and arg_21_0:isPet() then
		arg_21_0:nodeByName("top_rent_container"):setVisible(true)
		arg_21_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_21_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)

		if not arg_21_0.ischangeListRect then
			if arg_21_0.campaignType == xyd.CampaignType.GUILD or arg_21_0.campaignType == xyd.CampaignType.ADVENTURE_DEFENSE then
				var_0_9 = 70

				arg_21_0:nodeByName("lev_limit_txt"):setPositionY(arg_21_0:nodeByName("lev_limit_txt"):getPositionY() - var_0_9)
			end

			local var_21_0 = arg_21_0.heroList_:getViewRect()
			local var_21_1 = cc.rect(0, 0, var_21_0.width, var_21_0.height - var_0_9)

			arg_21_0.heroList_:setViewRect(var_21_1)

			arg_21_0.ischangeListRect = true
		end
	else
		arg_21_0:nodeByName("top_rent_container"):setVisible(false)

		if arg_21_0.ischangeListRect then
			if arg_21_0.campaignType == xyd.CampaignType.GUILD or arg_21_0.campaignType == xyd.CampaignType.ADVENTURE_DEFENSE then
				var_0_9 = 70

				arg_21_0:nodeByName("lev_limit_txt"):setPositionY(arg_21_0:nodeByName("lev_limit_txt"):getPositionY() + var_0_9)
			end

			local var_21_2 = arg_21_0.heroList_:getViewRect()
			local var_21_3 = cc.rect(0, 0, var_21_2.width, var_21_2.height + var_0_9)

			arg_21_0.heroList_:setViewRect(var_21_3)
		end

		arg_21_0.ischangeListRect = false
	end
end

function var_0_0.initPetCell(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_0.totalPet_[arg_22_2]
	local var_22_1 = false

	if arg_22_0.rentMenuType == var_0_18.RENT_PET then
		local var_22_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/cloud_city/rent_pet_avatar.csb")

		arg_22_1:addChild(var_22_2)

		arg_22_1.type = var_0_19.RENT_PET

		var_22_2:setName("rent_cell")

		local var_22_3 = var_22_2:getChildByName("container")

		arg_22_1:align(display.CENTER):size(var_22_3:getContentSize().width, var_22_3:getContentSize().height)

		local var_22_4 = var_22_3:getChildByName("avatar")

		var_22_3:getChildByName("player_name"):setString(var_22_0.player_name)
		var_22_3:getChildByName("rent_cost"):setString(var_22_0.rent_need_mana)
		var_22_4:getChildByName("yongbing_tubiao"):setPosition(cc.p(90, 100))
		xyd.setPetAvatar(var_22_4, var_22_0, 100)
		var_22_4:setPositionY(var_22_4:getPositionY() + 15)

		if not var_22_0.can_rent then
			var_22_3:getChildByName("can_not_rent"):setString(var_0_13:translation("CAN_NOT_BORROW"))
			var_22_4:getChildByName("layout"):getChildByName("chosen"):setVisible(false)
			var_22_4:getChildByName("layout"):getChildByName("avatar_mask"):setVisible(true)
		else
			var_22_3:getChildByName("can_not_rent"):setVisible(false)
		end
	else
		arg_22_1:align(display.CENTER):size(146, 146)
		xyd.setPetAvatar(arg_22_1, var_22_0, 100)

		arg_22_1.type = var_0_19.SELF_PET

		arg_22_0:initPetCellStatus(arg_22_1, var_22_0)
	end

	arg_22_1.data = var_22_0

	arg_22_1:setTouchEnabled(true)
	arg_22_1:setTouchSwallowEnabled(false)
	arg_22_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if not var_22_1 then
			arg_22_0:buttonHandler(nil, arg_22_1, arg_23_0)

			if arg_23_0.name == "began" then
				arg_22_0.startClick_ = true
				arg_22_0.prevX_ = arg_23_0.x
				arg_22_0.prevY_ = arg_23_0.y
			elseif arg_23_0.name == "moved" then
				if math.abs(arg_23_0.y - arg_22_0.prevY_) > 5 or math.abs(arg_23_0.x - arg_22_0.prevX_) > 5 then
					arg_22_0.startClick_ = false
				end
			elseif arg_23_0.name == "ended" and arg_22_0.startClick_ then
				local var_23_0 = var_22_0.rent_need_mana

				if arg_22_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_22_0:checkPetIsConquerUsed(var_22_0) then
					return
				elseif arg_22_0.isAwakeCampaign and arg_22_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
					local function var_23_1()
						arg_22_0:clickPetAvatar(arg_22_1)
					end

					local var_23_2 = {
						txt = var_0_13:translation("AWAKE_SELECT_TEAM_TIP6"),
						type = xyd.CommonAlertType.TWO_BTN,
						rcallback = var_23_1,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_23_2)
				elseif arg_22_0.rentMenuType == var_0_18.RENT_PET and not var_22_0.can_rent then
					return
				elseif var_23_0 and var_23_0 > arg_22_0.selfPlayer.mana and var_22_0.can_rent then
					local var_23_3 = var_0_13:translation("MERCENARY_ERROR_TIP4")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_23_3
					})

					return
				else
					arg_22_0:clickPetAvatar(arg_22_1)
				end
			end
		end

		return true
	end)

	for iter_22_0, iter_22_1 in ipairs(arg_22_0.petTeam_) do
		if var_22_0 == iter_22_1.data or arg_22_0.type == xyd.SelectTeamType.TWO_YEARS and var_22_0:getPetID() == iter_22_1.data:getPetID() then
			arg_22_0.petTeam_[iter_22_0].iniCell_ = arg_22_1
			arg_22_1.teamNo_ = iter_22_0

			local var_22_5

			if arg_22_0.rentMenuType == var_0_18.RENT_PET then
				var_22_5 = arg_22_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
			else
				var_22_5 = arg_22_1:getChildByName("layout")
			end

			local var_22_6 = var_22_5:getChildByName("avatar_mask")
			local var_22_7 = var_22_5:getChildByName("chosen")

			var_22_6:setVisible(true)
			var_22_7:setVisible(true)

			break
		end
	end

	for iter_22_2, iter_22_3 in pairs(arg_22_0.busyPets_) do
		if iter_22_3 == var_22_0:getPetID() then
			local var_22_8

			if arg_22_0.rentMenuType == var_0_18.RENT_PET then
				var_22_8 = arg_22_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
			else
				var_22_8 = arg_22_1:getChildByName("layout")
			end

			local var_22_9 = var_22_8:getChildByName("avatar_mask")

			var_22_8:getChildByName("chosen"):setVisible(true)
			var_22_9:setVisible(true)

			var_22_1 = true

			break
		end
	end
end

function var_0_0.initPetCellStatus(arg_25_0, arg_25_1, arg_25_2)
	if arg_25_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_25_0:checkPetIsConquerUsed(arg_25_2) then
		layout = arg_25_1:getChildByName("layout")

		layout:getChildByName("avatar_mask"):setVisible(true)

		local var_25_0 = layout:getChildByName("background"):getContentSize()
		local var_25_1 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

		var_25_1:setAnchorPoint(cc.p(0, 1))
		var_25_1:setPosition(var_25_0.width / 2, var_25_0.height - 20)
		arg_25_1:addChild(var_25_1, 11)
	end
end

function var_0_0.initPresetCell(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = arg_26_0.presetTeams[arg_26_2].team
	local var_26_1 = arg_26_0.presetTeams[arg_26_2].teamName
	local var_26_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list/hero_preset/preset_item_2.csb")
	local var_26_3 = var_26_2:getChildByName("container")
	local var_26_4 = var_26_3:getContentSize()

	arg_26_1:setContentSize(var_26_4)
	var_26_2:addTo(arg_26_1)
	var_26_3:getChildByName("text_name"):setString(var_26_1)

	local var_26_5 = var_26_3:getChildByName("hero_list")
	local var_26_6 = 0

	for iter_26_0 = 1, #var_26_0 do
		local var_26_7 = var_26_0[iter_26_0]
		local var_26_8 = display.newNode()

		var_26_8:setContentSize(var_0_10, var_0_10)
		xyd.setAvatarBorder(var_26_7, var_26_8)
		var_26_8:addTo(var_26_5)
		var_26_8:setPositionX(var_26_6)

		var_26_6 = var_26_6 + var_0_10 + 10

		local var_26_9 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")

		var_26_9:addTo(var_26_8)
		var_26_9:setPosition(cc.p(0, 0))
		var_26_9:setAnchorPoint(cc.p(0, 0))
		var_26_9:setName("avatar_mask")
		var_26_9:setScale(var_0_10 / var_26_9:getWidth())
		var_26_9:setVisible(false)

		if arg_26_0.type == xyd.SelectTeamType.ADVANCED and arg_26_0:isRecommend(var_26_7) then
			local var_26_10 = xyd.AssetLoader.get():loadSprite("windows/common/text/recommend.png")

			var_26_10:setAnchorPoint(cc.p(0.5, 1))
			var_26_10:setPosition(var_0_10 / 2, var_0_10)
			var_26_8:addChild(var_26_10)
		elseif arg_26_0:checkHeroIsNotUse(var_26_7) then
			var_26_9:setVisible(true)

			local var_26_11 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

			var_26_11:setAnchorPoint(cc.p(0.5, 1))
			var_26_11:setPosition(var_0_10 / 2, var_0_10)
			var_26_8:addChild(var_26_11, 11)
		end

		local var_26_12 = {
			size = 26,
			color = cc.c3b(206, 109, 109),
			align = cc.ui.TEXT_ALIGN_CENTER
		}
		local var_26_13 = xyd.AssetLoader.get():loadLabel(var_26_12)

		var_26_13:addTo(var_26_8)
		var_26_13:setAnchorPoint(cc.p(0.5, 1))
		var_26_13:setPosition(cc.p(var_0_10 / 2, var_0_10))
		var_26_13:setVisible(false)

		local var_26_14 = false

		if arg_26_0:checkHeroIsDead(var_26_7) then
			var_26_9:setVisible(true)
			var_26_13:setLocalZOrder(3)
			var_26_13:setVisible(true)
			var_26_13:setString(var_0_13:translation("ALREADY_DEAD"))
			var_26_13:enableOutline(cc.c4b(0, 0, 0), 2)

			var_26_14 = true
		end

		var_26_7.isDead = var_26_14

		for iter_26_1, iter_26_2 in pairs(arg_26_0.busyHeros_) do
			if iter_26_2 == var_26_7:getHeroID() then
				var_26_9:setVisible(true)

				break
			end
		end

		if (arg_26_0.type == xyd.SelectTeamType.INCUBUS or arg_26_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_26_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER or arg_26_0.selectSpType == xyd.SelectSpType.BAN) and arg_26_0:isBanned(var_26_7) then
			local var_26_15 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_26_15:setAnchorPoint(cc.p(0.5, 1))
			var_26_15:setPosition(var_0_10 / 2, var_0_10)
			var_26_8:addChild(var_26_15)
			var_26_9:setVisible(true)
		end
	end

	var_26_3:getChildByName("btn_use"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_26_0:checkPresetTeamCanUse(arg_26_2) then
				local var_27_0 = arg_26_0.selfPlayer:getSaveTeamStr()
				local var_27_1 = arg_26_0.selfPlayer:getSaveTeamIDs(var_27_0)

				arg_26_0.preSelect_ = var_27_1[arg_26_2]
				arg_26_0.preHeros_ = var_26_0

				arg_26_0:showPresetTeam(arg_26_2)
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_28_0)
	local var_28_0 = arg_28_0.team_

	arg_28_0.team_ = {}
	arg_28_0.select_ = {}

	arg_28_0:updateScore()
	arg_28_0:initPreHeros(true)

	local var_28_1 = arg_28_0.team_
	local var_28_2 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_29_0 = 1, #var_28_0 do
				local var_29_0 = var_28_0[iter_29_0]
				local var_29_1, var_29_2 = arg_28_0:nodeByName("avatar" .. iter_29_0):getPosition()

				arg_28_0:moveFadeOutAction(var_29_1, var_29_2, var_29_0)

				if var_29_0.type == var_0_17.RENT_HERO then
					arg_28_0.isSelectMerHero = false
					arg_28_0.selectMerHero = nil
				end
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_28_3 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_30_0 = 1, #var_28_1 do
				local var_30_0 = var_28_1[iter_30_0]

				var_30_0:show()

				local var_30_1, var_30_2 = arg_28_0:nodeByName("avatar" .. iter_30_0):getPosition()

				arg_28_0:moveFadeInAction(var_30_1, var_30_2, var_30_0)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_28_0:runAction(transition.sequence({
		var_28_2,
		var_28_3
	}))
end

function var_0_0.checkPresetTeamCanUse(arg_31_0, arg_31_1)
	local var_31_0 = arg_31_0.presetTeams[arg_31_1].team

	if arg_31_0.isAwakeCampaign then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_13:translation("PRESET_TEAM_NOT_USE")
		})

		return false
	elseif arg_31_0.type == xyd.SelectTeamType.CHALLENGE then
		local var_31_1 = var_0_14:modeType(arg_31_0.battleID)

		if var_31_1 == xyd.ChallengeType.OneHeroKillAll then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_13:translation("CHALLENGE_ONLY_ONE_HERO")
			})

			return false
		elseif var_31_1 == xyd.ChallengeType.Protect or var_31_1 == xyd.ChallengeType.KillSteal then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_13:translation("PRESET_TEAM_NOT_USE")
			})

			return false
		end
	end

	for iter_31_0 = 1, #var_31_0 do
		local var_31_2 = var_31_0[iter_31_0]

		if not arg_31_0:canHeroJoinBattle(var_31_2) or arg_31_0:checkHeroIsDead(var_31_2) or arg_31_0:checkBusyHero2(var_31_2) or arg_31_0.selectSpType == xyd.SelectSpType.BAN and arg_31_0:isBanned(var_31_2) or arg_31_0.type == xyd.SelectTeamType.INCUBUS and arg_31_0:isBanned(var_31_2) or arg_31_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER and arg_31_0:isBanned(var_31_2) or arg_31_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER and arg_31_0:isBanned(var_31_2) or arg_31_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_31_0:checkHeroIsConquerUsed(var_31_2) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_13:translation("PRESET_MEMBER_NOT_USE")
			})

			return false
		end
	end

	return true
end

function var_0_0.checkHeroIsDead(arg_32_0, arg_32_1)
	local var_32_0
	local var_32_1 = false

	if arg_32_0.heroStatus_ then
		var_32_0 = arg_32_0.heroStatus_.self_list

		if arg_32_0.campaignType == xyd.CampaignType.TREASURE then
			var_32_0 = arg_32_0.heroStatus_
		end
	end

	if var_32_0 and next(var_32_0) ~= nil then
		local var_32_2 = var_32_0[tostring(arg_32_1:getHeroID())]

		if not var_32_2 or not var_32_2.health or var_32_2.health == 0 then
			-- block empty
		elseif var_32_2.health == 1 and var_32_2.hp >= 1 then
			-- block empty
		else
			var_32_1 = true
		end
	end

	return var_32_1
end

function var_0_0.clickPetAvatar(arg_33_0, arg_33_1, arg_33_2)
	if arg_33_1.isAnimated_ or not arg_33_1.teamNo_ and #arg_33_0.petTeam_ > xyd.MAX_PET_NUMBER then
		return
	elseif arg_33_1.type == var_0_19.RENT_PET and arg_33_0.isSelectMerHero then
		local var_33_0 = var_0_13:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_33_0
		})

		return
	elseif not arg_33_1.teamNo_ and #arg_33_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_33_1 = arg_33_0.petTeam_[1]

		arg_33_0:clickPetBottomAvatarWithoutAnimation(var_33_1, function()
			arg_33_0:clickPetAvatar(arg_33_1, arg_33_2)
		end)

		return
	end

	local var_33_2

	if arg_33_0.rentMenuType == var_0_18.RENT_PET then
		var_33_2 = arg_33_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_33_2 = arg_33_1:getChildByName("layout")
	end

	local var_33_3 = var_33_2:getChildByName("avatar_mask")
	local var_33_4 = var_33_2:getChildByName("chosen")
	local var_33_5 = arg_33_1:convertToWorldSpace(cc.p(0, 0))
	local var_33_6 = var_33_5.x
	local var_33_7 = var_33_5.y

	arg_33_1.isAnimated_ = true

	if arg_33_1.teamNo_ then
		local var_33_8 = arg_33_0.petTeam_[arg_33_1.teamNo_]

		arg_33_0:moveFadeOutAction(var_33_6, var_33_7, var_33_8, function()
			arg_33_1.isAnimated_ = false
		end)
		var_33_3:setVisible(false)
		var_33_4:setVisible(false)

		for iter_33_0 = #arg_33_0.petTeam_, arg_33_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_33_0.petTeam_[iter_33_0])

			local var_33_9, var_33_10 = arg_33_0:nodeByName("avatar_pet" .. iter_33_0 - 1):getPosition()

			transition.moveTo(arg_33_0.petTeam_[iter_33_0], {
				time = 0.3,
				x = var_33_9,
				y = var_33_10
			})

			arg_33_0.petTeam_[iter_33_0].iniCell_.teamNo_ = iter_33_0 - 1
		end

		if arg_33_1.type == var_0_19.RENT_PET then
			arg_33_0.isSelectMerPet = false
			arg_33_0.selectMerPet = nil
		end

		table.remove(arg_33_0.petTeam_, arg_33_1.teamNo_)
		table.remove(arg_33_0.petSelect_, arg_33_1.teamNo_)

		arg_33_1.teamNo_ = nil
	elseif not arg_33_1.teamNo_ and #arg_33_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_33_11 = arg_33_1.data

		if not arg_33_2 and var_0_15:chosenSound(var_33_11:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_33_11:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_15:chosenSound(var_33_11:getTableID()), false)
		end

		if arg_33_0.rentMenuType == var_0_18.RENT_PET and var_33_11.can_rent == false then
			arg_33_1.isAnimated_ = false

			return
		end

		local var_33_12 = arg_33_0:initPetBottomCell(var_33_11)

		var_33_12.iniCell_ = arg_33_1

		var_33_12:pos(var_33_6, var_33_7)
		var_33_12:addTo(arg_33_0)
		var_33_12:setTouchEnabled(true)
		var_33_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_37_0)
			if arg_37_0.name == "ended" then
				arg_33_0:clickPetBottomAvatar(var_33_12)
			end

			return true
		end)

		if arg_33_1.type == var_0_19.RENT_PET then
			arg_33_0.isSelectMerPet = true
			arg_33_0.selectMerPet = var_33_11
		end

		arg_33_1.teamNo_ = arg_33_0:getPetTeamNo(var_33_12)

		for iter_33_1 = arg_33_1.teamNo_, #arg_33_0.petTeam_ do
			local var_33_13, var_33_14 = arg_33_0:nodeByName("avatar_pet" .. iter_33_1):getPosition()

			if arg_33_2 then
				arg_33_0.petTeam_[iter_33_1]:pos(var_33_13, var_33_14)

				arg_33_1.isAnimated_ = false
			elseif iter_33_1 ~= arg_33_1.teamNo_ then
				local var_33_15 = arg_33_0.petTeam_[iter_33_1]

				transition.stopTarget(var_33_15)
				transition.moveTo(var_33_15, {
					time = 0.3,
					x = var_33_13,
					y = var_33_14,
					onComplete = function()
						var_33_15.iniCell_.isAnimated_ = false
						var_33_15.isAnimated_ = false
					end
				})
			else
				local var_33_16 = arg_33_0.petTeam_[iter_33_1]

				transition.stopTarget(var_33_16)

				var_33_12.isAnimated_ = true

				transition.moveTo(var_33_16, {
					time = 0.3,
					x = var_33_13,
					y = var_33_14,
					onComplete = function()
						arg_33_1.isAnimated_ = false
						var_33_12.isAnimated_ = false
					end
				})
			end

			arg_33_0.petTeam_[iter_33_1].iniCell_.teamNo_ = iter_33_1
		end

		var_33_3:setVisible(true)
		var_33_4:setVisible(true)
	end

	arg_33_0:updateScore()
end

function var_0_0.initHeroCell(arg_40_0, arg_40_1, arg_40_2)
	local var_40_0 = arg_40_0.totalHero_[arg_40_0.selectedHeroClass_[arg_40_0.leftMenuType_]][arg_40_2]

	var_40_0.healthStatus = nil

	if arg_40_0.leftMenuType_ == var_0_17.RENT_HERO then
		local var_40_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/select_mercenary_item.csb")
		local var_40_2 = var_40_1:getChildByName("container")

		var_40_2:getChildByName("player_name"):setString(var_40_0.player_name)

		arg_40_1.player_name = var_40_0.player_name
		arg_40_1.can_rent = var_40_0.can_rent
		arg_40_1.type = var_0_17.RENT_HERO

		var_40_2:getChildByName("rent_cost"):setString(var_40_0.rent_need_mana)
		var_40_2:getChildByName("yongbing_tubiao"):setVisible(true)
		var_40_2:getChildByName("is_can_rent"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_40_2:getChildByName("is_can_rent"):setString(var_0_13:translation("CAN_NOT_BORROW"))
		arg_40_1:setContentSize(var_40_1:getChildByName("container"):getContentSize())
		xyd.setAvatarBorder(var_40_0, var_40_2:getChildByName("avatar"))

		local var_40_3 = var_40_2:getChildByName("chosen")

		var_40_3:setLocalZOrder(100)
		var_40_3:setVisible(false)

		local var_40_4 = var_40_2:getChildByName("avatar_mask")

		var_40_4:setLocalZOrder(2)
		var_40_4:setVisible(false)

		if var_40_0.can_rent then
			var_40_2:getChildByName("is_can_rent"):setVisible(false)
			var_40_4:setVisible(false)
		else
			var_40_2:getChildByName("is_can_rent"):setVisible(true)
			var_40_2:getChildByName("is_can_rent"):setColor(cc.c3b(255, 165, 159))
			var_40_2:getChildByName("is_can_rent"):enableOutline(cc.c4b(0, 0, 0, 105), 1)
			var_40_2:getChildByName("is_can_rent"):setLocalZOrder(100)
			var_40_4:setVisible(true)
		end

		if arg_40_0.type == xyd.SelectTeamType.ADVANCED and arg_40_0:isRecommend(var_40_0) then
			local var_40_5 = xyd.AssetLoader.get():loadSprite("windows/common/text/recommend.png")

			var_40_5:setAnchorPoint(cc.p(0.5, 1))
			var_40_5:setPosition(110, 160)
			var_40_2:addChild(var_40_5)
		end

		if arg_40_0.reinforcePartnerRatios[var_40_0:getTableID()] then
			local var_40_6 = xyd.AssetLoader.get():loadSprite("windows/common/attr_reinforcement.png")

			var_40_6:setAnchorPoint(cc.p(0, 0))

			local var_40_7 = arg_40_1:getContentSize()

			var_40_6:setPosition(var_40_7.width / 6, var_40_7.height - 40)
			var_40_2:addChild(var_40_6)

			local var_40_8 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 18,
				text = string.format("%6.2f%%", arg_40_0.reinforcePartnerRatios[var_40_0:getTableID()] * 100),
				color = cc.c4b(0, 192, 255, 255),
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_40_8:setAnchorPoint(cc.p(0, 0))
			var_40_8:addTo(var_40_6)
			var_40_8:setPosition(24, 3)
		end

		var_40_2:getChildByName("lv_txt"):setString(var_40_0:getLevel())

		local var_40_9 = var_40_2:getChildByName("name_txt")

		var_40_9:setString(var_40_0:getName())
		var_40_9:enableOutline(cc.c4b(0, 0, 0, 105), 1)

		if xyd.Color2Level[var_40_0:getColor()] ~= "" then
			local var_40_10 = {
				size = 20,
				align = cc.ui.TEXT_ALIGN_LEFT,
				valign = cc.ui.TEXT_VALIGN_BOTTOM,
				x = var_40_9:getX() + var_40_9:getWidth() / 2 - 10,
				y = var_40_9:getY(),
				color = xyd.color.HERO_QUALITY[var_40_0:getColor()],
				text = xyd.Color2Level[var_40_0:getColor()]
			}
			local var_40_11 = xyd.AssetLoader.get():loadLabel(var_40_10)

			var_40_11:addTo(var_40_2)
			var_40_11:align(display.CENTER_LEFT)
			var_40_11:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_40_9:x(var_40_9:getX() - 15)
		end

		local var_40_12 = var_40_2:getChildByName("hp_bar")
		local var_40_13 = var_40_2:getChildByName("mp_bar")
		local var_40_14 = var_40_2:getChildByName("dead_txt")

		var_40_14:setString(var_0_13:translation("ALREADY_DEAD"))

		if var_40_14 then
			var_40_14:setVisible(false)
		end

		local var_40_15 = false
		local var_40_16

		if arg_40_0.heroStatus_ then
			var_40_16 = arg_40_0.heroStatus_.rent_list
		end

		if var_40_16 and var_40_16.health then
			local var_40_17 = var_40_16

			var_40_0.healthStatus = var_40_17

			if var_40_17 and var_40_17.health then
				local var_40_18 = 0
				local var_40_19 = 0

				if var_40_17.health == 0 then
					var_40_18 = 100
					var_40_19 = 0
				elseif var_40_17.health == 1 and var_40_17.hp >= 1 then
					var_40_18 = var_40_17.hp / (var_40_17.total_hp or var_40_0:getTotalAttr(xyd.AttributeType.HP)) * 100
					var_40_19 = var_40_17.mp / 10
				else
					var_40_18 = 0
					var_40_19 = 0

					var_40_4:setVisible(true)
					var_40_14:setLocalZOrder(3)
					var_40_14:setVisible(true)
					var_40_14:enableOutline(cc.c4b(0, 0, 0), 2)
					var_40_14:getVirtualRenderer():setAdditionalKerning(2)

					var_40_15 = true
				end

				var_40_12:setPercent(var_40_18)
				var_40_12:setVisible(true)
				var_40_13:setPercent(var_40_19)
				var_40_13:setVisible(true)
			end
		elseif (not var_40_16 or not var_40_16.health) and arg_40_0.campaignType == xyd.CampaignType.MARCH then
			var_40_0.healthStatus = {}
			var_40_0.healthStatus.health = 0
			var_40_0.healthStatus.hp = 0
			var_40_0.healthStatus.mp = 0

			local var_40_20 = 100
			local var_40_21 = 0

			var_40_12:setPercent(var_40_20)
			var_40_12:setVisible(true)
			var_40_13:setPercent(var_40_21)
			var_40_13:setVisible(true)
		else
			var_40_12:hide()
			var_40_13:hide()
			var_40_2:getChildByName("hp_di"):hide()
			var_40_2:getChildByName("mp_di"):hide()
		end

		var_40_0.isDead = var_40_15

		var_40_2:setPosition(cc.p(0, 0))

		arg_40_1.data = var_40_0

		for iter_40_0, iter_40_1 in ipairs(arg_40_0.select_) do
			if iter_40_1:getTableID() == var_40_0:getTableID() and iter_40_1.player_name == var_40_0.player_name then
				arg_40_1.teamNo_ = iter_40_0

				var_40_3:setVisible(true)
				var_40_4:setVisible(true)

				arg_40_0.team_[iter_40_0].iniCell_ = arg_40_1
				arg_40_0.team_[iter_40_0].iniCellVisible_ = false

				break
			end
		end

		arg_40_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_40_1:addChild(var_40_1)
		var_40_1:setName("yongbingCell")
		arg_40_1:setTouchSwallowEnabled(false)
		arg_40_1:setTouchEnabled(true)

		local var_40_22 = false

		for iter_40_2, iter_40_3 in pairs(arg_40_0.busyHeros_) do
			if iter_40_3 == var_40_0:getHeroID() then
				var_40_3:setVisible(true)
				var_40_4:setVisible(true)

				var_40_22 = true

				break
			end
		end

		if not var_40_22 then
			arg_40_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
				arg_40_0:buttonHandler(nil, arg_40_1, arg_41_0)

				if arg_41_0.name == "began" then
					arg_40_0.startClick_ = true
					arg_40_0.prevX_ = arg_41_0.x
					arg_40_0.prevY_ = arg_41_0.y
				elseif arg_41_0.name == "moved" then
					if math.abs(arg_41_0.y - arg_40_0.prevY_) > 5 or math.abs(arg_41_0.x - arg_40_0.prevX_) > 5 then
						arg_40_0.startClick_ = false
					end
				elseif arg_41_0.name == "ended" and arg_40_0.startClick_ then
					if var_40_15 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_13:translation("HERO_DIE_ERROR")
						})
					else
						local var_41_0 = xyd.StoryData.get():getGuideID()

						if var_41_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
							arg_40_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO1)
						elseif var_41_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
							arg_40_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO2)
						elseif var_41_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
							arg_40_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO3)
						end

						if arg_40_0.isAwakeCampaign and arg_40_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
							local function var_41_1()
								arg_40_0:clickAvatar(arg_40_1)
							end

							local var_41_2 = {
								txt = var_0_13:translation("AWAKE_SELECT_TEAM_TIP6"),
								type = xyd.CommonAlertType.TWO_BTN,
								align = xyd.ui_align.CENTER,
								rcallback = var_41_1
							}

							xyd.WindowManager.get():openWindow("common_alert", var_41_2)
						elseif arg_40_0.type == xyd.SelectTeamType.CHALLENGE and var_0_14:modeType(arg_40_0.battleID) == xyd.ChallengeType.OneHeroKillAll and #arg_40_0.team_ > 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_13:translation("CHALLENGE_ONLY_ONE_HERO")
							})
						else
							arg_40_0:clickAvatar(arg_40_1)
						end
					end
				end

				return true
			end)
		end
	else
		local var_40_23 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

		var_40_23:getChildByName("yongbing_tubiao"):setVisible(false)

		local var_40_24 = var_40_23:getChildByName("background"):getContentSize()

		var_40_23:setContentSize(var_40_24)
		arg_40_1:setContentSize(var_40_24)
		xyd.setAvatarBorder(var_40_0, var_40_23:getChildByName("avatar"))

		local var_40_25 = var_40_23:getChildByName("chosen")

		var_40_25:setLocalZOrder(100)
		var_40_25:setVisible(false)

		local var_40_26 = var_40_23:getChildByName("avatar_mask")

		var_40_26:setLocalZOrder(2)
		var_40_26:setVisible(false)

		arg_40_1.type = var_0_17.SELF_HERO

		var_40_23:getChildByName("is_can_rent"):setVisible(false)

		for iter_40_4 = 1, 3 do
			var_40_23:getChildByName("team" .. iter_40_4):setVisible(false)
		end

		if arg_40_0.type == xyd.SelectTeamType.ADVANCED and arg_40_0:isRecommend(var_40_0) then
			local var_40_27 = xyd.AssetLoader.get():loadSprite("windows/common/text/recommend.png")

			var_40_27:setAnchorPoint(cc.p(0.5, 1))
			var_40_27:setPosition(80, 135)
			var_40_23:addChild(var_40_27)
		elseif arg_40_0:checkHeroIsNotUse(var_40_0) then
			var_40_26:setVisible(true)

			local var_40_28 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

			var_40_28:setPosition(85, 120)
			var_40_23:addChild(var_40_28, 11)
		end

		var_40_23:getChildByName("lv_txt"):setString(var_40_0:getLevel())

		local var_40_29 = var_40_23:getChildByName("name_text")

		var_40_29:setString(var_40_0:getName())
		var_40_29:enableOutline(cc.c4b(0, 0, 0, 105), 1)

		if xyd.Color2Level[var_40_0:getColor()] ~= "" then
			local var_40_30 = {
				size = 20,
				align = cc.ui.TEXT_ALIGN_LEFT,
				valign = cc.ui.TEXT_VALIGN_BOTTOM,
				x = var_40_29:getX() + var_40_29:getWidth() / 2 - 10,
				y = var_40_29:getY(),
				color = xyd.color.HERO_QUALITY[var_40_0:getColor()],
				text = xyd.Color2Level[var_40_0:getColor()]
			}
			local var_40_31 = xyd.AssetLoader.get():loadLabel(var_40_30)

			var_40_31:addTo(var_40_23)
			var_40_31:align(display.CENTER_LEFT)
			var_40_31:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_40_29:x(var_40_29:getX() - 15)
		end

		local var_40_32 = var_40_23:getChildByName("hp_bar")
		local var_40_33 = var_40_23:getChildByName("mp_bar")
		local var_40_34 = var_40_23:getChildByName("dead_text")

		var_40_34:setString(var_0_13:translation("ALREADY_DEAD"))

		if var_40_34 then
			var_40_34:setVisible(false)
		end

		local var_40_35 = false
		local var_40_36

		if arg_40_0.heroStatus_ then
			var_40_36 = arg_40_0.heroStatus_.self_list

			if arg_40_0.campaignType == xyd.CampaignType.TREASURE then
				var_40_36 = arg_40_0.heroStatus_
			end
		end

		if var_40_36 and next(var_40_36) ~= nil then
			local var_40_37 = var_40_36[tostring(var_40_0:getHeroID())]

			var_40_0.healthStatus = var_40_37

			if var_40_37 and var_40_37.health then
				local var_40_38 = 0
				local var_40_39 = 0

				if var_40_37.health == 0 then
					var_40_38 = 100
					var_40_39 = 0
				elseif var_40_37.health == 1 and var_40_37.hp >= 1 then
					var_40_38 = var_40_37.hp / (var_40_37.total_hp or var_40_0:getTotalAttr(xyd.AttributeType.HP)) * 100
					var_40_39 = var_40_37.mp / 10
				else
					var_40_38 = 0
					var_40_39 = 0

					var_40_26:setVisible(true)
					var_40_34:setLocalZOrder(3)
					var_40_34:setVisible(true)
					var_40_34:enableOutline(cc.c4b(0, 0, 0), 2)
					var_40_34:getVirtualRenderer():setAdditionalKerning(2)

					var_40_35 = true
				end

				var_40_32:setPercent(var_40_38)
				var_40_32:setVisible(true)
				var_40_33:setPercent(var_40_39)
				var_40_33:setVisible(true)
			end
		else
			var_40_32:hide()
			var_40_33:hide()
			var_40_23:getChildByName("hp_di"):hide()
			var_40_23:getChildByName("mp_di"):hide()
		end

		var_40_23:setName("layout")
		var_40_23:setPosition(cc.p(0, 0))

		if arg_40_0.reinforcePartnerRatios[var_40_0:getTableID()] then
			local var_40_40 = xyd.AssetLoader.get():loadSprite("windows/common/attr_reinforcement.png")

			var_40_40:setAnchorPoint(cc.p(0, 0))

			local var_40_41 = arg_40_1:getContentSize()

			var_40_40:setPosition(var_40_41.width / 6, var_40_41.height - 40)
			var_40_23:addChild(var_40_40)

			local var_40_42 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 18,
				text = string.format("%6.2f%%", arg_40_0.reinforcePartnerRatios[var_40_0:getTableID()] * 100),
				color = cc.c4b(0, 192, 255, 255),
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_40_42:setAnchorPoint(cc.p(0, 0))
			var_40_42:addTo(var_40_40)
			var_40_42:setPosition(24, 3)
		end

		arg_40_1.data = var_40_0

		for iter_40_5, iter_40_6 in ipairs(arg_40_0.select_) do
			if iter_40_6:getTableID() == var_40_0:getTableID() and iter_40_6.player_name == var_40_0.player_name then
				arg_40_1.teamNo_ = iter_40_5

				var_40_25:setVisible(true)
				var_40_26:setVisible(true)

				arg_40_0.team_[iter_40_5].iniCell_ = arg_40_1
				arg_40_0.team_[iter_40_5].iniCellVisible_ = false

				break
			end
		end

		var_40_0.isDead = var_40_35

		arg_40_1:setAnchorPoint(cc.p(0.5, 0.5))
		arg_40_1:addChild(var_40_23)
		arg_40_1:setTouchSwallowEnabled(false)
		arg_40_1:setTouchEnabled(true)

		local var_40_43 = false

		for iter_40_7, iter_40_8 in pairs(arg_40_0.busyHeros_) do
			if iter_40_8 == var_40_0:getHeroID() then
				var_40_25:setVisible(true)
				var_40_26:setVisible(true)

				var_40_43 = true

				break
			end
		end

		if (arg_40_0.type == xyd.SelectTeamType.INCUBUS or arg_40_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER or arg_40_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_40_0.selectSpType == xyd.SelectSpType.BAN) and arg_40_0:isBanned(var_40_0) then
			local var_40_44 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_40_44:setAnchorPoint(cc.p(0.5, 1))
			var_40_44:setPosition(80, 135)
			var_40_23:addChild(var_40_44)
			var_40_26:setVisible(true)
		elseif not var_40_43 then
			arg_40_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
				arg_40_0:buttonHandler(nil, arg_40_1, arg_43_0)

				if arg_43_0.name == "began" then
					arg_40_0.startClick_ = true
					arg_40_0.prevX_ = arg_43_0.x
					arg_40_0.prevY_ = arg_43_0.y
				elseif arg_43_0.name == "moved" then
					if math.abs(arg_43_0.y - arg_40_0.prevY_) > 5 or math.abs(arg_43_0.x - arg_40_0.prevX_) > 5 then
						arg_40_0.startClick_ = false
					end
				elseif arg_43_0.name == "ended" and arg_40_0.startClick_ then
					if var_40_35 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_13:translation("HERO_DIE_ERROR")
						})
					else
						local var_43_0 = xyd.StoryData.get():getGuideID()

						if var_43_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
							arg_40_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO1)
						elseif var_43_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
							arg_40_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO2)
						elseif var_43_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
							arg_40_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT_HERO3)
						end

						if arg_40_0.isAwakeCampaign and arg_40_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL and var_40_0:getTableID() ~= arg_40_0.awakeHero:getTableID() then
							local function var_43_1()
								arg_40_0:clickAvatar(arg_40_1)
							end

							local var_43_2 = {
								txt = var_0_13:translation("AWAKE_SELECT_TEAM_TIP6"),
								type = xyd.CommonAlertType.TWO_BTN,
								rcallback = var_43_1,
								align = xyd.ui_align.CENTER
							}

							xyd.WindowManager.get():openWindow("common_alert", var_43_2)
						elseif arg_40_0.type == xyd.SelectTeamType.CHALLENGE and var_0_14:modeType(arg_40_0.battleID) == xyd.ChallengeType.OneHeroKillAll and #arg_40_0.team_ > 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_13:translation("CHALLENGE_ONLY_ONE_HERO")
							})
						elseif arg_40_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_40_0:checkHeroIsConquerUsed(var_40_0) then
							return
						else
							arg_40_0:clickAvatar(arg_40_1)
						end
					end
				end

				return true
			end)
		end
	end
end

function var_0_0.initBottomCell(arg_45_0, arg_45_1)
	local var_45_0 = display.newNode()
	local var_45_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
	local var_45_2 = var_45_1:getChildByName("background"):getContentSize()

	var_45_1:setContentSize(var_45_2)
	var_45_0:setContentSize(var_45_2)
	xyd.setAvatarBorder(arg_45_1, var_45_1:getChildByName("avatar"))

	local var_45_3 = var_45_1:getChildByName("chosen")

	var_45_3:setLocalZOrder(100)
	var_45_3:setVisible(false)

	local var_45_4 = var_45_1:getChildByName("avatar_mask")

	var_45_4:setLocalZOrder(2)
	var_45_4:setVisible(false)

	local var_45_5 = var_45_1:getChildByName("yongbing_tubiao")

	if arg_45_0.leftMenuType_ == var_0_17.RENT_HERO or arg_45_1.type == var_0_17.RENT_HERO then
		var_45_5:setVisible(true)

		var_45_0.type = var_0_17.RENT_HERO
	else
		var_45_5:setVisible(false)

		var_45_0.type = var_0_17.SELF_HERO
	end

	if arg_45_1.isAssist and arg_45_0.campaignType == xyd.CampaignType.NORMAL then
		local var_45_6 = xyd.AssetLoader.get():loadSprite("windows/battle/text_assist.png")

		var_45_6:addTo(var_45_0)
		var_45_6:setAnchorPoint(cc.p(1, 1))
		var_45_6:setPosition(cc.p(var_45_2.width, var_45_2.height))
		var_45_6:setLocalZOrder(99)

		arg_45_0.assistHeroNode = var_45_0

		var_45_0:setVisible(false)
	end

	for iter_45_0 = 1, 3 do
		var_45_1:getChildByName("team" .. iter_45_0):setVisible(false)
	end

	var_45_1:getChildByName("lv_txt"):setString(arg_45_1:getLevel())

	local var_45_7 = var_45_1:getChildByName("name_text")

	var_45_7:setString(arg_45_1:getName())
	var_45_7:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_45_1:getColor()] ~= "" then
		local var_45_8 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_45_7:getX() + var_45_7:getWidth() / 2 - 10,
			y = var_45_7:getY(),
			color = xyd.color.HERO_QUALITY[arg_45_1:getColor()],
			text = xyd.Color2Level[arg_45_1:getColor()]
		}
		local var_45_9 = xyd.AssetLoader.get():loadLabel(var_45_8)

		var_45_9:addTo(var_45_1)
		var_45_9:align(display.CENTER_LEFT)
		var_45_9:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_45_7:x(var_45_7:getX() - 15)
	end

	local var_45_10 = var_45_1:getChildByName("hp_bar")
	local var_45_11 = var_45_1:getChildByName("mp_bar")
	local var_45_12 = var_45_1:getChildByName("dead_text")

	if var_45_12 then
		var_45_12:setVisible(false)
	end

	local var_45_13 = false

	if arg_45_0.heroStatus_ then
		if var_45_0.type == var_0_17.RENT_HERO then
			local var_45_14 = arg_45_0.heroStatus_.rent_list

			if var_45_14 and var_45_14.health then
				local var_45_15 = var_45_14

				arg_45_1.healthStatus = var_45_15

				if var_45_15 and var_45_15.health then
					local var_45_16 = 0
					local var_45_17 = 0

					if var_45_15.health == 0 then
						var_45_16 = 100
						var_45_17 = 0
					elseif var_45_15.health == 1 then
						var_45_16 = var_45_15.hp / (var_45_15.total_hp or arg_45_1:getTotalAttr(xyd.AttributeType.HP)) * 100
						var_45_17 = var_45_15.mp / 10
					else
						var_45_16 = 0
						var_45_17 = 0

						var_45_4:setVisible(true)
						var_45_12:setLocalZOrder(3)
						var_45_12:setVisible(true)
						var_45_12:enableOutline(cc.c4b(0, 0, 0), 2)
						var_45_12:getVirtualRenderer():setAdditionalKerning(2)

						local var_45_18 = true
					end

					var_45_10:setPercent(var_45_16)
					var_45_10:setVisible(true)
					var_45_11:setPercent(var_45_17)
					var_45_11:setVisible(true)
				end
			elseif (not var_45_14 or not var_45_14.health) and arg_45_0.campaignType == xyd.CampaignType.MARCH then
				arg_45_1.healthStatus = {}
				arg_45_1.healthStatus.health = 0
				arg_45_1.healthStatus.mp = 0
				arg_45_1.healthStatus.hp = 0

				local var_45_19 = 100
				local var_45_20 = 0

				var_45_10:setPercent(var_45_19)
				var_45_10:setVisible(true)
				var_45_11:setPercent(var_45_20)
				var_45_11:setVisible(true)
			else
				var_45_10:hide()
				var_45_11:hide()
				var_45_1:getChildByName("hp_di"):hide()
				var_45_1:getChildByName("mp_di"):hide()
			end
		else
			local var_45_21 = arg_45_0.heroStatus_.self_list

			if arg_45_0.campaignType == xyd.CampaignType.TREASURE then
				var_45_21 = arg_45_0.heroStatus_
			end

			if var_45_21 and next(var_45_21) then
				local var_45_22 = var_45_21[tostring(arg_45_1:getHeroID())]

				arg_45_1.healthStatus = var_45_22

				if var_45_22 and var_45_22.health then
					local var_45_23 = 0
					local var_45_24 = 0

					if var_45_22.health == 0 then
						var_45_23 = 100
						var_45_24 = 0
					elseif var_45_22.health == 1 then
						var_45_23 = var_45_22.hp / (var_45_22.total_hp or arg_45_1:getTotalAttr(xyd.AttributeType.HP)) * 100
						var_45_24 = var_45_22.mp / 10
					else
						var_45_23 = 0
						var_45_24 = 0

						var_45_4:setVisible(true)
						var_45_12:setLocalZOrder(3)
						var_45_12:setVisible(true)
						var_45_12:enableOutline(cc.c4b(0, 0, 0), 2)
						var_45_12:getVirtualRenderer():setAdditionalKerning(2)

						local var_45_25 = true
					end

					var_45_10:setPercent(var_45_23)
					var_45_10:setVisible(true)
					var_45_11:setPercent(var_45_24)
					var_45_11:setVisible(true)
				end
			else
				var_45_10:hide()
				var_45_11:hide()
				var_45_1:getChildByName("hp_di"):hide()
				var_45_1:getChildByName("mp_di"):hide()
			end
		end
	else
		var_45_10:hide()
		var_45_11:hide()
		var_45_1:getChildByName("hp_di"):hide()
		var_45_1:getChildByName("mp_di"):hide()
	end

	var_45_1:setName("layout")

	var_45_0.data = arg_45_1

	var_45_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_45_0:addChild(var_45_1)

	return var_45_0
end

function var_0_0.initPetBottomCell(arg_46_0, arg_46_1)
	local var_46_0 = display.newNode()

	var_46_0:size(146, 146)
	var_46_0:align(display.CENTER)

	var_46_0.data = arg_46_1
	var_46_0.type = var_0_19.SELF_PET

	xyd.setPetAvatar(var_46_0, arg_46_1, 100)

	if arg_46_0.rentMenuType == var_0_18.RENT_PET then
		local var_46_1 = xyd.AssetLoader.get():loadSprite("windows/cloud_city/yongbing_tubiao.png")

		var_46_1:addTo(var_46_0)
		var_46_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_46_1:setPosition(cc.p(110, 120))

		var_46_0.type = var_0_19.RENT_PET
	end

	return var_46_0
end

function var_0_0.delegate(arg_47_0, ...)
	if arg_47_0.isHeroPreset then
		return arg_47_0:presetDelegate(...)
	elseif arg_47_0.leftMenuType_ == var_0_17.SELF_PET or arg_47_0.leftMenuType_ == var_0_17.RENT_HERO and arg_47_0.rentMenuType == var_0_18.RENT_PET then
		return arg_47_0:petDelegate(...)
	end

	return arg_47_0:heroDelegate(...)
end

function var_0_0.petDelegate(arg_48_0, arg_48_1, arg_48_2, arg_48_3)
	if arg_48_0.leftMenuType_ == var_0_17.SELF_PET then
		var_0_6 = 5
	else
		var_0_6 = 4
	end

	local var_48_0 = math.ceil(#arg_48_0.totalPet_ / var_0_6)

	if cc.ui.UIListView.COUNT_TAG == arg_48_2 then
		return var_48_0
	elseif cc.ui.UIListView.CELL_TAG == arg_48_2 then
		local var_48_1
		local var_48_2
		local var_48_3
		local var_48_4 = arg_48_0.heroList_:dequeueItem()

		if not var_48_4 then
			var_48_4 = arg_48_0.heroList_:newItem()
		else
			var_48_4:removeAllChildren()
		end

		local var_48_5 = display.newNode()

		var_48_5:setTouchSwallowEnabled(false)

		for iter_48_0 = 1, var_0_6 do
			local var_48_6 = (arg_48_3 - 1) * var_0_6 + iter_48_0

			if var_48_6 > #arg_48_0.totalPet_ then
				break
			end

			var_48_3 = display.newNode()

			arg_48_0:initPetCell(var_48_3, var_48_6)

			local var_48_7 = var_48_3:getContentSize().width
			local var_48_8 = var_48_3:getContentSize().height
			local var_48_9 = (arg_48_0.heroList_.viewRect_.width - var_48_7 * var_0_6) / (var_0_6 + 1)

			var_48_3:align(display.CENTER, var_48_9 * iter_48_0 + (iter_48_0 - 1) * var_48_7 + var_48_7 / 2, var_48_8 / 2)
			var_48_5:addChild(var_48_3)
		end

		var_48_5:setContentSize(cc.size(arg_48_0.heroList_.viewRect_.width, var_48_3:getContentSize().height))
		var_48_4:setItemSize(arg_48_0.heroList_.viewRect_.width, var_48_3:getContentSize().height)
		var_48_4:addContent(var_48_5)

		return var_48_4
	end
end

function var_0_0.presetDelegate(arg_49_0, arg_49_1, arg_49_2, arg_49_3)
	local var_49_0 = #arg_49_0.presetTeams

	if cc.ui.UIListView.COUNT_TAG == arg_49_2 then
		return var_49_0
	elseif cc.ui.UIListView.CELL_TAG == arg_49_2 then
		local var_49_1
		local var_49_2
		local var_49_3
		local var_49_4 = arg_49_0.heroList_:dequeueItem()

		if not var_49_4 then
			var_49_4 = arg_49_0.heroList_:newItem()
		else
			var_49_4:removeAllChildren()
		end

		local var_49_5 = display.newNode()

		var_49_5:setTouchSwallowEnabled(false)

		local var_49_6 = display.newNode()

		arg_49_0:initPresetCell(var_49_6, arg_49_3)
		var_49_5:addChild(var_49_6)
		var_49_5:setContentSize(cc.size(arg_49_0.heroList_.viewRect_.width, var_49_6:getContentSize().height))
		var_49_4:setItemSize(arg_49_0.heroList_.viewRect_.width, var_49_6:getContentSize().height)
		var_49_4:addContent(var_49_5)

		return var_49_4
	end
end

function var_0_0.heroDelegate(arg_50_0, arg_50_1, arg_50_2, arg_50_3)
	if arg_50_0.leftMenuType_ == var_0_17.SELF_HERO then
		var_0_5 = 5
	else
		var_0_5 = 4
	end

	local var_50_0 = math.ceil(#arg_50_0.totalHero_[arg_50_0.selectedHeroClass_[arg_50_0.leftMenuType_]] / var_0_5)

	if cc.ui.UIListView.COUNT_TAG == arg_50_2 then
		return var_50_0
	elseif cc.ui.UIListView.CELL_TAG == arg_50_2 then
		local var_50_1
		local var_50_2
		local var_50_3
		local var_50_4 = arg_50_0.heroList_:dequeueItem()

		if not var_50_4 then
			var_50_4 = arg_50_0.heroList_:newItem()
		else
			var_50_4:removeAllChildren()
		end

		local var_50_5 = display.newNode()

		var_50_5:setTouchSwallowEnabled(false)

		for iter_50_0 = 1, var_0_5 do
			local var_50_6 = (arg_50_3 - 1) * var_0_5 + iter_50_0

			if var_50_6 > #arg_50_0.totalHero_[arg_50_0.selectedHeroClass_[arg_50_0.leftMenuType_]] then
				break
			end

			var_50_3 = display.newNode()

			arg_50_0:initHeroCell(var_50_3, var_50_6)

			local var_50_7 = var_50_3:getContentSize().width
			local var_50_8 = var_50_3:getContentSize().height
			local var_50_9 = (arg_50_0.heroList_.viewRect_.width - var_50_7 * var_0_5) / (var_0_5 + 1)

			var_50_3:pos(var_50_9 * iter_50_0 + (iter_50_0 - 1) * var_50_7 + var_50_7 / 2, var_0_4 + var_50_8 / 2 - 2)
			var_50_5:addChild(var_50_3)

			arg_50_0.heroCells_[var_50_6] = var_50_3
		end

		var_50_5:setContentSize(cc.size(arg_50_0.heroList_.viewRect_.width, var_50_3:getContentSize().height + var_0_4))
		var_50_4:setItemSize(arg_50_0.heroList_.viewRect_.width, var_50_3:getContentSize().height + var_0_4)
		var_50_4:addContent(var_50_5)

		return var_50_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_51_0)
	for iter_51_0 = 1, #arg_51_0.rightMenuButtons_ do
		if iter_51_0 == arg_51_0.selectedHeroClass_[arg_51_0.leftMenuType_] then
			arg_51_0.rightMenuButtons_[iter_51_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_51_0.rightMenuButtons_[iter_51_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_51_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.normal)
	arg_51_0.heroList_:removeAllItems()

	if arg_51_0.selectedHeroClass_[arg_51_0.leftMenuType_] == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_51_0.selectedHeroClass_[arg_51_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_51_1, iter_51_2 in ipairs(arg_51_0.select_) do
			if iter_51_2:getDistanceType() ~= arg_51_0.selectedHeroClass_[arg_51_0.leftMenuType_] then
				arg_51_0.team_[iter_51_1].iniCellVisible_ = true
			end
		end
	end

	arg_51_0:initPreHeros()
	arg_51_0:initPrePets()
	arg_51_0.heroList_:reload()
end

function var_0_0.buttonHandler(arg_52_0, arg_52_1, arg_52_2, arg_52_3)
	if not arg_52_2 or not arg_52_2:getParent() then
		return
	end

	if arg_52_3.name == "ended" then
		transition.stopTarget(arg_52_2)
		arg_52_2:setScale(1)

		if arg_52_1 then
			arg_52_1(arg_52_2, eventType)
		end
	elseif arg_52_3.name == "began" then
		local var_52_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_52_2:runAction(var_52_0)

		return true
	elseif arg_52_3.name == "cancled" then
		transition.stopTarget(arg_52_2)
		arg_52_2:setScale(1)
	end
end

function var_0_0.initPrePets(arg_53_0)
	if not arg_53_0:isPet() or arg_53_0.isAwakeCampaign then
		return
	end

	for iter_53_0, iter_53_1 in ipairs(arg_53_0.prePet_) do
		local var_53_0, var_53_1 = arg_53_0:nodeByName("avatar_pet" .. iter_53_0):getPosition()
		local var_53_2 = arg_53_0:initPetBottomCell(iter_53_1)

		var_53_2:pos(var_53_0, var_53_1)
		var_53_2:addTo(arg_53_0)
		var_53_2:setTouchEnabled(true)
		var_53_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
			if arg_54_0.name == "ended" then
				arg_53_0:clickPetBottomAvatar(var_53_2)
			end

			return true
		end)
		arg_53_0:getPetTeamNo(var_53_2)
	end

	arg_53_0.prePet_ = {}
end

function var_0_0.initPreHeros(arg_55_0, arg_55_1)
	if arg_55_0.preSelect_ and arg_55_0.preHeros_ then
		for iter_55_0, iter_55_1 in pairs(arg_55_0.preHeros_) do
			if iter_55_1.type == var_0_17.RENT_HERO then
				if not iter_55_1.can_rent or iter_55_1.isDead or arg_55_0.isSelectMerHero or not arg_55_0:checkHeroValid(iter_55_1) then
					return
				end

				local var_55_0 = iter_55_1.rent_need_mana

				if var_55_0 and var_55_0 > arg_55_0.selfPlayer.mana and not iter_55_1.have_rent then
					return
				end

				local var_55_1 = false

				if arg_55_0.heroStatus_ then
					local var_55_2 = arg_55_0.heroStatus_.rent_list

					iter_55_1.healthStatus = var_55_2

					if var_55_2 and var_55_2.health then
						local var_55_3 = 0
						local var_55_4 = 0

						if var_55_2.health == 0 then
							local var_55_5 = 100
							local var_55_6 = 0
						elseif var_55_2.health == 1 and var_55_2.hp >= 1 then
							local var_55_7 = var_55_2.hp / (var_55_2.total_hp or iter_55_1:getTotalAttr(xyd.AttributeType.HP)) * 100
							local var_55_8 = var_55_2.mp / 10
						else
							local var_55_9 = 0
							local var_55_10 = 0

							var_55_1 = true
						end
					end
				end

				if not var_55_1 then
					local var_55_11 = arg_55_0:initBottomCell(iter_55_1)

					var_55_11.iniCellVisible_ = true
					var_55_11.iniCell_ = display.newNode()

					var_55_11:addTo(arg_55_0)
					var_55_11:setTouchEnabled(true)
					var_55_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_56_0)
						if arg_56_0.name == "ended" then
							if (iter_55_1.isChallengeKillSteal_ or iter_55_1.isChallengeProtected_) and arg_55_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_14:modeType(arg_55_0.battleID) == xyd.ChallengeType.KillSteal or var_0_14:modeType(arg_55_0.battleID) == xyd.ChallengeType.Protect) then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_13:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
								})
							else
								arg_55_0:clickBottomAvatar(var_55_11)
							end
						end

						return true
					end)

					if iter_55_1.type == var_0_17.RENT_HERO then
						arg_55_0.isSelectMerHero = true
						arg_55_0.selectMerHero = var_55_11.data
					end

					for iter_55_2 = arg_55_0:getTeamNo(var_55_11), #arg_55_0.team_ do
						local var_55_12, var_55_13 = arg_55_0:nodeByName("avatar" .. iter_55_2):getPosition()

						arg_55_0.team_[iter_55_2]:pos(var_55_12, var_55_13)

						if arg_55_0.team_[iter_55_2].iniCell_ then
							arg_55_0.team_[iter_55_2].iniCell_.teamNo_ = iter_55_2
						end
					end
				end
			elseif arg_55_0.selectSpType ~= 0 and not arg_55_0:canHeroJoinBattle(iter_55_1) then
				-- block empty
			else
				if (arg_55_0.campaignType == xyd.CampaignType.MARCH or arg_55_0.campaignType == xyd.CampaignType.TREASURE) and iter_55_1.isDead or not arg_55_0:checkHeroValid(iter_55_1) then
					return
				end

				local var_55_14 = false

				if arg_55_0.heroStatus_ then
					local var_55_15 = arg_55_0.heroStatus_.self_list

					if arg_55_0.campaignType == xyd.CampaignType.TREASURE then
						var_55_15 = arg_55_0.heroStatus_
					end

					local var_55_16 = var_55_15[tostring(iter_55_1:getHeroID())]

					iter_55_1.healthStatus = var_55_16

					if var_55_16 and var_55_16.health then
						local var_55_17 = 0
						local var_55_18 = 0

						if var_55_16.health == 0 then
							local var_55_19 = 100
							local var_55_20 = 0
						elseif var_55_16.health == 1 and var_55_16.hp >= 1 then
							local var_55_21 = var_55_16.hp / (var_55_16.total_hp or iter_55_1:getTotalAttr(xyd.AttributeType.HP)) * 100
							local var_55_22 = var_55_16.mp / 10
						else
							local var_55_23 = 0
							local var_55_24 = 0

							var_55_14 = true
						end
					end
				end

				local var_55_25

				if arg_55_0.campaignType == xyd.CampaignType.MEMORIES_OF_SCHOOL then
					var_55_25 = arg_55_0:isBanned(iter_55_1)
				end

				if not var_55_14 and not var_55_25 then
					local var_55_26 = arg_55_0:initBottomCell(iter_55_1)

					if arg_55_1 then
						var_55_26:hide()
					end

					var_55_26.iniCellVisible_ = true
					var_55_26.iniCell_ = display.newNode()

					var_55_26:addTo(arg_55_0)
					var_55_26:setTouchEnabled(true)
					var_55_26:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_57_0)
						if arg_57_0.name == "ended" then
							local function var_57_0()
								arg_55_0:clickBottomAvatar(var_55_26)
							end

							if arg_55_0.isAwakeCampaign and iter_55_1:getTableID() == arg_55_0.awakeHero:getTableID() then
								local var_57_1 = {
									txt = string.format(var_0_13:translation("AWAKE_SELECT_TEAM_TIP5"), iter_55_1:getName()),
									type = xyd.CommonAlertType.TWO_BTN,
									align = xyd.ui_align.CENTER,
									rcallback = var_57_0
								}

								xyd.WindowManager.get():openWindow("common_alert", var_57_1)
							elseif (iter_55_1.isChallengeKillSteal_ or iter_55_1.isChallengeProtected_) and arg_55_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_14:modeType(arg_55_0.battleID) == xyd.ChallengeType.KillSteal or var_0_14:modeType(arg_55_0.battleID) == xyd.ChallengeType.Protect) then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_13:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
								})
							elseif iter_55_1.isAssist and arg_55_0.campaignType == xyd.CampaignType.NORMAL then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_13:translation("CAMPAIGN_ASSIST_HERO")
								})
							elseif iter_55_1.isAssist and arg_55_0.selectSpType == xyd.SelectSpType.ASSIST then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_13:translation("CAMPAIGN_ASSIST_HERO")
								})
							else
								arg_55_0:clickBottomAvatar(var_55_26)
							end
						end

						return true
					end)

					for iter_55_3 = arg_55_0:getTeamNo(var_55_26), #arg_55_0.team_ do
						local var_55_27, var_55_28 = arg_55_0:nodeByName("avatar" .. iter_55_3):getPosition()

						arg_55_0.team_[iter_55_3]:pos(var_55_27, var_55_28)

						if arg_55_0.team_[iter_55_3].iniCell_ then
							arg_55_0.team_[iter_55_3].iniCell_.teamNo_ = iter_55_3
						end
					end
				end
			end
		end

		arg_55_0:updateScore()
	end

	arg_55_0.preSelect_ = {}
	arg_55_0.preHeros_ = {}
end

function var_0_0.clickAvatar(arg_59_0, arg_59_1, arg_59_2)
	if arg_59_1.isAnimated_ or not arg_59_1.teamNo_ and #arg_59_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	if arg_59_0.selectSpType == xyd.SelectSpType.SINGLE and #arg_59_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_13:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return
	end

	if arg_59_0.selectSpType == xyd.SelectSpType.TRIPLE and #arg_59_0.team_ >= 3 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_13:translation("ARENA_MODE_MAX_HERO"), 3)
		})

		return
	end

	if not arg_59_2 then
		arg_59_0.unPreSelect_ = true
	end

	local var_59_0

	if arg_59_0.leftMenuType_ == var_0_17.SELF_HERO then
		var_59_0 = arg_59_1:getChildByName("layout")
	else
		var_59_0 = arg_59_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_59_1 = var_59_0:getChildByName("avatar_mask")
	local var_59_2 = var_59_0:getChildByName("chosen")
	local var_59_3 = arg_59_1:convertToWorldSpace(cc.p(0, 0))
	local var_59_4 = var_59_3.x + arg_59_1:getContentSize().width / 2
	local var_59_5 = var_59_3.y + arg_59_1:getContentSize().height / 2

	arg_59_1.isAnimated_ = true

	if arg_59_1.teamNo_ then
		local var_59_6 = arg_59_0.team_[arg_59_1.teamNo_]

		arg_59_0:moveFadeOutAction(var_59_4, var_59_5, var_59_6, function()
			arg_59_1.isAnimated_ = false
		end)
		var_59_1:setVisible(false)
		var_59_2:setVisible(false)

		for iter_59_0 = #arg_59_0.team_, arg_59_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_59_0.team_[iter_59_0])

			local var_59_7, var_59_8 = arg_59_0:nodeByName("avatar" .. iter_59_0 - 1):getPosition()

			transition.moveTo(arg_59_0.team_[iter_59_0], {
				time = 0.3,
				x = var_59_7,
				y = var_59_8
			})

			arg_59_0.team_[iter_59_0].iniCell_.teamNo_ = iter_59_0 - 1
		end

		if arg_59_1.type == var_0_17.RENT_HERO then
			arg_59_0.isSelectMerHero = false
			arg_59_0.selectMerHero = nil
		end

		table.remove(arg_59_0.team_, arg_59_1.teamNo_)
		table.remove(arg_59_0.select_, arg_59_1.teamNo_)

		arg_59_1.teamNo_ = nil
	elseif not arg_59_1.teamNo_ and #arg_59_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if not arg_59_2 then
			local var_59_9 = arg_59_1.data

			if var_0_15:chosenSound(var_59_9:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_59_9:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_15:chosenSound(var_59_9:getTableID()), false)
			end
		end

		if not arg_59_1.data.can_rent and arg_59_0.leftMenuType_ == var_0_17.RENT_HERO then
			arg_59_1.isAnimated_ = false

			return
		end

		if arg_59_1.data.isDead then
			arg_59_1.isAnimated_ = false

			return
		end

		if (arg_59_0.isSelectMerHero or arg_59_0.isSelectMerPet) and arg_59_0.leftMenuType_ == var_0_17.RENT_HERO then
			arg_59_1.isAnimated_ = false

			local var_59_10 = var_0_13:translation("MERCENARY_ERROR_TIP1")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_59_10
			})

			return
		end

		if not arg_59_0:checkHeroValid(arg_59_1.data) then
			arg_59_1.isAnimated_ = false

			local var_59_11 = var_0_13:translation("MERCENARY_ERROR_TIP2")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_59_11
			})

			return
		end

		local var_59_12 = arg_59_1.data.rent_need_mana

		if var_59_12 and var_59_12 > arg_59_0.selfPlayer.mana and not arg_59_1.data.have_rent then
			arg_59_1.isAnimated_ = false

			local var_59_13 = var_0_13:translation("MERCENARY_ERROR_TIP3")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_59_13
			})

			return
		end

		local var_59_14 = arg_59_0:initBottomCell(arg_59_1.data)

		var_59_14.iniCell_ = arg_59_1

		var_59_14:pos(var_59_4, var_59_5)
		var_59_14:addTo(arg_59_0)
		var_59_14:setTouchEnabled(true)

		local var_59_15 = arg_59_1.data

		var_59_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_62_0)
			if arg_62_0.name == "ended" then
				local function var_62_0()
					arg_59_0:clickBottomAvatar(var_59_14)
				end

				if arg_59_0.isAwakeCampaign and var_59_15:getTableID() == arg_59_0.awakeHero:getTableID() and arg_59_1.type == var_0_17.SELF_HERO then
					local var_62_1 = {
						txt = string.format(var_0_13:translation("AWAKE_SELECT_TEAM_TIP5"), var_59_15:getName()),
						type = xyd.CommonAlertType.TWO_BTN,
						align = xyd.ui_align.CENTER,
						rcallback = var_62_0
					}

					xyd.WindowManager.get():openWindow("common_alert", var_62_1)
				elseif (var_59_15.isChallengeKillSteal_ or var_59_15.isChallengeProtected_) and arg_59_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_14:modeType(arg_59_0.battleID) == xyd.ChallengeType.KillSteal or var_0_14:modeType(arg_59_0.battleID) == xyd.ChallengeType.Protect) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
					})
				elseif var_59_15.isAssist and arg_59_0.campaignType == xyd.CampaignType.NORMAL then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("CAMPAIGN_ASSIST_HERO")
					})
				elseif var_59_15.isAssist and arg_59_0.selectSpType == xyd.SelectSpType.ASSIST then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("CAMPAIGN_ASSIST_HERO")
					})
				else
					arg_59_0:clickBottomAvatar(var_59_14)
				end
			end

			return true
		end)

		if arg_59_1.type == var_0_17.RENT_HERO then
			arg_59_0.isSelectMerHero = true
			arg_59_0.selectMerHero = var_59_14.data
		end

		arg_59_1.teamNo_ = arg_59_0:getTeamNo(var_59_14)

		for iter_59_1 = arg_59_1.teamNo_, #arg_59_0.team_ do
			local var_59_16, var_59_17 = arg_59_0:nodeByName("avatar" .. iter_59_1):getPosition()

			if arg_59_2 then
				arg_59_0.team_[iter_59_1]:pos(var_59_16, var_59_17)

				arg_59_1.isAnimated_ = false
			elseif iter_59_1 ~= arg_59_1.teamNo_ then
				local var_59_18 = arg_59_0.team_[iter_59_1]

				transition.stopTarget(var_59_18)
				transition.moveTo(var_59_18, {
					time = 0.3,
					x = var_59_16,
					y = var_59_17,
					onComplete = function()
						var_59_18.iniCell_.isAnimated_ = false
						var_59_18.isAnimated_ = false
					end
				})
			else
				local var_59_19 = arg_59_0.team_[iter_59_1]

				transition.stopTarget(var_59_19)

				var_59_14.isAnimated_ = true

				transition.moveTo(var_59_19, {
					time = 0.3,
					x = var_59_16,
					y = var_59_17,
					onComplete = function()
						arg_59_1.isAnimated_ = false
						var_59_14.isAnimated_ = false
					end
				})
			end

			arg_59_0.team_[iter_59_1].iniCell_.teamNo_ = iter_59_1
		end

		var_59_1:setVisible(true)
		var_59_2:setVisible(true)
	end

	if not arg_59_2 then
		arg_59_0:playGuide()
	end

	arg_59_0:updateScore()
end

function var_0_0.checkHeroValid(arg_66_0, arg_66_1)
	for iter_66_0, iter_66_1 in pairs(arg_66_0.select_) do
		if arg_66_1:getTableID() == iter_66_1:getTableID() or xyd.tables.hero:beforeAwaken(arg_66_1:getTableID()) == iter_66_1:getTableID() or xyd.tables.hero:afterAwaken(arg_66_1:getTableID()) == iter_66_1:getTableID() or iter_66_1.isAssist and arg_66_1:getTableID() == arg_66_0.assistHeroID then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_67_0)
	if arg_67_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_67_0.type == xyd.SelectTeamType.REGION_ARENA then
		arg_67_0:nodeByName("text_bg"):hide()

		return
	end

	local var_67_0 = 0
	local var_67_1 = 0

	for iter_67_0, iter_67_1 in ipairs(arg_67_0.team_) do
		local var_67_2 = iter_67_1.data

		var_67_0 = var_67_0 + var_67_2:getZhandouli()

		if arg_67_0.type == xyd.SelectTeamType.ADVANCED then
			if arg_67_0:isRecommend(var_67_2) then
				var_67_1 = var_67_1 + var_67_2:getZhandouli() * 2
			else
				var_67_1 = var_67_1 + var_67_2:getZhandouli()
			end
		end
	end

	for iter_67_2, iter_67_3 in ipairs(arg_67_0.petTeam_) do
		var_67_0 = var_67_0 + iter_67_3.data:getZhandouli()
	end

	arg_67_0:nodeByName("zhandouli"):setString(var_67_0)

	if arg_67_0.type == xyd.SelectTeamType.ADVANCED then
		local var_67_3 = ""
		local var_67_4 = var_67_1 < arg_67_0.rateValue[1] and "d" or var_67_1 < arg_67_0.rateValue[2] and "c" or var_67_1 < arg_67_0.rateValue[3] and "b" or var_67_1 < arg_67_0.rateValue[4] and "a" or "s"

		arg_67_0:nodeByName("rate_pic"):loadTexture("windows/common/rate/" .. var_67_4 .. ".png")

		arg_67_0.rateScore = var_67_1
	end
end

function var_0_0.clickBottomAvatar(arg_68_0, arg_68_1)
	if arg_68_1.isAnimated_ then
		return
	end

	local var_68_0, var_68_1 = arg_68_0:nodeByName("list_layer"):getPosition()
	local var_68_2 = arg_68_1.iniCell_
	local var_68_3

	for iter_68_0, iter_68_1 in ipairs(arg_68_0.select_) do
		if iter_68_1:getTableID() == arg_68_1.data:getTableID() and iter_68_1.player_name == arg_68_1.data.player_name then
			var_68_3 = iter_68_0

			break
		end
	end

	if not var_68_3 then
		return
	end

	if not arg_68_1.iniCellVisible_ and arg_68_1.type == arg_68_0.leftMenuType_ and not tolua.isnull(var_68_2) then
		local var_68_4 = var_68_2:convertToWorldSpace(cc.p(0, 0))

		var_68_0, var_68_1 = var_68_4.x + var_68_2:getContentSize().width / 2, var_68_4.y + var_68_2:getContentSize().height / 2

		local var_68_5

		if arg_68_1.type == var_0_17.RENT_HERO then
			var_68_5 = var_68_2:getChildByName("yongbingCell"):getChildByName("container")
		else
			var_68_5 = var_68_2:getChildByName("layout")
		end

		local var_68_6 = var_68_5:getChildByName("avatar_mask")
		local var_68_7 = var_68_5:getChildByName("chosen")

		var_68_6:setVisible(false)
		var_68_7:setVisible(false)
	end

	arg_68_0:moveFadeOutAction(var_68_0, var_68_1, arg_68_1)

	for iter_68_2 = #arg_68_0.team_, var_68_3 + 1, -1 do
		local var_68_8 = arg_68_0.team_[iter_68_2]
		local var_68_9, var_68_10 = arg_68_0:nodeByName("avatar" .. iter_68_2 - 1):getPosition()

		transition.stopTarget(var_68_8)
		transition.moveTo(arg_68_0.team_[iter_68_2], {
			time = 0.3,
			x = var_68_9,
			y = var_68_10
		})

		arg_68_0.team_[iter_68_2].iniCell_.teamNo_ = iter_68_2 - 1
	end

	if arg_68_1.type == var_0_17.RENT_HERO then
		arg_68_0.isSelectMerHero = false
		arg_68_0.selectMerHero = nil
	end

	table.remove(arg_68_0.team_, var_68_3)
	table.remove(arg_68_0.select_, var_68_3)

	var_68_2.teamNo_ = nil

	arg_68_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_69_0, arg_69_1, arg_69_2)
	if arg_69_1.isAnimated_ then
		return
	end

	local var_69_0, var_69_1 = arg_69_0:nodeByName("list_layer"):getPosition()
	local var_69_2 = arg_69_1.iniCell_
	local var_69_3

	for iter_69_0, iter_69_1 in ipairs(arg_69_0.petSelect_) do
		if iter_69_1:getTableID() == arg_69_1.data:getTableID() and iter_69_1.player_name == arg_69_1.data.player_name then
			var_69_3 = iter_69_0

			break
		end
	end

	if not var_69_3 then
		return
	end

	if var_69_2 and not tolua.isnull(var_69_2) then
		local var_69_4 = var_69_2:convertToWorldSpace(cc.p(0, 0))

		var_69_0, var_69_1 = var_69_4.x, var_69_4.y

		local var_69_5

		if arg_69_0.rentMenuType == var_0_18.RENT_PET then
			var_69_5 = var_69_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_69_5 = var_69_2:getChildByName("layout")
		end

		local var_69_6 = var_69_5:getChildByName("avatar_mask")
		local var_69_7 = var_69_5:getChildByName("chosen")

		var_69_6:setVisible(false)
		var_69_7:setVisible(false)
	end

	arg_69_0:moveFadeOutAction(var_69_0, var_69_1, arg_69_1, arg_69_2)

	for iter_69_2 = #arg_69_0.petTeam_, var_69_3 + 1, -1 do
		local var_69_8 = arg_69_0.petTeam_[iter_69_2]
		local var_69_9, var_69_10 = arg_69_0:nodeByName("avatar_pet" .. iter_69_2 - 1):getPosition()

		transition.stopTarget(var_69_8)
		transition.moveTo(arg_69_0.petTeam_[iter_69_2], {
			time = 0.3,
			x = var_69_9,
			y = var_69_10
		})

		arg_69_0.petTeam_[iter_69_2].iniCell_.teamNo_ = iter_69_2 - 1
	end

	if arg_69_1.type == var_0_19.RENT_PET then
		arg_69_0.isSelectMerPet = false
		arg_69_0.selectMerPet = nil
	end

	table.remove(arg_69_0.petTeam_, var_69_3)
	table.remove(arg_69_0.petSelect_, var_69_3)

	if var_69_2 then
		var_69_2.teamNo_ = nil
	end

	arg_69_0:updateScore()
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_70_0, arg_70_1, arg_70_2)
	if arg_70_1.isAnimated_ then
		return
	end

	local var_70_0, var_70_1 = arg_70_0:nodeByName("list_layer"):getPosition()
	local var_70_2 = arg_70_1.iniCell_
	local var_70_3

	for iter_70_0, iter_70_1 in ipairs(arg_70_0.petTeam_) do
		if iter_70_1 == arg_70_1 then
			var_70_3 = iter_70_0

			break
		end
	end

	if not var_70_3 then
		return
	end

	if var_70_2 and not tolua.isnull(var_70_2) then
		local var_70_4 = var_70_2:convertToWorldSpace(cc.p(0, 0))
		local var_70_5

		if arg_70_0.rentMenuType == var_0_18.RENT_PET then
			var_70_5 = var_70_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_70_5 = var_70_2:getChildByName("layout")
		end

		local var_70_6 = var_70_5:getChildByName("avatar_mask")
		local var_70_7 = var_70_5:getChildByName("chosen")

		var_70_6:setVisible(false)
		var_70_7:setVisible(false)
	end

	for iter_70_2 = #arg_70_0.petTeam_, var_70_3 + 1, -1 do
		local var_70_8 = arg_70_0.petTeam_[iter_70_2]
		local var_70_9, var_70_10 = arg_70_0:nodeByName("avatar_pet" .. iter_70_2 - 1):getPosition()

		transition.stopTarget(var_70_8)
		transition.moveTo(arg_70_0.petTeam_[iter_70_2], {
			time = 0.3,
			x = var_70_9,
			y = var_70_10
		})

		arg_70_0.petTeam_[iter_70_2].iniCell_.teamNo_ = iter_70_2 - 1
	end

	if arg_70_1.type == var_0_19.RENT_PET then
		arg_70_0.isSelectMerPet = false
		arg_70_0.selectMerPet = nil
	end

	table.remove(arg_70_0.petTeam_, var_70_3)
	table.remove(arg_70_0.petSelect_, var_70_3)

	if var_70_2 then
		var_70_2.teamNo_ = nil
	end

	if arg_70_1 and not tolua.isnull(arg_70_1) then
		arg_70_1:removeSelf()
	end

	if arg_70_2 then
		arg_70_2()
	end
end

function var_0_0.getTeamNo(arg_71_0, arg_71_1)
	for iter_71_0, iter_71_1 in ipairs(arg_71_0.team_) do
		if arg_71_1.data:getDistance() < iter_71_1.data:getDistance() then
			table.insert(arg_71_0.team_, iter_71_0, arg_71_1)
			table.insert(arg_71_0.select_, iter_71_0, arg_71_1.data)

			return iter_71_0
		end
	end

	table.insert(arg_71_0.team_, arg_71_1)
	table.insert(arg_71_0.select_, arg_71_1.data)

	return #arg_71_0.team_
end

function var_0_0.getPetTeamNo(arg_72_0, arg_72_1)
	table.insert(arg_72_0.petTeam_, arg_72_1)
	table.insert(arg_72_0.petSelect_, arg_72_1.data)

	return #arg_72_0.petTeam_
end

function var_0_0.widgetSet(arg_73_0, arg_73_1)
	for iter_73_0, iter_73_1 in ipairs(arg_73_1:getChildren()) do
		if iter_73_1 ~= nil then
			iter_73_1:setCascadeOpacityEnabled(true)
			arg_73_0:widgetSet(iter_73_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_74_0, arg_74_1, arg_74_2, arg_74_3, arg_74_4)
	arg_74_0:widgetSet(arg_74_3)
	arg_74_3:setCascadeOpacityEnabled(true)

	local var_74_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_74_1, arg_74_2)))

	arg_74_3:runActionOnce(var_74_0, true, arg_74_4)
end

function var_0_0.moveFadeInAction(arg_75_0, arg_75_1, arg_75_2, arg_75_3, arg_75_4)
	arg_75_0:widgetSet(arg_75_3)
	arg_75_3:setCascadeOpacityEnabled(true)
	arg_75_3:setOpacity(0)

	local var_75_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_75_1, arg_75_2)))

	arg_75_3:runActionOnce(var_75_0, false, arg_75_4)
end

function var_0_0.getBattlepetBtn(arg_76_0)
	if not arg_76_0.battlepetBtn_ then
		if arg_76_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE then
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_ok")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_77_0, arg_77_1)
				if #arg_76_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("BATTLE_NO_HERO")
					})

					return
				end

				if #arg_76_0.select_ > 0 and #arg_76_0.select_ < 5 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("REGION_ARENA_TIP48")
					})

					return
				end

				if arg_77_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_77_0 = 0

					if #arg_76_0.petTeam_ ~= 0 and not arg_76_0.isSelectMerPet then
						var_77_0 = arg_76_0.petTeam_[1].data:getPetID()
					end

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.REGION_ARENA_DEFENSE_UPDATE,
						params = {
							defenseHeroes = arg_76_0.select_,
							pet_id = var_77_0
						}
					})
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_76_0.type == xyd.SelectTeamType.TREASURE_DEFENSE then
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_ok")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_78_0, arg_78_1)
				local var_78_0 = {}

				for iter_78_0, iter_78_1 in pairs(arg_76_0.select_) do
					table.insert(var_78_0, iter_78_1:getHeroID())
				end

				if #arg_76_0.select_ < 1 or #var_78_0 < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_78_1 == ccui.TouchEventType.ended then
					xyd.Backend.get():request(xyd.mid.TREASURE_SET_PARTNER, {
						type = arg_76_0.treasureType,
						partners = var_78_0,
						team_id = arg_76_0.treasureTeamID
					}, function(arg_79_0, arg_79_1)
						return
					end)
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_76_0.type == xyd.SelectTeamType.INCUBUS then
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_ok")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_80_0, arg_80_1)
				if arg_80_1 == ccui.TouchEventType.ended then
					if #arg_76_0.select_ < 5 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_13:translation("INCUBUS_FIRST")
						})

						return
					end

					xyd.WindowManager.get():openWindow("incubus_select_team", {
						id = arg_76_0.campaignID,
						firstHeros = arg_76_0.select_
					})
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_76_0.type == xyd.SelectTeamType.ADJUST_TROOP then
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_ok")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_81_0, arg_81_1)
				if #arg_76_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_81_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_81_0 = {
						defenseHeroes = arg_76_0.select_,
						selectTeamId = arg_76_0.selectTeamId
					}

					if #arg_76_0.petTeam_ ~= 0 then
						var_81_0.pet_id = arg_76_0.petTeam_[1].data:getPetID()
					else
						var_81_0.pet_id = 0
					end

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.UPDATE_GUILD_TROOP,
						params = var_81_0
					})
					xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_76_0.type == xyd.SelectTeamType.HERO_PRESET then
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_ok")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_82_0, arg_82_1)
				if #arg_76_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("BATTLE_NO_HERO")
					})

					return
				elseif #arg_76_0.select_ < 5 then
					xyd.WindowManager.get():openWindow("toast", {
						message = string.format(var_0_13:translation("PRESET_TEAM_MEM_NOT_ENOUGH"), xyd.MAX_TEAM_MEMBER_NUM)
					})

					return
				end

				if arg_82_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					local var_82_0 = arg_76_0:getFormationStr(arg_76_0.select_)
					local var_82_1 = {
						formation = var_82_0,
						presetHeroType = arg_76_0.presetHeroType,
						presetHeroIndex = arg_76_0.presetHeroIndex,
						callback = function()
							if xyd.WindowManager.get():getWindow(xyd.WindowName.SelectTeamWnd) then
								xyd.WindowManager.get():closeWindow(xyd.WindowName.SelectTeamWnd)
							end
						end
					}

					xyd.WindowManager.get():openWindow("save_team", var_82_1)
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_battle"):setVisible(false)
		elseif arg_76_0.type == xyd.SelectTeamType.TWO_YEARS then
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_ok")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_84_0, arg_84_1)
				if #arg_76_0.select_ < 1 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_84_1 == ccui.TouchEventType.ended and not arg_76_0.battleBegan then
					xyd.playButtonSound()

					if xyd.WindowManager.get():isWindowOpen("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					if arg_76_0.selectMerHero and not arg_76_0.selectMerHero.have_rent then
						local var_84_0 = {
							hero = arg_76_0.selectMerHero,
							type = xyd.ConfirmRent.HERO
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_84_0)
					elseif arg_76_0.isSelectMerPet and arg_76_0.selectMerPet.can_rent then
						local var_84_1 = {
							hero = arg_76_0.selectMerPet,
							type = xyd.ConfirmRent.PET
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_84_1)
					else
						arg_76_0.battleBegan = true

						arg_76_0:startBattle()
					end
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_battle"):setVisible(false)
		else
			arg_76_0.battlepetBtn_ = arg_76_0:nodeByName("button_battle")

			arg_76_0.battlepetBtn_:addTouchEventListener(function(arg_85_0, arg_85_1)
				if not arg_76_0:checkCanStartBattle() then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_13:translation("BATTLE_NO_HERO")
					})

					return
				end

				if arg_85_1 == ccui.TouchEventType.ended and not arg_76_0.battleBegan then
					xyd.playButtonSound()

					if xyd.WindowManager.get():isWindowOpen("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					if arg_76_0.selectMerHero and not arg_76_0.selectMerHero.have_rent then
						local var_85_0 = {
							hero = arg_76_0.selectMerHero,
							type = xyd.ConfirmRent.HERO
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_85_0)
					elseif arg_76_0.isSelectMerPet and arg_76_0.selectMerPet.can_rent then
						local var_85_1 = {
							hero = arg_76_0.selectMerPet,
							type = xyd.ConfirmRent.PET
						}

						xyd.WindowManager.get():openWindow("confirm_rent", var_85_1)
					else
						arg_76_0.battleBegan = true

						arg_76_0:startBattle()
					end
				end
			end)
			arg_76_0.battlepetBtn_:setVisible(true)
			arg_76_0:nodeByName("button_ok"):setVisible(false)
		end
	end

	return arg_76_0.battlepetBtn_
end

function var_0_0.checkCanStartBattle(arg_86_0)
	if #arg_86_0.select_ < 1 then
		return false
	elseif #arg_86_0.select_ == 1 and (arg_86_0.select_[1]:getHeroID() < 0 or arg_86_0.isSelectMerHero) then
		return false
	end

	return true
end

function var_0_0.recordFormation(arg_87_0)
	if arg_87_0.isAwakeCampaign then
		for iter_87_0, iter_87_1 in pairs(arg_87_0.team_) do
			if iter_87_1.type == var_0_17.SELF_HERO and iter_87_1.data:getTableID() == arg_87_0.awakeHero:getTableID() then
				arg_87_0.isAwakeCampaign = true

				return
			else
				arg_87_0.isAwakeCampaign = false
			end
		end
	end

	local var_87_0 = arg_87_0.campaignType
	local var_87_1 = {}

	if var_87_0 == xyd.CampaignType.MARCH then
		for iter_87_2, iter_87_3 in pairs(arg_87_0.team_) do
			if iter_87_3.type == var_0_17.RENT_HERO then
				table.insert(var_87_1, -iter_87_3.data:getHeroID())
			else
				table.insert(var_87_1, iter_87_3.data:getHeroID())
			end
		end
	else
		for iter_87_4, iter_87_5 in ipairs(arg_87_0.team_) do
			if iter_87_5.type ~= var_0_17.RENT_HERO then
				table.insert(var_87_1, iter_87_5.data:getHeroID())
			end
		end
	end

	local var_87_2 = ""

	for iter_87_6, iter_87_7 in ipairs(var_87_1) do
		var_87_2 = var_87_2 .. string.format("%d|", iter_87_7)
	end

	if arg_87_0:isPet() and next(arg_87_0.petTeam_) then
		local var_87_3 = ""

		for iter_87_8, iter_87_9 in ipairs(arg_87_0.petTeam_) do
			if iter_87_9.type ~= var_0_19.RENT_PET then
				var_87_3 = var_87_3 .. string.format("%d|", iter_87_9.data:getPetID())
			end
		end

		var_87_2 = var_87_2 .. "," .. var_87_3
	end

	xyd.db.formation:setFormationData(var_87_0, var_87_2)
end

function var_0_0.startBattle(arg_88_0)
	if next(arg_88_0.team_) == nil then
		return
	end

	if arg_88_0.type == xyd.SelectTeamType.ADVANCED then
		arg_88_0:startMarchAdvance()
	elseif arg_88_0.type == xyd.SelectTeamType.REGION_ARENA then
		if next(arg_88_0.enemyHeroes_) == nil then
			return
		end

		arg_88_0:recordFormation()
		arg_88_0:startRegionArenaBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.MARCH then
		if next(arg_88_0.enemyHeroes_) == nil then
			return
		end

		arg_88_0:recordFormation()
		arg_88_0:startMarchBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.TREASURE then
		if next(arg_88_0.enemyHeroes_) == nil then
			return
		end

		arg_88_0:recordFormation()
		arg_88_0:startTreasureBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.GUILD then
		arg_88_0:recordFormation()
		arg_88_0:startGuildCampaignBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.WORLD_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startWorldBossBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.NIAN_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startNianBossBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.SAKURA_CAMPAIGN then
		arg_88_0:recordFormation()
		arg_88_0:startSakuraBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.PET then
		arg_88_0:recordFormation()
		arg_88_0:startPetBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.PET_PRACTICE then
		arg_88_0:startPetBattle(true)
	elseif arg_88_0.type == xyd.SelectTeamType.CHALLENGE then
		arg_88_0:recordFormation()
		arg_88_0:startChallengeBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.THIEF_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startThiefBossBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.ILLUSION then
		arg_88_0:recordFormation()
		arg_88_0:startIllusionBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.SINGLE_DAY then
		arg_88_0:startSingleDayBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.CONQUER_SCHOOL then
		arg_88_0:recordFormation()
		arg_88_0:startConquerSchoolBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.SAKURA2_COMPETITOR then
		arg_88_0:startSakura2CompetitorBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.SAKURA2_WAR then
		arg_88_0:startSakura2WarBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.STUDENT_OVER then
		arg_88_0:recordFormation()
		arg_88_0:startStudentBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		arg_88_0:recordFormation()
		arg_88_0:startZhugeNoteBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.ZHUGE_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startZhugeBossBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER then
		arg_88_0:recordFormation()
		arg_88_0:startMemoriesOfSchoolBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER then
		arg_88_0:recordFormation()
		arg_88_0:startMemoriesOfSchoolPVPBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.SUMMER_FIGHT_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startSummerFightBossBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.TWO_YEARS then
		arg_88_0:recordFormation()
		arg_88_0:startTwoYearsFight()
	elseif arg_88_0.type == xyd.SelectTeamType.ADVENTURE_BATTLE then
		arg_88_0:recordFormation()
		arg_88_0:startAdventureBattleFight()
	elseif arg_88_0.type == xyd.SelectTeamType.ADVENTURE_ILLUSION_SINGLE then
		arg_88_0:recordFormation()
		arg_88_0:startAdventureIllusionSingleFight()
	elseif arg_88_0.type == xyd.SelectTeamType.ADVENTURE_DEFENSE then
		arg_88_0:recordFormation()
		arg_88_0:startAdventureDefenseFight()
	elseif arg_88_0.type == xyd.SelectTeamType.CHAPTER_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startChapterBossFight()
	elseif arg_88_0.type == xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS then
		arg_88_0:recordFormation()
		arg_88_0:startThirdAnniversaryBossBattle()
	elseif arg_88_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		arg_88_0:recordFormation()
		arg_88_0:startSuperRichChallenge()
	elseif arg_88_0.type == xyd.SelectTeamType.CHOCOLATE then
		arg_88_0:recordFormation()
		arg_88_0:startChocolateFight()
	else
		arg_88_0:recordFormation()
		arg_88_0:startCampaignBattle()
	end
end

function var_0_0.startChocolateFight(arg_89_0)
	local var_89_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.CHOCOLATE)
	local var_89_1 = {}
	local var_89_2 = false
	local var_89_3 = {
		herosA = {},
		herosB = {}
	}
	local var_89_4 = {}

	for iter_89_0, iter_89_1 in ipairs(arg_89_0.team_) do
		local var_89_5 = iter_89_1.data

		table.insert(var_89_4, var_89_5)
		table.insert(var_89_3.herosA, var_89_5)

		local var_89_6 = arg_89_0.reinforcePartnerRatios[var_89_5:getTableID()]

		if var_89_6 and not var_89_5.reinforceRatio then
			var_89_5.reinforceRatio = var_89_6

			local var_89_7 = var_89_5.getTotalAttr

			function var_89_5.getTotalAttr(arg_90_0, arg_90_1)
				local var_90_0 = var_89_7(arg_90_0, arg_90_1)

				if var_89_5.reinforceRatio and (arg_90_1 == xyd.AttributeType.HP or arg_90_1 == xyd.AttributeType.AD or arg_90_1 == xyd.AttributeType.AP) then
					return var_90_0 + var_90_0 * var_89_5.reinforceRatio
				else
					return var_90_0
				end
			end
		end
	end

	var_89_3.petsA = {}

	for iter_89_2, iter_89_3 in ipairs(arg_89_0.petSelect_) do
		table.insert(var_89_3.petsA, iter_89_3)
	end

	var_89_3.campaignType = xyd.CampaignType.CHOCOLATE
	var_89_3.campaignID = arg_89_0.campaignID
	var_89_3.battleID = arg_89_0.battleID
	var_89_3.stories = arg_89_0.stories
	var_89_3.rentFlag = var_89_2
	var_89_3.formation = arg_89_0:getFormationStr(var_89_3.herosA)

	local var_89_8 = xyd.tables.battle:monsters(var_89_3.battleID)

	var_89_3.herosB = {}

	for iter_89_4, iter_89_5 in ipairs(var_89_8) do
		local var_89_9 = {}

		for iter_89_6, iter_89_7 in ipairs(var_89_8[iter_89_4]) do
			local var_89_10 = var_0_1.new()

			var_89_10:populateWithTableID(iter_89_7)
			table.insert(var_89_9, var_89_10)
		end

		table.insert(var_89_3.herosB, var_89_9)
	end

	local var_89_11 = {
		campaign_id = arg_89_0.campaignID,
		formation = arg_89_0:getFormationStr(var_89_4)
	}
	local var_89_12

	if #arg_89_0.petTeam_ ~= 0 and not arg_89_0.isSelectMerPet then
		var_89_12 = arg_89_0.petTeam_[1].data:getPetID()
	end

	var_89_11.pet_id = var_89_12

	if arg_89_0.isSelectMerPet then
		var_89_3.rent_pet_id = arg_89_0.selectMerPet:getPetID()
	end

	if arg_89_0.selectMerPet then
		var_89_11.rent_pet_player = arg_89_0.selectMerPet.player_id
		var_89_11.rent_pet = tostring(arg_89_0.selectMerPet:getPetID())
	end

	if arg_89_0.selectMerHero then
		var_89_11.rent_hero_player = arg_89_0.selectMerHero.player_id
		var_89_11.rent_hero = tostring(arg_89_0.selectMerHero:getHeroID())
	end

	var_89_3.fightParams = var_89_11

	xyd.Backend.get():request(xyd.mid.CHOCOLATE_START_FIGHT, var_89_11, function(arg_91_0, arg_91_1)
		if arg_91_0 == xyd.error.OK then
			if arg_89_0.selectMerHero then
				arg_89_0.guild:setUseRent(arg_89_0.selectMerHero)
			end

			if arg_89_0.selectMerPet then
				arg_89_0.guild:setUseRentPet(arg_89_0.selectMerPet)
			end

			var_89_3.petsA = {}

			for iter_91_0, iter_91_1 in ipairs(arg_89_0.petSelect_) do
				table.insert(var_89_3.petsA, iter_91_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "chocolate_map"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_89_3)
		else
			arg_89_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startSuperRichChallenge(arg_92_0)
	local var_92_0 = false
	local var_92_1 = {
		herosA = {},
		herosB = {}
	}
	local var_92_2 = {}

	for iter_92_0, iter_92_1 in ipairs(arg_92_0.team_) do
		iter_92_1.data.type = iter_92_1.type

		table.insert(var_92_2, iter_92_1.data)
		table.insert(var_92_1.herosA, iter_92_1.data)
	end

	var_92_1.petsA = {}

	for iter_92_2, iter_92_3 in ipairs(arg_92_0.petSelect_) do
		table.insert(var_92_1.petsA, iter_92_3)
	end

	var_92_1.campaignType = xyd.CampaignType.SUPER_RICH_CHALLENGE
	var_92_1.campaignID = arg_92_0.campaignID
	var_92_1.battleID = arg_92_0.battleID

	local var_92_3 = arg_92_0:getFormationStr(var_92_2)

	var_92_1.fightParams = {
		campaign_id = var_92_1.campaignID,
		formation = var_92_3
	}

	local var_92_4 = xyd.tables.battle:monsters(arg_92_0.battleID)

	var_92_1.herosB = {}

	local var_92_5 = {}

	for iter_92_4, iter_92_5 in ipairs(var_92_4[1]) do
		local var_92_6 = var_0_1.new()

		var_92_6:populateWithTableID(iter_92_5)
		table.insert(var_92_5, var_92_6)
	end

	table.insert(var_92_1.herosB, var_92_5)

	function var_92_1.callback(arg_93_0)
		if arg_93_0 then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "super_rich_challenge"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_92_1)
		else
			arg_92_0.battleBegan = false
		end
	end

	xyd.WindowManager.get():openWindow("super_rich_challenge_formation", var_92_1)
end

function var_0_0.startAdventureDefenseFight(arg_94_0)
	local var_94_0 = {
		campaignType = arg_94_0.campaignType,
		campaignID = arg_94_0.campaignID,
		battleID = arg_94_0.battleID,
		monster_pos = arg_94_0.monsterPos,
		herosA = {}
	}
	local var_94_1 = {}
	local var_94_2 = false

	for iter_94_0, iter_94_1 in ipairs(arg_94_0.team_) do
		iter_94_1.data.type = iter_94_1.type

		if iter_94_1.type == var_0_17.RENT_HERO then
			var_94_2 = true
		else
			table.insert(var_94_1, iter_94_1.data)
		end

		table.insert(var_94_0.herosA, iter_94_1.data)
	end

	var_94_0.rentFlag = var_94_2
	var_94_0.formation = arg_94_0:getFormationStr(var_94_0.herosA)

	local var_94_3 = xyd.tables.battle:monsters(var_94_0.battleID)

	var_94_0.herosB = {}

	local var_94_4 = {}

	for iter_94_2, iter_94_3 in ipairs(var_94_3[1]) do
		local var_94_5 = var_0_1.new()

		var_94_5:populateWithTableID(iter_94_3)
		table.insert(var_94_4, var_94_5)
	end

	table.insert(var_94_0.herosB, var_94_4)

	local var_94_6 = {
		formation = arg_94_0:getFormationStr(var_94_1)
	}
	local var_94_7

	if #arg_94_0.petTeam_ ~= 0 and not arg_94_0.isSelectMerPet then
		var_94_7 = arg_94_0.petTeam_[1].data:getPetID()
	end

	var_94_6.pet_id = var_94_7

	if arg_94_0.isSelectMerPet then
		var_94_0.rent_pet_id = arg_94_0.selectMerPet:getPetID()
	end

	if arg_94_0.selectMerPet then
		var_94_6.rent_pet_player_id = arg_94_0.selectMerPet.player_id
		var_94_6.rent_pet_id = tostring(arg_94_0.selectMerPet:getPetID())
	end

	if arg_94_0.selectMerHero then
		var_94_6.rent_player_id = arg_94_0.selectMerHero.player_id
		var_94_6.rent_formation = tostring(arg_94_0.selectMerHero:getHeroID())
	end

	var_94_0.fightParams = var_94_6
	var_94_6.monster_pos = arg_94_0.monsterPos
	var_94_6.table_id = xyd.AdventureEventType.DEFENSE

	xyd.Backend.get():request(xyd.mid.ADVENTURE_DEFENSE_START_ROOM_FIGHT, var_94_6, function(arg_95_0, arg_95_1)
		if arg_95_0 == xyd.error.OK then
			if arg_94_0.selectMerHero then
				arg_94_0.guild:setUseRent(arg_94_0.selectMerHero)
			end

			if arg_94_0.selectMerPet then
				arg_94_0.guild:setUseRentPet(arg_94_0.selectMerPet)
			end

			var_94_0.petsA = {}

			for iter_95_0, iter_95_1 in ipairs(arg_94_0.petSelect_) do
				table.insert(var_94_0.petsA, iter_95_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "adventure_defense"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_94_0)
		else
			arg_94_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startAdventureBattleFight(arg_96_0)
	local var_96_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
	local var_96_1 = {}
	local var_96_2 = {}

	for iter_96_0, iter_96_1 in ipairs(arg_96_0.team_) do
		table.insert(var_96_2, iter_96_1.data)
	end

	var_96_1.formation = arg_96_0:getFormationStr(var_96_2)

	if #arg_96_0.petTeam_ ~= 0 then
		var_96_1.pet_id = arg_96_0.petTeam_[1].data:getPetID()
	end

	var_96_0:startAdventureBattleFight(var_96_1, function(arg_97_0, arg_97_1)
		if arg_97_0 == xyd.error.OK then
			local var_97_0 = {}

			ngx.ctx.battle.reportData = json.decode(arg_97_1.battle_report)
			var_97_0.herosA = {}
			var_97_0.herosB = {}
			var_97_0.summonMonsters = {}
			var_97_0.battleType = xyd.BattleType.ReplayReport
			var_97_0.battleID = xyd.MapBattleID.ARENA
			var_97_0.campaignType = arg_96_0.campaignType

			local var_97_1 = {}
			local var_97_2 = {}

			for iter_97_0, iter_97_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_97_3 = string.sub(iter_97_0, 1, 1)
				local var_97_4 = tonumber(string.sub(iter_97_0, 3, 3))

				if var_97_3 == "A" and tonumber(iter_97_1.summon_type) == xyd.summonMonsterType.None then
					local var_97_5 = var_0_1.new()

					var_97_5:populate(iter_97_1.hero)
					var_97_5:setReportData(iter_97_1)

					var_97_0.herosA[var_97_4] = var_97_5
				elseif var_97_3 == "A" and tonumber(iter_97_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_97_6 = var_0_2.new()

					var_97_6:populate(iter_97_1.hero)
					var_97_6:setReportData(iter_97_1)

					var_97_0.petsA = {
						var_97_6
					}
				elseif var_97_3 == "B" and tonumber(iter_97_1.summon_type) == xyd.summonMonsterType.None then
					local var_97_7 = var_0_1.new()

					var_97_7:populate(iter_97_1.hero)
					var_97_7:setReportData(iter_97_1)

					var_97_1[var_97_4] = var_97_7
				elseif var_97_3 == "B" and tonumber(iter_97_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_97_8 = var_0_2.new()

					var_97_8:populate(iter_97_1.hero)
					var_97_8:setReportData(iter_97_1)

					var_97_0.petsB = {
						var_97_8
					}
				elseif tonumber(iter_97_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_97_9 = var_0_1.new()

					var_97_9:populate(iter_97_1.hero)
					var_97_9:setReportData(iter_97_1)

					var_97_2[iter_97_0] = var_97_9
				end
			end

			var_97_0.reportStar = ngx.ctx.battle.reportData.star
			var_97_0.herosB = {
				var_97_1
			}
			var_97_0.summonMonsters = var_97_2

			local var_97_10 = arg_97_1.is_win

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "adventure_event"
				}
			})
			xyd.WindowManager.get():retainHistory()

			var_97_0.awards = arg_97_1.awards

			xyd.pushBattleScene(var_97_0)
		end
	end)
end

function var_0_0.startTwoYearsFight(arg_98_0)
	local var_98_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	local var_98_1 = {
		campaign_id = arg_98_0.campaignID
	}
	local var_98_2 = {}

	for iter_98_0, iter_98_1 in ipairs(arg_98_0.team_) do
		iter_98_1.data.type = iter_98_1.type

		table.insert(var_98_2, iter_98_1.data:getTableID())
	end

	var_98_1.formation = var_98_2

	local var_98_3

	if #arg_98_0.petTeam_ ~= 0 and not arg_98_0.isSelectMerPet then
		var_98_3 = arg_98_0.petTeam_[1].data:getPetID()
	end

	var_98_1.pet_id = var_98_3

	var_98_0:anniStartFight(var_98_1, function(arg_99_0, arg_99_1)
		if arg_99_0 == xyd.error.OK then
			local var_99_0 = {}
			local var_99_1 = var_98_0:getTempEnemiesInfo()
			local var_99_2 = var_98_0:getSelfHeroesInfo()

			ngx.ctx.battle.reportData = json.decode(arg_99_1.battle_report)
			var_99_0.herosA = {}
			var_99_0.herosB = {}
			var_99_0.summonMonsters = {}
			var_99_0.battleType = xyd.BattleType.ReplayReport
			var_99_0.battleID = xyd.MapBattleID.ARENA
			var_99_0.campaignType = arg_98_0.campaignType

			local var_99_3 = {}
			local var_99_4 = {}

			for iter_99_0, iter_99_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_99_5 = string.sub(iter_99_0, 1, 1)
				local var_99_6 = tonumber(string.sub(iter_99_0, 3, 3))

				if var_99_5 == "A" and tonumber(iter_99_1.summon_type) == xyd.summonMonsterType.None then
					local var_99_7 = var_0_1.new()

					var_99_7:populate(iter_99_1.hero)

					local var_99_8

					if var_99_2[tostring(var_99_7:getHeroID())] then
						var_99_8 = {}
						var_99_8.health = 1
						var_99_8.hp = var_99_2[tostring(var_99_7:getHeroID())].hp
						var_99_8.mp = var_99_2[tostring(var_99_7:getHeroID())].mp
						var_99_8.is_reborn = var_99_2[tostring(var_99_7:getHeroID())].is_reborn
					end

					var_99_7.healthStatus = var_99_8

					var_99_7:setReportData(iter_99_1)

					var_99_0.herosA[var_99_6] = var_99_7
				elseif var_99_5 == "A" and tonumber(iter_99_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_99_9 = var_0_2.new()

					var_99_9:populate(iter_99_1.hero)
					var_99_9:setReportData(iter_99_1)

					var_99_0.petsA = {
						var_99_9
					}
				elseif var_99_5 == "B" and tonumber(iter_99_1.summon_type) == xyd.summonMonsterType.None then
					local var_99_10 = var_0_1.new()

					var_99_10:populate(iter_99_1.hero)

					local var_99_11

					if var_99_1[tostring(var_99_10:getTableID())] then
						var_99_11 = {}
						var_99_11.health = 1
						var_99_11.hp = var_99_1[tostring(var_99_10:getTableID())].hp
						var_99_11.mp = var_99_1[tostring(var_99_10:getTableID())].mp
						var_99_11.is_reborn = var_99_1[tostring(var_99_10:getTableID())].is_reborn
					end

					var_99_10.healthStatus = var_99_11

					var_99_10:setReportData(iter_99_1)

					var_99_3[var_99_6] = var_99_10
				elseif var_99_5 == "B" and tonumber(iter_99_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_99_12 = var_0_2.new()

					var_99_12:populate(iter_99_1.hero)
					var_99_12:setReportData(iter_99_1)

					var_99_0.petsB = {
						var_99_12
					}
				elseif tonumber(iter_99_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_99_13 = var_0_1.new()

					var_99_13:populate(iter_99_1.hero)
					var_99_13:setReportData(iter_99_1)

					var_99_4[iter_99_0] = var_99_13
				end
			end

			var_99_0.reportStar = ngx.ctx.battle.reportData.star
			var_99_0.herosB = {
				var_99_3
			}
			var_99_0.summonMonsters = var_99_4

			local var_99_14 = arg_99_1.is_win
			local var_99_15 = {}

			if arg_99_1.awards then
				var_99_0.twoYearsAwards = arg_99_1.awards
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "two_years_main"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_99_0)
		end
	end)
end

function var_0_0.startMemoriesOfSchoolBattle(arg_100_0)
	arg_100_0.memoriesOfSchool:startFight({
		grid_pos = arg_100_0.memoriesOfSchool:getBattleGrid()
	}, function(arg_101_0, arg_101_1)
		if arg_101_0 == xyd.error.OK then
			local var_101_0 = false
			local var_101_1 = {
				herosA = {},
				herosB = {}
			}
			local var_101_2 = {}

			for iter_101_0, iter_101_1 in ipairs(arg_100_0.team_) do
				iter_101_1.data.type = iter_101_1.type

				if iter_101_1.type == var_0_17.RENT_HERO then
					var_101_0 = true
				else
					table.insert(var_101_2, iter_101_1.data)
				end

				table.insert(var_101_1.herosA, iter_101_1.data)
			end

			var_101_1.rentFlag = var_101_0
			var_101_1.campaignType = arg_100_0.campaignType
			var_101_1.campaignID = arg_100_0.campaignID
			var_101_1.battleID = arg_100_0.battleID

			local var_101_3 = arg_100_0:getFormationStr(var_101_2)
			local var_101_4 = {
				campaign_id = var_101_1.campaignID,
				formation = var_101_3
			}

			if arg_100_0.selectMerHero then
				var_101_4.rent_player_id = arg_100_0.selectMerHero.player_id
				var_101_4.rent_formation = tostring(arg_100_0.selectMerHero:getHeroID())
			end

			var_101_1.fightParams = var_101_4
			var_101_1.formation = var_101_3

			local var_101_5

			if #arg_100_0.petTeam_ ~= 0 and not arg_100_0.isSelectMerPet then
				var_101_5 = arg_100_0.petTeam_[1].data:getPetID()
			end

			var_101_4.pet_id = var_101_5
			var_101_1.pet_id = var_101_5
			var_101_1.petsA = {}

			for iter_101_2, iter_101_3 in ipairs(arg_100_0.petSelect_) do
				table.insert(var_101_1.petsA, iter_101_3)
			end

			local var_101_6 = xyd.tables.battle:monsters(var_101_1.battleID)
			local var_101_7, var_101_8 = arg_100_0.memoriesOfSchool:getTempEnemiesInfo()

			var_101_1.currentGroup = tonumber(var_101_8)
			var_101_1.herosB = {}

			for iter_101_4 = 1, #var_101_6 do
				local var_101_9 = {}

				for iter_101_5, iter_101_6 in ipairs(var_101_6[iter_101_4]) do
					local var_101_10 = var_0_1.new()

					var_101_10:populateWithTableID(iter_101_6)

					if var_101_7[tostring(iter_101_6)] then
						local var_101_11 = {}

						var_101_11.health = 1
						var_101_11.hp = var_101_7[tostring(iter_101_6)].hp
						var_101_11.is_reborn = var_101_7[tostring(iter_101_6)].is_reborn
						var_101_11.mp = var_101_7[tostring(iter_101_6)].mp
						var_101_10.healthStatus = var_101_11
					end

					table.insert(var_101_9, var_101_10)
				end

				if #var_101_9 ~= 0 then
					table.insert(var_101_1.herosB, var_101_9)
				end
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "memories_of_school"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_101_1)
		else
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("MEMROIES_OF_SCHOOL_ENERGY_NOT_ENOUGH")
			})
		end
	end)
end

function var_0_0.startMemoriesOfSchoolPVPBattle(arg_102_0)
	local var_102_0 = false
	local var_102_1 = {
		herosA = {},
		herosB = {}
	}
	local var_102_2 = {}

	for iter_102_0, iter_102_1 in ipairs(arg_102_0.team_) do
		iter_102_1.data.type = iter_102_1.type

		if iter_102_1.type == var_0_17.RENT_HERO then
			var_102_0 = true
		else
			table.insert(var_102_2, iter_102_1.data)
		end

		table.insert(var_102_1.herosA, iter_102_1.data)
	end

	var_102_1.rentFlag = var_102_0
	var_102_1.campaignType = arg_102_0.campaignType
	var_102_1.campaignID = arg_102_0.campaignID
	var_102_1.battleID = arg_102_0.battleID

	local var_102_3 = arg_102_0:getFormationStr(var_102_2)
	local var_102_4 = {
		campaign_id = var_102_1.campaignID,
		formation = var_102_3
	}

	if arg_102_0.selectMerHero then
		var_102_4.rent_player_id = arg_102_0.selectMerHero.player_id
		var_102_4.rent_formation = tostring(arg_102_0.selectMerHero:getHeroID())
	end

	var_102_1.fightParams = var_102_4
	var_102_1.formation = var_102_3
	var_102_1.herosB = {}

	local var_102_5

	if #arg_102_0.petTeam_ ~= 0 and not arg_102_0.isSelectMerPet then
		var_102_5 = arg_102_0.petTeam_[1].data:getPetID()
	end

	arg_102_0.memoriesOfSchool:fightPlayer({
		grid_pos = arg_102_0.memoriesOfSchool:getBattleGrid(),
		formation = var_102_3,
		pet_id = var_102_5
	}, function(arg_103_0, arg_103_1)
		if arg_103_0 == xyd.error.OK then
			local var_103_0 = {}
			local var_103_1, var_103_2 = arg_102_0.memoriesOfSchool:getTempEnemiesInfo()

			ngx.ctx.battle.reportData = json.decode(arg_103_1.battle_info.battle_report)
			var_103_0.herosA = {}
			var_103_0.herosB = {}
			var_103_0.summonMonsters = {}
			var_103_0.battleType = xyd.BattleType.ReplayReport
			var_103_0.battleID = xyd.MapBattleID.ARENA
			var_103_0.campaignType = arg_102_0.campaignType

			local var_103_3 = {}
			local var_103_4 = {}

			for iter_103_0, iter_103_1 in pairs(ngx.ctx.battle.reportData.fighter) do
				local var_103_5 = string.sub(iter_103_0, 1, 1)
				local var_103_6 = tonumber(string.sub(iter_103_0, 3, 3))

				if var_103_5 == "A" and tonumber(iter_103_1.summon_type) == xyd.summonMonsterType.None then
					local var_103_7 = var_0_1.new()

					var_103_7:populate(iter_103_1.hero)
					var_103_7:setReportData(iter_103_1)

					var_103_0.herosA[var_103_6] = var_103_7
				elseif var_103_5 == "A" and tonumber(iter_103_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_103_8 = var_0_2.new()

					var_103_8:populate(iter_103_1.hero)
					var_103_8:setReportData(iter_103_1)

					var_103_0.petsA = {
						var_103_8
					}
				elseif var_103_5 == "B" and tonumber(iter_103_1.summon_type) == xyd.summonMonsterType.None then
					local var_103_9 = var_0_1.new()

					var_103_9:populate(iter_103_1.hero)

					local var_103_10

					if var_103_1[tostring(var_103_9:getHeroID())] then
						var_103_10 = {}
						var_103_10.health = 1
						var_103_10.hp = var_103_1[tostring(var_103_9:getHeroID())].hp
						var_103_10.mp = var_103_1[tostring(var_103_9:getHeroID())].mp
						var_103_10.is_reborn = var_103_1[tostring(var_103_9:getHeroID())].is_reborn
					end

					var_103_9.healthStatus = var_103_10

					var_103_9:setReportData(iter_103_1)

					var_103_3[var_103_6] = var_103_9
				elseif var_103_5 == "B" and tonumber(iter_103_1.summon_type) == xyd.summonMonsterType.Pet then
					local var_103_11 = var_0_2.new()

					var_103_11:populate(iter_103_1.hero)
					var_103_11:setReportData(iter_103_1)

					var_103_0.petsB = {
						var_103_11
					}
				elseif tonumber(iter_103_1.summon_type) ~= xyd.summonMonsterType.None then
					local var_103_12 = var_0_1.new()

					var_103_12:populate(iter_103_1.hero)
					var_103_12:setReportData(iter_103_1)

					var_103_4[iter_103_0] = var_103_12
				end
			end

			var_103_0.reportStar = ngx.ctx.battle.reportData.star
			var_103_0.herosB = {
				var_103_3
			}
			var_103_0.summonMonsters = var_103_4

			local var_103_13 = 0

			if arg_103_1.battle_info.star > 0 then
				var_103_13 = 1
			end

			local var_103_14 = var_103_13
			local var_103_15 = {}

			if arg_103_1.battle_info.library_mission_formations.partner_favor then
				for iter_103_2, iter_103_3 in pairs(arg_103_1.battle_info.library_mission_formations.partner_favor) do
					if iter_103_3 > arg_102_0.selfPlayer:getHero(tonumber(iter_103_2)):getFavorDegree() then
						var_103_15[tonumber(iter_103_2)] = true

						arg_102_0.selfPlayer:getHero(tonumber(iter_103_2)):setFavorDegree(iter_103_3)
					end
				end

				var_103_0.favorDegreeUp = var_103_15
			end

			if arg_103_1.awards then
				var_103_0.memories_awards = arg_103_1.awards
			end

			var_103_0.pvp = 1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "memories_of_school"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_103_0)
		end
	end)
end

function var_0_0.startNianBossBattle(arg_104_0)
	local var_104_0 = false
	local var_104_1 = {
		herosA = {},
		herosB = {}
	}
	local var_104_2 = {}

	for iter_104_0, iter_104_1 in ipairs(arg_104_0.team_) do
		iter_104_1.data.type = iter_104_1.type

		if iter_104_1.type == var_0_17.RENT_HERO then
			var_104_0 = true
		else
			table.insert(var_104_2, iter_104_1.data)
		end

		table.insert(var_104_1.herosA, iter_104_1.data)
	end

	var_104_1.rentFlag = var_104_0
	var_104_1.campaignType = arg_104_0.campaignType
	var_104_1.campaignID = arg_104_0.campaignID
	var_104_1.battleID = xyd.tables.nianBoss.fight_id[arg_104_0.campaignID]

	local var_104_3 = arg_104_0:getFormationStr(var_104_2)
	local var_104_4 = {
		campaign_id = var_104_1.campaignID,
		formation = var_104_3
	}

	if arg_104_0.selectMerHero then
		var_104_4.rent_player_id = arg_104_0.selectMerHero.player_id
		var_104_4.rent_formation = tostring(arg_104_0.selectMerHero:getHeroID())
	end

	var_104_1.fightParams = var_104_4

	local var_104_5 = xyd.tables.battle:monsters(var_104_1.battleID)

	var_104_1.herosB = {}

	for iter_104_2 = 1, #var_104_5 do
		local var_104_6 = {}

		for iter_104_3, iter_104_4 in ipairs(var_104_5[iter_104_2]) do
			local var_104_7 = var_0_1.new()

			var_104_7:populateWithTableID(iter_104_4)
			table.insert(var_104_6, var_104_7)
		end

		table.insert(var_104_1.herosB, var_104_6)
	end

	xyd.Backend.get():request(xyd.mid.NIAN_BOSS_START_FIGHT, var_104_4, function(arg_105_0, arg_105_1)
		if arg_105_0 == xyd.error.OK then
			if arg_104_0.selectMerHero then
				arg_104_0.guild:setUseRent(arg_104_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "nian_boss_battle_pre"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_104_1)
		else
			arg_104_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startThiefBossBattle(arg_106_0)
	local var_106_0 = false
	local var_106_1 = {
		herosA = {},
		herosB = {}
	}
	local var_106_2 = {}

	for iter_106_0, iter_106_1 in ipairs(arg_106_0.team_) do
		iter_106_1.data.type = iter_106_1.type

		if iter_106_1.type == var_0_17.RENT_HERO then
			var_106_0 = true
		else
			table.insert(var_106_2, iter_106_1.data)
		end

		table.insert(var_106_1.herosA, iter_106_1.data)
	end

	var_106_1.rentFlag = var_106_0
	var_106_1.campaignType = arg_106_0.campaignType
	var_106_1.campaignID = arg_106_0.campaignID
	var_106_1.battleID = xyd.tables.nianBoss.fight_id[arg_106_0.campaignID]

	local var_106_3 = arg_106_0:getFormationStr(var_106_2)
	local var_106_4 = {
		campaign_id = var_106_1.campaignID,
		formation = var_106_3
	}

	if arg_106_0.selectMerHero then
		var_106_4.rent_player_id = arg_106_0.selectMerHero.player_id
		var_106_4.rent_formation = tostring(arg_106_0.selectMerHero:getHeroID())
	end

	var_106_1.fightParams = var_106_4

	local var_106_5 = xyd.tables.battle:monsters(var_106_1.battleID)

	var_106_1.herosB = {}

	for iter_106_2 = 1, #var_106_5 do
		local var_106_6 = {}

		for iter_106_3, iter_106_4 in ipairs(var_106_5[iter_106_2]) do
			local var_106_7 = var_0_1.new()

			var_106_7:populateWithTableID(iter_106_4)
			table.insert(var_106_6, var_106_7)
		end

		table.insert(var_106_1.herosB, var_106_6)
	end

	xyd.Backend.get():request(xyd.mid.NIAN_BOSS_START_FIGHT, var_106_4, function(arg_107_0, arg_107_1)
		if arg_107_0 == xyd.error.OK then
			if arg_106_0.selectMerHero then
				arg_106_0.guild:setUseRent(arg_106_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "thief_boss_battle_pre"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_106_1)
		else
			arg_106_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startSingleDayBattle(arg_108_0)
	local var_108_0 = false
	local var_108_1 = {
		missionID = arg_108_0.missionID,
		herosA = {},
		herosB = {}
	}
	local var_108_2 = {}

	for iter_108_0, iter_108_1 in ipairs(arg_108_0.team_) do
		iter_108_1.data.type = iter_108_1.type

		if iter_108_1.type == var_0_17.RENT_HERO then
			var_108_0 = true
		else
			table.insert(var_108_2, iter_108_1.data)
		end

		table.insert(var_108_1.herosA, iter_108_1.data)
	end

	var_108_1.rentFlag = var_108_0
	var_108_1.campaignType = arg_108_0.campaignType
	var_108_1.campaignID = arg_108_0.campaignID
	var_108_1.battleID = arg_108_0.battleID

	local var_108_3 = arg_108_0:getFormationStr(var_108_2)
	local var_108_4 = {
		campaign_id = var_108_1.campaignID,
		formation = var_108_3
	}

	if arg_108_0.selectMerHero then
		var_108_4.rent_player_id = arg_108_0.selectMerHero.player_id
		var_108_4.rent_formation = tostring(arg_108_0.selectMerHero:getHeroID())
	end

	var_108_1.fightParams = var_108_4

	local var_108_5 = xyd.tables.battle:monsters(var_108_1.battleID)

	var_108_1.herosB = {}

	for iter_108_2 = 1, 1 do
		local var_108_6 = {}

		for iter_108_3, iter_108_4 in ipairs(var_108_5[iter_108_2]) do
			local var_108_7 = var_0_1.new()

			var_108_7:populateWithTableID(iter_108_4)
			table.insert(var_108_6, var_108_7)
		end

		table.insert(var_108_1.herosB, var_108_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "single_day"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_108_1)
end

function var_0_0.startAdventureIllusionSingleFight(arg_109_0)
	local var_109_0 = {
		campaignType = arg_109_0.campaignType,
		campaignID = arg_109_0.campaignID,
		battleID = xyd.tables.illusionCampaign:fightId(arg_109_0.campaignID),
		herosA = {}
	}
	local var_109_1 = {}
	local var_109_2 = false

	for iter_109_0, iter_109_1 in ipairs(arg_109_0.team_) do
		iter_109_1.data.type = iter_109_1.type

		if iter_109_1.type == var_0_17.RENT_HERO then
			var_109_2 = true
		else
			table.insert(var_109_1, iter_109_1.data)
		end

		table.insert(var_109_0.herosA, iter_109_1.data)
	end

	var_109_0.rentFlag = var_109_2

	local var_109_3 = xyd.tables.battle:monsters(var_109_0.battleID)

	var_109_0.herosB = {}

	local var_109_4 = {}

	for iter_109_2, iter_109_3 in ipairs(var_109_3[1]) do
		local var_109_5 = var_0_1.new()

		var_109_5:populateWithTableID(iter_109_3)
		table.insert(var_109_4, var_109_5)
	end

	table.insert(var_109_0.herosB, var_109_4)

	local var_109_6 = {
		formation = arg_109_0:getFormationStr(var_109_1)
	}
	local var_109_7

	if #arg_109_0.petTeam_ ~= 0 and not arg_109_0.isSelectMerPet then
		var_109_7 = arg_109_0.petTeam_[1].data:getPetID()
	end

	var_109_6.pet_id = var_109_7

	if arg_109_0.isSelectMerPet then
		var_109_0.rent_pet_id = arg_109_0.selectMerPet:getPetID()
	end

	if arg_109_0.selectMerPet then
		var_109_6.rent_pet_player_id = arg_109_0.selectMerPet.player_id
		var_109_6.rent_pet_id = tostring(arg_109_0.selectMerPet:getPetID())
	end

	if arg_109_0.selectMerHero then
		var_109_6.rent_player_id = arg_109_0.selectMerHero.player_id
		var_109_6.rent_formation = tostring(arg_109_0.selectMerHero:getHeroID())
	end

	var_109_0.fightParams = var_109_6

	xyd.Backend.get():request(xyd.mid.START_PARADISE_FIGHT, var_109_6, function(arg_110_0, arg_110_1)
		if arg_110_0 == xyd.error.OK then
			if arg_109_0.selectMerHero then
				arg_109_0.guild:setUseRent(arg_109_0.selectMerHero)
			end

			if arg_109_0.selectMerPet then
				arg_109_0.guild:setUseRentPet(arg_109_0.selectMerPet)
			end

			var_109_0.petsA = {}

			for iter_110_0, iter_110_1 in ipairs(arg_109_0.petSelect_) do
				table.insert(var_109_0.petsA, iter_110_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "adventure_event"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_109_0)
		else
			arg_109_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startIllusionBattle(arg_111_0)
	local var_111_0 = {
		campaignType = arg_111_0.campaignType,
		campaignID = arg_111_0.campaignID,
		battleID = xyd.tables.illusionCampaign:fightId(arg_111_0.campaignID),
		herosA = {}
	}
	local var_111_1 = {}
	local var_111_2 = false

	for iter_111_0, iter_111_1 in ipairs(arg_111_0.team_) do
		iter_111_1.data.type = iter_111_1.type

		if iter_111_1.type == var_0_17.RENT_HERO then
			var_111_2 = true
		else
			table.insert(var_111_1, iter_111_1.data)
		end

		table.insert(var_111_0.herosA, iter_111_1.data)
	end

	var_111_0.rentFlag = var_111_2

	local var_111_3 = xyd.tables.battle:monsters(var_111_0.battleID)

	var_111_0.herosB = {}

	local var_111_4 = {}

	for iter_111_2, iter_111_3 in ipairs(var_111_3[1]) do
		local var_111_5 = var_0_1.new()

		var_111_5:populateWithTableID(iter_111_3)
		table.insert(var_111_4, var_111_5)
	end

	table.insert(var_111_0.herosB, var_111_4)

	local var_111_6 = {
		formation = arg_111_0:getFormationStr(var_111_1)
	}
	local var_111_7

	if #arg_111_0.petTeam_ ~= 0 and not arg_111_0.isSelectMerPet then
		var_111_7 = arg_111_0.petTeam_[1].data:getPetID()
	end

	var_111_6.pet_id = var_111_7

	if arg_111_0.isSelectMerPet then
		var_111_0.rent_pet_id = arg_111_0.selectMerPet:getPetID()
	end

	if arg_111_0.selectMerPet then
		var_111_6.rent_pet_player_id = arg_111_0.selectMerPet.player_id
		var_111_6.rent_pet_id = tostring(arg_111_0.selectMerPet:getPetID())
	end

	if arg_111_0.selectMerHero then
		var_111_6.rent_player_id = arg_111_0.selectMerHero.player_id
		var_111_6.rent_formation = tostring(arg_111_0.selectMerHero:getHeroID())
	end

	var_111_0.fightParams = var_111_6

	xyd.Backend.get():request(xyd.mid.ILLUSION_START_FIGHT, var_111_6, function(arg_112_0, arg_112_1)
		if arg_112_0 == xyd.error.OK then
			if arg_111_0.selectMerHero then
				arg_111_0.guild:setUseRent(arg_111_0.selectMerHero)
			end

			if arg_111_0.selectMerPet then
				arg_111_0.guild:setUseRentPet(arg_111_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "illusion_detail"
				}
			})

			var_111_0.petsA = {}

			for iter_112_0, iter_112_1 in ipairs(arg_111_0.petSelect_) do
				table.insert(var_111_0.petsA, iter_112_1)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_111_0)
		else
			arg_111_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startStudentBattle(arg_113_0)
	local var_113_0 = false
	local var_113_1 = {
		herosA = {},
		herosB = {}
	}
	local var_113_2 = {}

	for iter_113_0, iter_113_1 in ipairs(arg_113_0.team_) do
		iter_113_1.data.type = iter_113_1.type

		if iter_113_1.type == var_0_17.RENT_HERO then
			var_113_0 = true
		else
			table.insert(var_113_2, iter_113_1.data)
		end

		table.insert(var_113_1.herosA, iter_113_1.data)
	end

	var_113_1.rentFlag = var_113_0
	var_113_1.campaignType = arg_113_0.campaignType
	var_113_1.campaignID = arg_113_0.campaignID
	var_113_1.battleID = xyd.tables.campaign:fightID(arg_113_0.campaignID)

	local var_113_3 = arg_113_0:getFormationStr(var_113_2)

	var_113_1.fightParams = {
		campaign_id = var_113_1.campaignID,
		formation = var_113_3
	}
	var_113_1.formation = var_113_3

	local var_113_4 = xyd.tables.battle:monsters(var_113_1.battleID)

	var_113_1.herosB = {}

	for iter_113_2 = 1, #var_113_4 do
		local var_113_5 = {}

		for iter_113_3, iter_113_4 in ipairs(var_113_4[iter_113_2]) do
			local var_113_6 = var_0_1.new()

			var_113_6:populateWithTableID(iter_113_4)
			table.insert(var_113_5, var_113_6)
		end

		table.insert(var_113_1.herosB, var_113_5)
	end

	var_113_1.petsA = {}

	for iter_113_5, iter_113_6 in ipairs(arg_113_0.petSelect_) do
		table.insert(var_113_1.petsA, iter_113_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "teacher"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_113_1)
end

function var_0_0.startZhugeNoteBattle(arg_114_0)
	local var_114_0 = false
	local var_114_1 = {
		herosA = {},
		herosB = {}
	}
	local var_114_2 = {}

	for iter_114_0, iter_114_1 in ipairs(arg_114_0.team_) do
		iter_114_1.data.type = iter_114_1.type

		if iter_114_1.type == var_0_17.RENT_HERO then
			var_114_0 = true
		else
			table.insert(var_114_2, iter_114_1.data)
		end

		table.insert(var_114_1.herosA, iter_114_1.data)
	end

	var_114_1.rentFlag = var_114_0
	var_114_1.campaignType = arg_114_0.campaignType
	var_114_1.campaignID = arg_114_0.campaignID
	var_114_1.battleID = arg_114_0.battleID

	local var_114_3 = arg_114_0:getFormationStr(var_114_2)

	var_114_1.fightParams = {
		campaign_id = var_114_1.campaignID,
		formation = var_114_3
	}
	var_114_1.formation = var_114_3

	local var_114_4 = xyd.tables.battle:monsters(var_114_1.battleID)

	var_114_1.herosB = {}

	for iter_114_2 = 1, #var_114_4 do
		local var_114_5 = {}

		for iter_114_3, iter_114_4 in ipairs(var_114_4[iter_114_2]) do
			local var_114_6 = var_0_1.new()

			var_114_6:populateWithTableID(iter_114_4)
			table.insert(var_114_5, var_114_6)
		end

		if var_114_5 and next(var_114_5) then
			table.insert(var_114_1.herosB, var_114_5)
		end
	end

	var_114_1.petsA = {}

	for iter_114_5, iter_114_6 in ipairs(arg_114_0.petSelect_) do
		table.insert(var_114_1.petsA, iter_114_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_small_house"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_114_1)
end

function var_0_0.startZhugeBossBattle(arg_115_0)
	local var_115_0 = false
	local var_115_1 = {
		herosA = {},
		herosB = {}
	}
	local var_115_2 = {}

	for iter_115_0, iter_115_1 in ipairs(arg_115_0.team_) do
		iter_115_1.data.type = iter_115_1.type

		if iter_115_1.type == var_0_17.RENT_HERO then
			var_115_0 = true
		else
			table.insert(var_115_2, iter_115_1.data)
		end

		table.insert(var_115_1.herosA, iter_115_1.data)
	end

	var_115_1.rentFlag = var_115_0
	var_115_1.campaignType = arg_115_0.campaignType
	var_115_1.campaignID = arg_115_0.campaignID
	var_115_1.battleID = arg_115_0.battleID

	local var_115_3 = arg_115_0:getFormationStr(var_115_2)

	var_115_1.fightParams = {
		campaign_id = var_115_1.campaignID,
		formation = var_115_3
	}
	var_115_1.formation = var_115_3

	local var_115_4 = xyd.tables.battle:monsters(var_115_1.battleID)

	var_115_1.herosB = {}

	for iter_115_2 = 1, 1 do
		local var_115_5 = {}

		for iter_115_3, iter_115_4 in ipairs(var_115_4[iter_115_2]) do
			local var_115_6 = var_0_1.new()

			var_115_6:populateWithTableID(iter_115_4)
			table.insert(var_115_5, var_115_6)
		end

		table.insert(var_115_1.herosB, var_115_5)
	end

	var_115_1.petsA = {}

	for iter_115_5, iter_115_6 in ipairs(arg_115_0.petSelect_) do
		table.insert(var_115_1.petsA, iter_115_6)
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "zhuge_small_house"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_115_1)
end

function var_0_0.startSakuraBattle(arg_116_0)
	local var_116_0 = false
	local var_116_1 = {
		herosA = {},
		herosB = {}
	}
	local var_116_2 = {}

	for iter_116_0, iter_116_1 in ipairs(arg_116_0.team_) do
		iter_116_1.data.type = iter_116_1.type

		if iter_116_1.type == var_0_17.RENT_HERO then
			var_116_0 = true
		else
			table.insert(var_116_2, iter_116_1.data)
		end

		table.insert(var_116_1.herosA, iter_116_1.data)
	end

	var_116_1.rentFlag = var_116_0
	var_116_1.campaignType = arg_116_0.campaignType
	var_116_1.campaignID = arg_116_0.campaignID
	var_116_1.battleID = xyd.tables.campaign:fightID(arg_116_0.campaignID)

	local var_116_3 = arg_116_0:getFormationStr(var_116_2)
	local var_116_4 = {
		formation = var_116_3
	}

	if arg_116_0.selectMerHero then
		var_116_4.rent_player_id = arg_116_0.selectMerHero.player_id
		var_116_4.rent_formation = tostring(arg_116_0.selectMerHero:getHeroID())
	end

	var_116_1.fightParams = var_116_4

	local var_116_5 = xyd.tables.battle:monsters(var_116_1.battleID)

	var_116_1.herosB = {}

	for iter_116_2 = 1, #var_116_5 do
		local var_116_6 = {}

		for iter_116_3, iter_116_4 in ipairs(var_116_5[iter_116_2]) do
			local var_116_7 = var_0_1.new()

			var_116_7:populateWithTableID(iter_116_4)
			table.insert(var_116_6, var_116_7)
		end

		table.insert(var_116_1.herosB, var_116_6)
	end

	var_116_1.star = arg_116_0.star_

	xyd.Backend.get():request(xyd.mid.SAKURA_START_FIGHT, var_116_4, function(arg_117_0, arg_117_1)
		if arg_117_0 == xyd.error.OK then
			if arg_117_1.items then
				local var_117_0 = {}

				for iter_117_0, iter_117_1 in ipairs(arg_117_1.items) do
					for iter_117_2 = 1, iter_117_1.item_num do
						local var_117_1 = var_0_11.new()

						var_117_1:populate({
							table_id = iter_117_1.item_id
						})
						var_117_1:initDrop(arg_116_0.campaignID)
						table.insert(var_117_0, var_117_1)
					end
				end

				var_116_1.drops = var_117_0
			end

			local var_117_2 = clone(var_116_5)
			local var_117_3 = xyd.tables.campaign:gainMana(arg_116_0.campaignID)

			if var_117_3 > 0 then
				local var_117_4 = 0

				for iter_117_3, iter_117_4 in ipairs(var_116_5) do
					for iter_117_5, iter_117_6 in ipairs(iter_117_4) do
						var_117_4 = var_117_4 + 1
					end
				end

				local var_117_5 = xyd.tables.battleConfig.monsterDropMana
				local var_117_6 = (var_117_5 + var_117_5 + var_117_4 - 1) / 2 * var_117_4
				local var_117_7 = 0
				local var_117_8 = var_117_3

				for iter_117_7, iter_117_8 in ipairs(var_116_5) do
					for iter_117_9, iter_117_10 in ipairs(iter_117_8) do
						var_117_7 = var_117_7 + 1

						if var_117_7 ~= var_117_4 then
							var_117_2[iter_117_7][iter_117_9] = math.ceil(var_117_3 / var_117_6 * (var_117_5 + var_117_7 - 1))
							var_117_8 = var_117_8 - var_117_2[iter_117_7][iter_117_9]
						else
							var_117_2[iter_117_7][iter_117_9] = var_117_8
						end
					end
				end

				var_116_1.dropMana = var_117_2
			end

			if arg_116_0.selectMerHero then
				arg_116_0.guild:setUseRent(arg_116_0.selectMerHero)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_116_1)
		else
			arg_116_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startPetBattle(arg_118_0, arg_118_1)
	local var_118_0 = false
	local var_118_1 = {
		herosA = {},
		herosB = {}
	}

	if arg_118_1 then
		var_118_1.noResult = true
	end

	local var_118_2 = {}

	for iter_118_0, iter_118_1 in ipairs(arg_118_0.team_) do
		iter_118_1.data.type = iter_118_1.type

		if iter_118_1.type == var_0_17.RENT_HERO then
			var_118_0 = true
		else
			table.insert(var_118_2, iter_118_1.data)
		end

		table.insert(var_118_1.herosA, iter_118_1.data)
	end

	var_118_1.rentFlag = var_118_0
	var_118_1.campaignType = arg_118_0.campaignType
	var_118_1.campaignID = arg_118_0.campaignID
	var_118_1.battleID = xyd.tables.campaign:fightID(arg_118_0.campaignID)

	local var_118_3 = arg_118_0:getFormationStr(var_118_2)
	local var_118_4 = {
		campaign_id = var_118_1.campaignID,
		formation = var_118_3
	}

	if arg_118_0.selectMerHero then
		var_118_4.rent_player_id = arg_118_0.selectMerHero.player_id
		var_118_4.rent_formation = tostring(arg_118_0.selectMerHero:getHeroID())
	end

	var_118_1.fightParams = var_118_4

	local var_118_5 = xyd.tables.battle:monsters(var_118_1.battleID)

	var_118_1.herosB = {}

	for iter_118_2 = 1, #var_118_5 do
		if #var_118_5[iter_118_2] > 0 then
			local var_118_6 = {}

			for iter_118_3, iter_118_4 in ipairs(var_118_5[iter_118_2]) do
				local var_118_7 = var_0_1.new()

				var_118_7:populateWithTableID(iter_118_4)
				table.insert(var_118_6, var_118_7)
			end

			table.insert(var_118_1.herosB, var_118_6)
		end
	end

	var_118_1.petsA = {}

	local var_118_8

	for iter_118_5, iter_118_6 in ipairs(arg_118_0.petSelect_) do
		table.insert(var_118_1.petsA, iter_118_6)
	end

	local var_118_9

	if #arg_118_0.petTeam_ ~= 0 and not arg_118_0.isSelectMerPet then
		var_118_9 = arg_118_0.petTeam_[1].data:getPetID()
	end

	var_118_4.pet_id = var_118_9

	if arg_118_0.isSelectMerPet then
		var_118_1.rent_pet_id = arg_118_0.selectMerPet:getPetID()
	end

	if arg_118_0.selectMerPet then
		var_118_4.rent_pet_player_id = arg_118_0.selectMerPet.player_id
		var_118_4.rent_pet_id = tostring(arg_118_0.selectMerPet:getPetID())
	end

	var_118_1.petFloor = arg_118_0.petFloor
	var_118_1.petFloorType = arg_118_0.petFloorType

	local var_118_10 = xyd.ModelManager.get():loadModel(xyd.ModelType.PET_COMPAIGN)

	if arg_118_1 then
		xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_PRACTICE, var_118_4, function(arg_119_0, arg_119_1)
			if arg_119_0 == xyd.error.OK then
				if arg_118_0.selectMerHero then
					arg_118_0.guild:setUseRent(arg_118_0.selectMerHero)
				end

				if arg_118_0.selectMerPet then
					arg_118_0.guild:setUseRentPet(arg_118_0.selectMerPet)
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "pet_campaign"
					}
				})

				if arg_118_0.type == xyd.SelectTeamType.PET_PRACTICE and arg_118_0.petFloor then
					var_118_10.testFormation[arg_118_0.petFloor] = {}
					var_118_10.testFormation[arg_118_0.petFloor].heros = {}

					for iter_119_0, iter_119_1 in pairs(var_118_1.herosA) do
						table.insert(var_118_10.testFormation[arg_118_0.petFloor].heros, iter_119_1:getHeroID())
					end

					if var_118_9 then
						var_118_10.testFormation[arg_118_0.petFloor].pet = var_118_9
					end
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_118_1)
			else
				arg_118_0.battleBegan = false
			end
		end, nil, false, true)
	else
		xyd.Backend.get():request(xyd.mid.PET_CAMPAIGN_FIGHT, var_118_4, function(arg_120_0, arg_120_1)
			if arg_120_0 == xyd.error.OK then
				if var_118_10.state == xyd.PetCampaignFloorType.SUPER then
					arg_118_0.selfPlayer:getBackpack():removeItem({
						itemNum = 1,
						itemID = xyd.tables.misc.skyCitySuperPaper
					})
				end

				if arg_118_0.selectMerHero then
					arg_118_0.guild:setUseRent(arg_118_0.selectMerHero)
				end

				if arg_118_0.selectMerPet then
					arg_118_0.guild:setUseRentPet(arg_118_0.selectMerPet)
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "pet_campaign"
					}
				})

				if arg_120_1 and arg_120_1.award and arg_120_1.award.item_id and arg_120_1.award.item_num then
					arg_118_0.selfPlayer:getBackpack():addItemsByID(arg_120_1.award.item_id, arg_120_1.award.item_num)
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_118_1)
			else
				arg_118_0.battleBegan = false
			end
		end, nil, false, true)
	end
end

function var_0_0.startWorldBossBattle(arg_121_0)
	local var_121_0 = false
	local var_121_1 = {
		herosA = {},
		herosB = {}
	}
	local var_121_2 = {}

	for iter_121_0, iter_121_1 in ipairs(arg_121_0.team_) do
		iter_121_1.data.type = iter_121_1.type

		if iter_121_1.type == var_0_17.RENT_HERO then
			var_121_0 = true
		else
			table.insert(var_121_2, iter_121_1.data)
		end

		table.insert(var_121_1.herosA, iter_121_1.data)
	end

	var_121_1.rentFlag = var_121_0
	var_121_1.campaignType = arg_121_0.campaignType
	var_121_1.campaignID = arg_121_0.campaignID
	var_121_1.battleID = xyd.tables.worldBoss.fight_id[arg_121_0.campaignID]

	local var_121_3 = arg_121_0:getFormationStr(var_121_2)
	local var_121_4 = {
		campaign_id = var_121_1.campaignID,
		formation = var_121_3
	}

	if arg_121_0.selectMerHero then
		var_121_4.rent_player_id = arg_121_0.selectMerHero.player_id
		var_121_4.rent_formation = tostring(arg_121_0.selectMerHero:getHeroID())
	end

	var_121_1.fightParams = var_121_4

	local var_121_5 = xyd.tables.battle:monsters(var_121_1.battleID)

	var_121_1.herosB = {}

	for iter_121_2 = 1, #var_121_5 do
		local var_121_6 = {}

		for iter_121_3, iter_121_4 in ipairs(var_121_5[iter_121_2]) do
			local var_121_7 = var_0_1.new()

			var_121_7:populateWithTableID(iter_121_4)
			table.insert(var_121_6, var_121_7)
		end

		table.insert(var_121_1.herosB, var_121_6)
	end

	xyd.Backend.get():request(xyd.mid.WORLD_BOSS_START_FIGHT, var_121_4, function(arg_122_0, arg_122_1)
		if arg_122_0 == xyd.error.OK then
			if arg_121_0.selectMerHero then
				arg_121_0.guild:setUseRent(arg_121_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "world_boss_battle_pre"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_121_1)
		else
			arg_121_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startGuildCampaignBattle(arg_123_0)
	local var_123_0 = false
	local var_123_1 = {
		herosA = {},
		herosB = {}
	}
	local var_123_2 = {}

	for iter_123_0, iter_123_1 in ipairs(arg_123_0.team_) do
		iter_123_1.data.type = iter_123_1.type

		if iter_123_1.type == var_0_17.RENT_HERO then
			var_123_0 = true
		else
			table.insert(var_123_2, iter_123_1.data)
		end

		table.insert(var_123_1.herosA, iter_123_1.data)
	end

	var_123_1.rentFlag = var_123_0
	var_123_1.campaignType = arg_123_0.campaignType
	var_123_1.campaignID = arg_123_0.campaignID
	var_123_1.battleID = xyd.tables.teamCampaign:fightID(arg_123_0.campaignID)

	local var_123_3 = arg_123_0:getFormationStr(var_123_2)
	local var_123_4 = {
		copy_id = var_123_1.campaignID,
		campaign_type = var_123_1.campaignType,
		formation = var_123_3,
		chapter_id = arg_123_0.guildChapterID
	}
	local var_123_5

	if #arg_123_0.petTeam_ ~= 0 and not arg_123_0.isSelectMerPet then
		var_123_5 = arg_123_0.petTeam_[1].data:getPetID()
	end

	var_123_4.pet_id = var_123_5

	if arg_123_0.isSelectMerPet then
		var_123_1.rent_pet_id = arg_123_0.selectMerPet:getPetID()
	end

	if arg_123_0.selectMerPet then
		var_123_4.rent_pet_player_id = arg_123_0.selectMerPet.player_id
		var_123_4.rent_pet_id = tostring(arg_123_0.selectMerPet:getPetID())
	end

	if arg_123_0.selectMerHero then
		var_123_4.rent_player_id = arg_123_0.selectMerHero.player_id
		var_123_4.rent_formation = tostring(arg_123_0.selectMerHero:getHeroID())
	end

	xyd.Backend.get():request(xyd.mid.GUILD_START_FIGHT, var_123_4, function(arg_124_0, arg_124_1)
		if arg_124_0 == xyd.error.OK then
			local function var_124_0(arg_125_0)
				local var_125_0 = var_0_1.new()

				var_125_0:populate(arg_125_0)

				var_125_0.healthStatus = {
					health = arg_125_0.health,
					hp = arg_125_0.hp,
					is_reborn = arg_125_0.is_reborn
				}
				var_125_0.guildDrop = {}

				return var_125_0
			end

			if arg_123_0.selectMerHero then
				arg_123_0.guild:setUseRent(arg_123_0.selectMerHero)
			end

			if arg_123_0.selectMerPet then
				arg_123_0.guild:setUseRentPet(arg_123_0.selectMerPet)
			end

			local var_124_1 = {
				{},
				{},
				{}
			}

			for iter_124_0, iter_124_1 in pairs(arg_124_1.enemy_status) do
				local var_124_2 = var_124_1[iter_124_0]

				for iter_124_2, iter_124_3 in ipairs(iter_124_1) do
					table.insert(var_124_2, var_124_0(iter_124_3))
				end
			end

			if arg_124_1.guild_drop and next(arg_124_1.guild_drop) then
				for iter_124_4, iter_124_5 in ipairs(arg_124_1.guild_drop) do
					local var_124_3

					for iter_124_6, iter_124_7 in ipairs(var_124_1[iter_124_5.index]) do
						if iter_124_7:getHeroID() == iter_124_5.hero_id then
							var_124_3 = iter_124_7

							break
						end
					end

					if var_124_3 ~= nil then
						for iter_124_8 = 1, iter_124_5.item_num do
							local var_124_4 = var_0_11.new()

							var_124_4:populate({
								table_id = iter_124_5.item_id
							})
							table.insert(var_124_3.guildDrop, var_124_4)
						end
					else
						print("guild drop info is invalid :")
						print(unpack(iter_124_5))
					end
				end
			end

			if arg_124_1.normal_drop and next(arg_124_1.normal_drop) then
				var_123_1.guildNormalDrop = {}

				if not arg_124_1.current_index then
					local var_124_5 = 1
				end

				for iter_124_9, iter_124_10 in ipairs(arg_124_1.normal_drop) do
					for iter_124_11 = 1, iter_124_10.item_num do
						local var_124_6 = var_0_11.new()

						var_124_6:populate({
							table_id = iter_124_10.item_id
						})
						table.insert(var_123_1.guildNormalDrop, var_124_6)
					end
				end
			end

			if arg_124_1.monster_drop and next(arg_124_1.monster_drop) then
				local var_124_7 = {}

				for iter_124_12 = 1, 10 do
					table.insert(var_124_7, {})
				end

				for iter_124_13, iter_124_14 in ipairs(arg_124_1.monster_drop) do
					for iter_124_15 = 1, iter_124_14.item_num do
						local var_124_8 = var_0_11.new()

						var_124_8:populate({
							table_id = iter_124_14.item_id
						})

						if iter_124_14.index <= #var_124_7 then
							table.insert(var_124_7[iter_124_14.index], var_124_8)
						end
					end
				end

				local var_124_9 = var_124_1[#var_124_1][1]

				if var_124_9 then
					var_124_9.monsterDrop = var_124_7
				end
			end

			var_123_1.herosB = var_124_1
			var_123_1.fightParams = var_123_4
			var_123_1.currentGroup = arg_124_1.current_index or 1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_123_0.campaignType,
						chapter = arg_123_0.guildChapterID
					}
				}
			})

			var_123_1.petsA = {}

			for iter_124_16, iter_124_17 in ipairs(arg_123_0.petSelect_) do
				table.insert(var_123_1.petsA, iter_124_17)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_123_1)
		else
			arg_123_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startChallengeBattle(arg_126_0)
	local var_126_0 = false
	local var_126_1 = {
		herosA = {},
		herosB = {}
	}
	local var_126_2 = {}

	for iter_126_0, iter_126_1 in ipairs(arg_126_0.team_) do
		iter_126_1.data.type = iter_126_1.type

		if iter_126_1.type == var_0_17.RENT_HERO then
			var_126_0 = true
		elseif iter_126_1.data:getHeroID() > 0 then
			table.insert(var_126_2, iter_126_1.data)
		end

		table.insert(var_126_1.herosA, iter_126_1.data)
	end

	var_126_1.rentFlag = var_126_0
	var_126_1.campaignType = arg_126_0.campaignType
	var_126_1.campaignID = arg_126_0.campaignID
	var_126_1.battleID = arg_126_0.battleID
	var_126_1.challengeType = var_0_14:modeType(arg_126_0.battleID)

	local var_126_3 = arg_126_0:getFormationStr(var_126_2)
	local var_126_4 = {
		campaign_id = var_126_1.campaignID,
		campaign_type = var_126_1.campaignType,
		formation = var_126_3
	}

	var_126_1.campaignType = xyd.CampaignType.CHALLENGE

	if arg_126_0.selectMerHero then
		var_126_4.rent_player_id = arg_126_0.selectMerHero.player_id
		var_126_4.rent_formation = tostring(arg_126_0.selectMerHero:getHeroID())
	end

	var_126_1.formation = var_126_3

	local var_126_5 = xyd.tables.battle:monsters(var_126_1.battleID)

	var_126_1.herosB = {}

	for iter_126_2 = 1, #var_126_5 do
		local var_126_6 = {}

		for iter_126_3, iter_126_4 in ipairs(var_126_5[iter_126_2]) do
			local var_126_7 = var_0_1.new()

			var_126_7:populateWithTableID(iter_126_4)
			table.insert(var_126_6, var_126_7)
		end

		table.insert(var_126_1.herosB, var_126_6)
	end

	xyd.Backend.get():request(xyd.mid.FIGHT, var_126_4, function(arg_127_0, arg_127_1)
		if arg_127_0 == xyd.error.OK then
			if arg_127_1.items then
				local var_127_0 = {}

				for iter_127_0, iter_127_1 in ipairs(arg_127_1.items) do
					for iter_127_2 = 1, iter_127_1.item_num do
						local var_127_1 = var_0_11.new()

						var_127_1:populate({
							table_id = iter_127_1.item_id
						})
						var_127_1:initDrop(arg_126_0.campaignID)
						table.insert(var_127_0, var_127_1)
					end
				end

				var_126_1.drops = var_127_0
			end

			local var_127_2 = clone(var_126_5)
			local var_127_3 = xyd.tables.campaign:gainMana(arg_126_0.campaignID)

			if var_127_3 > 0 then
				local var_127_4 = 0

				for iter_127_3, iter_127_4 in ipairs(var_126_5) do
					for iter_127_5, iter_127_6 in ipairs(iter_127_4) do
						var_127_4 = var_127_4 + 1
					end
				end

				local var_127_5 = xyd.tables.battleConfig.monsterDropMana
				local var_127_6 = (var_127_5 + var_127_5 + var_127_4 - 1) / 2 * var_127_4
				local var_127_7 = 0
				local var_127_8 = var_127_3

				for iter_127_7, iter_127_8 in ipairs(var_126_5) do
					for iter_127_9, iter_127_10 in ipairs(iter_127_8) do
						var_127_7 = var_127_7 + 1

						if var_127_7 ~= var_127_4 then
							var_127_2[iter_127_7][iter_127_9] = math.ceil(var_127_3 / var_127_6 * (var_127_5 + var_127_7 - 1))
							var_127_8 = var_127_8 - var_127_2[iter_127_7][iter_127_9]
						else
							var_127_2[iter_127_7][iter_127_9] = var_127_8
						end
					end
				end

				var_126_1.dropMana = var_127_2
			end

			if arg_126_0.selectMerHero then
				arg_126_0.guild:setUseRent(arg_126_0.selectMerHero)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_126_0.campaignType,
						chapter = xyd.tables.campaign:chapter(var_126_1.campaignID)
					}
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_126_1)
		else
			arg_126_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.getBattleID(arg_128_0)
	local var_128_0
	local var_128_1
	local var_128_2
	local var_128_3 = false

	if arg_128_0.campaignType == xyd.CampaignType.NORMAL and arg_128_0.campaignID ~= 0 then
		local var_128_4 = xyd.tables.campaign:firstFightID(arg_128_0.campaignID)
		local var_128_5 = arg_128_0.selfPlayer.worldMaps_[arg_128_0.campaignID].star or 0

		if var_128_4 ~= 0 and var_128_5 <= 0 then
			var_128_0 = var_128_4
			var_128_3 = true
		else
			var_128_0 = arg_128_0.battleID or xyd.tables.campaign:fightID(arg_128_0.campaignID)
		end
	else
		var_128_0 = arg_128_0.battleID or xyd.tables.campaign:fightID(arg_128_0.campaignID)
	end

	return var_128_0, var_128_3
end

function var_0_0.startCampaignBattle(arg_129_0)
	local var_129_0 = false
	local var_129_1 = false
	local var_129_2 = {}
	local var_129_3 = xyd.StoryData.get():getGuideID()

	if var_129_3 == xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT then
		arg_129_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_START)

		var_129_2.isGuide = true
	elseif var_129_3 == xyd.GuideStoryType.GUIDE_FIGHT_5_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_FOUR)
		arg_129_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_5_3)
	elseif var_129_3 == xyd.GuideStoryType.GUIDE_FIGHT_3_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_END)
		arg_129_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_4)
	end

	var_129_2.herosA = {}

	for iter_129_0, iter_129_1 in ipairs(arg_129_0.team_) do
		iter_129_1.data.type = iter_129_1.type

		if iter_129_1.type == var_0_17.RENT_HERO then
			var_129_0 = true
		end

		table.insert(var_129_2.herosA, iter_129_1.data)
	end

	var_129_2.rentFlag = var_129_0
	var_129_2.campaignType = arg_129_0.campaignType
	var_129_2.campaignID = arg_129_0.campaignID
	var_129_2.itemComposeID = arg_129_0.itemComposeID

	local var_129_4

	var_129_2.battleID, var_129_4 = arg_129_0:getBattleID()

	local var_129_5 = {}

	if xyd.StoryData.get():getStoryID() <= var_129_2.battleID then
		local var_129_6 = var_0_14:storyHeroes(var_129_2.battleID)

		for iter_129_2, iter_129_3 in ipairs(var_129_6) do
			local var_129_7 = 0

			for iter_129_4, iter_129_5 in ipairs(var_129_2.herosA) do
				if iter_129_5:getTableID() == iter_129_3 then
					var_129_7 = iter_129_2

					break
				end
			end

			if var_129_7 > 0 then
				local var_129_8 = var_0_14:specialBefore(var_129_2.battleID)[var_129_7] or 0
				local var_129_9 = var_0_14:specialLose(var_129_2.battleID)[var_129_7] or 0
				local var_129_10 = var_0_14:specialVictory(var_129_2.battleID)[var_129_7] or 0

				var_129_5 = {
					var_129_8,
					var_129_9,
					var_129_10
				}

				break
			end
		end

		if next(var_129_5) == nil then
			local var_129_11 = var_0_14:storyBefore(var_129_2.battleID)
			local var_129_12 = var_0_14:storyLose(var_129_2.battleID)
			local var_129_13 = var_0_14:storyVictory(var_129_2.battleID)

			var_129_5 = {
				var_129_11,
				var_129_12,
				var_129_13
			}
		end

		if xyd.StoryData.get():getStoryID() == var_129_2.battleID then
			if xyd.StoryData.get():getStoryState() >= 1 then
				var_129_5[1] = 0
			end

			if xyd.StoryData.get():getStoryState() >= 2 then
				var_129_5[2] = 0
			end

			if xyd.StoryData.get():getStoryState() >= 3 then
				var_129_5[3] = 0
			end
		end

		if var_129_4 then
			var_129_5[1] = 0
		end

		var_129_2.stories = var_129_5
	end

	if arg_129_0.selfPlayer.worldMaps_[arg_129_0.campaignID] then
		var_129_2.star = arg_129_0.selfPlayer.worldMaps_[arg_129_0.campaignID].star or 0

		if var_129_2.star <= 0 then
			local var_129_14 = var_0_14:preBattleShow(var_129_2.battleID)

			var_129_2.preBattleShow = clone(var_129_14)
		end

		local var_129_15 = arg_129_0.selfPlayer.worldMaps_[arg_129_0.campaignID].is_partner_drop
		local var_129_16 = xyd.tables.campaign:storyDropPartner(arg_129_0.campaignID)

		if (not var_129_15 or var_129_15 ~= 1) and var_129_16 and next(var_129_16) and var_129_16[1] ~= 0 then
			var_129_2.isPartnerdrop = true
		end
	end

	local var_129_17 = var_0_14:monsters(var_129_2.battleID)

	var_129_2.herosB = {}

	for iter_129_6 = 1, #var_129_17 do
		local var_129_18 = {}

		for iter_129_7, iter_129_8 in ipairs(var_129_17[iter_129_6]) do
			local var_129_19 = var_0_1.new()

			var_129_19:populateWithTableID(iter_129_8)
			table.insert(var_129_18, var_129_19)
		end

		if next(var_129_18) then
			table.insert(var_129_2.herosB, var_129_18)
		end
	end

	local var_129_20 = {}

	for iter_129_9, iter_129_10 in pairs(var_129_2.herosA) do
		if iter_129_10.type ~= var_0_17.RENT_HERO and iter_129_10:getHeroID() > 0 then
			table.insert(var_129_20, iter_129_10)
		end
	end

	if var_129_4 then
		var_129_2.isAssist = true
		var_129_2.assistID = arg_129_0.assistID
	end

	if var_129_2.star and var_129_2.star >= 0 and var_0_14:escapeEnemy(var_129_2.battleID) > 0 then
		var_129_2.isEscapeStory = true
	end

	if xyd.StoryData:get():getGuideID() == xyd.GuideStoryType.GUIDE_FIGHT_2_FOUR then
		var_129_2.guideMonsterID = xyd.tables.misc.guideBreakEnemy
	end

	if arg_129_0.isAwakeCampaign then
		var_129_2.isAwakeCampaign = true
		var_129_2.awakeHero = arg_129_0.awakeHero
		var_129_2.awakeStage = arg_129_0.awakeStage
		var_129_2.awakeMissionGoalType = arg_129_0.awakeMissionGoalType
		var_129_2.awakeMissionID = arg_129_0.awakeMission.table_id
	else
		var_129_2.isAwakeCampaign = false
	end

	local var_129_21 = arg_129_0:getFormationStr(var_129_20)

	var_129_2.formation = var_129_21

	local var_129_22 = {
		campaign_id = var_129_2.campaignID,
		campaign_type = var_129_2.campaignType,
		formation = var_129_21
	}
	local var_129_23

	if #arg_129_0.petTeam_ ~= 0 and not arg_129_0.isSelectMerPet then
		var_129_23 = arg_129_0.petTeam_[1].data:getPetID()
	end

	var_129_22.pet_id = var_129_23

	if arg_129_0.isSelectMerPet then
		var_129_2.rent_pet_id = arg_129_0.selectMerPet:getPetID()
	end

	if arg_129_0.selectMerPet then
		var_129_22.rent_pet_player_id = arg_129_0.selectMerPet.player_id
		var_129_22.rent_pet_id = tostring(arg_129_0.selectMerPet:getPetID())
	end

	if arg_129_0.selectMerHero then
		var_129_22.rent_player_id = arg_129_0.selectMerHero.player_id
		var_129_22.rent_formation = tostring(arg_129_0.selectMerHero:getHeroID())
	end

	xyd.Backend.get():request(xyd.mid.FIGHT, var_129_22, function(arg_130_0, arg_130_1)
		if arg_130_0 == xyd.error.OK then
			if arg_130_1.items then
				local var_130_0 = {}

				for iter_130_0, iter_130_1 in ipairs(arg_130_1.items) do
					for iter_130_2 = 1, iter_130_1.item_num do
						local var_130_1 = var_0_11.new()

						var_130_1:populate({
							table_id = iter_130_1.item_id
						})
						var_130_1:initDrop(arg_129_0.campaignID)
						table.insert(var_130_0, var_130_1)
					end
				end

				var_129_2.drops = var_130_0
			end

			local var_130_2 = clone(var_129_17)
			local var_130_3 = xyd.tables.campaign:gainMana(arg_129_0.campaignID)

			if var_130_3 > 0 then
				local var_130_4 = 0

				for iter_130_3, iter_130_4 in ipairs(var_129_17) do
					for iter_130_5, iter_130_6 in ipairs(iter_130_4) do
						var_130_4 = var_130_4 + 1
					end
				end

				local var_130_5 = xyd.tables.battleConfig.monsterDropMana
				local var_130_6 = (var_130_5 + var_130_5 + var_130_4 - 1) / 2 * var_130_4
				local var_130_7 = 0
				local var_130_8 = var_130_3

				for iter_130_7, iter_130_8 in ipairs(var_129_17) do
					for iter_130_9, iter_130_10 in ipairs(iter_130_8) do
						var_130_7 = var_130_7 + 1

						if var_130_7 ~= var_130_4 then
							var_130_2[iter_130_7][iter_130_9] = math.ceil(var_130_3 / var_130_6 * (var_130_5 + var_130_7 - 1))
							var_130_8 = var_130_8 - var_130_2[iter_130_7][iter_130_9]
						else
							var_130_2[iter_130_7][iter_130_9] = var_130_8
						end
					end
				end

				var_129_2.dropMana = var_130_2
			end

			if arg_129_0.selectMerHero then
				arg_129_0.guild:setUseRent(arg_129_0.selectMerHero)
			end

			if arg_129_0.selectMerPet then
				arg_129_0.guild:setUseRentPet(arg_129_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_129_0.campaignType,
						chapter = xyd.tables.campaign:chapter(var_129_2.campaignID)
					}
				}
			})

			var_129_2.petsA = {}

			for iter_130_11, iter_130_12 in ipairs(arg_129_0.petSelect_) do
				table.insert(var_129_2.petsA, iter_130_12)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_129_2)
		else
			arg_129_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.startSummerFightBossBattle(arg_131_0)
	local var_131_0 = {
		herosA = {}
	}

	for iter_131_0, iter_131_1 in ipairs(arg_131_0.team_) do
		table.insert(var_131_0.herosA, iter_131_1.data)
	end

	local var_131_1 = arg_131_0:getFormationStr(var_131_0.herosA)

	var_131_0.formation = var_131_1

	local var_131_2

	if #arg_131_0.petTeam_ ~= 0 then
		var_131_2 = arg_131_0.petTeam_[1].data:getPetID()
	end

	local var_131_3 = {
		formation = var_131_1,
		pet_id = var_131_2
	}

	xyd.ModelManager.get():loadModel(xyd.ModelType.SUMMER):fightQuizBoss(var_131_3, function(arg_132_0, arg_132_1)
		if arg_132_0 == xyd.error.OK then
			arg_132_1 = arg_132_1.battle_info

			local function var_132_0()
				ngx.ctx.battle.reportData = json.decode(arg_132_1.battle_report)
				var_131_0.battle_report = arg_132_1.battle_report
				var_131_0.herosA = {}
				var_131_0.herosB = {}
				var_131_0.summonMonsters = {}
				var_131_0.campaignType = arg_131_0.campaignType
				var_131_0.campaignID = arg_131_0.campaignID
				var_131_0.battleID = arg_131_0.battleID
				var_131_0.battleType = xyd.BattleType.ReplayReport

				local var_133_0 = {}
				local var_133_1 = {}

				for iter_133_0, iter_133_1 in pairs(ngx.ctx.battle.reportData.fighter) do
					local var_133_2 = string.sub(iter_133_0, 1, 1)
					local var_133_3 = tonumber(string.sub(iter_133_0, 3, 3))

					if var_133_2 == "A" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.None then
						local var_133_4 = var_0_1.new()

						var_133_4:populate(iter_133_1.hero)
						var_133_4:setReportData(iter_133_1)

						var_131_0.herosA[var_133_3] = var_133_4
					elseif var_133_2 == "A" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.Pet then
						local var_133_5 = var_0_2.new()

						var_133_5:populate(iter_133_1.hero)
						var_133_5:setReportData(iter_133_1)

						var_131_0.petsA = {
							var_133_5
						}
					elseif var_133_2 == "B" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.None then
						local var_133_6 = var_0_1.new()

						var_133_6:populate(iter_133_1.hero)
						var_133_6:setReportData(iter_133_1)

						var_133_0[var_133_3] = var_133_6
					elseif var_133_2 == "B" and tonumber(iter_133_1.summon_type) == xyd.summonMonsterType.Pet then
						local var_133_7 = var_0_2.new()

						var_133_7:populate(iter_133_1.hero)
						var_133_7:setReportData(iter_133_1)

						var_131_0.petsB = {
							var_133_7
						}
					elseif tonumber(iter_133_1.summon_type) ~= xyd.summonMonsterType.None then
						local var_133_8 = var_0_1.new()

						var_133_8:populate(iter_133_1.hero)
						var_133_8:setReportData(iter_133_1)

						var_133_1[iter_133_0] = var_133_8
					end
				end

				var_131_0.reportStar = ngx.ctx.battle.reportData.star
				var_131_0.herosB = {
					var_133_0
				}
				var_131_0.summonMonsters = var_133_1

				local var_133_9 = 0

				if arg_132_1.star > 0 then
					var_133_9 = 1
				end

				local var_133_10 = var_133_9
				local var_133_11 = {}

				if arg_132_1.library_mission_formations.partner_favor then
					for iter_133_2, iter_133_3 in pairs(arg_132_1.library_mission_formations.partner_favor) do
						if iter_133_3 > arg_131_0.selfPlayer:getHero(tonumber(iter_133_2)):getFavorDegree() then
							var_133_11[tonumber(iter_133_2)] = true

							arg_131_0.selfPlayer:getHero(tonumber(iter_133_2)):setFavorDegree(iter_133_3)
						end
					end

					var_131_0.favorDegreeUp = var_133_11
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "summer_quiz"
					}
				})
				xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL):formatLvbuCampusHeros(var_131_0.herosA)
				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_131_0)
			end

			if arg_132_1.battle_report == {} or #arg_132_1.battle_report == 0 then
				var_0_12.performWithDelayGlobal(function()
					requestReport(var_131_3)
				end, 3)
			else
				var_132_0()
			end
		elseif arg_132_1.error_code == 31005 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_13:translation("CHANGE_SEAL_HERO_TIPS")
			})

			arg_131_0.battleBegan = false
		else
			arg_131_0.battleBegan = false
		end
	end)
end

function var_0_0.startRegionArenaBattle(arg_135_0)
	local var_135_0 = {
		herosA = {}
	}

	for iter_135_0, iter_135_1 in ipairs(arg_135_0.team_) do
		table.insert(var_135_0.herosA, iter_135_1.data)
	end

	var_135_0.campaignType = arg_135_0.campaignType
	var_135_0.campaignID = arg_135_0.campaignID
	var_135_0.herosB = {
		arg_135_0.enemyHeroes_
	}
	var_135_0.fighterInfo = arg_135_0.fighterInfo
	var_135_0.battleID = xyd.MapBattleID.ARENA

	local var_135_1 = arg_135_0:getFormationStr(var_135_0.herosA)

	var_135_0.formation = var_135_1
	var_135_0.battleType = xyd.BattleType.CreateReport

	local var_135_2

	if #arg_135_0.petTeam_ ~= 0 then
		var_135_2 = arg_135_0.petTeam_[1].data:getPetID()
	end

	local var_135_3 = {
		pet_id = var_135_2,
		campaign_id = var_135_0.campaignID,
		campaign_type = var_135_0.campaignType,
		formation = var_135_1
	}

	if arg_135_0.isRegionPractise then
		var_135_3.is_practice = 1
	else
		var_135_3.is_practice = 0
	end

	xyd.Backend.get():request(xyd.mid.REGION_START_FIGHT, var_135_3, function(arg_136_0, arg_136_1)
		if arg_136_0 == xyd.error.OK then
			if arg_136_1.formation and next(arg_136_1.formation) then
				local var_136_0 = {}

				for iter_136_0, iter_136_1 in ipairs(arg_136_1.formation) do
					local var_136_1 = var_0_1.new()

					var_136_1:populate(iter_136_1)
					table.insert(var_136_0, var_136_1)
				end

				xyd.formatRegionArenaHeros(var_136_0)

				var_135_0.herosA = var_136_0
			end

			var_135_0.petsA = {}

			for iter_136_2, iter_136_3 in ipairs(arg_135_0.petSelect_) do
				table.insert(var_135_0.petsA, iter_136_3)
			end

			xyd.formatRegionArenaPets(var_135_0.petsA)

			var_135_0.petsB = {}

			table.insert(var_135_0.petsB, arg_135_0.enemyPets_)

			if arg_135_0.isRegionPractise then
				var_135_0.is_practice = true
			else
				var_135_0.is_practice = false
			end

			var_135_0.enemy_id = arg_135_0.fighterInfo.enemy_id
			arg_135_0.regionArena.isPractise = arg_135_0.isRegionPractise

			xyd.WindowManager.get():hideAllWindows()
			xyd.LoadingProxy.get():openBattleLoading(var_135_0)
		else
			arg_135_0.battleBegan = false
		end
	end)
end

function var_0_0.startMarchBattle(arg_137_0)
	local var_137_0 = {
		herosA = {}
	}

	for iter_137_0, iter_137_1 in ipairs(arg_137_0.team_) do
		iter_137_1.data.type = iter_137_1.type

		table.insert(var_137_0.herosA, iter_137_1.data)
	end

	local var_137_1 = {}

	for iter_137_2, iter_137_3 in ipairs(arg_137_0.enemyHeroes_) do
		if iter_137_3.healthStatus.health ~= 2 then
			table.insert(var_137_1, iter_137_3)
		end
	end

	var_137_0.campaignType = arg_137_0.campaignType
	var_137_0.campaignID = arg_137_0.campaignID
	var_137_0.herosB = {
		var_137_1
	}
	var_137_0.enemyID = arg_137_0.enemyID_
	var_137_0.battleID = xyd.MapBattleID.MARCH[arg_137_0.marchStage_]

	local var_137_2 = clone(var_137_0.herosA)

	for iter_137_4, iter_137_5 in pairs(var_137_2) do
		if iter_137_5.type == var_0_17.RENT_HERO then
			table.remove(var_137_2, iter_137_4)
		end
	end

	local var_137_3 = arg_137_0:getFormationStr(var_137_2)

	var_137_0.formation = var_137_3

	local var_137_4 = {
		campaign_type = var_137_0.campaignType,
		formation = var_137_3
	}

	if arg_137_0.selectMerHero then
		var_137_4.rent_formation = tostring(arg_137_0.selectMerHero:getHeroID())
		var_137_4.rent_player_id = arg_137_0.selectMerHero.player_id
	end

	xyd.Backend.get():request(xyd.mid.MARCH_START_FIGHT, var_137_4, function(arg_138_0, arg_138_1)
		if arg_138_0 == xyd.error.OK then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "march"
				}
			})

			if arg_137_0.selectMerHero then
				arg_137_0.guild:setUseRent(arg_137_0.selectMerHero)
			end

			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_137_0)
		else
			arg_137_0.battleBegan = false
		end
	end)
end

function var_0_0.startMarchAdvance(arg_139_0)
	local var_139_0 = {}
	local var_139_1 = {}

	for iter_139_0, iter_139_1 in ipairs(arg_139_0.team_) do
		if iter_139_1.type ~= var_0_17.RENT_HERO then
			iter_139_1.data.type = iter_139_1.type

			table.insert(var_139_1, iter_139_1.data)
		end
	end

	var_139_0.campaign_type = xyd.CampaignType.MARCH
	var_139_0.formation = arg_139_0:getFormationStr(var_139_1)
	var_139_0.force = arg_139_0.rateScore

	if arg_139_0.selectMerHero then
		var_139_0.rent_formation = tostring(arg_139_0.selectMerHero:getHeroID())
		var_139_0.rent_player_id = arg_139_0.selectMerHero.player_id
	end

	xyd.Backend.get():request(xyd.mid.MARCH_ADVANCE_SWEEP, var_139_0, function(arg_140_0, arg_140_1)
		if arg_140_0 == xyd.error.OK then
			if arg_140_1.partner_favor then
				for iter_140_0, iter_140_1 in pairs(arg_140_1.partner_favor) do
					if iter_140_1 > arg_139_0.selfPlayer:getHero(tonumber(iter_140_0)):getFavorDegree() then
						arg_139_0.selfPlayer:getHero(tonumber(iter_140_0)):setFavorDegree(iter_140_1)
					end
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_FAVOR_INFO
				})
			end

			local var_140_0 = {
				award = arg_140_1.award,
				economy = arg_140_1.economy,
				power_drink = arg_140_1.power_drink
			}

			xyd.WindowManager.get():openWindow("march_sweep_window", var_140_0)
			xyd.WindowManager.get():closeWindow(arg_139_0)
			xyd.WindowManager.get():getWindow("march"):addMap()
		end
	end)
end

function var_0_0.startTreasureBattle(arg_141_0)
	local var_141_0 = false
	local var_141_1 = {
		herosA = {}
	}

	for iter_141_0, iter_141_1 in ipairs(arg_141_0.team_) do
		iter_141_1.data.type = iter_141_1.type

		if iter_141_1.type == var_0_17.RENT_HERO then
			var_141_0 = true
		end

		table.insert(var_141_1.herosA, iter_141_1.data)
	end

	var_141_1.rentFlag = var_141_0

	local var_141_2 = {}

	for iter_141_2, iter_141_3 in ipairs(arg_141_0.enemyHeroes_) do
		if iter_141_3.healthStatus.health ~= 2 and (iter_141_3.healthStatus.hp == nil or iter_141_3.healthStatus.hp > 0) then
			table.insert(var_141_2, iter_141_3)
		end
	end

	var_141_1.campaignType = arg_141_0.campaignType
	var_141_1.campaignID = arg_141_0.campaignID
	var_141_1.treasureAwardType = arg_141_0.treasureType
	var_141_1.herosB = {
		var_141_2
	}
	var_141_1.enemyID = arg_141_0.enemyID_
	var_141_1.battleID = xyd.MapBattleID.TREASURE[arg_141_0.treasureType]

	local var_141_3 = clone(var_141_1.herosA)

	for iter_141_4, iter_141_5 in pairs(var_141_3) do
		if iter_141_5.type == var_0_17.RENT_HERO then
			table.remove(var_141_3, iter_141_4)
		end
	end

	local var_141_4 = arg_141_0:getFormationStr(var_141_3)

	if arg_141_0.selectMerHero then
		local var_141_5 = {
			campaign_type = var_141_1.campaignType,
			formation = var_141_4,
			rent_player_id = arg_141_0.selectMerHero.player_id,
			rent_formation = tostring(arg_141_0.selectMerHero:getHeroID())
		}

		xyd.Backend.get():request(xyd.mid.TREASURE_START_FIGHT, var_141_5, function(arg_142_0, arg_142_1)
			if arg_142_0 == xyd.error.OK then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
					params = {
						window = "treasure_window",
						status = {
							isSelf = false
						}
					}
				})

				if arg_141_0.selectMerHero then
					arg_141_0.guild:setUseRent(arg_141_0.selectMerHero)
				end

				xyd.WindowManager.get():retainHistory()
				xyd.pushBattleScene(var_141_1)
			else
				arg_141_0.battleBegan = false
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
		xyd.pushBattleScene(var_141_1)
	end
end

function var_0_0.startConquerSchoolBattle(arg_143_0)
	local var_143_0 = false
	local var_143_1 = {
		herosA = {}
	}

	for iter_143_0, iter_143_1 in ipairs(arg_143_0.team_) do
		iter_143_1.data.type = iter_143_1.type

		if iter_143_1.type == var_0_17.RENT_HERO then
			var_143_0 = true
		end

		table.insert(var_143_1.herosA, iter_143_1.data)
	end

	var_143_1.rentFlag = var_143_0
	var_143_1.campaignType = arg_143_0.campaignType
	var_143_1.campaignID = arg_143_0.campaignID
	var_143_1.conquerSchoolTeamID = arg_143_0.conquerSchoolTeamID
	var_143_1.battleID = xyd.tables.conquerSchoolCampaign:fightIDs(arg_143_0.campaignID)[arg_143_0.conquerSchoolTeamID]

	local var_143_2 = xyd.tables.conquerSchoolCampaign:teams(arg_143_0.campaignID)[arg_143_0.conquerSchoolTeamID]

	var_143_1.herosB = {}

	local var_143_3 = {}

	for iter_143_2, iter_143_3 in ipairs(var_143_2) do
		local var_143_4 = var_0_1.new()
		local var_143_5 = arg_143_0.selfPlayer.conquerLoopID
		local var_143_6 = xyd.tables.ConquerSchoolLoop:ratio(var_143_5)

		var_143_4:populateWithTableID(iter_143_3)

		local var_143_7 = var_143_4.getTotalAttr

		function var_143_4.getTotalAttr(arg_144_0, arg_144_1)
			local var_144_0 = var_143_7(arg_144_0, arg_144_1)

			if arg_144_1 == xyd.AttributeType.HP or arg_144_1 == xyd.AttributeType.AD or arg_144_1 == xyd.AttributeType.AP or arg_144_1 == xyd.AttributeType.HUJIA or arg_144_1 == xyd.AttributeType.MOKANG or arg_144_1 == xyd.AttributeType.AD_BAOJI or arg_144_1 == xyd.AttributeType.AP_BAOJI or arg_144_1 == xyd.AttributeType.SHANBI or arg_144_1 == xyd.AttributeType.D_HUJIA or arg_144_1 == xyd.AttributeType.D_MOKANG or arg_144_1 == xyd.AttributeType.MINGZHONG then
				return var_144_0 * var_143_6
			else
				return var_144_0
			end
		end

		table.insert(var_143_3, var_143_4)
	end

	if next(var_143_3) then
		table.insert(var_143_1.herosB, var_143_3)
	end

	local var_143_8 = var_0_1.new()

	var_143_8:populateWithTableID(90000101)

	var_143_1.sceneFighter = var_143_8

	local var_143_9 = {}

	for iter_143_4, iter_143_5 in pairs(var_143_1.herosA) do
		if iter_143_5.type ~= var_0_17.RENT_HERO and iter_143_5:getHeroID() > 0 then
			table.insert(var_143_9, iter_143_5)
		end
	end

	local var_143_10 = arg_143_0:getFormationStr(var_143_9)

	var_143_1.formation = var_143_10

	local var_143_11 = {
		formation = var_143_10
	}
	local var_143_12

	if #arg_143_0.petTeam_ ~= 0 and not arg_143_0.isSelectMerPet then
		var_143_12 = arg_143_0.petTeam_[1].data:getPetID()
	end

	var_143_11.pet_id = var_143_12
	var_143_1.fightParams = var_143_11

	xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL):startFight(var_143_11, function(arg_145_0, arg_145_1)
		if arg_145_0 == xyd.error.OK then
			var_143_1.petsA = {}

			for iter_145_0, iter_145_1 in ipairs(arg_143_0.petSelect_) do
				table.insert(var_143_1.petsA, iter_145_1)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "conquer_school"
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_143_1)
		else
			arg_143_0.battleBegan = false
		end
	end)
end

function var_0_0.getFormationStr(arg_146_0, arg_146_1)
	local var_146_0 = ""

	for iter_146_0, iter_146_1 in ipairs(arg_146_1) do
		var_146_0 = var_146_0 .. string.format("%d", iter_146_1:getHeroID())

		if iter_146_0 < #arg_146_1 then
			var_146_0 = var_146_0 .. "|"
		end
	end

	return var_146_0
end

function var_0_0.size(arg_147_0, arg_147_1, arg_147_2)
	return {
		width = arg_147_1,
		height = arg_147_2
	}
end

function var_0_0.setIDBeforeGuideWnd(arg_148_0)
	local var_148_0 = xyd.StoryData.get():getGuideID()

	if var_148_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL)
	elseif var_148_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_TWO)
	elseif var_148_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_TWO)
	elseif var_148_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_149_0)
	local var_149_0 = xyd.StoryData.get():getGuideID()

	if var_149_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO)
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE)
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR)
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT)
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_MISSION_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START)
		xyd.StoryData.get():persist()
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE then
		arg_149_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_2_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_FOUR)
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO then
		arg_149_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_THREE)
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		arg_149_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_4)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_END)
		xyd.StoryData.get():persist()
	elseif var_149_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		arg_149_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR)
	end
end

function var_0_0.checkGuideIntoBattle(arg_150_0)
	local var_150_0 = xyd.StoryData.get():getGuideID()

	if var_150_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR or var_150_0 == xyd.GuideStoryType.GUIDE_MISSION_END or var_150_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE or var_150_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO or var_150_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		return true
	end

	return false
end

function var_0_0.getGuideHeroCell(arg_151_0, arg_151_1)
	local var_151_0 = xyd.StoryData.get():getGuideID()
	local var_151_1 = arg_151_1 or 10001001

	if var_151_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		var_151_1 = 10001004
	end

	for iter_151_0 = 1, #arg_151_0.heroCells_ do
		if arg_151_0.heroCells_[iter_151_0] and arg_151_0.heroCells_[iter_151_0].data and arg_151_0.heroCells_[iter_151_0].data:getTableID() == var_151_1 then
			return arg_151_0.heroCells_[iter_151_0]
		end
	end

	return arg_151_0.heroCells_[1]
end

function var_0_0.playGuide(arg_152_0)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_152_0 = xyd.StoryData.get():getGuideID()

	if tonumber(#arg_152_0.team_) >= 3 and var_152_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR)

		var_152_0 = xyd.StoryData.get():getGuideID()
	end

	if var_152_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
		local var_152_1 = arg_152_0.heroCells_[1]

		if var_152_1 == nil then
			return
		end

		local var_152_2 = {
			550,
			350
		}

		xyd.showGuideWnd(var_152_1, nil, nil, 1, var_152_2, true)
		arg_152_0:setIDAfterGuideWnd()
	elseif var_152_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
		local var_152_3 = arg_152_0.heroCells_[2]

		if var_152_3 == nil then
			return
		end

		local var_152_4 = {
			550,
			350
		}

		xyd.showGuideWnd(var_152_3, nil, nil, 1, var_152_4, true)
		arg_152_0:setIDAfterGuideWnd()
	elseif var_152_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
		local var_152_5 = arg_152_0.heroCells_[3]

		if var_152_5 == nil then
			return
		end

		local var_152_6 = {
			550,
			350
		}

		xyd.showGuideWnd(var_152_5, nil, nil, 1, var_152_6, true)
		arg_152_0:setIDAfterGuideWnd()
	elseif arg_152_0:checkGuideIntoBattle() then
		local var_152_7 = arg_152_0:nodeByName("button_battle")
		local var_152_8 = {
			850,
			250
		}

		xyd.showGuideWnd(var_152_7, nil, nil, 0, var_152_8, true)
		arg_152_0:setIDAfterGuideWnd()

		if #arg_152_0.select_ < 1 then
			arg_152_0.preSelect_ = {}
			arg_152_0.preHeros_ = {}

			table.insert(arg_152_0.preSelect_, 1)
			table.insert(arg_152_0.preSelect_, 2)
			table.insert(arg_152_0.preSelect_, 3)
			table.insert(arg_152_0.preHeros_, arg_152_0.selfPlayer:getHeroByID(1))
			table.insert(arg_152_0.preHeros_, arg_152_0.selfPlayer:getHeroByID(2))
			table.insert(arg_152_0.preHeros_, arg_152_0.selfPlayer:getHeroByID(3))
			arg_152_0:refreshSelectedHeroClass()
		end
	elseif var_152_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		local var_152_9 = arg_152_0:getGuideHeroCell()

		if var_152_9 == nil then
			return
		end

		local var_152_10 = {
			550,
			350
		}

		xyd.showGuideWnd(var_152_9, nil, nil, 1, var_152_10, true)
		arg_152_0:setIDAfterGuideWnd()
	end
end

function var_0_0.checkGuildPrepareTime(arg_153_0)
	if arg_153_0.campaignType == xyd.CampaignType.GUILD and arg_153_0.guildPrepareTime and arg_153_0.guildPrepareTime > 0 then
		arg_153_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_153_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_13:translation("GUILD_PREPARE_FIGHT"), arg_153_0.guildPrepareTime))

		arg_153_0.handle_ = var_0_12.scheduleGlobal(function()
			arg_153_0.guildPrepareTime = arg_153_0.guildPrepareTime - 1

			if arg_153_0.guildPrepareTime <= 0 then
				if arg_153_0.handle_ then
					var_0_12.unscheduleGlobal(arg_153_0.handle_)
				end

				xyd.WindowManager.get():closeWindow(arg_153_0.name)
			else
				arg_153_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_13:translation("GUILD_PREPARE_FIGHT"), arg_153_0.guildPrepareTime))
			end
		end, 1)
	end
end

function var_0_0.checkBusyHeros(arg_155_0, arg_155_1)
	for iter_155_0 = 1, #arg_155_0.busyHeroList do
		if arg_155_0.busyHeroList[iter_155_0] == arg_155_1:getHeroID() then
			for iter_155_1, iter_155_2 in pairs(arg_155_0.preSelect_) do
				if iter_155_2 == arg_155_0.busyHeroList[iter_155_0] then
					return true
				end
			end

			return false
		end
	end

	return true
end

function var_0_0.checkBusyHero2(arg_156_0, arg_156_1)
	local var_156_0 = false

	for iter_156_0, iter_156_1 in pairs(arg_156_0.busyHeros_) do
		if iter_156_1 == arg_156_1:getHeroID() then
			var_156_0 = true

			break
		end
	end

	return var_156_0
end

function var_0_0.canPetJoinBattle(arg_157_0, arg_157_1)
	if arg_157_0.type == xyd.SelectTeamType.ADJUST_TROOP and arg_157_1.level_ < arg_157_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
		return false
	end

	return true
end

function var_0_0.canHeroJoinBattle(arg_158_0, arg_158_1)
	if arg_158_0.campaignLimit and next(arg_158_0.campaignLimit) then
		local var_158_0 = arg_158_1:getFromType()

		if xyd.isInTable(arg_158_0.campaignLimit, var_158_0) then
			return false
		end
	end

	if arg_158_0.selectSpType == xyd.SelectSpType.WEI then
		if arg_158_1:getFromType() ~= xyd.HeroFromType.WEI then
			return false
		end
	elseif arg_158_0.selectSpType == xyd.SelectSpType.SHU then
		if arg_158_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_158_0.selectSpType == xyd.SelectSpType.WU then
		if arg_158_1:getFromType() ~= xyd.HeroFromType.WU then
			return false
		end
	elseif arg_158_0.selectSpType == xyd.SelectSpType.QUN and arg_158_1:getFromType() ~= xyd.HeroFromType.QUN then
		return false
	end

	if arg_158_0.campaignType == xyd.CampaignType.WU then
		if arg_158_1:getFromType() == xyd.HeroFromType.WU then
			return false
		end
	elseif arg_158_0.campaignType == xyd.CampaignType.SHU then
		if arg_158_1:getFromType() == xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_158_0.campaignType == xyd.CampaignType.WEI then
		if arg_158_1:getFromType() ~= xyd.HeroFromType.WU and arg_158_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_158_0.type == xyd.SelectTeamType.TREASURE_DEFENSE then
		if not arg_158_0:checkBusyHeros(arg_158_1) then
			return false
		end
	elseif arg_158_0.type == xyd.SelectTeamType.WORLD_BOSS then
		if arg_158_1.color_ < xyd.EquipQuality.PURPLE then
			return false
		end
	elseif arg_158_0.type == xyd.SelectTeamType.ADJUST_TROOP then
		if arg_158_1.level_ < arg_158_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
			return false
		end
	elseif arg_158_0.type == xyd.SelectTeamType.CHALLENGE then
		if var_0_14:modeType(arg_158_0.battleID) == xyd.ChallengeType.KillSteal then
			local var_158_1 = var_0_14:killingHero(arg_158_0.battleID)
			local var_158_2 = xyd.tables.hero:monster2PartnerID(var_158_1)

			if arg_158_1:getTableID() == var_158_2 or xyd.tables.hero:beforeAwaken(arg_158_1:getTableID()) == var_158_2 or xyd.tables.hero:afterAwaken(arg_158_1:getTableID()) == var_158_2 then
				return false
			end
		elseif var_0_14:modeType(arg_158_0.battleID) == xyd.ChallengeType.Protect then
			local var_158_3 = var_0_14:protectedHero(arg_158_0.battleID)
			local var_158_4 = xyd.tables.hero:monster2PartnerID(var_158_3)

			if arg_158_1:getTableID() == var_158_4 or xyd.tables.hero:beforeAwaken(arg_158_1:getTableID()) == var_158_4 or xyd.tables.hero:afterAwaken(arg_158_1:getTableID()) == var_158_4 then
				return false
			end
		end
	end

	if arg_158_0.type == xyd.SelectTeamType.ADVANCED then
		if arg_158_1:getLevel() >= var_0_8 then
			return true
		end
	elseif arg_158_1:getLevel() >= xyd.tables.battle:levLimit(arg_158_0.campaignID) then
		return true
	end

	return false
end

function var_0_0.initHeros(arg_159_0, arg_159_1, arg_159_2)
	arg_159_0.tmpTotalHero_[arg_159_2] = {}
	arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.ALL] = {}
	arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.QIANPAI] = {}
	arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.HOUPAI] = {}
	arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.FILTER] = {}

	for iter_159_0, iter_159_1 in pairs(arg_159_1) do
		if arg_159_0:canHeroJoinBattle(iter_159_1) then
			if iter_159_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.QIANPAI], iter_159_1)
			elseif iter_159_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.ZHONGPAI], iter_159_1)
			elseif iter_159_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.HOUPAI], iter_159_1)
			end

			table.insert(arg_159_0.tmpTotalHero_[arg_159_2][xyd.DistanceType.ALL], iter_159_1)
		end
	end

	arg_159_0:sortTables(arg_159_0.tmpTotalHero_[arg_159_2])

	arg_159_0.selectedHeroClass_[arg_159_2] = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_160_0, arg_160_1, arg_160_2)
	local var_160_0 = {}

	for iter_160_0, iter_160_1 in ipairs(arg_160_1) do
		if iter_160_1.is_show_ == 1 and arg_160_0:canPetJoinBattle(iter_160_1) then
			table.insert(var_160_0, iter_160_1)
		end
	end

	table.sort(var_160_0, function(arg_161_0, arg_161_1)
		return xyd.petNormalSort(arg_161_0, arg_161_1) or false
	end)

	arg_160_0.tmpTotalPets[arg_160_2] = var_160_0
end

function var_0_0.updateFilterHeros(arg_162_0)
	arg_162_0.totalHero_[xyd.DistanceType.FILTER] = {}

	local var_162_0 = {
		0,
		0,
		0
	}
	local var_162_1 = {
		0,
		0,
		0
	}
	local var_162_2 = {
		0,
		0,
		0,
		0
	}

	if arg_162_0.selfPlayer.sortType and arg_162_0.selfPlayer.sortType > 0 then
		local var_162_3 = {}
		local var_162_4 = arg_162_0.selfPlayer.sortType
		local var_162_5 = 1

		while var_162_4 > 0 do
			var_162_3[var_162_5] = var_162_4 % 2
			var_162_5 = var_162_5 + 1
			var_162_4 = math.floor(var_162_4 / 2)
		end

		local var_162_6 = 1

		for iter_162_0 = 10, 1, -1 do
			if iter_162_0 <= 4 then
				if iter_162_0 == 4 then
					var_162_6 = 1
				end

				var_162_2[var_162_6] = var_162_3[iter_162_0]
			elseif iter_162_0 <= 7 then
				if iter_162_0 == 7 then
					var_162_6 = 1
				end

				var_162_1[var_162_6] = var_162_3[iter_162_0]
			elseif iter_162_0 <= 10 and var_162_3[iter_162_0] then
				var_162_0[var_162_6] = var_162_3[iter_162_0]
			end

			var_162_6 = var_162_6 + 1
		end
	else
		var_162_0 = {
			1,
			1,
			1
		}
		var_162_1 = {
			1,
			1,
			1
		}
		var_162_2 = {
			1,
			1,
			1,
			1
		}
	end

	for iter_162_1, iter_162_2 in pairs(arg_162_0.totalHero_[xyd.DistanceType.ALL]) do
		if var_162_0[iter_162_2:getDistanceType() - 1] == 1 and var_162_1[iter_162_2:getHeroType()] == 1 and var_162_2[iter_162_2:getFromType()] == 1 and arg_162_0:canHeroJoinBattle(iter_162_2) then
			table.insert(arg_162_0.totalHero_[xyd.DistanceType.FILTER], iter_162_2)
		end
	end
end

function var_0_0.initPresetTeams(arg_163_0)
	arg_163_0.presetTeams = {}

	if not arg_163_0:checkCanPresetTeam() then
		return
	end

	local var_163_0 = arg_163_0.selfPlayer:getSaveTeams()

	if arg_163_0.type and arg_163_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_163_0.type == xyd.SelectTeamType.REGION_ARENA or arg_163_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		local var_163_1 = arg_163_0.regionAwards

		for iter_163_0 = 1, #var_163_0 do
			local var_163_2 = var_163_0[iter_163_0].team

			arg_163_0:initRegionHeros(var_163_2, var_163_1, true)
			xyd.formatRegionArenaHeros(var_163_2)
		end
	end

	arg_163_0.presetTeams = var_163_0
end

function var_0_0.selectHeros(arg_164_0)
	arg_164_0.totalHero_ = arg_164_0.tmpTotalHero_[arg_164_0.leftMenuType_]
end

function var_0_0.selectPets(arg_165_0)
	if arg_165_0.rentMenuType == var_0_18.RENT_PET then
		arg_165_0.totalPet_ = arg_165_0.tmpTotalPets[var_0_19.RENT_PET]
	else
		arg_165_0.totalPet_ = arg_165_0.tmpTotalPets[var_0_19.SELF_PET]
	end
end

function var_0_0.initListview(arg_166_0)
	local var_166_0 = arg_166_0:nodeByName("list_layer")
	local var_166_1 = var_166_0:getContentSize().width
	local var_166_2 = var_166_0:getContentSize().height

	arg_166_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_166_1, var_166_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_166_0)
	arg_166_0.heroCells_ = {}

	arg_166_0.heroList_:setDelegate(handler(arg_166_0, arg_166_0.delegate))
end

function var_0_0.initTextOfList(arg_167_0)
	arg_167_0.txt_height = arg_167_0:nodeByName("lev_limit_txt"):getY()

	if arg_167_0.type == xyd.SelectTeamType.ADVANCED then
		arg_167_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_167_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_13:translation("SELECT_HERO_LEV_LIMIT"), var_0_8, var_0_13:translation("MARCH_ADVANCED")))
	elseif arg_167_0.type == xyd.SelectTeamType.INCUBUS then
		arg_167_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_167_0:nodeByName("lev_limit_txt"):setString(var_0_13:translation("INCUBUS_CHOOSE_FIRST"))
	elseif arg_167_0.type == xyd.SelectTeamType.ADVENTURE_DEFENSE then
		arg_167_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_167_0:updateDefenseTimeCount(arg_167_0:nodeByName("lev_limit_txt"))
	elseif xyd.tables.battle:levLimit(arg_167_0.campaignID) > 0 then
		arg_167_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_167_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_13:translation("SELECT_HERO_LEV_LIMIT"), xyd.tables.battle:levLimit(arg_167_0.campaignID), xyd.tables.battle:name(arg_167_0.campaignID)))
	else
		arg_167_0:nodeByName("lev_limit_txt"):setVisible(false)
	end

	if arg_167_0.campaignType == xyd.CampaignType.ELEMENT and arg_167_0.hasPurpleHero ~= nil and arg_167_0.hasPurpleHero == false then
		arg_167_0:nodeByName("lev_limit_txt"):y(arg_167_0.txt_height - 20)
		arg_167_0:nodeByName("lev_limit_txt"):show()
		arg_167_0:nodeByName("lev_limit_txt"):setString(var_0_13:translation("HAS_NOT_PURPLE_HERO"))
	end
end

function var_0_0.updateTextOfList(arg_168_0)
	if arg_168_0.campaignType ~= xyd.CampaignType.ELEMENT then
		return
	end

	if arg_168_0.leftMenuType_ == var_0_17.SELF_HERO and arg_168_0.hasPurpleHero == false or arg_168_0.leftMenuType_ == var_0_17.RENT_HERO and arg_168_0.hasGuildPurpleHero == false then
		arg_168_0:nodeByName("lev_limit_txt"):y(arg_168_0.txt_height - 20)
		arg_168_0:nodeByName("lev_limit_txt"):show()
		arg_168_0:nodeByName("lev_limit_txt"):setString(var_0_13:translation("HAS_NOT_PURPLE_HERO"))
	else
		arg_168_0:nodeByName("lev_limit_txt"):setVisible(false)
	end
end

function var_0_0.awakeMissionInit(arg_169_0)
	local var_169_0 = arg_169_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_169_0 then
		local var_169_1 = xyd.tables.mission:sufMissionID(var_169_0)

		if var_169_1 and var_169_1 == 0 and xyd.getMissionGoIDs(var_169_0) == arg_169_0.campaignID then
			arg_169_0.isAwakeCampaign = true
			arg_169_0.awakeMission = arg_169_0.task:getTaskByID(var_169_0, xyd.TaskType.AWAKE)
			arg_169_0.awakeStage = xyd.tables.mission:stage(var_169_0)
			arg_169_0.awakeMissionGoalType = xyd.tables.mission:copyChallenges(var_169_0)
			arg_169_0.awakeHero = arg_169_0.selfPlayer:getHeroByTableID(xyd.tables.mission:beforeAwakenID(var_169_0))
		end

		if arg_169_0.awakeHero then
			arg_169_0.awakeHero.type = var_0_17.SELF_HERO
		end
	end

	if arg_169_0.isAwakeCampaign then
		local var_169_2 = ""
		local var_169_3 = arg_169_0.awakeMission.tableID

		if arg_169_0.awakeStage == 2 then
			var_169_2 = string.format(var_0_13:translation("AWAKE_SELECT_TEAM_TIP1"), arg_169_0.awakeHero:getName())
		elseif arg_169_0.awakeStage == 3 then
			if arg_169_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.SELF_KILL then
				var_169_2 = string.format(var_0_13:translation("AWAKE_SELECT_TEAM_TIP" .. arg_169_0.awakeMissionGoalType), arg_169_0.awakeHero:getName())
			elseif arg_169_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				var_169_2 = string.format(var_0_13:translation("AWAKE_SELECT_TEAM_TIP" .. arg_169_0.awakeMissionGoalType), xyd.tables.mission:challengeNums(var_169_3))
			elseif arg_169_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
				var_169_2 = string.format(var_0_13:translation("AWAKE_SELECT_TEAM_TIP" .. arg_169_0.awakeMissionGoalType), arg_169_0.awakeHero:getName())
			elseif arg_169_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALL_ALIVE then
				var_169_2 = var_0_13:translation("AWAKE_SELECT_TEAM_TIP" .. arg_169_0.awakeMissionGoalType)
			end
		end

		arg_169_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_169_0:nodeByName("lev_limit_txt"):setString(var_169_2)

		arg_169_0.preSelect_ = {}
		arg_169_0.preHeros_ = {}

		table.insert(arg_169_0.preSelect_, arg_169_0.awakeHero:getHeroID())
		table.insert(arg_169_0.preHeros_, arg_169_0.awakeHero)
	end
end

function var_0_0.sortTables(arg_170_0, arg_170_1)
	for iter_170_0 = 1, #arg_170_1 do
		table.sort(arg_170_1[iter_170_0], function(arg_171_0, arg_171_1)
			if arg_170_0.reinforcePartnerRatios[arg_171_0:getTableID()] and not arg_170_0.reinforcePartnerRatios[arg_171_1:getTableID()] then
				return true
			elseif arg_170_0.reinforcePartnerRatios[arg_171_1:getTableID()] and not arg_170_0.reinforcePartnerRatios[arg_171_0:getTableID()] then
				return false
			end

			if arg_170_0.type == xyd.SelectTeamType.INCUBUS or arg_170_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER or arg_170_0.type == xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER then
				local var_171_0 = arg_170_0:isBanned(arg_171_0)
				local var_171_1 = arg_170_0:isBanned(arg_171_1)

				if (var_171_0 or var_171_1) and (not var_171_0 or not var_171_1) then
					return var_171_1
				end
			elseif arg_170_0.type == xyd.SelectTeamType.ADVANCED then
				local var_171_2 = arg_170_0:isRecommend(arg_171_0)
				local var_171_3 = arg_170_0:isRecommend(arg_171_1)

				if (var_171_2 or var_171_3) and (not var_171_2 or not var_171_3) then
					return var_171_2
				end
			end

			if (arg_171_0.can_rent or arg_171_1.can_rent) and (not arg_171_0.can_rent or not arg_171_1.can_rent) then
				return arg_171_0.can_rent and not arg_171_1.can_rent
			end

			return xyd.heroNormalSort(arg_171_0, arg_171_1) or false
		end)
	end
end

function var_0_0.checkIsAssistBattle(arg_172_0)
	if arg_172_0.campaignType == xyd.CampaignType.NORMAL then
		local var_172_0, var_172_1 = arg_172_0:getBattleID()

		if var_172_1 then
			arg_172_0.preHeros_ = {}
			arg_172_0.preSelect_ = {}

			local var_172_2 = {}
			local var_172_3 = var_0_14:assistPartner(var_172_0)

			if not var_172_3 or not next(var_172_3) or #var_172_3 ~= 2 then
				return false
			end

			local var_172_4 = {}
			local var_172_5 = var_0_1.new()

			var_172_5:populateWithTableID(var_172_3[arg_172_0.assistID])
			table.insert(var_172_2, var_172_5)

			var_172_5.type = var_0_17.SELF_HERO
			var_172_5.isAssist = true
			arg_172_0.assistHeroID = var_172_5:getModelID()

			if #var_172_2 < xyd.MAX_TEAM_MEMBER_NUM then
				local var_172_6 = xyd.MAX_TEAM_MEMBER_NUM - #var_172_2

				for iter_172_0 = 1, var_172_6 do
					local var_172_7 = arg_172_0.selfPlayer:getHeroByID(iter_172_0)

					if var_172_7 then
						table.insert(var_172_2, var_172_7)
					end
				end

				table.sort(var_172_2, function(arg_173_0, arg_173_1)
					return arg_173_0:getDistance() < arg_173_1:getDistance()
				end)

				for iter_172_1, iter_172_2 in ipairs(var_172_2) do
					table.insert(arg_172_0.preSelect_, iter_172_2:getHeroID())
					table.insert(arg_172_0.preHeros_, iter_172_2)
				end

				return true
			end
		end

		return false
	end

	return false
end

function var_0_0.loadPreFormation(arg_174_0)
	if arg_174_0.type == xyd.SelectTeamType.TREASURE_DEFENSE or arg_174_0.type == xyd.SelectTeamType.ADVANCED or arg_174_0.type == xyd.SelectTeamType.ADJUST_TROOP or arg_174_0.type == xyd.SelectTeamType.PET_PRACTICE or arg_174_0.type == xyd.SelectTeamType.SUMMER_FIGHT_BOSS then
		return
	end

	if arg_174_0.type == xyd.SelectTeamType.CHALLENGE then
		arg_174_0.preHeros_ = {}
		arg_174_0.preSelect_ = {}

		if var_0_14:modeType(arg_174_0.battleID) == xyd.ChallengeType.KillSteal then
			local var_174_0 = var_0_1.new()

			var_174_0:populateWithTableID(var_0_14:killingHero(arg_174_0.battleID))
			table.insert(arg_174_0.preSelect_, -1)
			table.insert(arg_174_0.preHeros_, var_174_0)

			var_174_0.type = var_0_17.SELF_HERO
			var_174_0.isChallengeKillSteal_ = true

			return
		elseif var_0_14:modeType(arg_174_0.battleID) == xyd.ChallengeType.Protect then
			local var_174_1 = var_0_1.new()

			var_174_1:populateWithTableID(var_0_14:protectedHero(arg_174_0.battleID))
			table.insert(arg_174_0.preSelect_, -1)
			table.insert(arg_174_0.preHeros_, var_174_1)

			var_174_1.type = var_0_17.SELF_HERO
			var_174_1.isChallengeProtected_ = true

			return
		elseif var_0_14:modeType(arg_174_0.battleID) == xyd.ChallengeType.OneHeroKillAll then
			return
		end
	end

	if arg_174_0.selectSpType == xyd.SelectSpType.ASSIST and arg_174_0.assistID then
		local var_174_2 = var_0_1.new()

		var_174_2:populateWithTableID(arg_174_0.assistID)

		var_174_2.isAssist = true
		arg_174_0.preSelect_ = {
			-1
		}
		arg_174_0.preHeros_ = {
			var_174_2
		}

		return
	end

	if arg_174_0.type == xyd.SelectTeamType.HERO_PRESET then
		if arg_174_0.preHeros_ then
			for iter_174_0, iter_174_1 in pairs(arg_174_0.preHeros_) do
				iter_174_1.type = var_0_17.SELF_HERO
			end
		end

		return
	end

	if arg_174_0:checkIsAssistBattle() then
		arg_174_0.isAssistBattle = true

		return
	end

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		arg_174_0.preSelect_ = {
			1,
			2,
			3
		}
		arg_174_0.preHeros_ = {}

		table.insert(arg_174_0.preHeros_, arg_174_0.selfPlayer:getHeroByID(1))
		table.insert(arg_174_0.preHeros_, arg_174_0.selfPlayer:getHeroByID(2))
		table.insert(arg_174_0.preHeros_, arg_174_0.selfPlayer:getHeroByID(3))

		return
	end

	local var_174_3 = {}
	local var_174_4 = {}
	local var_174_5 = xyd.db.formation:getFormationData(arg_174_0.campaignType) or {}
	local var_174_6 = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
	local var_174_7 = var_174_5[1] or {}

	for iter_174_2, iter_174_3 in ipairs(var_174_7) do
		if arg_174_0.type == xyd.SelectTeamType.TWO_YEARS then
			local var_174_8 = var_174_6:getFightHeroes()

			for iter_174_4, iter_174_5 in pairs(var_174_8) do
				if iter_174_5:getHeroID() == iter_174_3 then
					iter_174_5.type = var_0_17.SELF_HERO

					table.insert(var_174_3, iter_174_3)
					table.insert(var_174_4, iter_174_5)
				end
			end
		elseif iter_174_3 < 0 and arg_174_0.type == xyd.SelectTeamType.MARCH then
			iter_174_3 = -iter_174_3

			for iter_174_6, iter_174_7 in pairs(arg_174_0.allTeamHeros) do
				if iter_174_7:getHeroID() == iter_174_3 and #var_174_3 < xyd.MAX_TEAM_MEMBER_NUM and not xyd.isInTable(arg_174_0.campaignLimit, iter_174_7:getFromType()) then
					iter_174_7.type = var_0_17.RENT_HERO

					table.insert(var_174_3, -iter_174_3)
					table.insert(var_174_4, iter_174_7)

					break
				end
			end
		else
			local var_174_9 = arg_174_0.selfPlayer:getHeroByID(iter_174_3)

			if var_174_9 and arg_174_0.campaignType == xyd.CampaignType.CONQUER_SCHOOL and arg_174_0:checkHeroIsConquerUsed(var_174_9) then
				return
			end

			if var_174_9 and #var_174_3 < xyd.MAX_TEAM_MEMBER_NUM and not xyd.isInTable(arg_174_0.campaignLimit, var_174_9:getFromType()) then
				var_174_9.type = var_0_17.SELF_HERO

				table.insert(var_174_3, iter_174_3)
				table.insert(var_174_4, var_174_9)
			end
		end
	end

	arg_174_0.preSelect_ = var_174_3
	arg_174_0.preHeros_ = var_174_4

	local var_174_10 = var_174_5[2] or {}

	for iter_174_8, iter_174_9 in ipairs(var_174_10) do
		local var_174_11 = arg_174_0.selfPlayer:getPetByID(iter_174_9)

		if var_174_11 and var_174_11 and #arg_174_0.prePet_ < xyd.MAX_PET_NUMBER then
			table.insert(arg_174_0.prePet_, var_174_11)
		end
	end
end

function var_0_0.willClose(arg_175_0)
	if arg_175_0.handle_ then
		var_0_12.unscheduleGlobal(arg_175_0.handle_)
	end

	if arg_175_0.handleDefense_ then
		var_0_12.unscheduleGlobal(arg_175_0.handleDefense_)
	end

	local var_175_0 = xyd.WindowManager.get():getWindow("guild_map_detail_window")

	if var_175_0 and arg_175_0.campaignType == xyd.CampaignType.GUILD then
		var_175_0.prepareTime = arg_175_0.guild:getPrepareTime(arg_175_0.campaignID)
		var_175_0.fightPlayerID = nil
		var_175_0.fightPlayerName = nil
		var_175_0.fightPlayerLev = nil
		var_175_0.fightPlayerAvatar = nil

		var_175_0:initPrepareWindow()
	end

	local var_175_1 = xyd.WindowManager.get():getWindow("pet_campaign")

	if var_175_1 and xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_ONE then
		var_175_1:playGuide(1)
	end

	local var_175_2 = xyd.StoryData.get():getGuideID()

	if var_175_2 >= xyd.GuideStoryType.GUIDE_FIGHT_5_TWO and var_175_2 < xyd.GuideStoryType.GUIDE_FIGHT_5_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_TWO, true)

		local var_175_3 = xyd.WindowManager.get():getWindow("map_detail_window")

		if var_175_3 and not tolua.isnull(var_175_3) then
			var_175_3:playGuide()
		end
	end
end

function var_0_0.canRentHero(arg_176_0)
	if arg_176_0.isMercenary and (arg_176_0.type ~= xyd.SelectTeamType.CHALLENGE or var_0_14:modeType(arg_176_0.battleID) ~= xyd.ChallengeType.OneHeroKillAll) then
		return true
	end

	return false
end

function var_0_0.isPet(arg_177_0)
	if not arg_177_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	if arg_177_0.banPet then
		return false
	end

	if arg_177_0.type == xyd.SelectTeamType.TREASURE_DEFENSE or arg_177_0.type == xyd.SelectTeamType.ADVANCED or arg_177_0.type == xyd.SelectTeamType.HERO_PRESET then
		return false
	end

	if arg_177_0.campaignType == xyd.CampaignType.NORMAL or arg_177_0.campaignType == xyd.CampaignType.SUPER or arg_177_0.campaignType == xyd.CampaignType.GUILD or arg_177_0.campaignType == xyd.CampaignType.NIAN_BOSS or arg_177_0.campaignType == xyd.CampaignType.WU or arg_177_0.campaignType == xyd.CampaignType.SHU or arg_177_0.campaignType == xyd.CampaignType.WEI or arg_177_0.campaignType == xyd.CampaignType.MOMIAN or arg_177_0.campaignType == xyd.CampaignType.WUMIAN or arg_177_0.campaignType == xyd.CampaignType.PROPHESY_JIUWEI or arg_177_0.campaignType == xyd.CampaignType.PROPHESY_NIAN or arg_177_0.campaignType == xyd.CampaignType.PROPHESY_QIUBITE or arg_177_0.campaignType == xyd.CampaignType.PROPHESY_YUAN or arg_177_0.campaignType == xyd.CampaignType.PROPHESY_SINGLE_DOG or arg_177_0.campaignType == xyd.CampaignType.PROPHESY_SONGZHONGJI or arg_177_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN or arg_177_0.campaignType == xyd.CampaignType.PET or arg_177_0.campaignType == xyd.CampaignType.REGION_ARENA or arg_177_0.campaignType == xyd.CampaignType.ILLUSION or arg_177_0.campaignType == xyd.CampaignType.CONQUER_SCHOOL or arg_177_0.campaignType == xyd.CampaignType.SAKURA2_COMPETITOR or arg_177_0.campaignType == xyd.CampaignType.SAKURA2_WAR or arg_177_0.campaignType == xyd.CampaignType.STUDENT_OVER or arg_177_0.campaignType == xyd.CampaignType.ZHUGE_NOTE or arg_177_0.campaignType == xyd.CampaignType.ZHUGE_BOSS or arg_177_0.campaignType == xyd.CampaignType.MEMORIES_OF_SCHOOL or arg_177_0.campaignType == xyd.CampaignType.SUMMER_FIGHT_BOSS or arg_177_0.campaignType == xyd.CampaignType.TWO_YEARS or arg_177_0.campaignType == xyd.CampaignType.ARENA or arg_177_0.campaignType == xyd.CampaignType.ADVENTURE_ILLUSION_SINGLE or arg_177_0.campaignType == xyd.CampaignType.ADVENTURE_DEFENSE or arg_177_0.campaignType == xyd.CampaignType.CHAPTER_BOSS or arg_177_0.campaignType == xyd.CampaignType.THIRD_ANNIVERSARY_BOSS or arg_177_0.campaignType == xyd.CampaignType.SUPER_RICH_CHALLENGE or arg_177_0.campaignType == xyd.CampaignType.CHOCOLATE then
		return true
	end

	return false
end

function var_0_0.formatRegionArenaHeros(arg_178_0, arg_178_1)
	for iter_178_0, iter_178_1 in pairs(arg_178_1) do
		if iter_178_1:isHaveAwakenItem() and not iter_178_1:isAwaken() then
			local var_178_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_178_1 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_178_2 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_178_0:renewHeroInfo(iter_178_1, var_178_0, var_178_1, var_178_2)
		elseif iter_178_1:isAwaken() then
			local var_178_3 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_178_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_178_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_178_0:renewHeroInfo(iter_178_1, var_178_3, var_178_4, var_178_5)
		else
			local var_178_6 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_178_7 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_178_8 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_178_0:renewHeroInfo(iter_178_1, var_178_6, var_178_7, var_178_8)
		end

		iter_178_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_178_1:updatePracticeAwardAttr()
	end
end

function var_0_0.formatRegionArenaPets(arg_179_0, arg_179_1)
	for iter_179_0, iter_179_1 in pairs(arg_179_1) do
		if iter_179_1:isHaveAwakenItem() and not iter_179_1:isAwaken() then
			local var_179_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_179_1 = {
				1,
				1,
				1
			}

			arg_179_0:renewPetInfo(iter_179_1, var_179_0, var_179_1)
		elseif iter_179_1:isAwaken() then
			local var_179_2 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_179_3 = {
				1,
				1,
				1
			}

			arg_179_0:renewPetInfo(iter_179_1, var_179_2, var_179_3)
		else
			local var_179_4 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_179_5 = {
				0,
				1,
				1
			}

			arg_179_0:renewPetInfo(iter_179_1, var_179_4, var_179_5)
		end

		iter_179_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_179_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_180_0, arg_180_1, arg_180_2, arg_180_3, arg_180_4)
	local var_180_0 = xyd.tables.misc.regionHeroColor

	arg_180_1.level_, arg_180_1.color_ = xyd.tables.misc.regionHeroLevel, var_180_0
	arg_180_1.skillLev_ = {}
	arg_180_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_180_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_180_1.color_ >= xyd.EquipQuality.GREEN then
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_180_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_180_1.color_ >= xyd.EquipQuality.BLUE then
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_180_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_180_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_180_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_180_1:isAwaken() then
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_180_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_180_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_180_1.equips_ = {}

	for iter_180_0 = 1, var_0_7 do
		table.insert(arg_180_1.equips_, tonumber(arg_180_4[iter_180_0]))
	end

	arg_180_1.fumo_ = {}

	for iter_180_1 = 1, var_0_7 do
		table.insert(arg_180_1.fumo_, tonumber(arg_180_3[iter_180_1]))
	end

	arg_180_1.fumoLev_ = {}

	for iter_180_2 = 1, var_0_7 do
		local var_180_1 = arg_180_1:getEquipByIndex(iter_180_2)

		table.insert(arg_180_1.fumoLev_, tonumber(var_180_1:getMaxFumoStar()))
	end
end

function var_0_0.renewPetInfo(arg_181_0, arg_181_1, arg_181_2, arg_181_3)
	local var_181_0 = 14

	arg_181_1.level_, arg_181_1.color_ = 90, var_181_0
	arg_181_1.skillLev_ = {}
	arg_181_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_181_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_181_1.color_ >= xyd.EquipQuality.GREEN then
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_181_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_181_1.color_ >= xyd.EquipQuality.BLUE then
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_181_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_181_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_181_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_181_1:isAwaken() then
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_181_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_181_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_181_1.equips_ = {}

	for iter_181_0 = 1, var_0_7 do
		table.insert(arg_181_1.equips_, tonumber(arg_181_3[iter_181_0]))
	end
end

function var_0_0.getHeros(arg_182_0)
	local var_182_0

	if arg_182_0.type and arg_182_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_182_0.type == xyd.SelectTeamType.REGION_ARENA or arg_182_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		var_182_0 = {}

		for iter_182_0, iter_182_1 in ipairs(arg_182_0.selfPlayer.heros_) do
			local var_182_1 = var_0_1.new()

			var_182_1:populate(iter_182_1:toParams())
			table.insert(var_182_0, var_182_1)
		end

		local var_182_2 = {}

		for iter_182_2, iter_182_3 in ipairs(arg_182_0.preHeros_) do
			local var_182_3 = var_0_1.new()

			var_182_3:populate(iter_182_3:toParams())
			table.insert(var_182_2, var_182_3)
		end

		local var_182_4 = arg_182_0.regionAwards

		arg_182_0:initRegionHeros(var_182_0, var_182_4)
		xyd.formatRegionArenaHeros(var_182_0)
		xyd.formatRegionArenaHeros(var_182_2)

		arg_182_0.preHeros_ = var_182_2
	elseif arg_182_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_182_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		local var_182_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)

		var_182_0 = {}

		for iter_182_4, iter_182_5 in ipairs(arg_182_0.selfPlayer.heros_) do
			local var_182_6 = var_0_1.new()

			var_182_6:populate(iter_182_5:toParams())
			table.insert(var_182_0, var_182_6)
		end

		var_182_5:formatNewHeros(var_182_0)

		local var_182_7 = {}

		for iter_182_6, iter_182_7 in ipairs(arg_182_0.preHeros_) do
			local var_182_8 = var_0_1.new()

			var_182_8:populate(iter_182_7:toParams())
			table.insert(var_182_7, var_182_8)
		end

		var_182_5:formatNewHeros(var_182_7)

		arg_182_0.preHeros_ = var_182_7
	elseif arg_182_0.type == xyd.SelectTeamType.SUMMER_FIGHT_BOSS then
		local var_182_9 = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)

		var_182_0 = clone(arg_182_0.selfPlayer.heros_)

		var_182_9:formatLvbuCampusHeros(var_182_0)
	elseif arg_182_0.type == xyd.SelectTeamType.TWO_YEARS then
		var_182_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS):getFightHeroes()
	elseif arg_182_0.type == xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS then
		var_182_0 = {}

		for iter_182_8, iter_182_9 in ipairs(arg_182_0.selfPlayer.heros_) do
			local var_182_10 = var_0_1.new()

			var_182_10:populate(iter_182_9:toParams())
			table.insert(var_182_0, var_182_10)
		end

		arg_182_0.thirdAnniversary:formatNewHeros(var_182_0)

		local var_182_11 = {}

		for iter_182_10, iter_182_11 in ipairs(arg_182_0.preHeros_) do
			local var_182_12 = var_0_1.new()

			var_182_12:populate(iter_182_11:toParams())
			table.insert(var_182_11, var_182_12)
		end

		arg_182_0.thirdAnniversary:formatNewHeros(var_182_11)

		arg_182_0.preHeros_ = var_182_11
	else
		var_182_0 = arg_182_0.selfPlayer.heros_
	end

	return var_182_0
end

function var_0_0.getPets(arg_183_0)
	local var_183_0

	if arg_183_0.type and arg_183_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_183_0.type == xyd.SelectTeamType.REGION_ARENA or arg_183_0.type == xyd.SelectTeamType.TWO_YEARS or arg_183_0.type == xyd.SelectTeamType.SUPER_RICH_CHALLENGE then
		var_183_0 = {}

		for iter_183_0, iter_183_1 in ipairs(arg_183_0.selfPlayer.collectedPets) do
			local var_183_1 = var_0_2.new()

			var_183_1:populate(iter_183_1:toParams())

			if arg_183_0.type == xyd.SelectTeamType.TWO_YEARS then
				var_183_1.star_ = xyd.MAX_STAR_LEVEL
			end

			table.insert(var_183_0, var_183_1)
		end

		local var_183_2 = {}

		for iter_183_2, iter_183_3 in ipairs(arg_183_0.prePet_) do
			local var_183_3 = var_0_2.new()

			var_183_3:populate(iter_183_3:toParams())

			if arg_183_0.type == xyd.SelectTeamType.TWO_YEARS then
				var_183_3.star_ = xyd.MAX_STAR_LEVEL
			end

			table.insert(var_183_2, var_183_3)
		end

		xyd.formatRegionArenaPets(var_183_0)
		xyd.formatRegionArenaPets(var_183_2)

		arg_183_0.prePet_ = var_183_2
	elseif arg_183_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_183_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		local var_183_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)

		var_183_0 = {}

		for iter_183_4, iter_183_5 in ipairs(arg_183_0.selfPlayer.collectedPets) do
			local var_183_5 = var_0_2.new()

			var_183_5:populate(iter_183_5:toParams())
			table.insert(var_183_0, var_183_5)
		end

		local var_183_6 = {}

		for iter_183_6, iter_183_7 in ipairs(arg_183_0.prePet_) do
			local var_183_7 = var_0_2.new()

			var_183_7:populate(iter_183_7:toParams())
			table.insert(var_183_6, var_183_7)
		end

		var_183_4:formatNewPets(var_183_0)
		var_183_4:formatNewPets(var_183_6)

		arg_183_0.prePet_ = var_183_6
	elseif arg_183_0.type == xyd.SelectTeamType.THIRD_ANNIVERSARY_BOSS then
		var_183_0 = {}

		for iter_183_8, iter_183_9 in ipairs(arg_183_0.selfPlayer.collectedPets) do
			local var_183_8 = var_0_2.new()

			var_183_8:populate(iter_183_9:toParams())
			table.insert(var_183_0, var_183_8)
		end

		local var_183_9 = {}

		for iter_183_10, iter_183_11 in ipairs(arg_183_0.prePet_) do
			local var_183_10 = var_0_2.new()

			var_183_10:populate(iter_183_11:toParams())
			table.insert(var_183_9, var_183_10)
		end

		arg_183_0.thirdAnniversary:formatNewPets(var_183_0)
		arg_183_0.thirdAnniversary:formatNewPets(var_183_9)

		arg_183_0.prePet_ = var_183_9
	else
		var_183_0 = arg_183_0.selfPlayer.collectedPets
	end

	return var_183_0
end

function var_0_0.initRegionPets(arg_184_0, arg_184_1)
	return
end

function var_0_0.initRegionHeros(arg_185_0, arg_185_1, arg_185_2, arg_185_3)
	for iter_185_0, iter_185_1 in pairs(arg_185_2) do
		local var_185_0 = arg_185_0:checkHeroExit(arg_185_1, iter_185_1.table_id)

		if not var_185_0 and arg_185_3 then
			-- block empty
		else
			if iter_185_1.is_summon == 1 and not var_185_0 then
				var_185_0 = var_0_1.new()

				var_185_0:initUnCollected(iter_185_1.table_id)
				table.insert(arg_185_1, var_185_0)
			end

			if iter_185_1.add_star > 0 then
				local var_185_1 = var_185_0:getStar()

				if not xyd.isSuperHero(var_185_0) then
					if var_185_1 + iter_185_1.add_star > xyd.MAX_STAR_LEVEL then
						var_185_0:setStar(xyd.MAX_STAR_LEVEL)
					else
						var_185_0:setStar(var_185_1 + iter_185_1.add_star)
					end
				elseif var_185_1 + iter_185_1.add_star > xyd.SUPER_HERO_TOTAL_STARS then
					var_185_0:setStar(xyd.SUPER_HERO_TOTAL_STARS)
				else
					var_185_0:setStar(var_185_1 + iter_185_1.add_star)
				end
			end

			if iter_185_1.is_awake == 1 and not var_185_0:isAwaken() then
				var_185_0:setTableID(xyd.tables.hero:afterAwaken(iter_185_1.table_id))
			end
		end
	end
end

function var_0_0.checkHeroExit(arg_186_0, arg_186_1, arg_186_2)
	local var_186_0 = false

	for iter_186_0, iter_186_1 in pairs(arg_186_1) do
		local var_186_1 = iter_186_1:getTableID()

		if var_186_1 == arg_186_2 then
			var_186_0 = iter_186_1

			break
		end

		if iter_186_1:isAwaken() then
			var_186_1 = iter_186_1:beforeAwakenID()
		end

		if var_186_1 == arg_186_2 then
			var_186_0 = iter_186_1

			break
		end
	end

	return var_186_0
end

function var_0_0.isRecommend(arg_187_0, arg_187_1)
	local var_187_0 = arg_187_1:getTableID()

	if var_0_15:beforeAwaken(var_187_0) > 0 then
		var_187_0 = var_0_15:beforeAwaken(var_187_0)
	end

	for iter_187_0 = 1, #arg_187_0.recommendHeros do
		if var_187_0 == arg_187_0.recommendHeros[iter_187_0] then
			return true
		end
	end

	return false
end

function var_0_0.initRecommend(arg_188_0)
	local var_188_0 = arg_188_0:nodeByName("list_layer"):getContentSize()

	arg_188_0:nodeByName("list_layer"):setContentSize(var_188_0.width, var_188_0.height - 140)

	local var_188_1 = cc.p(arg_188_0:nodeByName("lev_limit_txt"):getPosition())

	arg_188_0:nodeByName("lev_limit_txt"):setPosition(var_188_1.x, var_188_1.y - 130)
	arg_188_0:nodeByName("recommend_layer"):setVisible(true)
	arg_188_0:nodeByName("recommend_txt"):setString(var_0_13:translation("RECOMMENDED_HERO"))

	for iter_188_0 = 1, #arg_188_0.recommendHeros do
		xyd.setAvatarBorder(arg_188_0.recommendHeros[iter_188_0], arg_188_0:nodeByName("recommend_hero" .. iter_188_0), true, var_0_15:initialStar(arg_188_0.recommendHeros[iter_188_0]))
	end
end

function var_0_0.isBanned(arg_189_0, arg_189_1)
	local var_189_0 = arg_189_1:getTableID()

	if var_0_15:beforeAwaken(var_189_0) > 0 then
		var_189_0 = var_0_15:beforeAwaken(var_189_0)
	end

	for iter_189_0 = 1, #arg_189_0.bannedHeros do
		if var_189_0 == arg_189_0.bannedHeros[iter_189_0] then
			return true
		end
	end

	return false
end

function var_0_0.checkHeroIsNotUse(arg_190_0, arg_190_1)
	if arg_190_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_190_0:checkHeroIsConquerUsed(arg_190_1) then
		return true
	end

	return false
end

function var_0_0.checkHeroIsConquerUsed(arg_191_0, arg_191_1)
	if arg_191_0.conquerUsedTeam and arg_191_0.conquerUsedTeam.heroIDs then
		local var_191_0 = arg_191_0.conquerUsedTeam.heroIDs

		for iter_191_0, iter_191_1 in pairs(var_191_0) do
			if iter_191_1 == arg_191_1:getHeroID() then
				return true
			end
		end
	end

	return false
end

function var_0_0.checkPetIsConquerUsed(arg_192_0, arg_192_1)
	if arg_192_0.conquerUsedTeam and arg_192_0.conquerUsedTeam.petIDs then
		local var_192_0 = arg_192_0.conquerUsedTeam.petIDs

		for iter_192_0, iter_192_1 in pairs(var_192_0) do
			if iter_192_1 == arg_192_1:getPetID() then
				return true
			end
		end
	end

	return false
end

function var_0_0.checkHeroIsSeal(arg_193_0, arg_193_1)
	if arg_193_0.sealHeroID and arg_193_0.sealHeroID > 0 and arg_193_1:getFirstTableID() == arg_193_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.checkCanPresetTeam(arg_194_0)
	if arg_194_0.type == xyd.SelectTeamType.HERO_PRESET or arg_194_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_194_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		return false
	end

	return true
end

function var_0_0.startSakura2CompetitorBattle(arg_195_0)
	local var_195_0 = {
		herosA = {}
	}

	for iter_195_0, iter_195_1 in ipairs(arg_195_0.team_) do
		table.insert(var_195_0.herosA, iter_195_1.data)
	end

	var_195_0.petsA = {}

	for iter_195_2, iter_195_3 in ipairs(arg_195_0.petSelect_) do
		table.insert(var_195_0.petsA, iter_195_3)
	end

	var_195_0.campaignType = xyd.CampaignType.SAKURA2_COMPETITOR
	var_195_0.campaignID = 0
	var_195_0.herosB = {
		arg_195_0.enemyHeroes_
	}
	var_195_0.petsB = {}

	table.insert(var_195_0.petsB, arg_195_0.enemyPets_)

	var_195_0.battleID = xyd.MapBattleID.ARENA
	var_195_0.formation = arg_195_0:getFormationStr(var_195_0.herosA)

	xyd.pushBattleScene(var_195_0)
end

function var_0_0.startSakura2WarBattle(arg_196_0)
	local var_196_0 = {
		rentFlag = rentFlag,
		campaignType = arg_196_0.campaignType,
		campaignID = arg_196_0.campaignID,
		itemComposeID = arg_196_0.itemComposeID,
		battleID = xyd.tables.activitySakura2Campaign:fightId(arg_196_0.campaignID),
		herosA = {}
	}

	for iter_196_0, iter_196_1 in ipairs(arg_196_0.team_) do
		iter_196_1.data.type = iter_196_1.type

		if iter_196_1.type == var_0_17.RENT_HERO then
			rentFlag = true
		end

		table.insert(var_196_0.herosA, iter_196_1.data)
	end

	var_196_0.petsA = {}

	for iter_196_2, iter_196_3 in ipairs(arg_196_0.petSelect_) do
		table.insert(var_196_0.petsA, iter_196_3)
	end

	local var_196_1 = var_0_14:monsters(var_196_0.battleID)

	var_196_0.herosB = {}
	var_196_0.petsB = {}

	for iter_196_4 = 1, #var_196_1 do
		local var_196_2 = {}

		for iter_196_5, iter_196_6 in ipairs(var_196_1[iter_196_4]) do
			if xyd.tables.hero:summonType(iter_196_6) ~= 4 then
				local var_196_3 = arg_196_0.sakura:populateMonsterWithTableID(iter_196_6)

				table.insert(var_196_2, var_196_3)
			else
				local var_196_4 = arg_196_0.sakura:populatePetWithTableID(iter_196_6)

				table.insert(var_196_0.petsB, var_196_4)
			end
		end

		if next(var_196_2) then
			table.insert(var_196_0.herosB, var_196_2)
		end
	end

	var_196_0.formation = arg_196_0:getFormationStr(var_196_0.herosA)

	arg_196_0.sakura:setPreHerosFormation(var_196_0.formation)

	if var_196_0.petsA and next(var_196_0.petsA) then
		arg_196_0.sakura:setPrePetFormation(var_196_0.petsA[1]:getPetID())
	end

	local var_196_5 = xyd.tables.activitySakura2Campaign:preWarStory(arg_196_0.campaignID)

	if var_196_5 and var_196_5 ~= "" then
		local function var_196_6()
			xyd.pushBattleScene(var_196_0)
		end

		xyd.WindowManager.get():openWindow("school_story_talk", {
			callback = var_196_6,
			talk_id = var_196_5
		})
	else
		xyd.pushBattleScene(var_196_0)
	end
end

function var_0_0.startChapterBossFight(arg_198_0)
	local var_198_0 = {
		rentFlag = rentFlag,
		chapter_id = arg_198_0.chapter,
		campaignType = arg_198_0.campaignType,
		battleID = arg_198_0.battleID,
		herosA = {}
	}
	local var_198_1 = {}
	local var_198_2 = false

	for iter_198_0, iter_198_1 in ipairs(arg_198_0.team_) do
		iter_198_1.data.type = iter_198_1.type

		if iter_198_1.type == var_0_17.RENT_HERO then
			var_198_2 = true
		else
			table.insert(var_198_1, iter_198_1.data)
		end

		table.insert(var_198_0.herosA, iter_198_1.data)
	end

	var_198_0.petsA = {}

	for iter_198_2, iter_198_3 in ipairs(arg_198_0.petSelect_) do
		table.insert(var_198_0.petsA, iter_198_3)
	end

	var_198_0.rentFlag = var_198_2
	var_198_0.formation = arg_198_0:getFormationStr(var_198_0.herosA)

	local var_198_3 = xyd.tables.battle:monsters(var_198_0.battleID)

	var_198_0.herosB = {}

	local var_198_4 = arg_198_0.selfPlayer.chapterEvents[arg_198_0.chapter] or {}
	local var_198_5 = {}

	for iter_198_4, iter_198_5 in ipairs(var_198_3[1]) do
		local var_198_6 = var_0_1.new()

		var_198_6:populateWithTableID(iter_198_5)

		local var_198_7 = {
			total_hp = var_198_4.record,
			hp = var_198_4.val
		}

		var_198_7.health = 1
		var_198_7.mp = 0
		var_198_6.healthStatus = var_198_7

		table.insert(var_198_5, var_198_6)
	end

	table.insert(var_198_0.herosB, var_198_5)

	local var_198_8 = {
		formation = arg_198_0:getFormationStr(var_198_1)
	}
	local var_198_9

	if #arg_198_0.petTeam_ ~= 0 and not arg_198_0.isSelectMerPet then
		var_198_9 = arg_198_0.petTeam_[1].data:getPetID()
	end

	var_198_8.pet_id = var_198_9

	if arg_198_0.isSelectMerPet then
		var_198_0.rent_pet_id = arg_198_0.selectMerPet:getPetID()
	end

	if arg_198_0.selectMerPet then
		var_198_8.rent_pet_player_id = arg_198_0.selectMerPet.player_id
		var_198_8.rent_pet_id = tostring(arg_198_0.selectMerPet:getPetID())
	end

	if arg_198_0.selectMerHero then
		var_198_8.rent_player_id = arg_198_0.selectMerHero.player_id
		var_198_8.rent_formation = tostring(arg_198_0.selectMerHero:getHeroID())
	end

	var_198_8.chapter_id = arg_198_0.chapter
	var_198_0.fightParams = var_198_8

	xyd.Backend.get():request(xyd.mid.START_CHAPTER_BOSS_FIGHT, var_198_8, function(arg_199_0, arg_199_1)
		if arg_199_0 == xyd.error.OK then
			if arg_198_0.selectMerHero then
				arg_198_0.guild:setUseRent(arg_198_0.selectMerHero)
			end

			if arg_198_0.selectMerPet then
				arg_198_0.guild:setUseRentPet(arg_198_0.selectMerPet)
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
				params = {
					window = "map_window",
					status = {
						chapter_type = arg_198_0.chapterType,
						chapter = var_198_0.chapter_id
					}
				}
			})
			xyd.WindowManager.get():retainHistory()
			xyd.pushBattleScene(var_198_0)
		end
	end)
end

function var_0_0.startThirdAnniversaryBossBattle(arg_200_0)
	local var_200_0 = false
	local var_200_1 = {
		herosA = {},
		herosB = {}
	}
	local var_200_2 = {}

	for iter_200_0, iter_200_1 in ipairs(arg_200_0.team_) do
		iter_200_1.data.type = iter_200_1.type

		if iter_200_1.type == var_0_17.RENT_HERO then
			var_200_0 = true
		else
			table.insert(var_200_2, iter_200_1.data)
		end

		table.insert(var_200_1.herosA, iter_200_1.data)
	end

	var_200_1.rentFlag = var_200_0
	var_200_1.campaignType = arg_200_0.campaignType
	var_200_1.battleID = xyd.tables.thirdAnniversaryBoss:battleID(arg_200_0.thirdAnniversary.day_count)
	var_200_1.petsA = {}

	for iter_200_2, iter_200_3 in ipairs(arg_200_0.petSelect_) do
		table.insert(var_200_1.petsA, iter_200_3)
	end

	local var_200_3 = arg_200_0:getFormationStr(var_200_2)
	local var_200_4 = {
		formation = var_200_3
	}
	local var_200_5

	if #arg_200_0.petTeam_ ~= 0 and not arg_200_0.isSelectMerPet then
		var_200_5 = arg_200_0.petTeam_[1].data:getPetID()
	end

	var_200_4.pet_id = var_200_5

	if arg_200_0.isSelectMerPet then
		var_200_1.rent_pet_id = arg_200_0.selectMerPet:getPetID()
	end

	if arg_200_0.selectMerPet then
		var_200_4.rent_pet_player_id = arg_200_0.selectMerPet.player_id
		var_200_4.rent_pet_id = tostring(arg_200_0.selectMerPet:getPetID())
	end

	if arg_200_0.selectMerHero then
		var_200_4.rent_player_id = arg_200_0.selectMerHero.player_id
		var_200_4.rent_formation = tostring(arg_200_0.selectMerHero:getHeroID())
	end

	var_200_1.fightParams = var_200_4
	var_200_1.formation = var_200_3

	local var_200_6 = {}

	table.insert(var_200_6, arg_200_0.thirdAnniversary:getBossID())

	var_200_1.herosB = {}

	if not arg_200_0.thirdAnniversary then
		local var_200_7 = {}
	end

	local var_200_8 = {}

	for iter_200_4, iter_200_5 in ipairs(var_200_6) do
		local var_200_9 = var_0_1.new()

		var_200_9:populateWithTableID(iter_200_5)
		table.insert(var_200_8, var_200_9)
	end

	table.insert(var_200_1.herosB, var_200_8)
	xyd.Backend.get():request(xyd.mid.THIRD_ANNIVERSARY_BOSS_START_FIGHT, var_200_4, function(arg_201_0, arg_201_1)
		if arg_201_0 == xyd.error.OK then
			if arg_200_0.selectMerHero then
				arg_200_0.guild:setUseRent(arg_200_0.selectMerHero)
			end

			arg_200_0.selfPlayer:getBackpack():removeItem({
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
			xyd.pushBattleScene(var_200_1)
		else
			arg_200_0.battleBegan = false
		end
	end, nil, false, true)
end

function var_0_0.setCloseBtn(arg_202_0)
	if arg_202_0.type == xyd.SelectTeamType.ADVENTURE_DEFENSE then
		arg_202_0:nodeByName("close"):addTouchEventListener(function(arg_203_0, arg_203_1)
			if arg_203_1 == ccui.TouchEventType.ended then
				local var_203_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
				local var_203_1 = {
					table_id = xyd.AdventureEventType.DEFENSE,
					monster_pos = arg_202_0.monsterPos
				}

				var_203_0:quitRoomFight(var_203_1, function(arg_204_0, arg_204_1)
					if arg_204_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_202_0)
					end
				end)
			end
		end)
	end
end

function var_0_0.updateDefenseTimeCount(arg_205_0, arg_205_1)
	local var_205_0 = arg_205_1

	if arg_205_0.handleDefense_ then
		var_0_12.unscheduleGlobal(arg_205_0.handleDefense_)
	end

	local var_205_1 = xyd.tables.misc.adventureDefenseSelectTeamTimeLimit

	if var_205_1 <= 0 then
		var_205_0:setString(string.format(var_0_13:translation("GUILD_PREPARE_FIGHT"), 0))

		return
	end

	var_205_0:setString(string.format(var_0_13:translation("GUILD_PREPARE_FIGHT"), var_205_1))

	arg_205_0.handleDefense_ = var_0_12.scheduleGlobal(function()
		if var_205_0 and not tolua.isnull(var_205_0) then
			var_205_1 = var_205_1 - 1

			var_205_0:setString(string.format(var_0_13:translation("GUILD_PREPARE_FIGHT"), var_205_1))

			if var_205_1 == 0 then
				if arg_205_0.handleDefense_ then
					var_0_12.unscheduleGlobal(arg_205_0.handleDefense_)

					arg_205_0.handleDefense_ = nil
				end

				local var_206_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ADVENTURE_EVENT)
				local var_206_1 = {
					table_id = xyd.AdventureEventType.DEFENSE,
					monster_pos = arg_205_0.monsterPos
				}

				var_206_0:quitRoomFight(var_206_1, function(arg_207_0, arg_207_1)
					if arg_207_0 == xyd.error.OK then
						xyd.WindowManager.get():closeWindow(arg_205_0)
					end
				end)
			end
		elseif arg_205_0.handleDefense_ then
			var_0_12.unscheduleGlobal(arg_205_0.handleDefense_)

			arg_205_0.handleDefense_ = nil
		end
	end, 1)
end

return var_0_0
