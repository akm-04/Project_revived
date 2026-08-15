local var_0_0 = class("ScrollView", cc.ui.UIScrollView)

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.setScrollWidth(arg_2_0, arg_2_1)
	arg_2_0.scrollWidth = arg_2_1
end

function var_0_0.setScrollHeight(arg_3_0, arg_3_1)
	arg_3_0.scrollHeight = arg_3_1
end

local var_0_1 = 3
local var_0_2 = 1
local var_0_3 = 2
local var_0_4 = class("PetAttributeWindow", import("app.common.ui.BaseWindow"))
local var_0_5 = 4
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = 1
local var_0_9 = xyd.tables.hero
local var_0_10 = require("framework.scheduler")
local var_0_11 = xyd.tables.translation
local var_0_12 = import("app.common.ui.SpineEffect")
local var_0_13 = {}
local var_0_14 = 0
local var_0_15 = 1
local var_0_16 = 2
local var_0_17 = 1
local var_0_18 = 2

var_0_13.AddItem = "skeletons/ui_effect/common_effect_hero2/common_effect_hero2_new"
var_0_13.CanUpgrade = "skeletons/ui_effect/common_effect_hero12/new_advanced"
var_0_13.CanEvolve = "skeletons/ui_effect/hero/star_up"
var_0_13.Upgrade = "skeletons/ui_effect/common_effect_hero3/common_effect_hero3"
var_0_13.Evolve = "skeletons/ui_effect/common_effect_hero4/common_effect_hero4"
var_0_13.SkillUp = "skeletons/ui_effect/common_effect_hero7/common_effect_hero7"
var_0_13.CanSummon = "skeletons/ui_effect/common_effect_hero8/common_effect_hero8"
var_0_13.LevelUp = "skeletons/ui_effect/common_effect_exp_lv_up/common_effect_exp_lv_up"
var_0_13.Background1 = "skeletons/ui_effect/hero/hero_bg_effect01"
var_0_13.Background2 = "skeletons/ui_effect/hero/hero_bg_effect02"

function var_0_4.ctor(arg_4_0, arg_4_1, arg_4_2)
	var_0_4.super.ctor(arg_4_0, arg_4_1, arg_4_2)

	if arg_4_2 then
		arg_4_0.hero = arg_4_2
	end

	arg_4_0.UIEffects = {}
	arg_4_0.skillTips = {}
	arg_4_0.visibleHandler = {}
	arg_4_0.refresh_ = false
	arg_4_0.eatHandler = {}
	arg_4_0.skillLevel = {}
	arg_4_0.needEquip = {}
	arg_4_0.needPotion = {}
	arg_4_0.needGold = 0
	arg_4_0.scroll_moving_end = false
	arg_4_0.scroll_is_moving = false
	arg_4_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_4_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_4.willOpen(arg_5_0, arg_5_1)
	var_0_4.super:willOpen(arg_5_1)

	arg_5_0.maxLev = xyd.tables.player:heroMaxLev(arg_5_0.selfPlayer.lev)
	arg_5_0.skillPoints = arg_5_0.selfPlayer:getBackpack():getSkillBookNum()

	arg_5_0:addTopSidebar()
	arg_5_0:addThemeBG()
	arg_5_0:nodeByName("top_sidebar"):setLocalZOrder(6)
	arg_5_0:layout()
end

function var_0_4.didOpen(arg_6_0, arg_6_1)
	var_0_4.super:didOpen(arg_6_1)
	arg_6_0:update(arg_6_0.hero)
end

function var_0_4.didClose(arg_7_0, arg_7_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end
end

function var_0_4.addBgEffect(arg_8_0)
	local var_8_0 = var_0_13.Background1 .. ".json"
	local var_8_1 = var_0_13.Background1 .. ".atlas"

	arg_8_0.bgEffect = var_0_12.new(var_8_0, var_8_1, 1)

	arg_8_0:nodeByName("background"):addChild(arg_8_0.bgEffect)
	arg_8_0.bgEffect:setPosition(303, 593)
	arg_8_0.bgEffect:play(nil, true)

	local var_8_2 = var_0_13.Background2 .. ".json"
	local var_8_3 = var_0_13.Background2 .. ".atlas"

	arg_8_0.bgEffect2 = var_0_12.new(var_8_2, var_8_3, 1)

	arg_8_0:nodeByName("background"):addChild(arg_8_0.bgEffect2)
	arg_8_0.bgEffect2:setPosition(303, 593)
	arg_8_0.bgEffect2:play(nil, true)
	arg_8_0.bgEffect2:setScaleX(0.74)
	arg_8_0.bgEffect2:setScaleY(1.17)
	arg_8_0.bgEffect2:setRotation(51.5)
	arg_8_0.bgEffect:setLocalZOrder(1)
	arg_8_0.bgEffect2:setLocalZOrder(2)
	arg_8_0:nodeByName("card"):setLocalZOrder(3)
	arg_8_0:nodeByName("bg_divide"):setLocalZOrder(4)
	arg_8_0:nodeByName("bg_left"):setLocalZOrder(5)
end

function var_0_4.layout(arg_9_0)
	arg_9_0.mainContainer = arg_9_0:nodeByName("card_container")
	arg_9_0.cardContainer = arg_9_0:nodeByName("card_view")
	arg_9_0.cardBlock = arg_9_0:nodeByName("card_block")
	arg_9_0.infoContainer = arg_9_0:nodeByName("info_container")
	arg_9_0.skillContainer = arg_9_0:nodeByName("skill_container")
	arg_9_0.nameLabelContainer = arg_9_0:nodeByName("name_label")
	arg_9_0.homeCardContainer = arg_9_0:nodeByName("card")

	arg_9_0:nodeByName("borrow_container"):setVisible(true)
	arg_9_0:nodeByName("normal_container"):setVisible(false)
	arg_9_0.cardContainer:hide()
	arg_9_0.cardBlock:hide()
	arg_9_0.cardBlock:setTouchSwallowEnabled(true)
	arg_9_0:nodeByName("star_back"):setVisible(false)
	arg_9_0:nodeByName("jinengdian"):setVisible(false)
	arg_9_0:nodeByName("left_skill_title"):setVisible(false)
	arg_9_0:nodeByName("force_bg"):width(arg_9_0:nodeByName("force_bg"):getWidth() + 140)
	arg_9_0:nodeByName("zhandouli_txt"):runAction(cc.MoveBy:create(0, cc.p(140, 0)))
	arg_9_0:nodeByName("exp_bg"):width(arg_9_0:nodeByName("exp_bg"):getWidth() + 140)
	arg_9_0:nodeByName("exp_txt"):runAction(cc.MoveBy:create(0, cc.p(140, 0)))

	arg_9_0.containers = {}

	table.insert(arg_9_0.containers, arg_9_0.mainContainer)
	table.insert(arg_9_0.containers, arg_9_0.skillContainer)
	table.insert(arg_9_0.containers, arg_9_0.infoContainer)
	table.insert(arg_9_0.containers, arg_9_0.cardContainer)

	local var_9_0 = arg_9_0.mainContainer:getChildByName("lev_des"):setString(var_0_11:translation("HERO_DENGJI"))
	local var_9_1 = arg_9_0.mainContainer:getChildByName("zhandou_des"):setString(var_0_11:translation("HERO_INFO_ZHANDOULI"))
	local var_9_2 = arg_9_0.mainContainer:getChildByName("jingyan_des"):setString(var_0_11:translation("HERO_INFO_JINGYAN"))

	for iter_9_0, iter_9_1 in pairs(arg_9_0.containers) do
		iter_9_1:setVisible(false)
	end

	arg_9_0.mainContainer:setVisible(true)

	local var_9_3 = arg_9_0.infoContainer:getContentSize()

	arg_9_0.state = var_0_8

	arg_9_0:nodeByName("button_all"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_9_0.skillContainer:getChildByName("jinengdian"):setString(arg_9_0.selfPlayer:getBackpack():getSkillBookNum())
	arg_9_0:setupButtonClick()

	arg_9_0.infoScrollBg = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_9_3.width, var_9_3.height - 40)
	}):onScroll(handler(arg_9_0, arg_9_0.infoScrollListener)):setTouchType(true):setBounceable(true):pos(15, 20):addTo(arg_9_0.infoContainer)

	local var_9_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/info_container.csb")

	arg_9_0.infoScrollBg:addScrollNode(var_9_4)
	var_9_4:setName("info_scroll_node")
	var_9_4:removeChild(var_9_4:getChildByName("background"))
	arg_9_0:parseChildren_(var_9_4)

	local var_9_5 = arg_9_0.skillContainer:getChildByName("scroll_bg")

	arg_9_0.skillList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_9_5:getWidth(), var_9_5:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_9_5):onScroll(handler(arg_9_0, arg_9_0.infoScrollListener))

	arg_9_0:updateBtnShow()
	arg_9_0:updateStringLabels()
