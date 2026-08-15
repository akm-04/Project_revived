local var_0_0 = class("HeroListCell", import("app.common.ui.BaseNode"))
local var_0_1 = import("app.windows.HeroEquipItem")
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.model
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.translation
local var_0_6 = {
	BORDER = -60,
	LEV = 30,
	EXTRA_BORDER = 0,
	CARD = -100,
	FAVOR = 10,
	STARS = 20,
	NAME_BG = -80,
	QUALITY = 40,
	ATTR = 15,
	NAME = -70,
	MASK = -90
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0)

	arg_1_0.type = arg_1_1.type or xyd.HeroListDisplayType.HERO
	arg_1_0.hero = arg_1_1.hero

	if not arg_1_0.hero then
		return
	end

	arg_1_0.tableID = arg_1_0.hero:getTableID()
	arg_1_0.star = arg_1_0.hero:getStar()
	arg_1_0.level = arg_1_0.hero:getLevel()
	arg_1_0.inscriptLev = arg_1_0.hero:getInscriptionKuangLevel()
	arg_1_0.color = arg_1_0.hero:getColor()
	arg_1_0.hasEvent = arg_1_1.hasEvent or 1
	arg_1_0.idx = arg_1_1.idx or 1
	arg_1_0.frontRes = "windows/hero_collect/hero_cell_front.csb"
	arg_1_0.backRes = "windows/hero_collect/hero_cell_back.csb"
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.layout(arg_2_0)
	arg_2_0:setContentSize(202, 282)

	if arg_2_0.type == xyd.HeroListDisplayType.HERO then
		arg_2_0:createFront()
		arg_2_0:addSmallCard()
		arg_2_0:onRegister()
	elseif arg_2_0.type == xyd.HeroListDisplayType.EQUIP then
		arg_2_0:createBack()
		arg_2_0:addSmallCard()
		arg_2_0:onRegister()
	elseif arg_2_0.type == xyd.HeroListDisplayType.ONLYSHOW then
		arg_2_0:createCard()
	end
end

function var_0_0.createCard(arg_3_0)
	arg_3_0.frontCard = class("HeroCard", import("app.common.ui.BaseNode")).new()

	arg_3_0.frontCard:loadRes(arg_3_0.frontRes)
	arg_3_0.frontCard:addTo(arg_3_0)
	arg_3_0.frontCard:setPosition(0, 0)

	local var_3_0 = arg_3_0:getHeroElementIcon()
	local var_3_1, var_3_2 = arg_3_0.frontCard:nodeByName("pos_quality_txt"):getPosition()

	if var_3_0 then
		var_3_1 = var_3_1 - 10
	else
		var_3_0 = arg_3_0:getHeroQualityIcon()
	end

	if var_3_0 then
		var_3_0:addTo(arg_3_0.frontCard:background(), var_0_6.QUALITY)
		var_3_0:setAnchorPoint(0.5, 0.5)
		var_3_0:setPosition(var_3_1, var_3_2)
		var_3_0:setName("icon_quality")
	end

	if arg_3_0.level > 0 then
		arg_3_0.frontCard:nodeByName("txt_lev"):setString("Lv." .. arg_3_0.level)
		arg_3_0.frontCard:nodeByName("txt_lev"):enableOutline(xyd.convertHex2RGB("#ff331f1f"), 2)
	end

	arg_3_0.frontCard:nodeByName("icon_collocation"):setVisible(arg_3_0.hero:isCollocation())
	arg_3_0.frontCard:nodeByName("txt_name"):setString(var_0_2:name(arg_3_0.tableID))
	arg_3_0.frontCard:nodeByName("bg_hero_name"):setLocalZOrder(var_0_6.NAME_BG)

	local var_3_3 = xyd.getHeroAttrIcon(arg_3_0.tableID)

	var_3_3:addTo(arg_3_0.frontCard:background(), var_0_6.ATTR)
	var_3_3:setAnchorPoint(0.5, 0.5)
	var_3_3:setPosition(arg_3_0.frontCard:nodeByName("pos_icon_attr"):getPosition())
	var_3_3:setName("attr_icon")
	arg_3_0:updateFavorProgress()

	local var_3_4 = xyd.createHeroStars(arg_3_0.hero)

	var_3_4:addTo(arg_3_0.frontCard:background(), var_0_6.STARS)
	var_3_4:setAnchorPoint(0.5, 0.5)
	var_3_4:setPosition(arg_3_0.frontCard:nodeByName("pos_stars"):getPosition())
	var_3_4:setName("stars")

	local var_3_5 = xyd.getSmallCardBorder(arg_3_0.hero, displayType == xyd.HeroListDisplayType.EQUIP)

	if var_3_5 then
		local var_3_6 = arg_3_0.frontCard:background()

		if var_3_6:getChildByName("border") then
			var_3_6:removeChildByName("border")
		end

		var_3_5:setName("border")
	end

	var_3_5:addTo(arg_3_0.frontCard:background(), var_0_6.BORDER)
	var_3_5:setAnchorPoint(0.5, 0.5)
	var_3_5:setPosition(arg_3_0.frontCard:getWidth() / 2 + 2, arg_3_0.frontCard:getHeight() / 2 - 2)
	arg_3_0:addExtraBorder(true)
	arg_3_0.frontCard:nodeByName("bg_can_summon"):setVisible(false)
	arg_3_0.frontCard:nodeByName("bg_can_evolve"):setVisible(false)
	arg_3_0:hideStoneProgress(true)

	local var_3_7
	local var_3_8 = xyd.getNewSmallCard(arg_3_0.hero)

	var_3_8:addTo(arg_3_0)
	var_3_8:setAnchorPoint(0.5, 0.5)
	var_3_8:setPosition(arg_3_0:getWidth() / 2 + 2, arg_3_0:getHeight() / 2 - 2)
	var_3_8:setLocalZOrder(var_0_6.CARD)
