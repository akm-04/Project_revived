local var_0_0 = class("NewItemTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.itemType
local var_0_5 = xyd.tables.itemSubtype

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.params = arg_1_2
	arg_1_0.id = arg_1_2.id
	arg_1_0.hasNum = arg_1_2.hasNum
	arg_1_0.showNum = arg_1_2.showNum
	arg_1_0.desc1 = arg_1_2.desc1
	arg_1_0.tipsFlag = arg_1_2.specialTips

	if arg_1_2.hero then
		arg_1_0.hero = arg_1_2.hero
		arg_1_0.isBoss = arg_1_2.isBoss
		arg_1_0.lev = arg_1_2.lev
		arg_1_0.heroDesc = arg_1_2.desc
		arg_1_0.quality = arg_1_2.quality
		arg_1_0.heroName = arg_1_2.name
		arg_1_0.stars = arg_1_2.stars or 0
	end

	if arg_1_2.isHero then
		arg_1_0.heroName = arg_1_2.name
		arg_1_0.lev = arg_1_2.lev
		arg_1_0.quality = arg_1_2.quality
		arg_1_0.heroDesc = arg_1_2.desc
		arg_1_0.isBoss = arg_1_2.isBoss
		arg_1_0.hero = arg_1_2.hero
		arg_1_0.isHero = arg_1_2.isHero
		arg_1_0.stars = arg_1_2.stars or 0
		arg_1_0.elements = arg_1_2.elements
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	arg_2_0.panelAttr_ = arg_2_0:nodeByName("desc_container")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.showInfoContainer = true
	arg_3_0.type = var_0_2:type(arg_3_0.id) or 0

	if arg_3_0.isHero then
		arg_3_0.type = -1
	end

	arg_3_0.level = var_0_2:level(arg_3_0.id) or 1
	arg_3_0.desc = var_0_2:desc1(arg_3_0.id)
	arg_3_0.tipName = var_0_4:name(arg_3_0.type)
	arg_3_0.show = var_0_4:show(arg_3_0.type)
	arg_3_0.subType = var_0_2:subType(arg_3_0.id)

	local var_3_0 = 0
	local var_3_1 = var_0_2:crystal(arg_3_0.id)
	local var_3_2 = var_0_2:mana(arg_3_0.id)
	local var_3_3 = var_0_4:type(arg_3_0.type) or 0
	local var_3_4 = 0

	if var_3_1 and var_3_1 > 0 then
		var_3_0 = 1
		var_3_4 = var_3_1
	elseif var_3_2 and var_3_2 > 0 then
		var_3_0 = 2
		var_3_4 = var_3_2
	else
		var_3_0 = 0
		var_3_4 = 0
	end

	arg_3_0.tipHeight = 0

	arg_3_0:showInfo()

	if arg_3_0.hero or arg_3_0.isHero then
		arg_3_0:showTip(0)
	else
		arg_3_0:showTip(var_3_3, var_3_0, var_3_4)
	end
end

function var_0_0.showInfo(arg_4_0)
	if arg_4_0.id and arg_4_0.id > 0 then
		if arg_4_0.hero then
			xyd.setAvatarBorderNewUI(arg_4_0.hero, arg_4_0:nodeByName("item"))
		elseif arg_4_0.isHero then
			if arg_4_0.elements then
				if arg_4_0.elements == {} then
					xyd.setAvatarBorderNewUI(arg_4_0.id, arg_4_0:nodeByName("item"), arg_4_0.quality, arg_4_0.stars)
				else
					xyd.setAvatarBorderNewUI(arg_4_0.id, arg_4_0:nodeByName("item"), arg_4_0.quality, arg_4_0.stars, nil, nil, nil, nil, nil, nil, arg_4_0.elements)
				end
			else
				xyd.setAvatarBorderNewUI(arg_4_0.id, arg_4_0:nodeByName("item"), arg_4_0.quality, arg_4_0.stars)
			end
		else
			xyd.setItemBorder(arg_4_0:nodeByName("item"), arg_4_0.id)
		end

		arg_4_0:nodeByName("name"):setString(xyd.tables.item:name(arg_4_0.id))

		if arg_4_0.show == 1 then
			local var_4_0 = var_0_5:name(arg_4_0.subType)

			if arg_4_0.subType == 8 then
				local var_4_1 = var_0_2:skinPartner(arg_4_0.id)
				local var_4_2 = var_0_3:name(var_4_1)

				var_4_0 = var_4_0 .. " " .. var_4_2
			end

			arg_4_0:nodeByName("type_name"):setString(arg_4_0.tipName .. "  " .. var_4_0)
		else
			arg_4_0:nodeByName("type_name"):setString(arg_4_0.tipName)
		end

		if arg_4_0.lev then
			arg_4_0:nodeByName("type_name"):setString("LV." .. arg_4_0.lev)
		end
	end
end

function var_0_0.showTip(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0.player_:getBackpack():getItemNumByID(arg_5_0.id)
	local var_5_1 = var_0_2:itemNum(arg_5_0.id)
	local var_5_2 = var_0_2:stack(arg_5_0.id)
	local var_5_3 = arg_5_0.level
	local var_5_4 = arg_5_0.desc

	if arg_5_1 == 1 then
		arg_5_0:nodeByName("own_num"):setVisible(false)
		arg_5_0:createStrLabel(attr, own, var_5_3, var_5_4, arg_5_2, arg_5_3)
	elseif arg_5_1 == 2 then
		arg_5_0:nodeByName("own_num"):setString(string.format(var_0_1:translation("ACTIVITY_SP_SHOP_TIP"), var_5_0))

		if arg_5_0.type == xyd.ItemType.ELEMENT_EQUIP then
			local var_5_5 = xyd.split(xyd.tables.elementEquip:equipDsc(arg_5_0.id), "|")[1]
			local var_5_6 = xyd.tables.elementEquip:base(arg_5_0.id)

			var_5_4 = string.format(var_5_5, var_5_6)
		end

		arg_5_0:createStrLabel(attr, own, var_5_3, var_5_4, arg_5_2, arg_5_3)
	elseif arg_5_1 == 3 then
		local var_5_7 = xyd.tables.item:attrs(arg_5_0.id)
		local var_5_8 = {}

		for iter_5_0, iter_5_1 in pairs(var_5_7) do
			local var_5_9 = {
				name = xyd.tables.attr:name(iter_5_0),
				value = iter_5_1
			}

			table.insert(var_5_8, var_5_9)
		end

		local var_5_10 = ""

		for iter_5_2 = 1, #var_5_8 do
			var_5_10 = var_5_10 .. var_5_8[iter_5_2].name .. "+" .. var_5_8[iter_5_2].value .. "\n"
		end

		var_5_4 = var_5_10

		arg_5_0:nodeByName("own_num"):setString(string.format(var_0_1:translation("ACTIVITY_SP_SHOP_TIP"), var_5_0))
		arg_5_0:createStrLabel(attr, own, var_5_3, var_5_4, arg_5_2, arg_5_3)
	elseif arg_5_1 == 4 then
		arg_5_0:nodeByName("own_num"):setString(string.format(var_0_1:translation("OWN_PLUS_MAX"), var_5_0, var_5_2))
		arg_5_0:createStrLabel(attr, own, var_5_3, var_5_4, arg_5_2, arg_5_3)
	elseif arg_5_1 == 5 then
		arg_5_0:nodeByName("own_num"):setString(string.format(var_0_1:translation("SYNTHESIS_ONE"), var_5_0, var_5_1))
		arg_5_0:createStrLabel(attr, own, var_5_3, var_5_4, arg_5_2, arg_5_3)
	elseif arg_5_1 == 0 then
		arg_5_0:nodeByName("own_num"):setVisible(false)
		arg_5_0:nodeByName("type_name"):setVisible(false)
		arg_5_0:nodeByName("price_container"):setVisible(false)
		arg_5_0:getDesc1()

		local var_5_11 = ""

		if arg_5_0.id == -1 then
			var_5_11 = xyd.tables.translation:translation("SIGN_IN_DIAMOND")

			arg_5_0:nodeByName("name"):setString(xyd.tables.translation:translation("CRYSTAL"))
			xyd.setItemBorder(arg_5_0:nodeByName("item"), arg_5_0.id)
		elseif arg_5_0.id == -2 then
			var_5_11 = xyd.tables.translation:translation("COIN_DESC")

			arg_5_0:nodeByName("name"):setString(xyd.tables.translation:translation("COIN"))
			xyd.setItemBorder(arg_5_0:nodeByName("item"), arg_5_0.id)
		elseif arg_5_0.id == -3 then
			var_5_11 = xyd.tables.translation:translation("PK_COIN")

			arg_5_0:nodeByName("name"):setString(xyd.tables.translation:translation("PK_COIN"))
			xyd.setItemBorder(arg_5_0:nodeByName("item"), arg_5_0.id)
		elseif arg_5_0.id == -4 then
			var_5_11 = xyd.tables.translation:translation("MARCH_COIN")

			arg_5_0:nodeByName("name"):setString(xyd.tables.translation:translation("MARCH_COIN"))
			xyd.setItemBorder(arg_5_0:nodeByName("item"), arg_5_0.id)
		elseif arg_5_0.id == -17 then
			var_5_11 = xyd.tables.translation:translation("SKIN_COIN_TIP")

			arg_5_0:nodeByName("name"):setString(xyd.tables.asset:name(arg_5_0.id))
			xyd.setItemBorder(arg_5_0:nodeByName("item"), arg_5_0.id)
		else
			arg_5_0:nodeByName("info_container"):setVisible(false)

			arg_5_0.showInfoContainer = false
			var_5_11 = arg_5_0.desc1
		end

		if arg_5_0.hero then
			arg_5_0:nodeByName("info_container"):setVisible(true)
			arg_5_0:nodeByName("type_name"):setVisible(true)
			arg_5_0:nodeByName("name"):setString(arg_5_0.heroName)

			arg_5_0.showInfoContainer = true
			var_5_11 = arg_5_0.heroDesc

			local var_5_12 = arg_5_0.lev
		elseif arg_5_0.isHero then
			arg_5_0:nodeByName("info_container"):setVisible(true)
			arg_5_0:nodeByName("type_name"):setVisible(true)
			arg_5_0:nodeByName("name"):setString(arg_5_0.heroName)

			arg_5_0.showInfoContainer = true
			var_5_11 = arg_5_0.heroDesc

			local var_5_13 = arg_5_0.lev
		end

		arg_5_0:createStrLabel(nil, nil, nil, var_5_11, nil, nil)
	end
end

function var_0_0.getDesc1(arg_6_0)
	if arg_6_0.id == -3 then
		arg_6_0.desc1 = xyd.tables.translation:translation("STONE_DESC")
	elseif arg_6_0.id == -14 then
		for iter_6_0 = 1, #xyd.tables.activitySpringFestival:allcount() do
			if iter_6_0 == arg_6_0.tipsFlag then
				arg_6_0.desc1 = xyd.tables.activitySpringFestival:gift_list(iter_6_0)
			end
		end
	elseif arg_6_0.id == -5 then
		for iter_6_1 = 1, #xyd.tables.activitySpringLogin:all() do
			if xyd.tables.activitySpringLogin:setEffect(iter_6_1) == arg_6_0.specialItem then
				arg_6_0.desc1 = xyd.tables.item:desc1(arg_6_0.specialItem)
			end
		end
	elseif arg_6_0.id == -6 then
		arg_6_0.desc1 = xyd.tables.activityHeroSelling:giftList(1)
	elseif arg_6_0.id == -7 then
		for iter_6_2 = 1, #xyd.tables.activitySakuraSell:allcount() do
			if iter_6_2 == arg_6_0.tipsFlag then
				arg_6_0.desc1 = xyd.tables.activitySakuraSell:gift_list(iter_6_2)
			end
		end
	elseif arg_6_0.id == -8 then
		for iter_6_3 = 1, xyd.tables.activityGoHiking:tableLength() do
			if iter_6_3 == arg_6_0.tipsFlag then
				arg_6_0.desc1 = xyd.tables.activityGoHiking:getDesc(iter_6_3)
			end
		end
	elseif arg_6_0.id == -9 then
		arg_6_0.desc1 = var_0_1:translation("RANDOM_ITEM")
	elseif arg_6_0.id == -10 then
		arg_6_0.desc1 = var_0_1:translation("LUCKY_COIN_DESC")
	elseif arg_6_0.id == -11 then
		arg_6_0.desc1 = var_0_1:translation("MORE_CARD_DESC")
	elseif arg_6_0.id == -12 then
		for iter_6_4 = 1, #xyd.tables.activityPetGiftTable:allcount() do
			if iter_6_4 == arg_6_0.tipsFlag then
				arg_6_0.desc1 = xyd.tables.activityPetGiftTable:gift_list(iter_6_4)
			end
		end
	elseif arg_6_0.id == -13 then
		arg_6_0.desc1 = var_0_1:translation("RANDOM_3_STAR_HERO")
	elseif arg_6_0.id == -101 then
		arg_6_0.desc1 = var_0_1:translation("SKIN_FRAGMENT_DESC")
	elseif arg_6_0.id == -102 then
		arg_6_0.desc1 = var_0_1:translation("ACTIVITY_CULTIVATE_ITEM_TEXT")
	end
end

function var_0_0.createStrLabel(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6)
	local var_7_0 = {
		size = 20,
		color = cc.c3b(130, 254, 183)
	}
	local var_7_1 = {
		size = 20,
		color = cc.c3b(255, 255, 255)
	}
	local var_7_2 = {
		size = 20,
		color = cc.c3b(228, 214, 137)
	}
	local var_7_3 = 0

	if arg_7_5 then
		if arg_7_5 == 1 then
			arg_7_0:nodeByName("price"):setPositionX(40)
			arg_7_0:nodeByName("zuanshi_mini"):setVisible(true)
			arg_7_0:nodeByName("jinbi_mini"):setVisible(false)
			arg_7_0:nodeByName("price"):setString(":" .. arg_7_6)
		elseif arg_7_5 == 2 then
			arg_7_0:nodeByName("price"):setPositionX(40)
			arg_7_0:nodeByName("zuanshi_mini"):setVisible(false)
			arg_7_0:nodeByName("jinbi_mini"):setVisible(true)
			arg_7_0:nodeByName("price"):setString(":" .. arg_7_6)
		else
			arg_7_0:nodeByName("zuanshi_mini"):setVisible(false)
			arg_7_0:nodeByName("jinbi_mini"):setVisible(false)
			arg_7_0:nodeByName("price"):setPositionX(4)
			arg_7_0:nodeByName("price"):setString(var_0_1:translation("CANNOT_SELL"))
		end

		var_7_3 = var_7_3 + arg_7_0:nodeByName("price_container"):getHeight()
	end

	if arg_7_4 then
		local var_7_4 = xyd.AssetLoader:get():loadLabel(var_7_2)

		var_7_4:setMaxLineWidth(arg_7_0.panelAttr_:getContentSize().width)
		var_7_4:setString(arg_7_4)
		var_7_4:setAnchorPoint(cc.p(0, 0))
		var_7_4:y(var_7_3)
		var_7_4:setLineHeight(32)
		var_7_4:addTo(arg_7_0.panelAttr_)

		var_7_3 = var_7_3 + var_7_4:getContentSize().height
	end

	if arg_7_3 then
		local var_7_5 = xyd.AssetLoader:get():loadLabel(var_7_1)

		var_7_5:setMaxLineWidth(arg_7_0.panelAttr_:getContentSize().width)
		var_7_5:setString(string.format(var_0_1:translation("NEED_LEV"), arg_7_3))
		var_7_5:setAnchorPoint(cc.p(0, 0))
		var_7_5:y(var_7_3)
		var_7_5:setLineHeight(32)
		var_7_5:addTo(arg_7_0.panelAttr_)

		var_7_3 = var_7_3 + var_7_5:getContentSize().height
	end

	if arg_7_1 then
		local var_7_6 = xyd.AssetLoader:get():loadLabel(var_7_0)

		var_7_6:setMaxLineWidth(arg_7_0.panelAttr_:getContentSize().width)
		var_7_6:setString(arg_7_1)
		var_7_6:setAnchorPoint(cc.p(0, 0))
		var_7_6:y(var_7_3)
		var_7_6:setLineHeight(32)
		var_7_6:addTo(arg_7_0.panelAttr_)

		var_7_3 = var_7_3 + var_7_6:getContentSize().height
	end

	if arg_7_0.showInfoContainer then
		arg_7_0:nodeByName("info_container"):setPosition(cc.p(20, var_7_3 + 103))

		var_7_3 = var_7_3 + 103
	end

	arg_7_0.tipHeight = var_7_3 + 11

	arg_7_0:nodeByName("container"):setContentSize(362, arg_7_0.tipHeight)
end

function var_0_0.getTipHeight(arg_8_0)
	return arg_8_0.tipHeight
end

function var_0_0.getTipWidth(arg_9_0)
	return arg_9_0:nodeByName("container"):getWidth()
end

function var_0_0.getSoundEffect(arg_10_0)
	return xyd.tables.sound:getSound("ui_tips")
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)

	if not arg_11_1.noBlock then
		arg_11_0:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
	end
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	var_0_0.super:willClose(arg_12_1)
end

return var_0_0
