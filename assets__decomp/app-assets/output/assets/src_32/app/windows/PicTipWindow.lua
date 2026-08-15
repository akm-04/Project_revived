local var_0_0 = class("PicTipWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.path = arg_1_2.path
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = xyd.AssetLoader.get():loadSprite(arg_2_0.path)

	var_2_0:addTo(arg_2_0)
	var_2_0:setPosition(640, 360)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

return var_0_0
