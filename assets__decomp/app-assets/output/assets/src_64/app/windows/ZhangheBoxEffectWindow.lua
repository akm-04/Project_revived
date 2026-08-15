local var_0_0 = class("ZhangheBoxEffectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.awards = arg_1_2.awards
	arg_1_0.multiple = arg_1_2.multiple
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:init()
	arg_2_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("ACTIVITY_1106_TEXT_2"))
	arg_3_0:nodeByName("txt_title"):enableOutline(cc.c4b(52, 60, 75, 255), 2)

	local var_3_0 = "skeletons/ui_effect/vip_box_draw/vip_box_draw_open2"
	local var_3_1 = var_0_1.new(var_3_0 .. ".json", var_3_0 .. ".atlas")

	var_3_1:addTo(arg_3_0:nodeByName("effect_node"))
	var_3_1:setPosition(0, -50)
	var_3_1:play(function()
		arg_3_0:drawFinish()
	end, false, nil, "texiao01")
end

function var_0_0.drawFinish(arg_5_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards({
		arg_5_0.awards[1]
	}, function()
		if arg_5_0.multiple then
			xyd.WindowManager.get():openWindow("vip_box_draw_extra", {
				award = {
					arg_5_0.awards[2]
				},
				multiple = arg_5_0.multiple
			})
		end

		xyd.WindowManager.get():closeWindow(arg_5_0.name)
	end)
end

return var_0_0
