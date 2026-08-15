local var_0_0 = class("HeroAwakeLayer", function()
	return display.newLayer()
end)
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.TipsLayer")
local var_0_3 = 4
local var_0_4 = 0.05
local var_0_5 = -71
local var_0_6 = 436
local var_0_7 = 432
local var_0_8 = "sound/wake.ogg"

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.player_ = arg_2_1.player
	arg_2_0.selectedHeroID_ = arg_2_1.selectedHeroID
	arg_2_0.viewMode_ = arg_2_1.viewMode
	arg_2_0.initPos_ = arg_2_1.initPos

	arg_2_0:initLayout()
end

function var_0_0.initLayout(arg_3_0)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_awake.json")

	var_3_0:setPosition(cc.p(0, 0))
	arg_3_0:addChild(var_3_0)

	local var_3_1 = var_3_0:getChildByName("background")

	arg_3_0.whiteRarityLayer_ = var_3_1:getChildByName("white_rarity_layer")
	arg_3_0.blueRarityLayer_ = var_3_1:getChildByName("blue_rarity_layer")
	arg_3_0.purleRarityLayer_ = var_3_1:getChildByName("purle_rarity_layer")
	arg_3_0.awakeLayer_ = var_3_1:getChildByName("awake_layer")

	arg_3_0:initAwakeLayer()
	arg_3_0:initBlueRarityLayer()
end

function var_0_0.initAwakeLayer(arg_4_0)
	arg_4_0.awakeDesc1Layers_ = {}

	local var_4_0 = arg_4_0.awakeLayer_:getChildByName("awaken_desc_1_new_skill")
	local var_4_1 = arg_4_0.awakeLayer_:getChildByName("awaken_desc_1_skill_change")
	local var_4_2 = arg_4_0.awakeLayer_:getChildByName("awaken_desc_1_attr")

	table.insert(arg_4_0.awakeDesc1Layers_, var_4_1)
	table.insert(arg_4_0.awakeDesc1Layers_, var_4_0)
	table.insert(arg_4_0.awakeDesc1Layers_, var_4_2)

	arg_4_0.skillTipsPosY = var_4_0:getCascadeBoundingBox().height / 2 + var_4_0:getPositionY()

	local var_4_3 = xyd.tables.translation

	var_4_1:getChildByName("Label_desc_1_skill_change"):setString(var_4_3:translation("SKILL_CHANGE"))
	arg_4_0.awakeLayer_:getChildByName("awaken_desc_2"):getChildByName("Label_desc_2"):setString(var_4_3:translation("AWAKE_DESC_2"))
	arg_4_0.awakeLayer_:getChildByName("awaken_desc_3"):getChildByName("Label_desc_3"):setString(var_4_3:translation("AWAKE_DESC_3"))
end

function var_0_0.initBlueRarityLayer(arg_5_0)
	arg_5_0.essenceButtons_ = {}
	arg_5_0.essenceContainers_ = {}
	arg_5_0.essenceNumLabels_ = {}

	for iter_5_0 = 1, 4 do
		table.insert(arg_5_0.essenceButtons_, arg_5_0.blueRarityLayer_:getChildByName("Button_essence_" .. iter_5_0))
		table.insert(arg_5_0.essenceContainers_, arg_5_0.blueRarityLayer_:getChildByName("essence_" .. iter_5_0 .. "_container"))
		table.insert(arg_5_0.essenceNumLabels_, arg_5_0.blueRarityLayer_:getChildByName("Label_essence_" .. iter_5_0 .. "_num"))
	end

	local var_5_0 = xyd.tables.translation

	arg_5_0.blueRarityLayer_:getChildByName("Label_awake"):setString(var_5_0:translation("AWAKE"))

	arg_5_0.essenceTips_ = var_0_2:new()

	arg_5_0.essenceTips_:setAnchorPoint(cc.p(0, 0))
	arg_5_0.essenceTips_:setPosition(cc.p(0, 0))
	arg_5_0.blueRarityLayer_:getChildByName("essence_tips"):addChild(arg_5_0.essenceTips_)
	arg_5_0.essenceTips_:setVisible(false)
