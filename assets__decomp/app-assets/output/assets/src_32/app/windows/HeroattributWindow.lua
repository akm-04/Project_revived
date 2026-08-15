local var_0_0 = class("ScrollView", cc.ui.UIScrollView)

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.getScrollNodeRect(arg_2_0)
	local var_2_0 = cc.ui.UIScrollView.getScrollNodeRect(arg_2_0)

	var_2_0.x = var_2_0.x + (arg_2_0.offsetX or 0)
	var_2_0.y = var_2_0.y + (arg_2_0.offsetY or 0)
	var_2_0.width = arg_2_0.scrollWidth
	var_2_0.height = arg_2_0.scrollHeight

	return var_2_0
end

function var_0_0.setScrollWidth(arg_3_0, arg_3_1)
	arg_3_0.scrollWidth = arg_3_1
end

function var_0_0.setScrollHeight(arg_4_0, arg_4_1)
	arg_4_0.scrollHeight = arg_4_1
end

function var_0_0.setRectOffsetX(arg_5_0, arg_5_1)
	arg_5_0.offsetX = arg_5_1
end

function var_0_0.setRectOffsetY(arg_6_0, arg_6_1)
	arg_6_0.offsetY = arg_6_1
end

local var_0_1 = xyd.tables.translation
local var_0_2 = class("HeroattributWindow", import("app.common.ui.BaseWindow"))
local var_0_3 = import("app.common.ui.WndTopSidebar")
local var_0_4 = "skill_point_timestamp"
local var_0_5 = "skill_point"
local var_0_6 = "skill_point_time_count"
local var_0_7 = 1
local var_0_8 = 8
local var_0_9 = 3
local var_0_10 = 2
local var_0_11 = 6
local var_0_12 = 9
local var_0_13 = 7
local var_0_14 = 5
local var_0_15 = 4
local var_0_16 = require("framework.scheduler")
local var_0_17 = xyd.tables.translation
local var_0_18 = import("app.common.ui.SpineEffect")
local var_0_19 = {}

var_0_19.AddItem = "skeletons/ui_effect/common_effect_hero2/common_effect_hero2_new"
var_0_19.CanUpgrade = "skeletons/ui_effect/common_effect_hero1/common_effect_hero1"
var_0_19.CanEvolve = "skeletons/ui_effect/common_effect_hero12/common_effect_hero12"
var_0_19.Upgrade = "skeletons/ui_effect/common_effect_hero3/common_effect_hero3"
var_0_19.Evolve = "skeletons/ui_effect/common_effect_hero4/common_effect_hero4"
var_0_19.SkillUp = "skeletons/ui_effect/common_effect_hero7/common_effect_hero7"
var_0_19.CanSummon = "skeletons/ui_effect/common_effect_hero8/common_effect_hero8"
var_0_19.LevelUp = "skeletons/ui_effect/common_effect_exp_lv_up/common_effect_exp_lv_up"
var_0_19.Background1 = "skeletons/ui_effect/hero/hero_bg_effect01"
var_0_19.Background2 = "skeletons/ui_effect/hero/hero_bg_effect02"

function var_0_2.ctor(arg_7_0, arg_7_1, arg_7_2)
	var_0_2.super.ctor(arg_7_0, arg_7_1, arg_7_2)

	if arg_7_2 then
		arg_7_0.hero = arg_7_2
	end

	arg_7_0.UIEffects = {}
	arg_7_0.skillTips = {}
	arg_7_0.visibleHandler = {}
	arg_7_0.refresh_ = false
	arg_7_0.guidID = xyd.StoryData.get():getGuideID()
	arg_7_0.handler = {}
	arg_7_0.needEquip = {}
	arg_7_0.needPotion = {}
	arg_7_0.needGold = 0
	arg_7_0.isOneKeyUp = false
	arg_7_0.scroll_moving_end = false
	arg_7_0.scoll_is_moving = false
	arg_7_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
end

function var_0_2.updateBtnShow(arg_8_0)
	arg_8_0:nodeByName("btn_main"):setPositionX(725)
	arg_8_0:nodeByName("button_shuxing"):setPositionX(907)
	arg_8_0:nodeByName("button_jineng"):setPositionX(1089)
	arg_8_0:nodeByName("button_breach"):setVisible(false)
	arg_8_0:nodeByName("button_inscription"):setVisible(false)
	arg_8_0:nodeByName("button_shuxing"):width(188.3)
	arg_8_0:nodeByName("button_jineng"):width(188.3)
	arg_8_0:nodeByName("btn_main"):width(188.3)
	arg_8_0:nodeByName("txt_main"):setPositionX(arg_8_0:nodeByName("btn_main"):getWidth() / 2)
	arg_8_0:nodeByName("txt_shuxing"):setPositionX(arg_8_0:nodeByName("button_shuxing"):getWidth() / 2)
	arg_8_0:nodeByName("txt_jineng"):setPositionX(arg_8_0:nodeByName("button_jineng"):getWidth() / 2)
	arg_8_0:nodeByName("txt_breach"):setPositionX(arg_8_0:nodeByName("button_breach"):getWidth() / 2)
	arg_8_0:nodeByName("txt_inscription"):setPositionX(arg_8_0:nodeByName("button_inscription"):getWidth() / 2)
end

function var_0_2.willOpen(arg_9_0, arg_9_1)
	var_0_2.super:willOpen(arg_9_1)
	arg_9_0:addBgEffect()
	arg_9_0:addTopSidebar()

	if arg_9_1.isHideBorrow then
		for iter_9_0, iter_9_1 in ipairs(arg_9_0:nodeByName("borrow_container"):getChildren()) do
			if iter_9_1 ~= nil and iter_9_1:getName() ~= "jinengmiaoshu" then
				iter_9_1:setVisible(false)
			end
		end
	else
		arg_9_0:nodeByName("borrow_container"):setVisible(true)
	end

	arg_9_0:nodeByName("normal_container"):setVisible(false)
	arg_9_0:nodeByName("inscription_container"):setVisible(false)
	arg_9_0:nodeByName("breach_container"):setVisible(false)
	arg_9_0:nodeByName("book_container"):setVisible(false)
	arg_9_0:nodeByName("equip_info_container"):setVisible(false)
	arg_9_0:nodeByName("next_hero"):setVisible(false)
	arg_9_0:nodeByName("last_hero"):setVisible(false)
	arg_9_0:nodeByName("btn_favor"):setVisible(false)
	arg_9_0:nodeByName("btn_book"):setVisible(false)
	arg_9_0:nodeByName("btn_skin"):setVisible(false)
	arg_9_0:nodeByName("btn_hero_detail"):setVisible(false)
	arg_9_0:nodeByName("btn_forum"):setVisible(false)
	arg_9_0:nodeByName("btn_dorm"):setVisible(false)
	arg_9_0:nodeByName("btn_super"):setVisible(false)
	arg_9_0:nodeByName("btn_hunqi"):setVisible(false)
	arg_9_0:nodeByName("button_jinjie"):setVisible(false)
	arg_9_0:nodeByName("button_onekeyequips"):setVisible(false)
	arg_9_0:nodeByName("button_yijian"):setVisible(false)
	arg_9_0:nodeByName("button_jingyan"):setVisible(false)
	arg_9_0:nodeByName("btn_collocation"):setVisible(false)
	arg_9_0:nodeByName("bg_message_zhandouli"):width(345)
	arg_9_0:nodeByName("bg_message_jingyan"):width(496)
	arg_9_0:nodeByName("zhandouli_txt"):setPositionX(arg_9_0:nodeByName("zhandouli_txt"):getPositionX() + 136)
	arg_9_0:nodeByName("exp_txt"):setPositionX(arg_9_0:nodeByName("exp_txt"):getPositionX() + 136)

	arg_9_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_9_0.maxLev = xyd.tables.player:heroMaxLev(arg_9_0.selfPlayer.lev)
	arg_9_0.skillPoints = arg_9_0.selfPlayer:getSkillPoint()

	arg_9_0:layout()
end

function var_0_2.addBgEffect(arg_10_0)
	local var_10_0 = var_0_19.Background1 .. ".json"
	local var_10_1 = var_0_19.Background1 .. ".atlas"

	arg_10_0.bgEffect = var_0_18.new(var_10_0, var_10_1, 1)

	arg_10_0:nodeByName("background"):addChild(arg_10_0.bgEffect)
	arg_10_0.bgEffect:setPosition(303, 593)
	arg_10_0.bgEffect:play(nil, true)

	local var_10_2, var_10_3 = var_0_19.Background2 .. ".json", var_0_19.Background2 .. ".atlas"

	arg_10_0.bgEffect2 = var_0_18.new(var_10_2, var_10_3, 1)

	arg_10_0:nodeByName("background"):addChild(arg_10_0.bgEffect2)
	arg_10_0.bgEffect2:setPosition(303, 593)
	arg_10_0.bgEffect2:play(nil, true)
	arg_10_0.bgEffect2:setScaleX(0.74)
	arg_10_0.bgEffect2:setScaleY(1.17)
	arg_10_0.bgEffect2:setRotation(51.5)
end

function var_0_2.addTopSidebar(arg_11_0)
	arg_11_0:setTouchEnabled(true)
	arg_11_0:setTouchSwallowEnabled(true)

	if arg_11_0:nodeByName("top_sidebar") then
		return
	end

	local var_11_0 = {
		colorMode = arg_11_0.colorMode,
		parent = arg_11_0,
		title = xyd.tables.window:title(arg_11_0.name)
	}
	local var_11_1 = var_0_3.new(xyd.WidgetName.wndTopSidebar, var_11_0)

	var_11_1:setAnchorPoint(0, 1)
	var_11_1:addTo(arg_11_0:nodeByName("background_top"))
	var_11_1:setPosition(0, 720)

	arg_11_0.children_.top_sidebar = var_11_1
	arg_11_0.children_.eco_sidebar = var_11_1:nodeByName("eco_sidebar")
end

function var_0_2.didOpen(arg_12_0, arg_12_1)
	var_0_2.super:didOpen(arg_12_1)
	arg_12_0:update(arg_12_0.hero)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_12_0):addEventListener(xyd.event.ECONOMY, handler(arg_12_0, arg_12_0.updateSkillPoint))
	arg_12_0:updateText()
end

