local var_0_0 = class("SelectTeam", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = 30
local var_0_4 = 30
local var_0_5 = {
	5,
	4,
	5,
	4
}
local var_0_6 = 6
local var_0_7 = 65
local var_0_8 = 50
local var_0_9 = 90
local var_0_10 = xyd.tables.translation
local var_0_11 = xyd.tables.battle
local var_0_12 = xyd.tables.hero
local var_0_13 = 1
local var_0_14 = 2
local var_0_15 = 3
local var_0_16 = 4
local var_0_17 = 5
local var_0_18 = 6
local var_0_19 = 7
local var_0_20 = 8
local var_0_21 = 9
local var_0_22 = 10
local var_0_23
local var_0_24 = {
	{
		50,
		10
	},
	{
		34,
		16,
		66,
		16
	},
	{
		50,
		10,
		18,
		24,
		82,
		24
	},
	{
		38,
		12,
		62,
		12,
		18,
		24,
		82,
		24
	},
	{
		50,
		10,
		34,
		16,
		66,
		16,
		18,
		24,
		82,
		24
	}
}
local var_0_25 = {
	SELF_HERO = 1,
	SELF_PET = 3,
	RENT_HERO = 2,
	PRESET = 5,
	RENT_PET = 4
}
local var_0_26 = {
	RENT_HERO = 1,
	RENT_PET = 2
}
local var_0_27 = {
	RENT_PET = 2,
	SELF_PET = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.type = arg_1_2.type or xyd.SelectTeamType.CAMPAIGN
	arg_1_0.campaignType = arg_1_2.campaignType or xyd.CampaignType.NORMAL
	arg_1_0.campaignID = arg_1_2.campaignID or 0
	arg_1_0.totalModels_ = {
		{},
		{},
		{},
		{}
	}
	arg_1_0.selectedHeroClass_ = {}
	arg_1_0.team_ = {}
	arg_1_0.petTeam_ = {}
	arg_1_0.select_ = {}
	arg_1_0.tmpTotalPets = {}
	arg_1_0.petSelect_ = arg_1_2.petSelect or {}
	arg_1_0.preSelect_ = arg_1_2.selected or {}
	arg_1_0.allTeamHeros = arg_1_2.allTeamHeros or {}
	arg_1_0.allTeamPets = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:loadPreFormation()
	arg_2_0:initHeros(arg_2_0:getHeroModels(), var_0_25.SELF_HERO)
	arg_2_0:initHeros(arg_2_0:getRentHeroModels(), var_0_25.RENT_HERO)
	arg_2_0:initPets(arg_2_0:getPets(), var_0_25.SELF_PET)
	arg_2_0:initPresetTeams(var_0_25.PRESET)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:refreshSelectedHeroClass()
	arg_3_0:getBattlepetBtn()
	arg_3_0:updateScore()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.UPDATE_FILTER_HEROS, handler(arg_3_0, arg_3_0.updateList))
end

function var_0_0.updateList(arg_4_0)
	if arg_4_0.leftMenuType_ ~= var_0_25.SELF_HERO then
		return
	end

	arg_4_0.selectedHeroClass_[arg_4_0.leftMenuType_] = xyd.DistanceType.FILTER

	arg_4_0:updateFilterHeros()
	arg_4_0:refreshSelectedHeroClass()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initRightMenu()
	arg_5_0:initLeftMenu()
	arg_5_0:initTopRentMenu()
	arg_5_0:initListview()
	arg_5_0:initTextOfList()
end

function var_0_0.initRightMenu(arg_6_0)
	arg_6_0.rightMenuButtons_ = {}

	table.insert(arg_6_0.rightMenuButtons_, arg_6_0:nodeByName("button_all"))
	table.insert(arg_6_0.rightMenuButtons_, arg_6_0:nodeByName("button_qianpai"))
	table.insert(arg_6_0.rightMenuButtons_, arg_6_0:nodeByName("button_zhongpai"))
	table.insert(arg_6_0.rightMenuButtons_, arg_6_0:nodeByName("button_houpai"))
	table.insert(arg_6_0.rightMenuButtons_, arg_6_0:nodeByName("button_filter"))
	table.insert(arg_6_0.rightMenuButtons_, arg_6_0:nodeByName("button_preset"))

	for iter_6_0 = 1, #arg_6_0.rightMenuButtons_ do
		arg_6_0.rightMenuButtons_[iter_6_0]:setZoomScale(0.3)
		arg_6_0.rightMenuButtons_[iter_6_0]:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_7_0 = 1, #arg_6_0.rightMenuButtons_ do
					local var_7_0 = iter_7_0 == iter_6_0 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal

					arg_6_0.rightMenuButtons_[iter_7_0]:setBrightStyle(var_7_0)
				end

				if arg_6_0.selectedHeroClass_[arg_6_0.leftMenuType_] == iter_6_0 then
					return
				end

				if iter_6_0 < #arg_6_0.rightMenuButtons_ - 1 then
					arg_6_0.selectedHeroClass_[arg_6_0.leftMenuType_] = iter_6_0

					arg_6_0:refreshSelectedHeroClass()
				elseif iter_6_0 == #arg_6_0.rightMenuButtons_ - 1 and arg_6_0.leftMenuType_ == var_0_25.SELF_HERO then
					xyd.WindowManager.get():openWindow("hero_filter")
				else
					arg_6_0.leftMenuType_ = var_0_25.PRESET

					arg_6_0:refreshSelectedHeroClass()
				end
			end
		end)
	end
end

function var_0_0.initLeftMenu(arg_8_0)
	arg_8_0:nodeByName("zhandui"):hide()
	arg_8_0:nodeByName("button_zhandui"):hide()

	arg_8_0:nodeByName("button_zhandui").menu_type = var_0_25.SELF_HERO

	arg_8_0:nodeByName("yongbing"):hide()
	arg_8_0:nodeByName("button_yongbing"):hide()

	arg_8_0:nodeByName("button_yongbing").menu_type = var_0_25.RENT_HERO

	arg_8_0:nodeByName("pet"):hide()
	arg_8_0:nodeByName("button_pet"):hide()

	arg_8_0:nodeByName("button_pet").menu_type = var_0_25.SELF_PET
	arg_8_0.leftMenuType_ = var_0_25.SELF_HERO
	arg_8_0.leftMenuButtons_, arg_8_0.leftMenuText_ = {}, {}

	table.insert(arg_8_0.leftMenuButtons_, arg_8_0:nodeByName("button_zhandui"))
	table.insert(arg_8_0.leftMenuText_, arg_8_0:nodeByName("zhandui"))

	if arg_8_0:canRentHero() then
		table.insert(arg_8_0.leftMenuButtons_, arg_8_0:nodeByName("button_yongbing"))
		table.insert(arg_8_0.leftMenuText_, arg_8_0:nodeByName("yongbing"))
	end

	if arg_8_0:isPetOpen() then
		table.insert(arg_8_0.leftMenuButtons_, arg_8_0:nodeByName("button_pet"))
		table.insert(arg_8_0.leftMenuText_, arg_8_0:nodeByName("pet"))
	else
		arg_8_0:nodeByName("avatar_pet1"):hide()
		arg_8_0:nodeByName("zhandouli_bg"):y(arg_8_0:nodeByName("zhandouli_bg"):getY() - 120)
	end

	for iter_8_0 = 1, #arg_8_0.leftMenuButtons_ do
		arg_8_0.leftMenuButtons_[iter_8_0]:show()
		arg_8_0.leftMenuText_[iter_8_0]:show()
		arg_8_0.leftMenuButtons_[iter_8_0]:setZoomScale(0.3)

		local var_8_0 = arg_8_0.leftMenuButtons_[1]:getY() - 85 * (iter_8_0 - 1)

		arg_8_0.leftMenuButtons_[iter_8_0]:y(var_8_0)
		arg_8_0.leftMenuText_[iter_8_0]:y(var_8_0)
		arg_8_0.leftMenuButtons_[iter_8_0]:addTouchEventListener(function(arg_9_0, arg_9_1)
			if arg_9_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				for iter_9_0, iter_9_1 in ipairs(arg_8_0.leftMenuButtons_) do
					iter_9_1:setBrightStyle(arg_9_0 == iter_9_1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
				end

				arg_8_0.leftMenuType_ = arg_9_0.menu_type

				arg_8_0:updateTopRentMenu()
				arg_8_0:refreshSelectedHeroClass()
				arg_8_0:updateTextOfList()
			end
		end)
	end
end

function var_0_0.initTopRentMenu(arg_10_0)
	arg_10_0:nodeByName("btn_rent_hero"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_10_0.leftMenuType_ = var_0_25.RENT_HERO

			arg_10_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_10_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)
			arg_10_0.heroList_:reload()
		end
	end)
	arg_10_0:nodeByName("btn_rent_pet"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended and not arg_10_0.isClickRentPet then
			arg_10_0.isClickRentPet = true

			xyd.playButtonSound()

			arg_10_0.leftMenuType_ = var_0_25.RENT_PET

			arg_10_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.normal)
			arg_10_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_10_0:initRentPets(function()
				arg_10_0.heroList_:reload()

				arg_10_0.isClickRentPet = false
			end)
		end
	end)
	arg_10_0:nodeByName("top_rent_container"):setVisible(false)
end

function var_0_0.initRentPets(arg_14_0, arg_14_1)
	if not arg_14_0.isLoadAllTeamPets then
		local var_14_0 = {}

		arg_14_0.guild:loadAllTeamPets(var_14_0, function(arg_15_0)
			arg_14_0.allTeamPets = {}

			if arg_15_0 == xyd.error.OK then
				for iter_15_0, iter_15_1 in ipairs(arg_14_0.guild:getAllTeamPets()) do
					local var_15_0 = var_0_2.new()

					var_15_0:populate(iter_15_1)

					var_15_0.player_name = iter_15_1.player_name
					var_15_0.rent_need_mana = iter_15_1.rent_need_mana
					var_15_0.can_rent = iter_15_1.can_rent
					var_15_0.player_id = iter_15_1.player_id

					table.insert(arg_14_0.allTeamPets, var_15_0)
				end

				arg_14_0.isLoadAllTeamPets = true
			end

			arg_14_0:initPets(arg_14_0.allTeamPets, var_0_25.RENT_PET)

			if arg_14_1 then
				arg_14_1()
			end
		end)
	end

	if arg_14_1 then
		arg_14_1()
	end
end

