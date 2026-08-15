require("socket")

local var_0_0 = class("HeroSingleViewLayer", function()
	return display.newLayer()
end)
local var_0_1 = import(".HeroInfoLayer")
local var_0_2 = import(".HeroSkillLayer")
local var_0_3 = import(".HeroAwakeLayer")
local var_0_4 = import(".HeroRuneLayer")
local var_0_5 = import("app.common.ui.LayerMultiplex")
local var_0_6 = 1
local var_0_7 = 192
local var_0_8 = class("HeroCell", function()
	return display.newNode()
end)

var_0_8.CellType = {}
var_0_8.CellType.HERO = 1
var_0_8.CellType.EMPTY = 2
var_0_8.CellType.PLUS = 3

function var_0_8.ctor(arg_3_0, arg_3_1)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_single_view_cell.json")

	var_3_0:setPosition(cc.p(0, 0))
	arg_3_0:addChild(var_3_0)

	local var_3_1 = var_3_0:getChildByName("background")

	arg_3_0.sep_ = var_3_0:getChildByName("sep")
	arg_3_0.heroIconContainer_ = var_3_0:getChildByName("hero_icon_container")

	arg_3_0.heroIconContainer_:removeAllChildren()

	arg_3_0.levelBg_ = var_3_0:getChildByName("level_bg")
	arg_3_0.heroLevelLabel_ = var_3_0:getChildByName("Label_level")

	arg_3_0.heroLevelLabel_:enableShadow()

	arg_3_0.starContainer_ = var_3_0:getChildByName("star_container")

	arg_3_0.starContainer_:removeAllChildren()

	arg_3_0.highlightBg_ = var_3_0:getChildByName("highlight_bg")
	arg_3_0.newIcon_ = var_3_0:getChildByName("new")
	arg_3_0.heroButtonContainer_ = var_3_0:getChildByName("hero_button_container")

	local var_3_2 = arg_3_0.heroButtonContainer_:getContentSize().width / 2
	local var_3_3 = arg_3_0.heroButtonContainer_:getContentSize().height / 2

	arg_3_0.repIcon_ = var_3_0:getChildByName("rep")
	arg_3_0.lockIcon_ = var_3_0:getChildByName("lock")
	arg_3_0.heroButton_ = xyd.AssetLoader.get():loadButton("#single_view_hero_button", cc.ui.UIPushButton, nil)

	arg_3_0.heroButton_:align(display.CENTER, var_3_2, var_3_3):addTo(arg_3_0.heroButtonContainer_)
	arg_3_0.heroButton_:setTouchSwallowEnabled(false)

	local var_3_4 = arg_3_0:getCascadeBoundingBox()

	var_3_0:setContentSize(var_3_4.width, var_3_4.height)
	arg_3_0:setContentSize(var_3_4.width, var_3_4.height)
end

function var_0_8.setType(arg_4_0, arg_4_1)
	if arg_4_1 == var_0_8.CellType.HERO then
		arg_4_0.levelBg_:setVisible(true)
		arg_4_0.heroLevelLabel_:setVisible(true)
		arg_4_0.starContainer_:setVisible(true)
		arg_4_0.highlightBg_:setVisible(true)
		arg_4_0.newIcon_:setVisible(true)
		arg_4_0.repIcon_:setVisible(true)
		arg_4_0.lockIcon_:setVisible(true)
	elseif arg_4_1 == var_0_8.CellType.EMPTY then
		arg_4_0:initEmptyCell()

		local var_4_0 = xyd.AssetLoader.get():loadSprite("#cell_hero_icon.png")

		xyd.displaySpriteOnContainer(var_4_0, arg_4_0.heroIconContainer_, false)
	elseif arg_4_1 == var_0_8.CellType.PLUS then
		arg_4_0:initEmptyCell()

		local var_4_1 = xyd.AssetLoader.get():loadSprite("#cell_plus_icon.png")

		xyd.displaySpriteOnContainer(var_4_1, arg_4_0.heroIconContainer_, false)
	end
end

