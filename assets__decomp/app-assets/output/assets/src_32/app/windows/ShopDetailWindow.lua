local var_0_0 = class("ShopDetailWindow", import("app.common.ui.BaseWindow"))

var_0_0.CLOSE_BUTTON = "close_button"
var_0_0.BUY_BUTTON = "buy_button"
var_0_0.IMG_ICON = "img_icon"
var_0_0.NAME_TXT = "name_txt"
var_0_0.NUM_TXT = "num_txt"
var_0_0.DESC1_TXT = "desc1_txt"
var_0_0.DESC2_TXT = "desc2_txt"
var_0_0.IMG_CURRENCY = "img_currency"
var_0_0.PRICE = "price_txt"
var_0_0.PRICE_LABEL = "price_label"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.attr
local var_0_4 = 28
local var_0_5 = cc.c3b(68, 68, 85)
local var_0_6 = {
	10,
	30,
	80
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.itemNum = arg_1_2.itemNum
	arg_1_0.index = arg_1_2.index
	arg_1_0.shopType = arg_1_2.shopType
	arg_1_0.stoneID = arg_1_2.stoneID
	arg_1_0.sellPrice = arg_1_2.sellPrice
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.panelAttr_ = arg_2_0:nodeByName("panel_attr")

	arg_2_0:nodeByName("has_txt"):setString(var_0_1:translation("ITEM_OWN"))
	arg_2_0:nodeByName("jian_txt"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.backpack_ = arg_2_0.player_:getBackpack()
	arg_2_0.shop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)
	arg_2_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_2_0.stoneReplaceId = xyd.tables.misc.spaceShopItem

	arg_2_0:layout(arg_2_0.itemID)
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("is_for_words"):setString(var_0_1:translation("SHOP_IS_THE_HERO_ITEM"))

	if xyd.tables.item:type(arg_3_1) == xyd.ItemType.STONE and arg_3_0.player_:isFuncOpen(xyd.FunctionID.ID_RECOMMEND) then
		local var_3_0 = xyd.tables.item:heroID(arg_3_1)

		arg_3_0:nodeByName("panel_recommend"):setVisible(true)
		arg_3_0:nodeByName("score_txt"):setString(var_0_1:translation("RECOMMEND_SCORE_TEXT") .. ":" .. arg_3_0.heroRecommend:getHeroRecommendScore(var_3_0))
		arg_3_0:nodeByName("score_txt"):enableOutline(cc.c4b(77, 87, 142, 255), 2)
		arg_3_0:nodeByName("panel_desc"):setPositionY(arg_3_0:nodeByName("panel_desc"):getPositionY() - arg_3_0:nodeByName("panel_recommend"):getContentSize().height)
	else
		arg_3_0:nodeByName("panel_recommend"):setVisible(false)
	end

	local var_3_1 = false

	arg_3_0.heros_list = {}

	if arg_3_0.player_.heros_ and next(arg_3_0.player_.heros_) then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.player_.heros_) do
			if iter_3_1:getItemHeroHasNotEquip(arg_3_1) then
				var_3_1 = true

				table.insert(arg_3_0.heros_list, iter_3_1)
			end
		end
	end

	table.sort(arg_3_0.heros_list, function(arg_4_0, arg_4_1)
		if arg_4_0:getLevel() > arg_4_1:getLevel() then
			return true
		elseif arg_4_0:getLevel() == arg_4_1:getLevel() then
			if arg_4_0:getColor() > arg_4_1:getColor() then
				return true
			elseif arg_4_0:getColor() == arg_4_1:getColor() then
				if arg_4_0:getZhandouli() > arg_4_1:getZhandouli() then
					return true
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	end)

	if var_3_1 then
		arg_3_0:nodeByName("container"):setPosition(arg_3_0:nodeByName("container"):getX() - 100, arg_3_0:nodeByName("container"):getY())

		arg_3_0.list = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 20, 250, 440),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_3_0:nodeByName("is_for_list"))

		arg_3_0.list:reload()

		for iter_3_2 = 1, #arg_3_0.heros_list do
			local var_3_2 = display.newNode()
			local var_3_3 = arg_3_0.list:newItem()
			local var_3_4 = display.newNode()

			var_3_4:setContentSize(120, 120)
			var_3_4:setPosition(cc.p(45, 20))
			xyd.setAvatarBorderNewUI(arg_3_0.heros_list[iter_3_2], var_3_4)
			var_3_4:addTo(var_3_2)
			var_3_2:setContentSize(250, 150)
			var_3_3:addContent(var_3_2)
			var_3_3:setItemSize(250, 150)
			arg_3_0.list:addItem(var_3_3)
		end

		arg_3_0.list:reload()
	else
		arg_3_0:nodeByName("is_for_list"):setVisible(false)
	end

	local var_3_5 = xyd.tables.item:name(arg_3_1)
	local var_3_6 = xyd.tables.item:desc1(arg_3_1)
	local var_3_7 = xyd.tables.item:desc2(arg_3_1)

	arg_3_0:nodeByName(var_0_0.NAME_TXT):setString(var_3_5)
	arg_3_0:nodeByName(var_0_0.DESC2_TXT):setString(var_3_7)

	local var_3_8 = arg_3_0.backpack_:getItemNumByID(arg_3_1)

	arg_3_0:nodeByName("num_txt"):setString(tostring(var_3_8))

	local var_3_9, var_3_10 = arg_3_0:nodeByName("num_txt"):getPosition()

	arg_3_0:nodeByName("jian_txt"):x(var_3_9 + arg_3_0:nodeByName("num_txt"):getContentSize().width + 5)
	arg_3_0:nodeByName(var_0_0.PRICE_LABEL):setString(string.format(var_0_1:translation("SHOP_BUY_ITEM_NUM"), tostring(arg_3_0.itemNum)))
	arg_3_0:nodeByName(var_0_0.PRICE):setString(arg_3_0.params.sellPrice)

	local var_3_11 = arg_3_0.params.sellType
	local var_3_12 = arg_3_0.params.sellPrice
	local var_3_13

	if var_3_11 == xyd.currencyType.MANA then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")
	elseif var_3_11 == xyd.currencyType.CRYSTAL then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
	elseif var_3_11 == xyd.currencyType.ARENA_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/shell.png")
	elseif var_3_11 == xyd.currencyType.MARCH_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/march_coin.png")
	elseif var_3_11 == xyd.currencyType.TOP_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/top_coin.png")
	elseif var_3_11 == xyd.currencyType.GUILD_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/guild_coin.png")
	elseif var_3_11 == xyd.currencyType.REGION_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/region_coin.png")
	elseif var_3_11 == xyd.currencyType.HONOR_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/war_coin.png")
	elseif var_3_11 == xyd.currencyType.ILLUSION_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/illusion_coin.png")
	elseif var_3_11 == xyd.currencyType.ACADEMY_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/academy_coin.png")
	elseif var_3_11 == xyd.currencyType.TEA_TALK then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/gay_coin.png")
	elseif var_3_11 == xyd.currencyType.TEAM_DUNGEON then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/team_dungeon_coin.png")
	elseif var_3_11 == xyd.currencyType.SUMMON_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/summon_coin.png")
	elseif var_3_11 == xyd.currencyType.SKIN_FRAGMENT then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/ultra_skin_coin.png")
	elseif var_3_11 == xyd.currencyType.TUTOR_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/tutor_coin.png")
	elseif var_3_11 == xyd.currencyType.CUBE_NEW then
		var_3_13 = xyd.AssetLoader:get():loadSprite("windows/champions_league/icon_cube.png")
	elseif var_3_11 == xyd.currencyType.BATTLE_PASS_COIN then
		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/battle_pass_coin.png")
	end

	if arg_3_0.shopType == xyd.ShopType.SKIN and arg_3_0.backpack_:getItemNumByID(xyd.tables.misc.skinTicketId) > 0 then
		arg_3_0:nodeByName(var_0_0.PRICE):setString(1)

		var_3_13 = xyd.AssetLoader:get():loadSprite("images/icon/eco/skin_coin.png")
	end

	arg_3_0:nodeByName(var_0_0.IMG_CURRENCY):removeAllChildren()
	arg_3_0:nodeByName(var_0_0.IMG_CURRENCY):setScale(0.85)

	if var_3_13 then
		xyd.displaySpriteOnContainer(var_3_13, arg_3_0:nodeByName(var_0_0.IMG_CURRENCY), false)
	elseif var_3_11 == xyd.currencyType.STONE or var_3_11 == xyd.currencyType.PET_STONE then
		local var_3_14 = arg_3_0:nodeByName(var_0_0.IMG_CURRENCY)
		local var_3_15 = var_3_14:getContentSize().height

		var_3_14:setContentSize(var_3_15, var_3_15)

		if var_3_11 == xyd.currencyType.STONE and var_3_12 <= arg_3_0.backpack_:getItemNumByID(arg_3_0.stoneReplaceId) then
			xyd.setItemBorder(var_3_14, arg_3_0.stoneReplaceId, false, false)
		else
			xyd.setItemBorder(var_3_14, arg_3_0.stoneID, false, false)
		end
	end

	arg_3_0.iconImg = arg_3_0:nodeByName(var_0_0.IMG_ICON)

	arg_3_0.iconImg:removeAllChildren()
	xyd.setItemBorder(arg_3_0.iconImg, arg_3_0.itemID)
	arg_3_0.panelAttr_:removeAllChildren()

	local var_3_16 = xyd.tables.item:type(arg_3_1)

	if var_3_16 == xyd.ItemType.EQUIPMENT or var_3_16 == xyd.ItemType.PET_EQUIP then
		local var_3_17 = xyd.tables.item:attrs(arg_3_1)
		local var_3_18 = {}

		if var_3_17[1] and var_3_17[2] and var_3_17[3] and var_3_17[1] == var_3_17[2] and var_3_17[2] == var_3_17[3] then
			local var_3_19 = {
				name = var_0_3:name(1) .. "，" .. var_0_3:name(2) .. "，" .. var_0_3:name(3),
				value = var_3_17[1]
			}

			table.insert(var_3_18, var_3_19)

			for iter_3_3, iter_3_4 in pairs(var_3_17) do
				if iter_3_3 > 3 then
					local var_3_20 = {
						name = var_0_3:name(iter_3_3),
						value = iter_3_4
					}

					table.insert(var_3_18, var_3_20)
				end
			end
		else
			for iter_3_5, iter_3_6 in pairs(var_3_17) do
				local var_3_21 = {
					name = var_0_3:name(iter_3_5),
					value = iter_3_6
				}

				table.insert(var_3_18, var_3_21)
			end
		end

		arg_3_0:nodeByName("desc_bg"):height(math.max((#var_3_18 + 1) * var_0_4, 134))
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight() - 10)
		arg_3_0:createLabels(var_3_18)
		arg_3_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)
	elseif var_3_16 == xyd.ItemType.STONE then
		local var_3_22 = xyd.tables.item:heroID(arg_3_1)
		local var_3_23 = xyd.tables.hero:name(var_3_22)
		local var_3_24 = xyd.tables.hero:initialStar(var_3_22)
		local var_3_25 = var_0_6[var_3_24]
		local var_3_26

		if xyd.isSuperHero(var_3_22) then
			var_3_26 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_3_23)
		else
			var_3_26 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_3_25, var_3_23, var_3_23)
		end

		arg_3_0:nodeByName(var_0_0.DESC1_TXT):setString(var_3_26)
		arg_3_0:nodeByName(var_0_0.DESC1_TXT):setVisible(true)
		arg_3_0:nodeByName("desc_bg"):height(134)
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight() - 10)
	elseif var_3_16 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_3_16 == xyd.ItemType.REEL_FRAGMENT or var_3_16 == xyd.ItemType.BOOK_FRAGMENT then
		local var_3_27 = xyd.tables.item:itemNum(arg_3_1)
		local var_3_28 = xyd.tables.item:composeItem(arg_3_1)
		local var_3_29 = xyd.tables.item:name(var_3_28)
		local var_3_30 = string.format(var_0_1:translation("FRAGMENT_DESC1"), var_3_27, var_3_29)
		local var_3_31 = string.format(var_0_1:translation("FRAGMENT_DESC2"), var_3_8, var_3_27)

		arg_3_0:createStrLabel(var_3_30, var_3_31)
		arg_3_0:nodeByName(var_0_0.DESC1_TXT):setVisible(false)
		arg_3_0:nodeByName("desc_bg"):height(134)
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight())
	else
		arg_3_0:nodeByName(var_0_0.DESC1_TXT):setString(var_3_6)
		arg_3_0:nodeByName(var_0_0.DESC1_TXT):setVisible(true)
		arg_3_0:nodeByName("desc_bg"):height(134)
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight() - 10)
	end
