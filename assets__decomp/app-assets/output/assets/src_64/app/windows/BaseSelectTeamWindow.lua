local var_0_0 = class("BaseSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 30
local var_0_4 = 5
local var_0_5 = 4
local var_0_6 = 6
local var_0_7 = 50
local var_0_8 = 90
local var_0_9 = import("framework.scheduler")
local var_0_10 = xyd.tables.translation
local var_0_11 = xyd.tables.battle
local var_0_12 = xyd.tables.hero

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

function var_0_0.initEnemys(arg_8_0)
	local var_8_0 = 1
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
		else
			xyd.setAvatarBorder(iter_8_3, arg_8_0:nodeByName("enemy_hero_" .. var_8_0))
		end

		var_8_0 = var_8_0 + 1
	end

	if arg_8_0.enemyPets_ then
		if arg_8_0.hide_counts and arg_8_0.hide_counts >= 1 then
			local var_8_3 = xyd.AssetLoader.get():loadSprite("windows/across_arena/new_/pet_hide.png")

			xyd.displaySpriteOnContainer(var_8_3, arg_8_0:nodeByName("pet_back_enemy"), true)
		else
			xyd.setPetAvatar(arg_8_0:nodeByName("pet_back_enemy"), arg_8_0.enemyPets_, 100)
		end
	end
end

function var_0_0.layout(arg_10_0)
	arg_10_0:specialLayout()
	arg_10_0:initRightMenu()
	arg_10_0:initLeftMenu()
	arg_10_0:initTopRentMenu()
	arg_10_0:selectHeros()
	arg_10_0:selectPets()
	arg_10_0:initListview()
	arg_10_0:initTextOfList()
end

function var_0_0.specialLayout(arg_11_0)
	arg_11_0:nodeByName("recommend_layer"):setVisible(false)

	if arg_11_0.showEnemy then
		arg_11_0:nodeByName("battle_team_bg"):setVisible(true)
		arg_11_0:nodeByName("list_layer"):height(300)
		arg_11_0:initEnemys()
	else
		arg_11_0:nodeByName("battle_team_bg"):setVisible(false)
	end
end

function var_0_0.initRightMenu(arg_12_0)
	arg_12_0.rightMenuButtons_ = {}

	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_all"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_qianpai"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_zhongpai"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_houpai"))
	table.insert(arg_12_0.rightMenuButtons_, arg_12_0:nodeByName("button_filter"))

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

	if arg_12_0:checkCanPresetTeam() then
		arg_12_0:nodeByName("button_preset"):setZoomScale(0.3)
		arg_12_0:nodeByName("button_preset"):addTouchEventListener(function(arg_14_0, arg_14_1)
			if arg_14_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				if not arg_12_0.isHeroPreset then
					arg_12_0.isHeroPreset = true
					arg_12_0.leftMenuType_ = xyd.LeftMenuType.SELF_HERO

					arg_12_0:updateTopRentMenu()
					arg_12_0:selectHeros()
					arg_12_0:selectPets()

					if arg_12_0.leftMenuButtons_ then
						for iter_14_0, iter_14_1 in ipairs(arg_12_0.leftMenuButtons_) do
							iter_14_1:setBrightStyle(iter_14_1.menu_type == xyd.LeftMenuType.SELF_HERO and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
						end
					end

					for iter_14_2 = 1, #arg_12_0.rightMenuButtons_ do
						arg_12_0.rightMenuButtons_[iter_14_2]:setBrightStyle(ccui.BrightStyle.normal)
					end

					arg_12_0.heroList_:reload()
				end

				arg_12_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.highlight)
			end
		end)
	else
		arg_12_0:nodeByName("button_preset"):setVisible(false)
		arg_12_0:nodeByName("preset"):setVisible(false)
	end

	arg_12_0:nodeByName("button_filter"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_12_0.leftMenuType_ ~= xyd.LeftMenuType.SELF_HERO then
			return
		end

		xyd.WindowManager.get():openWindow("hero_filter")
	end)
end

function var_0_0.initLeftMenu(arg_16_0)
	arg_16_0:nodeByName("zhandui"):hide()
	arg_16_0:nodeByName("button_zhandui"):hide()

	arg_16_0:nodeByName("button_zhandui").menu_type = xyd.LeftMenuType.SELF_HERO

	arg_16_0:nodeByName("yongbing"):hide()
	arg_16_0:nodeByName("button_yongbing"):hide()

	arg_16_0:nodeByName("button_yongbing").menu_type = xyd.LeftMenuType.RENT_HERO

	arg_16_0:nodeByName("pet"):hide()
	arg_16_0:nodeByName("button_pet"):hide()

	arg_16_0:nodeByName("button_pet").menu_type = xyd.LeftMenuType.SELF_PET
	arg_16_0.leftMenuType_ = xyd.LeftMenuType.SELF_HERO
	arg_16_0.leftMenuButtons_, arg_16_0.leftMenuText_ = {}, {}

	table.insert(arg_16_0.leftMenuButtons_, arg_16_0:nodeByName("button_zhandui"))
	table.insert(arg_16_0.leftMenuText_, arg_16_0:nodeByName("zhandui"))

	if arg_16_0:canRentHero() then
		table.insert(arg_16_0.leftMenuButtons_, arg_16_0:nodeByName("button_yongbing"))
		table.insert(arg_16_0.leftMenuText_, arg_16_0:nodeByName("yongbing"))
	end

	if arg_16_0:isPet() then
		arg_16_0:nodeByName("rate_bg"):setVisible(false)
		table.insert(arg_16_0.leftMenuButtons_, arg_16_0:nodeByName("button_pet"))
		table.insert(arg_16_0.leftMenuText_, arg_16_0:nodeByName("pet"))
	else
		arg_16_0:nodeByName("avatar_pet1"):hide()

		if arg_16_0.type == xyd.SelectTeamType.ADVANCED then
			arg_16_0:nodeByName("rate_bg"):setVisible(true)
		else
			arg_16_0:nodeByName("rate_bg"):setVisible(false)
			arg_16_0:nodeByName("text_bg"):setLocalZOrder(10)
			arg_16_0:nodeByName("text_bg"):y(arg_16_0:nodeByName("text_bg"):getY() - 120)
		end
	end

	if #arg_16_0.leftMenuButtons_ <= 1 then
		return
	end

	for iter_16_0 = 1, #arg_16_0.leftMenuButtons_ do
		arg_16_0.leftMenuButtons_[iter_16_0]:show()
		arg_16_0.leftMenuText_[iter_16_0]:show()
		arg_16_0.leftMenuButtons_[iter_16_0]:setZoomScale(0.3)

		local var_16_0 = arg_16_0.leftMenuButtons_[1]:getY() - 85 * (iter_16_0 - 1)

		arg_16_0.leftMenuButtons_[iter_16_0]:y(var_16_0)
		arg_16_0.leftMenuText_[iter_16_0]:y(var_16_0)
		arg_16_0.leftMenuButtons_[iter_16_0]:addTouchEventListener(function(arg_17_0, arg_17_1)
			if arg_17_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_17_0, iter_17_1 in ipairs(arg_16_0.leftMenuButtons_) do
					iter_17_1:setBrightStyle(arg_17_0 == iter_17_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_16_0.leftMenuType_ = arg_17_0.menu_type
				arg_16_0.isHeroPreset = false
				arg_16_0.rentMenuType = xyd.RentMenuType.RENT_HERO

				arg_16_0:updateTopRentMenu()
				arg_16_0:selectHeros()
				arg_16_0:selectPets()
				arg_16_0:refreshSelectedHeroClass()
			end
		end)
	end
end

function var_0_0.initTopRentMenu(arg_18_0)
	arg_18_0:nodeByName("top_rent_container"):setVisible(false)

	arg_18_0.rentMenuType = xyd.RentMenuType.RENT_HERO

	if not arg_18_0:canRentHero() then
		return
	end

	arg_18_0:nodeByName("btn_rent_hero"):addTouchEventListener(function(arg_19_0, arg_19_1)
		if arg_19_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_18_0.rentMenuType = xyd.RentMenuType.RENT_HERO

			arg_18_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_18_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_18_0:selectPets()
			arg_18_0.heroList_:reload()
		end
	end)
	arg_18_0:nodeByName("btn_rent_pet"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended and not arg_18_0.isClickRentPet then
			arg_18_0.isClickRentPet = true

			xyd.playButtonSound()

			arg_18_0.rentMenuType = xyd.RentMenuType.RENT_PET

			arg_18_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.normal)
			arg_18_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_18_0:initRentPets(function()
				arg_18_0:selectPets()
				arg_18_0.heroList_:reload()

				arg_18_0.isClickRentPet = false
			end)
		end
	end)
end

function var_0_0.initRentPets(arg_22_0, arg_22_1)
	if not arg_22_0.isLoadAllTeamPets then
		local var_22_0 = {}

		arg_22_0.guild:loadAllTeamPets(var_22_0, function(arg_23_0)
			arg_22_0.allTeamPets = {}

			if arg_23_0 == xyd.error.OK then
				for iter_23_0, iter_23_1 in ipairs(arg_22_0.guild:getAllTeamPets()) do
					local var_23_0 = var_0_2.new()

					var_23_0:populate(iter_23_1)

					var_23_0.player_name = iter_23_1.player_name
					var_23_0.rent_need_mana = iter_23_1.rent_need_mana
					var_23_0.can_rent = iter_23_1.can_rent
					var_23_0.player_id = iter_23_1.player_id

					table.insert(arg_22_0.allTeamPets, var_23_0)
				end

				arg_22_0.isLoadAllTeamPets = true
			end

			arg_22_0:initPets(arg_22_0.allTeamPets, xyd.PetType.RENT_PET)

			if arg_22_1 then
				arg_22_1()
			end
		end)
	elseif arg_22_1 then
		arg_22_1()
	end
end

function var_0_0.updateTopRentMenu(arg_24_0)
	if arg_24_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO and arg_24_0:isPet() then
		arg_24_0:nodeByName("top_rent_container"):setVisible(true)
		arg_24_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_24_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)

		if not arg_24_0.ischangeListRect then
			if arg_24_0.campaignType == xyd.CampaignType.GUILD then
				var_0_7 = 70

				arg_24_0:nodeByName("lev_limit_txt"):setPositionY(arg_24_0:nodeByName("lev_limit_txt"):getPositionY() - var_0_7)
			end

			local var_24_0 = arg_24_0.heroList_:getViewRect()
			local var_24_1 = cc.rect(0, 0, var_24_0.width, var_24_0.height - var_0_7)

			arg_24_0.heroList_:setViewRect(var_24_1)

			arg_24_0.ischangeListRect = true
		end
	else
		arg_24_0:nodeByName("top_rent_container"):setVisible(false)

		if arg_24_0.ischangeListRect then
			if arg_24_0.campaignType == xyd.CampaignType.GUILD then
				var_0_7 = 70

				arg_24_0:nodeByName("lev_limit_txt"):setPositionY(arg_24_0:nodeByName("lev_limit_txt"):getPositionY() + var_0_7)
			end

			local var_24_2 = arg_24_0.heroList_:getViewRect()
			local var_24_3 = cc.rect(0, 0, var_24_2.width, var_24_2.height + var_0_7)

			arg_24_0.heroList_:setViewRect(var_24_3)
		end

		arg_24_0.ischangeListRect = false
	end
