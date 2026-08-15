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
local var_0_5 = 1
local var_0_6 = 2
local var_0_7 = 3
local var_0_8 = 4
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

var_0_13.AddItem = "skeletons/ui_effect/common_effect_hero2/common_effect_hero2"
var_0_13.CanUpgrade = "skeletons/ui_effect/common_effect_hero1/common_effect_hero1"
var_0_13.CanEvolve = "skeletons/ui_effect/common_effect_hero12/common_effect_hero12"
var_0_13.Upgrade = "skeletons/ui_effect/common_effect_hero3/common_effect_hero3"
var_0_13.Evolve = "skeletons/ui_effect/common_effect_hero4/common_effect_hero4"
var_0_13.SkillUp = "skeletons/ui_effect/common_effect_hero7/common_effect_hero7"
var_0_13.CanSummon = "skeletons/ui_effect/common_effect_hero8/common_effect_hero8"
var_0_13.LevelUp = "skeletons/ui_effect/common_effect_exp_lv_up/common_effect_exp_lv_up"

function var_0_4.ctor(arg_4_0, arg_4_1, arg_4_2)
	var_0_4.super.ctor(arg_4_0, arg_4_1, arg_4_2)

	arg_4_0.hero = arg_4_2
	arg_4_0.UIEffects = {}
	arg_4_0.skillTips = {}
	arg_4_0.visibleHandler = {}
	arg_4_0.refresh_ = false
	arg_4_0.eatHandler = {}
	arg_4_0.needEquip = {}
	arg_4_0.needPotion = {}
	arg_4_0.needGold = 0
	arg_4_0.scroll_moving_end = false
	arg_4_0.scroll_is_moving = false
	arg_4_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
end

function var_0_4.willOpen(arg_5_0, arg_5_1)
	var_0_4.super:willOpen(arg_5_1)

	arg_5_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_5_0.maxLev = xyd.tables.player:heroMaxLev(arg_5_0.selfPlayer.lev)
	arg_5_0.skillPoints = arg_5_0.selfPlayer:getBackpack():getSkillBookNum()

	arg_5_0:layout()
	arg_5_0:updateLayout()

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

function var_0_4.updateLayout(arg_8_0)
	arg_8_0:nodeByName("button_jingyan"):setVisible(false)
	arg_8_0:nodeByName("img_label4"):setVisible(false)
	arg_8_0:nodeByName("button_jinhua"):setVisible(false)
	arg_8_0:nodeByName("img_label5"):setVisible(false)
	arg_8_0:nodeByName("next_hero"):setVisible(false)
	arg_8_0:nodeByName("last_hero"):setVisible(false)
	arg_8_0:nodeByName("img_label1"):setVisible(false)
	arg_8_0:nodeByName("text_name"):setString(arg_8_0.hero.player_name)

	if arg_8_0.hero.conquer_lev and arg_8_0.hero.conquer_lev > 0 then
		xyd.setConquerLev(arg_8_0.hero.conquer_lev, arg_8_0:nodeByName("text_lev"), arg_8_0:nodeByName("level_bg"), nil, nil, nil, nil, arg_8_0.hero.conquer_loop_id)
	else
		arg_8_0:nodeByName("text_lev"):setString(arg_8_0.hero.player_lev)
	end

	arg_8_0:nodeByName("text_laizi"):setString(xyd.tables.translation:translation("LAI_ZI"))
	xyd.setAvatarClip(arg_8_0:nodeByName("touxiang_container"), arg_8_0.hero.player_avatar, 1)

	local var_8_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_8_0.hero.player_avatar_frame and arg_8_0.hero.player_avatar_frame ~= 0 then
		var_8_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_8_0.hero.player_avatar_frame] .. ".png"
	end

	local var_8_1 = xyd.AssetLoader.get():loadSprite(var_8_0)

	var_8_1:setPosition(40, 40)
	arg_8_0:nodeByName("touxiangkuang"):addChild(var_8_1)
end

function var_0_4.layout(arg_9_0)
	arg_9_0.mainContainer = arg_9_0:nodeByName("card_container")
	arg_9_0.infoContainer = arg_9_0:nodeByName("info_container")
	arg_9_0.skillContainer = arg_9_0:nodeByName("skill_container")
	arg_9_0.equipInfoContainer = arg_9_0:nodeByName("equip_info_container")
	arg_9_0.addExpContainer = arg_9_0:nodeByName("add_exp_container")

	arg_9_0.mainContainer:zorder(1)
	arg_9_0:nodeByName("borrow_container"):setVisible(true)
	arg_9_0:nodeByName("normal_container"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_9_0):addEventListener(xyd.event.PET_UPDATE_SKILL_BOOK, function(arg_10_0)
		arg_9_0.skillContainer:getChildByName("jinengdian"):setString(arg_9_0.selfPlayer:getBackpack():getSkillBookNum())
	end)

	arg_9_0.containers = {}

	table.insert(arg_9_0.containers, arg_9_0.infoContainer)
	table.insert(arg_9_0.containers, arg_9_0.skillContainer)
	table.insert(arg_9_0.containers, arg_9_0.equipInfoContainer)
	table.insert(arg_9_0.containers, arg_9_0.addExpContainer)

	for iter_9_0, iter_9_1 in pairs(arg_9_0.containers) do
		iter_9_1:setVisible(false)
	end

	arg_9_0.infoContainer:setVisible(true)

	local var_9_0 = arg_9_0.infoContainer:getContentSize()

	arg_9_0.state = var_0_5

	local var_9_1 = arg_9_0.mainContainer:getChildByName("lev_des"):setString(var_0_11:translation("HERO_DENGJI"))
	local var_9_2 = arg_9_0.mainContainer:getChildByName("zhandou_des"):setString(var_0_11:translation("HERO_INFO_ZHANDOULI"))
	local var_9_3 = arg_9_0.mainContainer:getChildByName("jingyan_des"):setString(var_0_11:translation("HERO_INFO_JINGYAN"))

	arg_9_0:nodeByName("label_title"):setString(var_0_11:translation("LONG_PRESSED_EAT"))
	arg_9_0:nodeByName("label_title"):enableOutline(cc.c4b(100, 100, 100, 255), 1)
	arg_9_0.skillContainer:getChildByName("jinengdian"):setVisible(false)
	arg_9_0.skillContainer:getChildByName("left_skill_title"):setVisible(false)
	arg_9_0:setupButtonClick()

	arg_9_0.infoScrollBg = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_9_0.width, var_9_0.height - 40)
	}):onScroll(handler(arg_9_0, arg_9_0.infoScrollListener)):setTouchType(true):setBounceable(true):pos(15, 20):addTo(arg_9_0.infoContainer)

	local var_9_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/info_container.csb")

	arg_9_0.infoScrollBg:addScrollNode(var_9_4)
	var_9_4:setName("info_scroll_node")
	var_9_4:removeChild(var_9_4:getChildByName("background"))
	arg_9_0:parseChildren_(var_9_4)
	arg_9_0:clickInfoButton()

	local var_9_5 = arg_9_0.equipInfoContainer:getChildByName("scroll")

	arg_9_0.equipScrollBg = var_0_0.new({
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		viewRect = cc.rect(0, 0, var_9_5:getWidth(), var_9_5:getHeight())
	}):onScroll(handler(arg_9_0, arg_9_0.equipScrollListener)):setTouchType(true):setBounceable(false):pos(var_9_5:getPosition()):addTo(arg_9_0.equipInfoContainer)

	local var_9_6 = display.newNode()

	var_9_6:size(var_9_5:getPosition())
	var_9_5:removeSelf()
	arg_9_0.equipScrollBg:addScrollNode(var_9_6)

	local var_9_7 = arg_9_0:nodeByName("exp_scroll")

	arg_9_0.expScrollBg = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_9_7:getWidth(), var_9_7:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):onScroll(handler(arg_9_0, arg_9_0.expScrollListener)):setTouchType(true):setBounceable(false):pos(var_9_7:getPosition()):addTo(arg_9_0.addExpContainer)

	arg_9_0:updateExpInfoContainer()

	local var_9_8 = arg_9_0.skillContainer:getChildByName("scroll_bg")

	arg_9_0.skillList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 370, 560),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_9_8):onScroll(handler(arg_9_0, arg_9_0.infoScrollListener))
end

function var_0_4.playActions(arg_11_0)
	if not arg_11_0.actions_ then
		arg_11_0.actions_ = {}

		local var_11_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
		local var_11_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

		arg_11_0.actions_[1] = cc.RepeatForever:create(var_11_0)
		arg_11_0.actions_[2] = cc.RepeatForever:create(var_11_1)

		arg_11_0:getLastHeroArrow():runAction(arg_11_0.actions_[1])
		arg_11_0:getNextHeroArrow():runAction(arg_11_0.actions_[2])
	end
end

function var_0_4.playEffect(arg_12_0, arg_12_1, arg_12_2, arg_12_3, arg_12_4, arg_12_5)
	local var_12_0
	local var_12_1 = arg_12_5 or false

	if arg_12_0.UIEffects[arg_12_2] and not tolua.isnull(arg_12_0.UIEffects[arg_12_2]) then
		var_12_0 = arg_12_0.UIEffects[arg_12_2]
	else
		local var_12_2 = var_0_13[arg_12_2] .. ".json"
		local var_12_3 = var_0_13[arg_12_2] .. ".atlas"

		var_12_0 = var_0_12.new(var_12_2, var_12_3, 1)

		arg_12_1:addChild(var_12_0, 10)

		arg_12_0.UIEffects[arg_12_2] = var_12_0
	end

	var_12_0:pos(arg_12_3.x, arg_12_3.y)

	if arg_12_4 == true then
		var_12_0:setToSetupPose()
		var_12_0:setVisible(true)

		if var_12_1 then
			var_12_0:play(function()
				return
			end, true)
		else
			var_12_0:play(function()
				var_12_0:setVisible(false)
			end)
		end
	else
		var_12_0:setVisible(false)
	end
end

function var_0_4.playRepeatingEffect(arg_15_0)
	return
end

function var_0_4.getLastHeroArrow(arg_16_0)
	if not arg_16_0.lastArrow_ then
		local var_16_0 = arg_16_0:nodeByName("last_hero")

		var_16_0:setTouchEnabled(true)
		var_16_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "ended" then
				arg_16_0:changeHero(true)
			end

			return true
		end)
		var_16_0:setCascadeOpacityEnabled(true)

		arg_16_0.lastArrow_ = var_16_0
	end

	return arg_16_0.lastArrow_
end

function var_0_4.getNextHeroArrow(arg_18_0)
	if not arg_18_0.nextArrow_ then
		local var_18_0 = arg_18_0:nodeByName("next_hero")

		var_18_0:setTouchEnabled(true)
		var_18_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
			if arg_19_0.name == "ended" then
				arg_18_0:changeHero(false)
			end

			return true
		end)

		arg_18_0.nextArrow_ = var_18_0

		var_18_0:setCascadeOpacityEnabled(true)
	end

	return arg_18_0.nextArrow_
end

function var_0_4.changeHero(arg_20_0, arg_20_1)
	arg_20_0:unscheduleExpHandle()

	local function var_20_0(arg_21_0)
		if arg_21_0 == false then
			if arg_20_0.current_ < #arg_20_0.heros_ then
				arg_20_0.current_ = arg_20_0.current_ + 1
			else
				arg_20_0.current_ = 1
			end
		elseif arg_20_0.current_ > 1 then
			arg_20_0.current_ = arg_20_0.current_ - 1
		else
			arg_20_0.current_ = #arg_20_0.heros_
		end

		arg_20_0.hero = arg_20_0.heros_[arg_20_0.current_]

		if not arg_20_0.hero:isCollected() or arg_20_0.hero.is_show_ == 0 then
			var_20_0(arg_20_1)
		end
	end

	if arg_20_0.scrolly then
		arg_20_0.scrolly = nil
	end

	if arg_20_0.frontState then
		arg_20_0.frontState = nil
	end

	var_20_0(arg_20_1)
	arg_20_0:update()
	arg_20_0:updateExpInfoContainer()
	arg_20_0:resetEffect()

	if arg_20_0.state == var_0_6 and arg_20_0.hero:isAwaken() then
		arg_20_0:skillListAction(0.01, 15, 0.2)
	end

	audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
end

function var_0_4.unscheduleLevUpHandle(arg_22_0)
	if arg_22_0.visibleHandler and next(arg_22_0.visibleHandler) then
		for iter_22_0, iter_22_1 in ipairs(arg_22_0.visibleHandler) do
			var_0_10.unscheduleGlobal(iter_22_1)
		end
	end
end

function var_0_4.unscheduleExpHandle(arg_23_0)
	if arg_23_0.eatHandler[var_0_17] ~= nil then
		var_0_10.unscheduleGlobal(arg_23_0.eatHandler[var_0_17])
	end

	if arg_23_0.eatHandler[var_0_18] ~= nil then
		var_0_10.unscheduleGlobal(arg_23_0.eatHandler[var_0_18])
	end

	if arg_23_0.skillTextHandle then
		var_0_10.unscheduleGlobal(arg_23_0.skillTextHandle)
	end

	if arg_23_0.skillClickHandle then
		var_0_10.unscheduleGlobal(arg_23_0.skillClickHandle)
	end
end

function var_0_4.infoScrollListener(arg_24_0, arg_24_1)
	if arg_24_1.name == "began" then
		arg_24_0.scrollViewMoved_ = false
		arg_24_0.prevX_ = arg_24_1.x
		arg_24_0.prevY_ = arg_24_1.y
	elseif arg_24_1.name == "moved" and 5 <= math.abs(arg_24_1.y - arg_24_0.prevY_) then
		arg_24_0.scrollViewMoved_ = true
	end

	local var_24_0 = arg_24_0.infoScrollBg:getScrollNode()
	local var_24_1 = 0
	local var_24_2 = -(var_24_0:getCascadeBoundingBox().height - var_24_0:getContentSize().height)

	if var_24_1 < var_24_0:getPositionX() then
		arg_24_0.infoScrollBg:scrollTo(0, var_24_1)
	elseif var_24_2 > var_24_0:getPositionX() then
		arg_24_0.infoScrollBg:scrollTo(0, var_24_2)
	end
end

