local var_0_0 = class("HeroTouchGameWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = 1000
local var_0_5 = "skeletons/ui_effect/library/touch_game/library_game_progress"
local var_0_6 = "skeletons/ui_effect/library/touch_game/library_game_touch1"
local var_0_7 = "skeletons/ui_effect/library/touch_game/library_game_touch2"
local var_0_8 = "skeletons/ui_effect/library/touch_game/library_game_touch3"
local var_0_9 = {
	GameTouchBreast = 3,
	GameTouchHead = 1,
	Main = 0,
	GamePull = 4,
	GameKiss = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.windowState = var_0_9.Main
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.partnerActs = arg_1_0.library.libraryInfos[arg_1_0.hero:getHeroID()].partner_acts
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.bg = arg_2_0:nodeByName("bg")

	arg_2_0:setBG()

	arg_2_0.cardContainer = arg_2_0:nodeByName("card_container")
	arg_2_0.progress = 0
	arg_2_0.isOnPress = false
	arg_2_0.handler = {}
	arg_2_0.touchBtns = {}

	arg_2_0:createTouchButtonEffect()
	arg_2_0:layout()

	local var_2_0 = {
		hero = arg_2_0.hero
	}

	xyd.WindowManager.get():openWindow("library_hero_favor", var_2_0)
end

function var_0_0.setBG(arg_3_0)
	if arg_3_0.bg then
		arg_3_0.bg:removeSelf()
	end

	arg_3_0.bg = xyd.SpriteLoader.new(xyd.tables.libraryBG:getBG(arg_3_0.library.bgRoom), nil, nil, xyd.DefaultImageType.BG_ROOM)

	arg_3_0.bg:setAnchorPoint(0, 0)
	arg_3_0.bg:addTo(arg_3_0, -1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:createProgressBar()
	arg_4_0:updateCardContainer()
	arg_4_0:setButtonClick()
	arg_4_0:updateWindow()
end

function var_0_0.createProgressBar(arg_5_0)
	local var_5_0 = cc.Sprite:create("windows/library/touch_game/progress_bar.png")

	arg_5_0.progressBar = display.newProgressTimer(var_5_0, display.PROGRESS_TIMER_BAR)

	arg_5_0.progressBar:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.progressBar:addTo(arg_5_0:nodeByName("progress_bg"))
	arg_5_0.progressBar:setPosition(cc.p(arg_5_0:nodeByName("progress_bg"):getContentSize().width / 2, arg_5_0:nodeByName("progress_bg"):getContentSize().height / 2))
	arg_5_0.progressBar:setMidpoint(cc.p(0, 0.5))
	arg_5_0.progressBar:setBarChangeRate(cc.p(1, 0))
	arg_5_0.progressBar:setVisible(true)
	arg_5_0.progressBar:setPercentage(0)
	arg_5_0:createProgressEffect()
end

function var_0_0.createProgressEffect(arg_6_0)
	arg_6_0.progressEffect = arg_6_0:createEffect(var_0_5)

	arg_6_0.progressEffect:setVisible(false)
	arg_6_0.progressEffect:addTo(arg_6_0.progressBar)
	arg_6_0.progressEffect:setPosition(cc.p(50, 10))
	arg_6_0.progressEffect:setName("progress_effect")
	arg_6_0.progressEffect:setLocalZOrder(20)
	arg_6_0.progressEffect:play(nil, true)
end

function var_0_0.createTouchButtonEffect(arg_7_0)
	if arg_7_0.touchBtnEffect and not tolua.isnull(arg_7_0.touchBtnEffect) then
		arg_7_0.touchBtnEffect:removeFromParent()

		arg_7_0.touchBtnEffect = nil
	end

	arg_7_0.touchBtnEffect = arg_7_0:createEffect(var_0_7)

	arg_7_0.touchBtnEffect:setVisible(true)
	arg_7_0.touchBtnEffect:addTo(arg_7_0:nodeByName("game_btn_pos"))
	arg_7_0.touchBtnEffect:setName("btn_effect")
	arg_7_0.touchBtnEffect:setLocalZOrder(30)
end

function var_0_0.createTouchArenaEffect(arg_8_0, arg_8_1)
	if arg_8_0.touchArenaEffect and not tolua.isnull(arg_8_0.touchArenaEffect) then
		arg_8_0.touchArenaEffect:removeFromParent()

		arg_8_0.touchArenaEffect = nil
	end

	arg_8_0.touchArenaEffect = arg_8_0:createEffect(var_0_6)

	arg_8_0.touchArenaEffect:setVisible(false)
	arg_8_0.touchArenaEffect:addTo(arg_8_1)

	local var_8_0 = xyd.tables.misc.libraryActFeelRadicus

	arg_8_0.touchArenaEffect:setPosition(cc.p(var_8_0 / 2, var_8_0 / 2))
	arg_8_0.touchArenaEffect:setName("arena_effect")
	arg_8_0.touchArenaEffect:setLocalZOrder(30)
	arg_8_0.touchArenaEffect:play(nil, true)
end

function var_0_0.createCentreBtnEffect(arg_9_0)
	if arg_9_0.touchCentreBtnEffect and not tolua.isnull(arg_9_0.touchCentreBtnEffect) then
		arg_9_0.touchCentreBtnEffect:removeFromParent()

		arg_9_0.touchCentreBtnEffect = nil
	end

	arg_9_0.touchCentreBtnEffect = arg_9_0:createEffect(var_0_8)

	arg_9_0.touchCentreBtnEffect:setVisible(true)
	arg_9_0.touchCentreBtnEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_9_0.touchCentreBtnEffect:addTo(arg_9_0:nodeByName("centre_btn"))
	arg_9_0.touchCentreBtnEffect:setPosition(cc.p(arg_9_0:nodeByName("centre_btn"):getContentSize().width / 2, arg_9_0:nodeByName("centre_btn"):getContentSize().height / 2))
	arg_9_0.touchCentreBtnEffect:setName("centre_btn_effect")
	arg_9_0.touchCentreBtnEffect:setLocalZOrder(30)
end

function var_0_0.createEffect(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1 .. ".json"
	local var_10_1 = arg_10_1 .. ".atlas"
	local var_10_2 = var_0_2.new(var_10_0, var_10_1, 1)

	var_10_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_10_2
end

function var_0_0.setButtonClick(arg_11_0)
	arg_11_0.touchBtns = {
		arg_11_0:nodeByName("touch_head_btn"),
		arg_11_0:nodeByName("kiss_btn"),
		arg_11_0:nodeByName("grab_btn"),
		arg_11_0:nodeByName("pull_lamp_btn")
	}

	for iter_11_0, iter_11_1 in pairs(arg_11_0.touchBtns) do
		if arg_11_0.partnerActs[iter_11_0] then
			iter_11_1:getChildByName("name_text"):setString(xyd.tables.libraryAct:name(iter_11_0))
			iter_11_1:addTouchEventListener(function(arg_12_0, arg_12_1)
				if arg_12_1 == ccui.TouchEventType.ended then
					arg_11_0:createTouchButtonEffect()
					arg_11_0.touchBtnEffect:setPosition(iter_11_1:getPosition())
					arg_11_0.touchBtnEffect:play(function()
						arg_11_0.windowState = iter_11_0

						arg_11_0:updateWindow()
					end, false)
				end
			end)
		else
			iter_11_1:setVisible(false)
		end
	end

	arg_11_0:nodeByName("close"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_11_0.windowState ~= var_0_9.Main then
				arg_11_0.windowState = var_0_9.Main

				arg_11_0:updateWindow()
			else
				xyd.WindowManager.get():closeWindow(arg_11_0)
			end
		end
	end)
	arg_11_0:nodeByName("centre_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			if arg_11_0.progress >= 100 then
				return
			end

			if arg_11_0.currentScale <= 1 then
				arg_11_0:createCentreBtnEffect()
				arg_11_0.touchCentreBtnEffect:play(nil, false)
				transition.stopTarget(arg_11_0.progressEffect)
				arg_11_0.progressEffect:setPositionX(arg_11_0:nodeByName("progress_bar"):getContentSize().width * arg_11_0.progress / 100)
				arg_11_0.progressEffect:setVisible(true)

				arg_11_0.progress = arg_11_0.progress + xyd.tables.misc.libraryActTouchIncrease
			else
				arg_11_0.progressEffect:setVisible(false)

				arg_11_0.progress = arg_11_0.progress + xyd.tables.misc.libraryActTouchDecrease
			end

			if arg_11_0.progress > 100 then
				arg_11_0.progress = 100
			elseif arg_11_0.progress < 0 then
				arg_11_0.progress = 0
			end

			arg_11_0:updateProgressBar()
		end
	end)
end

function var_0_0.updateProgressBar(arg_16_0)
	if arg_16_0.progress == 0 then
		arg_16_0.progressEffect:setVisible(false)
	end

	local var_16_0 = 0.1
	local var_16_1 = cc.ProgressTo:create(var_16_0, arg_16_0.progress)
	local var_16_2 = cc.MoveTo:create(var_16_0, cc.p(arg_16_0:nodeByName("progress_bar"):getContentSize().width * arg_16_0.progress / 100, arg_16_0.progressEffect:getPositionY()))

	arg_16_0.progressEffect:runActionOnce(var_16_2)

	arg_16_0.isOnGetting = false

	arg_16_0.progressBar:runActionOnce(var_16_1)

	if arg_16_0.progress >= 100 and arg_16_0.partnerActs[arg_16_0.windowState].is_awarded == 0 then
		if arg_16_0.isOnGetting then
			return
		end

		arg_16_0.isOnGetting = true

		local var_16_3 = {
			partner_id = arg_16_0.hero:getHeroID(),
			act_id = arg_16_0.windowState
		}

		arg_16_0.library:getActAward(var_16_3, function(arg_17_0, arg_17_1)
			if arg_17_0 == xyd.error.OK and arg_16_0 and not tolua.isnull(arg_16_0) then
				arg_16_0.partnerActs[arg_16_0.windowState].is_awarded = 1

				if arg_17_1.favor_degree then
					arg_16_0.hero:setFavorDegree(arg_17_1.favor_degree)
				end

				arg_16_0:endGame()
			end

			arg_16_0.isOnGetting = false
		end)
	elseif arg_16_0.progress >= 100 then
		arg_16_0:endGame()
	end
end

function var_0_0.endGame(arg_18_0)
	arg_18_0:unscheduleAllHandler()

	if arg_18_0.cardContainer:getChildByName("card"):getChildByName("touchNode") then
		arg_18_0.cardContainer:getChildByName("card"):removeChildByName("touchNode")
	end

	if arg_18_0.touchCentreBtnEffect then
		arg_18_0.touchCentreBtnEffect:setVisible(false)
	end

	local var_18_0 = {}

	if arg_18_0.windowState == var_0_9.GameTouchHead then
		var_18_0 = {
			is_read = 1,
			dialog_id = 12
		}
	elseif arg_18_0.windowState == var_0_9.GameKiss then
		var_18_0 = {
			is_read = 1,
			dialog_id = 13
		}
	elseif arg_18_0.windowState == var_0_9.GameTouchBreast then
		var_18_0 = {
			is_read = 1,
			dialog_id = 14
		}
	elseif arg_18_0.windowState == var_0_9.GamePull then
		arg_18_0:endPullGame()

		return
	end

	arg_18_0.library:playDialog(arg_18_0.hero, var_18_0)

	arg_18_0.windowState = var_0_9.Main

	arg_18_0:updateWindow()
end

function var_0_0.endPullGame(arg_19_0)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.SET_FAVOR_TOP_SHOW,
		params = {
			isShow = false
		}
	})

	local var_19_0 = xyd.AssetLoader.get():loadSprite("windows/library/touch_game/pull_game_img.png")
	local var_19_1 = var_19_0:getContentSize().height

	var_19_0:setAnchorPoint(cc.p(0, 0))
	var_19_0:addTo(arg_19_0:nodeByName("container"))
	var_19_0:setPosition(cc.p(0, 0))

	local var_19_2 = cc.MoveTo:create(4, cc.p(0, 720 - var_19_1))

	var_19_0:runActionOnce(var_19_2)
	var_19_0:setTouchEnabled(true)
	var_19_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			return true
		elseif arg_20_0.name == "ended" then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.SET_FAVOR_TOP_SHOW,
				params = {
					isShow = true
				}
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_FAVOR_INFO
			})
			var_19_0:removeFromParent()

			arg_19_0.windowState = var_0_9.Main

			arg_19_0:updateWindow()
		end
	end)
