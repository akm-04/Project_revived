local var_0_0 = class("LibraryHeroFavorWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = "skeletons/ui_effect/library/amour_up"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.hero = arg_1_0.selfPlayer:getHeroByID(arg_1_0.hero:getHeroID()) or arg_1_0.hero
	arg_1_0.lastFavorDegree = arg_1_0.hero:getFavorDegree()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_FAVOR_INFO, function(arg_3_0)
		if arg_3_0.params and arg_3_0.params.hero then
			arg_2_0.hero = arg_3_0.params.hero
			arg_2_0.lastFavorDegree = arg_2_0.hero:getFavorDegree()
		end

		if arg_2_0 and not tolua.isnull(arg_2_0) then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_HERO_VISIT_REDPOINT
			})
			arg_2_0:updateWindow()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.SET_FAVOR_TOP_SHOW, function(arg_4_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			if arg_4_0.params and arg_4_0.params.isShow then
				arg_2_0:setVisible(true)
			else
				arg_2_0:setVisible(false)
			end
		end
	end)
	arg_2_0:layout()
end

function var_0_0.createAmourUpEffect(arg_5_0)
	if arg_5_0.effect and not tolua.isnull(arg_5_0.effect) then
		arg_5_0.effect:removeFromParent()

		arg_5_0.effect = nil
	end

	local var_5_0 = var_0_3 .. ".json"
	local var_5_1 = var_0_3 .. ".atlas"

	arg_5_0.effect = var_0_2.new(var_5_0, var_5_1, 1)

	arg_5_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.effect:addTo(arg_5_0:nodeByName("container"))
	arg_5_0.effect:setPosition(cc.p(294, 57))
	arg_5_0.effect:setName("effect")
	arg_5_0.effect:play(nil, false)
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("desc_container"):setVisible(false)
	arg_6_0:nodeByName("heart_gray"):setTouchEnabled(true)
	arg_6_0:nodeByName("heart_gray"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			arg_6_0:nodeByName("heart_container"):setScale(0.9)

			if arg_6_0.hero:getFavorState() == xyd.FavorState.NOT_OPEN then
				local var_7_0 = var_0_1:translation("FAVOR_FUNCTION_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_0
				})
			elseif not arg_6_0.hero:getHeroID() or arg_6_0.hero:getHeroID() < 1 then
				local var_7_1 = var_0_1:translation("TO_SEE_WAY_GET_HERO")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_7_1
				})
			else
				arg_6_0:nodeByName("desc_container"):setVisible(true)
			end

			return true
		elseif arg_7_0.name == "ended" then
			xyd.playButtonSound()
			arg_6_0:nodeByName("heart_container"):setScale(1)
			arg_6_0:nodeByName("desc_container"):setVisible(false)
		end
	end)
	arg_6_0:updateWindow()
	arg_6_0:updateRule()
end

function var_0_0.updateRule(arg_8_0)
	local var_8_0 = arg_8_0:createLabel(var_0_1:translation("LIBRARY_AMOR_DESC5"))

	var_8_0:setAnchorPoint(cc.p(0, 0))
	var_8_0:addTo(arg_8_0:nodeByName("rule_coantainer1"))
	var_8_0:setPosition(5, 10)

	local var_8_1 = {
		size = 24,
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER
	}
	local var_8_2 = arg_8_0:createLabel(var_0_1:translation("LIBRARY_AMOR_DESC4"), var_8_1, 30)

	var_8_2:setAnchorPoint(cc.p(0.5, 0))
	var_8_2:addTo(arg_8_0:nodeByName("rule_coantainer1"))
	var_8_2:setPosition(190, var_8_0:getContentSize().height + 15)

	local var_8_3 = var_8_0:getContentSize().height + 60

	arg_8_0:nodeByName("rule_coantainer1"):height(var_8_3)

	local var_8_4 = arg_8_0:createLabel(var_0_1:translation("LIBRARY_AMOR_DESC7"))

	var_8_4:setAnchorPoint(cc.p(0, 0))
	var_8_4:addTo(arg_8_0:nodeByName("rule_coantainer2"))
	var_8_4:setPosition(5, 10)

	local var_8_5 = {
		size = 24,
		color = cc.c3b(255, 255, 255),
		align = cc.ui.TEXT_ALIGN_CENTER
	}
	local var_8_6 = arg_8_0:createLabel(var_0_1:translation("LIBRARY_AMOR_DESC6"), var_8_5, 30)

	var_8_6:setAnchorPoint(cc.p(0.5, 0))
	var_8_6:addTo(arg_8_0:nodeByName("rule_coantainer2"))
	var_8_6:setPosition(190, var_8_4:getContentSize().height + 15)

	local var_8_7 = var_8_4:getContentSize().height + 60

	arg_8_0:nodeByName("rule_coantainer2"):height(var_8_7)
	arg_8_0:nodeByName("desc_container"):height(var_8_7 + var_8_3 + 190)
	arg_8_0:nodeByName("rule_coantainer2"):setPositionY(30)
	arg_8_0:nodeByName("rule_coantainer1"):setPositionY(var_8_7 + 30 + 20)
	arg_8_0:nodeByName("lev_desc_container"):setPositionY(var_8_7 + var_8_3 + 30 + 20 + 20)
end

