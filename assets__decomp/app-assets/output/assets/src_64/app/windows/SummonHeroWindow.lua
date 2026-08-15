local var_0_0 = class("SummonHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = "skeletons/ui_effect/summon_hero/summon_bg"
local var_0_5 = "skeletons/ui_effect/summon_hero/summon_refresh"
local var_0_6 = "skeletons/ui_effect/summon_hero/summon_light"
local var_0_7 = "skeletons/ui_effect/summon_hero/summon_silhouette"
local var_0_8 = "skeletons/ui_effect/summon_hero/summon_star"
local var_0_9 = "skeletons/ui_effect/summon_hero/summon_new"
local var_0_10 = "windows/summon/circle.png"
local var_0_11 = "windows/summon/shadow.png"
local var_0_12 = 75
local var_0_13 = -20
local var_0_14 = 1087.5
local var_0_15 = 606.5
local var_0_16 = 20
local var_0_17 = require("framework.scheduler")
local var_0_18 = {
	{
		150,
		225,
		114
	},
	{
		115,
		199,
		255
	},
	{
		253,
		172,
		77
	}
}
local var_0_19 = {
	{
		36,
		94,
		24
	},
	{
		6,
		25,
		121
	},
	{
		121,
		6,
		6
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	local var_1_0 = arg_1_2.partnerID

	arg_1_0.isPet = arg_1_2.isPet

	if arg_1_0.isPet then
		arg_1_0.hero_ = var_0_2.new()

		arg_1_0.hero_:initUnCollected(var_1_0)
	else
		arg_1_0.hero_ = var_0_1.new()

		arg_1_0.hero_:populateWithTableID(var_1_0)
	end

	if arg_1_2.hero then
		arg_1_0.hero_ = arg_1_2.hero
	end

	arg_1_0.star = arg_1_2.star
	arg_1_0.toStone_ = arg_1_2.toStone
	arg_1_0.itemIndex = arg_1_2.item_index
	arg_1_0.isGuide = arg_1_2.isGuide
	arg_1_0.isStillGuide = arg_1_2.isStillGuide
	arg_1_0.canSkip = arg_1_2.can_skip
	arg_1_0.playSound_ = false
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.params = arg_2_1

	arg_2_0:layout()

	if not arg_2_0.isGuide then
		local var_2_0 = xyd.WindowManager.get():getWindow("summon_result")

		if var_2_0 then
			var_2_0:setVisible(false)
		end
	end

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	arg_2_0:addBlockLayerWithNoTouchEvent(cc.c4b(0, 0, 0, 0))
end

function var_0_0.didClose(arg_3_0)
	if arg_3_0.handler then
		var_0_17.unscheduleGlobal(arg_3_0.handler)

		arg_3_0.handler = nil
	end

	if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_LEVUP_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_ONE)

		local var_3_0 = xyd.WindowManager.get():getWindow("hero_list")

		if var_3_0 then
			var_3_0:playGuide()
		end
	end
end

function var_0_0.getSkipBtn(arg_4_0)
	if not arg_4_0.skipBtn_ then
		arg_4_0.skipBtn_ = arg_4_0:nodeByName("skip")
	end

	if arg_4_0.toStone_ then
		arg_4_0.skipBtn_:setVisible(true)
	else
		arg_4_0.skipBtn_:setVisible(false)
	end

	xyd.nodeEventSample(arg_4_0.skipBtn_, nil, function(arg_5_0)
		xyd.playButtonSound()

		arg_4_0.isSkipAnimation = true

		xyd.WindowManager.get():closeWindow(arg_4_0)
	end)
	arg_4_0.skipBtn_:setLocalZOrder(1000)

	return arg_4_0.skipBtn_
end

function var_0_0.willClose(arg_6_0)
	if not arg_6_0.isGuide then
		arg_6_0:dispatchEvent({
			name = xyd.event.SUMMON_HERO_CLOSE,
			item_index = arg_6_0.itemIndex or 0,
			is_skip_animation = arg_6_0.isSkipAnimation
		})

		local var_6_0 = xyd.WindowManager.get():getWindow("summon_result")

		if var_6_0 then
			var_6_0:setVisible(true)
		end
	else
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUMMON_START)
		xyd.StoryData.get():persist()

		if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SUMMON_START then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.PLAY_GUIDE,
				params = {
					guide_id = xyd.GuideStoryType.GUIDE_SUMMON_START
				}
			})
		end
	end

	if arg_6_0.isGuide or arg_6_0.isStillGuide then
		if arg_6_0.params.partnerID == 10001001 then
			arg_6_0.player:sendOperationLog(xyd.StatID.ID_GET_HERO1)
		elseif arg_6_0.params.partnerID == 10001002 then
			arg_6_0.player:sendOperationLog(xyd.StatID.ID_GET_HERO2)
		elseif arg_6_0.params.partnerID == 10001003 then
			arg_6_0.player:sendOperationLog(xyd.StatID.ID_GET_HERO3)
		end
	end
