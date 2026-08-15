local var_0_0 = class("GuideWindow", import("app.common.ui.BaseWindow"))
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

	arg_2_0.canSwallow = false

	arg_2_0:setContentSize(3000, 3000)
	dump(xyd.StoryData.get():getGuideID())

	arg_2_0.tipsSchedulerHandlers_ = {}

	local function var_2_0(arg_3_0, arg_3_1)
		if arg_2_0.scale_ == nil then
			return true
		end

		if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SKILL_END or xyd.StoryData.get():getGuideID() > xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START and xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_END then
			xyd.WindowManager.get():closeWindow("guide")
			xyd.StoryData.get():persist()

			return false
		end

		local var_3_0 = cc.Director:getInstance():convertToGL(arg_3_0:getLocationInView())

		if xyd.WindowManager.get():isWindowOpen("alert") and not xyd.WindowManager.get():getWindow("alert").showGuide then
			return false
		end

		if arg_2_0:isTouchInContent(var_3_0.x, var_3_0.y) then
			return false
		else
			if xyd.WindowManager.get():getWindow("toast") ~= nil then
				xyd.WindowManager.get():closeWindow("toast")
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("GUIDE_TIPS")
			})

			return true
		end
	end

	local var_2_1 = cc.EventListenerTouchOneByOne:create()

	var_2_1:setSwallowTouches(true)
	var_2_1:registerScriptHandler(var_2_0, cc.Handler.EVENT_TOUCH_BEGAN)
	cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(var_2_1, arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0.arrow_ = arg_4_0:nodeByName("arrow")
	arg_4_0.arrow1_ = arg_4_0:nodeByName("arrow1")

	arg_4_0.arrow_:setVisible(false)
	arg_4_0.arrow1_:setVisible(false)

	arg_4_0.content_ = arg_4_0:nodeByName("container")
end

function var_0_0.addNode(arg_5_0)
	arg_5_0:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(arg_6_0)
		if not arg_5_0:isTouchInContent(arg_6_0.x, arg_6_0.y) then
			return true
		end
	end)
end