function var_0_2.updateText(arg_13_0)
	arg_13_0:nodeByName("txt_skin"):setString(var_0_1:translation("HERO_MAIN_TEXT_14"))
	arg_13_0:nodeByName("txt_book"):setString(var_0_1:translation("HERO_MAIN_TEXT_15"))
	arg_13_0:nodeByName("txt_dorm"):setString(var_0_1:translation("HERO_MAIN_TEXT_16"))
	arg_13_0:nodeByName("txt_favor"):setString(var_0_1:translation("HERO_MAIN_TEXT_17"))
	arg_13_0:nodeByName("txt_super"):setString(var_0_1:translation("HERO_MAIN_TEXT_18"))
	arg_13_0:nodeByName("txt_tujian"):setString(var_0_1:translation("HERO_MAIN_TEXT_19"))
	arg_13_0:nodeByName("txt_main"):setString(var_0_1:translation("HERO_MAIN_TEXT_1"))
	arg_13_0:nodeByName("txt_shuxing"):setString(var_0_1:translation("HERO_MAIN_TEXT_2"))
	arg_13_0:nodeByName("txt_jineng"):setString(var_0_1:translation("HERO_MAIN_TEXT_3"))
	arg_13_0:nodeByName("txt_breach"):setString(var_0_1:translation("HERO_MAIN_TEXT_4"))
	arg_13_0:nodeByName("txt_inscription"):setString(var_0_1:translation("HERO_MAIN_TEXT_5"))
	arg_13_0:nodeByName("text_jinjie"):setString(var_0_1:translation("HERO_MAIN_TEXT_7"))
	arg_13_0:nodeByName("text_onkey_equip"):setString(var_0_1:translation("HERO_MAIN_TEXT_9"))
	arg_13_0:nodeByName("text_onkey_jinjie"):setString(var_0_1:translation("HERO_MAIN_TEXT_8"))
	arg_13_0:nodeByName("laizi_txt"):setString(var_0_1:translation("HERO_MAIN_TEXT_6"))
	arg_13_0:nodeByName("txt_jingyan"):setString(var_0_1:translation("HERO_MAIN_TEXT_13"))
	arg_13_0:nodeByName("attr_text"):setString(var_0_1:translation("HERO_MAIN_TEXT_20"))
	arg_13_0:nodeByName("modify_text"):setString(var_0_1:translation("HERO_MAIN_TEXT_22"))
	arg_13_0:nodeByName("breach_progress_text"):setString(var_0_1:translation("HERO_MAIN_TEXT_23"))
	arg_13_0:nodeByName("breach_text"):setString(var_0_1:translation("HERO_MAIN_TEXT_4"))
	arg_13_0:nodeByName("title_book"):setString(var_0_1:translation("HERO_MAIN_TEXT_15"))
	arg_13_0:nodeByName("detail_text"):setString(var_0_1:translation("HERO_MAIN_TEXT_41"))
	arg_13_0:nodeByName("text_title_des"):setString(var_0_1:translation("HERO_MAIN_TEXT_42"))
	arg_13_0:nodeByName("text_title_info"):setString(var_0_1:translation("HERO_MAIN_TEXT_43"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_ad"):setString(var_0_1:translation("HERO_MAIN_TEXT_48"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_as"):setString(var_0_1:translation("HERO_MAIN_TEXT_52"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_march"):setString(var_0_1:translation("HERO_MAIN_TEXT_51"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_boss"):setString(var_0_1:translation("HERO_MAIN_TEXT_50"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_df"):setString(var_0_1:translation("HERO_MAIN_TEXT_49"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_pk"):setString(var_0_1:translation("HERO_MAIN_TEXT_53"))
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_ad"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_as"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_march"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_boss"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_df"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_13_0:nodeByName("chart_container"):getChildByName("txt_pk"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_13_0:nodeByName("txt_skin_skill_other"):setString(var_0_1:translation("AVARTAR_POSE_SKILL"))
end

function var_0_2.didClose(arg_14_0)
	if arg_14_0.hero and arg_14_0.refresh_ == true then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.HERO_CELL_REFRESH,
			tableID = arg_14_0.hero:getTableID()
		})
	end
end

function var_0_2.updateSkillPoint(arg_15_0)
	if arg_15_0.isOneKeyUp then
		-- block empty
	end
end

function var_0_2.layout(arg_16_0)
	arg_16_0:updateBtnShow()

	arg_16_0.mainContainer = arg_16_0:nodeByName("card_container")
	arg_16_0.homeCardContainer = arg_16_0:nodeByName("card")
	arg_16_0.cardContainer = arg_16_0:nodeByName("card_view")
	arg_16_0.cardBlock = arg_16_0:nodeByName("card_block")
	arg_16_0.inscriptionContainer = arg_16_0:nodeByName("inscription_container")
	arg_16_0.infoContainer = arg_16_0:nodeByName("info_container")
	arg_16_0.skillContainer = arg_16_0:nodeByName("skill_container")
	arg_16_0.equipInfoContainer = arg_16_0:nodeByName("equip_info_container")
	arg_16_0.bookContainer = arg_16_0:nodeByName("book_container")
	arg_16_0.breachContainer = arg_16_0:nodeByName("breach_container")
	arg_16_0.nameLabelContainer = arg_16_0:nodeByName("name_label")

	local var_16_0 = arg_16_0.infoContainer:getContentSize()

	arg_16_0.infoContainer:hide()
	arg_16_0.skillContainer:hide()
	arg_16_0.bookContainer:hide()
	arg_16_0.equipInfoContainer:hide()
	arg_16_0.breachContainer:hide()
	arg_16_0.inscriptionContainer:hide()
	arg_16_0.cardContainer:hide()
	arg_16_0.cardBlock:hide()

	arg_16_0.state = var_0_7

	arg_16_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.highlight)

	arg_16_0.containers = {}

	table.insert(arg_16_0.containers, arg_16_0.mainContainer)
	table.insert(arg_16_0.containers, arg_16_0.infoContainer)
	table.insert(arg_16_0.containers, arg_16_0.skillContainer)
	table.insert(arg_16_0.containers, arg_16_0.breachContainer)
	table.insert(arg_16_0.containers, arg_16_0.inscriptionContainer)
	table.insert(arg_16_0.containers, arg_16_0.equipInfoContainer)
	table.insert(arg_16_0.containers, arg_16_0.bookContainer)
	arg_16_0:nodeByName("laizi_txt"):setString(xyd.tables.translation:translation("LAI_ZI"))

	local var_16_1 = arg_16_0.mainContainer:getChildByName("lev_des"):setString(var_0_1:translation("HERO_DENGJI"))
	local var_16_2 = arg_16_0.mainContainer:getChildByName("zhandou_des"):setString(var_0_1:translation("HERO_INFO_ZHANDOULI"))
	local var_16_3 = arg_16_0.mainContainer:getChildByName("jingyan_des"):setString(var_0_1:translation("HERO_INFO_JINGYAN"))

	arg_16_0:nodeByName("course_text"):setVisible(false)
	arg_16_0:nodeByName("course_modify_btn"):setVisible(false)
	arg_16_0:nodeByName("super_container"):setVisible(false)
	arg_16_0:nodeByName("btn_advance_info"):setVisible(false)
	arg_16_0:nodeByName("button_element"):setVisible(false)
	arg_16_0:setupButtonClick()

	arg_16_0.scrollBg = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_16_0.width, var_16_0.height - 40)
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

	arg_16_0:updateBtnShow()

	if arg_16_0.hero.isSkinOn_ == 1 then
		local var_16_7 = arg_16_0.hero:getSkinDatas()
		local var_16_8

		for iter_16_0, iter_16_1 in ipairs(var_16_7) do
			if iter_16_1.skinItem and xyd.tables.item:skinModel(iter_16_1.skinItem) == arg_16_0.hero.skinId_ then
				var_16_8 = iter_16_1.skinItem

				break
			end
		end

		if var_16_8 then
			xyd.setItemBorder(arg_16_0:nodeByName("skin_icon_other"), var_16_8)
			arg_16_0:nodeByName("txt_skin_name_other"):setString(xyd.tables.item:name(var_16_8))
			arg_16_0:nodeByName("skin_skill_other"):setVisible(true)
			arg_16_0:nodeByName("skin_icon_other"):addTouchEventListener(function(arg_17_0, arg_17_1)
				if arg_17_1 == ccui.TouchEventType.ended then
					local var_17_0 = {
						isSpecialSkill = false,
						id = xyd.tables.skinSkill:getSkillID(var_16_8),
						partnerID = arg_16_0.hero:getHeroID(),
						hero = arg_16_0.hero
					}
					local var_17_1 = xyd.WindowManager.get():getWindow("skill_tips")

					if not var_17_1 or tolua.isnull(var_17_1) then
						local var_17_2 = xyd.WindowManager.get():openWindow("skill_tips", var_17_0)
						local var_17_3 = arg_17_0:convertToWorldSpace(cc.p(98, 49))

						var_17_2:setPosition(var_17_3.x + 20, var_17_3.y - 140)
					end
				end
			end)
		end
	end
end

function var_0_2.playActions(arg_18_0)
	if not arg_18_0.actions_ then
		arg_18_0.actions_ = {}

		local var_18_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
		local var_18_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

		arg_18_0.actions_[1] = cc.RepeatForever:create(var_18_0)
		arg_18_0.actions_[2] = cc.RepeatForever:create(var_18_1)
	end
end

function var_0_2.playEffect(arg_19_0, arg_19_1, arg_19_2, arg_19_3, arg_19_4, arg_19_5)
	local var_19_0

	arg_19_5 = arg_19_5 or false

	if arg_19_0.UIEffects[arg_19_2] then
		var_19_0 = arg_19_0.UIEffects[arg_19_2]
	else
		local var_19_1 = var_0_19[arg_19_2] .. ".json"
		local var_19_2 = var_0_19[arg_19_2] .. ".atlas"

		var_19_0 = var_0_18.new(var_19_1, var_19_2, 1)

		arg_19_1:addChild(var_19_0, 10)

		arg_19_0.UIEffects[arg_19_2] = var_19_0
	end

	var_19_0:pos(arg_19_3.x, arg_19_3.y)

	if arg_19_4 == true then
		var_19_0:setToSetupPose()
		var_19_0:setVisible(true)

		if arg_19_5 then
			var_19_0:play(function()
				return
			end, true)
		else
			var_19_0:play(function()
				var_19_0:setVisible(false)
			end)
		end
	else
		var_19_0:setVisible(false)
	end
end

function var_0_2.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.scrollViewMoved_ = false
		arg_22_0.prevX_ = arg_22_1.x
		arg_22_0.prevY_ = arg_22_1.y
	elseif arg_22_1.name == "moved" and 5 <= math.abs(arg_22_1.y - arg_22_0.prevY_) then
		arg_22_0.scrollViewMoved_ = true
	end

	local var_22_0 = arg_22_0.scrollBg:getScrollNode()
	local var_22_1 = 0
	local var_22_2 = -(var_22_0:getCascadeBoundingBox().height - var_22_0:getContentSize().height)

	if var_22_1 < var_22_0:getPositionX() then
		arg_22_0.scrollBg:scrollTo(0, var_22_1)
	elseif var_22_2 > var_22_0:getPositionX() then
		arg_22_0.scrollBg:scrollTo(0, var_22_2)
	end
end

function var_0_2.scrollListener2(arg_23_0, arg_23_1)
	if arg_23_1.name == "began" then
		arg_23_0.scroll_is_moving = false

		arg_23_0.scrollBg2:scrollAuto()

		arg_23_0.scrollViewMoved_ = false
		arg_23_0.prevX_ = arg_23_1.x
		arg_23_0.prevY_ = arg_23_1.y

		if arg_23_0.scroll_moving_end == true then
			arg_23_0.scroll_moving_end = false
		end
	elseif arg_23_1.name == "moved" then
		local var_23_0 = arg_23_0.scrollBg2:getScrollNode()
		local var_23_1 = 0
		local var_23_2 = -(var_23_0:getCascadeBoundingBox().height - arg_23_0.scrollBg2:getViewRectInWorldSpace().height)

		if var_23_1 < var_23_0:getPositionY() then
			arg_23_0.scroll_is_moving = true
		elseif var_23_2 > var_23_0:getPositionY() then
			arg_23_0.scroll_is_moving = true
		else
			arg_23_0.scroll_is_moving = false
		end

		arg_23_0.scrolly = var_23_0:getPositionY()

		if 5 <= math.abs(arg_23_1.y - arg_23_0.prevY_) then
			arg_23_0.scrollViewMoved_ = true
		end
	elseif arg_23_1.name == "scrollEnd" then
		arg_23_0.scrolly = arg_23_0.scrollBg2:getScrollNode():getPositionY()

		if arg_23_0.scroll_is_moving == true then
			arg_23_0.scroll_moving_end = true
			arg_23_0.scroll_is_moving = false
		end
	end
end

function var_0_2.setupButtonClick(arg_24_0)
	arg_24_0:nodeByName("button_shuxing"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_24_0:clickInfoButton()
		end
	end)

	local var_24_0 = arg_24_0:nodeByName("btn_tujian")

	var_24_0:addTouchEventListener(function(arg_26_0, arg_26_1)
		xyd.buttonScaleAnim(var_24_0, arg_26_1)

		if arg_26_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_24_0:clickCardButton()
		end
	end)
	arg_24_0:nodeByName("button_jineng"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_24_0:clickSkillButton()
		end
	end)
	arg_24_0:nodeByName("btn_main"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_24_0:clickMainButton()
		end
	end)
end

function var_0_2.clickMainButton(arg_29_0)
	if arg_29_0.sendSkillLevUpRequest then
		arg_29_0:sendSkillLevUpRequest()
	end

	if arg_29_0.state ~= var_0_7 then
		local var_29_0 = arg_29_0.containers[arg_29_0.state]
		local var_29_1 = {}

		table.insert(var_29_1, cc.ScaleTo:create(0.2, 0))
		table.insert(var_29_1, cc.CallFunc:create(function()
			local var_30_0 = {}

			table.insert(var_30_0, cc.DelayTime:create(0.1))
			table.insert(var_30_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_30_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_30_0, cc.ScaleTo:create(0.05, 1))
			var_29_0:hide()
			arg_29_0.mainContainer:scale(0)
			arg_29_0.mainContainer:show()
			arg_29_0.mainContainer:runAction(transition.sequence(var_30_0))
		end))
		var_29_0:runAction(transition.sequence(var_29_1))

		arg_29_0.state = var_0_7

		arg_29_0:updateButtonBrightState()
	else
		arg_29_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_2.update(arg_31_0, arg_31_1)
	arg_31_0:playActions()

	if arg_31_0.equipContainerlist_ then
		for iter_31_0, iter_31_1 in ipairs(arg_31_0.equipContainerlist_) do
			iter_31_1:removeAllNodeEventListeners()
			iter_31_1:removeSelf()
		end

		arg_31_0.equipContainerlist_ = nil
	end

	for iter_31_2 = 1, xyd.MAX_ITEM_NUM do
		arg_31_0:getEquipContainerByIndex(iter_31_2):setTouchEnabled(false)
	end

	if arg_31_0.heroModel_ then
		arg_31_0.heroModel_:removeSelf()

		arg_31_0.heroModel_ = nil
	end

	local var_31_0 = arg_31_1 or arg_31_0.hero

	arg_31_0:updateHeroModel(var_31_0)
	arg_31_0:updateHeroHomeCard()
	arg_31_0:updateAttrScore()
	arg_31_0:updateExp()
	arg_31_0:updateHeroStar()
	arg_31_0:updateCard()
	arg_31_0:updateAttrLabels()
	arg_31_0:updateInfoChart()
	arg_31_0:updateIntroduceText()
	arg_31_0:updateScrollBg()
	arg_31_0:setSkillContainer()
	arg_31_0:updateNameLabel()
