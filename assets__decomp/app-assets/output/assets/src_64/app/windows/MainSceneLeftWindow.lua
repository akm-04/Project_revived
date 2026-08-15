local var_0_0 = class("MainSceneLeftWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.model.Hero")
local var_0_3 = 3
local var_0_4 = 1000
local var_0_5 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.imgIndex = 0
	arg_1_0.autoCount = 0
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.images = arg_1_0.selfPlayer.lev > 10 and xyd.tables.homeCard:ids() or xyd.tables.homeCard:beforeLoadingIds()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("partner"):pos(435, -20)
	arg_2_0:setMessageBoxVisible(false)
	arg_2_0:onEnterAction()
	xyd.EventDispatcher.get():addEventListener(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_2_0, arg_2_0.updateLive2d))
	xyd.EventDispatcher.get():addEventListener(xyd.event.REFRESH_MAINSCENE_LEFT_LIVE2D, handler(arg_2_0, arg_2_0.updateLive2d))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_START, function(arg_3_0)
		arg_2_0:onEnterAction(arg_3_0.params and arg_3_0.params.quickAction)
	end)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:nodeByName("refresh"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:random()
		end
	end)
	arg_4_0:random()
end

function var_0_0.updateLive2d(arg_6_0, arg_6_1)
	if xyd.WindowManager.get():isWindowOpen("activities") or xyd.WindowManager.get():isWindowOpen("tujian_herodetail") then
		return
	end

	if arg_6_0.handler then
		var_0_1.unscheduleGlobal(arg_6_0.handler)

		arg_6_0.handler = nil
	end

	if not arg_6_0.live2d then
		return
	end

	if arg_6_0 and not tolua.isnull(arg_6_0) and arg_6_0.nodeByName then
		arg_6_0:nodeByName("partner"):removeAllChildren()

		arg_6_0.live2d = nil
	end

	local var_6_0 = 0.5

	if arg_6_1 and string.lower(arg_6_1.name) == xyd.event.REFRESH_MAINSCENE_LEFT_LIVE2D then
		var_6_0 = 0.2
	end

	arg_6_0.handler = var_0_1.performWithDelayGlobal(function()
		if arg_6_0 and not tolua.isnull(arg_6_0) then
			if xyd.WindowManager.get():isWindowOpen("activities") or xyd.WindowManager.get():isWindowOpen("tujian_herodetail") then
				return
			end

			arg_6_0:random()
		end
	end, var_6_0)
end

