local var_0_0 = class("BattlePassShopDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
	arg_1_0.itemNum = arg_1_2.itemNum
	arg_1_0.index = arg_1_2.index
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

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("is_for_words"):setString(var_0_1:translation("SHOP_IS_THE_HERO_ITEM"))

	if xyd.tables.item:type(itemID) == xyd.ItemType.STONE and arg_3_0.player_:isFuncOpen(xyd.FunctionID.ID_RECOMMEND) then
		local var_3_0 = xyd.tables.item:heroID(itemID)

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
			if iter_3_1:getItemHeroHasNotEquip(itemID) then
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

	local var_3_5 = xyd.tables.item:name(itemID)
	local var_3_6 = xyd.tables.item:desc1(itemID)
	local var_3_7 = xyd.tables.item:desc2(itemID)

	arg_3_0:nodeByName(ShopDetailWindow.NAME_TXT):setString(var_3_5)
	arg_3_0:nodeByName(ShopDetailWindow.DESC2_TXT):setString(var_3_7)

	local var_3_8 = arg_3_0.backpack_:getItemNumByID(itemID)

	arg_3_0:nodeByName("num_txt"):setString(tostring(var_3_8))

	local var_3_9, var_3_10 = arg_3_0:nodeByName("num_txt"):getPosition()

	arg_3_0:nodeByName("jian_txt"):x(var_3_9 + arg_3_0:nodeByName("num_txt"):getContentSize().width + 5)
	arg_3_0:nodeByName(ShopDetailWindow.PRICE_LABEL):setString(string.format(var_0_1:translation("SHOP_BUY_ITEM_NUM"), tostring(arg_3_0.itemNum)))
	arg_3_0:nodeByName(ShopDetailWindow.PRICE):setString(arg_3_0.params.sellPrice)

	local var_3_11 = arg_3_0.params.sellPrice
	local var_3_12 = xyd.AssetLoader:get():loadSprite("images/jinbi.png")

	if arg_3_0.shopType == xyd.ShopType.SKIN and arg_3_0.backpack_:getItemNumByID(xyd.tables.misc.skinTicketId) > 0 then
		arg_3_0:nodeByName(ShopDetailWindow.PRICE):setString(1)

		var_3_12 = xyd.AssetLoader:get():loadSprite("images/icon/eco/skin_coin.png")
	end

	arg_3_0:nodeByName(ShopDetailWindow.IMG_CURRENCY):removeAllChildren()
	arg_3_0:nodeByName(ShopDetailWindow.IMG_CURRENCY):setScale(0.85)

	if var_3_12 then
		xyd.displaySpriteOnContainer(var_3_12, arg_3_0:nodeByName(ShopDetailWindow.IMG_CURRENCY), false)
	elseif sellType == xyd.currencyType.STONE or sellType == xyd.currencyType.PET_STONE then
		local var_3_13 = arg_3_0:nodeByName(ShopDetailWindow.IMG_CURRENCY)
		local var_3_14 = var_3_13:getContentSize().height

		var_3_13:setContentSize(var_3_14, var_3_14)

		if sellType == xyd.currencyType.STONE and var_3_11 <= arg_3_0.backpack_:getItemNumByID(arg_3_0.stoneReplaceId) then
			xyd.setItemBorder(var_3_13, arg_3_0.stoneReplaceId, false, false)
		else
			xyd.setItemBorder(var_3_13, arg_3_0.stoneID, false, false)
		end
	end

	arg_3_0.iconImg = arg_3_0:nodeByName(ShopDetailWindow.IMG_ICON)

	arg_3_0.iconImg:removeAllChildren()
	xyd.setItemBorder(arg_3_0.iconImg, arg_3_0.itemID)
	arg_3_0.panelAttr_:removeAllChildren()

	local var_3_15 = xyd.tables.item:type(itemID)

	if var_3_15 == xyd.ItemType.EQUIPMENT or var_3_15 == xyd.ItemType.PET_EQUIP then
		local var_3_16 = xyd.tables.item:attrs(itemID)
		local var_3_17 = {}

		if var_3_16[1] and var_3_16[2] and var_3_16[3] and var_3_16[1] == var_3_16[2] and var_3_16[2] == var_3_16[3] then
			local var_3_18 = {
				name = AttrTable:name(1) .. "，" .. AttrTable:name(2) .. "，" .. AttrTable:name(3),
				value = var_3_16[1]
			}

			table.insert(var_3_17, var_3_18)

			for iter_3_3, iter_3_4 in pairs(var_3_16) do
				if iter_3_3 > 3 then
					local var_3_19 = {
						name = AttrTable:name(iter_3_3),
						value = iter_3_4
					}

					table.insert(var_3_17, var_3_19)
				end
			end
		else
			for iter_3_5, iter_3_6 in pairs(var_3_16) do
				local var_3_20 = {
					name = AttrTable:name(iter_3_5),
					value = iter_3_6
				}

				table.insert(var_3_17, var_3_20)
			end
		end

		arg_3_0:nodeByName("desc_bg"):height(math.max((#var_3_17 + 1) * ATTR_LABEL_HEIGHT, 134))
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight() - 10)
		arg_3_0:createLabels(var_3_17)
		arg_3_0:nodeByName(ShopDetailWindow.DESC1_TXT):setVisible(false)
	elseif var_3_15 == xyd.ItemType.STONE then
		local var_3_21 = xyd.tables.item:heroID(itemID)
		local var_3_22 = xyd.tables.hero:name(var_3_21)
		local var_3_23 = xyd.tables.hero:initialStar(var_3_21)
		local var_3_24 = STONE_NUM[var_3_23]
		local var_3_25

		if xyd.isSuperHero(var_3_21) then
			var_3_25 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_3_22)
		else
			var_3_25 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_3_24, var_3_22, var_3_22)
		end

		arg_3_0:nodeByName(ShopDetailWindow.DESC1_TXT):setString(var_3_25)
		arg_3_0:nodeByName(ShopDetailWindow.DESC1_TXT):setVisible(true)
		arg_3_0:nodeByName("desc_bg"):height(134)
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight() - 10)
	elseif var_3_15 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_3_15 == xyd.ItemType.REEL_FRAGMENT or var_3_15 == xyd.ItemType.BOOK_FRAGMENT then
		local var_3_26 = xyd.tables.item:itemNum(itemID)
		local var_3_27 = xyd.tables.item:composeItem(itemID)
		local var_3_28 = xyd.tables.item:name(var_3_27)
		local var_3_29 = string.format(var_0_1:translation("FRAGMENT_DESC1"), var_3_26, var_3_28)
		local var_3_30 = string.format(var_0_1:translation("FRAGMENT_DESC2"), var_3_8, var_3_26)

		arg_3_0:createStrLabel(var_3_29, var_3_30)
		arg_3_0:nodeByName(ShopDetailWindow.DESC1_TXT):setVisible(false)
		arg_3_0:nodeByName("desc_bg"):height(134)
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight())
	else
		arg_3_0:nodeByName(ShopDetailWindow.DESC1_TXT):setString(var_3_6)
		arg_3_0:nodeByName(ShopDetailWindow.DESC1_TXT):setVisible(true)
		arg_3_0:nodeByName("desc_bg"):height(134)
		arg_3_0:nodeByName("desc2_txt"):y(arg_3_0:nodeByName("desc_bg"):getY() - arg_3_0:nodeByName("desc_bg"):getHeight() - 10)
	end
end

return var_0_0