end

function var_0_2.updateHeroHomeCard(arg_32_0)
	if arg_32_0.speakCellContent and not tolua.isnull(arg_32_0.speakCellContent) then
		arg_32_0.speakCellContent:removeDelay()
	end

	local var_32_0 = arg_32_0.hero

	arg_32_0.homeCardContainer:removeAllChildren()

	local function var_32_1(arg_33_0)
		if arg_33_0 == xyd.CardStatus.SKIN_CARD then
			if arg_32_0.hero.isSkinOn_ == 1 then
				return true
			else
				return false
			end
		elseif arg_33_0 == xyd.CardStatus.AWAKE_CARD then
			if arg_32_0.hero:isAwaken() then
				return true
			else
				return false
			end
		elseif arg_33_0 == xyd.CardStatus.NORMAL_CARD then
			return true
		end
	end

	if not arg_32_0.frontHomeState then
		if arg_32_0.hero.isSkinOn_ == 1 then
			arg_32_0.frontHomeState = xyd.CardStatus.SKIN_CARD
		elseif arg_32_0.hero:isAwaken() then
			arg_32_0.frontHomeState = xyd.CardStatus.AWAKE_CARD
		else
			arg_32_0.frontHomeState = xyd.CardStatus.NORMAL_CARD
		end

		arg_32_0.backHomeState = arg_32_0.frontHomeState + 1
	else
		arg_32_0.frontHomeState = arg_32_0.backHomeState
		arg_32_0.backHomeState = arg_32_0.backHomeState + 1
	end

	while not var_32_1(arg_32_0.backHomeState) do
		if arg_32_0.backHomeState > 3 then
			arg_32_0.backHomeState = 1
		else
			arg_32_0.backHomeState = arg_32_0.backHomeState + 1
		end
	end

	local var_32_2

	if arg_32_0.frontHomeState == 1 then
		if var_32_0:isAwaken() then
			var_32_2 = xyd.tables.hero:beforeAwaken(var_32_0:getTableID())
		else
			var_32_2 = var_32_0:getTableID()
		end
	elseif arg_32_0.frontHomeState == 2 then
		var_32_2 = var_32_0:getModelID()
	elseif arg_32_0.frontHomeState == 3 then
		var_32_2 = var_32_0:getTableID()
	end

	arg_32_0:setHeroCardBaseOnCardState(arg_32_0.hero, var_32_2)
	arg_32_0:nodeByName("btn_live"):setVisible(false)
end

function var_0_2.getHomeCardFrontModelID(arg_34_0)
	if arg_34_0.frontHomeState == 1 then
		return arg_34_0.hero:getFirstTableID()
	elseif arg_34_0.frontHomeState == 2 then
		return arg_34_0.hero:getModelID()
	else
		return arg_34_0.hero:getTableID()
	end
end

function var_0_2.setHeroCardBaseOnCardState(arg_35_0, arg_35_1)
	local var_35_0 = arg_35_1:getModelID()
	local var_35_1 = xyd.tables.libraryHomeCard:x(var_35_0)
	local var_35_2 = xyd.tables.libraryHomeCard:y(var_35_0)

	if not arg_35_0 or tolua.isnull(arg_35_0) or not arg_35_0.homeCardContainer or tolua.isnull(arg_35_0.homeCardContainer) then
		return
	end

	arg_35_0.homeCardContainer:removeAllChildren()

	arg_35_0.live2d = nil

	local var_35_3 = xyd.getTransparentCard(arg_35_1, xyd.SkinDynamicPosType.LIBRARY, var_35_0)

	if not var_35_3 then
		return
	end

	arg_35_0.homeCardContainer:addChild(var_35_3)
	var_35_3:setPosition(arg_35_0.homeCardContainer:getWidth() / 2 + var_35_1, var_35_2)
	var_35_3:setAnchorPoint(cc.p(0.5, 0))
	var_35_3:setTouchEnabled(false)
	arg_35_0:addDialog(touchAreaSize)
end

function var_0_2.addDialog(arg_36_0, arg_36_1)
	local var_36_0 = {
		touchPosition = cc.p(0, -175),
		touchAreaSize = touchAreaSize or {
			width = 400,
			height = 500
		},
		msgs = clone(xyd.tables.hero:clickDialog(arg_36_0.hero:getTableID())),
		sounds = clone(xyd.tables.hero:dialogSounds(arg_36_0.hero:getTableID())),
		times = clone(xyd.tables.hero:soundTimes(arg_36_0.hero:getTableID())),
		heroTableID = arg_36_0.hero:getTableID(),
		noTouch = arg_36_1
	}

	if arg_36_0.hero.isCollected_ then
		local var_36_1, var_36_2 = arg_36_0.hero:getHeroVoiceState()

		for iter_36_0 = 5, 1, -1 do
			if not var_36_2[iter_36_0 + 4] then
				table.remove(var_36_0.msgs, iter_36_0)
				table.remove(var_36_0.sounds, iter_36_0)
				table.remove(var_36_0.times, iter_36_0)
			end
		end
	else
		var_36_0.msgs = {
			var_36_0.msgs[1]
		}
		var_36_0.sounds = {
			var_36_0.sounds[1]
		}
		var_36_0.times = {
			var_36_0.times[1]
		}
	end

	arg_36_0.speakCellContent = import("app.windows.SpeakCell").new(var_36_0)

	arg_36_0.speakCellContent:addTo(arg_36_0.homeCardContainer)
	arg_36_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_36_0.speakCellContent:setPosition(arg_36_0:nodeByName("talks_pos"):getPosition())
end

function var_0_2.updateNameLabel(arg_37_0)
	arg_37_0.nameLabelContainer:removeAllChildren()

	local var_37_0 = arg_37_0.hero
	local var_37_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/hero_label.csb")

	var_37_1:addTo(arg_37_0.nameLabelContainer)

	local var_37_2 = var_37_1:getChildByName("bg")
	local var_37_3 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_" .. xyd.Color2Quality[var_37_0:getColor()] .. ".png")

	var_37_3:addTo(var_37_2:getChildByName("bg_name"))
	var_37_3:setAnchorPoint(0, 0)

	local var_37_4

	if arg_37_0.hero:isAwaken() then
		if arg_37_0.hero:isAwakeTwice() then
			var_37_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake_twice.png")
		else
			var_37_4 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_awake.png")
		end

		var_37_4:addTo(var_37_2:getChildByName("bg_awake"))
		var_37_4:setAnchorPoint(0, 0)
	end

	local var_37_5

	if xyd.Color2Level[var_37_0:getColor()] ~= "" then
		var_37_5 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/hero_quality_" .. var_37_0:getColor() .. ".png")
	end

	local var_37_6 = arg_37_0.hero:getInscriptionKuangLevel()

	if var_37_6 then
		if var_37_6 ~= 1 then
			var_37_5 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/hero_quality_suit_" .. var_37_6 .. ".png")
		else
			var_37_5 = nil
		end

		var_37_2:getChildByName("bg_name"):removeAllChildren()

		local var_37_7 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_suit.png")

		var_37_7:addTo(var_37_2:getChildByName("bg_name"))
		var_37_7:setAnchorPoint(0, 0)
	end

	local var_37_8 = var_37_0:getElementType()

	if var_37_8 ~= 0 then
		local var_37_9

		if var_37_6 then
			var_37_9 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_gold_bg.png")
		else
			var_37_9 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_red_bg.png")
		end

		local var_37_10 = "windows/common/hero_common/big_element_" .. var_37_8

		if var_37_0:isActiveSP() then
			var_37_10 = var_37_10 .. "sp"
		end

		var_37_5 = xyd.AssetLoader.get():loadSprite(var_37_10 .. ".png")

		var_37_9:setAnchorPoint(0.5, 0.5)
		var_37_9:addTo(var_37_2:getChildByName("quality"))
		var_37_5:setAnchorPoint(0.5, 0.5)
		var_37_5:addTo(var_37_2:getChildByName("quality"))

		if arg_37_0.hero:isActiveSP() then
			arg_37_0:addActiveEffeft(var_37_5, var_37_8)
		end
	elseif var_37_5 then
		var_37_5:setAnchorPoint(0.5, 0.5)
		var_37_5:addTo(var_37_2:getChildByName("quality"))
	end

	var_37_2:getChildByName("name"):setString(var_37_0:getName())

	local var_37_11 = var_37_0:getHeroType()
	local var_37_12

	if var_37_11 == xyd.HeroType.WISE then
		var_37_12 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_wise.png")
	elseif var_37_11 == xyd.HeroType.STRENGTH then
		var_37_12 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_strength.png")
	else
		var_37_12 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_agile.png")
	end

	var_37_12:addTo(var_37_2:getChildByName("icon_info"))

	if var_37_0:isSuper() then
		local var_37_13

		if var_37_0:getStar() > xyd.MAX_STAR_LEVEL then
			local var_37_14 = var_37_0:getStar() - xyd.MAX_STAR_LEVEL

			for iter_37_0 = 1, xyd.HERO_TOTAL_STARS do
				local var_37_15 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star_pink.png")

				var_37_2:getChildByName("star_" .. iter_37_0):setSpriteFrame(var_37_15:getSpriteFrame())
				var_37_2:getChildByName("star_" .. iter_37_0):setVisible(iter_37_0 <= var_37_14)
			end
		else
			local var_37_16 = var_37_0:getStar()

			for iter_37_1 = 1, xyd.HERO_TOTAL_STARS do
				local var_37_17 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

				var_37_2:getChildByName("star_" .. iter_37_1):setSpriteFrame(var_37_17:getSpriteFrame())
				var_37_2:getChildByName("star_" .. iter_37_1):setVisible(iter_37_1 <= var_37_16)
			end
		end

		local var_37_18 = xyd.AssetLoader.get():loadSprite("windows/hero/bg_name_super.png")

		var_37_2:getChildByName("quality"):removeAllChildren()
		var_37_2:getChildByName("bg_name"):removeAllChildren()

		if var_37_8 ~= 0 then
			local var_37_19 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/big_ur_bg.png")
			local var_37_20 = "windows/common/hero_common/big_element_" .. var_37_8

			if var_37_0:isActiveSP() then
				var_37_20 = var_37_20 .. "sp"
			end

			local var_37_21 = xyd.AssetLoader.get():loadSprite(var_37_20 .. ".png")

			var_37_19:setAnchorPoint(0.5, 0.5)
			var_37_19:addTo(var_37_2:getChildByName("quality"))
			var_37_21:addTo(var_37_2:getChildByName("quality"))
			var_37_21:setAnchorPoint(0.5, 0.5)
		end

		var_37_18:addTo(var_37_2:getChildByName("bg_name"))
		var_37_18:setAnchorPoint(0, 0)
	else
		for iter_37_2 = 1, xyd.HERO_TOTAL_STARS do
			local var_37_22 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

			var_37_2:getChildByName("star_" .. iter_37_2):setSpriteFrame(var_37_22:getSpriteFrame())
			var_37_2:getChildByName("star_" .. iter_37_2):setVisible(iter_37_2 <= var_37_0:getStar())
		end
	end
end

