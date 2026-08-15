local var_0_0 = class("GuideNewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.guideNew

var_0_0.TIPS_TIME = 1.5
var_0_0.FADEOUT_DELAY = 0.5

local var_0_3 = 10001001

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.nowGuideID = arg_2_1.nowGuideID or 0
	arg_2_0.nowFuncID = arg_2_1.nowFuncID
	arg_2_0.nextGuideID = arg_2_1.nextGuideID

	local var_2_0 = var_0_2:type(arg_2_0.nowGuideID)

	arg_2_0.addSkip = false

	arg_2_0:setContentSize(3000, 3000)

	arg_2_0.btnClick = false

	local var_2_1 = arg_2_0.nowGuideID
	local var_2_2 = var_0_2:pageName(var_2_1)

	if not arg_2_0.nextGuideID or arg_2_0.nextGuideID == 0 then
		arg_2_0.nextGuideID = var_0_2:nextId(arg_2_0.nowGuideID)
	end

	local var_2_3 = var_0_2:returnId(arg_2_0.nowGuideID)
	local var_2_4 = cc.EventListenerTouchOneByOne:create()

	var_2_4:setSwallowTouches(true)

	if var_2_0 ~= 2 then
		arg_2_0:addNode()
	end

	local function var_2_5(arg_3_0, arg_3_1)
		dump(var_2_0)

		local var_3_0 = cc.Director:getInstance():convertToGL(arg_3_0:getLocationInView())

		if var_2_0 == 3 then
			arg_2_0:setTouchSwallowEnabled(true)

			if arg_2_0.addSkip and arg_2_0.skipNode and not tolua.isnull(arg_2_0.skipNode) then
				arg_2_0.clickPartner = false

				if not arg_2_0:isTouchSkip(var_3_0.x, var_3_0.y) then
					return true
				else
					arg_2_0.clickPartner = true

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("GUIDE_SKIP_TIP"), function()
						if arg_2_0.nowFuncID and arg_2_0.nowFuncID ~= 0 then
							local var_4_0 = {
								guide_function_id = arg_2_0.nowFuncID
							}

							arg_2_0.selfPlayer:setPlayerGuideFunction(var_4_0)
						end

						xyd.WindowManager.get():closeWindow(arg_2_0)
					end, nil, nil, arg_2_0.colorMode)
				end
			end

			return true
		elseif var_2_0 == 1 then
			arg_2_0:setTouchSwallowEnabled(true)

			arg_2_0.notTouchInContent = false

			if arg_2_0:isTouchInContent(var_3_0.x, var_3_0.y) then
				return false
			else
				arg_2_0.notTouchInContent = true
			end

			if arg_2_0.addSkip and arg_2_0.skipNode and not tolua.isnull(arg_2_0.skipNode) then
				arg_2_0.clickPartner = false

				if not arg_2_0:isTouchSkip(var_3_0.x, var_3_0.y) and arg_2_0.notTouchInContent then
					if xyd.WindowManager.get():getWindow("toast") ~= nil then
						xyd.WindowManager.get():closeWindow("toast")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("GUIDE_TIPS")
					})

					return true
				else
					arg_2_0.clickPartner = true

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("GUIDE_SKIP_TIP"), function()
						if arg_2_0.nowFuncID and arg_2_0.nowFuncID ~= 0 then
							local var_5_0 = {
								guide_function_id = arg_2_0.nowFuncID
							}

							arg_2_0.selfPlayer:setPlayerGuideFunction(var_5_0)
						end

						xyd.WindowManager.get():closeWindow(arg_2_0)
					end, nil, nil, arg_2_0.colorMode)
				end
			elseif not arg_2_0:isTouchInContent(var_3_0.x, var_3_0.y) then
				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("GUIDE_TIPS")
				})

				return true
			end

			return true
		elseif var_2_0 == 2 then
			arg_2_0:setTouchSwallowEnabled(true)

			if arg_2_0.addSkip and arg_2_0.skipNode and not tolua.isnull(arg_2_0.skipNode) then
				arg_2_0.clickPartner = false

				if not arg_2_0:isTouchSkip(var_3_0.x, var_3_0.y) then
					return true
				else
					arg_2_0.clickPartner = true

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("GUIDE_SKIP_TIP"), function()
						if arg_2_0.nowFuncID and arg_2_0.nowFuncID ~= 0 then
							local var_6_0 = {
								guide_function_id = arg_2_0.nowFuncID
							}

							arg_2_0.selfPlayer:setPlayerGuideFunction(var_6_0)
						end

						xyd.WindowManager.get():closeWindow(arg_2_0)
					end, nil, nil, arg_2_0.colorMode)
				end
			end

			return true
		elseif var_2_0 == 4 then
			arg_2_0:setTouchSwallowEnabled(false)
			arg_2_0:touchEnded()

			return false
		end
	end

	local function var_2_6(arg_7_0, arg_7_1)
		if not arg_2_0.clickPartner and var_2_0 ~= 1 then
			arg_2_0:touchEnded()
		end
	end

	var_2_4:registerScriptHandler(var_2_5, cc.Handler.EVENT_TOUCH_BEGAN)
	var_2_4:registerScriptHandler(var_2_6, cc.Handler.EVENT_TOUCH_ENDED)
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(var_2_4, arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_8_0)
	arg_8_0.arrow_ = arg_8_0:nodeByName("arrow")
	arg_8_0.arrow1_ = arg_8_0:nodeByName("arrow1")

	arg_8_0.arrow_:setVisible(false)
	arg_8_0.arrow1_:setVisible(false)

	arg_8_0.content_ = arg_8_0:nodeByName("container")

	arg_8_0:addNewGuide()