function var_0_8.initEmptyCell(arg_5_0)
	arg_5_0.levelBg_:setVisible(false)
	arg_5_0.heroLevelLabel_:setVisible(false)
	arg_5_0.starContainer_:setVisible(false)
	arg_5_0.highlightBg_:setVisible(false)
	arg_5_0.newIcon_:setVisible(false)
	arg_5_0.repIcon_:setVisible(false)
	arg_5_0.lockIcon_:setVisible(false)
	arg_5_0.heroIconContainer_:removeAllChildren()

	local var_5_0 = xyd.AssetLoader.get():loadSprite("#single_view_empty_cell.png")

	xyd.displaySpriteOnContainer(var_5_0, arg_5_0.heroIconContainer_, false)
end

function var_0_8.setHero(arg_6_0, arg_6_1)
	if arg_6_1 == nil then
		return
	end

	arg_6_0.heroIconContainer_:removeAllChildren()

	local var_6_0 = xyd.AssetLoader.get():loadSprite(arg_6_1:getAvatar())

	xyd.displaySpriteOnContainer(var_6_0, arg_6_0.heroIconContainer_)
	arg_6_0.heroLevelLabel_:setString(string.format("%d", arg_6_1:getLevel()))
	arg_6_0.starContainer_:removeAllChildren()

	for iter_6_0 = 1, arg_6_1:getStar() do
		local var_6_1 = xyd.AssetLoader.get():loadSprite(xyd.heroStarMiddleIconName(arg_6_1:getHeroRarity()))
		local var_6_2 = var_6_1:getContentSize().width * (iter_6_0 - 1) / 2

		var_6_1:setAnchorPoint(cc.p(0, 0))
		var_6_1:setPosition(cc.p(var_6_2, 0))
		arg_6_0.starContainer_:addChild(var_6_1)
	end
end

function var_0_8.setSep(arg_7_0, arg_7_1)
	arg_7_0.sep_:setVisible(arg_7_1)
end

function var_0_8.setRep(arg_8_0, arg_8_1)
	arg_8_0.repIcon_:setVisible(arg_8_1)
end

function var_0_8.setLock(arg_9_0, arg_9_1)
	arg_9_0.lockIcon_:setVisible(arg_9_1)
end

function var_0_8.setNew(arg_10_0, arg_10_1)
	if arg_10_1 then
		arg_10_0.newIcon_:setVisible(true)
		arg_10_0.newIcon_:runAction(xyd.newIconAnimation())
	else
		arg_10_0.newIcon_:setVisible(false)
		arg_10_0.newIcon_:stopAllActions()
	end
end

function var_0_8.setSelected(arg_11_0, arg_11_1)
	if arg_11_1 then
		arg_11_0.highlightBg_:setVisible(true)
		arg_11_0.highlightBg_:runAction(xyd.highlightAnimation())
	else
		arg_11_0.highlightBg_:setVisible(false)
		arg_11_0.highlightBg_:stopAllActions()
	end
end

function var_0_0.ctor(arg_12_0, arg_12_1)
	arg_12_0.selectedIdx_ = 1
	arg_12_0.player_ = arg_12_1.player
	arg_12_0.selectedHeroID_ = arg_12_1.selectedHeroID
	arg_12_0.viewConf_ = arg_12_1.viewConf

	arg_12_0:initLayout()
	arg_12_0:refreshDisplayOption()
end

function var_0_0.playGuide(arg_13_0)
	xyd.WindowManager.get():closeWindow("guide")
	xyd.WindowManager.get():openWindow("guide")

	local var_13_0 = xyd.WindowManager.get():getWindow("guide")
	local var_13_1 = arg_13_0.rightLayer_:getChildByName("Button_rune")
	local var_13_2 = var_13_0:convertToNodeSpace(var_13_1:getParent():convertToWorldSpace(cc.p(var_13_1:getPositionX() + var_13_1:getCascadeBoundingBox().width / 2, var_13_1:getPositionY())))

	var_13_0:setStencil(var_13_1:getCascadeBoundingBox().width, var_13_1:getCascadeBoundingBox().height, var_13_2.x, var_13_2.y, 0)
end