end

function var_0_4.updateStringLabels(arg_10_0)
	arg_10_0:nodeByName("title_jieshao"):setString(var_0_11:translation("PET_MAIN_TXT1"))
	arg_10_0:nodeByName("title_shuxing"):setString(var_0_11:translation("PET_MAIN_TXT2"))
	arg_10_0:nodeByName("txt_all"):setString(var_0_11:translation("PET_MAIN_TXT3"))
	arg_10_0:nodeByName("txt_shuxing"):setString(var_0_11:translation("PET_MAIN_TXT4"))
	arg_10_0:nodeByName("txt_jineng"):setString(var_0_11:translation("PET_MAIN_TXT5"))
	arg_10_0:nodeByName("txt_tujian"):setString(var_0_11:translation("PET_MAIN_TXT6"))
	arg_10_0:nodeByName("txt_luntan"):setString(var_0_11:translation("PET_MAIN_TXT7"))
	arg_10_0:nodeByName("txt_levup"):setString(var_0_11:translation("PET_MAIN_TXT8"))
	arg_10_0:nodeByName("jinjie_txt"):setString(var_0_11:translation("PET_MAIN_TXT9"))
	arg_10_0:nodeByName("yijian_txt"):setString(var_0_11:translation("PET_MAIN_TXT10"))
	arg_10_0:nodeByName("onekey_txt"):setString(var_0_11:translation("PET_MAIN_TXT11"))
	arg_10_0:nodeByName("left_skill_title"):setString(var_0_11:translation("PET_MAIN_TXT12"))
end

function var_0_4.infoScrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevX_ = arg_11_1.x
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 15 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end

	local var_11_0 = arg_11_0.infoScrollBg:getScrollNode()
	local var_11_1 = 0
	local var_11_2 = -(var_11_0:getCascadeBoundingBox().height - var_11_0:getContentSize().height)

	if var_11_1 < var_11_0:getPositionX() then
		arg_11_0.infoScrollBg:scrollTo(0, var_11_1)
	elseif var_11_2 > var_11_0:getPositionX() then
		arg_11_0.infoScrollBg:scrollTo(0, var_11_2)
	end
end

function var_0_4.expScrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scroll_is_moving = false

		arg_12_0.expScrollBg:scrollAuto()

		arg_12_0.scrollViewMoved_ = false
		arg_12_0.prevY_ = arg_12_1.y

		if arg_12_0.scroll_moving_end == true then
			arg_12_0.scroll_moving_end = false
		end
	elseif arg_12_1.name == "moved" then
		local var_12_0 = arg_12_0.expScrollBg:getScrollNode()
		local var_12_1 = 0
		local var_12_2 = -(var_12_0:getCascadeBoundingBox().height - arg_12_0.expScrollBg:getViewRectInWorldSpace().height)

		if var_12_1 < var_12_0:getPositionY() then
			arg_12_0.scroll_is_moving = true
		elseif var_12_2 > var_12_0:getPositionY() then
			arg_12_0.scroll_is_moving = true
		else
			arg_12_0.scroll_is_moving = false
		end

		arg_12_0.scrolly = var_12_0:getPositionY()

		if 5 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
			arg_12_0.scrollViewMoved_ = true
		end
	elseif arg_12_1.name == "scrollEnd" then
		arg_12_0.scrolly = arg_12_0.expScrollBg:getScrollNode():getPositionY()

		if arg_12_0.scroll_is_moving == true then
			arg_12_0.scroll_moving_end = true
			arg_12_0.scroll_is_moving = false
		end
	end
end

function var_0_4.setupButtonClick(arg_13_0)
	arg_13_0:nodeByName("button_all"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_13_0:clickMainButton()
		end
	end)
	arg_13_0.mainContainer:getChildByName("button_onekeyequips"):setVisible(false)
	arg_13_0.mainContainer:getChildByName("button_jinjie"):setVisible(false)
	arg_13_0:nodeByName("button_jinhua"):setVisible(false)
	arg_13_0:nodeByName("button_shuxing"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_13_0:clickInfoButton()
		end
	end)

	local var_13_0 = arg_13_0:nodeByName("btn_tujian")

	xyd.nodeEventSample(var_13_0, nil, function()
		xyd.playButtonSound()
		arg_13_0:clickCardButton()
	end)
	arg_13_0:nodeByName("button_jineng"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_13_0:clickSkillButton()
		end
	end)
	arg_13_0.mainContainer:getChildByName("button_yijian"):setVisible(false)
	arg_13_0:nodeByName("button_linghunshi"):setVisible(false)
	arg_13_0:nodeByName("button_show_detail"):setVisible(false)
	arg_13_0:nodeByName("button_jingyan"):setVisible(false)
	arg_13_0:nodeByName("btn_luntan"):setVisible(false)
end