end

function var_0_0.refresh(arg_6_0)
	local var_6_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_6_0.selectedHeroID_.heroID == INVALID_HERO_ID then
		return
	end

	local var_6_1
	local var_6_2 = arg_6_0.player_ == nil or arg_6_0.player_.playerID == var_6_0.playerID

	if var_6_2 then
		var_6_1 = var_6_0:getHeroByID(arg_6_0.selectedHeroID_.heroID)
	else
		var_6_1 = arg_6_0.player_:getHeroByID(arg_6_0.selectedHeroID_.heroID)
	end

	if var_6_1 then
		local var_6_3 = var_6_1:getHeroRarity()

		if var_6_3 == xyd.HeroRarity.WHITE then
			arg_6_0.whiteRarityLayer_:setVisible(true)
			arg_6_0.awakeLayer_:setVisible(false)
			arg_6_0.blueRarityLayer_:setVisible(false)
			arg_6_0.purleRarityLayer_:setVisible(false)
			arg_6_0:refreshWhiteRarityLayer(var_6_1)
		elseif var_6_3 == xyd.HeroRarity.BLUE then
			arg_6_0.whiteRarityLayer_:setVisible(false)
			arg_6_0.blueRarityLayer_:setVisible(var_6_2)
			arg_6_0.purleRarityLayer_:setVisible(false)
			arg_6_0.awakeLayer_:setVisible(true)
			arg_6_0:refreshAwakeLayer(var_6_1)

			if var_6_2 then
				arg_6_0:loadEssences(var_6_1)
			end
		elseif var_6_3 == xyd.HeroRarity.PURLE then
			arg_6_0.whiteRarityLayer_:setVisible(false)
			arg_6_0.awakeLayer_:setVisible(true)
			arg_6_0.blueRarityLayer_:setVisible(false)
			arg_6_0.purleRarityLayer_:setVisible(true)
			arg_6_0:refreshAwakeLayer(var_6_1)
		end
	end
end

function var_0_0.loadEssences(arg_7_0, arg_7_1)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_7_0:loadEssences(function(arg_8_0)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.essences_ = var_7_0.essences_

			arg_7_0:refreshBlueRarityLayer(arg_7_1)
		end
	end)
end

function var_0_0.displayHero(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	arg_9_3:removeAllChildren()
	print("HeroAwakeLayer heroTableID:", arg_9_1:getTableID())

	local var_9_0 = xyd.AssetLoader.get():loadSprite(arg_9_1:getAvatar())

	xyd.displaySpriteOnContainer(var_9_0, arg_9_3)
	arg_9_4:removeAllChildren()

	for iter_9_0 = 1, arg_9_1:getStar() do
		local var_9_1 = xyd.AssetLoader.get():loadSprite(xyd.heroStarMiddleIconName(arg_9_1:getHeroRarity()))
		local var_9_2 = var_9_1:getContentSize().width * (iter_9_0 - 1) / 2

		var_9_1:setAnchorPoint(cc.p(0, 0))
		var_9_1:setPosition(cc.p(var_9_2, 0))
		arg_9_4:addChild(var_9_1)
	end

	arg_9_2:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hero_info", {
				partner_table_id = arg_9_1:getTableID(),
				star = arg_9_1:getStar(),
				level = arg_9_1:getMaxLevel()
			})
		end
	end)
end

function var_0_0.refreshWhiteRarityLayer(arg_11_0, arg_11_1)
	arg_11_0:displayHero(arg_11_1, arg_11_0.whiteRarityLayer_:getChildByName("Button_white_hero"), arg_11_0.whiteRarityLayer_:getChildByName("white_hero_container"), arg_11_0.whiteRarityLayer_:getChildByName("white_star_container"))
end

