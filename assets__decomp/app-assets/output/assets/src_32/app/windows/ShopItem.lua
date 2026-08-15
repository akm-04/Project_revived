local var_0_0 = class("ShopItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_2_0)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.activityModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.itemId = arg_3_1.itemID
	arg_3_0.isBuy = arg_3_1.isBuy
	arg_3_0.index = arg_3_1.index
	arg_3_0.disCount = arg_3_1.disCount
	arg_3_0.stoneID = arg_3_1.stoneID
	arg_3_0.shopType = arg_3_1.shopType
	arg_3_0.buyTimes = arg_3_1.buyTimes

	arg_3_0:setPriceDiscount(arg_3_1.sellPrice)
	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.setPriceDiscount(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_0:contentView():nodeByName("5_5zhe")
	local var_4_1 = arg_4_0:contentView():nodeByName("6zhe")

	if arg_4_0.disCount and arg_4_0.disCount == 1 then
		if (arg_4_0.selfPlayer.leftCardDay > 0 or arg_4_0.selfPlayer.leftEnergyMonthCardDay > 0) and (arg_4_0.shopType == xyd.ShopType.GNOME or arg_4_0.shopType == xyd.ShopType.BLACK) then
			var_4_1:setVisible(false)
			var_4_0:setVisible(true)
		else
			var_4_1:setVisible(true)
			var_4_0:setVisible(false)
		end
	else
		var_4_1:setVisible(false)
		var_4_0:setVisible(false)
	end

	if arg_4_0.shopType == xyd.ShopType.MAGIC and arg_4_0.activityModel:isMagicShopActivityOpen() then
		for iter_4_0, iter_4_1 in ipairs(var_0_1.magicShopNormal) do
			if arg_4_1 == iter_4_1 then
				arg_4_1 = var_0_1.magicShopDiscount[iter_4_0]

				var_4_1:setVisible(true)
			end
		end
	end

	if var_4_0:isVisible() or var_4_1:isVisible() then
		arg_4_0:contentView():nodeByName("discount_bg"):setVisible(true)
	else
		arg_4_0:contentView():nodeByName("discount_bg"):setVisible(false)
	end

	arg_4_0.params.sellPrice = arg_4_1
end

function var_0_0.layout(arg_5_0)
	arg_5_0:updateBuyLimit()

	arg_5_0.iconImg = arg_5_0:contentView():nodeByName("img_icon")

	arg_5_0.iconImg:removeAllChildren()

	local var_5_0 = arg_5_0.itemId
	local var_5_1 = arg_5_0.params.itemNum

	xyd.setItemBorder(arg_5_0.iconImg, var_5_0, false, false, var_5_1, true)

	local var_5_2 = xyd.tables.item:name(var_5_0)

	if var_5_1 > 1 then
		var_5_2 = var_5_2 .. "x" .. var_5_1
	end

	arg_5_0:contentView():nodeByName("name"):setString(var_5_2)

	local var_5_3 = arg_5_0.params.sellType
	local var_5_4 = tonumber(arg_5_0.params.sellPrice)
	local var_5_5 = xyd.tables.misc.spaceShopItem
	local var_5_6
	local var_5_7

	if var_5_3 == xyd.currencyType.STONE or var_5_3 == xyd.currencyType.PET_STONE then
		var_5_6 = arg_5_0.selfPlayer:getBackpack():getItemNumByID(arg_5_0.stoneID)
		var_5_7 = arg_5_0.selfPlayer:getBackpack():getItemNumByID(var_5_5)
	end

	arg_5_0.labelPrice = arg_5_0:contentView():nodeByName("price")

	arg_5_0.labelPrice:setString(var_5_4)

	if arg_5_0.stoneID then
		arg_5_0.labelPrice:setString(xyd.tables.item:name(arg_5_0.stoneID) .. "*" .. var_5_4)
		arg_5_0.labelPrice:setScale(0.7)

		local var_5_8, var_5_9 = arg_5_0.labelPrice:getPosition()

		arg_5_0.labelPrice:setPosition(var_5_8 - 18, var_5_9)
	end

	if var_5_4 > arg_5_0.selfPlayer.mana and var_5_3 == xyd.currencyType.MANA or var_5_4 > arg_5_0.selfPlayer.crystal and var_5_3 == xyd.currencyType.CRYSTAL or var_5_4 > arg_5_0.selfPlayer.arena_coin and var_5_3 == xyd.currencyType.ARENA_COIN or var_5_4 > arg_5_0.selfPlayer.march_coin and var_5_3 == xyd.currencyType.MARCH_COIN or var_5_4 > arg_5_0.selfPlayer.top_coin and var_5_3 == xyd.currencyType.TOP_COIN or var_5_4 > arg_5_0.selfPlayer.guild_coin and var_5_3 == xyd.currencyType.GUILD_COIN or var_5_4 > arg_5_0.selfPlayer.region_coin and var_5_3 == xyd.currencyType.REGION_COIN or var_5_4 > arg_5_0.selfPlayer.illusionCoin and var_5_3 == xyd.currencyType.ILLUSION_COIN or var_5_4 > arg_5_0.selfPlayer.academyCoin and var_5_3 == xyd.currencyType.ACADEMY_COIN or var_5_4 > arg_5_0.selfPlayer.friendMedal and var_5_3 == xyd.currencyType.TEA_TALK or var_5_3 == xyd.currencyType.STONE and var_5_6 < var_5_4 and var_5_7 < var_5_4 or var_5_3 == xyd.currencyType.HONOR_COIN and var_5_4 > arg_5_0.selfPlayer.honorCoin or var_5_3 == xyd.currencyType.TEAM_DUNGEON and var_5_4 > arg_5_0.selfPlayer.teamDungeonCoin or var_5_3 == xyd.currencyType.SUMMON_COIN and var_5_4 > arg_5_0.selfPlayer.summonCoin or var_5_3 == xyd.currencyType.PET_STONE and var_5_6 < var_5_4 then
		arg_5_0.labelPrice:setColor(cc.c4b(255, 0, 0, 150))
	else
		arg_5_0.labelPrice:setColor(cc.c4b(0, 0, 0, 255))
	end

	local var_5_10 = arg_5_0:getCurrencyPic(var_5_3)
	local var_5_11 = arg_5_0:contentView():nodeByName("img_currency")

	var_5_11:removeAllChildren()

	if var_5_10 then
		var_5_10:setScale(var_5_11:getContentSize().height / var_5_10:getContentSize().height * 1.1)
		xyd.displaySpriteOnContainer(var_5_10, var_5_11, false)
	elseif var_5_3 == xyd.currencyType.STONE or var_5_3 == xyd.currencyType.PET_STONE then
		local var_5_12 = var_5_11
		local var_5_13 = var_5_12:getContentSize().height

		var_5_12:setContentSize(var_5_13, var_5_13)

		if var_5_3 == xyd.currencyType.STONE and var_5_4 <= var_5_7 then
			xyd.setItemBorder(var_5_12, var_5_5, false, false)
		else
			xyd.setItemBorder(var_5_12, arg_5_0.stoneID, false, false)
		end
	end

	if arg_5_0.stoneID then
		local var_5_14, var_5_15 = var_5_11:getPosition()

		var_5_11:setPosition(var_5_14 - 25, var_5_15)
	end

	arg_5_0.checkgou = arg_5_0:contentView():nodeByName("gou")
	arg_5_0.bgSelect = arg_5_0:contentView():nodeByName("bg_item_select")
	arg_5_0.buyOne = arg_5_0:contentView():nodeByName("buy_one")

	arg_5_0.buyOne:setTouchSwallowEnabled(false)
	arg_5_0.buyOne:setTouchEnabled(true)

	arg_5_0.buySelect = arg_5_0:contentView():nodeByName("buy_select")

	arg_5_0.buySelect:setTouchSwallowEnabled(false)
	arg_5_0.buySelect:setTouchEnabled(true)
	arg_5_0:setBlock()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.BUY_SHOP, function(arg_6_0)
		if arg_5_0.params.index == arg_6_0.params.index and arg_5_0.shopType ~= xyd.ShopType.COURSE then
			arg_5_0.params.isBuy = arg_6_0.params.isBuy
			arg_5_0.params.buyTimes = arg_6_0.params.buy_times
			arg_5_0.isBuy = arg_6_0.params.isbuy
			arg_5_0.buyTimes = arg_6_0.params.buy_times

			arg_5_0:setBlock()
			arg_5_0:updateBuyLimit()
		end

		if arg_6_0.params.shop_type == arg_5_0.shopType then
			arg_5_0:updateRepalceItem()
		end
	end)
end

function var_0_0.updateBuyLimit(arg_7_0, ...)
	local var_7_0 = xyd.tables.shop:limitTimes(arg_7_0.shopType)[arg_7_0.index]

	if var_7_0 and var_7_0 > 0 and arg_7_0.buyTimes then
		arg_7_0:contentView():nodeByName("buy_limit_bg"):setVisible(true)
		arg_7_0:contentView():nodeByName("buy_limit_txt"):setVisible(true)
		arg_7_0:contentView():nodeByName("buy_limit_txt"):setString(string.format(var_0_2:translation("TUTOR_SHOP_BUY_LIMIT"), arg_7_0.buyTimes, var_7_0))
	end
end

function var_0_0.getCurrencyPic(arg_8_0, arg_8_1)
	local var_8_0

	if arg_8_1 == xyd.currencyType.MANA then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/icon_coin.png")
	elseif arg_8_1 == xyd.currencyType.CRYSTAL then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/icon_crystal.png")
	elseif arg_8_1 == xyd.currencyType.ARENA_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/shell.png")
	elseif arg_8_1 == xyd.currencyType.MARCH_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/march_coin.png")
	elseif arg_8_1 == xyd.currencyType.TOP_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/top_coin.png")
	elseif arg_8_1 == xyd.currencyType.GUILD_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/guild_coin.png")
	elseif arg_8_1 == xyd.currencyType.REGION_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/region_coin.png")
	elseif arg_8_1 == xyd.currencyType.HONOR_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/war_coin.png")
	elseif arg_8_1 == xyd.currencyType.ILLUSION_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/illusion_coin.png")
	elseif arg_8_1 == xyd.currencyType.ACADEMY_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/academy_coin.png")
	elseif arg_8_1 == xyd.currencyType.TEA_TALK then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/gay_coin.png")
	elseif arg_8_1 == xyd.currencyType.TEAM_DUNGEON then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/team_dungeon_coin.png")
	elseif arg_8_1 == xyd.currencyType.SUMMON_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/summon_coin.png")
	elseif arg_8_1 == xyd.currencyType.SKIN_FRAGMENT then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/ultra_skin_coin.png")
	elseif arg_8_1 == xyd.currencyType.TUTOR_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/tutor_coin.png")
	elseif arg_8_1 == xyd.currencyType.CUBE_NEW then
		var_8_0 = xyd.AssetLoader:get():loadSprite("windows/champions_league/icon_cube.png")
	elseif arg_8_1 == xyd.currencyType.BATTLE_PASS_COIN then
		var_8_0 = xyd.AssetLoader:get():loadSprite("images/icon/eco/battle_pass_coin.png")
	elseif arg_8_1 == xyd.currencyType.FISH_GAMBLING_GOLD then
		var_8_0 = xyd.AssetLoader:get():loadSprite("windows/fish_gambling/fish_gold_coin.png")

		var_8_0:setScale(0.5)
	end

	return var_8_0
end

function var_0_0.setBlock(arg_9_0)
	arg_9_0:contentView():nodeByName("block_bg"):setVisible(arg_9_0.isBuy > 0)
end

function var_0_0.updateRepalceItem(arg_10_0)
	if sellType ~= xyd.currencyType.STONE then
		return
	end

	local var_10_0 = arg_10_0.params.sellType
	local var_10_1 = tonumber(arg_10_0.params.sellPrice)
	local var_10_2 = xyd.tables.misc.spaceShopItem
	local var_10_3
	local var_10_4

	if var_10_0 == xyd.currencyType.STONE or var_10_0 == xyd.currencyType.PET_STONE then
		var_10_3 = arg_10_0.selfPlayer:getBackpack():getItemNumByID(arg_10_0.stoneID)
		var_10_4 = arg_10_0.selfPlayer:getBackpack():getItemNumByID(var_10_4)
	end

	if var_10_3 < var_10_1 and var_10_4 < var_10_1 then
		arg_10_0.labelPrice:setColor(cc.c4b(255, 0, 0, 150))
	else
		arg_10_0.labelPrice:setColor(cc.c4b(255, 255, 255, 150))
	end

	local var_10_5 = arg_10_0:contentView():nodeByName("img_currency")

	var_10_5:removeAllChildren()

	if var_10_4 < var_10_1 then
		xyd.setItemBorder(var_10_5, arg_10_0.stoneID, false, false)
	else
		xyd.setItemBorder(var_10_5, var_10_2, false, false)
	end
end

function var_0_0.contentView(arg_11_0)
	if arg_11_0.contentView_ == nil then
		arg_11_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_11_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/shop_window/shop_item.csb"))
		arg_11_0.contentView_:addTo(arg_11_0)
		arg_11_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_11_0.contentView_
end

return var_0_0
