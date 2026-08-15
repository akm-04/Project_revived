local var_0_0 = class("HeroSkillLayer", function()
	return display.newLayer()
end)
local var_0_1 = -1

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.player_ = arg_2_1.player
	arg_2_0.selectedHeroID_ = arg_2_1.selectedHeroID
	arg_2_0.viewMode_ = arg_2_1.viewMode
	arg_2_0.selectedIdx_ = 1

	arg_2_0:initLayout()
	arg_2_0:refresh()
end

function var_0_0.initLayout(arg_3_0)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_skill.json")

	var_3_0:setPosition(cc.p(0, 0))
	arg_3_0:addChild(var_3_0)

	local var_3_1 = var_3_0:getChildByName("background")

	arg_3_0.topLayer_ = var_3_1:getChildByName("top_layer")
	arg_3_0.bottomLayer_ = var_3_1:getChildByName("bottom_layer")

	arg_3_0:initTopLayer()
	arg_3_0:initBottomLayer()
end

function var_0_0.initTopLayer(arg_4_0)
	arg_4_0.skillButtons_ = {}
	arg_4_0.skillIconContainers_ = {}
	arg_4_0.highlightBgs_ = {}
	arg_4_0.levelLabels_ = {}

	for iter_4_0 = 1, 4 do
		local var_4_0 = arg_4_0.topLayer_:getChildByName("Button_skill_" .. iter_4_0)
		local var_4_1 = arg_4_0.topLayer_:getChildByName("skill_" .. iter_4_0 .. "_icon_container")
		local var_4_2 = arg_4_0.topLayer_:getChildByName("skill_" .. iter_4_0 .. "_highlight")
		local var_4_3 = arg_4_0.topLayer_:getChildByName("Label_skill_" .. iter_4_0 .. "_lv")

		if var_4_0 then
			table.insert(arg_4_0.skillButtons_, var_4_0)
			var_4_0:setBright(false)
			var_4_0:setTouchEnabled(false)
		end

		if var_4_1 then
			table.insert(arg_4_0.skillIconContainers_, var_4_1)
		end

		if var_4_2 then
			table.insert(arg_4_0.highlightBgs_, var_4_2)
			var_4_2:setVisible(false)
		end

		if var_4_3 then
			table.insert(arg_4_0.levelLabels_, var_4_3)
		end
	end
end

function var_0_0.initBottomLayer(arg_5_0)
	arg_5_0.skillTitleLabel_ = arg_5_0.bottomLayer_:getChildByName("Label_skill_title")
	arg_5_0.skillDescScrollView_ = arg_5_0.bottomLayer_:getChildByName("ScrollView_skill_desc")
	arg_5_0.originSkillDescHeight_ = arg_5_0.skillDescScrollView_:getContentSize().height
end

function var_0_0.refresh(arg_6_0)
	arg_6_0.selectedIdx_ = 1

	arg_6_0:refreshHero()
end