end

function var_0_0.initPetCell(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_0.totalPet_[arg_25_2]

	if arg_25_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		local var_25_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/cloud_city/rent_pet_avatar.csb")

		arg_25_1:addChild(var_25_1)

		arg_25_1.type = xyd.PetType.RENT_PET

		var_25_1:setName("rent_cell")

		local var_25_2 = var_25_1:getChildByName("container")

		arg_25_1:align(display.CENTER):size(var_25_2:getContentSize().width, var_25_2:getContentSize().height)

		local var_25_3 = var_25_2:getChildByName("avatar")

		var_25_2:getChildByName("player_name"):setString(var_25_0.player_name)
		var_25_2:getChildByName("rent_cost"):setString(var_25_0.rent_need_mana)
		var_25_3:getChildByName("yongbing_tubiao"):setPosition(cc.p(90, 100))
		xyd.setPetAvatar(var_25_3, var_25_0, 100)
		var_25_3:setPositionY(var_25_3:getPositionY() + 15)

		if not var_25_0.can_rent then
			var_25_2:getChildByName("can_not_rent"):setString(var_0_10:translation("CAN_NOT_BORROW"))
			var_25_3:getChildByName("layout"):getChildByName("chosen"):setVisible(false)
			var_25_3:getChildByName("layout"):getChildByName("avatar_mask"):setVisible(true)
		else
			var_25_2:getChildByName("can_not_rent"):setVisible(false)
		end
	else
		arg_25_1:align(display.CENTER):size(146, 146)
		xyd.setPetAvatar(arg_25_1, var_25_0, 100)

		arg_25_1.type = xyd.PetType.SELF_PET

		arg_25_0:initPetCellStatus(arg_25_1, var_25_0)
	end

	arg_25_1.data = var_25_0

	arg_25_1:setTouchEnabled(true)
	arg_25_1:setTouchSwallowEnabled(false)
	arg_25_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		arg_25_0:buttonHandler(nil, arg_25_1, arg_26_0)

		if arg_26_0.name == "began" then
			arg_25_0.startClick_ = true
			arg_25_0.prevX_ = arg_26_0.x
			arg_25_0.prevY_ = arg_26_0.y
		elseif arg_26_0.name == "moved" then
			if math.abs(arg_26_0.y - arg_25_0.prevY_) > 5 or math.abs(arg_26_0.x - arg_25_0.prevX_) > 5 then
				arg_25_0.startClick_ = false
			end
		elseif arg_26_0.name == "ended" and arg_25_0.startClick_ and not arg_25_0.battleBegan then
			arg_25_0:beforeClickPetAvatar(arg_25_1, var_25_0)
		end

		return true
	end)
	arg_25_0:updatePetCellMask(arg_25_1, var_25_0)
end

function var_0_0.updatePetCellMask(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0

	if arg_27_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		var_27_0 = arg_27_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_27_0 = arg_27_1:getChildByName("layout")
	end

	local var_27_1 = var_27_0:getChildByName("avatar_mask")
	local var_27_2 = var_27_0:getChildByName("chosen")

	for iter_27_0, iter_27_1 in ipairs(arg_27_0.petTeam_) do
		if iter_27_1.data:getTableID() == arg_27_2:getTableID() and iter_27_1.data.player_name == arg_27_2.player_name then
			arg_27_0.petTeam_[iter_27_0].iniCell_ = arg_27_1
			arg_27_1.teamNo_ = iter_27_0

			var_27_1:setVisible(true)
			var_27_2:setVisible(true)

			break
		end
	end
end

function var_0_0.initPetCellStatus(arg_28_0, arg_28_1, arg_28_2)
	return
end

function var_0_0.initPresetCell(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_0.presetTeams[arg_29_2].team
	local var_29_1 = arg_29_0.presetTeams[arg_29_2].teamName
	local var_29_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list/hero_preset/preset_item_2.csb")
	local var_29_3 = var_29_2:getChildByName("container")
	local var_29_4 = var_29_3:getContentSize()

	arg_29_1:setContentSize(var_29_4)
	var_29_2:addTo(arg_29_1)
	var_29_3:getChildByName("text_name"):setString(var_29_1)

	local var_29_5 = var_29_3:getChildByName("hero_list")
	local var_29_6 = 0

	for iter_29_0 = 1, #var_29_0 do
		local var_29_7 = var_29_0[iter_29_0]
		local var_29_8 = display.newNode()

		var_29_8:setContentSize(var_0_8, var_0_8)
		xyd.setAvatarBorder(var_29_7, var_29_8)
		var_29_8:addTo(var_29_5)
		var_29_8:setPositionX(var_29_6)

		var_29_6 = var_29_6 + var_0_8 + 10

		local var_29_9 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")

		var_29_9:addTo(var_29_8)
		var_29_9:setPosition(cc.p(0, 0))
		var_29_9:setAnchorPoint(cc.p(0, 0))
		var_29_9:setName("avatar_mask")
		var_29_9:setScale(var_0_8 / var_29_9:getWidth())
		var_29_9:setVisible(false)

		local var_29_10 = {
			size = 26,
			color = cc.c3b(206, 109, 109),
			align = cc.ui.TEXT_ALIGN_CENTER
		}
		local var_29_11 = xyd.AssetLoader.get():loadLabel(var_29_10)

		var_29_11:addTo(var_29_8)
		var_29_11:setAnchorPoint(cc.p(0.5, 1))
		var_29_11:setPosition(cc.p(var_0_8 / 2, var_0_8))
		var_29_11:setVisible(false)

		local var_29_12 = false

		if arg_29_0:checkHeroIsDead(var_29_7) then
			var_29_9:setVisible(true)
			var_29_11:setLocalZOrder(3)
			var_29_11:setVisible(true)
			var_29_11:setString(var_0_10:translation("ALREADY_DEAD"))
			var_29_11:enableOutline(cc.c4b(0, 0, 0), 2)

			var_29_12 = true
		end

		var_29_7.isDead = var_29_12

		if arg_29_0:isBanned(var_29_7) then
			local var_29_13 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_29_13:setAnchorPoint(cc.p(0.5, 1))
			var_29_13:setPosition(var_0_8 / 2, var_0_8)
			var_29_8:addChild(var_29_13)
			var_29_9:setVisible(true)
		end

		arg_29_0:updateHeroCell(var_29_8, var_29_7, false, true)
	end

	var_29_3:getChildByName("btn_use"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_29_0:checkPresetTeamCanUse(arg_29_2) then
				local var_30_0 = arg_29_0.selfPlayer:getSaveTeamStr()
				local var_30_1 = arg_29_0.selfPlayer:getSaveTeamIDs(var_30_0)

				arg_29_0.preSelect_ = var_30_1[arg_29_2]
				arg_29_0.preHeros_ = var_29_0

				arg_29_0:showPresetTeam(arg_29_2)
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_31_0)
	local var_31_0 = arg_31_0.team_

	arg_31_0.team_ = {}
	arg_31_0.select_ = {}

	arg_31_0:updateScore()
	arg_31_0:initPreHeros(true)

	local var_31_1 = arg_31_0.team_
	local var_31_2 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_32_0 = 1, #var_31_0 do
				local var_32_0 = var_31_0[iter_32_0]
				local var_32_1, var_32_2 = arg_31_0:nodeByName("avatar" .. iter_32_0):getPosition()

				arg_31_0:moveFadeOutAction(var_32_1, var_32_2, var_32_0)

				if var_32_0.type == xyd.LeftMenuType.RENT_HERO then
					arg_31_0.isSelectMerHero = false
					arg_31_0.selectMerHero = nil
				end
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_31_3 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_33_0 = 1, #var_31_1 do
				local var_33_0 = var_31_1[iter_33_0]

				var_33_0:show()

				local var_33_1, var_33_2 = arg_31_0:nodeByName("avatar" .. iter_33_0):getPosition()

				arg_31_0:moveFadeInAction(var_33_1, var_33_2, var_33_0)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_31_0:runAction(transition.sequence({
		var_31_2,
		var_31_3
	}))
end

function var_0_0.checkPresetTeamCanUse(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_0.presetTeams[arg_34_1].team

	for iter_34_0, iter_34_1 in ipairs(var_34_0) do
		if not arg_34_0:canHeroJoinBattle(iter_34_1) or arg_34_0:isBanned(iter_34_1) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_10:translation("PRESET_MEMBER_NOT_USE")
			})

			return false
		end
	end

	return true
end

function var_0_0.checkHeroIsDead(arg_35_0, arg_35_1)
	local var_35_0 = false
	local var_35_1 = false

	if arg_35_1.type == xyd.LeftMenuType.RENT_HERO then
		var_35_1 = true
	end

	local var_35_2 = arg_35_0:getListStatus(var_35_1, arg_35_1)

	if var_35_2 and next(var_35_2) ~= nil then
		local var_35_3 = var_35_2

		if not var_35_3 or not var_35_3.health or var_35_3.health == 0 then
			-- block empty
		elseif var_35_3.health == 1 and var_35_3.hp >= 1 then
			-- block empty
		else
			var_35_0 = true
		end
	end

	return var_35_0
end

function var_0_0.beforeClickPetAvatar(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = arg_36_2.rent_need_mana

	if var_36_0 and var_36_0 > arg_36_0.selfPlayer.mana and arg_36_2.can_rent then
		local var_36_1 = var_0_10:translation("MERCENARY_ERROR_TIP4")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_36_1
		})

		return
	end

	if arg_36_1.isAnimated_ or not arg_36_1.teamNo_ and #arg_36_0.petTeam_ > xyd.MAX_PET_NUMBER then
		return
	elseif arg_36_1.type == xyd.PetType.RENT_PET and arg_36_0.isSelectMerHero then
		local var_36_2 = var_0_10:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_36_2
		})

		return
	elseif not arg_36_1.teamNo_ and #arg_36_0.petTeam_ == xyd.MAX_PET_NUMBER then
		local var_36_3 = arg_36_0.petTeam_[1]

		arg_36_0:clickPetBottomAvatarWithoutAnimation(var_36_3, function()
			arg_36_0:clickPetAvatar(arg_36_1, no_animation)
		end)

		return
	end

	arg_36_0:clickPetAvatar(arg_36_1)
end

function var_0_0.checkClickNewPetAvatar(arg_38_0, arg_38_1, arg_38_2)
	if arg_38_0.rentMenuType == xyd.RentMenuType.RENT_PET and arg_38_2.can_rent == false then
		arg_38_1.isAnimated_ = false

		return false
	end

	return true
end

