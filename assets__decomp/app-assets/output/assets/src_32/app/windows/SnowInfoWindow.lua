local var_0_0 = class("SnowInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.skill
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.attr
local var_0_5 = xyd.tables.translation
local var_0_6 = xyd.tables.activitySnowEffect
local var_0_7 = xyd.tables.activityPartnerSkill
local var_0_8 = import("app.common.ui.SpineEffect")
local var_0_9 = {}

var_0_9.Evolve = "skeletons/ui_effect/common_effect_hero4/common_effect_hero4"
var_0_9.LevelUp = "skeletons/ui_effect/common_effect_exp_lv_up/common_effect_exp_lv_up"

local var_0_10 = {
	ATTR = 2,
	SKILL = 1
}
local var_0_11 = 130

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.activity = arg_1_0.snowActivity:getActivity()
	arg_1_0.leftStatus = var_0_10.SKILL
	arg_1_0.hero_ = nil
	arg_1_0.lastLevel = 0
	arg_1_0.levelUpCount_ = 0
	arg_1_0.attrListInit_ = false
	arg_1_0.skillListInit_ = false
	arg_1_0.rightBtnIsShow = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:initHero()
	arg_3_0:initListView()
	arg_3_0:setupButton()
	arg_3_0:updateNameLabel()
	arg_3_0:updateBottom()
	arg_3_0:updateHeroModel()
	arg_3_0:initRight()
	arg_3_0:nodeByName("text_name"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
end

function var_0_0.initHero(arg_4_0)
	arg_4_0.hero_ = arg_4_0.snowActivity:getHero()
	arg_4_0.lastLevel = arg_4_0.hero_:getLevel()
end

function var_0_0.initListView(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("skill_list")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.skillList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	local var_5_2 = arg_5_0:nodeByName("attr_list")
	local var_5_3 = var_5_0:getContentSize()

	arg_5_0.attrList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_5_3.width, var_5_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_2):onScroll(handler(arg_5_0, arg_5_0.scrollListener))
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 10 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.setupButton(arg_7_0)
	local function var_7_0()
		if arg_7_0.leftStatus == var_0_10.SKILL then
			arg_7_0:nodeByName("btn_attr"):setBrightStyle(ccui.BrightStyle.normal)
			arg_7_0:nodeByName("btn_skill"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_7_0:nodeByName("btn_attr"):setTouchEnabled(true)
			arg_7_0:nodeByName("btn_skill"):setTouchEnabled(false)
		else
			arg_7_0:nodeByName("btn_attr"):setBrightStyle(ccui.BrightStyle.highlight)
			arg_7_0:nodeByName("btn_skill"):setBrightStyle(ccui.BrightStyle.normal)
			arg_7_0:nodeByName("btn_attr"):setTouchEnabled(false)
			arg_7_0:nodeByName("btn_skill"):setTouchEnabled(true)
		end
	end

	arg_7_0:nodeByName("btn_attr"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended and arg_7_0.leftStatus ~= var_0_10.ATTR then
			arg_7_0:createAttrLayout()
			arg_7_0:showLeftAction(var_0_10.ATTR)
			var_7_0()
		end
	end)
	arg_7_0:nodeByName("btn_skill"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and arg_7_0.leftStatus ~= var_0_10.SKILL then
			arg_7_0:showLeftAction(var_0_10.SKILL)
			var_7_0()
		end
	end)
	arg_7_0:nodeByName("btn_lev_up"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				hero = arg_7_0.hero_
			}

			xyd.WindowManager.get():openWindow("snow_lev_up", var_11_0)
		end
	end)
	var_7_0()
	arg_7_0:nodeByName("attr_list"):hide()
	arg_7_0:createSkillLayout()
end

function var_0_0.createSkillLayout(arg_12_0)
	if arg_12_0.skillListInit_ then
		return
	end

	arg_12_0.skillList_:removeAllItems()

	for iter_12_0 = 1, 4 do
		local var_12_0 = var_0_3:getSkillTable(arg_12_0.hero_:getTableID(), iter_12_0)

		for iter_12_1 = 1, #var_12_0 do
			local var_12_1 = arg_12_0.skillList_:newItem()
			local var_12_2 = var_12_0[iter_12_1]
			local var_12_3 = arg_12_0:createSkillItem(iter_12_0, var_12_2)
			local var_12_4 = var_12_3:getWidth()
			local var_12_5 = var_12_3:getHeight()

			var_12_1:setItemSize(var_12_4, var_12_5)
			var_12_1:addContent(var_12_3)
			arg_12_0.skillList_:addItem(var_12_1)
		end
	end

	arg_12_0.skillList_:reload()

	arg_12_0.skillListInit_ = true
end

function var_0_0.createSkillItem(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_info/skill_item.csb")
	local var_13_1 = var_13_0:getChildByName("background"):getContentSize()

	var_13_0:setContentSize(var_13_1.width, var_13_1.height + 10)
	var_13_0:getChildByName("name"):setString(var_0_2:name(arg_13_2))
	xyd.setSkillBorder(var_13_0:getChildByName("icon"), arg_13_2)
	var_13_0:getChildByName("lev"):setString(string.format(var_0_5:translation("TEXT_LEVEL"), arg_13_0.hero_:getLevel()))

	local var_13_2 = true

	if arg_13_1 > xyd.Color2Quality[arg_13_0.hero_:getColor()] then
		var_13_0:getChildByName("jiesuo"):setString(var_0_5:translation("HERO_JIESUO_" .. arg_13_1))
		var_13_0:getChildByName("lev"):setVisible(false)

		var_13_2 = false
	end

	arg_13_0:createSkillTip(var_13_0, arg_13_2, var_13_2)

	return var_13_0
end

function var_0_0.createSkillTip(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	if tolua.isnull(arg_14_1) then
		return
	end

	local var_14_0, var_14_1 = arg_14_1:getPosition()

	if arg_14_1:getChildByName("skill_tip") and not tolua.isnull(arg_14_1:getChildByName("skill_tip")) then
		arg_14_1:removeChildByName("skill_tip")
	end

	local var_14_2 = display.newNode()

	if var_0_2:getItemID(arg_14_2) == 0 then
		var_14_2:setPosition(arg_14_1:getChildByName("icon"):getPosition())
	end

	var_14_2:setAnchorPoint(cc.p(0, 0))
	var_14_2:setContentSize(arg_14_1:getChildByName("icon"):getContentSize())
	var_14_2:setTouchEnabled(true)
	var_14_2:addTo(arg_14_1)
	var_14_2:setName("skill_tip")

	local var_14_3 = arg_14_0:convertToWorldSpace(cc.p(0, 0))

	var_14_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
		if arg_15_0.name == "began" then
			return true
		elseif arg_15_0.name == "ended" then
			arg_14_0:closeTipWindow()

			local var_15_0 = {
				isActivitySkill = true,
				id = arg_14_2,
				skillLev = arg_14_3 and arg_14_0.hero_:getLevel() or 0,
				extraSkillLevel = arg_14_0.hero_:getExtraSkillLevel(),
				partnerID = arg_14_0.hero_:getHeroID(),
				hero = arg_14_0.hero_,
				activitySkillDesc = arg_14_0:getSkillUnlockDesc(arg_14_2)
			}

			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_15_1 = xyd.WindowManager.get():openWindow("skill_tips", var_15_0)
				local var_15_2 = var_14_2:convertToWorldSpace(cc.p(0, 0))

				if var_0_2:getItemID(arg_14_2) == 0 then
					var_15_1:setPosition(var_15_2.x + arg_14_1:getContentSize().width + 7 - var_14_3.x, var_15_2.y - arg_14_1:getContentSize().height + 20 - var_14_3.y)
				end
			end
		end
	end)
end

function var_0_0.getSkillUnlockDesc(arg_16_0, arg_16_1)
	local var_16_0 = var_0_5:translation("SNOW_ACTIVITY_UNlOCK_DESC")
	local var_16_1 = var_0_7:type(arg_16_1)
	local var_16_2 = var_0_7:from(arg_16_1)
	local var_16_3 = var_0_7:distanceType(arg_16_1)
	local var_16_4 = var_0_7:partnerReq(arg_16_1)

	if var_16_4 <= 0 then
		return ""
	end

	local var_16_5 = ""

	if var_16_1 > 0 then
		var_16_5 = var_0_5:translation("HERO_FILTER_DES_2") .. var_0_5:translation("HERO_FILTER_TYPE_" .. var_16_1)
	elseif var_16_2 > 0 then
		var_16_5 = var_0_5:translation("HERO_FILTER_DES_3") .. var_0_5:translation("HERO_FILTER_POWER_" .. var_16_2)
	elseif var_16_3 > 0 then
		var_16_5 = var_0_5:translation("HERO_FILTER_DES_1") .. var_0_5:translation("HERO_FILTER_POS_" .. var_16_3 - 1)
	end

	return (string.format(var_16_0, var_16_5, var_16_4))
end

function var_0_0.closeTipWindow(arg_17_0)
	if xyd.WindowManager.get():getWindow("skill_tips") then
		xyd.WindowManager.get():closeWindow("skill_tips")
	end
end

function var_0_0.showLeftAction(arg_18_0, arg_18_1)
	arg_18_0.leftStatus = arg_18_1

	local var_18_0 = arg_18_0:nodeByName("left")
	local var_18_1 = {}

	table.insert(var_18_1, cc.ScaleTo:create(0.2, 0))
	table.insert(var_18_1, cc.CallFunc:create(function()
		local var_19_0 = {}

		table.insert(var_19_0, cc.DelayTime:create(0.1))
		table.insert(var_19_0, cc.ScaleTo:create(0.1, 1.2))
		table.insert(var_19_0, cc.ScaleTo:create(0.05, 0.95))
		table.insert(var_19_0, cc.ScaleTo:create(0.05, 1))

		if arg_18_0.leftStatus == var_0_10.SKILL then
			arg_18_0:nodeByName("skill_list"):show()
			arg_18_0:nodeByName("attr_list"):hide()
		else
			arg_18_0:nodeByName("skill_list"):hide()
			arg_18_0:nodeByName("attr_list"):show()
		end

		var_18_0:scale(0)
		var_18_0:show()
		var_18_0:runAction(transition.sequence(var_19_0))
	end))
	var_18_0:runAction(transition.sequence(var_18_1))
end

function var_0_0.updateNameLabel(arg_20_0)
	local var_20_0 = arg_20_0.hero_
	local var_20_1 = arg_20_0:nodeByName("container")
	local var_20_2 = arg_20_0:nodeByName("text_name")

	var_20_2:setString(var_20_0:getName())

	if arg_20_0.nameBg then
		var_20_1:removeChild(arg_20_0.nameBg)
	end

	if arg_20_0.colorText then
		var_20_1:removeChild(arg_20_0.colorText)
	end

	local var_20_3 = 705.96
	local var_20_4 = 338.91

	if xyd.Color2Level[var_20_0:getColor()] ~= "" then
		local var_20_5 = {
			size = 28,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_20_3 + var_20_2:getWidth() / 2 - 12,
			y = var_20_2:getY(),
			color = xyd.color.HERO_QUALITY[var_20_0:getColor()],
			text = xyd.Color2Level[var_20_0:getColor()]
		}

		arg_20_0.colorText = xyd.AssetLoader.get():loadLabel(var_20_5)

		arg_20_0.colorText:addTo(var_20_1)
		arg_20_0.colorText:align(display.CENTER_LEFT)
		arg_20_0.colorText:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_20_2:x(var_20_3 - 13)
	else
		var_20_2:x(var_20_3)
	end

	arg_20_0.nameBg = xyd.AssetLoader.get():loadSprite("windows/common/name_label" .. var_20_0:getColor() .. ".png")

	arg_20_0.nameBg:addTo(var_20_1)
	arg_20_0.nameBg:pos(var_20_3, var_20_4)
	var_20_2:setLocalZOrder(1)
end

function var_0_0.updateBottom(arg_21_0)
	local var_21_0 = arg_21_0:nodeByName("bottom")

	var_21_0:getChildByName("text_lev"):setString(var_0_5:translation("HERO_DENGJI"))
	var_21_0:getChildByName("text_force"):setString(var_0_5:translation("HERO_INFO_ZHANDOULI"))
	var_21_0:getChildByName("text_exp"):setString(var_0_5:translation("HERO_INFO_JINGYAN"))
	var_21_0:getChildByName("bar_text"):setString(var_0_5:translation("HERO_MAIN_MAX_STAR"))
	arg_21_0:updateForce()
	arg_21_0:updateExp()
end

function var_0_0.updateForce(arg_22_0)
	arg_22_0:nodeByName("text_force_num"):setString(arg_22_0.hero_:getZhandouli())
end

function var_0_0.updateExp(arg_23_0)
	arg_23_0:nodeByName("text_lev_num"):setString(arg_23_0.hero_:getLevel())

	local var_23_0 = arg_23_0.hero_:getExp() - xyd.tables.partnerExp:totalExp(arg_23_0.hero_:getLevel() - 1)

	arg_23_0:nodeByName("text_exp_num"):setString(var_23_0 .. " / " .. arg_23_0.hero_:getAddExp())
end

function var_0_0.setIsShow(arg_24_0)
	arg_24_0.isShow = false

	arg_24_0:getHeroModel():idle()
end

function var_0_0.resetModelState(arg_25_0)
	local var_25_0 = arg_25_0:getHeroModel()

	if arg_25_0.modelState == 8 then
		arg_25_0.modelState = arg_25_0.modelState + 1
	end

	arg_25_0.modelState = arg_25_0.modelState % 8
	arg_25_0.isShow = true

	local var_25_1

	if arg_25_0.modelState == xyd.ModelState.Walk then
		var_25_0:walk(true)

		arg_25_0.isShow = false
		var_25_1 = xyd.tables.model:getMoveSound(arg_25_0.hero_:getModelID())
	elseif arg_25_0.modelState == xyd.ModelState.Win then
		var_25_0:win(false, handler(arg_25_0, arg_25_0.setIsShow))

		var_25_1 = xyd.tables.model:getWinSound(arg_25_0.hero_:getModelID())
	elseif arg_25_0.modelState == xyd.ModelState.Attack1 then
		var_25_0:attack(1, nil, nil, handler(arg_25_0, arg_25_0.setIsShow))

		var_25_1 = xyd.tables.model:getNormalAttackSound(arg_25_0.hero_:getModelID())
	elseif arg_25_0.modelState == xyd.ModelState.Attack2 then
		var_25_0:attack(2, nil, nil, handler(arg_25_0, arg_25_0.setIsShow))

		var_25_1 = xyd.tables.model:getAttack1Sound(arg_25_0.hero_:getModelID())
	elseif arg_25_0.modelState == xyd.ModelState.Attack3 then
		var_25_0:attack(3, nil, nil, handler(arg_25_0, arg_25_0.setIsShow))

		var_25_1 = xyd.tables.model:getAttack2Sound(arg_25_0.hero_:getModelID())
	elseif arg_25_0.modelState == xyd.ModelState.Attack4 then
		if not var_25_0:hasAnimation("gongji04") then
			arg_25_0.modelState = arg_25_0.modelState + 1

			arg_25_0:resetModelState()

			return
		end

		var_25_0:attack(4, nil, nil, handler(arg_25_0, arg_25_0.setIsShow))

		var_25_1 = xyd.tables.model:getAttack4Sound(arg_25_0.hero_:getModelID())
	elseif arg_25_0.modelState == xyd.ModelState.Attack5 then
		if not var_25_0:hasAnimation("gongji05") then
			arg_25_0.modelState = arg_25_0.modelState + 1

			arg_25_0:resetModelState()

			return
		end

		var_25_0:attack(5, nil, nil, handler(arg_25_0, arg_25_0.setIsShow))

		var_25_1 = xyd.tables.model:getAttack4Sound(arg_25_0.hero_:getModelID())
	else
		arg_25_0:setIsShow()
	end

	if var_25_1 and var_25_1 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_25_1, false)
	end

	arg_25_0.modelState = arg_25_0.modelState + 1
end

function var_0_0.getHeroModel(arg_26_0)
	if arg_26_0.heroModel_ then
		return arg_26_0.heroModel_
	end

	local var_26_0 = arg_26_0.hero_:getModelID()
	local var_26_1 = xyd.HeroAnimation.new(arg_26_0.hero_:getTableID(), var_26_0, xyd.tables.model:uiScale(var_26_0), {})

	if var_26_1 then
		var_26_1:idle()
	end

	arg_26_0.heroModel_ = var_26_1

	do return arg_26_0.heroModel_ end

	if false then
		arg_26_0.heroModel_ = arg_26_0.hero_:getHeroModel()
	end

	return arg_26_0.heroModel_
end

function var_0_0.updateHeroModel(arg_27_0, arg_27_1)
	local var_27_0 = arg_27_0:getHeroModel()

	var_27_0:setTouchSwallowEnabled(false)

	arg_27_0.modelState = xyd.ModelState.Walk

	local var_27_1 = arg_27_0:getHeroContainer():getContentSize().width / 2

	var_27_0:setPosition(cc.p(var_27_1, 0))
	arg_27_0:getHeroContainer():removeAllChildren()
	var_27_0:addTo(arg_27_0:getHeroContainer())
	var_27_0:setTouchEnabled(true)

	arg_27_0.isShow = false

	arg_27_0:getHeroContainer():addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.ended and not arg_27_0.isShow then
			arg_27_0:resetModelState()
		end
	end)
end

function var_0_0.updateHeroEffect(arg_29_0)
	local var_29_0 = arg_29_0.snowActivity:getBaseInfo().effect_id

	if arg_29_0.heroEffect_ and not tolua.isnull(arg_29_0.heroEffect_) then
		arg_29_0.heroEffect_:removeSelf()
	end

	arg_29_0.heroEffect_ = arg_29_0.snowActivity:updateHeroEffect(var_29_0, arg_29_0:getHeroContainer())
end

function var_0_0.createAttrLayout(arg_30_0)
	if arg_30_0.attrListInit_ then
		return
	end

	arg_30_0.attrList_:removeAllItems()

	for iter_30_0 = 1, 4 do
		local var_30_0 = arg_30_0.attrList_:newItem()
		local var_30_1

		if iter_30_0 == 1 then
			var_30_1 = arg_30_0:createAttrTitle()
		elseif iter_30_0 == 2 then
			var_30_1 = arg_30_0:createGrowItem()
			arg_30_0.growItems = var_30_1
		elseif iter_30_0 == 3 then
			var_30_1 = arg_30_0:createAttrTitle2()
		elseif iter_30_0 == 4 then
			var_30_1 = arg_30_0:createTotalAttr()
		end

		local var_30_2 = var_30_1:getContentSize()

		var_30_0:setItemSize(var_30_2.width, var_30_2.height)
		var_30_0:addContent(var_30_1)
		arg_30_0.attrList_:addItem(var_30_0)
	end

	arg_30_0.attrList_:reload()

	arg_30_0.attrListInit_ = true
end

function var_0_0.createAttrTitle(arg_31_0)
	local var_31_0 = display.newNode()
	local var_31_1 = display.newNode()
	local var_31_2 = arg_31_0.backpack:getItemNumByID(var_0_3:attrItem(arg_31_0.hero_:getTableID()))
	local var_31_3 = var_0_5:translation("SNOW_ACTIVITY_FROST_NUM")
	local var_31_4 = arg_31_0:createTextLabel(var_31_3, nil, cc.ui.TEXT_ALIGN_LEFT, 24, cc.c3b(255, 181, 75))

	var_31_4:addTo(var_31_1)
	var_31_4:setPosition(cc.p(0, 0))
	var_31_4:setAnchorPoint(cc.p(0, 0))
	var_31_4:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_31_5 = var_31_4:getContentSize()
	local var_31_6 = arg_31_0:createTextLabel(var_31_2, nil, cc.ui.TEXT_ALIGN_LEFT, 26, cc.c3b(255, 255, 255))

	var_31_6:addTo(var_31_1)
	var_31_6:setPosition(cc.p(var_31_5.width + 10, -3))
	var_31_6:setAnchorPoint(cc.p(0, 0))
	var_31_6:enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_31_7 = var_31_6:getContentSize()

	var_31_1:addTo(var_31_0)
	var_31_1:setContentSize(var_31_5.width + 10 + var_31_7.width, var_31_7.height + 5)
	var_31_1:setAnchorPoint(cc.p(0.5, 0))
	var_31_1:setPosition(cc.p(185, 0))
	var_31_0:setContentSize(370, var_31_7.height + 5)

	return var_31_0
end

function var_0_0.createTextLabel(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4, arg_32_5)
	local var_32_0 = {
		text = arg_32_1,
		align = arg_32_3,
		color = arg_32_5,
		size = arg_32_4
	}
	local var_32_1 = xyd.AssetLoader.get():loadLabel(var_32_0)

	if arg_32_2 then
		var_32_1:setDimensions(arg_32_2, 0)
	end

	return var_32_1
end

function var_0_0.createGrowItem(arg_33_0)
	local var_33_0 = display.newNode()
	local var_33_1 = arg_33_0.hero_:promoteAttr()
	local var_33_2 = arg_33_0.hero_:maxAttrPoint()
	local var_33_3 = arg_33_0.hero_:attrStar()

	arg_33_0.addPromoteAttr_ = {}
	arg_33_0.attrItemNum_ = arg_33_0.backpack:getItemNumByID(var_0_3:attrItem(arg_33_0.hero_:getTableID()))

	local var_33_4 = 0

	for iter_33_0 = #var_33_1, 1, -1 do
		local var_33_5 = var_33_1[iter_33_0]
		local var_33_6 = arg_33_0.hero_:getPromoteAttrByIndex(iter_33_0)
		local var_33_7 = var_33_2[iter_33_0] or 1
		local var_33_8 = var_33_3[iter_33_0] or 0
		local var_33_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_info/attr_item.csb")

		var_33_9:getChildByName("name"):setString(var_0_4:name(var_33_5))
		var_33_9:getChildByName("name"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_33_9:getChildByName("text_cur_num"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_33_9:getChildByName("text_add_num"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_33_9:getChildByName("text_total_num"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_33_9:getChildByName("text_total_num"):setString("")

		local var_33_10 = var_33_9:getChildByName("name"):getContentSize()
		local var_33_11 = var_33_9:getChildByName("name"):getPositionX()

		var_33_9:getChildByName("text_total_num"):setPositionX(var_33_10.width / 2 + var_33_11 + 10)

		arg_33_0.addPromoteAttr_[iter_33_0] = 0

		arg_33_0:changeAttrNum(var_33_9, var_33_6, arg_33_0.addPromoteAttr_[iter_33_0], var_33_7, var_33_8)

		local function var_33_12(arg_34_0)
			if arg_33_0.addPromoteAttr_[iter_33_0] > 0 then
				arg_33_0.addPromoteAttr_[iter_33_0] = arg_33_0.addPromoteAttr_[iter_33_0] - 1
				arg_33_0.attrItemNum_ = arg_33_0.attrItemNum_ + 1

				arg_33_0:changeAttrNum(var_33_9, var_33_6, arg_33_0.addPromoteAttr_[iter_33_0], var_33_7, var_33_8)
			else
				if arg_34_0 then
					var_0_1.unscheduleGlobal(arg_34_0)

					arg_34_0 = nil
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_5:translation("HAS_DEL_MIN")
				})
			end
		end

		local function var_33_13(arg_35_0)
			if var_33_6 + arg_33_0.addPromoteAttr_[iter_33_0] < var_33_7 and arg_33_0.attrItemNum_ > 0 then
				arg_33_0.addPromoteAttr_[iter_33_0] = arg_33_0.addPromoteAttr_[iter_33_0] + 1
				arg_33_0.attrItemNum_ = arg_33_0.attrItemNum_ - 1

				arg_33_0:changeAttrNum(var_33_9, var_33_6, arg_33_0.addPromoteAttr_[iter_33_0], var_33_7, var_33_8)
			else
				if arg_35_0 then
					var_0_1.unscheduleGlobal(arg_35_0)

					arg_35_0 = nil
				end

				local var_35_0 = ""

				if arg_33_0.attrItemNum_ <= 0 then
					var_35_0 = var_0_5:translation("SNOW_ACTIVITY_FROST_NOT_ENOUGH")
				else
					var_35_0 = var_0_5:translation("HAS_ADD_MAX")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_35_0
				})
			end
		end

		xyd.buttonLongTouch(var_33_9:getChildByName("btn_del"), var_33_12, var_33_12)
		xyd.buttonLongTouch(var_33_9:getChildByName("btn_add"), var_33_13, var_33_13)
		var_33_9:addTo(var_33_0)
		var_33_9:setName("attr_item_" .. iter_33_0)
		var_33_9:setPosition(0, var_33_4)

		var_33_4 = var_33_4 + var_33_9:getChildByName("background"):getContentSize().height + 5
	end

	var_33_0:setContentSize(370, var_33_4 + 10)

	return var_33_0
end

function var_0_0.resetGrowItem(arg_36_0)
	if not arg_36_0.growItems then
		return
	end

	local var_36_0 = arg_36_0.hero_:promoteAttr()
	local var_36_1 = arg_36_0.hero_:maxAttrPoint()
	local var_36_2 = arg_36_0.hero_:attrStar()

	arg_36_0.attrItemNum_ = arg_36_0.backpack:getItemNumByID(var_0_3:attrItem(arg_36_0.hero_:getTableID()))

	for iter_36_0 = #var_36_0, 1, -1 do
		local var_36_3 = arg_36_0.growItems:getChildByName("attr_item_" .. iter_36_0)

		if var_36_3 then
			arg_36_0.addPromoteAttr_[iter_36_0] = 0

			local var_36_4 = var_36_1[iter_36_0] or 0
			local var_36_5 = arg_36_0.hero_:getPromoteAttrByIndex(iter_36_0)
			local var_36_6 = var_36_2[iter_36_0] or 0

			arg_36_0:changeAttrNum(var_36_3, var_36_5, arg_36_0.addPromoteAttr_[iter_36_0], var_36_4, var_36_6)
		end
	end
end

function var_0_0.changeAttrNum(arg_37_0, arg_37_1, arg_37_2, arg_37_3, arg_37_4, arg_37_5)
	local var_37_0 = arg_37_1:getChildByName("bar_new")
	local var_37_1 = arg_37_1:getChildByName("bar_cur")
	local var_37_2 = arg_37_1:getChildByName("text_cur_num")
	local var_37_3 = arg_37_1:getChildByName("text_add_num")
	local var_37_4 = arg_37_1:getChildByName("text_total_num")

	var_37_1:setPercent(math.floor(100 * arg_37_2 / arg_37_4))
	var_37_0:setPercent(math.floor(100 * (arg_37_2 + arg_37_3) / arg_37_4))
	var_37_2:setString(arg_37_2)

	if arg_37_3 > 0 then
		var_37_3:setString("+" .. arg_37_3)
	else
		var_37_3:setString("")
	end

	local var_37_5 = (arg_37_2 + arg_37_3) / arg_37_4 * arg_37_0.hero_:getLevel() * arg_37_5

	if var_37_5 > 0 then
		var_37_4:setString("(+" .. var_37_5 .. ")")
	else
		var_37_4:setString("")
	end
end

function var_0_0.createAttrTitle2(arg_38_0)
	local var_38_0 = display.newNode()
	local var_38_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/snow/snow_info/attr_item_2.csb")

	var_38_1:addTo(var_38_0)

	local var_38_2 = var_38_1:getChildByName("container")
	local var_38_3 = var_38_2:getContentSize()

	var_38_2:getChildByName("btn_reset"):addTouchEventListener(function(arg_39_0, arg_39_1)
		if arg_39_1 == ccui.TouchEventType.ended then
			arg_38_0:resetGrowItem()
		end
	end)
	var_38_2:getChildByName("btn_save"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.ended then
			local var_40_0 = {}
			local var_40_1 = {}

			for iter_40_0 = 1, #arg_38_0.addPromoteAttr_ do
				if arg_38_0.addPromoteAttr_[iter_40_0] > 0 then
					table.insert(var_40_0, iter_40_0)
					table.insert(var_40_1, arg_38_0.addPromoteAttr_[iter_40_0])
				end
			end

			if not next(var_40_0) then
				return
			end

			local var_40_2 = {
				table_id = arg_38_0.hero_:getTableID(),
				attr_indexes = var_40_0,
				attr_nums = var_40_1
			}

			arg_38_0.snowActivity:addAttr(var_40_2, function(arg_41_0, arg_41_1)
				if arg_41_0 == xyd.error.OK then
					arg_38_0.attrListInit_ = false

					arg_38_0:createAttrLayout()
					arg_38_0:updateForce()
				end
			end)
		end
	end)
	var_38_0:setContentSize(370, var_38_3.height + 10)

	return var_38_0
end

function var_0_0.createTotalAttr(arg_42_0)
	local var_42_0 = arg_42_0.hero_
	local var_42_1 = display.newNode()
	local var_42_2 = 20

	for iter_42_0 = xyd.AttributeType.TOTAL_NUM, 1, -1 do
		if var_42_0:getTotalAttrWithOutBook(iter_42_0) > 0 then
			local var_42_3, var_42_4, var_42_5, var_42_6 = arg_42_0:createLabel(iter_42_0, var_42_2)

			var_42_3:addTo(var_42_1)
			var_42_4:addTo(var_42_1)

			if var_42_5 then
				var_42_5:addTo(var_42_1)
			end

			var_42_2 = var_42_2 + 30
		end
	end

	var_42_1:setContentSize(370, var_42_2)

	return var_42_1
end

function var_0_0.createLabel(arg_43_0, arg_43_1, arg_43_2)
	local var_43_0 = arg_43_0.hero_
	local var_43_1 = var_43_0:getTotalAttr(arg_43_1)
	local var_43_2 = var_43_0:getSkillAttr(arg_43_1) + var_43_0:getSkill2Attr(arg_43_1) + var_43_0:getPromoteAttr(arg_43_1)
	local var_43_3 = {
		size = 22,
		x = 20,
		text = xyd.tables.attr:name(arg_43_1) .. ":",
		color = cc.c3b(255, 53, 143),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		y = arg_43_2
	}
	local var_43_4 = xyd.AssetLoader.get():loadLabel(var_43_3)
	local var_43_5 = {
		size = 22,
		text = math.ceil(math.max(0, var_43_1 - var_43_2)),
		color = cc.c3b(70, 69, 69),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		font = xyd.AssetLoader.FONT_NAME,
		x = var_43_3.x + 5 + var_43_4:getContentSize().width,
		y = arg_43_2
	}
	local var_43_6 = xyd.AssetLoader.get():loadLabel(var_43_5)
	local var_43_7 = {
		size = 22,
		text = "+" .. math.ceil(var_43_2),
		color = cc.c3b(24, 184, 54),
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_TOP,
		font = xyd.AssetLoader.FONT_NAME,
		x = var_43_5.x + 5 + var_43_6:getContentSize().width,
		y = arg_43_2
	}
	local var_43_8

	if var_43_2 > 0 then
		var_43_8 = xyd.AssetLoader.get():loadLabel(var_43_7)
	end

	return var_43_4, var_43_6, var_43_8
end

function var_0_0.initRight(arg_44_0)
	local var_44_0 = arg_44_0:nodeByName("btn_change")
	local var_44_1 = var_44_0:getChildByName("button_pink_2")

	function updateBtnChange()
		if arg_44_0.rightBtnIsShow then
			var_44_0:getChildByName("word_cancel"):setVisible(true)
			var_44_0:getChildByName("word_change"):setVisible(false)
		else
			var_44_0:getChildByName("word_cancel"):setVisible(false)
			var_44_0:getChildByName("word_change"):setVisible(true)
		end
	end

	updateBtnChange()
	var_44_1:setVisible(false)

	local var_44_2
	local var_44_3
	local var_44_4

	var_44_0:setTouchEnabled(true)
	var_44_0:setTouchSwallowEnabled(true)
	var_44_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_46_0)
		if arg_46_0.name == "began" then
			var_44_1:setVisible(true)

			var_44_2 = arg_46_0.x
			var_44_3 = arg_46_0.y
			var_44_4 = false
		elseif arg_46_0.name == "moved" then
			local var_46_0 = 10

			if var_46_0 < math.abs(arg_46_0.x - var_44_2) or var_46_0 < math.abs(arg_46_0.y - var_44_3) then
				var_44_1:setVisible(false)

				var_44_4 = true
			end
		elseif arg_46_0.name == "ended" and not var_44_4 then
			var_44_1:setVisible(false)

			arg_44_0.rightBtnIsShow = not arg_44_0.rightBtnIsShow

			arg_44_0:updateRightAction()
			updateBtnChange()
		end

		return true
	end)

	local var_44_5 = var_0_6:ids()
	local var_44_6 = cc.p(arg_44_0:nodeByName("btn_change"):getPosition())

	for iter_44_0 = 1, #var_44_5 do
		local var_44_7 = var_44_5[iter_44_0]
		local var_44_8 = xyd.AssetLoader.get():loadSprite("windows/snow/snow_info/right_bg.png")

		var_44_8:addTo(arg_44_0:nodeByName("btn_right_panel"))
		var_44_8:setName("btn_select_" .. var_44_7)
		var_44_8:setPosition(cc.p(var_44_6))

		local var_44_9 = var_44_8:getContentSize()

		var_44_8:setScale(var_0_11 / var_44_9.width)
		var_44_8:setVisible(false)
		xyd.imgEvent(var_44_8, function()
			if arg_44_0.snowActivity:getBaseInfo().effect_id == var_44_7 then
				return
			end

			if arg_44_0.snowActivity:isUnLockEffect(var_44_7) then
				local var_47_0 = {
					effect_id = var_44_7
				}

				arg_44_0.snowActivity:equipEffect(var_47_0, function(arg_48_0, arg_48_1)
					if arg_48_0 == xyd.error.OK and arg_44_0 and not tolua.isnull(arg_44_0) then
						arg_44_0.rightBtnIsShow = not arg_44_0.rightBtnIsShow

						arg_44_0:updateRightAction()
						updateBtnChange()
						arg_44_0:updateRight()
					end
				end)
			end
		end)

		local var_44_10 = xyd.AssetLoader.get():loadSprite("windows/snow/snow_info/btn_select_" .. var_44_7 .. ".png")

		var_44_10:addTo(var_44_8)
		var_44_10:setScale(0.98)
		var_44_10:setPosition(cc.p(var_44_9.width / 2, var_44_9.height / 2))

		local var_44_11 = xyd.AssetLoader.get():loadSprite("windows/snow/snow_info/word_select_" .. var_44_7 .. ".png")

		var_44_11:addTo(var_44_8)
		var_44_11:setScale(1.5)
		var_44_11:setName("word_select_" .. var_44_7)
		var_44_11:setPosition(cc.p(var_44_9.width / 2, var_44_9.height / 2))

		local var_44_12 = var_0_6:req(var_44_7)
		local var_44_13 = var_0_6:reqDesc(var_44_7)

		if var_44_12 > 0 then
			var_44_13 = string.format(var_0_6:reqDesc(var_44_7), var_44_12)
		end

		local var_44_14 = arg_44_0:createTextLabel(var_44_13, var_0_11 + 50, cc.ui.TEXT_ALIGN_CENTER, 22, cc.c3b(149, 190, 29))

		var_44_14:addTo(var_44_8)
		var_44_14:setScale(2)
		var_44_14:setName("text_lock_" .. var_44_7)
		var_44_14:setPosition(cc.p(var_44_9.width / 2, var_44_9.height / 2))
		var_44_14:setAnchorPoint(cc.p(0.5, 0.5))
		var_44_14:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	end

	arg_44_0:updateRight()