function var_0_0.isTouchInContent(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = cc.Director:getInstance():getVisibleSize()
	local var_7_1 = (var_7_0.width - xyd.STAGE_WIDTH) / 2
	local var_7_2 = (var_7_0.height - xyd.STAGE_HEIGHT) / 2

	arg_7_1 = arg_7_1 - var_7_1
	arg_7_2 = arg_7_2 - var_7_2

	local var_7_3 = arg_7_0.content_:getPositionX() - arg_7_0.content_:getContentSize().width / 2
	local var_7_4 = arg_7_0.content_:getPositionX() + arg_7_0.content_:getContentSize().width / 2
	local var_7_5 = arg_7_0.content_:getPositionY() + arg_7_0.content_:getContentSize().height / 2
	local var_7_6 = arg_7_0.content_:getPositionY() - arg_7_0.content_:getContentSize().height / 2

	if arg_7_1 < var_7_4 and var_7_3 < arg_7_1 and var_7_6 < arg_7_2 and arg_7_2 < var_7_5 then
		return true
	end

	if arg_7_0.canSwallow then
		return true
	end

	return false
end

function var_0_0.setStencil(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0 = xyd.StoryData.get():getGuideID()

	if var_0_2:isHaveId(var_8_0) then
		arg_8_0.isOldGudie = arg_8_0:checkOldGuide(var_8_0)

		if not arg_8_0.isOldGudie then
			arg_8_0:addNewGuide(arg_8_6)

			return
		end
	end

	local var_8_1 = xyd.tables.guide:desc(var_8_0)

	if var_8_1 then
		local var_8_2 = false
		local var_8_3 = {
			600,
			300
		}

		if arg_8_6 then
			var_8_3 = arg_8_6.position or var_8_3
			var_8_2 = arg_8_6.right or var_8_2
		end

		if arg_8_0.isOldGudie then
			local var_8_4 = var_0_2:lvmengPosition(var_8_0)

			var_8_3[1] = var_8_4[1]
			var_8_3[2] = var_8_4[2]
		end

		if var_8_0 == xyd.GuideStoryType.GUIDE_SUMMON_FREE_THREE or var_8_0 == xyd.GuideStoryType.GUIDE_SUMMON_CRYSTAL_THREE then
			var_8_3 = {
				630,
				200
			}
		end

		if arg_8_0.tipWindow then
			arg_8_0.tipWindow:setVisible(true)
		else
			arg_8_0.tipWindow = import("app.common.ui.BaseWindow"):new()

			arg_8_0.tipWindow:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_tip.csb"))
			arg_8_0.tipWindow:addTo(arg_8_0)

			local var_8_5 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip1.png")

			var_8_5:setAnchorPoint(0.5, 1)
			var_8_5:setPosition(0, -120)

			local var_8_6 = cc.ClippingNode:create()

			var_8_6:setStencil(var_8_5)
			var_8_6:setInverted(true)
			var_8_6:setAlphaThreshold(0)
			arg_8_0.tipWindow:nodeByName("card_pos"):addChild(var_8_6)

			local var_8_7 = xyd.tables.skinDynamic:path(var_0_3)
			local var_8_8 = xyd.tables.misc:getValue("guide_scailing")
			local var_8_9 = xyd.tables.misc:getValue("guide_location")

			xyd.EffectLoader.new(var_8_7, 5, var_8_8, {
				x = var_8_9[1],
				y = var_8_9[2]
			}):addTo(var_8_6)

			if var_8_0 > xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL then
				arg_8_0:addSkipNode(arg_8_0.tipWindow:nodeByName("click_node"))
			end
		end

		if var_8_0 > xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL then
			arg_8_0.tipWindow:nodeByName("guide_tip"):setVisible(true)
			arg_8_0.tipWindow:nodeByName("not_tip_bg"):setVisible(true)
		else
			arg_8_0.tipWindow:nodeByName("guide_tip"):setVisible(false)
			arg_8_0.tipWindow:nodeByName("not_tip_bg"):setVisible(false)
		end

		arg_8_0.tipWindow:setPosition(cc.p(var_8_3[1], var_8_3[2]))
		arg_8_0.tipWindow:nodeByName("tip_txt"):setString(var_8_1)

		local var_8_10 = xyd.createMultiLineMultiColorTxt(var_8_1, cc.c3b(187, 93, 41), 20, false)

		var_8_10:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_10:addTo(arg_8_0.tipWindow)
		var_8_10:setPosition(arg_8_0.tipWindow:nodeByName("tip_txt"):getPosition())
		arg_8_0.tipWindow:nodeByName("tip_txt"):setVisible(false)

		if var_8_2 then
			arg_8_0.tipWindow:nodeByName("tip_bg"):setFlippedX(true)
			arg_8_0.tipWindow:nodeByName("guide_tip"):setFlippedX(true)
			arg_8_0.tipWindow:nodeByName("not_tip_bg"):setFlippedX(true)
			var_8_10:setPositionX(var_8_10:getPositionX())
		else
			arg_8_0.tipWindow:nodeByName("tip_bg"):setFlippedX(false)
			arg_8_0.tipWindow:nodeByName("guide_tip"):setFlippedX(false)
			arg_8_0.tipWindow:nodeByName("not_tip_bg"):setFlippedX(false)
			var_8_10:setPositionX(var_8_10:getPositionX())
		end
	elseif arg_8_0.tipWindow then
		arg_8_0.tipWindow:setVisible(false)
	end

	arg_8_0.scale_ = true

	arg_8_0.content_:setContentSize(arg_8_1, arg_8_2)
	arg_8_0.content_:setPosition(cc.p(arg_8_3, arg_8_4))

	if arg_8_6 and arg_8_6.swallow then
		arg_8_0.canSwallow = true
	end

	if arg_8_6 and arg_8_6.main_scene then
		local var_8_11 = xyd.AssetLoader:get():loadSprite("windows/guide_window/main_clip.png")
		local var_8_12 = var_8_11:getContentSize()

		var_8_11:setScale(arg_8_1 / var_8_12.width, arg_8_2 / var_8_12.height)
		var_8_11:setAnchorPoint(0.5, 0.5)
		var_8_11:setPosition(arg_8_3, arg_8_4)

		local var_8_13 = cc.ClippingNode:create()

		var_8_13:setStencil(var_8_11)
		var_8_13:setInverted(true)
		var_8_13:setAlphaThreshold(0.5)
		var_8_13:addTo(arg_8_0, -1)

		arg_8_0.layer = display.newColorLayer(cc.c4b(0, 0, 0, 150))

		arg_8_0.layer:addTo(var_8_13)
		arg_8_0.layer:setPosition(0, 0)
		arg_8_0.layer:setContentSize(1280, 720)

		local var_8_14 = xyd.createEffect("skeletons/ui_effect/guide/guide_click")

		var_8_14:play(nil, true)
		var_8_14:addTo(arg_8_0)
		var_8_14:setPosition(arg_8_3, arg_8_4)
		var_8_14:setRotation(arg_8_5)

		if arg_8_6.effect_pos then
			var_8_14:runAction(cc.MoveBy:create(0, arg_8_6.effect_pos))
		end

		return
	end

	if arg_8_6 and arg_8_6.rect then
		arg_8_0.border = arg_8_0:nodeByName("guide_rect")
	elseif arg_8_6 and arg_8_6.machine1 then
		arg_8_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine1.png")

		arg_8_0.border:addTo(arg_8_0:nodeByName("container"))
		arg_8_0.border:setAnchorPoint(0.5, 0.5)
	elseif arg_8_6 and arg_8_6.machine2 then
		arg_8_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine2.png")

		arg_8_0.border:addTo(arg_8_0:nodeByName("container"))
		arg_8_0.border:setAnchorPoint(0.5, 0.5)
	else
		arg_8_0.border = arg_8_0:nodeByName("guide_circle")
	end

	arg_8_0.border:setContentSize(arg_8_1, arg_8_2)
	arg_8_0.border:setPosition(arg_8_1 / 2, arg_8_2 / 2)
	arg_8_0.border:setVisible(true)

	local var_8_15 = transition.sequence({
		cc.ScaleTo:create(1, (arg_8_1 + 50) / arg_8_1, (arg_8_2 + 50) / arg_8_2),
		cc.EaseSineIn:create(cc.ScaleTo:create(0.8, 1))
	})

	if var_8_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_END then
		var_8_15 = transition.sequence({
			cc.ScaleTo:create(1.2, (arg_8_1 + 50) / arg_8_1 * 1.2, (arg_8_2 + 50) / arg_8_2 * 1.2),
			cc.ScaleTo:create(1.2, 1.2)
		})
	end

	local var_8_16 = cc.RepeatForever:create(var_8_15)

	arg_8_0.border:runAction(var_8_16)

	if arg_8_5 == 0 then
		arg_8_0.arrow_:setVisible(true)
		arg_8_0.arrow1_:setVisible(false)
		arg_8_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow_:setPosition(cc.p(arg_8_3, arg_8_4 + arg_8_2 / 2 + 10))
		arg_8_0.arrow_:setFlippedY(false)
	elseif arg_8_5 == 1 then
		arg_8_0.arrow_:setVisible(true)
		arg_8_0.arrow1_:setVisible(false)
		arg_8_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow_:setPosition(cc.p(arg_8_3, arg_8_4 - arg_8_2 / 2 - 10))
		arg_8_0.arrow_:setFlippedY(true)
	elseif arg_8_5 == 2 then
		arg_8_0.arrow1_:setVisible(true)
		arg_8_0.arrow_:setFlippedY(false)
		arg_8_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow1_:setPosition(cc.p(arg_8_3 - arg_8_1 / 2 - 10, arg_8_4))
	elseif arg_8_5 == 3 then
		arg_8_0.arrow_:setVisible(false)
		arg_8_0.arrow1_:setVisible(true)
		arg_8_0.arrow1_:setFlippedY(true)
		arg_8_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_8_0.arrow1_:setPosition(cc.p(arg_8_3 + arg_8_1 / 2 + 10, arg_8_4))
	end

	if arg_8_7 then
		arg_8_0.arrow_:setPositionY(arg_8_0.arrow_:getPositionY() + arg_8_7)
	end

	arg_8_0:arrowAnimation(arg_8_5)
end

function var_0_0.addSkipNode(arg_9_0, arg_9_1)
	arg_9_1:setTouchEnabled(true)
	arg_9_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			return true
		elseif arg_10_0.name == "ended" then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("GUIDE_SKIP_TIP"), function()
				xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_TREASURE_END)
				xyd.StoryData.get():persist()
				xyd.WindowManager.get():closeWindow(arg_9_0)
			end, nil, nil, arg_9_0.colorMode)
		end
	end)