function var_0_0.clickPetAvatar(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0

	if arg_39_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		var_39_0 = arg_39_1:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
	else
		var_39_0 = arg_39_1:getChildByName("layout")
	end

	local var_39_1 = var_39_0:getChildByName("avatar_mask")
	local var_39_2 = var_39_0:getChildByName("chosen")
	local var_39_3 = arg_39_1:convertToWorldSpace(cc.p(0, 0))
	local var_39_4 = var_39_3.x
	local var_39_5 = var_39_3.y

	arg_39_1.isAnimated_ = true

	if arg_39_1.teamNo_ then
		local var_39_6 = arg_39_0.petTeam_[arg_39_1.teamNo_]

		arg_39_0:moveFadeOutAction(var_39_4, var_39_5, var_39_6, function()
			arg_39_1.isAnimated_ = false
		end)
		var_39_1:setVisible(false)
		var_39_2:setVisible(false)

		for iter_39_0 = #arg_39_0.petTeam_, arg_39_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_39_0.petTeam_[iter_39_0])

			local var_39_7, var_39_8 = arg_39_0:nodeByName("avatar_pet" .. iter_39_0 - 1):getPosition()

			transition.moveTo(arg_39_0.petTeam_[iter_39_0], {
				time = 0.3,
				x = var_39_7,
				y = var_39_8
			})

			arg_39_0.petTeam_[iter_39_0].iniCell_.teamNo_ = iter_39_0 - 1
		end

		if arg_39_1.type == xyd.PetType.RENT_PET then
			arg_39_0.isSelectMerPet = false
			arg_39_0.selectMerPet = nil
		end

		table.remove(arg_39_0.petTeam_, arg_39_1.teamNo_)
		table.remove(arg_39_0.petSelect_, arg_39_1.teamNo_)

		arg_39_1.teamNo_ = nil
	elseif not arg_39_1.teamNo_ and #arg_39_0.petTeam_ < xyd.MAX_PET_NUMBER then
		local var_39_9 = arg_39_1.data

		if not arg_39_2 and var_0_12:chosenSound(var_39_9:getTableID()) ~= "" then
			xyd.AssetDownload.get():preloadCharacterSound({
				var_39_9:getTableID()
			}, function()
				return
			end, true)
			audio.playSound(var_0_12:chosenSound(var_39_9:getTableID()), false)
		end

		if not arg_39_0:checkClickNewPetAvatar(arg_39_1, var_39_9) then
			return false
		end

		local var_39_10 = arg_39_0:initPetBottomCell(var_39_9)

		var_39_10.iniCell_ = arg_39_1

		var_39_10:pos(var_39_4, var_39_5)
		var_39_10:addTo(arg_39_0)
		var_39_10:setTouchEnabled(true)
		var_39_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_42_0)
			if arg_42_0.name == "ended" and not arg_39_0.battleBegan then
				arg_39_0:clickPetBottomAvatar(var_39_10)
			end

			return true
		end)

		if arg_39_1.type == xyd.PetType.RENT_PET then
			arg_39_0.isSelectMerPet = true
			arg_39_0.selectMerPet = var_39_9
		end

		arg_39_1.teamNo_ = arg_39_0:getPetTeamNo(var_39_10)

		for iter_39_1 = arg_39_1.teamNo_, #arg_39_0.petTeam_ do
			local var_39_11, var_39_12 = arg_39_0:nodeByName("avatar_pet" .. iter_39_1):getPosition()

			if arg_39_2 then
				arg_39_0.petTeam_[iter_39_1]:pos(var_39_11, var_39_12)

				arg_39_1.isAnimated_ = false
			elseif iter_39_1 ~= arg_39_1.teamNo_ then
				local var_39_13 = arg_39_0.petTeam_[iter_39_1]

				transition.stopTarget(var_39_13)
				transition.moveTo(var_39_13, {
					time = 0.3,
					x = var_39_11,
					y = var_39_12,
					onComplete = function()
						var_39_13.iniCell_.isAnimated_ = false
						var_39_13.isAnimated_ = false
					end
				})
			else
				local var_39_14 = arg_39_0.petTeam_[iter_39_1]

				transition.stopTarget(var_39_14)

				var_39_10.isAnimated_ = true

				transition.moveTo(var_39_14, {
					time = 0.3,
					x = var_39_11,
					y = var_39_12,
					onComplete = function()
						arg_39_1.isAnimated_ = false
						var_39_10.isAnimated_ = false
					end
				})
			end

			arg_39_0.petTeam_[iter_39_1].iniCell_.teamNo_ = iter_39_1
		end

		var_39_1:setVisible(true)
		var_39_2:setVisible(true)
	end

	arg_39_0:updateScore()
end

function var_0_0.initHeroCell(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = arg_45_0.totalHero_[arg_45_0.selectedHeroClass_[arg_45_0.leftMenuType_]][arg_45_2]

	var_45_0.healthStatus = nil

	local var_45_1
	local var_45_2 = false

	if arg_45_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO then
		var_45_2 = true

		local var_45_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/hire_hero/select_mercenary_item.csb")

		var_45_1 = var_45_3:getChildByName("container")

		var_45_1:getChildByName("player_name"):setString(var_45_0.player_name)

		arg_45_1.player_name = var_45_0.player_name
		arg_45_1.can_rent = var_45_0.can_rent
		arg_45_1.type = xyd.LeftMenuType.RENT_HERO

		var_45_1:getChildByName("rent_cost"):setString(var_45_0.rent_need_mana)
		var_45_1:getChildByName("yongbing_tubiao"):setVisible(true)
		var_45_1:getChildByName("is_can_rent"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		var_45_1:getChildByName("is_can_rent"):setString(var_0_10:translation("CAN_NOT_BORROW"))
		arg_45_1:setContentSize(var_45_3:getChildByName("container"):getContentSize())
		xyd.setAvatarBorder(var_45_0, var_45_1:getChildByName("avatar"))

		local var_45_4 = var_45_1:getChildByName("chosen")

		var_45_4:setLocalZOrder(100)
		var_45_4:setVisible(false)

		local var_45_5 = var_45_1:getChildByName("avatar_mask")

		var_45_5:setLocalZOrder(2)
		var_45_5:setVisible(false)

		if var_45_0.can_rent then
			var_45_1:getChildByName("is_can_rent"):setVisible(false)
			var_45_5:setVisible(false)
		else
			var_45_1:getChildByName("is_can_rent"):setVisible(true)
			var_45_1:getChildByName("is_can_rent"):setColor(cc.c3b(255, 165, 159))
			var_45_1:getChildByName("is_can_rent"):enableOutline(cc.c4b(0, 0, 0, 105), 1)
			var_45_1:getChildByName("is_can_rent"):setLocalZOrder(100)
			var_45_5:setVisible(true)
		end

		arg_45_1:addChild(var_45_3)
		var_45_3:setName("yongbingCell")
	else
		var_45_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

		var_45_1:getChildByName("yongbing_tubiao"):setVisible(false)

		local var_45_6 = var_45_1:getChildByName("background"):getContentSize()

		var_45_1:setContentSize(var_45_6)
		arg_45_1:setContentSize(var_45_6)
		xyd.setAvatarBorder(var_45_0, var_45_1:getChildByName("avatar"))

		local var_45_7 = var_45_1:getChildByName("chosen")

		var_45_7:setLocalZOrder(100)
		var_45_7:setVisible(false)

		local var_45_8 = var_45_1:getChildByName("avatar_mask")

		var_45_8:setLocalZOrder(2)
		var_45_8:setVisible(false)

		arg_45_1.type = xyd.LeftMenuType.SELF_HERO

		var_45_1:getChildByName("is_can_rent"):setVisible(false)

		for iter_45_0 = 1, 3 do
			var_45_1:getChildByName("team" .. iter_45_0):setVisible(false)
		end

		var_45_1:setName("layout")
		arg_45_1:addChild(var_45_1)
	end

	arg_45_0:initHeroStatus(arg_45_1, var_45_1, var_45_0, var_45_2)
	arg_45_0:updateHeroCell(var_45_1, var_45_0, var_45_2)
	arg_45_0:updateHeroMask(arg_45_1, var_45_1, var_45_0, var_45_2)

	if arg_45_0:isBanned(var_45_0) then
		local var_45_9 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

		var_45_9:setAnchorPoint(cc.p(0.5, 1))
		var_45_9:setPosition(70, 120)
		var_45_1:addChild(var_45_9)
		var_45_1:getChildByName("avatar_mask"):setVisible(true)

		return
	end

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
			arg_45_0:beforeClickAvatar(arg_45_1)
		end

		return true
	end)
end

function var_0_0.updateHeroCell(arg_47_0, arg_47_1, arg_47_2, arg_47_3, arg_47_4)
	if arg_47_0:checkHeroIsNotUse(arg_47_2) then
		mask:setVisible(true)

		local var_47_0 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

		var_47_0:setPosition(85, 120)
		arg_47_1:addChild(var_47_0, 11)
	end
end

function var_0_0.updateHeroMask(arg_48_0, arg_48_1, arg_48_2, arg_48_3, arg_48_4)
	local var_48_0 = arg_48_2:getChildByName("chosen")
	local var_48_1 = arg_48_2:getChildByName("avatar_mask")

	for iter_48_0, iter_48_1 in ipairs(arg_48_0.select_) do
		if iter_48_1:getTableID() == arg_48_3:getTableID() and iter_48_1.player_name == arg_48_3.player_name then
			arg_48_1.teamNo_ = iter_48_0

			var_48_0:setVisible(true)
			var_48_1:setVisible(true)

			arg_48_0.team_[iter_48_0].iniCell_ = arg_48_1
			arg_48_0.team_[iter_48_0].iniCellVisible_ = false

			break
		end
	end
end

function var_0_0.getListStatus(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0

	if arg_49_0.heroStatus_ then
		if arg_49_1 then
			var_49_0 = arg_49_0.heroStatus_.rent_list
		else
			var_49_0 = arg_49_0.heroStatus_.self_list
		end
	end

	if var_49_0 and next(var_49_0) then
		return var_49_0[tostring(arg_49_2:getHeroID())]
	end

	return nil
end

function var_0_0.initHeroStatus(arg_50_0, arg_50_1, arg_50_2, arg_50_3, arg_50_4)
	arg_50_2:getChildByName("lv_txt"):setString(arg_50_3:getLevel())

	local var_50_0 = arg_50_2:getChildByName("name_txt") or arg_50_2:getChildByName("name_text")

	var_50_0:setString(arg_50_3:getName())
	var_50_0:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_50_3:getColor()] ~= "" then
		local var_50_1 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_50_0:getX() + var_50_0:getWidth() / 2 - 10,
			y = var_50_0:getY(),
			color = xyd.color.HERO_QUALITY[arg_50_3:getColor()],
			text = xyd.Color2Level[arg_50_3:getColor()]
		}
		local var_50_2 = xyd.AssetLoader.get():loadLabel(var_50_1)

		var_50_2:addTo(arg_50_2)
		var_50_2:align(display.CENTER_LEFT)
		var_50_2:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_50_0:x(var_50_0:getX() - 15)
	end

	local var_50_3 = arg_50_2:getChildByName("hp_bar")
	local var_50_4 = arg_50_2:getChildByName("mp_bar")
	local var_50_5 = arg_50_2:getChildByName("dead_txt") or arg_50_2:getChildByName("dead_text")

	var_50_5:setString(var_0_10:translation("ALREADY_DEAD"))

	if var_50_5 then
		var_50_5:setVisible(false)
	end

	local var_50_6 = arg_50_2:getChildByName("avatar_mask")
	local var_50_7 = false
	local var_50_8 = arg_50_0:getListStatus(arg_50_4, arg_50_3)

	if var_50_8 and var_50_8.health then
		local var_50_9 = var_50_8

		arg_50_3.healthStatus = var_50_9

		if var_50_9 and var_50_9.health then
			local var_50_10 = 0
			local var_50_11 = 0

			if var_50_9.health == 0 then
				var_50_10 = 100
				var_50_11 = 0
			elseif var_50_9.health == 1 and var_50_9.hp >= 1 then
				var_50_10 = var_50_9.hp / arg_50_3:getTotalAttr(xyd.AttributeType.HP) * 100
				var_50_11 = var_50_9.mp / 10
			else
				var_50_10 = 0
				var_50_11 = 0

				var_50_6:setVisible(true)
				var_50_5:setLocalZOrder(3)
				var_50_5:setVisible(true)
				var_50_5:enableOutline(cc.c4b(0, 0, 0), 2)
				var_50_5:getVirtualRenderer():setAdditionalKerning(2)

				var_50_7 = true
			end

			var_50_3:setPercent(var_50_10)
			var_50_3:setVisible(true)
			var_50_4:setPercent(var_50_11)
			var_50_4:setVisible(true)
		end
	elseif (not var_50_8 or not var_50_8.health) and arg_50_0:showHpBarIgnoreHealth() then
		arg_50_3.healthStatus = {}
		arg_50_3.healthStatus.health = 0
		arg_50_3.healthStatus.hp = 0
		arg_50_3.healthStatus.mp = 0

		local var_50_12 = 100
		local var_50_13 = 0

		var_50_3:setPercent(var_50_12)
		var_50_3:setVisible(true)
		var_50_4:setPercent(var_50_13)
		var_50_4:setVisible(true)
	else
		var_50_3:hide()
		var_50_4:hide()
		arg_50_2:getChildByName("hp_di"):hide()
		arg_50_2:getChildByName("mp_di"):hide()
	end

	arg_50_3.isDead = var_50_7

	arg_50_2:setPosition(cc.p(0, 0))

	arg_50_1.data = arg_50_3

	arg_50_2:setPosition(cc.p(0, 0))
	arg_50_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_50_1:setTouchSwallowEnabled(false)
	arg_50_1:setTouchEnabled(true)