function var_0_0.refreshHero(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_7_0.selectedHeroID_.heroID == var_0_1 then
		return
	end

	local var_7_1

	if arg_7_0.player_ == nil or arg_7_0.player_.playerID == var_7_0.playerID then
		var_7_1 = var_7_0:getHeroByID(arg_7_0.selectedHeroID_.heroID)
	else
		var_7_1 = arg_7_0.player_:getHeroByID(arg_7_0.selectedHeroID_.heroID)
	end

	if var_7_1 then
		arg_7_0:refreshSkillButtons(var_7_1)
		arg_7_0:refreshBottomLayer(var_7_1)
	end
end

function var_0_0.refreshSkillButtons(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1:getSkillIDs()
	local var_8_1 = arg_8_1:getSkillLevels()

	for iter_8_0 = 1, #var_8_0 do
		local var_8_2 = var_8_0[iter_8_0]

		arg_8_0.skillIconContainers_[iter_8_0]:removeAllChildren()

		if var_8_2 > 0 then
			local var_8_3 = xyd.AssetLoader.get():loadSprite(xyd.tables.skill:icon(var_8_2))

			xyd.displaySpriteOnContainer(var_8_3, arg_8_0.skillIconContainers_[iter_8_0])
			arg_8_0.skillIconContainers_[iter_8_0]:setVisible(true)
			arg_8_0.skillButtons_[iter_8_0]:setTouchEnabled(true)
			arg_8_0.skillButtons_[iter_8_0]:setBright(true)
			arg_8_0.skillButtons_[iter_8_0]:addTouchEventListener(function(arg_9_0, arg_9_1)
				if arg_9_1 == ccui.TouchEventType.ended then
					xyd.playButtonSound()

					arg_8_0.selectedIdx_ = iter_8_0

					arg_8_0:refreshHero()
				end
			end)

			if xyd.tables.skill:isPassiveSkill(var_8_2) then
				local var_8_4 = xyd.AssetLoader.get():loadAnimation("a_0", true)
				local var_8_5 = display.newSprite()
				local var_8_6 = cc.Animate:create(var_8_4)

				var_8_5:runAction(cc.RepeatForever:create(var_8_6))
				var_8_5:setContentSize(arg_8_0.skillIconContainers_[iter_8_0]:getContentSize())
				var_8_5:setScale(0.7)
				xyd.displaySpriteOnContainer(var_8_5, arg_8_0.skillIconContainers_[iter_8_0], false)
			end

			if arg_8_0.levelLabels_[iter_8_0] then
				arg_8_0.levelLabels_[iter_8_0]:setString(tostring(var_8_1[iter_8_0]))
			end
		else
			arg_8_0.skillButtons_[iter_8_0]:setTouchEnabled(false)
			arg_8_0.skillButtons_[iter_8_0]:setBright(false)
		end

		if iter_8_0 == arg_8_0.selectedIdx_ and var_8_2 > 0 then
			arg_8_0.highlightBgs_[iter_8_0]:setVisible(true)

			local var_8_7 = 0.8
			local var_8_8 = cc.FadeTo:create(var_8_7, 128)
			local var_8_9 = cc.FadeTo:create(var_8_7, 255)
			local var_8_10 = cc.DelayTime:create(var_8_7)

			arg_8_0.highlightBgs_[iter_8_0]:runAction(cc.RepeatForever:create(cc.Sequence:create(var_8_8, var_8_9, var_8_10)))
		else
			arg_8_0.highlightBgs_[iter_8_0]:setVisible(false)
			arg_8_0.highlightBgs_[iter_8_0]:stopAllActions()
		end
	end
end

function var_0_0.refreshBottomLayer(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1:getBaseSkillIDs()[arg_10_0.selectedIdx_]
	local var_10_1 = arg_10_1:getSkillLevels()[arg_10_0.selectedIdx_]
	local var_10_2 = arg_10_1:getSkillIDs()[arg_10_0.selectedIdx_]

	arg_10_0.skillTitleLabel_:setString(xyd.tables.skill:name(var_10_0))
	arg_10_0.skillDescScrollView_:removeAllChildren()

	local var_10_3 = var_10_0
	local var_10_4 = xyd.tables.translation
	local var_10_5 = {}
	local var_10_6 = 1
	local var_10_7 = 0
	local var_10_8 = 20

	while var_10_3 ~= 0 do
		local var_10_9 = xyd.tables.skill:desc(var_10_3)

		if var_10_6 > 1 then
			var_10_9 = "Lv." .. var_10_6 .. " " .. var_10_9
		elseif xyd.tables.skill:cd(var_10_2) > 1 then
			var_10_9 = var_10_9 .. "\n" .. string.format(var_10_4:translation("CD_TIME"), xyd.tables.skill:cd(var_10_2))
		end

		local var_10_10 = xyd.AssetLoader.get():loadLabel({
			size = 24,
			text = var_10_9
		})

		if var_10_6 == 1 then
			var_10_10:setTextColor(xyd.color.FONT_E)
			var_10_10:enableShadow(xyd.color.FONT_SHADOW_E)
		elseif var_10_6 <= var_10_1 then
			var_10_10:setTextColor(xyd.color.FONT_F)
			var_10_10:enableShadow(xyd.color.FONT_SHADOW_F)
		else
			var_10_10:setTextColor(xyd.color.FONT_L)
		end

		var_10_10:setWidth(arg_10_0.skillDescScrollView_:getContentSize().width - var_10_8)
		var_10_10:setLineBreakWithoutSpace(true)

		var_10_7 = var_10_7 + var_10_10:getContentSize().height

		table.insert(var_10_5, var_10_10)

		var_10_3 = xyd.tables.skill:nextLevelSkill(var_10_3)
		var_10_6 = var_10_6 + 1
	end

	local var_10_11 = 17
	local var_10_12 = var_10_7 + var_10_11
	local var_10_13 = arg_10_0.skillDescScrollView_:getContentSize().width

	arg_10_0.skillDescScrollView_:setInnerContainerSize(cc.size(var_10_13, math.max(arg_10_0.originSkillDescHeight_, var_10_12)))

	local var_10_14 = math.max(arg_10_0.originSkillDescHeight_, var_10_12)

	for iter_10_0 = 1, #var_10_5 do
		var_10_5[iter_10_0]:setAnchorPoint(cc.p(0, 1))
		var_10_5[iter_10_0]:setPosition(cc.p(0, var_10_14))
		arg_10_0.skillDescScrollView_:addChild(var_10_5[iter_10_0])

		var_10_14 = var_10_14 - var_10_5[iter_10_0]:getContentSize().height

		if iter_10_0 == 1 then
			var_10_14 = var_10_14 - var_10_11
		end
	end

	arg_10_0.skillDescScrollView_:jumpToTop()
	arg_10_0.skillDescScrollView_:setClippingEnabled(true)
end

return var_0_0