function var_0_4.equipScrollListener(arg_25_0, arg_25_1)
	if arg_25_1.name == "began" then
		arg_25_0.scroll_is_moving = false

		arg_25_0.equipScrollBg:scrollAuto()

		arg_25_0.scrollViewMoved_ = false
		arg_25_0.prevX_ = arg_25_1.x
		arg_25_0.prevY_ = arg_25_1.y

		if arg_25_0.scroll_moving_end == true then
			arg_25_0.scroll_moving_end = false
		end
	elseif arg_25_1.name == "moved" then
		local var_25_0 = arg_25_0.equipScrollBg:getScrollNode()
		local var_25_1 = 0
		local var_25_2 = -(var_25_0:getCascadeBoundingBox().height - arg_25_0.equipScrollBg:getViewRectInWorldSpace().height)

		if var_25_1 < var_25_0:getPositionY() then
			arg_25_0.scroll_is_moving = true
		elseif var_25_2 > var_25_0:getPositionY() then
			arg_25_0.scroll_is_moving = true
		else
			arg_25_0.scroll_is_moving = false
		end

		arg_25_0.scrolly = var_25_0:getPositionY()

		if 5 <= math.abs(arg_25_1.y - arg_25_0.prevY_) then
			arg_25_0.scrollViewMoved_ = true
		end
	elseif arg_25_1.name == "scrollEnd" then
		arg_25_0.scrolly = arg_25_0.equipScrollBg:getScrollNode():getPositionY()

		if arg_25_0.scroll_is_moving == true then
			arg_25_0.scroll_moving_end = true
			arg_25_0.scroll_is_moving = false
		end
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
	for iter_27_0 = 1, 6 do
		arg_27_0:nodeByName("img_label" .. iter_27_0):setTouchEnabled(false)
	end

	arg_27_0:nodeByName("button_tujian"):setVisible(false)
	arg_27_0:nodeByName("img_label2"):setVisible(false)
	arg_27_0.mainContainer:getChildByName("button_shuxing"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickInfoButton()
		end
	end)
	arg_27_0.mainContainer:getChildByName("button_jineng"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickSkillButton()
		end
	end)
	arg_27_0:nodeByName("button_linghunshi"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			if xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end

			xyd.playButtonSound()
			arg_27_0:clickStoneButton()
		end
	end)
	arg_27_0:nodeByName("button_show_detail"):addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickShowDetailButton()
		end
	end)
	arg_27_0:nodeByName("button_jingyan"):addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_27_0:clickAddExpButton()

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
				arg_27_0.expScrollBg:scrollTo(0, 0)
				var_0_10.performWithDelayGlobal(function()
					arg_27_0:playGuide(var_0_3)
				end, 0.5)
			end
		end
	end)
end

function var_0_4.clickJinjieButton(arg_34_0)
	local var_34_0 = arg_34_0.hero
	local var_34_1 = cc.p(arg_34_0:getHeroContainer():getPosition())
	local var_34_2 = arg_34_0:getHeroContainer():getContentSize()

	var_34_1.x = var_34_1.x + var_34_2.width * 0.5
	var_34_1.y = var_34_1.y + var_34_2.height * 0.5

	local var_34_3 = var_34_0:getColor()
	local var_34_4 = var_34_0:getStar()
	local var_34_5 = var_34_0:getMaxHP()
	local var_34_6 = var_34_0:getZhandouli()

	local function var_34_7()
		var_34_0:powerUp(function(arg_36_0, arg_36_1)
			if arg_36_0 == xyd.error.OK then
				arg_34_0:playEffect(arg_34_0.mainContainer, "Upgrade", var_34_1, true)

				local var_36_0 = arg_34_0:getHeroModel()

				for iter_36_0 = 1, var_0_1 do
					if var_34_0:getEquipByIndex(iter_36_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_34_0:getEquipByIndex(iter_36_0):getTableID()) == 0 then
						local var_36_1 = arg_34_0:getEquipContainerByIndex(iter_36_0)
						local var_36_2 = display.newNode()

						var_36_2:size(var_36_1:getWidth(), var_36_1:getHeight())

						item = var_34_0:getEquipByIndex(iter_36_0, var_34_0:getColor() - 1)

						xyd.setSpecialItemBorder(var_36_2, item:getTableID())
						var_36_2:addTo(arg_34_0.mainContainer, 101)
						var_36_2:pos(var_36_1:getPosition())

						local var_36_3, var_36_4 = arg_34_0:getHeroContainer():getPosition()
						local var_36_5 = var_36_3 + arg_34_0:getHeroContainer():getWidth() / 2
						local var_36_6 = var_36_0.chestPoint.x + var_36_5
						local var_36_7 = var_36_4 + var_36_0.chestPoint.y
						local var_36_8 = cc.Spawn:create(cc.ScaleTo:create(0.8, 0.1), cc.MoveTo:create(0.8, cc.p(var_36_6, var_36_7)))

						var_36_2:runActionOnce(var_36_8, true)
					end
				end

				local var_36_9 = {}

				table.insert(var_36_9, xyd.JINJIE_ATTR_RATE * (var_34_0:getColor() - 1))
				table.insert(var_36_9, xyd.JINJIE_ATTR_RATE * (var_34_0:getColor() - 1))
				table.insert(var_36_9, xyd.JINJIE_ATTR_RATE * (var_34_0:getColor() - 1))

				arg_34_0.isShow = true

				var_36_0:win(false, handler(arg_34_0, arg_34_0.setIsShow))
				var_36_0:playAttribute(arg_34_0:getFloatAttrs(var_36_9))
				arg_34_0:updateEquip()
				arg_34_0:updateAttrScore()
				arg_34_0:updateAttrLabels()
				arg_34_0:updateIntroduceText()
				arg_34_0:updateScrollBg()
				arg_34_0:updateCollectWindow()
				arg_34_0:updateNameLabel()
				arg_34_0:updateEquipInfoContainer()
				arg_34_0:setSkillContainer()
				arg_34_0:updateExpInfoContainer()
				arg_34_0:playRepeatingEffect()
				arg_34_0:CheckOneClick()
				audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))

				arg_34_0.refresh_ = true

				local var_36_10 = var_34_0:getMaxHP()
				local var_36_11 = var_34_0:getZhandouli()
				local var_36_12 = {
					type_ = xyd.LevelUpType.ADVANCE,
					hero = var_34_0,
					vals = {
						oldStar = var_34_4,
						oldColor = var_34_3,
						newColor = var_34_3 + 1,
						oldHP = var_34_5,
						newHP = var_36_10,
						oldForce = var_34_6,
						newForce = var_36_11
					}
				}

				if arg_36_1.restore_items and #arg_36_1.restore_items > 0 then
					function var_36_12.callback()
						print(var_0_11:translation("FUMO_RESTORE_NAME"))
						xyd.WindowManager.get():openWindow("alert_award", {
							awards = arg_36_1.restore_items,
							name = var_0_11:translation("FUMO_RESTORE_NAME")
						})
					end

					for iter_36_1 = 1, #arg_36_1.restore_items do
						local var_36_13 = {
							itemID = arg_36_1.restore_items[iter_36_1].table_id,
							itemNum = arg_36_1.restore_items[iter_36_1].item_num
						}

						arg_34_0.selfPlayer:getBackpack():addItem(var_36_13)
					end
				end

				arg_34_0:runActionOnce(cc.CallFunc:create(function()
					xyd.WindowManager.get():openWindow("levelup", var_36_12)
				end), nil, nil, 1)
			end
		end)
	end

	local var_34_8 = true

	for iter_34_0 = 1, var_0_1 do
		if var_34_0:getEquipByIndex(iter_34_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_34_0:getEquipByIndex(iter_34_0):getTableID()) == 0 and var_34_0.equips_[iter_34_0] == 0 then
			var_34_8 = false

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_11:translation("CANNOT_EVOLVE")
			})

			break
		end
	end

	if var_34_8 then
		if var_34_0:getFumoCount() > 0 then
			xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
				string.format(var_0_11:translation("ALERT_POWER_UP1"), var_34_0:getName()),
				var_0_11:translation("ALERT_POWER_UP2")
			}, function(arg_39_0)
				if arg_39_0 then
					var_34_7()
				end
			end)
		else
			var_34_7()
		end
	end
end

function var_0_4.update(arg_40_0, arg_40_1)
	local var_40_0 = arg_40_0.hero

	arg_40_0:getLastHeroArrow()
	arg_40_0:getNextHeroArrow()
	arg_40_0:playActions()
	arg_40_0:playRepeatingEffect()

	if arg_40_0.equipContainerlist_ then
		for iter_40_0, iter_40_1 in ipairs(arg_40_0.equipContainerlist_) do
			iter_40_1:removeAllNodeEventListeners()
			iter_40_1:removeSelf()
		end

		arg_40_0.equipContainerlist_ = nil
	end

	for iter_40_2 = 1, var_0_1 do
		local var_40_1 = arg_40_0:getEquipContainerByIndex(iter_40_2)
		local var_40_2 = var_40_0:getEquipByIndex(iter_40_2)

		var_40_1:setTouchEnabled(true)
		var_40_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
			if arg_41_0.name == "ended" and var_40_2:getTableID() > 0 then
				-- block empty
			end

			return true
		end)
	end

	if arg_40_0.heroModel_ then
		arg_40_0.heroModel_:removeSelf()

		arg_40_0.heroModel_ = nil
	end

	local var_40_3 = arg_40_1 or arg_40_0.hero

	arg_40_0:updateHeroModel(var_40_3)
	arg_40_0:updateAttrScore()
	arg_40_0:updateExp()
	arg_40_0:updateHeroStar()
	arg_40_0:updateAttrLabels()
	arg_40_0:updateHeroRecommend()
	arg_40_0:updateIntroduceText()
	arg_40_0:updateScrollBg()
	arg_40_0:setSkillContainer()
	arg_40_0:updateNameLabel()
	arg_40_0:updateEquipInfoContainer()
	arg_40_0:CheckOneClick()
end

function var_0_4.updateHeroRecommend(arg_42_0)
	arg_42_0:nodeByName("zhenrong_container"):setVisible(false)
end

function var_0_4.updateNameLabel(arg_43_0)
	local var_43_0 = arg_43_0.hero
	local var_43_1 = arg_43_0:nodeByName("name_text")

	var_43_1:setString(var_43_0:getName())

	if arg_43_0.nameBg then
		arg_43_0.mainContainer:removeChild(arg_43_0.nameBg)
	end

	if arg_43_0.colorText then
		arg_43_0.mainContainer:removeChild(arg_43_0.colorText)
	end

	local var_43_2, var_43_3 = arg_43_0:nodeByName("node_name_pos"):getPosition()

	if xyd.Color2Level[var_43_0:getColor()] ~= "" then
		local var_43_4 = {
			size = 28,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_43_2 + var_43_1:getWidth() / 2 - 12,
			y = var_43_1:getY(),
			color = xyd.color.HERO_QUALITY[var_43_0:getColor()],
			text = xyd.Color2Level[var_43_0:getColor()]
		}

		arg_43_0.colorText = xyd.AssetLoader.get():loadLabel(var_43_4)

		arg_43_0.colorText:addTo(arg_43_0.mainContainer)
		arg_43_0.colorText:align(display.CENTER_LEFT)
		arg_43_0.colorText:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_43_1:x(var_43_2 - 13)
	else
		var_43_1:x(var_43_2)
	end

	arg_43_0.nameBg = xyd.AssetLoader.get():loadSprite("windows/common/name_label" .. var_43_0:getColor() .. ".png")

	if arg_43_0.hero:isAwaken() then
		if arg_43_0.hero:isAwakeTwice() then
			arg_43_0.nameBg = xyd.AssetLoader.get():loadSprite("windows/common/name_label_awake_twice" .. var_43_0:getColor() .. ".png")
		else
			arg_43_0.nameBg = xyd.AssetLoader.get():loadSprite("windows/common/name_label_awake" .. var_43_0:getColor() .. ".png")
		end
	end

	arg_43_0.nameBg:addTo(arg_43_0.mainContainer)
	arg_43_0.nameBg:pos(var_43_2, var_43_3)
	var_43_1:setLocalZOrder(1)
end

function var_0_4.updateHeroStar(arg_44_0)
	local var_44_0 = arg_44_0.hero
	local var_44_1 = arg_44_0:nodeByName("bar")
	local var_44_2
	local var_44_3

	if var_44_0:getStar() >= xyd.MAX_STAR_LEVEL then
		var_44_2 = 100
		var_44_3 = var_0_11:translation("HERO_MAIN_MAX_STAR")
	else
		var_44_2 = math.min(var_44_0:getSuiPian() / xyd.StarLevelSuipian[var_44_0:getStar() + 1] * 100, 100)
		var_44_3 = var_44_0:getSuiPian() .. " / " .. xyd.StarLevelSuipian[var_44_0:getStar() + 1]
	end

	var_44_1:setPercent(var_44_2)
	arg_44_0:nodeByName("bar_text"):setString(var_44_3)

	for iter_44_0 = 1, xyd.HERO_TOTAL_STARS do
		arg_44_0.mainContainer:getChildByName("hero_star" .. iter_44_0):setVisible(iter_44_0 <= var_44_0:getStar())
	end
end

function var_0_4.updateExp(arg_45_0, arg_45_1)
	arg_45_1 = arg_45_1 or arg_45_0.hero

	arg_45_0:nodeByName("lev_txt"):setString(arg_45_1:getLevel())

	local var_45_0 = arg_45_1:getExp() - xyd.tables.petExp:totalExp(arg_45_1:getLevel() - 1)

	arg_45_0:nodeByName("exp_txt"):setString(var_45_0 .. " / " .. arg_45_1:getAddExp())
end

function var_0_4.playEatExpEffect(arg_46_0, arg_46_1)
	local var_46_0 = arg_46_0:getHeroContainer():getContentSize().width
	local var_46_1 = arg_46_0:getHeroContainer():getContentSize().height
	local var_46_2 = xyd.tables.sound:getSound("train_exp_up")

	audio.playSound(var_46_2, false)

	if not arg_46_0.eatExpEffect then
		local var_46_3 = var_0_13.LevelUp .. ".json"
		local var_46_4 = var_0_13.LevelUp .. ".atlas"

		arg_46_0.eatExpEffect = var_0_12.new(var_46_3, var_46_4, 1)

		arg_46_0.eatExpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_46_0.eatExpEffect:setPosition(var_46_0 / 2, var_46_1 / 2)
		arg_46_0.eatExpEffect:addTo(arg_46_0:getHeroContainer())
	end

	arg_46_0.eatExpEffect:play(nil, false)

	local var_46_5 = arg_46_1:getChildByName("item"):getContentSize().width
	local var_46_6 = arg_46_1:getChildByName("item"):getContentSize().height
	local var_46_7, var_46_8 = arg_46_1:getChildByName("item"):getPosition()

	if arg_46_0.clickEffect and not tolua.isnull(arg_46_0.clickEffect) then
		arg_46_0.clickEffect:removeAllChildren()
	end

	local var_46_9 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_46_10 = var_46_9 .. ".json"
	local var_46_11 = var_46_9 .. ".atlas"

	arg_46_0.clickEffect = var_0_12.new(var_46_10, var_46_11, 1)

	arg_46_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_46_0.clickEffect:setPosition(var_46_7 + var_46_5 / 2, var_46_8 + var_46_6 / 2)
	arg_46_1:addChild(arg_46_0.clickEffect)
	arg_46_0.clickEffect:setScale(0.7)
	arg_46_0.clickEffect:play(nil, false)
