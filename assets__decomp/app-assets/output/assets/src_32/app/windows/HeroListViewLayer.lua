require("socket")

local var_0_0 = class("HeroListViewLayer", function()
	return display.newLayer()
end)
local var_0_1 = import(".HeroInfoLayer")
local var_0_2 = import(".HeroSkillLayer")
local var_0_3 = import(".HeroAwakeLayer")
local var_0_4 = import(".HeroRuneLayer")
local var_0_5 = import("app.common.ui.LayerMultiplex")
local var_0_6 = 125

local function var_0_7(arg_2_0, arg_2_1)
	if arg_2_0:getLevel() ~= arg_2_1:getLevel() then
		return arg_2_0:getLevel() > arg_2_1:getLevel()
	elseif arg_2_0:getStar() ~= arg_2_1:getStar() then
		return arg_2_0:getStar() > arg_2_1:getStar()
	elseif arg_2_0:getTableID() ~= arg_2_1:getTableID() then
		return arg_2_0:getTableID() > arg_2_1:getTableID()
	elseif arg_2_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) ~= arg_2_1:getAttribute(xyd.HeroAttribute.HP_LIMIT) then
		return arg_2_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) > arg_2_1:getAttribute(xyd.HeroAttribute.HP_LIMIT)
	else
		return arg_2_0:getHeroID() < arg_2_1:getHeroID()
	end
end

local function var_0_8(arg_3_0, arg_3_1)
	if arg_3_0:getStar() ~= arg_3_1:getStar() then
		return arg_3_0:getStar() > arg_3_1:getStar()
	elseif arg_3_0:getLevel() ~= arg_3_1:getLevel() then
		return arg_3_0:getLevel() > arg_3_1:getLevel()
	elseif arg_3_0:getTableID() ~= arg_3_1:getTableID() then
		return arg_3_0:getTableID() > arg_3_1:getTableID()
	elseif arg_3_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) ~= arg_3_1:getAttribute(xyd.HeroAttribute.HP_LIMIT) then
		return arg_3_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) > arg_3_1:getAttribute(xyd.HeroAttribute.HP_LIMIT)
	else
		return arg_3_0:getHeroID() < arg_3_1:getHeroID()
	end
end

local function var_0_9(arg_4_0, arg_4_1)
	if arg_4_0:getHeroClass() ~= arg_4_1:getHeroClass() then
		return arg_4_0:getHeroClass() < arg_4_1:getHeroClass()
	elseif arg_4_0:getLevel() ~= arg_4_1:getLevel() then
		return arg_4_0:getLevel() > arg_4_1:getLevel()
	elseif arg_4_0:getTableID() ~= arg_4_1:getTableID() then
		return arg_4_0:getTableID() > arg_4_1:getTableID()
	elseif arg_4_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) ~= arg_4_1:getAttribute(xyd.HeroAttribute.HP_LIMIT) then
		return arg_4_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) > arg_4_1:getAttribute(xyd.HeroAttribute.HP_LIMIT)
	else
		return arg_4_0:getHeroID() < arg_4_1:getHeroID()
	end
end

local function var_0_10(arg_5_0, arg_5_1)
	if arg_5_0:getFormationTime() ~= arg_5_1:getFormationTime() then
		return arg_5_0:getFormationTime() > arg_5_1:getFormationTime()
	elseif arg_5_0:getLevel() ~= arg_5_1:getLevel() then
		return arg_5_0:getLevel() > arg_5_1:getLevel()
	elseif arg_5_0:getTableID() ~= arg_5_1:getTableID() then
		return arg_5_0:getTableID() > arg_5_1:getTableID()
	elseif arg_5_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) ~= arg_5_1:getAttribute(xyd.HeroAttribute.HP_LIMIT) then
		return arg_5_0:getAttribute(xyd.HeroAttribute.HP_LIMIT) > arg_5_1:getAttribute(xyd.HeroAttribute.HP_LIMIT)
	else
		return arg_5_0:getHeroID() < arg_5_1:getHeroID()
	end
end

local var_0_11 = class("HeroCell", function()
	return display.newNode()
end)

