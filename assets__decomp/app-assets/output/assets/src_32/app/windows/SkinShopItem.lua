local var_0_0 = class("ShopItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.item
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_2_0)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.itemId = arg_3_1.itemID
	arg_3_0.isBuy = arg_3_1.isBuy
	arg_3_0.disCount = arg_3_1.disCount
	arg_3_0.stoneID = arg_3_1.stoneID
	arg_3_0.shopType = arg_3_1.shopType

	arg_3_0:setPriceDiscount(arg_3_1.sellPrice)
	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.setPriceDiscount(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:contentView():nodeByName("5_5zhe")
	local var_4_1 = arg_4_0:contentView():nodeByName("6zhe")

	if arg_4_0.disCount and arg_4_0.disCount == 1 then
		var_4_1:setVisible(true)
		var_4_0:setVisible(false)
	else
		var_4_1:setVisible(false)
		var_4_0:setVisible(false)
	end

	if arg_4_0.activityModel:isNewSkinSellShow() then
		arg_4_0.sellPrice = var_0_1.skinShopDiscountNum

		var_4_1:setVisible(true)
	else
		arg_4_0.sellPrice = arg_4_1
	end

	if not var_4_1:isVisible() then
		arg_4_0:contentView():nodeByName("discount_bg"):setVisible(false)
	else
		arg_4_0:contentView():nodeByName("discount_bg"):setVisible(true)
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.iconImg = arg_5_0:contentView():nodeByName("card_container")

	arg_5_0.iconImg:removeAllChildren()

	local var_5_0 = arg_5_0.itemId
	local var_5_1 = arg_5_0.params.itemNum
	local var_5_2 = xyd.tables.item:name(var_5_0)

	if var_5_1 > 1 then
		var_5_2 = var_5_2 .. "x" .. var_5_1
	end

	arg_5_0:contentView():nodeByName("name"):setString(var_5_2)

	local var_5_3 = arg_5_0.params.sellType
	local var_5_4 = tonumber(arg_5_0.params.sellPrice)

	arg_5_0.labelPrice = arg_5_0:contentView():nodeByName("price")

	arg_5_0.labelPrice:setString(var_5_4)

	if var_5_4 > arg_5_0.selfPlayer.crystal and var_5_3 == xyd.currencyType.CRYSTAL then
		arg_5_0.labelPrice:setColor(cc.c4b(255, 0, 0, 150))
	else
		arg_5_0.labelPrice:setColor(cc.c4b(123, 55, 0, 255))
	end

	local var_5_5 = arg_5_0:getCurrencyPic(var_5_3)
	local var_5_6 = arg_5_0:contentView():nodeByName("img_currency")

	var_5_6:removeAllChildren()

	if var_5_5 then
		var_5_5:setScale(var_5_6:getContentSize().height / var_5_5:getContentSize().height)
		xyd.displaySpriteOnContainer(var_5_5, var_5_6, false)
	end

	arg_5_0:contentView():nodeByName("new_container"):setVisible(false)
	arg_5_0:setBlock()

	local var_5_7 = var_0_2:skinPartner(var_5_0)
	local var_5_8 = var_0_2:skinModel(var_5_0)
	local var_5_9 = var_0_3.new()

	var_5_9 = arg_5_0.selfPlayer:getHeroIgnoreAwaken(var_5_7) or var_5_9:populateWithTableID(var_5_7)

	local var_5_10 = xyd.SpriteLoader.new(xyd.tables.model:card(var_5_8), nil, nil, xyd.DefaultImageType.HERO_CARD)

	var_5_10:setScale(0.85)

	local var_5_11 = arg_5_0.iconImg:getContentSize()
	local var_5_12 = cc.ClippingNode:create()
	local var_5_13 = display.newScale9Sprite("images/line_mask.png", 0, 0, var_5_11)

	var_5_13:setAnchorPoint(0, 0)
	var_5_12:setStencil(var_5_13)
	var_5_12:addChild(var_5_10)
	var_5_10:setAnchorPoint(0.5, 0.5)
	var_5_10:setPosition(var_5_11.width / 2, var_5_11.height / 2)
	var_5_12:addTo(arg_5_0.iconImg)
end

function var_0_0.getCurrencyPic(arg_6_0, arg_6_1)
	local var_6_0

	if arg_6_1 == xyd.currencyType.MANA then
		var_6_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/icon_coin.png")
	elseif arg_6_1 == xyd.currencyType.CRYSTAL then
		var_6_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/icon_crystal.png")
	elseif arg_6_1 == xyd.currencyType.SKIN_FRAGMENT then
		if arg_6_0.sellPrice > arg_6_0.selfPlayer.skinFragment then
			arg_6_0.labelPrice:setColor(cc.c4b(255, 0, 0, 150))
		end

		var_6_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/ultra_skin_coin.png")

		return var_6_0
	end

	if arg_6_0.selfPlayer:getBackpack():getItemNumByID(var_0_1.skinTicketId) > 0 then
		arg_6_0.labelPrice:setString(1)
		arg_6_0.labelPrice:setColor(cc.c4b(255, 255, 255, 150))

		var_6_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/skin_coin.png")
	end

	return var_6_0
end

function var_0_0.setBlock(arg_7_0)
	arg_7_0:contentView():nodeByName("block_bg"):setVisible(not arg_7_0:isCanBuy(arg_7_0.itemId))
	arg_7_0:contentView():nodeByName("desc_bg"):setVisible(arg_7_0:isCanBuy(arg_7_0.itemId))
end

function var_0_0.contentView(arg_8_0)
	if arg_8_0.contentView_ == nil then
		arg_8_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_8_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/skin_shop_window/skin_shop_item.csb"))
		arg_8_0.contentView_:addTo(arg_8_0)
		arg_8_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_8_0.contentView_
end

function var_0_0.isCanBuy(arg_9_0, arg_9_1)
	if arg_9_0.isBuy == 1 then
		return false
	end

	return arg_9_0:isHasSkin(arg_9_1)
end

function var_0_0.isHasSkin(arg_10_0, arg_10_1)
	local var_10_0 = var_0_2:skinPartner(arg_10_1)
	local var_10_1 = xyd.tables.hero:afterAwaken(var_10_0)
	local var_10_2 = false

	if arg_10_0.selfPlayer:getBackpack():getItemNumByID(arg_10_1) <= 0 then
		if arg_10_0.selfPlayer:getHeroByTableID(var_10_0) == nil and (var_10_1 == nil or arg_10_0.selfPlayer:getHeroByTableID(var_10_1) == nil) then
			var_10_2 = true
		end

		local function var_10_3(arg_11_0)
			local var_11_0 = false
			local var_11_1 = arg_11_0.skinIds_

			for iter_11_0 = 1, #var_11_1 do
				if var_11_1[iter_11_0] == var_0_2:skinModel(arg_10_1) then
					var_11_0 = true
				end
			end

			return var_11_0
		end

		if arg_10_0.selfPlayer:getHeroByTableID(var_10_0) == nil and var_10_1 and arg_10_0.selfPlayer:getHeroByTableID(var_10_1) and not var_10_3(arg_10_0.selfPlayer:getHeroByTableID(var_10_1)) then
			var_10_2 = true
		end

		if arg_10_0.selfPlayer:getHeroByTableID(var_10_0) and not var_10_3(arg_10_0.selfPlayer:getHeroByTableID(var_10_0)) then
			var_10_2 = true
		end
	end

	return var_10_2
end

return var_0_0