function var_0_0.updateTopRentMenu(arg_16_0)
	if arg_16_0.leftMenuType_ == var_0_25.RENT_HERO and arg_16_0:isPetOpen() then
		arg_16_0:nodeByName("top_rent_container"):setVisible(true)
		arg_16_0:nodeByName("btn_rent_hero"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_16_0:nodeByName("btn_rent_pet"):setBrightStyle(ccui.BrightStyle.normal)

		if not arg_16_0.ischangeListRect then
			if arg_16_0.campaignType == xyd.CampaignType.GUILD then
				var_0_8 = 70

				arg_16_0:nodeByName("lev_limit_txt"):setPositionY(arg_16_0:nodeByName("lev_limit_txt"):getPositionY() - var_0_8)
			end

			local var_16_0 = arg_16_0.heroList_:getViewRect()
			local var_16_1 = cc.rect(0, 0, var_16_0.width, var_16_0.height - var_0_8)

			arg_16_0.heroList_:setViewRect(var_16_1)

			arg_16_0.ischangeListRect = true
		end
	else
		arg_16_0:nodeByName("top_rent_container"):setVisible(false)

		if arg_16_0.ischangeListRect then
			if arg_16_0.campaignType == xyd.CampaignType.GUILD then
				var_0_8 = 70

				arg_16_0:nodeByName("lev_limit_txt"):setPositionY(arg_16_0:nodeByName("lev_limit_txt"):getPositionY() + var_0_8)
			end

			local var_16_2 = arg_16_0.heroList_:getViewRect()
			local var_16_3 = cc.rect(0, 0, var_16_2.width, var_16_2.height + var_0_8)

			arg_16_0.heroList_:setViewRect(var_16_3)
		end

		arg_16_0.ischangeListRect = false
	end
end

function var_0_0.initPetCell(arg_17_0, arg_17_1, arg_17_2)
	if arg_17_0.leftMenuType_ == var_0_25.RENT_PET then
		return arg_17_0:hirePetCell(arg_17_1, arg_17_2)
	end

	return arg_17_0:selfPetCell(arg_17_1, arg_17_2)
end

function var_0_0.selfPetCell(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = arg_18_0:getCurrPets(arg_18_2)
	local var_18_1 = arg_18_0:setPetCellLayout(var_18_0)

	arg_18_1:size(var_18_1:getContentSize())
	arg_18_0:setPetAvatar(var_18_1, var_18_0)
	var_18_1:addTo(arg_18_1)
	var_18_1:align(display.CENTER, arg_18_1:getWidth() / 2, arg_18_1:getHeight() / 2)

	arg_18_1.type = var_0_25.SELF_PET
	arg_18_1.heroModel = var_18_0

	for iter_18_0, iter_18_1 in ipairs(arg_18_0.petSelect_) do
		if var_18_0 == iter_18_1 then
			arg_18_0.petTeam_[iter_18_0].iniCell_ = arg_18_1
			arg_18_1.teamNo_ = iter_18_0

			local var_18_2 = arg_18_1:getChildByName("layout")

			var_18_2:getChildByName("avatar_mask"):show()
			var_18_2:getChildByName("chosen"):show()

			break
		end
	end

	arg_18_0:setCellTouchEvent(arg_18_1, var_18_0, arg_18_0.clickPetAvatar)
end

function var_0_0.hirePetCell(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_0:getCurrPets(arg_19_2)
	local var_19_1 = arg_19_0:setHirePetCellLayout(var_19_0)

	arg_19_1:size(var_19_1:getContentSize())
	arg_19_0:setPetAvatar(var_19_1, var_19_0)
	var_19_1:addTo(arg_19_1)
	var_19_1:align(display.CENTER, arg_19_1:getWidth() / 2, arg_19_1:getHeight() / 2)

	arg_19_1.type = var_0_25.RENT_PET
	arg_19_1.heroModel = var_19_0

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.petSelect_) do
		if var_19_0 == iter_19_1 then
			arg_19_0.petTeam_[iter_19_0].iniCell_ = arg_19_1
			arg_19_1.teamNo_ = iter_19_0

			local var_19_2 = arg_19_1:getChildByName("layout")

			var_19_2:getChildByName("avatar_mask"):show()
			var_19_2:getChildByName("chosen"):show()

			break
		end
	end

	arg_19_0:setCellTouchEvent(arg_19_1, var_19_0, arg_19_0.clickHirePetAvatar)
end

function var_0_0.setPetAvatar(arg_20_0, arg_20_1, arg_20_2)
	local function var_20_0()
		local var_21_0 = "images/battle/star_small2.png"

		return xyd.AssetLoader.get():loadSprite(var_21_0)
	end

	local var_20_1 = arg_20_1:getChildByName("avatar")
	local var_20_2 = arg_20_2[var_0_20] > 0 and xyd.AssetLoader.get():loadSprite("images/battle/b_pet_awake_avatar_border_" .. arg_20_2[var_0_16] .. ".png") or xyd.AssetLoader.get():loadSprite("images/battle/b_pet_avatar_border_" .. arg_20_2[var_0_16] .. ".png")

	var_20_1:addChild(var_20_2)
	var_20_2:align(display.CENTER, 50, 50)

	local var_20_3 = xyd.AssetLoader.get():loadSprite(arg_20_2[var_0_18])

	var_20_1:addChild(var_20_3)
	var_20_3:align(display.CENTER_BOTTOM, 50, 0)

	local var_20_4 = arg_20_2[var_0_17]

	if var_20_4 and var_20_4 > 0 then
		local var_20_5 = var_20_0():getWidth()
		local var_20_6 = var_0_24[var_20_4]

		for iter_20_0 = var_20_4, 1, -1 do
			local var_20_7 = var_20_0()

			var_20_1:addChild(var_20_7)
			var_20_7:align(display.CENTER, var_20_6[2 * iter_20_0 - 1], var_20_6[2 * iter_20_0])
		end
	end
end

function var_0_0.initPresetCell(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_0.presetTeams[arg_22_2].team
	local var_22_1 = arg_22_0.presetTeams[arg_22_2].teamName
	local var_22_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list/hero_preset/preset_item_2.csb")
	local var_22_3 = var_22_2:getChildByName("container")
	local var_22_4 = var_22_3:getContentSize()

	arg_22_1:setContentSize(var_22_4)
	var_22_2:addTo(arg_22_1)
	var_22_3:getChildByName("text_name"):setString(var_22_1)

	local var_22_5 = var_22_3:getChildByName("hero_list")
	local var_22_6 = 0

	for iter_22_0 = 1, #var_22_0 do
		local var_22_7 = var_22_0[iter_22_0]
		local var_22_8 = display.newNode()

		var_22_8:setContentSize(var_0_9, var_0_9)
		xyd.setAvatarBorder(var_22_7, var_22_8)
		var_22_8:addTo(var_22_5)
		var_22_8:setPositionX(var_22_6)

		var_22_6 = var_22_6 + var_0_9 + 10

		local var_22_9 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")

		var_22_9:addTo(var_22_8)
		var_22_9:setPosition(cc.p(0, 0))
		var_22_9:setAnchorPoint(cc.p(0, 0))
		var_22_9:setName("avatar_mask")
		var_22_9:setScale(var_0_9 / var_22_9:getWidth())
		var_22_9:setVisible(false)

		if arg_22_0.type == xyd.SelectTeamType.ADVANCED and arg_22_0:isRecommend(var_22_7) then
			local var_22_10 = xyd.AssetLoader.get():loadSprite("windows/common/text/recommend.png")

			var_22_10:setAnchorPoint(cc.p(0.5, 1))
			var_22_10:setPosition(var_0_9 / 2, var_0_9)
			var_22_8:addChild(var_22_10)
		elseif arg_22_0:checkHeroIsNotUse(var_22_7) then
			var_22_9:setVisible(true)

			local var_22_11 = xyd.AssetLoader.get():loadSprite("windows/arena/not_use.png")

			var_22_11:setAnchorPoint(cc.p(0.5, 1))
			var_22_11:setPosition(var_0_9 / 2, var_0_9)
			var_22_8:addChild(var_22_11, 11)
		end

		local var_22_12 = {
			size = 26,
			color = cc.c3b(206, 109, 109),
			align = cc.ui.TEXT_ALIGN_CENTER
		}
		local var_22_13 = xyd.AssetLoader.get():loadLabel(var_22_12)

		var_22_13:addTo(var_22_8)
		var_22_13:setAnchorPoint(cc.p(0.5, 1))
		var_22_13:setPosition(cc.p(var_0_9 / 2, var_0_9))
		var_22_13:setVisible(false)

		local var_22_14 = false

		if arg_22_0:checkHeroIsDead(var_22_7) then
			var_22_9:setVisible(true)
			var_22_13:setLocalZOrder(3)
			var_22_13:setVisible(true)
			var_22_13:setString(var_0_10:translation("ALREADY_DEAD"))
			var_22_13:enableOutline(cc.c4b(0, 0, 0), 2)

			var_22_14 = true
		end

		var_22_7.isDead = var_22_14

		for iter_22_1, iter_22_2 in pairs(arg_22_0.busyHeros_) do
			if iter_22_2 == heroModel[var_0_19] then
				var_22_9:setVisible(true)

				break
			end
		end

		if arg_22_0.type == xyd.SelectTeamType.INCUBUS and arg_22_0:isBanned(var_22_7) then
			local var_22_15 = xyd.AssetLoader.get():loadSprite("windows/common/text/banned.png")

			var_22_15:setAnchorPoint(cc.p(0.5, 1))
			var_22_15:setPosition(var_0_9 / 2, var_0_9)
			var_22_8:addChild(var_22_15)
			var_22_9:setVisible(true)
		end
	end

	var_22_3:getChildByName("btn_use"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_22_0:checkPresetTeamCanUse(arg_22_2) then
				local var_23_0 = arg_22_0.selfPlayer:getSaveTeamStr()
				local var_23_1 = arg_22_0.selfPlayer:getSaveTeamIDs(var_23_0)

				arg_22_0.preSelect_ = var_23_1[arg_22_2]
				arg_22_0.preHeros_ = var_22_0

				arg_22_0:showPresetTeam(arg_22_2)
			end
		end
	end)
end

function var_0_0.showPresetTeam(arg_24_0)
	local var_24_0 = arg_24_0.team_

	arg_24_0.team_ = {}
	arg_24_0.select_ = {}

	arg_24_0:updateScore()
	arg_24_0:initPreHeros(true)

	local var_24_1 = arg_24_0.team_
	local var_24_2 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_25_0 = 1, #var_24_0 do
				local var_25_0 = var_24_0[iter_25_0]
				local var_25_1, var_25_2 = arg_24_0:nodeByName("avatar" .. iter_25_0):getPosition()

				arg_24_0:moveFadeOutAction(var_25_1, var_25_2, var_25_0)

				if var_25_0.type == var_0_25.RENT_HERO then
					arg_24_0.isSelectMerHero = false
					arg_24_0.selectMerHero = nil
				end
			end
		end),
		cc.DelayTime:create(0.35)
	})
	local var_24_3 = cc.Spawn:create({
		cc.CallFunc:create(function()
			for iter_26_0 = 1, #var_24_1 do
				local var_26_0 = var_24_1[iter_26_0]

				var_26_0:show()

				local var_26_1, var_26_2 = arg_24_0:nodeByName("avatar" .. iter_26_0):getPosition()

				arg_24_0:moveFadeInAction(var_26_1, var_26_2, var_26_0)
			end
		end),
		cc.DelayTime:create(0.5)
	})

	arg_24_0:runAction(transition.sequence({
		var_24_2,
		var_24_3
	}))
end

function var_0_0.checkPresetTeamCanUse(arg_27_0, arg_27_1)
	local var_27_0 = arg_27_0.presetTeams[arg_27_1].team

	if arg_27_0.isAwakeCampaign then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_10:translation("PRESET_TEAM_NOT_USE")
		})

		return false
	elseif arg_27_0.type == xyd.SelectTeamType.CHALLENGE then
		local var_27_1 = var_0_11:modeType(arg_27_0.battleID)

		if var_27_1 == xyd.ChallengeType.OneHeroKillAll then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_10:translation("CHALLENGE_ONLY_ONE_HERO")
			})

			return false
		elseif var_27_1 == xyd.ChallengeType.Protect or var_27_1 == xyd.ChallengeType.KillSteal then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_10:translation("PRESET_TEAM_NOT_USE")
			})

			return false
		end
	elseif arg_27_0.type == xyd.SelectTeamType.ARENA or arg_27_0.type == xyd.SelectTeamType.ARENA_DEFENSE then
		for iter_27_0 = 1, #var_27_0 do
			local var_27_2 = var_27_0[iter_27_0]

			if arg_27_0:checkHeroIsSeal(var_27_2) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_10:translation("HERO_IS_SEAL_TIPS_1")
				})

				return false
			end
		end
	end

	for iter_27_1 = 1, #var_27_0 do
		local var_27_3 = var_27_0[iter_27_1]

		if not arg_27_0:canHeroJoinBattle(var_27_3) or arg_27_0:checkHeroIsDead(var_27_3) or arg_27_0:checkBusyHero2(var_27_3) or arg_27_0.type == xyd.SelectTeamType.INCUBUS and arg_27_0:isBanned(var_27_3) or arg_27_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_27_0:checkHeroIsConquerUsed(var_27_3) then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_10:translation("PRESET_MEMBER_NOT_USE")
			})

			return false
		end
	end

	return true
