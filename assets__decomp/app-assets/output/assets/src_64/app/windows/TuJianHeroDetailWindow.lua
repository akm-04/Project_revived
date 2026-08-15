local var_0_0 = class("TuJianHeroDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 1000
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = "skeletons/ui_effect/library/amour_up"
local var_0_6 = {
	Ability = 2,
	Info = 1,
	Skin = 3,
	Voice = 4
}
local var_0_7 = 342
local var_0_8 = 63
local var_0_9 = class("ScrollView", cc.ui.UIListView)

function var_0_9.ctor(arg_1_0, arg_1_1)
	var_0_9.super.ctor(arg_1_0, arg_1_1)
end

function var_0_9.scrollAuto(arg_2_0)
	return
end

function var_0_9.scrollTo(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0
	local var_3_1

	if type(arg_3_1) == "table" then
		var_3_0 = arg_3_1.x or 0
		var_3_1 = arg_3_1.y or 0
	else
		var_3_0 = arg_3_1
		var_3_1 = arg_3_2
	end

	local var_3_2 = var_3_0 + var_0_8

	arg_3_0.position_ = cc.p(var_3_2, var_3_1)

	if arg_3_3 and arg_3_3 > 0 then
		arg_3_0.scrollNode:runAction(cc.MoveTo:create(arg_3_3, arg_3_0.position_))
	else
		arg_3_0.scrollNode:setPosition(arg_3_0.position_)
	end
end

function var_0_0.ctor(arg_4_0, arg_4_1, arg_4_2)
	var_0_0.super.ctor(arg_4_0, arg_4_1, arg_4_2)

	if arg_4_2 then
		arg_4_0.heros_ = arg_4_2.heros
		arg_4_0.current_ = arg_4_2.current
		arg_4_0.hero = arg_4_0.heros_[arg_4_0.current_]
		arg_4_0.showType = arg_4_2.showType
	end

	arg_4_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_4_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_4_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_4_0.libraryInfos = arg_4_0.library.libraryInfos
	arg_4_0.logs = {}
	arg_4_0.data = {}
	arg_4_0.is_wrong_item = false
end

function var_0_0.updateLive2d(arg_5_0)
	if arg_5_0.handler then
		var_0_1.unscheduleGlobal(arg_5_0.handler)

		arg_5_0.handler = nil
	end

	if not arg_5_0.live2d then
		return
	end

	if arg_5_0 and not tolua.isnull(arg_5_0) and arg_5_0.nodeByName and not tolua.isnull(arg_5_0.cardContainer) then
		arg_5_0.cardContainer:removeAllChildren()

		arg_5_0.live2d = nil
	end

	arg_5_0.handler = var_0_1.performWithDelayGlobal(function()
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateCardContainer()
		end
	end, 0.5)
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	var_0_0.super:willOpen(arg_7_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.REFRESH_HERO_VISIT_REDPOINT, function(arg_8_0)
		if arg_7_0 and not tolua.isnull(arg_7_0) then
			arg_7_0:updateInfoScroll()
			arg_7_0:updateRedPoint()
		end
	end)
	xyd.EventDispatcher.get():addEventListener(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_7_0, arg_7_0.updateLive2d))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.REFRESH_FAVOR_INFO, function(arg_9_0)
		if arg_7_0 and not tolua.isnull(arg_7_0) then
			arg_7_0:updateWindow()
		end
	end)
	arg_7_0:addTopSidebar()
	arg_7_0:updateFavorContainer()
	arg_7_0:updateLikeDesc()
	arg_7_0:updateRule()
end

function var_0_0.updateFavorContainer(arg_10_0)
	arg_10_0:nodeByName("heart_gray"):setTouchEnabled(true)
	arg_10_0:nodeByName("heart_gray"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			arg_10_0:nodeByName("heart_gray"):setScale(0.9)
			arg_10_0:nodeByName("heart_married"):setScale(0.9)
			arg_10_0:nodeByName("heart_red"):setScale(0.9)

			if arg_10_0.hero:getFavorState() == xyd.FavorState.NOT_OPEN then
				local var_11_0 = var_0_2:translation("FAVOR_FUNCTION_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})
			elseif not arg_10_0.hero:getHeroID() or arg_10_0.hero:getHeroID() < 1 then
				local var_11_1 = var_0_2:translation("TO_SEE_WAY_GET_HERO")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_1
				})
			else
				arg_10_0.favorDetailContainer:setVisible(true)
			end

			return true
		elseif arg_11_0.name == "ended" then
			xyd.playButtonSound()
			arg_10_0:nodeByName("heart_gray"):setScale(1)
			arg_10_0:nodeByName("heart_married"):setScale(1)
			arg_10_0:nodeByName("heart_red"):setScale(1)
			arg_10_0.favorDetailContainer:setVisible(false)
		end
	end)

	if not arg_10_0.favorDetailContainer then
		local var_10_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/favor_detail.csb")

		var_10_0:addTo(arg_10_0:nodeByName("background"))
		var_10_0:setName("favor_detail")
		var_10_0:getChildByName("background"):setName("favor_detail_container")
		var_10_0:setPosition(cc.p(165, 102))
		arg_10_0:parseChildren_(var_10_0)

		arg_10_0.favorDetailContainer = var_10_0

		arg_10_0.favorDetailContainer:setVisible(false)
	end
end

function var_0_0.updateWindow(arg_12_0)
	arg_12_0:updateFavorContainer()
	arg_12_0:updateLikeDesc()
	arg_12_0:updateLikability()
	arg_12_0:updateFavor()
end

function var_0_0.updateLikeDesc(arg_13_0)
	local var_13_0 = arg_13_0:nodeByName("lev_desc_container")
	local var_13_1 = arg_13_0.hero:getFavorDegree()
	local var_13_2 = arg_13_0.hero:getFavorLev()
	local var_13_3 = xyd.tables.libraryAmour:amour(var_13_2)

	text = xyd.tables.libraryAmour:name(var_13_2) .. " " .. var_13_1 .. "/" .. var_13_3

	var_13_0:getChildByName("current_lev_text"):setString(var_0_2:translation("LIBRARY_AMOR_DESC1"))
	var_13_0:getChildByName("current_name_txt"):setString(xyd.tables.libraryAmour:name(var_13_2))
	var_13_0:getChildByName("current_attr_grow_desc"):setString("+" .. 100 * xyd.tables.libraryAmour:attr(var_13_2) .. "%")

	if arg_13_0.hero:getFavorState() ~= xyd.FavorState.MARRIED then
		var_13_0:getChildByName("next_lev_text"):setVisible(true)
		var_13_0:getChildByName("next_name_txt"):setVisible(true)
		var_13_0:getChildByName("next_attr_grow_desc"):setVisible(true)
		var_13_0:getChildByName("next_lev_text"):setString(var_0_2:translation("LIBRARY_AMOR_DESC2"))
		var_13_0:getChildByName("next_name_txt"):setString(xyd.tables.libraryAmour:name(var_13_2 + 1))
		var_13_0:getChildByName("next_attr_grow_desc"):setString("+" .. 100 * xyd.tables.libraryAmour:attr(var_13_2 + 1) .. "%")
		arg_13_0:nodeByName("line1"):width(211)
		arg_13_0:nodeByName("next_lev_bg"):setVisible(true)
		arg_13_0:nodeByName("current_name_txt"):setPositionX(229)
		arg_13_0:nodeByName("current_name_txt"):setColor(cc.c3b(76, 50, 25))
		arg_13_0:nodeByName("current_attr_grow_desc"):setPositionX(197)
		arg_13_0:nodeByName("attr_grow_arrow"):setVisible(true)
	else
		var_13_0:getChildByName("next_lev_text"):setVisible(false)
		var_13_0:getChildByName("next_name_txt"):setVisible(false)
		var_13_0:getChildByName("next_attr_grow_desc"):setVisible(false)
		arg_13_0:nodeByName("line1"):width(427)
		arg_13_0:nodeByName("next_lev_bg"):setVisible(false)
		arg_13_0:nodeByName("current_name_txt"):setPositionX(448)
		arg_13_0:nodeByName("current_name_txt"):setColor(cc.c3b(235, 75, 94))
		arg_13_0:nodeByName("current_attr_grow_desc"):setPositionX(448)
		arg_13_0:nodeByName("attr_grow_arrow"):setVisible(false)
	end

	arg_13_0:nodeByName("attr_grow_text"):setString(var_0_2:translation("DORM_ATTR_GROW_TEXT"))
end