function var_0_2.updateCard(arg_38_0)
	arg_38_0.cardContainer:removeAllChildren()
	arg_38_0.cardBlock:removeAllChildren()

	local var_38_0 = display.newNode()

	var_38_0:setContentSize(arg_38_0.cardBlock:getContentSize())
	var_38_0:addTo(arg_38_0.cardBlock)
	var_38_0:setTouchEnabled(true)
	var_38_0:setTouchSwallowEnabled(false)
	var_38_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_39_0)
		if arg_39_0.name == "ended" then
			if not arg_38_0.card or not arg_38_0.isCardShow then
				return
			end

			arg_38_0:clickCardButton()
		end

		return true
	end)

	local function var_38_1(arg_40_0)
		if arg_40_0 == xyd.CardStatus.SKIN_CARD then
			if arg_38_0.hero.isSkinOn_ == 1 then
				return true
			else
				return false
			end
		elseif arg_40_0 == xyd.CardStatus.AWAKE_CARD then
			if arg_38_0.hero:isAwaken() then
				return true
			else
				return false
			end
		elseif arg_40_0 == xyd.CardStatus.NORMAL_CARD then
			return true
		end
	end

	if not arg_38_0.frontState then
		if arg_38_0.hero.isSkinOn_ == 1 then
			arg_38_0.frontState = xyd.CardStatus.SKIN_CARD
		elseif arg_38_0.hero:isAwaken() then
			arg_38_0.frontState = xyd.CardStatus.AWAKE_CARD
		else
			arg_38_0.frontState = xyd.CardStatus.NORMAL_CARD
		end

		arg_38_0.backState = arg_38_0.frontState + 1
	else
		arg_38_0.frontState = arg_38_0.backState
		arg_38_0.backState = arg_38_0.backState + 1
	end

	while not var_38_1(arg_38_0.backState) do
		if arg_38_0.backState > 3 then
			arg_38_0.backState = 1
		else
			arg_38_0.backState = arg_38_0.backState + 1
		end
	end

	local var_38_2 = xyd.getNewHeroCard(arg_38_0.hero, arg_38_0.frontState, arg_38_0.backState, true)
	local var_38_3 = var_38_2:getChildByName("live")

	var_38_3:setTouchSwallowEnabled(true)

	local var_38_4 = display.newNode()
	local var_38_5, var_38_6 = var_38_3:getPosition()
	local var_38_7 = var_38_3:getContentSize()

	var_38_4:addTo(var_38_2)
	var_38_4:setAnchorPoint(0.5, 0.5)
	var_38_4:setTouchSwallowEnabled(true)
	var_38_4:setContentSize(var_38_7.width, var_38_7.height)
	var_38_4:setPosition(var_38_5, var_38_6)
	var_38_4:setName("node")
	var_38_4:setTouchEnabled(var_38_3:isVisible())
	var_38_3:setVisible(false)
	var_38_2:addTo(arg_38_0.cardContainer)

	arg_38_0.card = var_38_2

	var_38_2:align(display.CENTER, var_38_2:getWidth() / 2, var_38_2:getHeight() / 2)
	var_38_2:setTouchEnabled(true)
	var_38_2:setTouchSwallowEnabled(true)
	var_38_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
		if arg_41_0.name == "ended" then
			if not arg_38_0.card or not arg_38_0.isCardShow then
				return
			end

			arg_38_0:clickCardButton()
		end

		return true
	end)
	arg_38_0.card:scale(xyd.STAGE_HEIGHT / arg_38_0.card:getWidth())
	arg_38_0.card:setRotation(-90)
	arg_38_0.card:setPosition(xyd.STAGE_WIDTH / 2 - 128.31, xyd.STAGE_HEIGHT / 2)

	if arg_38_0.hero:isAwaken() or arg_38_0.hero.isSkinOn_ == 1 then
		local var_38_8 = cc.ui.UIPushButton.new({
			pressed = "windows/button/switch_button2.png",
			disabled = "windows/button/switch_button1.png",
			normal = "windows/button/switch_button1.png"
		})

		var_38_8:addTo(arg_38_0.card)
		var_38_8:setName("switchBtn")
		var_38_8:setPosition(arg_38_0.card:getChildByName("switch_pos"):getPosition())
		var_38_8:setTouchSwallowEnabled(true)

		arg_38_0.isFrontOut = true
		arg_38_0.canSwitchCard = true

		var_38_8:onButtonClicked(function(arg_42_0)
			if arg_38_0.canSwitchCard then
				arg_38_0.canSwitchCard = false

				arg_38_0:cardRolling(0.15, frontState, backState)
			end
		end)
	end
end

function var_0_2.getCardFrontModelID(arg_43_0)
	if arg_43_0.frontState == 1 then
		return arg_43_0.hero:getFirstTableID()
	elseif arg_43_0.frontState == 2 then
		return arg_43_0.hero:getModelID()
	else
		return arg_43_0.hero:getTableID()
	end
end

function var_0_2.cardRolling(arg_44_0, arg_44_1, arg_44_2, arg_44_3)
	local function var_44_0()
		arg_44_0.isFrontOut = not arg_44_0.isFrontOut
		arg_44_0.canSwitchCard = true
	end

	local function var_44_1()
		local var_46_0 = arg_44_0.card:getChildByName("container"):getChildByName("cardFront")
		local var_46_1 = arg_44_0.card:getChildByName("container"):getChildByName("cardBack")

		if arg_44_0.isFrontOut then
			var_46_0:setVisible(true)
			var_46_1:setVisible(false)
		else
			var_46_0:setVisible(false)
			var_46_1:setVisible(true)
		end

		arg_44_0:updateCard()
	end

	local var_44_2 = cc.OrbitCamera:create(arg_44_1, 1, 0, 0, 90, 0, 0)
	local var_44_3 = cc.OrbitCamera:create(arg_44_1, 1, 0, 270, 90, 0, 0)
	local var_44_4 = cc.CallFunc:create(var_44_1)
	local var_44_5 = cc.CallFunc:create(var_44_0)
	local var_44_6 = cc.Sequence:create(var_44_2, var_44_4, var_44_3, var_44_5)

	arg_44_0.card:runAction(var_44_6)
end

function var_0_2.updateHeroStar(arg_47_0)
	local var_47_0 = arg_47_0.hero

	if var_47_0.conquerSchoolLev and var_47_0.conquerSchoolLev > 0 then
		xyd.setConquerLev(var_47_0.conquerSchoolLev, arg_47_0:nodeByName("dengji_num"), arg_47_0:nodeByName("lev_bg"), nil, nil, nil, nil, var_47_0.conquerLoopID)
	else
		arg_47_0:nodeByName("dengji_num"):setString(tostring(var_47_0.player_lev))
	end

	arg_47_0:nodeByName("bottom_name_text"):setString(var_47_0.player_name)
	xyd.setAvatarClip(arg_47_0:nodeByName("touxiang_container"), var_47_0.player_avatar, 1)

	local var_47_1 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if var_47_0.player_avatar_frame and var_47_0.player_avatar_frame ~= 0 then
		var_47_1 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[var_47_0.player_avatar_frame] .. ".png"
	end

	local var_47_2 = xyd.AssetLoader.get():loadSprite(var_47_1)

	arg_47_0:nodeByName("touxiangkuang"):scale(0.75)
	arg_47_0:nodeByName("touxiangkuang"):addChild(var_47_2)
	var_47_2:setPosition(arg_47_0:nodeByName("touxiangkuang"):getWidth() / 2, arg_47_0:nodeByName("touxiangkuang"):getHeight() / 2)

	for iter_47_0 = 1, 3 do
		arg_47_0:nodeByName("star_gray" .. iter_47_0):setPositionX(237.58 + (iter_47_0 - 1) * 20)
		arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_0):setPositionX(237.58 + (iter_47_0 - 1) * 20)
	end

	for iter_47_1 = 1, 5 do
		arg_47_0:nodeByName("hero_star" .. iter_47_1):setPositionY(246.63)
		arg_47_0:nodeByName("star_gray" .. iter_47_1):setPositionY(246.63)
	end

	if var_47_0:isSuper() then
		local var_47_3

		if var_47_0:getStar() > xyd.MAX_STAR_LEVEL then
			arg_47_0:nodeByName("star_gray4"):setVisible(false)
			arg_47_0:nodeByName("star_gray5"):setVisible(false)

			for iter_47_2 = 1, 3 do
				arg_47_0:nodeByName("star_gray" .. iter_47_2):setPositionX(237.58 + iter_47_2 * 20)
				arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_2):setPositionX(237.58 + iter_47_2 * 20)
			end

			local var_47_4 = var_47_0:getStar() - xyd.MAX_STAR_LEVEL

			for iter_47_3 = 1, xyd.HERO_TOTAL_STARS do
				local var_47_5 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star_pink.png")

				arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_3):setSpriteFrame(var_47_5:getSpriteFrame())
				arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_3):setVisible(iter_47_3 <= var_47_4)
			end
		else
			arg_47_0:nodeByName("star_gray4"):setVisible(true)
			arg_47_0:nodeByName("star_gray5"):setVisible(true)

			local var_47_6 = var_47_0:getStar()

			for iter_47_4 = 1, xyd.HERO_TOTAL_STARS do
				local var_47_7 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

				arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_4):setSpriteFrame(var_47_7:getSpriteFrame())
				arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_4):setVisible(iter_47_4 <= var_47_6)
			end
		end
	else
		arg_47_0:nodeByName("star_gray4"):setVisible(true)
		arg_47_0:nodeByName("star_gray5"):setVisible(true)

		for iter_47_5 = 1, xyd.HERO_TOTAL_STARS do
			local var_47_8 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_star.png")

			arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_5):setSpriteFrame(var_47_8:getSpriteFrame())
			arg_47_0.mainContainer:getChildByName("hero_star" .. iter_47_5):setVisible(iter_47_5 <= var_47_0:getStar())
		end
	end
end

function var_0_2.updateExp(arg_48_0, arg_48_1)
	arg_48_1 = arg_48_1 or arg_48_0.hero

	arg_48_0:nodeByName("lev_txt"):setString(arg_48_1:getLevel())

	local var_48_0 = arg_48_1:getExp() - xyd.tables.partnerExp:totalExp(arg_48_1:getLevel() - 1)

	arg_48_0:nodeByName("exp_txt"):setString(var_48_0 .. " / " .. arg_48_1:getAddExp())
end

function var_0_2.playLevelUpEffect(arg_49_0, arg_49_1)
	local var_49_0 = arg_49_0:getHeroContainer():getContentSize().width
	local var_49_1 = arg_49_0:getHeroContainer():getContentSize().height
	local var_49_2 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_49_2, false)

	local var_49_3 = arg_49_0:getHeroContainer():getContentSize().width
	local var_49_4 = arg_49_0:getHeroContainer():getContentSize().height

	if arg_49_0.levelUpEffect == nil then
		local var_49_5 = var_0_19.Evolve .. ".json"
		local var_49_6 = var_0_19.Evolve .. ".atlas"

		arg_49_0.levelUpEffect = var_0_18.new(var_49_5, var_49_6, 1)

		arg_49_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_49_0.levelUpEffect:setPosition(var_49_3 / 2, var_49_4 / 2)
		arg_49_0.levelUpEffect:addTo(arg_49_0:getHeroContainer())
	end

	arg_49_0.levelUpEffect:play(nil, false)

	if arg_49_0.levelUpSprite == nil then
		arg_49_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

		arg_49_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
		arg_49_0.levelUpSprite:setPosition(var_49_3 / 2, var_49_4 / 2)
		arg_49_0.levelUpSprite:addTo(arg_49_0:getHeroContainer())
	end

	arg_49_0.levelUpSprite:setPosition(var_49_3 / 2, var_49_4 / 2)
	arg_49_0.levelUpSprite:setVisible(true)
	arg_49_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1, cc.p(var_49_3 / 2, var_49_4 / 2 + 100)), false, function()
		arg_49_0.levelUpSprite:setVisible(false)
	end)

	local var_49_7 = arg_49_1:getChildByName("item"):getContentSize().width
	local var_49_8 = arg_49_1:getChildByName("item"):getContentSize().height
	local var_49_9, var_49_10 = arg_49_1:getChildByName("item"):getPosition()

	if arg_49_0.clickEffect and not tolua.isnull(arg_49_0.clickEffect) then
		arg_49_0.clickEffect:removeAllChildren()
	end

	local var_49_11 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_49_12 = var_49_11 .. ".json"
	local var_49_13 = var_49_11 .. ".atlas"

	arg_49_0.clickEffect = var_0_18.new(var_49_12, var_49_13, 1)

	arg_49_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_49_0.clickEffect:setPosition(var_49_9 + var_49_7 / 2, var_49_10 + var_49_8 / 2)
	arg_49_1:addChild(arg_49_0.clickEffect)
	arg_49_0.clickEffect:setScale(0.7)
	arg_49_0.clickEffect:play(nil, false)
end

function var_0_2.resetEffect(arg_51_0)
	if arg_51_0.clickEffect then
		arg_51_0.clickEffect = nil
	end

	if arg_51_0.levelUpSprite then
		arg_51_0.levelUpSprite = nil
	end

	if arg_51_0.levelUpEffect then
		arg_51_0.levelUpEffect = nil
	end

	if arg_51_0.eatExpEffect then
		arg_51_0.eatExpEffect = nil
	end
end

function var_0_2.updateScrollBg(arg_52_0)
	arg_52_0:nodeByName("recommend_container"):setVisible(false)

	local var_52_0 = arg_52_0.scrollBg:getViewRect()
	local var_52_1 = arg_52_0:nodeByName("shuxing_container")
	local var_52_2 = arg_52_0:nodeByName("jieshao_container")
	local var_52_3 = arg_52_0:nodeByName("chart_container")
	local var_52_4 = var_52_1:getContentSize().height
	local var_52_5 = var_52_2:getContentSize().height
	local var_52_6 = var_52_3:getContentSize().height

	var_52_3:setPosition(cc.p(0, var_52_5 + var_52_4))
	var_52_2:setPosition(cc.p(0, var_52_4))
	var_52_1:setPosition(cc.p(0, 0))
	arg_52_0.scrollBg:setScrollWidth(var_52_0.width)
	arg_52_0.scrollBg:setScrollHeight(var_52_4 + var_52_5 + var_52_6)
	arg_52_0.scrollBg:scrollTo(0, var_52_0.height - var_52_4 - var_52_5 - var_52_6)
end

function var_0_2.updateAttrScore(arg_53_0, arg_53_1)
	arg_53_1 = arg_53_1 or arg_53_0.hero

	local var_53_0

	if arg_53_1.force_ and arg_53_1.force_ ~= 0 then
		var_53_0 = arg_53_1.force_
	else
		var_53_0 = arg_53_1:getZhandouli()
	end

	arg_53_0:nodeByName("zhandouli_txt"):setString(var_53_0)
end