end

function var_0_0.checkHeroIsDead(arg_28_0, arg_28_1)
	local var_28_0
	local var_28_1 = false

	if arg_28_0.heroStatus_ then
		var_28_0 = arg_28_0.heroStatus_.self_list

		if arg_28_0.campaignType == xyd.CampaignType.TREASURE then
			var_28_0 = arg_28_0.heroStatus_
		end
	end

	if var_28_0 and next(var_28_0) ~= nil then
		local var_28_2 = var_28_0[tostring(heroModel[var_0_19])]

		if not var_28_2 or not var_28_2.health or var_28_2.health == 0 then
			-- block empty
		elseif var_28_2.health == 1 and var_28_2.hp >= 1 then
			-- block empty
		else
			var_28_1 = true
		end
	end

	return var_28_1
end

function var_0_0.clickPetAvatar(arg_29_0, arg_29_1)
	if arg_29_1.isAnimated_ then
		return
	end

	arg_29_1.isAnimated_ = true

	if arg_29_1.teamNo_ then
		arg_29_0:unChoosePetCell(arg_29_1)
	elseif not arg_29_1.teamNo_ and #arg_29_0.petTeam_ == xyd.MAX_PET_NUMBER then
		arg_29_0:replacePetCell(arg_29_1)
	elseif not arg_29_1.teamNo_ and #arg_29_0.petTeam_ < xyd.MAX_PET_NUMBER then
		arg_29_0:choosePetCell(arg_29_1)
	end

	arg_29_0:updateScore()
end

function var_0_0.clickHirePetAvatar(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_1.heroModel

	if arg_30_1.isAnimated_ or not var_30_0.can_rent then
		return
	end

	if var_30_0.rent_need_mana and var_30_0.rent_need_mana > arg_30_0.selfPlayer.mana then
		local var_30_1 = var_0_10:translation("MERCENARY_ERROR_TIP4")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_30_1
		})

		return
	end

	arg_30_1.isAnimated_ = true

	if arg_30_1.teamNo_ then
		arg_30_0:unChoosePetCell(arg_30_1)
	elseif not arg_30_1.teamNo_ and #arg_30_0.petTeam_ == xyd.MAX_PET_NUMBER then
		arg_30_0:replacePetCell(arg_30_1)
	elseif not arg_30_1.teamNo_ and #arg_30_0.petTeam_ < xyd.MAX_PET_NUMBER then
		arg_30_0:choosePetCell(arg_30_1)
	end

	arg_30_0:updateScore()
end

function var_0_0.initHeroCell(arg_31_0, arg_31_1, arg_31_2)
	if arg_31_0.leftMenuType_ == var_0_25.RENT_HERO then
		return arg_31_0:hireHeroCell(arg_31_1, arg_31_2)
	end

	arg_31_0:selfHeroCell(arg_31_1, arg_31_2)
end

function var_0_0.hireHeroCell(arg_32_0, arg_32_1, arg_32_2)
	arg_32_1.type = var_0_25.RENT_HERO

	local var_32_0 = arg_32_0:getCurrModels()[arg_32_2]
	local var_32_1 = arg_32_0:setHireCellLayout(var_32_0)

	arg_32_1:size(var_32_1:getContentSize())
	arg_32_0:setAvatarBorder(var_32_0, var_32_1:getChildByName("avatar"))

	arg_32_1.heroModel = var_32_0

	for iter_32_0, iter_32_1 in ipairs(arg_32_0.select_) do
		if iter_32_1 == var_32_0 then
			arg_32_1.teamNo_ = iter_32_0

			chosen:setVisible(true)
			mask:setVisible(true)

			arg_32_0.team_[iter_32_0].iniCell_ = arg_32_1

			break
		end
	end

	arg_32_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_32_1:addChild(var_32_1)
	arg_32_0:setCellTouchEvent(arg_32_1, var_32_0, arg_32_0.clickHireAvatar)
end

function var_0_0.selfHeroCell(arg_33_0, arg_33_1, arg_33_2)
	arg_33_1.type = var_0_25.SELF_HERO

	local var_33_0 = arg_33_0:getCurrHeros(arg_33_2)
	local var_33_1 = arg_33_0:setCellLayout(var_33_0)

	arg_33_1:size(var_33_1:getChildByName("background"):getContentSize())
	arg_33_0:setAvatarBorder(var_33_0, var_33_1:getChildByName("avatar"))

	arg_33_1.heroModel = var_33_0

	for iter_33_0, iter_33_1 in ipairs(arg_33_0.select_) do
		if iter_33_1 == var_33_0 then
			arg_33_1.teamNo_ = iter_33_0

			chosen:setVisible(true)
			mask:setVisible(true)

			arg_33_0.team_[iter_33_0].iniCell_ = arg_33_1

			break
		end
	end

	arg_33_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_33_1:addChild(var_33_1)
	arg_33_0:setCellTouchEvent(arg_33_1, var_33_0, arg_33_0.clickAvatar)
end

function var_0_0.setAvatarBorder(arg_34_0, arg_34_1, arg_34_2)
	local function var_34_0()
		local var_35_0 = "windows/common/small_yellow_star.png"

		return xyd.AssetLoader.get():loadSprite(var_35_0)
	end

	local var_34_1 = xyd.AssetLoader:get():loadSprite(arg_34_1[var_0_18])
	local var_34_2 = arg_34_2:getContentSize()
	local var_34_3 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
	local var_34_4 = cc.ClippingNode:create()

	var_34_4:setStencil(var_34_3)
	var_34_4:setInverted(false)
	var_34_4:setAlphaThreshold(0)
	var_34_4:addChild(var_34_1)
	var_34_1:align(display.CENTER, var_34_2.width / 2, var_34_2.height / 2)
	var_34_1:scale(var_34_2.width / var_34_1:getWidth())
	var_34_3:addTo(arg_34_2, -1)
	var_34_3:align(display.CENTER, var_34_2.width / 2, var_34_2.height / 2)
	var_34_3:scale((var_34_2.width - 3) / var_34_3:getWidth())
	arg_34_2:addChild(var_34_4)

	local var_34_5 = xyd.getAvatarBorder(arg_34_1[var_0_16], arg_34_1[var_0_20] > 0, arg_34_1[var_0_20] > 1)
	local var_34_6, var_34_7 = unpack(var_34_5:getContentSize())

	xyd.displaySpriteOnContainer(var_34_5, arg_34_2, true)
	var_34_5:setName("border")

	local var_34_8 = var_34_0():getWidth() - 3
	local var_34_9 = (var_34_6 - heroStar * var_34_8) / 2
	local var_34_10 = display.newNode()

	var_34_10:setName("view")
	var_34_10:size(var_34_6, var_34_7)
	var_34_10:align(display.BOTTOM_LEFT, 0, 0)

	for iter_34_0 = 1, heroStar do
		local var_34_11 = var_34_0()

		var_34_10:addChild(var_34_11)
		var_34_11:x(var_34_9 + (iter_34_0 - 1) * var_34_8):y(5)
		var_34_11:setAnchorPoint(cc.p(0, 0))
	end

	var_34_10:setScale(var_34_2.width / var_34_6, var_34_2.height / var_34_7)
	arg_34_2:addChild(var_34_10)
end

function var_0_0.setCellLayout(arg_36_0, arg_36_1)
	local var_36_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/select_team/hero_avatar.csb")

	var_36_0:size(var_36_0:getChildByName("background"):getContentSize())
	var_36_0:getChildByName("yongbing_tubiao"):setVisible(arg_36_1.isRent)
	var_36_0:removeChild("background")
	var_36_0:setName("layout")

	local var_36_1 = var_36_0:getChildByName("chosen")

	var_36_1:setLocalZOrder(100)
	var_36_1:setVisible(false)

	local var_36_2 = var_36_0:getChildByName("avatar_mask")

	var_36_2:setLocalZOrder(2)
	var_36_2:setVisible(false)
	var_36_0:getChildByName("lv_txt"):setString(arg_36_1[var_0_15])

	local var_36_3 = var_36_0:getChildByName("name_text")

	var_36_3:setString(arg_36_1[var_0_14])
	var_36_3:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_36_1[var_0_16]] ~= "" then
		local var_36_4 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_36_3:getX() + var_36_3:getWidth() / 2 - 10,
			y = var_36_3:getY(),
			color = xyd.color.HERO_QUALITY[arg_36_1[var_0_16]],
			text = xyd.Color2Level[arg_36_1[var_0_16]]
		}
		local var_36_5 = xyd.AssetLoader.get():loadLabel(var_36_4)

		var_36_5:addTo(var_36_0)
		var_36_5:align(display.CENTER_LEFT)
		var_36_5:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_36_3:x(var_36_3:getX() - 15)
	end

	return var_36_0
end

function var_0_0.setHireCellLayout(arg_37_0, arg_37_1)
	local var_37_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/select_team/hire_hero_avatar.csb")

	var_37_0:size(var_37_0:getChildByName("yongbing_di"):getContentSize())
	var_37_0:setName("layout")
	var_37_0:getChildByName("player_name"):setString(arg_37_1.player_name)
	var_37_0:getChildByName("rent_cost"):setString(arg_37_1.rent_need_mana)
	var_37_0:getChildByName("is_can_rent"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_37_0:getChildByName("is_can_rent"):setColor(cc.c3b(255, 165, 159))
	var_37_0:getChildByName("is_can_rent"):enableOutline(cc.c4b(0, 0, 0, 105), 1)
	var_37_0:getChildByName("is_can_rent"):setString(var_0_10:translation("CAN_NOT_BORROW"))
	var_37_0:getChildByName("chosen"):setVisible(false)
	var_37_0:getChildByName("avatar_mask"):setVisible(arg_37_1.can_rent)
	var_37_0:getChildByName("is_can_rent"):setVisible(not arg_37_1.can_rent)
	var_37_0:getChildByName("lv_txt"):setString(arg_37_1[var_0_15])

	local var_37_1 = var_37_0:getChildByName("name_txt")

	var_37_1:setString(arg_37_1[var_0_14])
	var_37_1:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_37_1[var_0_16]] ~= "" then
		local var_37_2 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_37_1:getX() + var_37_1:getWidth() / 2 - 10,
			y = var_37_1:getY(),
			color = xyd.color.HERO_QUALITY[arg_37_1[var_0_16]],
			text = xyd.Color2Level[arg_37_1[var_0_16]]
		}
		local var_37_3 = xyd.AssetLoader.get():loadLabel(var_37_2)

		var_37_3:addTo(var_37_0)
		var_37_3:align(display.CENTER_LEFT)
		var_37_3:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_37_1:x(var_37_1:getX() - 15)
	end

	return var_37_0
end

function var_0_0.setPetCellLayout(arg_38_0, arg_38_1)
	local var_38_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team/pet_avatar.csb")

	var_38_0:getChildByName("yongbing_tubiao"):setVisible(arg_38_1.isRent)
	var_38_0:getChildByName("avatar_mask"):hide()
	var_38_0:getChildByName("chosen"):hide()
	var_38_0:getChildByName("name"):setString(arg_38_1[var_0_14])
	var_38_0:size(var_38_0:getChildByName("background"):getContentSize())
	var_38_0:setName("layout")

	return var_38_0
end