function var_0_0.createLabel(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = {
		size = 20,
		color = cc.c3b(76, 50, 19)
	}

	if arg_14_2 then
		var_14_0 = arg_14_2
	end

	local var_14_1 = xyd.AssetLoader.get():loadLabel(var_14_0)

	var_14_1:setMaxLineWidth(420)
	var_14_1:setLineHeight(arg_14_3 or 25)
	var_14_1:setString(arg_14_1)

	return var_14_1
end

function var_0_0.updateRule(arg_15_0)
	local var_15_0 = arg_15_0:createLabel(var_0_2:translation("LIBRARY_AMOR_DESC5"))

	var_15_0:setAnchorPoint(cc.p(0, 0))
	var_15_0:addTo(arg_15_0:nodeByName("rule_coantainer1"))
	var_15_0:setPosition(5, 24)
	arg_15_0:nodeByName("rule_title_text1"):setString(var_0_2:translation("LIBRARY_AMOR_DESC4"))

	local var_15_1 = var_15_0:getContentSize().height + 24

	arg_15_0:nodeByName("rule_coantainer1"):height(var_15_1)
	arg_15_0:nodeByName("rule_bg1"):setPositionY(var_15_1 + 23)
	arg_15_0:nodeByName("rule_title_text1"):setPositionY(var_15_1 + 23)

	local var_15_2 = arg_15_0:createLabel(var_0_2:translation("LIBRARY_AMOR_DESC7"))

	var_15_2:setAnchorPoint(cc.p(0, 0))
	var_15_2:addTo(arg_15_0:nodeByName("rule_coantainer2"))
	var_15_2:setPosition(5, 24)
	arg_15_0:nodeByName("rule_title_text2"):setString(var_0_2:translation("LIBRARY_AMOR_DESC6"))

	local var_15_3 = var_15_2:getContentSize().height + 24

	arg_15_0:nodeByName("rule_bg2"):setPositionY(var_15_3 + 23)
	arg_15_0:nodeByName("rule_title_text2"):setPositionY(var_15_3 + 23)
	arg_15_0:nodeByName("rule_coantainer2"):setPositionY(30)
	arg_15_0:nodeByName("rule_coantainer1"):setPositionY(var_15_3 + 30 + 20)
	arg_15_0:nodeByName("lev_desc_container"):setPositionY(var_15_3 + var_15_1 + 30 + 20 + 40)
	arg_15_0:nodeByName("favor_detail_container"):height(var_15_1 + var_15_3 + 30 + 20 + 40 + 150)
end

function var_0_0.createAmourUpEffect(arg_16_0)
	if arg_16_0.effect and not tolua.isnull(arg_16_0.effect) then
		arg_16_0.effect:removeFromParent()

		arg_16_0.effect = nil
	end

	local var_16_0 = var_0_5 .. ".json"
	local var_16_1 = var_0_5 .. ".atlas"

	arg_16_0.effect = var_0_4.new(var_16_0, var_16_1, 1)

	arg_16_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_16_0.effect:addTo(arg_16_0:nodeByName("favor_container"))
	arg_16_0.effect:setPosition(cc.p(50, 20))
	arg_16_0.effect:setName("effect")
	arg_16_0.effect:play(nil, false)
end

function var_0_0.updateFavor(arg_17_0)
	local var_17_0 = arg_17_0.hero:getFavorState()

	arg_17_0:updateHeartImgState(var_17_0)
	arg_17_0:nodeByName("progress_bar"):setVisible(false)

	local var_17_1

	if var_17_0 == xyd.FavorState.NOT_OPEN then
		var_17_1 = var_0_2:translation("FAVOR_FUNCTION_NOT_OPEN2")
	elseif var_17_0 == xyd.FavorState.MARRIED then
		var_17_1 = var_0_2:translation("HAVE_MARRIED")

		arg_17_0:nodeByName("progress_bar"):setVisible(true)
		arg_17_0:nodeByName("progress_bar"):setPercent(100)
	else
		local var_17_2 = arg_17_0.hero:getFavorDegree()
		local var_17_3 = xyd.tables.libraryAmour:getCurrentId(var_17_2)
		local var_17_4 = xyd.tables.libraryAmour:amour(var_17_3)

		var_17_1 = xyd.tables.libraryAmour:name(var_17_3) .. "   " .. var_17_2 .. "/" .. var_17_4

		arg_17_0:nodeByName("progress_bar"):setPercent(var_17_2 * 100 / var_17_4)
		arg_17_0:nodeByName("progress_bar"):setVisible(true)
	end

	if (not arg_17_0.hero:getHeroID() or arg_17_0.hero:getHeroID() < 1) and var_17_0 ~= xyd.FavorState.NOT_OPEN then
		var_17_1 = var_0_2:translation("NOT_OWN_HERO2")
	end

	arg_17_0:nodeByName("favor_progress_txt"):setString(var_17_1)
	arg_17_0:nodeByName("favor_progress_txt"):enableOutline(cc.c4b(51, 31, 37, 255), 3)
	arg_17_0:nodeByName("favor_progress_txt"):getVirtualRenderer():setAdditionalKerning(2)
end

function var_0_0.updateHeartImgState(arg_18_0, arg_18_1)
	arg_18_0:nodeByName("heart_gray"):setOpacity(0)
	arg_18_0:nodeByName("heart_red"):setVisible(false)
	arg_18_0:nodeByName("heart_married"):setVisible(false)

	if arg_18_1 == xyd.FavorState.NOT_OPEN then
		arg_18_0:nodeByName("heart_gray"):setOpacity(255)
	elseif arg_18_1 == xyd.FavorState.MARRIED then
		arg_18_0:nodeByName("heart_married"):setVisible(true)
	else
		arg_18_0:nodeByName("heart_red"):setVisible(true)
	end
end

function var_0_0.didOpen(arg_19_0, arg_19_1)
	var_0_0.super:didOpen(arg_19_1)
	arg_19_0:layout()
	arg_19_0:updateFavor()
end

function var_0_0.didClose(arg_20_0, arg_20_1)
	var_0_0.super:didClose(arg_20_1)

	if arg_20_0.speakCellContent then
		arg_20_0.speakCellContent:removeDelay()
	end

	if arg_20_0.voiceBtnHandler then
		var_0_1.unscheduleGlobal(arg_20_0.voiceBtnHandler)

		arg_20_0.voiceBtnHandler = nil
	end

	xyd.WindowManager.get():closeWindow("library_hero_favor")
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_MAINSCENE_LEFT_LIVE2D
	})
end

function var_0_0.layout(arg_21_0)
	arg_21_0.cardContainer = arg_21_0:nodeByName("card_container")
	arg_21_0.infoContainer = arg_21_0:nodeByName("info_container")
	arg_21_0.abilityContainer = arg_21_0:nodeByName("ability_container")
	arg_21_0.skinContainer = arg_21_0:nodeByName("skin_container")
	arg_21_0.voiceContainer = arg_21_0:nodeByName("voice_container")

	local var_21_0 = arg_21_0.abilityContainer:getContentSize()

	arg_21_0.abilityScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_21_0.width + 20, var_21_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_21_0.abilityContainer):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	arg_21_0.abilityScroll:setBounceable(true)
	arg_21_0.abilityScroll:setDelegate(handler(arg_21_0, arg_21_0.abilityScrollDelegate))

	local var_21_1 = arg_21_0.infoContainer:getContentSize()

	arg_21_0.infoScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(-10, 0, var_21_1.width + 20, var_21_1.height),
		padding_ = {
			top = 20,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_21_0.infoContainer):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	arg_21_0.infoScroll:setBounceable(true)
	arg_21_0.infoScroll:setDelegate(handler(arg_21_0, arg_21_0.infoScrollDelegate))

	local var_21_2 = arg_21_0.skinContainer:getContentSize()

	arg_21_0.skinScroll = var_0_9.new({
		async = false,
		viewRect = cc.rect(0, 16, var_21_2.width, var_21_2.height - 32),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_21_0.skinContainer):onScroll(handler(arg_21_0, arg_21_0.scrollListener2))

	arg_21_0.skinScroll:setBounceable(false)

	local var_21_3 = arg_21_0.voiceContainer:getChildByName("scroll"):getContentSize()

	arg_21_0.voiceScroll = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_21_3.width, var_21_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_21_0.voiceContainer:getChildByName("scroll")):onScroll(handler(arg_21_0, arg_21_0.scrollListener))

	arg_21_0.voiceScroll:setBounceable(true)
	arg_21_0.voiceScroll:setDelegate(handler(arg_21_0, arg_21_0.voiceScrollDelegate))

	arg_21_0.typeBtns = {
		arg_21_0:nodeByName("info_btn"),
		arg_21_0:nodeByName("ability_btn"),
		arg_21_0:nodeByName("skin_btn"),
		arg_21_0:nodeByName("voice_btn")
	}
	arg_21_0.typeContainer = {
		arg_21_0.infoContainer,
		arg_21_0.abilityContainer,
		arg_21_0.skinContainer,
		arg_21_0.voiceContainer
	}
	arg_21_0.typeTexts = {
		arg_21_0:nodeByName("info_txt"),
		arg_21_0:nodeByName("ability_txt"),
		arg_21_0:nodeByName("skin_txt"),
		arg_21_0:nodeByName("voice_txt")
	}

	arg_21_0:update()
	arg_21_0:setupButtonClick()
	arg_21_0:updateShowType(arg_21_0.showType or var_0_6.Info)
	arg_21_0:playActions()

	if #arg_21_0.heros_ <= 1 then
		arg_21_0:nodeByName("last_hero"):setVisible(false)
		arg_21_0:nodeByName("next_hero"):setVisible(false)
	end
end

function var_0_0.updateShowType(arg_22_0, arg_22_1)
	arg_22_0.showType = arg_22_1

	local var_22_0 = xyd.split(var_0_2:translation("TUJIAN_ABILITY_TYPE_TEXT"), ":")

	for iter_22_0, iter_22_1 in pairs(var_0_6) do
		arg_22_0.typeTexts[iter_22_1]:setString(var_22_0[iter_22_1])

		if iter_22_1 == arg_22_0.showType then
			arg_22_0.typeBtns[iter_22_1]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_22_0.typeContainer[iter_22_1]:setVisible(true)
		else
			arg_22_0.typeBtns[iter_22_1]:setBrightStyle(ccui.BrightStyle.normal)
			arg_22_0.typeContainer[iter_22_1]:setVisible(false)
		end
	end
end

function var_0_0.playActions(arg_23_0)
	if not arg_23_0.actions_ then
		arg_23_0.actions_ = {}

		local var_23_0 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))
		local var_23_1 = cc.Sequence:create(cc.FadeOut:create(1), cc.FadeIn:create(1))

		arg_23_0.actions_[1] = cc.RepeatForever:create(var_23_0)
		arg_23_0.actions_[2] = cc.RepeatForever:create(var_23_1)

		arg_23_0:nodeByName("last_hero"):runAction(arg_23_0.actions_[1])
		arg_23_0:nodeByName("next_hero"):runAction(arg_23_0.actions_[2])
	end
end

