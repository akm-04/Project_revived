local var_0_0 = class("ScrollView", cc.ui.UIScrollView)
local var_0_1 = "fonts/main_font.ttf"

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.setScrollWidth(arg_2_0, arg_2_1)
	arg_2_0.scrollWidth = arg_2_1
end

function var_0_0.setScrollHeight(arg_3_0, arg_3_1)
	arg_3_0.scrollHeight = arg_3_1
end

local var_0_2 = 0
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 3
local var_0_6 = {
	5,
	6,
	7,
	8,
	9,
	4,
	1,
	2,
	3
}
local var_0_7 = class("HeroMainWindow", import("app.common.ui.BaseWindow"))
local var_0_8 = import("app.common.ui.WndTopSidebar")
local var_0_9 = 1
local var_0_10 = 2
local var_0_11 = 3
local var_0_12 = 1
local var_0_13 = 2
local var_0_14 = 3
local var_0_15 = 4
local var_0_16 = 5
local var_0_17 = require("framework.scheduler")
local var_0_18 = xyd.tables.elementEquip
local var_0_19 = xyd.tables.hero
local var_0_20 = xyd.tables.item
local var_0_21 = xyd.tables.translation
local var_0_22 = xyd.tables.inscriptionSuit
local var_0_23 = xyd.tables.stoneEvolution
local var_0_24 = xyd.tables.skinDynamic
local var_0_25 = xyd.tables.skinSkill
local var_0_26 = xyd.tables.misc:getValue("skill_interval")
local var_0_27 = xyd.tables.misc:getValue("skill_speed_up")
local var_0_28 = import("app.common.tables.AvartarMallTable").new()
local var_0_29 = import("app.common.ui.SpineEffect")
local var_0_30 = {}

var_0_30.AddItem = "skeletons/ui_effect/common_effect_hero2/common_effect_hero2_new"
var_0_30.CanUpgrade = "skeletons/ui_effect/common_effect_hero12/new_advanced"
var_0_30.CanBreach = "skeletons/ui_effect/common_effect_hero12/new_advanced"
var_0_30.Upgrade = "skeletons/ui_effect/common_effect_hero3/common_effect_hero3"
var_0_30.Evolve = "skeletons/ui_effect/common_effect_hero4/common_effect_hero4"
var_0_30.SkillUp = "skeletons/ui_effect/common_effect_hero7/common_effect_hero7"
var_0_30.CanSummon = "skeletons/ui_effect/common_effect_hero8/common_effect_hero8"
var_0_30.LevelUp = "skeletons/ui_effect/common_effect_exp_lv_up/common_effect_exp_lv_up"
var_0_30.Fuwen2_1 = "skeletons/ui_effect/huizhang/fuwenlizi"
var_0_30.Fuwen2_2 = "skeletons/ui_effect/huizhang/fuwenlizi"
var_0_30.Fuwen2_3 = "skeletons/ui_effect/huizhang/fuwenlizi"
var_0_30.Fuwen3 = "skeletons/ui_effect/huizhang/fuwenxian2"
var_0_30.CanEvolve = "skeletons/ui_effect/common_effect_hero15/effect_tupo"
var_0_30.Background1 = "skeletons/ui_effect/hero/hero_bg_effect01"
var_0_30.Background2 = "skeletons/ui_effect/hero/hero_bg_effect02"
var_0_30.Starup = "skeletons/ui_effect/hero/star_up"

local var_0_31 = {
	Origin = 1,
	Super = 3,
	Normal = 2
}
local var_0_32 = {
	Element = 2,
	Normal = 1
}
local var_0_33 = {
	Inscription = 5,
	Skill = 4,
	Book = 2,
	Card = 6,
	Info = 3,
	Skin = 1
}

function var_0_7.ctor(arg_4_0, arg_4_1, arg_4_2)
	var_0_7.super.ctor(arg_4_0, arg_4_1, arg_4_2)

	if arg_4_2 then
		arg_4_0.heros_ = arg_4_2.heros
		arg_4_0.current_ = arg_4_2.current
		arg_4_0.hero = arg_4_0.heros_[arg_4_0.current_]
		arg_4_0.scrolly = arg_4_2.scrolly
	end

	arg_4_0.UIEffects = {}
	arg_4_0.skillTips = {}
	arg_4_0.visibleHandler = {}
	arg_4_0.handler = {}
	arg_4_0.skillLevel = {}
	arg_4_0.skillClickHandle = {}
	arg_4_0.cache = {}
	arg_4_0.needEquip = {}
	arg_4_0.needPotion = {}
	arg_4_0.needGold = 0
	arg_4_0.isCardShow = false
	arg_4_0.equipType = var_0_32.Normal
	arg_4_0.scroll_moving_end = false
	arg_4_0.scroll_is_moving = false
	arg_4_0.isTrySkin = false
	arg_4_0.trySkinModelID = 0
	arg_4_0.useStoneType = var_0_31.Origin
	arg_4_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_4_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_4_0.course = xyd.ModelManager.get():loadModel(xyd.ModelType.COURSE)
	arg_4_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_4_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_4_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_4_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_4_0.backpack = arg_4_0.selfPlayer:getBackpack()
	arg_4_0.giftPush = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
end

function var_0_7.willOpen(arg_5_0, arg_5_1)
	var_0_7.super:willOpen(arg_5_1)
	arg_5_0:addTopSidebar()
	arg_5_0:nodeByName("borrow_container"):setVisible(false)
	arg_5_0:nodeByName("normal_container"):setVisible(true)

	arg_5_0.maxLev = xyd.tables.player:heroMaxLev(arg_5_0.selfPlayer.lev)
	arg_5_0.skillPoints = arg_5_0.selfPlayer:getSkillPoint()

	arg_5_0:layout()
end

function var_0_7.addTopSidebar(arg_6_0)
	arg_6_0:setTouchEnabled(true)
	arg_6_0:setTouchSwallowEnabled(true)

	if arg_6_0:nodeByName("top_sidebar") then
		return
	end

	local var_6_0 = {
		colorMode = arg_6_0.colorMode,
		parent = arg_6_0,
		title = xyd.tables.window:title(arg_6_0.name)
	}
	local var_6_1 = var_0_8.new(xyd.WidgetName.wndTopSidebar, var_6_0)

	var_6_1:setAnchorPoint(0, 1)
	var_6_1:addTo(arg_6_0:nodeByName("background_top"))
	var_6_1:setPosition(0, 720)

	arg_6_0.children_.top_sidebar = var_6_1
	arg_6_0.children_.eco_sidebar = var_6_1:nodeByName("eco_sidebar")
end

function var_0_7.didOpen(arg_7_0, arg_7_1)
	var_0_7.super:didOpen(arg_7_1)
	arg_7_0:update(arg_7_0.hero)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.ECONOMY, handler(arg_7_0, arg_7_0.updateSkillPoint))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.UPDATE_HERO_BOOK, function(arg_8_0)
		arg_7_0:updateBookContainer()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.HERO_ELEMENT_EQUIP_CHANGED, function(arg_9_0)
		arg_7_0:updateElementEquip()
		arg_7_0:updateNameLabel()
		arg_7_0:updateAttrScore()
		arg_7_0:updateAttrLabels()
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.FRESH_EQUIPED_INSCRIPTION, function(arg_10_0)
		if arg_7_0 and not tolua.isnull(arg_7_0) then
			arg_7_0:updateAttrLabels()
			arg_7_0:updateInscription()
			arg_7_0:updateAttrScore()
			arg_7_0:updateAttrLabels()
			arg_7_0:updateInfoChart()
			arg_7_0:updateRecommendInfo()
			arg_7_0:updateIntroduceText()
			arg_7_0:updateScrollBg()
			arg_7_0:updateNameLabel()
			arg_7_0:updateCollectWindow()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.REFRESH_FAVOR_INFO, function(arg_11_0)
		if arg_7_0 then
			arg_7_0:updateFavor()
		end
	end)
	arg_7_0:updateText()
	arg_7_0:playGuide()
end

function var_0_7.didClose(arg_12_0, arg_12_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	arg_12_0:unscheduleLevUpHandle()
	arg_12_0:unscheduleExpHandle()

	local var_12_0 = xyd.StoryData.get():getGuideID()

	if var_12_0 < xyd.GuideStoryType.GUIDE_EQUIP_END or var_12_0 == xyd.GuideStoryType.GUIDE_LEVUP_END or var_12_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_NINE or var_12_0 == xyd.GuideStoryType.GUIDE_SKILL_END and arg_12_0.isPlaySkillEndGuide then
		if var_12_0 < xyd.GuideStoryType.GUIDE_EQUIP_END then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_END)
			xyd.StoryData.get():persist()
		elseif var_12_0 == xyd.GuideStoryType.GUIDE_SKILL_END then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_6_START)
			xyd.StoryData.get():persist()
		end

		local var_12_1 = xyd.WindowManager.get():getWindow("hero_list")

		if var_12_1 and not tolua.isnull(var_12_1) then
			var_12_1:playGuide()
		end
	end
end

function var_0_7.onTimer(arg_13_0)
	if tolua.isnull(arg_13_0.skillContainer) then
		return
	end

	local var_13_0 = arg_13_0.skillContainer:getChildByName("point_time")
	local var_13_1 = arg_13_0.skillContainer:getChildByName("jinengdian")
	local var_13_2 = arg_13_0.skillContainer:getChildByName("point_full")

	arg_13_0.skillPoints = arg_13_0.selfPlayer:getSkillPoint()

	if arg_13_0.skillPoints < 0 then
		arg_13_0.skillPoints = 0
	end

	var_13_1:setString(arg_13_0.skillPoints)

	local var_13_3 = math.floor(arg_13_0.selfPlayer:getNextSkillRecoverDuration() / 60)
	local var_13_4 = arg_13_0.selfPlayer:getNextSkillRecoverDuration() % 60
	local var_13_5 = string.format("( %02d:%02d )", var_13_3, var_13_4)

	var_13_0:setVisible(true)
	var_13_0:setString(var_13_5)
	var_13_2:hide()

	if arg_13_0.skillPoints == arg_13_0.selfPlayer:getSkillPointLimit() then
		var_13_0:setVisible(false)
		var_13_2:setVisible(true)
		arg_13_0:updateSkillContainer()
		var_0_17.unscheduleGlobal(arg_13_0.timer)

		arg_13_0.timer = nil
	end
end

function var_0_7.updateSkillPoint(arg_14_0)
	if not arg_14_0.cache[var_0_33.Skill] then
		return
	end

	if tolua.isnull(arg_14_0.skillContainer) then
		return
	end

	arg_14_0.skillContainer:getChildByName("jinengdian"):setString(arg_14_0.selfPlayer.skillPoint)
	arg_14_0:CheckOneClick()
	arg_14_0:updateSuperHero()
end

function var_0_7.addBgEffect(arg_15_0)
	local var_15_0 = var_0_30.Background1 .. ".json"
	local var_15_1 = var_0_30.Background1 .. ".atlas"

	arg_15_0.bgEffect = var_0_29.new(var_15_0, var_15_1, 1)

	arg_15_0:nodeByName("background"):addChild(arg_15_0.bgEffect)
	arg_15_0.bgEffect:setPosition(303, 593)
	arg_15_0.bgEffect:play(nil, true)

	local var_15_2 = var_0_30.Background2 .. ".json"
	local var_15_3 = var_0_30.Background2 .. ".atlas"

	arg_15_0.bgEffect2 = var_0_29.new(var_15_2, var_15_3, 1)

	arg_15_0:nodeByName("background"):addChild(arg_15_0.bgEffect2)
	arg_15_0.bgEffect2:setPosition(303, 593)
	arg_15_0.bgEffect2:play(nil, true)
	arg_15_0.bgEffect2:setScaleX(0.74)
	arg_15_0.bgEffect2:setScaleY(1.17)
	arg_15_0.bgEffect2:setRotation(51.5)
end

function var_0_7.layout(arg_16_0)
	arg_16_0.mainContainer = arg_16_0:nodeByName("card_container")
	arg_16_0.cardContainer = arg_16_0:nodeByName("card_view")
	arg_16_0.cardBlock = arg_16_0:nodeByName("card_block")
	arg_16_0.homeCardContainer = arg_16_0:nodeByName("card")
	arg_16_0.infoContainer = arg_16_0:nodeByName("info_container")
	arg_16_0.skillContainer = arg_16_0:nodeByName("skill_container")
	arg_16_0.inscriptionContainer = arg_16_0:nodeByName("inscription_container")
	arg_16_0.breachContainer = arg_16_0:nodeByName("breach_container")
	arg_16_0.nameLabelContainer = arg_16_0:nodeByName("name_label")

	local var_16_0 = arg_16_0.skillContainer:getChildByName("point_time")
	local var_16_1 = arg_16_0.skillContainer:getChildByName("jinengdian")

	var_16_0:setString("")
	var_16_1:setString("")

	local var_16_2 = arg_16_0.skillContainer:getChildByName("point_full")

	var_16_2:setString("(" .. var_0_21:translation("SKILL_POINT_FULL") .. ")")
	var_16_2:setVisible(false)
	arg_16_0.skillContainer:getChildByName("jinengdian_des"):setString(var_0_21:translation("HERO_MAIN_LEFT_POINT"))
	arg_16_0.infoContainer:hide()

	local var_16_3 = arg_16_0.infoContainer:getContentSize()

	arg_16_0.skillContainer:hide()
	arg_16_0.breachContainer:hide()
	arg_16_0.inscriptionContainer:hide()
	arg_16_0.cardContainer:hide()
	arg_16_0.cardBlock:hide()

	arg_16_0.state = var_0_9
	arg_16_0.detailState = var_0_12

	arg_16_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.highlight)

	arg_16_0.containers = {}
	arg_16_0.containers[var_0_9] = arg_16_0:nodeByName("hero_detail_container")
	arg_16_0.containers[var_0_10] = arg_16_0:nodeByName("equip_info_container")
	arg_16_0.containers[var_0_11] = arg_16_0:nodeByName("book_container")
	arg_16_0.detailContainers = {}
	arg_16_0.detailContainers[var_0_12] = arg_16_0:nodeByName("card_container")
	arg_16_0.detailContainers[var_0_13] = arg_16_0:nodeByName("info_container")
	arg_16_0.detailContainers[var_0_14] = arg_16_0:nodeByName("skill_container")
	arg_16_0.detailContainers[var_0_15] = arg_16_0:nodeByName("breach_container")
	arg_16_0.detailContainers[var_0_16] = arg_16_0:nodeByName("inscription_container")
	arg_16_0.state2Btn = {}
	arg_16_0.state2Btn[var_0_9] = arg_16_0:nodeByName("btn_hero_detail")
	arg_16_0.state2Btn[var_0_10] = arg_16_0:nodeByName("btn_skin")
	arg_16_0.state2Btn[var_0_11] = arg_16_0:nodeByName("btn_book")

	arg_16_0.containers[var_0_11]:setPositionX(1280)
	arg_16_0.containers[var_0_11]:hide()
	arg_16_0.containers[var_0_10]:setPositionX(1280)
	arg_16_0.containers[var_0_10]:hide()
	arg_16_0:setupButtonClick()

	arg_16_0.scrollBg = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_16_3.width, var_16_3.height - 40)
	}):onScroll(handler(arg_16_0, arg_16_0.scrollListener)):setTouchType(true):setBounceable(true):pos(15, 20):addTo(arg_16_0.infoContainer)

	local var_16_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/info_container.csb")

	arg_16_0.scrollBg:addScrollNode(var_16_4)
	var_16_4:setName("info_scroll_node")
	var_16_4:removeChild(var_16_4:getChildByName("background"))
	arg_16_0:parseChildren_(var_16_4)

	local var_16_5 = arg_16_0.skillContainer:getChildByName("course_scroll")
	local var_16_6 = var_16_5:getContentSize()

	arg_16_0.courseList = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_16_6.width, var_16_6.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(var_16_5):onScroll(handler(arg_16_0, arg_16_0.scrollListener))

	arg_16_0:updateBreachContainer(true)
	arg_16_0:updateBtnShow()
	arg_16_0:updateElementEquip()

	if #arg_16_0.heros_ <= 1 then
		arg_16_0:nodeByName("last_hero"):setVisible(false)
		arg_16_0:nodeByName("next_hero"):setVisible(false)
	end

	arg_16_0:checkRedPointShow()
	arg_16_0:updateCollocationBtnShow()
end

function var_0_7.updateText(arg_17_0)
	arg_17_0:nodeByName("txt_skin"):setString(var_0_21:translation("HERO_MAIN_TEXT_14"))
	arg_17_0:nodeByName("txt_book"):setString(var_0_21:translation("HERO_MAIN_TEXT_15"))
	arg_17_0:nodeByName("txt_dorm"):setString(var_0_21:translation("HERO_MAIN_TEXT_16"))
	arg_17_0:nodeByName("txt_hunqi"):setString(var_0_21:translation("HUNQI_TEXT_20"))
	arg_17_0:nodeByName("txt_favor"):setString(var_0_21:translation("HERO_MAIN_TEXT_17"))
	arg_17_0:nodeByName("txt_super"):setString(var_0_21:translation("HERO_MAIN_TEXT_18"))
	arg_17_0:nodeByName("txt_tujian"):setString(var_0_21:translation("HERO_MAIN_TEXT_19"))
	arg_17_0:nodeByName("txt_main"):setString(var_0_21:translation("HERO_MAIN_TEXT_1"))
	arg_17_0:nodeByName("txt_shuxing"):setString(var_0_21:translation("HERO_MAIN_TEXT_2"))
	arg_17_0:nodeByName("txt_jineng"):setString(var_0_21:translation("HERO_MAIN_TEXT_3"))
	arg_17_0:nodeByName("txt_breach"):setString(var_0_21:translation("HERO_MAIN_TEXT_4"))
	arg_17_0:nodeByName("txt_inscription"):setString(var_0_21:translation("HERO_MAIN_TEXT_5"))
	arg_17_0:nodeByName("text_jinjie"):setString(var_0_21:translation("HERO_MAIN_TEXT_7"))
	arg_17_0:nodeByName("text_onkey_equip"):setString(var_0_21:translation("HERO_MAIN_TEXT_9"))
	arg_17_0:nodeByName("text_onkey_jinjie"):setString(var_0_21:translation("HERO_MAIN_TEXT_8"))
	arg_17_0:nodeByName("laizi_txt"):setString(var_0_21:translation("HERO_MAIN_TEXT_6"))
	arg_17_0:nodeByName("txt_jingyan"):setString(var_0_21:translation("HERO_MAIN_TEXT_13"))
	arg_17_0:nodeByName("attr_text"):setString(var_0_21:translation("HERO_MAIN_TEXT_20"))
	arg_17_0:nodeByName("modify_text"):setString(var_0_21:translation("HERO_MAIN_TEXT_22"))
	arg_17_0:nodeByName("breach_progress_text"):setString(var_0_21:translation("HERO_MAIN_TEXT_23"))
	arg_17_0:nodeByName("breach_text"):setString(var_0_21:translation("HERO_MAIN_TEXT_4"))
	arg_17_0:nodeByName("title_book"):setString(var_0_21:translation("HERO_MAIN_TEXT_15"))
	arg_17_0:nodeByName("detail_text"):setString(var_0_21:translation("HERO_MAIN_TEXT_41"))
	arg_17_0:nodeByName("text_title_des"):setString(var_0_21:translation("HERO_MAIN_TEXT_42"))
	arg_17_0:nodeByName("text_title_info"):setString(var_0_21:translation("HERO_MAIN_TEXT_43"))
	arg_17_0:nodeByName("text_element"):setString(var_0_21:translation("ELEMENT_EQUIP_TEXT15"))
	arg_17_0:nodeByName("text_normal"):setString(var_0_21:translation("ELEMENT_EQUIP_TEXT16"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_ad"):setString(var_0_21:translation("HERO_MAIN_TEXT_48"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_as"):setString(var_0_21:translation("HERO_MAIN_TEXT_52"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_march"):setString(var_0_21:translation("HERO_MAIN_TEXT_51"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_boss"):setString(var_0_21:translation("HERO_MAIN_TEXT_50"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_df"):setString(var_0_21:translation("HERO_MAIN_TEXT_49"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_pk"):setString(var_0_21:translation("HERO_MAIN_TEXT_53"))
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_ad"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_as"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_march"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_boss"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_df"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("chart_container"):getChildByName("txt_pk"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("txt_skin_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("text_skin_last_time"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("txt_skin_model1"):setString(var_0_21:translation("AVARTAR_POSE"))
	arg_17_0:nodeByName("txt_skin_model2"):setString(var_0_21:translation("AVARTAR_POSE_TWOPOINTFIVE"))
	arg_17_0:nodeByName("txt_skin_skill1"):setString(var_0_21:translation("AVARTAR_POSE_EQUIP_SKILL"))
	arg_17_0:nodeByName("txt_skin_skill2"):setString(var_0_21:translation("AVARTAR_POSE_CLICK_BUTTO"))
	arg_17_0:nodeByName("txt_skin_time"):setString(var_0_21:translation("AVARTAR_POSE_COUNTDOWN"))
	arg_17_0:nodeByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_PAY"))
	arg_17_0:nodeByName("txt_skin_is_equipping"):setString(var_0_21:translation("AVARTAR_POSE_EUIPED"))
	arg_17_0:nodeByName("txt_skin_skill_other"):setString(var_0_21:translation("AVARTAR_POSE_SKILL"))
	arg_17_0:nodeByName("txt_hero_detail"):setString(var_0_21:translation("AVARTAR_POSE_DETAIL"))
	arg_17_0:nodeByName("txt_forum"):setString(var_0_21:translation("SENIOR_FORUM_TITLE"))
	arg_17_0:nodeByName("txt_collocation_1"):setString(var_0_21:translation("HERO_MAIN_TEXT_60"))
	arg_17_0:nodeByName("txt_collocation_2"):setString(var_0_21:translation("HERO_MAIN_TEXT_61"))
	arg_17_0:nodeByName("txt_skin_is_equipping"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_17_0:nodeByName("txt_collocation_1"):enableOutline(cc.c4b(80, 69, 69, 255), 2)
	arg_17_0:nodeByName("txt_collocation_2"):enableOutline(cc.c4b(65, 65, 65, 255), 2)
end

function var_0_7.updateCourseInfo(arg_18_0)
	if not arg_18_0.cache[var_0_33.Skill] then
		return
	end

	arg_18_0.courseList:removeAllItems()

	local var_18_0 = arg_18_0.hero:getEqupedCoursesInfo()
	local var_18_1 = table.keys(var_18_0)

	if arg_18_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_COURSE) ~= true then
		arg_18_0:nodeByName("course_modify_btn"):setVisible(false)
		arg_18_0:nodeByName("course_text"):setString("")
	elseif #var_18_1 == 0 then
		arg_18_0:nodeByName("course_text"):setString(var_0_21:translation("COURSE_NOT_EQUIP_TIP"))
	else
		arg_18_0:nodeByName("course_modify_btn"):setVisible(true)
		arg_18_0:nodeByName("course_text"):setString(var_0_21:translation("COURSE_TEXT"))
	end

	arg_18_0:nodeByName("course_text"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	for iter_18_0 = 1, #var_18_1 do
		local var_18_2
		local var_18_3 = arg_18_0.courseList:dequeueItem()

		if not var_18_3 then
			var_18_3 = arg_18_0.courseList:newItem()
		else
			var_18_3:removeAllChildren(true)
		end

		local var_18_4 = arg_18_0:createCourseContent(tonumber(var_18_1[iter_18_0]), var_18_0[var_18_1[iter_18_0]])
		local var_18_5 = var_18_4:getWidth()
		local var_18_6 = var_18_4:getHeight()

		var_18_3:setItemSize(var_18_5, var_18_6)
		var_18_3:addContent(var_18_4)
		arg_18_0.courseList:addItem(var_18_3)
		arg_18_0.courseList:reload()
	end
end

function var_0_7.createCourseContent(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = xyd.tables.objectBook
	local var_19_1 = 50
	local var_19_2 = display.newNode()

	var_19_2:setContentSize(var_19_1, var_19_1)

	local var_19_3 = var_19_0:icon(arg_19_1)

	xyd.setSpriteBorder(var_19_2, var_19_3, arg_19_2.quality)

	return var_19_2
end

function var_0_7.playActions(arg_20_0)
	if not arg_20_0.actions_ then
		arg_20_0.actions_ = {}

		local var_20_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
		local var_20_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

		arg_20_0.actions_[1] = cc.RepeatForever:create(var_20_0)
		arg_20_0.actions_[2] = cc.RepeatForever:create(var_20_1)

		arg_20_0:getLastHeroArrow():runAction(arg_20_0.actions_[1])
		arg_20_0:getNextHeroArrow():runAction(arg_20_0.actions_[2])
	end
end

function var_0_7.playEffect(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4, arg_21_5)
	local var_21_0

	arg_21_5 = arg_21_5 or false

	if arg_21_0.UIEffects[arg_21_2] and not tolua.isnull(arg_21_0.UIEffects[arg_21_2]) then
		var_21_0 = arg_21_0.UIEffects[arg_21_2]
	else
		local var_21_1 = var_0_30[arg_21_2] .. ".json"
		local var_21_2 = var_0_30[arg_21_2] .. ".atlas"

		var_21_0 = var_0_29.new(var_21_1, var_21_2, 1)

		arg_21_1:addChild(var_21_0, 10)

		arg_21_0.UIEffects[arg_21_2] = var_21_0
	end

	var_21_0:pos(arg_21_3.x, arg_21_3.y)

	if arg_21_4 == true then
		var_21_0:setToSetupPose()
		var_21_0:setVisible(true)

		if arg_21_5 then
			var_21_0:play(function()
				return
			end, true)
		elseif arg_21_5 == false then
			var_21_0:play(function()
				return
			end)
		else
			var_21_0:play(function()
				var_21_0:setVisible(false)
			end)
		end
	else
		var_21_0:setVisible(false)
	end
end

function var_0_7.playRepeatingEffect(arg_25_0)
	local var_25_0 = arg_25_0.hero
	local var_25_1 = true

	for iter_25_0 = 1, 6 do
		local var_25_2 = var_25_0:getEquipByIndex(iter_25_0)

		if not var_25_2:isCollected() and var_25_2:getTableID() ~= 0 and var_0_20:isAwakenItem(var_25_2:getTableID()) == 0 then
			var_25_1 = false
		end

		if var_25_0:getColor() >= xyd.selfPlayer.maxHeroColor or xyd.isSuperHero(var_25_0) then
			var_25_1 = false
		end
	end

	if tolua.isnull(arg_25_0.mainContainer) then
		return
	end

	local var_25_3 = cc.p(arg_25_0.mainContainer:getChildByName("button_jinjie"):getPosition())

	var_25_3.x = var_25_3.x
	var_25_3.y = var_25_3.y

	arg_25_0:playEffect(arg_25_0.mainContainer, "CanUpgrade", var_25_3, var_25_1, true)

	local var_25_4 = arg_25_0:isHeroCanEvolve()
	local var_25_5 = cc.p(arg_25_0:nodeByName("button_jinhua"):getPosition())

	arg_25_0:playEffect(arg_25_0:nodeByName("normal_container"), "Starup", var_25_5, var_25_4, true)

	local var_25_6 = arg_25_0:isHeroCanBreach()
	local var_25_7 = cc.p(arg_25_0:nodeByName("breach_container"):getChildByName("breach_btn"):getPosition())

	var_25_7.x = var_25_7.x + 2

	arg_25_0:playEffect(arg_25_0:nodeByName("breach_container"), "CanBreach", var_25_7, var_25_6, true)
end

function var_0_7.getLastHeroArrow(arg_26_0)
	if not arg_26_0.lastArrow_ then
		local var_26_0 = arg_26_0:nodeByName("last_hero")

		var_26_0:setTouchEnabled(true)
		var_26_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
			if arg_27_0.name == "ended" then
				arg_26_0:lastHero()
			end

			return true
		end)
		var_26_0:setCascadeOpacityEnabled(true)

		arg_26_0.lastArrow_ = var_26_0
	end

	return arg_26_0.lastArrow_
end

function var_0_7.getNextHeroArrow(arg_28_0)
	if not arg_28_0.nextArrow_ then
		local var_28_0 = arg_28_0:nodeByName("next_hero")

		var_28_0:setTouchEnabled(true)
		var_28_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
			if arg_29_0.name == "ended" then
				arg_28_0:nextHero()

				if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SKILL_SIX then
					xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_SEVEN)
					arg_28_0:playGuide()
				end
			end

			return true
		end)

		arg_28_0.nextArrow_ = var_28_0

		var_28_0:setCascadeOpacityEnabled(true)
	end

	return arg_28_0.nextArrow_
end

function var_0_7.lastHero(arg_30_0)
	arg_30_0:unscheduleExpHandle()

	if arg_30_0.sendSkillLevUpRequest then
		arg_30_0:sendSkillLevUpRequest()
	end

	local function var_30_0()
		if arg_30_0.current_ > 1 then
			arg_30_0.current_ = arg_30_0.current_ - 1
		else
			arg_30_0.current_ = #arg_30_0.heros_
		end

		arg_30_0.hero = arg_30_0.heros_[arg_30_0.current_]

		if not arg_30_0.hero:isCollected() then
			var_30_0()
		end
	end

	if arg_30_0.scrolly then
		arg_30_0.scrolly = nil
	end

	if arg_30_0.frontState then
		arg_30_0.frontState = nil
	end

	arg_30_0.isTrySkin = false
	arg_30_0.trySkinModelID = 0

	var_30_0()
	arg_30_0:update()
	arg_30_0:updateBookContainer()
	arg_30_0:updateInscription()
	arg_30_0:updateBreachContainer()
	arg_30_0:updateCourseInfo()
	arg_30_0:resetEffect()
	arg_30_0:updateBtnShow()
	arg_30_0:updateElementEquip()
	arg_30_0:checkRedPointShow()
	arg_30_0:updateCollocationBtnShow()

	if not arg_30_0.elementEquipOpen then
		arg_30_0:nodeByName("normal_equipment"):show()
		arg_30_0:nodeByName("element_equipment"):hide()
		arg_30_0:nodeByName("text_normal"):setVisible(true)
		arg_30_0:nodeByName("text_element"):setVisible(false)

		arg_30_0.equipType = var_0_32.Normal
	end

	if arg_30_0.detailState == var_0_14 and arg_30_0.hero:isAwaken() then
		arg_30_0:skillListAction(0.01, 15, 0.2)
	end

	audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
end

function var_0_7.nextHero(arg_32_0)
	arg_32_0:unscheduleExpHandle()

	if arg_32_0.sendSkillLevUpRequest then
		arg_32_0:sendSkillLevUpRequest()
	end

	local function var_32_0()
		if arg_32_0.current_ < #arg_32_0.heros_ then
			arg_32_0.current_ = arg_32_0.current_ + 1
		else
			arg_32_0.current_ = 1
		end

		arg_32_0.hero = arg_32_0.heros_[arg_32_0.current_]

		if not arg_32_0.hero:isCollected() then
			var_32_0()
		end
	end

	if arg_32_0.scrolly then
		arg_32_0.scrolly = nil
	end

	if arg_32_0.frontState then
		arg_32_0.frontState = nil
	end

	arg_32_0.isTrySkin = false
	arg_32_0.trySkinModelID = 0

	var_32_0()
	arg_32_0:update()
	arg_32_0:updateBookContainer()
	arg_32_0:updateInscription()
	arg_32_0:updateBreachContainer()
	arg_32_0:updateCourseInfo()
	arg_32_0:resetEffect()
	arg_32_0:updateBtnShow()
	arg_32_0:updateElementEquip()
	arg_32_0:checkRedPointShow()
	arg_32_0:updateCollocationBtnShow()

	if not arg_32_0.elementEquipOpen then
		arg_32_0:nodeByName("normal_equipment"):show()
		arg_32_0:nodeByName("element_equipment"):hide()
		arg_32_0:nodeByName("text_normal"):setVisible(true)
		arg_32_0:nodeByName("text_element"):setVisible(false)

		arg_32_0.equipType = var_0_32.Normal
	end

	if arg_32_0.detailState == var_0_14 and arg_32_0.hero:isAwaken() then
		arg_32_0:skillListAction(0.01, 15, 0.2)
	end

	audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
end

function var_0_7.unscheduleLevUpHandle(arg_34_0)
	if arg_34_0.visibleHandler and next(arg_34_0.visibleHandler) then
		for iter_34_0, iter_34_1 in ipairs(arg_34_0.visibleHandler) do
			var_0_17.unscheduleGlobal(iter_34_1)
		end
	end
end

function var_0_7.unscheduleExpHandle(arg_35_0)
	if arg_35_0.handler[1] ~= nil then
		var_0_17.unscheduleGlobal(arg_35_0.handler[1])
	end

	if arg_35_0.handler[2] ~= nil then
		var_0_17.unscheduleGlobal(arg_35_0.handler[2])
	end

	if arg_35_0.skillTextHandle then
		var_0_17.unscheduleGlobal(arg_35_0.skillTextHandle)
	end

	if arg_35_0.skillClickHandle[1] ~= nil then
		var_0_17.unscheduleGlobal(arg_35_0.skillClickHandle[1])
	end

	if arg_35_0.skillClickHandle[2] ~= nil then
		var_0_17.unscheduleGlobal(arg_35_0.skillClickHandle[2])
	end
end

function var_0_7.scrollListener(arg_36_0, arg_36_1)
	if arg_36_1.name == "began" then
		arg_36_0.scrollViewMoved_ = false
		arg_36_0.prevX_ = arg_36_1.x
		arg_36_0.prevY_ = arg_36_1.y
	elseif arg_36_1.name == "moved" and 5 <= math.abs(arg_36_1.y - arg_36_0.prevY_) then
		arg_36_0.scrollViewMoved_ = true
	end

	local var_36_0 = arg_36_0.scrollBg:getScrollNode()
	local var_36_1 = 0
	local var_36_2 = -(var_36_0:getCascadeBoundingBox().height - var_36_0:getContentSize().height)

	if var_36_1 < var_36_0:getPositionX() then
		arg_36_0.scrollBg:scrollTo(0, var_36_1)
	elseif var_36_2 > var_36_0:getPositionX() then
		arg_36_0.scrollBg:scrollTo(0, var_36_2)
	end
end

function var_0_7.scrollListener2(arg_37_0, arg_37_1)
	if arg_37_1.name == "began" then
		arg_37_0.scroll_is_moving = false

		arg_37_0.scrollBg2:scrollAuto()

		arg_37_0.scrollViewMoved_ = false
		arg_37_0.prevX_ = arg_37_1.x
		arg_37_0.prevY_ = arg_37_1.y

		if arg_37_0.scroll_moving_end == true then
			arg_37_0.scroll_moving_end = false
		end
	elseif arg_37_1.name == "moved" then
		local var_37_0 = arg_37_0.scrollBg2:getScrollNode()
		local var_37_1 = 0
		local var_37_2 = -(var_37_0:getCascadeBoundingBox().height - arg_37_0.scrollBg2:getViewRectInWorldSpace().height)

		if var_37_1 < var_37_0:getPositionY() then
			arg_37_0.scroll_is_moving = true
		elseif var_37_2 > var_37_0:getPositionY() then
			arg_37_0.scroll_is_moving = true
		else
			arg_37_0.scroll_is_moving = false
		end

		arg_37_0.scrolly = var_37_0:getPositionY()

		if 5 <= math.abs(arg_37_1.y - arg_37_0.prevY_) then
			arg_37_0.scrollViewMoved_ = true
		end
	elseif arg_37_1.name == "scrollEnd" then
		arg_37_0.scrolly = arg_37_0.scrollBg2:getScrollNode():getPositionY()

		if arg_37_0.scroll_is_moving == true then
			arg_37_0.scroll_moving_end = true
			arg_37_0.scroll_is_moving = false
		end
	end
end

function var_0_7.scrollListener3(arg_38_0, arg_38_1)
	if arg_38_1.name == "began" then
		arg_38_0.scrollViewMoved_ = false
		arg_38_0.prevX_ = arg_38_1.x
	elseif arg_38_1.name == "moved" and 10 <= math.abs(arg_38_1.x - arg_38_0.prevX_) then
		arg_38_0.scrollViewMoved_ = true
	end
end

function var_0_7.setupButtonClick(arg_39_0)
	local var_39_0 = arg_39_0.mainContainer:getChildByName("button_onekeyequips")

	var_39_0:addTouchEventListener(function(arg_40_0, arg_40_1)
		xyd.buttonScaleAnim(var_39_0, arg_40_1)

		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickOneKeyEquipsButton()
		end
	end)

	local var_39_1 = arg_39_0.mainContainer:getChildByName("button_jinjie")

	var_39_1:addTouchEventListener(function(arg_41_0, arg_41_1)
		xyd.buttonScaleAnim(var_39_1, arg_41_1)

		if arg_41_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickJinjieButton()
		end
	end)

	local var_39_2 = arg_39_0.mainContainer:getChildByName("button_yijian")

	var_39_2:addTouchEventListener(function(arg_42_0, arg_42_1)
		xyd.buttonScaleAnim(var_39_2, arg_42_1)

		if arg_42_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickYijianButton()
		end
	end)

	local var_39_3 = arg_39_0:nodeByName("button_breach")

	var_39_3:addTouchEventListener(function(arg_43_0, arg_43_1)
		if arg_43_1 == ccui.TouchEventType.ended then
			xyd.buttonScaleAnim(var_39_3, arg_43_1)
			xyd.playButtonSound()

			local var_43_0 = var_0_23:level(1)

			if var_43_0 > arg_39_0.selfPlayer.lev then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_21:translation("STONE_EVOLUTION_LEVEL_TIP"), var_43_0)
				})

				return
			end

			arg_39_0:clickBreachButton()
		end
	end)

	local var_39_4 = arg_39_0:nodeByName("button_jinhua")

	var_39_4:addTouchEventListener(function(arg_44_0, arg_44_1)
		xyd.buttonScaleAnim(var_39_4, arg_44_1)

		if arg_44_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.isSuperHero(arg_39_0.hero) then
				arg_39_0:clickUpgradeButton()
			else
				arg_39_0:clickJinhuaButton()
			end
		end
	end)
	arg_39_0:nodeByName("btn_main"):addTouchEventListener(function(arg_45_0, arg_45_1)
		if arg_45_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickMainButton()
		end
	end)
	arg_39_0:nodeByName("button_shuxing"):addTouchEventListener(function(arg_46_0, arg_46_1)
		if arg_46_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickInfoButton()
		end
	end)

	local var_39_5 = arg_39_0:nodeByName("btn_tujian")

	var_39_5:addTouchEventListener(function(arg_47_0, arg_47_1)
		xyd.buttonScaleAnim(var_39_5, arg_47_1)

		if arg_47_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickCardButton()
		end
	end)
	arg_39_0:nodeByName("button_jineng"):addTouchEventListener(function(arg_48_0, arg_48_1)
		if arg_48_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickSkillButton()

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SKILL_TWO then
				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_THREE)
				xyd.StoryData.get():persist()
				arg_39_0:playGuide()
			end
		end
	end)

	local var_39_6 = arg_39_0:nodeByName("button_linghunshi")

	var_39_6:addTouchEventListener(function(arg_49_0, arg_49_1)
		xyd.buttonScaleAnim(var_39_6, arg_49_1)

		if arg_49_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickStoneButton()
		end
	end)

	local var_39_7 = arg_39_0:nodeByName("button_jingyan")

	var_39_7:addTouchEventListener(function(arg_50_0, arg_50_1)
		xyd.buttonScaleAnim(var_39_7, arg_50_1)

		if arg_50_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickAddExpButton()
		end
	end)

	local var_39_8 = arg_39_0:nodeByName("btn_favor")

	var_39_8:addTouchEventListener(function(arg_51_0, arg_51_1)
		xyd.buttonScaleAnim(var_39_8, arg_51_1)

		if arg_51_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_51_0 = {
				heros = arg_39_0.heros_,
				current = arg_39_0.current_
			}

			xyd.WindowManager.get():openWindow("tujian_herodetail", var_51_0)
		end
	end)
	arg_39_0:nodeByName("btn_super"):addTouchEventListener(function(arg_52_0, arg_52_1)
		xyd.buttonScaleAnim(arg_39_0:nodeByName("btn_super"), arg_52_1)

		if arg_52_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if xyd.WindowManager.get():isWindowOpen("super_partner") then
				xyd.WindowManager.get():closeWindow(arg_39_0)
			else
				local var_52_0 = arg_39_0.hero:getTableID()

				xyd.WindowManager.get():openWindow("super_partner", {
					tableID = var_52_0
				})
			end
		end
	end)
	arg_39_0:nodeByName("btn_hunqi"):addTouchEventListener(function(arg_53_0, arg_53_1)
		xyd.buttonScaleAnim(arg_39_0:nodeByName("btn_hunqi"), arg_53_1)

		if arg_53_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("hunqi", {
				heros = arg_39_0.heros_,
				current = arg_39_0.current_
			})
		end
	end)
	arg_39_0:nodeByName("btn_advance_info"):addTouchEventListener(function(arg_54_0, arg_54_1)
		xyd.buttonScaleAnim(arg_39_0:nodeByName("btn_advance_info"), arg_54_1)

		if arg_54_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("advance_info", {
				hero = arg_39_0.hero
			})
		end
	end)
	arg_39_0.state2Btn[var_0_10]:addTouchEventListener(function(arg_55_0, arg_55_1)
		if arg_55_1 == ccui.TouchEventType.ended then
			if arg_39_0.state == var_0_10 then
				return
			end

			xyd.playButtonSound()
			arg_39_0:clickSkinButton()
			xyd.sendGudieBtnClick("btn_skin")
		end
	end)
	arg_39_0.state2Btn[var_0_9]:addTouchEventListener(function(arg_56_0, arg_56_1)
		if arg_56_1 == ccui.TouchEventType.ended then
			if arg_39_0.state == var_0_9 then
				return
			end

			xyd.playButtonSound()
			arg_39_0:clickHeroDetailButton()
		end
	end)
	arg_39_0.state2Btn[var_0_11]:addTouchEventListener(function(arg_57_0, arg_57_1)
		if arg_57_1 == ccui.TouchEventType.ended then
			if arg_39_0.state == var_0_11 then
				return
			end

			xyd.playButtonSound()
			arg_39_0:clickBookButton()
		end
	end)
	arg_39_0:nodeByName("btn_forum"):addTouchEventListener(function(arg_58_0, arg_58_1)
		xyd.buttonScaleAnim(arg_58_0, arg_58_1)

		if arg_58_1 == ccui.TouchEventType.ended then
			local var_58_0 = {}

			var_58_0.start_pos = 1
			var_58_0.end_pos = 50
			var_58_0.table_id = arg_39_0.hero:getTableID()

			arg_39_0.library:queryForumByPage(var_58_0, function(arg_59_0, arg_59_1)
				if arg_59_0 == xyd.error.OK then
					local var_59_0 = {
						hero = arg_39_0.hero,
						forum_list = arg_59_1.comments or {}
					}

					xyd.WindowManager.get():openWindow("senior_forum", var_59_0)
				end
			end)
		end
	end)
	arg_39_0:nodeByName("button_inscription"):addTouchEventListener(function(arg_60_0, arg_60_1)
		if arg_60_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickInscriptionButton()
		end
	end)

	local var_39_9 = arg_39_0:nodeByName("course_modify_btn")

	var_39_9:addTouchEventListener(function(arg_61_0, arg_61_1)
		xyd.buttonScaleAnim(var_39_9, arg_61_1)

		if arg_61_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickCourseModifyButton()
		end
	end)
	arg_39_0:nodeByName("btn_dorm"):addTouchEventListener(function(arg_62_0, arg_62_1)
		if arg_62_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.DORM):toHeroHouse(arg_39_0.hero)
		end
	end)
	arg_39_0:nodeByName("btn_upgrade"):addTouchEventListener(function(arg_63_0, arg_63_1)
		if arg_63_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:clickUpgradeButton()
		end
	end)
	arg_39_0:nodeByName("breach_btn"):addTouchEventListener(function(arg_64_0, arg_64_1)
		xyd.buttonScaleAnim(arg_39_0:nodeByName("breach_btn"), arg_64_1)

		if arg_64_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_64_0 = arg_39_0.hero:getEvoStage()
			local var_64_1 = var_0_23:level(var_64_0 + 1)
			local var_64_2 = var_0_23:star(var_64_0 + 1)

			if var_64_0 < var_0_23:getMaxStage() and (var_64_1 > arg_39_0.hero:getLevel() or var_64_2 > arg_39_0.hero:getStar()) then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_21:translation("STONE_EVOLUTION_STAR_LEVEL_TIP"), var_64_2, var_64_1)
				})

				return
			end

			local var_64_3 = {
				partner_id = arg_39_0.hero:getHeroID()
			}

			arg_39_0.selfPlayer:breachStoneEvolve(var_64_3, function(arg_65_0, arg_65_1, arg_65_2)
				arg_39_0:updateBreachContainer()
			end)
		end
	end)
	arg_39_0:nodeByName("paper_origin"):setTouchEnabled(true)
	arg_39_0:nodeByName("paper_origin"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_66_0)
		if arg_66_0.name == "began" then
			return true
		elseif arg_66_0.name == "ended" then
			xyd.playButtonSound()

			arg_39_0.useStoneType = var_0_31.Origin

			arg_39_0:updateBreachStoneType()
		end
	end)
	arg_39_0:nodeByName("paper_normal"):setTouchEnabled(true)
	arg_39_0:nodeByName("paper_normal"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_67_0)
		if arg_67_0.name == "began" then
			return true
		elseif arg_67_0.name == "ended" then
			xyd.playButtonSound()

			arg_39_0.useStoneType = var_0_31.Normal

			arg_39_0:updateBreachStoneType()
		end
	end)
	arg_39_0:nodeByName("paper_super"):setTouchEnabled(true)
	arg_39_0:nodeByName("paper_super"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_68_0)
		if arg_68_0.name == "began" then
			return true
		elseif arg_68_0.name == "ended" then
			xyd.playButtonSound()

			arg_39_0.useStoneType = var_0_31.Super

			arg_39_0:updateBreachStoneType()
		end
	end)
	arg_39_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_69_0, arg_69_1)
		xyd.buttonScaleAnim(arg_39_0:nodeByName("rule_btn"), arg_69_1)

		if arg_69_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_69_0 = {
				title_name = "STONE_EVOLUTION_RULE_TITLE",
				rule = "STONE_EVOLUTION_RULE",
				style = xyd.RuleStyle.BLUE
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_69_0)
		end
	end)
	arg_39_0:nodeByName("button_element"):addTouchEventListener(function(arg_70_0, arg_70_1)
		xyd.buttonScaleAnim(arg_39_0:nodeByName("button_element"), arg_70_1)

		if arg_70_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_39_0:changeEquipTypeShow()

			if not arg_39_0.elementRedPointNotShow then
				xyd.db.elementEquipRedMark:updateElementEquipRedMark(arg_39_0.selfPlayer.playerID, arg_39_0.hero:getHeroID(), 1)
				arg_39_0:checkRedPointShow()
			end
		end
	end)
	arg_39_0:nodeByName("btn_collocation"):addTouchEventListener(function(arg_71_0, arg_71_1)
		xyd.buttonScaleAnim(arg_71_0, arg_71_1)

		if arg_71_1 == ccui.TouchEventType.ended then
			arg_39_0.hero:setCollocation(nil, function(arg_72_0, arg_72_1)
				if arg_72_0 == xyd.error.OK then
					arg_39_0:updateCollocationBtnShow()
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.HERO_CELL_REFRESH,
						tableID = arg_39_0.hero:getTableID()
					})

					local var_72_0 = xyd.WindowManager.get():getWindow("hero_list")

					if var_72_0 and not tolua.isnull(var_72_0) and var_72_0.collocation then
						var_72_0:updateHeroList()
					end
				end
			end)
		end
	end)