function var_0_0.refreshAwakeLayer(arg_12_0, arg_12_1)
	local var_12_0
	local var_12_1

	if arg_12_1:getHeroRarity() == xyd.HeroRarity.BLUE then
		var_12_0 = arg_12_1:getTableID()
		var_12_1 = xyd.tables.hero:awakenID(var_12_0)
	elseif arg_12_1:getHeroRarity() == xyd.HeroRarity.PURLE then
		var_12_1 = arg_12_1:getTableID()
		var_12_0 = xyd.tables.hero:unawakenID(var_12_1)
	else
		return
	end

	local var_12_2 = var_0_1.new()

	var_12_2.tableID_ = var_12_0
	var_12_2.star_ = arg_12_1:getStar()

	local var_12_3 = var_0_1.new()

	var_12_3.tableID_ = var_12_1
	var_12_3.star_ = arg_12_1:getStar()

	arg_12_0:displayHero(var_12_2, arg_12_0.awakeLayer_:getChildByName("Button_blue_hero"), arg_12_0.awakeLayer_:getChildByName("blue_hero_container"), arg_12_0.awakeLayer_:getChildByName("blue_star_container"))
	arg_12_0:displayHero(var_12_3, arg_12_0.awakeLayer_:getChildByName("Button_purle_hero"), arg_12_0.awakeLayer_:getChildByName("purle_hero_container"), arg_12_0.awakeLayer_:getChildByName("purle_star_container"))

	if arg_12_0.skillTips_ then
		arg_12_0.skillTips_:removeFromParent(true)

		arg_12_0.skillTips_ = nil
	end

	arg_12_0:refreshAwakeDesc1Layer(var_12_0)
end

function var_0_0.refreshAwakeDesc1Layer(arg_13_0, arg_13_1)
	local function var_13_0(arg_14_0, arg_14_1)
		arg_14_0:setVisible(arg_14_1)

		local var_14_0 = arg_14_0:getChildren()
		local var_14_1 = arg_14_0:getChildrenCount()

		if var_14_1 < 1 then
			return
		end

		for iter_14_0 = 1, var_14_1 do
			var_13_0(var_14_0[iter_14_0], arg_14_1)
		end
	end

	local var_13_1 = xyd.tables.hero:awakeType(arg_13_1)

	for iter_13_0 = 1, #arg_13_0.awakeDesc1Layers_ do
		if iter_13_0 == var_13_1 then
			arg_13_0.awakeDesc1Layers_[iter_13_0]:setVisible(true)
			xyd.setWidgetVisible(arg_13_0.awakeDesc1Layers_[iter_13_0], true)
		else
			arg_13_0.awakeDesc1Layers_[iter_13_0]:setVisible(false)
			xyd.setWidgetVisible(arg_13_0.awakeDesc1Layers_[iter_13_0], false)
		end
	end

	if var_13_1 == xyd.HeroAwakeType.NEW_SKILL then
		arg_13_0:refreshNewSkillLayer(arg_13_1)
	elseif var_13_1 == xyd.HeroAwakeType.SKILL_CHANGE then
		arg_13_0:refreshSkillChangeLayer(arg_13_1)
	elseif var_13_1 == xyd.HeroAwakeType.ATTR_UPGRADE then
		arg_13_0:refreshAttrUpgradeLayer(arg_13_1)
	end
end

function var_0_0.initSkillTips(arg_15_0)
	if arg_15_0.skillTips_ then
		arg_15_0.skillTips_:removeFromParent(true)

		arg_15_0.skillTips_ = nil
	end

	arg_15_0.skillTips_ = var_0_2:new()

	local var_15_0 = xyd.WindowManager.get():getWindow("hero")
	local var_15_1 = cc.p(xyd.STAGE_WIDTH - var_0_6, var_0_7)

	arg_15_0.skillTips_:ignoreAnchorPointForPosition(false)
	arg_15_0.skillTips_:setAnchorPoint(cc.p(1, 0.5))
	arg_15_0.skillTips_:setPosition(var_15_1)
	var_15_0:addChild(arg_15_0.skillTips_)
	arg_15_0.skillTips_:setLocalZOrder(1000)
	arg_15_0.skillTips_:setVisible(false)