end

function var_0_4.playLevelUpEffect(arg_47_0, arg_47_1)
	local var_47_0 = arg_47_0:getHeroContainer():getContentSize().width
	local var_47_1 = arg_47_0:getHeroContainer():getContentSize().height
	local var_47_2 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_47_2, false)

	local var_47_3 = arg_47_0:getHeroContainer():getContentSize().width
	local var_47_4 = arg_47_0:getHeroContainer():getContentSize().height

	if arg_47_0.levelUpEffect == nil then
		local var_47_5 = var_0_13.Evolve .. ".json"
		local var_47_6 = var_0_13.Evolve .. ".atlas"

		arg_47_0.levelUpEffect = var_0_12.new(var_47_5, var_47_6, 1)

		arg_47_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_47_0.levelUpEffect:setPosition(var_47_3 / 2, var_47_4 / 2)
		arg_47_0.levelUpEffect:addTo(arg_47_0:getHeroContainer())
	end

	arg_47_0.levelUpEffect:play(nil, false)

	if arg_47_0.levelUpSprite == nil then
		arg_47_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

		arg_47_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
		arg_47_0.levelUpSprite:setPosition(var_47_3 / 2, var_47_4 / 2)
		arg_47_0.levelUpSprite:addTo(arg_47_0:getHeroContainer())
	end

	arg_47_0.levelUpSprite:setPosition(var_47_3 / 2, var_47_4 / 2)
	arg_47_0.levelUpSprite:setVisible(true)
	arg_47_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1, cc.p(var_47_3 / 2, var_47_4 / 2 + 100)), false, function()
		arg_47_0.levelUpSprite:setVisible(false)
	end)

	local var_47_7 = arg_47_1:getChildByName("item"):getContentSize().width
	local var_47_8 = arg_47_1:getChildByName("item"):getContentSize().height
	local var_47_9, var_47_10 = arg_47_1:getChildByName("item"):getPosition()

	if arg_47_0.clickEffect and not tolua.isnull(arg_47_0.clickEffect) then
		arg_47_0.clickEffect:removeAllChildren()
	end

	local var_47_11 = "skeletons/ui_effect/common_effect_exp_click/common_effect_exp_click"
	local var_47_12 = var_47_11 .. ".json"
	local var_47_13 = var_47_11 .. ".atlas"

	arg_47_0.clickEffect = var_0_12.new(var_47_12, var_47_13, 1)

	arg_47_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_47_0.clickEffect:setPosition(var_47_9 + var_47_7 / 2, var_47_10 + var_47_8 / 2)
	arg_47_1:addChild(arg_47_0.clickEffect)
	arg_47_0.clickEffect:setScale(0.7)
	arg_47_0.clickEffect:play(nil, false)
end

function var_0_4.resetEffect(arg_49_0)
	if arg_49_0.clickEffect then
		arg_49_0.clickEffect = nil
	end

	if arg_49_0.levelUpSprite then
		arg_49_0.levelUpSprite = nil
	end

	if arg_49_0.levelUpEffect then
		arg_49_0.levelUpEffect = nil
	end

	if arg_49_0.eatExpEffect then
		arg_49_0.eatExpEffect = nil
	end
end

function var_0_4.updateScrollBg(arg_50_0)
	local var_50_0 = arg_50_0.infoScrollBg:getViewRect()
	local var_50_1 = arg_50_0:nodeByName("shuxing_container")
	local var_50_2 = arg_50_0:nodeByName("jieshao_container")
	local var_50_3 = arg_50_0:nodeByName("zhenrong_container")
	local var_50_4 = var_50_1:getContentSize().height
	local var_50_5 = var_50_2:getContentSize().height
	local var_50_6 = 0

	var_50_2:setPosition(cc.p(0, var_50_6 + var_50_4))
	var_50_1:setPosition(cc.p(0, var_50_6))
	var_50_3:setPosition(cc.p(0, 0))
	arg_50_0.infoScrollBg:setScrollWidth(var_50_0.width)
	arg_50_0.infoScrollBg:setScrollHeight(var_50_4 + var_50_5 + var_50_6)
	arg_50_0.infoScrollBg:scrollTo(0, var_50_0.height - var_50_4 - var_50_5 - var_50_6)
end

function var_0_4.updateAttrScore(arg_51_0, arg_51_1)
	arg_51_1 = arg_51_1 or arg_51_0.hero

	arg_51_0:nodeByName("zhandouli_txt"):setString(arg_51_1:getZhandouli())
end

function var_0_4.updateHeroModel(arg_52_0, arg_52_1)
	local var_52_0 = {
		arg_52_1:getTableID()
	}
	local var_52_1 = arg_52_0:getHeroModel()

	var_52_1:setTouchSwallowEnabled(false)

	arg_52_0.modelState = xyd.ModelState.Walk

	local var_52_2 = arg_52_0:getHeroContainer():getContentSize().width / 2

	var_52_1:setPosition(cc.p(var_52_2, 0))
	arg_52_0:getHeroContainer():removeAllChildren()
	var_52_1:addTo(arg_52_0:getHeroContainer())
	var_52_1:setTouchEnabled(true)

	arg_52_0.isShow = false

	arg_52_0:getHeroContainer():addTouchEventListener(function(arg_53_0, arg_53_1)
		if arg_53_1 == ccui.TouchEventType.ended and not arg_52_0.isShow then
			arg_52_0:resetModelState()
		end
	end)
end

function var_0_4.setIsShow(arg_54_0)
	arg_54_0.isShow = false

	arg_54_0:getHeroModel():idle()
end

function var_0_4.resetModelState(arg_55_0)
	local var_55_0 = arg_55_0:getHeroModel()

	if arg_55_0.modelState == 6 then
		arg_55_0.modelState = arg_55_0.modelState + 1
	end

	arg_55_0.modelState = arg_55_0.modelState % 6
	arg_55_0.isShow = true

	local var_55_1

	if arg_55_0.modelState == xyd.ModelState.Walk then
		var_55_0:walk(true)

		arg_55_0.isShow = false
		var_55_1 = xyd.tables.model:getMoveSound(arg_55_0.hero:getModelID())
	elseif arg_55_0.modelState == xyd.ModelState.Win then
		var_55_0:win(false, handler(arg_55_0, arg_55_0.setIsShow))

		var_55_1 = xyd.tables.model:getWinSound(arg_55_0.hero:getModelID())
	elseif arg_55_0.modelState == xyd.ModelState.Attack1 then
		var_55_0:attack(1, nil, nil, handler(arg_55_0, arg_55_0.setIsShow))

		var_55_1 = xyd.tables.model:getNormalAttackSound(arg_55_0.hero:getModelID())
	elseif arg_55_0.modelState == xyd.ModelState.Attack2 then
		var_55_0:attack(2, nil, nil, handler(arg_55_0, arg_55_0.setIsShow))

		var_55_1 = xyd.tables.model:getAttack1Sound(arg_55_0.hero:getModelID())
	elseif arg_55_0.modelState == xyd.ModelState.Attack3 then
		var_55_0:attack(3, nil, nil, handler(arg_55_0, arg_55_0.setIsShow))

		var_55_1 = xyd.tables.model:getAttack2Sound(arg_55_0.hero:getModelID())
	elseif arg_55_0.modelState == xyd.ModelState.Attack4 then
		var_55_0:attack(4, nil, nil, handler(arg_55_0, arg_55_0.setIsShow))

		var_55_1 = xyd.tables.model:getAttack4Sound(arg_55_0.hero:getModelID())
	else
		arg_55_0:setIsShow()
	end

	if var_55_1 then
		audio.stopAllSounds()
		audio.playSound(var_55_1, false)
	end

	arg_55_0.modelState = arg_55_0.modelState + 1
end

function var_0_4.getHeroModel(arg_56_0, arg_56_1)
	if not arg_56_0.heroModel_ then
		arg_56_0.heroModel_ = arg_56_0.hero:getHeroModel()
	end

	return arg_56_0.heroModel_
end

function var_0_4.setSkillContainer(arg_57_0, arg_57_1)
	local var_57_0 = arg_57_1 or arg_57_0.hero
	local var_57_1 = var_57_0:getSkillId()
	local var_57_2 = {}

	arg_57_0.skillItems = {}

	arg_57_0.skillList:removeAllItems()

	local var_57_3 = 0
	local var_57_4 = 0

	for iter_57_0, iter_57_1 in ipairs(var_57_1) do
		if iter_57_0 == xyd.SKILL_INDEX.AwakeTwice then
			break
		end

		local var_57_5 = iter_57_1 == 0 or xyd.tables.skill:isAwakenSkill(iter_57_1) > 0

		if not (xyd.tables.hero:isCanAwaken(var_57_0:getTableID()) > 0 and arg_57_0.selfPlayer.maxTeamLev >= 90) and var_57_5 or var_57_5 and not var_57_0:isAwaken() then
			-- block empty
		else
			local var_57_6 = display.newNode()
			local var_57_7 = arg_57_0.skillList:newItem()
			local var_57_8 = xyd.tables.skill:icon(iter_57_1)
			local var_57_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/skill_item.csb")
			local var_57_10 = xyd.SpriteLoader.new(var_57_8, nil, extra_params, xyd.DefaultImageType.SKILL_ICON)
			local var_57_11 = var_57_9:getChildByName("background"):getContentSize()

			var_57_9:setContentSize(var_57_11)
			var_57_6:setContentSize(var_57_11)

			local var_57_12 = var_57_9:getChildByName("icon")
			local var_57_13 = var_57_9:getChildByName("border"):getChildByName("skill_hide")

			if not var_57_5 or var_57_0:isAwaken() then
				var_57_9:getChildByName("lev"):setVisible(true)
				var_57_9:getChildByName("level_extra"):setVisible(true)
				var_57_13:setVisible(false)
				var_57_9:getChildByName("skillBook"):setVisible(false)
				var_57_9:getChildByName("bookNum"):setVisible(false)

				stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

				stencil:setPosition(var_57_12:getWidth() / 2, var_57_12:getHeight() / 2)
				stencil:setAnchorPoint(cc.p(0.5, 0.5))
				stencil:scale(var_57_12:getWidth() / stencil:getWidth())

				local var_57_14 = cc.ClippingNode:create()

				var_57_14:setStencil(stencil)
				var_57_14:setInverted(true)
				var_57_14:setAlphaThreshold(0)
				var_57_12:addChild(var_57_14)
				var_57_14:addChild(var_57_10)
				var_57_10:align(display.LEFT_BOTTOM, 0, 0)
				var_57_10:scale((var_57_12:getWidth() - 3) / var_57_10:getWidth())

				local var_57_15 = var_57_9:getChildByName("btn_container")

				if var_57_0:getSkillLevel(iter_57_0) ~= 0 then
					local var_57_16 = var_57_0:getSkillLevel(iter_57_0) - xyd.SKILL_EXTRA[iter_57_0]

					var_57_9:getChildByName("lev"):setString("lv. " .. var_57_16)

					if var_57_0:getExtraSkillLevel() > 0 then
						var_57_9:getChildByName("level_extra"):show()
						var_57_9:getChildByName("level_extra"):setString("+" .. var_57_0:getExtraSkillLevel())
					else
						var_57_9:getChildByName("level_extra"):hide()
					end

					var_57_9:getChildByName("jiesuo"):setVisible(false)
				else
					local var_57_17 = var_0_11:translation("HERO_JIESUO_" .. iter_57_0)

					var_57_9:getChildByName("jiesuo"):setString(var_57_17)
					var_57_9:getChildByName("lev"):setVisible(false)
					var_57_9:getChildByName("level_extra"):hide()
				end
			else
				var_57_13:setVisible(true)
				var_57_9:getChildByName("lev"):setVisible(false)
				var_57_9:getChildByName("level_extra"):setVisible(false)
				var_57_9:getChildByName("jiesuo"):setString(var_0_11:translation("AWAKE_SKILL_LOCK_TIP"))
			end

			var_57_9:getChildByName("name"):setString(xyd.tables.skill:name(iter_57_1))
			var_57_9:addTo(var_57_6)
			table.insert(arg_57_0.skillItems, var_57_9)
			var_57_7:addContent(var_57_6)
			var_57_7:setItemSize(var_57_6:getWidth(), var_57_6:getHeight() + 12)
			arg_57_0.skillList:addItem(var_57_7)

			var_57_3 = var_57_3 + 1
			var_57_4 = var_57_4 + xyd.tables.petSkillBook:getBookNum(var_57_0:getSkillLevel(iter_57_0))

			arg_57_0:createSkillTip(iter_57_0, iter_57_1)
		end
	end

	if var_57_3 < 5 then
		arg_57_0.skillList:setBounceable(false)
	else
		arg_57_0.skillList:setBounceable(true)
	end

	arg_57_0.skillCount = var_57_3
	arg_57_0.skillBook = var_57_4

	arg_57_0.skillList:reload()
end

function var_0_4.addSkillLevel(arg_58_0, arg_58_1)
	local var_58_0 = arg_58_0.hero

	arg_58_0.skillBook = arg_58_0.skillBook + xyd.tables.petSkillBook:getBookNum(var_58_0:getSkillLevel(arg_58_1))

	if var_58_0:getSkillLevel(arg_58_1) >= var_58_0:getLevel() then
		local var_58_1 = var_0_11:translation("SKILL_UP_LIMIT")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_58_1
		})

		if arg_58_0.skillClickHandle then
			var_0_10.unscheduleGlobal(arg_58_0.skillClickHandle)
		end

		return
	elseif arg_58_0.selfPlayer:getBackpack():getSkillBookNum() <= arg_58_0.skillBook then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("PET_NO_SKILL_BOOK")
		})

		return
	else
		arg_58_0:playSKillUpEffect(arg_58_1)
		audio.playSound(xyd.tables.sound:getSound("hero_upskill"))

		var_58_0.skillLev_[arg_58_1] = var_58_0.skillLev_[arg_58_1] + 1

		arg_58_0:updateAttrScore()
		arg_58_0:updateSkillItem(arg_58_1, true)
		arg_58_0:updateSkillContainer(true)

		arg_58_0.skillCount = arg_58_0.skillCount + 1
		arg_58_0.skillPoints = arg_58_0.skillPoints - xyd.tables.petSkillBook:getBookNum(var_58_0:getSkillLevel(arg_58_1) - 1)

		arg_58_0.skillContainer:getChildByName("jinengdian"):setString(arg_58_0.skillPoints)
		arg_58_0:CheckOneClick()
	end
