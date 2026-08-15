local var_0_0 = class("SkinShopDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = require("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.item
local var_0_5 = xyd.tables.model
local var_0_6 = xyd.tables.skinDynamic
local var_0_7 = xyd.tables.skinSkill
local var_0_8 = xyd.tables.hero
local var_0_9 = xyd.tables.avartarMall
local var_0_10 = xyd.tables.avartarMallActivity
local var_0_11 = xyd.tables.ecoType
local var_0_12 = xyd.tables.misc
local var_0_13 = {}

var_0_13.Background1 = "skeletons/ui_effect/hero/hero_bg_effect01"
var_0_13.Background2 = "skeletons/ui_effect/hero/hero_bg_effect02"

local var_0_14 = var_0_12.skinTicketId
local var_0_15 = var_0_3:translation("AVARTAR_MALLCURRENCY_NTS")
local var_0_16 = var_0_11:getEcoPath("crystal")
local var_0_17 = var_0_11:getEcoPath("skin_coin")
local var_0_18 = var_0_11:getEcoPath("skin_fragment")
local var_0_19 = "windows/skin_shop_window/detail/old_skin_coin.png"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.shop = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_1_0.activity = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.index = arg_1_2.id
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		isEcoBar = 0
	})
	arg_2_0:addEcoSidebar()
	arg_2_0:layout()
end

function var_0_0.addEcoSidebar(arg_3_0)
	arg_3_0:nodeByName("eco_sidebar"):removeAllChildren()

	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_widgets/eco_display_sidebar.csb")

	var_3_0:setPosition(-120, 0)
	arg_3_0:nodeByName("eco_sidebar"):addChild(var_3_0)

	local var_3_1 = var_3_0:getChildByName("background")
	local var_3_2 = var_3_1:getChildByName("eco_1")
	local var_3_3 = xyd.AssetLoader.get():loadSprite(var_0_17)

	var_3_3:setPosition(var_3_2:getChildByName("pos_icon_1"):getPosition())
	var_3_2:addChild(var_3_3)

	arg_3_0.skinCoinTxt = var_3_2:getChildByName("txt_eco_val_1")

	arg_3_0.skinCoinTxt:setString(xyd.num2ThousandsStr(arg_3_0.selfPlayer.skinCoin))
	var_3_2:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0.coinTip:setVisible(true)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.coinTip:setVisible(false)
		elseif arg_4_1 == ccui.TouchEventType.canceled then
			arg_3_0.coinTip:setVisible(false)
		end
	end)

	local var_3_4 = var_3_1:getChildByName("eco_2")
	local var_3_5 = xyd.AssetLoader.get():loadSprite(var_0_16)

	var_3_5:setPosition(var_3_4:getChildByName("pos_icon_2"):getPosition())
	var_3_4:addChild(var_3_5)

	arg_3_0.crystalTxt = var_3_4:getChildByName("txt_eco_val_2")

	arg_3_0.crystalTxt:setString(xyd.num2ThousandsStr(arg_3_0.selfPlayer.crystal))

	local var_3_6 = 2

	if arg_3_0.selfPlayer.skinFragment > 0 then
		var_3_6 = var_3_6 + 1

		local var_3_7 = var_3_1:getChildByName("eco_" .. var_3_6)
		local var_3_8 = xyd.AssetLoader.get():loadSprite(var_0_18)

		var_3_8:setPosition(var_3_7:getChildByName("pos_icon_" .. var_3_6):getPosition())
		var_3_7:addChild(var_3_8)

		arg_3_0.fragmentTxt = var_3_7:getChildByName("txt_eco_val_" .. var_3_6)

		arg_3_0.fragmentTxt:setString(xyd.num2ThousandsStr(arg_3_0.selfPlayer.skinFragment))
	else
		arg_3_0.fragmentTxt = nil
	end

	if arg_3_0.backpack:getItemNumByID(var_0_14) > 0 then
		var_3_6 = var_3_6 + 1

		local var_3_9 = var_3_1:getChildByName("eco_" .. var_3_6)
		local var_3_10 = xyd.AssetLoader.get():loadSprite(var_0_19)

		var_3_10:setPosition(var_3_9:getChildByName("pos_icon_" .. var_3_6):getPosition())
		var_3_9:addChild(var_3_10)

		arg_3_0.oldCoinTxt = var_3_9:getChildByName("txt_eco_val_" .. var_3_6)

		arg_3_0.oldCoinTxt:setString(xyd.num2ThousandsStr(arg_3_0.backpack:getItemNumByID(var_0_14)))
	else
		arg_3_0.oldCoinTxt = nil
	end

	if var_3_6 < 4 then
		for iter_3_0 = var_3_6 + 1, 4 do
			var_3_1:getChildByName("eco_" .. iter_3_0):setVisible(false)
		end
	end
end