function var_0_0.setHirePetCellLayout(arg_39_0, arg_39_1)
	local var_39_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team/rent_pet_avatar.csb")

	var_39_0:getChildByName("player_name"):setString(arg_39_1.player_name)
	var_39_0:getChildByName("rent_cost"):setString(arg_39_1.rent_need_mana)
	var_39_0:getChildByName("can_not_rent"):setString(var_0_10:translation("CAN_NOT_BORROW"))
	var_39_0:getChildByName("can_not_rent"):setVisible(arg_39_1.can_rent)
	var_39_0:getChildByName("yongbing_tubiao"):setVisible(arg_39_1.isRent)
	var_39_0:getChildByName("avatar_mask"):setVisible(arg_39_1.can_rent)
	var_39_0:getChildByName("chosen"):hide()
	var_39_0:getChildByName("name"):setString(arg_39_1[var_0_14])
	var_39_0:size(var_39_0:getChildByName("background"):getContentSize())
	var_39_0:setName("layout")

	return var_39_0
end

function var_0_0.setCellTouchEvent(arg_40_0, arg_40_1, arg_40_2, arg_40_3)
	arg_40_1:setTouchSwallowEnabled(false)
	arg_40_1:setTouchEnabled(true)
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
			arg_40_3(arg_40_0, arg_40_1)
		end

		return true
	end)
end

function var_0_0.initBottomCell(arg_42_0, arg_42_1, arg_42_2)
	local var_42_0 = display.newNode()

	var_42_0.iniCell_ = arg_42_2

	local var_42_1 = arg_42_0:setCellLayout(arg_42_1)

	var_42_0:size(var_42_1:getChildByName("background"):getContentSize())
	arg_42_0:setAvatarBorder(arg_42_1, var_42_1:getChildByName("avatar"))

	var_42_0.heroModel = arg_42_1

	var_42_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_42_0:addChild(var_42_1)

	local var_42_2 = var_42_0:convertToWorldSpace(cc.p(0, 0))
	local var_42_3 = var_42_2.x + var_42_0:getWidth() / 2
	local var_42_4 = var_42_2.y + var_42_0:getHeight() / 2

	var_42_0:pos(var_42_3, var_42_4)
	var_42_0:addTo(arg_42_0)
	var_42_0:setTouchEnabled(true)
	var_42_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
		if arg_43_0.name == "ended" then
			arg_42_0:clickBottomAvatar(var_42_0)
		end

		return true
	end)

	return var_42_0
end

function var_0_0.initPetBottomCell(arg_44_0, arg_44_1, arg_44_2)
	local var_44_0 = display.newNode()

	var_44_0.iniCell_ = arg_44_2
	var_44_0.heroModel = arg_44_1

	local var_44_1 = arg_44_0:setPetCellLayout(arg_44_1)

	var_44_0:size(var_44_1:getContentSize())
	arg_44_0:setPetAvatar(var_44_1, arg_44_1)
	var_44_1:addTo(var_44_0)
	var_44_1:align(display.CENTER, var_44_0:getWidth() / 2, var_44_0:getHeight() / 2)

	local var_44_2 = arg_44_2:convertToWorldSpace(cc.p(0, 0))

	var_44_0:setPosition(var_44_2)
	var_44_0:addTo(arg_44_0)
	var_44_0:setTouchEnabled(true)
	var_44_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_45_0)
		if arg_45_0.name == "ended" then
			arg_44_0:clickPetBottomAvatar(var_44_0)
		end

		return true
	end)

	return var_44_0
end

function var_0_0.delegate(arg_46_0, ...)
	if arg_46_0.leftMenuType_ == var_0_25.PRESET then
		return arg_46_0:presetDelegate(...)
	elseif arg_46_0.leftMenuType_ == var_0_25.SELF_PET or arg_46_0.leftMenuType_ == var_0_25.RENT_PET then
		return arg_46_0:petDelegate(...)
	end

	return arg_46_0:heroDelegate(...)
end

function var_0_0.petDelegate(arg_47_0, arg_47_1, arg_47_2, arg_47_3)
	local var_47_0 = var_0_5[arg_47_0.leftMenuType_]
	local var_47_1 = math.ceil(#arg_47_0:getCurrPets() / var_47_0)

	if cc.ui.UIListView.COUNT_TAG == arg_47_2 then
		return var_47_1
	elseif cc.ui.UIListView.CELL_TAG == arg_47_2 then
		local var_47_2
		local var_47_3
		local var_47_4
		local var_47_5 = arg_47_0.heroList_:dequeueItem()

		if not var_47_5 then
			var_47_5 = arg_47_0.heroList_:newItem()
		else
			var_47_5:removeAllChildren()
		end

		local var_47_6 = display.newNode()

		var_47_6:setTouchSwallowEnabled(false)

		for iter_47_0 = 1, var_47_0 do
			local var_47_7 = (arg_47_3 - 1) * var_47_0 + iter_47_0

			if var_47_7 > #arg_47_0:getCurrPets() then
				break
			end

			var_47_4 = display.newNode()

			arg_47_0:initPetCell(var_47_4, var_47_7)

			local var_47_8 = var_47_4:getContentSize().width
			local var_47_9 = var_47_4:getContentSize().height
			local var_47_10 = (arg_47_0.heroList_.viewRect_.width - var_47_8 * var_47_0) / (var_47_0 + 1)

			var_47_4:align(display.CENTER, var_47_10 * iter_47_0 + (iter_47_0 - 1) * var_47_8 + var_47_8 / 2, var_47_9 / 2)
			var_47_6:addChild(var_47_4)
		end

		var_47_6:setContentSize(cc.size(arg_47_0.heroList_.viewRect_.width, var_47_4:getContentSize().height))
		var_47_5:setItemSize(arg_47_0.heroList_.viewRect_.width, var_47_4:getContentSize().height)
		var_47_5:addContent(var_47_6)

		return var_47_5
	end
end

function var_0_0.presetDelegate(arg_48_0, arg_48_1, arg_48_2, arg_48_3)
	local var_48_0 = #arg_48_0.presetTeams

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

		local var_48_6 = display.newNode()

		arg_48_0:initPresetCell(var_48_6, arg_48_3)
		var_48_5:addChild(var_48_6)
		var_48_5:setContentSize(cc.size(arg_48_0.heroList_.viewRect_.width, var_48_6:getContentSize().height))
		var_48_4:setItemSize(arg_48_0.heroList_.viewRect_.width, var_48_6:getContentSize().height)
		var_48_4:addContent(var_48_5)

		return var_48_4
	end
end

function var_0_0.heroDelegate(arg_49_0, arg_49_1, arg_49_2, arg_49_3)
	local var_49_0 = var_0_5[arg_49_0.leftMenuType_]
	local var_49_1 = math.ceil(#arg_49_0:getCurrHeros() / var_49_0)

	if cc.ui.UIListView.COUNT_TAG == arg_49_2 then
		return var_49_1
	elseif cc.ui.UIListView.CELL_TAG == arg_49_2 then
		local var_49_2
		local var_49_3
		local var_49_4
		local var_49_5 = arg_49_0.heroList_:dequeueItem()

		if not var_49_5 then
			var_49_5 = arg_49_0.heroList_:newItem()
		else
			var_49_5:removeAllChildren()
		end

		local var_49_6 = display.newNode()

		var_49_6:setTouchSwallowEnabled(false)

		for iter_49_0 = 1, var_49_0 do
			local var_49_7 = (arg_49_3 - 1) * var_49_0 + iter_49_0

			if var_49_7 > #arg_49_0:getCurrHeros() then
				break
			end

			var_49_4 = display.newNode()

			arg_49_0:initHeroCell(var_49_4, var_49_7)

			local var_49_8 = var_49_4:getContentSize().width
			local var_49_9 = var_49_4:getContentSize().height
			local var_49_10 = (arg_49_0.heroList_.viewRect_.width - var_49_8 * var_49_0) / (var_49_0 + 1)

			var_49_4:pos(var_49_10 * iter_49_0 + (iter_49_0 - 1) * var_49_8 + var_49_8 / 2, var_0_4 + var_49_9 / 2 - 2)
			var_49_6:addChild(var_49_4)
		end

		var_49_6:setContentSize(cc.size(arg_49_0.heroList_.viewRect_.width, var_49_4:getContentSize().height + var_0_4))
		var_49_5:setItemSize(arg_49_0.heroList_.viewRect_.width, var_49_4:getContentSize().height + var_0_4)
		var_49_5:addContent(var_49_6)

		return var_49_5
	end
end

function var_0_0.refreshSelectedHeroClass(arg_50_0)
	arg_50_0.heroList_:removeAllItems()
	arg_50_0:initPreHeros()
	arg_50_0:initPrePets()
	arg_50_0.heroList_:reload()
end

function var_0_0.buttonHandler(arg_51_0, arg_51_1, arg_51_2, arg_51_3)
	if not arg_51_2 or not arg_51_2:getParent() then
		return
	end

	if arg_51_3.name == "ended" then
		transition.stopTarget(arg_51_2)
		arg_51_2:setScale(1)

		if arg_51_1 then
			arg_51_1(arg_51_2, eventType)
		end
	elseif arg_51_3.name == "began" then
		local var_51_0 = cc.ScaleTo:create(0.3, 0.95)

		arg_51_2:runAction(var_51_0)

		return true
	elseif arg_51_3.name == "cancled" then
		transition.stopTarget(arg_51_2)
		arg_51_2:setScale(1)
	end
end

function var_0_0.initPrePets(arg_52_0)
	for iter_52_0, iter_52_1 in ipairs(arg_52_0.prePet_) do
		local var_52_0, var_52_1 = arg_52_0:nodeByName("avatar_pet" .. iter_52_0):getPosition()
		local var_52_2 = arg_52_0:initPetBottomCell(iter_52_1)

		var_52_2:pos(var_52_0, var_52_1)
		var_52_2:addTo(arg_52_0)
		var_52_2:setTouchEnabled(true)
		var_52_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_53_0)
			if arg_53_0.name == "ended" then
				arg_52_0:clickPetBottomAvatar(var_52_2)
			end

			return true
		end)
		arg_52_0:getPetTeamNo(var_52_2)
	end

	arg_52_0.prePet_ = {}
end