function var_0_11.initEmptyCell(arg_7_0)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list_view_empty_cell.json")

	var_7_0:setPosition(cc.p(0, 0))
	arg_7_0:addChild(var_7_0)

	arg_7_0.heroButtonContainer_ = var_7_0:getChildByName("hero_button_container")
	arg_7_0.heroButton_ = xyd.AssetLoader.get():loadButton("#list_view_empty_button", cc.ui.UIPushButton, nil)

	xyd.displaySpriteOnContainer(arg_7_0.heroButton_, arg_7_0.heroButtonContainer_, true)
	arg_7_0.heroButton_:setTouchSwallowEnabled(false)

	local var_7_1 = arg_7_0:getCascadeBoundingBox()

	var_7_0:setContentSize(var_7_1.width, var_7_1.height)
	arg_7_0:setContentSize(var_7_1.width, var_7_1.height)
end

function var_0_11.initHeroCell(arg_8_0)
	local var_8_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list_view_cell.json")
	local var_8_1 = var_8_0:getCascadeBoundingBox()

	var_8_0:setContentSize(var_8_1.width, var_8_1.height)
	arg_8_0:setContentSize(var_8_1.width, var_8_1.height)
	var_8_0:setPosition(cc.p(0, 0))
	arg_8_0:addChild(var_8_0)

	local var_8_2 = var_8_0:getChildByName("background")

	arg_8_0.heroIconContainer_ = var_8_0:getChildByName("hero_icon_container")

	arg_8_0.heroIconContainer_:setVisible(true)
	arg_8_0.heroIconContainer_:removeAllChildren()

	arg_8_0.levelBg_ = var_8_0:getChildByName("level_bg")
	arg_8_0.heroLevelLabel_ = var_8_0:getChildByName("Label_level")

	arg_8_0.heroLevelLabel_:enableShadow()

	arg_8_0.nameLabel_ = var_8_0:getChildByName("Label_name")

	arg_8_0.nameLabel_:enableShadow()

	arg_8_0.starContainer_ = var_8_0:getChildByName("star_container")

	arg_8_0.starContainer_:removeAllChildren()

	arg_8_0.highlightBg_ = var_8_0:getChildByName("highlight_bg")
	arg_8_0.newIcon_ = var_8_0:getChildByName("new")
	arg_8_0.heroButtonContainer_ = var_8_0:getChildByName("hero_button_container")

	local var_8_3 = arg_8_0.heroButtonContainer_:getContentSize().width / 2
	local var_8_4 = arg_8_0.heroButtonContainer_:getContentSize().height / 2

	arg_8_0.repIcon_ = var_8_0:getChildByName("rep")
	arg_8_0.lockIcon_ = var_8_0:getChildByName("lock")
	arg_8_0.heroButton_ = xyd.AssetLoader.get():loadButton("#list_view_hero_button", cc.ui.UIPushButton, nil):align(display.CENTER, var_8_3, var_8_4):addTo(arg_8_0.heroButtonContainer_)

	arg_8_0.heroButton_:setTouchSwallowEnabled(false)

	local var_8_5 = arg_8_0:getCascadeBoundingBox()

	var_8_0:setContentSize(var_8_5.width, var_8_5.height)
	arg_8_0:setContentSize(var_8_5.width, var_8_5.height)
end

function var_0_11.ctor(arg_9_0, arg_9_1)
	arg_9_0:setHero(arg_9_1)
end

function var_0_11.setHero(arg_10_0, arg_10_1)
	if not arg_10_1 then
		arg_10_0:initEmptyCell()
	else
		arg_10_0:initHeroCell()
		arg_10_0.heroIconContainer_:removeAllChildren()

		local var_10_0 = xyd.AssetLoader.get():loadSprite(arg_10_1:getAvatar())

		xyd.displaySpriteOnContainer(var_10_0, arg_10_0.heroIconContainer_)
		arg_10_0.heroLevelLabel_:setString(string.format("%d", arg_10_1:getLevel()))
		arg_10_0.nameLabel_:setString(arg_10_1:getName())
		arg_10_0.starContainer_:removeAllChildren()

		for iter_10_0 = 1, arg_10_1:getStar() do
			local var_10_1 = xyd.AssetLoader.get():loadSprite(xyd.heroStarMiddleIconName(arg_10_1:getHeroRarity()))
			local var_10_2 = var_10_1:getContentSize().width * (iter_10_0 - 1) / 2

			var_10_1:setAnchorPoint(cc.p(0, 0))
			var_10_1:setPosition(cc.p(var_10_2, 0))
			arg_10_0.starContainer_:addChild(var_10_1)
		end
	end