end

function var_0_4.sendLongSkillClick(arg_59_0, arg_59_1, arg_59_2)
	local var_59_0 = 0
	local var_59_1 = arg_59_0.selfPlayer:getBackpack():getSkillBookNum()

	arg_59_0.hero:skilllevelUp(arg_59_1, function(arg_60_0, arg_60_1)
		if arg_60_0 == xyd.error.OK then
			arg_59_0.refresh_ = true
		end
	end, arg_59_0.skillCount)
end

function var_0_4.skillLevelUp(arg_61_0, arg_61_1, arg_61_2, arg_61_3)
	local var_61_0 = arg_61_0.hero

	if var_61_0:getSkillLevel(arg_61_1) >= var_61_0:getLevel() then
		return
	end

	arg_61_0.skillPoints = arg_61_0.selfPlayer:getBackpack():getSkillBookNum()

	if arg_61_0.skillPoints < xyd.tables.petSkillBook:getBookNum(var_61_0:getSkillLevel(arg_61_1)) then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("PET_NO_SKILL_BOOK")
		})

		return
	end

	arg_61_3:setTouchEnabled(false)
	var_61_0:skilllevelUp(arg_61_1, function(arg_62_0, arg_62_1)
		if not tolua.isnull(arg_61_3) then
			arg_61_3:setTouchEnabled(true)
		end

		if arg_62_0 == xyd.error.OK then
			arg_61_0.refresh_ = true

			arg_61_0:playSKillUpEffect(arg_61_1)
			arg_61_0:createSkillTip(arg_61_1, arg_61_2)
			arg_61_0:updateSkillItem(arg_61_1)
			arg_61_0:updateSkillContainer()
			arg_61_0:updateAttrScore()
			audio.playSound(xyd.tables.sound:getSound("hero_upskill"))
		end
	end)
end

function var_0_4.playSKillUpEffect(arg_63_0, arg_63_1)
	local var_63_0 = arg_63_0.hero

	function generateSkillDesc2(arg_64_0, arg_64_1)
		local var_64_0 = {}
		local var_64_1 = xyd.tables.skill:desc3(arg_64_0)
		local var_64_2 = xyd.tables.skill:descNumInit(arg_64_0)
		local var_64_3 = xyd.tables.skill:descNumStep(arg_64_0)

		for iter_64_0 = 1, #var_64_1 do
			local var_64_4 = ""

			var_64_1[iter_64_0] = string.gsub(var_64_1[iter_64_0], "%%d%%", "%%d@")

			local var_64_5 = tonumber(var_64_3[iter_64_0])

			if var_64_5 - math.floor(var_64_5) ~= 0 then
				var_64_1[iter_64_0] = string.gsub(var_64_1[iter_64_0], "%%d", "%%.1f")
			end

			local var_64_6 = var_64_4 .. string.format(var_64_1[iter_64_0], var_64_5)
			local var_64_7 = string.gsub(var_64_6, "@", "%%")

			table.insert(var_64_0, var_64_7)
		end

		return var_64_0
	end

	local var_63_1 = var_0_13.LevelUp .. ".json"
	local var_63_2 = var_0_13.LevelUp .. ".atlas"
	local var_63_3 = var_0_12.new(var_63_1, var_63_2, 1)
	local var_63_4, var_63_5 = arg_63_0.skillItems[arg_63_1]:getChildByName("icon"):getPosition()
	local var_63_6 = arg_63_0.skillItems[arg_63_1]:getChildByName("icon"):getWidth()
	local var_63_7 = arg_63_0.skillItems[arg_63_1]:getChildByName("icon"):getHeight()

	var_63_3:setPosition(var_63_4 + var_63_6 / 2, var_63_5 + var_63_7 / 2)
	var_63_3:addTo(arg_63_0.skillItems[arg_63_1])
	var_63_3:play(nil, false)

	local var_63_8 = arg_63_0.skillItems[arg_63_1]:getWidth()
	local var_63_9 = {
		size = 24,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c4b(255, 255, 0, 0),
		dimensions = cc.size(var_63_8 - 10, 0)
	}
	local var_63_10 = generateSkillDesc2(var_63_0:getSkillId(arg_63_1), var_63_0:getSkillLevel(arg_63_1))
	local var_63_11 = arg_63_0.skillContainer:convertToNodeSpace(arg_63_0.skillItems[arg_63_1]:getChildByName("icon"):convertToWorldSpace(cc.p(0, 0)))
	local var_63_12 = 0.2
	local var_63_13 = 0.01

	if arg_63_0.skillTextHandle and arg_63_0.desc2list then
		for iter_63_0, iter_63_1 in ipairs(var_63_10) do
			table.insert(arg_63_0.desc2list, #arg_63_0.desc2list, iter_63_1)
		end
	else
		arg_63_0.desc2list = var_63_10
		arg_63_0.skillTextHandle = var_0_10.scheduleGlobal(function()
			local var_65_0 = xyd.WindowManager.get():getWindow("pet_main")

			if not var_65_0 then
				return
			end

			local var_65_1 = xyd.AssetLoader:get():loadLabel(var_63_9)

			var_65_1:setString(arg_63_0.desc2list[1])
			table.remove(arg_63_0.desc2list, 1)
			var_65_1:setAnchorPoint(0.5, 0.5)
			var_65_1:setPosition(var_63_11.x, var_63_11.y + var_63_7 / 2)
			var_65_1:align(display.CENTER_LEFT)
			var_65_1:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			var_65_0.skillContainer:addChild(var_65_1)

			local var_65_2 = cc.Spawn:create({
				cc.MoveBy:create(0.6, cc.p(0, 70)),
				cc.FadeOut:create(0.6)
			})

			var_65_1:runActionOnce(var_65_2, true, function()
				var_65_0.skillContainer:removeChild(var_65_1)
			end, 0)

			if not next(arg_63_0.desc2list) then
				arg_63_0.desc2list = nil

				if arg_63_0.skillTextHandle then
					var_0_10.unscheduleGlobal(arg_63_0.skillTextHandle)
				end
			end
		end, var_63_12)
	end
end

function var_0_4.createSkillTip(arg_67_0, arg_67_1, arg_67_2)
	local var_67_0 = arg_67_0.skillItems[arg_67_1]

	if not var_67_0 then
		return
	end

	local var_67_1, var_67_2 = var_67_0:getPosition()

	if var_67_0:getChildByName("skill_tip") and not tolua.isnull(var_67_0:getChildByName("skill_tip")) then
		var_67_0:removeChildByName("skill_tip")
	end

	local var_67_3 = display.newNode()

	var_67_3:setPosition(var_67_0:getChildByName("icon"):getPosition())
	var_67_3:setAnchorPoint(cc.p(0, 0))
	var_67_3:setContentSize(var_67_0:getChildByName("icon"):getContentSize())
	var_67_3:setTouchEnabled(true)
	var_67_3:addTo(var_67_0)
	var_67_3:setName("skill_tip")

	local var_67_4 = arg_67_0:convertToWorldSpace(cc.p(0, 0))

	var_67_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_68_0)
		if arg_68_0.name == "began" then
			local var_68_0 = {
				isShowSkillDesc4 = true,
				id = arg_67_2,
				skillLev = arg_67_0.hero:getSkillLevel(arg_67_1),
				extraSkillLevel = arg_67_0.hero:getExtraSkillLevel(),
				skillDesc4Change = arg_67_0.hero:checkSkillChange(arg_67_1)
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_68_1 = xyd.WindowManager.get():openWindow("skill_tips", var_68_0)
				local var_68_2 = var_67_3:convertToWorldSpace(cc.p(0, 0))

				var_68_1:setPosition(var_68_2.x + var_67_0:getContentSize().width + 7 - var_67_4.x, var_68_2.y - var_67_0:getContentSize().height + 20 - var_67_4.y)
			end

			return true
		elseif arg_68_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_4.updateAllSkillTips(arg_69_0)
	local var_69_0 = arg_69_0.hero:getSkillId()

	for iter_69_0, iter_69_1 in pairs(var_69_0) do
		if iter_69_1 <= 0 then
			var_69_0[iter_69_0] = nil
		end

		if arg_69_0.selfPlayer.maxTeamLev <= 80 and xyd.tables.skill:isAwakenSkill(iter_69_1) == 1 then
			var_69_0[iter_69_0] = nil
		end
	end

	for iter_69_2, iter_69_3 in pairs(var_69_0) do
		arg_69_0:createSkillTip(iter_69_2, iter_69_3)
	end
end

function var_0_4.setEquipNode(arg_70_0, arg_70_1, arg_70_2)
	if tolua.isnull(arg_70_0) or tolua.isnull(arg_70_2) then
		return
	end

	local var_70_0 = arg_70_0.hero
	local var_70_1 = xyd.split(var_0_11:translation("COLOR_TABLE"), ",")
	local var_70_2 = {
		size = 26,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = xyd.color.HERO_QUALITY[arg_70_1],
		text = var_70_1[arg_70_1] .. xyd.Color2Level[arg_70_1]
	}
	local var_70_3 = xyd.AssetLoader.get():loadLabel(var_70_2)

	var_70_3:addTo(arg_70_2)
	var_70_3:align(display.CENTER, arg_70_2:getChildByName("node_pos"):getPosition())
	var_70_3:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	var_70_3:setName("title")

	for iter_70_0 = 1, var_0_1 do
		local var_70_4 = var_70_0:getEquipByIndex(iter_70_0, arg_70_1)

		if var_70_4:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_70_4:getTableID()) == 0 then
			local var_70_5 = arg_70_2:getChildByName("icon" .. iter_70_0)

			var_70_5:removeAllChildren()

			local var_70_6 = display.newNode()

			var_70_6:size(var_70_5:getContentSize())
			var_70_5:addChild(var_70_6)
			xyd.setItemBorder(var_70_6, var_70_4:getTableID())
			var_70_6:setTouchEnabled(true)

			local var_70_7 = arg_70_0.equipScrollBg:getViewRectInWorldSpace()
			local var_70_8

			var_70_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_71_0)
				if arg_71_0.name == "began" then
					local var_71_0 = arg_70_0.equipScrollBg:getScrollNode()

					arg_70_0.scrolly = var_71_0:getPositionY()
					var_70_8 = arg_71_0.y
				elseif arg_71_0.name == "moved" then
					if arg_70_0.scroll_is_moving == true then
						if arg_70_0.scroll_moving_end == true then
							arg_70_0.equipScrollBg:scrollTo(0, arg_71_0.y - var_70_8 + arg_70_0.scrolly)
						end
					else
						arg_70_0.equipScrollBg:scrollTo(0, arg_71_0.y - var_70_8 + arg_70_0.scrolly)
					end
				elseif arg_71_0.name == "ended" then
					-- block empty
				end

				return true
			end)
		else
			local var_70_9 = arg_70_2:getChildByName("icon" .. iter_70_0)
			local var_70_10 = arg_70_2:getChildByName("awake_equip_hide")

			if var_70_10 then
				var_70_10:setVisible(true)
			end
		end
	end
end

function var_0_4.updateEquipInfoContainer(arg_72_0)
	local var_72_0 = arg_72_0.hero
	local var_72_1 = arg_72_0.equipScrollBg:getScrollNode()

	var_72_1:removeAllChildren()

	local var_72_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip_info.csb")

	var_72_2:size(var_72_2:getChildByName("background"):getContentSize())
	var_72_2:removeChild(var_72_2:getChildByName("background"))
	var_72_2:addTo(var_72_1)
	var_72_2:setName("node1")

	if var_72_0:getColor() >= xyd.tables.misc.maxPetColor then
		var_72_1:removeAllChildren()
	elseif var_72_0:getColor() == xyd.tables.misc.maxPetColor - 1 then
		var_72_2:align(display.LEFT_BOTTOM, 0, 0)
		arg_72_0:setEquipNode(var_72_0:getColor() + 1, var_72_2)
	elseif var_72_0:getColor() < xyd.tables.misc.maxPetColor - 1 then
		local var_72_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip_info.csb")

		var_72_3:size(var_72_2:getContentSize())
		var_72_3:removeChild(var_72_3:getChildByName("background"))
		var_72_3:addTo(var_72_1)
		var_72_3:align(display.LEFT_BOTTOM, 0, 0)
		var_72_2:align(display.LEFT_BOTTOM, 0, var_72_3:getHeight() + 20)
		var_72_3:setName("node2")
		arg_72_0:setEquipNode(var_72_0:getColor() + 1, var_72_2)
		arg_72_0:setEquipNode(var_72_0:getColor() + 2, var_72_3)
	end

	arg_72_0.equipInfoContainer:getChildByName("title1"):setString(var_0_11:translation("JINJIE_EQUIP"))

	local var_72_4 = arg_72_0.equipScrollBg:getViewRect()

	arg_72_0.equipScrollBg:setScrollWidth(var_72_4.width)
	arg_72_0.equipScrollBg:setScrollHeight(var_72_2:getHeight() + var_72_2:getY())
	arg_72_0.equipScrollBg:scrollTo(0, var_72_4.height - var_72_2:getHeight() - var_72_2:getY())

	if arg_72_0.scrolly then
		arg_72_0.equipScrollBg:scrollTo(0, arg_72_0.scrolly)
	end
end