end

function var_0_0.touchEnded(arg_9_0)
	local var_9_0 = var_0_2:returnId(arg_9_0.nowGuideID)

	if var_9_0 and var_9_0 ~= 0 then
		local var_9_1 = {
			guide_return_id = var_9_0
		}

		arg_9_0.selfPlayer:setPlayerReturnID(var_9_1)
	end

	if not arg_9_0.nextGuideID or arg_9_0.nextGuideID == 0 then
		if arg_9_0.nowFuncID and arg_9_0.nowFuncID ~= 0 then
			local var_9_2 = {
				guide_function_id = arg_9_0.nowFuncID
			}

			arg_9_0.selfPlayer:setPlayerGuideFunction(var_9_2)
		end

		xyd.WindowManager.get():closeWindow(arg_9_0)
	else
		arg_9_0:goToNextGuide()
	end
end

function var_0_0.getBtnClick(arg_10_0, arg_10_1)
	local var_10_0 = var_0_2:btnName(arg_10_0.nowGuideID)

	if not arg_10_0.nextGuideID or arg_10_0.nextGuideID == 0 then
		arg_10_0.nextGuideID = var_0_2:nextId(arg_10_0.nowGuideID)
	end

	if arg_10_1 then
		if arg_10_1 == var_10_0 then
			arg_10_0.btnClick = true
		else
			arg_10_0.btnClick = false
		end
	else
		arg_10_0.btnClick = false
	end
end

function var_0_0.goToNextGuide(arg_11_0, arg_11_1)
	local var_11_0 = var_0_2:btnName(arg_11_0.nowGuideID)

	if not arg_11_0.nextGuideID or arg_11_0.nextGuideID == 0 then
		arg_11_0.nextGuideID = var_0_2:nextId(arg_11_0.nowGuideID)
	end

	if arg_11_1 then
		if arg_11_1 == var_11_0 then
			xyd.goNextGuideNewWnd(arg_11_0.nextGuideID, arg_11_0.nowFuncID)
		else
			xyd.WindowManager.get():closeWindow(arg_11_0)
		end
	elseif not arg_11_0.nextGuideID or arg_11_0.nextGuideID == 0 then
		xyd.WindowManager.get():closeWindow(arg_11_0)
	elseif var_0_2:pageName(arg_11_0.nowGuideID) ~= var_0_2:pageName(arg_11_0.nextGuideID) and var_0_2:type(arg_11_0.nowGuideID) ~= 1 then
		xyd.WindowManager.get():closeWindow(arg_11_0)
	else
		xyd.goNextGuideNewWnd(arg_11_0.nextGuideID, arg_11_0.nowFuncID)
	end