function var_0_0.update(arg_24_0)
	arg_24_0.library.current_ = arg_24_0.current_

	if arg_24_0.voiceBtnHandler then
		var_0_1.unscheduleGlobal(arg_24_0.voiceBtnHandler)

		arg_24_0.voiceBtnHandler = nil
	end

	arg_24_0:updateHeroName()
	arg_24_0:updateInfoScroll()
	arg_24_0:updateAbilityScroll()
	arg_24_0:updateSkinScroll()
	arg_24_0:updateVoiceScroll()
	arg_24_0:updateCardContainer()
	arg_24_0:updateSetBoardButtonShow()
	arg_24_0:updateWindow()
end

function var_0_0.updateLikability(arg_25_0)
	return
end

function var_0_0.abilityScrollDelegate(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = arg_26_0.hero:getSkillId()

	for iter_26_0, iter_26_1 in pairs(var_26_0) do
		if iter_26_1 <= 0 then
			table.remove(var_26_0, iter_26_0)
		end
	end

	if cc.ui.UIListView.COUNT_TAG == arg_26_2 then
		if arg_26_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_RECOMMEND) and arg_26_0.heroRecommend:getHeroRecommendScore(arg_26_0.hero:getFirstTableID()) then
			return #var_26_0 + 2
		else
			return #var_26_0 + 1
		end
	elseif cc.ui.UIListView.CELL_TAG == arg_26_2 then
		local var_26_1 = arg_26_0.abilityScroll:dequeueItem()

		if not var_26_1 then
			var_26_1 = arg_26_0.abilityScroll:newItem()
		else
			var_26_1:removeAllChildren(true)
		end

		local var_26_2

		if arg_26_3 == 1 then
			var_26_2 = arg_26_0:creatChartContainerContent()
		elseif arg_26_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_RECOMMEND) and arg_26_0.heroRecommend:getHeroRecommendScore(arg_26_0.hero:getFirstTableID()) then
			if arg_26_3 == 2 then
				var_26_2 = arg_26_0:createRecommendContainerContent()
			else
				var_26_2 = arg_26_0:creatSkillItemContent(var_26_0[arg_26_3 - 2])
			end
		else
			var_26_2 = arg_26_0:creatSkillItemContent(var_26_0[arg_26_3 - 1])
		end

		local var_26_3 = var_26_2:getWidth()
		local var_26_4 = var_26_2:getHeight()

		var_26_1:setItemSize(var_26_3, var_26_4)
		var_26_1:addContent(var_26_2)

		return var_26_1
	end
end

function var_0_0.creatChartContainerContent(arg_27_0)
	local var_27_0 = display.newNode()
	local var_27_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/chart_container.csb")
	local var_27_2 = var_27_1:getChildByName("container")
	local var_27_3 = var_27_2:getChildByName("canvas")

	var_27_2:getChildByName("text_dps"):enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_27_2:getChildByName("text_tank"):enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_27_2:getChildByName("text_march"):enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_27_2:getChildByName("text_assistant"):enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_27_2:getChildByName("text_kill_boss"):enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_27_2:getChildByName("text_jic"):enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_27_2:getChildByName("text_dps"):setString(var_0_2:translation("TEXT_DPS"))
	var_27_2:getChildByName("text_tank"):setString(var_0_2:translation("TEXT_TANK"))
	var_27_2:getChildByName("text_march"):setString(var_0_2:translation("TEXT_MARCH"))
	var_27_2:getChildByName("text_assistant"):setString(var_0_2:translation("TEXT_ASSISTANT"))
	var_27_2:getChildByName("text_kill_boss"):setString(var_0_2:translation("TEXT_KILL_BOSS"))
	var_27_2:getChildByName("text_jic"):setString(var_0_2:translation("TEXT_JIC"))
	arg_27_0:updateInfoChart(var_27_3)
	var_27_1:addTo(var_27_0)
	var_27_1:setAnchorPoint(cc.p(0, 0))
	var_27_0:setContentSize(var_27_2:getContentSize())
	var_27_1:setName("source")

	return var_27_0
end

function var_0_0.createRecommendContainerContent(arg_28_0)
	local var_28_0 = display.newNode()
	local var_28_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/recommend_container.csb")
	local var_28_2 = var_28_1:getChildByName("container")

	var_28_2:getChildByName("score_text"):setString(var_0_2:translation("RECOMMEND_SCORE_TEXT") .. ":")
	var_28_2:getChildByName("score_txt"):setString(arg_28_0.heroRecommend:getHeroRecommendScore(arg_28_0.hero:getFirstTableID()))
	var_28_2:getChildByName("score_text"):enableOutline(cc.c4b(51, 31, 31, 255))
	var_28_2:getChildByName("score_txt"):enableOutline(cc.c4b(51, 31, 31, 255))
	var_28_2:getChildByName("skill_title_text"):setString(var_0_2:translation("SKILL_DESC_TEXT"))
	var_28_2:getChildByName("recommend_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.ended then
			arg_28_0.heroRecommend:toRecommendDetailWindow(arg_28_0.hero:getFirstTableID())
		end
	end)
	var_28_1:addTo(var_28_0)
	var_28_1:setAnchorPoint(cc.p(0, 0))
	var_28_0:setContentSize(var_28_2:getContentSize())
	var_28_1:setName("source")

	return var_28_0
end

function var_0_0.creatSkillItemContent(arg_30_0, arg_30_1)
	local var_30_0 = display.newNode()
	local var_30_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/skill_item.csb")
	local var_30_2 = var_30_1:getChildByName("container")
	local var_30_3 = var_30_2:getChildByName("icon_container")
	local var_30_4 = var_30_2:getChildByName("desc_pos")
	local var_30_5 = var_30_2:getChildByName("name_txt")

	var_30_5:enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_30_2:setPosition(cc.p(10, 0))

	if arg_30_1 > 0 then
		xyd.setSkillBorder(var_30_3, arg_30_1, true)
		var_30_5:setString(xyd.tables.skill:name(arg_30_1))

		local var_30_6 = arg_30_0:createSkillDescLabel(arg_30_1)

		var_30_6:setAnchorPoint(cc.p(0, 1))
		var_30_6:addTo(var_30_2)
		var_30_6:setPosition(var_30_4:getPosition())
		var_30_1:addTo(var_30_0)
		var_30_1:setAnchorPoint(cc.p(0, 0))
		var_30_0:setContentSize(var_30_2:getContentSize())
		var_30_1:setName("source")

		local var_30_7 = var_30_6:getContentSize().height

		if var_30_7 > cc.p(var_30_4:getPosition()).y then
			var_30_0:setContentSize(var_30_2:getContentSize().width, var_30_2:getContentSize().height + var_30_7 - cc.p(var_30_4:getPosition()).y)
			var_30_1:setPosition(0, var_30_7 - cc.p(var_30_4:getPosition()).y)
		end
	end

	return var_30_0
end

function var_0_0.createSkillDescLabel(arg_31_0, arg_31_1)
	local var_31_0 = xyd.tables.skill:desc(arg_31_1)
	local var_31_1 = {
		font = "fonts/main_font.ttf",
		size = 20,
		color = cc.c3b(76, 50, 25)
	}
	local var_31_2 = xyd.AssetLoader.get():loadLabel(var_31_1)

	var_31_2:setMaxLineWidth(358)
	var_31_2:setString(var_31_0)
	var_31_2:enableOutline(cc.c4b(255, 252, 245, 255), 2)

	return var_31_2
end