function var_0_4.updateSkinInfo(arg_73_0, arg_73_1)
	local var_73_0 = arg_73_1:getChildByName("skin_name")
	local var_73_1 = arg_73_1:getChildByName("icon")
	local var_73_2 = arg_73_1:getChildByName("locked")
	local var_73_3 = arg_73_1:getChildByName("skin_buy")
	local var_73_4 = arg_73_1:getChildByName("buy_txt")
	local var_73_5 = arg_73_1:getChildByName("use_txt")
	local var_73_6 = arg_73_1:getChildByName("cancel_txt")
	local var_73_7 = arg_73_1:getChildByName("buy_gray")
	local var_73_8 = arg_73_1:getChildByName("skin_time")
	local var_73_9 = xyd.tables.hero:skinItem(arg_73_0.hero:getTableID())
	local var_73_10 = xyd.tables.item:name(var_73_9)

	var_73_0:setString(var_73_10)
	var_73_2:setVisible(false)
	var_73_5:setVisible(false)
	var_73_4:setVisible(false)
	var_73_6:setVisible(false)
	var_73_7:setVisible(false)

	if arg_73_0.selfPlayer:getBackpack():getItemNumByID(var_73_9) > 0 or arg_73_0.hero.hasSkin_ > 0 then
		if arg_73_0.hero.isSkinOn_ > 0 then
			xyd.setAvatarClip(var_73_1, arg_73_0.hero:getModelID(), 1)

			local var_73_11 = var_73_1:getContentSize().width
			local var_73_12 = var_73_1:getContentSize().height
			local var_73_13 = xyd.AssetLoader.get():loadSprite("windows/hero/has_skin_clip.png")

			var_73_1:addChild(var_73_13)
			var_73_13:setAnchorPoint(cc.p(0.5, 0.5))
			var_73_13:pos(var_73_11 / 2, var_73_12 / 2)
			var_73_13:setScale(var_73_12 / var_73_13:getHeight() + 0.1)
			var_73_2:setVisible(false)
			var_73_5:setVisible(false)
			var_73_4:setVisible(false)
			var_73_6:setVisible(true)
			var_73_3:addTouchEventListener(function(arg_74_0, arg_74_1)
				if arg_74_1 == ccui.TouchEventType.ended then
					local var_74_0 = {
						partner_id = arg_73_0.hero:getHeroID()
					}

					xyd.Backend.get():request(xyd.mid.SKIN_CANCEL, var_74_0, function(arg_75_0, arg_75_1)
						if arg_75_0 == xyd.error.OK then
							arg_73_0.hero.hasSkin_ = 1
							arg_73_0.hero.isSkinOn_ = 0

							arg_73_0.hero:setSkinInfo(arg_73_0.hero.isSkinOn_, arg_73_0.hero.hasSkin_)
							arg_73_0:update()
						end
					end)
				end
			end)
		else
			local var_73_14 = xyd.tables.item:skinModel(var_73_9)

			xyd.setAvatarClip(var_73_1, var_73_14, 6)

			local var_73_15 = var_73_1:getContentSize().width
			local var_73_16 = var_73_1:getContentSize().height
			local var_73_17 = xyd.AssetLoader.get():loadSprite("windows/hero/no_skin_clip.png")

			var_73_1:addChild(var_73_17)
			var_73_17:setAnchorPoint(cc.p(0.5, 0.5))
			var_73_17:pos(var_73_15 / 2, var_73_16 / 2)
			var_73_17:setScale(var_73_16 / var_73_17:getHeight() + 0.1)

			if arg_73_0.hero.hasSkin_ == 1 then
				var_73_2:setVisible(false)
			else
				var_73_2:setVisible(true)
			end

			var_73_5:setVisible(true)
			var_73_4:setVisible(false)
			var_73_6:setVisible(false)
			var_73_3:addTouchEventListener(function(arg_76_0, arg_76_1)
				if arg_76_1 == ccui.TouchEventType.ended then
					local var_76_0 = {
						partner_id = arg_73_0.hero:getHeroID(),
						item_id = var_73_9
					}

					xyd.Backend.get():request(xyd.mid.SKIN_ON, var_76_0, function(arg_77_0, arg_77_1)
						if arg_77_0 == xyd.error.OK then
							arg_73_0.hero.hasSkin_ = arg_77_1.has_skin
							arg_73_0.hero.isSkinOn_ = arg_77_1.is_skin_on
							arg_73_0.hero.skinId_ = arg_77_1.skin_id

							arg_73_0.hero:setSkinInfo(arg_73_0.hero.isSkinOn_, arg_73_0.hero.hasSkin_, arg_73_0.hero.skinId_)

							if arg_77_1.remove_item == 1 then
								local var_77_0 = {
									itemID = var_73_9
								}

								var_77_0.itemNum = 1

								arg_73_0.selfPlayer:getBackpack():removeItem(var_77_0)
							end

							arg_73_0:update()
						end
					end)
				end
			end)
		end
	else
		var_73_5:setVisible(false)
		var_73_6:setVisible(false)

		local var_73_18 = xyd.tables.item:skinModel(var_73_9)

		xyd.setAvatarClip(var_73_1, var_73_18, 6)

		local var_73_19 = var_73_1:getContentSize().width
		local var_73_20 = var_73_1:getContentSize().height
		local var_73_21 = xyd.AssetLoader.get():loadSprite("windows/hero/no_skin_clip.png")

		var_73_1:addChild(var_73_21)
		var_73_21:setAnchorPoint(cc.p(0.5, 0.5))
		var_73_21:pos(var_73_19 / 2, var_73_20 / 2)
		var_73_21:setScale(var_73_20 / var_73_21:getHeight() + 0.1)

		local var_73_22 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):getActivitiesList()
		local var_73_23

		for iter_73_0, iter_73_1 in ipairs(var_73_22) do
			if iter_73_1.table_id == xyd.Activities.Skin then
				var_73_23 = iter_73_1
			end
		end

		if var_73_23 and var_73_23.is_open == 1 then
			var_73_7:setVisible(false)
			var_73_2:setVisible(true)
			var_73_4:setVisible(true)
			var_73_3:addTouchEventListener(function(arg_78_0, arg_78_1)
				if arg_78_1 == ccui.TouchEventType.ended then
					xyd.WindowManager.get():openWindow("activities", {
						default_table_id = xyd.Activities.Skin
					})
				end
			end)
		else
			var_73_7:setVisible(true)
			var_73_4:setVisible(false)
			var_73_2:setVisible(true)
			var_73_3:setBright(false)
			var_73_3:addTouchEventListener(function(arg_79_0, arg_79_1)
				if arg_79_1 == ccui.TouchEventType.ended then
					local var_79_0 = var_0_11:translation("ACTIVITY_NO_OPEN")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_79_0
					})
				end
			end)
		end
	end
end

function var_0_4.updateExpInfoContainer(arg_80_0)
	if arg_80_0.expScrollBg then
		arg_80_0.expScrollBg:removeAllItems()
	end

	local var_80_0 = arg_80_0.expScrollBg
	local var_80_1 = arg_80_0.hero
	local var_80_2 = xyd.tables.item:getPetUseItems()

	arg_80_0.usedItemNums = {}

	for iter_80_0, iter_80_1 in pairs(var_80_2) do
		local var_80_3 = arg_80_0.expScrollBg:dequeueItem()

		if not var_80_3 then
			var_80_3 = arg_80_0.expScrollBg:newItem()
		else
			var_80_3:removeAllChildren(true)
		end

		local var_80_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/exp_item.csb")
		local var_80_5 = var_80_4:getChildByName("container")

		var_80_5:getChildByName("use_num"):setVisible(false)
		var_80_5:getChildByName("use_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		local var_80_6 = var_80_5:getContentSize()

		var_80_4:setContentSize(var_80_6)

		local var_80_7 = var_80_5:getChildByName("item")

		xyd.setItemBorder(var_80_7, iter_80_1)

		local var_80_8 = xyd.tables.item:name(iter_80_1)

		var_80_5:getChildByName("item_title"):setString(var_80_8)

		local var_80_9 = arg_80_0.selfPlayer:getBackpack():getItemNumByID(iter_80_1)

		var_80_5:getChildByName("num_text"):setString(var_80_9)

		local var_80_10 = xyd.tables.item:exp(iter_80_1)
		local var_80_11 = string.format(var_0_11:translation("EXP_ITEM_DESC"), var_80_10)

		var_80_5:getChildByName("get_num"):setString(var_80_11)

		local var_80_12 = var_80_5:getChildByName("use_button_container")
		local var_80_13 = cc.ui.UIPushButton.new({
			pressed = "windows/button/small_button6.png",
			disabled = "windows/button/small_button5.png",
			normal = "windows/button/small_button5.png"
		})

		var_80_13:setAnchorPoint(cc.p(0.5, 0.5))

		local var_80_14 = var_80_12:getContentSize()

		var_80_13:setPosition(cc.p(var_80_14.width / 2, var_80_14.height / 2))
		var_80_13:addTo(var_80_12)
		var_80_13:setName("use_btn")
		var_80_13:setTouchSwallowEnabled(false)

		if iter_80_0 == #var_80_2 then
			arg_80_0.useButton = var_80_13
		end

		arg_80_0.usedItemNums[iter_80_1] = 0

		var_80_3:addContent(var_80_4)
		var_80_3:setItemSize(380, 120)

		local var_80_15 = false

		var_80_13:onButtonPressed(function(arg_81_0)
			local var_81_0 = 0

			local function var_81_1()
				var_81_0 = var_81_0 + 0.03
				var_80_9 = arg_80_0:addExp(var_80_9, iter_80_1, var_80_5)

				var_80_5:getChildByName("num_text"):setString(var_80_9)
			end

			local function var_81_2()
				var_81_0 = var_81_0 + 0.1

				if var_81_0 > 0.5 and var_81_0 <= 4 then
					var_80_15 = true
					var_80_9 = arg_80_0:addExp(var_80_9, iter_80_1, var_80_5)

					var_80_5:getChildByName("num_text"):setString(var_80_9)
				elseif var_81_0 > 4 then
					arg_80_0.eatHandler[var_0_18] = var_0_10.scheduleGlobal(var_81_1, 0.03)

					var_0_10.unscheduleGlobal(arg_80_0.eatHandler[var_0_17])
				else
					var_80_15 = false
				end
			end

			var_80_15 = false
			arg_80_0.eatHandler[var_0_17] = var_0_10.scheduleGlobal(var_81_2, 0.1)
		end)
		var_80_13:onButtonRelease(function(arg_84_0)
			if arg_80_0.eatHandler[var_0_17] ~= nil then
				var_0_10.unscheduleGlobal(arg_80_0.eatHandler[var_0_17])
			end

			if arg_80_0.eatHandler[var_0_18] ~= nil then
				var_0_10.unscheduleGlobal(arg_80_0.eatHandler[var_0_18])
			end

			if var_80_15 == false then
				var_80_9 = arg_80_0:addExp(var_80_9, iter_80_1, var_80_5)

				var_80_5:getChildByName("num_text"):setString(var_80_9)
			end

			if arg_80_0.usedItemNums[iter_80_1] <= 0 then
				return
			end

			var_80_13:setButtonEnabled(false)
			xyd.ModelManager.get():loadModel(xyd.ModelType.PET):feed({
				pet_id = arg_80_0.hero:getPetID(),
				item_id = iter_80_1,
				item_num = arg_80_0.usedItemNums[iter_80_1]
			}, function(arg_85_0, arg_85_1, arg_85_2)
				if not tolua.isnull(var_80_13) then
					var_80_13:setButtonEnabled(true)
				end

				if arg_85_0 == xyd.error.OK then
					arg_80_0.refresh_ = true
					var_80_9 = arg_80_0.selfPlayer:getBackpack():getItemNumByID(iter_80_1)

					if not tolua.isnull(var_80_5) then
						var_80_5:getChildByName("num_text"):setString(var_80_9)
					end

					if arg_80_0.levelUpCount_ and arg_80_0.levelUpCount_ > 0 then
						local var_85_0 = {}

						table.insert(var_85_0, arg_80_0.levelUpCount_ * var_0_9:getHeroAttrGrow(arg_80_0.hero:getTableID(), xyd.AttributeType.STRENGTH, arg_80_0.hero:getStar()))
						table.insert(var_85_0, arg_80_0.levelUpCount_ * var_0_9:getHeroAttrGrow(arg_80_0.hero:getTableID(), xyd.AttributeType.WISE, arg_80_0.hero:getStar()))
						table.insert(var_85_0, arg_80_0.levelUpCount_ * var_0_9:getHeroAttrGrow(arg_80_0.hero:getTableID(), xyd.AttributeType.AGILE, arg_80_0.hero:getStar()))

						local var_85_1 = arg_80_0:getHeroModel()

						arg_80_0.isShow = true

						var_85_1:win(false, handler(arg_80_0, arg_80_0.setIsShow))
						var_85_1:playAttribute(arg_80_0:getFloatAttrs(var_85_0))
					end

					arg_80_0.levelUpCount_ = 0

					arg_80_0:updateEquip()
					arg_80_0:updateAttrLabels()
					arg_80_0:updateScrollBg()
				end
			end)

			if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_PET_THREE)
				xyd.StoryData.get():persist()

				arg_80_0.selfPlayer.petGuideId = 0

				if xyd.WindowManager.get():getWindow("guide") then
					xyd.WindowManager.get():closeWindow("guide")
				end
			end

			arg_80_0.usedItemNums[iter_80_1] = 0

			arg_80_0:CheckOneClick()
		end)
		arg_80_0.expScrollBg:addItem(var_80_3)
	end

	arg_80_0.expScrollBg:reload()
end

function var_0_4.addExp(arg_86_0, arg_86_1, arg_86_2, arg_86_3)
	local var_86_0 = arg_86_0.hero

	arg_86_0.levelUpCount_ = arg_86_0.levelUpCount_ or 0

	local var_86_1 = var_86_0:getExp()
	local var_86_2 = xyd.tables.petExp:totalExp(arg_86_0.maxLev)
	local var_86_3 = xyd.tables.item:exp(arg_86_2)

	if arg_86_1 <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = string.format(var_0_11:translation("PET_ITEM_NOT_ENOUGH"), xyd.tables.item:name(arg_86_2))
		})
	elseif var_86_2 <= var_86_1 then
		local var_86_4 = xyd.tables.sound:getSound("train_exp_max")

		audio.playSound(var_86_4, false)
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("EXP_FULL")
		})
	else
		arg_86_0.usedItemNums[arg_86_2] = arg_86_0.usedItemNums[arg_86_2] + 1
		arg_86_1 = arg_86_1 - 1

		local var_86_5 = clone(var_86_0:getLevel())

		if var_86_3 > 0 then
			var_86_0:addExp(var_86_3, arg_86_0.maxLev)
			arg_86_0:updateExp(var_86_0)
			arg_86_0:updateAttrScore(var_86_0)
		end

		if var_86_5 < var_86_0:getLevel() then
			arg_86_0.levelUpCount_ = arg_86_0.levelUpCount_ + var_86_0:getLevel() - var_86_5

			arg_86_0:playLevelUpEffect(arg_86_3)
			arg_86_0:updateEquip(var_86_0)
			arg_86_0:setSkillContainer()
		else
			arg_86_0:playEatExpEffect(arg_86_3)
		end

		if not tolua.isnull(arg_86_3) then
			arg_86_3:getChildByName("use_num"):setVisible(true)
			arg_86_3:getChildByName("use_num"):setString("X" .. arg_86_0.usedItemNums[arg_86_2])
		end

		if arg_86_0.visibleHandler[arg_86_2] ~= nil then
			var_0_10.unscheduleGlobal(arg_86_0.visibleHandler[arg_86_2])
		end

		local var_86_6 = arg_86_3:getChildByName("use_num")

		arg_86_0.visibleHandler[arg_86_2] = var_0_10.performWithDelayGlobal(function()
			if not tolua.isnull(arg_86_3) then
				var_86_6:setVisible(false)
			end
		end, 0.1)
	end

	return arg_86_1
end