end

function var_0_11.setRep(arg_11_0, arg_11_1)
	arg_11_0.repIcon_:setVisible(arg_11_1)
end

function var_0_11.setLock(arg_12_0, arg_12_1)
	arg_12_0.lockIcon_:setVisible(arg_12_1)
end

function var_0_11.setNew(arg_13_0, arg_13_1)
	if arg_13_1 then
		arg_13_0.newIcon_:setVisible(true)
		arg_13_0.newIcon_:runAction(xyd.newIconAnimation())
	else
		arg_13_0.newIcon_:setVisible(false)
		arg_13_0.newIcon_:stopAllActions()
	end
end

function var_0_11.setSelected(arg_14_0, arg_14_1)
	if arg_14_1 then
		arg_14_0.highlightBg_:setVisible(true)
		arg_14_0.highlightBg_:runAction(xyd.highlightAnimation())
	else
		arg_14_0.highlightBg_:setVisible(false)
		arg_14_0.highlightBg_:stopAllActions()
	end
end

function var_0_0.ctor(arg_15_0, arg_15_1)
	arg_15_0.selectedIdx_ = 1
	arg_15_0.player_ = arg_15_1.player
	arg_15_0.selectedHeroID_ = arg_15_1.selectedHeroID
	arg_15_0.viewConf_ = arg_15_1.viewConf

	arg_15_0:initLayout()
	arg_15_0:refreshDisplayOption()

	arg_15_0.sortFuncs_ = {}

	table.insert(arg_15_0.sortFuncs_, var_0_7)
	table.insert(arg_15_0.sortFuncs_, var_0_8)
	table.insert(arg_15_0.sortFuncs_, var_0_9)
	table.insert(arg_15_0.sortFuncs_, var_0_10)
	print("HeroListViewLayer sortType:", arg_15_0.viewConf_.sortType)

	if not arg_15_0.viewConf_.sortType then
		arg_15_0.viewConf_.sortType = xyd.HeroDataSortType.BY_LEVEL
	end

	arg_15_0:refreshSortType()
end

function var_0_0.initLayout(arg_16_0)
	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_list_view_layer.json")

	var_16_0:setPosition(cc.p(0, 0))
	arg_16_0:addChild(var_16_0)
	arg_16_0:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))

	local var_16_1 = var_16_0:getChildByName("background")

	var_16_1:setContentSize(cc.size(xyd.STAGE_WIDTH, var_16_1:getContentSize().height))

	arg_16_0.rightLayer_ = var_16_1:getChildByName("right_layer")
	arg_16_0.leftLayer_ = var_16_1:getChildByName("left_layer")

	local var_16_2 = 14
	local var_16_3 = 34
	local var_16_4 = xyd.STAGE_WIDTH - var_16_2 - var_16_3 - arg_16_0.rightLayer_:getContentSize().width

	arg_16_0.leftLayer_:setContentSize(cc.size(var_16_4, arg_16_0.leftLayer_:getContentSize().height))

	arg_16_0.bottomLayer_ = var_16_1:getChildByName("bottom_layer")

	arg_16_0:initRightLayer()
	arg_16_0:initBottomLayer()

	local var_16_5 = arg_16_0.leftLayer_:getChildByName("hero_list_layer")
	local var_16_6 = var_16_5:getContentSize().width
	local var_16_7 = var_16_5:getContentSize().height

	arg_16_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_16_6, var_16_7),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):onTouch(handler(arg_16_0, arg_16_0.touchListener)):addTo(var_16_5)

	arg_16_0.heroList_:setDelegate(handler(arg_16_0, arg_16_0.heroDelegate))

	arg_16_0.heroListColNum_ = math.floor(var_16_6 / var_0_6)

	xyd.formatAllLabels(arg_16_0, function(arg_17_0)
		arg_17_0:enableShadow()
	end)