end

function var_0_0.layout(arg_7_0)
	local var_7_0 = xyd.WindowManager.get():getWindow("summon")

	if var_7_0 then
		var_7_0:hideTalkContainer()
	end

	arg_7_0.player:stopHeroSound()
	arg_7_0:nodeByName("has"):setVisible(false)
	arg_7_0:nodeByName("talk"):setVisible(false)

	arg_7_0.star = arg_7_0.star or arg_7_0.hero_:getStar()
	arg_7_0.limitedStar = arg_7_0.star > 3 and 3 or arg_7_0.star
	arg_7_0.starEffects = {}
	arg_7_0.frameAction = {}

	if arg_7_0.toStone_ then
		arg_7_0:nodeByName("desc"):setString(xyd.tables.translation:translation("SUMMON_HERO_TO_STONE"))
		arg_7_0:nodeByName("desc"):enableOutline(cc.c4b(54, 54, 54, 255), 2)
		arg_7_0:nodeByName("num"):setString("x" .. arg_7_0.toStone_)
		arg_7_0:nodeByName("num"):enableOutline(cc.c4b(54, 54, 54, 255), 2)
		xyd.setItemBorder(arg_7_0:nodeByName("item"), arg_7_0.hero_:getSuiPianID())
		arg_7_0:nodeByName("has_bg" .. arg_7_0.limitedStar):setVisible(true)
	end

	arg_7_0:nodeByName("hero_name"):setString(arg_7_0.hero_:getName())
	arg_7_0:nodeByName("content"):setString(xyd.tables.hero:dialog(arg_7_0.hero_:getTableID()))
	arg_7_0:nodeByName("cv"):setString("CV:" .. xyd.tables.hero:getCV(arg_7_0.hero_:getTableID()))
	arg_7_0:nodeByName("bg" .. arg_7_0.limitedStar):setVisible(true)

	arg_7_0.bgEffect = xyd.createEffect(var_0_4 .. arg_7_0.limitedStar)

	arg_7_0.bgEffect:addTo(arg_7_0:nodeByName("down_layer"))
	arg_7_0.bgEffect:setLocalZOrder(-2)
	arg_7_0.bgEffect:setPosition(640, 360)
	arg_7_0.bgEffect:play()

	arg_7_0.refreshEffect = xyd.createEffect(var_0_5)

	arg_7_0.refreshEffect:addTo(arg_7_0:nodeByName("up_layer"))
	arg_7_0.refreshEffect:setLocalZOrder(20)
	arg_7_0.refreshEffect:setPosition(640, 360)
	arg_7_0.refreshEffect:play()

	if arg_7_0.toStone_ then
		arg_7_0.frameAction[80] = arg_7_0.showHasContainer
	else
		arg_7_0.newEffect = xyd.createEffect(var_0_9)

		arg_7_0.newEffect:addTo(arg_7_0:nodeByName("up_layer"))
		arg_7_0.newEffect:setLocalZOrder(15)
		arg_7_0.newEffect:setPosition(232, 593.5)
		arg_7_0.newEffect:play()
	end

	arg_7_0.npcEffect = xyd.createEffect(var_0_7)

	arg_7_0.npcEffect:addTo(arg_7_0:nodeByName("down_layer"))
	arg_7_0.npcEffect:setLocalZOrder(6)
	arg_7_0.npcEffect:setPosition(640, 360)
	arg_7_0.npcEffect:play()

	arg_7_0.frame = 0
	arg_7_0.handler = var_0_17.scheduleGlobal(function()
		arg_7_0.frame = arg_7_0.frame + 1

		if arg_7_0.frameAction[arg_7_0.frame] then
			arg_7_0.frameAction[arg_7_0.frame](arg_7_0)
		end
	end, 0.01)
	arg_7_0.frameAction[17] = arg_7_0.createWheel
	arg_7_0.frameAction[50] = arg_7_0.changeWheel
	arg_7_0.frameAction[51] = arg_7_0.createHero
	arg_7_0.frameAction[55] = arg_7_0.createLight
	arg_7_0.frameAction[71] = arg_7_0.showContent
	arg_7_0.frameAction[81] = arg_7_0.npcSpeak
	arg_7_0.frameAction[85] = arg_7_0.onEnd

	for iter_7_0 = 1, arg_7_0.star do
		arg_7_0.frameAction[64 + 4 * iter_7_0] = arg_7_0.createStar
	end

	local var_7_1 = xyd.AssetLoader:get():loadSprite("windows/summon/clip1.png")

	arg_7_0.whiteWheelClipper = cc.ClippingNode:create()

	arg_7_0.whiteWheelClipper:setStencil(var_7_1)
	arg_7_0.whiteWheelClipper:setInverted(true)
	arg_7_0.whiteWheelClipper:setAlphaThreshold(0)
	var_7_1:setAnchorPoint(0, 1)
	var_7_1:setPosition(0, 719.5)
	arg_7_0.whiteWheelClipper:addTo(arg_7_0:nodeByName("down_layer"))
	arg_7_0.whiteWheelClipper:setLocalZOrder(5)

	local var_7_2 = xyd.AssetLoader:get():loadSprite("windows/summon/clip2.png")

	arg_7_0.colorWheelClipper = cc.ClippingNode:create()

	arg_7_0.colorWheelClipper:setStencil(var_7_2)
	arg_7_0.colorWheelClipper:setInverted(true)
	arg_7_0.colorWheelClipper:setAlphaThreshold(0)
	var_7_2:setAnchorPoint(0, 0)
	var_7_2:setPosition(0, -1)
	arg_7_0.colorWheelClipper:addTo(arg_7_0:nodeByName("down_layer"))
	arg_7_0.colorWheelClipper:setLocalZOrder(5)
	audio.playSound(xyd.tables.sound:getSound("summon_draw_card"))

	arg_7_0.layer = display.newNode()

	arg_7_0.layer:pos(0, 0)
	arg_7_0.layer:size(1280, 720)
	arg_7_0.layer:setAnchorPoint(0, 0)
	arg_7_0.layer:addTo(arg_7_0)
	arg_7_0.layer:setVisible(false)
	arg_7_0.layer:setTouchEnabled(true)
	arg_7_0.layer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_7_0)
		end

		return true
	end)
	arg_7_0:getSkipBtn()
