local var_0_0 = class("GetMarriedWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero_ = arg_1_2.hero
	arg_1_0.playSound_ = false
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.stage = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("married_bg"):setVisible(false)
	arg_3_0:nodeByName("hand_in_hand"):setOpacity(0)
	arg_3_0:nodeByName("hand_in_hand"):setVisible(true)

	local var_3_0 = cc.FadeTo:create(3, 255)

	arg_3_0:nodeByName("hand_in_hand"):runAction(var_3_0)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.SET_FAVOR_TOP_SHOW,
		params = {
			isShow = true
		}
	})
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = {
		size = 28,
		color = cc.c3b(255, 255, 255)
	}

	arg_5_0:setTouchEnabled(true)
	arg_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "ended" and arg_5_0.animated_ and arg_5_0.stage == 3 then
			arg_5_0:nodeByName("married_bg"):setVisible(false)

			local var_6_0 = {
				hero = arg_5_0.hero_,
				dialog = {
					is_read = 1,
					dialog_id = 10
				}
			}

			var_6_0.isNotShowCard = true

			if xyd.WindowManager.get():isWindowOpen("hero_talk_wnd") then
				xyd.WindowManager.get():closeWindow("hero_talk_wnd")
			end

			xyd.WindowManager.get():openWindow("hero_talk_wnd", var_6_0)

			local var_6_1 = xyd.WindowManager.get():getWindow("hero_talk_wnd")

			if var_6_1 then
				var_6_1:nodeByName("skip"):setVisible(false)
				var_6_1:nodeByName("bg"):setVisible(false)

				if var_6_1.bg then
					var_6_1.bg:setVisible(false)
				end
			end

			arg_5_0.close_ = true
			arg_5_0.animated_ = nil
		elseif arg_6_0.name == "ended" and arg_5_0.close_ then
			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		elseif arg_6_0.name == "ended" and arg_5_0.stage == 1 then
			arg_5_0:nodeByName("hand_in_hand"):setVisible(false)
			arg_5_0:nodeByName("flower_girls"):setOpacity(0)
			arg_5_0:nodeByName("flower_girls"):setVisible(true)

			local var_6_2 = cc.FadeTo:create(3, 255)

			arg_5_0:nodeByName("flower_girls"):runAction(var_6_2)

			arg_5_0.stage = 2
		elseif arg_6_0.name == "ended" and arg_5_0.stage == 2 then
			arg_5_0.stage = 3

			arg_5_0:nodeByName("flower_girls"):setVisible(false)
			arg_5_0:showAnimation()
		end

		return true
	end)
	audio.playSound(xyd.tables.sound:getSound("summon_draw_card"))
end

function var_0_0.showAnimation(arg_7_0)
	arg_7_0:getCardSp()

	local var_7_0 = arg_7_0:getContentSize()
	local var_7_1 = var_7_0.width / 2
	local var_7_2 = var_7_0.height / 2

	if not arg_7_0.textEffect_ then
		local var_7_3 = "skeletons/ui_effect/library/library_married"
		local var_7_4 = var_7_3 .. ".json"
		local var_7_5 = var_7_3 .. ".atlas"

		arg_7_0.textEffect_ = var_0_2.new(var_7_4, var_7_5, 1)

		arg_7_0.textEffect_:pos(var_7_1, 175)
		arg_7_0.textEffect_:setAnchorPoint(cc.p(0.5, 0))
		arg_7_0.textEffect_:addTo(arg_7_0, 10)
		arg_7_0.textEffect_:setVisible(false)
	end

	local var_7_6 = {}

	table.insert(var_7_6, cc.DelayTime:create(0.5))
	table.insert(var_7_6, cc.CallFunc:create(function()
		arg_7_0.textEffect_:setVisible(true)
		arg_7_0.textEffect_:play(function()
			arg_7_0.animated_ = true

			arg_7_0:nodeByName("married_bg"):setVisible(true)

			local var_9_0 = cc.FadeIn:create(1)

			arg_7_0:nodeByName("married_bg"):setOpacity(0)
			arg_7_0:nodeByName("married_bg"):runAction(var_9_0)
		end, false)
	end))
	arg_7_0:runAction(transition.sequence(var_7_6))
end

function var_0_0.getCardSp(arg_10_0)
	if not arg_10_0.card_ then
		local var_10_0, var_10_1, var_10_2 = arg_10_0.library:getCardIDInfoBaseOnCardState(arg_10_0.hero_, arg_10_0.library.cardState)

		arg_10_0.card_ = xyd.AssetLoader.get():loadSprite(xyd.tables.model:transparentCard(var_10_0))

		arg_10_0.card_:addTo(arg_10_0:nodeByName("card_pos"))
		arg_10_0.card_:setAnchorPoint(0.5, 0)
		arg_10_0.card_:setPosition(cc.p(0, 0))
		arg_10_0.card_:setTouchSwallowEnabled(true)
	end

	return arg_10_0.card_
end

return var_0_0