function var_0_0.updateDatas(arg_5_0)
	arg_5_0.itemID = var_0_9:item(arg_5_0.index)
	arg_5_0.saleType = var_0_9:saletype(arg_5_0.index)
	arg_5_0.price = var_0_9:price(arg_5_0.index)
	arg_5_0.discountPrice = var_0_9:discount(arg_5_0.index)
	arg_5_0.discount = var_0_9:discount(arg_5_0.index)
	arg_5_0.discountActivity = var_0_9:discountActivity(arg_5_0.index)
	arg_5_0.modelID = var_0_4:skinModel(arg_5_0.itemID)
	arg_5_0.heroTableID = var_0_7:getHeroID(arg_5_0.itemID)
	arg_5_0.hero = arg_5_0.selfPlayer:getHeroIgnoreAwaken(arg_5_0.heroTableID)
	arg_5_0.heroSkins = {}

	local var_5_0 = var_0_9:getItems()

	for iter_5_0, iter_5_1 in ipairs(var_5_0) do
		if var_0_7:getHeroID(iter_5_1) == arg_5_0.heroTableID then
			table.insert(arg_5_0.heroSkins, {
				idx = iter_5_0,
				item_id = iter_5_1
			})
		end
	end

	arg_5_0.totalNum = #var_5_0
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("txt_show_1"):setString(var_0_3:translation("AVARTAR_MALL_POSE"))
	arg_6_0:nodeByName("txt_show_2"):setString(var_0_3:translation("AVARTAR_MALL_TWOPOINTFIVE"))
	arg_6_0:nodeByName("txt_skill"):setString(var_0_3:translation("AVARTAR_MALL_EQUIP_SKILL"))
	arg_6_0:nodeByName("txt_null"):setString(var_0_3:translation("AVARTAR_MALL_NO_SKILL"))
	arg_6_0:nodeByName("txt_buy"):setString(var_0_3:translation("AVARTAR_MALLBUY"))
	arg_6_0:nodeByName("txt_own"):setString(var_0_3:translation("AVARTAR_MALLALREADY_HAVE"))
	arg_6_0:nodeByName("txt_null"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_6_0:nodeByName("txt_own"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_6_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
	local var_6_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

	arg_6_0:nodeByName("btn_last"):runAction(cc.RepeatForever:create(var_6_0))
	arg_6_0:nodeByName("btn_next"):runAction(cc.RepeatForever:create(var_6_1))

	arg_6_0.coinTip = xyd.AssetLoader.get():loadNodeFromJson("windows/skin_shop_window/detail/coin_tip.csb")

	arg_6_0.coinTip:setPosition(1260, 660)
	arg_6_0.coinTip:setVisible(false)
	arg_6_0:nodeByName("background"):addChild(arg_6_0.coinTip)

	local var_6_2 = arg_6_0.coinTip:getChildByName("container")
	local var_6_3 = var_6_2:getContentSize()
	local var_6_4 = xyd.createLabel(22, cc.c3b(255, 255, 255))

	var_6_4:setAnchorPoint(0, 1)
	var_6_4:setWidth(var_6_3.width - 30)
	var_6_4:setLineHeight(28)
	var_6_4:setString(var_0_3:translation("SKIN_SHOP_SKIN_COIN_TIP"))

	local var_6_5 = var_6_4:getContentSize()

	var_6_2:setContentSize(var_6_3.width, var_6_5.height + 30)
	var_6_4:setPosition((var_6_3.width - var_6_5.width) / 2, var_6_5.height + 15)
	var_6_2:addChild(var_6_4)
	arg_6_0:update()
	arg_6_0:initBtn()
end

function var_0_0.updateEco(arg_7_0)
	local var_7_0 = arg_7_0.crystalTxt:getString()
	local var_7_1 = xyd.num2ThousandsStr(arg_7_0.selfPlayer.crystal)

	if var_7_0 ~= var_7_1 then
		arg_7_0.crystalTxt:setString(var_7_1)

		local var_7_2 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_7_3 = cc.Spawn:create(var_7_2)

		arg_7_0.crystalTxt:runAction(var_7_3)
	end

	local var_7_4 = arg_7_0.skinCoinTxt:getString()
	local var_7_5 = xyd.num2ThousandsStr(arg_7_0.selfPlayer.skinCoin)

	if var_7_4 ~= var_7_5 then
		arg_7_0.skinCoinTxt:setString(var_7_5)

		local var_7_6 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_7_7 = cc.Spawn:create(var_7_6)

		arg_7_0.skinCoinTxt:runAction(var_7_7)
	end

	if arg_7_0.fragmentTxt then
		local var_7_8 = arg_7_0.fragmentTxt:getString()
		local var_7_9 = xyd.num2ThousandsStr(arg_7_0.selfPlayer.skinFragment)

		if var_7_8 ~= var_7_9 then
			arg_7_0.fragmentTxt:setString(var_7_9)

			local var_7_10 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_7_11 = cc.Spawn:create(var_7_10)

			arg_7_0.fragmentTxt:runAction(var_7_11)
		end
	end

	if arg_7_0.oldCoinTxt then
		local var_7_12 = arg_7_0.oldCoinTxt:getString()
		local var_7_13 = xyd.num2ThousandsStr(arg_7_0.backpack:getItemNumByID(var_0_14))

		if var_7_12 ~= var_7_13 then
			arg_7_0.oldCoinTxt:setString(var_7_13)

			local var_7_14 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_7_15 = cc.Spawn:create(var_7_14)

			arg_7_0.oldCoinTxt:runAction(var_7_15)
		end
	end
end

function var_0_0.initBtn(arg_8_0)
	arg_8_0:nodeByName("btn_live"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0.live = not arg_8_0.live

			arg_8_0:nodeByName("icon_on"):setVisible(arg_8_0.live)
			arg_8_0:nodeByName("icon_off"):setVisible(not arg_8_0.live)
			arg_8_0:nodeByName("txt_btn_live"):setString(arg_8_0.live and "ON" or "OFF")
			arg_8_0:nodeByName("txt_btn_live"):setPositionX(arg_8_0.live and 46 or 27)
			arg_8_0:updateHeroHomeCard()
		end
	end)
	arg_8_0:nodeByName("show"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			arg_8_0:resetModelState(arg_8_0.heroModel)
		end
	end)
	xyd.nodeEventSample(arg_8_0:nodeByName("btn_buy"), nil, function()
		local function var_11_0()
			if arg_8_0.fragmentTxt and arg_8_0.selfPlayer.skinFragment == 0 or arg_8_0.oldCoinTxt and arg_8_0.backpack:getItemNumByID(var_0_14) == 0 then
				arg_8_0:addEcoSidebar()
			end

			arg_8_0:updateEco()
			arg_8_0:updatePriceContainer()

			if arg_8_0.callback then
				arg_8_0.callback()
			end
		end

		local var_11_1 = {
			idx = arg_8_0.index,
			item_id = arg_8_0.itemID,
			sale_type = arg_8_0.saleType,
			price = arg_8_0.price,
			is_discount = arg_8_0.isDiscount,
			discount = arg_8_0.discount,
			callback = var_11_0
		}

		if not arg_8_0.hero then
			local var_11_2 = var_0_3:translation("AVARTAR_MALLNO_CHARACTER")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_2, function()
				xyd.WindowManager.get():openWindow("skin_shop_detail_alert", var_11_1)
			end, nil, nil, arg_8_0.colorMode)
		else
			xyd.WindowManager.get():openWindow("skin_shop_detail_alert", var_11_1)
		end
	end)
	arg_8_0:nodeByName("btn_next"):setTouchEnabled(true)
	arg_8_0:nodeByName("btn_next"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			return true
		elseif arg_14_0.name == "ended" then
			arg_8_0:nextHero()
		end
	end)
	arg_8_0:nodeByName("btn_last"):setTouchEnabled(true)
	arg_8_0:nodeByName("btn_last"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			arg_8_0:lastHero()
		end
	end)

	local var_8_0 = display.newNode()
	local var_8_1

	var_8_0:setContentSize(400, 600)
	var_8_0:setPosition(200, 0)
	arg_8_0:nodeByName("background"):addChild(var_8_0)
	var_8_0:setTouchEnabled(true)
	var_8_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			var_8_1 = arg_16_0.x

			return true
		elseif arg_16_0.name == "ended" then
			if arg_16_0.x - var_8_1 > 50 then
				arg_8_0:lastHero()
			elseif arg_16_0.x - var_8_1 < -50 then
				arg_8_0:nextHero()
			end
		end
	end)