end

function var_0_0.updateWindow(arg_21_0)
	arg_21_0.isOnPress = false
	arg_21_0.progress = 0

	arg_21_0:updateProgressBar()
	arg_21_0:unscheduleAllHandler()

	if arg_21_0.cardContainer:getChildByName("card"):getChildByName("touchNode") and not tolua.isnull(arg_21_0.cardContainer:getChildByName("card"):getChildByName("touchNode")) then
		arg_21_0.cardContainer:getChildByName("card"):removeChildByName("touchNode")
	end

	arg_21_0:nodeByName("game_btn_pos"):setVisible(false)
	arg_21_0:nodeByName("game_pull_pos"):setVisible(false)
	arg_21_0:nodeByName("progress_bg"):setVisible(false)
	arg_21_0.progressBar:setVisible(false)
	arg_21_0:nodeByName("progress_bar"):setVisible(false)
	arg_21_0:nodeByName("slient_touch_text"):setVisible(false)

	if arg_21_0.windowState == var_0_9.Main then
		arg_21_0:nodeByName("game_btn_pos"):setVisible(true)
	elseif arg_21_0.windowState == var_0_9.GameTouchHead or arg_21_0.windowState == var_0_9.GameTouchBreast then
		arg_21_0:nodeByName("progress_bg"):setVisible(true)
		arg_21_0.progressBar:setVisible(true)
		arg_21_0:nodeByName("slient_touch_text"):setVisible(true)
		arg_21_0:startTouchGame()
	elseif arg_21_0.windowState == var_0_9.GamePull or arg_21_0.windowState == var_0_9.GameKiss then
		arg_21_0:nodeByName("game_pull_pos"):setVisible(true)
		arg_21_0:nodeByName("progress_bg"):setVisible(true)
		arg_21_0.progressBar:setVisible(true)
		arg_21_0:startPullGame()
	end