function var_0_0.initLayout(arg_14_0)
	local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_single_view_layer.json")

	var_14_0:setPosition(cc.p(0, 0))
	arg_14_0:addChild(var_14_0)
	arg_14_0:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))

	local var_14_1 = var_14_0:getChildByName("background")

	var_14_1:setContentSize(cc.size(xyd.STAGE_WIDTH, var_14_1:getContentSize().height))

	local var_14_2 = var_14_1:getChildByName("middle_layer")

	arg_14_0.rightLayer_ = var_14_1:getChildByName("right_layer")
	arg_14_0.leftLayer_ = var_14_1:getChildByName("left_layer")

	local var_14_3 = 34
	local var_14_4 = 0.98
	local var_14_5 = var_14_2:getContentSize().width - arg_14_0.rightLayer_:getContentSize().width - (var_14_3 - xyd.STAGE_WIDTH * (1 - var_14_4) / 2)

	arg_14_0.leftLayer_:setContentSize(cc.size(var_14_5, arg_14_0.leftLayer_:getContentSize().height))
	arg_14_0:initLeftLayer()
	arg_14_0:initRightLayer()

	local var_14_6 = var_14_1:getChildByName("bottom_layer")
	local var_14_7 = var_14_6:getChildByName("hero_list_layer")
	local var_14_8 = var_14_6:getChildByName("Button_collect")

	var_14_8:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hero_collect")
		end
	end)

	local var_14_9 = xyd.tables.translation
	local var_14_10 = var_14_6:getChildByName("Label_collect")

	var_14_10:setString(var_14_9:translation("COLLECT"))
	var_14_10:enableShadow()

	local var_14_11 = var_14_6:getChildByName("bottom_bg_layer")
	local var_14_12 = 2
	local var_14_13 = xyd.STAGE_WIDTH - var_14_12 * 2
	local var_14_14 = var_14_11:getContentSize().height
	local var_14_15 = xyd.AssetLoader.get():loadSprite("images/hero_bottom_bg.png")

	var_14_15:setTextureRect(cc.rect(0, 0, var_14_13, var_14_14))
	var_14_15:setAnchorPoint(cc.p(0, 0))
	var_14_15:setPosition(cc.p(0, 0))
	var_14_11:addChild(var_14_15)

	local var_14_16 = 10
	local var_14_17
	local var_14_18 = var_14_7:getContentSize().height
	local var_14_19 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_14_0.player_ == nil or arg_14_0.player_.playerID == var_14_19.playerID then
		var_14_8:setVisible(true)
		var_14_10:setVisible(true)

		var_14_17 = var_14_13 - var_14_8:getContentSize().width - var_14_16 * 2
	else
		var_14_8:setVisible(false)
		var_14_10:setVisible(false)

		var_14_17 = var_14_13 - var_14_16 * 2
	end

	var_14_7:setContentSize(cc.size(var_14_17, var_14_18))

	arg_14_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_14_17, var_14_18),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):onTouch(handler(arg_14_0, arg_14_0.touchListener)):addTo(var_14_7)

	arg_14_0.heroList_:setDelegate(handler(arg_14_0, arg_14_0.heroDelegate))
	xyd.formatAllLabels(arg_14_0, function(arg_16_0)
		arg_16_0:enableShadow()
	end)
end