function var_0_0.infoScrollDelegate(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	if cc.ui.UIListView.COUNT_TAG == arg_32_2 then
		return #arg_32_0.data + 3
	elseif cc.ui.UIListView.CELL_TAG == arg_32_2 then
		local var_32_0 = arg_32_0.infoScroll:dequeueItem()

		if not var_32_0 then
			var_32_0 = arg_32_0.infoScroll:newItem()
		else
			var_32_0:removeAllChildren(true)
		end

		local var_32_1

		if arg_32_3 == 1 then
			var_32_1 = arg_32_0:creatDataContent()
		elseif arg_32_3 == 2 then
			var_32_1 = arg_32_0:createCharacterContent()
		elseif arg_32_3 == 3 then
			var_32_1 = arg_32_0:creatDiaryContainerContent()
		else
			var_32_1 = arg_32_0:createDailyLogItemContent(arg_32_3 - 3)

			if arg_32_0.is_wrong_item == true then
				var_32_1:setContentSize(arg_32_0.item_width, 0)
			end
		end

		local var_32_2 = var_32_1:getWidth()
		local var_32_3 = var_32_1:getHeight()

		var_32_0:setItemSize(var_32_2, var_32_3)
		var_32_0:addContent(var_32_1)

		return var_32_0
	end
end

function var_0_0.creatDataContent(arg_33_0)
	local var_33_0 = arg_33_0.hero
	local var_33_1 = var_33_0:getTableID()
	local var_33_2 = display.newNode()
	local var_33_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/data_container.csb")
	local var_33_4 = var_33_3:getChildByName("container")

	arg_33_0.item_width = var_33_4:getContentSize().width

	var_33_4:getChildByName("desc2_txt"):setVisible(false)
	var_33_4:getChildByName("hero_name_txt"):enableOutline(cc.c4b(255, 252, 245, 255), 2)

	local var_33_5 = arg_33_0:createDataLabel()

	var_33_5:setAnchorPoint(cc.p(0.5, 0))
	var_33_5:addTo(var_33_4:getChildByName("desc2_pos"))

	local var_33_6 = var_33_5:getContentSize().height - 29
	local var_33_7 = math.max(var_33_6, 0)

	xyd.setPositionBy(var_33_4:getChildByName("title_bg"), cc.p(0, var_33_7))
	xyd.setPositionBy(var_33_4:getChildByName("title_txt"), cc.p(0, var_33_7))

	local var_33_8 = var_33_0:getName()

	var_33_4:getChildByName("hero_name_txt"):setString("——" .. var_33_8)
	var_33_4:getChildByName("title_txt"):setString(var_0_2:translation("HERO_DATA_TITLE"))
	var_33_3:addTo(var_33_2)
	var_33_3:setAnchorPoint(cc.p(0, 0))
	var_33_2:setContentSize(var_33_4:getContentSize().width, var_33_4:getContentSize().height + var_33_7)
	var_33_3:setName("source")

	return var_33_2
end

function var_0_0.createDataLabel(arg_34_0)
	local var_34_0 = xyd.tables.hero:getTalkText(arg_34_0.hero:getTableID())
	local var_34_1 = {
		font = "fonts/main_font.ttf",
		size = 22,
		color = cc.c3b(76, 50, 25)
	}
	local var_34_2 = xyd.AssetLoader.get():loadLabel(var_34_1)

	var_34_2:enableOutline(cc.c4b(255, 252, 245, 255), 2)
	var_34_2:setMaxLineWidth(400)
	var_34_2:setString(var_34_0)

	return var_34_2
end

function var_0_0.createCharacterContent(arg_35_0)
	local var_35_0 = display.newNode()
	local var_35_1 = arg_35_0:createCharacterLabel()

	var_35_1:setAnchorPoint(cc.p(0, 0))
	var_35_1:addTo(var_35_0)
	var_35_1:setPosition(40, 18)
	var_35_0:setContentSize(var_35_1:getContentSize().width + 40, var_35_1:getContentSize().height + 36)

	return var_35_0
end

function var_0_0.createCharacterLabel(arg_36_0)
	local var_36_0 = xyd.tables.hero:getCharacterSetting(arg_36_0.hero:getTableID())

	if var_36_0 == "" then
		var_36_0 = xyd.tables.hero:getDes(arg_36_0.hero:getTableID())
	end

	local var_36_1 = {
		font = "fonts/main_font.ttf",
		size = 22,
		color = cc.c3b(235, 75, 94)
	}
	local var_36_2 = xyd.AssetLoader.get():loadLabel(var_36_1)

	var_36_2:setMaxLineWidth(460)
	var_36_2:setString(var_36_0)

	return var_36_2
end

function var_0_0.creatDiaryContainerContent(arg_37_0)
	local var_37_0 = arg_37_0.hero
	local var_37_1 = var_37_0:getTableID()
	local var_37_2 = display.newNode()
	local var_37_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/visit_container.csb")
	local var_37_4 = var_37_3:getChildByName("container")
	local var_37_5 = var_37_4:getChildByName("dialog_btn")
	local var_37_6 = var_37_4:getChildByName("entrust_btn")

	var_37_4:getChildByName("title_visit_txt"):setString(var_0_2:translation("VISIT_TITLE"))
	var_37_4:getChildByName("title_txt"):setString(var_0_2:translation("TUJIAN_DIALOG_TEXT"))
	var_37_4:getChildByName("not_own_hero_txt"):setVisible(false)

	if not var_37_0:getHeroID() or var_37_0:getHeroID() < 1 or not xyd.tables.hero:isOpenDialog(var_37_0:getTableID()) or not arg_37_0.libraryInfos[arg_37_0.hero:getHeroID()] then
		var_37_4:getChildByName("completion_txt"):setVisible(false)
		var_37_4:getChildByName("send_gift_btn"):setVisible(false)
		var_37_4:getChildByName("interact_btn"):setVisible(false)
		var_37_4:getChildByName("entrust_btn"):setVisible(false)
		var_37_4:getChildByName("dialog_btn"):setVisible(false)
		var_37_4:getChildByName("not_own_hero_txt"):setVisible(true)

		if not xyd.tables.hero:isOpenDialog(var_37_0:getTableID()) then
			var_37_4:getChildByName("not_own_hero_txt"):setString(var_0_2:translation("FAVOR_FUNCTION_NOT_OPEN"))
		else
			var_37_4:getChildByName("not_own_hero_txt"):setString(var_0_2:translation("TO_SEE_WAY_GET_HERO"))
		end
	else
		local var_37_7 = arg_37_0.hero:getTableID()

		if arg_37_0.hero:isAwaken() then
			local var_37_8 = xyd.tables.hero:beforeAwaken(var_37_7)
		end

		if arg_37_0.library:isDialogRedPointShow(arg_37_0.hero) then
			var_37_4:getChildByName("dialog_btn"):getChildByName("red_point"):setVisible(true)
		else
			var_37_4:getChildByName("dialog_btn"):getChildByName("red_point"):setVisible(false)
		end

		if arg_37_0.library:isMissionRedPointShow(arg_37_0.hero) then
			var_37_4:getChildByName("entrust_btn"):getChildByName("red_point"):setVisible(true)
		else
			var_37_4:getChildByName("entrust_btn"):getChildByName("red_point"):setVisible(false)
		end

		if arg_37_0.hero:isHeroMarried() then
			var_37_6:getChildByName("icon_feed"):setVisible(true)
			var_37_6:getChildByName("icon_mission"):setVisible(false)
		else
			var_37_6:getChildByName("icon_feed"):setVisible(false)
			var_37_6:getChildByName("icon_mission"):setVisible(true)
		end

		local var_37_9 = string.format(var_0_2:translation("DIALOGUE_OPEN_PERCENT"), arg_37_0:calculateCompletionString())

		var_37_4:getChildByName("completion_txt"):setString(var_37_9)
		var_37_4:getChildByName("interact_btn"):addTouchEventListener(function(arg_38_0, arg_38_1)
			if arg_38_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_38_0 = {
					hero = arg_37_0.hero
				}

				xyd.WindowManager.get():openWindow("hero_touch_game", var_38_0)
			end
		end)
		var_37_4:getChildByName("send_gift_btn"):addTouchEventListener(function(arg_39_0, arg_39_1)
			if arg_39_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_39_0 = {
					hero = arg_37_0.hero
				}

				xyd.WindowManager.get():openWindow("hero_gift_box", var_39_0)
			end
		end)
		var_37_4:getChildByName("entrust_btn"):addTouchEventListener(function(arg_40_0, arg_40_1)
			if arg_40_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_40_0 = {
					hero = arg_37_0.hero
				}

				if arg_37_0.hero:isHeroMarried() then
					xyd.WindowManager.get():openWindow("library_feed", var_40_0)
				else
					xyd.WindowManager.get():openWindow("hero_task_main", var_40_0)
				end
			end
		end)
		var_37_4:getChildByName("dialog_btn"):addTouchEventListener(function(arg_41_0, arg_41_1)
			if arg_41_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_41_0 = {
					hero = arg_37_0.hero
				}

				xyd.WindowManager.get():openWindow("hero_dialog", var_41_0)
			end
		end)
	end

	var_37_3:addTo(var_37_2)
	var_37_3:setAnchorPoint(cc.p(0, 0))
	var_37_2:setContentSize(var_37_4:getContentSize())
	var_37_3:setName("source")

	return var_37_2
end

function var_0_0.isHasNewDialog(arg_42_0)
	local var_42_0 = {}

	if arg_42_0.libraryInfos[arg_42_0.hero:getHeroID()] then
		var_42_0 = arg_42_0.libraryInfos[arg_42_0.hero:getHeroID()].partner_dialogs or {}
	end

	for iter_42_0 = 1, #var_42_0 do
		if var_42_0[iter_42_0].is_read == 0 then
			return true
		end
	end

	return false
end

function var_0_0.createDailyLogItemContent(arg_43_0, arg_43_1)
	local var_43_0 = display.newNode()
	local var_43_1 = display.newNode()
	local var_43_2 = arg_43_0:isSameDayAsFrontLog(arg_43_1)

	arg_43_0:initCell(var_43_1, arg_43_0.data[arg_43_1], var_43_2)

	if arg_43_0.is_wrong_item == false then
		var_43_0:addChild(var_43_1)
	end

	if var_43_2 == true then
		var_43_0:setContentSize(var_43_1:getContentSize().width, var_43_1:getContentSize().height + 15)
	else
		var_43_0:setContentSize(var_43_1:getContentSize().width, var_43_1:getContentSize().height + 50)
	end

	return var_43_0
end

function var_0_0.isSameDayAsFrontLog(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_0.data[arg_44_1]
	local var_44_1 = os.date("%m", var_44_0.time)
	local var_44_2 = os.date("%d", var_44_0.time)

	if arg_44_1 and arg_44_1 > 1 then
		local var_44_3 = os.date("%m", arg_44_0.data[arg_44_1 - 1].time)
		local var_44_4 = os.date("%d", arg_44_0.data[arg_44_1 - 1].time)

		if var_44_3 == var_44_1 and var_44_4 == var_44_2 then
			is_same_day = true
		else
			is_same_day = false
		end
	elseif arg_44_1 == 1 then
		is_same_day = false
	end

	return is_same_day
end

function var_0_0.initCell(arg_45_0, arg_45_1, arg_45_2, arg_45_3)
	local var_45_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/daily_item.csb")
	local var_45_1 = var_45_0:getChildByName("container")
	local var_45_2 = var_45_1:getContentSize()

	var_45_0:setContentSize(var_45_2)
	arg_45_1:setContentSize(var_45_2)
	var_45_0:setName("resource")
	var_45_0:setPosition(cc.p(30, 0))
	arg_45_1:addChild(var_45_0)
	arg_45_1:setTouchSwallowEnabled(false)
	arg_45_1:setTouchEnabled(true)

	local var_45_3 = os.date("%m", arg_45_2.time)
	local var_45_4 = os.date("%d", arg_45_2.time)

	if arg_45_3 == true then
		var_45_1:getChildByName("data_txt"):setVisible(false)
		var_45_1:getChildByName("cutline"):setVisible(false)
	else
		var_45_1:getChildByName("data_txt"):setString(string.format(var_0_2:translation("TEAM_DATA_DATE"), var_45_3, var_45_4))
	end

	var_45_1:getChildByName("data_txt"):enableOutline(cc.c4b(255, 252, 245, 255), 2)

	local var_45_5 = var_45_1:getChildByName("details")
	local var_45_6 = {}

	if tonumber(arg_45_2.type) == xyd.HeroDailyLogType.Collected then
		local var_45_7 = xyd.split(var_0_2:translation("GET_WAY_TABLE"), ",")[arg_45_2.condition]

		if var_45_7 and arg_45_0.selfPlayer.playerName then
			table.insert(var_45_6, var_45_7)
			table.insert(var_45_6, arg_45_0.selfPlayer.playerName)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.ColorIncrease then
		local var_45_8 = xyd.split(var_0_2:translation("COLOR_TABLE2"), ",")[arg_45_2.condition]

		if var_45_8 then
			table.insert(var_45_6, var_45_8)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.Awake then
		local var_45_9 = xyd.tables.hero:awakenItemID(xyd.tables.hero:beforeAwaken(arg_45_0.hero:getTableID()))
		local var_45_10 = xyd.tables.item:name()

		if var_45_10 then
			table.insert(var_45_6, var_45_10)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.IncreaseStar then
		local var_45_11

		if arg_45_2.condition > 5 then
			var_45_11 = string.format(var_0_2:translation("TITAN_PINK_STAR_NAME"), arg_45_2.condition - 5)
		else
			var_45_11 = string.format(var_0_2:translation("STAR_NUM_TXT"), arg_45_2.condition)
		end

		if var_45_11 then
			table.insert(var_45_6, var_45_11)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.HoldTime then
		local var_45_12 = string.format(var_0_2:translation("DAY_NUM_TXT"), arg_45_2.condition)

		if var_45_12 then
			table.insert(var_45_6, var_45_12)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.BattleCompletion then
		local var_45_13 = var_0_2:translation("BATTlE_TEXT")

		if arg_45_2.openDiary == 6 then
			table.insert(var_45_6, var_45_13)
		elseif arg_45_2.openDiary == 7 then
			table.insert(var_45_6, arg_45_2.condition)
			table.insert(var_45_6, var_45_13)
		elseif arg_45_2.openDiary == 8 then
			table.insert(var_45_6, var_45_13)
			table.insert(var_45_6, arg_45_2.condition)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.DialogueCompletion then
		local var_45_14 = var_0_2:translation("VISIT_TEXT")

		if arg_45_2.openDiary == 9 then
			table.insert(var_45_6, var_45_14)
		elseif arg_45_2.openDiary == 10 then
			table.insert(var_45_6, arg_45_2.condition)
		end
	elseif arg_45_2.type == xyd.HeroDailyLogType.FavorDegree then
		table.insert(var_45_6, arg_45_0.selfPlayer.playerName)
	elseif arg_45_2.type == xyd.HeroDailyLogType.Married then
		table.insert(var_45_6, arg_45_0.selfPlayer.playerName)
		table.insert(var_45_6, arg_45_0.selfPlayer.playerName)
	end

	arg_45_0:colorWords(var_45_5, arg_45_2, var_45_6)
	arg_45_1:setContentSize(var_45_5:getContentSize())
	var_45_1:getChildByName("data_txt"):setPositionY(var_45_5:getContentSize().height + 25)
	var_45_1:getChildByName("cutline"):setPositionY(var_45_5:getContentSize().height + 25 - 14)
end

function var_0_0.createSkinItem(arg_46_0, arg_46_1)
	local var_46_0 = arg_46_0.skinDatas[arg_46_1]
	local var_46_1 = display.newNode()
	local var_46_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/skin/skin_item.csb")
	local var_46_3 = var_46_2:getChildByName("container")
	local var_46_4 = var_46_3:getChildByName("card_container")
	local var_46_5 = xyd.getNormalCard(arg_46_0.hero, xyd.SkinDynamicPosType.LIBRARY_SHOW, var_46_0.modelID)

	if not var_46_0.isHave then
		var_46_5 = xyd.SpriteLoader.new(xyd.tables.model:card(var_46_0.modelID), nil, nil, xyd.DefaultImageType.HERO_CARD)

		xyd.GrayNode(var_46_5)
	end

	xyd.displaySpriteOnContainer(var_46_5, var_46_4, true)

	if var_46_0.isAwaken then
		var_46_3:getChildByName("type_text"):setString(var_0_2:translation("AWAKEN_TEXT"))
	elseif var_46_0.skinItem then
		var_46_3:getChildByName("type_text"):setString(xyd.tables.item:name(var_46_0.skinItem))
		xyd.setCardRare(arg_46_0.hero, var_46_0.modelID, var_46_3, 2, var_46_0.isHave)
	else
		var_46_3:getChildByName("type_text"):setString(var_0_2:translation("NORMAL_TEXT"))
	end

	var_46_3:getChildByName("type_text"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_46_6 = var_46_0.skinSkillID

	if var_46_6 and var_46_6 > 0 then
		var_46_3:getChildByName("no_extra_skill_txt"):setVisible(false)
		xyd.setSkillBorder(var_46_3:getChildByName("skill_icon"), var_46_6, 1)

		local var_46_7 = {
			has_jiantou = false,
			id = var_46_6
		}
		local var_46_8 = var_46_3:getChildByName("skill_icon")

		var_46_8:setTouchEnabled(true)
		var_46_8:addTouchEventListener(function(arg_47_0, arg_47_1)
			if arg_47_1 == ccui.TouchEventType.began then
				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_47_0 = xyd.WindowManager.get():openWindow("skill_tips", var_46_7)

					xyd.adaptToWorldPosition(var_46_8, var_47_0)
				end

				return true
			elseif arg_47_1 == ccui.TouchEventType.moved then
				-- block empty
			elseif arg_47_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	else
		var_46_3:getChildByName("no_extra_skill_txt"):setString(var_0_2:translation("DONT_HAVE_NOW"))
	end

	var_46_2:addTo(var_46_1)
	var_46_2:setAnchorPoint(cc.p(0, 0))
	var_46_1:setContentSize(var_46_3:getContentSize())
	var_46_2:setName("source")

	return var_46_1
end

function var_0_0.colorWords(arg_48_0, arg_48_1, arg_48_2, arg_48_3)
	local var_48_0 = display.newNode()
	local var_48_1 = xyd.tables.libraryDiaryTable:words(arg_48_2.openDiary)
	local var_48_2 = 0
	local var_48_3 = 1
	local var_48_4 = 1
	local var_48_5 = {}
	local var_48_6 = 0
	local var_48_7 = false

	while true do
		local function var_48_8(arg_49_0, arg_49_1)
			local var_49_0 = xyd.getTextLen(arg_49_0)
			local var_49_1 = var_48_6

			var_48_6 = var_48_6 + var_49_0

			while var_48_6 > 20 do
				var_48_4 = var_48_4 + 1

				local var_49_2

				if var_49_1 > 19 then
					var_49_1 = 18
				end

				local var_49_3

				var_49_3, arg_49_0 = xyd.getSplitByTextLen(arg_49_0, 19 - var_49_1)

				if arg_49_0 then
					var_48_6 = xyd.getTextLen(arg_49_0)
				else
					var_48_6 = 0
				end

				var_49_1 = 0

				local var_49_4 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 22,
					text = var_49_3,
					color = arg_49_1,
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_48_0:addChild(var_49_4)
				var_49_4:setPosition(var_48_2, 3)
				var_49_4:setAnchorPoint(cc.p(0, 0))

				var_48_2 = 0

				table.insert(var_48_5, var_49_4)

				for iter_49_0 = 1, #var_48_5 do
					var_48_5[iter_49_0]:setPositionY(var_48_5[iter_49_0]:getPositionY() + 30)
				end
			end

			if not arg_49_0 then
				return
			end

			local var_49_5 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 22,
				text = arg_49_0,
				color = arg_49_1,
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_48_0:addChild(var_49_5)
			var_49_5:setPosition(var_48_2, 3)
			var_49_5:setAnchorPoint(cc.p(0, 0))

			var_48_2 = var_48_2 + var_49_5:getContentSize().width + 3

			table.insert(var_48_5, var_49_5)
		end

		var_48_1 = var_48_1 or ""

		local var_48_9 = string.find(var_48_1, "{")
		local var_48_10 = string.find(var_48_1, "}")

		if var_48_9 and var_48_10 then
			local var_48_11 = string.sub(var_48_1, 1, var_48_9 - 1)
			local var_48_12 = arg_48_3[var_48_3]

			var_48_3 = var_48_3 + 1
			var_48_1 = string.sub(var_48_1, var_48_10 + 1, #var_48_1)

			if var_48_9 < var_48_10 then
				if var_48_12 == nil then
					arg_48_0.is_wrong_item = true

					break
				else
					arg_48_0.is_wrong_item = false
				end

				var_48_8(var_48_11, cc.c3b(76, 50, 25))
				var_48_8("" .. var_48_12, cc.c3b(235, 75, 94))
			else
				print("wrong data.")

				break
			end
		elseif var_48_9 or var_48_10 then
			print("Wrong data.")

			break
		else
			var_48_8(var_48_1, cc.c3b(76, 50, 25))

			break
		end
	end

	arg_48_1:addChild(var_48_0)
	arg_48_1:setContentSize(arg_48_1:getContentSize().width, arg_48_1:getContentSize().height + 30 * (var_48_4 - 1))
end

function var_0_0.setupButtonClick(arg_50_0)
	arg_50_0:nodeByName("senior_forum_text"):setString(var_0_2:translation("SENIOR_FORUM_TEXT"))
	arg_50_0:nodeByName("senior_forum_img"):setTouchEnabled(true)
	arg_50_0:nodeByName("senior_forum_img"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_51_0)
		if arg_51_0.name == "began" then
			arg_50_0:nodeByName("senior_forum_img"):setScale(0.9)

			return true
		elseif arg_51_0.name == "ended" then
			xyd.playButtonSound()
			arg_50_0:nodeByName("senior_forum_img"):setScale(1)
			arg_50_0:openSeniorForumWindow()
		end
	end)
	arg_50_0:nodeByName("set_kanban_img"):setTouchEnabled(true)
	arg_50_0:nodeByName("set_kanban_img"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_52_0)
		if arg_52_0.name == "began" then
			arg_50_0:nodeByName("set_kanban_img"):setScale(0.9)

			return true
		elseif arg_52_0.name == "ended" then
			xyd.playButtonSound()
			arg_50_0:nodeByName("set_kanban_img"):setScale(1)

			local var_52_0 = arg_50_0.hero:getHeroID()

			if var_52_0 and var_52_0 > 0 then
				arg_50_0:onclickSetBoard()
			else
				local var_52_1 = var_0_2:translation("NOT_OWN_HERO")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_52_1
				})
			end
		end
	end)
	arg_50_0:nodeByName("reset_board_hero"):setTouchEnabled(true)
	arg_50_0:nodeByName("reset_board_hero"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_53_0)
		if arg_53_0.name == "began" then
			arg_50_0:nodeByName("set_kanban_img"):setScale(0.9)

			return true
		elseif arg_53_0.name == "ended" then
			xyd.playButtonSound()
			arg_50_0:nodeByName("set_kanban_img"):setScale(1)
			arg_50_0:onclickSetBoard()
		end
	end)
	arg_50_0:nodeByName("get_way_text"):setString(var_0_2:translation("GET_WAY_TEXT"))
	arg_50_0:nodeByName("get_way_img"):setTouchEnabled(true)
	arg_50_0:nodeByName("get_way_img"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
		if arg_54_0.name == "began" then
			arg_50_0:nodeByName("get_way_img"):setScale(0.9)

			return true
		elseif arg_54_0.name == "ended" then
			xyd.playButtonSound()
			arg_50_0:nodeByName("get_way_img"):setScale(1)

			local var_54_0 = arg_50_0.hero
			local var_54_1 = xyd.tables.hero:stoneID(var_54_0:getTableID())

			xyd.WindowManager.get():openWindow("stone", {
				hero = var_54_0,
				itemComposeID = var_54_1
			})
		end
	end)
	arg_50_0:nodeByName("last_hero"):setTouchEnabled(true)
	arg_50_0:nodeByName("last_hero"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_55_0)
		if arg_55_0.name == "began" then
			arg_50_0:nodeByName("last_hero"):setScale(0.9)

			return true
		elseif arg_55_0.name == "ended" then
			audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
			arg_50_0:nodeByName("last_hero"):setScale(1)
			arg_50_0:updateCurrentHero(false)
		end
	end)
	arg_50_0:nodeByName("next_hero"):setTouchEnabled(true)
	arg_50_0:nodeByName("next_hero"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_56_0)
		if arg_56_0.name == "began" then
			arg_50_0:nodeByName("next_hero"):setScale(0.9)

			return true
		elseif arg_56_0.name == "ended" then
			audio.playSound(xyd.tables.sound:getSound("ui_switch_page"))
			arg_50_0:nodeByName("next_hero"):setScale(1)
			arg_50_0:updateCurrentHero(true)
		end
	end)

	for iter_50_0, iter_50_1 in pairs(arg_50_0.typeBtns) do
		iter_50_1:addTouchEventListener(function(arg_57_0, arg_57_1)
			if arg_57_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				arg_50_0:updateShowType(iter_50_0)
			end
		end)
	end