function var_0_0.initPreHeros(arg_54_0, arg_54_1)
	if arg_54_0.preSelect_ and arg_54_0.preHeros_ then
		for iter_54_0, iter_54_1 in pairs(arg_54_0.preHeros_) do
			if iter_54_1.type == var_0_25.RENT_HERO then
				if not iter_54_1.can_rent or iter_54_1.isDead or arg_54_0.isSelectMerHero or not arg_54_0:checkHeroValid(iter_54_1) then
					return
				end

				local var_54_0 = iter_54_1.rent_need_mana

				if var_54_0 and var_54_0 > arg_54_0.selfPlayer.mana and not iter_54_1.have_rent then
					return
				end

				local var_54_1 = false

				if arg_54_0.heroStatus_ then
					local var_54_2 = arg_54_0.heroStatus_.rent_list

					iter_54_1.healthStatus = var_54_2

					if var_54_2 and var_54_2.health then
						local var_54_3 = 0
						local var_54_4 = 0

						if var_54_2.health == 0 then
							local var_54_5 = 100
							local var_54_6 = 0
						elseif var_54_2.health == 1 and var_54_2.hp >= 1 then
							local var_54_7 = var_54_2.hp / iter_54_1:getTotalAttr(xyd.AttributeType.HP) * 100
							local var_54_8 = var_54_2.mp / 10
						else
							local var_54_9 = 0
							local var_54_10 = 0

							var_54_1 = true
						end
					end
				end

				if not var_54_1 then
					local var_54_11 = arg_54_0:initBottomCell(iter_54_1)

					var_54_11.iniCellVisible_ = true
					var_54_11.iniCell_ = display.newNode()

					var_54_11:addTo(arg_54_0)
					var_54_11:setTouchEnabled(true)
					var_54_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_55_0)
						if arg_55_0.name == "ended" then
							if (iter_54_1.isChallengeKillSteal_ or iter_54_1.isChallengeProtected_) and arg_54_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_11:modeType(arg_54_0.battleID) == xyd.ChallengeType.KillSteal or var_0_11:modeType(arg_54_0.battleID) == xyd.ChallengeType.Protect) then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_10:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
								})
							else
								arg_54_0:clickBottomAvatar(var_54_11)
							end
						end

						return true
					end)

					if iter_54_1.type == var_0_25.RENT_HERO then
						arg_54_0.isSelectMerHero = true
						arg_54_0.selectMerHero = teamcell.heroModel
					end

					for iter_54_2 = arg_54_0:getTeamNo(var_54_11), #arg_54_0.team_ do
						local var_54_12, var_54_13 = arg_54_0:nodeByName("avatar" .. iter_54_2):getPosition()

						arg_54_0.team_[iter_54_2]:pos(var_54_12, var_54_13)

						if arg_54_0.team_[iter_54_2].iniCell_ then
							arg_54_0.team_[iter_54_2].iniCell_.teamNo_ = iter_54_2
						end
					end
				end
			elseif arg_54_0.campaignType == xyd.CampaignType.ARENA and arg_54_0:checkHeroIsSeal(iter_54_1) then
				-- block empty
			else
				if (arg_54_0.campaignType == xyd.CampaignType.MARCH or arg_54_0.campaignType == xyd.CampaignType.TREASURE) and iter_54_1.isDead or not arg_54_0:checkHeroValid(iter_54_1) then
					return
				end

				local var_54_14 = false

				if arg_54_0.heroStatus_ then
					local var_54_15 = arg_54_0.heroStatus_.self_list

					if arg_54_0.campaignType == xyd.CampaignType.TREASURE then
						var_54_15 = arg_54_0.heroStatus_
					end

					local var_54_16 = var_54_15[tostring(heroModel[var_0_19])]

					iter_54_1.healthStatus = var_54_16

					if var_54_16 and var_54_16.health then
						local var_54_17 = 0
						local var_54_18 = 0

						if var_54_16.health == 0 then
							local var_54_19 = 100
							local var_54_20 = 0
						elseif var_54_16.health == 1 and var_54_16.hp >= 1 then
							local var_54_21 = var_54_16.hp / iter_54_1:getTotalAttr(xyd.AttributeType.HP) * 100
							local var_54_22 = var_54_16.mp / 10
						else
							local var_54_23 = 0
							local var_54_24 = 0

							var_54_14 = true
						end
					end
				end

				if not var_54_14 then
					local var_54_25 = arg_54_0:initBottomCell(iter_54_1)

					if arg_54_1 then
						var_54_25:hide()
					end

					var_54_25.iniCellVisible_ = true
					var_54_25.iniCell_ = display.newNode()

					var_54_25:addTo(arg_54_0)
					var_54_25:setTouchEnabled(true)
					var_54_25:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_56_0)
						if arg_56_0.name == "ended" then
							local function var_56_0()
								arg_54_0:clickBottomAvatar(var_54_25)
							end

							if arg_54_0.isAwakeCampaign and heroModel[var_0_13] == arg_54_0.awakeHero:getTableID() then
								local var_56_1 = {
									message = string.format(var_0_10:translation("AWAKE_SELECT_TEAM_TIP5"), heroModel[var_0_14])
								}

								var_56_1.alertType = 1
								var_56_1.callback = var_56_0

								xyd.WindowManager.get():openWindow("awake_alert", var_56_1)
							elseif (iter_54_1.isChallengeKillSteal_ or iter_54_1.isChallengeProtected_) and arg_54_0.type == xyd.SelectTeamType.CHALLENGE and (var_0_11:modeType(arg_54_0.battleID) == xyd.ChallengeType.KillSteal or var_0_11:modeType(arg_54_0.battleID) == xyd.ChallengeType.Protect) then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_10:translation("CHALLENGE_HERO_NEED_JOIN_FIGHT")
								})
							elseif iter_54_1.isAssist and arg_54_0.campaignType == xyd.CampaignType.NORMAL then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_10:translation("CAMPAIGN_ASSIST_HERO")
								})
							else
								arg_54_0:clickBottomAvatar(var_54_25)
							end
						end

						return true
					end)

					for iter_54_3 = arg_54_0:getTeamNo(var_54_25), #arg_54_0.team_ do
						local var_54_26, var_54_27 = arg_54_0:nodeByName("avatar" .. iter_54_3):getPosition()

						arg_54_0.team_[iter_54_3]:pos(var_54_26, var_54_27)

						if arg_54_0.team_[iter_54_3].iniCell_ then
							arg_54_0.team_[iter_54_3].iniCell_.teamNo_ = iter_54_3
						end
					end
				end
			end
		end

		arg_54_0:updateScore()
	end

	arg_54_0.preSelect_ = {}
	arg_54_0.preHeros_ = {}
end

function var_0_0.unChooseCell(arg_58_0, arg_58_1)
	local var_58_0 = arg_58_1:getChildByName("layout")
	local var_58_1 = var_58_0:getChildByName("avatar_mask")
	local var_58_2 = var_58_0:getChildByName("chosen")
	local var_58_3 = arg_58_1:convertToWorldSpace(cc.p(0, 0))
	local var_58_4 = var_58_3.x + arg_58_1:getWidth() / 2
	local var_58_5 = var_58_3.y + arg_58_1:getHeight() / 2
	local var_58_6 = arg_58_0.team_[arg_58_1.teamNo_]

	arg_58_0:moveFadeOutAction(var_58_4, var_58_5, var_58_6, function()
		arg_58_1.isAnimated_ = false
	end)
	var_58_1:setVisible(false)
	var_58_2:setVisible(false)

	for iter_58_0 = #arg_58_0.team_, arg_58_1.teamNo_ + 1, -1 do
		transition.stopTarget(arg_58_0.team_[iter_58_0])

		local var_58_7, var_58_8 = arg_58_0:nodeByName("avatar" .. iter_58_0 - 1):getPosition()

		transition.moveTo(arg_58_0.team_[iter_58_0], {
			time = 0.3,
			x = var_58_7,
			y = var_58_8
		})

		arg_58_0.team_[iter_58_0].iniCell_.teamNo_ = iter_58_0 - 1
	end

	table.remove(arg_58_0.team_, arg_58_1.teamNo_)
	table.remove(arg_58_0.select_, arg_58_1.teamNo_)

	arg_58_1.teamNo_ = nil
end

function var_0_0.unChoosePetCell(arg_60_0, arg_60_1)
	local var_60_0 = arg_60_1:getChildByName("layout")
	local var_60_1 = var_60_0:getChildByName("avatar_mask")
	local var_60_2 = var_60_0:getChildByName("chosen")
	local var_60_3 = arg_60_1:convertToWorldSpace(cc.p(0, 0))
	local var_60_4 = var_60_3.x
	local var_60_5 = var_60_3.y
	local var_60_6 = arg_60_0.petTeam_[arg_60_1.teamNo_]

	arg_60_0:moveFadeOutAction(var_60_4, var_60_5, var_60_6, function()
		arg_60_1.isAnimated_ = false
	end)
	var_60_1:setVisible(false)
	var_60_2:setVisible(false)

	for iter_60_0 = #arg_60_0.petTeam_, arg_60_1.teamNo_ + 1, -1 do
		transition.stopTarget(arg_60_0.petTeam_[iter_60_0])

		local var_60_7, var_60_8 = arg_60_0:nodeByName("avatar_pet" .. iter_60_0 - 1):getPosition()

		transition.moveTo(arg_60_0.petTeam_[iter_60_0], {
			time = 0.3,
			x = var_60_7,
			y = var_60_8
		})

		arg_60_0.petTeam_[iter_60_0].iniCell_.teamNo_ = iter_60_0 - 1
	end

	table.remove(arg_60_0.petTeam_, arg_60_1.teamNo_)
	table.remove(arg_60_0.petSelect_, arg_60_1.teamNo_)

	arg_60_1.teamNo_ = nil
end

function var_0_0.replacePetCell(arg_62_0, arg_62_1)
	local var_62_0 = 1
	local var_62_1 = arg_62_0.petTeam_[var_62_0]

	if not var_62_1 or var_62_1.isAnimated_ then
		arg_62_0:choosePetCell(arg_62_1)

		return
	end

	local var_62_2, var_62_3 = arg_62_0:nodeByName("list_layer"):getPosition()
	local var_62_4 = var_62_1.iniCell_

	if var_62_4 and not tolua.isnull(var_62_4) then
		var_62_4.teamNo_ = nil

		local var_62_5 = var_62_4:getChildByName("layout")

		var_62_5:getChildByName("avatar_mask"):hide()
		var_62_5:getChildByName("chosen"):hide()
	end

	table.remove(arg_62_0.petTeam_, var_62_0)
	table.remove(arg_62_0.petSelect_, var_62_0)

	if var_62_1 and not tolua.isnull(var_62_1) then
		transition.stopTarget(var_62_1)
		var_62_1:removeSelf()
	end

	arg_62_0:choosePetCell(arg_62_1)
end

function var_0_0.chooseCell(arg_63_0, arg_63_1)
	local var_63_0 = arg_63_1.heroModel

	if var_0_12:chosenSound(var_63_0[var_0_13]) ~= "" then
		audio.playSound(var_0_12:chosenSound(var_63_0[var_0_13]), false)
	end

	local var_63_1 = arg_63_1:getChildByName("layout")
	local var_63_2 = var_63_1:getChildByName("avatar_mask")
	local var_63_3 = var_63_1:getChildByName("chosen")

	var_63_2:setVisible(true)
	var_63_3:setVisible(true)

	local var_63_4 = arg_63_0:initBottomCell(var_63_0, arg_63_1)

	arg_63_1.teamNo_ = arg_63_0:getTeamNo(var_63_4)

	for iter_63_0 = arg_63_1.teamNo_, #arg_63_0.team_ do
		local var_63_5, var_63_6 = arg_63_0:nodeByName("avatar" .. iter_63_0):getPosition()

		if iter_63_0 ~= arg_63_1.teamNo_ then
			local var_63_7 = arg_63_0.team_[iter_63_0]

			transition.stopTarget(var_63_7)
			transition.moveTo(var_63_7, {
				time = 0.3,
				x = var_63_5,
				y = var_63_6,
				onComplete = function()
					var_63_7.iniCell_.isAnimated_ = false
					var_63_7.isAnimated_ = false
				end
			})
		else
			local var_63_8 = arg_63_0.team_[iter_63_0]

			transition.stopTarget(var_63_8)

			var_63_4.isAnimated_ = true

			transition.moveTo(var_63_8, {
				time = 0.3,
				x = var_63_5,
				y = var_63_6,
				onComplete = function()
					arg_63_1.isAnimated_ = false
					var_63_4.isAnimated_ = false
				end
			})
		end

		arg_63_0.team_[iter_63_0].iniCell_.teamNo_ = iter_63_0
	end
end

function var_0_0.choosePetCell(arg_66_0, arg_66_1)
	local var_66_0 = arg_66_1.heroModel

	if var_0_12:chosenSound(var_66_0[var_0_13]) ~= "" then
		audio.playSound(var_0_12:chosenSound(var_66_0[var_0_13]), false)
	end

	local var_66_1 = arg_66_1:getChildByName("layout")
	local var_66_2 = var_66_1:getChildByName("avatar_mask")
	local var_66_3 = var_66_1:getChildByName("chosen")

	var_66_2:setVisible(true)
	var_66_3:setVisible(true)

	local var_66_4 = arg_66_0:initPetBottomCell(var_66_0, arg_66_1)

	arg_66_0:getPetTeamNo(var_66_4)

	local var_66_5 = 1
	local var_66_6, var_66_7 = arg_66_0:nodeByName("avatar_pet" .. var_66_5):getPosition()

	var_66_4.isAnimated_ = true

	transition.moveTo(sp, {
		time = 0.3,
		x = var_66_6,
		y = var_66_7,
		onComplete = function()
			arg_66_1.isAnimated_ = false
			var_66_4.isAnimated_ = false
		end
	})