end

function var_0_0.lastHero(arg_17_0)
	if arg_17_0.index < arg_17_0.totalNum then
		arg_17_0.index = arg_17_0.index + 1
	else
		arg_17_0.index = 1
	end

	arg_17_0:update()
end

function var_0_0.nextHero(arg_18_0)
	if arg_18_0.index > 1 then
		arg_18_0.index = arg_18_0.index - 1
	else
		arg_18_0.index = arg_18_0.totalNum
	end

	arg_18_0:update()
end

function var_0_0.update(arg_19_0)
	if arg_19_0.handle then
		var_0_2.unscheduleGlobal(arg_19_0.handle)

		arg_19_0.handle = nil
	end

	arg_19_0:updateDatas()
	arg_19_0:updateNameLabel()
	arg_19_0:updateHeroHomeCard(true)
	arg_19_0:updateShowContainer()
	arg_19_0:updateSkillContainer()
	arg_19_0:updateSkinContainer(true)
	arg_19_0:updatePriceContainer()
	xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):setBackendCountCondition(16, 1)
end

function var_0_0.updateNameLabel(arg_20_0)
	arg_20_0:nodeByName("name_label"):removeAllChildren()

	local var_20_0 = arg_20_0.hero

	if not var_20_0 then
		local var_20_1 = xyd.AssetLoader.get():loadSprite("windows/skin_shop_window/detail/hero_name_bg.png")

		var_20_1:setAnchorPoint(0, 0)
		var_20_1:setPosition(88, 10)
		var_20_1:addTo(arg_20_0:nodeByName("name_label"))

		local var_20_2 = xyd.createLabel(22, cc.c3b(255, 255, 255))

		var_20_2:setAnchorPoint(0.5, 0.5)
		var_20_2:setPosition(113, 20)
		var_20_2:setString(var_0_8:name(arg_20_0.heroTableID) .. var_0_3:translation("AVARTAR_MALLNOTMINE"))
		var_20_1:addChild(var_20_2)

		return
	end

	local var_20_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/hero_label.csb")

	var_20_3:addTo(arg_20_0:nodeByName("name_label"))

	local var_20_4 = var_20_3:getChildByName("bg")
	local var_20_5 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_" .. xyd.Color2Quality[var_20_0:getColor()] .. ".png")

	var_20_5:addTo(var_20_4:getChildByName("bg_name"))
	var_20_5:setAnchorPoint(0, 0)

	local var_20_6

	if var_20_0:isAwaken() then
		if var_20_0:isAwakeTwice() then
			var_20_6 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake_twice.png")
		else
			var_20_6 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake.png")
		end

		var_20_6:addTo(var_20_4:getChildByName("bg_awake"))
		var_20_6:setAnchorPoint(0, 0)
	end

	local var_20_7

	if xyd.Color2Level[var_20_0:getColor()] ~= "" then
		var_20_7 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/hero_quality_" .. var_20_0:getColor() .. ".png")
	end

	local var_20_8 = var_20_0:getInscriptionKuangLevel()

	if var_20_8 then
		if var_20_8 ~= 1 then
			var_20_7 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/hero_quality_suit_" .. var_20_8 .. ".png")
		else
			var_20_7 = nil
		end

		var_20_4:getChildByName("bg_name"):removeAllChildren()

		local var_20_9 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_suit.png")

		var_20_9:addTo(var_20_4:getChildByName("bg_name"))
		var_20_9:setAnchorPoint(0, 0)
	end

	local var_20_10 = var_20_0:getElementType()

	if var_20_10 ~= 0 then
		local var_20_11

		if var_20_8 then
			var_20_11 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_gold_bg.png")
		else
			var_20_11 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_red_bg.png")
		end

		local var_20_12 = "windows/common/hero_common/big_element_" .. var_20_10

		if var_20_0:isActiveSP() then
			var_20_12 = var_20_12 .. "sp"
		end

		var_20_7 = xyd.AssetLoader.get():loadSprite(var_20_12 .. ".png")

		var_20_11:setAnchorPoint(0.5, 0.5)
		var_20_11:addTo(var_20_4:getChildByName("quality"))
		var_20_7:setAnchorPoint(0.5, 0.5)
		var_20_7:addTo(var_20_4:getChildByName("quality"))

		if var_20_0:isActiveSP() then
			arg_20_0:addActiveEffeft(var_20_7, var_20_10)
		end
	elseif var_20_7 then
		var_20_7:setAnchorPoint(0.5, 0.5)
		var_20_7:addTo(var_20_4:getChildByName("quality"))
	end

	var_20_4:getChildByName("name"):setString(var_20_0:getName())

	local var_20_13 = var_20_0:getHeroType()
	local var_20_14

	if var_20_13 == xyd.HeroType.WISE then
		var_20_14 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_wise.png")
	elseif var_20_13 == xyd.HeroType.STRENGTH then
		var_20_14 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_strength.png")
	else
		var_20_14 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_agile.png")
	end

	var_20_14:addTo(var_20_4:getChildByName("icon_info"))

	if var_20_0:isSuper() then
		local var_20_15

		if var_20_0:getStar() > xyd.MAX_STAR_LEVEL then
			local var_20_16 = var_20_0:getStar() - xyd.MAX_STAR_LEVEL

			for iter_20_0 = 1, xyd.HERO_TOTAL_STARS do
				local var_20_17 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star_pink.png")

				var_20_4:getChildByName("star_" .. iter_20_0):setSpriteFrame(var_20_17:getSpriteFrame())
				var_20_4:getChildByName("star_" .. iter_20_0):setVisible(iter_20_0 <= var_20_16)
			end
		else
			local var_20_18 = var_20_0:getStar()

			for iter_20_1 = 1, xyd.HERO_TOTAL_STARS do
				local var_20_19 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

				var_20_4:getChildByName("star_" .. iter_20_1):setSpriteFrame(var_20_19:getSpriteFrame())
				var_20_4:getChildByName("star_" .. iter_20_1):setVisible(iter_20_1 <= var_20_18)
			end
		end

		local var_20_20 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_super.png")

		var_20_4:getChildByName("quality"):removeAllChildren()
		var_20_4:getChildByName("bg_name"):removeAllChildren()

		if var_20_10 ~= 0 then
			local var_20_21 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_ur_bg.png")
			local var_20_22 = "windows/common/hero_common/big_element_" .. var_20_10

			if var_20_0:isActiveSP() then
				var_20_22 = var_20_22 .. "sp"
			end

			local var_20_23 = xyd.AssetLoader.get():loadSprite(var_20_22 .. ".png")

			var_20_21:setAnchorPoint(0.5, 0.5)
			var_20_21:addTo(var_20_4:getChildByName("quality"))
			var_20_23:addTo(var_20_4:getChildByName("quality"))
			var_20_23:setAnchorPoint(0.5, 0.5)

			if var_20_0:isActiveSP() then
				arg_20_0:addActiveEffeft(var_20_23, var_20_10)
			end
		end

		var_20_20:addTo(var_20_4:getChildByName("bg_name"))
		var_20_20:setAnchorPoint(0, 0)
	else
		for iter_20_2 = 1, xyd.HERO_TOTAL_STARS do
			local var_20_24 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

			var_20_4:getChildByName("star_" .. iter_20_2):setSpriteFrame(var_20_24:getSpriteFrame())
			var_20_4:getChildByName("star_" .. iter_20_2):setVisible(iter_20_2 <= var_20_0:getStar())
		end
	end