end

function var_0_7.updateBtnState(arg_73_0)
	for iter_73_0 = 1, 3 do
		if iter_73_0 == arg_73_0.state then
			arg_73_0.state2Btn[iter_73_0]:getChildByName("icon_normal"):setVisible(false)
			arg_73_0.state2Btn[iter_73_0]:getChildByName("icon_select"):setVisible(true)
		else
			arg_73_0.state2Btn[iter_73_0]:getChildByName("icon_normal"):setVisible(true)
			arg_73_0.state2Btn[iter_73_0]:getChildByName("icon_select"):setVisible(false)
		end
	end
end

function var_0_7.update(arg_74_0, arg_74_1)
	collectgarbage("collect")

	local var_74_0 = arg_74_0.hero

	arg_74_0:getLastHeroArrow()
	arg_74_0:getNextHeroArrow()
	arg_74_0:playActions()
	arg_74_0:playRepeatingEffect()
	arg_74_0:updateEquip(var_74_0)

	if arg_74_0.heroModel_ then
		arg_74_0.heroModel_:removeSelf()

		arg_74_0.heroModel_ = nil
	end

	local var_74_1 = arg_74_1 or arg_74_0.hero

	arg_74_0:updateHeroHomeCard()
	arg_74_0:updateHeroModel(var_74_1)
	arg_74_0:updateFavorContainer()
	arg_74_0:updateFuncBtn()
	arg_74_0:updateAttrScore()
	arg_74_0:updateExp()
	arg_74_0:updateHeroStar()
	arg_74_0:updateCard()
	arg_74_0:updateAttrLabels()
	arg_74_0:updateInfoChart()
	arg_74_0:updateRecommendInfo()
	arg_74_0:updateIntroduceText()
	arg_74_0:updateScrollBg()
	arg_74_0:setSkillContainer()
	arg_74_0:updateNameLabel()
	arg_74_0:updateEquipInfoContainer()
	arg_74_0:updateSkinModel(var_74_1)
	arg_74_0:CheckOneClick()
	arg_74_0:updateSuperHero()
	arg_74_0.giftPush:cleanSceneCondition(28)
	arg_74_0.giftPush:cleanSceneCondition(36)
end

function var_0_7.updateHeroHomeCard(arg_75_0, arg_75_1)
	if arg_75_0.isTrySkin and not arg_75_1 then
		return
	end

	if arg_75_0.speakCellContent and not tolua.isnull(arg_75_0.speakCellContent) then
		arg_75_0.speakCellContent:removeDelay()
	end

	arg_75_0.homeCardContainer:removeAllChildren()

	local var_75_0 = arg_75_1 or arg_75_0.hero:getModelID()

	arg_75_0:setHeroCardBaseOnCardState(arg_75_0.hero, var_75_0)
	arg_75_0:updateLiveBtnShow(arg_75_1)
end

function var_0_7.updateLiveBtnShow(arg_76_0, arg_76_1)
	local var_76_0 = arg_76_1 or arg_76_0.hero:getModelID()
	local var_76_1 = arg_76_0:nodeByName("btn_live")

	var_76_1:setTouchSwallowEnabled(true)

	local var_76_2 = xyd.tables.model:dynamicType(arg_76_0.hero:getModelID()) == 2

	var_76_1:setVisible(var_76_2)

	if xyd.isShowDynamicCard(arg_76_0.hero, var_76_0) and arg_76_0.hero:getDynamicCardState(var_76_0) == 1 then
		var_76_1:setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_76_1:setBrightStyle(ccui.BrightStyle.normal)
	end

	var_76_1:addTouchEventListener(function(arg_77_0, arg_77_1)
		xyd.buttonScaleAnim(var_76_1, arg_77_1)

		if arg_77_1 == ccui.TouchEventType.ended then
			local var_77_0 = arg_76_0.hero:getModelID()

			if arg_76_0.hero:isUnlockDynamicCard(var_77_0) then
				arg_76_0.hero:changeDynamicCardState(var_77_0, function()
					arg_76_0:updateEquipInfoContainer()
					arg_76_0:updateHeroHomeCard()
				end)
			else
				local var_77_1 = xyd.tables.skinDynamic:cost(var_77_0)
				local var_77_2 = xyd.tables.skinDynamic:num(var_77_0)

				if not var_77_1 or not var_77_2 then
					return
				end

				local var_77_3 = string.format(var_0_21:translation("DYNAMIC_SENTENCE"), var_77_1, var_77_2)

				if var_77_1 == 0 then
					var_77_3 = string.format(var_0_21:translation("DYNAMIC_SENTENCE1"), var_77_2)
				elseif var_77_2 == 0 then
					var_77_3 = string.format(var_0_21:translation("DYNAMIC_SENTENCE2"), var_77_1)
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_77_3
				}, function()
					local var_79_0 = xyd.tables.misc:getValue("dymisic_item")

					if arg_76_0.backpack:getItemNumByID(var_79_0) < var_77_2 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_21:translation("DYNAMIC_ITEM_TIP")
						})

						return
					end

					if arg_76_0.selfPlayer.crystal < var_77_1 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_21:translation("STICK_BLESS_NO_CRYSTAL")
						})

						return
					end

					arg_76_0.hero:unlockDynamicCard(var_77_0, function()
						arg_76_0:updateHeroHomeCard()
						arg_76_0.backpack:removeItem({
							itemID = var_79_0,
							itemNum = var_77_2
						})
					end)
				end)
			end
		end
	end)

	if arg_76_0.state == var_0_10 then
		arg_76_0:nodeByName("btn_live"):setVisible(false)
		arg_76_0:nodeByName("btn_collocation"):setVisible(false)
	else
		arg_76_0:nodeByName("btn_collocation"):setVisible(true)
	end
end

function var_0_7.setHeroCardBaseOnCardState(arg_81_0, arg_81_1, arg_81_2)
	local var_81_0 = xyd.tables.libraryHomeCard:x(arg_81_2)
	local var_81_1 = xyd.tables.libraryHomeCard:y(arg_81_2)

	if not arg_81_0 or tolua.isnull(arg_81_0) or not arg_81_0.homeCardContainer or tolua.isnull(arg_81_0.homeCardContainer) then
		return
	end

	arg_81_0.homeCardContainer:removeAllChildren()

	arg_81_0.live2d = nil

	local var_81_2

	if arg_81_1:isAwaken() then
		var_81_2 = arg_81_1:getFirstTableID()
	else
		var_81_2 = arg_81_1:getTableID()
	end

	local var_81_3 = xyd.tables.hero:isSX(var_81_2)
	local var_81_4 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_sx.png")

	var_81_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_81_4:setPosition(cc.p(140, 600))
	arg_81_0.homeCardContainer:addChild(var_81_4)

	if var_81_3 then
		var_81_4:setVisible(true)
	else
		var_81_4:setVisible(false)
	end

	local var_81_5 = xyd.getTransparentCard(arg_81_1, xyd.SkinDynamicPosType.LIBRARY, arg_81_2)

	if not var_81_5 then
		return
	end

	arg_81_0.homeCardContainer:addChild(var_81_5)
	var_81_5:setPosition(arg_81_0.homeCardContainer:getWidth() / 2 + var_81_0, var_81_1)
	var_81_5:setAnchorPoint(cc.p(0.5, 0))
	var_81_5:setTouchEnabled(false)
	arg_81_0:addDialog(touchAreaSize)
end

function var_0_7.addDialog(arg_82_0, arg_82_1)
	local var_82_0 = {
		touchPosition = cc.p(0, -175),
		touchAreaSize = touchAreaSize or {
			width = 400,
			height = 500
		},
		msgs = clone(xyd.tables.hero:clickDialog(arg_82_0.hero:getTableID())),
		sounds = clone(xyd.tables.hero:dialogSounds(arg_82_0.hero:getTableID())),
		times = clone(xyd.tables.hero:soundTimes(arg_82_0.hero:getTableID())),
		heroTableID = arg_82_0.hero:getTableID(),
		noTouch = arg_82_1,
		lastFunc = handler(arg_82_0, arg_82_0.lastHero),
		nextFunc = handler(arg_82_0, arg_82_0.nextHero)
	}

	if arg_82_0.hero.isCollected_ then
		local var_82_1, var_82_2 = arg_82_0.hero:getHeroVoiceState()

		for iter_82_0 = 5, 1, -1 do
			if not var_82_2[iter_82_0 + 4] then
				table.remove(var_82_0.msgs, iter_82_0)
				table.remove(var_82_0.sounds, iter_82_0)
				table.remove(var_82_0.times, iter_82_0)
			end
		end
	else
		var_82_0.msgs = {
			var_82_0.msgs[1]
		}
		var_82_0.sounds = {
			var_82_0.sounds[1]
		}
		var_82_0.times = {
			var_82_0.times[1]
		}
	end

	arg_82_0.speakCellContent = import("app.windows.SpeakCell").new(var_82_0)

	arg_82_0.speakCellContent:addTo(arg_82_0:nodeByName("talks_pos"))
	arg_82_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_82_0.speakCellContent:setPositionX(100)
end

function var_0_7.checkBookShow(arg_83_0)
	local var_83_0 = true

	if arg_83_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ACT_CENTRE) == nil or arg_83_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ACT_CENTRE) == false then
		var_83_0 = false
	end

	local var_83_1 = arg_83_0.hero:getTableID()

	if arg_83_0.hero:isAwaken() then
		var_83_1 = xyd.tables.hero:beforeAwaken(arg_83_0.hero:getTableID())
	end

	xyd.tables.cabinetSkillTable:partnerSkills(var_83_1)

	if #xyd.tables.cabinetSkillTable:partnerSkills(var_83_1) == 0 then
		var_83_0 = false
	end

	return var_83_0
end

function var_0_7.updateFuncBtn(arg_84_0)
	arg_84_0.btnList = {}

	if arg_84_0:checkBookShow() then
		arg_84_0:nodeByName("btn_book"):setVisible(true)
	else
		arg_84_0:nodeByName("btn_book"):setVisible(false)
	end

	local var_84_0 = arg_84_0.hero:getHouseInfo()

	if var_84_0 and var_84_0.house_id > 0 then
		arg_84_0:nodeByName("btn_dorm"):setVisible(true)
		table.insert(arg_84_0.btnList, arg_84_0:nodeByName("btn_dorm"))
	else
		arg_84_0:nodeByName("btn_dorm"):setVisible(false)
	end

	arg_84_0:nodeByName("btn_favor"):setVisible(true)
	table.insert(arg_84_0.btnList, arg_84_0:nodeByName("btn_favor"))

	if arg_84_0:isMaterialorSuper(arg_84_0.hero) and xyd.isFunctionOpen(xyd.FunctionID.ID_SUPER_PARTNER) then
		arg_84_0:nodeByName("btn_super"):setVisible(true)
		table.insert(arg_84_0.btnList, arg_84_0:nodeByName("btn_super"))
	else
		arg_84_0:nodeByName("btn_super"):setVisible(false)
	end

	if xyd.isFunctionOpen(xyd.FunctionID.ID_HUNQI) then
		arg_84_0:nodeByName("btn_hunqi"):setVisible(true)
		table.insert(arg_84_0.btnList, arg_84_0:nodeByName("btn_hunqi"))
	else
		arg_84_0:nodeByName("btn_hunqi"):setVisible(false)
	end

	if arg_84_0.hero:getColor() >= xyd.selfPlayer.maxHeroColor or xyd.isSuperHero(arg_84_0.hero) then
		arg_84_0:nodeByName("btn_advance_info"):setVisible(false)
	else
		arg_84_0:nodeByName("btn_advance_info"):setVisible(true)
	end

	local var_84_1 = 200

	for iter_84_0 = #arg_84_0.btnList, 1, -1 do
		arg_84_0.btnList[iter_84_0]:setPositionY(var_84_1)

		var_84_1 = var_84_1 + 80
	end
end

function var_0_7.updateSuperHero(arg_85_0)
	arg_85_0:nodeByName("super_hero_container"):removeAllChildren()

	if xyd.isSuperHero(arg_85_0.hero) then
		if arg_85_0.hero:getStar() <= xyd.MAX_STAR_LEVEL then
			arg_85_0:nodeByName("super_container"):setVisible(true)
			arg_85_0:nodeByName("normal_container"):setVisible(false)
		else
			arg_85_0:nodeByName("super_container"):setVisible(false)
			arg_85_0:nodeByName("normal_container"):setVisible(true)
		end

		if arg_85_0.detailState == var_0_15 or arg_85_0.detailState == var_0_16 then
			arg_85_0:clickMainButton()
		end

		arg_85_0:nodeByName("button_jinjie"):setVisible(false)
		arg_85_0:nodeByName("button_onekeyequips"):setVisible(false)
		arg_85_0:nodeByName("button_yijian"):setVisible(false)
	else
		arg_85_0:nodeByName("super_container"):setVisible(false)
		arg_85_0:nodeByName("normal_container"):setVisible(true)
	end

	if arg_85_0:nodeByName("super_container"):isVisible() then
		local var_85_0 = 0

		for iter_85_0 = 1, 5 do
			local var_85_1 = display.newNode()
			local var_85_2 = arg_85_0:nodeByName("super_container"):getContentSize().height

			var_85_1:setContentSize(var_85_2, var_85_2)
			var_85_1:addTo(arg_85_0:nodeByName("super_hero_container"))
			var_85_1:setPosition((var_85_2 + 5) * (iter_85_0 - 1), 0)

			local var_85_3 = var_0_19:materialHero(arg_85_0.hero:getTableID())
			local var_85_4 = arg_85_0.selfPlayer:getHeroByTableID(var_85_3[iter_85_0]) or arg_85_0.selfPlayer:getHeroByTableID(var_0_19:afterAwaken(var_85_3[iter_85_0]))

			if var_85_4 then
				xyd.setAvatarBorder(var_85_4, var_85_1, nil, nil, nil, nil, nil, nil, nil, true)

				if var_85_4:getStar() == xyd.MAX_STAR_LEVEL then
					var_85_0 = var_85_0 + 1

					local var_85_5 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

					var_85_5:addTo(var_85_1)
					var_85_5:setPosition(var_85_2 - 8, var_85_2 - 8)
				end

				local var_85_6 = display.newNode()
				local var_85_7
				local var_85_8

				var_85_6:setContentSize(var_85_1:getContentSize())
				var_85_6:addTo(var_85_1)
				var_85_6:setTouchEnabled(true)
				var_85_6:setTouchSwallowEnabled(false)
				var_85_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_86_0)
					if arg_86_0.name == "began" then
						var_85_7 = arg_86_0.y
						var_85_8 = false

						return true
					elseif arg_86_0.name == "moved" then
						local var_86_0 = arg_86_0.y

						if math.abs(var_86_0 - var_85_7) > 30 then
							var_85_8 = true
						end
					elseif arg_86_0.name == "ended" and not var_85_8 then
						local var_86_1 = {
							heros = {
								var_85_4
							}
						}

						var_86_1.current = 1

						xyd.WindowManager.get():closeWindow("hero_main")
						xyd.WindowManager.get():openWindow("hero_main", var_86_1)
					end
				end)
			end

			if var_85_0 > arg_85_0.hero:getStar() or arg_85_0.hero:getStar() == xyd.MAX_STAR_LEVEL then
				local var_85_9 = cc.p(arg_85_0:nodeByName("super_container"):getChildByName("btn_upgrade"):getPosition())

				arg_85_0:nodeByName("upgrade_effect"):removeAllChildren()

				local var_85_10 = var_0_30.Starup .. ".json"
				local var_85_11 = var_0_30.Starup .. ".atlas"
				local var_85_12 = var_0_29.new(var_85_10, var_85_11, 1)

				var_85_12:setAnchorPoint(cc.p(0.5, 0.5))
				var_85_12:addTo(arg_85_0:nodeByName("upgrade_effect"))
				var_85_12:play(nil, true)
				arg_85_0:nodeByName("super_container"):getChildByName("btn_upgrade"):setVisible(true)
			else
				arg_85_0:nodeByName("upgrade_effect"):removeAllChildren()
				arg_85_0:nodeByName("super_container"):getChildByName("btn_upgrade"):setVisible(false)
			end
		end
	end
end

function var_0_7.isMaterialorSuper(arg_87_0, arg_87_1)
	local var_87_0 = arg_87_1:getTableID()

	if xyd.isSuperHero(arg_87_1) then
		return true
	end

	local var_87_1 = var_0_19:getSuperHeros()

	for iter_87_0, iter_87_1 in ipairs(var_87_1) do
		for iter_87_2, iter_87_3 in ipairs(var_0_19:materialHero(var_87_1[iter_87_0])) do
			if iter_87_3 == var_87_0 or var_0_19:afterAwaken(iter_87_3) == var_87_0 then
				return true
			end
		end
	end

	return false
end

function var_0_7.updateFavorContainer(arg_88_0)
	local var_88_0 = arg_88_0.hero:getFavorState()

	arg_88_0:nodeByName("heart_gray"):setVisible(false)
	arg_88_0:nodeByName("heart_read"):setVisible(false)
	arg_88_0:nodeByName("heart_married"):setVisible(false)

	if var_88_0 == xyd.FavorState.NOT_OPEN then
		arg_88_0:nodeByName("heart_gray"):setVisible(true)
	elseif var_88_0 == xyd.FavorState.MARRIED then
		arg_88_0:nodeByName("heart_married"):setVisible(true)
	else
		arg_88_0:nodeByName("heart_married"):setVisible(false)
		arg_88_0:nodeByName("heart_gray"):setVisible(true)
		arg_88_0:nodeByName("heart_read"):setVisible(true)
		arg_88_0:updateFavor()
	end
end

function var_0_7.updateFavor(arg_89_0)
	if arg_89_0 and arg_89_0:nodeByName("heart_read") and not tolua.isnull(arg_89_0:nodeByName("heart_read")) then
		local var_89_0 = arg_89_0.selfPlayer:getHero(arg_89_0.hero:getHeroID()):getFavorDegree()

		arg_89_0:nodeByName("heart_read"):setPercent(var_89_0 * 100 / xyd.tables.misc.libraryFavorLimit)
	end
end

function var_0_7.updateNameLabel(arg_90_0)
	arg_90_0.nameLabelContainer:removeAllChildren()
	arg_90_0:nodeByName("from"):removeAllChildren()

	local var_90_0 = arg_90_0.hero
	local var_90_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/hero_label.csb")

	var_90_1:addTo(arg_90_0.nameLabelContainer)

	local var_90_2 = var_90_1:getChildByName("bg")
	local var_90_3 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_" .. xyd.Color2Quality[var_90_0:getColor()] .. ".png")

	var_90_3:addTo(var_90_2:getChildByName("bg_name"))
	var_90_3:setAnchorPoint(0, 0)

	local var_90_4

	if arg_90_0.hero:isAwaken() then
		if arg_90_0.hero:isAwakeTwice() then
			var_90_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake_twice.png")
		else
			var_90_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake.png")
		end

		var_90_4:addTo(var_90_2:getChildByName("bg_awake"))
		var_90_4:setAnchorPoint(0, 0)
	end

	local var_90_5

	if xyd.Color2Level[var_90_0:getColor()] ~= "" then
		var_90_5 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/hero_quality_" .. var_90_0:getColor() .. ".png")
	end

	local var_90_6 = arg_90_0.hero:getInscriptionKuangLevel()

	if var_90_6 then
		if var_90_6 ~= 1 then
			var_90_5 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/hero_quality_suit_" .. var_90_6 .. ".png")
		else
			var_90_5 = nil
		end

		var_90_2:getChildByName("bg_name"):removeAllChildren()

		local var_90_7 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_suit.png")

		var_90_7:addTo(var_90_2:getChildByName("bg_name"))
		var_90_7:setAnchorPoint(0, 0)
	end

	local var_90_8 = var_90_0:getElementType()

	if var_90_8 ~= 0 then
		local var_90_9

		if var_90_6 then
			var_90_9 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_gold_bg.png")
		else
			var_90_9 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_red_bg.png")
		end

		local var_90_10 = "windows/common/hero_common/big_element_" .. var_90_8

		if var_90_0:isActiveSP() then
			var_90_10 = var_90_10 .. "sp"
		end

		var_90_5 = xyd.AssetLoader.get():loadSprite(var_90_10 .. ".png")

		var_90_9:setAnchorPoint(0.5, 0.5)
		var_90_9:addTo(var_90_2:getChildByName("quality"))
		var_90_5:setAnchorPoint(0.5, 0.5)
		var_90_5:addTo(var_90_2:getChildByName("quality"))

		if arg_90_0.hero:isActiveSP() then
			arg_90_0:addActiveEffeft(var_90_5, var_90_8)
		end
	elseif var_90_5 then
		var_90_5:setAnchorPoint(0.5, 0.5)
		var_90_5:addTo(var_90_2:getChildByName("quality"))
	end

	var_90_2:getChildByName("name"):setString(var_90_0:getName())

	local var_90_11 = var_90_0:getHeroType()
	local var_90_12

	if var_90_11 == xyd.HeroType.WISE then
		var_90_12 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_wise.png")
	elseif var_90_11 == xyd.HeroType.STRENGTH then
		var_90_12 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_strength.png")
	else
		var_90_12 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_agile.png")
	end

	var_90_12:addTo(var_90_2:getChildByName("icon_info"))

	local var_90_13
	local var_90_14 = var_90_0:getFromType() == xyd.HeroFromType.WEI and "windows/hero/icon_wei.png" or var_90_0:getFromType() == xyd.HeroFromType.SHU and "windows/hero/icon_shu.png" or var_90_0:getFromType() == xyd.HeroFromType.WU and "windows/hero/icon_wu.png" or "windows/hero/icon_qun.png"

	xyd.AssetLoader.get():loadSprite(var_90_14):addTo(arg_90_0:nodeByName("from"))

	if var_90_0:isSuper() then
		local var_90_15

		if var_90_0:getStar() > xyd.MAX_STAR_LEVEL then
			local var_90_16 = var_90_0:getStar() - xyd.MAX_STAR_LEVEL

			for iter_90_0 = 1, xyd.HERO_TOTAL_STARS do
				local var_90_17 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star_pink.png")

				var_90_2:getChildByName("star_" .. iter_90_0):setSpriteFrame(var_90_17:getSpriteFrame())
				var_90_2:getChildByName("star_" .. iter_90_0):setVisible(iter_90_0 <= var_90_16)
			end
		else
			local var_90_18 = var_90_0:getStar()

			for iter_90_1 = 1, xyd.HERO_TOTAL_STARS do
				local var_90_19 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

				var_90_2:getChildByName("star_" .. iter_90_1):setSpriteFrame(var_90_19:getSpriteFrame())
				var_90_2:getChildByName("star_" .. iter_90_1):setVisible(iter_90_1 <= var_90_18)
			end
		end

		local var_90_20 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_super.png")

		var_90_2:getChildByName("quality"):removeAllChildren()
		var_90_2:getChildByName("bg_name"):removeAllChildren()

		if var_90_8 ~= 0 then
			local var_90_21 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_ur_bg.png")
			local var_90_22 = "windows/common/hero_common/big_element_" .. var_90_8

			if var_90_0:isActiveSP() then
				var_90_22 = var_90_22 .. "sp"
			end

			local var_90_23 = xyd.AssetLoader.get():loadSprite(var_90_22 .. ".png")

			var_90_21:setAnchorPoint(0.5, 0.5)
			var_90_21:addTo(var_90_2:getChildByName("quality"))
			var_90_23:addTo(var_90_2:getChildByName("quality"))
			var_90_23:setAnchorPoint(0.5, 0.5)

			if arg_90_0.hero:isActiveSP() then
				arg_90_0:addActiveEffeft(var_90_23, var_90_8)
			end
		end

		var_90_20:addTo(var_90_2:getChildByName("bg_name"))
		var_90_20:setAnchorPoint(0, 0)
	else
		for iter_90_2 = 1, xyd.HERO_TOTAL_STARS do
			local var_90_24 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

			var_90_2:getChildByName("star_" .. iter_90_2):setSpriteFrame(var_90_24:getSpriteFrame())
			var_90_2:getChildByName("star_" .. iter_90_2):setVisible(iter_90_2 <= var_90_0:getStar())
		end
	end
end

function var_0_7.updateCard(arg_91_0)
	if not arg_91_0.cache[var_0_33.Card] then
		return
	end

	arg_91_0.cardContainer:removeAllChildren()
	arg_91_0.cardBlock:removeAllChildren()

	local var_91_0 = display.newNode()

	var_91_0:setContentSize(arg_91_0.cardBlock:getContentSize())
	var_91_0:addTo(arg_91_0.cardBlock)
	var_91_0:setTouchEnabled(true)
	var_91_0:setTouchSwallowEnabled(false)
	var_91_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_92_0)
		if arg_92_0.name == "ended" then
			if not arg_91_0.card or not arg_91_0.isCardShow then
				return
			end

			arg_91_0:clickCardButton()
		end

		return true
	end)

	local function var_91_1(arg_93_0)
		if arg_93_0 == xyd.CardStatus.SKIN_CARD then
			if arg_91_0.hero.illusionSkinId_ > 1 then
				return true
			else
				return false
			end
		elseif arg_93_0 == xyd.CardStatus.AWAKE_CARD then
			if arg_91_0.hero:isAwaken() then
				return true
			else
				return false
			end
		elseif arg_93_0 == xyd.CardStatus.NORMAL_CARD then
			return true
		end
	end

	if not arg_91_0.frontState then
		if arg_91_0.hero.illusionSkinId_ > 1 then
			arg_91_0.frontState = xyd.CardStatus.SKIN_CARD
		elseif arg_91_0.hero.illusionSkinId_ == 1 then
			arg_91_0.frontState = xyd.CardStatus.AWAKE_CARD
		else
			arg_91_0.frontState = xyd.CardStatus.NORMAL_CARD
		end

		arg_91_0.backState = arg_91_0.frontState + 1
	else
		arg_91_0.frontState = arg_91_0.backState
		arg_91_0.backState = arg_91_0.backState + 1
	end

	while not var_91_1(arg_91_0.backState) do
		if arg_91_0.backState > 3 then
			arg_91_0.backState = 1
		else
			arg_91_0.backState = arg_91_0.backState + 1
		end
	end

	local var_91_2 = xyd.getNewHeroCard(arg_91_0.hero, arg_91_0.frontState, arg_91_0.backState, true)
	local var_91_3 = var_91_2:getChildByName("live")

	var_91_3:setTouchSwallowEnabled(true)

	local var_91_4 = display.newNode()
	local var_91_5, var_91_6 = var_91_3:getPosition()
	local var_91_7 = var_91_3:getContentSize()

	var_91_4:addTo(var_91_2)
	var_91_4:setAnchorPoint(0.5, 0.5)
	var_91_4:setTouchSwallowEnabled(true)
	var_91_4:setContentSize(var_91_7.width, var_91_7.height)
	var_91_4:setPosition(var_91_5, var_91_6)
	var_91_4:setName("node")
	var_91_4:setTouchEnabled(var_91_3:isVisible())

	local var_91_8 = xyd.tables.model:dynamicType(arg_91_0:getCardFrontModelID()) == 2

	var_91_3:setVisible(var_91_8)
	var_91_4:setTouchEnabled(var_91_8)
	var_91_3:addTouchEventListener(function(arg_94_0, arg_94_1)
		if arg_94_1 == ccui.TouchEventType.ended then
			local var_94_0 = arg_91_0:getCardFrontModelID()

			if arg_91_0.hero:isUnlockDynamicCard(var_94_0) then
				arg_91_0.hero:changeDynamicCardState(var_94_0, function()
					arg_91_0.backState = arg_91_0.frontState

					arg_91_0:updateCard()
				end)
			else
				local var_94_1 = xyd.tables.skinDynamic:cost(var_94_0)
				local var_94_2 = xyd.tables.skinDynamic:num(var_94_0)

				if not var_94_1 or not var_94_2 then
					return
				end

				local var_94_3 = string.format(var_0_21:translation("DYNAMIC_SENTENCE"), var_94_1, var_94_2)

				if var_94_1 == 0 then
					var_94_3 = string.format(var_0_21:translation("DYNAMIC_SENTENCE1"), var_94_2)
				elseif var_94_2 == 0 then
					var_94_3 = string.format(var_0_21:translation("DYNAMIC_SENTENCE2"), var_94_1)
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_94_3
				}, function()
					local var_96_0 = xyd.tables.misc:getValue("dymisic_item")

					if arg_91_0.backpack:getItemNumByID(var_96_0) < var_94_2 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_21:translation("DYNAMIC_ITEM_TIP")
						})

						return
					end

					if arg_91_0.selfPlayer.crystal < var_94_1 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_21:translation("STICK_BLESS_NO_CRYSTAL")
						})

						return
					end

					arg_91_0.hero:unlockDynamicCard(var_94_0, function()
						arg_91_0.backState = arg_91_0.frontState

						arg_91_0:updateCard()
						arg_91_0.backpack:removeItem({
							itemID = var_96_0,
							itemNum = var_94_2
						})
					end)
				end)
			end
		end

		if xyd.isShowDynamicCard(arg_91_0.hero, curModelID) and arg_91_0.hero:getDynamicCardState(curModelID) == 1 then
			var_91_3:setBrightStyle(ccui.BrightStyle.highlight)
		else
			var_91_3:setBrightStyle(ccui.BrightStyle.normal)
		end
	end)
	var_91_2:addTo(arg_91_0.cardContainer)

	arg_91_0.card = var_91_2

	var_91_2:align(display.CENTER, var_91_2:getWidth() / 2, var_91_2:getHeight() / 2)
	var_91_2:setTouchEnabled(true)
	var_91_2:setTouchSwallowEnabled(true)
	var_91_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_98_0)
		if arg_98_0.name == "ended" then
			if not arg_91_0.card or not arg_91_0.isCardShow then
				return
			end

			arg_91_0:clickCardButton()
		end

		return true
	end)
	arg_91_0.card:scale(xyd.STAGE_HEIGHT / arg_91_0.card:getWidth())
	arg_91_0.card:setRotation(-90)
	arg_91_0.card:setPosition(xyd.STAGE_WIDTH / 2 - 128.31, xyd.STAGE_HEIGHT / 2)

	if arg_91_0.hero:isAwaken() or arg_91_0.hero.isSkinOn_ == 1 then
		local var_91_9 = cc.ui.UIPushButton.new({
			pressed = "windows/button/switch_button2.png",
			disabled = "windows/button/switch_button1.png",
			normal = "windows/button/switch_button1.png"
		})

		var_91_9:addTo(arg_91_0.card)
		var_91_9:setName("switchBtn")
		var_91_9:setPosition(arg_91_0.card:getChildByName("switch_pos"):getPosition())
		var_91_9:setTouchSwallowEnabled(true)

		arg_91_0.isFrontOut = true
		arg_91_0.canSwitchCard = true

		var_91_9:onButtonClicked(function(arg_99_0)
			if arg_91_0.canSwitchCard then
				arg_91_0.canSwitchCard = false

				arg_91_0:cardRolling(0.15, frontState, backState)
			end
		end)
	end
end

