local var_0_0 = class("NormalClickTips", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

var_0_0.IMG_ICON = "item_node"
var_0_0.LEV_TXT = "level_txt"
var_0_0.COIN_IMG = "coin_img"
var_0_0.PRICE = "price_txt"
var_0_0.DESC_CONTAINER = "desc_container"
var_0_0.BG_IMG = "jiugong_img"
var_0_0.NAME = "name_txt"
var_0_0.NUM = "num_txt"
var_0_0.DESC_DI = "desc_di"
var_0_0.BOSS = "boss_txt"

local var_0_2 = {
	10,
	30,
	80
}
local var_0_3 = {
	AVATAR_TIP = 0,
	SKILL_TIP = 2,
	SIGN_IN_TIP = 4,
	ITEM_TIP = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.id = arg_1_2.id
	arg_1_0.tipsType = arg_1_2.tipsType
	arg_1_0.tipName = arg_1_2.name
	arg_1_0.lev = arg_1_2.lev
	arg_1_0.quality = arg_1_2.quality
	arg_1_0.desc1 = arg_1_2.desc1
	arg_1_0.desc2 = arg_1_2.desc2
	arg_1_0.hasNum = arg_1_2.hasNum
	arg_1_0.showNum = arg_1_2.showNum
	arg_1_0.isBoss = arg_1_2.isBoss
	arg_1_0.has_jiantou = arg_1_2.has_jiantou
	arg_1_0.skillLevel = arg_1_2.skillLev
	arg_1_0.skillColor = arg_1_2.skillColor
	arg_1_0.itemHeroList = arg_1_2.itemHeroList
	arg_1_0.signInCrystal = arg_1_2.award_crystal
	arg_1_0.signInIdx = arg_1_2.idx
	arg_1_0.tipsFlag = arg_1_2.specialTips
	arg_1_0.specialItem = arg_1_2.specialItem
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("jiantou_img"):setVisible(false)
	arg_2_0:nodeByName("hero_can_use_txt"):setVisible(false)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.createLabel(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = {
		color = arg_3_2,
		size = arg_3_1
	}
	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_1:setMaxLineWidth(290)

	return var_3_1
end

function var_0_0.getDescByItemType(arg_4_0, arg_4_1)
	local var_4_0 = xyd.tables.item:type(arg_4_0.id)

	if var_4_0 == xyd.ItemType.EQUIPMENT then
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
	elseif var_4_0 == xyd.ItemType.ELEMENT_EQUIP then
		local var_4_15 = xyd.split(xyd.tables.elementEquip:equipDsc(arg_4_0.id), "|")[1]
		local var_4_16 = xyd.tables.elementEquip:base(arg_4_0.id)

		arg_4_1:setString(string.format(var_4_15, var_4_16))
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("hero_can_use_txt"):setString(var_0_1:translation("CAN_USE_HERO"))
	arg_5_0:nodeByName(var_0_0.LEV_TXT):setString(string.format(var_0_1:translation("NEED_LEV"), ""))

	if arg_5_0.tipsType == var_0_3.AVATAR_TIP then
		arg_5_0:nodeByName("jiantou_img"):setVisible(false)

		local var_5_0 = arg_5_0:nodeByName(var_0_0.IMG_ICON)

		var_5_0:removeAllChildren()

		local var_5_1 = arg_5_0:createLabel(20, cc.c3b(250, 230, 92))

		var_5_1:y(70)
		xyd.setAvatarBorder(arg_5_0.id, var_5_0, arg_5_0.quality, 0)
		arg_5_0:nodeByName(var_0_0.NAME):setString(arg_5_0.tipName)

		if arg_5_0.lev then
			arg_5_0:nodeByName(var_0_0.LEV_TXT):setString("LV." .. arg_5_0.lev)
		else
			arg_5_0:nodeByName(var_0_0.LEV_TXT):setString("")
		end

		var_5_1:setString(arg_5_0.desc1)
		arg_5_0:nodeByName(var_0_0.NUM):setVisible(false)
		arg_5_0:nodeByName(var_0_0.PRICE):setVisible(false)
		arg_5_0:nodeByName(var_0_0.COIN_IMG):setVisible(false)

		if arg_5_0.isBoss then
			arg_5_0:nodeByName(var_0_0.BOSS):setVisible(true)
		end

		var_5_1:setAnchorPoint(cc.p(0, 1))
		var_5_1:addTo(arg_5_0:nodeByName(var_0_0.DESC_CONTAINER))

		local var_5_2 = var_5_1:getContentSize().height

		arg_5_0:nodeByName(var_0_0.DESC_DI):height(var_5_2 + 2)

		if not var_5_1:getString() or var_5_1:getString() == "" or var_5_1:getString() == "\n" then
			arg_5_0:nodeByName(var_0_0.DESC_DI):setVisible(false)
		end

		arg_5_0.tipHeight = var_5_2 + 120

		arg_5_0:nodeByName(var_0_0.BG_IMG):height(arg_5_0.tipHeight)
	end

	if arg_5_0.tipsType == var_0_3.ITEM_TIP then
		if arg_5_0.id < 0 then
			if arg_5_0.id == -1 then
				arg_5_0.desc1 = xyd.tables.translation:translation("SIGN_IN_DIAMOND")
			elseif arg_5_0.id == -2 then
				arg_5_0.desc1 = xyd.tables.translation:translation("COIN_DESC")
			elseif arg_5_0.id == -3 then
				arg_5_0.desc1 = xyd.tables.translation:translation("STONE_DESC")
			elseif arg_5_0.id == -4 then
				for iter_5_0 = 1, #xyd.tables.activitySpringFestival:allcount() do
					if iter_5_0 == arg_5_0.tipsFlag then
						arg_5_0.desc1 = xyd.tables.activitySpringFestival:gift_list(iter_5_0)
					end
				end
			elseif arg_5_0.id == -5 then
				for iter_5_1 = 1, #xyd.tables.activitySpringLogin:all() do
					if xyd.tables.activitySpringLogin:setEffect(iter_5_1) == arg_5_0.specialItem then
						arg_5_0.desc1 = xyd.tables.item:desc1(arg_5_0.specialItem)
					end
				end
			elseif arg_5_0.id == -6 then
				arg_5_0.desc1 = xyd.tables.activityHeroSelling:giftList(1)
			elseif arg_5_0.id == -7 then
				for iter_5_2 = 1, #xyd.tables.activitySakuraSell:allcount() do
					if iter_5_2 == arg_5_0.tipsFlag then
						arg_5_0.desc1 = xyd.tables.activitySakuraSell:gift_list(iter_5_2)
					end
				end
			elseif arg_5_0.id == -8 then
				for iter_5_3 = 1, xyd.tables.activityGoHiking:tableLength() do
					if iter_5_3 == arg_5_0.tipsFlag then
						arg_5_0.desc1 = xyd.tables.activityGoHiking:getDesc(iter_5_3)
					end
				end
			elseif arg_5_0.id == -9 then
				arg_5_0.desc1 = var_0_1:translation("RANDOM_ITEM")
			elseif arg_5_0.id == -10 then
				arg_5_0.desc1 = var_0_1:translation("LUCKY_COIN_DESC")
			elseif arg_5_0.id == -11 then
				arg_5_0.desc1 = var_0_1:translation("MORE_CARD_DESC")
			elseif arg_5_0.id == -12 then
				for iter_5_4 = 1, #xyd.tables.activityPetGiftTable:allcount() do
					if iter_5_4 == arg_5_0.tipsFlag then
						arg_5_0.desc1 = xyd.tables.activityPetGiftTable:gift_list(iter_5_4)
					end
				end
			elseif arg_5_0.id == -13 then
				arg_5_0.desc1 = var_0_1:translation("RANDOM_3_STAR_HERO")
			elseif arg_5_0.id == -101 then
				arg_5_0.desc1 = var_0_1:translation("SKIN_FRAGMENT_DESC")
			elseif arg_5_0.id == -102 then
				arg_5_0.desc1 = var_0_1:translation("ACTIVITY_CULTIVATE_ITEM_TEXT")
			end

			arg_5_0:nodeByName("name_panel"):setVisible(false)
			arg_5_0:nodeByName("desc_di"):setVisible(false)

			local var_5_3 = {
				size = 20,
				color = cc.c3b(250, 230, 92)
			}
			local var_5_4 = xyd.AssetLoader.get():loadLabel(var_5_3)

			var_5_4:setString(arg_5_0.desc1)
			var_5_4:setMaxLineWidth(290)
			var_5_4:y(160)
			var_5_4:x(40)
			var_5_4:addTo(arg_5_0:nodeByName("backgroud"))
			var_5_4:setAnchorPoint(cc.p(0, 1))
			arg_5_0:nodeByName("jiugong_img"):height(var_5_4:getContentSize().height + 57)

			arg_5_0.tipHeight = var_5_4:getContentSize().height
		else
			arg_5_0.lev = xyd.tables.item:level(arg_5_0.id)
			arg_5_0.tipName = xyd.tables.item:name(arg_5_0.id)
			arg_5_0.desc1 = xyd.tables.item:desc1(arg_5_0.id)
			arg_5_0.desc2 = xyd.tables.item:desc2(arg_5_0.id)

			local var_5_5 = arg_5_0:nodeByName(var_0_0.IMG_ICON)
			local var_5_6 = arg_5_0:createLabel(20, cc.c3b(250, 230, 92))

			var_5_6:y(70)
			xyd.setItemBorder(var_5_5, arg_5_0.id)
			arg_5_0:nodeByName(var_0_0.NAME):setString(arg_5_0.tipName)
			arg_5_0:nodeByName(var_0_0.LEV_TXT):setString(string.format(xyd.tables.translation:translation("NEED_LEV"), arg_5_0.lev))
			arg_5_0:nodeByName(var_0_0.NUM):setString(string.format(xyd.tables.translation:translation("HAS_NUM"), arg_5_0.hasNum))

			if arg_5_0.hasNum == 0 and not arg_5_0.showNum then
				arg_5_0:nodeByName(var_0_0.NUM):setVisible(false)
			end

			local var_5_7 = xyd.tables.item:mana(arg_5_0.id)

			if var_5_7 and var_5_7 ~= "" then
				arg_5_0:nodeByName(var_0_0.PRICE):setVisible(true)
				arg_5_0:nodeByName(var_0_0.COIN_IMG):setVisible(true)
				arg_5_0:nodeByName(var_0_0.PRICE):setString(var_5_7)
			end

			if arg_5_0.desc1 and arg_5_0.desc1 ~= "" then
				local var_5_8

				if arg_5_0.desc2 and arg_5_0.desc2 ~= "" then
					var_5_8 = arg_5_0.desc1 .. "\n" .. "\n" .. arg_5_0.desc2
				else
					var_5_8 = arg_5_0.desc1
				end

				var_5_6:setString(var_5_8)
			else
				arg_5_0:getDescByItemType(var_5_6)
			end

			var_5_6:setAnchorPoint(cc.p(0, 1))
			var_5_6:addTo(arg_5_0:nodeByName(var_0_0.DESC_CONTAINER))

			local var_5_9 = var_5_6:getContentSize().height

			arg_5_0:nodeByName(var_0_0.DESC_DI):height(var_5_9 + 2)

			if not var_5_6:getString() or var_5_6:getString() == "" or var_5_6:getString() == "\n" then
				arg_5_0:nodeByName(var_0_0.DESC_DI):setVisible(false)
			end

			arg_5_0.tipHeight = var_5_9 + 120

			if arg_5_0.itemHeroList and next(arg_5_0.itemHeroList) ~= nil then
				arg_5_0:nodeByName("hero_can_use_txt"):setVisible(true)

				local var_5_10, var_5_11 = arg_5_0:nodeByName(var_0_0.DESC_DI):getPosition()

				arg_5_0:nodeByName("hero_can_use_txt"):setPosition(var_5_10 + 25, var_5_11 - var_5_9 - 12)
				arg_5_0:nodeByName("hero_use_container"):setPosition(var_5_10, var_5_11 - var_5_9 - 44)

				local var_5_12 = math.ceil(#arg_5_0.itemHeroList / 5)

				arg_5_0.listView = cc.ui.UIListView.new({
					viewRect = cc.rect(0, 0, 360, 60 * var_5_12),
					padding_ = {
						top = 0,
						bottom = 0,
						left = 0,
						right = 0
					},
					direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
				})

				arg_5_0.listView:addTo(arg_5_0:nodeByName("hero_use_container"))
				arg_5_0:nodeByName("hero_use_container"):setContentSize(320, 60 * var_5_12)

				for iter_5_5 = 1, var_5_12 do
					local var_5_13 = arg_5_0.listView:newItem()
					local var_5_14 = display.newNode()

					for iter_5_6 = 1, 5 do
						local var_5_15 = (iter_5_5 - 1) * 5 + iter_5_6

						if var_5_15 <= #arg_5_0.itemHeroList then
							local var_5_16 = display.newNode()

							var_5_16:setContentSize(55, 55)
							xyd.setAvatarBorder(arg_5_0.itemHeroList[var_5_15].hero, var_5_16)

							local var_5_17

							if arg_5_0.itemHeroList[var_5_15].plusType == 0 then
								var_5_17 = xyd.AssetLoader.get():loadSprite("windows/common/white_plus.png")
							else
								var_5_17 = xyd.AssetLoader.get():loadSprite("windows/common/green_plus.png")
							end

							var_5_17:setScale(0.5)
							var_5_17:addTo(var_5_16)
							var_5_17:setAnchorPoint(cc.p(0.5, 0.5))
							var_5_17:setPosition(42, 42)
							var_5_14:addChild(var_5_16)
							var_5_16:setPosition((iter_5_6 - 1) * 65, 0)
							var_5_16:setAnchorPoint(cc.p(0, 0))
							var_5_16:ignoreAnchorPointForPosition(false)
						end
					end

					var_5_14:setContentSize(320, 55)
					var_5_14:setAnchorPoint(cc.p(0.5, 0.5))
					var_5_13:addContent(var_5_14)
					var_5_13:setItemSize(320, 55)
					arg_5_0.listView:addItem(var_5_13)
				end

				arg_5_0.listView:reload()

				arg_5_0.tipHeight = var_5_9 + 135 + arg_5_0:nodeByName("hero_can_use_txt"):getContentSize().height + arg_5_0:nodeByName("hero_use_container"):getContentSize().height
			end

			arg_5_0:nodeByName(var_0_0.BG_IMG):height(arg_5_0.tipHeight)
		end
	end

	if arg_5_0.tipsType == var_0_3.SKILL_TIP then
		arg_5_0:nodeByName("name_panel"):setVisible(false)
		arg_5_0:nodeByName("desc_di"):setVisible(false)

		if arg_5_0.has_jiantou == nil then
			arg_5_0:nodeByName("jiantou_img"):setVisible(true)
		elseif arg_5_0.has_jiantou == false then
			arg_5_0:nodeByName("jiantou_img"):setVisible(false)
		end

		arg_5_0:nodeByName("desc_container"):setVisible(false)

		arg_5_0.desc1 = xyd.tables.skill:desc(arg_5_0.id)

		local var_5_18 = {
			size = 22,
			color = cc.c3b(255, 255, 255)
		}
		local var_5_19 = xyd.AssetLoader.get():loadLabel(var_5_18)

		var_5_19:setMaxLineWidth(290)
		var_5_19:setString(arg_5_0.desc1)
		var_5_19:setAnchorPoint(cc.p(0, 1))
		var_5_19:addTo(arg_5_0:nodeByName("skill_panel"))
		var_5_19:setName("skill_desc1")

		local var_5_20 = var_5_19:getContentSize().height
		local var_5_21 = {}
		local var_5_22 = 0
		local var_5_23 = {
			size = 22,
			color = cc.c3b(241, 255, 15)
		}
		local var_5_24 = xyd.AssetLoader.get():loadLabel(var_5_23)

		var_5_24:setMaxLineWidth(290)
		var_5_24:setAnchorPoint(cc.p(0, 1))
		var_5_24:addTo(arg_5_0:nodeByName("skill_panel"))
		var_5_24:setName("skill_desc2")

		if arg_5_0.skillLevel and arg_5_0.skillLevel > 0 and arg_5_0:generateSkillDesc2(arg_5_0.id, arg_5_0.skillLevel) then
			var_5_24:setVisible(true)
			var_5_24:setString(arg_5_0:generateSkillDesc2(arg_5_0.id, arg_5_0.skillLevel))

			var_5_22 = var_5_24:getContentSize().height
		else
			var_5_24:setVisible(false)
		end

		arg_5_0.tipHeight = var_5_20 + var_5_22 + 50

		arg_5_0:setSkillTipPosition(var_5_19, var_5_24, var_5_20, var_5_22)

		local var_5_25 = arg_5_0:nodeByName(var_0_0.BG_IMG)

		var_5_25:height(arg_5_0.tipHeight)

		local var_5_26, var_5_27 = var_5_25:getPosition()

		arg_5_0:nodeByName("jiantou_img"):y(var_5_27 - 55)
	end

	if arg_5_0.tipsType == var_0_3.SIGN_IN_TIP then
		arg_5_0:nodeByName("hero_can_use_txt"):setVisible(false)
		arg_5_0:nodeByName("jiantou_img"):setVisible(false)
		arg_5_0:nodeByName("item_node"):removeAllChildren()

		arg_5_0.desc1 = xyd.tables.item:desc1(arg_5_0.id)
		arg_5_0.desc2 = xyd.tables.item:desc2(arg_5_0.id)

		if xyd.tables.item:type(arg_5_0.id) == -1 then
			arg_5_0.desc1 = xyd.tables.hero:getDes(arg_5_0.id)

			arg_5_0:nodeByName("num_txt"):setVisible(false)
			arg_5_0:nodeByName("price_txt"):setVisible(false)
			arg_5_0:nodeByName("coin_img"):setVisible(false)
			arg_5_0:nodeByName("level_txt"):setString("Lv.1")
		end

		if arg_5_0.id and arg_5_0.id > 0 then
			local var_5_28 = arg_5_0:createLabel(20, cc.c3b(250, 230, 92))

			var_5_28:y(70)
			xyd.setItemBorder(arg_5_0:nodeByName("item_node"), arg_5_0.id)
			arg_5_0:nodeByName("name_txt"):setString(xyd.tables.item:name(arg_5_0.id))

			if xyd.tables.item:level(arg_5_0.id) > 0 and arg_5_0.itemType ~= -1 then
				arg_5_0:nodeByName("level_txt"):setString(string.format(var_0_1:translation("NEED_LEV"), xyd.tables.item:level(arg_5_0.id)))
			end

			arg_5_0:nodeByName("num_txt"):setString(string.format(var_0_1:translation("HAS_NUM"), arg_5_0.hasNum))

			if arg_5_0.hasNum and arg_5_0.hasNum <= 0 then
				arg_5_0:nodeByName("num_txt"):setVisible(false)
			end

			local var_5_29 = xyd.tables.item:mana(arg_5_0.id)

			if var_5_29 and var_5_29 ~= "" and arg_5_0.itemType ~= -1 then
				arg_5_0:nodeByName("price_txt"):setVisible(true)
				arg_5_0:nodeByName("coin_img"):setVisible(true)
				arg_5_0:nodeByName("price_txt"):setString(var_5_29)
			end

			if arg_5_0.desc1 and arg_5_0.desc1 ~= "" then
				local var_5_30 = arg_5_0.desc1

				if arg_5_0.desc2 and arg_5_0.desc2 ~= "" then
					var_5_30 = var_5_30 .. "\n" .. "\n" .. arg_5_0.desc2
				end

				var_5_28:setString(var_5_30)
			else
				arg_5_0:getDescByItemType(var_5_28)
			end

			var_5_28:setAnchorPoint(cc.p(0, 1))
			var_5_28:addTo(arg_5_0:nodeByName("desc_container"))

			local var_5_31 = var_5_28:getContentSize().height

			arg_5_0:nodeByName("desc_di"):height(var_5_31 + 2)

			local var_5_32 = arg_5_0:createLabel(20, cc.c3b(250, 230, 92))

			var_5_32:setString(string.format(var_0_1:translation("SIGN_IN_TIPS"), arg_5_0.signInIdx))
			var_5_32:addTo(arg_5_0:nodeByName("backgroud"))
			var_5_32:setAnchorPoint(cc.p(0, 1))

			local var_5_33, var_5_34 = arg_5_0:nodeByName("desc_di"):getPosition()

			var_5_32:setPosition(var_5_33 + 29, var_5_34 - arg_5_0:nodeByName("desc_di"):getContentSize().height - 12)

			if not var_5_28:getString() or var_5_28:getString() == "" or var_5_28:getString() == "\n" then
				arg_5_0:nodeByName("desc_di"):setVisible(false)
			end

			arg_5_0.tipHeight = var_5_31 + 125 + var_5_32:getContentSize().height

			arg_5_0:nodeByName("jiugong_img"):height(arg_5_0.tipHeight)
		elseif arg_5_0.signInCrystal and arg_5_0.signInCrystal > 0 then
			arg_5_0:nodeByName("name_panel"):setVisible(false)
			arg_5_0:nodeByName("desc_di"):setVisible(false)

			local var_5_35 = {
				size = 20,
				color = cc.c3b(250, 230, 92)
			}
			local var_5_36 = xyd.AssetLoader.get():loadLabel(var_5_35)

			var_5_36:setString(var_0_1:translation("SIGN_IN_DIAMOND"))
			var_5_36:setMaxLineWidth(290)
			var_5_36:y(160)
			var_5_36:x(40)
			var_5_36:addTo(arg_5_0:nodeByName("backgroud"))
			var_5_36:setAnchorPoint(cc.p(0, 1))

			local var_5_37 = xyd.AssetLoader.get():loadLabel(var_5_35)

			var_5_37:setMaxLineWidth(290)
			var_5_37:setString(string.format(var_0_1:translation("SIGN_IN_TIPS"), arg_5_0.signInIdx))
			var_5_37:addTo(arg_5_0:nodeByName("backgroud"))
			var_5_37:setAnchorPoint(cc.p(0, 1))

			local var_5_38, var_5_39 = var_5_36:getPosition()

			var_5_37:setPosition(var_5_38, var_5_39 - var_5_36:getContentSize().height - 12)
			arg_5_0:nodeByName("jiugong_img"):height(var_5_36:getContentSize().height + 60 + var_5_37:getContentSize().height)
		end
	end
end

function var_0_0.setSkillTipPosition(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
	if arg_6_0.tipHeight <= 100 then
		arg_6_0.tipHeight = 110
	end

	local var_6_0 = 0

	if arg_6_4 > 0 and arg_6_3 > 0 then
		var_6_0 = (arg_6_0.tipHeight - arg_6_3 - arg_6_4 - 10) / 2
	else
		var_6_0 = (arg_6_0.tipHeight - arg_6_3 - arg_6_4) / 2
	end

	arg_6_1:y(162 - var_6_0)

	if arg_6_0.skillLevel and arg_6_0.skillLevel > 0 then
		if arg_6_3 > 0 then
			arg_6_2:y(162 - var_6_0 - arg_6_3 - 10)
		else
			arg_6_2:y(162 - var_6_0)
		end
	end
end

function var_0_0.generateSkillDesc2(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = ""
	local var_7_1 = xyd.tables.skill:desc2(arg_7_1)
	local var_7_2 = xyd.tables.skill:descNumInit(arg_7_1)
	local var_7_3 = xyd.tables.skill:descNumStep(arg_7_1)

	for iter_7_0 = 1, #var_7_1 do
		var_7_1[iter_7_0] = string.gsub(var_7_1[iter_7_0], "%%d%%", "%%d@")

		local var_7_4 = tonumber(var_7_2[iter_7_0]) + arg_7_2 * tonumber(var_7_3[iter_7_0])

		if var_7_4 - math.floor(var_7_4) ~= 0 then
			var_7_1[iter_7_0] = string.gsub(var_7_1[iter_7_0], "%%d", "%%.1f")
		end

		if iter_7_0 ~= #var_7_1 then
			var_7_0 = var_7_0 .. string.format(var_7_1[iter_7_0], var_7_4) .. "\n"
		else
			var_7_0 = var_7_0 .. string.format(var_7_1[iter_7_0], var_7_4)
		end

		var_7_0 = string.gsub(var_7_0, "@", "%%")
	end

	return var_7_0
end

function var_0_0.getTipHeight(arg_8_0)
	return arg_8_0.tipHeight
end

function var_0_0.updateTip(arg_9_0, arg_9_1)
	if arg_9_1.iconType ~= arg_9_0.iconType then
		return
	end

	if arg_9_1.iconType == TipType.SKILL_TIP then
		arg_9_0.id = arg_9_0.id
		arg_9_0.skillLevel = arg_9_1.skillLevel

		arg_9_0:reloadTip(TipType.SKILL_TIP)
	end
end

function var_0_0.reloadTip(arg_10_0, arg_10_1)
	if arg_10_1 == TipType.SKILL_TIP then
		local var_10_0 = arg_10_0:nodeByName("skill_panel"):getChildByName("skill_desc1")

		var_10_0:setString(xyd.tables.skill:desc(arg_10_0.id))

		local var_10_1 = var_10_0:getContentSize().height
		local var_10_2 = 0
		local var_10_3 = arg_10_0:nodeByName("skill_panel"):getChildByName("skill_desc2")

		if not arg_10_0.skillLevel or arg_10_0.skillLevel <= 0 then
			var_10_3:setString("")
			var_10_3:setVisible(false)
		else
			var_10_3:setString(arg_10_0:generateSkillDesc2(arg_10_0.id, arg_10_0.skillLevel))

			var_10_2 = var_10_3:getContentSize().height

			var_10_3:setVisible(true)
		end

		arg_10_0.tipHeight = var_10_1 + var_10_2 + 50

		arg_10_0:setSkillTipPosition(var_10_0, var_10_3, var_10_1, var_10_2)

		local var_10_4 = arg_10_0:nodeByName(var_0_0.BG_IMG)

		var_10_4:height(arg_10_0.tipHeight)

		local var_10_5, var_10_6 = var_10_4:getPosition()

		arg_10_0:nodeByName("jiantou_img"):y(var_10_6 - arg_10_0.tipHeight / 2)
	end
end

function var_0_0.getSoundEffect(arg_11_0)
	return xyd.tables.sound:getSound("ui_tips")
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	var_0_0.super:didOpen(arg_12_1)

	if not arg_12_1.noBlock then
		arg_12_0:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
	else
		dump("!!!!!!!!!!")
	end
end

function var_0_0.willClose(arg_13_0, arg_13_1)
	var_0_0.super:willClose(arg_13_1)

	if arg_13_0.tipsType == var_0_3.SIGN_IN_TIP then
		local var_13_0 = xyd.tables.sound:getSound("ui_tips")

		audio.playSound(var_13_0, false)
	end
end

return var_0_0