function var_0_4.update(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0.hero

	arg_18_0:nodeByName("last_hero"):setVisible(false)
	arg_18_0:nodeByName("next_hero"):setVisible(false)

	if arg_18_0.equipContainerlist_ then
		for iter_18_0, iter_18_1 in ipairs(arg_18_0.equipContainerlist_) do
			iter_18_1:removeAllNodeEventListeners()
			iter_18_1:removeSelf()
		end

		arg_18_0.equipContainerlist_ = nil
	end

	for iter_18_2 = 1, var_0_1 do
		local var_18_1 = arg_18_0:getEquipContainerByIndex(iter_18_2)
		local var_18_2 = var_18_0:getEquipByIndex(iter_18_2)
	end

	if arg_18_0.heroModel_ then
		arg_18_0.heroModel_:removeSelf()

		arg_18_0.heroModel_ = nil
	end

	local var_18_3 = arg_18_1 or arg_18_0.hero

	arg_18_0:updateHeroModel(var_18_3)
	arg_18_0:updateAttrScore()
	arg_18_0:updateExp()
	arg_18_0:updateHeroStar()
	arg_18_0:updateCard()
	arg_18_0:updateHomeCard()
	arg_18_0:updateAttrLabels()
	arg_18_0:updateIntroduceText()
	arg_18_0:updateScrollBg()
	arg_18_0:setSkillContainer()
	arg_18_0:updateNameLabel()
	arg_18_0:updateBtnShow()
end

function var_0_4.updateNameLabel(arg_19_0)
	arg_19_0.nameLabelContainer:removeAllChildren()

	local var_19_0 = arg_19_0.hero
	local var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/hero_label.csb")

	var_19_1:addTo(arg_19_0.nameLabelContainer)

	local var_19_2 = var_19_1:getChildByName("bg")
	local var_19_3 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_" .. xyd.Color2Quality[var_19_0:getColor()] .. ".png")

	var_19_3:addTo(var_19_2:getChildByName("bg_name"))
	var_19_3:setAnchorPoint(0, 0)

	local var_19_4

	if arg_19_0.hero:isAwaken() then
		if arg_19_0.hero:isAwakeTwice() then
			var_19_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake_twice.png")
		else
			var_19_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake.png")
		end

		var_19_4:addTo(var_19_2:getChildByName("bg_awake"))
		var_19_4:setAnchorPoint(0, 0)
	end

	local var_19_5 = xyd.AssetLoader.get():loadSprite("windows/hero/quality_" .. var_19_0:getColor() .. ".png")
	local var_19_6 = arg_19_0.hero:getInscriptionKuangLevel()

	if var_19_6 then
		var_19_5 = xyd.AssetLoader.get():loadSprite("windows/hero/suit_" .. var_19_6 .. ".png")

		var_19_2:getChildByName("bg_name"):removeAllChildren()

		local var_19_7 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_suit.png")

		var_19_7:addTo(var_19_2:getChildByName("bg_name"))
		var_19_7:setAnchorPoint(0, 0)
	end

	var_19_5:setAnchorPoint(0.5, 0.5)
	var_19_5:addTo(var_19_2:getChildByName("quality"))
	var_19_2:getChildByName("name"):setString(var_19_0:getName())

	for iter_19_0 = 1, xyd.HERO_TOTAL_STARS do
		local var_19_8 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

		var_19_2:getChildByName("star_" .. iter_19_0):setSpriteFrame(var_19_8:getSpriteFrame())
		var_19_2:getChildByName("star_" .. iter_19_0):setVisible(iter_19_0 <= var_19_0:getStar())
	end
end

function var_0_4.updateCard(arg_20_0)
	arg_20_0.cardContainer:removeAllChildren()
	arg_20_0.cardBlock:removeAllChildren()

	local var_20_0 = display.newNode()

	var_20_0:setContentSize(arg_20_0.cardBlock:getContentSize())
	var_20_0:addTo(arg_20_0.cardBlock)
	var_20_0:setTouchEnabled(true)
	var_20_0:setTouchSwallowEnabled(true)
	var_20_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "ended" then
			if not arg_20_0.card or not arg_20_0.isCardShow then
				return
			end

			arg_20_0:clickCardButton()
		end

		return true
	end)

	local function var_20_1(arg_22_0)
		if arg_22_0 == xyd.CardStatus.SKIN_CARD then
			if arg_20_0.hero.isSkinOn_ == 1 then
				return true
			else
				return false
			end
		elseif arg_22_0 == xyd.CardStatus.AWAKE_CARD then
			if arg_20_0.hero:isAwaken() then
				return true
			else
				return false
			end
		elseif arg_22_0 == xyd.CardStatus.NORMAL_CARD then
			return true
		end
	end

	if not arg_20_0.frontState then
		if arg_20_0.hero.isSkinOn_ == 1 then
			arg_20_0.frontState = xyd.CardStatus.SKIN_CARD
		elseif arg_20_0.hero:isAwaken() then
			arg_20_0.frontState = xyd.CardStatus.AWAKE_CARD
		else
			arg_20_0.frontState = xyd.CardStatus.NORMAL_CARD
		end

		arg_20_0.backState = arg_20_0.frontState + 1
	else
		arg_20_0.frontState = arg_20_0.backState
		arg_20_0.backState = arg_20_0.backState + 1
	end

	while not var_20_1(arg_20_0.backState) do
		if arg_20_0.backState > 3 then
			arg_20_0.backState = 1
		else
			arg_20_0.backState = arg_20_0.backState + 1
		end
	end

	local var_20_2 = xyd.getPetCard(arg_20_0.hero, arg_20_0.frontState, arg_20_0.backState)

	var_20_2:addTo(arg_20_0.cardContainer)

	arg_20_0.card = var_20_2

	var_20_2:align(display.CENTER, var_20_2:getWidth() / 2, var_20_2:getHeight() / 2)
	var_20_2:setTouchEnabled(true)
	var_20_2:setTouchSwallowEnabled(true)
	var_20_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "ended" then
			if not arg_20_0.card or not arg_20_0.isCardShow then
				return
			end

			arg_20_0:clickCardButton()
		end

		return true
	end)
	arg_20_0.card:scale(xyd.STAGE_HEIGHT / arg_20_0.card:getWidth())
	arg_20_0.card:setRotation(-90)
	arg_20_0.card:setPosition(xyd.STAGE_WIDTH / 2 - 128.31, xyd.STAGE_HEIGHT / 2)
end

function var_0_4.updateHomeCard(arg_24_0)
	if not arg_24_0 or tolua.isnull(arg_24_0) or not arg_24_0.homeCardContainer or tolua.isnull(arg_24_0.homeCardContainer) then
		return
	end

	arg_24_0.homeCardContainer:removeAllChildren()

	local var_24_0 = xyd.getTransparentCard(arg_24_0.hero)

	if not var_24_0 then
		return
	end

	arg_24_0.homeCardContainer:addChild(var_24_0)
	var_24_0:setPosition(arg_24_0.homeCardContainer:getWidth() / 2, 0)
	var_24_0:setAnchorPoint(cc.p(0.5, 0))
	var_24_0:setTouchEnabled(false)
end

function var_0_4.cardRolling(arg_25_0, arg_25_1)
	local function var_25_0()
		arg_25_0.isFrontOut = not arg_25_0.isFrontOut
		arg_25_0.canSwitchCard = true
	end

	local function var_25_1()
		local var_27_0 = arg_25_0.card:getChildByName("container"):getChildByName("cardFront")
		local var_27_1 = arg_25_0.card:getChildByName("container"):getChildByName("cardBack")

		if arg_25_0.isFrontOut then
			var_27_0:setVisible(true)
			var_27_1:setVisible(false)
		else
			var_27_0:setVisible(false)
			var_27_1:setVisible(true)
		end

		arg_25_0:updateCard()
	end

	local var_25_2 = cc.OrbitCamera:create(arg_25_1, 1, 0, 0, 90, 0, 0)
	local var_25_3 = cc.OrbitCamera:create(arg_25_1, 1, 0, 270, 90, 0, 0)
	local var_25_4 = cc.CallFunc:create(var_25_1)
	local var_25_5 = cc.CallFunc:create(var_25_0)
	local var_25_6 = cc.Sequence:create(var_25_2, var_25_4, var_25_3, var_25_5)

	arg_25_0.card:runAction(var_25_6)
end

function var_0_4.updateHeroStar(arg_28_0)
	local var_28_0 = arg_28_0.hero

	arg_28_0:nodeByName("text_name"):setString(arg_28_0.hero.player_name)

	if arg_28_0.hero.conquer_lev and arg_28_0.hero.conquer_lev > 0 then
		xyd.setConquerLev(arg_28_0.hero.conquer_lev, arg_28_0:nodeByName("text_lev"), arg_28_0:nodeByName("level_bg"), nil, nil, nil, nil, arg_28_0.hero.conquer_loop_id)
	else
		arg_28_0:nodeByName("text_lev"):setString(arg_28_0.hero.player_lev)
	end

	arg_28_0:nodeByName("text_laizi"):setString(xyd.tables.translation:translation("LAI_ZI"))
	xyd.setAvatarClip(arg_28_0:nodeByName("touxiang_container"), arg_28_0.hero.player_avatar, 1)

	local var_28_1 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_28_0.hero.player_avatar_frame and arg_28_0.hero.player_avatar_frame ~= 0 then
		var_28_1 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_28_0.hero.player_avatar_frame] .. ".png"
	end

	local var_28_2 = xyd.AssetLoader.get():loadSprite(var_28_1)

	arg_28_0:nodeByName("touxiangkuang"):addChild(var_28_2)
	var_28_2:scale(0.75)
	var_28_2:pos(arg_28_0:nodeByName("touxiangkuang"):getWidth() / 2, arg_28_0:nodeByName("touxiangkuang"):getHeight() / 2)

	for iter_28_0 = 1, 5 do
		arg_28_0:nodeByName("hero_star" .. iter_28_0):setPositionY(247)
		arg_28_0:nodeByName("star_gray" .. iter_28_0):setPositionY(247)
		arg_28_0:nodeByName("hero_star" .. iter_28_0):setVisible(iter_28_0 <= var_28_0:getStar())
	end