function var_0_4.updateSkillContainer(arg_88_0, arg_88_1)
	local var_88_0 = arg_88_0.hero

	if arg_88_0.skillPoints < 0 then
		arg_88_0.skillPoints = 0
	end

	for iter_88_0, iter_88_1 in pairs(arg_88_0.skillItems) do
		local var_88_1 = iter_88_1:getChildByName("jiadian")

		if var_88_0:getSkillLevel(iter_88_0) ~= 0 then
			local var_88_2 = var_88_0:getSkillLevel(iter_88_0) - xyd.SKILL_EXTRA[iter_88_0]

			iter_88_1:getChildByName("lev"):setString("lv. " .. var_88_2)
			iter_88_1:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(var_88_0:getSkillLevel(iter_88_0)))
		end

		if not arg_88_1 and var_88_1 then
			if var_88_0:getSkillLevel(iter_88_0) == 0 or var_88_0:getSkillLevel(iter_88_0) >= var_88_0:getLevel() then
				var_88_1:setButtonEnabled(false)
			else
				var_88_1:setButtonEnabled(true)
			end
		end
	end
end

function var_0_4.updateIntroduceText(arg_89_0)
	local var_89_0 = arg_89_0.hero
	local var_89_1 = arg_89_0:nodeByName("jieshao_container")
	local var_89_2 = var_89_1:getChildByName("title1")
	local var_89_3 = var_89_1:getChildByName("hua_l")
	local var_89_4 = var_89_1:getChildByName("hua_r")
	local var_89_5 = var_89_1:getChildren()

	if var_89_5 then
		for iter_89_0, iter_89_1 in ipairs(var_89_5) do
			if iter_89_1 ~= var_89_2 and iter_89_1 ~= var_89_3 and iter_89_1 ~= var_89_4 then
				var_89_1:removeChild(iter_89_1)
			end
		end
	end

	local var_89_6 = 0

	if arg_89_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_CLOUD_CITY) then
		local var_89_7 = xyd.tables.hero:getHolyAttr(arg_89_0.hero:getTableID())
		local var_89_8 = display.newNode()
		local var_89_9 = 20

		var_89_6 = 60

		for iter_89_2 = 1, #var_89_7 do
			local var_89_10 = xyd.tables.petHolyAttr:icon(var_89_7[iter_89_2])

			if var_89_10 then
				local var_89_11 = xyd.AssetLoader.get():loadSprite(var_89_10)

				var_89_11:addTo(var_89_8)
				var_89_11:setPosition(cc.p(var_89_9, 0))
				var_89_11:setAnchorPoint(cc.p(0.5, 0.5))

				var_89_9 = var_89_9 + var_89_11:getContentSize().width + 30

				var_89_11:setTouchEnabled(true)
				var_89_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_90_0)
					if arg_90_0.name == "began" then
						arg_89_0.startClick = true

						var_89_11:setScale(0.9)

						return true
					elseif arg_90_0.name == "moved" then
						arg_89_0.startClick = false

						var_89_11:setScale(1)
					elseif arg_90_0.name == "ended" and arg_89_0.startClick then
						var_89_11:setScale(1)
					end
				end)
			end
		end

		var_89_8:addTo(var_89_1)
		var_89_8:setContentSize(var_89_1:getContentSize().width, 60)
		var_89_8:setPosition(cc.p(25, 0))
		var_89_8:setAnchorPoint(cc.p(0, 0))
	end

	local var_89_12 = {
		size = 22,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = 0 + var_89_6,
		color = cc.c3b(255, 144, 35),
		dimensions = cc.size(380, 54),
		text = var_89_0:getTalkText()
	}
	local var_89_13
	local var_89_14 = 0
	local var_89_15 = 0

	if var_89_0:getTalkText() then
		local var_89_16 = xyd.AssetLoader.get():loadLabel(var_89_12)

		var_89_16:addTo(var_89_1)
		var_89_16:setAnchorPoint(cc.p(0, 0))

		var_89_14 = var_89_16:getStringNumLines()
		var_89_15 = 10
	end

	local var_89_17 = {
		size = 26,
		x = 25,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		y = 10 + var_89_6 + var_89_14 * 30 + var_89_15,
		color = cc.c3b(70, 69, 69),
		dimensions = cc.size(380, 100),
		text = var_89_0:getDes()
	}
	local var_89_18 = xyd.AssetLoader.get():loadLabel(var_89_17)

	var_89_18:addTo(var_89_1)
	var_89_18:setAnchorPoint(cc.p(0, 0))

	local var_89_19 = var_89_18:getStringNumLines()

	var_89_4:y(var_89_17.y + var_89_19 * 40 + 20)
	var_89_3:y(var_89_17.y + var_89_19 * 40 + 20)
	var_89_2:y(var_89_17.y + var_89_19 * 40 + 20)

	local var_89_20 = var_89_2:getY()

	var_89_1:height(var_89_20 + 40)
end

function var_0_4.updateAttrLabels(arg_91_0)
	if not arg_91_0.hero then
		return
	end

	local var_91_0 = arg_91_0.hero
	local var_91_1 = 0
	local var_91_2 = arg_91_0:nodeByName("shuxing_container")
	local var_91_3 = var_91_2:getChildByName("title2")
	local var_91_4 = var_91_2:getChildByName("hua_l")
	local var_91_5 = var_91_2:getChildByName("hua_r")
	local var_91_6 = var_91_2:getChildren()

	if var_91_6 then
		for iter_91_0, iter_91_1 in ipairs(var_91_6) do
			if iter_91_1 ~= var_91_3 and iter_91_1 ~= var_91_4 and iter_91_1 ~= var_91_5 then
				var_91_2:removeChild(iter_91_1)
			end
		end
	end

	for iter_91_2 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if iter_91_2 ~= xyd.AttributeType.HP and iter_91_2 ~= xyd.AttributeType.HUJIA and iter_91_2 ~= xyd.AttributeType.MOKANG and iter_91_2 ~= xyd.AttributeType.REHP and var_91_0:getTotalAttr(iter_91_2) > 0 then
			var_91_1 = var_91_1 + 1

			local var_91_7, var_91_8, var_91_9, var_91_10 = arg_91_0:createLabel(iter_91_2, 20 + var_91_1 * 30)

			var_91_7:addTo(var_91_2)
			var_91_8:addTo(var_91_2)

			if var_91_9 then
				var_91_9:addTo(var_91_2)
			end

			if var_91_10 then
				var_91_10:addTo(var_91_2)
			end
		end
	end

	local var_91_11 = arg_91_0:setGrowAttrLabel(50 + var_91_1 * 30)

	var_91_5:y(var_91_11 + 15)
	var_91_4:y(var_91_11 + 15)
	var_91_3:y(var_91_11 + 15)
	var_91_2:height(var_91_11 + 75)
	var_91_2:setPosition(cc.p(0, 0))
end

function var_0_4.setGrowAttrLabel(arg_92_0, arg_92_1)
	local var_92_0 = arg_92_0.hero
	local var_92_1 = {
		size = 22,
		x = 20,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		y = arg_92_1
	}
	local var_92_2 = cc.c3b(255, 72, 0)
	local var_92_3 = cc.c3b(70, 69, 69)

	var_92_1.color = var_92_2
	var_92_1.text = var_0_11:translation("HERO_BUTTON_MINJIECHENGZHANG")

	local var_92_4 = xyd.AssetLoader.get():loadLabel(var_92_1)

	var_92_1.color = var_92_3
	var_92_1.font = xyd.AssetLoader.FONT_NAME
	var_92_1.text = var_92_0:getAttrGlow(xyd.AttributeType.AGILE)
	var_92_1.x = var_92_1.x + 2 + var_92_4:getContentSize().width

	local var_92_5 = xyd.AssetLoader.get():loadLabel(var_92_1)

	var_92_1.color = var_92_2
	var_92_1.font = xyd.AssetLoader.FONT_NAME
	var_92_1.text = var_0_11:translation("HERO_BUTTON_ZHILICHENGZHANG")
	var_92_1.y = var_92_1.y + 30
	var_92_1.x = 20

	local var_92_6 = xyd.AssetLoader.get():loadLabel(var_92_1)

	var_92_1.color = var_92_3
	var_92_1.font = xyd.AssetLoader.FONT_NAME
	var_92_1.text = var_92_0:getAttrGlow(xyd.AttributeType.WISE)
	var_92_1.x = var_92_1.x + 2 + var_92_6:getContentSize().width

	local var_92_7 = xyd.AssetLoader.get():loadLabel(var_92_1)

	var_92_1.color = var_92_2
	var_92_1.font = xyd.AssetLoader.FONT_NAME
	var_92_1.text = var_0_11:translation("HERO_BUTTON_LILIANGCHENGZHANG")
	var_92_1.y = var_92_1.y + 30
	var_92_1.x = 20

	local var_92_8 = xyd.AssetLoader.get():loadLabel(var_92_1)

	var_92_1.color = var_92_3
	var_92_1.font = xyd.AssetLoader.FONT_NAME
	var_92_1.text = var_92_0:getAttrGlow(xyd.AttributeType.STRENGTH)
	var_92_1.x = var_92_1.x + 2 + var_92_8:getContentSize().width

	local var_92_9 = xyd.AssetLoader.get():loadLabel(var_92_1)
	local var_92_10 = arg_92_0:nodeByName("shuxing_container")

	var_92_4:addTo(var_92_10)
	var_92_5:addTo(var_92_10)
	var_92_6:addTo(var_92_10)
	var_92_7:addTo(var_92_10)
	var_92_8:addTo(var_92_10)
	var_92_9:addTo(var_92_10)

	return var_92_1.y + 30
end

function var_0_4.createLabel(arg_93_0, arg_93_1, arg_93_2)
	local var_93_0 = arg_93_0.hero
	local var_93_1 = {
		size = 22,
		x = 20,
		text = xyd.tables.attr:name(arg_93_1) .. ":",
		color = cc.c3b(255, 53, 143),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		y = arg_93_2
	}
	local var_93_2 = xyd.AssetLoader.get():loadLabel(var_93_1)
	local var_93_3 = {
		size = 22,
		text = math.ceil(math.max(0, var_93_0:getTotalAttr(arg_93_1) - var_93_0:getEquipFumoAttr(arg_93_1) - var_93_0:getEquipAttr(arg_93_1) - var_93_0:getSkillAttr(arg_93_1) - var_93_0:getSkill2Attr(arg_93_1))),
		color = cc.c3b(70, 69, 69),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		font = xyd.AssetLoader.FONT_NAME,
		x = var_93_1.x + 5 + var_93_2:getContentSize().width,
		y = arg_93_2
	}
	local var_93_4 = xyd.AssetLoader.get():loadLabel(var_93_3)
	local var_93_5 = {
		size = 22,
		text = "+" .. math.ceil(var_93_0:getEquipFumoAttr(arg_93_1) + var_93_0:getEquipAttr(arg_93_1) + var_93_0:getSkillAttr(arg_93_1) + var_93_0:getSkill2Attr(arg_93_1)),
		color = cc.c3b(24, 184, 54),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		font = xyd.AssetLoader.FONT_NAME,
		x = var_93_3.x + 5 + var_93_4:getContentSize().width,
		y = arg_93_2
	}
	local var_93_6

	if var_93_0:getEquipFumoAttr(arg_93_1) + var_93_0:getEquipAttr(arg_93_1) + var_93_0:getSkillAttr(arg_93_1) + var_93_0:getSkill2Attr(arg_93_1) > 0 then
		var_93_6 = xyd.AssetLoader.get():loadLabel(var_93_5)
	end

	local var_93_7

	if xyd.tables.attr:suffix(arg_93_1) ~= "" then
		local var_93_8 = var_93_5.x

		if var_93_6 ~= nil then
			var_93_8 = var_93_8 + 5 + var_93_6:getContentSize().width
		end

		local var_93_9 = {
			size = 22,
			text = xyd.tables.attr:suffix(arg_93_1),
			color = cc.c3b(70, 69, 69),
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_TOP,
			x = var_93_8,
			y = arg_93_2
		}

		var_93_7 = xyd.AssetLoader.get():loadLabel(var_93_9)
	end

	return var_93_2, var_93_4, var_93_6, var_93_7
end

function var_0_4.playActionByButton(arg_94_0, arg_94_1, arg_94_2)
	local var_94_0 = arg_94_0.containers[arg_94_0.state]
	local var_94_1 = {}

	table.insert(var_94_1, cc.ScaleTo:create(0.2, 0))
	table.insert(var_94_1, cc.CallFunc:create(function()
		local var_95_0 = {}

		table.insert(var_95_0, cc.DelayTime:create(0.1))
		table.insert(var_95_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_95_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_95_0, cc.ScaleTo:create(0.05, 1))

		if arg_94_1 == var_0_6 then
			table.insert(var_95_0, cc.CallFunc:create(function()
				arg_94_0:skillListAction(0.01, 15, 0.2)
			end))
		end

		var_94_0:hide()
		arg_94_2:scale(0)
		arg_94_2:show()
		arg_94_2:runAction(transition.sequence(var_95_0))
	end))
	var_94_0:runAction(transition.sequence(var_94_1))

	arg_94_0.state = arg_94_1

	arg_94_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.normal)
	arg_94_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.normal)
	arg_94_0:nodeByName("button_show_detail"):setBrightStyle(ccui.BrightStyle.normal)
	arg_94_0:nodeByName("button_jingyan"):setBrightStyle(ccui.BrightStyle.normal)
end