end

function var_0_0.updateHeroHomeCard(arg_21_0, arg_21_1)
	arg_21_0:nodeByName("card"):removeAllChildren()

	local var_21_0 = arg_21_0.modelID
	local var_21_1 = xyd.tables.libraryHomeCard:x(var_21_0)
	local var_21_2 = xyd.tables.libraryHomeCard:y(var_21_0)
	local var_21_3 = var_0_5:dynamicType(var_21_0) == 2
	local var_21_4

	arg_21_0:nodeByName("bg_live"):setVisible(var_21_3)
	arg_21_0:nodeByName("btn_live"):setVisible(var_21_3)

	if arg_21_1 then
		arg_21_0.live = var_0_5:dynamicType(var_21_0) >= 1

		arg_21_0:nodeByName("icon_on"):setVisible(arg_21_0.live)
		arg_21_0:nodeByName("icon_off"):setVisible(not arg_21_0.live)
		arg_21_0:nodeByName("txt_btn_live"):setString(arg_21_0.live and "ON" or "OFF")
		arg_21_0:nodeByName("txt_btn_live"):setPositionX(arg_21_0.live and 46 or 27)
	end

	if arg_21_0.live then
		local var_21_5 = var_0_6:path(var_21_0)
		local var_21_6 = var_0_6:homeCardScale(var_21_0)
		local var_21_7 = var_0_6:pos(var_21_0, xyd.SkinDynamicPosType.LIBRARY)

		var_21_4 = xyd.EffectLoader.new(var_21_5, 3, var_21_6, var_21_7)
	else
		var_21_4 = xyd.SpriteLoader.new(var_0_5:transparentCard(var_21_0), nil, nil, xyd.DefaultImageType.HOME_CARD)
	end

	if not var_21_4 then
		return
	end

	var_21_4:addTo(arg_21_0:nodeByName("card"))
	var_21_4:setPosition(arg_21_0:nodeByName("card"):getWidth() / 2 + var_21_1, var_21_2)
	var_21_4:setAnchorPoint(cc.p(0.5, 0))
	var_21_4:setTouchEnabled(false)