end

function var_0_0.initRightLayer(arg_18_0)
	arg_18_0.optionLayers_ = {}

	local var_18_0 = xyd.HeroViewMode.LIST_VIEW
	local var_18_1 = var_0_1.new({
		player = arg_18_0.player_,
		selectedHeroID = arg_18_0.selectedHeroID_,
		viewMode = var_18_0
	})

	table.insert(arg_18_0.optionLayers_, var_18_1)

	local var_18_2 = var_0_2.new({
		player = arg_18_0.player_,
		selectedHeroID = arg_18_0.selectedHeroID_,
		viewMode = var_18_0
	})

	table.insert(arg_18_0.optionLayers_, var_18_2)

	local var_18_3 = arg_18_0.rightLayer_:getChildByName("details_layer"):convertToWorldSpace(cc.p(0, 0))
	local var_18_4 = var_0_3.new({
		player = arg_18_0.player_,
		selectedHeroID = arg_18_0.selectedHeroID_,
		viewMode = var_18_0,
		initPos = var_18_3
	})

	table.insert(arg_18_0.optionLayers_, var_18_4)

	local var_18_5 = var_0_4.new({
		player = arg_18_0.player_,
		selectedHeroID = arg_18_0.selectedHeroID_,
		viewConf = arg_18_0.viewConf_,
		viewMode = var_18_0
	})

	table.insert(arg_18_0.optionLayers_, var_18_5)

	for iter_18_0, iter_18_1 in pairs(arg_18_0.optionLayers_) do
		xyd.formatAllLabels(iter_18_1, function(arg_19_0)
			arg_19_0:enableShadow()
		end)
	end

	arg_18_0.detailsLayers_ = var_0_5.new(arg_18_0.optionLayers_)

	arg_18_0.detailsLayers_:setPosition(cc.p(0, 0))
	arg_18_0.rightLayer_:getChildByName("details_layer"):addChild(arg_18_0.detailsLayers_)

	arg_18_0.optionButtons_ = {}

	table.insert(arg_18_0.optionButtons_, arg_18_0.rightLayer_:getChildByName("Button_info"))
	table.insert(arg_18_0.optionButtons_, arg_18_0.rightLayer_:getChildByName("Button_skill"))
	table.insert(arg_18_0.optionButtons_, arg_18_0.rightLayer_:getChildByName("Button_awake"))
	table.insert(arg_18_0.optionButtons_, arg_18_0.rightLayer_:getChildByName("Button_rune"))

	for iter_18_2 = 1, #arg_18_0.optionButtons_ do
		arg_18_0.optionButtons_[iter_18_2]:addTouchEventListener(function(arg_20_0, arg_20_1)
			if arg_20_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()
				xyd.WindowManager.get():closeWindow("rune_panel")
				xyd.WindowManager.get():closeWindow("rune_detail_unequipped")

				if iter_18_2 ~= 4 then
					xyd.WindowManager.get():closeWindow("rune_detail_equipped")
				end

				arg_18_0.viewConf_.displayOption = iter_18_2

				arg_18_0:refreshDisplayOption()
			end
		end)
	end

	arg_18_0.optionNormalTitles_ = {}

	local var_18_6 = xyd.tables.translation

	infoLabel = arg_18_0.rightLayer_:getChildByName("Label_info")

	infoLabel:setString(var_18_6:translation("INFO"))

	skillLabel = arg_18_0.rightLayer_:getChildByName("Label_skill")

	skillLabel:setString(var_18_6:translation("SKILL"))

	awakeLabel = arg_18_0.rightLayer_:getChildByName("Label_awake")

	awakeLabel:setString(var_18_6:translation("AWAKE"))

	runeLabel = arg_18_0.rightLayer_:getChildByName("Label_rune")

	runeLabel:setString(var_18_6:translation("RUNE"))
	table.insert(arg_18_0.optionNormalTitles_, infoLabel)
	table.insert(arg_18_0.optionNormalTitles_, skillLabel)
	table.insert(arg_18_0.optionNormalTitles_, awakeLabel)
	table.insert(arg_18_0.optionNormalTitles_, runeLabel)

	arg_18_0.optionHighlightTitles_ = {}

	table.insert(arg_18_0.optionHighlightTitles_, arg_18_0.rightLayer_:getChildByName("info"))
	table.insert(arg_18_0.optionHighlightTitles_, arg_18_0.rightLayer_:getChildByName("skill"))
	table.insert(arg_18_0.optionHighlightTitles_, arg_18_0.rightLayer_:getChildByName("awake"))
	table.insert(arg_18_0.optionHighlightTitles_, arg_18_0.rightLayer_:getChildByName("rune"))