end

function var_0_0.updateRightAction(arg_49_0)
	for iter_49_0 = 1, 6 do
		local var_49_0
		local var_49_1 = arg_49_0:nodeByName("btn_right_panel")
		local var_49_2

		if arg_49_0.rightBtnIsShow then
			var_49_0 = cc.p(arg_49_0:nodeByName("right_pos_" .. iter_49_0):getPosition())
		else
			var_49_0 = cc.p(arg_49_0:nodeByName("right_pos_0"):getPosition())

			function var_49_2()
				var_49_1:getChildByName("btn_select_" .. iter_49_0):setVisible(false)
			end
		end

		var_49_1:getChildByName("btn_select_" .. iter_49_0):setVisible(true)
		transition.stopTarget(var_49_1:getChildByName("btn_select_" .. iter_49_0))
		transition.moveTo(var_49_1:getChildByName("btn_select_" .. iter_49_0), {
			time = 0.3,
			x = var_49_0.x,
			y = var_49_0.y,
			onComplete = var_49_2
		})
	end
end

function var_0_0.updateRight(arg_51_0)
	local var_51_0 = var_0_6:ids()

	for iter_51_0 = 1, #var_51_0 do
		local var_51_1 = var_51_0[iter_51_0]
		local var_51_2 = arg_51_0:nodeByName("btn_right_panel"):getChildByName("btn_select_" .. var_51_1)
		local var_51_3 = var_51_2:getChildByName("word_select_" .. var_51_1)
		local var_51_4 = var_51_2:getChildByName("text_lock_" .. var_51_1)

		if not arg_51_0.snowActivity:isUnLockEffect(var_51_1) then
			var_51_4:setVisible(true)
			var_51_3:setVisible(false)
		else
			var_51_4:setVisible(false)
			var_51_3:setVisible(true)
		end
	end

	local var_51_5 = arg_51_0.snowActivity:getBaseInfo().effect_id

	arg_51_0:nodeByName("text_cur_effect"):setTexture("windows/snow/snow_info/word_select_" .. var_51_5 .. ".png")
	arg_51_0:nodeByName("right_bg"):removeAllChildren()

	local var_51_6 = arg_51_0:nodeByName("right_bg"):getContentSize()
	local var_51_7 = xyd.AssetLoader.get():loadSprite("windows/snow/snow_info/btn_select_" .. var_51_5 .. ".png")

	var_51_7:addTo(arg_51_0:nodeByName("right_bg"))
	var_51_7:setPosition(cc.p(var_51_6.width / 2, var_51_6.height / 2))
	arg_51_0:updateHeroEffect()