end

function var_0_0.createFront(arg_4_0)
	arg_4_0.frontCard = class("HeroCard", import("app.common.ui.BaseNode")).new()

	arg_4_0.frontCard:loadRes(arg_4_0.frontRes)
	arg_4_0.frontCard:addTo(arg_4_0)
	arg_4_0.frontCard:setPosition(0, 0)

	if arg_4_0.hero:isCollected() then
		local var_4_0 = arg_4_0:getHeroElementIcon()
		local var_4_1, var_4_2 = arg_4_0.frontCard:nodeByName("pos_quality_txt"):getPosition()

		if var_4_0 then
			var_4_1 = var_4_1 - 10
		else
			var_4_0 = arg_4_0:getHeroQualityIcon()
		end

		if var_4_0 then
			var_4_0:addTo(arg_4_0.frontCard:background(), var_0_6.QUALITY)
			var_4_0:setAnchorPoint(0.5, 0.5)
			var_4_0:setPosition(var_4_1, var_4_2)
			var_4_0:setName("icon_quality")
		end

		arg_4_0.frontCard:nodeByName("txt_lev"):setString("Lv." .. arg_4_0.level)
		arg_4_0.frontCard:nodeByName("txt_lev"):enableOutline(xyd.convertHex2RGB("#ff331f1f"), 2)
		arg_4_0.frontCard:nodeByName("icon_collocation"):setVisible(arg_4_0.hero:isCollocation())
	end

	arg_4_0.frontCard:nodeByName("txt_name"):setString(var_0_2:name(arg_4_0.tableID))
	arg_4_0.frontCard:nodeByName("bg_hero_name"):setLocalZOrder(var_0_6.NAME_BG)

	local var_4_3 = xyd.getHeroAttrIcon(arg_4_0.tableID)

	var_4_3:addTo(arg_4_0.frontCard:background(), var_0_6.ATTR)
	var_4_3:setAnchorPoint(0.5, 0.5)
	var_4_3:setPosition(arg_4_0.frontCard:nodeByName("pos_icon_attr"):getPosition())
	var_4_3:setName("attr_icon")
	arg_4_0:updateFavorProgress()

	local var_4_4 = xyd.createHeroStars(arg_4_0.hero)

	var_4_4:addTo(arg_4_0.frontCard:background(), var_0_6.STARS)
	var_4_4:setAnchorPoint(0.5, 0.5)
	var_4_4:setPosition(arg_4_0.frontCard:nodeByName("pos_stars"):getPosition())
	var_4_4:setName("stars")
	arg_4_0:addBorder(true)
	arg_4_0:addExtraBorder(true)
	arg_4_0.frontCard:nodeByName("bg_can_summon"):setVisible(false)
	arg_4_0.frontCard:nodeByName("bg_can_evolve"):setVisible(false)
	arg_4_0:hideStoneProgress(true)

	if arg_4_0.hero:canSummon() then
		arg_4_0.frontCard:nodeByName("bg_can_summon"):setVisible(true)

		local var_4_5 = xyd.createAutoFixLabel({
			height = 25,
			fontSize = 20,
			txtColor = "#ffffff",
			width = 100,
			text = var_0_5:translation("TXT_HERO_LIST_CAN_SUMMON"),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_4_5:addTo(arg_4_0.frontCard:background())
		var_4_5:setAnchorPoint(0.5, 0.5)
		var_4_5:setPosition(arg_4_0.frontCard:nodeByName("bg_can_summon"):getPosition())
	elseif not arg_4_0.hero:isCollected() then
		arg_4_0:showStoneProgress(true)
	end

	if not arg_4_0.hero:canSummon() and arg_4_0.hero:canEnvolve() then
		arg_4_0.frontCard:nodeByName("bg_can_evolve"):setVisible(true)

		local var_4_6 = xyd.createAutoFixLabel({
			height = 25,
			fontSize = 20,
			txtColor = "#ffffff",
			width = 100,
			text = var_0_5:translation("TXT_HERO_LIST_CAN_ENVOLVE"),
			align = cc.ui.TEXT_ALIGN_CENTER,
			valign = cc.ui.TEXT_VALIGN_CENTER
		})

		var_4_6:addTo(arg_4_0.frontCard:background())
		var_4_6:setAnchorPoint(0.5, 0.5)
		var_4_6:setPosition(arg_4_0.frontCard:nodeByName("bg_can_evolve"):getPosition())
		var_4_6:setName("can_evolve_txt")
	end
end

function var_0_0.createBack(arg_5_0)
	arg_5_0.backCard = class("HeroCard", import("app.common.ui.BaseNode")).new()

	arg_5_0.backCard:loadRes(arg_5_0.backRes)
	arg_5_0.backCard:addTo(arg_5_0)
	arg_5_0.backCard:setPosition(0, 0)
	arg_5_0.backCard:nodeByName("bg_hero_mask"):setLocalZOrder(var_0_6.MASK)

	if arg_5_0.hero:isCollected() then
		arg_5_0:showEquips()
	end

	arg_5_0:showStoneProgress(false)
	arg_5_0:addBorder(false)
	arg_5_0:addExtraBorder(false)
end

function var_0_0.showStoneProgress(arg_6_0, arg_6_1)
	local var_6_0

	if arg_6_1 then
		var_6_0 = arg_6_0.frontCard
	else
		var_6_0 = arg_6_0.backCard
	end

	var_6_0:nodeByName("stone_progress"):setVisible(true)
	var_6_0:nodeByName("txt_stone"):setVisible(true)
	var_6_0:nodeByName("bg_stone_progress"):setVisible(true)
	var_6_0:nodeByName("icon_stone"):setVisible(true)
	var_6_0:nodeByName("txt_stone"):enableOutline(xyd.convertHex2RGB("#ff331f1f"), 2)
	arg_6_0:updateStoneProgress(var_6_0)
end

function var_0_0.updateStoneProgress(arg_7_0, arg_7_1)
	arg_7_1:nodeByName("icon_top_envolve"):setVisible(false)

	local var_7_0 = arg_7_1:nodeByName("icon_super_tip")

	if var_7_0 then
		var_7_0:setVisible(false)
	end

	if not xyd.isSuperHero(arg_7_0.hero) then
		if arg_7_0.star >= xyd.MAX_STAR_LEVEL and arg_7_0.hero:isCollected() then
			arg_7_1:nodeByName("stone_progress"):setPercent(100)
			arg_7_1:nodeByName("icon_top_envolve"):setVisible(true)
		elseif arg_7_0.hero:canSummon() then
			arg_7_1:nodeByName("txt_stone"):setString(var_0_5:translation("TXT_HERO_LIST_CAN_SUMMON"))
			arg_7_1:nodeByName("txt_stone"):setColor(xyd.convertHex2RGB("#77f15d"))
		elseif not arg_7_0.hero:isCollected() then
			arg_7_1:nodeByName("txt_stone"):setString(tostring(arg_7_0.hero:getSuiPian()) .. "/" .. tostring(xyd.TotalStarSuipian[arg_7_0.star]))
			arg_7_1:nodeByName("txt_stone"):setColor(xyd.convertHex2RGB("#ffff00"))
			arg_7_1:nodeByName("stone_progress"):setPercent(math.min(arg_7_0.hero:getSuiPian() / xyd.TotalStarSuipian[arg_7_0.star] * 100, 100))
		else
			arg_7_1:nodeByName("txt_stone"):setString(tostring(arg_7_0.hero:getSuiPian()) .. "/" .. tostring(xyd.StarLevelSuipian[arg_7_0.star + 1]))
			arg_7_1:nodeByName("txt_stone"):setColor(xyd.convertHex2RGB("#ffff00"))
			arg_7_1:nodeByName("stone_progress"):setPercent(math.min(arg_7_0.hero:getSuiPian() / xyd.StarLevelSuipian[arg_7_0.star + 1] * 100, 100))
		end
	elseif arg_7_0.star >= xyd.SUPER_HERO_TOTAL_STARS then
		arg_7_1:nodeByName("stone_progress"):setPercent(100)
		arg_7_1:nodeByName("icon_top_envolve"):setVisible(true)
	elseif arg_7_0.star <= xyd.MAX_STAR_LEVEL then
		arg_7_1:nodeByName("stone_progress"):setPercent(100)

		if var_7_0 then
			var_7_0:setVisible(true)
		end
	else
		arg_7_1:nodeByName("stone_progress"):setPercent(math.min(arg_7_0.hero:getSuiPian() / xyd.StarLevelSuipian[arg_7_0.star + 1] * 100, 100))
		arg_7_1:nodeByName("txt_stone"):setString(tostring(arg_7_0.hero:getSuiPian()) .. "/" .. tostring(xyd.StarLevelSuipian[arg_7_0.star + 1]))
	end
end

function var_0_0.hideStoneProgress(arg_8_0, arg_8_1)
	if arg_8_1 then
		arg_8_0.frontCard:nodeByName("stone_progress"):setVisible(false)
		arg_8_0.frontCard:nodeByName("txt_stone"):setVisible(false)
		arg_8_0.frontCard:nodeByName("bg_stone_progress"):setVisible(false)
		arg_8_0.frontCard:nodeByName("icon_stone"):setVisible(false)
		arg_8_0.frontCard:nodeByName("icon_top_envolve"):setVisible(false)
	else
		arg_8_0.backCard:nodeByName("stone_progress"):setVisible(false)
		arg_8_0.backCard:nodeByName("txt_stone"):setVisible(false)
		arg_8_0.backCard:nodeByName("bg_stone_progress"):setVisible(false)
		arg_8_0.backCard:nodeByName("icon_top_envolve"):setVisible(false)
		arg_8_0.backCard:nodeByName("icon_stone"):setVisible(false)
	end
end

function var_0_0.showEquips(arg_9_0)
	for iter_9_0 = 1, xyd.MAX_ITEM_NUM do
		local var_9_0 = arg_9_0.backCard:nodeByName("equip_" .. iter_9_0)

		if var_9_0:getChildByName("back_equip_" .. iter_9_0) then
			var_9_0:removeChildByName("back_equip_" .. iter_9_0)
		end

		local var_9_1 = var_0_1.new({
			hero = arg_9_0.hero,
			idx = iter_9_0
		})

		var_9_1:layout()
		var_9_1:addTo(var_9_0)
		var_9_1:setAnchorPoint(0, 0)
		var_9_1:setPosition(0, 0)
		var_9_1:setName("back_equip_" .. iter_9_0)

		local var_9_2 = arg_9_0.backCard:nodeByName("equip_" .. iter_9_0):getWidth() / var_9_1:getWidth()

		var_9_1:setScale(var_9_2)
	end
end

function var_0_0.updateFavorProgress(arg_10_0, arg_10_1)
	arg_10_1 = arg_10_1 or arg_10_0.hero

	if not arg_10_1:isCollected() or not var_0_2:isOpenDialog(arg_10_0.tableID) then
		if arg_10_0.frontCard and not tolua.isnull(arg_10_0.frontCard) then
			arg_10_0.frontCard:nodeByName("icon_favor_bg"):setVisible(false)
			arg_10_0.frontCard:nodeByName("icon_married"):setVisible(false)
		end

		return
	end

	if arg_10_1:isHeroMarried() then
		if arg_10_0.frontCard and not tolua.isnull(arg_10_0.frontCard) then
			arg_10_0.frontCard:nodeByName("icon_favor_bg"):setVisible(false)
			arg_10_0.frontCard:nodeByName("icon_married"):setVisible(true)
			arg_10_0.frontCard:nodeByName("icon_married"):setLocalZOrder(var_0_6.FAVOR)

			if arg_10_0.favorProgress and not tolua.isnull(arg_10_0.favorProgress) then
				arg_10_0.favorProgress:setVisible(false)
			end
		end
	else
		if arg_10_0.frontCard and not tolua.isnull(arg_10_0.frontCard) then
			arg_10_0.frontCard:nodeByName("icon_favor_bg"):setVisible(true)
			arg_10_0.frontCard:nodeByName("icon_married"):setVisible(false)
			arg_10_0.frontCard:nodeByName("icon_favor_bg"):setLocalZOrder(var_0_6.FAVOR)
		end

		if not arg_10_0.favorProgress or tolua.isnull(arg_10_0.favorProgress) then
			local var_10_0 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/icon_favor_bright.png")
			local var_10_1 = cc.ProgressTimer:create(var_10_0)

			var_10_1:setType(1)
			var_10_1:setMidpoint(cc.p(0.5, 0))
			var_10_1:setBarChangeRate(cc.p(0, 1))
			var_10_1:setAnchorPoint(0.5, 0.5)
			var_10_1:addTo(arg_10_0.frontCard:background(), var_0_6.FAVOR + 1)
			var_10_1:setPosition(arg_10_0.frontCard:nodeByName("pos_favor_progress"):getPosition())
			var_10_1:setName("favor_progress")
			var_10_1:setScale(0.7)

			arg_10_0.favorProgress = var_10_1
		end

		arg_10_0.favorProgress:setPercentage(arg_10_1:getFavorDegree() / var_0_4.libraryFavorLimit * 100)
	end
end

function var_0_0.getHeroElementIcon(arg_11_0)
	local var_11_0 = arg_11_0.hero:getElementType()

	if not var_11_0 or var_11_0 == 0 then
		return
	end

	local var_11_1 = arg_11_0.hero:isActiveSP()
	local var_11_2 = display.newNode()
	local var_11_3
	local var_11_4 = arg_11_0.inscriptLev and "windows/common/hero_common/small_gold_bg.png" or "windows/common/hero_common/small_red_bg.png"

	if xyd.isSuperHero(arg_11_0.hero) then
		var_11_4 = "windows/common/hero_common/small_ur_bg.png"
	end

	xyd.AssetLoader.get():loadSprite(var_11_4):addTo(var_11_2)

	local var_11_5 = "windows/common/hero_common/big_element_" .. var_11_0

	if var_11_1 then
		var_11_5 = var_11_5 .. "sp"
	end

	local var_11_6 = xyd.AssetLoader.get():loadSprite(var_11_5 .. ".png")

	var_11_6:setScale(0.55)
	var_11_6:addTo(var_11_2)

	if arg_11_0.hero:isActiveSP() then
		arg_11_0:addActiveEffeft(var_11_6, var_11_0)
	end

	return var_11_2
end

function var_0_0.addActiveEffeft(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = arg_12_3 or 1
	local var_12_1 = xyd.createEffect("skeletons/ui_effect/element_equip/element_" .. arg_12_2, var_12_0)
	local var_12_2 = arg_12_1:getContentSize()

	var_12_1:addTo(arg_12_1)
	var_12_1:setPosition(var_12_2.width / 2, var_12_2.height / 2)
	var_12_1:play(nil, true)
end

function var_0_0.getHeroQualityIcon(arg_13_0, arg_13_1)
	arg_13_1 = arg_13_1 or arg_13_0.color

	if xyd.Color2Level[arg_13_1] == "" then
		return
	end

	local var_13_0 = "windows/common/hero_common/hero_quality_"
	local var_13_1

	if xyd.isSuperHero(arg_13_0.hero) then
		return
	elseif arg_13_0.inscriptLev then
		if arg_13_0.inscriptLev == 1 then
			return
		end

		var_13_1 = "suit_" .. arg_13_0.inscriptLev
	else
		var_13_1 = tostring(arg_13_1)
	end

	return xyd.AssetLoader.get():loadSprite(var_13_0 .. var_13_1 .. ".png")
end

function var_0_0.addSmallCard(arg_14_0)
	local var_14_0

	if arg_14_0.hero:isCollected() then
		var_14_0 = xyd.getNewSmallCard(arg_14_0.hero)
	else
		var_14_0 = xyd.SpriteLoader.new(var_0_3:newSmallCard(arg_14_0.hero:getModelID()), nil, nil, xyd.DefaultImageType.S_CARD)

		local var_14_1 = cc.FileUtils:getInstance():getStringFromFile("shaders/no_mvp.vsh")
		local var_14_2 = cc.FileUtils:getInstance():getStringFromFile("shaders/grayed_sprite.fsh")
		local var_14_3 = cc.GLProgram:createWithByteArrays(var_14_1, var_14_2)
		local var_14_4 = cc.GLProgramState:create(var_14_3)

		var_14_0:setGLProgramState(var_14_4)
	end

	var_14_0:addTo(arg_14_0)
	var_14_0:setAnchorPoint(0.5, 0.5)
	var_14_0:setPosition(arg_14_0:getWidth() / 2 + 2, arg_14_0:getHeight() / 2 - 2)
	var_14_0:setLocalZOrder(var_0_6.CARD)
end

function var_0_0.addBorder(arg_15_0, arg_15_1)
	local var_15_0

	if arg_15_1 then
		var_15_0 = xyd.HeroListDisplayType.HERO
	else
		var_15_0 = xyd.HeroListDisplayType.EQUIP
	end

	local var_15_1

	if arg_15_0.hero:isCollected() then
		var_15_1 = xyd.getSmallCardBorder(arg_15_0.hero, var_15_0 == xyd.HeroListDisplayType.EQUIP)
	else
		var_15_1 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_gray.png")
	end

	if var_15_1 then
		if arg_15_1 then
			local var_15_2 = arg_15_0.frontCard:background()

			if var_15_2:getChildByName("border") then
				var_15_2:removeChildByName("border")
			end

			var_15_1:addTo(arg_15_0.frontCard:background(), var_0_6.BORDER)
			var_15_1:setAnchorPoint(0.5, 0.5)
			var_15_1:setPosition(arg_15_0.frontCard:getWidth() / 2 + 2, arg_15_0.frontCard:getHeight() / 2 - 2)
		else
			local var_15_3 = arg_15_0.backCard:background()

			if var_15_3:getChildByName("border") then
				var_15_3:removeChildByName("border")
			end

			var_15_1:addTo(arg_15_0.backCard:background(), var_0_6.BORDER)
			var_15_1:setAnchorPoint(0.5, 0.5)
			var_15_1:setPosition(arg_15_0.backCard:getWidth() / 2 + 2, arg_15_0.backCard:getHeight() / 2 - 2)
		end

		var_15_1:setName("border")
	end
end

function var_0_0.addExtraBorder(arg_16_0, arg_16_1)
	local var_16_0

	if arg_16_0.hero:isAwakeTwice() then
		var_16_0 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_awake_twice.png")
	elseif arg_16_0.hero:isAwaken() then
		var_16_0 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_awake.png")
	else
		return
	end

	if var_16_0 then
		if arg_16_1 then
			local var_16_1 = arg_16_0.frontCard:background()

			if var_16_1:getChildByName("extra_border") then
				var_16_1:removeChildByName("extra_border")
			end

			var_16_0:addTo(var_16_1, var_0_6.EXTRA_BORDER)
			var_16_0:setAnchorPoint(0.5, 0.5)
			var_16_0:setPosition(arg_16_0.frontCard:getWidth() / 2 + 5, arg_16_0.frontCard:getHeight() / 2 + 15)
		else
			local var_16_2 = arg_16_0.backCard:background()

			if var_16_2:getChildByName("extra_border") then
				var_16_2:removeChildByName("extra_border")
			end

			var_16_0:addTo(var_16_2, var_0_6.EXTRA_BORDER)
			var_16_0:setAnchorPoint(0.5, 0.5)
			var_16_0:setPosition(arg_16_0.backCard:getWidth() / 2 + 5, arg_16_0.backCard:getHeight() / 2 + 15)
		end

		var_16_0:setName("extra_border")
	end
end

function var_0_0.switchState(arg_17_0, arg_17_1)
	if arg_17_1 == xyd.HeroListDisplayType.HERO then
		if not arg_17_0.frontCard or tolua.isnull(arg_17_0.frontCard) then
			arg_17_0:createFront()
		end

		arg_17_0.frontCard:setVisible(true)

		if arg_17_0.backCard and not tolua.isnull(arg_17_0.backCard) then
			arg_17_0.backCard:setVisible(false)
		end
	end

	if arg_17_1 == xyd.HeroListDisplayType.EQUIP then
		if not arg_17_0.backCard or tolua.isnull(arg_17_0.backCard) then
			arg_17_0:createBack()
		end

		arg_17_0.backCard:setVisible(true)

		if arg_17_0.frontCard and not tolua.isnull(arg_17_0.frontCard) then
			arg_17_0.frontCard:setVisible(false)
		end
	end
end

function var_0_0.updateCell(arg_18_0)
	local var_18_0 = arg_18_0.selfPlayer:getHeroByTableID(arg_18_0.tableID)

	if not var_18_0 or not next(var_18_0) then
		return
	end

	arg_18_0.hero = var_18_0
	arg_18_0.level = arg_18_0.hero:getLevel()
	arg_18_0.color = arg_18_0.hero:getColor()
	arg_18_0.inscriptLev = arg_18_0.hero:getInscriptionKuangLevel()
	arg_18_0.star = arg_18_0.hero:getStar()

	if arg_18_0.frontCard and not tolua.isnull(arg_18_0.frontCard) then
		local var_18_1 = arg_18_0.frontCard:background()

		arg_18_0.frontCard:nodeByName("txt_lev"):setString("Lv." .. arg_18_0.level)
		arg_18_0.frontCard:nodeByName("icon_collocation"):setVisible(arg_18_0.hero:isCollocation())

		if var_18_1:getChildByName("stars") then
			var_18_1:removeChildByName("stars")
		end

		if var_18_1:getChildByName("icon_quality") then
			var_18_1:removeChildByName("icon_quality")
		end

		local var_18_2 = xyd.createHeroStars(arg_18_0.hero)

		var_18_2:addTo(var_18_1, var_0_6.STARS)
		var_18_2:setAnchorPoint(0.5, 0.5)
		var_18_2:setPosition(arg_18_0.frontCard:nodeByName("pos_stars"):getPosition())
		var_18_2:setName("stars")

		local var_18_3 = arg_18_0:getHeroElementIcon()
		local var_18_4, var_18_5 = arg_18_0.frontCard:nodeByName("pos_quality_txt"):getPosition()

		if var_18_3 then
			var_18_4 = var_18_4 - 10
		else
			var_18_3 = arg_18_0:getHeroQualityIcon()
		end

		if var_18_3 then
			var_18_3:addTo(var_18_1, var_0_6.QUALITY)
			var_18_3:setAnchorPoint(0.5, 0.5)
			var_18_3:setPosition(var_18_4, var_18_5)
			var_18_3:setName("icon_quality")
		end

		if not xyd.isSuperHero(arg_18_0.tableID) then
			arg_18_0:addBorder(true)
		end

		arg_18_0:updateFavorProgress(arg_18_0.hero)

		if not arg_18_0.hero:isCollected() then
			arg_18_0:updateStoneProgress(arg_18_0.frontCard)
		end

		if arg_18_0.hero:isCollected() and not arg_18_0.hero:canEnvolve() then
			arg_18_0.frontCard:nodeByName("bg_can_evolve"):setVisible(false)

			local var_18_6 = arg_18_0.frontCard:background()

			if var_18_6:getChildByName("can_evolve_txt") then
				var_18_6:getChildByName("can_evolve_txt"):setVisible(false)
			end
		end
	end

	if arg_18_0.backCard and not tolua.isnull(arg_18_0.backCard) then
		if not xyd.isSuperHero(arg_18_0.tableID) then
			arg_18_0:addBorder(false)
		end

		arg_18_0:showEquips()
		arg_18_0:updateStoneProgress(arg_18_0.backCard)
	end
end

function var_0_0.onRegister(arg_19_0)
	if arg_19_0.hasEvent == 1 then
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_19_0):addEventListener(xyd.event.HERO_CELL_STATE_CHANGE, function(arg_20_0)
			arg_19_0.type = arg_20_0.state

			arg_19_0:switchState(arg_19_0.type)
		end)
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_19_0):addEventListener(xyd.event.HERO_CELL_REFRESH, function(arg_21_0)
			if arg_21_0.tableID and arg_21_0.tableID == arg_19_0.tableID then
				arg_19_0:updateCell()
			end
		end)
		cc.EventProxy.new(xyd.EventDispatcher.get(), arg_19_0):addEventListener(xyd.event.HERO_ELEMENT_EQUIP_CHANGED, function(arg_22_0)
			arg_19_0:updateCell()
		end)

		local var_19_0 = false
		local var_19_1 = 0
		local var_19_2 = 0

		arg_19_0:setTouchEnabled(true)
		arg_19_0:setTouchSwallowEnabled(false)
		arg_19_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
			if arg_23_0.name == "began" then
				var_19_1 = arg_23_0.x
				var_19_2 = arg_23_0.y
				var_19_0 = false

				return true
			elseif arg_23_0.name == "moved" then
				if math.abs(arg_23_0.y - var_19_2) > 10 or math.abs(arg_23_0.x - var_19_1) > 10 then
					var_19_0 = true
				end
			elseif arg_23_0.name == "ended" then
				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if var_19_0 then
					return
				end

				xyd.playButtonSound()

				if arg_19_0.hero:isCollected() then
					local var_23_0 = xyd.WindowManager.get():getWindow("hero_list")

					if var_23_0 and not tolua.isnull(var_23_0) then
						local var_23_1 = xyd.StoryData.get():getGuideID()

						if var_23_1 < xyd.GuideStoryType.GUIDE_EQUIP_END then
							arg_19_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HERO)
						elseif var_23_1 == xyd.GuideStoryType.GUIDE_STONE_ONE then
							arg_19_0.selfPlayer:sendOperationLog(xyd.StatID.ID_STONE_2)
						end

						xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, {
							activity_id = xyd.Activities.HalfPriceSkill
						}, nil, nil, false, false)

						local var_23_2 = var_23_0.data

						xyd.WindowManager.get():openWindow(xyd.WindowName.heroMainWnd, {
							heros = var_23_2,
							current = arg_19_0.idx,
							scrolly = var_23_0.scrollY
						})
					end
				elseif arg_19_0.hero:getSuiPian() >= xyd.TotalStarSuipian[arg_19_0.star] then
					local var_23_3 = xyd.tables.star:summonPrice(arg_19_0.star)
					local var_23_4 = string.format(var_0_5:translation("SUMMON_HERO"), var_23_3)

					local function var_23_5()
						local function var_24_0()
							local var_25_0 = xyd.FunctionID.ID_GOLD_HAND

							if arg_19_0.selfPlayer:isFuncOpen(var_25_0) then
								xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
							else
								local var_25_1 = xyd.tables.functionOpen:level(var_25_0)
								local var_25_2 = string.format(var_0_5:translation("FUNCTION_OPEN_TIP_LEVEL"), var_25_1)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_25_2
								})
							end
						end

						if var_23_3 > arg_19_0.selfPlayer.mana then
							xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)

							local var_24_1 = {
								rcallBefore = 0,
								txt = var_0_5:translation("JINBI_ABSENCE"),
								rcallback = var_24_0
							}

							xyd.WindowManager.get():openWindow("common_alert", var_24_1)
						else
							arg_19_0:summonHero(arg_19_0.hero)
						end
					end

					local var_23_6 = {
						rcallBefore = 0,
						txt = var_23_4,
						rcallback = var_23_5,
						guideID = xyd.StoryData.get():getGuideID()
					}

					xyd.WindowManager.get():openWindow("common_alert", var_23_6)
				else
					local var_23_7 = xyd.tables.hero:stoneID(arg_19_0.tableID)

					xyd.WindowManager.get():openWindow("stone", {
						hero = arg_19_0.hero,
						itemComposeID = var_23_7
					})
				end
			end
		end)
	end
end

function var_0_0.summonHero(arg_26_0, arg_26_1)
	arg_26_1:stoneSummonHero(function(arg_27_0)
		if arg_27_0 == xyd.error.OK then
			local var_27_0 = {
				toStone = false,
				partnerID = arg_26_1:getTableID()
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_27_0)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.HERO_LIST_REFRESH
			})
		end
	end)
end

return var_0_0