end

function var_0_0.refreshSkillTips(arg_16_0, arg_16_1)
	arg_16_0.skillTips_:setTitle(xyd.tables.skill:name(arg_16_1))
	arg_16_0.skillTips_:clearAllDescText()
	arg_16_0.skillTips_:addDescText(xyd.tables.skill:desc(arg_16_1))
end

function var_0_0.refreshNewSkillLayer(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.awakeDesc1Layers_[xyd.HeroAwakeType.NEW_SKILL]
	local var_17_1 = var_17_0:getChildByName("new_skill_container")
	local var_17_2 = var_17_0:getChildByName("Button_new_skill")
	local var_17_3 = xyd.tables.hero:newSkill(arg_17_1)

	if not arg_17_0.skillTips_ then
		arg_17_0:initSkillTips()
	end

	var_17_2:setTouchEnabled(false)
	arg_17_0:setupTips(var_17_2, function()
		arg_17_0.skillTips_:setVisible(true)
		print("newSkillLayer skillID:", var_17_3)
		arg_17_0:refreshSkillTips(var_17_3)
	end, function()
		arg_17_0.skillTips_:setVisible(false)
	end)

	local var_17_4 = xyd.AssetLoader.get():loadSprite(xyd.tables.skill:icon(var_17_3))

	xyd.displaySpriteOnContainer(var_17_4, var_17_1)

	local var_17_5 = xyd.tables.translation

	if xyd.tables.skill:isLeaderSkill(var_17_3) == 1 then
		var_17_0:getChildByName("Label_desc_1_new_skill"):setString(var_17_5:translation("OBTAIN_LEADER_SKILL"))
	else
		var_17_0:getChildByName("Label_desc_1_new_skill"):setString(var_17_5:translation("OBTAIN_NEW_SKILL"))
	end
end

function var_0_0.refreshSkillChangeLayer(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_0.awakeDesc1Layers_[xyd.HeroAwakeType.SKILL_CHANGE]
	local var_20_1 = var_20_0:getChildByName("origin_skill_container")
	local var_20_2 = var_20_0:getChildByName("Button_origin_skill")
	local var_20_3 = var_20_0:getChildByName("update_skill_container")
	local var_20_4 = var_20_0:getChildByName("Button_update_skill")
	local var_20_5 = xyd.tables.hero:originSkill(arg_20_1)
	local var_20_6 = xyd.AssetLoader.get():loadSprite(xyd.tables.skill:icon(var_20_5))

	xyd.displaySpriteOnContainer(var_20_6, var_20_1)

	local var_20_7 = xyd.tables.hero:updateSkill(arg_20_1)
	local var_20_8 = xyd.AssetLoader.get():loadSprite(xyd.tables.skill:icon(var_20_7))

	xyd.displaySpriteOnContainer(var_20_8, var_20_3)

	if not arg_20_0.skillTips_ then
		arg_20_0:initSkillTips()
	end

	var_20_2:setTouchEnabled(false)
	arg_20_0:setupTips(var_20_2, function()
		arg_20_0.skillTips_:setVisible(true)
		print("skillChangeLayer skillID:", var_20_5)
		arg_20_0:refreshSkillTips(var_20_5)
	end, function()
		arg_20_0.skillTips_:setVisible(false)
	end)
	var_20_4:setTouchEnabled(false)
	arg_20_0:setupTips(var_20_4, function()
		arg_20_0.skillTips_:setVisible(true)
		print("skillChangeLayer skillID:", var_20_7)
		arg_20_0:refreshSkillTips(var_20_7)
	end, function()
		arg_20_0.skillTips_:setVisible(false)
	end)
end

function var_0_0.refreshAttrUpgradeLayer(arg_25_0, arg_25_1)
	local var_25_0 = arg_25_0.awakeDesc1Layers_[xyd.HeroAwakeType.ATTR_UPGRADE]
	local var_25_1 = xyd.tables.hero:attrID(arg_25_1)
	local var_25_2 = xyd.tables.hero:attrUpgradeNum(arg_25_1)
	local var_25_3 = xyd.tables.rune:getAttrName(var_25_1)
	local var_25_4 = xyd.tables.rune:isRatio(var_25_1)
	local var_25_5

	if var_25_4 then
		var_25_5 = string.format("%d%%", var_25_2 * 100 / xyd.DECIMAL_BASE)
	else
		var_25_5 = tostring(var_25_2)
	end

	local var_25_6 = xyd.tables.translation

	var_25_0:getChildByName("Label_desc_1_attr"):setString(string.format(var_25_6:translation("ATTR_UPGRADE_PROMPT"), var_25_3, var_25_5))
end

function var_0_0.refreshEssenceTips(arg_26_0, arg_26_1)
	arg_26_0.essenceTips_:setTitle(xyd.tables.essence:name(arg_26_1))
	arg_26_0.essenceTips_:clearAllDescText()
	arg_26_0.essenceTips_:addDescText(xyd.tables.essence:desc(arg_26_1))
end

function var_0_0.refreshBlueRarityLayer(arg_27_0, arg_27_1)
	local var_27_0 = xyd.tables.hero:essences(arg_27_1:getTableID())

	if var_27_0 == nil then
		print("no requireEssences: ", arg_27_1:getTableID())
	end

	for iter_27_0 = 1, #arg_27_0.essenceButtons_ do
		arg_27_0.essenceButtons_[iter_27_0]:setTouchEnabled(false)

		if iter_27_0 <= #var_27_0 then
			arg_27_0.essenceButtons_[iter_27_0]:setVisible(true)
			arg_27_0.essenceContainers_[iter_27_0]:setVisible(true)
			arg_27_0.essenceNumLabels_[iter_27_0]:setVisible(true)

			local var_27_1 = var_27_0[iter_27_0].id

			arg_27_0:setupTips(arg_27_0.essenceButtons_[iter_27_0], function()
				arg_27_0.essenceTips_:setVisible(true)
				arg_27_0:refreshEssenceTips(var_27_1)
			end, function()
				arg_27_0.essenceTips_:setVisible(false)
			end)

			local var_27_2 = xyd.AssetLoader.get():loadSprite(xyd.tables.essence:icon(var_27_1))

			xyd.displaySpriteOnContainer(var_27_2, arg_27_0.essenceContainers_[iter_27_0])

			local var_27_3 = arg_27_0.essences_[var_27_1] or 0
			local var_27_4 = var_27_0[iter_27_0].num

			arg_27_0.essenceNumLabels_[iter_27_0]:setString(string.format("%d/%d", var_27_3, var_27_4))

			if var_27_3 < var_27_4 then
				arg_27_0.essenceNumLabels_[iter_27_0]:setTextColor(cc.c4b(255, 0, 0, 255))
			else
				arg_27_0.essenceNumLabels_[iter_27_0]:setTextColor(xyd.color.WHITE)
			end
		else
			arg_27_0.essenceButtons_[iter_27_0]:setVisible(false)
			arg_27_0.essenceContainers_[iter_27_0]:setVisible(false)
			arg_27_0.essenceNumLabels_[iter_27_0]:setVisible(false)
		end
	end

	local var_27_5 = xyd.tables.translation

	arg_27_0.blueRarityLayer_:getChildByName("Button_awake"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_27_5:translation("CONFIRM_AWAKE"), function()
				if arg_27_0:canAwake(arg_27_1) then
					arg_27_0:awake(arg_27_1)
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_27_5:translation("AWAKE_CONDITIONS_UNSATISFIED"))
				end
			end, nil, 0)
		end
	end)