end

function var_0_0.arrowAnimation(arg_12_0, arg_12_1)
	if arg_12_0.scale_ then
		if arg_12_1 == 0 or arg_12_1 == 1 then
			local var_12_0 = cc.p(0, 20)
			local var_12_1 = cc.MoveBy:create(0.5, var_12_0)

			arg_12_0.arrow_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_12_1, var_12_1:reverse(), nil)))
		elseif arg_12_1 == 2 or arg_12_1 == 3 then
			local var_12_2 = cc.p(-20, 0)
			local var_12_3 = cc.MoveBy:create(0.5, var_12_2)

			arg_12_0.arrow1_:runAction(cc.RepeatForever:create(cc.Sequence:create(var_12_3, var_12_3:reverse(), nil)))
		end
	end
end

function var_0_0.checkOldGuide(arg_13_0, arg_13_1)
	local var_13_0 = var_0_2:type(arg_13_1)

	dump(arg_13_1)
	dump(var_13_0)

	if var_13_0 == 5 then
		return true
	else
		return false
	end
end

function var_0_0.addNewGuide(arg_14_0, arg_14_1)
	local var_14_0 = xyd.StoryData.get():getGuideID()

	if arg_14_1 and arg_14_1.main_scene then
		var_14_0 = var_0_2:nextId(var_14_0)
	end

	local var_14_1 = var_0_2:desc(var_14_0)
	local var_14_2 = var_0_2:type(var_14_0)
	local var_14_3 = var_0_2:picType(var_14_0)
	local var_14_4 = var_0_2:picSize(var_14_0)
	local var_14_5 = var_0_2:picPosition(var_14_0)
	local var_14_6 = var_0_2:handPosition(var_14_0)
	local var_14_7 = var_0_2:handType(var_14_0)
	local var_14_8 = var_0_2:handPosition(var_14_0)
	local var_14_9 = var_0_2:isLvmeng(var_14_0)
	local var_14_10 = var_0_2:lvmengDirection(var_14_0)
	local var_14_11 = var_0_2:lvmengPosition(var_14_0)
	local var_14_12 = var_0_2:dialoguePosition(var_14_0)
	local var_14_13 = var_0_2:dialogueType(var_14_0)
	local var_14_14 = var_0_2:dialogueDirection(var_14_0)
	local var_14_15 = var_14_4[1]
	local var_14_16 = var_14_4[2]
	local var_14_17 = var_14_5[1]
	local var_14_18 = var_14_5[2]
	local var_14_19 = 4
	local var_14_20 = var_14_7 == 3 and 0 or var_14_7 == 2 and 1 or var_14_7 == 5 and 2 or var_14_7 == 4 and 3 or 4

	if var_14_1 then
		if arg_14_0.tipWindow then
			arg_14_0.tipWindow:setVisible(true)
		else
			arg_14_0.tipWindow = import("app.common.ui.BaseWindow"):new()

			arg_14_0.tipWindow:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guide_window/guide_tip_new.csb"))
			arg_14_0.tipWindow:addTo(arg_14_0)

			if var_14_9 ~= 0 then
				local var_14_21 = xyd.AssetLoader:get():loadSprite("windows/guide_window/guide_clip1.png")

				var_14_21:setAnchorPoint(0.5, 1)
				var_14_21:setPosition(0, -120)

				local var_14_22 = cc.ClippingNode:create()

				var_14_22:setStencil(var_14_21)
				var_14_22:setInverted(true)
				var_14_22:setAlphaThreshold(0)
				arg_14_0.tipWindow:nodeByName("card_pos"):addChild(var_14_22)
				arg_14_0.tipWindow:nodeByName("lvmeng_container"):setPosition(cc.p(var_14_11[1], var_14_11[2] - 150))

				local var_14_23 = xyd.tables.skinDynamic:path(var_0_3)
				local var_14_24 = xyd.tables.misc:getValue("guide_scailing")
				local var_14_25 = xyd.tables.misc:getValue("guide_location")

				xyd.EffectLoader.new(var_14_23, 5, var_14_24, {
					x = var_14_25[1],
					y = var_14_25[2]
				}):addTo(var_14_22)

				if var_14_10 == 1 then
					arg_14_0.tipWindow:nodeByName("lvmeng_container"):setFlippedX(true)
					arg_14_0.tipWindow:nodeByName("tip_word"):setFlippedX(true)
				elseif var_14_10 == 2 then
					arg_14_0.tipWindow:nodeByName("lvmeng_container"):setFlippedX(false)
					arg_14_0.tipWindow:nodeByName("tip_word"):setFlippedX(false)
				end
			end

			if var_14_9 == 2 then
				arg_14_0.tipWindow:nodeByName("not_tip_bg"):setVisible(true)
				arg_14_0.tipWindow:nodeByName("tip_word"):setVisible(true)
				arg_14_0:addSkipNode(arg_14_0.tipWindow:nodeByName("click_node"))
			else
				arg_14_0.tipWindow:nodeByName("not_tip_bg"):setVisible(false)
				arg_14_0.tipWindow:nodeByName("tip_word"):setVisible(false)
			end
		end

		if var_14_13 == 0 then
			arg_14_0.tipWindow:nodeByName("talk_container"):setVisible(false)
		elseif var_14_13 == 1 then
			arg_14_0.tipWindow:nodeByName("talk_bg1"):setVisible(true)
		elseif var_14_13 == 2 then
			arg_14_0.tipWindow:nodeByName("talk_bg2"):setVisible(true)
		elseif var_14_13 == 3 then
			arg_14_0.tipWindow:nodeByName("talk_bg3"):setVisible(true)
		end

		arg_14_0.tipWindow:setAnchorPoint(0, 0)
		arg_14_0.tipWindow:setPosition(cc.p(0, 0))
		arg_14_0.tipWindow:nodeByName("tip_txt"):setString(var_14_1)
		arg_14_0.tipWindow:nodeByName("talk_container"):setPosition(cc.p(var_14_12[1], var_14_12[2] - 80))

		if var_14_14 == 1 then
			arg_14_0.tipWindow:nodeByName("triangle_up"):setVisible(true)
		elseif var_14_14 == 2 then
			arg_14_0.tipWindow:nodeByName("triangle_down"):setVisible(true)
		elseif var_14_14 == 3 then
			arg_14_0.tipWindow:nodeByName("triangle_left"):setVisible(true)
		elseif var_14_14 == 4 then
			arg_14_0.tipWindow:nodeByName("triangle_right"):setVisible(true)
		end
	elseif arg_14_0.tipWindow then
		arg_14_0.tipWindow:setVisible(false)
	end

	arg_14_0.scale_ = true

	arg_14_0.content_:setContentSize(var_14_15, var_14_16)
	arg_14_0.content_:setPosition(cc.p(var_14_17, var_14_18))
	dump(var_14_15 .. " " .. var_14_16 .. " " .. var_14_17 .. " " .. var_14_18)

	if arg_14_1 and arg_14_1.swallow then
		arg_14_0.canSwallow = true
	end

	if arg_14_1 and arg_14_1.main_scene then
		local var_14_26 = xyd.AssetLoader:get():loadSprite("windows/guide_window/main_clip.png")
		local var_14_27 = var_14_26:getContentSize()

		var_14_26:setScale(var_14_15 / var_14_27.width, var_14_16 / var_14_27.height)
		var_14_26:setAnchorPoint(0.5, 0.5)
		dump(var_14_17)
		dump(var_14_18)
		var_14_26:setPosition(var_14_17, var_14_18)

		local var_14_28 = cc.ClippingNode:create()

		var_14_28:setStencil(var_14_26)
		var_14_28:setInverted(true)
		var_14_28:setAlphaThreshold(0.5)
		var_14_28:addTo(arg_14_0, -1)

		arg_14_0.layer = display.newColorLayer(cc.c4b(0, 0, 0, 150))

		arg_14_0.layer:addTo(var_14_28)
		arg_14_0.layer:setPosition(0, 0)
		arg_14_0.layer:setContentSize(1280, 720)

		local var_14_29 = xyd.createEffect("skeletons/ui_effect/guide/guide_click")

		var_14_29:play(nil, true)
		var_14_29:addTo(arg_14_0)
		var_14_29:setPosition(var_14_17, var_14_18)
		var_14_29:setRotation(var_14_20)

		if arg_14_1.effect_pos then
			var_14_29:runAction(cc.MoveBy:create(0, arg_14_1.effect_pos))
		end

		return
	end

	if var_14_3 == 2 then
		arg_14_0.border = arg_14_0:nodeByName("guide_rect")
	elseif var_14_3 == 5 then
		arg_14_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine1.png")

		arg_14_0.border:addTo(arg_14_0:nodeByName("container"))
		arg_14_0.border:setAnchorPoint(0.5, 0.5)
	elseif var_14_3 == 6 then
		arg_14_0.border = xyd.AssetLoader.get():loadSprite("windows/guide_window/machine2.png")

		arg_14_0.border:addTo(arg_14_0:nodeByName("container"))
		arg_14_0.border:setAnchorPoint(0.5, 0.5)
	else
		arg_14_0.border = arg_14_0:nodeByName("guide_circle")
	end

	arg_14_0.border:setContentSize(var_14_15, var_14_16)
	arg_14_0.border:setPosition(var_14_15 / 2, var_14_16 / 2)
	arg_14_0.border:setVisible(true)

	local var_14_30 = cc.Sequence:create(cc.CallFunc:create(function()
		arg_14_0.border:setVisible(true)
	end), cc.DelayTime:create(1.18), cc.Spawn:create(cc.ScaleBy:create(0.4166666666666667, 0.5), cc.FadeOut:create(0.4166666666666667)), cc.CallFunc:create(function()
		arg_14_0.border:setVisible(false)
	end))
	local var_14_31 = transition.sequence({
		cc.ScaleTo:create(1, (var_14_15 + 50) / var_14_15, (var_14_16 + 50) / var_14_16),
		cc.EaseSineIn:create(cc.ScaleTo:create(0.8, 1))
	})

	if var_14_3 == 2 then
		var_14_31 = transition.sequence({
			cc.ScaleTo:create(0.8, 1.2),
			cc.EaseSineIn:create(cc.ScaleTo:create(0.8, 1))
		})
	end

	if var_14_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_END then
		var_14_31 = transition.sequence({
			cc.ScaleTo:create(1.2, (var_14_15 + 50) / var_14_15 * 1.2, (var_14_16 + 50) / var_14_16 * 1.2),
			cc.ScaleTo:create(1.2, 1.2)
		})
	end

	local var_14_32 = cc.RepeatForever:create(var_14_31)

	arg_14_0.border:runAction(var_14_32)

	if var_14_20 == 0 then
		arg_14_0.arrow_:setVisible(true)
		arg_14_0.arrow1_:setVisible(false)
		arg_14_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_14_0.arrow_:setPosition(cc.p(var_14_17, var_14_18 + var_14_16 / 2 + 10))
		arg_14_0.arrow_:setFlippedY(false)
	elseif var_14_20 == 1 then
		arg_14_0.arrow_:setVisible(true)
		arg_14_0.arrow1_:setVisible(false)
		arg_14_0.arrow_:setAnchorPoint(cc.p(0.5, 0))
		arg_14_0.arrow_:setPosition(cc.p(var_14_17, var_14_18 - var_14_16 / 2 - 10))
		arg_14_0.arrow_:setFlippedY(true)
	elseif var_14_20 == 2 then
		arg_14_0.arrow1_:setVisible(true)
		arg_14_0.arrow_:setFlippedY(false)
		arg_14_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_14_0.arrow1_:setPosition(cc.p(var_14_17 - var_14_15 / 2 - 10, var_14_18))
	elseif var_14_20 == 3 then
		arg_14_0.arrow_:setVisible(false)
		arg_14_0.arrow1_:setVisible(true)
		arg_14_0.arrow1_:setFlippedY(true)
		arg_14_0.arrow1_:setAnchorPoint(cc.p(0.5, 0))
		arg_14_0.arrow1_:setPosition(cc.p(var_14_17 + var_14_15 / 2 + 10, var_14_18))
	else
		arg_14_0.arrow_:setVisible(false)
		arg_14_0.arrow1_:setVisible(false)
	end

	if offsetY then
		arg_14_0.arrow_:setPositionY(arg_14_0.arrow_:getPositionY() + offsetY)
	end

	arg_14_0:arrowAnimation(var_14_20)
end

function var_0_0.didClose(arg_17_0)
	var_0_0.super.didClose(arg_17_0, params)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.GUIDE_WINODW_CLOSE
	})
end

return var_0_0