end

function var_0_0.updateShowContainer(arg_22_0)
	arg_22_0:nodeByName("show"):removeAllChildren()

	local var_22_0 = arg_22_0.modelID
	local var_22_1 = xyd.HeroAnimation.new(arg_22_0.heroTableID, var_22_0, var_0_5:uiScale(var_22_0) * 0.5, {})

	var_22_1:idle()

	arg_22_0.heroModel = var_22_1
	arg_22_0.modelState = xyd.ModelState.Walk

	var_22_1:setPositionX(arg_22_0:nodeByName("show"):getWidth() / 2)
	var_22_1:addTo(arg_22_0:nodeByName("show"))
	arg_22_0:nodeByName("hero_avatar"):removeAllChildren()

	local var_22_2 = arg_22_0:nodeByName("hero_avatar"):getContentSize()
	local var_22_3 = xyd.tables.model:avatar(var_22_0)
	local var_22_4 = display.newClippingRectangleNode(cc.rect(0, 0, var_22_2.width - 4, var_22_2.height - 4))
	local var_22_5 = xyd.SpriteLoader.new(var_22_3, nil, nil, xyd.DefaultImageType.SKILL_ICON)
	local var_22_6 = xyd.getAvatarBorderNewUI(1)

	var_22_5 = var_22_5 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	var_22_4:addTo(arg_22_0:nodeByName("hero_avatar"))
	var_22_4:pos(2, 2)
	var_22_5:addTo(var_22_4)
	var_22_5:setScale(var_22_2.width / var_22_5:getWidth())
	var_22_5:align(display.CENTER, var_22_2.width / 2, var_22_2.height / 2)
	xyd.displaySpriteOnContainer(var_22_6, arg_22_0:nodeByName("hero_avatar"), true)
end

function var_0_0.updateSkillContainer(arg_23_0)
	arg_23_0:nodeByName("icon_skill"):removeAllChildren()

	local var_23_0 = var_0_7:getSkillID(arg_23_0.itemID)

	if not var_23_0 or var_23_0 == 0 then
		arg_23_0:nodeByName("skill"):hide()
		arg_23_0:nodeByName("txt_null"):show()

		return
	end

	arg_23_0:nodeByName("skill"):show()
	arg_23_0:nodeByName("txt_null"):hide()
	xyd.setItemBorder(arg_23_0:nodeByName("icon_skill"), arg_23_0.itemID)
	arg_23_0:nodeByName("txt_skill_name"):setString(var_0_4:name(arg_23_0.itemID))

	local var_23_1 = arg_23_0:nodeByName("skill_intro"):getContentSize()

	if not arg_23_0.skillIntroList then
		arg_23_0.skillIntroList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_23_1.width, var_23_1.height),
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_23_0:nodeByName("skill_intro"))
	end

	arg_23_0.skillIntroList:removeAllItems()

	local var_23_2 = arg_23_0.skillIntroList:newItem()
	local var_23_3 = xyd.createLabel(18, cc.c3b(52, 54, 55))

	var_23_3:setWidth(var_23_1.width - 20)
	var_23_3:setLineHeight(24)
	var_23_3:setLineBreakWithoutSpace(true)
	var_23_3:setString(xyd.tables.skill:desc(var_23_0))
	var_23_2:addContent(var_23_3)
	var_23_2:setItemSize(var_23_1.width, var_23_3:getContentSize().height)
	arg_23_0.skillIntroList:addItem(var_23_2)
	arg_23_0.skillIntroList:reload()
end