end

function var_0_0.clickAvatar(arg_68_0, arg_68_1)
	if arg_68_1.isAnimated_ or not arg_68_1.teamNo_ and #arg_68_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	arg_68_1.isAnimated_ = true

	if arg_68_1.teamNo_ then
		arg_68_0:unChooseCell(arg_68_1)
	elseif not arg_68_1.teamNo_ and #arg_68_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		arg_68_0:chooseCell(arg_68_1)
	end

	arg_68_0:updateScore()
end

function var_0_0.clickHireAvatar(arg_69_0, arg_69_1)
	if arg_69_1.isAnimated_ or not arg_69_1.teamNo_ and #arg_69_0.team_ >= xyd.MAX_TEAM_MEMBER_NUM then
		return
	end

	arg_69_1.isAnimated_ = true

	if arg_69_1.teamNo_ then
		arg_69_0.isSelectMerHero = false
		arg_69_0.selectMerHero = nil

		arg_69_0:unChooseCell(arg_69_1)
	elseif not arg_69_1.teamNo_ and #arg_69_0.team_ < xyd.MAX_TEAM_MEMBER_NUM then
		local var_69_0 = arg_69_1.heroModel

		if not var_69_0.can_rent then
			arg_69_1.isAnimated_ = false

			return
		end

		if arg_69_0.isSelectMerHero then
			arg_69_1.isAnimated_ = false

			local var_69_1 = var_0_10:translation("MERCENARY_ERROR_TIP1")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_69_1
			})

			return
		end

		if not arg_69_0:checkHeroValid(var_69_0) then
			arg_69_1.isAnimated_ = false

			local var_69_2 = var_0_10:translation("MERCENARY_ERROR_TIP2")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_69_2
			})

			return
		end

		local var_69_3 = var_69_0.rent_need_mana

		if var_69_3 and var_69_3 > arg_69_0.selfPlayer.mana and not var_69_0.have_rent then
			arg_69_1.isAnimated_ = false

			local var_69_4 = var_0_10:translation("MERCENARY_ERROR_TIP3")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_69_4
			})

			return
		end

		arg_69_0.isSelectMerHero = true
		arg_69_0.selectMerHero = var_69_0

		arg_69_0:chooseCell(arg_69_1)
	end

	arg_69_0:updateScore()
end

function var_0_0.checkHeroValid(arg_70_0, arg_70_1)
	for iter_70_0, iter_70_1 in pairs(arg_70_0.select_) do
		if heroModel[var_0_13] == iter_70_1:getTableID() or xyd.tables.hero:beforeAwaken(heroModel[var_0_13]) == iter_70_1:getTableID() or xyd.tables.hero:afterAwaken(heroModel[var_0_13]) == iter_70_1:getTableID() then
			return false
		end
	end

	return true
end

function var_0_0.updateScore(arg_71_0)
	local var_71_0 = 0
	local var_71_1 = 0

	for iter_71_0, iter_71_1 in ipairs(arg_71_0.team_) do
		var_71_0 = var_71_0 + iter_71_1.data:getZhandouli()
	end

	for iter_71_2, iter_71_3 in ipairs(arg_71_0.petTeam_) do
		var_71_0 = var_71_0 + iter_71_3.data:getZhandouli()
	end

	arg_71_0:nodeByName("zhandouli"):setString(var_71_0)
end

function var_0_0.clickBottomAvatar(arg_72_0, arg_72_1)
	if arg_72_1.isAnimated_ then
		return
	end

	local var_72_0 = arg_72_1.heroModel
	local var_72_1, var_72_2 = arg_72_0:nodeByName("list_layer"):getPosition()
	local var_72_3 = arg_72_1.iniCell_
	local var_72_4 = table.indexof(arg_72_0.team_, var_72_0)

	if not var_72_4 then
		return
	end

	if not tolua.isnull(var_72_3) and arg_72_1.type == arg_72_0.leftMenuType_ then
		local var_72_5 = var_72_3:convertToWorldSpace(cc.p(0, 0))

		var_72_1, var_72_2 = var_72_5.x + var_72_3:getContentSize().width / 2, var_72_5.y + var_72_3:getContentSize().height / 2

		local var_72_6 = var_72_3:getChildByName("layout")

		var_72_6:getChildByName("avatar_mask"):setVisible(false)
		var_72_6:getChildByName("chosen"):setVisible(false)
	end

	arg_72_0:moveFadeOutAction(var_72_1, var_72_2, arg_72_1)

	for iter_72_0 = #arg_72_0.team_, var_72_4 + 1, -1 do
		local var_72_7 = arg_72_0.team_[iter_72_0]
		local var_72_8, var_72_9 = arg_72_0:nodeByName("avatar" .. iter_72_0 - 1):getPosition()

		transition.stopTarget(var_72_7)
		transition.moveTo(arg_72_0.team_[iter_72_0], {
			time = 0.3,
			x = var_72_8,
			y = var_72_9
		})

		arg_72_0.team_[iter_72_0].iniCell_.teamNo_ = iter_72_0 - 1
	end

	table.remove(arg_72_0.team_, var_72_4)
	table.remove(arg_72_0.select_, var_72_4)

	if arg_72_1.type == var_0_25.RENT_HERO then
		arg_72_0.isSelectMerHero = false
		arg_72_0.selectMerHero = nil
	end

	var_72_3.teamNo_ = nil

	arg_72_0:updateScore()
end

function var_0_0.clickPetBottomAvatar(arg_73_0, arg_73_1)
	if arg_73_1.isAnimated_ then
		return
	end

	local var_73_0, var_73_1 = arg_73_0:nodeByName("list_layer"):getPosition()
	local var_73_2 = arg_73_1.iniCell_
	local var_73_3 = 1

	if arg_73_0.petSelect_[var_73_3] ~= teamcell.heroModel then
		return
	end

	if var_73_2 and not tolua.isnull(var_73_2) then
		local var_73_4 = var_73_2:convertToWorldSpace(cc.p(0, 0))

		var_73_0, var_73_1 = var_73_4.x, var_73_4.y

		local var_73_5 = var_73_2:getChildByName("layout")

		var_73_5:getChildByName("avatar_mask"):setVisible(false)
		var_73_5:getChildByName("chosen"):setVisible(false)
	end

	arg_73_0:moveFadeOutAction(var_73_0, var_73_1, arg_73_1)
	table.remove(arg_73_0.petTeam_, var_73_3)
	table.remove(arg_73_0.petSelect_, var_73_3)

	if var_73_2 then
		var_73_2.teamNo_ = nil
	end

	arg_73_0:updateScore()
end

function var_0_0.getTeamNo(arg_74_0, arg_74_1)
	for iter_74_0, iter_74_1 in ipairs(arg_74_0.team_) do
		if teamcell.heroModel:getDistance() < iter_74_1.data:getDistance() then
			table.insert(arg_74_0.team_, iter_74_0, arg_74_1)
			table.insert(arg_74_0.select_, iter_74_0, teamcell.heroModel)

			return iter_74_0
		end
	end

	table.insert(arg_74_0.team_, arg_74_1)
	table.insert(arg_74_0.select_, teamcell.heroModel)

	return #arg_74_0.team_
end

function var_0_0.getPetTeamNo(arg_75_0, arg_75_1)
	table.insert(arg_75_0.petTeam_, arg_75_1)
	table.insert(arg_75_0.petSelect_, teamcell.heroModel)

	return #arg_75_0.petTeam_
end

function var_0_0.widgetSet(arg_76_0, arg_76_1)
	for iter_76_0, iter_76_1 in ipairs(arg_76_1:getChildren()) do
		if iter_76_1 ~= nil then
			iter_76_1:setCascadeOpacityEnabled(true)
			arg_76_0:widgetSet(iter_76_1)
		end
	end
end

function var_0_0.moveFadeOutAction(arg_77_0, arg_77_1, arg_77_2, arg_77_3, arg_77_4)
	arg_77_0:widgetSet(arg_77_3)
	arg_77_3:setCascadeOpacityEnabled(true)

	local var_77_0 = cc.Spawn:create(cc.FadeOut:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_77_1, arg_77_2)))

	arg_77_3:runActionOnce(var_77_0, true, arg_77_4)
end

function var_0_0.moveFadeInAction(arg_78_0, arg_78_1, arg_78_2, arg_78_3, arg_78_4)
	arg_78_0:widgetSet(arg_78_3)
	arg_78_3:setCascadeOpacityEnabled(true)
	arg_78_3:setOpacity(0)

	local var_78_0 = cc.Spawn:create(cc.FadeIn:create(0.4), cc.MoveTo:create(0.5, cc.p(arg_78_1, arg_78_2)))

	arg_78_3:runActionOnce(var_78_0, false, arg_78_4)
end

function var_0_0.getBattlepetBtn(arg_79_0)
	if not arg_79_0.battlepetBtn_ then
		arg_79_0.battlepetBtn_ = arg_79_0:nodeByName("button_battle")

		arg_79_0.battlepetBtn_:addTouchEventListener(function(arg_80_0, arg_80_1)
			if not arg_79_0:checkCanStartBattle() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_10:translation("BATTLE_NO_HERO")
				})

				return
			end

			if arg_80_1 == ccui.TouchEventType.ended and not arg_79_0.battleBegan then
				xyd.playButtonSound()

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if arg_79_0.selectMerHero and not arg_79_0.selectMerHero.have_rent then
					local var_80_0 = {
						hero = arg_79_0.selectMerHero,
						type = xyd.ConfirmRent.HERO
					}

					xyd.WindowManager.get():openWindow("confirm_rent", var_80_0)
				elseif arg_79_0.isSelectMerPet and arg_79_0.selectMerPet.can_rent then
					local var_80_1 = {
						hero = arg_79_0.selectMerPet,
						type = xyd.ConfirmRent.PET
					}

					xyd.WindowManager.get():openWindow("confirm_rent", var_80_1)
				else
					arg_79_0.battleBegan = true

					arg_79_0:startBattle()
				end
			end
		end)
		arg_79_0.battlepetBtn_:setVisible(true)
		arg_79_0:nodeByName("button_ok"):setVisible(false)
	end

	return arg_79_0.battlepetBtn_
end

function var_0_0.checkCanStartBattle(arg_81_0)
	if #arg_81_0.select_ < 1 then
		return false
	elseif #arg_81_0.select_ == 1 and (arg_81_0.select_[1][var_0_19] < 0 or arg_81_0.selectMerHero) then
		return false
	end

	return true
end