end

function var_0_0.createStrLabel(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = {
		size = 22,
		color = var_0_5
	}
	local var_5_1 = xyd.AssetLoader:get():loadLabel(var_5_0)

	var_5_1:setMaxLineWidth(310)
	var_5_1:setString(arg_5_1)
	var_5_1:y(114)
	var_5_1:setAnchorPoint(cc.p(0, 1))
	var_5_1:addTo(arg_5_0.panelAttr_)

	local var_5_2 = xyd.AssetLoader:get():loadLabel(var_5_0)

	var_5_2:setString(arg_5_2)
	var_5_2:setAnchorPoint(cc.p(0, 1))
	var_5_2:y(54)
	var_5_2:addTo(arg_5_0.panelAttr_)
end

function var_0_0.createLabels(arg_6_0, arg_6_1)
	local var_6_0 = arg_6_0.panelAttr_:getContentSize().height

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_1 = {
			size = 22,
			color = var_0_5
		}
		local var_6_2 = xyd.AssetLoader:get():loadLabel(var_6_1)

		var_6_2:setString(iter_6_1.name .. "+" .. iter_6_1.value)
		var_6_2:y(var_6_0 - (iter_6_0 - 1) * var_0_4)
		var_6_2:setAnchorPoint(cc.p(0, 1))
		var_6_2:addTo(arg_6_0.panelAttr_)
	end
end

function var_0_0.buy(arg_7_0)
	local var_7_0 = {
		index = arg_7_0.index,
		shop_type = arg_7_0.shopType
	}

	if arg_7_0.shopType == xyd.ShopType.MAGIC then
		var_7_0.client_price = arg_7_0.sellPrice
	end

	arg_7_0.shop_:buy(var_7_0, function(arg_8_0)
		if arg_8_0 == xyd.error.OK then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.SHOP_DIALOG,
				messageType = xyd.ShopMessageType.BUY
			})

			if arg_7_0.shopType == xyd.ShopType.SKIN and arg_7_0.backpack_:getItemNumByID(xyd.tables.misc.skinTicketId) > 0 then
				local var_8_0 = {
					itemID = xyd.tables.misc.skinTicketId
				}

				var_8_0.itemNum = 1

				arg_7_0.backpack_:removeItem(var_8_0)
			end

			if arg_7_0.shopType == xyd.ShopType.SKIN or arg_7_0.shopType == xyd.ShopType.ULTRA_SKIN then
				local var_8_1 = xyd.WindowManager.get():getWindow("skin_shop")

				if var_8_1 then
					var_8_1.shopList:refreshList()
				end
			end

			if arg_7_0.shopType == xyd.ShopType.MAGIC then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_MAGIC_GIFT
				})
			end

			if arg_7_0.shopType == xyd.ShopType.COURSE then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.REFRESH_COURSE_BOOK
				})
			end

			if arg_7_0.shopType == xyd.ShopType.CHAMPIONS_LEAGUE then
				arg_7_0.backpack_:addItemsByID(var_0_2:getValue("cross_arena_magic_cube_new"), -arg_7_0.sellPrice)
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.CHAMPIONS_ECONOMY_AFTER,
					messageType = arg_7_0.params.sellType
				})
			end

			if arg_7_0.shopType == xyd.ShopType.BATTLE_PASS_SHOP then
				arg_7_0.backpack_:addItemsByID(var_0_2:getValue("battle_pass_shop_coin_id"), -arg_7_0.sellPrice)

				local var_8_2 = xyd.WindowManager.get():getWindow("battle_pass_shop")

				if var_8_2 and not tolua.isnull(var_8_2) then
					var_8_2:upadteEco()
				end
			end

			if arg_7_0.shopType == xyd.ShopType.COURSE then
				local var_8_3 = xyd.WindowManager.get():getWindow("course")

				if var_8_3 and not tolua.isnull(var_8_3) then
					var_8_3:updateLevelUpItems()
				end
			end

			xyd.WindowManager.get():closeWindow(arg_7_0.name or "shop_detail_window")
			xyd.WindowManager.get():closeWindow("skin_shop_detail_window")
		end
	end)