function var_0_0.createLabel(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = {
		size = 20,
		color = cc.c3b(250, 170, 10)
	}

	if arg_9_2 then
		var_9_0 = arg_9_2
	end

	local var_9_1 = xyd.AssetLoader.get():loadLabel(var_9_0)

	var_9_1:setMaxLineWidth(380)
	var_9_1:setLineHeight(arg_9_3 or 25)
	var_9_1:setString(arg_9_1)

	return var_9_1
end

function var_0_0.updateLikeDesc(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("lev_desc_container")
	local var_10_1 = arg_10_0.hero:getFavorDegree()
	local var_10_2 = arg_10_0.hero:getFavorLev()
	local var_10_3 = xyd.tables.libraryAmour:amour(var_10_2)
	local var_10_4 = xyd.tables.libraryAmour:name(var_10_2) .. " " .. var_10_1 .. "/" .. var_10_3

	var_10_0:getChildByName("current_lev_text"):setString(var_0_1:translation("LIBRARY_AMOR_DESC1"))
	var_10_0:getChildByName("current_name_txt"):setString(xyd.tables.libraryAmour:name(var_10_2))
	var_10_0:getChildByName("current_attr_grow_desc"):setString(string.format(var_0_1:translation("LIBRARY_AMOR_DESC3"), 100 * xyd.tables.libraryAmour:attr(var_10_2)) .. "%")

	if arg_10_0.hero:getFavorState() ~= xyd.FavorState.MARRIED then
		var_10_0:getChildByName("next_lev_text"):setVisible(true)
		var_10_0:getChildByName("next_name_txt"):setVisible(true)
		var_10_0:getChildByName("next_attr_grow_desc"):setVisible(true)
		var_10_0:getChildByName("next_lev_text"):setString(var_0_1:translation("LIBRARY_AMOR_DESC2"))
		var_10_0:getChildByName("next_name_txt"):setString(xyd.tables.libraryAmour:name(var_10_2 + 1))
		var_10_0:getChildByName("next_attr_grow_desc"):setString(string.format(var_0_1:translation("LIBRARY_AMOR_DESC3"), 100 * xyd.tables.libraryAmour:attr(var_10_2 + 1)) .. "%")
	else
		var_10_0:getChildByName("next_lev_text"):setVisible(false)
		var_10_0:getChildByName("next_name_txt"):setVisible(false)
		var_10_0:getChildByName("next_attr_grow_desc"):setVisible(false)
	end

	if arg_10_0.lastFavorDegree < arg_10_0.hero:getFavorDegree() then
		arg_10_0.lastFavorDegree = arg_10_0.hero:getFavorDegree()

		arg_10_0:createAmourUpEffect()
	end
end

function var_0_0.updateWindow(arg_11_0)
	arg_11_0:updateLikeDesc()
	arg_11_0:updateLikability()
end

function var_0_0.updateLikability(arg_12_0)
	local var_12_0 = arg_12_0.hero:getFavorState()

	arg_12_0:updateHeartImgState(var_12_0)
	arg_12_0:nodeByName("progress_bar"):setVisible(false)
	arg_12_0:nodeByName("progress_bg"):setVisible(false)

	local var_12_1

	if var_12_0 == xyd.FavorState.NOT_OPEN then
		var_12_1 = var_0_1:translation("FAVOR_FUNCTION_NOT_OPEN2")
	elseif var_12_0 == xyd.FavorState.MARRIED then
		var_12_1 = var_0_1:translation("HAVE_MARRIED")
	else
		local var_12_2 = arg_12_0.hero:getFavorDegree()
		local var_12_3 = xyd.tables.libraryAmour:getCurrentId(var_12_2)
		local var_12_4 = xyd.tables.libraryAmour:amour(var_12_3)

		var_12_1 = xyd.tables.libraryAmour:name(var_12_3) .. " " .. var_12_2 .. "/" .. var_12_4

		arg_12_0:nodeByName("progress_bar"):setPercent(var_12_2 * 100 / var_12_4)
		arg_12_0:nodeByName("progress_bar"):setVisible(true)
		arg_12_0:nodeByName("progress_bg"):setVisible(true)
	end

	if (not arg_12_0.hero:getHeroID() or arg_12_0.hero:getHeroID() < 1) and var_12_0 ~= xyd.FavorState.NOT_OPEN then
		var_12_1 = var_0_1:translation("NOT_OWN_HERO2")
	end

	arg_12_0:nodeByName("progress_txt"):setString(var_12_1)
	arg_12_0:nodeByName("progress_txt"):enableShadow()
end

function var_0_0.updateHeartImgState(arg_13_0, arg_13_1)
	arg_13_0:nodeByName("heart_gray"):setOpacity(0)
	arg_13_0:nodeByName("heart_red"):setVisible(false)
	arg_13_0:nodeByName("heart_married"):setVisible(false)

	if arg_13_1 == xyd.FavorState.NOT_OPEN then
		arg_13_0:nodeByName("heart_gray"):setOpacity(255)
	elseif arg_13_1 == xyd.FavorState.MARRIED then
		arg_13_0:nodeByName("heart_married"):setVisible(true)
	else
		arg_13_0:nodeByName("heart_red"):setVisible(true)
	end
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevX_ = arg_14_1.x
	elseif arg_14_1.name == "moved" and 5 <= math.abs(arg_14_1.x - arg_14_0.prevX_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

return var_0_0