function var_0_0.initRightLayer(arg_17_0)
	arg_17_0.optionLayers_ = {}

	local var_17_0 = xyd.HeroViewMode.SINGLE_VIEW
	local var_17_1 = var_0_1.new({
		player = arg_17_0.player_,
		selectedHeroID = arg_17_0.selectedHeroID_,
		viewMode = var_17_0
	})

	table.insert(arg_17_0.optionLayers_, var_17_1)

	local var_17_2 = var_0_2.new({
		player = arg_17_0.player_,
		selectedHeroID = arg_17_0.selectedHeroID_,
		viewMode = var_17_0
	})

	table.insert(arg_17_0.optionLayers_, var_17_2)

	local var_17_3 = arg_17_0.rightLayer_:getChildByName("details_layer"):convertToWorldSpace(cc.p(0, 0))
	local var_17_4 = var_0_3.new({
		player = arg_17_0.player_,
		selectedHeroID = arg_17_0.selectedHeroID_,
		viewMode = var_17_0,
		initPos = var_17_3
	})

	table.insert(arg_17_0.optionLayers_, var_17_4)

	local var_17_5 = var_0_4.new({
		player = arg_17_0.player_,
		selectedHeroID = arg_17_0.selectedHeroID_,
		viewConf = arg_17_0.viewConf_,
		viewMode = var_17_0
	})

	table.insert(arg_17_0.optionLayers_, var_17_5)

	for iter_17_0, iter_17_1 in pairs(arg_17_0.optionLayers_) do
		xyd.formatAllLabels(iter_17_1, function(arg_18_0)
			arg_18_0:enableShadow()
		end)
	end

	arg_17_0.detailsLayers_ = var_0_5.new(arg_17_0.optionLayers_)

	arg_17_0.detailsLayers_:setPosition(cc.p(0, 0))
	arg_17_0.rightLayer_:getChildByName("details_layer"):addChild(arg_17_0.detailsLayers_)

	arg_17_0.optionButtons_ = {}

	table.insert(arg_17_0.optionButtons_, arg_17_0.rightLayer_:getChildByName("Button_info"))
	table.insert(arg_17_0.optionButtons_, arg_17_0.rightLayer_:getChildByName("Button_skill"))
	table.insert(arg_17_0.optionButtons_, arg_17_0.rightLayer_:getChildByName("Button_awake"))
	table.insert(arg_17_0.optionButtons_, arg_17_0.rightLayer_:getChildByName("Button_rune"))

	for iter_17_2 = 1, #arg_17_0.optionButtons_ do
		arg_17_0.optionButtons_[iter_17_2]:addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				local var_19_0 = xyd.StoryData.get():getGuideID()
				local var_19_1 = xyd.StoryData.get():getStageID()

				if (var_19_0 < xyd.GuideStoryType.GUIDE_ID_QIANGHUA or var_19_1 == xyd.StoryData.get().SECOND_STAGE and var_19_0 < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN) and arg_19_0:getName() ~= "Button_rune" then
					return
				end

				xyd.playTabButtonSound()
				xyd.WindowManager.get():closeWindow("rune_panel")
				xyd.WindowManager.get():closeWindow("rune_detail_unequipped")

				if iter_17_2 ~= 4 then
					xyd.WindowManager.get():closeWindow("rune_detail_equipped")
				end

				arg_17_0.viewConf_.displayOption = iter_17_2

				arg_17_0:refreshDisplayOption()
				xyd.WindowManager.get():closeWindow("guide")

				if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_ID_QIANGHUA and xyd.StoryData.get().heroGuideStep < 2 then
					xyd.StoryData.get().heroGuideStep = 2

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.GUIDE_HERO_STEP,
						params = {
							step = 2
						}
					})
				elseif xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN and xyd.StoryData.get().heroGuideStep < 6 then
					xyd.StoryData.get().heroGuideStep = 6

					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.GUIDE_HERO_STEP,
						params = {
							step = 6
						}
					})
				end
			end
		end)
	end

	arg_17_0.optionNormalTitles_ = {}

	local var_17_6 = xyd.tables.translation

	infoLabel = arg_17_0.rightLayer_:getChildByName("Label_info")

	infoLabel:setString(var_17_6:translation("INFO"))

	skillLabel = arg_17_0.rightLayer_:getChildByName("Label_skill")

	skillLabel:setString(var_17_6:translation("SKILL"))

	awakeLabel = arg_17_0.rightLayer_:getChildByName("Label_awake")

	awakeLabel:setString(var_17_6:translation("AWAKE"))

	runeLabel = arg_17_0.rightLayer_:getChildByName("Label_rune")

	runeLabel:setString(var_17_6:translation("RUNE"))
	table.insert(arg_17_0.optionNormalTitles_, infoLabel)
	table.insert(arg_17_0.optionNormalTitles_, skillLabel)
	table.insert(arg_17_0.optionNormalTitles_, awakeLabel)
	table.insert(arg_17_0.optionNormalTitles_, runeLabel)

	arg_17_0.optionHighlightTitles_ = {}

	table.insert(arg_17_0.optionHighlightTitles_, arg_17_0.rightLayer_:getChildByName("info"))
	table.insert(arg_17_0.optionHighlightTitles_, arg_17_0.rightLayer_:getChildByName("skill"))
	table.insert(arg_17_0.optionHighlightTitles_, arg_17_0.rightLayer_:getChildByName("awake"))
	table.insert(arg_17_0.optionHighlightTitles_, arg_17_0.rightLayer_:getChildByName("rune"))
