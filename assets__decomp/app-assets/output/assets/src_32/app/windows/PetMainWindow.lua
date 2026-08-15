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
local var_0_4 = class("PetMainWindow", import("app.common.ui.BaseWindow"))
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
		arg_4_0.heros_ = arg_4_2.heros
		arg_4_0.current_ = arg_4_2.current
		arg_4_0.hero = arg_4_0.heros_[arg_4_0.current_]
		arg_4_0.scrollx = arg_4_2.scrollx
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
	arg_5_0:updateStringLabels()

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
		arg_5_0:playGuide(var_0_2)
	end
end

function var_0_4.didOpen(arg_6_0, arg_6_1)
	var_0_4.super:didOpen(arg_6_1)
	arg_6_0:update(arg_6_0.hero)
end

function var_0_4.didClose(arg_7_0, arg_7_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	arg_7_0:unscheduleLevUpHandle()
	arg_7_0:unscheduleExpHandle()

	local var_7_0 = xyd.WindowManager.get():getWindow("pet_collect")

	if var_7_0 then
		if arg_7_0.refresh_ == true then
			var_7_0:update()
			var_7_0.heroList_:reload()
			var_7_0:scrollToHero(arg_7_0.hero.heroID_)
		elseif arg_7_0.scrollx == nil or arg_7_0.scrollx >= 0 then
			var_7_0.heroList_:scrollTo(0, 0)
		else
			var_7_0.heroList_:scrollTo(arg_7_0.scrollx, 0)
		end
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

	arg_9_0:nodeByName("borrow_container"):setVisible(false)
	arg_9_0:nodeByName("normal_container"):setVisible(true)
	arg_9_0.cardContainer:hide()
	arg_9_0.cardBlock:hide()
	arg_9_0.cardBlock:setTouchSwallowEnabled(true)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_9_0):addEventListener(xyd.event.PET_UPDATE_SKILL_BOOK, function(arg_10_0)
		arg_9_0.skillContainer:getChildByName("jinengdian"):setString(arg_9_0.selfPlayer:getBackpack():getSkillBookNum())
	end)

	arg_9_0.containers = {}

	table.insert(arg_9_0.containers, arg_9_0.mainContainer)
	table.insert(arg_9_0.containers, arg_9_0.skillContainer)
	table.insert(arg_9_0.containers, arg_9_0.infoContainer)
	table.insert(arg_9_0.containers, arg_9_0.cardContainer)

	for iter_9_0, iter_9_1 in pairs(arg_9_0.containers) do
		iter_9_1:setVisible(false)
	end

	arg_9_0.mainContainer:setVisible(true)

	local var_9_0 = arg_9_0.infoContainer:getContentSize()

	arg_9_0.state = var_0_8

	arg_9_0:nodeByName("button_all"):setBrightStyle(ccui.BrightStyle.highlight)
	arg_9_0.skillContainer:getChildByName("jinengdian"):setString(arg_9_0.selfPlayer:getBackpack():getSkillBookNum())
	arg_9_0:setupButtonClick()

	arg_9_0.infoScrollBg = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_9_0.width, var_9_0.height - 40)
	}):onScroll(handler(arg_9_0, arg_9_0.infoScrollListener)):setTouchType(true):setBounceable(true):pos(15, 20):addTo(arg_9_0.infoContainer)

	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/info_container.csb")

	arg_9_0.infoScrollBg:addScrollNode(var_9_1)
	var_9_1:setName("info_scroll_node")
	var_9_1:removeChild(var_9_1:getChildByName("background"))
	arg_9_0:parseChildren_(var_9_1)

	local var_9_2 = arg_9_0.skillContainer:getChildByName("scroll_bg")

	arg_9_0.skillList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_9_2:getWidth(), var_9_2:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_9_2):onScroll(handler(arg_9_0, arg_9_0.infoScrollListener))

	arg_9_0:updateBtnShow()
end

function var_0_4.updateStringLabels(arg_11_0)
	arg_11_0:nodeByName("title_jieshao"):setString(var_0_11:translation("PET_MAIN_TXT1"))
	arg_11_0:nodeByName("title_shuxing"):setString(var_0_11:translation("PET_MAIN_TXT2"))
	arg_11_0:nodeByName("txt_all"):setString(var_0_11:translation("PET_MAIN_TXT3"))
	arg_11_0:nodeByName("txt_shuxing"):setString(var_0_11:translation("PET_MAIN_TXT4"))
	arg_11_0:nodeByName("txt_jineng"):setString(var_0_11:translation("PET_MAIN_TXT5"))
	arg_11_0:nodeByName("txt_tujian"):setString(var_0_11:translation("PET_MAIN_TXT6"))
	arg_11_0:nodeByName("txt_luntan"):setString(var_0_11:translation("PET_MAIN_TXT7"))
	arg_11_0:nodeByName("txt_levup"):setString(var_0_11:translation("PET_MAIN_TXT8"))
	arg_11_0:nodeByName("jinjie_txt"):setString(var_0_11:translation("PET_MAIN_TXT9"))
	arg_11_0:nodeByName("yijian_txt"):setString(var_0_11:translation("PET_MAIN_TXT10"))
	arg_11_0:nodeByName("onekey_txt"):setString(var_0_11:translation("PET_MAIN_TXT11"))
	arg_11_0:nodeByName("left_skill_title"):setString(var_0_11:translation("PET_MAIN_TXT12"))
end

function var_0_4.playActions(arg_12_0)
	if not arg_12_0.actions_ then
		arg_12_0.actions_ = {}

		local var_12_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
		local var_12_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

		arg_12_0.actions_[1] = cc.RepeatForever:create(var_12_0)
		arg_12_0.actions_[2] = cc.RepeatForever:create(var_12_1)

		arg_12_0:getLastHeroArrow():runAction(arg_12_0.actions_[1])
		arg_12_0:getNextHeroArrow():runAction(arg_12_0.actions_[2])
	end
end

function var_0_4.playEffect(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5)
	local var_13_0

	arg_13_5 = arg_13_5 or false

	if arg_13_0.UIEffects[arg_13_2] and not tolua.isnull(arg_13_0.UIEffects[arg_13_2]) then
		var_13_0 = arg_13_0.UIEffects[arg_13_2]
	else
		local var_13_1 = var_0_13[arg_13_2] .. ".json"
		local var_13_2 = var_0_13[arg_13_2] .. ".atlas"

		var_13_0 = var_0_12.new(var_13_1, var_13_2, 1)

		arg_13_1:addChild(var_13_0, 10)

		arg_13_0.UIEffects[arg_13_2] = var_13_0
	end

	var_13_0:pos(arg_13_3.x, arg_13_3.y)

	if arg_13_4 == true then
		var_13_0:setToSetupPose()
		var_13_0:setVisible(true)

		if arg_13_5 then
			var_13_0:play(function()
				return
			end, true)
		else
			var_13_0:play(function()
				var_13_0:setVisible(false)
			end)
		end
	else
		var_13_0:setVisible(false)
	end
end

function var_0_4.playRepeatingEffect(arg_16_0)
	local var_16_0 = arg_16_0.hero
	local var_16_1 = true

	for iter_16_0 = 1, var_0_1 do
		local var_16_2 = var_16_0:getEquipByIndex(iter_16_0)

		if not var_16_2:isCollected() and var_16_2:getTableID() ~= 0 then
			var_16_1 = false
		end

		if var_16_0:getColor() >= xyd.tables.misc.maxPetColor then
			var_16_1 = false
		end
	end

	local var_16_3 = cc.p(arg_16_0.mainContainer:getChildByName("button_jinjie"):getPosition())

	var_16_3.x = var_16_3.x
	var_16_3.y = var_16_3.y

	arg_16_0:playEffect(arg_16_0.mainContainer, "CanUpgrade", var_16_3, var_16_1, true)

	local var_16_4 = true

	if var_16_0:getStar() >= xyd.MAX_STAR_LEVEL or var_16_0:getSuiPian() < xyd.StarLevelSuipian[var_16_0:getStar() + 1] then
		var_16_4 = false
	end

	local var_16_5 = cc.p(arg_16_0:nodeByName("button_jinhua"):getPosition())

	arg_16_0:playEffect(arg_16_0.mainContainer, "CanEvolve", var_16_5, var_16_4, true)
end

function var_0_4.getLastHeroArrow(arg_17_0)
	if not arg_17_0.lastArrow_ then
		local var_17_0 = arg_17_0:nodeByName("last_hero")

		var_17_0:setTouchEnabled(true)
		var_17_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			if arg_18_0.name == "ended" then
				arg_17_0:changeHero(true)
			end

			return true
		end)
		var_17_0:setCascadeOpacityEnabled(true)

		arg_17_0.lastArrow_ = var_17_0
	end

	return arg_17_0.lastArrow_
end

function var_0_4.getNextHeroArrow(arg_19_0)
	if not arg_19_0.nextArrow_ then
		local var_19_0 = arg_19_0:nodeByName("next_hero")

		var_19_0:setTouchEnabled(true)
		var_19_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "ended" then
				arg_19_0:changeHero(false)
			end

			return true
		end)

		arg_19_0.nextArrow_ = var_19_0

		var_19_0:setCascadeOpacityEnabled(true)
	end

	return arg_19_0.nextArrow_
end

function var_0_4.changeHero(arg_21_0, arg_21_1)
	arg_21_0:unscheduleExpHandle()

	if arg_21_0.sendSkillLevUpRequest then
		arg_21_0:sendSkillLevUpRequest()
	end

	local function var_21_0(arg_22_0)
		if arg_22_0 == false then
			if arg_21_0.current_ < #arg_21_0.heros_ then
				arg_21_0.current_ = arg_21_0.current_ + 1
			else
				arg_21_0.current_ = 1
			end
		elseif arg_21_0.current_ > 1 then
			arg_21_0.current_ = arg_21_0.current_ - 1
		else
			arg_21_0.current_ = #arg_21_0.heros_
		end

		arg_21_0.hero = arg_21_0.heros_[arg_21_0.current_]

		if not arg_21_0.hero:isCollected() or arg_21_0.hero.is_show_ == 0 then
			var_21_0(arg_21_1)
		end
	end

	if arg_21_0.scrolly then
		arg_21_0.scrolly = nil
	end

	if arg_21_0.frontState then
		arg_21_0.frontState = nil
	end

	var_21_0(arg_21_1)
	arg_21_0:update()
	arg_21_0:resetEffect()

	if arg_21_0.state == var_0_6 and arg_21_0.hero:isAwaken() then
		arg_21_0:skillListAction(0.01, 15, 0.2)
	end

	audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
end

function var_0_4.unscheduleLevUpHandle(arg_23_0)
	if arg_23_0.visibleHandler and next(arg_23_0.visibleHandler) then
		for iter_23_0, iter_23_1 in ipairs(arg_23_0.visibleHandler) do
			var_0_10.unscheduleGlobal(iter_23_1)
		end
	end
end

function var_0_4.unscheduleExpHandle(arg_24_0)
	if arg_24_0.eatHandler[var_0_17] ~= nil then
		var_0_10.unscheduleGlobal(arg_24_0.eatHandler[var_0_17])
	end

	if arg_24_0.eatHandler[var_0_18] ~= nil then
		var_0_10.unscheduleGlobal(arg_24_0.eatHandler[var_0_18])
	end

	if arg_24_0.skillTextHandle then
		var_0_10.unscheduleGlobal(arg_24_0.skillTextHandle)
	end

	if arg_24_0.skillClickHandle then
		var_0_10.unscheduleGlobal(arg_24_0.skillClickHandle)
	end
end

function var_0_4.infoScrollListener(arg_25_0, arg_25_1)
	if arg_25_1.name == "began" then
		arg_25_0.scrollViewMoved_ = false
		arg_25_0.prevX_ = arg_25_1.x
		arg_25_0.prevY_ = arg_25_1.y
	elseif arg_25_1.name == "moved" and 15 <= math.abs(arg_25_1.y - arg_25_0.prevY_) then
		arg_25_0.scrollViewMoved_ = true
	end

	local var_25_0 = arg_25_0.infoScrollBg:getScrollNode()
	local var_25_1 = 0
	local var_25_2 = -(var_25_0:getCascadeBoundingBox().height - var_25_0:getContentSize().height)

	if var_25_1 < var_25_0:getPositionX() then
		arg_25_0.infoScrollBg:scrollTo(0, var_25_1)
	elseif var_25_2 > var_25_0:getPositionX() then
		arg_25_0.infoScrollBg:scrollTo(0, var_25_2)
	end
end

function var_0_4.expScrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.scroll_is_moving = false

		arg_26_0.expScrollBg:scrollAuto()

		arg_26_0.scrollViewMoved_ = false
		arg_26_0.prevY_ = arg_26_1.y

		if arg_26_0.scroll_moving_end == true then
			arg_26_0.scroll_moving_end = false
		end
	elseif arg_26_1.name == "moved" then
		local var_26_0 = arg_26_0.expScrollBg:getScrollNode()
		local var_26_1 = 0
		local var_26_2 = -(var_26_0:getCascadeBoundingBox().height - arg_26_0.expScrollBg:getViewRectInWorldSpace().height)

		if var_26_1 < var_26_0:getPositionY() then
			arg_26_0.scroll_is_moving = true
		elseif var_26_2 > var_26_0:getPositionY() then
			arg_26_0.scroll_is_moving = true
		else
			arg_26_0.scroll_is_moving = false
		end

		arg_26_0.scrolly = var_26_0:getPositionY()

		if 5 <= math.abs(arg_26_1.y - arg_26_0.prevY_) then
			arg_26_0.scrollViewMoved_ = true
		end
	elseif arg_26_1.name == "scrollEnd" then
		arg_26_0.scrolly = arg_26_0.expScrollBg:getScrollNode():getPositionY()

		if arg_26_0.scroll_is_moving == true then
			arg_26_0.scroll_moving_end = true
			arg_26_0.scroll_is_moving = false
		end
	end
end

function var_0_4.setupButtonClick(arg_27_0)
	arg_27_0:nodeByName("button_all"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickMainButton()
		end
	end)

	local var_27_0 = arg_27_0.mainContainer:getChildByName("button_onekeyequips")

	xyd.nodeEventSample(var_27_0, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickOneKeyEquipsButton()
	end)

	local var_27_1 = arg_27_0.mainContainer:getChildByName("button_jinjie")

	xyd.nodeEventSample(var_27_1, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickJinjieButton()
	end)

	local var_27_2 = arg_27_0:nodeByName("button_jinhua")

	xyd.nodeEventSample(var_27_2, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickJinhuaButton()
	end)
	arg_27_0:nodeByName("button_shuxing"):addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickInfoButton()
		end
	end)

	local var_27_3 = arg_27_0:nodeByName("btn_tujian")

	xyd.nodeEventSample(var_27_3, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickCardButton()
	end)
	arg_27_0:nodeByName("button_jineng"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickSkillButton()
		end
	end)

	local var_27_4 = arg_27_0.mainContainer:getChildByName("button_yijian")

	xyd.nodeEventSample(var_27_4, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickYijianButton()
	end)

	local var_27_5 = arg_27_0:nodeByName("button_linghunshi")

	xyd.nodeEventSample(var_27_5, nil, function()
		if xyd.WindowManager.get():isWindowOpen("guide") then
			xyd.WindowManager.get():closeWindow("guide")
		end

		xyd.playButtonSound()
		arg_27_0:clickStoneButton()
	end)

	local var_27_6 = arg_27_0:nodeByName("button_show_detail")

	xyd.nodeEventSample(var_27_6, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickShowDetailButton()
	end)

	local var_27_7 = arg_27_0:nodeByName("button_jingyan")

	xyd.nodeEventSample(var_27_7, nil, function()
		xyd.playButtonSound()
		arg_27_0:clickAddExpButton()
	end)

	local var_27_8 = arg_27_0:nodeByName("btn_luntan")

	xyd.nodeEventSample(var_27_8, nil, function()
		xyd.playButtonSound()

		local var_39_0 = {}

		var_39_0.start_pos = 1
		var_39_0.end_pos = 50
		var_39_0.table_id = arg_27_0.hero:getTableID()

		local var_39_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)

		var_39_0.forum_type = xyd.ForumType.Pet

		var_39_1:queryForumByPage(var_39_0, function(arg_40_0, arg_40_1)
			if arg_40_0 == xyd.error.OK then
				local var_40_0 = {
					hero = arg_27_0.hero,
					forum_list = arg_40_1.comments or {}
				}

				xyd.WindowManager.get():openWindow("pet_forum", var_40_0)
			end
		end)
	end)