function var_0_0.recordFormation(arg_82_0)
	if arg_82_0.isAwakeCampaign then
		for iter_82_0, iter_82_1 in pairs(arg_82_0.team_) do
			if iter_82_1.type == var_0_25.SELF_HERO and iter_82_1.data:getTableID() == arg_82_0.awakeHero:getTableID() then
				arg_82_0.isAwakeCampaign = true

				return
			else
				arg_82_0.isAwakeCampaign = false
			end
		end
	end

	local var_82_0 = arg_82_0.campaignType
	local var_82_1 = {}

	if var_82_0 == xyd.CampaignType.MARCH then
		for iter_82_2, iter_82_3 in pairs(arg_82_0.team_) do
			if iter_82_3.type == var_0_25.RENT_HERO then
				table.insert(var_82_1, -iter_82_3.data:getHeroID())
			else
				table.insert(var_82_1, iter_82_3.data:getHeroID())
			end
		end
	else
		for iter_82_4, iter_82_5 in ipairs(arg_82_0.team_) do
			if iter_82_5.type ~= var_0_25.RENT_HERO then
				table.insert(var_82_1, iter_82_5.data:getHeroID())
			end
		end
	end

	local var_82_2 = ""

	for iter_82_6, iter_82_7 in ipairs(var_82_1) do
		var_82_2 = var_82_2 .. string.format("%d|", iter_82_7)
	end

	if arg_82_0:isPetOpen() and next(arg_82_0.petTeam_) then
		local var_82_3 = ""

		for iter_82_8, iter_82_9 in ipairs(arg_82_0.petTeam_) do
			if iter_82_9.type ~= var_0_27.RENT_PET then
				var_82_3 = var_82_3 .. string.format("%d|", iter_82_9.data:getPetID())
			end
		end

		var_82_2 = var_82_2 .. "," .. var_82_3
	end

	xyd.db.formation:setFormationData(var_82_0, var_82_2)
end

function var_0_0.startBattle(arg_83_0)
	if next(arg_83_0.team_) == nil then
		return
	end

	arg_83_0:recordFormation()
	arg_83_0:startCampaignBattle()
end

function var_0_0.getBattleID(arg_84_0)
	local var_84_0
	local var_84_1
	local var_84_2
	local var_84_3 = false

	if arg_84_0.campaignType == xyd.CampaignType.NORMAL and arg_84_0.campaignID ~= 0 then
		local var_84_4 = xyd.tables.campaign:firstFightID(arg_84_0.campaignID)
		local var_84_5 = arg_84_0.selfPlayer.worldMaps_[arg_84_0.campaignID].star or 0

		if var_84_4 ~= 0 and var_84_5 <= 0 then
			var_84_0 = var_84_4
			var_84_3 = true
		else
			var_84_0 = arg_84_0.battleID or xyd.tables.campaign:fightID(arg_84_0.campaignID)
		end
	else
		var_84_0 = arg_84_0.battleID or xyd.tables.campaign:fightID(arg_84_0.campaignID)
	end

	return var_84_0, var_84_3
end

function var_0_0.startCampaignBattle(arg_85_0)
	return
end

function var_0_0.getFormationStr(arg_86_0, arg_86_1)
	local var_86_0 = ""

	for iter_86_0, iter_86_1 in ipairs(arg_86_1) do
		var_86_0 = var_86_0 .. string.format("%d", heroModel[var_0_19])

		if iter_86_0 < #arg_86_1 then
			var_86_0 = var_86_0 .. "|"
		end
	end

	return var_86_0
end

function var_0_0.canHeroJoinBattle(arg_87_0, arg_87_1)
	if arg_87_0.campaignType == xyd.CampaignType.WU then
		if arg_87_1:getFromType() == xyd.HeroFromType.WU then
			return false
		end
	elseif arg_87_0.campaignType == xyd.CampaignType.SHU then
		if arg_87_1:getFromType() == xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_87_0.campaignType == xyd.CampaignType.WEI then
		if arg_87_1:getFromType() ~= xyd.HeroFromType.WU and arg_87_1:getFromType() ~= xyd.HeroFromType.SHU then
			return false
		end
	elseif arg_87_0.type == xyd.SelectTeamType.TREASURE_DEFENSE then
		if not arg_87_0:checkBusyHeros(arg_87_1) then
			return false
		end
	elseif arg_87_0.type == xyd.SelectTeamType.WORLD_BOSS then
		if arg_87_1.color_ < xyd.EquipQuality.PURPLE then
			return false
		end
	elseif arg_87_0.type == xyd.SelectTeamType.ADJUST_TROOP then
		if arg_87_1.level_ < arg_87_0.selfPlayer.lev - xyd.tables.misc.guildBattleLimit then
			return false
		end
	elseif arg_87_0.type == xyd.SelectTeamType.CHALLENGE then
		if var_0_11:modeType(arg_87_0.battleID) == xyd.ChallengeType.KillSteal then
			local var_87_0 = var_0_11:killingHero(arg_87_0.battleID)
			local var_87_1 = xyd.tables.hero:monster2PartnerID(var_87_0)

			if heroModel[var_0_13] == var_87_1 or xyd.tables.hero:beforeAwaken(heroModel[var_0_13]) == var_87_1 or xyd.tables.hero:afterAwaken(heroModel[var_0_13]) == var_87_1 then
				return false
			end
		elseif var_0_11:modeType(arg_87_0.battleID) == xyd.ChallengeType.Protect then
			local var_87_2 = var_0_11:protectedHero(arg_87_0.battleID)
			local var_87_3 = xyd.tables.hero:monster2PartnerID(var_87_2)

			if heroModel[var_0_13] == var_87_3 or xyd.tables.hero:beforeAwaken(heroModel[var_0_13]) == var_87_3 or xyd.tables.hero:afterAwaken(heroModel[var_0_13]) == var_87_3 then
				return false
			end
		end
	end

	if arg_87_0.type == xyd.SelectTeamType.ADVANCED then
		if heroModel[var_0_15] >= var_0_7 then
			return true
		end
	elseif heroModel[var_0_15] >= xyd.tables.battle:levLimit(arg_87_0.campaignID) then
		return true
	end

	return false
end

function var_0_0.initHeros(arg_88_0, arg_88_1, arg_88_2)
	if not var_0_25[arg_88_2] then
		error()
	end

	arg_88_0.totalModels_[arg_88_2] = {}
	arg_88_0.totalModels_[arg_88_2][xyd.DistanceType.ALL] = {}
	arg_88_0.totalModels_[arg_88_2][xyd.DistanceType.QIANPAI] = {}
	arg_88_0.totalModels_[arg_88_2][xyd.DistanceType.ZHONGPAI] = {}
	arg_88_0.totalModels_[arg_88_2][xyd.DistanceType.HOUPAI] = {}

	for iter_88_0, iter_88_1 in ipairs(arg_88_1) do
		table.insert(arg_88_0.totalModels_[arg_88_2][iter_88_1[var_0_21]], iter_88_1)
		table.insert(arg_88_0.totalModels_[arg_88_2][xyd.DistanceType.ALL], iter_88_1)
	end

	arg_88_0:sortTables(arg_88_0.totalModels_[arg_88_2])

	arg_88_0.selectedHeroClass_[arg_88_2] = xyd.DistanceType.ALL
end

function var_0_0.initPets(arg_89_0, arg_89_1, arg_89_2)
	table.sort(arg_89_1, function(arg_90_0, arg_90_1)
		if arg_90_0[var_0_15] ~= arg_90_1[var_0_15] then
			return arg_90_0[var_0_15] > arg_90_1[var_0_15]
		elseif arg_90_0[var_0_17] ~= arg_90_1[var_0_17] then
			return arg_90_0[var_0_17] > arg_90_1[var_0_17]
		else
			return arg_90_0[var_0_16] > arg_90_1[var_0_16]
		end
	end)

	arg_89_0.totalModels_[arg_89_2] = arg_89_1
end

function var_0_0.initPresetTeams(arg_91_0, arg_91_1)
	arg_91_0.totalModels_[arg_91_1] = arg_91_0.selfPlayer:getSaveTeams()
end

function var_0_0.updateFilterHeros(arg_92_0)
	arg_92_0.totalModels_[arg_92_0.leftMenuType_][xyd.DistanceType.FILTER] = {}

	local var_92_0 = {
		0,
		0,
		0
	}
	local var_92_1 = {
		0,
		0,
		0
	}
	local var_92_2 = {
		0,
		0,
		0,
		0
	}

	if arg_92_0.selfPlayer.sortType and arg_92_0.selfPlayer.sortType > 0 then
		local var_92_3 = {}
		local var_92_4 = arg_92_0.selfPlayer.sortType
		local var_92_5 = 1

		while var_92_4 > 0 do
			var_92_3[var_92_5] = var_92_4 % 2
			var_92_5 = var_92_5 + 1
			var_92_4 = math.floor(var_92_4 / 2)
		end

		local var_92_6 = 1

		for iter_92_0 = 10, 1, -1 do
			if iter_92_0 <= 4 then
				if iter_92_0 == 4 then
					var_92_6 = 1
				end

				var_92_2[var_92_6] = var_92_3[iter_92_0]
			elseif iter_92_0 <= 7 then
				if iter_92_0 == 7 then
					var_92_6 = 1
				end

				var_92_1[var_92_6] = var_92_3[iter_92_0]
			elseif iter_92_0 <= 10 and var_92_3[iter_92_0] then
				var_92_0[var_92_6] = var_92_3[iter_92_0]
			end

			var_92_6 = var_92_6 + 1
		end
	else
		var_92_0 = {
			1,
			1,
			1
		}
		var_92_1 = {
			1,
			1,
			1
		}
		var_92_2 = {
			1,
			1,
			1,
			1
		}
	end

	for iter_92_1, iter_92_2 in ipairs(arg_92_0.totalModels_[arg_92_0.leftMenuType_][xyd.DistanceType.ALL]) do
		if var_92_0[iter_92_2[var_0_21] - 1] == 1 and var_92_1[iter_92_2[var_0_22]] == 1 and var_92_2[iter_92_2[var_0_23]] == 1 then
			table.insert(arg_92_0.totalModels_[arg_92_0.leftMenuType_][xyd.DistanceType.FILTER], iter_92_2)
		end
	end
end

function var_0_0.initListview(arg_93_0)
	local var_93_0 = arg_93_0:nodeByName("list_layer")
	local var_93_1 = var_93_0:getContentSize().width
	local var_93_2 = var_93_0:getContentSize().height

	arg_93_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_93_1, var_93_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_93_0)

	arg_93_0.heroList_:setDelegate(handler(arg_93_0, arg_93_0.delegate))
end

function var_0_0.initTextOfList(arg_94_0)
	arg_94_0:nodeByName("lev_limit_txt"):hide()
end

function var_0_0.updateTextOfList(arg_95_0)
	return
end

function var_0_0.sortTables(arg_96_0, arg_96_1)
	for iter_96_0, iter_96_1 in ipairs(arg_96_1) do
		table.sort(iter_96_1, function(arg_97_0, arg_97_1)
			if arg_97_0[var_0_15] ~= arg_97_1[var_0_15] then
				return arg_97_0[var_0_15] > arg_97_1[var_0_15]
			elseif arg_97_0[var_0_17] ~= arg_97_1[var_0_17] then
				return arg_97_0[var_0_17] > arg_97_1[var_0_17]
			else
				return arg_97_0[var_0_16] > arg_97_1[var_0_16]
			end
		end)
	end
end

function var_0_0.loadPreFormation(arg_98_0)
	if arg_98_0.preSelect_ then
		return
	end

	local var_98_0 = xyd.db.formation:getFormationData(arg_98_0.campaignType) or {}

	if not var_98_0[1] then
		local var_98_1 = {}
	end

	if not var_98_0[2] then
		local var_98_2 = {}
	end

	arg_98_0.preSelect_ = {}
	arg_98_0.prePet_ = {}
end

function var_0_0.canRentHero(arg_99_0)
	return true
end

function var_0_0.isPetOpen(arg_100_0)
	return arg_100_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET)
end

function var_0_0.formatRegionArenaHeros(arg_101_0, arg_101_1)
	for iter_101_0, iter_101_1 in pairs(arg_101_1) do
		if iter_101_1:isHaveAwakenItem() and not iter_101_1:isAwaken() then
			local var_101_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_101_1 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_101_2 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_0, var_101_1, var_101_2)
		elseif iter_101_1:isAwaken() then
			local var_101_3 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_101_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_101_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_3, var_101_4, var_101_5)
		else
			local var_101_6 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_101_7 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_101_8 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_101_0:renewHeroInfo(iter_101_1, var_101_6, var_101_7, var_101_8)
		end

		iter_101_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_101_1:updatePracticeAwardAttr()
	end