end

function var_0_0.createWheel(arg_10_0)
	arg_10_0.GrayWheel = xyd.AssetLoader.get():loadSprite(var_0_10)

	arg_10_0.GrayWheel:setOpacity(128)
	arg_10_0.GrayWheel:addTo(arg_10_0.colorWheelClipper)
	arg_10_0.GrayWheel:setPosition(639, 314)
	arg_10_0.GrayWheel:setAnchorPoint(0.5, 0.5)
	arg_10_0.GrayWheel:runAction(cc.Sequence:create({
		cc.TintBy:create(0, 165, 165, 165),
		cc.CallFunc:create(function()
			arg_10_0.GrayWheel:setScale(2.35)
		end),
		cc.Spawn:create({
			cc.Sequence:create({
				cc.DelayTime:create(0.03),
				cc.ScaleTo:create(0.13, 1.44),
				cc.ScaleTo:create(0.13, 1)
			}),
			cc.Sequence:create({
				cc.DelayTime:create(0.2),
				cc.CallFunc:create(function()
					arg_10_0.GrayWheel:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, var_0_16)))
				end)
			})
		})
	}))

	arg_10_0.GrayShadow = xyd.AssetLoader.get():loadSprite(var_0_11)

	arg_10_0.GrayShadow:setOpacity(51)
	arg_10_0.GrayShadow:addTo(arg_10_0.colorWheelClipper)
	arg_10_0.GrayShadow:setPosition(639, 314)
	arg_10_0.GrayShadow:setAnchorPoint(0.5, 0.5)
	arg_10_0.GrayShadow:runAction(cc.Sequence:create({
		cc.TintBy:create(0, 63, 63, 63),
		cc.CallFunc:create(function()
			arg_10_0.GrayWheel:setScale(2.35)
		end),
		cc.Spawn:create({
			cc.Sequence:create({
				cc.DelayTime:create(0.03),
				cc.ScaleTo:create(0.13, 1.44),
				cc.ScaleTo:create(0.13, 1)
			}),
			cc.Sequence:create({
				cc.DelayTime:create(0.2),
				cc.CallFunc:create(function()
					arg_10_0.GrayShadow:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, var_0_16)))
				end)
			})
		})
	}))

	arg_10_0.WhiteWheel = xyd.AssetLoader.get():loadSprite(var_0_10)

	arg_10_0.WhiteWheel:setOpacity(128)
	arg_10_0.WhiteWheel:addTo(arg_10_0.whiteWheelClipper)
	arg_10_0.WhiteWheel:setPosition(639, 314.5)
	arg_10_0.WhiteWheel:setAnchorPoint(0.5, 0.5)
	arg_10_0.WhiteWheel:runAction(cc.Sequence:create({
		cc.CallFunc:create(function()
			arg_10_0.WhiteWheel:setScale(2.35)
		end),
		cc.Spawn:create({
			cc.Sequence:create({
				cc.ScaleTo:create(0.13, 1.44),
				cc.ScaleTo:create(0.13, 1)
			}),
			cc.Sequence:create({
				cc.DelayTime:create(0.2),
				cc.CallFunc:create(function()
					arg_10_0.WhiteWheel:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, var_0_16)))
				end)
			})
		})
	}))

	arg_10_0.WhiteShadow = xyd.AssetLoader.get():loadSprite(var_0_11)

	arg_10_0.WhiteShadow:setOpacity(51)
	arg_10_0.WhiteShadow:addTo(arg_10_0.whiteWheelClipper, -1)
	arg_10_0.WhiteShadow:setPosition(639, 314.5)
	arg_10_0.WhiteShadow:setAnchorPoint(0.5, 0.5)
	arg_10_0.WhiteShadow:runAction(cc.Sequence:create({
		cc.TintBy:create(0, 165, 165, 165),
		cc.CallFunc:create(function()
			arg_10_0.WhiteShadow:setScale(2.35)
		end),
		cc.Spawn:create({
			cc.Sequence:create({
				cc.ScaleTo:create(0.13, 1.44),
				cc.ScaleTo:create(0.13, 1)
			}),
			cc.Sequence:create({
				cc.DelayTime:create(0.2),
				cc.CallFunc:create(function()
					arg_10_0.WhiteShadow:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, var_0_16)))
				end)
			})
		})
	}))