end

function var_0_4.clickJinjieButton(arg_41_0)
	local var_41_0 = arg_41_0.hero
	local var_41_1 = cc.p(arg_41_0:getHeroContainer():getPosition())
	local var_41_2 = arg_41_0:getHeroContainer():getContentSize()

	var_41_1.x = var_41_1.x
	var_41_1.y = var_41_1.y + var_41_2.height * 0.5

	local var_41_3 = var_41_0:getColor()
	local var_41_4 = var_41_0:getStar()
	local var_41_5 = var_41_0:getMaxHP()
	local var_41_6 = var_41_0:getZhandouli()

	local function var_41_7()
		var_41_0:powerUp(function(arg_43_0, arg_43_1)
			if arg_43_0 == xyd.error.OK then
				arg_41_0:playEffect(arg_41_0.mainContainer, "Upgrade", var_41_1, true)

				local var_43_0 = arg_41_0:getHeroModel()

				for iter_43_0 = 1, var_0_1 do
					if var_41_0:getEquipByIndex(iter_43_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_41_0:getEquipByIndex(iter_43_0):getTableID()) == 0 and not var_41_0:isLastColorHasAwakeItem() and xyd.tables.item:isAwakenItem(var_41_0:getEquipByIndex(iter_43_0):getTableID()) == 1 then
						local var_43_1 = arg_41_0:getEquipContainerByIndex(iter_43_0)
						local var_43_2 = display.newNode()

						var_43_2:size(var_43_1:getWidth(), var_43_1:getHeight())

						local var_43_3 = var_41_0:getEquipByIndex(iter_43_0, var_41_0:getColor() - 1)

						xyd.setSpecialItemBorder(var_43_2, var_43_3:getTableID())
						var_43_2:addTo(arg_41_0.mainContainer, 101)
						var_43_2:pos(var_43_1:getPosition())

						local var_43_4, var_43_5 = arg_41_0:getHeroContainer():getPosition()
						local var_43_6 = var_43_4 + arg_41_0:getHeroContainer():getWidth() / 2
						local var_43_7 = var_43_0.chestPoint.x + var_43_6
						local var_43_8 = var_43_5 + var_43_0.chestPoint.y
						local var_43_9 = cc.Spawn:create(cc.ScaleTo:create(0.8, 0.1), cc.MoveTo:create(0.8, cc.p(var_43_7, var_43_8)))

						var_43_2:runActionOnce(var_43_9, true)
					end
				end

				local var_43_10 = {}

				table.insert(var_43_10, xyd.JINJIE_ATTR_RATE * (var_41_0:getColor() - 1))
				table.insert(var_43_10, xyd.JINJIE_ATTR_RATE * (var_41_0:getColor() - 1))
				table.insert(var_43_10, xyd.JINJIE_ATTR_RATE * (var_41_0:getColor() - 1))

				arg_41_0.isShow = true

				var_43_0:win(false, handler(arg_41_0, arg_41_0.setIsShow))
				var_43_0:playAttribute(arg_41_0:getFloatAttrs(var_43_10))
				arg_41_0:updateEquip()
				arg_41_0:updateAttrScore()
				arg_41_0:updateAttrLabels()
				arg_41_0:updateIntroduceText()
				arg_41_0:updateScrollBg()
				arg_41_0:updateCollectWindow()
				arg_41_0:updateNameLabel()
				arg_41_0:setSkillContainer()
				arg_41_0:playRepeatingEffect()
				arg_41_0:updateBtnShow()
				arg_41_0:CheckOneClick()
				audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))

				arg_41_0.refresh_ = true

				local var_43_11 = var_41_0:getMaxHP()
				local var_43_12 = var_41_0:getZhandouli()
				local var_43_13 = {
					type_ = xyd.LevelUpType.ADVANCE,
					hero = var_41_0,
					vals = {
						oldStar = var_41_4,
						oldColor = var_41_3,
						newColor = var_41_3 + 1,
						oldHP = var_41_5,
						newHP = var_43_11,
						oldForce = var_41_6,
						newForce = var_43_12
					}
				}

				if arg_43_1.restore_items and #arg_43_1.restore_items > 0 then
					function var_43_13.callback()
						print(var_0_11:translation("FUMO_RESTORE_NAME"))
						xyd.WindowManager.get():openWindow("alert_award", {
							awards = arg_43_1.restore_items,
							name = var_0_11:translation("FUMO_RESTORE_NAME")
						})
					end

					for iter_43_1 = 1, #arg_43_1.restore_items do
						local var_43_14 = {
							itemID = arg_43_1.restore_items[iter_43_1].table_id,
							itemNum = arg_43_1.restore_items[iter_43_1].item_num
						}

						arg_41_0.selfPlayer:getBackpack():addItem(var_43_14)
					end
				end

				arg_41_0:runActionOnce(cc.CallFunc:create(function()
					xyd.WindowManager.get():openWindow("levelup", var_43_13)
				end), nil, nil, 1)
			end
		end)
	end

	local var_41_8 = true

	for iter_41_0 = 1, var_0_1 do
		if var_41_0:getEquipByIndex(iter_41_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_41_0:getEquipByIndex(iter_41_0):getTableID()) == 0 and var_41_0.equips_[iter_41_0] == 0 then
			var_41_8 = false

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_11:translation("CANNOT_EVOLVE")
			})

			break
		end
	end

	if var_41_0:getColor() == xyd.MAX_HERO_COLOR then
		var_41_8 = false

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("CANNOT_EVOLVE")
		})
	end

	if var_41_8 then
		if var_41_0:getFumoCount() > 0 and not var_41_0:isHaveAwakenItem() or var_41_0:getWithoutAwakeFumoCount() > 0 and var_41_0:isHaveAwakenItem() then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_11:translation("ALERT_POWER_UP1"), var_41_0:getName()),
				var_0_11:translation("ALERT_POWER_UP2")
			}, function()
				var_41_7()
			end, nil, nil, arg_41_0.colorMode)
		else
			var_41_7()
		end
	end
end

function var_0_4.update(arg_47_0, arg_47_1)
	local var_47_0 = arg_47_0.hero

	arg_47_0:getLastHeroArrow()
	arg_47_0:getNextHeroArrow()
	arg_47_0:playActions()
	arg_47_0:playRepeatingEffect()

	if arg_47_0.equipContainerlist_ then
		for iter_47_0, iter_47_1 in ipairs(arg_47_0.equipContainerlist_) do
			iter_47_1:removeAllNodeEventListeners()
			iter_47_1:removeSelf()
		end

		arg_47_0.equipContainerlist_ = nil
	end

	for iter_47_2 = 1, var_0_1 do
		local var_47_1 = arg_47_0:getEquipContainerByIndex(iter_47_2)
		local var_47_2 = var_47_0:getEquipByIndex(iter_47_2)

		var_47_1:setTouchEnabled(true)
		var_47_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_48_0)
			if arg_48_0.name == "ended" then
				local var_48_0
				local var_48_1, var_48_2 = arg_47_0.task:isActiveAwake(var_47_0:getTableID(), xyd.AwakeType.PET)

				if not var_48_1 then
					var_48_0 = false
					var_48_1 = xyd.tables.mission:getMissionIDByTableIDAndStage(var_47_0:getTableID(), 1)
				else
					var_48_0 = true
				end

				local function var_48_3(arg_49_0)
					local var_49_0 = {
						table_id = arg_49_0.missionID
					}

					xyd.Backend.get():request(xyd.mid.OPEN_PET_AWAKE_MISSION, var_49_0, function(arg_50_0)
						if arg_50_0 == xyd.error.OK then
							local var_50_0 = xyd.WindowManager.get():getWindow("pet_main")

							if var_50_0 and not tolua.isnull(var_50_0) then
								var_50_0:update()

								var_50_0.refresh_ = true
							end
						end
					end)
				end

				if var_48_2 or var_47_2:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_47_2:getTableID()) == 0 or var_47_0:isAwaken() then
					arg_47_0:showItemDetail(iter_47_2)
				elseif var_47_0:getLevel() < xyd.tables.misc.awakenOpenLev then
					local var_48_4 = {
						txt = var_0_11:translation("PET_AWAKE_CAN_NOT_OPEN"),
						type = xyd.CommonAlertType.ONE_BTN,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_48_4)
				elseif var_47_2:getTableID() == 0 or xyd.tables.hero:isCanAwaken(var_47_0:getTableID()) == 0 and xyd.tables.item:isAwakenItem(var_47_2:getTableID()) == 1 then
					local var_48_5 = {
						txt = var_0_11:translation("PET_AWAKE_MISSION_NOT_EXIST"),
						type = xyd.CommonAlertType.ONE_BTN,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_48_5)
				elseif arg_47_0.task:isHasAwakeOpen(xyd.AwakeType.PET) then
					local var_48_6 = {
						txt = var_0_11:translation("CAN_NOT_OPEN_AWAKE_MISSION"),
						type = xyd.CommonAlertType.ONE_BTN,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_48_6)
				elseif var_48_0 then
					local var_48_7 = {
						txt = string.format(var_0_11:translation("OPEN_AWAKE_MISSION_AGAIN"), var_47_0:getName()),
						type = xyd.CommonAlertType.TWO_BTN,
						rcallback = var_48_3,
						align = xyd.ui_align.CENTER,
						callbackParams = {
							missionID = var_48_1
						}
					}

					xyd.WindowManager.get():openWindow("common_alert", var_48_7)
				else
					local var_48_8 = {
						txt = string.format(var_0_11:translation("FIRST_TIME_OPEN_AWAKE_MISSION"), var_47_0:getName()),
						type = xyd.CommonAlertType.TWO_BTN,
						rcallback = var_48_3,
						align = xyd.ui_align.CENTER,
						callbackParams = {
							missionID = var_48_1
						}
					}

					xyd.WindowManager.get():openWindow("common_alert", var_48_8)
				end
			end

			return true
		end)
	end

	if arg_47_0.heroModel_ then
		arg_47_0.heroModel_:removeSelf()

		arg_47_0.heroModel_ = nil
	end

	local var_47_3 = arg_47_1 or arg_47_0.hero

	arg_47_0:updateHeroModel(var_47_3)
	arg_47_0:updateAttrScore()
	arg_47_0:updateExp()
	arg_47_0:updateHeroStar()
	arg_47_0:updateCard()
	arg_47_0:updateHomeCard()
	arg_47_0:updateAttrLabels()
	arg_47_0:updateIntroduceText()
	arg_47_0:updateScrollBg()
	arg_47_0:setSkillContainer()
	arg_47_0:updateNameLabel()
	arg_47_0:CheckOneClick()
	arg_47_0:updateBtnShow()
end

function var_0_4.updateNameLabel(arg_51_0)
	arg_51_0.nameLabelContainer:removeAllChildren()

	local var_51_0 = arg_51_0.hero
	local var_51_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/hero_label.csb")

	var_51_1:addTo(arg_51_0.nameLabelContainer)

	local var_51_2 = var_51_1:getChildByName("bg")
	local var_51_3 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_" .. xyd.Color2Quality[var_51_0:getColor()] .. ".png")

	var_51_3:addTo(var_51_2:getChildByName("bg_name"))
	var_51_3:setAnchorPoint(0, 0)

	local var_51_4

	if arg_51_0.hero:isAwaken() then
		if arg_51_0.hero:isAwakeTwice() then
			var_51_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake_twice.png")
		else
			var_51_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake.png")
		end

		var_51_4:addTo(var_51_2:getChildByName("bg_awake"))
		var_51_4:setAnchorPoint(0, 0)
	end

	local var_51_5 = xyd.AssetLoader.get():loadSprite("windows/hero/quality_" .. var_51_0:getColor() .. ".png")
	local var_51_6 = arg_51_0.hero:getInscriptionKuangLevel()

	if var_51_6 then
		var_51_5 = xyd.AssetLoader.get():loadSprite("windows/hero/suit_" .. var_51_6 .. ".png")

		var_51_2:getChildByName("bg_name"):removeAllChildren()

		local var_51_7 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_suit.png")

		var_51_7:addTo(var_51_2:getChildByName("bg_name"))
		var_51_7:setAnchorPoint(0, 0)
	end

	var_51_5:setAnchorPoint(0.5, 0.5)
	var_51_5:addTo(var_51_2:getChildByName("quality"))
	var_51_2:getChildByName("name"):setString(var_51_0:getName())

	for iter_51_0 = 1, xyd.HERO_TOTAL_STARS do
		local var_51_8 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

		var_51_2:getChildByName("star_" .. iter_51_0):setSpriteFrame(var_51_8:getSpriteFrame())
		var_51_2:getChildByName("star_" .. iter_51_0):setVisible(iter_51_0 <= var_51_0:getStar())
	end
end

function var_0_4.updateCard(arg_52_0)
	arg_52_0.cardContainer:removeAllChildren()
	arg_52_0.cardBlock:removeAllChildren()

	local var_52_0 = display.newNode()

	var_52_0:setContentSize(arg_52_0.cardBlock:getContentSize())
	var_52_0:addTo(arg_52_0.cardBlock)
	var_52_0:setTouchEnabled(true)
	var_52_0:setTouchSwallowEnabled(true)
	var_52_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_53_0)
		if arg_53_0.name == "ended" then
			if not arg_52_0.card or not arg_52_0.isCardShow then
				return
			end

			arg_52_0:clickCardButton()
		end

		return true
	end)

	local function var_52_1(arg_54_0)
		if arg_54_0 == xyd.CardStatus.SKIN_CARD then
			if arg_52_0.hero.isSkinOn_ == 1 then
				return true
			else
				return false
			end
		elseif arg_54_0 == xyd.CardStatus.AWAKE_CARD then
			if arg_52_0.hero:isAwaken() then
				return true
			else
				return false
			end
		elseif arg_54_0 == xyd.CardStatus.NORMAL_CARD then
			return true
		end
	end

	if not arg_52_0.frontState then
		if arg_52_0.hero.isSkinOn_ == 1 then
			arg_52_0.frontState = xyd.CardStatus.SKIN_CARD
		elseif arg_52_0.hero:isAwaken() then
			arg_52_0.frontState = xyd.CardStatus.AWAKE_CARD
		else
			arg_52_0.frontState = xyd.CardStatus.NORMAL_CARD
		end

		arg_52_0.backState = arg_52_0.frontState + 1
	else
		arg_52_0.frontState = arg_52_0.backState
		arg_52_0.backState = arg_52_0.backState + 1
	end

	while not var_52_1(arg_52_0.backState) do
		if arg_52_0.backState > 3 then
			arg_52_0.backState = 1
		else
			arg_52_0.backState = arg_52_0.backState + 1
		end
	end

	local var_52_2 = xyd.getPetCard(arg_52_0.hero, arg_52_0.frontState, arg_52_0.backState)

	var_52_2:addTo(arg_52_0.cardContainer)

	arg_52_0.card = var_52_2

	var_52_2:align(display.CENTER, var_52_2:getWidth() / 2, var_52_2:getHeight() / 2)
	var_52_2:setTouchEnabled(true)
	var_52_2:setTouchSwallowEnabled(true)
	var_52_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_55_0)
		if arg_55_0.name == "ended" then
			if not arg_52_0.card or not arg_52_0.isCardShow then
				return
			end

			arg_52_0:clickCardButton()
		end

		return true
	end)
	arg_52_0.card:scale(xyd.STAGE_HEIGHT / arg_52_0.card:getWidth())
	arg_52_0.card:setRotation(-90)
	arg_52_0.card:setPosition(xyd.STAGE_WIDTH / 2 - 128.31, xyd.STAGE_HEIGHT / 2)