end

function var_0_0.showHpBarIgnoreHealth(arg_51_0)
	if arg_51_0.campaignType == xyd.CampaignType.MARCH then
		return true
	end

	return false
end

function var_0_0.updateHeroBottomCell(arg_52_0, arg_52_1, arg_52_2)
	if arg_52_2.isAssist and arg_52_0.campaignType == xyd.CampaignType.NORMAL then
		local var_52_0 = xyd.AssetLoader.get():loadSprite("windows/battle/text_assist.png")

		var_52_0:addTo(arg_52_1)
		var_52_0:setAnchorPoint(cc.p(1, 1))
		var_52_0:setPosition(cc.p(cellSize.width, cellSize.height))
		var_52_0:setLocalZOrder(99)

		arg_52_0.assistHeroNode = arg_52_1

		arg_52_1:setVisible(false)
	end
end

function var_0_0.initBottomCell(arg_53_0, arg_53_1)
	local var_53_0 = display.newNode()
	local var_53_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")
	local var_53_2 = var_53_1:getChildByName("background"):getContentSize()

	var_53_1:setContentSize(var_53_2)
	var_53_0:setContentSize(var_53_2)
	xyd.setAvatarBorder(arg_53_1, var_53_1:getChildByName("avatar"))

	local var_53_3 = var_53_1:getChildByName("chosen")

	var_53_3:setLocalZOrder(100)
	var_53_3:setVisible(false)

	local var_53_4 = var_53_1:getChildByName("avatar_mask")

	var_53_4:setLocalZOrder(2)
	var_53_4:setVisible(false)

	local var_53_5 = var_53_1:getChildByName("yongbing_tubiao")
	local var_53_6 = false

	if arg_53_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO or arg_53_1.type == xyd.LeftMenuType.RENT_HERO then
		var_53_5:setVisible(true)

		var_53_0.type = xyd.LeftMenuType.RENT_HERO
		var_53_6 = true
	else
		var_53_5:setVisible(false)

		var_53_0.type = xyd.LeftMenuType.SELF_HERO
	end

	for iter_53_0 = 1, 3 do
		var_53_1:getChildByName("team" .. iter_53_0):setVisible(false)
	end

	arg_53_0:initHeroStatus(var_53_0, var_53_1, arg_53_1, var_53_6)
	arg_53_0:updateHeroBottomCell(var_53_0, arg_53_1)
	var_53_1:setName("layout")
	var_53_0:addChild(var_53_1)

	return var_53_0
end

function var_0_0.initPetBottomCell(arg_54_0, arg_54_1)
	local var_54_0 = display.newNode()

	var_54_0:size(146, 146)
	var_54_0:align(display.CENTER)

	var_54_0.data = arg_54_1
	var_54_0.type = xyd.PetType.SELF_PET

	xyd.setPetAvatar(var_54_0, arg_54_1, 100)

	if arg_54_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		local var_54_1 = xyd.AssetLoader.get():loadSprite("windows/cloud_city/yongbing_tubiao.png")

		var_54_1:addTo(var_54_0)
		var_54_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_54_1:setPosition(cc.p(110, 120))

		var_54_0.type = xyd.PetType.RENT_PET
	end

	return var_54_0
end

function var_0_0.delegate(arg_55_0, ...)
	if arg_55_0.isHeroPreset then
		return arg_55_0:presetDelegate(...)
	elseif arg_55_0.leftMenuType_ == xyd.LeftMenuType.SELF_PET or arg_55_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO and arg_55_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		return arg_55_0:petDelegate(...)
	end

	return arg_55_0:heroDelegate(...)
end