end

function var_0_0.initLeftLayer(arg_20_0)
	arg_20_0.heroNameContainer_ = arg_20_0.leftLayer_:getChildByName("hero_name_container")
	arg_20_0.repHeroLayer_ = arg_20_0.leftLayer_:getChildByName("rep_hero_layer")

	arg_20_0.repHeroLayer_:setVisible(false)

	arg_20_0.modelBottom_ = arg_20_0.leftLayer_:getChildByName("model_bottom")
end

function var_0_0.initHeroCell(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_21_2 > #arg_21_0.heros_ then
		if arg_21_2 > var_21_0.maxHeroNumLimit_ then
			arg_21_1:setType(var_0_8.CellType.PLUS)
		else
			arg_21_1:setType(var_0_8.CellType.EMPTY)
		end

		arg_21_1.heroButton_:removeEventListenersByEvent(cc.ui.UIPushButton.CLICKED_EVENT)
		arg_21_1.heroButton_:onButtonClicked(function(arg_22_0)
			local var_22_0 = xyd.StoryData.get():getGuideID()
			local var_22_1 = xyd.StoryData.get():getStageID()

			if var_22_0 < xyd.GuideStoryType.GUIDE_ID_QIANGHUA or var_22_1 == xyd.StoryData.get().SECOND_STAGE and var_22_0 < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN then
				return
			end

			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hero_slots_expand", {})
		end)

		if var_21_0.maxHeroNumLimit_ < xyd.tables.heroSlot:maxHeroSlotNum() then
			arg_21_1.heroButton_:setTouchEnabled(true)
		else
			arg_21_1.heroButton_:setTouchEnabled(false)
		end
	else
		arg_21_1:setSep(arg_21_2 ~= 1)

		local var_21_1 = arg_21_0.heros_[arg_21_2]

		arg_21_1:setType(var_0_8.CellType.HERO)
		arg_21_1:setHero(var_21_1)

		local var_21_2 = arg_21_0.player_ == nil or arg_21_0.player_.playerID == var_21_0.playerID

		if var_21_1:isRep() == 1 then
			arg_21_1:setRep(true)
			arg_21_1:setLock(false)
		else
			arg_21_1:setRep(false)

			if not var_21_2 then
				arg_21_1:setLock(false)
			else
				arg_21_1:setLock(var_21_1:isLock() == 1)
			end
		end

		if var_21_2 then
			if var_21_0:isNewHero(var_21_1:getHeroID()) then
				arg_21_1:setNew(true)
			else
				arg_21_1:setNew(false)
			end
		else
			arg_21_1:setNew(false)
		end

		if arg_21_0.selectedHeroID_.heroID == var_21_1:getHeroID() then
			arg_21_1:setSelected(true)
		else
			arg_21_1:setSelected(false)
		end

		arg_21_1.heroButton_:removeEventListenersByEvent(cc.ui.UIPushButton.CLICKED_EVENT)
		arg_21_1.heroButton_:onButtonClicked(function(arg_23_0)
			local var_23_0 = xyd.StoryData.get():getGuideID()
			local var_23_1 = xyd.StoryData.get():getStageID()

			if var_23_0 < xyd.GuideStoryType.GUIDE_ID_QIANGHUA or var_23_1 == xyd.StoryData.get().SECOND_STAGE and var_23_0 < xyd.GuideStoryType.GUIDE_ID_SECOND_XIANGQIAN then
				return
			end

			print("touch:" .. arg_21_2)
			xyd.playButtonSound()
			arg_21_0:touchHeroCell(arg_21_2)
		end)
		arg_21_1.heroButton_:setTouchEnabled(true)
	end

	arg_21_1:addNodeEventListener(cc.NODE_EVENT, function(arg_24_0)
		if arg_24_0.name == "cleanup" then
			print(string.format("%dth hero cell: %s is removed from view", arg_21_2, tostring(arg_21_1)))

			if arg_21_0.heroCells_[arg_21_2] then
				arg_21_0.heroCells_[arg_21_2] = nil
			end
		end
	end)

	for iter_21_0, iter_21_1 in pairs(arg_21_0.heroCells_) do
		if iter_21_0 ~= arg_21_2 and iter_21_1 == arg_21_1 then
			arg_21_0.heroCells_[iter_21_0] = nil
		end
	end

	arg_21_0.heroCells_[arg_21_2] = arg_21_1
end

function var_0_0.touchHeroCell(arg_25_0, arg_25_1)
	if arg_25_0.selectedHeroID_.heroID ~= arg_25_0.heros_[arg_25_1]:getHeroID() then
		arg_25_0.selectedHeroID_.heroID = arg_25_0.heros_[arg_25_1]:getHeroID()

		arg_25_0:refreshNewHero()
		print("hero tableID:", arg_25_0.heros_[arg_25_1]:getTableID())
		arg_25_0:updateSelectedCell(arg_25_1)

		arg_25_0.selectedIdx_ = arg_25_1
		arg_25_0.viewConf_.rune_slot = nil

		arg_25_0:updateSelectedIdx()
		arg_25_0:refreshOptionLayers(event)
		arg_25_0:refreshDisplayOption()
		arg_25_0:refreshLeftLayer()
	end
end

function var_0_0.heroDelegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_26_0.player_ == nil or arg_26_0.player_.playerID == var_26_0.playerID then
		if var_26_0.maxHeroNumLimit_ < xyd.tables.heroSlot:maxHeroSlotNum() then
			arg_26_0.cellNum_ = math.max(var_26_0.maxHeroNumLimit_, #arg_26_0.heros_) + var_0_6
		else
			arg_26_0.cellNum_ = math.max(var_26_0.maxHeroNumLimit_, #arg_26_0.heros_)
		end
	else
		arg_26_0.cellNum_ = #arg_26_0.heros_
	end

	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		return arg_26_0.cellNum_
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		local var_26_1
		local var_26_2
		local var_26_3 = arg_26_0.heroList_:dequeueItem()

		if not var_26_3 then
			var_26_3 = arg_26_0.heroList_:newItem()
			var_26_2 = var_0_8.new()

			var_26_3:addContent(var_26_2)
		else
			var_26_2 = var_26_3:getContent()
		end

		arg_26_0:initHeroCell(var_26_2, arg_26_3)

		local var_26_4 = var_26_3:getCascadeBoundingBox()

		var_26_3:setItemSize(var_26_4.width, var_26_4.height)
		var_26_2:setContentSize(var_26_4.width, var_26_4.height)

		return var_26_3
	end
end

function var_0_0.touchListener(arg_27_0, arg_27_1)
	if arg_27_1.name == "began" then
		arg_27_0.listViewMoved_ = false
	elseif arg_27_1.name == "moved" then
		arg_27_0.listViewMoved_ = true
	elseif arg_27_1.name == "ended" then
		-- block empty
	end
end

function var_0_0.refresh(arg_28_0, arg_28_1)
	arg_28_0.heroCells_ = {}

	arg_28_0:loadHeros(arg_28_1)
end

function var_0_0.loadHeros(arg_29_0, arg_29_1)
	local var_29_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_29_0.heros_ then
		if arg_29_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW and #arg_29_0.heros_ > 0 then
			arg_29_0:sortHeros()
		end

		arg_29_0:updateSelectedIdx()
		arg_29_0:refreshNewHero()
		arg_29_0:refreshHeroList()
		arg_29_0:refreshOptionLayers(arg_29_1)
		arg_29_0:refreshDisplayOption()
		arg_29_0:refreshLeftLayer()

		return
	else
		local var_29_1

		if arg_29_0.player_ == nil or arg_29_0.player_.playerID == var_29_0.playerID then
			var_29_1 = {}
		else
			var_29_1 = {
				player_id = arg_29_0.player_.playerID
			}
		end

		if not arg_29_0.player_ then
			arg_29_0.player_ = var_29_0
		end

		arg_29_0.player_:loadHeros(var_29_1, function(arg_30_0, arg_30_1)
			if arg_30_0 == xyd.error.OK then
				arg_29_0.heros_ = arg_29_0.player_.heros_

				if #arg_29_0.heros_ > 0 then
					if arg_29_0.viewConf_.viewMode == xyd.HeroViewMode.SINGLE_VIEW and arg_29_0.selectedHeroID_.heroID <= 0 then
						arg_29_0:sortHeros()

						arg_29_0.selectedHeroID_.heroID = arg_29_0.heros_[arg_29_0.selectedIdx_]:getHeroID()
					end

					arg_29_0:updateSelectedIdx()
					arg_29_0:refreshNewHero()
					arg_29_0:refreshHeroList()
					arg_29_0:refreshOptionLayers()
					arg_29_0:refreshDisplayOption()
					arg_29_0:refreshLeftLayer()
				else
					arg_29_0.heroList_:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
				end
			else
				xyd.errorAlert(arg_30_1)
			end
		end)
	end
end

function var_0_0.sortHeros(arg_31_0)
	table.sort(arg_31_0.heros_, xyd.heroSortFunc)
end

function var_0_0.getSelectedHero(arg_32_0)
	return arg_32_0.player_:getHeroByID(arg_32_0.selectedHeroID_.heroID)
end

function var_0_0.updateSelectedCell(arg_33_0, arg_33_1)
	local var_33_0 = socket.gettime() * 1000
	local var_33_1 = arg_33_0.heroCells_[arg_33_0.selectedIdx_]

	if var_33_1 then
		var_33_1:setSelected(false)
	end

	local var_33_2 = arg_33_0.heroCells_[arg_33_1]

	if var_33_2 then
		var_33_2:setSelected(true)

		local var_33_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if arg_33_0.player_ == nil or arg_33_0.player_.playerID == var_33_3.playerID then
			if var_33_3:isNewHero(arg_33_0.selectedHeroID_.heroID) then
				var_33_2:setNew(true)
			else
				var_33_2:setNew(false)
			end
		else
			var_33_2:setNew(false)
		end
	end

	local var_33_4 = socket.gettime() * 1000 - var_33_0

	print("update cell: ", var_33_4)
end

function var_0_0.refreshHeroList(arg_34_0)
	local var_34_0 = socket.gettime() * 1000

	xyd.refreshUIListView(arg_34_0.heroList_)

	local var_34_1 = socket.gettime() * 1000 - var_34_0

	print("refreshHeroList: ", var_34_1)
end

function var_0_0.refreshLeftLayer(arg_35_0)
	arg_35_0:refreshHeroModel()
	arg_35_0:refreshHeroNameLayer()

	if arg_35_0:getSelectedHero():isRep() == 1 then
		arg_35_0.repHeroLayer_:setVisible(true)
	else
		arg_35_0.repHeroLayer_:setVisible(false)
	end
end

function var_0_0.refreshHeroNameLayer(arg_36_0)
	local var_36_0 = arg_36_0:getSelectedHero()

	arg_36_0.heroNameContainer_:removeAllChildren()
	arg_36_0.heroNameContainer_:setContentSize(cc.size(0, 0))

	local var_36_1 = 10
	local var_36_2 = 17
	local var_36_3 = xyd.AssetLoader.get():loadSprite(xyd.heroClassMiddleIconName(var_36_0:getHeroClass()))

	var_36_3:setAnchorPoint(cc.p(0, 0.5))
	var_36_3:setPosition(cc.p(0, var_36_2))
	arg_36_0.heroNameContainer_:addChild(var_36_3)

	local var_36_4 = xyd.AssetLoader.get():loadLabel({
		size = 30,
		text = string.format("Lv.%d %s", var_36_0:getLevel(), var_36_0:getName())
	})

	var_36_4:setTextColor(xyd.heroNameColor(var_36_0:getHeroRarity()))
	var_36_4:enableShadow(xyd.color.FONT_SHADOW_B)

	local var_36_5 = var_36_3:getPositionX() + var_36_3:getContentSize().width + var_36_1

	var_36_4:setAnchorPoint(cc.p(0, 0.5))
	var_36_4:setPosition(cc.p(var_36_5, var_36_2))
	arg_36_0.heroNameContainer_:addChild(var_36_4)

	for iter_36_0 = 1, var_36_0:getStar() do
		local var_36_6 = xyd.AssetLoader.get():loadSprite(xyd.heroStarBigIconName(var_36_0:getHeroRarity()))
		local var_36_7 = var_36_4:getPositionX() + var_36_4:getContentSize().width + var_36_1 + var_36_6:getContentSize().width * (iter_36_0 - 1)

		var_36_6:setAnchorPoint(cc.p(0, 0.5))
		var_36_6:setPosition(cc.p(var_36_7, var_36_2))
		arg_36_0.heroNameContainer_:addChild(var_36_6)
	end

	arg_36_0.heroNameContainer_:setContentSize(arg_36_0.heroNameContainer_:getCascadeBoundingBox())
	arg_36_0.leftLayer_:setContentSize(arg_36_0.leftLayer_:getContentSize())
end

function var_0_0.refreshHeroModel(arg_37_0)
	local var_37_0 = socket.gettime() * 1000

	arg_37_0.modelBottom_:removeAllChildren(true)

	arg_37_0.heroModel_ = xyd.HeroAnimation.new(arg_37_0:getSelectedHero():getTableID(), arg_37_0:getSelectedHero():getModelID(), 0.8)

	arg_37_0.heroModel_:win(function()
		arg_37_0.heroModel_:idle()
	end)

	local var_37_1 = cc.DelayTime:create(6)
	local var_37_2 = cc.CallFunc:create(function()
		arg_37_0.heroModel_:win(function()
			arg_37_0.heroModel_:idle()
		end)
	end)
	local var_37_3 = cc.RepeatForever:create(cc.Sequence:create(var_37_1, var_37_2))

	arg_37_0.heroModel_:runAction(var_37_3)
	arg_37_0.heroModel_:setTimeScale(1)
	arg_37_0.heroModel_:setPosition(cc.p(arg_37_0.modelBottom_:getContentSize().width / 2, arg_37_0.modelBottom_:getContentSize().height / 2))
	arg_37_0.modelBottom_:addChild(arg_37_0.heroModel_)

	local var_37_4 = socket.gettime() * 1000 - var_37_0

	print("refreshHeroModel: ", var_37_4)
end

function var_0_0.refreshDisplayOption(arg_41_0)
	for iter_41_0 = 1, #arg_41_0.optionButtons_ do
		if iter_41_0 == arg_41_0.viewConf_.displayOption then
			arg_41_0.optionButtons_[iter_41_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_41_0.optionNormalTitles_[iter_41_0]:setVisible(false)
			arg_41_0.optionHighlightTitles_[iter_41_0]:setVisible(true)
		else
			arg_41_0.optionButtons_[iter_41_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_41_0.optionNormalTitles_[iter_41_0]:setVisible(true)
			arg_41_0.optionHighlightTitles_[iter_41_0]:setVisible(false)
		end
	end

	arg_41_0.detailsLayers_:switchTo(arg_41_0.viewConf_.displayOption)

	if arg_41_0.optionLayers_[arg_41_0.viewConf_.displayOption].registerEvents then
		arg_41_0.optionLayers_[arg_41_0.viewConf_.displayOption]:registerEvents()
	end
end

function var_0_0.refreshOptionLayers(arg_42_0, arg_42_1)
	for iter_42_0 = 1, #arg_42_0.optionLayers_ do
		if arg_42_0.optionLayers_[iter_42_0].refresh then
			arg_42_0.optionLayers_[iter_42_0]:refresh(arg_42_1)
		end
	end
end

function var_0_0.refreshNewHero(arg_43_0)
	local var_43_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_43_0.player_ == nil or arg_43_0.player_.playerID == var_43_0.playerID then
		var_43_0:deleteNewHero(arg_43_0.selectedHeroID_.heroID)
	end
end

function var_0_0.updateSelectedIdx(arg_44_0)
	for iter_44_0 = 1, #arg_44_0.heros_ do
		if arg_44_0.heros_[iter_44_0]:getHeroID() == arg_44_0.selectedHeroID_.heroID then
			arg_44_0.selectedIdx_ = iter_44_0

			break
		end
	end
end

function var_0_0.getNextHeroID(arg_45_0)
	local var_45_0

	if arg_45_0.selectedIdx_ >= #arg_45_0.heros_ then
		var_45_0 = #arg_45_0.heros_
	else
		var_45_0 = arg_45_0.selectedIdx_
	end

	return arg_45_0.heros_[var_45_0]:getHeroID()
end

return var_0_0