end

function var_0_4.updateHomeCard(arg_56_0)
	if not arg_56_0 or tolua.isnull(arg_56_0) or not arg_56_0.homeCardContainer or tolua.isnull(arg_56_0.homeCardContainer) then
		return
	end

	arg_56_0.homeCardContainer:removeAllChildren()

	local var_56_0 = xyd.getTransparentCard(arg_56_0.hero)

	if not var_56_0 then
		return
	end

	arg_56_0.homeCardContainer:addChild(var_56_0)
	var_56_0:setPosition(arg_56_0.homeCardContainer:getWidth() / 2, 0)
	var_56_0:setAnchorPoint(cc.p(0.5, 0))
	var_56_0:setTouchEnabled(false)
end

function var_0_4.cardRolling(arg_57_0, arg_57_1)
	local function var_57_0()
		arg_57_0.isFrontOut = not arg_57_0.isFrontOut
		arg_57_0.canSwitchCard = true
	end

	local function var_57_1()
		local var_59_0 = arg_57_0.card:getChildByName("container"):getChildByName("cardFront")
		local var_59_1 = arg_57_0.card:getChildByName("container"):getChildByName("cardBack")

		if arg_57_0.isFrontOut then
			var_59_0:setVisible(true)
			var_59_1:setVisible(false)
		else
			var_59_0:setVisible(false)
			var_59_1:setVisible(true)
		end

		arg_57_0:updateCard()
	end

	local var_57_2 = cc.OrbitCamera:create(arg_57_1, 1, 0, 0, 90, 0, 0)
	local var_57_3 = cc.OrbitCamera:create(arg_57_1, 1, 0, 270, 90, 0, 0)
	local var_57_4 = cc.CallFunc:create(var_57_1)
	local var_57_5 = cc.CallFunc:create(var_57_0)
	local var_57_6 = cc.Sequence:create(var_57_2, var_57_4, var_57_3, var_57_5)

	arg_57_0.card:runAction(var_57_6)
end

function var_0_4.updateHeroStar(arg_60_0)
	local var_60_0 = arg_60_0.hero
	local var_60_1 = arg_60_0:nodeByName("bar")
	local var_60_2
	local var_60_3

	if var_60_0:getStar() >= xyd.MAX_STAR_LEVEL then
		var_60_2 = 100
		var_60_3 = var_0_11:translation("HERO_MAIN_MAX_STAR")
	else
		var_60_2 = math.min(var_60_0:getSuiPian() / xyd.StarLevelSuipian[var_60_0:getStar() + 1] * 100, 100)
		var_60_3 = var_60_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_60_0:getStar() + 1]
	end

	var_60_1:setPercent(var_60_2)
	arg_60_0:nodeByName("bar_text"):setString(var_60_3)

	for iter_60_0 = 1, xyd.HERO_TOTAL_STARS do
		arg_60_0.mainContainer:getChildByName("hero_star" .. iter_60_0):setVisible(iter_60_0 <= var_60_0:getStar())
	end
end

function var_0_4.updateExp(arg_61_0, arg_61_1)
	arg_61_1 = arg_61_1 or arg_61_0.hero

	arg_61_0:nodeByName("lev_txt"):setString(arg_61_1:getLevel())

	local var_61_0 = arg_61_1:getExp() - xyd.tables.petExp:totalExp(arg_61_1:getLevel() - 1)

	arg_61_0:nodeByName("exp_txt"):setString(var_61_0 .. " / " .. arg_61_1:getAddExp())
end

function var_0_4.playEatExpEffect(arg_62_0, arg_62_1)
	local var_62_0 = arg_62_0:getHeroContainer():getContentSize().width
	local var_62_1 = arg_62_0:getHeroContainer():getContentSize().height
	local var_62_2 = xyd.tables.sound:getSound("train_exp_up")

	audio.playSound(var_62_2, false)

	if not arg_62_0.eatExpEffect then
		local var_62_3 = var_0_13.LevelUp .. ".json"
		local var_62_4 = var_0_13.LevelUp .. ".atlas"

		arg_62_0.eatExpEffect = var_0_12.new(var_62_3, var_62_4, 1)

		arg_62_0.eatExpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_62_0.eatExpEffect:setPosition(0, var_62_1 / 2)
		arg_62_0.eatExpEffect:addTo(arg_62_0:getHeroContainer())
	end

	arg_62_0.eatExpEffect:play(nil, false)

	local var_62_5 = arg_62_1:getChildByName("item"):getContentSize().width
	local var_62_6 = arg_62_1:getChildByName("item"):getContentSize().height
	local var_62_7, var_62_8 = arg_62_1:getChildByName("item"):getPosition()

	if arg_62_0.clickEffect and not tolua.isnull(arg_62_0.clickEffect) then
		arg_62_0.clickEffect:removeAllChildren()
	end

	local var_62_9 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_62_10 = var_62_9 .. ".json"
	local var_62_11 = var_62_9 .. ".atlas"

	arg_62_0.clickEffect = var_0_12.new(var_62_10, var_62_11, 1)

	arg_62_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_62_0.clickEffect:setPosition(var_62_7 + var_62_5 / 2, var_62_8 + var_62_6 / 2)
	arg_62_1:addChild(arg_62_0.clickEffect)
	arg_62_0.clickEffect:setScale(0.7)
	arg_62_0.clickEffect:play(nil, false)
end

function var_0_4.playLevelUpEffect(arg_63_0, arg_63_1)
	local var_63_0 = arg_63_0:getHeroContainer():getContentSize().width
	local var_63_1 = arg_63_0:getHeroContainer():getContentSize().height
	local var_63_2 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_63_2, false)

	if arg_63_0.levelUpEffect == nil then
		local var_63_3 = var_0_13.Evolve .. ".json"
		local var_63_4 = var_0_13.Evolve .. ".atlas"

		arg_63_0.levelUpEffect = var_0_12.new(var_63_3, var_63_4, 1)

		arg_63_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_63_0.levelUpEffect:setPosition(var_63_0 / 2, var_63_1 / 2)
		arg_63_0.levelUpEffect:addTo(arg_63_0:getHeroContainer())
	end

	arg_63_0.levelUpEffect:play(nil, false)

	if arg_63_0.levelUpSprite == nil then
		arg_63_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

		arg_63_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
		arg_63_0.levelUpSprite:setPosition(var_63_0 / 2, var_63_1 / 2)
		arg_63_0.levelUpSprite:addTo(arg_63_0:getHeroContainer())
	end

	arg_63_0.levelUpSprite:setPosition(var_63_0 / 2, var_63_1 / 2)
	arg_63_0.levelUpSprite:setVisible(true)
	arg_63_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1, cc.p(var_63_0 / 2, var_63_1 / 2 + 100)), false, function()
		arg_63_0.levelUpSprite:setVisible(false)
	end)

	local var_63_5 = arg_63_1:getChildByName("item"):getContentSize().width
	local var_63_6 = arg_63_1:getChildByName("item"):getContentSize().height
	local var_63_7, var_63_8 = arg_63_1:getChildByName("item"):getPosition()

	if arg_63_0.clickEffect and not tolua.isnull(arg_63_0.clickEffect) then
		arg_63_0.clickEffect:removeAllChildren()
	end

	local var_63_9 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_63_10 = var_63_9 .. ".json"
	local var_63_11 = var_63_9 .. ".atlas"

	arg_63_0.clickEffect = var_0_12.new(var_63_10, var_63_11, 1)

	arg_63_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_63_0.clickEffect:setPosition(var_63_7 + var_63_5 / 2, var_63_8 + var_63_6 / 2)
	arg_63_1:addChild(arg_63_0.clickEffect)
	arg_63_0.clickEffect:setScale(0.7)
	arg_63_0.clickEffect:play(nil, false)
end

function var_0_4.resetEffect(arg_65_0)
	if arg_65_0.clickEffect then
		arg_65_0.clickEffect = nil
	end

	if arg_65_0.levelUpSprite then
		arg_65_0.levelUpSprite = nil
	end

	if arg_65_0.levelUpEffect then
		arg_65_0.levelUpEffect = nil
	end

	if arg_65_0.eatExpEffect then
		arg_65_0.eatExpEffect = nil
	end
end

function var_0_4.updateScrollBg(arg_66_0)
	local var_66_0 = arg_66_0.infoScrollBg:getViewRect()
	local var_66_1 = arg_66_0:nodeByName("shuxing_container")
	local var_66_2 = arg_66_0:nodeByName("jieshao_container")
	local var_66_3 = var_66_1:getContentSize().height
	local var_66_4 = var_66_2:getContentSize().height

	var_66_2:setPosition(cc.p(0, var_66_3))
	var_66_1:setPosition(cc.p(0, 0))
	arg_66_0.infoScrollBg:setScrollWidth(var_66_0.width)
	arg_66_0.infoScrollBg:setScrollHeight(var_66_3 + var_66_4)
	arg_66_0.infoScrollBg:scrollTo(0, var_66_0.height - var_66_3 - var_66_4)
end

function var_0_4.updateAttrScore(arg_67_0, arg_67_1)
	arg_67_1 = arg_67_1 or arg_67_0.hero

	local var_67_0 = arg_67_1:getZhandouli()

	arg_67_0:nodeByName("zhandouli_txt"):setString(var_67_0)
end

function var_0_4.updateHeroModel(arg_68_0, arg_68_1)
	local var_68_0 = arg_68_1:getTableID()
	local var_68_1 = arg_68_0:getHeroModel()

	if not var_68_1 then
		return
	end

	var_68_1:setTouchSwallowEnabled(false)

	arg_68_0.modelState = xyd.ModelState.Walk

	local var_68_2 = arg_68_0:getHeroContainer():getContentSize().width / 2

	var_68_1:setPosition(cc.p(var_68_2, 0))
	arg_68_0:getHeroContainer():removeAllChildren()
	var_68_1:addTo(arg_68_0:getHeroContainer())
	var_68_1:setTouchEnabled(true)

	arg_68_0.isShow = false

	arg_68_0:getHeroContainer():addTouchEventListener(function(arg_69_0, arg_69_1)
		if arg_69_1 == ccui.TouchEventType.ended and not arg_68_0.isShow then
			arg_68_0:resetModelState()
		end
	end)
end

function var_0_4.setIsShow(arg_70_0)
	arg_70_0.isShow = false

	arg_70_0:getHeroModel():idle()
end

function var_0_4.resetModelState(arg_71_0)
	local var_71_0 = arg_71_0:getHeroModel()

	if arg_71_0.modelState == 6 then
		arg_71_0.modelState = arg_71_0.modelState + 1
	end

	arg_71_0.modelState = arg_71_0.modelState % 6
	arg_71_0.isShow = true

	local var_71_1

	if arg_71_0.modelState == xyd.ModelState.Walk then
		var_71_0:walk(true)

		arg_71_0.isShow = false
		var_71_1 = xyd.tables.model:getMoveSound(arg_71_0.hero:getModelID())
	elseif arg_71_0.modelState == xyd.ModelState.Win then
		var_71_0:win(false, handler(arg_71_0, arg_71_0.setIsShow))

		var_71_1 = xyd.tables.model:getWinSound(arg_71_0.hero:getModelID())
	elseif arg_71_0.modelState == xyd.ModelState.Attack1 then
		var_71_0:attack(1, nil, nil, handler(arg_71_0, arg_71_0.setIsShow))

		var_71_1 = xyd.tables.model:getNormalAttackSound(arg_71_0.hero:getModelID())
	elseif arg_71_0.modelState == xyd.ModelState.Attack2 then
		var_71_0:attack(2, nil, nil, handler(arg_71_0, arg_71_0.setIsShow))

		var_71_1 = xyd.tables.model:getAttack1Sound(arg_71_0.hero:getModelID())
	elseif arg_71_0.modelState == xyd.ModelState.Attack3 then
		var_71_0:attack(3, nil, nil, handler(arg_71_0, arg_71_0.setIsShow))

		var_71_1 = xyd.tables.model:getAttack2Sound(arg_71_0.hero:getModelID())
	elseif arg_71_0.modelState == xyd.ModelState.Attack4 then
		var_71_0:attack(4, nil, nil, handler(arg_71_0, arg_71_0.setIsShow))

		var_71_1 = xyd.tables.model:getAttack4Sound(arg_71_0.hero:getModelID())
	else
		arg_71_0:setIsShow()
	end

	if var_71_1 then
		audio.stopAllSounds()
		audio.playSound(var_71_1, false)
	end

	arg_71_0.modelState = arg_71_0.modelState + 1
end

function var_0_4.getHeroModel(arg_72_0)
	if not arg_72_0.heroModel_ then
		if arg_72_0.hero then
			arg_72_0.heroModel_ = arg_72_0.hero:getHeroModel()
		else
			return false
		end
	end

	return arg_72_0.heroModel_
end