function var_0_7.cardRolling(arg_100_0, arg_100_1, arg_100_2, arg_100_3)
	local function var_100_0()
		arg_100_0.isFrontOut = not arg_100_0.isFrontOut
		arg_100_0.canSwitchCard = true
	end

	local function var_100_1()
		local var_102_0 = arg_100_0.card:getChildByName("container"):getChildByName("cardFront")
		local var_102_1 = arg_100_0.card:getChildByName("container"):getChildByName("cardBack")

		if arg_100_0.isFrontOut then
			var_102_0:setVisible(true)
			var_102_1:setVisible(false)
		else
			var_102_0:setVisible(false)
			var_102_1:setVisible(true)
		end

		arg_100_0:updateCard()
	end

	local var_100_2 = cc.OrbitCamera:create(arg_100_1, 1, 0, 0, 90, 0, 0)
	local var_100_3 = cc.OrbitCamera:create(arg_100_1, 1, 0, 270, 90, 0, 0)
	local var_100_4 = cc.CallFunc:create(var_100_1)
	local var_100_5 = cc.CallFunc:create(var_100_0)
	local var_100_6 = cc.Sequence:create(var_100_2, var_100_4, var_100_3, var_100_5)

	arg_100_0.card:runAction(var_100_6)
end

function var_0_7.updateHeroStar(arg_103_0)
	local var_103_0 = arg_103_0.hero
	local var_103_1 = arg_103_0.mainContainer:getChildByName("normal_container"):getChildByName("bar")
	local var_103_2
	local var_103_3

	for iter_103_0 = 1, 3 do
		arg_103_0:nodeByName("star_gray" .. iter_103_0):setPositionX(237.58 + (iter_103_0 - 1) * 20)
		arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_0):setPositionX(237.58 + (iter_103_0 - 1) * 20)
	end

	if not xyd.isSuperHero(arg_103_0.hero) or arg_103_0.hero:getStar() > xyd.MAX_STAR_LEVEL then
		for iter_103_1 = 1, 5 do
			arg_103_0:nodeByName("hero_star" .. iter_103_1):setPositionY(188.63)
			arg_103_0:nodeByName("star_gray" .. iter_103_1):setPositionY(188.63)
		end
	else
		for iter_103_2 = 1, 5 do
			arg_103_0:nodeByName("hero_star" .. iter_103_2):setPositionY(246.63)
			arg_103_0:nodeByName("star_gray" .. iter_103_2):setPositionY(246.63)
		end
	end

	if var_103_0:isSuper() then
		if var_103_0:getStar() >= xyd.SUPER_HERO_TOTAL_STARS then
			var_103_2 = 100
			var_103_3 = var_0_21:translation("HERO_MAIN_MAX_STAR")

			var_103_1:setPercent(var_103_2)
			arg_103_0.mainContainer:getChildByName("normal_container"):getChildByName("bar_text"):setString(var_103_3)
		elseif var_103_0:getStar() > xyd.MAX_STAR_LEVEL then
			var_103_2 = math.min(var_103_0:getSuiPian() / xyd.StarLevelSuipian[var_103_0:getStar() + 1] * 100, 100)
			var_103_3 = var_103_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_103_0:getStar() + 1]

			var_103_1:setPercent(var_103_2)
			arg_103_0.mainContainer:getChildByName("normal_container"):getChildByName("bar_text"):setString(var_103_3)
		else
			arg_103_0.mainContainer:getChildByName("normal_container"):setVisible(false)
		end

		local var_103_4

		if var_103_0:getStar() > xyd.MAX_STAR_LEVEL then
			arg_103_0:nodeByName("star_gray4"):setVisible(false)
			arg_103_0:nodeByName("star_gray5"):setVisible(false)

			for iter_103_3 = 1, 3 do
				arg_103_0:nodeByName("star_gray" .. iter_103_3):setPositionX(237.58 + iter_103_3 * 20)
				arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_3):setPositionX(237.58 + iter_103_3 * 20)
			end

			local var_103_5 = var_103_0:getStar() - xyd.MAX_STAR_LEVEL

			for iter_103_4 = 1, xyd.HERO_TOTAL_STARS do
				local var_103_6 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star_pink.png")

				arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_4):setSpriteFrame(var_103_6:getSpriteFrame())
				arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_4):setVisible(iter_103_4 <= var_103_5)
			end
		else
			arg_103_0:nodeByName("star_gray4"):setVisible(true)
			arg_103_0:nodeByName("star_gray5"):setVisible(true)

			local var_103_7 = var_103_0:getStar()

			for iter_103_5 = 1, xyd.HERO_TOTAL_STARS do
				local var_103_8 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

				arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_5):setSpriteFrame(var_103_8:getSpriteFrame())
				arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_5):setVisible(iter_103_5 <= var_103_7)
			end
		end
	else
		arg_103_0:nodeByName("star_gray4"):setVisible(true)
		arg_103_0:nodeByName("star_gray5"):setVisible(true)

		if var_103_0:getStar() >= xyd.MAX_STAR_LEVEL then
			var_103_2 = 100
			var_103_3 = var_0_21:translation("HERO_MAIN_MAX_STAR")
		else
			var_103_2 = math.min(var_103_0:getSuiPian() / xyd.StarLevelSuipian[var_103_0:getStar() + 1] * 100, 100)
			var_103_3 = var_103_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_103_0:getStar() + 1]
		end

		var_103_1:setPercent(var_103_2)
		arg_103_0.mainContainer:getChildByName("normal_container"):getChildByName("bar_text"):setString(var_103_3)

		for iter_103_6 = 1, xyd.HERO_TOTAL_STARS do
			local var_103_9 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

			arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_6):setSpriteFrame(var_103_9:getSpriteFrame())
			arg_103_0.mainContainer:getChildByName("hero_star" .. iter_103_6):setVisible(iter_103_6 <= var_103_0:getStar())
		end
	end
end

function var_0_7.updateExp(arg_104_0, arg_104_1)
	arg_104_1 = arg_104_1 or arg_104_0.hero

	arg_104_0:nodeByName("lev_txt"):setString(arg_104_1:getLevel())

	local var_104_0 = arg_104_1:getExp() - xyd.tables.partnerExp:totalExp(arg_104_1:getLevel() - 1)

	arg_104_0:nodeByName("exp_txt"):setString(var_104_0 .. " / " .. arg_104_1:getAddExp())
end

function var_0_7.playEatExpEffect(arg_105_0, arg_105_1)
	if tolua.isnull(arg_105_1) then
		return
	end

	local var_105_0 = arg_105_0:getHeroContainer():getContentSize().width
	local var_105_1 = arg_105_0:getHeroContainer():getContentSize().height
	local var_105_2 = xyd.tables.sound:getSound("train_exp_up")

	audio.playSound(var_105_2, false)

	if not arg_105_0.eatExpEffect then
		local var_105_3 = var_0_30.LevelUp .. ".json"
		local var_105_4 = var_0_30.LevelUp .. ".atlas"

		arg_105_0.eatExpEffect = var_0_29.new(var_105_3, var_105_4, 1)

		arg_105_0.eatExpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_105_0.eatExpEffect:setPosition(var_105_0 / 2, var_105_1 / 2)
		arg_105_0.eatExpEffect:addTo(arg_105_0:getHeroContainer())
	end

	arg_105_0.eatExpEffect:play(nil, false)
end

function var_0_7.playLevelUpEffect(arg_106_0)
	local var_106_0 = arg_106_0:getHeroContainer():getContentSize().width
	local var_106_1 = arg_106_0:getHeroContainer():getContentSize().height
	local var_106_2 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_106_2, false)

	local var_106_3 = arg_106_0:getHeroContainer():getContentSize().width
	local var_106_4 = arg_106_0:getHeroContainer():getContentSize().height

	if arg_106_0.levelUpEffect == nil then
		local var_106_5 = var_0_30.Evolve .. ".json"
		local var_106_6 = var_0_30.Evolve .. ".atlas"

		arg_106_0.levelUpEffect = var_0_29.new(var_106_5, var_106_6, 1)

		arg_106_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_106_0.levelUpEffect:setPosition(var_106_3 / 2, var_106_4 / 2)
		arg_106_0.levelUpEffect:addTo(arg_106_0:getHeroContainer())
	end

	arg_106_0.levelUpEffect:play(nil, false)

	if arg_106_0.levelUpSprite == nil then
		arg_106_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

		arg_106_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
		arg_106_0.levelUpSprite:setPosition(var_106_3 / 2, var_106_4 / 2)
		arg_106_0.levelUpSprite:addTo(arg_106_0:getHeroContainer())
	end

	arg_106_0.levelUpSprite:setPosition(var_106_3 / 2, var_106_4 / 2)
	arg_106_0.levelUpSprite:setVisible(true)
	arg_106_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1, cc.p(var_106_3 / 2, var_106_4 / 2 + 100)), false, function()
		arg_106_0.levelUpSprite:setVisible(false)
	end)
end

function var_0_7.resetEffect(arg_108_0)
	if arg_108_0.clickEffect then
		arg_108_0.clickEffect = nil
	end

	if arg_108_0.levelUpSprite then
		arg_108_0.levelUpSprite = nil
	end

	if arg_108_0.levelUpEffect then
		arg_108_0.levelUpEffect = nil
	end

	if arg_108_0.eatExpEffect then
		arg_108_0.eatExpEffect = nil
	end
end

function var_0_7.updateScrollBg(arg_109_0)
	if not arg_109_0.cache[var_0_33.Info] then
		return
	end

	local var_109_0 = arg_109_0.scrollBg:getViewRect()
	local var_109_1 = arg_109_0:nodeByName("shuxing_container")
	local var_109_2 = arg_109_0:nodeByName("jieshao_container")
	local var_109_3 = arg_109_0:nodeByName("recommend_container")
	local var_109_4 = arg_109_0:nodeByName("chart_container")
	local var_109_5 = var_109_1:getContentSize().height
	local var_109_6 = var_109_3:getContentSize().height
	local var_109_7 = var_109_2:getContentSize().height
	local var_109_8 = var_109_4:getContentSize().height

	var_109_4:setPosition(cc.p(0, var_109_6 + var_109_7 + var_109_5))
	var_109_3:setPositionY(var_109_7 + var_109_5)
	var_109_2:setPosition(cc.p(0, var_109_5))
	var_109_1:setPosition(cc.p(0, 0))
	arg_109_0.scrollBg:setScrollWidth(var_109_0.width)
	arg_109_0.scrollBg:setScrollHeight(var_109_5 + var_109_7 + var_109_6 + var_109_8)
	arg_109_0.scrollBg:scrollTo(0, var_109_0.height - var_109_5 - var_109_7 - var_109_6 - var_109_8)
end

function var_0_7.updateAttrScore(arg_110_0, arg_110_1)
	arg_110_1 = arg_110_1 or arg_110_0.hero

	arg_110_0:nodeByName("zhandouli_txt"):setString(arg_110_1:getZhandouli())
end

function var_0_7.updateHeroModel(arg_111_0, arg_111_1)
	if arg_111_1 then
		local var_111_0 = {
			arg_111_1:getTableID()
		}
		local var_111_1 = arg_111_0:getHeroModel()

		var_111_1:setTouchSwallowEnabled(false)

		arg_111_0.modelState = xyd.ModelState.Walk

		local var_111_2 = arg_111_0:getHeroContainer():getContentSize().width / 2

		var_111_1:setPosition(cc.p(var_111_2, 0))

		if arg_111_1:getTableID() == 11005 then
			var_111_1:setPosition(cc.p(var_111_2 - 100, 0))
		end

		arg_111_0:getHeroContainer():removeAllChildren()
		var_111_1:addTo(arg_111_0:getHeroContainer())
		var_111_1:setTouchEnabled(true)

		arg_111_0.isShow = false

		arg_111_0:getHeroContainer():addTouchEventListener(function(arg_112_0, arg_112_1)
			if arg_112_1 == ccui.TouchEventType.ended and not arg_111_0.isShow then
				arg_111_0:resetModelState()
			end
		end)
	else
		local var_111_3 = arg_111_0:getHeroModel()

		var_111_3:setTouchSwallowEnabled(false)

		arg_111_0.modelState = xyd.ModelState.Walk

		local var_111_4 = arg_111_0:getHeroContainer():getContentSize().width / 2

		var_111_3:setPosition(cc.p(var_111_4, 0))
		arg_111_0:getHeroContainer():removeAllChildren()
		var_111_3:addTo(arg_111_0:getHeroContainer())
		var_111_3:setTouchEnabled(true)

		arg_111_0.isShow = false

		arg_111_0:getHeroContainer():addTouchEventListener(function(arg_113_0, arg_113_1)
			if arg_113_1 == ccui.TouchEventType.ended and not arg_111_0.isShow then
				arg_111_0:resetModelState()
			end
		end)
	end
end

function var_0_7.setIsShow(arg_114_0)
	arg_114_0.isShow = false

	arg_114_0:getHeroModel():idle()
end

function var_0_7.setIsSkinShow(arg_115_0)
	arg_115_0.isSkinShow = false

	arg_115_0.heroSkinModel_:idle()
end

function var_0_7.resetModelState(arg_116_0)
	local var_116_0 = arg_116_0:getHeroModel()

	if arg_116_0.modelState == 8 then
		arg_116_0.modelState = arg_116_0.modelState + 1
	end

	arg_116_0.modelState = arg_116_0.modelState % 8
	arg_116_0.isShow = true

	local var_116_1

	if arg_116_0.modelState == xyd.ModelState.Walk then
		var_116_0:walk(true)

		arg_116_0.isShow = false
		var_116_1 = xyd.tables.model:getMoveSound(arg_116_0.hero:getModelID())
	elseif arg_116_0.modelState == xyd.ModelState.Win then
		var_116_0:win(false, handler(arg_116_0, arg_116_0.setIsShow))

		var_116_1 = xyd.tables.model:getWinSound(arg_116_0.hero:getModelID())
	elseif arg_116_0.modelState == xyd.ModelState.Attack1 then
		var_116_0:attack(1, nil, nil, handler(arg_116_0, arg_116_0.setIsShow))

		var_116_1 = xyd.tables.model:getNormalAttackSound(arg_116_0.hero:getModelID())
	elseif arg_116_0.modelState == xyd.ModelState.Attack2 then
		var_116_0:attack(2, nil, nil, handler(arg_116_0, arg_116_0.setIsShow))

		var_116_1 = xyd.tables.model:getAttack1Sound(arg_116_0.hero:getModelID())
	elseif arg_116_0.modelState == xyd.ModelState.Attack3 then
		var_116_0:attack(3, nil, nil, handler(arg_116_0, arg_116_0.setIsShow))

		var_116_1 = xyd.tables.model:getAttack2Sound(arg_116_0.hero:getModelID())
	elseif arg_116_0.modelState == xyd.ModelState.Attack4 then
		if not var_116_0:hasAnimation("gongji04") then
			arg_116_0.modelState = arg_116_0.modelState + 1

			arg_116_0:resetModelState()

			return
		end

		var_116_0:attack(4, nil, nil, handler(arg_116_0, arg_116_0.setIsShow))

		var_116_1 = xyd.tables.model:getAttack4Sound(arg_116_0.hero:getModelID())
	elseif arg_116_0.modelState == xyd.ModelState.Attack5 then
		if not var_116_0:hasAnimation("gongji05") then
			arg_116_0.modelState = arg_116_0.modelState + 1

			arg_116_0:resetModelState()

			return
		end

		var_116_0:attack(5, nil, nil, handler(arg_116_0, arg_116_0.setIsShow))

		var_116_1 = xyd.tables.model:getAttack4Sound(arg_116_0.hero:getModelID())
	else
		arg_116_0:setIsShow()
	end

	if var_116_1 and var_116_1 ~= "" then
		local var_116_2 = string.sub(var_116_1, #var_116_1 - 4, #var_116_1 - 4)
		local var_116_3 = xyd.tables.hero:getSoundDelayTime(arg_116_0.hero.tableID_, tonumber(var_116_2))
		local var_116_4, var_116_5 = arg_116_0.hero:getHeroVoiceState()

		if var_116_5[var_0_6[tonumber(var_116_2)]] and var_116_3 > 0 then
			arg_116_0.selfPlayer:playHeroSound(var_116_1, var_116_3)
		end
	end

	arg_116_0.modelState = arg_116_0.modelState + 1
end

function var_0_7.resetSkinModelState(arg_117_0)
	local var_117_0 = arg_117_0.heroSkinModel_

	if arg_117_0.modelState == 8 then
		arg_117_0.modelState = arg_117_0.modelState + 1
	end

	arg_117_0.modelState = arg_117_0.modelState % 8
	arg_117_0.isSkinShow = true

	local var_117_1

	if arg_117_0.modelState == xyd.ModelState.Walk then
		var_117_0:walk(true)

		arg_117_0.isSkinShow = false
		var_117_1 = xyd.tables.model:getMoveSound(arg_117_0.hero:getModelID())
	elseif arg_117_0.modelState == xyd.ModelState.Win then
		var_117_0:win(false, handler(arg_117_0, arg_117_0.setIsSkinShow))

		var_117_1 = xyd.tables.model:getWinSound(arg_117_0.hero:getModelID())
	elseif arg_117_0.modelState == xyd.ModelState.Attack1 then
		var_117_0:attack(1, nil, nil, handler(arg_117_0, arg_117_0.setIsSkinShow))

		var_117_1 = xyd.tables.model:getNormalAttackSound(arg_117_0.hero:getModelID())
	elseif arg_117_0.modelState == xyd.ModelState.Attack2 then
		var_117_0:attack(2, nil, nil, handler(arg_117_0, arg_117_0.setIsSkinShow))

		var_117_1 = xyd.tables.model:getAttack1Sound(arg_117_0.hero:getModelID())
	elseif arg_117_0.modelState == xyd.ModelState.Attack3 then
		var_117_0:attack(3, nil, nil, handler(arg_117_0, arg_117_0.setIsSkinShow))

		var_117_1 = xyd.tables.model:getAttack2Sound(arg_117_0.hero:getModelID())
	elseif arg_117_0.modelState == xyd.ModelState.Attack4 then
		if not var_117_0:hasAnimation("gongji04") then
			arg_117_0.modelState = arg_117_0.modelState + 1

			arg_117_0:resetSkinModelState()

			return
		end

		var_117_0:attack(4, nil, nil, handler(arg_117_0, arg_117_0.setIsSkinShow))

		var_117_1 = xyd.tables.model:getAttack4Sound(arg_117_0.hero:getModelID())
	elseif arg_117_0.modelState == xyd.ModelState.Attack5 then
		if not var_117_0:hasAnimation("gongji05") then
			arg_117_0.modelState = arg_117_0.modelState + 1

			arg_117_0:resetSkinModelState()

			return
		end

		var_117_0:attack(5, nil, nil, handler(arg_117_0, arg_117_0.setIsSkinShow))

		var_117_1 = xyd.tables.model:getAttack4Sound(arg_117_0.hero:getModelID())
	else
		arg_117_0:setIsSkinShow()
	end

	if var_117_1 and var_117_1 ~= "" then
		local var_117_2 = string.sub(var_117_1, #var_117_1 - 4, #var_117_1 - 4)
		local var_117_3 = xyd.tables.hero:getSoundDelayTime(arg_117_0.hero.tableID_, tonumber(var_117_2))
		local var_117_4, var_117_5 = arg_117_0.hero:getHeroVoiceState()

		if var_117_5[var_0_6[tonumber(var_117_2)]] and var_117_3 > 0 then
			arg_117_0.selfPlayer:playHeroSound(var_117_1, var_117_3)
		end
	end

	arg_117_0.modelState = arg_117_0.modelState + 1
end

function var_0_7.getHeroModel(arg_118_0)
	if arg_118_0.heroModel_ then
		return arg_118_0.heroModel_
	end

	if arg_118_0.isTrySkin and arg_118_0.trySkinModelID > 0 then
		local var_118_0 = xyd.HeroAnimation.new(arg_118_0.trySkinModelID, arg_118_0.trySkinModelID, xyd.tables.model:uiScale(arg_118_0.trySkinModelID), {})

		if var_118_0 then
			var_118_0:idle()
		end

		arg_118_0.heroModel_ = var_118_0

		return arg_118_0.heroModel_
	else
		arg_118_0.heroModel_ = arg_118_0.hero:getHeroModel()
	end

	return arg_118_0.heroModel_
end

function var_0_7.setSkillContainer(arg_119_0, arg_119_1)
	if not arg_119_0.cache[var_0_33.Skill] then
		return
	end

	if tolua.isnull(arg_119_0.skillContainer) then
		return
	end

	arg_119_1 = arg_119_1 or arg_119_0.hero

	local var_119_0 = arg_119_1:getSkillId()

	arg_119_0.skillItems = {}

	local var_119_1 = arg_119_0.skillContainer:getChildByName("scroll_bg")

	arg_119_0:initPriceActivity()

	if not arg_119_0.skillList then
		arg_119_0.skillList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 500, 420),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(var_119_1):onScroll(handler(arg_119_0, arg_119_0.scrollListener))
	else
		arg_119_0.skillList:removeAllItems()
	end

	local var_119_2 = 0
	local var_119_3 = xyd.tables.skill

	for iter_119_0, iter_119_1 in ipairs(var_119_0) do
		local var_119_4 = var_119_3:isAwakenSkill(iter_119_1) > 0
		local var_119_5 = var_119_3:isAwakeTwiceSkill(iter_119_1) > 0
		local var_119_6 = not var_119_4 and not var_119_5

		if iter_119_1 ~= 0 and (var_119_6 or var_119_4 and xyd.tables.hero:isCanAwaken(arg_119_1:getTableID()) > 0 and arg_119_0.selfPlayer.maxTeamLev >= 90 or var_119_5 and xyd.tables.hero:isCanAwakeTwice(arg_119_1:getTableID()) > 0 and arg_119_0.selfPlayer.maxTeamLev >= 100) then
			local var_119_7 = display.newNode()
			local var_119_8 = arg_119_0.skillList:newItem()
			local var_119_9 = xyd.tables.skill:icon(iter_119_1)
			local var_119_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/skill_item.csb")
			local var_119_11 = var_119_10:getChildByName("icon")
			local var_119_12 = xyd.SpriteLoader.new(var_119_9, nil, nil, xyd.DefaultImageType.SKILL_ICON, var_119_11)
			local var_119_13 = var_119_10:getChildByName("background"):getContentSize()

			var_119_10:setContentSize(var_119_13)
			var_119_7:setContentSize(var_119_13)

			local var_119_14 = var_119_10:getChildByName("border"):getChildByName("skill_hide")

			if var_119_6 or var_119_4 and arg_119_1:isAwaken() or var_119_5 and arg_119_1:isAwakeTwice() then
				var_119_10:getChildByName("small_mana"):setVisible(true)
				var_119_10:getChildByName("gold_text"):setVisible(true)
				var_119_10:getChildByName("lev"):setVisible(true)
				var_119_10:getChildByName("level_extra"):setVisible(true)
				var_119_14:setVisible(false)

				local var_119_15 = xyd.AssetLoader:get():loadSprite("windows/hero/skill_icon_mask.png")

				var_119_15:setPosition(var_119_11:getWidth() / 2, var_119_11:getHeight() / 2)
				var_119_15:setAnchorPoint(cc.p(0.5, 0.5))
				var_119_15:scale(var_119_11:getWidth() / var_119_15:getWidth())

				local var_119_16 = cc.ClippingNode:create()

				var_119_16:setStencil(var_119_15)
				var_119_16:setInverted(true)
				var_119_16:setAlphaThreshold(0)
				var_119_11:addChild(var_119_16)
				var_119_16:addChild(var_119_12)
				var_119_12:align(display.LEFT_BOTTOM, 0, 0)
				var_119_12:scale((var_119_11:getWidth() - 3) / var_119_12:getWidth())

				local var_119_17 = cc.ui.UIPushButton.new({
					pressed = "windows/hero/btn_plus.png",
					disabled = "windows/hero/btn_plus_white.png",
					normal = "windows/hero/btn_plus.png"
				})

				var_119_17:setAnchorPoint(cc.p(0.5, 0.5))
				var_119_17:setPosition(var_119_10:getChildByName("btn_pos"):getPosition())
				var_119_17:addTo(var_119_10)
				var_119_17:setName("jiadian")

				if arg_119_1:getSkillLevel(iter_119_0) then
					local var_119_18 = arg_119_1:getSkillLevel(iter_119_0) - xyd.SKILL_EXTRA[iter_119_0]

					var_119_10:getChildByName("lev"):setString("lv. " .. var_119_18)

					if arg_119_1:getExtraSkillLevel() > 0 then
						var_119_10:getChildByName("level_extra"):show()
						var_119_10:getChildByName("level_extra"):setString("+" .. arg_119_1:getExtraSkillLevel())
					else
						var_119_10:getChildByName("level_extra"):hide()
					end

					var_119_10:getChildByName("jiesuo"):setVisible(false)

					local var_119_19 = arg_119_0:getSkillUpgradeDiscount()
					local var_119_20 = xyd.isSuperHero(arg_119_1) and var_119_19 * xyd.tables.skillPrice:gold(arg_119_1:getSkillLevel(iter_119_0)) * 10 or var_119_19 * xyd.tables.skillPrice:gold(arg_119_1:getSkillLevel(iter_119_0))

					var_119_10:getChildByName("gold_text"):setString(var_119_20)

					if var_119_20 > arg_119_0.selfPlayer.mana then
						var_119_10:getChildByName("gold_text"):setColor(cc.c4b(255, 0, 0, 255))
					else
						var_119_10:getChildByName("gold_text"):setColor(cc.c4b(13, 66, 128, 255))
					end
				else
					local var_119_21 = var_0_21:translation("HERO_JIESUO_" .. iter_119_0)

					if var_119_4 then
						var_119_21 = var_0_21:translation("AWAKE_SKILL_LOCK_TIP")
					elseif var_119_5 then
						var_119_21 = var_0_21:translation("AWAKE_TWICE_SKILL_LOCK_TIP")
					end

					var_119_10:getChildByName("jiesuo"):setString(var_119_21)
					var_119_10:getChildByName("lev"):setVisible(false)
					var_119_10:getChildByName("level_extra"):hide()
					var_119_10:getChildByName("gold_text"):setVisible(false)
					var_119_10:getChildByName("small_mana"):setVisible(false)
				end

				if not arg_119_1:getSkillLevel(iter_119_0) or arg_119_1:getSkillLevel(iter_119_0) >= arg_119_1:getLevel() + arg_119_1:getBookShelfSkillLevel() then
					var_119_17:setButtonEnabled(false)
				else
					var_119_17:setButtonEnabled(true)

					local var_119_22 = false

					arg_119_0.isCanLongTouchSkill = true

					var_119_17:onButtonPressed(function(arg_120_0)
						var_119_17:setScale(0.9)

						local var_120_0 = 0

						local function var_120_1()
							var_120_0 = var_120_0 + var_0_27

							if arg_119_0.addSkillLevel and arg_119_0.isCanLongTouchSkill then
								arg_119_0:addSkillLevel(iter_119_0, var_119_17)
							end
						end

						local function var_120_2()
							var_120_0 = var_120_0 + 0.2

							if var_120_0 > 1 and var_120_0 <= var_0_26 then
								var_119_22 = true

								if arg_119_0.addSkillLevel and arg_119_0.isCanLongTouchSkill then
									arg_119_0:addSkillLevel(iter_119_0, var_119_17)
								end
							elseif var_120_0 > var_0_26 then
								arg_119_0.skillClickHandle[2] = var_0_17.scheduleGlobal(var_120_1, var_0_27)

								var_0_17.unscheduleGlobal(arg_119_0.skillClickHandle[1])
							else
								var_119_22 = false
							end
						end

						var_119_22 = false

						if arg_119_0.skillClickHandle[1] then
							var_0_17.unscheduleGlobal(arg_119_0.skillClickHandle[1])
						end

						if arg_119_0.skillClickHandle[2] then
							var_0_17.unscheduleGlobal(arg_119_0.skillClickHandle[2])
						end

						arg_119_0.skillClickHandle[1] = var_0_17.scheduleGlobal(var_120_2, 0.2)
					end)
					var_119_17:onButtonRelease(function(arg_123_0)
						var_119_17:setScale(1)

						if xyd.WindowManager.get():isWindowOpen("guide") then
							xyd.WindowManager.get():closeWindow("guide")
						end

						if arg_119_0.skillClickHandle[1] ~= nil then
							var_0_17.unscheduleGlobal(arg_119_0.skillClickHandle[1])
						end

						if arg_119_0.skillClickHandle[2] ~= nil then
							var_0_17.unscheduleGlobal(arg_119_0.skillClickHandle[2])
						end

						if not arg_119_1:getSkillLevel(iter_119_0) or arg_119_1:getSkillLevel(iter_119_0) >= arg_119_1:getLevel() + arg_119_1:getBookShelfSkillLevel() then
							var_119_17:setButtonEnabled(false)
						else
							var_119_17:setButtonEnabled(true)
						end

						if not var_119_22 then
							arg_119_0:addSkillLevel(iter_119_0, var_119_17)
						end

						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.ECONOMY_AFTER
						})
					end)
				end
			else
				var_119_14:setVisible(true)
				var_119_10:getChildByName("small_mana"):setVisible(false)
				var_119_10:getChildByName("gold_text"):setVisible(false)
				var_119_10:getChildByName("lev"):setVisible(false)
				var_119_10:getChildByName("level_extra"):setVisible(false)

				local var_119_23 = var_0_21:translation("AWAKE_SKILL_LOCK_TIP")

				if var_119_5 then
					var_119_23 = var_0_21:translation("AWAKE_TWICE_SKILL_LOCK_TIP")
				end

				var_119_10:getChildByName("jiesuo"):setString(var_119_23)
			end

			var_119_10:getChildByName("name"):setString(xyd.tables.skill:name(iter_119_1))
			var_119_10:addTo(var_119_7)

			var_119_10.id = iter_119_1

			table.insert(arg_119_0.skillItems, var_119_10)
			var_119_8:addContent(var_119_7)
			var_119_8:setItemSize(var_119_7:getWidth(), var_119_7:getHeight() + 6)
			arg_119_0.skillList:addItem(var_119_8)

			var_119_2 = var_119_2 + 1

			arg_119_0:createSkillTip(iter_119_0, iter_119_1)
		end
	end

	local var_119_24 = arg_119_0:getFilteredSkinItemIds()

	if var_119_24 and next(var_119_24) then
		for iter_119_2 = 1, #var_119_24 do
			local var_119_25 = var_119_24[iter_119_2]
			local var_119_26 = xyd.tables.skinSkill:getSkillID(var_119_25)

			if var_119_26 > 0 then
				local var_119_27 = arg_119_0:createSkinSkillItem(var_119_26, var_119_25)

				arg_119_0.skillList:addItem(var_119_27)

				var_119_2 = var_119_2 + 1

				arg_119_0:createSkillTip(var_119_2, var_119_26)
			end
		end
	end

	if var_119_2 < 5 then
		arg_119_0.skillList:setBounceable(false)
	else
		arg_119_0.skillList:setBounceable(true)
	end

	arg_119_0.skillCount = var_119_2

	arg_119_0.skillList:reload()
end

function var_0_7.createSkinSkillItem(arg_124_0, arg_124_1, arg_124_2)
	local var_124_0 = display.newNode()
	local var_124_1 = arg_124_0.skillList:newItem()
	local var_124_2 = xyd.tables.skill:icon(arg_124_1)
	local var_124_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/skill_item.csb")
	local var_124_4 = var_124_3:getChildByName("icon")
	local var_124_5 = xyd.SpriteLoader.new(var_124_2, nil, nil, xyd.DefaultImageType.SKILL_ICON, var_124_4)
	local var_124_6 = var_124_3:getChildByName("background"):getContentSize()

	var_124_3:setContentSize(var_124_6)
	var_124_0:setContentSize(var_124_6)

	local var_124_7 = var_124_3:getChildByName("border"):getChildByName("skill_hide")

	var_124_3:getChildByName("small_mana"):setVisible(false)
	var_124_3:getChildByName("gold_text"):setVisible(false)
	var_124_3:getChildByName("lev"):setVisible(true)
	var_124_3:getChildByName("level_extra"):setVisible(false)
	var_124_7:setVisible(false)

	local var_124_8 = xyd.AssetLoader:get():loadSprite("windows/hero/skill_icon_mask.png")

	var_124_8:setPosition(var_124_4:getWidth() / 2, var_124_4:getHeight() / 2)
	var_124_8:setAnchorPoint(cc.p(0.5, 0.5))
	var_124_8:scale(var_124_4:getWidth() / var_124_8:getWidth())

	local var_124_9 = cc.ClippingNode:create()

	var_124_9:setStencil(var_124_8)
	var_124_9:setInverted(true)
	var_124_9:setAlphaThreshold(0)
	var_124_4:addChild(var_124_9)
	var_124_9:addChild(var_124_5)
	var_124_5:align(display.LEFT_BOTTOM, 0, 0)
	var_124_5:scale((var_124_4:getWidth() - 3) / var_124_5:getWidth())

	local var_124_10 = cc.ui.UIPushButton.new({
		pressed = "windows/hero/btn_plus.png",
		disabled = "windows/hero/btn_plus_white.png",
		normal = "windows/hero/btn_plus.png"
	})

	var_124_10:setAnchorPoint(cc.p(0.5, 0.5))
	var_124_10:setPosition(var_124_3:getChildByName("btn_pos"):getPosition())
	var_124_10:addTo(var_124_3)
	var_124_10:setName("jiadian")
	var_124_3:getChildByName("lev"):setVisible(false)
	var_124_10:setVisible(false)

	local var_124_11 = xyd.getItemBg(1)
	local var_124_12 = var_124_11:getContentSize().height
	local var_124_13 = var_124_4:getContentSize()

	var_124_11:addTo(var_124_9, -100)
	var_124_11:setAnchorPoint(0.5, 0.5)
	var_124_11:setPosition(var_124_13.width / 2, var_124_13.height / 2)
	var_124_11:setScale(var_124_13.height / var_124_12)

	if arg_124_0.hero.skinId_ == xyd.tables.item:skinModel(arg_124_2) then
		var_124_7:setVisible(false)
	else
		var_124_7:setVisible(true)
	end

	local var_124_14 = var_0_21:translation("skin_skill")

	var_124_3:getChildByName("jiesuo"):setVisible(true)
	var_124_3:getChildByName("jiesuo"):setString(var_124_14)
	var_124_3:getChildByName("name"):setString(xyd.tables.skill:name(arg_124_1))
	var_124_3:addTo(var_124_0)

	var_124_3.isSkinSkill = true

	table.insert(arg_124_0.skillItems, var_124_3)
	var_124_1:addContent(var_124_0)
	var_124_1:setItemSize(var_124_0:getWidth(), var_124_0:getHeight() + 12)

	return var_124_1
end

function var_0_7.initPriceActivity(arg_125_0)
	local var_125_0 = arg_125_0.skillContainer:getChildByName("price_activity")
	local var_125_1 = arg_125_0:getSkillUpgradeDiscount()

	if var_125_1 == xyd.SkillUpgradeDiscount.FOUR_DISCOUNT then
		-- block empty
	elseif var_125_1 == xyd.SkillUpgradeDiscount.FIVE_DISCOUNT then
		arg_125_0:nodeByName("txt_discount"):setString(var_0_21:translation("HERO_MAIN_TEXT_21"))
	elseif var_125_1 == xyd.SkillUpgradeDiscount.EIGHT_DISCOUNT then
		-- block empty
	else
		var_125_0:setVisible(false)
	end
end

function var_0_7.getSkillUpgradeDiscount(arg_126_0)
	local var_126_0 = xyd.SkillUpgradeDiscount.NOT_DISCOUNT

	if arg_126_0.activities:isHalfPriceOpen() then
		var_126_0 = xyd.SkillUpgradeDiscount.FIVE_DISCOUNT
	end

	return var_126_0
end