end

function var_0_0.changeWheel(arg_19_0)
	local var_19_0 = var_0_18[arg_19_0.limitedStar]
	local var_19_1 = var_0_19[arg_19_0.limitedStar]

	arg_19_0.ColorWheel = xyd.AssetLoader.get():loadSprite(var_0_10)

	arg_19_0.ColorWheel:setOpacity(0)
	arg_19_0.ColorWheel:addTo(arg_19_0.colorWheelClipper)
	arg_19_0.ColorWheel:setPosition(639, 314)
	arg_19_0.ColorWheel:setAnchorPoint(0.5, 0.5)
	arg_19_0.ColorWheel:setRotation(0.9 * var_0_16)
	arg_19_0.ColorWheel:runAction(cc.Sequence:create({
		cc.TintBy:create(0, var_19_0[1], var_19_0[2], var_19_0[3]),
		cc.Spawn:create({
			cc.FadeTo:create(0.16, 128),
			cc.CallFunc:create(function()
				arg_19_0.ColorWheel:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, var_0_16)))
			end)
		})
	}))
	arg_19_0.GrayWheel:runAction(cc.Sequence:create({
		cc.FadeOut:create(0.16),
		cc.CallFunc:create(function()
			arg_19_0.GrayWheel:removeSelf()

			arg_19_0.GrayWheel = nil
		end)
	}))

	arg_19_0.ColorShadow = xyd.AssetLoader.get():loadSprite(var_0_11)

	arg_19_0.ColorShadow:setOpacity(0)
	arg_19_0.ColorShadow:addTo(arg_19_0.colorWheelClipper)
	arg_19_0.ColorShadow:setPosition(639, 314)
	arg_19_0.ColorShadow:setAnchorPoint(0.5, 0.5)
	arg_19_0.ColorShadow:setRotation(0.9 * var_0_16)
	arg_19_0.ColorShadow:runAction(cc.Sequence:create({
		cc.TintBy:create(0, var_19_1[1], var_19_1[2], var_19_1[3]),
		cc.Spawn:create({
			cc.FadeTo:create(0.16, 51),
			cc.CallFunc:create(function()
				arg_19_0.ColorShadow:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, var_0_16)))
			end)
		})
	}))
	arg_19_0.GrayShadow:runAction(cc.Sequence:create({
		cc.FadeOut:create(0.16),
		cc.CallFunc:create(function()
			arg_19_0.GrayShadow:removeSelf()

			arg_19_0.GrayShadow = nil
		end)
	}))
	arg_19_0.WhiteShadow:runAction(cc.Spawn:create({
		cc.TintTo:create(0.16, var_19_1[1], var_19_1[2], var_19_1[3])
	}))