end

function var_0_0.didOpen(arg_9_0)
	arg_9_0:nodeByName(var_0_0.BUY_BUTTON):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName(var_0_0.BUY_BUTTON), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_10_0 = arg_9_0.params.sellType
			local var_10_1 = arg_9_0.params.sellPrice
			local var_10_2

			if arg_9_0.stoneID then
				var_10_2 = arg_9_0.backpack_:getItemNumByID(arg_9_0.stoneID)
				stoneReplaceNum = arg_9_0.backpack_:getItemNumByID(arg_9_0.stoneReplaceId)
			end

			local var_10_3 = false

			if arg_9_0.shopType == xyd.ShopType.SKIN and arg_9_0.backpack_:getItemNumByID(xyd.tables.misc.skinTicketId) > 0 then
				var_10_3 = true
			end

			if not var_10_3 and var_10_1 > arg_9_0.player_.crystal and var_10_0 == xyd.currencyType.CRYSTAL then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					local var_11_0 = {}

					var_11_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
				end, nil, nil, arg_9_0.colorMode)
			elseif var_10_1 > arg_9_0.player_.mana and var_10_0 == xyd.currencyType.MANA then
				xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH):judgePush(4)
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("JINBI_ABSENCE"), function()
					local var_12_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_9_0.player_:isFuncOpen(var_12_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_12_1 = xyd.tables.functionOpen:level(var_12_0)
						local var_12_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_12_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_12_2
						})
					end
				end, nil, nil, arg_9_0.colorMode)
			elseif var_10_1 > arg_9_0.player_.arena_coin and var_10_0 == xyd.currencyType.ARENA_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ARENA_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.march_coin and var_10_0 == xyd.currencyType.MARCH_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MARCH_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.top_coin and var_10_0 == xyd.currencyType.TOP_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TOP_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.guild_coin and var_10_0 == xyd.currencyType.GUILD_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GUILD_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.region_coin and var_10_0 == xyd.currencyType.REGION_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("REGION_COIN_ABSENCE")
				})
			elseif var_10_0 == xyd.currencyType.STONE and var_10_2 < var_10_1 and var_10_1 > stoneReplaceNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("STONE_ABSENCE")
				})
			elseif var_10_0 == xyd.currencyType.PET_STONE and var_10_2 < var_10_1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("STONE_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.honorCoin and var_10_0 == xyd.currencyType.HONOR_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("HONOR_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.academyCoin and var_10_0 == xyd.currencyType.ACADEMY_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ACADEMY_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.illusionCoin and var_10_0 == xyd.currencyType.ILLUSION_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PARADISE_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.teamDungeonCoin and var_10_0 == xyd.currencyType.TEAM_DUNGEON then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TEAM_DUNGEON_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.summonCoin and var_10_0 == xyd.currencyType.SUMMON_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SUMMON_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.friendMedal and var_10_0 == xyd.currencyType.TEA_TALK then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GAY_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.skinFragment and var_10_0 == xyd.currencyType.SKIN_FRAGMENT then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SKIN_FRAGMENT_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_.tutorCoin and var_10_0 == xyd.currencyType.TUTOR_COIN then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TUTOR_COIN_ABSENCE")
				})
			elseif var_10_1 > arg_9_0.player_:getBackpack():getItemNumByID(var_0_2:getValue("cross_arena_magic_cube_new")) and var_10_0 == xyd.currencyType.CUBE_NEW then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("CROSS_ARENA_SHOP_TIP")
				})
			elseif arg_9_0.backpack_:getItemNumByID(arg_9_0.itemID) + arg_9_0.itemNum <= xyd.tables.item:stack(arg_9_0.itemID) then
				arg_9_0:buy()
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("SHOP_BACKPACK_IS_FULL")
				})
			end
		end
	end)
	arg_9_0:addBlockLayer()
end

return var_0_0