function var_0_7.addSkillLevel(arg_127_0, arg_127_1, arg_127_2)
	local var_127_0 = arg_127_0.hero
	local var_127_1 = xyd.StoryData.get():getGuideID()

	if var_127_0:getSkillLevel(arg_127_1) >= var_127_0:getLevel() + var_127_0:getBookShelfSkillLevel() then
		-- block empty
	elseif var_127_1 == xyd.GuideStoryType.GUIDE_SKILL_THREE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_FOUR)
		arg_127_0:playGuide()
	elseif var_127_1 == xyd.GuideStoryType.GUIDE_SKILL_FOUR then
		if arg_127_0.selfPlayer:getSkillPoint() <= 6 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_FIVE)
			arg_127_0:playGuide()
		else
			arg_127_0:playGuide()
		end
	elseif var_127_1 == xyd.GuideStoryType.GUIDE_SKILL_FIVE then
		if arg_127_0.selfPlayer:getSkillPoint() <= 1 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_SIX)
			arg_127_0:playGuide()
		else
			arg_127_0:playGuide()
		end
	elseif var_127_1 == xyd.GuideStoryType.GUIDE_SKILL_SEVEN then
		if arg_127_0.selfPlayer:getSkillPoint() <= 0 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_END)
			xyd.StoryData.get():persist()

			arg_127_0.isPlaySkillEndGuide = true
		else
			arg_127_0:playGuide()
		end
	end

	local var_127_2 = arg_127_0.hero

	if var_127_2:getSkillLevel(arg_127_1) >= var_127_2:getLevel() + var_127_2:getBookShelfSkillLevel() then
		local var_127_3 = var_0_21:translation("SKILL_UP_LIMIT")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_127_3
		})

		if arg_127_0.skillClickHandle[1] then
			var_0_17.unscheduleGlobal(arg_127_0.skillClickHandle[1])
		end

		if arg_127_0.skillClickHandle[2] then
			var_0_17.unscheduleGlobal(arg_127_0.skillClickHandle[2])
		end

		return
	elseif arg_127_0.selfPlayer:getSkillPoint() <= 0 then
		local var_127_4 = arg_127_0.selfPlayer.buySkillTimes
		local var_127_5 = xyd.tables.refreshCost:buySkillCost(var_127_4 + 1)
		local var_127_6 = xyd.tables.vip:skillBuy(arg_127_0.selfPlayer.vip)
		local var_127_7
		local var_127_8

		if not var_127_6 then
			var_127_7 = 1
			var_127_8 = string.format(var_0_21:translation("BUY_SKILL_POINTS_TIP1"), var_127_5, arg_127_0.skillPoints, var_127_4)
		else
			var_127_7 = 2
			var_127_8 = string.format(var_0_21:translation("SKILL_POINT_BUY"), var_127_5, var_127_4)
		end

		if arg_127_0:isHasSkillItem() then
			local var_127_9 = {
				buytype = var_127_7,
				text = var_127_8,
				callback = function()
					if not var_127_6 then
						xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
							windowState = false
						})
					else
						local var_128_0 = arg_127_0.selfPlayer.buySkillTimes
						local var_128_1 = xyd.tables.refreshCost:buySkillCost(var_128_0 + 1)

						if var_128_1 > arg_127_0.selfPlayer.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
								var_0_21:translation("ZUANSHI_ABSENCE")
							}, function()
								local var_129_0 = {}

								var_129_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_129_0)
							end)
						else
							local function var_128_2()
								xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
									var_0_21:translation("SKILL_POINT_ABSENCE"),
									string.format(var_0_21:translation("SKILL_POINT_BUY"), var_128_1, var_128_0)
								}, function()
									arg_127_0.selfPlayer:buySkillPoint()
									arg_127_0.giftPush:setSceneCondition(27)

									var_128_0 = var_128_0 + 1
									var_128_1 = xyd.tables.refreshCost:buySkillCost(var_128_0 + 1)
									var_127_8 = string.format(var_0_21:translation("SKILL_POINT_BUY"), var_128_1, var_128_0)

									xyd.WindowManager.get():getWindow("buy_tili"):nodeByName("text_tips1"):setString(var_127_8)
								end)
							end

							if not arg_127_0.skillLevel or not next(arg_127_0.skillLevel) then
								var_128_2()
							else
								arg_127_0.isCanLongTouchSkill = false

								if arg_127_0.sendSkillLevUpRequest then
									arg_127_0:sendSkillLevUpRequest(function()
										var_128_2()

										arg_127_0.isCanLongTouchSkill = true
									end)
								end
							end
						end
					end
				end
			}

			if arg_127_0.sendSkillLevUpRequest then
				arg_127_0:sendSkillLevUpRequest()
			end

			xyd.WindowManager.get():openWindow("buy_tili", var_127_9)
		else
			if not xyd.tables.vip:skillBuy(arg_127_0.selfPlayer.vip) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_0_21:translation("SKILL_POINT_VIP")
				}, function()
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
						windowState = true
					})
				end, {
					btnRightName = var_0_21:translation("CHECK_PRIVILEGE")
				})
			else
				local var_127_10 = arg_127_0.selfPlayer.buySkillTimes
				local var_127_11 = xyd.tables.refreshCost:buySkillCost(var_127_10 + 1)

				if var_127_11 > arg_127_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						var_0_21:translation("ZUANSHI_ABSENCE")
					}, function()
						local var_134_0 = {}

						var_134_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_134_0)
					end)
				else
					local function var_127_12()
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
							var_0_21:translation("SKILL_POINT_ABSENCE"),
							string.format(var_0_21:translation("SKILL_POINT_BUY"), var_127_11, var_127_10)
						}, function()
							arg_127_0.selfPlayer:buySkillPoint()
							arg_127_0.giftPush:setSceneCondition(27)
						end)
					end

					if not arg_127_0.skillLevel or not next(arg_127_0.skillLevel) then
						var_127_12()
					else
						arg_127_0.isCanLongTouchSkill = false

						if arg_127_0.sendSkillLevUpRequest then
							arg_127_0:sendSkillLevUpRequest(function()
								var_127_12()

								arg_127_0.isCanLongTouchSkill = true
							end)
						end
					end
				end
			end

			return
		end
	else
		local var_127_13 = xyd.FunctionID.ID_SKILL_UP

		if arg_127_0.selfPlayer:isFuncOpen(var_127_13) == false then
			local var_127_14 = xyd.tables.functionOpen:level(var_127_13)
			local var_127_15 = string.format(var_0_21:translation("FUNCTION_OPEN_TIP_LEVEL"), var_127_14)

			xyd.WindowManager.get():openWindow("toast", {
				message = var_127_15
			})

			return
		end

		local var_127_16 = arg_127_0:getSkillUpgradeDiscount()

		if (xyd.isSuperHero(var_127_2) and xyd.tables.skillPrice:gold(var_127_2:getSkillLevel(arg_127_1)) * var_127_16 * 10 or xyd.tables.skillPrice:gold(var_127_2:getSkillLevel(arg_127_1)) * var_127_16) > arg_127_0.selfPlayer.mana then
			arg_127_0.giftPush:judgePush(4)
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_0_21:translation("JINBI_ABSENCE")
			}, function()
				local var_138_0 = xyd.FunctionID.ID_GOLD_HAND

				if arg_127_0.selfPlayer:isFuncOpen(var_138_0) == true then
					xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
				else
					local var_138_1 = xyd.tables.functionOpen:level(var_138_0)
					local var_138_2 = string.format(var_0_21:translation("FUNCTION_OPEN_TIP_LEVEL"), var_138_1)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_138_2
					})
				end
			end)

			return
		end

		arg_127_0:playSKillUpEffect(arg_127_1)
		audio.playSound(xyd.tables.sound:getSound("hero_upskill"))

		local var_127_17 = arg_127_0:getSkillUpgradeDiscount()

		arg_127_0.selfPlayer.mana = arg_127_0.selfPlayer.mana - (xyd.isSuperHero(var_127_2) and xyd.tables.skillPrice:gold(var_127_2:getSkillLevel(arg_127_1)) * var_127_17 * 10 or xyd.tables.skillPrice:gold(var_127_2:getSkillLevel(arg_127_1)) * var_127_17)

		arg_127_0.selfPlayer:skillPointDecr()

		var_127_2.skillLev_[arg_127_1] = var_127_2.skillLev_[arg_127_1] + 1

		arg_127_0:updateAttrScore()
		arg_127_0:updateSkillItem(arg_127_1, true)
		arg_127_0:updateSkillContainer(true)

		if arg_127_0.skillLevel[arg_127_1] then
			arg_127_0.skillLevel[arg_127_1] = arg_127_0.skillLevel[arg_127_1] + 1
		else
			arg_127_0.skillLevel[arg_127_1] = 1
		end

		if arg_127_0.selfPlayer:getSkillPoint() == xyd.tables.vip:skillPoint(arg_127_0.selfPlayer.vip) - 1 then
			arg_127_0.selfPlayer:updateLastSkillPoint(xyd.ServerTime.get():getServerTime())
		end

		if not var_127_2:getSkillLevel(arg_127_1) or var_127_2:getSkillLevel(arg_127_1) >= var_127_2:getLevel() + var_127_2:getBookShelfSkillLevel() then
			if arg_127_2 and not tolua.isnull(arg_127_2) then
				arg_127_2:setButtonEnabled(false)
			end
		elseif arg_127_2 and not tolua.isnull(arg_127_2) then
			arg_127_2:setButtonEnabled(true)
		end
	end
end

function var_0_7.sendSkillLevUpRequest(arg_139_0, arg_139_1)
	if not arg_139_0.skillLevel or not next(arg_139_0.skillLevel) then
		return
	end

	local var_139_0 = {}
	local var_139_1 = {}
	local var_139_2 = 0

	for iter_139_0, iter_139_1 in pairs(arg_139_0.skillLevel) do
		table.insert(var_139_0, iter_139_0)
		table.insert(var_139_1, iter_139_1)

		var_139_2 = var_139_2 + iter_139_1
	end

	arg_139_0.giftPush:setSceneCondition(28, var_139_2)

	local var_139_3 = xyd.luaStringMerge(var_139_0, "|")
	local var_139_4 = xyd.luaStringMerge(var_139_1, "|")
	local var_139_5 = {
		partner_id = arg_139_0.hero:getHeroID(),
		skill_colors = var_139_3,
		skill_counts = var_139_4
	}

	arg_139_0.selfPlayer:setAllSkillLevel(var_139_5, function(arg_140_0, arg_140_1)
		local var_140_0

		if arg_140_1 and arg_140_1.skills then
			var_140_0 = xyd.splitToNumber(arg_140_1.skills, "|")
		end

		local var_140_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
		local var_140_2 = var_140_1:getHeroByID(var_139_5.partner_id)

		if arg_140_0 == xyd.error.OK then
			if arg_140_1.is_success == 0 then
				var_140_1.skillPoint = arg_140_1.skill_point
				var_140_1.lastSkillPoint = arg_140_1.skill_time

				for iter_140_0, iter_140_1 in pairs(var_139_0) do
					var_140_2.skillLev_[iter_140_1] = var_140_0[iter_140_1] + xyd.SKILL_EXTRA[iter_140_1]
				end

				return
			end

			var_140_1.skillPoint = arg_140_1.skill_point
			var_140_1.lastSkillPoint = arg_140_1.skill_time

			for iter_140_2, iter_140_3 in pairs(var_139_0) do
				var_140_2.skillLev_[iter_140_3] = var_140_0[iter_140_3] + xyd.SKILL_EXTRA[iter_140_3]
			end
		else
			var_140_1.skillPoint = arg_140_1.skill_point
			var_140_1.lastSkillPoint = arg_140_1.skill_time

			for iter_140_4, iter_140_5 in pairs(var_139_0) do
				var_140_2.skillLev_[iter_140_5] = var_140_0[iter_140_5] + xyd.SKILL_EXTRA[iter_140_5]
			end
		end

		if not tolua.isnull(arg_139_0.skillContainer) then
			arg_139_0.skillContainer:getChildByName("jinengdian"):setString(var_140_1:getSkillPoint())
		end

		if arg_139_0.skillLevel then
			arg_139_0.skillLevel = {}
		end

		if arg_139_1 then
			arg_139_1()
		end
	end)
end

function var_0_7.playSKillUpEffect(arg_141_0, arg_141_1)
	if tolua.isnull(arg_141_0.skillItems[arg_141_1]) or tolua.isnull(arg_141_0.skillContainer) then
		return
	end

	local var_141_0 = arg_141_0.hero

	local function var_141_1(arg_142_0, arg_142_1)
		local var_142_0 = {}
		local var_142_1 = xyd.tables.skill:desc3(arg_142_0)
		local var_142_2 = xyd.tables.skill:descNumStep(arg_142_0)

		for iter_142_0 = 1, #var_142_1 do
			local var_142_3 = ""

			var_142_1[iter_142_0] = string.gsub(var_142_1[iter_142_0], "%%d%%", "%%d@")

			local var_142_4 = tonumber(var_142_2[iter_142_0])

			if var_142_4 - math.floor(var_142_4) ~= 0 then
				var_142_1[iter_142_0] = string.gsub(var_142_1[iter_142_0], "%%d", "%%.1f")
			end

			local var_142_5 = var_142_3 .. string.format(var_142_1[iter_142_0], var_142_4)
			local var_142_6 = string.gsub(var_142_5, "@", "%%")

			table.insert(var_142_0, var_142_6)
		end

		return var_142_0
	end

	local var_141_2 = var_0_30.LevelUp .. ".json"
	local var_141_3 = var_0_30.LevelUp .. ".atlas"
	local var_141_4 = var_0_29.new(var_141_2, var_141_3, 1)
	local var_141_5, var_141_6 = arg_141_0.skillItems[arg_141_1]:getChildByName("icon"):getPosition()
	local var_141_7 = arg_141_0.skillItems[arg_141_1]:getChildByName("icon"):getWidth()
	local var_141_8 = arg_141_0.skillItems[arg_141_1]:getChildByName("icon"):getHeight()

	var_141_4:setPosition(var_141_5 + var_141_7 / 2, var_141_6 + var_141_8 / 2)
	var_141_4:addTo(arg_141_0.skillItems[arg_141_1])
	var_141_4:play(nil, false)

	local var_141_9 = arg_141_0.skillItems[arg_141_1]:getWidth()
	local var_141_10 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c4b(255, 255, 0, 0),
		dimensions = cc.size(var_141_9 - 10, 0)
	}
	local var_141_11 = var_141_1(var_141_0:getSkillId(arg_141_1), var_141_0:getSkillLevel(arg_141_1))

	arg_141_0.point = arg_141_0.skillContainer:convertToNodeSpace(arg_141_0.skillItems[arg_141_1]:getChildByName("icon"):convertToWorldSpace(cc.p(0, 0)))

	local var_141_12 = 0.2

	if arg_141_0.skillTextHandle and arg_141_0.desc2list then
		for iter_141_0, iter_141_1 in ipairs(var_141_11) do
			table.insert(arg_141_0.desc2list, #arg_141_0.desc2list, iter_141_1)
		end
	else
		arg_141_0.desc2list = var_141_11
		arg_141_0.skillTextHandle = var_0_17.scheduleGlobal(function()
			local var_143_0 = xyd.WindowManager.get():getWindow("hero_main")

			if not var_143_0 then
				return
			end

			local var_143_1 = xyd.AssetLoader:get():loadLabel(var_141_10)

			var_143_1:setString(arg_141_0.desc2list[1])
			table.remove(arg_141_0.desc2list, 1)
			var_143_1:setAnchorPoint(0.5, 0.5)
			var_143_1:setPosition(arg_141_0.point.x, arg_141_0.point.y + var_141_8 / 2)
			var_143_1:align(display.CENTER_LEFT)
			var_143_1:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_143_0.skillContainer:addChild(var_143_1)

			local var_143_2 = cc.Spawn:create({
				cc.MoveBy:create(0.6, cc.p(0, 70)),
				cc.FadeOut:create(0.6)
			})

			var_143_1:runActionOnce(var_143_2, true, function()
				var_143_0.skillContainer:removeChild(var_143_1)
			end, 0)

			if not next(arg_141_0.desc2list) then
				arg_141_0.desc2list = nil

				if arg_141_0.skillTextHandle then
					var_0_17.unscheduleGlobal(arg_141_0.skillTextHandle)
				end
			end
		end, var_141_12)
	end
end

function var_0_7.createSkillTip(arg_145_0, arg_145_1, arg_145_2)
	local var_145_0 = arg_145_0.skillItems[arg_145_1]

	if not var_145_0 then
		return
	end

	if tolua.isnull(var_145_0) then
		return
	end

	local var_145_1, var_145_2 = var_145_0:getPosition()

	if var_145_0:getChildByName("skill_tip") and not tolua.isnull(var_145_0:getChildByName("skill_tip")) then
		var_145_0:removeChildByName("skill_tip")
	end

	local var_145_3 = display.newNode()
	local var_145_4 = xyd.tables.skill

	if var_145_4:getItemID(arg_145_2) == 0 then
		var_145_3:setPosition(var_145_0:getChildByName("icon"):getPosition())
	end

	var_145_3:setAnchorPoint(cc.p(0, 0))
	var_145_3:setContentSize(var_145_0:getChildByName("icon"):getContentSize())
	var_145_3:setTouchEnabled(true)
	var_145_3:addTo(var_145_0)
	var_145_3:setName("skill_tip")

	local var_145_5 = arg_145_0:convertToWorldSpace(cc.p(0, 0))

	var_145_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_146_0)
		if arg_146_0.name == "began" then
			return true
		elseif arg_146_0.name == "ended" then
			arg_145_0:closeTipWindow()

			local var_146_0 = {
				id = arg_145_2,
				skillLev = arg_145_0.hero:getSkillLevel(arg_145_1),
				extraSkillLevel = arg_145_0.hero:getExtraSkillLevel(),
				partnerID = arg_145_0.hero:getHeroID(),
				tipIndex = arg_145_1,
				skills = var_0_19:getSkillTable(arg_145_0.hero:getTableID(), arg_145_1),
				courseId = arg_145_0.hero:getSkillCourseId(arg_145_2),
				hero = arg_145_0.hero
			}

			if var_145_4:getItemID(arg_145_2) == 0 then
				var_146_0.isSpecialSkill = false
			else
				var_146_0.isSpecialSkill = true
			end

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_146_1 = xyd.WindowManager.get():openWindow("skill_tips", var_146_0)
				local var_146_2 = var_145_3:convertToWorldSpace(cc.p(0, 0))
				local var_146_3 = var_146_1:convertToNodeSpace(var_146_2)

				if var_145_4:getItemID(arg_145_2) == 0 then
					var_146_1:setPosition(var_146_3.x + var_146_1:getContentSize().width + 240, var_146_2.y - var_145_0:getContentSize().height + 30 - var_145_5.y)
				end
			end
		end
	end)
end

function var_0_7.closeTipWindow(arg_147_0)
	if xyd.WindowManager.get():getWindow("skill_tips") then
		xyd.WindowManager.get():closeWindow("skill_tips")
	end
end

function var_0_7.updateAllSkillTips(arg_148_0)
	local var_148_0 = arg_148_0.hero:getSkillId()

	for iter_148_0, iter_148_1 in pairs(var_148_0) do
		if iter_148_1 <= 0 then
			var_148_0[iter_148_0] = nil
		end

		if xyd.tables.skill:isAwakenSkill(iter_148_1) == 1 and (not arg_148_0.hero:isCanAwaken() or arg_148_0.selfPlayer.maxTeamLev < 80) then
			var_148_0[iter_148_0] = nil
		end

		if xyd.tables.skill:isAwakeTwiceSkill(iter_148_1) == 1 and (xyd.tables.hero:isCanAwakeTwice(arg_148_0.hero:getTableID()) < 1 or not arg_148_0.hero:isAwaken() or arg_148_0.selfPlayer.maxTeamLev < 100) then
			var_148_0[iter_148_0] = nil
		end
	end

	for iter_148_2, iter_148_3 in pairs(var_148_0) do
		arg_148_0:createSkillTip(iter_148_2, iter_148_3)
	end
end

function var_0_7.setEquipNode(arg_149_0, arg_149_1, arg_149_2)
	if tolua.isnull(arg_149_0) or tolua.isnull(arg_149_2) then
		return
	end

	local var_149_0 = arg_149_0.hero
	local var_149_1 = xyd.split(var_0_21:translation("COLOR_TABLE"), ",")
	local var_149_2 = {
		size = 26,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = xyd.color.HERO_QUALITY[arg_149_1],
		text = var_149_1[arg_149_1] .. xyd.Color2Level[arg_149_1]
	}
	local var_149_3 = xyd.AssetLoader.get():loadLabel(var_149_2)

	var_149_3:addTo(arg_149_2)
	var_149_3:align(display.CENTER, arg_149_2:getChildByName("node_pos"):getPosition())
	var_149_3:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_149_3:setName("title")

	for iter_149_0 = 1, xyd.MAX_ITEM_NUM do
		local var_149_4 = var_149_0:getEquipByIndexShow(iter_149_0, arg_149_1)

		if var_149_4:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_149_4:getTableID()) == 0 then
			local var_149_5 = arg_149_2:getChildByName("icon" .. iter_149_0)

			var_149_5:removeAllChildren()

			local var_149_6 = display.newNode()

			var_149_6:size(var_149_5:getContentSize())
			var_149_5:addChild(var_149_6)
			xyd.setItemBorder(var_149_6, var_149_4:getTableID())
			var_149_6:setTouchEnabled(true)

			if var_149_4:isInBackpack() or var_149_4:isHasMaterial() then
				local var_149_7 = xyd.AssetLoader:get():loadSprite("images/green_point.png")

				var_149_7:setPosition(var_149_5:getContentSize().width / 14 * 13, var_149_5:getContentSize().height / 14 * 13)
				var_149_5:addChild(var_149_7)
			end

			local var_149_8

			var_149_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_150_0)
				if arg_150_0.name == "began" then
					local var_150_0 = arg_149_0.scrollBg2:getScrollNode()

					arg_149_0.scrolly = var_150_0:getPositionY()
					var_149_8 = arg_150_0.y
				elseif arg_150_0.name == "moved" then
					if arg_149_0.scroll_is_moving == true then
						if arg_149_0.scroll_moving_end == true then
							arg_149_0.scrollBg2:scrollTo(0, arg_150_0.y - var_149_8 + arg_149_0.scrolly)
						end
					else
						arg_149_0.scrollBg2:scrollTo(0, arg_150_0.y - var_149_8 + arg_149_0.scrolly)
					end
				elseif arg_150_0.name == "ended" then
					if arg_149_0.scroll_is_moving == true then
						if arg_149_0.scroll_moving_end == true then
							if math.abs(var_149_8 - arg_150_0.y) < 20 then
								arg_149_0:showItemDetail(iter_149_0, arg_149_1, true)
							end

							arg_149_0.scrolly = arg_150_0.y - var_149_8 + arg_149_0.scrolly

							arg_149_0.scrollBg2:scrollAuto()
						end
					else
						if math.abs(var_149_8 - arg_150_0.y) < 20 then
							arg_149_0:showItemDetail(iter_149_0, arg_149_1, true)
						end

						arg_149_0.scrolly = arg_150_0.y - var_149_8 + arg_149_0.scrolly

						arg_149_0.scrollBg2:scrollAuto()
					end
				end

				return true
			end)
		else
			local var_149_9 = arg_149_2:getChildByName("awake_equip_hide")
			local var_149_10 = arg_149_2:getChildByName("awake_hide")

			if var_149_9 then
				var_149_9:setVisible(true)
				var_149_10:setVisible(true)
			end
		end
	end
end

function var_0_7.updateEquipInfoContainer(arg_151_0)
	if not arg_151_0.cache[var_0_33.Skin] then
		return
	end

	if not arg_151_0.skinList then
		local var_151_0 = arg_151_0:nodeByName("skin_list"):getContentSize()

		arg_151_0.skinList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_151_0.width, var_151_0.height),
			direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
		}):addTo(arg_151_0:nodeByName("skin_list")):onScroll(handler(arg_151_0, arg_151_0.scrollListener3))
	else
		arg_151_0.skinList:removeAllItems()
	end

	arg_151_0.skinDatas = arg_151_0:getSkinDatas()
	arg_151_0.skinItemContainer = {}

	if arg_151_0.hero.illusionSkinId_ <= 1 then
		arg_151_0.skinSelect = arg_151_0.hero.illusionSkinId_ + 1
	else
		for iter_151_0, iter_151_1 in ipairs(arg_151_0.skinDatas) do
			if iter_151_1.skinItem and var_0_20:skinModel(iter_151_1.skinItem) == arg_151_0.hero.illusionSkinId_ then
				arg_151_0.skinSelect = iter_151_0

				break
			end
		end
	end

	arg_151_0.skinSkillEquip = 0

	if arg_151_0.hero.isSkinOn_ == 1 then
		for iter_151_2, iter_151_3 in ipairs(arg_151_0.skinDatas) do
			if iter_151_3.skinItem and var_0_20:skinModel(iter_151_3.skinItem) == arg_151_0.hero.skinId_ then
				arg_151_0.skinSkillEquip = iter_151_2

				break
			end
		end
	end

	arg_151_0.skinIllusionEquip = arg_151_0.skinSelect

	for iter_151_4, iter_151_5 in ipairs(arg_151_0.skinDatas) do
		local var_151_1 = arg_151_0.skinList:newItem()
		local var_151_2 = arg_151_0:createSkinItem(iter_151_4, iter_151_5)

		var_151_1:addContent(var_151_2)
		var_151_1:setItemSize(var_151_2:getWidth() + 12, var_151_2:getHeight())
		arg_151_0.skinList:addItem(var_151_1)
	end

	arg_151_0.skinList:reload()
	arg_151_0:nodeByName("btn_skin2"):hide()
	arg_151_0:nodeByName("txt_skin_is_equipping"):show()
	arg_151_0:updateBtnSkinBtnShow(true, arg_151_0.skinDatas[arg_151_0.skinIllusionEquip].modelID)

	if arg_151_0.skinIllusionEquip >= 4 then
		arg_151_0.skinList:getScrollNode():setPositionX(525 - arg_151_0.skinIllusionEquip * 163)
	end

	arg_151_0:updateSkinSkillContainer()
	arg_151_0:updateSkinTime(arg_151_0.skinSelect)
end

function var_0_7.updateBtnSkinBtnShow(arg_152_0, arg_152_1, arg_152_2)
	local var_152_0 = arg_152_0:nodeByName("bg_skin_live")
	local var_152_1 = arg_152_0:nodeByName("btn_skin_live")

	if not arg_152_1 then
		var_152_0:hide()
		var_152_1:hide()

		return
	end

	local var_152_2 = xyd.tables.model:dynamicType(arg_152_2) == 2

	var_152_0:setVisible(var_152_2)
	var_152_1:setVisible(var_152_2)

	if not var_152_2 then
		return
	end

	local function var_152_3()
		local var_153_0 = xyd.isShowDynamicCard(arg_152_0.hero, arg_152_2)

		var_152_1:getChildByName("icon_on"):setVisible(var_153_0)
		var_152_1:getChildByName("icon_off"):setVisible(not var_153_0)
		var_152_1:getChildByName("txt_btn_skin_live"):setString(var_153_0 and "ON" or "OFF")
		var_152_1:getChildByName("txt_btn_skin_live"):setPositionX(var_153_0 and 46 or 27)
	end

	local function var_152_4()
		local var_154_0 = arg_152_0.skinItemContainer[arg_152_0.skinSelect]:getChildByName("card")
		local var_154_1 = var_154_0:getChildByName("clip")
		local var_154_2 = var_154_0:getContentSize()

		var_154_1:removeAllChildren()

		local var_154_3 = arg_152_0:getNormalCard(xyd.SkinDynamicPosType.LIBRARY_SHOW, arg_152_2, arg_152_1)

		var_154_3:setScale(0.4)
		var_154_3:setAnchorPoint(0.5, 0.5)
		var_154_3:setPosition(var_154_2.width / 2, var_154_2.height / 2)
		var_154_1:addChild(var_154_3)
	end

	var_152_3()
	var_152_1:addTouchEventListener(function(arg_155_0, arg_155_1)
		if arg_155_1 == ccui.TouchEventType.ended then
			if arg_152_0.hero:isUnlockDynamicCard(arg_152_2) then
				arg_152_0.hero:changeDynamicCardState(arg_152_2, function()
					arg_152_0:updateHeroHomeCard(arg_152_2)
					var_152_3()
					var_152_4()
				end)
			else
				local var_155_0 = xyd.tables.skinDynamic:cost(arg_152_2)
				local var_155_1 = xyd.tables.skinDynamic:num(arg_152_2)

				if not var_155_0 or not var_155_1 then
					return
				end

				local var_155_2 = string.format(var_0_21:translation("DYNAMIC_SENTENCE"), var_155_0, var_155_1)

				if var_155_0 == 0 then
					var_155_2 = string.format(var_0_21:translation("DYNAMIC_SENTENCE1"), var_155_1)
				elseif var_155_1 == 0 then
					var_155_2 = string.format(var_0_21:translation("DYNAMIC_SENTENCE2"), var_155_0)
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_155_2
				}, function()
					local var_157_0 = xyd.tables.misc:getValue("dymisic_item")

					if arg_152_0.backpack:getItemNumByID(var_157_0) < var_155_1 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_21:translation("DYNAMIC_ITEM_TIP")
						})

						return
					end

					if arg_152_0.selfPlayer.crystal < var_155_0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_21:translation("STICK_BLESS_NO_CRYSTAL")
						})

						return
					end

					arg_152_0.hero:unlockDynamicCard(arg_152_2, function()
						arg_152_0:updateHeroHomeCard(arg_152_2)
						var_152_3()
						var_152_4()
						arg_152_0.backpack:removeItem({
							itemID = var_157_0,
							itemNum = var_155_1
						})
					end)
				end)
			end
		end
	end)
end

function var_0_7.updateSkinSkillContainer(arg_159_0)
	arg_159_0:nodeByName("skin_skill_icon"):removeAllChildren()

	local var_159_0 = arg_159_0:nodeByName("skin_skill_intro"):getContentSize()

	if not arg_159_0.skinSkillIntroList then
		arg_159_0.skinSkillIntroList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, var_159_0.width, var_159_0.height),
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_159_0:nodeByName("skin_skill_intro"))
	end

	arg_159_0.skinSkillIntroList:removeAllItems()

	local var_159_1 = 0

	if arg_159_0.skinSkillEquip > 0 then
		var_159_1 = arg_159_0.skinDatas[arg_159_0.skinSkillEquip].skinItem
	end

	local var_159_2 = var_0_25:getSkillID(var_159_1)
	local var_159_3 = {}
	local var_159_4 = arg_159_0.skinDatas

	if var_159_2 and var_159_2 > 0 then
		table.insert(var_159_3, {
			is_equip = true,
			item_id = var_159_1,
			skill_id = var_159_2,
			idx = arg_159_0.skinSkillEquip
		})
	end

	for iter_159_0, iter_159_1 in ipairs(var_159_4) do
		if iter_159_1.skinItem and (iter_159_1.isHave or iter_159_1.isHasTemp) and iter_159_1.skinItem ~= var_159_1 then
			local var_159_5 = var_0_25:getSkillID(iter_159_1.skinItem)

			if var_159_5 and var_159_5 > 0 then
				table.insert(var_159_3, {
					item_id = iter_159_1.skinItem,
					skill_id = var_159_5,
					idx = iter_159_0,
					isHasTemp = iter_159_1.isHasTemp
				})
			end
		end
	end

	if not var_159_2 or var_159_2 == 0 then
		arg_159_0:nodeByName("skin_skill_pos"):hide()
		arg_159_0:nodeByName("txt_skin_skill_null"):show()

		if next(var_159_3) then
			arg_159_0:nodeByName("txt_skin_skill_null"):setString(var_0_21:translation("AVARTAR_POSE_HAVENT_EQUIP"))
		else
			arg_159_0:nodeByName("txt_skin_skill_null"):setString(var_0_21:translation("AVARTAR_POSE_NOTOWN_EQUIP"))
		end
	else
		arg_159_0:nodeByName("skin_skill_pos"):show()
		arg_159_0:nodeByName("txt_skin_skill_null"):hide()
		xyd.setItemBorder(arg_159_0:nodeByName("skin_skill_icon"), var_159_1)
		arg_159_0:nodeByName("txt_skin_skill_name"):setString(var_0_20:name(var_159_1))

		local var_159_6 = arg_159_0.skinSkillIntroList:newItem()
		local var_159_7 = xyd.createLabel(18, cc.c3b(52, 54, 55))

		var_159_7:setWidth(var_159_0.width - 20)
		var_159_7:setLineHeight(24)
		var_159_7:setLineBreakWithoutSpace(true)
		var_159_7:setString(xyd.tables.skill:desc(var_159_2))
		var_159_6:addContent(var_159_7)
		var_159_6:setItemSize(var_159_0.width, var_159_7:getContentSize().height)
		arg_159_0.skinSkillIntroList:addItem(var_159_6)
		arg_159_0.skinSkillIntroList:reload()
	end

	local var_159_8 = xyd.db.skinSkillRedMark:getSkinSkillRedMark(arg_159_0.selfPlayer.playerID, arg_159_0.hero:getHeroID())

	if var_159_8 and var_159_8 ~= 0 then
		arg_159_0:nodeByName("skin_skill_red_point"):setVisible(true)
	else
		arg_159_0:nodeByName("skin_skill_red_point"):setVisible(false)
	end

	arg_159_0:nodeByName("skin_skill_icon"):addTouchEventListener(function(arg_160_0, arg_160_1)
		if arg_160_1 == ccui.TouchEventType.ended then
			if not next(var_159_3) then
				local var_160_0 = var_0_21:translation("AVARTAR_POSE_SKILL_UNFOUND")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_160_0
				})

				return
			end

			local function var_160_1(arg_161_0)
				arg_159_0.skinSkillEquip = arg_161_0

				arg_159_0:updateSkinSkillContainer()
			end

			local var_160_2 = {
				items = var_159_3,
				hero = arg_159_0.hero,
				callback = var_160_1
			}

			xyd.WindowManager.get():openWindow("skin_skill_select", var_160_2)

			if var_159_8 and var_159_8 ~= 0 then
				xyd.db.skinSkillRedMark:updateSkinSkillRedMark(arg_159_0.selfPlayer.playerID, arg_159_0.hero:getHeroID(), 0)
				arg_159_0:updateSkinSkillContainer()
			end
		end
	end)
end

function var_0_7.updateSkinModel(arg_162_0)
	if not arg_162_0.cache[var_0_33.Skin] then
		return
	end

	local var_162_0 = arg_162_0:nodeByName("skin_model_container")
	local var_162_1 = arg_162_0.skinDatas[arg_162_0.skinSelect]
	local var_162_2 = xyd.tables.model:uiScale(var_162_1.modelID) * 0.5

	arg_162_0.heroSkinModel_ = xyd.HeroAnimation.new(arg_162_0.hero:getTableID(), var_162_1.modelID, var_162_2, {})

	arg_162_0.heroSkinModel_:idle()

	arg_162_0.modelState = xyd.ModelState.Walk

	local var_162_3 = var_162_0:getContentSize().width / 2

	arg_162_0.heroSkinModel_:setPosition(cc.p(var_162_3, 0))
	var_162_0:removeAllChildren()
	arg_162_0.heroSkinModel_:addTo(var_162_0)

	if arg_162_0.hero:getTableID() == 11005 then
		arg_162_0.heroSkinModel_:setPosition(cc.p(var_162_3 - 50, 0))
	end

	arg_162_0.isShow = false

	var_162_0:addTouchEventListener(function(arg_163_0, arg_163_1)
		if arg_163_1 == ccui.TouchEventType.ended and not arg_162_0.isShow then
			arg_162_0:resetSkinModelState()
		end
	end)
	arg_162_0:nodeByName("skin_avatar"):removeAllChildren()

	local var_162_4 = arg_162_0:nodeByName("skin_avatar"):getContentSize()
	local var_162_5 = xyd.tables.model:avatar(var_162_1.modelID)
	local var_162_6 = display.newClippingRectangleNode(cc.rect(0, 0, var_162_4.width - 4, var_162_4.height - 4))
	local var_162_7 = xyd.SpriteLoader.new(var_162_5, nil, nil, xyd.DefaultImageType.SKILL_ICON)
	local var_162_8 = xyd.getAvatarBorderNewUI(1)

	var_162_7 = var_162_7 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	var_162_6:addTo(arg_162_0:nodeByName("skin_avatar"))
	var_162_6:pos(2, 2)
	var_162_7:addTo(var_162_6)
	var_162_7:setScale(var_162_4.width / var_162_7:getWidth())
	var_162_7:align(display.CENTER, var_162_4.width / 2, var_162_4.height / 2)
	xyd.displaySpriteOnContainer(var_162_8, arg_162_0:nodeByName("skin_avatar"), true)
end

function var_0_7.getNormalCard(arg_164_0, arg_164_1, arg_164_2, arg_164_3)
	local var_164_0

	if arg_164_2 and xyd.isShowDynamicCard(arg_164_0.hero, arg_164_1) then
		local var_164_1 = var_0_24:path(arg_164_1)
		local var_164_2 = var_0_24:oldSmallCardScale(arg_164_1)
		local var_164_3 = var_0_24:pos(arg_164_1, xyd.SkinDynamicPosType.PERSON_DISPLAY)

		var_164_0 = xyd.EffectLoader.new(var_164_1, 1, var_164_2, var_164_3)

		var_164_0:setPosition(0, arg_164_3.height - 225)
	else
		var_164_0 = xyd.SpriteLoader.new(xyd.tables.model:smallCard(arg_164_1), nil, nil, xyd.DefaultImageType.SMALL_CARD)

		var_164_0:setAnchorPoint(0, 1)
		var_164_0:setPosition(0, arg_164_3.height)
	end

	return var_164_0
end

function var_0_7.getSkinDatas(arg_165_0)
	local var_165_0 = arg_165_0.hero:getSkinDatas()
	local var_165_1 = var_0_28:getItems()

	for iter_165_0, iter_165_1 in ipairs(var_165_0) do
		if iter_165_1.skinItem then
			local var_165_2 = arg_165_0.hero.timeLimitSkins
			local var_165_3
			local var_165_4 = false

			for iter_165_2, iter_165_3 in pairs(var_165_2) do
				if tonumber(iter_165_2) == var_0_20:skinModel(iter_165_1.skinItem) and iter_165_3 > 0 then
					var_165_4 = true
					var_165_3 = iter_165_3
				end
			end

			for iter_165_4, iter_165_5 in ipairs(var_165_1) do
				if iter_165_5 == iter_165_1.skinItem then
					iter_165_1.shopIndex = iter_165_4

					break
				end
			end

			iter_165_1.isHasTemp = var_165_4
			iter_165_1.timeStamp = var_165_3
		end
	end

	return var_165_0
end

function var_0_7.createSkinItem(arg_166_0, arg_166_1, arg_166_2)
	local var_166_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/skin_item.csb")
	local var_166_1 = var_166_0:getChildByName("container")
	local var_166_2 = var_166_1:getContentSize()

	var_166_0:setContentSize(var_166_2)
	table.insert(arg_166_0.skinItemContainer, var_166_1)

	local var_166_3 = var_166_1:getChildByName("card"):getContentSize()
	local var_166_4 = arg_166_0:getNormalCard(arg_166_2.modelID, arg_166_2.isHave, var_166_3)
	local var_166_5 = cc.ClippingNode:create()
	local var_166_6 = display.newScale9Sprite("images/line_mask.png", 0, 0, var_166_3)

	var_166_6:setAnchorPoint(0, 0)
	var_166_5:setStencil(var_166_6)
	var_166_1:getChildByName("card"):addChild(var_166_5)
	var_166_5:addChild(var_166_4)
	var_166_5:setName("clip")

	if arg_166_2.isAwaken then
		var_166_1:getChildByName("txt_type"):setString(var_0_21:translation("AVARTAR_STATE_BREAKUP"))
		var_166_1:getChildByName("txt_name"):setString(var_0_21:translation("AWAKEN_TEXT"))
	elseif arg_166_2.skinItem then
		if arg_166_2.isHasTemp and not arg_166_2.isHave then
			var_166_1:getChildByName("bg_skin_time"):setVisible(true)
		end

		if arg_166_2.shopIndex then
			var_166_1:getChildByName("txt_type"):setString(var_0_21:translation("AVARTAR_STATE_MALL"))
		else
			var_166_1:getChildByName("txt_type"):setString(var_0_21:translation("AVARTAR_STATE_ACTIVE"))
		end

		var_166_1:getChildByName("txt_name"):setString(var_0_20:name(arg_166_2.skinItem))
	else
		var_166_1:getChildByName("txt_type"):setString(var_0_21:translation("AVARTAR_STATE_NOMAL"))
		var_166_1:getChildByName("txt_name"):setString(var_0_21:translation("NORMAL_TEXT"))
	end

	if not arg_166_2.isHave and not arg_166_2.isHasTemp then
		arg_166_0:GrayNode(var_166_1)
		var_166_1:getChildByName("txt_name"):setColor(cc.c3b(125, 125, 125))

		if arg_166_0.selfPlayer:getBackpack():getItemNumByID(arg_166_2.skinItem) > 0 then
			var_166_0:getChildByName("red_point"):show()
		end

		if arg_166_2.skinItem then
			local var_166_7 = arg_166_0.hero:getTempSkinItemId(arg_166_2.skinItem)

			if arg_166_0.selfPlayer:getBackpack():getItemNumByID(var_166_7) > 0 then
				var_166_0:getChildByName("red_point"):show()
			end
		end
	end

	var_166_1:getChildByName("bg_skin_item"):setVisible(arg_166_0.skinSelect ~= arg_166_1)
	var_166_1:getChildByName("bg_skin_item2"):setVisible(arg_166_0.skinSelect == arg_166_1)
	var_166_1:getChildByName("select"):setVisible(arg_166_0.skinSelect == arg_166_1)
	var_166_1:getChildByName("bg_item_top"):setVisible(arg_166_0.skinSelect ~= arg_166_1)
	var_166_1:getChildByName("bg_item_top2"):setVisible(arg_166_0.skinSelect == arg_166_1)
	var_166_1:getChildByName("bg_skill"):getChildByName("txt_skill"):setString(var_0_21:translation("AVARTAR_MALL_SKILL"))
	var_166_1:getChildByName("bg_skin_time"):getChildByName("txt_time"):setString(var_0_21:translation("AVARTAR_POSE_TIME_LIMIT"))
	var_166_1:getChildByName("bg_skill"):setVisible(arg_166_2.skinSkillID and arg_166_2.skinSkillID > 0)
	var_166_1:getChildByName("bg_select"):setVisible(arg_166_0.skinSelect == arg_166_1)

	local function var_166_8(arg_167_0)
		if arg_166_0.scrollViewMoved_ then
			return
		end

		if arg_166_0.skinSelect == arg_167_0 then
			return
		end

		if arg_166_0.skinIllusionEquip == arg_167_0 then
			arg_166_0.isTrySkin = false
			arg_166_0.trySkinModelID = nil
		else
			arg_166_0.isTrySkin = true
			arg_166_0.trySkinModelID = arg_166_0.skinDatas[arg_167_0].modelID
		end

		local var_167_0 = arg_166_0.skinItemContainer[arg_166_0.skinSelect]
		local var_167_1 = arg_166_0.skinItemContainer[arg_167_0]

		arg_166_0.skinSelect = arg_167_0

		var_167_0:getChildByName("bg_skin_item"):show()
		var_167_0:getChildByName("bg_skin_item2"):hide()
		var_167_0:getChildByName("select"):hide()
		var_167_0:getChildByName("bg_item_top"):show()
		var_167_0:getChildByName("bg_item_top2"):hide()
		var_167_1:getChildByName("bg_skin_item"):hide()
		var_167_1:getChildByName("bg_skin_item2"):show()
		var_167_1:getChildByName("select"):show()
		var_167_1:getChildByName("bg_item_top"):hide()
		var_167_1:getChildByName("bg_item_top2"):show()
		arg_166_0:updateBtnSkinBtnShow(arg_166_2.isHave, arg_166_2.modelID)
		arg_166_0:updateHeroHomeCard(arg_166_0.trySkinModelID)
		arg_166_0:updateSkinModel()
		arg_166_0:updateSkinBtn(arg_167_0)
		arg_166_0:updateSkinTime(arg_167_0)
	end

	var_166_1:addTouchEventListener(function(arg_168_0, arg_168_1)
		if arg_168_1 == ccui.TouchEventType.ended then
			var_166_8(arg_166_1)
		end
	end)

	return var_166_0
