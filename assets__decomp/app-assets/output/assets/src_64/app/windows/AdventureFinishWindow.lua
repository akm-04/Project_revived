local var_0_0 = class("AdventureFinishWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)
end

function var_0_0.showTopEffect(arg_5_0)
	local var_5_0 = "skeletons/adventure/adventure_complete_light"
	local var_5_1 = var_0_1.new(var_5_0 .. ".json", var_5_0 .. ".atlas", 1)
	local var_5_2 = cc.p(arg_5_0:nodeByName("effect"):getPosition())

	var_5_1:align(display.CENTER, var_5_2.x, var_5_2.y):addTo(arg_5_0:nodeByName("effect"))
	var_5_1:play(nil, false, 1, nil)

	local var_5_3 = "skeletons/adventure/adventure-firework"
	local var_5_4 = var_0_1.new(var_5_3 .. ".json", var_5_3 .. ".atlas", 1)
	local var_5_5 = cc.p(arg_5_0:nodeByName("effect"):getPosition())

	var_5_4:align(display.CENTER_TOP, var_5_5.x, var_5_5.y):addTo(arg_5_0:nodeByName("effect"))
	var_5_4:play(nil, false, 1, nil)
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = cc.Sequence:create({
		cc.DelayTime:create(2.5)
	})

	arg_6_0:showTopEffect()
	arg_6_0:nodeByName("effect"):runActionOnce(var_6_0, false, function()
		xyd.WindowManager.get():closeWindow(arg_6_0)
	end)
end

return var_0_0