end

function var_0_0.isTouchSkip(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = cc.Director:getInstance():getVisibleSize()
	local var_12_1 = (var_12_0.width - xyd.STAGE_WIDTH) / 2
	local var_12_2 = (var_12_0.height - xyd.STAGE_HEIGHT) / 2

	arg_12_1 = arg_12_1 - var_12_1
	arg_12_2 = arg_12_2 - var_12_2

	local var_12_3, var_12_4 = arg_12_0.skipNode:getPosition()
	local var_12_5 = var_12_3 - 100
	local var_12_6 = var_12_3 + 60
	local var_12_7 = var_12_4 + 280
	local var_12_8 = var_12_4

	if arg_12_1 < var_12_6 and var_12_5 < arg_12_1 and var_12_8 < arg_12_2 and arg_12_2 < var_12_7 then
		return true
	end

	return false
end

function var_0_0.addNode(arg_13_0)
	arg_13_0:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(arg_14_0)
		if not arg_13_0:isTouchInContent(arg_14_0.x, arg_14_0.y) then
			return true
		end
	end)
end

function var_0_0.isTouchInContent(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = cc.Director:getInstance():getVisibleSize()
	local var_15_1 = (var_15_0.width - xyd.STAGE_WIDTH) / 2
	local var_15_2 = (var_15_0.height - xyd.STAGE_HEIGHT) / 2

	arg_15_1 = arg_15_1 - var_15_1
	arg_15_2 = arg_15_2 - var_15_2

	local var_15_3 = arg_15_0.content_:getPositionX() - arg_15_0.content_:getContentSize().width / 2
	local var_15_4 = arg_15_0.content_:getPositionX() + arg_15_0.content_:getContentSize().width / 2
	local var_15_5 = arg_15_0.content_:getPositionY() + arg_15_0.content_:getContentSize().height / 2
	local var_15_6 = arg_15_0.content_:getPositionY() - arg_15_0.content_:getContentSize().height / 2

	if arg_15_1 < var_15_4 and var_15_3 < arg_15_1 and var_15_6 < arg_15_2 and arg_15_2 < var_15_5 then
		return true
	end

	if arg_15_0.canSwallow then
		return true
	end

	return false
end

function var_0_0.arrowAnimation(arg_16_0, arg_16_1)
	if arg_16_0.scale_ then
		if arg_16_1 == 0 or arg_16_1 == 1 then
			local var_16_0 = cc.p(0, 20)
			local var_16_1 = cc.MoveBy:create(0.5, var_16_0)

			arg_16_0.arrow_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_16_1, var_16_1:reverse(), nil)))
		elseif arg_16_1 == 2 or arg_16_1 == 3 then
			local var_16_2 = cc.p(-20, 0)
			local var_16_3 = cc.MoveBy:create(0.5, var_16_2)

			arg_16_0.arrow1_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_16_3, var_16_3:reverse(), nil)))
		end
	end
end