end

function var_0_0.updateLev(arg_52_0)
	if arg_52_0.hero_:getLevel() > arg_52_0.lastLevel then
		arg_52_0.levelUpCount_ = arg_52_0.levelUpCount_ + arg_52_0.hero_:getLevel() - arg_52_0.lastLevel

		arg_52_0:playLevelUpEffect()

		arg_52_0.lastLevel = arg_52_0.hero_:getLevel()
		arg_52_0.skillListInit_ = false

		arg_52_0:createSkillLayout()

		arg_52_0.attrListInit_ = false

		arg_52_0:createAttrLayout()
		arg_52_0:updateForce()
		arg_52_0:updateNameLabel()
	else
		arg_52_0:playEatExpEffect()
	end

	arg_52_0:updateExp()

	if arg_52_0.levelUpCount_ and arg_52_0.levelUpCount_ > 0 then
		local var_52_0 = {}

		table.insert(var_52_0, arg_52_0.levelUpCount_ * var_0_3:getHeroAttrGrow(arg_52_0.hero_:getTableID(), xyd.AttributeType.STRENGTH, arg_52_0.hero_:getStar()))
		table.insert(var_52_0, arg_52_0.levelUpCount_ * var_0_3:getHeroAttrGrow(arg_52_0.hero_:getTableID(), xyd.AttributeType.WISE, arg_52_0.hero_:getStar()))
		table.insert(var_52_0, arg_52_0.levelUpCount_ * var_0_3:getHeroAttrGrow(arg_52_0.hero_:getTableID(), xyd.AttributeType.AGILE, arg_52_0.hero_:getStar()))

		local var_52_1 = arg_52_0:getHeroModel()

		arg_52_0.isShow = true

		var_52_1:win(false, handler(arg_52_0, arg_52_0.setIsShow))
		var_52_1:playAttribute(arg_52_0:getFloatAttrs(var_52_0))
	end

	arg_52_0.levelUpCount_ = 0
