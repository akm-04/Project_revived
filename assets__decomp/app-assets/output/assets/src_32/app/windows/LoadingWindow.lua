local var_0_0 = class("LoadingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.delay = arg_1_2.delay or 1.5

	arg_1_0:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	var_2_0:setContentSize(cc.size(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT))
	var_2_0:setPosition(cc.p(0, 0))
	arg_2_0:addChild(var_2_0)

	local function var_2_1(arg_3_0, arg_3_1)
		return true
	end

	local var_2_2 = cc.EventListenerTouchOneByOne:create()

	var_2_2:setSwallowTouches(true)
	var_2_2:registerScriptHandler(var_2_1, cc.Handler.EVENT_TOUCH_BEGAN)
	arg_2_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(var_2_2, arg_2_0)

	local var_2_3 = arg_2_0:nodeByName("bg")

	var_2_3:setVisible(false)
	var_2_0:runAction(cc.Sequence:create({
		cc.DelayTime:create(arg_2_0.delay),
		cc.CallFunc:create(function()
			var_2_3:setVisible(true)

			if not arg_2_0.effect then
				local var_4_0 = "skeletons/ui_effect/loading/loading"

				arg_2_0.effect = var_0_1.new(var_4_0 .. ".json", var_4_0 .. ".atlas", 1)

				arg_2_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
				arg_2_0.effect:addTo(arg_2_0:nodeByName("effect_container"))
				arg_2_0.effect:play(nil, true)
			end
		end)
	}))
	var_2_3:retain()

	arg_2_0.retainBg = var_2_3

	arg_2_0:nodeByName("percent"):setVisible(false)
end

function var_0_0.isAnimated(arg_5_0)
	return arg_5_0.effect
end

function var_0_0.setPercent(arg_6_0, arg_6_1)
	arg_6_0:nodeByName("percent"):setVisible(true)
	arg_6_0:nodeByName("percent"):setString(string.format(var_0_3:translation("LOADING_PERCENT_TEXT"), arg_6_1))
	arg_6_0:nodeByName("percent"):enableOutline(cc.c4b(0, 0, 0, 255), 1)
end

function var_0_0.willClose(arg_7_0)
	arg_7_0.retainBg:release()
end

function var_0_0.closeWindow(arg_8_0)
	xyd.WindowManager.get():closeWindow(arg_8_0.name)
end

return var_0_0