end

function var_0_0.updateCurrentHero(arg_58_0, arg_58_1)
	local var_58_0 = -1

	if arg_58_1 then
		var_58_0 = 1
	end

	while true do
		arg_58_0.current_ = arg_58_0.current_ + var_58_0
		arg_58_0.current_ = (arg_58_0.current_ - 1) % #arg_58_0.heros_ + 1

		if xyd.tables.hero:isLibraryShow(arg_58_0.heros_[arg_58_0.current_]:getFirstTableID()) then
			arg_58_0.hero = arg_58_0.heros_[arg_58_0.current_]

			break
		end
	end

	arg_58_0:update()
end

function var_0_0.openSeniorForumWindow(arg_59_0)
	local var_59_0 = {}

	var_59_0.start_pos = 1
	var_59_0.end_pos = 50
	var_59_0.table_id = arg_59_0.hero:getTableID()

	arg_59_0.library:queryForumByPage(var_59_0, function(arg_60_0, arg_60_1)
		if arg_60_0 == xyd.error.OK then
			local var_60_0 = {
				hero = arg_59_0.hero,
				forum_list = arg_60_1.comments or {}
			}

			xyd.WindowManager.get():openWindow("senior_forum", var_60_0)
		end
	end)
end

function var_0_0.onclickSetBoard(arg_61_0)
	local var_61_0 = arg_61_0.skinDatas[arg_61_0.skinIndex]
	local var_61_1 = arg_61_0.hero:getBoardModelID()

	if not var_61_0.isHave then
		msg = var_0_2:translation("SET_BOARD_NOT_HAVE_TIP")

		xyd.WindowManager.get():openWindow("toast", {
			message = msg
		})

		return
	end

	local var_61_2 = string.format(var_0_2:translation("SURE_SET_BOARD_HERO"), arg_61_0.hero:getName())

	if arg_61_0.hero:isBoardHero() and var_61_0.cardState == arg_61_0.hero:getBoardCard() and (var_61_1 == var_61_0.modelID or var_61_1 == 0 and var_61_0.modelID == arg_61_0.hero.skinId_) then
		var_61_2 = string.format(var_0_2:translation("SURE_RESET_BOARD_HERO"), arg_61_0.hero:getName())
	end

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_61_2, function()
		arg_61_0:playSetBoardHero()
	end, nil, nil, arg_61_0.colorMode)