end

function var_0_4.updateExp(arg_29_0, arg_29_1)
	arg_29_1 = arg_29_1 or arg_29_0.hero

	arg_29_0:nodeByName("lev_txt"):setString(arg_29_1:getLevel())

	local var_29_0 = arg_29_1:getExp() - xyd.tables.petExp:totalExp(arg_29_1:getLevel() - 1)

	arg_29_0:nodeByName("exp_txt"):setString(var_29_0 .. " / " .. arg_29_1:getAddExp())
end

function var_0_4.playEatExpEffect(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0:getHeroContainer():getContentSize().width
	local var_30_1 = arg_30_0:getHeroContainer():getContentSize().height
	local var_30_2 = xyd.tables.sound:getSound("train_exp_up")

	audio.playSound(var_30_2, false)

	if not arg_30_0.eatExpEffect then
		local var_30_3 = var_0_13.LevelUp .. ".json"
		local var_30_4 = var_0_13.LevelUp .. ".atlas"

		arg_30_0.eatExpEffect = var_0_12.new(var_30_3, var_30_4, 1)

		arg_30_0.eatExpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_30_0.eatExpEffect:setPosition(var_30_0 / 2, var_30_1 / 2)
		arg_30_0.eatExpEffect:addTo(arg_30_0:getHeroContainer())
	end

	arg_30_0.eatExpEffect:play(nil, false)

	local var_30_5 = arg_30_1:getChildByName("item"):getContentSize().width
	local var_30_6 = arg_30_1:getChildByName("item"):getContentSize().height
	local var_30_7, var_30_8 = arg_30_1:getChildByName("item"):getPosition()

	if arg_30_0.clickEffect and not tolua.isnull(arg_30_0.clickEffect) then
		arg_30_0.clickEffect:removeAllChildren()
	end

	local var_30_9 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_30_10 = var_30_9 .. ".json"
	local var_30_11 = var_30_9 .. ".atlas"

	arg_30_0.clickEffect = var_0_12.new(var_30_10, var_30_11, 1)

	arg_30_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_30_0.clickEffect:setPosition(var_30_7 + var_30_5 / 2, var_30_8 + var_30_6 / 2)
	arg_30_1:addChild(arg_30_0.clickEffect)
	arg_30_0.clickEffect:setScale(0.7)
	arg_30_0.clickEffect:play(nil, false)
end

function var_0_4.updateScrollBg(arg_31_0)
	local var_31_0 = arg_31_0.infoScrollBg:getViewRect()
	local var_31_1 = arg_31_0:nodeByName("shuxing_container")
	local var_31_2 = arg_31_0:nodeByName("jieshao_container")
	local var_31_3 = var_31_1:getContentSize().height
	local var_31_4 = var_31_2:getContentSize().height

	var_31_2:setPosition(cc.p(0, var_31_3))
	var_31_1:setPosition(cc.p(0, 0))
	arg_31_0.infoScrollBg:setScrollWidth(var_31_0.width)
	arg_31_0.infoScrollBg:setScrollHeight(var_31_3 + var_31_4)
	arg_31_0.infoScrollBg:scrollTo(0, var_31_0.height - var_31_3 - var_31_4)
end

function var_0_4.updateAttrScore(arg_32_0, arg_32_1)
	arg_32_1 = arg_32_1 or arg_32_0.hero

	local var_32_0 = arg_32_1:getZhandouli()

	arg_32_0:nodeByName("zhandouli_txt"):setString(var_32_0)
end

function var_0_4.updateHeroModel(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_1:getTableID()
	local var_33_1 = arg_33_0:getHeroModel()

	if not var_33_1 then
		return
	end

	var_33_1:setTouchSwallowEnabled(false)

	arg_33_0.modelState = xyd.ModelState.Walk

	local var_33_2 = arg_33_0:getHeroContainer():getContentSize().width / 2

	var_33_1:setPosition(cc.p(var_33_2, 0))
	arg_33_0:getHeroContainer():removeAllChildren()
	var_33_1:addTo(arg_33_0:getHeroContainer())
	var_33_1:setTouchEnabled(true)

	arg_33_0.isShow = false

	arg_33_0:getHeroContainer():addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended and not arg_33_0.isShow then
			arg_33_0:resetModelState()
		end
	end)
end

function var_0_4.setIsShow(arg_35_0)
	arg_35_0.isShow = false

	arg_35_0:getHeroModel():idle()
end

function var_0_4.resetModelState(arg_36_0)
	local var_36_0 = arg_36_0:getHeroModel()

	if arg_36_0.modelState == 6 then
		arg_36_0.modelState = arg_36_0.modelState + 1
	end

	arg_36_0.modelState = arg_36_0.modelState % 6
	arg_36_0.isShow = true

	local var_36_1

	if arg_36_0.modelState == xyd.ModelState.Walk then
		var_36_0:walk(true)

		arg_36_0.isShow = false
		var_36_1 = xyd.tables.model:getMoveSound(arg_36_0.hero:getModelID())
	elseif arg_36_0.modelState == xyd.ModelState.Win then
		var_36_0:win(false, handler(arg_36_0, arg_36_0.setIsShow))

		var_36_1 = xyd.tables.model:getWinSound(arg_36_0.hero:getModelID())
	elseif arg_36_0.modelState == xyd.ModelState.Attack1 then
		var_36_0:attack(1, nil, nil, handler(arg_36_0, arg_36_0.setIsShow))

		var_36_1 = xyd.tables.model:getNormalAttackSound(arg_36_0.hero:getModelID())
	elseif arg_36_0.modelState == xyd.ModelState.Attack2 then
		var_36_0:attack(2, nil, nil, handler(arg_36_0, arg_36_0.setIsShow))

		var_36_1 = xyd.tables.model:getAttack1Sound(arg_36_0.hero:getModelID())
	elseif arg_36_0.modelState == xyd.ModelState.Attack3 then
		var_36_0:attack(3, nil, nil, handler(arg_36_0, arg_36_0.setIsShow))

		var_36_1 = xyd.tables.model:getAttack2Sound(arg_36_0.hero:getModelID())
	elseif arg_36_0.modelState == xyd.ModelState.Attack4 then
		var_36_0:attack(4, nil, nil, handler(arg_36_0, arg_36_0.setIsShow))

		var_36_1 = xyd.tables.model:getAttack4Sound(arg_36_0.hero:getModelID())
	else
		arg_36_0:setIsShow()
	end

	if var_36_1 then
		audio.stopAllSounds()
		audio.playSound(var_36_1, false)
	end

	arg_36_0.modelState = arg_36_0.modelState + 1
end

function var_0_4.getHeroModel(arg_37_0)
	if not arg_37_0.heroModel_ then
		if arg_37_0.hero then
			arg_37_0.heroModel_ = arg_37_0.hero:getHeroModel()
		else
			return false
		end
	end

	return arg_37_0.heroModel_
end

function var_0_4.setSkillContainer(arg_38_0, arg_38_1)
	arg_38_1 = arg_38_1 or arg_38_0.hero

	local var_38_0 = arg_38_1:getSkillId()

	arg_38_0.skillItems = {}

	arg_38_0.skillList:removeAllItems()

	local var_38_1 = 0
	local var_38_2 = 0

	for iter_38_0, iter_38_1 in ipairs(var_38_0) do
		if iter_38_0 == xyd.SKILL_INDEX.AwakeTwice then
			break
		end

		local var_38_3 = iter_38_1 == 0 or xyd.tables.skill:isAwakenSkill(iter_38_1) > 0

		if xyd.tables.hero:isCanAwaken(arg_38_1:getTableID()) > 0 and arg_38_0.selfPlayer.maxTeamLev >= 90 or not var_38_3 then
			local var_38_4 = display.newNode()
			local var_38_5 = arg_38_0.skillList:newItem()
			local var_38_6 = xyd.tables.skill:icon(iter_38_1)
			local var_38_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/skill_item.csb")
			local var_38_8 = xyd.SpriteLoader.new(var_38_6, nil, nil, xyd.DefaultImageType.SKILL_ICON)
			local var_38_9 = var_38_7:getChildByName("background"):getContentSize()

			var_38_7:setContentSize(var_38_9)
			var_38_4:setContentSize(var_38_9)

			local var_38_10 = var_38_7:getChildByName("icon")
			local var_38_11 = var_38_7:getChildByName("border"):getChildByName("skill_hide")

			if not var_38_3 or arg_38_1:isAwaken() then
				var_38_7:getChildByName("lev"):setVisible(true)
				var_38_7:getChildByName("level_extra"):setVisible(true)
				var_38_11:setVisible(false)
				var_38_7:getChildByName("skillBook"):setVisible(false)
				var_38_7:getChildByName("bookNum"):setVisible(false)

				local var_38_12 = xyd.AssetLoader:get():loadSprite("windows/pet/petMainWindow/skill_icon_mask.png")

				var_38_12:setPosition(var_38_10:getWidth() / 2, var_38_10:getHeight() / 2)
				var_38_12:setAnchorPoint(cc.p(0.5, 0.5))
				var_38_12:scale(var_38_10:getWidth() / var_38_12:getWidth())

				local var_38_13 = cc.ClippingNode:create()

				var_38_13:setStencil(var_38_12)
				var_38_13:setInverted(true)
				var_38_13:setAlphaThreshold(0)
				var_38_10:addChild(var_38_13)
				var_38_13:addChild(var_38_8)
				var_38_8:align(display.LEFT_BOTTOM, 0, 0)
				var_38_8:scale((var_38_10:getWidth() - 3) / var_38_8:getWidth())

				if arg_38_1:getSkillLevel(iter_38_0) ~= 0 then
					local var_38_14 = arg_38_1:getSkillLevel(iter_38_0) - xyd.SKILL_EXTRA[iter_38_0]

					var_38_7:getChildByName("lev"):setString("lv. " .. var_38_14)

					if arg_38_1:getExtraSkillLevel() > 0 then
						var_38_7:getChildByName("level_extra"):show()
						var_38_7:getChildByName("level_extra"):setString("+" .. arg_38_1:getExtraSkillLevel())
					else
						var_38_7:getChildByName("level_extra"):hide()
					end

					var_38_7:getChildByName("jiesuo"):setVisible(false)
				else
					local var_38_15 = var_0_11:translation("HERO_JIESUO_" .. iter_38_0)

					var_38_7:getChildByName("jiesuo"):setString(var_38_15)
					var_38_7:getChildByName("lev"):setVisible(false)
					var_38_7:getChildByName("level_extra"):hide()
				end
			else
				var_38_11:setVisible(true)
				var_38_7:getChildByName("lev"):setVisible(false)
				var_38_7:getChildByName("skillBook"):setVisible(false)
				var_38_7:getChildByName("bookNum"):setVisible(false)
				var_38_7:getChildByName("level_extra"):setVisible(false)
				var_38_7:getChildByName("jiesuo"):setString(var_0_11:translation("PET_AWAKE_SKILL_LOCK_TIP"))
			end

			var_38_7:getChildByName("name"):setString(xyd.tables.skill:name(iter_38_1))
			var_38_7:addTo(var_38_4)
			table.insert(arg_38_0.skillItems, var_38_7)
			var_38_5:addContent(var_38_4)
			var_38_5:setItemSize(var_38_4:getWidth(), var_38_4:getHeight() + 6)
			arg_38_0.skillList:addItem(var_38_5)

			var_38_1 = var_38_1 + 1
			var_38_2 = var_38_2 + xyd.tables.petSkillBook:getBookNum(arg_38_1:getSkillLevel(iter_38_0))

			arg_38_0:createSkillTip(iter_38_0, iter_38_1)
		end
	end

	if var_38_1 < 5 then
		arg_38_0.skillList:setBounceable(false)
	else
		arg_38_0.skillList:setBounceable(true)
	end

	arg_38_0.skillCount = var_38_1
	arg_38_0.skillBook = var_38_2

	arg_38_0.skillList:reload()
end

function var_0_4.createSkillTip(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_0.skillItems[arg_39_1]

	if not var_39_0 then
		return
	end

	if var_39_0:getChildByName("skill_tip") and not tolua.isnull(var_39_0:getChildByName("skill_tip")) then
		var_39_0:removeChildByName("skill_tip")
	end

	local var_39_1 = display.newNode()

	var_39_1:setPosition(var_39_0:getChildByName("icon"):getPosition())
	var_39_1:setAnchorPoint(cc.p(0, 0))
	var_39_1:setContentSize(var_39_0:getChildByName("icon"):getContentSize())
	var_39_1:setTouchEnabled(true)
	var_39_1:addTo(var_39_0)
	var_39_1:setName("skill_tip")

	local var_39_2 = arg_39_0:convertToWorldSpace(cc.p(0, 0))

	var_39_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_40_0)
		if arg_40_0.name == "began" then
			return true
		elseif arg_40_0.name == "ended" then
			if xyd.WindowManager.get():getWindow("skill_tips") then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end

			local var_40_0 = {
				isShowSkillDesc4 = true,
				id = arg_39_2,
				skillLev = arg_39_0.hero:getSkillLevel(arg_39_1),
				extraSkillLevel = arg_39_0.hero:getExtraSkillLevel(),
				skillDesc4Change = arg_39_0.hero:checkSkillChange(arg_39_1)
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_40_1 = xyd.WindowManager.get():openWindow("skill_tips", var_40_0)
				local var_40_2 = var_39_1:convertToWorldSpace(cc.p(0, 0))

				var_40_1:setPosition(var_40_2.x + 110 + 7 - var_39_2.x, var_40_2.y - var_39_0:getContentSize().height + 20 - var_39_2.y)
			end
		end
	end)
end

function var_0_4.updateAllSkillTips(arg_41_0)
	local var_41_0 = arg_41_0.hero:getSkillId()

	for iter_41_0, iter_41_1 in pairs(var_41_0) do
		if iter_41_1 <= 0 then
			var_41_0[iter_41_0] = nil
		end

		if arg_41_0.selfPlayer.maxTeamLev <= 80 and xyd.tables.skill:isAwakenSkill(iter_41_1) == 1 then
			var_41_0[iter_41_0] = nil
		end
	end

	for iter_41_2, iter_41_3 in pairs(var_41_0) do
		arg_41_0:createSkillTip(iter_41_2, iter_41_3)
	end
end

function var_0_4.updateSkillContainer(arg_42_0, arg_42_1)
	local var_42_0 = arg_42_0.hero

	if arg_42_0.skillPoints < 0 then
		arg_42_0.skillPoints = 0
	end

	for iter_42_0, iter_42_1 in pairs(arg_42_0.skillItems) do
		local var_42_1 = iter_42_1:getChildByName("jiadian")

		if var_42_0:getSkillLevel(iter_42_0) ~= 0 then
			local var_42_2 = var_42_0:getSkillLevel(iter_42_0) - xyd.SKILL_EXTRA[iter_42_0]

			iter_42_1:getChildByName("lev"):setString("lv. " .. var_42_2)
			iter_42_1:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(var_42_0:getSkillLevel(iter_42_0)))
		end

		if var_42_1 then
			if var_42_0:getSkillLevel(iter_42_0) == 0 or var_42_0:getSkillLevel(iter_42_0) >= var_42_0:getSkillLimitLevel(iter_42_0) then
				var_42_1:setButtonEnabled(false)
			else
				var_42_1:setButtonEnabled(true)
			end
		end
	end