end

function var_0_0.formatRegionArenaPets(arg_102_0, arg_102_1)
	for iter_102_0, iter_102_1 in pairs(arg_102_1) do
		if iter_102_1:isHaveAwakenItem() and not iter_102_1:isAwaken() then
			local var_102_0 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_102_1 = {
				1,
				1,
				1
			}

			arg_102_0:renewPetInfo(iter_102_1, var_102_0, var_102_1)
		elseif iter_102_1:isAwaken() then
			local var_102_2 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_102_3 = {
				1,
				1,
				1
			}

			arg_102_0:renewPetInfo(iter_102_1, var_102_2, var_102_3)
		else
			local var_102_4 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_102_5 = {
				0,
				1,
				1
			}

			arg_102_0:renewPetInfo(iter_102_1, var_102_4, var_102_5)
		end

		iter_102_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_102_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_103_0, arg_103_1, arg_103_2, arg_103_3, arg_103_4)
	local var_103_0 = xyd.tables.misc.regionHeroColor

	arg_103_1.level_, arg_103_1.color_ = xyd.tables.misc.regionHeroLevel, var_103_0
	arg_103_1.skillLev_ = {}
	arg_103_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_103_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_103_1.color_ >= xyd.EquipQuality.GREEN then
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_103_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_103_1.color_ >= xyd.EquipQuality.BLUE then
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_103_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_103_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_103_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_103_1:isAwaken() then
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_103_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_103_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_103_1.equips_ = {}

	for iter_103_0 = 1, var_0_6 do
		table.insert(arg_103_1.equips_, tonumber(arg_103_4[iter_103_0]))
	end

	arg_103_1.fumo_ = {}

	for iter_103_1 = 1, var_0_6 do
		table.insert(arg_103_1.fumo_, tonumber(arg_103_3[iter_103_1]))
	end

	arg_103_1.fumoLev_ = {}

	for iter_103_2 = 1, var_0_6 do
		local var_103_1 = arg_103_1:getEquipByIndex(iter_103_2)

		table.insert(arg_103_1.fumoLev_, tonumber(var_103_1:getMaxFumoStar()))
	end
end

function var_0_0.renewPetInfo(arg_104_0, arg_104_1, arg_104_2, arg_104_3)
	local var_104_0 = 14

	arg_104_1.level_, arg_104_1.color_ = 90, var_104_0
	arg_104_1.skillLev_ = {}
	arg_104_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_104_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_104_1.color_ >= xyd.EquipQuality.GREEN then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_104_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_104_1.color_ >= xyd.EquipQuality.BLUE then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_104_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_104_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_104_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_104_1:isAwaken() then
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_104_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_104_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_104_1.equips_ = {}

	for iter_104_0 = 1, var_0_6 do
		table.insert(arg_104_1.equips_, tonumber(arg_104_3[iter_104_0]))
	end
end

function var_0_0.getHeroModels(arg_105_0)
	local var_105_0 = {}

	for iter_105_0, iter_105_1 in ipairs(arg_105_0.selfPlayer.heros_) do
		if arg_105_0:canHeroJoinBattle(iter_105_1) then
			local var_105_1 = iter_105_1:isAwakeTwice() and 2 or iter_105_1:isAwaken() and 1 or 0
			local var_105_2 = {
				iter_105_1:getTableID(),
				iter_105_1:getName(),
				iter_105_1:getLevel(),
				iter_105_1:getColor(),
				iter_105_1:getStar(),
				iter_105_1:getAvatar(),
				iter_105_1:getHeroID(),
				var_105_1,
				iter_105_1:getDistanceType(),
				iter_105_1:getHeroType(),
				iter_105_1:getFromType()
			}

			table.insert(var_105_0, var_105_2)
		end
	end

	return var_105_0
end

function var_0_0.getRentHeroModels(arg_106_0)
	local var_106_0 = {}

	for iter_106_0, iter_106_1 in ipairs(arg_106_0.allTeamHeros) do
		if arg_106_0:canHeroJoinBattle(iter_106_1) then
			local var_106_1 = iter_106_1:isAwakeTwice() and 2 or iter_106_1:isAwaken() and 1 or 0
			local var_106_2 = {
				iter_106_1:getTableID(),
				iter_106_1:getName(),
				iter_106_1:getLevel(),
				iter_106_1:getColor(),
				iter_106_1:getStar(),
				iter_106_1:getAvatar(),
				iter_106_1:getHeroID(),
				var_106_1,
				iter_106_1:getDistanceType(),
				isRent = true,
				player_name = iter_106_1.player_name,
				rent_need_mana = iter_106_1.rent_need_mana,
				can_rent = iter_106_1.can_rent,
				player_id = iter_106_1.player_id
			}

			table.insert(var_106_0, var_106_2)
		end
	end

	return var_106_0
end

function var_0_0.getPets(arg_107_0)
	local var_107_0 = {}

	for iter_107_0, iter_107_1 in ipairs(arg_107_0.selfPlayer.collectedPets or {}) do
		if iter_107_1.is_show_ then
			local var_107_1 = iter_107_1:isAwaken() and 1 or 0
			local var_107_2 = {
				iter_107_1:getTableID(),
				iter_107_1:getName(),
				iter_107_1:getLevel(),
				iter_107_1:getColor(),
				iter_107_1:getStar(),
				iter_107_1:getAvatar(),
				iter_107_1:getHeroID(),
				var_107_1
			}

			table.insert(var_107_0, var_107_2)
		end
	end

	return var_107_0
end

function var_0_0.initRegionHeros(arg_108_0, arg_108_1, arg_108_2, arg_108_3)
	for iter_108_0, iter_108_1 in pairs(arg_108_2) do
		local var_108_0 = arg_108_0:checkHeroExit(arg_108_1, iter_108_1.table_id)

		if not var_108_0 and arg_108_3 then
			-- block empty
		else
			if iter_108_1.is_summon == 1 and not var_108_0 then
				var_108_0 = var_0_1.new()

				var_108_0:initUnCollected(iter_108_1.table_id)
				table.insert(arg_108_1, var_108_0)
			end

			if iter_108_1.add_star > 0 then
				local var_108_1 = heroModel[var_0_17]

				if var_108_1 + iter_108_1.add_star > xyd.MAX_STAR_LEVEL then
					var_108_0:setStar(xyd.MAX_STAR_LEVEL)
				else
					var_108_0:setStar(var_108_1 + iter_108_1.add_star)
				end
			end

			if iter_108_1.is_awake == 1 and not var_108_0:isAwaken() then
				var_108_0:setTableID(xyd.tables.hero:afterAwaken(iter_108_1.table_id))
			end
		end
	end
end

function var_0_0.checkHeroExit(arg_109_0, arg_109_1, arg_109_2)
	local var_109_0 = false

	for iter_109_0, iter_109_1 in pairs(arg_109_1) do
		local var_109_1 = heroModel[var_0_13]

		if var_109_1 == arg_109_2 then
			var_109_0 = iter_109_1

			break
		end

		if iter_109_1:isAwaken() then
			var_109_1 = iter_109_1:beforeAwakenID()
		end

		if var_109_1 == arg_109_2 then
			var_109_0 = iter_109_1

			break
		end
	end

	return var_109_0
end

function var_0_0.isRecommend(arg_110_0, arg_110_1)
	local var_110_0 = heroModel[var_0_13]

	if var_0_12:beforeAwaken(var_110_0) > 0 then
		var_110_0 = var_0_12:beforeAwaken(var_110_0)
	end

	for iter_110_0 = 1, #arg_110_0.recommendHeros do
		if var_110_0 == arg_110_0.recommendHeros[iter_110_0] then
			return true
		end
	end

	return false
end

function var_0_0.initRecommend(arg_111_0)
	local var_111_0 = arg_111_0:nodeByName("list_layer"):getContentSize()

	arg_111_0:nodeByName("list_layer"):setContentSize(var_111_0.width, var_111_0.height - 140)

	local var_111_1 = cc.p(arg_111_0:nodeByName("lev_limit_txt"):getPosition())

	arg_111_0:nodeByName("lev_limit_txt"):setPosition(var_111_1.x, var_111_1.y - 130)
	arg_111_0:nodeByName("recommend_layer"):setVisible(true)
	arg_111_0:nodeByName("recommend_txt"):setString(var_0_10:translation("RECOMMENDED_HERO"))

	for iter_111_0 = 1, #arg_111_0.recommendHeros do
		xyd.setAvatarBorder(arg_111_0.recommendHeros[iter_111_0], arg_111_0:nodeByName("recommend_hero" .. iter_111_0), true, var_0_12:initialStar(arg_111_0.recommendHeros[iter_111_0]))
	end
end

function var_0_0.isBanned(arg_112_0, arg_112_1)
	local var_112_0 = heroModel[var_0_13]

	if var_0_12:beforeAwaken(var_112_0) > 0 then
		var_112_0 = var_0_12:beforeAwaken(var_112_0)
	end

	for iter_112_0 = 1, #arg_112_0.bannedHeros do
		if var_112_0 == arg_112_0.bannedHeros[iter_112_0] then
			return true
		end
	end

	return false
end

function var_0_0.checkHeroIsNotUse(arg_113_0, arg_113_1)
	if (arg_113_0.type == xyd.SelectTeamType.ARENA or arg_113_0.type == xyd.SelectTeamType.ARENA_DEFENSE) and arg_113_0:checkHeroIsSeal(arg_113_1) then
		return true
	elseif arg_113_0.type == xyd.SelectTeamType.CONQUER_SCHOOL and arg_113_0:checkHeroIsConquerUsed(arg_113_1) then
		return true
	end

	return false
end

function var_0_0.checkHeroIsConquerUsed(arg_114_0, arg_114_1)
	if arg_114_0.conquerUsedTeam and arg_114_0.conquerUsedTeam.heroIDs then
		local var_114_0 = arg_114_0.conquerUsedTeam.heroIDs

		for iter_114_0, iter_114_1 in pairs(var_114_0) do
			if iter_114_1 == heroModel[var_0_19] then
				return true
			end
		end
	end

	return false
end

function var_0_0.checkPetIsConquerUsed(arg_115_0, arg_115_1)
	if arg_115_0.conquerUsedTeam and arg_115_0.conquerUsedTeam.petIDs then
		local var_115_0 = arg_115_0.conquerUsedTeam.petIDs

		for iter_115_0, iter_115_1 in pairs(var_115_0) do
			if iter_115_1 == arg_115_1:getPetID() then
				return true
			end
		end
	end

	return false
end

function var_0_0.checkHeroIsSeal(arg_116_0, arg_116_1)
	if arg_116_0.sealHeroID and arg_116_0.sealHeroID > 0 and arg_116_1:getFirstTableID() == arg_116_0.sealHeroID then
		return true
	end

	return false
end

function var_0_0.checkCanPresetTeam(arg_117_0)
	if arg_117_0.type == xyd.SelectTeamType.HERO_PRESET then
		return false
	end

	return true
end

function var_0_0.getCurrHeros(arg_118_0, arg_118_1)
	if arg_118_1 then
		return arg_118_0.totalModels_[arg_118_0.leftMenuType_][arg_118_0.selectedHeroClass_[arg_118_0.leftMenuType_]][arg_118_1]
	end

	return arg_118_0.totalModels_[arg_118_0.leftMenuType_][arg_118_0.selectedHeroClass_[arg_118_0.leftMenuType_]]
end

function var_0_0.getCurrPets(arg_119_0, arg_119_1)
	if arg_119_1 then
		return arg_119_0.totalModels_[arg_119_0.leftMenuType_][arg_119_1]
	end

	return arg_119_0.totalModels_[arg_119_0.leftMenuType_]
end

return var_0_0