end

function var_0_0.playSetBoardHero(arg_63_0)
	local var_63_0 = arg_63_0.skinDatas[arg_63_0.skinIndex]
	local var_63_1 = {
		partner_id = arg_63_0.hero:getHeroID(),
		card_status = var_63_0.cardState,
		board_model_id = var_63_0.modelID
	}

	arg_63_0.library:setBoardHero(var_63_1, function(arg_64_0, arg_64_1)
		if arg_64_0 == xyd.error.OK then
			arg_63_0.selfPlayer:reSetAllHeroBoardInfo()

			if arg_64_1.board_partner and arg_64_1.board_partner > 0 then
				arg_63_0.hero:setIsBoardHero(1)
			end

			if arg_64_1.board_card then
				arg_63_0.hero:setBoardCard(arg_64_1.board_card)
			end

			if arg_64_1.board_model_id then
				arg_63_0.hero:setBoardModelID(arg_64_1.board_model_id)
			end

			arg_63_0:updateSetBoardButtonShow()
			arg_63_0:updateKanBanIconShow()
		end
	end)
end

function var_0_0.updateKanBanIconShow(arg_65_0)
	local var_65_0 = xyd.WindowManager.get():getWindow("tujian_hero")

	if var_65_0 then
		var_65_0:updataHeroShow()
	end
end

function var_0_0.updateAbilityScroll(arg_66_0)
	arg_66_0.abilityScroll:reload()
end

function var_0_0.updateSkinScroll(arg_67_0)
	arg_67_0.skinDatas = arg_67_0.hero:getSkinDatas()
	arg_67_0.skinIndex = arg_67_0:getInitSkinIndex(arg_67_0.skinDatas)
	arg_67_0.skinItems = {}

	arg_67_0.skinScroll:removeAllItems(true)

	for iter_67_0 = 1, #arg_67_0.skinDatas do
		local var_67_0
		local var_67_1 = arg_67_0.skinScroll:dequeueItem()

		if not var_67_1 then
			var_67_1 = arg_67_0.skinScroll:newItem()
		else
			var_67_1:removeAllChildren(true)
		end

		local var_67_2 = arg_67_0:createSkinItem(iter_67_0)
		local var_67_3 = var_67_2:getWidth()
		local var_67_4 = var_67_2:getHeight()

		arg_67_0.itemwidth = var_67_3

		var_67_1:setItemSize(var_67_3, var_67_4)
		var_67_1:addContent(var_67_2)
		arg_67_0.skinScroll:addItem(var_67_1)
		arg_67_0.skinScroll:reload()
		table.insert(arg_67_0.skinItems, var_67_2)
	end

	arg_67_0:updateCurrentSelectSkinItem(0)
end

function var_0_0.getInitSkinIndex(arg_68_0, arg_68_1)
	local var_68_0 = 1

	if not arg_68_0.hero.illusionSkinId_ then
		return var_68_0
	end

	if arg_68_0.hero.illusionSkinId_ <= 1 then
		return arg_68_0.hero.illusionSkinId_ + 1
	else
		for iter_68_0 = 2, #arg_68_1 do
			local var_68_1 = arg_68_1[iter_68_0]

			if var_68_1.isHave and var_68_1.cardState == xyd.CardStatus.SKIN_CARD and arg_68_0.hero.illusionSkinId_ == var_68_1.modelID then
				return iter_68_0
			end
		end
	end

	return var_68_0
end

function var_0_0.updateCurrentSelectSkinItem(arg_69_0, arg_69_1)
	arg_69_0.skinScroll:scrollTo((1 - arg_69_0.skinIndex) * var_0_7, 0, arg_69_1 or 0.5)

	for iter_69_0 = 1, #arg_69_0.skinItems do
		local var_69_0 = arg_69_0.skinItems[iter_69_0]:getChildByName("source"):getChildByName("container")

		if iter_69_0 == arg_69_0.skinIndex then
			var_69_0:getChildByName("frame_normal"):setVisible(false)
			var_69_0:getChildByName("frame_bright"):setVisible(true)
		else
			var_69_0:getChildByName("frame_normal"):setVisible(true)
			var_69_0:getChildByName("frame_bright"):setVisible(false)
		end
	end

	arg_69_0:updateCardContainer()
	arg_69_0:updateSetBoardButtonShow()