end

function var_0_4.updateIntroduceText(arg_43_0)
	local var_43_0 = arg_43_0.hero
	local var_43_1 = arg_43_0:nodeByName("jieshao_container")
	local var_43_2 = var_43_1:getChildByName("title_jieshao")
	local var_43_3 = var_43_1:getChildByName("bg")
	local var_43_4 = var_43_1:getChildren()

	if var_43_4 then
		for iter_43_0, iter_43_1 in ipairs(var_43_4) do
			if iter_43_1 ~= var_43_2 and iter_43_1 ~= var_43_3 then
				var_43_1:removeChild(iter_43_1)
			end
		end
	end

	local var_43_5 = 0

	if arg_43_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) then
		local var_43_6 = xyd.tables.hero:getHolyAttr(arg_43_0.hero:getTableID())
		local var_43_7 = display.newNode()
		local var_43_8 = 25

		var_43_5 = 60

		for iter_43_2 = 1, #var_43_6 do
			local var_43_9 = xyd.tables.petHolyAttr:icon(var_43_6[iter_43_2])

			if var_43_9 then
				local var_43_10 = xyd.AssetLoader.get():loadSprite(var_43_9)

				var_43_10:addTo(var_43_7)
				var_43_10:setPosition(cc.p(var_43_8, 25))
				var_43_10:setAnchorPoint(cc.p(0.5, 0.5))

				var_43_8 = var_43_8 + var_43_10:getContentSize().width + 8
			end
		end

		var_43_7:addTo(var_43_1)
		var_43_7:setContentSize(var_43_1:getContentSize().width, 60)
		var_43_7:setPosition(cc.p(25, 0))
		var_43_7:setAnchorPoint(cc.p(0, 0))
	end

	local var_43_11 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = 0 + var_43_5,
		color = cc.c3b(54, 54, 54),
		dimensions = cc.size(470, 54),
		text = var_43_0:getTalkText()
	}
	local var_43_12
	local var_43_13 = 0
	local var_43_14 = 0

	if var_43_0:getTalkText() then
		local var_43_15 = xyd.AssetLoader.get():loadLabel(var_43_11)

		var_43_15:addTo(var_43_1)
		var_43_15:setAnchorPoint(cc.p(0, 0))

		var_43_13 = var_43_15:getStringNumLines()
		var_43_14 = 10
	end

	local var_43_16 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = var_43_5 + var_43_13 * 30 + var_43_14,
		color = cc.c3b(235, 75, 94),
		dimensions = cc.size(470, 100),
		text = var_43_0:getDes()
	}
	local var_43_17 = xyd.AssetLoader.get():loadLabel(var_43_16)

	var_43_17:addTo(var_43_1)
	var_43_17:setAnchorPoint(cc.p(0, 0))

	local var_43_18 = var_43_17:getStringNumLines()

	var_43_3:y(var_43_16.y + var_43_18 * 30 + 20)
	var_43_2:y(var_43_16.y + var_43_18 * 30 + 20)

	local var_43_19 = var_43_2:getY()

	var_43_1:height(var_43_19 + 30)
