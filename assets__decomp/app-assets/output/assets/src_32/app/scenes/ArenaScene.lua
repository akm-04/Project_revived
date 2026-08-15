local var_0_0 = import(cc.PACKAGE_NAME .. ".scheduler")
local var_0_1 = class("ArenaScene", import("app.common.ui.BaseScene"))

function var_0_1.ctor(arg_1_0)
	arg_1_0.super.ctor(arg_1_0)
end

function var_0_1.onEnterTransitionFinish(arg_2_0)
	arg_2_0.super.onEnterTransitionFinish(arg_2_0)
	var_0_0.performWithDelayGlobal(handler(arg_2_0, arg_2_0.openWindows), 0.1)
	arg_2_0:display()
end

function var_0_1.openWindows(arg_3_0, arg_3_1)
	xyd.WindowManager.get():openWindow("arena")
end

function var_0_1.display(arg_4_0)
	local var_4_0 = xyd.AssetLoader.get():loadSprite("images/scene_bg.png")

	var_4_0:addTo(arg_4_0)
	var_4_0:setAnchorPoint(cc.p(0, 0))
	var_4_0:setPosition(cc.p(0, 0))
end

return var_0_1