function var_0_2.updateHeroModel(arg_54_0, arg_54_1)
	local var_54_0 = arg_54_0:getHeroModel()

	var_54_0:setTouchSwallowEnabled(false)

	arg_54_0.modelState = xyd.ModelState.Walk

	local var_54_1 = arg_54_0:getHeroContainer():getContentSize().width / 2

	var_54_0:setPosition(cc.p(var_54_1, 0))

	if arg_54_1:getTableID() == 11005 then
		var_54_0:setPosition(cc.p(var_54_1 - 100, 0))
	end

	arg_54_0:getHeroContainer():removeAllChildren()
	var_54_0:addTo(arg_54_0:getHeroContainer())
	var_54_0:setTouchEnabled(true)

	arg_54_0.isShow = false

	arg_54_0:getHeroContainer():addTouchEventListener(function(arg_55_0, arg_55_1)
		if arg_55_1 == ccui.TouchEventType.ended and not arg_54_0.isShow then
			arg_54_0:resetModelState()
		end
	end)
end

function var_0_2.setIsShow(arg_56_0)
	arg_56_0.isShow = false

	arg_56_0:getHeroModel():idle()
end

function var_0_2.resetModelState(arg_57_0)
	local var_57_0 = arg_57_0:getHeroModel()

	if arg_57_0.modelState == 7 then
		arg_57_0.modelState = arg_57_0.modelState + 1
	end

	arg_57_0.modelState = arg_57_0.modelState % 7
	arg_57_0.isShow = true

	local var_57_1

	if arg_57_0.modelState == xyd.ModelState.Walk then
		var_57_0:walk(true)

		arg_57_0.isShow = false
		var_57_1 = xyd.tables.model:getMoveSound(arg_57_0.hero:getModelID())
	elseif arg_57_0.modelState == xyd.ModelState.Win then
		var_57_0:win(false, handler(arg_57_0, arg_57_0.setIsShow))

		var_57_1 = xyd.tables.model:getWinSound(arg_57_0.hero:getModelID())
	elseif arg_57_0.modelState == xyd.ModelState.Attack1 then
		var_57_0:attack(1, nil, nil, handler(arg_57_0, arg_57_0.setIsShow))

		var_57_1 = xyd.tables.model:getNormalAttackSound(arg_57_0.hero:getModelID())
	elseif arg_57_0.modelState == xyd.ModelState.Attack2 then
		var_57_0:attack(2, nil, nil, handler(arg_57_0, arg_57_0.setIsShow))

		var_57_1 = xyd.tables.model:getAttack1Sound(arg_57_0.hero:getModelID())
	elseif arg_57_0.modelState == xyd.ModelState.Attack3 then
		var_57_0:attack(3, nil, nil, handler(arg_57_0, arg_57_0.setIsShow))

		var_57_1 = xyd.tables.model:getAttack2Sound(arg_57_0.hero:getModelID())
	elseif arg_57_0.modelState == xyd.ModelState.Attack4 then
		var_57_0:attack(4, nil, nil, handler(arg_57_0, arg_57_0.setIsShow))

		var_57_1 = xyd.tables.model:getAttack4Sound(arg_57_0.hero:getModelID())
	else
		arg_57_0:setIsShow()
	end

	if var_57_1 then
		audio.stopAllSounds()
		audio.playSound(var_57_1, false)
	end

	arg_57_0.modelState = arg_57_0.modelState + 1
end

function var_0_2.getHeroModel(arg_58_0)
	if not arg_58_0.heroModel_ then
		arg_58_0.heroModel_ = arg_58_0.hero:getHeroModel()
	end

	return arg_58_0.heroModel_
end

function var_0_2.setSkillContainer(arg_59_0, arg_59_1)
	if tolua.isnull(arg_59_0.skillContainer) then
		return
	end

	arg_59_0:nodeByName("jinengdian_des"):setVisible(false)
	arg_59_0:nodeByName("jinengdian"):setVisible(false)
	arg_59_0:nodeByName("point_full"):setVisible(false)
	arg_59_0:nodeByName("point_time"):setVisible(false)
	arg_59_0:nodeByName("price_activity"):setVisible(false)

	local var_59_0 = arg_59_1 or arg_59_0.hero
	local var_59_1 = var_59_0:getSkillId()
	local var_59_2 = {}

	arg_59_0.skillItems = {}

	local var_59_3 = arg_59_0.skillContainer:getChildByName("scroll_bg")
	local var_59_4 = arg_59_0.skillContainer:getChildByName("price_activity")

	if not arg_59_0.skillList then
		arg_59_0.skillList = cc.ui.UIListView.new({
			viewRect = cc.rect(0, 0, 500, 420),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(var_59_3):onScroll(handler(arg_59_0, arg_59_0.scrollListener))
	else
		arg_59_0.skillList:removeAllItems()
	end

	local var_59_5 = 0
	local var_59_6 = xyd.tables.skill

	for iter_59_0, iter_59_1 in ipairs(var_59_1) do
		local var_59_7 = var_59_6:isAwakenSkill(iter_59_1) > 0
		local var_59_8 = var_59_6:isAwakeTwiceSkill(iter_59_1) > 0
		local var_59_9 = not var_59_7 and not var_59_8

		if iter_59_1 ~= 0 and (var_59_9 or var_59_7 and xyd.tables.hero:isCanAwaken(var_59_0:getTableID()) > 0 and arg_59_0.selfPlayer.maxTeamLev >= 90 or var_59_8 and xyd.tables.hero:isCanAwakeTwice(var_59_0:getTableID()) > 0 and arg_59_0.selfPlayer.maxTeamLev >= 100) then
			local var_59_10 = display.newNode()
			local var_59_11 = arg_59_0.skillList:newItem()
			local var_59_12 = xyd.tables.skill:icon(iter_59_1)
			local var_59_13 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/skill_item.csb")
			local var_59_14 = xyd.SpriteLoader.new(var_59_12, nil, nil, xyd.DefaultImageType.SKILL_ICON)
			local var_59_15 = var_59_13:getChildByName("background"):getContentSize()

			var_59_13:setContentSize(var_59_15)
			var_59_10:setContentSize(var_59_15)

			local var_59_16 = var_59_13:getChildByName("icon")
			local var_59_17 = var_59_13:getChildByName("border"):getChildByName("skill_hide")

			if var_59_9 or var_59_7 and var_59_0:isAwaken() or var_59_8 and var_59_0:isAwakeTwice() then
				var_59_13:getChildByName("small_mana"):setVisible(true)
				var_59_13:getChildByName("gold_text"):setVisible(true)
				var_59_13:getChildByName("lev"):setVisible(true)
				var_59_13:getChildByName("level_extra"):setVisible(true)
				var_59_17:setVisible(false)

				stencil = xyd.AssetLoader:get():loadSprite("windows/hero/skill_icon_mask.png")

				stencil:setPosition(var_59_16:getWidth() / 2, var_59_16:getHeight() / 2)
				stencil:setAnchorPoint(cc.p(0.5, 0.5))
				stencil:scale(var_59_16:getWidth() / stencil:getWidth())

				local var_59_18 = cc.ClippingNode:create()

				var_59_18:setStencil(stencil)
				var_59_18:setInverted(true)
				var_59_18:setAlphaThreshold(0)
				var_59_16:addChild(var_59_18)
				var_59_18:addChild(var_59_14)
				var_59_14:align(display.LEFT_BOTTOM, 0, 0)
				var_59_14:scale((var_59_16:getWidth() - 3) / var_59_14:getWidth())

				local var_59_19 = var_59_13:getChildByName("btn_container")

				if var_59_0:getSkillLevel(iter_59_0) then
					local var_59_20 = var_59_0:getSkillLevel(iter_59_0) - xyd.SKILL_EXTRA[iter_59_0]

					var_59_13:getChildByName("lev"):setString("lv. " .. var_59_20)

					if var_59_0:getExtraSkillLevel() > 0 then
						var_59_13:getChildByName("level_extra"):show()
						var_59_13:getChildByName("level_extra"):setString("+" .. var_59_0:getExtraSkillLevel())
					else
						var_59_13:getChildByName("level_extra"):hide()
					end

					var_59_13:getChildByName("jiesuo"):setVisible(false)
				else
					local var_59_21 = var_0_1:translation("HERO_JIESUO_" .. iter_59_0)

					var_59_13:getChildByName("jiesuo"):setString(var_59_21)
					var_59_13:getChildByName("lev"):setVisible(false)
				end

				var_59_13:getChildByName("level_extra"):hide()
				var_59_13:getChildByName("gold_text"):setVisible(false)
				var_59_13:getChildByName("small_mana"):setVisible(false)
			else
				var_59_17:setVisible(true)
				var_59_13:getChildByName("small_mana"):setVisible(false)
				var_59_13:getChildByName("gold_text"):setVisible(false)
				var_59_13:getChildByName("lev"):setVisible(false)
				var_59_13:getChildByName("level_extra"):setVisible(false)
				var_59_13:getChildByName("jiesuo"):setString(var_0_1:translation("AWAKE_SKILL_LOCK_TIP"))
			end

			var_59_13:getChildByName("name"):setString(xyd.tables.skill:name(iter_59_1))
			var_59_13:addTo(var_59_10)
			table.insert(arg_59_0.skillItems, var_59_13)
			var_59_11:addContent(var_59_10)
			var_59_11:setItemSize(var_59_10:getWidth(), var_59_10:getHeight() + 12)
			arg_59_0.skillList:addItem(var_59_11)

			var_59_5 = var_59_5 + 1

			arg_59_0:createSkillTip(iter_59_0, iter_59_1)
		end
	end

	if var_59_5 < 5 then
		arg_59_0.skillList:setBounceable(false)
	else
		arg_59_0.skillList:setBounceable(true)
	end

	arg_59_0.skillCount = var_59_5

	arg_59_0.skillList:reload()
end

function var_0_2.createSkillTip(arg_60_0, arg_60_1, arg_60_2)
	local var_60_0 = arg_60_0.skillItems[arg_60_1]

	if var_60_0 ~= nil then
		local var_60_1, var_60_2 = var_60_0:getPosition()

		if var_60_0:getChildByName("skill_tip") and not tolua.isnull(var_60_0:getChildByName("skill_tip")) then
			var_60_0:removeChildByName("skill_tip")
		end

		local var_60_3 = display.newNode()

		var_60_3:setPosition(var_60_0:getChildByName("icon"):getPosition())
		var_60_3:setAnchorPoint(cc.p(0, 0))
		var_60_3:setContentSize(var_60_0:getChildByName("icon"):getContentSize())
		var_60_3:setTouchEnabled(true)
		var_60_3:addTo(var_60_0)
		var_60_3:setName("skill_tip")

		local var_60_4 = arg_60_0:convertToWorldSpace(cc.p(0, 0))

		var_60_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_61_0)
			if arg_61_0.name == "began" then
				local var_61_0 = {
					has_jiantou = false,
					id = arg_60_2,
					skillLev = arg_60_0.hero:getSkillLevel(arg_60_1),
					extraSkillLevel = arg_60_0.hero:getExtraSkillLevel()
				}

				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_61_1 = xyd.WindowManager.get():openWindow("skill_tips", var_61_0)

					xyd.adaptToWorldPosition(var_60_3, var_61_1)
				end

				return true
			elseif arg_61_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	end
end

function var_0_2.setEquipNode(arg_62_0, arg_62_1, arg_62_2)
	if tolua.isnull(arg_62_0) or tolua.isnull(arg_62_2) then
		return
	end

	local var_62_0 = arg_62_0.hero
	local var_62_1 = xyd.split(var_0_1:translation("COLOR_TABLE"), ",")
	local var_62_2 = {
		size = 26,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = xyd.color.HERO_QUALITY[arg_62_1],
		text = var_62_1[arg_62_1] .. xyd.Color2Level[arg_62_1]
	}
	local var_62_3 = xyd.AssetLoader.get():loadLabel(var_62_2)

	var_62_3:addTo(arg_62_2)
	var_62_3:align(display.CENTER, arg_62_2:getChildByName("node_pos"):getPosition())
	var_62_3:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_62_3:setName("title")

	for iter_62_0 = 1, xyd.MAX_ITEM_NUM do
		local var_62_4 = var_62_0:getEquipByIndex(iter_62_0, arg_62_1)

		if var_62_4:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_62_4:getTableID()) == 0 then
			local var_62_5 = arg_62_2:getChildByName("icon" .. iter_62_0)

			var_62_5:removeAllChildren()

			local var_62_6 = display.newNode()

			var_62_6:size(var_62_5:getContentSize())
			var_62_5:addChild(var_62_6)
			xyd.setItemBorder(var_62_6, var_62_4:getTableID())
			var_62_6:setTouchEnabled(true)

			local var_62_7 = arg_62_0.scrollBg2:getViewRectInWorldSpace()
			local var_62_8

			var_62_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_63_0)
				if arg_63_0.name == "began" then
					local var_63_0 = arg_62_0.scrollBg2:getScrollNode()

					arg_62_0.scrolly = var_63_0:getPositionY()
					var_62_8 = arg_63_0.y
				elseif arg_63_0.name == "moved" then
					if arg_62_0.scroll_is_moving == true then
						if arg_62_0.scroll_moving_end == true then
							arg_62_0.scrollBg2:scrollTo(0, arg_63_0.y - var_62_8 + arg_62_0.scrolly)
						end
					else
						arg_62_0.scrollBg2:scrollTo(0, arg_63_0.y - var_62_8 + arg_62_0.scrolly)
					end
				elseif arg_63_0.name == "ended" then
					if arg_62_0.scroll_is_moving == true then
						if arg_62_0.scroll_moving_end == true then
							arg_62_0.scrolly = arg_63_0.y - var_62_8 + arg_62_0.scrolly

							arg_62_0.scrollBg2:scrollAuto()
						end
					else
						arg_62_0.scrolly = arg_63_0.y - var_62_8 + arg_62_0.scrolly

						arg_62_0.scrollBg2:scrollAuto()
					end
				end

				return true
			end)
		else
			local var_62_9 = arg_62_2:getChildByName("icon" .. iter_62_0)
			local var_62_10 = arg_62_2:getChildByName("awake_equip_hide")
			local var_62_11 = arg_62_2:getChildByName("awake_hide")

			if var_62_10 then
				var_62_10:setVisible(true)
				var_62_11:setVisible(true)
			end
		end
	end