end

function var_0_7.updateSkinTime(arg_169_0, arg_169_1)
	local var_169_0 = arg_169_0.skinDatas[arg_169_1]

	if var_169_0.isHasTemp and not var_169_0.isHave then
		local var_169_1 = arg_169_0:nodeByName("text_skin_last_time")

		arg_169_0:nodeByName("txt_skin_time"):setVisible(true)
		var_169_1:setVisible(true)
		var_169_1:setString(xyd.timeFormatAsHMS(var_169_0.timeStamp - xyd.ServerTime.get():getServerTime()))

		var_169_1.timeStamp = var_169_0.timeStamp

		arg_169_0:updateSkinItemSchedule(var_169_1)
	else
		arg_169_0:nodeByName("text_skin_last_time"):setVisible(false)
		arg_169_0:nodeByName("txt_skin_time"):setVisible(false)
	end
end

function var_0_7.updateSkinBtn(arg_170_0, arg_170_1)
	local var_170_0 = arg_170_0.skinDatas[arg_170_1]
	local var_170_1 = arg_170_0:nodeByName("btn_skin2")

	if arg_170_1 == arg_170_0.skinIllusionEquip then
		var_170_1:hide()
		arg_170_0:nodeByName("txt_skin_is_equipping"):show()

		return
	else
		var_170_1:show()
		arg_170_0:nodeByName("txt_skin_is_equipping"):hide()

		if var_170_0.cardState == xyd.CardStatus.AWAKE_CARD and not var_170_0.isHave then
			var_170_1:getChildByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_BREAKUP"))
			var_170_1:setTouchEnabled(false)
			var_170_1:setBright(false)
		elseif var_170_0.cardState == xyd.CardStatus.SKIN_CARD then
			local var_170_2 = arg_170_0.hero:getTempSkinItemId(var_170_0.skinItem)
			local var_170_3

			if var_170_0.isHave or var_170_0.isHasTemp then
				var_170_1:setTouchEnabled(true)
				var_170_1:setBright(true)

				if var_170_0.isHave then
					var_170_3 = var_170_0.skinItem
				elseif var_170_0.isHasTemp then
					var_170_3 = var_170_2
				end

				var_170_1:setBright(true)
				var_170_1:setTouchEnabled(true)
				var_170_1:getChildByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_APPLY"))
				var_170_1:addTouchEventListener(function(arg_171_0, arg_171_1)
					xyd.buttonScaleAnim(arg_171_0, arg_171_1)

					if arg_171_1 == ccui.TouchEventType.ended then
						local var_171_0 = {
							partner_id = arg_170_0.hero:getHeroID(),
							item_id = var_170_3
						}

						xyd.Backend.get():request(xyd.mid.USE_ILLUSION_SKIN_ITEM, var_171_0, function(arg_172_0, arg_172_1)
							if arg_172_0 == xyd.error.OK then
								arg_170_0.hero.illusionSkinId_ = arg_172_1.illusion_skin_id

								arg_170_0:changeIllusionSkin(arg_170_1)

								if xyd.WindowManager.get():getWindow("hero_list") then
									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.HERO_LIST_REFRESH
									})
								end
							end
						end)
					end
				end)
			elseif arg_170_0.selfPlayer:getBackpack():getItemNumByID(var_170_0.skinItem) > 0 or arg_170_0.selfPlayer:getBackpack():getItemNumByID(var_170_2) > 0 then
				if arg_170_0.selfPlayer:getBackpack():getItemNumByID(var_170_0.skinItem) > 0 then
					var_170_3 = var_170_0.skinItem
				elseif arg_170_0.selfPlayer:getBackpack():getItemNumByID(var_170_2) > 0 then
					var_170_3 = var_170_2
				end

				var_170_1:setBright(true)
				var_170_1:setTouchEnabled(true)
				var_170_1:getChildByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_ACTIVATION"))
				var_170_1:addTouchEventListener(function(arg_173_0, arg_173_1)
					xyd.buttonScaleAnim(arg_173_0, arg_173_1)

					if arg_173_1 == ccui.TouchEventType.ended then
						local var_173_0 = {
							partner_id = arg_170_0.hero:getHeroID(),
							item_id = var_170_3
						}

						xyd.Backend.get():request(xyd.mid.SKIN_ON, var_173_0, function(arg_174_0, arg_174_1)
							if arg_174_0 == xyd.error.OK then
								arg_170_0.hero:setSkinInfo(arg_170_0.hero.skinId_, arg_174_1.skin_ids)

								if arg_174_1.remove_item == 1 then
									local var_174_0 = {
										itemID = var_170_3
									}

									var_174_0.itemNum = 1

									arg_170_0.selfPlayer:getBackpack():removeItem(var_174_0)

									local var_174_1 = var_0_25:getSkillID(var_170_0.skinItem)

									if var_174_1 and var_174_1 > 0 then
										xyd.db.skinSkillRedMark:updateSkinSkillRedMark(arg_170_0.selfPlayer.playerID, arg_170_0.hero:getHeroID(), 1)
									end
								end

								local var_174_2 = arg_170_0.skinItemContainer[arg_170_0.skinSelect]

								var_174_2:getParent():getChildByName("red_point"):setVisible(false)
								arg_170_0:unGrayNode(var_174_2)

								arg_170_0.skinDatas = arg_170_0:getSkinDatas()

								arg_170_0:updateSkinBtn(arg_170_0.skinSelect)
								arg_170_0:updateSkinSkillContainer()
							end
						end)
					end
				end)
			elseif var_170_0.shopIndex then
				var_170_1:getChildByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_PAY"))
				var_170_1:setTouchEnabled(true)
				var_170_1:setBright(true)
				var_170_1:addTouchEventListener(function(arg_175_0, arg_175_1)
					xyd.buttonScaleAnim(arg_175_0, arg_175_1)

					if arg_175_1 == ccui.TouchEventType.ended then
						if not arg_170_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_SHOP) then
							local var_175_0 = xyd.tables.functionOpen
							local var_175_1 = xyd.tables.campaign
							local var_175_2 = "NUM_" .. var_175_1:chapter(var_175_0:stage(xyd.FunctionID.ID_SHOP))
							local var_175_3 = string.format(var_0_21:translation("FUNCTION_OPEN_TIP_STAGE"), var_0_21:translation(var_175_2))

							xyd.WindowManager.get():openWindow("toast", {
								message = var_175_3
							})

							return
						end

						local var_175_4 = xyd.FunctionID.ID_SKIN_SHOP

						if arg_170_0.selfPlayer:isFuncOpen(var_175_4) == false then
							local var_175_5 = xyd.tables.functionOpen:level(var_175_4)
							local var_175_6 = string.format(var_0_21:translation("FUNCTION_OPEN_TIP_LEVEL"), var_175_5)

							xyd.WindowManager.get():openWindow("toast", {
								message = var_175_6
							})

							return
						end

						xyd.WindowManager.get():openWindow("skin_shop_detail_window", {
							id = var_170_0.shopIndex
						})
					end
				end)
			else
				var_170_1:getChildByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_CHANEL_ACTIVITY"))
				var_170_1:setTouchEnabled(false)
				var_170_1:setBright(false)
			end
		else
			var_170_1:getChildByName("txt_btn_skin2"):setString(var_0_21:translation("AVARTAR_POSE_APPLY"))
			var_170_1:setTouchEnabled(true)
			var_170_1:setBright(true)

			local var_170_4
			local var_170_5 = var_170_0.cardState == xyd.CardStatus.AWAKE_CARD and 1 or 0

			var_170_1:addTouchEventListener(function(arg_176_0, arg_176_1)
				xyd.buttonScaleAnim(arg_176_0, arg_176_1)

				if arg_176_1 == ccui.TouchEventType.ended then
					local var_176_0 = {
						partner_id = arg_170_0.hero:getHeroID(),
						item_id = var_170_5
					}

					xyd.Backend.get():request(xyd.mid.USE_ILLUSION_SKIN_ITEM, var_176_0, function(arg_177_0, arg_177_1)
						if arg_177_0 == xyd.error.OK then
							arg_170_0.hero.illusionSkinId_ = arg_177_1.illusion_skin_id

							arg_170_0:changeIllusionSkin(arg_170_1)

							if xyd.WindowManager.get():getWindow("hero_list") then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.HERO_LIST_REFRESH
								})
							end
						end
					end)
				end
			end)
		end
	end
end

function var_0_7.changeIllusionSkin(arg_178_0, arg_178_1)
	arg_178_0.trySkinModelID = 0
	arg_178_0.isTrySkin = false

	arg_178_0.skinItemContainer[arg_178_0.skinIllusionEquip]:getChildByName("bg_select"):setVisible(false)
	arg_178_0.skinItemContainer[arg_178_1]:getChildByName("bg_select"):setVisible(true)

	arg_178_0.skinIllusionEquip = arg_178_1
	arg_178_0.frontState = nil

	if arg_178_0.heroModel_ then
		arg_178_0.heroModel_:removeSelf()

		arg_178_0.heroModel_ = nil
	end

	arg_178_0:updateSkinBtn(arg_178_1)
	arg_178_0:updateCard()
	arg_178_0:updateHeroModel(arg_178_0.hero)
end

function var_0_7.GrayNode(arg_179_0, arg_179_1, arg_179_2)
	if not arg_179_2 then
		local var_179_0 = cc.GLProgram:createWithByteArrays(xyd.shader.NO_MVP_VERT_STRING, xyd.shader.GRAY_FRAG_STRING)

		arg_179_2 = cc.GLProgramState:create(var_179_0)
	end

	arg_179_1:setGLProgramState(arg_179_2)

	for iter_179_0, iter_179_1 in pairs(arg_179_1:getChildren()) do
		arg_179_0:GrayNode(iter_179_1, arg_179_2)
	end
end

function var_0_7.unGrayNode(arg_180_0, arg_180_1, arg_180_2)
	if not arg_180_2 then
		local var_180_0 = cc.GLProgram:createWithByteArrays(xyd.shader.NO_MVP_VERT_STRING, xyd.shader.NO_MVP_FRAG_STRING)

		arg_180_2 = cc.GLProgramState:create(var_180_0)
	end

	arg_180_1:setGLProgramState(arg_180_2)

	for iter_180_0, iter_180_1 in pairs(arg_180_1:getChildren()) do
		arg_180_0:GrayNode(iter_180_1, arg_180_2)
	end
end

function var_0_7.getFilteredSkinItemIds(arg_181_0)
	local var_181_0 = {}
	local var_181_1 = xyd.tables.hero:skinItem(arg_181_0.hero:getTableID())
	local var_181_2 = xyd.tables.hero:skinHide(arg_181_0.hero:getTableID())
	local var_181_3 = arg_181_0.hero.skinIds_

	for iter_181_0, iter_181_1 in pairs(var_181_1) do
		if var_0_20:skinLastTime(iter_181_1) == 0 then
			local var_181_4 = xyd.tables.item:skinModel(iter_181_1)

			if xyd.isInTable(var_181_3, var_181_4) or not xyd.isInTable(var_181_2, iter_181_1) then
				table.insert(var_181_0, iter_181_1)
			end
		end
	end

	return var_181_0
end

function var_0_7.updateBookContainer(arg_182_0)
	if not arg_182_0.cache[var_0_33.Book] then
		return
	end

	if tolua.isnull(arg_182_0.containers[var_0_11]) then
		return
	end

	local var_182_0 = arg_182_0.hero
	local var_182_1 = arg_182_0.hero:getTableID()

	if var_182_0:isAwaken() then
		var_182_1 = xyd.tables.hero:beforeAwaken(arg_182_0.hero:getTableID())
	end

	if arg_182_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ACT_CENTRE) == nil or arg_182_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ACT_CENTRE) == false then
		return
	end

	xyd.tables.cabinetSkillTable:partnerSkills(var_182_1)

	if #xyd.tables.cabinetSkillTable:partnerSkills(var_182_1) == 0 then
		if arg_182_0.state == var_0_11 then
			arg_182_0:clickHeroDetailButton()
		end

		return
	end

	local var_182_2 = {}
	local var_182_3 = {}

	for iter_182_0, iter_182_1 in pairs(xyd.tables.cabinetSkillTable:partnerSkills(var_182_1)) do
		local var_182_4 = xyd.tables.cabinetSkillTable:skillbook(iter_182_1)

		if xyd.tables.cabinetBookTable:isHide(var_182_4) ~= 1 then
			if var_182_2[var_182_4] == nil then
				var_182_2[var_182_4] = {}
				var_182_2[var_182_4].skills = {}
				var_182_2[var_182_4].num = 0
				var_182_2[var_182_4].totalNum = 0
				var_182_2[var_182_4].star = xyd.tables.cabinetBookTable:star(var_182_4)
				var_182_2[var_182_4].id = var_182_4
				var_182_2[var_182_4].type = xyd.tables.cabinetBookTable:type(var_182_4)
			end

			local var_182_5 = {
				id = iter_182_1
			}

			var_182_5.lev = 0

			if var_182_0:skillBook()[tostring(iter_182_1)] then
				var_182_5.lev = var_182_0:skillBook()[tostring(iter_182_1)]
				var_182_2[var_182_4].num = var_182_2[var_182_4].num + var_182_5.lev
			end

			table.insert(var_182_2[var_182_4].skills, var_182_5)

			var_182_2[var_182_4].totalNum = var_182_2[var_182_4].totalNum + xyd.tables.cabinetBookTable:star(var_182_4)
		end
	end

	for iter_182_2, iter_182_3 in pairs(var_182_2) do
		if arg_182_0.selfPlayer:getBackpack():getItemNumByID(iter_182_2) <= 0 then
			table.insert(var_182_3, iter_182_3)

			var_182_2[iter_182_2] = nil
		end
	end

	if not arg_182_0.bookList then
		local var_182_6 = arg_182_0.containers[var_0_11]:getChildByName("book_scroll")

		var_182_6:removeAllChildren()

		arg_182_0.bookList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 500, 575),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(var_182_6):onScroll(handler(arg_182_0, arg_182_0.scrollListener))
	else
		arg_182_0.bookList:removeAllItems()
	end

	local var_182_7 = 0
	local var_182_8 = true
	local var_182_9 = true

	local function var_182_10(arg_183_0)
		local var_183_0 = arg_182_0.bookList:newItem()
		local var_183_1 = display.newNode()

		var_183_1:setAnchorPoint(cc.p(0, 1))

		local var_183_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/book/book_title.csb")

		var_183_2:getChildByName("container"):getChildByName(arg_183_0):setVisible(false)
		var_183_2:getChildByName("container"):getChildByName("title_has"):setString(var_0_21:translation("HERO_MAIN_TEXT_25"))
		var_183_2:getChildByName("container"):getChildByName("title_not_has"):setString(var_0_21:translation("HERO_MAIN_TEXT_26"))

		local var_183_3 = var_183_2:getChildByName("container"):getWidth()
		local var_183_4 = var_183_2:getChildByName("container"):getHeight()

		var_183_2:ignoreAnchorPointForPosition(false)
		var_183_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_183_2:setTouchEnabled(true)
		var_183_2:setTouchSwallowEnabled(false)
		var_183_1:addChild(var_183_2)
		var_183_0:addContent(var_183_1)
		var_183_1:setContentSize(cc.size(var_183_3, var_183_4))
		var_183_0:setItemSize(var_183_3, var_183_4 + 15)
		arg_182_0.bookList:addItem(var_183_0)

		var_182_8 = false
	end

	local function var_182_11(arg_184_0, arg_184_1, arg_184_2)
		local var_184_0 = arg_182_0.bookList:newItem()
		local var_184_1 = display.newNode()

		var_184_1:setAnchorPoint(cc.p(0, 1))

		local var_184_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/book/book_item.csb")
		local var_184_3 = var_184_2:getChildByName("container"):getWidth()
		local var_184_4 = var_184_2:getChildByName("container"):getHeight()

		var_184_2:ignoreAnchorPointForPosition(false)
		var_184_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_184_2:setTouchEnabled(true)
		var_184_2:setTouchSwallowEnabled(false)
		var_184_1:addChild(var_184_2)
		var_184_0:addContent(var_184_1)
		var_184_1:setContentSize(cc.size(var_184_3, var_184_4))
		var_184_0:setItemSize(var_184_3, var_184_4 + 10)
		arg_182_0.bookList:addItem(var_184_0)

		local var_184_5 = var_184_2:getChildByName("container")

		var_184_5:getChildByName("skills_words"):setString(var_0_21:translation("SKILL_TOTAL"))

		for iter_184_0 = 1, 6 do
			if iter_184_0 > xyd.tables.cabinetBookTable:star(arg_184_2.id) then
				var_184_5:getChildByName("stars"):getChildByName("star" .. iter_184_0):setVisible(false)
			elseif iter_184_0 == xyd.tables.cabinetBookTable:star(arg_184_2.id) then
				var_184_5:getChildByName("stars"):setPositionX(var_184_5:getChildByName("stars"):getPositionX() - (iter_184_0 - 1) * 8)
			end
		end

		var_184_5:getChildByName("book_name"):setString(xyd.tables.cabinetBookTable:name(arg_184_2.id))
		xyd.setItemBorder(var_184_5:getChildByName("border"), arg_184_2.id)
		var_184_5:getChildByName("skills_text"):setString(arg_184_2.num .. "/" .. arg_184_2.totalNum)

		if arg_184_1 then
			var_184_5:getChildByName("bar_container"):setVisible(false)

			for iter_184_1, iter_184_2 in pairs(arg_184_2.skills) do
				local var_184_6 = display.newNode()

				var_184_6:setContentSize(44, 44)
				var_184_6:setAnchorPoint(0.5, 0.5)

				if iter_184_2.lev > 0 then
					xyd.setSpriteBorder(var_184_6, xyd.tables.cabinetSkillTable:icon(iter_184_2.id), 1)
				else
					xyd.setSpriteBorder(var_184_6, xyd.tables.cabinetSkillTable:icon(iter_184_2.id), 1, true)
				end

				var_184_6:addTo(var_184_5:getChildByName("skill_node" .. iter_184_1))
				var_184_6:setPosition(0, 0)
				var_184_6:setTouchEnabled(true)
				var_184_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_185_0)
					if arg_185_0.name == "began" then
						local var_185_0 = {
							id = iter_184_2.id,
							lev = iter_184_2.lev
						}

						xyd.WindowManager.get():openWindow("book_skill_tip", var_185_0):setPosition(arg_185_0.x - 450, arg_185_0.y - 80)
					elseif arg_185_0.name == "ended" or arg_185_0.name == "canceled" then
						xyd.WindowManager.get():closeWindow("book_skill_tip")
					end

					return true
				end)
			end

			var_184_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_186_0)
				if arg_186_0.name == "ended" and not arg_182_0.scrollViewMoved_ then
					local var_186_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

					var_186_0:getBuildingList({}, function(arg_187_0)
						if arg_187_0 == xyd.error.OK then
							var_186_0:getCabinetInfo(function(arg_188_0, arg_188_1)
								if arg_188_0 == xyd.error.OK then
									local var_188_0 = {
										id = arg_184_2.id
									}

									if arg_184_2.num == arg_184_2.totalNum and arg_184_2.type == 1 then
										var_188_0.bookType = 3
									elseif arg_184_2.type == 1 then
										var_188_0.bookType = 1
									else
										var_188_0.bookType = 0
									end

									xyd.WindowManager.get():openWindow("junk_chest", var_188_0)
								end
							end)
						end
					end)
				end

				return true
			end)
		else
			var_184_5:getChildByName("skills_words"):setVisible(false)
			var_184_5:getChildByName("skills_text"):setVisible(false)

			if arg_184_2.type ~= 2 then
				local var_184_7 = arg_182_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.cabinetBookTable:piece(arg_184_2.id))
				local var_184_8 = xyd.tables.item:itemNum(xyd.tables.cabinetBookTable:piece(arg_184_2.id))

				var_184_5:getChildByName("bar_container"):getChildByName("bar_text"):setString(var_184_7 .. "/" .. var_184_8)
				var_184_5:getChildByName("bar_container"):getChildByName("bar_text"):enableOutline(cc.c4b(0, 0, 0, 255), 2)

				if var_184_8 < var_184_7 then
					var_184_5:getChildByName("bar_container"):getChildByName("loading_bar"):setPercent(100)
				else
					var_184_5:getChildByName("bar_container"):getChildByName("loading_bar"):setPercent(var_184_7 / var_184_8 * 100)
				end

				var_184_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_189_0)
					if arg_189_0.name == "ended" then
						local var_189_0 = {
							id = xyd.tables.cabinetBookTable:piece(arg_184_2.id)
						}

						xyd.WindowManager.get():openWindow("book_gain", var_189_0)
					end

					return true
				end)
			else
				var_184_5:getChildByName("bar_container"):setVisible(false)
			end
		end
	end

	for iter_182_4, iter_182_5 in pairs(var_182_2) do
		if var_182_8 then
			var_182_10("title_not_has")

			var_182_8 = false
		end

		var_182_7 = var_182_7 + 1

		var_182_11(var_182_7, true, iter_182_5)
	end

	for iter_182_6, iter_182_7 in pairs(var_182_3) do
		if var_182_9 then
			var_182_10("title_has")

			var_182_9 = false
		end

		var_182_7 = var_182_7 + 1

		var_182_11(var_182_7, false, iter_182_7)
	end

	arg_182_0.bookList:reload()
end

function var_0_7.scrollListener(arg_190_0, arg_190_1)
	if arg_190_1.name == "began" then
		arg_190_0.scrollViewMoved_ = false
		arg_190_0.prevY_ = arg_190_1.y
	elseif arg_190_1.name == "moved" and 20 <= math.abs(arg_190_1.y - arg_190_0.prevY_) then
		arg_190_0.scrollViewMoved_ = true
	end
end

function var_0_7.getEvoProgress(arg_191_0)
	local var_191_0 = arg_191_0.hero:getEvoStage()
	local var_191_1 = arg_191_0.hero:getEvoAttrPoints()
	local var_191_2 = var_0_23:limitNum(var_191_0) * #var_0_23:attrs(var_191_0)
	local var_191_3 = 0

	for iter_191_0, iter_191_1 in pairs(var_191_1) do
		var_191_3 = var_191_3 + iter_191_1
	end

	arg_191_0.giftPush:cleanSceneCondition(35)
	arg_191_0.giftPush:setSceneCondition(35, (var_191_3 + arg_191_0.usedStoneNum) * 1 / var_191_2)

	return (var_191_3 + arg_191_0.usedStoneNum) * 1 / var_191_2
end

function var_0_7.updateBreachContainer(arg_192_0, arg_192_1)
	local var_192_0 = arg_192_0.breachContainer:getChildByName("breach_scroll")
	local var_192_1 = arg_192_0.hero:getEvoStage()
	local var_192_2 = var_0_23:attrs(var_192_1)

	if not arg_192_0.breachList or tolua.isnull(arg_192_0.breachList) then
		arg_192_0.breachList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 498, 405),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(var_192_0):onScroll(handler(arg_192_0, arg_192_0.scrollListener))
	else
		arg_192_0.breachList:removeAllItems()
	end

	for iter_192_0 = 1, #var_192_2 do
		local var_192_3 = arg_192_0.breachList:newItem()
		local var_192_4 = arg_192_0:createBreachItem(iter_192_0)

		var_192_3:addContent(var_192_4)
		var_192_3:setItemSize(var_192_4:getWidth(), var_192_4:getHeight() - 3)
		arg_192_0.breachList:addItem(var_192_3)
	end

	arg_192_0.breachList:reload()
	arg_192_0:nodeByName("breach_progress_txt"):setString(tostring(arg_192_0:getEvoProgress() * 100) .. "%")

	if arg_192_0:getEvoProgress() >= 1 and var_192_1 < var_0_23:getMaxStage() then
		arg_192_0:nodeByName("breach_btn"):setVisible(true)
	else
		arg_192_0:nodeByName("breach_btn"):setVisible(false)
	end

	if arg_192_1 then
		arg_192_0:nodeByName("stone_num_text"):enableOutline(cc.c4b(255, 255, 255, 188), 2)
		arg_192_0:nodeByName("stone_num_txt"):enableOutline(cc.c4b(255, 255, 255, 188), 2)
	end

	arg_192_0:playRepeatingEffect()
	arg_192_0:updateBreachStoneType()
end

function var_0_7.updateBreachStoneType(arg_193_0)
	local var_193_0 = xyd.tables.misc.stoneTicketLow
	local var_193_1 = xyd.tables.misc.stoneTicketHigh
	local var_193_2 = {
		arg_193_0:nodeByName("paper_origin"),
		arg_193_0:nodeByName("paper_normal"),
		arg_193_0:nodeByName("paper_super")
	}
	local var_193_3 = {
		arg_193_0:nodeByName("paper_origin_gray"),
		arg_193_0:nodeByName("paper_normal_gray"),
		arg_193_0:nodeByName("paper_super_gray")
	}
	local var_193_4 = xyd.tables.hero:stoneTicket(arg_193_0.hero:getTableID())
	local var_193_5 = xyd.tables.stoneTicket:stoneTicketItems(var_193_4)

	if not xyd.isInTable(var_193_5, var_193_0) then
		var_193_2[var_0_31.Normal]:setVisible(false)
		xyd.GrayNode(var_193_3[var_0_31.Normal])

		if arg_193_0.useStoneType == var_0_31.Normal then
			arg_193_0.useStoneType = var_0_31.Origin
		end
	else
		var_193_2[var_0_31.Normal]:setVisible(true)
	end

	if not xyd.isInTable(var_193_5, var_193_1) then
		var_193_2[var_0_31.Super]:setVisible(false)
		xyd.GrayNode(var_193_3[var_0_31.Super])

		if arg_193_0.useStoneType == var_0_31.Super then
			arg_193_0.useStoneType = var_0_31.Origin
		end
	else
		var_193_2[var_0_31.Super]:setVisible(true)
	end

	local var_193_6 = arg_193_0:getUseStoneId()
	local var_193_7 = arg_193_0.backpack:getItemNumByID(var_193_6)

	arg_193_0:nodeByName("stone_num_text"):setString(xyd.tables.item:name(var_193_6) .. ":")

	if arg_193_0.useStoneType == var_0_31.Origin then
		arg_193_0:nodeByName("stone_num_text"):setString(var_0_21:translation("STONE_NUMS_TEXT") .. ":")
	end

	arg_193_0:nodeByName("stone_num_txt"):setString(var_193_7)
	arg_193_0:nodeByName("select"):setPositionX(var_193_2[arg_193_0.useStoneType]:getPositionX() + 10)
end

function var_0_7.getUseStoneId(arg_194_0)
	if arg_194_0.useStoneType == var_0_31.Origin then
		local var_194_0 = arg_194_0.hero

		return (xyd.tables.hero:stoneID(var_194_0:getTableID()))
	elseif arg_194_0.useStoneType == var_0_31.Normal then
		return xyd.tables.misc.stoneTicketLow
	elseif arg_194_0.useStoneType == var_0_31.Super then
		return xyd.tables.misc.stoneTicketHigh
	end
end

function var_0_7.createBreachItem(arg_195_0, arg_195_1)
	local var_195_0 = display.newNode()
	local var_195_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/breach/breach_item.csb")
	local var_195_2 = var_195_1:getChildByName("container")
	local var_195_3 = arg_195_0.hero:getEvoStage()
	local var_195_4 = var_0_23:limitNum(var_195_3)
	local var_195_5 = var_0_23:attrs(var_195_3)
	local var_195_6 = arg_195_0.hero:getEvoAttrPoints()[tostring(var_195_5[arg_195_1])] or 0

	var_195_2:getChildByName("attr_name_txt"):setString(xyd.tables.attr:name(var_195_5[arg_195_1]) .. "：")
	arg_195_0:updateStoneProgress(arg_195_1, var_195_2)

	local var_195_7 = var_195_2:getChildByName("add_container")
	local var_195_8 = cc.ui.UIPushButton.new({
		pressed = "windows/hero/btn_plus.png",
		disabled = "windows/hero/btn_plus_white.png",
		normal = "windows/hero/btn_plus.png"
	})

	var_195_8:setAnchorPoint(cc.p(0.5, 0.5))

	local var_195_9 = var_195_7:getContentSize()

	var_195_8:setPosition(cc.p(var_195_9.width / 2, var_195_9.height / 2))
	var_195_8:addTo(var_195_7)
	var_195_8:setTouchSwallowEnabled(false)

	arg_195_0.usedStoneNum = 0

	if var_195_4 <= var_195_6 then
		var_195_8:setButtonEnabled(false)
	end

	local var_195_10 = false

	var_195_8:onButtonPressed(function(arg_196_0)
		var_195_8:setScale(0.9)

		local var_196_0 = 0

		local function var_196_1()
			if tolua.isnull(arg_195_0) then
				if arg_195_0.handler and arg_195_0.handler[1] ~= nil then
					var_0_17.unscheduleGlobal(arg_195_0.handler[1])
				end

				return
			end

			var_196_0 = var_196_0 + 0.1

			if var_196_0 > 0.5 then
				var_195_10 = true

				arg_195_0:addStone(var_195_5, arg_195_1, var_195_2)
			else
				var_195_10 = false
			end
		end

		var_195_10 = false

		if arg_195_0.handler and arg_195_0.handler[1] ~= nil then
			var_0_17.unscheduleGlobal(arg_195_0.handler[1])
		end

		arg_195_0.handler[1] = var_0_17.scheduleGlobal(var_196_1, 0.05)
	end)
	var_195_8:onButtonRelease(function(arg_198_0)
		var_195_8:setScale(1)

		if arg_195_0.handler[1] ~= nil then
			var_0_17.unscheduleGlobal(arg_195_0.handler[1])
		end

		if var_195_10 == false then
			arg_195_0:addStone(var_195_5, arg_195_1, var_195_2)
		end

		var_195_8:setButtonEnabled(false)

		if arg_195_0.usedStoneNum <= 0 then
			var_195_8:setButtonEnabled(true)

			return
		end

		local var_198_0 = {
			partner_id = arg_195_0.hero:getHeroID(),
			attr_id = var_195_5[arg_195_1],
			add_num = arg_195_0.usedStoneNum,
			cost_item = arg_195_0:getUseStoneId()
		}

		arg_195_0.selfPlayer:breachStoneAdd(var_198_0, function(arg_199_0, arg_199_1, arg_199_2)
			if not tolua.isnull(var_195_8) then
				var_195_8:setButtonEnabled(true)
			end

			local var_199_0 = arg_195_0.breachList:getScrollNode():getPositionY()

			arg_195_0:updateBreachContainer()
			arg_195_0.breachList:scrollTo(0, var_199_0)
			arg_195_0:updateAttrScore()
		end)

		arg_195_0.usedStoneNum = 0
	end)
	var_195_1:addTo(var_195_0)
	var_195_1:setAnchorPoint(cc.p(0, 0))
	var_195_0:setContentSize(var_195_2:getContentSize())
	var_195_1:setName("source")

	return var_195_0
end

function var_0_7.addStone(arg_200_0, arg_200_1, arg_200_2, arg_200_3)
	local var_200_0 = arg_200_0.hero
	local var_200_1 = arg_200_0:getUseStoneId()
	local var_200_2 = arg_200_0.backpack:getItemNumByID(var_200_1)
	local var_200_3 = var_200_0:getEvoStage()
	local var_200_4 = var_200_0:getEvoAttrPoints()
	local var_200_5 = var_0_23:limitNum(var_200_3)
	local var_200_6 = var_0_23:level(var_200_3)
	local var_200_7 = var_0_23:star(var_200_3)

	if var_200_6 > arg_200_0.hero:getLevel() or var_200_7 > arg_200_0.hero:getStar() then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_21:translation("STONE_EVOLUTION_STAR_LEVEL_TIP"), var_200_7, var_200_6)
		})
	elseif var_200_2 <= arg_200_0.usedStoneNum then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_21:translation("STONE_ITEM_ABSENCE"), xyd.tables.item:name(var_200_1))
		})
	elseif var_200_5 <= (var_200_4[tostring(arg_200_1[arg_200_2])] or 0) + arg_200_0.usedStoneNum then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_21:translation("STONE_ADD_LIMIT")
		})
	else
		arg_200_0.usedStoneNum = (arg_200_0.usedStoneNum or 0) + 1
	end

	arg_200_0:nodeByName("stone_num_txt"):setString(var_200_2 - arg_200_0.usedStoneNum)
	arg_200_0:nodeByName("breach_progress_txt"):setString(tostring(arg_200_0:getEvoProgress() * 100) .. "%")
	arg_200_0:updateStoneProgress(arg_200_2, arg_200_3)
	arg_200_0.giftPush:setSceneCondition(36)
end

function var_0_7.updateStoneProgress(arg_201_0, arg_201_1, arg_201_2)
	local var_201_0 = arg_201_0.hero
	local var_201_1 = arg_201_0.hero:getEvoStage()
	local var_201_2 = var_201_0:getEvoAttrPoints()
	local var_201_3 = var_0_23:attrs(var_201_1)
	local var_201_4 = (var_201_2[tostring(var_201_3[arg_201_1])] or 0) + (arg_201_0.usedStoneNum or 0)
	local var_201_5, var_201_6 = var_0_23:getCumAttr(var_201_1, var_201_4, arg_201_1)

	arg_201_2:getChildByName("progress_txt"):setString(tostring(var_201_5) .. "/" .. tostring(var_201_6))
	arg_201_2:getChildByName("progress_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	arg_201_2:getChildByName("progress_bar"):setPercent(var_201_5 * 100 / var_201_6)
end

function var_0_7.addExp(arg_202_0, arg_202_1, arg_202_2, arg_202_3)
	arg_202_0:playGuide()

	local var_202_0 = arg_202_0.hero

	arg_202_0.levelUpCount_ = arg_202_0.levelUpCount_ or 0

	local var_202_1 = var_202_0:getExp()
	local var_202_2 = xyd.tables.partnerExp:totalExp(arg_202_0.maxLev)
	local var_202_3 = xyd.tables.item:exp(arg_202_2)

	if arg_202_1 <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_21:translation("EXP_ITEM_ABSENCE")
		})
	elseif var_202_2 <= var_202_1 then
		local var_202_4 = xyd.tables.sound:getSound("train_exp_max")

		audio.playSound(var_202_4, false)
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_21:translation("EXP_FULL")
		})
	else
		arg_202_0.usedItemNums[arg_202_2] = arg_202_0.usedItemNums[arg_202_2] + 1
		arg_202_1 = arg_202_1 - 1

		local var_202_5 = clone(var_202_0:getLevel())

		var_202_0:addExp(var_202_3, arg_202_0.maxLev)
		arg_202_0:updateExp(var_202_0)
		arg_202_0:updateAttrScore(var_202_0)

		if var_202_5 < var_202_0:getLevel() then
			arg_202_0.levelUpCount_ = arg_202_0.levelUpCount_ + var_202_0:getLevel() - var_202_5

			arg_202_0:playLevelUpEffect(arg_202_3)
			arg_202_0:updateEquip(var_202_0)
			arg_202_0:setSkillContainer()
		else
			arg_202_0:playEatExpEffect(arg_202_3)
		end

		if not tolua.isnull(arg_202_3) then
			arg_202_3:getChildByName("use_num"):setVisible(true)
			arg_202_3:getChildByName("use_num"):setString("X" .. arg_202_0.usedItemNums[arg_202_2])
		end

		if arg_202_0.visibleHandler[arg_202_2] ~= nil then
			var_0_17.unscheduleGlobal(arg_202_0.visibleHandler[arg_202_2])
		end

		if not tolua.isnull(arg_202_3) then
			local var_202_6 = arg_202_3:getChildByName("use_num")

			arg_202_0.visibleHandler[arg_202_2] = var_0_17.performWithDelayGlobal(function()
				if not tolua.isnull(arg_202_3) then
					var_202_6:setVisible(false)
				end
			end, 0.1)
		end
	end

	return arg_202_1
end

function var_0_7.updateSkillContainer(arg_204_0, arg_204_1)
	if not arg_204_0.cache[var_0_33.Skill] then
		return
	end

	if tolua.isnull(arg_204_0.skillContainer) then
		return
	end

	local var_204_0 = arg_204_0.hero

	arg_204_0.skillPoints = arg_204_0.selfPlayer:getSkillPoint()

	if arg_204_0.skillPoints < 0 then
		arg_204_0.skillPoints = 0
	end

	arg_204_0.skillContainer:getChildByName("jinengdian"):setString(arg_204_0.skillPoints)

	if arg_204_0.skillPoints < arg_204_0.selfPlayer:getSkillPointLimit() then
		arg_204_0:initTimer()
	else
		arg_204_0.skillContainer:getChildByName("point_time"):setVisible(false)
		arg_204_0.skillContainer:getChildByName("point_full"):setVisible(true)
	end

	for iter_204_0, iter_204_1 in pairs(arg_204_0.skillItems) do
		if not tolua.isnull(iter_204_1) then
			local var_204_1 = iter_204_1:getChildByName("jiadian")

			if var_204_0:getSkillLevel(iter_204_0) then
				local var_204_2 = var_204_0:getSkillLevel(iter_204_0) - xyd.SKILL_EXTRA[iter_204_0]

				iter_204_1:getChildByName("lev"):setString("lv. " .. var_204_2)

				local var_204_3 = arg_204_0:getSkillUpgradeDiscount()

				iter_204_1:getChildByName("gold_text"):setString(xyd.isSuperHero(var_204_0) and xyd.tables.skillPrice:gold(var_204_0:getSkillLevel(iter_204_0)) * var_204_3 * 10 or xyd.tables.skillPrice:gold(var_204_0:getSkillLevel(iter_204_0)) * var_204_3)
			end

			if not arg_204_1 and var_204_1 then
				if not var_204_0:getSkillLevel(iter_204_0) or var_204_0:getSkillLevel(iter_204_0) >= var_204_0:getLevel() + var_204_0:getBookShelfSkillLevel() then
					var_204_1:setButtonEnabled(false)
				else
					var_204_1:setButtonEnabled(true)
				end
			end
		end
	end
end

function var_0_7.updateInfoChart(arg_205_0)
	if not arg_205_0.cache[var_0_33.Info] then
		return
	end

	local var_205_0 = arg_205_0.hero
	local var_205_1 = arg_205_0:nodeByName("canvas")
	local var_205_2 = var_205_0:getAttrRates()

	xyd.drawColorPentagon(var_205_1, {
		radius = 110,
		values = var_205_2,
		center = cc.p(112, 100)
	})
end