function var_0_0.random(arg_8_0)
	if not arg_8_0 or tolua.isnull(arg_8_0) or not arg_8_0.nodeByName or not arg_8_0:nodeByName("partner") or tolua.isnull(arg_8_0:nodeByName("partner")) then
		return
	end

	if arg_8_0.imgIndex == 0 then
		arg_8_0.imgIndex = math.random(#arg_8_0.images)
	else
		arg_8_0.imgIndex = xyd.randomIndex(arg_8_0.imgIndex, #arg_8_0.images)
	end

	arg_8_0.image = arg_8_0.images[arg_8_0.imgIndex]
	arg_8_0.showHeroID = arg_8_0.image
	arg_8_0.speakIndex = 0

	local var_8_0 = arg_8_0.selfPlayer:getHeroIgnoreAwaken(arg_8_0.showHeroID)

	if var_8_0 then
		arg_8_0.showHeroID = var_8_0:getModelID()
	end

	if arg_8_0.selfPlayer:getBoardHero() then
		var_8_0 = arg_8_0.selfPlayer:getBoardHero()
		arg_8_0.image = var_8_0:getTableID()
		arg_8_0.showHeroID = var_8_0:getTableID()

		local var_8_1 = var_8_0:getBoardCard()
		local var_8_2 = var_8_0:getBoardModelID()

		if var_8_2 and var_8_2 > 0 then
			arg_8_0.showHeroID = var_8_2
		else
			arg_8_0.showHeroID = var_8_0:getModelID()
		end
	end

	if arg_8_0.live2d and not tolua.isnull(arg_8_0.live2d) and arg_8_0.live2d.showHeroID == arg_8_0.showHeroID and xyd.isLive2dCanUse() then
		return
	end

	arg_8_0:nodeByName("partner"):removeAllChildren()

	arg_8_0.live2d = nil

	local var_8_3 = xyd.tables.model:live2d(arg_8_0.showHeroID)

	if not var_8_3 or var_8_3 == "" or not xyd.isLive2dCanUse() then
		local var_8_4

		if var_8_0 then
			var_8_4 = xyd.getTransparentCard(var_8_0, xyd.SkinDynamicPosType.MAIN_SCENE, arg_8_0.showHeroID)
		else
			var_8_4 = xyd.SpriteLoader.new(xyd.tables.model:transparentCard(arg_8_0.showHeroID), nil, nil, xyd.DefaultImageType.HOME_CARD)
		end

		local var_8_5 = xyd.tables.libraryHomeCard:x(arg_8_0.showHeroID)
		local var_8_6 = xyd.tables.libraryHomeCard:y(arg_8_0.showHeroID)

		arg_8_0:nodeByName("partner"):addChild(var_8_4)
		var_8_4:setPosition(var_8_5, var_8_6)
		var_8_4:setAnchorPoint(cc.p(0.5, 0))
		var_8_4:setTouchEnabled(false)

		arg_8_0.shaking_ = false

		if arg_8_0.commonhandler then
			var_0_1.unscheduleGlobal(arg_8_0.commonhandler)

			arg_8_0.commonhandler = nil
		end

		local var_8_7 = xyd.tables.misc.homepageFloatTime
		local var_8_8 = 0.5

		if var_8_7 then
			local var_8_9 = var_8_7 + var_8_7
		end

		arg_8_0.commonshaking_ = false

		arg_8_0:commonShake(var_8_4)

		arg_8_0.commonhandler = var_0_1.scheduleGlobal(function()
			if arg_8_0 and not tolua.isnull(arg_8_0) then
				if xyd.WindowManager.get():isWindowOpen("activities") or xyd.WindowManager.get():isWindowOpen("tujian_herodetail") then
					return
				end

				arg_8_0:commonShake(var_8_4)
			end
		end, 1)

		local var_8_10 = display.newNode()

		var_8_10:setContentSize(var_8_4:getContentSize().width - 80, var_8_4:getContentSize().height - 80)
		var_8_10:setTouchEnabled(true)
		var_8_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_8_0.isAnimation then
				return
			end

			if arg_10_0.name == "began" then
				return true
			elseif arg_10_0.name == "ended" then
				arg_8_0:playSound()
				arg_8_0:shakeCard(var_8_4)
			end
		end)
		var_8_4:addChild(var_8_10)
	else
		local var_8_11 = xyd.tables.libraryHomeCard:live2dx(arg_8_0.showHeroID)
		local var_8_12 = xyd.tables.libraryHomeCard:live2dy(arg_8_0.showHeroID)
		local var_8_13 = 435 + var_8_11
		local var_8_14 = 345 + var_8_12
		local var_8_15 = cc.Director:getInstance():getVisibleSize()
		local var_8_16, var_8_17 = var_8_13 + (var_8_15.width - xyd.STAGE_WIDTH) / 2, var_8_14 + (var_8_15.height - xyd.STAGE_HEIGHT) / 2
		local var_8_18 = xyd.tables.model:live2dScale(arg_8_0.showHeroID)
		local var_8_19 = xyd.newLive2d(arg_8_0:nodeByName("partner"), var_8_3, var_8_18 * xyd.STAGE_WIDTH / var_8_15.width, var_8_18 * xyd.STAGE_WIDTH / var_8_15.width, cc.p(var_8_16, var_8_17))

		var_8_19:playRandomMotion("idle", xyd.live2dPriority.PRIORITY_NORMAL)

		arg_8_0.live2d = var_8_19
		arg_8_0.live2d.showHeroID = arg_8_0.showHeroID

		local var_8_20 = arg_8_0.live2d.uuid

		local function var_8_21(arg_11_0, arg_11_1)
			if not arg_8_0 or not arg_8_0.live2d or tolua.isnull(arg_8_0.live2d) or arg_8_0.live2d.uuid ~= var_8_20 or arg_8_0.isAnimation then
				return false
			else
				return true
			end
		end

		local function var_8_22(arg_12_0, arg_12_1)
			if not arg_8_0 or not arg_8_0.live2d or tolua.isnull(arg_8_0.live2d) or arg_8_0.live2d.uuid ~= var_8_20 or arg_8_0.isAnimation then
				return
			end

			var_8_19:onDrag(arg_12_0:getLocationInView().x, arg_12_0:getLocationInView().y)

			return true
		end

		local function var_8_23(arg_13_0, arg_13_1)
			if not arg_8_0 or not arg_8_0.live2d or tolua.isnull(arg_8_0.live2d) or arg_8_0.live2d.uuid ~= var_8_20 or arg_8_0.isAnimation then
				return
			end

			local var_13_0 = var_8_19:getHitAreaName(arg_13_0:getLocationInView().x, arg_13_0:getLocationInView().y)

			if (var_13_0 == "head" or var_13_0 == "body") and math.random() <= 0.5 then
				arg_8_0:playSound()
				var_8_19:playRandomMotion("talk", xyd.live2dPriority.PRIORITY_NORMAL)
			elseif var_13_0 == "head" then
				var_8_19:playRandomMotion("tap_head", xyd.live2dPriority.PRIORITY_NORMAL)
			elseif var_13_0 == "body" then
				var_8_19:playRandomMotion("tap_body", xyd.live2dPriority.PRIORITY_NORMAL)
			end

			if callback then
				callback()
			end

			var_8_19:initDrag()
		end

		arg_8_0.listener = cc.EventListenerTouchOneByOne:create()

		arg_8_0.listener:setSwallowTouches(true)
		arg_8_0.listener:registerScriptHandler(var_8_21, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_8_0.listener:registerScriptHandler(var_8_22, cc.Handler.EVENT_TOUCH_MOVED)
		arg_8_0.listener:registerScriptHandler(var_8_23, cc.Handler.EVENT_TOUCH_ENDED)
		var_8_19:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_8_0.listener, var_8_19)
	end

	arg_8_0:removeDelay()
	arg_8_0:autoPlaySound()

	if var_8_0 then
		arg_8_0:marriedEffect(var_8_0)
	end
end

function var_0_0.shakeCard(arg_14_0, arg_14_1)
	if arg_14_0.shaking_ then
		return
	end

	arg_14_0.shaking_ = true

	local var_14_0 = xyd.tables.misc.homepageShakeDuration
	local var_14_1 = xyd.tables.misc.homepageShakeOffPosition1
	local var_14_2 = cc.Sequence:create({
		cc.MoveBy:create(var_14_0[1], cc.p(0, var_14_1)),
		cc.MoveBy:create(var_14_0[2], cc.p(0, -var_14_1 / 2)),
		cc.MoveBy:create(var_14_0[3], cc.p(0, -var_14_1 / 2))
	})

	arg_14_1:runActionOnce(var_14_2, nil, function()
		arg_14_0.shaking_ = false
	end)
end

function var_0_0.commonShake(arg_16_0, arg_16_1)
	if arg_16_0.commonshaking_ then
		return
	end

	arg_16_0.commonshaking_ = true

	local var_16_0 = xyd.tables.misc.homepageFloatTime
	local var_16_1 = xyd.tables.misc.homepageFloatPixel
	local var_16_2 = cc.Sequence:create({
		cc.MoveBy:create(var_16_0, cc.p(0, -var_16_1)),
		cc.MoveBy:create(var_16_0, cc.p(0, var_16_1))
	})

	if arg_16_1 and not tolua.isnull(arg_16_1) then
		arg_16_1:runActionOnce(var_16_2, nil, function()
			arg_16_0.commonshaking_ = false
		end)
	end
end

function var_0_0.playSound(arg_18_0)
	if arg_18_0.live2d and not tolua.isnull(arg_18_0.live2d) then
		arg_18_0.live2d:playRandomMotion("talk", xyd.live2dPriority.PRIORITY_NORMAL)
	end

	local var_18_0 = xyd.tables.hero:clickDialog(arg_18_0.image)
	local var_18_1 = xyd.tables.hero:dialogSounds(arg_18_0.image)
	local var_18_2 = xyd.tables.hero:soundTimes(arg_18_0.image)
	local var_18_3 = xyd.tables.hero:name(arg_18_0.image)
	local var_18_4 = arg_18_0.selfPlayer:getHeroIgnoreAwaken(arg_18_0.image)
	local var_18_5 = {}

	if var_18_4 then
		local var_18_6, var_18_7 = var_18_4:getHeroVoiceState()

		for iter_18_0 = 1, 5 do
			if var_18_7[iter_18_0 + 4] then
				table.insert(var_18_5, iter_18_0)
			end
		end
	else
		var_18_5 = {
			1
		}
	end

	if var_18_0 ~= nil and #var_18_0 > 0 then
		if arg_18_0.speakIndex == 0 then
			arg_18_0.speakIndex = math.random(#var_18_5)
		else
			arg_18_0.speakIndex = xyd.randomIndex(arg_18_0.speakIndex, #var_18_5)
		end

		local var_18_8 = var_18_5[arg_18_0.speakIndex]

		arg_18_0:npcSpeak(var_18_0[var_18_8], var_18_2[var_18_8], var_18_3)

		if var_18_1[var_18_8] ~= "" and var_18_2[var_18_8] > 0 then
			local var_18_9 = {
				arg_18_0.image
			}

			xyd.AssetDownload.get():preloadCharacterSound(var_18_9, function()
				return
			end, true)
			arg_18_0.selfPlayer:playHeroSound(var_18_1[var_18_8], var_18_2[var_18_8], function()
				arg_18_0.autoCount = 0
			end)
		end
	end
end

function var_0_0.setMessageBoxVisible(arg_21_0, arg_21_1)
	if arg_21_1 then
		arg_21_0:nodeByName("talks"):setVisible(true)

		if arg_21_0.selfPlayer:getBoardHero() or arg_21_0.isInTouch then
			arg_21_0:nodeByName("refresh"):setVisible(false)
		else
			arg_21_0:nodeByName("refresh"):setVisible(true)
		end
	else
		arg_21_0:nodeByName("talks"):setVisible(false)
	end
end

function var_0_0.didClose(arg_22_0)
	var_0_0.super.didClose()
	arg_22_0:removeDelay()
end

function var_0_0.npcSpeak(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	if arg_23_0.delay then
		arg_23_0:removeDelay()
	end

	arg_23_0:nodeByName("message_node"):removeAllChildren()
	arg_23_0:nodeByName("name_node"):removeAllChildren()

	local var_23_0 = {
		size = 24,
		color = cc.c4b(86, 51, 19, 255)
	}
	local var_23_1 = xyd.AssetLoader.get():loadLabel(var_23_0)

	var_23_1:setMaxLineWidth(260)
	var_23_1:setString(arg_23_1)
	var_23_1:setAnchorPoint(cc.p(0, 1))
	var_23_1:addTo(arg_23_0:nodeByName("message_node"))

	local var_23_2 = {
		size = 24,
		color = xyd.color.RED,
		valign = cc.ui.TEXT_VALIGN_CENTER
	}
	local var_23_3 = xyd.AssetLoader.get():loadLabel(var_23_2)

	var_23_3:setMaxLineWidth(150)
	var_23_3:setString(arg_23_3)
	var_23_3:setAnchorPoint(cc.p(0.5, 1))
	var_23_3:addTo(arg_23_0:nodeByName("name_node"))

	local var_23_4 = var_23_1:getContentSize().height
	local var_23_5 = var_23_1:getContentSize().width

	arg_23_0:nodeByName("duihua_bg"):height(var_23_4 + 30)
	arg_23_0:nodeByName("duihua_bg"):width(var_23_5 + 55)
	arg_23_0:nodeByName("message_node"):height(var_23_4 + 55)
	var_23_1:setPositionY(25)
	var_23_3:setPosition(arg_23_0:nodeByName("name_node"):getWidth() / 2, 30)
	arg_23_0:setMessageBoxVisible(true)

	arg_23_0.delay = var_0_1.performWithDelayGlobal(function()
		arg_23_0:setMessageBoxVisible(false)
	end, arg_23_2)
end

function var_0_0.removeDelay(arg_25_0)
	arg_25_0:setMessageBoxVisible(false)

	if arg_25_0.delay ~= nil then
		var_0_1.unscheduleGlobal(arg_25_0.delay)

		arg_25_0.delay = nil
	end

	if arg_25_0.autoHandle ~= nil then
		var_0_1.unscheduleGlobal(arg_25_0.autoHandle)

		arg_25_0.autoHandle = nil
	end
end

function var_0_0.autoPlaySound(arg_26_0)
	return
end

function var_0_0.playWindowMove(arg_27_0, arg_27_1)
	local var_27_0 = arg_27_0:nodeByName("background")

	arg_27_0.isInTouch = arg_27_1

	if arg_27_1 then
		local var_27_1 = arg_27_0.image
		local var_27_2 = var_27_1
		local var_27_3 = arg_27_0.selfPlayer:getHeroIgnoreAwaken(var_27_1)

		if var_27_3 then
			var_27_1 = var_27_3:getTableID()
			var_27_2 = var_27_3:getModelID()
		end

		if arg_27_0.selfPlayer:getBoardHero() then
			local var_27_4 = arg_27_0.selfPlayer:getBoardHero()

			var_27_1 = var_27_4:getTableID()

			local var_27_5 = var_27_4:getBoardModelID()
			local var_27_6 = var_27_4:getBoardCard()

			if var_27_5 and var_27_5 > 0 then
				var_27_2 = var_27_5
			else
				var_27_2 = var_27_4:getModelID()
			end
		end

		local var_27_7 = xyd.HeroAnimation.new(var_27_1, var_27_2, xyd.tables.model:uiScale(var_27_2), {})

		if not var_27_7 then
			return false
		end

		var_27_7:idle()
		var_27_7:setName("model")
		var_27_7:setAnchorPoint(cc.p(0, 0))

		arg_27_0.heroModelNode = display.newNode()

		arg_27_0.heroModelNode:addChild(var_27_7)
		arg_27_0.heroModelNode:addTo(arg_27_0:nodeByName("background"))
		arg_27_0:nodeByName("background"):setTouchSwallowEnabled(true)
		var_27_7:setPosition(100, 0)
		arg_27_0.heroModelNode:setContentSize(200, 270)
		arg_27_0.heroModelNode:setPosition(cc.p(xyd.STAGE_WIDTH + 150, 100))

		arg_27_0.heroModelNode.modelID = var_27_2

		arg_27_0.heroModelNode:setTouchEnabled(true)
		arg_27_0.heroModelNode:setTouchSwallowEnabled(true)
		arg_27_0.heroModelNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
			if arg_28_0.name == "began" then
				return true
			elseif arg_28_0.name == "ended" then
				arg_27_0:resetModelState(var_27_7)
			end
		end, nil, 999)
		arg_27_0:showHeroAnimation(arg_27_1)
	else
		arg_27_0:showHeroAnimation(arg_27_1)
	end
end

function var_0_0.showHeroAnimation(arg_29_0, arg_29_1)
	if not arg_29_0.heroModelNode then
		return false
	end

	local var_29_0 = arg_29_0.heroModelNode:getChildByName("model")

	if arg_29_1 then
		arg_29_0.modelState = xyd.ModelState.Walk

		var_29_0:setFlipX(true)
		arg_29_0:resetModelState(var_29_0)
		arg_29_0.heroModelNode:runActionOnce(cc.MoveTo:create(1, cc.p(800, 100)), false, function()
			arg_29_0.modelState = xyd.ModelState.Win

			arg_29_0:resetModelState(var_29_0)
		end)
	else
		var_29_0:setFlipX(false)

		arg_29_0.modelState = xyd.ModelState.Walk

		arg_29_0:resetModelState(var_29_0)
		arg_29_0.heroModelNode:runActionOnce(cc.MoveTo:create(1, cc.p(xyd.STAGE_WIDTH + 150, 100)), true, function()
			return
		end)
	end
end

function var_0_0.resetModelState(arg_32_0, arg_32_1)
	if not arg_32_0.heroModelNode then
		return
	end

	local var_32_0 = arg_32_0.heroModelNode.modelID
	local var_32_1 = arg_32_1

	if arg_32_0.modelState == 8 then
		arg_32_0.modelState = arg_32_0.modelState + 1
	end

	arg_32_0.modelState = arg_32_0.modelState % 8
	arg_32_0.isShow = true

	local var_32_2

	if arg_32_0.modelState == xyd.ModelState.Walk then
		var_32_1:walk(true)

		arg_32_0.isShow = false
		var_32_2 = xyd.tables.model:getMoveSound(var_32_0)
	elseif arg_32_0.modelState == xyd.ModelState.Win then
		var_32_1:win(false, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_2 = xyd.tables.model:getWinSound(var_32_0)
	elseif arg_32_0.modelState == xyd.ModelState.Attack1 then
		var_32_1:attack(1, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_2 = xyd.tables.model:getNormalAttackSound(var_32_0)
	elseif arg_32_0.modelState == xyd.ModelState.Attack2 then
		var_32_1:attack(2, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_2 = xyd.tables.model:getAttack1Sound(var_32_0)
	elseif arg_32_0.modelState == xyd.ModelState.Attack3 then
		var_32_1:attack(3, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_2 = xyd.tables.model:getAttack2Sound(var_32_0)
	elseif arg_32_0.modelState == xyd.ModelState.Attack4 then
		if not var_32_1:hasAnimation("gongji04") then
			arg_32_0.modelState = arg_32_0.modelState + 1

			arg_32_0:resetModelState(arg_32_1)

			return
		end

		var_32_1:attack(4, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_2 = xyd.tables.model:getAttack4Sound(var_32_0)
	elseif arg_32_0.modelState == xyd.ModelState.Attack5 then
		if not var_32_1:hasAnimation("gongji05") then
			arg_32_0.modelState = arg_32_0.modelState + 1

			arg_32_0:resetModelState(arg_32_1)

			return
		end

		var_32_1:attack(5, nil, nil, handler(arg_32_0, arg_32_0.setIsShow))

		var_32_2 = xyd.tables.model:getAttack4Sound(var_32_0)
	else
		arg_32_0:setIsShow()
	end

	if var_32_2 and var_32_2 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_32_2, false)
	end

	arg_32_0.modelState = arg_32_0.modelState + 1
end

function var_0_0.setIsShow(arg_33_0)
	if not arg_33_0.heroModelNode then
		return
	end

	local var_33_0 = arg_33_0.heroModelNode:getChildByName("model")

	arg_33_0.isShow = false

	var_33_0:idle()
end

function var_0_0.marriedEffect(arg_34_0, arg_34_1)
	if arg_34_1:isHeroMarried() then
		local var_34_0 = xyd.tables.libraryHomeCard:x(arg_34_0.showHeroID)
		local var_34_1 = xyd.tables.libraryHomeCard:y(arg_34_0.showHeroID)
		local var_34_2 = arg_34_0:nodeByName("partner")
		local var_34_3 = "skeletons/dynamic_marry/jiemianaixin"
		local var_34_4 = cc.p(var_34_2:getPosition())

		if arg_34_0.live2d and not tolua.isnull(arg_34_0.live2d) and arg_34_0.live2d.showHeroID == arg_34_0.showHeroID and xyd.isLive2dCanUse() then
			-- block empty
		end

		local var_34_5 = xyd.EffectLoader.new(var_34_3, 3, 0.7, {
			x = var_34_0 + 0,
			y = var_34_1 + 200
		})

		var_34_5:setScale(1.6)
		var_34_5:addTo(var_34_2)
		var_34_5:setLocalZOrder(1)
	end
end

function var_0_0.onEnterAction(arg_35_0)
	arg_35_0.isAnimation = true

	arg_35_0:nodeByName("partner"):setOpacity(0)
	arg_35_0:nodeByName("partner"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(90, 0)),
		cc.Spawn:create({
			cc.FadeIn:create(0.4),
			cc.MoveBy:create(0.4, cc.p(-90, 0))
		}),
		cc.CallFunc:create(function()
			arg_35_0.isAnimation = false
		end)
	}))
end

return var_0_0