end

function var_0_2.updateEquipInfoContainer(arg_64_0)
	local var_64_0 = arg_64_0.scrollBg2:getScrollNode()
	local var_64_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	var_64_0:removeAllChildren()

	local var_64_2 = arg_64_0.hero
	local var_64_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/heroattribute/equip_info.csb")

	var_64_3:size(var_64_3:getChildByName("background"):getContentSize())
	var_64_3:removeChild(var_64_3:getChildByName("background"))
	var_64_3:addTo(var_64_0)

	if var_64_2:getColor() >= var_64_1.maxHeroColor or xyd.isSuperHero(var_64_2) then
		var_64_0:removeAllChildren()
	elseif var_64_2:getColor() == xyd.selfPlayer.maxHeroColor - 1 then
		var_64_3:align(display.LEFT_BOTTOM, 0, 0)
		arg_64_0:setEquipNode(var_64_2:getColor() + 1, var_64_3)
	elseif var_64_2:getColor() < xyd.selfPlayer.maxHeroColor - 1 then
		var_64_3:align(display.LEFT_BOTTOM, 0, var_64_3:getHeight() + 20)

		local var_64_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/heroattribute/equip_info.csb")

		var_64_4:size(var_64_3:getContentSize())
		var_64_4:removeChild(var_64_4:getChildByName("background"))
		var_64_4:addTo(var_64_0)
		var_64_4:align(display.LEFT_BOTTOM, 0, 0)
		arg_64_0:setEquipNode(var_64_2:getColor() + 1, var_64_3)
		arg_64_0:setEquipNode(var_64_2:getColor() + 2, var_64_4)
	end

	local var_64_5 = arg_64_0.scrollBg2:getViewRect()

	arg_64_0.scrollBg2:setScrollWidth(var_64_5.width)
	arg_64_0.scrollBg2:setScrollHeight(var_64_3:getHeight() + var_64_3:getY())
	arg_64_0.scrollBg2:scrollTo(0, var_64_5.height - var_64_3:getHeight() - var_64_3:getY())

	if arg_64_0.scrolly then
		arg_64_0.scrollBg2:scrollTo(0, arg_64_0.scrolly)
	end
end

function var_0_2.updateSkillContainer(arg_65_0)
	local var_65_0 = arg_65_0.hero

	for iter_65_0, iter_65_1 in pairs(arg_65_0.skillItems) do
		if var_65_0:getSkillLevel(iter_65_0) then
			local var_65_1 = var_65_0:getSkillLevel(iter_65_0) - xyd.SKILL_EXTRA[iter_65_0]

			iter_65_1:getChildByName("lev"):setString("lv." .. var_65_1)

			if var_65_0:getExtraSkillLevel() > 0 then
				iter_65_1:getChildByName("level_extra"):show()
				iter_65_1:getChildByName("level_extra"):setString("+" .. var_65_0:getExtraSkillLevel())
			else
				iter_65_1:getChildByName("level_extra"):hide()
			end
		else
			iter_65_1:getChildByName("level_extra"):hide()
		end
	end
end

function var_0_2.updateInfoChart(arg_66_0)
	local var_66_0 = arg_66_0.hero
	local var_66_1 = arg_66_0:nodeByName("canvas")
	local var_66_2 = arg_66_0:nodeByName("chart_container")
	local var_66_3 = cc.p(var_66_1:getPosition())
	local var_66_4 = var_66_0:getAttrRates()

	xyd.drawColorPentagon(var_66_1, {
		radius = 110,
		values = var_66_4,
		center = cc.p(112, 100)
	})
end

function var_0_2.updateIntroduceText(arg_67_0)
	local var_67_0 = arg_67_0.hero
	local var_67_1 = arg_67_0:nodeByName("jieshao_container")

	if tolua.isnull(var_67_1) then
		return
	end

	local var_67_2 = var_67_1:getChildByName("text_title_des")
	local var_67_3 = var_67_1:getChildByName("title_back")
	local var_67_4 = var_67_1:getChildren()

	if var_67_4 then
		for iter_67_0, iter_67_1 in ipairs(var_67_4) do
			if iter_67_1 ~= var_67_2 and iter_67_1 ~= var_67_3 then
				var_67_1:removeChild(iter_67_1)
			end
		end
	end

	local var_67_5 = {
		y = 0,
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(54, 54, 54),
		dimensions = cc.size(470, 54),
		text = var_67_0:getTalkText()
	}
	local var_67_6
	local var_67_7 = 0
	local var_67_8 = 0

	if var_67_0:getTalkText() then
		local var_67_9 = xyd.AssetLoader.get():loadLabel(var_67_5)

		var_67_9:addTo(var_67_1)
		var_67_9:setAnchorPoint(cc.p(0, 0))

		var_67_7 = var_67_9:getStringNumLines()
		var_67_8 = 10
	end

	local var_67_10 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = var_67_7 * 30 + var_67_8,
		color = cc.c3b(235, 75, 94),
		dimensions = cc.size(470, 100),
		text = var_67_0:getDes()
	}
	local var_67_11 = xyd.AssetLoader.get():loadLabel(var_67_10)

	var_67_11:addTo(var_67_1)
	var_67_11:setAnchorPoint(cc.p(0, 0))

	local var_67_12 = var_67_11:getStringNumLines()

	var_67_3:y(var_67_10.y + var_67_12 * 30 + 20)
	var_67_2:y(var_67_10.y + var_67_12 * 30 + 20)

	local var_67_13 = var_67_2:getY()

	var_67_1:height(var_67_13 + 31)
end

function var_0_2.updateAttrLabels(arg_68_0)
	if not arg_68_0.hero then
		return
	end

	local var_68_0 = arg_68_0.hero
	local var_68_1 = 0
	local var_68_2 = arg_68_0:nodeByName("shuxing_container")

	if tolua.isnull(var_68_2) then
		return
	end

	local var_68_3 = var_68_2:getChildByName("text_title_info")
	local var_68_4 = var_68_2:getChildByName("title_back")
	local var_68_5 = var_68_2:getChildren()

	if var_68_5 then
		for iter_68_0, iter_68_1 in ipairs(var_68_5) do
			if iter_68_1 ~= var_68_3 and iter_68_1 ~= var_68_4 then
				var_68_2:removeChild(iter_68_1)
			end
		end
	end

	local var_68_6 = {
		xyd.AttributeType.DIKANG_YINGZHI,
		xyd.AttributeType.HALF_MP
	}

	for iter_68_2, iter_68_3 in ipairs(var_68_6) do
		if var_68_0:getSkillBookAttr(iter_68_3) > 0 then
			var_68_1 = var_68_1 + 1

			local var_68_7 = arg_68_0:createBookLabel(iter_68_3)

			var_68_7:addTo(var_68_2)
			var_68_7:setPosition(20, 20 + var_68_1 * 35)
		end
	end

	for iter_68_4 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if var_68_0:getSkillBookAttr(iter_68_4) > 0 then
			var_68_1 = var_68_1 + 1

			local var_68_8 = arg_68_0:createBookLabel(iter_68_4)

			var_68_8:addTo(var_68_2)
			var_68_8:setPosition(20, 20 + var_68_1 * 35)
		end
	end

	local var_68_9 = 50 + var_68_1 * 35 + 15
	local var_68_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/book/book_title.csb")

	if var_68_1 == 0 then
		var_68_9 = 0
	else
		var_68_10:addTo(var_68_2)
		var_68_10:getChildByName("container"):getChildByName("title_not_has"):setVisible(false)
		var_68_10:getChildByName("container"):getChildByName("title_has"):setString(var_0_1:translation("HERO_MAIN_TEXT_58"))
		var_68_10:setPosition(18, var_68_9 + 15)
	end

	local var_68_11 = 0

	for iter_68_5, iter_68_6 in ipairs(var_68_6) do
		if var_68_0:getTotalAttrWithOutBook(iter_68_6) > 0 then
			var_68_11 = var_68_11 + 1

			local var_68_12 = arg_68_0:createLabel(iter_68_6)

			var_68_12:addTo(var_68_2)
			var_68_12:setPosition(20, 20 + var_68_11 * 35 + var_68_9)
		end
	end

	for iter_68_7 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if var_68_0:getTotalAttrWithOutBook(iter_68_7) > 0 then
			var_68_11 = var_68_11 + 1

			local var_68_13 = arg_68_0:createLabel(iter_68_7)

			var_68_13:addTo(var_68_2)
			var_68_13:setPosition(20, 20 + var_68_11 * 35 + var_68_9)
		end
	end

	local var_68_14 = arg_68_0:setGrowAttrLabel(55 + var_68_11 * 35 + var_68_9)

	var_68_4:y(var_68_14 + 15)
	var_68_3:y(var_68_14 + 15)
	var_68_2:height(var_68_14 + 43)
	var_68_2:setPosition(cc.p(0, 0))
end

function var_0_2.setGrowAttrLabel(arg_69_0, arg_69_1)
	local var_69_0 = arg_69_0:nodeByName("shuxing_container")
	local var_69_1 = arg_69_0.hero
	local var_69_2 = var_69_1.bookshelfLev

	if var_69_2 == 0 then
		var_69_2 = 1
	end

	local var_69_3 = xyd.tables.bookShelfTable:attribute(var_69_2)

	local function var_69_4(arg_70_0)
		local var_70_0 = var_69_1:getAttrGlow(arg_70_0)
		local var_70_1 = tonumber(var_69_3[arg_70_0])

		if var_69_1:getFavorAttrGrowth() > 0 or var_69_1:getHouseAttrGrowthByType(arg_70_0) > 0 then
			local var_70_2 = var_69_1:getFavorAttrGrowByType(arg_70_0)
			local var_70_3 = var_69_1:getHouseAttrGrowByType(arg_70_0)

			text = "+" .. string.format("%.2f(%0.1f%%)", var_70_0 * var_70_1 * 0.01 + var_70_2 + var_70_3, var_70_1 + var_69_1:getFavorAttrGrowth() * 100 + var_69_1:getHouseAttrGrowthByType(arg_70_0) * 100)
		elseif var_70_1 ~= 0 then
			text = "+" .. string.format("%.2f(%0.1f%%)", var_70_0 * var_70_1 * 0.01, var_70_1)
		elseif var_70_1 == 0 then
			text = ""
		end

		return text
	end

	local var_69_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_69_5:getChildByName("txt_title"):setString(var_0_1:translation("HERO_BUTTON_MINJIECHENGZHANG"))
	var_69_5:getChildByName("title_bg"):width(34 + var_69_5:getChildByName("txt_title"):getWidth())
	var_69_5:getChildByName("txt_ini"):setString(var_69_1:getAttrGlow(xyd.AttributeType.AGILE))
	var_69_5:getChildByName("txt_add"):setString(var_69_4(xyd.AttributeType.AGILE))

	local var_69_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_69_6:getChildByName("txt_title"):setString(var_0_1:translation("HERO_BUTTON_ZHILICHENGZHANG"))
	var_69_6:getChildByName("title_bg"):width(34 + var_69_6:getChildByName("txt_title"):getWidth())
	var_69_6:getChildByName("txt_ini"):setString(var_69_1:getAttrGlow(xyd.AttributeType.WISE))
	var_69_6:getChildByName("txt_add"):setString(var_69_4(xyd.AttributeType.WISE))

	local var_69_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_69_7:getChildByName("txt_title"):setString(var_0_1:translation("HERO_BUTTON_LILIANGCHENGZHANG"))
	var_69_7:getChildByName("title_bg"):width(34 + var_69_7:getChildByName("txt_title"):getWidth())
	var_69_7:getChildByName("txt_ini"):setString(var_69_1:getAttrGlow(xyd.AttributeType.STRENGTH))
	var_69_7:getChildByName("txt_add"):setString(var_69_4(xyd.AttributeType.STRENGTH))
	var_69_5:addTo(var_69_0)
	var_69_5:setPosition(20, arg_69_1)
	var_69_6:addTo(var_69_0)
	var_69_6:setPosition(20, arg_69_1 + 35)
	var_69_7:addTo(var_69_0)
	var_69_7:setPosition(20, arg_69_1 + 70)

	return arg_69_1 + 110