function var_0_4.setSkillContainer(arg_73_0, arg_73_1)
	arg_73_1 = arg_73_1 or arg_73_0.hero

	local var_73_0 = arg_73_1:getSkillId()

	arg_73_0.skillItems = {}

	arg_73_0.skillList:removeAllItems()

	local var_73_1 = 0
	local var_73_2 = 0

	for iter_73_0, iter_73_1 in ipairs(var_73_0) do
		if iter_73_0 == xyd.SKILL_INDEX.AwakeTwice then
			break
		end

		local var_73_3 = iter_73_1 == 0 or xyd.tables.skill:isAwakenSkill(iter_73_1) > 0

		if xyd.tables.hero:isCanAwaken(arg_73_1:getTableID()) > 0 and arg_73_0.selfPlayer.maxTeamLev >= 90 or not var_73_3 then
			local var_73_4 = display.newNode()
			local var_73_5 = arg_73_0.skillList:newItem()
			local var_73_6 = xyd.tables.skill:icon(iter_73_1)
			local var_73_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/skill_item.csb")
			local var_73_8 = xyd.SpriteLoader.new(var_73_6, nil, nil, xyd.DefaultImageType.SKILL_ICON)
			local var_73_9 = var_73_7:getChildByName("background"):getContentSize()

			var_73_7:setContentSize(var_73_9)
			var_73_4:setContentSize(var_73_9)

			local var_73_10 = var_73_7:getChildByName("icon")
			local var_73_11 = var_73_7:getChildByName("border"):getChildByName("skill_hide")

			if not var_73_3 or arg_73_1:isAwaken() then
				var_73_7:getChildByName("lev"):setVisible(true)
				var_73_7:getChildByName("level_extra"):setVisible(true)
				var_73_11:setVisible(false)

				if arg_73_1:getSkillLevel(iter_73_0) and arg_73_1:getSkillLevel(iter_73_0) > 0 then
					var_73_7:getChildByName("skillBook"):setVisible(true)
					var_73_7:getChildByName("bookNum"):setVisible(true)
					var_73_7:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(arg_73_1:getSkillLevel(iter_73_0)))
				else
					var_73_7:getChildByName("skillBook"):setVisible(false)
					var_73_7:getChildByName("bookNum"):setVisible(false)
				end

				local var_73_12 = xyd.AssetLoader:get():loadSprite("windows/pet/petMainWindow/skill_icon_mask.png")

				var_73_12:setPosition(var_73_10:getWidth() / 2, var_73_10:getHeight() / 2)
				var_73_12:setAnchorPoint(cc.p(0.5, 0.5))
				var_73_12:scale(var_73_10:getWidth() / var_73_12:getWidth())

				local var_73_13 = cc.ClippingNode:create()

				var_73_13:setStencil(var_73_12)
				var_73_13:setInverted(true)
				var_73_13:setAlphaThreshold(0)
				var_73_10:addChild(var_73_13)
				var_73_13:addChild(var_73_8)
				var_73_8:align(display.LEFT_BOTTOM, 0, 0)
				var_73_8:scale((var_73_10:getWidth() - 3) / var_73_8:getWidth())

				local var_73_14 = cc.ui.UIPushButton.new({
					pressed = "windows/pet/petMainWindow/btn_plus.png",
					disabled = "windows/pet/petMainWindow/btn_plus_white.png",
					normal = "windows/pet/petMainWindow/btn_plus.png"
				})

				var_73_14:setAnchorPoint(cc.p(0.5, 0.5))
				var_73_14:setPosition(var_73_7:getChildByName("btn_pos"):getPosition())
				var_73_14:addTo(var_73_7)
				var_73_14:setName("jiadian")

				if arg_73_1:getSkillLevel(iter_73_0) ~= 0 then
					local var_73_15 = arg_73_1:getSkillLevel(iter_73_0) - xyd.SKILL_EXTRA[iter_73_0]

					var_73_7:getChildByName("lev"):setString("lv. " .. var_73_15)

					if arg_73_1:getExtraSkillLevel() > 0 then
						var_73_7:getChildByName("level_extra"):show()
						var_73_7:getChildByName("level_extra"):setString("+" .. arg_73_1:getExtraSkillLevel())
					else
						var_73_7:getChildByName("level_extra"):hide()
					end

					var_73_7:getChildByName("jiesuo"):setVisible(false)
				else
					local var_73_16 = var_0_11:translation("HERO_JIESUO_" .. iter_73_0)

					var_73_7:getChildByName("jiesuo"):setString(var_73_16)
					var_73_7:getChildByName("lev"):setVisible(false)
					var_73_7:getChildByName("level_extra"):hide()
				end

				if arg_73_1:getSkillLevel(iter_73_0) == 0 or arg_73_1:getSkillLevel(iter_73_0) >= arg_73_1:getSkillLimitLevel(iter_73_0) then
					var_73_14:setButtonEnabled(false)
				else
					var_73_14:setButtonEnabled(true)

					local var_73_17 = false

					arg_73_0.isCanLongTouchSkill = true

					var_73_14:onButtonPressed(function(arg_74_0)
						local var_74_0 = 0

						arg_73_0.skillCount = 0

						local function var_74_1()
							var_74_0 = var_74_0 + 0.2

							if var_74_0 > 0.6 then
								if not var_73_17 then
									var_73_17 = true
								end

								if arg_73_0.addSkillLevel and arg_73_0.isCanLongTouchSkill then
									arg_73_0:addSkillLevel(iter_73_0)
								end
							end
						end

						var_73_17 = false
						arg_73_0.skillClickHandle = var_0_10.scheduleGlobal(var_74_1, 0.2)
					end)
					var_73_14:onButtonRelease(function(arg_76_0)
						if arg_73_1:getSkillLevel(iter_73_0) == 0 or arg_73_1:getSkillLevel(iter_73_0) >= arg_73_1:getSkillLimitLevel(iter_73_0) then
							var_73_14:setButtonEnabled(false)
						else
							var_73_14:setButtonEnabled(true)
						end

						if arg_73_0.skillClickHandle then
							var_0_10.unscheduleGlobal(arg_73_0.skillClickHandle)
						end

						if not var_73_17 then
							arg_73_0:addSkillLevel(iter_73_0)
						end
					end)
				end
			else
				var_73_11:setVisible(true)
				var_73_7:getChildByName("lev"):setVisible(false)
				var_73_7:getChildByName("skillBook"):setVisible(false)
				var_73_7:getChildByName("bookNum"):setVisible(false)
				var_73_7:getChildByName("level_extra"):setVisible(false)
				var_73_7:getChildByName("jiesuo"):setString(var_0_11:translation("PET_AWAKE_SKILL_LOCK_TIP"))
			end

			var_73_7:getChildByName("name"):setString(xyd.tables.skill:name(iter_73_1))
			var_73_7:addTo(var_73_4)
			table.insert(arg_73_0.skillItems, var_73_7)
			var_73_5:addContent(var_73_4)
			var_73_5:setItemSize(var_73_4:getWidth(), var_73_4:getHeight() + 6)
			arg_73_0.skillList:addItem(var_73_5)

			var_73_1 = var_73_1 + 1
			var_73_2 = var_73_2 + xyd.tables.petSkillBook:getBookNum(arg_73_1:getSkillLevel(iter_73_0))

			arg_73_0:createSkillTip(iter_73_0, iter_73_1)
		end
	end

	if var_73_1 < 5 then
		arg_73_0.skillList:setBounceable(false)
	else
		arg_73_0.skillList:setBounceable(true)
	end

	arg_73_0.skillCount = var_73_1

	arg_73_0.skillList:reload()
end

function var_0_4.addSkillLevel(arg_77_0, arg_77_1)
	local var_77_0 = arg_77_0.hero

	if not arg_77_0.skillBook then
		arg_77_0.skillBook = 0
	end

	if var_77_0:getSkillLevel(arg_77_1) >= var_77_0:getSkillLimitLevel(arg_77_1) then
		local var_77_1 = var_0_11:translation("SKILL_UP_LIMIT")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_77_1
		})

		if arg_77_0.skillClickHandle then
			var_0_10.unscheduleGlobal(arg_77_0.skillClickHandle)
		end

		return
	elseif arg_77_0.selfPlayer:getBackpack():getSkillBookNum() < arg_77_0.skillBook + xyd.tables.petSkillBook:getBookNum(var_77_0:getSkillLevel(arg_77_1)) then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("PET_NO_SKILL_BOOK")
		})

		return
	else
		arg_77_0.skillBook = arg_77_0.skillBook + xyd.tables.petSkillBook:getBookNum(var_77_0:getSkillLevel(arg_77_1))

		arg_77_0:playSKillUpEffect(arg_77_1)
		audio.playSound(xyd.tables.sound:getSound("hero_upskill"))

		var_77_0.skillLev_[arg_77_1] = var_77_0.skillLev_[arg_77_1] + 1

		arg_77_0:updateAttrScore()
		arg_77_0:updateSkillItem(arg_77_1, true)
		arg_77_0:updateSkillContainer(true)

		if arg_77_0.skillLevel[arg_77_1] then
			arg_77_0.skillLevel[arg_77_1] = arg_77_0.skillLevel[arg_77_1] + 1
		else
			arg_77_0.skillLevel[arg_77_1] = 1
		end

		arg_77_0.skillPoints = arg_77_0.skillPoints - xyd.tables.petSkillBook:getBookNum(var_77_0:getSkillLevel(arg_77_1) - 1)

		arg_77_0.skillContainer:getChildByName("jinengdian"):setString(arg_77_0.skillPoints)
		arg_77_0:CheckOneClick()
	end
end

function var_0_4.sendSkillLevUpRequest(arg_78_0)
	if not arg_78_0.skillLevel or not next(arg_78_0.skillLevel) then
		return
	end

	local var_78_0 = {}
	local var_78_1 = {}

	for iter_78_0, iter_78_1 in pairs(arg_78_0.skillLevel) do
		table.insert(var_78_0, iter_78_0)
		table.insert(var_78_1, iter_78_1)
	end

	arg_78_0.hero:skilllevelUp(var_78_0, function(arg_79_0)
		if arg_79_0 == xyd.error.OK then
			arg_78_0.refresh_ = true
		end

		if arg_78_0.skillLevel then
			arg_78_0.skillLevel = {}
		end

		arg_78_0.skillBook = 0
	end, var_78_1)
end

function var_0_4.playSKillUpEffect(arg_80_0, arg_80_1)
	local var_80_0 = arg_80_0.hero

	local function var_80_1(arg_81_0)
		local var_81_0 = {}
		local var_81_1 = xyd.tables.skill:desc3(arg_81_0)
		local var_81_2 = xyd.tables.skill:descNumStep(arg_81_0)

		for iter_81_0 = 1, #var_81_1 do
			local var_81_3 = ""

			var_81_1[iter_81_0] = string.gsub(var_81_1[iter_81_0], "%%d%%", "%%d@")

			local var_81_4 = tonumber(var_81_2[iter_81_0])

			if var_81_4 - math.floor(var_81_4) ~= 0 then
				var_81_1[iter_81_0] = string.gsub(var_81_1[iter_81_0], "%%d", "%%.1f")
			end

			local var_81_5 = var_81_3 .. string.format(var_81_1[iter_81_0], var_81_4)
			local var_81_6 = string.gsub(var_81_5, "@", "%%")

			table.insert(var_81_0, var_81_6)
		end

		return var_81_0
	end

	local var_80_2 = var_0_13.LevelUp .. ".json"
	local var_80_3 = var_0_13.LevelUp .. ".atlas"
	local var_80_4 = var_0_12.new(var_80_2, var_80_3, 1)
	local var_80_5, var_80_6 = arg_80_0.skillItems[arg_80_1]:getChildByName("icon"):getPosition()
	local var_80_7 = arg_80_0.skillItems[arg_80_1]:getChildByName("icon"):getWidth()
	local var_80_8 = arg_80_0.skillItems[arg_80_1]:getChildByName("icon"):getHeight()

	var_80_4:setPosition(var_80_5 - var_80_7 / 2, var_80_6 + var_80_8 / 2)
	var_80_4:addTo(arg_80_0.skillItems[arg_80_1])
	var_80_4:play(nil, false)

	local var_80_9 = arg_80_0.skillItems[arg_80_1]:getWidth()
	local var_80_10 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c4b(255, 255, 0, 0),
		dimensions = cc.size(var_80_9 - 10, 0)
	}
	local var_80_11 = var_80_1(var_80_0:getSkillId(arg_80_1), var_80_0:getSkillLevel(arg_80_1))
	local var_80_12 = arg_80_0.skillContainer:convertToNodeSpace(arg_80_0.skillItems[arg_80_1]:getChildByName("icon"):convertToWorldSpace(cc.p(0, 0)))
	local var_80_13 = 0.2

	if arg_80_0.skillTextHandle and arg_80_0.desc2list then
		for iter_80_0, iter_80_1 in ipairs(var_80_11) do
			table.insert(arg_80_0.desc2list, #arg_80_0.desc2list, iter_80_1)
		end
	else
		arg_80_0.desc2list = var_80_11
		arg_80_0.skillTextHandle = var_0_10.scheduleGlobal(function()
			local var_82_0 = xyd.WindowManager.get():getWindow("pet_main")

			if not var_82_0 then
				return
			end

			local var_82_1 = xyd.AssetLoader:get():loadLabel(var_80_10)

			var_82_1:setString(arg_80_0.desc2list[1])
			table.remove(arg_80_0.desc2list, 1)
			var_82_1:setAnchorPoint(0.5, 0.5)
			var_82_1:setPosition(var_80_12.x, var_80_12.y + var_80_8 / 2)
			var_82_1:align(display.CENTER_LEFT)
			var_82_1:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_82_0.skillContainer:addChild(var_82_1)

			local var_82_2 = cc.Spawn:create({
				cc.MoveBy:create(0.6, cc.p(0, 70)),
				cc.FadeOut:create(0.6)
			})

			var_82_1:runActionOnce(var_82_2, true, function()
				var_82_0.skillContainer:removeChild(var_82_1)
			end, 0)

			if not next(arg_80_0.desc2list) then
				arg_80_0.desc2list = nil

				if arg_80_0.skillTextHandle then
					var_0_10.unscheduleGlobal(arg_80_0.skillTextHandle)
				end
			end
		end, var_80_13)
	end
end

function var_0_4.createSkillTip(arg_84_0, arg_84_1, arg_84_2)
	local var_84_0 = arg_84_0.skillItems[arg_84_1]

	if not var_84_0 then
		return
	end

	if var_84_0:getChildByName("skill_tip") and not tolua.isnull(var_84_0:getChildByName("skill_tip")) then
		var_84_0:removeChildByName("skill_tip")
	end

	local var_84_1 = display.newNode()

	var_84_1:setPosition(var_84_0:getChildByName("icon"):getPosition())
	var_84_1:setAnchorPoint(cc.p(0, 0))
	var_84_1:setContentSize(var_84_0:getChildByName("icon"):getContentSize())
	var_84_1:setTouchEnabled(true)
	var_84_1:addTo(var_84_0)
	var_84_1:setName("skill_tip")

	local var_84_2 = arg_84_0:convertToWorldSpace(cc.p(0, 0))

	var_84_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_85_0)
		if arg_85_0.name == "began" then
			return true
		elseif arg_85_0.name == "ended" then
			if xyd.WindowManager.get():getWindow("skill_tips") then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end

			local var_85_0 = {
				isShowSkillDesc4 = true,
				id = arg_84_2,
				skillLev = arg_84_0.hero:getSkillLevel(arg_84_1),
				extraSkillLevel = arg_84_0.hero:getExtraSkillLevel(),
				skillDesc4Change = arg_84_0.hero:checkSkillChange(arg_84_1)
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_85_1 = xyd.WindowManager.get():openWindow("skill_tips", var_85_0)
				local var_85_2 = var_84_1:convertToWorldSpace(cc.p(0, 0))

				var_85_1:setPosition(var_85_2.x + 110 + 7 - var_84_2.x, var_85_2.y - var_84_0:getContentSize().height + 20 - var_84_2.y)
			end
		end
	end)
end

function var_0_4.updateAllSkillTips(arg_86_0)
	local var_86_0 = arg_86_0.hero:getSkillId()

	for iter_86_0, iter_86_1 in pairs(var_86_0) do
		if iter_86_1 <= 0 then
			var_86_0[iter_86_0] = nil
		end

		if arg_86_0.selfPlayer.maxTeamLev <= 80 and xyd.tables.skill:isAwakenSkill(iter_86_1) == 1 then
			var_86_0[iter_86_0] = nil
		end
	end

	for iter_86_2, iter_86_3 in pairs(var_86_0) do
		arg_86_0:createSkillTip(iter_86_2, iter_86_3)
	end