function var_0_0.heroDelegate(arg_56_0, arg_56_1, arg_56_2, arg_56_3)
	if arg_56_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
		var_0_4 = 5
	else
		var_0_4 = 4
	end

	local var_56_0 = math.ceil(#arg_56_0.totalHero_[arg_56_0.selectedHeroClass_[arg_56_0.leftMenuType_]] / var_0_4)

	if cc.ui.UIListView.COUNT_TAG == arg_56_2 then
		return var_56_0
	elseif cc.ui.UIListView.CELL_TAG == arg_56_2 then
		local var_56_1
		local var_56_2
		local var_56_3
		local var_56_4 = arg_56_0.heroList_:dequeueItem()

		if not var_56_4 then
			var_56_4 = arg_56_0.heroList_:newItem()
		else
			var_56_4:removeAllChildren()
		end

		local var_56_5 = display.newNode()

		var_56_5:setTouchSwallowEnabled(false)

		for iter_56_0 = 1, var_0_4 do
			local var_56_6 = (arg_56_3 - 1) * var_0_4 + iter_56_0

			if var_56_6 > #arg_56_0.totalHero_[arg_56_0.selectedHeroClass_[arg_56_0.leftMenuType_]] then
				break
			end

			var_56_3 = display.newNode()

			arg_56_0:initHeroCell(var_56_3, var_56_6)

			local var_56_7 = var_56_3:getContentSize().width
			local var_56_8 = var_56_3:getContentSize().height
			local var_56_9 = (arg_56_0.heroList_.viewRect_.width - var_56_7 * var_0_4) / (var_0_4 + 1)

			var_56_3:pos(var_56_9 * iter_56_0 + (iter_56_0 - 1) * var_56_7 + var_56_7 / 2, var_0_3 + var_56_8 / 2 - 2)
			var_56_5:addChild(var_56_3)

			arg_56_0.heroCells_[var_56_6] = var_56_3
		end

		var_56_5:setContentSize(cc.size(arg_56_0.heroList_.viewRect_.width, var_56_3:getContentSize().height + var_0_3))
		var_56_4:setItemSize(arg_56_0.heroList_.viewRect_.width, var_56_3:getContentSize().height + var_0_3)
		var_56_4:addContent(var_56_5)

		return var_56_4
	end
end

function var_0_0.petDelegate(arg_57_0, arg_57_1, arg_57_2, arg_57_3)
	if arg_57_0.leftMenuType_ == xyd.LeftMenuType.SELF_PET then
		var_0_5 = 5
	else
		var_0_5 = 4
	end

	local var_57_0 = math.ceil(#arg_57_0.totalPet_ / var_0_5)

	if cc.ui.UIListView.COUNT_TAG == arg_57_2 then
		return var_57_0
	elseif cc.ui.UIListView.CELL_TAG == arg_57_2 then
		local var_57_1
		local var_57_2
		local var_57_3
		local var_57_4 = arg_57_0.heroList_:dequeueItem()

		if not var_57_4 then
			var_57_4 = arg_57_0.heroList_:newItem()
		else
			var_57_4:removeAllChildren()
		end

		local var_57_5 = display.newNode()

		var_57_5:setTouchSwallowEnabled(false)

		for iter_57_0 = 1, var_0_5 do
			local var_57_6 = (arg_57_3 - 1) * var_0_5 + iter_57_0

			if var_57_6 > #arg_57_0.totalPet_ then
				break
			end

			var_57_3 = display.newNode()

			arg_57_0:initPetCell(var_57_3, var_57_6)

			local var_57_7 = var_57_3:getContentSize().width
			local var_57_8 = var_57_3:getContentSize().height
			local var_57_9 = (arg_57_0.heroList_.viewRect_.width - var_57_7 * var_0_5) / (var_0_5 + 1)

			var_57_3:align(display.CENTER, var_57_9 * iter_57_0 + (iter_57_0 - 1) * var_57_7 + var_57_7 / 2, var_57_8 / 2)
			var_57_5:addChild(var_57_3)
		end

		var_57_5:setContentSize(cc.size(arg_57_0.heroList_.viewRect_.width, var_57_3:getContentSize().height))
		var_57_4:setItemSize(arg_57_0.heroList_.viewRect_.width, var_57_3:getContentSize().height)
		var_57_4:addContent(var_57_5)

		return var_57_4
	end
end

function var_0_0.presetDelegate(arg_58_0, arg_58_1, arg_58_2, arg_58_3)
	local var_58_0 = #arg_58_0.presetTeams

	if cc.ui.UIListView.COUNT_TAG == arg_58_2 then
		return var_58_0
	elseif cc.ui.UIListView.CELL_TAG == arg_58_2 then
		local var_58_1
		local var_58_2
		local var_58_3
		local var_58_4 = arg_58_0.heroList_:dequeueItem()

		if not var_58_4 then
			var_58_4 = arg_58_0.heroList_:newItem()
		else
			var_58_4:removeAllChildren()
		end

		local var_58_5 = display.newNode()

		var_58_5:setTouchSwallowEnabled(false)

		local var_58_6 = display.newNode()

		arg_58_0:initPresetCell(var_58_6, arg_58_3)
		var_58_5:addChild(var_58_6)
		var_58_5:setContentSize(cc.size(arg_58_0.heroList_.viewRect_.width, var_58_6:getContentSize().height))
		var_58_4:setItemSize(arg_58_0.heroList_.viewRect_.width, var_58_6:getContentSize().height)
		var_58_4:addContent(var_58_5)

		return var_58_4
	end
end

function var_0_0.refreshSelectedHeroClass(arg_59_0)
	for iter_59_0 = 1, #arg_59_0.rightMenuButtons_ do
		if iter_59_0 == arg_59_0.selectedHeroClass_[arg_59_0.leftMenuType_] then
			arg_59_0.rightMenuButtons_[iter_59_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_59_0.rightMenuButtons_[iter_59_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end

	arg_59_0:nodeByName("button_preset"):setBrightStyle(ccui.BrightStyle.normal)
	arg_59_0.heroList_:removeAllItems()

	if arg_59_0.selectedHeroClass_[arg_59_0.leftMenuType_] == xyd.DistanceType.FILTER then
		-- block empty
	elseif arg_59_0.selectedHeroClass_[arg_59_0.leftMenuType_] ~= xyd.DistanceType.ALL then
		for iter_59_1, iter_59_2 in ipairs(arg_59_0.select_) do
			if iter_59_2:getDistanceType() ~= arg_59_0.selectedHeroClass_[arg_59_0.leftMenuType_] then
				arg_59_0.team_[iter_59_1].iniCellVisible_ = true
			end
		end
	end

	if not arg_59_0.isFirstInitPreHero then
		arg_59_0.isFirstInitPreHero = true

		arg_59_0:initPreHeros()
		arg_59_0:initPrePets()
	end

	arg_59_0.heroList_:reload()
end

function var_0_0.buttonHandler(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	if not arg_60_2 or not arg_60_2:getParent() then
		return
	end

	if arg_60_3.name == "ended" then
		transition.stopTarget(arg_60_2)
		arg_60_2:setScale(1)

		if arg_60_1 then
			arg_60_1(arg_60_2, eventType)
		end
	elseif arg_60_3.name == "began" then
		local var_60_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_60_2:runAction(var_60_0)

		return true
	elseif arg_60_3.name == "cancled" then
		transition.stopTarget(arg_60_2)
		arg_60_2:setScale(1)
	end
end

function var_0_0.initPrePets(arg_61_0)
	if not arg_61_0:isPet() then
		return
	end

	for iter_61_0, iter_61_1 in ipairs(arg_61_0.prePet_) do
		local var_61_0, var_61_1 = arg_61_0:nodeByName("avatar_pet" .. iter_61_0):getPosition()
		local var_61_2 = arg_61_0:initPetBottomCell(iter_61_1)

		var_61_2:pos(var_61_0, var_61_1)
		var_61_2:addTo(arg_61_0)
		var_61_2:setTouchEnabled(true)
		var_61_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_62_0)
			if arg_62_0.name == "ended" and not arg_61_0.battleBegan then
				arg_61_0:clickPetBottomAvatar(var_61_2)
			end

			return true
		end)
		arg_61_0:getPetTeamNo(var_61_2)
	end

	arg_61_0.prePet_ = {}
end

function var_0_0.checkPreHeroCanLoad(arg_63_0, arg_63_1)
	if arg_63_1.type == xyd.LeftMenuType.RENT_HERO then
		if not arg_63_1.can_rent or arg_63_1.isDead or arg_63_0.isSelectMerHero or not arg_63_0:checkHeroValid(arg_63_1) then
			return false
		end

		local var_63_0 = arg_63_1.rent_need_mana

		if var_63_0 and var_63_0 > arg_63_0.selfPlayer.mana and not arg_63_1.have_rent then
			return false
		end
	elseif arg_63_0.selectSpType ~= 0 and not arg_63_0:canHeroJoinBattle(arg_63_1) then
		return false
	end

	if arg_63_0:checkHeroIsDead(arg_63_1) then
		return false
	end

	return true
end

function var_0_0.initPreHeros(arg_64_0, arg_64_1)
	if arg_64_0.preSelect_ and arg_64_0.preHeros_ then
		for iter_64_0, iter_64_1 in pairs(arg_64_0.preHeros_) do
			if not arg_64_0:checkPreHeroCanLoad(iter_64_1) then
				arg_64_0.preSelect_ = {}
				arg_64_0.preHeros_ = {}

				return
			end

			local var_64_0 = arg_64_0:initBottomCell(iter_64_1)

			if arg_64_1 then
				var_64_0:hide()
			end

			var_64_0.iniCellVisible_ = true
			var_64_0.iniCell_ = display.newNode()

			var_64_0:addTo(arg_64_0)
			var_64_0:setTouchEnabled(true)
			var_64_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_65_0)
				if arg_65_0.name == "ended" then
					arg_64_0:checkClickBottomAvatar(var_64_0, iter_64_1)
				end

				return true
			end)

			if iter_64_1.type == xyd.LeftMenuType.RENT_HERO then
				arg_64_0.isSelectMerHero = true
				arg_64_0.selectMerHero = var_64_0.data
			end

			for iter_64_2 = arg_64_0:getTeamNo(var_64_0), #arg_64_0.team_ do
				local var_64_1, var_64_2 = arg_64_0:nodeByName("avatar" .. iter_64_2):getPosition()

				arg_64_0.team_[iter_64_2]:pos(var_64_1, var_64_2)

				if arg_64_0.team_[iter_64_2].iniCell_ then
					arg_64_0.team_[iter_64_2].iniCell_.teamNo_ = iter_64_2
				end
			end
		end

		arg_64_0:updateScore()
	end

	arg_64_0.preSelect_ = {}
	arg_64_0.preHeros_ = {}
end

function var_0_0.beforeClickAvatar(arg_66_0, arg_66_1)
	arg_66_0:clickAvatar(arg_66_1)
end

function var_0_0.checkClickAvatar(arg_67_0, arg_67_1)
	if arg_67_1.isAnimated_ or not arg_67_1.teamNo_ and #arg_67_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return false
	end

	if arg_67_0.selectSpType == xyd.SelectSpType.SINGLE and #arg_67_0.team_ >= 1 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_10:translation("ARENA_MODE_MAX_HERO"), 1)
		})

		return false
	end

	if arg_67_0.selectSpType == xyd.SelectSpType.TRIPLE and #arg_67_0.team_ >= 3 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_10:translation("ARENA_MODE_MAX_HERO"), 3)
		})

		return false
	end

	if arg_67_0.battleBegan then
		return false
	end

	return true
end

function var_0_0.checkClickNewAvatar(arg_68_0, arg_68_1)
	if not arg_68_1.data.can_rent and arg_68_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO then
		arg_68_1.isAnimated_ = false

		return false
	end

	if arg_68_1.data.isDead then
		arg_68_1.isAnimated_ = false

		return false
	end

	if (arg_68_0.isSelectMerHero or arg_68_0.isSelectMerPet) and arg_68_0.leftMenuType_ == xyd.LeftMenuType.RENT_HERO then
		arg_68_1.isAnimated_ = false

		local var_68_0 = var_0_10:translation("MERCENARY_ERROR_TIP1")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_68_0
		})

		return false
	end

	if not arg_68_0:checkHeroValid(arg_68_1.data) then
		arg_68_1.isAnimated_ = false

		local var_68_1 = var_0_10:translation("MERCENARY_ERROR_TIP2")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_68_1
		})

		return false
	end

	local var_68_2 = arg_68_1.data.rent_need_mana

	if var_68_2 and var_68_2 > arg_68_0.selfPlayer.mana and not arg_68_1.data.have_rent then
		arg_68_1.isAnimated_ = false

		local var_68_3 = var_0_10:translation("MERCENARY_ERROR_TIP3")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_68_3
		})

		return false
	end

	return true
end

function var_0_0.clickAvatar(arg_69_0, arg_69_1, arg_69_2)
	if not arg_69_0:checkClickAvatar(arg_69_1) then
		return
	end

	local var_69_0

	if arg_69_0.leftMenuType_ == xyd.LeftMenuType.SELF_HERO then
		var_69_0 = arg_69_1:getChildByName("layout")
	else
		var_69_0 = arg_69_1:getChildByName("yongbingCell"):getChildByName("container")
	end

	local var_69_1 = var_69_0:getChildByName("avatar_mask")
	local var_69_2 = var_69_0:getChildByName("chosen")
	local var_69_3 = arg_69_1:convertToWorldSpace(cc.p(0, 0))
	local var_69_4 = var_69_3.x + arg_69_1:getContentSize().width / 2
	local var_69_5 = var_69_3.y + arg_69_1:getContentSize().height / 2

	arg_69_1.isAnimated_ = true

	if arg_69_1.teamNo_ then
		local var_69_6 = arg_69_0.team_[arg_69_1.teamNo_]

		arg_69_0:moveFadeOutAction(var_69_4, var_69_5, var_69_6, function()
			arg_69_1.isAnimated_ = false
		end)
		var_69_1:setVisible(false)
		var_69_2:setVisible(false)

		for iter_69_0 = #arg_69_0.team_, arg_69_1.teamNo_ + 1, -1 do
			transition.stopTarget(arg_69_0.team_[iter_69_0])

			local var_69_7, var_69_8 = arg_69_0:nodeByName("avatar" .. iter_69_0 - 1):getPosition()

			transition.moveTo(arg_69_0.team_[iter_69_0], {
				time = 0.3,
				x = var_69_7,
				y = var_69_8
			})

			arg_69_0.team_[iter_69_0].iniCell_.teamNo_ = iter_69_0 - 1
		end

		if arg_69_1.type == xyd.LeftMenuType.RENT_HERO then
			arg_69_0.isSelectMerHero = false
			arg_69_0.selectMerHero = nil
		end

		table.remove(arg_69_0.team_, arg_69_1.teamNo_)
		table.remove(arg_69_0.select_, arg_69_1.teamNo_)

		arg_69_1.teamNo_ = nil
	elseif not arg_69_1.teamNo_ and #arg_69_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		if arg_69_0.selectSpType == xyd.SelectSpType.CAMP and arg_69_0.team_[1] and arg_69_1.data.getFromType and arg_69_1.data:getFromType() ~= arg_69_0.team_[1].data:getFromType() then
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("ARENA_SAME_CAMP_WARNING")
			})

			return
		end

		if not arg_69_2 then
			local var_69_9 = arg_69_1.data

			if var_0_12:chosenSound(var_69_9:getTableID()) ~= "" then
				xyd.AssetDownload.get():preloadCharacterSound({
					var_69_9:getTableID()
				}, function()
					return
				end, true)
				audio.playSound(var_0_12:chosenSound(var_69_9:getTableID()), false)
			end
		end

		if not arg_69_0:checkClickNewAvatar(arg_69_1) then
			return
		end

		local var_69_10 = arg_69_0:initBottomCell(arg_69_1.data)

		var_69_10.iniCell_ = arg_69_1

		var_69_10:pos(var_69_4, var_69_5)
		var_69_10:addTo(arg_69_0)
		var_69_10:setTouchEnabled(true)

		local var_69_11 = arg_69_1.data

		var_69_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_72_0)
			if arg_72_0.name == "ended" then
				if var_69_11.isAssist and arg_69_0.selectSpType == xyd.SelectSpType.ASSIST then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_10:translation("CAMPAIGN_ASSIST_HERO")
					})
				elseif not arg_69_0.battleBegan then
					arg_69_0:clickBottomAvatar(var_69_10)
				end
			end

			return true
		end)

		if arg_69_1.type == xyd.LeftMenuType.RENT_HERO then
			arg_69_0.isSelectMerHero = true
			arg_69_0.selectMerHero = var_69_10.data
		end

		arg_69_1.teamNo_ = arg_69_0:getTeamNo(var_69_10)

		for iter_69_1 = arg_69_1.teamNo_, #arg_69_0.team_ do
			local var_69_12, var_69_13 = arg_69_0:nodeByName("avatar" .. iter_69_1):getPosition()

			if arg_69_2 then
				arg_69_0.team_[iter_69_1]:pos(var_69_12, var_69_13)

				arg_69_1.isAnimated_ = false
			elseif iter_69_1 ~= arg_69_1.teamNo_ then
				local var_69_14 = arg_69_0.team_[iter_69_1]

				transition.stopTarget(var_69_14)
				transition.moveTo(var_69_14, {
					time = 0.3,
					x = var_69_12,
					y = var_69_13,
					onComplete = function()
						var_69_14.iniCell_.isAnimated_ = false
						var_69_14.isAnimated_ = false
					end
				})
			else
				local var_69_15 = arg_69_0.team_[iter_69_1]

				transition.stopTarget(var_69_15)

				var_69_10.isAnimated_ = true

				transition.moveTo(var_69_15, {
					time = 0.3,
					x = var_69_12,
					y = var_69_13,
					onComplete = function()
						arg_69_1.isAnimated_ = false
						var_69_10.isAnimated_ = false
					end
				})
			end

			arg_69_0.team_[iter_69_1].iniCell_.teamNo_ = iter_69_1
		end

		var_69_1:setVisible(true)
		var_69_2:setVisible(true)
	end

	if not arg_69_2 then
		arg_69_0:playGuide()
	end

	arg_69_0:updateScore()
