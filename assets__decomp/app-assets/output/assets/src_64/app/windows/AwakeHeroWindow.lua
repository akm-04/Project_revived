local var_0_0 = class("AwakeHeroWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = {}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.oldHeroID = arg_1_2.oldHeroID
	arg_1_0.newHeroID = arg_1_2.newHeroID
	arg_1_0.oldHeroForce = arg_1_2.oldHeroForce
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.hero = arg_1_2.hero

	arg_1_0:initEffectSource()

	arg_1_0.canCloseWnd = false
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:nodeByName("bg_awake"):setOpacity(0)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)

	arg_3_0.centerPos = arg_3_0:centerPosition()
	arg_3_0.newCard = arg_3_0:getCardSp(arg_3_0.newHeroID)

	arg_3_0.newCard:setScale(0.7)
	arg_3_0.newCard:setLocalZOrder(3)

	local var_3_0 = arg_3_0.newCard:getChildByName("container"):getChildByName("cardFront"):getHeight()
	local var_3_1 = arg_3_0.newCard:getChildByName("container"):getChildByName("cardFront"):getWidth()
	local var_3_2, var_3_3 = arg_3_0.newCard:getChildByName("container"):getPosition()
	local var_3_4 = arg_3_0.newCard:getChildByName("container"):getWidth()
	local var_3_5 = arg_3_0.newCard:getChildByName("container"):getHeight()
	local var_3_6 = arg_3_0.newCard:getChildByName("container"):getChildByName("cardFront"):getHeight()
	local var_3_7 = 0.01
	local var_3_8 = 22
	local var_3_9 = {
		x = arg_3_0:centerPosition().x,
		y = arg_3_0:centerPosition().y - (var_3_0 / 2 + var_3_1 / 2) + 20
	}
	local var_3_10 = {
		x = var_3_2 + var_3_4 / 2 + 10,
		y = var_3_3 - 40
	}
	local var_3_11 = {
		x = var_3_10.x,
		y = var_3_3 + var_3_5 - 50
	}
	local var_3_12 = 0.1

	arg_3_0:playCardLight(var_3_6, var_3_7, var_3_8, var_3_9, var_3_10, var_3_11, var_3_12)
	arg_3_0:setTouchEnabled(true)
	arg_3_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "ended" and arg_3_0.canCloseWnd then
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end

		return true
	end)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.getCardSp(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_0.hero

	if not var_5_0 then
		var_5_0 = arg_5_0.selfPlayer:getHeroByTableID(arg_5_1)

		if not var_5_0 then
			var_5_0 = clone(arg_5_0.selfPlayer:getHeroByTableID(xyd.tables.hero:beforeAwaken(arg_5_1)))

			if var_5_0 then
				var_5_0:setTableID(arg_5_1)
			end
		end
	end

	local var_5_1 = xyd.getNewHeroCard(var_5_0, 3)

	var_5_1:addTo(arg_5_0:nodeByName("node_card"))
	var_5_1:setPosition(arg_5_0.centerPos.x, arg_5_0.centerPos.y + 60)
	var_5_1:setTouchSwallowEnabled(true)
	var_5_1:getChildByName("label_name"):setVisible(false)

	return var_5_1
end

function var_0_0.initEffectSource(arg_6_0)
	var_0_3.shining = "skeletons/ui_effect/effect_card/effect_card7"
	var_0_3.title = "skeletons/ui_effect/effect_card/effect_card4"
	var_0_3.explode = "skeletons/ui_effect/effect_card/effect_card2"
	var_0_3.rollingBall = "skeletons/ui_effect/effect_card/effect_card5"
	var_0_3.shiningEnd = "skeletons/ui_effect/effect_card/effect_card6"
end

function var_0_0.playEffect(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7, arg_7_8, arg_7_9)
	local var_7_0 = var_0_3[arg_7_2] .. ".json"
	local var_7_1 = var_0_3[arg_7_2] .. ".atlas"
	local var_7_2 = var_0_1.new(var_7_0, var_7_1, arg_7_4)

	var_7_2:addTo(arg_7_1)
	var_7_2:setAnchorPoint(arg_7_7)
	var_7_2:setLocalZOrder(arg_7_5)
	var_7_2:setPosition(arg_7_3)
	var_7_2:play(arg_7_8, arg_7_6, arg_7_9)

	return var_7_2
end

function var_0_0.playCardLight(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0 = cc.Director:getInstance():getWinSize()
	local var_8_1 = arg_8_0.newCard:getChildByName("container"):getChildByName("cardFront"):getWidth() / 2
	local var_8_2 = cc.DrawNode:create()

	var_8_2:drawDot(cc.p(0, 0), var_8_1, cc.c4f(0, 0, 0, 0))
	var_8_2:retain()

	local var_8_3 = cc.RenderTexture:create(var_8_0.width, var_8_0.height)

	var_8_3:setPosition(arg_8_0.newCard:getChildByName("container"):getChildByName("cardFront"):getPosition())
	var_8_3:retain()
	var_8_3:addTo(arg_8_0.newCard:getChildByName("container"), 1000)

	local var_8_4 = xyd.tables.hero:modelID(arg_8_0.oldHeroID)
	local var_8_5 = xyd.SpriteLoader.new(xyd.tables.model:card(var_8_4), nil, nil, xyd.DefaultImageType.HERO_CARD)

	var_8_5:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_5:setPosition(var_8_0.width / 2, var_8_0.height / 2)
	var_8_3:begin()
	var_8_5:visit()
	var_8_3:endToLua()

	local var_8_6 = arg_8_0:convertToWorldSpace(cc.p(0, 0))
	local var_8_7 = arg_8_1
	local var_8_8 = arg_8_4.y + var_8_6.y
	local var_8_9 = arg_8_4.x + var_8_6.x
	local var_8_10 = arg_8_5.y
	local var_8_11 = arg_8_3

	arg_8_0.delayHandle = var_0_2.performWithDelayGlobal(function()
		local var_9_0 = arg_8_0:playEffect(arg_8_0.newCard, "shining", {
			x = arg_8_5.x,
			y = var_8_10
		}, 1.8, 1000, true, cc.p(0.5, 1))

		arg_8_0:playEffect(arg_8_0:nodeByName("node_card"), "rollingBall", {
			x = arg_8_0:centerPosition().x + 10,
			y = arg_8_0:centerPosition().y + 30
		}, nil, 2, false, cc.p(0.5, 0.5))

		arg_8_0.shiningHandle = var_0_2.scheduleGlobal(function()
			var_9_0:setPosition(arg_8_5.x, var_8_10)
			var_8_2:setPosition(var_8_9, var_8_8)
			var_8_2:setBlendFunc(gl.ONE, gl.ZERO)
			var_8_3:begin()
			var_8_2:visit()
			var_8_3:endToLua()

			var_8_8 = var_8_8 + var_8_11
			var_8_10 = var_8_10 + var_8_11

			if var_8_7 <= arg_8_1 / 2 and var_8_7 > arg_8_1 / 4 then
				var_8_11 = var_8_11 + 5
			elseif var_8_7 <= arg_8_1 / 4 then
				var_8_11 = var_8_11 + 30
			end

			if var_8_10 >= arg_8_6.y then
				if arg_8_0.shiningHandle then
					var_0_2.unscheduleGlobal(arg_8_0.shiningHandle)
				end

				var_9_0:runActionOnce(cc.FadeOut:create(0.3), false, nil)
				arg_8_0:playEffect(arg_8_0.newCard, "shiningEnd", {
					x = arg_8_6.x,
					y = arg_8_6.y
				}, 1.8, 500, false, cc.p(0.5, 0.5), function()
					arg_8_0:nodeByName("bg_awake"):runAction(cc.FadeIn:create(1))
					arg_8_0:playEffect(arg_8_0:nodeByName("node_card"), "explode", {
						x = arg_8_0:centerPosition().x + 10,
						y = arg_8_0:centerPosition().y + 30
					}, nil, 1, false, cc.p(0.5, 0.5))

					local var_11_0 = cc.ScaleTo:create(0.1, 0.39)
					local var_11_1 = cc.ScaleTo:create(0.4, 0.85)
					local var_11_2 = cc.ScaleTo:create(0.1, 0.7)
					local var_11_3 = cc.CallFunc:create(function()
						arg_8_0.canCloseWnd = true
					end)

					arg_8_0.newCard:runAction(cc.Sequence:create(var_11_0, var_11_1, var_11_2, var_11_3))
				end, 2)
			end
		end, arg_8_2)
	end, arg_8_7)
end

function var_0_0.willClose(arg_13_0)
	if arg_13_0.delayHandle then
		var_0_2.unscheduleGlobal(arg_13_0.delayHandle)
	end

	if arg_13_0.shiningHandle then
		var_0_2.unscheduleGlobal(arg_13_0.shiningHandle)
	end

	local var_13_0 = {
		oldHeroID = arg_13_0.oldHeroID,
		newHeroID = arg_13_0.newHeroID,
		oldHeroForce = arg_13_0.oldHeroForce,
		hero = arg_13_0.hero
	}

	xyd.WindowManager.get():openWindow("awake_complete", var_13_0)
end

return var_0_0