end

function var_0_0.setupTips(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	local function var_32_0(arg_33_0, arg_33_1)
		local var_33_0 = arg_32_1:convertToNodeSpace(arg_33_0:getLocation())
		local var_33_1 = arg_32_1:getContentSize().width
		local var_33_2 = arg_32_1:getContentSize().height
		local var_33_3 = cc.rect(0, 0, var_33_1, var_33_2)

		if arg_32_1:isVisible() and cc.rectContainsPoint(var_33_3, var_33_0) then
			print("onTouchBegan")
			arg_32_2()

			return true
		else
			return false
		end
	end

	local function var_32_1(arg_34_0, arg_34_1)
		local var_34_0 = arg_32_1:convertToNodeSpace(arg_34_0:getLocation())
		local var_34_1 = arg_32_1:getContentSize().width
		local var_34_2 = arg_32_1:getContentSize().height
		local var_34_3 = cc.rect(0, 0, var_34_1, var_34_2)

		if cc.rectContainsPoint(var_34_3, var_34_0) then
			print("onTouchMoved")
			arg_32_2()
		else
			arg_32_3()
		end
	end

	local function var_32_2(arg_35_0, arg_35_1)
		arg_32_3()
	end

	local var_32_3 = cc.EventListenerTouchOneByOne:create()

	var_32_3:registerScriptHandler(var_32_0, cc.Handler.EVENT_TOUCH_BEGAN)
	var_32_3:registerScriptHandler(var_32_1, cc.Handler.EVENT_TOUCH_MOVED)
	var_32_3:registerScriptHandler(var_32_2, cc.Handler.EVENT_TOUCH_ENDED)

	local var_32_4 = arg_32_0:getEventDispatcher()

	var_32_4:removeEventListenersForTarget(arg_32_1)
	var_32_4:addEventListenerWithSceneGraphPriority(var_32_3, arg_32_1)
end

function var_0_0.canAwake(arg_36_0, arg_36_1)
	local var_36_0 = true
	local var_36_1 = xyd.tables.hero:essences(arg_36_1:getTableID())

	for iter_36_0, iter_36_1 in pairs(var_36_1) do
		local var_36_2 = arg_36_0.essences_[iter_36_1.id]

		if var_36_2 == nil or var_36_2 < iter_36_1.num then
			var_36_0 = false
		end
	end

	return var_36_0
end

function var_0_0.awake(arg_37_0, arg_37_1)
	local function var_37_0()
		audio.stopMusic()
		arg_37_0:restoreMusic()
		arg_37_0.animationBg_:removeFromParent(true)

		arg_37_0.awakeComplete_ = nil

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.HERO_UPDATE_COMPLETE
		})
	end

	local function var_37_1()
		arg_37_0:playAwakeResultAnimation(var_37_0)
	end

	arg_37_0.awakeComplete_ = nil

	arg_37_0:prepareAnimationBg(var_37_0)
	arg_37_0:playAwakeAnimation(var_37_1)

	local var_37_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_37_3 = {
		partner_id = arg_37_1:getHeroID()
	}

	var_37_2:awakeHero(var_37_3, function(arg_40_0)
		if arg_40_0 == xyd.error.OK then
			arg_37_0.awakeComplete_ = true
		else
			arg_37_0.awakeComplete_ = nil

			local var_40_0 = xyd.tables.translation:translation("NETWORK_DELAY")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_40_0, function()
				audio.stopMusic()
				arg_37_0:restoreMusic()
				arg_37_0.animationBg_:removeFromParent(true)
			end)
		end
	end)