end

function var_0_0.checkClickBottomAvatar(arg_75_0, arg_75_1, arg_75_2)
	if arg_75_0.battleBegan then
		return false
	end

	arg_75_0:clickBottomAvatar(arg_75_1)
end

function var_0_0.checkHeroValid(arg_76_0, arg_76_1)
	for iter_76_0, iter_76_1 in pairs(arg_76_0.select_) do
		if arg_76_1:getTableID() == iter_76_1:getTableID() or xyd.tables.hero:beforeAwaken(arg_76_1:getTableID()) == iter_76_1:getTableID() or xyd.tables.hero:afterAwaken(arg_76_1:getTableID()) == iter_76_1:getTableID() or iter_76_1.isAssist and arg_76_1:getTableID() == arg_76_0.assistHeroID then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_77_0)
	local var_77_0 = 0

	for iter_77_0, iter_77_1 in ipairs(arg_77_0.team_) do
		var_77_0 = var_77_0 + iter_77_1.data:getZhandouli()
	end

	for iter_77_2, iter_77_3 in ipairs(arg_77_0.petTeam_) do
		var_77_0 = var_77_0 + iter_77_3.data:getZhandouli()
	end

	arg_77_0:nodeByName("zhandouli"):setString(var_77_0)
end

function var_0_0.clickBottomAvatar(arg_78_0, arg_78_1)
	if arg_78_1.isAnimated_ then
		return
	end

	local var_78_0, var_78_1 = arg_78_0:nodeByName("list_layer"):getPosition()
	local var_78_2 = arg_78_1.iniCell_
	local var_78_3

	for iter_78_0, iter_78_1 in ipairs(arg_78_0.select_) do
		if iter_78_1:getTableID() == arg_78_1.data:getTableID() and iter_78_1.player_name == arg_78_1.data.player_name then
			var_78_3 = iter_78_0

			break
		end
	end

	if not var_78_3 then
		return
	end

	if not arg_78_1.iniCellVisible_ and arg_78_1.type == arg_78_0.leftMenuType_ and not tolua.isnull(var_78_2) then
		local var_78_4 = var_78_2:convertToWorldSpace(cc.p(0, 0))

		var_78_0, var_78_1 = var_78_4.x + var_78_2:getContentSize().width / 2, var_78_4.y + var_78_2:getContentSize().height / 2

		local var_78_5

		if arg_78_1.type == xyd.LeftMenuType.RENT_HERO then
			var_78_5 = var_78_2:getChildByName("yongbingCell"):getChildByName("container")
		else
			var_78_5 = var_78_2:getChildByName("layout")
		end

		local var_78_6 = var_78_5:getChildByName("avatar_mask")
		local var_78_7 = var_78_5:getChildByName("chosen")

		var_78_6:setVisible(false)
		var_78_7:setVisible(false)
	end

	arg_78_0:moveFadeOutAction(var_78_0, var_78_1, arg_78_1)

	for iter_78_2 = #arg_78_0.team_, var_78_3 + 1, -1 do
		local var_78_8 = arg_78_0.team_[iter_78_2]
		local var_78_9, var_78_10 = arg_78_0:nodeByName("avatar" .. iter_78_2 - 1):getPosition()

		transition.stopTarget(var_78_8)
		transition.moveTo(arg_78_0.team_[iter_78_2], {
			time = 0.3,
			x = var_78_9,
			y = var_78_10
		})

		arg_78_0.team_[iter_78_2].iniCell_.teamNo_ = iter_78_2 - 1
	end

	if arg_78_1.type == xyd.LeftMenuType.RENT_HERO then
		arg_78_0.isSelectMerHero = false
		arg_78_0.selectMerHero = nil
	end

	table.remove(arg_78_0.team_, var_78_3)
	table.remove(arg_78_0.select_, var_78_3)

	var_78_2.teamNo_ = nil

	arg_78_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_79_0, arg_79_1, arg_79_2)
	if arg_79_1.isAnimated_ then
		return
	end

	local var_79_0, var_79_1 = arg_79_0:nodeByName("list_layer"):getPosition()
	local var_79_2 = arg_79_1.iniCell_
	local var_79_3

	for iter_79_0, iter_79_1 in ipairs(arg_79_0.petSelect_) do
		if iter_79_1:getTableID() == arg_79_1.data:getTableID() and iter_79_1.player_name == arg_79_1.data.player_name then
			var_79_3 = iter_79_0

			break
		end
	end

	if not var_79_3 then
		return
	end

	if var_79_2 and not tolua.isnull(var_79_2) then
		local var_79_4 = var_79_2:convertToWorldSpace(cc.p(0, 0))

		var_79_0, var_79_1 = var_79_4.x, var_79_4.y

		local var_79_5

		if arg_79_0.rentMenuType == xyd.RentMenuType.RENT_PET then
			var_79_5 = var_79_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_79_5 = var_79_2:getChildByName("layout")
		end

		local var_79_6 = var_79_5:getChildByName("avatar_mask")
		local var_79_7 = var_79_5:getChildByName("chosen")

		var_79_6:setVisible(false)
		var_79_7:setVisible(false)
	end

	arg_79_0:moveFadeOutAction(var_79_0, var_79_1, arg_79_1, arg_79_2)

	if arg_79_1.type == xyd.PetType.RENT_PET then
		arg_79_0.isSelectMerPet = false
		arg_79_0.selectMerPet = nil
	end

	table.remove(arg_79_0.petTeam_, var_79_3)
	table.remove(arg_79_0.petSelect_, var_79_3)

	if var_79_2 then
		var_79_2.teamNo_ = nil
	end

	arg_79_0:updateScore()
end

function var_0_0.clickPetBottomAvatarWithoutAnimation(arg_80_0, arg_80_1, arg_80_2)
	if arg_80_1.isAnimated_ then
		return
	end

	local var_80_0, var_80_1 = arg_80_0:nodeByName("list_layer"):getPosition()
	local var_80_2 = arg_80_1.iniCell_
	local var_80_3

	for iter_80_0, iter_80_1 in ipairs(arg_80_0.petTeam_) do
		if iter_80_1 == arg_80_1 then
			var_80_3 = iter_80_0

			break
		end
	end

	if not var_80_3 then
		return
	end

	if var_80_2 and not tolua.isnull(var_80_2) then
		local var_80_4 = var_80_2:convertToWorldSpace(cc.p(0, 0))
		local var_80_5

		if arg_80_0.rentMenuType == xyd.RentMenuType.RENT_PET then
			var_80_5 = var_80_2:getChildByName("rent_cell"):getChildByName("container"):getChildByName("avatar"):getChildByName("layout")
		else
			var_80_5 = var_80_2:getChildByName("layout")
		end

		local var_80_6 = var_80_5:getChildByName("avatar_mask")
		local var_80_7 = var_80_5:getChildByName("chosen")

		var_80_6:setVisible(false)
		var_80_7:setVisible(false)
	end

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

	if arg_80_1.type == xyd.PetType.RENT_PET then
		arg_80_0.isSelectMerPet = false
		arg_80_0.selectMerPet = nil
	end

	table.remove(arg_80_0.petTeam_, var_80_3)
	table.remove(arg_80_0.petSelect_, var_80_3)

	if var_80_2 then
		var_80_2.teamNo_ = nil
	end

	if arg_80_1 and not tolua.isnull(arg_80_1) then
		arg_80_1:removeSelf()
	end

	if arg_80_2 then
		arg_80_2()
	end
end

function var_0_0.getTeamNo(arg_81_0, arg_81_1)
	for iter_81_0, iter_81_1 in ipairs(arg_81_0.team_) do
		if arg_81_1.data:getDistance() < iter_81_1.data:getDistance() then
			table.insert(arg_81_0.team_, iter_81_0, arg_81_1)
			table.insert(arg_81_0.select_, iter_81_0, arg_81_1.data)

			return iter_81_0
		end
	end

	table.insert(arg_81_0.team_, arg_81_1)
	table.insert(arg_81_0.select_, arg_81_1.data)

	return #arg_81_0.team_
end

function var_0_0.getPetTeamNo(arg_82_0, arg_82_1)
	table.insert(arg_82_0.petTeam_, arg_82_1)
	table.insert(arg_82_0.petSelect_, arg_82_1.data)

	return #arg_82_0.petTeam_
end

function var_0_0.widgetSet(arg_83_0, arg_83_1)
	for iter_83_0, iter_83_1 in ipairs(arg_83_1:getChildren()) do
		if iter_83_1 ~= nil then
			iter_83_1:setCascadeOpacityEnabled(true)
			arg_83_0:widgetSet(iter_83_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_84_0, arg_84_1, arg_84_2, arg_84_3, arg_84_4)
	arg_84_0:widgetSet(arg_84_3)
	arg_84_3:setCascadeOpacityEnabled(true)

	local var_84_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_84_1, arg_84_2)))

	arg_84_3:runActionOnce(var_84_0, true, arg_84_4)
end

function var_0_0.moveFadeInAction(arg_85_0, arg_85_1, arg_85_2, arg_85_3, arg_85_4)
	arg_85_0:widgetSet(arg_85_3)
	arg_85_3:setCascadeOpacityEnabled(true)
	arg_85_3:setOpacity(0)

	local var_85_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_85_1, arg_85_2)))

	arg_85_3:runActionOnce(var_85_0, false, arg_85_4)
end