function var_0_0.updateSkinContainer(arg_24_0, arg_24_1)
	if not arg_24_0.skinList then
		local var_24_0 = arg_24_0:nodeByName("skin_list"):getContentSize()

		arg_24_0.skinList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_24_0.width, var_24_0.height),
			direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
		}):addTo(arg_24_0:nodeByName("skin_list")):onScroll(handler(arg_24_0, arg_24_0.scrollListener))

		arg_24_0.skinList:setDelegate(handler(arg_24_0, arg_24_0.delegate))
	end

	if arg_24_1 then
		arg_24_0.skinSelect = 0

		for iter_24_0, iter_24_1 in ipairs(arg_24_0.heroSkins) do
			if iter_24_1.item_id == arg_24_0.itemID then
				arg_24_0.skinSelect = iter_24_0

				break
			end
		end

		arg_24_0.skinList:reload()

		if arg_24_0.skinSelect >= 4 then
			arg_24_0.skinList:getScrollNode():setPositionX(525 - arg_24_0.skinSelect * 164)
		end
	else
		arg_24_0.skinList:refreshList(0)
	end
end

function var_0_0.updatePriceContainer(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.selfPlayer:hasSkin(arg_25_0.itemID)
	local var_25_1

	arg_25_0.isDiscount = false

	if var_25_0 then
		arg_25_0:nodeByName("price_container"):setVisible(false)
		arg_25_0:nodeByName("bg_discount"):setVisible(false)
		arg_25_0:nodeByName("txt_own"):setVisible(true)

		return
	else
		arg_25_0:nodeByName("price_container"):setVisible(true)
		arg_25_0:nodeByName("txt_own"):setVisible(false)
	end

	if arg_25_0.discountActivity == 1 and not arg_25_1 then
		var_25_1 = var_0_10:actId(arg_25_0.saleType)
		arg_25_0.isDiscount = arg_25_0.activity:isActivityOpen(var_25_1)
	end

	arg_25_0:nodeByName("bg_discount"):setVisible(arg_25_0.isDiscount)

	if arg_25_0.isDiscount then
		local var_25_2 = arg_25_0.activity:getActivityInfo(var_25_1)

		arg_25_0:setTimer(var_25_2)
	end

	arg_25_0:nodeByName("txt_charge"):setVisible(false)
	arg_25_0:nodeByName("txt_discount"):setVisible(false)

	if arg_25_0.saleType == 1 then
		arg_25_0:nodeByName("left"):setVisible(false)
		arg_25_0:nodeByName("right"):setVisible(false)
		arg_25_0:nodeByName("line"):setVisible(false)
		arg_25_0:nodeByName("txt_charge"):setVisible(true)
		arg_25_0:nodeByName("txt_charge"):setString((arg_25_0.isDiscount and arg_25_0.discountPrice[1] or arg_25_0.price[1]) .. var_0_15)

		if arg_25_0.isDiscount then
			arg_25_0:nodeByName("txt_discount"):setVisible(true)
			arg_25_0:nodeByName("txt_discount"):setString(arg_25_0.price[1] .. var_0_15)
			arg_25_0:nodeByName("red_line"):setContentSize(arg_25_0:nodeByName("txt_discount"):getWidth() + 10, 2)
			arg_25_0:nodeByName("txt_charge"):setPositionY(37)
		else
			arg_25_0:nodeByName("txt_charge"):setPositionY(27)
		end
	elseif arg_25_0.saleType == 2 then
		arg_25_0:setPriceShow({
			var_0_16
		}, arg_25_0.isDiscount)
	elseif arg_25_0.saleType == 3 then
		arg_25_0:setPriceShow({
			var_0_17
		}, arg_25_0.isDiscount)
	elseif arg_25_0.saleType == 4 then
		arg_25_0:setPriceShow({
			var_0_16,
			var_0_17
		}, arg_25_0.isDiscount)
	elseif arg_25_0.saleType == 5 then
		if arg_25_0.oldCoinTxt then
			arg_25_0:setPriceShow({
				var_0_19,
				var_0_17
			}, arg_25_0.isDiscount)
		else
			arg_25_0:setPriceShow({
				var_0_17
			}, arg_25_0.isDiscount, 2)
		end
	elseif arg_25_0.saleType == 6 then
		if arg_25_0.fragmentTxt then
			arg_25_0:setPriceShow({
				var_0_18,
				var_0_17
			}, arg_25_0.isDiscount)
		else
			arg_25_0:setPriceShow({
				var_0_17
			}, arg_25_0.isDiscount, 2)
		end
	elseif arg_25_0.saleType == 7 then
		if arg_25_0.oldCoinTxt then
			arg_25_0:setPriceShow({
				var_0_19,
				var_0_16
			}, arg_25_0.isDiscount)
		else
			arg_25_0:setPriceShow({
				var_0_16
			}, arg_25_0.isDiscount, 2)
		end
	elseif arg_25_0.saleType == 8 then
		if arg_25_0.fragmentTxt then
			arg_25_0:setPriceShow({
				var_0_18,
				var_0_16
			}, arg_25_0.isDiscount)
		else
			arg_25_0:setPriceShow({
				var_0_16
			}, arg_25_0.isDiscount, 2)
		end
	end
end

function var_0_0.setPriceShow(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = arg_26_3 or 1

	if #arg_26_1 == 1 then
		arg_26_0:nodeByName("left"):setVisible(true)
		arg_26_0:nodeByName("line"):setVisible(false)
		arg_26_0:nodeByName("right"):setVisible(false)
		arg_26_0:nodeByName("txt_left"):setString(arg_26_2 and arg_26_0.discountPrice[var_26_0] or arg_26_0.price[var_26_0])
		arg_26_0:nodeByName("left"):setPositionX(75)
		arg_26_0:nodeByName("icon_left"):setTexture(arg_26_1[1])
	else
		arg_26_0:nodeByName("left"):setVisible(true)
		arg_26_0:nodeByName("line"):setVisible(true)
		arg_26_0:nodeByName("right"):setVisible(true)
		arg_26_0:nodeByName("txt_left"):setString(arg_26_2 and arg_26_0.discountPrice[1] or arg_26_0.price[1])
		arg_26_0:nodeByName("txt_right"):setString(arg_26_2 and arg_26_0.discountPrice[2] or arg_26_0.price[2])
		arg_26_0:nodeByName("left"):setPositionX(0)
		arg_26_0:nodeByName("right"):setPositionX(150)
		arg_26_0:nodeByName("icon_left"):setTexture(arg_26_1[1])
		arg_26_0:nodeByName("icon_right"):setTexture(arg_26_1[2])
	end
end

function var_0_0.setTimer(arg_27_0, arg_27_1)
	local var_27_0 = xyd.ServerTime.get():getServerTime()
	local var_27_1 = arg_27_1.end_time

	if var_27_0 < var_27_1 then
		arg_27_0:nodeByName("txt_time"):setString(xyd.secondsToString1(var_27_1 - var_27_0))
	else
		arg_27_0:updatePriceContainer(true)
	end

	if arg_27_0.handle then
		var_0_2.unscheduleGlobal(arg_27_0.handle)

		arg_27_0.handle = nil
	end

	arg_27_0.handle = var_0_2.scheduleGlobal(function()
		local var_28_0 = xyd.ServerTime.get():getServerTime()

		if var_28_0 < var_27_1 then
			arg_27_0:nodeByName("txt_time"):setString(xyd.secondsToString1(var_27_1 - var_28_0))
		else
			if arg_27_0.handle then
				var_0_2.unscheduleGlobal(arg_27_0.handle)

				arg_27_0.handle = nil
			end

			arg_27_0:updatePriceContainer(true)
		end
	end, 1)
end

function var_0_0.delegate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	if arg_29_2 == cc.ui.UIListView.COUNT_TAG then
		return #arg_29_0.heroSkins
	elseif arg_29_2 == cc.ui.UIListView.CELL_TAG then
		local var_29_0 = arg_29_0.skinList:dequeueItem()

		if var_29_0 then
			var_29_0:removeAllChildren()
		else
			var_29_0 = arg_29_0.skinList:newItem()
		end

		local var_29_1 = arg_29_0:createContent(arg_29_3)
		local var_29_2 = var_29_1:getContentSize()

		var_29_0:addContent(var_29_1)
		var_29_0:setContentSize(var_29_2)
		var_29_0:setItemSize(var_29_2.width + 12, var_29_2.height)

		return var_29_0
	end
end

function var_0_0.createContent(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0.heroSkins[arg_30_1].item_id
	local var_30_1 = var_0_7:getSkillID(var_30_0)
	local var_30_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/skin_shop_window/detail/skin_item.csb")
	local var_30_3 = var_30_2:getChildByName("container")
	local var_30_4 = var_0_4:skinModel(var_30_0)

	var_30_2:setContentSize(var_30_3:getContentSize())
	var_30_3:getChildByName("bg_skin_item"):setVisible(arg_30_0.skinSelect ~= arg_30_1)
	var_30_3:getChildByName("bg_skin_item2"):setVisible(arg_30_0.skinSelect == arg_30_1)
	var_30_3:getChildByName("select"):setVisible(arg_30_0.skinSelect == arg_30_1)
	var_30_3:getChildByName("bg_item_top"):setVisible(arg_30_0.skinSelect ~= arg_30_1)
	var_30_3:getChildByName("bg_item_top2"):setVisible(arg_30_0.skinSelect == arg_30_1)
	var_30_3:getChildByName("txt_type"):setString(var_0_3:translation("AVARTAR_STATE_MALL"))
	var_30_3:getChildByName("bg_skill"):getChildByName("txt_skill"):setString(var_0_3:translation("AVARTAR_MALL_SKILL"))

	local var_30_5 = xyd.SpriteLoader.new(var_0_5:smallCard(var_30_4), nil, nil, xyd.DefaultImageType.SMALL_CARD)
	local var_30_6 = var_30_3:getChildByName("card"):getContentSize()
	local var_30_7 = cc.ClippingNode:create()
	local var_30_8 = display.newScale9Sprite("images/line_mask.png", 0, 0, var_30_6)

	var_30_8:setAnchorPoint(0, 0)
	var_30_7:setStencil(var_30_8)
	var_30_3:getChildByName("card"):addChild(var_30_7)
	var_30_5:setAnchorPoint(0, 1)
	var_30_5:setPosition(0, var_30_6.height)
	var_30_7:addChild(var_30_5)
	var_30_7:setName("clip")
	var_30_3:getChildByName("txt_name"):setString(var_0_4:name(var_30_0))
	var_30_3:getChildByName("bg_skill"):setVisible(var_30_1 and var_30_1 > 0)
	var_30_3:addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.ended then
			if arg_30_0.scrollViewMoved_ or arg_30_0.skinSelect == arg_30_1 then
				return
			end

			arg_30_0.index = arg_30_0.heroSkins[arg_30_1].idx
			arg_30_0.skinSelect = arg_30_1

			arg_30_0:updateDatas()
			arg_30_0:updateHeroHomeCard(true)
			arg_30_0:updateShowContainer()
			arg_30_0:updateSkillContainer()
			arg_30_0:updateSkinContainer()
			arg_30_0:updatePriceContainer()
		end
	end)

	return var_30_2
end

function var_0_0.resetModelState(arg_32_0, arg_32_1)
	if arg_32_0.modelState == 8 then
		arg_32_0.modelState = arg_32_0.modelState + 1
	end

	arg_32_0.modelState = arg_32_0.modelState % 8
	arg_32_0.isShow = true

	local var_32_0

	if arg_32_0.modelState == xyd.ModelState.Walk then
		arg_32_1:walk(true)

		arg_32_0.isShow = false
		var_32_0 = xyd.tables.model:getMoveSound(arg_32_0.modelID)
	elseif arg_32_0.modelState == xyd.ModelState.Win then
		arg_32_1:win(false, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_0 = xyd.tables.model:getWinSound(arg_32_0.modelID)
	elseif arg_32_0.modelState == xyd.ModelState.Attack1 then
		arg_32_1:attack(1, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_0 = xyd.tables.model:getNormalAttackSound(arg_32_0.modelID)
	elseif arg_32_0.modelState == xyd.ModelState.Attack2 then
		arg_32_1:attack(2, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_0 = xyd.tables.model:getAttack1Sound(arg_32_0.modelID)
	elseif arg_32_0.modelState == xyd.ModelState.Attack3 then
		arg_32_1:attack(3, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_0 = xyd.tables.model:getAttack2Sound(arg_32_0.modelID)
	elseif arg_32_0.modelState == xyd.ModelState.Attack4 then
		if not arg_32_1:hasAnimation("gongji04") then
			arg_32_0.modelState = arg_32_0.modelState + 1

			arg_32_0:resetModelState(arg_32_1)

			return
		end

		arg_32_1:attack(4, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_0 = xyd.tables.model:getAttack4Sound(arg_32_0.modelID)
	elseif arg_32_0.modelState == xyd.ModelState.Attack5 then
		if not arg_32_1:hasAnimation("gongji05") then
			arg_32_0.modelState = arg_32_0.modelState + 1

			arg_32_0:resetModelState(arg_32_1)

			return
		end

		arg_32_1:attack(5, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_0 = xyd.tables.model:getAttack4Sound(arg_32_0.modelID)
	else
		arg_32_0:setIsShow()
	end

	if var_32_0 and var_32_0 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_32_0, false)
	end

	arg_32_0.modelState = arg_32_0.modelState + 1
end

function var_0_0.setIsShow(arg_33_0)
	arg_33_0.isShow = false

	arg_33_0.heroModel:idle()
end

function var_0_0.scrollListener(arg_34_0, arg_34_1)
	if arg_34_1.name == "began" then
		arg_34_0.scrollViewMoved_ = false
		arg_34_0.prevX_ = arg_34_1.x
	elseif arg_34_1.name == "moved" and 10 <= math.abs(arg_34_1.x - arg_34_0.prevX_) then
		arg_34_0.scrollViewMoved_ = true
	end
end

function var_0_0.addBgEffect(arg_35_0)
	local var_35_0 = var_0_13.Background1 .. ".json"
	local var_35_1 = var_0_13.Background1 .. ".atlas"

	arg_35_0.bgEffect = var_0_1.new(var_35_0, var_35_1, 1)

	arg_35_0:nodeByName("background"):addChild(arg_35_0.bgEffect, arg_35_0.BG_ZORDER + 5)
	arg_35_0.bgEffect:setPosition(303, 593)
	arg_35_0.bgEffect:play(nil, true)

	local var_35_2 = var_0_13.Background2 .. ".json"
	local var_35_3 = var_0_13.Background2 .. ".atlas"

	arg_35_0.bgEffect2 = var_0_1.new(var_35_2, var_35_3, 1)

	arg_35_0:nodeByName("background"):addChild(arg_35_0.bgEffect2, arg_35_0.BG_ZORDER + 5)
	arg_35_0.bgEffect2:setPosition(303, 593)
	arg_35_0.bgEffect2:play(nil, true)
	arg_35_0.bgEffect2:setScaleX(0.74)
	arg_35_0.bgEffect2:setScaleY(1.17)
	arg_35_0.bgEffect2:setRotation(51.5)
end

function var_0_0.addActiveEffeft(arg_36_0, arg_36_1, arg_36_2, arg_36_3, arg_36_4)
	local var_36_0 = arg_36_3 or 1
	local var_36_1 = "skeletons/ui_effect/element_equip/element_" .. arg_36_2

	if arg_36_4 then
		var_36_1 = var_36_1 .. "xiao"
	end

	local var_36_2 = xyd.createEffect(var_36_1, var_36_0)
	local var_36_3 = arg_36_1:getContentSize()

	var_36_2:addTo(arg_36_1)
	var_36_2:setPosition(var_36_3.width / 2, var_36_3.height / 2)
	var_36_2:play(nil, true)
end

function var_0_0.willClose(arg_37_0)
	if arg_37_0.handle then
		var_0_2.unscheduleGlobal(arg_37_0.handle)

		arg_37_0.handle = nil
	end
end

return var_0_0