end

function var_0_2.createBookLabel(arg_71_0, arg_71_1, arg_71_2)
	local var_71_0 = arg_71_0.hero
	local var_71_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_71_1:getChildByName("txt_title"):setString(xyd.tables.attr:name(arg_71_1))
	var_71_1:getChildByName("title_bg"):width(34 + var_71_1:getChildByName("txt_title"):getWidth())
	var_71_1:getChildByName("txt_ini"):setString(math.ceil(math.max(0, var_71_0:getSkillBookAttr(arg_71_1))))
	var_71_1:getChildByName("txt_add"):setString("")

	return var_71_1
end

function var_0_2.createLabel(arg_72_0, arg_72_1, arg_72_2)
	local var_72_0 = arg_72_0.hero
	local var_72_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/shuxing_item.csb")

	var_72_1:getChildByName("txt_title"):setString(xyd.tables.attr:name(arg_72_1))
	var_72_1:getChildByName("title_bg"):width(34 + var_72_1:getChildByName("txt_title"):getWidth())
	var_72_1:getChildByName("txt_ini"):setString(math.ceil(math.max(0, var_72_0:getTotalAttr(arg_72_1) - var_72_0:getEquipFumoAttr(arg_72_1) - var_72_0:getEquipAttr(arg_72_1) - var_72_0:getSkillAttr(arg_72_1) - var_72_0:getSkill2Attr(arg_72_1) - var_72_0:getTotalPracticeAttr(arg_72_1) - var_72_0:getBookShelfAttr(arg_72_1) - var_72_0:getInscriptionAttr(arg_72_1) - var_72_0:getConquerSchoolAttr(arg_72_1))))

	local var_72_2 = math.ceil(var_72_0:getEquipFumoAttr(arg_72_1) + var_72_0:getEquipAttr(arg_72_1) + var_72_0:getSkillAttr(arg_72_1) + var_72_0:getSkill2Attr(arg_72_1) + var_72_0:getTotalPracticeAttr(arg_72_1) + var_72_0:getBookShelfAttr(arg_72_1) + var_72_0:getInscriptionAttr(arg_72_1) + var_72_0:getConquerSchoolAttr(arg_72_1))

	if var_72_2 > 0 then
		var_72_1:getChildByName("txt_add"):setString("+" .. var_72_2 .. (xyd.tables.attr:suffix(arg_72_1) ~= "" and xyd.tables.attr:suffix(arg_72_1) or ""))
	else
		var_72_1:getChildByName("txt_add"):setString("")
	end

	return var_72_1
end

function var_0_2.updateButtonBrightState(arg_73_0)
	if arg_73_0.state == var_0_7 or arg_73_0.state == var_0_8 or arg_73_0.state == var_0_9 or arg_73_0.state == var_0_10 or arg_73_0.state == var_0_11 or arg_73_0.state == var_0_12 or arg_73_0.state == var_0_14 or arg_73_0.state == var_0_13 or arg_73_0.state == var_0_15 then
		arg_73_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.normal)
		arg_73_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.normal)
		arg_73_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.normal)
		arg_73_0:nodeByName("button_inscription"):setBrightStyle(ccui.BrightStyle.normal)
		arg_73_0:nodeByName("button_breach"):setBrightStyle(ccui.BrightStyle.normal)
	end

	if arg_73_0.state == var_0_7 then
		arg_73_0:nodeByName("btn_main"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_73_0.state == var_0_9 then
		arg_73_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_73_0.state == var_0_10 then
		arg_73_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_73_0.state == var_0_11 then
		-- block empty
	elseif arg_73_0.state == var_0_14 then
		arg_73_0:nodeByName("button_inscription"):setBrightStyle(ccui.BrightStyle.highlight)
	elseif arg_73_0.state == var_0_15 then
		arg_73_0:nodeByName("button_breach"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_2.clickInfoButton(arg_74_0)
	if arg_74_0.sendSkillLevUpRequest then
		arg_74_0:sendSkillLevUpRequest()
	end

	local var_74_0 = arg_74_0.infoContainer:getContentSize().width
	local var_74_1 = arg_74_0.mainContainer:getContentSize().width

	if arg_74_0.state ~= var_0_10 then
		local var_74_2 = arg_74_0.containers[arg_74_0.state]
		local var_74_3 = {}

		table.insert(var_74_3, cc.ScaleTo:create(0.2, 0))
		table.insert(var_74_3, cc.CallFunc:create(function()
			local var_75_0 = {}

			table.insert(var_75_0, cc.DelayTime:create(0.1))
			table.insert(var_75_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_75_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_75_0, cc.ScaleTo:create(0.05, 1))
			var_74_2:hide()
			arg_74_0.infoContainer:scale(0)
			arg_74_0.infoContainer:show()
			arg_74_0.infoContainer:runAction(transition.sequence(var_75_0))
		end))
		var_74_2:runAction(transition.sequence(var_74_3))

		arg_74_0.state = var_0_10

		arg_74_0:updateButtonBrightState()
	else
		arg_74_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_2.clickSkillButton(arg_76_0)
	if arg_76_0.sendSkillLevUpRequest then
		arg_76_0:sendSkillLevUpRequest()
	end

	local var_76_0 = arg_76_0.infoContainer:getContentSize().width
	local var_76_1 = arg_76_0.mainContainer:getContentSize().width

	if arg_76_0.state ~= var_0_9 then
		if arg_76_0.skillList and not tolua.isnull(arg_76_0.skillList) then
			if arg_76_0.skillCount and arg_76_0.skillCount == 4 then
				arg_76_0.skillList:getScrollNode():setPositionY(-3)
			elseif arg_76_0.skillCount and arg_76_0.skillCount == 5 then
				arg_76_0.skillList:getScrollNode():setPositionY(-120)
			end
		end

		local var_76_2 = arg_76_0.containers[arg_76_0.state]
		local var_76_3 = {}

		table.insert(var_76_3, cc.ScaleTo:create(0.2, 0))
		table.insert(var_76_3, cc.CallFunc:create(function()
			local var_77_0 = {}

			table.insert(var_77_0, cc.DelayTime:create(0.1))
			table.insert(var_77_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_77_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_77_0, cc.ScaleTo:create(0.05, 1))
			table.insert(var_77_0, cc.CallFunc:create(function()
				arg_76_0:skillListAction(0.01, 15, 0.2)
			end))
			var_76_2:hide()
			arg_76_0.skillContainer:scale(0)
			arg_76_0.skillContainer:show()
			arg_76_0.skillContainer:runAction(transition.sequence(var_77_0))
		end))
		var_76_2:runAction(transition.sequence(var_76_3))

		arg_76_0.state = var_0_9

		arg_76_0:updateButtonBrightState()
	else
		arg_76_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	if arg_76_0.state == var_0_9 then
		arg_76_0:updateSkillContainer()
		arg_76_0:updateAllSkillTips()
	end
end

function var_0_2.skillListAction(arg_79_0, arg_79_1, arg_79_2, arg_79_3)
	if arg_79_0.hero:isAwaken() then
		local var_79_0 = var_0_16.performWithDelayGlobal(function()
			if not arg_79_0 or tolua.isnull(arg_79_0) then
				return
			end

			local var_80_0 = 120 / arg_79_2
			local var_80_1 = -120
			local var_80_2 = var_0_16.scheduleGlobal(function()
				var_80_1 = var_80_1 + var_80_0

				if arg_79_0 and var_80_1 <= 0 then
					if arg_79_0.skillList and not tolua.isnull(arg_79_0.skillList) then
						arg_79_0.skillList:getScrollNode():setPositionY(var_80_1)
					end
				elseif skillHandle then
					var_0_16.unscheduleGlobal(skillHandle)
				end
			end, arg_79_1)
		end, arg_79_3)
	end
end

function var_0_2.updateAllSkillTips(arg_82_0)
	local var_82_0 = arg_82_0.hero:getSkillId()

	for iter_82_0, iter_82_1 in pairs(var_82_0) do
		arg_82_0:createSkillTip(iter_82_0, iter_82_1)
	end
end

function var_0_2.clickShowDetailButton(arg_83_0)
	local var_83_0 = arg_83_0.infoContainer:getContentSize().width
	local var_83_1 = arg_83_0.mainContainer:getContentSize().width

	if arg_83_0.state ~= var_0_11 then
		local var_83_2 = arg_83_0.containers[arg_83_0.state]
		local var_83_3 = {}

		table.insert(var_83_3, cc.ScaleTo:create(0.2, 0))
		table.insert(var_83_3, cc.CallFunc:create(function()
			local var_84_0 = {}

			table.insert(var_84_0, cc.DelayTime:create(0.1))
			table.insert(var_84_0, cc.ScaleTo:create(0.1, 1.2))
			table.insert(var_84_0, cc.ScaleTo:create(0.05, 0.95))
			table.insert(var_84_0, cc.ScaleTo:create(0.05, 1))
			var_83_2:hide()
			arg_83_0.equipInfoContainer:scale(0)
			arg_83_0.equipInfoContainer:show()
			arg_83_0.equipInfoContainer:runAction(transition.sequence(var_84_0))
		end))
		var_83_2:runAction(transition.sequence(var_83_3))

		arg_83_0.state = var_0_11

		arg_83_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.normal)
		arg_83_0:nodeByName("button_tujian"):setBrightStyle(ccui.BrightStyle.normal)
		arg_83_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.normal)
		arg_83_0:nodeByName("button_show_detail"):setBrightStyle(ccui.BrightStyle.highlight)

		local var_83_4 = arg_83_0.scrollBg2:getViewRect()

		arg_83_0.scrollBg2:scrollTo(0, var_83_4.height - arg_83_0.scrollBg2.scrollHeight)
	else
		arg_83_0:nodeByName("button_show_detail"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_2.clickCardButton(arg_85_0)
	if arg_85_0.sendSkillLevUpRequest then
		arg_85_0:sendSkillLevUpRequest()
	end

	local var_85_0 = arg_85_0.infoContainer:getContentSize().width
	local var_85_1 = arg_85_0.mainContainer:getContentSize().width

	if not arg_85_0.isCardShow then
		local var_85_2 = {}

		table.insert(var_85_2, cc.DelayTime:create(0.1))
		table.insert(var_85_2, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_85_2, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_85_2, cc.ScaleTo:create(0.05, 1))
		table.insert(var_85_2, cc.CallFunc:create(function()
			arg_85_0.cardBlock:show()
		end))
		arg_85_0.cardContainer:scale(0)
		arg_85_0.cardContainer:show()
		arg_85_0.cardContainer:runAction(transition.sequence(var_85_2))

		arg_85_0.isCardShow = true
	else
		local var_85_3 = {}

		table.insert(var_85_3, cc.ScaleTo:create(0.2, 0))
		table.insert(var_85_3, cc.CallFunc:create(function()
			arg_85_0.cardContainer:hide()
			arg_85_0.cardBlock:hide()
		end))
		arg_85_0.cardContainer:runAction(transition.sequence(var_85_3))

		arg_85_0.isCardShow = false
	end
end

function var_0_2.skillLevelUp(arg_88_0, arg_88_1, arg_88_2)
	local var_88_0 = arg_88_0.hero

	if var_88_0:getSkillLevel(arg_88_1) >= var_88_0:getLevel() then
		return
	end

	if arg_88_0.skillPoints < 1 then
		if not xyd.tables.vip:skillBuy(arg_88_0.selfPlayer.vip) then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_17:translation("SKILL_POINT_VIP"), function()
				xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
					windowState = true
				})
			end, {
				rightName = var_0_17:translation("CHECK_PRIVILEGE")
			}, nil, arg_88_0.colorMode)
		else
			local var_88_1 = arg_88_0.selfPlayer.buySkillTimes
			local var_88_2 = xyd.tables.refreshCost:buySkillCost(var_88_1 + 1)

			if var_88_2 > arg_88_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_17:translation("ZUANSHI_ABSENCE"), function()
					local var_90_0 = {}

					var_90_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_90_0)
				end, nil, nil, arg_88_0.colorMode)
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_0_17:translation("SKILL_POINT_ABSENCE"),
					string.format(var_0_17:translation("SKILL_POINT_BUY"), var_88_2, var_88_1)
				}, function()
					arg_88_0.selfPlayer:buySkillPoint()
				end, nil, nil, arg_88_0.colorMode)
			end
		end

		return
	end

	local var_88_3 = xyd.FunctionID.ID_SKILL_UP

	if arg_88_0.selfPlayer:isFuncOpen(var_88_3) == false then
		local var_88_4 = xyd.tables.functionOpen:level(var_88_3)
		local var_88_5 = string.format(var_0_17:translation("FUNCTION_OPEN_TIP_LEVEL"), var_88_4)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_88_5
		})

		return
	end

	if xyd.tables.skillPrice:gold(var_88_0:getSkillLevel(arg_88_1)) > arg_88_0.selfPlayer.mana then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_17:translation("JINBI_ABSENCE"), function()
			local var_92_0 = xyd.FunctionID.ID_GOLD_HAND

			if arg_88_0.selfPlayer:isFuncOpen(var_92_0) == true then
				xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
			else
				local var_92_1 = xyd.tables.functionOpen:level(var_92_0)
				local var_92_2 = string.format(var_0_17:translation("FUNCTION_OPEN_TIP_LEVEL"), var_92_1)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_92_2
				})
			end
		end, nil, nil, arg_88_0.colorMode)

		return
	end

	local var_88_6 = arg_88_0.skillItems[arg_88_1]
	local var_88_7 = var_88_6:getChildByName("icon")
	local var_88_8, var_88_9 = arg_88_0.skillContainer:getChildByName("scroll_bg"):getPosition()
	local var_88_10, var_88_11 = var_88_6:getPosition()
	local var_88_12, var_88_13 = var_88_7:getPosition()
	local var_88_14 = var_88_7:getContentSize()
	local var_88_15 = cc.p(var_88_8 + var_88_10 + var_88_12 + var_88_14.width * 0.5, var_88_9 + var_88_11 + var_88_13 + var_88_14.height * 0.5)

	arg_88_0:playEffect(arg_88_0.skillContainer, "SkillUp", var_88_15, true)
	arg_88_2:setTouchEnabled(false)
	var_88_0:skilllevelUp(arg_88_1, function(arg_93_0, arg_93_1)
		if not tolua.isnull(arg_88_2) then
			arg_88_2:setTouchEnabled(true)
		end

		if arg_93_0 == xyd.error.OK then
			arg_88_0:updateSkillContainer()
			arg_88_0:setSkillContainer()

			arg_88_0.refresh_ = true

			audio.playSound(xyd.tables.sound:getSound("hero_upskill"))
		end
	end)