function var_0_7.updateRecommendInfo(arg_206_0)
	if not arg_206_0.cache[var_0_33.Info] then
		return
	end

	arg_206_0:nodeByName("recommend_score_txt"):setString(var_0_21:translation("RECOMMEND_SCORE_TEXT") .. ":" .. (arg_206_0.heroRecommend:getHeroRecommendScore(arg_206_0.hero:getFirstTableID()) or 0))
	arg_206_0:nodeByName("recommend_score_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	arg_206_0:nodeByName("recommend_btn"):addTouchEventListener(function(arg_207_0, arg_207_1)
		xyd.buttonScaleAnim(arg_206_0:nodeByName("recommend_btn"), arg_207_1)

		if arg_207_1 == ccui.TouchEventType.ended then
			arg_206_0.heroRecommend:toRecommendDetailWindow(arg_206_0.hero:getFirstTableID())
		end
	end)
end

function var_0_7.updateIntroduceText(arg_208_0)
	if not arg_208_0.cache[var_0_33.Info] then
		return
	end

	local var_208_0 = arg_208_0.hero
	local var_208_1 = arg_208_0:nodeByName("jieshao_container")

	if tolua.isnull(var_208_1) then
		return
	end

	local var_208_2 = var_208_1:getChildByName("text_title_des")
	local var_208_3 = var_208_1:getChildByName("title_back")
	local var_208_4 = var_208_1:getChildren()

	if var_208_4 then
		for iter_208_0, iter_208_1 in ipairs(var_208_4) do
			if iter_208_1 ~= var_208_2 and iter_208_1 ~= var_208_3 then
				var_208_1:removeChild(iter_208_1)
			end
		end
	end

	local var_208_5 = {
		y = 0,
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(54, 54, 54),
		dimensions = cc.size(470, 54),
		text = var_208_0:getTalkText()
	}
	local var_208_6
	local var_208_7 = 0
	local var_208_8 = 0

	if var_208_0:getTalkText() then
		local var_208_9 = xyd.AssetLoader.get():loadLabel(var_208_5)

		var_208_9:addTo(var_208_1)
		var_208_9:setAnchorPoint(cc.p(0, 0))

		var_208_7 = var_208_9:getStringNumLines()
		var_208_8 = 10
	end

	local var_208_10 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = var_208_7 * 30 + var_208_8,
		color = cc.c3b(235, 75, 94),
		dimensions = cc.size(470, 100),
		text = var_208_0:getDes()
	}
	local var_208_11 = xyd.AssetLoader.get():loadLabel(var_208_10)

	var_208_11:addTo(var_208_1)
	var_208_11:setAnchorPoint(cc.p(0, 0))

	local var_208_12 = var_208_11:getStringNumLines()

	var_208_3:y(var_208_10.y + var_208_12 * 30 + 20)
	var_208_2:y(var_208_10.y + var_208_12 * 30 + 20)

	local var_208_13 = var_208_2:getY()

	var_208_1:height(var_208_13 + 31)
end

function var_0_7.updateAttrLabels(arg_209_0)
	if not arg_209_0.cache[var_0_33.Info] then
		return
	end

	if not arg_209_0.hero then
		return
	end

	local var_209_0 = arg_209_0.hero
	local var_209_1 = 0
	local var_209_2 = arg_209_0:nodeByName("shuxing_container")

	if tolua.isnull(var_209_2) then
		return
	end

	local var_209_3 = var_209_2:getChildByName("text_title_info")
	local var_209_4 = var_209_2:getChildByName("title_back")
	local var_209_5 = var_209_2:getChildren()

	if var_209_5 then
		for iter_209_0, iter_209_1 in ipairs(var_209_5) do
			if iter_209_1 ~= var_209_3 and iter_209_1 ~= var_209_4 then
				var_209_2:removeChild(iter_209_1)
			end
		end
	end

	local var_209_6 = {
		xyd.AttributeType.DIKANG_YINGZHI,
		xyd.AttributeType.HALF_MP
	}

	for iter_209_2, iter_209_3 in ipairs(var_209_6) do
		if var_209_0:getSkillBookAttr(iter_209_3) > 0 then
			var_209_1 = var_209_1 + 1

			local var_209_7 = arg_209_0:createBookLabel(iter_209_3)

			var_209_7:addTo(var_209_2)
			var_209_7:setPosition(20, 20 + var_209_1 * 35)
		end
	end

	for iter_209_4 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if var_209_0:getSkillBookAttr(iter_209_4) > 0 then
			var_209_1 = var_209_1 + 1

			local var_209_8 = arg_209_0:createBookLabel(iter_209_4)

			var_209_8:addTo(var_209_2)
			var_209_8:setPosition(20, 20 + var_209_1 * 35)
		end
	end

	local var_209_9 = 30 + var_209_1 * 35 + 15
	local var_209_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/book/book_title.csb")

	if var_209_1 == 0 then
		var_209_9 = 0
	else
		var_209_10:addTo(var_209_2)
		var_209_10:getChildByName("container"):getChildByName("title_not_has"):setVisible(false)
		var_209_10:getChildByName("container"):getChildByName("title_has"):setString(var_0_21:translation("HERO_MAIN_TEXT_58"))
		var_209_10:setPosition(18, var_209_9 + 15)
	end

	local var_209_11 = 0

	for iter_209_5, iter_209_6 in ipairs(var_209_6) do
		if var_209_0:getTotalAttrWithOutBook(iter_209_6) > 0 then
			var_209_11 = var_209_11 + 1

			local var_209_12 = arg_209_0:createLabel(iter_209_6)

			var_209_12:addTo(var_209_2)
			var_209_12:setPosition(20, 20 + var_209_11 * 35 + var_209_9)
		end
	end

	for iter_209_7 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if var_209_0:getTotalAttrWithOutBook(iter_209_7) > 0 then
			var_209_11 = var_209_11 + 1

			local var_209_13 = arg_209_0:createLabel(iter_209_7)

			var_209_13:addTo(var_209_2)
			var_209_13:setPosition(20, 20 + var_209_11 * 35 + var_209_9)
		end
	end

	local var_209_14 = arg_209_0:setGrowAttrLabel(55 + var_209_11 * 35 + var_209_9)

	var_209_4:y(var_209_14 + 15)
	var_209_3:y(var_209_14 + 15)
	var_209_2:height(var_209_14 + 43)
	var_209_2:setPosition(cc.p(0, 0))
end

function var_0_7.setGrowAttrLabel(arg_210_0, arg_210_1)
	local var_210_0 = arg_210_0:nodeByName("shuxing_container")
	local var_210_1 = arg_210_0.hero

	arg_210_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

	local var_210_2 = arg_210_0.eventCentre.buidingInfo[tostring(xyd.EventCentreBuildingType.BOOKSHELF)].lev
	local var_210_3 = xyd.tables.bookShelfTable:attribute(var_210_2)

	local function var_210_4(arg_211_0)
		local var_211_0 = var_210_1:getAttrGlow(arg_211_0)
		local var_211_1 = tonumber(var_210_3[arg_211_0])

		if var_210_1:getFavorAttrGrowth() > 0 or var_210_1:getHouseAttrGrowthByType(arg_211_0) > 0 then
			local var_211_2 = var_210_1:getFavorAttrGrowByType(arg_211_0)
			local var_211_3 = var_210_1:getHouseAttrGrowByType(arg_211_0)

			text = "+" .. string.format("%.2f(%0.1f%%)", var_211_0 * var_211_1 * 0.01 + var_211_2 + var_211_3, var_211_1 + var_210_1:getFavorAttrGrowth() * 100 + var_210_1:getHouseAttrGrowthByType(arg_211_0) * 100)
		elseif var_211_1 ~= 0 then
			text = "+" .. string.format("%.2f(%0.1f%%)", var_211_0 * var_211_1 * 0.01, var_211_1)
		elseif var_211_1 == 0 then
			text = ""
		end

		return text
	end

	local var_210_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_210_5:getChildByName("txt_title"):setString(var_0_21:translation("HERO_BUTTON_MINJIECHENGZHANG"))
	var_210_5:getChildByName("title_bg"):width(34 + var_210_5:getChildByName("txt_title"):getWidth())
	var_210_5:getChildByName("txt_ini"):setString(var_210_1:getAttrGlow(xyd.AttributeType.AGILE))
	var_210_5:getChildByName("txt_add"):setString(var_210_4(xyd.AttributeType.AGILE))

	local var_210_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_210_6:getChildByName("txt_title"):setString(var_0_21:translation("HERO_BUTTON_ZHILICHENGZHANG"))
	var_210_6:getChildByName("title_bg"):width(34 + var_210_6:getChildByName("txt_title"):getWidth())
	var_210_6:getChildByName("txt_ini"):setString(var_210_1:getAttrGlow(xyd.AttributeType.WISE))
	var_210_6:getChildByName("txt_add"):setString(var_210_4(xyd.AttributeType.WISE))

	local var_210_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_210_7:getChildByName("txt_title"):setString(var_0_21:translation("HERO_BUTTON_LILIANGCHENGZHANG"))
	var_210_7:getChildByName("title_bg"):width(34 + var_210_7:getChildByName("txt_title"):getWidth())
	var_210_7:getChildByName("txt_ini"):setString(var_210_1:getAttrGlow(xyd.AttributeType.STRENGTH))
	var_210_7:getChildByName("txt_add"):setString(var_210_4(xyd.AttributeType.STRENGTH))
	var_210_5:addTo(var_210_0)
	var_210_5:setPosition(20, arg_210_1)
	var_210_6:addTo(var_210_0)
	var_210_6:setPosition(20, arg_210_1 + 35)
	var_210_7:addTo(var_210_0)
	var_210_7:setPosition(20, arg_210_1 + 70)

	return arg_210_1 + 110
end

function var_0_7.createBookLabel(arg_212_0, arg_212_1)
	local var_212_0 = arg_212_0.hero
	local var_212_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_212_1:getChildByName("txt_title"):setString(xyd.tables.attr:name(arg_212_1))
	var_212_1:getChildByName("title_bg"):width(34 + var_212_1:getChildByName("txt_title"):getWidth())
	var_212_1:getChildByName("txt_ini"):setString(math.ceil(math.max(0, var_212_0:getSkillBookAttr(arg_212_1))))
	var_212_1:getChildByName("txt_add"):setString("")

	return var_212_1
end

function var_0_7.createLabel(arg_213_0, arg_213_1)
	local var_213_0 = arg_213_0.hero
	local var_213_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_213_1:getChildByName("txt_title"):setString(xyd.tables.attr:name(arg_213_1))
	var_213_1:getChildByName("title_bg"):width(34 + var_213_1:getChildByName("txt_title"):getWidth())
	var_213_1:getChildByName("txt_ini"):setString(math.ceil(math.max(0, var_213_0:getTotalAttr(arg_213_1) - var_213_0:getEquipFumoAttr(arg_213_1) - var_213_0:getEquipAttr(arg_213_1) - var_213_0:getSkillAttr(arg_213_1) - var_213_0:getSkill2Attr(arg_213_1) - var_213_0:getTotalPracticeAttr(arg_213_1) - var_213_0:getBookShelfAttr(arg_213_1) - var_213_0:getInscriptionAttr(arg_213_1) - var_213_0:getConquerSchoolAttr(arg_213_1) - var_213_0:getWhiteAlbumAttr(arg_213_1) - var_213_0:getElementAttr(arg_213_1) - var_213_0:getSpiritEquipsAttr(arg_213_1))))

	local var_213_2 = math.ceil(var_213_0:getEquipFumoAttr(arg_213_1) + var_213_0:getEquipAttr(arg_213_1) + var_213_0:getSkillAttr(arg_213_1) + var_213_0:getSkill2Attr(arg_213_1) + var_213_0:getTotalPracticeAttr(arg_213_1) + var_213_0:getBookShelfAttr(arg_213_1) + var_213_0:getInscriptionAttr(arg_213_1) + var_213_0:getConquerSchoolAttr(arg_213_1) + var_213_0:getWhiteAlbumAttr(arg_213_1) + var_213_0:getElementAttr(arg_213_1) + var_213_0:getSpiritEquipsAttr(arg_213_1))

	if var_213_2 > 0 then
		var_213_1:getChildByName("txt_add"):setString("+" .. var_213_2 .. (xyd.tables.attr:suffix(arg_213_1) ~= "" and xyd.tables.attr:suffix(arg_213_1) or ""))
	else
		var_213_1:getChildByName("txt_add"):setString("")
	end

	return var_213_1
end

function var_0_7.updateInscription(arg_214_0, arg_214_1)
	if not arg_214_0.cache[var_0_33.Inscription] then
		return
	end

	local var_214_0 = 3
	local var_214_1 = 0

	if not arg_214_0.inscriptionList then
		arg_214_0.inscriptionList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 500, 170),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_214_0:nodeByName("inscription_attr_container")):onScroll(handler(arg_214_0, arg_214_0.scrollListener))
	else
		arg_214_0.inscriptionList:removeAllItems()
	end

	local var_214_2 = arg_214_0.inscription:getSuitInfo(arg_214_0.hero)

	arg_214_0.inscriptionInfos = {}

	local var_214_3 = {}

	for iter_214_0, iter_214_1 in pairs(var_214_2) do
		local var_214_4 = {
			name = var_0_22:name(iter_214_0)
		}
		local var_214_5, var_214_6, var_214_7 = arg_214_0.inscription:getInscriptionSuitAttrLabelText(iter_214_0)

		var_214_4.attrLabelTxt = tostring(var_214_5 .. "+" .. var_214_6 .. var_214_7)
		var_214_4.isSuit = true
		var_214_4.isSuitOn = iter_214_1
		var_214_4.suitID = iter_214_0
		var_214_4.hero = arg_214_0.hero

		table.insert(arg_214_0.inscriptionInfos, var_214_4)

		if iter_214_1 then
			var_214_3 = var_0_22:itemID(iter_214_0)
		end
	end

	if #var_214_3 >= 3 then
		local var_214_8 = cc.p(164, 166)

		arg_214_0:playEffect(arg_214_0.inscriptionContainer:getChildByName("set_inscription_bg"), "Fuwen3", var_214_8, true)
		arg_214_0.UIEffects.Fuwen3:setScale(0.89)
	elseif not tolua.isnull(arg_214_0.UIEffects.Fuwen3) then
		arg_214_0.UIEffects.Fuwen3:removeSelf()
	end

	for iter_214_2 = 1, var_214_0 do
		if arg_214_1 then
			arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setTouchEnabled(true)
			arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_215_0)
				local var_215_0 = arg_214_0.hero:getInscriptItem(iter_214_2)

				if arg_215_0.name == "began" then
					arg_214_0.scrollViewMoved_ = false
					arg_214_0.prevX_ = arg_215_0.x
					arg_214_0.prevY_ = arg_215_0.y

					if not var_215_0 then
						arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setScale(0.9)
					end

					return true
				elseif arg_215_0.name == "moved" then
					local var_215_1 = 5

					if var_215_1 <= math.abs(arg_215_0.y - arg_214_0.prevY_) or var_215_1 <= math.abs(arg_215_0.x - arg_214_0.prevX_) then
						arg_214_0.scrollViewMoved_ = true
					end
				elseif arg_215_0.name == "ended" then
					if not var_215_0 then
						arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setScale(1)
					end

					if arg_214_0.scrollViewMoved_ == true then
						return
					end

					local var_215_2 = {
						hero = arg_214_0.hero,
						inscript_type = iter_214_2
					}

					xyd.WindowManager.get():openWindow("inscription_equip", var_215_2)
				end
			end)
		end

		arg_214_0.inscriptionContainer:getChildByName("inscription" .. iter_214_2):removeAllChildren(true)
		arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setOpacity(255)
		arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setScale(1)

		local var_214_9 = arg_214_0.hero:getInscriptItem(iter_214_2)

		if xyd.tableHaveElement(var_214_3, var_214_9) then
			local var_214_10 = cc.p(arg_214_0.inscriptionContainer:getChildByName("inscription" .. iter_214_2):getPositionX() + 1, arg_214_0.inscriptionContainer:getChildByName("inscription" .. iter_214_2):getPositionY() - 18)

			arg_214_0:playEffect(arg_214_0.inscriptionContainer, "Fuwen2_" .. iter_214_2, var_214_10, true, true)
			arg_214_0.UIEffects["Fuwen2_" .. iter_214_2]:setScale(0.45)
		elseif not tolua.isnull(arg_214_0.UIEffects["Fuwen2_" .. iter_214_2]) then
			arg_214_0.UIEffects["Fuwen2_" .. iter_214_2]:removeSelf()
		end

		local var_214_11 = xyd.tables.item:inscriptId(var_214_9)

		if var_214_9 then
			arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setOpacity(0)
			arg_214_0.inscriptionContainer:getChildByName("green_plus" .. iter_214_2):setScale(2)
			arg_214_0.inscription:setTransparentBorder(arg_214_0.inscriptionContainer:getChildByName("inscription" .. iter_214_2), var_214_9)
			arg_214_0.inscriptionContainer:getChildByName("inscription" .. iter_214_2):setScale(0.9)

			var_214_1 = var_214_1 + 1

			local var_214_12 = {
				name = tostring("Lv." .. xyd.tables.inscription:level(var_214_11) .. " " .. xyd.tables.item:name(var_214_9))
			}
			local var_214_13, var_214_14, var_214_15 = arg_214_0.inscription:getInscriptionAttrLabelText(var_214_9)

			var_214_12.attrLabelTxt = tostring(var_214_13 .. "+" .. var_214_14 .. var_214_15)
			var_214_12.isSuit = false
			var_214_12.itemID = var_214_9
			var_214_12.hero = arg_214_0.hero

			table.insert(arg_214_0.inscriptionInfos, var_214_12)
		end
	end

	for iter_214_3, iter_214_4 in ipairs(arg_214_0.inscriptionInfos) do
		local var_214_16 = arg_214_0.inscriptionList:newItem()
		local var_214_17 = display.newNode()
		local var_214_18 = 130
		local var_214_19 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/inscription_item.csb")
		local var_214_20 = var_214_19:getChildByName("bg")

		var_214_20:getChildByName("inscription_name"):setString(iter_214_4.name)
		var_214_20:getChildByName("inscription_attr"):setString(iter_214_4.attrLabelTxt)
		var_214_20:getChildByName("bg_name"):width(var_214_20:getChildByName("inscription_name"):getWidth() + 24)

		if iter_214_4.isSuit and not iter_214_4.isSuitOn then
			var_214_20:getChildByName("inscription_attr"):setOpacity(128)
		end

		if iter_214_4.isSuit then
			for iter_214_5, iter_214_6 in ipairs(var_0_22:itemID(iter_214_4.suitID)) do
				local var_214_21 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/inscription_item_detail.csb")
				local var_214_22 = var_214_21:getChildByName("bg")

				arg_214_0:setInscriptionIcon(var_214_22:getChildByName("icon"), iter_214_6)
				var_214_22:getChildByName("name"):setString(xyd.tables.item:name(iter_214_6))
				var_214_21:addTo(var_214_20)
				var_214_21:setPosition((iter_214_5 + 1) % 2 * 255, #var_0_22:itemID(iter_214_4.suitID) > 2 and (1 - (math.ceil(iter_214_5 / 2) - 1)) * 70 + 50 or 50)

				if not xyd.tableHaveElement(iter_214_4.hero:getInscriptItems(), iter_214_6) then
					var_214_22:setOpacity(128)
				end
			end

			if #var_0_22:itemID(iter_214_4.suitID) > 2 then
				var_214_18 = 200
			end
		else
			local var_214_23 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/inscription_item_detail.csb")
			local var_214_24 = var_214_23:getChildByName("bg")

			arg_214_0:setInscriptionIcon(var_214_24:getChildByName("icon"), iter_214_4.itemID)
			var_214_24:getChildByName("name"):setString(xyd.tables.item:name(iter_214_4.itemID))
			var_214_23:addTo(var_214_20)
			var_214_23:setPosition(0, 50)
		end

		var_214_17:addChild(var_214_19)
		var_214_16:addContent(var_214_17)
		var_214_17:setContentSize(494, var_214_18)
		var_214_16:setItemSize(494, var_214_18)
		arg_214_0.inscriptionList:addItem(var_214_16)
	end

	arg_214_0.inscriptionList:reload()
end

function var_0_7.setInscriptionIcon(arg_216_0, arg_216_1, arg_216_2)
	local var_216_0 = xyd.tables.item:transparentIcon(arg_216_2)
	local var_216_1 = xyd.SpriteLoader.new(var_216_0, nil, nil, xyd.DefaultImageType.INSCRIPTION)
	local var_216_2 = arg_216_1:getContentSize().width
	local var_216_3 = arg_216_1:getContentSize().height

	var_216_1:setScale((var_216_2 + 20) / var_216_1:getWidth())
	var_216_1:addTo(arg_216_1)
	var_216_1:setAnchorPoint(0.5, 0.5)
	var_216_1:setPosition(cc.p(var_216_2 / 2, var_216_3 / 2))
end

function var_0_7.clickMainButton(arg_217_0)
	if arg_217_0.sendSkillLevUpRequest then
		arg_217_0:sendSkillLevUpRequest()
	end

	if arg_217_0.detailState ~= var_0_12 then
		arg_217_0.detailContainers[arg_217_0.detailState]:setVisible(false)
		arg_217_0.detailContainers[var_0_12]:setVisible(true)

		arg_217_0.detailState = var_0_12

		arg_217_0:updateButtonBrightState()
	else
		arg_217_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_7.clickInfoButton(arg_218_0)
	if not arg_218_0.cache[var_0_33.Info] then
		arg_218_0.cache[var_0_33.Info] = true

		arg_218_0:updateAttrLabels()
		arg_218_0:updateInfoChart()
		arg_218_0:updateRecommendInfo()
		arg_218_0:updateIntroduceText()
		arg_218_0:updateScrollBg()
	end

	if arg_218_0.sendSkillLevUpRequest then
		arg_218_0:sendSkillLevUpRequest()
	end

	if arg_218_0.detailState ~= var_0_13 then
		arg_218_0.detailContainers[arg_218_0.detailState]:setVisible(false)
		arg_218_0.detailContainers[var_0_13]:setVisible(true)

		arg_218_0.detailState = var_0_13

		arg_218_0:updateButtonBrightState()
	else
		arg_218_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_7.clickSkillButton(arg_219_0)
	if not arg_219_0.cache[var_0_33.Skill] then
		arg_219_0.cache[var_0_33.Skill] = true

		arg_219_0:setSkillContainer()
		arg_219_0:updateCourseInfo()
	end

	if arg_219_0.sendSkillLevUpRequest then
		arg_219_0:sendSkillLevUpRequest()
	end

	if arg_219_0.detailState ~= var_0_14 then
		if arg_219_0.skillList and not tolua.isnull(arg_219_0.skillList) then
			if arg_219_0.skillCount and arg_219_0.skillCount == 4 then
				arg_219_0.skillList:getScrollNode():setPositionY(-3)
			elseif arg_219_0.skillCount and arg_219_0.skillCount == 5 then
				arg_219_0.skillList:getScrollNode():setPositionY(-120)
			end
		end

		arg_219_0.detailContainers[arg_219_0.detailState]:setVisible(false)
		arg_219_0.detailContainers[var_0_14]:setVisible(true)

		arg_219_0.detailState = var_0_14

		arg_219_0:updateButtonBrightState()
		arg_219_0:updateSkillContainer()
		arg_219_0:updateAllSkillTips()
	else
		arg_219_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_7.skillListAction(arg_220_0, arg_220_1, arg_220_2, arg_220_3)
	if arg_220_0.hero:isAwaken() then
		local var_220_0 = var_0_17.performWithDelayGlobal(function()
			if not xyd.WindowManager.get():getWindow("hero_main") then
				return
			end

			local var_221_0 = 120 / arg_220_2
			local var_221_1 = -120
			local var_221_2 = var_0_17.scheduleGlobal(function()
				var_221_1 = var_221_1 + var_221_0

				local var_222_0 = xyd.WindowManager.get():getWindow("hero_main")

				if var_222_0 and var_221_1 <= 0 then
					var_222_0.skillList:getScrollNode():setPositionY(var_221_1)
				elseif skillHandle then
					var_0_17.unscheduleGlobal(skillHandle)
				end
			end, arg_220_1)
		end, arg_220_3)
	end
end

function var_0_7.clickStoneButton(arg_223_0)
	local var_223_0 = arg_223_0.hero
	local var_223_1 = xyd.tables.hero:stoneID(var_223_0:getTableID())

	xyd.WindowManager.get():openWindow("stone", {
		hero = var_223_0,
		itemComposeID = var_223_1
	})
end

function var_0_7.clickSkinButton(arg_224_0)
	if not arg_224_0.cache[var_0_33.Skin] then
		arg_224_0.cache[var_0_33.Skin] = true

		arg_224_0:updateEquipInfoContainer()
		arg_224_0:updateSkinModel(arg_224_0.hero)
	end

	local var_224_0 = arg_224_0.containers[arg_224_0.state]
	local var_224_1 = {}

	table.insert(var_224_1, cc.MoveBy:create(0.1, cc.p(560, 0)))
	table.insert(var_224_1, cc.CallFunc:create(function()
		local var_225_0 = {}

		table.insert(var_225_0, cc.DelayTime:create(0.1))
		table.insert(var_225_0, cc.MoveBy:create(0.1, cc.p(-753, 0)))
		var_224_0:hide()
		arg_224_0.containers[var_0_10]:show()
		arg_224_0.containers[var_0_10]:runAction(transition.sequence(var_225_0))
	end))
	arg_224_0:updateBtnSkinBtnShow(true, arg_224_0.skinDatas[arg_224_0.skinIllusionEquip].modelID)
	var_224_0:runAction(transition.sequence(var_224_1))

	arg_224_0.state = var_0_10

	arg_224_0:updateBtnState()
	arg_224_0:updateLiveBtnShow()
end

function var_0_7.clickHeroDetailButton(arg_226_0)
	local var_226_0 = arg_226_0.containers[arg_226_0.state]
	local var_226_1
	local var_226_2 = arg_226_0.state == var_0_10 and 753 or 560
	local var_226_3 = {}

	table.insert(var_226_3, cc.MoveBy:create(0.1, cc.p(var_226_2, 0)))
	table.insert(var_226_3, cc.CallFunc:create(function()
		local var_227_0 = {}

		table.insert(var_227_0, cc.DelayTime:create(0.1))
		table.insert(var_227_0, cc.MoveBy:create(0.1, cc.p(-560, 0)))
		var_226_0:hide()
		arg_226_0.containers[var_0_9]:show()
		arg_226_0.containers[var_0_9]:runAction(transition.sequence(var_227_0))
	end))
	var_226_0:runAction(transition.sequence(var_226_3))

	arg_226_0.state = var_0_9

	if arg_226_0.isTrySkin then
		arg_226_0.isTrySkin = false
		arg_226_0.trySkinModelID = 0

		arg_226_0:updateEquipInfoContainer()
		arg_226_0:updateSkinModel()
		arg_226_0:updateHeroHomeCard()
	else
		arg_226_0:updateLiveBtnShow()
	end

	arg_226_0:updateBtnState()
end

function var_0_7.clickAddExpButton(arg_228_0)
	local var_228_0 = {
		hero = arg_228_0.hero,
		wnd = arg_228_0
	}

	xyd.WindowManager.get():openWindow("add_exp", var_228_0)
end

function var_0_7.clickBookButton(arg_229_0)
	if not arg_229_0.cache[var_0_33.Book] then
		arg_229_0.cache[var_0_33.Book] = true

		arg_229_0:updateBookContainer()
	end

	local var_229_0 = arg_229_0.containers[arg_229_0.state]
	local var_229_1
	local var_229_2 = arg_229_0.state == var_0_10 and 753 or 560
	local var_229_3 = {}

	table.insert(var_229_3, cc.MoveBy:create(0.1, cc.p(var_229_2, 0)))
	table.insert(var_229_3, cc.CallFunc:create(function()
		local var_230_0 = {}

		table.insert(var_230_0, cc.DelayTime:create(0.1))
		table.insert(var_230_0, cc.MoveBy:create(0.1, cc.p(-560, 0)))
		var_229_0:hide()
		arg_229_0.containers[var_0_11]:show()
		arg_229_0.containers[var_0_11]:runAction(transition.sequence(var_230_0))
	end))
	var_229_0:runAction(transition.sequence(var_229_3))

	if arg_229_0.isTrySkin then
		arg_229_0.isTrySkin = false
		arg_229_0.trySkinModelID = 0

		arg_229_0:updateEquipInfoContainer()
		arg_229_0:updateSkinModel()
		arg_229_0:updateHeroHomeCard()
	else
		arg_229_0:updateLiveBtnShow()
	end

	arg_229_0.state = var_0_11

	arg_229_0:updateBtnState()
end

function var_0_7.clickInscriptionButton(arg_231_0)
	if not arg_231_0.cache[var_0_33.Inscription] then
		arg_231_0.cache[var_0_33.Inscription] = true

		arg_231_0:updateInscription(true)
	end

	if arg_231_0.detailState ~= var_0_16 then
		arg_231_0.detailContainers[arg_231_0.detailState]:setVisible(false)
		arg_231_0.detailContainers[var_0_16]:setVisible(true)

		if not tolua.isnull(arg_231_0.UIEffects.Fuwen3) then
			arg_231_0.UIEffects.Fuwen3:play(function()
				return
			end)
		end

		arg_231_0.detailState = var_0_16

		arg_231_0:updateButtonBrightState()
	else
		arg_231_0:nodeByName("button_inscription"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_7.clickBreachButton(arg_233_0)
	if arg_233_0.detailState ~= var_0_15 then
		arg_233_0.detailContainers[arg_233_0.detailState]:setVisible(false)
		arg_233_0.detailContainers[var_0_15]:setVisible(true)

		if not tolua.isnull(arg_233_0.UIEffects.Fuwen3) then
			arg_233_0.UIEffects.Fuwen3:play(function()
				return
			end)
		end

		arg_233_0.detailState = var_0_15

		arg_233_0:updateButtonBrightState()
	else
		arg_233_0:nodeByName("button_breach"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_7.clickCourseModifyButton(arg_235_0)
	local function var_235_0()
		if arg_235_0 and arg_235_0.courseList and not tolua.isnull(arg_235_0.courseList) then
			arg_235_0:updateCourseInfo()
		end
	end

	arg_235_0.course:enterCourseWindow(arg_235_0.hero, var_235_0)
end

function var_0_7.initTimer(arg_237_0)
	arg_237_0.skillPoints = arg_237_0.selfPlayer:getSkillPoint()
	arg_237_0.timeCount = arg_237_0.selfPlayer:getNextSkillRecoverDuration()

	if arg_237_0.timer then
		return
	end

	if arg_237_0.skillPoints < arg_237_0.selfPlayer:getSkillPointLimit() then
		arg_237_0.timer = var_0_17.scheduleGlobal(handler(arg_237_0, arg_237_0.onTimer), 0.1)
	end
end

function var_0_7.clickCardButton(arg_238_0)
	if not arg_238_0.cache[var_0_33.Card] then
		arg_238_0.cache[var_0_33.Card] = true

		arg_238_0:updateCard()
	end

	if arg_238_0.sendSkillLevUpRequest then
		arg_238_0:sendSkillLevUpRequest()
	end

	if not arg_238_0.isCardShow then
		local var_238_0 = {}

		table.insert(var_238_0, cc.DelayTime:create(0.1))
		table.insert(var_238_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_238_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_238_0, cc.ScaleTo:create(0.05, 1))
		table.insert(var_238_0, cc.CallFunc:create(function()
			arg_238_0.cardBlock:show()
		end))
		arg_238_0.cardContainer:scale(0)
		arg_238_0.cardContainer:show()
		arg_238_0.cardContainer:runAction(transition.sequence(var_238_0))

		arg_238_0.isCardShow = true
	else
		local var_238_1 = {}

		table.insert(var_238_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_238_1, cc.CallFunc:create(function()
			arg_238_0.cardContainer:hide()
			arg_238_0.cardBlock:hide()
		end))
		arg_238_0.cardContainer:runAction(transition.sequence(var_238_1))

		arg_238_0.isCardShow = false
	end
end

function var_0_7.updateButtonBrightState(arg_241_0)
	arg_241_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.normal)
	arg_241_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.normal)
	arg_241_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.normal)
	arg_241_0:nodeByName("button_inscription"):setBrightStyle(ccui.BrightStyle.normal)
	arg_241_0:nodeByName("button_breach"):setBrightStyle(ccui.BrightStyle.normal)

	if arg_241_0.detailState == var_0_12 then
		arg_241_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_241_0.detailState == var_0_14 then
		arg_241_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_241_0.detailState == var_0_13 then
		arg_241_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_241_0.detailState == var_0_16 then
		arg_241_0:nodeByName("button_inscription"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_241_0.detailState == var_0_15 then
		arg_241_0:nodeByName("button_breach"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_7.updateBtnShow(arg_242_0)
	local var_242_0 = var_0_23:level(1)
	local var_242_1 = false

	if var_242_0 <= arg_242_0.selfPlayer.lev and not xyd.isSuperHero(arg_242_0.hero) then
		var_242_1 = true
	end

	arg_242_0:nodeByName("btn_main"):setPositionX(5)

	if not var_242_1 and not arg_242_0.hero:isInscriptionOpen() then
		arg_242_0:nodeByName("button_shuxing"):setPositionX(187)
		arg_242_0:nodeByName("button_jineng"):setPositionX(369)
		arg_242_0:nodeByName("button_breach"):setVisible(false)
		arg_242_0:nodeByName("button_inscription"):setVisible(false)
		arg_242_0:nodeByName("button_shuxing"):width(188.3)
		arg_242_0:nodeByName("button_jineng"):width(188.3)
		arg_242_0:nodeByName("btn_main"):width(188.3)

		arg_242_0.inscriptionOn = false
	elseif var_242_1 and not arg_242_0.hero:isInscriptionOpen() then
		arg_242_0:nodeByName("button_shuxing"):setPositionX(141.5)
		arg_242_0:nodeByName("button_jineng"):setPositionX(278)
		arg_242_0:nodeByName("button_breach"):setPositionX(414.5)
		arg_242_0:nodeByName("button_breach"):setVisible(true)
		arg_242_0:nodeByName("button_inscription"):setVisible(false)
		arg_242_0:nodeByName("button_shuxing"):width(142.5)
		arg_242_0:nodeByName("button_jineng"):width(142.5)
		arg_242_0:nodeByName("button_breach"):width(142.5)
		arg_242_0:nodeByName("btn_main"):width(142.5)

		arg_242_0.inscriptionOn = false
	else
		arg_242_0:nodeByName("button_shuxing"):setPositionX(114)
		arg_242_0:nodeByName("button_jineng"):setPositionX(223)
		arg_242_0:nodeByName("button_breach"):setPositionX(332)
		arg_242_0:nodeByName("button_inscription"):setPositionX(441)
		arg_242_0:nodeByName("button_breach"):setVisible(true)
		arg_242_0:nodeByName("button_inscription"):setVisible(true)
		arg_242_0:nodeByName("btn_main"):width(115)
		arg_242_0:nodeByName("button_shuxing"):width(115)
		arg_242_0:nodeByName("button_jineng"):width(115)
		arg_242_0:nodeByName("button_breach"):width(115)
		arg_242_0:nodeByName("button_inscription"):width(115)

		arg_242_0.inscriptionOn = true
	end

	arg_242_0:nodeByName("txt_main"):setPositionX(arg_242_0:nodeByName("btn_main"):getWidth() / 2)
	arg_242_0:nodeByName("txt_shuxing"):setPositionX(arg_242_0:nodeByName("button_shuxing"):getWidth() / 2)
	arg_242_0:nodeByName("txt_jineng"):setPositionX(arg_242_0:nodeByName("button_jineng"):getWidth() / 2)
	arg_242_0:nodeByName("txt_breach"):setPositionX(arg_242_0:nodeByName("button_breach"):getWidth() / 2)
	arg_242_0:nodeByName("txt_inscription"):setPositionX(arg_242_0:nodeByName("button_inscription"):getWidth() / 2)

	if arg_242_0.detailState == var_0_16 then
		arg_242_0:clickMainButton()
	end

	if arg_242_0.state == var_0_11 and not arg_242_0:checkBookShow() then
		arg_242_0:clickHeroDetailButton()
	end

	if arg_242_0:isHeroCanEvolve() then
		arg_242_0:nodeByName("button_jinhua"):setVisible(true)
		arg_242_0:nodeByName("button_linghunshi"):setVisible(false)
	else
		arg_242_0:nodeByName("button_jinhua"):setVisible(false)
		arg_242_0:nodeByName("button_linghunshi"):setVisible(true)
	end
end

function var_0_7.isHeroCanEvolve(arg_243_0)
	local var_243_0 = arg_243_0.hero

	if not xyd.isSuperHero(var_243_0) then
		if var_243_0:getStar() >= xyd.MAX_STAR_LEVEL or var_243_0:getSuiPian() < xyd.StarLevelSuipian[var_243_0:getStar() + 1] then
			return false
		end
	elseif var_243_0:getStar() <= xyd.MAX_STAR_LEVEL or var_243_0:getStar() >= xyd.SUPER_HERO_TOTAL_STARS or var_243_0:getSuiPian() < xyd.StarLevelSuipian[var_243_0:getStar() + 1] then
		return false
	end

	return true
end

function var_0_7.isHeroCanBreach(arg_244_0)
	local var_244_0 = arg_244_0.hero:getEvoStage()
	local var_244_1 = var_0_23:level(var_244_0 + 1)
	local var_244_2 = var_0_23:star(var_244_0 + 1)

	if arg_244_0:getEvoProgress() >= 1 and var_244_0 < var_0_23:getMaxStage() and var_244_1 <= arg_244_0.hero:getLevel() and var_244_2 <= arg_244_0.hero:getStar() then
		return true
	else
		return false
	end
end

function var_0_7.clickJinhuaButton(arg_245_0)
	if arg_245_0.sendSkillLevUpRequest then
		arg_245_0:sendSkillLevUpRequest()
	end

	local var_245_0 = arg_245_0.hero

	if not arg_245_0:isHeroCanEvolve() then
		return
	end

	if var_245_0:getStar() >= xyd.MAX_STAR_LEVEL then
		return
	end

	local var_245_1 = var_245_0:getStar()
	local var_245_2 = xyd.tables.star:evolvePrice(var_245_0:getStar() + 1)

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
		string.format(var_0_21:translation("EVOLVE_PRICE"), var_245_2)
	}, function()
		if var_245_2 > arg_245_0.selfPlayer.mana then
			arg_245_0.giftPush:judgePush(4)
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_0_21:translation("JINBI_ABSENCE")
			}, function()
				local var_247_0 = xyd.FunctionID.ID_GOLD_HAND

				if arg_245_0.selfPlayer:isFuncOpen(var_247_0) == true then
					xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
				else
					local var_247_1 = xyd.tables.functionOpen:level(var_247_0)
					local var_247_2 = string.format(var_0_21:translation("FUNCTION_OPEN_TIP_LEVEL"), var_247_1)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_247_2
					})
				end
			end)
		else
			var_245_0:evolution(function(arg_248_0, arg_248_1)
				if arg_248_0 == xyd.error.OK then
					local var_248_0 = {}

					table.insert(var_248_0, var_0_19:getHeroMainAttr(var_245_0:getTableID(), 1, var_245_0:getStar(), var_245_0:getLevel()) - var_0_19:getHeroMainAttr(var_245_0:getTableID(), 1, var_245_0:getStar() - 1, var_245_0:getLevel()))
					table.insert(var_248_0, var_0_19:getHeroMainAttr(var_245_0:getTableID(), 1, var_245_0:getStar(), var_245_0:getLevel()) - var_0_19:getHeroMainAttr(var_245_0:getTableID(), 2, var_245_0:getStar() - 1, var_245_0:getLevel()))
					table.insert(var_248_0, var_0_19:getHeroMainAttr(var_245_0:getTableID(), 1, var_245_0:getStar(), var_245_0:getLevel()) - var_0_19:getHeroMainAttr(var_245_0:getTableID(), 3, var_245_0:getStar() - 1, var_245_0:getLevel()))

					local var_248_1 = arg_245_0:getHeroModel()

					arg_245_0.isShow = true

					arg_245_0:updateAttrScore()
					arg_245_0:updateHeroStar()
					arg_245_0:updateCard()
					arg_245_0:updateAttrLabels()
					arg_245_0:updateIntroduceText()
					arg_245_0:updateScrollBg()
					arg_245_0:updateCollectWindow()
					arg_245_0:updateNameLabel()
					arg_245_0:playRepeatingEffect()
					arg_245_0:updateBtnShow()
					arg_245_0:updateBreachStoneType()
					audio.playSound(xyd.tables.sound:getSound("hero_upstar"))
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.HERO_CELL_REFRESH,
						tableID = var_245_0:getTableID()
					})

					local var_248_2 = {
						type_ = xyd.LevelUpType.EVOLVE,
						hero = var_245_0,
						vals = {
							oldStar = var_245_1,
							newStar = var_245_1 + 1,
							oldColor = var_245_0:getColor()
						},
						callback = function()
							local var_249_0 = cc.p(arg_245_0:getHeroContainer():getPosition())
							local var_249_1 = arg_245_0:getHeroContainer():getContentSize()

							var_249_0.x = var_249_0.x + var_249_1.width * 0.5
							var_249_0.y = var_249_0.y + var_249_1.height * 0.5

							arg_245_0:playEffect(arg_245_0.mainContainer, "Evolve", var_249_0, true)
							var_248_1:win(false, handler(arg_245_0, arg_245_0.setIsShow))
							var_248_1:playAttribute(arg_245_0:getFloatAttrs(var_248_0))
						end
					}

					xyd.WindowManager.get():openWindow("levelup", var_248_2)

					local var_248_3 = xyd.WindowManager.get():getWindow("super_partner")

					if var_248_3 and not tolua.isnull(var_248_3) then
						var_248_3:updateViews()
					end
				end
			end)
		end
	end, nil, 0)