end

function var_0_0.prepareAnimationBg(arg_42_0, arg_42_1)
	local var_42_0 = 1000

	arg_42_0.animationBg_ = display.newColorLayer(xyd.color.BLACK)

	arg_42_0.animationBg_:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
	arg_42_0.animationBg_:setPosition(cc.p(0, 0))
	xyd.WindowManager.get():getWindow("hero"):addChild(arg_42_0.animationBg_, var_42_0)

	local function var_42_1(arg_43_0, arg_43_1)
		if arg_42_0.awakeComplete_ then
			return true
		else
			return false
		end
	end

	local function var_42_2(arg_44_0, arg_44_1)
		if arg_42_0.awakeComplete_ then
			arg_42_1()
		end
	end

	local var_42_3 = cc.EventListenerTouchOneByOne:create()

	var_42_3:setSwallowTouches(true)
	var_42_3:registerScriptHandler(var_42_1, cc.Handler.EVENT_TOUCH_BEGAN)
	var_42_3:registerScriptHandler(var_42_2, cc.Handler.EVENT_TOUCH_ENDED)
	arg_42_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_42_3, arg_42_0.animationBg_)
end

function var_0_0.playAwakeAnimation(arg_45_0, arg_45_1)
	audio.playMusic(var_0_8, false)

	local var_45_0 = xyd.AssetLoader.get():loadAnimation("juexing/")

	arg_45_0.animationSprite_ = display.newSprite():pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2):addTo(arg_45_0.animationBg_)

	arg_45_0.animationSprite_:setScale(var_0_3, var_0_3)

	local var_45_1 = cc.Animate:create(var_45_0)
	local var_45_2 = cc.CallFunc:create(function()
		if arg_45_0.awakeComplete_ then
			arg_45_0.animationSprite_:stopAllActions()
			arg_45_1()
		else
			audio.playMusic(var_0_8, false)
		end
	end)

	arg_45_0.animationSprite_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_45_1, var_45_2)))
