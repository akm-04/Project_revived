local var_0_0 = class("AssistHeroShowWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroTableID = arg_1_2.table_id
	arg_1_0.heroPos = arg_1_2.pos
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.hero = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initHero()
	arg_2_0:layout()
end

function var_0_0.didClose(arg_3_0, arg_3_1)
	var_0_0.super:didClose(arg_3_1)
end

function var_0_0.initHero(arg_4_0)
	local var_4_0 = var_0_2.new()

	var_4_0:initUnCollected(arg_4_0.heroTableID)

	arg_4_0.hero = var_4_0
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = display.newNode()
	local var_5_1 = arg_5_0:nodeByName("card_bg"):getContentSize()
	local var_5_2 = cc.p(arg_5_0:nodeByName("card_bg"):getPosition())

	var_5_0:setContentSize(var_5_1)
	var_5_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_0:setPosition(cc.p(var_5_2))
	var_5_0:addTo(arg_5_0:nodeByName("container"))
	var_5_0:setVisible(false)
	xyd.displaySpriteOnContainer(xyd.getHeroCard(arg_5_0.hero), var_5_0)

	arg_5_0.heroCard = var_5_0

	arg_5_0:animations()
end

function var_0_0.animations(arg_6_0)
	arg_6_0:nodeByName("img_text_1"):setVisible(false)
	arg_6_0:nodeByName("img_text_2"):setVisible(false)
	arg_6_0:nodeByName("img_left"):setVisible(false)
	arg_6_0:nodeByName("img_right"):setVisible(false)
	arg_6_0:showTopEffect()
	arg_6_0:heroCardAnimation()
end

function var_0_0.showTopEffect(arg_7_0)
	local var_7_0 = "skeletons/ui_effect/assist_hero/zhuzhan01"
	local var_7_1 = var_0_1.new(var_7_0 .. ".json", var_7_0 .. ".atlas", 1)
	local var_7_2 = cc.p(arg_7_0:nodeByName("card_bg"):getPosition())

	var_7_1:align(display.CENTER, var_7_2.x, 607.13):addTo(arg_7_0:nodeByName("container"))
	var_7_1:play(nil, false)
end

function var_0_0.showHideEffect(arg_8_0)
	local var_8_0 = "skeletons/ui_effect/assist_hero/zhuzhan02"
	local var_8_1 = var_0_1.new(var_8_0 .. ".json", var_8_0 .. ".atlas", 1)
	local var_8_2 = display.newNode()

	var_8_2:size(294, 434)
	var_8_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_2:addTo(arg_8_0:nodeByName("container"))

	local var_8_3 = var_8_2:getContentSize()

	var_8_1:align(display.CENTER, var_8_3.width / 2, var_8_3.height / 2):addTo(var_8_2)
	var_8_1:play(nil, false)

	local var_8_4 = cc.p(arg_8_0:nodeByName("card_bg"):getPosition())

	var_8_2:pos(var_8_4.x, var_8_4.y)

	local var_8_5 = cc.Spawn:create(cc.CallFunc:create(function()
		arg_8_0.heroCard:setVisible(false)
	end), cc.MoveTo:create(1.2, arg_8_0.heroPos), cc.Sequence:create({
		cc.DelayTime:create(0.7),
		cc.CallFunc:create(function()
			if arg_8_0.callback then
				arg_8_0.callback()
			end
		end)
	}))

	var_8_2:runActionOnce(var_8_5, false, function()
		xyd.WindowManager.get():closeWindow(arg_8_0)
	end, 0.2)
end

function var_0_0.showSummonEffect(arg_12_0)
	local var_12_0 = "skeletons/ui_effect/summon_hero/common_effect_summon12_02"
	local var_12_1 = var_0_1.new(var_12_0 .. ".json", var_12_0 .. ".atlas", 0.68)
	local var_12_2 = cc.p(arg_12_0:nodeByName("card_bg"):getPosition())

	var_12_1:align(display.CENTER, var_12_2.x, var_12_2.y):addTo(arg_12_0:nodeByName("container"))
	var_12_1:play(function()
		arg_12_0:showHideEffect()
	end, false)
end

function var_0_0.heroCardAnimation(arg_14_0)
	local var_14_0 = 0.15
	local var_14_1 = cc.Sequence:create({
		cc.ScaleTo:create(var_14_0, 0, 1),
		cc.CallFunc:create(function()
			return
		end)
	})

	arg_14_0:nodeByName("card_bg"):runActionOnce(var_14_1, false, function()
		local var_16_0 = cc.Sequence:create({
			cc.ScaleTo:create(var_14_0, 1, 1)
		})

		arg_14_0.heroCard:setScaleX(0)
		arg_14_0.heroCard:setVisible(true)
		arg_14_0.heroCard:runActionOnce(var_16_0, false, function()
			arg_14_0:showSummonEffect()
		end)
	end)
end

return var_0_0