end

function var_0_0.startTouchGame(arg_22_0)
	local var_22_0 = display.newNode()
	local var_22_1 = xyd.tables.misc.libraryActFeelRadicus

	var_22_0:setName("touchNode")
	var_22_0:setContentSize(var_22_1, var_22_1)
	var_22_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_22_0:setTouchEnabled(true)
	var_22_0:addTo(arg_22_0.cardContainer:getChildByName("card"))
	var_22_0:setPosition(arg_22_0:calculateTouchPosition())
	arg_22_0:createTouchArenaEffect(var_22_0)

	if SHOW_HERO_TOUCH_NODE == true then
		arg_22_0.touchArenaEffect:setVisible(true)
	end

	var_22_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			arg_22_0.isOnPress = true

			arg_22_0.touchArenaEffect:setVisible(true)

			return true
		elseif arg_23_0.name == "moved" then
			-- block empty
		elseif arg_23_0.name == "ended" then
			arg_22_0.isOnPress = false

			arg_22_0.touchArenaEffect:setVisible(false)
		end
	end)

	local var_22_2 = 0.1

	arg_22_0.handler[3] = var_0_1.scheduleGlobal(function()
		if arg_22_0.progress >= 100 and arg_22_0.handler[3] ~= nil then
			var_0_1.unscheduleGlobal(arg_22_0.handler[3])

			arg_22_0.handler[3] = nil
		end

		if arg_22_0.isOnPress == true then
			arg_22_0.progressEffect:setPositionX(arg_22_0:nodeByName("progress_bar"):getContentSize().width * arg_22_0.progress / 100)

			arg_22_0.progress = arg_22_0.progress + xyd.tables.misc.libraryActFeelIncrease * var_22_2

			arg_22_0.progressEffect:setVisible(true)
		else
			arg_22_0.progress = arg_22_0.progress + xyd.tables.misc.libraryActFeelDecrease * var_22_2

			arg_22_0.progressEffect:setVisible(false)
		end

		if arg_22_0.progress > 100 then
			arg_22_0.progress = 100
		elseif arg_22_0.progress < 0 then
			arg_22_0.progress = 0
		end

		arg_22_0:updateProgressBar()
	end, var_22_2)