end

function var_0_0.playAwakeResultAnimation(arg_47_0, arg_47_1)
	if not arg_47_0.awakeComplete_ then
		return
	end

	local var_47_0 = xyd.AssetLoader.get():loadSprite("images/awake_result_bg.png")

	var_47_0:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2))
	arg_47_0.animationBg_:addChild(var_47_0)

	local var_47_1 = xyd.AssetLoader.get():loadSprite("images/awake_light.png")

	var_47_1:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2))

	local var_47_2 = math.sqrt(xyd.STAGE_WIDTH * xyd.STAGE_WIDTH + xyd.STAGE_HEIGHT * xyd.STAGE_HEIGHT) / var_47_1:getContentSize().width

	var_47_1:setScale(var_47_2)
	arg_47_0.animationBg_:addChild(var_47_1)
	var_47_1:runAction(cc.RepeatForever:create(cc.RotateBy:create(4, 360)))

	local var_47_3 = cc.ParticleSystemQuad:create("atlases/awake_star.plist")

	var_47_3:setTexture(cc.Director:getInstance():getTextureCache():addImage("atlases/awake_star.png"))
	var_47_3:setAutoRemoveOnFinish(true)
	var_47_3:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2))

	local var_47_4 = cc.ParticleBatchNode:createWithTexture(var_47_3:getTexture())

	var_47_4:addChild(var_47_3)
	arg_47_0.animationBg_:addChild(var_47_4)

	local var_47_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getHeroByID(arg_47_0.selectedHeroID_.heroID)
	local var_47_6 = xyd.HeroAnimation.new(var_47_5:getTableID(), var_47_5:getModelID(), 1)

	var_47_6:win(function()
		var_47_6:idle()
	end)

	local var_47_7 = 200

	var_47_6:setPosition(cc.p(xyd.STAGE_WIDTH / 2, var_47_7))
	arg_47_0.animationBg_:addChild(var_47_6)

	local var_47_8 = 4
	local var_47_9 = cc.DelayTime:create(var_47_8)
	local var_47_10 = cc.CallFunc:create(function()
		arg_47_1()
	end)

	arg_47_0.animationSprite_:runAction(cc.Sequence:create(var_47_9, var_47_10))
end

function var_0_0.restoreMusic(arg_50_0)
	if not audio.isMusicPlaying() then
		audio.playMusic("sound/main.ogg", true)
	end
end

return var_0_0