end

function var_0_0.initBottomLayer(arg_21_0)
	arg_21_0.sortTypeCheckboxes_ = {}

	table.insert(arg_21_0.sortTypeCheckboxes_, arg_21_0.bottomLayer_:getChildByName("CheckBox_level"))
	table.insert(arg_21_0.sortTypeCheckboxes_, arg_21_0.bottomLayer_:getChildByName("CheckBox_star"))
	table.insert(arg_21_0.sortTypeCheckboxes_, arg_21_0.bottomLayer_:getChildByName("CheckBox_class"))
	table.insert(arg_21_0.sortTypeCheckboxes_, arg_21_0.bottomLayer_:getChildByName("CheckBox_recent_used"))

	for iter_21_0 = 1, #arg_21_0.sortTypeCheckboxes_ do
		arg_21_0.sortTypeCheckboxes_[iter_21_0]:addEventListener(function(arg_22_0, arg_22_1)
			if arg_22_1 == ccui.CheckBoxEventType.selected then
				xyd.playButtonSound()

				arg_21_0.viewConf_.sortType = iter_21_0

				arg_21_0:refreshSortType()
			elseif arg_22_1 == ccui.CheckBoxEventType.unselected then
				arg_21_0.sortTypeCheckboxes_[iter_21_0]:setSelected(true)
			end
		end)
	end

	local var_21_0 = xyd.tables.translation

	arg_21_0.bottomLayer_:getChildByName("Label_level"):setString(var_21_0:translation("LEVEL"))
	arg_21_0.bottomLayer_:getChildByName("Label_star"):setString(var_21_0:translation("STAR"))
	arg_21_0.bottomLayer_:getChildByName("Label_class"):setString(var_21_0:translation("CLASS"))
	arg_21_0.bottomLayer_:getChildByName("Label_recent_used"):setString(var_21_0:translation("RECENT_USED"))
	arg_21_0.bottomLayer_:getChildByName("Button_collect"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hero_collect")
		end
	end)
end