end

function var_0_7.clickUpgradeButton(arg_250_0)
	local var_250_0 = arg_250_0.hero
	local var_250_1 = var_250_0:getStar()
	local var_250_2 = xyd.tables.superPartnerStar:manaCost(var_250_0:getStar() + 1)

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
		string.format(var_0_21:translation("EVOLVE_PRICE"), var_250_2)
	}, function()
		if var_250_2 > arg_250_0.selfPlayer.mana then
			arg_250_0.giftPush:judgePush(4)
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_0_21:translation("JINBI_ABSENCE")
			}, function()
				local var_252_0 = xyd.FunctionID.ID_GOLD_HAND

				if arg_250_0.selfPlayer:isFuncOpen(var_252_0) == true then
					xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
				else
					local var_252_1 = xyd.tables.functionOpen:level(var_252_0)
					local var_252_2 = string.format(var_0_21:translation("FUNCTION_OPEN_TIP_LEVEL"), var_252_1)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_252_2
					})
				end
			end)
		else
			var_250_0:evolution(function(arg_253_0, arg_253_1)
				if arg_253_0 == xyd.error.OK then
					local var_253_0 = {}

					table.insert(var_253_0, var_0_19:getHeroMainAttr(var_250_0:getTableID(), 1, var_250_0:getStar(), var_250_0:getLevel()) - var_0_19:getHeroMainAttr(var_250_0:getTableID(), 1, var_250_0:getStar() - 1, var_250_0:getLevel()))
					table.insert(var_253_0, var_0_19:getHeroMainAttr(var_250_0:getTableID(), 1, var_250_0:getStar(), var_250_0:getLevel()) - var_0_19:getHeroMainAttr(var_250_0:getTableID(), 2, var_250_0:getStar() - 1, var_250_0:getLevel()))
					table.insert(var_253_0, var_0_19:getHeroMainAttr(var_250_0:getTableID(), 1, var_250_0:getStar(), var_250_0:getLevel()) - var_0_19:getHeroMainAttr(var_250_0:getTableID(), 3, var_250_0:getStar() - 1, var_250_0:getLevel()))

					local var_253_1 = arg_250_0:getHeroModel()

					arg_250_0.isShow = true

					arg_250_0:updateEquip()
					arg_250_0:updateAttrScore()
					arg_250_0:updateHeroStar()
					arg_250_0:updateCard()
					arg_250_0:updateAttrLabels()
					arg_250_0:updateIntroduceText()
					arg_250_0:updateScrollBg()
					arg_250_0:updateCollectWindow()
					arg_250_0:updateNameLabel()
					arg_250_0:playRepeatingEffect()
					arg_250_0:updateBtnShow()
					arg_250_0:updateSuperHero()
					arg_250_0:updateBreachStoneType()
					audio.playSound(xyd.tables.sound:getSound("hero_upstar"))
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.HERO_CELL_REFRESH,
						tableID = var_250_0:getTableID()
					})

					local var_253_2 = {
						type_ = xyd.LevelUpType.EVOLVE,
						hero = var_250_0,
						vals = {
							oldStar = var_250_1,
							newStar = var_250_1 + 1
						},
						callback = function()
							local var_254_0 = cc.p(arg_250_0:getHeroContainer():getPosition())
							local var_254_1 = arg_250_0:getHeroContainer():getContentSize()

							var_254_0.x = var_254_0.x + var_254_1.width * 0.5
							var_254_0.y = var_254_0.y + var_254_1.height * 0.5

							arg_250_0:playEffect(arg_250_0.mainContainer, "Evolve", var_254_0, true)
							var_253_1:win(false, handler(arg_250_0, arg_250_0.setIsShow))
							var_253_1:playAttribute(arg_250_0:getFloatAttrs(var_253_0))
						end
					}

					xyd.WindowManager.get():openWindow("levelup", var_253_2)

					local var_253_3 = xyd.WindowManager.get():getWindow("super_partner")

					if var_253_3 and not tolua.isnull(var_253_3) then
						var_253_3:updateViews()
					end
				end
			end)
		end
	end, nil, 0)
end

function var_0_7.clickJinjieButton(arg_255_0)
	if arg_255_0.sendSkillLevUpRequest then
		arg_255_0:sendSkillLevUpRequest()
	end

	local var_255_0 = arg_255_0.hero
	local var_255_1 = cc.p(arg_255_0:getHeroContainer():getPosition())
	local var_255_2 = arg_255_0:getHeroContainer():getContentSize()

	var_255_1.x = var_255_1.x + var_255_2.width * 0.5
	var_255_1.y = var_255_1.y + var_255_2.height * 0.5

	local var_255_3 = var_255_0:getColor()
	local var_255_4 = var_255_0:getStar()
	local var_255_5 = var_255_0:getMaxHP()
	local var_255_6 = var_255_0:getZhandouli()

	local function var_255_7()
		var_255_0:powerUp(function(arg_257_0, arg_257_1)
			if arg_257_0 == xyd.error.OK then
				local var_257_0 = arg_255_0:getHeroModel()

				for iter_257_0 = 1, xyd.MAX_ITEM_NUM do
					if var_255_0:getEquipByIndex(iter_257_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_255_0:getEquipByIndex(iter_257_0):getTableID()) == 0 and not var_255_0:isLastColorHasAwakeItem() and xyd.tables.item:isAwakenItem(var_255_0:getEquipByIndex(iter_257_0):getTableID()) == 1 then
						local var_257_1 = arg_255_0:getEquipContainerByIndex(iter_257_0)
						local var_257_2 = display.newNode()

						var_257_2:size(var_257_1:getWidth(), var_257_1:getHeight())

						local var_257_3 = var_255_0:getEquipByIndex(iter_257_0, var_255_0:getColor() - 1)
						local var_257_4, var_257_5 = arg_255_0:nodeByName("normal_equipment"):getPosition()

						xyd.setSpecialItemBorderNewUI(var_257_2, var_257_3:getTableID())
						var_257_2:addTo(arg_255_0.mainContainer, 101)
						var_257_2:pos(var_257_1:getPositionX() + var_257_4, var_257_1:getPositionY() + var_257_5)

						local var_257_6, var_257_7 = arg_255_0:getHeroContainer():getPosition()
						local var_257_8 = var_257_6 + arg_255_0:getHeroContainer():getWidth() / 2
						local var_257_9 = var_257_0.chestPoint.x + var_257_8
						local var_257_10 = var_257_7 + var_257_0.chestPoint.y
						local var_257_11 = cc.Spawn:create(cc.ScaleTo:create(0.8, 0.1), cc.MoveTo:create(0.8, cc.p(var_257_9, var_257_10)))

						var_257_2:runActionOnce(var_257_11, true)
					end
				end

				local var_257_12 = {}

				table.insert(var_257_12, xyd.JINJIE_ATTR_RATE * (var_255_0:getColor() - 1))
				table.insert(var_257_12, xyd.JINJIE_ATTR_RATE * (var_255_0:getColor() - 1))
				table.insert(var_257_12, xyd.JINJIE_ATTR_RATE * (var_255_0:getColor() - 1))

				arg_255_0.isShow = true

				arg_255_0:updateEquip()
				arg_255_0:updateAttrScore()
				arg_255_0:updateAttrLabels()
				arg_255_0:updateIntroduceText()
				arg_255_0:updateScrollBg()
				arg_255_0:updateCollectWindow()
				arg_255_0:updateNameLabel()
				arg_255_0:updateEquipInfoContainer()
				arg_255_0:setSkillContainer()
				arg_255_0:playRepeatingEffect()
				arg_255_0:CheckOneClick()
				audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.HERO_CELL_REFRESH,
					tableID = var_255_0:getTableID()
				})

				local var_257_13 = var_255_0:getMaxHP()
				local var_257_14 = var_255_0:getZhandouli()
				local var_257_15 = {
					type_ = xyd.LevelUpType.ADVANCE,
					hero = var_255_0,
					vals = {
						oldStar = var_255_4,
						oldColor = var_255_3,
						newColor = var_255_3 + 1,
						oldHP = var_255_5,
						newHP = var_257_13,
						oldForce = var_255_6,
						newForce = var_257_14
					},
					callback = function()
						arg_255_0:playEffect(arg_255_0.mainContainer, "Upgrade", var_255_1, true)
						var_257_0:win(false, handler(arg_255_0, arg_255_0.setIsShow))
						var_257_0:playAttribute(arg_255_0:getFloatAttrs(var_257_12))
					end
				}

				if arg_257_1.restore_items and #arg_257_1.restore_items > 0 then
					function var_257_15.callback()
						xyd.WindowManager.get():openWindow("alert_award", {
							awards = arg_257_1.restore_items,
							name = var_0_21:translation("FUMO_RESTORE_NAME")
						})
						arg_255_0:playEffect(arg_255_0.mainContainer, "Upgrade", var_255_1, true)
						var_257_0:win(false, handler(arg_255_0, arg_255_0.setIsShow))
						var_257_0:playAttribute(arg_255_0:getFloatAttrs(var_257_12))
					end

					for iter_257_1 = 1, #arg_257_1.restore_items do
						local var_257_16 = {
							itemID = arg_257_1.restore_items[iter_257_1].table_id,
							itemNum = arg_257_1.restore_items[iter_257_1].item_num
						}

						arg_255_0.selfPlayer:getBackpack():addItem(var_257_16)
					end
				end

				arg_255_0:runActionOnce(cc.CallFunc:create(function()
					xyd.WindowManager.get():openWindow("levelup", var_257_15)
				end), nil, nil, 1)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_21:translation("CANNOT_EVOLVE")
				})
			end
		end)
	end

	local var_255_8 = true

	for iter_255_0 = 1, xyd.MAX_ITEM_NUM do
		if var_255_0:getEquipByIndex(iter_255_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_255_0:getEquipByIndex(iter_255_0):getTableID()) == 0 and var_255_0.equips_[iter_255_0] == 0 then
			var_255_8 = false

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_21:translation("CANNOT_EVOLVE")
			})

			break
		end
	end

	if xyd.isSuperHero(var_255_0) or var_255_0:getColor() == xyd.MAX_HERO_COLOR then
		var_255_8 = false

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_21:translation("CANNOT_EVOLVE")
		})
	end

	if var_255_8 then
		if var_255_0:getFumoCount() > 0 and not var_255_0:isHaveAwakenItem() or var_255_0:getWithoutAwakeFumoCount() > 0 and var_255_0:isHaveAwakenItem() then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				string.format(var_0_21:translation("ALERT_POWER_UP1"), var_255_0:getName()),
				var_0_21:translation("ALERT_POWER_UP2")
			}, function()
				var_255_7()
			end)
		else
			var_255_7()
		end
	end
end

function var_0_7.updateSkillItem(arg_262_0, arg_262_1, arg_262_2)
	if not arg_262_0.cache[var_0_33.Skill] then
		return
	end

	local var_262_0 = arg_262_0.hero

	for iter_262_0, iter_262_1 in ipairs(arg_262_0.skillItems) do
		local var_262_1 = arg_262_0.skillItems[iter_262_0]

		if not tolua.isnull(var_262_1) then
			if var_262_0:getSkillLevel(iter_262_0) then
				local var_262_2 = var_262_0:getSkillLevel(iter_262_0) - xyd.SKILL_EXTRA[iter_262_0]

				var_262_1:getChildByName("lev"):setString("lv. " .. var_262_2)

				if var_262_0:getExtraSkillLevel() > 0 then
					var_262_1:getChildByName("level_extra"):show()
					var_262_1:getChildByName("level_extra"):setString("+" .. var_262_0:getExtraSkillLevel())
				else
					var_262_1:getChildByName("level_extra"):hide()
				end

				var_262_1:getChildByName("jiesuo"):setVisible(false)

				local var_262_3 = arg_262_0:getSkillUpgradeDiscount()
				local var_262_4 = xyd.isSuperHero(var_262_0) and xyd.tables.skillPrice:gold(var_262_0:getSkillLevel(iter_262_0)) * var_262_3 * 10 or xyd.tables.skillPrice:gold(var_262_0:getSkillLevel(iter_262_0)) * var_262_3

				var_262_1:getChildByName("gold_text"):setString(var_262_4)

				if var_262_4 > arg_262_0.selfPlayer.mana then
					var_262_1:getChildByName("gold_text"):setColor(cc.c4b(255, 0, 0, 255))
				else
					var_262_1:getChildByName("gold_text"):setColor(cc.c4b(13, 66, 128, 255))
				end
			else
				local var_262_5 = arg_262_0:getFilteredSkinItemIds()[1]

				if not xyd.tables.skinSkill:getSkillID(var_262_5) or iter_262_0 ~= #arg_262_0.skillItems then
					local var_262_6 = var_0_21:translation("HERO_JIESUO_" .. iter_262_0)
					local var_262_7 = var_262_1.id
					local var_262_8 = xyd.tables.skill
					local var_262_9 = var_262_8:isAwakenSkill(var_262_7) > 0
					local var_262_10 = var_262_8:isAwakeTwiceSkill(var_262_7) > 0

					if var_262_9 then
						var_262_6 = var_0_21:translation("AWAKE_SKILL_LOCK_TIP")
					elseif var_262_10 then
						var_262_6 = var_0_21:translation("AWAKE_TWICE_SKILL_LOCK_TIP")
					elseif var_262_1.isSkinSkill then
						var_262_6 = var_0_21:translation("skin_skill")
					end

					var_262_1:getChildByName("jiesuo"):setString(var_262_6)
					var_262_1:getChildByName("lev"):setVisible(false)
					var_262_1:getChildByName("level_extra"):hide()
					var_262_1:getChildByName("gold_text"):setVisible(false)
					var_262_1:getChildByName("small_mana"):setVisible(false)
				end
			end
		end
	end

	if not arg_262_2 and arg_262_1 then
		local var_262_11 = arg_262_0.skillItems[arg_262_1]

		if not tolua.isnull(var_262_11) then
			local var_262_12 = var_262_11:getChildByName("jiadian")

			if not var_262_0:getSkillLevel(arg_262_1) or var_262_0:getSkillLevel(arg_262_1) >= var_262_0:getLevel() + var_262_0:getBookShelfSkillLevel() then
				var_262_12:setButtonEnabled(false)
			else
				var_262_12:setButtonEnabled(true)
			end
		end
	end
end

function var_0_7.showItemDetail(arg_263_0, arg_263_1, arg_263_2, arg_263_3)
	local var_263_0

	if xyd.isSuperHero(arg_263_0.hero) then
		var_263_0 = xyd.WindowManager.get():openWindow("super_equip_confirm", {
			hero = arg_263_0.hero,
			item_index = arg_263_1,
			color = arg_263_2,
			state = arg_263_3
		})
	else
		var_263_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.equipConfirmWnd, {
			hero = arg_263_0.hero,
			item_index = arg_263_1,
			color = arg_263_2,
			state = arg_263_3
		})
	end

	cc.EventProxy.new(var_263_0, var_263_0):addEventListener(xyd.event.HERO_EQUIP_CHANGED, function(arg_264_0)
		arg_263_0:playEffect(arg_263_0:nodeByName("normal_equipment"), "AddItem", cc.p(arg_263_0:getEquipContainerByIndex(arg_263_1):getPosition()), true)

		local var_264_0 = arg_263_0.hero:getEquipByIndexShow(arg_263_1)
		local var_264_1 = arg_263_0:getHeroModel()

		arg_263_0.isShow = true

		var_264_1:win(false, handler(arg_263_0, arg_263_0.setIsShow))
		var_264_1:playAttribute(var_264_0:getAttrFloat(arg_263_0.hero:getHeroType()))
		arg_263_0:updateEquip()
		arg_263_0:playRepeatingEffect()
		arg_263_0:updateAttrScore()
		arg_263_0:updateAttrLabels()
		arg_263_0:updateIntroduceText()
		arg_263_0:updateScrollBg()
		xyd.WindowManager.get():closeWindow(xyd.WindowName.equipConfirmWnd)
		xyd.WindowManager.get():closeWindow("super_equip_confirm")
		xyd.WindowManager.get():closeWindow("super_equip_enhance")
		xyd.WindowManager.get():closeWindow(xyd.WindowName.itemComposeWnd)
		arg_263_0:updateCollectWindow()
		arg_263_0:updateSkillItem(nil, false)
		arg_263_0.selfPlayer:checkEquipableAndSummon()
		audio.playSound(xyd.tables.sound:getSound("hero_equip"))
		arg_263_0:CheckOneClick()
		arg_263_0:updateSuperHero()
	end)
end

function var_0_7.playEnhance(arg_265_0, arg_265_1, arg_265_2)
	local var_265_0 = arg_265_0:getHeroModel()

	arg_265_0.isShow = true

	var_265_0:win(false, handler(arg_265_0, arg_265_0.setIsShow))
	var_265_0:playAttribute(arg_265_1:getEquipAttrFloat(arg_265_0.hero:getHeroType(), arg_265_2))
	arg_265_0:updateEquip()
	arg_265_0:playRepeatingEffect()
	arg_265_0:updateAttrScore()
	arg_265_0:updateAttrLabels()
	arg_265_0:updateIntroduceText()
	arg_265_0:updateScrollBg()
	arg_265_0:updateSuperHero()
end

function var_0_7.buttonHandler(arg_266_0, arg_266_1, arg_266_2, arg_266_3)
	if arg_266_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_266_2)
		arg_266_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound(xyd.tables.sound:getSound("ui_button_click"), false)

		if arg_266_1 then
			arg_266_1(arg_266_2, arg_266_3)
		end
	elseif arg_266_3 == ccui.TouchEventType.began then
		local var_266_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_266_1 = cc.RepeatForever:create(var_266_0)

		arg_266_2:runAction(var_266_1)

		return true
	elseif arg_266_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_266_2)
		arg_266_2:setScale(1)
	end
end

function var_0_7.willClose(arg_267_0)
	xyd.WindowManager.get():closeWindow("book_skill_tip")

	if arg_267_0.sendSkillLevUpRequest then
		arg_267_0:sendSkillLevUpRequest()
	end

	if arg_267_0.skillPoints then
		arg_267_0.timeCount = arg_267_0.timeCount or 300

		if arg_267_0.timer then
			var_0_17.unscheduleGlobal(arg_267_0.timer)

			arg_267_0.timer = nil
		end
	end

	if arg_267_0.handler[1] ~= nil then
		var_0_17.unscheduleGlobal(arg_267_0.handler[1])
	end

	if arg_267_0.handler[2] ~= nil then
		var_0_17.unscheduleGlobal(arg_267_0.handler[2])
	end

	if arg_267_0.skillTextHandle then
		var_0_17.unscheduleGlobal(arg_267_0.skillTextHandle)
	end

	if arg_267_0.skillClickHandle[1] then
		var_0_17.unscheduleGlobal(arg_267_0.skillClickHandle[1])
	end

	if arg_267_0.skillClickHandle[2] then
		var_0_17.unscheduleGlobal(arg_267_0.skillClickHandle[2])
	end

	if arg_267_0.skinHandle then
		var_0_17.unscheduleGlobal(arg_267_0.skinHandle)
	end

	arg_267_0.giftPush:cleanSceneCondition(28)
	arg_267_0.giftPush:cleanSceneCondition(36)
end

function var_0_7.getHeroContainer(arg_268_0)
	if not arg_268_0.heroContainer_ then
		arg_268_0.heroContainer_ = arg_268_0:nodeByName("hero_container")

		arg_268_0.heroContainer_:setLocalZOrder(100)
	end

	return arg_268_0.heroContainer_
end

function var_0_7.updateElementEquip(arg_269_0, arg_269_1)
	arg_269_1 = arg_269_1 or arg_269_0.hero

	if not xyd.isSuperHero(arg_269_1) and not arg_269_1:getColor() == xyd.MAX_HERO_COLOR then
		return
	end

	if arg_269_0.elementEquipContainerList_ then
		for iter_269_0, iter_269_1 in ipairs(arg_269_0.elementEquipContainerList_) do
			iter_269_1:removeAllNodeEventListeners()
			iter_269_1:removeSelf()
		end

		arg_269_0.elementEquipContainerList_ = nil
	end

	for iter_269_2 = 1, xyd.MAX_ELEMENT_ITEM_NUM do
		local var_269_0 = arg_269_0:getElementEquipContainerByIndex(iter_269_2)

		var_269_0:setTouchEnabled(true)
		var_269_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_270_0)
			if arg_270_0.name == "began" then
				var_269_0:getChildByName("green_plus"):setScale(0.9)

				return true
			elseif arg_270_0.name == "ended" then
				var_269_0:getChildByName("green_plus"):setScale(1)

				local var_270_0 = {
					hero = arg_269_0.hero,
					pos = iter_269_2
				}

				xyd.WindowManager.get():openWindow("element_equip", var_270_0)
			end
		end)
	end
end

function var_0_7.updateEquip(arg_271_0, arg_271_1)
	arg_271_1 = arg_271_1 or arg_271_0.hero

	if arg_271_0.equipContainerlist_ then
		for iter_271_0, iter_271_1 in ipairs(arg_271_0.equipContainerlist_) do
			iter_271_1:removeAllNodeEventListeners()
			iter_271_1:removeSelf()
		end

		arg_271_0.equipContainerlist_ = nil
	end

	for iter_271_2 = 1, xyd.MAX_ITEM_NUM do
		local var_271_0 = arg_271_0:getEquipContainerByIndex(iter_271_2)
		local var_271_1 = arg_271_1:getEquipByIndexShow(iter_271_2)

		var_271_0:setTouchEnabled(true)

		local var_271_2
		local var_271_3
		local var_271_4

		var_271_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_272_0)
			if arg_272_0.name == "began" then
				var_271_2 = arg_272_0.x
				var_271_3 = arg_272_0.y
				var_271_4 = false

				var_271_0:getChildByName("green_plus"):scale(0.9)
				var_271_0:getChildByName("white_plus"):scale(0.9)
			elseif arg_272_0.name == "moved" then
				if math.abs(arg_272_0.x - var_271_2) > 10 or math.abs(arg_272_0.y - var_271_3) > 10 then
					var_271_4 = true

					var_271_0:getChildByName("green_plus"):scale(1)
					var_271_0:getChildByName("white_plus"):scale(1)
				end
			elseif arg_272_0.name == "ended" and not var_271_4 then
				var_271_0:getChildByName("green_plus"):scale(1)
				var_271_0:getChildByName("white_plus"):scale(1)

				if xyd.WindowManager.get():isWindowOpen("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end

				if iter_271_2 == 5 and xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_EQUIP_TWO then
					arg_271_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HERO_ITEM)
				end

				if var_271_1:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_271_1:getTableID()) == 0 then
					arg_271_0:showItemDetail(iter_271_2)
				elseif not arg_271_1:isAwaken() and not arg_271_0.task:isAwaking(arg_271_1:getTableID(), xyd.AwakeType.HERO) then
					arg_271_0:openAwakeMission(arg_271_1, var_271_1)
				elseif not arg_271_0.task:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE) and arg_271_1:canOpenAwakeTwiceMission() then
					arg_271_0:openAwakeTwiceMission(arg_271_1, var_271_1)
				else
					arg_271_0:showItemDetail(iter_271_2)
				end
			end

			return true
		end)
	end
end

function var_0_7.openAwakeTwiceMission(arg_273_0, arg_273_1, arg_273_2)
	local var_273_0 = xyd.tables.mission
	local var_273_1 = arg_273_0.task:isActiveAwake(arg_273_1:getTableID(), xyd.AwakeType.HERO) or var_273_0:getMissionIDByTableIDAndStage(arg_273_1:getTableID(), 1)

	local function var_273_2()
		arg_273_0.task:openAwakeTask(var_273_1, xyd.AwakeType.HERO_TWICE, function(arg_275_0)
			if arg_275_0 == xyd.error.OK then
				local var_275_0 = xyd.WindowManager.get():getWindow("hero_main")

				if var_275_0 then
					var_275_0:update()
				end
			end
		end)
	end

	local var_273_3 = {
		txt = string.format(var_0_21:translation("AWAKE_TWICE_ALERT_TXT"), xyd.tables.hero:name(arg_273_0.hero:getTableID())),
		type = xyd.CommonAlertType.TWO_BTN,
		rcallback = var_273_2,
		align = xyd.ui_align.CENTER
	}

	xyd.WindowManager.get():openWindow("common_alert", var_273_3)
end

function var_0_7.openAwakeMission(arg_276_0, arg_276_1, arg_276_2)
	local var_276_0 = arg_276_0.task:isAwaking(arg_276_1:getTableID(), xyd.AwakeType.HERO) or xyd.tables.mission:getMissionIDByTableIDAndStage(arg_276_1:getTableID(), 1)

	local function var_276_1()
		arg_276_0.task:openAwakeTask(var_276_0, xyd.AwakeType.HERO, function(arg_278_0)
			if arg_278_0 == xyd.error.OK then
				local var_278_0 = xyd.WindowManager.get():getWindow("hero_main")

				if var_278_0 then
					var_278_0:update()
				end

				if xyd.WindowManager.get():getWindow("hero_list") then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.HERO_LIST_REFRESH
					})
				end
			end
		end)
	end

	if arg_276_1:getLevel() < xyd.tables.misc.awakenOpenLev then
		local var_276_2 = {
			txt = var_0_21:translation("AWAKE_CAN_NOT_OPEN"),
			type = xyd.CommonAlertType.ONE_BTN,
			align = xyd.ui_align.CENTER
		}

		xyd.WindowManager.get():openWindow("common_alert", var_276_2)
	elseif arg_276_2:getTableID() == 0 or xyd.tables.hero:isCanAwaken(arg_276_1:getTableID()) == 0 and xyd.tables.item:isAwakenItem(arg_276_2:getTableID()) == 1 then
		local var_276_3 = {
			txt = var_0_21:translation("AWAKE_MISSION_NOT_EXIST"),
			type = xyd.CommonAlertType.ONE_BTN,
			align = xyd.ui_align.CENTER
		}

		xyd.WindowManager.get():openWindow("common_alert", var_276_3)
	elseif arg_276_0.task:isHasAwakeOpen(xyd.AwakeType.HERO) then
		local var_276_4 = {
			txt = var_0_21:translation("CAN_NOT_OPEN_AWAKE_MISSION"),
			type = xyd.CommonAlertType.ONE_BTN,
			align = xyd.ui_align.CENTER
		}

		xyd.WindowManager.get():openWindow("common_alert", var_276_4)
	elseif arg_276_0.task:isActiveAwake(arg_276_1:getTableID(), xyd.AwakeType.HERO) then
		local var_276_5 = arg_276_0.task:getTaskList(xyd.TaskType.AWAKE)
		local var_276_6 = false

		for iter_276_0, iter_276_1 in pairs(var_276_5) do
			if iter_276_1.table_id == var_276_0 then
				var_276_6 = true

				break
			end
		end

		var_276_0 = var_276_0 and (not var_276_6 and xyd.tables.mission:getMissionIDByTableIDAndStage(arg_276_1:getTableID(), 2) or var_276_0)

		local var_276_7 = {
			txt = string.format(var_0_21:translation("OPEN_AWAKE_MISSION_AGAIN"), arg_276_1:getName()),
			type = xyd.CommonAlertType.TWO_BTN,
			align = xyd.ui_align.CENTER,
			rcallback = var_276_1
		}

		xyd.WindowManager.get():openWindow("common_alert", var_276_7)
	else
		local var_276_8 = {
			txt = string.format(var_0_21:translation("FIRST_TIME_OPEN_AWAKE_MISSION"), arg_276_1:getName()),
			type = xyd.CommonAlertType.TWO_BTN,
			align = xyd.ui_align.CENTER,
			rcallback = var_276_1
		}

		xyd.WindowManager.get():openWindow("common_alert", var_276_8)
	end
end

function var_0_7.getElementEquipContainerByIndex(arg_279_0, arg_279_1)
	local var_279_0 = arg_279_0.hero

	if not xyd.isSuperHero(var_279_0) and not var_279_0:getColor() == xyd.MAX_HERO_COLOR then
		return
	end

	if arg_279_0.elementEquipContainerList_ then
		return arg_279_0.elementEquipContainerList_[arg_279_1]
	else
		local var_279_1 = {
			xyd.ItemType.ELEMENT_EQUIP
		}
		local var_279_2 = arg_279_0.backpack:getItemsByTypes(var_279_1)
		local var_279_3 = false
		local var_279_4 = false

		if var_279_2 and next(var_279_2) then
			for iter_279_0 = 1, #var_279_2 do
				if var_279_3 and var_279_4 then
					break
				end

				local var_279_5 = var_279_2[iter_279_0].itemID

				if var_0_18:equipType(var_279_5) == xyd.ElementEquipType.NORMAL then
					var_279_4 = true
				elseif var_0_18:equipType(var_279_5) == xyd.ElementEquipType.CORE then
					var_279_3 = true
				elseif var_0_18:equipType(var_279_5) == xyd.ElementEquipType.SP_CORE and var_0_18:partnerID(var_279_5) == arg_279_0.hero:getFirstTableID() then
					var_279_3 = true
				end
			end
		end

		local var_279_6 = arg_279_0.hero:getElementBindingEquips()

		if var_279_6 and next(var_279_6) then
			for iter_279_1 = 1, #var_279_6 do
				if var_279_3 and var_279_4 then
					break
				end

				local var_279_7 = var_0_18:itemID(var_279_6[iter_279_1])

				if var_0_18:equipType(var_279_7) == xyd.ElementEquipType.NORMAL then
					var_279_4 = true
				else
					var_279_3 = true
				end
			end
		end

		arg_279_0.elementEquipContainerList_ = {}

		local var_279_8, var_279_9 = var_279_0:getElementEquips()

		for iter_279_2 = 1, xyd.MAX_ELEMENT_ITEM_NUM do
			local var_279_10 = arg_279_0:nodeByName("element_node_" .. iter_279_2)
			local var_279_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/element_equip.csb")
			local var_279_12 = var_279_11:getChildByName("gray_label")

			var_279_11:setContentSize(var_279_11:getChildByName("background"):getContentSize())
			var_279_11:setAnchorPoint(cc.p(0.5, 0.5))
			var_279_11:setPosition(var_279_10:getPosition())
			var_279_11:addTo(arg_279_0:nodeByName("element_equipment"), var_279_10:getLocalZOrder())
			table.insert(arg_279_0.elementEquipContainerList_, var_279_11)
			var_279_12:setString(var_0_21:translation("ELEMENT_EQUIP_TEXT17"))
			var_279_12:enableOutline(cc.c4b(84, 110, 123, 255), 2)

			if iter_279_2 == 1 then
				var_279_11:getChildByName("bg2"):setVisible(false)
			else
				var_279_11:getChildByName("bg1"):setVisible(false)
			end

			if var_279_8 and var_279_8[iter_279_2] ~= 0 then
				var_279_11:getChildByName("bg1"):setVisible(false)
				var_279_11:getChildByName("bg2"):setVisible(false)

				local var_279_13 = tonumber(var_279_8[iter_279_2])
				local var_279_14 = var_0_18:itemID(var_279_13)
				local var_279_15 = var_279_11:getChildByName("icon")
				local var_279_16 = var_279_11:getChildByName("bg_element_lv")

				xyd.setSpecialItemBorderNewUI(var_279_15, var_279_14)

				local var_279_17 = var_279_9[iter_279_2]

				if var_279_17 ~= 0 then
					var_279_16:setVisible(true)
					var_279_16:getChildByName("txt_lv"):setString(var_279_17)
					var_279_16:getChildByName("txt_lv"):enableOutline(cc.c4b(84, 110, 123, 255), 2)
				end

				var_279_11:getChildByName("green_plus"):setVisible(false)
				var_279_11:getChildByName("yellow_plus"):setVisible(false)
				var_279_12:setVisible(false)

				local var_279_18 = var_0_18:element(var_279_14)
				local var_279_19 = var_0_18:equipType(var_279_14)
				local var_279_20

				if var_279_19 == xyd.ElementEquipType.SP_CORE then
					var_279_20 = var_279_11:getChildByName("icon" .. var_279_18 .. "_2")
				else
					var_279_20 = var_279_11:getChildByName("icon" .. var_279_18 .. "_1")
				end

				var_279_20:setVisible(true)

				if arg_279_0.hero:getElementEquipActiveRate(var_279_14) > 1 or var_279_19 == xyd.ElementEquipType.SP_CORE then
					arg_279_0:addActiveEffeft(var_279_20, var_279_18, 1, true)
				end
			elseif iter_279_2 == 1 then
				if var_279_3 then
					var_279_11:getChildByName("yellow_plus"):setVisible(false)
				else
					var_279_11:getChildByName("green_plus"):setVisible(false)
					var_279_12:setVisible(false)
				end
			elseif var_279_4 then
				var_279_11:getChildByName("yellow_plus"):setVisible(false)
			else
				var_279_11:getChildByName("green_plus"):setVisible(false)
				var_279_12:setVisible(false)
			end
		end

		return arg_279_0.elementEquipContainerList_[arg_279_1]
	end
end

function var_0_7.getEquipContainerByIndex(arg_280_0, arg_280_1)
	local var_280_0 = arg_280_0.hero

	if not arg_280_0.equipContainerlist_ then
		arg_280_0.equipContainerlist_ = {}

		for iter_280_0 = 1, xyd.MAX_ITEM_NUM do
			local var_280_1 = arg_280_0:nodeByName("pos_node" .. iter_280_0)
			local var_280_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/equip.csb")

			var_280_2:setContentSize(var_280_2:getChildByName("background"):getContentSize())

			local var_280_3 = var_280_2:getChildByName("green_plus")
			local var_280_4 = var_280_2:getChildByName("white_plus")
			local var_280_5 = var_280_2:getChildByName("green_label")
			local var_280_6 = var_280_2:getChildByName("gray_label")
			local var_280_7 = var_280_2:getChildByName("arrow")

			var_280_3:setVisible(false)
			var_280_4:setVisible(false)
			var_280_6:setVisible(false)
			var_280_6:enableOutline(cc.c4b(0, 0, 0, 255), 2)
			var_280_5:setVisible(false)
			var_280_5:enableOutline(cc.c4b(0, 0, 0, 255), 2)
			var_280_7:setVisible(false)
			var_280_2:setName("equip_container" .. iter_280_0)
			var_280_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_280_2:setPosition(var_280_1:getPosition())
			var_280_2:addTo(arg_280_0:nodeByName("normal_equipment"), var_280_1:getLocalZOrder())
			table.insert(arg_280_0.equipContainerlist_, var_280_2)

			local var_280_8 = var_280_0:getEquipByIndexShow(iter_280_0)

			if not var_280_8:isCollected() and (var_280_8:getTableID() == 0 or xyd.tables.item:isAwakenItem(var_280_8:getTableID()) == 1) and not var_280_0:isAwaken() and not arg_280_0.task:isAwaking(var_280_0:getTableID(), xyd.AwakeType.HERO) then
				var_280_2:getChildByName("awake_equip_hide"):setVisible(true)
				var_280_2:getChildByName("awake_hide"):setVisible(true)

				if not arg_280_0.task:isHasAwakeOpen(xyd.AwakeType.HERO) and xyd.tables.hero:isCanAwaken(var_280_0:getTableID()) == 1 and var_280_0:getLevel() >= xyd.tables.misc.awakenOpenLev then
					local var_280_9 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new.json"
					local var_280_10 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new.atlas"

					arg_280_0.awakeEffect = var_0_29.new(var_280_9, var_280_10, 1)

					arg_280_0.awakeEffect:addTo(var_280_2)
					arg_280_0.awakeEffect:setPosition(var_280_2:getWidth() / 2, var_280_2:getHeight() / 2)
					arg_280_0.awakeEffect:play(nil, true)
					arg_280_0.awakeEffect:setName("awake_effect")
				end
			else
				var_280_2:getChildByName("awake_equip_hide"):setVisible(false)
				var_280_2:getChildByName("awake_hide"):setVisible(false)

				local var_280_11 = var_280_8:getFumoLev()
				local var_280_12 = var_280_2:getChildByName("icon")

				if xyd.isSuperHero(var_280_0) then
					xyd.setSpecialItemBorderNewUI(var_280_12, var_280_8:getTableID(), not var_280_8:isCollected(), var_280_0:getEquipLevel(iter_280_0))

					if var_280_8:getSelfNum() >= xyd.tables.superEquipEnhance:needNum(math.ceil((var_280_0:getEquipLevel(iter_280_0) + 1) / 10)) and var_280_0:getEquipLevel(iter_280_0) < xyd.tables.superPartnerStar:equipLimit(var_280_0:getStar()) and var_280_8:isCollected() then
						local var_280_13 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new.json"
						local var_280_14 = "skeletons/ui_effect/effect_awaken_item/effect_awaken_item_new.atlas"

						arg_280_0.emhanceEffect = var_0_29.new(var_280_13, var_280_14, 1)

						arg_280_0.emhanceEffect:addTo(var_280_2)
						arg_280_0.emhanceEffect:setPosition(var_280_2:getWidth() / 2, var_280_2:getHeight() / 2)
						arg_280_0.emhanceEffect:play(nil, true)
						arg_280_0.emhanceEffect:setName("awake_effect")
						var_280_7:setVisible(true)
						var_280_5:setString(var_0_21:translation("HERO_MAIN_TEXT_56"))
						var_280_5:setVisible(true)
					end
				else
					xyd.setSpecialItemBorderNewUI(var_280_12, var_280_8:getTableID(), not var_280_8:isCollected())

					local var_280_15 = xyd.getBorder(var_0_20:quality(var_280_8:getTableID()))

					xyd.displaySpriteOnContainer(var_280_15, var_280_12, true)
				end

				if not var_280_8:isCollected() and var_280_8:isInBackpack() and var_280_0:getLevel() >= var_280_8:getLevel() then
					var_280_3:setVisible(true)
					var_280_5:setString(var_0_21:translation("HERO_MAIN_HAVE_ITEM"))
					var_280_5:setVisible(true)
				elseif not var_280_8:isCollected() and var_280_8:isInBackpack() and var_280_0:getLevel() < var_280_8:getLevel() then
					var_280_4:setVisible(true)
					var_280_6:setString(var_0_21:translation("HERO_MAIN_NO_EQUIP"))
					var_280_6:setVisible(true)
				elseif not var_280_8:isCollected() and not var_280_8:isInBackpack() and var_280_8:isHasMaterial() and var_280_0:getLevel() >= var_280_8:getLevel() then
					var_280_3:setVisible(true)
					var_280_5:setString(var_0_21:translation("HERO_MAIN_CAN_COMPOSE"))
					var_280_5:setVisible(true)
				elseif not var_280_8:isCollected() and not var_280_8:isInBackpack() and var_280_8:isHasMaterial() and var_280_0:getLevel() < var_280_8:getLevel() then
					var_280_4:setVisible(true)
					var_280_6:setString(var_0_21:translation("HERO_MAIN_CAN_COMPOSE"))
					var_280_6:setVisible(true)
				elseif not var_280_8:isCollected() and not var_280_8:isInBackpack() and not var_280_8:isHasMaterial() then
					var_280_6:setString(var_0_21:translation("HERO_MAIN_NO_ITEM"))
					var_280_6:setVisible(true)
				end

				for iter_280_1 = xyd.MAX_STAR_LEVEL, var_280_11 + 1, -1 do
					var_280_2:getChildByName("blue_star" .. iter_280_1):setVisible(false)
				end

				if xyd.tables.item:isAwakenItem(var_280_8:getTableID()) == 1 and var_280_0:canOpenAwakeTwiceMission() and not arg_280_0.task:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE) then
					var_280_2:getChildByName("awake_equip_hide"):setVisible(false)
					var_280_2:getChildByName("awake_hide"):setVisible(false)

					local var_280_16 = "skeletons/ui_effect/awake_twice/awake_twice_effect2_new"

					arg_280_0.awakeTwiceEffect = var_0_29.new(var_280_16 .. ".json", var_280_16 .. ".atlas", 1)

					arg_280_0.awakeTwiceEffect:addTo(var_280_2)
					arg_280_0.awakeTwiceEffect:setPosition(var_280_2:getWidth() / 2, var_280_2:getHeight() / 2)
					arg_280_0.awakeTwiceEffect:play(nil, true)
					arg_280_0.awakeTwiceEffect:setName("awake_twice_effect")
				end
			end
		end
	end

	return arg_280_0.equipContainerlist_[arg_280_1]