end

function var_0_0.updateInfoScroll(arg_70_0)
	if not arg_70_0.hero:getHeroID() or arg_70_0.hero:getHeroID() <= 0 then
		arg_70_0.data = {}

		arg_70_0.infoScroll:reload()

		return
	end

	if arg_70_0.libraryInfos[arg_70_0.hero:getHeroID()] then
		arg_70_0.logs = arg_70_0.libraryInfos[arg_70_0.hero:getHeroID()].partner_logs or {}
	else
		arg_70_0.logs = {}
	end

	arg_70_0:parseDailyLog()
	arg_70_0.infoScroll:reload()
end

function var_0_0.parseDailyLog(arg_71_0)
	arg_71_0.data = {}

	for iter_71_0, iter_71_1 in pairs(arg_71_0.logs) do
		local var_71_0 = iter_71_1
		local var_71_1 = xyd.tables.libraryHeroLogTable:openDiary(tonumber(iter_71_0))

		if var_71_1 then
			var_71_0.openDiary = var_71_1
			var_71_0.type = xyd.tables.libraryHeroLogTable:getLogType(tonumber(iter_71_0))
			var_71_0.condition = xyd.tables.libraryHeroLogTable:getCondition(tonumber(iter_71_0))

			table.insert(arg_71_0.data, var_71_0)
		end
	end

	table.sort(arg_71_0.data, function(arg_72_0, arg_72_1)
		return arg_72_0.time < arg_72_1.time
	end)
end

function var_0_0.calculateCompletionString(arg_73_0)
	local var_73_0 = 10
	local var_73_1 = arg_73_0.library.libraryInfos[arg_73_0.hero:getHeroID()]

	if not var_73_1 then
		return "0%"
	end

	local var_73_2 = var_73_1.partner_dialogs or {}
	local var_73_3 = 0

	for iter_73_0 = 1, #var_73_2 do
		if var_73_0 >= var_73_2[iter_73_0].dialog_id then
			var_73_3 = var_73_3 + 1
		end
	end

	if var_73_3 > 10 then
		var_73_3 = 10
	end

	return math.ceil(var_73_3 * 100 / var_73_0) .. "%"
end

function var_0_0.updateInfoChart(arg_74_0, arg_74_1)
	local var_74_0 = arg_74_0.hero

	arg_74_1:removeAllChildren()

	local var_74_1 = cc.p(arg_74_1:getPosition())
	local var_74_2 = var_74_0:getAttrRates()

	xyd.drawColorPentagon(arg_74_1, {
		radius = 112,
		values = var_74_2,
		center = cc.p(110, 100)
	})
end

function var_0_0.updateVoiceScroll(arg_75_0)
	arg_75_0.voiceTable, arg_75_0.isHaveVoice = arg_75_0.hero:getHeroVoiceState()

	arg_75_0.voiceScroll:reload()
end