function var_0_0.initHeroCell(arg_24_0, arg_24_1)
	local var_24_0
	local var_24_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_24_1 > #arg_24_0.heros_ then
		var_24_0 = var_0_11.new()

		var_24_0.heroButton_:removeEventListenersByEvent(cc.ui.UIPushButton.CLICKED_EVENT)
		var_24_0.heroButton_:onButtonClicked(function(arg_25_0)
			print("touch:" .. arg_24_1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hero_slots_expand", {})
		end)

		if var_24_1.maxHeroNumLimit_ < xyd.tables.heroSlot:maxHeroSlotNum() then
			var_24_0.heroButton_:setTouchEnabled(true)
		else
			var_24_0.heroButton_:setTouchEnabled(false)
		end

		if arg_24_1 > arg_24_0.totalCellNum_ - arg_24_0.addCellNum_ then
			local var_24_2 = xyd.AssetLoader.get():loadSprite("#cell_plus_icon.png")

			xyd.displaySpriteOnContainer(var_24_2, var_24_0.heroButton_, false, "left_bottom")
		else
			local var_24_3 = xyd.AssetLoader.get():loadSprite("#cell_hero_icon.png")

			xyd.displaySpriteOnContainer(var_24_3, var_24_0.heroButton_, false, "left_bottom")
		end
	else
		local var_24_4 = arg_24_0.heros_[arg_24_1]

		var_24_0 = var_0_11.new(var_24_4)

		var_24_0.heroButton_:removeEventListenersByEvent(cc.ui.UIPushButton.CLICKED_EVENT)
		var_24_0.heroButton_:onButtonClicked(function(arg_26_0)
			print("touch:" .. arg_24_1)
			xyd.playButtonSound()
			arg_24_0:touchHeroCell(arg_24_1)
		end)

		local var_24_5 = arg_24_0.player_ == nil or arg_24_0.player_.playerID == var_24_1.playerID

		if var_24_4:isRep() == 1 then
			var_24_0:setRep(true)
			var_24_0:setLock(false)
		else
			var_24_0:setRep(false)

			if not var_24_5 then
				var_24_0:setLock(false)
			else
				var_24_0:setLock(var_24_4:isLock() == 1)
			end
		end

		if var_24_5 then
			if var_24_1:isNewHero(var_24_4:getHeroID()) then
				var_24_0:setNew(true)
			else
				var_24_0:setNew(false)
			end
		else
			var_24_0:setNew(false)
		end

		if arg_24_0.selectedHeroID_.heroID == var_24_4:getHeroID() then
			var_24_0:setSelected(true)
		else
			var_24_0:setSelected(false)
		end
	end

	var_24_0:addNodeEventListener(cc.NODE_EVENT, function(arg_27_0)
		if arg_27_0.name == "exit" then
			print(string.format("%dth cell: %s is removed from view", arg_24_1, tostring(var_24_0)))

			if arg_24_0.heroCells_[arg_24_1] then
				arg_24_0.heroCells_[arg_24_1] = nil
			end
		end
	end)

	arg_24_0.heroCells_[arg_24_1] = var_24_0

	return var_24_0
end

function var_0_0.touchHeroCell(arg_28_0, arg_28_1)
	if arg_28_0.selectedHeroID_.heroID ~= arg_28_0.heros_[arg_28_1]:getHeroID() then
		arg_28_0.selectedHeroID_.heroID = arg_28_0.heros_[arg_28_1]:getHeroID()

		arg_28_0:refreshNewHero()
		print("hero tableID:", arg_28_0.heros_[arg_28_1]:getTableID())
		arg_28_0:updateSelectedCell(arg_28_1)

		arg_28_0.selectedIdx_ = arg_28_1
		arg_28_0.viewConf_.rune_slot = nil

		arg_28_0:updateSelectedIdx()
		arg_28_0:refreshOptionLayers(event)
		arg_28_0:refreshDisplayOption()
	end
end

function var_0_0.heroDelegate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	local var_29_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_29_1 = math.max(var_29_0.maxHeroNumLimit_, #arg_29_0.heros_)

	if (arg_29_0.player_ == nil or arg_29_0.player_.playerID == var_29_0.playerID) and var_29_0.maxHeroNumLimit_ < xyd.tables.heroSlot:maxHeroSlotNum() then
		arg_29_0.addCellNum_ = arg_29_0.heroListColNum_ - var_29_1 % arg_29_0.heroListColNum_
	else
		arg_29_0.addCellNum_ = 0
	end

	arg_29_0.totalCellNum_ = var_29_1 + arg_29_0.addCellNum_

	local var_29_2 = math.ceil(arg_29_0.totalCellNum_ / arg_29_0.heroListColNum_)

	if cc.ui.UIListView.COUNT_TAG == arg_29_2 then
		return var_29_2
	elseif cc.ui.UIListView.CELL_TAG == arg_29_2 then
		local var_29_3
		local var_29_4
		local var_29_5 = arg_29_0.heroList_:dequeueItem()

		if not var_29_5 then
			var_29_5 = arg_29_0.heroList_:newItem()
		else
			var_29_5:removeAllChildren()
		end

		local var_29_6 = display.newNode()
		local var_29_7 = 0
		local var_29_8 = {}

		for iter_29_0 = 1, arg_29_0.heroListColNum_ do
			local var_29_9 = (arg_29_3 - 1) * arg_29_0.heroListColNum_ + iter_29_0
			local var_29_10 = arg_29_0:initHeroCell(var_29_9)

			var_29_6:addChild(var_29_10)
			table.insert(var_29_8, var_29_10)

			local var_29_11 = var_29_10:getContentSize().height

			if var_29_7 < var_29_11 then
				var_29_7 = var_29_11
			end
		end

		for iter_29_1 = 1, arg_29_0.heroListColNum_ do
			local var_29_12 = var_29_8[iter_29_1]
			local var_29_13 = var_29_12:getContentSize().height

			var_29_12:setAnchorPoint(cc.p(0, 0))

			if var_29_13 < var_29_7 then
				var_29_12:setPosition(cc.p(var_0_6 * (iter_29_1 - 1), var_29_7 - var_29_13))
			else
				var_29_12:setPosition(cc.p(var_0_6 * (iter_29_1 - 1), 0))
			end
		end

		var_29_5:addContent(var_29_6)

		local var_29_14 = var_29_5:getCascadeBoundingBox()

		var_29_5:setItemSize(var_29_14.width, var_29_7)
		var_29_6:setContentSize(cc.size(var_29_14.width, var_29_7))

		return var_29_5
	end
end

function var_0_0.touchListener(arg_30_0, arg_30_1)
	if arg_30_1.name == "began" then
		arg_30_0.listViewMoved_ = false
	elseif arg_30_1.name == "moved" then
		arg_30_0.listViewMoved_ = true
	elseif arg_30_1.name == "ended" then
		-- block empty
	end
end

function var_0_0.refresh(arg_31_0, arg_31_1)
	arg_31_0.heroCells_ = {}

	arg_31_0:loadHeros(arg_31_1)
end

function var_0_0.loadHeros(arg_32_0, arg_32_1)
	local var_32_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_32_0.heros_ then
		if arg_32_0.viewConf_.viewMode == xyd.HeroViewMode.LIST_VIEW and #arg_32_0.heros_ > 0 then
			arg_32_0:sortHeros()
		end

		arg_32_0:updateSelectedIdx()
		arg_32_0:refreshNewHero()
		arg_32_0:refreshHeroList()
		arg_32_0:refreshOptionLayers(arg_32_1)
		arg_32_0:refreshDisplayOption()

		return
	else
		local var_32_1

		if arg_32_0.player_ == nil or arg_32_0.player_.playerID == var_32_0.playerID then
			var_32_1 = {}
		else
			var_32_1 = {
				player_id = arg_32_0.player_.playerID
			}
		end

		if not arg_32_0.player_ then
			arg_32_0.player_ = var_32_0
		end

		arg_32_0.player_:loadHeros(var_32_1, function(arg_33_0, arg_33_1)
			if arg_33_0 == xyd.error.OK then
				arg_32_0.heros_ = arg_32_0.player_.heros_

				if #arg_32_0.heros_ > 0 then
					if arg_32_0.viewConf_.viewMode == xyd.HeroViewMode.LIST_VIEW and arg_32_0.selectedHeroID_.heroID <= 0 then
						arg_32_0:sortHeros()

						arg_32_0.selectedHeroID_.heroID = arg_32_0.heros_[arg_32_0.selectedIdx_]:getHeroID()
					end

					arg_32_0:updateSelectedIdx()
					arg_32_0:refreshNewHero()
					arg_32_0:refreshHeroList()
					arg_32_0:refreshOptionLayers()
					arg_32_0:refreshDisplayOption()
				else
					arg_32_0.heroList_:removeNodeEventListenersByEvent(cc.NODE_ENTER_FRAME_EVENT)
				end
			else
				xyd.errorAlert(arg_33_1)
			end
		end)
	end
end

function var_0_0.sortHeros(arg_34_0)
	table.sort(arg_34_0.heros_, arg_34_0.sortFuncs_[arg_34_0.viewConf_.sortType])
end

function var_0_0.updateSelectedCell(arg_35_0, arg_35_1)
	local var_35_0 = socket.gettime() * 1000
	local var_35_1 = arg_35_0.heroCells_[arg_35_0.selectedIdx_]

	if var_35_1 then
		var_35_1:setSelected(false)
	end

	local var_35_2 = arg_35_0.heroCells_[arg_35_1]

	if var_35_2 then
		var_35_2:setSelected(true)

		local var_35_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		if arg_35_0.player_ == nil or arg_35_0.player_.playerID == var_35_3.playerID then
			if var_35_3:isNewHero(arg_35_0.selectedHeroID_.heroID) then
				var_35_2:setNew(true)
			else
				var_35_2:setNew(false)
			end
		else
			var_35_2:setNew(false)
		end
	end

	local var_35_4 = socket.gettime() * 1000 - var_35_0
end

function var_0_0.refreshHeroList(arg_36_0)
	local var_36_0 = socket.gettime() * 1000

	xyd.refreshUIListView(arg_36_0.heroList_)

	local var_36_1 = socket.gettime() * 1000 - var_36_0
end

function var_0_0.refreshDisplayOption(arg_37_0)
	for iter_37_0 = 1, #arg_37_0.optionButtons_ do
		if iter_37_0 == arg_37_0.viewConf_.displayOption then
			arg_37_0.optionButtons_[iter_37_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_37_0.optionNormalTitles_[iter_37_0]:setVisible(false)
			arg_37_0.optionHighlightTitles_[iter_37_0]:setVisible(true)
		else
			arg_37_0.optionButtons_[iter_37_0]:setBrightStyle(ccui.BrightStyle.normal)
			arg_37_0.optionNormalTitles_[iter_37_0]:setVisible(true)
			arg_37_0.optionHighlightTitles_[iter_37_0]:setVisible(false)
		end
	end

	arg_37_0.detailsLayers_:switchTo(arg_37_0.viewConf_.displayOption)

	if arg_37_0.optionLayers_[arg_37_0.viewConf_.displayOption].registerEvents then
		arg_37_0.optionLayers_[arg_37_0.viewConf_.displayOption]:registerEvents()
	end
end

function var_0_0.refreshSortType(arg_38_0)
	for iter_38_0 = 1, #arg_38_0.sortTypeCheckboxes_ do
		if iter_38_0 == arg_38_0.viewConf_.sortType then
			arg_38_0.sortTypeCheckboxes_[iter_38_0]:setSelected(true)
		else
			arg_38_0.sortTypeCheckboxes_[iter_38_0]:setSelected(false)
		end
	end

	if arg_38_0.heros_ and #arg_38_0.heros_ > 0 then
		arg_38_0:sortHeros()
		arg_38_0:refreshHeroList()
	end
end

function var_0_0.refreshOptionLayers(arg_39_0, arg_39_1)
	for iter_39_0 = 1, #arg_39_0.optionLayers_ do
		if arg_39_0.optionLayers_[iter_39_0].refresh then
			arg_39_0.optionLayers_[iter_39_0]:refresh(arg_39_1)
		end
	end
end

function var_0_0.refreshNewHero(arg_40_0)
	local var_40_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_40_0.player_ == nil or arg_40_0.player_.playerID == var_40_0.playerID then
		var_40_0:deleteNewHero(arg_40_0.selectedHeroID_.heroID)
	end
end

function var_0_0.updateSelectedIdx(arg_41_0)
	for iter_41_0 = 1, #arg_41_0.heros_ do
		if arg_41_0.heros_[iter_41_0]:getHeroID() == arg_41_0.selectedHeroID_.heroID then
			arg_41_0.selectedIdx_ = iter_41_0

			break
		end
	end
end

function var_0_0.getNextHeroID(arg_42_0)
	local var_42_0

	if arg_42_0.selectedIdx_ >= #arg_42_0.heros_ then
		var_42_0 = #arg_42_0.heros_
	else
		var_42_0 = arg_42_0.selectedIdx_
	end

	return arg_42_0.heros_[var_42_0]:getHeroID()
end

return var_0_0