end

function var_0_2.buttonHandler(arg_94_0, arg_94_1, arg_94_2, arg_94_3)
	if arg_94_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_94_2)
		arg_94_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound(xyd.tables.sound:getSound("ui_button_click"), false)

		if arg_94_1 then
			arg_94_1(arg_94_2, arg_94_3)
		end
	elseif arg_94_3 == ccui.TouchEventType.began then
		local var_94_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_94_1 = cc.RepeatForever:create(var_94_0)

		arg_94_2:runAction(var_94_1)

		return true
	elseif arg_94_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_94_2)
		arg_94_2:setScale(1)
	end
end

function var_0_2.willClose(arg_95_0)
	if arg_95_0.skillPoints then
		arg_95_0.timeCount = arg_95_0.timeCount or 300

		cc.UserDefault:getInstance():setIntegerForKey(var_0_5, arg_95_0.skillPoints)
		cc.UserDefault:getInstance():setIntegerForKey(var_0_4, os.time())
		cc.UserDefault:getInstance():setIntegerForKey(var_0_6, arg_95_0.timeCount)

		if arg_95_0.timer then
			var_0_16.unscheduleGlobal(arg_95_0.timer)

			arg_95_0.timer = nil
		end
	end

	if arg_95_0.handler[1] ~= nil then
		var_0_16.unscheduleGlobal(arg_95_0.handler[1])
	end

	if arg_95_0.handler[2] ~= nil then
		var_0_16.unscheduleGlobal(arg_95_0.handler[2])
	end
end

function var_0_2.getHeroContainer(arg_96_0)
	if not arg_96_0.heroContainer_ then
		arg_96_0.heroContainer_ = arg_96_0:nodeByName("hero_container")

		arg_96_0.heroContainer_:setLocalZOrder(100)
	end

	return arg_96_0.heroContainer_
end

function var_0_2.updateEquip(arg_97_0, arg_97_1)
	arg_97_1 = arg_97_1 or arg_97_0.hero

	for iter_97_0, iter_97_1 in ipairs(arg_97_0.equipContainerlist_) do
		local var_97_0 = iter_97_1:getChildByName("green_plus")
		local var_97_1 = iter_97_1:getChildByName("white_plus")
		local var_97_2 = iter_97_1:getChildByName("green_label")
		local var_97_3 = iter_97_1:getChildByName("gray_label")
		local var_97_4 = iter_97_1:getChildByName("arrow")

		var_97_0:setVisible(false)
		var_97_1:setVisible(false)
		var_97_3:setVisible(false)
		var_97_2:setVisible(false)
		var_97_4:setVisible(false)

		local var_97_5 = arg_97_1:getEquipByIndex(iter_97_0)
		local var_97_6 = var_97_5:getFumoLev()
		local var_97_7 = var_97_5:getIcon(not var_97_5:isCollected())
		local var_97_8 = iter_97_1:getChildByName("icon")

		var_97_8:removeAllChildren()
		xyd.setSpecialItemBorderNewUI(var_97_8, var_97_5:getTableID(), not var_97_5:isCollected())

		if not var_97_5:isCollected() and var_97_5:isInBackpack() and arg_97_1:getLevel() >= var_97_5:getLevel() then
			var_97_0:setVisible(true)
			var_97_2:setString(var_0_17:translation("HERO_MAIN_HAVE_ITEM"))
			var_97_2:setVisible(true)
		elseif not var_97_5:isCollected() and var_97_5:isInBackpack() and arg_97_1:getLevel() < var_97_5:getLevel() then
			var_97_1:setVisible(true)
			var_97_3:setString(var_0_17:translation("HERO_MAIN_NO_EQUIP"))
			var_97_3:setVisible(true)
		elseif not var_97_5:isCollected() and not var_97_5:isInBackpack() and var_97_5:isHasMaterial() and arg_97_1:getLevel() >= var_97_5:getLevel() then
			var_97_0:setVisible(true)
			var_97_2:setString(var_0_17:translation("HERO_MAIN_CAN_COMPOSE"))
			var_97_2:setVisible(true)
		elseif not var_97_5:isCollected() and not var_97_5:isInBackpack() and var_97_5:isHasMaterial() and arg_97_1:getLevel() < var_97_5:getLevel() then
			var_97_1:setVisible(true)
			var_97_3:setString(var_0_17:translation("HERO_MAIN_CAN_COMPOSE"))
			var_97_3:setVisible(true)
		elseif not var_97_5:isCollected() and not var_97_5:isInBackpack() and not var_97_5:isHasMaterial() then
			var_97_3:setString(var_0_17:translation("HERO_MAIN_NO_ITEM"))
			var_97_3:setVisible(true)
		end

		if var_97_6 < 1 then
			iter_97_1:getChildByName("star_bg"):setVisible(false)
		end

		for iter_97_2 = xyd.MAX_STAR_LEVEL, var_97_6 + 1, -1 do
			iter_97_1:getChildByName("blue_star" .. iter_97_2):setVisible(false)
		end
	end
end

function var_0_2.getEquipContainerByIndex(arg_98_0, arg_98_1)
	local var_98_0 = arg_98_0.hero

	if not arg_98_0.equipContainerlist_ then
		arg_98_0.equipContainerlist_ = {}

		for iter_98_0 = 1, xyd.MAX_ITEM_NUM do
			local var_98_1 = arg_98_0:nodeByName("pos_node" .. iter_98_0)
			local var_98_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/equip.csb")

			var_98_2:setContentSize(var_98_2:getChildByName("background"):getContentSize())

			local var_98_3 = var_98_2:getContentSize()
			local var_98_4 = var_98_2:getChildByName("green_plus")
			local var_98_5 = var_98_2:getChildByName("white_plus")
			local var_98_6 = var_98_2:getChildByName("green_label")
			local var_98_7 = var_98_2:getChildByName("gray_label")
			local var_98_8 = var_98_2:getChildByName("arrow")

			var_98_4:setVisible(false)
			var_98_5:setVisible(false)
			var_98_7:setVisible(false)
			var_98_6:setVisible(false)
			var_98_8:setVisible(false)
			var_98_2:setName("equip_container" .. iter_98_0)
			var_98_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_98_2:setPosition(var_98_1:getPosition())
			var_98_2:addTo(arg_98_0:nodeByName("normal_equipment"), var_98_1:getLocalZOrder())
			table.insert(arg_98_0.equipContainerlist_, var_98_2)

			local var_98_9 = var_98_0:getEquipByIndex(iter_98_0)

			if not var_98_9:isCollected() and (var_98_9:getTableID() == 0 or xyd.tables.item:isAwakenItem(var_98_9:getTableID()) == 1) and not var_98_0:isAwaken() and not arg_98_0.task:isAwaking(var_98_0:getTableID(), xyd.AwakeType.HERO) then
				var_98_2:getChildByName("awake_equip_hide"):setVisible(true)
				var_98_2:getChildByName("awake_hide"):setVisible(true)
			else
				var_98_2:getChildByName("awake_equip_hide"):setVisible(false)
				var_98_2:getChildByName("awake_hide"):setVisible(false)

				local var_98_10 = var_98_9:getFumoLev()
				local var_98_11 = var_98_9:getIcon(not var_98_9:isCollected())
				local var_98_12 = var_98_2:getChildByName("icon")

				if xyd.isSuperHero(var_98_0) then
					xyd.setSpecialItemBorderNewUI(var_98_12, var_98_9:getTableID(), not var_98_9:isCollected(), var_98_0:getEquipLevel(iter_98_0))
				else
					xyd.setSpecialItemBorderNewUI(var_98_12, var_98_9:getTableID(), not var_98_9:isCollected())
				end

				for iter_98_1 = xyd.MAX_STAR_LEVEL, var_98_10 + 1, -1 do
					var_98_2:getChildByName("blue_star" .. iter_98_1):setVisible(false)
				end
			end
		end
	end

	return arg_98_0.equipContainerlist_[arg_98_1]
end

function var_0_2.getSpineEffect(arg_99_0, arg_99_1)
	local var_99_0 = var_0_19[arg_99_1] .. ".json"
	local var_99_1 = var_0_19[arg_99_1] .. ".atlas"

	return (var_0_18.new(var_99_0, var_99_1, 1))
end

function var_0_2.updateCollectWindow(arg_100_0)
	local var_100_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.heroCollectWnd)

	if var_100_0 then
		var_100_0:refreshSelectedHeroClass()
	end
end

function var_0_2.getFloatAttrs(arg_101_0, arg_101_1)
	local var_101_0 = clone(arg_101_1)

	if arg_101_1[1] and arg_101_1[1] > 0 then
		var_101_0[xyd.AttributeType.HP] = math.ceil((var_101_0[xyd.AttributeType.HP] or 0) + arg_101_1[1] * xyd.STRENGTH_HP_RATE)
		var_101_0[xyd.AttributeType.HUJIA] = math.ceil((var_101_0[xyd.AttributeType.HUJIA] or 0) + arg_101_1[1] * xyd.STRENGTH_HUJIA_RATE)
	end

	if arg_101_1[2] and arg_101_1[2] > 0 then
		var_101_0[xyd.AttributeType.AP] = math.ceil((var_101_0[xyd.AttributeType.AP] or 0) + arg_101_1[2] * xyd.WISE_AP_RATE)
		var_101_0[xyd.AttributeType.MOKANG] = math.ceil((var_101_0[xyd.AttributeType.MOKANG] or 0) + arg_101_1[2] * xyd.WISE_MOKANG_RATE)
	end

	if arg_101_1[3] and arg_101_1[3] > 0 then
		var_101_0[xyd.AttributeType.AD] = math.ceil((var_101_0[xyd.AttributeType.AD] or 0) + arg_101_1[3] * xyd.AGILE_AD_RATE)
		var_101_0[xyd.AttributeType.HUJIA] = math.ceil((var_101_0[xyd.AttributeType.HUJIA] or 0) + arg_101_1[3] * xyd.AGILE_HUJIA_RATE)
		var_101_0[xyd.AttributeType.AD_BAOJI] = math.ceil((var_101_0[xyd.AttributeType.AD_BAOJI] or 0) + arg_101_1[3] * xyd.AGILE_AD_BAOJI_RATE)
	end

	if arg_101_1[arg_101_0.hero:getHeroType()] then
		var_101_0[xyd.AttributeType.AD] = (var_101_0[xyd.AttributeType.AD] or 0) + arg_101_1[arg_101_0.hero:getHeroType()]
	end

	return var_101_0
end

function var_0_2.addActiveEffeft(arg_102_0, arg_102_1, arg_102_2, arg_102_3, arg_102_4)
	local var_102_0 = arg_102_3 or 1
	local var_102_1 = "skeletons/ui_effect/element_equip/element_" .. arg_102_2

	if arg_102_4 then
		var_102_1 = var_102_1 .. "xiao"
	end

	local var_102_2 = xyd.createEffect(var_102_1, var_102_0)
	local var_102_3 = arg_102_1:getContentSize()

	var_102_2:addTo(arg_102_1)
	var_102_2:setPosition(var_102_3.width / 2, var_102_3.height / 2)
	var_102_2:play(nil, true)
end

return var_0_2