end

function var_0_4.updateSkillContainer(arg_87_0, arg_87_1)
	local var_87_0 = arg_87_0.hero

	if arg_87_0.skillPoints < 0 then
		arg_87_0.skillPoints = 0
	end

	for iter_87_0, iter_87_1 in pairs(arg_87_0.skillItems) do
		local var_87_1 = iter_87_1:getChildByName("jiadian")

		if var_87_0:getSkillLevel(iter_87_0) ~= 0 then
			local var_87_2 = var_87_0:getSkillLevel(iter_87_0) - xyd.SKILL_EXTRA[iter_87_0]

			iter_87_1:getChildByName("lev"):setString("lv. " .. var_87_2)
			iter_87_1:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(var_87_0:getSkillLevel(iter_87_0)))
		end

		if var_87_1 then
			if var_87_0:getSkillLevel(iter_87_0) == 0 or var_87_0:getSkillLevel(iter_87_0) >= var_87_0:getSkillLimitLevel(iter_87_0) then
				var_87_1:setButtonEnabled(false)
			else
				var_87_1:setButtonEnabled(true)
			end
		end
	end
end

function var_0_4.updateIntroduceText(arg_88_0)
	local var_88_0 = arg_88_0.hero
	local var_88_1 = arg_88_0:nodeByName("jieshao_container")
	local var_88_2 = var_88_1:getChildByName("title_jieshao")
	local var_88_3 = var_88_1:getChildByName("bg")
	local var_88_4 = var_88_1:getChildren()

	if var_88_4 then
		for iter_88_0, iter_88_1 in ipairs(var_88_4) do
			if iter_88_1 ~= var_88_2 and iter_88_1 ~= var_88_3 then
				var_88_1:removeChild(iter_88_1)
			end
		end
	end

	local var_88_5 = 0

	if arg_88_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) then
		local var_88_6 = xyd.tables.hero:getHolyAttr(arg_88_0.hero:getTableID())
		local var_88_7 = display.newNode()
		local var_88_8 = 25

		var_88_5 = 60

		for iter_88_2 = 1, #var_88_6 do
			local var_88_9 = xyd.tables.petHolyAttr:icon(var_88_6[iter_88_2])

			if var_88_9 then
				local var_88_10 = xyd.AssetLoader.get():loadSprite(var_88_9)

				var_88_10:addTo(var_88_7)
				var_88_10:setPosition(cc.p(var_88_8, 25))
				var_88_10:setAnchorPoint(cc.p(0.5, 0.5))

				var_88_8 = var_88_8 + var_88_10:getContentSize().width + 8

				var_88_10:setTouchEnabled(true)
				var_88_10:setTouchSwallowEnabled(true)
				var_88_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_89_0)
					if arg_89_0.name == "began" then
						var_88_10:setScale(0.9)

						return true
					elseif arg_89_0.name == "ended" then
						var_88_10:setScale(1)

						local var_89_0 = {
							pet = var_88_0,
							id = var_88_6[iter_88_2]
						}

						xyd.WindowManager.get():openWindow("pet_other_attr", var_89_0)
					end
				end)
			end
		end

		var_88_7:addTo(var_88_1)
		var_88_7:setContentSize(var_88_1:getContentSize().width, 60)
		var_88_7:setPosition(cc.p(25, 0))
		var_88_7:setAnchorPoint(cc.p(0, 0))
	end

	local var_88_11 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = 0 + var_88_5,
		color = cc.c3b(54, 54, 54),
		dimensions = cc.size(470, 54),
		text = var_88_0:getTalkText()
	}
	local var_88_12
	local var_88_13 = 0
	local var_88_14 = 0

	if var_88_0:getTalkText() then
		local var_88_15 = xyd.AssetLoader.get():loadLabel(var_88_11)

		var_88_15:addTo(var_88_1)
		var_88_15:setAnchorPoint(cc.p(0, 0))

		var_88_13 = var_88_15:getStringNumLines()
		var_88_14 = 10
	end

	local var_88_16 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = var_88_5 + var_88_13 * 30 + var_88_14,
		color = cc.c3b(235, 75, 94),
		dimensions = cc.size(470, 100),
		text = var_88_0:getDes()
	}
	local var_88_17 = xyd.AssetLoader.get():loadLabel(var_88_16)

	var_88_17:addTo(var_88_1)
	var_88_17:setAnchorPoint(cc.p(0, 0))

	local var_88_18 = var_88_17:getStringNumLines()

	var_88_3:y(var_88_16.y + var_88_18 * 30 + 20)
	var_88_2:y(var_88_16.y + var_88_18 * 30 + 20)

	local var_88_19 = var_88_2:getY()

	var_88_1:height(var_88_19 + 30)
end

function var_0_4.updateAttrLabels(arg_90_0)
	if not arg_90_0.hero then
		return
	end

	local var_90_0 = arg_90_0.hero
	local var_90_1 = 0
	local var_90_2 = arg_90_0:nodeByName("shuxing_container")
	local var_90_3 = var_90_2:getChildByName("title_shuxing")
	local var_90_4 = var_90_2:getChildByName("bg")
	local var_90_5 = var_90_2:getChildren()

	if var_90_5 then
		for iter_90_0, iter_90_1 in ipairs(var_90_5) do
			if iter_90_1 ~= var_90_3 and iter_90_1 ~= var_90_4 then
				var_90_2:removeChild(iter_90_1)
			end
		end
	end

	local var_90_6 = -33

	for iter_90_2 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if iter_90_2 ~= xyd.AttributeType.HP and iter_90_2 ~= xyd.AttributeType.HUJIA and iter_90_2 ~= xyd.AttributeType.MOKANG and iter_90_2 ~= xyd.AttributeType.REHP and var_90_0:getTotalAttr(iter_90_2) > 0 then
			var_90_1 = var_90_1 + 1

			local var_90_7 = arg_90_0:createLabel(iter_90_2)

			var_90_7:addTo(var_90_2)
			var_90_7:setPosition(20, var_90_1 * 35 + var_90_6)
		end
	end

	local var_90_8 = arg_90_0:setGrowAttrLabel(35 + var_90_1 * 35 + var_90_6)

	var_90_4:y(var_90_8 + 15)
	var_90_3:y(var_90_8 + 15)
	var_90_2:height(var_90_8 + 43)
	var_90_2:setPosition(cc.p(0, 0))
end

function var_0_4.createLabel(arg_91_0, arg_91_1)
	local var_91_0 = arg_91_0.hero
	local var_91_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_91_1:getChildByName("txt_title"):setString(xyd.tables.attr:name(arg_91_1))
	var_91_1:getChildByName("title_bg"):width(34 + var_91_1:getChildByName("txt_title"):getWidth())
	var_91_1:getChildByName("txt_ini"):setString(math.ceil(math.max(0, var_91_0:getTotalAttr(arg_91_1) - var_91_0:getEquipFumoAttr(arg_91_1) - var_91_0:getEquipAttr(arg_91_1) - var_91_0:getSkillAttr(arg_91_1) - var_91_0:getSkill2Attr(arg_91_1) - var_91_0:getTotalPracticeAttr(arg_91_1))))

	local var_91_2 = math.ceil(var_91_0:getEquipFumoAttr(arg_91_1) + var_91_0:getEquipAttr(arg_91_1) + var_91_0:getSkillAttr(arg_91_1) + var_91_0:getSkill2Attr(arg_91_1) + var_91_0:getTotalPracticeAttr(arg_91_1))

	if var_91_2 > 0 then
		var_91_1:getChildByName("txt_add"):setString("+" .. var_91_2 .. (xyd.tables.attr:suffix(arg_91_1) ~= "" and xyd.tables.attr:suffix(arg_91_1) or ""))
	else
		var_91_1:getChildByName("txt_add"):setString("")
	end

	return var_91_1
end

function var_0_4.setGrowAttrLabel(arg_92_0, arg_92_1)
	local var_92_0 = arg_92_0:nodeByName("shuxing_container")
	local var_92_1 = arg_92_0.hero
	local var_92_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_92_2:getChildByName("txt_title"):setString(var_0_11:translation("HERO_BUTTON_MINJIECHENGZHANG"))
	var_92_2:getChildByName("title_bg"):width(34 + var_92_2:getChildByName("txt_title"):getWidth())
	var_92_2:getChildByName("txt_ini"):setString(var_92_1:getAttrGlow(xyd.AttributeType.AGILE))
	var_92_2:getChildByName("txt_add"):setString("")

	local var_92_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_92_3:getChildByName("txt_title"):setString(var_0_11:translation("HERO_BUTTON_ZHILICHENGZHANG"))
	var_92_3:getChildByName("title_bg"):width(34 + var_92_3:getChildByName("txt_title"):getWidth())
	var_92_3:getChildByName("txt_ini"):setString(var_92_1:getAttrGlow(xyd.AttributeType.WISE))
	var_92_3:getChildByName("txt_add"):setString("")

	local var_92_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/shuxing_item.csb")

	var_92_4:getChildByName("txt_title"):setString(var_0_11:translation("HERO_BUTTON_LILIANGCHENGZHANG"))
	var_92_4:getChildByName("title_bg"):width(34 + var_92_4:getChildByName("txt_title"):getWidth())
	var_92_4:getChildByName("txt_ini"):setString(var_92_1:getAttrGlow(xyd.AttributeType.STRENGTH))
	var_92_4:getChildByName("txt_add"):setString("")
	var_92_2:addTo(var_92_0)
	var_92_2:setPosition(20, arg_92_1)
	var_92_3:addTo(var_92_0)
	var_92_3:setPosition(20, arg_92_1 + 35)
	var_92_4:addTo(var_92_0)
	var_92_4:setPosition(20, arg_92_1 + 70)

	return arg_92_1 + 110
end

function var_0_4.playActionByButton(arg_93_0, arg_93_1, arg_93_2)
	local var_93_0 = arg_93_0.containers[arg_93_0.state]
	local var_93_1 = {}

	table.insert(var_93_1, cc.ScaleTo:create(0.2, 0))
	table.insert(var_93_1, cc.CallFunc:create(function()
		local var_94_0 = {}

		table.insert(var_94_0, cc.DelayTime:create(0.1))
		table.insert(var_94_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_94_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_94_0, cc.ScaleTo:create(0.05, 1))

		if arg_93_1 == var_0_6 then
			table.insert(var_94_0, cc.CallFunc:create(function()
				arg_93_0:skillListAction(0.01, 15, 0.2)
			end))
		end

		var_93_0:hide()
		arg_93_2:scale(0)
		arg_93_2:show()
		arg_93_2:runAction(transition.sequence(var_94_0))
	end))
	var_93_0:runAction(transition.sequence(var_93_1))

	arg_93_0.state = arg_93_1

	arg_93_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.normal)
	arg_93_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.normal)
	arg_93_0:nodeByName("button_all"):setBrightStyle(ccui.BrightStyle.normal)
end

function var_0_4.clickInfoButton(arg_96_0)
	if arg_96_0.sendSkillLevUpRequest then
		arg_96_0:sendSkillLevUpRequest()
	end

	if arg_96_0.state ~= var_0_7 then
		arg_96_0:playActionByButton(var_0_7, arg_96_0.infoContainer)
		arg_96_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_96_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.clickSkillButton(arg_97_0)
	if arg_97_0.sendSkillLevUpRequest then
		arg_97_0:sendSkillLevUpRequest()
	end

	if arg_97_0.state ~= var_0_6 then
		if arg_97_0.skillList and not tolua.isnull(arg_97_0.skillList) then
			if arg_97_0.skillCount and arg_97_0.skillCount == 4 then
				arg_97_0.skillList:getScrollNode():setPositionY(-3)
			elseif arg_97_0.skillCount and arg_97_0.skillCount == 5 then
				arg_97_0.skillList:getScrollNode():setPositionY(-120)
			end
		end

		local var_97_0 = arg_97_0.containers[arg_97_0.state]
		local var_97_1 = {}

		table.insert(var_97_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_97_1, cc.CallFunc:create(function()
			local var_98_0 = {}

			table.insert(var_98_0, cc.DelayTime:create(0.1))
			table.insert(var_98_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_98_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_98_0, cc.ScaleTo:create(0.05, 1))
			table.insert(var_98_0, cc.CallFunc:create(function()
				arg_97_0:skillListAction(0.01, 15, 0.2)
			end))
			var_97_0:hide()
			arg_97_0.skillContainer:scale(0)
			arg_97_0.skillContainer:show()
			arg_97_0.skillContainer:runAction(transition.sequence(var_98_0))
		end))
		var_97_0:runAction(transition.sequence(var_97_1))

		arg_97_0.state = var_0_6

		arg_97_0:updateButtonBrightState()
	else
		arg_97_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	if arg_97_0.state == var_0_6 then
		arg_97_0:updateSkillContainer()
		arg_97_0:updateAllSkillTips()
	end
end

function var_0_4.clickShowDetailButton(arg_100_0)
	xyd.WindowManager.get():openWindow("pet_equip_info", {
		hero = arg_100_0.hero
	})
end