end

function var_0_4.updateAttrLabels(arg_44_0)
	if not arg_44_0.hero then
		return
	end

	local var_44_0 = arg_44_0.hero
	local var_44_1 = 0
	local var_44_2 = arg_44_0:nodeByName("shuxing_container")
	local var_44_3 = var_44_2:getChildByName("title_shuxing")
	local var_44_4 = var_44_2:getChildByName("bg")
	local var_44_5 = var_44_2:getChildren()

	if var_44_5 then
		for iter_44_0, iter_44_1 in ipairs(var_44_5) do
			if iter_44_1 ~= var_44_3 and iter_44_1 ~= var_44_4 then
				var_44_2:removeChild(iter_44_1)
			end
		end
	end

	local var_44_6 = -33

	for iter_44_2 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if iter_44_2 ~= xyd.AttributeType.HP and iter_44_2 ~= xyd.AttributeType.HUJIA and iter_44_2 ~= xyd.AttributeType.MOKANG and iter_44_2 ~= xyd.AttributeType.REHP and var_44_0:getTotalAttr(iter_44_2) > 0 then
			var_44_1 = var_44_1 + 1

			local var_44_7 = arg_44_0:createLabel(iter_44_2)

			var_44_7:addTo(var_44_2)
			var_44_7:setPosition(20, var_44_1 * 35 + var_44_6)
		end
	end

	local var_44_8 = arg_44_0:setGrowAttrLabel(35 + var_44_1 * 35 + var_44_6)

	var_44_4:y(var_44_8 + 15)
	var_44_3:y(var_44_8 + 15)
	var_44_2:height(var_44_8 + 43)
	var_44_2:setPosition(cc.p(0, 0))
end

function var_0_4.createLabel(arg_45_0, arg_45_1)
	local var_45_0 = arg_45_0.hero
	local var_45_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_45_1:getChildByName("txt_title"):setString(xyd.tables.attr:name(arg_45_1))
	var_45_1:getChildByName("title_bg"):width(34 + var_45_1:getChildByName("txt_title"):getWidth())
	var_45_1:getChildByName("txt_ini"):setString(math.ceil(math.max(0, var_45_0:getTotalAttr(arg_45_1) - var_45_0:getEquipFumoAttr(arg_45_1) - var_45_0:getEquipAttr(arg_45_1) - var_45_0:getSkillAttr(arg_45_1) - var_45_0:getSkill2Attr(arg_45_1) - var_45_0:getTotalPracticeAttr(arg_45_1))))

	local var_45_2 = math.ceil(var_45_0:getEquipFumoAttr(arg_45_1) + var_45_0:getEquipAttr(arg_45_1) + var_45_0:getSkillAttr(arg_45_1) + var_45_0:getSkill2Attr(arg_45_1) + var_45_0:getTotalPracticeAttr(arg_45_1))

	if var_45_2 > 0 then
		var_45_1:getChildByName("txt_add"):setString("+" .. var_45_2 .. (xyd.tables.attr:suffix(arg_45_1) ~= "" and xyd.tables.attr:suffix(arg_45_1) or ""))
	else
		var_45_1:getChildByName("txt_add"):setString("")
	end

	return var_45_1
end