end

function var_0_0.getFloatAttrs(arg_53_0, arg_53_1)
	local var_53_0 = clone(arg_53_1)

	if arg_53_1[1] and arg_53_1[1] > 0 then
		var_53_0[xyd.AttributeType.HP] = math.ceil((var_53_0[xyd.AttributeType.HP] or 0) + arg_53_1[1] * xyd.STRENGTH_HP_RATE)
		var_53_0[xyd.AttributeType.HUJIA] = math.ceil((var_53_0[xyd.AttributeType.HUJIA] or 0) + arg_53_1[1] * xyd.STRENGTH_HUJIA_RATE)
	end

	if arg_53_1[2] and arg_53_1[2] > 0 then
		var_53_0[xyd.AttributeType.AP] = math.ceil((var_53_0[xyd.AttributeType.AP] or 0) + arg_53_1[2] * xyd.WISE_AP_RATE)
		var_53_0[xyd.AttributeType.MOKANG] = math.ceil((var_53_0[xyd.AttributeType.MOKANG] or 0) + arg_53_1[2] * xyd.WISE_MOKANG_RATE)
	end

	if arg_53_1[3] and arg_53_1[3] > 0 then
		var_53_0[xyd.AttributeType.AD] = math.ceil((var_53_0[xyd.AttributeType.AD] or 0) + arg_53_1[3] * xyd.AGILE_AD_RATE)
		var_53_0[xyd.AttributeType.HUJIA] = math.ceil((var_53_0[xyd.AttributeType.HUJIA] or 0) + arg_53_1[3] * xyd.AGILE_HUJIA_RATE)
		var_53_0[xyd.AttributeType.AD_BAOJI] = math.ceil((var_53_0[xyd.AttributeType.AD_BAOJI] or 0) + arg_53_1[3] * xyd.AGILE_AD_BAOJI_RATE)
	end

	if arg_53_1[arg_53_0.hero_:getHeroType()] then
		var_53_0[xyd.AttributeType.AD] = (var_53_0[xyd.AttributeType.AD] or 0) + arg_53_1[arg_53_0.hero_:getHeroType()]
	end

	return var_53_0