function var_0_4.clickMainButton(arg_101_0)
	if arg_101_0.sendSkillLevUpRequest then
		arg_101_0:sendSkillLevUpRequest()
	end

	if arg_101_0.state ~= var_0_8 then
		local var_101_0 = arg_101_0.containers[arg_101_0.state]
		local var_101_1 = {}

		table.insert(var_101_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_101_1, cc.CallFunc:create(function()
			local var_102_0 = {}

			table.insert(var_102_0, cc.DelayTime:create(0.1))
			table.insert(var_102_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_102_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_102_0, cc.ScaleTo:create(0.05, 1))
			var_101_0:hide()
			arg_101_0.mainContainer:scale(0)
			arg_101_0.mainContainer:show()
			arg_101_0.mainContainer:runAction(transition.sequence(var_102_0))
		end))
		var_101_0:runAction(transition.sequence(var_101_1))

		arg_101_0.state = var_0_8

		arg_101_0:updateButtonBrightState()
	else
		arg_101_0:nodeByName("button_all"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.clickCardButton(arg_103_0)
	if arg_103_0.sendSkillLevUpRequest then
		arg_103_0:sendSkillLevUpRequest()
	end

	if not arg_103_0.isCardShow then
		local var_103_0 = {}

		table.insert(var_103_0, cc.DelayTime:create(0.1))
		table.insert(var_103_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_103_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_103_0, cc.ScaleTo:create(0.05, 1))
		table.insert(var_103_0, cc.CallFunc:create(function()
			arg_103_0.cardBlock:show()
		end))
		arg_103_0.cardContainer:scale(0)
		arg_103_0.cardContainer:show()
		arg_103_0.cardContainer:runAction(transition.sequence(var_103_0))

		arg_103_0.isCardShow = true
	else
		local var_103_1 = {}

		table.insert(var_103_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_103_1, cc.CallFunc:create(function()
			arg_103_0.cardContainer:hide()
			arg_103_0.cardBlock:hide()
		end))
		arg_103_0.cardContainer:runAction(transition.sequence(var_103_1))

		arg_103_0.isCardShow = false
	end
end

function var_0_4.clickAddExpButton(arg_106_0)
	local var_106_0 = {
		hero = arg_106_0.hero,
		wnd = arg_106_0
	}

	xyd.WindowManager.get():openWindow("pet_add_exp", var_106_0)
end

function var_0_4.skillListAction(arg_107_0, arg_107_1, arg_107_2, arg_107_3)
	if arg_107_0.hero:isAwaken() then
		local var_107_0 = var_0_10.performWithDelayGlobal(function()
			if not xyd.WindowManager.get():getWindow("pet_main") then
				return
			end

			local var_108_0 = 120 / arg_107_2
			local var_108_1 = -120
			local var_108_2 = var_0_10.scheduleGlobal(function()
				var_108_1 = var_108_1 + var_108_0

				local var_109_0 = xyd.WindowManager.get():getWindow("pet_main")

				if var_109_0 and var_108_1 <= 0 then
					var_109_0.skillList:getScrollNode():setPositionY(var_108_1)
				elseif skillHandle then
					var_0_10.unscheduleGlobal(skillHandle)
				end
			end, arg_107_1)
		end, arg_107_3)
	end
end

function var_0_4.clickStoneButton(arg_110_0)
	local var_110_0 = arg_110_0.hero
	local var_110_1 = xyd.tables.hero:stoneID(var_110_0:getTableID())

	xyd.WindowManager.get():openWindow("pet_stone", {
		hero = var_110_0,
		itemComposeID = var_110_1
	})
end

function var_0_4.clickJinhuaButton(arg_111_0)
	if arg_111_0.sendSkillLevUpRequest then
		arg_111_0:sendSkillLevUpRequest()
	end

	local var_111_0 = arg_111_0.hero

	if var_111_0:getStar() >= xyd.MAX_STAR_LEVEL then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("HERO_MAIN_MAX_STAR")
		})

		return
	end

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_11:translation("EVOLVE_PET_ALERT"), xyd.StarLevelSuipian[var_111_0:getStar() + 1]), function()
		if var_111_0:getSuiPian() < xyd.StarLevelSuipian[var_111_0:getStar() + 1] then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_11:translation("PET_STONE_TOO_LESS")
			})
		else
			local var_112_0 = var_111_0:getStar()
			local var_112_1 = cc.p(arg_111_0:getHeroContainer():getPosition())
			local var_112_2 = arg_111_0:getHeroContainer():getContentSize()

			var_112_1.x = var_112_1.x
			var_112_1.y = var_112_1.y + var_112_2.height * 0.5

			arg_111_0:playEffect(arg_111_0.mainContainer, "Evolve", var_112_1, true)

			local var_112_3 = clone(arg_111_0.hero)

			var_111_0:evolution(function(arg_113_0, arg_113_1)
				if arg_113_0 == xyd.error.OK then
					local var_113_0 = {}

					table.insert(var_113_0, var_0_9:getHeroMainAttr(var_111_0:getTableID(), 1, var_111_0:getStar(), var_111_0:getLevel()) - var_0_9:getHeroMainAttr(var_111_0:getTableID(), 1, var_111_0:getStar() - 1, var_111_0:getLevel()))
					table.insert(var_113_0, var_0_9:getHeroMainAttr(var_111_0:getTableID(), 1, var_111_0:getStar(), var_111_0:getLevel()) - var_0_9:getHeroMainAttr(var_111_0:getTableID(), 2, var_111_0:getStar() - 1, var_111_0:getLevel()))
					table.insert(var_113_0, var_0_9:getHeroMainAttr(var_111_0:getTableID(), 1, var_111_0:getStar(), var_111_0:getLevel()) - var_0_9:getHeroMainAttr(var_111_0:getTableID(), 3, var_111_0:getStar() - 1, var_111_0:getLevel()))

					local var_113_1 = arg_111_0:getHeroModel()

					arg_111_0.isShow = true

					var_113_1:win(false, handler(arg_111_0, arg_111_0.setIsShow))
					var_113_1:playAttribute(arg_111_0:getFloatAttrs(var_113_0))
					arg_111_0:updateAttrScore()
					arg_111_0:updateHeroStar()
					arg_111_0:updateAttrLabels()
					arg_111_0:updateIntroduceText()
					arg_111_0:updateScrollBg()
					arg_111_0:updateCard()
					arg_111_0:updateHomeCard()
					arg_111_0:updateNameLabel()
					arg_111_0:updateCollectWindow()
					arg_111_0:playRepeatingEffect()
					arg_111_0:setSkillContainer()

					arg_111_0.heroModel_ = nil

					arg_111_0:updateHeroModel(var_111_0)
					arg_111_0:resetEffect()
					audio.playSound(xyd.tables.sound:getSound("hero_upstar"))

					arg_111_0.refresh_ = true

					local var_113_2 = {
						type_ = xyd.LevelUpType.EVOLVE,
						hero = var_111_0,
						old_hero = var_112_3,
						vals = {
							isShowSkillDesc4 = true,
							oldStar = var_112_0,
							newStar = var_112_0 + 1,
							oldColor = var_111_0:getColor()
						}
					}

					xyd.WindowManager.get():openWindow("levelup", var_113_2)
				end
			end)
		end
	end, nil, nil, arg_111_0.colorMode)
end

function var_0_4.updateButtonBrightState(arg_114_0)
	arg_114_0:nodeByName("button_all"):setBrightStyle(arg_114_0.state == var_0_8 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_114_0:nodeByName("button_shuxing"):setBrightStyle(arg_114_0.state == var_0_7 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
	arg_114_0:nodeByName("button_jineng"):setBrightStyle(arg_114_0.state == var_0_6 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
end

function var_0_4.updateSkillItem(arg_115_0, arg_115_1, arg_115_2)
	local var_115_0 = arg_115_0.hero

	for iter_115_0, iter_115_1 in ipairs(arg_115_0.skillItems) do
		local var_115_1 = arg_115_0.skillItems[iter_115_0]

		if var_115_0:getSkillLevel(iter_115_0) ~= 0 then
			local var_115_2 = var_115_0:getSkillLevel(iter_115_0) - xyd.SKILL_EXTRA[iter_115_0]

			var_115_1:getChildByName("lev"):setString("lv. " .. var_115_2)
			var_115_1:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(var_115_0:getSkillLevel(iter_115_0)))

			if var_115_0:getExtraSkillLevel() > 0 then
				var_115_1:getChildByName("level_extra"):show()
				var_115_1:getChildByName("level_extra"):setString("+" .. var_115_0:getExtraSkillLevel())
			else
				var_115_1:getChildByName("level_extra"):hide()
			end

			var_115_1:getChildByName("jiesuo"):setVisible(false)
		else
			local var_115_3 = var_0_11:translation("HERO_JIESUO_" .. iter_115_0)

			if iter_115_0 == 5 then
				var_115_3 = var_0_11:translation("PET_AWAKE_SKILL_LOCK_TIP")
			end

			var_115_1:getChildByName("jiesuo"):setString(var_115_3)
			var_115_1:getChildByName("lev"):setVisible(false)
			var_115_1:getChildByName("level_extra"):hide()
			var_115_1:getChildByName("bookNum"):setVisible(false)
			var_115_1:getChildByName("skillBook"):setVisible(false)
		end
	end

	if not arg_115_2 and arg_115_1 then
		local var_115_4 = arg_115_0.skillItems[arg_115_1]:getChildByName("jiadian")

		if var_115_0:getSkillLevel(arg_115_1) == 0 or var_115_0:getSkillLevel(arg_115_1) >= var_115_0:getLevel() then
			var_115_4:setButtonEnabled(false)
		else
			var_115_4:setButtonEnabled(true)
		end
	end
end

function var_0_4.showItemDetail(arg_116_0, arg_116_1, arg_116_2, arg_116_3)
	local var_116_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.equipConfirmWnd, {
		is_pet = true,
		hero = arg_116_0.hero,
		item_index = arg_116_1,
		color = arg_116_2,
		state = arg_116_3
	})

	cc.EventProxy.new(var_116_0, var_116_0):addEventListener(xyd.event.HERO_EQUIP_CHANGED, function(arg_117_0)
		arg_116_0:playEffect(arg_116_0.mainContainer, "AddItem", cc.p(arg_116_0:getEquipContainerByIndex(arg_116_1):getPosition()), true)

		local var_117_0 = arg_116_0.hero:getEquipByIndex(arg_116_1)
		local var_117_1 = arg_116_0:getHeroModel()

		arg_116_0.isShow = true

		var_117_1:win(false, handler(arg_116_0, arg_116_0.setIsShow))
		var_117_1:playAttribute(var_117_0:getAttrFloat(arg_116_0.hero:getHeroType()))
		arg_116_0:updateEquip()
		arg_116_0:playRepeatingEffect()
		arg_116_0:updateAttrScore()
		arg_116_0:updateAttrLabels()
		arg_116_0:updateIntroduceText()
		arg_116_0:updateScrollBg()
		xyd.WindowManager.get():closeWindow(xyd.WindowName.equipConfirmWnd)
		xyd.WindowManager.get():closeWindow(xyd.WindowName.itemComposeWnd)
		arg_116_0:updateCollectWindow()
		arg_116_0:updateSkillItem(nil, false)
		arg_116_0.selfPlayer:checkEquipableAndSummon()
		audio.playSound(xyd.tables.sound:getSound("hero_equip"))
		arg_116_0:CheckOneClick()
	end)
end

function var_0_4.CheckOneClickJinjie(arg_118_0)
	local var_118_0 = arg_118_0.hero
	local var_118_1 = 0

	arg_118_0.needEquip = {}
	arg_118_0.needPotion = {}
	arg_118_0.needGold = 0

	local function var_118_2(arg_119_0)
		local var_119_0 = arg_118_0.needEquip[arg_119_0] or 0
		local var_119_1 = xyd.tables.item:compose(arg_119_0)
		local var_119_2 = xyd.tables.item:composeNum(arg_119_0)
		local var_119_3 = xyd.tables.item:composeMana(arg_119_0) or 0

		if var_119_1[1] ~= 0 then
			if arg_118_0.selfPlayer:getBackpack():getItemNumByID(arg_119_0) == var_119_0 then
				arg_118_0.needGold = arg_118_0.needGold + var_119_3

				for iter_119_0 = 1, #var_119_1 do
					for iter_119_1 = 1, var_119_2[iter_119_0] do
						var_118_2(var_119_1[iter_119_0])
					end
				end
			else
				arg_118_0.needEquip[arg_119_0] = var_119_0 + 1
			end
		else
			arg_118_0.needEquip[arg_119_0] = var_119_0 + 1
		end
	end

	for iter_118_0 = 1, 3 do
		local var_118_3 = var_118_0:getEquipByIndex(iter_118_0)

		if var_118_3:getTableID() > 0 and not var_118_3:isCollected() and xyd.tables.item:isAwakenItem(var_118_3:getTableID()) == 0 then
			break
		end

		if iter_118_0 == 3 then
			arg_118_0:setjinjieBtn(var_0_16)

			return false
		end
	end

	for iter_118_1 = 1, 3 do
		local var_118_4 = var_118_0:getEquipByIndex(iter_118_1)

		if var_118_4:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_118_4:getTableID()) == 0 and not var_118_4:isCollected() then
			if arg_118_0.maxLev < var_118_4:getLevel() then
				arg_118_0:setjinjieBtn(var_0_16)

				return false
			end

			if var_118_0:getLevel() < var_118_4:getLevel() and var_118_1 < var_118_4:getLevel() then
				var_118_1 = var_118_4:getLevel()
			end

			var_118_2(var_118_4:getTableID())
		end
	end

	if arg_118_0.needGold > arg_118_0.selfPlayer.mana then
		arg_118_0:setjinjieBtn(var_0_16)

		return false
	end

	for iter_118_2, iter_118_3 in pairs(arg_118_0.needEquip) do
		if iter_118_3 > arg_118_0.selfPlayer:getBackpack():getItemNumByID(iter_118_2) then
			arg_118_0:setjinjieBtn(var_0_16)

			return false
		end
	end

	if var_118_1 ~= 0 then
		local var_118_5 = 0
		local var_118_6 = var_118_0:getLevel()
		local var_118_7 = var_118_0:getExp() - xyd.tables.partnerExp:totalExp(var_118_0:getLevel() - 1)
		local var_118_8 = {
			50001087,
			50001088,
			50001089
		}

		for iter_118_4 = var_118_6, var_118_1 - 1 do
			var_118_5 = var_118_5 + xyd.tables.partnerExp:exp(iter_118_4)
		end

		local var_118_9 = var_118_5 - var_118_7

		for iter_118_5, iter_118_6 in pairs(var_118_8) do
			local var_118_10 = arg_118_0.selfPlayer:getBackpack():getItemNumByID(iter_118_6)
			local var_118_11 = xyd.tables.item:exp(iter_118_6)

			if var_118_9 <= var_118_10 * var_118_11 then
				local var_118_12 = math.ceil(var_118_9 / var_118_11)

				arg_118_0.needPotion[iter_118_6] = var_118_12
				var_118_9 = 0

				break
			elseif var_118_10 ~= 0 then
				var_118_9 = var_118_9 - var_118_10 * var_118_11
				arg_118_0.needPotion[iter_118_6] = var_118_10
			end
		end

		if var_118_9 ~= 0 then
			arg_118_0:setjinjieBtn(var_0_16)

			return false
		end
	end

	arg_118_0:setjinjieBtn(var_0_14)

	return true
end