function var_0_0.voiceScrollDelegate(arg_76_0, arg_76_1, arg_76_2, arg_76_3)
	if cc.ui.UIListView.COUNT_TAG == arg_76_2 then
		return #arg_76_0.voiceTable
	elseif cc.ui.UIListView.CELL_TAG == arg_76_2 then
		local var_76_0 = arg_76_0.voiceScroll:dequeueItem()

		if not var_76_0 then
			var_76_0 = arg_76_0.voiceScroll:newItem()
		else
			var_76_0:removeAllChildren(true)
		end

		local var_76_1 = display.newNode()
		local var_76_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/voice_item.csb")
		local var_76_3 = var_76_2:getChildByName("container")

		var_76_3:setTouchSwallowEnabled(false)

		local var_76_4 = xyd.AssetLoader.get():loadSprite("windows/library/new/word" .. arg_76_0.voiceTable[arg_76_3] .. ".png")

		var_76_4:setAnchorPoint(0, 0.5)
		var_76_4:addTo(var_76_3:getChildByName("img_pos"))

		if arg_76_0.isHaveVoice[arg_76_3] then
			var_76_3:getChildByName("bg_tip"):setVisible(false)
		else
			var_76_3:getChildByName("bg_tip"):getChildByName("tip"):setString(var_0_2:translation("LIBRARY_CV_COLLECT_SOUND_" .. arg_76_0.voiceTable[arg_76_3]))
			var_76_3:getChildByName("bg_tip"):getChildByName("tip"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
			var_76_3:getChildByName("voice_btn"):setTouchEnabled(false)
		end

		var_76_3:getChildByName("voice_btn"):addTouchEventListener(function(arg_77_0, arg_77_1)
			if arg_77_1 == ccui.TouchEventType.ended then
				xyd.AssetDownload.get():preloadCharacterSound({
					arg_76_0.hero:getTableID()
				}, function()
					local var_78_0, var_78_1, var_78_2 = xyd.tables.hero:getSingleVoiceInfo(arg_76_0.hero:getTableID(), arg_76_0.voiceTable[arg_76_3])

					arg_76_0.speakCellContent:specialDialog(var_78_0, var_78_1, var_78_2)

					local var_78_3 = 1

					if arg_76_0.voiceBtnHandler then
						for iter_78_0 = 1, 3 do
							arg_76_0.voiceBtnContainer:getChildByName("icon" .. iter_78_0):setVisible(iter_78_0 == 3)
						end

						var_0_1.unscheduleGlobal(arg_76_0.voiceBtnHandler)
					end

					for iter_78_1 = 1, 3 do
						var_76_3:getChildByName("icon" .. iter_78_1):setVisible(iter_78_1 == 1)
					end

					arg_76_0.voiceBtnContainer = var_76_3
					arg_76_0.voiceBtnHandler = var_0_1.scheduleGlobal(function()
						var_78_2 = var_78_2 - 0.5

						if not var_76_3 or tolua.isnull(var_76_3) then
							var_0_1.unscheduleGlobal(arg_76_0.voiceBtnHandler)

							arg_76_0.voiceBtnHandler = nil

							return
						end

						if var_78_2 <= 0 then
							for iter_79_0 = 1, 3 do
								var_76_3:getChildByName("icon" .. iter_79_0):setVisible(iter_79_0 == 3)
							end

							var_0_1.unscheduleGlobal(arg_76_0.voiceBtnHandler)

							arg_76_0.voiceBtnHandler = nil
						else
							var_78_3 = var_78_3 % 3 + 1

							for iter_79_1 = 1, 3 do
								var_76_3:getChildByName("icon" .. iter_79_1):setVisible(iter_79_1 == var_78_3)
							end
						end
					end, 0.5)
				end)
			end
		end)

		local var_76_5 = var_76_3:getContentSize()

		var_76_1:setContentSize(var_76_5.width, var_76_5.height)
		var_76_2:addTo(var_76_1)
		var_76_0:setItemSize(var_76_5.width, var_76_5.height)
		var_76_0:addContent(var_76_1)

		return var_76_0
	end
end

function var_0_0.updateCardContainer(arg_80_0)
	if arg_80_0.speakCellContent and not tolua.isnull(arg_80_0.speakCellContent) then
		arg_80_0.speakCellContent:removeDelay()
	end

	arg_80_0:setHeroCardBaseOnCardState(arg_80_0.hero)
end

function var_0_0.isCardStateValid(arg_81_0, arg_81_1, arg_81_2)
	if arg_81_2 == xyd.CardStatus.SKIN_CARD then
		if arg_81_1.isSkinOn_ == 1 then
			return true
		else
			return false
		end
	elseif arg_81_2 == xyd.CardStatus.AWAKE_CARD then
		if arg_81_1:isAwaken() then
			return true
		else
			return false
		end
	elseif arg_81_2 == xyd.CardStatus.NORMAL_CARD then
		return true
	end
end

function var_0_0.setHeroCardBaseOnCardState(arg_82_0, arg_82_1)
	local var_82_0 = arg_82_0.skinDatas[arg_82_0.skinIndex]
	local var_82_1 = var_82_0.modelID
	local var_82_2 = xyd.tables.libraryHomeCard:x(var_82_1)
	local var_82_3 = xyd.tables.libraryHomeCard:y(var_82_1)
	local var_82_4 = xyd.tables.model:live2d(var_82_1)

	if arg_82_0.live2d and not tolua.isnull(arg_82_0.live2d) and arg_82_0.live2d.showHeroID == var_82_1 and xyd.isLive2dCanUse() then
		return
	end

	if not arg_82_0 or tolua.isnull(arg_82_0) or not arg_82_0.cardContainer or tolua.isnull(arg_82_0.cardContainer) then
		return
	end

	arg_82_0.cardContainer:removeAllChildren()

	arg_82_0.live2d = nil

	if var_82_0.isHave then
		arg_82_0.library.cardState = arg_82_0.skinIndex
	end

	if not var_82_4 or var_82_4 == "" or not xyd.isLive2dCanUse() then
		local var_82_5 = xyd.getTransparentCard(arg_82_1, xyd.SkinDynamicPosType.LIBRARY, var_82_0.modelID)

		if not var_82_5 then
			return
		end

		arg_82_0.cardContainer:addChild(var_82_5)
		var_82_5:setPosition(cc.p(arg_82_0.cardContainer:getContentSize().width / 2 + var_82_2, var_82_3))
		var_82_5:setAnchorPoint(cc.p(0.5, 0))
		var_82_5:setTouchEnabled(false)
		arg_82_0:addDialog(touchAreaSize)
	else
		local var_82_6 = xyd.tables.libraryHomeCard:live2dx(var_82_1)
		local var_82_7 = xyd.tables.libraryHomeCard:live2dy(var_82_1)
		local var_82_8 = arg_82_0.cardContainer:getContentSize().width / 2 + var_82_6
		local var_82_9 = arg_82_0.cardContainer:getContentSize().height / 2 + var_82_7
		local var_82_10 = cc.Director:getInstance():getVisibleSize()
		local var_82_11, var_82_12 = var_82_8 + (var_82_10.width - xyd.STAGE_WIDTH) / 2, var_82_9 + (var_82_10.height - xyd.STAGE_HEIGHT) / 2
		local var_82_13 = xyd.tables.model:live2dScale(var_82_1)
		local var_82_14 = xyd.newLive2d(arg_82_0.cardContainer, var_82_4, var_82_13 * xyd.STAGE_WIDTH / var_82_10.width, var_82_13 * xyd.STAGE_WIDTH / var_82_10.width, cc.p(var_82_11, var_82_12))

		arg_82_0.live2d = var_82_14
		arg_82_0.live2d.showHeroID = var_82_1

		local function var_82_15(arg_83_0, arg_83_1)
			if not arg_82_0 or not arg_82_0.live2d or tolua.isnull(arg_82_0.live2d) then
				return false
			else
				return true
			end
		end

		local function var_82_16(arg_84_0, arg_84_1)
			if not arg_82_0 or not arg_82_0.live2d or tolua.isnull(arg_82_0.live2d) then
				return
			end

			var_82_14:onDrag(arg_84_0:getLocationInView().x, arg_84_0:getLocationInView().y)

			return true
		end

		local function var_82_17(arg_85_0, arg_85_1)
			if not arg_82_0 or not arg_82_0.live2d or tolua.isnull(arg_82_0.live2d) then
				return
			end

			local var_85_0 = var_82_14:getHitAreaName(arg_85_0:getLocationInView().x, arg_85_0:getLocationInView().y)

			if (var_85_0 == "head" or var_85_0 == "body") and math.random() <= 0.5 then
				if arg_82_0.speakCellContent and not tolua.isnull(arg_82_0.speakCellContent) then
					arg_82_0.speakCellContent:onclick()
				end

				var_82_14:playRandomMotion("talk", xyd.live2dPriority.PRIORITY_NORMAL)
			elseif var_85_0 == "head" then
				var_82_14:playRandomMotion("tap_head", xyd.live2dPriority.PRIORITY_NORMAL)
			elseif var_85_0 == "body" then
				var_82_14:playRandomMotion("tap_body", xyd.live2dPriority.PRIORITY_NORMAL)
			end

			if callback then
				callback()
			end

			var_82_14:initDrag()
		end

		arg_82_0.listener = cc.EventListenerTouchOneByOne:create()

		arg_82_0.listener:setSwallowTouches(false)
		arg_82_0.listener:registerScriptHandler(var_82_15, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_82_0.listener:registerScriptHandler(var_82_16, cc.Handler.EVENT_TOUCH_MOVED)
		arg_82_0.listener:registerScriptHandler(var_82_17, cc.Handler.EVENT_TOUCH_ENDED)
		var_82_14:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_82_0.listener, var_82_14)
		arg_82_0:addDialog(true)
	end

	local var_82_18

	if arg_82_1:isAwaken() then
		var_82_18 = arg_82_1:getFirstTableID()
	else
		var_82_18 = arg_82_1:getTableID()
	end

	local var_82_19 = xyd.tables.hero:isSX(var_82_18)
	local var_82_20 = xyd.AssetLoader.get():loadSprite("windows/hero/icon_sx.png")

	var_82_20:setAnchorPoint(cc.p(0.5, 0.5))
	var_82_20:setPosition(cc.p(140, 600))
	arg_82_0.cardContainer:addChild(var_82_20)

	if var_82_19 then
		var_82_20:setVisible(true)
	else
		var_82_20:setVisible(false)
	end
end

function var_0_0.addDialog(arg_86_0, arg_86_1)
	arg_86_0.cvItem = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/cv_item.csb")

	arg_86_0.cvItem:setAnchorPoint(0.5, 0.5)
	arg_86_0.cvItem:addTo(arg_86_0.cardContainer)
	arg_86_0.cvItem:setPosition(433, 40)
	arg_86_0.cvItem:getChildByName("txt"):enableOutline(cc.c4b(30, 30, 30, 255), 3)
	arg_86_0.cvItem:getChildByName("txt"):setString("CV:" .. xyd.tables.hero:getCV(arg_86_0.hero:getTableID()))

	local var_86_0 = {
		touchPosition = cc.p(0, -175),
		touchAreaSize = touchAreaSize or {
			width = 400,
			height = 500
		},
		msgs = clone(xyd.tables.hero:clickDialog(arg_86_0.hero:getTableID())),
		sounds = clone(xyd.tables.hero:dialogSounds(arg_86_0.hero:getTableID())),
		times = clone(xyd.tables.hero:soundTimes(arg_86_0.hero:getTableID())),
		heroTableID = arg_86_0.hero:getTableID(),
		noTouch = arg_86_1
	}

	if arg_86_0.hero.isCollected_ then
		local var_86_1, var_86_2 = arg_86_0.hero:getHeroVoiceState()

		for iter_86_0 = 5, 1, -1 do
			if not var_86_2[iter_86_0 + 4] then
				table.remove(var_86_0.msgs, iter_86_0)
				table.remove(var_86_0.sounds, iter_86_0)
				table.remove(var_86_0.times, iter_86_0)
			end
		end
	else
		var_86_0.msgs = {
			var_86_0.msgs[1]
		}
		var_86_0.sounds = {
			var_86_0.sounds[1]
		}
		var_86_0.times = {
			var_86_0.times[1]
		}
	end

	arg_86_0.speakCellContent = import("app.windows.SpeakCell").new(var_86_0)

	arg_86_0.speakCellContent:addTo(arg_86_0.cardContainer)
	arg_86_0.speakCellContent:setAnchorPoint(cc.p(0, 0))
	arg_86_0.speakCellContent:setPosition(arg_86_0:nodeByName("talks_pos"):getPosition())
end

function var_0_0.updateHeroName(arg_87_0)
	arg_87_0:nodeByName("hero_name_txt"):setString(arg_87_0.hero:getName())
end

function var_0_0.updateSetBoardButtonShow(arg_88_0)
	local var_88_0 = arg_88_0.skinDatas[arg_88_0.skinIndex]
	local var_88_1 = arg_88_0.hero:getBoardModelID()

	if arg_88_0.hero:isBoardHero() and var_88_0.cardState == arg_88_0.hero:getBoardCard() and (var_88_1 == var_88_0.modelID or var_88_1 == 0 and var_88_0.modelID == arg_88_0.hero.skinId_) then
		arg_88_0:nodeByName("set_kanban_img"):setVisible(false)
		arg_88_0:nodeByName("reset_board_hero"):setVisible(true)
		arg_88_0:nodeByName("set_kanban_text"):setString(var_0_2:translation("RESET_BOARD_TEXT"))
	else
		arg_88_0:nodeByName("set_kanban_img"):setVisible(true)
		arg_88_0:nodeByName("reset_board_hero"):setVisible(false)
		arg_88_0:nodeByName("set_kanban_text"):setString(var_0_2:translation("SET_BOARD_TEXT"))
	end
end

function var_0_0.scrollListener(arg_89_0, arg_89_1)
	if arg_89_1.name == "began" then
		arg_89_0.startClick_ = true
		arg_89_0.prevY_ = arg_89_1.y
	elseif arg_89_1.name == "moved" and 20 <= math.abs(arg_89_1.y - arg_89_0.prevY_) then
		arg_89_0.startClick_ = false
	end
end

function var_0_0.scrollListener2(arg_90_0, arg_90_1)
	if arg_90_1.name == "began" then
		arg_90_0.scrollViewMoved2_ = false
		arg_90_0.prevx_ = arg_90_1.x
	elseif arg_90_1.name == "moved" then
		if 30 <= math.abs(arg_90_1.x - arg_90_0.prevx_) then
			arg_90_0.scrollViewMoved2_ = true
		end
	elseif arg_90_1.name == "ended" then
		if arg_90_0.prevx_ > arg_90_1.x then
			if arg_90_0.prevx_ - arg_90_1.x > var_0_7 / 2 and arg_90_0.skinIndex < #arg_90_0.skinDatas then
				arg_90_0.skinIndex = arg_90_0.skinIndex + 1

				if arg_90_0.skinIndex > #arg_90_0.skinDatas then
					arg_90_0.skinIndex = 1
				end
			end

			arg_90_0:updateCurrentSelectSkinItem()
		elseif arg_90_0.prevx_ < arg_90_1.x then
			if arg_90_0.prevx_ - arg_90_1.x < -var_0_7 / 2 and arg_90_0.skinIndex > 1 then
				arg_90_0.skinIndex = arg_90_0.skinIndex - 1

				if arg_90_0.skinIndex < 1 then
					arg_90_0.skinIndex = #arg_90_0.skinDatas
				end
			end

			arg_90_0:updateCurrentSelectSkinItem()
		end
	end
end

function var_0_0.updateRedPoint(arg_91_0)
	local var_91_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/tujian_hero/hero_detail/visit_container.csb"):getChildByName("container")
	local var_91_1 = var_91_0:getChildByName("dialog_btn")
	local var_91_2 = var_91_0:getChildByName("entrust_btn")

	if arg_91_0.library:isDialogRedPointShow(arg_91_0.hero) then
		var_91_1:getChildByName("red_point"):setVisible(true)
	else
		var_91_1:getChildByName("red_point"):setVisible(false)
	end

	if arg_91_0.library:isMissionRedPointShow(arg_91_0.hero) then
		var_91_2:getChildByName("red_point"):setVisible(true)
	else
		var_91_2:getChildByName("red_point"):setVisible(false)
	end
end

return var_0_0