function var_0_0.getBattleBtn(arg_86_0)
	if not arg_86_0.battleBtn_ then
		arg_86_0.battleBtn_ = arg_86_0:nodeByName("button_battle")

		arg_86_0.battleBtn_:addTouchEventListener(function(arg_87_0, arg_87_1)
			if not arg_86_0:checkCanStartBattle() then
				return
			end

			if arg_87_1 == ccui.TouchEventType.ended and not arg_86_0.battleBegan then
				xyd.playButtonSound()

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				arg_86_0:beforeStartBattle()
			end
		end)
		arg_86_0.battleBtn_:setVisible(true)
		arg_86_0:nodeByName("button_ok"):setVisible(false)
	end

	return arg_86_0.battleBtn_
end

function var_0_0.checkCanStartBattle(arg_88_0)
	local var_88_0 = true
	local var_88_1 = ""

	if #arg_88_0.select_ < 1 then
		var_88_0 = false
		var_88_1 = var_0_10:translation("BATTLE_NO_HERO")
	elseif #arg_88_0.select_ == 1 and (arg_88_0.select_[1]:getHeroID() < 0 or arg_88_0.isSelectMerHero) then
		var_88_1 = var_0_10:translation("BATTLE_NO_HERO")
		var_88_0 = false
	end

	if not var_88_0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_88_1
		})
	end

	return var_88_0
end

function var_0_0.beforeStartBattle(arg_89_0)
	if arg_89_0.selectMerHero and not arg_89_0.selectMerHero.have_rent then
		local var_89_0 = {
			hero = arg_89_0.selectMerHero,
			type = xyd.ConfirmRent.HERO
		}

		xyd.WindowManager.get():openWindow("confirm_rent", var_89_0)
	elseif arg_89_0.isSelectMerPet and arg_89_0.selectMerPet.can_rent then
		local var_89_1 = {
			hero = arg_89_0.selectMerPet,
			type = xyd.ConfirmRent.PET
		}

		xyd.WindowManager.get():openWindow("confirm_rent", var_89_1)
	else
		arg_89_0.battleBegan = true

		arg_89_0:startBattle()
	end
end

function var_0_0.startBattle(arg_90_0)
	return
end

function var_0_0.recordFormation(arg_91_0)
	local var_91_0 = {}

	for iter_91_0, iter_91_1 in ipairs(arg_91_0.team_) do
		if iter_91_1.type ~= xyd.LeftMenuType.RENT_HERO then
			table.insert(var_91_0, iter_91_1.data:getHeroID())
		end
	end

	local var_91_1 = ""

	for iter_91_2, iter_91_3 in ipairs(var_91_0) do
		var_91_1 = var_91_1 .. string.format("%d|", iter_91_3)
	end

	if arg_91_0:isPet() and next(arg_91_0.petTeam_) then
		local var_91_2 = ""

		for iter_91_4, iter_91_5 in ipairs(arg_91_0.petTeam_) do
			if iter_91_5.type ~= xyd.PetType.RENT_PET then
				var_91_2 = var_91_2 .. string.format("%d|", iter_91_5.data:getPetID())
			end
		end

		var_91_1 = var_91_1 .. "," .. var_91_2
	end

	xyd.db.formation:setFormationData(arg_91_0.campaignType, var_91_1)
end

function var_0_0.getBattleID(arg_92_0)
	local var_92_0
	local var_92_1
	local var_92_2
	local var_92_3 = false

	if arg_92_0.campaignType == xyd.CampaignType.NORMAL and arg_92_0.campaignID ~= 0 then
		local var_92_4 = xyd.tables.campaign:firstFightID(arg_92_0.campaignID)
		local var_92_5 = arg_92_0.selfPlayer.worldMaps_[arg_92_0.campaignID].star or 0

		if var_92_4 ~= 0 and var_92_5 <= 0 then
			var_92_0 = var_92_4
			var_92_3 = true
		else
			var_92_0 = arg_92_0.battleID or xyd.tables.campaign:fightID(arg_92_0.campaignID)
		end
	else
		var_92_0 = arg_92_0.battleID or xyd.tables.campaign:fightID(arg_92_0.campaignID)
	end

	return var_92_0, var_92_3
end

function var_0_0.getFormationStr(arg_93_0, arg_93_1)
	local var_93_0 = ""

	for iter_93_0, iter_93_1 in ipairs(arg_93_1) do
		var_93_0 = var_93_0 .. string.format("%d", iter_93_1:getHeroID())

		if iter_93_0 < #arg_93_1 then
			var_93_0 = var_93_0 .. "|"
		end
	end

	return var_93_0
end

function var_0_0.setIDBeforeGuideWnd(arg_94_0)
	local var_94_0 = xyd.StoryData.get():getGuideID()

	if var_94_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL)
	elseif var_94_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_TWO)
	elseif var_94_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_TWO)
	elseif var_94_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_95_0)
	local var_95_0 = xyd.StoryData.get():getGuideID()

	if var_95_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO)
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE)
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR)
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_RESULT)
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_MISSION_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START)
		xyd.StoryData.get():persist()
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE then
		arg_95_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_2_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_FOUR)
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO then
		arg_95_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_THREE)
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		arg_95_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_4)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_END)
		xyd.StoryData.get():persist()
	elseif var_95_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		arg_95_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_4_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR)
	end
end

function var_0_0.checkGuideIntoBattle(arg_96_0)
	local var_96_0 = xyd.StoryData.get():getGuideID()

	if var_96_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_FOUR or var_96_0 == xyd.GuideStoryType.GUIDE_MISSION_END or var_96_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_THREE or var_96_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_TWO or var_96_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_FOUR then
		return true
	end

	return false
end

function var_0_0.getGuideHeroCell(arg_97_0, arg_97_1)
	local var_97_0 = xyd.StoryData.get():getGuideID()
	local var_97_1 = arg_97_1 or 10001001

	if var_97_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_THREE then
		var_97_1 = 10001004
	end

	for iter_97_0 = 1, #arg_97_0.heroCells_ do
		if arg_97_0.heroCells_[iter_97_0] and arg_97_0.heroCells_[iter_97_0].data and arg_97_0.heroCells_[iter_97_0].data:getTableID() == var_97_1 then
			return arg_97_0.heroCells_[iter_97_0]
		end
	end

	return arg_97_0.heroCells_[1]
end

function var_0_0.playGuide(arg_98_0)
	return
end

function var_0_0.canPetJoinBattle(arg_99_0, arg_99_1)
	return true
end

function var_0_0.canHeroJoinBattle(arg_100_0, arg_100_1)
	if arg_100_0.selectSpType == xyd.SelectSpType.WEI then
		if arg_100_1:getFromType() ~= xyd.HeroFromType.WEI then
			return false
		end
	elseif arg_100_0.selectSpType == xyd.SelectSpType.SHU then
		if arg_100_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_100_0.selectSpType == xyd.SelectSpType.WU and arg_100_1:getFromType() ~= xyd.HeroFromType.WU then
		return false
	end

	return true
end

function var_0_0.initHeros(arg_101_0, arg_101_1, arg_101_2)
	arg_101_0.tmpTotalHero_[arg_101_2] = {}
	arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.ALL] = {}
	arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.QIANPAI] = {}
	arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.HOUPAI] = {}
	arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.FILTER] = {}

	local var_101_0 = os.clock()

	for iter_101_0, iter_101_1 in pairs(arg_101_1) do
		if arg_101_0:canHeroJoinBattle(iter_101_1) then
			if iter_101_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.QIANPAI], iter_101_1)
			elseif iter_101_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.ZHONGPAI], iter_101_1)
			elseif iter_101_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.HOUPAI], iter_101_1)
			end

			table.insert(arg_101_0.tmpTotalHero_[arg_101_2][xyd.DistanceType.ALL], iter_101_1)
		end
	end

	arg_101_0:sortTables(arg_101_0.tmpTotalHero_[arg_101_2])

	arg_101_0.selectedHeroClass_[arg_101_2] = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_102_0, arg_102_1, arg_102_2)
	local var_102_0 = {}

	for iter_102_0, iter_102_1 in ipairs(arg_102_1) do
		if iter_102_1.is_show_ == 1 and arg_102_0:canPetJoinBattle(iter_102_1) then
			table.insert(var_102_0, iter_102_1)
		end
	end

	table.sort(var_102_0, function(arg_103_0, arg_103_1)
		return xyd.petNormalSort(arg_103_0, arg_103_1) or false
	end)

	arg_102_0.tmpTotalPets[arg_102_2] = var_102_0
end

function var_0_0.updateFilterHeros(arg_104_0)
	arg_104_0.totalHero_[xyd.DistanceType.FILTER] = {}

	local var_104_0 = {
		0,
		0,
		0
	}
	local var_104_1 = {
		0,
		0,
		0
	}
	local var_104_2 = {
		0,
		0,
		0,
		0
	}

	if arg_104_0.selfPlayer.sortType and arg_104_0.selfPlayer.sortType > 0 then
		local var_104_3 = {}
		local var_104_4 = arg_104_0.selfPlayer.sortType
		local var_104_5 = 1

		while var_104_4 > 0 do
			var_104_3[var_104_5] = var_104_4 % 2
			var_104_5 = var_104_5 + 1
			var_104_4 = math.floor(var_104_4 / 2)
		end

		local var_104_6 = 1

		for iter_104_0 = 10, 1, -1 do
			if iter_104_0 <= 4 then
				if iter_104_0 == 4 then
					var_104_6 = 1
				end

				var_104_2[var_104_6] = var_104_3[iter_104_0]
			elseif iter_104_0 <= 7 then
				if iter_104_0 == 7 then
					var_104_6 = 1
				end

				var_104_1[var_104_6] = var_104_3[iter_104_0]
			elseif iter_104_0 <= 10 and var_104_3[iter_104_0] then
				var_104_0[var_104_6] = var_104_3[iter_104_0]
			end

			var_104_6 = var_104_6 + 1
		end
	else
		var_104_0 = {
			1,
			1,
			1
		}
		var_104_1 = {
			1,
			1,
			1
		}
		var_104_2 = {
			1,
			1,
			1,
			1
		}
	end

	for iter_104_1, iter_104_2 in pairs(arg_104_0.totalHero_[xyd.DistanceType.ALL]) do
		if var_104_0[iter_104_2:getDistanceType() - 1] == 1 and var_104_1[iter_104_2:getHeroType()] == 1 and var_104_2[iter_104_2:getFromType()] == 1 and arg_104_0:canHeroJoinBattle(iter_104_2) then
			table.insert(arg_104_0.totalHero_[xyd.DistanceType.FILTER], iter_104_2)
		end
	end
end

function var_0_0.updatePresetTeams(arg_105_0, arg_105_1)
	if arg_105_0.type and arg_105_0.type == xyd.SelectTeamType.REGION_ARENA_DEFENSE or arg_105_0.type == xyd.SelectTeamType.REGION_ARENA then
		local var_105_0 = arg_105_0.regionAwards

		for iter_105_0 = 1, #arg_105_1 do
			local var_105_1 = arg_105_1[iter_105_0].team

			arg_105_0:initRegionHeros(var_105_1, var_105_0, true)
			xyd.formatRegionArenaHeros(var_105_1)
		end
	end

	return arg_105_1
end

function var_0_0.initPresetTeams(arg_106_0)
	arg_106_0.presetTeams = {}

	if not arg_106_0:checkCanPresetTeam() then
		return
	end

	local var_106_0 = arg_106_0.selfPlayer:getSaveTeams()

	arg_106_0.presetTeams = arg_106_0:updatePresetTeams(var_106_0)