end

function var_0_0.playEatExpEffect(arg_54_0)
	local var_54_0 = arg_54_0:getHeroContainer():getContentSize().width
	local var_54_1 = arg_54_0:getHeroContainer():getContentSize().height
	local var_54_2 = xyd.tables.sound:getSound("train_exp_up")

	audio.playSound(var_54_2, false)

	if not arg_54_0.eatExpEffect then
		local var_54_3 = var_0_9.LevelUp .. ".json"
		local var_54_4 = var_0_9.LevelUp .. ".atlas"

		arg_54_0.eatExpEffect = var_0_8.new(var_54_3, var_54_4, 1)

		arg_54_0.eatExpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_54_0.eatExpEffect:setPosition(var_54_0 / 2, var_54_1 / 2)
		arg_54_0.eatExpEffect:addTo(arg_54_0:getHeroContainer())
	end

	arg_54_0.eatExpEffect:play(nil, false)
end

function var_0_0.playLevelUpEffect(arg_55_0, arg_55_1)
	local var_55_0 = arg_55_0:getHeroContainer():getContentSize().width
	local var_55_1 = arg_55_0:getHeroContainer():getContentSize().height
	local var_55_2 = xyd.tables.sound:getSound("train_lv_up")

	audio.playSound(var_55_2, false)

	local var_55_3 = arg_55_0:getHeroContainer():getContentSize().width
	local var_55_4 = arg_55_0:getHeroContainer():getContentSize().height

	if arg_55_0.levelUpEffect == nil then
		local var_55_5 = var_0_9.Evolve .. ".json"
		local var_55_6 = var_0_9.Evolve .. ".atlas"

		arg_55_0.levelUpEffect = var_0_8.new(var_55_5, var_55_6, 1)

		arg_55_0.levelUpEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_55_0.levelUpEffect:setPosition(var_55_3 / 2, var_55_4 / 2)
		arg_55_0.levelUpEffect:addTo(arg_55_0:getHeroContainer())
	end

	arg_55_0.levelUpEffect:play(nil, false)

	if arg_55_0.levelUpSprite == nil then
		arg_55_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

		arg_55_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
		arg_55_0.levelUpSprite:setPosition(var_55_3 / 2, var_55_4 / 2)
		arg_55_0.levelUpSprite:addTo(arg_55_0:getHeroContainer())
	end

	arg_55_0.levelUpSprite:setPosition(var_55_3 / 2, var_55_4 / 2)
	arg_55_0.levelUpSprite:setVisible(true)
	arg_55_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1, cc.p(var_55_3 / 2, var_55_4 / 2 + 100)), false, function()
		arg_55_0.levelUpSprite:setVisible(false)
	end)
end

function var_0_0.getHeroContainer(arg_57_0)
	if not arg_57_0.heroContainer_ then
		arg_57_0.heroContainer_ = arg_57_0:nodeByName("hero")

		arg_57_0.heroContainer_:setLocalZOrder(100)
	end

	return arg_57_0.heroContainer_
end

return var_0_0