function var_0_4.clickInfoButton(arg_97_0)
	local var_97_0 = arg_97_0.mainContainer:getContentSize().width

	if arg_97_0.state ~= var_0_5 then
		arg_97_0:playActionByButton(var_0_5, arg_97_0.infoContainer)
		arg_97_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_97_0:nodeByName("button_shuxing"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.clickSkillButton(arg_98_0)
	if arg_98_0.state ~= var_0_6 then
		if arg_98_0.skillList and not tolua.isnull(arg_98_0.skillList) then
			if arg_98_0.skillCount and arg_98_0.skillCount == 4 then
				arg_98_0.skillList:getScrollNode():setPositionY(90)
			elseif arg_98_0.skillCount and arg_98_0.skillCount == 5 then
				arg_98_0.skillList:getScrollNode():setPositionY(-33)
			end
		end

		arg_98_0:playActionByButton(var_0_6, arg_98_0.skillContainer)
		arg_98_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_98_0:nodeByName("button_jineng"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	if arg_98_0.state == var_0_6 then
		arg_98_0:updateSkillContainer()
		arg_98_0:updateAllSkillTips()
	end
end

function var_0_4.clickShowDetailButton(arg_99_0)
	if arg_99_0.state ~= var_0_7 then
		arg_99_0:playActionByButton(var_0_7, arg_99_0.equipInfoContainer)
		arg_99_0:nodeByName("button_show_detail"):setBrightStyle(ccui.BrightStyle.highlight)

		local var_99_0 = arg_99_0.equipScrollBg:getViewRect()

		arg_99_0.equipScrollBg:scrollTo(0, var_99_0.height - arg_99_0.equipScrollBg.scrollHeight)
	else
		arg_99_0:nodeByName("button_show_detail"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.clickAddExpButton(arg_100_0)
	if arg_100_0.state ~= var_0_8 then
		arg_100_0:playActionByButton(var_0_8, arg_100_0.addExpContainer)
		arg_100_0:nodeByName("button_jingyan"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_100_0:nodeByName("button_jingyan"):setBrightStyle(ccui.BrightStyle.highlight)
	end
end

function var_0_4.skillListAction(arg_101_0, arg_101_1, arg_101_2, arg_101_3)
	if arg_101_0.hero:isAwaken() then
		local var_101_0 = var_0_10.performWithDelayGlobal(function()
			if not xyd.WindowManager.get():getWindow("pet_main") then
				return
			end

			local var_102_0 = 120 / arg_101_2
			local var_102_1 = -120
			local var_102_2 = var_0_10.scheduleGlobal(function()
				var_102_1 = var_102_1 + var_102_0

				local var_103_0 = xyd.WindowManager.get():getWindow("pet_main")

				if var_103_0 and var_102_1 <= 0 then
					var_103_0.skillList:getScrollNode():setPositionY(var_102_1)
				elseif skillHandle then
					var_0_10.unscheduleGlobal(skillHandle)
				end
			end, arg_101_1)
		end, arg_101_3)
	end
end

function var_0_4.clickStoneButton(arg_104_0)
	local var_104_0 = arg_104_0.hero
	local var_104_1 = xyd.tables.hero:stoneID(var_104_0:getTableID())

	xyd.WindowManager.get():openWindow("pet_stone", {
		hero = var_104_0,
		itemComposeID = var_104_1
	})
end

function var_0_4.clickJinhuaButton(arg_105_0)
	local var_105_0 = arg_105_0.hero

	if var_105_0:getStar() >= xyd.MAX_STAR_LEVEL then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("HERO_MAIN_MAX_STAR")
		})

		return
	end

	xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
		string.format(var_0_11:translation("EVOLVE_PET_ALERT"), xyd.StarLevelSuipian[var_105_0:getStar() + 1])
	}, function(arg_106_0)
		if arg_106_0 then
			if var_105_0:getSuiPian() < xyd.StarLevelSuipian[var_105_0:getStar() + 1] then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_11:translation("PET_STONE_TOO_LESS")
				})
			else
				local var_106_0 = var_105_0:getStar()
				local var_106_1 = var_105_0:getColor()
				local var_106_2 = cc.p(arg_105_0:getHeroContainer():getPosition())
				local var_106_3 = arg_105_0:getHeroContainer():getContentSize()

				var_106_2.x = var_106_2.x + var_106_3.width * 0.5
				var_106_2.y = var_106_2.y + var_106_3.height * 0.5

				arg_105_0:playEffect(arg_105_0.mainContainer, "Evolve", var_106_2, true)

				local var_106_4 = clone(arg_105_0.hero)

				var_105_0:evolution(function(arg_107_0, arg_107_1)
					if arg_107_0 == xyd.error.OK then
						local var_107_0 = {}

						table.insert(var_107_0, var_0_9:getHeroMainAttr(var_105_0:getTableID(), 1, var_105_0:getStar(), var_105_0:getLevel()) - var_0_9:getHeroMainAttr(var_105_0:getTableID(), 1, var_105_0:getStar() - 1, var_105_0:getLevel()))
						table.insert(var_107_0, var_0_9:getHeroMainAttr(var_105_0:getTableID(), 1, var_105_0:getStar(), var_105_0:getLevel()) - var_0_9:getHeroMainAttr(var_105_0:getTableID(), 2, var_105_0:getStar() - 1, var_105_0:getLevel()))
						table.insert(var_107_0, var_0_9:getHeroMainAttr(var_105_0:getTableID(), 1, var_105_0:getStar(), var_105_0:getLevel()) - var_0_9:getHeroMainAttr(var_105_0:getTableID(), 3, var_105_0:getStar() - 1, var_105_0:getLevel()))

						local var_107_1 = arg_105_0:getHeroModel()

						arg_105_0.isShow = true

						var_107_1:win(false, handler(arg_105_0, arg_105_0.setIsShow))
						var_107_1:playAttribute(arg_105_0:getFloatAttrs(var_107_0))
						arg_105_0:updateAttrScore()
						arg_105_0:updateHeroStar()
						arg_105_0:updateAttrLabels()
						arg_105_0:updateIntroduceText()
						arg_105_0:updateScrollBg()
						arg_105_0:updateCollectWindow()
						arg_105_0:playRepeatingEffect()
						arg_105_0:updateExpInfoContainer()

						arg_105_0.heroModel_ = nil

						arg_105_0:updateHeroModel(var_105_0)
						audio.playSound(xyd.tables.sound:getSound("hero_upstar"))

						arg_105_0.refresh_ = true

						local var_107_2 = {
							type_ = xyd.LevelUpType.EVOLVE,
							hero = var_105_0,
							old_hero = var_106_4,
							vals = {
								oldStar = var_106_0,
								newStar = var_106_0 + 1,
								oldColor = var_105_0:getColor()
							}
						}

						xyd.WindowManager.get():openWindow("levelup", var_107_2)
					end
				end)
			end
		end
	end)
end

function var_0_4.updateSkillItem(arg_108_0, arg_108_1, arg_108_2)
	local var_108_0 = arg_108_0.hero

	for iter_108_0, iter_108_1 in ipairs(arg_108_0.skillItems) do
		local var_108_1 = arg_108_0.skillItems[iter_108_0]

		if var_108_0:getSkillLevel(iter_108_0) ~= 0 then
			local var_108_2 = var_108_0:getSkillLevel(iter_108_0) - xyd.SKILL_EXTRA[iter_108_0]

			var_108_1:getChildByName("lev"):setString("lv. " .. var_108_2)
			var_108_1:getChildByName("bookNum"):setString(xyd.tables.petSkillBook:getBookNum(var_108_0:getSkillLevel(iter_108_0)))

			if var_108_0:getExtraSkillLevel() > 0 then
				var_108_1:getChildByName("level_extra"):show()
				var_108_1:getChildByName("level_extra"):setString("+" .. var_108_0:getExtraSkillLevel())
			else
				var_108_1:getChildByName("level_extra"):hide()
			end

			var_108_1:getChildByName("jiesuo"):setVisible(false)
		else
			local var_108_3 = var_0_11:translation("HERO_JIESUO_" .. iter_108_0)

			var_108_1:getChildByName("jiesuo"):setString(var_108_3)
			var_108_1:getChildByName("lev"):setVisible(false)
			var_108_1:getChildByName("level_extra"):hide()
			var_108_1:getChildByName("bookNum"):setVisible(false)
			var_108_1:getChildByName("skillBook"):setVisible(false)
		end
	end

	if not arg_108_2 and arg_108_1 then
		local var_108_4 = arg_108_0.skillItems[arg_108_1]:getChildByName("jiadian")

		if var_108_0:getSkillLevel(arg_108_1) == 0 or var_108_0:getSkillLevel(arg_108_1) >= var_108_0:getLevel() then
			var_108_4:setButtonEnabled(false)
		else
			var_108_4:setButtonEnabled(true)
		end
	end
end

function var_0_4.showItemDetail(arg_109_0, arg_109_1, arg_109_2, arg_109_3)
	local var_109_0 = xyd.WindowManager.get():openWindow(xyd.WindowName.equipConfirmWnd, {
		is_pet = true,
		hero = arg_109_0.hero,
		item_index = arg_109_1,
		color = arg_109_2,
		state = arg_109_3
	})

	cc.EventProxy.new(var_109_0, var_109_0):addEventListener(xyd.event.HERO_EQUIP_CHANGED, function(arg_110_0)
		arg_109_0:playEffect(arg_109_0.mainContainer, "AddItem", cc.p(arg_109_0:getEquipContainerByIndex(arg_109_1):getPosition()), true)

		local var_110_0 = arg_109_0.hero:getEquipByIndex(arg_109_1)
		local var_110_1 = arg_109_0:getHeroModel()

		arg_109_0.isShow = true

		var_110_1:win(false, handler(arg_109_0, arg_109_0.setIsShow))
		var_110_1:playAttribute(var_110_0:getAttrFloat(arg_109_0.hero:getHeroType()))
		arg_109_0:updateEquip()
		arg_109_0:playRepeatingEffect()
		arg_109_0:updateAttrScore()
		arg_109_0:updateAttrLabels()
		arg_109_0:updateIntroduceText()
		arg_109_0:updateScrollBg()
		xyd.WindowManager.get():closeWindow(xyd.WindowName.equipConfirmWnd)
		xyd.WindowManager.get():closeWindow(xyd.WindowName.itemComposeWnd)
		arg_109_0:updateCollectWindow()
		arg_109_0:updateExpInfoContainer()
		arg_109_0:updateSkillItem(nil, false)
		arg_109_0.selfPlayer:checkEquipableAndSummon()
		audio.playSound(xyd.tables.sound:getSound("hero_equip"))
		arg_109_0:CheckOneClick()
	end)
end

function var_0_4.CheckOneClickJinjie(arg_111_0)
	local var_111_0 = arg_111_0.hero
	local var_111_1 = 0

	arg_111_0.needEquip = {}
	arg_111_0.needPotion = {}
	arg_111_0.needGold = 0

	local function var_111_2(arg_112_0)
		local var_112_0 = arg_111_0.needEquip[arg_112_0] or 0
		local var_112_1 = xyd.tables.item:compose(arg_112_0)
		local var_112_2 = xyd.tables.item:composeNum(arg_112_0)
		local var_112_3 = xyd.tables.item:composeMana(arg_112_0) or 0

		if var_112_1[1] ~= 0 then
			if arg_111_0.selfPlayer:getBackpack():getItemNumByID(arg_112_0) == var_112_0 then
				arg_111_0.needGold = arg_111_0.needGold + var_112_3

				for iter_112_0 = 1, #var_112_1 do
					for iter_112_1 = 1, var_112_2[iter_112_0] do
						var_111_2(var_112_1[iter_112_0])
					end
				end
			else
				arg_111_0.needEquip[arg_112_0] = var_112_0 + 1
			end
		else
			arg_111_0.needEquip[arg_112_0] = var_112_0 + 1
		end
	end

	for iter_111_0 = 1, 3 do
		local var_111_3 = var_111_0:getEquipByIndex(iter_111_0)

		if var_111_3:getTableID() > 0 and not var_111_3:isCollected() and xyd.tables.item:isAwakenItem(var_111_3:getTableID()) == 0 then
			break
		end

		if iter_111_0 == 3 then
			arg_111_0:setjinjieBtn(var_0_16)

			return false
		end
	end

	for iter_111_1 = 1, 3 do
		local var_111_4 = var_111_0:getEquipByIndex(iter_111_1)

		if var_111_4:getTableID() > 0 and xyd.tables.item:isAwakenItem(var_111_4:getTableID()) == 0 and not var_111_4:isCollected() then
			if arg_111_0.maxLev < var_111_4:getLevel() then
				arg_111_0:setjinjieBtn(var_0_16)

				return false
			end

			if var_111_0:getLevel() < var_111_4:getLevel() and var_111_1 < var_111_4:getLevel() then
				var_111_1 = var_111_4:getLevel()
			end

			var_111_2(var_111_4:getTableID())
		end
	end

	if arg_111_0.needGold > arg_111_0.selfPlayer.mana then
		arg_111_0:setjinjieBtn(var_0_16)

		return false
	end

	for iter_111_2, iter_111_3 in pairs(arg_111_0.needEquip) do
		if iter_111_3 > arg_111_0.selfPlayer:getBackpack():getItemNumByID(iter_111_2) then
			arg_111_0:setjinjieBtn(var_0_16)

			return false
		end
	end

	if var_111_1 ~= 0 then
		local var_111_5 = 0
		local var_111_6 = var_111_0:getLevel()
		local var_111_7 = var_111_0:getExp() - xyd.tables.partnerExp:totalExp(var_111_0:getLevel() - 1)
		local var_111_8 = {
			50001087,
			50001088,
			50001089
		}

		for iter_111_4 = var_111_6, var_111_1 - 1 do
			var_111_5 = var_111_5 + xyd.tables.partnerExp:exp(iter_111_4)
		end

		local var_111_9 = var_111_5 - var_111_7

		for iter_111_5, iter_111_6 in pairs(var_111_8) do
			local var_111_10 = arg_111_0.selfPlayer:getBackpack():getItemNumByID(iter_111_6)
			local var_111_11 = xyd.tables.item:exp(iter_111_6)

			if var_111_9 <= var_111_10 * var_111_11 then
				local var_111_12 = math.ceil(var_111_9 / var_111_11)

				arg_111_0.needPotion[iter_111_6] = var_111_12
				var_111_9 = 0

				break
			elseif var_111_10 ~= 0 then
				var_111_9 = var_111_9 - var_111_10 * var_111_11
				arg_111_0.needPotion[iter_111_6] = var_111_10
			end
		end

		if var_111_9 ~= 0 then
			arg_111_0:setjinjieBtn(var_0_16)

			return false
		end
	end

	if var_111_0:getColor() >= xyd.tables.misc.maxPetColor then
		arg_111_0:setjinjieBtn(var_0_16)
	else
		arg_111_0:setjinjieBtn(var_0_14)
	end

	return true
end

function var_0_4.CheckOneClick(arg_113_0)
	if arg_113_0:CheckOneClickJinjie() == false then
		-- block empty
	end
end