function var_0_4.checkOneKeyEquips(arg_120_0)
	local var_120_0 = arg_120_0.hero

	arg_120_0.needGold2Equip = 0
	arg_120_0.needEquip2Equip = {}
	arg_120_0.needPotion2Equip = {}
	arg_120_0.canEquipIndex = {}

	local function var_120_1(arg_121_0)
		local var_121_0 = {}
		local var_121_1 = 0

		local function var_121_2(arg_122_0)
			local var_122_0 = var_121_0[arg_122_0] or 0
			local var_122_1 = xyd.tables.item:compose(arg_122_0)
			local var_122_2 = xyd.tables.item:composeNum(arg_122_0)
			local var_122_3 = xyd.tables.item:composeMana(arg_122_0) or 0

			if var_122_1[1] ~= 0 then
				if arg_120_0.selfPlayer:getBackpack():getItemNumByID(arg_122_0) == var_122_0 + (arg_120_0.needEquip2Equip[arg_122_0] or 0) then
					var_121_1 = var_121_1 + var_122_3

					for iter_122_0 = 1, #var_122_1 do
						for iter_122_1 = 1, var_122_2[iter_122_0] do
							var_121_2(var_122_1[iter_122_0])
						end
					end
				else
					var_121_0[arg_122_0] = var_122_0 + 1
				end
			else
				var_121_0[arg_122_0] = var_122_0 + 1
			end
		end

		var_121_2(arg_121_0)

		return var_121_0, var_121_1
	end

	local function var_120_2(arg_123_0, arg_123_1)
		arg_123_1 = arg_123_1 or {}

		for iter_123_0, iter_123_1 in pairs(arg_123_0) do
			if iter_123_1 > arg_120_0.selfPlayer:getBackpack():getItemNumByID(iter_123_0) - (arg_123_1[iter_123_0] or 0) then
				return false
			end
		end

		return true
	end

	local var_120_3 = arg_120_0:allPotionsExpInBackPack()
	local var_120_4 = 0

	for iter_120_0 = 1, 3 do
		local var_120_5 = var_120_0:getEquipByIndex(iter_120_0)
		local var_120_6
		local var_120_7
		local var_120_8, var_120_9 = var_120_1(var_120_5:getTableID())

		if not var_120_5:isCollected() and var_120_5:getTableID() > 0 and arg_120_0.maxLev >= var_120_5:getLevel() and xyd.tables.item:isAwakenItem(var_120_5:getTableID()) == 0 and var_120_9 <= arg_120_0.selfPlayer.mana - arg_120_0.needGold2Equip and var_120_2(var_120_8, arg_120_0.needEquip2Equip) then
			if var_120_0:getLevel() >= var_120_5:getLevel() then
				arg_120_0.needGold2Equip = arg_120_0.needGold2Equip + var_120_9

				for iter_120_1, iter_120_2 in pairs(var_120_8) do
					arg_120_0.needEquip2Equip[iter_120_1] = (arg_120_0.needEquip2Equip[iter_120_1] or 0) + iter_120_2
				end

				table.insert(arg_120_0.canEquipIndex, iter_120_0)
			else
				local var_120_10 = 0
				local var_120_11 = var_120_0:getLevel()
				local var_120_12 = var_120_0:getExp() - xyd.tables.partnerExp:totalExp(var_120_0:getLevel() - 1)

				for iter_120_3 = var_120_11, var_120_5:getLevel() - 1 do
					var_120_10 = var_120_10 + xyd.tables.partnerExp:exp(iter_120_3)
				end

				local var_120_13 = var_120_10 - var_120_12

				if var_120_13 <= var_120_3 then
					if var_120_4 < var_120_13 then
						var_120_4 = var_120_13
					end

					arg_120_0.needGold2Equip = arg_120_0.needGold2Equip + var_120_9

					for iter_120_4, iter_120_5 in pairs(var_120_8) do
						arg_120_0.needEquip2Equip[iter_120_4] = (arg_120_0.needEquip2Equip[iter_120_4] or 0) + iter_120_5
					end

					table.insert(arg_120_0.canEquipIndex, iter_120_0)
				end
			end
		end
	end

	if #arg_120_0.canEquipIndex == 0 then
		arg_120_0:setjinjieBtn(var_0_16)

		return false
	end

	if var_120_4 then
		local var_120_14 = {
			50001087,
			50001088,
			50001089
		}

		for iter_120_6, iter_120_7 in pairs(var_120_14) do
			local var_120_15 = arg_120_0.selfPlayer:getBackpack():getItemNumByID(iter_120_7)
			local var_120_16 = xyd.tables.item:exp(iter_120_7)

			if var_120_4 <= var_120_15 * var_120_16 then
				local var_120_17 = math.ceil(var_120_4 / var_120_16)

				arg_120_0.needPotion2Equip[iter_120_7] = var_120_17

				break
			elseif var_120_15 ~= 0 then
				var_120_4 = var_120_4 - var_120_15 * var_120_16
				arg_120_0.needPotion2Equip[iter_120_7] = var_120_15
			end
		end
	end

	arg_120_0:setjinjieBtn(var_0_15)

	return true
end

function var_0_4.CheckOneClick(arg_124_0)
	if arg_124_0:CheckOneClickJinjie() == false then
		arg_124_0:checkOneKeyEquips()
	end
end

function var_0_4.clickYijianButton(arg_125_0)
	if arg_125_0.sendSkillLevUpRequest then
		arg_125_0:sendSkillLevUpRequest()
	end

	local function var_125_0(arg_126_0)
		local var_126_0 = arg_125_0.hero
		local var_126_1 = var_126_0:getColor()
		local var_126_2 = var_126_0:getStar()
		local var_126_3 = var_126_0:getMaxHP()
		local var_126_4 = var_126_0:getZhandouli()
		local var_126_5 = cc.p(arg_125_0:getHeroContainer():getPosition())
		local var_126_6 = arg_125_0:getHeroContainer():getContentSize()

		var_126_5.x = var_126_5.x
		var_126_5.y = var_126_5.y + var_126_6.height * 0.5

		var_126_0:oneKeyPowerUp(function(arg_127_0, arg_127_1)
			if arg_127_0 == xyd.error.OK then
				arg_125_0:playEffect(arg_125_0.mainContainer, "Upgrade", var_126_5, true)

				local var_127_0 = arg_125_0:getHeroModel()

				if not var_126_0:getEquipByIndex(2):isCollected() then
					for iter_127_0 = 1, var_0_1 do
						if var_126_0:getEquipByIndex(iter_127_0):isCollected() and xyd.tables.item:isAwakenItem(var_126_0:getEquipByIndex(iter_127_0):getTableID()) == 0 and not var_126_0:isLastColorHasAwakeItem() and xyd.tables.item:isAwakenItem(var_126_0:getEquipByIndex(iter_127_0):getTableID()) == 1 then
							local var_127_1 = arg_125_0:getEquipContainerByIndex(iter_127_0)
							local var_127_2 = display.newNode()

							var_127_2:size(var_127_1:getWidth(), var_127_1:getHeight())

							local var_127_3 = var_126_0:getEquipByIndex(iter_127_0, var_126_0:getColor() - 1)

							xyd.setSpecialItemBorder(var_127_2, var_127_3:getTableID())
							var_127_2:addTo(arg_125_0.mainContainer, 101)
							var_127_2:pos(var_127_1:getPosition())

							local var_127_4, var_127_5 = arg_125_0:getHeroContainer():getPosition()
							local var_127_6 = var_127_4 + arg_125_0:getHeroContainer():getWidth() / 2
							local var_127_7 = var_127_0.chestPoint.x + var_127_6
							local var_127_8 = var_127_5 + var_127_0.chestPoint.y
							local var_127_9 = cc.Spawn:create(cc.ScaleTo:create(0.8, 0.1), cc.MoveTo:create(0.8, cc.p(var_127_7, var_127_8)))

							var_127_2:runActionOnce(var_127_9, true)
						end
					end

					for iter_127_1, iter_127_2 in pairs(arg_126_0.items) do
						local var_127_10 = {
							itemID = iter_127_2.table_id,
							itemNum = iter_127_2.item_num
						}

						arg_125_0.selfPlayer:getBackpack():removeItem(var_127_10)
					end

					for iter_127_3, iter_127_4 in pairs(arg_125_0.needPotion) do
						local var_127_11 = iter_127_4 * xyd.tables.item:exp(iter_127_3)

						var_126_0:addExp(var_127_11, xyd.tables.player:heroMaxLev(arg_125_0.selfPlayer.lev))
						arg_125_0:updateExp()
					end

					arg_125_0.selfPlayer.mana = arg_125_0.selfPlayer.mana - arg_125_0.needGold

					local var_127_12 = {}

					table.insert(var_127_12, xyd.JINJIE_ATTR_RATE * (var_126_0:getColor() - 1))
					table.insert(var_127_12, xyd.JINJIE_ATTR_RATE * (var_126_0:getColor() - 1))
					table.insert(var_127_12, xyd.JINJIE_ATTR_RATE * (var_126_0:getColor() - 1))

					arg_125_0.isShow = true

					var_127_0:win(false, handler(arg_125_0, arg_125_0.setIsShow))
					var_127_0:playAttribute(arg_125_0:getFloatAttrs(var_127_12))
					arg_125_0:updateEquip()
					arg_125_0:updateAttrScore()
					arg_125_0:updateAttrLabels()
					arg_125_0:updateIntroduceText()
					arg_125_0:updateScrollBg()
					arg_125_0:updateCollectWindow()
					arg_125_0:updateNameLabel()
					arg_125_0:setSkillContainer()
					arg_125_0:playRepeatingEffect()
					arg_125_0:CheckOneClick()
					audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))

					arg_125_0.refresh_ = true

					local var_127_13 = var_126_0:getMaxHP()
					local var_127_14 = var_126_0:getZhandouli()
					local var_127_15 = {
						type_ = xyd.LevelUpType.ADVANCE,
						hero = var_126_0,
						vals = {
							oldStar = var_126_2,
							oldColor = var_126_1,
							newColor = var_126_1 + 1,
							oldHP = var_126_3,
							newHP = var_127_13,
							oldForce = var_126_4,
							newForce = var_127_14
						}
					}

					if arg_127_1.restore_items and #arg_127_1.restore_items > 0 then
						function var_127_15.callback()
							xyd.WindowManager.get():openWindow("alert_award", {
								awards = arg_127_1.restore_items,
								name = var_0_11:translation("FUMO_RESTORE_NAME")
							})
						end

						for iter_127_5 = 1, #arg_127_1.restore_items do
							local var_127_16 = {
								itemID = arg_127_1.restore_items[iter_127_5].table_id,
								itemNum = arg_127_1.restore_items[iter_127_5].item_num
							}

							arg_125_0.selfPlayer:getBackpack():addItem(var_127_16)
						end
					end

					arg_125_0:runActionOnce(cc.CallFunc:create(function()
						xyd.WindowManager.get():openWindow("levelup", var_127_15)
					end), nil, nil, 1)
				else
					for iter_127_6, iter_127_7 in pairs(arg_126_0.items) do
						local var_127_17 = {
							itemID = iter_127_7.table_id,
							itemNum = iter_127_7.item_num
						}

						arg_125_0.selfPlayer:getBackpack():removeItem(var_127_17)
					end

					for iter_127_8, iter_127_9 in pairs(arg_125_0.needPotion) do
						local var_127_18 = iter_127_9 * xyd.tables.item:exp(iter_127_8)

						var_126_0:addExp(var_127_18, xyd.tables.player:heroMaxLev(arg_125_0.selfPlayer.lev))
						arg_125_0:updateExp()
					end

					arg_125_0.selfPlayer.mana = arg_125_0.selfPlayer.mana - arg_125_0.needGold

					local var_127_19 = {}

					table.insert(var_127_19, xyd.JINJIE_ATTR_RATE * (var_126_0:getColor() - 1))
					table.insert(var_127_19, xyd.JINJIE_ATTR_RATE * (var_126_0:getColor() - 1))
					table.insert(var_127_19, xyd.JINJIE_ATTR_RATE * (var_126_0:getColor() - 1))

					arg_125_0.isShow = true

					local var_127_20 = arg_125_0:getHeroModel()

					arg_125_0.isShow = true

					var_127_20:win(false, handler(arg_125_0, arg_125_0.setIsShow))
					var_127_20:playAttribute(arg_125_0:getFloatAttrs(var_127_19))
					arg_125_0:updateEquip()
					arg_125_0:updateAttrScore()
					arg_125_0:updateAttrLabels()
					arg_125_0:updateIntroduceText()
					arg_125_0:updateScrollBg()
					arg_125_0:updateCollectWindow()
					arg_125_0:updateNameLabel()
					arg_125_0:setSkillContainer()
					arg_125_0:playRepeatingEffect()
					arg_125_0:CheckOneClick()
					audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))

					arg_125_0.refresh_ = true
				end
			end
		end)
	end

	arg_125_0:CheckOneClick()

	local var_125_1 = 1
	local var_125_2 = {}

	for iter_125_0, iter_125_1 in pairs(arg_125_0.needEquip) do
		var_125_2[var_125_1] = {
			table_id = iter_125_0,
			item_num = iter_125_1
		}
		var_125_1 = var_125_1 + 1
	end

	for iter_125_2, iter_125_3 in pairs(arg_125_0.needPotion) do
		var_125_2[var_125_1] = {
			table_id = iter_125_2,
			item_num = iter_125_3
		}
		var_125_1 = var_125_1 + 1
	end

	if arg_125_0.needGold ~= 0 then
		var_125_2[var_125_1] = {
			table_id = 0,
			item_num = arg_125_0.needGold
		}
	end

	local var_125_3 = {
		isPet = true,
		items = var_125_2,
		heroName = arg_125_0.hero:getName()
	}

	xyd.AdvancedTipWindow.open(var_125_3, function(arg_130_0)
		if arg_130_0 then
			var_125_0(var_125_3)
		end
	end)
end

function var_0_4.clickOneKeyEquipsButton(arg_131_0)
	local function var_131_0(arg_132_0)
		local var_132_0 = arg_131_0.hero
		local var_132_1 = {}

		for iter_132_0, iter_132_1 in pairs(arg_131_0.canEquipIndex) do
			local var_132_2 = var_132_0:getEquipByIndex(iter_132_1):getAttr()

			for iter_132_2, iter_132_3 in pairs(var_132_2) do
				var_132_1[iter_132_2] = (var_132_1[iter_132_2] or 0) + iter_132_3
			end
		end

		return var_132_1
	end

	local function var_131_1()
		local var_133_0 = arg_131_0.hero
		local var_133_1 = var_133_0:getColor()
		local var_133_2 = var_133_0:getStar()
		local var_133_3 = var_133_0:getMaxHP()
		local var_133_4 = var_133_0:getZhandouli()
		local var_133_5 = cc.p(arg_131_0:getHeroContainer():getPosition())
		local var_133_6 = arg_131_0:getHeroContainer():getContentSize()

		var_133_5.x = var_133_5.x
		var_133_5.y = var_133_5.y + var_133_6.height * 0.5

		arg_131_0:playEffect(arg_131_0.mainContainer, "Upgrade", var_133_5, true)
		var_133_0:oneKeyEquip(arg_131_0.canEquipIndex, function()
			for iter_134_0, iter_134_1 in pairs(arg_131_0.needEquip2Equip) do
				local var_134_0 = {
					itemID = iter_134_0,
					itemNum = iter_134_1
				}

				arg_131_0.selfPlayer:getBackpack():removeItem(var_134_0)
			end

			for iter_134_2, iter_134_3 in pairs(arg_131_0.needPotion2Equip) do
				local var_134_1 = {
					itemID = iter_134_2,
					itemNum = iter_134_3
				}

				arg_131_0.selfPlayer:getBackpack():removeItem(var_134_1)

				local var_134_2 = iter_134_3 * xyd.tables.item:exp(iter_134_2)

				var_133_0:addExp(var_134_2, xyd.tables.player:heroMaxLev(arg_131_0.selfPlayer.lev))
				arg_131_0:updateExp()
			end

			arg_131_0.selfPlayer.mana = arg_131_0.selfPlayer.mana - arg_131_0.needGold2Equip

			local var_134_3 = arg_131_0:getHeroModel()

			arg_131_0.isShow = true

			var_134_3:win(false, handler(arg_131_0, arg_131_0.setIsShow))
			var_134_3:playAttribute(var_131_0(arg_131_0.canEquipIndex))
			arg_131_0:updateEquip()
			arg_131_0:updateAttrScore()
			arg_131_0:updateAttrLabels()
			arg_131_0:updateIntroduceText()
			arg_131_0:updateScrollBg()
			arg_131_0:updateCollectWindow()
			arg_131_0:updateNameLabel()
			arg_131_0:setSkillContainer()
			arg_131_0:playRepeatingEffect()
			arg_131_0:CheckOneClick()
			audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))
		end)
	end

	arg_131_0:checkOneKeyEquips()

	local var_131_2 = {}

	for iter_131_0, iter_131_1 in pairs(arg_131_0.needEquip2Equip) do
		table.insert(var_131_2, {
			table_id = iter_131_0,
			item_num = iter_131_1
		})
	end

	for iter_131_2, iter_131_3 in pairs(arg_131_0.needPotion2Equip) do
		if iter_131_3 ~= 0 then
			table.insert(var_131_2, {
				table_id = iter_131_2,
				item_num = iter_131_3
			})
		end
	end

	if arg_131_0.needGold2Equip ~= 0 then
		table.insert(var_131_2, {
			table_id = 0,
			item_num = arg_131_0.needGold2Equip
		})
	end

	local var_131_3 = {
		items = var_131_2,
		heroName = arg_131_0.hero:getName()
	}

	xyd.OneKeyEquipTipWindow.open(var_131_3, function(arg_135_0)
		if arg_135_0 then
			var_131_1()
		end
	end)
