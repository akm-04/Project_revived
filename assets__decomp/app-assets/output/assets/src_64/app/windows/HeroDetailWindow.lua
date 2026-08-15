local var_0_0 = class("HeroDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.TipsLayer")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.AssetLoader.get()

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("max_level"):setString(var_0_2:translation("MAXIMUM_LEVEL"))
	arg_3_0:nodeByName("max_level_value"):setString("")
	arg_3_0:nodeByName("type"):setString(var_0_2:translation("TYPE"))
	arg_3_0:nodeByName("type_value"):setString("")
	arg_3_0:nodeByName("hp"):setString(var_0_2:translation("HP"))
	arg_3_0:nodeByName("hp_value"):setString("")
	arg_3_0:nodeByName("atk"):setString(var_0_2:translation("ATTACK"))
	arg_3_0:nodeByName("atk_value"):setString("")
	arg_3_0:nodeByName("def"):setString(var_0_2:translation("DEFENCE"))
	arg_3_0:nodeByName("def_value"):setString("")
	arg_3_0:nodeByName("spd"):setString(var_0_2:translation("SPEED"))
	arg_3_0:nodeByName("spd_value"):setString("")
	arg_3_0:nodeByName("name_label"):setString("")
	arg_3_0:nodeByName("lev"):setString("")
	arg_3_0:nodeByName("ok_label"):setString(var_0_2:translation("OK"))

	arg_3_0.menu_ = import("app.common.ui.TipsMenu").new()

	arg_3_0.menu_:pos(0, 0):addTo(arg_3_0)
	arg_3_0:nodeByName("ok_button"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			audio.playSound("sound/button.ogg", false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.setHero(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	arg_5_3 = arg_5_3 or 1

	if type(arg_5_1) == "number" then
		arg_5_0.hero_ = import("app.model.Hero").new()

		arg_5_0.hero_:initCollected(arg_5_1, arg_5_2, arg_5_3)
	else
		arg_5_0.hero_ = arg_5_1
	end

	arg_5_0:refresh()
end

function var_0_0.refresh(arg_6_0)
	local var_6_0 = xyd.AssetLoader.get():loadSprite(arg_6_0.hero_:getAvatar())

	var_6_0:setScale(74 / var_6_0:getContentSize().width, 74 / var_6_0:getContentSize().height)
	xyd.displaySpriteOnContainer(var_6_0, arg_6_0:nodeByName("hero_border"), false)
	arg_6_0:nodeByName("lev"):setString(arg_6_0.hero_.lev)
	arg_6_0:nodeByName("class_container"):removeAllChildren()

	local var_6_1 = var_0_3:loadSprite(xyd.heroClassMiddleIconName(arg_6_0.hero_:getHeroClass()))

	xyd.displaySpriteOnContainer(var_6_1, arg_6_0:nodeByName("class_container"), false)
	arg_6_0:nodeByName("name_label"):setString(arg_6_0.hero_:getName())
	arg_6_0:nodeByName("name_label"):setTextColor(xyd.heroNameColor(arg_6_0.hero_:getHeroRarity()))
	arg_6_0:nodeByName("star_panel"):removeAllChildren()

	for iter_6_0 = 1, arg_6_0.hero_:getStar() do
		local var_6_2 = var_0_3:loadSprite(xyd.heroStarBigIconName(arg_6_0.hero_:getHeroRarity()))

		var_6_2:setAnchorPoint(0, 0)
		var_6_2:pos((iter_6_0 - 1) * 36, 0):addTo(arg_6_0:nodeByName("star_panel"))
	end

	arg_6_0:nodeByName("type_value"):setString(xyd.heroTypeName(arg_6_0.hero_:getHeroType()))
	arg_6_0:nodeByName("max_level_value"):setString(arg_6_0.hero_:getMaxLevel())
	arg_6_0:nodeByName("hp_value"):setString(string.format("%.0f", arg_6_0.hero_:getAttribute(xyd.HeroAttribute.HP_LIMIT)))
	arg_6_0:nodeByName("atk_value"):setString(string.format("%.0f", arg_6_0.hero_:getAttribute(xyd.HeroAttribute.ATTACK)))
	arg_6_0:nodeByName("def_value"):setString(string.format("%.0f", arg_6_0.hero_:getAttribute(xyd.HeroAttribute.DEFENCE)))
	arg_6_0:nodeByName("spd_value"):setString(string.format("%.0f", arg_6_0.hero_:getAttribute(xyd.HeroAttribute.SPEED)))
	arg_6_0.menu_:clear()

	local var_6_3 = arg_6_0.hero_:getSkillIDs()

	for iter_6_1 = 1, 4 do
		local var_6_4 = arg_6_0:nodeByName("skill_" .. iter_6_1 - 1)

		var_6_4:removeAllChildren()

		if var_6_3[iter_6_1] > 0 then
			local var_6_5 = var_0_3:loadSprite(xyd.tables.skill:icon(var_6_3[iter_6_1]))

			xyd.displaySpriteOnContainer(var_6_5, var_6_4, false)

			local var_6_6 = var_0_3:loadSprite("images/skill_highlight_bg.png")
			local var_6_7 = display.newNode()

			var_6_7:setContentSize(var_6_6:getContentSize())

			local var_6_8 = cc.MenuItemSprite:create(var_6_7, var_6_6)

			function var_6_8.getTitle()
				return xyd.tables.skill:name(var_6_3[iter_6_1])
			end

			function var_6_8.getDesc()
				local var_8_0 = xyd.tables.skill:desc(var_6_3[iter_6_1])
				local var_8_1 = xyd.tables.skill:cd(var_6_3[iter_6_1])

				if var_8_1 > 1 then
					var_8_0 = var_8_0 .. "\n" .. string.format(var_0_2:translation("CD_TIME"), tostring(var_8_1))
				end

				return var_8_0
			end

			var_6_8:setAnchorPoint(0.5, 0.5)
			var_6_8:ignoreAnchorPointForPosition(false)
			var_6_8:pos(var_6_4:getPositionX(), var_6_4:getPositionY())
			arg_6_0.menu_:addItem(var_6_8)
		else
			local var_6_9 = var_0_3:loadSprite("images/skill_button-disabled.png")

			xyd.displaySpriteOnContainer(var_6_9, var_6_4, false)
		end
	end

	local var_6_10 = import("app.common.ui.TipsLayer").new()

	var_6_10:setAnchorPoint(0, 0)
	var_6_10:pos(80, 220)
	var_6_10:setWidth(369)
	arg_6_0.menu_:setTipsLayer(var_6_10)
end

function var_0_0.didOpen(arg_9_0)
	arg_9_0:addBlockLayer(cc.c4b(0, 0, 0, 128))
end

return var_0_0