end

function var_0_0.selectHeros(arg_107_0)
	arg_107_0.totalHero_ = arg_107_0.tmpTotalHero_[arg_107_0.leftMenuType_]
end

function var_0_0.selectPets(arg_108_0)
	if arg_108_0.rentMenuType == xyd.RentMenuType.RENT_PET then
		arg_108_0.totalPet_ = arg_108_0.tmpTotalPets[xyd.PetType.RENT_PET]
	else
		arg_108_0.totalPet_ = arg_108_0.tmpTotalPets[xyd.PetType.SELF_PET]
	end
end

function var_0_0.initListview(arg_109_0)
	local var_109_0 = arg_109_0:nodeByName("list_layer")
	local var_109_1 = var_109_0:getContentSize().width
	local var_109_2 = var_109_0:getContentSize().height

	arg_109_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_109_1, var_109_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_109_0)
	arg_109_0.heroCells_ = {}

	arg_109_0.heroList_:setDelegate(handler(arg_109_0, arg_109_0.delegate))
end

function var_0_0.initTextOfList(arg_110_0)
	arg_110_0.txt_height = arg_110_0:nodeByName("lev_limit_txt"):getY()

	if xyd.tables.battle:levLimit(arg_110_0.campaignID) > 0 then
		arg_110_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_110_0:nodeByName("lev_limit_txt"):setString(string.format(var_0_10:translation("SELECT_HERO_LEV_LIMIT"), xyd.tables.battle:levLimit(arg_110_0.campaignID), xyd.tables.battle:name(arg_110_0.campaignID)))
	else
		arg_110_0:nodeByName("lev_limit_txt"):setVisible(false)
	end
end

function var_0_0.awakeMissionInit(arg_111_0)
	local var_111_0 = arg_111_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_111_0 then
		local var_111_1 = xyd.tables.mission:stage(var_111_0)

		if var_111_1 == 3 and xyd.getMissionGoIDs(var_111_0) == arg_111_0.campaignID then
			arg_111_0.isAwakeCampaign = true
			arg_111_0.awakeMission = arg_111_0.task:getTaskByID(var_111_0, xyd.TaskType.AWAKE)
			arg_111_0.awakeStage = var_111_1
			arg_111_0.awakeMissionGoalType = xyd.tables.mission:copyChallenges(var_111_0)
			arg_111_0.awakeHero = arg_111_0.selfPlayer:getHeroByTableID(xyd.tables.mission:beforeAwakenID(var_111_0))
		end

		if arg_111_0.awakeHero then
			arg_111_0.awakeHero.type = xyd.LeftMenuType.SELF_HERO
		end
	end

	if arg_111_0.isAwakeCampaign then
		local var_111_2 = ""
		local var_111_3 = var_111_0

		if arg_111_0.awakeStage == 2 then
			var_111_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP1"), arg_111_0.awakeHero:getName())
		elseif arg_111_0.awakeStage == 3 then
			if arg_111_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.SELF_KILL then
				var_111_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_111_0.awakeMissionGoalType), arg_111_0.awakeHero:getName())
			elseif arg_111_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				var_111_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_111_0.awakeMissionGoalType), xyd.tables.mission:challengeNums(var_111_3))
			elseif arg_111_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALONE_KILL then
				var_111_2 = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_111_0.awakeMissionGoalType), arg_111_0.awakeHero:getName())
			elseif arg_111_0.awakeMissionGoalType == xyd.AwakeStage3MissionType.ALL_ALIVE then
				var_111_2 = var_0_10:translation("AWAKE_SELECT_TEAM_TIP" .. arg_111_0.awakeMissionGoalType)
			end
		end

		arg_111_0:nodeByName("lev_limit_txt"):setVisible(true)
		arg_111_0:nodeByName("lev_limit_txt"):setString(var_111_2)

		arg_111_0.preSelect_ = {}
		arg_111_0.preHeros_ = {}

		table.insert(arg_111_0.preSelect_, arg_111_0.awakeHero:getHeroID())
		table.insert(arg_111_0.preHeros_, arg_111_0.awakeHero)
	end
end

function var_0_0.sortTables(arg_112_0, arg_112_1)
	for iter_112_0 = 1, #arg_112_1 do
		table.sort(arg_112_1[iter_112_0], function(arg_113_0, arg_113_1)
			if (arg_113_0.can_rent or arg_113_1.can_rent) and (not arg_113_0.can_rent or not arg_113_1.can_rent) then
				return arg_113_0.can_rent and not arg_113_1.can_rent
			end

			return xyd.heroNormalSort(arg_113_0, arg_113_1) or false
		end)
	end
end

function var_0_0.checkIsAssistBattle(arg_114_0)
	if arg_114_0.campaignType == xyd.CampaignType.NORMAL then
		local var_114_0, var_114_1 = arg_114_0:getBattleID()

		if var_114_1 then
			arg_114_0.preHeros_ = {}
			arg_114_0.preSelect_ = {}

			local var_114_2 = {}
			local var_114_3 = var_0_11:assistPartner(var_114_0)

			if not var_114_3 or not next(var_114_3) or #var_114_3 ~= 2 then
				return false
			end

			local var_114_4 = var_0_1.new()

			var_114_4:populateWithTableID(var_114_3[arg_114_0.assistID])
			table.insert(var_114_2, var_114_4)

			var_114_4.type = xyd.LeftMenuType.SELF_HERO
			var_114_4.isAssist = true
			arg_114_0.assistHeroID = var_114_4:getModelID()

			if #var_114_2 < xyd.MAX_TEAM_MEMBER_NUM then
				local var_114_5 = xyd.MAX_TEAM_MEMBER_NUM - #var_114_2

				for iter_114_0 = 1, var_114_5 do
					local var_114_6 = arg_114_0.selfPlayer:getHeroByID(iter_114_0)

					if var_114_6 then
						table.insert(var_114_2, var_114_6)
					end
				end

				table.sort(var_114_2, function(arg_115_0, arg_115_1)
					return arg_115_0:getDistance() < arg_115_1:getDistance()
				end)

				for iter_114_1, iter_114_2 in ipairs(var_114_2) do
					table.insert(arg_114_0.preSelect_, iter_114_2:getHeroID())
					table.insert(arg_114_0.preHeros_, iter_114_2)
				end

				return true
			end
		end

		return false
	end

	return false
end

function var_0_0.checkCanLoadPreFormation(arg_116_0)
	return false
end

function var_0_0.loadPreFormation(arg_117_0)
	local var_117_0 = {}
	local var_117_1 = {}
	local var_117_2 = xyd.db.formation:getFormationData(arg_117_0.campaignType) or {}
	local var_117_3 = var_117_2[1] or {}

	for iter_117_0, iter_117_1 in ipairs(var_117_3) do
		if iter_117_1 < 0 then
			iter_117_1 = -iter_117_1

			for iter_117_2, iter_117_3 in pairs(arg_117_0.allTeamHeros) do
				if iter_117_3:getHeroID() == iter_117_1 and #var_117_0 < xyd.MAX_TEAM_MEMBER_NUM then
					iter_117_3.type = xyd.LeftMenuType.RENT_HERO

					table.insert(var_117_0, -iter_117_1)
					table.insert(var_117_1, iter_117_3)

					break
				end
			end
		else
			local var_117_4 = arg_117_0.selfPlayer:getHeroByID(iter_117_1)

			if var_117_4 and #var_117_0 < xyd.MAX_TEAM_MEMBER_NUM then
				var_117_4.type = xyd.LeftMenuType.SELF_HERO

				table.insert(var_117_0, iter_117_1)
				table.insert(var_117_1, var_117_4)
			end
		end
	end

	arg_117_0.preSelect_ = var_117_0
	arg_117_0.preHeros_ = var_117_1

	local var_117_5 = var_117_2[2] or {}

	for iter_117_4, iter_117_5 in ipairs(var_117_5) do
		local var_117_6 = arg_117_0.selfPlayer:getPetByID(iter_117_5)

		if var_117_6 and var_117_6 and #arg_117_0.prePet_ < xyd.MAX_PET_NUMBER then
			table.insert(arg_117_0.prePet_, var_117_6)
		end
	end
end

function var_0_0.canRentHero(arg_118_0)
	if arg_118_0.isMercenary then
		return true
	end

	return false
end

function var_0_0.isPet(arg_119_0)
	if not arg_119_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) then
		return false
	end

	return true
end

function var_0_0.getHeros(arg_120_0)
	return arg_120_0.selfPlayer.heros_
end

function var_0_0.getPets(arg_121_0)
	return arg_121_0.selfPlayer.collectedPets
end

function var_0_0.initRegionHeros(arg_122_0, arg_122_1, arg_122_2, arg_122_3)
	for iter_122_0, iter_122_1 in pairs(arg_122_2) do
		local var_122_0 = arg_122_0:checkHeroExit(arg_122_1, iter_122_1.table_id)

		if not var_122_0 and arg_122_3 then
			-- block empty
		else
			if iter_122_1.is_summon == 1 and not var_122_0 then
				var_122_0 = var_0_1.new()

				var_122_0:initUnCollected(iter_122_1.table_id)
				table.insert(arg_122_1, var_122_0)
			end

			if iter_122_1.add_star > 0 then
				local var_122_1 = var_122_0:getStar()

				if not xyd.isSuperHero(var_122_0) then
					if var_122_1 + iter_122_1.add_star > xyd.MAX_STAR_LEVEL then
						var_122_0:setStar(xyd.MAX_STAR_LEVEL)
					else
						var_122_0:setStar(var_122_1 + iter_122_1.add_star)
					end
				elseif var_122_1 + iter_122_1.add_star > xyd.SUPER_HERO_TOTAL_STARS then
					var_122_0:setStar(xyd.SUPER_HERO_TOTAL_STARS)
				else
					var_122_0:setStar(var_122_1 + iter_122_1.add_star)
				end
			end

			if iter_122_1.is_awake == 1 and not var_122_0:isAwaken() then
				var_122_0:setTableID(xyd.tables.hero:afterAwaken(iter_122_1.table_id))
			end
		end
	end
end

function var_0_0.checkHeroExit(arg_123_0, arg_123_1, arg_123_2)
	local var_123_0 = false

	for iter_123_0, iter_123_1 in pairs(arg_123_1) do
		local var_123_1 = iter_123_1:getTableID()

		if var_123_1 == arg_123_2 then
			var_123_0 = iter_123_1

			break
		end

		if iter_123_1:isAwaken() then
			var_123_1 = iter_123_1:beforeAwakenID()
		end

		if var_123_1 == arg_123_2 then
			var_123_0 = iter_123_1

			break
		end
	end

	return var_123_0
end

function var_0_0.checkHeroIsNotUse(arg_124_0, arg_124_1)
	return false
end

function var_0_0.checkCanPresetTeam(arg_125_0)
	if arg_125_0.type == xyd.SelectTeamType.HERO_PRESET or arg_125_0.type == xyd.SelectTeamType.ZHUGE_BOSS or arg_125_0.type == xyd.SelectTeamType.ZHUGE_NOTE then
		return false
	end

	return true
end

function var_0_0.isBanned(arg_126_0, arg_126_1)
	return false
end

return var_0_0
