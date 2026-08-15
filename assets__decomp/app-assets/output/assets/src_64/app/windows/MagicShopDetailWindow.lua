local var_0_0 = class("MagicShopDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.TipsLayer")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.magicShop_ = xyd.ModelManager.get():loadModel(xyd.ModelType.MAGIC_SHOP)
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.tableID_ = arg_1_2.table_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.runeLayer = arg_4_0:nodeByName("rune_panel")
	arg_4_0.heroLayer = arg_4_0:nodeByName("hero_panel")
	arg_4_0.scrollLayer = arg_4_0:nodeByName("scroll_panel")
	arg_4_0.itemInfo = arg_4_0.magicShop_.items[arg_4_0.tableID_]

	if arg_4_0.itemInfo == nil then
		return
	end

	local var_4_0 = arg_4_0.magicShop_:getItemType(arg_4_0.tableID_)

	if var_4_0 == xyd.ItemType.HERO then
		arg_4_0:layoutHeroLayer()
	elseif var_4_0 == xyd.ItemType.RUNE then
		arg_4_0:layoutRuneLayer()
	elseif var_4_0 == xyd.ItemType.SCROLL then
		arg_4_0:layoutScrollLayer()
	end
end

function var_0_0.layoutHeroLayer(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("skill_tips")

	arg_5_0.skillTips_ = var_0_1:new()

	arg_5_0.skillTips_:setAnchorPoint(cc.p(0, 0))
	arg_5_0.skillTips_:setPosition(cc.p(0, 0))
	var_5_0:addChild(arg_5_0.skillTips_)
	arg_5_0.skillTips_:setVisible(false)
	arg_5_0.runeLayer:setVisible(false)
	arg_5_0.heroLayer:setVisible(true)
	arg_5_0.scrollLayer:setVisible(false)

	arg_5_0.headContainer = arg_5_0:nodeByName("hero_icon_container")
	arg_5_0.heroName = arg_5_0:nodeByName("hero_name")
	arg_5_0.heroClassContainer = arg_5_0:nodeByName("hero_class_container")

	arg_5_0:nodeByName("hero_level"):setString(arg_5_0.itemInfo.item.lev)

	local var_5_1 = arg_5_0.itemInfo.item.table_id

	arg_5_0.heroName:setTextColor(xyd.heroNameColor(xyd.tables.hero:rarity(var_5_1)))

	local var_5_2 = xyd.AssetLoader.get():loadSprite(xyd.heroClassMiddleIconName(xyd.tables.hero:heroClass(var_5_1)))

	var_5_2:setAnchorPoint(cc.p(0, 0))
	arg_5_0.heroClassContainer:addChild(var_5_2)

	if arg_5_0.magicShop_:getItemIcon(arg_5_0.tableID_) then
		local var_5_3 = xyd.AssetLoader:get():loadSprite(arg_5_0.magicShop_:getItemIcon(arg_5_0.tableID_))

		if var_5_3 then
			xyd.displaySpriteOnContainer(var_5_3, arg_5_0.headContainer, true)
		end
	end

	arg_5_0.heroName:setString(arg_5_0.magicShop_:getItemName(arg_5_0.tableID_))
	arg_5_0.heroClassContainer:setPositionX(arg_5_0.heroName:getPositionX() - arg_5_0.heroName:getContentSize().width / 2 - arg_5_0.heroClassContainer:getContentSize().width - 2)

	local var_5_4 = arg_5_0:nodeByName("star_container")

	var_5_4:removeAllChildren()

	for iter_5_0 = 1, arg_5_0.itemInfo.item.star do
		local var_5_5 = xyd.AssetLoader.get():loadSprite(xyd.heroStarBigIconName(xyd.tables.hero:rarity(var_5_1)))
		local var_5_6 = var_5_5:getContentSize().width * (iter_5_0 - 1) + var_5_4:getContentSize().width / 2 - var_5_5:getContentSize().width * arg_5_0.itemInfo.item.star / 2

		var_5_5:setAnchorPoint(cc.p(0, 0))
		var_5_5:setPosition(cc.p(var_5_6, 0))
		var_5_4:addChild(var_5_5)
	end

	arg_5_0:nodeByName("hero_max_level"):setString(xyd.tables.translation:translation("MAXIMUM_LEVEL"))
	arg_5_0:nodeByName("hero_type"):setString(xyd.tables.translation:translation("TYPE"))
	arg_5_0:nodeByName("hero_hp"):setString(xyd.tables.translation:translation("HERO_HP"))
	arg_5_0:nodeByName("hero_attack"):setString(xyd.tables.translation:translation("ATTACK"))
	arg_5_0:nodeByName("hero_defence"):setString(xyd.tables.translation:translation("DEFENCE"))
	arg_5_0:nodeByName("hero_speed"):setString(xyd.tables.translation:translation("SPEED"))
	arg_5_0:nodeByName("hero_max_level_value"):setString(xyd.tables.star:maxLev(arg_5_0.itemInfo.item.star))

	local var_5_7 = xyd.tables.hero:heroType(arg_5_0.tableID_)

	if var_5_7 == xyd.HeroType.ATTACKER then
		arg_5_0:nodeByName("hero_type_value"):setString(xyd.tables.hero:translation("ATTACKER"))
	elseif var_5_7 == xyd.HeroType.DEFENCER then
		arg_5_0:nodeByName("hero_type_value"):setString(xyd.tables.hero:translation("DEFENCER"))
	elseif var_5_7 == xyd.HeroType.PHYSICAL then
		arg_5_0:nodeByName("hero_type_value"):setString(xyd.tables.hero:translation("PHYSICAL"))
	elseif var_5_7 == xyd.HeroType.ASSISTANT then
		arg_5_0:nodeByName("hero_type_value"):setString(xyd.tables.hero:translation("ASSISTANT"))
	end

	arg_5_0:nodeByName("hero_hp_value"):setString(xyd.tables.hero:getAttribute(arg_5_0.tableID_, arg_5_0.itemInfo.item.star, arg_5_0.itemInfo.item.lev, xyd.HeroAttribute.HP_LIMIT))
	arg_5_0:nodeByName("hero_attack_value"):setString(xyd.tables.hero:getAttribute(arg_5_0.tableID_, arg_5_0.itemInfo.item.star, arg_5_0.itemInfo.item.lev, xyd.HeroAttribute.ATTACK))
	arg_5_0:nodeByName("hero_defence_value"):setString(xyd.tables.hero:getAttribute(arg_5_0.tableID_, arg_5_0.itemInfo.item.star, arg_5_0.itemInfo.item.lev, xyd.HeroAttribute.DEFENCE))
	arg_5_0:nodeByName("hero_speed_value"):setString(xyd.tables.hero:getAttribute(arg_5_0.tableID_, arg_5_0.itemInfo.item.star, arg_5_0.itemInfo.item.lev, xyd.HeroAttribute.SPEED))

	arg_5_0.skillButtons_ = {}
	arg_5_0.skillIconContainers_ = {}
	arg_5_0.skillHighlightBgs_ = {}

	for iter_5_1 = 1, 4 do
		local var_5_8 = arg_5_0:nodeByName("skill_" .. tostring(iter_5_1 - 1))

		table.insert(arg_5_0.skillButtons_, var_5_8)

		local var_5_9 = arg_5_0:nodeByName("hero_skill_" .. tostring(iter_5_1 - 1))

		table.insert(arg_5_0.skillIconContainers_, var_5_9)
	end

	for iter_5_2 = 1, #arg_5_0.skillIconContainers_ do
		arg_5_0.skillIconContainers_[iter_5_2]:removeAllChildren()
	end

	local var_5_10 = xyd.tables.hero:skills(var_5_1)

	for iter_5_3 = 1, #var_5_10 do
		arg_5_0.skillButtons_[iter_5_3]:setTouchEnabled(false)

		if var_5_10[iter_5_3] > 0 then
			local var_5_11 = xyd.AssetLoader.get():loadSprite(xyd.tables.skill:icon(var_5_10[iter_5_3]))

			xyd.displaySpriteOnContainer(var_5_11, arg_5_0.skillIconContainers_[iter_5_3], true)
			arg_5_0:setupTips(arg_5_0.skillButtons_[iter_5_3], function()
				arg_5_0:refreshSkillTips(var_5_10[iter_5_3])
				arg_5_0.skillTips_:setVisible(true)
			end, function()
				arg_5_0.skillTips_:setVisible(false)
			end)
			arg_5_0:nodeByName("hero_skill_" .. tostring(iter_5_3 - 1) .. "_1"):setVisible(true)
		else
			arg_5_0:nodeByName("hero_skill_" .. tostring(iter_5_3 - 1) .. "_1"):setVisible(false)
		end
	end
end

function var_0_0.refreshSkillTips(arg_8_0, arg_8_1)
	arg_8_0.skillTips_:setTitle(xyd.tables.skill:name(arg_8_1))
	arg_8_0.skillTips_:clearAllDescText()

	local var_8_0 = xyd.tables.skill:desc(arg_8_1)
	local var_8_1 = xyd.tables.skill:cd(arg_8_1)
	local var_8_2 = xyd.tables.translation

	if var_8_1 > 1 then
		var_8_0 = var_8_0 .. "\n" .. string.format(var_8_2:translation("CD_TIME"), tostring(var_8_1))
	end

	arg_8_0.skillTips_:addDescText(var_8_0)
end

function var_0_0.setupTips(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local function var_9_0(arg_10_0, arg_10_1)
		local var_10_0 = arg_9_1:convertToNodeSpace(arg_10_0:getLocation())
		local var_10_1 = arg_9_1:getContentSize().width
		local var_10_2 = arg_9_1:getContentSize().height
		local var_10_3 = cc.rect(0, 0, var_10_1, var_10_2)

		if cc.rectContainsPoint(var_10_3, var_10_0) then
			arg_9_2()

			return true
		else
			return false
		end
	end

	local function var_9_1(arg_11_0, arg_11_1)
		local var_11_0 = arg_9_1:convertToNodeSpace(arg_11_0:getLocation())
		local var_11_1 = arg_9_1:getContentSize().width
		local var_11_2 = arg_9_1:getContentSize().height
		local var_11_3 = cc.rect(0, 0, var_11_1, var_11_2)

		if cc.rectContainsPoint(var_11_3, var_11_0) then
			arg_9_2()
		else
			arg_9_3()
		end
	end

	local function var_9_2(arg_12_0, arg_12_1)
		arg_9_3()
	end

	local var_9_3 = cc.EventListenerTouchOneByOne:create()

	var_9_3:registerScriptHandler(var_9_0, cc.Handler.EVENT_TOUCH_BEGAN)
	var_9_3:registerScriptHandler(var_9_1, cc.Handler.EVENT_TOUCH_MOVED)
	var_9_3:registerScriptHandler(var_9_2, cc.Handler.EVENT_TOUCH_ENDED)
	arg_9_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_9_3, arg_9_1)
end

function var_0_0.layoutRuneLayer(arg_13_0)
	arg_13_0.runeLayer:setVisible(true)
	arg_13_0.heroLayer:setVisible(false)
	arg_13_0.scrollLayer:setVisible(false)

	arg_13_0.rune_ = import("app.model.Rune").new()

	local var_13_0 = arg_13_0.itemInfo.item

	arg_13_0.rune_:populate(var_13_0)

	local var_13_1 = arg_13_0.rune_:getIcon()

	xyd.displaySpriteOnContainer(var_13_1, arg_13_0:nodeByName("rune_icon_background"), false)

	for iter_13_0 = 1, arg_13_0.rune_:getStar() do
		local var_13_2

		if arg_13_0.rune_:getLevel() == 15 then
			var_13_2 = xyd.AssetLoader.get():loadSprite("star_middle_icon_purle.png")
		else
			var_13_2 = xyd.AssetLoader.get():loadSprite("star_middle_icon_yellow.png")
		end

		var_13_2:setAnchorPoint(0, 1)
		var_13_2:pos((iter_13_0 - 1) * 10, var_13_1:getContentSize().height):addTo(var_13_1, 5)
	end

	arg_13_0:nodeByName("rune_name"):setString(arg_13_0.rune_:getName())
	arg_13_0:nodeByName("rune_name"):setTextColor(arg_13_0.rune_:getColor())

	local function var_13_3(arg_14_0, arg_14_1, arg_14_2)
		arg_14_0:outputToLabel(arg_14_1, arg_14_2)
		arg_14_2:pos(arg_14_1:getPositionX() + arg_14_1:getContentSize().width, arg_14_1:getPositionY())
	end

	var_13_3(arg_13_0.rune_:getMainAttr(), arg_13_0:nodeByName("main_attr"), arg_13_0:nodeByName("main_attr_value"))

	if arg_13_0.rune_:getExtraAttr().attrID_ > 0 then
		var_13_3(arg_13_0.rune_:getExtraAttr(), arg_13_0:nodeByName("extra_attr"), arg_13_0:nodeByName("extra_attr_value"))
	else
		arg_13_0:nodeByName("extra_attr"):setVisible(false)
		arg_13_0:nodeByName("extra_attr_value"):setVisible(false)
	end

	for iter_13_1 = 1, arg_13_0.rune_:getRarity() - 1 do
		var_13_3(arg_13_0.rune_:getBonusAttr(iter_13_1), arg_13_0:nodeByName("bonus_attr_" .. iter_13_1 - 1), arg_13_0:nodeByName("bonus_attr_value_" .. iter_13_1 - 1))
	end

	for iter_13_2 = arg_13_0.rune_:getRarity(), 4 do
		arg_13_0:nodeByName("bonus_attr_" .. iter_13_2 - 1):setVisible(false)
		arg_13_0:nodeByName("bonus_attr_value_" .. iter_13_2 - 1):setVisible(false)
	end

	arg_13_0:nodeByName("runeset_effect"):setString(string.format(xyd.tables.translation:translation("SET_NUM"), xyd.tables.runeset:getSetNum(arg_13_0.rune_:getSetID())) .. " " .. xyd.tables.runeset:getDescription(arg_13_0.rune_:getSetID()))
end

function var_0_0.layoutScrollLayer(arg_15_0)
	arg_15_0.runeLayer:setVisible(false)
	arg_15_0.heroLayer:setVisible(false)
	arg_15_0.scrollLayer:setVisible(true)

	arg_15_0.headContainer = arg_15_0:nodeByName("scroll_image_container")

	if arg_15_0.magicShop_:getItemIcon(arg_15_0.tableID_) then
		local var_15_0 = xyd.AssetLoader:get():loadSprite(arg_15_0.magicShop_:getItemIcon(arg_15_0.tableID_))

		if var_15_0 then
			xyd.displaySpriteOnContainer(var_15_0, arg_15_0.headContainer, true)
		end
	end

	arg_15_0:nodeByName("scroll_name"):setString(arg_15_0.magicShop_:getItemName(arg_15_0.tableID_) .. "x1")

	local var_15_1 = xyd.tables.scroll:desc(arg_15_0.magicShop_:getItemID(arg_15_0.tableID_))

	string.gsub(var_15_1, "|", "\n")
	arg_15_0:nodeByName("scroll_desc"):setString(var_15_1)
end

function var_0_0.buyEvent(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_2 == ccui.TouchEventType.ended then
		if arg_16_0.magicShop_.items[arg_16_0.tableID_] == nil or arg_16_0.magicShop_.items[arg_16_0.tableID_].is_bought == 1 then
			return
		end

		if not arg_16_0.player_.runeBagLoaded_ then
			return
		end

		if arg_16_0.player_:getRuneBag().size_ >= xyd.tables.misc.maxRuneBag then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("BAG_FULL_MESSAGE"), nil, nil, nil, arg_16_0.colorMode)

			return
		end

		if arg_16_0.player_.mana < arg_16_0.itemInfo.price then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("LACK_OF_MANA"), function()
				xyd.WindowManager.get():openWindow("guide_market", {
					type = 1
				})
			end, nil, nil, arg_16_0.colorMode)
		else
			arg_16_0.player_:loadHeros({}, function(arg_18_0)
				if arg_18_0 == xyd.error.OK then
					if #arg_16_0.player_.heros_ >= arg_16_0.player_.maxHeroNumLimit_ and arg_16_0.magicShop_:getItemType(arg_16_0.tableID_) == xyd.ItemType.HERO then
						if arg_16_0.player_.maxHeroNumLimit_ < xyd.tables.heroSlot:maxHeroSlotNum() then
							xyd.WindowManager.get():openWindow("hero_slots_expand", {})
						else
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("MAX_HERO_SLOT_NUM_CANNOT_SUMMON"), nil, nil, nil, arg_16_0.colorMode)
						end
					else
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, string.format(xyd.tables.translation:translation("BUY_PROMOT"), arg_16_0.itemInfo.price, xyd.tables.translation:translation("MANA")), function()
							arg_16_0.magicShop_:buy(arg_16_0.tableID_, function(arg_20_0)
								if arg_20_0 == xyd.error.OK and (not xyd.WindowManager.get():isWindowOpen("shop") or true) then
									xyd.WindowManager.get():closeWindow("shop_item_details")
								end
							end)
						end, nil, nil, arg_16_0.colorMode)
					end
				end
			end)
		end
	end
end

function var_0_0.cancelEvent(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_2 == ccui.TouchEventType.ended then
		xyd.WindowManager.get():closeWindow("shop_item_details")
	end
end

function var_0_0.soundButtonClick(arg_22_0, arg_22_1, arg_22_2)
	var_0_0.super.soundButtonClick(arg_22_0, arg_22_1, arg_22_2)

	local var_22_0 = arg_22_1:getName()

	if var_22_0 == "cancel" then
		arg_22_0:cancelEvent(arg_22_1, arg_22_2)
	elseif var_22_0 == "buy" then
		arg_22_0:buyEvent(arg_22_1, arg_22_2)
	end
end

return var_0_0
