local var_0_0 = class("ItemTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	10,
	30,
	80
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.id = arg_1_2.id
	arg_1_0.hasNum = arg_1_2.hasNum
	arg_1_0.showNum = arg_1_2.showNum
	arg_1_0.itemHeroList = arg_1_2.itemHeroList

	dump(arg_1_2.itemHeroList)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("hero_can_use_txt"):setVisible(false)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.createLabel(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	local var_3_0 = {
		color = arg_3_2,
		size = arg_3_1
	}
	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_1:setMaxLineWidth(290)

	if arg_3_3 then
		var_3_1:setString(arg_3_3)
	end

	var_3_1:addTo(arg_3_4)

	return var_3_1
end

function var_0_0.getDescByItemType(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.item:type(arg_4_0.id)

	if var_4_0 == xyd.ItemType.EQUIPMENT or var_4_0 == xyd.ItemType.PET_EQUIP then
		local var_4_1 = xyd.tables.item:attrs(arg_4_0.id)
		local var_4_2 = {}

		for iter_4_0, iter_4_1 in pairs(var_4_1) do
			local var_4_3 = {
				name = xyd.tables.attr:name(iter_4_0),
				value = iter_4_1
			}

			table.insert(var_4_2, var_4_3)
		end

		local var_4_4 = ""

		for iter_4_2 = 1, #var_4_2 do
			var_4_4 = var_4_4 .. var_4_2[iter_4_2].name .. "+" .. var_4_2[iter_4_2].value .. "\n"
		end

		arg_4_1:setString(var_4_4)
	elseif var_4_0 == xyd.ItemType.STONE then
		local var_4_5 = xyd.tables.item:heroID(arg_4_0.id)
		local var_4_6 = xyd.tables.hero:name(var_4_5)
		local var_4_7 = xyd.tables.hero:initialStar(var_4_5)
		local var_4_8 = var_0_2[var_4_7]
		local var_4_9

		if xyd.isSuperHero(var_4_5) then
			var_4_9 = string.format(xyd.tables.translation:translation("BACKPACK_SUPER_STONE_DESC"), var_4_6)
		else
			var_4_9 = string.format(xyd.tables.translation:translation("BACKPACK_STONE_DESC"), var_4_8, var_4_6, var_4_6)
		end

		local var_4_10 = {}

		if arg_4_0.desc2 and arg_4_0.desc2 ~= "" then
			var_4_10 = var_4_9 .. "\n" .. "\n" .. arg_4_0.desc2
		else
			var_4_10 = var_4_9
		end

		arg_4_1:setString(var_4_10)
	elseif var_4_0 == xyd.ItemType.EQUIPMENT_FRAGMENT or var_4_0 == xyd.ItemType.REEL_FRAGMENT or var_4_0 == xyd.ItemType.BOOK_FRAGMENT then
		local var_4_11 = xyd.tables.item:itemNum(arg_4_0.id)
		local var_4_12 = xyd.tables.item:composeItem(arg_4_0.id)
		local var_4_13 = xyd.tables.item:name(var_4_12)
		local var_4_14 = string.format(var_0_1:translation("FRAGMENT_DESC1"), var_4_11, var_4_13)

		arg_4_1:setString(var_4_14)
	elseif var_4_0 == xyd.ItemType.BOOK then
		arg_4_1:setString(var_0_1:translation("EFFECT_HERO") .. var_0_1:translation("COLON"))
	elseif var_4_0 == xyd.ItemType.ELEMENT_EQUIP then
		local var_4_15 = xyd.split(xyd.tables.elementEquip:equipDsc(arg_4_0.id), "|")[1]
		local var_4_16 = xyd.tables.elementEquip:base(arg_4_0.id)

		arg_4_1:setString(string.format(var_4_15, var_4_16))
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0.lev = xyd.tables.item:level(arg_5_0.id) or 1
	arg_5_0.tipName = xyd.tables.item:name(arg_5_0.id)
	arg_5_0.desc1 = xyd.tables.item:desc1(arg_5_0.id)
	arg_5_0.desc2 = xyd.tables.item:desc2(arg_5_0.id)

	if arg_5_0.id == -1 then
		arg_5_0.desc1 = xyd.tables.translation:translation("SIGN_IN_DIAMOND")
		arg_5_0.tipName = xyd.tables.translation:translation("CRYSTAL")
	elseif arg_5_0.id == -2 then
		arg_5_0.desc1 = xyd.tables.translation:translation("COIN_DESC")
		arg_5_0.tipName = xyd.tables.translation:translation("COIN")
	elseif arg_5_0.id == -3 then
		arg_5_0.desc1 = xyd.tables.translation:translation("PK_COIN")
		arg_5_0.tipName = xyd.tables.translation:translation("PK_COIN")
	elseif arg_5_0.id == -4 then
		arg_5_0.desc1 = xyd.tables.translation:translation("MARCH_COIN")
		arg_5_0.tipName = xyd.tables.translation:translation("MARCH_COIN")
	end

	local var_5_0 = arg_5_0:nodeByName("item")

	xyd.setItemBorder(var_5_0, arg_5_0.id)
	arg_5_0:nodeByName("name"):setString(arg_5_0.tipName)
	arg_5_0:nodeByName("level"):setString(string.format(xyd.tables.translation:translation("NEED_LEV"), arg_5_0.lev))
	arg_5_0:nodeByName("num"):setString(string.format(xyd.tables.translation:translation("HAS_NUM"), arg_5_0.hasNum))

	if arg_5_0.hasNum == 0 and not arg_5_0.showNum then
		arg_5_0:nodeByName("num"):setVisible(false)
	end

	local var_5_1 = xyd.tables.item:crystal(arg_5_0.id)
	local var_5_2 = xyd.tables.item:mana(arg_5_0.id)

	if var_5_1 and var_5_1 > 0 then
		arg_5_0:nodeByName("jinbi_mini"):loadTexture("windows/tips_window/zuanshi_mini.png")
		arg_5_0:nodeByName("price"):setString(var_5_1)
	elseif var_5_2 and var_5_2 > 0 then
		arg_5_0:nodeByName("price"):setString(var_5_2)
	else
		arg_5_0:nodeByName("price"):setVisible(false)
		arg_5_0:nodeByName("jinbi_mini"):setVisible(false)
	end

	local var_5_3 = arg_5_0:createLabel(20, cc.c3b(250, 230, 92), nil, arg_5_0:nodeByName("desc_container"))

	var_5_3:setAnchorPoint(cc.p(0, 1))
	var_5_3:y(70)

	if arg_5_0.desc1 and arg_5_0.desc1 ~= "" then
		local var_5_4

		if arg_5_0.desc2 and arg_5_0.desc2 ~= "" then
			var_5_4 = arg_5_0.desc1 .. "\n" .. "\n" .. arg_5_0.desc2
		else
			var_5_4 = arg_5_0.desc1
		end

		var_5_3:setString(var_5_4)
	else
		arg_5_0:getDescByItemType(var_5_3)
	end

	local var_5_5 = var_5_3:getContentSize().height

	arg_5_0:nodeByName("tishi_di"):height(var_5_5 + 2)

	if not var_5_3:getString() or var_5_3:getString() == "" or var_5_3:getString() == "\n" then
		arg_5_0:nodeByName("tishi_di"):setVisible(false)
	end

	if xyd.tables.item:type(arg_5_0.id) == xyd.ItemType.BOOK then
		arg_5_0:createLabel(20, xyd.color.WHITE, var_0_1:translation("CAN_UP_HERO"), arg_5_0:nodeByName("desc_container")):y(var_5_5)

		var_5_5 = var_5_5 + 40

		arg_5_0:nodeByName("container"):width(arg_5_0:nodeByName("container"):getWidth() + 40)
		arg_5_0:nodeByName("tishi_di"):width(arg_5_0:nodeByName("tishi_di"):getWidth() + 40)
		arg_5_0:nodeByName("jinbi_mini"):x(arg_5_0:nodeByName("jinbi_mini"):getX() + 40)
		arg_5_0:nodeByName("price"):x(arg_5_0:nodeByName("price"):getX() + 40)

		local var_5_6 = 0

		for iter_5_0, iter_5_1 in pairs(xyd.tables.cabinetBookTable:relevantHero(arg_5_0.id)) do
			local var_5_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getHeroIgnoreAwaken(iter_5_1)
			local var_5_8 = display.newNode()

			var_5_8:setContentSize(50, 50)

			if var_5_7 then
				xyd.setAvatarBorder(var_5_7:getTableID(), var_5_8, var_5_7:getColor(), var_5_7:getStar())

				var_5_6 = var_5_6 + 1
			end

			var_5_8:addTo(arg_5_0:nodeByName("desc_container"))
			var_5_8:setPosition((var_5_6 - 1) * 60, -52)
		end

		if var_5_6 ~= 0 then
			var_5_5 = var_5_5 + 60
		end
	end

	arg_5_0.tipHeight = var_5_5 + 120

	if arg_5_0.itemHeroList and next(arg_5_0.itemHeroList) ~= nil then
		arg_5_0:nodeByName("hero_can_use_txt"):setVisible(true)
		arg_5_0:nodeByName("hero_can_use_txt"):setString(var_0_1:translation("CAN_USE_HERO"))

		local var_5_9, var_5_10 = arg_5_0:nodeByName("tishi_di"):getPosition()

		arg_5_0:nodeByName("hero_can_use_txt"):setPosition(var_5_9 + 25, var_5_10 - var_5_5 - 12)
		arg_5_0:nodeByName("hero_use_container"):setPosition(var_5_9, var_5_10 - var_5_5 - 44)

		local var_5_11 = math.ceil(#arg_5_0.itemHeroList / 5)

		arg_5_0.listView = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 360, 60 * var_5_11),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		})

		arg_5_0.listView:addTo(arg_5_0:nodeByName("hero_use_container"))
		arg_5_0:nodeByName("hero_use_container"):setContentSize(320, 60 * var_5_11)

		for iter_5_2 = 1, var_5_11 do
			local var_5_12 = arg_5_0.listView:newItem()
			local var_5_13 = display.newNode()

			for iter_5_3 = 1, 5 do
				local var_5_14 = (iter_5_2 - 1) * 5 + iter_5_3

				if var_5_14 <= #arg_5_0.itemHeroList then
					local var_5_15 = display.newNode()

					var_5_15:setContentSize(55, 55)
					xyd.setAvatarBorder(arg_5_0.itemHeroList[var_5_14].hero, var_5_15)

					local var_5_16

					if arg_5_0.itemHeroList[var_5_14].plusType == 0 then
						var_5_16 = xyd.AssetLoader.get():loadSprite("windows/common/white_plus.png")
					else
						var_5_16 = xyd.AssetLoader.get():loadSprite("windows/common/green_plus.png")
					end

					var_5_16:setScale(0.5)
					var_5_16:addTo(var_5_15)
					var_5_16:setAnchorPoint(cc.p(0.5, 0.5))
					var_5_16:setPosition(42, 42)
					var_5_13:addChild(var_5_15)
					var_5_15:setPosition((iter_5_3 - 1) * 65, 0)
					var_5_15:setAnchorPoint(cc.p(0, 0))
					var_5_15:ignoreAnchorPointForPosition(false)
				end
			end

			var_5_13:setContentSize(320, 55)
			var_5_13:setAnchorPoint(cc.p(0.5, 0.5))
			var_5_12:addContent(var_5_13)
			var_5_12:setItemSize(320, 55)
			arg_5_0.listView:addItem(var_5_12)
		end

		arg_5_0.listView:reload()

		arg_5_0.tipHeight = var_5_5 + 135 + arg_5_0:nodeByName("hero_can_use_txt"):getContentSize().height + arg_5_0:nodeByName("hero_use_container"):getContentSize().height
	end

	arg_5_0:nodeByName("container"):height(arg_5_0.tipHeight)
end

function var_0_0.getTipHeight(arg_6_0)
	return arg_6_0.tipHeight
end

function var_0_0.getTipWidth(arg_7_0)
	return arg_7_0:nodeByName("container"):getWidth()
end

function var_0_0.getSoundEffect(arg_8_0)
	return xyd.tables.sound:getSound("ui_tips")
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)

	if not arg_9_1.noBlock then
		arg_9_0:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
	end
end

function var_0_0.willClose(arg_10_0, arg_10_1)
	var_0_0.super:willClose(arg_10_1)
end

return var_0_0