end

function var_0_4.setjinjieBtn(arg_136_0, arg_136_1)
	if arg_136_1 == var_0_14 then
		arg_136_0:nodeByName("button_jinjie"):setVisible(false)
		arg_136_0:nodeByName("button_onekeyequips"):setVisible(false)
		arg_136_0:nodeByName("button_yijian"):setVisible(true)
	elseif arg_136_1 == var_0_15 then
		arg_136_0:nodeByName("button_jinjie"):setVisible(false)
		arg_136_0:nodeByName("button_onekeyequips"):setVisible(true)
		arg_136_0:nodeByName("button_yijian"):setVisible(false)
	else
		arg_136_0:nodeByName("button_jinjie"):setVisible(true)
		arg_136_0:nodeByName("button_onekeyequips"):setVisible(false)
		arg_136_0:nodeByName("button_yijian"):setVisible(false)
	end
end

function var_0_4.willClose(arg_137_0)
	if arg_137_0.sendSkillLevUpRequest then
		arg_137_0:sendSkillLevUpRequest()
	end

	if arg_137_0.eatHandler[var_0_17] ~= nil then
		var_0_10.unscheduleGlobal(arg_137_0.eatHandler[var_0_17])
	end

	if arg_137_0.eatHandler[var_0_18] ~= nil then
		var_0_10.unscheduleGlobal(arg_137_0.eatHandler[var_0_18])
	end

	if arg_137_0.skillTextHandle then
		var_0_10.unscheduleGlobal(arg_137_0.skillTextHandle)
	end

	if arg_137_0.skillClickHandle then
		var_0_10.unscheduleGlobal(arg_137_0.skillClickHandle)
	end
end

function var_0_4.getHeroContainer(arg_138_0)
	if not arg_138_0.heroContainer_ then
		arg_138_0.heroContainer_ = arg_138_0:nodeByName("hero_container")

		arg_138_0.heroContainer_:setLocalZOrder(100)
	end

	return arg_138_0.heroContainer_
end

function var_0_4.updateEquip(arg_139_0, arg_139_1)
	arg_139_1 = arg_139_1 or arg_139_0.hero

	if arg_139_0.equipContainerlist_ then
		for iter_139_0, iter_139_1 in ipairs(arg_139_0.equipContainerlist_) do
			iter_139_1:removeAllNodeEventListeners()
			iter_139_1:removeSelf()
		end

		arg_139_0.equipContainerlist_ = nil
	end

	for iter_139_2 = 1, var_0_1 do
		local var_139_0 = arg_139_0:getEquipContainerByIndex(iter_139_2)
		local var_139_1 = arg_139_1:getEquipByIndex(iter_139_2)

		var_139_0:setTouchEnabled(true)
		var_139_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_140_0)
			if arg_140_0.name == "ended" then
				local var_140_0
				local var_140_1, var_140_2 = arg_139_0.task:isActiveAwake(arg_139_1:getTableID(), xyd.AwakeType.PET)

				if not var_140_1 then
					var_140_0 = false
					var_140_1 = xyd.tables.mission:getMissionIDByTableIDAndStage(arg_139_1:getTableID(), 1)
				else
					var_140_0 = true
				end

				local function var_140_3(arg_141_0)
					local var_141_0 = {
						table_id = arg_141_0.missionID
					}

					xyd.Backend.get():request(xyd.mid.OPEN_PET_AWAKE_MISSION, var_141_0, function(arg_142_0, arg_142_1)
						if arg_142_0 == xyd.error.OK then
							local var_142_0 = xyd.WindowManager.get():getWindow("pet_main")

							if var_142_0 and not tolua.isnull(var_142_0) then
								var_142_0:update()

								var_142_0.refresh_ = true
							end
						end
					end)
				end

				if var_140_2 or var_139_1:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_139_1:getTableID()) == 0 or arg_139_1:isAwaken() then
					arg_139_0:showItemDetail(iter_139_2)
				elseif arg_139_1:getLevel() < xyd.tables.misc.awakenOpenLev then
					local var_140_4 = {
						txt = var_0_11:translation("PET_AWAKE_CAN_NOT_OPEN"),
						type = xyd.CommonAlertType.ONE_BTN,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_140_4)
				elseif var_139_1:getTableID() == 0 or xyd.tables.hero:isCanAwaken(arg_139_1:getTableID()) == 0 and xyd.tables.item:isAwakenItem(var_139_1:getTableID()) == 1 then
					local var_140_5 = {
						txt = var_0_11:translation("PET_AWAKE_MISSION_NOT_EXIST"),
						type = xyd.CommonAlertType.ONE_BTN,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_140_5)
				elseif arg_139_0.task:isHasAwakeOpen(xyd.AwakeType.PET) then
					local var_140_6 = {
						txt = var_0_11:translation("CAN_NOT_OPEN_AWAKE_MISSION"),
						type = xyd.CommonAlertType.ONE_BTN,
						align = xyd.ui_align.CENTER
					}

					xyd.WindowManager.get():openWindow("common_alert", var_140_6)
				elseif var_140_0 then
					local var_140_7 = {
						txt = string.format(var_0_11:translation("OPEN_AWAKE_MISSION_AGAIN"), arg_139_1:getName()),
						type = xyd.CommonAlertType.TWO_BTN,
						rcallback = var_140_3,
						align = xyd.ui_align.CENTER,
						callbackParams = {
							missionID = var_140_1
						}
					}

					xyd.WindowManager.get():openWindow("common_alert", var_140_7)
				else
					local var_140_8 = {
						txt = string.format(var_0_11:translation("FIRST_TIME_OPEN_AWAKE_MISSION"), arg_139_1:getName()),
						type = xyd.CommonAlertType.TWO_BTN,
						rcallback = var_140_3,
						align = xyd.ui_align.CENTER,
						callbackParams = {
							missionID = var_140_1
						}
					}

					xyd.WindowManager.get():openWindow("common_alert", var_140_8)
				end
			end

			return true
		end)
	end
end

function var_0_4.getEquipContainerByIndex(arg_143_0, arg_143_1)
	local var_143_0 = arg_143_0.hero

	if not arg_143_0.equipContainerlist_ then
		arg_143_0.equipContainerlist_ = {}

		for iter_143_0 = 1, var_0_1 do
			local var_143_1 = arg_143_0:nodeByName("pos_node" .. iter_143_0)
			local var_143_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip.csb")

			var_143_2:setContentSize(var_143_2:getChildByName("background"):getContentSize())

			local var_143_3 = var_143_2:getContentSize()
			local var_143_4 = var_143_2:getChildByName("green_plus")
			local var_143_5 = var_143_2:getChildByName("white_plus")
			local var_143_6 = var_143_2:getChildByName("green_label")
			local var_143_7 = var_143_2:getChildByName("gray_label")

			var_143_6:enableOutline(cc.c4b(69, 69, 69, 255), 2)
			var_143_7:enableOutline(cc.c4b(69, 69, 69, 255), 2)
			var_143_4:setVisible(false)
			var_143_5:setVisible(false)
			var_143_7:setVisible(false)
			var_143_6:setVisible(false)
			var_143_2:setName("equip_container" .. iter_143_0)
			var_143_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_143_2:setPosition(var_143_1:getPosition())
			var_143_2:addTo(arg_143_0.mainContainer, var_143_1:getLocalZOrder())
			table.insert(arg_143_0.equipContainerlist_, var_143_2)

			local var_143_8 = var_143_0:getEquipByIndex(iter_143_0)
			local var_143_9, var_143_10 = arg_143_0.task:isActiveAwake(var_143_0:getTableID(), xyd.AwakeType.PET)

			if not var_143_8:isCollected() and (var_143_8:getTableID() == 0 or xyd.tables.item:isAwakenItem(var_143_8:getTableID()) == 1) and not var_143_0:isAwaken() and not var_143_10 then
				var_143_2:getChildByName("awake_equip_hide"):setVisible(true)

				if not arg_143_0.task:isHasAwakeOpen(xyd.AwakeType.PET) and xyd.tables.hero:isCanAwaken(var_143_0:getTableID()) == 1 and var_143_0:getLevel() >= xyd.tables.misc.awakenOpenLev then
					local var_143_11 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new.json"
					local var_143_12 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new.atlas"

					arg_143_0.awakeEffect = var_0_12.new(var_143_11, var_143_12, 1)

					arg_143_0.awakeEffect:addTo(var_143_2)
					arg_143_0.awakeEffect:setPosition(var_143_2:getWidth() / 2, var_143_2:getHeight() / 2)
					arg_143_0.awakeEffect:play(nil, true)
					arg_143_0.awakeEffect:setName("awake_effect")
				end
			else
				var_143_2:getChildByName("awake_equip_hide"):setVisible(false)

				local var_143_13 = var_143_8:getFumoLev()
				local var_143_14 = var_143_2:getChildByName("icon")

				xyd.setSpecialItemBorderNewUI(var_143_14, var_143_8:getTableID(), not var_143_8:isCollected())

				if not var_143_8:isCollected() and var_143_8:isInBackpack() and var_143_0:getLevel() >= var_143_8:getLevel() then
					var_143_4:setVisible(true)
					var_143_6:setString(var_0_11:translation("HERO_MAIN_HAVE_ITEM"))
					var_143_6:setVisible(true)
				elseif not var_143_8:isCollected() and var_143_8:isInBackpack() and var_143_0:getLevel() < var_143_8:getLevel() then
					var_143_5:setVisible(true)
					var_143_7:setString(var_0_11:translation("HERO_MAIN_NO_EQUIP"))
					var_143_7:setVisible(true)
				elseif not var_143_8:isCollected() and not var_143_8:isInBackpack() and var_143_8:isHasMaterial() and var_143_0:getLevel() >= var_143_8:getLevel() then
					var_143_4:setVisible(true)
					var_143_6:setString(var_0_11:translation("HERO_MAIN_CAN_COMPOSE"))
					var_143_6:setVisible(true)
				elseif not var_143_8:isCollected() and not var_143_8:isInBackpack() and var_143_8:isHasMaterial() and var_143_0:getLevel() < var_143_8:getLevel() then
					var_143_5:setVisible(true)
					var_143_7:setString(var_0_11:translation("HERO_MAIN_CAN_COMPOSE"))
					var_143_7:setVisible(true)
				elseif not var_143_8:isCollected() and not var_143_8:isInBackpack() and not var_143_8:isHasMaterial() then
					var_143_7:setString(var_0_11:translation("HERO_MAIN_NO_ITEM"))
					var_143_7:setVisible(true)
				end
			end
		end
	end

	return arg_143_0.equipContainerlist_[arg_143_1]
end

function var_0_4.getSpineEffect(arg_144_0, arg_144_1)
	local var_144_0 = var_0_13[arg_144_1] .. ".json"
	local var_144_1 = var_0_13[arg_144_1] .. ".atlas"

	return (var_0_12.new(var_144_0, var_144_1, 1))
end

function var_0_4.updateCollectWindow(arg_145_0)
	local var_145_0 = xyd.WindowManager.get():getWindow("pet_collect")

	if var_145_0 then
		var_145_0:refreshSelectedHeroClass()
	end
end

function var_0_4.getFloatAttrs(arg_146_0, arg_146_1)
	local var_146_0 = clone(arg_146_1)

	if arg_146_1[1] and arg_146_1[1] > 0 then
		var_146_0[xyd.AttributeType.HP] = math.ceil((var_146_0[xyd.AttributeType.HP] or 0) + arg_146_1[1] * xyd.STRENGTH_HP_RATE)
		var_146_0[xyd.AttributeType.HUJIA] = math.ceil((var_146_0[xyd.AttributeType.HUJIA] or 0) + arg_146_1[1] * xyd.STRENGTH_HUJIA_RATE)
	end

	if arg_146_1[2] and arg_146_1[2] > 0 then
		var_146_0[xyd.AttributeType.AP] = math.ceil((var_146_0[xyd.AttributeType.AP] or 0) + arg_146_1[2] * xyd.WISE_AP_RATE)
		var_146_0[xyd.AttributeType.MOKANG] = math.ceil((var_146_0[xyd.AttributeType.MOKANG] or 0) + arg_146_1[2] * xyd.WISE_MOKANG_RATE)
	end

	if arg_146_1[3] and arg_146_1[3] > 0 then
		var_146_0[xyd.AttributeType.AD] = math.ceil((var_146_0[xyd.AttributeType.AD] or 0) + arg_146_1[3] * xyd.AGILE_AD_RATE)
		var_146_0[xyd.AttributeType.HUJIA] = math.ceil((var_146_0[xyd.AttributeType.HUJIA] or 0) + arg_146_1[3] * xyd.AGILE_HUJIA_RATE)
		var_146_0[xyd.AttributeType.AD_BAOJI] = math.ceil((var_146_0[xyd.AttributeType.AD_BAOJI] or 0) + arg_146_1[3] * xyd.AGILE_AD_BAOJI_RATE)
	end

	if arg_146_1[arg_146_0.hero:getHeroType()] then
		var_146_0[xyd.AttributeType.AD] = (var_146_0[xyd.AttributeType.AD] or 0) + arg_146_1[arg_146_0.hero:getHeroType()]
	end

	return var_146_0
end

function var_0_4.playGuide(arg_147_0, arg_147_1)
	local var_147_0
	local var_147_1 = 0
	local var_147_2 = 0

	if arg_147_1 == var_0_3 then
		-- block empty
	elseif arg_147_1 == var_0_2 then
		var_147_0 = arg_147_0:nodeByName("button_jingyan")
	end

	local var_147_3 = var_147_0:getPositionX()
	local var_147_4 = var_147_0:getPositionY()

	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_147_5 = xyd.WindowManager.get():openWindow("guide")
	local var_147_6 = arg_147_0:convertToNodeSpace(var_147_0:getParent():convertToWorldSpace(cc.p(var_147_3, var_147_4)))

	var_147_5:addNode()
	var_147_5:setStencil(var_147_0:getContentSize().width + var_147_1, var_147_0:getContentSize().height + var_147_2, var_147_6.x, var_147_6.y, 2)
end

function var_0_4.allPotionsExpInBackPack(arg_148_0)
	local var_148_0 = 0
	local var_148_1 = {
		50001087,
		50001088,
		50001089
	}

	for iter_148_0, iter_148_1 in pairs(var_148_1) do
		var_148_0 = var_148_0 + arg_148_0.selfPlayer:getBackpack():getItemNumByID(iter_148_1) * xyd.tables.item:exp(iter_148_1)
	end

	return var_148_0
end

function var_0_4.updateBtnShow(arg_149_0)
	if arg_149_0:isHeroCanEvolve() then
		arg_149_0:nodeByName("button_jinhua"):setVisible(true)
		arg_149_0:nodeByName("button_linghunshi"):setVisible(false)
	else
		arg_149_0:nodeByName("button_jinhua"):setVisible(false)
		arg_149_0:nodeByName("button_linghunshi"):setVisible(true)
	end
end

function var_0_4.isHeroCanEvolve(arg_150_0)
	local var_150_0 = arg_150_0.hero

	if var_150_0:getStar() >= xyd.MAX_STAR_LEVEL or var_150_0:getSuiPian() < xyd.StarLevelSuipian[var_150_0:getStar() + 1] then
		return false
	end

	return true
end

return var_0_4