function var_0_4.setGrowAttrLabel(arg_46_0, arg_46_1)
	local var_46_0 = arg_46_0:nodeByName("shuxing_container")
	local var_46_1 = arg_46_0.hero
	local var_46_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_46_2:getChildByName("txt_title"):setString(var_0_11:translation("HERO_BUTTON_MINJIECHENGZHANG"))
	var_46_2:getChildByName("title_bg"):width(34 + var_46_2:getChildByName("txt_title"):getWidth())
	var_46_2:getChildByName("txt_ini"):setString(var_46_1:getAttrGlow(xyd.AttributeType.AGILE))
	var_46_2:getChildByName("txt_add"):setString("")

	local var_46_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_46_3:getChildByName("txt_title"):setString(var_0_11:translation("HERO_BUTTON_ZHILICHENGZHANG"))
	var_46_3:getChildByName("title_bg"):width(34 + var_46_3:getChildByName("txt_title"):getWidth())
	var_46_3:getChildByName("txt_ini"):setString(var_46_1:getAttrGlow(xyd.AttributeType.WISE))
	var_46_3:getChildByName("txt_add"):setString("")

	local var_46_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_46_4:getChildByName("txt_title"):setString(var_0_11:translation("HERO_BUTTON_LILIANGCHENGZHANG"))
	var_46_4:getChildByName("title_bg"):width(34 + var_46_4:getChildByName("txt_title"):getWidth())
	var_46_4:getChildByName("txt_ini"):setString(var_46_1:getAttrGlow(xyd.AttributeType.STRENGTH))
	var_46_4:getChildByName("txt_add"):setString("")
	var_46_2:addTo(var_46_0)
	var_46_2:setPosition(20, arg_46_1)
	var_46_3:addTo(var_46_0)
	var_46_3:setPosition(20, arg_46_1 + 35)
	var_46_4:addTo(var_46_0)
	var_46_4:setPosition(20, arg_46_1 + 70)

	return arg_46_1 + 110
end

function var_0_4.playActionByButton(arg_47_0, arg_47_1, arg_47_2)
	local var_47_0 = arg_47_0.containers[arg_47_0.state]
	local var_47_1 = {}

	table.insert(var_47_1, cc.ScaleTo:create(0.2, 0))
	table.insert(var_47_1, cc.CallFunc:create(function()
		local var_48_0 = {}

		table.insert(var_48_0, cc.DelayTime:create(0.1))
		table.insert(var_48_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_48_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_48_0, cc.ScaleTo:create(0.05, 1))

		if arg_47_1 == var_0_6 then
			table.insert(var_48_0, cc.CallFunc:create(function()
				arg_47_0:skillListAction(0.01, 15, 0.2)
			end))
		end

		var_47_0:hide()
		arg_47_2:scale(0)
		arg_47_2:show()
		arg_47_2:runAction(transition.sequence(var_48_0))
	end))
	var_47_0:runAction(transition.sequence(var_47_1))

	arg_47_0.state = arg_47_1

	arg_47_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.normal)
	arg_47_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.normal)
	arg_47_0:nodeByName("button_all"):setBrightStyle(ccui.BrightStyle.normal)
end

function var_0_4.clickInfoButton(arg_50_0)
	if arg_50_0.state ~= var_0_7 then
		arg_50_0:playActionByButton(var_0_7, arg_50_0.infoContainer)
		arg_50_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_50_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.clickSkillButton(arg_51_0)
	if arg_51_0.sendSkillLevUpRequest then
		arg_51_0:sendSkillLevUpRequest()
	end

	if arg_51_0.state ~= var_0_6 then
		if arg_51_0.skillList and not tolua.isnull(arg_51_0.skillList) then
			if arg_51_0.skillCount and arg_51_0.skillCount == 4 then
				arg_51_0.skillList:getScrollNode():setPositionY(-3)
			elseif arg_51_0.skillCount and arg_51_0.skillCount == 5 then
				arg_51_0.skillList:getScrollNode():setPositionY(-120)
			end
		end

		local var_51_0 = arg_51_0.containers[arg_51_0.state]
		local var_51_1 = {}

		table.insert(var_51_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_51_1, cc.CallFunc:create(function()
			local var_52_0 = {}

			table.insert(var_52_0, cc.DelayTime:create(0.1))
			table.insert(var_52_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_52_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_52_0, cc.ScaleTo:create(0.05, 1))
			table.insert(var_52_0, cc.CallFunc:create(function()
				arg_51_0:skillListAction(0.01, 15, 0.2)
			end))
			var_51_0:hide()
			arg_51_0.skillContainer:scale(0)
			arg_51_0.skillContainer:show()
			arg_51_0.skillContainer:runAction(transition.sequence(var_52_0))
		end))
		var_51_0:runAction(transition.sequence(var_51_1))

		arg_51_0.state = var_0_6

		arg_51_0:updateButtonBrightState()
	else
		arg_51_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	if arg_51_0.state == var_0_6 then
		arg_51_0:updateSkillContainer()
		arg_51_0:updateAllSkillTips()
	end
end