end

function var_0_7.getSpineEffect(arg_281_0, arg_281_1)
	local var_281_0 = var_0_30[arg_281_1] .. ".json"
	local var_281_1 = var_0_30[arg_281_1] .. ".atlas"

	return (var_0_29.new(var_281_0, var_281_1, 1))
end

function var_0_7.updateCollectWindow(arg_282_0)
	if xyd.WindowManager.get():getWindow("hero_list") then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.HERO_CELL_REFRESH,
			tableID = arg_282_0.hero:getTableID()
		})
	end
end

function var_0_7.playGuide(arg_283_0)
	local var_283_0 = xyd.StoryData.get():getGuideID()

	if var_283_0 == xyd.GuideStoryType.GUIDE_EQUIP_TWO then
		local var_283_1 = arg_283_0:getEquipContainerByIndex(5)
		local var_283_2 = {
			900,
			300
		}

		xyd.showGuideWnd(var_283_1, nil, nil, 2, var_283_2, false)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_THREE)
	elseif var_283_0 == xyd.GuideStoryType.GUIDE_EQUIP_FIVE or var_283_0 == xyd.GuideStoryType.GUIDE_LEVUP_FOUR or var_283_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_EIGHT then
		local var_283_3 = arg_283_0.children_.top_sidebar:nodeByName("return_btn")
		local var_283_4 = {
			450,
			500
		}

		xyd.showGuideWnd(var_283_3, nil, nil, 2, var_283_4, false)

		if var_283_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_EIGHT then
			arg_283_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_9)
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_NINE)
		elseif var_283_0 == xyd.GuideStoryType.GUIDE_LEVUP_FOUR then
			arg_283_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_4)
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_END)
		end
	elseif var_283_0 == xyd.GuideStoryType.GUIDE_LEVUP_TWO then
		local var_283_5 = arg_283_0:nodeByName("button_jingyan")
		local var_283_6 = {
			900,
			350
		}

		xyd.showGuideWnd(var_283_5, nil, nil, 2, var_283_6, false)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_THREE)
		arg_283_0.selfPlayer:sendOperationLog(xyd.StatID.ID_LEVUP_2)
	elseif var_283_0 == xyd.GuideStoryType.GUIDE_SKILL_TWO then
		local var_283_7 = arg_283_0:nodeByName("button_jineng")
		local var_283_8 = {
			800,
			150
		}

		xyd.showGuideWnd(var_283_7, nil, nil, 2, var_283_8, false)
	elseif var_283_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_FOUR then
		local var_283_9 = arg_283_0:nodeByName("button_yijian")
		local var_283_10 = {
			800,
			300
		}

		xyd.showGuideWnd(var_283_9, nil, nil, 2, var_283_10, false)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_FIVE)
		arg_283_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_5)
	elseif var_283_0 > xyd.GuideStoryType.GUIDE_SKILL_TWO and var_283_0 < xyd.GuideStoryType.GUIDE_SKILL_END then
		local var_283_11 = arg_283_0.skillItems[1]:getChildByName("jiadian")
		local var_283_12 = {
			500,
			350
		}
		local var_283_13 = true

		if var_283_0 == xyd.GuideStoryType.GUIDE_SKILL_FIVE then
			var_283_11 = arg_283_0.skillItems[2]:getChildByName("jiadian")
			var_283_12 = {
				500,
				250
			}
		elseif var_283_0 == xyd.GuideStoryType.GUIDE_SKILL_SIX then
			var_283_11 = arg_283_0.nextArrow_
			var_283_12 = {
				1100,
				200
			}
			var_283_13 = false
		end

		local var_283_14 = var_283_11:getPositionX()
		local var_283_15 = var_283_11:getPositionY()

		xyd.WindowManager.get():closeWindow("guide")
		xyd.WindowManager.get():openWindow("guide")

		local var_283_16 = xyd.WindowManager.get():getWindow("guide")
		local var_283_17 = var_283_16:convertToNodeSpace(var_283_11:getParent():convertToWorldSpace(cc.p(var_283_14, var_283_15)))

		var_283_16:addNode()
		var_283_16:setStencil(100, 50, var_283_17.x, var_283_17.y, 2, {
			position = var_283_12,
			right = var_283_13
		})
	end
end

function var_0_7.getFloatAttrs(arg_284_0, arg_284_1)
	local var_284_0 = clone(arg_284_1)

	if arg_284_1[1] and arg_284_1[1] > 0 then
		var_284_0[xyd.AttributeType.HP] = math.ceil((var_284_0[xyd.AttributeType.HP] or 0) + arg_284_1[1] * xyd.STRENGTH_HP_RATE)
		var_284_0[xyd.AttributeType.HUJIA] = math.ceil((var_284_0[xyd.AttributeType.HUJIA] or 0) + arg_284_1[1] * xyd.STRENGTH_HUJIA_RATE)
	end

	if arg_284_1[2] and arg_284_1[2] > 0 then
		var_284_0[xyd.AttributeType.AP] = math.ceil((var_284_0[xyd.AttributeType.AP] or 0) + arg_284_1[2] * xyd.WISE_AP_RATE)
		var_284_0[xyd.AttributeType.MOKANG] = math.ceil((var_284_0[xyd.AttributeType.MOKANG] or 0) + arg_284_1[2] * xyd.WISE_MOKANG_RATE)
	end

	if arg_284_1[3] and arg_284_1[3] > 0 then
		var_284_0[xyd.AttributeType.AD] = math.ceil((var_284_0[xyd.AttributeType.AD] or 0) + arg_284_1[3] * xyd.AGILE_AD_RATE)
		var_284_0[xyd.AttributeType.HUJIA] = math.ceil((var_284_0[xyd.AttributeType.HUJIA] or 0) + arg_284_1[3] * xyd.AGILE_HUJIA_RATE)
		var_284_0[xyd.AttributeType.AD_BAOJI] = math.ceil((var_284_0[xyd.AttributeType.AD_BAOJI] or 0) + arg_284_1[3] * xyd.AGILE_AD_BAOJI_RATE)
	end

	if arg_284_1[arg_284_0.hero:getHeroType()] then
		var_284_0[xyd.AttributeType.AD] = (var_284_0[xyd.AttributeType.AD] or 0) + arg_284_1[arg_284_0.hero:getHeroType()]
	end

	return var_284_0
end

function var_0_7.CheckOneClickJinjie(arg_285_0)
	local var_285_0 = arg_285_0.hero
	local var_285_1 = 0

	arg_285_0.needEquip = {}
	arg_285_0.needPotion = {}
	arg_285_0.needGold = 0

	local function var_285_2(arg_286_0)
		local var_286_0 = arg_285_0.needEquip[arg_286_0] or 0
		local var_286_1 = xyd.tables.item:compose(arg_286_0)
		local var_286_2 = xyd.tables.item:composeNum(arg_286_0)
		local var_286_3 = xyd.tables.item:composeMana(arg_286_0) or 0

		if var_286_1[1] ~= 0 then
			if arg_285_0.selfPlayer:getBackpack():getItemNumByID(arg_286_0) == var_286_0 then
				arg_285_0.needGold = arg_285_0.needGold + var_286_3

				for iter_286_0 = 1, #var_286_1 do
					for iter_286_1 = 1, var_286_2[iter_286_0] do
						var_285_2(var_286_1[iter_286_0])
					end
				end
			else
				arg_285_0.needEquip[arg_286_0] = var_286_0 + 1
			end
		else
			arg_285_0.needEquip[arg_286_0] = var_286_0 + 1
		end
	end

	local var_285_3 = true

	for iter_285_0 = 1, xyd.MAX_ITEM_NUM do
		if var_285_0:getEquipByIndex(iter_285_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_285_0:getEquipByIndex(iter_285_0):getTableID()) == 0 and xyd.tables.item:isAwakeTwiceItem(var_285_0:getEquipByIndex(iter_285_0):getTableID()) == 0 and var_285_0.equips_[iter_285_0] == 0 then
			var_285_3 = false

			break
		end
	end

	if arg_285_0.selfPlayer:isMaxLev() and not xyd.isSuperHero(var_285_0) and var_285_0:getColor() == xyd.MAX_HERO_COLOR and var_285_3 == true then
		arg_285_0.elementEquipOpen = true

		arg_285_0:setjinjieBtn(var_0_5)

		return true
	else
		arg_285_0.elementEquipOpen = false
	end

	local var_285_4 = true

	for iter_285_1 = 1, xyd.MAX_ITEM_NUM do
		if var_285_0:getEquipByIndex(iter_285_1):getTableID() == 0 or var_285_0:getEquipLevel(iter_285_1) < 20 then
			var_285_4 = false

			break
		end
	end

	if arg_285_0.selfPlayer:isMaxLev() and xyd.isSuperHero(var_285_0) and var_285_4 == true then
		arg_285_0.elementEquipOpen = true

		arg_285_0:setjinjieBtn(var_0_5)

		return true
	else
		arg_285_0.elementEquipOpen = false
	end

	for iter_285_2 = 1, 6 do
		local var_285_5 = var_285_0:getEquipByIndex(iter_285_2)

		if var_285_5:getTableID() > 0 and not var_285_5:isCollected() and xyd.tables.item:isAwakenItem(var_285_5:getTableID()) == 0 then
			break
		end

		if iter_285_2 == 6 then
			arg_285_0:setjinjieBtn(var_0_4)

			return false
		end
	end

	for iter_285_3 = 1, 6 do
		local var_285_6 = var_285_0:getEquipByIndex(iter_285_3)

		if var_285_6:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_285_6:getTableID()) == 0 and not var_285_6:isCollected() then
			if arg_285_0.maxLev < var_285_6:getLevel() then
				arg_285_0:setjinjieBtn(var_0_4)

				return false
			end

			if var_285_0:getLevel() < var_285_6:getLevel() and var_285_1 < var_285_6:getLevel() then
				var_285_1 = var_285_6:getLevel()
			end

			var_285_2(var_285_6:getTableID())
		end
	end

	if arg_285_0.needGold > arg_285_0.selfPlayer.mana then
		arg_285_0:setjinjieBtn(var_0_4)

		return false
	end

	for iter_285_4, iter_285_5 in pairs(arg_285_0.needEquip) do
		if iter_285_5 > arg_285_0.selfPlayer:getBackpack():getItemNumByID(iter_285_4) then
			arg_285_0:setjinjieBtn(var_0_4)

			return false
		end
	end

	if var_285_1 ~= 0 then
		local var_285_7 = 0
		local var_285_8 = var_285_0:getLevel()
		local var_285_9 = var_285_0:getExp() - xyd.tables.partnerExp:totalExp(var_285_0:getLevel() - 1)
		local var_285_10 = {
			50001001,
			50001002,
			50001004,
			50001005,
			50005182
		}

		for iter_285_6 = var_285_8, var_285_1 - 1 do
			var_285_7 = var_285_7 + xyd.tables.partnerExp:exp(iter_285_6)
		end

		local var_285_11 = var_285_7 - var_285_9

		for iter_285_7, iter_285_8 in pairs(var_285_10) do
			local var_285_12 = arg_285_0.selfPlayer:getBackpack():getItemNumByID(iter_285_8)
			local var_285_13 = xyd.tables.item:exp(iter_285_8)

			if var_285_11 <= var_285_12 * var_285_13 then
				local var_285_14 = math.ceil(var_285_11 / var_285_13)

				arg_285_0.needPotion[iter_285_8] = var_285_14
				var_285_11 = 0

				break
			elseif var_285_12 ~= 0 then
				var_285_11 = var_285_11 - var_285_12 * var_285_13
				arg_285_0.needPotion[iter_285_8] = var_285_12
			end
		end

		if var_285_11 ~= 0 then
			arg_285_0:setjinjieBtn(var_0_4)

			return false
		end
	end

	if xyd.isSuperHero(arg_285_0.hero) then
		arg_285_0:setjinjieBtn(var_0_4)

		return false
	end

	if var_285_0:getColor() == xyd.MAX_HERO_COLOR then
		arg_285_0:setjinjieBtn(var_0_4)

		return false
	end

	arg_285_0:setjinjieBtn(var_0_2)

	return true
end

function var_0_7.checkOneKeyEquips(arg_287_0)
	local var_287_0 = arg_287_0.hero

	arg_287_0.needGold2Equip = 0
	arg_287_0.needEquip2Equip = {}
	arg_287_0.needPotion2Equip = {}
	arg_287_0.canEquipIndex = {}

	local function var_287_1(arg_288_0)
		local var_288_0 = {}
		local var_288_1 = 0

		local function var_288_2(arg_289_0)
			local var_289_0 = var_288_0[arg_289_0] or 0
			local var_289_1 = xyd.tables.item:compose(arg_289_0)
			local var_289_2 = xyd.tables.item:composeNum(arg_289_0)
			local var_289_3 = xyd.tables.item:composeMana(arg_289_0) or 0

			if var_289_1[1] ~= 0 then
				if arg_287_0.selfPlayer:getBackpack():getItemNumByID(arg_289_0) == var_289_0 + (arg_287_0.needEquip2Equip[arg_289_0] or 0) then
					var_288_1 = var_288_1 + var_289_3

					for iter_289_0 = 1, #var_289_1 do
						for iter_289_1 = 1, var_289_2[iter_289_0] do
							var_288_2(var_289_1[iter_289_0])
						end
					end
				else
					var_288_0[arg_289_0] = var_289_0 + 1
				end
			else
				var_288_0[arg_289_0] = var_289_0 + 1
			end
		end

		var_288_2(arg_288_0)

		return var_288_0, var_288_1
	end

	local function var_287_2(arg_290_0, arg_290_1)
		arg_290_1 = arg_290_1 or {}

		for iter_290_0, iter_290_1 in pairs(arg_290_0) do
			if iter_290_1 > arg_287_0.selfPlayer:getBackpack():getItemNumByID(iter_290_0) - (arg_290_1[iter_290_0] or 0) then
				return false
			end
		end

		return true
	end

	local var_287_3 = arg_287_0:allPotionsExpInBackPack()
	local var_287_4 = 0

	for iter_287_0 = 1, 6 do
		local var_287_5 = var_287_0:getEquipByIndex(iter_287_0)
		local var_287_6 = {}
		local var_287_7 = 0
		local var_287_8, var_287_9 = var_287_1(var_287_5:getTableID())

		if not var_287_5:isCollected() and var_287_5:getTableID() > 0 and arg_287_0.maxLev >= var_287_5:getLevel() and xyd.tables.item:isAwakenItem(var_287_5:getTableID()) == 0 and var_287_9 <= arg_287_0.selfPlayer.mana - arg_287_0.needGold2Equip and var_287_2(var_287_8, arg_287_0.needEquip2Equip) then
			if var_287_0:getLevel() >= var_287_5:getLevel() then
				arg_287_0.needGold2Equip = arg_287_0.needGold2Equip + var_287_9

				for iter_287_1, iter_287_2 in pairs(var_287_8) do
					arg_287_0.needEquip2Equip[iter_287_1] = (arg_287_0.needEquip2Equip[iter_287_1] or 0) + iter_287_2
				end

				table.insert(arg_287_0.canEquipIndex, iter_287_0)
			else
				local var_287_10 = 0
				local var_287_11 = var_287_0:getLevel()
				local var_287_12 = var_287_0:getExp() - xyd.tables.partnerExp:totalExp(var_287_0:getLevel() - 1)

				for iter_287_3 = var_287_11, var_287_5:getLevel() - 1 do
					var_287_10 = var_287_10 + xyd.tables.partnerExp:exp(iter_287_3)
				end

				local var_287_13 = var_287_10 - var_287_12

				if var_287_13 <= var_287_3 then
					if var_287_4 < var_287_13 then
						var_287_4 = var_287_13
					end

					arg_287_0.needGold2Equip = arg_287_0.needGold2Equip + var_287_9

					for iter_287_4, iter_287_5 in pairs(var_287_8) do
						arg_287_0.needEquip2Equip[iter_287_4] = (arg_287_0.needEquip2Equip[iter_287_4] or 0) + iter_287_5
					end

					table.insert(arg_287_0.canEquipIndex, iter_287_0)
				end
			end
		end
	end

	if #arg_287_0.canEquipIndex == 0 then
		arg_287_0:setjinjieBtn(var_0_4)

		return false
	end

	if var_287_4 then
		local var_287_14 = {
			50001001,
			50001002,
			50001004,
			50001005,
			50005182
		}

		for iter_287_6, iter_287_7 in pairs(var_287_14) do
			local var_287_15 = arg_287_0.selfPlayer:getBackpack():getItemNumByID(iter_287_7)
			local var_287_16 = xyd.tables.item:exp(iter_287_7)

			if var_287_4 <= var_287_15 * var_287_16 then
				local var_287_17 = math.ceil(var_287_4 / var_287_16)

				arg_287_0.needPotion2Equip[iter_287_7] = var_287_17
				var_287_4 = 0

				break
			elseif var_287_15 ~= 0 then
				var_287_4 = var_287_4 - var_287_15 * var_287_16
				arg_287_0.needPotion2Equip[iter_287_7] = var_287_15
			end
		end
	end

	arg_287_0:setjinjieBtn(var_0_3)

	return true
end

function var_0_7.allPotionsExpInBackPack(arg_291_0)
	local var_291_0 = 0
	local var_291_1 = {
		50001001,
		50001002,
		50001004,
		50001005,
		50005182
	}

	for iter_291_0, iter_291_1 in pairs(var_291_1) do
		var_291_0 = var_291_0 + arg_291_0.selfPlayer:getBackpack():getItemNumByID(iter_291_1) * xyd.tables.item:exp(iter_291_1)
	end

	return var_291_0
end

function var_0_7.CheckOneClick(arg_292_0)
	if arg_292_0:CheckOneClickJinjie() == false then
		arg_292_0:checkOneKeyEquips()
	end
end

function var_0_7.setjinjieBtn(arg_293_0, arg_293_1)
	if arg_293_1 == var_0_5 then
		arg_293_0:nodeByName("button_element"):setVisible(true)
		arg_293_0:nodeByName("button_jinjie"):setVisible(false)
		arg_293_0:nodeByName("button_onekeyequips"):setVisible(false)
		arg_293_0:nodeByName("button_yijian"):setVisible(false)
	elseif arg_293_1 == var_0_2 then
		arg_293_0:nodeByName("button_element"):setVisible(false)
		arg_293_0:nodeByName("button_jinjie"):setVisible(false)
		arg_293_0:nodeByName("button_onekeyequips"):setVisible(false)
		arg_293_0:nodeByName("button_yijian"):setVisible(true)
	elseif arg_293_1 == var_0_3 then
		arg_293_0:nodeByName("button_element"):setVisible(false)
		arg_293_0:nodeByName("button_jinjie"):setVisible(false)
		arg_293_0:nodeByName("button_onekeyequips"):setVisible(true)
		arg_293_0:nodeByName("button_yijian"):setVisible(false)
	else
		arg_293_0:nodeByName("button_element"):setVisible(false)
		arg_293_0:nodeByName("button_jinjie"):setVisible(true)
		arg_293_0:nodeByName("button_onekeyequips"):setVisible(false)
		arg_293_0:nodeByName("button_yijian"):setVisible(false)
	end
end

function var_0_7.clickYijianButton(arg_294_0)
	if arg_294_0.sendSkillLevUpRequest then
		arg_294_0:sendSkillLevUpRequest()
	end

	local function var_294_0()
		local var_295_0 = arg_294_0.hero
		local var_295_1 = var_295_0:getColor()
		local var_295_2 = var_295_0:getStar()
		local var_295_3 = var_295_0:getMaxHP()
		local var_295_4 = var_295_0:getZhandouli()
		local var_295_5 = cc.p(arg_294_0:getHeroContainer():getPosition())
		local var_295_6 = arg_294_0:getHeroContainer():getContentSize()

		var_295_5.x = var_295_5.x + var_295_6.width * 0.5
		var_295_5.y = var_295_5.y + var_295_6.height * 0.5

		var_295_0:oneKeyPowerUp(function(arg_296_0, arg_296_1)
			if arg_296_0 == xyd.error.OK then
				local var_296_0 = arg_294_0:getHeroModel()

				if not var_295_0:getEquipByIndex(2):isCollected() then
					for iter_296_0 = 1, xyd.MAX_ITEM_NUM do
						if var_295_0:getEquipByIndex(iter_296_0):isCollected() and xyd.tables.item:isAwakenItem(var_295_0:getEquipByIndex(iter_296_0):getTableID()) == 0 and not var_295_0:isLastColorHasAwakeItem() and xyd.tables.item:isAwakenItem(var_295_0:getEquipByIndex(iter_296_0):getTableID()) == 1 then
							local var_296_1 = arg_294_0:getEquipContainerByIndex(iter_296_0)
							local var_296_2 = display.newNode()

							var_296_2:size(var_296_1:getWidth(), var_296_1:getHeight())

							local var_296_3 = var_295_0:getEquipByIndex(iter_296_0, var_295_0:getColor() - 1)
							local var_296_4, var_296_5 = arg_294_0:nodeByName("normal_equipment"):getPosition()

							xyd.setSpecialItemBorderNewUI(var_296_2, var_296_3:getTableID())
							var_296_2:addTo(arg_294_0.mainContainer, 101)
							var_296_2:pos(var_296_1:getPositionX() + var_296_4, var_296_1:getPositionY() + var_296_5)

							local var_296_6, var_296_7 = arg_294_0:getHeroContainer():getPosition()
							local var_296_8 = var_296_6 + arg_294_0:getHeroContainer():getWidth() / 2
							local var_296_9 = var_296_0.chestPoint.x + var_296_8
							local var_296_10 = var_296_7 + var_296_0.chestPoint.y
							local var_296_11 = cc.Spawn:create(cc.ScaleTo:create(0.8, 0.1), cc.MoveTo:create(0.8, cc.p(var_296_9, var_296_10)))

							var_296_2:runActionOnce(var_296_11, true)
						end
					end

					for iter_296_1, iter_296_2 in pairs(arg_294_0.needEquip) do
						local var_296_12 = {
							itemID = iter_296_1,
							itemNum = iter_296_2
						}

						arg_294_0.selfPlayer:getBackpack():removeItem(var_296_12)
					end

					for iter_296_3, iter_296_4 in pairs(arg_294_0.needPotion) do
						local var_296_13 = {
							itemID = iter_296_3,
							itemNum = iter_296_4
						}

						arg_294_0.selfPlayer:getBackpack():removeItem(var_296_13)

						local var_296_14 = iter_296_4 * xyd.tables.item:exp(iter_296_3)

						var_295_0:addExp(var_296_14, xyd.tables.player:heroMaxLev(arg_294_0.selfPlayer.lev))
						arg_294_0:updateExp()
					end

					local var_296_15 = {}

					table.insert(var_296_15, xyd.JINJIE_ATTR_RATE * (var_295_0:getColor() - 1))
					table.insert(var_296_15, xyd.JINJIE_ATTR_RATE * (var_295_0:getColor() - 1))
					table.insert(var_296_15, xyd.JINJIE_ATTR_RATE * (var_295_0:getColor() - 1))

					arg_294_0.isShow = true

					arg_294_0:updateEquip()
					arg_294_0:updateAttrScore()
					arg_294_0:updateAttrLabels()
					arg_294_0:updateIntroduceText()
					arg_294_0:updateScrollBg()
					arg_294_0:updateCollectWindow()
					arg_294_0:updateNameLabel()
					arg_294_0:updateEquipInfoContainer()
					arg_294_0:setSkillContainer()
					arg_294_0:playRepeatingEffect()
					arg_294_0:CheckOneClick()
					audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))

					local var_296_16 = var_295_0:getMaxHP()
					local var_296_17 = var_295_0:getZhandouli()
					local var_296_18 = {
						type_ = xyd.LevelUpType.ADVANCE,
						hero = var_295_0,
						vals = {
							oldStar = var_295_2,
							oldColor = var_295_1,
							newColor = var_295_1 + 1,
							oldHP = var_295_3,
							newHP = var_296_16,
							oldForce = var_295_4,
							newForce = var_296_17
						},
						callback = function()
							arg_294_0:playEffect(arg_294_0.mainContainer, "Upgrade", var_295_5, true)
							var_296_0:win(false, handler(arg_294_0, arg_294_0.setIsShow))
							var_296_0:playAttribute(arg_294_0:getFloatAttrs(var_296_15))
						end
					}

					if arg_296_1.restore_items and #arg_296_1.restore_items > 0 then
						function var_296_18.callback()
							xyd.WindowManager.get():openWindow("alert_award", {
								awards = arg_296_1.restore_items,
								name = var_0_21:translation("FUMO_RESTORE_NAME")
							})

							if arg_294_0 and not tolua.isnull(arg_294_0) then
								arg_294_0:playEffect(arg_294_0.mainContainer, "Upgrade", var_295_5, true)
								var_296_0:win(false, handler(arg_294_0, arg_294_0.setIsShow))
								var_296_0:playAttribute(arg_294_0:getFloatAttrs(var_296_15))
							end
						end

						for iter_296_5 = 1, #arg_296_1.restore_items do
							local var_296_19 = {
								itemID = arg_296_1.restore_items[iter_296_5].table_id,
								itemNum = arg_296_1.restore_items[iter_296_5].item_num
							}

							arg_294_0.selfPlayer:getBackpack():addItem(var_296_19)
						end
					end

					arg_294_0:runActionOnce(cc.CallFunc:create(function()
						xyd.WindowManager.get():openWindow("levelup", var_296_18)
					end), nil, nil, 1)
				else
					for iter_296_6, iter_296_7 in pairs(arg_294_0.needEquip) do
						local var_296_20 = {
							itemID = iter_296_6,
							itemNum = iter_296_7
						}

						arg_294_0.selfPlayer:getBackpack():removeItem(var_296_20)
					end

					for iter_296_8, iter_296_9 in pairs(arg_294_0.needPotion) do
						local var_296_21 = {
							itemID = iter_296_8,
							itemNum = iter_296_9
						}

						arg_294_0.selfPlayer:getBackpack():removeItem(var_296_21)

						local var_296_22 = iter_296_9 * xyd.tables.item:exp(iter_296_8)

						var_295_0:addExp(var_296_22, xyd.tables.player:heroMaxLev(arg_294_0.selfPlayer.lev))
						arg_294_0:updateExp()
					end

					local var_296_23 = {}

					table.insert(var_296_23, xyd.JINJIE_ATTR_RATE * (var_295_0:getColor() - 1))
					table.insert(var_296_23, xyd.JINJIE_ATTR_RATE * (var_295_0:getColor() - 1))
					table.insert(var_296_23, xyd.JINJIE_ATTR_RATE * (var_295_0:getColor() - 1))

					arg_294_0.isShow = true
					var_296_0 = arg_294_0:getHeroModel()
					arg_294_0.isShow = true

					var_296_0:win(false, handler(arg_294_0, arg_294_0.setIsShow))
					var_296_0:playAttribute(arg_294_0:getFloatAttrs(var_296_23))
					arg_294_0:updateEquip()
					arg_294_0:updateAttrScore()
					arg_294_0:updateAttrLabels()
					arg_294_0:updateIntroduceText()
					arg_294_0:updateScrollBg()
					arg_294_0:updateCollectWindow()
					arg_294_0:updateNameLabel()
					arg_294_0:updateEquipInfoContainer()
					arg_294_0:setSkillContainer()
					arg_294_0:playRepeatingEffect()
					arg_294_0:CheckOneClick()
					audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))
				end

				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.HERO_CELL_REFRESH,
					tableID = var_295_0:getTableID()
				})
			end
		end)
	end

	local var_294_1 = 1
	local var_294_2 = {}

	for iter_294_0, iter_294_1 in pairs(arg_294_0.needEquip) do
		var_294_2[var_294_1] = {
			table_id = iter_294_0,
			item_num = iter_294_1
		}
		var_294_1 = var_294_1 + 1
	end

	for iter_294_2, iter_294_3 in pairs(arg_294_0.needPotion) do
		var_294_2[var_294_1] = {
			table_id = iter_294_2,
			item_num = iter_294_3
		}
		var_294_1 = var_294_1 + 1
	end

	if arg_294_0.needGold ~= 0 then
		var_294_2[var_294_1] = {
			table_id = 0,
			item_num = arg_294_0.needGold
		}
	end

	local var_294_3 = {
		items = var_294_2,
		heroName = arg_294_0.hero:getName()
	}

	xyd.AdvancedTipWindow.open(var_294_3, function(arg_300_0)
		if arg_300_0 then
			var_294_0()
		end
	end)
end

function var_0_7.clickOneKeyEquipsButton(arg_301_0)
	local function var_301_0(arg_302_0)
		local var_302_0 = arg_301_0.hero
		local var_302_1 = {}

		for iter_302_0, iter_302_1 in pairs(arg_301_0.canEquipIndex) do
			local var_302_2 = var_302_0:getEquipByIndex(iter_302_1):getAttr()

			for iter_302_2, iter_302_3 in pairs(var_302_2) do
				var_302_1[iter_302_2] = (var_302_1[iter_302_2] or 0) + iter_302_3
			end
		end

		return var_302_1
	end

	local function var_301_1()
		local var_303_0 = arg_301_0.hero
		local var_303_1 = cc.p(arg_301_0:getHeroContainer():getPosition())
		local var_303_2 = arg_301_0:getHeroContainer():getContentSize()

		var_303_1.x = var_303_1.x + var_303_2.width * 0.5
		var_303_1.y = var_303_1.y + var_303_2.height * 0.5

		arg_301_0:playEffect(arg_301_0.mainContainer, "Upgrade", var_303_1, true)
		var_303_0:oneKeyEquip(arg_301_0.canEquipIndex, function(arg_304_0, arg_304_1)
			for iter_304_0, iter_304_1 in pairs(arg_301_0.needEquip2Equip) do
				local var_304_0 = {
					itemID = iter_304_0,
					itemNum = iter_304_1
				}

				arg_301_0.selfPlayer:getBackpack():removeItem(var_304_0)
			end

			for iter_304_2, iter_304_3 in pairs(arg_301_0.needPotion2Equip) do
				local var_304_1 = {
					itemID = iter_304_2,
					itemNum = iter_304_3
				}

				arg_301_0.selfPlayer:getBackpack():removeItem(var_304_1)

				local var_304_2 = iter_304_3 * xyd.tables.item:exp(iter_304_2)

				var_303_0:addExp(var_304_2, xyd.tables.player:heroMaxLev(arg_301_0.selfPlayer.lev))
				arg_301_0:updateExp()
			end

			local var_304_3 = arg_301_0:getHeroModel()

			arg_301_0.isShow = true

			var_304_3:win(false, handler(arg_301_0, arg_301_0.setIsShow))
			var_304_3:playAttribute(var_301_0(arg_301_0.canEquipIndex))
			arg_301_0:updateEquip()
			arg_301_0:updateAttrScore()
			arg_301_0:updateAttrLabels()
			arg_301_0:updateIntroduceText()
			arg_301_0:updateScrollBg()
			arg_301_0:updateCollectWindow()
			arg_301_0:updateNameLabel()
			arg_301_0:updateEquipInfoContainer()
			arg_301_0:setSkillContainer()
			arg_301_0:playRepeatingEffect()
			arg_301_0:CheckOneClick()
			audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))
		end)
	end

	local var_301_2 = {}

	for iter_301_0, iter_301_1 in pairs(arg_301_0.needEquip2Equip) do
		table.insert(var_301_2, {
			table_id = iter_301_0,
			item_num = iter_301_1
		})
	end

	for iter_301_2, iter_301_3 in pairs(arg_301_0.needPotion2Equip) do
		if iter_301_3 ~= 0 then
			table.insert(var_301_2, {
				table_id = iter_301_2,
				item_num = iter_301_3
			})
		end
	end

	if arg_301_0.needGold2Equip ~= 0 then
		table.insert(var_301_2, {
			table_id = 0,
			item_num = arg_301_0.needGold2Equip
		})
	end

	local var_301_3 = {
		items = var_301_2,
		heroName = arg_301_0.hero:getName()
	}

	xyd.OneKeyEquipTipWindow.open(var_301_3, function(arg_305_0)
		if arg_305_0 then
			var_301_1()
		end
	end)
end

function var_0_7.getCardFrontModelID(arg_306_0)
	if arg_306_0.frontState == 1 then
		return arg_306_0.hero:getFirstTableID()
	elseif arg_306_0.frontState == 2 then
		return arg_306_0.hero:getModelID()
	else
		return arg_306_0.hero:getTableID()
	end
end

function var_0_7.isHasSkillItem(arg_307_0)
	local var_307_0 = arg_307_0.selfPlayer:getBackpack():getItems()

	for iter_307_0, iter_307_1 in pairs(var_307_0) do
		if xyd.tables.item:subType(iter_307_1.itemID) == xyd.ConsumeItemType.SKILL_POINT then
			return true
		end
	end

	return false
end

function var_0_7.updateSkinItemSchedule(arg_308_0, arg_308_1)
	arg_308_0.skinText = arg_308_1

	if not arg_308_0.skinHandle then
		arg_308_0.skinHandle = var_0_17.scheduleGlobal(function()
			local var_309_0 = xyd.ServerTime.get():getServerTime()

			if arg_308_0.skinText and not tolua.isnull(arg_308_0.skinText) then
				if var_309_0 < arg_308_0.skinText.timeStamp then
					arg_308_0.skinText:setString(xyd.timeFormatAsHMS(arg_308_0.skinText.timeStamp - var_309_0))
				else
					arg_308_0.skinText:setString(xyd.timeFormatAsHMS(0))
				end
			end
		end, 1)
	end
end

function var_0_7.addActiveEffeft(arg_310_0, arg_310_1, arg_310_2, arg_310_3, arg_310_4)
	local var_310_0 = arg_310_3 or 1
	local var_310_1 = "skeletons/ui_effect/element_equip/element_" .. arg_310_2

	if arg_310_4 then
		var_310_1 = var_310_1 .. "xiao"
	end

	local var_310_2 = xyd.createEffect(var_310_1, var_310_0)
	local var_310_3 = arg_310_1:getContentSize()

	var_310_2:addTo(arg_310_1)
	var_310_2:setPosition(var_310_3.width / 2, var_310_3.height / 2)
	var_310_2:play(nil, true)
end

function var_0_7.checkRedPointShow(arg_311_0)
	local var_311_0 = arg_311_0.hero:getHeroID()

	arg_311_0.elementRedPointNotShow = xyd.db.elementEquipRedMark:getElementEquipRedMark(arg_311_0.selfPlayer.playerID, var_311_0)

	if arg_311_0.elementRedPointNotShow and arg_311_0.elementRedPointNotShow ~= 0 then
		arg_311_0:nodeByName("element_red_point"):setVisible(false)
	else
		arg_311_0:nodeByName("element_red_point"):setVisible(true)
	end
end

function var_0_7.checkIfSatisfyGuide(arg_312_0, arg_312_1)
	if arg_312_1 == 2 then
		local var_312_0 = arg_312_0.hero:getHeroID()

		arg_312_0.elementRedPointNotShow = xyd.db.elementEquipRedMark:getElementEquipRedMark(arg_312_0.selfPlayer.playerID, var_312_0)

		if arg_312_0.elementRedPointNotShow and arg_312_0.elementRedPointNotShow ~= 0 then
			return false
		elseif not arg_312_0:nodeByName("button_element"):isVisible() then
			return false
		else
			return true
		end
	elseif arg_312_1 == 3 then
		if arg_312_0.inscriptionOn == true then
			return true
		else
			return false
		end
	else
		return false
	end
end

function var_0_7.changeEquipTypeShow(arg_313_0)
	if arg_313_0.equipType == var_0_32.Normal then
		arg_313_0:nodeByName("normal_equipment"):hide()
		arg_313_0:nodeByName("element_equipment"):show()
		arg_313_0:nodeByName("text_normal"):setVisible(false)
		arg_313_0:nodeByName("text_element"):setVisible(true)

		arg_313_0.equipType = var_0_32.Element

		xyd.sendGudieBtnClick("change_element")
	else
		arg_313_0:nodeByName("element_equipment"):hide()
		arg_313_0:nodeByName("normal_equipment"):show()
		arg_313_0:nodeByName("text_normal"):setVisible(true)
		arg_313_0:nodeByName("text_element"):setVisible(false)

		arg_313_0.equipType = var_0_32.Normal
	end
end

function var_0_7.updateCollocationBtnShow(arg_314_0)
	arg_314_0:nodeByName("icon_collocation_1"):setVisible(not arg_314_0.hero:isCollocation())
	arg_314_0:nodeByName("icon_collocation_2"):setVisible(arg_314_0.hero:isCollocation())
end

return var_0_7