end

function var_0_0.createHero(arg_24_0)
	local var_24_0 = arg_24_0.hero_:getModelID()

	arg_24_0.npc = xyd.getTransparentCard(arg_24_0.hero_, xyd.SkinDynamicPosType.MAIN_SCENE, nil, 1.1)

	arg_24_0.npc:setAnchorPoint(0.5, 0)
	arg_24_0.npc:setOpacity(0)
	arg_24_0.npc:addTo(arg_24_0:nodeByName("down_layer"))
	arg_24_0.npc:setLocalZOrder(6)

	local var_24_1 = xyd.tables.libraryHomeCard:x(var_24_0)
	local var_24_2 = xyd.tables.libraryHomeCard:y(var_24_0)

	arg_24_0.npc:runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(640 + var_24_1, 0 + var_24_2)),
		cc.FadeIn:create(0.6)
	}))
end

function var_0_0.showContent(arg_25_0)
	arg_25_0:nodeByName("talk"):setVisible(true)
	arg_25_0:nodeByName("talk"):setOpacity(0)
	arg_25_0:nodeByName("talk"):runAction(cc.FadeIn:create(0.3))
end

function var_0_0.npcSpeak(arg_26_0)
	local var_26_0, var_26_1, var_26_2 = xyd.tables.hero:getSingleVoiceInfo(arg_26_0.hero_:getTableID(), 7)

	arg_26_0.player:playHeroSound(var_26_0, var_26_2)
end

function var_0_0.createLight(arg_27_0)
	arg_27_0.lightEffect = xyd.createEffect(var_0_6)

	arg_27_0.lightEffect:addTo(arg_27_0:nodeByName("up_layer"))
	arg_27_0.lightEffect:setPosition(640, 360)
	arg_27_0.lightEffect:setLocalZOrder(15)
	arg_27_0.lightEffect:play(nil, true)
	arg_27_0.lightEffect:setTimeScale(0.8)
end

function var_0_0.createStar(arg_28_0)
	local var_28_0 = #arg_28_0.starEffects + 1

	arg_28_0.starEffects[var_28_0] = xyd.createEffect(var_0_8)

	local var_28_1 = var_0_14 + (var_28_0 - (1 + arg_28_0.star) / 2) * var_0_12
	local var_28_2 = var_0_15 + (var_28_0 - (1 + arg_28_0.star) / 2) * var_0_13

	arg_28_0.starEffects[var_28_0]:addTo(arg_28_0:nodeByName("up_layer"))
	arg_28_0.starEffects[var_28_0]:setPosition(var_28_1, var_28_2)
	arg_28_0.starEffects[var_28_0]:setLocalZOrder(16)
	arg_28_0.starEffects[var_28_0]:play()
end

function var_0_0.showHasContainer(arg_29_0)
	arg_29_0:nodeByName("has"):setVisible(true)
end

function var_0_0.onEnd(arg_30_0)
	arg_30_0:nodeByName("skip"):setVisible(false)
	arg_30_0.layer:setVisible(true)
	var_0_17.unscheduleGlobal(arg_30_0.handler)

	arg_30_0.handler = nil
end

return var_0_0