function var_0_0.addNewGuide(arg_17_0)
	local var_17_0 = arg_17_0.nowGuideID
	local var_17_1 = var_0_2:desc(var_17_0)
	local var_17_2 = var_0_2:picType(var_17_0)
	local var_17_3 = var_0_2:picSize(var_17_0)
	local var_17_4 = var_0_2:picScale(var_17_0)
	local var_17_5 = var_0_2:picPosition(var_17_0)
	local var_17_6 = var_0_2:handPosition(var_17_0)
	local var_17_7 = var_0_2:handType(var_17_0)
	local var_17_8 = var_0_2:handPosition(var_17_0)
	local var_17_9 = var_0_2:isLvmeng(var_17_0)
	local var_17_10 = var_0_2:lvmengDirection(var_17_0)
	local var_17_11 = var_0_2:lvmengPosition(var_17_0)
	local var_17_12 = var_0_2:dialoguePosition(var_17_0)
	local var_17_13 = var_0_2:dialogueType(var_17_0)
	local var_17_14 = var_0_2:dialogueDirection(var_17_0)
	local var_17_15 = var_0_2:pageName(var_17_0)
	local var_17_16 = var_17_3[1]
	local var_17_17 = var_17_3[2]
	local var_17_18 = var_17_5[1]
	local var_17_19 = var_17_5[2]
	local var_17_20 = 4
	local var_17_21 = var_17_7 == 3 and 0 or var_17_7 == 2 and 1 or var_17_7 == 5 and 2 or var_17_7 == 4 and 3 or 4
	local var_17_22 = var_0_2:type(arg_17_0.nowGuideID)

	dump(var_17_22)

	if var_17_2 == 7 or var_17_2 == 8 or var_17_2 == 9 or var_17_2 == 10 then
		local var_17_23 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip1.png")

		if var_17_2 == 8 or var_17_2 == 10 then
			var_17_23 = xyd.AssetLoader:get():loadSprite("windows/guide_window/main_clip.png")
		end

		local var_17_24 = var_17_23:getContentSize()

		var_17_23:setScale(var_17_16 / var_17_24.width, var_17_17 / var_17_24.height)
		var_17_23:setAnchorPoint(0.5, 0.5)
		var_17_23:setPosition(var_17_18, var_17_19)

		local var_17_25 = cc.ClippingNode:create()

		var_17_25:setStencil(var_17_23)
		var_17_25:setInverted(true)
		var_17_25:setAlphaThreshold(0.5)
		var_17_25:addTo(arg_17_0, -1)

		arg_17_0.layer = display.newColorLayer(cc.c4b(0, 0, 0, 150))

		arg_17_0.layer:addTo(var_17_25)
		arg_17_0.layer:setPosition(0, 0)
		arg_17_0.layer:setContentSize(1280, 720)
	end

	if var_17_1 then
		if arg_17_0.tipWindow then
			arg_17_0.tipWindow:setVisible(true)
		else
			arg_17_0.tipWindow = import("app.common.ui.BaseWindow"):new()

			arg_17_0.tipWindow:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_tip_new.csb"))
			arg_17_0.tipWindow:addTo(arg_17_0)

			if var_17_9 ~= 0 then
				local var_17_26 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip1.png")

				var_17_26:setAnchorPoint(0.5, 1)
				var_17_26:setPosition(0, -120)

				local var_17_27 = cc.ClippingNode:create()

				var_17_27:setStencil(var_17_26)
				var_17_27:setInverted(true)
				var_17_27:setAlphaThreshold(0)
				arg_17_0.tipWindow:nodeByName("card_pos"):addChild(var_17_27)
				arg_17_0.tipWindow:nodeByName("lvmeng_container"):setPosition(cc.p(var_17_11[1], var_17_11[2] - 150))

				local var_17_28 = xyd.tables.skinDynamic:path(var_0_3)
				local var_17_29 = xyd.tables.misc:getValue("guide_scailing")
				local var_17_30 = xyd.tables.misc:getValue("guide_location")

				xyd.EffectLoader.new(var_17_28, 5, var_17_29, {
					x = var_17_30[1],
					y = var_17_30[2]
				}):addTo(var_17_27)

				if var_17_10 == 1 then
					arg_17_0.tipWindow:nodeByName("lvmeng_container"):setFlippedX(true)
					arg_17_0.tipWindow:nodeByName("tip_word"):setFlippedX(true)
				elseif var_17_10 == 2 then
					arg_17_0.tipWindow:nodeByName("lvmeng_container"):setFlippedX(false)
					arg_17_0.tipWindow:nodeByName("tip_word"):setFlippedX(false)
				end
			end

			if var_17_9 == 2 then
				arg_17_0.tipWindow:nodeByName("not_tip_bg"):setVisible(true)
				arg_17_0.tipWindow:nodeByName("tip_word"):setVisible(true)

				arg_17_0.skipNode = arg_17_0.tipWindow:nodeByName("lvmeng_container")
				arg_17_0.addSkip = true
			else
				arg_17_0.tipWindow:nodeByName("not_tip_bg"):setVisible(false)
				arg_17_0.tipWindow:nodeByName("tip_word"):setVisible(false)
			end
		end

		if var_17_13 == 0 then
			arg_17_0.tipWindow:nodeByName("talk_container"):setVisible(false)
		elseif var_17_13 == 1 then
			arg_17_0.tipWindow:nodeByName("talk_bg1"):setVisible(true)
		elseif var_17_13 == 2 then
			arg_17_0.tipWindow:nodeByName("talk_bg2"):setVisible(true)
		elseif var_17_13 == 3 then
			arg_17_0.tipWindow:nodeByName("talk_bg3"):setVisible(true)
		end

		arg_17_0.tipWindow:setAnchorPoint(0, 0)
		arg_17_0.tipWindow:setPosition(cc.p(0, 0))
		arg_17_0.tipWindow:nodeByName("tip_txt"):setString(var_17_1)
		arg_17_0.tipWindow:nodeByName("talk_container"):setPosition(cc.p(var_17_12[1], var_17_12[2] - 80))

		if var_17_14 == 1 then
			arg_17_0.tipWindow:nodeByName("triangle_up"):setVisible(true)
		elseif var_17_14 == 2 then
			arg_17_0.tipWindow:nodeByName("triangle_down"):setVisible(true)
		elseif var_17_14 == 3 then
			arg_17_0.tipWindow:nodeByName("triangle_left"):setVisible(true)
		elseif var_17_14 == 4 then
			arg_17_0.tipWindow:nodeByName("triangle_right"):setVisible(true)
		end
	elseif arg_17_0.tipWindow then
		arg_17_0.tipWindow:setVisible(false)
	end

	arg_17_0.scale_ = true

	arg_17_0.content_:setContentSize(var_17_16, var_17_17)
	arg_17_0.content_:setPosition(cc.p(var_17_18, var_17_19))

	if var_17_15 == "main" then
		local var_17_31 = xyd.AssetLoader:get():loadSprite("windows/guide_window/main_clip.png")
		local var_17_32 = var_17_31:getContentSize()

		var_17_31:setScale(var_17_16 / var_17_32.width, var_17_17 / var_17_32.height)
		var_17_31:setAnchorPoint(0.5, 0.5)
		var_17_31:setPosition(var_17_18, var_17_19)

		local var_17_33 = cc.ClippingNode:create()

		var_17_33:setStencil(var_17_31)
		var_17_33:setInverted(true)
		var_17_33:setAlphaThreshold(0.5)
		var_17_33:addTo(arg_17_0, -1)

		arg_17_0.layer = display.newColorLayer(cc.c4b(0, 0, 0, 150))

		arg_17_0.layer:addTo(var_17_33)
		arg_17_0.layer:setPosition(0, 0)
		arg_17_0.layer:setContentSize(1280, 720)

		local var_17_34 = xyd.createEffect("skeletons/ui_effect/guide/guide_click")

		var_17_34:play(nil, true)
		var_17_34:addTo(arg_17_0)
		var_17_34:setPosition(var_17_18, var_17_19)
		var_17_34:setRotation(var_17_21)

		if var_17_18 and var_17_19 then
			var_17_34:runAction(cc.MoveBy:create(0, cc.p(var_17_18, var_17_19)))
		end

		return
	end

	if var_17_2 == 2 or var_17_2 == 9 then
		arg_17_0.border = arg_17_0:nodeByName("guide_rect")
	elseif var_17_2 == 5 then
		arg_17_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine1.png")

		arg_17_0.border:addTo(arg_17_0:nodeByName("container"))
		arg_17_0.border:setAnchorPoint(0.5, 0.5)
	elseif var_17_2 == 6 then
		arg_17_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine2.png")

		arg_17_0.border:addTo(arg_17_0:nodeByName("container"))
		arg_17_0.border:setAnchorPoint(0.5, 0.5)
	else
		arg_17_0.border = arg_17_0:nodeByName("guide_circle")
	end

	if var_17_2 ~= 7 and var_17_2 ~= 8 then
		arg_17_0.border:setContentSize(var_17_16, var_17_17)
		arg_17_0.border:setPosition(var_17_16 / 2, var_17_17 / 2)
		arg_17_0.border:setVisible(true)

		local var_17_35 = cc.Sequence:create(cc.CallFunc:create(function()
			arg_17_0.border:setVisible(true)
		end), cc.DelayTime:create(1.18), cc.Spawn:create(cc.ScaleBy:create(0.4166666666666667, 0.5), cc.FadeOut:create(0.4166666666666667)), cc.CallFunc:create(function()
			arg_17_0.border:setVisible(false)
		end))
	end

	local var_17_36 = transition.sequence({
		cc.ScaleTo:create(1, (var_17_16 + 50) / var_17_16, (var_17_17 + 50) / var_17_17),
		cc.EaseSineIn:create(cc.ScaleTo:create(0.8, 1))
	})

	if var_17_2 == 2 or var_17_2 == 9 then
		var_17_36 = transition.sequence({
			cc.ScaleTo:create(var_17_4[1] or 0.8, var_17_4[2] or 1.2),
			cc.EaseSineIn:create(cc.ScaleTo:create(var_17_4[1] or 0.8, 1))
		})
	end

	if var_17_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_END then
		var_17_36 = transition.sequence({
			cc.ScaleTo:create(1.2, (var_17_16 + 50) / var_17_16 * 1.2, (var_17_17 + 50) / var_17_17 * 1.2),
			cc.ScaleTo:create(1.2, 1.2)
		})
	end

	if var_17_2 ~= 7 and var_17_2 ~= 8 then
		local var_17_37 = cc.RepeatForever:create(var_17_36)

		arg_17_0.border:runAction(var_17_37)
	end

	if var_17_21 == 0 then
		arg_17_0.arrow_:setVisible(true)
		arg_17_0.arrow1_:setVisible(false)
		arg_17_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_17_0.arrow_:setPosition(cc.p(var_17_18, var_17_19 + var_17_17 / 2 + 10))
		arg_17_0.arrow_:setFlippedY(false)
	elseif var_17_21 == 1 then
		arg_17_0.arrow_:setVisible(true)
		arg_17_0.arrow1_:setVisible(false)
		arg_17_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_17_0.arrow_:setPosition(cc.p(var_17_18, var_17_19 - var_17_17 / 2 - 10))
		arg_17_0.arrow_:setFlippedY(true)
	elseif var_17_21 == 2 then
		arg_17_0.arrow1_:setVisible(true)
		arg_17_0.arrow_:setFlippedY(false)
		arg_17_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_17_0.arrow1_:setPosition(cc.p(var_17_18 - var_17_16 / 2 - 10, var_17_19))
	elseif var_17_21 == 3 then
		arg_17_0.arrow_:setVisible(false)
		arg_17_0.arrow1_:setVisible(true)
		arg_17_0.arrow1_:setFlippedY(true)
		arg_17_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_17_0.arrow1_:setPosition(cc.p(var_17_18 + var_17_16 / 2 + 10, var_17_19))
	else
		arg_17_0.arrow_:setVisible(false)
		arg_17_0.arrow1_:setVisible(false)
	end

	if offsetY then
		arg_17_0.arrow_:setPositionY(arg_17_0.arrow_:getPositionY() + offsetY)
	end

	arg_17_0:arrowAnimation(var_17_21)
end

return var_0_0