function var_0_4.clickMainButton(arg_54_0)
	if arg_54_0.sendSkillLevUpRequest then
		arg_54_0:sendSkillLevUpRequest()
	end

	if arg_54_0.state ~= var_0_8 then
		local var_54_0 = arg_54_0.containers[arg_54_0.state]
		local var_54_1 = {}

		table.insert(var_54_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_54_1, cc.CallFunc:create(function()
			local var_55_0 = {}

			table.insert(var_55_0, cc.DelayTime:create(0.1))
			table.insert(var_55_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_55_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_55_0, cc.ScaleTo:create(0.05, 1))
			var_54_0:hide()
			arg_54_0.mainContainer:scale(0)
			arg_54_0.mainContainer:show()
			arg_54_0.mainContainer:runAction(transition.sequence(var_55_0))
		end))
		var_54_0:runAction(transition.sequence(var_54_1))

		arg_54_0.state = var_0_8

		arg_54_0:updateButtonBrightState()
	else
		arg_54_0:nodeByName("button_all"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.clickCardButton(arg_56_0)
	if arg_56_0.sendSkillLevUpRequest then
		arg_56_0:sendSkillLevUpRequest()
	end

	if not arg_56_0.isCardShow then
		local var_56_0 = {}

		table.insert(var_56_0, cc.DelayTime:create(0.1))
		table.insert(var_56_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_56_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_56_0, cc.ScaleTo:create(0.05, 1))
		table.insert(var_56_0, cc.CallFunc:create(function()
			arg_56_0.cardBlock:show()
		end))
		arg_56_0.cardContainer:scale(0)
		arg_56_0.cardContainer:show()
		arg_56_0.cardContainer:runAction(transition.sequence(var_56_0))

		arg_56_0.isCardShow = true
	else
		local var_56_1 = {}

		table.insert(var_56_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_56_1, cc.CallFunc:create(function()
			arg_56_0.cardContainer:hide()
			arg_56_0.cardBlock:hide()
		end))
		arg_56_0.cardContainer:runAction(transition.sequence(var_56_1))

		arg_56_0.isCardShow = false
	end
end

function var_0_4.skillListAction(arg_59_0, arg_59_1, arg_59_2, arg_59_3)
	if arg_59_0.hero:isAwaken() then
		local var_59_0 = var_0_10.performWithDelayGlobal(function()
			if not xyd.WindowManager.get():getWindow("pet_main") then
				return
			end

			local var_60_0 = 120 / arg_59_2
			local var_60_1 = -120
			local var_60_2 = var_0_10.scheduleGlobal(function()
				var_60_1 = var_60_1 + var_60_0

				local var_61_0 = xyd.WindowManager.get():getWindow("pet_main")

				if var_61_0 and var_60_1 <= 0 then
					var_61_0.skillList:getScrollNode():setPositionY(var_60_1)
				elseif skillHandle then
					var_0_10.unscheduleGlobal(skillHandle)
				end
			end, arg_59_1)
		end, arg_59_3)
	end
end

function var_0_4.updateButtonBrightState(arg_62_0)
	arg_62_0:nodeByName("button_all"):setBrightStyle(arg_62_0.state == var_0_8 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_62_0:nodeByName("button_shuxing"):setBrightStyle(arg_62_0.state == var_0_7 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_62_0:nodeByName("button_jineng"):setBrightStyle(arg_62_0.state == var_0_6 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
end

function var_0_4.updateSkillItem(arg_63_0, arg_63_1, arg_63_2)
	local var_63_0 = arg_63_0.hero

	for iter_63_0, iter_63_1 in ipairs(arg_63_0.skillItems) do
		local var_63_1 = arg_63_0.skillItems[iter_63_0]

		if var_63_0:getSkillLevel(iter_63_0) ~= 0 then
			local var_63_2 = var_63_0:getSkillLevel(iter_63_0) - xyd.SKILL_EXTRA[iter_63_0]

			var_63_1:getChildByName("lev"):setString("lv. " .. var_63_2)
			var_63_1:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(var_63_0:getSkillLevel(iter_63_0)))

			if var_63_0:getExtraSkillLevel() > 0 then
				var_63_1:getChildByName("level_extra"):show()
				var_63_1:getChildByName("level_extra"):setString("+" .. var_63_0:getExtraSkillLevel())
			else
				var_63_1:getChildByName("level_extra"):hide()
			end

			var_63_1:getChildByName("jiesuo"):setVisible(false)
		else
			local var_63_3 = var_0_11:translation("HERO_JIESUO_" .. iter_63_0)

			if iter_63_0 == 5 then
				var_63_3 = var_0_11:translation("PET_AWAKE_SKILL_LOCK_TIP")
			end

			var_63_1:getChildByName("jiesuo"):setString(var_63_3)
			var_63_1:getChildByName("lev"):setVisible(false)
			var_63_1:getChildByName("level_extra"):hide()
			var_63_1:getChildByName("bookNum"):setVisible(false)
			var_63_1:getChildByName("skillBook"):setVisible(false)
		end
	end

	if not arg_63_2 and arg_63_1 then
		local var_63_4 = arg_63_0.skillItems[arg_63_1]:getChildByName("jiadian")

		if var_63_0:getSkillLevel(arg_63_1) == 0 or var_63_0:getSkillLevel(arg_63_1) >= var_63_0:getLevel() then
			var_63_4:setButtonEnabled(false)
		else
			var_63_4:setButtonEnabled(true)
		end
	end
end

function var_0_4.getHeroContainer(arg_64_0)
	if not arg_64_0.heroContainer_ then
		arg_64_0.heroContainer_ = arg_64_0:nodeByName("hero_container")

		arg_64_0.heroContainer_:setLocalZOrder(100)
	end

	return arg_64_0.heroContainer_
end

function var_0_4.updateEquip(arg_65_0, arg_65_1)
	arg_65_1 = arg_65_1 or arg_65_0.hero

	if arg_65_0.equipContainerlist_ then
		for iter_65_0, iter_65_1 in ipairs(arg_65_0.equipContainerlist_) do
			iter_65_1:removeAllNodeEventListeners()
			iter_65_1:removeSelf()
		end

		arg_65_0.equipContainerlist_ = nil
	end

	for iter_65_2 = 1, var_0_1 do
		local var_65_0 = arg_65_0:getEquipContainerByIndex(iter_65_2)
		local var_65_1 = arg_65_1:getEquipByIndex(iter_65_2)
	end
end

function var_0_4.getEquipContainerByIndex(arg_66_0, arg_66_1)
	local var_66_0 = arg_66_0.hero

	if not arg_66_0.equipContainerlist_ then
		arg_66_0.equipContainerlist_ = {}

		for iter_66_0 = 1, var_0_1 do
			local var_66_1 = arg_66_0:nodeByName("pos_node" .. iter_66_0)
			local var_66_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip.csb")

			var_66_2:setContentSize(var_66_2:getChildByName("background"):getContentSize())

			local var_66_3 = var_66_2:getContentSize()
			local var_66_4 = var_66_2:getChildByName("green_plus")
			local var_66_5 = var_66_2:getChildByName("white_plus")
			local var_66_6 = var_66_2:getChildByName("green_label")
			local var_66_7 = var_66_2:getChildByName("gray_label")

			var_66_4:setVisible(false)
			var_66_5:setVisible(false)
			var_66_7:setVisible(false)
			var_66_6:setVisible(false)
			var_66_2:setName("equip_container" .. iter_66_0)
			var_66_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_66_2:setPosition(var_66_1:getPosition())
			var_66_2:addTo(arg_66_0.mainContainer, var_66_1:getLocalZOrder())
			table.insert(arg_66_0.equipContainerlist_, var_66_2)

			local var_66_8 = var_66_0:getEquipByIndex(iter_66_0)
			local var_66_9, var_66_10 = arg_66_0.task:isActiveAwake(var_66_0:getTableID(), xyd.AwakeType.PET)

			if not var_66_8:isCollected() and (var_66_8:getTableID() == 0 or xyd.tables.item:isAwakenItem(var_66_8:getTableID()) == 1) and not var_66_0:isAwaken() and not var_66_10 then
				var_66_2:getChildByName("awake_equip_hide"):setVisible(true)

				if not arg_66_0.task:isHasAwakeOpen(xyd.AwakeType.PET) and xyd.tables.hero:isCanAwaken(var_66_0:getTableID()) == 1 and var_66_0:getLevel() >= xyd.tables.misc.awakenOpenLev then
					local var_66_11 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item2.json"
					local var_66_12 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item2.atlas"

					arg_66_0.awakeEffect = var_0_12.new(var_66_11, var_66_12, 1)

					arg_66_0.awakeEffect:addTo(var_66_2)
					arg_66_0.awakeEffect:setPosition(var_66_2:getWidth() / 2, var_66_2:getHeight() / 2)
					arg_66_0.awakeEffect:play(nil, true)
					arg_66_0.awakeEffect:setName("awake_effect")
				end
			else
				var_66_2:getChildByName("awake_equip_hide"):setVisible(false)

				local var_66_13 = var_66_8:getFumoLev()
				local var_66_14 = var_66_2:getChildByName("icon")

				xyd.setSpecialItemBorderNewUI(var_66_14, var_66_8:getTableID(), not var_66_8:isCollected())

				if not var_66_8:isCollected() and var_66_8:isInBackpack() and var_66_0:getLevel() >= var_66_8:getLevel() then
					var_66_4:setVisible(true)
					var_66_6:setString(var_0_11:translation("HERO_MAIN_HAVE_ITEM"))
					var_66_6:setVisible(true)
				elseif not var_66_8:isCollected() and var_66_8:isInBackpack() and var_66_0:getLevel() < var_66_8:getLevel() then
					var_66_5:setVisible(true)
					var_66_7:setString(var_0_11:translation("HERO_MAIN_NO_EQUIP"))
					var_66_7:setVisible(true)
				elseif not var_66_8:isCollected() and not var_66_8:isInBackpack() and var_66_8:isHasMaterial() and var_66_0:getLevel() >= var_66_8:getLevel() then
					var_66_4:setVisible(true)
					var_66_6:setString(var_0_11:translation("HERO_MAIN_CAN_COMPOSE"))
					var_66_6:setVisible(true)
				elseif not var_66_8:isCollected() and not var_66_8:isInBackpack() and var_66_8:isHasMaterial() and var_66_0:getLevel() < var_66_8:getLevel() then
					var_66_5:setVisible(true)
					var_66_7:setString(var_0_11:translation("HERO_MAIN_CAN_COMPOSE"))
					var_66_7:setVisible(true)
				elseif not var_66_8:isCollected() and not var_66_8:isInBackpack() and not var_66_8:isHasMaterial() then
					var_66_7:setString(var_0_11:translation("HERO_MAIN_NO_ITEM"))
					var_66_7:setVisible(true)
				end
			end
		end
	end

	return arg_66_0.equipContainerlist_[arg_66_1]
end

function var_0_4.updateBtnShow(arg_67_0)
	arg_67_0:nodeByName("button_linghunshi"):setVisible(false)
	arg_67_0:nodeByName("button_jinhua"):setVisible(false)
end

return var_0_4