function var_0_4.clickYijianButton(arg_114_0)
	local function var_114_0()
		local var_115_0 = arg_114_0.hero
		local var_115_1 = var_115_0:getColor()
		local var_115_2 = var_115_0:getStar()
		local var_115_3 = var_115_0:getMaxHP()
		local var_115_4 = var_115_0:getZhandouli()
		local var_115_5 = cc.p(arg_114_0:getHeroContainer():getPosition())
		local var_115_6 = arg_114_0:getHeroContainer():getContentSize()

		var_115_5.x = var_115_5.x + var_115_6.width * 0.5
		var_115_5.y = var_115_5.y + var_115_6.height * 0.5

		var_115_0:oneKeyPowerUp(function(arg_116_0, arg_116_1)
			if arg_116_0 == xyd.error.OK then
				local var_116_0 = arg_114_0:getHeroModel()

				arg_114_0:playEffect(arg_114_0.mainContainer, "Upgrade", var_115_5, true)

				for iter_116_0 = 1, var_0_1 do
					if var_115_0:getEquipByIndex(iter_116_0):getTableID() ~= 0 and xyd.tables.item:isAwakenItem(var_115_0:getEquipByIndex(iter_116_0):getTableID()) == 0 then
						local var_116_1 = arg_114_0:getEquipContainerByIndex(iter_116_0)
						local var_116_2 = display.newNode()

						var_116_2:size(var_116_1:getWidth(), var_116_1:getHeight())

						item = var_115_0:getEquipByIndex(iter_116_0, var_115_0:getColor() - 1)

						xyd.setSpecialItemBorder(var_116_2, item:getTableID())
						var_116_2:addTo(arg_114_0.mainContainer, 101)
						var_116_2:pos(var_116_1:getPosition())

						local var_116_3, var_116_4 = arg_114_0:getHeroContainer():getPosition()
						local var_116_5 = var_116_3 + arg_114_0:getHeroContainer():getWidth() / 2
						local var_116_6 = var_116_0.chestPoint.x + var_116_5
						local var_116_7 = var_116_4 + var_116_0.chestPoint.y
						local var_116_8 = cc.Spawn:create(cc.ScaleTo:create(0.8, 0.1), cc.MoveTo:create(0.8, cc.p(var_116_6, var_116_7)))

						var_116_2:runActionOnce(var_116_8, true)
					end
				end

				for iter_116_1, iter_116_2 in pairs(arg_114_0.needEquip) do
					local var_116_9 = {
						itemID = iter_116_1,
						itemNum = iter_116_2
					}

					arg_114_0.selfPlayer:getBackpack():removeItem(var_116_9)
				end

				for iter_116_3, iter_116_4 in pairs(arg_114_0.needPotion) do
					local var_116_10 = {
						itemID = iter_116_3,
						itemNum = iter_116_4
					}

					arg_114_0.selfPlayer:getBackpack():removeItem(var_116_10)

					local var_116_11 = iter_116_4 * xyd.tables.item:exp(iter_116_3)

					var_115_0:addExp(var_116_11, xyd.tables.player:heroMaxLev(arg_114_0.selfPlayer.lev))
					arg_114_0:updateExp()
				end

				arg_114_0.selfPlayer.mana = arg_114_0.selfPlayer.mana - arg_114_0.needGold

				local var_116_12 = {}

				table.insert(var_116_12, xyd.JINJIE_ATTR_RATE * (var_115_0:getColor() - 1))
				table.insert(var_116_12, xyd.JINJIE_ATTR_RATE * (var_115_0:getColor() - 1))
				table.insert(var_116_12, xyd.JINJIE_ATTR_RATE * (var_115_0:getColor() - 1))

				arg_114_0.isShow = true

				var_116_0:win(false, handler(arg_114_0, arg_114_0.setIsShow))
				var_116_0:playAttribute(arg_114_0:getFloatAttrs(var_116_12))
				arg_114_0:updateEquip()
				arg_114_0:updateAttrScore()
				arg_114_0:updateAttrLabels()
				arg_114_0:updateIntroduceText()
				arg_114_0:updateScrollBg()
				arg_114_0:updateCollectWindow()
				arg_114_0:updateNameLabel()
				arg_114_0:updateEquipInfoContainer()
				arg_114_0:setSkillContainer()
				arg_114_0:playRepeatingEffect()
				arg_114_0:CheckOneClick()
				arg_114_0:updateExpInfoContainer()
				audio.playSound(xyd.tables.sound:getSound("hero_upgrade"))

				arg_114_0.refresh_ = true

				local var_116_13 = var_115_0:getMaxHP()
				local var_116_14 = var_115_0:getZhandouli()
				local var_116_15 = {
					type_ = xyd.LevelUpType.ADVANCE,
					hero = var_115_0,
					vals = {
						oldStar = var_115_2,
						oldColor = var_115_1,
						newColor = var_115_1 + 1,
						oldHP = var_115_3,
						newHP = var_116_13,
						oldForce = var_115_4,
						newForce = var_116_14
					}
				}

				if arg_116_1.restore_items and #arg_116_1.restore_items > 0 then
					function var_116_15.callback()
						xyd.WindowManager.get():openWindow("alert_award", {
							awards = arg_116_1.restore_items,
							name = var_0_11:translation("FUMO_RESTORE_NAME")
						})
					end

					for iter_116_5 = 1, #arg_116_1.restore_items do
						local var_116_16 = {
							itemID = arg_116_1.restore_items[iter_116_5].table_id,
							itemNum = arg_116_1.restore_items[iter_116_5].item_num
						}

						arg_114_0.selfPlayer:getBackpack():addItem(var_116_16)
					end
				end

				arg_114_0:runActionOnce(cc.CallFunc:create(function()
					xyd.WindowManager.get():openWindow("levelup", var_116_15)
				end), nil, nil, 1)
			end
		end)
	end

	local var_114_1 = 1
	local var_114_2 = {}

	for iter_114_0, iter_114_1 in pairs(arg_114_0.needEquip) do
		var_114_2[var_114_1] = {
			table_id = iter_114_0,
			item_num = iter_114_1
		}
		var_114_1 = var_114_1 + 1
	end

	for iter_114_2, iter_114_3 in pairs(arg_114_0.needPotion) do
		var_114_2[var_114_1] = {
			table_id = iter_114_2,
			item_num = iter_114_3
		}
		var_114_1 = var_114_1 + 1
	end

	if arg_114_0.needGold ~= 0 then
		var_114_2[var_114_1] = {
			table_id = 0,
			item_num = arg_114_0.needGold
		}
	end

	params = {
		isPet = true,
		items = var_114_2,
		heroName = arg_114_0.hero:getName()
	}

	xyd.AdvancedTipWindow.open(params, function(arg_119_0)
		if arg_119_0 then
			var_114_0()
		end
	end)
end

function var_0_4.setjinjieBtn(arg_120_0, arg_120_1)
	if arg_120_1 == var_0_14 then
		arg_120_0:nodeByName("button_jinjie"):setVisible(false)
		arg_120_0:nodeByName("button_yijian"):setVisible(true)
	elseif arg_120_1 == var_0_15 then
		arg_120_0:nodeByName("button_jinjie"):setVisible(false)
		arg_120_0:nodeByName("button_yijian"):setVisible(true)
	else
		arg_120_0:nodeByName("button_jinjie"):setVisible(true)
		arg_120_0:nodeByName("button_yijian"):setVisible(false)
	end
end

function var_0_4.buttonHandler(arg_121_0, arg_121_1, arg_121_2, arg_121_3)
	if arg_121_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_121_2)
		arg_121_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound(xyd.tables.sound:getSound("ui_button_click"), false)

		if arg_121_1 then
			arg_121_1(arg_121_2, arg_121_3)
		end
	elseif arg_121_3 == ccui.TouchEventType.began then
		local var_121_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_121_1 = cc.RepeatForever:create(var_121_0)

		arg_121_2:runAction(var_121_1)

		return true
	elseif arg_121_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_121_2)
		arg_121_2:setScale(1)
	end
end

function var_0_4.willClose(arg_122_0)
	if arg_122_0.eatHandler[var_0_17] ~= nil then
		var_0_10.unscheduleGlobal(arg_122_0.eatHandler[var_0_17])
	end

	if arg_122_0.eatHandler[var_0_18] ~= nil then
		var_0_10.unscheduleGlobal(arg_122_0.eatHandler[var_0_18])
	end

	if arg_122_0.skillTextHandle then
		var_0_10.unscheduleGlobal(arg_122_0.skillTextHandle)
	end

	if arg_122_0.skillClickHandle then
		var_0_10.unscheduleGlobal(arg_122_0.skillClickHandle)
	end
end

function var_0_4.getHeroContainer(arg_123_0)
	if not arg_123_0.heroContainer_ then
		arg_123_0.heroContainer_ = arg_123_0:nodeByName("hero_container")

		arg_123_0.heroContainer_:setLocalZOrder(100)
	end

	return arg_123_0.heroContainer_
end

function var_0_4.updateEquip(arg_124_0, arg_124_1)
	arg_124_1 = arg_124_1 or arg_124_0.hero

	if arg_124_0.equipContainerlist_ then
		for iter_124_0, iter_124_1 in ipairs(arg_124_0.equipContainerlist_) do
			iter_124_1:removeAllNodeEventListeners()
			iter_124_1:removeSelf()
		end

		arg_124_0.equipContainerlist_ = nil
	end

	for iter_124_2 = 1, var_0_1 do
		local var_124_0 = arg_124_0:getEquipContainerByIndex(iter_124_2)
		local var_124_1 = arg_124_1:getEquipByIndex(iter_124_2)

		var_124_0:setTouchEnabled(true)
		var_124_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_125_0)
			if arg_125_0.name == "ended" and var_124_1:getTableID() > 0 then
				-- block empty
			end

			return true
		end)
	end
end

function var_0_4.getEquipContainerByIndex(arg_126_0, arg_126_1)
	local var_126_0 = arg_126_0.hero

	if not arg_126_0.equipContainerlist_ then
		arg_126_0.equipContainerlist_ = {}

		for iter_126_0 = 1, var_0_1 do
			local var_126_1 = arg_126_0:nodeByName("pos_node" .. iter_126_0)
			local var_126_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/equip.csb")

			var_126_2:setContentSize(var_126_2:getChildByName("background"):getContentSize())

			local var_126_3 = var_126_2:getContentSize()
			local var_126_4 = var_126_2:getChildByName("green_plus")
			local var_126_5 = var_126_2:getChildByName("white_plus")
			local var_126_6 = var_126_2:getChildByName("green_label")
			local var_126_7 = var_126_2:getChildByName("gray_label")

			var_126_4:setVisible(false)
			var_126_5:setVisible(false)
			var_126_7:setVisible(false)
			var_126_6:setVisible(false)
			var_126_2:setName("equip_container" .. iter_126_0)
			var_126_2:setAnchorPoint(cc.p(0.5, 0.5))
			var_126_2:setPosition(var_126_1:getPosition())
			var_126_2:addTo(arg_126_0.mainContainer, var_126_1:getLocalZOrder())
			table.insert(arg_126_0.equipContainerlist_, var_126_2)

			local var_126_8 = var_126_0:getEquipByIndex(iter_126_0)

			if not var_126_8:isCollected() and (var_126_8:getTableID() == 0 or xyd.tables.item:isAwakenItem(var_126_8:getTableID()) == 1) and not var_126_0:isAwaken() and not arg_126_0.task:isAwaking(var_126_0:getTableID(), xyd.AwakeType.PET) then
				var_126_2:getChildByName("awake_equip_hide"):setVisible(true)
			else
				var_126_2:getChildByName("awake_equip_hide"):setVisible(false)

				local var_126_9 = var_126_8:getFumoLev()
				local var_126_10 = var_126_2:getChildByName("icon")

				xyd.setSpecialItemBorder(var_126_10, var_126_8:getTableID(), not var_126_8:isCollected())

				if var_126_9 < 1 then
					var_126_2:getChildByName("star_bg"):setVisible(false)
				end

				for iter_126_1 = xyd.MAX_STAR_LEVEL, var_126_9 + 1, -1 do
					var_126_2:getChildByName("blue_star" .. iter_126_1):setVisible(false)
				end
			end
		end
	end

	return arg_126_0.equipContainerlist_[arg_126_1]
end

function var_0_4.getSpineEffect(arg_127_0, arg_127_1)
	local var_127_0 = var_0_13[arg_127_1] .. ".json"
	local var_127_1 = var_0_13[arg_127_1] .. ".atlas"

	return (var_0_12.new(var_127_0, var_127_1, 1))
end

function var_0_4.updateCollectWindow(arg_128_0)
	local var_128_0 = xyd.WindowManager.get():getWindow("pet_collect")

	if var_128_0 then
		var_128_0:refreshSelectedHeroClass()
	end
end

function var_0_4.getFloatAttrs(arg_129_0, arg_129_1)
	local var_129_0 = clone(arg_129_1)

	if arg_129_1[1] and arg_129_1[1] > 0 then
		var_129_0[xyd.AttributeType.HP] = math.ceil((var_129_0[xyd.AttributeType.HP] or 0) + arg_129_1[1] * xyd.STRENGTH_HP_RATE)
		var_129_0[xyd.AttributeType.HUJIA] = math.ceil((var_129_0[xyd.AttributeType.HUJIA] or 0) + arg_129_1[1] * xyd.STRENGTH_HUJIA_RATE)
	end

	if arg_129_1[2] and arg_129_1[2] > 0 then
		var_129_0[xyd.AttributeType.AP] = math.ceil((var_129_0[xyd.AttributeType.AP] or 0) + arg_129_1[2] * xyd.WISE_AP_RATE)
		var_129_0[xyd.AttributeType.MOKANG] = math.ceil((var_129_0[xyd.AttributeType.MOKANG] or 0) + arg_129_1[2] * xyd.WISE_MOKANG_RATE)
	end

	if arg_129_1[3] and arg_129_1[3] > 0 then
		var_129_0[xyd.AttributeType.AD] = math.ceil((var_129_0[xyd.AttributeType.AD] or 0) + arg_129_1[3] * xyd.AGILE_AD_RATE)
		var_129_0[xyd.AttributeType.HUJIA] = math.ceil((var_129_0[xyd.AttributeType.HUJIA] or 0) + arg_129_1[3] * xyd.AGILE_HUJIA_RATE)
		var_129_0[xyd.AttributeType.AD_BAOJI] = math.ceil((var_129_0[xyd.AttributeType.AD_BAOJI] or 0) + arg_129_1[3] * xyd.AGILE_AD_BAOJI_RATE)
	end

	if arg_129_1[arg_129_0.hero:getHeroType()] then
		var_129_0[xyd.AttributeType.AD] = (var_129_0[xyd.AttributeType.AD] or 0) + arg_129_1[arg_129_0.hero:getHeroType()]
	end

	return var_129_0
end

function var_0_4.playGuide(arg_130_0, arg_130_1)
	local var_130_0
	local var_130_1 = 0
	local var_130_2 = 0

	if arg_130_1 == var_0_3 then
		var_130_0 = arg_130_0.useButton
		var_130_2 = 40
		var_130_1 = 100
	elseif arg_130_1 == var_0_2 then
		var_130_0 = arg_130_0:nodeByName("button_jingyan")
	end

	local var_130_3 = var_130_0:getPositionX()
	local var_130_4 = var_130_0:getPositionY()

	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_130_5 = xyd.WindowManager.get():openWindow("guide")
	local var_130_6 = arg_130_0:convertToNodeSpace(var_130_0:getParent():convertToWorldSpace(cc.p(var_130_3, var_130_4)))

	var_130_5:addNode()
	var_130_5:setStencil(var_130_0:getContentSize().width + var_130_1, var_130_0:getContentSize().height + var_130_2, var_130_6.x, var_130_6.y, 2)
end

return var_0_4