end

function var_0_0.calculateTouchPosition(arg_25_0)
	local var_25_0 = arg_25_0.cardContainer:getChildByName("card"):getContentSize()
	local var_25_1
	local var_25_2
	local var_25_3 = xyd.isShowDynamicCard(arg_25_0.hero, arg_25_0.cardID)

	if arg_25_0.windowState == var_0_9.GameTouchHead then
		if var_25_3 then
			var_25_1 = xyd.tables.libraryHomeCard:dynamicHeadX(arg_25_0.cardID)
			var_25_2 = xyd.tables.libraryHomeCard:dynamicHeadY(arg_25_0.cardID)
		else
			var_25_1 = xyd.tables.libraryHomeCard:headx(arg_25_0.cardID)
			var_25_2 = xyd.tables.libraryHomeCard:heady(arg_25_0.cardID)
		end
	elseif arg_25_0.windowState == var_0_9.GameTouchBreast then
		if var_25_3 then
			var_25_1 = xyd.tables.libraryHomeCard:dynamicBreastX(arg_25_0.cardID)
			var_25_2 = xyd.tables.libraryHomeCard:dynamicBreastY(arg_25_0.cardID)
		else
			var_25_1 = xyd.tables.libraryHomeCard:breastx(arg_25_0.cardID)
			var_25_2 = xyd.tables.libraryHomeCard:breasty(arg_25_0.cardID)
		end
	end

	local var_25_4 = var_25_0.height - var_25_2

	return cc.p(var_25_1, var_25_4)
end

function var_0_0.startPullGame(arg_26_0)
	arg_26_0.progress = 0

	arg_26_0:updateProgressBar()
	arg_26_0:createScheduler()
end

function var_0_0.createScheduler(arg_27_0)
	if arg_27_0.handler[1] then
		var_0_1.unscheduleGlobal(arg_27_0.handler[1])

		arg_27_0.handler[1] = nil
	end

	arg_27_0.progress = 0

	local var_27_0 = arg_27_0:nodeByName("circle"):getContentSize().width / arg_27_0:nodeByName("centre_btn"):getContentSize().width
	local var_27_1 = 0.05
	local var_27_2 = 0

	arg_27_0.currentScale = var_27_0
	arg_27_0.isScaleUp = false
	arg_27_0.scaleDelta = arg_27_0:getScaleDelta(var_27_1)
	arg_27_0.handler[1] = var_0_1.scheduleGlobal(function()
		var_27_2 = var_27_2 + 1

		if arg_27_0.isScaleUp then
			arg_27_0.currentScale = arg_27_0.currentScale + arg_27_0.scaleDelta
		else
			arg_27_0.currentScale = arg_27_0.currentScale - arg_27_0.scaleDelta
		end

		if arg_27_0.currentScale >= 3 then
			arg_27_0.isScaleUp = false
			arg_27_0.scaleDelta = arg_27_0:getScaleDelta(var_27_1)
		elseif arg_27_0.currentScale <= 0.8 then
			arg_27_0.isScaleUp = true
			arg_27_0.scaleDelta = arg_27_0:getScaleDelta(var_27_1)
		end

		arg_27_0:nodeByName("circle"):setScale(arg_27_0.currentScale / var_27_0)
	end, var_27_1)
end

function var_0_0.getScaleDelta(arg_29_0, arg_29_1)
	local var_29_0 = math.ceil(xyd.tables.misc.librarySpeedMax * 100)
	local var_29_1 = math.ceil(xyd.tables.misc.librarySpeedMin * 100)

	return arg_29_1 * 100 / math.random(var_29_1, var_29_0)
end

function var_0_0.updateCardContainer(arg_30_0)
	arg_30_0.cardID = arg_30_0.library:updateCardContainer(arg_30_0.hero, arg_30_0.cardContainer, arg_30_0.library.cardState)
end

function var_0_0.didClose(arg_31_0, arg_31_1)
	var_0_0.super.didClose(arg_31_0, arg_31_1)
	arg_31_0:unscheduleAllHandler()
	xyd.WindowManager.get():closeWindow("library_hero_favor")
end

function var_0_0.unscheduleAllHandler(arg_32_0)
	for iter_32_0, iter_32_1 in pairs(arg_32_0.handler) do
		if iter_32_1 then
			var_0_1.unscheduleGlobal(iter_32_1)
		end
	end
end

return var_0_0
